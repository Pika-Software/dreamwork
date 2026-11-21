local dreamwork_exceptions = dreamwork.exceptions
local exceptions_call = dreamwork_exceptions.call

local dreamwork_engine = dreamwork.engine
local engine_gui = dreamwork_engine.gui

---@type garrysmod.HTML
---@diagnostic disable-next-line: assign-type-mismatch
local engine_Panel = dreamwork_engine.Panel
local Panel_IsValid = engine_Panel.IsValid
local Panel_IsLoading = engine_Panel.IsLoading
local Panel_NewObject = engine_Panel.NewObject
local Panel_NewObjectCallback = engine_Panel.NewObjectCallback
local Panel_RunJavascript = engine_Panel.RunJavascript
local Panel_OpenURL = engine_Panel.OpenURL
local Panel_Refresh = engine_Panel.Refresh
local Panel_StopLoading = engine_Panel.StopLoading
local Panel_SetSize = engine_Panel.SetSize
local Panel_SetVisible = engine_Panel.SetVisible
local Panel_SetPaintedManually = engine_Panel.SetPaintedManually
local Panel_SetMouseInputEnabled = engine_Panel.SetMouseInputEnabled
local Panel_SetKeyboardInputEnabled = engine_Panel.SetKeyboardInputEnabled

local gui_panelCreate = engine_gui.panelCreate
local gui_panelDestroy = engine_gui.panelDestroy

---@class dreamwork.std
local std = dreamwork.std

local class = std.class

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local raw = std.raw
local raw_index = raw.index
local raw_tostring = raw.tostring
local raw_pairs = raw.pairs

local string = std.string
local string_format = string.format
local string_match = string.match
local string_sub = string.sub

local table = std.table
local table_unpack = table.unpack
local table_concat = table.concat

local type = std.type
local error = std.error
local isFunction = std.isFunction

local Emitter = std.Emitter

local base64_encode = std.base64.encode
local ValueError = std.ValueError


---@alias dreamwork.std.WebClient.Status
---| "closed" # Panel destroyed or never created.
---| "loading" # Document is loading / not ready for JS yet.
---| "ready" # Document ready; `:run` executes immediately.

local STATUS_CLOSED = 0
local STATUS_LOADING = 1
local STATUS_READY = 2

---@type table<integer, dreamwork.std.WebClient.Status>
local status_names = {
    [ STATUS_CLOSED ] = "closed",
    [ STATUS_LOADING ] = "loading",
    [ STATUS_READY ] = "ready"
}


---@type table<dreamwork.std.WebClient, garrysmod.HTML>
local panels = {}
gc_setTableRules( panels, true, false )

--- Reverse panel → client lookup, weak values so panel callbacks never keep the client alive.
---
---@type table<garrysmod.HTML, dreamwork.std.WebClient>
local clients = {}
gc_setTableRules( clients, false, true )

---@type table<dreamwork.std.WebClient, integer>
local statuses = {}
gc_setTableRules( statuses, true, false )

---@type table<dreamwork.std.WebClient, ( string | nil )>
local urls = {}
gc_setTableRules( urls, true, false )

--- Last known document HTML: the assigned source, then the parsed DOM snapshot taken after every `"load"`.
---
---@type table<dreamwork.std.WebClient, ( string | nil )>
local htmls = {}
gc_setTableRules( htmls, true, false )

--- Clients that never navigated: the first `:run` starts a blank document for them.
---
--- Constructors do not preload a blank page, its late `"ready"` would otherwise flush
--- JS queued for the document assigned right after construction into the blank one.
---
---@type table<dreamwork.std.WebClient, boolean>
local idle = {}
gc_setTableRules( idle, true, false )

--- Serializes the current document (doctype included) back to Lua through the internal bridge.
local SNAPSHOT_JS = "dreamwork.html((document.doctype?new XMLSerializer().serializeToString(document.doctype):'')+document.documentElement.outerHTML);"

--- Pending JS snippets, flushed on the next `"ready"` event (Chromium does not delay `RunJavascript`).
---
---@type table<dreamwork.std.WebClient, { [0]: integer, [integer]: string }>
local run_queues = {}
gc_setTableRules( run_queues, true, false )

---@alias dreamwork.std.WebClient.JSCallback fun( ...: any ): any

