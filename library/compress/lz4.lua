---@meta _

--- [SHARED AND MENU]
---
--- LZ4 is lossless compression algorithm, providing compression speed > 500 MB/s per core (>0.15 Bytes/cycle).
---
--- [Source Code](https://github.com/RiskoZS/llz4)
---
--- Author: [RiskoZS](https://github.com/RiskoZS)
---
--- Edited by Unknown Developer
---
---@class lz4
lz4 = {}

--- [SHARED AND MENU]
---
--- Compresses a string using the LZ4 block format.
---
---@param data string The string to compress.
---@param acceleration? integer A positive integer, defaults to 1. Higher values may increase the compression speed, especially on incompressible data, at the cost of compression efficiency.
---@return string The compressed data as a string.
---@nodiscard
function lz4.compress(data, acceleration) end

--- [SHARED AND MENU]
---
--- Decompresses a string that was compressed using the LZ4 block format. If any
--- issue is encountered during decompression, this function will throw an
--- error; call via `pcall()` when processing untrusted input.
---
---@param data string The string to decompress.
---@return string The decompressed string.
---@nodiscard
function lz4.decompress(data) end
