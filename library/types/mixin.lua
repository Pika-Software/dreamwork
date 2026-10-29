---@meta _

--- [SHARED AND MENU]
---
--- A mixin is an ordered chain of transformer functions.
---
--- Each handler in the chain receives the previous (`old_value`) and
--- current (`new_value`) values plus any extra arguments, and may return
--- a new value to replace `new_value` for the next handler in the chain.
---
--- Mixins are themselves callable and can be nested inside
--- one another as handlers.
---
---@class Mixin<T> : Object
---@field __class MixinClass
---@field name string The name of the mixin.
---@field protected handlers table<integer, ( Mixin<T> | fun( old_value: ( T | nil ), new: T, ...: any ): ( T | nil ) )>
local __Mixin = {}

---@param name string | nil
---@protected
function __Mixin:__init(name) end

--- [SHARED AND MENU]
---
--- Attaches a handler (or nested `Mixin`) to the end of the chain. If the
--- handler is already attached, it is moved to the end instead of being
--- added twice.
---
--- Throws if `mixer` is not callable, or if attaching it would
--- create a cycle (a `Mixin` that indirectly contains `self`).
---
---@generic T
---@param self Mixin<T>
---@param mixer ( fun( old_value: ( T | nil ), new: T, ...: any ): ( T | nil ) ) | Mixin<T> The handler to attach.
---@return integer depth The handler's position in the chain after attaching.
function __Mixin:attach(mixer) end

--- [SHARED AND MENU]
---
--- Detaches a previously attached handler from the chain.
---
---@generic T
---@param self Mixin<T>
---@param mixer ( fun( old_value: ( T | nil ), new: T, ...: any ): ( T | nil ) ) | Mixin<T> The exact handler reference that was previously passed to `attach`.
---@return boolean is_detached Returns `true` if the handler was found and detached, otherwise `false`.
function __Mixin:detach(mixer) end

--- [SHARED AND MENU]
---
--- Runs every handler in the chain in order, passing each one the running
--- `old_value`/`new_value` pair plus any extra arguments.
---
--- Any handler that returns a non-`nil` result becomes the new `new_value` for
--- the next handler (with the previous `new_value` shifted into `old_value`).
---
--- Throws if any handler errors.
---
---@generic T
---@param self Mixin<T>
---@param old_value T | nil The previous value, if any.
---@param new_value T The current value to transform.
---@param ... any Extra arguments forwarded to every handler.
---@return T new_value The final value after all handlers have run.
function __Mixin:call(old_value, new_value, ...) end

--- [SHARED AND MENU]
---
--- The class used to create new `Mixin` instances.
---
---@class MixinClass : Mixin
---@field __base Mixin
---@overload fun( name: ( string | nil ) ): Mixin
Mixin = {}
