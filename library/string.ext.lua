---@meta _

--- [SHARED AND MENU]
---
--- Escapes special characters in a string.
---
--- Within the given range, any byte that has a known escape sequence (e.g. newline, tab, quote, backslash etc.) is replaced with that sequence.
---
--- Any other byte that is a control character (below `0x20`, or below `0x21` i.e. including the space
--- character when `escape_spaces` is `true`) or is outside the printable ASCII range (`0x7F` and above) is replaced with a `\xHH` hexadecimal escape.
---
--- All other bytes, and anything outside `start_position`/`end_position`, are left untouched.
---
---@see string.unescape
---
---@param str string The string to escape.
---@param escape_spaces? boolean Whether the space character (`0x20`) should also be escaped as `\x20`. Defaults to `false`.
---@param start_position? integer The position to start escaping from, inclusive. Negative values count from the end of the string. Defaults to `1` (the start of the string).
---@param end_position? integer The position to stop escaping at, inclusive. Negative values count from the end of the string. Defaults to the end of the string.
---@return string escaped_str The string with special characters escaped.
---@nodiscard
function string.escape(str, escape_spaces, start_position, end_position) end

--- [SHARED AND MENU]
---
--- Unescapes special characters in a string.
---
--- The inverse of `string.escape`.
---
--- Within the given range, recognized escape sequences (e.g. `\n`, `\t`, `\"`, `\\` etc.)
--- are converted back into their raw byte, and `\xHH` hexadecimal escapes are decoded into the byte they represent.
---
--- Any other byte, and anything outside `start_position`/`end_position`, is left untouched.
---
---@see string.escape
---
---@param escaped_str string The string to unescape.
---@param start_position? integer The position to start unescaping from, inclusive. Negative values count from the end of the string. Defaults to `1` (the start of the string).
---@param end_position? integer The position to stop unescaping at, inclusive. Negative values count from the end of the string. Defaults to the end of the string.
---@return string str The unescaped string.
---@nodiscard
function string.unescape(escaped_str, start_position, end_position) end

--- [SHARED AND MENU]
---
--- Returns the Fowler-Noll-Vo (FNV-0) [deprecated] hash of the string.
---
--- [Wiki Page](https://en.wikipedia.org/wiki/Fowler–Noll–Vo_hash_function)
---
---@param str string The string used to calculate the Fowler-Noll-Vo hash.
---@return integer hash_int The Fowler-Noll-Vo hash, which is greater or equal to 0, and less than 2^32 (0x100000000).
---@nodiscard
function string.fnv0(str) end

--- [SHARED AND MENU]
---
--- Returns the Fowler-Noll-Vo (FNV-1) hash of the string.
---
--- [Wiki Page](https://en.wikipedia.org/wiki/Fowler–Noll–Vo_hash_function)
---
---@param str string The string used to calculate the Fowler-Noll-Vo hash.
---@return integer hash_int The Fowler-Noll-Vo hash, which is greater or equal to 0, and less than 2^32 (0x100000000).
---@nodiscard
function string.fnv1(str) end

--- [SHARED AND MENU]
---
--- Returns the Fowler-Noll-Vo (FNV-1a) hash of the string.
---
--- [Wiki Page](https://en.wikipedia.org/wiki/Fowler–Noll–Vo_hash_function)
---
---@param str string The string used to calculate the Fowler-Noll-Vo hash.
---@return integer hash_int The Fowler-Noll-Vo hash, which is greater or equal to 0, and less than 2^32 (0x100000000).
---@nodiscard
function string.fnv1a(str) end
