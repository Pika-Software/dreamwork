---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_error = raw.error
local raw_pairs = raw.pairs
local raw_tonumber = raw.tonumber

local class = std.class
local class_isInherited = class.isInherited

local debug = std.debug
local debug_getmetatable = debug.getmetatable

local math = std.math
local math_huge = math.huge
local math_min, math_max = math.min, math.max
local math_abs, math_floor = math.abs, math.floor

local string = std.string
local string_sub, string_rep = string.sub, string.rep
local string_byte, string_char = string.byte, string.char
local string_lower, string_upper = string.lower, string.upper
local string_format, string_gmatch = string.format, string.gmatch
local string_find, string_match, string_gsub = string.find, string.match, string.gsub

local table = std.table
local table_concat = table.concat

local utf8 = std.utf8
local utf8_encode = utf8.encode

local time = std.time
local time_offset = time.offset
local time_civilFromTimestamp = time.civilFromTimestamp

local type = std.type
local pcall = std.pcall
local error = std.error
local isError = std.isError
local tostring = std.tostring
local setmetatable = std.setmetatable
local isString, isNumber, isBoolean = std.isString, std.isNumber, std.isBoolean


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
---@class dreamwork.std.fluent
local fluent = {}
std.fluent = fluent

---@type table
local EMPTY = {}

--- The maximum number of placeables resolved by one `FluentBundle:formatPattern` call, protects from the billion laughs attack.
---
---@type integer
local MAX_PLACEABLES = 100

--- U+2068 FIRST STRONG ISOLATE
---
---@type string
local FSI = "\xE2\x81\xA8"

--- U+2069 POP DIRECTIONAL ISOLATE
---
---@type string
local PDI = "\xE2\x81\xA9"

--- [SHARED AND MENU]
---
--- An error raised while formatting Fluent messages, e.g. a missing variable or message.
---
---@class dreamwork.std.FluentError : dreamwork.std.Error
---@field __class dreamwork.std.FluentErrorClass
---@field __parent dreamwork.std.Error
local FluentError = class.base( "FluentError", false, std.Error )

--- [SHARED AND MENU]
---
--- The class used to create new `FluentError` instances.
---
---@class dreamwork.std.FluentErrorClass : dreamwork.std.FluentError, dreamwork.std.ErrorClass
---@field __base dreamwork.std.FluentError
---@field __parent dreamwork.std.ErrorClass
---@overload fun( message: string ): dreamwork.std.FluentError
local FluentErrorClass = class.create( FluentError )
std.FluentError = FluentErrorClass

