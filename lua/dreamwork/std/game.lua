local _G = _G

local dreamwork = _G.dreamwork
local engine = dreamwork.engine

---@class dreamwork.std
local std = dreamwork.std

local debug = std.debug

local glua_engine = _G.engine
local glua_game = _G.game
local glua_util = _G.util

--- [SHARED AND MENU]
---
--- The game library.
---
---@class dreamwork.std.game
local game = std.game or {}
std.game = game

game.getUptime = game.getUptime or _G.SysTime
game.addDebugInfo = game.addDebugInfo or _G.DebugInfo

game.getTickTime = game.getTickTime or _G.FrameTime or function() return 1 end
game.getTickCount = game.getTickCount or glua_engine.TickCount or function() return 1 end
game.getTickInterval = game.getTickInterval or glua_engine.TickInterval or function() return 0.1 end

do

    --- [SHARED AND MENU]
    ---
    --- Returns a list of items corresponding to all games from which Garry's Mod supports content mounting.
    ---
    ---@return dreamwork.std.game.Item[] items The list of games.
    ---@return integer item_count The length of the items array (`#items`).
    function game.getAll()
        local item_count = engine.game_count
        local games = engine.games
        local items = {}

        for i = 1, item_count, 1 do
            local data = games[ i ]
            items[ i ] = {
                installed = data.installed,
                mounted = data.mounted,
                folder = data.folder,
                appid = data.depot,
                owned = data.owned,
                title = data.title
            }
        end

        return items, item_count
    end

    local name2game = engine.name2game

    --- [SHARED AND MENU]
    ---
    --- Checks whether or not a game is currently mounted.
    ---
    ---@param folder_name string The folder name of the game.
    ---@return boolean is_mounted Returns `true` if the game is mounted, `false` otherwise.
    function game.isMounted( folder_name )
        if folder_name == "episodic" or folder_name == "ep2" or folder_name == "lostcoast" then
            folder_name = "hl2"
        end

        return name2game[ folder_name ] == true
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

if std.LUA_CLIENT_MENU then
    do

        --- [CLIENT AND MENU]
        ---
        --- The game demo library.
        ---
        ---@class dreamwork.std.game.demo
        local demo = {
            getTotalPlaybackTicks = glua_engine.GetDemoPlaybackTotalTicks,
            getPlaybackStartTick = glua_engine.GetDemoPlaybackStartTick,
            getPlaybackSpeed = glua_engine.GetDemoPlaybackTimeScale,
            getPlaybackTick = glua_engine.GetDemoPlaybackTick,
            isRecording = glua_engine.IsRecordingDemo,
            isPlaying = glua_engine.IsPlayingDemo
        }

        if std.LUA_MENU then
            demo.getFileDetails = _G.GetDemoFileDetails
        end

        game.demo = demo

    end

    do

        local glua_achievements = _G.achievements
        local achievements_Count, achievements_GetName, achievements_GetDesc, achievements_GetCount, achievements_GetGoal, achievements_IsAchieved = glua_achievements.Count, glua_achievements.GetName, glua_achievements.GetDesc, glua_achievements.GetCount, glua_achievements.GetGoal, glua_achievements.IsAchieved

        -- TODO: update code/docs

        --- [CLIENT AND MENU]
        ---
        --- Returns information about an achievement (name, description, value, etc.)
        ---
        ---@param id number The ID of achievement to retrieve name of. Note  IDs start from 0, not 1.
        ---@return table | nil table Returns nil if the ID is invalid.
        local function get( id )
            local goal = achievements_GetGoal( id )
            if goal == nil then return nil end

            local isAchieved = achievements_IsAchieved( id )

            return {
                name = achievements_GetName( id ),
                description = achievements_GetDesc( id ),
                value = isAchieved and goal or achievements_GetCount( id ),
                achieved = isAchieved,
                goal = goal
            }
        end

        --- [CLIENT AND MENU]
        ---
        --- The game achievement library.
        ---
        ---@class dreamwork.std.game.achievement
        local achievement = {
            getCount = achievements_Count,
            get = get
        }

        --- [CLIENT AND MENU]
        ---
        --- Checks if an achievement with the given ID exists.
        ---
        ---@param id number
        ---@return boolean exist Returns true if the achievement exists.
        function achievement.exists( id )
            return achievements_IsAchieved( id ) ~= nil
        end

        --- [CLIENT AND MENU]
        ---
        --- Returns information about all achievements.
        ---
        ---@return table achievement_list The list of all achievements.
        ---@return number achievement_count The count of achievements.
        function achievement.getAll()
            local tbl, count = {}, achievements_Count()
            for index = 0, count - 1 do
                tbl[ index + 1 ] = get( index )
            end

            return tbl, count
        end

        game.achievement = achievement

    end

end

if std.LUA_CLIENT then

    game.getTimeoutInfo = _G.GetTimeoutInfo

end

if std.SHARED then

    game.getAbsoluteFrameTime = glua_engine.AbsoluteFrameTime
    -- game.isDedicatedServer = glua_game.IsDedicated
    -- game.isSinglePlayer = glua_game.SinglePlayer
    game.getDifficulty = glua_game.GetSkillLevel

    -- game.getRealTime = _G.RealTime

    game.getActivityName = glua_util.GetActivityNameByID
    game.getActivityID = glua_util.GetActivityIDByName

    game.getAnimEventName = glua_util.GetAnimEventNameByID
    game.getAnimEventID = glua_util.GetAnimEventIDByName

    game.getModelMeshes = glua_util.GetModelMeshes
    game.getModelInfo = glua_util.GetModelInfo

    -- TODO: https://wiki.facepunch.com/gmod/Global.PrecacheSentenceFile
    -- TODO: https://wiki.facepunch.com/gmod/Global.PrecacheSentenceGroup

    game.precacheModel = glua_util.PrecacheModel
    game.precacheSound = glua_util.PrecacheSound

    if std.SERVER then
        game.precacheScene = _G.PrecacheScene
    end

    -- game.getFrameNumber = _G.FrameNumber

end

if std.SERVER then

    game.setDifficulty = game.setDifficulty or glua_game.SetSkillLevel

end
