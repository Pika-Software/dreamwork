---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_get = raw.get
local raw_type = raw.type
local raw_pairs = raw.pairs
local raw_tonumber = raw.tonumber

local debug = std.debug
local debug_getmetatable = debug.getmetatable

local math = std.math
local math_huge = math.huge
local math_floor = math.floor

local string = std.string
local string_len = string.len
local string_sub = string.sub
local string_char = string.char
local string_byte = string.byte
local string_find = string.find
local string_gsub = string.gsub
local string_match = string.match
local string_format = string.format
local string_byteRep = string.byteRep

local utf8 = std.utf8
local utf8_encode = utf8.encode

local table = std.table
local table_concat = table.concat
local table_isSequential = table.isSequential

local len = std.len
local null = std.null
local error = std.error
local isString = std.isString

local DecodeError = std.DecodeError
local EncodeError = std.EncodeError


--- [SHARED AND MENU]
---
--- The JSON format is a lightweight data interchange format.
---
--- Follows [RFC 8259](https://datatracker.ietf.org/doc/html/rfc8259) strictly: objects, arrays, strings, numbers, `true`, `false` and `null`.
---
---@class dreamwork.std.json
local json = {}
std.json = json

--- The default maximum nesting depth of arrays and objects, for both decoding and encoding.
local MAX_DEPTH = 512

local escapes = {
    [ 0x22 ] = "\"",
    [ 0x5C ] = "\\",
    [ 0x2F ] = "/",
    [ 0x62 ] = "\b",
    [ 0x66 ] = "\f",
    [ 0x6E ] = "\n",
    [ 0x72 ] = "\r",
    [ 0x74 ] = "\t"
}

--- Parses a string, `position` points to the opening quote.
---@param text string
---@param position integer
---@return string str
---@return integer position
local function parseString( text, position )
    local start = position + 1
    local stop = string_find( text, "[\"\\%z\1-\31]", start )
    if stop == nil then
        error( DecodeError( "unterminated string", string_len( text ) + 1 ), 2 )
    end

    -- fast path: no escapes
    if string_byte( text, stop ) == 0x22 then
        return string_sub( text, start, stop - 1 ), stop + 1
    end

    ---@type string[]
    local segments = {}

    ---@type integer
    local segment_count = 0

    ::json_string_segment::

    if stop > start then
        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( text, start, stop - 1 )
    end

    local uint8 = string_byte( text, stop )
    if uint8 == 0x22 then
        return table_concat( segments, "", 1, segment_count ), stop + 1
    elseif uint8 ~= 0x5C then
        error( DecodeError( "invalid control character in string", stop ), 2 )
    end

    local escape = string_byte( text, stop + 1 )
    local value = escapes[ escape ]
    start = stop + 2

    if value ~= nil then
        segment_count = segment_count + 1
        segments[ segment_count ] = value
    elseif escape == 0x75 then
        local hex = string_match( text, "^%x%x%x%x", start )
        if hex == nil then
            error( DecodeError( "invalid unicode escape", stop ), 2 )
        end

        local code = raw_tonumber( hex, 16 ) or 0
        start = start + 4

        if code >= 0xD800 and code <= 0xDBFF then
            local low = string_match( text, "^\\u(%x%x%x%x)", start )
            low = low and raw_tonumber( low, 16 )

            if low == nil or low < 0xDC00 or low > 0xDFFF then
                error( DecodeError( "invalid surrogate pair", stop ), 2 )
            end

            code = 0x10000 + (code - 0xD800) * 0x400 + (low - 0xDC00)
            start = start + 6
        elseif code >= 0xDC00 and code <= 0xDFFF then
            error( DecodeError( "unexpected low surrogate", stop ), 2 )
        end

        segment_count = segment_count + 1
        segments[ segment_count ] = utf8_encode( code )
    else
        error( DecodeError( "invalid escape sequence", stop ), 2 )
    end

    stop = string_find( text, "[\"\\%z\1-\31]", start )
    if stop == nil then
        error( DecodeError( "unterminated string", string_len( text ) + 1 ), 2 )
    end

    ---@diagnostic disable-next-line: missing-return
    goto json_string_segment
end

local parseValue

--- Parses a value, skipping leading whitespace.
---@param text string
---@param position integer
---@param depth integer
---@param max_depth integer
---@return dreamwork.std.json.Value value
---@return integer position
function parseValue( text, position, depth, max_depth )
    local start = string_find( text, "[^ \t\r\n]", position )
    if start == nil then
        error( DecodeError( "unexpected end of input", string_len( text ) + 1 ), 2 )
    end

    local uint8 = string_byte( text, start )

    -- string
    if uint8 == 0x22 then
        return parseString( text, start )
    end

    -- object
    if uint8 == 0x7B then
        if depth > max_depth then
            error( DecodeError( "maximum nesting depth exceeded", start ), 2 )
        end

        local result = {}

        local stop = string_find( text, "[^ \t\r\n]", start + 1 )
        if stop ~= nil and string_byte( text, stop ) == 0x7D then
            return result, stop + 1
        end

        position = start + 1

        ::json_object_member::

        local key_start = string_find( text, "[^ \t\r\n]", position )
        if key_start == nil or string_byte( text, key_start ) ~= 0x22 then
            error( DecodeError( "object key must be a string", key_start or string_len( text ) + 1 ), 2 )
        end

        local key
        key, position = parseString( text, key_start )

        local colon = string_find( text, "[^ \t\r\n]", position )
        if colon == nil or string_byte( text, colon ) ~= 0x3A then
            error( DecodeError( "expected ':'", colon or string_len( text ) + 1 ), 2 )
        end

        result[ key ], position = parseValue( text, colon + 1, depth + 1, max_depth )

        local separator = string_find( text, "[^ \t\r\n]", position )
        local sep_byte = separator and string_byte( text, separator )

        if sep_byte == 0x2C then
            position = separator + 1
            goto json_object_member
        elseif sep_byte == 0x7D then
            return result, separator + 1
        end

        error( DecodeError( "expected ',' or '}'", separator or string_len( text ) + 1 ), 2 )
    end

    -- array
    if uint8 == 0x5B then
        if depth > max_depth then
            error( DecodeError( "maximum nesting depth exceeded", start ), 2 )
        end

        local result, length = {}, 0

        local stop = string_find( text, "[^ \t\r\n]", start + 1 )
        if stop ~= nil and string_byte( text, stop ) == 0x5D then
            return result, stop + 1
        end

        position = start + 1

        ::json_array_element::

        length = length + 1
        result[ length ], position = parseValue( text, position, depth + 1, max_depth )

        local separator = string_find( text, "[^ \t\r\n]", position )
        local sep_byte = separator and string_byte( text, separator )

        if sep_byte == 0x2C then
            position = separator + 1
            goto json_array_element
        elseif sep_byte == 0x5D then
            return result, separator + 1
        end

        error( DecodeError( "expected ',' or ']'", separator or string_len( text ) + 1 ), 2 )
    end

    -- number
    if uint8 == 0x2D or (uint8 >= 0x30 and uint8 <= 0x39) then
        local _, stop = string_find( text, "^-?%d+", start )
        if stop == nil then
            error( DecodeError( "invalid number", start ), 2 )
        end

        -- no leading zeros
        local first = uint8 == 0x2D and start + 1 or start
        if string_byte( text, first ) == 0x30 and stop > first then
            error( DecodeError( "leading zeros are not allowed", start ), 2 )
        end

        local _, frac_stop = string_find( text, "^%.%d+", stop + 1 )
        if frac_stop ~= nil then
            stop = frac_stop
        elseif string_byte( text, stop + 1 ) == 0x2E then
            error( DecodeError( "invalid number", stop + 1 ), 2 )
        end

        local _, exp_stop = string_find( text, "^[eE][+-]?%d+", stop + 1 )
        if exp_stop ~= nil then
            stop = exp_stop
        else
            local next_byte = string_byte( text, stop + 1 )
            if next_byte == 0x65 or next_byte == 0x45 then
                error( DecodeError( "invalid number", stop + 1 ), 2 )
            end
        end

        return raw_tonumber( string_sub( text, start, stop ) ) or 0, stop + 1
    end

    -- literals
    if uint8 == 0x74 and string_sub( text, start, start + 3 ) == "true" then
        return true, start + 4
    elseif uint8 == 0x66 and string_sub( text, start, start + 4 ) == "false" then
        return false, start + 5
    elseif uint8 == 0x6E and string_sub( text, start, start + 3 ) == "null" then
        return null, start + 4
    end

    error( DecodeError( "unexpected character", start ), 2 )
end

--- [SHARED AND MENU]
---
--- Deserialize a JSON string into a Lua value.
---
--- JSON `null` becomes `std.null` (never `nil`), numbers become Lua numbers, objects and arrays become plain tables.
---
--- A leading UTF-8 BOM is skipped, nesting deeper than `max_depth` levels is rejected.
---
--- Raises a `DecodeError` (with the byte position of the problem) on malformed input or trailing data.
---
---@param json_str string The JSON string to deserialize.
---@param max_depth? integer The maximum nesting depth, default is `512`.
---@return dreamwork.std.json.Value json_value The deserialized value.
function json.deserialize( json_str, max_depth )
    local uint8_1, uint8_2, uint8_3 = string_byte( json_str, 1, 3 )

    local value, end_position = parseValue(
        json_str,
        (uint8_1 == 0xEF and uint8_2 == 0xBB and uint8_3 == 0xBF) and 4 or 1, -- skip UTF-8 BOM
        1,
        max_depth or MAX_DEPTH
    )

    local trailing = string_find( json_str, "[^ \t\r\n]", end_position )
    if trailing ~= nil then
        error( DecodeError( "unexpected trailing data", trailing ), 2 )
    end

    return value
end

local quote
do

    ---@type table<string, string>
    local escape_map = {
        [ "\"" ] = "\\\"",
        [ "\\" ] = "\\\\",
        [ "\b" ] = "\\b",
        [ "\f" ] = "\\f",
        [ "\n" ] = "\\n",
        [ "\r" ] = "\\r",
        [ "\t" ] = "\\t"
    }

    for uint8 = 0, 0x1F do
        local char = string_char( uint8 )
        if escape_map[ char ] == nil then
            escape_map[ char ] = string_format( "\\u%04x", uint8 )
        end
    end

    escape_map[ "\127" ] = "\\u007f"

    ---@param str string
    ---@return string
    function quote( str )
        if string_find( str, "[%z\1-\31\"\\\127]" ) ~= nil then
            str = string_gsub( str, "[%z\1-\31\"\\\127]", escape_map )
        end

        return "\"" .. str .. "\""
    end

end

---@type table<integer, string>
local indent_cache = {
    [ 0 ] = "\n",
}

setmetatable( indent_cache, {
    ---@param self table<integer, string>
    ---@param depth integer
    __index = function( self, depth )
        local value = "\n" .. string_byteRep( 0x20, depth * 2 )
        self[ depth ] = value
        return value
    end
} )

---@param number number
---@return string
local function encodeNumber( number )
    if number ~= number or number == math_huge or number == -math_huge then
        error( EncodeError( "unable to serialize non-finite number", number ), 2 )
    end

    if number == math_floor( number ) and number > -1e15 and number < 1e15 then
        if number == 0 and 1 / number < 0 then
            return "-0"
        end

        return string_format( "%d", number )
    end

    local str = string_format( "%.14g", number )
    if raw_tonumber( str ) ~= number then
        str = string_format( "%.17g", number )
    end

    return str
end

---@param value any
---@return boolean
local function isCustomObject( value )
    local metatable = debug_getmetatable( value )
    return metatable ~= nil and not (
        raw_get( metatable, "__tostring" ) == nil and
        raw_get( metatable, "__tonumber" ) == nil and
        raw_get( metatable, "__tojson" ) == nil
    )
end

---@param value any
---@return string
local function convertObject( value )
    local metatable = debug_getmetatable( value )
    if metatable ~= nil then
        local to_json = raw_get( metatable, "__tojson" )
        if to_json ~= nil then
            return to_json( value )
        end

        local to_number = raw_get( metatable, "__tonumber" )
        if to_number ~= nil then
            return encodeNumber( to_number( value ) )
        end

        local to_string = raw_get( metatable, "__tostring" )
        if to_string ~= nil then
            return quote( to_string( value ) )
        end
    end

    error( EncodeError( "unable to serialize " .. raw_type( value ) .. " value", value ), 2 )
end

---@param key any
---@return string
local function convertKey( key )
    local key_type = raw_type( key )
    if key_type == "number" then
        return encodeNumber( key )
    elseif key_type == "boolean" then
        return key and "true" or "false"
    end

    local metatable = debug_getmetatable( key )
    if metatable ~= nil then
        local to_string = raw_get( metatable, "__tostring" )
        if to_string ~= nil then
            return to_string( key )
        end
    end

    error( EncodeError( "unable to use " .. key_type .. " value as an object key", key ), 3 )
end

--- Appends `value` to `buffer` and returns the new buffer size.
---
---@param buffer string[]
---@param buffer_size integer
---@param value dreamwork.std.json.Value | nil
---@param depth integer
---@param max_depth integer
---@param pretty boolean
---@return integer buffer_size
local function serializeValue( buffer, buffer_size, value, depth, max_depth, pretty )
    local value_type = raw_type( value )

    if value_type == "string" then
        ---@cast value string
        buffer_size = buffer_size + 1
        buffer[ buffer_size ] = quote( value )
        return buffer_size
    elseif value_type == "number" then
        ---@cast value number
        buffer_size = buffer_size + 1
        buffer[ buffer_size ] = encodeNumber( value )
        return buffer_size
    elseif value_type == "boolean" then
        ---@cast value boolean
        buffer_size = buffer_size + 1
        buffer[ buffer_size ] = value and "true" or "false"
        return buffer_size
    elseif value == nil or value == null then
        ---@cast value dreamwork.std.null
        buffer_size = buffer_size + 1
        buffer[ buffer_size ] = "null"
        return buffer_size
    elseif value_type ~= "table" or isCustomObject( value ) then
        buffer_size = buffer_size + 1
        buffer[ buffer_size ] = convertObject( value )
        return buffer_size
    end

    ---@cast value dreamwork.std.json.Table

    if depth > max_depth then
        error( EncodeError( "maximum nesting depth exceeded (circular reference?)", value ), 2 )
    end

    local inner = depth + 1

    if table_isSequential( value ) then
        ---@cast value dreamwork.std.json.Array

        local length = len( value )
        if length == 0 then
            buffer_size = buffer_size + 1
            buffer[ buffer_size ] = "[]"
            return buffer_size
        end

        buffer_size = buffer_size + 1
        buffer[ buffer_size ] = pretty and ("[" .. indent_cache[ inner ]) or "["

        local separator = pretty and ("," .. indent_cache[ inner ]) or ","

        for index = 1, length do
            if index > 1 then
                buffer_size = buffer_size + 1
                buffer[ buffer_size ] = separator
            end

            buffer_size = serializeValue( buffer, buffer_size, value[ index ], inner, max_depth, pretty )
        end

        buffer_size = buffer_size + 1
        buffer[ buffer_size ] = pretty and (indent_cache[ depth ] .. "]") or "]"

        return buffer_size
    end

    ---@cast value dreamwork.std.json.Object

    buffer_size = buffer_size + 1
    buffer[ buffer_size ] = pretty and ("{" .. indent_cache[ inner ]) or "{"

    local separator = pretty and ("," .. indent_cache[ inner ]) or ","
    local colon = pretty and ": " or ":"
    local first = true

    for key, item in raw_pairs( value ) do
        ---@type string
        local key_str

        if isString( key ) then
            key_str = key
        else
            key_str = convertKey( key )
            if raw_get( value, key_str ) ~= nil then
                error( EncodeError( "duplicate object key '" .. key_str .. "'", value ), 2 )
            end
        end

        if first then
            first = false
        else
            buffer_size = buffer_size + 1
            buffer[ buffer_size ] = separator
        end

        buffer_size = buffer_size + 1
        buffer[ buffer_size ] = quote( key_str ) .. colon

        buffer_size = serializeValue( buffer, buffer_size, item, inner, max_depth, pretty )
    end

    buffer_size = buffer_size + 1
    buffer[ buffer_size ] = pretty and (indent_cache[ depth ] .. "}") or "}"

    return buffer_size
end

--- [SHARED AND MENU]
---
--- Serialize a Lua value into a JSON string.
---
--- Tables with only sequential keys `1..n` (and empty tables) become arrays, all other tables become objects.
---
--- `nil` and `std.null` are written as `null`.
---
--- Tables with a metatable are converted by the first available metamethod: `__tojson` (must return a valid JSON string, written as is), `__tonumber` (number) or `__tostring` (string).
---
--- Object keys that are not strings are converted: numbers and booleans are formatted, other values need `__tostring`.
---
--- Raises an `EncodeError` for any other non-JSON value (functions, threads, `NaN`/`inf`), unconvertible keys, keys that collide after conversion, or nesting deeper than `max_depth` levels (circular references).
---
---@param value dreamwork.std.json.Value | nil The value to serialize.
---@param prettify? boolean Whether to indent the output, default is `false`.
---@param max_depth? integer The maximum nesting depth, default is `512`.
---@return string json_str The JSON string.
---@nodiscard
function json.serialize( value, prettify, max_depth )
    local buffer = {}
    return table_concat( buffer, "", 1, serializeValue( buffer, 0, value, 0, max_depth or MAX_DEPTH, prettify == true ) )
end
