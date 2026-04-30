local std = dreamwork.std
---@class dreamwork.std.encoding
local encoding = std.encoding

local bytepack = std.pack.bytes
local bytepack_readHex8 = bytepack.readHex8
local bytepack_writeHex8 = bytepack.writeHex8

local string = std.string
local string_len = string.len
local string_byte, string_char = string.byte, string.char

local math = std.math
local math_min = math.min
local math_relative = math.relative

local table_concat = std.table.concat

--- [SHARED AND MENU]
---
--- Base16 (hexadecimal) encoding/decoding library.
---
--- See https://en.wikipedia.org/wiki/Hexadecimal
---
---@class dreamwork.std.encoding.base16
local base16 = encoding.base16 or {}
encoding.base16 = base16

--- [SHARED AND MENU]
---
--- Encodes the specified string to base16.
---
---@param raw_str string The string to encode.
---@param start_position? number The start position of the string, default is `1`.
---@param end_position? number The end position of the string, default is the length of the base16 string.
---@return string The encoded string.
function base16.encode( raw_str, start_position, end_position )
    ---@type integer
    local str_length = string_len( raw_str )

    if str_length == 0 then
        return raw_str
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

    for index = start_position, end_position, 1 do
        segment_count = segment_count + 1
        segments[ segment_count ] = string_char( bytepack_writeHex8( string_byte( raw_str, index, index ) ) )
    end

    return table_concat( segments, "", 1, segment_count )
end

--- [SHARED AND MENU]
---
--- Decodes the specified base16 string to a string.
---
---@param base16_str string The base16 string to decode.
---@param start_position? number The start position of the base16 string, default is `1`.
---@param end_position? number The end position of the base16 string, default is the length of the base16 string.
---@return string str_raw The decoded string.
function base16.decode( base16_str, start_position, end_position )
    ---@type integer
    local str_length = string_len( base16_str )

    if str_length == 0 then
        return base16_str
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

    for index = start_position, end_position, 2 do
        segment_count = segment_count + 1

        local uint8_1, uint8_2 = string_byte( base16_str, index, index + 1 )

        local decoded_uint8 = bytepack_readHex8( uint8_1, uint8_2 )
        if decoded_uint8 == nil then
            segments[ segment_count ] = string_char( uint8_1, uint8_2 )
        else
            segments[ segment_count ] = string_char( decoded_uint8 )
        end
    end

    return table_concat( segments, "", 1, segment_count )
end

--- [SHARED AND MENU]
---
--- Validates the specified base16 string.
---
---@param base16_str string The base16 string to validate.
---@param start_position? number The start position of the base16 string, default is `1`.
---@param end_position? number The end position of the base16 string, default is the length of the base16 string.
---@return boolean is_valid `true` if the base16 string is valid, otherwise `false`.
---@return nil | string err_msg The error message.
function base16.validate( base16_str, start_position, end_position )
    ---@type integer
    local str_length = string_len( base16_str )

    if str_length == 0 then
        return false, "string cannot be empty"
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

    if (end_position - (start_position - 1)) % 2 ~= 0 then
        return false, "string length must be even"
    end

    for index = start_position, end_position, 2 do
        if bytepack_readHex8( string_byte( base16_str, index, index + 1 ) ) == nil then
            return false, "string contains invalid characters"
        end
    end

    return true
end

do

    local string_sub = string.sub

    --- [SHARED AND MENU]
    ---
    --- Escapes the specified base16 string.
    ---
    --- Escape sequence: `\xXX`
    ---
    ---@param base16_str string The base16 string to escape.
    ---@param start_position? number The start position of the base16 string, default is `1`.
    ---@param end_position? number The end position of the base16 string, default is the length of the base16 string.
    ---@return string base16_escape_str The escaped base16 string, or `nil` if the base16 string is invalid.
    function base16.escape( base16_str, start_position, end_position )
        ---@type integer
        local str_length = string_len( base16_str )

        if str_length == 0 then
            return base16_str
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

        for index = start_position, end_position, 2 do
            segment_count = segment_count + 1
            segments[ segment_count ] = "\\x" .. string_sub( base16_str, index, index + 1 )
        end

        if segment_count == 0 then
            return ""
        elseif segment_count == 1 then
            return segments[ 1 ]
        else
            return table_concat( segments, "", 1, segment_count )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Unescapes the specified base16 string.
    ---
    --- Unescape sequence: `\xXX`
    ---
    ---@param base16_escape_str string The base16 string to unescape.
    ---@param start_position? number The start position of the escaped base16 string, default is `1`.
    ---@param end_position? number The end position of the escaped base16 string, default is the length of the base16 string.
    ---@return string base16_str The unescaped base16 string.
    function base16.unescape( base16_escape_str, start_position, end_position )
        ---@type integer
        local str_length = string_len( base16_escape_str )

        if str_length == 0 then
            return base16_escape_str
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
        end_position = end_position + 1

        repeat
            local uint8_1 = string_byte( base16_escape_str, start_position, start_position )
            if uint8_1 == nil then
                break
            end

            start_position = start_position + 1

            local uint8_2 = string_byte( base16_escape_str, start_position, start_position )
            if uint8_2 == nil then
                segment_count = segment_count + 1
                segments[ segment_count ] = string_char( uint8_1 )
                break
            end

            if uint8_1 == 0x5C --[[ "\" ]] and uint8_2 == 0x78 --[[ "x" ]] then

                start_position = start_position + 1

                local uint8_3 = string_byte( base16_escape_str, start_position, start_position )
                if uint8_3 == nil then
                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_char( uint8_1, uint8_2 )
                    break
                end

                start_position = start_position + 1

                local uint8_4 = string_byte( base16_escape_str, start_position, start_position )
                if uint8_4 == nil then
                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_char( uint8_1, uint8_2, uint8_3 )
                    break
                end

                segment_count = segment_count + 1
                segments[ segment_count ] = string_char( uint8_3, uint8_4 )
            else
                segment_count = segment_count + 1
                segments[ segment_count ] = string_char( uint8_1, uint8_2 )
            end

            start_position = start_position + 1
        until start_position > end_position

        if segment_count == 0 then
            return ""
        elseif segment_count == 1 then
            return segments[ 1 ]
        else
            return table_concat( segments, "", 1, segment_count )
        end
    end

end
