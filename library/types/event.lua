---@meta _

--- A function, or a callable object such as another `Event` (called through its `__call` metamethod).
---
---@alias Event.Handler function | Event

--- Handlers sorted by priority: `[0]` is the count, `[1..n]` the handlers.
---
--- `iterating` counts the `call` loops walking this list, a list being walked
--- is never mutated, `attach`/`detach` swap in a fresh copy instead.
---
---@class Event.List
---@field [0] integer
---@field [integer] Event.Handler
---@field iterating integer

--- [SHARED AND MENU]
---
--- A named list of handlers called one after another, a simpler `Hook`.
---
--- There are no stages and no return values: `call` runs every handler in
--- priority order (lower first, equal priorities keep attach order) and
--- returns nothing. Each handler runs in protected mode, a failing handler is
--- reported and never stops the others.
---
--- Calls may nest, handlers attached during a call run from the next call on,
--- handlers detached during a call are skipped right away.
---
---@class Event : Object
---@field __class EventClass
---@field name string The name of the event.
---@field protected running integer The number of `call`s in progress.
---@field protected handlers Event.List
---@field protected priorities table<Event.Handler, integer>
---@field protected once_handlers table<Event.Handler, boolean>
local __Event = {}

---@return string
---@protected
function __Event:__represent() end

---@return boolean
---@protected
function __Event:__toboolean() end

---@return integer
---@protected
function __Event:__len() end

---@param name string | nil
---@protected
function __Event:__init(name) end

--- [SHARED AND MENU]
---
--- Checks if the event is running currently.
---
---@return boolean is_running Returns `true` if the event is running currently, otherwise `false`.
---@nodiscard
function __Event:isRunning() end

--- [SHARED AND MENU]
---
--- Attaches a handler to the event.
---
--- If the handler is already attached, only its priority is updated
--- (when a new one is supplied); it will not be attached twice.
---
---@param handler Event.Handler The callback or callable object, receives the `call` arguments.
---@param priority integer | nil The priority of the handler; handlers with a lower value run earlier. Defaults to `0`.
function __Event:attach(handler, priority) end

--- [SHARED AND MENU]
---
--- Attaches a one-shot handler, detached right before it runs.
---
--- It can still be removed with `detach` using the same `handler` reference.
---
---@param handler Event.Handler The callback or callable object, receives the `call` arguments.
---@param priority integer | nil The priority of the handler; handlers with a lower value run earlier. Defaults to `0`.
function __Event:once(handler, priority) end

--- [SHARED AND MENU]
---
--- Detaches a handler previously passed to `attach` or `once`.
---
--- Detaching during a `call` skips the handler in every call in progress.
---
---@param handler Event.Handler The exact handler reference.
---@return boolean is_detached Returns `true` if the handler was attached, otherwise `false`.
function __Event:detach(handler) end

--- [SHARED AND MENU]
---
--- Removes every handler attached to the event.
---
--- Handlers still pending in a running `call` are skipped.
---
function __Event:clear() end

--- [SHARED AND MENU]
---
--- Runs every attached handler with `...`, in priority order.
---
--- Each handler runs in protected mode: errors are reported and the rest still run.
--- Non-function handlers are called through their `__call` metamethod with themselves first.
---
---@param ... any Arguments forwarded to every handler.
function __Event:call(...) end

--- [SHARED AND MENU]
---
--- Suspends the caller until the event is next called, then returns its arguments.
---
---@return any ... The arguments the event was called with.
---@async
function __Event:await() end

--- [SHARED AND MENU]
---
--- The class used to create new `Event` instances.
---
---@class EventClass : Event, Class
---@field __base Event
---@overload fun( name: string? ): Event
Event = {}
