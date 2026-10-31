---@meta _

--- [SHARED AND MENU]
---
--- DEFLATE is a lossless compression format that combines LZ77 and Huffman coding, it is used by zlib, gzip, PNG and ZIP.
---
--- Produces and consumes raw [DEFLATE](https://www.rfc-editor.org/rfc/rfc1951) streams (no header, no checksum)
--- compatible with zlib's `deflate` / `inflate` with negative window bits, see `zlib` for the zlib format.
---
---@class deflate
deflate = {}

---@alias deflate.Bytes ffi.cdata* | integer[]

---@class deflate.Writer
---@field bytes deflate.Bytes
---@field length integer
---@field capacity integer
---@field bit_buffer integer
---@field bit_count integer

---@alias deflate.Input string | ffi.cdata*

--- [SHARED AND MENU]
---
--- Compresses a string into a raw DEFLATE stream.
---
---@param raw_data string The string to compress.
---@param options? deflate.Options The compression options.
---@return string compressed_data The compressed string.
---@nodiscard
function deflate.compress(raw_data, options) end

--- [SHARED AND MENU]
---
--- Decompresses a raw DEFLATE stream.
---
--- Throws an error on malformed or truncated data; call via `pcall()` when processing untrusted input.
---
--- The stream may be followed by other data (like the zlib or gzip trailer),
--- the second return value is the position right after the stream.
---
---@param compressed_data string The DEFLATE stream to decompress.
---@param dictionary? string The preset dictionary the data was compressed with.
---@param start_position? integer The position of the stream in the string, `1` by default.
---@return string decompressed_data The decompressed string.
---@return integer end_position The position of the first byte after the stream.
---@nodiscard
function deflate.decompress(compressed_data, dictionary, start_position) end
