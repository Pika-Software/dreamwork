local dreamwork_engine = dreamwork.engine


local vfs           = dreamwork.vfs
local vfs_isFile    = vfs.isFile
local vfs_writeFile = vfs.writeFile


---@type garrysmod.game
local glua_game = dreamwork_engine.requireLibrary( "game" )
local game_MountGMA = glua_game.MountGMA


---@class dreamwork.std
local std = dreamwork.std

local class = std.class

local string = std.string
local string_sub = string.sub
local string_format = string.format
local string_find, string_gsub, string_lower = string.find, string.gsub, string.lower

local table = std.table
local table_concat = table.concat

local json = std.json
local json_serialize = json.serialize
local json_deserialize = json.deserialize

local lzma = std.lzma
local lzma_validate = lzma.validate
local lzma_decompress = lzma.decompress

local time = std.time
local time_now = time.now

local CRC32 = std.CRC32
local CRC32_digest = CRC32.digest

local steam = std.steam
local SteamIdentifier = steam.Identifier

local uuid = std.uuid
local uuid_unique = uuid.unique

local BinaryReader = std.BinaryReader
local BinaryWriter = std.BinaryWriter

local error = std.error
local pcall = std.pcall
local isTable = std.isTable
local tostring = std.tostring
local DecodeError = std.DecodeError


--- `GMAD` as little endian uint32.
---
---@type integer
local GMA_SIGNATURE = 0x44414D47

--- The latest supported format version.
---
---@type integer
local GMA_VERSION = 3

--- The addon types allowed by `gmad`.
---
---@type table<string, boolean>
local types = {
    gamemode = true,
    map = true,
    weapon = true,
    vehicle = true,
    npc = true,
    entity = true,
    tool = true,
    effects = true,
    model = true,
    servercontent = true
}

--- The addon tags allowed by `gmad`.
---
---@type table<string, boolean>
local tags = {
    fun = true,
    roleplay = true,
    scenic = true,
    movie = true,
    realism = true,
    cartoon = true,
    water = true,
    comic = true,
    build = true
}

---@type string[]
local blacklist = {
    "models/*.sw.vtx", -- these variations are unused by the game
    "models/*.360.vtx",
    "models/*.xbox.vtx",

    "gamemodes/*/*/*.txt", -- only in the root gamemode folder please!
    "gamemodes/*/*/*.fgd",

    "gamemodes/*/content/models/*.sw.vtx",
    "gamemodes/*/content/models/*.360.vtx",
    "gamemodes/*/content/models/*.xbox.vtx"
}

