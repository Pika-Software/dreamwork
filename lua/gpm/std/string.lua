---@class gpm.std
local std = _G.gpm.std

local math = std.math
local math_floor = math.floor
local math_random = math.random
local math_relative = math.relative
local math_min, math_max = math.min, math.max

--- [SHARED AND MENU]
---
--- The string type is a sequence of characters.
---
--- The string library is a standard Lua library which provides functions for the manipulation of strings.
---
--- In gpm string library contains additional functions.
---
---@class gpm.std.string
local string = std.string or {}
std.string = string

do

    local glua_string = _G.string

    -- Lua 5.1
    string.byte = string.byte or glua_string.byte
    string.char = string.char or glua_string.char
    string.dump = string.dump or glua_string.dump
    string.find = string.find or glua_string.find
    string.format = string.format or glua_string.format
    ---@diagnostic disable-next-line: deprecated
    string.gmatch = string.gmatch or glua_string.gmatch or glua_string.gfind
    string.gsub = string.gsub or glua_string.gsub
    string.len = string.len or glua_string.len
    string.lower = string.lower or glua_string.lower
    string.match = string.match or glua_string.match
    string.rep = string.rep or glua_string.rep
    string.reverse = string.reverse or glua_string.reverse
    string.sub = string.sub or glua_string.sub
    string.upper = string.upper or glua_string.upper

end

local string_char, string_byte = string.char, string.byte
local string_match, string_find = string.match, string.find
local string_sub, string_rep, string_len = string.sub, string.rep, string.len

local table = std.table
local table_concat = table.concat

--- [SHARED AND MENU]
---
--- Checks if the string is empty.
---
---@param str string The string to check.
---@return boolean result True if the string is empty.
function string.isEmpty( str )
    return string_byte( str, 1, 1 ) == nil
end

--- [SHARED AND MENU]
---
--- Cuts the string into two.
---
---@param str string The string to cut.
---@param index integer String cutting index.
---@param str_length? integer The length of the string. Optionally, it should be used to speed up calculations.
---@return string left_part The first part of the string.
---@return string right_part The second part of the string.
function string.cut( str, index, str_length )
    if str_length == nil then
        str_length = string_len( str )
    end

    if index == nil then
        index = str_length * 0.5
    elseif index < 0 then
        index = math_relative( index, str_length )
    else
        index = math_min( index, str_length )
    end

    return string_sub( str, 1, index - 1 ), string_sub( str, index, str_length )
end

--- [SHARED AND MENU]
---
--- Divides the string by the pattern.
---
---@param str string The string to divide.
---@param pattern_str string The pattern to divide by.
---@param start_position? integer The start position to divide from.
---@param with_pattern? boolean If set to `true`, `pattern_str` will be used as a pattern.
---@param str_length? integer The length of the string. Optionally, it should be used to speed up calculations.
---@return string left_part The first part of the strin.
---@return string right_part The second part of the string.
function string.divide( str, pattern_str, start_position, with_pattern, str_length )
    local divide_start, divide_end = string_find( str, pattern_str, start_position or 1, with_pattern ~= true )
    if divide_start == nil then
        return str, ""
    else
        return string_sub( str, 1, divide_start - 1 ), string_sub( str, divide_end + 1, str_length or string_len( str ) )
    end
end

--- [SHARED AND MENU]
---
--- Extracts a string from the other string.
---
---@param str string The string to extract from.
---@param pattern_str string The pattern or searchable to extract by.
---@param start_position? integer The start position to extract from.
---@param default? string | nil The default string that is returned if no matches are found.
---@param with_pattern? boolean If set to `true`, `pattern_str` will be used as a pattern.
---@return string new_string The new string without the extracted string.
---@return string | nil extracted The extracted string, otherwise the default string.
function string.extract( str, pattern_str, start_position, default, with_pattern )
    local extraction_start, extraction_end, str_matched = string_find( str, pattern_str, start_position or 1, with_pattern ~= true )
    if extraction_start == nil then
        return str, default
    else
        return string_sub( str, 1, extraction_start - 1 ) .. string_sub( str, extraction_end + 1 ), str_matched or default
    end
end