--- Per-object JS bridge map for one panel.
--- Sentinel: `bridges[ object ] = true`. Callback: `bridges[ object .. "." .. method ] = fn`.
---
---@class dreamwork.std.WebClient.JSBridges
---@field [string] dreamwork.std.WebClient.JSCallback | true

--- JS↔Lua bridges for the underlying `HTML` panel (`NewObject` / `NewObjectCallback` / `OnCallback`).
---
---@type table<dreamwork.std.WebClient, dreamwork.std.WebClient.JSBridges>
local js_bridges = {}
gc_setTableRules( js_bridges, true, false )

--- Bridges used internally (`"message"` event, `html` snapshot), `bind` / `unbind` refuse them.
---
---@type table<string, boolean>
local reserved_paths = {
    [ "dreamwork.message" ] = true,
    [ "dreamwork.html" ] = true
}

--- Unbound `"object.method"` paths mapped to their object name.
---
--- The engine re-injects every `NewObjectCallback` function into each new document,
--- so these are deleted from `window` again on every `"ready"`.
---
---@type table<dreamwork.std.WebClient, table<string, string>>
local unbound = {}
gc_setTableRules( unbound, true, false )

--- Returns `true` if `object_name` still has any bound method.
---
---@param bridges dreamwork.std.WebClient.JSBridges
---@param object_name string
---@return boolean
local function has_methods( bridges, object_name )
    local prefix = object_name .. "."
    local prefix_length = #prefix

    for key in raw_pairs( bridges ) do
        if string_sub( key, 1, prefix_length ) == prefix then
            return true
        end
    end

    return false
end

--- Registers every bound object / function on the panel again.
---
--- Navigating to another origin moves the page into a new renderer process, which
--- loses all `NewObject` / `NewObjectCallback` injections. Registering twice is harmless.
---
---@param client dreamwork.std.WebClient
---@param panel garrysmod.HTML
local function register_bridges( client, panel )
    local bridges = js_bridges[ client ]
    if bridges == nil then return end

    for key, value in raw_pairs( bridges ) do
        if value == true then
            Panel_NewObject( panel, key )
        end
    end

    for key, value in raw_pairs( bridges ) do
        if value ~= true then
            Panel_NewObjectCallback( panel, string_match( key, "^([^.]+)%.(.+)$" ) )
        end
    end
end

--- Loads `html` as a document.
---
--- Same URL `HTML:SetHTML` builds, but through `OpenURL`: the engine's `SetHTML`
--- silently does nothing once the panel has navigated to another origin.
---
---@param panel garrysmod.HTML
---@param html string
local function open_html( panel, html )
    Panel_OpenURL( panel, "asset://html/?" .. base64_encode( html ) )
end

--- Deletes every unbound function (and objects left without methods) from the current document.
---
---@param client dreamwork.std.WebClient
---@param panel garrysmod.HTML
local function apply_unbinds( client, panel )
    local paths = unbound[ client ]
    if paths == nil then return end

    local bridges = js_bridges[ client ]
    if bridges == nil then return end

    ---@type string[]
    local segments = {}

    ---@type integer
    local segment_count = 0

    ---@type table<string, boolean>
    local objects = {}

    for path, object_name in raw_pairs( paths ) do
        segment_count = segment_count + 1
        segments[ segment_count ] = string_format( "if(window.%s)delete window.%s;", object_name, path )
        objects[ object_name ] = true
    end

    if segment_count == 0 then return end

    for object_name in raw_pairs( objects ) do
        if not has_methods( bridges, object_name ) then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_format( "delete window.%s;", object_name )
        end
    end

    exceptions_call( Panel_RunJavascript, panel, "try{" .. table_concat( segments, "", 1, segment_count ) .. "}catch(e){}" )
end

--- Exposes `object.method` to JavaScript, same wiring as `DHTML:AddFunction`.
---
---@param panel garrysmod.HTML
---@param bridges dreamwork.std.WebClient.JSBridges
---@param path string The `"object.method"` key, matches what `OnCallback` receives.
---@param object_name string
---@param method string
---@param callback dreamwork.std.WebClient.JSCallback
local function expose_js( panel, bridges, path, object_name, method, callback )
    if bridges[ object_name ] ~= true then
        Panel_NewObject( panel, object_name )
        bridges[ object_name ] = true
    end

    Panel_NewObjectCallback( panel, object_name, method )
    bridges[ path ] = callback
