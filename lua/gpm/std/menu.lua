local _G = _G
local gpm = _G.gpm

---@class gpm.std
local std = gpm.std
local window = std.os.window

--- [CLIENT AND MENU]
---
--- The game's main menu library.
---
---@class gpm.std.menu
---@field visible boolean `true` if the menu is visible, `false` otherwise.
local menu = std.menu or { visible = false }
std.menu = menu

do

    local gui = _G.gui

    menu.isVisible = gui.IsGameUIVisible
    menu.open = gui.ActivateGameUI
    menu.openURL = gui.OpenURL

    ---@diagnostic disable-next-line: deprecated
    menu.close = gui.HideGameUI or std.debug.fempty

    local gui_IsGameUIVisible = gui.IsGameUIVisible

    if std.CLIENT_MENU and gui_IsGameUIVisible ~= nil then

        menu.visible = gui_IsGameUIVisible()

        _G.timer.Create( gpm.PREFIX .. " - gui.IsGameUIVisible", 0.1, 0, function()
            menu.visible = gui_IsGameUIVisible()
        end )

    end

end

if std.MENU then

    menu.getWorkshopStatus = _G.GetAddonStatus

    local menu_runCommand = menu.runCommand or _G.RunGameUICommand
    menu.runCommand = menu_runCommand

    --- [MENU]
    ---
    --- Closes the menu and returns to the game.
    ---
    function menu.close()
        menu_runCommand( "ResumeGame" )
    end

    --- [MENU]
    ---
    --- Opens the legacy server browser.
    ---
    function menu.openServerBrowser()
        menu_runCommand( "OpenServerBrowser" )
    end

    --- [MENU]
    ---
    --- Opens the Source "Load Game" dialog.
    ---
    function menu.openGameLoadDialog()
        menu_runCommand( "OpenLoadGameDialog" )
    end

    --- [MENU]
    ---
    --- Opens the Source "Save Game" dialog.
    ---
    function menu.openGameSaveDialog()
        menu_runCommand( "OpenSaveGameDialog" )
    end

    --- [MENU]
    ---
    --- Opens the "Mute Players" dialog that shows all players connected to the server and allows to mute them.
    ---
    function menu.openPlayerList()
        menu_runCommand( "OpenPlayerListDialog" )
    end

    --- [MENU]
    ---
    --- Quits the game.
    ---
    --- **NOTE**: confirmation dialog is broken in Garry's mod and `no_confirm` do nothing.
    ---
    ---@param no_confirm boolean Whether to skip the confirmation prompt.
    function menu.quit( no_confirm )
        menu_runCommand( no_confirm and "QuitNoConfirm" or "Quit" )
    end

    --- [MENU]
    ---
    --- The game's menu loading ( connecting to the server ) module.
    ---
    ---@class gpm.std.menu.loading
    local loading = menu.loading or {}

    loading.getDefaultURL = loading.getDefaultURL or _G.GetDefaultLoadingHTML
    loading.getFileCount = loading.getFileCount or _G.NumDownloadables
    loading.getFiles = loading.getFiles or _G.GetDownloadables
    loading.getStatus = loading.getStatus or _G.GetLoadStatus
    loading.cancel = loading.cancel or _G.CancelLoading

    -- TODO: Add getProgress
    -- TODO: https://github.com/Pika-Software/atmosphere/blob/master/lua/menu/atmosphere/components/loading.lua

    menu.loading = loading

end

