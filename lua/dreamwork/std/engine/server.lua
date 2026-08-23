---@class dreamwork.GModEngineLib
---@field ActiveGamemode fun(): string
---@field ServerFrameTime fun(): number
---@field GetIPAddress fun(): string
---@diagnostic disable-next-line: undefined-global
local glua_engine = engine or {}

---@class dreamwork.GModGameLib
---@field SinglePlayer fun(): boolean
---@field IsDedicated fun(): boolean
---@field GetTimeScale fun(): number
---@field SetTimeScale fun(scale: number)
---@diagnostic disable-next-line: undefined-global
local glua_game = game or {}

local engine = dreamwork.engine
local engine_hookCatch = engine.hookCatch

---@class dreamwork.std
local std = dreamwork.std

local debug = std.debug
local debug_fempty = debug.fempty

local Hook = std.Hook

local console = std.console
local console_Variable = console.Variable

--- [SHARED AND MENU]
---
--- The game's server library.
---
---@class dreamwork.std.server
---@field singleplayer boolean `true` if server is running in singleplayer mode, `false` otherwise. **READ-ONLY**
---@field dedicated boolean `true` if server is running as a dedicated server, `false` otherwise. **READ-ONLY**
---@field tickrate number The tickrate of the server in seconds. **READ-ONLY**
local server = {}
std.server = server

---@diagnostic disable-next-line: undefined-global
server.tickrate = 1 / (FrameTime or debug_fempty)()

server.singleplayer = (glua_game.SinglePlayer or debug_fempty)() == true
server.dedicated = (glua_game.IsDedicated or debug_fempty)() == true

-- server.ClientLimit =

if server.getGamemodeName == nil then

    local dreamwork_server_gamemode = console_Variable( {
        name = "dreamwork.server.gamemode",
        description = "The publicly visible gamemode name of the server.",
        replicated = true,
        type = "string"
    } )

    local gamemode_name = (glua_engine.ActiveGamemode or debug_fempty)() or "base"

    --- [SHARED AND MENU]
    ---
    --- Gets the name of the active gamemode.
    ---
    ---@return string name The name of the active gamemode.
    function server.getGamemodeName()
        ---@type string
        ---@diagnostic disable-next-line: assign-type-mismatch
        local name = dreamwork_server_gamemode.value

        if name == "" then
            return gamemode_name
        else
            return name
        end
    end

    if std.LUA_CLIENT_SERVER and server.getGamemode == nil and server.setGamemode == nil then

        ---@type dreamwork.std.Gamemode | nil
        local gamemode_value = nil

        local key2base_key = {
            Name = "title",
            Author = "author",
            Email = "email",
            Website = "website",
            FolderName = "name",
            Folder = "name"
        }

        local translator = {}

        setmetatable( translator, {
            __index = function( _, key )
                if gamemode_value == nil then
                    return nil
                end

                if key == "ThisClass" then
                    ---@diagnostic disable-next-line: need-check-nil
                    return std.type( gamemode_value.__class )
                elseif key == "BaseClass" then
                    return gamemode_value.__parent
                elseif key == "IsSandboxDerived" or key == "TeamBased" then
                    return false
                end

                local base_key = key2base_key[ key ]
                if base_key == nil then
                    return gamemode_value[ key ]
                else
                    return gamemode_value[ base_key ]
                end
            end
        } )

        ---@class dreamwork.GModGModLib
        ---@field GetGamemode fun(): table
        ---@diagnostic disable-next-line: undefined-global
        local glua_gmod = gmod

        ---@class dreamwork.GModGamemodeLib
        ---@field Get fun(name: string): table
        ---@diagnostic disable-next-line: undefined-global
        local glua_gamemode = gamemode

        --- [SHARED]
        ---
        --- Returns the active gamemode object.
        ---
        ---@return boolean is_legacy `true` if the gamemode is a legacy gamemode, `false` otherwise.
        ---@return table | dreamwork.std.Gamemode gamemode The active gamemode object.
        function server.getGamemode()
            if gamemode_value == nil then
                ---@diagnostic disable-next-line: undefined-global
                return true, ((glua_gmod.GetGamemode or debug_fempty)() or GAMEMODE or (glua_gamemode.Get or debug_fempty)( gamemode_name ))
            else
                return false, gamemode_value
            end
        end

        --- [SHARED]
        ---
        --- Sets the active gamemode object.
        ---
        ---@param gm dreamwork.std.Gamemode The new active gamemode object.
        function server.setGamemode( gm )
            gamemode_value = gm

            if gm == nil then
                dreamwork_server_gamemode.value = gamemode_name or "base"
            else
                dreamwork_server_gamemode.value = gm.name or "unknown"
            end
        end

        engine_hookCatch( "dreamwork.gamemode.select", "gamemode.translator", function( name )
            if gamemode_value == nil then
                return nil
            else
                return translator
            end
        end, -1000 )

    end

    if server.getGamemodeTitle == nil then

        --- [SHARED AND MENU]
        ---
        --- Returns the title of the gamemode in the server browser.
        ---
        ---@return string title The title of the gamemode.
        function server.getGamemodeTitle()
            ---@diagnostic disable-next-line: undefined-field, undefined-global
            return hook.Call( "GetGameDescription" ) or (GM or GAMEMODE or {}).Title or "unknown"
        end

    end

