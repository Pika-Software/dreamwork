---@meta _

--- [SHARED AND MENU]
---
--- The unicode library provides functions for working with unicode code points,
--- unicode escape sequences, case mapping, display width and blocks of UTF-8 strings.
---
---@class unicode
---@field MAX integer The largest valid unicode code point, `U+10FFFF`.
---@field REPLACEMENT integer The replacement character code point, `U+FFFD`.
---@field BOM integer The byte order mark code point, `U+FEFF`.
unicode = {}

unicode.MAX = 0x10FFFF

unicode.REPLACEMENT = 0xFFFD

unicode.BOM = 0xFEFF

--- [SHARED AND MENU]
---
--- Checks if the given value is a unicode scalar value, an integer in range `U+0000` - `U+10FFFF` that is not a surrogate.
---
--- Only scalar values can be encoded in UTF-8.
---
---@param utf8_codepoint integer The code point to check.
---@return boolean is_valid `true` if the code point is a unicode scalar value, `false` otherwise.
---@nodiscard
function unicode.isValid(utf8_codepoint) end

--- [SHARED AND MENU]
---
--- Checks if the given code point is a UTF-16 surrogate, in range `U+D800` - `U+DFFF`.
---
---@param utf8_codepoint integer The code point to check.
---@return boolean is_surrogate `true` if the code point is a surrogate, `false` otherwise.
---@nodiscard
function unicode.isSurrogate(utf8_codepoint) end

--- [SHARED AND MENU]
---
--- Checks if the given code point is a UTF-16 high (leading) surrogate, in range `U+D800` - `U+DBFF`.
---
---@param utf8_codepoint integer The code point to check.
---@return boolean is_high_surrogate `true` if the code point is a high surrogate, `false` otherwise.
---@nodiscard
function unicode.isHighSurrogate(utf8_codepoint) end

--- [SHARED AND MENU]
---
--- Checks if the given code point is a UTF-16 low (trailing) surrogate, in range `U+DC00` - `U+DFFF`.
---
---@param utf8_codepoint integer The code point to check.
---@return boolean is_low_surrogate `true` if the code point is a low surrogate, `false` otherwise.
---@nodiscard
function unicode.isLowSurrogate(utf8_codepoint) end

--- [SHARED AND MENU]
---
--- Checks if the given code point is a noncharacter, `U+FDD0` - `U+FDEF` or the last two code points of any plane (`U+xFFFE`, `U+xFFFF`).
---
---@param utf8_codepoint integer The code point to check.
---@return boolean is_noncharacter `true` if the code point is a noncharacter, `false` otherwise.
---@nodiscard
function unicode.isNoncharacter(utf8_codepoint) end

--- [SHARED AND MENU]
---
--- Checks if the given code point belongs to a private use area, `U+E000` - `U+F8FF`, `U+F0000` - `U+FFFFD` or `U+100000` - `U+10FFFD`.
---
---@param utf8_codepoint integer The code point to check.
---@return boolean is_private_use `true` if the code point is a private use code point, `false` otherwise.
---@nodiscard
function unicode.isPrivateUse(utf8_codepoint) end

--- [SHARED AND MENU]
---
--- Returns the unicode plane of the given code point, `0` for the Basic Multilingual Plane up to `16`.
---
---@param utf8_codepoint integer The code point.
---@return integer plane The plane number.
---@nodiscard
function unicode.plane(utf8_codepoint) end

--- [SHARED AND MENU]
---
--- Splits a supplementary code point (`U+10000` - `U+10FFFF`) into a UTF-16 surrogate pair.
---
---@param utf8_codepoint integer The supplementary code point.
---@return integer high_surrogate The high (leading) surrogate.
---@return integer low_surrogate The low (trailing) surrogate.
---@nodiscard
function unicode.toSurrogates(utf8_codepoint) end

--- [SHARED AND MENU]
---
--- Combines a UTF-16 surrogate pair into a supplementary code point.
---
---@param high_surrogate integer The high (leading) surrogate, `U+D800` - `U+DBFF`.
---@param low_surrogate integer The low (trailing) surrogate, `U+DC00` - `U+DFFF`.
---@return integer utf8_codepoint The code point in range `U+10000` - `U+10FFFF`.
---@nodiscard
function unicode.fromSurrogates(high_surrogate, low_surrogate) end

--- [SHARED AND MENU]
---
--- Returns a string representation of the given unicode code point.
---
---@param utf8_codepoint integer The unicode code point to represent.
---@return string utf8_tag The string representation of the code point, in the format `U+XXXX` - `U+XXXXXX`.
---@nodiscard
function unicode.tag(utf8_codepoint) end

