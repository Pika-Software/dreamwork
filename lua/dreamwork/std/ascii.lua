---@class dreamwork.std
local std = dreamwork.std

--- [SHARED AND MENU]
---
--- An ASCII library that provides functions for this encoding.
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
local function isLower( uint8 )
    return uint8 >= 0x61 and uint8 <= 0x7A
end

ascii.isLower = isLower

--- [SHARED AND MENU]
---
--- Checks if the byte is an uppercase ASCII letter (A–Z).
---
---@param uint8 integer The byte to check.
---@return boolean is_upper `true` if the byte is in the range 0x41–0x5A.
local function isUpper( uint8 )
    return uint8 >= 0x41 and uint8 <= 0x5A
end

ascii.isUpper = isUpper

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII alphabetic character (a–z or A–Z).
---
---@param uint8 integer The byte to check.
---@return boolean is_alpha `true` if the byte is a lowercase or uppercase letter.
local function isAlpha( uint8 )
    return isLower( uint8 ) or isUpper( uint8 )
end

ascii.isAlpha = isAlpha

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII decimal digit (0–9).
---
---@param uint8 integer The byte to check.
---@return boolean is_digit `true` if the byte is in the range 0x30–0x39.
local function isDigit( uint8 )
    return uint8 >= 0x30 and uint8 <= 0x39
end

ascii.isDigit = isDigit

--- [SHARED AND MENU]
---
--- Checks if the byte is a valid hexadecimal digit (0–9, A–F, a–f).
---
---@param uint8 integer The byte to check.
---@return boolean is_hex_digit `true` if the byte is a decimal digit or a hex letter.
local function isHexDigit( uint8 )
    return isDigit( uint8 )
        or (uint8 >= 0x41 and uint8 <= 0x46)
        or (uint8 >= 0x61 and uint8 <= 0x66)
end

ascii.isHexDigit = isHexDigit

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII whitespace character.
--- Matches: space (0x20), horizontal tab (0x09), line feed (0x0A),
--- vertical tab (0x0B), form feed (0x0C), and carriage return (0x0D).
---
---@param uint8 integer The byte to check.
---@return boolean is_space `true` if the byte is a whitespace character, `false` otherwise.
function ascii.isSpace( uint8 )
    return uint8 == 0x20 -- space
        or uint8 == 0x09 -- horizontal tab
        or uint8 == 0x0A -- line feed (new line)
        or uint8 == 0x0B -- vertical tab
        or uint8 == 0x0C -- form feed
        or uint8 == 0x0D -- carriage return
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
--- Checks if the byte is a Lua pattern magic character.
--- Magic characters have special meaning inside Lua string patterns and
--- must be escaped with `%` when used as literals.
--- The magic set is: `( ) . % + - * ? [ ^ $`
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
        or uint8 == 0x5E -- ^
        or uint8 == 0x24 -- $
end

--- [SHARED AND MENU]
---
--- Checks if the byte is an ASCII special (punctuation/symbol) character.
--- Covers the following ranges and individual code points:
--- `! – /` (0x21–0x2F), `: – ?` (0x3A–0x3F), `@` (0x40),
--- `[ – _` (0x5B–0x5F), `` ` `` (0x60), `{ – ~` (0x7B–0x7E).
---
---@param uint8 integer The byte to check.
---@return boolean is_special `true` if the byte is a punctuation or symbol character.
function ascii.isSpecial( uint8 )
    return (uint8 >= 0x21 and uint8 <= 0x2F) -- ! – /
        or (uint8 >= 0x3A and uint8 <= 0x3F) -- : – ?
        or uint8 == 0x40                     -- @
        or (uint8 >= 0x5B and uint8 <= 0x5F) -- [ – _
        or uint8 == 0x60                     -- `
        or (uint8 >= 0x7B and uint8 <= 0x7E) -- { – ~
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

do

    ---@type table<integer, integer>
    local byte_to_number = {}

    -- general digits
    for uint8 = 48, 57, 1 do
        byte_to_number[ uint8 ] = uint8 - 48
    end

    -- uppercase letters
    for uint8 = 65, 90, 1 do
        byte_to_number[ uint8 ] = uint8 - 55
    end

    -- lowercase letters
    for uint8 = 97, 122, 1 do
        byte_to_number[ uint8 ] = uint8 - 87
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the numerical representation of the given byte.
    ---
    ---@param uint8 integer The byte to convert.
    ---@return integer | nil number A number in Lua that equals this byte.
    function ascii.toInteger( uint8 )
        return byte_to_number[ uint8 ]
    end

end
