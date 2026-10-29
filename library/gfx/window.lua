---@meta _

---@class dreamwork.GModSystemLib
---@field IsWindowed fun(): boolean
---@field FlashWindow fun()
local glua_system = {}

--- [CLIENT AND MENU]
---
--- The game's window library.
---
---@class window
---@field width number The width of the game's window (in pixels).
---@field height number The height of the game's window (in pixels).
---@field focus boolean `true` if the game's window has focus, `false` otherwise.
window = {}

--- [CLIENT AND MENU]
---
--- Returns whether the game window is fullscreen.
---
---@return boolean is_on `true` if the game window is fullscreen, `false` if not.
---@nodiscard
function window.isFullscreen() end