do

    local console = std.console
    local command = console.Command
    local console_Variable = console.Variable

    --- [CLIENT AND MENU]
    ---
    --- The game's menu options module.
    ---
    ---@class gpm.std.menu.options
    local options = {}

    --- [CLIENT AND MENU]
    ---
    --- Gets the master volume.
    ---
    ---@return number: The volume, from 0 to 1.
    function options.getMasterVolume()
        return console_Variable.getNumber( "volume" )
    end

    --- [CLIENT AND MENU]
    ---
    --- Gets the effects volume.
    ---
    ---@return number: The volume, from 0 to 1.
    function options.getEffectsVolume()
        return console_Variable.getNumber( "volume_sfx" )
    end

    --- [CLIENT AND MENU]
    ---
    --- Gets the music volume.
    ---
    ---@return number: The volume, from 0 to 1.
    function options.getMusicVolume()
        return console_Variable.getNumber( "snd_musicvolume" )
    end

    --- [CLIENT AND MENU]
    ---
    --- Gets the HEV suit volume.
    ---
    ---@return number: The volume, from 0 to 1.
    function options.getSuitVolume()
        return console_Variable.getNumber( "suitvolume" )
    end

    --- [CLIENT AND MENU]
    ---
    --- Gets whether to mute the volume when the game loses focus.
    ---
    ---@return boolean: Whether to mute the volume.
    function options.getMuteVolumeOnLoseFocus()
        return console_Variable.getBoolean( "snd_mute_losefocus" )
    end

    --- [CLIENT AND MENU]
    ---
    --- Returns the selected game language.
    ---
    --- All language codes https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes.
    ---
    ---@return string: ISO 639-1 language code.
    function options.getLanguage()
        return console_Variable.getString( "gmod_language" )
    end

    --- [CLIENT AND MENU]
    ---
    --- Returns whether the fast weapon switch is enabled.
    ---
    ---@return boolean: Whether the fast weapon switch is enabled.
    function options.getFastWeaponSwitch()
        return console_Variable.getBoolean( "hud_fastswitch" )
    end

    --- [CLIENT AND MENU]
    ---
    --- Returns whether the quick info is enabled.
    ---
    ---@return boolean: Whether the quick info is enabled.
    function options.getQuickInfo()
        return console_Variable.getBoolean( "hud_quickinfo" )
    end

    --- [CLIENT AND MENU]
    ---
    --- Returns whether the crosshair is enabled.
    ---
    ---@return boolean: Whether the crosshair is enabled.
    function options.getCrosshair()
        return console_Variable.getBoolean( "crosshair" )
    end


    --- [CLIENT AND MENU]
    ---
    --- Returns whether the HUD render (health, ammo, etc) is enabled.
    ---
    ---@return boolean: Whether the HUD render is enabled.
    function options.getDrawHUD()
        return console_Variable.getBoolean( "cl_drawhud" )
    end

    --- [CLIENT AND MENU]
    ---
    --- Returns client's mouse sensitivity.
    ---
    ---@return number: The mouse sensitivity.
    function options.getMouseSensitivity()
        return console_Variable.getNumber( "sensitivity" )
    end

    --- [CLIENT AND MENU]
    ---
    --- Returns whether the loading URL is enabled.
    ---
    ---@return boolean: Whether the loading URL is enabled.
    function options.isCustomLoadingScreenAllowed()
        return console_Variable.getBoolean( "cl_enable_loadingurl" )
    end

    --- [CLIENT AND MENU]
    ---
    --- Returns the width and height of the game's window (in pixels).
    ---
    ---@return number width The width of the game's window (in pixels).
    ---@return number height The height of the game's window (in pixels).
    function options.getScreenResolution()
        return window.width, window.height
    end

    options.getFullscreen = window.isFullscreen

    --- [CLIENT AND MENU]
    ---
    --- Returns whether the game is running in VSync mode.
    ---
    ---@return boolean is_on `true` if the game is running in VSync mode, `false` if not.
    function options.getVSync()
        return console_Variable.getBoolean( "mat_vsync" )
    end

    if std.MENU then

        local menu_runCommand = menu.runCommand

        --- [MENU]
        ---
        --- Reloads all local addons. (**garrysmod/addons**)
        ---
        function menu.reloadAddons()
            command.run( "reload_legacy_addons" )
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
        ---@param width? integer The width of the game window.
        ---@param height? integer The height of the game window.
        function options.setScreenResolution( width, height )
            command.run( "mat_setvideomode", width or window.width, height or window.height, window.isWindowed() and 1 or 0 )
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
            command.run( "mat_setvideomode", window.width, window.height, value == true and 0 or 1 )
        end

        --[[

            TODO:

            - gmod_unload_test: Unload materials and models on disconnect. Unstable. Use at your own risk.

            - gmod_mcore_test

            - gmod_delete_temp_files: Delete temporary files downloaded from servers such as sprays.

            - fs_tellmeyoursecrets: Causes the Filesystem to print every action.

        ]]

        --- [MENU]
        ---
        --- Opens the options dialog.
        ---
        function options.open()
            menu_runCommand( "OpenOptionsDialog" )
        end

    end

    menu.options = options

end
