---@meta _

--- [SHARED AND MENU]
---
--- zlib is a data format that wraps a DEFLATE stream with a 2 byte header and an Adler-32 checksum.
---
--- Produces and consumes [zlib](https://www.rfc-editor.org/rfc/rfc1950) streams
--- compatible with zlib's `compress` / `uncompress`.
---
---@class zlib
zlib = {}

--- [SHARED AND MENU]
---
--- Compresses a string into a zlib stream.
---
---@param raw_data string The string to compress.
---@param options? deflate.Options The compression options.
---@return string compressed_data The compressed string.
---@nodiscard
function zlib.compress(raw_data, options) end

--- [SHARED AND MENU]
---
--- Decompresses a zlib stream.
---
--- Throws an error on malformed or truncated data, or if the checksum does not match;
--- call via `pcall()` when processing untrusted input.
---
---@param compressed_data string The zlib stream to decompress.
---@param dictionary? string The preset dictionary, required if the data was compressed with one.
---@return string decompressed_data The decompressed string.
---@return integer end_position The position of the first byte after the stream.
---@nodiscard
function zlib.decompress(compressed_data, dictionary) end
