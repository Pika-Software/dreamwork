---@meta _

--- [SHARED AND MENU]
---
--- The lzma format is a lossless data compression algorithm that is used to compress large files.
---
---@class lzma
---@field PROPS_SIZE number The size of the lzma properties in bytes.
lzma = {}

lzma.PROPS_SIZE = 5

--- [SHARED AND MENU]
---
--- Returns the decompressed size of the given string.
---
---@param str string Compressed string.
---@return integer size The decompressed size in bytes.
---@nodiscard
function lzma.size(str) end
