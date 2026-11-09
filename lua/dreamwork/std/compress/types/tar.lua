---@class dreamwork.std
local std = dreamwork.std

local class = std.class

local raw = std.raw
local raw_tonumber = raw.tonumber

local math = std.math
local math_floor, math_ceil = math.floor, math.ceil

local string = std.string
local string_byte, string_sub, string_rep = string.byte, string.sub, string.rep
local string_find, string_match, string_format = string.find, string.match, string.format

local table = std.table
local table_concat = table.concat

local time = std.time
local time_now = time.now

local gzip = std.gzip
local gzip_decompress = gzip.decompress

local error = std.error
local DecodeError = std.DecodeError


--- The size of the header and the content block.
---
---@type integer
local BLOCK_SIZE = 512

--- The empty block, two of them end the archive.
---
---@type string
local ZERO_BLOCK = string_rep( "\0", BLOCK_SIZE )

--- The largest value of the 12 bytes octal fields (`size`, `mtime`).
---
---@type integer
local MAX_OCTAL_11 = 8589934591 -- 8^11 - 1

--- The largest value of the 8 bytes octal fields (`mode`, `uid`, `gid`).
---
---@type integer
local MAX_OCTAL_7 = 2097151 -- 8^7 - 1

--- [SHARED AND MENU]
---
--- The tar (`.tar`) archive.
---
--- Parses POSIX ustar, pax and GNU archives (long names and base-256 numbers), gzip compressed archives are decompressed on parse.
---
--- Builds ustar archives, long paths and out of range values are written with pax headers.
---
--- ```lua
--- local tar = Tar()
--- tar:addDirectory( "docs" )
--- tar:addFile( "docs/readme.txt", "hello" )
---
--- local data = tar:compile()
--- print( Tar( data ):readFile( "docs/readme.txt" ) ) -- hello
--- ```
---
---@class dreamwork.std.Tar : dreamwork.std.Object
---@field __class dreamwork.std.TarClass
---@field files dreamwork.std.Tar.File[] The entries of the archive.
---@field file_count integer The number of entries.
---@field file_indexes table<string, integer> The indexes of entries in `files` by their paths.
---@field gzipped boolean `true` if the parsed archive was gzip compressed.
---@field data string | nil The parsed archive data, the content of not yet read entries.
local Tar = class.base( "Tar", false, nil )

--- [SHARED AND MENU]
---
--- The class used to create new `Tar` objects.
---
---@class dreamwork.std.TarClass : dreamwork.std.Tar, dreamwork.std.Class
---@field __base dreamwork.std.Tar
---@overload fun( data: string? ): dreamwork.std.Tar
local TarClass = class.create( Tar )
std.Tar = TarClass

---@return string
---@nodiscard
---@protected
function Tar:__represent()
    return string_format( "Tar: %p [%d files]", self, self.file_count )
end

---@param data string?
---@protected
function Tar:__init( data )
    self.files = {}
    self.file_count = 0
    self.file_indexes = {}
    self.gzipped = false

    if data ~= nil then
        self:parse( data )
    end
end

---@param header string
---@return integer checksum
local function headerChecksum( header )
    local checksum = 256 -- the checksum field counts as 8 spaces

    for i = 1, 148, 1 do
        checksum = checksum + string_byte( header, i )
    end

    for i = 157, BLOCK_SIZE, 1 do
        checksum = checksum + string_byte( header, i )
    end

    return checksum
end

---@param header string
---@param start integer
---@param length integer
---@return string str
local function readString( header, start, length )
    local str = string_sub( header, start, start + length - 1 )

    local terminator = string_find( str, "\0", 1, true )
    if terminator == nil then
        return str
    end

    return string_sub( str, 1, terminator - 1 )
end