end


--- Per-client event listeners.
---
---@type dreamwork.std.Emitter
local events = Emitter( "WebClient" )

---@type table<dreamwork.std.WebClient.Event, boolean>
local event_names = {
    ready = true,
    load = true,
    begin = true,
    console = true,
    title = true,
    url = true,
    message = true,
    destroy = true
}

--- Throws unless `event` is a known WebClient event, the error points at the method's caller.
---
---@param event any
local function check_event( event )
    if not event_names[ event ] then
        error( string_format( "unknown WebClient event '%s'", raw_tostring( event ) ), 3 )
    end
end

--- Drops the `exceptions_call` success flag, returning the callback results on success only.
---
---@param success boolean
---@param ... any
---@return any ...
local function bridge_results( success, ... )
    if success then
        return ...
    end
end

--- Returns the internal integer status of the client.
---
---@param client dreamwork.std.WebClient
---@return integer
local function get_status( client )
    return statuses[ client ] or STATUS_CLOSED
end

--- Returns the live (not closed) client that owns the panel, or `nil`.
---
---@param panel garrysmod.HTML
---@return dreamwork.std.WebClient | nil
local function panel_client( panel )
    local client = clients[ panel ]
    if client == nil or get_status( client ) == STATUS_CLOSED then
        return nil
    end

    return client
end

--- Returns the live panel, or `nil` when missing / invalid.
---
---@param client dreamwork.std.WebClient
---@return ( garrysmod.HTML | nil )
local function get_panel( client )
    local panel = panels[ client ]
    if panel == nil then
        return nil
    end

    if not Panel_IsValid( panel ) then
        panels[ client ] = nil
        return nil
    end

    return panel
end

--- Clears pending JS for a client.
---
---@param client dreamwork.std.WebClient
local function clear_queue( client )
    run_queues[ client ] = nil
end

--- Flushes queued JS after the document becomes ready.
---
---@param client dreamwork.std.WebClient
---@param panel garrysmod.HTML
local function flush_queue( client, panel )
    local queue = run_queues[ client ]
    if queue == nil then
        return
    end

    run_queues[ client ] = nil

    for i = 1, queue[ 0 ], 1 do
        exceptions_call( Panel_RunJavascript, panel, queue[ i ] )
    end
end

--- Marks the client closed, drops the panel reference and fires `"destroy"` once.
---
---@param client dreamwork.std.WebClient
---@param remove_panel boolean When `true`, also destroy the VGUI panel.
local function emit_destroy( client, remove_panel )
    if get_status( client ) == STATUS_CLOSED then return end

    statuses[ client ] = STATUS_CLOSED
    clear_queue( client )

    local panel = panels[ client ]

    panels[ client ] = nil
    urls[ client ] = nil
    htmls[ client ] = nil
    idle[ client ] = nil
    js_bridges[ client ] = nil
    unbound[ client ] = nil

    if panel ~= nil then
        clients[ panel ] = nil
    end

    if remove_panel and panel ~= nil and Panel_IsValid( panel ) then
        exceptions_call( gui_panelDestroy, panel )
    end

    events:emit( client, "destroy", client )
end

--- Ensures the client still owns a live panel; throws otherwise.
---
---@param client dreamwork.std.WebClient
---@return garrysmod.HTML panel
local function require_panel( client )
    local panel = get_panel( client )
    if panel == nil then
        if get_status( client ) ~= STATUS_CLOSED then
            emit_destroy( client, false )
        end

        error( "WebClient panel is not valid", 3 )
    end

    return panel
end


--- Engine callbacks copied onto every `HTML` panel in `WebClient:__init`.
---
--- They must never capture a client: the engine keeps the panel alive, so any strong
--- path panel → client would make `__gc` unreachable; resolve it through `clients[ self ]`.
---
---@type garrysmod.HTML
---@diagnostic disable-next-line: missing-fields
local panel_methods = {}

function panel_methods:OnRemove()
    local client = clients[ self ]
    if client ~= nil then
        emit_destroy( client, false )
    end