--- [SHARED AND MENU]
---
--- Inserts a value into the string.
---
---@param str string
---@param index integer The string insertion index.
---@param value string The string value to insert.
---@param str_length? integer The length of the string. Optionally, it should be used to speed up calculations.
---@return string result
---@overload fun( str: string, value: string ): string
function string.insert( str, index, value, str_length )
    if value == nil then
        return str .. index
    end

    if str_length == nil then
        str_length = string_len( str )
    end

    if index == nil then
        index = str_length + 1
    elseif index < 0 then
        index = math_relative( index, str_length )
    else
        index = math_min( index, str_length + 1 )
    end

    if index == 0 then
        return value .. str
    elseif index == ( str_length + 1 ) then
        return str .. value
    end

    return string_sub( str, 1, index - 1 ) .. value .. string_sub( str, index, str_length )
end

--- [SHARED AND MENU]
---
--- Removes the specified interval from the string.
---
---@param str string The string to remove from.
---@param start_position integer The start position of the removal interval.
---@param end_position integer The end position of the removal interval.
---@param str_length? integer The length of the string. Optionally, it should be used to speed up calculations.
---@return string new_string A string without a specified byte interval.
function string.remove( str, start_position, end_position, str_length )
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

    if start_position == 1 and end_position == str_length then
        return ""
    else
        return string_sub( str, 1, start_position - 1 ) .. string_sub( str, end_position + 1, str_length )
    end
end

--- [SHARED AND MENU]
---
--- Checks if the string starts with the start string.
---
---@param str string The string to check.
---@param str_start string The start string.
---@return boolean is_starts `true` if the string starts with the start string, otherwise `false`.
function string.startsWith( str, str_start )
    return str == str_start or string_sub( str, 1, string_len( str_start ) ) == str_start
end

--- [SHARED AND MENU]
---
--- Checks if the string ends with the end string.
---
---@param str string The string to check.
---@param str_end string The end string.
---@return boolean is_ends `true` if the string ends with the end string, otherwise `false`.
function string.endsWith( str, str_end )
    return str_end == "" or str == str_end or
        string_sub( str, -string_len( str_end ) ) == str_end
end

--- [SHARED AND MENU]
---
--- Checks if the string contains the searchable string.
---
---@param str string
---@param searchable string The searchable string.
---@param position? integer The position to start from.
---@param with_pattern? boolean If set to `true`, `pattern_str` will be used as a pattern.
---@param str_length? integer The length of the string. Optionally, it should be used to speed up calculations.
---@return integer index The index of the searchable string, otherwise `-1`.
function string.indexOf( str, searchable, position, with_pattern, str_length )
    if searchable == nil or searchable == "" then
        return 0
    end

    if str_length == nil then
        str_length = string_len( str )
    end

    if position == nil then
        position = 1
    elseif position < 0 then
        position = math_relative( position, str_length )
    elseif position > str_length then
        return -1
    end

    return string_find( str, searchable, position, with_pattern ~= true ) or -1
end

--- [SHARED AND MENU]
---
--- Pads the string to a desired length.
---
---@param str string The string to pad.
---@param desired_length integer The desired length of the string.
---@param char? string The padding compensation symbol. Space by default.
---@param direction boolean | nil The compensation direction, `true` for right, `false` for left, `nil` for both.
---@param str_length? integer The length of the string. Optionally, it should be used to speed up calculations.
---@return string padded_str The padded string.
function string.pad( str, desired_length, char, direction, str_length )
    local missing_length = math_max( 0, desired_length - ( str_length or string_len( str ) ) )
    if missing_length == 0 then
        return str
    end

    if char == nil then
        char = " "
    elseif string_byte( char, 2, 2 ) ~= nil then
        error( "char must be a single character", 2 )
    end

    if direction == nil then
        missing_length = math_floor( missing_length * 0.5 )
        return string_rep( char, missing_length ) .. str .. string_rep( char, missing_length + ( ( missing_length % 1 == 0 ) and 0 or 1 ) )
    elseif direction then
        return str .. string_rep( char, missing_length )
    else
        return string_rep( char, missing_length ) .. str
    end
end

