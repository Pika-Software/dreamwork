local dreamwork_engine = dreamwork.engine
local dreamwork_Logger = dreamwork.Logger

local engine_hook = dreamwork_engine.hook

local dreamwork_sandbox = dreamwork.sandbox
local sandbox_owner = dreamwork_sandbox.owner
local sandbox_claim = dreamwork_sandbox.claim
local sandbox_prefix = dreamwork_sandbox.prefix

---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_type = raw.type
local raw_pairs = raw.pairs

local class = std.class

local debug = std.debug
local debug_getmetatable = debug.getmetatable

local string = std.string
local string_find, string_match = string.find, string.match
local string_format, string_sub = string.format, string.sub

local console = std.console
local console_Variable = console.Variable

local fluent = std.fluent
local fluent_normalizeTag = fluent.normalizeTag

local FluentNumber = fluent.Number
local FluentBundle = fluent.Bundle
local FluentResource = fluent.Resource
local FluentDateTime = fluent.DateTime

local error = std.error
local isObject = std.isObject
local setmetatable = std.setmetatable

local Event = std.Event

local LUA_CLIENT = std.LUA_CLIENT
local LUA_SERVER = std.LUA_SERVER
local LUA_MENU = std.LUA_MENU

local vfs = dreamwork.vfs
local vfs_isFile = vfs.isFile
local vfs_readFile = vfs.readFile


--- [SHARED AND MENU]
---
--- The localization library, the runtime layer over `std.fluent`.
---
--- Every addon has its own `i18n.Localization`, translations are FTL files
--- at `data_static/localization/<language>/<name>.txt`, e.g. `data_static/localization/pt-BR/myaddon.txt`.
---
--- Localizations created by a package get its id as the prefix and read the files of the package instead,
--- `localization/<language>/<name>.ftl`, e.g. `localization/pt-BR/main.ftl`.
---
--- Messages are looked up in the current language, its parent languages and the fallback one: `pt-BR` -> `pt` -> `en`.
---
--- ```lua
--- local l10n = i18n.Localization( "myaddon" )
---
--- print( l10n:get( "files", { count = 3 } ) ) -- 3 files
--- print( l10n:get( "login.placeholder" ) ) -- attributes are `message.attribute`
--- ```
---
---@class dreamwork.std.i18n
---@field language string The current language tag, e.g. `"pt-BR"`. **READ-ONLY**
---@field fallback string The language used when a message is missing in the current one, `"en"` by default. **READ-ONLY**
local i18n = {}
std.i18n = i18n

--- The folder of translation files, `data_static` of the `GAME` search path.
---
---@type string
local ROOT_FOLDER = "/game/data_static/localization/"

---@type string
local fallback = "en"
i18n.fallback = fallback

--- The language set by `i18n.setLanguage`, `nil` follows the game language.
---
---@type string | nil
local override

--- The language of the game ( `gmod_language` ), `nil` on the server.
---
---@type string | nil
local game_language

---@type string
local language = fallback
i18n.language = language

--- The languages reported by clients, filled on the server only.
---
---@type table<dreamwork.std.Client, string>
local client_languages = {}
setmetatable( client_languages, { __mode = "k" } )

--- [SHARED AND MENU]
---
--- Called when the current language changes.
---
--- Arguments: `language: string`, `previous: string`.
---
local LanguageChanged = Event( "i18n.LanguageChanged" )
i18n.LanguageChanged = LanguageChanged

--- Normalizes the tag, `nil` for empty and malformed ones.
---
---@param tag string | nil
---@return string | nil
local function normalize( tag )
    if tag == nil or #tag == 0 or #tag > 35 or string_find( tag, "^[%w%-_]+$" ) == nil then
        return nil
    end

    return fluent_normalizeTag( tag )
end