---@type string[]
local whitelist = {
    "lua/*.lua",
    "scenes/*.vcd",
    "particles/*.pcf",
    "resource/fonts/*.ttf",
    "scripts/vehicles/*.txt",
    "resource/localization/*/*.properties",
    "maps/*.bsp",
    "maps/*.lmp",
    "maps/*.nav",
    "maps/*.ain",
    "maps/thumb/*.png",
    "sound/*.wav",
    "sound/*.mp3",
    "sound/*.ogg",
    "materials/*.vmt",
    "materials/*.vtf",
    "materials/*.png",
    "materials/*.jpg",
    "materials/*.jpeg",
    "materials/colorcorrection/*.raw",
    "models/*.mdl",
    "models/*.phy",
    "models/*.ani",
    "models/*.vvd",
    "models/*.vtx",

    "gamemodes/*/*.txt",
    "gamemodes/*/*.fgd",

    "gamemodes/*/logo.png",
    "gamemodes/*/icon24.png",
    "gamemodes/*/gamemode/*.lua",
    "gamemodes/*/entities/effects/*.lua",
    "gamemodes/*/entities/weapons/*.lua",
    "gamemodes/*/entities/entities/*.lua",
    "gamemodes/*/backgrounds/*.png",
    "gamemodes/*/backgrounds/*.jpg",
    "gamemodes/*/backgrounds/*.jpeg",
    "gamemodes/*/content/models/*.mdl",
    "gamemodes/*/content/models/*.phy",
    "gamemodes/*/content/models/*.ani",
    "gamemodes/*/content/models/*.vvd",
    "gamemodes/*/content/models/*.vtx",
    "gamemodes/*/content/materials/*.vmt",
    "gamemodes/*/content/materials/*.vtf",
    "gamemodes/*/content/materials/*.png",
    "gamemodes/*/content/materials/*.jpg",
    "gamemodes/*/content/materials/*.jpeg",
    "gamemodes/*/content/materials/colorcorrection/*.raw",
    "gamemodes/*/content/scenes/*.vcd",
    "gamemodes/*/content/particles/*.pcf",
    "gamemodes/*/content/resource/fonts/*.ttf",
    "gamemodes/*/content/scripts/vehicles/*.txt",
    "gamemodes/*/content/resource/localization/*/*.properties",
    "gamemodes/*/content/maps/*.bsp",
    "gamemodes/*/content/maps/*.nav",
    "gamemodes/*/content/maps/*.ain",
    "gamemodes/*/content/maps/thumb/*.png",
    "gamemodes/*/content/sound/*.wav",
    "gamemodes/*/content/sound/*.mp3",
    "gamemodes/*/content/sound/*.ogg",

    -- static version of the data/ folder, only types that are not allowed above
    "data_static/*.txt",
    "data_static/*.dat",
    "data_static/*.json",
    "data_static/*.xml",
    "data_static/*.csv",

    "shaders/fxc/*.vcs"
}

--- Converts `gmad` wildcards to Lua patterns, `*` matches any sequence of bytes, including `/`.
---
---@param list string[]
local function compile_wildcards( list )
    for i = 1, #list, 1 do
        list[ i ] = "^" .. string_gsub( (string_gsub( list[ i ], "[%^%$%(%)%%%.%[%]%+%-%?]", "%%%0" )), "%*", ".*" ) .. "$"
    end

    list[ 0 ] = #list
end

compile_wildcards( blacklist )
compile_wildcards( whitelist )

--- [SHARED AND MENU]
---
--- The file inside of the addon.
---
--- `content` is `nil` for files of a parsed addon until it is read with `Addon:readFile`,
--- the data stays in the addon string at `offset`.
---
---@class dreamwork.std.Addon.File
---@field path string The path of the file inside of the addon, e.g. `lua/autorun/test.lua`.
---@field size integer The size of the file in bytes.
---@field checksum integer The CRC-32 checksum of the file content, `0` if there is no checksum.
---@field content string | nil The file content, `nil` if it is still in the addon data.
---@field offset integer | nil The `1`-based position of the file content in the addon data.