--- [SHARED AND MENU]
---
--- Splits the string into an array, using the specified pattern.
---
---@param str string The string to split.
---@param pattern_str? string The pattern to split by.
---@param start_position? integer The start position to split from.
---@param with_pattern? boolean If set to `true`, `pattern_str` will be used as a pattern.
---@param str_length? integer The length of the string. Optionally, it should be used to speed up calculations.
---@return string[] segments The string array.
---@return integer segment_count The length of the array.
function string.split( str, pattern_str, start_position, with_pattern, str_length )
    local segments = {}

    if str_length == nil then
        str_length = string_len( str )
    end

    if pattern_str == nil or pattern_str == "" then
        for index = 1, str_length, 1 do
            segments[ index ] = string_sub( str, index, index )
        end

        return segments, str_length
    end

    with_pattern = with_pattern ~= true

    local segment_count = 0

    repeat
        local segment_start, segment_end = string_find( str, pattern_str, start_position, with_pattern )
        if segment_start == nil then
            break
        else
            segment_count = segment_count + 1
            ---@diagnostic disable-next-line: param-type-mismatch
            segments[ segment_count ] = string_sub( str, start_position, segment_start - 1 )
            start_position = math_min( segment_end + 1, str_length )
        end
    until start_position == str_length

    segment_count = segment_count + 1
    ---@diagnostic disable-next-line: param-type-mismatch
    segments[ segment_count ] = string_sub( str, start_position )

    return segments, segment_count
end

--- [SHARED AND MENU]
---
--- Returns the number of matches of a string.
---
---@param str string The string to count.
---@param pattern_str? string The pattern to count by.
---@param with_pattern? boolean If set to `true`, `pattern_str` will be used as a pattern.
---@param str_length? integer The length of the string. Optionally, it should be used to speed up calculations.
---@return integer match_count The number of matches.
function string.count( str, pattern_str, with_pattern, str_length )
    if str_length == nil then
        str_length = string_len( str )
    end

    if pattern_str == nil or pattern_str == "" then
        return str_length
    end

    with_pattern = with_pattern ~= true
    local index, length = 1, 0

    repeat
        local start_position, end_position = string_find( str, pattern_str, index, with_pattern )
        if start_position == nil then
            break
        else
            index = math_min( end_position + 1, str_length )
            length = length + 1
        end
    until index == str_length

    return length
end

--- [SHARED AND MENU]
---
--- Returns the number of specified byte repetitions.
---
---@param str string The string to count.
---@param counted_byte? integer The byte to count.
---@param str_length? integer The length of the string. Optionally, it should be used to speed up calculations.
---@return integer byte_count The number of occurrences.
function string.byteCount( str, counted_byte, str_length )
    if counted_byte == nil or str == "" then
        return 0
    end

    local byte_count = 0

    for index = 1, str_length or string_len( str ) do
        if string_byte( str, index, index ) == counted_byte then
            byte_count = byte_count + 1
        end
    end

    return byte_count
end

--- [SHARED AND MENU]
---
--- Returns the string trimmed by the specified byte.
---
---@param str string The string to trim.
---@param trailing_byte? integer The byte to trim trailing characters.
---@param direction boolean | nil The trim direction, `true` for right, `false` for left, `nil` for both.
---@param str_length? integer The length of the string. Optionally, it should be used to speed up calculations.
---@return string trimmed_str The trimmed string.
---@return integer trimmed_length The length of the trimmed string.
function string.byteTrim( str, trailing_byte, direction, str_length )
    local start_position, end_position = 1, str_length or string_len( str )

    if direction ~= true then
        while string_byte( str, start_position, start_position ) == trailing_byte do
            if start_position == end_position then
                return "", 0
            else
                start_position = start_position + 1
            end
        end
    end

    if direction ~= false then
        while string_byte( str, end_position ) == trailing_byte do
            if end_position == 0 then
                return "", 0
            else
                end_position = end_position - 1
            end
        end
    end

    return string_sub( str, start_position, end_position ), end_position - start_position + 1
end

