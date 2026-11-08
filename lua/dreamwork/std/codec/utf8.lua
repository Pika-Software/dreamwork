---@class dreamwork.std
local std = dreamwork.std

local ffi = std.ffi

local ffi_cast, ffi_copy, ffi_string
local uint8_ptr_t, uint8_array_t

if ffi ~= nil then
    ffi_cast, ffi_copy, ffi_string = ffi.cast, ffi.copy, ffi.string
    uint8_ptr_t, uint8_array_t = ffi.typeof( "const uint8_t *" ), ffi.typeof( "uint8_t[?]" )
end

local raw                      = std.raw
local raw_select               = raw.select

local string                   = std.string
local string_sub               = string.sub
local string_char, string_byte = string.char, string.byte

local math                     = std.math
local math_relative            = math.relative
local math_range               = math.range
local math_min                 = math.min

local rbit                     = raw.bit
local rbit_band, rbit_bor      = rbit.band, rbit.bor
local rbit_lshift, rbit_rshift = rbit.lshift, rbit.rshift

local table                    = std.table
local table_unpack             = table.unpack
local table_concat             = table.concat

local error                    = std.error


--- [SHARED AND MENU]
---
--- The utf8 library provides functions for the manipulation of UTF-8 strings.
---
--- A rewrite of the standard Lua `utf8` library with strict validation (Unicode Table 3-7) and additional functions.
---
--- Positions are in bytes, except `utf8.sub`, which takes code point positions like `string.sub` takes byte positions.
---
--- Functions that take `lax` raise an error on the first invalid sequence, unless `lax` is `true`;
--- in lax mode each maximal invalid subpart counts as one code point, decoded as U+FFFD.
---
---@class dreamwork.std.utf8
---@field charpattern string The pattern (a string, not a function) that matches exactly one UTF-8 byte sequence, assuming that the subject is a valid UTF-8 string.
local utf8 = {}
std.utf8 = utf8

utf8.charpattern = "[%z\x01-\x7F\xC2-\xF4][\x80-\xBF]*"

---@alias dreamwork.std.utf8.ErrorCode
---| 1 # Unexpected end of string.
---| 2 # Unexpected continuation byte.
---| 3 # Invalid lead byte.
---| 4 # Invalid continuation byte.
---| 5 # Overlong encoding.
---| 6 # UTF-16 surrogate code point.
---| 7 # Code point exceeds U+10FFFF.
---| 8 # Not a valid code point (negative).

---@type table<dreamwork.std.utf8.ErrorCode, string>
local error_messages = {
    [ 1 ] = "unexpected end of string",
    [ 2 ] = "unexpected continuation byte",
    [ 3 ] = "invalid lead byte",
    [ 4 ] = "invalid continuation byte",
    [ 5 ] = "overlong encoding",
    [ 6 ] = "UTF-16 surrogate code point",
    [ 7 ] = "code point exceeds U+10FFFF",
    [ 8 ] = "not a valid code point"
}

---@param utf8_string string
---@param error_position integer
---@param error_code dreamwork.std.utf8.ErrorCode
---@param stack_level integer The error level, relative to this function.
local function invalid_sequence( utf8_string, error_position, error_code, stack_level )
    local uint8 = string_byte( utf8_string, error_position, error_position )
    if uint8 == nil or error_code == 1 then
        error( string.format( "invalid UTF-8 sequence at position %d (%s)", error_position, error_messages[ error_code ] ), stack_level )
    else
        error( string.format( "invalid UTF-8 byte '0x%02X' at position %d (%s)", uint8, error_position, error_messages[ error_code ] ), stack_level )
    end
end

---@param utf8_codepoint integer
---@param stack_level integer The error level, relative to this function.
local function invalid_codepoint( utf8_codepoint, stack_level )
    if utf8_codepoint < 0 then
        error( string.format( "invalid UTF-8 code point '-0x%X' (%s)", -utf8_codepoint, error_messages[ 8 ] ), stack_level )
    elseif utf8_codepoint > 0x10FFFF then
        error( string.format( "invalid UTF-8 code point '0x%X' (%s)", utf8_codepoint, error_messages[ 7 ] ), stack_level )
    else
        error( string.format( "invalid UTF-8 code point '0x%X' (%s)", utf8_codepoint, error_messages[ 6 ] ), stack_level )
    end
end

--- Must be tail-called from `decode`, so `decode`'s frame is gone when the error is raised.
---
---@param utf8_string string
---@param strict boolean | nil
---@param stack_level integer | nil
---@param sequence_length integer
---@param error_position integer
---@param error_code dreamwork.std.utf8.ErrorCode
---@return nil utf8_codepoint
---@return integer sequence_length
---@return integer error_position
---@return dreamwork.std.utf8.ErrorCode error_code
local function invalid( utf8_string, strict, stack_level, sequence_length, error_position, error_code )
    if strict then
        invalid_sequence( utf8_string, error_position, error_code, (stack_level or 1) + 2 )
    end

    return nil, sequence_length, error_position, error_code
