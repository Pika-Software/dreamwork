---@meta _

--- [SHARED AND MENU]
---
--- The localization library, the runtime layer over `fluent`.
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
---@class i18n
---@field language string The current language tag, e.g. `"pt-BR"`. **READ-ONLY**
---@field fallback string The language used when a message is missing in the current one, `"en"` by default. **READ-ONLY**
i18n = {}

---@type string
i18n.fallback = nil

---@type string
i18n.language = nil

--- [SHARED AND MENU]
---
--- Called when the current language changes.
---
--- Arguments: `language: string`, `previous: string`.
---
---@type Event
i18n.LanguageChanged = nil

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
function i18n.getChain(tag) end

--- [SHARED AND MENU]
---
--- Returns the current language.
---
--- On the server, the language of the client can be requested, clients report their language once initialized.
---
---@param client Client? The client, the server only.
---@return string language The language tag, e.g. `"pt-BR"`.
---@nodiscard
function i18n.getLanguage(client) end

--- [SHARED AND MENU]
---
--- Overrides the current language, `nil` follows the game language ( `gmod_language` ) again.
---
--- The server has no game language, its language is the fallback one by default.
---
---@param tag string? The language tag.
function i18n.setLanguage(tag) end

--- [SHARED AND MENU]
---
--- Sets the language used when a message is missing in the current one.
---
---@param tag string The language tag, `"en"` by default.
function i18n.setFallback(tag) end

--- [SHARED AND MENU]
---
--- The translations of one addon, created once per name, `Localization( name )` returns the existing one.
---
--- Translation files are read lazily with `vfs`, on the first lookup of a language,
--- asynchronously if that lookup happens inside a coroutine.
---
---@class i18n.Localization : Object
---@field __class i18n.LocalizationClass
---@field name string The name of the localization, `{id}::{name}` for packages. **READ-ONLY**
---@field Received Event The client event of messages sent by `Localization:send`, arguments: `l10n: Localization`, `id: string`, `text: string`, `args: table | nil`.
---@field protected sources table<string, string[]> The sources added by `Localization:addSource` by language tags.
---@field protected bundles table<string, FluentBundle | false> The loaded bundles by language tags, `false` if the language has no translations.
---@field protected chains table<string, FluentBundle[]> The bundles in the lookup order by requested language tags.
---@field protected reported table<string, boolean> The message identifiers with reported formatting errors.
---@field protected directory string The directory of translation files, with the trailing `/`.
---@field protected file_name string The name of translation files, with the extension.
local Localization = {}

---@param name string
---@protected
function Localization:__init(name) end

---@return string
---@nodiscard
---@protected
function Localization:__represent() end

--- Returns the bundle of the language, `false` if there are no translations.
---
---@param tag string
---@return FluentBundle | false
---@protected
function Localization:loadBundle(tag) end

--- Returns the bundles in the lookup order of the language.
---
---@param tag string
---@return FluentBundle[]
---@protected
function Localization:loadChain(tag) end

--- [SHARED AND MENU]
---
--- Formats the message in the current language, or in the given one.
---
--- Formatting errors ( e.g. missing variables ) are logged once per message,
--- the message identifier is returned if no language of the lookup order has the message.
---
---@param id string The message identifier, `message.attribute` formats the attribute.
---@param args table<string, fluent.Argument>? The variables.
---@param tag string? The language tag, the current language by default.
---@return string text The formatted message, or `id` if it is missing.
---@nodiscard
function Localization:get(id, args, tag) end

--- [SHARED AND MENU]
---
--- Checks if the message exists in the lookup order of the language.
---
---@param id string The message identifier, `message.attribute` checks the attribute.
---@param tag string? The language tag, the current language by default.
---@return boolean exists `true` if the message exists.
---@nodiscard
function Localization:has(id, tag) end

--- [SHARED AND MENU]
---
--- Adds the FTL source to the language, its messages replace the ones of translation files.
---
--- Useful for translations shipped inside Lua files, e.g. for servers without workshop content.
---
---@param tag string The language tag.
---@param text string The FTL source.
function Localization:addSource(tag, text) end

--- [SHARED AND MENU]
---
--- Drops the loaded translations, files are read again on the next lookup.
---
function Localization:reload() end

--- [SHARED AND MENU]
---
--- The class used to create or get `Localization` objects.
---
---@class i18n.LocalizationClass : i18n.Localization, Class
---@field __base i18n.Localization
---@overload fun( name: string ): i18n.Localization
local LocalizationClass = {}

i18n.Localization = LocalizationClass

---@param name string
---@return i18n.Localization | nil
---@protected
function LocalizationClass:__new(name) end

--- [SHARED AND MENU]
---
--- Returns the existing localization.
---
---@param name string The name of the localization, the package prefix is added for package code.
---@return i18n.Localization | nil l10n The localization, `nil` if it was not created.
---@nodiscard
function i18n.getLocalization(name) end

--- [SERVER]
---
--- Called when a client reports its language, once initialized and on every change.
---
--- Arguments: `client: Client`, `language: string`, `previous: string | nil`.
---
---@type Event
i18n.PlayerLanguageChanged = nil

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
---@param target ( Client | Client[] )? The receivers, every human client if `nil`.
---@param id string The message identifier.
---@param args table<string, fluent.Argument>? The variables, strings, numbers, `fluent.Number` and `fluent.DateTime` only.
function Localization:send(target, id, args) end
