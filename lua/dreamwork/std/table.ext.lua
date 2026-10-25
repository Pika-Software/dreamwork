local std = dreamwork.std

local string = std.string
local string_len = string.len
local string_sub = string.sub
local string_byte = string.byte

local isTable = std.isTable

---@class dreamwork.std.table
local table = std.table


--- [SHARED AND MENU]
---
--- Returns the value of the given key path.
---
--- If the key path does not exist, or passes through a non-table value, returns `nil`.
---
--- Every separator splits the path, empty segments are `""` keys,
--- so `""` is `t[ "" ]`, `".a"` is `t[ "" ].a`, `"a."` is `t.a[ "" ]` and `"a..b"` is `t.a[ "" ].b`.
---
--- Example:
---
--- ```lua
---     local t = { a = { b = { c = { d = { e = "e value!" } } } } }
---     print( table.get( t, "a.b.c.d.e" ) ) -- e value!
--- ```
---
---@param tbl table The table to get the value from.
---@param path string The key path to get.
---@param separator? integer The separator of the key path, default is `0x2E`.
---@return any value The value of the key path.
function table.get( tbl, path, separator )
    if separator == nil then
        separator = 0x2E --[[ "." ]]
    end

    local str_length = string_len( path )
    local split_position = 0

    for position = 1, str_length, 1 do
        if string_byte( path, position, position ) == separator then
            tbl = tbl[ string_sub( path, split_position + 1, position - 1 ) ]

            if not isTable( tbl ) then
                return nil
            end

            split_position = position
        end
    end

    return tbl[ string_sub( path, split_position + 1, str_length ) ]
end

--- [SHARED AND MENU]
---
--- Sets the value of the given key path.
---
--- Tables are created if they do not exist, non-table values on the path are replaced.
---
--- Every separator splits the path, empty segments are `""` keys,
--- so `""` is `t[ "" ]`, `".a"` is `t[ "" ].a`, `"a."` is `t.a[ "" ]` and `"a..b"` is `t.a[ "" ].b`.
---
--- Example:
---
--- ```lua
---     local t = {}
---     table.set( t, "a.b.c.d.e", "e value!" )
---     print( t.a.b.c.d.e ) -- e value!
--- ```
---
---@param tbl table The table to set the value in.
---@param path string The key path.
---@param value any The value to set.
---@param separator? integer The separator of the key path, default is `0x2E`.
function table.set( tbl, path, value, separator )
    if separator == nil then
        separator = 0x2E --[[ "." ]]
    end

    local str_length = string_len( path )
    local split_position = 0

    for position = 1, str_length, 1 do
        if string_byte( path, position, position ) == separator then
            local key = string_sub( path, split_position + 1, position - 1 )

            local tbl_value = tbl[ key ]
            if isTable( tbl_value ) then
                tbl = tbl_value
            else
                tbl_value = {}
                tbl[ key ] = tbl_value
                tbl = tbl_value
            end

            split_position = position
        end
    end

    tbl[ string_sub( path, split_position + 1, str_length ) ] = value
end