--- [SHARED AND MENU]
---
--- Returns the unicode code point represented by the given string.
---
---@param utf8_tag string The string representation of a unicode code point, in the format `U+XXXX` - `U+XXXXXX`.
---@return integer | nil utf8_codepoint The unicode code point represented by the string, or `nil` if the string is not a valid tag.
---@nodiscard
function unicode.untag(utf8_tag) end

---@alias unicode.EscapeStyle
---| "json" # `\uXXXX`, supplementary code points are written as surrogate pairs `\uXXXX\uXXXX` (JSON, JavaScript, Java, C#).
---| "es6" # `\u{X}` for every code point (JavaScript ES6+, Lua 5.3+, Rust, Swift).
---| "python" # `\uXXXX`, supplementary code points are written as `\UXXXXXXXX` (Python, C, C++).

--- [SHARED AND MENU]
---
--- Converts each character in the input string into a unicode escape sequence,
--- suitable for serialization, logging, or safe ASCII output.
---
---@param utf8_str string The input string containing unicode characters.
---@param style? unicode.EscapeStyle The escape sequence style, `"json"` by default.
---@param keep_ascii? boolean If `true`, printable ASCII characters (except `\`) are left as is.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-8 validity check, invalid sequences are escaped as `U+FFFD`.
---@return string escaped_str A string where each character is replaced with its unicode escape sequence.
---@nodiscard
function unicode.escape(utf8_str, style, keep_ascii, start_position, end_position, lax) end

--- [SHARED AND MENU]
---
--- Converts unicode escape sequences into actual characters.
---
--- Supported formats are `\uXXXX` (exactly 4 hex digits), UTF-16 surrogate pairs `\uXXXX\uXXXX`,
--- `\u{X}` (any number of hex digits) and `\UXXXXXXXX` (exactly 8 hex digits).
---
--- `\\` is treated as an escaped backslash and left as is, malformed sequences are left as is.
---
---@param escaped_str string A string containing unicode escape sequences.
---@param lax? boolean If `true`, lone surrogates and code points above `U+10FFFF` are replaced with `U+FFFD` instead of raising an error.
---@return string utf8_str A string with the escape sequences converted to real unicode characters.
---@nodiscard
function unicode.unescape(escaped_str, lax) end

--- [SHARED AND MENU]
---
--- Converts a UTF-8 string to lowercase within the given byte range.
---
--- Each decoded codepoint that has a known uppercase-to-lowercase mapping is
--- replaced with its lowercase form; any codepoint with no such mapping
--- (already lowercase, digits, symbols, whitespace, or characters outside
--- the known case tables) is left unchanged.
---
--- Bytes outside the given range are always left untouched.
---
---@param utf8_string string The UTF-8 string to convert.
---@param start_position? integer The byte position to start converting from (inclusive). Defaults to 1. Negative values count from the end of the string.
---@param end_position? integer The byte position to stop converting at (inclusive). Defaults to the end of the string. Negative values count from the end of the string.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return string lowercase_utf8_str The string with the given range converted to lowercase; identical to the input if nothing in range needed conversion.
---@nodiscard
function unicode.lower(utf8_string, start_position, end_position, lax) end

--- [SHARED AND MENU]
---
--- Converts a UTF-8 string to uppercase within the given byte range.
---
--- Each decoded codepoint that has a known lowercase-to-uppercase mapping is
--- replaced with its uppercase form; any codepoint with no such mapping
--- (already uppercase, digits, symbols, whitespace, or characters outside
--- the known case tables) is left unchanged.
---
--- Bytes outside the given range are always left untouched.
---
---@param utf8_string string The UTF-8 string to convert.
---@param start_position? integer The byte position to start converting from (inclusive). Defaults to 1. Negative values count from the end of the string.
---@param end_position? integer The byte position to stop converting at (inclusive). Defaults to the end of the string. Negative values count from the end of the string.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return string uppercase_utf8_str The string with the given range converted to uppercase; identical to the input if nothing in range needed conversion.
---@nodiscard
function unicode.upper(utf8_string, start_position, end_position, lax) end

--- [SHARED AND MENU]
---
--- Capitalizes a UTF-8 string: the first case-able character within the given
--- range is converted to uppercase (left untouched if it's already uppercase),
--- and every case-able character after it is converted to lowercase.
---
--- Characters with no case mapping (digits, symbols, whitespace, etc.) are
--- skipped and do not count as "the first character".
---
---@param utf8_string string The UTF-8 string to capitalize.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return string capitalized_utf8_str The capitalized UTF-8 string.
---@nodiscard
function unicode.capitalize(utf8_string, start_position, end_position, lax) end

--- [SHARED AND MENU]
---
--- Converts a UTF-8 string to title case within the given range: the first
--- case-able character of each word is converted to uppercase (left alone if
--- already uppercase), and every other case-able character in the word is
--- converted to lowercase.
---
--- Words are separated by whitespace and punctuation, apostrophes (`'` and `’`),
--- digits and letters without case (`ß`, CJK, etc.) don't break a word.
---
---@param utf8_string string The UTF-8 string to convert to title case.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return string title_utf8_str The title-cased UTF-8 string.
---@nodiscard
function unicode.title(utf8_string, start_position, end_position, lax) end

--- [SHARED AND MENU]
---
--- Returns the number of terminal columns the given code point takes in a monospace font.
---
--- * `0` for control characters, combining marks, format characters (ZWJ, ZWSP, BOM, ...) and variation selectors.
--- * `2` for East Asian wide and fullwidth characters (CJK, kana, hangul) and emoji.
--- * `1` for everything else.
---
--- Use `unicode.displayWidth` for strings, it also handles emoji sequences.
---
---@param utf8_codepoint integer The code point.
---@return integer width The width of the code point in columns, `0`, `1` or `2`.
---@nodiscard
function unicode.width(utf8_codepoint) end

--- [SHARED AND MENU]
---
--- Returns the number of terminal columns the given UTF-8 string takes in a monospace font.
---
--- Unlike `utf8.len`, wide characters (CJK, emoji) count as `2`, combining marks
--- and other zero-width characters count as `0`, emoji ZWJ sequences (`👨‍👩‍👧`),
--- skin tones (`👍🏽`) and flags (`🇺🇦`) count as a single wide character.
---
--- The result depends on the font and terminal, emoji are rendered inconsistently across them.
---
---@param utf8_string string The UTF-8 string to measure.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-8 validity check, invalid sequences count as `U+FFFD`.
---@return integer width The width of the string in columns.
---@nodiscard
function unicode.displayWidth(utf8_string, start_position, end_position, lax) end

--- [SHARED AND MENU]
---
--- Wraps a UTF-8 string so that no line is wider than `max_width` columns (see `unicode.displayWidth`),
--- breaking on the last ASCII space before the limit when one is available
--- within the current line, or hard-splitting mid-word otherwise.
---
--- Zero-width characters stay with the character they belong to, so a line
--- can only exceed `max_width` when a single wide character doesn't fit into it.
---
--- Lines are joined with "\n", existing "\n" characters start a new line.
---
--- Bytes outside the given range are left untouched and don't count towards the line width.
---
---@param utf8_string string The UTF-8 string to wrap.
---@param max_width integer The maximum width of each line, in columns.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return string wrapped_string The string with newlines inserted so no line is wider than `max_width` columns.
---@nodiscard
function unicode.wrap(utf8_string, max_width, start_position, end_position, lax) end

--- [SHARED AND MENU]
---
--- Pads a UTF-8 string with a repeated padding string until it is `desired_width` columns wide
--- (see `unicode.displayWidth`), on the left, the right, or both sides evenly.
---
--- If neither `left` nor `right` is `true`, `padding` has no width, or the string is already
--- at least `desired_width` columns wide, `utf8_string` is returned unchanged.
---
--- When padding both sides, the missing width is split as evenly as possible between the
--- left and right, with any extra leftover column going to the right side; if it doesn't divide
--- evenly by whole copies of `padding`, the shortfall is made up with a partial copy of `padding`,
--- and with spaces where a wide character of `padding` doesn't fit.
---
---@param utf8_string string The UTF-8 string to pad.
---@param desired_width integer The target width, in columns, that the result should reach.
---@param padding string? The string to pad with, repeated as needed. Defaults to a single space.
---@param left boolean? Whether to add padding on the left side.
---@param right boolean? Whether to add padding on the right side.
---@param lax boolean? Whether to lax the UTF-8 validity check.
---@return string result The padded string, or `utf8_string` unchanged if no padding was needed or requested.
---@nodiscard
function unicode.pad(utf8_string, desired_width, padding, left, right, lax) end

--- [SHARED AND MENU]
---
--- Returns the name and the range of the unicode block that contains the given code point.
---
--- Some ranges are not assigned to any block, `nil` is returned for them.
---
---@param utf8_codepoint integer The code point.
---@return string | nil block_name The name of the block, e.g. `"Basic Latin"` or `"CJK Unified Ideographs"`.
---@return integer | nil first_codepoint The first code point of the block.
---@return integer | nil last_codepoint The last code point of the block.
---@nodiscard
function unicode.block(utf8_codepoint) end

--- [SHARED AND MENU]
---
--- Returns an iterator over all unicode blocks in code point order.
---
--- ```lua
--- for block_name, first_codepoint, last_codepoint in unicode.blocks() do
---     print( block_name, unicode.tag( first_codepoint ), unicode.tag( last_codepoint ) )
--- end
--- ```
---
---@return fun(): string, integer, integer iterator The iterator function, returns the name, the first and the last code point of each block.
---@nodiscard
function unicode.blocks() end
