---@class dreamwork.engine
local dreamwork_engine = dreamwork.engine

local engine_console = dreamwork_engine.console
local console_commandRun = engine_console.commandRun

local engine_Player = dreamwork_engine.Player

local Player_SteamID64 = engine_Player.SteamID64 or function() return "76561197960265728" end
local Player_Nick = engine_Player.Nick or function() return "unknown" end
local Player_IsBot = engine_Player.IsBot or function() return false end
local Player_UserID = engine_Player.UserID or function() return 0 end

local engine_Entity = dreamwork_engine.Entity

local Entity_IsValid = engine_Entity.IsValid or function() return true end
local Entity_EntIndex = engine_Entity.EntIndex or function() return 0 end

local engine_entity = dreamwork_engine.entity

---@class garrysmod.player
local glua_player = dreamwork_engine.requireLibrary( "player" )

---@type holylib
local holylib = dreamwork_engine.requireLibrary( "HolyLib" )

local player_GetAll = glua_player.GetAll

if player_GetAll == nil then
    ---@type garrysmod.Player[]
    local woops = {}
    function player_GetAll() return woops end
end

local dreamwork_Logger = dreamwork.Logger

local engine_network = dreamwork_engine.network

local network_send = engine_network and engine_network.send
local network_start = engine_network and engine_network.start

local network_readUInt = engine_network and engine_network.readUInt
local network_writeUInt = engine_network and engine_network.writeUInt

local engine_hook = dreamwork_engine.hook
local hook_call = engine_hook.call

local engine_timer = dreamwork_engine.timer

---@class dreamwork.std
local std = dreamwork.std

if std.Client ~= nil then return end -- don't do that

local raw = std.raw
local raw_get = raw.get
local raw_type = raw.type
local raw_index = raw.index
local raw_tonumber = raw.tonumber

local rbit = raw.bit
local rbit_width = rbit.width

local debug = std.debug
local debug_fempty = debug.fempty

local math = std.math
local math_max = math.max

local string = std.string
local string_sub = string.sub
local string_find = string.find
local string_lower = string.lower
local string_format = string.format
local string_findByte = string.findByte

local ipv4 = std.ipv4
local ipv4_parse = ipv4.parse

local class = std.class
local class_new = class.new

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local server = std.server

local console = std.console
local console_Command = console.Command

local steam_Identifier = std.steam.Identifier
local Identifier_tryParse = steam_Identifier.tryParse
local Identifier_fromAccountID = steam_Identifier.fromAccountID

local LUA_CLIENT = std.LUA_CLIENT
local LUA_SERVER = std.LUA_SERVER


--- [SHARED]
---
--- Engine helpers for `std.Client`: map between clients and their player entities.
---
---@class dreamwork.engine.client
local engine_client = dreamwork_engine.client or {}
dreamwork_engine.client = engine_client

--- The number of bits of a serialized client, its player entity index.
---
--- Player entities take the indexes from `1` to `server.slots`, which is the same on the server and the client.
local index_bits = rbit_width( server.slots )

local STAGE_NONE = 0
local STAGE_CONNECTED = 1
local STAGE_ESTABLISHED = 2
local STAGE_SPAWNING = 3
local STAGE_SPAWNED = 4
local STAGE_INITIALIZED = 5
local STAGE_DISCONNECTED = 6

---@type table<integer, dreamwork.std.Client.Stage>
local stage_names = {
    [ STAGE_NONE ] = "none",
    [ STAGE_CONNECTED ] = "connected",
    [ STAGE_ESTABLISHED ] = "established",
    [ STAGE_SPAWNING ] = "spawning",
    [ STAGE_SPAWNED ] = "spawned",
    [ STAGE_INITIALIZED ] = "initialized",
    [ STAGE_DISCONNECTED ] = "disconnected"
}

---@type table<dreamwork.std.Client.Stage, integer>
local stage_indexes = {}

for index = STAGE_NONE, STAGE_DISCONNECTED, 1 do
    stage_indexes[ stage_names[ index ] ] = index
end

--- The hooks called when a client reaches the stage, all of them get the client as the only argument.
---
---@type table<integer, string>
local stage_hooks = {
    [ STAGE_CONNECTED ] = "dreamwork.client.connected",
    [ STAGE_ESTABLISHED ] = "dreamwork.client.established",
    [ STAGE_SPAWNING ] = "dreamwork.client.spawning",
    [ STAGE_SPAWNED ] = "dreamwork.client.spawned",
    [ STAGE_INITIALIZED ] = "dreamwork.client.initialized"
}

--- The stages of the `SIGNONSTATE` values, `SIGNONSTATE_FULL` comes before the player entity exists.
---
---@type table<integer, integer>
local signon_stages = {
    [ 2 ] = STAGE_CONNECTED,   -- SIGNONSTATE_CONNECTED
    [ 3 ] = STAGE_ESTABLISHED, -- SIGNONSTATE_NEW
    [ 4 ] = STAGE_ESTABLISHED, -- SIGNONSTATE_PRESPAWN
    [ 5 ] = STAGE_SPAWNING,    -- SIGNONSTATE_SPAWN
    [ 6 ] = STAGE_SPAWNING     -- SIGNONSTATE_FULL
}

