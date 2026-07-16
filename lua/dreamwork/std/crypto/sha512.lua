---@class dreamwork.std
local std = dreamwork.std

---@class dreamwork.std.crypto
local crypto = std.crypto

---@class dreamwork.std.crypto.SHA512 : dreamwork.std.Object
---@field __class dreamwork.std.crypto.SHA512Class
local SHA512 = std.class.base( "SHA512" )

---@class dreamwork.std.crypto.SHA512Class : dreamwork.std.crypto.SHA512
---@field __base dreamwork.std.crypto.SHA512
---@field digest_size integer
---@field block_size integer
---@overload fun(): dreamwork.std.crypto.SHA512
local SHA512Class = std.class.create( SHA512 )
crypto.SHA512 = SHA512Class

-- SHA512Class.digest_size = 32
-- SHA512Class.block_size = 64

-- TODO: implement (example: md5)
