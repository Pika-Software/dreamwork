local dreamwork_load = dreamwork.load

local dreamwork_engine = dreamwork.engine

local engine_hook = dreamwork_engine.hook
local hook_call = engine_hook.call

---@type garrysmod.engine
local glua_engine = dreamwork_engine.requireLibrary( "engine" )

---@type garrysmod.game
local glua_game = dreamwork_engine.requireLibrary( "game" )

---@type holylib.gameserver
local holylib_gameserver = dreamwork_engine.requireLibrary( "gameserver" )

---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_tonumber = raw.tonumber

local rbit = raw.bit
local rbit_tobit = rbit.tobit
local rbit_unsign = rbit.unsign

local debug = std.debug
local debug_fempty = debug.fempty

local math = std.math
local math_clamp = math.clamp

local string = std.string
local string_match = string.match
local string_format = string.format

local ipv4 = std.ipv4
local ipv4_parse = ipv4.parse
local ipv4_toString = ipv4.toString

local console = std.console
local console_Variable = console.Variable
local console_Command = console.Command
local command_run = console_Command.run

local Variable_set = console_Variable.set
local Variable_getString = console_Variable.getString
local Variable_getInteger = console_Variable.getInteger
local Variable_getBoolean = console_Variable.getBoolean

local Event = std.Event

local LUA_MENU = std.LUA_MENU
local LUA_CLIENT = std.LUA_CLIENT
local LUA_SERVER = std.LUA_SERVER
local LUA_CLIENT_MENU = std.LUA_CLIENT_MENU


--- [SHARED AND MENU]
---
--- The game's server library.
---
---@class dreamwork.std.server
---@field singleplayer boolean `true` if server is running in singleplayer mode, `false` otherwise. **READ-ONLY**
---@field dedicated boolean `true` if server is running as a dedicated server, `false` otherwise. **READ-ONLY**
---@field tickrate number The configured number of server ticks per second, see `std.TPS` for the measured one. **READ-ONLY**
---@field slots integer The maximum number of players the server can hold. **READ-ONLY**
---@field gamemode string The name of the active gamemode, `"base"` if unknown. **READ-ONLY**
---@field ipv4 integer The public IPv4 address of the server as an unsigned 32-bit integer, `0x7F000001` ( 127.0.0.1 ) for local servers. **READ-ONLY**
---@field port integer The public UDP port of the server, `27015` by default. **READ-ONLY**
---@field address string The public address of the server in the `ip:port` format. **READ-ONLY**
local server = {}
std.server = server

server.singleplayer = (glua_game.SinglePlayer or debug_fempty)() == true
server.dedicated = (glua_game.IsDedicated or debug_fempty)() == true

server.tickrate = 1 / ((glua_engine.TickInterval or FrameTime or debug_fempty)() or (1 / 66))

local max_slots = (glua_game.MaxPlayers or debug_fempty)() or 1
server.slots = max_slots

server.gamemode = (glua_engine.ActiveGamemode or debug_fempty)() or "base"

--- [SHARED AND MENU]
---
--- Returns the current server time, it is predicted on the client.
---
--- Falls back to `dreamwork.getUpTime` when `CurTime` is not available.
---
---@return number time The server time in seconds.
---@nodiscard
server.getTime = CurTime or dreamwork.getUpTime

