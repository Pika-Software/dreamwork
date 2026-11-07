---@meta garrysmod.input


--- [CLIENT AND MENU]
---
--- The input library allows you to gather information about the clients input devices (mouse & keyboard),
--- such as the cursor position and whether a key is pressed or not.
---
---@class garrysmod.input
input = {}

--- [CLIENT AND MENU]
---
--- Returns the last key captured by key trapping.
---
---@return integer key The key. See `KEY` enums.
function input.CheckKeyTrapping() end

--- [CLIENT AND MENU]
---
--- Returns the digital value of an analog stick on the current (set up via convars) controller.
---
--- > **NOTE**: A joystick axis returns `-32768` when it's pushed completely up/completely left, and returns `32767` when it's pushed completely down/completely right.
--- >
--- > A mouse wheel starts at `0` and increases by `1` for every unit of scroll up / decreases by `1` for every unit of scroll down.
--- >
--- > A mouse axis is `0` when the arrow is at the top or left of the screen; when the arrow is at the bottom right of the screen, the mouse y axis is the height of the screen and the mouse x axis is the width of the screen (in pixels). Note that in game, the "arrow" stays near the middle of the screen.
--- >
--- > Trigger axis always return `0` (verify).
---
---@param axis integer The analog axis to poll. See `ANALOG` enums.
---@return number value The digital value.
function input.GetAnalogValue( axis ) end

