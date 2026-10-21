---@meta holylib.util


---@class garrysmod.util
util = {}

--- [SHARED AND MENU]
---
--- Compresses the given data using [LZ4](https://github.com/lz4/lz4).
---
---@param decompressed_data string
---@return string compressed_data
function util.CompressLZ4( decompressed_data ) end

--- [SHARED AND MENU]
---
--- Decompresses the given data using [LZ4](https://github.com/lz4/lz4).
---
---@param compressed_data string
---@return string decompressed_data
function util.DecompressLZ4( compressed_data ) end
