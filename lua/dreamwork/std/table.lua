local _G = _G

---@class dreamwork.std
local std = _G.dreamwork.std

local len = std.len
local next = std.next
local select = std.select

local math = std.math
local math_min = math.min
local math_floor = math.floor
local math_random = math.random
local math_relative = math.relative

--- [SHARED AND MENU]
---
--- The table library is a standard Lua library which provides functions to manipulate tables.
---
---@class dreamwork.std.table
local table = std.table or {}
std.table = table

do

    local debug_iscf = std.debug.iscf
    local glua_table = _G.table

    -- Lua 5.1
    table.concat = glua_table.concat
    table.insert = glua_table.insert
    table.remove = glua_table.remove
    table.sort = glua_table.sort

    table.maxn = glua_table.maxn -- removed in Lua 5.2

    -- Lua 5.2
    local table_pack = glua_table.pack
    if table_pack ~= nil and debug_iscf( table_pack ) then
        table.pack = table_pack
    end

    if table.pack == nil then
        ---@diagnostic disable-next-line: duplicate-set-field
        function table.pack( ... )
            return { n = select( "#", ... ), ... }
        end
    end

    table.unpack = glua_table.unpack or _G.unpack

    -- Lua 5.3
    local table_move = glua_table.move
    if table_move ~= nil and debug_iscf( table_move ) then
        table.move = table_move
    end

    if table.move == nil then

        --- [SHARED AND MENU]
        ---
        --- Moves elements from one table to another.
        ---
        ---@param source table The source table.
        ---@param start_position? integer The start position of the source table, defaults to 1.
        ---@param end_position? integer The end position of the source table, defaults to the length of the source table.
        ---@param offset? integer The start position of the destination table, defaults to 1.
        ---@param destination? table The destination table.
        ---@param source_length? integer The length of the source table. Optionally, it should be used to speed up calculations.
        ---@return table destination The destination table.
        ---@diagnostic disable-next-line: duplicate-set-field
        function table.move( source, start_position, end_position, offset, destination, source_length )
            if destination == nil then
                destination = source
            end

            if source_length == nil then
                source_length = len( source )
            end

            if start_position == nil then
                start_position = 1
            elseif start_position < 0 then
                start_position = math_relative( start_position, source_length )
            else
                start_position = math_min( start_position, source_length )
            end

            if end_position == nil then
                end_position = source_length
            elseif end_position < 0 then
                end_position = math_relative( end_position, source_length )
            else
                end_position = math_min( end_position, source_length )
            end

            if offset == nil then
                offset = 1
            end

            for index = 0, end_position - start_position, 1 do
                destination[ offset + index ] = source[ start_position + index ]
            end

            return destination
        end

    end

end

--- [SHARED AND MENU]
---
--- Returns a slice of the given table.
---
---@param tbl table The table to slice.
---@param start_position? integer The start position of the slice.
---@param end_position? integer The end position of the slice.
---@param step? integer The step.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
---@return table slice The sliced table.
---@return integer length The length of the sliced table.
function table.sub( tbl, start_position, end_position, step, tbl_length )
    if tbl_length == nil then
        tbl_length = len( tbl )
    end

    if start_position == nil then
        start_position = 1
    elseif start_position < 0 then
        start_position = math_relative( start_position, tbl_length )
    else
        start_position = math_min( start_position, tbl_length )
    end

    if end_position == nil then
        end_position = tbl_length
    elseif end_position < 0 then
        end_position = math_relative( end_position, tbl_length )
    else
        end_position = math_min( end_position, tbl_length )
    end

    local slice, slice_size = {}, 0

    for index = start_position, end_position, step or 1 do
        slice_size = slice_size + 1
        slice[ slice_size ] = tbl[ index ]
    end

    return slice, slice_size
end

--- [SHARED AND MENU]
---
--- Truncates the given table.
---
--- The original table is modified.
---
--- The truncated table is a shallow copy of the original table.
---
---@param tbl table The table to truncate.
---@param new_length? integer The length of the truncated table.
---@param tbl_length? integer The length of the original table. Optionally, it should be used to speed up calculations.
function table.truncate( tbl, new_length, tbl_length )
    for index = ( new_length or 0 ) + 1, tbl_length or len( tbl ), 1 do
        tbl[ index ] = nil
    end
end

--- [SHARED AND MENU]
---
--- Creates a truncated copy of the given table.
---
--- The original table is not modified.
---
--- The returned table is a shallow copy of the original table.
---
---@param tbl table The table to truncate.
---@param tbl_length? integer The length of the truncated table. Optionally, it should be used to speed up calculations.
---@return table result The truncated table.
function table.truncated( tbl, tbl_length )
    local copy = {}

    for index = 1, tbl_length or len( tbl ), 1 do
        copy[ index ] = tbl[ index ]
    end

    return copy
