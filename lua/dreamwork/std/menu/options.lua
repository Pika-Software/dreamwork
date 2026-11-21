local std = dreamwork.std

local console = std.console
local console_Command = console.Command
local console_Variable = console.Variable

local window = std.window

local LUA_MENU = std.LUA_MENU

---@class dreamwork.std.menu
local menu = std.menu


--- [CLIENT AND MENU]
---
--- The game's menu options module.
---
--- ```lua
--- print( std.menu.options.getMasterVolume() ) -- 0
--- ```
---
---@class dreamwork.std.menu.options
local options = {}
menu.options = options

--- [CLIENT AND MENU]
---
--- Gets the master volume.
---
---@return number master_volume The volume, from 0 to 1.
---@nodiscard
function options.getMasterVolume()
    return console_Variable.getNumber( "volume" )
end

--- [CLIENT AND MENU]
---
--- Gets the effects volume.
---
---@return number sfx_volume The volume, from 0 to 1.
---@nodiscard
function options.getEffectsVolume()
    return console_Variable.getNumber( "volume_sfx" )
end

--- [CLIENT AND MENU]
---
--- Gets the music volume.
---
---@return number music_volume The volume, from 0 to 1.
---@nodiscard
function options.getMusicVolume()
    return console_Variable.getNumber( "snd_musicvolume" )
end

--- [CLIENT AND MENU]
---
--- Gets the HEV suit volume.
---
---@return number hev_volume The volume, from 0 to 1.
---@nodiscard
function options.getSuitVolume()
    return console_Variable.getNumber( "suitvolume" )
end

--- [CLIENT AND MENU]
---
--- Gets whether to mute the volume when the game loses focus.
---
---@return boolean muted Whether to mute the volume.
---@nodiscard
function options.getMuteVolumeOnLoseFocus()
    return console_Variable.getBoolean( "snd_mute_losefocus" )
end

--- [CLIENT AND MENU]
---
--- Returns the selected game language.
---
--- All language codes https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes.
---
---@return string language_code ISO 639-1 language code.
---@nodiscard
function options.getLanguage()
    return console_Variable.getString( "gmod_language" )
end

--- [CLIENT AND MENU]
---
--- Returns whether the fast weapon switch is enabled.
---
---@return boolean enabled Whether the fast weapon switch is enabled.
---@nodiscard
function options.getFastWeaponSwitch()
    return console_Variable.getBoolean( "hud_fastswitch" )
end

--- [CLIENT AND MENU]
---
--- Returns whether the quick info is enabled.
---
---@return boolean enabled Whether the quick info is enabled.
---@nodiscard
function options.getQuickInfo()
    return console_Variable.getBoolean( "hud_quickinfo" )
end

--- [CLIENT AND MENU]
---
--- Returns whether the crosshair is enabled.
---
---@return boolean enabled Whether the crosshair is enabled.
---@nodiscard
function options.getCrosshair()
    return console_Variable.getBoolean( "crosshair" )
end

--- [CLIENT AND MENU]
---
--- Returns whether the HUD render (health, ammo, etc) is enabled.
---
---@return boolean enabled Whether the HUD render is enabled.
---@nodiscard
function options.getDrawHUD()
    return console_Variable.getBoolean( "cl_drawhud" )
end

--- [CLIENT AND MENU]
---
--- Returns client's mouse sensitivity.
---
---@return number sensitivity The mouse sensitivity.
---@nodiscard
function options.getMouseSensitivity()
    return console_Variable.getNumber( "sensitivity" )
end

--- [CLIENT AND MENU]
---
--- Returns whether the loading URL is enabled.
---
---@return boolean allowed Whether the loading URL is enabled.
---@nodiscard
function options.isCustomLoadingScreenAllowed()
    return console_Variable.getBoolean( "cl_enable_loadingurl" )
end

--- [CLIENT AND MENU]
---
--- Returns the width and height of the game's window (in pixels).
---
---@return number width The width of the game's window (in pixels).
---@return number height The height of the game's window (in pixels).
---@nodiscard
function options.getScreenResolution()
    return window.width, window.height
end

options.getFullscreen = window.isFullscreen

--- [CLIENT AND MENU]
---
--- Returns whether the game is running in VSync mode.
---
---@return boolean is_on `true` if the game is running in VSync mode, `false` if not.
---@nodiscard
function options.getVSync()
    return console_Variable.getBoolean( "mat_vsync" )