--- The names the engine reports before the real one is known,
--- `""` on the server and `"unconnected"` on the client when the player entity is created.
---
---@type table<string, boolean>
local temporary_names = {
    [ "" ] = true,
    unconnected = true
}

--- The metamethods readable through the client object, `raw.index` hides them,
--- but `BinaryWriter:writeObject` and `BinaryReader:readObject` look them up on the object.
---
---@type table<string, boolean>
local public_metamethods = {
    __serialize = true,
    __deserialize = true
}

--- The fields of `dreamwork.std.Client.Data` readable through the client object.
---
---@type table<string, boolean>
local public_fields = {
    entity_id = true,
    steam_id = true,
    user_id = true,
    ip = true,
    port = true,
    name = true,
    is_bot = true
}

--- The fields computed from `dreamwork.std.Client.Data` readable through the client object.
---
---@type table<string, fun( data: dreamwork.std.Client.Data ): any>
local computed_fields = {
    is_initialized = function( data )
        return data.stage == STAGE_INITIALIZED
    end,
    is_connected = function( data )
        return data.stage ~= STAGE_DISCONNECTED
    end,
    stage = function( data )
        return stage_names[ data.stage ]
    end
}

--- [SHARED]
---
--- A client of the server, a player that is connecting or connected.
---
--- A client exists from the moment it starts connecting, before its player entity,
--- its data is collected from the engine hooks, game events and the player entity.
---
--- Fields are read-only and can be `nil` until they are known:
--- * `name` is updated with the `dreamwork.client.renamed` hook.
--- * `steam_id` is `nil` for bots, it is set with the `dreamwork.client.identified` hook.
--- * `ip` and `port` are only known on the server, `ip` is `0x7F000001` ( 127.0.0.1 ) without `port` for the listen server host.
---
--- The object stays readable after the client disconnects, but it is not returned by `get` anymore.
---
---@class dreamwork.std.Client : dreamwork.std.Object
---@field __class dreamwork.std.ClientClass
---@field stage dreamwork.std.Client.Stage The current connection stage of the client.
---@field steam_id dreamwork.std.steam.Identifier | nil The Steam ID of the client, `nil` for bots and until it is known.
---@field user_id integer The user ID of the client, unique during the map.
---@field entity_id integer | nil The entity index of the player entity of the client.
---@field ip dreamwork.std.IPv4 | nil The IPv4 address of the client as an unsigned 32-bit integer, see `std.ipv4`, always `nil` on the client.
---@field port integer | nil The port of the client, always `nil` on the client.
---@field name string | nil The name of the client, `nil` until it is known.
---@field is_bot boolean `true` if the client is a bot.
---@field is_initialized boolean `true` if the player entity of the client is valid on the client and it can send and receive network messages. On the server a client is initialized by its first user command that is not forced, which the client sends after `InitPostEntity`. On the client the local client is initialized in `InitPostEntity`, the others once the server reports them.
---@field is_connected boolean `true` until the client disconnects.
local Client = class.base( "Client", true )

--- [SHARED]
---
--- The class of `Client`, call it with a user ID to get the client.
---
---@class dreamwork.std.ClientClass : dreamwork.std.Client, dreamwork.std.Class
---@field __base dreamwork.std.Client
---@overload fun( user_id: integer ): dreamwork.std.Client
local ClientClass = class.create( Client )
std.Client = ClientClass

local bot_count = 0
local human_count = 0
local connecting_count = 0

--- The methods of the previous load, used to keep the stages of the clients on reload.
---
---@type ( fun( pl: garrysmod.Player ): dreamwork.std.Client | nil ) | nil
local previous_fromEntity = engine_client.fromEntity

--- The data of the clients, kept while the objects are referenced.
---
---@type table<dreamwork.std.Client, dreamwork.std.Client.Data>
local client_data = {}
gc_setTableRules( client_data, true, false )

--- The clients that are not disconnected by their user IDs, including the ones that are not announced yet.
---
---@type table<integer, dreamwork.std.Client>
local clients = {}

--- The user IDs of the disconnected clients, the engine never reuses them during a map.
---
---@type table<integer, boolean>
local disconnected_ids = {}

--- The announced clients in the order of their connection.
---
---@type dreamwork.std.Client[]
local client_list = {}

--- The number of clients in `client_list`.
---
---@type integer
local client_count = 0

--- The clients by their player entities.
---
---@type table<garrysmod.Player, dreamwork.std.Client>
local entity_clients = {}

--- The clients by their player entity indexes, the indexes are reused after a disconnect.
---
---@type table<integer, dreamwork.std.Client>
local index_clients = {}

--- The local client, see `Client:isLocal`.
---
---@type dreamwork.std.Client | nil
local local_client

---@return string
---@protected
function Client:__represent()
    local data = client_data[ self ]
    return string_format( "Client: %p [%d][%s]", self, data.user_id, data.name or "unknown" )
end

---@param key string
---@return any
---@protected
function Client:__index( key )
    local method = raw_index( Client, key )
    if method ~= nil then
        return method
    end

    if public_fields[ key ] then
        return client_data[ self ][ key ]
    end

    local compute = computed_fields[ key ]
    if compute ~= nil then
        return compute( client_data[ self ] )
    end

    if public_metamethods[ key ] then
        return raw_get( Client, key )
    end

    return nil
end

---@param key string
---@protected
function Client:__newindex( key )
    error( string_format( "Client field '%s' is read-only.", key ), 3 )
