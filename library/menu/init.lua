---@meta _

--- [CLIENT AND MENU]
---
--- The game's main menu library.
---
---@class menu
---@field visible boolean `true` if the menu is visible, `false` otherwise.
menu = {}

function menu.run(command) end

--- [MENU]
---
--- Closes the menu and returns to the game.
---
function menu.hide() end

--- [MENU]
---
--- Opens the legacy server browser.
---
function menu.openServerBrowser() end

--- [MENU]
---
--- Opens the Source "Load Game" dialog.
---
function menu.openGameLoadDialog() end

--- [MENU]
---
--- Opens the Source "Save Game" dialog.
---
function menu.openGameSaveDialog() end

--- [MENU]
---
--- Opens the "Mute Players" dialog that shows all players connected to the server and allows to mute them.
---
function menu.openPlayerList() end

--- [MENU]
---
--- Quits the game.
---
--- **NOTE**: confirmation dialog is broken in Garry's mod and `no_confirm` do nothing.
---
---@param no_confirm boolean Whether to skip the confirmation prompt.
function menu.quit(no_confirm) end
