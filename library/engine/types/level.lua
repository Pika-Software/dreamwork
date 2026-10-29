---@meta _

--- [SHARED AND MENU]
---
--- The game-level library.
---
--- BSP: `maps/{name}.bsp`
--- AI navigation: `maps/{name}.ain`
--- Navigation Mesh: `maps/{name}.nav`
---
---@class level
---@field name string The name of the current loaded level.
level = {}

--- [SHARED AND MENU]
---
--- Checks if a map/level exists.
---
---@param name string The map/level name in maps/*.bsp folder.
---@param gamePath? string An optional argument specifying the search location, as an example for addon searches.
---@return boolean
---@nodiscard
function level.exists(name, gamePath) end

--- [SHARED AND MENU]
---
--- Returns the gravity of the current level.
---
---@return integer gravity The gravity of the current level.
---@nodiscard
function level.getGravity() end

--- [SHARED AND MENU]
---
--- It will end the current game, load the specified map and start a new game on it. Players are not kicked from the server.
---@param name string
---@return boolean isSuccessful
function level.change(name) end

--- [SHARED AND MENU]
---
--- Sets the gravity of the current level.
---@param value integer The value to set. Default: 600
function level.setGravity(value) end

--- [SHARED AND MENU]
---
---@class level.save
local save = {}

level.save = save

save.getFileDetails = _G.GetSaveFileDetails