end

--- Validates and decodes one UTF-8 sequence (Unicode Table 3-7).
---
--- On an invalid sequence raises an error if `strict` is `true`, otherwise returns
--- `nil` as code point and the length of its maximal valid prefix (at least `1`)
--- as sequence length, so callers can always advance by `sequence_length`.
---
---@param utf8_string string
---@param index integer
---@param end_index integer The last byte position that belongs to the sequence range.
---@param strict boolean?
---@param stack_level integer? The error level, relative to the caller of `decode`.
---@return integer | nil utf8_codepoint
---@return integer sequence_length
---@return integer | nil error_position
---@return dreamwork.std.utf8.ErrorCode | nil error_code
local function decode( utf8_string, index, end_index, strict, stack_level )
    local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( utf8_string, index, math_min( index + 3, end_index ) )

    if uint8_1 == nil then
        return invalid( utf8_string, strict, stack_level, 1, index, 1 )
    elseif uint8_1 < 0x80 then
        return uint8_1, 1, nil, nil
    elseif uint8_1 < 0xC0 then
        return invalid( utf8_string, strict, stack_level, 1, index, 2 )
    elseif uint8_1 < 0xC2 then
        return invalid( utf8_string, strict, stack_level, 1, index, 5 )
    elseif uint8_1 > 0xF4 then
        return invalid( utf8_string, strict, stack_level, 1, index, 3 )
    elseif uint8_2 == nil then
        return invalid( utf8_string, strict, stack_level, 1, index + 1, 1 )
    end

    if uint8_1 < 0xE0 then
        if uint8_2 < 0x80 or uint8_2 > 0xBF then
            return invalid( utf8_string, strict, stack_level, 1, index + 1, 4 )
        end

        return rbit_bor(
            rbit_lshift( rbit_band( uint8_1, 0x1F ), 6 ),
            rbit_band( uint8_2, 0x3F )
        ), 2, nil, nil
    end

    if uint8_2 < 0x80 or uint8_2 > 0xBF then
        return invalid( utf8_string, strict, stack_level, 1, index + 1, 4 )
    elseif uint8_1 == 0xE0 and uint8_2 < 0xA0 then
        return invalid( utf8_string, strict, stack_level, 1, index + 1, 5 )
    elseif uint8_1 == 0xED and uint8_2 > 0x9F then
        return invalid( utf8_string, strict, stack_level, 1, index + 1, 6 )
    elseif uint8_1 == 0xF0 and uint8_2 < 0x90 then
        return invalid( utf8_string, strict, stack_level, 1, index + 1, 5 )
    elseif uint8_1 == 0xF4 and uint8_2 > 0x8F then
        return invalid( utf8_string, strict, stack_level, 1, index + 1, 7 )
    elseif uint8_3 == nil then
        return invalid( utf8_string, strict, stack_level, 2, index + 2, 1 )
    elseif uint8_3 < 0x80 or uint8_3 > 0xBF then
        return invalid( utf8_string, strict, stack_level, 2, index + 2, 4 )
    end

    if uint8_1 < 0xF0 then
        return rbit_bor(
            rbit_lshift( rbit_band( uint8_1, 0x0F ), 12 ),
            rbit_lshift( rbit_band( uint8_2, 0x3F ), 6 ),
            rbit_band( uint8_3, 0x3F )
        ), 3, nil, nil
    end

    if uint8_4 == nil then
        return invalid( utf8_string, strict, stack_level, 3, index + 3, 1 )
    elseif uint8_4 < 0x80 or uint8_4 > 0xBF then
        return invalid( utf8_string, strict, stack_level, 3, index + 3, 4 )
    end

    return rbit_bor(
        rbit_lshift( rbit_band( uint8_1, 0x07 ), 18 ),
        rbit_lshift( rbit_band( uint8_2, 0x3F ), 12 ),
        rbit_lshift( rbit_band( uint8_3, 0x3F ), 6 ),
        rbit_band( uint8_4, 0x3F )
    ), 4, nil, nil
end

