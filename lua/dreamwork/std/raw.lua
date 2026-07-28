local ipairs = ipairs
local pairs = pairs

---@class dreamwork.std
local std = dreamwork.std

--- [SHARED AND MENU]
---
--- Library containing functions for working with raw data. (ignoring metatables)
---@class dreamwork.std.raw
local raw = {}
std.raw = raw

raw.assert = assert
raw.print = print

raw.tostring = tostring
raw.tonumber = tonumber
raw.error = error

raw.ipairs = ipairs
raw.pairs = pairs

raw.equal = rawequal

raw.get = rawget
raw.set = rawset
raw.len = rawlen

if raw.len == nil then

    function raw.len( value )
        return #value
    end

end

do

    local dummy_table = {}

    raw.inext = ipairs( dummy_table )
    raw.next = next or pairs( dummy_table )

    dummy_table = nil

end

--- [SHARED AND MENU]
---
--- If `index` is a number, returns all arguments after argument number `index`;
---
--- a negative number indexes from the end (`-1` is the last argument).
---
--- Otherwise, `index` must be the string `"#"`, and `select` returns the total number of extra arguments it received.
---
--- [View documents](http://www.lua.org/manual/5.4/manual.html#pdf-select)
---
---@overload fun( parameter: "#", ...: any ): integer
---@overload fun( parameter: integer, ...: any ): ...: any
raw.select = select
