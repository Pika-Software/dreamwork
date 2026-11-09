---@class dreamwork.std
local std = dreamwork.std

local class = std.class

local bit = std.bit
local bit_band, bit_bor, bit_lshift, bit_rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local math = std.math
local math_floor = math.floor

local string = std.string
local string_byte, string_sub = string.byte, string.sub
local string_find, string_format = string.find, string.format

local table = std.table
local table_concat = table.concat

local time = std.time
local time_now = time.now
local time_offset = time.offset
local time_civilFromTimestamp = time.civilFromTimestamp
local time_timestampFromCivil = time.timestampFromCivil

local bytepack = std.bytepack
local bytepack_readTime, bytepack_writeTime = bytepack.readTime, bytepack.writeTime
local bytepack_readDate, bytepack_writeDate = bytepack.readDate, bytepack.writeDate

local deflate = std.deflate
local deflate_compress = deflate.compress
local deflate_decompress = deflate.decompress

local CRC32 = std.CRC32
local crc32_digest = CRC32.digest

local BinaryReader = std.BinaryReader
local BinaryWriter = std.BinaryWriter

local error = std.error
local pcall = std.pcall
local DecodeError = std.DecodeError

--- `PK\3\4` as little endian uint32.
---
---@type integer
local LOCAL_HEADER_SIGNATURE = 0x04034B50

--- `PK\1\2` as little endian uint32.
---
---@type integer
local CENTRAL_HEADER_SIGNATURE = 0x02014B50

--- `PK\5\6` as little endian uint32.
---
---@type integer
local END_SIGNATURE = 0x06054B50

--- `PK\6\6` as little endian uint32.
---
---@type integer
local ZIP64_END_SIGNATURE = 0x06064B50

--- `PK\6\7` as little endian uint32.
---
---@type integer
local ZIP64_LOCATOR_SIGNATURE = 0x07064B50

--- The extra field with 64-bit sizes and offsets.
---
---@type integer
local ZIP64_EXTRA_ID = 0x0001

--- The extended timestamp extra field (`UT`), the modification time as a Unix timestamp.
---
---@type integer
local TIMESTAMP_EXTRA_ID = 0x5455

--- The version needed to extract, `2.0` for deflate and directories.
---
---@type integer
local VERSION_NEEDED = 20

--- The version needed to extract ZIP64 records, `4.5`.
---
---@type integer
local ZIP64_VERSION_NEEDED = 45

--- The general purpose flags kept on rewrite: encryption (`0`), deflate options (`1` - `2`) and UTF-8 names (`11`),
--- the data descriptor (`3`) is dropped because the sizes are always written in the local header.
---
---@type integer
local KEPT_FLAGS = 0x0807

--- The UTF-8 names flag.
---
---@type integer
local UTF8_FLAG = 0x0800

--- The MS-DOS directory attribute.
---
---@type integer
local DIRECTORY_ATTRIBUTE = 0x10

--- The maximum size of the end of central directory record with the comment.
---
---@type integer
local END_SEARCH_LENGTH = 22 + 0xFFFF

---@type dreamwork.std.deflate.Options
local deflate_options = { level = 6 }

--- [SHARED AND MENU]
---
--- The file inside of the zip archive.
---
--- `content` is `nil` for files of a parsed archive, the compressed data stays in the archive string at `offset`,
--- `compressed` is the compressed data of added files.
---
---@class dreamwork.std.Zip.File
---@field path string The path of the file inside of the archive, e.g. `docs/readme.txt`, directories end with `/`.
---@field size integer The uncompressed size of the file in bytes.
---@field compressed_size integer The compressed size of the file in bytes.
---@field checksum integer The CRC-32 checksum of the uncompressed content.
---@field method integer The compression method, `0` is stored, `8` is deflate, others can't be read.
---@field flags integer The general purpose flags, `1` means the file is encrypted.
---@field timestamp integer The Unix timestamp of the last modification in seconds.
---@field comment string The file comment.
---@field attributes integer The external file attributes, MS-DOS attributes or the Unix mode in the high 16 bits, depends on `system`.
---@field system integer The host system the file was created on, `0` is MS-DOS, `3` is Unix.
---@field content string | nil The uncompressed content, `nil` if it is still in the archive data.
---@field compressed string | nil The compressed content, `nil` if it is still in the archive data.
---@field offset integer | nil The `1`-based position of the compressed content in the archive data.

