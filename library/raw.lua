---@meta _

--- [SHARED AND MENU]
---
--- The raw library, low-level Lua primitives and table access that skips metamethods.
---
--- Holds bootstrap copies of core builtins (`assert`, `error`, `tostring`,
--- `tonumber`, `ipairs`, `pairs`, `print`, `select`) plus true raw accessors:
--- `get` / `set` / `len` / `equal` (`rawget` / `rawset` / `rawlen` / `rawequal`),
--- and the `inext` / `next` iterators. Also hosts `raw.bit`, the native 32-bit
--- integer bit library used under `bit`.
---
---@class raw
raw = {}

raw.assert = assert

raw.error = error

raw.tostring = tostring

raw.tonumber = tonumber

raw.ipairs = ipairs

raw.pairs = pairs

raw.equal = rawequal

raw.get = rawget

raw.set = rawset

raw.print = print

--- [SHARED AND MENU]
---
--- Returns the length of the object `value`, without invoking the `__len` metamethod.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-rawlen)
---
---@param value table | string | any
---@return integer length
---@nodiscard
function raw.len(value) end