--- [SHARED AND MENU]
---
--- The Garry's Mod addon (`.gma`) archive.
---
--- Parses and builds the same format as `gmad`, legacy LZMA compressed addons are decompressed on parse.
---
--- ```lua
--- local addon = Addon()
--- addon.title = "My Addon"
--- addon.type = "tool"
--- addon.tags = { "fun", "build" }
--- addon:addFile( "lua/autorun/test.lua", "print( 'hello' )" )
---
--- local data = addon:compile()
--- print( Addon( data ):readFile( "lua/autorun/test.lua" ) ) -- print( 'hello' )
--- ```
---
---@class dreamwork.std.Addon : dreamwork.std.Object
---@field __class dreamwork.std.AddonClass
---@field format_version integer The version of the `.gma` format, `3` by default.
---@field steamid dreamwork.std.steam.Identifier The Steam ID of the author, all zero bytes by default (`gmad` doesn't set it).
---@field timestamp integer The Unix timestamp of the creation in seconds.
---@field required_content string[] The content required by the addon, unused by the game.
---@field title string The title of the addon.
---@field description string The description of the addon.
---@field type string The type of the addon, one of `AddonClass.Types`.
---@field tags string[] The tags of the addon, from `1` to `3` of `AddonClass.Tags`.
---@field author string The author of the addon, unused by the game.
---@field version integer The version of the addon, unused by the game.
---@field files dreamwork.std.Addon.File[] The files of the addon.
---@field file_count integer The number of files.
---@field size integer The size of the addon data in bytes without the trailing checksum, `0` until parsed or compiled.
---@field checksum integer The CRC-32 checksum of the addon data, `0` until parsed or compiled.
---@field legacy boolean `true` if the parsed addon was LZMA compressed.
---@field data string | nil The parsed addon data, the content of not yet read files.
---@field file_indexes table<string, integer> The indexes of files in `files` by their paths.
local Addon = class.base( "Addon", false, nil )

--- [SHARED AND MENU]
---
--- The class used to create new `Addon` objects.
---
---@class dreamwork.std.AddonClass : dreamwork.std.Addon, dreamwork.std.Class
---@field __base dreamwork.std.Addon
---@overload fun( data: string?, ratio: number? ): dreamwork.std.Addon
local AddonClass = class.create( Addon )
std.Addon = AddonClass

AddonClass.Signature = GMA_SIGNATURE
AddonClass.Version = GMA_VERSION

--- [SHARED AND MENU]
---
--- Checks if the type is allowed by `gmad`.
---
---@param type_name string The addon type, e.g. `tool`.
---@return boolean is_valid `true` if the type is allowed.
---@nodiscard
function AddonClass.isValidType( type_name )
    return types[ type_name ] == true
end

--- [SHARED AND MENU]
---
--- Checks if the tag is allowed by `gmad`.
---
---@param tag_name string The addon tag, e.g. `fun`.
---@return boolean is_valid `true` if the tag is allowed.
---@nodiscard
function AddonClass.isValidTag( tag_name )
    return tags[ tag_name ] == true
end

--- [SHARED AND MENU]
---
--- Checks if the file path is allowed by the `gmad` whitelist.
---
---@param file_path string The path of the file inside of the addon, e.g. `lua/autorun/test.lua`.
---@return boolean is_allowed `true` if the path is allowed.
---@nodiscard
local function isAllowedPath( file_path )
    for i = 1, blacklist[ 0 ], 1 do
        if string_find( file_path, blacklist[ i ] ) ~= nil then
            return false
        end
    end

    for i = 1, whitelist[ 0 ], 1 do
        if string_find( file_path, whitelist[ i ] ) ~= nil then
            return true
        end
    end

    return false
end

AddonClass.isAllowedPath = isAllowedPath

---@return string
---@nodiscard
---@protected
function Addon:__represent()
    return string_format( "Addon: %p [%s, %d files]", self, self.title, self.file_count )
end

---@param data string?
---@param ratio number?
---@protected
function Addon:__init( data, ratio )
    self.format_version = GMA_VERSION
    self.steamid = SteamIdentifier.INVALID
    self.timestamp = time_now()
    self.required_content = {}
    self.title = "unknown"
    self.description = ""
    self.type = ""
    self.tags = {}
    self.author = "unknown"
    self.version = 1
    self.files = {}
    self.file_count = 0
    self.file_indexes = {}
    self.size = 0
    self.checksum = 0
    self.legacy = false

    if data ~= nil then
        self:parse( data, ratio )
    end
end

---@param reader dreamwork.std.BinaryReader
---@return string str
local function readString( reader )
    local position = reader:tell( true ) + 1

    local str, terminated = reader:readTerminatedString( 0x00 )
    if not terminated then
        error( DecodeError( "unterminated string", position ), 3 )
    end

    return str
end

---@param addon dreamwork.std.Addon
---@param description_str string
local function parseDescription( addon, description_str )
    local success, description = pcall( json_deserialize, description_str )
    if not success or description == nil then
        -- old addons store a plain text description
        addon.description = description_str
        return
    end

    ---@cast description table

    local description_text = description.description
    if description_text == nil then
        addon.description = ""
    else
        addon.description = tostring( description_text )
    end

    local type_name = description.type
    if type_name == nil then
        addon.type = ""
    else
        addon.type = string_lower( tostring( type_name ) )
    end

    local tag_list = {}

    local raw_tags = description.tags
    if isTable( raw_tags ) then
        for i = 1, #raw_tags, 1 do
            tag_list[ i ] = string_lower( tostring( raw_tags[ i ] ) )
        end
    end

    addon.tags = tag_list
end

--- [SHARED AND MENU]
---
--- Replaces the addon with the parsed `.gma` data.
---
--- Legacy LZMA compressed addons are decompressed first, on a separate thread when HolyLib is installed and the call is made from a coroutine.
---
--- File contents are not copied, they are read from the data on demand by `readFile`.
---
--- `ratio` limits how much a legacy addon may expand, see `lzma.decompress`; pass a value like `0.99` for untrusted data,
--- since a few bytes of crafted lzma data can claim up to 4 GiB of output.
---
---@param data string The `.gma` data.
---@param ratio number? The maximum allowed compression ratio of legacy addons, no limit by default.
---@async
function Addon:parse( data, ratio )
    local reader = BinaryReader( data )
    local signature = reader:readUInt( 32, true )

    -- legacy addons are whole `.gma` files compressed with `util.Compress`
    local legacy = signature ~= GMA_SIGNATURE and lzma_validate( data )
    if legacy then
        local success, result = pcall( lzma_decompress, data, ratio )
        if not success then
            error( DecodeError( "invalid addon signature and not a legacy lzma addon, " .. tostring( result ), 1 ), 2 )
        end

        data = result
        reader:open( data )
        signature = reader:readUInt( 32, true )
    end

    if signature ~= GMA_SIGNATURE then
        error( DecodeError( "invalid addon signature", 1 ), 2 )
    end

    local format_version = reader:readUInt( 8 )
    if format_version > GMA_VERSION then
        error( DecodeError( "unsupported addon version " .. format_version, 5 ), 2 )
    end

    ---@type dreamwork.std.steam.Identifier
    local steamid = reader:readClass( SteamIdentifier )
    local timestamp = reader:readInt( 64, true )

    local required_content, required_count = {}, 0

    if format_version > 1 then
        local str

        ::required_content_reader::

        str = readString( reader )

        if str ~= "" then
            required_count = required_count + 1
            required_content[ required_count ] = str
            goto required_content_reader
        end
    end

    local title = readString( reader )
    local description_str = readString( reader )
    local author = readString( reader )

    local version = reader:readInt( 32, true )

    local files, file_count, file_indexes = {}, 0, {}

    -- file entries, the content offsets are relative to the end of the list for now
    local content_offset = 0

    ::file_entry_reader::

    if reader:readUInt( 32, true ) ~= 0 then
        local file_path = readString( reader )

        local size = reader:readInt( 64, true )
        local checksum = reader:readUInt( 32, true )

        file_count = file_count + 1

        files[ file_count ] = {
            path = file_path,
            size = size,
            checksum = checksum,
            offset = content_offset
        }

        file_indexes[ file_path ] = file_count
        content_offset = content_offset + size

        goto file_entry_reader
    end

    local position = reader:tell( true ) + 1

    for i = 1, file_count, 1 do
        local file = files[ i ]
        file.offset = file.offset + position
    end

    if reader:remaining( true ) < content_offset then
        error( DecodeError( "unexpected end of addon data", position ), 2 )
    end

    local size = position + content_offset - 1
    local checksum = 0

    -- the trailing checksum is optional
    if reader:size( true ) >= size + 4 then
        reader:seek( size, true )
        checksum = reader:readUInt( 32, true )
    end

    self.format_version = format_version
    self.steamid = steamid
    self.timestamp = timestamp
    self.required_content = required_content
    self.title = title
    self.description = ""
    self.type = ""
    self.tags = {}
    self.author = author
    self.version = version
    self.files = files
    self.file_count = file_count
    self.file_indexes = file_indexes
    self.size = size
    self.checksum = checksum
    self.legacy = legacy
    self.data = data

    parseDescription( self, description_str )
end

---@param addon dreamwork.std.Addon
---@param file dreamwork.std.Addon.File
---@return string content
local function getContent( addon, file )
    local content = file.content
    if content ~= nil then
        return content
    end

    local offset = file.offset
    if offset == nil then
        error( "file '" .. file.path .. "' has no content and no offset in the addon data", 3 )
    end

    return string_sub( addon.data, offset, offset + file.size - 1 )
end

--- [SHARED AND MENU]
---
--- Builds the `.gma` data of the addon, same as `gmad create`.
---
--- Updates `size` and `checksum` of the addon.
---
--- Doesn't check `type`, `tags` and file paths, use `validate` for that.
---
---@return string data The `.gma` data.
---@nodiscard
function Addon:compile()
    local format_version = self.format_version

    local writer = BinaryWriter()
    writer:writeUInt( GMA_SIGNATURE, 32, true )
    writer:writeUInt( format_version, 8 )
    writer:writeObject( self.steamid )
    writer:writeInt( self.timestamp, 64, true )

    if format_version > 1 then
        local required_content = self.required_content

        for i = 1, #required_content, 1 do
            writer:writeString( required_content[ i ] )
        end

        writer:writeUInt( 0, 8 )
    end

    writer:writeString( self.title )

    writer:writeString( json_serialize( {
        title = self.title,
        description = self.description,
        type = self.type,
        tags = self.tags
    }, false ) )

    writer:writeString( self.author )
    writer:writeInt( self.version, 32, true )

    local files, file_count = self.files, self.file_count

    -- the header and the contents are joined by one `table.concat` with the checksum as the last piece,
    -- the CRC runs over the pieces, so the data is copied only once (45 MiB: 57 ms, 106 ms with `data .. checksum`, server)
    ---@type string[]
    local buffer = {}
    local size = 0

    for i = 1, file_count, 1 do
        local file = files[ i ]

        local content = getContent( self, file )
        buffer[ i + 1 ] = content
        size = size + #content

        writer:writeUInt( i, 32, true )
        writer:writeString( file.path )
        writer:writeInt( #content, 64, true )
        writer:writeUInt( file.checksum, 32, true )
    end

    writer:writeUInt( 0, 32, true )

    local header = writer:compile()
    buffer[ 1 ] = header

    local crc = CRC32()

    for i = 1, file_count + 1, 1 do
        crc:update( buffer[ i ] )
    end

    local checksum = crc:digest()

    self.size = size + #header
    self.checksum = checksum

    writer:open( "" )
    writer:writeUInt( checksum, 32, true )
    buffer[ file_count + 2 ] = writer:compile()

    return table_concat( buffer, "", 1, file_count + 2 )
end

Addon.__tostring = Addon.compile

--- [SHARED AND MENU]
---
--- Returns the file of the addon.
---
---@param file_path string The path of the file inside of the addon.
---@return dreamwork.std.Addon.File | nil file The file, `nil` if there is no such file.
---@nodiscard
function Addon:getFile( file_path )
    local index = self.file_indexes[ file_path ]
    if index == nil then
        return nil
    end

    return self.files[ index ]
end

--- [SHARED AND MENU]
---
--- Returns the content of the file of the addon.
---
---@param file_path string The path of the file inside of the addon.
---@return string | nil content The file content, `nil` if there is no such file.
---@nodiscard
function Addon:readFile( file_path )
    local index = self.file_indexes[ file_path ]
    if index == nil then
        return nil
    end

    return getContent( self, self.files[ index ] )
end

--- [SHARED AND MENU]
---
--- Adds the file to the addon, replaces the existing file with the same path.
---
--- The path is lowercased, same as `gmad` does.
---
---@param file_path string The path of the file inside of the addon, e.g. `lua/autorun/test.lua`.
---@param content string The file content.
---@return dreamwork.std.Addon.File file The added file.
function Addon:addFile( file_path, content )
    file_path = string_lower( file_path )

    ---@type dreamwork.std.Addon.File
    local file = {
        path = file_path,
        size = #content,
        checksum = CRC32_digest( content ),
        content = content
    }

    local index = self.file_indexes[ file_path ]
    if index == nil then
        index = self.file_count + 1
        self.file_count = index
        self.file_indexes[ file_path ] = index
    end

    self.files[ index ] = file
    return file
end

--- [SHARED AND MENU]
---
--- Removes the file from the addon.
---
---@param file_path string The path of the file inside of the addon.
---@return boolean removed `true` if the file was removed, `false` if there is no such file.
function Addon:removeFile( file_path )
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
--- Checks the CRC-32 checksums of the parsed addon data and all files.
---
--- Zero checksums are skipped, same as `gmad`.
---
---@return boolean is_valid `true` if all checksums match.
---@return string | nil file_path The path of the first damaged file, `nil` if the addon data itself is damaged.
---@nodiscard
function Addon:verify()
    local data = self.data
    if data ~= nil and self.checksum ~= 0 and CRC32_digest( string_sub( data, 1, self.size ) ) ~= self.checksum then
        return false, nil
    end

    local files = self.files

    for i = 1, self.file_count, 1 do
        local file = files[ i ]
        local checksum = file.checksum

        if checksum ~= 0 and CRC32_digest( getContent( self, file ) ) ~= checksum then
            return false, file.path
        end
    end

    return true, nil
end

--- [SHARED AND MENU]
---
--- Checks the addon against the `gmad` rules:
--- an allowed type, `1` - `3` unique allowed tags and whitelisted file paths.
---
---@return boolean is_valid `true` if the addon follows the rules.
---@return string | nil reason The reason why the addon is invalid.
---@nodiscard
function Addon:isAllowed()
    if types[ self.type ] == nil then
        return false, "addon type '" .. self.type .. "' is not allowed"
    end

    local tag_list = self.tags
    local tag_count = #tag_list

    if tag_count == 0 then
        return false, "addon must have at least one tag"
    elseif tag_count > 3 then
        return false, "addon must have at most 3 tags"
    end

    for i = 1, tag_count, 1 do
        local tag = tag_list[ i ]
        if tags[ tag ] == nil then
            return false, "addon tag '" .. tag .. "' is not allowed"
        end

        for j = 1, i - 1, 1 do
            if tag_list[ j ] == tag then
                return false, "addon must have unique tags"
            end
        end
    end

    local files = self.files

    for i = 1, self.file_count, 1 do
        local file_path = files[ i ].path
        if not isAllowedPath( file_path ) then
            return false, "file path '" .. file_path .. "' is not allowed"
        end
    end

    return true, nil
end

Addon.__isvalid = Addon.isAllowed

do

    local TMP_DIRECTORY = "/garrysmod/data/dreamwork/tmp/"

    if vfs.isDirectory( TMP_DIRECTORY ) then
        vfs.deleteDirectory( TMP_DIRECTORY, true )
    end

    vfs.createDirectory( TMP_DIRECTORY )

    ---@param uuid_str string
    ---@return boolean
    local function is_free( uuid_str )
        return not vfs_isFile( TMP_DIRECTORY .. uuid_str .. ".gma" )
    end

    --- [SHARED AND MENU]
    ---
    --- Compiles the addon into a temporary `.gma` in `/garrysmod/data/dreamwork/tmp/` and mounts it into the game.
    ---
    --- The file is written asynchronously when called from a coroutine.
    --- Mounted addons cannot be unmounted, so the file stays until the game is closed.
    ---
    ---@return boolean success `true` if the addon was mounted.
    ---@return string[] files If successful, a list of files that have been mounted.
    ---@async
    function Addon:mount()
        local file_name = uuid_unique( is_free ) .. ".gma"
        vfs_writeFile( TMP_DIRECTORY .. file_name, self:compile() )
        return game_MountGMA( "data/dreamwork/tmp/" .. file_name )
    end

end
