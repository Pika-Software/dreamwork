local dreamwork_engine = dreamwork.engine

local vfs = dreamwork.vfs
local vfs_isFile = vfs.isFile
local vfs_writeFile = vfs.writeFile

local cleanup = dreamwork.cleanup
local cleanup_registerTemporary = cleanup.registerTemporary

---@type holylib.addonsystem
local holylib_addonsystem = dreamwork_engine.requireLibrary( "addonsystem" )

---@type garrysmod.steamworks
local glua_steamworks = dreamwork_engine.requireLibrary( "steamworks" )

local std = dreamwork.std

local debug = std.debug
local debug_fempty = debug.fempty

local raw = std.raw
local raw_type = raw.type
local raw_next = raw.next
local raw_select = raw.select

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local math = std.math
local math_min = math.min
local math_max = math.max

local string = std.string
local string_sub = string.sub
local string_byte = string.byte
local string_lower = string.lower
local string_match = string.match
local string_format = string.format
local string_trimSpaces = string.trimSpaces
local string_byteSplit = string.byteSplit

local ascii = std.ascii
local ascii_isDigit = ascii.isDigit

local table = std.table
local table_insert = table.insert

local class = std.class

local error = std.error
local tostring = std.tostring

local HTTPError = std.HTTPError
local ValueError = std.ValueError
local SteamError = std.SteamError

local Future = std.Future
local setTimeout = std.setTimeout

local json = std.json
local json_deserialize = json.deserialize

local http = std.http
local http_client = http.client
local client_request = http_client.request

local futures = std.futures
local futures_run = futures.run

local uuid = std.uuid
local uuid_unique = uuid.unique

---@class dreamwork.std.steam
local steam = std.steam

local steam_Identifier = steam.Identifier
local Identifier_from64 = steam_Identifier.from64

local LUA_CLIENT = std.LUA_CLIENT
local LUA_MENU = std.LUA_MENU
local LUA_SERVER = std.LUA_SERVER


