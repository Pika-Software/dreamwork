---@class dreamwork.std
local std = dreamwork.std

local ffi = std.ffi

local ffi_cast, ffi_copy, ffi_string
local uint8_ptr_t, uint8_array_t

if ffi ~= nil then
    ffi_cast, ffi_copy, ffi_string = ffi.cast, ffi.copy, ffi.string
    uint8_ptr_t, uint8_array_t = ffi.typeof( "const uint8_t *" ), ffi.typeof( "uint8_t[?]" )
end

local raw = std.raw
local raw_pairs = raw.pairs
local raw_tonumber = raw.tonumber

local rbit = raw.bit
local rbit_band, rbit_bor = rbit.band, rbit.bor
local rbit_lshift, rbit_rshift = rbit.lshift, rbit.rshift

local string = std.string
local string_len, string_rep = string.len, string.rep
local string_sub, string_find = string.sub, string.find
local string_char, string_byte = string.char, string.byte
local string_match, string_format = string.match, string.format

local ascii = std.ascii
local ascii_isPrintable, ascii_isDigit = ascii.isPrintable, ascii.isDigit

local math = std.math
local math_range = math.range
local math_ceil, math_floor = math.ceil, math.floor

local table = std.table
local table_concat = table.concat

local utf8 = std.utf8
local utf8_encode = utf8.encode
local utf8_decode = utf8.decode
local utf8_unpack = utf8.unpack

local error = std.error


--- [SHARED AND MENU]
---
--- The unicode library provides functions for working with unicode code points,
--- unicode escape sequences, case mapping, display width and blocks of UTF-8 strings.
---
---@class dreamwork.std.unicode
---@field MAX integer The largest valid unicode code point, `U+10FFFF`.
---@field REPLACEMENT integer The replacement character code point, `U+FFFD`.
---@field BOM integer The byte order mark code point, `U+FEFF`.
local unicode = {
    MAX = 0x10FFFF,
    REPLACEMENT = 0xFFFD,
    BOM = 0xFEFF
}

std.unicode = unicode

---@param value any
---@return boolean
local function is_codepoint( value )
    return value == value and value >= 0 and value <= 0x10FFFF and value % 1 == 0
end

--- [SHARED AND MENU]
---
--- Checks if the given value is a unicode scalar value, an integer in range `U+0000` - `U+10FFFF` that is not a surrogate.
---
--- Only scalar values can be encoded in UTF-8.
---
---@param utf8_codepoint integer The code point to check.
---@return boolean is_valid `true` if the code point is a unicode scalar value, `false` otherwise.
function unicode.isValid( utf8_codepoint )
    return is_codepoint( utf8_codepoint ) and (utf8_codepoint < 0xD800 or utf8_codepoint > 0xDFFF)
end

--- [SHARED AND MENU]
---
--- Checks if the given code point is a UTF-16 surrogate, in range `U+D800` - `U+DFFF`.
---
---@param utf8_codepoint integer The code point to check.
---@return boolean is_surrogate `true` if the code point is a surrogate, `false` otherwise.
function unicode.isSurrogate( utf8_codepoint )
    return utf8_codepoint >= 0xD800 and utf8_codepoint <= 0xDFFF
end

--- [SHARED AND MENU]
---
--- Checks if the given code point is a UTF-16 high (leading) surrogate, in range `U+D800` - `U+DBFF`.
---
---@param utf8_codepoint integer The code point to check.
---@return boolean is_high_surrogate `true` if the code point is a high surrogate, `false` otherwise.
function unicode.isHighSurrogate( utf8_codepoint )
    return utf8_codepoint >= 0xD800 and utf8_codepoint <= 0xDBFF
end

--- [SHARED AND MENU]
---
--- Checks if the given code point is a UTF-16 low (trailing) surrogate, in range `U+DC00` - `U+DFFF`.
---
---@param utf8_codepoint integer The code point to check.
---@return boolean is_low_surrogate `true` if the code point is a low surrogate, `false` otherwise.
function unicode.isLowSurrogate( utf8_codepoint )
    return utf8_codepoint >= 0xDC00 and utf8_codepoint <= 0xDFFF
end

--- [SHARED AND MENU]
---
--- Checks if the given code point is a noncharacter, `U+FDD0` - `U+FDEF` or the last two code points of any plane (`U+xFFFE`, `U+xFFFF`).
---
---@param utf8_codepoint integer The code point to check.
---@return boolean is_noncharacter `true` if the code point is a noncharacter, `false` otherwise.
function unicode.isNoncharacter( utf8_codepoint )
    if not is_codepoint( utf8_codepoint ) then
        return false
    end

    return (utf8_codepoint >= 0xFDD0 and utf8_codepoint <= 0xFDEF) or rbit_band( utf8_codepoint, 0xFFFE ) == 0xFFFE
end

--- [SHARED AND MENU]
---
--- Checks if the given code point belongs to a private use area, `U+E000` - `U+F8FF`, `U+F0000` - `U+FFFFD` or `U+100000` - `U+10FFFD`.
---
---@param utf8_codepoint integer The code point to check.
---@return boolean is_private_use `true` if the code point is a private use code point, `false` otherwise.
function unicode.isPrivateUse( utf8_codepoint )
    if utf8_codepoint < 0xE000 then
        return false
    elseif utf8_codepoint <= 0xF8FF then
        return true
    elseif utf8_codepoint < 0xF0000 or utf8_codepoint > 0x10FFFD then
        return false
    end

    return rbit_band( utf8_codepoint, 0xFFFE ) ~= 0xFFFE
end

--- [SHARED AND MENU]
---
--- Returns the unicode plane of the given code point, `0` for the Basic Multilingual Plane up to `16`.
---
---@param utf8_codepoint integer The code point.
---@return integer plane The plane number.
function unicode.plane( utf8_codepoint )
    if not is_codepoint( utf8_codepoint ) then
        error( string_format( "invalid unicode code point '%s'", utf8_codepoint ), 2 )
    end

    return rbit_rshift( utf8_codepoint, 16 )
end

--- [SHARED AND MENU]
---
--- Splits a supplementary code point (`U+10000` - `U+10FFFF`) into a UTF-16 surrogate pair.
---
---@param utf8_codepoint integer The supplementary code point.
---@return integer high_surrogate The high (leading) surrogate.
---@return integer low_surrogate The low (trailing) surrogate.
function unicode.toSurrogates( utf8_codepoint )
    if not (is_codepoint( utf8_codepoint ) and utf8_codepoint > 0xFFFF) then
        error( string_format( "code point '%s' is not in range U+10000 - U+10FFFF", utf8_codepoint ), 2 )
    end

    utf8_codepoint = utf8_codepoint - 0x10000
    return 0xD800 + rbit_rshift( utf8_codepoint, 10 ), 0xDC00 + rbit_band( utf8_codepoint, 0x3FF )
end

---@param high_surrogate integer
---@param low_surrogate integer
---@return integer utf8_codepoint
local function from_surrogates( high_surrogate, low_surrogate )
    return rbit_bor( rbit_lshift( high_surrogate - 0xD800, 10 ), low_surrogate - 0xDC00 ) + 0x10000
end

--- [SHARED AND MENU]
---
--- Combines a UTF-16 surrogate pair into a supplementary code point.
---
---@param high_surrogate integer The high (leading) surrogate, `U+D800` - `U+DBFF`.
---@param low_surrogate integer The low (trailing) surrogate, `U+DC00` - `U+DFFF`.
---@return integer utf8_codepoint The code point in range `U+10000` - `U+10FFFF`.
function unicode.fromSurrogates( high_surrogate, low_surrogate )
    if not (high_surrogate >= 0xD800 and high_surrogate <= 0xDBFF) then
        error( string_format( "invalid high surrogate '%s'", high_surrogate ), 2 )
    elseif not (low_surrogate >= 0xDC00 and low_surrogate <= 0xDFFF) then
        error( string_format( "invalid low surrogate '%s'", low_surrogate ), 2 )
    end

    return from_surrogates( high_surrogate, low_surrogate )
end

--- [SHARED AND MENU]
---
--- Returns a string representation of the given unicode code point.
---
---@param utf8_codepoint integer The unicode code point to represent.
---@return string utf8_tag The string representation of the code point, in the format `U+XXXX` - `U+XXXXXX`.
function unicode.tag( utf8_codepoint )
    if not is_codepoint( utf8_codepoint ) then
        error( string_format( "invalid unicode code point '%s'", utf8_codepoint ), 2 )
    end

    return string_format( "U+%04X", utf8_codepoint )
end

--- [SHARED AND MENU]
---
--- Returns the unicode code point represented by the given string.
---
---@param utf8_tag string The string representation of a unicode code point, in the format `U+XXXX` - `U+XXXXXX`.
---@return integer | nil utf8_codepoint The unicode code point represented by the string, or `nil` if the string is not a valid tag.
function unicode.untag( utf8_tag )
    local hex_str = string_match( utf8_tag, "^[Uu]%+(%x%x%x%x%x?%x?)$" )
    if hex_str == nil then
        return nil
    end

    local utf8_codepoint = raw_tonumber( hex_str, 16 )
    if utf8_codepoint > 0x10FFFF then
        return nil
    end

    return utf8_codepoint
end

---@alias dreamwork.std.unicode.EscapeStyle
---| "json" # `\uXXXX`, supplementary code points are written as surrogate pairs `\uXXXX\uXXXX` (JSON, JavaScript, Java, C#).
---| "es6" # `\u{X}` for every code point (JavaScript ES6+, Lua 5.3+, Rust, Swift).
---| "python" # `\uXXXX`, supplementary code points are written as `\UXXXXXXXX` (Python, C, C++).

