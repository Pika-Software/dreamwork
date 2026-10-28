---@class dreamwork.std
local std = dreamwork.std

--- [SHARED AND MENU]
---
--- Library containing functions for working with raw data. (ignoring metatables)
---
---@class dreamwork.std.raw
local raw = std.raw

if raw == nil then
    ---@class dreamwork.std.raw
    raw = {
        assert = assert,
        error = error,

        tostring = tostring,
        tonumber = tonumber,

        ipairs = ipairs,
        pairs = pairs,

        equal = rawequal,

        get = rawget,
        set = rawset,
        len = rawlen,

        print = print
    }

    std.raw = raw
end

if raw.len == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the length of the object `value`, without invoking the `__len` metamethod.
    ---
    --- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-rawlen)
    ---
    ---@param value table | string | any
    ---@return integer length
    ---@nodiscard
    function raw.len( value )
        return #value
    end

end

if raw.inext == nil or raw.next == nil then
    local dummy_table = {}

    if raw.inext == nil then
        raw.inext = raw.ipairs( dummy_table )
    end

    if raw.next == nil then
        raw.next = next or raw.pairs( dummy_table )
    end

    dummy_table = nil
end

raw.select = raw.select or select
