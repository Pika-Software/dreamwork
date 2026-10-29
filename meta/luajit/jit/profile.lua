---@meta jit.profile


--- [SHARED AND MENU]
---
--- The LuaJIT built-in low-overhead statistical profiler.
---
--- [View documents](https://luajit.org/ext_profile.html)
---
local profile = {}

--- [SHARED AND MENU]
---
--- The VM state of a profiler sample.
---
--- * `"N"` - Native (compiled) code.
--- * `"I"` - Interpreted code.
--- * `"C"` - C code.
--- * `"G"` - Garbage collector.
--- * `"J"` - JIT compiler.
---
---@alias jit.profile.vmstate "N" | "I" | "C" | "G" | "J"

--- [SHARED AND MENU]
---
--- Starts the profiler.
---
--- The `mode` string is a combination of options:
---
--- * `"f"` - Profile with precision down to the function level.
--- * `"l"` - Profile with precision down to the line level.
--- * `"i<number>"` - Sampling interval in milliseconds (default `10`ms).
---
--- The `func` callback is called with the coroutine that was sampled,
--- the number of samples taken since the last call and the VM state of the sample.
---
--- The callback can call `profile.dumpstack` to get the stack of the sampled coroutine.
---
--- [View documents](https://luajit.org/ext_profile.html#profile_start)
---
---@param mode string The profiling mode, e.g. `"fi1"` or `"l"`.
---@param func fun( L: thread, samples: integer, vmstate: jit.profile.vmstate ) The callback that is called for every sample.
function profile.start( mode, func ) end

--- [SHARED AND MENU]
---
--- Stops the profiler.
---
--- [View documents](https://luajit.org/ext_profile.html#profile_stop)
---
function profile.stop() end

--- [SHARED AND MENU]
---
--- Dumps the stack of the given coroutine (or the current one) into a string.
---
--- The `fmt` string is a combination of options:
---
--- * `"p"` - Preserve the full path for module names, otherwise only the file name is used.
--- * `"f"` - Dump the function name if it can be derived, otherwise use `module:line`.
--- * `"F"` - Same as `"f"`, but dump `module:name`.
--- * `"l"` - Dump `module:line`.
--- * `"Z"` - Zap the following characters for the last dumped frame.
--- * All other characters are added verbatim to the output string.
---
--- The `depth` is the number of stack frames to dump, a negative number dumps the frames in inverse order.
---
--- [View documents](https://luajit.org/ext_profile.html#profile_dump)
---
---@overload fun( th: thread, fmt: string, depth: integer ): string
---@param fmt string The format of the stack dump, e.g. `"f\n"` or `"l;"`.
---@param depth integer The number of stack frames to dump.
---@return string stack The dumped stack.
function profile.dumpstack( fmt, depth ) end

return profile
