---@class dreamwork.std
local std = dreamwork.std

local bitpack = std.bitpack
local bitpack_get = bitpack.get
local bitpack_readUInt = bitpack.readUInt

local bytepack = std.bytepack
local bytepack_readUInt32BE = bytepack.readUInt32BE
local bytepack_writeUInt32BE = bytepack.writeUInt32BE

local string = std.string
local string_byte = string.byte
local string_char = string.char

local Adler32 = std.Adler32
local Adler32_digest = Adler32.digest

local deflate = std.deflate
local deflate_compress = deflate.compress
local deflate_decompress = deflate.decompress

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

--- [SHARED AND MENU]
---
--- Compresses a string into a zlib stream.
---
---@param raw_data string The string to compress.
---@param options? dreamwork.std.deflate.Options The compression options.
---@return string compressed_data The compressed string.
---@nodiscard
function zlib.compress( raw_data, options )
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

    return header .. deflate_compress( raw_data, options ) .. string_char( bytepack_writeUInt32BE( Adler32_digest( raw_data ) ) )
end

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
function zlib.decompress( compressed_data, dictionary )
    local cmf, flg = string_byte( compressed_data, 1, 2 )
    if flg == nil then
        error( "corrupt zlib data: truncated header", 2 )
    end

    if (cmf * 0x100 + flg) % 31 ~= 0 then
        error( "corrupt zlib data: invalid header checksum", 2 )
    end

    if bitpack_readUInt( cmf, 0, 4 ) ~= 8 then
        error( "corrupt zlib data: unknown compression method", 2 )
    end

    if bitpack_readUInt( cmf, 4, 4 ) > 7 then
        error( "corrupt zlib data: invalid window size", 2 )
    end

    local start_position = 3

    if bitpack_get( flg, 5 ) then
        local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( compressed_data, 3, 6 )
        if uint8_4 == nil then
            error( "corrupt zlib data: truncated header", 2 )
        end

        if dictionary == nil then
            error( "zlib data requires a preset dictionary", 2 )
        end

        if bytepack_readUInt32BE( uint8_1, uint8_2, uint8_3, uint8_4 ) ~= Adler32_digest( dictionary ) then
            error( "zlib data requires a different preset dictionary", 2 )
        end

        start_position = 7
    else
        dictionary = nil
    end

    local decompressed_data, end_position = deflate_decompress( compressed_data, dictionary, start_position )

    local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( compressed_data, end_position, end_position + 3 )
    if uint8_4 == nil then
        error( "corrupt zlib data: truncated checksum", 2 )
    end

    if bytepack_readUInt32BE( uint8_1, uint8_2, uint8_3, uint8_4 ) ~= Adler32_digest( decompressed_data ) then
        error( "corrupt zlib data: checksum mismatch", 2 )
    end

    return decompressed_data, end_position + 4
end
