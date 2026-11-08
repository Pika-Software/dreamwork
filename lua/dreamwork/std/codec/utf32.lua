---@class dreamwork.std
local std = dreamwork.std

local ffi = std.ffi

local ffi_cast, ffi_copy, ffi_string
local uint8_ptr_t, uint8_array_t

if ffi ~= nil then
    ffi_cast, ffi_copy, ffi_string = ffi.cast, ffi.copy, ffi.string
    uint8_ptr_t, uint8_array_t = ffi.typeof( "const uint8_t *" ), ffi.typeof( "uint8_t[?]" )
end

local raw = std.raw
local raw_select = raw.select

local string = std.string
local string_sub = string.sub
local string_char, string_byte = string.char, string.byte

local math = std.math
local math_relative = math.relative
local math_range = math.range
local math_min, math_max = math.min, math.max
local math_ceil = math.ceil

local rbit = raw.bit
local rbit_band, rbit_rshift = rbit.band, rbit.rshift

local table = std.table
local table_unpack = table.unpack
local table_concat = table.concat

local error = std.error


--- [SHARED AND MENU]
---
--- The utf32 library provides functions for the manipulation of UTF-32 strings.
---
--- Positions are in bytes, except `utf32.sub`, which takes code point positions.
--- Code units are aligned to the start of the string, all functions use little-endian
--- byte order unless `big_endian` is `true`, a byte order mark is not handled.
---
--- Functions that take `lax` raise an error on the first invalid code unit (a surrogate, a value above U+10FFFF
--- or a truncated tail), unless `lax` is `true`; in lax mode each invalid code unit counts as one code point, decoded as U+FFFD.
---
---@class dreamwork.std.utf32
local utf32 = {}
std.utf32 = utf32

---@alias dreamwork.std.utf32.ErrorCode
---| 1 # Unexpected end of string (length is not a multiple of 4).
---| 2 # UTF-16 surrogate code point.
---| 3 # Code point exceeds U+10FFFF.
---| 4 # Not a valid code point (negative).

---@type table<dreamwork.std.utf32.ErrorCode, string>
local error_messages = {
    [ 1 ] = "unexpected end of string",
    [ 2 ] = "UTF-16 surrogate code point",
    [ 3 ] = "code point exceeds U+10FFFF",
    [ 4 ] = "not a valid code point"
}

---@param error_position integer
---@param error_code dreamwork.std.utf32.ErrorCode
---@param stack_level integer The error level, relative to this function.
local function invalid_sequence( error_position, error_code, stack_level )
    error( string.format( "invalid UTF-32 sequence at position %d (%s)", error_position, error_messages[ error_code ] ), stack_level )
end

---@param utf32_codepoint integer
---@param stack_level integer The error level, relative to this function.
local function invalid_codepoint( utf32_codepoint, stack_level )
    if utf32_codepoint < 0 then
        error( string.format( "invalid UTF-32 code point '-0x%X' (%s)", -utf32_codepoint, error_messages[ 4 ] ), stack_level )
    elseif utf32_codepoint > 0x10FFFF then
        error( string.format( "invalid UTF-32 code point '0x%X' (%s)", utf32_codepoint, error_messages[ 3 ] ), stack_level )
    else
        error( string.format( "invalid UTF-32 code point '0x%X' (%s)", utf32_codepoint, error_messages[ 2 ] ), stack_level )
    end
end

--- Must be tail-called from `decode`, so `decode`'s frame is gone when the error is raised.
---
---@param strict boolean | nil
---@param stack_level integer | nil
---@param sequence_length integer
---@param error_position integer
---@param error_code dreamwork.std.utf32.ErrorCode
---@return nil utf32_codepoint
---@return integer sequence_length
---@return integer error_position
---@return dreamwork.std.utf32.ErrorCode error_code
local function invalid( strict, stack_level, sequence_length, error_position, error_code )
    if strict then
        invalid_sequence( error_position, error_code, (stack_level or 1) + 2 )
    end

    return nil, sequence_length, error_position, error_code
end

