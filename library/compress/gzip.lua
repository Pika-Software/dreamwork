---@meta _

--- [SHARED AND MENU]
---
--- gzip is a file format that wraps a DEFLATE stream with a header (file name, comment, time)
--- and a CRC-32 checksum with the size of the original data.
---
--- Produces and consumes [gzip](https://www.rfc-editor.org/rfc/rfc1952) streams
--- compatible with the `gzip` tool, `Content-Encoding: gzip` and zlib's `gzopen` / `inflateInit2`.
---
---@class gzip
gzip = {}

--- [SHARED AND MENU]
---
--- Compresses a string into a gzip stream.
---
---@param raw_data string The string to compress.
---@param options gzip.Options? The compression options.
---@return string compressed_data The compressed string.
---@nodiscard
function gzip.compress(raw_data, options) end

--- [SHARED AND MENU]
---
--- Decompresses a gzip stream.
---
--- Concatenated gzip members are decompressed into one string, like the `gzip` tool does,
--- data after the last member that is not another gzip member is left unread.
---
--- Throws an error on malformed or truncated data, or if the checksum or the size does not match;
--- call via `pcall()` when processing untrusted input.
---
---@param compressed_data string The gzip stream to decompress.
---@param start_position integer? The position of the stream in the string, `1` by default.
---@return string decompressed_data The decompressed string.
---@return integer end_position The position of the first byte after the stream.
---@return gzip.Header header The header of the first member.
---@nodiscard
function gzip.decompress(compressed_data, start_position) end
