---@meta _

--- [SHARED AND MENU]
---
--- The utf8 library is a standard Lua library which provides functions for the manipulation of UTF-8 strings.
---
--- In dreamwork utf8 library rewrited from zero and contains additional functions.
---
---@class utf8lib
---@field charpattern string This is NOT a function, it's a pattern (a string, not a function) which matches exactly one UTF-8 byte sequence, assuming that the subject is a valid UTF-8 string.
utf8 = {}

utf8.charpattern = "[%z\x01-\x7F\xC2-\xF4][\x80-\xBF]*"

---@alias utf8.ErrorCode
---| 1 # Unexpected end of string.
---| 2 # Unexpected continuation byte.
---| 3 # Invalid lead byte.
---| 4 # Invalid continuation byte.
---| 5 # Overlong encoding.
---| 6 # UTF-16 surrogate code point.
---| 7 # Code point exceeds U+10FFFF.
---| 8 # Not a valid code point (negative).

--- [SHARED AND MENU]
---
--- Encodes a single code point into a UTF-8 sequence.
---
---@param utf8_codepoint integer The code point to encode.
---@param lax? boolean If `true`, invalid code points (surrogates, negative or above `U+10FFFF`) are encoded as `U+FFFD` instead of raising an error.
---@param stack_level? integer The error level, relative to the caller, `1` (default) blames the caller of this function.
---@return string utf8_sequence The UTF-8 sequence, 1 to 4 bytes long.
---@nodiscard
function utf8.encode(utf8_codepoint, lax, stack_level) end

--- [SHARED AND MENU]
---
--- Decodes a single UTF-8 sequence starting at the given byte position.
---
--- In lax mode invalid sequences are not raised, `nil` is returned as the code point
--- together with the number of bytes to skip, the error position and the error code.
---
---@param utf8_string string The UTF-8 string to decode from.
---@param index? integer The position of the sequence in bytes, `1` by default.
---@param end_index? integer The last byte that can be read, the end of the string by default.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@param stack_level? integer The error level, relative to the caller, `1` (default) blames the caller of this function.
---@return integer | nil utf8_codepoint The decoded code point, or `nil` if the sequence is invalid.
---@return integer sequence_length The length of the sequence in bytes, at least `1`.
---@return integer | nil error_position The position of the invalid byte.
---@return utf8.ErrorCode | nil error_code The error code.
---@nodiscard
function utf8.decode(utf8_string, index, end_index, lax, stack_level) end

--- [SHARED AND MENU]
---
--- Returns the length of the string in UTF-8 code units.
---
---@param utf8_string string The UTF-8/16/32 string to get the length of.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return integer sequence_length The length of the string in UTF-8 code units.
---@nodiscard
function utf8.len(utf8_string, start_position, end_position, lax) end

--- [SHARED AND MENU]
---
--- Returns a table of UTF-8 code points and the length of the string in UTF-8 code units.
---
---@param utf8_string string The UTF-8/16/32 string to get the length of.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return integer[] utf8_codepoints A table of UTF-8 code points.
---@return integer utf8_codepoint_count The length of the string in UTF-8 code units.
---@nodiscard
function utf8.unpack(utf8_string, start_position, end_position, lax) end

--- [SHARED AND MENU]
---
--- Returns a substring of the string in UTF-8 code units.
---
--- This functions similarly to `string.sub`, negative positions count from the end of the string.
---
---@param utf8_string string The UTF-8/16/32 string to get the substring of.
---@param start_position? integer The position to start from in UTF-8 code units.
---@param end_position? integer The position to end at in UTF-8 code units.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return string utf8_sub The substring of the string in UTF-8 code units.
---@nodiscard
function utf8.sub(utf8_string, start_position, end_position, lax) end

--- [SHARED AND MENU]
---
--- Returns the code points of all characters that start between byte positions
--- `start_position` and `end_position` (both inclusive).
---
--- This functions similarly to `string.byte`, use `utf8.unpack` for long strings.
---
---@param utf8_string string The UTF-8 string to decode.
---@param start_position? integer The position to start from in bytes, defaults to `1`.
---@param end_position? integer The position to end at in bytes, defaults to `start_position`.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return integer ... The code points of the UTF-8 string.
---@nodiscard
function utf8.codepoint(utf8_string, start_position, end_position, lax) end

--- [SHARED AND MENU]
---
--- Returns an iterator function that iterates over the code points of a UTF-8 string.
---
--- Invalid sequences raise an error, or yield U+FFFD if `lax` is `true`.
---
---@param utf8_string string The UTF-8 string to iterate over.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return ( fun( utf8_string: string, index: integer ): integer | nil, integer | nil ), string, integer
---@nodiscard
function utf8.codes(utf8_string, lax) end

---@param utf8_codepoints integer[]
---@param utf8_codepoint_count? integer
---@param lax? boolean
---@return string utf8_string
---@nodiscard
function utf8.pack(utf8_codepoints, utf8_codepoint_count, lax) end

--- [SHARED AND MENU]
---
--- Encodes a sequence of code points into a UTF-8 string.
---
--- This functions similarly to `string.char`
---
---@param a integer The code points to encode.
---@param b integer The code points to encode.
---@param ... integer The code points to encode.
---@return string utf8_string The UTF-8 string.
---@nodiscard
function utf8.char(a, b, ...) end

--- [SHARED AND MENU]
---
--- Returns the byte position of a code point in UTF-8 string.
---
---@param utf8_string string The UTF-8 string to search in.
---@param index integer The code point to search for in the UTF-8 units, `0` returns the start of the code point containing byte `offset`.
---@param offset? integer The position to start from in bytes.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return integer | nil index The position of the code point in bytes or `nil` if not found.
---@nodiscard
function utf8.offset(utf8_string, index, offset, lax) end

--- [SHARED AND MENU]
---
--- Returns the reverse of a UTF-8 string.
---
--- This functions similarly to `string.reverse`
---
---@param utf8_string string The UTF-8 string to reverse.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-8 validity check, invalid sequences are replaced with U+FFFD.
---@return string utf8_reversed The reversed UTF-8 string.
---@nodiscard
function utf8.reverse(utf8_string, start_position, end_position, lax) end

---@param utf8_string string
---@param start_position? integer
---@param end_position? integer
---@param lax? boolean
---@return string utf8_reversed
---@nodiscard
function utf8.reverse(utf8_string, start_position, end_position, lax) end

--- [SHARED AND MENU]
---
--- Normalizes a UTF-8 string.
---
--- This function will remove all invalid UTF-8 code points.
---
---@param utf8_string string The UTF-8 string to normalize.
---@param replacement_str? string The string to replace invalid UTF-8 code points with, by default `0xFFFD`.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@return string utf8_normalized The normalized UTF-8 string.
---@nodiscard
function utf8.normalize(utf8_string, replacement_str, start_position, end_position) end