end

---@type fun(): number
---@diagnostic disable-next-line: undefined-global
server.getUptime = UnPredictedCurTime
-- server.getPredictedUptime = CurTime

-- function server.getPredictionOffset()
--     return CurTime() - UnPredictedCurTime()
-- end

if std.LUA_CLIENT and server.Tick == nil then

    --- [CLIENT]
    ---
    --- Called once every processed server frame during lag.
    ---
    local Tick = Hook( "server.Tick" )
    engine_hookCatch( "Think", "server.Tick", Tick )
    server.Tick = Tick

end

if std.LUA_CLIENT_MENU then

    server.getFrameTime = glua_engine.ServerFrameTime or function() return 0, 0 end

    ---@class dreamwork.GModPermissionsLib
    ---@field Grant fun()
    ---@field Revoke fun()
    ---@field IsGranted fun()
    ---@field GetAll fun()
    ---@diagnostic disable-next-line: undefined-global
    local glua_permissions = permissions or {}

    server.grantPermission = glua_permissions.Grant or debug_fempty
    server.revokePermission = glua_permissions.Revoke or debug_fempty
    server.hasPermission = glua_permissions.IsGranted or function() return false end
    server.getAllPermissions = glua_permissions.GetAll or function() return {} end

end

if std.LUA_MENU then

    --- [MENU]
    ---
    --- Called when the server details are received from the server.
    ---
    local server_Details = std.Hook( "server.GameDetails" )
    engine_hookCatch( "dreamwork.server.details", "server.Details", server_Details )
    server.Details = server_Details

end

do

    local string_match = std.string.match

    local game_GetIPAddress = glua_engine.GetIPAddress or function() return "127.0.0.1:27015" end
    server.getAddress = game_GetIPAddress

    --- [SHARED AND MENU]
    ---
    --- Returns the IP of the server.
    ---
    ---@return string ip The IP of the server.
    function server.getIP()
        return string_match( game_GetIPAddress(), "(%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?):" ) or "127.0.0.1"
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the port of the server.
    ---
    ---@return string port The port of the server.
    function server.getPort()
        return string_match( game_GetIPAddress(), ":(%d+)" ) or "27015"
    end

end

if server.getName == nil then

    local dreamwork_server_hostname = console_Variable( {
        name = "dreamwork.server.hostname",
        description = "The publicly visible name of the server.",
        replicated = true,
        type = "string"
    } )

    --- [SHARED AND MENU]
    ---
    --- Gets the name of the server.
    ---
    ---@return string hostname The name of the server.
    function server.getName()
        ---@diagnostic disable-next-line: return-type-mismatch
        return dreamwork_server_hostname.value
    end

    if std.LUA_SERVER then

        local hostname = console_Variable.get( "hostname", "string" )

        if hostname ~= nil then
            dreamwork_server_hostname.value = hostname.value

            dreamwork_server_hostname:attach( function( _, value )
                if hostname.value ~= value then
                    hostname.value = value
                end
            end, hostname.name )

            hostname:attach( function( _, value )
                if dreamwork_server_hostname.value ~= value then
                    dreamwork_server_hostname.value = value
                end
            end, dreamwork_server_hostname.name )
        end

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

