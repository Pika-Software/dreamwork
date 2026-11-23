local std = dreamwork.std

---@class dreamwork.std.crypto
local crypto = std.crypto

local class = std.class

--- [SHARED AND MENU]
---
--- An incremental SHA-384 hasher.
---
--- Same engine as `SHA512` with a different IV; the digest is truncated to 48 bytes.
--- Inherits `:update`, `:digest` and `:reset` from `SHA512`.
---
--- ```lua
--- local sha = std.crypto.SHA384()
---
--- print( sha:update( "hi" ):digest( true ) ) -- 0791006df8128477244f53d0fdce210db81f55757510e26acee35c18a6bceaa28dcdbbfd6dc041b9b4dc7b1b54e37f52
--- ```
---
---@class dreamwork.std.crypto.SHA384 : dreamwork.std.crypto.SHA512
---@field __class dreamwork.std.crypto.SHA384Class
---@field protected initial_state integer[] The initial hash state as `hi, lo` pairs, overridden by SHA384.
local SHA384 = class.base( "SHA384", false, crypto.SHA512 )

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
--- print( std.crypto.SHA384.digest( "hi", true ) ) -- 0791006df8128477244f53d0fdce210db81f55757510e26acee35c18a6bceaa28dcdbbfd6dc041b9b4dc7b1b54e37f52
--- ```
---
---@class dreamwork.std.crypto.SHA384Class : dreamwork.std.crypto.SHA384, dreamwork.std.crypto.SHA512Class
---@field __base dreamwork.std.crypto.SHA384
---@field digest fun( message: string, as_hex: boolean? ): string
---@field digest_size integer
---@field block_size integer
---@operator call: dreamwork.std.crypto.SHA384
local SHA384Class = class.create( SHA384 )
crypto.SHA384 = SHA384Class

SHA384Class.digest_size = 48
SHA384Class.block_size = 128

SHA384.initial_state = {
    -0x344462a3, 0xc1059ed8, 0x629a292a, 0x367cd507, -0x6ea6fea6, 0x3070dd17, 0x152fecd8, 0xf70e5939,
    0x67332667, 0xffc00b31, -0x714bb579, 0x68581511, -0x24f3d1f3, 0x64f98fa7, 0x47b5481d, 0xbefa4fa4
}

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
function SHA384Class.digest( message, as_hex )
    return SHA384Class():update( message ):digest( as_hex )
end
