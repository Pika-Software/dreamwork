---@class dreamwork.engine
local dreamwork_engine = dreamwork.engine
if dreamwork_engine.hook ~= nil then return end

local engine_Player = dreamwork_engine.Player

local std = dreamwork.std

local setmetatable = std.setmetatable

local raw = std.raw
local raw_get = raw.get
local raw_set = raw.set
local raw_pairs = raw.pairs
local raw_select = raw.select

local debug = std.debug
local debug_fempty = debug.fempty
local debug_getmetatable = debug.getmetatable

local string = std.string
local string_format = string.format

local table = std.table
local table_sort = table.sort

local LUA_SERVER = std.LUA_SERVER
local LUA_CLIENT = std.LUA_CLIENT
local LUA_MENU = std.LUA_MENU


--- [SHARED AND MENU]
---
--- The bridge between the game engine events (`GM:*` hooks and game events)
--- and the Dreamwork hook system.
---
---@class dreamwork.engine.hook
local hook = {}
dreamwork_engine.hook = hook


---
--- A callback that can be attached to an engine event.
---
---@alias dreamwork.engine.hook.Handler
---| fun( ...: any ): ...
---| dreamwork.std.Hook
---| dreamwork.std.Event
---| dreamwork.std.Mixin

--- Handlers of each event, sorted by priority (highest first).
---
--- The `0` index holds the handler count, so the array part is `1..handlers[ 0 ]`.
---
---@type table<string, dreamwork.engine.hook.Handler[]>
local hook_handlers = {}

setmetatable( hook_handlers, {
    ---@param self table<string, dreamwork.engine.hook.Handler[]>
    ---@param event_name string
    __index = function( self, event_name )
        local handlers = { [ 0 ] = 0 }
        self[ event_name ] = handlers
        return handlers
    end
} )

---
--- Source engine game events that must be requested via `gameevent.Listen` before they fire.
---
---@see https://wiki.facepunch.com/gmod/gameevent
---@type table<string, boolean>
local source_events = {
    achievement_earned = true,
    achievement_event = true,
    break_breakable = true,
    break_prop = true,
    client_beginconnect = true,
    client_connected = true,
    client_disconnect = true,
    entity_killed = true,
    flare_ignite_npc = true,
    freezecam_started = true,
    game_newmap = true,
    hide_freezepanel = true,
    hltv_cameraman = true,
    hltv_changed_mode = true,
    hltv_changed_target = true,
    hltv_chase = true,
    hltv_fixed = true,
    hltv_message = true,
    hltv_rank_camera = true,
    hltv_rank_entity = true,
    hltv_status = true,
    hltv_title = true,
    host_quit = true,
    OnRequestFullUpdate = true,
    player_activate = true,
    player_changename = true,
    player_connect = true,
    player_connect_client = true,
    player_disconnect = true,
    player_hurt = true,
    player_info = true,
    player_say = true,
    player_spawn = true,
    ragdoll_dissolved = true,
    server_addban = true,
    server_cvar = true,
    server_removeban = true,
    server_spawn = true,
    show_freezepanel = true,
    user_data_downloaded = true,
}

--- Game events that are already being listened to,
--- assigning a new key calls `gameevent.Listen` for it.
---
---@type table<string, boolean>
local listen_events = {}

do

    local gameevent = dreamwork_engine.requireLibrary( "gameevent" )

    ---@type fun( event_name: string )
    local gameevent_Listen = gameevent.Listen or debug_fempty

    ---@type metatable<string, boolean>
    local events_metatable = {}

    ---@param key string The name of the game event.
    ---@protected
    function events_metatable:__newindex( key )
        gameevent_Listen( key )
        raw_set( self, key, true )
    end

    setmetatable( listen_events, events_metatable )

end

--- [SHARED AND MENU]
---
--- This function allows you to enable the listening of engine events from the game engine directly into the Dreamwork hook system.
---
--- > NOTE: Ideally, this function should **never** be used, as the **hook library automatically detects** the need to request these events.
---
--- > NOTE: Use it only if the required event **is missing** in Dreamwork (i.e., check first without calling this function).
---
---@param ... string The names of the game events to listen for.
function hook.listenEvents( ... )
    for i = 1, raw_select( "#", ... ), 1 do
        listen_events[ raw_select( i, ... ) ] = true
    end
end

---@param handlers dreamwork.engine.hook.Handler[]
local function handler_empty( handlers )
    for i = 1, handlers[ 0 ], 1 do
        handlers[ i ]()
    end
