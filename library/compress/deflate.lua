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

---@class deflate.State : deflate.Writer
---@field position integer The index of the next byte to compress.
---@field block_first integer The index of the first byte of the unfinished block, `< 1` if it is not kept anymore.
---@field item_count integer The number of items of the unfinished block in `items`.
---@field hash_end integer The index of the first position that is not in the hash chains yet.
---@field match_available boolean Lazy matching: the byte before `position` waits for a decision.
---@field match_length integer Lazy matching: the length of the match at the byte before `position`.
---@field match_start integer Lazy matching: the start of the match at the byte before `position`.
---@field base integer The base of the positions in the hash chains.
---@field settings table The settings of the compression level.
---@field strategy integer

--- [SHARED AND MENU]
---
--- Compresses a string into a raw DEFLATE stream.
---
---@param raw_data string The string to compress.
---@param options deflate.Options? The compression options.
---@return string compressed_data The compressed string.
---@nodiscard
function deflate.compress(raw_data, options) end

---@class deflate.Stream : deflate.State
---@field level integer
---@field dictionary string | nil
---@field data string The kept bytes: up to 65535 bytes before `position` and the bytes that are not compressed yet.
---@field pending string[] The input that is not added to `data` yet.
---@field pending_count integer
---@field pending_length integer
---@field output string[] The compressed data that is not read yet.
---@field output_count integer

--- [SHARED AND MENU]
---
--- The DEFLATE stream compressor object.
---
---@class deflate.Compressor : Object, deflate.Stream
---@field __class deflate.CompressorClass
local Compressor = {}

---@param options deflate.Options? The compression options.
---@protected
function Compressor:__init(options) end

--- [SHARED AND MENU]
---
--- Drops all input and output, the next update starts a new stream with the same options.
---
---@return deflate.Compressor self
function Compressor:reset() end

--- [SHARED AND MENU]
---
--- Adds the string to the stream.
---
--- Input is compressed in parts of at least 32768 bytes,
--- the last 258 bytes always wait for more input, since a match can continue into it.
---
--- The output is the same as `deflate.compress` of all input,
--- unless another stream or `deflate.compress` is used between the updates,
--- then the unfinished block is written early, which costs a few bytes.
---
---@param raw_data string The string to add.
---@return deflate.Compressor self
function Compressor:update(raw_data) end

--- [SHARED AND MENU]
---
--- Compresses all input, writes the last block and returns the compressed data.
---
--- The stream is reset after this, so the compressor can be used for the next stream.
---
---@return string compressed_data
---@nodiscard
function Compressor:flush() end

--- [SHARED AND MENU]
---
--- The class used to create new DEFLATE stream compressors.
---
--- Compresses the data added by `update` parts into one raw DEFLATE stream,
--- the same as `deflate.compress` of all of them together.
---
--- ```lua
--- local compressor = deflate.Compressor( { level = 9 } )
--- compressor:update( "hello, " ):update( "world" )
--- local compressed_data = compressor:flush()
--- ```
---
---@class deflate.CompressorClass : deflate.Compressor, Class
---@field __base deflate.Compressor
---@overload fun( options: deflate.Options? ): deflate.Compressor
local CompressorClass = {}

deflate.Compressor = CompressorClass

---@class deflate.InflateState
---@field bytes deflate.Bytes The output, starting with the dictionary.
---@field length integer
---@field capacity integer
---@field bit_buffer integer
---@field bit_count integer
---@field block integer `0` before a block header, `1` in a stored block, `2` in a block of codes, `3` after the last block.
---@field is_last boolean The current block is the last one.
---@field stored_size integer The number of bytes left in the stored block.
---@field literals integer[] The literal/length decoding table of the current block.
---@field distances integer[] The distance decoding table of the current block.
---@field literal_table integer[] The literal/length table for dynamic blocks.
---@field distance_table integer[] The distance table for dynamic blocks.

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
---@param dictionary string? The preset dictionary the data was compressed with.
---@param start_position integer? The position of the stream in the string, `1` by default.
---@return string decompressed_data The decompressed string.
---@return integer end_position The position of the first byte after the stream.
---@nodiscard
function deflate.decompress(compressed_data, dictionary, start_position) end

---@class deflate.InflateStream : deflate.InflateState
---@field dictionary string | nil
---@field dictionary_length integer
---@field data string The input that is not decoded yet, after the last block it is the data after the stream.
---@field pending string[] The input that is not added to `data` yet.
---@field pending_count integer
---@field pending_length integer

--- [SHARED AND MENU]
---
--- The DEFLATE stream decompressor object.
---
---@class deflate.Decompressor : Object, deflate.InflateStream
---@field __class deflate.DecompressorClass
local Decompressor = {}

---@param dictionary string? The preset dictionary the data was compressed with.
---@protected
function Decompressor:__init(dictionary) end

--- [SHARED AND MENU]
---
--- Drops all input and output, the next update starts a new stream with the same dictionary.
---
---@return deflate.Decompressor self
function Decompressor:reset() end

--- [SHARED AND MENU]
---
--- Adds the compressed string to the stream.
---
--- Input is decoded in parts of at least 32768 bytes, the decompressor is reset on malformed data.
---
--- Throws an error on malformed data; call via `pcall()` when processing untrusted input.
---
---@param compressed_data string The next part of the DEFLATE stream.
---@return deflate.Decompressor self
function Decompressor:update(compressed_data) end

--- [SHARED AND MENU]
---
--- Decodes all input and returns the decompressed data.
---
--- The stream is reset after this, so the decompressor can be used for the next stream.
---
--- Throws an error on malformed or truncated data; call via `pcall()` when processing untrusted input.
---
---@return string decompressed_data The decompressed string.
---@return string remaining_data The data after the end of the stream (like the zlib or gzip trailer).
---@nodiscard
function Decompressor:flush() end

--- [SHARED AND MENU]
---
--- The class used to create new DEFLATE stream decompressors.
---
--- Decompresses a raw DEFLATE stream added by `update` parts, the same as `deflate.decompress` of all of them together.
---
--- ```lua
--- local decompressor = deflate.Decompressor()
--- decompressor:update( part1 ):update( part2 )
--- local decompressed_data = decompressor:flush()
--- ```
---
---@class deflate.DecompressorClass : deflate.Decompressor, Class
---@field __base deflate.Decompressor
---@overload fun( dictionary: string? ): deflate.Decompressor
local DecompressorClass = {}

deflate.Decompressor = DecompressorClass