--- [SHARED AND MENU]
---
--- The zip (`.zip`) archive.
---
--- Parses stored and deflated files (ZIP64 too), builds archives with deflated files,
--- the files of a parsed archive are copied without recompression.
---
--- ```lua
--- local zip = Zip()
--- zip:addFile( "docs/readme.txt", "hello" )
---
--- local data = zip:compile()
--- print( Zip( data ):readFile( "docs/readme.txt" ) ) -- hello
--- ```
---
---@class dreamwork.std.Zip : dreamwork.std.Object
---@field __class dreamwork.std.ZipClass
---@field comment string The comment of the archive.
---@field files dreamwork.std.Zip.File[] The files of the archive.
---@field file_count integer The number of files.
---@field file_indexes table<string, integer> The indexes of files in `files` by their paths.
---@field data string | nil The parsed archive data, the content of not yet read files.
local Zip = class.base( "Zip", false, nil )

--- [SHARED AND MENU]
---
--- The class used to create new `Zip` objects.
---
---@class dreamwork.std.ZipClass : dreamwork.std.Zip, dreamwork.std.Class
---@field __base dreamwork.std.Zip
---@overload fun( data: string? ): dreamwork.std.Zip
local ZipClass = class.create( Zip )
std.Zip = ZipClass

ZipClass.Signature = LOCAL_HEADER_SIGNATURE

---@return string
---@nodiscard
---@protected
function Zip:__represent()
    return string_format( "Zip: %p [%d files]", self, self.file_count )
end

---@param data string?
---@protected
function Zip:__init( data )
    self.comment = ""
    self.files = {}
    self.file_count = 0
    self.file_indexes = {}

    if data ~= nil then
        self:parse( data )
    end
end

--- Converts MS-DOS date and time (local time) to a Unix timestamp.
---
---@param dos_date integer
---@param dos_time integer
---@return integer timestamp
local function fromDOSTime( dos_date, dos_time )
    local day, month, year = bytepack_readDate( dos_date )
    local hour, minute, second = bytepack_readTime( dos_time )

    local local_seconds = time_timestampFromCivil( year, month, day, hour, minute, second )
    return local_seconds - time_offset( local_seconds )
end

--- Converts a Unix timestamp to MS-DOS date and time (local time).
---
---@param timestamp integer
---@return integer dos_date
---@return integer dos_time
local function toDOSTime( timestamp )
    local year, month, day, hour, minute, second = time_civilFromTimestamp( timestamp + time_offset( timestamp ) )
    return bytepack_writeDate( day, month, year ), bytepack_writeTime( hour, minute, second )
end

--- Finds the end of central directory record, the one whose comment ends with the data,
--- so a signature inside of the comment is skipped, the last one found if none of them fits.
---
---@param data string
---@param data_length integer
---@return integer | nil position
local function findEnd( data, data_length )
    local last = data_length - 21

    local first = last - END_SEARCH_LENGTH + 22
    if first < 1 then
        first = 1
    end

    local fallback = nil

    for position = last, first, -1 do
        if string_byte( data, position ) == 0x50 and string_sub( data, position, position + 3 ) == "PK\5\6" then
            local low, high = string_byte( data, position + 20, position + 21 )
            if position + 21 + low + high * 256 == data_length then
                return position
            end

            if fallback == nil then
                fallback = position
            end
        end
    end

    return fallback
end

