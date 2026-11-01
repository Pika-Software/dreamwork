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
local string_len = string.len
local string_sub = string.sub
local string_byte = string.byte
local string_char = string.char
local string_find = string.find

local table = std.table
local table_concat = table.concat

local CRC32 = std.CRC32
local CRC32_digest = CRC32.digest

local deflate = std.deflate
local deflate_compress = deflate.compress
local deflate_decompress = deflate.decompress

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
        error( "options." .. name .. " must not contain zero bytes", 3 )
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

--- [SHARED AND MENU]
---
--- Compresses a string into a gzip stream.
---
---@param raw_data string The string to compress.
---@param options? dreamwork.std.gzip.Options The compression options.
---@return string compressed_data The compressed string.
---@nodiscard
function gzip.compress( raw_data, options )
    local level, mtime, os_code = 6, 0, OS_CODE
    local text, header_crc = false, false
    local name, comment, extra

    ---@type string
    local compressed_data

    if options == nil then
        compressed_data = deflate_compress( raw_data )
    else
        level = options.level or 6

        name = check_zero_terminated( options.name, "name" )
        comment = check_zero_terminated( options.comment, "comment" )

        if options.mtime ~= nil then
            mtime = options.mtime
            if not (mtime % 1 == 0 and mtime >= 0 and mtime <= 0xFFFFFFFF) then
                error( "options.mtime must be an integer from 0 to 4294967295", 2 )
            end

            ---@cast mtime integer
        end

        if options.os ~= nil then
            os_code = options.os
            if not (os_code % 1 == 0 and os_code >= 0 and os_code <= 255) then
                error( "options.os must be an integer from 0 to 255", 2 )
            end
        end

        extra = options.extra
        if extra ~= nil and string_len( extra ) > 0xFFFF then
            error( "options.extra must be up to 65535 bytes long", 2 )
        end

        text = options.text == true
        header_crc = options.header_crc == true

        deflate_options.level = options.level
        deflate_options.strategy = options.strategy

        compressed_data = deflate_compress( raw_data, deflate_options )
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
        segments[ segment_count + 1 ] = string_char( bytepack_writeUInt16LE( string_len( extra ) ) )
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

    segments[ segment_count + 1 ] = compressed_data
    segments[ segment_count + 2 ] = string_char( bytepack_writeUInt32LE( CRC32_digest( raw_data ) ) )
    segments[ segment_count + 3 ] = string_char( bytepack_writeUInt32LE( string_len( raw_data ) % 0x100000000 ) )

    return table_concat( segments, "", 1, segment_count + 3 )
end

---@param compressed_data string
---@param position integer
---@return string | nil value
---@return integer position
local function read_zero_terminated( compressed_data, position )
    local zero_position = string_find( compressed_data, "\0", position, true )
    if zero_position == nil then
        error( "corrupt gzip data: truncated header", 3 )
    end

    return string_sub( compressed_data, position, zero_position - 1 ), zero_position + 1
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
---@param start_position? integer The position of the stream in the string, `1` by default.
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
        local id1, id2, method, flags, uint8_1, uint8_2, uint8_3, uint8_4, _, os_code = string_byte( compressed_data, position, position + 9 )
        if os_code == nil then
            error( "corrupt gzip data: truncated header", 2 )
        end

        if id1 ~= 0x1F or id2 ~= 0x8B then
            error( "corrupt gzip data: invalid magic number", 2 )
        end

        if method ~= 8 then
            error( "corrupt gzip data: unknown compression method", 2 )
        end

        if flags > 0x1F then
            error( "corrupt gzip data: reserved flags are set", 2 )
        end

        local header_start = position
        position = position + 10

        local name, comment, extra

        if bitpack_get( flags, 2 ) then
            local length_1, length_2 = string_byte( compressed_data, position, position + 1 )
            if length_2 == nil then
                error( "corrupt gzip data: truncated header", 2 )
            end

            local extra_end = position + 1 + bytepack_readUInt16LE( length_1, length_2 )
            if extra_end > string_len( compressed_data ) then
                error( "corrupt gzip data: truncated header", 2 )
            end

            extra = string_sub( compressed_data, position + 2, extra_end )
            position = extra_end + 1
        end

        if bitpack_get( flags, 3 ) then
            name, position = read_zero_terminated( compressed_data, position )
        end

        if bitpack_get( flags, 4 ) then
            comment, position = read_zero_terminated( compressed_data, position )
        end

        if bitpack_get( flags, 1 ) then
            local crc_1, crc_2 = string_byte( compressed_data, position, position + 1 )
            if crc_2 == nil then
                error( "corrupt gzip data: truncated header", 2 )
            end

            if bytepack_readUInt16LE( crc_1, crc_2 ) ~= CRC32_digest( string_sub( compressed_data, header_start, position - 1 ) ) % 0x10000 then
                error( "corrupt gzip data: header checksum mismatch", 2 )
            end

            position = position + 2
        end

        if header == nil then
            header = {
                name = name,
                comment = comment,
                mtime = bytepack_readUInt32LE( uint8_1, uint8_2, uint8_3, uint8_4 ),
                os = os_code,
                extra = extra,
                text = bitpack_get( flags, 0 )
            }
        end

        local decompressed_data, end_position = deflate_decompress( compressed_data, nil, position )

        local crc_1, crc_2, crc_3, crc_4, size_1, size_2, size_3, size_4 = string_byte( compressed_data, end_position, end_position + 7 )
        if size_4 == nil then
            error( "corrupt gzip data: truncated trailer", 2 )
        end

        if bytepack_readUInt32LE( crc_1, crc_2, crc_3, crc_4 ) ~= CRC32_digest( decompressed_data ) then
            error( "corrupt gzip data: checksum mismatch", 2 )
        end

        if bytepack_readUInt32LE( size_1, size_2, size_3, size_4 ) ~= string_len( decompressed_data ) % 0x100000000 then
            error( "corrupt gzip data: size mismatch", 2 )
        end

        member_count = member_count + 1
        members[ member_count ] = decompressed_data

        position = end_position + 8

        id1, id2 = string_byte( compressed_data, position, position + 1 )
    until id1 ~= 0x1F or id2 ~= 0x8B

    if member_count == 1 then
        return members[ 1 ], position, header
    end

    return table_concat( members, "", 1, member_count ), position, header
end
