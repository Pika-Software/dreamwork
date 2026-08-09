---@class dreamwork.std
local std = dreamwork.std
local class = std.class

--- [SHARED AND MENU]
---
--- A queue is a first-in-first-out (FIFO) data structure object.
---
---@class dreamwork.std.Queue<T> : dreamwork.std.Object
---@field __class dreamwork.std.QueueClass
---@field front integer The front of the queue. **Read-only**
---@field back integer The back of the queue. **Read-only**
local Queue = class.base( "Queue" )

---@protected
function Queue:__init()
    self.front = 0
    self.back = 0
end

---@param writer dreamwork.std.buffer.Writer
---@protected
function Queue:__serialize( writer )
    writer:writeInt32( self.front )
    writer:writeInt32( self.back )

    for i = self.back + 1, self.front, 1 do
        writer:serialize( self[ i ] )
    end
end

---@param reader dreamwork.std.buffer.Reader
---@param fallback dreamwork.std.Object | nil
---@protected
function Queue:__deserialize( reader, fallback )
    local front, back = reader:readInt32() or 0, reader:readInt32() or 0
    self.front, self.back = front, back

    for i = back + 1, front, 1 do
        self[ i ] = reader:deserialize( self[ i ] or fallback or Queue, fallback )
    end
end

--- [SHARED AND MENU]
---
--- Returns the length of the queue.
---
---@return integer length The length of the queue.
function Queue:getLength()
    return self.front - self.back
end

--- [SHARED AND MENU]
---
--- Checks if the queue is empty.
---
---@return boolean isEmpty Returns true if the queue is empty.
function Queue:isEmpty()
    return self.front == self.back
end

--- [SHARED AND MENU]
---
--- Empties the queue.
---
function Queue:empty()
    for i = self.back + 1, self.front, 1 do
        self[ i ] = nil
    end

    self.front = 0
    self.back = 0
end

--- [SHARED AND MENU]
---
--- Returns the value at the front of the queue or the back if `from_tail` is `true`.
---
---@generic T
---@param self dreamwork.std.Queue<T>
---@param from_tail? boolean If `true`, returns the value at the back of the queue.
---@return T | nil value The value at the front of the queue, or `nil` if the queue is empty.
function Queue:peek( from_tail )
    return self[ from_tail and self.front or (self.back + 1) ]
end

--- [SHARED AND MENU]
---
--- Appends a value to the end of the queue or the front if `to_head` is `true`.
---
---@generic T
---@param self dreamwork.std.Queue<T>
---@param value T The value to append.
---@param to_head? boolean If `true`, appends the value to the front of the queue.
function Queue:push( value, to_head )
    if to_head then
        local back = self.back
        self[ back ] = value
        self.back = back - 1
    else
        local front = self.front + 1
        self[ front ] = value
        self.front = front
    end
end

--- [SHARED AND MENU]
---
--- Removes and returns the value at the back of the queue or the front if `from_tail` is `true`.
---
---@generic T
---@param self dreamwork.std.Queue<T>
---@param from_tail? boolean If `true`, removes and returns the value at the front of the queue.
---@return T | nil value The value at the back of the queue or the front if `from_tail` is `true`, or `nil` if the queue is empty.
function Queue:pop( from_tail )
    local back, front = self.back, self.front
    if back == front then return nil end

    local value

    if from_tail then

        value = self[ front ]
        self[ front ] = nil -- unreference the value

        front = front - 1
        self.front = front

    else

        back = back + 1
        self.back = back

        value = self[ back ]
        self[ back ] = nil -- unreference the value

    end

    -- reset pointers if the queue is empty
    if back == front then
        self.front = 0
        self.back = 0
    end

    return value
end

--- [SHARED AND MENU]
---
--- Returns an iterator for the queue.
---
---@generic T
---@param self dreamwork.std.Queue<T>
---@param from_tail? boolean If `true`, returns an iterator for the back of the queue.
---@return fun( queue: dreamwork.std.Queue<T>, from_tail: boolean ): T iterator The iterator function.
---@return dreamwork.std.Queue<T> queue The queue being iterated over.
---@return boolean from_tail `true` if the iterator is for the back of the queue.
function Queue:iterator( from_tail )
    return self.pop, self, from_tail == true
end

--- [SHARED AND MENU]
---
--- A queue class.
---
---@class dreamwork.std.QueueClass : dreamwork.std.Queue
---@field __base dreamwork.std.Queue
---@overload fun(): dreamwork.std.Queue
local QueueClass = class.create( Queue )
std.Queue = QueueClass

---@alias Queue dreamwork.std.Queue