--- [SHARED AND MENU]
---
--- Replaces the archive with the parsed `.zip` data.
---
--- File contents are not copied, they are read from the data on demand by `readFile`.
---
--- Multi-disk archives are not supported.
---
---@param data string The `.zip` data.
function Zip:parse( data )
    local data_length = #data

    local end_position = findEnd( data, data_length )
    if end_position == nil then
        error( DecodeError( "end of central directory not found", data_length ), 2 )
    end

    local reader = BinaryReader( data )
    reader:seek( end_position + 3, true )

    local disk = reader:readUInt( 16, true )
    local directory_disk = reader:readUInt( 16, true )

    if disk ~= 0 or directory_disk ~= 0 then
        error( DecodeError( "multi-disk archives are not supported", end_position ), 2 )
    end

    reader:skip( 16 ) -- entries on this disk

    local entry_count = reader:readUInt( 16, true )
    local directory_size = reader:readUInt( 32, true )
    local directory_offset = reader:readUInt( 32, true )
    local comment = reader:read( reader:readUInt( 16, true ) )

    if entry_count == 0xFFFF or directory_size == 0xFFFFFFFF or directory_offset == 0xFFFFFFFF then
        local locator_position = end_position - 20
        if locator_position < 1 then
            error( DecodeError( "ZIP64 end of central directory locator not found", end_position ), 2 )
        end

        reader:seek( locator_position - 1, true )

        if reader:readUInt( 32, true ) == ZIP64_LOCATOR_SIGNATURE then
            reader:skip( 32 )

            local record_position = reader:readUInt( 64, true ) + 1
            reader:seek( record_position - 1, true )

            if reader:readUInt( 32, true ) ~= ZIP64_END_SIGNATURE then
                error( DecodeError( "invalid ZIP64 end of central directory signature", record_position ), 2 )
            end

            -- record size, version made by, version needed, disk numbers and entries on this disk
            reader:skip( 28, true )

            entry_count = reader:readUInt( 64, true )
            directory_size = reader:readUInt( 64, true )
            directory_offset = reader:readUInt( 64, true )
        elseif entry_count ~= 0xFFFF then
            -- a real 0xFFFF entry count without ZIP64 is fine, the rest is not
            error( DecodeError( "ZIP64 end of central directory locator not found", locator_position ), 2 )
        end
    end

    if directory_offset + directory_size > end_position - 1 then
        error( DecodeError( "central directory is out of the archive data", end_position ), 2 )
    end

    local files, file_count, file_indexes = {}, 0, {}

    reader:seek( directory_offset, true )

    for _ = 1, entry_count, 1 do
        local entry_position = reader:tell( true ) + 1

        if reader:readUInt( 32, true ) ~= CENTRAL_HEADER_SIGNATURE then
            error( DecodeError( "invalid central directory entry signature", entry_position ), 2 )
        end

        local made_by = reader:readUInt( 16, true )
        reader:skip( 16 ) -- version needed

        local flags = reader:readUInt( 16, true )
        local method = reader:readUInt( 16, true )
        local dos_time = reader:readUInt( 16, true )
        local dos_date = reader:readUInt( 16, true )
        local checksum = reader:readUInt( 32, true )
        local compressed_size = reader:readUInt( 32, true )
        local size = reader:readUInt( 32, true )
        local path_length = reader:readUInt( 16, true )
        local extra_length = reader:readUInt( 16, true )
        local comment_length = reader:readUInt( 16, true )

        reader:skip( 32 ) -- disk number and internal attributes

        local attributes = reader:readUInt( 32, true )
        local local_offset = reader:readUInt( 32, true )

        local file_path = reader:read( path_length )

        local timestamp = nil

        local extra_end = reader:tell( true ) + extra_length

        ::extra_reader::

        if reader:tell( true ) + 4 <= extra_end then
            local extra_id = reader:readUInt( 16, true )
            local extra_size = reader:readUInt( 16, true )
            local field_end = reader:tell( true ) + extra_size

            if extra_id == ZIP64_EXTRA_ID then
                if size == 0xFFFFFFFF and reader:tell( true ) + 8 <= field_end then
                    size = reader:readUInt( 64, true )
                end

                if compressed_size == 0xFFFFFFFF and reader:tell( true ) + 8 <= field_end then
                    compressed_size = reader:readUInt( 64, true )
                end

                if local_offset == 0xFFFFFFFF and reader:tell( true ) + 8 <= field_end then
                    local_offset = reader:readUInt( 64, true )
                end
            elseif extra_id == TIMESTAMP_EXTRA_ID and extra_size >= 5 and bit_band( reader:readUInt( 8 ), 1 ) ~= 0 then
                timestamp = reader:readInt( 32, true )
            end

            reader:seek( field_end, true )
            goto extra_reader
        end

        reader:seek( extra_end, true )

        local file_comment = reader:read( comment_length )
        local next_position = reader:tell( true )

        local header_position = local_offset + 1
        if string_sub( data, header_position, header_position + 3 ) ~= "PK\3\4" then
            error( DecodeError( "invalid local file header signature", header_position ), 2 )
        end

        reader:seek( local_offset + 26, true )

        local offset = header_position + 30 + reader:readUInt( 16, true ) + reader:readUInt( 16, true )
        if offset + compressed_size - 1 > data_length then
            error( DecodeError( "unexpected end of file data", offset ), 2 )
        end

        if timestamp == nil then
            timestamp = fromDOSTime( dos_date, dos_time )
        end

        file_count = file_count + 1

        files[ file_count ] = {
            path = file_path,
            size = size,
            compressed_size = compressed_size,
            checksum = checksum,
            method = method,
            flags = flags,
            timestamp = timestamp,
            comment = file_comment,
            attributes = attributes,
            system = bit_rshift( made_by, 8 ),
            offset = offset
        }

        file_indexes[ file_path ] = file_count

        reader:seek( next_position, true )
    end

    self.comment = comment
    self.files = files
    self.file_count = file_count
    self.file_indexes = file_indexes
    self.data = data