end

--- Deserialized objects share the data of their client, so they are equal to it.
---
---@param other dreamwork.std.Client
---@return boolean
---@protected
function Client:__eq( other )
    return client_data[ self ] == client_data[ other ]
end

--- Writes the player entity index of the client, `0` if it is not known yet.
---
---@param writer dreamwork.std.BinaryWriter The writer to write to.
---@protected
function Client:__serialize( writer )
    writer:writeUInt( client_data[ self ].entity_id or 0, index_bits )
end

--- Reads the player entity index written by `__serialize`, the object becomes a view of the client with the index.
---
--- An unknown index gives a disconnected client without data, e.g. the client left before the message arrived.
---
--- > **NOTE**: The object is equal (`==`) to the client, but it is a different key in tables.
---
---@param reader dreamwork.std.BinaryReader The reader to read from.
---@protected
function Client:__deserialize( reader )
    local index = reader:readUInt( index_bits )

    local client = index_clients[ index ]
    if client ~= nil then
        client_data[ self ] = client_data[ client ]
        return
    end

    client_data[ self ] = {
        user_id = 0,
        entity_id = index ~= 0 and index or nil,
        stage = STAGE_DISCONNECTED,
        announced = false,
        is_local = false,
        is_bot = false
    }
end

---@param user_id integer
---@return dreamwork.std.Client | nil
---@protected
function ClientClass:__new( user_id )
    local client = clients[ user_id ]
    if client ~= nil and client_data[ client ].announced then
        return client
    end

    error( string_format( "Client with user ID %d does not exist.", user_id ), 3 )
end

--- [SHARED]
---
--- Checks if the client is the local one, the game client itself on the client,
--- the host on a listen server or in single-player.
---
---@return boolean is_local `true` if the client is the local one, `false` otherwise.
---@nodiscard
function Client:isLocal()
    return client_data[ self ].is_local
end

--- [SHARED]
---
--- Returns the client with the user ID.
---
---@param user_id integer The user ID.
---@return dreamwork.std.Client | nil client The client, or `nil` if there is no connected client with the user ID.
---@nodiscard
function ClientClass.get( user_id )
    local client = clients[ user_id ]
    if client ~= nil and client_data[ client ].announced then
        return client
    end

    return nil
end

--- [SHARED]
---
--- Returns the local client, see `Client:isLocal`.
---
--- > **NOTE**: Always `nil` on a dedicated server.
---
---@return dreamwork.std.Client | nil client The local client, or `nil` if it is not known yet.
---@nodiscard
function ClientClass.getLocal()
    return local_client
end

--- [SHARED]
---
--- Returns the connected clients in the order of their connection.
---
---@param ignore_bots boolean? If `true`, bots are skipped.
---@param ignore_humans boolean? If `true`, humans are skipped.
---@return dreamwork.std.Client[] client_list The new list of the clients.
---@return integer client_count The number of the clients in the list.
---@nodiscard
function ClientClass.getAll( ignore_bots, ignore_humans )
    ---@type dreamwork.std.Client[]
    local result, count = {}, 0

    for i = 1, client_count, 1 do
        local client = client_list[ i ]

        local is_bot = client_data[ client ].is_bot
        if not (is_bot and ignore_bots or not is_bot and ignore_humans) then
            count = count + 1
            result[ count ] = client
        end
    end

    return result, count
end

--- [SHARED]
---
--- Finds a connected client by its name.
---
--- An exact match is preferred, otherwise the first client whose name contains `name`, ignoring the case.
---
---@param name string The name or a part of it.
---@return dreamwork.std.Client | nil client The found client, or `nil` if there is none.
---@nodiscard
function ClientClass.findByName( name )
    for i = 1, client_count, 1 do
        local client = client_list[ i ]
        if client_data[ client ].name == name then
            return client
        end
    end

    local lower_name = string_lower( name )

    for i = 1, client_count, 1 do
        local client = client_list[ i ]

        local client_name = client_data[ client ].name
        if client_name ~= nil and string_find( string_lower( client_name ), lower_name, 1, true ) ~= nil then
            return client
        end
    end

    return nil
end

--- [SHARED]
---
--- Finds a connected client by its Steam ID.
---
--- Matches on the account ID (`identifier.id`), so any `steam.Identifier` form
--- for the same account works. Bots and clients without a known Steam ID are skipped.
---
---@param identifier dreamwork.std.steam.Identifier The Steam ID to search for.
---@return dreamwork.std.Client | nil client The found client, or `nil` if there is none.
---@nodiscard
function ClientClass.findBySteamId( identifier )
    local account_id = identifier.id

    for i = 1, client_count, 1 do
        local client = client_list[ i ]
        local steam_id = client_data[ client ].steam_id
        if steam_id ~= nil and steam_id.id == account_id then
            return client
        end
    end

    return nil
end

--- [SHARED]
---
--- Returns the number of connected clients, optionally filtering by type.
---
--- Without filters this is the same as the length returned by `getAll`.
--- Spawned bots and humans are counted separately from connecting clients
--- ( announced, but not yet at the `spawned` stage ).
---
---@param ignore_bots boolean? If `true`, spawned bots are skipped.
---@param ignore_humans boolean? If `true`, spawned humans are skipped.
---@param ignore_connecting boolean? If `true`, connecting clients are skipped.
---@return integer client_count The number of matching clients.
---@nodiscard
function ClientClass.getCount( ignore_bots, ignore_humans, ignore_connecting )
    local count = 0

    if not ignore_bots then
        count = count + bot_count
    end

    if not ignore_humans then
        count = count + human_count
    end

    if not ignore_connecting then
        count = count + connecting_count
    end

    return count
