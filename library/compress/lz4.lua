---@meta _

--- [SHARED AND MENU]
---
--- LZ4 is lossless compression algorithm, providing compression speed > 500 MB/s per core (>0.15 Bytes/cycle).
---
--- Produces and consumes raw [LZ4 blocks](https://github.com/lz4/lz4/blob/dev/doc/lz4_Block_format.md)
--- (no frame header, no checksum, no stored size) compatible with the reference `LZ4_compress_fast` / `LZ4_decompress_safe`.
---
---@class lz4
lz4 = {}

--- [SHARED AND MENU]
---
--- Compresses a string into a raw LZ4 block.
---
--- The block does not store the uncompressed size, keep it alongside
--- the block if the receiving side needs to know it in advance.
---
---@param data string The string to compress.
---@param acceleration? integer A positive integer, defaults to `1`. Higher values may increase the compression speed, especially on incompressible data, at the cost of compression efficiency.
---@return string compressed The compressed data as a string.
---@nodiscard
function lz4.compress(data, acceleration) end

--- [SHARED AND MENU]
---
--- Decompresses a raw LZ4 block.
---
--- Throws an error on malformed input (truncated lengths/literals, offsets pointing
--- before the start of the output, a block not ending with literals); call via `pcall()`
--- when processing untrusted input.
---
--- LZ4 blocks carry no checksum, so corrupted data may still decode into wrong output,
--- and a block cut exactly at a sequence boundary is indistinguishable from a shorter valid block.
---
---@param data string The LZ4 block to decompress.
---@return string decompressed The decompressed string.
---@nodiscard
function lz4.decompress(data) end
