---@class dreamwork.std
local std = dreamwork.std

local pack_readUInt32 = std.buffer.readUInt32
local glua_util = util

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- The lzma format is a lossless data compression algorithm that is used to compress large files.
---
---@class dreamwork.std.lzma
---@field PROPS_SIZE number The size of the lzma properties in bytes.
local lzma = std.lzma or { PROPS_SIZE = 5 }
std.lzma = lzma

lzma.compress = glua_util.Compress or function() return "" end
lzma.decompress = glua_util.Decompress or lzma.compress

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns the decompressed size of the given string.
---
---@param str string Compressed string.
---@return integer size The decompressed size in bytes.
function lzma.size( str )
    return pack_readUInt32( str, false, 6 ) or 0
end