end

--- [SHARED AND MENU]
---
--- Injects values from one table to another.
---
---@param destination table The destination table.
---@param source table The source table.
---@param offset? integer The position to inject.
---@param start_position? integer The start position.
---@param end_position? integer The end position.
---@param destination_length? integer The length of the destination table. Optionally, it should be used to speed up calculations.
---@param source_length? integer The length of the source table.
function table.inject( destination, source, offset, start_position, end_position, destination_length, source_length )
    if destination_length == nil then
        destination_length = len( destination )
    end

    if offset == nil then
        if start_position == nil and end_position == nil then
            for index = 1, len( source ), 1 do
                destination[ destination_length + index ] = source[ index ]
            end

            return
        end

        offset = destination_length + 1
    elseif offset < 0 then
        if ( 0 - offset ) > destination_length then
            offset = 1
        else
            offset = destination_length + offset + 2
        end
    end

    if source_length == nil then
        source_length = len( source )
    end

    if start_position == nil then
        start_position = 1
    elseif start_position < 0 then
        start_position = math_relative( start_position, source_length )
    else
        start_position = math_min( start_position, source_length )
    end

    if end_position == nil then
        end_position = source_length
    elseif end_position < 0 then
        end_position = math_relative( end_position, source_length )
    else
        end_position = math_min( end_position, source_length )
    end

    local steps = end_position - start_position

    for i = destination_length, offset, -1 do
        destination[ steps + i + 1 ] = destination[ i ]
    end

    for i = 0, steps, 1 do
        destination[ offset + i ] = source[ start_position + i ]
    end
end

--- [SHARED AND MENU]
---
--- Removes a range of values from the given table.
---
---@param tbl table The table to remove from.
---@param start_position? integer The start position.
---@param end_position? integer The end position.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
function table.eject( tbl, start_position, end_position, tbl_length )
    if tbl_length == nil then
        tbl_length = len( tbl )
    end

    if start_position == nil then
        start_position = 1
    else
        start_position = math_relative( start_position, tbl_length )
    end

    if end_position == nil then
        end_position = tbl_length
    else
        end_position = math_relative( end_position, tbl_length )
    end

    for index = start_position, end_position, 1 do
        tbl[ index ] = nil
    end

    local distance = ( end_position - start_position ) + 1

    for index = end_position + 1, tbl_length, 1 do
        tbl[ index - distance ], tbl[ index ] = tbl[ index ], nil
    end
end

--- [SHARED AND MENU]
---
--- Returns the index of the value in the given table.
---
--- Returns `nil` if the value is not found in the table.
---
---@param tbl table The table to search.
---@param searchable any The value to search for.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
---@return integer | nil index The index of the value.
function table.getIndex( tbl, searchable, tbl_length )
    for index = 1, tbl_length or len( tbl ), 1 do
        if tbl[ index ] == searchable then
            return index
        end
    end

    return nil
end

--- [SHARED AND MENU]
---
--- Returns true if the given table is empty.
---
---@param tbl table The table to check.
---@return boolean result `true` if the table is empty, `false` otherwise.
function table.isEmpty( tbl )
    return next( tbl ) == nil
end

--- [SHARED AND MENU]
---
--- Returns the key of the value in the given table.
---
--- Returns `nil` if the value is not found in the table.
---
---@param tbl table The table to search.
---@param searchable any The value to search for.
---@return any | nil key The key of the value.
function table.getKey( tbl, searchable )
    local key, value = next( tbl, nil )

    while key ~= nil do
        if value == searchable then
            return key
        end

        key, value = next( tbl, key )
    end

    return nil
end

--- [SHARED AND MENU]
---
--- Returns list (table) of keys and length of this list.
---
---@param tbl table The table.
---@return any[] key_lst The list of keys.
---@return integer key_count The length of the list.
function table.keys( tbl )
    local key = next( tbl, nil )
    local keys, key_count = {}, 0

    while key ~= nil do
        key_count = key_count + 1
        keys[ key_count ] = key
        key = next( tbl, key )
    end

    return keys, key_count
end

--- [SHARED AND MENU]
---
--- Returns list (table) of values and length of this list.
---
---@param tbl table The table.
---@return any[] value_lst The list of values.
---@return integer value_count The length of the list.
function table.values( tbl )
    local key, value = next( tbl, nil )
    local values, value_count = {}, 0

    while key ~= nil do
        value_count = value_count + 1
        values[ value_count ] = value
        key, value = next( tbl, key )
    end

    return values, value_count
end

--- [SHARED AND MENU]
---
--- Returns the count of keys in the given table.
---
---@param tbl table The table.
---@return integer key_count The count of keys.
function table.count( tbl )
    local key, key_count = next( tbl, nil ), 0

    while key ~= nil do
        key_count = key_count + 1
        key = next( tbl, key )
    end

    return key_count
