---@class dreamwork.std
local std = dreamwork.std

--- [SHARED AND MENU]
---
--- An ASCII library that provides functions for this encoding.
---
--- All functions operate on single bytes (integers in the range 0x00–0xFF),
--- as returned by `string.byte`, and do not accept `nil`.
---
---@class dreamwork.std.ascii
local ascii = {}
std.ascii = ascii

--- [SHARED AND MENU]
---
--- Checks if the byte is a lowercase ASCII letter (a–z).
---
---@param uint8 integer The byte to check.
---@return boolean is_lower `true` if the byte is in the range 0x61–0x7A.
function ascii.isLower( uint8 )
    return uint8 >= 0x61 and uint8 <= 0x7A
end

--- [SHARED AND MENU]
---
--- Checks if the byte is an uppercase ASCII letter (A–Z).
---
---@param uint8 integer The byte to check.
---@return boolean is_upper `true` if the byte is in the range 0x41–0x5A.
function ascii.isUpper( uint8 )
    return uint8 >= 0x41 and uint8 <= 0x5A
end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII alphabetic character (a–z or A–Z).
---
---@param uint8 integer The byte to check.
---@return boolean is_alpha `true` if the byte is a lowercase or uppercase letter.
function ascii.isAlpha( uint8 )
    return (uint8 >= 0x61 and uint8 <= 0x7A)
        or (uint8 >= 0x41 and uint8 <= 0x5A)
end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII decimal digit (0–9).
---
---@param uint8 integer The byte to check.
---@return boolean is_digit `true` if the byte is in the range 0x30–0x39.
function ascii.isDigit( uint8 )
    return uint8 >= 0x30 and uint8 <= 0x39
end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII binary digit (0–1).
---
---@param uint8 integer The byte to check.
---@return boolean is_binary_digit `true` if the byte is `0` or `1`.
function ascii.isBinaryDigit( uint8 )
    return uint8 == 0x30 or uint8 == 0x31
end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII octal digit (0–7).
---
---@param uint8 integer The byte to check.
---@return boolean is_octal_digit `true` if the byte is in the range 0x30–0x37.
function ascii.isOctalDigit( uint8 )
    return uint8 >= 0x30 and uint8 <= 0x37
end

--- [SHARED AND MENU]
---
--- Checks if the byte is a valid hexadecimal digit (0–9, A–F, a–f).
---
---@param uint8 integer The byte to check.
---@return boolean is_hex_digit `true` if the byte is a decimal digit or a hex letter.
function ascii.isHexDigit( uint8 )
    return (uint8 >= 0x30 and uint8 <= 0x39)
        or (uint8 >= 0x61 and uint8 <= 0x66)
        or (uint8 >= 0x41 and uint8 <= 0x46)
end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII alphanumeric character (A–Z, a–z, or 0–9).
---
---@param uint8 integer The byte to check.
---@return boolean is_alnum `true` if the byte is an ASCII letter or decimal digit.
function ascii.isAlnum( uint8 )
    return (uint8 >= 0x61 and uint8 <= 0x7A)
        or (uint8 >= 0x41 and uint8 <= 0x5A)
        or (uint8 >= 0x30 and uint8 <= 0x39)
end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII word character (A–Z, a–z, 0–9 or `_`),
--- i.e. a character allowed in identifiers.
---
---@param uint8 integer The byte to check.
---@return boolean is_word `true` if the byte is an ASCII letter, decimal digit or underscore.
function ascii.isWord( uint8 )
    return (uint8 >= 0x61 and uint8 <= 0x7A)
        or (uint8 >= 0x41 and uint8 <= 0x5A)
        or (uint8 >= 0x30 and uint8 <= 0x39)
        or uint8 == 0x5F -- _
end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII whitespace character.
--- Matches: space (0x20), horizontal tab (0x09), line feed (0x0A),
--- vertical tab (0x0B), form feed (0x0C), and carriage return (0x0D).
---
---@param uint8 integer The byte to check.
---@return boolean is_space `true` if the byte is a whitespace character, `false` otherwise.
function ascii.isSpace( uint8 )
    return uint8 == 0x20                     -- space
        or (uint8 >= 0x09 and uint8 <= 0x0D) -- \t \n \v \f \r
end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII blank character, i.e. space (0x20) or horizontal tab (0x09).
---
---@param uint8 integer The byte to check.
---@return boolean is_blank `true` if the byte is a space or a horizontal tab.
function ascii.isBlank( uint8 )
    return uint8 == 0x20 or uint8 == 0x09
end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII character, i.e. in the range 0x00–0x7F.
---
---@param uint8 integer The byte to check.
---@return boolean is_ascii `true` if the byte is not greater than 0x7F.
function ascii.isASCII( uint8 )
    return uint8 >= 0x00 and uint8 <= 0x7F
end

--- [SHARED AND MENU]
---
--- Checks if the byte is an extended (non-ASCII) byte, i.e. above 0x7F.
--- These bytes appear in multi-byte UTF-8 sequences and Latin-1 supplements.
---
---@param uint8 integer The byte to check.
---@return boolean is_extended `true` if the byte is greater than 0x7F.
function ascii.isExtended( uint8 )
    return uint8 > 0x7F
end

--- [SHARED AND MENU]
---
--- Checks if the byte is a printable ASCII character (0x20–0x7E), space included.
---
---@param uint8 integer The byte to check.
---@return boolean is_printable `true` if the byte is a printable character.
function ascii.isPrintable( uint8 )
    return uint8 >= 0x20 and uint8 <= 0x7E
