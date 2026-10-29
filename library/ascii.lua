---@meta _

--- [SHARED AND MENU]
---
--- An ASCII library that provides functions for this encoding.
---
--- All functions operate on single bytes (integers in the range 0x00–0xFF),
--- as returned by `string.byte`, and do not accept `nil`.
---
---@class ascii
ascii = {}

--- [SHARED AND MENU]
---
--- Checks if the byte is a lowercase ASCII letter (a–z).
---
---@param uint8 byte The byte to check.
---@return boolean is_lower `true` if the byte is in the range 0x61–0x7A.
---@nodiscard
function ascii.isLower(uint8) end

--- [SHARED AND MENU]
---
--- Checks if the byte is an uppercase ASCII letter (A–Z).
---
---@param uint8 byte The byte to check.
---@return boolean is_upper `true` if the byte is in the range 0x41–0x5A.
---@nodiscard
function ascii.isUpper(uint8) end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII alphabetic character (a–z or A–Z).
---
---@param uint8 byte The byte to check.
---@return boolean is_alpha `true` if the byte is a lowercase or uppercase letter.
---@nodiscard
function ascii.isAlpha(uint8) end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII decimal digit (0–9).
---
---@param uint8 byte The byte to check.
---@return boolean is_digit `true` if the byte is in the range 0x30–0x39.
---@nodiscard
function ascii.isDigit(uint8) end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII binary digit (0–1).
---
---@param uint8 byte The byte to check.
---@return boolean is_binary_digit `true` if the byte is `0` or `1`.
---@nodiscard
function ascii.isBinaryDigit(uint8) end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII octal digit (0–7).
---
---@param uint8 byte The byte to check.
---@return boolean is_octal_digit `true` if the byte is in the range 0x30–0x37.
---@nodiscard
function ascii.isOctalDigit(uint8) end

--- [SHARED AND MENU]
---
--- Checks if the byte is a valid hexadecimal digit (0–9, A–F, a–f).
---
---@param uint8 byte The byte to check.
---@return boolean is_hex_digit `true` if the byte is a decimal digit or a hex letter.
---@nodiscard
function ascii.isHexDigit(uint8) end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII alphanumeric character (A–Z, a–z, or 0–9).
---
---@param uint8 byte The byte to check.
---@return boolean is_alnum `true` if the byte is an ASCII letter or decimal digit.
---@nodiscard
function ascii.isAlnum(uint8) end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII word character (A–Z, a–z, 0–9 or `_`),
--- i.e. a character allowed in identifiers.
---
---@param uint8 byte The byte to check.
---@return boolean is_word `true` if the byte is an ASCII letter, decimal digit or underscore.
---@nodiscard
function ascii.isWord(uint8) end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII whitespace character.
--- Matches: space (0x20), horizontal tab (0x09), line feed (0x0A),
--- vertical tab (0x0B), form feed (0x0C), and carriage return (0x0D).
---
---@param uint8 byte The byte to check.
---@return boolean is_space `true` if the byte is a whitespace character, `false` otherwise.
---@nodiscard
function ascii.isSpace(uint8) end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII blank character, i.e. space (0x20) or horizontal tab (0x09).
---
---@param uint8 byte The byte to check.
---@return boolean is_blank `true` if the byte is a space or a horizontal tab.
---@nodiscard
function ascii.isBlank(uint8) end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII character, i.e. in the range 0x00–0x7F.
---
---@param uint8 byte The byte to check.
---@return boolean is_ascii `true` if the byte is not greater than 0x7F.
---@nodiscard
function ascii.isASCII(uint8) end

--- [SHARED AND MENU]
---
--- Checks if the byte is an extended (non-ASCII) byte, i.e. above 0x7F.
--- These bytes appear in multi-byte UTF-8 sequences and Latin-1 supplements.
---
---@param uint8 byte The byte to check.
---@return boolean is_extended `true` if the byte is greater than 0x7F.
---@nodiscard
function ascii.isExtended(uint8) end

--- [SHARED AND MENU]
---
--- Checks if the byte is a printable ASCII character (0x20–0x7E), space included.
---
---@param uint8 byte The byte to check.
---@return boolean is_printable `true` if the byte is a printable character.
---@nodiscard
function ascii.isPrintable(uint8) end

--- [SHARED AND MENU]
---
--- Checks if the byte is a visible ASCII character (0x21–0x7E), i.e. printable and not a space.
---
---@param uint8 byte The byte to check.
---@return boolean is_graphic `true` if the byte has a visible glyph.
---@nodiscard
function ascii.isGraphic(uint8) end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII control character.
--- Control characters are non-printable bytes in the range 0x00–0x1F
--- (e.g. NUL, BEL, BS, HT, LF, CR) as well as DEL (0x7F).
---
---@param uint8 byte The byte to check.
---@return boolean is_control `true` if the byte is a control character.
---@nodiscard
function ascii.isControl(uint8) end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII special (punctuation/symbol) character.
--- Covers the following ranges:
--- `! – /` (0x21–0x2F), `: – @` (0x3A–0x40),
--- ``[ – ` `` (0x5B–0x60), `{ – ~` (0x7B–0x7E).
---
---@param uint8 byte The byte to check.
---@return boolean is_special `true` if the byte is a punctuation or symbol character.
---@nodiscard
function ascii.isSpecial(uint8) end

--- [SHARED AND MENU]
---
--- Checks if the byte is a Lua pattern magic character.
--- Magic characters have special meaning inside Lua string patterns and
--- must be escaped with `%` when used as literals.
--- The magic set is: `^ $ ( ) % . [ ] * + - ?`
---
---@param uint8 byte The byte to check.
---@return boolean is_magic `true` if the byte is a Lua pattern magic character.
---@nodiscard
function ascii.isMagic(uint8) end

--- [SHARED AND MENU]
---
--- Converts an uppercase ASCII letter to lowercase, any other byte is returned as is.
---
---@param uint8 byte The byte to convert.
---@return byte lower_uint8 The lowercase byte.
---@nodiscard
function ascii.toLower(uint8) end

--- [SHARED AND MENU]
---
--- Converts a lowercase ASCII letter to uppercase, any other byte is returned as is.
---
---@param uint8 byte The byte to convert.
---@return byte upper_uint8 The uppercase byte.
---@nodiscard
function ascii.toUpper(uint8) end

---@alias ascii.integer
---|   0 |   1 |   2 |   3 |   4 |   5 |   6 |   7 |   8 |   9
---|  10 |  11 |  12 |  13 |  14 |  15 |  16 |  17 |  18 |  19
---|  20 |  21 |  22 |  23 |  24 |  25 |  26 |  27 |  28 |  29
---|  30 |  31 |  32 |  33 |  34 |  35

--- [SHARED AND MENU]
---
--- Returns the numerical value of the given digit byte (`0–9`, then `a–z`/`A–Z` for 10–35).
---
---@see ascii.fromInteger
---
---@param uint8 byte The byte to convert.
---@return ascii.integer | nil number The digit value, or `nil` if the byte is not a valid digit.
---@nodiscard
function ascii.toInteger(uint8) end

--- [SHARED AND MENU]
---
--- Returns the digit byte of the given numerical value (0–35), the inverse of `ascii.toInteger`.
---
---@see ascii.toInteger
---
---@param value ascii.integer The digit value to convert.
---@param uppercase? boolean If `true`, letters are returned in uppercase. Defaults to `false`.
---@return byte | nil uint8 The digit byte, or `nil` if the value is out of range.
---@nodiscard
function ascii.fromInteger(value, uppercase) end
