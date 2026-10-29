---@meta _

--- [SHARED AND MENU]
---
--- Library containing functions for working with raw data. (ignoring metatables)
---
---@class raw
raw = {}

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
