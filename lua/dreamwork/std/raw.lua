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

raw.print = print
raw.select = select
raw.tostring = tostring