--- [SHARED AND MENU]
---
--- Splits the string into an array, using the specified byte.
---
---@param str string The string to split.
---@param split_byte? integer The byte to split by.
---@param start_position? integer The start position to split from.
---@param end_position? integer The end position to split to.
---@param str_length? integer The length of the string. Optionally, it should be used to speed up calculations.
---@return string[] segments The string array.
---@return integer segment_count The length of the array.
local function byteSplit( str, split_byte, start_position, end_position, str_length )
    if split_byte == nil then
        split_byte = 0x20 --[[ Space ]]
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

    local split_position = start_position - 1
    local segments, segment_count = {}, 0

    while true do
        local uint8 = string_byte( str, start_position, start_position )
        if uint8 == split_byte then
            if split_position ~= start_position then
                segment_count = segment_count + 1
                segments[ segment_count ] = string_sub( str, split_position + 1, start_position - 1 )
            end

            split_position = start_position
        end

        if start_position == end_position then
            break
        else
            start_position = start_position + 1
        end
    end

    if split_position ~= start_position then
        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( str, split_position + 1, start_position )
    end

    return segments, segment_count
end

string.byteSplit = byteSplit

--- [SHARED AND MENU]
---
--- Removes all instances of a byte from a string.
---
---@param str string The string to purge.
---@param byte integer The byte to purge.
---@param start_position? integer The start position in the string.
---@param end_position? integer The end position in the string.
---@return string str_purged The purged string.
function string.purge( str, byte, start_position, end_position, str_length )
    local segments, segment_count = byteSplit( str, byte, start_position, end_position, str_length )
    return table_concat( segments, "", 1, segment_count )
end

do

    local raw_tonumber = std.raw.tonumber

    --- [SHARED AND MENU]
    ---
    --- Checks if the string is a number.
    ---
    ---@param str string The string to check.
    ---@param base? integer The base to check the string in.
    ---@param start_position? integer The start position to check from.
    ---@param end_position? integer The end position to check to.
    ---@return boolean is_number `true` if the string is a number, otherwise `false`.
    function string.isNumber( str, base, start_position, end_position )
        if start_position == nil and end_position == nil then
            return raw_tonumber( str, base ) ~= nil
        else
            return raw_tonumber( string_sub( str, start_position or 1, end_position ), base ) ~= nil
        end
    end

end

do

    local string_gsub = string.gsub

    --- [SHARED AND MENU]
    ---
    --- Replaces all occurrences of the supplied second string.
    ---
    ---@param str string The string we are seeking to replace an occurrence(s).
    ---@param searchable string What we are seeking to replace.
    ---@param replaceable string What to replace find with.
    ---@param with_pattern? boolean Whether to use pattern or not.
    ---@return string new_string The new string with the occurrences replaced.
    function string.replace( str, searchable, replaceable, with_pattern )
        if with_pattern then
            str = string_gsub( str, searchable, replaceable or "" )
        else
            local start_position, end_position = string_find( str, searchable, 1, true )
            if replaceable == nil then
                while start_position ~= nil do
                    str = string_sub( str, 1, start_position - 1 ) .. string_sub( str, end_position + 1 )
                    start_position, end_position = string_find( str, searchable, end_position + 1, true )
                end
            else
                while start_position ~= nil do
                    str = string_sub( str, 1, start_position - 1 ) .. replaceable .. string_sub( str, end_position + 1 )
                    start_position, end_position = string_find( str, searchable, end_position + 1, true )
                end
            end
        end

        return str
    end

end

do

    ---@param str string The string to unpack.
    ---@param start_position integer The start position to unpack from.
    ---@param end_position integer The end position to unpack to.
    ---@return string part1 The first part of the string.
    ---@return string | nil part2 The second part of the string.
    local function unpack( str, start_position, end_position )
        if start_position == end_position then
            return string_sub( str, end_position, end_position )
        else
            return string_sub( str, start_position, start_position ), unpack( str, start_position + 1, end_position )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Unpacks a string into it's characters.
    ---
    ---@param str string The string to unpack.
    ---@param start_position? integer The start position to unpack from.
    ---@param end_position? integer The end position to unpack to.
    ---@param str_length? integer The length of the string. Optionally, it should be used to speed up calculations.
    ---@return string ... The unpacked characters of the string.
    function string.unpack( str, start_position, end_position, str_length )
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
            return ""
        else
            return unpack( str, start_position, end_position )
        end
    end

end

