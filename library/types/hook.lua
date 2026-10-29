---@meta _

--- [SHARED AND MENU]
---
--- A hook is a named, prioritized event pipeline that other code can attach
--- handlers to and later call to run them. Handlers are grouped into four
--- ordered stages - `peek`, `provide`, `mixin`, and `observe` - which run in
--- that order each time the hook is called via `Hook:call` (or by calling the
--- hook object itself, since it is callable).
---
--- Hook call pipeline, stages run in this order:
---
--- ```md
--- ┌─────────┐
--- │  peek   │ --> Always called, return is optional;
--- └─────────┘     if any handler returns a value,
---      ↓          it overrides the `provide` stage.
--- ┌─────────┐
--- │ provide │ --> Called only if `peek` produced `nil`.
--- └─────────┘     First hook that returns a value wins,
---      ↓          its return value becomes the result.
--- ┌─────────┐
--- │  mixin  │ --> Called as long as a result exists.
--- └─────────┘     Lets handlers mutate the result,
---      ↓          receiving both the old & new value.
--- ┌─────────┐
--- │ observe │ --> Read-only listeners for the final
--- └─────────┘     result and args. Any return values
---                 will be ignored.
---```
---
---@class Hook<T> : Object
---@field __class HookClass
---@field name string The name of the hook.
---@field protected running boolean Whether the hook is currently running.
---@field protected has_changes boolean Whether the hook has changes to apply.
---@field protected peek_handlers (Hook<T> | fun( ...: any ): T)[]
---@field protected peek_priorities table<(Hook<T> | fun( ...: any ): T), integer>
---@field protected provide_handlers (Hook<T> | fun( ...: any ): T)[]
---@field protected provide_priorities table<(Hook<T> | fun( ...: any ): T), integer>
---@field protected observe_handlers (Hook<T> | fun( ...: any ): T)[]
---@field protected observe_priorities table<(Hook<T> | fun( ...: any ): T), integer>
---@field protected mixin_handlers (Hook<T> | Mixin<T> | fun( ...: any ): T)[]
---@field protected mixin_priorities table<(Hook<T> | Mixin<T> | fun( ...: any ): T), integer>
local __Hook = {}

---@return string
---@protected
function __Hook:__represent() end

---@return boolean
---@protected
function __Hook:__toboolean() end

---@return integer
---@protected
function __Hook:__len() end

---@param name string | nil
---@protected
function __Hook:__init(name) end

--- [SHARED AND MENU]
---
--- Checks if the hook is running currently.
---
---@return boolean is_running Returns `true` if the hook is running currently, otherwise `false`.
---@nodiscard
function __Hook:isRunning() end

--- [SHARED AND MENU]
---
--- Detaches a previously attached handler from the given stage of the hook.
--- If the hook is currently running, the handler is replaced with a no-op and
--- the actual removal is deferred until the hook finishes running.
---
---@generic T
---@param self Hook<T>
---@param type Hook.type The stage to detach the handler from.
---@param handler Hook<T> | Mixin<T> | fun( ...: any ): T The exact handler reference that was previously passed to `attach`.
---@return boolean is_detached Returns `true` if the handler was found and detached, otherwise `false`.
function __Hook:detach(type, handler) end

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
---@param self Hook<T>
---@param type Hook.type The stage to attach the handler to.
---@param handler Hook<T> | Mixin<T> | fun( ...: any )
---@param priority integer | nil The priority of the handler within its stage; handlers with a lower value run earlier. Defaults to `0`.
---@overload fun( self: Hook<T>, type: "peek", handler: ( Hook<T> | Mixin<T> | fun( ...: any ): ( T | nil ) ), priority: ( integer | nil ) )
---@overload fun( self: Hook<T>, type: ( "provide" | nil ), handler: ( Hook<T> | Mixin<T> | fun( ...: any ): ( T | nil ) ), priority: ( integer | nil ) )
---@overload fun( self: Hook<T>, type: "mixin", handler: fun( old_value: ( T | nil ), new_value: T, ...: any ): ( T | nil ), priority: ( integer | nil ) )
---@overload fun( self: Hook<T>, type: "observe", handler: fun( value: T, ...: any ), priority: ( integer | nil ) )
function __Hook:attach(type, handler, priority) end

---@generic T
---@param self Hook<T>
---@return boolean
function __Hook.cancel(self) end

--- [SHARED AND MENU]
---
--- Cancels the hook if it is currently running, and removes every handler
--- attached to every stage (`peek`, `provide`, `observe`, `mixin`), resetting
--- their priority tables as well.
---
function __Hook:clear() end

--- [SHARED AND MENU]
---
--- Runs the hook, calling its handlers in order across all four stages:
--- `peek` (early handlers that may short-circuit the result), `provide`
--- (produces the base result), `mixin` (allowed to transform the result),
--- and `observe` (read-only listeners called with the final result).
---
--- Throws (and cancels the hook) if any handler errors, or if the hook is
--- already running.
---
---@generic T
---@param self Hook<T>
---@param ... any Arguments forwarded to every handler in every stage.
---@return T | nil result The final value produced by `peek`/`provide` and possibly transformed by `mixin` handlers; `nil` if no handler produced a value.
function __Hook:call(...) end

--- [SHARED AND MENU]
---
--- Attaches a handler function to the hook that automatically detaches
--- itself right before being invoked, so it only ever runs once.
---
---@generic T
---@param self Hook<T>
---@param type Hook.type The stage to attach the handler to.
---@param handler Hook<T> | fun( ...: any )
---@param priority integer | nil The priority of the handler within its stage; handlers with a lower value run earlier. Defaults to `0`.
---@overload fun( self: Hook<T>, type: ( "peek" | nil ), handler: ( Hook<T> | fun( ...: any ): ( T | nil ) ), priority: ( integer | nil ) )
---@overload fun( self: Hook<T>, type: "provide", handler: ( Hook<T> | fun( ...: any ): T ), priority: ( integer | nil ) )
---@overload fun( self: Hook<T>, type: "mixin", handler: ( Mixin<T> | fun( old_value: ( T | nil ), new_value: T, ...: any ): T ), priority: ( integer | nil ) )
---@overload fun( self: Hook<T>, type: "observe", handler: fun( value: T, ...: any ), priority: ( integer | nil ) )
function __Hook:once(type, handler, priority) end

--- [SHARED AND MENU]
---
--- Asynchronously suspends the caller until the given stage of the hook is
--- next called, then resumes with the arguments that stage's handler
--- received.
---
---@param type Hook.type The stage to wait for.
---@return any ... The arguments passed to the handler when the awaited stage fired.
---@async
function __Hook:await(type) end

--- [SHARED AND MENU]
---
--- The class used to create new `Hook` instances.
---
---@class HookClass : Hook
---@field __base Hook
---@overload fun( name: string? ): Hook
Hook = {}