--- Validates and decodes one UTF-32 code unit.
---
--- On an invalid sequence raises an error if `strict` is `true`, otherwise returns
--- `nil` as code point and the number of bytes to skip (at least `1`) as sequence length.
---
---@param utf32_string string
---@param index integer
---@param end_index integer The last byte position that belongs to the sequence range.
---@param strict boolean?
---@param stack_level integer? The error level, relative to the caller of `decode`.
---@param big_endian boolean?
---@return integer | nil utf32_codepoint
---@return integer sequence_length
---@return integer | nil error_position
---@return dreamwork.std.utf32.ErrorCode | nil error_code
local function decode( utf32_string, index, end_index, strict, stack_level, big_endian )
    local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( utf32_string, index, math_min( index + 3, end_index ) )

    if uint8_4 == nil then
        return invalid( strict, stack_level, math_max( 1, end_index - index + 1 ), index, 1 )
    end

    local utf32_codepoint

    if big_endian then
        utf32_codepoint = ((uint8_1 * 0x100 + uint8_2) * 0x100 + uint8_3) * 0x100 + uint8_4
    else
        utf32_codepoint = ((uint8_4 * 0x100 + uint8_3) * 0x100 + uint8_2) * 0x100 + uint8_1
    end

    if utf32_codepoint > 0x10FFFF then
        return invalid( strict, stack_level, 4, index, 3 )
    elseif utf32_codepoint >= 0xD800 and utf32_codepoint <= 0xDFFF then
        return invalid( strict, stack_level, 4, index, 2 )
    end

    return utf32_codepoint, 4, nil, nil
end

local encode
do

    ---@type table<integer, string>
    local le_cache = {}

    ---@type table<integer, string>
    local be_cache = {}

    ---@param utf32_codepoint integer
    ---@param strict boolean If `false`, invalid code points are encoded as U+FFFD.
    ---@param stack_level integer?
    ---@param big_endian boolean?
    ---@return string utf32_sequence
    function encode( utf32_codepoint, strict, stack_level, big_endian )
        local cache = big_endian and be_cache or le_cache

        local utf32_sequence = cache[ utf32_codepoint ]
        if utf32_sequence ~= nil then
            return utf32_sequence
        end

        if utf32_codepoint < 0 or utf32_codepoint > 0x10FFFF or (utf32_codepoint >= 0xD800 and utf32_codepoint <= 0xDFFF) then
            if strict then
                invalid_codepoint( utf32_codepoint, (stack_level or 1) + 2 )
            end

            return big_endian and "\0\0\xFF\xFD" or "\xFD\xFF\0\0"
        end

        local uint8_1 = rbit_rshift( utf32_codepoint, 16 )
        local uint8_2 = rbit_band( rbit_rshift( utf32_codepoint, 8 ), 0xFF )
        local uint8_3 = rbit_band( utf32_codepoint, 0xFF )

        if big_endian then
            utf32_sequence = string_char( 0, uint8_1, uint8_2, uint8_3 )
        else
            utf32_sequence = string_char( uint8_3, uint8_2, uint8_1, 0 )
        end

        cache[ utf32_codepoint ] = utf32_sequence
        return utf32_sequence
    end

end

--- [SHARED AND MENU]
---
--- Encodes a single code point into a UTF-32 sequence of 1 code unit (4 bytes).
---
---@param utf32_codepoint integer The code point to encode.
---@param lax boolean? If `true`, invalid code points (surrogates, negative or above `U+10FFFF`) are encoded as `U+FFFD` instead of raising an error.
---@param big_endian boolean? Whether to encode as big-endian.
---@param stack_level integer? The error level, relative to the caller, `1` (default) blames the caller of this function.
---@return string utf32_sequence The UTF-32 sequence.
---@nodiscard
function utf32.encode( utf32_codepoint, lax, big_endian, stack_level )
    return encode( utf32_codepoint, lax ~= true, stack_level or 1, big_endian )
end