end

---@param zip dreamwork.std.Zip
---@param file dreamwork.std.Zip.File
---@return string compressed
local function getCompressed( zip, file )
    local compressed = file.compressed
    if compressed ~= nil then
        return compressed
    end

    local offset = file.offset
    if offset == nil then
        error( "file '" .. file.path .. "' has no compressed content and no offset in the archive data", 3 )
    end

    return string_sub( zip.data, offset, offset + file.compressed_size - 1 )
end

---@param zip dreamwork.std.Zip
---@param file dreamwork.std.Zip.File
---@return string content
local function getContent( zip, file )
    local content = file.content
    if content ~= nil then
        return content
    end

    if bit_band( file.flags, 1 ) ~= 0 then
        error( "file '" .. file.path .. "' is encrypted", 3 )
    end

    local method = file.method

    if method == 0 then
        return getCompressed( zip, file )
    elseif method ~= 8 then
        error( "file '" .. file.path .. "' has unsupported compression method " .. method, 3 )
    end

    local compressed = file.compressed
    if compressed ~= nil then
        return ( deflate_decompress( compressed ) )
    end

    local offset = file.offset
    if offset == nil then
        error( "file '" .. file.path .. "' has no compressed content and no offset in the archive data", 3 )
    end

    -- decompressed in place, without copying the compressed data out of the archive
    return ( deflate_decompress( zip.data, nil, offset ) )
end

