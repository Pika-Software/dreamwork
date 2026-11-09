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

--- [SHARED AND MENU]
---
--- The gzip stream compressor object.
---
---@class gzip.Compressor : deflate.Compressor
---@field __class gzip.CompressorClass
---@field protected header string
---@field protected checksum checksum.CRC32 The checksum of the input.
---@field protected size integer The size of the input.
local Compressor = {}

---@param options gzip.Options? The compression options.
---@protected
function Compressor:__init(options) end

--- [SHARED AND MENU]
---
--- Drops all input and output, the next update starts a new stream with the same options.
---
---@return gzip.Compressor self
function Compressor:reset() end

--- [SHARED AND MENU]
---
--- Adds the string to the stream.
---
--- Input is compressed in parts of at least 32768 bytes,
--- the output is the same as `gzip.compress` of all input.
---
---@param raw_data string The string to add.
---@return gzip.Compressor self
function Compressor:update(raw_data) end

--- [SHARED AND MENU]
---
--- Compresses all input and returns the gzip stream.
---
--- The stream is reset after this, so the compressor can be used for the next stream.
---
---@return string compressed_data
---@nodiscard
function Compressor:flush() end

--- [SHARED AND MENU]
---
--- The class used to create new gzip stream compressors.
---
--- Compresses the data added by `update` parts into one gzip member,
--- the same as `gzip.compress` of all of them together.
---
--- ```lua
--- local compressor = gzip.Compressor( { name = "log.txt" } )
--- compressor:update( "hello, " ):update( "world" )
--- local compressed_data = compressor:flush()
--- ```
---
---@class gzip.CompressorClass : gzip.Compressor, deflate.CompressorClass
---@field __base gzip.Compressor
---@overload fun( options: gzip.Options? ): gzip.Compressor
local CompressorClass = {}

gzip.Compressor = CompressorClass

--- [SHARED AND MENU]
---
--- The gzip stream decompressor object.
---
---@class gzip.Decompressor : deflate.Decompressor
---@field __class gzip.DecompressorClass
---@field protected header_data string | nil The input collected until the header is complete, `nil` after the header.
---@field protected header gzip.Header | nil The header of the first member.
local Decompressor = {}

--- [SHARED AND MENU]
---
--- Drops all input and output, the next update starts a new stream.
---
---@return gzip.Decompressor self
function Decompressor:reset() end

--- [SHARED AND MENU]
---
--- Adds the compressed string to the stream.
---
--- Throws an error on malformed data and resets the decompressor; call via `pcall()` when processing untrusted input.
---
---@param compressed_data string The next part of the gzip stream.
---@return gzip.Decompressor self
function Decompressor:update(compressed_data) end

--- [SHARED AND MENU]
---
--- Decodes all input, checks the checksum and the size, and returns the decompressed data.
---
--- Concatenated gzip members are decompressed into one string, like `gzip.decompress` does,
--- the members after the first one are decoded here at once.
---
--- The stream is reset after this, so the decompressor can be used for the next stream.
---
--- Throws an error on malformed or truncated data, or if the checksum or the size does not match;
--- call via `pcall()` when processing untrusted input.
---
---@return string decompressed_data The decompressed string.
---@return string remaining_data The data after the end of the stream.
---@return gzip.Header header The header of the first member.
---@nodiscard
function Decompressor:flush() end

--- [SHARED AND MENU]
---
--- The class used to create new gzip stream decompressors.
---
--- Decompresses a gzip stream added by `update` parts, the same as `gzip.decompress` of all of them together.
---
--- ```lua
--- local decompressor = gzip.Decompressor()
--- decompressor:update( part1 ):update( part2 )
--- local decompressed_data, _, header = decompressor:flush()
--- ```
---
---@class gzip.DecompressorClass : gzip.Decompressor, deflate.DecompressorClass
---@field __base gzip.Decompressor
---@overload fun(): gzip.Decompressor
local DecompressorClass = {}

gzip.Decompressor = DecompressorClass