--- Reads the octal number, or the GNU base-256 number if the high bit of the first byte is set.
---
---@param header string
---@param start integer
---@param length integer
---@return integer value
local function readNumber( header, start, length )
    local first = string_byte( header, start )

    if first >= 0x80 then
        local value = first - 0x80

        -- negative numbers, only possible for `mtime`
        local negative = first == 0xFF
        if negative then
            value = 0
        end

        for i = start + 1, start + length - 1, 1 do
            local byte = string_byte( header, i )
            if negative then
                byte = 0xFF - byte
            end

            value = value * 256 + byte
        end

        if negative then
            return -value - 1
        end

        return value
    end

    return raw_tonumber( string_match( string_sub( header, start, start + length - 1 ), "^[ %z]*([0-7]*)" ), 8 ) or 0
end

---@param records string
---@param records_position integer
---@param pax table<string, string>
local function parsePax( records, records_position, pax )
    local records_length = #records
    local position = 1

    ::record_reader::

    if position <= records_length then
        local _, length_end, length_str = string_find( records, "^(%d+) ", position )
        if length_end == nil then
            error( DecodeError( "invalid pax record", records_position + position - 1 ), 3 )
        end

        local record_end = position + raw_tonumber( length_str, 10 ) - 1
        if record_end > records_length or record_end <= length_end then
            error( DecodeError( "invalid pax record length", records_position + position - 1 ), 3 )
        end

        local key, value = string_match( string_sub( records, length_end + 1, record_end - 1 ), "^([^=]*)=(.*)$" )
        if key ~= nil then
            if value == "" then
                pax[ key ] = nil
            else
                pax[ key ] = value
            end
        end

        position = record_end + 1
        goto record_reader
    end
end

---@param pax table<string, string>
---@param pax_global table<string, string>
---@param key string
---@return string | nil value
local function getPax( pax, pax_global, key )
    local value = pax[ key ]
    if value == nil then
        return pax_global[ key ]
    end

    return value
end

---@param pax table<string, string>
---@param pax_global table<string, string>
---@param key string
---@param default integer
---@return integer value
local function getPaxNumber( pax, pax_global, key, default )
    local value = getPax( pax, pax_global, key )
    if value == nil then
        return default
    end

    local number = raw_tonumber( value, 10 )
    if number == nil then
        -- fractional seconds, e.g. `1700000000.5`
        number = raw_tonumber( value )
        if number == nil then
            return default
        end

        return math_floor( number )
    end

    return number
end