--- [SHARED AND MENU]
---
--- Builds the `.zip` data of the archive.
---
--- Files are written with the extended timestamp, ZIP64 records are added only for more than `65534` files.
---
---@return string data The `.zip` data.
---@nodiscard
function Zip:compile()
    local files, file_count = self.files, self.file_count

    local writer = BinaryWriter()
    local directory = BinaryWriter()

    ---@type string[]
    local buffer = {}
    local buffer_size = 0

    local position = 0

    for i = 1, file_count, 1 do
        local file = files[ i ]

        local file_path = file.path
        local compressed = getCompressed( self, file )
        local timestamp = math_floor( file.timestamp )
        local dos_date, dos_time = toDOSTime( timestamp )

        local flags = bit_band( file.flags, KEPT_FLAGS )

        local file_comment = file.comment
        if string_find( file_path, "[\128-\255]" ) ~= nil or string_find( file_comment, "[\128-\255]" ) ~= nil then
            flags = bit_bor( flags, UTF8_FLAG )
        end

        writer:open( "" )
        writer:writeUInt( LOCAL_HEADER_SIGNATURE, 32, true )
        writer:writeUInt( VERSION_NEEDED, 16, true )
        writer:writeUInt( flags, 16, true )
        writer:writeUInt( file.method, 16, true )
        writer:writeUInt( dos_time, 16, true )
        writer:writeUInt( dos_date, 16, true )
        writer:writeUInt( file.checksum, 32, true )
        writer:writeUInt( #compressed, 32, true )
        writer:writeUInt( file.size, 32, true )
        writer:writeUInt( #file_path, 16, true )
        writer:writeUInt( 9, 16, true )
        writer:write( file_path )
        writer:writeUInt( TIMESTAMP_EXTRA_ID, 16, true )
        writer:writeUInt( 5, 16, true )
        writer:writeUInt( 1, 8 )
        writer:writeInt( timestamp, 32, true )

        local header = writer:compile()

        buffer[ buffer_size + 1 ] = header
        buffer[ buffer_size + 2 ] = compressed
        buffer_size = buffer_size + 2

        directory:writeUInt( CENTRAL_HEADER_SIGNATURE, 32, true )
        directory:writeUInt( bit_bor( bit_lshift( file.system, 8 ), VERSION_NEEDED ), 16, true )
        directory:writeUInt( VERSION_NEEDED, 16, true )
        directory:writeUInt( flags, 16, true )
        directory:writeUInt( file.method, 16, true )
        directory:writeUInt( dos_time, 16, true )
        directory:writeUInt( dos_date, 16, true )
        directory:writeUInt( file.checksum, 32, true )
        directory:writeUInt( #compressed, 32, true )
        directory:writeUInt( file.size, 32, true )
        directory:writeUInt( #file_path, 16, true )
        directory:writeUInt( 9, 16, true )
        directory:writeUInt( #file_comment, 16, true )
        directory:writeUInt( 0, 16, true ) -- disk number
        directory:writeUInt( 0, 16, true ) -- internal attributes
        directory:writeUInt( file.attributes, 32, true )
        directory:writeUInt( position, 32, true )
        directory:write( file_path )
        directory:writeUInt( TIMESTAMP_EXTRA_ID, 16, true )
        directory:writeUInt( 5, 16, true )
        directory:writeUInt( 1, 8 )
        directory:writeInt( timestamp, 32, true )
        directory:write( file_comment )

        position = position + #header + #compressed
    end

    local directory_size = directory:tell( true )
    local entry_count = file_count

    if file_count >= 0xFFFF then
        local record_position = position + directory_size

        directory:writeUInt( ZIP64_END_SIGNATURE, 32, true )
        directory:writeUInt( 44, 64, true )
        directory:writeUInt( ZIP64_VERSION_NEEDED, 16, true )
        directory:writeUInt( ZIP64_VERSION_NEEDED, 16, true )
        directory:writeUInt( 0, 32, true ) -- disk number
        directory:writeUInt( 0, 32, true ) -- central directory disk
        directory:writeUInt( file_count, 64, true )
        directory:writeUInt( file_count, 64, true )
        directory:writeUInt( directory_size, 64, true )
        directory:writeUInt( position, 64, true )

        directory:writeUInt( ZIP64_LOCATOR_SIGNATURE, 32, true )
        directory:writeUInt( 0, 32, true ) -- ZIP64 end of central directory disk
        directory:writeUInt( record_position, 64, true )
        directory:writeUInt( 1, 32, true ) -- total disks

        entry_count = 0xFFFF
    end

    local comment = self.comment

    directory:writeUInt( END_SIGNATURE, 32, true )
    directory:writeUInt( 0, 16, true ) -- disk number
    directory:writeUInt( 0, 16, true ) -- central directory disk
    directory:writeUInt( entry_count, 16, true )
    directory:writeUInt( entry_count, 16, true )
    directory:writeUInt( directory_size, 32, true )
    directory:writeUInt( position, 32, true )
    directory:writeUInt( #comment, 16, true )
    directory:write( comment )

    buffer[ buffer_size + 1 ] = directory:compile()

    return table_concat( buffer, "", 1, buffer_size + 1 )
end

Zip.__tostring = Zip.compile

--- [SHARED AND MENU]
---
--- Returns the file of the archive.
---
---@param file_path string The path of the file inside of the archive.
---@return dreamwork.std.Zip.File | nil file The file, `nil` if there is no such file.
---@nodiscard
function Zip:getFile( file_path )
    local index = self.file_indexes[ file_path ]
    if index == nil then
        return nil
    end

    return self.files[ index ]
end

--- [SHARED AND MENU]
---
--- Returns the uncompressed content of the file of the archive.
---
--- Throws an error if the file is encrypted, uses an unsupported compression method or its data is malformed.
---
---@param file_path string The path of the file inside of the archive.
---@return string | nil content The file content, `nil` if there is no such file.
---@nodiscard
function Zip:readFile( file_path )
    local index = self.file_indexes[ file_path ]
    if index == nil then
        return nil
    end

    return getContent( self, self.files[ index ] )
end

---@param zip dreamwork.std.Zip
---@param file dreamwork.std.Zip.File
local function insertFile( zip, file )
    local file_path = file.path

    local index = zip.file_indexes[ file_path ]
    if index == nil then
        index = zip.file_count + 1
        zip.file_count = index
        zip.file_indexes[ file_path ] = index
    end

    zip.files[ index ] = file
end

--- [SHARED AND MENU]
---
--- Adds the file to the archive, replaces the existing file with the same path.
---
--- The content is deflated right away, it is stored as is if deflate doesn't make it smaller.
---
---@param file_path string The path of the file inside of the archive, e.g. `docs/readme.txt`.
---@param content string The file content.
---@param level integer? The deflate level ( 0 - 9 ), `0` stores the content without compression, `6` by default.
---@return dreamwork.std.Zip.File file The added file.
function Zip:addFile( file_path, content, level )
    local size = #content

    local method, compressed = 0, content

    if level ~= 0 and size ~= 0 then
        deflate_options.level = level or 6

        local deflated = deflate_compress( content, deflate_options )
        if #deflated < size then
            method, compressed = 8, deflated
        end
    end

    ---@type dreamwork.std.Zip.File
    local file = {
        path = file_path,
        size = size,
        compressed_size = #compressed,
        checksum = crc32_digest( content ),
        method = method,
        flags = 0,
        timestamp = time_now(),
        comment = "",
        attributes = 0,
        system = 0,
        content = content,
        compressed = compressed
    }

    insertFile( self, file )
    return file
end

--- [SHARED AND MENU]
---
--- Adds the directory to the archive, replaces the existing entry with the same path.
---
--- Directories don't have to be added for their files, but some tools show empty directories only this way.
---
---@param directory_path string The path of the directory inside of the archive, `/` is appended if missing.
---@return dreamwork.std.Zip.File file The added directory entry.
function Zip:addDirectory( directory_path )
    if string_byte( directory_path, -1 ) ~= 0x2F --[[ / ]] then
        directory_path = directory_path .. "/"
    end

    ---@type dreamwork.std.Zip.File
    local file = {
        path = directory_path,
        size = 0,
        compressed_size = 0,
        checksum = 0,
        method = 0,
        flags = 0,
        timestamp = time_now(),
        comment = "",
        attributes = DIRECTORY_ATTRIBUTE,
        system = 0,
        content = "",
        compressed = ""
    }

    insertFile( self, file )
    return file
end

--- [SHARED AND MENU]
---
--- Removes the file from the archive.
---
---@param file_path string The path of the file inside of the archive.
---@return boolean removed `true` if the file was removed, `false` if there is no such file.
function Zip:removeFile( file_path )
    local file_indexes = self.file_indexes

    local index = file_indexes[ file_path ]
    if index == nil then
        return false
    end

    local files, file_count = self.files, self.file_count
    file_indexes[ file_path ] = nil

    for i = index, file_count - 1, 1 do
        local file = files[ i + 1 ]
        files[ i ] = file
        file_indexes[ file.path ] = i
    end

    files[ file_count ] = nil
    self.file_count = file_count - 1

    return true
end

--- [SHARED AND MENU]
---
--- Decompresses all files and checks their CRC-32 checksums.
---
--- Encrypted files and files with unsupported compression methods are reported as damaged.
---
---@return boolean is_valid `true` if all files are fine.
---@return string | nil file_path The path of the first damaged file.
---@nodiscard
function Zip:verify()
    local files = self.files

    for i = 1, self.file_count, 1 do
        local file = files[ i ]

        local success, content = pcall( getContent, self, file )
        if not ( success and #content == file.size and crc32_digest( content ) == file.checksum ) then
            return false, file.path
        end
    end

    return true, nil
end
