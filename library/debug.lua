---@meta _

--- [SHARED AND MENU]
---
--- The debug library is intended to help you debug your scripts,
--- however it also has several other powerful uses.
---
---@class debuglib
--- [SHARED AND MENU]
---
--- Just empty function, do nothing.
---
--- Sometimes makes jit happy :>
---
---@field fempty fun()
--- [SHARED AND MENU]
---
--- Sets the metatable for the given value to the given table (which can be `nil`).
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.setmetatable)
---
---@field setmetatable fun( object: any, metatable: ( metatable | nil ) )
debug = {}

debug.newproxy = newproxy

function debug.fempty() end

--- [SHARED AND MENU]
---
--- Calls the given function or object with the given arguments.
---
---@param f function | any The function or object to call.
---@param ... any The arguments to pass to the function or object.
---@return any ... The result of execution.
function debug.fcall(f, ...) end

--- [SHARED AND MENU]
---
--- Returns all upvalues of the given function as a table, keyed by upvalue name.
---
--- If the function is a C function (or otherwise has no debug info), an empty
--- table and a count of `0` are returned.
---
---@param fn function The function to get upvalues from.
---@return table<string, any> values A table mapping each upvalue's name to its current value.
---@return integer value_count The number of upvalues found.
---@nodiscard
function debug.getupvalues(fn) end

