local std = _G.dreamwork.std

---@class dreamwork.std.hash
local hash = std.hash

---@class dreamwork.std.hash.SHA512 : dreamwork.Object
---@field __class dreamwork.std.hash.SHA512Class
local SHA512 = std.class.base( "SHA512" )

---@alias SHA512 dreamwork.std.hash.SHA512

---@class dreamwork.std.hash.SHA512Class : dreamwork.std.hash.SHA512
---@field __base dreamwork.std.hash.SHA512
---@field digest_size integer
---@field block_size integer
---@overload fun(): dreamwork.std.hash.SHA512
local SHA512Class = std.class.create( SHA512 )
hash.SHA512 = SHA512Class

-- SHA512Class.digest_size = 32
-- SHA512Class.block_size = 64

-- TODO: implement (example: md5)