--- Steam [ERemoteStoragePublishedFileVisibility](https://partner.steamgames.com/doc/api/ISteamRemoteStorage#ERemoteStoragePublishedFileVisibility).
---
---@type table<integer, dreamwork.std.steam.workshop.Visibility>
local ERemoteStoragePublishedFileVisibility = {
    [ 0 ] = "public",
    [ 1 ] = "friends-only",
    [ 2 ] = "private",
    [ 3 ] = "unlisted"
}

std.setmetatable( ERemoteStoragePublishedFileVisibility, {
    __index = function( _, code )
        return "unknown code (" .. tostring( code ) .. ")"
    end
} )

--- https://wiki.facepunch.com/gmod/Structures/UGCFileInfo#error
local ugc_error_codes = {
    [ -1 ] = "failed to create query",
    [ -2 ] = "failed to send query",
    [ -3 ] = "Steam API response is invalid",
    [ -4 ] = "failed to get item data from the response",
    [ -5 ] = "Steam Workshop item ID in the response is invalid",
    [ -6 ] = "Steam Workshop item ID in response is mismatching the requested file ID"
}

--- The default timeout of Workshop requests in seconds.
local DEFAULT_TIMEOUT = 30


--- Fails `future` with `SteamError` 16 if it is still pending after `seconds`.
---
--- `false` and `nil` use the default of 30 seconds.
---
---@param future dreamwork.std.Future
---@param seconds number | false | nil
---@param message string
local function setup_timeout( future, seconds, message )
    local delay = DEFAULT_TIMEOUT

    if raw_type( seconds ) == "number" then
        ---@cast seconds number
        delay = seconds
    end

    setTimeout( function()
        if future:isPending() then
            future:setError( SteamError( 16, message ) )
        end
    end, delay )
end


--- [SHARED AND MENU]
---
--- The Steam Workshop API library.
---
---@class dreamwork.std.steam.workshop
---@field available boolean `true` if the Steam Workshop API is available.
local workshop = steam.workshop or {}
steam.workshop = workshop

if LUA_MENU then
    workshop.available = raw_select( 2, (GetAddonStatus or debug_fempty)() ) ~= false
else
    workshop.available = true
end

--- Any protocol, then the Workshop file page, up to `id=`.
--- The id is the following digits. A later segment, begun by `&`, `#`, `/`, or `?`, is ignored.
local WORKSHOP_LINK = "^.-steamcommunity%.com/sharedfiles/filedetails/%?id="

--- Turns any value into a Workshop id.
---
--- `tostring` is trimmed of spaces. A Workshop file link is reduced to the
--- digits after `id=`. Every remaining byte must be an ASCII digit.
---
---@param value any
---@return string id
local function normalize_id( value )
    local id, length = string_trimSpaces( tostring( value ) )

    local lowered = string_lower( id )
    local from_link = string_match( lowered, WORKSHOP_LINK .. "(%d+)$" )
        or string_match( lowered, WORKSHOP_LINK .. "(%d+)[&/#?]" )
    if raw_type( from_link ) == "string" then
        ---@cast from_link string
        id, length = from_link, #from_link
    end

    if length == 0 then
        error( ValueError( value, "invalid Steam Workshop id, expected a non-empty digit string" ), 3 )
    end

    for i = 1, length, 1 do
        if not ascii_isDigit( string_byte( id, i, i ) ) then
            error( ValueError( value, "invalid Steam Workshop id, expected a non-empty digit string" ), 3 )
        end
    end

    return id
end

--- Builds Steam Web API publishedfileids[n] parameter tables.
---
---@param count_key string
---@param ids string[]
---@param id_count integer
---@return table<string, string>
local function prepare_parameters( count_key, ids, id_count )
    local parameters = {}

    for i = 0, id_count - 1, 1 do
        parameters[ "publishedfileids[" .. i .. "]" ] = ids[ i + 1 ]
    end

    parameters[ count_key ] = tostring( id_count )
    return parameters
end

---@class dreamwork.std.steam.workshop.WebTag
---@field tag string

---@class dreamwork.std.steam.workshop.WebFile
---@field result integer
---@field publishedfileid string
---@field title string | nil
---@field description string | nil
---@field preview_url string | nil
---@field visibility integer | nil
---@field tags dreamwork.std.steam.workshop.WebTag[] | nil
---@field banned integer | nil
---@field ban_reason string | nil
---@field lifetime_favorited integer | nil
---@field lifetime_subscriptions integer | nil
---@field views integer | nil
---@field creator string | nil
---@field time_created integer | nil
---@field time_updated integer | nil
---@field filename string | nil
---@field file_size integer | nil
---@field file_url string | nil
---@field consumer_app_id integer | nil
---@field creator_app_id integer | nil
---@field hcontent_file string | nil
---@field hcontent_preview string | nil

---@class dreamwork.std.steam.workshop.WebFileResponse
---@field result integer
---@field publishedfiledetails dreamwork.std.steam.workshop.WebFile[] | nil

---@class dreamwork.std.steam.workshop.WebChild
---@field publishedfileid string
---@field filetype integer
---@field sortorder integer

---@class dreamwork.std.steam.workshop.WebCollection
---@field result integer
---@field publishedfileid string
---@field children dreamwork.std.steam.workshop.WebChild[] | nil

---@class dreamwork.std.steam.workshop.WebCollectionResponse
---@field result integer
---@field collectiondetails dreamwork.std.steam.workshop.WebCollection[] | nil

--- Fields read from `steamworks.FileInfo` and from the Workshop Web API.
---
---@class dreamwork.std.steam.workshop.FilePayload
---@field tags string | dreamwork.std.steam.workshop.WebTag[] | nil
---@field content_descriptors garrysmod.steamworks.ContentDescriptor[] | nil
---@field children ( string | number )[] | nil
---@field title string | nil
---@field description string | nil
---@field visibility integer | nil
---@field installed boolean | nil
---@field disabled boolean | nil
---@field banned boolean | integer | nil
---@field ban_reason string | nil
---@field owner string | number | nil
---@field creator string | nil
---@field fileid string | number | nil
---@field file_id string | number | nil
---@field size integer | nil
---@field file_size integer | nil
---@field previewid string | number | nil
---@field preview_id string | number | nil
---@field previewurl string | nil
---@field preview_url string | nil
---@field previewsize integer | nil
---@field preview_size integer | nil
---@field created integer | nil
---@field time_created integer | nil
---@field created_at integer | nil
---@field updated integer | nil
---@field time_updated integer | nil
---@field updated_at integer | nil
---@field up number | nil
---@field votes_up number | nil
---@field down number | nil
---@field votes_down number | nil
---@field total number | nil
---@field votes_total number | nil
---@field score number | nil
---@field votes_score number | nil
---@field lifetime_favorited integer | nil
---@field favorited integer | nil
---@field lifetime_subscriptions integer | nil
---@field subscriptions integer | nil
---@field views integer | nil
---@field filename string | nil
---@field file_name string | nil
---@field file_url string | nil
---@field consumer_app_id integer | nil
---@field creator_app_id integer | nil
---@field hcontent_file string | nil
---@field hcontent_preview string | nil

do

    --- [SHARED AND MENU]
    ---
    --- A Steam Workshop item (published file).
    ---
    --- Identity-cached: `workshop.Item( id )` returns the same object for the same id.
    ---
    --- Call `:fetch()` to hydrate metadata from Steam.
    ---
    ---@class dreamwork.std.steam.workshop.Item : dreamwork.std.Object
    ---@field __class dreamwork.std.steam.workshop.ItemClass
    ---@field id string The Steam Workshop published-file id.
    ---@field title string | nil
    ---@field description string | nil
    ---@field visibility dreamwork.std.steam.workshop.Visibility | nil
    ---@field warnings dreamwork.std.steam.workshop.Warning[] | nil
    ---@field tags dreamwork.std.steam.workshop.Item.Tag[] | nil
    ---@field installed boolean | nil
    ---@field disabled boolean | nil
    ---@field banned boolean | nil
    ---@field ban_reason string | nil
    ---@field owner_id dreamwork.std.steam.Identifier | nil
    ---@field file_id string | integer | nil
    ---@field file_size integer | nil
    ---@field file_name string | nil
    ---@field file_url string | nil
    ---@field preview_id string | integer | nil
    ---@field preview_url string | nil
    ---@field preview_size integer | nil
    ---@field created_at integer | nil
    ---@field updated_at integer | nil
    ---@field children string[] | nil
    ---@field votes_up number | nil
    ---@field votes_down number | nil
    ---@field votes_total number | nil
    ---@field votes_score number | nil
    ---@field favorited integer | nil
    ---@field subscriptions integer | nil
    ---@field views integer | nil
    ---@field consumer_app_id integer | nil
    ---@field creator_app_id integer | nil
    ---@field hcontent_file string | nil
    ---@field hcontent_preview string | nil
    ---@field url string Steam Workshop page for this item.
    ---@field enabled boolean Whether the engine should mount this item. Writable on the server and in the menu.
    ---@field subscribed boolean Whether the local client is subscribed. Writable in the menu, and on the server when set to `true`.
    local Item = class.base( "steam.workshop.Item", true )

    --- [SHARED AND MENU]
    ---
    --- The class used to create or get `Item` objects.
    ---
    ---@class dreamwork.std.steam.workshop.ItemClass : dreamwork.std.steam.workshop.Item, dreamwork.std.Class
    ---@field __base dreamwork.std.steam.workshop.Item
    ---@overload fun( id: any ): dreamwork.std.steam.workshop.Item
    local ItemClass = class.create( Item )
    workshop.Item = ItemClass

    ---@type table<string, boolean>
    local ITEM_FIELDS = {
        title = true,
        description = true,
        visibility = true,
        warnings = true,
        tags = true,
        installed = true,
        disabled = true,
        banned = true,
        ban_reason = true,
        owner_id = true,
        file_id = true,
        file_size = true,
        file_name = true,
        file_url = true,
        preview_id = true,
        preview_url = true,
        preview_size = true,
        created_at = true,
        updated_at = true,
        children = true,
        votes_up = true,
        votes_down = true,
        votes_total = true,
        votes_score = true,
        favorited = true,
        subscriptions = true,
        views = true,
        consumer_app_id = true,
        creator_app_id = true,
        hcontent_file = true,
        hcontent_preview = true
    }

    ---@type table<string, dreamwork.std.steam.workshop.Item>
    local items_by_id = {}

    ---@type table<dreamwork.std.steam.workshop.Item, string>
    local item_ids = {}
    gc_setTableRules( item_ids, true, false )

    ---@type table<dreamwork.std.steam.workshop.Item, table>
    local item_state = {}
    gc_setTableRules( item_state, true, false )

    ---@param id any
    ---@return dreamwork.std.steam.workshop.Item | nil
    ---@protected
    function ItemClass:__new( id )
        return items_by_id[ normalize_id( id ) ]
    end

    ---@return string
    ---@nodiscard
    ---@protected
    function Item:__represent()
        local state = item_state[ self ]
        local title = state and state.title
        if title ~= nil and title ~= "" then
            return string_format( "steam.workshop.Item: %p [%s][%s]", self, item_ids[ self ], title )
        end

        return string_format( "steam.workshop.Item: %p [%s]", self, item_ids[ self ] )
    end

    local read_enabled, write_enabled
    local read_subscribed, write_subscribed

    local WORKSHOP_PAGE = "https://steamcommunity.com/sharedfiles/filedetails/?id="

    ---@param key string
    ---@return any
    ---@protected
    function Item:__index( key )
        if key == "id" then
            return item_ids[ self ]
        elseif key == "url" then
            return WORKSHOP_PAGE .. item_ids[ self ]
        elseif key == "enabled" then
            if read_enabled == nil then
                error( "workshop item enabled state is not available", 2 )
            end

            return read_enabled( self )
        elseif key == "subscribed" then
            if read_subscribed == nil then
                error( "workshop item subscription state is not available", 2 )
            end

            return read_subscribed( self )
        end

        if ITEM_FIELDS[ key ] then
            local state = item_state[ self ]
            return state and state[ key ]
        end

        return raw.get( Item, key )
    end

    ---@param key string
    ---@param value any
    ---@protected
    function Item:__newindex( key, value )
        if key == "enabled" then
            if write_enabled == nil then
                error( "workshop item enabled state cannot be changed", 2 )
            end

            write_enabled( self, value == true )
            return
        elseif key == "subscribed" then
            if write_subscribed == nil then
                error( "workshop item subscription cannot be changed", 2 )
            end

            write_subscribed( self, value == true )
            return
        end

        error( "attempt to modify unknown workshop item property '" .. key .. "'", 2 )
    end

    ---@param id any
    ---@protected
    function Item:__init( id )
        id = normalize_id( id )
        item_ids[ self ] = id
        items_by_id[ id ] = self
        item_state[ self ] = {}
    end

    --- Applies a `steamworks.FileInfo` / UGCFileInfo / Web API payload onto the item.
    ---
    ---@param self dreamwork.std.steam.workshop.Item
    ---@param info dreamwork.std.steam.workshop.FilePayload | dreamwork.std.steam.workshop.WebFile
    local function apply_file_info( self, info )
        local state = item_state[ self ]

        local tag_list = {}
        local raw_tags = info.tags

        if raw_type( raw_tags ) == "table" then
            ---@cast raw_tags ( dreamwork.std.steam.workshop.WebTag | string )[]

            for i = 1, #raw_tags, 1 do
                local entry = raw_tags[ i ]
                if raw_type( entry ) == "table" then
                    ---@cast entry dreamwork.std.steam.workshop.WebTag
                    tag_list[ i ] = string_lower( entry.tag or "" )
                elseif raw_type( entry ) == "string" then
                    ---@cast entry string
                    tag_list[ i ] = string_lower( entry )
                end
            end
        elseif raw_type( raw_tags ) == "string" then
            ---@cast raw_tags string
            local tags, tag_count = string_byteSplit( raw_tags, 0x2C --[[ , ]] )
            for i = 1, tag_count, 1 do
                tag_list[ i ] = string_lower( tags[ i ] )
            end
        end

        local warnings = info.content_descriptors
        if warnings ~= nil and #warnings == 0 then
            warnings = nil
        end

        local children = info.children
        if children ~= nil and #children == 0 then
            children = nil
        end

        state.title = info.title
        state.description = info.description

        local visibility = info.visibility
        if raw_type( visibility ) == "number" then
            ---@cast visibility integer
            state.visibility = ERemoteStoragePublishedFileVisibility[ visibility ] or "unknown"
        else
            state.visibility = nil
        end

        ---@cast warnings dreamwork.std.steam.workshop.Warning[] | nil
        ---@cast children string[] | nil

        state.warnings = warnings
        state.tags = tag_list
        state.installed = info.installed
        state.disabled = info.disabled
        state.banned = info.banned == true or info.banned == 1
        state.owner_id = Identifier_from64( tostring( info.owner or info.creator or "0" ) )
        state.file_id = info.fileid or info.file_id
        state.file_size = info.size or info.file_size
        state.preview_id = info.previewid or info.preview_id
        state.preview_url = info.previewurl or info.preview_url
        state.preview_size = info.previewsize or info.preview_size
        state.created_at = info.created or info.time_created or info.created_at
        state.updated_at = info.updated or info.time_updated or info.updated_at
        state.children = children
        state.votes_up = info.up or info.votes_up
        state.votes_down = info.down or info.votes_down
        state.votes_total = info.total or info.votes_total
        state.votes_score = info.score or info.votes_score
        state.favorited = info.lifetime_favorited or info.favorited
        state.subscriptions = info.lifetime_subscriptions or info.subscriptions
        state.views = info.views
        state.file_name = info.filename or info.file_name
        state.file_url = info.file_url
        state.consumer_app_id = info.consumer_app_id
        state.creator_app_id = info.creator_app_id
        state.hcontent_file = info.hcontent_file
        state.hcontent_preview = info.hcontent_preview

        if state.banned then
            state.ban_reason = info.ban_reason
        else
            state.ban_reason = nil
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Fetches metadata for this item from Steam and hydrates the object.
    ---
    ---@param seconds number? Timeout in seconds, `30` by default.
    ---@return dreamwork.std.steam.workshop.Item self
    ---@async
    function Item:fetch( seconds )
        local wsid = item_ids[ self ]
        local f = Future()

        glua_steamworks.FileInfo( wsid, function( info )
            if info == nil then
                f:setError( SteamError( nil, string_format( "failed to fetch info for '%s', unknown error", wsid ) ) )
                return
            end

            local error_message = ugc_error_codes[ info.error or 0 ]
            if error_message ~= nil then
                f:setError( SteamError( info.error, error_message ) )
                return
            end

            ---@cast info dreamwork.std.steam.workshop.FilePayload
            apply_file_info( self, info )
            f:setResult( self )
        end )

        setup_timeout( f, seconds, string_format( "fetch info for '%s' timed out", wsid ) )

        return f:await()
    end

    --- [SHARED AND MENU]
    ---
    --- Fetches multiple items from the Steam Web API and hydrates identity-cached objects.
    ---
    ---@param ids string[] Workshop item ids.
    ---@param id_count integer? Number of ids, `#ids` by default.
    ---@param timeout number? Timeout in seconds.
    ---@return dreamwork.std.steam.workshop.Item[] items
    ---@return integer item_count
    ---@nodiscard
    ---@async
    function ItemClass.fetchMany( ids, id_count, timeout )
        if id_count == nil then
            id_count = #ids
        end

        local url = "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/"

        local http_response = client_request( {
            parameters = prepare_parameters( "itemcount", ids, id_count ),
            timeout = timeout,
            method = "POST",
            url = url
        } )

        if http_response.status ~= 200 then
            error( HTTPError( http_response.status, url ), 2 )
        end

        local json_data = json_deserialize( http_response.body or "" )
        if json_data == nil then
            error( "Wrong JSON format - wrong response format", 2 )
        end

        local steam_response = json_data.response
        if raw_type( steam_response ) ~= "table" then
            error( "No response - API returned invalid data", 2 )
        end

        ---@cast steam_response dreamwork.std.steam.workshop.WebFileResponse

        if steam_response.result ~= 1 then
            error( SteamError( steam_response.result ), 2 )
        end

        local publishedfiledetails = steam_response.publishedfiledetails
        if publishedfiledetails == nil then
            error( "No publishedfiledetails - API returned invalid data", 2 )
        end

        local items = {}
        for i = 1, id_count, 1 do
            local details = publishedfiledetails[ i ]
            if raw_type( details ) ~= "table" then
                error( "No publishedfiledetails - API returned invalid data", 2 )
            end

            ---@cast details dreamwork.std.steam.workshop.WebFile

            local item = ItemClass( details.publishedfileid or ids[ i ] )
            if details.result == 1 then
                apply_file_info( item, details )
            else
                error( SteamError( details.result, string_format( "item '%s'", item.id ) ), 2 )
            end

            items[ i ] = item
        end

        return items, id_count
    end

    do

        local CACHE_DIRECTORY = "/garrysmod/data/dreamwork/cache/workshop/"

        ---@param uuid_str string
        ---@return boolean
        local function is_free( uuid_str )
            return not vfs_isFile( CACHE_DIRECTORY .. uuid_str .. ".gma" )
        end

        ---@param f dreamwork.std.Future
        ---@param wsid string
        ---@param file_path string?
        ---@param file_class garrysmod.File?
        ---@async
        local function perform_response( f, wsid, file_path, file_class )
            if file_path ~= nil and vfs_isFile( "/garrysmod/" .. file_path ) then
                f:setResult( "/game/" .. file_path )
                return
            end

            if file_class == nil then
                f:setError( SteamError( nil, string_format( "failed to download addon '%s', unknown error", wsid ) ) )
                return
            end

            local new_path = CACHE_DIRECTORY .. uuid_unique( is_free ) .. ".gma"
            vfs_writeFile( new_path, file_class:Read( file_class:Size() ) )
            cleanup_registerTemporary( new_path )
            f:setResult( new_path )
        end

        --- [SHARED AND MENU]
        ---
        --- Downloads this item's `.gma` from the Steam Workshop.
        ---
        --- A copy outside of the game file system is written to `/garrysmod/data/dreamwork/cache/workshop/`
        --- and registered with `dreamwork.cleanup`. It is deleted once its time to live passes.
        ---
        ---@param seconds number? Timeout in seconds, `30` by default.
        ---@return string file_path Absolute path to the downloaded `.gma`.
        ---@async
        function Item:download( seconds )
            local wsid = item_ids[ self ]
            local f = Future()

            if glua_steamworks.DownloadUGC == nil then
                f:setError( SteamError( nil, string_format( "failed to download addon '%s', part of Steam Workshop API is missing", wsid ) ) )
            else
                glua_steamworks.DownloadUGC( wsid, function( file_path, file_class )
                    futures_run( perform_response, nil, f, wsid, file_path, file_class )
                end )

                setup_timeout( f, seconds, string_format( "failed to download addon '%s', timed out", wsid ) )
            end

            return f:await()
        end

    end

    if LUA_CLIENT or LUA_MENU then

        ---@param self dreamwork.std.steam.workshop.Item
        ---@return boolean
        function read_enabled( self )
            return glua_steamworks.ShouldMountAddon( item_ids[ self ] ) == true
        end

        ---@param self dreamwork.std.steam.workshop.Item
        ---@return boolean
        function read_subscribed( self )
            return glua_steamworks.IsSubscribed( item_ids[ self ] ) == true
        end

        --- [CLIENT AND MENU]
        ---
        --- Downloads the preview icon and returns an absolute path to the file.
        ---
        ---@param uncompress boolean? `true` by default.
        ---@param seconds number? Timeout in seconds, `30` by default.
        ---@return string file_path
        ---@async
        function Item:downloadIcon( uncompress, seconds )
            local wsid = item_ids[ self ]
            local f = Future()

            glua_steamworks.Download( wsid, uncompress ~= false, function( file_path )
                if file_path == nil then
                    f:setError( SteamError( nil, string_format( "failed to download icon file for '%s', unknown error", wsid ) ) )
                else
                    f:setResult( "/game/" .. file_path )
                end
            end )

            setup_timeout( f, seconds, string_format( "failed to download icon file for '%s', timed out", wsid ) )

            return f:await()
        end

    end

    if LUA_SERVER then

        ---@param self dreamwork.std.steam.workshop.Item
        ---@return boolean
        function read_enabled( self )
            return holylib_addonsystem.ShouldMount( item_ids[ self ] ) == true
        end

        ---@param self dreamwork.std.steam.workshop.Item
        ---@param enabled boolean
        function write_enabled( self, enabled )
            holylib_addonsystem.SetShouldMount( item_ids[ self ], enabled )
        end

        ---@param self dreamwork.std.steam.workshop.Item
        ---@param subscribed boolean
        function write_subscribed( self, subscribed )
            if subscribed ~= true then
                error( "addonsystem cannot unsubscribe a Workshop item", 3 )
            end

            holylib_addonsystem.Subscribe( item_ids[ self ] )
        end

    end

    if LUA_MENU then

        local steamworks_Publish = glua_steamworks.Publish

        ---@param self dreamwork.std.steam.workshop.Item
        ---@param enabled boolean
        function write_enabled( self, enabled )
            glua_steamworks.SetShouldMountAddon( item_ids[ self ], enabled )
        end

        ---@param self dreamwork.std.steam.workshop.Item
        ---@param subscribed boolean
        function write_subscribed( self, subscribed )
            (subscribed and glua_steamworks.Subscribe or glua_steamworks.Unsubscribe)( item_ids[ self ] )
        end

        ---@param file_path string
        ---@return string
        local function publish_path( file_path )
            if string_byte( file_path, 1 ) == 0x2F --[[ / ]] then
                return string_sub( file_path, 2 )
            end

            error( ValueError( file_path, "invalid file path, expected absolute path" ), 3 )
        end

        --- [MENU]
        ---
        --- Publishes a file to the Steam Workshop and returns the new item.
        ---
        ---@param file_path string Absolute path to the addon file.
        ---@param image_path string Absolute path to the preview image.
        ---@param title string
        ---@param description string?
        ---@param tags string[]
        ---@param change_log string?
        ---@param seconds number | false | nil
        ---@return dreamwork.std.steam.workshop.Item item
        ---@nodiscard
        ---@async
        function ItemClass.publish( file_path, image_path, title, description, tags, change_log, seconds )
            local f = Future()

            file_path = publish_path( file_path )

            steamworks_Publish( file_path, image_path, title, description or "", tags, function( wsid, errorMsg )
                if raw_type( errorMsg ) == "string" then
                    ---@cast errorMsg string
                    f:setError( errorMsg )
                else
                    f:setResult( wsid )
                end
            end, nil, change_log )

            setup_timeout( f, seconds, "failed to publish addon, timed out" )

            return ItemClass( f:await() )
        end

        --- [MENU]
        ---
        --- Updates this Workshop publication.
        ---
        ---@param file_path string Absolute path to the addon file.
        ---@param image_path string Absolute path to the preview image.
        ---@param title string
        ---@param description string?
        ---@param tags string[]
        ---@param change_log string?
        ---@param seconds number | false | nil
        ---@return dreamwork.std.steam.workshop.Item self
        ---@async
        function Item:update( file_path, image_path, title, description, tags, change_log, seconds )
            local wsid = item_ids[ self ]
            local f = Future()

            file_path = publish_path( file_path )

            steamworks_Publish( file_path, image_path, title, description or "", tags, function( _, errorMsg )
                if raw_type( errorMsg ) == "string" then
                    ---@cast errorMsg string
                    f:setError( errorMsg )
                else
                    f:setResult( self )
                end
            end, tonumber( wsid, 10 ), change_log )

            setup_timeout( f, seconds, string_format( "failed to update addon '%s', timed out", wsid ) )

            return f:await()
        end

        --- [MENU]
        ---
        --- Marks this item as completed.
        function Item:markAsCompleted()
            glua_steamworks.SetFileCompleted( item_ids[ self ] )
        end

        --- [MENU]
        ---
        --- Marks this item as played.
        function Item:markAsPlayed()
            glua_steamworks.SetFilePlayed( item_ids[ self ] )
        end

        --- [MENU]
        ---
        --- Votes for this item.
        ---
        ---@param upvote boolean `true` to vote up, `false` to vote down.
        function Item:vote( upvote )
            glua_steamworks.Vote( item_ids[ self ], upvote )
        end

    end

    do

        ---@type table<string, string>
        local type2type = {
            subscribed = "followed",
            friendfavorite = "friend_favs"
        }

        --- Normalizes `steamworks.GetList` results into a 1-based id array.
        ---
        ---@param data garrysmod.steamworks.ListResult
        ---@return string[] ids
        ---@return integer id_count
        ---@return integer total
        local function normalize_list( data )
            local ids = data.results or {}
            table_insert( ids, 1, ids[ 0 ] )
            ids[ 0 ] = nil

            ---@cast ids string[]
            return ids, data.numresults or #ids, data.totalresults or 0
        end

        --- [SHARED AND MENU]
        ---
        --- Searches the Workshop and returns matching items.
        ---
        ---@param params dreamwork.std.steam.workshop.Item.SearchParams
        ---@param seconds number?
        ---@return dreamwork.std.steam.workshop.Item[] items
        ---@return integer item_count
        ---@return integer total
        ---@nodiscard
        ---@async
        function ItemClass.search( params, seconds )
            params = params or {}
            local f = Future()

            local item_type = params.type or "latest"

            glua_steamworks.GetList(
                type2type[ item_type ] or item_type,
                params.tags,
                math_max( 0, params.offset or 0 ),
                math_min( math_max( params.count or 50, 1 ), 50 ),
                math_min( math_min( params.days or 365, 1 ), 365 ),
                params.owned and "1" or (params.steamid64 or "0"),
                function( data )
                    f:setResult( data )
                end
            )

            setup_timeout( f, seconds or params.timeout, "workshop search timed out" )

            local data = f:await()

            if raw_type( data ) ~= "table" then
                error( "No response - workshop search returned invalid data", 2 )
            end

            ---@cast data garrysmod.steamworks.ListResult

            local ids, id_count, total = normalize_list( data )
            local items = {}

            for i = 1, id_count, 1 do
                items[ i ] = ItemClass( ids[ i ] )
            end

            return items, id_count, total
        end

        --- [SHARED AND MENU]
        ---
        --- Performs a quick search for publications.
        ---
        ---@param wtype dreamwork.std.steam.workshop.Item.SearchType?
        ---@param wtags string[]?
        ---@param woffset integer?
        ---@param timeout number?
        ---@return dreamwork.std.steam.workshop.Item[] items
        ---@return integer item_count
        ---@return integer total
        ---@nodiscard
        ---@async
        function ItemClass.quickSearch( wtype, wtags, woffset, timeout )
            return ItemClass.search( {
                type = wtype or "latest",
                tags = wtags,
                offset = woffset or 0,
                count = 50,
                days = 365,
                owned = false,
                steamid64 = "0"
            }, timeout )
        end

        --- [SHARED AND MENU]
        ---
        --- Returns publications published by the local Steam user.
        ---
        ---@param wtype dreamwork.std.steam.workshop.Item.SearchType?
        ---@param wtags string[]?
        ---@param woffset integer?
        ---@param timeout number?
        ---@return dreamwork.std.steam.workshop.Item[] items
        ---@return integer item_count
        ---@return integer total
        ---@nodiscard
        ---@async
        function ItemClass.getPublished( wtype, wtags, woffset, timeout )
            return ItemClass.search( {
                type = wtype or "latest",
                tags = wtags,
                offset = woffset or 0,
                count = 50,
                days = 365,
                owned = true
            }, timeout )
        end

    end

end

do

    --- [SHARED AND MENU]
    ---
    --- A Steam Workshop collection.
    ---
    --- Identity-cached: `workshop.Collection( id )` returns the same object for the same id.
    ---
    --- Call `:fetch()` to hydrate children from the Steam Web API.
    ---
    ---@class dreamwork.std.steam.workshop.Collection : dreamwork.std.Object
    ---@field __class dreamwork.std.steam.workshop.CollectionClass
    ---@field id string The Steam Workshop collection id.
    ---@field items dreamwork.std.steam.workshop.Item[] | nil Ordered child items.
    ---@field item_count integer | nil
    local Collection = class.base( "steam.workshop.Collection", true )

    --- [SHARED AND MENU]
    ---
    --- The class used to create or get `Collection` objects.
    ---
    ---@class dreamwork.std.steam.workshop.CollectionClass : dreamwork.std.steam.workshop.Collection, dreamwork.std.Class
    ---@field __base dreamwork.std.steam.workshop.Collection
    ---@overload fun( id: any ): dreamwork.std.steam.workshop.Collection
    local CollectionClass = class.create( Collection )
    ---@cast CollectionClass dreamwork.std.steam.workshop.CollectionClass
    workshop.Collection = CollectionClass

    ---@type table<string, boolean>
    local COLLECTION_FIELDS = {
        items = true,
        item_count = true
    }

    ---@type table<string, dreamwork.std.steam.workshop.Collection>
    local collections_by_id = {}

    ---@type table<dreamwork.std.steam.workshop.Collection, string>
    local collection_ids = {}
    gc_setTableRules( collection_ids, true, false )

    ---@type table<dreamwork.std.steam.workshop.Collection, table>
    local collection_state = {}
    gc_setTableRules( collection_state, true, false )

    ---@param id any
    ---@return dreamwork.std.steam.workshop.Collection | nil
    ---@protected
    function CollectionClass:__new( id )
        return collections_by_id[ normalize_id( id ) ]
    end

    ---@return string
    ---@nodiscard
    ---@protected
    function Collection:__represent()
        local state = collection_state[ self ]
        local count = state and state.item_count
        if count ~= nil then
            return string_format( "steam.workshop.Collection: %p [%s][%d items]", self, collection_ids[ self ], count )
        end

        return string_format( "steam.workshop.Collection: %p [%s]", self, collection_ids[ self ] )
    end

    ---@param key string
    ---@return any
    ---@protected
    function Collection:__index( key )
        if key == "id" then
            return collection_ids[ self ]
        end

        if COLLECTION_FIELDS[ key ] then
            local state = collection_state[ self ]
            return state and state[ key ]
        end

        return raw.get( Collection, key )
    end

    ---@param collection dreamwork.std.steam.workshop.Collection
    ---@param key any
    ---@return integer | nil
    ---@return dreamwork.std.steam.workshop.Item | nil
    local function collection_next( collection, key )
        local state = collection_state[ collection ]
        local items = state and state.items
        if items == nil then
            return nil
        end

        return raw_next( items, key )
    end

    ---@return fun( collection: dreamwork.std.steam.workshop.Collection, key: any ): integer | nil, dreamwork.std.steam.workshop.Item | nil
    ---@protected
    function Collection:__pairs()
        return collection_next
    end

    ---@param id any
    ---@protected
    function Collection:__init( id )
        id = normalize_id( id )
        collection_ids[ self ] = id
        collections_by_id[ id ] = self
        collection_state[ self ] = {}
    end

    --- Applies one GetCollectionDetails entry onto the collection.
    ---
    ---@param self dreamwork.std.steam.workshop.Collection
    ---@param entry dreamwork.std.steam.workshop.WebCollection
    local function apply_collection_details( self, entry )
        local state = collection_state[ self ]
        local children = entry.children or {}
        local child_count = #children

        ---@type { order: integer, item: dreamwork.std.steam.workshop.Item }[]
        local ranked = {}
        for i = 1, child_count, 1 do
            local child = children[ i ]
            if raw_type( child ) ~= "table" then
                error( "No collectiondetails - API returned invalid data", 2 )
            end

            ---@cast child dreamwork.std.steam.workshop.WebChild

            ranked[ i ] = {
                order = child.sortorder or i,
                item = workshop.Item( child.publishedfileid )
            }
        end

        table.sort( ranked, function( a, b )
            return a.order < b.order
        end )

        local items = {}
        for i = 1, child_count, 1 do
            items[ i ] = ranked[ i ].item
        end

        state.items = items
        state.item_count = child_count
    end

    --- [SHARED AND MENU]
    ---
    --- Fetches this collection's children from the Steam Web API and hydrates the object.
    ---
    ---@param timeout number? Timeout in seconds.
    ---@return dreamwork.std.steam.workshop.Collection self
    ---@async
    function Collection:fetch( timeout )
        local wsid = collection_ids[ self ]

        local url = "https://api.steampowered.com/ISteamRemoteStorage/GetCollectionDetails/v1/"

        local http_response = client_request( {
            parameters = prepare_parameters( "collectioncount", { wsid }, 1 ),
            timeout = timeout,
            method = "POST",
            url = url
        } )

        if http_response.status ~= 200 then
            error( HTTPError( http_response.status, url ), 2 )
        end

        local json_data = json_deserialize( http_response.body or "" )
        if json_data == nil then
            error( "Wrong JSON format - wrong response format", 2 )
        end

        local steam_response = json_data.response
        if raw_type( steam_response ) ~= "table" then
            error( "No response - API returned invalid data", 2 )
        end

        ---@cast steam_response dreamwork.std.steam.workshop.WebCollectionResponse

        if steam_response.result ~= 1 then
            error( SteamError( steam_response.result ), 2 )
        end

        local collectiondetails = steam_response.collectiondetails
        if collectiondetails == nil or raw_type( collectiondetails[ 1 ] ) ~= "table" then
            error( "No collectiondetails - API returned invalid data", 2 )
        end

        local entry = collectiondetails[ 1 ]
        ---@cast entry dreamwork.std.steam.workshop.WebCollection

        if entry.result ~= 1 then
            error( SteamError( entry.result ), 2 )
        end

        apply_collection_details( self, entry )
        return self
    end

    --- [SHARED AND MENU]
    ---
    --- Fetches multiple collections and returns identity-cached objects.
    ---
    ---@param ids string[] Workshop collection ids.
    ---@param id_count integer? Number of ids, `#ids` by default.
    ---@param timeout number? Timeout in seconds.
    ---@return dreamwork.std.steam.workshop.Collection[] collections
    ---@return integer collection_count
    ---@nodiscard
    ---@async
    function CollectionClass.fetchMany( ids, id_count, timeout )
        if id_count == nil then
            id_count = #ids
        end

        local url = "https://api.steampowered.com/ISteamRemoteStorage/GetCollectionDetails/v1/"

        local http_response = client_request( {
            parameters = prepare_parameters( "collectioncount", ids, id_count ),
            timeout = timeout,
            method = "POST",
            url = url
        } )

        if http_response.status ~= 200 then
            error( HTTPError( http_response.status, url ), 2 )
        end

        local json_data = json_deserialize( http_response.body or "" )
        if json_data == nil then
            error( "Wrong JSON format - wrong response format", 2 )
        end

        local steam_response = json_data.response
        if raw_type( steam_response ) ~= "table" then
            error( "No response - API returned invalid data", 2 )
        end

        ---@cast steam_response dreamwork.std.steam.workshop.WebCollectionResponse

        if steam_response.result ~= 1 then
            error( SteamError( steam_response.result ), 2 )
        end

        local collectiondetails = steam_response.collectiondetails
        if collectiondetails == nil then
            error( "No collectiondetails - API returned invalid data", 2 )
        end

        local collections = {}
        for i = 1, id_count, 1 do
            local entry = collectiondetails[ i ]
            if raw_type( entry ) ~= "table" then
                error( "No collectiondetails - API returned invalid data", 2 )
            end

            ---@cast entry dreamwork.std.steam.workshop.WebCollection

            local collection = CollectionClass( entry.publishedfileid or ids[ i ] )
            if entry.result == 1 then
                apply_collection_details( collection, entry )
            else
                error( SteamError( entry.result, string_format( "collection '%s'", collection.id ) ), 2 )
            end

            collections[ i ] = collection
        end

        return collections, id_count
    end

end

if LUA_SERVER then

    --- [SERVER AND MENU]
    ---
    --- Refreshes the engine addon system so it picks up addon changes.
    ---
    --- Applies local Workshop addon changes after `enabled` or `subscribed` is set.
    ---
    function workshop.apply()
        holylib_addonsystem.Refresh()
    end

    --- [SERVER]
    ---
    --- Clears the engine addon system, removing active addons.
    ---
    --- Uses HolyLib `addonsystem.Clear`.
    function workshop.clear()
        holylib_addonsystem.Clear()
    end

end

if LUA_MENU then

    function workshop.apply()
        glua_steamworks.ApplyAddons()
    end

end