end

---@param handlers dreamwork.engine.hook.Handler[]
---@param data table
local function handler_gameevent( handlers, data )
    for i = 1, handlers[ 0 ], 1 do
        handlers[ i ]( data )
    end
end

--- Dispatchers of the supported events, each one calls the attached handlers
--- and decides how their results are combined and returned.
---
--- An event without a dispatcher here cannot be caught.
---
---@type table<string, fun( handlers: dreamwork.engine.hook.Handler[], ...: any ): ...>
local event_handlers = {
    -- engine
    [ "GameContentChanged" ] = handler_empty,
    [ "Think" ] = handler_empty,
    [ "Tick" ] = handler_empty,

    -- gameevents
    [ "achievement_earned" ] = handler_gameevent,
    [ "break_breakable" ] = handler_gameevent,
    [ "break_prop" ] = handler_gameevent,
    [ "entity_killed" ] = handler_gameevent,
    [ "flare_ignite_npc" ] = handler_gameevent,
    [ "hltv_status" ] = handler_gameevent,
    [ "hltv_title" ] = handler_gameevent,
    [ "host_quit" ] = handler_gameevent,
    [ "OnRequestFullUpdate" ] = handler_gameevent,
    [ "player_activate" ] = handler_gameevent,
    [ "player_changename" ] = handler_gameevent,
    [ "player_connect" ] = handler_gameevent,
    [ "player_connect_client" ] = handler_gameevent,
    [ "player_disconnect" ] = handler_gameevent,
    [ "player_hurt" ] = handler_gameevent,
    [ "player_info" ] = handler_gameevent,
    [ "player_say" ] = handler_gameevent,
    [ "player_spawn" ] = handler_gameevent,
    [ "ragdoll_dissolved" ] = handler_gameevent,
    [ "server_addban" ] = handler_gameevent,
    [ "server_cvar" ] = handler_gameevent,
    [ "server_removeban" ] = handler_gameevent,

    -- dreamwork

    --- Handlers may return the number of changed games and addons, the totals are summed.
    ---
    ---@param handlers dreamwork.engine.hook.Handler[]
    ---@return integer total_game_changes
    ---@return integer total_addon_changes
    [ "dreamwork.content.update" ] = function( handlers )
        ---@type integer
        local total_game_changes = 0

        ---@type integer
        local total_addon_changes = 0

        for i = 1, handlers[ 0 ], 1 do
            local game_changes, addon_changes = handlers[ i ]()
            if game_changes ~= nil then
                total_game_changes = total_game_changes + game_changes
            end

            if addon_changes ~= nil then
                total_addon_changes = total_addon_changes + addon_changes
            end
        end

        return total_game_changes, total_addon_changes
    end,
}

--- Handlers may return a replacement error value, which is then passed to the next handlers.
---
---@param handlers dreamwork.engine.hook.Handler[]
---@param error_value dreamwork.std.Error | any The error value.
---@return dreamwork.std.Error | any error_value The final error value.
event_handlers[ "dreamwork.lua.error" ] = function( handlers, error_value )
    for i = 1, handlers[ 0 ], 1 do
        local new_value = handlers[ i ]( error_value )
        if new_value ~= nil then
            error_value = new_value
        end
    end

    return error_value
end

do

    ---@param handlers dreamwork.engine.hook.Handler[]
    ---@param info dreamwork.engine.mounts.GameInfo | dreamwork.engine.mounts.AddonInfo The game or addon that was (un)mounted.
    ---@param is_mounted boolean `true` if the content was mounted, `false` if unmounted.
    local function handler_mount( handlers, info, is_mounted )
        for i = 1, handlers[ 0 ], 1 do
            handlers[ i ]( info, is_mounted )
        end
    end

    event_handlers[ "dreamwork.game.mount" ] = handler_mount
    event_handlers[ "dreamwork.addon.mount" ] = handler_mount

end

do

    ---@param handlers dreamwork.engine.hook.Handler[]
    ---@param vfs_path string The path of the affected VFS node.
    ---@param is_directory boolean `true` if the node is a directory.
    local function handler_vfs( handlers, vfs_path, is_directory )
        for i = 1, handlers[ 0 ], 1 do
            handlers[ i ]( vfs_path, is_directory )
        end
    end

    event_handlers[ "dreamwork.vfs.created" ] = handler_vfs
    event_handlers[ "dreamwork.vfs.deleted" ] = handler_vfs
    event_handlers[ "dreamwork.vfs.modified" ] = handler_vfs

end

