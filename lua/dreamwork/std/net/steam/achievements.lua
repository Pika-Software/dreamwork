local dreamwork_engine = dreamwork.engine

---@type garrysmod.achievements
local glua_achievements = dreamwork_engine.requireLibrary( "achievements" )

local achievements_GetName = glua_achievements.GetName or function() return "unknown" end
local achievements_GetDesc = glua_achievements.GetDesc or achievements_GetName
local achievements_GetCount = glua_achievements.GetCount or function() return 0 end
local achievements_GetGoal = glua_achievements.GetGoal or achievements_GetCount
local achievements_IsAchieved = glua_achievements.IsAchieved or function() return false end

---@class dreamwork.std
local std = dreamwork.std

local debug = std.debug
local debug_fempty = debug.fempty

---@class dreamwork.std.steam
local steam = std.steam


--- The engine reports one extra hidden/non-functional achievement at index `0`.
local achievement_count = ((glua_achievements.Count or debug_fempty)() or 0) - 1

--- [CLIENT AND MENU]
---
--- Information about a Garry's Mod achievement.
---
---@class dreamwork.std.steam.AchievementsInfo
---@field id integer The ID of the achievement, from `1` to `achievements.count`.
---@field name string The name of the achievement.
---@field description string The description of the achievement.
---@field progress integer The current progress, equals `goal` once the achievement is achieved.
---@field goal integer The progress required to achieve the achievement.
---@field achieved boolean `true` if the achievement is achieved, otherwise `false`.

--- [CLIENT AND MENU]
---
--- The Garry's Mod Steam achievements library.
---
--- Achievement IDs are the engine ones, from `1` to `achievements.count`.
---
---@class dreamwork.std.steam.achievements
---@field count integer The amount of achievements in Garry's Mod.
local achievements = {
    count = achievement_count
}

steam.achievements = achievements

--- [CLIENT AND MENU]
---
--- Checks if an achievement with the given ID exists.
---
---@param id integer The ID of the achievement.
---@return boolean exists `true` if the achievement exists, otherwise `false`.
---@nodiscard
local function exists( id )
    return id >= 1 and id <= achievement_count
end

achievements.exists = exists

--- [CLIENT AND MENU]
---
--- Checks if the achievement with the given ID is achieved.
---
---@param id integer The ID of the achievement.
---@return boolean achieved `true` if the achievement is achieved, `false` if not or if it doesn't exist.
---@nodiscard
function achievements.isAchieved( id )
    return exists( id ) and achievements_IsAchieved( id ) == true
end

--- [CLIENT AND MENU]
---
--- Returns the current progress of the achievement with the given ID.
---
--- One-time achievements have no progress counter, so their progress is `0` until they are achieved.
---
---@param id integer The ID of the achievement.
---@return integer | nil progress The progress, equals the goal once the achievement is achieved, `nil` if the achievement doesn't exist.
---@nodiscard
function achievements.getProgress( id )
    if not exists( id ) then
        return nil
    elseif achievements_IsAchieved( id ) then
        return achievements_GetGoal( id )
    end

    return achievements_GetCount( id )
end

--- [CLIENT AND MENU]
---
--- Returns information about the achievement with the given ID.
---
---@param id integer The ID of the achievement.
---@return dreamwork.std.steam.AchievementsInfo | nil info The achievement information, `nil` if the achievement doesn't exist.
---@nodiscard
local function get( id )
    if exists( id ) then
        local goal = achievements_GetGoal( id )
        local achieved = achievements_IsAchieved( id ) == true

        return {
            id = id,
            name = achievements_GetName( id ),
            description = achievements_GetDesc( id ),
            progress = achieved and goal or achievements_GetCount( id ),
            goal = goal,
            achieved = achieved
        }
    end

    return nil
end

achievements.get = get

--- [CLIENT AND MENU]
---
--- Returns information about all achievements.
---
---@return dreamwork.std.steam.AchievementsInfo[] list The list of all achievements, indexed by their IDs.
---@return integer count The amount of achievements.
---@nodiscard
function achievements.getAll()
    ---@type dreamwork.std.steam.AchievementsInfo[]
    local list = {}

    for id = 1, achievement_count, 1 do
        list[ id ] = get( id )
    end

    return list, achievement_count
end
