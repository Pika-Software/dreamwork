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
local math_range = math.range
local math_relative = math.relative
local math_min = math.min

local rbit = raw.bit
local rbit_band, rbit_rshift = rbit.band, rbit.rshift

local table = std.table
local table_unpack = table.unpack
local table_concat = table.concat

local error = std.error


--- [SHARED AND MENU]
---
--- The utf16 library provides functions for the manipulation of UTF-16 strings.
---
--- Positions are in bytes, except `utf16.sub`, which takes code point positions.
--- Code units are aligned to the start of the string, all functions use little-endian
--- byte order unless `big_endian` is `true`, a byte order mark is not handled.
---
--- Functions that take `lax` raise an error on the first invalid sequence (an unpaired surrogate
--- or an odd trailing byte), unless `lax` is `true`; in lax mode each invalid sequence counts as one code point, decoded as U+FFFD.
---
---@class dreamwork.std.utf16
local utf16 = {}
std.utf16 = utf16

---@alias dreamwork.std.utf16.ErrorCode
---| 1 # Unexpected end of string (odd number of bytes).
---| 2 # Unpaired high surrogate.
---| 3 # Unpaired low surrogate.
---| 4 # UTF-16 surrogate code point.
---| 5 # Code point exceeds U+10FFFF.
---| 6 # Not a valid code point (negative).

---@type table<dreamwork.std.utf16.ErrorCode, string>
local error_messages = {
    [ 1 ] = "unexpected end of string",
    [ 2 ] = "unpaired high surrogate",
    [ 3 ] = "unpaired low surrogate",
    [ 4 ] = "UTF-16 surrogate code point",
    [ 5 ] = "code point exceeds U+10FFFF",
    [ 6 ] = "not a valid code point"
}

---@param error_position integer
---@param error_code dreamwork.std.utf16.ErrorCode
---@param stack_level integer The error level, relative to this function.
local function invalid_sequence( error_position, error_code, stack_level )
    error( string.format( "invalid UTF-16 sequence at position %d (%s)", error_position, error_messages[ error_code ] ), stack_level )
end

---@param utf16_codepoint integer
---@param stack_level integer The error level, relative to this function.
local function invalid_codepoint( utf16_codepoint, stack_level )
    if utf16_codepoint < 0 then
        error( string.format( "invalid UTF-16 code point '-0x%X' (%s)", -utf16_codepoint, error_messages[ 6 ] ), stack_level )
    elseif utf16_codepoint > 0x10FFFF then
        error( string.format( "invalid UTF-16 code point '0x%X' (%s)", utf16_codepoint, error_messages[ 5 ] ), stack_level )
    else
        error( string.format( "invalid UTF-16 code point '0x%X' (%s)", utf16_codepoint, error_messages[ 4 ] ), stack_level )
    end
end

--- Must be tail-called from `decode`, so `decode`'s frame is gone when the error is raised.
---
---@param strict boolean | nil
---@param stack_level integer | nil
---@param sequence_length integer
---@param error_position integer
---@param error_code dreamwork.std.utf16.ErrorCode
---@return nil utf16_codepoint
---@return integer sequence_length
---@return integer error_position
---@return dreamwork.std.utf16.ErrorCode error_code
local function invalid( strict, stack_level, sequence_length, error_position, error_code )
    if strict then
        invalid_sequence( error_position, error_code, (stack_level or 1) + 2 )
    end

    return nil, sequence_length, error_position, error_code
end

