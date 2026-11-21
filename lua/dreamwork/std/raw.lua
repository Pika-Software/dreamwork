---@class dreamwork.std
local std = dreamwork.std

--- [SHARED AND MENU]
---
--- The raw library.
---
--- Low-level Lua primitives and table access that skip metamethods.
---
--- What it holds:
--- * Bootstrap builtins — `assert`, `error`, `tostring`, `tonumber`, …
--- * Raw accessors — `get`, `set`, `len`, `equal`
--- * Iterators — `inext`, `next`
--- * `raw.bit` — native 32-bit integer bit ops used by `std.bit`
---
--- ```lua
--- local obj = setmetatable( { hidden = 1 }, {
---     __index = function()
---         return "meta"
---     end
--- } )
---
--- print( raw.get( obj, "hidden" ) ) -- 1
--- print( obj.missing ) -- meta
--- ```
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