end

--- Engine JS→Lua entry point (same as `DHTML:OnCallback`).
---@param library string
---@param name string
---@param arguments any[]
---@return any?
function panel_methods:OnCallback( library, name, arguments )
    local client = clients[ self ]
    if client == nil then return end

    local bridges = js_bridges[ client ]
    if bridges == nil then return end

    local fn = bridges[ library .. "." .. name ]
    if isFunction( fn ) then
        ---@cast fn dreamwork.std.WebClient.JSCallback
        return fn( table_unpack( arguments ) )
    end
end

---@param url string
function panel_methods:OnBeginLoadingDocument( url )
    local client = panel_client( self )
    if client == nil then return end

    -- Only page-driven navigation drops the queue; `url` / `html` assignment and `refresh`
    -- already cleared it and anything queued since targets the new document.
    if get_status( client ) == STATUS_READY then
        clear_queue( client )
    end

    statuses[ client ] = STATUS_LOADING
    urls[ client ] = url

    events:emit( client, "begin", client, url )
end

---@param url string
function panel_methods:OnDocumentReady( url )
    local client = panel_client( self )
    if client == nil then return end

    statuses[ client ] = STATUS_READY
    urls[ client ] = url

    register_bridges( client, self )
    apply_unbinds( client, self )
    flush_queue( client, self )

    events:emit( client, "ready", client, url )
end

---@param url string
function panel_methods:OnFinishLoadingDocument( url )
    local client = panel_client( self )
    if client == nil then return end

    urls[ client ] = url

    -- Some Chromium builds only fire finish; treat it as ready if ready was skipped.
    if get_status( client ) == STATUS_LOADING then
        statuses[ client ] = STATUS_READY
        register_bridges( client, self )
        apply_unbinds( client, self )
        flush_queue( client, self )
        events:emit( client, "ready", client, url )
    end

    exceptions_call( Panel_RunJavascript, self, SNAPSHOT_JS )
    events:emit( client, "load", client, url )
end

---@param url string
function panel_methods:OnChangeAddressBar( url )
    local client = panel_client( self )
    if client == nil then
        return
    end

    urls[ client ] = url

    events:emit( client, "url", client, url )
end

---@param title string
function panel_methods:OnChangeTitle( title )
    local client = panel_client( self )
    if client == nil then
        return
    end

    events:emit( client, "title", client, title )
end

---@param msg string?
---@param file_name string?
---@param line_nr number?
---@param severity string?
function panel_methods:ConsoleMessage( msg, file_name, line_nr, severity )
    local client = panel_client( self )
    if client == nil then
        return
    end

    events:emit( client, "console", client, msg, file_name, line_nr, severity )
end

--- [CLIENT AND MENU]
---
--- A headless `HTML` panel for running browser JavaScript, WebSockets and other web
--- APIs from Lua without painting a visible UI.
---
--- JS↔Lua uses the engine `HTML` bridge (`NewObject` / `NewObjectCallback` / `OnCallback`) via `:bind`.
--- Page-driven Lua (`SetAllowLua` / `RUNLUA:`) stays off; use `:bind` instead.
---
--- Create with `std.WebClient()`, attach handlers, assign `url` or `html` (a new client has no
--- document and stays `"loading"` until then, or until the first `:run`), then `:run` JS /
--- `:bind` Lua bridges. Prefer waiting for `"ready"` (or using the built-in JS queue)
--- before touching the document on Chromium.
---
---@class dreamwork.std.WebClient : dreamwork.std.Object
---@field __class dreamwork.std.WebClientClass
---@field url ( string | nil ) The current document URL; assigning opens it (`http(s)://`, `asset://`, `about:blank`, ...), resets readiness and drops queued JS.
---@field html ( string | nil ) The current document HTML; assigning replaces the document, resets readiness and drops queued JS. Reads return the assigned source until the next `"load"`, then a snapshot of the parsed DOM (normalized markup) taken right after every `"load"` fires; `nil` after a `url` assignment until that snapshot arrives.
local WebClient = class.base( "WebClient", true, nil )

---@param key string
---@return any
---@protected
function WebClient:__index( key )
    if key == "url" then
        return urls[ self ]
    elseif key == "html" then
        return htmls[ self ]
    end

    return raw_index( WebClient, key )