local encode
do

    --- The maximal amount of cached sequences, the cache is emptied when it is full.
    local CACHE_LIMIT = 4096

    ---@type table<integer, string>
    local cache = {}

    ---@type integer
    local cache_size = 0

    local replacement_sequence = "\xEF\xBF\xBD"

    ---@param utf8_codepoint integer
    ---@param strict boolean If `false`, invalid code points are encoded as U+FFFD.
    ---@param stack_level integer?
    ---@return string utf8_sequence
    function encode( utf8_codepoint, strict, stack_level )
        local utf8_sequence = cache[ utf8_codepoint ]
        if utf8_sequence ~= nil then
            return utf8_sequence
        end

        if utf8_codepoint < 0 or utf8_codepoint > 0x10FFFF or (utf8_codepoint >= 0xD800 and utf8_codepoint <= 0xDFFF) then
            if strict then
                invalid_codepoint( utf8_codepoint, (stack_level or 1) + 2 )
            end

            return replacement_sequence
        end

        if utf8_codepoint < 0x80 then
            utf8_sequence = string_char( utf8_codepoint )
        elseif utf8_codepoint < 0x800 then
            utf8_sequence = string_char(
                rbit_bor( 0xC0, rbit_band( rbit_rshift( utf8_codepoint, 6 ), 0x1F ) ),
                rbit_bor( 0x80, rbit_band( utf8_codepoint, 0x3F ) )
            )
        elseif utf8_codepoint < 0x10000 then
            utf8_sequence = string_char(
                rbit_bor( 0xE0, rbit_band( rbit_rshift( utf8_codepoint, 12 ), 0x0F ) ),
                rbit_bor( 0x80, rbit_band( rbit_rshift( utf8_codepoint, 6 ), 0x3F ) ),
                rbit_bor( 0x80, rbit_band( utf8_codepoint, 0x3F ) )
            )
        else
            utf8_sequence = string_char(
                rbit_bor( 0xF0, rbit_band( rbit_rshift( utf8_codepoint, 18 ), 0x07 ) ),
                rbit_bor( 0x80, rbit_band( rbit_rshift( utf8_codepoint, 12 ), 0x3F ) ),
                rbit_bor( 0x80, rbit_band( rbit_rshift( utf8_codepoint, 6 ), 0x3F ) ),
                rbit_bor( 0x80, rbit_band( utf8_codepoint, 0x3F ) )
            )
        end

        if cache_size == CACHE_LIMIT then
            cache, cache_size = {}, 0
        end

        cache_size = cache_size + 1
        cache[ utf8_codepoint ] = utf8_sequence

        return utf8_sequence
    end

end

---@param utf8_string string
---@param start_position integer?
---@param end_position integer?
---@param lax boolean?
---@return integer | nil
---@return nil | integer error_position
---@return nil | dreamwork.std.utf8.ErrorCode error_code
local function len( utf8_string, start_position, end_position, lax )
    local str_length = #utf8_string
    if str_length == 0 then
        return 0
    end

    local start_index, end_index = math_range( str_length, start_position, end_position )

    local utf8_codepoint_count = 0
    local strict = lax ~= true

    while start_index <= end_index do
        local utf8_codepoint, sequence_length, error_position, error_code = decode( utf8_string, start_index, end_index )
        if utf8_codepoint == nil and strict then
            return nil, error_position, error_code
        end

        start_index = start_index + sequence_length
        utf8_codepoint_count = utf8_codepoint_count + 1
    end

    return utf8_codepoint_count, nil, nil
end

--- [SHARED AND MENU]
---
--- Encodes a single code point into a UTF-8 sequence.
---
---@param utf8_codepoint integer The code point to encode.
---@param lax boolean? If `true`, invalid code points (surrogates, negative or above U+10FFFF) are encoded as U+FFFD instead of raising an error.
---@param stack_level integer? The error level, relative to the caller, `1` (default) blames the caller of this function.
---@return string utf8_sequence The UTF-8 sequence, 1 to 4 bytes long.
---@nodiscard
function utf8.encode( utf8_codepoint, lax, stack_level )
    return encode( utf8_codepoint, lax ~= true, stack_level or 1 )
end

