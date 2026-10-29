---@meta _

--- [SHARED AND MENU]
---
--- Percent (URL/URI) encoding/decoding library.
---
--- Percent-encoding is a mechanism to encode 8-bit characters that have specific meaning in the context of URLs.
---
--- It is sometimes called **URL encoding**.
---
--- The encoding consists of substitution: A '%' followed by the hexadecimal representation of the ASCII value of the replace character.
---
--- See https://en.wikipedia.org/wiki/Percent-encoding & https://datatracker.ietf.org/doc/html/rfc3986#section-2.1
---
---@class percent
percent = {}

--- [SHARED AND MENU]
---
--- Creates a character whitelist for the given pattern.
---
---@param pattern_str string The pattern.
---@param base? table The base table, optional.
---@return table<integer, boolean> whitelist The character whitelist.
---@nodiscard
function percent.whitelist(pattern_str, base) end

--- [SHARED AND MENU]
---
--- Encodes the specified string to percent encoding.
---
--- Bytes not in the whitelist are encoded as `"%XX"` (upper-case hex),
--- spaces are encoded as `"+"` unless `ignore_spaces` is `true`.
---
--- ```lua
--- percent.encode( "a b&c" ) -- "a+b%26c"
--- percent.encode( "a b&c", nil, true ) -- "a%20b%26c"
--- ```
---
---@param raw_str string The string to encode.
---@param whitelist? table<integer, boolean> The character whitelist, bytes in it are left as is, optional.
---@param ignore_spaces? boolean If `true`, spaces are encoded as `"%20"` instead of `"+"`, optional.
---@return string percent_str The encoded string.
---@nodiscard
function percent.encode(raw_str, whitelist, ignore_spaces) end

--- [SHARED AND MENU]
---
--- Decodes the specified string from percent encoding.
---
--- Invalid or incomplete `"%"` sequences are kept as is.
---
--- ```lua
--- percent.decode( "a+b%26c" ) -- "a b&c"
--- percent.decode( "a+b%26c", true ) -- "a+b&c"
--- ```
---
---@param percent_str string The string to decode.
---@param ignore_spaces? boolean If `true`, `"+"` is kept as is instead of being decoded as a space, optional.
---@return string raw_str The decoded string.
---@nodiscard
function percent.decode(percent_str, ignore_spaces) end

--- [SHARED AND MENU]
---
--- Validates the specified percent string.
---
--- A valid string contains only whitelisted bytes, complete `"%XX"` sequences
--- and, unless `ignore_spaces` is `true`, `"+"`.
---
---@param percent_str string The percent string to validate.
---@param whitelist? table<integer, boolean> The character whitelist, optional.
---@param ignore_spaces? boolean If `true`, `"+"` is not allowed unless whitelisted, optional.
---@return boolean is_valid `true` if the percent string is valid, otherwise `false`.
---@return nil | string err_msg The error message.
---@nodiscard
function percent.validate(percent_str, whitelist, ignore_spaces) end
