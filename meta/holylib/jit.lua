---@meta holylib.jit

---@version JIT
---@class jitlib
jit = {}

--- [SHARED AND MENU]
---
--- If ffi is enabled in the config, then this will return a valid table, else it will return nothing.
---
---@version JIT
---@return ffilib
function jit.getffi() end

--- [SHARED AND MENU]
---
--- LuaJIT's default require function, this function does not exist when `ffi` is disabled.
---
---@param name string The library to load.
---@return table | nil module
---@deprecated
function jit.require( name ) end
