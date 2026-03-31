local _G = _G
local std = _G.dreamwork.std
---@class dreamwork.std.compress
local compress = std.compress

local pack_readUInt32 = std.pack.readUInt32
local glua_util = _G.util

--- [SHARED AND MENU]
---
--- The lzma format is a lossless data compression algorithm that is used to compress large files.
---
---@class dreamwork.std.compress.lzma
---@field PROPS_SIZE number The size of the lzma properties in bytes.
local lzma = compress.lzma or { PROPS_SIZE = 5 }
compress.lzma = lzma

lzma.compress = glua_util.Compress or function() return "" end
lzma.decompress = glua_util.Decompress or lzma.compress

--- [SHARED AND MENU]
---
--- Returns the decompressed size of the given string.
---
---@param str string Compressed string.
---@return integer size The decompressed size in bytes.
function lzma.size( str )
    return pack_readUInt32( str, false, 6 ) or 0
end
