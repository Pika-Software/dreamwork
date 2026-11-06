local dreamwork_exceptions = dreamwork.exceptions
local exceptions_call = dreamwork_exceptions.call

---@class dreamwork.std
local std = dreamwork.std

local debug = std.debug
local debug_getmetavalue = debug.getmetavalue

local table = std.table
local table_unpack = table.unpack

local string = std.string
local string_format = string.format

local class = std.class

local isType = std.isType
local isFunction = std.isFunction
local error = std.error

local Future = std.Future


--- A function, or a callable object such as another `Event` (called through its `__call` metamethod).
---
---@alias dreamwork.std.Event.Handler function | dreamwork.std.Event

--- Handlers sorted by priority: `[0]` is the count, `[1..n]` the handlers.
---
--- `iterating` counts the `call` loops walking this list, a list being walked
--- is never mutated, `attach`/`detach` swap in a fresh copy instead.
---
---@class dreamwork.std.Event.List
---@field [0] integer
---@field [integer] dreamwork.std.Event.Handler
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
---@class dreamwork.std.Event : dreamwork.std.Object
---@field __class dreamwork.std.EventClass
---@field name string The name of the event.
---@field protected running integer The number of `call`s in progress.
---@field protected handlers dreamwork.std.Event.List
---@field protected priorities table<dreamwork.std.Event.Handler, integer>
---@field protected once_handlers table<dreamwork.std.Event.Handler, boolean>
local Event = class.base( "Event", false, nil )

---@return string
---@protected
function Event:__represent()
    return string_format( "Event: %p [%s][%s]", self, self.name, self.running == 0 and "stopped" or "running" )
end

---@return boolean
---@protected
function Event:__toboolean()
    return self.running ~= 0
end

---@return integer
---@protected
function Event:__len()
    ---@diagnostic disable-next-line: return-type-mismatch
    return self.handlers[ 0 ]
end

---@param name string | nil
---@protected
function Event:__init( name )
    self.name = name or string_format( "%p", self )
    self.running = 0
    self:clear()
end

--- [SHARED AND MENU]
---
--- Checks if the event is running currently.
---
---@return boolean is_running Returns `true` if the event is running currently, otherwise `false`.
---@nodiscard
function Event:isRunning()
    return self.running ~= 0
end

--- Returns the handler list of `self`, copied first if a `call` is walking it.
---
---@param self dreamwork.std.Event
---@return dreamwork.std.Event.List list
local function writable( self )
    ---@diagnostic disable-next-line: invisible
    local list = self.handlers
    if list.iterating == 0 then
        return list
    end

    local count = list[ 0 ]

    ---@type dreamwork.std.Event.List
    local copy = { [ 0 ] = count, iterating = 0 }

    for i = 1, count, 1 do
        copy[ i ] = list[ i ]
    end

    ---@diagnostic disable-next-line: invisible
    self.handlers = copy
    return copy
end

---@param list dreamwork.std.Event.List
---@param handler dreamwork.std.Event.Handler
local function remove( list, handler )
    local count = list[ 0 ]

    for i = 1, count, 1 do
        if list[ i ] == handler then
            for j = i, count - 1, 1 do
                list[ j ] = list[ j + 1 ]
            end

            list[ count ] = nil
            list[ 0 ] = count - 1
            return
        end
    end
end

--- Inserts `handler` after every handler with a lower or equal priority.
---
---@param list dreamwork.std.Event.List
---@param priorities table<dreamwork.std.Event.Handler, integer>
---@param handler dreamwork.std.Event.Handler
---@param priority integer
local function insert( list, priorities, handler, priority )
    local count = list[ 0 ]
    local index = count + 1

    while index > 1 and priorities[ list[ index - 1 ] ] > priority do
        list[ index ] = list[ index - 1 ]
        index = index - 1
    end

    list[ index ] = handler
    list[ 0 ] = count + 1
end

---@param self dreamwork.std.Event
---@param parent dreamwork.std.Event
---@return boolean is_contained
local function contains_parent( self, parent )
    if self == parent then
        return true
    end

    ---@diagnostic disable-next-line: invisible
    local list = self.handlers
    for i = 1, list[ 0 ], 1 do
        ---@type dreamwork.std.Event
        ---@diagnostic disable-next-line: assign-type-mismatch
        local value = list[ i ]
        if isType( value, Event ) and contains_parent( value, parent ) then
            return true
        end
    end

    return false
end

