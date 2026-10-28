local _G = _G

---@class dreamwork
local dreamwork = dreamwork
if dreamwork.engine ~= nil then return end

local detour = dreamwork.detour

---@class dreamwork.std
local std = dreamwork.std

local class = std.class

local LUA_SERVER = std.LUA_SERVER
local LUA_CLIENT = std.LUA_CLIENT
local LUA_MENU = std.LUA_MENU

local math = std.math

local debug = std.debug
local debug_fempty = debug.fempty
local debug_getmetatable = debug.getmetatable

local string = std.string
local string_lower = string.lower
local string_format = string.format

local table = std.table
local table_sort = table.sort
local table_concat = table.concat
local table_removeByValue = table.removeByValue

local raw = std.raw
local raw_pairs = raw.pairs
local raw_select = raw.select

local rbit = raw.bit
local rbit_band = rbit.band

local setmetatable = std.setmetatable
local error = std.error
local pcall = std.pcall
local is = std.is


---@class garrysmod.Entity
local EntityMetatable = debug.initmetatable( "Entity" )

---@class garrysmod.Player
local PlayerMetatable = debug.initmetatable( "Player" )
PlayerMetatable.__parent = EntityMetatable

---@class garrysmod.Weapon : garrysmod.Entity
local WeaponMetatable = debug.initmetatable( "Weapon" )
WeaponMetatable.__parent = EntityMetatable

---@class garrysmod.Vehicle : garrysmod.Entity
local VehicleMetatable = debug.initmetatable( "Vehicle" )
VehicleMetatable.__parent = EntityMetatable

---@class garrysmod.NPC : garrysmod.Entity
local NPCMetatable = debug.initmetatable( "NPC" )
NPCMetatable.__parent = EntityMetatable

---@class garrysmod.NextBot : garrysmod.Entity
local NextBotMetatable = debug.initmetatable( "NextBot" )
NextBotMetatable.__parent = EntityMetatable

---@class garrysmod.console.Variable
local ConVarMetatable = debug.initmetatable( "ConVar" )


--- [SHARED AND MENU]
---
--- Source engine library.
---
---@class dreamwork.engine
---@field SupportedGames table<integer, dreamwork.engine.GameInfo> The list of games that are currently supported by the engine.
---@field GameList dreamwork.engine.GameInfo[] The list of currently mounted games.
---@field GameCount integer The length of the `GameList` array (`#GameList`).
---@field GameHash table<integer, dreamwork.engine.GameInfo> The hash of currently mounted games.
---@field AddonList dreamwork.engine.AddonInfo[] The list of currently mounted addons.
---@field AddonCount integer The length of the `AddonList` array (`#AddonList`).
---@field AddonHash table<string, dreamwork.engine.AddonInfo> The hash of currently mounted addons.
---@field NetworkHeaderSize integer The size of the network header in bits.
local engine = {}
dreamwork.engine = engine


--- [SHARED]
---
--- unsigned short ( 2 byte / 16 bit / 0-65535, 0 is reserved )
---
--- wiki says that we have only 4095 slots...
--- i don't care, i will use absolute header limit
--- because f*ck you garry
---
--- it have additional bit for unreliable flag so it will be 17 bits in total
---
---@type integer
engine.NetworkHeaderSize = 16 + 1

---@param name string
---@return table
local function glua_library( name )
    local lib = _G[ name ]
    if lib == nil then
        lib = {}
        _G[ name ] = lib
    end

    return lib
end


