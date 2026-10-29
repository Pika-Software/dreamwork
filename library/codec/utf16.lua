---@meta _

--- [SHARED AND MENU]
---
--- The utf16 library provides functions for the manipulation of UTF-16 strings
--- and conversion between UTF-8 and UTF-16.
---
--- All positions are in bytes, all functions use little-endian byte order
--- unless `big_endian` is `true`.
---
---@class utf16
utf16 = {}

---@alias utf16.ErrorCode
---| 1 # Unexpected end of string (odd number of bytes).
---| 2 # Unpaired high surrogate.
---| 3 # Unpaired low surrogate.
---| 4 # UTF-16 surrogate code point.
---| 5 # Code point exceeds U+10FFFF.
---| 6 # Not a valid code point (negative).

--- [SHARED AND MENU]
---
--- Encodes a single code point into a UTF-16 sequence of 1 or 2 code units (2 or 4 bytes).
---
---@param utf16_codepoint integer The code point to encode.
---@param lax? boolean If `true`, invalid code points (surrogates, negative or above `U+10FFFF`) are encoded as `U+FFFD` instead of raising an error.
---@param big_endian? boolean Whether to encode as big-endian.
---@param stack_level? integer The error level, relative to the caller, `1` (default) blames the caller of this function.
---@return string utf16_sequence The UTF-16 sequence.
---@nodiscard
function utf16.encode(utf16_codepoint, lax, big_endian, stack_level) end

--- [SHARED AND MENU]
---
--- Decodes a single UTF-16 sequence starting at the given byte position.
---
--- In lax mode invalid sequences are not raised, `nil` is returned as the code point
--- together with the number of bytes to skip, the error position and the error code.
---
---@param utf16_string string The UTF-16 string to decode from.
---@param index? integer The position of the sequence in bytes, `1` by default.
---@param end_index? integer The last byte that can be read, the end of the string by default.
---@param lax? boolean Whether to lax the UTF-16 validity check.
---@param big_endian? boolean Whether the string is big-endian.
---@param stack_level? integer The error level, relative to the caller, `1` (default) blames the caller of this function.
---@return integer | nil utf16_codepoint The decoded code point, or `nil` if the sequence is invalid.
---@return integer sequence_length The length of the sequence in bytes, at least `1`.
---@return integer | nil error_position The position of the invalid sequence.
---@return utf16.ErrorCode | nil error_code The error code.
---@nodiscard
function utf16.decode(utf16_string, index, end_index, lax, big_endian, stack_level) end

--- [SHARED AND MENU]
---
--- Returns the number of code points in a UTF-16 string.
---
---@param utf16_string string The UTF-16 string to get the length of.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-16 validity check, invalid sequences count as one code point each.
---@param big_endian? boolean Whether the string is big-endian.
---@return integer utf16_codepoint_count The number of code points.
---@nodiscard
function utf16.len(utf16_string, start_position, end_position, lax, big_endian) end

--- [SHARED AND MENU]
---
--- Decodes a UTF-16 string into a table of code points.
---
--- Invalid sequences raise an error, or are replaced with U+FFFD if `lax` is `true`.
---
---@param utf16_string string The UTF-16 string to decode.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-16 validity check.
---@param big_endian? boolean Whether the string is big-endian.
---@return integer[] utf16_codepoints The code points.
---@return integer utf16_codepoint_count The number of code points.
---@nodiscard
function utf16.unpack(utf16_string, start_position, end_position, lax, big_endian) end

--- [SHARED AND MENU]
---
--- Encodes a table of code points into a UTF-16 string.
---
--- Invalid code points raise an error, or are replaced with U+FFFD if `lax` is `true`.
---
---@param utf16_codepoints integer[] The code points to encode.
---@param utf16_codepoint_count? integer The number of code points to encode.
---@param lax? boolean Whether to lax the UTF-16 validity check.
---@param big_endian? boolean Whether to produce a big-endian string.
---@return string utf16_string The UTF-16 string.
---@nodiscard
function utf16.pack(utf16_codepoints, utf16_codepoint_count, lax, big_endian) end

