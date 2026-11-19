---@class dreamwork.std
local std = dreamwork.std

--- [SHARED AND MENU]
---
--- The raw library, low-level Lua primitives and table access that skips metamethods.
---
--- Holds bootstrap copies of core builtins (`assert`, `error`, `tostring`,
--- `tonumber`, `ipairs`, `pairs`, `print`, `select`) plus true raw accessors:
--- `get` / `set` / `len` / `equal` (`rawget` / `rawset` / `rawlen` / `rawequal`),
--- and the `inext` / `next` iterators. Also hosts `raw.bit`, the native 32-bit
--- integer bit library used under `std.bit`.
---
---@class dreamwork.std.raw
local raw = {
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
