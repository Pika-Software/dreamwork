---@class dreamwork.std
local std                    = dreamwork.std

local raw                    = std.raw
local raw_pairs              = raw.pairs
local raw_get, raw_set       = raw.get, raw.set

local debug                  = std.debug
local debug_getmetatable     = debug.getmetatable

local table                  = std.table
local table_concat           = table.concat
local table_remove           = table.remove
local table_unpack           = table.unpack
local table_shallowCopy      = table.shallowCopy

local ascii                  = std.ascii
local ascii_isLower          = ascii.isLower
local ascii_isUpper          = ascii.isUpper
local ascii_isAlpha          = ascii.isAlpha
local ascii_isDigit          = ascii.isDigit
local ascii_isHexDigit       = ascii.isHexDigit
local ascii_toInteger        = ascii.toInteger

local string                 = std.string
local string_len             = string.len
local string_sub             = string.sub
local string_find            = string.find
local string_gsub            = string.gsub
local string_lower           = string.lower
local string_format          = string.format
local string_findByte        = string.findByte
local string_byteSplit       = string.byteSplit
local string_toNumber        = string.toNumber
local string_containsBytes   = string.containsBytes
local string_byte            = string.byte
local string_char            = string.char

local unicode                = std.unicode
local unicode_lower          = unicode.lower
local unicode_isSurrogate    = unicode.isSurrogate
local unicode_isNoncharacter = unicode.isNoncharacter

local utf8                   = std.utf8
local utf8_char              = utf8.char
local utf8_codepoint         = utf8.codepoint

local percent                = std.percent
local percent_encode         = percent.encode
local percent_decode         = percent.decode
local percent_whitelist      = percent.whitelist

local punycode               = std.punycode
local punycode_encode        = punycode.encode
local punycode_unpack        = punycode.unpack

local ipv4                   = std.ipv4
local ipv4_toString          = ipv4.toString

local class                  = std.class

local tostring               = std.tostring

local isString               = std.isString
local isNumber               = std.isNumber
local isTable                = std.isTable

local IPv6                   = std.IPv6