end

do

    local Player_RunConsoleCommand = engine_Player.RunConsoleCommand

    if Player_RunConsoleCommand == nil then
        local Player_ConCommand = engine_Player.ConCommand

        function Player_RunConsoleCommand( pl, command, ... )
            local arguments = { ... }

            for i = 1, #arguments, 1 do
                command = command .. " \"" .. arguments[ i ] .. "\""
            end

            Player_ConCommand( pl, command )
        end
    end

    --- [SHARED]
    ---
    --- Runs a console command on the client.
    ---
    --- On the server it works for any client with a player entity,
    --- on the client only for the local one.
    ---
    --- > **NOTE**: The arguments are quoted, so they cannot contain `"`.
    ---
    ---@param command string The name of the console command.
    ---@param ... string The arguments of the console command.
    ---@return boolean is_sent `true` if the command was sent, `false` if the client cannot run it.
    function Client:runConsoleCommand( command, ... )
        local data = client_data[ self ]
        if data.stage == STAGE_DISCONNECTED then
            return false
        end

        if LUA_CLIENT then
            if data.is_local then
                console_commandRun( command, ... )
                return true
            end

            return false
        end

        local pl = data.entity
        if pl == nil or not Entity_IsValid( pl ) then
            return false
        end

        Player_RunConsoleCommand( pl, command, ... )
        return true
    end

end

--- [SHARED]
---
--- Returns the client of the player entity.
---
---@param pl garrysmod.Player The player entity.
---@return dreamwork.std.Client | nil client The client, or `nil` if the entity has no connected client.
---@nodiscard
function engine_client.fromEntity( pl )
    local client = entity_clients[ pl ]
    if client ~= nil and client_data[ client ].announced then
        return client
    end

    return nil
end

--- [SHARED]
---
--- Returns the player entity of the client.
---
--- > **NOTE**: `nil` until the entity is created on this side, after the entity is removed and after the client disconnects.
---
---@param client dreamwork.std.Client
---@return garrysmod.Player | nil pl The player entity, or `nil` if there is none.
---@nodiscard
function engine_client.toEntity( client )
    return client_data[ client ].entity
end

if LUA_SERVER then

    local HolyLib_Reconnect = holylib.Reconnect

    if HolyLib_Reconnect ~= nil then

        --- [SHARED]
        ---
        --- Reconnects the client to the server.
        ---
        ---@return boolean success `true` if the reconnect was sent, `false` if the client cannot reconnect.
        function Client:reconnect()
            local entity = engine_client.toEntity( self )
            if entity == nil then
                return self:runConsoleCommand( "retry" )
            end

            return HolyLib_Reconnect( entity )
        end

    end

end

if Client.reconnect == nil then

    --- [SHARED]
    ---
    --- Reconnects the client to the server.
    ---
    --- Runs `retry` via `Client:runConsoleCommand`.
    --- On the server it needs a player entity, on the client only the local one.
    ---
    ---@return boolean success `true` if the reconnect was sent, `false` if the client cannot reconnect.
    function Client:reconnect()
        return self:runConsoleCommand( "retry" )
    end

end

do

    ---@type fun( data: dreamwork.std.Client.Data, reason: string, silent: boolean? ): boolean
    local kick_client

    if LUA_SERVER then

        local HolyLib_Disconnect = holylib.Disconnect

        if HolyLib_Disconnect ~= nil then
            function kick_client( data, reason, silent )
                return HolyLib_Disconnect( data.user_id, reason, silent )
            end
        end

        if kick_client == nil then

            ---@class garrysmod.game
            local glua_game = dreamwork_engine.requireLibrary( "game" )
            local game_KickID = glua_game.KickID

            if game_KickID ~= nil then
                function kick_client( data, reason )
                    game_KickID( data.user_id, reason )
                    return true
                end
            end

        end

    end

    if kick_client == nil then
        function kick_client( data, reason )
            if LUA_SERVER then
                console_Command.run( "kickid", string_format( "%d", data.user_id ), reason )
                return true
            end

            if data.is_local then
                console_Command.run( "disconnect" )
                return true
            end

            return false
        end
    end

    --- [SHARED]
    ---
    --- Disconnects the client from the server.
    ---
    ---@param reason string? The reason to disconnect the client with.
    ---@param silent boolean? If `true`, silently closes the net channel and sends no disconnect to the client. Defaults to `false`, ignored without HolyLib.
    ---@return boolean success `true` if the client was successfully disconnected.
    function Client:disconnect( reason, silent )
        local data = client_data[ self ]
        if data.stage == STAGE_DISCONNECTED then
            return false
        end

        return kick_client( data, reason or "Kicked by the server.", silent )
    end

end

