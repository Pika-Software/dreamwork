local std = _G.dreamwork.std

---@class dreamwork.std.string
local string = std.string
local string_sub, string_len = string.sub, string.len
local string_char, string_byte = string.char, string.byte

---@class dreamwork.std.table
local table = std.table
local table_concat = table.concat

local math = std.math
local math_min = math.min
local math_relative = math.relative

--- [SHARED AND MENU]
---
--- Returns the value of the given key path.
---
--- If the key path does not exist, returns `nil`.
---
--- Example:
---
--- ```lua
---     local t = { a = { b = { c = { d = { e = "e value!" } } } } }
---     print( table.get( t, "a.b.c.d.e" ) ) -- e value!
--- ```
---@param tbl table The table to get the value from.
---@param str string The key path to get.
---@param separator? integer The separator of the key path, default is `0x2E`.
---@param str_length? integer The length of the key path, default is `string.len( str )`.
---@return any value The value of the key path.
function table.get( tbl, str, separator, start_position, end_position, str_length )
    if separator == nil then
        separator = 0x2E --[[ "." ]]
    end

    if str_length == nil then
        str_length = string_len( str )
    end

    if start_position == nil then
        start_position = 1
    elseif start_position < 0 then
        start_position = math_relative( start_position, str_length )
    else
        start_position = math_min( start_position, str_length )
    end

    if end_position == nil then
        end_position = str_length
    elseif end_position < 0 then
        end_position = math_relative( end_position, str_length )
    else
        end_position = math_min( end_position, str_length )
    end

    if start_position > end_position then
        return nil
    end

    local split_position = start_position - 1

    ::table_lookup_loop::

    if string_byte( str, start_position, start_position ) == separator then
        if split_position ~= start_position then
            tbl = tbl[ string_sub( str, split_position + 1, start_position - 1 ) ]
            if tbl == nil then return nil end
        end

        split_position = start_position
    end

    if start_position ~= end_position then
        start_position = start_position + 1
        goto table_lookup_loop
    end

    if split_position ~= start_position then
        tbl = tbl[ string_sub( str, split_position + 1, start_position ) ]
    end

    return tbl
end

do

    local isTable = std.isTable

    --- [SHARED AND MENU]
    ---
    --- Sets the value of the given key path.
    ---
    --- Tables are created if they do not exist.
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
    ---@param str string The key path.
    ---@param value any The value to set.
    ---@param separator? integer The separator of the key path, default is `0x2E`.
    ---@param str_length? integer The length of the key path, default is `string.len( str )`.
    function table.set( tbl, str, value, separator, str_length )
        if separator == nil then
            separator = 0x2E --[[ "." ]]
        end

        if str_length == nil then
            str_length = string_len( str )
        end

        local split_position = 0
        local position = 1

        while true do
            local uint8 = string_byte( str, position, position )
            if uint8 == separator then
                if split_position ~= position then
                    local key = string_sub( str, split_position + 1, position - 1 )

                    if position == str_length then
                        tbl[ key ] = value
                        return
                    end

                    local tbl_value = tbl[ key ]
                    if tbl_value ~= nil and isTable( tbl_value ) then
                        tbl = tbl_value
                    else
                        local new_tbl = {}
                        tbl[ key ] = new_tbl
                        tbl = new_tbl
                    end
                end

                split_position = position
            end

            if position == str_length then
                break
            else
                position = position + 1
            end
        end

        if split_position ~= position then
            tbl[ string_sub( str, split_position + 1, position ) ] = value
        end
    end

end

local bytepack = std.pack.bytes