--- Appends the tag and its parent tags to the list, `pt-BR` -> `pt-BR`, `pt`.
---
---@param tags string[]
---@param count integer
---@param tag string
---@return integer count
local function append_tags( tags, count, tag )
    ::append::

    local exists = false

    for index = 1, count, 1 do
        if tags[ index ] == tag then
            exists = true
            break
        end
    end

    if not exists then
        count = count + 1
        tags[ count ] = tag
    end

    local separator = string_match( tag, "()%-[^%-]*$" )
    if separator ~= nil then
        tag = string_sub( tag, 1, separator - 1 )
        goto append
    end

    return count
end

--- [SHARED AND MENU]
---
--- Returns the lookup order of the language, the language, its parents and the fallback language.
---
--- ```lua
--- i18n.getChain( "pt-BR" ) -- { "pt-BR", "pt", "en" }
--- ```
---
---@param tag string The language tag.
---@return string[] tags The language tags in the lookup order.
---@return integer tag_count The number of tags.
---@nodiscard
local function getChain( tag )
    local tags = {}
    local count = append_tags( tags, 0, tag )
    return tags, append_tags( tags, count, fallback )
end

i18n.getChain = getChain

---@type table<string, dreamwork.std.i18n.Localization>
local registry = {}

--- Clears the cached bundles of every localization.
local function reset_all()
    for _, l10n in raw_pairs( registry ) do
        l10n:reload()
    end
end

local function update_language()
    local tag = override or game_language or fallback
    if tag == language then return end

    local previous = language

    language = tag
    i18n.language = tag

    LanguageChanged( tag, previous )
end

--- [SHARED AND MENU]
---
--- Returns the current language.
---
--- On the server, the language of the client can be requested, clients report their language once initialized.
---
---@param client dreamwork.std.Client? The client, the server only.
---@return string language The language tag, e.g. `"pt-BR"`.
---@nodiscard
function i18n.getLanguage( client )
    if client == nil then
        return language
    end

    return client_languages[ client ] or fallback
end

--- [SHARED AND MENU]
---
--- Overrides the current language, `nil` follows the game language ( `gmod_language` ) again.
---
--- The server has no game language, its language is the fallback one by default.
---
---@param tag string? The language tag.
function i18n.setLanguage( tag )
    if tag == nil then
        override = nil
    else
        override = normalize( tag )

        if override == nil then
            error( string_format( "invalid language tag '%s'", tag ), 2 )
        end
    end

    update_language()
end

--- [SHARED AND MENU]
---
--- Sets the language used when a message is missing in the current one.
---
---@param tag string The language tag, `"en"` by default.
function i18n.setFallback( tag )
    local normalized = normalize( tag )
    if normalized == nil then
        error( string_format( "invalid language tag '%s'", tag ), 2 )
    end

    if normalized == fallback then return end

    fallback = normalized
    i18n.fallback = normalized

    reset_all()
    update_language()
end

if LUA_CLIENT or LUA_MENU then

    local gmod_language = console_Variable.get( "gmod_language", "string" )

    game_language = normalize( gmod_language.value )
    update_language()

    gmod_language:attach( function( _, value )
        game_language = normalize( value )
        update_language()
    end )

end

--- The reusable list of formatting errors.
---
---@type dreamwork.std.Error[]
local format_errors = {}

--- [SHARED AND MENU]
---
--- The translations of one addon, created once per name, `Localization( name )` returns the existing one.
---
--- Translation files are read lazily with `vfs`, on the first lookup of a language,
--- asynchronously if that lookup happens inside a coroutine.
---
---@class dreamwork.std.i18n.Localization : dreamwork.std.Object
---@field __class dreamwork.std.i18n.LocalizationClass
---@field name string The name of the localization, `{id}::{name}` for packages. **READ-ONLY**
---@field Received dreamwork.std.Event The client event of messages sent by `Localization:send`, arguments: `l10n: dreamwork.std.Localization`, `id: string`, `text: string`, `args: table | nil`.
---@field protected sources table<string, string[]> The sources added by `Localization:addSource` by language tags.
---@field protected bundles table<string, dreamwork.std.FluentBundle | false> The loaded bundles by language tags, `false` if the language has no translations.
---@field protected chains table<string, dreamwork.std.FluentBundle[]> The bundles in the lookup order by requested language tags.
---@field protected reported table<string, boolean> The message identifiers with reported formatting errors.
---@field protected directory string The directory of translation files, with the trailing `/`.
---@field protected file_name string The name of translation files, with the extension.
local Localization = class.base( "i18n.Localization", false, nil )

