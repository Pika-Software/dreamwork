---@meta _

---@class garrysmod.console.Variable
local GModConVar = {}

--- [SHARED AND MENU]
---
--- The console variable object.
---
---@class console.Variable<T> : Object
---@field __class console.Variable
---@field value T The value of the variable.
---@field type console.VariableType The type of the variable (e.g., "int", "string").
---@field name string The name of the variable.
---@field description string The description of the variable.
---@field flags integer The flags of the variable.
---@field default T The default value of the variable.
---@field min T | nil The minimum value of the variable (if applicable).
---@field max T | nil The maximum value of the variable (if applicable).
local Variable = {}

---@return string
---@protected
function Variable:__represent() end

---@param str_key string
---@return any
---@protected
function Variable:__index(str_key) end

---@param str_key string
---@param value any
---@protected
function Variable:__newindex(str_key, value) end

---@param options console.VariableOptions
---@protected
function Variable:__init(options) end

--- [SHARED AND MENU]
---
--- The console variable class.
---
---@class console.VariableClass : console.Variable
---@field __base console.Variable
---@overload fun( options: console.VariableOptions ): console.Variable
console.Variable = {}

---@param str_name string
---@return console.Variable?
---@protected
function console.Variable:__new(str_name) end

--- [SHARED AND MENU]
---
--- Gets a `console.Variable` object by its name.
---
---@param str_name string The name of the console variable.
---@param cvar_type console.VariableType The type of the console variable.
---@return console.Variable variable The `console.Variable` object.
---@nodiscard
---@overload fun( str_name: string, cvar_type: "boolean"): console.Variable<boolean>
---@overload fun( str_name: string, cvar_type: "integer"): console.Variable<integer>
---@overload fun( str_name: string, cvar_type: "number"): console.Variable<number>
---@overload fun( str_name: string, cvar_type: "string"): console.Variable<string>
function console.Variable.get(str_name, cvar_type) end

--- [SHARED AND MENU]
---
--- Gets the value of the `console.Variable` object as a string.
---
---@param name string The name of the console variable.
---@return string value The value of the `console.Variable` object.
---@nodiscard
function console.Variable.getString(name) end

--- [SHARED AND MENU]
---
--- Gets the value of the `console.Variable` object as an integer.
---
---@param name string The name of the console variable.
---@return integer value The value of the `console.Variable` object.
---@nodiscard
function console.Variable.getInteger(name) end

--- [SHARED AND MENU]
---
--- Gets the value of the `console.Variable` object as a float/double.
---
---@param name string The name of the console variable.
---@return number value The value of the `console.Variable` object.
---@nodiscard
function console.Variable.getFloat(name) end

--- [SHARED AND MENU]
---
--- Gets the value of the `console.Variable` object as a boolean.
---
---@param name string The name of the console variable.
---@return boolean value The value of the `console.Variable` object.
---@nodiscard
function console.Variable.getBoolean(name) end

--- [SHARED AND MENU]
---
--- Reverts the value of the `console.Variable` object to its default value.
---
---@generic T
---@param self console.Variable<T>
---@return T default The default value of the `console.Variable` object.
function Variable:revert() end

--- [SHARED AND MENU]
---
--- Reverts the value of the `console.Variable` object to its default value.
---
---@param name string The name of the console variable.
function console.Variable.revert(name) end

--- [SHARED AND MENU]
---
--- Gets the help text of the `console.Variable` object.
---
---@param name string The name of the console variable.
---@return string help The help text of the `console.Variable` object.
---@nodiscard
function console.Variable.getDescription(name) end

--- [SHARED AND MENU]
---
--- Gets the default value of the `console.Variable` object.
---
---@param name string The name of the console variable.
---@return string default The default value of the `console.Variable` object.
---@nodiscard
function console.Variable.getDefault(name) end

--- [SHARED AND MENU]
---
--- Gets the flags of the `console.Variable` object.
---
---@param name string The name of the console variable.
---@return integer flags The flags of the `console.Variable` object.
---@nodiscard
function console.Variable.getFlags(name) end

--- [SHARED AND MENU]
---
--- Sets the value of the `console.Variable` object.
---
---@param name string The name of the console variable.
---@param value console.VariableValue The value to set.
function console.Variable.set(name, value) end

--- [SHARED AND MENU]
---
--- Checks if the flag is set on the `console.Variable` object.
---
---@param name string The name of the console variable.
---@param flags integer The flags to check.
---@return boolean is_set `true` if the flag is set on the `console.Variable` object, `false` otherwise.
---@nodiscard
function console.Variable.isFlagSet(name, flags) end

--- [SHARED AND MENU]
---
--- Gets the minimum value of the `console.Variable` object.
---
---@param name string The name of the console variable.
---@return number minimum The minimum value of the `console.Variable` object.
---@nodiscard
function console.Variable.getMin(name) end

--- [SHARED AND MENU]
---
--- Gets the maximum value of the `console.Variable` object.
---
---@param name string The name of the console variable.
---@return number maximum The maximum value of the `console.Variable` object.
---@nodiscard
function console.Variable.getMax(name) end

--- [SHARED AND MENU]
---
--- Returns the minimum and maximum values of the `console.Variable` object.
---
---@param name string The name of the console variable.
---@return number minimum The minimum value of the `console.Variable` object.
---@return number maximum The maximum value of the `console.Variable` object.
---@nodiscard
function console.Variable.getBounds(name) end

--- [SHARED AND MENU]
---
--- Attaches a handler function to the given stage of the hook.
--- If the handler is already attached to that stage, only its priority is
--- updated (when a new one is supplied); it will not be attached twice.
---
--- If the hook is currently running, the change is deferred and applied once
--- the hook finishes running.
---
---@generic T
---@param self console.Variable<T>
---@param handler Hook<T> | Mixin<T> | fun( value: T )
function Variable:attach(handler) end

--- [SHARED AND MENU]
---
--- Attaches a handler function to the hook that automatically detaches
--- itself right before being invoked, so it only ever runs once.
---
---@generic T
---@param self console.Variable<T>
---@param handler Hook<T> | Mixin<T> | fun( value: T )
function Variable:once(handler) end

--- [SHARED AND MENU]
---
--- Detaches a previously attached handler from the given stage of the hook.
--- If the hook is currently running, the handler is replaced with a no-op and
--- the actual removal is deferred until the hook finishes running.
---
---@param handler Hook<T> | Mixin<T> | fun( value: T )
function Variable:detach(handler) end

--- [SHARED AND MENU]
---
--- Cancels the hook if it is currently running, and removes every handler,
--- resetting their priority tables as well.
---
function Variable:clear() end

--- [SHARED AND MENU]
---
--- Waits for the `console.Variable` object to change.
---
---@generic T
---@param self console.Variable<T>
---@return T new_value
---@async
function Variable:await() end