if std.LUA_CLIENT_SERVER then

    do

        local game_GetTimeScale = glua_game.GetTimeScale or debug

        ---@type dreamwork.std.console.Variable<number>
        local host_timescale = console_Variable.get( "host_timescale", "float" )

        --- [SERVER]
        ---
        --- Gets the time scale of the game.
        ---
        ---@return number timescale The current time scale of the game.
        function server.getTimeScale()
            return host_timescale.value * game_GetTimeScale()
        end

    end

    --- [SHARED]
    ---
    --- Checks if cheats are enabled.
    ---
    ---@return boolean enabled `true` if cheats are enabled, `false` if not.
    function server.isCheatsEnabled()
        return console_Variable.getBoolean( "sv_cheats" )
    end

    --- [SHARED]
    ---
    --- Enables or disables cheats.
    ---
    --- It gives all players access to commmands that would normally be abused or misused by players.
    ---
    ---@param bool boolean `true` to enable cheats, `false` to disable them.
    function server.setCheatsEnabled( bool )
        console_Variable.set( "sv_cheats", bool )
    end

    --- [SHARED]
    ---
    --- Checks if the server allows clients to run `lua_openscript_cl` and `lua_run_cl`.
    ---
    ---@return boolean allowed `true` if the server allows clients to run lua_openscript_cl and lua_run_cl, `false` if not.
    function server.isUserScriptsAllowed()
        return console_Variable.getBoolean( "sv_allowcslua" )
    end

end

if std.LUA_SERVER then

    server.setTimeScale = glua_game.SetTimeScale or debug_fempty

    local command_run = console.Command.run

    --- [SERVER]
    ---
    --- Shutdown the engine immediately.
    ---
    function server.kill()
        command_run( "killserver" )
    end

    if server.message == nil then

        ---@type fun( message_type: ( 1 | 2 | 3 | 4 ), message: string )
        ---@diagnostic disable-next-line: undefined-global
        local PrintMessage = PrintMessage or debug_fempty

        --- [SERVER]
        ---
        --- Sends a message to all players on the server.
        ---
        --- This message will be displayed in the console, chat or HUD.
        ---
        ---@param message string The message to print.
        ---@param in_chat? boolean `true` to print the message in chat, `false` to print it in the console only.
        ---@param in_hud? boolean `true` to print the message in the HUD (center of the screen), `false` to not print it.
        function server.message( message, in_chat, in_hud )
            if in_chat then
                PrintMessage( 3, message )
            else
                PrintMessage( 2, message )
            end

            if in_hud then
                PrintMessage( 4, message )
            end
        end

    end

    ---@type fun( message: string )
    ---@diagnostic disable-next-line: undefined-global
    server.log = ServerLog

    --- [SERVER]
    ---
    --- Gets the download URL of the server.
    ---
    ---@return string url The download URL.
    function server.getDownloadURL()
        return console_Variable.getString( "sv_downloadurl" )
    end

    --- [SERVER]
    ---
    --- Sets the download URL of the server.
    ---
    ---@param url string The download URL to set.
    function server.setDownloadURL( url )
        console_Variable.set( "sv_downloadurl", url )
    end

    -- TODO: replace with URL class

    --- [SERVER]
    ---
    --- Checks if the server allows downloads.
    ---
    ---@return boolean allowed Whether the server allows downloads.
    function server.isDowloadAllowed()
        return console_Variable.getBoolean( "sv_allowdownload" )
    end

    --- [SERVER]
    ---
    --- Allow clients to download files from the server.
    ---
    ---@param allowed boolean Whether the server allows downloads.
    function server.allowDownload( allowed )
        console_Variable.set( "sv_allowdownload", allowed )
    end

    --- [SERVER]
    ---
    --- Checks if the server allows uploads.
    ---
    ---@return boolean allowed Whether the server allows uploads.
    function server.isUploadAllowed()
        return console_Variable.getBoolean( "sv_allowupload" )
    end

    --- [SERVER]
    ---
    --- Allow clients to upload customizations files to the server.
    ---
    ---@param allow boolean Whether the server allows uploads.
    function server.allowUpload( allow )
        console_Variable.set( "sv_allowupload", allow )
    end

    ---@alias dreamwork.std.SERVER_REGION
    ---| number # The region of the world to report this server in.
    ---| `0`	US - East
    ---| `1`	US - West
    ---| `2`	South America
    ---| `3`	Europe
    ---| `4`	Asia
    ---| `5`	Australia
    ---| `6`	Middle East
    ---| `7`	Africa
    ---| `255`	World (default)

    --- [SERVER]
    ---
    --- Gets the console_Variable requested by the server browser to determine in which part of the world the server is located.
    ---
    ---@return dreamwork.std.SERVER_REGION region_id The region of the world to report this server in.
    function server.getRegion()
        return console_Variable.getNumber( "sv_region" )
    end

    --- [SERVER]
    ---
    --- Sets the console_Variable requested by the server browser to determine in which part of the world the server is located.
    ---
    ---@param region_id dreamwork.std.SERVER_REGION The region of the world to report this server in.
    function server.setRegion( region_id )
        console_Variable.set( "sv_region", region_id )
    end

    -- TODO: replace with string names

    --- [SERVER]
    ---
    --- Checks if the server is hidden from the master server.
    ---@return boolean hidden `true` if the server is hidden, `false` if not.
    function server.isHidden()
        return console_Variable.getBoolean( "hide_server" )
    end

    --- [SERVER]
    ---
    --- Hides/unhides the server from the master server.
    ---
    ---@param hide boolean `true` to hide the server, `false` to unhide it.
    function server.setHidden( hide )
        console_Variable.set( "hide_server", hide )
    end

    -- TODO: fns for convars: sv_visiblemaxplayers


    --- [SERVER]
    ---
    --- Allow clients to run `lua_openscript_cl` and `lua_run_cl`.
    ---
    ---@param allow boolean `true` to allow clients to run lua_openscript_cl and lua_run_cl, `false` to disallow them.
    function server.allowUserScripts( allow )
        console_Variable.set( "sv_allowcslua", allow )
    end

    --- [SERVER]
    ---
    --- Returns whether or not close captions are allowed in multiplayer.
    ---
    ---@return boolean result `true` if close captions are allowed, `false` otherwise.
    function server.isCloseCaptionsAllowed()
        return console_Variable.getBoolean( "closecaption_mp" )
    end

    --- [SERVER]
    ---
    --- Allow/disallow closecaptions in multiplayer (for dedicated servers).
    ---
    ---@param enable boolean `true` to enable close captions, `false` to disable them.
    function server.allowCloseCaptions( enable )
        console_Variable.set( "closecaption_mp", enable )
    end

    --[[

        TODO:

        - lua_networkvar_bytespertick: Allows you to control how many bytes are networked each tick.
            This should affect all NW functions. not NW2

        - gmod_sneak_attack: If set to 0 disables HL2's sneak attack, where headshotting
            NPCs that haven't seen the player would result in an instant kill.

        - sv_infinite_aux_power: This boolean ConVar enables/disables infinite suit power on the server. (For usual only on Half-Life 2 and modifications)
            when sv_infinite_aux_power is non-zero players will have infinitive suit power.

        https://wiki.facepunch.com/gmod/Blocked_ConCommands

        https://developer.valvesoftware.com/wiki/Console_Command_List

    --]]

    if server.setGamemodeTitile == nil then

        local title = nil

        engine_hookCatch( "GetGameDescription", "gamemode.title", function()
            return title
        end, 1000 )

        --- [SERVER]
        ---
        --- Sets the title of the gamemode in the server browser.
        ---
        ---@param str string The title to set.
        function server.setGamemodeTitile( str )
            title = str
        end

    end

