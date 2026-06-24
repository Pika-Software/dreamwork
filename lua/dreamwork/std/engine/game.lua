local glua_engine = engine or {}
local glua_game = game or {}

---@class dreamwork.std
local std = dreamwork.std

local class = std.class

local engine = dreamwork.engine
local engine_hookCatch = engine.hookCatch

local os_clock = std.os.clock
local Hook = std.Hook

---@class dreamwork.std.Game : dreamwork.std.Object
local Game = class.base( "Game", true )

local GameClass = class.base( "GameClass", false, Game )

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- The game library.
---
---@class dreamwork.std.game
---@field TickInterval number The time between ticks.
---@field TPS number The ticks per second.
---@field TickTime number The time of the last tick.
---@field Tick integer The current tick id.
local game = std.game or {}
std.game = game

game.getUptime = game.getUptime or _G.SysTime
game.addDebugInfo = game.addDebugInfo or _G.DebugInfo

do

    ---@diagnostic disable-next-line: undefined-field
    local engine_TickCount = glua_engine.TickCount

    if engine_TickCount == nil then
        function engine_TickCount()
            return 0
        end
    end

    ---@diagnostic disable-next-line: undefined-field
    local tick_interval = (glua_engine.TickInterval or std.debug.fempty)()
    local last_tick = os_clock()

    local tick_id = engine_TickCount()

    engine.hookCatch( "Tick", function()
        local ticks_elapsed = engine_TickCount()
        if ticks_elapsed ~= tick_id then
            tick_id = ticks_elapsed

            local current_tick = os_clock()
            tick_interval, last_tick = current_tick - last_tick, current_tick

            game.TickInterval = tick_interval
            game.TPS = 1 / tick_interval
            game.TickTime = last_tick
            game.TickCount = tick_id
        end
    end, 1 )

end

-- game.getTickTime = game.getTickTime or _G.FrameTime or function() return 1 end
-- game.getTickCount = game.getTickCount or glua_engine.TickCount or function() return 1 end
-- game.getTickInterval = game.getTickInterval or glua_engine.TickInterval or function() return 0.1 end

do

    --- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
    ---
    --- Returns a list of items corresponding to all games from which Garry's Mod supports content mounting.
    ---
    ---@return dreamwork.std.game.Item[] items The list of games.
    ---@return integer item_count The length of the items array (`#items`).
    function game.getAll()

        return {}, 0
    end

    --- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
    ---
    --- Checks whether or not a game is currently mounted.
    ---
    ---@param folder_name string The folder name of the game.
    ---@return boolean is_mounted Returns `true` if the game is mounted, `false` otherwise.
    function game.isMounted( folder_name )
        if folder_name == "episodic" or folder_name == "ep2" or folder_name == "lostcoast" then
            folder_name = "hl2"
        end

        -- return name2game[ folder_name ] == true
        return false
    end

end

if std.LUA_MENU then

    local SetMounted = glua_game.SetMounted
    local tostring = std.tostring

    --- [MENU]
    ---
    --- Mounts or unmounts a game content to the client.
    ---
    ---@param appID number Steam AppID of the game.
    ---@param value boolean `true` to mount, `false` to unmount.
    function game.setMount( appID, value )
        SetMounted( tostring( appID ), true )
    end

end

if std.LUA_CLIENT_SERVER then

    game.getAbsoluteFrameTime = glua_engine.AbsoluteFrameTime

    -- game.isDedicatedServer = glua_game.IsDedicated
    -- game.isSinglePlayer = glua_game.SinglePlayer

    -- game.getRealTime = _G.RealTime

    -- TODO: https://wiki.facepunch.com/gmod/Global.PrecacheSentenceFile
    -- TODO: https://wiki.facepunch.com/gmod/Global.PrecacheSentenceGroup

    -- game.getFrameNumber = _G.FrameNumber

end

game.OnTick:attach( function()

end, "engine" )

if game.OnTick == nil then

    --- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
    ---
    --- A hook that is called every tick.
    ---
    local OnTick = Hook( "game.OnTick" )
    engine_hookCatch( "Tick", OnTick )
    game.OnTick = OnTick

end

if game.OnShutDown == nil then

    --- [SHARED]
    ---
    --- A hook that is called when the game is shutting down.
    ---
    local OnShutDown = Hook( "game.OnShutDown" )
    engine_hookCatch( "ShutDown", OnShutDown, 2 )
    game.OnShutDown = OnShutDown

end

-- TODO: rewrite game library
