---@meta _

--- [SHARED AND MENU]
---
--- The LuaJIT FFI library, allows calling external C functions and using C data structures from pure Lua code.
---
--- Available only if the server/client has access to it (e.g. via [HolyLib](https://holylib.raphaelit7.com/jit.getffi)), otherwise `ffi` is `nil`.
---
--- Some builds (e.g. HolyLib's LuaJIT) sandbox it: `string`, `copy`, `fill` and `load` are removed
--- and `ffi.C` symbol lookups throw, see `ffi.SANDBOXED`.
--- `string`, `copy` and `fill` are rebuilt on top of `string.buffer` when it is available.
---
---@class ffilib
---@field SANDBOXED boolean `true` if the FFI is sandboxed: `C` and `load` are unavailable, `string`, `copy` and `fill` are emulated (or `nil` without `string.buffer`).

---@type ffilib | nil
ffi = nil

--- [SHARED AND MENU]
---
--- The jit library is a standard Lua library which provides functions to manipulate the JIT compiler.
---
--- It's a wrapper for the native jit library from LuaJIT.
---
---@class jitlib
---@field os "Windows" | "Linux" | "OSX" | "BSD" | "POSIX" | "Other" | "unknown" | string The target OS name, `"unknown"` if not available.
---@field arch "x86" | "x64" | "arm" | "arm64" | "arm64be" | "ppc" | "ppc64" | "ppc64le" | "mips" | "mipsel" | "mips64" | "mips64el" | "unknown" | string The target architecture name, `"unknown"` if not available.
---@field version string | "unknown" The full name of the JIT compiler version, e.g. `"LuaJIT 2.1.0-beta3"`, `"unknown"` if not available.
---@field version_number integer | 0 The version of the JIT compiler as a number, e.g. `20100` for `2.1.0`, `0` if not available.
---@field version_byte integer | 0 The major version of the JIT compiler: `1` for LuaJIT 2.0, `2` for LuaJIT 2.1+, `0` if unknown.
---@field edge boolean `true` if the JIT compiler is an edge version (LuaJIT 2.1+), `false` otherwise.
--- [SHARED AND MENU]
---
--- Sets the JIT compiler optimization flags and parameters.
---
--- It's an alias for `jit.opt.start`.
---
--- Flags: `"-O0"`..`"-O3"`, `"+fold"`, `"-dce"`, `"+loop"`, `"-abc"`, etc.
---
--- Parameters: `"maxtrace=1000"`, `"hotloop=56"`, `"maxmcode=8192"`, etc.
---
--- [View documents](https://luajit.org/running.html#opt_O)
---
---@field options fun( ...: string )
jit = {}

---@type integer
jit.version_number = nil

jit.edge = false

jit.version_byte = 0

jit.options = debug.fempty

--- [SHARED AND MENU]
---
--- Returns the LuaJIT internal information about the given function.
---
--- For Lua functions returns `jit.funcinfo.lua` (lines, stack slots, params, bytecodes count, constants, source, etc.),
--- if `position` is given, `currentline` and `loc` will be related to the bytecode at this position.
---
--- For C functions returns `jit.funcinfo.c` (address, upvalues count and `ffid` for builtin fast functions).
---
---@param location function | integer The function or the stack level to get the main function from.
---@param position? integer The bytecode position (program counter) inside the function.
---@return jit.funcinfo.c | jit.funcinfo.lua info The function information.
---@nodiscard
function jit.getfinfo(location, position) end

--- [SHARED AND MENU]
---
--- Returns the bytecode instruction at the given position of the given Lua function.
---
--- Returns `nil` if the position is out of range or the function is not a Lua function.
---
---@param location function | integer The function or the stack level to get the main function from.
---@param position integer The bytecode position (program counter), starting from `0`.
---@return integer | nil ins The raw 32-bit bytecode instruction.
---@return integer | nil mode The opcode mode flags of the instruction.
---@nodiscard
function jit.getfbc(location, position) end

--- [SHARED AND MENU]
---
--- Returns the constant at the given index of the given Lua function.
---
--- Non-negative indices are for number constants, negative indices are for GC constants (strings, tables, child prototypes, etc.).
---
--- Returns `nil` if the index is out of range.
---
---@param location function | integer The function or the stack level to get the main function from.
---@param position integer The index of the constant.
---@return any | nil value The constant value.
---@nodiscard
function jit.getfconst(location, position) end

--- [SHARED AND MENU]
---
--- Returns the name of the upvalue at the given index of the given Lua function.
---
--- Returns `nil` if the index is out of range.
---
---@param location function | integer The function or the stack level to get the main function from.
---@param position integer The index of the upvalue, starting from `0`.
---@return string | nil name The name of the upvalue.
---@nodiscard
function jit.getfupvalue(location, position) end

--- [SHARED AND MENU]
---
--- Checks if the given function is a FFI function.
---
--- Fallback, `jit.util` is not available, so any C function is treated as a fast function.
---
---@param fn function The function to check.
---@return boolean is_ffi `true` if the function is a FFI function, `false` otherwise.
---@nodiscard
function jit.isFFI(fn) end

--- [SHARED AND MENU]
---
--- Checks if the given function is a FFI function.
---
---@param fn function The function to check.
---@return boolean is_ffi `true` if the function is a FFI function, `false` otherwise.
---@nodiscard
function jit.isFFI(fn) end

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

--- [SHARED AND MENU]
---
--- If object does not have a metatable, returns `nil`.
---
--- Otherwise, if the object's metatable has a `__metatable` field, returns the associated value.
---
--- Otherwise, returns the metatable of the given object.
---
--- Use `debug.getmetatable` to get the real metatable regardless of a `__metatable` field.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-getmetatable)
---
---@param object any The value to get the metatable of.
---@return metatable | table | nil metatable The metatable (or its `__metatable` value), or `nil` if there is none.
---@nodiscard
function getmetatable(object) end

---@type table
ffi = nil