end

if std.LUA_MENU then

    ---@class dreamwork.GModServerListLib
    ---@field PingServer fun( ip: string, callback: fun( server_ping: number, server_name: string, gamemode_title: string, level_name: string, player_count: number, player_limit: number, bot_count: number, has_password: boolean, last_played_time: number, server_address: string, gamemode_name: string, gamemode_workshopid: number, is_anonymous_server: boolean, gmod_version: string, server_localization: string, gamemode_category: string ) )
    ---@field PlayerList fun( ip: string, callback: fun( players: { time: number, name: string, score: string }[] ) )
    ---@field AddCurrentServerToFavorites fun()
    ---@field IsCurrentServerFavorite fun(): boolean
    ---@field AddServerToFavorites fun( ip: string )
    ---@field RemoveServerFromFavorites fun( ip: string )
    ---@field IsServerFavorite fun( ip: string ): boolean
    ---@field Query fun( data: { GameDir: string, Type: string, AppID: integer, Callback: fun( server_ping: number, server_name: string, gamemode_title: string, level_name: string, player_count: number, player_limit: number, bot_count: number, has_password: boolean, last_played_time: number, server_address: string, gamemode_name: string, gamemode_workshopid: number, is_anonymous_server: boolean, gmod_version: string, server_localization: string, gamemode_category: string ), CallbackFailed: fun( reason: string ), Finished: fun() } )
    ---@diagnostic disable-next-line: undefined-global
    local glua_serverlist = serverlist
    local setTimeout = std.setTimeout
    local Future = std.Future

    do

        local serverlist_PingServer = glua_serverlist.PingServer

        --- [MENU]
        ---
        --- Queries a server for its information/ping.
        ---
        ---@param address string The address of the server. ( IP:Port like `127.0.0.1:27015` )
        ---@param timeout number? The timeout in seconds. Set to `false` to disable the timeout.
        ---@return dreamwork.std.server.Info info The server information.
        ---@async
        function server.ping( address, timeout )
            local f = Future()

            serverlist_PingServer( address, function( server_ping, server_name, gamemode_title, level_name, player_count, player_limit, bot_count, has_password, last_played_time, server_address, gamemode_name, gamemode_workshopid, is_anonymous_server, gmod_version, server_localization, gamemode_category )
                f:setResult( {
                    ping = server_ping,
                    name = server_name,
                    version = gmod_version,
                    level_name = level_name,
                    address = server_address,
                    country = server_localization,
                    last_played_time = last_played_time,
                    has_password = has_password,
                    is_anonymous = is_anonymous_server,
                    player_count = player_count,
                    player_limit = player_limit,
                    bot_count = bot_count,
                    human_count = player_count - bot_count,
                    gamemode_name = gamemode_name,
                    gamemode_title = gamemode_title,
                    gamemode_wsid = gamemode_workshopid,
                    gamemode_category = gamemode_category
                } )
            end )

            if timeout ~= false then
                setTimeout( function()
                    if f:isPending() then
                        f:setError( "timed out" )
                    end
                end, timeout or 30 )
            end

            return f:await()
        end

    end

    do

        local serverlist_PlayerList = glua_serverlist.PlayerList

        --- [MENU]
        ---
        --- Queries a server for it's player list.
        ---
        ---@param address string The address of the server. ( IP:Port like `127.0.0.1:27015` )
        ---@param timeout number? The timeout in seconds. Set to `false` to disable the timeout.
        ---@async
        function server.getPlayers( address, timeout )
            local f = Future()

            serverlist_PlayerList( address, function( data )
                if data == nil then
                    f:setError( "failed to get player list" )
                else
                    f:setResult( data )
                end
            end )

            if timeout ~= false then
                setTimeout( function()
                    if f:isPending() then
                        f:setError( "timed out" )
                    end
                end, timeout or 30 )
            end

            return f:await()
        end

    end

    --- [MENU]
    ---
    --- Queries the master server for server list.
    ---
    ---@param data dreamwork.std.server.QueryData The query data to send to the master server.
    function server.getAll( data )
        glua_serverlist.Query( {
            GameDir = data.directory,
            Type = data.type,
            AppID = data.appid,
            Callback = data.server_queried,
            CallbackFailed = data.query_failed,
            Finished = data.finished
        } )
    end

    ---@type fun( ip: string ): boolean
    ---@diagnostic disable-next-line: undefined-global
    server.isInBlacklist = IsServerBlacklisted

    do

        local serverlist_IsCurrentServerFavorite = glua_serverlist.IsCurrentServerFavorite
        local serverlist_IsServerFavorite = glua_serverlist.IsServerFavorite

        --- [MENU]
        ---
        --- Returns true if the given server address is in their favorites.
        ---
        ---@param address string? The address of the server, current server if `nil`. ( IP:Port like `127.0.0.1:27015` )
        ---@return boolean is_favorite `true` if the given server is in player favorites, `false` if not.
        function server.isInFavorites( address )
            if address == nil then
                return serverlist_IsCurrentServerFavorite()
            else
                return serverlist_IsServerFavorite( address )
            end
        end

    end

    local serverlist_AddCurrentServerToFavorites = glua_serverlist.AddCurrentServerToFavorites

    do

        local serverlist_AddServerToFavorites = glua_serverlist.AddServerToFavorites

        --- [MENU]
        ---
        --- Adds the given server address to their favorites.
        ---
        ---@param address string? The address of the server, current server if `nil`. ( IP:Port like `127.0.0.1:27015` )
        function server.addToFavorites( address )
            if address == nil then
                ---@diagnostic disable-next-line: redundant-parameter
                serverlist_AddCurrentServerToFavorites( true )
            else
                serverlist_AddServerToFavorites( address )
            end
        end

    end

    do

        local serverlist_RemoveServerFromFavorites = glua_serverlist.RemoveServerFromFavorites

        --- [MENU]
        ---
        --- Removes the given server address from their favorites.
        ---
        ---@param address string? The address of the server, current server if `nil`. ( IP:Port like `127.0.0.1:27015` )
        function server.removeFromFavorites( address )
            if address == nil then
                ---@diagnostic disable-next-line: redundant-parameter
                serverlist_AddCurrentServerToFavorites( false )
            else
                serverlist_RemoveServerFromFavorites( address )
            end
        end

    end

end

-- TODO: put https://wiki.facepunch.com/gmod/Global.SuppressHostEvents somewhere
