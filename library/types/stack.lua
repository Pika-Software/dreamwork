---@meta _

--- [SHARED AND MENU]
---
--- A stack is a last-in-first-out (LIFO) data structure object.
---
--- Values are added and removed from the same end (the "top") via `push`
--- and `pop`, so the most recently pushed value is always the first one
--- popped.
---
--- The stack can also be iterated destructively with `iterator`, which pops
--- values one by one until it is empty.
---
---@class Stack<T>: Object
---@field __class StackClass
---@field size integer The size of the stack. **Read-only**
local __Stack = {}

---@return string
---@protected
function __Stack:__represent() end

---@return boolean
---@protected
function __Stack:__toboolean() end

---@return integer
---@protected
function __Stack:__len() end

---@protected
function __Stack:__init() end

--- Writes the stack, the number of values (`UInt32`), then every value from the bottom to the top,
--- each is a presence bit and the value (`writer:writeObject`).
---
--- Values must be objects with `__serialize`, or `nil`.
---
---@generic T
---@param self Stack<T>
---@param writer BinaryWriter The writer.
---@param ... any The arguments passed to `__serialize` of every value.
---@protected
function __Stack:__serialize(writer, ...) end

--- Reads the stack written by `__serialize`, replacing its values,
--- values are read with `reader:readClass( value_class, ... )`.
---
--- ```
--- local stack = reader:readClass( Stack, Vector3 )
--- ```
---
---@generic T
---@param self Stack<T>
---@param reader BinaryReader The reader.
---@param value_class? Class The class of the values, can be omitted if every value is `nil`.
---@param ... any The arguments passed to `__deserialize` of every value.
---@protected
function __Stack:__deserialize(reader, value_class, ...) end

--- [SHARED AND MENU]
---
--- Checks if the stack is empty.
---
---@return boolean is_empty Returns `true` if the stack has no values, otherwise `false`.
---@nodiscard
function __Stack:isEmpty() end

--- [SHARED AND MENU]
---
--- Pushes a value onto the stack.
---
---@generic T
---@param self Stack<T>
---@param value T The value to push onto the stack.
---@return integer position The position of the value in the stack.
function __Stack:push(value) end

--- [SHARED AND MENU]
---
--- Pops the value from the top of the stack.
---
---@generic T
---@param self Stack<T>
---@return T | nil value The value that was removed from the stack, or `nil` if the stack is empty.
function __Stack:pop() end

--- [SHARED AND MENU]
---
--- Returns the value at the top of the stack.
---
---@generic T
---@param self Stack<T>
---@return T | nil value The value at the top of the stack, or `nil` if the stack is empty.
---@nodiscard
function __Stack:peek() end

--- [SHARED AND MENU]
---
--- Empties the stack, removing every value and resetting its size to `0`.
---
function __Stack:clear() end

--- [SHARED AND MENU]
---
--- Removes every item for which `predicate` returns `true`, keeping the order of the remaining items.
---
---@generic T
---@param self Stack<T>
---@param predicate fun( item: T ): boolean The function that decides whether a frame is removed.
function __Stack:filter(predicate) end

--- [SHARED AND MENU]
---
--- Returns an iterator for the stack, suitable for use in a `for` loop
--- (e.g. `for value in stack:iterator() do ... end`). Iterating pops values
--- off the stack one at a time until it is empty, so this consumes the stack.
---
---@generic T
---@param self Stack<T>
---@return fun( self: Stack<T> ): T | nil iterator The iterator function; calling it pops and returns the next value, or `nil` once the stack is empty.
---@return Stack<T> stack The stack being iterated over, passed as state to the iterator function.
---@nodiscard
function __Stack:iterator() end

--- [SHARED AND MENU]
---
--- The class used to create new `Stack` instances.
---
---@class StackClass : Stack
---@field __base Stack
---@overload fun(): Stack
Stack = {}
