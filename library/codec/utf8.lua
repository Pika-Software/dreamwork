---@meta _

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
---@class utf8lib
---@field charpattern string The pattern (a string, not a function) that matches exactly one UTF-8 byte sequence, assuming that the subject is a valid UTF-8 string.
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
---@param lax boolean? If `true`, invalid code points (surrogates, negative or above U+10FFFF) are encoded as U+FFFD instead of raising an error.
---@param stack_level integer? The error level, relative to the caller, `1` (default) blames the caller of this function.
---@return string utf8_sequence The UTF-8 sequence, 1 to 4 bytes long.
---@nodiscard
function utf8.encode(utf8_codepoint, lax, stack_level) end

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
---@return utf8.ErrorCode | nil error_code The error code, `nil` if the sequence is valid.
---@nodiscard
function utf8.decode(utf8_string, index, end_index, lax, stack_level) end

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
function utf8.len(utf8_string, start_position, end_position, lax) end

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
function utf8.unpack(utf8_string, start_position, end_position, lax) end

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
function utf8.sub(utf8_string, start_position, end_position, lax) end

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
function utf8.codepoint(utf8_string, start_position, end_position, lax) end

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
function utf8.codes(utf8_string, lax) end

---@param utf8_codepoints integer[]
---@param utf8_codepoint_count integer?
---@param lax boolean?
---@return string utf8_string
---@nodiscard
function utf8.pack(utf8_codepoints, utf8_codepoint_count, lax) end

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
function utf8.char(a, b, ...) end

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
function utf8.offset(utf8_string, n, position, lax) end

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
function utf8.reverse(utf8_string, start_position, end_position, lax) end

---@param utf8_string string
---@param start_position integer?
---@param end_position integer?
---@param lax boolean?
---@return string utf8_reversed
---@nodiscard
function utf8.reverse(utf8_string, start_position, end_position, lax) end

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
function utf8.normalize(utf8_string, replacement_str, start_position, end_position) end