do

    local bytepack_writeHex8 = bytepack.writeHex8

    ---@type table<integer, string>
    local escape_sequences = {
        [ 0x5C ] = "\\\\",
        [ 0x07 ] = "\\a",
        [ 0x08 ] = "\\b",
        [ 0x0C ] = "\\f",
        [ 0x0A ] = "\\n",
        [ 0x0D ] = "\\r",
        [ 0x09 ] = "\\t",
        [ 0x0B ] = "\\v",
        [ 0x22 ] = "\\\"",
        [ 0x27 ] = "\\\'"
    }

    --- [SHARED AND MENU]
    ---
    --- Escapes special characters in a string.
    ---
    ---@param str string The string to escape.
    ---@param start_position? integer The start index.
    ---@param end_position? integer The end index.
    ---@param encode_spaces? boolean Whether to encode spaces.
    ---@return string escaped_str The escaped string.
    function string.escape( str, start_position, end_position, encode_spaces )
        ---@type integer
        local str_length = string_len( str )

        if str_length == 0 then
            return str
        end

        if start_position == nil then
            start_position = 1
        elseif start_position < 0 then
            start_position = math_relative( start_position, str_length )
        else
            start_position = math_min( start_position, str_length )
        end

        if end_position == nil then
            end_position = str_length
        elseif end_position < 0 then
            end_position = math_relative( end_position, str_length )
        else
            end_position = math_min( end_position, str_length )
        end

        local sequence_position = start_position
        local segments, segment_count = {}, 0

        local in_range = encode_spaces and 0x21 or 0x20

        for index = start_position, end_position, 1 do
            local uint8 = string_byte( str, index, index )
            local escape_sequence = escape_sequences[ uint8 ]
            if escape_sequence ~= nil then
                segment_count = segment_count + 1
                segments[ segment_count ] = string_sub( str, sequence_position, index - 1 ) .. escape_sequence
                sequence_position = index + 1
            elseif uint8 < in_range or uint8 > 0x7F then
                segment_count = segment_count + 1
                segments[ segment_count ] = string_sub( str, sequence_position, index - 1 ) .. string_char( 0x5C, 0x78, bytepack_writeHex8( uint8 ) )
                sequence_position = index + 1
            end
        end

        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( str, sequence_position, end_position )

        return table_concat( segments, "", 1, segment_count )
    end

end

do

    local bytepack_readHex8 = bytepack.readHex8

    ---@type table<integer, string>
    local unescape_sequences = {
        [ 0x5C ] = "\\",
        [ 0x61 ] = "\a",
        [ 0x62 ] = "\b",
        [ 0x66 ] = "\f",
        [ 0x6E ] = "\n",
        [ 0x72 ] = "\r",
        [ 0x74 ] = "\t",
        [ 0x76 ] = "\v",
        [ 0x22 ] = "\"",
        [ 0x27 ] = "\'"
    }

    --- [SHARED AND MENU]
    ---
    --- Unescapes special characters in a string.
    ---
    ---@param escaped_str string The string to unescape.
    ---@param start_position? integer The start index.
    ---@param end_position? integer The end index.
    ---@return string str The unescaped string.
    function string.unescape( escaped_str, start_position, end_position )
        ---@type integer
        local str_length = string_len( escaped_str )

        if str_length == 0 then
            return escaped_str
        end

        if start_position == nil then
            start_position = 1
        elseif start_position < 0 then
            start_position = math_relative( start_position, str_length )
        else
            start_position = math_min( start_position, str_length )
        end

        if end_position == nil then
            end_position = str_length
        elseif end_position < 0 then
            end_position = math_relative( end_position, str_length )
        else
            end_position = math_min( end_position, str_length )
        end

        local segments, segment_count = {}, 0

        while true do
            local uint8_1 = string_byte( escaped_str, start_position, start_position )
            if uint8_1 == nil then
                break
            end

            segment_count = segment_count + 1

            if uint8_1 == 0x5C --[[ "\" ]] then
                start_position = start_position + 1

                local uint8_2 = string_byte( escaped_str, start_position, start_position )
                if uint8_2 == nil then
                    segments[ segment_count ] = string_char( uint8_1 )
                    break
                elseif uint8_2 == 0x78 --[[ "x" ]] then
                    start_position = start_position + 1

                    local uint8_3, uint8_4 = string_byte( escaped_str, start_position, start_position + 1 )
                    if uint8_3 == nil then
                        segments[ segment_count ] = string_char( uint8_1, uint8_2 )
                        break
                    elseif uint8_4 == nil then
                        segments[ segment_count ] = string_char( uint8_1, uint8_2, uint8_3 )
                        break
                    end

                    start_position = start_position + 1

                    local decoded_uint8 = bytepack_readHex8( uint8_3, uint8_4 )
                    if decoded_uint8 == nil then
                        segments[ segment_count ] = string_char( uint8_1, uint8_2, uint8_3, uint8_4 )
                    else
                        segments[ segment_count ] = string_char( decoded_uint8 )
                    end
                else
                    local unescape_sequence = unescape_sequences[ uint8_2 ]
                    if unescape_sequence == nil then
                        segments[ segment_count ] = string_char( uint8_1, uint8_2 )
                    else
                        segments[ segment_count ] = unescape_sequence
                    end
                end
            else
                segments[ segment_count ] = string_char( uint8_1 )
            end

            if start_position == end_position then
                break
            else
                start_position = start_position + 1
            end
        end

        if segment_count == 0 then
            return ""
        elseif segment_count == 1 then
            return segments[ 1 ]
        else
            return table_concat( segments, "", 1, segment_count )
        end
    end

end
