---@meta _

--- [SHARED AND MENU]
---
--- The input library allows you to
--- manipulate the client's input devices
--- (mouse & keyboard), such as the cursor
--- position and whether a key is pressed or not.
---
---@class input
input = {}

--- [CLIENT AND MENU]
---
--- The cursor module allows to manipulate the client's cursor.
---
---@clas input.cursor
input.cursor = nil

--- [CLIENT AND MENU]
---
--- The clipboard module allows to manipulate the client's clipboard.
---
---@class input.clipboard
local clipboard = {}

input.clipboard = clipboard

--- [CLIENT AND MENU]
---
--- Returns the contents of the clipboard.
---
---@return string
---@nodiscard
function clipboard.getText() end

--- [CLIENT AND MENU]
---
--- Sets the contents of the clipboard.
---
---@param text string
function clipboard.setText(text) end

--- [CLIENT AND MENU]
---
--- Adds text to the clipboard.
---
---@param text string
function clipboard.addText(text) end

--- [CLIENT AND MENU]
---
--- Clears the clipboard.
---
function clipboard.clear() end

--- [CLIENT AND MENU]
---
--- The mouse module allows to manipulate the client's mouse.
---
---@class input.mouse
local mouse = {}

input.mouse = mouse

--- [CLIENT AND MENU]
---
--- The key module allows manipulate the client's keys.
---
---@class input.key
---@field count integer The number of keys.
local key = {}

input.key = key

--- [CLIENT AND MENU]
---
--- Starts a key capture and returns the key code of the key that was pressed.
---
--- The captured key will not be pressed and committed to the game engine.
---
---@return integer key_code The key code of the key that was pressed.
---@nodiscard
---@async
function key.capture() end

--- [CLIENT AND MENU]
---
--- Get the name of a key.
---
---@param key_code integer The key code of the key.
---@return string key_code The name of the key.
---@nodiscard
function key.getName(key_code) end

--- [CLIENT AND MENU]
---
--- Get the key code of a name.
---
---@param name string The name of the key.
---@return integer key_code The key code of the key.
---@nodiscard
---@see key.getName as a reverse lookup
function key.getCode(name) end

--- [CLIENT AND MENU]
---
--- The bind module allows to manipulate the client's binds.
---
---@class input.binding
local binding = {}

input.binding = binding

--- [MENU]
---
--- Sets the bind of a key.
---
---@param key_code integer
---@param ... string
function binding.set(key_code, ...) end

--- [CLIENT AND MENU]
---
--- The controller module allows to manipulate the client's controllers.
---
---@class input.controller
local controller = {}

input.controller = controller

--- [CLIENT]
---
--- The weapon module allows to manipulate the client's weapon.
---
---@class input.weapon
local weapon = {}

input.weapon = weapon

--- [CLIENT]
---
--- Selects the previously selected weapon.
---
--- Instantly sets the player's past weapons as active.
---
function weapon.last() end

--- [CLIENT]
---
--- Selects the next weapon in the inventory.
---
--- Weapons will most likely not be selected immediately because often players do not use `hud_fastswitch`, so they will just have their inventory with the selected weapon displayed in the next slot.
---
function weapon.next() end

--- [CLIENT]
---
--- Selects the previous weapon in the inventory.
---
--- Weapons will most likely not be selected immediately because often players do not use `hud_fastswitch`, so they will just have their inventory with the selected weapon displayed in the next slot.
---
function weapon.previous() end

--- [CLIENT AND SERVER]
---
--- The kinect module allows to manipulate the client's kinect.
---
--- Highly recommended to use with https://github.com/WilliamVenner/gmcl_rekinect
---
---@class input.kinect
local kinect = {}

input.kinect = kinect