---@param handlers dreamwork.engine.hook.Handler[]
---@param mount_path string The VFS path the directory is mounted at.
---@param search_path string The engine search path of the directory.
---@param is_mounted boolean `true` if the directory was mounted, `false` if unmounted.
event_handlers[ "dreamwork.vfs.directory.mount" ] = function( handlers, mount_path, search_path, is_mounted )
    for i = 1, handlers[ 0 ], 1 do
        handlers[ i ]( mount_path, search_path, is_mounted )
    end
end

--- The first handler that returns a non-`nil` value stops the chain.
---
---@param handlers dreamwork.engine.hook.Handler[]
---@param pl garrysmod.Player | nil The player who executed the command, `nil` for the server console.
---@param command string The name of the executed command.
---@param args string[] The parsed arguments.
---@param argument_string string The raw argument string.
---@return boolean is_command_found `true` if a handler took care of the command.
event_handlers[ "dreamwork.console.command.execute" ] = function( handlers, pl, command, args, argument_string )
    for i = 1, handlers[ 0 ], 1 do
        local is_command_found = handlers[ i ]( pl, command, args, argument_string )
        if is_command_found ~= nil then
            return is_command_found
        end
    end

    return false
end

--- The first handler that returns a non-`nil` value stops the chain.
---
---@param handlers dreamwork.engine.hook.Handler[]
---@param name string The name of the command being completed.
---@param argument_string string The raw argument string.
---@param args string[] The parsed arguments.
---@return string[] | nil suggestions The autocomplete suggestions, `nil` if no handler provided any.
event_handlers[ "dreamwork.console.command.autocomplete" ] = function( handlers, name, argument_string, args )
    for i = 1, handlers[ 0 ], 1 do
        local suggestions = handlers[ i ]( name, argument_string, args )
        if suggestions ~= nil then
            return suggestions
        end
    end

    return nil
end

---@param handlers dreamwork.engine.hook.Handler[]
---@param name string The name of the changed console variable.
---@param old_value string The previous value.
---@param new_value string The new value.
event_handlers[ "dreamwork.console.variable.change" ] = function( handlers, name, old_value, new_value )
    for i = 1, handlers[ 0 ], 1 do
        handlers[ i ]( name, old_value, new_value )
    end
end

--- Called for every incoming message before it is routed to a receiver.
---
--- The first handler that returns a non-`nil` value stops the chain:
--- * `true` - the handler has read the whole message, routing is skipped.
--- * `false` - the message is dropped without being read.
--- * `nil` - the message is passed on, the handler must not read from it.
---
---@param handlers dreamwork.engine.hook.Handler[]
---@param network_id integer The ID of the network.
---@param unreliable boolean `true` if the message was sent unreliably.
---@param remaining_bits integer The number of bits left after the header.
---@param sender garrysmod.Player | nil The player who sent the message, `nil` on the client.
---@return boolean | nil verdict `true` if consumed, `false` if dropped, `nil` to route the message.
event_handlers[ "dreamwork.network.message.incoming" ] = function( handlers, network_id, unreliable, remaining_bits, sender )
    for i = 1, handlers[ 0 ], 1 do
        local verdict = handlers[ i ]( network_id, unreliable, remaining_bits, sender )
        if verdict ~= nil then
            return verdict
        end
    end

    return nil
end

--- Called when an incoming message cannot be routed.
---
--- The first handler that returns `true` marks the message as handled and suppresses the default kick (server) or warning (client).
---
---@param handlers dreamwork.engine.hook.Handler[]
---@param network_id integer The ID of the network.
---@param network_name string | nil The name of the network, `nil` if the ID is not registered.
---@param reason "unknown" | "unexpected" `"unknown"` if the ID is not registered, `"unexpected"` if the network has no receiver.
---@param unreliable boolean `true` if the message was sent unreliably.
---@param remaining_bits integer The number of bits left after the header.
---@param sender garrysmod.Player | nil The player who sent the message, `nil` on the client.
---@return boolean is_handled `true` if a handler took care of the message.
event_handlers[ "dreamwork.network.message.unhandled" ] = function( handlers, network_id, network_name, reason, unreliable, remaining_bits, sender )
    for i = 1, handlers[ 0 ], 1 do
        if handlers[ i ]( network_id, network_name, reason, unreliable, remaining_bits, sender ) == true then
            return true
        end
    end

    return false
end

if LUA_SERVER then
    event_handlers[ "hltv_rank_camera" ] = handler_gameevent
    event_handlers[ "hltv_rank_entity" ] = handler_gameevent