end

--- [CLIENT AND MENU]
---
--- Checks if close captions are enabled.
---
---@return boolean is_enabled `true` if close captions are enabled, `false` otherwise.
---@nodiscard
function options.getCloseCaptions()
    return console_Variable.getBoolean( "closecaption" )
end

--- [CLIENT AND MENU]
---
--- Enables or disables close captions.
---
---@param state boolean `true` to enable close captions, `false` to disable them.
function options.setCloseCaptions( state )
    console_Variable.set( "closecaption", state )
end

--- [CLIENT AND MENU]
---
--- Returns whether materials and models are unloaded on disconnect.
---
--- Unstable. Use at your own risk.
---
---@return boolean enabled `true` if assets are unloaded on disconnect, `false` otherwise.
---@nodiscard
function options.getUnloadOnDisconnect()
    return console_Variable.getBoolean( "gmod_unload_test" )
end

--- [CLIENT AND MENU]
---
--- Returns whether experimental multicore rendering is enabled.
---
---@return boolean enabled `true` if multicore rendering is enabled, `false` otherwise.
---@nodiscard
function options.getMulticoreRendering()
    return console_Variable.getBoolean( "gmod_mcore_test" )
end

--- [CLIENT AND MENU]
---
--- Returns whether temporary files downloaded from servers (such as sprays) are deleted.
---
---@return boolean enabled `true` if temporary files are deleted, `false` otherwise.
---@nodiscard
function options.getDeleteTempFiles()
    return console_Variable.getBoolean( "gmod_delete_temp_files" )
end

--- [CLIENT AND MENU]
---
--- Returns the filesystem debug level.
---
--- `0` = off, `1` = on, `2` = extra.
---
---@return integer level The filesystem debug level.
---@nodiscard
function options.getFilesystemDebug()
    return console_Variable.getInteger( "fs_tellmeyoursecrets" )
end

--- [CLIENT AND MENU]
---
--- Returns how long the engine sleeps per frame when the game window is unfocused.
---
---@return number milliseconds Sleep duration in milliseconds per frame.
---@nodiscard
function options.getNoFocusSleep()
    return console_Variable.getNumber( "engine_no_focus_sleep" )
end