--- [SHARED AND MENU]
---
--- Decodes a single UTF-32 sequence starting at the given byte position.
---
--- In lax mode invalid sequences do not raise an error, `nil` is returned as the code point
--- together with the number of bytes to skip, the position of the sequence and the error code.
---
---@param utf32_string string The UTF-32 string to decode from.
---@param index integer? The position of the sequence in bytes, `1` by default.
---@param end_index integer? The last byte that can be read, the end of the string by default; a sequence cut by it is invalid.
---@param lax boolean? If `true`, invalid sequences are returned as `nil` instead of raising an error.
---@param big_endian boolean? Whether the string is big-endian.
---@param stack_level integer? The error level, relative to the caller, `1` (default) blames the caller of this function.
---@return integer | nil utf32_codepoint The decoded code point, or `nil` if the sequence is invalid.
---@return integer sequence_length The length of the sequence in bytes, at least `1`.
---@return integer | nil error_position The position of the invalid sequence, `nil` if the sequence is valid.
---@return dreamwork.std.utf32.ErrorCode | nil error_code The error code, `nil` if the sequence is valid.
---@nodiscard
function utf32.decode( utf32_string, index, end_index, lax, big_endian, stack_level )
    return decode( utf32_string, index or 1, end_index or #utf32_string, lax ~= true, stack_level or 1, big_endian )
end

--- [SHARED AND MENU]
---
--- Returns the number of code points that start between byte positions `start_position` and `end_position` (both inclusive).
---
---@param utf32_string string The UTF-32 string to count the code points of.
---@param start_position integer? The position to start from in bytes, `1` by default.
---@param end_position integer? The position to end at in bytes, the end of the string by default; a sequence cut by it is invalid.
---@param lax boolean? If `true`, every invalid sequence counts as one code point instead of raising an error.
---@param big_endian boolean? Whether the string is big-endian.
---@return integer utf32_codepoint_count The number of code points.
---@nodiscard
function utf32.len( utf32_string, start_position, end_position, lax, big_endian )
    local start_index, end_index = math_range( #utf32_string, start_position, end_position )

    if lax == true then
        -- fixed width: every 4 bytes are one code point, a truncated tail counts as one more
        return math_max( 0, math_ceil( (end_index - start_index + 1) / 4 ) )
    end

    local utf32_codepoint_count = 0

    while start_index <= end_index do
        local _, utf32_sequence_length = decode( utf32_string, start_index, end_index, true, 2, big_endian )
        start_index = start_index + utf32_sequence_length
        utf32_codepoint_count = utf32_codepoint_count + 1
    end

    return utf32_codepoint_count
end

---@param utf32_string string
---@param start_position integer
---@param end_position integer
---@param strict boolean
---@param stack_level integer The error level, relative to the caller of `unpack`.
---@param big_endian boolean?
---@return integer[] utf32_codepoints
---@return integer utf32_codepoint_count
local function unpack( utf32_string, start_position, end_position, strict, stack_level, big_endian )
    ---@type integer[]
    local utf32_codepoints = {}
    local utf32_codepoint_count = 0

    stack_level = stack_level + 1

    while start_position <= end_position do
        local utf32_codepoint, utf32_sequence_length = decode( utf32_string, start_position, end_position, strict, stack_level, big_endian )
        start_position = start_position + utf32_sequence_length

        utf32_codepoint_count = utf32_codepoint_count + 1
        utf32_codepoints[ utf32_codepoint_count ] = utf32_codepoint or 0xFFFD
    end

    return utf32_codepoints, utf32_codepoint_count
end

local pack

if ffi == nil then

    ---@param utf32_codepoints integer[]
    ---@param utf32_codepoint_count integer
    ---@param strict boolean
    ---@param stack_level integer The error level, relative to the caller of `pack`.
    ---@param big_endian boolean?
    ---@return string utf32_string
    function pack( utf32_codepoints, utf32_codepoint_count, strict, stack_level, big_endian )
        ---@type string[]
        local utf32_sequences = {}

        stack_level = stack_level + 1

        for index = 1, utf32_codepoint_count, 1 do
            utf32_sequences[ index ] = encode( utf32_codepoints[ index ], strict, stack_level, big_endian )
        end

        return table_concat( utf32_sequences, "", 1, utf32_codepoint_count )
    end

else

    ---@param utf32_codepoints integer[]
    ---@param utf32_codepoint_count integer
    ---@param strict boolean
    ---@param stack_level integer The error level, relative to the caller of `pack`.
    ---@param big_endian boolean?
    ---@return string utf32_string
    function pack( utf32_codepoints, utf32_codepoint_count, strict, stack_level, big_endian )
        local buffer = uint8_array_t( utf32_codepoint_count * 4 )
        local length = 0

        stack_level = stack_level + 1

        for index = 1, utf32_codepoint_count, 1 do
            local utf32_codepoint = utf32_codepoints[ index ]

            if utf32_codepoint < 0 or utf32_codepoint > 0x10FFFF or (utf32_codepoint >= 0xD800 and utf32_codepoint <= 0xDFFF) then
                -- raises in strict mode, U+FFFD otherwise
                ffi_copy( buffer + length, encode( utf32_codepoint, strict, stack_level, big_endian ), 4 )
            else
                local uint8_1 = rbit_rshift( utf32_codepoint, 16 )
                local uint8_2 = rbit_band( rbit_rshift( utf32_codepoint, 8 ), 0xFF )
                local uint8_3 = rbit_band( utf32_codepoint, 0xFF )

                if big_endian then
                    buffer[ length ], buffer[ length + 1 ], buffer[ length + 2 ], buffer[ length + 3 ] = 0, uint8_1, uint8_2, uint8_3
                else
                    buffer[ length ], buffer[ length + 1 ], buffer[ length + 2 ], buffer[ length + 3 ] = uint8_3, uint8_2, uint8_1, 0
                end
            end

            length = length + 4
        end

        return ffi_string( buffer, length )
    end

end

--- [SHARED AND MENU]
---
--- Decodes a UTF-32 string into a table of code points.
---
---@param utf32_string string The UTF-32 string to decode.
---@param start_position integer? The position to start from in bytes, `1` by default.
---@param end_position integer? The position to end at in bytes, the end of the string by default; a sequence cut by it is invalid.
---@param lax boolean? If `true`, invalid sequences are decoded as U+FFFD instead of raising an error.
---@param big_endian boolean? Whether the string is big-endian.
---@return integer[] utf32_codepoints The code points.
---@return integer utf32_codepoint_count The number of code points.
---@nodiscard
function utf32.unpack( utf32_string, start_position, end_position, lax, big_endian )
    local start_index, end_index = math_range( #utf32_string, start_position, end_position )
    return unpack( utf32_string, start_index, end_index, lax ~= true, 1, big_endian )
end

--- [SHARED AND MENU]
---
--- Encodes a table of code points into a UTF-32 string.
---
---@param utf32_codepoints integer[] The code points to encode.
---@param utf32_codepoint_count integer? The number of code points to encode, `#utf32_codepoints` by default.
---@param lax boolean? If `true`, invalid code points (surrogates, negative or above U+10FFFF) are encoded as U+FFFD instead of raising an error.
---@param big_endian boolean? Whether to produce a big-endian string.
---@return string utf32_string The UTF-32 string.
---@nodiscard
function utf32.pack( utf32_codepoints, utf32_codepoint_count, lax, big_endian )
    return pack( utf32_codepoints, utf32_codepoint_count or #utf32_codepoints, lax ~= true, 1, big_endian )
end

--- [SHARED AND MENU]
---
--- Encodes code points into a little-endian UTF-32 string.
---
--- This functions similarly to `string.char`, invalid code points raise an error, use `utf32.pack` for big-endian strings.
---
---@param a integer? The first code point.
---@param b integer? The second code point.
---@param ... integer The rest of the code points.
---@return string utf32_string The UTF-32 string.
---@nodiscard
function utf32.char( a, b, ... )
    if b == nil then
        if a == nil then
            return ""
        end

        return encode( a, true, 1 )
    end

    return pack( { a, b, ... }, raw_select( "#", a, b, ... ), true, 1 )
end

--- [SHARED AND MENU]
---
--- Returns the code points of all characters that start between byte positions
--- `start_position` and `end_position` (both inclusive).
---
--- This functions similarly to `string.byte`, use `utf32.unpack` for long strings.
---
--- The last code point is decoded completely even if it ends after `end_position`.
---
---@param utf32_string string The UTF-32 string to decode.
---@param start_position integer? The position to start from in bytes, `1` by default.
---@param end_position integer? The position to end at in bytes, `start_position` by default.
---@param lax boolean? If `true`, invalid sequences are decoded as U+FFFD instead of raising an error.
---@param big_endian boolean? Whether the string is big-endian.
---@return integer ... The code points.
---@nodiscard
function utf32.codepoint( utf32_string, start_position, end_position, lax, big_endian )
    local str_length = #utf32_string

    local start_index, end_index = math_range( str_length, start_position, end_position or start_position or 1 )

    if start_index > end_index then
        return
    end

    local strict = lax ~= true

    local utf32_codepoint, utf32_sequence_length = decode( utf32_string, start_index, str_length, strict, 2, big_endian )
    start_index = start_index + utf32_sequence_length

    if start_index > end_index then
        return utf32_codepoint or 0xFFFD
    end

    ---@type integer[]
    local utf32_codepoints = { utf32_codepoint or 0xFFFD }
    local utf32_codepoint_count = 1

    repeat
        utf32_codepoint, utf32_sequence_length = decode( utf32_string, start_index, str_length, strict, 2, big_endian )
        start_index = start_index + utf32_sequence_length

        utf32_codepoint_count = utf32_codepoint_count + 1
        utf32_codepoints[ utf32_codepoint_count ] = utf32_codepoint or 0xFFFD
    until start_index > end_index

    return table_unpack( utf32_codepoints, 1, utf32_codepoint_count )
end

--- Raises an error on the first invalid code unit at `first_index`, `first_index + step`, ... `last_index`.
---
--- Checks only the 3 high bytes, `decode` runs just to raise the error.
---
---@param utf32_string string
---@param first_index integer
---@param last_index integer
---@param step integer `4` or `-4`.
---@param str_length integer
---@param big_endian boolean?
local function validate( utf32_string, first_index, last_index, step, str_length, big_endian )
    for index = first_index, last_index, step do
        -- from the most significant byte, `nil` for a truncated tail
        local uint8_1, uint8_2, uint8_3

        if index + 3 <= str_length then
            if big_endian then
                uint8_1, uint8_2, uint8_3 = string_byte( utf32_string, index, index + 2 )
            else
                uint8_3, uint8_2, uint8_1 = string_byte( utf32_string, index + 1, index + 3 )
            end
        end

        -- above U+10FFFF, a surrogate or truncated
        if uint8_1 ~= 0 or uint8_2 > 0x10 or (uint8_2 == 0 and uint8_3 >= 0xD8 and uint8_3 <= 0xDF) then
            decode( utf32_string, index, str_length, true, 3, big_endian )
        end
    end
end

--- [SHARED AND MENU]
---
--- Returns the byte positions where the `n`-th code point, counting from byte `position`, starts and ends.
---
--- This functions similarly to `utf8.offset` from Lua 5.5:
--- * `n > 0` counts forward, `1` is the code point that starts at `position`.
--- * `n < 0` counts backward, `-1` is the code point right before `position`.
--- * `n = 0` returns the code point that contains byte `position`.
---
--- `#utf32_string + 1` is the position right after the last code point and is returned as `#utf32_string + 1, #utf32_string + 1`.
---
--- Code units are aligned to the start of the string, a truncated tail (1 to 3 bytes) is one code point.
--- In lax mode positions are computed without reading the string, otherwise any invalid code unit
--- that is walked over raises an error.
---
--- Raises an error if `n ~= 0` and `position` points inside a code point.
---
---@param utf32_string string The UTF-32 string to search in.
---@param n integer The number of the code point, relative to `position`.
---@param position integer? The byte position to count from, `1` if `n >= 0`, otherwise `#utf32_string + 1`, negative positions count from the end of the string, out of range positions are clamped.
---@param lax boolean? If `true`, invalid code units count as code points instead of raising an error.
---@param big_endian boolean? Whether the string is big-endian.
---@return integer | nil start_position The position of the first byte of the code point, or `nil` if the string has no such code point.
---@return integer | nil end_position The position of the last byte of the code point, or `nil` if the string has no such code point.
---@nodiscard
function utf32.offset( utf32_string, n, position, lax, big_endian )
    local str_length = #utf32_string
    local end_of_string = str_length + 1

    if position == nil then
        position = n < 0 and end_of_string or 1
    elseif position < 0 then
        position = math_relative( position, str_length )
    elseif position == 0 then
        position = 1
    elseif position > end_of_string then
        position = end_of_string
    end

    local strict = lax ~= true

    if n == 0 then
        if position == end_of_string then
            return position, position
        end

        local start_index = position - (position - 1) % 4

        if strict then
            decode( utf32_string, start_index, str_length, true, 2, big_endian )
        end

        return start_index, math_min( start_index + 3, str_length )
    end

    if position ~= end_of_string and (position - 1) % 4 ~= 0 then
        error( string.format( "initial position %d is inside a code point", position ), 2 )
    end

    local start_index

    if n > 0 then
        -- fixed width: the n-th code point is always 4 * (n - 1) bytes further
        start_index = position + (n - 1) * 4

        if strict then
            validate( utf32_string, position, math_min( start_index, str_length ), 4, str_length, big_endian )
        end

        if start_index > str_length then
            -- the position right after the last code point, only if the previous one exists
            if start_index - 4 < end_of_string then
                return end_of_string, end_of_string
            end

            return nil, nil
        end
    else
        -- zero-based number of the code point to return
        local utf32_codepoint_count = math_ceil( (position - 1) / 4 )
        local target = utf32_codepoint_count + n

        if strict then
            validate( utf32_string, (utf32_codepoint_count - 1) * 4 + 1, math_max( target, 0 ) * 4 + 1, -4, str_length, big_endian )
        end

        if target < 0 then
            return nil, nil
        end

        start_index = target * 4 + 1
    end

    return start_index, math_min( start_index + 3, str_length )
end

--- [SHARED AND MENU]
---
--- Returns the substring between code points `start_position` and `end_position` (both inclusive).
---
--- This functions similarly to `string.sub`, but positions are in code points, negative positions count from the end of the string.
---
--- The bytes are copied as is, in lax mode invalid sequences are kept (each counts as one code point).
---
---@param utf32_string string The UTF-32 string to get the substring of.
---@param start_position integer? The position of the first code point, `1` by default.
---@param end_position integer? The position of the last code point, the last code point of the string by default.
---@param lax boolean? If `true`, every invalid sequence counts as one code point instead of raising an error.
---@param big_endian boolean? Whether the string is big-endian.
---@return string utf32_sub The substring.
---@nodiscard
function utf32.sub( utf32_string, start_position, end_position, lax, big_endian )
    local str_length = #utf32_string
    if str_length == 0 then
        return utf32_string
    end

    if start_position == nil then
        start_position = 1
    end

    local strict = lax ~= true

    if not strict then
        -- fixed width: code point positions map straight to byte positions
        local utf32_codepoint_count = math_ceil( str_length / 4 )

        if start_position < 0 then
            start_position = utf32_codepoint_count + start_position + 1
        end

        if end_position == nil then
            end_position = utf32_codepoint_count
        elseif end_position < 0 then
            end_position = utf32_codepoint_count + end_position + 1
        end

        if start_position < 1 then
            start_position = 1
        end

        if end_position < start_position then
            return ""
        end

        return string_sub( utf32_string, (start_position - 1) * 4 + 1, end_position * 4 )
    end

    if start_position < 0 or (end_position ~= nil and end_position < 0) then
        local utf32_codepoint_count = 0
        local index = 1

        while index <= str_length do
            local _, utf32_sequence_length = decode( utf32_string, index, str_length, strict, 2, big_endian )
            index = index + utf32_sequence_length
            utf32_codepoint_count = utf32_codepoint_count + 1
        end

        if start_position < 0 then
            start_position = utf32_codepoint_count + start_position + 1
        end

        if end_position ~= nil and end_position < 0 then
            end_position = utf32_codepoint_count + end_position + 1
        end
    end

    if start_position < 1 then
        start_position = 1
    end

    if end_position ~= nil and end_position < start_position then
        return ""
    end

    ---@type integer | nil
    local utf32_start

    local utf32_codepoint_count = 0
    local index = 1

    while index <= str_length do
        local _, utf32_sequence_length = decode( utf32_string, index, str_length, strict, 2, big_endian )

        utf32_codepoint_count = utf32_codepoint_count + 1

        if utf32_codepoint_count == start_position then
            utf32_start = index
        end

        if utf32_codepoint_count == end_position then
            return string_sub( utf32_string, utf32_start or 1, index + (utf32_sequence_length - 1) )
        end

        index = index + utf32_sequence_length
    end

    if utf32_start == nil then
        return ""
    end

    return string_sub( utf32_string, utf32_start, str_length )
end

if ffi == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the code points between byte positions `start_position` and `end_position` in reverse order.
    ---
    --- This functions similarly to `string.reverse`, but the bytes of each code point keep their order.
    ---
    ---@param utf32_string string The UTF-32 string to reverse.
    ---@param start_position integer? The position to start from in bytes, `1` by default.
    ---@param end_position integer? The position to end at in bytes, the end of the string by default; a sequence cut by it is invalid.
    ---@param lax boolean? If `true`, invalid sequences are replaced with U+FFFD instead of raising an error.
    ---@param big_endian boolean? Whether the string is big-endian.
    ---@return string utf32_reversed The reversed UTF-32 string.
    ---@nodiscard
    function utf32.reverse( utf32_string, start_position, end_position, lax, big_endian )
        local start_index, end_index = math_range( #utf32_string, start_position, end_position )

        local strict = lax ~= true

        ---@type string[]
        local utf32_sequences = {}
        local utf32_sequence_count = 0

        while start_index <= end_index do
            local utf32_codepoint, utf32_sequence_length = decode( utf32_string, start_index, end_index, strict, 2, big_endian )
            utf32_sequence_count = utf32_sequence_count + 1

            if utf32_codepoint == nil then
                utf32_sequences[ utf32_sequence_count ] = big_endian and "\0\0\xFF\xFD" or "\xFD\xFF\0\0"
            else
                utf32_sequences[ utf32_sequence_count ] = string_sub( utf32_string, start_index, start_index + (utf32_sequence_length - 1) )
            end

            start_index = start_index + utf32_sequence_length
        end

        local left, right = 1, utf32_sequence_count

        while left < right do
            utf32_sequences[ left ], utf32_sequences[ right ] = utf32_sequences[ right ], utf32_sequences[ left ]
            left, right = left + 1, right - 1
        end

        return table_concat( utf32_sequences, "", 1, utf32_sequence_count )
    end

else

    ---@param utf32_string string
    ---@param start_position integer?
    ---@param end_position integer?
    ---@param lax boolean?
    ---@param big_endian boolean?
    ---@return string utf32_reversed
    ---@nodiscard
    function utf32.reverse( utf32_string, start_position, end_position, lax, big_endian )
        local start_index, end_index = math_range( #utf32_string, start_position, end_position )

        if start_index > end_index then
            return ""
        end

        local strict = lax ~= true
        local source = ffi_cast( uint8_ptr_t, utf32_string )

        -- in lax mode a truncated tail of 1-3 bytes turns into a 4-byte U+FFFD
        local capacity = end_index - start_index + 1
        if not strict then
            capacity = capacity + 3
        end

        -- filled from the end towards the start
        local buffer = uint8_array_t( capacity )
        local length = capacity

        while start_index <= end_index do
            local index = start_index - 1

            local utf32_codepoint = -1
            if start_index + 3 <= end_index then
                if big_endian then
                    utf32_codepoint = ((source[ index ] * 0x100 + source[ index + 1 ]) * 0x100 + source[ index + 2 ]) * 0x100 + source[ index + 3 ]
                else
                    utf32_codepoint = ((source[ index + 3 ] * 0x100 + source[ index + 2 ]) * 0x100 + source[ index + 1 ]) * 0x100 + source[ index ]
                end
            end

            if utf32_codepoint >= 0 and utf32_codepoint <= 0x10FFFF and (utf32_codepoint < 0xD800 or utf32_codepoint > 0xDFFF) then
                length = length - 4
                ffi_copy( buffer + length, source + index, 4 )
                start_index = start_index + 4
            else
                -- raises in strict mode
                local _, utf32_sequence_length = decode( utf32_string, start_index, end_index, strict, 2, big_endian )

                length = length - 4
                ffi_copy( buffer + length, big_endian and "\0\0\xFF\xFD" or "\xFD\xFF\0\0", 4 )

                start_index = start_index + utf32_sequence_length
            end
        end

        return ffi_string( buffer + length, capacity - length )
    end

end

--- [SHARED AND MENU]
---
--- Returns a well-formed copy of a UTF-32 string, every invalid sequence (surrogates, values above U+10FFFF, a truncated tail) is replaced with `replacement_str`.
---
--- This is **not** Unicode normalization (NFC, NFD, NFKC, NFKD): valid sequences are copied as is.
---
--- Only the range between `start_position` and `end_position` is returned, a sequence cut by `end_position` is invalid.
---
---@param utf32_string string The UTF-32 string to sanitize.
---@param replacement_str string? The string to replace invalid sequences with, U+FFFD in the string's byte order by default.
---@param start_position integer? The position to start from in bytes, `1` by default.
---@param end_position integer? The position to end at in bytes, the end of the string by default.
---@param big_endian boolean? Whether the string is big-endian.
---@return string utf32_normalized The well-formed UTF-32 string.
---@nodiscard
function utf32.normalize( utf32_string, replacement_str, start_position, end_position, big_endian )
    local start_index, end_index = math_range( #utf32_string, start_position, end_position )

    if replacement_str == nil then
        replacement_str = big_endian and "\0\0\xFF\xFD" or "\xFD\xFF\0\0"
    end

    ---@type string[]
    local segments = {}
    local segment_count = 0

    -- start of the current run of valid sequences
    local valid_start = start_index

    while start_index <= end_index do
        local utf32_codepoint, utf32_sequence_length = decode( utf32_string, start_index, end_index, false, nil, big_endian )

        if utf32_codepoint == nil then
            if valid_start < start_index then
                segment_count = segment_count + 1
                segments[ segment_count ] = string_sub( utf32_string, valid_start, start_index - 1 )
            end

            segment_count = segment_count + 1
            segments[ segment_count ] = replacement_str

            valid_start = start_index + utf32_sequence_length
        end

        start_index = start_index + utf32_sequence_length
    end

    if segment_count == 0 then
        return string_sub( utf32_string, valid_start, end_index )
    end

    if valid_start <= end_index then
        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( utf32_string, valid_start, end_index )
    end

    return table_concat( segments, "", 1, segment_count )
end

do

    --- Stateless, so nested and interleaved loops are safe: the next position is
    --- derived from the control variable by re-scanning the previous sequence.
    ---
    --- Must be tail-called by the iterators, so errors point at the `for` loop.
    ---
    ---@param utf32_string string
    ---@param index integer The position of the previous code point, `0` before the first one.
    ---@param strict boolean
    ---@param big_endian boolean
    ---@return integer | nil
    ---@return integer | nil
    local function iterate( utf32_string, index, strict, big_endian )
        local str_length = #utf32_string

        if index == 0 then
            index = 1
        else
            local _, utf32_sequence_length = decode( utf32_string, index, str_length, false, nil, big_endian )
            index = index + utf32_sequence_length
        end

        if index > str_length then
            return nil, nil
        end

        local utf32_codepoint = decode( utf32_string, index, str_length, strict, 2, big_endian )
        if utf32_codepoint == nil then
            utf32_codepoint = 0xFFFD
        end

        return index, utf32_codepoint
    end

    local iterators = {
        [ true ] = {
            [ true ] = function( utf32_string, index ) return iterate( utf32_string, index, true, true ) end,
            [ false ] = function( utf32_string, index ) return iterate( utf32_string, index, true, false ) end
        },
        [ false ] = {
            [ true ] = function( utf32_string, index ) return iterate( utf32_string, index, false, true ) end,
            [ false ] = function( utf32_string, index ) return iterate( utf32_string, index, false, false ) end
        }
    }

    --- [SHARED AND MENU]
    ---
    --- Returns an iterator function that iterates over the code points of a UTF-32 string.
    ---
    --- Yields the byte position and the code point of every character, like `utf8.codes`.
    ---
    --- Invalid sequences raise an error, or yield U+FFFD if `lax` is `true`.
    ---
    ---@param utf32_string string The UTF-32 string to iterate over.
    ---@param lax boolean? If `true`, invalid sequences are yielded as U+FFFD instead of raising an error.
    ---@param big_endian boolean? Whether the string is big-endian.
    ---@return ( fun( utf32_string: string, index: integer ): integer | nil, integer | nil ), string, integer
    ---@nodiscard
    function utf32.codes( utf32_string, lax, big_endian )
        return iterators[ lax ~= true ][ big_endian == true ], utf32_string, 0
    end

end