end

if LUA_MENU then
    -- permissions
    event_handlers[ "OnPauseMenuBlockedTooManyTimes" ] = handler_empty
    event_handlers[ "OnPermissionsChanged" ] = handler_empty

    -- video/audio capture
    event_handlers[ "CaptureVideo" ] = handler_empty

    -- workshop
    event_handlers[ "WorkshopSubscriptionsChanged" ] = handler_empty
    event_handlers[ "WorkshopStart" ] = handler_empty
    event_handlers[ "WorkshopEnd" ] = handler_empty

    -- menu
    event_handlers[ "MenuStart" ] = handler_empty

    -- gameevents
    event_handlers[ "client_beginconnect" ] = handler_gameevent
    event_handlers[ "client_connected" ] = handler_gameevent
    event_handlers[ "game_newmap" ] = handler_gameevent
    event_handlers[ "server_spawn" ] = handler_gameevent
    event_handlers[ "user_data_downloaded" ] = handler_gameevent
end

if LUA_CLIENT then
    -- 2d render
    event_handlers[ "RenderScreenspaceEffects" ] = handler_empty
    event_handlers[ "PostRenderVGUI" ] = handler_empty
    event_handlers[ "PostDrawHUD" ] = handler_empty
    event_handlers[ "PreDrawHUD" ] = handler_empty
    event_handlers[ "HUDPaint" ] = handler_empty

    -- 3d render
    event_handlers[ "PreDrawViewModels" ] = handler_empty
    event_handlers[ "PostDrawEffects" ] = handler_empty
    event_handlers[ "PreDrawEffects" ] = handler_empty
    event_handlers[ "DrawMonitors" ] = handler_empty

    --- If a handler returns `true`, the remaining handlers are still called, and `true` is returned.
    ---
    ---@param handlers dreamwork.engine.hook.Handler[]
    ---@return boolean | nil should_suppress `true` if any handler requested to suppress the rendering.
    event_handlers[ "PreRender" ] = function( handlers )
        for i = 1, handlers[ 0 ], 1 do
            if handlers[ i ]() then
                for j = i + 1, handlers[ 0 ], 1 do
                    handlers[ j ]()
                end

                return true
            end
        end

        return nil
    end

    event_handlers[ "PostRender" ] = handler_empty

    -- skybox (3d render)
    event_handlers[ "PostDraw2DSkyBox" ] = handler_empty
    event_handlers[ "PostDrawSkyBox" ] = handler_empty

    -- chat
    event_handlers[ "FinishChat" ] = handler_empty
end

if LUA_CLIENT or LUA_MENU then
    -- 2d render
    event_handlers[ "DrawOverlay" ] = handler_empty

    ---@param handlers dreamwork.engine.hook.Handler[]
    ---@param old_width integer The previous screen width in pixels.
    ---@param old_height integer The previous screen height in pixels.
    ---@param new_width integer The new screen width in pixels.
    ---@param new_height integer The new screen height in pixels.
    event_handlers[ "OnScreenSizeChanged" ] = function( handlers, old_width, old_height, new_width, new_height )
        for i = 1, handlers[ 0 ], 1 do
            handlers[ i ]( old_width, old_height, new_width, new_height )
        end
    end

    -- gameevents
    event_handlers[ "achievement_event" ] = handler_gameevent
    event_handlers[ "client_disconnect" ] = handler_gameevent
    event_handlers[ "freezecam_started" ] = handler_gameevent
    event_handlers[ "hide_freezepanel" ] = handler_gameevent
    event_handlers[ "hltv_cameraman" ] = handler_gameevent
    event_handlers[ "hltv_changed_mode" ] = handler_gameevent
    event_handlers[ "hltv_changed_target" ] = handler_gameevent
    event_handlers[ "hltv_chase" ] = handler_gameevent
    event_handlers[ "hltv_fixed" ] = handler_gameevent
    event_handlers[ "hltv_message" ] = handler_gameevent
    event_handlers[ "show_freezepanel" ] = handler_gameevent
end