--- [SHARED AND MENU]
---
--- Decodes a single UTF-8 sequence starting at the given byte position.
---
--- In lax mode invalid sequences do not raise an error, `nil` is returned as the code point
--- together with the length of the maximal invalid subpart (the number of bytes to skip),
--- the position of the offending byte and the error code.
---
---@param utf8_string string The UTF-8 string to decode from.
---@param index integer? The position of the sequence in bytes, `1` by default.
---@param end_index integer? The last byte that can be read, the end of the string by default; a sequence cut by it is invalid.
---@param lax boolean? If `true`, invalid sequences are returned as `nil` instead of raising an error.
---@param stack_level integer? The error level, relative to the caller, `1` (default) blames the caller of this function.
---@return integer | nil utf8_codepoint The decoded code point, or `nil` if the sequence is invalid.
---@return integer sequence_length The length of the sequence in bytes, at least `1`.
---@return integer | nil error_position The position of the offending byte, `nil` if the sequence is valid.
---@return dreamwork.std.utf8.ErrorCode | nil error_code The error code, `nil` if the sequence is valid.
---@nodiscard
function utf8.decode( utf8_string, index, end_index, lax, stack_level )
    return decode( utf8_string, index or 1, end_index or #utf8_string, lax ~= true, stack_level or 1 )
end

--- [SHARED AND MENU]
---
--- Returns the number of code points that start between byte positions `start_position` and `end_position` (both inclusive).
---
--- Unlike the standard `utf8.len`, an invalid sequence raises an error instead of returning `nil` and its position.
---
---@param utf8_string string The UTF-8 string to count the code points of.
---@param start_position integer? The position to start from in bytes, `1` by default.
---@param end_position integer? The position to end at in bytes, the end of the string by default; a sequence cut by it is invalid.
---@param lax boolean? If `true`, every invalid sequence counts as one code point instead of raising an error.
---@return integer utf8_codepoint_count The number of code points.
---@nodiscard
function utf8.len( utf8_string, start_position, end_position, lax )
    local sequence_length, error_position, error_code = len( utf8_string, start_position, end_position, lax )
    if sequence_length == nil then
        ---@cast error_position integer
        ---@cast error_code dreamwork.std.utf8.ErrorCode
        invalid_sequence( utf8_string, error_position, error_code, 3 )
    end

    ---@cast sequence_length integer
    return sequence_length
end

--- [SHARED AND MENU]
---
--- Decodes a UTF-8 string into a table of code points.
---
---@param utf8_string string The UTF-8 string to decode.
---@param start_position integer? The position to start from in bytes, `1` by default.
---@param end_position integer? The position to end at in bytes, the end of the string by default; a sequence cut by it is invalid.
---@param lax boolean? If `true`, invalid sequences are decoded as U+FFFD instead of raising an error.
---@return integer[] utf8_codepoints The code points.
---@return integer utf8_codepoint_count The number of code points.
---@nodiscard
local function unpack( utf8_string, start_position, end_position, lax )
    local str_length = #utf8_string
    if str_length == 0 then
        return {}, 0
    end

    local start_index, end_index = math_range( str_length, start_position, end_position )

    local utf8_codepoint_count = 0
    local strict = lax ~= true

    ---@type integer[]
    local utf8_codepoints = {}

    while start_index <= end_index do
        local utf8_codepoint, utf8_sequence_length = decode( utf8_string, start_index, end_index, strict, 2 )
        start_index = start_index + utf8_sequence_length

        utf8_codepoint_count = utf8_codepoint_count + 1
        utf8_codepoints[ utf8_codepoint_count ] = utf8_codepoint or 0xFFFD
    end

    return utf8_codepoints, utf8_codepoint_count
end

utf8.unpack = unpack

--- [SHARED AND MENU]
---
--- Returns the substring between code points `start_position` and `end_position` (both inclusive).
---
--- This functions similarly to `string.sub`, but positions are in code points, negative positions count from the end of the string.
---
--- The bytes are copied as is, in lax mode invalid sequences are kept (each counts as one code point).
---
---@param utf8_string string The UTF-8 string to get the substring of.
---@param start_position integer? The position of the first code point, `1` by default.
---@param end_position integer? The position of the last code point, the last code point of the string by default.
---@param lax boolean? If `true`, every invalid sequence counts as one code point instead of raising an error.
---@return string utf8_sub The substring.
---@nodiscard
local function sub( utf8_string, start_position, end_position, lax )
    local str_length = #utf8_string
    if str_length == 0 then
        return utf8_string
    end

    if start_position == nil then
        start_position = 1
    end

    if start_position < 0 or (end_position ~= nil and end_position < 0) then
        local utf8_codepoint_count, error_position, error_code = len( utf8_string, 1, str_length, lax )
        if utf8_codepoint_count == nil then
            ---@cast error_position integer
            ---@cast error_code dreamwork.std.utf8.ErrorCode
            invalid_sequence( utf8_string, error_position, error_code, 3 )
        end

        ---@cast utf8_codepoint_count integer

        if start_position < 0 then
            start_position = utf8_codepoint_count + start_position + 1
        end

        if end_position ~= nil and end_position < 0 then
            end_position = utf8_codepoint_count + end_position + 1
        end
    end

    if start_position < 1 then
        start_position = 1
    end

    if end_position ~= nil and end_position < start_position then
        return ""
    end

    local strict = lax ~= true

    ---@type integer | nil
    local utf8_start

    local utf8_codepoint_count = 0
    local index = 1

    while index <= str_length do
        local _, utf8_sequence_length = decode( utf8_string, index, str_length, strict, 2 )

        utf8_codepoint_count = utf8_codepoint_count + 1

        if utf8_codepoint_count == start_position then
            utf8_start = index
        end

        if utf8_codepoint_count == end_position then
            return string_sub( utf8_string, utf8_start or 1, index + (utf8_sequence_length - 1) )
        end

        index = index + utf8_sequence_length
    end

    if utf8_start == nil then
        return ""
    end

    return string_sub( utf8_string, utf8_start, str_length )
end

utf8.sub = sub

--- [SHARED AND MENU]
---
--- Returns the code points of all characters that start between byte positions
--- `start_position` and `end_position` (both inclusive).
---
--- This functions similarly to `string.byte`, use `utf8.unpack` for long strings.
---
--- The last code point is decoded completely even if it ends after `end_position`.
---
---@param utf8_string string The UTF-8 string to decode.
---@param start_position integer? The position to start from in bytes, `1` by default.
---@param end_position integer? The position to end at in bytes, `start_position` by default.
---@param lax boolean? If `true`, invalid sequences are decoded as U+FFFD instead of raising an error.
---@return integer ... The code points.
---@nodiscard
function utf8.codepoint( utf8_string, start_position, end_position, lax )
    local str_length = #utf8_string

    local start_index, end_index = math_range( str_length, start_position, end_position or start_position or 1 )

    if start_index > end_index then
        return
    end

    local strict = lax ~= true

    local utf8_codepoint, utf8_sequence_length = decode( utf8_string, start_index, str_length, strict, 2 )
    start_index = start_index + utf8_sequence_length

    if start_index > end_index then
        return utf8_codepoint or 0xFFFD
    end

    ---@type integer[]
    local utf8_codepoints = { utf8_codepoint or 0xFFFD }
    local utf8_codepoint_count = 1

    repeat
        utf8_codepoint, utf8_sequence_length = decode( utf8_string, start_index, str_length, strict, 2 )
        start_index = start_index + utf8_sequence_length

        utf8_codepoint_count = utf8_codepoint_count + 1
        utf8_codepoints[ utf8_codepoint_count ] = utf8_codepoint or 0xFFFD
    until start_index > end_index

    return table_unpack( utf8_codepoints, 1, utf8_codepoint_count )
end

do

    --- Stateless, so nested and interleaved loops are safe: the next position is
    --- derived from the control variable by re-scanning the previous sequence.
    ---
    --- Must be tail-called by the iterators, so errors point at the `for` loop.
    ---
    ---@param utf8_string string
    ---@param index integer The position of the previous code point, `0` before the first one.
    ---@param strict boolean
    ---@return integer | nil
    ---@return integer | nil
    local function iterate( utf8_string, index, strict )
        local str_length = #utf8_string

        if index == 0 then
            index = 1
        else
            local _, utf8_sequence_length = decode( utf8_string, index, str_length )
            index = index + utf8_sequence_length
        end

        if index > str_length then
            return nil, nil
        end

        local utf8_codepoint = decode( utf8_string, index, str_length, strict, 2 )
        if utf8_codepoint == nil then
            utf8_codepoint = 0xFFFD
        end

        return index, utf8_codepoint
    end

    ---@param utf8_string string
    ---@param index integer
    ---@return integer | nil
    ---@return integer | nil
    local function utf8_iterator( utf8_string, index )
        return iterate( utf8_string, index, false )
    end

    ---@param utf8_string string
    ---@param index integer
    ---@return integer | nil
    ---@return integer | nil
    local function utf8_strict_iterator( utf8_string, index )
        return iterate( utf8_string, index, true )
    end

    --- [SHARED AND MENU]
    ---
    --- Returns an iterator function that iterates over the code points of a UTF-8 string.
    ---
    --- Yields the byte position and the code point of every character, like the standard `utf8.codes`.
    ---
    --- Invalid sequences raise an error, or yield U+FFFD if `lax` is `true`.
    ---
    ---@param utf8_string string The UTF-8 string to iterate over.
    ---@param lax boolean? If `true`, invalid sequences are yielded as U+FFFD instead of raising an error.
    ---@return ( fun( utf8_string: string, index: integer ): integer | nil, integer | nil ), string, integer
    ---@nodiscard
    function utf8.codes( utf8_string, lax )
        return lax ~= true and utf8_strict_iterator or utf8_iterator, utf8_string, 0
    end

end

local pack

if ffi == nil then

    --- [SHARED AND MENU]
    ---
    --- Encodes a sequence of code points into a UTF-8 string.
    ---
    ---@param utf8_codepoints integer[] The code points to encode.
    ---@param utf8_codepoint_count integer? The number of code points to encode, `#utf8_codepoints` by default.
    ---@param lax boolean? If `true`, invalid code points (surrogates, negative or above U+10FFFF) are encoded as U+FFFD instead of raising an error.
    ---@return string utf8_string The UTF-8 string.
    ---@nodiscard
    function pack( utf8_codepoints, utf8_codepoint_count, lax )
        if utf8_codepoint_count == nil then
            utf8_codepoint_count = #utf8_codepoints
        end

        if utf8_codepoint_count == 0 then
            return ""
        end

        ---@type string[]
        local utf8_sequences = {}
        local strict = lax ~= true

        for i = 1, utf8_codepoint_count, 1 do
            utf8_sequences[ i ] = encode( utf8_codepoints[ i ], strict, 2 )
        end

        return table_concat( utf8_sequences, "", 1, utf8_codepoint_count )
    end

else

    ---@param utf8_codepoints integer[]
    ---@param utf8_codepoint_count integer?
    ---@param lax boolean?
    ---@return string utf8_string
    ---@nodiscard
    function pack( utf8_codepoints, utf8_codepoint_count, lax )
        if utf8_codepoint_count == nil then
            utf8_codepoint_count = #utf8_codepoints
        end

        if utf8_codepoint_count == 0 then
            return ""
        end

        local strict = lax ~= true

        -- every code point takes at most 4 bytes, U+FFFD takes 3
        local buffer = uint8_array_t( utf8_codepoint_count * 4 )
        local length = 0

        for i = 1, utf8_codepoint_count, 1 do
            local utf8_codepoint = utf8_codepoints[ i ]

            if utf8_codepoint < 0 or utf8_codepoint > 0x10FFFF or (utf8_codepoint >= 0xD800 and utf8_codepoint <= 0xDFFF) then
                -- raises in strict mode, U+FFFD otherwise
                local utf8_sequence = encode( utf8_codepoint, strict, 2 )
                local utf8_sequence_length = #utf8_sequence

                ffi_copy( buffer + length, utf8_sequence, utf8_sequence_length )
                length = length + utf8_sequence_length
            elseif utf8_codepoint < 0x80 then
                buffer[ length ] = utf8_codepoint
                length = length + 1
            elseif utf8_codepoint < 0x800 then
                buffer[ length ] = rbit_bor( 0xC0, rbit_rshift( utf8_codepoint, 6 ) )
                buffer[ length + 1 ] = rbit_bor( 0x80, rbit_band( utf8_codepoint, 0x3F ) )
                length = length + 2
            elseif utf8_codepoint < 0x10000 then
                buffer[ length ] = rbit_bor( 0xE0, rbit_rshift( utf8_codepoint, 12 ) )
                buffer[ length + 1 ] = rbit_bor( 0x80, rbit_band( rbit_rshift( utf8_codepoint, 6 ), 0x3F ) )
                buffer[ length + 2 ] = rbit_bor( 0x80, rbit_band( utf8_codepoint, 0x3F ) )
                length = length + 3
            else
                buffer[ length ] = rbit_bor( 0xF0, rbit_rshift( utf8_codepoint, 18 ) )
                buffer[ length + 1 ] = rbit_bor( 0x80, rbit_band( rbit_rshift( utf8_codepoint, 12 ), 0x3F ) )
                buffer[ length + 2 ] = rbit_bor( 0x80, rbit_band( rbit_rshift( utf8_codepoint, 6 ), 0x3F ) )
                buffer[ length + 3 ] = rbit_bor( 0x80, rbit_band( utf8_codepoint, 0x3F ) )
                length = length + 4
            end
        end

        return ffi_string( buffer, length )
    end

end

utf8.pack = pack

--- [SHARED AND MENU]
---
--- Encodes a sequence of code points into a UTF-8 string.
---
--- This functions similarly to `string.char`, invalid code points raise an error.
---
---@param a integer? The first code point.
---@param b integer? The second code point.
---@param ... integer The rest of the code points.
---@return string utf8_string The UTF-8 string.
---@nodiscard
function utf8.char( a, b, ... )
    if b == nil then
        if a == nil then
            return ""
        end

        -- tail call, so level 1 already is the caller of `utf8.char`
        return encode( a, true, 1 )
    end

    return pack( { a, b, ... }, raw_select( "#", a, b, ... ), false )
end

--- Finds the sequence that contains byte `index`, as `decode` would split the string when walking it from the start.
---
--- Every byte that is not a continuation byte starts a sequence, so the sequence that covers `index`
--- starts at the closest such byte at most 3 bytes back; a continuation byte that no sequence covers
--- is an invalid sequence of its own.
---
---@param utf8_string string
---@param index integer The byte position, `1 <= index <= str_length`.
---@param str_length integer
---@return integer start_index
---@return integer sequence_length
---@return integer | nil utf8_codepoint `nil` if the sequence is invalid.
local function find_sequence( utf8_string, index, str_length )
    local start_index = index

    local uint8 = string_byte( utf8_string, index, index )

    -- unrolled, a loop here would be an inner loop in the traces of `utf8.offset`
    if uint8 > 0x7F and uint8 < 0xC0 then
        start_index = index - 1
        if start_index == 0 then
            return index, 1, nil
        end

        uint8 = string_byte( utf8_string, start_index, start_index )
        if uint8 > 0x7F and uint8 < 0xC0 then
            start_index = start_index - 1
            if start_index == 0 then
                return index, 1, nil
            end

            uint8 = string_byte( utf8_string, start_index, start_index )
            if uint8 > 0x7F and uint8 < 0xC0 then
                start_index = start_index - 1
                if start_index == 0 then
                    return index, 1, nil
                end

                uint8 = string_byte( utf8_string, start_index, start_index )
                if uint8 > 0x7F and uint8 < 0xC0 then
                    return index, 1, nil
                end
            end
        end
    end

    local utf8_codepoint, sequence_length = decode( utf8_string, start_index, str_length )
    if start_index + sequence_length <= index then
        return index, 1, nil
    end

    return start_index, sequence_length, utf8_codepoint
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
--- `#utf8_string + 1` is the position right after the last code point and is returned as `#utf8_string + 1, #utf8_string + 1`,
--- so `utf8.offset( s, utf8.len( s ) + 1 )` is `#s + 1`, just like Lua.
---
--- In lax mode every invalid sequence counts as one code point (the same way `utf8.len` counts them),
--- otherwise any invalid sequence that is walked over raises an error.
---
--- Raises an error if `n ~= 0` and `position` points inside a code point.
---
---@param utf8_string string The UTF-8 string to search in.
---@param n integer The number of the code point, relative to `position`.
---@param position integer? The byte position to count from, `1` if `n >= 0`, otherwise `#utf8_string + 1`, negative positions count from the end of the string, out of range positions are clamped.
---@param lax boolean? If `true`, invalid sequences count as code points instead of raising an error.
---@return integer | nil start_position The position of the first byte of the code point, or `nil` if the string has no such code point.
---@return integer | nil end_position The position of the last byte of the code point, or `nil` if the string has no such code point.
---@nodiscard
function utf8.offset( utf8_string, n, position, lax )
    local str_length = #utf8_string
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

        local start_index, sequence_length, utf8_codepoint = find_sequence( utf8_string, position, str_length )
        if utf8_codepoint == nil and strict then
            decode( utf8_string, start_index, str_length, true, 2 )
        end

        return start_index, start_index + (sequence_length - 1)
    end

    if position ~= end_of_string and find_sequence( utf8_string, position, str_length ) ~= position then
        error( string.format( "initial position %d is a continuation byte", position ), 2 )
    end

    if n > 0 then
        while position <= str_length do
            local sequence_length = 1

            -- ASCII is always valid and 1 byte long, no need to decode it
            if string_byte( utf8_string, position, position ) > 0x7F then
                local _
                _, sequence_length = decode( utf8_string, position, str_length, strict, 2 )
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
        local start_index, sequence_length = position - 1, 1

        -- a byte before a boundary that is ASCII is a whole code point
        if string_byte( utf8_string, start_index, start_index ) > 0x7F then
            local utf8_codepoint
            start_index, sequence_length, utf8_codepoint = find_sequence( utf8_string, start_index, str_length )

            if utf8_codepoint == nil and strict then
                decode( utf8_string, start_index, str_length, true, 2 )
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

if ffi == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the code points between byte positions `start_position` and `end_position` in reverse order.
    ---
    --- This functions similarly to `string.reverse`, but the bytes of each code point keep their order.
    ---
    ---@param utf8_string string The UTF-8 string to reverse.
    ---@param start_position integer? The position to start from in bytes, `1` by default.
    ---@param end_position integer? The position to end at in bytes, the end of the string by default; a sequence cut by it is invalid.
    ---@param lax boolean? If `true`, invalid sequences are replaced with U+FFFD instead of raising an error.
    ---@return string utf8_reversed The reversed UTF-8 string.
    ---@nodiscard
    function utf8.reverse( utf8_string, start_position, end_position, lax )
        local str_length = #utf8_string

        local start_index, end_index = math_range( str_length, start_position, end_position )

        local strict = lax ~= true

        ---@type string[]
        local utf8_sequences = {}
        local utf8_sequence_count = 0

        while start_index <= end_index do
            local utf8_codepoint, utf8_sequence_length = decode( utf8_string, start_index, end_index, strict, 2 )
            utf8_sequence_count = utf8_sequence_count + 1

            if utf8_codepoint == nil then
                utf8_sequences[ utf8_sequence_count ] = "\xEF\xBF\xBD"
            else
                utf8_sequences[ utf8_sequence_count ] = string_sub( utf8_string, start_index, start_index + (utf8_sequence_length - 1) )
            end

            start_index = start_index + utf8_sequence_length
        end

        local left, right = 1, utf8_sequence_count

        while left < right do
            utf8_sequences[ left ], utf8_sequences[ right ] = utf8_sequences[ right ], utf8_sequences[ left ]
            left, right = left + 1, right - 1
        end

        return table_concat( utf8_sequences, "", 1, utf8_sequence_count )
    end

else

    ---@param utf8_string string
    ---@param start_position integer?
    ---@param end_position integer?
    ---@param lax boolean?
    ---@return string utf8_reversed
    ---@nodiscard
    function utf8.reverse( utf8_string, start_position, end_position, lax )
        local str_length = #utf8_string

        local start_index, end_index = math_range( str_length, start_position, end_position )

        if start_index > end_index then
            return ""
        end

        local strict = lax ~= true
        local source = ffi_cast( uint8_ptr_t, utf8_string )

        -- in lax mode a single invalid byte can turn into a 3-byte U+FFFD
        local capacity = end_index - start_index + 1
        if not strict then
            capacity = capacity * 3
        end

        -- filled from the end towards the start
        local buffer = uint8_array_t( capacity )
        local length = capacity

        while start_index <= end_index do
            local uint8 = source[ start_index - 1 ]
            if uint8 < 0x80 then
                length = length - 1
                buffer[ length ] = uint8
                start_index = start_index + 1
            else
                local utf8_codepoint, utf8_sequence_length = decode( utf8_string, start_index, end_index, strict, 2 )

                if utf8_codepoint == nil then
                    length = length - 3
                    ffi_copy( buffer + length, "\xEF\xBF\xBD", 3 )
                else
                    length = length - utf8_sequence_length
                    ffi_copy( buffer + length, source + (start_index - 1), utf8_sequence_length )
                end

                start_index = start_index + utf8_sequence_length
            end
        end

        return ffi_string( buffer + length, capacity - length )
    end

end

do

    local default_replacement_str = encode( 0xFFFD, false, 2 )

    --- [SHARED AND MENU]
    ---
    --- Returns a well-formed copy of a UTF-8 string, every invalid sequence is replaced with `replacement_str`.
    ---
    --- Each maximal invalid subpart is replaced once (Unicode 3.9 "U+FFFD Substitution of Maximal Subparts",
    --- the same as the WHATWG decoder), e.g. `"\xE2\x82A"` becomes `"\u{FFFD}A"` and `"\x80\x80"` becomes `"\u{FFFD}\u{FFFD}"`.
    ---
    --- This is **not** Unicode normalization (NFC, NFD, NFKC, NFKD): valid sequences are copied as is,
    --- so canonically equivalent strings like `"\u{E9}"` and `"e\u{301}"` stay different.
    ---
    --- Only the range between `start_position` and `end_position` is returned, a sequence cut by `end_position` is invalid.
    ---
    ---@param utf8_string string The UTF-8 string to sanitize.
    ---@param replacement_str string? The string to replace invalid sequences with, U+FFFD (`"\xEF\xBF\xBD"`) by default.
    ---@param start_position integer? The position to start from in bytes, `1` by default.
    ---@param end_position integer? The position to end at in bytes, the end of the string by default.
    ---@return string utf8_normalized The well-formed UTF-8 string.
    ---@nodiscard
    function utf8.normalize( utf8_string, replacement_str, start_position, end_position )
        local str_length = #utf8_string
        if str_length == 0 then
            return utf8_string
        end

        local start_index, end_index = math_range( str_length, start_position, end_position )

        if replacement_str == nil then
            replacement_str = default_replacement_str
        end

        ---@type string[]
        local segments = {}
        local segment_count = 0

        -- start of the current run of valid sequences
        local valid_start = start_index

        while start_index <= end_index do
            local utf8_codepoint, utf8_sequence_length = decode( utf8_string, start_index, end_index, false, 2 )

            if utf8_codepoint == nil then
                if valid_start < start_index then
                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_sub( utf8_string, valid_start, start_index - 1 )
                end

                segment_count = segment_count + 1
                segments[ segment_count ] = replacement_str

                valid_start = start_index + utf8_sequence_length
            end

            start_index = start_index + utf8_sequence_length
        end

        if segment_count == 0 then
            return string_sub( utf8_string, valid_start, end_index )
        end

        if valid_start <= end_index then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_sub( utf8_string, valid_start, end_index )
        end

        return table_concat( segments, "", 1, segment_count )
    end

end