end

---@param key string
---@param value any
---@protected
function WebClient:__newindex( key, value )
    if key == "url" then
        local panel = require_panel( self )

        idle[ self ] = nil
        statuses[ self ] = STATUS_LOADING

        clear_queue( self )

        urls[ self ] = value
        htmls[ self ] = nil

        Panel_OpenURL( panel, value )
        return
    elseif key == "html" then
        local panel = require_panel( self )

        idle[ self ] = nil
        statuses[ self ] = STATUS_LOADING

        clear_queue( self )

        htmls[ self ] = value

        open_html( panel, value )
        return
    end

    error( string_format( "attempt to modify unknown WebClient property '%s'", key ), 2 )
end

---@return string
---@protected
function WebClient:__represent()
    return string_format( "%s: %p [%s][%s]", type( self ), self, urls[ self ] or "about:blank", status_names[ get_status( self ) ] )
end

---@param width integer? Panel width in pixels. Defaults to `0`.
---@param height integer? Panel height in pixels. Defaults to `0`.
---@protected
function WebClient:__init( width, height )
    local panel = gui_panelCreate( "HTML" )
    if panel == nil then
        error( "failed to create HTML panel for WebClient", 2 )
    end

    panels[ self ] = panel
    clients[ panel ] = self
    statuses[ self ] = STATUS_LOADING

    ---@type dreamwork.std.WebClient.JSBridges
    local bridges = {}
    js_bridges[ self ] = bridges

    Panel_SetSize( panel, width or 0, height or 0 )

    -- Keep CEF alive without contributing to the normal paint pass.
    Panel_SetVisible( panel, true )
    Panel_SetPaintedManually( panel, true )
    Panel_SetMouseInputEnabled( panel, false )
    Panel_SetKeyboardInputEnabled( panel, false )

    for key, value in raw_pairs( panel_methods ) do
        panel[ key ] = value
    end

    -- Default JS → Lua bridge (not SetAllowLua / RUNLUA).
    expose_js( panel, bridges, "dreamwork.message", "dreamwork", "message", function( channel, payload )
        local client = panel_client( panel )
        if client ~= nil then
            events:emit( client, "message", client, channel, payload )
        end
    end )

    -- Internal bridge for `SNAPSHOT_JS`, keeps `html` in sync with the loaded document.
    expose_js( panel, bridges, "dreamwork.html", "dreamwork", "html", function( html )
        local client = panel_client( panel )
        if client ~= nil then
            htmls[ client ] = html
        end
    end )

    idle[ self ] = true
end

--- Destroys the panel when the object is collected.
---
---@protected
function WebClient:__gc()
    emit_destroy( self, true )
end

--- [CLIENT AND MENU]
---
--- Returns the current lifecycle status as a string.
---
---@return dreamwork.std.WebClient.Status status `"closed"`, `"loading"` or `"ready"`.
---@nodiscard
function WebClient:getStatus()
    return status_names[ get_status( self ) ]
end

--- [CLIENT AND MENU]
---
--- Returns `true` while the underlying HTML panel still exists.
---
---@return boolean is_valid
---@nodiscard
function WebClient:__isvalid()
    return get_panel( self ) ~= nil and get_status( self ) ~= STATUS_CLOSED
end

--- [CLIENT AND MENU]
---
--- Returns `true` when the document is ready for immediate `:run` calls.
---
---@return boolean is_ready
---@nodiscard
function WebClient:isReady()
    return get_status( self ) == STATUS_READY
end

--- [CLIENT AND MENU]
---
--- Returns `true` while a document is loading.
---
---@return boolean is_loading
---@nodiscard
function WebClient:isLoading()
    local status = get_status( self )
    if status == STATUS_LOADING then
        return true
    end

    if status ~= STATUS_READY then
        return false
    end

    local panel = get_panel( self )
    if panel == nil then
        return false
    end

    return Panel_IsLoading( panel ) == true
end

--- [CLIENT AND MENU]
---
--- Returns `true` after `:close` / panel removal.
---
---@return boolean is_closed
---@nodiscard
function WebClient:isClosed()
    return get_status( self ) == STATUS_CLOSED
end

