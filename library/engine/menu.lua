---@meta _

--- [CLIENT AND MENU]
---
--- The game's main menu library.
---
---@class menu
---@field visible boolean `true` if the menu is visible, `false` otherwise.
menu = {}

menu.open = debug.fempty

menu.openURL = debug.fempty

--- [MENU]
---
--- Runs a menu command.
---
--- Equivalent to `console.Command.run( "gamemenucommand", command )` unless the command starts with the "engine" keyword in which case it is equivalent to `console.Command.run( command )`.
---
---@param cmd string The command to run.
function menu.run(cmd) end

--- [MENU]
---
--- Closes the menu and returns to the game.
---
function menu.close() end

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

--- [MENU]
---
--- The game's menu loading ( connecting to the server ) module.
---
---@class menu.loading
local loading = {}

menu.loading = loading

--- [CLIENT AND MENU]
---
--- The game's menu options module.
---
---@class menu.options
local options = {}

--- [CLIENT AND MENU]
---
--- Gets the master volume.
---
---@return number master_volume The volume, from 0 to 1.
---@nodiscard
function options.getMasterVolume() end

--- [CLIENT AND MENU]
---
--- Gets the effects volume.
---
---@return number sfx_volume The volume, from 0 to 1.
---@nodiscard
function options.getEffectsVolume() end

--- [CLIENT AND MENU]
---
--- Gets the music volume.
---
---@return number music_volume The volume, from 0 to 1.
---@nodiscard
function options.getMusicVolume() end

--- [CLIENT AND MENU]
---
--- Gets the HEV suit volume.
---
---@return number hev_volume The volume, from 0 to 1.
---@nodiscard
function options.getSuitVolume() end

--- [CLIENT AND MENU]
---
--- Gets whether to mute the volume when the game loses focus.
---
---@return boolean muted Whether to mute the volume.
---@nodiscard
function options.getMuteVolumeOnLoseFocus() end

--- [CLIENT AND MENU]
---
--- Returns the selected game language.
---
--- All language codes https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes.
---
---@return string language_code ISO 639-1 language code.
---@nodiscard
function options.getLanguage() end

--- [CLIENT AND MENU]
---
--- Returns whether the fast weapon switch is enabled.
---
---@return boolean enabled Whether the fast weapon switch is enabled.
---@nodiscard
function options.getFastWeaponSwitch() end

--- [CLIENT AND MENU]
---
--- Returns whether the quick info is enabled.
---
---@return boolean enabled Whether the quick info is enabled.
---@nodiscard
function options.getQuickInfo() end

--- [CLIENT AND MENU]
---
--- Returns whether the crosshair is enabled.
---
---@return boolean enabled Whether the crosshair is enabled.
---@nodiscard
function options.getCrosshair() end

--- [CLIENT AND MENU]
---
--- Returns whether the HUD render (health, ammo, etc) is enabled.
---
---@return boolean enabled Whether the HUD render is enabled.
---@nodiscard
function options.getDrawHUD() end

--- [CLIENT AND MENU]
---
--- Returns client's mouse sensitivity.
---
---@return number sensitivity The mouse sensitivity.
---@nodiscard
function options.getMouseSensitivity() end

--- [CLIENT AND MENU]
---
--- Returns whether the loading URL is enabled.
---
---@return boolean allowed Whether the loading URL is enabled.
---@nodiscard
function options.isCustomLoadingScreenAllowed() end

--- [CLIENT AND MENU]
---
--- Returns the width and height of the game's window (in pixels).
---
---@return number width The width of the game's window (in pixels).
---@return number height The height of the game's window (in pixels).
---@nodiscard
function options.getScreenResolution() end

options.getFullscreen = window.isFullscreen

--- [CLIENT AND MENU]
---
--- Returns whether the game is running in VSync mode.
---
---@return boolean is_on `true` if the game is running in VSync mode, `false` if not.
---@nodiscard
function options.getVSync() end

--- [CLIENT AND MENU]
---
--- Checks if close captions are enabled.
---
---@return boolean is_enabled `true` if close captions are enabled, `false` otherwise.
---@nodiscard
function options.getCloseCaptions() end

--- [CLIENT AND MENU]
---
--- Enables or disables close captions.
---
---@param state boolean `true` to enable close captions, `false` to disable them.
function options.setCloseCaptions(state) end

--- [MENU]
---
--- Reloads all local addons. (**garrysmod/addons**)
---
function menu.reloadAddons() end

--- [MENU]
---
--- Sets the master volume.
---
---@param volume number The volume to set, from 0 to 1.
function options.setMasterVolume(volume) end

--- [MENU]
---
--- Sets the effects volume.
---
---@param volume number The volume to set, from 0 to 1.
function options.setEffectsVolume(volume) end

--- [MENU]
---
--- Sets the music volume.
---
---@param volume number The volume to set, from 0 to 1.
function options.setMusicVolume(volume) end

--- [MENU]
---
--- Sets the HEV suit volume.
---
---@param volume number The volume to set, from 0 to 1.
function options.setSuitVolume(volume) end

--- [MENU]
---
--- Sets whether to mute the volume when the game loses focus.
---
---@param mute boolean Whether to mute the volume.
function options.setMuteVolumeOnLoseFocus(mute) end

--- [MENU]
---
--- Sets the selected game language.
---
--- All language codes https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes.
---
---@param language string ISO 639-1 language code.
function options.setLanguage(language) end

--- [MENU]
---
--- Sets whether the fast weapon switch is enabled.
---
---@param value boolean Whether the fast weapon switch is enabled.
function options.setFastWeaponSwitch(value) end

--- [MENU]
---
--- Sets whether the quick info is enabled.
---
---@param value boolean Whether the quick info is enabled.
function options.setQuickInfo(value) end

--- [MENU]
---
--- Sets whether the crosshair is enabled.
---
---@param value boolean Whether the crosshair is enabled.
function options.setCrosshair(value) end

--- [MENU]
---
--- Sets whether the HUD render (health, ammo, etc) is enabled.
---
---@param value boolean Whether the HUD render is enabled.
function options.setDrawHUD(value) end

--- [MENU]
---
--- Sets the mouse sensitivity.
---
---@param value number The mouse sensitivity.
function options.setMouseSensitivity(value) end

--- [MENU]
---
--- Sets whether the loading URL is enabled.
---
---@param value boolean Whether the loading URL is enabled.
function options.allowCustomLoadingScreen(value) end

--- [MENU]
---
--- Changes the resolution of the game window.
---
---@param width? integer The width of the game window.
---@param height? integer The height of the game window.
function options.setScreenResolution(width, height) end

--- [MENU]
---
--- Sets whether the game is running in VSync mode.
---
---@param value boolean `true` to enable VSync, `false` to disable it.
function options.setVSync(value) end

--- [MENU]
---
--- Sets the fullscreen state of the game window.
---@param value boolean `true` to set the game window to fullscreen, `false` to set it to windowed.
function options.setFullscreen(value) end

--- [MENU]
---
--- Opens the options dialog.
---
function options.open() end

menu.options = options
