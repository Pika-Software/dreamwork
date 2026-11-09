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
---@param options deflate.Options? The compression options.
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
---@param dictionary string? The preset dictionary, required if the data was compressed with one.
---@return string decompressed_data The decompressed string.
---@return integer end_position The position of the first byte after the stream.
---@nodiscard
function zlib.decompress(compressed_data, dictionary) end

--- [SHARED AND MENU]
---
--- The zlib stream compressor object.
---
---@class zlib.Compressor : deflate.Compressor
---@field __class zlib.CompressorClass
---@field protected header string
---@field protected checksum Adler32 The checksum of the input.
local Compressor = {}

---@param options deflate.Options? The compression options.
---@protected
function Compressor:__init(options) end

--- [SHARED AND MENU]
---
--- Drops all input and output, the next update starts a new stream with the same options.
---
---@return zlib.Compressor self
function Compressor:reset() end

--- [SHARED AND MENU]
---
--- Adds the string to the stream.
---
--- Input is compressed in parts of at least 32768 bytes,
--- the output is the same as `zlib.compress` of all input.
---
---@param raw_data string The string to add.
---@return zlib.Compressor self
function Compressor:update(raw_data) end

--- [SHARED AND MENU]
---
--- Compresses all input and returns the zlib stream.
---
--- The stream is reset after this, so the compressor can be used for the next stream.
---
---@return string compressed_data
---@nodiscard
function Compressor:flush() end

--- [SHARED AND MENU]
---
--- The class used to create new zlib stream compressors.
---
--- Compresses the data added by `update` parts into one zlib stream,
--- the same as `zlib.compress` of all of them together.
---
--- ```lua
--- local compressor = zlib.Compressor( { level = 9 } )
--- compressor:update( "hello, " ):update( "world" )
--- local compressed_data = compressor:flush()
--- ```
---
---@class zlib.CompressorClass : zlib.Compressor, deflate.CompressorClass
---@field __base zlib.Compressor
---@overload fun( options: deflate.Options? ): zlib.Compressor
local CompressorClass = {}

zlib.Compressor = CompressorClass

--- [SHARED AND MENU]
---
--- The zlib stream decompressor object.
---
---@class zlib.Decompressor : deflate.Decompressor
---@field __class zlib.DecompressorClass
---@field protected dictionary_checksum integer | nil The Adler-32 checksum of the preset dictionary.
---@field protected header_data string | nil The input collected until the header is complete, `nil` after the header.
local Decompressor = {}

---@param dictionary string? The preset dictionary, required if the data was compressed with one.
---@protected
function Decompressor:__init(dictionary) end

--- [SHARED AND MENU]
---
--- Drops all input and output, the next update starts a new stream with the same dictionary.
---
---@return zlib.Decompressor self
function Decompressor:reset() end

--- [SHARED AND MENU]
---
--- Adds the compressed string to the stream.
---
--- Throws an error on malformed data and resets the decompressor; call via `pcall()` when processing untrusted input.
---
---@param compressed_data string The next part of the zlib stream.
---@return zlib.Decompressor self
function Decompressor:update(compressed_data) end

--- [SHARED AND MENU]
---
--- Decodes all input, checks the checksum and returns the decompressed data.
---
--- The stream is reset after this, so the decompressor can be used for the next stream.
---
--- Throws an error on malformed or truncated data, or if the checksum does not match;
--- call via `pcall()` when processing untrusted input.
---
---@return string decompressed_data The decompressed string.
---@return string remaining_data The data after the end of the stream.
---@nodiscard
function Decompressor:flush() end

--- [SHARED AND MENU]
---
--- The class used to create new zlib stream decompressors.
---
--- Decompresses a zlib stream added by `update` parts, the same as `zlib.decompress` of all of them together.
---
--- ```lua
--- local decompressor = zlib.Decompressor()
--- decompressor:update( part1 ):update( part2 )
--- local decompressed_data = decompressor:flush()
--- ```
---
---@class zlib.DecompressorClass : zlib.Decompressor, deflate.DecompressorClass
---@field __base zlib.Decompressor
---@overload fun( dictionary: string? ): zlib.Decompressor
local DecompressorClass = {}

zlib.Decompressor = DecompressorClass