if LUA_CLIENT or LUA_SERVER then
    -- gamemode
    event_handlers[ "PostGamemodeLoaded" ] = handler_empty
    event_handlers[ "PreGamemodeLoaded" ]  = handler_empty
    event_handlers[ "OnGamemodeLoaded" ]   = handler_empty
    event_handlers[ "OnReloaded" ]         = handler_empty
    event_handlers[ "Initialize" ]         = handler_empty

    --- The first handler that returns a non-`nil` name stops the chain.
    ---
    ---@param handlers dreamwork.engine.hook.Handler[]
    ---@return string | nil name The game description, `nil` if no handler provided one.
    event_handlers[ "GetGameDescription" ] = function( handlers )
        for i = 1, handlers[ 0 ], 1 do
            local name = handlers[ i ]()
            if name ~= nil then
                return name
            end
        end

        return nil
    end


    -- entity
    event_handlers[ "InitPostEntity" ]            = handler_empty
    event_handlers[ "PostCleanupMap" ]            = handler_empty
    event_handlers[ "PreCleanupMap" ]             = handler_empty

    ---@param handlers dreamwork.engine.hook.Handler[]
    ---@param entity garrysmod.Entity The removed entity.
    ---@param is_full_update boolean `true` if the entity was removed because of a full update.
    event_handlers[ "EntityRemoved" ]             = function( handlers, entity, is_full_update )
        is_full_update = is_full_update == true

        for i = 1, handlers[ 0 ], 1 do
            handlers[ i ]( entity, is_full_update )
        end
    end

    ---@param handlers dreamwork.engine.hook.Handler[]
    ---@param entity garrysmod.Entity The spawned entity.
    ---@param is_player boolean `true` if the entity is a player.
    event_handlers[ "dreamwork.entity.spawn" ]    = function( handlers, entity, is_player )
        if not is_player and debug_getmetatable( entity ) == engine_Player then
            is_player = true
        end

        for i = 1, handlers[ 0 ], 1 do
            handlers[ i ]( entity, is_player )
        end
    end

    ---@param handlers dreamwork.engine.hook.Handler[]
    ---@param entity garrysmod.Entity The destroyed entity.
    ---@param is_player boolean `true` if the entity is a player.
    event_handlers[ "dreamwork.entity.destroy" ]  = function( handlers, entity, is_player )
        if not is_player and debug_getmetatable( entity ) == engine_Player then
            is_player = true
        end

        for i = 1, handlers[ 0 ], 1 do
            handlers[ i ]( entity, is_player )
        end
    end

    ---@param handlers dreamwork.engine.hook.Handler[]
    ---@param entity garrysmod.Entity The garbage collected entity.
    event_handlers[ "dreamwork.entity.gc" ]       = function( handlers, entity )
        local is_player = debug_getmetatable( entity ) == engine_Player

        for i = 1, handlers[ 0 ], 1 do
            handlers[ i ]( entity, is_player )
        end
    end

    ---@param handlers dreamwork.engine.hook.Handler[]
    ---@param entities garrysmod.Entity[] The entity registry.
    ---@param entity_count integer The number of entities in the registry.
    event_handlers[ "dreamwork.entity.registry" ] = function( handlers, entities, entity_count )
        for i = 1, handlers[ 0 ], 1 do
            handlers[ i ]( entities, entity_count )
        end
    end

    -- TODO: NetworkEntityCreated


    -- engine
    event_handlers[ "ShutDown" ] = handler_empty


    -- save/load system
    event_handlers[ "Restored" ] = handler_empty
    event_handlers[ "Saved" ]    = handler_empty


    -- gamemode

    --- The first handler that returns a non-`nil` table replaces the gamemode table.
    ---
    ---@param handlers dreamwork.engine.hook.Handler[]
    ---@param name string The name of the selected gamemode.
    ---@param tbl table The gamemode table.
    ---@return table gamemode The replacement table, or `tbl` if no handler provided one.
    event_handlers[ "dreamwork.gamemode.select" ] = function( handlers, name, tbl )
        for i = 1, handlers[ 0 ], 1 do
            local result = handlers[ i ]( name, tbl )
            if result ~= nil then
                return result
            end
        end

        return tbl
    end

end