--- Validates and decodes one UTF-16 sequence (one code unit or a surrogate pair).
---
--- On an invalid sequence raises an error if `strict` is `true`, otherwise returns
--- `nil` as code point and the number of bytes to skip (at least `1`) as sequence length.
---
---@param utf16_string string
---@param index integer
---@param end_index integer The last byte position that belongs to the sequence range.
---@param strict boolean?
---@param stack_level integer? The error level, relative to the caller of `decode`.
---@param big_endian boolean?
---@return integer | nil utf16_codepoint
---@return integer sequence_length
---@return integer | nil error_position
---@return dreamwork.std.utf16.ErrorCode | nil error_code
local function decode( utf16_string, index, end_index, strict, stack_level, big_endian )
    local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( utf16_string, index, math_min( index + 3, end_index ) )

    if uint8_2 == nil then
        return invalid( strict, stack_level, 1, index, 1 )
    end

    local uint16_1
    if big_endian then
        uint16_1 = (uint8_1 * 0x100) + uint8_2
    else
        uint16_1 = (uint8_2 * 0x100) + uint8_1
    end

    if uint16_1 < 0xD800 or uint16_1 > 0xDFFF then
        return uint16_1, 2, nil, nil
    elseif uint16_1 > 0xDBFF then
        return invalid( strict, stack_level, 2, index, 3 )
    elseif uint8_4 == nil then
        return invalid( strict, stack_level, 2, index, 2 )
    end

    local uint16_2
    if big_endian then
        uint16_2 = (uint8_3 * 0x100) + uint8_4
    else
        uint16_2 = (uint8_4 * 0x100) + uint8_3
    end

    if uint16_2 < 0xDC00 or uint16_2 > 0xDFFF then
        return invalid( strict, stack_level, 2, index, 2 )
    end

    return 0x10000 + ((uint16_1 - 0xD800) * 0x400) + (uint16_2 - 0xDC00), 4, nil, nil
end

local encode
do

    ---@type table<integer, string>
    local le_cache = {}

    ---@type table<integer, string>
    local be_cache = {}

    ---@param utf16_codepoint integer
    ---@param strict boolean If `false`, invalid code points are encoded as U+FFFD.
    ---@param stack_level integer?
    ---@param big_endian boolean?
    ---@return string utf16_sequence
    function encode( utf16_codepoint, strict, stack_level, big_endian )
        local cache = big_endian and be_cache or le_cache

        local utf16_sequence = cache[ utf16_codepoint ]
        if utf16_sequence ~= nil then
            return utf16_sequence
        end

        if utf16_codepoint < 0 or utf16_codepoint > 0x10FFFF or (utf16_codepoint >= 0xD800 and utf16_codepoint <= 0xDFFF) then
            if strict then
                invalid_codepoint( utf16_codepoint, (stack_level or 1) + 2 )
            end

            return big_endian and "\xFF\xFD" or "\xFD\xFF"
        end

        if utf16_codepoint < 0x10000 then
            local uint8_1, uint8_2 = rbit_rshift( utf16_codepoint, 8 ), rbit_band( utf16_codepoint, 0xFF )

            if big_endian then
                utf16_sequence = string_char( uint8_1, uint8_2 )
            else
                utf16_sequence = string_char( uint8_2, uint8_1 )
            end
        else
            local value = utf16_codepoint - 0x10000
            local high_surrogate = 0xD800 + rbit_rshift( value, 10 )
            local low_surrogate = 0xDC00 + rbit_band( value, 0x3FF )

            if big_endian then
                utf16_sequence = string_char(
                    rbit_rshift( high_surrogate, 8 ), rbit_band( high_surrogate, 0xFF ),
                    rbit_rshift( low_surrogate, 8 ), rbit_band( low_surrogate, 0xFF )
                )
            else
                utf16_sequence = string_char(
                    rbit_band( high_surrogate, 0xFF ), rbit_rshift( high_surrogate, 8 ),
                    rbit_band( low_surrogate, 0xFF ), rbit_rshift( low_surrogate, 8 )
                )
            end
        end

        cache[ utf16_codepoint ] = utf16_sequence
        return utf16_sequence
    end

end

--- [SHARED AND MENU]
---
--- Encodes a single code point into a UTF-16 sequence of 1 or 2 code units (2 or 4 bytes).
---
---@param utf16_codepoint integer The code point to encode.
---@param lax boolean? If `true`, invalid code points (surrogates, negative or above `U+10FFFF`) are encoded as `U+FFFD` instead of raising an error.
---@param big_endian boolean? Whether to encode as big-endian.
---@param stack_level integer? The error level, relative to the caller, `1` (default) blames the caller of this function.
---@return string utf16_sequence The UTF-16 sequence.
---@nodiscard
function utf16.encode( utf16_codepoint, lax, big_endian, stack_level )
    return encode( utf16_codepoint, lax ~= true, stack_level or 1, big_endian )
end

