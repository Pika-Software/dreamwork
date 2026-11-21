local dreamwork_engine = dreamwork.engine

local engine_timer = dreamwork_engine.timer
local engine_hook = dreamwork_engine.hook

---@type garrysmod.gui
local glua_gui = dreamwork_engine.requireLibrary( "gui" )

---@class dreamwork.std
local std = dreamwork.std

local debug = std.debug
local debug_fempty = debug.fempty

local console = std.console
local console_Command = console.Command

local LUA_SERVER = std.LUA_SERVER
local LUA_MENU = std.LUA_MENU


--- [CLIENT AND MENU]
---
--- The game's main menu library.
---
--- ```lua
--- print( std.menu.visible ) -- false
--- ```
---
---@class dreamwork.std.menu
---@field visible boolean `true` if the menu is visible, `false` otherwise.
local menu = std.menu or { visible = false }
std.menu = menu

do

    local Visibility = menu.Visibility or std.Event( "menu.Visibility" )
    menu.Visibility = Visibility

    local gui_IsGameUIVisible = gui.IsGameUIVisible
    if gui_IsGameUIVisible ~= nil then
        engine_timer.create( "std.menu.visibility", 0.1, 0, function()
            local visible = gui_IsGameUIVisible()
            if menu.visible ~= visible then
                menu.visible = visible
                Visibility:call( visible )
            end
        end, true )
    end

end

if LUA_MENU then

    local RunGameUICommand = RunGameUICommand

    if RunGameUICommand == nil then
        function RunGameUICommand( command )
            return console_Command.run( "gamemenucommand", command )
        end
    end

    menu.run = RunGameUICommand

end

menu.openURL = glua_gui.OpenURL or debug_fempty

menu.show = gui.ActivateGameUI or debug_fempty

if LUA_MENU then
    menu.hide = gui.HideGameUI or debug_fempty
else

    --- [MENU]
    ---
    --- Closes the menu and returns to the game.
    ---
    function menu.hide()
        return menu.run( "ResumeGame" )
    end

end

if LUA_MENU then

    --- [MENU]
    ---
    --- Opens the legacy server browser.
    ---
    function menu.openServerBrowser()
        menu.run( "OpenServerBrowser" )
    end

    --- [MENU]
    ---
    --- Opens the Source "Load Game" dialog.
    ---
    function menu.openGameLoadDialog()
        menu.run( "OpenLoadGameDialog" )
    end

    --- [MENU]
    ---
    --- Opens the Source "Save Game" dialog.
    ---
    function menu.openGameSaveDialog()
        menu.run( "OpenSaveGameDialog" )
    end

    --- [MENU]
    ---
    --- Opens the "Mute Players" dialog that shows all players connected to the server and allows to mute them.
    ---
    function menu.openPlayerList()
        menu.run( "OpenPlayerListDialog" )
    end

    --- [MENU]
    ---
    --- Quits the game.
    ---
    --- **NOTE**: confirmation dialog is broken in Garry's mod and `no_confirm` do nothing.
    ---
    ---@param no_confirm boolean Whether to skip the confirmation prompt.
    function menu.quit( no_confirm )
        engine_hook.call( "ShutDown" )
        menu.run( no_confirm and "QuitNoConfirm" or "Quit" )
    end

end

dreamwork.load( "std/menu/loading.lua", false, not LUA_MENU )
dreamwork.load( "std/menu/options.lua", false, LUA_SERVER )
