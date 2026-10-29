---@meta _

--- [SHARED AND MENU]
---
--- SHA384 object.
---
--- SHA384 is SHA512 with a different initial state and the digest truncated to 48 bytes,
--- so it inherits all methods from `SHA512` and only overrides the initial state.
---
---@class crypto.SHA384 : crypto.SHA512
---@field __class crypto.SHA384Class
---@field protected initial_state integer[] The initial hash state as `hi, lo` pairs, overridden by SHA384.
local SHA384 = {}

--- [SHARED AND MENU]
---
--- The class used to create new `SHA384` hash calculation instances.
---
--- Secure Hash Algorithm 384-bit, part of the SHA-2 family.
---
--- Like other hash classes, it takes input data ( string )
--- and produces a digest ( string ) — a
--- fixed-size output string that represents that data.
---
---@class crypto.SHA384Class : crypto.SHA384, crypto.HashClass
---@field __base crypto.SHA384
---@field digest fun( message: string, as_hex?: boolean ): string
---@field digest_size integer
---@field block_size integer
---@operator call: crypto.SHA384
crypto.SHA384 = {}

crypto.SHA384.digest_size = 48

crypto.SHA384.block_size = 128

SHA384.initial_state = {}

--- [SHARED AND MENU]
---
--- Computes the SHA384 digest of the given input string.
---
--- This static method takes a string and returns its SHA384 hash as a hexadecimal string.
--- Commonly used for checksums, data integrity validation, and password hashing.
---
---@param message string The message to compute SHA384 for.
---@param as_hex? boolean If true, the result will be a hex string.
---@return string str_result The SHA384 string of the message.
---@nodiscard
function crypto.SHA384.digest(message, as_hex) end
