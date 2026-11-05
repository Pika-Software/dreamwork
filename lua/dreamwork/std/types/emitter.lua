local dreamwork_exceptions = dreamwork.exceptions
local exceptions_call = dreamwork_exceptions.call

---@class dreamwork.std
local std = dreamwork.std

local class = std.class

local debug = std.debug
local debug_fempty = debug.fempty
local debug_getmetavalue = debug.getmetavalue

local raw = std.raw
local raw_pairs = raw.pairs
local raw_get, raw_set = raw.get, raw.set

local string = std.string
local string_format = string.format

local type = std.type
local isFunction = std.isFunction

local Future = std.Future

--- Owner names used in error messages, kept out of the emitters (which hold only listener lists).
---
---@type table<dreamwork.std.Emitter, string>
local names = {}
setmetatable( names, { __mode = "k" } )

--- A function, or a callable object such as a `Hook` (called through its `__call` metamethod).
---
---@alias dreamwork.std.Emitter.Handler function | dreamwork.std.Hook

--- One event's handlers: `[0]` is the count, `[1..n]` the handlers in attach order.
---
--- `once[ handler ]` marks one-shot handlers, `emitting` counts nested `emit` calls
--- and `dirty` is set when a handler was detached mid-emit (slot holds `debug.fempty`).
---
---@class dreamwork.std.Emitter.List
---@field [0] integer
---@field [integer] dreamwork.std.Emitter.Handler
---@field once table<dreamwork.std.Emitter.Handler, boolean>
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
--- local events = std.Emitter( "Thing" )
---
--- function Thing:attach( event, handler ) events:attach( self, event, handler ) end
---
--- events:emit( thing, "open", thing )
--- ```
---
---@class dreamwork.std.Emitter : dreamwork.std.Object
---@field __class dreamwork.std.EmitterClass
---@field protected [any] table<string, dreamwork.std.Emitter.List> Per-object lists, weak keys.
local Emitter = class.base( "Emitter", false, nil )

-- every instance is its own weak-keyed listener table
Emitter.__mode = "k"

---@param name string Owner name used in error messages, e.g. `"WebClient"`.
---@protected
function Emitter:__init( name )
    names[ self ] = name
end

---@return string
---@protected
function Emitter:__represent()
    return string_format( "%s: %p [%s]", type( self ), self, names[ self ] )
end

function Emitter:__len()
    local count = 0

    for _ in raw_pairs( self ) do
        count = count + 1
    end

    return count
end

--- Removes `debug.fempty` slots left by mid-emit detaches.
---
---@param list dreamwork.std.Emitter.List
local function compact( list )
    local count = list[ 0 ]
    local size = 0

    for i = 1, count, 1 do
        local handler = list[ i ]
        if handler ~= debug_fempty then
            size = size + 1
            list[ size ] = handler
        end
    end

    for i = size + 1, count, 1 do
        list[ i ] = nil
    end

    list[ 0 ] = size
    list.dirty = false
end

--- Removes `handler` from `list`, deferring the shift while the list is emitting.
---
---@param list dreamwork.std.Emitter.List
---@param handler dreamwork.std.Emitter.Handler
---@return boolean removed
local function remove( list, handler )
    local count = list[ 0 ]

    for i = 1, count, 1 do
        if list[ i ] == handler then
            list.once[ handler ] = nil

            if list.emitting == 0 then
                for j = i, count - 1, 1 do
                    list[ j ] = list[ j + 1 ]
                end

                list[ count ] = nil
                list[ 0 ] = count - 1
            else
                list[ i ] = debug_fempty
                list.dirty = true
            end

            return true
        end
    end

    return false
end

--- Appends `handler`, a handler already in the list only updates its one-shot flag.
---
---@param emitter dreamwork.std.Emitter
---@param object any
---@param event_name string
---@param handler dreamwork.std.Emitter.Handler
---@param once boolean
local function add( emitter, object, event_name, handler, once )
    ---@type table<any, dreamwork.std.Emitter.List>
    local lists = raw_get( emitter, object )
    if lists == nil then
        lists = {}
        raw_set( emitter, object, lists )
    end

    ---@type dreamwork.std.Emitter.List
    local list = lists[ event_name ]
    if list == nil then
        list = {
            [ 0 ] = 0,
            once = {},
            emitting = 0,
            dirty = false,
        }

        lists[ event_name ] = list
    end

    list.once[ handler ] = once or nil

    for i = 1, list[ 0 ], 1 do
        if list[ i ] == handler then
            return
        end
    end

    local index = list[ 0 ] + 1
    list[ 0 ] = index
    list[ index ] = handler
end

--- [SHARED AND MENU]
---
--- Attaches a handler for `event_name` on `object`. Attaching the same handler twice is a no-op.
---
---@param object any The object the handler listens on.
---@param event_name string The event name.
---@param handler dreamwork.std.Emitter.Handler The callback or callable object, receives the `emit` arguments.
function Emitter:attach( object, event_name, handler )
    add( self, object, event_name, handler, false )
end

--- [SHARED AND MENU]
---
--- Attaches a one-shot handler, detached right before it runs.
---
--- It can still be removed with `detach` using the same `handler` reference.
---
---@param object any The object the handler listens on.
---@param event_name string The event name.
---@param handler dreamwork.std.Emitter.Handler The callback or callable object, receives the `emit` arguments.
function Emitter:once( object, event_name, handler )
    add( self, object, event_name, handler, true )
end

--- [SHARED AND MENU]
---
--- Detaches a handler previously passed to `attach` or `once`.
---
---@param object any The object the handler listens on.
---@param event_name string The event name.
---@param handler dreamwork.std.Emitter.Handler The exact handler reference.
---@return boolean removed `true` if the handler was attached.
function Emitter:detach( object, event_name, handler )
    local lists = raw_get( self, object )
    if lists == nil then
        return false
    end

    local list = lists[ event_name ]
    if list == nil then
        return false
    end

    return remove( list, handler )
end

--- [SHARED AND MENU]
---
--- Removes every handler of `event_name` on `object`, or of every event when `event_name` is `nil`.
---
--- Handlers still pending in a running `emit` of a cleared event are skipped.
---
---@param object any The object to clear.
---@param event_name? string The event name, or `nil` for all events.
function Emitter:clear( object, event_name )
    local lists = raw_get( self, object )
    if lists == nil then
        return
    end

    if event_name ~= nil then
        local list = lists[ event_name ]
        if list ~= nil then
            for i = list[ 0 ], 1, -1 do
                remove( list, list[ i ] )
            end
        end

        return
    end

    for _, list in raw_pairs( lists ) do
        for i = list[ 0 ], 1, -1 do
            remove( list, list[ i ] )
        end
    end
end

--- [SHARED AND MENU]
---
--- Returns the number of handlers attached to `event_name` on `object`.
---
---@param object any The object to inspect.
---@param event_name string The event name.
---@return integer count
---@nodiscard
function Emitter:count( object, event_name )
    local lists = raw_get( self, object )
    if lists == nil then
        return 0
    end

    local list = lists[ event_name ]
    if list == nil then
        return 0
    end

    if list.dirty then
        local count = 0
        for i = 1, list[ 0 ], 1 do
            if list[ i ] ~= debug_fempty then
                count = count + 1
            end
        end

        return count
    end

    return list[ 0 ]
end

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
function Emitter:emit( object, event_name, ... )
    local lists = raw_get( self, object )
    if lists == nil then return end

    local list = lists[ event_name ]
    if list == nil then return end

    local count = list[ 0 ]
    if count == 0 then return end

    local once = list.once
    list.emitting = list.emitting + 1

    for i = 1, count, 1 do
        local handler = list[ i ]
        if handler ~= debug_fempty then
            if once[ handler ] then
                remove( list, handler )
            end

            if isFunction( handler ) then
                exceptions_call( handler, ... )
            else
                exceptions_call( debug_getmetavalue( handler, "__call" ), handler, ... )
            end
        end
    end

    local emitting = list.emitting - 1
    list.emitting = emitting

    if emitting == 0 and list.dirty then
        compact( list )
    end
end

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
---@param abort_event? string An event that cancels the wait, e.g. `"close"`.
---@param abort_message? string The error message thrown on abort.
---@return any ... The arguments `event` was emitted with.
---@async
function Emitter:await( object, event_name, abort_event, abort_message )
    local future = Future()
    local on_event, on_abort

    function on_event( ... )
        if abort_event ~= nil then
            self:detach( object, abort_event, on_abort )
        end

        future:setResult( { ... } )
    end

    add( self, object, event_name, on_event, true )

    if abort_event ~= nil then
        function on_abort()
            self:detach( object, event_name, on_event )
            future:setError( abort_message or string_format( "%s '%s' fired while awaiting '%s'", names[ self ], abort_event, event_name ) )
        end

        add( self, object, abort_event, on_abort, true )
    end

    local result = future:await()
    return result[ 1 ], result[ 2 ], result[ 3 ], result[ 4 ], result[ 5 ], result[ 6 ]
end

--- [SHARED AND MENU]
---
--- The class used to create new `Emitter` registries.
---
---@class dreamwork.std.EmitterClass : dreamwork.std.Emitter, dreamwork.std.Class
---@field __base dreamwork.std.Emitter
---@overload fun( name: string ): dreamwork.std.Emitter
std.Emitter = class.create( Emitter )