---@param self dreamwork.std.Event
---@param handler dreamwork.std.Event.Handler
---@param priority integer | nil
---@param once boolean
local function attach( self, handler, priority, once )
    if isType( handler, Event ) and ---@cast handler dreamwork.std.Event
        contains_parent( handler, self ) then
        error( "attempt to create circular event reference", 3 )
    end

    ---@diagnostic disable-next-line: invisible
    self.once_handlers[ handler ] = once or nil

    ---@diagnostic disable-next-line: invisible
    local priorities = self.priorities
    local current = priorities[ handler ]

    if current ~= nil then
        if priority == nil or priority == current then
            return
        end

        local list = writable( self )
        remove( list, handler )
        priorities[ handler ] = priority
        insert( list, priorities, handler, priority )
        return
    end

    priority = priority or 0
    priorities[ handler ] = priority
    insert( writable( self ), priorities, handler, priority )
end

--- [SHARED AND MENU]
---
--- Attaches a handler to the event.
---
--- If the handler is already attached, only its priority is updated
--- (when a new one is supplied); it will not be attached twice.
---
---@param handler dreamwork.std.Event.Handler The callback or callable object, receives the `call` arguments.
---@param priority integer | nil The priority of the handler; handlers with a lower value run earlier. Defaults to `0`.
function Event:attach( handler, priority )
    attach( self, handler, priority, false )
end

--- [SHARED AND MENU]
---
--- Attaches a one-shot handler, detached right before it runs.
---
--- It can still be removed with `detach` using the same `handler` reference.
---
---@param handler dreamwork.std.Event.Handler The callback or callable object, receives the `call` arguments.
---@param priority integer | nil The priority of the handler; handlers with a lower value run earlier. Defaults to `0`.
function Event:once( handler, priority )
    attach( self, handler, priority, true )
end

--- [SHARED AND MENU]
---
--- Detaches a handler previously passed to `attach` or `once`.
---
--- Detaching during a `call` skips the handler in every call in progress.
---
---@param handler dreamwork.std.Event.Handler The exact handler reference.
---@return boolean is_detached Returns `true` if the handler was attached, otherwise `false`.
function Event:detach( handler )
    local priorities = self.priorities
    if priorities[ handler ] == nil then
        return false
    end

    priorities[ handler ] = nil
    self.once_handlers[ handler ] = nil

    remove( writable( self ), handler )
    return true
end

--- [SHARED AND MENU]
---
--- Removes every handler attached to the event.
---
--- Handlers still pending in a running `call` are skipped.
---
function Event:clear()
    self.handlers = { [ 0 ] = 0, iterating = 0 }
    self.priorities = {}
    self.once_handlers = {}
end

--- [SHARED AND MENU]
---
--- Runs every attached handler with `...`, in priority order.
---
--- Each handler runs in protected mode: errors are reported and the rest still run.
--- Non-function handlers are called through their `__call` metamethod with themselves first.
---
---@param ... any Arguments forwarded to every handler.
function Event:call( ... )
    local list = self.handlers

    local count = list[ 0 ]
    if count == 0 then return end

    list.iterating = list.iterating + 1
    self.running = self.running + 1

    for i = 1, count, 1 do
        ---@type dreamwork.std.Event.Handler
        ---@diagnostic disable-next-line: assign-type-mismatch
        local handler = list[ i ]

        -- `clear` swaps the tables, so they are looked up on every step
        if self.priorities[ handler ] ~= nil then
            if self.once_handlers[ handler ] then
                self:detach( handler )
            end

            if isFunction( handler ) then
                ---@cast handler function
                exceptions_call( handler, ... )
            else
                exceptions_call( debug_getmetavalue( handler, "__call" ), handler, ... )
            end
        end
    end

    self.running = self.running - 1
    list.iterating = list.iterating - 1
end

Event.__call = Event.call

--- [SHARED AND MENU]
---
--- Suspends the caller until the event is next called, then returns its arguments.
---
---@return any ... The arguments the event was called with.
---@async
function Event:await()
    local future = Future()

    attach( self, function( ... )
        future:setResult( { ... } )
    end, nil, true )

    return table_unpack( future:await() )
end

--- [SHARED AND MENU]
---
--- The class used to create new `Event` instances.
---
---@class dreamwork.std.EventClass : dreamwork.std.Event, dreamwork.std.Class
---@field __base dreamwork.std.Event
---@overload fun( name: string? ): dreamwork.std.Event
std.Event = class.create( Event )