do

    ---
    --- A handler attached to an event with its sorting keys.
    ---
    ---@class dreamwork.engine.hook.Entry
    ---@field handler dreamwork.engine.hook.Handler The callback function.
    ---@field priority integer The priority of the handler, higher is called first.
    ---@field order integer The registration order, earlier is called first among equal priorities.

    ---
    --- Handler entries of each event by their identifier.
    ---
    ---@type table<string, table<string, dreamwork.engine.hook.Entry>>
    local hook_entries = {}

    setmetatable( hook_entries, {
        ---@param self table<string, table<string, dreamwork.engine.hook.Entry>>
        ---@param event_name string
        __index = function( self, event_name )
            local entries = {}
            self[ event_name ] = entries
            return entries
        end
    } )

    ---
    --- The registration counter, keeps the sorting stable.
    ---
    ---@type integer
    local entry_order = 0

    ---
    --- Sorts entries by priority (highest first), then by registration order.
    ---
    ---@param a dreamwork.engine.hook.Entry
    ---@param b dreamwork.engine.hook.Entry
    local function entries_sort_fn( a, b )
        local a_priority, b_priority = a.priority, b.priority
        if a_priority == b_priority then
            return a.order < b.order
        end

        return a_priority > b_priority
    end

    --- Rebuilds the sorted handler array of the event from its entries.
    ---
    ---@param event_name string
    ---@param entries table<string, dreamwork.engine.hook.Entry>
    local function handlers_rebuild( event_name, entries )
        ---@type dreamwork.engine.hook.Entry[]
        local sorted_entries = {}

        ---@type integer
        local entry_count = 0

        for _, value in raw_pairs( entries ) do
            entry_count = entry_count + 1
            sorted_entries[ entry_count ] = value
        end

        table_sort( sorted_entries, entries_sort_fn )

        -- a new array, so the running calls keep iterating over the old one
        local handlers = { [ 0 ] = entry_count }

        for i = 1, entry_count, 1 do
            handlers[ i ] = sorted_entries[ i ].handler
        end

        hook_handlers[ event_name ] = handlers
    end

    --- [SHARED AND MENU]
    ---
    --- Attaches a handler to an engine event.
    ---
    --- If a handler with the same `identifier` is already attached to the event, it is replaced in place,
    --- keeping its registration order.
    ---
    --- Handlers are called in order of descending `priority`, handlers with equal priority are called in registration order.
    ---
    --- Game events are automatically requested from the engine, see `hook.listenEvents`.
    ---
    --- > NOTE: Raises an error if the event is not supported by Dreamwork.
    ---
    --- > NOTE: Attaching during the event call does not affect the running call, the change applies to the next one.
    ---
    ---@param event_name string The name of the engine event.
    ---@param identifier string The unique identifier of the handler within the event.
    ---@param handler dreamwork.engine.hook.Handler The callback function.
    ---@param priority integer? The priority of the handler, higher is called first. Default is `0`.
    function hook.catch( event_name, identifier, handler, priority )
        if event_handlers[ event_name ] == nil then
            error( string_format( "An attempt to catch a '%s' hook from an engine that does not have a handler; before attach, make sure that this hook is supported!", event_name ), 2 )
        end

        if source_events[ event_name ] ~= nil and listen_events[ event_name ] == nil then
            hook.listenEvents( event_name )
        end

        local entries = hook_entries[ event_name ]

        local entry = entries[ identifier ]
        if entry == nil then
            entry_order = entry_order + 1

            entries[ identifier ] = {
                handler = handler,
                priority = priority or 0,
                order = entry_order
            }
        else
            entry.handler = handler
            entry.priority = priority or 0
        end

        handlers_rebuild( event_name, entries )
    end

    --- [SHARED AND MENU]
    ---
    --- Detaches a handler from an engine event.
    ---
    --- > NOTE: Detaching during the event call does not affect the running call, the change applies to the next one.
    ---
    --- > NOTE: Game events requested from the engine keep being listened to.
    ---
    ---@param event_name string The name of the engine event.
    ---@param identifier string The identifier the handler was attached with.
    ---@return boolean released `true` if the handler was attached and has been removed.
    function hook.release( event_name, identifier )
        local entries = raw_get( hook_entries, event_name )
        if entries == nil or entries[ identifier ] == nil then
            return false
        end

        entries[ identifier ] = nil
        handlers_rebuild( event_name, entries )
        return true
    end

end

--- [SHARED AND MENU]
---
--- Returns the number of handlers attached to an engine event.
---
---@param event_name string The name of the engine event.
---@return integer handler_count The number of attached handlers.
---@nodiscard
function hook.count( event_name )
    local handlers = raw_get( hook_handlers, event_name )
    if handlers == nil then
        return 0
    end

    return handlers[ 0 ]
end

--- [SHARED AND MENU]
---
--- Calls the handlers attached to an engine event.
---
--- Does nothing if the event is not supported.
---
---@param event_name string The name of the engine event.
---@param ... any The arguments passed to the handlers.
---@return any ... The results of the event dispatcher, see the event's documentation.
function hook.call( event_name, ... )
    local fn = event_handlers[ event_name ]
    if fn == nil then return end

    return fn( hook_handlers[ event_name ], ... )
end
