---@class dreamwork.std
local std = dreamwork.std

local bitpack = std.bitpack
local bitpack_get = bitpack.get
local bitpack_readUInt = bitpack.readUInt

local bytepack = std.bytepack
local bytepack_readUInt32BE = bytepack.readUInt32BE
local bytepack_writeUInt32BE = bytepack.writeUInt32BE

local string = std.string
local string_sub = string.sub
local string_byte = string.byte
local string_char = string.char

local class = std.class

local Adler32 = std.Adler32
local Adler32_digest = Adler32.digest

local deflate = std.deflate
local deflate_compress = deflate.compress
local deflate_decompress = deflate.decompress

local DeflateCompressor = deflate.Compressor.__base
local DeflateDecompressor = deflate.Decompressor.__base

local error = std.error


--- [SHARED AND MENU]
---
--- zlib is a data format that wraps a DEFLATE stream with a 2 byte header and an Adler-32 checksum.
---
--- Produces and consumes [zlib](https://www.rfc-editor.org/rfc/rfc1950) streams
--- compatible with zlib's `compress` / `uncompress`.
---
---@class dreamwork.std.zlib
local zlib = {}
std.zlib = zlib

--- Returns the zlib header for the options.
---
---@param options dreamwork.std.deflate.Options?
---@return string header
local function write_header( options )
    local strategy, dictionary
    local level = 6

    if options ~= nil then
        strategy, dictionary = options.strategy, options.dictionary
        level = options.level or level
    end

    -- the compression level is only informative, it is set the same way zlib does
    local level_flags
    if level < 2 or strategy == "huffman_only" or strategy == "rle" then
        level_flags = 0
    elseif level < 6 then
        level_flags = 1
    elseif level == 6 then
        level_flags = 2
    else
        level_flags = 3
    end

    -- deflate with a 32K window
    local flg = level_flags * 0x40

    if dictionary ~= nil then
        flg = flg + 0x20
    end

    -- the header as a big endian 16-bit integer is a multiple of 31
    local header = string_char( 0x78, flg + 31 - (0x7800 + flg) % 31 )

    if dictionary ~= nil then
        header = header .. string_char( bytepack_writeUInt32BE( Adler32_digest( dictionary ) ) )
    end

    return header
end

--- Reads the zlib header.
---
---@param compressed_data string
---@param dictionary_checksum integer | nil The Adler-32 checksum of the preset dictionary, `nil` if there is none.
---@return integer | nil start_position The position of the DEFLATE stream, `nil` if the header is truncated or invalid.
---@return string? error_message The error message, `nil` if the header is truncated.
---@return boolean? has_dictionary `true` if the stream uses the preset dictionary.
local function read_header( compressed_data, dictionary_checksum )
    local cmf, flg = string_byte( compressed_data, 1, 2 )
    if flg == nil then
        return nil
    end

    if (cmf * 0x100 + flg) % 31 ~= 0 then
        return nil, "corrupt zlib data: invalid header checksum"
    end

    if bitpack_readUInt( cmf, 0, 4 ) ~= 8 then
        return nil, "corrupt zlib data: unknown compression method"
    end

    if bitpack_readUInt( cmf, 4, 4 ) > 7 then
        return nil, "corrupt zlib data: invalid window size"
    end

    if not bitpack_get( flg, 5 ) then
        return 3, nil, false
    end

    local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( compressed_data, 3, 6 )
    if uint8_4 == nil then
        return nil
    end

    if dictionary_checksum == nil then
        return nil, "zlib data requires a preset dictionary"
    end

    if bytepack_readUInt32BE( uint8_1, uint8_2, uint8_3, uint8_4 ) ~= dictionary_checksum then
        return nil, "zlib data requires a different preset dictionary"
    end

    return 7, nil, true
end

--- [SHARED AND MENU]
---
--- Compresses a string into a zlib stream.
---
---@param raw_data string The string to compress.
---@param options dreamwork.std.deflate.Options? The compression options.
---@return string compressed_data The compressed string.
---@nodiscard
function zlib.compress( raw_data, options )
    return write_header( options ) .. deflate_compress( raw_data, options ) .. string_char( bytepack_writeUInt32BE( Adler32_digest( raw_data ) ) )
end

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
function zlib.decompress( compressed_data, dictionary )
    local start_position, error_message, has_dictionary = read_header( compressed_data, dictionary ~= nil and Adler32_digest( dictionary ) or nil )
    if start_position == nil then
        error( error_message or "corrupt zlib data: truncated header", 2 )
    end

    local decompressed_data, end_position = deflate_decompress( compressed_data, has_dictionary and dictionary or nil, start_position )

    local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( compressed_data, end_position, end_position + 3 )
    if uint8_4 == nil then
        error( "corrupt zlib data: truncated checksum", 2 )
    end

    if bytepack_readUInt32BE( uint8_1, uint8_2, uint8_3, uint8_4 ) ~= Adler32_digest( decompressed_data ) then
        error( "corrupt zlib data: checksum mismatch", 2 )
    end

    return decompressed_data, end_position + 4
end

--- [SHARED AND MENU]
---
--- The zlib stream compressor object.
---
---@class dreamwork.std.zlib.Compressor : dreamwork.std.deflate.Compressor
---@field __class dreamwork.std.zlib.CompressorClass
---@field protected header string
---@field protected checksum dreamwork.std.Adler32 The checksum of the input.
local Compressor = class.base( "ZlibCompressor", false, deflate.Compressor )

---@param options dreamwork.std.deflate.Options? The compression options.
---@protected
function Compressor:__init( options )
    self.header = write_header( options )
    self.checksum = Adler32()

    DeflateCompressor.__init( self, options )
end

--- [SHARED AND MENU]
---
--- Drops all input and output, the next update starts a new stream with the same options.
---
---@return dreamwork.std.zlib.Compressor self
function Compressor:reset()
    self.checksum:reset()
    DeflateCompressor.reset( self )
    return self
end

--- [SHARED AND MENU]
---
--- Adds the string to the stream.
---
--- Input is compressed in parts of at least 32768 bytes,
--- the output is the same as `zlib.compress` of all input.
---
---@param raw_data string The string to add.
---@return dreamwork.std.zlib.Compressor self
function Compressor:update( raw_data )
    self.checksum:update( raw_data )
    DeflateCompressor.update( self, raw_data )
    return self
end

--- [SHARED AND MENU]
---
--- Compresses all input and returns the zlib stream.
---
--- The stream is reset after this, so the compressor can be used for the next stream.
---
---@return string compressed_data
---@nodiscard
function Compressor:flush()
    local checksum = self.checksum:digest()
    return self.header .. DeflateCompressor.flush( self ) .. string_char( bytepack_writeUInt32BE( checksum ) )
end

--- [SHARED AND MENU]
---
--- The class used to create new zlib stream compressors.
---
--- Compresses the data added by `update` parts into one zlib stream,
--- the same as `zlib.compress` of all of them together.
---
--- ```lua
--- local compressor = std.zlib.Compressor( { level = 9 } )
--- compressor:update( "hello, " ):update( "world" )
--- local compressed_data = compressor:flush()
--- ```
---
---@class dreamwork.std.zlib.CompressorClass : dreamwork.std.zlib.Compressor, dreamwork.std.deflate.CompressorClass
---@field __base dreamwork.std.zlib.Compressor
---@overload fun( options: dreamwork.std.deflate.Options? ): dreamwork.std.zlib.Compressor
local CompressorClass = class.create( Compressor )
zlib.Compressor = CompressorClass

--- [SHARED AND MENU]
---
--- The zlib stream decompressor object.
---
---@class dreamwork.std.zlib.Decompressor : dreamwork.std.deflate.Decompressor
---@field __class dreamwork.std.zlib.DecompressorClass
---@field protected dictionary_checksum integer | nil The Adler-32 checksum of the preset dictionary.
---@field protected header_data string | nil The input collected until the header is complete, `nil` after the header.
local Decompressor = class.base( "ZlibDecompressor", false, deflate.Decompressor )

---@param dictionary string? The preset dictionary, required if the data was compressed with one.
---@protected
function Decompressor:__init( dictionary )
    if dictionary ~= nil then
        self.dictionary_checksum = Adler32_digest( dictionary )
    end

    DeflateDecompressor.__init( self, dictionary )
end

--- [SHARED AND MENU]
---
--- Drops all input and output, the next update starts a new stream with the same dictionary.
---
---@return dreamwork.std.zlib.Decompressor self
function Decompressor:reset()
    self.header_data = ""
    DeflateDecompressor.reset( self )
    return self
end

--- [SHARED AND MENU]
---
--- Adds the compressed string to the stream.
---
--- Throws an error on malformed data and resets the decompressor; call via `pcall()` when processing untrusted input.
---
---@param compressed_data string The next part of the zlib stream.
---@return dreamwork.std.zlib.Decompressor self
function Decompressor:update( compressed_data )
    local header_data = self.header_data

    if header_data ~= nil then
        header_data = header_data .. compressed_data

        local start_position, error_message = read_header( header_data, self.dictionary_checksum )
        if start_position == nil then
            if error_message ~= nil then
                self:reset()
                error( error_message, 2 )
            end

            self.header_data = header_data
            return self
        end

        self.header_data = nil
        compressed_data = string_sub( header_data, start_position )
    end

    DeflateDecompressor.update( self, compressed_data )
    return self
end

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
function Decompressor:flush()
    if self.header_data ~= nil then
        self:reset()
        error( "corrupt zlib data: truncated header", 2 )
    end

    local decompressed_data, remaining_data = DeflateDecompressor.flush( self )

    local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( remaining_data, 1, 4 )
    if uint8_4 == nil then
        error( "corrupt zlib data: truncated checksum", 2 )
    end

    if bytepack_readUInt32BE( uint8_1, uint8_2, uint8_3, uint8_4 ) ~= Adler32_digest( decompressed_data ) then
        error( "corrupt zlib data: checksum mismatch", 2 )
    end

    return decompressed_data, string_sub( remaining_data, 5 )
end

--- [SHARED AND MENU]
---
--- The class used to create new zlib stream decompressors.
---
--- Decompresses a zlib stream added by `update` parts, the same as `zlib.decompress` of all of them together.
---
--- ```lua
--- local decompressor = std.zlib.Decompressor()
--- decompressor:update( part1 ):update( part2 )
--- local decompressed_data = decompressor:flush()
--- ```
---
---@class dreamwork.std.zlib.DecompressorClass : dreamwork.std.zlib.Decompressor, dreamwork.std.deflate.DecompressorClass
---@field __base dreamwork.std.zlib.Decompressor
---@overload fun( dictionary: string? ): dreamwork.std.zlib.Decompressor
local DecompressorClass = class.create( Decompressor )
zlib.Decompressor = DecompressorClass
