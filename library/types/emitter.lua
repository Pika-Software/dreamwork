---@meta _

--- A function, or a callable object such as a `Hook` or an `Event` (called through its `__call` metamethod).
---
---@alias Emitter.Handler function | Hook | Event

--- One event's handlers: `[0]` is the count, `[1..n]` the handlers in attach order.
---
--- `once[ handler ]` marks one-shot handlers, `emitting` counts nested `emit` calls
--- and `dirty` is set when a handler was detached mid-emit (slot holds `debug.fempty`).
---
---@class Emitter.List
---@field [0] integer
---@field [integer] Emitter.Handler
---@field once table<Emitter.Handler, boolean>
---@field emitting integer
---@field dirty boolean

--- [SHARED AND MENU]
---
--- A minimal event registry shared by every instance of a class.
---
--- Unlike `Hook` it has no stages, priorities or return values: `emit` calls each
--- handler in attach order, in protected mode, so one failing handler is reported
--- and never stops the others, and emits may nest freely.
---
--- Handlers are functions or callable objects, e.g. a `Hook` attached as a handler
--- runs its own `call` with the emitted arguments.
---
--- Listener lists are created on the first `attach` and kept in the emitter itself
--- (weak keys), objects without listeners cost nothing.
--- A handler capturing its own object as an upvalue keeps that object alive
--- (LuaJIT weak tables are not ephemerons), use the object passed to the handler instead.
---
--- ```lua
--- local events = Emitter( "Thing" )
---
--- function Thing:attach( event, handler ) events:attach( self, event, handler ) end
---
--- events:emit( thing, "open", thing )
--- ```
---
---@class Emitter : Object
---@field __class EmitterClass
---@field protected [any] table<string, Emitter.List> Per-object lists, weak keys.
local __Emitter = {}

__Emitter.__mode = "k"

---@param name string Owner name used in error messages, e.g. `"WebClient"`.
---@protected
function __Emitter:__init(name) end

---@return string
---@protected
function __Emitter:__represent() end

function __Emitter:__len() end

--- [SHARED AND MENU]
---
--- Attaches a handler for `event_name` on `object`. Attaching the same handler twice is a no-op.
---
---@param object any The object the handler listens on.
---@param event_name string The event name.
---@param handler Emitter.Handler The callback or callable object, receives the `emit` arguments.
function __Emitter:attach(object, event_name, handler) end

--- [SHARED AND MENU]
---
--- Attaches a one-shot handler, detached right before it runs.
---
--- It can still be removed with `detach` using the same `handler` reference.
---
---@param object any The object the handler listens on.
---@param event_name string The event name.
---@param handler Emitter.Handler The callback or callable object, receives the `emit` arguments.
function __Emitter:once(object, event_name, handler) end

--- [SHARED AND MENU]
---
--- Detaches a handler previously passed to `attach` or `once`.
---
---@param object any The object the handler listens on.
---@param event_name string The event name.
---@param handler Emitter.Handler The exact handler reference.
---@return boolean removed `true` if the handler was attached.
function __Emitter:detach(object, event_name, handler) end

--- [SHARED AND MENU]
---
--- Removes every handler of `event_name` on `object`, or of every event when `event_name` is `nil`.
---
--- Handlers still pending in a running `emit` of a cleared event are skipped.
---
---@param object any The object to clear.
---@param event_name string? The event name, or `nil` for all events.
function __Emitter:clear(object, event_name) end

--- [SHARED AND MENU]
---
--- Returns the number of handlers attached to `event_name` on `object`.
---
---@param object any The object to inspect.
---@param event_name string The event name.
---@return integer count
---@nodiscard
function __Emitter:count(object, event_name) end

--- [SHARED AND MENU]
---
--- Calls every handler of `event_name` on `object` with `...`, in attach order.
---
--- Each handler runs in protected mode: errors are reported and the rest still run.
--- Non-function handlers are called through their `__call` metamethod with themselves first.
--- Handlers attached during the emit run from the next emit on.
---
---@param object any The object the event fires on.
---@param event_name string The event name.
---@param ... any Arguments forwarded to every handler.
function __Emitter:emit(object, event_name, ...) end

--- [SHARED AND MENU]
---
--- Suspends the caller until `event_name` fires on `object`, then returns its arguments.
---
--- When `abort_event` fires first, both listeners are detached and `abort_message`
--- (or a generic message) is thrown instead.
---
--- At most the first **6** emitted values are returned, keep awaitable events within that.
---
---@param object any The object to wait on.
---@param event_name string The event to wait for.
---@param abort_event string? An event that cancels the wait, e.g. `"close"`.
---@param abort_message string? The error message thrown on abort.
---@return any ... The arguments `event` was emitted with.
---@async
function __Emitter:await(object, event_name, abort_event, abort_message) end

--- [SHARED AND MENU]
---
--- The class used to create new `Emitter` registries.
---
---@class EmitterClass : Emitter, Class
---@field __base Emitter
---@overload fun( name: string ): Emitter
Emitter = {}
