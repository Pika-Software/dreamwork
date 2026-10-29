---@meta _

--- [SHARED AND MENU]
---
--- Lempel–Ziv–Welch (LZW) is a universal lossless compression algorithm created by Abraham Lempel, Jacob Ziv, and Terry Welch.
---
--- [Source Code](https://github.com/Rochet2/lualzw)
---
--- Author: [Rochet2](https://github.com/Rochet2)
---
--- Edited by Unknown Developer
---
---@class lzw
lzw = {}

--- [SHARED AND MENU]
---
--- Compresses a string using LZW compression.
---
---@param raw_data string The string to compress.
---@param forced? boolean If `true`, compression will ignore the excess length of compressed data relative to uncompressed data. By default: `true`
---@return string | nil compressed_data The compressed string or `nil` if the compression fails.
---@return nil | string error_message The error message or `nil` if the compression succeeds.
---@nodiscard
function lzw.compress(raw_data, forced) end

--- [SHARED AND MENU]
---
--- Decompresses a string using LZW compression.
---
---@param encoded_data string The string to decompress.
---@return string | nil decompressed_data The decompressed string or `nil` if the decompression fails.
---@return nil | string error_message The error message or `nil` if the decompression succeeds.
---@nodiscard
function lzw.decompress(encoded_data) end