--- [CLIENT AND MENU]
---
--- Returns the cursor's position on the screen.
---
--- > **BUG** (#4964): On macOS, the cursor isn't locked on the middle of the screen which causes a significant offset of the positions returned by this function.
---
---@return number x The cursor's position on the X axis.
---@return number y The cursor's position on the Y axis.
function input.GetCursorPos() end

--- [CLIENT AND MENU]
---
--- Gets the button code from a button name. This is opposite of `input.GetKeyName`.
---
---@param button string The internal button name, such as `E` or `SHIFT`.
---@return integer button_code The button code. See `BUTTON_CODE` enums.
function input.GetKeyCode( button ) end

--- [CLIENT AND MENU]
---
--- Gets the button name from a numeric button code. The name needs to be translated with `language.GetPhrase` before being displayed.
---
--- > **NOTE**: Despite the name of the function, this also works for the full range of keys in `BUTTON_CODE`.
---
---@param button integer The button. See `BUTTON_CODE` enums.
---@return string name Button name.
function input.GetKeyName( button ) end

--- [CLIENT AND MENU]
---
--- Gets whether the specified button code is down.
---
--- Unlike `input.IsKeyDown` this can also detect joystick presses from `JOYSTICK`.
---
---@param button integer The button. Valid values are in the range of `BUTTON_CODE` enums.
---@return boolean is_down Whether the button is down.
function input.IsButtonDown( button ) end

--- [CLIENT AND MENU]
---
--- Returns whether a control key is being pressed.
---
---@return boolean is_down Whether a Ctrl key is down.
function input.IsControlDown() end

--- [CLIENT AND MENU]
---
--- Gets whether a key is down.
---
---@param key integer The key. See `KEY` enums.
---@return boolean is_down Whether the key is down.
function input.IsKeyDown( key ) end

--- [CLIENT AND MENU]
---
--- Returns whether key trapping is active and the next key press will be captured.
---
---@return boolean is_trapping Whether key trapping is active.
function input.IsKeyTrapping() end

--- [CLIENT AND MENU]
---
--- Gets whether a mouse button is down.
---
---@param mouse_key integer The key. See `MOUSE` enums.
---@return boolean is_down Whether the key is down.
function input.IsMouseDown( mouse_key ) end

--- [CLIENT AND MENU]
---
--- Gets whether a shift key is being pressed.
---
---@return boolean is_down Whether a Shift key is down.
function input.IsShiftDown() end

--- [CLIENT AND MENU]
---
--- Returns the client's bound key for the specified console command.
---
--- If the player has multiple keys bound to a single command, then the key with the lowest `BUTTON_CODE` will be returned.
---
---@param binding string The binding name.
---@param exact boolean? `true` to disable automatic stripping of a single leading `+` character. Defaults to `false`.
---@return string? key The first key found with that binding, or no value if no key with the given binding was found. See also `input.GetKeyCode`.
function input.LookupBinding( binding, exact ) end

--- [CLIENT AND MENU]
---
--- Returns the bind string that the given key is bound to.
---
---@param key integer Key from `BUTTON_CODE` enums.
---@return string binding The bind string of the given key.
function input.LookupKeyBinding( key ) end

--- [CLIENT]
---
--- Switches to the provided weapon on the next `CUserCmd` generation / `CreateMove` call.
---
--- Direct binding to `CInput::MakeWeaponSelection`.
---
---@param weapon garrysmod.Weapon The weapon entity to switch to.
function input.SelectWeapon( weapon ) end

--- [CLIENT AND MENU]
---
--- Sets the cursor's position on the screen, relative to the topleft corner of the window.
---
---@param mouse_x number X coordinate for mouse position.
---@param mouse_y number Y coordinate for mouse position.
function input.SetCursorPos( mouse_x, mouse_y ) end

--- [CLIENT AND MENU]
---
--- Begins waiting for a key to be pressed so we can save it for `input.CheckKeyTrapping`.
---
--- Used by the `DBinder`.
---
function input.StartKeyTrapping() end

--- [CLIENT AND MENU]
---
--- Translates a console command alias, basically reverse of the `alias` console command.
---
---@param command string The alias to lookup.
---@return string? commands The command(s) this alias will execute if ran, or `nil` if the alias doesn't exist.
function input.TranslateAlias( command ) end

--- [CLIENT AND MENU]
---
--- Returns whether a key was initially pressed in the same frame this function was called.
---
--- This function only works in Move hooks, and will detect key presses even in main menu or when typing in a text field.
---
---@param key integer The key. See `KEY` enums.
---@return boolean was_pressed `true` if the key was initially pressed the same frame that this function was called.
function input.WasKeyPressed( key ) end

--- [CLIENT AND MENU]
---
--- Returns whether a key was released in the same frame this function was called.
---
--- This function only works in Move hooks, and will detect key releases even in main menu or when typing in a text field.
---
---@param key integer The key. See `KEY` enums.
---@return boolean was_released `true` if the key was released the same frame that this function was called.
function input.WasKeyReleased( key ) end

--- [CLIENT AND MENU]
---
--- Returns whether the key is being held down or not.
---
--- This function only works in Move hooks, and will detect key events even in main menu or when typing in a text field.
---
---@param key integer The key to test. See `KEY` enums.
---@return boolean is_down Whether the key is being held down.
function input.WasKeyTyped( key ) end

--- [CLIENT AND MENU]
---
--- Returns whether a mouse key was double pressed in the same frame this function was called.
---
--- If this function returns `true`, `input.WasMousePressed` will return `false`.
---
--- This function only works in Move hooks, and will detect mouse events even in main menu or when typing in a text field.
---
---@param button integer The mouse button to test. See `MOUSE` enums.
---@return boolean was_double_pressed Whether the mouse key was double pressed.
function input.WasMouseDoublePressed( button ) end

--- [CLIENT AND MENU]
---
--- Returns whether a mouse key was initially pressed in the same frame this function was called.
---
--- If `input.WasMouseDoublePressed` returns `true`, this function will return `false`.
---
--- This function only works in Move hooks, and will detect mouse events even in main menu or when typing in a text field.
---
---@param key integer The key. See `MOUSE` enums.
---@return boolean was_pressed `true` if the mouse key was initially pressed the same frame that this function was called.
function input.WasMousePressed( key ) end

--- [CLIENT AND MENU]
---
--- Returns whether a mouse key was released in the same frame this function was called.
---
--- This function only works in Move hooks, and will detect mouse events even in main menu or when typing in a text field.
---
---@param key integer The key to test. See `MOUSE` enums.
---@return boolean was_released `true` if the mouse key was released the same frame that this function was called.
function input.WasMouseReleased( key ) end