--- Returns the client of the user ID, creates it if needed, `nil` for disconnected clients.
---
---@param user_id integer
---@return dreamwork.std.Client | nil
---@return dreamwork.std.Client.Data | nil
local function ensure( user_id )
    local client = clients[ user_id ]
    if client ~= nil then
        return client, client_data[ client ]
    end

    if disconnected_ids[ user_id ] then
        return nil, nil
    end

    client = class_new( Client )

    ---@type dreamwork.std.Client.Data
    local data = {
        user_id = user_id,
        stage = STAGE_NONE,
        announced = false,
        is_local = false,
        is_bot = false
    }

    client_data[ client ] = data
    clients[ user_id ] = client

    return client, data
end

--- Moves the client to the stage, calls the hooks of all passed stages if the client is announced.
---
---@param client dreamwork.std.Client
---@param data dreamwork.std.Client.Data
---@param stage integer
local function advance( client, data, stage )
    local previous_stage = data.stage
    if stage <= previous_stage then return end

    if not data.announced then
        data.stage = stage
        return
    end

    -- one stage at a time, so every hook sees its own stage
    for index = previous_stage + 1, stage, 1 do
        data.stage = index

        if index == STAGE_SPAWNED then
            connecting_count = connecting_count - 1

            if data.is_bot then
                bot_count = bot_count + 1
            else
                human_count = human_count + 1
            end
        end

        hook_call( stage_hooks[ index ], client )

        -- disconnected or advanced by a handler
        if data.stage ~= index then return end
    end
end

--- Makes the client public, calls `dreamwork.client.connected` and the hooks of the stages it already passed.
---
---@param client dreamwork.std.Client
---@param data dreamwork.std.Client.Data
local function announce( client, data )
    data.announced = true

    client_count = client_count + 1
    client_list[ client_count ] = client

    connecting_count = connecting_count + 1

    local stage = data.stage
    data.stage = STAGE_CONNECTED

    hook_call( "dreamwork.client.connected", client )

    if data.steam_id ~= nil and data.stage ~= STAGE_DISCONNECTED then
        hook_call( "dreamwork.client.identified", client )
    end

    if data.stage ~= STAGE_DISCONNECTED then
        advance( client, data, stage )
    end
end

--- Sets the name of the client, temporary names are ignored.
---
--- The first name announces the client, the next ones call `dreamwork.client.renamed`.
---
---@param client dreamwork.std.Client
---@param data dreamwork.std.Client.Data
---@param name string | nil
local function set_name( client, data, name )
    if name == nil or temporary_names[ name ] or data.name == name then return end

    local previous_name = data.name
    data.name = name

    if not data.announced then
        announce( client, data )
    elseif previous_name ~= nil then
        hook_call( "dreamwork.client.renamed", client, previous_name )
    end
end

--- Sets the Steam ID of the client, bots and invalid or placeholder IDs are ignored.
---
---@param client dreamwork.std.Client
---@param data dreamwork.std.Client.Data
---@param steam_id dreamwork.std.steam.Identifier | nil
local function set_steam_id( client, data, steam_id )
    if steam_id == nil or data.is_bot or not (steam_id:isIndividual() and steam_id:isValid()) then return end

    local previous_steam_id = data.steam_id
    if previous_steam_id ~= nil and previous_steam_id == steam_id then return end

    data.steam_id = steam_id

    if data.announced then
        hook_call( "dreamwork.client.identified", client )
    end
end

--- Parses a Steam ID in any format, `nil` for anything else.
---
---@param value any
---@return dreamwork.std.steam.Identifier | nil
local function parse_steam_id( value )
    if raw_type( value ) ~= "string" then
        return nil
    end

    return (Identifier_tryParse( value ))
end

--- Sets the IP address and port of the client from an `ip:port` address.
---
---@param data dreamwork.std.Client.Data
---@param address string | nil
local function set_address( data, address )
    -- `none` for bots, `Error!` from `Player:IPAddress` of bots
    if address == nil or address == "" or address == "none" or address == "Error!" then return end

    if address == "loopback" then
        data.ip = 0x7F000001
        data.port = nil
        return
    end

    local colon_position = string_findByte( address, 0x3A --[[ : ]] )
    if colon_position == nil then
        data.ip = ipv4_parse( address )
        data.port = nil
    else
        data.ip = ipv4_parse( address, 1, colon_position - 1 )
        data.port = raw_tonumber( string_sub( address, colon_position + 1 ), 10 )
    end
end

---@param client dreamwork.std.Client
---@param data dreamwork.std.Client.Data
local function set_local( client, data )
    data.is_local = true
    local_client = client
end

--- Sets the player entity index of the client, see `index_clients`.
---
---@param client dreamwork.std.Client
---@param data dreamwork.std.Client.Data
---@param index integer
local function set_entity_id( client, data, index )
    local previous_index = data.entity_id
    if previous_index ~= nil and index_clients[ previous_index ] == client then
        index_clients[ previous_index ] = nil
    end

    data.entity_id = index
    index_clients[ index ] = client
end

--- Collects the data of the `player_connect`, `player_connect_client` and `player_info` game events.
---
---@param event table
---@return dreamwork.std.Client | nil
---@return dreamwork.std.Client.Data | nil
local function collect( event )
    local client, data = ensure( event.userid )
    if client == nil or data == nil then
        return nil, nil
    end

    if event.bot == 1 then
        data.is_bot = true
    end

    local index = event.index
    if index ~= nil then
        set_entity_id( client, data, index + 1 )
    end

    set_steam_id( client, data, parse_steam_id( event.networkid ) )

    local account_id = event.friendsid
    if data.steam_id == nil and account_id ~= nil and account_id ~= 0 then
        set_steam_id( client, data, Identifier_fromAccountID( account_id ) )
    end

    -- the last one, the name announces the client
    set_name( client, data, event.name )

    return client, data
