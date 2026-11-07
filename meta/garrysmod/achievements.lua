---@meta garrysmod.achievements


--- [CLIENT AND MENU]
---
--- This library is used internally by Garry's Mod to help keep track of achievement progress
--- and unlock the appropriate achievements once a certain number is reached.
---
---@class garrysmod.achievements
achievements = {}

--- [CLIENT]
---
--- Adds one to the count of balloons burst. Once this count reaches `1000`, the `Popper` achievement is unlocked.
---
--- > **INTERNAL**: This is used internally - although you're able to use it you probably shouldn't.
---
function achievements.BalloonPopped() end

--- [CLIENT AND MENU]
---
--- Returns the amount of achievements currently in Garry's Mod.
---
--- This will include `1` extra hidden/non functional achievement at index `0`.
---
---@return integer count The amount of achievements available.
function achievements.Count() end

--- [CLIENT]
---
--- Adds one to the count of balls eaten. Once this count reaches `200`, the `Ball Eater` achievement is unlocked.
---
--- > **INTERNAL**: This is used internally - although you're able to use it you probably shouldn't.
---
function achievements.EatBall() end

--- [CLIENT AND MENU]
---
--- Retrieves progress of given achievement.
---
--- One-time achievements **always** have the progress of `0`.
---
---@param achievement_id integer The ID of the achievement.
---@return integer progress The numerical progress.
function achievements.GetCount( achievement_id ) end

--- [CLIENT AND MENU]
---
--- Retrieves the description of the given achievement.
---
---@param achievement_id integer The ID of the achievement.
---@return string description The description.
function achievements.GetDesc( achievement_id ) end

--- [CLIENT AND MENU]
---
--- Retrieves the end progress goal of the given achievement.
---
---@param achievement_id integer The ID of the achievement.
---@return integer goal The end progress goal.
function achievements.GetGoal( achievement_id ) end

--- [CLIENT AND MENU]
---
--- Retrieves the name of the given achievement.
---
---@param achievement_id integer The ID of the achievement.
---@return string name The name.
function achievements.GetName( achievement_id ) end

--- [CLIENT]
---
--- Adds one to the count of baddies killed. Once this count reaches `1000`, the `War Zone` achievement is unlocked.
---
--- > **INTERNAL**: This is used internally - although you're able to use it you probably shouldn't.
---
function achievements.IncBaddies() end

--- [CLIENT]
---
--- Adds one to the count of innocent animals killed. Once this count reaches `1000`, the `Innocent Bystander` achievement is unlocked.
---
--- > **INTERNAL**: This is used internally - although you're able to use it you probably shouldn't.
---
function achievements.IncBystander() end

--- [CLIENT]
---
--- Adds one to the count of friendly NPCs killed. Once this count reaches `1000`, the `Bad Friend` achievement is unlocked.
---
--- > **INTERNAL**: This is used internally - although you're able to use it you probably shouldn't.
---
function achievements.IncGoodies() end

--- [CLIENT AND MENU]
---
--- Returns whether the given achievement is obtained or not.
---
---@param achievement_id integer The ID of the achievement.
---@return boolean achieved The state.
function achievements.IsAchieved( achievement_id ) end

--- [CLIENT]
---
--- Adds one to the count of things removed. Once this count reaches `5000`, the `Destroyer` achievement is unlocked.
---
--- > **INTERNAL**: This is used internally - although you're able to use it you probably shouldn't.
---
function achievements.Remover() end

--- [CLIENT]
---
--- Adds one to the count of NPCs spawned. Once this count reaches `1000`, the `Procreator` achievement is unlocked.
---
--- > **INTERNAL**: This is used internally - although you're able to use it you probably shouldn't.
---
function achievements.SpawnedNPC() end

--- [CLIENT]
---
--- Adds one to the count of props spawned. Once this count reaches `5000`, the `Creator` achievement is unlocked.
---
--- > **INTERNAL**: This is used internally - although you're able to use it you probably shouldn't.
---
function achievements.SpawnedProp() end

--- [CLIENT]
---
--- Adds one to the count of ragdolls spawned. Once this count reaches `2000`, the `Dollhouse` achievement is unlocked.
---
--- > **INTERNAL**: This is used internally - although you're able to use it you probably shouldn't.
---
function achievements.SpawnedRagdoll() end

--- [CLIENT]
---
--- Adds one to the count of how many times the spawnmenu has been opened.
--- Once this count reaches `100000`, the `Menu User` achievement is unlocked.
---
--- > **INTERNAL**: This is used internally - although you're able to use it you probably shouldn't.
---
function achievements.SpawnMenuOpen() end