do

    ---@alias dreamwork.engine.hook.Handler
    ---| fun( ...: any ): ...
    ---| dreamwork.std.Hook
    ---| dreamwork.std.Mixin

    ---@type table<string, dreamwork.engine.hook.Handler[]>
    local hook_handlers = {}

    setmetatable( hook_handlers, {
        ---@param event_name string
        __index = function( self, event_name )
            local handlers = { [ 0 ] = 0 }
            self[ event_name ] = handlers
            return handlers
        end
    } )

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

    ---@type table<string, boolean>
    local listen_events = {}

    do

        local listen_event

        ---@class dreamwork.GModGameEventLib
        ---@field Listen fun( event_name: string )
        ---@diagnostic disable-next-line: undefined-global
        local gameevent = gameevent

        if gameevent ~= nil and gameevent.Listen ~= nil then
            listen_event = gameevent.Listen
        else
            listen_event = debug_fempty
        end

        ---@cast listen_event fun( event_name: string )

        ---@type metatable<string, boolean>
        local events_metatable = {}

        function events_metatable:__newindex( key )
            listen_event( key )
        end

        std.setmetatable( listen_events, events_metatable )

    end

    --- [SHARED AND MENU]
    ---
    --- This function allows you to enable the listening of engine events from the game engine directly into the Dreamwork hook system.
    ---
    --- Note: Ideally, this function should **never** be used, as the **hook library automatically detects** the need to request these events.
    ---
    --- Note: Use it only if the required event **is missing** in Dreamwork (i.e., check first without calling this function).
    ---
    ---@param ... string The names of the events to listen for.
    function engine.hookListenEvents( ... )
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

        ---@param handlers dreamwork.engine.hook.Handler[]
        ---@return integer, integer
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

    ---@param handlers dreamwork.engine.hook.Handler[]
    ---@param error_value dreamwork.std.Error | any
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
        ---@param info dreamwork.engine.GameInfo | dreamwork.engine.AddonInfo
        ---@param is_mounted boolean
        local function handler_mount( handlers, info, is_mounted )
            for i = 1, handlers[ 0 ], 1 do
                handlers[ i ]( info, is_mounted )
            end
        end

        event_handlers[ "dreamwork.game.mount" ] = handler_mount
        event_handlers[ "dreamwork.addon.mount" ] = handler_mount

    end

    ---@param handlers dreamwork.engine.hook.Handler[]
    ---@param command string
    ---@param pl garrysmod.Player | nil
    ---@param args string[]
    ---@param argument_string string
    ---@return boolean
    event_handlers[ "dreamwork.console.command.execute" ] = function( handlers, command, pl, args, argument_string )
        for i = 1, handlers[ 0 ], 1 do
            local is_command_found = handlers[ i ]( command, pl, args, argument_string )
            if is_command_found ~= nil then
                return is_command_found
            end
        end

        return false
    end

    ---@param handlers dreamwork.engine.hook.Handler[]
    ---@param name string
    ---@param argument_string string
    ---@param args string[]
    ---@return boolean | nil
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
    ---@param name string
    ---@param old_value string
    ---@param new_value string
    event_handlers[ "dreamwork.console.variable.change" ] = function( handlers, name, old_value, new_value )
        for i = 1, handlers[ 0 ], 1 do
            handlers[ i ]( name, old_value, new_value )
        end
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

        ---@param handlers dreamwork.engine.hook.Handler[]
        ---@return boolean | nil
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
        ---@param old_width integer
        ---@param old_height integer
        ---@param new_width integer
        ---@param new_height integer
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

        ---@param handlers dreamwork.engine.hook.Handler[]
        ---@return string | nil
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
        ---@param entity garrysmod.Entity
        ---@param is_full_update boolean
        event_handlers[ "EntityRemoved" ]             = function( handlers, entity, is_full_update )
            is_full_update = is_full_update == true

            for i = 1, handlers[ 0 ], 1 do
                handlers[ i ]( entity, is_full_update )
            end
        end

        ---@param handlers dreamwork.engine.hook.Handler[]
        ---@param entity garrysmod.Entity
        ---@param is_player boolean
        event_handlers[ "dreamwork.entity.spawn" ]    = function( handlers, entity, is_player )
            if not is_player and debug_getmetatable( entity ) == PlayerMetatable then
                is_player = true
            end

            for i = 1, handlers[ 0 ], 1 do
                handlers[ i ]( entity, is_player )
            end
        end

        ---@param handlers dreamwork.engine.hook.Handler[]
        ---@param entity garrysmod.Entity
        ---@param is_player boolean
        event_handlers[ "dreamwork.entity.destroy" ]  = function( handlers, entity, is_player )
            if not is_player and debug_getmetatable( entity ) == PlayerMetatable then
                is_player = true
            end

            for i = 1, handlers[ 0 ], 1 do
                handlers[ i ]( entity, is_player )
            end
        end

        event_handlers[ "dreamwork.entity.gc" ]       = function( handlers, entity )
            local is_player = debug_getmetatable( entity ) == PlayerMetatable

            for i = 1, handlers[ 0 ], 1 do
                handlers[ i ]( entity, is_player )
            end
        end

        ---@param handlers dreamwork.engine.hook.Handler[]
        ---@param entities garrysmod.Entity[]
        ---@param entity_count integer
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


        -- network

        ---@param handlers dreamwork.engine.hook.Handler[]
        ---@param network_id integer
        ---@param unreliable boolean
        ---@param remaining_bits integer
        ---@param sender garrysmod.Player | nil
        ---@return boolean
        event_handlers[ "dreamwork.network.message.incoming" ] = function( handlers, network_id, unreliable, remaining_bits, sender )
            for i = 1, handlers[ 0 ], 1 do
                if handlers[ i ]( network_id, unreliable, remaining_bits, sender ) then return true end
            end

            return false
        end


        -- gamemode

        ---@param handlers dreamwork.engine.hook.Handler[]
        ---@param name string
        ---@param tbl table
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

        ---@type table<string, table<dreamwork.engine.hook.Handler, integer>>
        local hook_priorities = {}

        setmetatable( hook_priorities, {
            __index = function( self, handler )
                local priorities = {}
                self[ handler ] = priorities
                return priorities
            end
        } )

        ---@type table<dreamwork.engine.hook.Handler, integer>
        local priorities

        ---@param a dreamwork.engine.hook.Handler
        ---@param b dreamwork.engine.hook.Handler
        local function handlers_sort_fn( a, b )
            return priorities[ a ] > priorities[ b ]
        end

        ---@type table<string, table<string, dreamwork.engine.hook.Handler>>
        local hook_identifiers = {}

        setmetatable( hook_identifiers, {
            ---@param event_name string
            __index = function( self, event_name )
                local identifiers = {}
                self[ event_name ] = identifiers
                return identifiers
            end
        } )

        --- [SHARED AND MENU]
        ---
        --- Adds a callback to the `hookCatch` event.
        ---
        ---@param event_name string The name of the source engine event.
        ---@param identifier string
        ---@param handler dreamwork.std.Hook | fun( ... ): ... The callback function.
        ---@param priority? integer The index to insert the callback at.
        function engine.hookCatch( event_name, identifier, handler, priority )
            if event_handlers[ event_name ] == nil then
                error( string.format( "An attempt to catch a '%s' hook from an engine that does not have a handler; before attach, make sure that this hook is supported!", event_name ), 2 )
            end

            if source_events[ event_name ] ~= nil and listen_events[ event_name ] == nil then
                engine.hookListenEvents( event_name )
            end

            local identifiers = hook_identifiers[ event_name ]
            local handlers = hook_handlers[ event_name ]

            priorities = hook_priorities[ event_name ]
            priorities[ handler ] = priority or 0

            local existing_handler = identifiers[ identifier ]
            if existing_handler == nil then
                local handler_count = handlers[ 0 ] + 1
                handlers[ handler_count ] = handler
                handlers[ 0 ] = handler_count
            elseif existing_handler ~= handler then
                priorities[ existing_handler ] = nil

                local handler_count = handlers[ 0 ]

                if table_removeByValue( handlers, existing_handler, handler_count ) == nil then
                    handler_count = handler_count + 1
                end

                handlers[ handler_count ] = handler
                handlers[ 0 ] = handler_count
            end

            identifiers[ identifier ] = handler
            table_sort( handlers, handlers_sort_fn )
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Calls a source engine event.
    ---
    ---@param event_name string
    ---@param ... any
    ---@return any, any, any, any
    function engine.hookCall( event_name, ... )
        local fn = event_handlers[ event_name ]
        if fn == nil then return end

        return fn( hook_handlers[ event_name ], ... )
    end

end

local engine_hookCatch = engine.hookCatch
local engine_hookCall = engine.hookCall

do

    local hook = glua_library( "hook" )

    local hook_Call = hook.Call
    if hook_Call == nil then
        function hook.Call( event_name, _, ... )
            return engine_hookCall( event_name, ... )
        end
    else
        function hook.Call( event_name, tbl, ... )
            local a, b, c, d = engine_hookCall( event_name, ... )
            if a == nil then
                return hook_Call( event_name, tbl, ... )
            else
                return a, b, c, d
            end
        end
    end

end

do

    ---@type table[]
    local queue = {}

    ---@type integer
    local queue_size = 0

    --- [SHARED AND MENU]
    ---
    --- Calls a function on the next tick.
    ---
    ---@param fn function
    ---@param ... any
    function engine.waitNextTick( fn, ... )
        queue_size = queue_size + 1
        queue[ queue_size ] = { fn, ... }
    end

    engine_hookCatch( "Tick", "engine.waitNextTick", function()
        if queue_size == 0 then
            return nil
        end

        for i = 1, queue_size, 1 do
            local data = queue[ i ]
            data[ 1 ]( data[ 2 ], data[ 3 ], data[ 4 ], data[ 5 ], data[ 6 ] )
        end

        queue_size = 0
        queue = {}

        return nil
    end, -1000 )

end

do

    local entity_metatables = {
        EntityMetatable,
        PlayerMetatable,
        WeaponMetatable,
        VehicleMetatable,
        NPCMetatable,
        NextBotMetatable,
    }

    for i = 1, #entity_metatables, 1 do
        local metatable = entity_metatables[ i ]
        metatable.__gc = detour.before( function( entity_userdata )
            engine_hookCall( "dreamwork.entity.gc", entity_userdata )
        end, metatable.__gc )
    end

end

if LUA_CLIENT or LUA_SERVER then

    ---@class dreamwork.std.gc
    local gc = std.gc

    local raw_set = raw.set

    ---@alias dreamwork.std.gc.Type "Entity" | "EntityID" | "Player" | "UserID" | "AccountID"

    ---@alias dreamwork.std.gc.Instruction fun( object: any ): any

    ---@type table<string, table>
    local track_list = {}

    ---@type table<table, dreamwork.std.gc.Instruction>
    local track_instructions = {}

    std.setmetatable( track_list, {
        ---@param self table<string, table>
        ---@param type_name dreamwork.std.gc.Type
        __index = function( self, type_name )
            local tables = {
                [ 0 ] = 0,
            }

            gc.setTableRules( tables, false, true )

            self[ type_name ] = tables
            return tables
        end
    } )

    --- [SHARED AND MENU]
    ---
    --- Sets up garbage collection for the given table by type.
    ---
    ---@param tbl table
    ---@param type_name dreamwork.std.gc.Type
    ---@param instruction dreamwork.std.gc.Instruction | nil
    function gc.setup( tbl, type_name, instruction )
        local tables = track_list[ type_name ]
        local record_count = tables[ 0 ] + 1

        tables[ record_count ] = tbl
        tables[ 0 ] = record_count

        track_instructions[ tbl ] = instruction
    end

    ---@param record_type dreamwork.std.gc.Type
    ---@param object any
    local function object_destroyed( record_type, object )
        local tables = track_list[ record_type ]
        local record_count = tables[ 0 ]

        for i = record_count, 1, -1 do
            local tbl = tables[ i ]
            if tbl ~= nil then
                local key

                local fn = track_instructions[ tbl ]
                if fn ~= nil then
                    key = fn( object )
                end

                raw_set( tbl, key or object, nil )
            end
        end

        tables[ 0 ] = record_count
    end

    do

        local Player_AccountID = PlayerMetatable.AccountID
        local Player_UserID = PlayerMetatable.UserID
        local Player_IsBot = PlayerMetatable.IsBot

        local Entity_EntIndex = EntityMetatable.EntIndex

        engine_hookCatch( "EntityRemoved", "gc.setup", function( entity )
            object_destroyed( "Entity", entity )
            object_destroyed( "EntityID", Entity_EntIndex( entity ) )

            if is( entity, PlayerMetatable ) then
                ---@cast entity garrysmod.Player

                object_destroyed( "Player", entity )
                object_destroyed( "UserID", Player_UserID( entity ) )

                if not Player_IsBot( entity ) then
                    object_destroyed( "AccountID", Player_AccountID( entity ) )
                end
            end
        end, -1000 )

    end