--- Unregisters the localization of an unloaded package.
---
---@param l10n dreamwork.std.i18n.Localization
local function release( l10n )
    local name = l10n.name
    if registry[ name ] == l10n then
        registry[ name ] = nil
    end
end

---@param name string
---@protected
function Localization:__init( name )
    local owner = sandbox_owner( 2 )
    if owner == nil then
        self.directory = ROOT_FOLDER
        self.file_name = name .. ".txt"
    else
        name = sandbox_prefix( owner, name )
        sandbox_claim( owner, self, release )

        self.directory = owner.root .. "/localization/"
        self.file_name = string_sub( name, #owner.id + 3 ) .. ".ftl"
    end

    self.name = name
    self.Received = Event( "i18n.Localization.Received" )

    self.sources = {}
    self.bundles = {}
    self.chains = {}
    self.reported = {}

    registry[ name ] = self
end

---@return string
---@nodiscard
---@protected
function Localization:__represent()
    return string_format( "Localization: %p [%s]", self, self.name )
end

--- Parses the source into the bundle, syntax errors are logged.
---
---@param bundle dreamwork.std.FluentBundle
---@param text string
---@param origin string
local function add_source( bundle, text, origin )
    local resource = FluentResource( text )

    local errors = resource.errors
    for index = 1, #errors, 1 do
        dreamwork_Logger:warn( "Localization '%s': %s", origin, errors[ index ] )
    end

    bundle:addResource( resource, true )
end

--- Returns the bundle of the language, `false` if there are no translations.
---
---@param tag string
---@return dreamwork.std.FluentBundle | false
---@protected
function Localization:loadBundle( tag )
    local bundles = self.bundles

    local bundle = bundles[ tag ]
    if bundle ~= nil then
        return bundle
    end

    local file_path = self.directory .. tag .. "/" .. self.file_name

    ---@type string | nil
    local text
    if vfs_isFile( file_path ) then
        text = vfs_readFile( file_path )
    end

    local sources = self.sources[ tag ]

    if text == nil and sources == nil then
        bundles[ tag ] = false
        return false
    end

    bundle = FluentBundle( tag )

    if text ~= nil then
        add_source( bundle, text, file_path )
    end

    if sources ~= nil then
        for index = 1, #sources, 1 do
            add_source( bundle, sources[ index ], self.name .. " (" .. tag .. ")" )
        end
    end

    bundles[ tag ] = bundle
    return bundle
end

--- Returns the bundles in the lookup order of the language.
---
---@param tag string
---@return dreamwork.std.FluentBundle[]
---@protected
function Localization:loadChain( tag )
    local chains = self.chains

    local chain = chains[ tag ]
    if chain ~= nil then
        return chain
    end

    chain = {}

    local count = 0
    local tags, tag_count = getChain( tag )

    for index = 1, tag_count, 1 do
        local bundle = self:loadBundle( tags[ index ] )
        if bundle then
            count = count + 1
            chain[ count ] = bundle
        end
    end

    chains[ tag ] = chain
    return chain
end

--- Splits `message.attribute` identifiers.
---
---@param id string
---@return string message_id
---@return string | nil attribute
local function split_id( id )
    local separator = string_find( id, ".", 2, true )
    if separator == nil then
        return id, nil
    end

    return string_sub( id, 1, separator - 1 ), string_sub( id, separator + 1 )
end

--- [SHARED AND MENU]
---
--- Formats the message in the current language, or in the given one.
---
--- Formatting errors ( e.g. missing variables ) are logged once per message,
--- the message identifier is returned if no language of the lookup order has the message.
---
---@param id string The message identifier, `message.attribute` formats the attribute.
---@param args table<string, dreamwork.std.fluent.Argument>? The variables.
---@param tag string? The language tag, the current language by default.
---@return string text The formatted message, or `id` if it is missing.
---@nodiscard
function Localization:get( id, args, tag )
    local chain = self:loadChain( tag or language )

    local message_id, attribute = split_id( id )

    for index = 1, #chain, 1 do
        local bundle = chain[ index ]

        local message = bundle.messages[ message_id ]
        if message ~= nil then
            local pattern
            if attribute == nil then
                pattern = message.value
            else
                pattern = message.attributes[ attribute ]
            end

            if pattern ~= nil then
                local text = bundle:formatPattern( pattern, args, format_errors )

                local error_count = #format_errors
                if error_count ~= 0 then
                    if not self.reported[ id ] then
                        self.reported[ id ] = true
                        dreamwork_Logger:warn( "Localization '%s' message '%s' (%s): %s", self.name, id, bundle.locales[ 1 ], format_errors[ 1 ] )
                    end

                    for error_index = error_count, 1, -1 do
                        format_errors[ error_index ] = nil
                    end
                end

                return text
            end
        end
    end

    return id
end

--- [SHARED AND MENU]
---
--- Checks if the message exists in the lookup order of the language.
---
---@param id string The message identifier, `message.attribute` checks the attribute.
---@param tag string? The language tag, the current language by default.
---@return boolean exists `true` if the message exists.
---@nodiscard
function Localization:has( id, tag )
    local chain = self:loadChain( tag or language )

    local message_id, attribute = split_id( id )

    for index = 1, #chain, 1 do
        local message = chain[ index ].messages[ message_id ]
        if message ~= nil then
            if attribute == nil then
                if message.value ~= nil then
                    return true
                end
            elseif message.attributes[ attribute ] ~= nil then
                return true
            end
        end
    end

    return false
end

--- [SHARED AND MENU]
---
--- Adds the FTL source to the language, its messages replace the ones of translation files.
---
--- Useful for translations shipped inside Lua files, e.g. for servers without workshop content.
---
---@param tag string The language tag.
---@param text string The FTL source.
function Localization:addSource( tag, text )
    local normalized = normalize( tag )
    if normalized == nil then
        error( string_format( "invalid language tag '%s'", tag ), 2 )
    end

    local sources = self.sources[ normalized ]
    if sources == nil then
        self.sources[ normalized ] = { text }
    else
        sources[ #sources + 1 ] = text
    end

    self:reload()
end

--- [SHARED AND MENU]
---
--- Drops the loaded translations, files are read again on the next lookup.
---
function Localization:reload()
    self.bundles = {}
    self.chains = {}
    self.reported = {}
end

--- [SHARED AND MENU]
---
--- The class used to create or get `Localization` objects.
---
---@class dreamwork.std.i18n.LocalizationClass : dreamwork.std.i18n.Localization, dreamwork.std.Class
---@field __base dreamwork.std.i18n.Localization
---@overload fun( name: string ): dreamwork.std.i18n.Localization
local LocalizationClass = class.create( Localization )
i18n.Localization = LocalizationClass

---@param name string
---@return dreamwork.std.i18n.Localization | nil
---@protected
function LocalizationClass:__new( name )
    local owner = sandbox_owner( 2 )
    if owner ~= nil then
        name = sandbox_prefix( owner, name )
    end

    return registry[ name ]
end

--- [SHARED AND MENU]
---
--- Returns the existing localization.
---
---@param name string The name of the localization, the package prefix is added for package code.
---@return dreamwork.std.i18n.Localization | nil l10n The localization, `nil` if it was not created.
---@nodiscard
function i18n.getLocalization( name )
    local owner = sandbox_owner( 2 )
    if owner ~= nil then
        name = sandbox_prefix( owner, name )
    end

    return registry[ name ]
end

if not (LUA_SERVER or LUA_CLIENT) then
    return
end

-- Networking: the server sends message identifiers and variables, clients format them in their languages

--- client -> server `language: string`
local OP_LANGUAGE = 0

--- server -> client `name: string`, `id: string`, `args`
local OP_MESSAGE = 1

local ARG_STRING = 0
local ARG_NUMBER = 1
local ARG_FLUENT_NUMBER = 2
local ARG_FLUENT_DATETIME = 3

local network = std.Network( "dreamwork.i18n", true )

local Client = std.Client

if LUA_SERVER then

    -- only language tags are received
    network.limit = 64

    local BinaryWriter = std.BinaryWriter

    local Client_getAll = Client.getAll

    --- The messages to the clients that are not initialized yet.
    ---
    ---@type table<dreamwork.std.Client, string[]>
    local pending = {}
    setmetatable( pending, { __mode = "k" } )

    --- [SERVER]
    ---
    --- Called when a client reports its language, once initialized and on every change.
    ---
    --- Arguments: `client: dreamwork.std.Client`, `language: string`, `previous: string | nil`.
    ---
    local PlayerLanguageChanged = Event( "i18n.PlayerLanguageChanged" )
    i18n.PlayerLanguageChanged = PlayerLanguageChanged

    ---@param _ dreamwork.std.Network
    ---@param reader dreamwork.std.BinaryReader
    ---@param sender dreamwork.std.Client | nil
    network:attach( function( _, reader, sender )
        if sender == nil or reader:readUInt( 8 ) ~= OP_LANGUAGE then return end

        local tag = normalize( reader:readString() )
        if tag == nil then return end

        local previous = client_languages[ sender ]
        if previous == tag then return end

        client_languages[ sender ] = tag
        PlayerLanguageChanged( sender, tag, previous )
    end )

    ---@param client dreamwork.std.Client
    engine_hook.catch( "dreamwork.client.initialized", "std.i18n.pending", function( client )
        local messages = pending[ client ]
        if messages == nil then return end

        pending[ client ] = nil

        for index = 1, #messages, 1 do
            network:send( messages[ index ], client )
        end
    end )

    --- Writes the variables, only strings, numbers, `fluent.Number` and `fluent.DateTime` can be sent.
    ---
    ---@param writer dreamwork.std.BinaryWriter
    ---@param args table<string, dreamwork.std.fluent.Argument> | nil
    local function write_args( writer, args )
        if args == nil then
            writer:writeUInt( 0, 8 )
            return
        end

        local count = 0
        for _ in raw_pairs( args ) do
            count = count + 1
        end

        if count > 255 then
            error( "too many variables, 255 can be sent at most", 3 )
        end

        writer:writeUInt( count, 8 )

        for name, value in raw_pairs( args ) do
            writer:writeString( name )

            if raw_type( value ) == "string" then
                ---@cast value string
                writer:writeUInt( ARG_STRING, 8 )
                writer:writeCountedString( value, 16 )
            elseif raw_type( value ) == "number" then
                ---@cast value number
                writer:writeUInt( ARG_NUMBER, 8 )
                writer:writeDouble( value, true )
            else
                ---@cast value dreamwork.std.FluentType
                local metatable = debug_getmetatable( value )
                if metatable == FluentNumber.__base then
                    writer:writeUInt( ARG_FLUENT_NUMBER, 8 )
                elseif metatable == FluentDateTime.__base then
                    writer:writeUInt( ARG_FLUENT_DATETIME, 8 )
                else
                    error( string_format( "variable '%s' can not be sent, only strings, numbers, `fluent.Number` and `fluent.DateTime` are supported", name ), 3 )
                end

                writer:writeProto( value )
            end
        end
    end

    ---@param client dreamwork.std.Client
    ---@param data string
    local function queue_message( client, data )
        local messages = pending[ client ]
        if messages == nil then
            pending[ client ] = { data }
        else
            messages[ #messages + 1 ] = data
        end
    end

    --- [SERVER]
    ---
    --- Sends the message to clients, they format it in their languages and call `Localization.Received`.
    ---
    --- Messages to clients that are not initialized yet are queued until they are.
    ---
    --- ```lua
    --- -- client
    --- l10n.Received:attach( function( _, id, text )
    ---     chat.AddText( text )
    --- end )
    ---
    --- -- server
    --- l10n:send( client, "round-won", { team = "Red", score = 3 } )
    --- ```
    ---
    ---@param target ( dreamwork.std.Client | dreamwork.std.Client[] )? The receivers, every human client if `nil`.
    ---@param id string The message identifier.
    ---@param args table<string, dreamwork.std.fluent.Argument>? The variables, strings, numbers, `fluent.Number` and `fluent.DateTime` only.
    function Localization:send( target, id, args )
        local writer = BinaryWriter()
        writer:writeUInt( OP_MESSAGE, 8 )
        writer:writeString( self.name )
        writer:writeString( id )
        write_args( writer, args )

        local data = writer:compile()

        if target == nil then
            target = Client_getAll( true )
        elseif isObject( target ) then
            ---@cast target dreamwork.std.Client
            target = { target }
        end

        ---@cast target dreamwork.std.Client[]

        ---@type dreamwork.std.Client[]
        local receivers, receiver_count = {}, 0

        for i = 1, #target, 1 do
            local client = target[ i ]
            if client.is_bot or not client.is_connected then
                -- bots have no client state, disconnected clients never initialize
            elseif client.is_initialized then
                receiver_count = receiver_count + 1
                receivers[ receiver_count ] = client
            else
                queue_message( client, data )
            end
        end

        if receiver_count ~= 0 then
            network:send( data, receivers )
        end
    end

else

    ---@param reader dreamwork.std.BinaryReader
    ---@return table<string, dreamwork.std.fluent.Argument> | nil
    local function read_args( reader )
        local count = reader:readUInt( 8 )
        if count == 0 then
            return nil
        end

        local args = {}

        for _ = 1, count, 1 do
            local name = reader:readString()
            local value_type = reader:readUInt( 8 )

            if value_type == ARG_STRING then
                args[ name ] = reader:readCountedString( 16 )
            elseif value_type == ARG_NUMBER then
                args[ name ] = reader:readDouble( true )
            elseif value_type == ARG_FLUENT_NUMBER then
                args[ name ] = reader:readProto( FluentNumber )
            elseif value_type == ARG_FLUENT_DATETIME then
                args[ name ] = reader:readProto( FluentDateTime )
            end
        end

        return args
    end

    ---@param _ dreamwork.std.Network
    ---@param reader dreamwork.std.BinaryReader
    network:attach( function( _, reader )
        if reader:readUInt( 8 ) ~= OP_MESSAGE then return end

        local l10n = LocalizationClass( reader:readString() )
        local id = reader:readString()
        local args = read_args( reader )

        l10n.Received( l10n, id, l10n:get( id, args ), args )
    end )

    local function report_language()
        network:transmit( function( _, writer )
            writer:writeUInt( OP_LANGUAGE, 8 )
            writer:writeString( language )
        end )
    end

    ---@param client dreamwork.std.Client
    engine_hook.catch( "dreamwork.client.initialized", "std.i18n.language", function( client )
        if client:isLocal() then
            report_language()
        end
    end )

    local Client_getLocal = Client.getLocal

    LanguageChanged:attach( function()
        local client = Client_getLocal()
        if client ~= nil and client.is_initialized then
            report_language()
        end
    end )

    -- reloaded after the initialization
    local client = Client_getLocal()
    if client ~= nil and client.is_initialized then
        report_language()
    end

end
