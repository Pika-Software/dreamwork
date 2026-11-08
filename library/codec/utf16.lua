---@meta _

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
---@param lax boolean? If `true`, invalid code points (surrogates, negative or above `U+10FFFF`) are encoded as `U+FFFD` instead of raising an error.
---@param big_endian boolean? Whether to encode as big-endian.
---@param stack_level integer? The error level, relative to the caller, `1` (default) blames the caller of this function.
---@return string utf16_sequence The UTF-16 sequence.
---@nodiscard
function utf16.encode(utf16_codepoint, lax, big_endian, stack_level) end

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
---@return utf16.ErrorCode | nil error_code The error code, `nil` if the sequence is valid.
---@nodiscard
function utf16.decode(utf16_string, index, end_index, lax, big_endian, stack_level) end

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
function utf16.len(utf16_string, start_position, end_position, lax, big_endian) end

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
function utf16.unpack(utf16_string, start_position, end_position, lax, big_endian) end

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
function utf16.pack(utf16_codepoints, utf16_codepoint_count, lax, big_endian) end

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
function utf16.char(a, b, ...) end

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
function utf16.codepoint(utf16_string, start_position, end_position, lax, big_endian) end

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
function utf16.offset(utf16_string, n, position, lax, big_endian) end

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
function utf16.sub(utf16_string, start_position, end_position, lax, big_endian) end

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
function utf16.reverse(utf16_string, start_position, end_position, lax, big_endian) end

---@param utf16_string string
---@param start_position integer?
---@param end_position integer?
---@param lax boolean?
---@param big_endian boolean?
---@return string utf16_reversed
---@nodiscard
function utf16.reverse(utf16_string, start_position, end_position, lax, big_endian) end

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
function utf16.normalize(utf16_string, replacement_str, start_position, end_position, big_endian) end

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
function utf16.codes(utf16_string, lax, big_endian) end