end

--- [SHARED AND MENU]
---
--- Flips the keys with values in the given list (table).
---
--- The original table is modified.
---
--- The keys are now the values and the values are now the keys.
---
--- `{ key = value } -> { value = key }`
---
---@param tbl table The table to flip.
function table.flip( tbl )
    local key, value = next( tbl, nil )
    while key ~= nil do
        tbl[ key ], tbl[ value ] = nil, key
        key, value = next( tbl, key )
    end
end

--- [SHARED AND MENU]
---
--- Creates a flipped version of the given table.
---
--- The original table is not modified.
---
--- The flipped table has the values as keys and the keys as values.
---
--- `{ key = value } -> { value = key }`
---
---@param tbl table The table to flip.
---@return table result The flipped table.
function table.flipped( tbl )
    local key, value = next( tbl, nil )
    local result = {}

    while key ~= nil do
        result[ value ] = key
        key, value = next( tbl, key )
    end

    return result
end

--- [SHARED AND MENU]
---
--- Returns the list (table) of key/value pairs and length of this list.
---
---@param tbl table The table.
---@return table result The list of key/value pairs ( sequential table ).
---@return integer result_length The length of the list.
function table.pairs( tbl )
    local result, result_length = {}, 0
    local key, value = next( tbl, nil )

    while key ~= nil do
        result_length = result_length + 1
        result[ result_length ] = { key, value }
        key, value = next( tbl, key )
    end

    return result, result_length
end

--- [SHARED AND MENU]
---
--- Returns true if the given table is sequential.
---
---@param tbl table The table to check.
---@return boolean is_sequential `true` if the table is sequential, `false` otherwise.
function table.isSequential( tbl )
    local key, index = next( tbl, nil ), 1

    while key ~= nil do
        if tbl[ index ] == nil then
            return false
        else
            index = index + 1
        end

        key = next( tbl, key )
    end

    return true
end

--- [SHARED AND MENU]
---
--- Empties the indexes of the given table.
---
---@param tbl table The table to empty.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
function table.clearIndexes( tbl, tbl_length )
    for index = 1, tbl_length or len( tbl ), 1 do
        tbl[ index ] = nil
    end
end

--- [SHARED AND MENU]
---
--- Empties the keys of the given table.
---
---@param tbl table The table to empty.
function table.clearKeys( tbl )
    local key = next( tbl, nil )
    while key ~= nil do
        tbl[ key ] = nil
        key = next( tbl, key )
    end
end

--- [SHARED AND MENU]
---
--- Shuffles the given table.
---
---@param tbl table The table.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
function table.shuffle( tbl, tbl_length )
    if tbl_length == nil then
        tbl_length = len( tbl )
    end

    local j = 0

    for i = tbl_length, 1, -1 do
        j = math_random( 1, tbl_length )
        tbl[ i ], tbl[ j ] = tbl[ j ], tbl[ i ]
    end
end

--- [SHARED AND MENU]
---
--- Returns a random index and its value from the given sequential table.
---
---@param tbl table The sequential table.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
---@return any value The random value.
---@return integer | nil index The index of the value.
function table.randomVI( tbl, tbl_length )
    if tbl_length == nil then
        tbl_length = len( tbl )
    end

    if tbl_length == 0 then
        return nil, nil
    elseif tbl_length == 1 then
        return tbl[ 1 ], 1
    else
        local index = math_random( 1, tbl_length )
        return tbl[ index ], index
    end
end

--- [SHARED AND MENU]
---
--- Returns a random key and its value from the given table.
---
---@param tbl table The key-value table.
---@return any value The random value.
---@return any key The key of the value.
function table.randomVK( tbl )
    local key, key_count = next( tbl, nil ), 0
    while key ~= nil do
        key_count = key_count + 1
        key = next( tbl, key )
    end

    if key_count == 0 then
        return nil, nil
    end

    local i = math_random( 1, key_count )

    local value
    key, value = next( tbl, nil )

    repeat
        i = i - 1
        key, value = next( tbl, key )
    until i == 0

    return value, key
end

--- [SHARED AND MENU]
---
--- Reverses all indexes in the given table.
---
--- The original table will be **modified**.
---
--- Example of a reversed table:
---
---|   Old   |   New   |
---|---------|---------|
---| `[ 1 ]` | `[ 5 ]` |
---| `[ 2 ]` | `[ 4 ]` |
---| `[ 3 ]` | `[ 3 ]` |
---| `[ 4 ]` | `[ 2 ]` |
---| `[ 5 ]` | `[ 1 ]` |
---
---@param tbl table The table to reverse.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
---@return table tbl The reversed table.
---@return integer length The length of the reversed table.
function table.reverse( tbl, tbl_length )
    if tbl_length == nil then
        tbl_length = len( tbl )
    end

    tbl_length = tbl_length + 1

    for i = 1, math_floor( ( tbl_length - 1 ) * 0.5 ), 1 do
        local j = tbl_length - i
        tbl[ i ], tbl[ j ] = tbl[ j ], tbl[ i ]
    end

    return tbl, tbl_length - 1
