---@meta _

--- [SHARED AND MENU]
---
--- Base64 encoding/decoding library.
---
---@see https://en.wikipedia.org/wiki/Base64
---@class base64
base64 = {}

--- [SHARED AND MENU]
---
--- The base64 encoding/decoding alphabet, created by `base64.alphabet`.
---
---@class base64.Alphabet
---@field [1] table<integer, integer> | ffi.cdata* The encoding map, value ( 0 - 63 ) to character byte.
---@field [2] table<integer, integer> | ffi.cdata* The decoding map, character byte ( 0 - 255 ) to value, `-1` for characters outside the alphabet.

--- [SHARED AND MENU]
---
--- Creates a base64 alphabet with encoding and decoding maps.
---
---@param alphabet_str string The alphabet string, 64 unique non-whitespace characters.
---@return base64.Alphabet alphabet The alphabet.
---@nodiscard
function base64.alphabet(alphabet_str) end

--- [SHARED AND MENU]
---
--- Base64 encoding/decoding options variant.
---
---@class base64.Variant
---@field alphabet base64.Alphabet The 64-character alphabet used for encoding and decoding.
---@field pad string | false | nil Padding character (usually "="), `false` disables padding.
---@field wrap integer | false | nil Line wrap length, `false` or `0` disables wrapping.
---@field eol string | nil End-of-line characters used if `wrap` is set, default is `"\r\n"`.

--- [SHARED AND MENU]
---
--- Base64 encoding/decoding options.
---
--- Fields that are `nil` are taken from the variant, `custom` has the standard alphabet without padding and wrapping.
---
---@class base64.Options : base64.Variant
---@field variant "standard" | "urlsafe" | "mime" | "jwt" | "custom" | nil The base64 variant to use, default is `"standard"`.

--- [SHARED AND MENU]
---
--- Encodes the specified string to base64.
---
---@param raw_str string The string to encode.
---@param options? base64.Options The base64 encoding options, default is the standard variant.
---@return string base64_str The encoded string.
---@nodiscard
function base64.encode(raw_str, options) end

--- [SHARED AND MENU]
---
--- Decodes the specified base64 encoded string.
---
--- Whitespace ( including line breaks ) is ignored, padding is optional but must be correct if present.
---
--- Throws an error if the string has invalid length, padding or characters.
---
---@param base64_str string The base64 encoded string to decode.
---@param options? base64.Options The base64 encoding options, default is the standard variant.
---@return string raw_str The decoded string.
---@nodiscard
function base64.decode(base64_str, options) end

--- [SHARED AND MENU]
---
--- Checks if the specified base64 encoded string is valid, follows the same rules as `base64.decode`.
---
---@param base64_str string The base64 encoded string to check.
---@param options? base64.Options The base64 encoding options, default is the standard variant.
---@return boolean is_valid `true` if the base64 string is valid, `false` otherwise
---@return nil | string err_msg The error message.
---@nodiscard
function base64.validate(base64_str, options) end