-- Plural rules ( https://unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html )

--- Checks if the integer `x` is in the range `[ a, b ]`, CLDR ranges never match fractions.
---
---@param x number
---@param a integer
---@param b integer
---@return boolean
local function within( x, a, b )
    return x >= a and x <= b and x % 1 == 0
end

---@type dreamwork.std.fluent.PluralRule
local function plural_other()
    return "other"
end

--- `one: i = 1 and v = 0` ( en, de, nl, sv, fi, et, ... )
---
---@type dreamwork.std.fluent.PluralRule
local function plural_one_i1v0( _, i, v )
    if i == 1 and v == 0 then
        return "one"
    end

    return "other"
end

--- `one: n = 1` ( bg, el, hu, tr, nb, ... )
---
---@type dreamwork.std.fluent.PluralRule
local function plural_one_n1( n )
    if n == 1 then
        return "one"
    end

    return "other"
end

--- `one: i = 0,1` ( hy, ff, kab )
---
---@type dreamwork.std.fluent.PluralRule
local function plural_one_i01( _, i )
    if i == 0 or i == 1 then
        return "one"
    end

    return "other"
end

--- `one: i = 0 or n = 1` ( hi, bn, fa, gu, kn, zu, am )
---
---@type dreamwork.std.fluent.PluralRule
local function plural_hi( n, i )
    if i == 0 or n == 1 then
        return "one"
    end

    return "other"
end

--- `many: e = 0 and i != 0 and i % 1000000 = 0 and v = 0`, the compact exponent is always `0`.
---
---@param i number
---@param v integer
---@return boolean
local function is_millions( i, v )
    return v == 0 and i ~= 0 and i % 1000000 == 0
end

---@type dreamwork.std.fluent.PluralRule
local function plural_fr( _, i, v )
    if i == 0 or i == 1 then
        return "one"
    elseif is_millions( i, v ) then
        return "many"
    end

    return "other"
end

---@type dreamwork.std.fluent.PluralRule
local function plural_es( n, i, v )
    if n == 1 then
        return "one"
    elseif is_millions( i, v ) then
        return "many"
    end

    return "other"
end

--- it, ca, pt-PT
---
---@type dreamwork.std.fluent.PluralRule
local function plural_it( _, i, v )
    if i == 1 and v == 0 then
        return "one"
    elseif is_millions( i, v ) then
        return "many"
    end

    return "other"
end

---@type dreamwork.std.fluent.PluralRule
local function plural_pt( _, i, v )
    if i == 0 or i == 1 then
        return "one"
    elseif is_millions( i, v ) then
        return "many"
    end

    return "other"
end

--- ru, uk
---
---@type dreamwork.std.fluent.PluralRule
local function plural_ru( _, i, v )
    if v ~= 0 then
        return "other"
    end

    local i10, i100 = i % 10, i % 100
    if i10 == 1 and i100 ~= 11 then
        return "one"
    elseif i10 >= 2 and i10 <= 4 and (i100 < 12 or i100 > 14) then
        return "few"
    end

    return "many"
end

---@type dreamwork.std.fluent.PluralRule
local function plural_be( n )
    if n % 1 ~= 0 then
        return "other"
    end

    local n10, n100 = n % 10, n % 100
    if n10 == 1 and n100 ~= 11 then
        return "one"
    elseif n10 >= 2 and n10 <= 4 and (n100 < 12 or n100 > 14) then
        return "few"
    end

    return "many"
end

---@type dreamwork.std.fluent.PluralRule
local function plural_pl( _, i, v )
    if v ~= 0 then
        return "other"
    elseif i == 1 then
        return "one"
    end

    local i10, i100 = i % 10, i % 100
    if i10 >= 2 and i10 <= 4 and (i100 < 12 or i100 > 14) then
        return "few"
    end

    return "many"
end

--- cs, sk
---
---@type dreamwork.std.fluent.PluralRule
local function plural_cs( _, i, v )
    if v ~= 0 then
        return "many"
    elseif i == 1 then
        return "one"
    elseif i >= 2 and i <= 4 then
        return "few"
    end

    return "other"
end

---@type dreamwork.std.fluent.PluralRule
local function plural_lt( n, _, _, f )
    local n10, n100 = n % 10, n % 100
    if n10 == 1 and not within( n100, 11, 19 ) then
        return "one"
    elseif within( n10, 2, 9 ) and not within( n100, 11, 19 ) then
        return "few"
    elseif f ~= 0 then
        return "many"
    end

    return "other"
end

---@type dreamwork.std.fluent.PluralRule
local function plural_lv( n, _, v, f )
    local n10, n100 = n % 10, n % 100
    local f10, f100 = f % 10, f % 100

    if n10 == 0 or within( n100, 11, 19 ) or (v == 2 and within( f100, 11, 19 )) then
        return "zero"
    elseif (n10 == 1 and n100 ~= 11) or (v == 2 and f10 == 1 and f100 ~= 11) or (v ~= 2 and f10 == 1) then
        return "one"
    end

    return "other"
end

---@type dreamwork.std.fluent.PluralRule
local function plural_ro( n, i, v )
    if i == 1 and v == 0 then
        return "one"
    elseif v ~= 0 or n == 0 or (n ~= 1 and within( n % 100, 1, 19 )) then
        return "few"
    end

    return "other"
end

---@type dreamwork.std.fluent.PluralRule
local function plural_sl( _, i, v )
    if v ~= 0 then
        return "few"
    end

    local i100 = i % 100
    if i100 == 1 then
        return "one"
    elseif i100 == 2 then
        return "two"
    elseif i100 == 3 or i100 == 4 then
        return "few"
    end

    return "other"
end

--- hr, sr, bs
---
---@type dreamwork.std.fluent.PluralRule
local function plural_hr( _, i, v, f )
    local i10, i100 = i % 10, i % 100
    local f10, f100 = f % 10, f % 100

    if (v == 0 and i10 == 1 and i100 ~= 11) or (f10 == 1 and f100 ~= 11) then
        return "one"
    elseif (v == 0 and i10 >= 2 and i10 <= 4 and (i100 < 12 or i100 > 14)) or (f10 >= 2 and f10 <= 4 and (f100 < 12 or f100 > 14)) then
        return "few"
    end

    return "other"
end

---@type dreamwork.std.fluent.PluralRule
local function plural_mk( _, i, v, f )
    if (v == 0 and i % 10 == 1 and i % 100 ~= 11) or (f % 10 == 1 and f % 100 ~= 11) then
        return "one"
    end

    return "other"
end

---@type dreamwork.std.fluent.PluralRule
local function plural_ar( n )
    if n == 0 then
        return "zero"
    elseif n == 1 then
        return "one"
    elseif n == 2 then
        return "two"
    end

    local n100 = n % 100
    if within( n100, 3, 10 ) then
        return "few"
    elseif within( n100, 11, 99 ) then
        return "many"
    end

    return "other"
end

---@type dreamwork.std.fluent.PluralRule
local function plural_he( _, i, v )
    if (i == 1 and v == 0) or (i == 0 and v ~= 0) then
        return "one"
    elseif i == 2 and v == 0 then
        return "two"
    end

    return "other"
end

---@type dreamwork.std.fluent.PluralRule
local function plural_ga( n )
    if n == 1 then
        return "one"
    elseif n == 2 then
        return "two"
    elseif within( n, 3, 6 ) then
        return "few"
    elseif within( n, 7, 10 ) then
        return "many"
    end

    return "other"
end

---@type dreamwork.std.fluent.PluralRule
local function plural_cy( n )
    if n == 0 then
        return "zero"
    elseif n == 1 then
        return "one"
    elseif n == 2 then
        return "two"
    elseif n == 3 then
        return "few"
    elseif n == 6 then
        return "many"
    end

    return "other"
end

---@type dreamwork.std.fluent.PluralRule
local function plural_da( n, i, _, _, t )
    if n == 1 or (t ~= 0 and (i == 0 or i == 1)) then
        return "one"
    end

    return "other"
end

---@type dreamwork.std.fluent.PluralRule
local function plural_is( _, i, _, _, t )
    if (t == 0 and i % 10 == 1 and i % 100 ~= 11) or (t % 10 == 1 and t % 100 ~= 11) then
        return "one"
    end

    return "other"
end

--- fil, tl
---
---@type dreamwork.std.fluent.PluralRule
local function plural_fil( _, i, v, f )
    if v == 0 then
        local i10 = i % 10
        if i == 1 or i == 2 or i == 3 or (i10 ~= 4 and i10 ~= 6 and i10 ~= 9) then
            return "one"
        end
    else
        local f10 = f % 10
        if f10 ~= 4 and f10 ~= 6 and f10 ~= 9 then
            return "one"
        end
    end

    return "other"
end

---@type dreamwork.std.fluent.PluralRule
local function ordinal_en( n )
    local n10, n100 = n % 10, n % 100
    if n10 == 1 and n100 ~= 11 then
        return "one"
    elseif n10 == 2 and n100 ~= 12 then
        return "two"
    elseif n10 == 3 and n100 ~= 13 then
        return "few"
    end

    return "other"
end

---@type dreamwork.std.fluent.PluralRule
local function ordinal_sv( n )
    local n10, n100 = n % 10, n % 100
    if (n10 == 1 or n10 == 2) and n100 ~= 11 and n100 ~= 12 then
        return "one"
    end

    return "other"
end

---@type dreamwork.std.fluent.PluralRule
local function ordinal_hu( n )
    if n == 1 or n == 5 then
        return "one"
    end

    return "other"
end

---@type dreamwork.std.fluent.PluralRule
local function ordinal_it( n )
    if n == 11 or n == 8 or n == 80 or n == 800 then
        return "many"
    end

    return "other"
end

-- Locales

--- U+00A0 NO-BREAK SPACE
local NBSP = "\xC2\xA0"

--- U+202F NARROW NO-BREAK SPACE
local NNBSP = "\xE2\x80\xAF"

--- U+2212 MINUS SIGN
local MINUS = "\xE2\x88\x92"

---@type table<string, string>
local TIME_24 = { short = "{HH}:{mm}", medium = "{HH}:{mm}:{ss}" }

---@type table<string, string>
local TIME_24_SHORT_HOUR = { short = "{H}:{mm}", medium = "{H}:{mm}:{ss}" }

--- The data of locales that are not registered, English names with ISO dates and `other` plurals.
---
---@type dreamwork.std.fluent.Locale
local ROOT = {
    tag = "und",
    decimal = ".",
    group = ",",
    minus = "-",
    minimum_grouping = 1,
    primary_group = 3,
    percent = "#%",
    currency = "¤" .. NBSP .. "#",
    cardinal = plural_other,
    ordinal = plural_other,
    date = { short = "{y}-{MM}-{dd}", medium = "{y} {MMM} {d}", long = "{y} {MMMM} {d}", full = "{y} {MMMM} {d}, {EEEE}" },
    time = TIME_24,
    datetime = "{date} {time}",
    months = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" },
    months_short = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" },
    weekdays = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" },
    weekdays_short = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" },
    am = "AM",
    pm = "PM"
}

---@type table<string, dreamwork.std.fluent.Locale>
local registry = {}

--- [SHARED AND MENU]
---
--- The registered locales by their normalized tags.
---
---@type table<string, dreamwork.std.fluent.Locale>
fluent.locales = registry

--- [SHARED AND MENU]
---
--- Normalizes the BCP 47 locale tag, `en_us` -> `en-US`, `zh-hant-tw` -> `zh-Hant-TW`.
---
---@param tag string The locale tag.
---@return string normalized_tag The normalized tag.
---@nodiscard
local function normalize_tag( tag )
    local subtags, count = {}, 0

    for subtag in string_gmatch( tag, "[^%-_]+" ) do
        count = count + 1

        if count == 1 then
            subtag = string_lower( subtag )
        elseif #subtag == 2 then
            subtag = string_upper( subtag )
        elseif #subtag == 4 then
            subtag = string_upper( string_sub( subtag, 1, 1 ) ) .. string_lower( string_sub( subtag, 2 ) )
        else
            subtag = string_lower( subtag )
        end

        subtags[ count ] = subtag
    end

    return table_concat( subtags, "-", 1, count )
end

fluent.normalizeTag = normalize_tag

--- [SHARED AND MENU]
---
--- Returns the formatting data of the locale.
---
--- Subtags are removed one by one until a registered locale is found, `pt-BR` -> `pt`,
--- the data of unknown languages uses ISO dates and the `other` plural category only.
---
---@param tag string The BCP 47 locale tag, e.g. `"pt-BR"`, `"zh-Hant-TW"`.
---@return dreamwork.std.fluent.Locale locale The locale data.
---@nodiscard
local function getLocale( tag )
    tag = normalize_tag( tag )

    ::lookup::

    local locale = registry[ tag ]
    if locale ~= nil then
        return locale
    end

    local separator = string_match( tag, "()%-[^%-]*$" )
    if separator ~= nil then
        tag = string_sub( tag, 1, separator - 1 )
        goto lookup
    end

    return ROOT
end

fluent.getLocale = getLocale

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
---@param data table The locale data, see `dreamwork.std.fluent.Locale`, becomes the locale object.
---@param parent string? The tag of the parent locale, the root locale if `nil`.
---@return dreamwork.std.fluent.Locale locale The registered locale.
local function setLocale( tag, data, parent )
    tag = normalize_tag( tag )
    data.tag = tag

    local parent_locale = ROOT
    if parent ~= nil then
        parent_locale = getLocale( parent )
    end

    registry[ tag ] = setmetatable( data, { __index = parent_locale } )

    ---@cast data dreamwork.std.fluent.Locale
    return data
end

fluent.setLocale = setLocale

setLocale( "en", {
    currency = "¤#",
    cardinal = plural_one_i1v0,
    ordinal = ordinal_en,
    date = { short = "{M}/{d}/{y}", medium = "{MMM} {d}, {y}", long = "{MMMM} {d}, {y}", full = "{EEEE}, {MMMM} {d}, {y}" },
    time = { short = "{h}:{mm} {a}", medium = "{h}:{mm}:{ss} {a}" },
    datetime = "{date}, {time}"
} )

setLocale( "en-GB", {
    date = { short = "{dd}/{MM}/{y}", medium = "{d} {MMM} {y}", long = "{d} {MMMM} {y}", full = "{EEEE} {d} {MMMM} {y}" },
    time = TIME_24,
    am = "am",
    pm = "pm"
}, "en" )

setLocale( "ru", {
    decimal = ",",
    group = NBSP,
    percent = "#" .. NBSP .. "%",
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_ru,
    date = { short = "{dd}.{MM}.{y}", medium = "{d} {MMM} {y} г.", long = "{d} {MMMM} {y} г.", full = "{EEEE}, {d} {MMMM} {y} г." },
    datetime = "{date}, {time}",
    months = { "января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря" },
    months_short = { "янв.", "февр.", "мар.", "апр.", "мая", "июн.", "июл.", "авг.", "сент.", "окт.", "нояб.", "дек." },
    weekdays = { "воскресенье", "понедельник", "вторник", "среда", "четверг", "пятница", "суббота" },
    weekdays_short = { "вс", "пн", "вт", "ср", "чт", "пт", "сб" }
} )

setLocale( "uk", { date = { short = "{dd}.{MM}.{y}" } }, "ru" )
setLocale( "be", { cardinal = plural_be, date = { short = "{d}.{MM}.{y}" } }, "ru" )

setLocale( "de", {
    decimal = ",",
    group = ".",
    percent = "#" .. NBSP .. "%",
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_one_i1v0,
    date = { short = "{d}.{M}.{y}" },
    datetime = "{date}, {time}"
} )

setLocale( "fr", {
    decimal = ",",
    group = NNBSP,
    percent = "#" .. NNBSP .. "%",
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_fr,
    ordinal = plural_one_n1,
    date = { short = "{dd}/{MM}/{y}" }
} )

setLocale( "es", {
    decimal = ",",
    group = ".",
    minimum_grouping = 2,
    percent = "#" .. NBSP .. "%",
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_es,
    date = { short = "{d}/{M}/{y}" },
    time = TIME_24_SHORT_HOUR,
    datetime = "{date}, {time}"
} )

setLocale( "pt", {
    decimal = ",",
    group = ".",
    percent = "#%",
    currency = "¤" .. NBSP .. "#",
    cardinal = plural_pt,
    date = { short = "{dd}/{MM}/{y}" },
    datetime = "{date}, {time}"
} )

setLocale( "pt-PT", {
    group = NBSP,
    minimum_grouping = 2,
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_it
}, "pt" )

setLocale( "it", {
    decimal = ",",
    group = ".",
    percent = "#%",
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_it,
    ordinal = ordinal_it,
    date = { short = "{d}/{M}/{y}" },
    datetime = "{date}, {time}"
} )

setLocale( "ca", { cardinal = plural_it, ordinal = plural_other }, "it" )

setLocale( "pl", {
    decimal = ",",
    group = NBSP,
    minimum_grouping = 2,
    percent = "#%",
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_pl,
    date = { short = "{d}.{MM}.{y}" },
    datetime = "{date}, {time}"
} )

setLocale( "cs", {
    decimal = ",",
    group = NBSP,
    percent = "#" .. NBSP .. "%",
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_cs,
    date = { short = "{d}. {M}. {y}" },
    time = TIME_24_SHORT_HOUR
} )

setLocale( "sk", {}, "cs" )

setLocale( "tr", {
    decimal = ",",
    group = ".",
    percent = "%#",
    currency = "¤#",
    cardinal = plural_one_n1,
    date = { short = "{dd}.{MM}.{y}" }
} )

setLocale( "zh", {
    currency = "¤#",
    date = { short = "{y}/{M}/{d}" }
} )

setLocale( "ja", {
    currency = "¤#",
    date = { short = "{y}/{M}/{d}" },
    time = TIME_24_SHORT_HOUR
} )

setLocale( "ko", {
    currency = "¤#",
    date = { short = "{y}. {M}. {d}." },
    time = { short = "{a} {h}:{mm}", medium = "{a} {h}:{mm}:{ss}" },
    am = "오전",
    pm = "오후"
} )

setLocale( "th", {
    currency = "¤#",
    date = { short = "{d}/{M}/{y}" }
} )

setLocale( "vi", {
    decimal = ",",
    group = ".",
    currency = "#" .. NBSP .. "¤",
    date = { short = "{d}/{M}/{y}" },
    datetime = "{time} {date}"
} )

setLocale( "id", {
    decimal = ",",
    group = ".",
    currency = "¤#",
    date = { short = "{d}/{M}/{y}" },
    time = { short = "{HH}.{mm}", medium = "{HH}.{mm}.{ss}" }
} )

setLocale( "ms", {
    currency = "¤#",
    date = { short = "{d}/{M}/{y}" },
    time = { short = "{h}:{mm} {a}", medium = "{h}:{mm}:{ss} {a}" },
    datetime = "{date}, {time}",
    am = "PG",
    pm = "PTG"
} )

setLocale( "sv", {
    decimal = ",",
    group = NBSP,
    minus = MINUS,
    percent = "#" .. NBSP .. "%",
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_one_i1v0,
    ordinal = ordinal_sv
} )

setLocale( "nl", {
    decimal = ",",
    group = ".",
    currency = "¤" .. NBSP .. "#",
    cardinal = plural_one_i1v0,
    date = { short = "{d}-{M}-{y}" },
    datetime = "{date}, {time}"
} )

setLocale( "da", {
    decimal = ",",
    group = ".",
    percent = "#" .. NBSP .. "%",
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_da,
    date = { short = "{d}.{M}.{y}" },
    time = { short = "{HH}.{mm}", medium = "{HH}.{mm}.{ss}" }
} )

setLocale( "fi", {
    decimal = ",",
    group = NBSP,
    minus = MINUS,
    percent = "#" .. NBSP .. "%",
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_one_i1v0,
    date = { short = "{d}.{M}.{y}" },
    time = { short = "{H}.{mm}", medium = "{H}.{mm}.{ss}" },
    datetime = "{date} klo {time}"
} )

setLocale( "nb", {
    decimal = ",",
    group = NBSP,
    minus = MINUS,
    percent = "#" .. NBSP .. "%",
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_one_n1,
    date = { short = "{d}.{M}.{y}" },
    datetime = "{date}, {time}"
} )

setLocale( "no", {}, "nb" )
setLocale( "nn", {}, "nb" )

setLocale( "hu", {
    decimal = ",",
    group = NBSP,
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_one_n1,
    ordinal = ordinal_hu,
    date = { short = "{y}. {MM}. {dd}." },
    time = TIME_24_SHORT_HOUR
} )

setLocale( "ro", {
    decimal = ",",
    group = ".",
    percent = "#" .. NBSP .. "%",
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_ro,
    date = { short = "{dd}.{MM}.{y}" },
    datetime = "{date}, {time}"
} )

setLocale( "bg", {
    decimal = ",",
    group = NBSP,
    minimum_grouping = 2,
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_one_n1,
    date = { short = "{d}.{MM}.{y} г." },
    time = { short = "{H}:{mm} ч.", medium = "{H}:{mm}:{ss} ч." },
    datetime = "{date}, {time}"
} )

setLocale( "el", {
    decimal = ",",
    group = ".",
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_one_n1,
    date = { short = "{d}/{M}/{y}" },
    time = { short = "{h}:{mm} {a}", medium = "{h}:{mm}:{ss} {a}" },
    datetime = "{date}, {time}",
    am = "π.μ.",
    pm = "μ.μ."
} )

setLocale( "he", {
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_he,
    date = { short = "{d}.{M}.{y}" },
    time = TIME_24_SHORT_HOUR,
    datetime = "{date}, {time}"
} )

setLocale( "ar", {
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_ar,
    date = { short = "{d}/{M}/{y}" },
    time = { short = "{h}:{mm} {a}", medium = "{h}:{mm}:{ss} {a}" },
    datetime = "{date}, {time}",
    am = "ص",
    pm = "م"
} )

setLocale( "lt", {
    decimal = ",",
    group = NBSP,
    minus = MINUS,
    percent = "#" .. NBSP .. "%",
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_lt
} )

setLocale( "lv", {
    decimal = ",",
    group = NBSP,
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_lv,
    date = { short = "{dd}.{MM}.{y}." }
} )

setLocale( "et", {
    decimal = ",",
    group = NBSP,
    minus = MINUS,
    minimum_grouping = 2,
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_one_i1v0,
    date = { short = "{dd}.{MM}.{y}" },
    datetime = "{date}, {time}"
} )

setLocale( "sl", {
    decimal = ",",
    group = ".",
    minus = MINUS,
    percent = "#" .. NBSP .. "%",
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_sl,
    date = { short = "{d}. {M}. {y}" },
    datetime = "{date}, {time}"
} )

setLocale( "hr", {
    decimal = ",",
    group = ".",
    minus = MINUS,
    percent = "#" .. NBSP .. "%",
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_hr,
    date = { short = "{dd}. {MM}. {y}." }
} )

setLocale( "sr", {
    decimal = ",",
    group = ".",
    currency = "#" .. NBSP .. "¤",
    cardinal = plural_hr,
    date = { short = "{d}. {M}. {y}." }
} )

setLocale( "bs", {}, "sr" )
setLocale( "mk", { cardinal = plural_mk }, "sr" )

setLocale( "hi", {
    secondary_group = 2,
    currency = "¤#",
    cardinal = plural_hi,
    date = { short = "{d}/{M}/{y}" },
    time = { short = "{h}:{mm} {a}", medium = "{h}:{mm}:{ss} {a}" },
    datetime = "{date}, {time}",
    am = "am",
    pm = "pm"
} )

-- the languages with known plural rules only
do

    ---@type table<string, dreamwork.std.fluent.PluralRule>
    local plural_rules = {
        ga = plural_ga,
        cy = plural_cy,
        is = plural_is,
        fil = plural_fil,
        tl = plural_fil,
        hy = plural_one_i01,
        ff = plural_one_i01,
        kab = plural_one_i01,
        gl = plural_one_i1v0,
        ur = plural_one_i1v0,
        sw = plural_one_i1v0,
        fy = plural_one_i1v0,
        bn = plural_hi,
        fa = plural_hi,
        gu = plural_hi,
        kn = plural_hi,
        zu = plural_hi,
        am = plural_hi,
        af = plural_one_n1,
        az = plural_one_n1,
        ka = plural_one_n1,
        kk = plural_one_n1,
        ky = plural_one_n1,
        uz = plural_one_n1,
        sq = plural_one_n1,
        mn = plural_one_n1,
        ta = plural_one_n1,
        te = plural_one_n1,
        ml = plural_one_n1,
        ne = plural_one_n1,
        eu = plural_one_n1,
        ps = plural_one_n1,
        mr = plural_one_n1
    }

    for tag, rule in raw_pairs( plural_rules ) do
        setLocale( tag, { cardinal = rule } )
    end

end

-- Number formatting

---@type table<string, string>
local CURRENCY_SYMBOLS = {
    USD = "$",
    EUR = "€",
    GBP = "£",
    JPY = "¥",
    CNY = "CN¥",
    RUB = "₽",
    UAH = "₴",
    KRW = "₩",
    INR = "₹",
    BRL = "R$",
    TRY = "₺",
    PLN = "zł",
    ILS = "₪",
    VND = "₫",
    THB = "฿",
    PHP = "₱",
    KZT = "₸",
    CAD = "CA$",
    AUD = "A$"
}

--- Currencies without minor units, the others use `2` fraction digits.
---
---@type table<string, integer>
local CURRENCY_DIGITS = {
    JPY = 0, KRW = 0, VND = 0, CLP = 0, ISK = 0, PYG = 0, UGX = 0, XAF = 0, XOF = 0, IDR = 0, HUF = 2
}

--- Returns the shortest round-trip decimal digits of the positive finite number.
---
---@param absolute number
---@return string digits The significant digits, without leading and trailing zeros.
---@return integer point The number of digits before the decimal point, the value is `0.<digits> * 10^point`.
local function shortest_digits( absolute )
    local str = string_format( "%.14e", absolute )
    if raw_tonumber( str ) ~= absolute then
        str = string_format( "%.15e", absolute )
        if raw_tonumber( str ) ~= absolute then
            str = string_format( "%.16e", absolute )
        end
    end

    local first, rest, exponent = string_match( str, "^(%d)%.?(%d*)e([-+]%d+)$" )
    return string_match( first .. rest, "^(.-)0*$" ), raw_tonumber( exponent ) + 1
end

--- Rounds the digits to the given count, half away from zero like ECMA-402.
---
---@param digits string
---@param point integer
---@param count integer The number of digits to keep.
---@return string digits The rounded digits, without trailing zeros, `""` if the value became zero.
---@return integer point
local function round_digits( digits, point, count )
    local length = #digits
    if count >= length then
        return digits, point
    elseif count < 0 then
        return "", 0
    end

    local round_up = string_byte( digits, count + 1 ) >= 0x35 --[[ 5 ]]
    digits = string_sub( digits, 1, count )

    if round_up then
        local position = count

        while position > 0 and string_byte( digits, position ) == 0x39 --[[ 9 ]] do
            position = position - 1
        end

        if position == 0 then
            return "1", point + 1
        end

        digits = string_sub( digits, 1, position - 1 ) .. string_char( string_byte( digits, position ) + 1 )
    end

    return string_match( digits, "^(.-)0*$" ), point
end

--- Splits the non-negative number into rounded integer and fraction digits.
---
---@param absolute number
---@param min_fraction integer
---@param max_fraction integer
---@param min_significant integer | nil `nil` disables the significant digits rounding.
---@param max_significant integer | nil
---@return string integer
---@return string fraction
local function number_parts( absolute, min_fraction, max_fraction, min_significant, max_significant )
    if absolute == 0 then
        if min_significant == nil then
            return "0", string_rep( "0", min_fraction )
        end

        return "0", string_rep( "0", min_significant - 1 )
    end

    if min_significant == nil and absolute % 1 == 0 and absolute < 9007199254740992 then
        return string_format( "%.0f", absolute ), string_rep( "0", min_fraction )
    end

    local digits, point = shortest_digits( absolute )

    if min_significant == nil then
        digits, point = round_digits( digits, point, point + max_fraction )
    else
        ---@cast max_significant integer
        digits, point = round_digits( digits, point, max_significant )
    end

    local length = #digits
    if length == 0 then
        if min_significant == nil then
            return "0", string_rep( "0", min_fraction )
        end

        return "0", string_rep( "0", min_significant - 1 )
    end

    local integer, fraction
    if point <= 0 then
        integer, fraction = "0", string_rep( "0", -point ) .. digits
    elseif point >= length then
        integer, fraction = digits .. string_rep( "0", point - length ), ""
    else
        integer, fraction = string_sub( digits, 1, point ), string_sub( digits, point + 1 )
    end

    if min_significant == nil then
        local missing = min_fraction - #fraction
        if missing > 0 then
            fraction = fraction .. string_rep( "0", missing )
        end
    else
        local shown = length
        if point > length then
            shown = point
        end

        local missing = min_significant - shown
        if missing > 0 then
            fraction = fraction .. string_rep( "0", missing )
        end
    end

    return integer, fraction
end

--- Resolves the fraction and significant digits options.
---
---@param options dreamwork.std.fluent.NumberOptions
---@param default_min integer
---@param default_max integer
---@return integer min_fraction
---@return integer max_fraction
---@return integer | nil min_significant
---@return integer | nil max_significant
local function digit_options( options, default_min, default_max )
    local min_significant, max_significant = options.minimumSignificantDigits, options.maximumSignificantDigits
    if min_significant ~= nil or max_significant ~= nil then
        min_significant = min_significant or 1
        return 0, 0, min_significant, math_max( max_significant or 21, min_significant )
    end

    local min_fraction, max_fraction = options.minimumFractionDigits, options.maximumFractionDigits

    if min_fraction == nil then
        min_fraction = math_min( default_min, max_fraction or default_min )
    end

    ---@cast min_fraction integer

    if max_fraction == nil then
        max_fraction = math_max( default_max, min_fraction )
    elseif max_fraction < min_fraction then
        max_fraction = min_fraction
    end

    ---@cast max_fraction integer

    return min_fraction, max_fraction, nil, nil
end

--- Inserts the grouping separators into the integer digits.
---
---@param integer string
---@param locale dreamwork.std.fluent.Locale
---@param minimum_grouping integer
---@return string
local function group_digits( integer, locale, minimum_grouping )
    local length = #integer
    local primary = locale.primary_group

    if length < primary + minimum_grouping then
        return integer
    end

    local size = locale.secondary_group or primary
    local head_length = length - primary

    local first = head_length % size
    if first == 0 then
        first = size
    end

    local parts, count = { string_sub( integer, 1, first ) }, 1

    for position = first + 1, head_length, size do
        count = count + 1
        parts[ count ] = string_sub( integer, position, position + size - 1 )
    end

    count = count + 1
    parts[ count ] = string_sub( integer, head_length + 1 )

    return table_concat( parts, locale.group, 1, count )
end

--- Places the number and the currency into the locale pattern.
---
---@param pattern string
---@param body string
---@param symbol string
---@return string
local function apply_pattern( pattern, body, symbol )
    local prefix, suffix = string_match( pattern, "^(.-)#(.*)$" )

    if symbol ~= "" then
        -- alphabetic codes are separated from digits, `USD 1.00`
        local alphabetic = string_find( symbol, "^%a+$" ) ~= nil

        if alphabetic and string_sub( prefix, -2 ) == "¤" then
            prefix = prefix .. NBSP
        end

        if alphabetic and string_sub( suffix, 1, 2 ) == "¤" then
            suffix = NBSP .. suffix
        end

        prefix = string_gsub( prefix, "¤", symbol, 1 )
        suffix = string_gsub( suffix, "¤", symbol, 1 )
    end

    return prefix .. body .. suffix
end

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
---@param options dreamwork.std.fluent.NumberOptions? The formatting options.
---@param locale ( dreamwork.std.fluent.Locale | string )? The locale or its tag, the root locale by default.
---@return string str The formatted number.
---@nodiscard
local function formatNumber( value, options, locale )
    if locale == nil then
        locale = ROOT
    elseif isString( locale ) then
        ---@cast locale string
        locale = getLocale( locale )
    end

    ---@cast locale dreamwork.std.fluent.Locale

    if value ~= value then
        return "NaN"
    end

    if options == nil then
        options = EMPTY
    end

    ---@cast options dreamwork.std.fluent.NumberOptions

    local negative = value < 0 or (value == 0 and 1 / value < 0)

    local absolute = value
    if negative then
        absolute = -value
    end

    local style = options.style
    local default_min, default_max = 0, 3
    local symbol = ""

    if style == "percent" then
        absolute = absolute * 100
        default_max = 0
    elseif style == "currency" then
        local code = string_upper( options.currency or "XXX" )

        default_min = CURRENCY_DIGITS[ code ] or 2
        default_max = default_min

        local display = options.currencyDisplay
        if display == "code" or display == "name" then
            symbol = code
        else
            symbol = CURRENCY_SYMBOLS[ code ] or code
        end
    end

    local body

    if absolute == math_huge then
        body = "∞"
    else
        local integer, fraction = number_parts( absolute, digit_options( options, default_min, default_max ) )

        local min_integer = options.minimumIntegerDigits
        if min_integer ~= nil and #integer < min_integer then
            integer = string_rep( "0", min_integer - #integer ) .. integer
        end

        local grouping = options.useGrouping
        if grouping == nil or grouping == true or grouping == "auto" or grouping == "true" then
            integer = group_digits( integer, locale, locale.minimum_grouping )
        elseif grouping == "always" then
            integer = group_digits( integer, locale, 1 )
        elseif grouping == "min2" then
            integer = group_digits( integer, locale, 2 )
        end

        if fraction == "" then
            body = integer
        else
            body = integer .. locale.decimal .. fraction
        end
    end

    if style == "percent" then
        body = apply_pattern( locale.percent, body, "" )
    elseif style == "currency" then
        body = apply_pattern( locale.currency, body, symbol )
    end

    if negative then
        return locale.minus .. body
    end

    return body
end

fluent.formatNumber = formatNumber

--- [SHARED AND MENU]
---
--- Returns the plural category of the number like `Intl.PluralRules`.
---
--- The fraction and significant digits options affect the category, `1.0` is `other` in English.
---
---@param value number The number.
---@param options dreamwork.std.fluent.NumberOptions? The digits options and the rule `type`.
---@param locale ( dreamwork.std.fluent.Locale | string )? The locale or its tag, the root locale by default.
---@return dreamwork.std.fluent.Category category The plural category.
---@nodiscard
local function pluralCategory( value, options, locale )
    if locale == nil then
        locale = ROOT
    elseif isString( locale ) then
        ---@cast locale string
        locale = getLocale( locale )
    end

    ---@cast locale dreamwork.std.fluent.Locale

    if options == nil then
        options = EMPTY
    end

    ---@cast options dreamwork.std.fluent.NumberOptions

    local rule = locale.cardinal
    if options.type == "ordinal" then
        rule = locale.ordinal
    end

    local absolute = math_abs( value )
    if absolute ~= absolute or absolute == math_huge then
        return "other"
    end

    if absolute % 1 == 0 and absolute < 9007199254740992 and (options.minimumFractionDigits or 0) == 0 and options.minimumSignificantDigits == nil and options.maximumSignificantDigits == nil then
        return rule( absolute, absolute, 0, 0, 0, 0 )
    end

    local integer, fraction = number_parts( absolute, digit_options( options, 0, 3 ) )

    local i = raw_tonumber( integer ) or 0
    local v = #fraction
    if v == 0 then
        return rule( i, i, 0, 0, 0, 0 )
    end

    local trimmed = string_match( fraction, "^(.-)0*$" )
    local w = #trimmed

    local t = 0
    if w ~= 0 then
        t = raw_tonumber( trimmed ) or 0
    end

    return rule( raw_tonumber( integer .. "." .. fraction ) or 0, i, v, raw_tonumber( fraction ) or 0, t, w )
end

fluent.pluralCategory = pluralCategory

-- Date formatting

---@type table<string, boolean>
local UTC_ZONES = { UTC = true, utc = true, GMT = true, [ "Etc/UTC" ] = true, [ "Etc/GMT" ] = true }

--- [SHARED AND MENU]
---
--- Formats the Unix timestamp like `Intl.DateTimeFormat`, see `dreamwork.std.fluent.DateTimeOptions`.
---
--- ```lua
--- print( fluent.formatDateTime( 905989690, { dateStyle = "long", timeZone = "UTC" }, "en" ) ) -- September 16, 1998
--- print( fluent.formatDateTime( 905989690, { dateStyle = "short", timeStyle = "short", timeZone = "UTC" }, "ru" ) ) -- 16.09.1998, 23:48
--- ```
---
---@param timestamp number The Unix timestamp in seconds.
---@param options dreamwork.std.fluent.DateTimeOptions? The formatting options.
---@param locale ( dreamwork.std.fluent.Locale | string )? The locale or its tag, the root locale by default.
---@return string str The formatted date and time.
---@nodiscard
local function formatDateTime( timestamp, options, locale )
    if locale == nil then
        locale = ROOT
    elseif isString( locale ) then
        ---@cast locale string
        locale = getLocale( locale )
    end

    ---@cast locale dreamwork.std.fluent.Locale

    if options == nil then
        options = EMPTY
    end

    ---@cast options dreamwork.std.fluent.DateTimeOptions

    local date_style, time_style = options.dateStyle, options.timeStyle

    if date_style == nil and time_style == nil then
        local month = options.month

        if options.weekday ~= nil then
            date_style = "full"
        elseif month == "long" then
            date_style = "long"
        elseif month == "short" or month == "narrow" then
            date_style = "medium"
        elseif options.year ~= nil or month ~= nil or options.day ~= nil then
            date_style = "short"
        end

        if options.second ~= nil then
            time_style = "medium"
        elseif options.hour ~= nil or options.minute ~= nil then
            time_style = "short"
        end

        if date_style == nil and time_style == nil then
            date_style = "short"
        end
    end

    local pattern

    if date_style ~= nil then
        local dates = locale.date
        pattern = dates[ date_style ] or dates.short
    end

    if time_style ~= nil then
        local short = time_style == "short"
        local hour12 = options.hour12

        local time_pattern
        if hour12 == nil then
            local times = locale.time
            time_pattern = short and times.short or times.medium
        elseif hour12 == true or hour12 == "true" then
            time_pattern = short and "{h}:{mm} {a}" or "{h}:{mm}:{ss} {a}"
        else
            time_pattern = short and "{HH}:{mm}" or "{HH}:{mm}:{ss}"
        end

        if pattern == nil then
            pattern = time_pattern
        else
            pattern = string_gsub( locale.datetime, "{(%a+)}", { date = pattern, time = time_pattern } )
        end
    end

    local zone = options.timeZone
    if zone == nil or not UTC_ZONES[ zone ] then
        timestamp = timestamp + time_offset( timestamp )
    end

    local year, month, day, hour, minute, second, weekday = time_civilFromTimestamp( timestamp )

    local hour12 = hour % 12
    if hour12 == 0 then
        hour12 = 12
    end

    weekday = weekday + 1

    return (string_gsub( pattern, "{(%a+)}", {
        d = tostring( day ),
        dd = string_format( "%02d", day ),
        M = tostring( month ),
        MM = string_format( "%02d", month ),
        MMM = locale.months_short[ month ],
        MMMM = locale.months[ month ],
        y = tostring( year ),
        yy = string_format( "%02d", year % 100 ),
        E = locale.weekdays_short[ weekday ],
        EEEE = locale.weekdays[ weekday ],
        H = tostring( hour ),
        HH = string_format( "%02d", hour ),
        h = tostring( hour12 ),
        hh = string_format( "%02d", hour12 ),
        mm = string_format( "%02d", minute ),
        ss = string_format( "%02d", math_floor( second ) ),
        a = hour < 12 and locale.am or locale.pm
    } ))
end

fluent.formatDateTime = formatDateTime

-- Types

---@param scope dreamwork.std.fluent.Scope | nil
---@return dreamwork.std.fluent.Locale
local function scope_locale( scope )
    if scope == nil then
        return ROOT
    end

    return scope.bundle.locale
end

--- [SHARED AND MENU]
---
--- The base of values with custom formatting, inherit it to pass custom objects as variables.
---
---@class dreamwork.std.FluentType : dreamwork.std.Object
---@field __class dreamwork.std.FluentTypeClass
---@field value any The wrapped value.
local FluentType = class.base( "FluentType", false, nil )

---@param value any
---@protected
function FluentType:__init( value )
    self.value = value
end

--- [SHARED AND MENU]
---
--- Formats the value, called when the value is placed into a pattern.
---
--- The base implementation formats numbers with the bundle locale and converts other values with `tostring`.
---
---@param scope dreamwork.std.fluent.Scope? The formatting state, the bundle is `scope.bundle`.
---@return string str The formatted value.
---@nodiscard
function FluentType:toString( scope )
    local value = self.value
    if isNumber( value ) then
        return formatNumber( value, nil, scope_locale( scope ) )
    end

    return tostring( value )
end

--- [SHARED AND MENU]
---
--- The class used to create new `FluentType` objects.
---
---@class dreamwork.std.FluentTypeClass : dreamwork.std.FluentType, dreamwork.std.Class
---@field __base dreamwork.std.FluentType
---@overload fun( value: any ): dreamwork.std.FluentType
local FluentTypeClass = class.create( FluentType )
fluent.Type = FluentTypeClass

--- [SHARED AND MENU]
---
--- Checks if the value is a Fluent type ( `fluent.None`, `fluent.Number`, `fluent.DateTime` or a custom one ).
---
---@param value any The value to check.
---@return boolean is_type `true` if the value inherits `fluent.Type`.
---@nodiscard
local function isType( value )
    return class_isInherited( value, FluentType )
end

fluent.isType = isType

--- [SHARED AND MENU]
---
--- The missing value, formatted as `{name}` to show what failed to resolve.
---
---@class dreamwork.std.FluentNone : dreamwork.std.FluentType
---@field __class dreamwork.std.FluentNoneClass
---@field value string The name of the missing value, `"???"` by default.
local FluentNone = class.base( "FluentNone", false, FluentTypeClass )

---@param value string?
---@protected
function FluentNone:__init( value )
    self.value = value or "???"
end

---@return string
---@nodiscard
function FluentNone:toString()
    return "{" .. self.value .. "}"
end

--- [SHARED AND MENU]
---
--- The class used to create new `FluentNone` objects.
---
---@class dreamwork.std.FluentNoneClass : dreamwork.std.FluentNone, dreamwork.std.FluentTypeClass
---@field __base dreamwork.std.FluentNone
---@overload fun( value: string? ): dreamwork.std.FluentNone
local FluentNoneClass = class.create( FluentNone )
fluent.None = FluentNoneClass

--- Writes the flat formatting options, only string, number and boolean values are kept.
---
---@param writer dreamwork.std.BinaryWriter
---@param options table | nil
local function write_options( writer, options )
    if options == nil then
        writer:writeUInt( 0, 8 )
        return
    end

    local count = 0

    for _, value in raw_pairs( options ) do
        if isString( value ) or isNumber( value ) or isBoolean( value ) then
            count = count + 1
        end
    end

    writer:writeUInt( count, 8 )

    for key, value in raw_pairs( options ) do
        if isString( value ) then
            writer:writeString( key )
            writer:writeUInt( 0, 2 )
            writer:writeCountedString( value, 16 )
        elseif isNumber( value ) then
            writer:writeString( key )
            writer:writeUInt( 1, 2 )
            writer:writeDouble( value, true )
        elseif isBoolean( value ) then
            writer:writeString( key )
            writer:writeUInt( 2, 2 )
            writer:writeBoolean( value )
        end
    end
end

--- Reads the options written by `write_options`.
---
---@param reader dreamwork.std.BinaryReader
---@return table | nil options
local function read_options( reader )
    local count = reader:readUInt( 8 )
    if count == 0 then
        return nil
    end

    local options = {}

    for _ = 1, count, 1 do
        local key = reader:readString()
        local value_type = reader:readUInt( 2 )

        if value_type == 0 then
            options[ key ] = reader:readCountedString( 16 )
        elseif value_type == 1 then
            options[ key ] = reader:readDouble( true )
        else
            options[ key ] = reader:readBoolean()
        end
    end

    return options
end

--- [SHARED AND MENU]
---
--- The number with formatting options, numbers passed as variables are wrapped in it automatically.
---
---@class dreamwork.std.FluentNumber : dreamwork.std.FluentType
---@field __class dreamwork.std.FluentNumberClass
---@field value number The number.
---@field options dreamwork.std.fluent.NumberOptions | nil The formatting options, must not be changed since they can be shared.
local FluentNumber = class.base( "FluentNumber", false, FluentTypeClass )

---@param value number
---@param options dreamwork.std.fluent.NumberOptions?
---@protected
function FluentNumber:__init( value, options )
    self.value = value
    self.options = options
end

---@param scope dreamwork.std.fluent.Scope?
---@return string
---@nodiscard
function FluentNumber:toString( scope )
    return formatNumber( self.value, self.options, scope_locale( scope ) )
end

---@param writer dreamwork.std.BinaryWriter
---@protected
function FluentNumber:__serialize( writer )
    writer:writeDouble( self.value, true )
    write_options( writer, self.options )
end

---@param reader dreamwork.std.BinaryReader
---@protected
function FluentNumber:__deserialize( reader )
    self.value = reader:readDouble( true )
    self.options = read_options( reader )
end

--- [SHARED AND MENU]
---
--- The class used to create new `FluentNumber` objects.
---
--- ```lua
--- bundle:format( "price", { amount = fluent.Number( 9.99, { style = "currency", currency = "USD" } ) } )
--- ```
---
---@class dreamwork.std.FluentNumberClass : dreamwork.std.FluentNumber, dreamwork.std.FluentTypeClass
---@field __base dreamwork.std.FluentNumber
---@overload fun( value: number, options: dreamwork.std.fluent.NumberOptions? ): dreamwork.std.FluentNumber
local FluentNumberClass = class.create( FluentNumber )
fluent.Number = FluentNumberClass

--- [SHARED AND MENU]
---
--- The date and time, Unix timestamps must be wrapped in it to be formatted as dates.
---
---@class dreamwork.std.FluentDateTime : dreamwork.std.FluentType
---@field __class dreamwork.std.FluentDateTimeClass
---@field value number The Unix timestamp in seconds.
---@field options dreamwork.std.fluent.DateTimeOptions | nil The formatting options, must not be changed since they can be shared.
local FluentDateTime = class.base( "FluentDateTime", false, FluentTypeClass )

---@param value number
---@param options dreamwork.std.fluent.DateTimeOptions?
---@protected
function FluentDateTime:__init( value, options )
    self.value = value
    self.options = options
end

---@param scope dreamwork.std.fluent.Scope?
---@return string
---@nodiscard
function FluentDateTime:toString( scope )
    return formatDateTime( self.value, self.options, scope_locale( scope ) )
end

---@param writer dreamwork.std.BinaryWriter
---@protected
function FluentDateTime:__serialize( writer )
    writer:writeDouble( self.value, true )
    write_options( writer, self.options )
end

---@param reader dreamwork.std.BinaryReader
---@protected
function FluentDateTime:__deserialize( reader )
    self.value = reader:readDouble( true )
    self.options = read_options( reader )
end

--- [SHARED AND MENU]
---
--- The class used to create new `FluentDateTime` objects.
---
--- ```lua
--- bundle:format( "last-seen", { date = fluent.DateTime( time.now(), { dateStyle = "long" } ) } )
--- ```
---
---@class dreamwork.std.FluentDateTimeClass : dreamwork.std.FluentDateTime, dreamwork.std.FluentTypeClass
---@field __base dreamwork.std.FluentDateTime
---@overload fun( value: number, options: dreamwork.std.fluent.DateTimeOptions? ): dreamwork.std.FluentDateTime
local FluentDateTimeClass = class.create( FluentDateTime )
fluent.DateTime = FluentDateTimeClass

-- Built-in functions

---@type table<string, boolean>
local NUMBER_ALLOWED = {
    unitDisplay = true,
    currencyDisplay = true,
    useGrouping = true,
    minimumIntegerDigits = true,
    minimumFractionDigits = true,
    maximumFractionDigits = true,
    minimumSignificantDigits = true,
    maximumSignificantDigits = true,
    type = true
}

---@type table<string, boolean>
local DATETIME_ALLOWED = {
    dateStyle = true,
    timeStyle = true,
    fractionalSecondDigits = true,
    dayPeriod = true,
    hour12 = true,
    weekday = true,
    era = true,
    year = true,
    month = true,
    day = true,
    hour = true,
    minute = true,
    second = true,
    timeZoneName = true
}

--- Copies the allowed named arguments over the base options, Fluent types are unwrapped.
---
---@param named table<string, dreamwork.std.fluent.Value>
---@param allowed table<string, boolean>
---@param base table | nil
---@return table options
local function merge_options( named, allowed, base )
    local options = {}

    if base ~= nil then
        for key, value in raw_pairs( base ) do
            options[ key ] = value
        end
    end

    for key, value in raw_pairs( named ) do
        if allowed[ key ] then
            if isType( value ) then
                value = value.value
            end

            options[ key ] = value
        end
    end

    return options
end

---@type table<string, dreamwork.std.fluent.Function>
local builtins = {}

--- [SHARED AND MENU]
---
--- The built-in functions available to every bundle, `NUMBER` and `DATETIME`.
---
---@type table<string, dreamwork.std.fluent.Function>
fluent.builtins = builtins

--- `NUMBER( $value, minimumFractionDigits: 2, type: "ordinal" )`
---
---@param positional dreamwork.std.fluent.Value[]
---@param named table<string, dreamwork.std.fluent.Value>
---@return dreamwork.std.fluent.Value
function builtins.NUMBER( positional, named )
    local argument = positional[ 1 ]
    local metatable = debug_getmetatable( argument )

    if metatable == FluentNone then
        ---@cast argument dreamwork.std.FluentNone
        return FluentNoneClass( "NUMBER(" .. argument.value .. ")" )
    elseif metatable == FluentNumber then
        ---@cast argument dreamwork.std.FluentNumber
        return FluentNumberClass( argument.value, merge_options( named, NUMBER_ALLOWED, argument.options ) )
    elseif metatable == FluentDateTime then
        ---@cast argument dreamwork.std.FluentDateTime
        return FluentNumberClass( argument.value, merge_options( named, NUMBER_ALLOWED, nil ) )
    end

    error( FluentErrorClass( "Invalid argument to NUMBER" ), 2 )
end

--- `DATETIME( $date, dateStyle: "long" )`
---
---@param positional dreamwork.std.fluent.Value[]
---@param named table<string, dreamwork.std.fluent.Value>
---@return dreamwork.std.fluent.Value
function builtins.DATETIME( positional, named )
    local argument = positional[ 1 ]
    local metatable = debug_getmetatable( argument )

    if metatable == FluentNone then
        ---@cast argument dreamwork.std.FluentNone
        return FluentNoneClass( "DATETIME(" .. argument.value .. ")" )
    elseif metatable == FluentDateTime then
        ---@cast argument dreamwork.std.FluentDateTime
        return FluentDateTimeClass( argument.value, merge_options( named, DATETIME_ALLOWED, argument.options ) )
    elseif metatable == FluentNumber then
        ---@cast argument dreamwork.std.FluentNumber
        return FluentDateTimeClass( argument.value, merge_options( named, DATETIME_ALLOWED, nil ) )
    end

    error( FluentErrorClass( "Invalid argument to DATETIME" ), 2 )
end

-- Parser, a port of `FluentResource` from `@fluent/bundle`, invalid entries are skipped

--- The source being parsed.
---
---@type string
local source = ""

--- The current position in `source`.
---
---@type integer
local cursor = 1

--- The message of the last syntax error.
---
---@type string
local syntax_message = ""

--- Thrown by `syntax_error`, the entry is skipped.
---
---@type table
local SYNTAX_ERROR = {}

--- The reusable buffer of text pieces joined by `parse_pattern_elements`.
---
---@type string[]
local text_pieces = {}

---@type table<integer, dreamwork.std.fluent.NumberOptions>
local literal_options = {}

---@param message string
local function syntax_error( message )
    syntax_message = message
    raw_error( SYNTAX_ERROR, 0 )
end

--- Removes trailing spaces ( not other whitespace ) of the text.
---
---@param text string
---@return string
local function trim_trailing_spaces( text )
    local position = #text

    while string_byte( text, position ) == 0x20 --[[ " " ]] do
        position = position - 1
    end

    return string_sub( text, 1, position )
end

--- Matches the text run `[^{}\n\r]+` at the cursor.
---
---@return string | nil
local function match_text()
    local text, position = string_match( source, "^([^{}\n\r]+)()", cursor )
    if text ~= nil then
        cursor = position
    end

    return text
end

---@class dreamwork.std.fluent.Indent
---@field type "indent"
---@field value string The blank text, newlines are normalized.
---@field length integer The number of spaces in the last line.

--- Consumes blank text and checks if the pattern continues after it, the cursor is not restored if it does not.
---
---@return dreamwork.std.fluent.Indent | nil
local function parse_indent()
    local start = cursor
    cursor = string_match( source, "^%s*()", cursor )

    local uint8 = string_byte( source, cursor )

    -- special characters and the end of the source end the pattern
    if uint8 == nil or uint8 == 0x2E --[[ . ]] or uint8 == 0x5B --[[ [ ]] or uint8 == 0x2A --[[ * ]] or uint8 == 0x7D --[[ } ]] then
        return nil
    end

    -- placeables do not require indentation, text does
    if uint8 ~= 0x7B --[[ { ]] and string_byte( source, cursor - 1 ) ~= 0x20 --[[ " " ]] then
        return nil
    end

    local blank = string_sub( source, start, cursor - 1 )

    local length = 0
    local position = #blank

    while string_byte( blank, position ) == 0x20 do
        length = length + 1
        position = position - 1
    end

    return {
        type = "indent",
        value = string_gsub( blank, " *\r?\n", "\n" ),
        length = length
    }
end

local parse_pattern, parse_placeable

---@return dreamwork.std.fluent.NumberLiteral
local function parse_number_literal()
    local integer, position = string_match( source, "^(%-?%d+)()", cursor )
    local fraction, fraction_position = string_match( source, "^%.(%d+)()", position )

    local precision, text = 0, integer
    if fraction ~= nil then
        precision, text = #fraction, integer .. "." .. fraction
        position = fraction_position
    end

    cursor = position

    local options = literal_options[ precision ]
    if options == nil then
        options = { minimumFractionDigits = precision }
        literal_options[ precision ] = options
    end

    return {
        type = "num",
        value = raw_tonumber( text ),
        precision = precision,
        options = options
    }
end

---@return string
local function parse_escape_sequence()
    local escaped = string_match( source, '^\\([\\"])', cursor )
    if escaped ~= nil then
        cursor = cursor + 2
        return escaped
    end

    local hex, position = string_match( source, "^\\u(%x%x%x%x)()", cursor )
    if hex == nil then
        hex, position = string_match( source, "^\\U(%x%x%x%x%x%x)()", cursor )
    end

    if hex ~= nil then
        cursor = position

        local codepoint = raw_tonumber( hex, 16 )
        ---@cast codepoint integer

        -- surrogates and out of range code points are U+FFFD
        return utf8_encode( codepoint, true )
    end

    syntax_error( "Unknown escape sequence" )
    return ""
end

---@return dreamwork.std.fluent.StringLiteral
local function parse_string_literal()
    cursor = cursor + 1

    local value = ""

    ::string_run::

    local run, position = string_match( source, '^([^\\"\n\r]*)()', cursor )
    value = value .. run
    cursor = position

    local uint8 = string_byte( source, cursor )
    if uint8 == 0x5C --[[ \ ]] then
        value = value .. parse_escape_sequence()
        goto string_run
    elseif uint8 == 0x22 --[[ " ]] then
        cursor = cursor + 1
        return { type = "str", value = value }
    end

    syntax_error( "Unclosed string literal" )
    return { type = "str", value = value }
end

---@return dreamwork.std.fluent.Literal
local function parse_literal()
    if string_find( source, "^%-?%d", cursor ) ~= nil then
        return parse_number_literal()
    elseif string_byte( source, cursor ) == 0x22 --[[ " ]] then
        return parse_string_literal()
    end

    syntax_error( "Invalid expression" )
    return { type = "str", value = "" }
end

local parse_inline_expression

---@return dreamwork.std.fluent.CallArgument
local function parse_argument()
    local expression = parse_inline_expression()
    if expression.type ~= "mesg" then
        return expression
    end

    ---@cast expression dreamwork.std.fluent.MessageReference

    local position = string_match( source, "^%s*:%s*()", cursor )
    if position == nil then
        return expression
    end

    cursor = position

    return {
        type = "narg",
        name = expression.name,
        value = parse_literal()
    }
end

---@return dreamwork.std.fluent.CallArgument[]
local function parse_arguments()
    local arguments, count = {}, 0

    ::argument::

    local uint8 = string_byte( source, cursor )
    if uint8 ~= 0x29 --[[ ) ]] then
        if uint8 == nil then
            syntax_error( "Unclosed argument list" )
        end

        count = count + 1
        arguments[ count ] = parse_argument()

        -- commas between arguments are treated as whitespace
        cursor = string_match( source, "^%s*,?%s*()", cursor )
        goto argument
    end

    cursor = cursor + 1
    return arguments
end

---@return dreamwork.std.fluent.Expression
function parse_inline_expression()
    local uint8 = string_byte( source, cursor )
    if uint8 == 0x7B --[[ { ]] then
        return parse_placeable()
    end

    local start = cursor
    if uint8 == 0x24 --[[ $ ]] or uint8 == 0x2D --[[ - ]] then
        start = start + 1
    end

    local name, position = string_match( source, "^([a-zA-Z][%w_%-]*)()", start )
    if name == nil then
        return parse_literal()
    end

    local attribute, attribute_position = string_match( source, "^%.([a-zA-Z][%w_%-]*)()", position )
    if attribute ~= nil then
        position = attribute_position
    end

    cursor = position

    if uint8 == 0x24 --[[ $ ]] then
        return { type = "var", name = name }
    end

    position = string_match( source, "^%s*%(%s*()", cursor )
    if position ~= nil then
        cursor = position

        local arguments = parse_arguments()

        if uint8 == 0x2D --[[ - ]] then
            return { type = "term", name = name, id = "-" .. name, attribute = attribute, arguments = arguments }
        elseif string_find( name, "^[A-Z][A-Z0-9_%-]*$" ) == nil then
            syntax_error( "Function names must be all upper-case" )
        end

        return { type = "func", name = name, arguments = arguments }
    end

    if uint8 == 0x2D --[[ - ]] then
        return { type = "term", name = name, id = "-" .. name, attribute = attribute, arguments = EMPTY }
    end

    return { type = "mesg", name = name, attribute = attribute }
end

---@return dreamwork.std.fluent.Literal
local function parse_variant_key()
    cursor = string_match( source, "^%[%s*()", cursor ) or syntax_error( "Expected [" )

    local key
    if string_find( source, "^%-?%d", cursor ) ~= nil then
        key = parse_number_literal()
    else
        local name, position = string_match( source, "^([a-zA-Z][%w_%-]*)()", cursor )
        if name == nil then
            syntax_error( "Expected variant key" )
        end

        cursor = position
        key = { type = "str", value = name }
    end

    cursor = string_match( source, "^%s*] *()", cursor ) or syntax_error( "Expected ]" )
    return key
end

---@return dreamwork.std.fluent.Variant[] variants
---@return integer star
local function parse_variants()
    local variants, count, star = {}, 0, nil

    ::variant::

    if string_find( source, "^%*?%[", cursor ) ~= nil then
        if string_byte( source, cursor ) == 0x2A --[[ * ]] then
            cursor = cursor + 1
            star = count + 1
        end

        local key = parse_variant_key()

        local value = parse_pattern()
        if value == nil then
            syntax_error( "Expected variant value" )
        end

        count = count + 1
        variants[ count ] = { key = key, value = value }
        goto variant
    end

    if count == 0 then
        syntax_error( "Expected variants" )
    elseif star == nil then
        syntax_error( "Expected default variant" )
    end

    ---@cast star integer
    return variants, star
end

---@return dreamwork.std.fluent.Expression
function parse_placeable()
    -- `{` is checked by callers
    cursor = string_match( source, "^{%s*()", cursor )

    local selector = parse_inline_expression()

    local position = string_match( source, "^%s*}()", cursor )
    if position ~= nil then
        cursor = position
        return selector
    end

    position = string_match( source, "^%s*%->%s*()", cursor )
    if position == nil then
        syntax_error( "Unclosed placeable" )
    end

    cursor = position

    local variants, star = parse_variants()

    cursor = string_match( source, "^%s*}()", cursor ) or syntax_error( "Expected }" )

    return {
        type = "select",
        selector = selector,
        variants = variants,
        star = star
    }
end

--- Parses the pattern elements, dedents and joins them.
---
---@param elements ( string | dreamwork.std.fluent.Expression | dreamwork.std.fluent.Indent )[]
---@param common_indent number
---@return dreamwork.std.fluent.Pattern
local function parse_pattern_elements( elements, common_indent )
    local count = #elements

    ::element::

    local text = match_text()
    if text ~= nil then
        count = count + 1
        elements[ count ] = text
        goto element
    end

    local uint8 = string_byte( source, cursor )
    if uint8 == 0x7B --[[ { ]] then
        count = count + 1
        elements[ count ] = parse_placeable()
        goto element
    elseif uint8 == 0x7D --[[ } ]] then
        syntax_error( "Unbalanced closing brace" )
    end

    local indent = parse_indent()
    if indent ~= nil then
        count = count + 1
        elements[ count ] = indent

        if indent.length < common_indent then
            common_indent = indent.length
        end

        goto element
    end

    local last = elements[ count ]
    if isString( last ) then
        ---@cast last string
        elements[ count ] = trim_trailing_spaces( last )
    end

    local pattern, pattern_length = {}, 0
    local piece_count = 0

    for index = 1, count, 1 do
        local element = elements[ index ]

        if not isString( element ) and element.type == "indent" then
            ---@cast element dreamwork.std.fluent.Indent
            local value = element.value
            element = string_sub( value, 1, #value - common_indent )
        end

        if isString( element ) then
            ---@cast element string
            if element ~= "" then
                piece_count = piece_count + 1
                text_pieces[ piece_count ] = element
            end
        else
            if piece_count ~= 0 then
                pattern_length = pattern_length + 1
                pattern[ pattern_length ] = table_concat( text_pieces, "", 1, piece_count )
                piece_count = 0
            end

            pattern_length = pattern_length + 1
            pattern[ pattern_length ] = element
        end
    end

    if piece_count ~= 0 then
        local joined = table_concat( text_pieces, "", 1, piece_count )
        if pattern_length == 0 then
            return joined
        end

        pattern_length = pattern_length + 1
        pattern[ pattern_length ] = joined
    end

    if pattern_length == 0 then
        return ""
    end

    ---@cast pattern dreamwork.std.fluent.PatternElement[]
    return pattern
end

---@return dreamwork.std.fluent.Pattern | nil
function parse_pattern()
    -- simple text on the same line as the identifier
    local first = match_text()

    local uint8 = string_byte( source, cursor )
    if uint8 == 0x7B --[[ { ]] or uint8 == 0x7D --[[ } ]] then
        return parse_pattern_elements( { first }, math_huge )
    end

    -- the pattern continues only if the next line is indented
    local indent = parse_indent()
    if indent ~= nil then
        if first ~= nil then
            -- the blank block is a part of the value
            return parse_pattern_elements( { first, indent }, indent.length )
        end

        -- the block pattern, leading newlines are discarded, the indent is kept for dedenting
        indent.value = string_gsub( indent.value, "^\n+", "" )
        return parse_pattern_elements( { indent }, indent.length )
    end

    if first ~= nil then
        return trim_trailing_spaces( first )
    end

    return nil
end

---@param id string
---@return dreamwork.std.fluent.Message
local function parse_message( id )
    local value = parse_pattern()

    local attributes, has_attributes = {}, false

    ::attribute::

    local name, position = string_match( source, "^%.([a-zA-Z][%w_%-]*) *= *()", cursor )
    if name ~= nil then
        cursor = position

        local attribute_value = parse_pattern()
        if attribute_value == nil then
            syntax_error( "Expected attribute value" )
        end

        ---@cast attribute_value dreamwork.std.fluent.Pattern
        attributes[ name ] = attribute_value
        has_attributes = true

        goto attribute
    end

    if value == nil then
        if string_byte( id, 1 ) == 0x2D --[[ - ]] then
            syntax_error( "Expected term value" )
        elseif not has_attributes then
            syntax_error( "Expected message value or attributes" )
        end
    end

    return {
        id = id,
        value = value,
        attributes = attributes
    }
end

--- Parses the FTL source into entries, invalid entries are skipped and reported.
---
---@param text string
---@param body dreamwork.std.fluent.Message[]
---@param errors string[]
local function parse_resource( text, body, errors )
    source = text

    local position = 1

    -- UTF-8 BOM
    if string_sub( text, 1, 3 ) == "\xEF\xBB\xBF" then
        position = 4
    end

    local entry_count, error_count = #body, #errors

    ::line::

    local id, value_position = string_match( text, "^(%-?[a-zA-Z][%w_%-]*) *= *()", position )
    if id ~= nil then
        cursor = value_position

        local success, result = pcall( parse_message, id )
        if success then
            entry_count = entry_count + 1
            body[ entry_count ] = result
        elseif result == SYNTAX_ERROR then
            local _, line = string_gsub( string_sub( text, 1, position ), "\n", "" )

            error_count = error_count + 1
            errors[ error_count ] = string_format( "line %d: %s in '%s'", line + 1, syntax_message, id )
        else
            source = ""
            raw_error( result, 0 )
        end

        position = value_position
    end

    local newline = string_find( text, "\n", position, true )
    if newline ~= nil then
        position = newline + 1
        goto line
    end

    source = ""
end

--- [SHARED AND MENU]
---
--- The parsed FTL ( Fluent Translation List ) source.
---
--- The parser is the runtime one from `@fluent/bundle`: comments are ignored
--- and invalid entries are skipped, their errors are collected in `errors`.
---
---@class dreamwork.std.FluentResource : dreamwork.std.Object
---@field __class dreamwork.std.FluentResourceClass
---@field body dreamwork.std.fluent.Message[] The messages and terms in the source order.
---@field errors string[] The syntax errors of skipped entries, e.g. `line 4: Expected default variant in 'emails'`.
local FluentResource = class.base( "FluentResource", false, nil )

---@param text string?
---@protected
function FluentResource:__init( text )
    self.body = {}
    self.errors = {}

    if text ~= nil then
        parse_resource( text, self.body, self.errors )
    end
end

---@return string
---@nodiscard
---@protected
function FluentResource:__represent()
    return string_format( "FluentResource: %p [%d entries]", self, #self.body )
end

--- [SHARED AND MENU]
---
--- Parses more FTL source into the resource.
---
---@param text string The FTL source.
---@return dreamwork.std.FluentResource resource The resource itself.
function FluentResource:parse( text )
    parse_resource( text, self.body, self.errors )
    return self
end

--- [SHARED AND MENU]
---
--- The class used to create new `FluentResource` objects.
---
---@class dreamwork.std.FluentResourceClass : dreamwork.std.FluentResource, dreamwork.std.Class
---@field __base dreamwork.std.FluentResource
---@overload fun( text: string? ): dreamwork.std.FluentResource
local FluentResourceClass = class.create( FluentResource )
fluent.Resource = FluentResourceClass

-- Resolver

--- Wraps values that are not errors ( messages, thrown values ) in `FluentError`.
---
---@param value any
---@return dreamwork.std.Error
local function to_error( value )
    if isError( value ) then
        return value
    end

    return FluentErrorClass( tostring( value ) )
end

--- Reports the error, throws it if the scope does not collect errors.
---
---@param scope dreamwork.std.fluent.Scope
---@param value any
local function report( scope, value )
    local err = to_error( value )

    local errors = scope.errors
    if errors == nil then
        error( err, 3 )
    end

    ---@cast errors dreamwork.std.Error[]
    errors[ #errors + 1 ] = err
end

local resolve_expression, resolve_pattern

---@param scope dreamwork.std.fluent.Scope
---@param arguments dreamwork.std.fluent.CallArgument[]
---@return dreamwork.std.fluent.Value[] positional
---@return table<string, dreamwork.std.fluent.Value> named
local function resolve_arguments( scope, arguments )
    local positional, named, count = {}, {}, 0

    for index = 1, #arguments, 1 do
        local argument = arguments[ index ]
        if argument.type == "narg" then
            ---@cast argument dreamwork.std.fluent.NamedArgument
            named[ argument.name ] = resolve_expression( scope, argument.value )
        else
            ---@cast argument dreamwork.std.fluent.Expression
            count = count + 1
            positional[ count ] = resolve_expression( scope, argument )
        end
    end

    return positional, named
end

---@param scope dreamwork.std.fluent.Scope
---@param name string
---@return dreamwork.std.fluent.Value
local function resolve_variable( scope, name )
    local value

    local params = scope.params
    if params == nil then
        local args = scope.args
        if args ~= nil then
            value = args[ name ]
        end

        if value == nil then
            report( scope, "Unknown variable: $" .. name )
            return FluentNoneClass( "$" .. name )
        end
    else
        -- terms can reference undefined parameters
        value = params[ name ]

        if value == nil then
            return FluentNoneClass( "$" .. name )
        end
    end

    if isString( value ) then
        ---@cast value string
        return value
    elseif isNumber( value ) then
        ---@cast value number
        return FluentNumberClass( value, nil )
    elseif isType( value ) then
        ---@cast value dreamwork.std.FluentType
        return value
    end

    report( scope, string_format( "Variable type not supported: $%s, %s", name, type( value ) ) )
    return FluentNoneClass( "$" .. name )
end

---@param scope dreamwork.std.fluent.Scope
---@param expression dreamwork.std.fluent.MessageReference
---@return dreamwork.std.fluent.Value
local function resolve_message_reference( scope, expression )
    local name = expression.name

    local message = scope.bundle.messages[ name ]
    if message == nil then
        report( scope, "Unknown message: " .. name )
        return FluentNoneClass( name )
    end

    local attribute = expression.attribute
    if attribute ~= nil then
        local pattern = message.attributes[ attribute ]
        if pattern == nil then
            report( scope, "Unknown attribute: " .. attribute )
            return FluentNoneClass( name .. "." .. attribute )
        end

        return resolve_pattern( scope, pattern )
    end

    local value = message.value
    if value == nil then
        report( scope, "No value: " .. name )
        return FluentNoneClass( name )
    end

    return resolve_pattern( scope, value )
end

---@param scope dreamwork.std.fluent.Scope
---@param expression dreamwork.std.fluent.TermReference
---@return dreamwork.std.fluent.Value
local function resolve_term_reference( scope, expression )
    local id = expression.id

    local term = scope.bundle.terms[ id ]
    if term == nil then
        report( scope, "Unknown term: " .. id )
        return FluentNoneClass( id )
    end

    local pattern

    local attribute = expression.attribute
    if attribute == nil then
        pattern = term.value
    else
        pattern = term.attributes[ attribute ]

        if pattern == nil then
            report( scope, "Unknown attribute: " .. attribute )
            return FluentNoneClass( id .. "." .. attribute )
        end
    end

    -- every term reference has its own variables
    local _, named = resolve_arguments( scope, expression.arguments )

    local params = scope.params
    scope.params = named

    local resolved = resolve_pattern( scope, pattern )
    scope.params = params

    return resolved
end

---@param scope dreamwork.std.fluent.Scope
---@param expression dreamwork.std.fluent.FunctionReference
---@return dreamwork.std.fluent.Value
local function resolve_function_reference( scope, expression )
    local name = expression.name

    local fn = scope.bundle.functions[ name ]
    if fn == nil then
        report( scope, "Unknown function: " .. name .. "()" )
        return FluentNoneClass( name .. "()" )
    end

    local positional, named = resolve_arguments( scope, expression.arguments )

    local result
    if scope.errors == nil then
        result = fn( positional, named )
    else
        local success, value = pcall( fn, positional, named )
        if not success then
            report( scope, value )
            return FluentNoneClass( name .. "()" )
        end

        result = value
    end

    if result == nil then
        return FluentNoneClass( name .. "()" )
    elseif isNumber( result ) then
        ---@cast result number
        return FluentNumberClass( result, nil )
    end

    ---@cast result dreamwork.std.fluent.Value
    return result
end

---@param scope dreamwork.std.fluent.Scope
---@param expression dreamwork.std.fluent.SelectExpression
---@return dreamwork.std.fluent.Value
local function resolve_select_expression( scope, expression )
    local selector = resolve_expression( scope, expression.selector )
    local variants = expression.variants

    if isString( selector ) then
        for index = 1, #variants, 1 do
            local variant = variants[ index ]
            local key = variant.key

            if key.type == "str" and key.value == selector then
                return resolve_pattern( scope, variant.value )
            end
        end
    elseif class_isInherited( selector, FluentNumber ) then
        ---@cast selector dreamwork.std.FluentNumber
        local value = selector.value

        ---@type dreamwork.std.fluent.Category | nil
        local category

        for index = 1, #variants, 1 do
            local variant = variants[ index ]
            local key = variant.key

            if key.type == "num" then
                if key.value == value then
                    return resolve_pattern( scope, variant.value )
                end
            else
                if category == nil then
                    category = pluralCategory( value, selector.options, scope.bundle.locale )
                end

                if key.value == category then
                    return resolve_pattern( scope, variant.value )
                end
            end
        end
    end

    return resolve_pattern( scope, variants[ expression.star ].value )
end

---@param scope dreamwork.std.fluent.Scope
---@param expression dreamwork.std.fluent.Expression
---@return dreamwork.std.fluent.Value
function resolve_expression( scope, expression )
    local expression_type = expression.type

    if expression_type == "str" then
        ---@cast expression dreamwork.std.fluent.StringLiteral
        return expression.value
    elseif expression_type == "var" then
        ---@cast expression dreamwork.std.fluent.VariableReference
        return resolve_variable( scope, expression.name )
    elseif expression_type == "num" then
        ---@cast expression dreamwork.std.fluent.NumberLiteral
        return FluentNumberClass( expression.value, expression.options )
    elseif expression_type == "mesg" then
        ---@cast expression dreamwork.std.fluent.MessageReference
        return resolve_message_reference( scope, expression )
    elseif expression_type == "term" then
        ---@cast expression dreamwork.std.fluent.TermReference
        return resolve_term_reference( scope, expression )
    elseif expression_type == "func" then
        ---@cast expression dreamwork.std.fluent.FunctionReference
        return resolve_function_reference( scope, expression )
    elseif expression_type == "select" then
        ---@cast expression dreamwork.std.fluent.SelectExpression
        return resolve_select_expression( scope, expression )
    end

    return FluentNoneClass( nil )
end

---@param scope dreamwork.std.fluent.Scope
---@param pattern dreamwork.std.fluent.PatternElement[]
---@return dreamwork.std.fluent.Value
local function resolve_complex_pattern( scope, pattern )
    local dirty = scope.dirty
    if dirty[ pattern ] then
        report( scope, "Cyclic reference" )
        return FluentNoneClass( nil )
    end

    dirty[ pattern ] = true

    local bundle = scope.bundle
    local transform = bundle.transform

    local length = #pattern
    local use_isolating = bundle.use_isolating and length > 1

    local result = {}

    for index = 1, length, 1 do
        local element = pattern[ index ]

        if isString( element ) then
            ---@cast element string
            if transform ~= nil then
                element = transform( element )
            end
        else
            ---@cast element dreamwork.std.fluent.Expression
            local placeables = scope.placeables + 1
            scope.placeables = placeables

            if placeables > MAX_PLACEABLES then
                dirty[ pattern ] = nil
                error( FluentErrorClass( string_format( "Too many placeables expanded: %d, max allowed is %d", placeables, MAX_PLACEABLES ) ), 2 )
            end

            local value = resolve_expression( scope, element )
            if not isString( value ) then
                ---@cast value dreamwork.std.FluentType
                value = value:toString( scope )
            end

            ---@cast value string

            if use_isolating then
                element = FSI .. value .. PDI
            else
                element = value
            end
        end

        result[ index ] = element
    end

    dirty[ pattern ] = nil

    return table_concat( result, "", 1, length )
end

---@param scope dreamwork.std.fluent.Scope
---@param pattern dreamwork.std.fluent.Pattern
---@return dreamwork.std.fluent.Value
function resolve_pattern( scope, pattern )
    if isString( pattern ) then
        ---@cast pattern string
        local transform = scope.bundle.transform
        if transform == nil then
            return pattern
        end

        return transform( pattern )
    end

    ---@cast pattern dreamwork.std.fluent.PatternElement[]
    return resolve_complex_pattern( scope, pattern )
end

-- Bundle

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
---@class dreamwork.std.FluentBundle : dreamwork.std.Object
---@field __class dreamwork.std.FluentBundleClass
---@field locales string[] The locale tags, the first one is used for formatting.
---@field locale dreamwork.std.fluent.Locale The formatting data of the first locale.
---@field messages table<string, dreamwork.std.fluent.Message> The messages by their identifiers.
---@field terms table<string, dreamwork.std.fluent.Message> The terms by their identifiers, with `-`.
---@field functions table<string, dreamwork.std.fluent.Function> The functions available to messages.
---@field use_isolating boolean If `true`, placeables are wrapped in Unicode bidi isolation marks.
---@field transform ( fun( text: string ): string ) | nil The function applied to every text element.
local FluentBundle = class.base( "FluentBundle", false, nil )

---@param locales string | string[]
---@param options dreamwork.std.fluent.BundleOptions?
---@protected
function FluentBundle:__init( locales, options )
    ---@type string[]
    local tags

    if isString( locales ) then
        ---@cast locales string
        tags = { locales }
    else
        ---@cast locales string[]
        tags = locales
    end

    if options == nil then
        options = EMPTY
    end

    ---@cast options dreamwork.std.fluent.BundleOptions

    self.locales = tags
    self.locale = getLocale( tags[ 1 ] or "und" )

    self.messages = {}
    self.terms = {}

    local functions = {}

    for name, fn in raw_pairs( builtins ) do
        functions[ name ] = fn
    end

    local custom_functions = options.functions
    if custom_functions ~= nil then
        for name, fn in raw_pairs( custom_functions ) do
            functions[ name ] = fn
        end
    end

    self.functions = functions
    self.use_isolating = options.use_isolating == true
    self.transform = options.transform
end

---@return string
---@nodiscard
---@protected
function FluentBundle:__represent()
    return string_format( "FluentBundle: %p [%s]", self, table_concat( self.locales, ", " ) )
end

--- [SHARED AND MENU]
---
--- Adds the messages and terms of the resource to the bundle.
---
---@param resource dreamwork.std.FluentResource | string The resource or the FTL source to parse.
---@param allow_overrides boolean? If `true`, existing messages and terms are replaced, otherwise they are kept and reported.
---@return string[] errors The override errors, syntax errors of a parsed source are in `FluentResource.errors`.
function FluentBundle:addResource( resource, allow_overrides )
    if isString( resource ) then
        ---@cast resource string
        resource = FluentResourceClass( resource )
    end

    ---@cast resource dreamwork.std.FluentResource

    local messages, terms = self.messages, self.terms
    local errors, error_count = {}, 0

    local body = resource.body

    for index = 1, #body, 1 do
        local entry = body[ index ]
        local id = entry.id

        local entries, kind = messages, "message"
        if string_byte( id, 1 ) == 0x2D --[[ - ]] then
            entries, kind = terms, "term"
        end

        if allow_overrides or entries[ id ] == nil then
            entries[ id ] = entry
        else
            error_count = error_count + 1
            errors[ error_count ] = string_format( "Attempt to override an existing %s: \"%s\"", kind, id )
        end
    end

    return errors
end

--- [SHARED AND MENU]
---
--- Checks if the bundle has the message, terms are not messages.
---
---@param id string The message identifier.
---@return boolean has_message `true` if the message exists.
---@nodiscard
function FluentBundle:hasMessage( id )
    return self.messages[ id ] ~= nil
end

--- [SHARED AND MENU]
---
--- Returns the message, its `value` and `attributes` patterns are formatted with `FluentBundle:formatPattern`.
---
---@param id string The message identifier.
---@return dreamwork.std.fluent.Message | nil message The message, `nil` if it does not exist.
---@nodiscard
function FluentBundle:getMessage( id )
    return self.messages[ id ]
end

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
---@param pattern dreamwork.std.fluent.Pattern The pattern to format.
---@param args table<string, dreamwork.std.fluent.Argument>? The variables.
---@param errors dreamwork.std.Error[]? The list collecting the errors.
---@return string str The formatted string.
---@nodiscard
function FluentBundle:formatPattern( pattern, args, errors )
    if isString( pattern ) then
        ---@cast pattern string
        local transform = self.transform
        if transform == nil then
            return pattern
        end

        return transform( pattern )
    end

    ---@cast pattern dreamwork.std.fluent.PatternElement[]

    ---@type dreamwork.std.fluent.Scope
    local scope = {
        bundle = self,
        args = args,
        errors = errors,
        dirty = {},
        placeables = 0
    }

    local value

    if errors == nil then
        value = resolve_complex_pattern( scope, pattern )
    else
        local success, result = pcall( resolve_complex_pattern, scope, pattern )
        if not success then
            errors[ #errors + 1 ] = to_error( result )
            return "{???}"
        end

        value = result
    end

    if isString( value ) then
        ---@cast value string
        return value
    end

    ---@cast value dreamwork.std.FluentType

    return value:toString( scope )
end

--- [SHARED AND MENU]
---
--- Formats the message value, or its attribute if the identifier is `message.attribute`.
---
---@param id string The message identifier, e.g. `"login-input"` or `"login-input.placeholder"`.
---@param args table<string, dreamwork.std.fluent.Argument>? The variables.
---@param errors dreamwork.std.Error[]? The list collecting the errors, see `FluentBundle:formatPattern`.
---@return string | nil str The formatted string, `nil` if the message or its attribute does not exist.
---@nodiscard
function FluentBundle:format( id, args, errors )
    local attribute

    local separator = string_find( id, ".", 2, true )
    if separator ~= nil then
        attribute = string_sub( id, separator + 1 )
        id = string_sub( id, 1, separator - 1 )
    end

    local message = self.messages[ id ]
    if message == nil then
        return nil
    end

    local pattern
    if attribute == nil then
        pattern = message.value
    else
        pattern = message.attributes[ attribute ]
    end

    if pattern == nil then
        return nil
    end

    return self:formatPattern( pattern, args, errors )
end

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
---@param fn dreamwork.std.fluent.Function | nil The function, `nil` removes it.
function FluentBundle:setFunction( name, fn )
    self.functions[ name ] = fn
end

--- [SHARED AND MENU]
---
--- The class used to create new `FluentBundle` objects.
---
---@class dreamwork.std.FluentBundleClass : dreamwork.std.FluentBundle, dreamwork.std.Class
---@field __base dreamwork.std.FluentBundle
---@overload fun( locales: ( string | string[] ), options: dreamwork.std.fluent.BundleOptions? ): dreamwork.std.FluentBundle
local FluentBundleClass = class.create( FluentBundle )
fluent.Bundle = FluentBundleClass
