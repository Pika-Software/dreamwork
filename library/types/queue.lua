---@meta _

--- [SHARED AND MENU]
---
--- A queue is a first-in-first-out (FIFO) data structure object.
---
--- Values are appended at one end and removed from the other by default
--- (`push` appends to the front, `pop` removes from the back), so the
--- earliest-pushed value is the first one popped.
---
--- Both `push` and `pop` accept an optional flag to operate on the opposite
--- end instead, which lets the same object also be used as a deque.
---
--- Elements are stored between the `back` and `front` indices,
--- which are advanced/rewound as values are pushed and popped,
--- and are reset to `0` whenever the queue becomes empty.
---
---@class Queue<T> : Object
---@field __class QueueClass
---@field front integer The front of the queue. **Read-only**
---@field back integer The back of the queue. **Read-only**
local __Queue = {}

---@return string
---@protected
function __Queue:__represent() end

---@return boolean
---@protected
function __Queue:__toboolean() end

---@return integer
---@protected
function __Queue:__len() end

---@protected
function __Queue:__init() end

--- [SHARED AND MENU]
---
--- Checks if the queue is empty.
---
---@generic T
---@param self Queue<T>
---@return boolean is_empty Returns `true` if the queue has no values, otherwise `false`.
---@nodiscard
function __Queue:isEmpty() end

--- [SHARED AND MENU]
---
--- Empties the queue, removing every value and resetting `front` and `back` to `0`.
---
---@generic T
---@param self Queue<T>
function __Queue:clear() end

--- [SHARED AND MENU]
---
--- Returns the value at the front of the queue or the back if `from_tail` is `true`.
---
---@generic T
---@param self Queue<T>
---@param from_tail? boolean If `true`, returns the value at the back of the queue.
---@return T | nil value The value at the front of the queue, or `nil` if the queue is empty.
---@nodiscard
function __Queue:peek(from_tail) end

--- [SHARED AND MENU]
---
--- Appends a value to the end of the queue or the front if `to_head` is `true`.
---
---@generic T
---@param self Queue<T>
---@param value T The value to append.
---@param to_head? boolean If `true`, appends the value to the front of the queue.
function __Queue:push(value, to_head) end

--- [SHARED AND MENU]
---
--- Removes and returns the value at the back of the queue or the front if `from_tail` is `true`.
---
---@generic T
---@param self Queue<T>
---@param from_tail? boolean If `true`, removes and returns the value at the front of the queue.
---@return T | nil value The value at the back of the queue or the front if `from_tail` is `true`, or `nil` if the queue is empty.
function __Queue:pop(from_tail) end

--- [SHARED AND MENU]
---
--- Returns an iterator for the queue.
---
---@generic T
---@param self Queue<T>
---@param from_tail? boolean If `true`, returns an iterator for the back of the queue.
---@return fun( queue: Queue<T>, from_tail: boolean ): T iterator The iterator function.
---@return Queue<T> queue The queue being iterated over.
---@return boolean from_tail `true` if the iterator is for the back of the queue.
---@nodiscard
function __Queue:iterator(from_tail) end

--- [SHARED AND MENU]
---
--- The class used to create new `Queue` instances.
---
---@class QueueClass : Queue
---@field __base Queue
---@overload fun(): Queue
Queue = {}
