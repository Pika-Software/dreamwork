---@meta _

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
---@param lax boolean? If `true`, invalid code points (surrogates, negative or above `U+10FFFF`) are encoded as `U+FFFD` instead of raising an error.
---@param big_endian boolean? Whether to encode as big-endian.
---@param stack_level integer? The error level, relative to the caller, `1` (default) blames the caller of this function.
---@return string utf32_sequence The UTF-32 sequence.
---@nodiscard
function utf32.encode(utf32_codepoint, lax, big_endian, stack_level) end

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
---@return utf32.ErrorCode | nil error_code The error code, `nil` if the sequence is valid.
---@nodiscard
function utf32.decode(utf32_string, index, end_index, lax, big_endian, stack_level) end

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
function utf32.len(utf32_string, start_position, end_position, lax, big_endian) end

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
function utf32.unpack(utf32_string, start_position, end_position, lax, big_endian) end

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
function utf32.pack(utf32_codepoints, utf32_codepoint_count, lax, big_endian) end

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
function utf32.char(a, b, ...) end

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
function utf32.codepoint(utf32_string, start_position, end_position, lax, big_endian) end

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
function utf32.offset(utf32_string, n, position, lax, big_endian) end

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
function utf32.sub(utf32_string, start_position, end_position, lax, big_endian) end

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
function utf32.reverse(utf32_string, start_position, end_position, lax, big_endian) end

---@param utf32_string string
---@param start_position integer?
---@param end_position integer?
---@param lax boolean?
---@param big_endian boolean?
---@return string utf32_reversed
---@nodiscard
function utf32.reverse(utf32_string, start_position, end_position, lax, big_endian) end

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
function utf32.normalize(utf32_string, replacement_str, start_position, end_position, big_endian) end

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
function utf32.codes(utf32_string, lax, big_endian) end
