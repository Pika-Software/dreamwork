---@meta _

--- [CLIENT AND MENU]
---
--- The game's menu options module.
---
---@class menu.options
menu.options = {}

--- [CLIENT AND MENU]
---
--- Gets the master volume.
---
---@return number master_volume The volume, from 0 to 1.
---@nodiscard
function menu.options.getMasterVolume() end

--- [CLIENT AND MENU]
---
--- Gets the effects volume.
---
---@return number sfx_volume The volume, from 0 to 1.
---@nodiscard
function menu.options.getEffectsVolume() end

--- [CLIENT AND MENU]
---
--- Gets the music volume.
---
---@return number music_volume The volume, from 0 to 1.
---@nodiscard
function menu.options.getMusicVolume() end

--- [CLIENT AND MENU]
---
--- Gets the HEV suit volume.
---
---@return number hev_volume The volume, from 0 to 1.
---@nodiscard
function menu.options.getSuitVolume() end

--- [CLIENT AND MENU]
---
--- Gets whether to mute the volume when the game loses focus.
---
---@return boolean muted Whether to mute the volume.
---@nodiscard
function menu.options.getMuteVolumeOnLoseFocus() end

--- [CLIENT AND MENU]
---
--- Returns the selected game language.
---
--- All language codes https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes.
---
---@return string language_code ISO 639-1 language code.
---@nodiscard
function menu.options.getLanguage() end

--- [CLIENT AND MENU]
---
--- Returns whether the fast weapon switch is enabled.
---
---@return boolean enabled Whether the fast weapon switch is enabled.
---@nodiscard
function menu.options.getFastWeaponSwitch() end

--- [CLIENT AND MENU]
---
--- Returns whether the quick info is enabled.
---
---@return boolean enabled Whether the quick info is enabled.
---@nodiscard
function menu.options.getQuickInfo() end

--- [CLIENT AND MENU]
---
--- Returns whether the crosshair is enabled.
---
---@return boolean enabled Whether the crosshair is enabled.
---@nodiscard
function menu.options.getCrosshair() end

--- [CLIENT AND MENU]
---
--- Returns whether the HUD render (health, ammo, etc) is enabled.
---
---@return boolean enabled Whether the HUD render is enabled.
---@nodiscard
function menu.options.getDrawHUD() end

--- [CLIENT AND MENU]
---
--- Returns client's mouse sensitivity.
---
---@return number sensitivity The mouse sensitivity.
---@nodiscard
function menu.options.getMouseSensitivity() end

--- [CLIENT AND MENU]
---
--- Returns whether the loading URL is enabled.
---
---@return boolean allowed Whether the loading URL is enabled.
---@nodiscard
function menu.options.isCustomLoadingScreenAllowed() end

--- [CLIENT AND MENU]
---
--- Returns the width and height of the game's window (in pixels).
---
---@return number width The width of the game's window (in pixels).
---@return number height The height of the game's window (in pixels).
---@nodiscard
function menu.options.getScreenResolution() end

menu.options.getFullscreen = window.isFullscreen

--- [CLIENT AND MENU]
---
--- Returns whether the game is running in VSync mode.
---
---@return boolean is_on `true` if the game is running in VSync mode, `false` if not.
---@nodiscard
function menu.options.getVSync() end

--- [CLIENT AND MENU]
---
--- Checks if close captions are enabled.
---
---@return boolean is_enabled `true` if close captions are enabled, `false` otherwise.
---@nodiscard
function menu.options.getCloseCaptions() end

--- [CLIENT AND MENU]
---
--- Enables or disables close captions.
---
---@param state boolean `true` to enable close captions, `false` to disable them.
function menu.options.setCloseCaptions(state) end

--- [CLIENT AND MENU]
---
--- Returns whether materials and models are unloaded on disconnect.
---
--- Unstable. Use at your own risk.
---
---@return boolean enabled `true` if assets are unloaded on disconnect, `false` otherwise.
---@nodiscard
function menu.options.getUnloadOnDisconnect() end

--- [CLIENT AND MENU]
---
--- Returns whether experimental multicore rendering is enabled.
---
---@return boolean enabled `true` if multicore rendering is enabled, `false` otherwise.
---@nodiscard
function menu.options.getMulticoreRendering() end

--- [CLIENT AND MENU]
---
--- Returns whether temporary files downloaded from servers (such as sprays) are deleted.
---
---@return boolean enabled `true` if temporary files are deleted, `false` otherwise.
---@nodiscard
function menu.options.getDeleteTempFiles() end