--- [SHARED AND MENU]
---
--- Checks if a string is a URL.
---
---@param str string The string to check.
---@return boolean result `true` if the string is a URL, otherwise `false`.
function string.isURL( str )
    return string_match( str, "^%l[%l+-.]+%:[^%z\x01-\x20\x7F-\xFF\"<>^`:{-}]*$" ) ~= nil
end

do

    local jit_version = ( {
        [ "200" ] = 0x01,
        [ "201" ] = 0x02
    } )[ string_sub( std.tostring( std.JIT_VERSION_INT ), 1, 3 ) ]

    --- [SHARED AND MENU]
    ---
    --- Checks if a string is bytecode.
    ---
    ---@param str string The string to check.
    ---@param start_position? integer The start position of the string.
    ---@return boolean result `true` if the string is bytecode, otherwise `false`.
    function string.isBytecode( str, start_position )
        if start_position == nil then
            start_position = 1
        end

        local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, start_position, start_position + 3 )
        return uint8_1 == 0x1B and uint8_2 == 0x4C and uint8_3 == 0x4A and uint8_4 == jit_version
    end

end

do

    local unsafe_bytes = {
        -- ()
        [ 0x28 ] = "%(",
        [ 0x29 ] = "%)",

        -- []
        [ 0x5B ] = "%[",
        [ 0x5D ] = "%]",

        -- .
        [ 0x2E ] = "%.",

        -- %
        [ 0x25 ] = "%%",

        -- +-
        [ 0x2B ] = "%+",
        [ 0x2D ] = "%-",

        -- *
        [ 0x2A ] = "%*",

        -- ?
        [ 0x3F ] = "%?",

        -- ^
        [ 0x5E ] = "%^",

        -- $
        [ 0x24 ] = "%$"
    }

    --- [SHARED AND MENU]
    ---
    --- Escapes a string for use it as a pattern.
    ---
    ---@param str string The string to escape.
    ---@param start_position? integer The start position to escape from.
    ---@param end_position? integer The end position to escape to.
    ---@param str_length? integer The length of the string. Optionally, it should be used to speed up calculations.
    ---@return string escaped_str The escaped string.
    function string.escapePattern( str, start_position, end_position, str_length )
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

        local escape_position = start_position - 1
        local segments, segment_count = {}, 0

        while true do
            local uint8 = string_byte( str, start_position, start_position )

            local replacement

            if uint8 == 0x0 then
                replacement = "%z"
            else
                replacement = unsafe_bytes[ uint8 ]
            end

            if replacement ~= nil then
                if escape_position ~= start_position then
                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_sub( str, escape_position + 1, start_position - 1 ) .. replacement
                end

                escape_position = start_position
            end

            if start_position == end_position then
                break
            else
                start_position = start_position + 1
            end
        end

        if escape_position ~= start_position then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_sub( str, escape_position + 1, start_position )
        end

        if segment_count == 0 then
            return str
        elseif segment_count == 1 then
            return segments[ 1 ]
        else
            return table_concat( segments, "", 1, segment_count )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Removes leading/trailing matches of a string.
    ---
    ---@param str string The string to trim.
    ---@param pattern_str? string The pattern to match, `%s` for whitespace.
    ---@param direction boolean | nil The trim direction, `true` for right, `false` for left, `nil` for both.
    ---@return string trimmed_str The trimmed string.
    function string.trim( str, pattern_str, direction )
        if pattern_str == nil then
            pattern_str = "%s"
        else
            local uint8_1, uint8_2, uint8_3 = string_byte( pattern_str, 1, 3 )

            if uint8_1 == nil then
                pattern_str = "%s"
            elseif uint8_2 == nil then
                pattern_str = unsafe_bytes[ uint8_1 ] or pattern_str
            elseif uint8_3 ~= nil or uint8_1 ~= 0x25 --[[ % ]] then
                pattern_str = "[" .. pattern_str .. "]"
            end
        end

        if direction == true then
            return string_match( str, "^(.-)" .. pattern_str .. "*$" ) or str
        elseif direction == false then
            return string_match( str, "^" .. pattern_str .. "*(.+)$" ) or str
        else
            return string_match( str, "^" .. pattern_str .. "*(.-)" .. pattern_str .. "*$" ) or str
        end
    end

