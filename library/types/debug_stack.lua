---@meta _

--- [SHARED AND MENU]
---
--- A specialized `Stack` that holds `debug.StackLevel`
--- call-stack frames captured via `debug.getstack`.
---
--- Unlike a plain stack, `capture` is coalescing: instead of blindly
--- replacing its contents on every call, it compares the newly captured
--- frames against the frames it already holds (starting from the top) and
--- only appends the frames that changed. This lets the same `Stack`
--- instance be reused across repeated captures (e.g. on every `error` call
--- within a loop) without re-allocating or re-formatting frames that are
--- still the same as before.
---
---@class debug.Stack : Stack
---@field __class debug.StackClass
---@field __parent Stack
---@field push fun( self: debug.Stack, info: debug.StackLevel ): integer
---@field pop fun( self: debug.Stack ): debug.StackLevel | nil
---@field peek fun( self: debug.Stack ): debug.StackLevel | nil
---@field size integer The size of the stack. **Read-only**
---@field start integer The index of the first frame belonging to the most recent `capture` call, i.e. the "hop start". Used to bound how far back coalescing needs to compare.
local Stack = {}

---@protected
function Stack:__init() end

---@return debug.Stack
---@protected
function Stack:__copy() end

--- [SHARED AND MENU]
---
--- Contains information about a function with extra fields.
---
---@class debug.StackLevel : debuginfo
---@field thread thread | nil Thread of call, available only when called inside a coroutine.

--- [SHARED AND MENU]
---
--- Merges the given `other` stack into this one, with the `other` stack's frames reversed before merging.
---
---@param other debug.Stack The stack to merge into this one.
function Stack:merge(other) end

--- [SHARED AND MENU]
---
--- Removes every item for which `predicate` returns `true`, keeping the order of the remaining items.
---
---@param predicate fun( item: debug.Stack ): boolean The function that decides whether a frame is removed.
function Stack:filter(predicate) end

--- [SHARED AND MENU]
---
--- Captures the current call stack and merges it into this `Stack`.
---
--- On the first call (empty stack), every captured frame is simply pushed
--- in bottom-to-top order.
---
--- On subsequent calls, the newly captured frames are compared against
--- the frames already stored, starting at the top of
--- the stack, and matched by `currentline`, `source` and `name`.
---
--- Frames behind the first match are assumed unchanged and are left alone;
--- only the new frames above the match (i.e. calls made since the previous capture) are appended.
---
--- If no match is found, the new capture is appended wholesale on top of the existing frames.
---
---@param stack_level? integer  How many levels to skip to reach the caller (same meaning as the `level` argument of `debug.getstack`/`debug.getinfo`). Defaults to `2`, i.e. the function calling `capture`.
---@param head_skip? integer    Constant number of frames to drop from the innermost end of the capture (e.g. `1` to drop the bare `error` C frame).
---@param tail_skip? integer    Constant number of frames to drop from the outermost end of the capture (e.g. to drop your own `xpcall`/wrapper frames).
---@param max_levels? integer   Maximum number of stack frames to read, counted from the innermost frame (after `head_skip` is applied). Stack walking stops as soon as this many frames have been captured, so frames further up (older/outer) are never read at all. `nil`/omitted means no limit.
function Stack:capture(stack_level, head_skip, tail_skip, max_levels) end

--- [SHARED AND MENU]
---
--- The class used to create new `debug.Stack` instances.
---
---@class debug.StackClass : Stack
---@field __parent StackClass
---@field __base debug.Stack
---@overload fun(): debug.Stack
debug.Stack = {}