--- [SHARED AND MENU]
---
--- A parsed URL, see the [URL Standard](https://url.spec.whatwg.org/).
---
--- Fields are computed from the internal state on access and can be assigned,
--- assigned values are parsed the same way the browser `URL` setters do,
--- invalid values are ignored.
---
--- `tostring( url )` returns `url.href`.
---
--- ```lua
--- local url = std.URL( "https://user:pass@example.com:8080/a/b?x=1#top" )
---
--- url.protocol -- "https:"
--- url.host     -- "example.com:8080"
--- url.pathname -- "/a/b"
--- url.search   -- "?x=1"
--- url.hash     -- "#top"
---
--- url.port = 443
--- url.href     -- "https://user:pass@example.com/a/b?x=1#top"
--- ```
---
---@class dreamwork.std.URL : dreamwork.std.Object, dreamwork.std.URL.State
---@field __class dreamwork.std.URLClass
---@field state dreamwork.std.URL.State The internal state, prefer the fields below.
---@field href string The whole serialized URL, assigning it re-parses the URL and throws on invalid input.
---@field origin string? *Read-only.* The `scheme://host:port` origin, `nil` for schemes without one (e.g. `file:`, `data:`).
---@field protocol string? The scheme followed by `":"`, e.g. `"https:"`.
---@field username string? The percent-encoded username, `nil` if not given.
---@field password string? The percent-encoded password, `nil` if not given.
---@field host string The hostname followed by `":port"` when the port is not the default one, `""` if there is no host.
---@field hostname string? The serialized host: a lowercase ASCII domain, a dotted IPv4 address or an IPv6 address in brackets.
---@field port integer? The port, `nil` when it is not given or is the default port of the scheme.
---@field pathname string? The path, e.g. `"/a/b"`, opaque paths (`mailto:`, `data:`) are returned as is.
---@field query string? The percent-encoded query without the leading `"?"`.
---@field search string The query with a leading `"?"`, `""` if the query is empty.
---@field searchParams dreamwork.std.URL.SearchParams The query as a list of name-value pairs, changes to it update the URL.
---@field fragment string? The percent-encoded fragment without the leading `"#"`.
---@field hash string The fragment with a leading `"#"`, `""` if the fragment is empty.
local URL                    = class.base( "URL" )

--- [SHARED AND MENU]
---
--- The class used to create new `URL` instances.
---
--- Calling the class parses `url`, relative URLs are resolved against `base`,
--- which can be a string or another `URL`.
---
--- Throws an error if `url` is invalid or is relative and `base` is not given,
--- use `URL.canParse` to check without throwing.
---
--- ```lua
--- local base_url = "https://developer.mozilla.org"
---
--- local a = std.URL( "/", base_url )                -- "https://developer.mozilla.org/"
--- local b = std.URL( base_url )                     -- "https://developer.mozilla.org/"
---
--- std.URL( "en-US/docs", b )                        -- "https://developer.mozilla.org/en-US/docs"
--- std.URL( "/en-US/docs", a )                       -- "https://developer.mozilla.org/en-US/docs"
--- std.URL( "../x?y#z", "https://h.com/a/b/c" )      -- "https://h.com/a/x?y#z"
--- std.URL( "//other.com/p", "https://h.com/" )      -- "https://other.com/p"
---
--- std.URL( "/en-US/docs" )                          -- error: Missing scheme
--- ```
---@class dreamwork.std.URLClass : dreamwork.std.URL, dreamwork.std.Class
---@field __base dreamwork.std.URL
---@overload fun( url: string, base: string | dreamwork.std.URL | nil ): dreamwork.std.URL
local URLClass               = class.create( URL )
std.URL                      = URLClass

--- [SHARED AND MENU]
---
--- A list of query parameters, stored as `{ name, value }` pairs in order.
---
--- Names may repeat, a pair without `=` in the query has an empty value.
---
--- When taken from `url.searchParams`, every change is written back to the URL.
---
--- `tostring( params )` returns the serialized query without the leading `"?"`,
--- `#params` is the number of pairs.
---
--- ```lua
--- local url = std.URL( "https://example.com/?a=1&b=2" )
--- local params = url.searchParams
---
--- params:get( "a" )      -- "1"
--- params:append( "c", "x y" )
--- url.search             -- "?a=1&b=2&c=x+y"
--- ```
---
---@class dreamwork.std.URL.SearchParams : dreamwork.std.Object
---@field __class dreamwork.std.URL.SearchParamsClass
---@field url dreamwork.std.URL | nil The URL this list belongs to, `nil` for standalone lists.
---@field [ integer ] { [ 1 ]: string, [ 2 ]: string | nil } The name-value pairs.
local SearchParams           = class.base( "URLSearchParams" )

--- [SHARED AND MENU]
---
--- The class used to create new `URL.SearchParams` instances.
---
--- Calling the class creates a list from a query string (a leading `"?"` is skipped,
--- `"+"` is decoded as a space) or from a list of `{ name, value }` pairs.
---
--- ```lua
--- std.URL.SearchParams( "?a=1&b=x+y" ):get( "b" ) -- "x y"
--- std.URL.SearchParams( { { "a", "1" }, { "flag" } } ):has( "flag" ) -- true
--- ```
---
---@class dreamwork.std.URL.SearchParamsClass : dreamwork.std.URL.SearchParams, dreamwork.std.Class
---@field __base dreamwork.std.URL.SearchParams
---@operator len:integer
---@overload fun( init: string | { [ 1 ]: string, [ 2 ]: string | nil }[] | nil, url: dreamwork.std.URL | nil ): dreamwork.std.URL.SearchParams
local SearchParamsClass      = class.create( SearchParams )
URLClass.SearchParams        = SearchParamsClass

--- [SHARED AND MENU]
---
--- Checks if the given value is a `URLSearchParams`.
---
---@param value any The value to check.
---@return boolean result Returns `true` if the value is a `URLSearchParams`, otherwise `false`.
---@nodiscard
local function isURLSearchParams( value )
    return debug_getmetatable( value ) == SearchParams
end

std.isURLSearchParams = isURLSearchParams

--- [SHARED AND MENU]
---
--- Checks if the given value is a `URL`.
---
---@param value any The value to check.
---@return boolean result Returns `true` if the value is a URL, otherwise `false`.
---@nodiscard
local function isURL( value )
    return debug_getmetatable( value ) == URL
end

std.isURL = isURL

-- special schemes and their default ports, `file` has no port
---@type table<string, ( integer | boolean )>
local SPECIAL_SCHEMES = {
    ftp = 21,
    file = true,
    http = 80,
    https = 443,
    ws = 80,
    wss = 443
}

local FORBIDDEN_HOST_BYTES = string.byteMap(
    "\0", "\t", "\n", "\r", " ", "#", "/", ":",
    "<", ">", "?", "@", "[", "\\", "]", "^", "|"
)

local FORBIDDEN_DOMAIN_BYTES = string.byteMap(
    "\0", "\t", "\n", "\r", " ", "#", "/", ":", "<", ">",
    "?", "@", "[", "\\", "]", "^", "|",
    { leading_byte = "\0", trailing_byte = "\x1F" },
    "%", "\x7F"
)

local NON_ASCII_BYTES = string.byteMap(
    { leading_byte = "\x80", trailing_byte = "\xFF" }
)

local FILE_OTHERWISE_BYTES = string.byteMap(
    "/", "\\", "?", "#"
)

-- percent-encode sets from the URL standard, written as pattern
-- classes of the bytes that get encoded, whitelists keep everything else

local C0_CONTROL_SET = "%z\1-\31\127-\255"
local FRAGMENT_SET = C0_CONTROL_SET .. " \"<>`"
local QUERY_SET = C0_CONTROL_SET .. " \"#<>"
local SPECIAL_QUERY_SET = QUERY_SET .. "'"
local PATH_SET = QUERY_SET .. "?`{}"
local USERINFO_SET = PATH_SET .. "/:;=@[\\%]^|"
local COMPONENT_SET = USERINFO_SET .. "$%%&+,"
local URLENCODED_SET = COMPONENT_SET .. "!'()~"

local C0_CONTROL_WHITELIST = percent_whitelist( "^" .. C0_CONTROL_SET )
local FRAGMENT_WHITELIST = percent_whitelist( "^" .. FRAGMENT_SET )
local QUERY_WHITELIST = percent_whitelist( "^" .. QUERY_SET )
local SPECIAL_QUERY_WHITELIST = percent_whitelist( "^" .. SPECIAL_QUERY_SET )
local PATH_WHITELIST = percent_whitelist( "^" .. PATH_SET )
local USERINFO_WHITELIST = percent_whitelist( "^" .. USERINFO_SET )
local URLENCODED_WHITELIST = percent_whitelist( "^" .. URLENCODED_SET )

-- `encodeURI` and `encodeURIComponent` from ECMAScript
local URI_WHITELIST = percent_whitelist( "%w;,/?:@&=+$%-_.!~*'()#" )
local URI_COMPONENT_WHITELIST = percent_whitelist( "%w%-_.!~*'()" )

-- escapes of these bytes are kept as is by `decodeURI`
local URI_RESERVED_BYTES = string.byteMap(
    ";", "/", "?", ":", "@", "&", "=", "+", "$", ",", "#"
)

-- UTS #46 mapping of the characters that are ignored or are full stops
local IDNA_MAPPING = {
    [ "\xC2\xAD" ] = "",      -- U+00AD soft hyphen
    [ "\xE2\x80\x8B" ] = "",  -- U+200B zero width space
    [ "\xE2\x81\xA0" ] = "",  -- U+2060 word joiner
    [ "\xEF\xBB\xBF" ] = "",  -- U+FEFF zero width no-break space
    [ "\xE3\x80\x82" ] = ".", -- U+3002 ideographic full stop
    [ "\xEF\xBC\x8E" ] = ".", -- U+FF0E fullwidth full stop
    [ "\xEF\xBD\xA1" ] = "."  -- U+FF61 halfwidth ideographic full stop
}

---@param str string
---@param str_length integer
---@return boolean
local function is_single_dot( str, str_length )
    if str_length == 1 then
        return string_byte( str, 1, 1 ) == 0x2E --[[ . ]]
    elseif str_length == 3 then
        return string_lower( str ) == "%2e"
    end

    return false
end

---@param str string
---@param str_length integer
---@return boolean
local function is_double_dot( str, str_length )
    if str_length == 2 then
        local uint8_1, uint8_2 = string_byte( str, 1, 2 )
        return uint8_1 == 0x2E --[[ . ]] and uint8_2 == 0x2E --[[ . ]]
    elseif str_length == 4 then
        str = string_lower( str )
        return str == "%2e." or str == ".%2e"
    elseif str_length == 6 then
        return string_lower( str ) == "%2e%2e"
    end

    return false
end

---@param uint8_1 integer | nil
---@param uint8_2 integer | nil
---@param normalized boolean
---@return boolean
local function is_windows_drive_letter_bytes( uint8_1, uint8_2, normalized )
    return uint8_1 ~= nil and ascii_isAlpha( uint8_1 ) and (uint8_2 == 0x3A --[[ : ]] or (not normalized and uint8_2 == 0x7C --[[ | ]]))
end

---@param str string | nil
---@param normalized boolean
---@return boolean
local function is_windows_drive_letter( str, normalized )
    ---@cast str string
    return isString( str ) and string_len( str ) == 2 and is_windows_drive_letter_bytes( string_byte( str, 1, 1 ), string_byte( str, 2, 2 ), normalized )
end

---@param str string
---@param start_position integer
---@param end_position integer
---@return boolean
local function starts_with_windows_drive_letter( str, start_position, end_position )
    local length = (end_position - start_position) + 1
    if length < 2 then
        return false
    end

    local uint8_1, uint8_2, uint8_3 = string_byte( str, start_position, start_position + 2 )
    return is_windows_drive_letter_bytes( uint8_1, uint8_2, false ) and (length == 2 or FILE_OTHERWISE_BYTES[ uint8_3 ] == true)
end

-- returns the position of the nearest byte above the space, walking from start to end
---@param str string
---@param start_position integer
---@param end_position integer
---@return integer
local function trim_input( str, start_position, end_position )
    for position = start_position, end_position, (start_position < end_position) and 1 or -1 do
        local uint8 = string_byte( str, position, position )
        if uint8 == nil or uint8 > 0x20 --[[ space ]] then
            return position
        end
    end

    return end_position - 1
end

---@param str string
---@param position integer
---@param end_position integer
---@param address integer[]
---@param piece_index integer
---@return integer piece_index
local function parse_ipv4_in_ipv6( str, position, end_position, address, piece_index )
    local numbers_seen = 0

    while position <= end_position do
        ---@type integer | nil
        local ipv4_piece = nil

        ---@type integer | nil
        local uint8 = string_byte( str, position, position )

        if numbers_seen > 0 then
            if not (uint8 == 0x2E --[[ . ]] and numbers_seen < 4) then
                error( "Invalid URL: IPv4 in IPv6 invalid code point" )
            end

            position = position + 1
            uint8 = position <= end_position and string_byte( str, position, position ) or nil
        end

        while uint8 ~= nil and ascii_isDigit( uint8 ) do
            local number = ascii_toInteger( uint8 )

            if ipv4_piece == nil then
                ipv4_piece = number
            elseif ipv4_piece == 0 then
                error( "Invalid URL: IPv4 in IPv6 invalid code point" )
            else
                ipv4_piece = ipv4_piece * 10 + number
            end

            if ipv4_piece > 255 then
                error( "Invalid URL: IPv4 in IPv6 out of range part" )
            end

            position = position + 1
            uint8 = position <= end_position and string_byte( str, position, position ) or nil
        end

        if ipv4_piece == nil then
            error( "Invalid URL: IPv4 in IPv6 invalid code point" )
        end

        address[ piece_index ] = address[ piece_index ] * 0x100 + ipv4_piece
        numbers_seen = numbers_seen + 1

        if numbers_seen == 2 or numbers_seen == 4 then
            piece_index = piece_index + 1
        end
    end

    if numbers_seen ~= 4 then
        error( "Invalid URL: IPv4 in IPv6 too few parts" )
    end

    return piece_index
end

---@param str string
---@param start_position integer
---@param end_position integer
---@return dreamwork.std.IPv6
local function parse_ipv6( str, start_position, end_position )
    local address = { 0, 0, 0, 0, 0, 0, 0, 0 }
    local position = start_position
    local piece_index = 1

    ---@type integer | nil
    local compress = nil

    if string_byte( str, start_position, start_position ) == 0x3A --[[ : ]] then
        if start_position == end_position or string_byte( str, start_position + 1, start_position + 1 ) ~= 0x3A --[[ : ]] then
            error( "Invalid URL: IPv6 invalid compression" )
        end

        position = position + 2
        piece_index = 2
        compress = 2
    end

    while position <= end_position do
        if piece_index == 9 then
            error( "Invalid URL: IPv6 too many pieces" )
        end

        ---@type integer | nil
        local uint8 = string_byte( str, position, position )

        if uint8 == 0x3A --[[ : ]] then
            if compress ~= nil then
                error( "Invalid URL: IPv6 multiple compression" )
            end

            position = position + 1
            piece_index = piece_index + 1
            compress = piece_index
        else
            local value, length = 0, 0

            while length < 4 and uint8 ~= nil and ascii_isHexDigit( uint8 ) do
                value = value * 0x10 + ascii_toInteger( uint8 )

                position = position + 1
                length = length + 1

                uint8 = position <= end_position and string_byte( str, position, position ) or nil
            end

            if uint8 == 0x2E --[[ . ]] then
                if length == 0 then
                    error( "Invalid URL: IPv4 in IPv6 invalid code point" )
                end

                position = position - length

                if piece_index > 7 then
                    error( "Invalid URL: IPv4 in IPv6 too many pieces" )
                end

                piece_index = parse_ipv4_in_ipv6( str, position, end_position, address, piece_index )
                break
            elseif uint8 == 0x3A --[[ : ]] then
                position = position + 1

                if position > end_position then
                    error( "Invalid URL: IPv6 invalid code point" )
                end
            elseif position <= end_position then
                error( "Invalid URL: IPv6 invalid code point" )
            end

            address[ piece_index ] = value
            piece_index = piece_index + 1
        end
    end

    if compress ~= nil then
        local swaps = piece_index - compress
        piece_index = 8

        while piece_index ~= 1 and swaps > 0 do
            local swap_index = compress + swaps - 1
            address[ piece_index ], address[ swap_index ] = address[ swap_index ], address[ piece_index ]

            swaps = swaps - 1
            piece_index = piece_index - 1
        end
    elseif piece_index ~= 9 then
        error( "Invalid URL: IPv6 too few pieces" )
    end

    return IPv6( table_unpack( address, 1, 8 ) )
end

-- checks if the last label of a domain is a number, so the domain must be parsed as IPv4
---@param str string
---@param start_position integer
---@param end_position integer
---@return boolean
local function ends_in_a_number( str, start_position, end_position )
    local number_start, number_end = start_position, end_position

    for position = end_position, start_position, -1 do
        if string_byte( str, position, position ) == 0x2E --[[ . ]] then
            if position == end_position then
                number_end = position - 1
            else
                number_start = position + 1
                break
            end
        end
    end

    for position = number_start, number_end, 1 do
        if not ascii_isDigit( string_byte( str, position, position ) ) then
            -- it still can be a hex number
            local uint8_1, uint8_2 = string_byte( str, number_start, number_start + 1 )
            if not (uint8_1 == 0x30 --[[ 0 ]] and (uint8_2 == 0x78 --[[ x ]] or uint8_2 == 0x58 --[[ X ]])) then
                return false
            end

            for hex_position = number_start + 2, number_end, 1 do
                if not ascii_isHexDigit( string_byte( str, hex_position, hex_position ) ) then
                    return false
                end
            end

            return true
        end
    end

    return number_start <= number_end
end

-- parses one part of an IPv4 address: decimal, octal with a leading "0" or hex with "0x"
---@param str string
---@param start_position integer
---@param end_position integer
---@return integer
local function parse_ipv4_number( str, start_position, end_position )
    if start_position > end_position then
        error( "Invalid URL: IPv4 empty part" )
    end

    local radix = 10

    local uint8_1, uint8_2 = string_byte( str, start_position, start_position + 1 )
    if uint8_1 == 0x30 --[[ 0 ]] and (uint8_2 == 0x78 --[[ x ]] or uint8_2 == 0x58 --[[ X ]]) then
        radix = 16
        start_position = start_position + 2
    elseif uint8_1 == 0x30 --[[ 0 ]] and start_position ~= end_position then
        radix = 8
        start_position = start_position + 1
    end

    local number = 0

    for position = start_position, end_position, 1 do
        local digit = ascii_toInteger( string_byte( str, position, position ) )
        if digit == nil or digit >= radix then
            error( "Invalid URL: IPv4 invalid number" )
        end

        number = number * radix + digit
    end

    return number
end

-- parses an IPv4 address the way the URL standard does, e.g. `127.1`, `0x7f000001` or `2130706433`
---@param str string
---@param start_position integer
---@param end_position integer
---@return dreamwork.std.IPv4
local function parse_ipv4( str, start_position, end_position )
    ---@type integer[]
    local numbers = {}
    local number_count = 0

    local part_start = start_position

    for position = start_position, end_position + 1, 1 do
        if position > end_position or string_byte( str, position, position ) == 0x2E --[[ . ]] then
            if number_count == 4 then
                error( "Invalid URL: IPv4 too many parts" )
            end

            number_count = number_count + 1
            numbers[ number_count ] = parse_ipv4_number( str, part_start, position - 1 )
            part_start = position + 1
        end
    end

    -- every part but the last is a single byte, the last one fills the remaining bytes
    local address = 0

    for index = 1, number_count - 1, 1 do
        local number = numbers[ index ]
        if number > 255 then
            error( "Invalid URL: IPv4 out of range part" )
        end

        address = address + number * 256 ^ (4 - index)
    end

    local last_number = numbers[ number_count ]
    if last_number >= 256 ^ (5 - number_count) then
        error( "Invalid URL: IPv4 out of range part" )
    end

    return address + last_number
end

-- code points that are never valid in a domain
---@param codepoint integer
---@return boolean
local function is_idna_disallowed( codepoint )
    return (codepoint >= 0x80 and codepoint <= 0x9F) or codepoint == 0xFFFD or unicode_isSurrogate( codepoint ) or unicode_isNoncharacter( codepoint )
end

-- a part of the UTS #46 mapping: ignored characters, full stops,
-- fullwidth forms and mathematical letters and digits
---@param char string
---@return string | nil
local function idna_map( char )
    local mapped = IDNA_MAPPING[ char ]
    if mapped ~= nil then
        return mapped
    end

    local codepoint = utf8_codepoint( char, 1, -1, true )

    if is_idna_disallowed( codepoint ) then
        error( "Invalid URL: Domain invalid code point" )
    elseif codepoint >= 0xFF01 and codepoint <= 0xFF5E then
        -- fullwidth ASCII
        return string_char( codepoint - 0xFEE0 )
    elseif codepoint == 0x3000 then
        -- ideographic space
        return " "
    elseif codepoint >= 0x1D400 and codepoint <= 0x1D6A3 then
        -- mathematical latin letters, 26 uppercase and 26 lowercase per style
        return string_char( 0x61 + ((codepoint - 0x1D400) % 52) % 26 )
    elseif codepoint >= 0x1D7CE and codepoint <= 0x1D7FF then
        -- mathematical digits
        return string_char( 0x30 + (codepoint - 0x1D7CE) % 10 )
    end

    return nil
end

-- code points that the mapping would change, so they can't appear in a decoded punycode label
---@param codepoint integer
---@return boolean
local function is_idna_mapped( codepoint )
    if codepoint < 0x80 then
        return ascii_isUpper( codepoint )
    end

    if (codepoint >= 0x2460 and codepoint <= 0x24FF) or (codepoint >= 0x3200 and codepoint <= 0x33FF) then
        -- enclosed alphanumerics and CJK letters, mapped to their contents
        return true
    end

    local char = utf8_char( codepoint )
    return IDNA_MAPPING[ char ] ~= nil or idna_map( char ) ~= nil or unicode_lower( char ) ~= char
end

-- labels with the "xn--" prefix must be punycode of a valid non-ASCII label
---@param domain string
local function validate_punycode_labels( domain )
    local labels, label_count = string_byteSplit( domain, 0x2E --[[ . ]] )

    for index = 1, label_count, 1 do
        local label = labels[ index ]
        if string_sub( label, 1, 4 ) == "xn--" then
            local codepoints, codepoint_count = punycode_unpack( label )
            if codepoints == nil or codepoint_count == 0 then
                error( "Invalid URL: Domain invalid punycode" )
            end

            local has_non_ascii = false

            for codepoint_index = 1, codepoint_count, 1 do
                local codepoint = codepoints[ codepoint_index ]
                if is_idna_disallowed( codepoint ) or is_idna_mapped( codepoint ) then
                    error( "Invalid URL: Domain invalid punycode" )
                end

                if codepoint >= 0x80 then
                    has_non_ascii = true
                end
            end

            if not has_non_ascii then
                error( "Invalid URL: Domain invalid punycode" )
            end
        end
    end
end

---@param domain string
---@return string ascii_domain
local function domain_to_ascii( domain )
    if not string_containsBytes( domain, NON_ASCII_BYTES ) then
        domain = string_lower( domain )
        validate_punycode_labels( domain )
        return domain
    end

    domain = unicode_lower( (string_gsub( domain, "[\xC2-\xF4][\x80-\xBF]+", idna_map )) )

    -- labels that already are punycode can't contain non-ASCII characters
    if string_find( "." .. domain, "%.xn%-%-[^.]*[\128-\255]" ) ~= nil then
        error( "Invalid URL: Domain invalid code point" )
    end

    local ascii_domain, err_msg = punycode_encode( domain )
    if ascii_domain == nil then
        error( "Invalid URL: " .. tostring( err_msg ) )
    end

    validate_punycode_labels( ascii_domain )
    return ascii_domain
end

---@param str string
---@param start_position integer
---@param end_position integer
---@param is_special integer | boolean | nil
---@return string | dreamwork.std.IPv4 | dreamwork.std.IPv6
local function parse_host_string( str, start_position, end_position, is_special )
    if string_byte( str, start_position, start_position ) == 0x5B --[[ [ ]] then
        if string_byte( str, end_position, end_position ) ~= 0x5D --[[ ] ]] then
            error( "Invalid URL: IPv6 unclosed" )
        end

        return parse_ipv6( str, start_position + 1, end_position - 1 )
    end

    if not is_special then
        -- opaque host
        if string_containsBytes( str, FORBIDDEN_HOST_BYTES, start_position, end_position ) then
            error( "Invalid URL: Host invalid code point" )
        end

        return percent_encode( string_sub( str, start_position, end_position ), C0_CONTROL_WHITELIST, true )
    end

    local ascii_domain = domain_to_ascii( percent_decode( string_sub( str, start_position, end_position ), true ) )
    if ascii_domain == "" then
        error( "Invalid URL: Missing host" )
    end

    if string_containsBytes( ascii_domain, FORBIDDEN_DOMAIN_BYTES ) then
        error( "Invalid URL: Domain invalid code point" )
    end

    local ascii_domain_length = string_len( ascii_domain )

    if ends_in_a_number( ascii_domain, 1, ascii_domain_length ) then
        -- one trailing dot is allowed, other empty parts are not
        if string_byte( ascii_domain, ascii_domain_length, ascii_domain_length ) == 0x2E --[[ . ]] then
            ascii_domain_length = ascii_domain_length - 1
        end

        return parse_ipv4( ascii_domain, 1, ascii_domain_length )
    end

    return ascii_domain
end

---@param host string | dreamwork.std.IPv4 | dreamwork.std.IPv6 | nil
---@return string | nil
local function serialize_host( host )
    if isNumber( host ) then
        ---@cast host dreamwork.std.IPv4
        return ipv4_toString( host )
    elseif isTable( host ) then
        ---@cast host dreamwork.std.IPv6
        return "[" .. host:toString() .. "]"
    end

    ---@cast host string | nil
    return host
end

---@param state dreamwork.std.URL.State
---@return integer | boolean | nil
local function get_special( state )
    local scheme = state.scheme
    return scheme ~= nil and SPECIAL_SCHEMES[ scheme ] or nil
end

-- predefine locals so functions can be written in the same order as the states in the specification
local parse_scheme, parse_no_scheme, parse_special_relative_or_authority, parse_path_or_authority
local parse_relative, parse_relative_slash, parse_special_authority_ignore_slashes, parse_authority
local parse_host, parse_port, parse_file, parse_file_slash, parse_file_host
local parse_path_start, parse_path, parse_opaque_path, parse_query, parse_fragment

function parse_scheme( state, str, start_position, end_position, base, state_override )
    -- scheme start state
    if start_position <= end_position and ascii_isAlpha( string_byte( str, start_position, start_position ) ) then
        -- scheme state
        local lowercase = false

        for position = start_position, end_position, 1 do
            local uint8 = string_byte( str, position, position )
            if uint8 == 0x3A --[[ : ]] then
                local scheme = string_sub( str, start_position, position - 1 )
                if lowercase then
                    scheme = string_lower( scheme )
                end

                local is_special = SPECIAL_SCHEMES[ scheme ]

                if state_override then
                    local is_url_special = get_special( state )
                    if (is_url_special ~= nil) ~= (is_special ~= nil) then
                        return
                    end

                    if (state.username ~= nil or state.password ~= nil or state.port ~= nil) and is_special == true then
                        return
                    end

                    if is_url_special == true and state.hostname == "" then
                        return
                    end
                end

                state.scheme = scheme

                if state_override then
                    if state.port == is_special then
                        state.port = nil
                    end
                elseif is_special == true then
                    -- file state
                    parse_file( state, str, position + 1, end_position, base )
                elseif is_special ~= nil and base ~= nil and base.scheme == scheme then
                    -- special relative or authority state
                    parse_special_relative_or_authority( state, str, position + 1, end_position, base, is_special )
                elseif is_special ~= nil then
                    -- special authority slashes state
                    parse_special_authority_ignore_slashes( state, str, position + 1, end_position, is_special )
                elseif string_byte( str, position + 1, position + 1 ) == 0x2F --[[ / ]] then
                    -- path or authority state
                    parse_path_or_authority( state, str, position + 2, end_position )
                else
                    -- opaque path state
                    parse_opaque_path( state, str, position + 1, end_position )
                end

                return
            elseif ascii_isUpper( uint8 ) then
                lowercase = true
            elseif not (ascii_isLower( uint8 ) or ascii_isDigit( uint8 ) or uint8 == 0x2B --[[ + ]] or uint8 == 0x2D --[[ - ]] or uint8 == 0x2E --[[ . ]]) then
                -- not a scheme
                break
            end
        end
    end

    if not state_override then
        -- no scheme state
        return parse_no_scheme( state, str, start_position, end_position, base )
    end
end

function parse_no_scheme( state, str, start_position, end_position, base )
    local starts_with_fragment = string_byte( str, start_position, start_position ) == 0x23 --[[ # ]]
    local base_has_opaque_path = base ~= nil and isString( base.path )

    if base == nil or (base_has_opaque_path and not starts_with_fragment) then
        error( "Invalid URL: Missing scheme" )
    end

    if base_has_opaque_path then
        state.scheme = base.scheme
        state.path = base.path
        state.query = base.query
        return parse_fragment( state, str, start_position + 1, end_position )
    elseif base.scheme == "file" then
        state.scheme = "file"
        return parse_file( state, str, start_position, end_position, base )
    end

    return parse_relative( state, str, start_position, end_position, base, SPECIAL_SCHEMES[ base.scheme ] )
end

function parse_special_relative_or_authority( state, str, start_position, end_position, base, is_special )
    local uint8_1, uint8_2 = string_byte( str, start_position, start_position + 1 )
    if uint8_1 == 0x2F --[[ / ]] and uint8_2 == 0x2F --[[ / ]] then
        -- special authority ignore slashes state
        return parse_special_authority_ignore_slashes( state, str, start_position + 2, end_position, is_special )
    end

    -- relative state
    return parse_relative( state, str, start_position, end_position, base, is_special )
end

function parse_path_or_authority( state, str, start_position, end_position )
    if string_byte( str, start_position, start_position ) == 0x2F --[[ / ]] then
        return parse_authority( state, str, start_position + 1, end_position )
    end

    return parse_path( state, str, start_position, end_position )
end

function parse_relative( state, str, start_position, end_position, base, is_special )
    state.scheme = base.scheme

    local uint8 = start_position <= end_position and string_byte( str, start_position, start_position ) or nil
    if uint8 == 0x2F --[[ / ]] or (is_special and uint8 == 0x5C --[[ \ ]]) then
        -- relative slash state
        return parse_relative_slash( state, str, start_position + 1, end_position, base, is_special )
    end

    state.username = base.username
    state.password = base.password
    state.hostname = base.hostname
    state.port = base.port

    local path = base.path and table_shallowCopy( base.path ) or {}
    state.path = path

    if uint8 == nil then
        state.query = base.query
    elseif uint8 == 0x3F --[[ ? ]] then
        return parse_query( state, str, start_position + 1, end_position, is_special )
    elseif uint8 == 0x23 --[[ # ]] then
        state.query = base.query
        return parse_fragment( state, str, start_position + 1, end_position )
    else
        local path_length = #path
        if path_length ~= 0 then
            path[ path_length ] = nil
        end

        return parse_path( state, str, start_position, end_position, is_special, path )
    end
end

function parse_relative_slash( state, str, start_position, end_position, base, is_special )
    local uint8 = string_byte( str, start_position, start_position )
    if is_special and (uint8 == 0x2F --[[ / ]] or uint8 == 0x5C --[[ \ ]]) then
        -- special authority ignore slashes state
        return parse_special_authority_ignore_slashes( state, str, start_position + 1, end_position, is_special )
    elseif uint8 == 0x2F --[[ / ]] then
        -- authority state
        return parse_authority( state, str, start_position + 1, end_position, is_special )
    else
        state.username = base.username
        state.password = base.password
        state.hostname = base.hostname
        state.port = base.port
        return parse_path( state, str, start_position, end_position, is_special )
    end
end

function parse_special_authority_ignore_slashes( state, str, start_position, end_position, is_special )
    for position = start_position, end_position, 1 do
        local uint8 = string_byte( str, position, position )
        if uint8 ~= 0x2F --[[ / ]] and uint8 ~= 0x5C --[[ \ ]] then
            return parse_authority( state, str, position, end_position, is_special )
        end
    end

    error( "Invalid URL: Missing host" )
end

function parse_authority( state, str, start_position, end_position, is_special )
    local path_end_position = end_position

    ---@type integer | nil
    local at_sign_position = nil

    ---@type integer | nil
    local password_token_position = nil

    for position = start_position, end_position, 1 do
        local uint8 = string_byte( str, position, position )
        if uint8 == 0x2F --[[ / ]] or uint8 == 0x3F --[[ ? ]] or uint8 == 0x23 --[[ # ]] or (is_special and uint8 == 0x5C --[[ \ ]]) then
            end_position = position - 1
            break
        elseif uint8 == 0x40 --[[ @ ]] then
            at_sign_position = position
        elseif uint8 == 0x3A --[[ : ]] and password_token_position == nil then
            password_token_position = position
        end
    end

    if at_sign_position ~= nil then
        -- credentials are everything before the last "@", a ":" after it belongs to the port
        if password_token_position ~= nil and password_token_position > at_sign_position then
            password_token_position = nil
        end

        -- after @ there is no hostname
        if at_sign_position == end_position then
            error( "Invalid URL: Missing host" )
        end

        if password_token_position == nil then
            state.username = percent_encode( string_sub( str, start_position, at_sign_position - 1 ), USERINFO_WHITELIST, true )
        else
            state.username = percent_encode( string_sub( str, start_position, password_token_position - 1 ), USERINFO_WHITELIST, true )
            state.password = percent_encode( string_sub( str, password_token_position + 1, at_sign_position - 1 ), USERINFO_WHITELIST, true )
        end

        start_position = at_sign_position + 1
    end

    parse_host( state, str, start_position, end_position, is_special )
    return parse_path_start( state, str, end_position + 1, path_end_position, is_special )
end

function parse_host( state, str, start_position, end_position, is_special, state_override )
    if state_override and is_special == true then
        return parse_file_host( state, str, start_position, end_position, state_override )
    end

    local inside_brackets = false

    for position = start_position, end_position, 1 do
        local uint8 = string_byte( str, position, position )
        if uint8 == 0x3A --[[ : ]] and not inside_brackets then
            if position == start_position then
                error( "Invalid URL: Missing host" )
            end

            if state_override == "hostname" then
                return
            end

            parse_port( state, str, position + 1, end_position, is_special, state_override )
            end_position = position - 1
            break
        elseif uint8 == 0x5B --[[ [ ]] then
            inside_brackets = true
        elseif uint8 == 0x5D --[[ ] ]] then
            inside_brackets = false
        end
    end

    if start_position > end_position then
        if is_special then
            error( "Invalid URL: Missing host" )
        elseif state_override and (state.username ~= nil or state.password ~= nil or state.port ~= nil) then
            return
        end

        state.hostname = ""
        return
    end

    state.hostname = parse_host_string( str, start_position, end_position, is_special )
end

function parse_port( state, str, start_position, end_position, default_port, state_override )
    if start_position > end_position then
        return
    end

    local port, digit_count = 0, 0

    for position = start_position, end_position, 1 do
        local uint8 = string_byte( str, position, position )
        if not ascii_isDigit( uint8 ) then
            -- setters use the leading digits only
            if not state_override then
                error( "Invalid URL: Invalid port" )
            end

            break
        end

        port = port * 10 + ascii_toInteger( uint8 )
        digit_count = digit_count + 1
    end

    if digit_count == 0 then
        return
    end

    if port > 0xFFFF then
        if state_override then
            return
        end

        error( "Invalid URL: Invalid port" )
    end

    if port == default_port then
        state.port = nil
    else
        state.port = port
    end
end

function parse_file( state, str, start_position, end_position, base )
    state.scheme = "file"
    state.hostname = ""

    local uint8 = start_position <= end_position and string_byte( str, start_position, start_position ) or nil
    if uint8 == 0x2F --[[ / ]] or uint8 == 0x5C --[[ \ ]] then
        return parse_file_slash( state, str, start_position + 1, end_position, base )
    end

    if base == nil or base.scheme ~= "file" then
        return parse_path( state, str, start_position, end_position, true )
    end

    state.hostname = base.hostname

    local path = base.path and table_shallowCopy( base.path ) or {}
    state.path = path

    if uint8 == nil then
        state.query = base.query
        return
    elseif uint8 == 0x3F --[[ ? ]] then
        return parse_query( state, str, start_position + 1, end_position, true )
    elseif uint8 == 0x23 --[[ # ]] then
        state.query = base.query
        return parse_fragment( state, str, start_position + 1, end_position )
    end

    if starts_with_windows_drive_letter( str, start_position, end_position ) then
        path = {}
    else
        local path_length = #path
        if path_length ~= 0 and not (path_length == 1 and is_windows_drive_letter( path[ 1 ], true )) then
            path[ path_length ] = nil
        end
    end

    return parse_path( state, str, start_position, end_position, true, path )
end

function parse_file_slash( state, str, start_position, end_position, base )
    local uint8 = string_byte( str, start_position, start_position )
    if uint8 == 0x2F --[[ / ]] or uint8 == 0x5C --[[ \ ]] then
        return parse_file_host( state, str, start_position + 1, end_position )
    end

    local path = {}

    if base ~= nil and base.scheme == "file" then
        state.hostname = base.hostname

        local base_path = base.path
        if isTable( base_path ) and not starts_with_windows_drive_letter( str, start_position, end_position ) and is_windows_drive_letter( base_path[ 1 ], true ) then
            path[ 1 ] = base_path[ 1 ]
        end
    end

    return parse_path( state, str, start_position, end_position, true, path )
end

function parse_file_host( state, str, start_position, end_position, state_override )
    local position = start_position

    while true do
        local uint8 = position <= end_position and string_byte( str, position, position ) or nil
        if uint8 == nil or uint8 == 0x2F --[[ / ]] or uint8 == 0x5C --[[ \ ]] or uint8 == 0x3F --[[ ? ]] or uint8 == 0x23 --[[ # ]] then
            local host_length = position - start_position

            if not state_override and host_length == 2 and is_windows_drive_letter_bytes( string_byte( str, start_position, start_position ), string_byte( str, start_position + 1, start_position + 1 ), false ) then
                return parse_path( state, str, start_position, end_position, true )
            end

            if host_length == 0 then
                state.hostname = ""
            else
                local hostname = parse_host_string( str, start_position, position - 1, true )
                if hostname == "localhost" then
                    hostname = ""
                end

                state.hostname = hostname
            end

            if state_override then
                return
            end

            return parse_path_start( state, str, position, end_position, true )
        end

        position = position + 1
    end
end

function parse_path_start( state, str, start_position, end_position, is_special, state_override )
    local uint8 = start_position <= end_position and string_byte( str, start_position, start_position ) or nil

    if is_special then
        if uint8 == 0x2F --[[ / ]] or uint8 == 0x5C --[[ \ ]] then
            start_position = start_position + 1
        end

        return parse_path( state, str, start_position, end_position, is_special, nil, state_override )
    elseif not state_override and uint8 == 0x3F --[[ ? ]] then
        return parse_query( state, str, start_position + 1, end_position, is_special )
    elseif not state_override and uint8 == 0x23 --[[ # ]] then
        return parse_fragment( state, str, start_position + 1, end_position )
    elseif uint8 ~= nil then
        if uint8 == 0x2F --[[ / ]] then
            start_position = start_position + 1
        end

        return parse_path( state, str, start_position, end_position, is_special, nil, state_override )
    elseif state_override and state.hostname == nil then
        local path = state.path
        path[ #path + 1 ] = ""
    end
end

function parse_path( state, str, start_position, end_position, is_special, segments, state_override )
    if segments == nil then
        segments = {}
    end

    local segment_count = #segments
    local has_windows_letter = is_special == true and segment_count ~= 0 and is_windows_drive_letter( segments[ 1 ], true )
    local segment_start = start_position
    local position = start_position

    while true do
        local uint8 = position <= end_position and string_byte( str, position, position ) or nil
        local is_slash = uint8 == 0x2F --[[ / ]] or (is_special and uint8 == 0x5C --[[ \ ]])

        if uint8 == nil or is_slash or (not state_override and (uint8 == 0x3F --[[ ? ]] or uint8 == 0x23 --[[ # ]])) then
            local segment = percent_encode( string_sub( str, segment_start, position - 1 ), PATH_WHITELIST, true )
            local segment_length = string_len( segment )
            segment_start = position + 1

            if is_double_dot( segment, segment_length ) then
                -- shorten the path, a lone windows drive letter stays
                if segment_count ~= 0 and not (segment_count == 1 and has_windows_letter) then
                    segments[ segment_count ] = nil
                    segment_count = segment_count - 1
                end

                if not is_slash then
                    segment_count = segment_count + 1
                    segments[ segment_count ] = ""
                end
            elseif is_single_dot( segment, segment_length ) then
                if not is_slash then
                    segment_count = segment_count + 1
                    segments[ segment_count ] = ""
                end
            else
                if is_special == true and segment_count == 0 and is_windows_drive_letter( segment, false ) then
                    segment = string_sub( segment, 1, 1 ) .. ":"
                    has_windows_letter = true
                end

                segment_count = segment_count + 1
                segments[ segment_count ] = segment
            end

            if uint8 == nil then
                break
            elseif not is_slash then
                if uint8 == 0x3F --[[ ? ]] then
                    parse_query( state, str, position + 1, end_position, is_special )
                else
                    parse_fragment( state, str, position + 1, end_position )
                end

                break
            end
        end

        position = position + 1
    end

    state.path = segments
end

function parse_opaque_path( state, str, start_position, end_position )
    for position = start_position, end_position, 1 do
        local uint8 = string_byte( str, position, position )
        if uint8 == 0x3F --[[ ? ]] then
            parse_query( state, str, position + 1, end_position )
            end_position = position - 1
            break
        elseif uint8 == 0x23 --[[ # ]] then
            parse_fragment( state, str, position + 1, end_position )
            end_position = position - 1
            break
        end
    end

    state.path = percent_encode( string_sub( str, start_position, end_position ), C0_CONTROL_WHITELIST, true )
end

function parse_query( state, str, start_position, end_position, is_special, state_override )
    if not state_override then
        local fragment_position = string_findByte( str, 0x23 --[[ # ]], start_position, end_position )
        if fragment_position ~= nil then
            parse_fragment( state, str, fragment_position + 1, end_position )
            end_position = fragment_position - 1
        end
    end

    state.query = percent_encode( string_sub( str, start_position, end_position ), is_special and SPECIAL_QUERY_WHITELIST or QUERY_WHITELIST, true )
end

function parse_fragment( state, str, start_position, end_position )
    state.fragment = percent_encode( string_sub( str, start_position, end_position ), FRAGMENT_WHITELIST, true )
end

---@param state table
---@param str string
---@param base string | dreamwork.std.URL | dreamwork.std.URL.State | nil
---@return dreamwork.std.URL.State
local function parse( state, str, base )
    if not isString( str ) then
        error( "Invalid URL: URL must be a string" )
    end

    if isString( base ) then
        ---@cast base string
        base = parse( {}, base )
    elseif isURL( base ) then
        ---@cast base dreamwork.std.URL
        base = raw_get( base, "state" )
    end

    str = string_gsub( str, "[\t\n\r]", "" )

    -- trim leading and trailing C0 controls and spaces
    local start_position = trim_input( str, 1, string_len( str ) )
    local end_position = trim_input( str, string_len( str ), start_position )

    parse_scheme( state, str, start_position, end_position, base )

    return state
end

-- parses application/x-www-form-urlencoded string into a list of name-value pairs
---@param str string
---@param search_params dreamwork.std.URL.SearchParams
local function parse_query_string( str, search_params )
    local segments, segment_count = string_byteSplit( str, 0x26 --[[ & ]] )
    local pair_count = 0

    for index = 1, segment_count, 1 do
        local segment = segments[ index ]
        if segment ~= "" then
            pair_count = pair_count + 1

            local equals_position = string_findByte( segment, 0x3D --[[ = ]] )
            if equals_position == nil then
                search_params[ pair_count ] = { percent_decode( segment ), "" }
            else
                search_params[ pair_count ] = {
                    percent_decode( string_sub( segment, 1, equals_position - 1 ) ),
                    percent_decode( string_sub( segment, equals_position + 1 ) )
                }
            end
        end
    end
end

---@param query string | dreamwork.std.URL.SearchParams | nil
---@return string | nil
local function serialize_query( query )
    if debug_getmetatable( query ) ~= SearchParams then
        ---@cast query string | nil
        return query
    end

    ---@cast query dreamwork.std.URL.SearchParams

    local segments, segment_count = {}, 0

    for index = 1, #query, 1 do
        local pair = query[ index ]
        local name, value = pair[ 1 ], pair[ 2 ]

        segment_count = segment_count + 1
        segments[ segment_count ] = (name and percent_encode( name, URLENCODED_WHITELIST ) or "") .. "=" .. (value and percent_encode( value, URLENCODED_WHITELIST ) or "")
    end

    return table_concat( segments, "&", 1, segment_count )
end

--- [SHARED AND MENU]
---
--- Serializes a URL state, as returned by `URL.parse`, into a URL string.
---
--- Gives the same result as `url.href`.
---
--- ```lua
--- local state = std.URL.parse( "HTTP://Example.com:80/a?b#c" )
--- std.URL.serialize( state )       -- "http://example.com/a?b#c"
--- std.URL.serialize( state, true ) -- "http://example.com/a?b"
--- ```
---
---@param state dreamwork.std.URL.State The URL state to serialize.
---@param exclude_fragment? boolean If `true`, the fragment is left out, defaults to `false`.
---@return string url_str The serialized URL.
---@nodiscard
local function serialize( state, exclude_fragment )
    local hostname = state.hostname
    local path = state.path
    local is_opaque = isString( path )

    local segments, segment_count = {}, 0

    local scheme = state.scheme
    if scheme ~= nil then
        segment_count = segment_count + 1
        segments[ segment_count ] = scheme .. ":"
    end

    if hostname ~= nil then
        segment_count = segment_count + 1
        segments[ segment_count ] = "//"

        local username, password = state.username, state.password
        if (username ~= nil and username ~= "") or (password ~= nil and password ~= "") then
            segment_count = segment_count + 1
            segments[ segment_count ] = username or ""

            if password ~= nil and password ~= "" then
                segment_count = segment_count + 1
                segments[ segment_count ] = ":" .. password
            end

            segment_count = segment_count + 1
            segments[ segment_count ] = "@"
        end

        segment_count = segment_count + 1
        segments[ segment_count ] = serialize_host( hostname )

        local port = state.port
        if port ~= nil then
            segment_count = segment_count + 1
            segments[ segment_count ] = ":" .. tostring( port )
        end
    elseif path ~= nil and not is_opaque and #path > 1 and path[ 1 ] == "" then
        -- keeps "//" at the start of the path from being read as an authority
        segment_count = segment_count + 1
        segments[ segment_count ] = "/."
    end

    if path ~= nil then
        segment_count = segment_count + 1

        if is_opaque then
            ---@cast path string
            segments[ segment_count ] = path
        elseif #path ~= 0 then
            ---@cast path string[]
            segments[ segment_count ] = "/" .. table_concat( path, "/" )
        else
            segments[ segment_count ] = ""
        end
    end

    -- an empty query still keeps its "?"
    local query = serialize_query( state.query )
    if query ~= nil then
        segment_count = segment_count + 1
        segments[ segment_count ] = "?" .. query
    end

    local fragment = state.fragment
    if fragment ~= nil and exclude_fragment ~= true then
        segment_count = segment_count + 1
        segments[ segment_count ] = "#" .. fragment
    end

    return table_concat( segments, "", 1, segment_count )
end

---@param state dreamwork.std.URL.State
---@return string | nil scheme
---@return string | dreamwork.std.IPv4 | dreamwork.std.IPv6 | nil hostname
---@return integer | nil port
local function get_origin( state )
    local scheme = state.scheme
    if scheme == "ftp" or scheme == "http" or scheme == "https" or scheme == "ws" or scheme == "wss" then
        return scheme, state.hostname, state.port
    elseif scheme == "blob" then
        local path = state.path
        if isString( path ) then
            local success, inner_state = pcall( parse, {}, path )
            if success and (inner_state.scheme == "http" or inner_state.scheme == "https") then
                return get_origin( inner_state )
            end
        end
    end
end

---@param state dreamwork.std.URL.State
---@return string | nil
local function serialize_origin( state )
    local scheme, hostname, port = get_origin( state )
    if scheme == nil then
        return nil
    end

    local origin = scheme .. "://" .. serialize_host( hostname )

    if port ~= nil then
        origin = origin .. ":" .. port
    end

    return origin
end

---@type table<string, boolean>
local STATE_FIELDS = {
    scheme = true,
    username = true,
    password = true,
    hostname = true,
    port = true,
    path = true,
    query = true,
    fragment = true
}

---@param url dreamwork.std.URL
local function reset_cache( url )
    raw_set( url, "_href", nil )
    raw_set( url, "_origin", nil )
    raw_set( url, "_host", nil )
    raw_set( url, "_hostname", nil )
    raw_set( url, "_pathname", nil )
    raw_set( url, "_query", nil )
end

---@generic V
---@param url dreamwork.std.URL
---@param key string
---@param value V
---@return V
local function cache_value( url, key, value )
    raw_set( url, key, value )
    return value
end

---@param search_params dreamwork.std.URL.SearchParams
local function update( search_params )
    local url = search_params.url
    if url == nil then
        return
    end

    local query = serialize_query( search_params )
    if query == "" then
        query = nil
    end

    raw_get( url, "state" ).query = query
    reset_cache( url )
end

-- re-reads `url.searchParams` after the query of the URL was replaced
---@param url dreamwork.std.URL
local function refresh_search_params( url )
    local search_params = raw_get( url, "_search_params" )
    if search_params == nil then
        return
    end

    for index = #search_params, 1, -1 do
        search_params[ index ] = nil
    end

    local query = raw_get( url, "state" ).query
    if query ~= nil then
        parse_query_string( query, search_params )
    end
end

---@param query string | { [ 1 ]: string, [ 2 ]: string | nil }[] | nil
---@param url? dreamwork.std.URL
---@protected
function SearchParams:__init( query, url )
    self.url = url

    if isString( query ) then
        ---@cast query string

        -- the query of a URL is used as is, it has no leading "?" to skip
        if url == nil and string_byte( query, 1, 1 ) == 0x3F --[[ ? ]] then
            query = string_sub( query, 2 )
        end

        parse_query_string( query, self )
    elseif isTable( query ) then
        ---@cast query { [ 1 ]: string, [ 2 ]: string | nil }[]

        for index = 1, #query, 1 do
            self[ index ] = query[ index ]
        end
    end
end

---@return string
---@protected
function SearchParams:__tostring()
    return serialize_query( self ) or ""
end

---@return string
---@protected
function SearchParams:__represent()
    return string_format( "URLSearchParams: %p [%s]", self, self )
end

--- [SHARED AND MENU]
---
--- Appends a name-value pair to the end of the list.
---
---@param name string The name of the parameter.
---@param value? string The value of the parameter, `nil` is the same as `""`.
function SearchParams:append( name, value )
    self[ #self + 1 ] = { name, value }
    update( self )
end

--- [SHARED AND MENU]
---
--- Removes every pair with the given name.
---
--- If `value` is given, only pairs with both the given name and value are removed.
---
---@param name string The name of the parameters to remove.
---@param value? string The value the removed pairs must have.
function SearchParams:delete( name, value )
    for index = #self, 1, -1 do
        local pair = self[ index ]
        if pair[ 1 ] == name and (value == nil or pair[ 2 ] == value) then
            table_remove( self, index )
        end
    end

    update( self )
end

--- [SHARED AND MENU]
---
--- Returns the value of the first pair with the given name.
---
---@param name string The name of the parameter.
---@return string | nil value The value, `nil` if there is no such pair.
---@nodiscard
function SearchParams:get( name )
    for index = 1, #self, 1 do
        local pair = self[ index ]
        if pair[ 1 ] == name then
            return pair[ 2 ]
        end
    end

    return nil
end

--- [SHARED AND MENU]
---
--- Returns the values of every pair with the given name, in order.
---
--- ```lua
--- std.URL.SearchParams( "a=1&b=2&a=3" ):getAll( "a" ) -- { "1", "3" }
--- ```
---
---@param name string The name of the parameters.
---@return string[] values The values, empty if there are no such pairs.
---@nodiscard
function SearchParams:getAll( name )
    local values, value_count = {}, 0

    for index = 1, #self, 1 do
        local pair = self[ index ]
        if pair[ 1 ] == name then
            value_count = value_count + 1
            values[ value_count ] = pair[ 2 ]
        end
    end

    return values
end

--- [SHARED AND MENU]
---
--- Checks if there is a pair with the given name.
---
--- If `value` is given, the pair must also have the given value.
---
---@param name string The name of the parameter.
---@param value? string The value the pair must have.
---@return boolean exists `true` if such a pair exists, otherwise `false`.
---@nodiscard
function SearchParams:has( name, value )
    for index = 1, #self, 1 do
        local pair = self[ index ]
        if pair[ 1 ] == name and (value == nil or pair[ 2 ] == value) then
            return true
        end
    end

    return false
end

--- [SHARED AND MENU]
---
--- Sets the value of the first pair with the given name and removes the other pairs with that name.
---
--- Appends a new pair if there is no pair with the given name.
---
--- ```lua
--- local params = std.URL.SearchParams( "a=1&b=2&a=3" )
--- params:set( "a", "9" )
--- tostring( params ) -- "a=9&b=2"
--- ```
---
---@param name string The name of the parameter.
---@param value? string The new value.
function SearchParams:set( name, value )
    for index = 1, #self, 1 do
        local pair = self[ index ]
        if pair[ 1 ] == name then
            pair[ 2 ] = value

            for other_index = #self, index + 1, -1 do
                if self[ other_index ][ 1 ] == name then
                    table_remove( self, other_index )
                end
            end

            update( self )
            return
        end
    end

    self[ #self + 1 ] = { name, value }
    update( self )
end

--- [SHARED AND MENU]
---
--- Sorts the pairs by name, pairs with the same name keep their relative order.
---
--- ```lua
--- local params = std.URL.SearchParams( "b=1&a=2&b=0" )
--- params:sort()
--- tostring( params ) -- "a=2&b=1&b=0"
--- ```
function SearchParams:sort()
    for index = 2, #self, 1 do
        local pair = self[ index ]
        local name = pair[ 1 ]

        local insert_index = index
        while insert_index > 1 and self[ insert_index - 1 ][ 1 ] > name do
            self[ insert_index ] = self[ insert_index - 1 ]
            insert_index = insert_index - 1
        end

        self[ insert_index ] = pair
    end

    update( self )
end

--- [SHARED AND MENU]
---
--- Returns an iterator over the name-value pairs.
---
--- ```lua
--- for name, value in url.searchParams:iterator() do
---     print( name, value )
--- end
--- ```
---
---@return fun(): string | nil, string | nil iterator The iterator function.
---@nodiscard
function SearchParams:iterator()
    local index = 0

    return function()
        index = index + 1

        local pair = self[ index ]
        if pair ~= nil then
            return pair[ 1 ], pair[ 2 ]
        end
    end
end

--- [SHARED AND MENU]
---
--- Returns an iterator over the names, names that repeat are returned every time.
---
---@return fun(): string | nil iterator The iterator function.
---@nodiscard
function SearchParams:keys()
    local index = 0

    return function()
        index = index + 1

        local pair = self[ index ]
        if pair ~= nil then
            return pair[ 1 ]
        end
    end
end

--- [SHARED AND MENU]
---
--- Returns an iterator over the values, a `nil` value gives `""`.
---
---@return fun(): string | nil iterator The iterator function.
---@nodiscard
function SearchParams:values()
    local index = 0

    return function()
        index = index + 1

        local pair = self[ index ]
        if pair ~= nil then
            return pair[ 2 ] or ""
        end
    end
end

---@param state dreamwork.std.URL.State
---@return boolean
local function cannot_have_credentials( state )
    local hostname = state.hostname
    return hostname == nil or hostname == "" or state.scheme == "file"
end

---@param key string
---@protected
function URL:__index( key )
    local state = raw_get( self, "state" )
    ---@cast state dreamwork.std.URL.State

    if STATE_FIELDS[ key ] then
        if key == "hostname" then
            return raw_get( self, "_hostname" ) or cache_value( self, "_hostname", serialize_host( state.hostname ) )
        elseif key == "query" then
            local cached = raw_get( self, "_query" )
            if cached ~= nil then
                return cached
            end

            return cache_value( self, "_query", serialize_query( state.query ) )
        end

        return state[ key ]
    end

    if key == "href" then
        return raw_get( self, "_href" ) or cache_value( self, "_href", serialize( state ) )
    elseif key == "origin" then
        return raw_get( self, "_origin" ) or cache_value( self, "_origin", serialize_origin( state ) )
    elseif key == "protocol" then
        local scheme = state.scheme
        if scheme ~= nil then
            return scheme .. ":"
        end
    elseif key == "host" then
        local cached = raw_get( self, "_host" )
        if cached ~= nil then
            return cached
        end

        if state.hostname == nil then
            return ""
        end

        local port = state.port
        if port == nil then
            return cache_value( self, "_host", self.hostname )
        end

        return cache_value( self, "_host", self.hostname .. ":" .. port )
    elseif key == "pathname" then
        local cached = raw_get( self, "_pathname" )
        if cached ~= nil then
            return cached
        end

        local path = state.path
        if isTable( path ) then
            ---@cast path string[]
            return cache_value( self, "_pathname", #path == 0 and "" or ("/" .. table_concat( path, "/" )) )
        end

        return path or ""
    elseif key == "search" then
        local query = self.query
        if query ~= nil and query ~= "" then
            return "?" .. query
        end

        return ""
    elseif key == "searchParams" then
        local search_params = raw_get( self, "_search_params" )
        if search_params == nil then
            search_params = SearchParamsClass( state.query, self )
            raw_set( self, "_search_params", search_params )
        end

        return search_params
    elseif key == "hash" then
        local fragment = state.fragment
        if fragment ~= nil and fragment ~= "" then
            return "#" .. fragment
        end

        return ""
    end
end

-- an invalid host is ignored like in the browser, the host and the port
-- are parsed into a copy of the state so a failure can't leave half of them set
---@param url dreamwork.std.URL
---@param state dreamwork.std.URL.State
---@param value string
---@param state_override "host" | "hostname"
local function set_host( url, state, value, state_override )
    if isString( state.path ) then
        return
    end

    local new_state = {}

    for key, state_value in raw_pairs( state ) do
        new_state[ key ] = state_value
    end

    if pcall( parse_host, new_state, value, 1, string_len( value ), get_special( state ), state_override ) then
        raw_set( url, "state", new_state )
        reset_cache( url )
    end
end

---@param key string
---@param value any
---@protected
function URL:__newindex( key, value )
    local state = raw_get( self, "state" )
    ---@cast state dreamwork.std.URL.State

    if STATE_FIELDS[ key ] then
        reset_cache( self )

        if key == "username" or key == "password" then
            if not cannot_have_credentials( state ) then
                state[ key ] = percent_encode( value, USERINFO_WHITELIST, true )
            end
        elseif key == "hostname" then
            set_host( self, state, value, "hostname" )
        elseif key == "port" then
            if cannot_have_credentials( state ) then
                return
            end

            if value == nil or value == "" then
                state.port = nil
            else
                value = tostring( value )
                parse_port( state, value, 1, string_len( value ), get_special( state ), true )
            end
        elseif key == "query" then
            if isURLSearchParams( value ) then
                value = serialize_query( value )
            end

            state.query = value
            refresh_search_params( self )
        else
            state[ key ] = value
        end

        return
    end

    if key == "href" then
        reset_cache( self )
        raw_set( self, "state", parse( {}, value ) )
        refresh_search_params( self )
    elseif key == "protocol" then
        reset_cache( self )
        parse_scheme( state, value .. ":", 1, string_len( value ) + 1, nil, true )
    elseif key == "host" then
        set_host( self, state, value, "host" )
    elseif key == "pathname" then
        if isString( state.path ) then return end

        reset_cache( self )

        state.path = {}
        parse_path_start( state, value, 1, string_len( value ), get_special( state ), true )
    elseif key == "search" then
        reset_cache( self )

        if value == nil or value == "" then
            state.query = nil
        else
            parse_query( state, value, (string_byte( value, 1, 1 ) == 0x3F --[[ ? ]]) and 2 or 1, string_len( value ), get_special( state ), true )
        end

        refresh_search_params( self )
    elseif key == "searchParams" or key == "origin" then
        return
    elseif key == "hash" then
        reset_cache( self )

        if value == nil or value == "" then
            state.fragment = nil
            return
        end

        parse_fragment( state, value, (string_byte( value, 1, 1 ) == 0x23 --[[ # ]]) and 2 or 1, string_len( value ) )
    else
        raw_set( self, key, value )
    end
end

---@return string
---@protected
function URL:__tostring()
    return self.href
end

---@return string
---@protected
function URL:__represent()
    return string_format( "URL: %p [%s]", self, self )
end

---@param str string
---@param base? string | dreamwork.std.URL
---@protected
function URL:__init( str, base )
    self.state = parse( {}, str, base )
end

--- [SHARED AND MENU]
---
--- Parses a URL string into a plain state table, without creating a `URL` object.
---
--- Same rules as calling `URL`, throws an error if the URL is invalid.
---
--- ```lua
--- local state = std.URL.parse( "https://example.com:8080/a/b?q" )
--- state.hostname -- "example.com"
--- state.port     -- 8080
--- state.path     -- { "a", "b" }
--- ```
---
---@see dreamwork.std.URL
---
---@param url string The URL string to parse.
---@param base? string | dreamwork.std.URL The base URL that relative URLs are resolved against.
---@return dreamwork.std.URL.State state The parsed URL state.
---@nodiscard
function URLClass.parse( url, base )
    return parse( {}, url, base )
end

--- [SHARED AND MENU]
---
--- Checks if a URL string can be parsed, without throwing an error.
---
--- ```lua
--- std.URL.canParse( "https://example.com" ) -- true, state
--- std.URL.canParse( "/path" )                -- false, "...Invalid URL: Missing scheme"
--- std.URL.canParse( "/path", "https://h/" )  -- true, state
--- ```
---
---@param url string The URL string to check.
---@param base? string | dreamwork.std.URL The base URL that relative URLs are resolved against.
---@return boolean success `true` if the URL is valid, otherwise `false`.
---@return dreamwork.std.URL.State | string state_or_error The parsed URL state, or the error message if the URL is invalid.
---@nodiscard
function URLClass.canParse( url, base )
    return pcall( parse, {}, url, base )
end

URLClass.serialize = serialize

--- [SHARED AND MENU]
---
--- Percent-encodes a whole URI, like JavaScript `encodeURI`.
---
--- Letters, digits, `-_.!~*'()` and the URI delimiters `;,/?:@&=+$#` are kept,
--- every other byte is encoded as `%XX`, spaces included.
---
--- ```lua
--- std.URL.encodeURI( "https://h/a b?q=ü" ) -- "https://h/a%20b?q=%C3%BC"
--- ```
---
--- See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURI
---
---@param uri string The URI to encode.
---@return string encoded_uri The encoded URI.
---@nodiscard
function URLClass.encodeURI( uri )
    return percent_encode( uri, URI_WHITELIST, true )
end

---@param hex string
---@return string | nil
local function decode_uri_escape( hex )
    local uint8 = string_toNumber( hex, 16 ) or 0
    if not URI_RESERVED_BYTES[ uint8 ] then
        return string_char( uint8 )
    end
end

--- [SHARED AND MENU]
---
--- Decodes `%XX` escapes in a whole URI, like JavaScript `decodeURI`.
---
--- Escapes of the URI delimiters `;/?:@&=+$,#` are kept as is,
--- so the structure of the URI does not change. Invalid escapes are kept as is.
---
--- ```lua
--- std.URL.decodeURI( "/a%20b%2Fc" ) -- "/a b%2Fc"
--- ```
---
--- See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/decodeURI
---
---@param uri string The URI to decode.
---@return string decoded_uri The decoded URI.
---@nodiscard
function URLClass.decodeURI( uri )
    return (string_gsub( uri, "%%(%x%x)", decode_uri_escape ))
end

--- [SHARED AND MENU]
---
--- Percent-encodes a single URI component, like JavaScript `encodeURIComponent`.
---
--- Only letters, digits and `-_.!~*'()` are kept, every other byte is encoded as `%XX`,
--- spaces become `%20`. Use it for values put into a path segment or a query.
---
--- ```lua
--- std.URL.encodeURIComponent( "a b&c=d/e" ) -- "a%20b%26c%3Dd%2Fe"
--- ```
---
--- See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent
---
---@param uri string The URI component to encode.
---@return string encoded_uri The encoded URI component.
---@nodiscard
function URLClass.encodeURIComponent( uri )
    return percent_encode( uri, URI_COMPONENT_WHITELIST, true )
end

--- [SHARED AND MENU]
---
--- Decodes every `%XX` escape in a URI component, like JavaScript `decodeURIComponent`.
---
--- `"+"` is kept as is, invalid escapes are kept as is.
---
--- ```lua
--- std.URL.decodeURIComponent( "a%20b%26c+d" ) -- "a b&c+d"
--- ```
---
--- See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/decodeURIComponent
---
---@param uri string The URI component to decode.
---@return string decoded_uri The decoded URI component.
---@nodiscard
function URLClass.decodeURIComponent( uri )
    return percent_decode( uri, true )
end
