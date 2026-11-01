---@meta garrysmod.gui


--- [CLIENT AND MENU]
---
--- The gui library is similar to the `input` library but features functions
--- that are more focused on the mouse's interaction with GUI panels.
---
---@class garrysmod.gui
gui = {}

--- [CLIENT AND MENU]
---
--- Opens the game main menu as if the player pressed their Escape key.
---
function gui.ActivateGameUI() end

--- [CLIENT]
---
--- Pushes text to the closed caption box.
---
--- > WARNING: The function will not work if the console variable `closecaption` is set to `0`.
---
---@param caption_stream string The caption to emit, see [Closed Captions](https://developer.valvesoftware.com/wiki/Closed_Captions) for more info.
---
--- Special commands can be added to captions, such as `<sfx>` to mark the caption as a sound effect caption,
--- which is hidden if `cc_subtitles` is set to `1` (to only show dialogue subtitles).
---@param duration number How long the caption should stay for, in seconds.
---@param from_player? boolean `true` if the caption is coming from the player.
---
--- This is used to give different colors to the caption to differentiate,
--- for example, whether the SMG is fired by the player or an NPC.
function gui.AddCaption( caption_stream, duration, from_player ) end

--- [CLIENT]
---
--- Enables the mouse cursor without restricting player movement, like using Sandbox's context menu.
---
--- See `vgui.CursorVisible` for a function to see if the cursor is visible or not.
---
--- > NOTE: Some `CUserCmd` functions will return incorrect values when this function is active
--- > because [the user input is getting overtaken by the vgui system](https://github.com/Facepunch/garrysmod-issues/issues/982#issuecomment-505671531).
---
---@param enabled boolean `true` to enable the cursor, `false` to disable it.
function gui.EnableScreenClicker( enabled ) end

--- [CLIENT AND MENU]
---
--- Hides the game main menu if it is currently open.
---
--- This can only be ran a certain amount of times per second
--- to prevent the main menu from being completely inaccessible by the player.
---
--- Use `GM:OnPauseMenuShow` to prevent opening the main menu without a one frame flash.
---
function gui.HideGameUI() end

--- [CLIENT AND MENU]
---
--- Simulates a mouse move with the given deltas.
---
---@param delta_x number The movement delta on the x axis.
---@param delta_y number The movement delta on the y axis.
function gui.InternalCursorMoved( delta_x, delta_y ) end

--- [CLIENT AND MENU]
---
--- Simulates a key press for the given key.
---
---@param key integer The key, see `KEY` enums.
function gui.InternalKeyCodePressed( key ) end

--- [CLIENT AND MENU]
---
--- Simulates a key release for the given key.
---
---@param key integer The key, see `KEY` enums.
function gui.InternalKeyCodeReleased( key ) end

--- [CLIENT AND MENU]
---
--- Simulates a key type typing to the specified key.
---
---@param key integer The key, see `KEY` enums.
function gui.InternalKeyCodeTyped( key ) end

--- [CLIENT AND MENU]
---
--- Simulates an ASCII symbol writing.
--- Use to write text in the chat or in VGUI.
---
--- > NOTE: Doesn't work while the main menu is open!
---
---@param code integer The ASCII code of the symbol, see [this chart](https://files.facepunch.com/wiki/files/ab571/8dc389806d65b98.gif).
function gui.InternalKeyTyped( code ) end

--- [CLIENT AND MENU]
---
--- Simulates a double mouse key press for the given mouse key.
---
---@param key integer The key, see `MOUSE` enums.
function gui.InternalMouseDoublePressed( key ) end

--- [CLIENT AND MENU]
---
--- Simulates a mouse key press for the given mouse key.
---
---@param key integer The key, see `MOUSE` enums.
function gui.InternalMousePressed( key ) end

--- [CLIENT AND MENU]
---
--- Simulates a mouse key release for the given mouse key.
---
---@param key integer The key, see `MOUSE` enums.
function gui.InternalMouseReleased( key ) end

--- [CLIENT AND MENU]
---
--- Simulates a mouse wheel scroll with the given delta.
---
---@param delta number The amount of scrolling to simulate.
function gui.InternalMouseWheeled( delta ) end

--- [CLIENT AND MENU]
---
--- Returns whether the console is visible or not.
---
---@return boolean is_visible `true` if the console is visible.
function gui.IsConsoleVisible() end

--- [CLIENT AND MENU]
---
--- Returns whether the game menu overlay (main menu) is open or not.
---
---@return boolean is_visible `true` if the game menu overlay is open.
function gui.IsGameUIVisible() end

--- [CLIENT AND MENU]
---
--- Returns the cursor's position on the screen, or `0, 0` if the cursor is not visible.
---
---@return integer x The x coordinate of the cursor.
---@return integer y The y coordinate of the cursor.
---@deprecated Use `input.GetCursorPos` instead.
function gui.MousePos() end

--- [CLIENT AND MENU]
---
--- Returns the x component of the mouse position.
---
---@return integer x The x coordinate of the cursor.
function gui.MouseX() end

--- [CLIENT AND MENU]
---
--- Returns the y component of the mouse position.
---
---@return integer y The y coordinate of the cursor.
function gui.MouseY() end

--- [CLIENT AND MENU]
---
--- Opens the specified URL in the steam overlay browser.
---
--- > NOTE: When called clientside, the user will be asked for confirmation before the website will open.
---
---@param url string The URL to open, it has to start with either `http://` or `https://`.
function gui.OpenURL( url ) end

--- [CLIENT]
---
--- Converts the specified screen position to a **direction** vector local to the player's view.
---
--- A related function is `Vector:ToScreen`, which translates a 3D position to a screen coordinate.
---
--- `util.AimVector` is a more generic version of this, using a custom view instead of the player's current view.
---
---@param x integer The x coordinate on the screen.
---@param y integer The y coordinate on the screen.
---@return garrysmod.Vector direction The direction vector.
function gui.ScreenToVector( x, y ) end

--- [CLIENT AND MENU]
---
--- Sets the cursor's position on the screen, relative to the top-left corner of the window.
---
---@param x integer The x coordinate to move the cursor to.
---@param y integer The y coordinate to move the cursor to.
---@deprecated Use `input.SetCursorPos` instead.
function gui.SetMousePos( x, y ) end

--- [MENU]
---
--- Shows the console in the game UI.
---
function gui.ShowConsole() end
