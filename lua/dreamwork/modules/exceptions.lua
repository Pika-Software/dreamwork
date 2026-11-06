---@class dreamwork
local dreamwork = dreamwork

local dreamwork_engine = dreamwork.engine
local engine_hook = dreamwork_engine.hook
local hook_call = engine_hook.call

---@class dreamwork.std
local std = dreamwork.std

local gc = std.gc

local raw = std.raw
local raw_select = raw.select
local raw_tostring = raw.tostring

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

local pcall = std.pcall

---@class dreamwork.exceptions
local exceptions = dreamwork.exceptions

-- created once and kept across loader reloads, so functions hidden by persistent engine modules stay hidden
if exceptions == nil then

    --- [SHARED AND MENU]
    ---
    --- Core of the error pipeline: call stack capturing, hidden frames, `xpcall` handlers
    --- and reporting errors to the `dreamwork.lua.error` engine hook.
    ---
    --- User-facing functions (`toError`, `try`, `error`, `errorf`, `warn`, `assert`) live in `std`.
    ---
    ---@class dreamwork.exceptions
    ---@field Sentinel string Message handed back to the engine once dreamwork has displayed the error itself.
    exceptions = {
        Sentinel = "The original error message was caught by dreamwork, see above for details about the error."
    }

    dreamwork.exceptions = exceptions


    --- Survives loader reloads together with this module, so functions hidden by persistent engine modules stay hidden.
    ---
    --- Weak keys, reloaded modules register new functions and the old ones must not be kept alive.
    ---
    ---@type table<function, (true | nil)>
    local hidden_functions = {}
    gc.setTableRules( hidden_functions, true, false )

    --- [SHARED AND MENU]
    ---
    --- Hides the given functions from error call stacks.
    ---
    --- Use it for internal dispatchers and wrappers (hook runners, timer callers, ...)
    --- whose frames carry no useful information for whoever reads the error.
    ---
    ---@param ... function The functions to hide.
    function exceptions.hide( ... )
        for i = 1, raw_select( "#", ... ), 1 do
            hidden_functions[ raw_select( i, ... ) ] = true
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Shows the given functions in error call stacks again, undoing `hide`.
    ---
    ---@param ... function The functions to show.
    function exceptions.show( ... )
        for i = 1, raw_select( "#", ... ), 1 do
            hidden_functions[ raw_select( i, ... ) ] = nil
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Checks whether the frame belongs to a hidden function and is left out of error call stacks.
    ---
    --- Pass it to `exceptions.Stack:filter` to clean up a stack captured by hand.
    ---
    ---@param frame dreamwork.exceptions.StackLevel | debuginfo The frame to check.
    ---@return boolean is_hidden
    ---@nodiscard
    function exceptions.isHiddenFrame( frame )
        local fn = frame.func
        return not (fn == nil or hidden_functions[ fn ] == nil)
    end

    --- [SHARED AND MENU]
    ---
    --- Checks whether the function is hidden from error call stacks.
    ---
    --- Use it when there is only a function and no stack frame to check.
    ---
    ---@param fn function The function to check.
    ---@return boolean is_hidden
    ---@nodiscard
    function exceptions.isHiddenFunction( fn )
        return hidden_functions[ fn ] ~= nil
    end

    --- [SHARED AND MENU]
    ---
    --- Passes the error to the `dreamwork.lua.error` handlers, which display it.
    ---
    ---@param error_object dreamwork.std.Error The error to report.
    ---@return any result The value returned by the handlers.
    function exceptions.report( error_object )
        return hook_call( "dreamwork.lua.error", error_object )
    end

    --- [SHARED AND MENU]
    ---
    --- Converts the value into a string without ever raising an error.
    ---
    --- Safe to use inside error handlers, where a second error would replace the original one.
    ---
    ---@param value any The value to convert.
    ---@return string str The string, or a placeholder if `tostring` failed.
    ---@nodiscard
    function exceptions.tostring( value )
        local success, result = pcall( raw_tostring, value )
        return success and result or "<value that cannot be converted to string>"
    end