--- [SHARED AND MENU]
---
--- Returns all available local variables at the given stack level (and, optionally,
--- in the given thread/coroutine) as a table keyed by variable name.
---
---@param stack_level? integer The stack level to inspect, relative to the caller (defaults to the immediate caller's frame). Cannot be negative.
---@param thread? thread The thread/coroutine to inspect. If omitted, the current thread is used.
---@return table<string, any> values A table mapping each local variable's name to its current value.
---@return integer value_count The number of locals found.
---@nodiscard
function debug.getlocals(stack_level, thread) end

--- [SHARED AND MENU]
---
--- Returns the function at the given stack level.
---
---@param level integer The stack level.
---@return function | nil The function at the given level, or `nil` if the level is invalid.
---@nodiscard
function debug.getf(level) end

--- [SHARED AND MENU]
---
--- Attempts to determine the name and kind of a function,
--- the same way the `n` option of the standard `debug.getinfo` does.
---
--- `location` can be either a function reference or a stack level
--- (an integer, where `1` is the function that called `getfname`).
---
--- Since Lua functions have no inherent name, this works by inspecting
--- how the function was called or accessed - e.g. as a global, a local variable,
--- a table field, a method, or an upvalue - and can fail to find anything,
--- in which case both results are `nil`.
---
---@param location? integer The function or stack level.
---@return string | nil name The name of the function, or `nil` if unknown.
---@return "global" | "local" | "method" | "field" | "upvalue" | nil name_what The kind of the function, or `nil` if unknown.
---@nodiscard
function debug.getfname(location) end

--- [SHARED AND MENU]
---
--- Returns the path to the file that the function is defined in.
---
---@param location function | integer The function or stack level to get the path from.
---@return string | nil file_path The file path or `nil` if not found.
---@nodiscard
function debug.getfsource(location) end

--- [SHARED AND MENU]
---
--- Returns the main function of the current stack.
---
---@param stack_level? integer The stack `stack_level` to get the main function from.
---@return function | nil main_fn The main function or `nil` if not found.
---@nodiscard
function debug.getfmain(stack_level) end

--- [SHARED AND MENU]
---
--- Captures the current call stack, starting at `stack_level` relative to the caller
--- of this function, and returns it as a list of debug info tables.
---
---@param stack_level? integer The level to start capturing from, where `0` is the function that called `getstackinfo`. Default is `0`.
---@param what? infowhat A string of `debug.getinfo`-style flags selecting which fields to populate per frame. Default is `"Snluf"`.
---@param head_skip? integer Number of extra frames to skip from the top ( nearest the caller ) before capturing begins. Default is `0`.
---@param tail_skip? integer Number of frames to drop from the bottom ( nearest the root ) of the captured stack after capturing ends. Default is `0`.
---@param max_levels? integer Maximum number of frames to read (after `head_skip` is applied). Stack walking stops as soon as this many frames have been collected, so no `debug.getinfo` call is made beyond that point. `tail_skip` is still applied afterward to this (already capped) set. `nil`/`0` means no limit.
---@return debuginfo[] stack A list of debug info tables, one per captured stack frame, ordered from `stack_level` outward.
---@return integer stack_size The number of entries in `stack` ( equivalent to `#stack` ).
---@nodiscard
function debug.getstack(stack_level, what, head_skip, tail_skip, max_levels) end

--- [SHARED AND MENU]
---
--- Checks if the given function or stack level is a C function.
---
---@param location integer | function The function or stack level.
---@return boolean iscf `true` if the function is a C function, `false` otherwise.
---@nodiscard
function debug.iscf(location) end

--- [SHARED AND MENU]
---
--- Checks whether any of the given functions is on the call stack, starting from
--- `stack_level` and walking outward all the way to the bottom of the stack.
---
--- Levels follow the same convention as `debug.getinfo`, relative to the function that
--- calls `debug.calledby`: level `1` is that function itself, level `2` is whoever called
--- it, and so on. Levels below `1` are treated as `1`, so the check always includes at
--- least the calling function. This function's own stack frame is skipped automatically.
---
--- Because the whole remaining stack is scanned, a `true` result means "one of these
--- functions is somewhere at or above `stack_level`", not that it is exactly at that
--- level. To test a single level, use `debug.getinfo` directly.
---
--- Only functions that are actually on the stack are seen. Tail calls replace their
--- caller's frame, so a function that was tail-called away won't be found.
---
--- Returns `false` if no functions are given.
---
--- ```lua
--- local function guarded()
---     -- true if `guarded` was reached through `handler` at any depth
---     return debug.calledby( 1, handler )
--- end
--- ```
---
---@param stack_level integer The stack level to start checking from (`1` = the function calling `calledby`). Values below `1` are treated as `1`.
---@param ... function The functions to look for on the call stack.
---@return boolean result `true` if any of the given functions is on the stack at or above `stack_level`, `false` otherwise.
---@nodiscard
function debug.calledby(stack_level, ...) end

--- [SHARED AND MENU]
---
--- Returns the registry table.
---
function debug.getregistry() end

--- [SHARED AND MENU]
---
--- Sets registry table.
---
--- **ATTENTION**
---
--- This function is extremly dangerous,
--- only reason why this exists is fact
--- that `getregistry` originally broken by cockpunch
--- and i cannot set locals over debug,
--- so only way to implement 3rd party moudles support
--- is implement this function :c
---
---@param tbl table
function debug.setregistry(tbl) end

--- [SHARED AND MENU]
---
--- Returns the metatable of the given name or `nil` if not found.
---
---@param name string The name of the metatable.
---@return metatable | nil meta The metatable.
---@nodiscard
function debug.findmetatable(name) end

--- [SHARED AND MENU]
---
--- Registers the metatable of the given name and table.
---
---@param name string The name of the metatable.
---@param tbl metatable The metatable to register.
---@param do_full_register? boolean `true`, the metatable will be registered, `false` otherwise.
---@return integer meta_id The ID of the metatable or `-1` if not fully registered.
function debug.registermetatable(name, tbl, do_full_register) end

--- [SHARED AND MENU]
---
---
---@param name string The name of the metatable.
---@return metatable metatable The metatable.
function debug.initmetatable(name) end

--- [SHARED AND MENU]
---
--- Returns the metatable of the given value, or `nil` if it doesn't have one.
---
--- Unlike the standard `getmetatable`, this ignores the `__metatable` field, so it can
--- reach metatables that are protected from normal code.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.getmetatable)
---
---@param object any The value to get the metatable of.
---@return metatable | nil metatable The metatable of `object`, or `nil` if it has none.
---@nodiscard
function debug.getmetatable(object) end
