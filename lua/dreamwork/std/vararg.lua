---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_select = raw.select

local math = std.math
local math_relative = math.relative
local math_min, math_max = math.min, math.max

local table = std.table
local table_unpack = table.unpack

--- [SHARED AND MENU]
---
--- Provides utility functions for selecting, accessing, modifying, slicing,
--- packing, and unpacking variable-length argument lists.
---
---@class dreamwork.std.vararg
local vararg = {}
std.vararg = vararg

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
vararg.select = raw_select

--- [SHARED AND MENU]
---
--- Returns the value at the specified argument `index`.
---
--- A positive index starts at `1`.
---
--- A negative index starts from the end, where `-1` is the last argument.
---
--- [View documents](http://www.lua.org/manual/5.4/manual.html#pdf-select)
---
---@param index integer The index of the value to retrieve.
---@param ... any The argument list to retrieve the value from.
---@return any value The value at `index`.
function vararg.get( index, ... )
    return (raw_select( index, ... ))
end

do

    ---@param index integer
    ---@param value any
    ---@param ... any
    ---@return any ...
    local function set( index, value, ... )
        if index == 0 then
            return ...
        elseif index == 1 then
            return value, raw_select( 2, ... )
        elseif index == 2 then
            return (...), value, raw_select( 3, ... )
        else
            return (...), set( index - 1, value, raw_select( 2, ... ) )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Sets the value at `index` with `value` in the argument list.
    ---
    --- If `index` is out of bounds, the argument list is returned unchanged.
    ---
    --- A positive index starts at `1`.
    ---
    --- A negative index starts from the end, where `-1` is the last argument.
    ---
    ---@param index integer The index at which to replace the value.
    ---@param value any The value to set.
    ---@param ... any The argument list to modify.
    ---@return any ... The argument list with the value at `index` replaced.
    function vararg.set( index, value, ... )
        local count = raw_select( "#", ... )

        if index < 0 then
            index = math_max( 0, (count + index) + 1 )
            if index > count then return ... end
        end

        if index == 0 then
            return ...
        elseif index == 1 then
            return value, raw_select( 2, ... )
        else
            return set( index, value, ... )
        end
    end

end

do

    ---@param length integer
    ---@param ... any
    ---@return any ...
    local function slice( length, ... )
        length = length - 1

        if length == 0 then
            return (...)
        else
            return (...), slice( length, raw_select( 2, ... ) )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Returns a slice of the argument list between `start_position` and
    --- `end_position`, inclusive.
    ---
    --- Positive positions start at `1`.
    ---
    --- Negative positions start from the end, where `-1` is the last argument.
    ---
    --- If `start_position` is omitted, `1` is used.
    ---
    --- If `end_position` is omitted, the last argument is used.
    ---
    --- Positions outside the argument list are clamped to its bounds.
    ---
    ---@param start_position? integer The first position to include.
    ---@param end_position? integer The last position to include.
    ---@param ... any The argument list to slice.
    ---@return any ... The selected portion of the argument list.
    function vararg.slice( start_position, end_position, ... )
        local count = raw_select( "#", ... )
        if count == 0 then return end

        if start_position == nil then
            start_position = 1
        elseif start_position < 0 then
            start_position = math_relative( start_position, count )
        else
            start_position = math_min( start_position, count )
        end

        if end_position == nil then
            end_position = count
        elseif end_position < 0 then
            end_position = math_relative( end_position, count )
        else
            end_position = math_min( end_position, count )
        end

        local length = math_max( 0, (end_position - start_position) + 1 )
        if length == 0 then
            return
        elseif length == 1 then
            return (raw_select( start_position, ... ))
        end

        return slice( length, raw_select( start_position, ... ) )
    end

end

--- [SHARED AND MENU]
---
--- Packs the argument list into a table.
---
--- The number of arguments is stored at index `0`, allowing `nil` values
--- to be preserved.
---
---@param ... any The values to pack.
---@return table packed A table containing the packed values.
---@return integer A size of the given table.
function vararg.pack( ... )
    local count = raw_select( "#", ... )
    return { [ 0 ] = count, ... }, count
end

--- [SHARED AND MENU]
---
--- Unpacks a table created by `vararg.pack` into an argument list.
---
--- The argument count must be stored at index `0`.
---
---@param tbl table The packed argument table.
---@return any ... The values stored in the table.
function vararg.unpack( tbl )
    local size = tbl[ 0 ]

    if size == 0 then
        return
    elseif size == 1 then
        return tbl[ 1 ]
    elseif size == 2 then
        return tbl[ 1 ], tbl[ 2 ]
    elseif size == 3 then
        return tbl[ 1 ], tbl[ 2 ], tbl[ 3 ]
    elseif size == 4 then
        return tbl[ 1 ], tbl[ 2 ], tbl[ 3 ], tbl[ 4 ]
    end

    return table_unpack( tbl, 1, size )
end
