local dreamwork_engine = dreamwork.engine

---@class dreamwork.std
local std = dreamwork.std

local setTimeout = std.setTimeout
local clearTimeout = std.clearTimeout

local Future = std.Future

--- The default timeout of server browser requests in seconds.
local DEFAULT_TIMEOUT = 30

---@class dreamwork.std.server.Player
---@field name string The name of the player.
---@field score integer The score of the player.
---@field time number The time the player has been connected, in seconds.

---@alias dreamwork.GModServerListCallback fun( server_ping: number, server_name: string, gamemode_title: string, level_name: string, player_count: number, player_limit: number, bot_count: number, has_password: boolean, last_played_time: number, server_address: string, gamemode_name: string, gamemode_workshopid: number, is_anonymous_server: boolean, gmod_version: string, server_localization: string, gamemode_category: string ): boolean?

---@class dreamwork.GModServerListLib
---@field PingServer fun( ip: string, callback: dreamwork.GModServerListCallback )
---@field PlayerList fun( ip: string, callback: fun( players: dreamwork.std.server.Player[] | nil ) )
---@field AddCurrentServerToFavorites fun( add: boolean? )
---@field IsCurrentServerFavorite fun(): boolean
---@field AddServerToFavorites fun( ip: string )
---@field RemoveServerFromFavorites fun( ip: string )
---@field IsServerFavorite fun( ip: string ): boolean
---@field Query fun( data: { GameDir: string, Type: string, AppID: integer, Callback: dreamwork.GModServerListCallback, CallbackFailed: function?, Finished: function? } )
local glua_serverlist = dreamwork_engine.requireLibrary( "serverlist" )

--- [MENU]
---
--- The server browser library.
---
---@class dreamwork.std.server.browser
local browser = {}
std.server.browser = browser

---@return dreamwork.std.server.Info info
local function make_info( server_ping, server_name, gamemode_title, level_name, player_count, player_limit, bot_count, has_password, last_played_time, server_address, gamemode_name, gamemode_workshopid, is_anonymous_server, gmod_version, server_localization, gamemode_category )
    return {
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
    }
end

---@param future dreamwork.std.Future
---@param address string
local function timeout_expire( future, address )
    if future:isPending() then
        future:setError( "request to '" .. address .. "' timed out" )
    end
end

---@param future dreamwork.std.Future
---@param address string
---@param timeout ( number | false )?
---@return integer | nil timeout_id
local function start_timeout( future, address, timeout )
    if timeout == false then
        return nil
    end

    return setTimeout( timeout_expire, timeout or DEFAULT_TIMEOUT, future, address )
end

do

    local serverlist_PingServer = glua_serverlist.PingServer

    --- [MENU]
    ---
    --- Starts a query of a server for its information/ping, without waiting for it.
    ---
    --- Several requests can be awaited together with `futures.all`.
    ---
    ---@param address string The address of the server. ( IP:Port like `127.0.0.1:27015` )
    ---@param timeout ( number | false )? The timeout in seconds, default is `30`, `false` to disable the timeout.
    ---@return dreamwork.std.Future<dreamwork.std.server.Info> future The future of the server information.
    function browser.requestPing( address, timeout )
        ---@type dreamwork.std.Future<dreamwork.std.server.Info>
        local future = Future()

        local timeout_id = start_timeout( future, address, timeout )

        serverlist_PingServer( address, function( ... )
            if not future:isPending() then return end

            if timeout_id ~= nil then
                clearTimeout( timeout_id )
            end

            future:setResult( make_info( ... ) )
        end )

        return future
    end

    local requestPing = browser.requestPing

    --- [MENU]
    ---
    --- Queries a server for its information/ping.
    ---
    ---@param address string The address of the server. ( IP:Port like `127.0.0.1:27015` )
    ---@param timeout ( number | false )? The timeout in seconds, default is `30`, `false` to disable the timeout.
    ---@return dreamwork.std.server.Info info The server information.
    ---@async
    function browser.ping( address, timeout )
        return requestPing( address, timeout ):await()
    end

end