end

---@type fun( pl: garrysmod.Player ): boolean
local is_local_entity

--- Called when the player entity of the client was attached.
---
---@type fun( client: dreamwork.std.Client, data: dreamwork.std.Client.Data, pl: garrysmod.Player )
local entity_attached

--- Attaches the player entity to its client, announces the client if it has no name yet.
---
---@param pl garrysmod.Player
local function attach( pl )
    local client, data = ensure( Player_UserID( pl ) )
    if client == nil or data == nil then return end

    -- the reference can be stored before the entity cache reports the spawn
    if data.entity == pl then
        entity_attached( client, data, pl )
        return
    end

    local previous_entity = data.entity
    if previous_entity ~= nil then
        entity_clients[ previous_entity ] = nil
    end

    data.entity = pl
    entity_clients[ pl ] = client

    set_entity_id( client, data, Entity_EntIndex( pl ) )

    if Player_IsBot( pl ) then
        data.is_bot = true
    elseif data.steam_id == nil then
        set_steam_id( client, data, parse_steam_id( Player_SteamID64( pl ) ) )
    end

    if is_local_entity( pl ) then
        set_local( client, data )
    end

    local name = Player_Nick( pl )
    data.polled_name = name
    set_name( client, data, name )

    if not data.announced then
        announce( client, data )
    end

    if data.stage == STAGE_DISCONNECTED then return end

    advance( client, data, STAGE_SPAWNED )

    if data.stage == STAGE_DISCONNECTED then return end

    entity_attached( client, data, pl )
end

--- Disconnects the client, calls `dreamwork.client.disconnected` if it was announced.
---
---@param user_id integer
---@param reason string | nil
local function disconnect( user_id, reason )
    local client = clients[ user_id ]
    if client == nil then return end

    clients[ user_id ] = nil
    disconnected_ids[ user_id ] = true

    local data = client_data[ client ]
    local previous_stage = data.stage
    data.stage = STAGE_DISCONNECTED

    if local_client == client then
        local_client = nil
    end

    if data.announced then
        for i = 1, client_count, 1 do
            if client_list[ i ] == client then
                for j = i, client_count - 1, 1 do
                    client_list[ j ] = client_list[ j + 1 ]
                end

                client_list[ client_count ] = nil
                client_count = client_count - 1
                break
            end
        end

        if previous_stage < STAGE_SPAWNED then
            connecting_count = connecting_count - 1
        elseif data.is_bot then
            bot_count = bot_count - 1
        else
            human_count = human_count - 1
        end

        hook_call( "dreamwork.client.disconnected", client, reason )
    end

    -- kept for the disconnect handlers
    local pl = data.entity
    if pl ~= nil then
        data.entity = nil
        entity_clients[ pl ] = nil
    end

    local index = data.entity_id
    if index ~= nil and index_clients[ index ] == client then
        index_clients[ index ] = nil
    end
end

if LUA_CLIENT or LUA_SERVER then

    engine_hook.catch( "dreamwork.entity.client.spawn", "std.client", attach, 1000 )

    ---@param pl garrysmod.Player
    engine_hook.catch( "dreamwork.entity.client.destroy", "std.client", function( pl )
        local client = entity_clients[ pl ]
        if client == nil then return end

        entity_clients[ pl ] = nil

        local data = client_data[ client ]
        if data.entity == pl then
            data.entity = nil
        end
    end, -1000 )

    ---@param event { userid: integer, oldname: string, newname: string }
    engine_hook.catch( "player_changename", "std.client", function( event )
        local client = clients[ event.userid ]
        if client ~= nil then
            set_name( client, client_data[ client ], event.newname )
        end
    end )

    ---@param event { userid: integer }
    engine_hook.catch( "player_activate", "std.client", function( event )
        local client, data = ensure( event.userid )
        if client ~= nil and data ~= nil then
            advance( client, data, STAGE_SPAWNING )
        end
    end )

    ---@param event { userid: integer, reason: string }
    engine_hook.catch( "player_disconnect", "std.client", function( event )
        disconnect( event.userid, event.reason )
    end )

    ---@param user_id integer
    ---@param new_state integer
    engine_hook.catch( "ClientSignOnStateChanged", "std.client", function( user_id, _, new_state )
        -- `SIGNONSTATE_NONE` comes after `player_disconnect`, it disconnects the clients without one
        if new_state == 0 then
            disconnect( user_id, nil )
            return
        end

        local stage = signon_stages[ new_state ]
        if stage == nil then return end

        local client, data = ensure( user_id )
        if client ~= nil and data ~= nil then
            advance( client, data, stage )
        end
    end )

    -- the name and the Steam ID of the entity are temporary on its creation, they are updated by the polling
    engine_timer.create( "std.client.poll", 1, 0, function()
        for i = client_count, 1, -1 do
            local client = client_list[ i ]
            if client ~= nil then
                local data = client_data[ client ]

                local pl = data.entity
                if pl ~= nil and Entity_IsValid( pl ) then
                    -- only a changed value counts, the engine can cache a stale name
                    local name = Player_Nick( pl )
                    if name ~= data.polled_name then
                        data.polled_name = name
                        set_name( client, data, name )
                    end

                    if data.steam_id == nil and not data.is_bot then
                        set_steam_id( client, data, parse_steam_id( Player_SteamID64( pl ) ) )
                    end
                end
            end
        end
    end, true )

