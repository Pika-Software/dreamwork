local glua_jit = jit

local jit_util = glua_jit.util or {}

---@type fun( func: function, position?: integer ): integer, integer
local util_funcbc = jit_util.funcbc

---@type fun( func: function, position?: integer ): jit.funcinfo.c | jit.funcinfo.lua
local util_funcinfo = jit_util.funcinfo

---@type fun( func: function, index?: integer ): any
local util_funck = jit_util.funck

---@type fun( func: function, index?: integer ): string | nil
local util_funcuvname = jit_util.funcuvname


--- [SHARED AND MENU]
---
--- The LuaJIT FFI library, allows calling external C functions and using C data structures from pure Lua code.
---
--- Available only if the server/client has access to it (e.g. via [HolyLib](https://holylib.raphaelit7.com/jit.getffi)), otherwise `std.ffi` is `nil`.
---
---@class dreamwork.std.ffi : ffilib

---@class dreamwork.std
---@field ffi dreamwork.std.ffi | nil
local std = dreamwork.std

local raw = std.raw
local raw_get = raw.get
local raw_type = raw.type
local raw_pairs = raw.pairs
local raw_tonumber = raw.tonumber

---@class dreamwork.std.debug
local debug = std.debug
local debug_fempty = debug.fempty
local debug_getfmain = debug.getfmain
local debug_getmetatable = debug.getmetatable

local error = std.error
local getmetatable = std.getmetatable

local debug_getinfo = debug.getinfo

-- fallback: bytecode and constants are not reachable without `jit.util`, so act as "out of range".
if util_funcbc == nil then
    util_funcbc = debug_fempty
end

if util_funck == nil then
    util_funck = debug_fempty
end

-- fallback: only fields that `debug.getinfo` can provide, the rest are zeroed, `position` is ignored.
if util_funcinfo == nil then

    function util_funcinfo( fn )
        local info = debug_getinfo( fn, "Su" )
        if info == nil then
            return {
                upvalues = 0
            }
        end

        if info.what == "C" then
            return {
                upvalues = info.nups or 0
            }
        end

        local linedefined = info.linedefined or 0

        return {
            linedefined = linedefined,
            lastlinedefined = info.lastlinedefined or 0,
            stackslots = 0,
            params = info.nparams or 0,
            bytecodes = 0,
            gcconsts = 0,
            nconsts = 0,
            upvalues = info.nups or 0,
            currentline = linedefined,
            isvararg = info.isvararg == true,
            children = false,
            source = info.source or "",
            loc = (info.short_src or "?") .. ":" .. linedefined
        }
    end

end

if util_funcuvname == nil then

    local debug_getupvalue = debug.getupvalue
    if debug_getupvalue == nil then
        util_funcuvname = debug_fempty
    else

        -- fallback: `debug.getupvalue` uses 1-based indices and returns `""` names for C functions.
        function util_funcuvname( fn, index )
            local info = debug_getinfo( fn, "S" )
            if info == nil or info.what == "C" then
                return nil
            end

            return (debug_getupvalue( fn, index + 1 ))
        end

    end

end

--- [SHARED AND MENU]
---
--- The jit library is a standard Lua library which provides functions to manipulate the JIT compiler.
---
--- It's a wrapper for the native jit library from LuaJIT.
---
---@class dreamwork.std.jit : jitlib
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
local jit = {}
std.jit = jit

jit.os = glua_jit.os or "unknown"
jit.arch = glua_jit.arch or "unknown"
jit.version = glua_jit.version or "unknown"

do

    ---@type integer
    local jit_version = glua_jit.version_num or 0
    jit.version_number = jit_version

    jit.edge = false

    if jit_version == 0 then
        jit.version_byte = 0
    elseif jit_version >= 20100 then
        jit.version_byte = 2
        jit.edge = true
    else
        jit.version_byte = 1
    end

end

jit.on = glua_jit.on or debug_fempty
jit.off = glua_jit.off or debug_fempty
jit.status = glua_jit.status or function() return false end

---@diagnostic disable-next-line: deprecated, undefined-field
jit.attach = glua_jit.attach or debug_fempty
jit.flush = glua_jit.flush or debug_fempty

if glua_jit.opt == nil then
    jit.options = debug_fempty
else
    jit.options = glua_jit.opt.start or debug_fempty
end

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
function jit.getfinfo( location, position )
    if raw_type( location ) == "number" then
        ---@cast location integer

        local main_fn = debug_getfmain( location + 1 )
        if main_fn == nil then
            error( "function not found", 2 )
        end

        location = main_fn
    end

    ---@cast location function

    return util_funcinfo( location, position )
end

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
function jit.getfbc( location, position )
    if raw_type( location ) == "number" then
        ---@cast location integer

        local main_fn = debug_getfmain( location + 1 )
        if main_fn == nil then
            error( "function not found", 2 )
        end

        location = main_fn
    end

    ---@cast location function

    return util_funcbc( location, position )
end

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
function jit.getfconst( location, position )
    if raw_type( location ) == "number" then
        ---@cast location integer

        local main_fn = debug_getfmain( location + 1 )
        if main_fn == nil then
            error( "function not found", 2 )
        end

        location = main_fn
    end

    ---@cast location function

    if location == nil then
        error( "function not found", 2 )
    end

    return util_funck( location, position )
end

--- [SHARED AND MENU]
---
--- Returns the name of the upvalue at the given index of the given Lua function.
---
--- Returns `nil` if the index is out of range.
---
---@param location function | integer The function or the stack level to get the main function from.
---@param position integer The index of the upvalue, starting from `0`.
---@return string | nil name The name of the upvalue.
function jit.getfupvalue( location, position )
    if raw_type( location ) == "number" then
        ---@cast location integer

        local main_fn = debug_getfmain( location + 1 )
        if main_fn == nil then
            error( "function not found", 2 )
        end

        location = main_fn
    end

    ---@cast location function

    if location == nil then
        error( "function not found", 2 )
    end

    return util_funcuvname( location, position )
end

if jit_util.funcinfo == nil then

    --- [SHARED AND MENU]
    ---
    --- Checks if the given function is a FFI function.
    ---
    --- Fallback, `jit.util` is not available, so any C function is treated as a fast function.
    ---
    ---@param fn function The function to check.
    ---@return boolean is_ffi `true` if the function is a FFI function, `false` otherwise.
    function jit.isFFI( fn )
        local info = debug_getinfo( fn, "S" )
        return info ~= nil and info.what == "C"
    end

else

    --- [SHARED AND MENU]
    ---
    --- Checks if the given function is a FFI function.
    ---
    ---@param fn function The function to check.
    ---@return boolean is_ffi `true` if the function is a FFI function, `false` otherwise.
    function jit.isFFI( fn )
        local info = util_funcinfo( fn )
        return info ~= nil and info.ffid ~= nil
    end

end

-- https://holylib.raphaelit7.com/jit.getffi
do

    local fn = glua_jit.getffi
    if fn ~= nil then
        ---@type table
        local ffi_copy = {}

        ---@type ffilib
        local ffi = fn()

        local ffi_metatype = ffi.metatype
        local ffi_typeof = ffi.typeof

        for key, value in raw_pairs( ffi ) do
            ffi_copy[ key ] = value
        end

        ---@type table<integer, metatable>
        local ctype_metatables = {}

        ---@param ct        ffi.ct*
        ---@param metatable metatable
        ---@return ffi.ctype* ctype
        function ffi_copy.metatype( ct, metatable )
            local ctype = ffi_metatype( ct, metatable )
            ctype_metatables[ raw_tonumber( ctype ) ] = metatable
            return ctype
        end

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
        function debug.getmetatable( object )
            if raw_type( object ) == "cdata" then
                return ctype_metatables[ raw_tonumber( ffi_typeof( object ) ) ]
            end

            return debug_getmetatable( object )
        end

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
        function std.getmetatable( object )
            local metatable = getmetatable( object )
            if metatable == "ffi" then
                local ctype_metatable = ctype_metatables[ raw_tonumber( ffi_typeof( object ) ) ]
                if ctype_metatable == nil then
                    return nil
                end

                return raw_get( ctype_metatable, "__metatable" ) or ctype_metatable
            end

            ---@cast metatable metatable | table | nil
            return metatable
        end

        std.ffi = ffi_copy
    end

end