do

    local serverlist_PlayerList = glua_serverlist.PlayerList

    --- [MENU]
    ---
    --- Starts a query of a server for its player list, without waiting for it.
    ---
    --- Several requests can be awaited together with `futures.all`.
    ---
    ---@param address string The address of the server. ( IP:Port like `127.0.0.1:27015` )
    ---@param timeout ( number | false )? The timeout in seconds, default is `30`, `false` to disable the timeout.
    ---@return dreamwork.std.Future<dreamwork.std.server.Player[]> future The future of the player list.
    function browser.requestPlayers( address, timeout )
        ---@type dreamwork.std.Future<dreamwork.std.server.Player[]>
        local future = Future()

        local timeout_id = start_timeout( future, address, timeout )

        serverlist_PlayerList( address, function( players )
            if not future:isPending() then return end

            if timeout_id ~= nil then
                clearTimeout( timeout_id )
            end

            if players == nil then
                future:setError( "request to '" .. address .. "' returned no player list" )
            else
                future:setResult( players )
            end
        end )

        return future
    end

    local requestPlayers = browser.requestPlayers

    --- [MENU]
    ---
    --- Queries a server for its player list.
    ---
    ---@param address string The address of the server. ( IP:Port like `127.0.0.1:27015` )
    ---@param timeout ( number | false )? The timeout in seconds, default is `30`, `false` to disable the timeout.
    ---@return dreamwork.std.server.Player[] players The players on the server.
    ---@async
    function browser.getPlayers( address, timeout )
        return requestPlayers( address, timeout ):await()
    end

end

do

    local serverlist_Query = glua_serverlist.Query

    --- [MENU]
    ---
    --- Queries the master server for the server list.
    ---
    ---@param data dreamwork.std.server.QueryData The query data to send to the master server.
    function browser.query( data )
        local server_queried = data.server_queried

        serverlist_Query( {
            GameDir = data.directory,
            Type = data.type,
            AppID = data.appid,
            Callback = function( ... )
                return server_queried( make_info( ... ) )
            end,
            CallbackFailed = data.query_failed,
            Finished = data.finished
        } )
    end

end

--- [MENU]
---
--- Checks if the server address is blacklisted by Garry's Mod.
---
---@type fun( address: string ): boolean
---@diagnostic disable-next-line: undefined-global
browser.isBlacklisted = IsServerBlacklisted or function() return false end

do

    local serverlist_IsCurrentServerFavorite = glua_serverlist.IsCurrentServerFavorite
    local serverlist_IsServerFavorite = glua_serverlist.IsServerFavorite

    --- [MENU]
    ---
    --- Checks if the given server address is in the player's favorites.
    ---
    ---@param address string? The address of the server, current server if `nil`. ( IP:Port like `127.0.0.1:27015` )
    ---@return boolean is_favorite `true` if the given server is in player favorites, `false` if not.
    ---@nodiscard
    function browser.isFavorite( address )
        if address == nil then
            return serverlist_IsCurrentServerFavorite()
        end

        return serverlist_IsServerFavorite( address )
    end

end

do

    local serverlist_AddCurrentServerToFavorites = glua_serverlist.AddCurrentServerToFavorites
    local serverlist_AddServerToFavorites = glua_serverlist.AddServerToFavorites
    local serverlist_RemoveServerFromFavorites = glua_serverlist.RemoveServerFromFavorites

    --- [MENU]
    ---
    --- Adds the given server address to the player's favorites.
    ---
    ---@param address string? The address of the server, current server if `nil`. ( IP:Port like `127.0.0.1:27015` )
    function browser.addFavorite( address )
        if address == nil then
            serverlist_AddCurrentServerToFavorites( true )
        else
            serverlist_AddServerToFavorites( address )
        end
    end

    --- [MENU]
    ---
    --- Removes the given server address from the player's favorites.
    ---
    ---@param address string? The address of the server, current server if `nil`. ( IP:Port like `127.0.0.1:27015` )
    function browser.removeFavorite( address )
        if address == nil then
            serverlist_AddCurrentServerToFavorites( false )
        else
            serverlist_RemoveServerFromFavorites( address )
        end
    end

end
