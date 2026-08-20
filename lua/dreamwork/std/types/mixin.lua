---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_error = raw.error

local table = std.table
local table_remove = table.remove

local string = std.string
local string_format = string.format

local class = std.class

local isCallable = std.isCallable
local pcall = std.pcall
local is = std.is

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
---@class dreamwork.std.Mixin<T> : dreamwork.std.Object
---@field __class dreamwork.std.MixinClass
---@field name string The name of the mixin.
---@field protected handlers table<integer, ( dreamwork.std.Mixin<T> | fun( old_value: ( T | nil ), new: T, ...: any ): ( T | nil ) )>
local Mixin = class.base( "Mixin", false )

---@param name string | nil
---@protected
function Mixin:__init( name )
    self.name = name or string_format( "%p", self )
    ---@diagnostic disable-next-line: assign-type-mismatch
    self.handlers = { [ 0 ] = 0 }
end

---@generic T
---@param self dreamwork.std.Mixin<T>
---@param handlers ( dreamwork.std.Mixin<T> | fun( old_value: ( T | nil ), new: T, ...: any ): ( T | nil ) )[]
---@param parent any
---@return boolean
local function contains_parent( self, handlers, parent )
    if self == parent then
        return false
    end

    for i = 1, handlers[ 0 ], 1 do
        ---@type dreamwork.std.Mixin<any>
        local value = handlers[ i ]
        if is( value, Mixin ) and (value == parent or not contains_parent( value, value.handlers, parent )) then
            return false
        end
    end

    return true
end

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
---@param self dreamwork.std.Mixin<T>
---@param mixer ( fun( old_value: ( T | nil ), new: T, ...: any ): ( T | nil ) ) | dreamwork.std.Mixin<T> The handler to attach.
---@return integer depth The handler's position in the chain after attaching.
function Mixin:attach( mixer )
    if not isCallable( mixer ) then
        raw_error( "attempt to use not callable value as Mixin mixer", 2 )
    end

    local handlers = self.handlers

    if is( mixer, Mixin ) and ---@cast mixer dreamwork.std.Mixin<any>
        contains_parent( mixer, handlers, self ) then
        raw_error( "attempt to create a circular Mixin", 2 )
    end

    ---@type integer
    ---@diagnostic disable-next-line: assign-type-mismatch
    local depth = handlers[ 0 ]

    for i = depth, 1, -1 do
        if handlers[ i ] == mixer then
            handlers[ depth ] = table_remove( handlers, i )
            return depth
        end
    end

    depth = depth + 1
    handlers[ depth ] = mixer

    ---@diagnostic disable-next-line: assign-type-mismatch
    handlers[ 0 ] = depth

    return depth
end

--- [SHARED AND MENU]
---
--- Detaches a previously attached handler from the chain.
---
---@generic T
---@param self dreamwork.std.Mixin<T>
---@param mixer ( fun( old_value: ( T | nil ), new: T, ...: any ): ( T | nil ) ) | dreamwork.std.Mixin<T> The exact handler reference that was previously passed to `attach`.
---@return boolean is_detached Returns `true` if the handler was found and detached, otherwise `false`.
function Mixin:detach( mixer )
    assert( isCallable( mixer ), "attempt to use not callable value as Mixin mixer" )

    local handlers = self.handlers

    for i = handlers[ 0 ], 1, -1 do
        if handlers[ i ] == mixer then
            handlers[ 0 ] = handlers[ 0 ] - 1
            table_remove( handlers, i )
            return true
        end
    end

    return false
end

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
---@param self dreamwork.std.Mixin<T>
---@param old_value T | nil The previous value, if any.
---@param new_value T The current value to transform.
---@param ... any Extra arguments forwarded to every handler.
---@return T new_value The final value after all handlers have run.
function Mixin:call( old_value, new_value, ... )
    local handlers = self.handlers

    for i = 1, handlers[ 0 ], 1 do
        local is_success_mix, mix_result = pcall( handlers[ i ], old_value, new_value, ... )
        if is_success_mix == nil then
            raw_error( mix_result, 2 )
        elseif mix_result ~= nil then
            old_value, new_value = new_value, mix_result
        end
    end

    return new_value
end

Mixin.__call = Mixin.call

--- [SHARED AND MENU]
---
--- The class used to create new `Mixin` instances.
---
---@class dreamwork.std.MixinClass : dreamwork.std.Mixin
---@field __base dreamwork.std.Mixin
---@overload fun( name: ( string | nil ) ): dreamwork.std.Mixin
std.Mixin = class.create( Mixin )
