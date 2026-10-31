local glua_util = util

---@class dreamwork.std
local std = dreamwork.std

local pack = std.pack
local pack_readUInt32LE = pack.readUInt32LE

--- [SHARED AND MENU]
---
--- The lzma format is a lossless data compression algorithm that is used to compress large files.
---
---@class dreamwork.std.lzma
---@field PROPS_SIZE number The size of the lzma properties in bytes.
local lzma = { PROPS_SIZE = 5 }
std.lzma = lzma

lzma.compress = glua_util.Compress or function() return "" end
lzma.decompress = glua_util.Decompress or function() return "" end

--- [SHARED AND MENU]
---
--- Returns the decompressed size of the given string.
---
---@param str string Compressed string.
---@return integer size The decompressed size in bytes.
---@nodiscard
function lzma.size( str )
    return pack_readUInt32LE( str, 6 )
end

-- https://holylib.raphaelit7.com/util.AsyncCompress
-- https://holylib.raphaelit7.com/util.AsyncDecompress
