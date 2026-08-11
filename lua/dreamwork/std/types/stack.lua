---@class dreamwork.std
local std = dreamwork.std

local string = std.string
local class = std.class

--- [SHARED AND MENU]
---
--- A stack is a last-in-first-out (LIFO) data structure object.
---
---@class dreamwork.std.Stack<T>: dreamwork.std.Object
---@field __class dreamwork.std.StackClass
---@field size integer The size of the stack. **Read-only**
local Stack = class.base( "Stack", false, nil )

---@return string
---@protected
function Stack:__represent()
    return string.format( "%s: %p [%d]", self.__type, self, self.size )
end

---@return boolean
---@protected
function Stack:__toboolean()
    return self.size ~= 0
end

---@return integer
---@protected
function Stack:__len()
    return self.size
end

---@protected
function Stack:__init()
    self.size = 0
end

---@param writer dreamwork.std.buffer.Writer
---@protected
function Stack:__serialize( writer )
    local size = self.size
    writer:writeInt32( size )

    for i = 1, size, 1 do
        writer:serialize( self[ i ] )
    end
end

---@param reader dreamwork.std.buffer.Reader
---@param fallback dreamwork.std.Object | nil
---@protected
function Stack:__deserialize( reader, fallback )
    local size = reader:readInt32() or 0
    self.size = size

    for i = 1, size, 1 do
        self[ i ] = reader:deserialize( self[ i ] or fallback or Stack, fallback )
    end
end

--- [SHARED AND MENU]
---
--- Checks if the stack is empty.
---
---@return boolean
function Stack:isEmpty()
    return self.size == 0
end

--- [SHARED AND MENU]
---
--- Pushes a value onto the stack.
---
---@generic T
---@param self dreamwork.std.Stack<T>
---@param value T The value to push onto the stack.
---@return integer position The position of the value in the stack.
function Stack:push( value )
    local position = self.size + 1
    self.size, self[ position ] = position, value
    return position
end

--- [SHARED AND MENU]
---
--- Pops the value from the top of the stack.
---
---@generic T
---@param self dreamwork.std.Stack<T>
---@return T | nil value The value that was removed from the stack, or `nil` if the stack is empty.
function Stack:pop()
    local position = self.size
    if position == 0 then
        return nil
    end

    self.size = position - 1

    local value = self[ position ]
    self[ position ] = nil
    return value
end

--- [SHARED AND MENU]
---
--- Returns the value at the top of the stack.
---
---@generic T
---@param self dreamwork.std.Stack<T>
---@return T | nil value The value at the top of the stack, or `nil` if the stack is empty.
function Stack:peek()
    return self[ self.size ]
end

--- [SHARED AND MENU]
---
--- Empties the stack.
---
function Stack:empty()
    for i = 1, self.size, 1 do
        self[ i ] = nil
    end

    self.size = 0
end

--- [SHARED AND MENU]
---
--- Returns an iterator for the stack.
---
---@return function iterator The iterator function.
---@return dreamwork.std.Stack stack The stack being iterated over.
function Stack:iterator()
    return self.pop, self
end

--- [SHARED AND MENU]
---
--- A stack class.
---
---@class dreamwork.std.StackClass : dreamwork.std.Stack
---@field __base dreamwork.std.Stack
---@overload fun(): dreamwork.std.Stack
local StackClass = class.create( Stack )
std.Stack = StackClass