end

--- Restores the client of a player entity that existed before the module was loaded, without calling hooks.
---
---@param pl garrysmod.Player
---@return dreamwork.std.Client | nil
---@return dreamwork.std.Client.Data | nil
local function restore( pl )
    local client, data = ensure( Player_UserID( pl ) )
    if client == nil or data == nil then
        return nil, nil
    end

    data.entity = pl
    entity_clients[ pl ] = client

    set_entity_id( client, data, Entity_EntIndex( pl ) )
    data.is_bot = Player_IsBot( pl )

    if not data.is_bot then
        local steam_id = parse_steam_id( Player_SteamID64( pl ) )
        if steam_id ~= nil and steam_id:isIndividual() and steam_id:isValid() then
            data.steam_id = steam_id
        end
    end

    local name = Player_Nick( pl )
    data.polled_name = name

    if not temporary_names[ name ] then
        data.name = name
    end

    if is_local_entity( pl ) then
        set_local( client, data )
    end

    ---@type integer
    local stage = STAGE_SPAWNED

    if previous_fromEntity ~= nil then
        local previous_client = previous_fromEntity( pl )
        if previous_client ~= nil then
            stage = math_max( stage, stage_indexes[ previous_client.stage ] or stage )
        end
    end

    data.stage = stage
    data.announced = true

    client_count = client_count + 1
    client_list[ client_count ] = client

    if stage < STAGE_SPAWNED then
        connecting_count = connecting_count + 1
    elseif data.is_bot then
        bot_count = bot_count + 1
    else
        human_count = human_count + 1
    end

    return client, data
end

---@type string
local network_name = "dreamwork.client"

if LUA_SERVER then

    local Player_IsListenServerHost = engine_Player.IsListenServerHost or debug_fempty
    local Player_IPAddress = engine_Player.IPAddress or debug_fempty

    local is_listen_server = not server.dedicated

    ---@param pl garrysmod.Player
    ---@return boolean
    function is_local_entity( pl )
        return is_listen_server and Player_IsListenServerHost( pl )
    end

    --- Sends the user IDs of the clients to the receivers.
    ---
    ---@param user_ids integer[]
    ---@param user_id_count integer
    ---@param receivers garrysmod.Player | garrysmod.Player[]
    local function send_ids( user_ids, user_id_count, receivers )
        network_start( network_name )
        network_writeUInt( user_id_count, 8 )

        for i = 1, user_id_count, 1 do
            network_writeUInt( user_ids[ i ], 32 )
        end

        network_send( receivers )
    end

    ---@param client dreamwork.std.Client
    ---@param data dreamwork.std.Client.Data
    local function initialize( client, data )
        if data.stage >= STAGE_INITIALIZED then return end

        local pl = data.entity

        ---@type integer[]
        local user_ids, user_id_count = {}, 0

        ---@type garrysmod.Player[]
        local receivers, receiver_count = {}, 0

        for i = 1, client_count, 1 do
            local other_data = client_data[ client_list[ i ] ]
            if other_data.stage == STAGE_INITIALIZED then
                user_id_count = user_id_count + 1
                user_ids[ user_id_count ] = other_data.user_id

                local other_pl = other_data.entity
                if other_pl ~= nil and not other_data.is_bot then
                    receiver_count = receiver_count + 1
                    receivers[ receiver_count ] = other_pl
                end
            end
        end

        if pl ~= nil and not data.is_bot then
            -- the new client gets every initialized client, itself included
            user_id_count = user_id_count + 1
            user_ids[ user_id_count ] = data.user_id
            send_ids( user_ids, user_id_count, pl )
        end

        if receiver_count ~= 0 then
            send_ids( { data.user_id }, 1, receivers )
        end

        advance( client, data, STAGE_INITIALIZED )
    end

    --- The players waiting for their first user command that is not forced.
    ---
    ---@type table<garrysmod.Player, boolean>
    local pending_players = {}
    local pending_count = 0

    local hook_name = "std.client.initialize"

    ---@param pl garrysmod.Player
    local function stop_waiting( pl )
        if pending_players[ pl ] == nil then return end

        pending_players[ pl ] = nil
        pending_count = pending_count - 1

        if pending_count == 0 then
            engine_hook.release( "StartCommand", hook_name )
        end
    end

    ---@param pl garrysmod.Player
    ---@param cmd garrysmod.UserCommand
    local function command_received( pl, cmd )
        -- the server makes forced commands while the client is loading
        if pending_players[ pl ] == nil or cmd:IsForced() then return end

        stop_waiting( pl )

        local client = entity_clients[ pl ]
        if client ~= nil then
            initialize( client, client_data[ client ] )
        end
    end

    ---@param pl garrysmod.Player
    local function wait_for_client( pl )
        if pending_players[ pl ] ~= nil then return end

        pending_players[ pl ] = true
        pending_count = pending_count + 1

        if pending_count == 1 then
            engine_hook.catch( "StartCommand", hook_name, command_received )
        end
    end

    ---@param data dreamwork.std.Client.Data
    ---@param pl garrysmod.Player
    function entity_attached( _, data, pl )
        -- bots are not flagged yet, their commands are never forced
        if data.stage < STAGE_INITIALIZED then
            wait_for_client( pl )
        end
    end

    engine_network.register( network_name )

    ---@param event { userid: integer, name: string, networkid: string, address: string, bot: integer, index: integer }
    engine_hook.catch( "player_connect", "std.client", function( event )
        local client, data = ensure( event.userid )
        if client == nil or data == nil then return end

        set_address( data, event.address )

        if event.address == "loopback" then
            set_local( client, data )
        end

        collect( event )
    end )

    ---@param pl garrysmod.Player
    ---@param steam_id string
    engine_hook.catch( "PlayerAuthed", "std.client", function( pl, steam_id )
        local client = clients[ Player_UserID( pl ) ]
        if client ~= nil then
            set_steam_id( client, client_data[ client ], parse_steam_id( steam_id ) )
        end
    end )

    -- the entity registry can be updated later than the initial spawn
    engine_hook.catch( "PlayerInitialSpawn", "std.client", attach, 1000 )

    engine_hook.catch( "dreamwork.entity.client.destroy", hook_name, stop_waiting, -1000 )

    local players = player_GetAll()

    for i = 1, #players, 1 do
        local pl = players[ i ]

        local client, data = restore( pl )
        if client ~= nil and data ~= nil then
            if data.ip == nil then
                set_address( data, Player_IPAddress( pl ) )
            end

            entity_attached( client, data, pl )
        end
    end

