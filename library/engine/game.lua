---@meta _

---@class Game : Object
local Game = {}

--- [SHARED AND MENU]
---
--- The game library.
---
---@class game
---@field TickInterval number The time between ticks.
---@field TPS number The ticks per second.
---@field TickTime number The time of the last tick.
---@field Tick integer The current tick id.
game = {}

--- [SHARED AND MENU]
---
--- Returns a list of items corresponding to all games from which Garry's Mod supports content mounting.
---
---@return game.Item[] items The list of games.
---@return integer item_count The length of the items array (`#items`).
---@nodiscard
function game.getAll() end

--- [SHARED AND MENU]
---
--- Checks whether or not a game is currently mounted.
---
---@param folder_name string The folder name of the game.
---@return boolean is_mounted Returns `true` if the game is mounted, `false` otherwise.
---@nodiscard
function game.isMounted(folder_name) end

--- [MENU]
---
--- Mounts or unmounts a game content to the client.
---
---@param appID number Steam AppID of the game.
---@param value boolean `true` to mount, `false` to unmount.
function game.setMount(appID, value) end

--- [SHARED AND MENU]
---
--- A hook that is called every tick.
---
game.OnTick = nil

--- [SHARED]
---
--- A hook that is called when the game is shutting down.
---
game.OnShutDown = nil
