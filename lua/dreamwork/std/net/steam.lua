local dreamwork_engine = dreamwork.engine
local dreamwork_load = dreamwork.load

---@type garrysmod.steamworks
local glua_steamworks = dreamwork_engine.requireLibrary( "steamworks" )

---@type garrysmod.system
local glua_system = dreamwork_engine.requireLibrary( "system" )

---@type garrysmod.game
local glua_game = dreamwork_engine.requireLibrary( "game" )

---@class dreamwork.std
local std = dreamwork.std

local debug = std.debug
local debug_fempty = debug.fempty

local string = std.string
local string_format = string.format

local time = std.time
local time_now = time.now
local time_elapsed = time.elapsed

local server = std.server

local represent = std.represent
local setTimeout = std.setTimeout
local clearTimeout = std.clearTimeout

local Future = std.Future

local LUA_SERVER = std.LUA_SERVER
local LUA_CLIENT_MENU = std.LUA_CLIENT_MENU


--- [SHARED AND MENU]
---
--- The Steam API library.
---
---@class dreamwork.std.steam
local steam = std.steam or {}
std.steam = steam

dreamwork_load( "std/net/steam/types/error.lua" )
dreamwork_load( "std/net/steam/types/identifier.lua" )

local SteamError = std.SteamError

if LUA_SERVER and server.dedicated then

    --- [SHARED AND MENU]
    ---
    --- Returns the amount of seconds since the Steam user last moved their mouse.
    ---
    --- Always `0` on dedicated servers.
    ---
    ---@return number seconds The amount of seconds since the user was last active.
    ---@nodiscard
    function steam.getAwayTime()
        return 0
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the total uptime of the application in seconds as reported by Steam.
    ---
    --- Uses `time.elapsed` on dedicated servers.
    ---
    ---@return number seconds The uptime in seconds.
    ---@nodiscard
    function steam.getAppTime()
        return time_elapsed()
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the Steam synchronized Unix time in seconds.
    ---
    --- Uses `time.now` on dedicated servers.
    ---
    ---@return integer timestamp The Unix timestamp in seconds.
    ---@nodiscard
    function steam.getTime()
        return time_now()
    end

else

    --- [SHARED AND MENU]
    ---
    --- Returns the amount of seconds since the Steam user last moved their mouse.
    ---
    --- Always `0` on dedicated servers.
    ---
    ---@return number seconds The amount of seconds since the user was last active.
    ---@nodiscard
    steam.getAwayTime = glua_system.UpTime

    --- [SHARED AND MENU]
    ---
    --- Returns the total uptime of the application in seconds as reported by Steam.
    ---
    --- Uses `time.elapsed` on dedicated servers.
    ---
    ---@return number seconds The uptime in seconds.
    ---@nodiscard
    steam.getAppTime = glua_system.AppTime

    --- [SHARED AND MENU]
    ---
    --- Returns the Steam synchronized Unix time in seconds.
    ---
    --- Uses `time.now` on dedicated servers.
    ---
    ---@return integer timestamp The Unix timestamp in seconds.
    ---@nodiscard
    steam.getTime = glua_system.SteamTime

end

if LUA_CLIENT_MENU then

    local steamworks_RequestPlayerInfo = glua_steamworks.RequestPlayerInfo or debug_fempty

    --- The default timeout of Steam requests in seconds.
    local DEFAULT_TIMEOUT = 10

    --- [CLIENT AND MENU]
    ---
    --- Requests the Steam name of the user with the given Steam ID.
    ---
    --- Fails with `SteamError` if Steam doesn't know the account (`EResult` 42) or doesn't respond in time (`EResult` 16).
    ---
    ---@param id dreamwork.std.steam.Identifier The Steam ID of the user, or its SteamID64 string.
    ---@param timeout number? The timeout in seconds, `10` by default.
    ---@return string name The Steam name of the user.
    ---@nodiscard
    ---@async
    function steam.getUserName( id, timeout )
        ---@type dreamwork.std.Future<string>
        local future = Future()

        local timeout_id = setTimeout( function()
            if future:isPending() then
                future:setError( SteamError( 16, string_format( "player info request for `%s` timed out", represent( id ) ) ) )
            end
        end, timeout or DEFAULT_TIMEOUT )

        steamworks_RequestPlayerInfo( id:to64(), function( name )
            if not future:isPending() then return end

            clearTimeout( timeout_id )

            -- Steam answers with "[unknown]" for accounts it can't find
            if name == nil or name == "" or name == "[unknown]" then
                future:setError( SteamError( 42, string_format( "player info request for `%s` returned no name", represent( id ) ) ) )
                return
            end

            future:setResult( name )
        end )

        return future:await()
    end

end

dreamwork_load( "std/net/steam/achievements.lua", false, LUA_SERVER )
