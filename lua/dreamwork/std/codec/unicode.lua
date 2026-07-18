---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_tonumber = raw.tonumber

local string = std.string
local string_sub = string.sub
local string_gsub = string.gsub
local string_format = string.format

local table = std.table
local table_concat = table.concat

local utf8 = std.utf8
local utf8_char = utf8.char
local utf8_unpack = utf8.unpack

--- [SHARED AND MENU]
---
--- The unicode library provides functions for the manipulation of unicode encoded UTF-8 strings.
---
---@class dreamwork.std.unicode
---@field MAX integer The maximum number of characters that can be stored in a unicode string.
local unicode = {
    MAX = 0x10FFFF
}

std.unicode = unicode

--- [SHARED AND MENU]
---
--- Returns a string representation of the given unicode codepoint.
---
---@param utf8_codepoint integer The unicode codepoint to represent.
---@return string utf8_tag The string representation of the codepoint, in the format `U+XXXX` or `U+XXXXX`.
function unicode.tag( utf8_codepoint )
    return string_format( utf8_codepoint > 0xFFFF and "U+%06X" or "U+%04X", utf8_codepoint )
end

--- [SHARED AND MENU]
---
--- Returns the unicode codepoint represented by the given string.
---
---@param utf8_tag string The string representation of a unicode codepoint, in the format `U+XXXX` or `U+XXXXX`.
---@return integer | nil utf8_codepoint The unicode codepoint represented by the string.
function unicode.untag( utf8_tag )
    return raw_tonumber( string_sub( utf8_tag, 3 ), 16 )
end

--- [SHARED AND MENU]
---
--- Converts each character in the input string into a Unicode escape sequence
--- (`\uXXXX` or `\u{XXXX}`), suitable for serialization, logging, or safe ASCII output.
---
---@param utf8_str string The input string containing Unicode characters.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return string escaped_str A string where each character is replaced with its Unicode escape sequence
function unicode.escape( utf8_str, start_position, end_position, lax )
    local codepoints, codepoint_count = utf8_unpack( utf8_str, start_position, end_position, lax )
    local segments, segment_count = {}, 0

    for i = 1, codepoint_count, 1 do
        local codepoint = codepoints[ i ]
        segment_count = segment_count + 1

        if codepoint > 0xFFFF then
            segments[ segment_count ] = string_format( "\\u{%X}", codepoint )
        else
            segments[ segment_count ] = string_format( "\\u%04X", codepoint )
        end
    end

    if segment_count == 0 then
        return ""
    else
        return table_concat( segments, "", 1, segment_count )
    end
end

do

    ---@param hex_str string
    ---@return string
    local function unescape( hex_str )
        return utf8_char( raw_tonumber( hex_str, 16 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Converts Unicode escape sequences (such as `\uXXXX` or `\u{XXXX}`) into actual characters.
    --- Supports both fixed-length and variable-length Unicode escape formats.
    ---
    ---@param escaped_str string A string containing Unicode escape sequences
    ---@return string utf8_str A string with the escape sequences converted to real Unicode characters
    function unicode.unescape( escaped_str )
        return (string_gsub( escaped_str, "\\u([0-9a-fA-F]+)", unescape ))
    end

end
