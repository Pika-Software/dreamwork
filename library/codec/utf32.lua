---@meta _

--- [SHARED AND MENU]
---
--- The utf32 library provides functions for the manipulation of UTF-32 strings.
---
--- All positions are in bytes, all functions use little-endian byte order
--- unless `big_endian` is `true`.
---
---@class utf32
utf32 = {}

---@alias utf32.ErrorCode
---| 1 # Unexpected end of string (length is not a multiple of 4).
---| 2 # UTF-16 surrogate code point.
---| 3 # Code point exceeds U+10FFFF.
---| 4 # Not a valid code point (negative).

--- [SHARED AND MENU]
---
--- Encodes a single code point into a UTF-32 sequence of 1 code unit (4 bytes).
---
---@param utf32_codepoint integer The code point to encode.
---@param lax? boolean If `true`, invalid code points (surrogates, negative or above `U+10FFFF`) are encoded as `U+FFFD` instead of raising an error.
---@param big_endian? boolean Whether to encode as big-endian.
---@param stack_level? integer The error level, relative to the caller, `1` (default) blames the caller of this function.
---@return string utf32_sequence The UTF-32 sequence.
---@nodiscard
function utf32.encode(utf32_codepoint, lax, big_endian, stack_level) end

--- [SHARED AND MENU]
---
--- Decodes a single UTF-32 sequence starting at the given byte position.
---
--- In lax mode invalid sequences are not raised, `nil` is returned as the code point
--- together with the number of bytes to skip, the error position and the error code.
---
---@param utf32_string string The UTF-32 string to decode from.
---@param index? integer The position of the sequence in bytes, `1` by default.
---@param end_index? integer The last byte that can be read, the end of the string by default.
---@param lax? boolean Whether to lax the UTF-32 validity check.
---@param big_endian? boolean Whether the string is big-endian.
---@param stack_level? integer The error level, relative to the caller, `1` (default) blames the caller of this function.
---@return integer | nil utf32_codepoint The decoded code point, or `nil` if the sequence is invalid.
---@return integer sequence_length The length of the sequence in bytes, at least `1`.
---@return integer | nil error_position The position of the invalid sequence.
---@return utf32.ErrorCode | nil error_code The error code.
---@nodiscard
function utf32.decode(utf32_string, index, end_index, lax, big_endian, stack_level) end

--- [SHARED AND MENU]
---
--- Returns the number of code points in a UTF-32 string.
---
---@param utf32_string string The UTF-32 string to get the length of.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-32 validity check, invalid sequences count as one code point each.
---@param big_endian? boolean Whether the string is big-endian.
---@return integer utf32_codepoint_count The number of code points.
---@nodiscard
function utf32.len(utf32_string, start_position, end_position, lax, big_endian) end

--- [SHARED AND MENU]
---
--- Decodes a UTF-32 string into a table of code points.
---
--- Invalid sequences raise an error, or are replaced with U+FFFD if `lax` is `true`.
---
---@param utf32_string string The UTF-32 string to decode.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-32 validity check.
---@param big_endian? boolean Whether the string is big-endian.
---@return integer[] utf32_codepoints The code points.
---@return integer utf32_codepoint_count The number of code points.
---@nodiscard
function utf32.unpack(utf32_string, start_position, end_position, lax, big_endian) end

--- [SHARED AND MENU]
---
--- Encodes a table of code points into a UTF-32 string.
---
--- Invalid code points raise an error, or are replaced with U+FFFD if `lax` is `true`.
---
---@param utf32_codepoints integer[] The code points to encode.
---@param utf32_codepoint_count? integer The number of code points to encode.
---@param lax? boolean Whether to lax the UTF-32 validity check.
---@param big_endian? boolean Whether to produce a big-endian string.
---@return string utf32_string The UTF-32 string.
---@nodiscard
function utf32.pack(utf32_codepoints, utf32_codepoint_count, lax, big_endian) end

