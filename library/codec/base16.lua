---@meta _

--- [SHARED AND MENU]
---
--- Base16 (hexadecimal) encoding/decoding library.
---
--- See https://en.wikipedia.org/wiki/Hexadecimal
---
---@class base16
base16 = {}

--- [SHARED AND MENU]
---
--- Encodes the specified string to base16 (upper-case).
---
---@param raw_str string The string to encode.
---@return string base16_str The encoded string.
---@nodiscard
function base16.encode(raw_str) end

--- [SHARED AND MENU]
---
--- Decodes the specified base16 string to a string.
---
--- Pairs that are not valid hex digits and a trailing odd character are copied as-is, use `base16.validate` to reject them.
---
---@param base16_str string The base16 string to decode.
---@param start_position? integer The start position of the base16 string, default is `1`.
---@param end_position? integer The end position of the base16 string, default is the length of the base16 string.
---@return string raw_str The decoded string.
---@nodiscard
function base16.decode(base16_str, start_position, end_position) end

--- [SHARED AND MENU]
---
--- Validates the specified base16 string.
---
---@param base16_str string The base16 string to validate.
---@return boolean is_valid `true` if the base16 string is valid, otherwise `false`.
---@return nil | string err_msg The error message.
---@nodiscard
function base16.validate(base16_str) end

--- [SHARED AND MENU]
---
--- Escapes the specified base16 string.
---
--- Escape sequence: `\xXX`
---
---@param base16_str string The base16 string to escape.
---@return string base16_escape_str The escaped base16 string.
---@nodiscard
function base16.escape(base16_str) end

--- [SHARED AND MENU]
---
--- Unescapes the specified base16 string.
---
--- Unescape sequence: `\xXX`
---
---@param base16_escape_str string The base16 string to unescape.
---@return string base16_str The unescaped base16 string.
---@nodiscard
function base16.unescape(base16_escape_str) end