--- [CLIENT AND MENU]
---
--- Executes JavaScript in the panel.
---
--- If the document is not ready yet, the snippet is queued and flushed on the next
--- `"ready"` event (required on Chromium, which does not delay `RunJavascript`).
--- On a client that has no document yet (no `url` / `html` assigned), a blank one is started.
---
---@param js string JavaScript source to run.
function WebClient:run( js )
    local panel = require_panel( self )

    if get_status( self ) == STATUS_READY then
        Panel_RunJavascript( panel, js )
        return
    end

    local queue = run_queues[ self ]
    if queue == nil then
        queue = { [ 0 ] = 0 }
        run_queues[ self ] = queue
    end

    local index = queue[ 0 ] + 1
    queue[ 0 ] = index
    queue[ index ] = js

    if idle[ self ] then
        idle[ self ] = nil
        open_html( panel, "" )
    end
end

--- [CLIENT AND MENU]
---
--- Reloads the current document.
---
---@param ignore_cache boolean? When `true`, bypasses the HTTP cache. Defaults to `false`.
function WebClient:refresh( ignore_cache )
    local panel = require_panel( self )

    statuses[ self ] = STATUS_LOADING
    clear_queue( self )
    Panel_Refresh( panel, ignore_cache == true )
end

--- [CLIENT AND MENU]
---
--- Stops the current navigation / load, if any.
---
function WebClient:stop()
    Panel_StopLoading( require_panel( self ) )
end

--- [CLIENT AND MENU]
---
--- Exposes a Lua function to JavaScript as `object.method( ... )`.
---
--- `path` is exactly one `object.method` pair of JS identifiers ( `[A-Za-z_$][A-Za-z0-9_$]*` ),
--- the engine has no nested objects: `"a.b.c"` would become a global literally named `"a.b"`.
--- The object is a global created on first use and survives navigation.
---
--- Arguments arriving from JS are strings / numbers / booleans only; serialize
--- structured data on the JS side (e.g. `JSON.stringify`) and parse in Lua.
---
--- Values returned by `callback` are forwarded back to JS asynchronously: pass a trailing JS
--- function, e.g. `lua.add( 2, 3, function( result ) { ... } )`; the direct JS return is `undefined`.
--- Errors are reported and yield nothing.
---
--- ```lua
--- web:bind( "lua.add", function( a, b ) return a + b end )
--- ```
---
---@param path string The JavaScript `"object.method"` path, e.g. `"lua.add"`.
---@param callback fun( ...: any ): any Lua function invoked from JS.
function WebClient:bind( path, callback )
    local object_name, method = string_match( path, "^([%a_$][%w_$]*)%.([%a_$][%w_$]*)$" )
    if object_name == nil then
        error( ValueError( path, "path must be 'object.method' made of two JavaScript identifiers" ), 2 )
    end

    if reserved_paths[ path ] then
        error( ValueError( path, "path is reserved for internal use" ), 2 )
    end

    local panel = require_panel( self )

    ---@type dreamwork.std.WebClient.JSBridges
    local bridges = js_bridges[ self ]
    if bridges == nil then
        bridges = {}
        js_bridges[ self ] = bridges
    end

    local paths = unbound[ self ]
    if paths ~= nil and paths[ path ] ~= nil then
        paths[ path ] = nil

        -- the object itself may have been deleted from `window` together with its last method
        bridges[ object_name ] = nil
    end

    -- Captures `panel`, never `self`: bridges are reachable from the panel (see `__init`).
    expose_js( panel, bridges, path, object_name, method, function( ... )
        if panel_client( panel ) ~= nil then
            return bridge_results( exceptions_call( callback, ... ) )
        end
    end )
end

