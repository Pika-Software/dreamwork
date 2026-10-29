local std = dreamwork.std

---@class dreamwork.std.crypto
local crypto = std.crypto

local class = std.class

--- [SHARED AND MENU]
---
--- SHA384 object.
---
--- SHA384 is SHA512 with a different initial state and the digest truncated to 48 bytes,
--- so it inherits all methods from `SHA512` and only overrides the initial state.
---
---@class dreamwork.std.crypto.SHA384 : dreamwork.std.crypto.SHA512
---@field __class dreamwork.std.crypto.SHA384Class
---@field protected initial_state integer[] The initial hash state as `hi, lo` pairs, overridden by SHA384.
local SHA384 = class.base( "SHA384", false, crypto.SHA512 )

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
---@class dreamwork.std.crypto.SHA384Class : dreamwork.std.crypto.SHA384, dreamwork.std.crypto.HashClass
---@field __base dreamwork.std.crypto.SHA384
---@field digest fun( message: string, as_hex?: boolean ): string
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
---@param as_hex? boolean If true, the result will be a hex string.
---@return string str_result The SHA384 string of the message.
---@nodiscard
function SHA384Class.digest( message, as_hex )
    return SHA384Class():update( message ):digest( as_hex )
end
