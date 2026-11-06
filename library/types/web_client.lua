---@meta _

---@alias WebClient.Status
---| "closed" # Panel destroyed or never created.
---| "loading" # Document is loading / not ready for JS yet.
---| "ready" # Document ready; `:run` executes immediately.

---@alias WebClient.JSCallback fun( ...: any ): any

--- Per-object JS bridge map for one panel.
--- Sentinel: `bridges[ object ] = true`. Callback: `bridges[ object .. "." .. method ] = fn`.
---
---@class WebClient.JSBridges
---@field [string] WebClient.JSCallback | true

--- [CLIENT AND MENU]
---
--- A headless `HTML` panel for running browser JavaScript, WebSockets and other web
--- APIs from Lua without painting a visible UI.
---
--- JS↔Lua uses the engine `HTML` bridge (`NewObject` / `NewObjectCallback` / `OnCallback`) via `:bind`.
--- Page-driven Lua (`SetAllowLua` / `RUNLUA:`) stays off; use `:bind` instead.
---
--- Create with `WebClient()`, attach handlers, assign `url` or `html` (a new client has no
--- document and stays `"loading"` until then, or until the first `:run`), then `:run` JS /
--- `:bind` Lua bridges. Prefer waiting for `"ready"` (or using the built-in JS queue)
--- before touching the document on Chromium.
---
---@class WebClient : Object
---@field __class WebClientClass
---@field url ( string | nil ) The current document URL; assigning opens it (`http(s)://`, `asset://`, `about:blank`, ...), resets readiness and drops queued JS.
---@field html ( string | nil ) The current document HTML; assigning replaces the document, resets readiness and drops queued JS. Reads return the assigned source until the next `"load"`, then a snapshot of the parsed DOM (normalized markup) taken right after every `"load"` fires; `nil` after a `url` assignment until that snapshot arrives.
local __WebClient = {}

---@param key string
---@return any
---@protected
function __WebClient:__index(key) end

---@param key string
---@param value any
---@protected
function __WebClient:__newindex(key, value) end

---@return string
---@protected
function __WebClient:__represent() end

---@param width integer? Panel width in pixels. Defaults to `0`.
---@param height integer? Panel height in pixels. Defaults to `0`.
---@protected
function __WebClient:__init(width, height) end

--- Destroys the panel when the object is collected.
---
---@protected
function __WebClient:__gc() end

--- [CLIENT AND MENU]
---
--- Returns the current lifecycle status as a string.
---
---@return WebClient.Status status `"closed"`, `"loading"` or `"ready"`.
---@nodiscard
function __WebClient:getStatus() end

--- [CLIENT AND MENU]
---
--- Returns `true` while the underlying HTML panel still exists.
---
---@return boolean is_valid
---@nodiscard
function __WebClient:__isvalid() end

--- [CLIENT AND MENU]
---
--- Returns `true` when the document is ready for immediate `:run` calls.
---
---@return boolean is_ready
---@nodiscard
function __WebClient:isReady() end

--- [CLIENT AND MENU]
---
--- Returns `true` while a document is loading.
---
---@return boolean is_loading
---@nodiscard
function __WebClient:isLoading() end

--- [CLIENT AND MENU]
---
--- Returns `true` after `:close` / panel removal.
---
---@return boolean is_closed
---@nodiscard
function __WebClient:isClosed() end

--- [CLIENT AND MENU]
---
--- Executes JavaScript in the panel.
---
--- If the document is not ready yet, the snippet is queued and flushed on the next
--- `"ready"` event (required on Chromium, which does not delay `RunJavascript`).
--- On a client that has no document yet (no `url` / `html` assigned), a blank one is started.
---
---@param js string JavaScript source to run.
function __WebClient:run(js) end

--- [CLIENT AND MENU]
---
--- Reloads the current document.
---
---@param ignore_cache boolean? When `true`, bypasses the HTTP cache. Defaults to `false`.
function __WebClient:refresh(ignore_cache) end

--- [CLIENT AND MENU]
---
--- Stops the current navigation / load, if any.
---
function __WebClient:stop() end

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
function __WebClient:bind(path, callback) end

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
function __WebClient:unbind(path) end

--- [CLIENT AND MENU]
---
--- Destroys the panel and fires `"destroy"`. Further methods throw.
---
function __WebClient:close() end

--- [CLIENT AND MENU]
---
--- Alias of `WebClient:close`.
---
function __WebClient:destroy() end

---@alias WebClient.Event
---| "ready" # DOM is ready; safe to run JS immediately.
---| "load" # Document finished loading (resources may still settle).
---| "begin" # Navigation / load started.
---| "console" # `console.*` from the page.
---| "title" # Document title changed.
---| "url" # Address bar / location changed.
---| "message" # Default bridge: `dreamwork.message( channel, payload )` from JS.
---| "destroy" # Panel was closed or removed.