end

if std.LUA_MENU then

    ---@diagnostic disable-next-line: inject-field
    _G.ListAddonPresets = detour.before( function()
        ---@diagnostic disable-next-line: undefined-field
        engine_hookCall( "dreamwork.addon.presets", (_G.LoadAddonPresets or debug_fempty)() )
    end, _G.ListAddonPresets )

    ---@param server_name string
    ---@param loading_url string
    ---@param map_name string
    ---@param max_players integer
    ---@param player_steamid64 string
    ---@param gamemode_name string
    ---@diagnostic disable-next-line: inject-field
    _G.GameDetails = detour.before( function( server_name, loading_url, map_name, max_players, player_steamid64, gamemode_name )
        engine_hookCall( "dreamwork.server.details", {
            server_name = server_name,
            loading_url = loading_url,
            map_name = map_name,
            max_players = max_players,
            player_steamid64 = player_steamid64,
            gamemode_name = gamemode_name
        } )
    end, _G.GameDetails )

end

do

    ---@class garrysmod.concommand
    local concommand = glua_library( "concommand" )

    local fallback_exists = concommand.Run ~= nil

    ---@param ply garrysmod.Player
    ---@param cmd string
    ---@param args string[]
    ---@param argument_string string
    concommand.Run = detour.simple( function( ply, cmd, args, argument_string )
        local is_command_found = engine_hookCall( "dreamwork.console.command.execute", ply, cmd, args, argument_string ) == true
        if not is_command_found then
            if fallback_exists then
                return nil
            end

            dreamwork.Logger:error( "Catched attempt to run unknown console command '%s %s' by %s.", cmd, argument_string or "", ply )
        end

        return is_command_found
    end, concommand.Run )

    ---@param cmd string
    ---@param argument_string string
    ---@param args string[]
    ---@return string[] | nil
    concommand.AutoComplete = detour.simple( function( cmd, argument_string, args )
        return engine_hookCall( "dreamwork.console.command.autocomplete", cmd, argument_string, args )
    end, concommand.AutoComplete )

end