--- [CLIENT AND MENU]
---
--- Removes a function exposed with `:bind`.
---
--- The engine cannot unregister `NewObjectCallback` functions, so the Lua callback is dropped
--- and the JS function is deleted from `window` now and again on every `"ready"` (the engine
--- re-injects it into each new document). The object is deleted too once it has no bound methods.
---
---@param path string The JavaScript `"object.method"` path given to `:bind`.
---@return boolean removed `true` if `path` was bound.
function WebClient:unbind( path )
    local object_name = string_match( path, "^([%a_$][%w_$]*)%.[%a_$][%w_$]*$" )
    if object_name == nil then
        error( ValueError( path, "path must be 'object.method' made of two JavaScript identifiers" ), 2 )
    end

    if reserved_paths[ path ] then
        error( ValueError( path, "path is reserved for internal use" ), 2 )
    end

    local panel = require_panel( self )

    local bridges = js_bridges[ self ]
    if bridges == nil or bridges[ path ] == nil then
        return false
    end

    bridges[ path ] = nil

    local paths = unbound[ self ]
    if paths == nil then
        paths = {}
        unbound[ self ] = paths
    end

    paths[ path ] = object_name

    if get_status( self ) == STATUS_READY then
        apply_unbinds( self, panel )
    end

    return true
end

--- [CLIENT AND MENU]
---
--- Destroys the panel and fires `"destroy"`. Further methods throw.
---
function WebClient:close()
    emit_destroy( self, true )
end

--- [CLIENT AND MENU]
---
--- Alias of `WebClient:close`.
---
function WebClient:destroy()
    return self:close()
end

---@alias dreamwork.std.WebClient.Event
---| "ready" # DOM is ready; safe to run JS immediately.
---| "load" # Document finished loading (resources may still settle).
---| "begin" # Navigation / load started.
---| "console" # `console.*` from the page.
---| "title" # Document title changed.
---| "url" # Address bar / location changed.
---| "message" # Default bridge: `dreamwork.message( channel, payload )` from JS.
---| "destroy" # Panel was closed or removed.

---@alias dreamwork.std.WebClient.ReadyHandler fun( client: dreamwork.std.WebClient, url: string )
---@alias dreamwork.std.WebClient.LoadHandler fun( client: dreamwork.std.WebClient, url: string )
---@alias dreamwork.std.WebClient.BeginHandler fun( client: dreamwork.std.WebClient, url: string )
---@alias dreamwork.std.WebClient.ConsoleHandler fun( client: dreamwork.std.WebClient, msg: ( string | nil ), file_name: ( string | nil ), line_nr: ( number | nil ), severity: ( string | nil ) )
---@alias dreamwork.std.WebClient.TitleHandler fun( client: dreamwork.std.WebClient, title: ( string | nil ) )
---@alias dreamwork.std.WebClient.UrlHandler fun( client: dreamwork.std.WebClient, url: string )
---@alias dreamwork.std.WebClient.MessageHandler fun( client: dreamwork.std.WebClient, channel: ( string | nil ), payload: ( string | nil ) )
---@alias dreamwork.std.WebClient.DestroyHandler fun( client: dreamwork.std.WebClient )

--- [CLIENT AND MENU]
---
--- Attaches a handler for the given event.
---
---@param event dreamwork.std.WebClient.Event
---@param handler function
---
---@overload fun( self: dreamwork.std.WebClient, event: "ready", handler: dreamwork.std.WebClient.ReadyHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "load", handler: dreamwork.std.WebClient.LoadHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "begin", handler: dreamwork.std.WebClient.BeginHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "console", handler: dreamwork.std.WebClient.ConsoleHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "title", handler: dreamwork.std.WebClient.TitleHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "url", handler: dreamwork.std.WebClient.UrlHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "message", handler: dreamwork.std.WebClient.MessageHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "destroy", handler: dreamwork.std.WebClient.DestroyHandler )
function WebClient:attach( event, handler )
    check_event( event )
    events:attach( self, event, handler )
end

--- [CLIENT AND MENU]
---
--- Attaches a one-shot handler for the given event.
---
---@param event dreamwork.std.WebClient.Event
---@param handler function
---
---@overload fun( self: dreamwork.std.WebClient, event: "ready", handler: dreamwork.std.WebClient.ReadyHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "load", handler: dreamwork.std.WebClient.LoadHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "begin", handler: dreamwork.std.WebClient.BeginHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "console", handler: dreamwork.std.WebClient.ConsoleHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "title", handler: dreamwork.std.WebClient.TitleHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "url", handler: dreamwork.std.WebClient.UrlHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "message", handler: dreamwork.std.WebClient.MessageHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "destroy", handler: dreamwork.std.WebClient.DestroyHandler )
function WebClient:once( event, handler )
    check_event( event )
    events:once( self, event, handler )
end