--- [CLIENT AND MENU]
---
--- Returns the filesystem debug level.
---
--- `0` = off, `1` = on, `2` = extra.
---
---@return integer level The filesystem debug level.
---@nodiscard
function menu.options.getFilesystemDebug() end

--- [CLIENT AND MENU]
---
--- Returns how long the engine sleeps per frame when the game window is unfocused.
---
---@return number milliseconds Sleep duration in milliseconds per frame.
---@nodiscard
function menu.options.getNoFocusSleep() end

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
function menu.options.setMasterVolume(volume) end

--- [MENU]
---
--- Sets the effects volume.
---
---@param volume number The volume to set, from 0 to 1.
function menu.options.setEffectsVolume(volume) end

--- [MENU]
---
--- Sets the music volume.
---
---@param volume number The volume to set, from 0 to 1.
function menu.options.setMusicVolume(volume) end

--- [MENU]
---
--- Sets the HEV suit volume.
---
---@param volume number The volume to set, from 0 to 1.
function menu.options.setSuitVolume(volume) end

--- [MENU]
---
--- Sets whether to mute the volume when the game loses focus.
---
---@param mute boolean Whether to mute the volume.
function menu.options.setMuteVolumeOnLoseFocus(mute) end

--- [MENU]
---
--- Sets the selected game language.
---
--- All language codes https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes.
---
---@param language string ISO 639-1 language code.
function menu.options.setLanguage(language) end

--- [MENU]
---
--- Sets whether the fast weapon switch is enabled.
---
---@param value boolean Whether the fast weapon switch is enabled.
function menu.options.setFastWeaponSwitch(value) end

--- [MENU]
---
--- Sets whether the quick info is enabled.
---
---@param value boolean Whether the quick info is enabled.
function menu.options.setQuickInfo(value) end

--- [MENU]
---
--- Sets whether the crosshair is enabled.
---
---@param value boolean Whether the crosshair is enabled.
function menu.options.setCrosshair(value) end

--- [MENU]
---
--- Sets whether the HUD render (health, ammo, etc) is enabled.
---
---@param value boolean Whether the HUD render is enabled.
function menu.options.setDrawHUD(value) end

--- [MENU]
---
--- Sets the mouse sensitivity.
---
---@param value number The mouse sensitivity.
function menu.options.setMouseSensitivity(value) end

--- [MENU]
---
--- Sets whether the loading URL is enabled.
---
---@param value boolean Whether the loading URL is enabled.
function menu.options.allowCustomLoadingScreen(value) end

--- [MENU]
---
--- Changes the resolution of the game window.
---
---@param width integer? The width of the game window.
---@param height integer? The height of the game window.
function menu.options.setScreenResolution(width, height) end

--- [MENU]
---
--- Sets whether the game is running in VSync mode.
---
---@param value boolean `true` to enable VSync, `false` to disable it.
function menu.options.setVSync(value) end

--- [MENU]
---
--- Sets the fullscreen state of the game window.
---@param value boolean `true` to set the game window to fullscreen, `false` to set it to windowed.
function menu.options.setFullscreen(value) end

--- [MENU]
---
--- Sets whether materials and models are unloaded on disconnect.
---
--- Unstable. Use at your own risk.
---
---@param value boolean `true` to unload assets on disconnect, `false` to keep them cached.
function menu.options.setUnloadOnDisconnect(value) end

--- [MENU]
---
--- Sets whether experimental multicore rendering is enabled.
---
---@param value boolean `true` to enable multicore rendering, `false` to disable it.
function menu.options.setMulticoreRendering(value) end

--- [MENU]
---
--- Sets whether temporary files downloaded from servers (such as sprays) are deleted.
---
---@param value boolean `true` to delete temporary files, `false` to keep them.
function menu.options.setDeleteTempFiles(value) end

--- [MENU]
---
--- Sets the filesystem debug level.
---
--- Causes the filesystem to print actions. `0` = off, `1` = on, `2` = extra.
---
---@param level integer The filesystem debug level (`0`, `1`, or `2`).
function menu.options.setFilesystemDebug(level) end

--- [MENU]
---
--- Sets how long the engine sleeps per frame when the game window is unfocused.
---
---@param milliseconds number Sleep duration in milliseconds per frame. Use `0` to disable.
function menu.options.setNoFocusSleep(milliseconds) end

--- [MENU]
---
--- Opens the color correction tools UI.
---
function menu.options.openColorCorrectionUI() end

--- [MENU]
---
--- Opens the options dialog.
---
function menu.options.open() end