if engine.consoleCommandRegister == nil or engine.consoleCommandExists == nil or engine.consoleCommandBlocked == nil then

    local IsConCommandBlocked = _G.IsConCommandBlocked or function() return false end
    local AddConsoleCommand = _G.AddConsoleCommand or debug_fempty

    ---@type table<string, boolean>
    local exists_commands = {}

    ---@type table<string, boolean>
    local blocked_commands = {}

    setmetatable( blocked_commands, {
        ---@param self table<string, boolean>
        ---@param name string
        __index = function( self, name )
            local is_blocked = IsConCommandBlocked( name ) == true
            self[ name ] = is_blocked
            return is_blocked
        end,
    } )

    --- [SHARED AND MENU]
    ---
    --- Checks if the console command was registered through `engine.consoleCommandRegister`.
    ---
    --- This only knows about commands registered through this module, not commands that are
    --- built into the engine or were added by other code, so a `false` result doesn't mean the
    --- command doesn't exist in the engine.
    ---
    ---@param name string The name of the console command.
    ---@return boolean exists `true` if the console command was registered through this module, `false` otherwise.
    function engine.consoleCommandExists( name )
        return exists_commands[ name ] ~= nil
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if the console command is blocked, as reported by the engine's
    --- `IsConCommandBlocked` (the engine's list of commands it refuses to run from Lua).
    ---
    --- The answer for each name is cached after the first check. Where `IsConCommandBlocked`
    --- isn't available, nothing is considered blocked.
    ---
    ---@param name string The name of the console command.
    ---@return boolean blocked `true` if the console command is blocked, `false` otherwise.
    function engine.consoleCommandBlocked( name )
        return blocked_commands[ name ]
    end

    --- [SHARED AND MENU]
    ---
    --- Tells the engine to register a console command.
    ---
    --- Registering is only done once per name: if the command was already registered through
    --- this function, the call does nothing, and the new `description` and `flags` are ignored.
    ---
    ---@param name string The name of the console command.
    ---@param description string The description of the console command.
    ---@param flags integer The bit flags of the console command (a combination of `FCVAR_*` values).
    function engine.consoleCommandRegister( name, description, flags )
        if exists_commands[ name ] == nil then
            AddConsoleCommand( name, description, flags )
            exists_commands[ name ] = true
        end
    end

end

if engine.consoleCommandRun == nil then

    --- [SHARED AND MENU]
    ---
    --- Run console command.
    ---
    ---@param name string The name of the console command.
    ---@param ... string? The arguments of the console command.
    ---@diagnostic disable-next-line: undefined-field
    engine.consoleCommandRun = _G.RunConsoleCommand or function( name, ... )
        raw.print( "dreamwork.engine.consoleCommandRun", name, ... )
    end

end

do

    local ConVarExists = _G.ConVarExists or debug_fempty
    local CreateConVar = _G.CreateConVar or debug_fempty

    local GetConVar
    local RemoveConVar
    local SetConVar

    local cvar = _G.cvar
    if cvar ~= nil then
        GetConVar = cvar.Find
        RemoveConVar = cvar.Unregister
        SetConVar = cvar.SetValue
    end

    if GetConVar == nil then
        GetConVar = _G.GetConVar_Internal or _G.GetConVar or debug_fempty
    end

    if RemoveConVar == nil then
        RemoveConVar = debug_fempty
    end

    --- [SHARED AND MENU]
    ---
    --- A registry of used console variables, mapped by their names to their ConVar objects (engine `userdata`).
    ---
    ---@type table<string, garrysmod.console.Variable>
    local console_variables = {}

    if SetConVar == nil then

        local engine_consoleCommandBlocked = engine.consoleCommandBlocked
        local engine_consoleCommandRun = engine.consoleCommandRun

        local ConVar_GetString = ConVarMetatable.GetString
        local ConVar_SetString = ConVarMetatable.SetString

        ---@param name string
        ---@param value string
        ---@return boolean success
        function SetConVar( name, value )
            if engine_consoleCommandBlocked( name ) then
                return false
            end

            local variable = console_variables[ name ]
            if variable ~= nil then
                if not pcall( ConVar_SetString, variable, value ) then
                    engine_consoleCommandRun( name, value )
                end

                return ConVar_GetString( variable ) == value
            end

            return false
        end

    end

    ---@type metatable<string, garrysmod.console.Variable>
    local metatable = {
        __mode = "v"
    }

    ---@type table<string, boolean>
    local blacklist = {}

    function metatable:__index( name )
        if blacklist[ name ] then
            return nil
        end

        local console_variable = GetConVar( name )
        if console_variable == nil then
            if ConVarExists( name ) then
                blacklist[ name ] = true
            end

            return nil
        end

        console_variables[ name ] = console_variable

        return console_variable
    end

    std.setmetatable( console_variables, metatable )

    engine.ConsoleVariables = console_variables

    --- [SHARED AND MENU]
    ---
    --- Gets a console variable's C object (userdata) by name.
    ---
    --- Existing console variables are loaded from the engine on first use and cached. Returns
    --- `nil` if no such console variable exists, or if it exists but the engine doesn't hand out
    --- its object.
    ---
    ---@see dreamwork.engine.consoleVariableCreate
    ---@see dreamwork.engine.consoleVariableRemove
    ---@see dreamwork.engine.consoleVariableExists
    ---
    ---@param name string The name of the console variable.
    ---@return garrysmod.console.Variable? cvar The console variable object, or `nil`.
    function engine.consoleVariableGet( name )
        return console_variables[ name ]
    end

    --- [SHARED AND MENU]
    ---
    --- Creates a console variable and returns its C object (userdata).
    ---
    --- If a console variable with this name is already available through the registry, that
    --- existing object is returned as is and `default`, `flags`, `description`, `min` and `max`
    --- are ignored. Since the registry loads existing console variables lazily, this also
    --- covers ones that already exist in the engine.
    ---
    --- Raises an error (reported at the caller's level) if the engine has a console variable
    --- with this name but its object can't be obtained, or if the engine refuses to create it.
    ---
    ---@see dreamwork.engine.consoleVariableGet
    ---@see dreamwork.engine.consoleVariableRemove
    ---@see dreamwork.engine.consoleVariableExists
    ---
    ---@param name string The name of the console variable.
    ---@param default string The default value of the console variable.
    ---@param flags? integer The flags of the console variable (a combination of `FCVAR_*` values).
    ---@param description? string The description of the console variable.
    ---@param min? number The minimum value of the console variable.
    ---@param max? number The maximum value of the console variable.
    ---@return garrysmod.console.Variable cvar The console variable object.
    function engine.consoleVariableCreate( name, default, flags, description, min, max )
        ---@type garrysmod.console.Variable | nil
        local variable = console_variables[ name ]
        if variable == nil then
            if ConVarExists( name ) then
                error( "console variable creation failed, already exists", 2 )
            end

            variable = CreateConVar( name, default, flags, description, min, max )
            if variable == nil then
                error( "console variable creation failed, restricted by the engine", 2 )
            end

            console_variables[ name ] = variable
        end

        return variable
    end

    --- [SHARED AND MENU]
    ---
    --- Removes a console variable that was registered through the engine module.
    ---
    --- Only variables tracked in the module's `console_variables` registry can be removed. If
    --- `name` isn't in it, nothing is touched and `false` is returned, so built-in console
    --- variables and ones created elsewhere are protected from this function.
    ---
    --- Otherwise the variable is removed from the engine, and the result tells you whether
    --- the removal actually took effect: `true` if the console variable no longer exists
    --- afterwards, `false` if it is still there.
    ---
    ---@see dreamwork.engine.consoleVariableGet
    ---@see dreamwork.engine.consoleVariableCreate
    ---@see dreamwork.engine.consoleVariableExists
    ---
    ---@param name string The name of the console variable.
    ---@return boolean success `true` if the console variable no longer exists after the call, `false` if it wasn't registered here or couldn't be removed.
    function engine.consoleVariableRemove( name )
        if console_variables[ name ] == nil then
            return false
        end

        -- console_variables[ name ] = nil
        RemoveConVar( name )

        return not ConVarExists( name )
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if a console variable with the given name exists, whether it was registered
    --- through the engine module or comes from the engine itself.
    ---
    --- Unlike `engine.consoleVariableRemove`, which only acts on variables in the module's
    --- `console_variables` registry, this also reports built-in console variables and ones
    --- created elsewhere, since it falls back to the engine's own `ConVarExists` check.
    ---
    ---@see dreamwork.engine.consoleVariableGet
    ---@see dreamwork.engine.consoleVariableCreate
    ---@see dreamwork.engine.consoleVariableRemove
    ---
    ---@param name string The name of the console variable.
    ---@return boolean exists `true` if the console variable is registered in the module or exists in the engine, `false` otherwise.
    function engine.consoleVariableExists( name )
        return console_variables[ name ] ~= nil or ConVarExists( name )
    end

    local raw_get = raw.get

    --- Names of known Source engine and Garry's Mod console variables.
    ---@type string[]
    local engine_variables = {
        -- server
        "hostname", "hostport", "hostip", "sv_password", "rcon_password", "sv_lan", "sv_region",
        "sv_tags", "sv_contact", "sv_visiblemaxplayers", "sv_loadingurl", "sv_downloadurl",
        "sv_allowupload", "sv_allowdownload", "sv_allowcslua", "sv_cheats", "sv_pausable",
        "sv_hibernate_think", "sv_timeout", "sv_kickerrornum", "sv_logecho", "sv_logfile",
        "sv_log_onefile", "sv_logbans", "sv_rcon_banpenalty", "sv_rcon_maxfailures",
        "sv_rcon_minfailures", "sv_rcon_minfailuretime", "sv_skyname", "gamemode",
        "skill", "deathmatch", "coop",

        -- networking
        "sv_minrate", "sv_maxrate", "sv_mincmdrate", "sv_maxcmdrate", "sv_minupdaterate",
        "sv_maxupdaterate", "sv_client_min_interp_ratio", "sv_client_max_interp_ratio",
        "sv_unlag", "sv_maxunlag", "net_maxfilesize",
        "rate", "cl_cmdrate", "cl_updaterate", "cl_interp", "cl_interp_ratio",
        "cl_predict", "cl_smooth", "cl_timeout", "cl_downloadfilter",

        -- movement & physics
        "sv_gravity", "sv_friction", "sv_stopspeed", "sv_accelerate", "sv_airaccelerate",
        "sv_wateraccelerate", "sv_waterfriction", "sv_maxvelocity", "sv_stepsize", "sv_bounce",
        "sv_rollangle", "sv_rollspeed", "sv_noclipspeed", "sv_noclipaccelerate",
        "sv_specaccelerate", "sv_specspeed", "sv_specnoclip", "sv_sticktoground",
        "sv_footsteps", "sv_playerpickupallowed", "sv_defaultdeployspeed",
        "sv_infinite_aux_power", "sv_robust_explosions",
        "phys_timescale", "phys_pushscale", "phys_impactforcescale", "phys_upimpactforcescale",
        "gmod_physiterations", "host_timescale", "host_framerate",

        -- gameplay
        "mp_falldamage", "mp_flashlight", "mp_footsteps", "mp_friendlyfire", "mp_forcecamera",
        "mp_timelimit", "mp_fraglimit", "mp_decals", "mp_show_voice_icons",
        "sv_alltalk", "sv_voiceenable", "sv_voicecodec",
        "ai_disabled", "ai_ignoreplayers", "ai_serverragdolls", "g_ragdoll_maxcount",
        "gmod_suit", "gmod_maxammo", "gmod_npcweapon",

        -- physgun
        "physgun_limited", "physgun_maxrange", "physgun_maxspeed", "physgun_maxangular",
        "physgun_timetoarrive", "physgun_DampingFactor", "physgun_teleportDistance",
        "physgun_wheelspeed", "physgun_halo", "physgun_drawbeams",

        -- sandbox
        "sbox_noclip", "sbox_godmode", "sbox_playershurtplayers", "sbox_weapons", "sbox_persist",
        "sbox_bonemanip_npc", "sbox_bonemanip_player", "sbox_bonemanip_misc",
        "sbox_maxprops", "sbox_maxragdolls", "sbox_maxvehicles", "sbox_maxeffects",
        "sbox_maxballoons", "sbox_maxnpcs", "sbox_maxdynamite", "sbox_maxlamps", "sbox_maxlights",
        "sbox_maxwheels", "sbox_maxthrusters", "sbox_maxhoverballs", "sbox_maxbuttons",
        "sbox_maxemitters", "sbox_maxsents", "sbox_maxcameras", "sbox_maxconstraints",
        "sbox_maxropeconstraints",

        -- player
        "name", "cl_playermodel", "cl_playercolor", "cl_weaponcolor", "cl_playerskin",
        "cl_playerbodygroups", "gmod_language", "gmod_toolmode", "gmod_drawhelp",
        "gmod_drawtooleffects",

        -- input
        "sensitivity", "m_pitch", "m_yaw", "m_filter", "m_rawinput",
        "cl_forwardspeed", "cl_sidespeed", "cl_backspeed", "cl_upspeed",
        "cl_yawspeed", "cl_pitchspeed",

        -- audio & voice
        "volume", "snd_musicvolume", "voice_enable", "voice_scale", "voice_loopback",

        -- video & rendering
        "fps_max", "fov_desired", "cl_drawhud", "cl_showfps", "cl_showpos", "net_graph",
        "cl_new_impact_effects", "mat_fullbright", "mat_wireframe", "mat_monitorgamma",
        "mat_picmip", "mat_specular", "mat_bloomscale", "mat_hdr_level", "mat_queue_mode",
        "r_3dsky", "r_drawviewmodel", "r_shadows", "r_decals", "r_drawdetailprops", "r_lod",
        "r_rootlod", "r_eyes", "r_teeth", "r_flex", "r_dynamic", "r_waterforceexpensive",
        "r_queued_ropes",

        -- multicore
        "gmod_mcore_test", "cl_threaded_bone_setup", "cl_threaded_client_leaf_system",
        "studio_queue_mode",

        -- console
        "developer", "con_enable", "con_drawnotify", "con_filter_enable",
        "con_filter_text", "con_filter_text_out"
    }

    local engine_variable_count = #engine_variables

    --- [SHARED AND MENU]
    ---
    --- Gets the names of all console variables known to the engine module.
    ---
    --- Lua can't enumerate the engine's console variables, so the result is assembled from
    --- two sources:
    ---
    --- * a built-in list of known Source engine and Garry's Mod console variables, filtered
    --- to the ones that exist in the current realm;
    --- * every console variable in the module's `console_variables` registry, that is, ones
    --- created with `engine.consoleVariableCreate` or loaded through `engine.consoleVariableGet`.
    ---
    --- Each name appears at most once. Console variables created elsewhere and never looked up
    --- through the module (e.g. by other addons via `CreateConVar`) are not included unless
    --- they're on the built-in list. The order of the names is not specified.
    ---
    ---@see dreamwork.engine.consoleVariableGet
    ---@see dreamwork.engine.consoleVariableExists
    ---
    ---@return string[] variables The names of the console variables.
    ---@return integer variable_count The number of names in `variables`.
    function engine.consoleVariableGetAll()
        local variables = {}
        local variable_count = 0

        for i = 1, engine_variable_count, 1 do
            local name = engine_variables[ i ]
            if raw_get( console_variables, name ) == nil and ConVarExists( name ) then
                variable_count = variable_count + 1
                variables[ variable_count ] = name
            end
        end

        for name in raw_pairs( console_variables ) do
            variable_count = variable_count + 1
            variables[ variable_count ] = name
        end

        return variables, variable_count
    end

end

do

    ---@class garrysmod.cvars
    local cvars = glua_library( "cvars" )

    ---@param name string
    ---@param old_value string
    ---@param new_value string
    cvars.OnConVarChanged = detour.before( function( name, old_value, new_value )
        engine_hookCall( "dreamwork.console.variable.change", name, old_value, new_value )
    end, cvars.OnConVarChanged )

end

do

    ---@class dreamwork.engine.ColorProxy : dreamwork.std.Object
    local ColorProxy = class.base( "dreamwork.engine.ColorProxy", false )

    ---@protected
    function ColorProxy:__init( r, g, b, a )
        self.r = r or 0
        self.g = g or 0
        self.b = b or 0
        self.a = a or 255
    end

    ---@protected
    ---@return string
    function ColorProxy:__tostring()
        return string.format( "ColorProxy(%d, %d, %d, %d)", self.r, self.g, self.b, self.a )
    end

    local color_toRGB = std.color.toRGB

    ---@type table<dreamwork.engine.ColorProxy, dreamwork.std.Color>
    local cache = {}
    std.gc.setTableRules( cache, true, false )

    --- [SHARED AND MENU]
    ---
    --- Updates the color proxy with a new color.
    ---
    ---@param clr dreamwork.std.Color
    function ColorProxy:update( clr )
        if cache[ self ] == clr then return end

        self.r, self.g, self.b = color_toRGB( clr )
        cache[ self ] = clr
    end

    ---@class dreamwork.engine.ColorProxyClass : dreamwork.engine.ColorProxy
    ---@overload fun(r: number, g: number, b: number, a: number): dreamwork.engine.ColorProxy
    std.ColorProxy = class.create( ColorProxy )

end

do

    ---@type fun( data: integer[][] ) | nil
    ---@diagnostic disable-next-line: undefined-field
    local Matrix = _G.Matrix
    if Matrix ~= nil then

        -- ---@class dreamwork.engine.VMatrixProxy : dreamwork.std.Object
        -- local VMatrixProxy = class.base( "dreamwork.engine.VMatrixProxy", true )

        -- function VMatrixProxy:update()

        -- end

        -- ---@class dreamwork.engine.VMatrixProxyClass : dreamwork.engine.VMatrixProxy
        -- ---@overload fun(): dreamwork.engine.VMatrixProxy
        -- local VMatrixProxyClass = class.create( VMatrixProxy )

        -- local VMatrix = Matrix

        -- function VMatrixProxyClass:__new()
        --     return VMatrix()
        -- end

        -- TODO: VMatrixProxy

    end

end


do

    ---@type table<string, string>
    local values = {}

    engine_hookCatch( "server_cvar", "dreamwork.console.variable.change", function( data )
        local name, new_value = data.cvarname, data.cvarvalue
        local old_value = values[ name ]

        if old_value == nil then
            local variable = engine.consoleVariableGet( name )
            if variable ~= nil then
                old_value = variable:GetDefault()
            end

            values[ name ] = old_value or ""
        else
            values[ name ] = new_value
        end

        engine_hookCall( "dreamwork.console.variable.change", name, old_value, new_value )
    end, -1000 )

end

do

    ---@type fun( msg: string )
    ---@diagnostic disable-next-line: undefined-field
    local Msg = _G.Msg or _G.print
    local math_min = math.min

    local utf8 = std.utf8
    local utf8_sub, utf8_len = utf8.sub, utf8.len

    --- [SHARED AND MENU]
    ---
    --- Prints the given arguments to the console.
    ---
    ---@param str string The string to print.
    function engine.consoleMessage( str )
        local index, str_length = 1, utf8_len( str )

        while str_length ~= 0 do
            -- https://developer.valvesoftware.com/wiki/Developer_Console_Control
            -- by Retr0 ( 989 characters per message )
            local segment_length = math_min( 989, str_length )
            Msg( utf8_sub( str, index, index + segment_length - 1 ) )
            str_length = str_length - segment_length
            index = index + segment_length
        end
    end

    ---@type fun( color: { r: integer, g: integer, b: integer, a: integer }, msg: string )
    ---@diagnostic disable-next-line: undefined-field
    local MsgC = _G.MsgC
    if MsgC == nil then

        engine.consoleMessageColored = engine.consoleMessage

    else

        local color_buffer = std.ColorProxy( 255, 255, 255, 255 )

        --- [SHARED AND MENU]
        ---
        --- Prints the given arguments to the console.
        ---
        ---@param str string The string to print.
        ---@param color dreamwork.std.Color The color to print the string with.
        function engine.consoleMessageColored( str, color )
            local index, str_length = 1, utf8_len( str )
            color_buffer:update( color or 0xFFFFFF )

            while str_length ~= 0 do
                -- https://developer.valvesoftware.com/wiki/Developer_Console_Control
                -- by Retr0 ( 989 characters per message )
                local segment_length = math_min( 989, str_length )
                MsgC( color_buffer, utf8_sub( str, index, index + segment_length - 1 ) )
                str_length = str_length - segment_length
                index = index + segment_length
            end
        end

    end

end

do

    ---@class garrysmod.scripted_ents
    local scripted_ents = glua_library( "scripted_ents" )

    ---@param name string
    ---@param output table | nil
    ---@return table | nil
    scripted_ents.Get = detour.simple( function( name, output )
        return engine_hookCall( "dreamwork.entity.create", name, output )
    end, scripted_ents.Get )

    ---@type table<string, table>
    local SEntList = debug.getupvalues( scripted_ents.GetStored ).SEntList

    scripted_ents.OnLoaded = detour.before( function()
        for class_name, metatable in raw_pairs( SEntList ) do
            engine_hookCall( "dreamwork.entity.load", class_name, metatable )
        end
    end, scripted_ents.OnLoaded )

end

do

    ---@class garrysmod.weapons
    local weapons = glua_library( "weapons" )

    ---@param name string
    ---@param output table | nil
    ---@return table | nil
    weapons.Get = detour.simple( function( name, output )
        return engine_hookCall( "dreamwork.weapon.create", name, output )
    end, weapons.Get )

    ---@type table<string, table>
    local WeaponList = debug.getupvalues( weapons.GetStored ).WeaponList

    weapons.OnLoaded = detour.before( function()
        for class_name, metatable in raw_pairs( WeaponList ) do
            engine_hookCall( "dreamwork.weapon.load", class_name, metatable )
        end
    end, weapons.OnLoaded )

end

do

    ---@class garrysmod.effects
    local effects = glua_library( "effects" )

    ---@param name string
    ---@param output table | nil
    ---@return table | nil
    effects.Create = detour.simple( function( name, output )
        return engine_hookCall( "dreamwork.effect.create", name, output )
    end, effects.Create )

    -- TODO: register?

end

-- TODO: effects | particles?

if LUA_CLIENT or LUA_SERVER then

    ---@class garrysmod.ents
    local ents = glua_library( "ents" )

    if ents.GetAll == nil then
        local woops = {}
        function ents.GetAll()
            return woops
        end
    end

    ---@type table<integer, garrysmod.Entity>
    local entity_list = ents.GetAll()

    ---@type integer
    local entity_count = #entity_list

    ---@type table<garrysmod.Entity, integer>
    local entity_map = {}

    for i = 1, entity_count, 1 do
        entity_map[ entity_list[ i ] ] = i
    end

    ---@diagnostic disable-next-line: inject-field
    _G.InvalidateInternalEntityCache = detour.before( function( is_player )
        local new_entities = ents.GetAll()
        local new_count = #new_entities

        ---@type table<garrysmod.Entity, integer>
        local new_map = {}

        local has_changes = false

        for i = 1, new_count, 1 do
            local entity = new_entities[ i ]
            new_map[ entity ] = i

            if entity_map[ entity ] == nil then
                engine_hookCall( "dreamwork.entity.spawn", entity, is_player )
                has_changes = true
            end
        end

        for i = 1, entity_count, 1 do
            local entity = entity_list[ i ]
            if new_map[ entity ] == nil then
                engine_hookCall( "dreamwork.entity.destroy", entity, is_player )
                has_changes = true
            end
        end

        entity_list = new_entities
        entity_count = new_count
        entity_map = new_map

        if has_changes then
            engine_hookCall( "dreamwork.entity.registry", new_entities, new_count )
        end
    end, _G.InvalidateInternalEntityCache )

    ---@return garrysmod.Entity[], integer
    function engine.getEntities()
        return entity_list, entity_count
    end

end

do

    ---@class garrysmod.gamemode
    local gamemode = glua_library( "gamemode" )

    if gamemode.Get == nil then

        ---@type table<string, table>
        local gamemodes = {}

        ---@param name string
        ---@return table | nil
        ---@diagnostic disable-next-line: duplicate-set-field
        function gamemode.Get( name )
            local tbl = gamemodes[ name ]
            return engine_hookCall( "dreamwork.gamemode.select", name, tbl ) or tbl
        end

        if gamemode.Register == nil then

            ---@param gm table
            ---@param name string
            ---@param base_name string
            ---@diagnostic disable-next-line: duplicate-set-field
            function gamemode.Register( gm, name, base_name )
                gamemodes[ name ] = {
                    FolderName = gm.FolderName,
                    Name = gm.Name or name,
                    Folder = gm.Folder,
                    Base = base_name
                }
            end

        end

    else

        ---@param name string
        ---@return table | nil
        ---@diagnostic disable-next-line: duplicate-set-field
        gamemode.Get = detour.attach( function( fn, name )
            ---@diagnostic disable-next-line: need-check-nil
            local tbl = fn( name )
            return engine_hookCall( "dreamwork.gamemode.select", name, tbl ) or tbl
        end, gamemode.Get )

        gamemode.Register = gamemode.Register or debug_fempty

    end

end

do

    ---@class dreamwork.engine.GameInfo
    ---@field depot integer The game's Steam Depot ID.
    ---@field folder string The game's mount folder name.
    ---@field title string The game's title.
    ---@field owned boolean Whether the game is owned or not.
    ---@field mounted boolean Whether the game is mounted or not.
    ---@field installed boolean Whether the game is installed or not.
    ---@field index integer The game's index in the game list.

    ---@class dreamwork.engine.AddonInfo
    ---@field downloaded boolean Whether the addon is downloaded or not.
    ---@field size integer The addon's size in bytes.
    ---@field file string The absolute path to the addon's `.gma` file.
    ---@field mounted boolean Whether the addon is mounted or not.
    ---@field updated integer The addon's last update time in Unix timestamp.
    ---@field models integer The addon's model count.
    ---@field title string The addon's title.
    ---@field tags string The addon's tags.
    ---@field wsid string The addon's Steam Workshop ID.
    ---@field timeadded integer The addon's time added, in Unix timestamp.
    ---@field index integer The addon's index in the addon list.
    ---@field folder string The addon's folder name.

    ---@class garrysmod.engine
    local glua_engine = glua_library( "engine" )

    if glua_engine.GetGame == nil then
        local woops = {}
        function glua_engine.GetGame()
            return woops
        end
    end

    if glua_engine.GetAddons == nil then
        local woops = {}
        function glua_engine.GetAddons()
            return woops
        end
    end

    local engine_GetGames = glua_engine.GetGames
    local engine_GetAddons = glua_engine.GetAddons

    ---@type table<integer, dreamwork.engine.GameInfo>
    local supported_games = {}
    engine.SupportedGames = supported_games

    ---@type dreamwork.engine.GameInfo[]
    local actual_game_list = {}

    ---@type integer
    local actual_game_count = 0

    ---@type table<integer, dreamwork.engine.GameInfo>
    local actual_game_hash = {}

    ---@type dreamwork.engine.AddonInfo[]
    local actual_addon_list = {}

    ---@type integer
    local actual_addon_count = 0

    ---@type table<string, dreamwork.engine.AddonInfo>
    local actual_addon_hash = {}

    engine.GameList, engine.GameCount, engine.GameHash = actual_game_list, actual_game_count, actual_game_hash
    engine.AddonList, engine.AddonCount, engine.AddonHash = actual_addon_list, actual_addon_count, actual_addon_hash

    engine_hookCatch( "dreamwork.content.update", "dreamwork.content.mount", function()
        for app_id in raw_pairs( supported_games ) do
            supported_games[ app_id ] = nil
        end

        ---@type dreamwork.engine.GameInfo[]
        local engine_games = engine_GetGames()

        ---@type table<integer, dreamwork.engine.GameInfo>
        local games_hash = {}

        ---@type integer
        local games_changed = 0

        ---@type dreamwork.engine.GameInfo[]
        local game_list = {}

        ---@type integer
        local game_count = 0

        for i = 1, #engine_games, 1 do
            local game_info = engine_games[ i ]

            local app_id = game_info.depot
            supported_games[ app_id ] = game_info

            if game_info.mounted then
                game_count = game_count + 1
                game_list[ game_count ] = game_info

                game_info.index = game_count

                games_hash[ app_id ] = game_info

                if actual_game_hash[ app_id ] == nil then
                    engine_hookCall( "dreamwork.game.mount", game_info, true )
                    games_changed = games_changed + 1
                end
            end
        end

        for i = actual_game_count, 1, -1 do
            local game_info = actual_game_list[ i ]
            local depot = game_info.depot

            if actual_game_hash[ depot ] ~= nil and games_hash[ depot ] == nil then
                engine_hookCall( "dreamwork.game.mount", game_info, false )
                games_changed = games_changed + 1
            end

            actual_game_list[ i ] = nil
        end

        for app_id in raw_pairs( actual_game_hash ) do
            actual_game_hash[ app_id ] = nil
        end

        for app_id, game_info in raw_pairs( games_hash ) do
            actual_game_hash[ app_id ] = game_info
        end

        for i = 1, game_count, 1 do
            actual_game_list[ i ] = game_list[ i ]
        end

        actual_game_count = game_count
        engine.GameCount = game_count

        ---@type dreamwork.engine.AddonInfo[]
        local engine_addons = engine_GetAddons()

        ---@type table<integer, dreamwork.engine.AddonInfo>
        local addons_hash = {}

        ---@type integer
        local addons_changed = 0

        ---@type dreamwork.engine.AddonInfo[]
        local addon_list = {}

        ---@type integer
        local addon_count = 0

        for i = 1, #engine_addons, 1 do
            local addon_info = engine_addons[ i ]

            if addon_info.mounted then
                addon_count = addon_count + 1
                addon_list[ addon_count ] = addon_info

                addon_info.index = addon_count

                local addon_title = addon_info.title
                addons_hash[ addon_title ] = addon_info

                if actual_addon_hash[ addon_title ] == nil then
                    addon_info.folder = string_format( "gma_%.4x", addon_info.index )
                    engine_hookCall( "dreamwork.addon.mount", addon_info, true )
                    addons_changed = addons_changed + 1
                end
            end
        end

        for i = actual_addon_count, 1, -1 do
            local addon_info = actual_addon_list[ i ]
            local addon_title = addon_info.title

            if actual_addon_hash[ addon_title ] ~= nil and addons_hash[ addon_title ] == nil then
                engine_hookCall( "dreamwork.addon.mount", addon_info, false )
                addons_changed = addons_changed + 1
            end

            actual_addon_list[ i ] = nil
        end

        for addon_title in raw_pairs( actual_addon_hash ) do
            actual_addon_hash[ addon_title ] = nil
        end

        for addon_title, addon_info in raw_pairs( addons_hash ) do
            actual_addon_hash[ addon_title ] = addon_info
        end

        for i = 1, addon_count, 1 do
            actual_addon_list[ i ] = addon_list[ i ]
        end

        actual_addon_count = addon_count
        engine.AddonCount = addon_count

        return games_changed, addons_changed
    end, 1 )

end

do

    ---@class garrysmod.util
    local glua_util = glua_library( "util" )

    if LUA_CLIENT or LUA_SERVER then

        ---@type fun( network_name: string ): integer | nil
        local network_register = glua_util.AddNetworkString or debug_fempty

        ---@type fun( network_id: integer ): string | nil
        local network_get_name = glua_util.NetworkIDToString or debug_fempty

        ---@type fun( network_name: string ): integer | nil
        local network_get_id = glua_util.NetworkStringToID or debug_fempty

        local full_header_size = engine.NetworkHeaderSize

        local header_size = full_header_size - 1 -- take unreliable flag

        ---@type table<string, integer>
        local network_ids = {}

        ---@type table<integer, string>
        local network_names = {}

        ---@type integer
        local network_limit = (2 ^ header_size) - 1

        setmetatable( network_ids, {
            __index = function( self, network_name )
                local network_id = network_get_id( network_name )

                if network_id == nil or network_id <= 0 or network_id > network_limit then
                    return nil
                end

                network_names[ network_id ] = network_name
                self[ network_name ] = network_id
                return network_id
            end
        } )

        setmetatable( network_names, {
            __index = function( self, network_id )
                if network_id <= 0 or network_id > network_limit then
                    return nil
                end

                local network_name = network_get_name( network_id )

                if network_name ~= nil then
                    network_ids[ network_name ] = network_id
                    self[ network_id ] = network_name
                end

                return network_name
            end
        } )

        --- [SHARED]
        ---
        --- Get the names of all registered networks.
        ---
        ---@return string[] networks The names of the registered networks.
        ---@return integer network_count The number of registered networks.
        function engine.getNetworks()
            local networks, network_count = {}, 0

            for network_id = 1, network_limit, 1 do
                local network_name = network_get_name( network_id )
                if network_name == nil then
                    break
                end

                network_ids[ network_name ] = network_id
                network_names[ network_id ] = network_name

                network_count = network_count + 1
                networks[ network_count ] = network_name
            end

            return networks,
                network_count
        end

        --- [SHARED]
        ---
        --- Checks if the network exists.
        ---
        ---@return boolean exists `true` if the network exists, `false` otherwise.
        function engine.networkExists( network_name )
            return network_ids[ network_name ] ~= nil
        end

        --- [SHARED]
        ---
        --- Get the ID of the network from its name.
        ---
        ---@param network_name string The name of the network.
        ---@return integer | nil network_id The ID of the network, or `nil` if the network does not exist.
        function engine.networkGetID( network_name )
            return network_ids[ network_name ]
        end

        --- [SHARED]
        ---
        --- Get the name of the network from its ID.
        ---
        ---@param network_id integer The ID of the network message.
        ---@return string | nil network_name The name of the network message, or `nil` if the network message does not exist.
        function engine.networkGetName( network_id )
            return network_names[ network_id ]
        end

        --- [SHARED]
        ---
        --- Register a new network message or returns the ID of an existing one.
        ---
        ---@param network_name string The name of the network message.
        ---@return integer network_id The ID of the network message.
        function engine.networkRegister( network_name )
            local network_id = network_ids[ network_name ]
            if network_id == nil then
                if not LUA_SERVER then
                    error( "Networks can only be registered on the server.", 2 )
                end

                ---@type integer
                ---@diagnostic disable-next-line: assign-type-mismatch
                network_id = network_register( network_name )

                if network_id == nil then
                    error( string_format( "Failed to register network '%s', unknown error.", network_name ), 2 )
                end

                network_names[ network_id ] = network_name
                network_ids[ network_name ] = network_id
            end

            return network_id
        end

        ---@class garrysmod.net
        local glua_net = glua_library( "net" )

        if glua_net ~= nil then

            local net_WriteBool = glua_net.WriteBool
            local net_ReadUInt = glua_net.ReadUInt
            local net_ReadBit = glua_net.ReadBit

            local receivers = glua_net.Receivers or {}
            glua_net.Receivers = receivers

            ---@param remaining_bits integer
            ---@param sender garrysmod.Player
            ---@diagnostic disable-next-line: duplicate-set-field
            function glua_net.Incoming( remaining_bits, sender )
                local network_id = net_ReadUInt( header_size )
                local unreliable = net_ReadBit() == 1

                remaining_bits = remaining_bits - full_header_size

                local is_complete, block_size = engine_hookCall( "dreamwork.network.message.incoming", network_id, unreliable, remaining_bits, sender )
                if is_complete == true then return end

                if block_size ~= nil then
                    remaining_bits = remaining_bits - block_size
                end

                local network_name = network_names[ network_id ]
                if network_name == nil then
                    if LUA_SERVER then
                        dreamwork.Logger:warn( "Client '%s' was disconnected for sending an invalid network message. [Network ID: %d, %s]", sender:Nick(), network_id, unreliable and "UDP" or "TCP" )
                        sender:Kick( string_format( "Server received an invalid network message. [Network ID: %d, %s]", network_id, unreliable and "UDP" or "TCP" ) )
                    else
                        dreamwork.Logger:warn( "Client received an invalid network message. [Network ID: %d, %s]", network_id, unreliable and "UDP" or "TCP" )
                    end

                    return
                end

                local fn = receivers[ string_lower( network_name ) ]
                if fn == nil then
                    if LUA_SERVER then
                        dreamwork.Logger:warn( "Client '%s' was disconnected for sending an unexpected network message. [Network ID: %d, %s]", sender:Nick(), network_id, unreliable and "UDP" or "TCP" )
                        sender:Kick( string_format( "Server received an unexpected network message. [Network ID: %d, %s]", network_id, unreliable and "UDP" or "TCP" ) )
                    else
                        dreamwork.Logger:warn( "Client received an unexpected network message. [Network ID: %d, %s]", network_id, unreliable and "UDP" or "TCP" )
                    end

                    return
                end

                fn( remaining_bits, sender )
            end

            if glua_net.Start ~= nil then

                ---@param network_name string
                ---@param unreliable? boolean
                ---@diagnostic disable-next-line: duplicate-set-field
                glua_net.Start = detour.attach( function( fn, network_name, unreliable )
                    if network_ids[ network_name ] == nil then
                        if LUA_SERVER then
                            error( string_format( "Failed to start network message '%s', network does not exist.", network_name ), 2 )
                        end

                        dreamwork.Logger:error( "Client was disconnected for sending message using unregistered network. [Network ID: %d]", network_ids[ network_name ] )
                        engine.consoleCommandRun( "disconnect" )
                        return
                    end

                    fn( network_name, unreliable )
                    net_WriteBool( unreliable == true )
                end, glua_net.Start )

            end

        end

    end

end

if engine.loadMaterial == nil then

    ---@alias dreamwork.engine.ImageParameters integer
    ---| 1 # Makes the created material a `VertexLitGeneric`, so it can be applied to models. Default shader is `UnlitGeneric`.
    ---| 2 # Sets the `$nocull` to `1` in the created material.
    ---| 4 # Sets the `$alphatest` to `1` in the created material instead of `$vertexalpha` being set to `1`.
    ---| 8 # Generates Mipmaps for the imported texture, or sets **No Level Of Detail** and **No Mipmaps** if unset. This adjusts the material's dimensions to a power of 2.
    ---| 16 # Makes the image able to tile when used with non standard UV maps. Sets the `CLAMPS` and `CLAMPT` flags if unset.
    ---| 32 # If set does nothing, if unset - enables **Point Sampling (Texture Filtering)** on the material as well as adds the **No Level Of Detail** flag to it.
    ---| 64 # If set, the material will be given `$ignorez` flag, which is necessary for some rendering operations, such as render targets and 3d2d rendering.

    local bitpack = std.bitpack
    local bitpack_toString = bitpack.toString
    local bitpack_writeUInt = bitpack.writeUInt

    local glua_Material = _G.Material

    local upvalues = debug.getupvalues( glua_Material )

    ---@type fun( path: string, params: ( string | nil ) ): garrysmod.Material, number
    local c_material_fn = upvalues.C_Material

    if c_material_fn == nil then

        ---@type { [ 1 ]: number, [ 2 ]: string }[]
        local bit_to_param = {
            { 1,  "vertexlitgeneric" },
            { 2,  "nocull" },
            { 4,  "alphatest" },
            { 8,  "mips" },
            { 16, "noclamp" },
            { 32, "smooth" },
            { 64, "ignorez" }
        }

        bit_to_param[ 0 ] = #bit_to_param

        --- [SHARED AND MENU]
        ---
        --- Loads a material from the file.
        ---
        ---@param file_path string The path to the file.
        ---@param parameters? dreamwork.engine.ImageParameters The parameters to load the image with.
        ---@return garrysmod.Material material The loaded material.
        ---@return number time_taken The time taken to load the material.
        function engine.loadMaterial( file_path, parameters )
            if parameters == nil then
                return glua_Material( file_path )
            end

            ---@type string[]
            local gparams = {}

            ---@type integer
            local gparam_count = 0

            for i = 1, bit_to_param[ 0 ], 1 do
                local data = bit_to_param[ i ]
                if rbit_band( parameters, data[ 1 ] ) ~= 0 then
                    gparam_count = gparam_count + 1
                    gparams[ gparam_count ] = data[ 2 ]
                end
            end

            if gparam_count == 0 then
                return glua_Material( file_path )
            elseif gparam_count == 1 then
                return glua_Material( file_path, gparams[ 1 ] )
            end

            return glua_Material( file_path, table_concat( gparams, " ", 1, gparam_count ) )
        end

    else

        --- [SHARED AND MENU]
        ---
        --- Loads a material from the file.
        ---
        ---@param file_path string The path to the file.
        ---@param parameters? dreamwork.engine.ImageParameters The parameters to load the image with.
        ---@return garrysmod.Material material The loaded material.
        ---@return number time_taken The time taken to load the material.
        function engine.loadMaterial( file_path, parameters )
            if parameters == nil then
                return c_material_fn( file_path )
            end

            return c_material_fn( file_path, bitpack_toString( bitpack_writeUInt( parameters, 8 ), 8, false ) )
        end

    end

end

if LUA_CLIENT then

    ---@class garrysmod.matproxy
    local glua_matproxy = glua_library( "matproxy" )

    local proxy_list = glua_matproxy.ProxyList or {}
    glua_matproxy.ProxyList = proxy_list

    local active_list = glua_matproxy.ActiveList or {}
    glua_matproxy.ActiveList = active_list

    -- TODO: matproxy
    --
    -- ref: https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/modules/matproxy.lua

end