end

do

    local extended_ascii_alphabet = {}
    local lowercase_alphabet = {}
    local uppercase_alphabet = {}
    local numberic_alphabet = {}
    local symbol_alphabet = {}

    do

        local extended_ascii_alphabet_size = 0
        local lowercase_alphabet_size = 0
        local uppercase_alphabet_size = 0
        local numberic_alphabet_size = 0
        local symbol_alphabet_size = 0

        for i = 33, 47, 1 do
            symbol_alphabet_size = symbol_alphabet_size + 1
            symbol_alphabet[ symbol_alphabet_size ] = i
        end

        for i = 48, 57, 1 do
            numberic_alphabet_size = numberic_alphabet_size + 1
            numberic_alphabet[ numberic_alphabet_size ] = i
        end

        for i = 58, 64, 1 do
            symbol_alphabet_size = symbol_alphabet_size + 1
            symbol_alphabet[ symbol_alphabet_size ] = i
        end

        for i = 65, 90, 1 do
            uppercase_alphabet_size = uppercase_alphabet_size + 1
            uppercase_alphabet[ uppercase_alphabet_size ] = i
        end

        for i = 91, 96, 1 do
            symbol_alphabet_size = symbol_alphabet_size + 1
            symbol_alphabet[ symbol_alphabet_size ] = i
        end

        for i = 97, 122, 1 do
            lowercase_alphabet_size = lowercase_alphabet_size + 1
            lowercase_alphabet[ lowercase_alphabet_size ] = i
        end

        for i = 123, 126, 1 do
            symbol_alphabet_size = symbol_alphabet_size + 1
            symbol_alphabet[ symbol_alphabet_size ] = i
        end

        for i = 128, 255, 1 do
            extended_ascii_alphabet_size = extended_ascii_alphabet_size + 1
            extended_ascii_alphabet[ extended_ascii_alphabet_size ] = i
        end

        lowercase_alphabet[ 0 ] = lowercase_alphabet_size
        uppercase_alphabet[ 0 ] = uppercase_alphabet_size
        numberic_alphabet[ 0 ] = numberic_alphabet_size
        symbol_alphabet[ 0 ] = symbol_alphabet_size

    end

    local table_unpack = table.unpack

    --- [SHARED AND MENU]
    ---
    --- Generates a random string.
    ---
    --- Can be used to generate a password/key/secret.
    ---
    --- The length of the string is 8 by default.
    ---
    ---@param length? integer The length of the string, defaults to 8.
    ---@param lowercase? boolean Whether to include lowercase letters.
    ---@param uppercase? boolean Whether to include uppercase letters.
    ---@param numbers? boolean Whether to include numbers.
    ---@param symbols? boolean Whether to include symbols.
    ---@param extended_ascii? boolean Whether to include extended ASCII characters.
    ---@return string
    function string.random( length, lowercase, uppercase, numbers, symbols, extended_ascii )
        if length == nil then
            length = 8
        elseif length == 0 then
            return ""
        end

        local alphabets, alphabet_count = {}, 0

        if lowercase ~= false then
            alphabet_count = alphabet_count + 1
            alphabets[ alphabet_count ] = lowercase_alphabet
        end

        if uppercase then
            alphabet_count = alphabet_count + 1
            alphabets[ alphabet_count ] = uppercase_alphabet
        end

        if numbers ~= false then
            alphabet_count = alphabet_count + 1
            alphabets[ alphabet_count ] = numberic_alphabet
        end

        if symbols then
            alphabet_count = alphabet_count + 1
            alphabets[ alphabet_count ] = symbol_alphabet
        end

        if extended_ascii then
            alphabet_count = alphabet_count + 1
            alphabets[ alphabet_count ] = extended_ascii_alphabet
        end

        local chars, char_count = {}, 0

        for _ = 1, length, 1 do
            local alphabet = alphabets[ math_random( 1, alphabet_count ) ]

            char_count = char_count + 1
            chars[ char_count ] = alphabet[ math_random( 1, alphabet[ 0 ] ) ]
        end

        return string_char( table_unpack( chars, 1, char_count ) )
    end

end