--- [SHARED AND MENU]
---
--- Replaces the archive with the parsed `.tar` or `.tar.gz` data.
---
--- File contents are not copied, they are read from the data on demand by `readFile`.
---
---@param data string The `.tar` or `.tar.gz` data.
function Tar:parse( data )
    local gzipped = false

    local id1, id2 = string_byte( data, 1, 2 )
    if id1 == 0x1F and id2 == 0x8B then
        data = gzip_decompress( data )
        gzipped = true
    end

    local data_length = #data

    local files, file_count, file_indexes = {}, 0, {}

    ---@type table<string, string>
    local pax_global = {}

    ---@type table<string, string>
    local pax = {}

    ---@type string | nil
    local long_path = nil

    ---@type string | nil
    local long_link = nil

    local position = 1

    ::header_reader::

    -- archives without the end blocks are accepted
    if position + BLOCK_SIZE - 1 <= data_length then
        local header = string_sub( data, position, position + BLOCK_SIZE - 1 )
        if header == ZERO_BLOCK then
            goto header_end
        end

        if readNumber( header, 149, 8 ) ~= headerChecksum( header ) then
            error( DecodeError( "invalid tar header checksum", position ), 2 )
        end

        local type_name = string_sub( header, 157, 157 )
        if type_name == "\0" then
            type_name = "0"
        end

        local size = readNumber( header, 125, 12 )

        local is_meta = type_name == "x" or type_name == "g" or type_name == "L" or type_name == "K"
        if not is_meta then
            size = getPaxNumber( pax, pax_global, "size", size )
        end

        local offset = position + BLOCK_SIZE
        if offset + size - 1 > data_length then
            error( DecodeError( "unexpected end of tar data", offset ), 2 )
        end

        if type_name == "x" then
            parsePax( string_sub( data, offset, offset + size - 1 ), offset, pax )
        elseif type_name == "g" then
            parsePax( string_sub( data, offset, offset + size - 1 ), offset, pax_global )
        elseif type_name == "L" then
            long_path = readString( data, offset, size )
        elseif type_name == "K" then
            long_link = readString( data, offset, size )
        else
            local file_path = long_path or getPax( pax, pax_global, "path" )
            if file_path == nil then
                file_path = readString( header, 1, 100 )

                -- only POSIX ustar has the prefix, GNU uses these bytes for other fields
                if string_sub( header, 258, 263 ) == "ustar\0" then
                    local prefix = readString( header, 346, 155 )
                    if prefix ~= "" then
                        file_path = prefix .. "/" .. file_path
                    end
                end
            end

            local link = long_link or getPax( pax, pax_global, "linkpath" ) or readString( header, 158, 100 )

            file_count = file_count + 1

            files[ file_count ] = {
                path = file_path,
                type = type_name,
                size = size,
                mode = readNumber( header, 101, 8 ),
                uid = getPaxNumber( pax, pax_global, "uid", readNumber( header, 109, 8 ) ),
                gid = getPaxNumber( pax, pax_global, "gid", readNumber( header, 117, 8 ) ),
                timestamp = getPaxNumber( pax, pax_global, "mtime", readNumber( header, 137, 12 ) ),
                link = link,
                user = getPax( pax, pax_global, "uname" ) or readString( header, 266, 32 ),
                group = getPax( pax, pax_global, "gname" ) or readString( header, 298, 32 ),
                offset = offset
            }

            file_indexes[ file_path ] = file_count

            pax = {}
            long_path, long_link = nil, nil
        end

        position = offset + math_ceil( size / BLOCK_SIZE ) * BLOCK_SIZE
        goto header_reader
    end

    ::header_end::

    self.files = files
    self.file_count = file_count
    self.file_indexes = file_indexes
    self.gzipped = gzipped
    self.data = data
end

---@param tar dreamwork.std.Tar
---@param file dreamwork.std.Tar.File
---@return string content
local function getContent( tar, file )
    local content = file.content
    if content ~= nil then
        return content
    end

    local offset = file.offset
    if offset == nil then
        error( "file '" .. file.path .. "' has no content and no offset in the archive data", 3 )
    end

    return string_sub( tar.data, offset, offset + file.size - 1 )
end

---@param str string
---@param length integer
---@return string field
local function padString( str, length )
    local str_length = #str
    if str_length >= length then
        return string_sub( str, 1, length )
    end

    return str .. string_rep( "\0", length - str_length )
end

---@param path string
---@return string | nil name
---@return string | nil prefix
local function splitPath( path )
    local path_length = #path
    if path_length <= 100 then
        return path, ""
    end

    local first = path_length - 100
    if first < 2 then
        first = 2
    end

    local last = path_length - 1
    if last > 156 then
        last = 156
    end

    -- the longest prefix, the name can't be empty
    for i = last, first, -1 do
        if string_byte( path, i ) == 0x2F --[[ / ]] then
            return string_sub( path, i + 1 ), string_sub( path, 1, i - 1 )
        end
    end

    return nil, nil
end

---@param records string[]
---@param record_count integer
---@param key string
---@param value string
---@return integer record_count
local function addPaxRecord( records, record_count, key, value )
    local body = " " .. key .. "=" .. value .. "\n"
    local body_length = #body

    -- the length counts its own digits
    local length = body_length + #string_format( "%d", body_length )
    if #string_format( "%d", length ) + body_length ~= length then
        length = length + 1
    end

    record_count = record_count + 1
    records[ record_count ] = length .. body
    return record_count
end

