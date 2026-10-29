---@meta jit

--- [SHARED AND MENU]
---
--- The LuaJIT library which provides functions to control the JIT compiler.
---
--- [View documents](https://luajit.org/ext_jit.html)
---
---@version JIT
---@class jitlib
---@field version     string The full name of the LuaJIT version, e.g. `"LuaJIT 2.1.0-beta3"`.
---@field version_num integer The version of LuaJIT as a number, e.g. `20100` for `2.1.0`.
---@field os          'Windows'|'Linux'|'OSX'|'BSD'|'POSIX'|'Other' The target OS name.
---@field arch        'x86'|'x64'|'arm'|'arm64'|'arm64be'|'ppc'|'ppc64'|'ppc64le'|'mips'|'mipsel'|'mips64'|'mips64el'|string The target architecture name.
jit = {}

--- [SHARED AND MENU]
---
--- Turns the whole JIT compiler on (default) or enables JIT compilation for a function.
---
--- If `func` is a function, enables JIT compilation for it.
---
--- If `func` is `true`, enables JIT compilation for the function of the caller.
---
--- If `recursive` is `true`, all sub-functions of the function are affected too.
---
--- [View documents](https://luajit.org/ext_jit.html#jit_onoff)
---
---@overload fun(...):...
---@param func       function|boolean The function or `true` for the function of the caller.
---@param recursive? boolean `true` to affect all sub-functions too.
function jit.on(func, recursive)
end

--- [SHARED AND MENU]
---
--- Turns the whole JIT compiler off or disables JIT compilation for a function.
---
--- If `func` is a function, disables JIT compilation for it and flushes any already compiled code.
---
--- If `func` is `true`, disables JIT compilation for the function of the caller.
---
--- If `recursive` is `true`, all sub-functions of the function are affected too.
---
--- [View documents](https://luajit.org/ext_jit.html#jit_onoff)
---
---@overload fun(...):...
---@param func       function|boolean The function or `true` for the function of the caller.
---@param recursive? boolean `true` to affect all sub-functions too.
function jit.off(func, recursive)
end

--- [SHARED AND MENU]
---
--- Flushes the whole cache of compiled code, the compiled code of a function or a single trace.
---
--- If `func` is a function, flushes its compiled code.
---
--- If `func` is `true`, flushes compiled code of the function of the caller.
---
--- If `tr` (trace number) is given, flushes only this trace.
---
--- If `recursive` is `true`, all sub-functions of the function are affected too.
---
--- [View documents](https://luajit.org/ext_jit.html#jit_flush)
---
---@overload fun(...):...
---@overload fun(tr: jit.trace)
---@param func       function|boolean The function or `true` for the function of the caller.
---@param recursive? boolean `true` to affect all sub-functions too.
function jit.flush(func, recursive)
end

--- [SHARED AND MENU]
---
--- Returns the current status of the JIT compiler.
---
--- The first result is `true` or `false` if the JIT compiler is turned on or off,
--- the remaining results are strings with the CPU-specific features and enabled optimizations, e.g. `"SSE2"`, `"fold"`, `"cse"`.
---
--- [View documents](https://luajit.org/ext_jit.html#jit_status)
---
---@return boolean status `true` if the JIT compiler is turned on, `false` otherwise.
---@return string ... The CPU-specific features and enabled optimizations.
---@nodiscard
function jit.status()
end

--- [SHARED AND MENU]
---
--- Attaches a handler to the compiler pipeline event, or detaches it if `event` is omitted.
---
--- Undocumented and not stable LuaJIT API, used by `jit.v` and `jit.dump` modules.
---
---@param handler function The event handler.
---@param event? "bc" | "trace" | "record" | "texit" | string The event name, omit to detach the handler.
function jit.attach(handler, event)
end

--- [SHARED AND MENU]
---
--- The JIT compiler optimizations control.
---
--- [View documents](https://luajit.org/ext_jit.html#jit_opt)
---
---@class jitlib.opt
jit.opt = {}

--- [SHARED AND MENU]
---
--- Sets the JIT compiler optimization flags and parameters.
---
--- Flags: `"-O0"`..`"-O3"`, `"+fold"`, `"-dce"`, `"+loop"`, `"-abc"`, etc.
---
--- Parameters: `"maxtrace=1000"`, `"hotloop=56"`, `"maxmcode=8192"`, etc.
---
--- [View documents](https://luajit.org/running.html#opt_O)
---
---@param ... string The optimization flags and parameters.
function jit.opt.start(...)
end

return jit
