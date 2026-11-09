---@class dreamwork.std
local std = dreamwork.std

local bitpack = std.bitpack
local bitpack_get = bitpack.get

local bytepack = std.bytepack
local bytepack_readUInt16LE = bytepack.readUInt16LE
local bytepack_writeUInt16LE = bytepack.writeUInt16LE
local bytepack_readUInt32LE = bytepack.readUInt32LE
local bytepack_writeUInt32LE = bytepack.writeUInt32LE

local string = std.string
local string_sub = string.sub
local string_byte = string.byte
local string_char = string.char
local string_find = string.find

local table = std.table
local table_concat = table.concat

local class = std.class

local CRC32 = std.CRC32
local CRC32_digest = CRC32.digest

local deflate = std.deflate
local deflate_compress = deflate.compress
local deflate_decompress = deflate.decompress

local DeflateCompressor = deflate.Compressor.__base
local DeflateDecompressor = deflate.Decompressor.__base

local error = std.error


--- [SHARED AND MENU]
---
--- gzip is a file format that wraps a DEFLATE stream with a header (file name, comment, time)
--- and a CRC-32 checksum with the size of the original data.
---
--- Produces and consumes [gzip](https://www.rfc-editor.org/rfc/rfc1952) streams
--- compatible with the `gzip` tool, `Content-Encoding: gzip` and zlib's `gzopen` / `inflateInit2`.
---
---@class dreamwork.std.gzip
local gzip = {}
std.gzip = gzip

---@param value any
---@param name string
---@return string | nil
local function check_zero_terminated( value, name )
    if value == nil then
        return nil
    end

    if string_find( value, "\0", 1, true ) ~= nil then
        error( "options." .. name .. " must not contain zero bytes", 4 )
    end

    return value
end

---@type dreamwork.std.deflate.Options
local deflate_options = {}

-- the operating system code of the runtime, `11` (NTFS) on Windows, `3` (Unix) on Linux and macOS like the `gzip` tool writes there
---@type integer
local OS_CODE = 255

if std.SYSTEM_WINDOWS then
    OS_CODE = 11
elseif std.SYSTEM_LINUX or std.SYSTEM_OSX then
    OS_CODE = 3
end

--- Returns the gzip header for the options, with the options of the DEFLATE stream.
---
---@param options dreamwork.std.gzip.Options?
---@return string header
---@return dreamwork.std.deflate.Options? deflate_options
local function write_header( options )
    local level, mtime, os_code = 6, 0, OS_CODE
    local text, header_crc = false, false
    local name, comment, extra

    ---@type dreamwork.std.deflate.Options | nil
    local stream_options = nil

    if options ~= nil then
        level = options.level or 6

        name = check_zero_terminated( options.name, "name" )
        comment = check_zero_terminated( options.comment, "comment" )

        if options.mtime ~= nil then
            mtime = options.mtime
            if not (mtime % 1 == 0 and mtime >= 0 and mtime <= 0xFFFFFFFF) then
                error( "options.mtime must be an integer from 0 to 4294967295", 3 )
            end

            ---@cast mtime integer
        end

        if options.os ~= nil then
            os_code = options.os
            if not (os_code % 1 == 0 and os_code >= 0 and os_code <= 255) then
                error( "options.os must be an integer from 0 to 255", 3 )
            end
        end

        extra = options.extra
        if extra ~= nil and #extra > 0xFFFF then
            error( "options.extra must be up to 65535 bytes long", 3 )
        end

        text = options.text == true
        header_crc = options.header_crc == true

        deflate_options.level = options.level
        deflate_options.strategy = options.strategy

        stream_options = deflate_options
    end

    local flags = (text and 0x01 or 0) +
        (header_crc and 0x02 or 0) +
        (extra ~= nil and 0x04 or 0) +
        (name ~= nil and 0x08 or 0) +
        (comment ~= nil and 0x10 or 0)

    -- the extra flags are only informative, they are set the same way zlib does
    local extra_flags = 0
    if level == 9 then
        extra_flags = 2
    elseif level == 1 then
        extra_flags = 4
    end

    local uint8_1, uint8_2, uint8_3, uint8_4 = bytepack_writeUInt32LE( mtime )

    ---@type string[]
    local segments = { string_char( 0x1F, 0x8B, 8, flags, uint8_1, uint8_2, uint8_3, uint8_4, extra_flags, os_code ) }
    local segment_count = 1

    if extra ~= nil then
        segments[ segment_count + 1 ] = string_char( bytepack_writeUInt16LE( #extra ) )
        segments[ segment_count + 2 ] = extra
        segment_count = segment_count + 2
    end

    if name ~= nil then
        segments[ segment_count + 1 ] = name
        segments[ segment_count + 2 ] = "\0"
        segment_count = segment_count + 2
    end

    if comment ~= nil then
        segments[ segment_count + 1 ] = comment
        segments[ segment_count + 2 ] = "\0"
        segment_count = segment_count + 2
    end

    if header_crc then
        segment_count = segment_count + 1
        segments[ segment_count ] = string_char( bytepack_writeUInt16LE( CRC32_digest( table_concat( segments, "", 1, segment_count - 1 ) ) % 0x10000 ) )
    end

    return table_concat( segments, "", 1, segment_count ), stream_options
end

--- Returns the gzip trailer: the checksum and the size of the original data.
---
---@param checksum integer
---@param size integer
---@return string trailer
local function write_trailer( checksum, size )
    local crc_1, crc_2, crc_3, crc_4 = bytepack_writeUInt32LE( checksum )
    return string_char( crc_1, crc_2, crc_3, crc_4, bytepack_writeUInt32LE( size % 0x100000000 ) )
end

--- [SHARED AND MENU]
---
--- Compresses a string into a gzip stream.
---
---@param raw_data string The string to compress.
---@param options dreamwork.std.gzip.Options? The compression options.
---@return string compressed_data The compressed string.
---@nodiscard
function gzip.compress( raw_data, options )
    local header, stream_options = write_header( options )
    return header .. deflate_compress( raw_data, stream_options ) .. write_trailer( CRC32_digest( raw_data ), #raw_data )
end

---@param compressed_data string
---@param position integer
---@return string | nil value The value, `nil` if it has no end.
---@return integer position
local function read_zero_terminated( compressed_data, position )
    local zero_position = string_find( compressed_data, "\0", position, true )
    if zero_position == nil then
        return nil, position
    end

    return string_sub( compressed_data, position, zero_position - 1 ), zero_position + 1
end

--- Reads the header of a gzip member.
---
---@param compressed_data string
---@param position integer
---@return dreamwork.std.gzip.Header | nil header The header, `nil` if it is truncated or invalid.
---@return integer | string | nil position The position of the DEFLATE stream, or the error message, `nil` if the header is truncated.
local function read_header( compressed_data, position )
    local id1, id2, method, flags, uint8_1, uint8_2, uint8_3, uint8_4, _, os_code = string_byte( compressed_data, position, position + 9 )
    if os_code == nil then
        return nil
    end

    if id1 ~= 0x1F or id2 ~= 0x8B then
        return nil, "corrupt gzip data: invalid magic number"
    end

    if method ~= 8 then
        return nil, "corrupt gzip data: unknown compression method"
    end

    if flags > 0x1F then
        return nil, "corrupt gzip data: reserved flags are set"
    end

    local header_start = position
    position = position + 10

    local name, comment, extra

    if bitpack_get( flags, 2 ) then
        local length_1, length_2 = string_byte( compressed_data, position, position + 1 )
        if length_2 == nil then
            return nil
        end

        local extra_end = position + 1 + bytepack_readUInt16LE( length_1, length_2 )
        if extra_end > #compressed_data then
            return nil
        end

        extra = string_sub( compressed_data, position + 2, extra_end )
        position = extra_end + 1
    end

    if bitpack_get( flags, 3 ) then
        name, position = read_zero_terminated( compressed_data, position )
        if name == nil then
            return nil
        end
    end

    if bitpack_get( flags, 4 ) then
        comment, position = read_zero_terminated( compressed_data, position )
        if comment == nil then
            return nil
        end
    end

    if bitpack_get( flags, 1 ) then
        local crc_1, crc_2 = string_byte( compressed_data, position, position + 1 )
        if crc_2 == nil then
            return nil
        end

        if bytepack_readUInt16LE( crc_1, crc_2 ) ~= CRC32_digest( string_sub( compressed_data, header_start, position - 1 ) ) % 0x10000 then
            return nil, "corrupt gzip data: header checksum mismatch"
        end

        position = position + 2
    end

    ---@type dreamwork.std.gzip.Header
    local header = {
        name = name,
        comment = comment,
        mtime = bytepack_readUInt32LE( uint8_1, uint8_2, uint8_3, uint8_4 ),
        os = os_code,
        extra = extra,
        text = bitpack_get( flags, 0 )
    }

    return header, position
end

--- Checks the trailer of a gzip member.
---
---@param compressed_data string
---@param position integer The position of the trailer.
---@param decompressed_data string The data of the member.
---@return string? error_message
local function check_trailer( compressed_data, position, decompressed_data )
    local crc_1, crc_2, crc_3, crc_4, size_1, size_2, size_3, size_4 = string_byte( compressed_data, position, position + 7 )
    if size_4 == nil then
        return "corrupt gzip data: truncated trailer"
    end

    if bytepack_readUInt32LE( crc_1, crc_2, crc_3, crc_4 ) ~= CRC32_digest( decompressed_data ) then
        return "corrupt gzip data: checksum mismatch"
    end

    if bytepack_readUInt32LE( size_1, size_2, size_3, size_4 ) ~= #decompressed_data % 0x100000000 then
        return "corrupt gzip data: size mismatch"
    end

    return nil
end

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
---@return dreamwork.std.gzip.Header header The header of the first member.
---@nodiscard
function gzip.decompress( compressed_data, start_position )
    if start_position == nil then
        start_position = 1
    elseif not (start_position % 1 == 0 and start_position >= 1) then
        error( "start_position must be a positive integer", 2 )
    end

    ---@type dreamwork.std.gzip.Header
    local header

    ---@type string[]
    local members = {}
    local member_count = 0

    local position = start_position

    repeat
        local member_header, stream_position = read_header( compressed_data, position )
        if member_header == nil then
            error( stream_position or "corrupt gzip data: truncated header", 2 )
        end

        ---@cast stream_position integer

        if header == nil then
            header = member_header
        end

        local decompressed_data, end_position = deflate_decompress( compressed_data, nil, stream_position )

        local error_message = check_trailer( compressed_data, end_position, decompressed_data )
        if error_message ~= nil then
            error( error_message, 2 )
        end

        member_count = member_count + 1
        members[ member_count ] = decompressed_data

        position = end_position + 8

        local id1, id2 = string_byte( compressed_data, position, position + 1 )
    until id1 ~= 0x1F or id2 ~= 0x8B

    if member_count == 1 then
        return members[ 1 ], position, header
    end

    return table_concat( members, "", 1, member_count ), position, header
end

--- [SHARED AND MENU]
---
--- The gzip stream compressor object.
---
---@class dreamwork.std.gzip.Compressor : dreamwork.std.deflate.Compressor
---@field __class dreamwork.std.gzip.CompressorClass
---@field protected header string
---@field protected checksum dreamwork.std.checksum.CRC32 The checksum of the input.
---@field protected size integer The size of the input.
local Compressor = class.base( "GzipCompressor", false, deflate.Compressor )

---@param options dreamwork.std.gzip.Options? The compression options.
---@protected
function Compressor:__init( options )
    local header, stream_options = write_header( options )

    self.header = header
    self.checksum = CRC32()

    DeflateCompressor.__init( self, stream_options )
end

--- [SHARED AND MENU]
---
--- Drops all input and output, the next update starts a new stream with the same options.
---
---@return dreamwork.std.gzip.Compressor self
function Compressor:reset()
    self.checksum:reset()
    self.size = 0

    DeflateCompressor.reset( self )
    return self
end

--- [SHARED AND MENU]
---
--- Adds the string to the stream.
---
--- Input is compressed in parts of at least 32768 bytes,
--- the output is the same as `gzip.compress` of all input.
---
---@param raw_data string The string to add.
---@return dreamwork.std.gzip.Compressor self
function Compressor:update( raw_data )
    self.checksum:update( raw_data )
    self.size = self.size + #raw_data

    DeflateCompressor.update( self, raw_data )
    return self
end

--- [SHARED AND MENU]
---
--- Compresses all input and returns the gzip stream.
---
--- The stream is reset after this, so the compressor can be used for the next stream.
---
---@return string compressed_data
---@nodiscard
function Compressor:flush()
    local trailer = write_trailer( self.checksum:digest(), self.size )
    return self.header .. DeflateCompressor.flush( self ) .. trailer
end

--- [SHARED AND MENU]
---
--- The class used to create new gzip stream compressors.
---
--- Compresses the data added by `update` parts into one gzip member,
--- the same as `gzip.compress` of all of them together.
---
--- ```lua
--- local compressor = std.gzip.Compressor( { name = "log.txt" } )
--- compressor:update( "hello, " ):update( "world" )
--- local compressed_data = compressor:flush()
--- ```
---
---@class dreamwork.std.gzip.CompressorClass : dreamwork.std.gzip.Compressor, dreamwork.std.deflate.CompressorClass
---@field __base dreamwork.std.gzip.Compressor
---@overload fun( options: dreamwork.std.gzip.Options? ): dreamwork.std.gzip.Compressor
local CompressorClass = class.create( Compressor )
gzip.Compressor = CompressorClass

--- [SHARED AND MENU]
---
--- The gzip stream decompressor object.
---
---@class dreamwork.std.gzip.Decompressor : dreamwork.std.deflate.Decompressor
---@field __class dreamwork.std.gzip.DecompressorClass
---@field protected header_data string | nil The input collected until the header is complete, `nil` after the header.
---@field protected header dreamwork.std.gzip.Header | nil The header of the first member.
local Decompressor = class.base( "GzipDecompressor", false, deflate.Decompressor )

--- [SHARED AND MENU]
---
--- Drops all input and output, the next update starts a new stream.
---
---@return dreamwork.std.gzip.Decompressor self
function Decompressor:reset()
    self.header_data, self.header = "", nil

    DeflateDecompressor.reset( self )
    return self
end

--- [SHARED AND MENU]
---
--- Adds the compressed string to the stream.
---
--- Throws an error on malformed data and resets the decompressor; call via `pcall()` when processing untrusted input.
---
---@param compressed_data string The next part of the gzip stream.
---@return dreamwork.std.gzip.Decompressor self
function Decompressor:update( compressed_data )
    local header_data = self.header_data

    if header_data ~= nil then
        header_data = header_data .. compressed_data

        local header, stream_position = read_header( header_data, 1 )
        if header == nil then
            if stream_position ~= nil then
                self:reset()
                error( stream_position, 2 )
            end

            self.header_data = header_data
            return self
        end

        ---@cast stream_position integer

        self.header_data, self.header = nil, header
        compressed_data = string_sub( header_data, stream_position )
    end

    DeflateDecompressor.update( self, compressed_data )
    return self
end

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
---@return dreamwork.std.gzip.Header header The header of the first member.
---@nodiscard
function Decompressor:flush()
    local header = self.header
    if header == nil then
        self:reset()
        error( "corrupt gzip data: truncated header", 2 )
    end

    local decompressed_data, remaining_data = DeflateDecompressor.flush( self )

    local error_message = check_trailer( remaining_data, 1, decompressed_data )
    if error_message ~= nil then
        error( error_message, 2 )
    end

    local id1, id2 = string_byte( remaining_data, 9, 10 )
    if id1 == 0x1F and id2 == 0x8B then
        local members_data, end_position = gzip.decompress( remaining_data, 9 )
        return decompressed_data .. members_data, string_sub( remaining_data, end_position ), header
    end

    return decompressed_data, string_sub( remaining_data, 9 ), header
end

--- [SHARED AND MENU]
---
--- The class used to create new gzip stream decompressors.
---
--- Decompresses a gzip stream added by `update` parts, the same as `gzip.decompress` of all of them together.
---
--- ```lua
--- local decompressor = std.gzip.Decompressor()
--- decompressor:update( part1 ):update( part2 )
--- local decompressed_data, _, header = decompressor:flush()
--- ```
---
---@class dreamwork.std.gzip.DecompressorClass : dreamwork.std.gzip.Decompressor, dreamwork.std.deflate.DecompressorClass
---@field __base dreamwork.std.gzip.Decompressor
---@overload fun(): dreamwork.std.gzip.Decompressor
local DecompressorClass = class.create( Decompressor )
gzip.Decompressor = DecompressorClass
