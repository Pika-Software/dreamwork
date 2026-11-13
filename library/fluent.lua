---@meta _

--- [SHARED AND MENU]
---
--- A port of [Project Fluent](https://projectfluent.org/), the localization system, based on `@fluent/bundle`.
---
--- ```lua
--- local resource = fluent.Resource( [[
--- -brand = Dreamwork
--- welcome = Welcome to { -brand }, { $name }!
--- files = { $count ->
---     [one] { $count } file
---    *[other] { $count } files
--- }
--- ]] )
---
--- local bundle = fluent.Bundle( "en-US" )
--- bundle:addResource( resource )
---
--- print( bundle:format( "welcome", { name = "Player" } ) ) -- Welcome to Dreamwork, Player!
--- print( bundle:format( "files", { count = 1500 } ) ) -- 1,500 files
--- ```
---
---@class fluent
fluent = {}

--- [SHARED AND MENU]
---
--- An error raised while formatting Fluent messages, e.g. a missing variable or message.
---
---@class FluentError : Error
---@field __class FluentErrorClass
---@field __parent Error
local __FluentError = {}

--- [SHARED AND MENU]
---
--- The class used to create new `FluentError` instances.
---
---@class FluentErrorClass : FluentError, ErrorClass
---@field __base FluentError
---@field __parent ErrorClass
---@overload fun( message: string ): FluentError
FluentError = {}

--- [SHARED AND MENU]
---
--- The registered locales by their normalized tags.
---
---@type table<string, fluent.Locale>
fluent.locales = nil

--- [SHARED AND MENU]
---
--- Normalizes the BCP 47 locale tag, `en_us` -> `en-US`, `zh-hant-tw` -> `zh-Hant-TW`.
---
---@param tag string The locale tag.
---@return string normalized_tag The normalized tag.
---@nodiscard
function fluent.normalizeTag(tag) end

--- [SHARED AND MENU]
---
--- Returns the formatting data of the locale.
---
--- Subtags are removed one by one until a registered locale is found, `pt-BR` -> `pt`,
--- the data of unknown languages uses ISO dates and the `other` plural category only.
---
---@param tag string The BCP 47 locale tag, e.g. `"pt-BR"`, `"zh-Hant-TW"`.
---@return fluent.Locale locale The locale data.
---@nodiscard
function fluent.getLocale(tag) end

--- [SHARED AND MENU]
---
--- Registers the formatting data of the locale, missing fields are taken from the parent locale.
---
--- ```lua
--- fluent.setLocale( "uk", {
---     months = { "січня", "лютого", ... },
---     date = { short = "{dd}.{MM}.{y}", long = "{d} {MMMM} {y} р." }
--- }, "ru" )
--- ```
---
---@param tag string The BCP 47 locale tag.
---@param data table The locale data, see `fluent.Locale`, becomes the locale object.
---@param parent string? The tag of the parent locale, the root locale if `nil`.
---@return fluent.Locale locale The registered locale.
function fluent.setLocale(tag, data, parent) end

--- [SHARED AND MENU]
---
--- Formats the number like `Intl.NumberFormat`.
---
--- ```lua
--- print( fluent.formatNumber( 1234.5, { minimumFractionDigits = 2 }, "en" ) ) -- 1,234.50
--- print( fluent.formatNumber( 0.25, { style = "percent" }, "ru" ) ) -- 25 %
--- print( fluent.formatNumber( 9.99, { style = "currency", currency = "EUR" }, "de" ) ) -- 9,99 €
--- ```
---
---@param value number The number to format.
---@param options fluent.NumberOptions? The formatting options.
---@param locale ( fluent.Locale | string )? The locale or its tag, the root locale by default.
---@return string str The formatted number.
---@nodiscard
function fluent.formatNumber(value, options, locale) end

--- [SHARED AND MENU]
---
--- Returns the plural category of the number like `Intl.PluralRules`.
---
--- The fraction and significant digits options affect the category, `1.0` is `other` in English.
---
---@param value number The number.
---@param options fluent.NumberOptions? The digits options and the rule `type`.
---@param locale ( fluent.Locale | string )? The locale or its tag, the root locale by default.
---@return fluent.Category category The plural category.
---@nodiscard
function fluent.pluralCategory(value, options, locale) end

--- [SHARED AND MENU]
---
--- Formats the Unix timestamp like `Intl.DateTimeFormat`, see `fluent.DateTimeOptions`.
---
--- ```lua
--- print( fluent.formatDateTime( 905989690, { dateStyle = "long", timeZone = "UTC" }, "en" ) ) -- September 16, 1998
--- print( fluent.formatDateTime( 905989690, { dateStyle = "short", timeStyle = "short", timeZone = "UTC" }, "ru" ) ) -- 16.09.1998, 23:48
--- ```
---
---@param timestamp number The Unix timestamp in seconds.
---@param options fluent.DateTimeOptions? The formatting options.
---@param locale ( fluent.Locale | string )? The locale or its tag, the root locale by default.
---@return string str The formatted date and time.
---@nodiscard
function fluent.formatDateTime(timestamp, options, locale) end

--- [SHARED AND MENU]
---
--- The base of values with custom formatting, inherit it to pass custom objects as variables.
---
---@class FluentType : Object
---@field __class FluentTypeClass
---@field value any The wrapped value.
local FluentType = {}

---@param value any
---@protected
function FluentType:__init(value) end

--- [SHARED AND MENU]
---
--- Formats the value, called when the value is placed into a pattern.
---
--- The base implementation formats numbers with the bundle locale and converts other values with `tostring`.
---
---@param scope fluent.Scope? The formatting state, the bundle is `scope.bundle`.
---@return string str The formatted value.
---@nodiscard
function FluentType:toString(scope) end

--- [SHARED AND MENU]
---
--- The class used to create new `FluentType` objects.
---
---@class FluentTypeClass : FluentType, Class
---@field __base FluentType
---@overload fun( value: any ): FluentType
local FluentTypeClass = {}

fluent.Type = FluentTypeClass

--- [SHARED AND MENU]
---
--- Checks if the value is a Fluent type ( `fluent.None`, `fluent.Number`, `fluent.DateTime` or a custom one ).
---
---@param value any The value to check.
---@return boolean is_type `true` if the value inherits `fluent.Type`.
---@nodiscard
function fluent.isType(value) end

--- [SHARED AND MENU]
---
--- The missing value, formatted as `{name}` to show what failed to resolve.
---
---@class FluentNone : FluentType
---@field __class FluentNoneClass
---@field value string The name of the missing value, `"???"` by default.
local FluentNone = {}

---@param value string?
---@protected
function FluentNone:__init(value) end

---@return string
---@nodiscard
function FluentNone:toString() end

--- [SHARED AND MENU]
---
--- The class used to create new `FluentNone` objects.
---
---@class FluentNoneClass : FluentNone, FluentTypeClass
---@field __base FluentNone
---@overload fun( value: string? ): FluentNone
local FluentNoneClass = {}

fluent.None = FluentNoneClass

--- [SHARED AND MENU]
---
--- The number with formatting options, numbers passed as variables are wrapped in it automatically.
---
---@class FluentNumber : FluentType
---@field __class FluentNumberClass
---@field value number The number.
---@field options fluent.NumberOptions | nil The formatting options, must not be changed since they can be shared.
local FluentNumber = {}

---@param value number
---@param options fluent.NumberOptions?
---@protected
function FluentNumber:__init(value, options) end

---@param scope fluent.Scope?
---@return string
---@nodiscard
function FluentNumber:toString(scope) end

---@param writer BinaryWriter
---@protected
function FluentNumber:__serialize(writer) end

---@param reader BinaryReader
---@protected
function FluentNumber:__deserialize(reader) end

--- [SHARED AND MENU]
---
--- The class used to create new `FluentNumber` objects.
---
--- ```lua
--- bundle:format( "price", { amount = fluent.Number( 9.99, { style = "currency", currency = "USD" } ) } )
--- ```
---
---@class FluentNumberClass : FluentNumber, FluentTypeClass
---@field __base FluentNumber
---@overload fun( value: number, options: fluent.NumberOptions? ): FluentNumber
local FluentNumberClass = {}

fluent.Number = FluentNumberClass

--- [SHARED AND MENU]
---
--- The date and time, Unix timestamps must be wrapped in it to be formatted as dates.
---
---@class FluentDateTime : FluentType
---@field __class FluentDateTimeClass
---@field value number The Unix timestamp in seconds.
---@field options fluent.DateTimeOptions | nil The formatting options, must not be changed since they can be shared.
local FluentDateTime = {}

---@param value number
---@param options fluent.DateTimeOptions?
---@protected
function FluentDateTime:__init(value, options) end

---@param scope fluent.Scope?
---@return string
---@nodiscard
function FluentDateTime:toString(scope) end

---@param writer BinaryWriter
---@protected
function FluentDateTime:__serialize(writer) end

---@param reader BinaryReader
---@protected
function FluentDateTime:__deserialize(reader) end

--- [SHARED AND MENU]
---
--- The class used to create new `FluentDateTime` objects.
---
--- ```lua
--- bundle:format( "last-seen", { date = fluent.DateTime( time.now(), { dateStyle = "long" } ) } )
--- ```
---
---@class FluentDateTimeClass : FluentDateTime, FluentTypeClass
---@field __base FluentDateTime
---@overload fun( value: number, options: fluent.DateTimeOptions? ): FluentDateTime
local FluentDateTimeClass = {}

fluent.DateTime = FluentDateTimeClass

--- [SHARED AND MENU]
---
--- The built-in functions available to every bundle, `NUMBER` and `DATETIME`.
---
---@type table<string, fluent.Function>
fluent.builtins = nil

---@class fluent.Indent
---@field type "indent"
---@field value string The blank text, newlines are normalized.
---@field length integer The number of spaces in the last line.

--- [SHARED AND MENU]
---
--- The parsed FTL ( Fluent Translation List ) source.
---
--- The parser is the runtime one from `@fluent/bundle`: comments are ignored
--- and invalid entries are skipped, their errors are collected in `errors`.
---
---@class FluentResource : Object
---@field __class FluentResourceClass
---@field body fluent.Message[] The messages and terms in the source order.
---@field errors string[] The syntax errors of skipped entries, e.g. `line 4: Expected default variant in 'emails'`.
local FluentResource = {}

---@param text string?
---@protected
function FluentResource:__init(text) end

---@return string
---@nodiscard
---@protected
function FluentResource:__represent() end

--- [SHARED AND MENU]
---
--- Parses more FTL source into the resource.
---
---@param text string The FTL source.
---@return FluentResource resource The resource itself.
function FluentResource:parse(text) end

--- [SHARED AND MENU]
---
--- The class used to create new `FluentResource` objects.
---
---@class FluentResourceClass : FluentResource, Class
---@field __base FluentResource
---@overload fun( text: string? ): FluentResource
local FluentResourceClass = {}

fluent.Resource = FluentResourceClass

--- [SHARED AND MENU]
---
--- The collection of messages of one locale, formats them with variables.
---
--- ```lua
--- local bundle = fluent.Bundle( "ru" )
--- bundle:addResource( file_content )
---
--- local errors = {}
--- print( bundle:format( "items", { count = 3 }, errors ) ) -- 3 предмета
--- ```
---
---@class FluentBundle : Object
---@field __class FluentBundleClass
---@field locales string[] The locale tags, the first one is used for formatting.
---@field locale fluent.Locale The formatting data of the first locale.
---@field messages table<string, fluent.Message> The messages by their identifiers.
---@field terms table<string, fluent.Message> The terms by their identifiers, with `-`.
---@field functions table<string, fluent.Function> The functions available to messages.
---@field use_isolating boolean If `true`, placeables are wrapped in Unicode bidi isolation marks.
---@field transform ( fun( text: string ): string ) | nil The function applied to every text element.
local FluentBundle = {}

---@param locales string | string[]
---@param options fluent.BundleOptions?
---@protected
function FluentBundle:__init(locales, options) end

---@return string
---@nodiscard
---@protected
function FluentBundle:__represent() end

--- [SHARED AND MENU]
---
--- Adds the messages and terms of the resource to the bundle.
---
---@param resource FluentResource | string The resource or the FTL source to parse.
---@param allow_overrides boolean? If `true`, existing messages and terms are replaced, otherwise they are kept and reported.
---@return string[] errors The override errors, syntax errors of a parsed source are in `FluentResource.errors`.
function FluentBundle:addResource(resource, allow_overrides) end

--- [SHARED AND MENU]
---
--- Checks if the bundle has the message, terms are not messages.
---
---@param id string The message identifier.
---@return boolean has_message `true` if the message exists.
---@nodiscard
function FluentBundle:hasMessage(id) end

--- [SHARED AND MENU]
---
--- Returns the message, its `value` and `attributes` patterns are formatted with `FluentBundle:formatPattern`.
---
---@param id string The message identifier.
---@return fluent.Message | nil message The message, `nil` if it does not exist.
---@nodiscard
function FluentBundle:getMessage(id) end

--- [SHARED AND MENU]
---
--- Formats the pattern of a message or its attribute.
---
--- If `errors` is given, errors are collected into it and the best possible string is returned,
--- e.g. `{$name}` for a missing variable, otherwise the first error is thrown.
---
--- ```lua
--- local message = bundle:getMessage( "hello" )
--- if message ~= nil and message.value ~= nil then
---     local errors = {}
---     print( bundle:formatPattern( message.value, { name = "World" }, errors ) )
--- end
--- ```
---
---@param pattern fluent.Pattern The pattern to format.
---@param args table<string, fluent.Argument>? The variables.
---@param errors Error[]? The list collecting the errors.
---@return string str The formatted string.
---@nodiscard
function FluentBundle:formatPattern(pattern, args, errors) end

--- [SHARED AND MENU]
---
--- Formats the message value, or its attribute if the identifier is `message.attribute`.
---
---@param id string The message identifier, e.g. `"login-input"` or `"login-input.placeholder"`.
---@param args table<string, fluent.Argument>? The variables.
---@param errors Error[]? The list collecting the errors, see `FluentBundle:formatPattern`.
---@return string | nil str The formatted string, `nil` if the message or its attribute does not exist.
---@nodiscard
function FluentBundle:format(id, args, errors) end

--- [SHARED AND MENU]
---
--- Adds or replaces the function available to messages.
---
--- ```lua
--- bundle:setFunction( "UPPER", function( positional )
---     return string.upper( tostring( positional[ 1 ] ) )
--- end )
--- ```
---
---@param name string The function name, must be upper-case to be callable from FTL.
---@param fn fluent.Function | nil The function, `nil` removes it.
function FluentBundle:setFunction(name, fn) end

--- [SHARED AND MENU]
---
--- The class used to create new `FluentBundle` objects.
---
---@class FluentBundleClass : FluentBundle, Class
---@field __base FluentBundle
---@overload fun( locales: ( string | string[] ), options: fluent.BundleOptions? ): FluentBundle
local FluentBundleClass = {}

fluent.Bundle = FluentBundleClass