end

--- [SHARED AND MENU]
---
--- Creates a reversed by indexes copy of the given table.
---
--- The original table remains **unchanged**.
---
--- Example of a reversed table:
---
---|   Old   |   New   |
---|---------|---------|
---| `[ 1 ]` | `[ 5 ]` |
---| `[ 2 ]` | `[ 4 ]` |
---| `[ 3 ]` | `[ 3 ]` |
---| `[ 4 ]` | `[ 2 ]` |
---| `[ 5 ]` | `[ 1 ]` |
---
---@param tbl table The table to reverse.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
---@return table tbl The reversed table.
---@return integer length The length of the reversed table.
function table.reversed( tbl, tbl_length )
    if tbl_length == nil then
        tbl_length = len( tbl )
    end

    tbl_length = tbl_length + 1

    local reversed = {}

    for index = tbl_length - 1, 1, -1 do
        reversed[ tbl_length - index ] = tbl[ index ]
    end

    return reversed, tbl_length - 1
end

do

    --- [SHARED AND MENU]
    ---
    --- Creates a new table, filled with the given value and size.
    ---
    ---@param value any The value to fill the table with.
    ---@param ... integer The sizes of the table.
    ---@return table tbl The created table.
    local function create( value, size, ... )
        if size == nil then
            return value
        else
            local tbl = {}
            for i = 1, size, 1 do
                tbl[ i ] = create( value, ... )
            end

            return tbl
        end
    end

    table.create = create

end

--- [SHARED AND MENU]
---
--- Extracts selected range of values from the table.
---
---@param tbl table The table.
---@param start_position? integer The start position.
---@param end_position? integer The end position.
---@param step_size? integer The step size.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
---@return table values The extracted values.
---@return integer length The length of the extracted values.
function table.extract( tbl, start_position, end_position, step_size, tbl_length )
    if tbl_length == nil then
        tbl_length = len( tbl )
    end

    if start_position == nil then
        start_position = 1
    elseif start_position < 0 then
        start_position = math_relative( start_position, tbl_length )
    else
        start_position = math_min( start_position, tbl_length )
    end

    if end_position == nil then
        end_position = tbl_length
    elseif end_position < 0 then
        end_position = math_relative( end_position, tbl_length )
    else
        end_position = math_min( end_position, tbl_length )
    end

    local extracted, extracted_length = {}, 0

    for index = start_position, end_position, step_size or 1 do
        extracted_length = extracted_length + 1
        extracted[ extracted_length ] = tbl[ index ]
    end

    return extracted, extracted_length
end

--- [SHARED AND MENU]
---
--- Applies a function to each value of the table.
---
--- The original table remains **unchanged**.
---
--- The returned table is a shallow copy of the original table.
---
---@generic V: any
---@param tbl table<integer, V> The sequential table.
---@param fn fun( index: integer, value: V ): V | nil The function to apply.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up execution.
---@return table<integer, V> mapped The new mapped sequential table.
---@return integer mapped_length The length of the new mapped sequential table.
function table.map( tbl, fn, tbl_length )
    local mapped, mapped_length = {}, 0

    if tbl_length == nil then
        tbl_length = len( tbl )
    end

    for index = 1, tbl_length, 1 do
        local new_value = fn( index, tbl[ index ] )
        if new_value ~= nil then
            mapped_length = mapped_length + 1
            mapped[ index ] = new_value
        end
    end

    return mapped, mapped_length
end

do

    local pairs = std.pairs

    --- [SHARED AND MENU]
    ---
    --- Applies a function to each key/value pair of the table.
    ---
    --- The original table remains **unchanged**.
    ---
    --- The returned table is a shallow copy of the original table.
    ---
    ---@generic K: any, V: any
    ---@param tbl table<K, V> The key/value table.
    ---@param fn fun( key: K, value: V ): V | nil The function to apply.
    ---@return table<K, V> transformed The new transformed key/value table.
    function table.transform( tbl, fn )
        local transformed = {}

        for key, value in pairs( tbl ) do
            transformed[ key ] = fn( key, value ) or value
        end

        return transformed
    end

end

--- [SHARED AND MENU]
---
--- Executes a provided function once for each table value.
---
---@generic V: any
---@param tbl table<integer, V> The sequential table.
---@param fn fun( index: integer, value: V ) The function to execute.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up execution.
function table.foreach( tbl, fn, tbl_length )
    if tbl_length == nil then
        tbl_length = len( tbl )
    end

    for index = 1, tbl_length, 1 do
        fn( index, tbl[ index ] )
    end
end

return table
