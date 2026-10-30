---@meta _

--- [SHARED AND MENU]
---
--- Lempel–Ziv–Welch (LZW) is a universal lossless compression algorithm created by Abraham Lempel, Jacob Ziv, and Terry Welch.
---
---@class lzw
lzw = {}

--- [SHARED AND MENU]
---
--- Compresses a string using variable-width LZW, the format is set by the options.
---
---@param raw_data string The string to compress.
---@param options? lzw.Options The format options.
---@return string compressed_data The compressed string.
---@nodiscard
function lzw.compress(raw_data, options) end

--- [SHARED AND MENU]
---
--- Decompresses a variable-width LZW string, the options must match the compression ones.
---
--- Without an end code the bits that do not form a whole code are ignored,
--- so formats with codes narrower than a character should use one.
---
---@param compressed_data string The string to decompress.
---@param options? lzw.Options The format options.
---@return string decompressed_data The decompressed string.
---@nodiscard
function lzw.decompress(compressed_data, options) end