--- [SHARED AND MENU]
---
--- Converts each character in the input string into a unicode escape sequence,
--- suitable for serialization, logging, or safe ASCII output.
---
---@param utf8_str string The input string containing unicode characters.
---@param style? dreamwork.std.unicode.EscapeStyle The escape sequence style, `"json"` by default.
---@param keep_ascii? boolean If `true`, printable ASCII characters (except `\`) are left as is.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-8 validity check, invalid sequences are escaped as `U+FFFD`.
---@return string escaped_str A string where each character is replaced with its unicode escape sequence.
function unicode.escape( utf8_str, style, keep_ascii, start_position, end_position, lax )
    local bmp_format, supplementary_format, surrogates

    if style == nil or style == "json" then
        bmp_format, supplementary_format, surrogates = "\\u%04X", "\\u%04X\\u%04X", true
    elseif style == "es6" then
        bmp_format, supplementary_format, surrogates = "\\u{%X}", "\\u{%X}", false
    elseif style == "python" then
        bmp_format, supplementary_format, surrogates = "\\u%04X", "\\U%08X", false
    else
        error( string_format( "unknown escape style '%s'", style ), 2 )
    end

    local codepoints, codepoint_count = utf8_unpack( utf8_str, start_position, end_position, lax )
    if codepoint_count == 0 then
        return ""
    end

    ---@type string[]
    local segments = {}

    for i = 1, codepoint_count, 1 do
        local codepoint = codepoints[ i ]

        if keep_ascii and ascii_isPrintable( codepoint ) and codepoint ~= 0x5C then
            segments[ i ] = string_char( codepoint )
        elseif codepoint < 0x10000 then
            segments[ i ] = string_format( bmp_format, codepoint )
        elseif surrogates then
            codepoint = codepoint - 0x10000
            segments[ i ] = string_format( supplementary_format, 0xD800 + rbit_rshift( codepoint, 10 ), 0xDC00 + rbit_band( codepoint, 0x3FF ) )
        else
            segments[ i ] = string_format( supplementary_format, codepoint )
        end
    end

    return table_concat( segments, "", 1, codepoint_count )
end

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
function unicode.unescape( escaped_str, lax )
    local position = string_find( escaped_str, "\\", 1, true )
    if position == nil then
        return escaped_str
    end

    ---@type string[]
    local segments, segment_count = {}, 0

    local str_length = string_len( escaped_str )

    -- start of the chunk that is not copied yet
    local copy_position = 1

    repeat
        local uint8 = string_byte( escaped_str, position + 1, position + 1 )
        local codepoint, next_position

        if uint8 == 0x75 --[[ u ]] then
            if string_byte( escaped_str, position + 2, position + 2 ) == 0x7B --[[ { ]] then
                local hex_str, close_position = string_match( escaped_str, "^(%x+)}()", position + 3 )
                if hex_str ~= nil then
                    next_position = close_position

                    -- leading zeros are allowed, but more than 8 significant digits can't fit
                    hex_str = string_match( hex_str, "^0*(.-)$" )
                    codepoint = string_len( hex_str ) > 8 and 0x7FFFFFFF or (raw_tonumber( hex_str, 16 ) or 0)
                end
            else
                local hex_str = string_match( escaped_str, "^%x%x%x%x", position + 2 )
                if hex_str ~= nil then
                    next_position = position + 6
                    codepoint = raw_tonumber( hex_str, 16 )

                    if codepoint ~= nil and codepoint >= 0xD800 and codepoint <= 0xDBFF then
                        local low_hex_str = string_match( escaped_str, "^\\u(%x%x%x%x)", next_position )
                        if low_hex_str ~= nil then
                            local low_surrogate = raw_tonumber( low_hex_str, 16 )
                            if low_surrogate ~= nil and low_surrogate >= 0xDC00 and low_surrogate <= 0xDFFF then
                                codepoint = from_surrogates( codepoint, low_surrogate )
                                next_position = next_position + 6
                            end
                        end
                    end
                end
            end
        elseif uint8 == 0x55 --[[ U ]] then
            local hex_str = string_match( escaped_str, "^%x%x%x%x%x%x%x%x", position + 2 )
            if hex_str ~= nil then
                next_position = position + 10
                codepoint = raw_tonumber( hex_str, 16 )
            end
        end

        if codepoint == nil then
            -- not a unicode escape, skip `\` and the escaped character (`\\` stays intact)
            -- Lua 5.1 clamps `init` past the end instead of failing, so check the bounds
            if position + 2 > str_length then
                break
            end

            position = string_find( escaped_str, "\\", position + 2, true )
        else
            if codepoint > 0x10FFFF or (codepoint >= 0xD800 and codepoint <= 0xDFFF) then
                if not lax then
                    error( string_format( "invalid unicode escape sequence '%s' at position %d (%s)",
                        string_sub( escaped_str, position, next_position - 1 ), position,
                        codepoint > 0x10FFFF and "code point exceeds U+10FFFF" or "lone UTF-16 surrogate"
                    ), 2 )
                end

                codepoint = 0xFFFD
            end

            if copy_position < position then
                segment_count = segment_count + 1
                segments[ segment_count ] = string_sub( escaped_str, copy_position, position - 1 )
            end

            segment_count = segment_count + 1
            segments[ segment_count ] = utf8_encode( codepoint, lax )

            copy_position = next_position
            position = string_find( escaped_str, "\\", next_position, true )
        end
    until position == nil

    if segment_count == 0 then
        return escaped_str
    end

    if copy_position <= str_length then
        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( escaped_str, copy_position )
    end

    return table_concat( segments, "", 1, segment_count )
end

---@type table<integer, string>
local codepoint_to_lower = {
    [ 0x41 ] = "a",
    [ 0x42 ] = "b",
    [ 0x43 ] = "c",
    [ 0x44 ] = "d",
    [ 0x45 ] = "e",
    [ 0x46 ] = "f",
    [ 0x47 ] = "g",
    [ 0x48 ] = "h",
    [ 0x49 ] = "i",
    [ 0x4A ] = "j",
    [ 0x4B ] = "k",
    [ 0x4C ] = "l",
    [ 0x4D ] = "m",
    [ 0x4E ] = "n",
    [ 0x4F ] = "o",
    [ 0x50 ] = "p",
    [ 0x51 ] = "q",
    [ 0x52 ] = "r",
    [ 0x53 ] = "s",
    [ 0x54 ] = "t",
    [ 0x55 ] = "u",
    [ 0x56 ] = "v",
    [ 0x57 ] = "w",
    [ 0x58 ] = "x",
    [ 0x59 ] = "y",
    [ 0x5A ] = "z",
    [ 0xC0 ] = "à",
    [ 0xC1 ] = "á",
    [ 0xC2 ] = "â",
    [ 0xC3 ] = "ã",
    [ 0xC4 ] = "ä",
    [ 0xC5 ] = "å",
    [ 0xC6 ] = "æ",
    [ 0xC7 ] = "ç",
    [ 0xC8 ] = "è",
    [ 0xC9 ] = "é",
    [ 0xCA ] = "ê",
    [ 0xCB ] = "ë",
    [ 0xCC ] = "ì",
    [ 0xCD ] = "í",
    [ 0xCE ] = "î",
    [ 0xCF ] = "ï",
    [ 0xD0 ] = "ð",
    [ 0xD1 ] = "ñ",
    [ 0xD2 ] = "ò",
    [ 0xD3 ] = "ó",
    [ 0xD4 ] = "ô",
    [ 0xD5 ] = "õ",
    [ 0xD6 ] = "ö",
    [ 0xD8 ] = "ø",
    [ 0xD9 ] = "ù",
    [ 0xDA ] = "ú",
    [ 0xDB ] = "û",
    [ 0xDC ] = "ü",
    [ 0xDD ] = "ý",
    [ 0xDE ] = "þ",
    [ 0x100 ] = "ā",
    [ 0x102 ] = "ă",
    [ 0x104 ] = "ą",
    [ 0x106 ] = "ć",
    [ 0x108 ] = "ĉ",
    [ 0x10A ] = "ċ",
    [ 0x10C ] = "č",
    [ 0x10E ] = "ď",
    [ 0x110 ] = "đ",
    [ 0x112 ] = "ē",
    [ 0x114 ] = "ĕ",
    [ 0x116 ] = "ė",
    [ 0x118 ] = "ę",
    [ 0x11A ] = "ě",
    [ 0x11C ] = "ĝ",
    [ 0x11E ] = "ğ",
    [ 0x120 ] = "ġ",
    [ 0x122 ] = "ģ",
    [ 0x124 ] = "ĥ",
    [ 0x126 ] = "ħ",
    [ 0x128 ] = "ĩ",
    [ 0x12A ] = "ī",
    [ 0x12C ] = "ĭ",
    [ 0x12E ] = "į",
    [ 0x132 ] = "ĳ",
    [ 0x134 ] = "ĵ",
    [ 0x136 ] = "ķ",
    [ 0x139 ] = "ĺ",
    [ 0x13B ] = "ļ",
    [ 0x13D ] = "ľ",
    [ 0x13F ] = "ŀ",
    [ 0x141 ] = "ł",
    [ 0x143 ] = "ń",
    [ 0x145 ] = "ņ",
    [ 0x147 ] = "ň",
    [ 0x14A ] = "ŋ",
    [ 0x14C ] = "ō",
    [ 0x14E ] = "ŏ",
    [ 0x150 ] = "ő",
    [ 0x152 ] = "œ",
    [ 0x154 ] = "ŕ",
    [ 0x156 ] = "ŗ",
    [ 0x158 ] = "ř",
    [ 0x15A ] = "ś",
    [ 0x15C ] = "ŝ",
    [ 0x15E ] = "ş",
    [ 0x160 ] = "š",
    [ 0x162 ] = "ţ",
    [ 0x164 ] = "ť",
    [ 0x166 ] = "ŧ",
    [ 0x168 ] = "ũ",
    [ 0x16A ] = "ū",
    [ 0x16C ] = "ŭ",
    [ 0x16E ] = "ů",
    [ 0x170 ] = "ű",
    [ 0x172 ] = "ų",
    [ 0x174 ] = "ŵ",
    [ 0x176 ] = "ŷ",
    [ 0x178 ] = "ÿ",
    [ 0x179 ] = "ź",
    [ 0x17B ] = "ż",
    [ 0x17D ] = "ž",
    [ 0x181 ] = "ɓ",
    [ 0x182 ] = "ƃ",
    [ 0x184 ] = "ƅ",
    [ 0x186 ] = "ɔ",
    [ 0x187 ] = "ƈ",
    [ 0x189 ] = "ɖ",
    [ 0x18A ] = "ɗ",
    [ 0x18B ] = "ƌ",
    [ 0x18E ] = "ǝ",
    [ 0x18F ] = "ə",
    [ 0x190 ] = "ɛ",
    [ 0x191 ] = "ƒ",
    [ 0x193 ] = "ɠ",
    [ 0x194 ] = "ɣ",
    [ 0x196 ] = "ɩ",
    [ 0x197 ] = "ɨ",
    [ 0x198 ] = "ƙ",
    [ 0x19C ] = "ɯ",
    [ 0x19D ] = "ɲ",
    [ 0x19F ] = "ɵ",
    [ 0x1A0 ] = "ơ",
    [ 0x1A2 ] = "ƣ",
    [ 0x1A4 ] = "ƥ",
    [ 0x1A6 ] = "ʀ",
    [ 0x1A7 ] = "ƨ",
    [ 0x1A9 ] = "ʃ",
    [ 0x1AC ] = "ƭ",
    [ 0x1AE ] = "ʈ",
    [ 0x1AF ] = "ư",
    [ 0x1B1 ] = "ʊ",
    [ 0x1B2 ] = "ʋ",
    [ 0x1B3 ] = "ƴ",
    [ 0x1B5 ] = "ƶ",
    [ 0x1B7 ] = "ʒ",
    [ 0x1B8 ] = "ƹ",
    [ 0x1BC ] = "ƽ",
    [ 0x1C4 ] = "ǅ",
    [ 0x1C7 ] = "ǈ",
    [ 0x1CA ] = "ǌ",
    [ 0x1CD ] = "ǎ",
    [ 0x1CF ] = "ǐ",
    [ 0x1D1 ] = "ǒ",
    [ 0x1D3 ] = "ǔ",
    [ 0x1D5 ] = "ǖ",
    [ 0x1D7 ] = "ǘ",
    [ 0x1D9 ] = "ǚ",
    [ 0x1DB ] = "ǜ",
    [ 0x1DE ] = "ǟ",
    [ 0x1E0 ] = "ǡ",
    [ 0x1E2 ] = "ǣ",
    [ 0x1E4 ] = "ǥ",
    [ 0x1E6 ] = "ǧ",
    [ 0x1E8 ] = "ǩ",
    [ 0x1EA ] = "ǫ",
    [ 0x1EC ] = "ǭ",
    [ 0x1EE ] = "ǯ",
    [ 0x1F1 ] = "ǳ",
    [ 0x1F4 ] = "ǵ",
    [ 0x1F6 ] = "ƕ",
    [ 0x1F7 ] = "ƿ",
    [ 0x1F8 ] = "ǹ",
    [ 0x1FA ] = "ǻ",
    [ 0x1FC ] = "ǽ",
    [ 0x1FE ] = "ǿ",
    [ 0x200 ] = "ȁ",
    [ 0x202 ] = "ȃ",
    [ 0x204 ] = "ȅ",
    [ 0x206 ] = "ȇ",
    [ 0x208 ] = "ȉ",
    [ 0x20A ] = "ȋ",
    [ 0x20C ] = "ȍ",
    [ 0x20E ] = "ȏ",
    [ 0x210 ] = "ȑ",
    [ 0x212 ] = "ȓ",
    [ 0x214 ] = "ȕ",
    [ 0x216 ] = "ȗ",
    [ 0x218 ] = "ș",
    [ 0x21A ] = "ț",
    [ 0x21C ] = "ȝ",
    [ 0x21E ] = "ȟ",
    [ 0x220 ] = "ƞ",
    [ 0x222 ] = "ȣ",
    [ 0x224 ] = "ȥ",
    [ 0x226 ] = "ȧ",
    [ 0x228 ] = "ȩ",
    [ 0x22A ] = "ȫ",
    [ 0x22C ] = "ȭ",
    [ 0x22E ] = "ȯ",
    [ 0x230 ] = "ȱ",
    [ 0x232 ] = "ȳ",
    [ 0x23A ] = "ⱥ",
    [ 0x23B ] = "ȼ",
    [ 0x23D ] = "ƚ",
    [ 0x23E ] = "ⱦ",
    [ 0x241 ] = "ɂ",
    [ 0x243 ] = "ƀ",
    [ 0x244 ] = "ʉ",
    [ 0x245 ] = "ʌ",
    [ 0x246 ] = "ɇ",
    [ 0x248 ] = "ɉ",
    [ 0x24A ] = "ɋ",
    [ 0x24C ] = "ɍ",
    [ 0x24E ] = "ɏ",
    [ 0x386 ] = "ά",
    [ 0x388 ] = "έ",
    [ 0x389 ] = "ή",
    [ 0x38A ] = "ί",
    [ 0x38C ] = "ό",
    [ 0x38E ] = "ύ",
    [ 0x38F ] = "ώ",
    [ 0x391 ] = "α",
    [ 0x392 ] = "ϐ",
    [ 0x393 ] = "γ",
    [ 0x394 ] = "δ",
    [ 0x395 ] = "ε",
    [ 0x396 ] = "ζ",
    [ 0x397 ] = "η",
    [ 0x398 ] = "θ",
    [ 0x399 ] = "ͅ",
    [ 0x39A ] = "ϰ",
    [ 0x39B ] = "λ",
    [ 0x39C ] = "μ",
    [ 0x39D ] = "ν",
    [ 0x39E ] = "ξ",
    [ 0x39F ] = "ο",
    [ 0x3A0 ] = "π",
    [ 0x3A1 ] = "ϱ",
    [ 0x3A3 ] = "ς",
    [ 0x3A4 ] = "τ",
    [ 0x3A5 ] = "υ",
    [ 0x3A6 ] = "ϕ",
    [ 0x3A7 ] = "χ",
    [ 0x3A8 ] = "ψ",
    [ 0x3A9 ] = "ω",
    [ 0x3AA ] = "ϊ",
    [ 0x3AB ] = "ϋ",
    [ 0x3D8 ] = "ϙ",
    [ 0x3DA ] = "ϛ",
    [ 0x3DC ] = "ϝ",
    [ 0x3DE ] = "ϟ",
    [ 0x3E0 ] = "ϡ",
    [ 0x3E2 ] = "ϣ",
    [ 0x3E4 ] = "ϥ",
    [ 0x3E6 ] = "ϧ",
    [ 0x3E8 ] = "ϩ",
    [ 0x3EA ] = "ϫ",
    [ 0x3EC ] = "ϭ",
    [ 0x3EE ] = "ϯ",
    [ 0x3F7 ] = "ϸ",
    [ 0x3F9 ] = "ϲ",
    [ 0x3FA ] = "ϻ",
    [ 0x3FD ] = "ͻ",
    [ 0x3FE ] = "ͼ",
    [ 0x3FF ] = "ͽ",
    [ 0x400 ] = "ѐ",
    [ 0x401 ] = "ё",
    [ 0x402 ] = "ђ",
    [ 0x403 ] = "ѓ",
    [ 0x404 ] = "є",
    [ 0x405 ] = "ѕ",
    [ 0x406 ] = "і",
    [ 0x407 ] = "ї",
    [ 0x408 ] = "ј",
    [ 0x409 ] = "љ",
    [ 0x40A ] = "њ",
    [ 0x40B ] = "ћ",
    [ 0x40C ] = "ќ",
    [ 0x40D ] = "ѝ",
    [ 0x40E ] = "ў",
    [ 0x40F ] = "џ",
    [ 0x410 ] = "а",
    [ 0x411 ] = "б",
    [ 0x412 ] = "в",
    [ 0x413 ] = "г",
    [ 0x414 ] = "д",
    [ 0x415 ] = "е",
    [ 0x416 ] = "ж",
    [ 0x417 ] = "з",
    [ 0x418 ] = "и",
    [ 0x419 ] = "й",
    [ 0x41A ] = "к",
    [ 0x41B ] = "л",
    [ 0x41C ] = "м",
    [ 0x41D ] = "н",
    [ 0x41E ] = "о",
    [ 0x41F ] = "п",
    [ 0x420 ] = "р",
    [ 0x421 ] = "с",
    [ 0x422 ] = "т",
    [ 0x423 ] = "у",
    [ 0x424 ] = "ф",
    [ 0x425 ] = "х",
    [ 0x426 ] = "ц",
    [ 0x427 ] = "ч",
    [ 0x428 ] = "ш",
    [ 0x429 ] = "щ",
    [ 0x42A ] = "ъ",
    [ 0x42B ] = "ы",
    [ 0x42C ] = "ь",
    [ 0x42D ] = "э",
    [ 0x42E ] = "ю",
    [ 0x42F ] = "я",
    [ 0x460 ] = "ѡ",
    [ 0x462 ] = "ѣ",
    [ 0x464 ] = "ѥ",
    [ 0x466 ] = "ѧ",
    [ 0x468 ] = "ѩ",
    [ 0x46A ] = "ѫ",
    [ 0x46C ] = "ѭ",
    [ 0x46E ] = "ѯ",
    [ 0x470 ] = "ѱ",
    [ 0x472 ] = "ѳ",
    [ 0x474 ] = "ѵ",
    [ 0x476 ] = "ѷ",
    [ 0x478 ] = "ѹ",
    [ 0x47A ] = "ѻ",
    [ 0x47C ] = "ѽ",
    [ 0x47E ] = "ѿ",
    [ 0x480 ] = "ҁ",
    [ 0x48A ] = "ҋ",
    [ 0x48C ] = "ҍ",
    [ 0x48E ] = "ҏ",
    [ 0x490 ] = "ґ",
    [ 0x492 ] = "ғ",
    [ 0x494 ] = "ҕ",
    [ 0x496 ] = "җ",
    [ 0x498 ] = "ҙ",
    [ 0x49A ] = "қ",
    [ 0x49C ] = "ҝ",
    [ 0x49E ] = "ҟ",
    [ 0x4A0 ] = "ҡ",
    [ 0x4A2 ] = "ң",
    [ 0x4A4 ] = "ҥ",
    [ 0x4A6 ] = "ҧ",
    [ 0x4A8 ] = "ҩ",
    [ 0x4AA ] = "ҫ",
    [ 0x4AC ] = "ҭ",
    [ 0x4AE ] = "ү",
    [ 0x4B0 ] = "ұ",
    [ 0x4B2 ] = "ҳ",
    [ 0x4B4 ] = "ҵ",
    [ 0x4B6 ] = "ҷ",
    [ 0x4B8 ] = "ҹ",
    [ 0x4BA ] = "һ",
    [ 0x4BC ] = "ҽ",
    [ 0x4BE ] = "ҿ",
    [ 0x4C0 ] = "ӏ",
    [ 0x4C1 ] = "ӂ",
    [ 0x4C3 ] = "ӄ",
    [ 0x4C5 ] = "ӆ",
    [ 0x4C7 ] = "ӈ",
    [ 0x4C9 ] = "ӊ",
    [ 0x4CB ] = "ӌ",
    [ 0x4CD ] = "ӎ",
    [ 0x4D0 ] = "ӑ",
    [ 0x4D2 ] = "ӓ",
    [ 0x4D4 ] = "ӕ",
    [ 0x4D6 ] = "ӗ",
    [ 0x4D8 ] = "ә",
    [ 0x4DA ] = "ӛ",
    [ 0x4DC ] = "ӝ",
    [ 0x4DE ] = "ӟ",
    [ 0x4E0 ] = "ӡ",
    [ 0x4E2 ] = "ӣ",
    [ 0x4E4 ] = "ӥ",
    [ 0x4E6 ] = "ӧ",
    [ 0x4E8 ] = "ө",
    [ 0x4EA ] = "ӫ",
    [ 0x4EC ] = "ӭ",
    [ 0x4EE ] = "ӯ",
    [ 0x4F0 ] = "ӱ",
    [ 0x4F2 ] = "ӳ",
    [ 0x4F4 ] = "ӵ",
    [ 0x4F6 ] = "ӷ",
    [ 0x4F8 ] = "ӹ",
    [ 0x4FA ] = "ӻ",
    [ 0x4FC ] = "ӽ",
    [ 0x4FE ] = "ӿ",
    [ 0x500 ] = "ԁ",
    [ 0x502 ] = "ԃ",
    [ 0x504 ] = "ԅ",
    [ 0x506 ] = "ԇ",
    [ 0x508 ] = "ԉ",
    [ 0x50A ] = "ԋ",
    [ 0x50C ] = "ԍ",
    [ 0x50E ] = "ԏ",
    [ 0x510 ] = "ԑ",
    [ 0x512 ] = "ԓ",
    [ 0x531 ] = "ա",
    [ 0x532 ] = "բ",
    [ 0x533 ] = "գ",
    [ 0x534 ] = "դ",
    [ 0x535 ] = "ե",
    [ 0x536 ] = "զ",
    [ 0x537 ] = "է",
    [ 0x538 ] = "ը",
    [ 0x539 ] = "թ",
    [ 0x53A ] = "ժ",
    [ 0x53B ] = "ի",
    [ 0x53C ] = "լ",
    [ 0x53D ] = "խ",
    [ 0x53E ] = "ծ",
    [ 0x53F ] = "կ",
    [ 0x540 ] = "հ",
    [ 0x541 ] = "ձ",
    [ 0x542 ] = "ղ",
    [ 0x543 ] = "ճ",
    [ 0x544 ] = "մ",
    [ 0x545 ] = "յ",
    [ 0x546 ] = "ն",
    [ 0x547 ] = "շ",
    [ 0x548 ] = "ո",
    [ 0x549 ] = "չ",
    [ 0x54A ] = "պ",
    [ 0x54B ] = "ջ",
    [ 0x54C ] = "ռ",
    [ 0x54D ] = "ս",
    [ 0x54E ] = "վ",
    [ 0x54F ] = "տ",
    [ 0x550 ] = "ր",
    [ 0x551 ] = "ց",
    [ 0x552 ] = "ւ",
    [ 0x553 ] = "փ",
    [ 0x554 ] = "ք",
    [ 0x555 ] = "օ",
    [ 0x556 ] = "ֆ",
    [ 0x10A0 ] = "ⴀ",
    [ 0x10A1 ] = "ⴁ",
    [ 0x10A2 ] = "ⴂ",
    [ 0x10A3 ] = "ⴃ",
    [ 0x10A4 ] = "ⴄ",
    [ 0x10A5 ] = "ⴅ",
    [ 0x10A6 ] = "ⴆ",
    [ 0x10A7 ] = "ⴇ",
    [ 0x10A8 ] = "ⴈ",
    [ 0x10A9 ] = "ⴉ",
    [ 0x10AA ] = "ⴊ",
    [ 0x10AB ] = "ⴋ",
    [ 0x10AC ] = "ⴌ",
    [ 0x10AD ] = "ⴍ",
    [ 0x10AE ] = "ⴎ",
    [ 0x10AF ] = "ⴏ",
    [ 0x10B0 ] = "ⴐ",
    [ 0x10B1 ] = "ⴑ",
    [ 0x10B2 ] = "ⴒ",
    [ 0x10B3 ] = "ⴓ",
    [ 0x10B4 ] = "ⴔ",
    [ 0x10B5 ] = "ⴕ",
    [ 0x10B6 ] = "ⴖ",
    [ 0x10B7 ] = "ⴗ",
    [ 0x10B8 ] = "ⴘ",
    [ 0x10B9 ] = "ⴙ",
    [ 0x10BA ] = "ⴚ",
    [ 0x10BB ] = "ⴛ",
    [ 0x10BC ] = "ⴜ",
    [ 0x10BD ] = "ⴝ",
    [ 0x10BE ] = "ⴞ",
    [ 0x10BF ] = "ⴟ",
    [ 0x10C0 ] = "ⴠ",
    [ 0x10C1 ] = "ⴡ",
    [ 0x10C2 ] = "ⴢ",
    [ 0x10C3 ] = "ⴣ",
    [ 0x10C4 ] = "ⴤ",
    [ 0x10C5 ] = "ⴥ",
    [ 0x1E00 ] = "ḁ",
    [ 0x1E02 ] = "ḃ",
    [ 0x1E04 ] = "ḅ",
    [ 0x1E06 ] = "ḇ",
    [ 0x1E08 ] = "ḉ",
    [ 0x1E0A ] = "ḋ",
    [ 0x1E0C ] = "ḍ",
    [ 0x1E0E ] = "ḏ",
    [ 0x1E10 ] = "ḑ",
    [ 0x1E12 ] = "ḓ",
    [ 0x1E14 ] = "ḕ",
    [ 0x1E16 ] = "ḗ",
    [ 0x1E18 ] = "ḙ",
    [ 0x1E1A ] = "ḛ",
    [ 0x1E1C ] = "ḝ",
    [ 0x1E1E ] = "ḟ",
    [ 0x1E20 ] = "ḡ",
    [ 0x1E22 ] = "ḣ",
    [ 0x1E24 ] = "ḥ",
    [ 0x1E26 ] = "ḧ",
    [ 0x1E28 ] = "ḩ",
    [ 0x1E2A ] = "ḫ",
    [ 0x1E2C ] = "ḭ",
    [ 0x1E2E ] = "ḯ",
    [ 0x1E30 ] = "ḱ",
    [ 0x1E32 ] = "ḳ",
    [ 0x1E34 ] = "ḵ",
    [ 0x1E36 ] = "ḷ",
    [ 0x1E38 ] = "ḹ",
    [ 0x1E3A ] = "ḻ",
    [ 0x1E3C ] = "ḽ",
    [ 0x1E3E ] = "ḿ",
    [ 0x1E40 ] = "ṁ",
    [ 0x1E42 ] = "ṃ",
    [ 0x1E44 ] = "ṅ",
    [ 0x1E46 ] = "ṇ",
    [ 0x1E48 ] = "ṉ",
    [ 0x1E4A ] = "ṋ",
    [ 0x1E4C ] = "ṍ",
    [ 0x1E4E ] = "ṏ",
    [ 0x1E50 ] = "ṑ",
    [ 0x1E52 ] = "ṓ",
    [ 0x1E54 ] = "ṕ",
    [ 0x1E56 ] = "ṗ",
    [ 0x1E58 ] = "ṙ",
    [ 0x1E5A ] = "ṛ",
    [ 0x1E5C ] = "ṝ",
    [ 0x1E5E ] = "ṟ",
    [ 0x1E60 ] = "ẛ",
    [ 0x1E62 ] = "ṣ",
    [ 0x1E64 ] = "ṥ",
    [ 0x1E66 ] = "ṧ",
    [ 0x1E68 ] = "ṩ",
    [ 0x1E6A ] = "ṫ",
    [ 0x1E6C ] = "ṭ",
    [ 0x1E6E ] = "ṯ",
    [ 0x1E70 ] = "ṱ",
    [ 0x1E72 ] = "ṳ",
    [ 0x1E74 ] = "ṵ",
    [ 0x1E76 ] = "ṷ",
    [ 0x1E78 ] = "ṹ",
    [ 0x1E7A ] = "ṻ",
    [ 0x1E7C ] = "ṽ",
    [ 0x1E7E ] = "ṿ",
    [ 0x1E80 ] = "ẁ",
    [ 0x1E82 ] = "ẃ",
    [ 0x1E84 ] = "ẅ",
    [ 0x1E86 ] = "ẇ",
    [ 0x1E88 ] = "ẉ",
    [ 0x1E8A ] = "ẋ",
    [ 0x1E8C ] = "ẍ",
    [ 0x1E8E ] = "ẏ",
    [ 0x1E90 ] = "ẑ",
    [ 0x1E92 ] = "ẓ",
    [ 0x1E94 ] = "ẕ",
    [ 0x1EA0 ] = "ạ",
    [ 0x1EA2 ] = "ả",
    [ 0x1EA4 ] = "ấ",
    [ 0x1EA6 ] = "ầ",
    [ 0x1EA8 ] = "ẩ",
    [ 0x1EAA ] = "ẫ",
    [ 0x1EAC ] = "ậ",
    [ 0x1EAE ] = "ắ",
    [ 0x1EB0 ] = "ằ",
    [ 0x1EB2 ] = "ẳ",
    [ 0x1EB4 ] = "ẵ",
    [ 0x1EB6 ] = "ặ",
    [ 0x1EB8 ] = "ẹ",
    [ 0x1EBA ] = "ẻ",
    [ 0x1EBC ] = "ẽ",
    [ 0x1EBE ] = "ế",
    [ 0x1EC0 ] = "ề",
    [ 0x1EC2 ] = "ể",
    [ 0x1EC4 ] = "ễ",
    [ 0x1EC6 ] = "ệ",
    [ 0x1EC8 ] = "ỉ",
    [ 0x1ECA ] = "ị",
    [ 0x1ECC ] = "ọ",
    [ 0x1ECE ] = "ỏ",
    [ 0x1ED0 ] = "ố",
    [ 0x1ED2 ] = "ồ",
    [ 0x1ED4 ] = "ổ",
    [ 0x1ED6 ] = "ỗ",
    [ 0x1ED8 ] = "ộ",
    [ 0x1EDA ] = "ớ",
    [ 0x1EDC ] = "ờ",
    [ 0x1EDE ] = "ở",
    [ 0x1EE0 ] = "ỡ",
    [ 0x1EE2 ] = "ợ",
    [ 0x1EE4 ] = "ụ",
    [ 0x1EE6 ] = "ủ",
    [ 0x1EE8 ] = "ứ",
    [ 0x1EEA ] = "ừ",
    [ 0x1EEC ] = "ử",
    [ 0x1EEE ] = "ữ",
    [ 0x1EF0 ] = "ự",
    [ 0x1EF2 ] = "ỳ",
    [ 0x1EF4 ] = "ỵ",
    [ 0x1EF6 ] = "ỷ",
    [ 0x1EF8 ] = "ỹ",
    [ 0x1F08 ] = "ἀ",
    [ 0x1F09 ] = "ἁ",
    [ 0x1F0A ] = "ἂ",
    [ 0x1F0B ] = "ἃ",
    [ 0x1F0C ] = "ἄ",
    [ 0x1F0D ] = "ἅ",
    [ 0x1F0E ] = "ἆ",
    [ 0x1F0F ] = "ἇ",
    [ 0x1F18 ] = "ἐ",
    [ 0x1F19 ] = "ἑ",
    [ 0x1F1A ] = "ἒ",
    [ 0x1F1B ] = "ἓ",
    [ 0x1F1C ] = "ἔ",
    [ 0x1F1D ] = "ἕ",
    [ 0x1F28 ] = "ἠ",
    [ 0x1F29 ] = "ἡ",
    [ 0x1F2A ] = "ἢ",
    [ 0x1F2B ] = "ἣ",
    [ 0x1F2C ] = "ἤ",
    [ 0x1F2D ] = "ἥ",
    [ 0x1F2E ] = "ἦ",
    [ 0x1F2F ] = "ἧ",
    [ 0x1F38 ] = "ἰ",
    [ 0x1F39 ] = "ἱ",
    [ 0x1F3A ] = "ἲ",
    [ 0x1F3B ] = "ἳ",
    [ 0x1F3C ] = "ἴ",
    [ 0x1F3D ] = "ἵ",
    [ 0x1F3E ] = "ἶ",
    [ 0x1F3F ] = "ἷ",
    [ 0x1F48 ] = "ὀ",
    [ 0x1F49 ] = "ὁ",
    [ 0x1F4A ] = "ὂ",
    [ 0x1F4B ] = "ὃ",
    [ 0x1F4C ] = "ὄ",
    [ 0x1F4D ] = "ὅ",
    [ 0x1F59 ] = "ὑ",
    [ 0x1F5B ] = "ὓ",
    [ 0x1F5D ] = "ὕ",
    [ 0x1F5F ] = "ὗ",
    [ 0x1F68 ] = "ὠ",
    [ 0x1F69 ] = "ὡ",
    [ 0x1F6A ] = "ὢ",
    [ 0x1F6B ] = "ὣ",
    [ 0x1F6C ] = "ὤ",
    [ 0x1F6D ] = "ὥ",
    [ 0x1F6E ] = "ὦ",
    [ 0x1F6F ] = "ὧ",
    [ 0x1F88 ] = "ᾀ",
    [ 0x1F89 ] = "ᾁ",
    [ 0x1F8A ] = "ᾂ",
    [ 0x1F8B ] = "ᾃ",
    [ 0x1F8C ] = "ᾄ",
    [ 0x1F8D ] = "ᾅ",
    [ 0x1F8E ] = "ᾆ",
    [ 0x1F8F ] = "ᾇ",
    [ 0x1F98 ] = "ᾐ",
    [ 0x1F99 ] = "ᾑ",
    [ 0x1F9A ] = "ᾒ",
    [ 0x1F9B ] = "ᾓ",
    [ 0x1F9C ] = "ᾔ",
    [ 0x1F9D ] = "ᾕ",
    [ 0x1F9E ] = "ᾖ",
    [ 0x1F9F ] = "ᾗ",
    [ 0x1FA8 ] = "ᾠ",
    [ 0x1FA9 ] = "ᾡ",
    [ 0x1FAA ] = "ᾢ",
    [ 0x1FAB ] = "ᾣ",
    [ 0x1FAC ] = "ᾤ",
    [ 0x1FAD ] = "ᾥ",
    [ 0x1FAE ] = "ᾦ",
    [ 0x1FAF ] = "ᾧ",
    [ 0x1FB8 ] = "ᾰ",
    [ 0x1FB9 ] = "ᾱ",
    [ 0x1FBA ] = "ὰ",
    [ 0x1FBB ] = "ά",
    [ 0x1FBC ] = "ᾳ",
    [ 0x1FC8 ] = "ὲ",
    [ 0x1FC9 ] = "έ",
    [ 0x1FCA ] = "ὴ",
    [ 0x1FCB ] = "ή",
    [ 0x1FCC ] = "ῃ",
    [ 0x1FD8 ] = "ῐ",
    [ 0x1FD9 ] = "ῑ",
    [ 0x1FDA ] = "ὶ",
    [ 0x1FDB ] = "ί",
    [ 0x1FE8 ] = "ῠ",
    [ 0x1FE9 ] = "ῡ",
    [ 0x1FEA ] = "ὺ",
    [ 0x1FEB ] = "ύ",
    [ 0x1FEC ] = "ῥ",
    [ 0x1FF8 ] = "ὸ",
    [ 0x1FF9 ] = "ό",
    [ 0x1FFA ] = "ὼ",
    [ 0x1FFB ] = "ώ",
    [ 0x1FFC ] = "ῳ",
    [ 0x2132 ] = "ⅎ",
    [ 0x2160 ] = "ⅰ",
    [ 0x2161 ] = "ⅱ",
    [ 0x2162 ] = "ⅲ",
    [ 0x2163 ] = "ⅳ",
    [ 0x2164 ] = "ⅴ",
    [ 0x2165 ] = "ⅵ",
    [ 0x2166 ] = "ⅶ",
    [ 0x2167 ] = "ⅷ",
    [ 0x2168 ] = "ⅸ",
    [ 0x2169 ] = "ⅹ",
    [ 0x216A ] = "ⅺ",
    [ 0x216B ] = "ⅻ",
    [ 0x216C ] = "ⅼ",
    [ 0x216D ] = "ⅽ",
    [ 0x216E ] = "ⅾ",
    [ 0x216F ] = "ⅿ",
    [ 0x2183 ] = "ↄ",
    [ 0x24B6 ] = "ⓐ",
    [ 0x24B7 ] = "ⓑ",
    [ 0x24B8 ] = "ⓒ",
    [ 0x24B9 ] = "ⓓ",
    [ 0x24BA ] = "ⓔ",
    [ 0x24BB ] = "ⓕ",
    [ 0x24BC ] = "ⓖ",
    [ 0x24BD ] = "ⓗ",
    [ 0x24BE ] = "ⓘ",
    [ 0x24BF ] = "ⓙ",
    [ 0x24C0 ] = "ⓚ",
    [ 0x24C1 ] = "ⓛ",
    [ 0x24C2 ] = "ⓜ",
    [ 0x24C3 ] = "ⓝ",
    [ 0x24C4 ] = "ⓞ",
    [ 0x24C5 ] = "ⓟ",
    [ 0x24C6 ] = "ⓠ",
    [ 0x24C7 ] = "ⓡ",
    [ 0x24C8 ] = "ⓢ",
    [ 0x24C9 ] = "ⓣ",
    [ 0x24CA ] = "ⓤ",
    [ 0x24CB ] = "ⓥ",
    [ 0x24CC ] = "ⓦ",
    [ 0x24CD ] = "ⓧ",
    [ 0x24CE ] = "ⓨ",
    [ 0x24CF ] = "ⓩ",
    [ 0x2C00 ] = "ⰰ",
    [ 0x2C01 ] = "ⰱ",
    [ 0x2C02 ] = "ⰲ",
    [ 0x2C03 ] = "ⰳ",
    [ 0x2C04 ] = "ⰴ",
    [ 0x2C05 ] = "ⰵ",
    [ 0x2C06 ] = "ⰶ",
    [ 0x2C07 ] = "ⰷ",
    [ 0x2C08 ] = "ⰸ",
    [ 0x2C09 ] = "ⰹ",
    [ 0x2C0A ] = "ⰺ",
    [ 0x2C0B ] = "ⰻ",
    [ 0x2C0C ] = "ⰼ",
    [ 0x2C0D ] = "ⰽ",
    [ 0x2C0E ] = "ⰾ",
    [ 0x2C0F ] = "ⰿ",
    [ 0x2C10 ] = "ⱀ",
    [ 0x2C11 ] = "ⱁ",
    [ 0x2C12 ] = "ⱂ",
    [ 0x2C13 ] = "ⱃ",
    [ 0x2C14 ] = "ⱄ",
    [ 0x2C15 ] = "ⱅ",
    [ 0x2C16 ] = "ⱆ",
    [ 0x2C17 ] = "ⱇ",
    [ 0x2C18 ] = "ⱈ",
    [ 0x2C19 ] = "ⱉ",
    [ 0x2C1A ] = "ⱊ",
    [ 0x2C1B ] = "ⱋ",
    [ 0x2C1C ] = "ⱌ",
    [ 0x2C1D ] = "ⱍ",
    [ 0x2C1E ] = "ⱎ",
    [ 0x2C1F ] = "ⱏ",
    [ 0x2C20 ] = "ⱐ",
    [ 0x2C21 ] = "ⱑ",
    [ 0x2C22 ] = "ⱒ",
    [ 0x2C23 ] = "ⱓ",
    [ 0x2C24 ] = "ⱔ",
    [ 0x2C25 ] = "ⱕ",
    [ 0x2C26 ] = "ⱖ",
    [ 0x2C27 ] = "ⱗ",
    [ 0x2C28 ] = "ⱘ",
    [ 0x2C29 ] = "ⱙ",
    [ 0x2C2A ] = "ⱚ",
    [ 0x2C2B ] = "ⱛ",
    [ 0x2C2C ] = "ⱜ",
    [ 0x2C2D ] = "ⱝ",
    [ 0x2C2E ] = "ⱞ",
    [ 0x2C60 ] = "ⱡ",
    [ 0x2C62 ] = "ɫ",
    [ 0x2C63 ] = "ᵽ",
    [ 0x2C64 ] = "ɽ",
    [ 0x2C67 ] = "ⱨ",
    [ 0x2C69 ] = "ⱪ",
    [ 0x2C6B ] = "ⱬ",
    [ 0x2C75 ] = "ⱶ",
    [ 0x2C80 ] = "ⲁ",
    [ 0x2C82 ] = "ⲃ",
    [ 0x2C84 ] = "ⲅ",
    [ 0x2C86 ] = "ⲇ",
    [ 0x2C88 ] = "ⲉ",
    [ 0x2C8A ] = "ⲋ",
    [ 0x2C8C ] = "ⲍ",
    [ 0x2C8E ] = "ⲏ",
    [ 0x2C90 ] = "ⲑ",
    [ 0x2C92 ] = "ⲓ",
    [ 0x2C94 ] = "ⲕ",
    [ 0x2C96 ] = "ⲗ",
    [ 0x2C98 ] = "ⲙ",
    [ 0x2C9A ] = "ⲛ",
    [ 0x2C9C ] = "ⲝ",
    [ 0x2C9E ] = "ⲟ",
    [ 0x2CA0 ] = "ⲡ",
    [ 0x2CA2 ] = "ⲣ",
    [ 0x2CA4 ] = "ⲥ",
    [ 0x2CA6 ] = "ⲧ",
    [ 0x2CA8 ] = "ⲩ",
    [ 0x2CAA ] = "ⲫ",
    [ 0x2CAC ] = "ⲭ",
    [ 0x2CAE ] = "ⲯ",
    [ 0x2CB0 ] = "ⲱ",
    [ 0x2CB2 ] = "ⲳ",
    [ 0x2CB4 ] = "ⲵ",
    [ 0x2CB6 ] = "ⲷ",
    [ 0x2CB8 ] = "ⲹ",
    [ 0x2CBA ] = "ⲻ",
    [ 0x2CBC ] = "ⲽ",
    [ 0x2CBE ] = "ⲿ",
    [ 0x2CC0 ] = "ⳁ",
    [ 0x2CC2 ] = "ⳃ",
    [ 0x2CC4 ] = "ⳅ",
    [ 0x2CC6 ] = "ⳇ",
    [ 0x2CC8 ] = "ⳉ",
    [ 0x2CCA ] = "ⳋ",
    [ 0x2CCC ] = "ⳍ",
    [ 0x2CCE ] = "ⳏ",
    [ 0x2CD0 ] = "ⳑ",
    [ 0x2CD2 ] = "ⳓ",
    [ 0x2CD4 ] = "ⳕ",
    [ 0x2CD6 ] = "ⳗ",
    [ 0x2CD8 ] = "ⳙ",
    [ 0x2CDA ] = "ⳛ",
    [ 0x2CDC ] = "ⳝ",
    [ 0x2CDE ] = "ⳟ",
    [ 0x2CE0 ] = "ⳡ",
    [ 0x2CE2 ] = "ⳣ",
    [ 0xFF21 ] = "ａ",
    [ 0xFF22 ] = "ｂ",
    [ 0xFF23 ] = "ｃ",
    [ 0xFF24 ] = "ｄ",
    [ 0xFF25 ] = "ｅ",
    [ 0xFF26 ] = "ｆ",
    [ 0xFF27 ] = "ｇ",
    [ 0xFF28 ] = "ｈ",
    [ 0xFF29 ] = "ｉ",
    [ 0xFF2A ] = "ｊ",
    [ 0xFF2B ] = "ｋ",
    [ 0xFF2C ] = "ｌ",
    [ 0xFF2D ] = "ｍ",
    [ 0xFF2E ] = "ｎ",
    [ 0xFF2F ] = "ｏ",
    [ 0xFF30 ] = "ｐ",
    [ 0xFF31 ] = "ｑ",
    [ 0xFF32 ] = "ｒ",
    [ 0xFF33 ] = "ｓ",
    [ 0xFF34 ] = "ｔ",
    [ 0xFF35 ] = "ｕ",
    [ 0xFF36 ] = "ｖ",
    [ 0xFF37 ] = "ｗ",
    [ 0xFF38 ] = "ｘ",
    [ 0xFF39 ] = "ｙ",
    [ 0xFF3A ] = "ｚ",
    [ 0x10400 ] = "𐐨",
    [ 0x10401 ] = "𐐩",
    [ 0x10402 ] = "𐐪",
    [ 0x10403 ] = "𐐫",
    [ 0x10404 ] = "𐐬",
    [ 0x10405 ] = "𐐭",
    [ 0x10406 ] = "𐐮",
    [ 0x10407 ] = "𐐯",
    [ 0x10408 ] = "𐐰",
    [ 0x10409 ] = "𐐱",
    [ 0x1040A ] = "𐐲",
    [ 0x1040B ] = "𐐳",
    [ 0x1040C ] = "𐐴",
    [ 0x1040D ] = "𐐵",
    [ 0x1040E ] = "𐐶",
    [ 0x1040F ] = "𐐷",
    [ 0x10410 ] = "𐐸",
    [ 0x10411 ] = "𐐹",
    [ 0x10412 ] = "𐐺",
    [ 0x10413 ] = "𐐻",
    [ 0x10414 ] = "𐐼",
    [ 0x10415 ] = "𐐽",
    [ 0x10416 ] = "𐐾",
    [ 0x10417 ] = "𐐿",
    [ 0x10418 ] = "𐑀",
    [ 0x10419 ] = "𐑁",
    [ 0x1041A ] = "𐑂",
    [ 0x1041B ] = "𐑃",
    [ 0x1041C ] = "𐑄",
    [ 0x1041D ] = "𐑅",
    [ 0x1041E ] = "𐑆",
    [ 0x1041F ] = "𐑇",
    [ 0x10420 ] = "𐑈",
    [ 0x10421 ] = "𐑉",
    [ 0x10422 ] = "𐑊",
    [ 0x10423 ] = "𐑋",
    [ 0x10424 ] = "𐑌",
    [ 0x10425 ] = "𐑍",
    [ 0x10426 ] = "𐑎",
    [ 0x10427 ] = "𐑏",
}

---@type table<integer, string>
local codepoint_to_upper = {
    [ 0x61 ] = "A",
    [ 0x62 ] = "B",
    [ 0x63 ] = "C",
    [ 0x64 ] = "D",
    [ 0x65 ] = "E",
    [ 0x66 ] = "F",
    [ 0x67 ] = "G",
    [ 0x68 ] = "H",
    [ 0x69 ] = "I",
    [ 0x6A ] = "J",
    [ 0x6B ] = "K",
    [ 0x6C ] = "L",
    [ 0x6D ] = "M",
    [ 0x6E ] = "N",
    [ 0x6F ] = "O",
    [ 0x70 ] = "P",
    [ 0x71 ] = "Q",
    [ 0x72 ] = "R",
    [ 0x73 ] = "S",
    [ 0x74 ] = "T",
    [ 0x75 ] = "U",
    [ 0x76 ] = "V",
    [ 0x77 ] = "W",
    [ 0x78 ] = "X",
    [ 0x79 ] = "Y",
    [ 0x7A ] = "Z",
    [ 0xB5 ] = "Μ",
    [ 0xE0 ] = "À",
    [ 0xE1 ] = "Á",
    [ 0xE2 ] = "Â",
    [ 0xE3 ] = "Ã",
    [ 0xE4 ] = "Ä",
    [ 0xE5 ] = "Å",
    [ 0xE6 ] = "Æ",
    [ 0xE7 ] = "Ç",
    [ 0xE8 ] = "È",
    [ 0xE9 ] = "É",
    [ 0xEA ] = "Ê",
    [ 0xEB ] = "Ë",
    [ 0xEC ] = "Ì",
    [ 0xED ] = "Í",
    [ 0xEE ] = "Î",
    [ 0xEF ] = "Ï",
    [ 0xF0 ] = "Ð",
    [ 0xF1 ] = "Ñ",
    [ 0xF2 ] = "Ò",
    [ 0xF3 ] = "Ó",
    [ 0xF4 ] = "Ô",
    [ 0xF5 ] = "Õ",
    [ 0xF6 ] = "Ö",
    [ 0xF8 ] = "Ø",
    [ 0xF9 ] = "Ù",
    [ 0xFA ] = "Ú",
    [ 0xFB ] = "Û",
    [ 0xFC ] = "Ü",
    [ 0xFD ] = "Ý",
    [ 0xFE ] = "Þ",
    [ 0xFF ] = "Ÿ",
    [ 0x101 ] = "Ā",
    [ 0x103 ] = "Ă",
    [ 0x105 ] = "Ą",
    [ 0x107 ] = "Ć",
    [ 0x109 ] = "Ĉ",
    [ 0x10B ] = "Ċ",
    [ 0x10D ] = "Č",
    [ 0x10F ] = "Ď",
    [ 0x111 ] = "Đ",
    [ 0x113 ] = "Ē",
    [ 0x115 ] = "Ĕ",
    [ 0x117 ] = "Ė",
    [ 0x119 ] = "Ę",
    [ 0x11B ] = "Ě",
    [ 0x11D ] = "Ĝ",
    [ 0x11F ] = "Ğ",
    [ 0x121 ] = "Ġ",
    [ 0x123 ] = "Ģ",
    [ 0x125 ] = "Ĥ",
    [ 0x127 ] = "Ħ",
    [ 0x129 ] = "Ĩ",
    [ 0x12B ] = "Ī",
    [ 0x12D ] = "Ĭ",
    [ 0x12F ] = "Į",
    [ 0x131 ] = "I",
    [ 0x133 ] = "Ĳ",
    [ 0x135 ] = "Ĵ",
    [ 0x137 ] = "Ķ",
    [ 0x13A ] = "Ĺ",
    [ 0x13C ] = "Ļ",
    [ 0x13E ] = "Ľ",
    [ 0x140 ] = "Ŀ",
    [ 0x142 ] = "Ł",
    [ 0x144 ] = "Ń",
    [ 0x146 ] = "Ņ",
    [ 0x148 ] = "Ň",
    [ 0x14B ] = "Ŋ",
    [ 0x14D ] = "Ō",
    [ 0x14F ] = "Ŏ",
    [ 0x151 ] = "Ő",
    [ 0x153 ] = "Œ",
    [ 0x155 ] = "Ŕ",
    [ 0x157 ] = "Ŗ",
    [ 0x159 ] = "Ř",
    [ 0x15B ] = "Ś",
    [ 0x15D ] = "Ŝ",
    [ 0x15F ] = "Ş",
    [ 0x161 ] = "Š",
    [ 0x163 ] = "Ţ",
    [ 0x165 ] = "Ť",
    [ 0x167 ] = "Ŧ",
    [ 0x169 ] = "Ũ",
    [ 0x16B ] = "Ū",
    [ 0x16D ] = "Ŭ",
    [ 0x16F ] = "Ů",
    [ 0x171 ] = "Ű",
    [ 0x173 ] = "Ų",
    [ 0x175 ] = "Ŵ",
    [ 0x177 ] = "Ŷ",
    [ 0x17A ] = "Ź",
    [ 0x17C ] = "Ż",
    [ 0x17E ] = "Ž",
    [ 0x17F ] = "S",
    [ 0x180 ] = "Ƀ",
    [ 0x183 ] = "Ƃ",
    [ 0x185 ] = "Ƅ",
    [ 0x188 ] = "Ƈ",
    [ 0x18C ] = "Ƌ",
    [ 0x192 ] = "Ƒ",
    [ 0x195 ] = "Ƕ",
    [ 0x199 ] = "Ƙ",
    [ 0x19A ] = "Ƚ",
    [ 0x19E ] = "Ƞ",
    [ 0x1A1 ] = "Ơ",
    [ 0x1A3 ] = "Ƣ",
    [ 0x1A5 ] = "Ƥ",
    [ 0x1A8 ] = "Ƨ",
    [ 0x1AD ] = "Ƭ",
    [ 0x1B0 ] = "Ư",
    [ 0x1B4 ] = "Ƴ",
    [ 0x1B6 ] = "Ƶ",
    [ 0x1B9 ] = "Ƹ",
    [ 0x1BD ] = "Ƽ",
    [ 0x1BF ] = "Ƿ",
    [ 0x1C5 ] = "Ǆ",
    [ 0x1C6 ] = "Ǆ",
    [ 0x1C8 ] = "Ǉ",
    [ 0x1C9 ] = "Ǉ",
    [ 0x1CB ] = "Ǌ",
    [ 0x1CC ] = "Ǌ",
    [ 0x1CE ] = "Ǎ",
    [ 0x1D0 ] = "Ǐ",
    [ 0x1D2 ] = "Ǒ",
    [ 0x1D4 ] = "Ǔ",
    [ 0x1D6 ] = "Ǖ",
    [ 0x1D8 ] = "Ǘ",
    [ 0x1DA ] = "Ǚ",
    [ 0x1DC ] = "Ǜ",
    [ 0x1DD ] = "Ǝ",
    [ 0x1DF ] = "Ǟ",
    [ 0x1E1 ] = "Ǡ",
    [ 0x1E3 ] = "Ǣ",
    [ 0x1E5 ] = "Ǥ",
    [ 0x1E7 ] = "Ǧ",
    [ 0x1E9 ] = "Ǩ",
    [ 0x1EB ] = "Ǫ",
    [ 0x1ED ] = "Ǭ",
    [ 0x1EF ] = "Ǯ",
    [ 0x1F2 ] = "Ǳ",
    [ 0x1F3 ] = "Ǳ",
    [ 0x1F5 ] = "Ǵ",
    [ 0x1F9 ] = "Ǹ",
    [ 0x1FB ] = "Ǻ",
    [ 0x1FD ] = "Ǽ",
    [ 0x1FF ] = "Ǿ",
    [ 0x201 ] = "Ȁ",
    [ 0x203 ] = "Ȃ",
    [ 0x205 ] = "Ȅ",
    [ 0x207 ] = "Ȇ",
    [ 0x209 ] = "Ȉ",
    [ 0x20B ] = "Ȋ",
    [ 0x20D ] = "Ȍ",
    [ 0x20F ] = "Ȏ",
    [ 0x211 ] = "Ȑ",
    [ 0x213 ] = "Ȓ",
    [ 0x215 ] = "Ȕ",
    [ 0x217 ] = "Ȗ",
    [ 0x219 ] = "Ș",
    [ 0x21B ] = "Ț",
    [ 0x21D ] = "Ȝ",
    [ 0x21F ] = "Ȟ",
    [ 0x223 ] = "Ȣ",
    [ 0x225 ] = "Ȥ",
    [ 0x227 ] = "Ȧ",
    [ 0x229 ] = "Ȩ",
    [ 0x22B ] = "Ȫ",
    [ 0x22D ] = "Ȭ",
    [ 0x22F ] = "Ȯ",
    [ 0x231 ] = "Ȱ",
    [ 0x233 ] = "Ȳ",
    [ 0x23C ] = "Ȼ",
    [ 0x242 ] = "Ɂ",
    [ 0x247 ] = "Ɇ",
    [ 0x249 ] = "Ɉ",
    [ 0x24B ] = "Ɋ",
    [ 0x24D ] = "Ɍ",
    [ 0x24F ] = "Ɏ",
    [ 0x253 ] = "Ɓ",
    [ 0x254 ] = "Ɔ",
    [ 0x256 ] = "Ɖ",
    [ 0x257 ] = "Ɗ",
    [ 0x259 ] = "Ə",
    [ 0x25B ] = "Ɛ",
    [ 0x260 ] = "Ɠ",
    [ 0x263 ] = "Ɣ",
    [ 0x268 ] = "Ɨ",
    [ 0x269 ] = "Ɩ",
    [ 0x26B ] = "Ɫ",
    [ 0x26F ] = "Ɯ",
    [ 0x272 ] = "Ɲ",
    [ 0x275 ] = "Ɵ",
    [ 0x27D ] = "Ɽ",
    [ 0x280 ] = "Ʀ",
    [ 0x283 ] = "Ʃ",
    [ 0x288 ] = "Ʈ",
    [ 0x289 ] = "Ʉ",
    [ 0x28A ] = "Ʊ",
    [ 0x28B ] = "Ʋ",
    [ 0x28C ] = "Ʌ",
    [ 0x292 ] = "Ʒ",
    [ 0x345 ] = "Ι",
    [ 0x37B ] = "Ͻ",
    [ 0x37C ] = "Ͼ",
    [ 0x37D ] = "Ͽ",
    [ 0x3AC ] = "Ά",
    [ 0x3AD ] = "Έ",
    [ 0x3AE ] = "Ή",
    [ 0x3AF ] = "Ί",
    [ 0x3B1 ] = "Α",
    [ 0x3B2 ] = "Β",
    [ 0x3B3 ] = "Γ",
    [ 0x3B4 ] = "Δ",
    [ 0x3B5 ] = "Ε",
    [ 0x3B6 ] = "Ζ",
    [ 0x3B7 ] = "Η",
    [ 0x3B8 ] = "Θ",
    [ 0x3B9 ] = "Ι",
    [ 0x3BA ] = "Κ",
    [ 0x3BB ] = "Λ",
    [ 0x3BC ] = "Μ",
    [ 0x3BD ] = "Ν",
    [ 0x3BE ] = "Ξ",
    [ 0x3BF ] = "Ο",
    [ 0x3C0 ] = "Π",
    [ 0x3C1 ] = "Ρ",
    [ 0x3C2 ] = "Σ",
    [ 0x3C3 ] = "Σ",
    [ 0x3C4 ] = "Τ",
    [ 0x3C5 ] = "Υ",
    [ 0x3C6 ] = "Φ",
    [ 0x3C7 ] = "Χ",
    [ 0x3C8 ] = "Ψ",
    [ 0x3C9 ] = "Ω",
    [ 0x3CA ] = "Ϊ",
    [ 0x3CB ] = "Ϋ",
    [ 0x3CC ] = "Ό",
    [ 0x3CD ] = "Ύ",
    [ 0x3CE ] = "Ώ",
    [ 0x3D0 ] = "Β",
    [ 0x3D1 ] = "Θ",
    [ 0x3D5 ] = "Φ",
    [ 0x3D6 ] = "Π",
    [ 0x3D9 ] = "Ϙ",
    [ 0x3DB ] = "Ϛ",
    [ 0x3DD ] = "Ϝ",
    [ 0x3DF ] = "Ϟ",
    [ 0x3E1 ] = "Ϡ",
    [ 0x3E3 ] = "Ϣ",
    [ 0x3E5 ] = "Ϥ",
    [ 0x3E7 ] = "Ϧ",
    [ 0x3E9 ] = "Ϩ",
    [ 0x3EB ] = "Ϫ",
    [ 0x3ED ] = "Ϭ",
    [ 0x3EF ] = "Ϯ",
    [ 0x3F0 ] = "Κ",
    [ 0x3F1 ] = "Ρ",
    [ 0x3F2 ] = "Ϲ",
    [ 0x3F5 ] = "Ε",
    [ 0x3F8 ] = "Ϸ",
    [ 0x3FB ] = "Ϻ",
    [ 0x430 ] = "А",
    [ 0x431 ] = "Б",
    [ 0x432 ] = "В",
    [ 0x433 ] = "Г",
    [ 0x434 ] = "Д",
    [ 0x435 ] = "Е",
    [ 0x436 ] = "Ж",
    [ 0x437 ] = "З",
    [ 0x438 ] = "И",
    [ 0x439 ] = "Й",
    [ 0x43A ] = "К",
    [ 0x43B ] = "Л",
    [ 0x43C ] = "М",
    [ 0x43D ] = "Н",
    [ 0x43E ] = "О",
    [ 0x43F ] = "П",
    [ 0x440 ] = "Р",
    [ 0x441 ] = "С",
    [ 0x442 ] = "Т",
    [ 0x443 ] = "У",
    [ 0x444 ] = "Ф",
    [ 0x445 ] = "Х",
    [ 0x446 ] = "Ц",
    [ 0x447 ] = "Ч",
    [ 0x448 ] = "Ш",
    [ 0x449 ] = "Щ",
    [ 0x44A ] = "Ъ",
    [ 0x44B ] = "Ы",
    [ 0x44C ] = "Ь",
    [ 0x44D ] = "Э",
    [ 0x44E ] = "Ю",
    [ 0x44F ] = "Я",
    [ 0x450 ] = "Ѐ",
    [ 0x451 ] = "Ё",
    [ 0x452 ] = "Ђ",
    [ 0x453 ] = "Ѓ",
    [ 0x454 ] = "Є",
    [ 0x455 ] = "Ѕ",
    [ 0x456 ] = "І",
    [ 0x457 ] = "Ї",
    [ 0x458 ] = "Ј",
    [ 0x459 ] = "Љ",
    [ 0x45A ] = "Њ",
    [ 0x45B ] = "Ћ",
    [ 0x45C ] = "Ќ",
    [ 0x45D ] = "Ѝ",
    [ 0x45E ] = "Ў",
    [ 0x45F ] = "Џ",
    [ 0x461 ] = "Ѡ",
    [ 0x463 ] = "Ѣ",
    [ 0x465 ] = "Ѥ",
    [ 0x467 ] = "Ѧ",
    [ 0x469 ] = "Ѩ",
    [ 0x46B ] = "Ѫ",
    [ 0x46D ] = "Ѭ",
    [ 0x46F ] = "Ѯ",
    [ 0x471 ] = "Ѱ",
    [ 0x473 ] = "Ѳ",
    [ 0x475 ] = "Ѵ",
    [ 0x477 ] = "Ѷ",
    [ 0x479 ] = "Ѹ",
    [ 0x47B ] = "Ѻ",
    [ 0x47D ] = "Ѽ",
    [ 0x47F ] = "Ѿ",
    [ 0x481 ] = "Ҁ",
    [ 0x48B ] = "Ҋ",
    [ 0x48D ] = "Ҍ",
    [ 0x48F ] = "Ҏ",
    [ 0x491 ] = "Ґ",
    [ 0x493 ] = "Ғ",
    [ 0x495 ] = "Ҕ",
    [ 0x497 ] = "Җ",
    [ 0x499 ] = "Ҙ",
    [ 0x49B ] = "Қ",
    [ 0x49D ] = "Ҝ",
    [ 0x49F ] = "Ҟ",
    [ 0x4A1 ] = "Ҡ",
    [ 0x4A3 ] = "Ң",
    [ 0x4A5 ] = "Ҥ",
    [ 0x4A7 ] = "Ҧ",
    [ 0x4A9 ] = "Ҩ",
    [ 0x4AB ] = "Ҫ",
    [ 0x4AD ] = "Ҭ",
    [ 0x4AF ] = "Ү",
    [ 0x4B1 ] = "Ұ",
    [ 0x4B3 ] = "Ҳ",
    [ 0x4B5 ] = "Ҵ",
    [ 0x4B7 ] = "Ҷ",
    [ 0x4B9 ] = "Ҹ",
    [ 0x4BB ] = "Һ",
    [ 0x4BD ] = "Ҽ",
    [ 0x4BF ] = "Ҿ",
    [ 0x4C2 ] = "Ӂ",
    [ 0x4C4 ] = "Ӄ",
    [ 0x4C6 ] = "Ӆ",
    [ 0x4C8 ] = "Ӈ",
    [ 0x4CA ] = "Ӊ",
    [ 0x4CC ] = "Ӌ",
    [ 0x4CE ] = "Ӎ",
    [ 0x4CF ] = "Ӏ",
    [ 0x4D1 ] = "Ӑ",
    [ 0x4D3 ] = "Ӓ",
    [ 0x4D5 ] = "Ӕ",
    [ 0x4D7 ] = "Ӗ",
    [ 0x4D9 ] = "Ә",
    [ 0x4DB ] = "Ӛ",
    [ 0x4DD ] = "Ӝ",
    [ 0x4DF ] = "Ӟ",
    [ 0x4E1 ] = "Ӡ",
    [ 0x4E3 ] = "Ӣ",
    [ 0x4E5 ] = "Ӥ",
    [ 0x4E7 ] = "Ӧ",
    [ 0x4E9 ] = "Ө",
    [ 0x4EB ] = "Ӫ",
    [ 0x4ED ] = "Ӭ",
    [ 0x4EF ] = "Ӯ",
    [ 0x4F1 ] = "Ӱ",
    [ 0x4F3 ] = "Ӳ",
    [ 0x4F5 ] = "Ӵ",
    [ 0x4F7 ] = "Ӷ",
    [ 0x4F9 ] = "Ӹ",
    [ 0x4FB ] = "Ӻ",
    [ 0x4FD ] = "Ӽ",
    [ 0x4FF ] = "Ӿ",
    [ 0x501 ] = "Ԁ",
    [ 0x503 ] = "Ԃ",
    [ 0x505 ] = "Ԅ",
    [ 0x507 ] = "Ԇ",
    [ 0x509 ] = "Ԉ",
    [ 0x50B ] = "Ԋ",
    [ 0x50D ] = "Ԍ",
    [ 0x50F ] = "Ԏ",
    [ 0x511 ] = "Ԑ",
    [ 0x513 ] = "Ԓ",
    [ 0x561 ] = "Ա",
    [ 0x562 ] = "Բ",
    [ 0x563 ] = "Գ",
    [ 0x564 ] = "Դ",
    [ 0x565 ] = "Ե",
    [ 0x566 ] = "Զ",
    [ 0x567 ] = "Է",
    [ 0x568 ] = "Ը",
    [ 0x569 ] = "Թ",
    [ 0x56A ] = "Ժ",
    [ 0x56B ] = "Ի",
    [ 0x56C ] = "Լ",
    [ 0x56D ] = "Խ",
    [ 0x56E ] = "Ծ",
    [ 0x56F ] = "Կ",
    [ 0x570 ] = "Հ",
    [ 0x571 ] = "Ձ",
    [ 0x572 ] = "Ղ",
    [ 0x573 ] = "Ճ",
    [ 0x574 ] = "Մ",
    [ 0x575 ] = "Յ",
    [ 0x576 ] = "Ն",
    [ 0x577 ] = "Շ",
    [ 0x578 ] = "Ո",
    [ 0x579 ] = "Չ",
    [ 0x57A ] = "Պ",
    [ 0x57B ] = "Ջ",
    [ 0x57C ] = "Ռ",
    [ 0x57D ] = "Ս",
    [ 0x57E ] = "Վ",
    [ 0x57F ] = "Տ",
    [ 0x580 ] = "Ր",
    [ 0x581 ] = "Ց",
    [ 0x582 ] = "Ւ",
    [ 0x583 ] = "Փ",
    [ 0x584 ] = "Ք",
    [ 0x585 ] = "Օ",
    [ 0x586 ] = "Ֆ",
    [ 0x1D7D ] = "Ᵽ",
    [ 0x1E01 ] = "Ḁ",
    [ 0x1E03 ] = "Ḃ",
    [ 0x1E05 ] = "Ḅ",
    [ 0x1E07 ] = "Ḇ",
    [ 0x1E09 ] = "Ḉ",
    [ 0x1E0B ] = "Ḋ",
    [ 0x1E0D ] = "Ḍ",
    [ 0x1E0F ] = "Ḏ",
    [ 0x1E11 ] = "Ḑ",
    [ 0x1E13 ] = "Ḓ",
    [ 0x1E15 ] = "Ḕ",
    [ 0x1E17 ] = "Ḗ",
    [ 0x1E19 ] = "Ḙ",
    [ 0x1E1B ] = "Ḛ",
    [ 0x1E1D ] = "Ḝ",
    [ 0x1E1F ] = "Ḟ",
    [ 0x1E21 ] = "Ḡ",
    [ 0x1E23 ] = "Ḣ",
    [ 0x1E25 ] = "Ḥ",
    [ 0x1E27 ] = "Ḧ",
    [ 0x1E29 ] = "Ḩ",
    [ 0x1E2B ] = "Ḫ",
    [ 0x1E2D ] = "Ḭ",
    [ 0x1E2F ] = "Ḯ",
    [ 0x1E31 ] = "Ḱ",
    [ 0x1E33 ] = "Ḳ",
    [ 0x1E35 ] = "Ḵ",
    [ 0x1E37 ] = "Ḷ",
    [ 0x1E39 ] = "Ḹ",
    [ 0x1E3B ] = "Ḻ",
    [ 0x1E3D ] = "Ḽ",
    [ 0x1E3F ] = "Ḿ",
    [ 0x1E41 ] = "Ṁ",
    [ 0x1E43 ] = "Ṃ",
    [ 0x1E45 ] = "Ṅ",
    [ 0x1E47 ] = "Ṇ",
    [ 0x1E49 ] = "Ṉ",
    [ 0x1E4B ] = "Ṋ",
    [ 0x1E4D ] = "Ṍ",
    [ 0x1E4F ] = "Ṏ",
    [ 0x1E51 ] = "Ṑ",
    [ 0x1E53 ] = "Ṓ",
    [ 0x1E55 ] = "Ṕ",
    [ 0x1E57 ] = "Ṗ",
    [ 0x1E59 ] = "Ṙ",
    [ 0x1E5B ] = "Ṛ",
    [ 0x1E5D ] = "Ṝ",
    [ 0x1E5F ] = "Ṟ",
    [ 0x1E61 ] = "Ṡ",
    [ 0x1E63 ] = "Ṣ",
    [ 0x1E65 ] = "Ṥ",
    [ 0x1E67 ] = "Ṧ",
    [ 0x1E69 ] = "Ṩ",
    [ 0x1E6B ] = "Ṫ",
    [ 0x1E6D ] = "Ṭ",
    [ 0x1E6F ] = "Ṯ",
    [ 0x1E71 ] = "Ṱ",
    [ 0x1E73 ] = "Ṳ",
    [ 0x1E75 ] = "Ṵ",
    [ 0x1E77 ] = "Ṷ",
    [ 0x1E79 ] = "Ṹ",
    [ 0x1E7B ] = "Ṻ",
    [ 0x1E7D ] = "Ṽ",
    [ 0x1E7F ] = "Ṿ",
    [ 0x1E81 ] = "Ẁ",
    [ 0x1E83 ] = "Ẃ",
    [ 0x1E85 ] = "Ẅ",
    [ 0x1E87 ] = "Ẇ",
    [ 0x1E89 ] = "Ẉ",
    [ 0x1E8B ] = "Ẋ",
    [ 0x1E8D ] = "Ẍ",
    [ 0x1E8F ] = "Ẏ",
    [ 0x1E91 ] = "Ẑ",
    [ 0x1E93 ] = "Ẓ",
    [ 0x1E95 ] = "Ẕ",
    [ 0x1E9B ] = "Ṡ",
    [ 0x1EA1 ] = "Ạ",
    [ 0x1EA3 ] = "Ả",
    [ 0x1EA5 ] = "Ấ",
    [ 0x1EA7 ] = "Ầ",
    [ 0x1EA9 ] = "Ẩ",
    [ 0x1EAB ] = "Ẫ",
    [ 0x1EAD ] = "Ậ",
    [ 0x1EAF ] = "Ắ",
    [ 0x1EB1 ] = "Ằ",
    [ 0x1EB3 ] = "Ẳ",
    [ 0x1EB5 ] = "Ẵ",
    [ 0x1EB7 ] = "Ặ",
    [ 0x1EB9 ] = "Ẹ",
    [ 0x1EBB ] = "Ẻ",
    [ 0x1EBD ] = "Ẽ",
    [ 0x1EBF ] = "Ế",
    [ 0x1EC1 ] = "Ề",
    [ 0x1EC3 ] = "Ể",
    [ 0x1EC5 ] = "Ễ",
    [ 0x1EC7 ] = "Ệ",
    [ 0x1EC9 ] = "Ỉ",
    [ 0x1ECB ] = "Ị",
    [ 0x1ECD ] = "Ọ",
    [ 0x1ECF ] = "Ỏ",
    [ 0x1ED1 ] = "Ố",
    [ 0x1ED3 ] = "Ồ",
    [ 0x1ED5 ] = "Ổ",
    [ 0x1ED7 ] = "Ỗ",
    [ 0x1ED9 ] = "Ộ",
    [ 0x1EDB ] = "Ớ",
    [ 0x1EDD ] = "Ờ",
    [ 0x1EDF ] = "Ở",
    [ 0x1EE1 ] = "Ỡ",
    [ 0x1EE3 ] = "Ợ",
    [ 0x1EE5 ] = "Ụ",
    [ 0x1EE7 ] = "Ủ",
    [ 0x1EE9 ] = "Ứ",
    [ 0x1EEB ] = "Ừ",
    [ 0x1EED ] = "Ử",
    [ 0x1EEF ] = "Ữ",
    [ 0x1EF1 ] = "Ự",
    [ 0x1EF3 ] = "Ỳ",
    [ 0x1EF5 ] = "Ỵ",
    [ 0x1EF7 ] = "Ỷ",
    [ 0x1EF9 ] = "Ỹ",
    [ 0x1F00 ] = "Ἀ",
    [ 0x1F01 ] = "Ἁ",
    [ 0x1F02 ] = "Ἂ",
    [ 0x1F03 ] = "Ἃ",
    [ 0x1F04 ] = "Ἄ",
    [ 0x1F05 ] = "Ἅ",
    [ 0x1F06 ] = "Ἆ",
    [ 0x1F07 ] = "Ἇ",
    [ 0x1F10 ] = "Ἐ",
    [ 0x1F11 ] = "Ἑ",
    [ 0x1F12 ] = "Ἒ",
    [ 0x1F13 ] = "Ἓ",
    [ 0x1F14 ] = "Ἔ",
    [ 0x1F15 ] = "Ἕ",
    [ 0x1F20 ] = "Ἠ",
    [ 0x1F21 ] = "Ἡ",
    [ 0x1F22 ] = "Ἢ",
    [ 0x1F23 ] = "Ἣ",
    [ 0x1F24 ] = "Ἤ",
    [ 0x1F25 ] = "Ἥ",
    [ 0x1F26 ] = "Ἦ",
    [ 0x1F27 ] = "Ἧ",
    [ 0x1F30 ] = "Ἰ",
    [ 0x1F31 ] = "Ἱ",
    [ 0x1F32 ] = "Ἲ",
    [ 0x1F33 ] = "Ἳ",
    [ 0x1F34 ] = "Ἴ",
    [ 0x1F35 ] = "Ἵ",
    [ 0x1F36 ] = "Ἶ",
    [ 0x1F37 ] = "Ἷ",
    [ 0x1F40 ] = "Ὀ",
    [ 0x1F41 ] = "Ὁ",
    [ 0x1F42 ] = "Ὂ",
    [ 0x1F43 ] = "Ὃ",
    [ 0x1F44 ] = "Ὄ",
    [ 0x1F45 ] = "Ὅ",
    [ 0x1F51 ] = "Ὑ",
    [ 0x1F53 ] = "Ὓ",
    [ 0x1F55 ] = "Ὕ",
    [ 0x1F57 ] = "Ὗ",
    [ 0x1F60 ] = "Ὠ",
    [ 0x1F61 ] = "Ὡ",
    [ 0x1F62 ] = "Ὢ",
    [ 0x1F63 ] = "Ὣ",
    [ 0x1F64 ] = "Ὤ",
    [ 0x1F65 ] = "Ὥ",
    [ 0x1F66 ] = "Ὦ",
    [ 0x1F67 ] = "Ὧ",
    [ 0x1F70 ] = "Ὰ",
    [ 0x1F71 ] = "Ά",
    [ 0x1F72 ] = "Ὲ",
    [ 0x1F73 ] = "Έ",
    [ 0x1F74 ] = "Ὴ",
    [ 0x1F75 ] = "Ή",
    [ 0x1F76 ] = "Ὶ",
    [ 0x1F77 ] = "Ί",
    [ 0x1F78 ] = "Ὸ",
    [ 0x1F79 ] = "Ό",
    [ 0x1F7A ] = "Ὺ",
    [ 0x1F7B ] = "Ύ",
    [ 0x1F7C ] = "Ὼ",
    [ 0x1F7D ] = "Ώ",
    [ 0x1F80 ] = "ᾈ",
    [ 0x1F81 ] = "ᾉ",
    [ 0x1F82 ] = "ᾊ",
    [ 0x1F83 ] = "ᾋ",
    [ 0x1F84 ] = "ᾌ",
    [ 0x1F85 ] = "ᾍ",
    [ 0x1F86 ] = "ᾎ",
    [ 0x1F87 ] = "ᾏ",
    [ 0x1F90 ] = "ᾘ",
    [ 0x1F91 ] = "ᾙ",
    [ 0x1F92 ] = "ᾚ",
    [ 0x1F93 ] = "ᾛ",
    [ 0x1F94 ] = "ᾜ",
    [ 0x1F95 ] = "ᾝ",
    [ 0x1F96 ] = "ᾞ",
    [ 0x1F97 ] = "ᾟ",
    [ 0x1FA0 ] = "ᾨ",
    [ 0x1FA1 ] = "ᾩ",
    [ 0x1FA2 ] = "ᾪ",
    [ 0x1FA3 ] = "ᾫ",
    [ 0x1FA4 ] = "ᾬ",
    [ 0x1FA5 ] = "ᾭ",
    [ 0x1FA6 ] = "ᾮ",
    [ 0x1FA7 ] = "ᾯ",
    [ 0x1FB0 ] = "Ᾰ",
    [ 0x1FB1 ] = "Ᾱ",
    [ 0x1FB3 ] = "ᾼ",
    [ 0x1FBE ] = "Ι",
    [ 0x1FC3 ] = "ῌ",
    [ 0x1FD0 ] = "Ῐ",
    [ 0x1FD1 ] = "Ῑ",
    [ 0x1FE0 ] = "Ῠ",
    [ 0x1FE1 ] = "Ῡ",
    [ 0x1FE5 ] = "Ῥ",
    [ 0x1FF3 ] = "ῼ",
    [ 0x214E ] = "Ⅎ",
    [ 0x2170 ] = "Ⅰ",
    [ 0x2171 ] = "Ⅱ",
    [ 0x2172 ] = "Ⅲ",
    [ 0x2173 ] = "Ⅳ",
    [ 0x2174 ] = "Ⅴ",
    [ 0x2175 ] = "Ⅵ",
    [ 0x2176 ] = "Ⅶ",
    [ 0x2177 ] = "Ⅷ",
    [ 0x2178 ] = "Ⅸ",
    [ 0x2179 ] = "Ⅹ",
    [ 0x217A ] = "Ⅺ",
    [ 0x217B ] = "Ⅻ",
    [ 0x217C ] = "Ⅼ",
    [ 0x217D ] = "Ⅽ",
    [ 0x217E ] = "Ⅾ",
    [ 0x217F ] = "Ⅿ",
    [ 0x2184 ] = "Ↄ",
    [ 0x24D0 ] = "Ⓐ",
    [ 0x24D1 ] = "Ⓑ",
    [ 0x24D2 ] = "Ⓒ",
    [ 0x24D3 ] = "Ⓓ",
    [ 0x24D4 ] = "Ⓔ",
    [ 0x24D5 ] = "Ⓕ",
    [ 0x24D6 ] = "Ⓖ",
    [ 0x24D7 ] = "Ⓗ",
    [ 0x24D8 ] = "Ⓘ",
    [ 0x24D9 ] = "Ⓙ",
    [ 0x24DA ] = "Ⓚ",
    [ 0x24DB ] = "Ⓛ",
    [ 0x24DC ] = "Ⓜ",
    [ 0x24DD ] = "Ⓝ",
    [ 0x24DE ] = "Ⓞ",
    [ 0x24DF ] = "Ⓟ",
    [ 0x24E0 ] = "Ⓠ",
    [ 0x24E1 ] = "Ⓡ",
    [ 0x24E2 ] = "Ⓢ",
    [ 0x24E3 ] = "Ⓣ",
    [ 0x24E4 ] = "Ⓤ",
    [ 0x24E5 ] = "Ⓥ",
    [ 0x24E6 ] = "Ⓦ",
    [ 0x24E7 ] = "Ⓧ",
    [ 0x24E8 ] = "Ⓨ",
    [ 0x24E9 ] = "Ⓩ",
    [ 0x2C30 ] = "Ⰰ",
    [ 0x2C31 ] = "Ⰱ",
    [ 0x2C32 ] = "Ⰲ",
    [ 0x2C33 ] = "Ⰳ",
    [ 0x2C34 ] = "Ⰴ",
    [ 0x2C35 ] = "Ⰵ",
    [ 0x2C36 ] = "Ⰶ",
    [ 0x2C37 ] = "Ⰷ",
    [ 0x2C38 ] = "Ⰸ",
    [ 0x2C39 ] = "Ⰹ",
    [ 0x2C3A ] = "Ⰺ",
    [ 0x2C3B ] = "Ⰻ",
    [ 0x2C3C ] = "Ⰼ",
    [ 0x2C3D ] = "Ⰽ",
    [ 0x2C3E ] = "Ⰾ",
    [ 0x2C3F ] = "Ⰿ",
    [ 0x2C40 ] = "Ⱀ",
    [ 0x2C41 ] = "Ⱁ",
    [ 0x2C42 ] = "Ⱂ",
    [ 0x2C43 ] = "Ⱃ",
    [ 0x2C44 ] = "Ⱄ",
    [ 0x2C45 ] = "Ⱅ",
    [ 0x2C46 ] = "Ⱆ",
    [ 0x2C47 ] = "Ⱇ",
    [ 0x2C48 ] = "Ⱈ",
    [ 0x2C49 ] = "Ⱉ",
    [ 0x2C4A ] = "Ⱊ",
    [ 0x2C4B ] = "Ⱋ",
    [ 0x2C4C ] = "Ⱌ",
    [ 0x2C4D ] = "Ⱍ",
    [ 0x2C4E ] = "Ⱎ",
    [ 0x2C4F ] = "Ⱏ",
    [ 0x2C50 ] = "Ⱐ",
    [ 0x2C51 ] = "Ⱑ",
    [ 0x2C52 ] = "Ⱒ",
    [ 0x2C53 ] = "Ⱓ",
    [ 0x2C54 ] = "Ⱔ",
    [ 0x2C55 ] = "Ⱕ",
    [ 0x2C56 ] = "Ⱖ",
    [ 0x2C57 ] = "Ⱗ",
    [ 0x2C58 ] = "Ⱘ",
    [ 0x2C59 ] = "Ⱙ",
    [ 0x2C5A ] = "Ⱚ",
    [ 0x2C5B ] = "Ⱛ",
    [ 0x2C5C ] = "Ⱜ",
    [ 0x2C5D ] = "Ⱝ",
    [ 0x2C5E ] = "Ⱞ",
    [ 0x2C61 ] = "Ⱡ",
    [ 0x2C65 ] = "Ⱥ",
    [ 0x2C66 ] = "Ⱦ",
    [ 0x2C68 ] = "Ⱨ",
    [ 0x2C6A ] = "Ⱪ",
    [ 0x2C6C ] = "Ⱬ",
    [ 0x2C76 ] = "Ⱶ",
    [ 0x2C81 ] = "Ⲁ",
    [ 0x2C83 ] = "Ⲃ",
    [ 0x2C85 ] = "Ⲅ",
    [ 0x2C87 ] = "Ⲇ",
    [ 0x2C89 ] = "Ⲉ",
    [ 0x2C8B ] = "Ⲋ",
    [ 0x2C8D ] = "Ⲍ",
    [ 0x2C8F ] = "Ⲏ",
    [ 0x2C91 ] = "Ⲑ",
    [ 0x2C93 ] = "Ⲓ",
    [ 0x2C95 ] = "Ⲕ",
    [ 0x2C97 ] = "Ⲗ",
    [ 0x2C99 ] = "Ⲙ",
    [ 0x2C9B ] = "Ⲛ",
    [ 0x2C9D ] = "Ⲝ",
    [ 0x2C9F ] = "Ⲟ",
    [ 0x2CA1 ] = "Ⲡ",
    [ 0x2CA3 ] = "Ⲣ",
    [ 0x2CA5 ] = "Ⲥ",
    [ 0x2CA7 ] = "Ⲧ",
    [ 0x2CA9 ] = "Ⲩ",
    [ 0x2CAB ] = "Ⲫ",
    [ 0x2CAD ] = "Ⲭ",
    [ 0x2CAF ] = "Ⲯ",
    [ 0x2CB1 ] = "Ⲱ",
    [ 0x2CB3 ] = "Ⲳ",
    [ 0x2CB5 ] = "Ⲵ",
    [ 0x2CB7 ] = "Ⲷ",
    [ 0x2CB9 ] = "Ⲹ",
    [ 0x2CBB ] = "Ⲻ",
    [ 0x2CBD ] = "Ⲽ",
    [ 0x2CBF ] = "Ⲿ",
    [ 0x2CC1 ] = "Ⳁ",
    [ 0x2CC3 ] = "Ⳃ",
    [ 0x2CC5 ] = "Ⳅ",
    [ 0x2CC7 ] = "Ⳇ",
    [ 0x2CC9 ] = "Ⳉ",
    [ 0x2CCB ] = "Ⳋ",
    [ 0x2CCD ] = "Ⳍ",
    [ 0x2CCF ] = "Ⳏ",
    [ 0x2CD1 ] = "Ⳑ",
    [ 0x2CD3 ] = "Ⳓ",
    [ 0x2CD5 ] = "Ⳕ",
    [ 0x2CD7 ] = "Ⳗ",
    [ 0x2CD9 ] = "Ⳙ",
    [ 0x2CDB ] = "Ⳛ",
    [ 0x2CDD ] = "Ⳝ",
    [ 0x2CDF ] = "Ⳟ",
    [ 0x2CE1 ] = "Ⳡ",
    [ 0x2CE3 ] = "Ⳣ",
    [ 0x2D00 ] = "Ⴀ",
    [ 0x2D01 ] = "Ⴁ",
    [ 0x2D02 ] = "Ⴂ",
    [ 0x2D03 ] = "Ⴃ",
    [ 0x2D04 ] = "Ⴄ",
    [ 0x2D05 ] = "Ⴅ",
    [ 0x2D06 ] = "Ⴆ",
    [ 0x2D07 ] = "Ⴇ",
    [ 0x2D08 ] = "Ⴈ",
    [ 0x2D09 ] = "Ⴉ",
    [ 0x2D0A ] = "Ⴊ",
    [ 0x2D0B ] = "Ⴋ",
    [ 0x2D0C ] = "Ⴌ",
    [ 0x2D0D ] = "Ⴍ",
    [ 0x2D0E ] = "Ⴎ",
    [ 0x2D0F ] = "Ⴏ",
    [ 0x2D10 ] = "Ⴐ",
    [ 0x2D11 ] = "Ⴑ",
    [ 0x2D12 ] = "Ⴒ",
    [ 0x2D13 ] = "Ⴓ",
    [ 0x2D14 ] = "Ⴔ",
    [ 0x2D15 ] = "Ⴕ",
    [ 0x2D16 ] = "Ⴖ",
    [ 0x2D17 ] = "Ⴗ",
    [ 0x2D18 ] = "Ⴘ",
    [ 0x2D19 ] = "Ⴙ",
    [ 0x2D1A ] = "Ⴚ",
    [ 0x2D1B ] = "Ⴛ",
    [ 0x2D1C ] = "Ⴜ",
    [ 0x2D1D ] = "Ⴝ",
    [ 0x2D1E ] = "Ⴞ",
    [ 0x2D1F ] = "Ⴟ",
    [ 0x2D20 ] = "Ⴠ",
    [ 0x2D21 ] = "Ⴡ",
    [ 0x2D22 ] = "Ⴢ",
    [ 0x2D23 ] = "Ⴣ",
    [ 0x2D24 ] = "Ⴤ",
    [ 0x2D25 ] = "Ⴥ",
    [ 0xFF41 ] = "Ａ",
    [ 0xFF42 ] = "Ｂ",
    [ 0xFF43 ] = "Ｃ",
    [ 0xFF44 ] = "Ｄ",
    [ 0xFF45 ] = "Ｅ",
    [ 0xFF46 ] = "Ｆ",
    [ 0xFF47 ] = "Ｇ",
    [ 0xFF48 ] = "Ｈ",
    [ 0xFF49 ] = "Ｉ",
    [ 0xFF4A ] = "Ｊ",
    [ 0xFF4B ] = "Ｋ",
    [ 0xFF4C ] = "Ｌ",
    [ 0xFF4D ] = "Ｍ",
    [ 0xFF4E ] = "Ｎ",
    [ 0xFF4F ] = "Ｏ",
    [ 0xFF50 ] = "Ｐ",
    [ 0xFF51 ] = "Ｑ",
    [ 0xFF52 ] = "Ｒ",
    [ 0xFF53 ] = "Ｓ",
    [ 0xFF54 ] = "Ｔ",
    [ 0xFF55 ] = "Ｕ",
    [ 0xFF56 ] = "Ｖ",
    [ 0xFF57 ] = "Ｗ",
    [ 0xFF58 ] = "Ｘ",
    [ 0xFF59 ] = "Ｙ",
    [ 0xFF5A ] = "Ｚ",
    [ 0x10428 ] = "𐐀",
    [ 0x10429 ] = "𐐁",
    [ 0x1042A ] = "𐐂",
    [ 0x1042B ] = "𐐃",
    [ 0x1042C ] = "𐐄",
    [ 0x1042D ] = "𐐅",
    [ 0x1042E ] = "𐐆",
    [ 0x1042F ] = "𐐇",
    [ 0x10430 ] = "𐐈",
    [ 0x10431 ] = "𐐉",
    [ 0x10432 ] = "𐐊",
    [ 0x10433 ] = "𐐋",
    [ 0x10434 ] = "𐐌",
    [ 0x10435 ] = "𐐍",
    [ 0x10436 ] = "𐐎",
    [ 0x10437 ] = "𐐏",
    [ 0x10438 ] = "𐐐",
    [ 0x10439 ] = "𐐑",
    [ 0x1043A ] = "𐐒",
    [ 0x1043B ] = "𐐓",
    [ 0x1043C ] = "𐐔",
    [ 0x1043D ] = "𐐕",
    [ 0x1043E ] = "𐐖",
    [ 0x1043F ] = "𐐗",
    [ 0x10440 ] = "𐐘",
    [ 0x10441 ] = "𐐙",
    [ 0x10442 ] = "𐐚",
    [ 0x10443 ] = "𐐛",
    [ 0x10444 ] = "𐐜",
    [ 0x10445 ] = "𐐝",
    [ 0x10446 ] = "𐐞",
    [ 0x10447 ] = "𐐟",
    [ 0x10448 ] = "𐐠",
    [ 0x10449 ] = "𐐡",
    [ 0x1044A ] = "𐐢",
    [ 0x1044B ] = "𐐣",
    [ 0x1044C ] = "𐐤",
    [ 0x1044D ] = "𐐥",
    [ 0x1044E ] = "𐐦",
    [ 0x1044F ] = "𐐧"
}

if ffi == nil then

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
    function unicode.lower( utf8_string, start_position, end_position, lax )
        local str_length = string_len( utf8_string )
        if str_length == 0 then
            return utf8_string
        end

        local start_index, end_index = math_range( str_length, start_position, end_position )

        if start_index > end_index then
            return utf8_string
        end

        ---@type string[]
        local segments = {}

        ---@type integer
        local segment_count = 0

        if start_index ~= 1 then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_sub( utf8_string, 1, start_index - 1 )
        end

        ---@type integer
        local break_point = start_index

        repeat
            local utf8_codepoint, utf8_sequence_length = utf8_decode( utf8_string, start_index, end_index, lax )

            if utf8_codepoint ~= nil then
                local replacement = codepoint_to_lower[ utf8_codepoint ]
                if replacement ~= nil then
                    if break_point < start_index then
                        segment_count = segment_count + 1
                        segments[ segment_count ] = string_sub( utf8_string, break_point, start_index - 1 )
                    end

                    segment_count = segment_count + 1
                    segments[ segment_count ] = replacement

                    break_point = start_index + utf8_sequence_length
                end
            end

            start_index = start_index + utf8_sequence_length
        until start_index > end_index

        if segment_count == 0 then
            return utf8_string
        end

        if break_point <= str_length then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_sub( utf8_string, break_point, str_length )
        end

        return table_concat( segments, "", 1, segment_count )
    end

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
    function unicode.upper( utf8_string, start_position, end_position, lax )
        local str_length = string_len( utf8_string )
        if str_length == 0 then
            return utf8_string
        end

        local start_index, end_index = math_range( str_length, start_position, end_position )

        if start_index > end_index then
            return utf8_string
        end

        ---@type string[]
        local segments = {}

        ---@type integer
        local segment_count = 0

        if start_index ~= 1 then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_sub( utf8_string, 1, start_index - 1 )
        end

        ---@type integer
        local break_point = start_index

        repeat
            local utf8_codepoint, utf8_sequence_length = utf8_decode( utf8_string, start_index, end_index, lax )

            if utf8_codepoint ~= nil then
                local replacement = codepoint_to_upper[ utf8_codepoint ]
                if replacement ~= nil then
                    if break_point < start_index then
                        segment_count = segment_count + 1
                        segments[ segment_count ] = string_sub( utf8_string, break_point, start_index - 1 )
                    end

                    segment_count = segment_count + 1
                    segments[ segment_count ] = replacement

                    break_point = start_index + utf8_sequence_length
                end
            end

            start_index = start_index + utf8_sequence_length
        until start_index > end_index

        if segment_count == 0 then
            return utf8_string
        end

        if break_point <= str_length then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_sub( utf8_string, break_point, str_length )
        end

        return table_concat( segments, "", 1, segment_count )
    end

else

    --- Builds an FFI `unicode.lower`/`unicode.upper`, writing straight into a byte buffer
    --- instead of collecting string segments, ~2x faster with JIT.
    ---
    ---@param case_map table<integer, string>
    ---@return fun( utf8_string: string, start_position?: integer, end_position?: integer, lax?: boolean ): string
    local function ffi_case_mapper( case_map )
        local ascii_map = uint8_array_t( 128 )

        for uint8 = 0, 127, 1 do
            local replacement = case_map[ uint8 ]
            if replacement == nil then
                ascii_map[ uint8 ] = uint8
            elseif string_len( replacement ) == 1 then
                ascii_map[ uint8 ] = string_byte( replacement, 1, 1 )
            else
                error( "ascii case mapping must stay ascii" )
            end
        end

        -- worst output/input byte ratio, e.g. 'Ⱥ' (2 bytes) -> 'ⱥ' (3 bytes)
        local max_growth = 1

        for utf8_codepoint, replacement in raw_pairs( case_map ) do
            local growth = string_len( replacement ) / string_len( utf8_encode( utf8_codepoint, true ) )
            if growth > max_growth then
                max_growth = growth
            end
        end

        return function( utf8_string, start_position, end_position, lax )
            local str_length = string_len( utf8_string )
            if str_length == 0 then
                return utf8_string
            end

            local start_index, end_index = math_range( str_length, start_position, end_position )

            if start_index > end_index then
                return utf8_string
            end

            local source = ffi_cast( uint8_ptr_t, utf8_string )
            local buffer = uint8_array_t( math_ceil( str_length * max_growth ) )

            -- 0-based, `index` walks the source, `length` the buffer
            local index = start_index - 1
            local length = index

            ffi_copy( buffer, source, length )

            local changed = false

            while index < end_index do
                local uint8 = source[ index ]
                if uint8 < 0x80 then
                    local mapped = ascii_map[ uint8 ]
                    if mapped ~= uint8 then
                        changed = true
                    end

                    buffer[ length ] = mapped
                    length = length + 1
                    index = index + 1
                else
                    local utf8_codepoint, utf8_sequence_length = utf8_decode( utf8_string, index + 1, end_index, lax )

                    local replacement = utf8_codepoint and case_map[ utf8_codepoint ]
                    if replacement == nil then
                        ffi_copy( buffer + length, source + index, utf8_sequence_length )
                        length = length + utf8_sequence_length
                    else
                        changed = true

                        local replacement_length = string_len( replacement )
                        ffi_copy( buffer + length, replacement, replacement_length )
                        length = length + replacement_length
                    end

                    index = index + utf8_sequence_length
                end
            end

            if changed then
                ffi_copy( buffer + length, source + index, str_length - index )
                return ffi_string( buffer, length + (str_length - index) )
            end

            return utf8_string
        end
    end

    unicode.lower = ffi_case_mapper( codepoint_to_lower )
    unicode.upper = ffi_case_mapper( codepoint_to_upper )

end

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
function unicode.capitalize( utf8_string, start_position, end_position, lax )
    local str_length = string_len( utf8_string )
    if str_length == 0 then
        return utf8_string
    end

    local start_index, end_index = math_range( str_length, start_position, end_position )

    if start_index > end_index then
        return utf8_string
    end

    ---@type string[]
    local segments = {}

    ---@type integer
    local segment_count = 0

    if start_index ~= 1 then
        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( utf8_string, 1, start_index - 1 )
    end

    ---@type integer
    local break_point = start_index
    local first_sequence = false

    repeat
        local utf8_codepoint, utf8_sequence_length = utf8_decode( utf8_string, start_index, end_index, lax )

        if utf8_codepoint ~= nil then
            if first_sequence then
                local lower_sequence = codepoint_to_lower[ utf8_codepoint ]
                if lower_sequence ~= nil then
                    if break_point < start_index then
                        segment_count = segment_count + 1
                        segments[ segment_count ] = string_sub( utf8_string, break_point, start_index - 1 )
                    end

                    segment_count = segment_count + 1
                    segments[ segment_count ] = lower_sequence

                    break_point = start_index + utf8_sequence_length
                end
            else
                if codepoint_to_lower[ utf8_codepoint ] ~= nil then
                    first_sequence = true
                else
                    local upper_sequence = codepoint_to_upper[ utf8_codepoint ]
                    if upper_sequence ~= nil then
                        first_sequence = true

                        if break_point < start_index then
                            segment_count = segment_count + 1
                            segments[ segment_count ] = string_sub( utf8_string, break_point, start_index - 1 )
                        end

                        segment_count = segment_count + 1
                        segments[ segment_count ] = upper_sequence

                        break_point = start_index + utf8_sequence_length
                    end
                end
            end
        end

        start_index = start_index + utf8_sequence_length
    until start_index > end_index

    if segment_count == 0 then
        return utf8_string
    end

    if break_point <= str_length then
        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( utf8_string, break_point, str_length )
    end

    return table_concat( segments, "", 1, segment_count )
end

--- How a code point without case mapping affects word boundaries in `unicode.title`:
--- `true` starts a new word, `false` continues the current one, `nil` keeps the current state.
---
---@type table<integer, boolean>
local word_breaks = {}

do

    -- ascii whitespace, controls and punctuation, except the apostrophe
    for uint8 = 0x00, 0x7F, 1 do
        if ascii_isDigit( uint8 ) then
            word_breaks[ uint8 ] = false
        elseif uint8 ~= 0x27 then
            word_breaks[ uint8 ] = true
        end
    end

    -- no-break space, '¡', '«', '»', '¿'
    word_breaks[ 0xA0 ] = true
    word_breaks[ 0xA1 ] = true
    word_breaks[ 0xAB ] = true
    word_breaks[ 0xBB ] = true
    word_breaks[ 0xBF ] = true

    -- general punctuation (spaces, dashes, quotes), except the typographic apostrophe '’'
    for utf8_codepoint = 0x2000, 0x206F, 1 do
        if utf8_codepoint ~= 0x2019 then
            word_breaks[ utf8_codepoint ] = true
        end
    end

    -- CJK symbols and punctuation
    for utf8_codepoint = 0x3000, 0x303F, 1 do
        word_breaks[ utf8_codepoint ] = true
    end

end

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
function unicode.title( utf8_string, start_position, end_position, lax )
    local str_length = string_len( utf8_string )
    if str_length == 0 then
        return utf8_string
    end

    local start_index, end_index = math_range( str_length, start_position, end_position )

    if start_index > end_index then
        return utf8_string
    end

    ---@type string[]
    local segments = {}

    ---@type integer
    local segment_count = 0

    if start_index ~= 1 then
        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( utf8_string, 1, start_index - 1 )
    end

    ---@type integer
    local break_point = start_index
    local at_word_start = true

    repeat
        local utf8_codepoint, utf8_sequence_length = utf8_decode( utf8_string, start_index, end_index, lax )

        if utf8_codepoint ~= nil then
            local upper_sequence = codepoint_to_upper[ utf8_codepoint ]
            local lower_sequence = codepoint_to_lower[ utf8_codepoint ]

            if upper_sequence == nil and lower_sequence == nil then
                local word_break = word_breaks[ utf8_codepoint ]
                if word_break ~= nil then
                    at_word_start = word_break
                end
            elseif at_word_start then
                at_word_start = false

                if upper_sequence ~= nil then
                    if break_point < start_index then
                        segment_count = segment_count + 1
                        segments[ segment_count ] = string_sub( utf8_string, break_point, start_index - 1 )
                    end

                    segment_count = segment_count + 1
                    segments[ segment_count ] = upper_sequence

                    break_point = start_index + utf8_sequence_length
                end
            elseif lower_sequence ~= nil then
                if break_point < start_index then
                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_sub( utf8_string, break_point, start_index - 1 )
                end

                segment_count = segment_count + 1
                segments[ segment_count ] = lower_sequence

                break_point = start_index + utf8_sequence_length
            end
        end

        start_index = start_index + utf8_sequence_length
    until start_index > end_index

    if segment_count == 0 then
        return utf8_string
    end

    if break_point <= str_length then
        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( utf8_string, break_point, str_length )
    end

    return table_concat( segments, "", 1, segment_count )
end

do

    -- `first, last, width` triplets sorted by `first`, code points outside of them have width `1`
    -- generated from Unicode 16.0.0: `0` for Cc, Mn, Me, Cf and Hangul medial vowels / final consonants,
    -- `2` for East Asian Wide / Fullwidth and Emoji_Presentation
    ---@type integer[]
    local widths = {
        0x0000, 0x001F, 0,
        0x007F, 0x009F, 0,
        0x00AD, 0x00AD, 0,
        0x0300, 0x036F, 0,
        0x0483, 0x0489, 0,
        0x0591, 0x05BD, 0,
        0x05BF, 0x05BF, 0,
        0x05C1, 0x05C2, 0,
        0x05C4, 0x05C5, 0,
        0x05C7, 0x05C7, 0,
        0x0600, 0x0605, 0,
        0x0610, 0x061A, 0,
        0x061C, 0x061C, 0,
        0x064B, 0x065F, 0,
        0x0670, 0x0670, 0,
        0x06D6, 0x06DD, 0,
        0x06DF, 0x06E4, 0,
        0x06E7, 0x06E8, 0,
        0x06EA, 0x06ED, 0,
        0x070F, 0x070F, 0,
        0x0711, 0x0711, 0,
        0x0730, 0x074A, 0,
        0x07A6, 0x07B0, 0,
        0x07EB, 0x07F3, 0,
        0x07FD, 0x07FD, 0,
        0x0816, 0x0819, 0,
        0x081B, 0x0823, 0,
        0x0825, 0x0827, 0,
        0x0829, 0x082D, 0,
        0x0859, 0x085B, 0,
        0x0890, 0x0891, 0,
        0x0897, 0x089F, 0,
        0x08CA, 0x0902, 0,
        0x093A, 0x093A, 0,
        0x093C, 0x093C, 0,
        0x0941, 0x0948, 0,
        0x094D, 0x094D, 0,
        0x0951, 0x0957, 0,
        0x0962, 0x0963, 0,
        0x0981, 0x0981, 0,
        0x09BC, 0x09BC, 0,
        0x09C1, 0x09C4, 0,
        0x09CD, 0x09CD, 0,
        0x09E2, 0x09E3, 0,
        0x09FE, 0x09FE, 0,
        0x0A01, 0x0A02, 0,
        0x0A3C, 0x0A3C, 0,
        0x0A41, 0x0A42, 0,
        0x0A47, 0x0A48, 0,
        0x0A4B, 0x0A4D, 0,
        0x0A51, 0x0A51, 0,
        0x0A70, 0x0A71, 0,
        0x0A75, 0x0A75, 0,
        0x0A81, 0x0A82, 0,
        0x0ABC, 0x0ABC, 0,
        0x0AC1, 0x0AC5, 0,
        0x0AC7, 0x0AC8, 0,
        0x0ACD, 0x0ACD, 0,
        0x0AE2, 0x0AE3, 0,
        0x0AFA, 0x0AFF, 0,
        0x0B01, 0x0B01, 0,
        0x0B3C, 0x0B3C, 0,
        0x0B3F, 0x0B3F, 0,
        0x0B41, 0x0B44, 0,
        0x0B4D, 0x0B4D, 0,
        0x0B55, 0x0B56, 0,
        0x0B62, 0x0B63, 0,
        0x0B82, 0x0B82, 0,
        0x0BC0, 0x0BC0, 0,
        0x0BCD, 0x0BCD, 0,
        0x0C00, 0x0C00, 0,
        0x0C04, 0x0C04, 0,
        0x0C3C, 0x0C3C, 0,
        0x0C3E, 0x0C40, 0,
        0x0C46, 0x0C48, 0,
        0x0C4A, 0x0C4D, 0,
        0x0C55, 0x0C56, 0,
        0x0C62, 0x0C63, 0,
        0x0C81, 0x0C81, 0,
        0x0CBC, 0x0CBC, 0,
        0x0CBF, 0x0CBF, 0,
        0x0CC6, 0x0CC6, 0,
        0x0CCC, 0x0CCD, 0,
        0x0CE2, 0x0CE3, 0,
        0x0D00, 0x0D01, 0,
        0x0D3B, 0x0D3C, 0,
        0x0D41, 0x0D44, 0,
        0x0D4D, 0x0D4D, 0,
        0x0D62, 0x0D63, 0,
        0x0D81, 0x0D81, 0,
        0x0DCA, 0x0DCA, 0,
        0x0DD2, 0x0DD4, 0,
        0x0DD6, 0x0DD6, 0,
        0x0E31, 0x0E31, 0,
        0x0E34, 0x0E3A, 0,
        0x0E47, 0x0E4E, 0,
        0x0EB1, 0x0EB1, 0,
        0x0EB4, 0x0EBC, 0,
        0x0EC8, 0x0ECE, 0,
        0x0F18, 0x0F19, 0,
        0x0F35, 0x0F35, 0,
        0x0F37, 0x0F37, 0,
        0x0F39, 0x0F39, 0,
        0x0F71, 0x0F7E, 0,
        0x0F80, 0x0F84, 0,
        0x0F86, 0x0F87, 0,
        0x0F8D, 0x0F97, 0,
        0x0F99, 0x0FBC, 0,
        0x0FC6, 0x0FC6, 0,
        0x102D, 0x1030, 0,
        0x1032, 0x1037, 0,
        0x1039, 0x103A, 0,
        0x103D, 0x103E, 0,
        0x1058, 0x1059, 0,
        0x105E, 0x1060, 0,
        0x1071, 0x1074, 0,
        0x1082, 0x1082, 0,
        0x1085, 0x1086, 0,
        0x108D, 0x108D, 0,
        0x109D, 0x109D, 0,
        0x1100, 0x115F, 2,
        0x1160, 0x11FF, 0,
        0x135D, 0x135F, 0,
        0x1712, 0x1714, 0,
        0x1732, 0x1733, 0,
        0x1752, 0x1753, 0,
        0x1772, 0x1773, 0,
        0x17B4, 0x17B5, 0,
        0x17B7, 0x17BD, 0,
        0x17C6, 0x17C6, 0,
        0x17C9, 0x17D3, 0,
        0x17DD, 0x17DD, 0,
        0x180B, 0x180F, 0,
        0x1885, 0x1886, 0,
        0x18A9, 0x18A9, 0,
        0x1920, 0x1922, 0,
        0x1927, 0x1928, 0,
        0x1932, 0x1932, 0,
        0x1939, 0x193B, 0,
        0x1A17, 0x1A18, 0,
        0x1A1B, 0x1A1B, 0,
        0x1A56, 0x1A56, 0,
        0x1A58, 0x1A5E, 0,
        0x1A60, 0x1A60, 0,
        0x1A62, 0x1A62, 0,
        0x1A65, 0x1A6C, 0,
        0x1A73, 0x1A7C, 0,
        0x1A7F, 0x1A7F, 0,
        0x1AB0, 0x1ACE, 0,
        0x1B00, 0x1B03, 0,
        0x1B34, 0x1B34, 0,
        0x1B36, 0x1B3A, 0,
        0x1B3C, 0x1B3C, 0,
        0x1B42, 0x1B42, 0,
        0x1B6B, 0x1B73, 0,
        0x1B80, 0x1B81, 0,
        0x1BA2, 0x1BA5, 0,
        0x1BA8, 0x1BA9, 0,
        0x1BAB, 0x1BAD, 0,
        0x1BE6, 0x1BE6, 0,
        0x1BE8, 0x1BE9, 0,
        0x1BED, 0x1BED, 0,
        0x1BEF, 0x1BF1, 0,
        0x1C2C, 0x1C33, 0,
        0x1C36, 0x1C37, 0,
        0x1CD0, 0x1CD2, 0,
        0x1CD4, 0x1CE0, 0,
        0x1CE2, 0x1CE8, 0,
        0x1CED, 0x1CED, 0,
        0x1CF4, 0x1CF4, 0,
        0x1CF8, 0x1CF9, 0,
        0x1DC0, 0x1DFF, 0,
        0x200B, 0x200F, 0,
        0x202A, 0x202E, 0,
        0x2060, 0x2064, 0,
        0x2066, 0x206F, 0,
        0x20D0, 0x20F0, 0,
        0x231A, 0x231B, 2,
        0x2329, 0x232A, 2,
        0x23E9, 0x23EC, 2,
        0x23F0, 0x23F0, 2,
        0x23F3, 0x23F3, 2,
        0x25FD, 0x25FE, 2,
        0x2614, 0x2615, 2,
        0x2630, 0x2637, 2,
        0x2648, 0x2653, 2,
        0x267F, 0x267F, 2,
        0x268A, 0x268F, 2,
        0x2693, 0x2693, 2,
        0x26A1, 0x26A1, 2,
        0x26AA, 0x26AB, 2,
        0x26BD, 0x26BE, 2,
        0x26C4, 0x26C5, 2,
        0x26CE, 0x26CE, 2,
        0x26D4, 0x26D4, 2,
        0x26EA, 0x26EA, 2,
        0x26F2, 0x26F3, 2,
        0x26F5, 0x26F5, 2,
        0x26FA, 0x26FA, 2,
        0x26FD, 0x26FD, 2,
        0x2705, 0x2705, 2,
        0x270A, 0x270B, 2,
        0x2728, 0x2728, 2,
        0x274C, 0x274C, 2,
        0x274E, 0x274E, 2,
        0x2753, 0x2755, 2,
        0x2757, 0x2757, 2,
        0x2795, 0x2797, 2,
        0x27B0, 0x27B0, 2,
        0x27BF, 0x27BF, 2,
        0x2B1B, 0x2B1C, 2,
        0x2B50, 0x2B50, 2,
        0x2B55, 0x2B55, 2,
        0x2CEF, 0x2CF1, 0,
        0x2D7F, 0x2D7F, 0,
        0x2DE0, 0x2DFF, 0,
        0x2E80, 0x2E99, 2,
        0x2E9B, 0x2EF3, 2,
        0x2F00, 0x2FD5, 2,
        0x2FF0, 0x3029, 2,
        0x302A, 0x302D, 0,
        0x302E, 0x303E, 2,
        0x3041, 0x3096, 2,
        0x3099, 0x309A, 0,
        0x309B, 0x30FF, 2,
        0x3105, 0x312F, 2,
        0x3131, 0x318E, 2,
        0x3190, 0x31E5, 2,
        0x31EF, 0x321E, 2,
        0x3220, 0x3247, 2,
        0x3250, 0xA48C, 2,
        0xA490, 0xA4C6, 2,
        0xA66F, 0xA672, 0,
        0xA674, 0xA67D, 0,
        0xA69E, 0xA69F, 0,
        0xA6F0, 0xA6F1, 0,
        0xA802, 0xA802, 0,
        0xA806, 0xA806, 0,
        0xA80B, 0xA80B, 0,
        0xA825, 0xA826, 0,
        0xA82C, 0xA82C, 0,
        0xA8C4, 0xA8C5, 0,
        0xA8E0, 0xA8F1, 0,
        0xA8FF, 0xA8FF, 0,
        0xA926, 0xA92D, 0,
        0xA947, 0xA951, 0,
        0xA960, 0xA97C, 2,
        0xA980, 0xA982, 0,
        0xA9B3, 0xA9B3, 0,
        0xA9B6, 0xA9B9, 0,
        0xA9BC, 0xA9BD, 0,
        0xA9E5, 0xA9E5, 0,
        0xAA29, 0xAA2E, 0,
        0xAA31, 0xAA32, 0,
        0xAA35, 0xAA36, 0,
        0xAA43, 0xAA43, 0,
        0xAA4C, 0xAA4C, 0,
        0xAA7C, 0xAA7C, 0,
        0xAAB0, 0xAAB0, 0,
        0xAAB2, 0xAAB4, 0,
        0xAAB7, 0xAAB8, 0,
        0xAABE, 0xAABF, 0,
        0xAAC1, 0xAAC1, 0,
        0xAAEC, 0xAAED, 0,
        0xAAF6, 0xAAF6, 0,
        0xABE5, 0xABE5, 0,
        0xABE8, 0xABE8, 0,
        0xABED, 0xABED, 0,
        0xAC00, 0xD7A3, 2,
        0xD7B0, 0xD7FF, 0,
        0xF900, 0xFAFF, 2,
        0xFB1E, 0xFB1E, 0,
        0xFE00, 0xFE0F, 0,
        0xFE10, 0xFE19, 2,
        0xFE20, 0xFE2F, 0,
        0xFE30, 0xFE52, 2,
        0xFE54, 0xFE66, 2,
        0xFE68, 0xFE6B, 2,
        0xFEFF, 0xFEFF, 0,
        0xFF01, 0xFF60, 2,
        0xFFE0, 0xFFE6, 2,
        0xFFF9, 0xFFFB, 0,
        0x101FD, 0x101FD, 0,
        0x102E0, 0x102E0, 0,
        0x10376, 0x1037A, 0,
        0x10A01, 0x10A03, 0,
        0x10A05, 0x10A06, 0,
        0x10A0C, 0x10A0F, 0,
        0x10A38, 0x10A3A, 0,
        0x10A3F, 0x10A3F, 0,
        0x10AE5, 0x10AE6, 0,
        0x10D24, 0x10D27, 0,
        0x10D69, 0x10D6D, 0,
        0x10EAB, 0x10EAC, 0,
        0x10EFC, 0x10EFF, 0,
        0x10F46, 0x10F50, 0,
        0x10F82, 0x10F85, 0,
        0x11001, 0x11001, 0,
        0x11038, 0x11046, 0,
        0x11070, 0x11070, 0,
        0x11073, 0x11074, 0,
        0x1107F, 0x11081, 0,
        0x110B3, 0x110B6, 0,
        0x110B9, 0x110BA, 0,
        0x110BD, 0x110BD, 0,
        0x110C2, 0x110C2, 0,
        0x110CD, 0x110CD, 0,
        0x11100, 0x11102, 0,
        0x11127, 0x1112B, 0,
        0x1112D, 0x11134, 0,
        0x11173, 0x11173, 0,
        0x11180, 0x11181, 0,
        0x111B6, 0x111BE, 0,
        0x111C9, 0x111CC, 0,
        0x111CF, 0x111CF, 0,
        0x1122F, 0x11231, 0,
        0x11234, 0x11234, 0,
        0x11236, 0x11237, 0,
        0x1123E, 0x1123E, 0,
        0x11241, 0x11241, 0,
        0x112DF, 0x112DF, 0,
        0x112E3, 0x112EA, 0,
        0x11300, 0x11301, 0,
        0x1133B, 0x1133C, 0,
        0x11340, 0x11340, 0,
        0x11366, 0x1136C, 0,
        0x11370, 0x11374, 0,
        0x113BB, 0x113C0, 0,
        0x113CE, 0x113CE, 0,
        0x113D0, 0x113D0, 0,
        0x113D2, 0x113D2, 0,
        0x113E1, 0x113E2, 0,
        0x11438, 0x1143F, 0,
        0x11442, 0x11444, 0,
        0x11446, 0x11446, 0,
        0x1145E, 0x1145E, 0,
        0x114B3, 0x114B8, 0,
        0x114BA, 0x114BA, 0,
        0x114BF, 0x114C0, 0,
        0x114C2, 0x114C3, 0,
        0x115B2, 0x115B5, 0,
        0x115BC, 0x115BD, 0,
        0x115BF, 0x115C0, 0,
        0x115DC, 0x115DD, 0,
        0x11633, 0x1163A, 0,
        0x1163D, 0x1163D, 0,
        0x1163F, 0x11640, 0,
        0x116AB, 0x116AB, 0,
        0x116AD, 0x116AD, 0,
        0x116B0, 0x116B5, 0,
        0x116B7, 0x116B7, 0,
        0x1171D, 0x1171D, 0,
        0x1171F, 0x1171F, 0,
        0x11722, 0x11725, 0,
        0x11727, 0x1172B, 0,
        0x1182F, 0x11837, 0,
        0x11839, 0x1183A, 0,
        0x1193B, 0x1193C, 0,
        0x1193E, 0x1193E, 0,
        0x11943, 0x11943, 0,
        0x119D4, 0x119D7, 0,
        0x119DA, 0x119DB, 0,
        0x119E0, 0x119E0, 0,
        0x11A01, 0x11A0A, 0,
        0x11A33, 0x11A38, 0,
        0x11A3B, 0x11A3E, 0,
        0x11A47, 0x11A47, 0,
        0x11A51, 0x11A56, 0,
        0x11A59, 0x11A5B, 0,
        0x11A8A, 0x11A96, 0,
        0x11A98, 0x11A99, 0,
        0x11C30, 0x11C36, 0,
        0x11C38, 0x11C3D, 0,
        0x11C3F, 0x11C3F, 0,
        0x11C92, 0x11CA7, 0,
        0x11CAA, 0x11CB0, 0,
        0x11CB2, 0x11CB3, 0,
        0x11CB5, 0x11CB6, 0,
        0x11D31, 0x11D36, 0,
        0x11D3A, 0x11D3A, 0,
        0x11D3C, 0x11D3D, 0,
        0x11D3F, 0x11D45, 0,
        0x11D47, 0x11D47, 0,
        0x11D90, 0x11D91, 0,
        0x11D95, 0x11D95, 0,
        0x11D97, 0x11D97, 0,
        0x11EF3, 0x11EF4, 0,
        0x11F00, 0x11F01, 0,
        0x11F36, 0x11F3A, 0,
        0x11F40, 0x11F40, 0,
        0x11F42, 0x11F42, 0,
        0x11F5A, 0x11F5A, 0,
        0x13430, 0x13440, 0,
        0x13447, 0x13455, 0,
        0x1611E, 0x16129, 0,
        0x1612D, 0x1612F, 0,
        0x16AF0, 0x16AF4, 0,
        0x16B30, 0x16B36, 0,
        0x16F4F, 0x16F4F, 0,
        0x16F8F, 0x16F92, 0,
        0x16FE0, 0x16FE3, 2,
        0x16FE4, 0x16FE4, 0,
        0x16FF0, 0x16FF1, 2,
        0x17000, 0x187F7, 2,
        0x18800, 0x18CD5, 2,
        0x18CFF, 0x18D08, 2,
        0x1AFF0, 0x1AFF3, 2,
        0x1AFF5, 0x1AFFB, 2,
        0x1AFFD, 0x1AFFE, 2,
        0x1B000, 0x1B122, 2,
        0x1B132, 0x1B132, 2,
        0x1B150, 0x1B152, 2,
        0x1B155, 0x1B155, 2,
        0x1B164, 0x1B167, 2,
        0x1B170, 0x1B2FB, 2,
        0x1BC9D, 0x1BC9E, 0,
        0x1BCA0, 0x1BCA3, 0,
        0x1CF00, 0x1CF2D, 0,
        0x1CF30, 0x1CF46, 0,
        0x1D167, 0x1D169, 0,
        0x1D173, 0x1D182, 0,
        0x1D185, 0x1D18B, 0,
        0x1D1AA, 0x1D1AD, 0,
        0x1D242, 0x1D244, 0,
        0x1D300, 0x1D356, 2,
        0x1D360, 0x1D376, 2,
        0x1DA00, 0x1DA36, 0,
        0x1DA3B, 0x1DA6C, 0,
        0x1DA75, 0x1DA75, 0,
        0x1DA84, 0x1DA84, 0,
        0x1DA9B, 0x1DA9F, 0,
        0x1DAA1, 0x1DAAF, 0,
        0x1E000, 0x1E006, 0,
        0x1E008, 0x1E018, 0,
        0x1E01B, 0x1E021, 0,
        0x1E023, 0x1E024, 0,
        0x1E026, 0x1E02A, 0,
        0x1E08F, 0x1E08F, 0,
        0x1E130, 0x1E136, 0,
        0x1E2AE, 0x1E2AE, 0,
        0x1E2EC, 0x1E2EF, 0,
        0x1E4EC, 0x1E4EF, 0,
        0x1E5EE, 0x1E5EF, 0,
        0x1E8D0, 0x1E8D6, 0,
        0x1E944, 0x1E94A, 0,
        0x1F004, 0x1F004, 2,
        0x1F0CF, 0x1F0CF, 2,
        0x1F18E, 0x1F18E, 2,
        0x1F191, 0x1F19A, 2,
        0x1F1E6, 0x1F202, 2,
        0x1F210, 0x1F23B, 2,
        0x1F240, 0x1F248, 2,
        0x1F250, 0x1F251, 2,
        0x1F260, 0x1F265, 2,
        0x1F300, 0x1F320, 2,
        0x1F32D, 0x1F335, 2,
        0x1F337, 0x1F37C, 2,
        0x1F37E, 0x1F393, 2,
        0x1F3A0, 0x1F3CA, 2,
        0x1F3CF, 0x1F3D3, 2,
        0x1F3E0, 0x1F3F0, 2,
        0x1F3F4, 0x1F3F4, 2,
        0x1F3F8, 0x1F43E, 2,
        0x1F440, 0x1F440, 2,
        0x1F442, 0x1F4FC, 2,
        0x1F4FF, 0x1F53D, 2,
        0x1F54B, 0x1F54E, 2,
        0x1F550, 0x1F567, 2,
        0x1F57A, 0x1F57A, 2,
        0x1F595, 0x1F596, 2,
        0x1F5A4, 0x1F5A4, 2,
        0x1F5FB, 0x1F64F, 2,
        0x1F680, 0x1F6C5, 2,
        0x1F6CC, 0x1F6CC, 2,
        0x1F6D0, 0x1F6D2, 2,
        0x1F6D5, 0x1F6D7, 2,
        0x1F6DC, 0x1F6DF, 2,
        0x1F6EB, 0x1F6EC, 2,
        0x1F6F4, 0x1F6FC, 2,
        0x1F7E0, 0x1F7EB, 2,
        0x1F7F0, 0x1F7F0, 2,
        0x1F90C, 0x1F93A, 2,
        0x1F93C, 0x1F945, 2,
        0x1F947, 0x1F9FF, 2,
        0x1FA70, 0x1FA7C, 2,
        0x1FA80, 0x1FA89, 2,
        0x1FA8F, 0x1FAC6, 2,
        0x1FACE, 0x1FADC, 2,
        0x1FADF, 0x1FAE9, 2,
        0x1FAF0, 0x1FAF8, 2,
        0x20000, 0x2FFFD, 2,
        0x30000, 0x3FFFD, 2,
        0xE0001, 0xE0001, 0,
        0xE0020, 0xE007F, 0,
        0xE0100, 0xE01EF, 0,
    }

    local width_count = #widths / 3

    ---@param utf8_codepoint integer
    ---@return integer width
    local function search( utf8_codepoint )
        local low, high = 1, width_count

        while low <= high do
            local middle = rbit_rshift( low + high, 1 )
            local index = middle * 3 - 2

            if utf8_codepoint < widths[ index ] then
                high = middle - 1
            elseif utf8_codepoint > widths[ index + 1 ] then
                low = middle + 1
            else
                return widths[ index + 2 ]
            end
        end

        return 1
    end

    -- widths of U+0000 - U+1FFF (latin, greek, cyrillic, arabic, indic, ...), one byte per code point
    local dense_widths
    do

        ---@type string[]
        local bytes = {}

        for utf8_codepoint = 0x0000, 0x1FFF, 1 do
            bytes[ utf8_codepoint + 1 ] = string_char( search( utf8_codepoint ) )
        end

        dense_widths = table_concat( bytes, "", 1, 0x2000 )

    end

    ---@param utf8_codepoint integer
    ---@return integer width
    local function lookup( utf8_codepoint )
        if utf8_codepoint < 0x2000 then
            return string_byte( dense_widths, utf8_codepoint + 1, utf8_codepoint + 1 )
        elseif (utf8_codepoint >= 0x3250 and utf8_codepoint <= 0xA48C) or (utf8_codepoint >= 0xAC00 and utf8_codepoint <= 0xD7A3) then
            -- CJK and hangul syllables, both are single wide ranges of `widths`
            return 2
        end

        return search( utf8_codepoint )
    end

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
    function unicode.width( utf8_codepoint )
        if not is_codepoint( utf8_codepoint ) then
            error( string_format( "invalid unicode code point '%s'", utf8_codepoint ), 2 )
        end

        return lookup( utf8_codepoint )
    end

    --- Returns how many columns `utf8_codepoint` adds to the line, given the previous code point.
    ---
    --- `cluster_width` is the width of the cluster the previous code point belongs to,
    --- `regional_open` is `true` when the previous code point is the first half of a flag.
    ---
    --- Emoji ZWJ sequences, skin tone modifiers and flags count as a single wide character,
    --- `U+FE0F` turns a preceding narrow character into a wide emoji.
    ---
    ---@param utf8_codepoint integer
    ---@param previous_codepoint integer | nil
    ---@param cluster_width integer
    ---@param regional_open boolean
    ---@return integer advance
    ---@return integer cluster_width
    ---@return boolean regional_open
    local function advance( utf8_codepoint, previous_codepoint, cluster_width, regional_open )
        if utf8_codepoint < 0x7F then
            if utf8_codepoint < 0x20 then
                return 0, 0, false
            end

            return 1, 1, false
        elseif utf8_codepoint >= 0x1F1E6 and utf8_codepoint <= 0x1F1FF then
            -- regional indicators pair up into flags
            if regional_open then
                return 0, 2, false
            end

            return 2, 2, true
        elseif cluster_width == 2 and (previous_codepoint == 0x200D or (utf8_codepoint >= 0x1F3FB and utf8_codepoint <= 0x1F3FF)) then
            -- joined by ZWJ or a skin tone modifier
            return 0, 2, false
        elseif utf8_codepoint == 0xFE0F then
            -- emoji presentation selector
            if cluster_width == 1 then
                return 1, 2, false
            end

            return 0, cluster_width, false
        end

        local width = lookup( utf8_codepoint )
        if width == 0 then
            -- extends the current cluster, but controls break it
            if utf8_codepoint < 0xA0 then
                return 0, 0, false
            end

            return 0, cluster_width, false
        end

        return width, width, false
    end

    ---@param utf8_string string
    ---@param start_index integer
    ---@param end_index integer
    ---@param lax boolean | nil
    ---@return integer width
    local function measure( utf8_string, start_index, end_index, lax )
        local width, cluster_width, regional_open = 0, 0, false
        local previous_codepoint = nil

        while start_index <= end_index do
            local uint8 = string_byte( utf8_string, start_index, start_index )
            if uint8 > 0x1F and uint8 < 0x7F then
                -- printable ascii, always a new narrow cluster
                width, cluster_width, regional_open = width + 1, 1, false
                previous_codepoint = uint8
                start_index = start_index + 1
            else
                local utf8_codepoint, utf8_sequence_length = utf8_decode( utf8_string, start_index, end_index, lax )
                if utf8_codepoint == nil then
                    utf8_codepoint = 0xFFFD
                end

                local codepoint_width
                codepoint_width, cluster_width, regional_open = advance( utf8_codepoint, previous_codepoint, cluster_width, regional_open )

                width = width + codepoint_width
                previous_codepoint = utf8_codepoint

                start_index = start_index + utf8_sequence_length
            end
        end

        return width
    end

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
    function unicode.displayWidth( utf8_string, start_position, end_position, lax )
        local str_length = string_len( utf8_string )
        if str_length == 0 then
            return 0
        end

        local start_index, end_index = math_range( str_length, start_position, end_position )
        return measure( utf8_string, start_index, end_index, lax )
    end

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
    function unicode.wrap( utf8_string, max_width, start_position, end_position, lax )
        if max_width <= 0 then
            return utf8_string
        end

        local str_length = string_len( utf8_string )
        if str_length == 0 then
            return utf8_string
        end

        local start_index, end_index = math_range( str_length, start_position, end_position )

        ---@type string[]
        local lines = {}

        ---@type integer
        local line_count = 0

        -- bytes before `start_position` stay glued to the first line
        local line_start = 1
        local line_width = 0

        ---@type integer | nil
        local last_space_index = nil
        local last_space_line_width = 0

        local cluster_width, regional_open = 0, false
        local previous_codepoint = nil

        while start_index <= end_index do
            ---@type integer | nil
            local utf8_codepoint, utf8_sequence_length = string_byte( utf8_string, start_index, start_index ), 1
            if utf8_codepoint > 0x7F then
                utf8_codepoint, utf8_sequence_length = utf8_decode( utf8_string, start_index, end_index, lax )
                if utf8_codepoint == nil then
                    utf8_codepoint = 0xFFFD
                end
            end

            ---@cast utf8_codepoint integer

            if utf8_codepoint == 0x0A then
                -- existing line break, the line starts over
                line_width, last_space_index = 0, nil
                cluster_width, regional_open = 0, false
            else
                local codepoint_width
                codepoint_width, cluster_width, regional_open = advance( utf8_codepoint, previous_codepoint, cluster_width, regional_open )

                if codepoint_width ~= 0 and line_width ~= 0 and line_width + codepoint_width > max_width then
                    -- the current code point doesn't fit, it goes to the next line
                    if utf8_codepoint == 0x20 then
                        -- break right here, dropping the space itself
                        line_count = line_count + 1
                        lines[ line_count ] = string_sub( utf8_string, line_start, start_index - 1 )

                        line_start, line_width, last_space_index = start_index + 1, 0, nil
                        codepoint_width = 0
                    else
                        if last_space_index ~= nil then
                            -- break at the last space, dropping the space itself
                            line_count = line_count + 1
                            lines[ line_count ] = string_sub( utf8_string, line_start, last_space_index - 1 )

                            line_start, line_width, last_space_index = last_space_index + 1, line_width - last_space_line_width - 1, nil
                        end

                        if line_width ~= 0 and line_width + codepoint_width > max_width then
                            -- no space to break on or the rest still doesn't fit: hard-split before the current code point
                            line_count = line_count + 1
                            lines[ line_count ] = string_sub( utf8_string, line_start, start_index - 1 )

                            line_start, line_width = start_index, 0
                        end
                    end
                elseif utf8_codepoint == 0x20 then
                    -- track break opportunities (ascii space only)
                    last_space_index, last_space_line_width = start_index, line_width
                end

                line_width = line_width + codepoint_width
            end

            previous_codepoint = utf8_codepoint
            start_index = start_index + utf8_sequence_length
        end

        if line_count == 0 then
            return utf8_string
        end

        -- nothing left when the very last break dropped a trailing space
        if line_start <= str_length then
            line_count = line_count + 1
            lines[ line_count ] = string_sub( utf8_string, line_start, str_length )
        end

        return table_concat( lines, "\n", 1, line_count )
    end

    --- Repeats `padding` up to exactly `width` columns, a wide character that doesn't
    --- fit into the remainder is replaced with spaces.
    ---
    ---@param padding string
    ---@param padding_width integer The width of `padding` in columns.
    ---@param width integer
    ---@return string
    local function fill( padding, padding_width, width )
        local repetitions = math_floor( width / padding_width )
        local remainder = width - repetitions * padding_width

        if remainder == 0 then
            return string_rep( padding, repetitions )
        end

        -- the longest prefix of `padding` that fits into `remainder`
        local padding_length = string_len( padding )
        local index, prefix_width = 1, 0

        local cluster_width, regional_open = 0, false
        local previous_codepoint = nil

        while index <= padding_length do
            local utf8_codepoint, utf8_sequence_length = utf8_decode( padding, index, padding_length, true )
            if utf8_codepoint == nil then
                utf8_codepoint = 0xFFFD
            end

            local codepoint_width
            codepoint_width, cluster_width, regional_open = advance( utf8_codepoint, previous_codepoint, cluster_width, regional_open )

            if prefix_width + codepoint_width > remainder then
                break
            end

            prefix_width = prefix_width + codepoint_width
            previous_codepoint = utf8_codepoint
            index = index + utf8_sequence_length
        end

        return string_rep( padding, repetitions ) .. string_sub( padding, 1, index - 1 ) .. string_rep( " ", remainder - prefix_width )
    end

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
    function unicode.pad( utf8_string, desired_width, padding, left, right, lax )
        if not (left or right) then
            return utf8_string
        end

        local padding_width = 1

        if padding == nil then
            padding = " "
        else
            padding_width = measure( padding, 1, string_len( padding ), lax )
            if padding_width == 0 then
                return utf8_string
            end
        end

        local missing_width = desired_width - measure( utf8_string, 1, string_len( utf8_string ), lax )
        if missing_width <= 0 then
            return utf8_string
        end

        if left and right then
            local left_width = math_floor( missing_width * 0.5 )
            return fill( padding, padding_width, left_width ) .. utf8_string .. fill( padding, padding_width, missing_width - left_width )
        elseif left then
            return fill( padding, padding_width, missing_width ) .. utf8_string
        end

        return utf8_string .. fill( padding, padding_width, missing_width )
    end

end

do

    -- `first, last, name` triplets sorted by `first`, generated from Unicode 16.0.0 `Blocks.txt`
    ---@type (integer | string)[]
    local blocks = {
        0x0000, 0x007F, "Basic Latin",
        0x0080, 0x00FF, "Latin-1 Supplement",
        0x0100, 0x017F, "Latin Extended-A",
        0x0180, 0x024F, "Latin Extended-B",
        0x0250, 0x02AF, "IPA Extensions",
        0x02B0, 0x02FF, "Spacing Modifier Letters",
        0x0300, 0x036F, "Combining Diacritical Marks",
        0x0370, 0x03FF, "Greek and Coptic",
        0x0400, 0x04FF, "Cyrillic",
        0x0500, 0x052F, "Cyrillic Supplement",
        0x0530, 0x058F, "Armenian",
        0x0590, 0x05FF, "Hebrew",
        0x0600, 0x06FF, "Arabic",
        0x0700, 0x074F, "Syriac",
        0x0750, 0x077F, "Arabic Supplement",
        0x0780, 0x07BF, "Thaana",
        0x07C0, 0x07FF, "NKo",
        0x0800, 0x083F, "Samaritan",
        0x0840, 0x085F, "Mandaic",
        0x0860, 0x086F, "Syriac Supplement",
        0x0870, 0x089F, "Arabic Extended-B",
        0x08A0, 0x08FF, "Arabic Extended-A",
        0x0900, 0x097F, "Devanagari",
        0x0980, 0x09FF, "Bengali",
        0x0A00, 0x0A7F, "Gurmukhi",
        0x0A80, 0x0AFF, "Gujarati",
        0x0B00, 0x0B7F, "Oriya",
        0x0B80, 0x0BFF, "Tamil",
        0x0C00, 0x0C7F, "Telugu",
        0x0C80, 0x0CFF, "Kannada",
        0x0D00, 0x0D7F, "Malayalam",
        0x0D80, 0x0DFF, "Sinhala",
        0x0E00, 0x0E7F, "Thai",
        0x0E80, 0x0EFF, "Lao",
        0x0F00, 0x0FFF, "Tibetan",
        0x1000, 0x109F, "Myanmar",
        0x10A0, 0x10FF, "Georgian",
        0x1100, 0x11FF, "Hangul Jamo",
        0x1200, 0x137F, "Ethiopic",
        0x1380, 0x139F, "Ethiopic Supplement",
        0x13A0, 0x13FF, "Cherokee",
        0x1400, 0x167F, "Unified Canadian Aboriginal Syllabics",
        0x1680, 0x169F, "Ogham",
        0x16A0, 0x16FF, "Runic",
        0x1700, 0x171F, "Tagalog",
        0x1720, 0x173F, "Hanunoo",
        0x1740, 0x175F, "Buhid",
        0x1760, 0x177F, "Tagbanwa",
        0x1780, 0x17FF, "Khmer",
        0x1800, 0x18AF, "Mongolian",
        0x18B0, 0x18FF, "Unified Canadian Aboriginal Syllabics Extended",
        0x1900, 0x194F, "Limbu",
        0x1950, 0x197F, "Tai Le",
        0x1980, 0x19DF, "New Tai Lue",
        0x19E0, 0x19FF, "Khmer Symbols",
        0x1A00, 0x1A1F, "Buginese",
        0x1A20, 0x1AAF, "Tai Tham",
        0x1AB0, 0x1AFF, "Combining Diacritical Marks Extended",
        0x1B00, 0x1B7F, "Balinese",
        0x1B80, 0x1BBF, "Sundanese",
        0x1BC0, 0x1BFF, "Batak",
        0x1C00, 0x1C4F, "Lepcha",
        0x1C50, 0x1C7F, "Ol Chiki",
        0x1C80, 0x1C8F, "Cyrillic Extended-C",
        0x1C90, 0x1CBF, "Georgian Extended",
        0x1CC0, 0x1CCF, "Sundanese Supplement",
        0x1CD0, 0x1CFF, "Vedic Extensions",
        0x1D00, 0x1D7F, "Phonetic Extensions",
        0x1D80, 0x1DBF, "Phonetic Extensions Supplement",
        0x1DC0, 0x1DFF, "Combining Diacritical Marks Supplement",
        0x1E00, 0x1EFF, "Latin Extended Additional",
        0x1F00, 0x1FFF, "Greek Extended",
        0x2000, 0x206F, "General Punctuation",
        0x2070, 0x209F, "Superscripts and Subscripts",
        0x20A0, 0x20CF, "Currency Symbols",
        0x20D0, 0x20FF, "Combining Diacritical Marks for Symbols",
        0x2100, 0x214F, "Letterlike Symbols",
        0x2150, 0x218F, "Number Forms",
        0x2190, 0x21FF, "Arrows",
        0x2200, 0x22FF, "Mathematical Operators",
        0x2300, 0x23FF, "Miscellaneous Technical",
        0x2400, 0x243F, "Control Pictures",
        0x2440, 0x245F, "Optical Character Recognition",
        0x2460, 0x24FF, "Enclosed Alphanumerics",
        0x2500, 0x257F, "Box Drawing",
        0x2580, 0x259F, "Block Elements",
        0x25A0, 0x25FF, "Geometric Shapes",
        0x2600, 0x26FF, "Miscellaneous Symbols",
        0x2700, 0x27BF, "Dingbats",
        0x27C0, 0x27EF, "Miscellaneous Mathematical Symbols-A",
        0x27F0, 0x27FF, "Supplemental Arrows-A",
        0x2800, 0x28FF, "Braille Patterns",
        0x2900, 0x297F, "Supplemental Arrows-B",
        0x2980, 0x29FF, "Miscellaneous Mathematical Symbols-B",
        0x2A00, 0x2AFF, "Supplemental Mathematical Operators",
        0x2B00, 0x2BFF, "Miscellaneous Symbols and Arrows",
        0x2C00, 0x2C5F, "Glagolitic",
        0x2C60, 0x2C7F, "Latin Extended-C",
        0x2C80, 0x2CFF, "Coptic",
        0x2D00, 0x2D2F, "Georgian Supplement",
        0x2D30, 0x2D7F, "Tifinagh",
        0x2D80, 0x2DDF, "Ethiopic Extended",
        0x2DE0, 0x2DFF, "Cyrillic Extended-A",
        0x2E00, 0x2E7F, "Supplemental Punctuation",
        0x2E80, 0x2EFF, "CJK Radicals Supplement",
        0x2F00, 0x2FDF, "Kangxi Radicals",
        0x2FF0, 0x2FFF, "Ideographic Description Characters",
        0x3000, 0x303F, "CJK Symbols and Punctuation",
        0x3040, 0x309F, "Hiragana",
        0x30A0, 0x30FF, "Katakana",
        0x3100, 0x312F, "Bopomofo",
        0x3130, 0x318F, "Hangul Compatibility Jamo",
        0x3190, 0x319F, "Kanbun",
        0x31A0, 0x31BF, "Bopomofo Extended",
        0x31C0, 0x31EF, "CJK Strokes",
        0x31F0, 0x31FF, "Katakana Phonetic Extensions",
        0x3200, 0x32FF, "Enclosed CJK Letters and Months",
        0x3300, 0x33FF, "CJK Compatibility",
        0x3400, 0x4DBF, "CJK Unified Ideographs Extension A",
        0x4DC0, 0x4DFF, "Yijing Hexagram Symbols",
        0x4E00, 0x9FFF, "CJK Unified Ideographs",
        0xA000, 0xA48F, "Yi Syllables",
        0xA490, 0xA4CF, "Yi Radicals",
        0xA4D0, 0xA4FF, "Lisu",
        0xA500, 0xA63F, "Vai",
        0xA640, 0xA69F, "Cyrillic Extended-B",
        0xA6A0, 0xA6FF, "Bamum",
        0xA700, 0xA71F, "Modifier Tone Letters",
        0xA720, 0xA7FF, "Latin Extended-D",
        0xA800, 0xA82F, "Syloti Nagri",
        0xA830, 0xA83F, "Common Indic Number Forms",
        0xA840, 0xA87F, "Phags-pa",
        0xA880, 0xA8DF, "Saurashtra",
        0xA8E0, 0xA8FF, "Devanagari Extended",
        0xA900, 0xA92F, "Kayah Li",
        0xA930, 0xA95F, "Rejang",
        0xA960, 0xA97F, "Hangul Jamo Extended-A",
        0xA980, 0xA9DF, "Javanese",
        0xA9E0, 0xA9FF, "Myanmar Extended-B",
        0xAA00, 0xAA5F, "Cham",
        0xAA60, 0xAA7F, "Myanmar Extended-A",
        0xAA80, 0xAADF, "Tai Viet",
        0xAAE0, 0xAAFF, "Meetei Mayek Extensions",
        0xAB00, 0xAB2F, "Ethiopic Extended-A",
        0xAB30, 0xAB6F, "Latin Extended-E",
        0xAB70, 0xABBF, "Cherokee Supplement",
        0xABC0, 0xABFF, "Meetei Mayek",
        0xAC00, 0xD7AF, "Hangul Syllables",
        0xD7B0, 0xD7FF, "Hangul Jamo Extended-B",
        0xD800, 0xDB7F, "High Surrogates",
        0xDB80, 0xDBFF, "High Private Use Surrogates",
        0xDC00, 0xDFFF, "Low Surrogates",
        0xE000, 0xF8FF, "Private Use Area",
        0xF900, 0xFAFF, "CJK Compatibility Ideographs",
        0xFB00, 0xFB4F, "Alphabetic Presentation Forms",
        0xFB50, 0xFDFF, "Arabic Presentation Forms-A",
        0xFE00, 0xFE0F, "Variation Selectors",
        0xFE10, 0xFE1F, "Vertical Forms",
        0xFE20, 0xFE2F, "Combining Half Marks",
        0xFE30, 0xFE4F, "CJK Compatibility Forms",
        0xFE50, 0xFE6F, "Small Form Variants",
        0xFE70, 0xFEFF, "Arabic Presentation Forms-B",
        0xFF00, 0xFFEF, "Halfwidth and Fullwidth Forms",
        0xFFF0, 0xFFFF, "Specials",
        0x10000, 0x1007F, "Linear B Syllabary",
        0x10080, 0x100FF, "Linear B Ideograms",
        0x10100, 0x1013F, "Aegean Numbers",
        0x10140, 0x1018F, "Ancient Greek Numbers",
        0x10190, 0x101CF, "Ancient Symbols",
        0x101D0, 0x101FF, "Phaistos Disc",
        0x10280, 0x1029F, "Lycian",
        0x102A0, 0x102DF, "Carian",
        0x102E0, 0x102FF, "Coptic Epact Numbers",
        0x10300, 0x1032F, "Old Italic",
        0x10330, 0x1034F, "Gothic",
        0x10350, 0x1037F, "Old Permic",
        0x10380, 0x1039F, "Ugaritic",
        0x103A0, 0x103DF, "Old Persian",
        0x10400, 0x1044F, "Deseret",
        0x10450, 0x1047F, "Shavian",
        0x10480, 0x104AF, "Osmanya",
        0x104B0, 0x104FF, "Osage",
        0x10500, 0x1052F, "Elbasan",
        0x10530, 0x1056F, "Caucasian Albanian",
        0x10570, 0x105BF, "Vithkuqi",
        0x105C0, 0x105FF, "Todhri",
        0x10600, 0x1077F, "Linear A",
        0x10780, 0x107BF, "Latin Extended-F",
        0x10800, 0x1083F, "Cypriot Syllabary",
        0x10840, 0x1085F, "Imperial Aramaic",
        0x10860, 0x1087F, "Palmyrene",
        0x10880, 0x108AF, "Nabataean",
        0x108E0, 0x108FF, "Hatran",
        0x10900, 0x1091F, "Phoenician",
        0x10920, 0x1093F, "Lydian",
        0x10980, 0x1099F, "Meroitic Hieroglyphs",
        0x109A0, 0x109FF, "Meroitic Cursive",
        0x10A00, 0x10A5F, "Kharoshthi",
        0x10A60, 0x10A7F, "Old South Arabian",
        0x10A80, 0x10A9F, "Old North Arabian",
        0x10AC0, 0x10AFF, "Manichaean",
        0x10B00, 0x10B3F, "Avestan",
        0x10B40, 0x10B5F, "Inscriptional Parthian",
        0x10B60, 0x10B7F, "Inscriptional Pahlavi",
        0x10B80, 0x10BAF, "Psalter Pahlavi",
        0x10C00, 0x10C4F, "Old Turkic",
        0x10C80, 0x10CFF, "Old Hungarian",
        0x10D00, 0x10D3F, "Hanifi Rohingya",
        0x10D40, 0x10D8F, "Garay",
        0x10E60, 0x10E7F, "Rumi Numeral Symbols",
        0x10E80, 0x10EBF, "Yezidi",
        0x10EC0, 0x10EFF, "Arabic Extended-C",
        0x10F00, 0x10F2F, "Old Sogdian",
        0x10F30, 0x10F6F, "Sogdian",
        0x10F70, 0x10FAF, "Old Uyghur",
        0x10FB0, 0x10FDF, "Chorasmian",
        0x10FE0, 0x10FFF, "Elymaic",
        0x11000, 0x1107F, "Brahmi",
        0x11080, 0x110CF, "Kaithi",
        0x110D0, 0x110FF, "Sora Sompeng",
        0x11100, 0x1114F, "Chakma",
        0x11150, 0x1117F, "Mahajani",
        0x11180, 0x111DF, "Sharada",
        0x111E0, 0x111FF, "Sinhala Archaic Numbers",
        0x11200, 0x1124F, "Khojki",
        0x11280, 0x112AF, "Multani",
        0x112B0, 0x112FF, "Khudawadi",
        0x11300, 0x1137F, "Grantha",
        0x11380, 0x113FF, "Tulu-Tigalari",
        0x11400, 0x1147F, "Newa",
        0x11480, 0x114DF, "Tirhuta",
        0x11580, 0x115FF, "Siddham",
        0x11600, 0x1165F, "Modi",
        0x11660, 0x1167F, "Mongolian Supplement",
        0x11680, 0x116CF, "Takri",
        0x116D0, 0x116FF, "Myanmar Extended-C",
        0x11700, 0x1174F, "Ahom",
        0x11800, 0x1184F, "Dogra",
        0x118A0, 0x118FF, "Warang Citi",
        0x11900, 0x1195F, "Dives Akuru",
        0x119A0, 0x119FF, "Nandinagari",
        0x11A00, 0x11A4F, "Zanabazar Square",
        0x11A50, 0x11AAF, "Soyombo",
        0x11AB0, 0x11ABF, "Unified Canadian Aboriginal Syllabics Extended-A",
        0x11AC0, 0x11AFF, "Pau Cin Hau",
        0x11B00, 0x11B5F, "Devanagari Extended-A",
        0x11BC0, 0x11BFF, "Sunuwar",
        0x11C00, 0x11C6F, "Bhaiksuki",
        0x11C70, 0x11CBF, "Marchen",
        0x11D00, 0x11D5F, "Masaram Gondi",
        0x11D60, 0x11DAF, "Gunjala Gondi",
        0x11EE0, 0x11EFF, "Makasar",
        0x11F00, 0x11F5F, "Kawi",
        0x11FB0, 0x11FBF, "Lisu Supplement",
        0x11FC0, 0x11FFF, "Tamil Supplement",
        0x12000, 0x123FF, "Cuneiform",
        0x12400, 0x1247F, "Cuneiform Numbers and Punctuation",
        0x12480, 0x1254F, "Early Dynastic Cuneiform",
        0x12F90, 0x12FFF, "Cypro-Minoan",
        0x13000, 0x1342F, "Egyptian Hieroglyphs",
        0x13430, 0x1345F, "Egyptian Hieroglyph Format Controls",
        0x13460, 0x143FF, "Egyptian Hieroglyphs Extended-A",
        0x14400, 0x1467F, "Anatolian Hieroglyphs",
        0x16100, 0x1613F, "Gurung Khema",
        0x16800, 0x16A3F, "Bamum Supplement",
        0x16A40, 0x16A6F, "Mro",
        0x16A70, 0x16ACF, "Tangsa",
        0x16AD0, 0x16AFF, "Bassa Vah",
        0x16B00, 0x16B8F, "Pahawh Hmong",
        0x16D40, 0x16D7F, "Kirat Rai",
        0x16E40, 0x16E9F, "Medefaidrin",
        0x16F00, 0x16F9F, "Miao",
        0x16FE0, 0x16FFF, "Ideographic Symbols and Punctuation",
        0x17000, 0x187FF, "Tangut",
        0x18800, 0x18AFF, "Tangut Components",
        0x18B00, 0x18CFF, "Khitan Small Script",
        0x18D00, 0x18D7F, "Tangut Supplement",
        0x1AFF0, 0x1AFFF, "Kana Extended-B",
        0x1B000, 0x1B0FF, "Kana Supplement",
        0x1B100, 0x1B12F, "Kana Extended-A",
        0x1B130, 0x1B16F, "Small Kana Extension",
        0x1B170, 0x1B2FF, "Nushu",
        0x1BC00, 0x1BC9F, "Duployan",
        0x1BCA0, 0x1BCAF, "Shorthand Format Controls",
        0x1CC00, 0x1CEBF, "Symbols for Legacy Computing Supplement",
        0x1CF00, 0x1CFCF, "Znamenny Musical Notation",
        0x1D000, 0x1D0FF, "Byzantine Musical Symbols",
        0x1D100, 0x1D1FF, "Musical Symbols",
        0x1D200, 0x1D24F, "Ancient Greek Musical Notation",
        0x1D2C0, 0x1D2DF, "Kaktovik Numerals",
        0x1D2E0, 0x1D2FF, "Mayan Numerals",
        0x1D300, 0x1D35F, "Tai Xuan Jing Symbols",
        0x1D360, 0x1D37F, "Counting Rod Numerals",
        0x1D400, 0x1D7FF, "Mathematical Alphanumeric Symbols",
        0x1D800, 0x1DAAF, "Sutton SignWriting",
        0x1DF00, 0x1DFFF, "Latin Extended-G",
        0x1E000, 0x1E02F, "Glagolitic Supplement",
        0x1E030, 0x1E08F, "Cyrillic Extended-D",
        0x1E100, 0x1E14F, "Nyiakeng Puachue Hmong",
        0x1E290, 0x1E2BF, "Toto",
        0x1E2C0, 0x1E2FF, "Wancho",
        0x1E4D0, 0x1E4FF, "Nag Mundari",
        0x1E5D0, 0x1E5FF, "Ol Onal",
        0x1E7E0, 0x1E7FF, "Ethiopic Extended-B",
        0x1E800, 0x1E8DF, "Mende Kikakui",
        0x1E900, 0x1E95F, "Adlam",
        0x1EC70, 0x1ECBF, "Indic Siyaq Numbers",
        0x1ED00, 0x1ED4F, "Ottoman Siyaq Numbers",
        0x1EE00, 0x1EEFF, "Arabic Mathematical Alphabetic Symbols",
        0x1F000, 0x1F02F, "Mahjong Tiles",
        0x1F030, 0x1F09F, "Domino Tiles",
        0x1F0A0, 0x1F0FF, "Playing Cards",
        0x1F100, 0x1F1FF, "Enclosed Alphanumeric Supplement",
        0x1F200, 0x1F2FF, "Enclosed Ideographic Supplement",
        0x1F300, 0x1F5FF, "Miscellaneous Symbols and Pictographs",
        0x1F600, 0x1F64F, "Emoticons",
        0x1F650, 0x1F67F, "Ornamental Dingbats",
        0x1F680, 0x1F6FF, "Transport and Map Symbols",
        0x1F700, 0x1F77F, "Alchemical Symbols",
        0x1F780, 0x1F7FF, "Geometric Shapes Extended",
        0x1F800, 0x1F8FF, "Supplemental Arrows-C",
        0x1F900, 0x1F9FF, "Supplemental Symbols and Pictographs",
        0x1FA00, 0x1FA6F, "Chess Symbols",
        0x1FA70, 0x1FAFF, "Symbols and Pictographs Extended-A",
        0x1FB00, 0x1FBFF, "Symbols for Legacy Computing",
        0x20000, 0x2A6DF, "CJK Unified Ideographs Extension B",
        0x2A700, 0x2B73F, "CJK Unified Ideographs Extension C",
        0x2B740, 0x2B81F, "CJK Unified Ideographs Extension D",
        0x2B820, 0x2CEAF, "CJK Unified Ideographs Extension E",
        0x2CEB0, 0x2EBEF, "CJK Unified Ideographs Extension F",
        0x2EBF0, 0x2EE5F, "CJK Unified Ideographs Extension I",
        0x2F800, 0x2FA1F, "CJK Compatibility Ideographs Supplement",
        0x30000, 0x3134F, "CJK Unified Ideographs Extension G",
        0x31350, 0x323AF, "CJK Unified Ideographs Extension H",
        0xE0000, 0xE007F, "Tags",
        0xE0100, 0xE01EF, "Variation Selectors Supplement",
        0xF0000, 0xFFFFF, "Supplementary Private Use Area-A",
        0x100000, 0x10FFFF, "Supplementary Private Use Area-B",
    }

    local block_count = #blocks / 3

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
    function unicode.block( utf8_codepoint )
        if not is_codepoint( utf8_codepoint ) then
            error( string_format( "invalid unicode code point '%s'", utf8_codepoint ), 2 )
        end

        if utf8_codepoint < 0x80 then
            return "Basic Latin", 0x0000, 0x007F
        end

        local low, high = 1, block_count

        while low <= high do
            local middle = rbit_rshift( low + high, 1 )
            local index = middle * 3 - 2

            if utf8_codepoint < blocks[ index ] then
                high = middle - 1
            elseif utf8_codepoint > blocks[ index + 1 ] then
                low = middle + 1
            else
                ---@diagnostic disable-next-line: return-type-mismatch
                return blocks[ index + 2 ], blocks[ index ], blocks[ index + 1 ]
            end
        end

        return nil, nil, nil
    end

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
    function unicode.blocks()
        local index = -2

        return function()
            index = index + 3

            local block_name = blocks[ index + 2 ]
            if block_name ~= nil then
                ---@diagnostic disable-next-line: return-type-mismatch
                return block_name, blocks[ index ], blocks[ index + 1 ]
                ---@diagnostic disable-next-line: missing-return
            end
        end
    end

end