end

--- [SHARED AND MENU]
---
--- Checks if the byte is a visible ASCII character (0x21–0x7E), i.e. printable and not a space.
---
---@param uint8 integer The byte to check.
---@return boolean is_graphic `true` if the byte has a visible glyph.
function ascii.isGraphic( uint8 )
    return uint8 >= 0x21 and uint8 <= 0x7E
end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII control character.
--- Control characters are non-printable bytes in the range 0x00–0x1F
--- (e.g. NUL, BEL, BS, HT, LF, CR) as well as DEL (0x7F).
---
---@param uint8 integer The byte to check.
---@return boolean is_control `true` if the byte is a control character.
function ascii.isControl( uint8 )
    return (uint8 >= 0x00 and uint8 <= 0x1F)
        or uint8 == 0x7F -- DEL
end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII special (punctuation/symbol) character.
--- Covers the following ranges:
--- `! – /` (0x21–0x2F), `: – @` (0x3A–0x40),
--- ``[ – ` `` (0x5B–0x60), `{ – ~` (0x7B–0x7E).
---
---@param uint8 integer The byte to check.
---@return boolean is_special `true` if the byte is a punctuation or symbol character.
function ascii.isSpecial( uint8 )
    return (uint8 >= 0x21 and uint8 <= 0x2F) -- ! – /
        or (uint8 >= 0x3A and uint8 <= 0x40) -- : – @
        or (uint8 >= 0x5B and uint8 <= 0x60) -- [ – `
        or (uint8 >= 0x7B and uint8 <= 0x7E) -- { – ~
end

--- [SHARED AND MENU]
---
--- Checks if the byte is a Lua pattern magic character.
--- Magic characters have special meaning inside Lua string patterns and
--- must be escaped with `%` when used as literals.
--- The magic set is: `^ $ ( ) % . [ ] * + - ?`
---
---@param uint8 integer The byte to check.
---@return boolean is_magic `true` if the byte is a Lua pattern magic character.
function ascii.isMagic( uint8 )
    return uint8 == 0x28 -- (
        or uint8 == 0x29 -- )
        or uint8 == 0x2E -- .
        or uint8 == 0x25 -- %
        or uint8 == 0x2B -- +
        or uint8 == 0x2D -- -
        or uint8 == 0x2A -- *
        or uint8 == 0x3F -- ?
        or uint8 == 0x5B -- [
        or uint8 == 0x5D -- ]
        or uint8 == 0x5E -- ^
        or uint8 == 0x24 -- $
end

--- [SHARED AND MENU]
---
--- Converts an uppercase ASCII letter to lowercase, any other byte is returned as is.
---
---@param uint8 integer The byte to convert.
---@return integer lower_uint8 The lowercase byte.
function ascii.toLower( uint8 )
    if uint8 >= 0x41 and uint8 <= 0x5A then
        return uint8 + 0x20
    else
        return uint8
    end
end

--- [SHARED AND MENU]
---
--- Converts a lowercase ASCII letter to uppercase, any other byte is returned as is.
---
---@param uint8 integer The byte to convert.
---@return integer upper_uint8 The uppercase byte.
function ascii.toUpper( uint8 )
    if uint8 >= 0x61 and uint8 <= 0x7A then
        return uint8 - 0x20
    else
        return uint8
    end
end

do

    ---@type table<integer, integer>
    local byte_to_number = {}

    -- general digits
    for uint8 = 0x30, 0x39, 1 do
        byte_to_number[ uint8 ] = uint8 - 0x30
    end

    -- uppercase letters
    for uint8 = 0x41, 0x5A, 1 do
        byte_to_number[ uint8 ] = uint8 - 0x37
    end

    -- lowercase letters
    for uint8 = 0x61, 0x7A, 1 do
        byte_to_number[ uint8 ] = uint8 - 0x57
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the numerical value of the given digit byte (`0–9`, then `a–z`/`A–Z` for 10–35).
    ---
    ---@see dreamwork.std.ascii.fromInteger
    ---
    ---@param uint8 integer The byte to convert.
    ---@param base? integer The numerical base (2–36), digits that are not valid in it are rejected. Defaults to `36`.
    ---@return integer | nil number The digit value, or `nil` if the byte is not a valid digit.
    function ascii.toInteger( uint8, base )
        local value = byte_to_number[ uint8 ]
        if value == nil or (base ~= nil and value >= base) then
            return nil
        end

        return value
    end

    ---@type table<integer, integer>
    local lower_digits, upper_digits = {}, {}

    for value = 0, 9, 1 do
        lower_digits[ value ] = 0x30 + value
        upper_digits[ value ] = 0x30 + value
    end

    for value = 10, 35, 1 do
        lower_digits[ value ] = 0x57 + value
        upper_digits[ value ] = 0x37 + value
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the digit byte of the given numerical value (0–35), the inverse of `ascii.toInteger`.
    ---
    ---@see dreamwork.std.ascii.toInteger
    ---
    ---@param value integer The digit value to convert.
    ---@param uppercase? boolean If `true`, letters are returned in uppercase. Defaults to `false`.
    ---@return integer | nil uint8 The digit byte, or `nil` if the value is out of range.
    function ascii.fromInteger( value, uppercase )
        return (uppercase and upper_digits or lower_digits)[ value ]
    end

end