---@alias WebClient.ReadyHandler fun( client: WebClient, url: string )
---@alias WebClient.LoadHandler fun( client: WebClient, url: string )
---@alias WebClient.BeginHandler fun( client: WebClient, url: string )
---@alias WebClient.ConsoleHandler fun( client: WebClient, msg: ( string | nil ), file_name: ( string | nil ), line_nr: ( number | nil ), severity: ( string | nil ) )
---@alias WebClient.TitleHandler fun( client: WebClient, title: ( string | nil ) )
---@alias WebClient.UrlHandler fun( client: WebClient, url: string )
---@alias WebClient.MessageHandler fun( client: WebClient, channel: ( string | nil ), payload: ( string | nil ) )
---@alias WebClient.DestroyHandler fun( client: WebClient )

--- [CLIENT AND MENU]
---
--- Attaches a handler for the given event.
---
---@param event WebClient.Event
---@param handler function
---
---@overload fun( self: WebClient, event: "ready", handler: WebClient.ReadyHandler )
---@overload fun( self: WebClient, event: "load", handler: WebClient.LoadHandler )
---@overload fun( self: WebClient, event: "begin", handler: WebClient.BeginHandler )
---@overload fun( self: WebClient, event: "console", handler: WebClient.ConsoleHandler )
---@overload fun( self: WebClient, event: "title", handler: WebClient.TitleHandler )
---@overload fun( self: WebClient, event: "url", handler: WebClient.UrlHandler )
---@overload fun( self: WebClient, event: "message", handler: WebClient.MessageHandler )
---@overload fun( self: WebClient, event: "destroy", handler: WebClient.DestroyHandler )
function __WebClient:attach(event, handler) end

--- [CLIENT AND MENU]
---
--- Attaches a one-shot handler for the given event.
---
---@param event WebClient.Event
---@param handler function
---
---@overload fun( self: WebClient, event: "ready", handler: WebClient.ReadyHandler )
---@overload fun( self: WebClient, event: "load", handler: WebClient.LoadHandler )
---@overload fun( self: WebClient, event: "begin", handler: WebClient.BeginHandler )
---@overload fun( self: WebClient, event: "console", handler: WebClient.ConsoleHandler )
---@overload fun( self: WebClient, event: "title", handler: WebClient.TitleHandler )
---@overload fun( self: WebClient, event: "url", handler: WebClient.UrlHandler )
---@overload fun( self: WebClient, event: "message", handler: WebClient.MessageHandler )
---@overload fun( self: WebClient, event: "destroy", handler: WebClient.DestroyHandler )
function __WebClient:once(event, handler) end

--- [CLIENT AND MENU]
---
--- Detaches a previously attached handler from the given event.
---
---@param event WebClient.Event
---@param handler function
---
---@overload fun( self: WebClient, event: "ready", handler: WebClient.ReadyHandler )
---@overload fun( self: WebClient, event: "load", handler: WebClient.LoadHandler )
---@overload fun( self: WebClient, event: "begin", handler: WebClient.BeginHandler )
---@overload fun( self: WebClient, event: "console", handler: WebClient.ConsoleHandler )
---@overload fun( self: WebClient, event: "title", handler: WebClient.TitleHandler )
---@overload fun( self: WebClient, event: "url", handler: WebClient.UrlHandler )
---@overload fun( self: WebClient, event: "message", handler: WebClient.MessageHandler )
---@overload fun( self: WebClient, event: "destroy", handler: WebClient.DestroyHandler )
function __WebClient:detach(event, handler) end

--- [CLIENT AND MENU]
---
--- Removes every handler for `event`, or every handler of every event when omitted.
---
---@param event WebClient.Event?
function __WebClient:clear(event) end

--- [CLIENT AND MENU]
---
--- Waits until the given event fires, then resumes with that event's arguments.
---
--- `"ready"` returns immediately on a ready client and `"destroy"` on a closed one.
--- Awaiting any other event throws if the client is closed, or gets closed while waiting.
---
---@param event WebClient.Event
---@return any ...
---@async
---
---@overload fun( self: WebClient, event: "ready" ): WebClient, string
---@overload fun( self: WebClient, event: "load" ): WebClient, string
---@overload fun( self: WebClient, event: "begin" ): WebClient, string
---@overload fun( self: WebClient, event: "console" ): WebClient, ( string | nil ), ( string | nil ), ( number | nil ), ( string | nil )
---@overload fun( self: WebClient, event: "title" ): WebClient, ( string | nil )
---@overload fun( self: WebClient, event: "url" ): WebClient, string
---@overload fun( self: WebClient, event: "message" ): WebClient, ( string | nil ), ( string | nil )
---@overload fun( self: WebClient, event: "destroy" ): WebClient
function __WebClient:await(event) end

--- [CLIENT AND MENU]
---
--- The class used to create new `WebClient` instances.
---
--- Client / menu only. Prefer attaching handlers before navigation settles, or rely on
--- the JS queue inside `:run`.
---
--- ```lua
--- local web = WebClient()
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
---@class WebClientClass : WebClient, Class
---@field __base WebClient
---@overload fun( width: integer?, height: integer? ): WebClient
WebClient = {}