elseif LUA_CLIENT then

    local entity_isRegistered = engine_entity.isRegistered
    local entity_update = engine_entity.update

    local LocalPlayer = LocalPlayer or debug_fempty

    ---@param pl garrysmod.Player
    ---@return boolean
    function is_local_entity( pl )
        return pl == LocalPlayer()
    end

    ---@param client dreamwork.std.Client
    ---@param data dreamwork.std.Client.Data
    function entity_attached( client, data )
        if data.initialize_pending then
            data.initialize_pending = nil
            advance( client, data, STAGE_INITIALIZED )
        end
    end

    --- Initializes the local client, `false` if its player entity is not valid yet.
    ---
    ---@return boolean is_initialized
    local function initialize_local()
        local pl = LocalPlayer()
        if pl == nil or not Entity_IsValid( pl ) then
            return false
        end

        attach( pl )

        local client = entity_clients[ pl ]
        if client ~= nil then
            local data = client_data[ client ]
            set_local( client, data )
            advance( client, data, STAGE_INITIALIZED )
        end

        return true
    end

    engine_hook.catch( "player_connect_client", "std.client", collect )
    engine_hook.catch( "player_info", "std.client", collect )

    ---@param event { message: string }
    engine_hook.catch( "client_disconnect", "std.client", function( event )
        if local_client ~= nil then
            disconnect( client_data[ local_client ].user_id, event.message )
        end
    end )

    local network_id = engine_network.getId( network_name )
    if network_id == nil then
        dreamwork_Logger:warn( "Server has no '%s' network, other clients will not be initialized.", network_name )
    else

        engine_network.receiveById( network_id, function()
            for _ = 1, network_readUInt( 8 ), 1 do
                local user_id = network_readUInt( 32 )

                local pl = LocalPlayer()
                if pl ~= nil and Entity_IsValid( pl ) and Player_UserID( pl ) == user_id then
                    initialize_local()
                else
                    local client, data = ensure( user_id )
                    if client ~= nil and data ~= nil and data.stage < STAGE_INITIALIZED then
                        local other_pl = data.entity
                        if other_pl ~= nil and not entity_isRegistered( other_pl ) then
                            -- valid before the engine reports it in the entity cache
                            entity_update()
                            other_pl = data.entity
                        end

                        if other_pl ~= nil and entity_isRegistered( other_pl ) then
                            data.initialize_pending = nil
                            advance( client, data, STAGE_INITIALIZED )
                        else
                            -- announced before its `dreamwork.client.spawn`
                            data.initialize_pending = true
                        end
                    end
                end
            end
        end )

    end

    local players = player_GetAll()

    for i = 1, #players, 1 do
        restore( players[ i ] )
    end

    -- loaded after the local client has spawned, e.g. reloaded
    if not initialize_local() then
        engine_hook.catch( "InitPostEntity", "std.client.initialize", function()
            engine_hook.release( "InitPostEntity", "std.client.initialize" )
            initialize_local()
        end )
    end

end

-- TODO:
--
-- https://holylib.raphaelit7.com/HolyLib:GetFreeClient
-- https://holylib.raphaelit7.com/HolyLib:OnClientDisconnect
-- https://holylib.raphaelit7.com/HolyLib:OnClientExecuteStringCommand
-- https://holylib.raphaelit7.com/HolyLib:OnClientTimeout
-- https://holylib.raphaelit7.com/HolyLib:OnPlayerChangedSlot
-- https://holylib.raphaelit7.com/HolyLib:OnSetSignonState
-- https://holylib.raphaelit7.com/HolyLib:ProcessConnectionlessPacket
--
-- https://holylib.raphaelit7.com/HolyLib:OnNotifyClientConnect
--
-- Player:IsTimingOut
--
--
--