--- [SHARED AND MENU]
---
--- Decodes a single UTF-16 sequence starting at the given byte position.
---
--- In lax mode invalid sequences do not raise an error, `nil` is returned as the code point
--- together with the number of bytes to skip, the position of the sequence and the error code.
---
---@param utf16_string string The UTF-16 string to decode from.
---@param index integer? The position of the sequence in bytes, `1` by default.
---@param end_index integer? The last byte that can be read, the end of the string by default; a sequence cut by it is invalid.
---@param lax boolean? If `true`, invalid sequences are returned as `nil` instead of raising an error.
---@param big_endian boolean? Whether the string is big-endian.
---@param stack_level integer? The error level, relative to the caller, `1` (default) blames the caller of this function.
---@return integer | nil utf16_codepoint The decoded code point, or `nil` if the sequence is invalid.
---@return integer sequence_length The length of the sequence in bytes, at least `1`.
---@return integer | nil error_position The position of the invalid sequence, `nil` if the sequence is valid.
---@return dreamwork.std.utf16.ErrorCode | nil error_code The error code, `nil` if the sequence is valid.
---@nodiscard
function utf16.decode( utf16_string, index, end_index, lax, big_endian, stack_level )
    return decode( utf16_string, index or 1, end_index or #utf16_string, lax ~= true, stack_level or 1, big_endian )
end

--- [SHARED AND MENU]
---
--- Returns the number of code points that start between byte positions `start_position` and `end_position` (both inclusive).
---
---@param utf16_string string The UTF-16 string to count the code points of.
---@param start_position integer? The position to start from in bytes, `1` by default.
---@param end_position integer? The position to end at in bytes, the end of the string by default; a sequence cut by it is invalid.
---@param lax boolean? If `true`, every invalid sequence counts as one code point instead of raising an error.
---@param big_endian boolean? Whether the string is big-endian.
---@return integer utf16_codepoint_count The number of code points.
---@nodiscard
function utf16.len( utf16_string, start_position, end_position, lax, big_endian )
    local start_index, end_index = math_range( #utf16_string, start_position, end_position )
    local utf16_codepoint_count = 0
    local strict = lax ~= true

    while start_index <= end_index do
        local _, utf16_sequence_length = decode( utf16_string, start_index, end_index, strict, 2, big_endian )
        start_index = start_index + utf16_sequence_length
        utf16_codepoint_count = utf16_codepoint_count + 1
    end

    return utf16_codepoint_count
end

---@param utf16_string string
---@param start_position integer
---@param end_position integer
---@param strict boolean
---@param stack_level integer The error level, relative to the caller of `unpack`.
---@param big_endian boolean?
---@return integer[] utf16_codepoints
---@return integer utf16_codepoint_count
local function unpack( utf16_string, start_position, end_position, strict, stack_level, big_endian )
    ---@type integer[]
    local utf16_codepoints = {}
    local utf16_codepoint_count = 0

    stack_level = stack_level + 1

    while start_position <= end_position do
        local utf16_codepoint, utf16_sequence_length = decode( utf16_string, start_position, end_position, strict, stack_level, big_endian )
        start_position = start_position + utf16_sequence_length

        utf16_codepoint_count = utf16_codepoint_count + 1
        utf16_codepoints[ utf16_codepoint_count ] = utf16_codepoint or 0xFFFD
    end

    return utf16_codepoints, utf16_codepoint_count
end

local pack

if ffi == nil then

    ---@param utf16_codepoints integer[]
    ---@param utf16_codepoint_count integer
    ---@param strict boolean
    ---@param stack_level integer The error level, relative to the caller of `pack`.
    ---@param big_endian boolean?
    ---@return string utf16_string
    function pack( utf16_codepoints, utf16_codepoint_count, strict, stack_level, big_endian )
        ---@type string[]
        local utf16_sequences = {}

        stack_level = stack_level + 1

        for index = 1, utf16_codepoint_count, 1 do
            utf16_sequences[ index ] = encode( utf16_codepoints[ index ], strict, stack_level, big_endian )
        end

        return table_concat( utf16_sequences, "", 1, utf16_codepoint_count )
    end

else

    ---@param utf16_codepoints integer[]
    ---@param utf16_codepoint_count integer
    ---@param strict boolean
    ---@param stack_level integer The error level, relative to the caller of `pack`.
    ---@param big_endian boolean?
    ---@return string utf16_string
    function pack( utf16_codepoints, utf16_codepoint_count, strict, stack_level, big_endian )
        -- every code point takes at most 4 bytes
        local buffer = uint8_array_t( utf16_codepoint_count * 4 )
        local length = 0

        stack_level = stack_level + 1

        for index = 1, utf16_codepoint_count, 1 do
            local utf16_codepoint = utf16_codepoints[ index ]

            if utf16_codepoint < 0 or utf16_codepoint > 0x10FFFF or (utf16_codepoint >= 0xD800 and utf16_codepoint <= 0xDFFF) then
                -- raises in strict mode, U+FFFD otherwise
                ffi_copy( buffer + length, encode( utf16_codepoint, strict, stack_level, big_endian ), 2 )
                length = length + 2
            elseif utf16_codepoint < 0x10000 then
                local uint8_1, uint8_2 = rbit_rshift( utf16_codepoint, 8 ), rbit_band( utf16_codepoint, 0xFF )

                if big_endian then
                    buffer[ length ], buffer[ length + 1 ] = uint8_1, uint8_2
                else
                    buffer[ length ], buffer[ length + 1 ] = uint8_2, uint8_1
                end

                length = length + 2
            else
                local value = utf16_codepoint - 0x10000
                local high_surrogate = 0xD800 + rbit_rshift( value, 10 )
                local low_surrogate = 0xDC00 + rbit_band( value, 0x3FF )

                if big_endian then
                    buffer[ length ], buffer[ length + 1 ] = rbit_rshift( high_surrogate, 8 ), rbit_band( high_surrogate, 0xFF )
                    buffer[ length + 2 ], buffer[ length + 3 ] = rbit_rshift( low_surrogate, 8 ), rbit_band( low_surrogate, 0xFF )
                else
                    buffer[ length ], buffer[ length + 1 ] = rbit_band( high_surrogate, 0xFF ), rbit_rshift( high_surrogate, 8 )
                    buffer[ length + 2 ], buffer[ length + 3 ] = rbit_band( low_surrogate, 0xFF ), rbit_rshift( low_surrogate, 8 )
                end

                length = length + 4
            end
        end

        return ffi_string( buffer, length )
    end

end

--- [SHARED AND MENU]
---
--- Decodes a UTF-16 string into a table of code points.
---
---@param utf16_string string The UTF-16 string to decode.
---@param start_position integer? The position to start from in bytes, `1` by default.
---@param end_position integer? The position to end at in bytes, the end of the string by default; a sequence cut by it is invalid.
---@param lax boolean? If `true`, invalid sequences are decoded as U+FFFD instead of raising an error.
---@param big_endian boolean? Whether the string is big-endian.
---@return integer[] utf16_codepoints The code points.
---@return integer utf16_codepoint_count The number of code points.
---@nodiscard
function utf16.unpack( utf16_string, start_position, end_position, lax, big_endian )
    local start_index, end_index = math_range( #utf16_string, start_position, end_position )
    return unpack( utf16_string, start_index, end_index, lax ~= true, 1, big_endian )
end

--- [SHARED AND MENU]
---
--- Encodes a table of code points into a UTF-16 string.
---
---@param utf16_codepoints integer[] The code points to encode.
---@param utf16_codepoint_count integer? The number of code points to encode, `#utf16_codepoints` by default.
---@param lax boolean? If `true`, invalid code points (surrogates, negative or above U+10FFFF) are encoded as U+FFFD instead of raising an error.
---@param big_endian boolean? Whether to produce a big-endian string.
---@return string utf16_string The UTF-16 string.
---@nodiscard
function utf16.pack( utf16_codepoints, utf16_codepoint_count, lax, big_endian )
    return pack( utf16_codepoints, utf16_codepoint_count or #utf16_codepoints, lax ~= true, 1, big_endian )
end

--- [SHARED AND MENU]
---
--- Encodes code points into a little-endian UTF-16 string.
---
--- This functions similarly to `string.char`, invalid code points raise an error, use `utf16.pack` for big-endian strings.
---
---@param a integer? The first code point.
---@param b integer? The second code point.
---@param ... integer The rest of the code points.
---@return string utf16_string The UTF-16 string.
---@nodiscard
function utf16.char( a, b, ... )
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
--- This functions similarly to `string.byte`, use `utf16.unpack` for long strings.
---
--- The last code point is decoded completely even if it ends after `end_position`.
---
---@param utf16_string string The UTF-16 string to decode.
---@param start_position integer? The position to start from in bytes, `1` by default.
---@param end_position integer? The position to end at in bytes, `start_position` by default.
---@param lax boolean? If `true`, invalid sequences are decoded as U+FFFD instead of raising an error.
---@param big_endian boolean? Whether the string is big-endian.
---@return integer ... The code points.
---@nodiscard
function utf16.codepoint( utf16_string, start_position, end_position, lax, big_endian )
    local str_length = #utf16_string
    if str_length == 0 then
        return
    end

    local start_index, end_index = math_range( str_length, start_position, end_position or start_position or 1 )
    if start_index > end_index then
        return
    end

    local strict = lax ~= true

    local utf16_codepoint, utf16_sequence_length = decode( utf16_string, start_index, str_length, strict, 2, big_endian )
    start_index = start_index + utf16_sequence_length

    if start_index > end_index then
        return utf16_codepoint or 0xFFFD
    end

    ---@type integer[]
    local utf16_codepoints = { utf16_codepoint or 0xFFFD }
    local utf16_codepoint_count = 1

    repeat
        utf16_codepoint, utf16_sequence_length = decode( utf16_string, start_index, str_length, strict, 2, big_endian )
        start_index = start_index + utf16_sequence_length

        utf16_codepoint_count = utf16_codepoint_count + 1
        utf16_codepoints[ utf16_codepoint_count ] = utf16_codepoint or 0xFFFD
    until start_index > end_index

    return table_unpack( utf16_codepoints, 1, utf16_codepoint_count )
end

--- Finds the sequence that contains byte `index`, as `decode` splits the string when walking it from the start:
--- code units start at odd positions, and a low surrogate right after a high surrogate belongs to it.
---
---@param utf16_string string
---@param index integer The byte position, `1 <= index <= str_length`.
---@param str_length integer
---@param big_endian boolean?
---@return integer start_index
---@return integer sequence_length
---@return integer | nil utf16_codepoint `nil` if the sequence is invalid.
local function find_sequence( utf16_string, index, str_length, big_endian )
    local start_index = index - (index - 1) % 2

    if start_index > 2 then
        local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( utf16_string, start_index - 2, start_index + 1 )
        if uint8_4 ~= nil then
            if big_endian then
                uint8_2, uint8_4 = uint8_1, uint8_3
            end

            -- `uint8_2` and `uint8_4` are the high bytes of the previous and the current code unit
            if uint8_2 >= 0xD8 and uint8_2 <= 0xDB and uint8_4 >= 0xDC and uint8_4 <= 0xDF then
                start_index = start_index - 2
            end
        end
    end

    local utf16_codepoint, sequence_length = decode( utf16_string, start_index, str_length, false, nil, big_endian )
    return start_index, sequence_length, utf16_codepoint
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
--- `#utf16_string + 1` is the position right after the last code point and is returned as `#utf16_string + 1, #utf16_string + 1`.
---
--- Code units are aligned to the start of the string. In lax mode every invalid sequence counts as one code point
--- (the same way `utf16.len` counts them), otherwise any invalid sequence that is walked over raises an error.
---
--- Raises an error if `n ~= 0` and `position` points inside a code point.
---
---@param utf16_string string The UTF-16 string to search in.
---@param n integer The number of the code point, relative to `position`.
---@param position integer? The byte position to count from, `1` if `n >= 0`, otherwise `#utf16_string + 1`, negative positions count from the end of the string, out of range positions are clamped.
---@param lax boolean? If `true`, invalid sequences count as code points instead of raising an error.
---@param big_endian boolean? Whether the string is big-endian.
---@return integer | nil start_position The position of the first byte of the code point, or `nil` if the string has no such code point.
---@return integer | nil end_position The position of the last byte of the code point, or `nil` if the string has no such code point.
---@nodiscard
function utf16.offset( utf16_string, n, position, lax, big_endian )
    local str_length = #utf16_string
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

        local start_index, sequence_length, utf16_codepoint = find_sequence( utf16_string, position, str_length, big_endian )
        if utf16_codepoint == nil and strict then
            decode( utf16_string, start_index, str_length, true, 2, big_endian )
        end

        return start_index, start_index + (sequence_length - 1)
    end

    if position ~= end_of_string and find_sequence( utf16_string, position, str_length, big_endian ) ~= position then
        error( string.format( "initial position %d is inside a code point", position ), 2 )
    end

    -- position of the high byte in a code unit, relative to its first byte
    local high_offset = big_endian and 0 or 1

    if n > 0 then
        while position <= str_length do
            local sequence_length = 2

            -- a whole code unit that is not a surrogate is always valid, no need to decode it
            if position == str_length then
                local _
                _, sequence_length = decode( utf16_string, position, str_length, strict, 2, big_endian )
            else
                local uint8 = string_byte( utf16_string, position + high_offset, position + high_offset )
                if uint8 >= 0xD8 and uint8 <= 0xDF then
                    local _
                    _, sequence_length = decode( utf16_string, position, str_length, strict, 2, big_endian )
                end
            end

            if n == 1 then
                return position, position + (sequence_length - 1)
            end

            n = n - 1
            position = position + sequence_length
        end

        if n == 1 then
            return end_of_string, end_of_string
        end

        return nil, nil
    end

    while position > 1 do
        local start_index, sequence_length = position - 2, 2

        -- the high byte of the code unit before `position`, `nil` if that is an odd trailing byte
        local uint8
        if position % 2 == 1 then
            uint8 = string_byte( utf16_string, start_index + high_offset, start_index + high_offset )
        end

        -- surrogates (pairs or not) and an odd trailing byte need the full lookup
        if uint8 == nil or (uint8 >= 0xD8 and uint8 <= 0xDF) then
            local utf16_codepoint
            start_index, sequence_length, utf16_codepoint = find_sequence( utf16_string, position - 1, str_length, big_endian )

            if utf16_codepoint == nil and strict then
                decode( utf16_string, start_index, str_length, true, 2, big_endian )
            end
        end

        n = n + 1
        if n == 0 then
            return start_index, start_index + (sequence_length - 1)
        end

        position = start_index
    end

    return nil, nil
end

--- [SHARED AND MENU]
---
--- Returns the substring between code points `start_position` and `end_position` (both inclusive).
---
--- This functions similarly to `string.sub`, but positions are in code points, negative positions count from the end of the string.
---
--- The bytes are copied as is, in lax mode invalid sequences are kept (each counts as one code point).
---
---@param utf16_string string The UTF-16 string to get the substring of.
---@param start_position integer? The position of the first code point, `1` by default.
---@param end_position integer? The position of the last code point, the last code point of the string by default.
---@param lax boolean? If `true`, every invalid sequence counts as one code point instead of raising an error.
---@param big_endian boolean? Whether the string is big-endian.
---@return string utf16_sub The substring.
---@nodiscard
function utf16.sub( utf16_string, start_position, end_position, lax, big_endian )
    local str_length = #utf16_string
    if str_length == 0 then
        return utf16_string
    end

    if start_position == nil then
        start_position = 1
    end

    local strict = lax ~= true

    if start_position < 0 or (end_position ~= nil and end_position < 0) then
        local utf16_codepoint_count = 0
        local index = 1

        while index <= str_length do
            local _, utf16_sequence_length = decode( utf16_string, index, str_length, strict, 2, big_endian )
            index = index + utf16_sequence_length
            utf16_codepoint_count = utf16_codepoint_count + 1
        end

        if start_position < 0 then
            start_position = utf16_codepoint_count + start_position + 1
        end

        if end_position ~= nil and end_position < 0 then
            end_position = utf16_codepoint_count + end_position + 1
        end
    end

    if start_position < 1 then
        start_position = 1
    end

    if end_position ~= nil and end_position < start_position then
        return ""
    end

    ---@type integer | nil
    local utf16_start

    local utf16_codepoint_count = 0
    local index = 1

    while index <= str_length do
        local _, utf16_sequence_length = decode( utf16_string, index, str_length, strict, 2, big_endian )

        utf16_codepoint_count = utf16_codepoint_count + 1

        if utf16_codepoint_count == start_position then
            utf16_start = index
        end

        if utf16_codepoint_count == end_position then
            return string_sub( utf16_string, utf16_start or 1, index + (utf16_sequence_length - 1) )
        end

        index = index + utf16_sequence_length
    end

    if utf16_start == nil then
        return ""
    end

    return string_sub( utf16_string, utf16_start, str_length )
end

if ffi == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the code points between byte positions `start_position` and `end_position` in reverse order.
    ---
    --- This functions similarly to `string.reverse`, but the bytes of each code point (and surrogate pair) keep their order.
    ---
    ---@param utf16_string string The UTF-16 string to reverse.
    ---@param start_position integer? The position to start from in bytes, `1` by default.
    ---@param end_position integer? The position to end at in bytes, the end of the string by default; a sequence cut by it is invalid.
    ---@param lax boolean? If `true`, invalid sequences are replaced with U+FFFD instead of raising an error.
    ---@param big_endian boolean? Whether the string is big-endian.
    ---@return string utf16_reversed The reversed UTF-16 string.
    ---@nodiscard
    function utf16.reverse( utf16_string, start_position, end_position, lax, big_endian )
        local start_index, end_index = math_range( #utf16_string, start_position, end_position )
        local strict = lax ~= true

        ---@type string[]
        local utf16_sequences = {}
        local utf16_sequence_count = 0

        while start_index <= end_index do
            local utf16_codepoint, utf16_sequence_length = decode( utf16_string, start_index, end_index, strict, 2, big_endian )
            utf16_sequence_count = utf16_sequence_count + 1

            if utf16_codepoint == nil then
                utf16_sequences[ utf16_sequence_count ] = big_endian and "\xFF\xFD" or "\xFD\xFF"
            else
                utf16_sequences[ utf16_sequence_count ] = string_sub( utf16_string, start_index, start_index + (utf16_sequence_length - 1) )
            end

            start_index = start_index + utf16_sequence_length
        end

        local left, right = 1, utf16_sequence_count

        while left < right do
            utf16_sequences[ left ], utf16_sequences[ right ] = utf16_sequences[ right ], utf16_sequences[ left ]
            left, right = left + 1, right - 1
        end

        return table_concat( utf16_sequences, "", 1, utf16_sequence_count )
    end

else

    ---@param utf16_string string
    ---@param start_position integer?
    ---@param end_position integer?
    ---@param lax boolean?
    ---@param big_endian boolean?
    ---@return string utf16_reversed
    ---@nodiscard
    function utf16.reverse( utf16_string, start_position, end_position, lax, big_endian )
        local start_index, end_index = math_range( #utf16_string, start_position, end_position )
        if start_index > end_index then
            return ""
        end

        local strict = lax ~= true
        local source = ffi_cast( uint8_ptr_t, utf16_string )

        -- in lax mode an odd trailing byte turns into a 2-byte U+FFFD
        local capacity = end_index - start_index + 1
        if not strict then
            capacity = capacity + 1
        end

        -- filled from the end towards the start
        local buffer = uint8_array_t( capacity )
        local length = capacity

        -- offset of the byte that holds the high half of a code unit
        local high_offset = big_endian and 0 or 1

        while start_index <= end_index do
            local high_uint8 = source[ start_index - 1 + high_offset ]

            if start_index < end_index and (high_uint8 < 0xD8 or high_uint8 > 0xDF) then
                length = length - 2
                buffer[ length ], buffer[ length + 1 ] = source[ start_index - 1 ], source[ start_index ]
                start_index = start_index + 2
            else
                local utf16_codepoint, utf16_sequence_length = decode( utf16_string, start_index, end_index, strict, 2, big_endian )

                if utf16_codepoint == nil then
                    length = length - 2
                    ffi_copy( buffer + length, big_endian and "\xFF\xFD" or "\xFD\xFF", 2 )
                else
                    length = length - utf16_sequence_length
                    ffi_copy( buffer + length, source + (start_index - 1), utf16_sequence_length )
                end

                start_index = start_index + utf16_sequence_length
            end
        end

        return ffi_string( buffer + length, capacity - length )
    end

end

--- [SHARED AND MENU]
---
--- Returns a well-formed copy of a UTF-16 string, every invalid sequence (unpaired surrogates, an odd trailing byte) is replaced with `replacement_str`.
---
--- This is **not** Unicode normalization (NFC, NFD, NFKC, NFKD): valid sequences are copied as is.
---
--- Only the range between `start_position` and `end_position` is returned, a sequence cut by `end_position` is invalid.
---
---@param utf16_string string The UTF-16 string to sanitize.
---@param replacement_str string? The string to replace invalid sequences with, U+FFFD in the string's byte order by default.
---@param start_position integer? The position to start from in bytes, `1` by default.
---@param end_position integer? The position to end at in bytes, the end of the string by default.
---@param big_endian boolean? Whether the string is big-endian.
---@return string utf16_normalized The well-formed UTF-16 string.
---@nodiscard
function utf16.normalize( utf16_string, replacement_str, start_position, end_position, big_endian )
    local start_index, end_index = math_range( #utf16_string, start_position, end_position )

    if replacement_str == nil then
        replacement_str = big_endian and "\xFF\xFD" or "\xFD\xFF"
    end

    ---@type string[]
    local segments = {}
    local segment_count = 0

    -- start of the current run of valid sequences
    local valid_start = start_index

    while start_index <= end_index do
        local utf16_codepoint, utf16_sequence_length = decode( utf16_string, start_index, end_index, false, nil, big_endian )

        if utf16_codepoint == nil then
            if valid_start < start_index then
                segment_count = segment_count + 1
                segments[ segment_count ] = string_sub( utf16_string, valid_start, start_index - 1 )
            end

            segment_count = segment_count + 1
            segments[ segment_count ] = replacement_str

            valid_start = start_index + utf16_sequence_length
        end

        start_index = start_index + utf16_sequence_length
    end

    if segment_count == 0 then
        return string_sub( utf16_string, valid_start, end_index )
    end

    if valid_start <= end_index then
        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( utf16_string, valid_start, end_index )
    end

    return table_concat( segments, "", 1, segment_count )
end

do

    --- Stateless, so nested and interleaved loops are safe: the next position is
    --- derived from the control variable by re-scanning the previous sequence.
    ---
    --- Must be tail-called by the iterators, so errors point at the `for` loop.
    ---
    ---@param utf16_string string
    ---@param index integer The position of the previous code point, `0` before the first one.
    ---@param strict boolean
    ---@param big_endian boolean
    ---@return integer | nil
    ---@return integer | nil
    local function iterate( utf16_string, index, strict, big_endian )
        local str_length = #utf16_string

        if index == 0 then
            index = 1
        else
            local _, utf16_sequence_length = decode( utf16_string, index, str_length, false, nil, big_endian )
            index = index + utf16_sequence_length
        end

        if index > str_length then
            return nil, nil
        end

        local utf16_codepoint = decode( utf16_string, index, str_length, strict, 2, big_endian )
        if utf16_codepoint == nil then
            utf16_codepoint = 0xFFFD
        end

        return index, utf16_codepoint
    end

    local iterators = {
        [ true ] = {
            [ true ] = function( utf16_string, index ) return iterate( utf16_string, index, true, true ) end,
            [ false ] = function( utf16_string, index ) return iterate( utf16_string, index, true, false ) end
        },
        [ false ] = {
            [ true ] = function( utf16_string, index ) return iterate( utf16_string, index, false, true ) end,
            [ false ] = function( utf16_string, index ) return iterate( utf16_string, index, false, false ) end
        }
    }

    --- [SHARED AND MENU]
    ---
    --- Returns an iterator function that iterates over the code points of a UTF-16 string.
    ---
    --- Yields the byte position and the code point of every character, like `utf8.codes`.
    ---
    --- Invalid sequences raise an error, or yield U+FFFD if `lax` is `true`.
    ---
    ---@param utf16_string string The UTF-16 string to iterate over.
    ---@param lax boolean? If `true`, invalid sequences are yielded as U+FFFD instead of raising an error.
    ---@param big_endian boolean? Whether the string is big-endian.
    ---@return ( fun( utf16_string: string, index: integer ): integer | nil, integer | nil ), string, integer
    ---@nodiscard
    function utf16.codes( utf16_string, lax, big_endian )
        return iterators[ lax ~= true ][ big_endian == true ], utf16_string, 0
    end

end