end

-- its parent `std.Stack` is recreated on every loader reload,
-- so the stack class is defined again on every load instead of being kept with the module above

--- [SHARED AND MENU]
---
--- A specialized `dreamwork.std.Stack` that holds `dreamwork.exceptions.StackLevel`
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
---@class dreamwork.exceptions.Stack : dreamwork.std.Stack
---@field __class dreamwork.exceptions.StackClass
---@field __parent dreamwork.std.Stack
---@field push fun( self: dreamwork.exceptions.Stack, info: dreamwork.exceptions.StackLevel ): integer
---@field pop fun( self: dreamwork.exceptions.Stack ): dreamwork.exceptions.StackLevel | nil
---@field peek fun( self: dreamwork.exceptions.Stack ): dreamwork.exceptions.StackLevel | nil
---@field size integer The size of the stack. **Read-only**
---@field start integer The index of the first frame belonging to the most recent `capture` call, i.e. the "hop start". Used to bound how far back coalescing needs to compare.
local Stack = class.base( "exceptions.Stack", false, std.Stack )

---@protected
function Stack:__init()
    self.start = 1 -- hop start
    self.size = 0
end

---@return dreamwork.exceptions.Stack
---@protected
function Stack:__copy()
    ---@type dreamwork.exceptions.Stack
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
---@class dreamwork.exceptions.StackLevel : debuginfo
---@field thread thread | nil Thread of call, available only when called inside a coroutine.

---@param stack_level debuginfo
---@param current_thread thread | nil
---@return dreamwork.exceptions.StackLevel stack_level
local function update_source( stack_level, current_thread )
    ---@cast stack_level dreamwork.exceptions.StackLevel
    local source = stack_level.source

    if source ~= nil and source ~= "=[C]" then
        ---@type string
        local relative_path = string_match( source, "^@?.-(lua/.*)$", 1 ) or source
        stack_level.source = "/game/" .. (string_match( relative_path, "^.-([%w_]+/gamemode/.*)$", 1 ) or relative_path)
    end

    stack_level.thread = current_thread
    return stack_level
end

---@param self dreamwork.exceptions.Stack
---@param levels debuginfo[]
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
---@param other dreamwork.exceptions.Stack The stack to merge into this one.
function Stack:merge( other )
    return merge( self, table_reversed( other, other.size ) )
end

--- [SHARED AND MENU]
---
--- Removes every item for which `predicate` returns `true`, keeping the order of the remaining items.
---
---@param predicate fun( item: dreamwork.exceptions.Stack ): boolean The function that decides whether a frame is removed.
function Stack:filter( predicate )
    self.__parent.filter( self, predicate )
    self.start = 1 -- hop start
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
---@param stack_level integer?  How many levels to skip to reach the caller (same meaning as the `level` argument of `debug.getstack`/`debug.getinfo`). Defaults to `2`, i.e. the function calling `capture`.
---@param head_skip integer?    Constant number of frames to drop from the innermost end of the capture (e.g. `1` to drop the bare `error` C frame).
---@param tail_skip integer?    Constant number of frames to drop from the outermost end of the capture (e.g. to drop your own `xpcall`/wrapper frames).
---@param max_levels integer?   Maximum number of stack frames to read, counted from the innermost frame (after `head_skip` is applied). Stack walking stops as soon as this many frames have been captured, so frames further up (older/outer) are never read at all. `nil`/omitted means no limit.
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
--- The class used to create new `exceptions.Stack` instances.
---
---@class dreamwork.exceptions.StackClass : dreamwork.std.Stack, dreamwork.std.Class
---@field __parent dreamwork.std.StackClass
---@field __base dreamwork.exceptions.Stack
---@overload fun(): dreamwork.exceptions.Stack
exceptions.Stack = class.create( Stack )