do

    local address_ipv4, address_port = 0x7F000001, 27015

    ---@type string
    local address_str

    --- Rebuilds `server.address` and calls the `dreamwork.server.address` hook if it changed.
    local function update_address_string()
        address_str = string_format( "%s:%d", ipv4_toString( address_ipv4 ), address_port )
        if server.address ~= address_str then
            server.address = address_str
            hook_call( "dreamwork.server.address", address_str, address_ipv4, address_port )
        end
    end

    local gameserver_GetUDPPort = holylib_gameserver.GetUDPPort or function() return address_port end
    local game_GetIPAddress = glua_game.GetIPAddress or function() return address_str end

    ---@type dreamwork.std.console.Variable<integer>
    local dreamwork_server_ipv4 = console_Variable( {
        name = "dreamwork_server_ipv4",
        description = "The public IPv4 address of the server as a signed 32-bit integer, kept up to date by the server.",
        default = rbit_tobit( address_ipv4 ),
        type = "integer",
        replicated = true,
        hidden = true,
        notify = true
    } )

    address_ipv4 = rbit_unsign( dreamwork_server_ipv4.value )
    server.ipv4 = address_ipv4

    ---@type dreamwork.std.console.Variable<integer>
    local dreamwork_server_port = console_Variable( {
        name = "dreamwork_server_port",
        description = "The public UDP port of the server, kept up to date by the server.",
        default = address_port,
        type = "integer",
        replicated = true,
        hidden = true,
        notify = true
    } )

    address_port = dreamwork_server_port.value
    server.port = address_port

    update_address_string()

    dreamwork_server_ipv4:attach( function( _, value )
        value = rbit_unsign( value )
        address_ipv4 = value
        server.ipv4 = value
        update_address_string()
    end )

    dreamwork_server_port:attach( function( _, value )
        address_port = value
        server.port = value
        update_address_string()
    end )

    if LUA_SERVER then

        -- yay, another 10 years issue, i love how facepunch do their work
        --
        -- https://github.com/Facepunch/garrysmod-issues/issues/3001

        local function update_address()
            local address = game_GetIPAddress()
            if address == "loopback" then
                address_ipv4, address_port = 0x7F000001, gameserver_GetUDPPort()
            else

                local ip, port = string_match( address, "^([^:]+):(%d+)" )
                if ip == nil then
                    local new_port = gameserver_GetUDPPort()
                    if new_port ~= 0 then
                        address_port = new_port
                    end
                else
                    local new_ipv4 = ipv4_parse( ip )
                    if new_ipv4 ~= 0 then -- 0.0.0.0 magical cases
                        address_ipv4 = new_ipv4
                    end

                    local new_port = raw_tonumber( port, 10 )
                    if new_port == nil or new_port == 0 then
                        new_port = gameserver_GetUDPPort()
                    end

                    if new_port ~= 0 then
                        address_port = new_port
                    end
                end

            end

            dreamwork_server_ipv4.value, dreamwork_server_port.value = rbit_tobit( address_ipv4 ), address_port
            server.ipv4, server.port = address_ipv4, address_port

            update_address_string()
        end

        engine_hook.catch( "GetGameDescription", "dreamwork.server.address", update_address )
        update_address()

    end

end

do

    ---@type dreamwork.std.console.Variable<string>
    local dreamwork_server_hostname = console_Variable( {
        name = "dreamwork_server_hostname",
        description = "The publicly visible name of the server.",
        type = "string",
        replicated = true,
        hidden = true,
        notify = true
    } )

    --- [SHARED AND MENU]
    ---
    --- Gets the name of the server.
    ---
    ---@return string hostname The name of the server.
    ---@nodiscard
    function server.getName()
        return dreamwork_server_hostname.value
    end

    if LUA_SERVER then

        local hostname = console_Variable.get( "hostname", "string" )
        dreamwork_server_hostname.value = hostname.value

        dreamwork_server_hostname:attach( function( _, value )
            if hostname.value ~= value then
                hostname.value = value
            end
        end )

        hostname:attach( function( _, value )
            if dreamwork_server_hostname.value ~= value then
                dreamwork_server_hostname.value = value
            end
        end )

        --- [SERVER]
        ---
        --- Sets the name of the server.
        ---
        ---@param name string The name to set.
        function server.setName( name )
            dreamwork_server_hostname.value = name
        end

    end

end

if LUA_CLIENT or LUA_SERVER then

    --- [SHARED]
    ---
    --- Checks if cheats are enabled.
    ---
    ---@return boolean enabled `true` if cheats are enabled, `false` if not.
    ---@nodiscard
    function server.isCheatsEnabled()
        return Variable_getBoolean( "sv_cheats" )
    end

    --- [SHARED]
    ---
    --- Checks if the server allows clients to run `lua_openscript_cl` and `lua_run_cl`.
    ---
    ---@return boolean allowed `true` if the server allows clients to run `lua_openscript_cl` and `lua_run_cl`, `false` if not.
    ---@nodiscard
    function server.isUserScriptsAllowed()
        return Variable_getBoolean( "sv_allowcslua" )
    end