---@param name string
---@param mode integer
---@param uid integer
---@param gid integer
---@param size integer
---@param timestamp integer
---@param type_name string
---@param link string
---@param user string
---@param group string
---@param prefix string
---@return string header
local function buildHeader( name, mode, uid, gid, size, timestamp, type_name, link, user, group, prefix )
    local head = padString( name, 100 ) ..
        string_format( "%07o\0%07o\0%07o\0%011o\0%011o\0", mode, uid, gid, size, timestamp )

    local tail = type_name .. padString( link, 100 ) .. "ustar\0" .. "00" ..
        padString( user, 32 ) .. padString( group, 32 ) ..
        "0000000\0" .. "0000000\0" .. padString( prefix, 155 ) .. string_rep( "\0", 12 )

    return head .. string_format( "%06o\0 ", headerChecksum( head .. "        " .. tail ) ) .. tail
end

--- [SHARED AND MENU]
---
--- Builds the `.tar` data of the archive.
---
--- Use `gzip.compress` on the result to get `.tar.gz`.
---
---@return string data The `.tar` data.
---@nodiscard
function Tar:compile()
    local files, file_count = self.files, self.file_count

    ---@type string[]
    local buffer = {}
    local buffer_size = 0

    ---@type string[]
    local records = {}

    for i = 1, file_count, 1 do
        local file = files[ i ]

        local content = getContent( self, file )
        local size = #content

        local file_path, link = file.path, file.link
        local user, group = file.user, file.group
        local mode, uid, gid = file.mode, file.uid, file.gid
        local timestamp = math_floor( file.timestamp )

        local record_count = 0

        local name, prefix = splitPath( file_path )
        if name == nil then
            record_count = addPaxRecord( records, record_count, "path", file_path )
            name, prefix = file_path, ""
        end

        ---@cast prefix string

        if #link > 100 then
            record_count = addPaxRecord( records, record_count, "linkpath", link )
        end

        if #user > 32 then
            record_count = addPaxRecord( records, record_count, "uname", user )
        end

        if #group > 32 then
            record_count = addPaxRecord( records, record_count, "gname", group )
        end

        if uid < 0 or uid > MAX_OCTAL_7 then
            record_count = addPaxRecord( records, record_count, "uid", string_format( "%d", uid ) )
            uid = 0
        end

        if gid < 0 or gid > MAX_OCTAL_7 then
            record_count = addPaxRecord( records, record_count, "gid", string_format( "%d", gid ) )
            gid = 0
        end

        if timestamp < 0 or timestamp > MAX_OCTAL_11 then
            record_count = addPaxRecord( records, record_count, "mtime", string_format( "%d", timestamp ) )
            timestamp = 0
        end

        if record_count ~= 0 then
            local pax_data = table_concat( records, "", 1, record_count )
            local pax_size = #pax_data

            buffer[ buffer_size + 1 ] = buildHeader( "PaxHeader/" .. string_sub( name, 1, 90 ), 420, 0, 0, pax_size, timestamp, "x", "", "", "", "" )
            buffer[ buffer_size + 2 ] = pax_data
            buffer_size = buffer_size + 2

            local padding = (BLOCK_SIZE - pax_size % BLOCK_SIZE) % BLOCK_SIZE
            if padding ~= 0 then
                buffer_size = buffer_size + 1
                buffer[ buffer_size ] = string_sub( ZERO_BLOCK, 1, padding )
            end
        end

        buffer[ buffer_size + 1 ] = buildHeader( name, mode % (MAX_OCTAL_7 + 1), uid, gid, size, timestamp, file.type, link, user, group, prefix )
        buffer[ buffer_size + 2 ] = content
        buffer_size = buffer_size + 2

        local padding = (BLOCK_SIZE - size % BLOCK_SIZE) % BLOCK_SIZE
        if padding ~= 0 then
            buffer_size = buffer_size + 1
            buffer[ buffer_size ] = string_sub( ZERO_BLOCK, 1, padding )
        end
    end

    buffer[ buffer_size + 1 ] = ZERO_BLOCK
    buffer[ buffer_size + 2 ] = ZERO_BLOCK

    return table_concat( buffer, "", 1, buffer_size + 2 )