--- [SHARED AND MENU]
---
--- Encodes code points into a little-endian UTF-32 string.
---
--- This functions similarly to `string.char`, use `utf32.pack` for big-endian strings.
---
---@param a integer The code points to encode.
---@param b integer The code points to encode.
---@param ... integer The code points to encode.
---@return string utf32_string The UTF-32 string.
---@nodiscard
function utf32.char(a, b, ...) end

--- [SHARED AND MENU]
---
--- Returns the code points of all characters that start between byte positions
--- `start_position` and `end_position` (both inclusive).
---
--- This functions similarly to `string.byte`, use `utf32.unpack` for long strings.
---
---@param utf32_string string The UTF-32 string to decode.
---@param start_position? integer The position to start from in bytes, defaults to `1`.
---@param end_position? integer The position to end at in bytes, defaults to `start_position`.
---@param lax? boolean Whether to lax the UTF-32 validity check.
---@param big_endian? boolean Whether the string is big-endian.
---@return integer ... The code points.
---@nodiscard
function utf32.codepoint(utf32_string, start_position, end_position, lax, big_endian) end

--- [SHARED AND MENU]
---
--- Returns the byte position of a code point in UTF-32 string.
---
---@param utf32_string string The UTF-32 string to search in.
---@param index integer The code point to search for, `0` returns the start of the code point containing byte `offset`.
---@param offset? integer The position to start from in bytes.
---@param lax? boolean Whether to lax the UTF-32 validity check.
---@param big_endian? boolean Whether the string is big-endian.
---@return integer | nil index The position of the code point in bytes or `nil` if not found.
---@nodiscard
function utf32.offset(utf32_string, index, offset, lax, big_endian) end

--- [SHARED AND MENU]
---
--- Returns a substring of the UTF-32 string, positions are in code points.
---
--- This functions similarly to `string.sub`, negative positions count from the end of the string.
---
---@param utf32_string string The UTF-32 string to get the substring of.
---@param start_position? integer The position to start from in code points.
---@param end_position? integer The position to end at in code points.
---@param lax? boolean Whether to lax the UTF-32 validity check.
---@param big_endian? boolean Whether the string is big-endian.
---@return string utf32_sub The substring.
---@nodiscard
function utf32.sub(utf32_string, start_position, end_position, lax, big_endian) end

--- [SHARED AND MENU]
---
--- Returns the reverse of a UTF-32 string.
---
--- This functions similarly to `string.reverse`
---
---@param utf32_string string The UTF-32 string to reverse.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-32 validity check, invalid sequences are replaced with U+FFFD.
---@param big_endian? boolean Whether the string is big-endian.
---@return string utf32_reversed The reversed UTF-32 string.
---@nodiscard
function utf32.reverse(utf32_string, start_position, end_position, lax, big_endian) end

---@param utf32_string string
---@param start_position? integer
---@param end_position? integer
---@param lax? boolean
---@param big_endian? boolean
---@return string utf32_reversed
---@nodiscard
function utf32.reverse(utf32_string, start_position, end_position, lax, big_endian) end

--- [SHARED AND MENU]
---
--- Normalizes a UTF-32 string.
---
--- This function will replace all invalid UTF-32 sequences (surrogates, values above U+10FFFF, truncated tail).
---
---@param utf32_string string The UTF-32 string to normalize.
---@param replacement_str? string The string to replace invalid sequences with, by default U+FFFD in the string's byte order.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param big_endian? boolean Whether the string is big-endian.
---@return string utf32_normalized The normalized UTF-32 string.
---@nodiscard
function utf32.normalize(utf32_string, replacement_str, start_position, end_position, big_endian) end

--- [SHARED AND MENU]
---
--- Returns an iterator function that iterates over the code points of a UTF-32 string.
---
--- Invalid sequences raise an error, or yield U+FFFD if `lax` is `true`.
---
---@param utf32_string string The UTF-32 string to iterate over.
---@param lax? boolean Whether to lax the UTF-32 validity check.
---@param big_endian? boolean Whether the string is big-endian.
---@return ( fun( utf32_string: string, index: integer ): integer | nil, integer | nil ), string, integer
---@nodiscard
function utf32.codes(utf32_string, lax, big_endian) end