--- [SHARED AND MENU]
---
--- Encodes code points into a little-endian UTF-16 string.
---
--- This functions similarly to `string.char`, use `utf16.pack` for big-endian strings.
---
---@param a integer The code points to encode.
---@param b integer The code points to encode.
---@param ... integer The code points to encode.
---@return string utf16_string The UTF-16 string.
---@nodiscard
function utf16.char(a, b, ...) end

--- [SHARED AND MENU]
---
--- Returns the code points of all characters that start between byte positions
--- `start_position` and `end_position` (both inclusive).
---
--- This functions similarly to `string.byte`, use `utf16.unpack` for long strings.
---
---@param utf16_string string The UTF-16 string to decode.
---@param start_position? integer The position to start from in bytes, defaults to `1`.
---@param end_position? integer The position to end at in bytes, defaults to `start_position`.
---@param lax? boolean Whether to lax the UTF-16 validity check.
---@param big_endian? boolean Whether the string is big-endian.
---@return integer ... The code points.
---@nodiscard
function utf16.codepoint(utf16_string, start_position, end_position, lax, big_endian) end

--- [SHARED AND MENU]
---
--- Returns the byte position of a code point in UTF-16 string.
---
---@param utf16_string string The UTF-16 string to search in.
---@param index integer The code point to search for, `0` returns the start of the code point containing byte `offset`.
---@param offset? integer The position to start from in bytes.
---@param lax? boolean Whether to lax the UTF-16 validity check.
---@param big_endian? boolean Whether the string is big-endian.
---@return integer | nil index The position of the code point in bytes or `nil` if not found.
---@nodiscard
function utf16.offset(utf16_string, index, offset, lax, big_endian) end

--- [SHARED AND MENU]
---
--- Returns a substring of the UTF-16 string, positions are in code points.
---
--- This functions similarly to `string.sub`, negative positions count from the end of the string.
---
---@param utf16_string string The UTF-16 string to get the substring of.
---@param start_position? integer The position to start from in code points.
---@param end_position? integer The position to end at in code points.
---@param lax? boolean Whether to lax the UTF-16 validity check.
---@param big_endian? boolean Whether the string is big-endian.
---@return string utf16_sub The substring.
---@nodiscard
function utf16.sub(utf16_string, start_position, end_position, lax, big_endian) end

--- [SHARED AND MENU]
---
--- Returns the reverse of a UTF-16 string, surrogate pairs are kept intact.
---
--- This functions similarly to `string.reverse`
---
---@param utf16_string string The UTF-16 string to reverse.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-16 validity check, invalid sequences are replaced with U+FFFD.
---@param big_endian? boolean Whether the string is big-endian.
---@return string utf16_reversed The reversed UTF-16 string.
---@nodiscard
function utf16.reverse(utf16_string, start_position, end_position, lax, big_endian) end

---@param utf16_string string
---@param start_position? integer
---@param end_position? integer
---@param lax? boolean
---@param big_endian? boolean
---@return string utf16_reversed
---@nodiscard
function utf16.reverse(utf16_string, start_position, end_position, lax, big_endian) end

--- [SHARED AND MENU]
---
--- Normalizes a UTF-16 string.
---
--- This function will replace all invalid UTF-16 sequences (unpaired surrogates, odd trailing byte).
---
---@param utf16_string string The UTF-16 string to normalize.
---@param replacement_str? string The string to replace invalid sequences with, by default U+FFFD in the string's byte order.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param big_endian? boolean Whether the string is big-endian.
---@return string utf16_normalized The normalized UTF-16 string.
---@nodiscard
function utf16.normalize(utf16_string, replacement_str, start_position, end_position, big_endian) end

--- [SHARED AND MENU]
---
--- Returns an iterator function that iterates over the code points of a UTF-16 string.
---
--- Invalid sequences raise an error, or yield U+FFFD if `lax` is `true`.
---
---@param utf16_string string The UTF-16 string to iterate over.
---@param lax? boolean Whether to lax the UTF-16 validity check.
---@param big_endian? boolean Whether the string is big-endian.
---@return ( fun( utf16_string: string, index: integer ): integer | nil, integer | nil ), string, integer
---@nodiscard
function utf16.codes(utf16_string, lax, big_endian) end