if LUA_MENU then

    --- [MENU]
    ---
    --- Reloads all local addons. (**garrysmod/addons**)
    ---
    function menu.reloadAddons()
        console_Command.run( "reload_legacy_addons" )
    end

    --- [MENU]
    ---
    --- Sets the master volume.
    ---
    ---@param volume number The volume to set, from 0 to 1.
    function options.setMasterVolume( volume )
        console_Variable.set( "volume", volume )
    end

    --- [MENU]
    ---
    --- Sets the effects volume.
    ---
    ---@param volume number The volume to set, from 0 to 1.
    function options.setEffectsVolume( volume )
        console_Variable.set( "volume_sfx", volume )
    end

    --- [MENU]
    ---
    --- Sets the music volume.
    ---
    ---@param volume number The volume to set, from 0 to 1.
    function options.setMusicVolume( volume )
        console_Variable.set( "snd_musicvolume", volume )
    end

    --- [MENU]
    ---
    --- Sets the HEV suit volume.
    ---
    ---@param volume number The volume to set, from 0 to 1.
    function options.setSuitVolume( volume )
        console_Variable.set( "suitvolume", volume )
    end

    --- [MENU]
    ---
    --- Sets whether to mute the volume when the game loses focus.
    ---
    ---@param mute boolean Whether to mute the volume.
    function options.setMuteVolumeOnLoseFocus( mute )
        console_Variable.set( "snd_mute_losefocus", mute )
    end

    --- [MENU]
    ---
    --- Sets the selected game language.
    ---
    --- All language codes https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes.
    ---
    ---@param language string ISO 639-1 language code.
    function options.setLanguage( language )
        console_Variable.set( "gmod_language", language )
    end

    --- [MENU]
    ---
    --- Sets whether the fast weapon switch is enabled.
    ---
    ---@param value boolean Whether the fast weapon switch is enabled.
    function options.setFastWeaponSwitch( value )
        console_Variable.set( "hud_fastswitch", value )
    end

    --- [MENU]
    ---
    --- Sets whether the quick info is enabled.
    ---
    ---@param value boolean Whether the quick info is enabled.
    function options.setQuickInfo( value )
        console_Variable.set( "hud_quickinfo", value )
    end

    --- [MENU]
    ---
    --- Sets whether the crosshair is enabled.
    ---
    ---@param value boolean Whether the crosshair is enabled.
    function options.setCrosshair( value )
        console_Variable.set( "crosshair", value )
    end

    --- [MENU]
    ---
    --- Sets whether the HUD render (health, ammo, etc) is enabled.
    ---
    ---@param value boolean Whether the HUD render is enabled.
    function options.setDrawHUD( value )
        console_Variable.set( "cl_drawhud", value )
    end

    --- [MENU]
    ---
    --- Sets the mouse sensitivity.
    ---
    ---@param value number The mouse sensitivity.
    function options.setMouseSensitivity( value )
        console_Variable.set( "sensitivity", value )
    end

    --- [MENU]
    ---
    --- Sets whether the loading URL is enabled.
    ---
    ---@param value boolean Whether the loading URL is enabled.
    function options.allowCustomLoadingScreen( value )
        console_Variable.set( "cl_enable_loadingurl", value )
    end

    --- [MENU]
    ---
    --- Changes the resolution of the game window.
    ---
    ---@param width integer? The width of the game window.
    ---@param height integer? The height of the game window.
    function options.setScreenResolution( width, height )
        console_Command.run( "mat_setvideomode", tostring( width or window.width ), tostring( height or window.height ), window.isWindowed() and 1 or 0 )
    end

    --- [MENU]
    ---
    --- Sets whether the game is running in VSync mode.
    ---
    ---@param value boolean `true` to enable VSync, `false` to disable it.
    function options.setVSync( value )
        console_Variable.set( "mat_vsync", value )
    end

    --- [MENU]
    ---
    --- Sets the fullscreen state of the game window.
    ---@param value boolean `true` to set the game window to fullscreen, `false` to set it to windowed.
    function options.setFullscreen( value )
        console_Command.run( "mat_setvideomode", tostring( window.width ), tostring( window.height ), value == true and 0 or 1 )
    end

    --- [MENU]
    ---
    --- Sets whether materials and models are unloaded on disconnect.
    ---
    --- Unstable. Use at your own risk.
    ---
    ---@param value boolean `true` to unload assets on disconnect, `false` to keep them cached.
    function options.setUnloadOnDisconnect( value )
        console_Variable.set( "gmod_unload_test", value )
    end

    --- [MENU]
    ---
    --- Sets whether experimental multicore rendering is enabled.
    ---
    ---@param value boolean `true` to enable multicore rendering, `false` to disable it.
    function options.setMulticoreRendering( value )
        console_Variable.set( "gmod_mcore_test", value )
    end

    --- [MENU]
    ---
    --- Sets whether temporary files downloaded from servers (such as sprays) are deleted.
    ---
    ---@param value boolean `true` to delete temporary files, `false` to keep them.
    function options.setDeleteTempFiles( value )
        console_Variable.set( "gmod_delete_temp_files", value )
    end

    --- [MENU]
    ---
    --- Sets the filesystem debug level.
    ---
    --- Causes the filesystem to print actions. `0` = off, `1` = on, `2` = extra.
    ---
    ---@param level integer The filesystem debug level (`0`, `1`, or `2`).
    function options.setFilesystemDebug( level )
        console_Variable.set( "fs_tellmeyoursecrets", level )
    end

    --- [MENU]
    ---
    --- Sets how long the engine sleeps per frame when the game window is unfocused.
    ---
    ---@param milliseconds number Sleep duration in milliseconds per frame. Use `0` to disable.
    function options.setNoFocusSleep( milliseconds )
        console_Variable.set( "engine_no_focus_sleep", milliseconds )
    end

    --- [MENU]
    ---
    --- Opens the color correction tools UI.
    ---
    function options.openColorCorrectionUI()
        console_Command.run( "colorcorrectionui" )
    end

    --- [MENU]
    ---
    --- Opens the options dialog.
    ---
    function options.open()
        menu.run( "OpenOptionsDialog" )
    end

end

-- TODO: review for more variables and commands
