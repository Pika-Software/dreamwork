---@meta _

--- [SHARED AND MENU]
---
--- An incremental SHA-384 hasher.
---
--- Same engine as `SHA512` with a different IV; the digest is truncated to 48 bytes.
--- Inherits `:update`, `:digest` and `:reset` from `SHA512`.
---
--- ```lua
--- local sha = crypto.SHA384()
---
--- print( sha:update( "hi" ):digest( true ) ) -- 0791006df8128477244f53d0fdce210db81f55757510e26acee35c18a6bceaa28dcdbbfd6dc041b9b4dc7b1b54e37f52
--- ```
---
---@class crypto.SHA384 : crypto.SHA512
---@field __class crypto.SHA384Class
---@field protected initial_state integer[] The initial hash state as `hi, lo` pairs, overridden by SHA384.
local SHA384 = {}

--- [SHARED AND MENU]
---
--- The class used to create `SHA384` instances.
---
--- Secure Hash Algorithm 384-bit (SHA-2). Built on SHA-512 with a truncated
--- digest — a middle ground between SHA-256 and full SHA-512.
---
--- One-shot hashing via `SHA384.digest`, or create an instance and stream with
--- `:update` / `:digest` / `:reset`.
---
--- ```lua
--- print( crypto.SHA384.digest( "hi", true ) ) -- 0791006df8128477244f53d0fdce210db81f55757510e26acee35c18a6bceaa28dcdbbfd6dc041b9b4dc7b1b54e37f52
--- ```
---
---@class crypto.SHA384Class : crypto.SHA384, crypto.SHA512Class
---@field __base crypto.SHA384
---@field digest fun( message: string, as_hex: boolean? ): string
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
---@param as_hex boolean? If true, the result will be a hex string.
---@return string str_result The SHA384 string of the message.
---@nodiscard
function crypto.SHA384.digest(message, as_hex) end