end

Tar.__tostring = Tar.compile

--- [SHARED AND MENU]
---
--- Returns the entry of the archive.
---
---@param file_path string The path of the entry inside of the archive.
---@return dreamwork.std.Tar.File | nil file The entry, `nil` if there is no such entry.
---@nodiscard
function Tar:getFile( file_path )
    local index = self.file_indexes[ file_path ]
    if index == nil then
        return nil
    end

    return self.files[ index ]
end

--- [SHARED AND MENU]
---
--- Returns the content of the entry of the archive.
---
---@param file_path string The path of the entry inside of the archive.
---@return string | nil content The content, `nil` if there is no such entry.
---@nodiscard
function Tar:readFile( file_path )
    local index = self.file_indexes[ file_path ]
    if index == nil then
        return nil
    end

    return getContent( self, self.files[ index ] )
end

---@param tar dreamwork.std.Tar
---@param file dreamwork.std.Tar.File
local function insertFile( tar, file )
    local file_path = file.path

    local index = tar.file_indexes[ file_path ]
    if index == nil then
        index = tar.file_count + 1
        tar.file_count = index
        tar.file_indexes[ file_path ] = index
    end

    tar.files[ index ] = file
end

--- [SHARED AND MENU]
---
--- Adds the regular file to the archive, replaces the existing entry with the same path.
---
---@param file_path string The path of the file inside of the archive, e.g. `docs/readme.txt`.
---@param content string The file content.
---@param mode integer? The permission bits, `420` (`0644`) by default.
---@return dreamwork.std.Tar.File file The added file.
function Tar:addFile( file_path, content, mode )
    ---@type dreamwork.std.Tar.File
    local file = {
        path = file_path,
        type = "0",
        size = #content,
        mode = mode or 420,
        uid = 0,
        gid = 0,
        timestamp = time_now(),
        link = "",
        user = "",
        group = "",
        content = content
    }

    insertFile( self, file )
    return file
end

--- [SHARED AND MENU]
---
--- Adds the directory to the archive, replaces the existing entry with the same path.
---
---@param directory_path string The path of the directory inside of the archive, `/` is appended if missing.
---@param mode integer? The permission bits, `493` (`0755`) by default.
---@return dreamwork.std.Tar.File file The added directory.
function Tar:addDirectory( directory_path, mode )
    if string_byte( directory_path, -1 ) ~= 0x2F --[[ / ]] then
        directory_path = directory_path .. "/"
    end

    ---@type dreamwork.std.Tar.File
    local file = {
        path = directory_path,
        type = "5",
        size = 0,
        mode = mode or 493,
        uid = 0,
        gid = 0,
        timestamp = time_now(),
        link = "",
        user = "",
        group = "",
        content = ""
    }

    insertFile( self, file )
    return file
end

--- [SHARED AND MENU]
---
--- Adds the symbolic link to the archive, replaces the existing entry with the same path.
---
---@param link_path string The path of the link inside of the archive.
---@param target string The path the link points to.
---@return dreamwork.std.Tar.File file The added link.
function Tar:addSymlink( link_path, target )
    ---@type dreamwork.std.Tar.File
    local file = {
        path = link_path,
        type = "2",
        size = 0,
        mode = 511, -- 0777
        uid = 0,
        gid = 0,
        timestamp = time_now(),
        link = target,
        user = "",
        group = "",
        content = ""
    }

    insertFile( self, file )
    return file
end

--- [SHARED AND MENU]
---
--- Removes the entry from the archive.
---
---@param file_path string The path of the entry inside of the archive.
---@return boolean removed `true` if the entry was removed, `false` if there is no such entry.
function Tar:removeFile( file_path )
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