--- [CLIENT AND MENU]
---
--- Detaches a previously attached handler from the given event.
---
---@param event dreamwork.std.WebClient.Event
---@param handler function
---
---@overload fun( self: dreamwork.std.WebClient, event: "ready", handler: dreamwork.std.WebClient.ReadyHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "load", handler: dreamwork.std.WebClient.LoadHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "begin", handler: dreamwork.std.WebClient.BeginHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "console", handler: dreamwork.std.WebClient.ConsoleHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "title", handler: dreamwork.std.WebClient.TitleHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "url", handler: dreamwork.std.WebClient.UrlHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "message", handler: dreamwork.std.WebClient.MessageHandler )
---@overload fun( self: dreamwork.std.WebClient, event: "destroy", handler: dreamwork.std.WebClient.DestroyHandler )
function WebClient:detach( event, handler )
    check_event( event )
    events:detach( self, event, handler )
end

--- [CLIENT AND MENU]
---
--- Removes every handler for `event`, or every handler of every event when omitted.
---
---@param event dreamwork.std.WebClient.Event?
function WebClient:clear( event )
    if event ~= nil then
        check_event( event )
    end

    events:clear( self, event )
end

--- [CLIENT AND MENU]
---
--- Waits until the given event fires, then resumes with that event's arguments.
---
--- `"ready"` returns immediately on a ready client and `"destroy"` on a closed one.
--- Awaiting any other event throws if the client is closed, or gets closed while waiting.
---
---@param event dreamwork.std.WebClient.Event
---@return any ...
---@async
---
---@overload fun( self: dreamwork.std.WebClient, event: "ready" ): dreamwork.std.WebClient, string
---@overload fun( self: dreamwork.std.WebClient, event: "load" ): dreamwork.std.WebClient, string
---@overload fun( self: dreamwork.std.WebClient, event: "begin" ): dreamwork.std.WebClient, string
---@overload fun( self: dreamwork.std.WebClient, event: "console" ): dreamwork.std.WebClient, ( string | nil ), ( string | nil ), ( number | nil ), ( string | nil )
---@overload fun( self: dreamwork.std.WebClient, event: "title" ): dreamwork.std.WebClient, ( string | nil )
---@overload fun( self: dreamwork.std.WebClient, event: "url" ): dreamwork.std.WebClient, string
---@overload fun( self: dreamwork.std.WebClient, event: "message" ): dreamwork.std.WebClient, ( string | nil ), ( string | nil )
---@overload fun( self: dreamwork.std.WebClient, event: "destroy" ): dreamwork.std.WebClient
function WebClient:await( event )
    check_event( event )

    local status = get_status( self )

    if status == STATUS_CLOSED then
        if event == "destroy" then
            return self
        end

        error( string_format( "cannot await '%s' on a closed WebClient", event ), 2 )
    end

    -- Already-ready clients would hang forever waiting for another `"ready"` fire.
    if event == "ready" and status == STATUS_READY then
        return self, urls[ self ]
    end

    if event == "destroy" then
        return events:await( self, "destroy" )
    end

    return events:await( self, event, "destroy", string_format( "WebClient was closed while awaiting '%s'", event ) )
end

--- [CLIENT AND MENU]
---
--- The class used to create new `WebClient` instances.
---
--- Client / menu only. Prefer attaching handlers before navigation settles, or rely on
--- the JS queue inside `:run`.
---
--- ```lua
--- local web = std.WebClient()
---
--- web:attach( "ready", function( client )
---     client:run( "dreamwork.message('ping', 'hello')" )
--- end )
---
--- web:attach( "message", function( client, channel, payload )
---     print( channel, payload )
--- end )
---
--- web.html = "<html><body>hello</body></html>" -- or `web.url = "https://example.com"`
--- web:run( "console.log('queued until ready')" )
---
--- web:attach( "load", function( client )
---     print( client.url ) -- `client.html` gets the parsed DOM snapshot shortly after this
--- end )
--- ```
---
---@class dreamwork.std.WebClientClass : dreamwork.std.WebClient, dreamwork.std.Class
---@field __base dreamwork.std.WebClient
---@overload fun( width: integer?, height: integer? ): dreamwork.std.WebClient
std.WebClient = class.create( WebClient )
