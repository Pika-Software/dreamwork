---@class dreamwork.std
local std = dreamwork.std

---@class dreamwork.std.debug
local debug = std.debug
local debug_getstack = debug.getstack
local debug_getmetatable = debug.getmetatable

local math = std.math
local math_min = math.min

local string = std.string
local string_match = string.match

local table = std.table
local table_reversed = table.reversed

local coroutine = std.coroutine
local coroutine_running = coroutine.running

local class = std.class
local class_new = class.new


--- [SHARED AND MENU]
---
--- A specialized `dreamwork.std.Stack` that holds `dreamwork.std.debug.StackLevel`
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
---@class dreamwork.std.debug.Stack : dreamwork.std.Stack
---@field __class dreamwork.std.debug.StackClass
---@field __parent dreamwork.std.Stack
---@field push fun( self: dreamwork.std.debug.Stack, info: dreamwork.std.debug.StackLevel ): integer
---@field pop fun( self: dreamwork.std.debug.Stack ): dreamwork.std.debug.StackLevel | nil
---@field peek fun( self: dreamwork.std.debug.Stack ): dreamwork.std.debug.StackLevel | nil
---@field size integer The size of the stack. **Read-only**
---@field start integer The index of the first frame belonging to the most recent `capture` call, i.e. the "hop start". Used to bound how far back coalescing needs to compare.
local Stack = class.base( "debug.Stack", false, std.Stack )

---@protected
function Stack:__init()
    self.start = 1 -- hop start
    self.size = 0
end

---@return dreamwork.std.debug.Stack
---@protected
function Stack:__copy()
    ---@type dreamwork.std.debug.Stack
    ---@diagnostic disable-next-line: param-type-mismatch, assign-type-mismatch
    local object = class_new( debug_getmetatable( self ) )

    for i = 1, self.size, 1 do
        object[ i ] = self[ i ]
    end

    object.start = self.start
    object.size = self.size

    return object
end

--- [SHARED AND MENU]
---
--- Contains information about a function with extra fields.
---
---@class dreamwork.std.debug.StackLevel : dreamwork.std.debug.Info
---@field thread thread | nil Thread of call, available only when called inside a coroutine.

---@param stack_level dreamwork.std.debug.Info
---@param current_thread thread | nil
---@return dreamwork.std.debug.StackLevel stack_level
local function update_source( stack_level, current_thread )
    ---@cast stack_level dreamwork.std.debug.StackLevel
    local source = stack_level.source

    if source ~= nil and source ~= "=[C]" then
        ---@type string
        local relative_path = string_match( source, "^@?.-(lua/.*)$", 1 ) or source
        stack_level.source = "/workspace/" .. (string_match( relative_path, "^.-([%w_]+/gamemode/.*)$", 1 ) or relative_path)
    end

    stack_level.thread = current_thread
    return stack_level
end

---@param self dreamwork.std.debug.Stack
---@param levels dreamwork.std.debug.Info[]
---@param level_count integer
local function merge( self, levels, level_count )
    local stack_size = self.size

    if stack_size == 0 then
        for i = 1, level_count, 1 do
            self[ i ] = levels[ (level_count - i) + 1 ]
        end

        self.start = 1 -- hop start
        self.size = level_count
        return
    end

    for d = 0, math_min( (stack_size - self.start) + 1, level_count ) - 1, 1 do
        local old_info = self[ stack_size - d ]
        local new_info = levels[ d + 1 ]

        if old_info.currentline == new_info.currentline
            and old_info.source == new_info.source
            and old_info.name == new_info.name then

            -- matched frame and everything behind it is already correct;
            -- just append the part of the new capture that's genuinely new
            for i = 1, d, 1 do
                self[ (stack_size - d) + i ] = levels[ (d - i) + 1 ]
            end

            self.size = stack_size            -- unchanged depth
            self.start = (stack_size - d) + 1 -- optional but correct: bound future search to just the newly-written frames
            return
        end
    end

    local start = stack_size + 1

    for i = 1, level_count, 1 do
        self[ (start + i) - 1 ] = levels[ (level_count - i) + 1 ]
    end

    self.size = (start + level_count) - 1
    self.start = start
end

--- [SHARED AND MENU]
---
--- Merges the given `other` stack into this one, with the `other` stack's frames reversed before merging.
---
---@param other dreamwork.std.debug.Stack The stack to merge into this one.
function Stack:merge( other )
    return merge( self, table_reversed( other, other.size ) )
end

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
function Stack:capture( stack_level, head_skip, tail_skip, max_levels )
    local levels, level_count = debug_getstack( (stack_level or 2) + 1, "Slnf", head_skip, tail_skip, max_levels )
    local current_thread = coroutine_running()

    for i = 1, level_count, 1 do
        levels[ i ] = update_source( levels[ i ], current_thread )
    end

    merge( self, levels, level_count )
end

--- [SHARED AND MENU]
---
--- The class used to create new `debug.Stack` instances.
---
---@class dreamwork.std.debug.StackClass : dreamwork.std.Stack
---@field __parent dreamwork.std.StackClass
---@field __base dreamwork.std.debug.Stack
---@overload fun(): dreamwork.std.debug.Stack
debug.Stack = class.create( Stack )
