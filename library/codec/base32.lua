---@meta _

--- [SHARED AND MENU]
---
--- Base32 encoding/decoding library.
---
--- See https://en.wikipedia.org/wiki/Base32
---
---@class base32
base32 = {}

--- [SHARED AND MENU]
---
--- The base32 encoding/decoding alphabet, created by `base32.alphabet`.
---
---@class base32.Alphabet
---@field [1] table<integer, integer> | ffi.cdata* The encoding map, value ( 0 - 31 ) to character byte.
---@field [2] table<integer, integer> | ffi.cdata* The decoding map, character byte ( 0 - 255 ) to value, `-1` for characters outside the alphabet.

--- [SHARED AND MENU]
---
--- Creates a base32 alphabet with encoding and decoding maps.
---
---@param alphabet_str string The alphabet string, 32 unique characters without `=`.
---@return base32.Alphabet alphabet The alphabet.
---@nodiscard
function base32.alphabet(alphabet_str) end

--- [SHARED AND MENU]
---
--- Encodes the specified string to base32.
---
---@param raw_str string The string to encode.
---@param ignore_padding? boolean Whether to ignore padding.
---@param alphabet? "standard" | "extended" | base32.Alphabet The alphabet to use.
---@return string base32_str The encoded string.
---@nodiscard
function base32.encode(raw_str, ignore_padding, alphabet) end

--- [SHARED AND MENU]
---
--- Decodes the specified base32 encoded string.
---
--- Throws an error if the string has invalid length, padding or characters.
---
---@param base32_str string The base32 encoded string to decode.
---@param ignore_padding? boolean Whether padding is optional.
---@param alphabet? "standard" | "extended" | base32.Alphabet The alphabet to use.
---@return string raw_str The decoded string.
---@nodiscard
function base32.decode(base32_str, ignore_padding, alphabet) end

--- [SHARED AND MENU]
---
--- Checks if the specified base32 encoded string is valid.
---
---@param base32_str string The base32 encoded string to check.
---@param ignore_padding? boolean Whether padding is optional.
---@param alphabet? "standard" | "extended" | base32.Alphabet The alphabet to use.
---@return boolean is_valid `true` if the base32 string is valid, `false` otherwise
---@return nil | string err_msg The error message.
---@nodiscard
function base32.validate(base32_str, ignore_padding, alphabet) end