end

if LUA_SERVER then

    --- [SERVER]
    ---
    --- Shuts down the server immediately.
    ---
    function server.kill()
        command_run( "killserver" ) -- _restart?
    end

    do

        local PrintMessage = PrintMessage or debug_fempty

        --- [SERVER]
        ---
        --- Sends a message to all players on the server.
        ---
        --- This message will be displayed in the console, chat or HUD.
        ---
        ---@param message string The message to print.
        ---@param in_chat boolean? `true` to print the message in chat ( and console ), `false` to print it in the console only.
        ---@param in_hud boolean? `true` to print the message in the HUD (center of the screen), `false` to not print it.
        function server.message( message, in_chat, in_hud )
            PrintMessage( in_chat and 3 or 2, message )

            if in_hud then
                PrintMessage( 4, message )
            end
        end

    end

    --- [SERVER]
    ---
    --- Enables or disables cheats.
    ---
    --- It gives all players access to commands that would normally be abused or misused by players.
    ---
    ---@param enabled boolean `true` to enable cheats, `false` to disable them.
    function server.setCheatsEnabled( enabled )
        Variable_set( "sv_cheats", enabled )
    end

    --- [SERVER]
    ---
    --- Allows or disallows clients to run `lua_openscript_cl` and `lua_run_cl`.
    ---
    ---@param allowed boolean `true` to allow clients to run `lua_openscript_cl` and `lua_run_cl`, `false` to disallow them.
    function server.setUserScriptsAllowed( allowed )
        Variable_set( "sv_allowcslua", allowed )
    end

    --- [SERVER]
    ---
    --- Gets the download URL of the server.
    ---
    ---@return string url The download URL.
    ---@nodiscard
    function server.getDownloadURL()
        return Variable_getString( "sv_downloadurl" )
    end

    --- [SERVER]
    ---
    --- Sets the download URL of the server.
    ---
    ---@param url string The download URL to set.
    function server.setDownloadURL( url )
        Variable_set( "sv_downloadurl", url )
    end

    --- [SERVER]
    ---
    --- Checks if the server allows downloads.
    ---
    ---@return boolean allowed `true` if clients can download files from the server, `false` if not.
    ---@nodiscard
    function server.isDownloadAllowed()
        return Variable_getBoolean( "sv_allowdownload" )
    end

    --- [SERVER]
    ---
    --- Allows or disallows clients to download files from the server.
    ---
    ---@param allowed boolean `true` to allow downloads, `false` to disallow them.
    function server.setDownloadAllowed( allowed )
        Variable_set( "sv_allowdownload", allowed )
    end

    --- [SERVER]
    ---
    --- Checks if the server allows uploads.
    ---
    ---@return boolean allowed `true` if clients can upload customization files ( sprays ) to the server, `false` if not.
    ---@nodiscard
    function server.isUploadAllowed()
        return Variable_getBoolean( "sv_allowupload" )
    end

    --- [SERVER]
    ---
    --- Allows or disallows clients to upload customization files to the server.
    ---
    ---@param allowed boolean `true` to allow uploads, `false` to disallow them.
    function server.setUploadAllowed( allowed )
        Variable_set( "sv_allowupload", allowed )
    end

    --- [SERVER]
    ---
    --- Checks if close captions are allowed in multiplayer.
    ---
    ---@return boolean allowed `true` if close captions are allowed, `false` otherwise.
    ---@nodiscard
    function server.isCloseCaptionsAllowed()
        return Variable_getBoolean( "closecaption_mp" )
    end

    --- [SERVER]
    ---
    --- Allows or disallows close captions in multiplayer (for dedicated servers).
    ---
    ---@param allowed boolean `true` to allow close captions, `false` to disallow them.
    function server.setCloseCaptionsAllowed( allowed )
        Variable_set( "closecaption_mp", allowed )
    end

    --- [SERVER]
    ---
    --- Checks if the server is hidden from the master server.
    ---
    ---@return boolean hidden `true` if the server is hidden, `false` if not.
    ---@nodiscard
    function server.isHidden()
        return Variable_getBoolean( "hide_server" )
    end

    --- [SERVER]
    ---
    --- Hides/unhides the server from the master server.
    ---
    ---@param hidden boolean `true` to hide the server, `false` to unhide it.
    function server.setHidden( hidden )
        Variable_set( "hide_server", hidden )
    end

    --- [SERVER]
    ---
    --- Gets the number of player slots shown in the server browser.
    ---
    --- Values below `1` mean that the real `server.slots` count is shown.
    ---
    ---@return integer slots The number of visible slots.
    ---@nodiscard
    function server.getVisibleSlots()
        return Variable_getInteger( "sv_visiblemaxplayers" )
    end

    --- [SERVER]
    ---
    --- Sets the number of player slots shown in the server browser.
    ---
    --- Does not limit how many players can join, use it to reserve slots ( e.g. for admins ).
    ---
    ---@param slots integer The number of visible slots, clamped between `1` and `server.slots`.
    ---@return integer slots The number of visible slots that was set.
    function server.setVisibleSlots( slots )
        slots = math_clamp( slots, 1, max_slots )
        Variable_set( "sv_visiblemaxplayers", slots )
        return slots
    end

    do

        ---@alias dreamwork.std.server.Region
        ---| "us-east"
        ---| "us-west"
        ---| "south-america"
        ---| "europe"
        ---| "asia"
        ---| "australia"
        ---| "middle-east"
        ---| "africa"
        ---| "world"

        ---@type table<integer, dreamwork.std.server.Region>
        local id2region = {
            [ 0 ] = "us-east",
            [ 1 ] = "us-west",
            [ 2 ] = "south-america",
            [ 3 ] = "europe",
            [ 4 ] = "asia",
            [ 5 ] = "australia",
            [ 6 ] = "middle-east",
            [ 7 ] = "africa",
            [ 255 ] = "world"
        }

        ---@type table<dreamwork.std.server.Region, integer>
        local region2id = {}

        for region_id, region in std.raw.pairs( id2region ) do
            region2id[ region ] = region_id
        end

        --- [SERVER]
        ---
        --- Gets the region the server browser reports this server in.
        ---
        ---@return dreamwork.std.server.Region region The region of the world, `"world"` by default.
        ---@nodiscard
        function server.getRegion()
            return id2region[ Variable_getInteger( "sv_region" ) ] or "world"
        end

        --- [SERVER]
        ---
        --- Sets the region the server browser reports this server in.
        ---
        ---@param region dreamwork.std.server.Region The region of the world, unknown regions are reported as `"world"`.
        function server.setRegion( region )
            Variable_set( "sv_region", region2id[ region ] or 255 )
        end

    end

end

if LUA_CLIENT then

    --- [CLIENT]
    ---
    --- Returns an estimate of the server's performance, equivalent to calling `FrameTime` on the server.
    ---
    ---@return number frame_time The server frame time in seconds.
    ---@return number deviation The standard deviation of the server frame time.
    ---@nodiscard
    server.getFrameTime = glua_engine.ServerFrameTime or function() return 0, 0 end

end

if LUA_MENU then

    --- [MENU]
    ---
    --- Called when the server details are received while connecting to a server.
    ---
    --- Arguments: `details: table` with `server_name: string`, `loading_url: string`, `map_name: string`, `max_players: integer`, `player_steamid64: string` and `gamemode_name: string` keys.
    ---
    local Details = Event( "server.Details" )
    engine_hook.catch( "dreamwork.server.details", "std.server.Details", Details )
    server.Details = Details

end

dreamwork_load( "std/server/permissions.lua", false, not LUA_CLIENT_MENU )
dreamwork_load( "std/server/browser.lua", false, not LUA_MENU )
dreamwork_load( "std/server/hardware.lua", false, not LUA_SERVER )
