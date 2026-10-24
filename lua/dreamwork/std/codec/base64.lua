---@type fun( data: string ): string
local util_Base64Encode

---@type fun( data: string ): string
local util_Base64Decode

local glua_util = util
if glua_util ~= nil then
    util_Base64Encode = glua_util.Base64Encode
    util_Base64Decode = glua_util.Base64Decode
end

---@class dreamwork.std
local std = dreamwork.std

local ffi = std.ffi

local raw = std.raw

local math = std.math
local math_max = math.max

local table = std.table
local table_concat = table.concat

local string = std.string
local string_len = string.len
local string_sub, string_rep = string.sub, string.rep
local string_byte, string_char = string.byte, string.char
local string_find, string_gsub = string.find, string.gsub

local rbit = raw.bit
local rbit_band, rbit_bor = rbit.band, rbit.bor
local rbit_lshift, rbit_rshift = rbit.lshift, rbit.rshift

local error = std.error


--- [SHARED AND MENU]
---
--- Base64 encoding/decoding library.
---
---@see https://en.wikipedia.org/wiki/Base64
---@class dreamwork.std.base64
local base64 = {}
std.base64 = base64

--- [SHARED AND MENU]
---
--- The base64 encoding/decoding alphabet, created by `base64.alphabet`.
---
---@class dreamwork.std.base64.Alphabet
---@field [1] table<integer, integer> | ffi.cdata* The encoding map, value ( 0 - 63 ) to character byte.
---@field [2] table<integer, integer> | ffi.cdata* The decoding map, character byte ( 0 - 255 ) to value, `-1` for characters outside the alphabet.

--- [SHARED AND MENU]
---
--- Creates a base64 alphabet with encoding and decoding maps.
---
---@param alphabet_str string The alphabet string, 64 unique non-whitespace characters.
---@return dreamwork.std.base64.Alphabet alphabet The alphabet.
function base64.alphabet( alphabet_str )
    if string_len( alphabet_str ) ~= 64 then
        error( "alphabet must be 64 characters long", 2 )
    end

    if string_find( alphabet_str, "%s" ) ~= nil then
        error( "alphabet cannot contain whitespace characters", 2 )
    end

    local encode_map, decode_map

    if ffi == nil then
        encode_map, decode_map = {}, {}

        for uint8 = 0, 255, 1 do
            decode_map[ uint8 ] = -1
        end
    else
        encode_map, decode_map = ffi.new( "uint8_t[64]" ), ffi.new( "int8_t[256]", -1 )
    end

    for index = 1, 64, 1 do
        local uint8 = string_byte( alphabet_str, index, index )

        if decode_map[ uint8 ] ~= -1 then
            if uint8 > 32 and uint8 < 127 then
                error( "alphabet characters must be unique, duplicate character: '" .. string_char( uint8 ) .. "' [" .. index .. "]", 2 )
            else
                error( "alphabet characters must be unique, duplicate character: '\\" .. uint8 .. "' [" .. index .. "]", 2 )
            end
        end

        encode_map[ index - 1 ] = uint8
        decode_map[ uint8 ] = index - 1
    end

    return { encode_map, decode_map }
end

local standard = base64.alphabet( "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/" )
local urlsafe = base64.alphabet( "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_" )

--- [SHARED AND MENU]
---
--- Base64 encoding/decoding options variant.
---
---@class dreamwork.std.base64.Variant
---@field alphabet dreamwork.std.base64.Alphabet The 64-character alphabet used for encoding and decoding.
---@field pad string | false | nil Padding character (usually "="), `false` disables padding.
---@field wrap integer | false | nil Line wrap length, `false` or `0` disables wrapping.
---@field eol string | nil End-of-line characters used if `wrap` is set, default is `"\r\n"`.

---@type table<string, dreamwork.std.base64.Variant>
local variants = {
    standard = {
        alphabet = standard,
        pad = "="
    },

    urlsafe = {
        alphabet = urlsafe
    },

    mime = {
        alphabet = standard,
        pad = "=",
        wrap = 76,
        eol = "\r\n"
    },

    custom = {
        alphabet = standard
    }
}

variants.jwt = variants.urlsafe

--- [SHARED AND MENU]
---
--- Base64 encoding/decoding options.
---
--- Fields that are `nil` are taken from the variant, `custom` has the standard alphabet without padding and wrapping.
---
---@class dreamwork.std.base64.Options : dreamwork.std.base64.Variant
---@field variant "standard" | "urlsafe" | "mime" | "jwt" | "custom" | nil The base64 variant to use, default is `"standard"`.

--- Resolves the options without modifying them.
---
---@param options dreamwork.std.base64.Options
---@return dreamwork.std.base64.Alphabet alphabet
---@return integer | nil pad_byte
---@return integer | nil wrap
---@return string eol
local function get_options( options )
    local variant_name = options.variant or "standard"

    local variant = variants[ variant_name ]
    if variant == nil then
        error( "unknown base64 variant '" .. variant_name .. "'", 3 )
    end

    local alphabet = options.alphabet or variant.alphabet

    local pad = options.pad
    if pad == nil then
        pad = variant.pad
    end

    local pad_byte

    if pad then
        if string_len( pad ) ~= 1 then
            error( "pad must be a single character", 3 )
        end

        pad_byte = string_byte( pad, 1, 1 )

        if alphabet[ 2 ][ pad_byte ] ~= -1 then
            error( "pad character cannot be part of the alphabet", 3 )
        end
    end

    local wrap = options.wrap
    if wrap == nil then
        wrap = variant.wrap
    end

    if wrap == false or wrap == 0 then
        wrap = nil
    elseif wrap ~= nil and (wrap < 1 or wrap % 1 ~= 0) then
        error( "wrap must be a positive integer", 3 )
    end

    return alphabet, pad_byte, wrap, options.eol or variant.eol or "\r\n"
end

--- Number of characters in the last incomplete block for each number of remaining bytes.
---
---@type table<integer, integer>
local tail_chars = { [ 0 ] = 0, [ 1 ] = 2, [ 2 ] = 3 }

--- Number of bytes in the last incomplete block for each number of remaining characters, `nil` for impossible lengths.
---
---@type table<integer, integer>
local tail_bytes = { [ 0 ] = 0, [ 2 ] = 1, [ 3 ] = 2 }

---@type table<integer, boolean>
local whitespace_bytes = { [ 0x09 ] = true, [ 0x0A ] = true, [ 0x0B ] = true, [ 0x0C ] = true, [ 0x0D ] = true, [ 0x20 ] = true }

--- Checks the length and padding of a base64 string without whitespace.
---
---@param base64_str string
---@param pad_byte integer
---@return integer | nil data_length The length without padding, or `nil` if the string is invalid.
---@return nil | string err_msg The error message.
local function get_data_length( base64_str, pad_byte )
    ---@type integer
    local str_length = string_len( base64_str )
    local data_length = str_length

    while data_length ~= 0 and string_byte( base64_str, data_length, data_length ) == pad_byte do
        data_length = data_length - 1
    end

    local remainder = data_length % 4

    if tail_bytes[ remainder ] == nil then
        return nil, "string has invalid length"
    end

    local padding = str_length - data_length

    if padding ~= 0 and (data_length == 0 or padding ~= (4 - remainder) % 4) then
        return nil, "string has invalid padding"
    end

    return data_length
end

--- Returns the position of the first character outside the alphabet in the original ( not stripped ) string.
---
---@param base64_str string
---@param decode_map table<integer, integer> | ffi.cdata*
---@param pad_byte integer
---@return integer | nil
local function find_invalid( base64_str, decode_map, pad_byte )
    local end_position = string_len( base64_str )

    while end_position ~= 0 do
        local uint8 = string_byte( base64_str, end_position, end_position )
        if uint8 ~= pad_byte and not whitespace_bytes[ uint8 ] then
            break
        end

        end_position = end_position - 1
    end

    for index = 1, end_position, 1 do
        local uint8 = string_byte( base64_str, index, index )
        if not whitespace_bytes[ uint8 ] and decode_map[ uint8 ] < 0 then
            return index
        end
    end
end

---@type fun( str: string, str_length: integer, encode_map: table<integer, integer> | ffi.cdata*, pad_byte: integer | nil ): string
local encode

---@type fun( str: string, data_length: integer, decode_map: table<integer, integer> | ffi.cdata* ): string | nil
local decode

if ffi == nil then

    function encode( str, str_length, encode_map, pad_byte )
        local segments, segment_count = {}, 0
        local remainder = str_length % 3

        for index = 1, str_length - remainder, 3 do
            local uint8_1, uint8_2, uint8_3 = string_byte( str, index, index + 2 )

            segment_count = segment_count + 1
            segments[ segment_count ] = string_char(
                encode_map[ rbit_rshift( uint8_1, 2 ) ],
                encode_map[ rbit_bor( rbit_lshift( rbit_band( uint8_1, 0x03 ), 4 ), rbit_rshift( uint8_2, 4 ) ) ],
                encode_map[ rbit_bor( rbit_lshift( rbit_band( uint8_2, 0x0F ), 2 ), rbit_rshift( uint8_3, 6 ) ) ],
                encode_map[ rbit_band( uint8_3, 0x3F ) ]
            )
        end

        if remainder ~= 0 then
            local uint8_1, uint8_2 = string_byte( str, str_length - remainder + 1, str_length )
            uint8_2 = uint8_2 or 0

            segment_count = segment_count + 1
            segments[ segment_count ] = string_sub( string_char(
                encode_map[ rbit_rshift( uint8_1, 2 ) ],
                encode_map[ rbit_bor( rbit_lshift( rbit_band( uint8_1, 0x03 ), 4 ), rbit_rshift( uint8_2, 4 ) ) ],
                encode_map[ rbit_lshift( rbit_band( uint8_2, 0x0F ), 2 ) ]
            ), 1, tail_chars[ remainder ] )

            if pad_byte ~= nil then
                segment_count = segment_count + 1
                segments[ segment_count ] = string_rep( string_char( pad_byte ), 3 - remainder )
            end
        end

        return table_concat( segments, "", 1, segment_count )
    end

    function decode( str, data_length, decode_map )
        local segments, segment_count = {}, 0
        local remainder = data_length % 4

        for index = 1, data_length - remainder, 4 do
            local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, index, index + 3 )
            local value_1, value_2, value_3, value_4 = decode_map[ uint8_1 ], decode_map[ uint8_2 ], decode_map[ uint8_3 ], decode_map[ uint8_4 ]

            if rbit_bor( value_1, value_2, value_3, value_4 ) < 0 then
                return nil
            end

            segment_count = segment_count + 1
            segments[ segment_count ] = string_char(
                rbit_bor( rbit_lshift( value_1, 2 ), rbit_rshift( value_2, 4 ) ),
                rbit_bor( rbit_lshift( rbit_band( value_2, 0x0F ), 4 ), rbit_rshift( value_3, 2 ) ),
                rbit_bor( rbit_lshift( rbit_band( value_3, 0x03 ), 6 ), value_4 )
            )
        end

        if remainder ~= 0 then
            local uint8_1, uint8_2, uint8_3 = string_byte( str, data_length - remainder + 1, data_length )
            local value_1, value_2, value_3 = decode_map[ uint8_1 ], decode_map[ uint8_2 ], uint8_3 and decode_map[ uint8_3 ] or 0

            if rbit_bor( value_1, value_2, value_3 ) < 0 then
                return nil
            end

            segment_count = segment_count + 1
            segments[ segment_count ] = string_sub( string_char(
                rbit_bor( rbit_lshift( value_1, 2 ), rbit_rshift( value_2, 4 ) ),
                rbit_bor( rbit_lshift( rbit_band( value_2, 0x0F ), 4 ), rbit_rshift( value_3, 2 ) )
            ), 1, tail_bytes[ remainder ] )
        end

        return table_concat( segments, "", 1, segment_count )
    end

else

    local ffi_cast = ffi.cast
    local ffi_string = ffi.string

    local uint8_ptr_t = ffi.typeof( "const uint8_t *" )
    local uint8_array_t = ffi.typeof( "uint8_t[?]" )

    --- Larger outputs get a temporary buffer, so memory isn't held after one big call.
    local max_buffer_size = 0x100000

    local buffer_size = 256
    local buffer = uint8_array_t( buffer_size )

    ---@param size integer
    ---@return ffi.cdata*
    local function get_buffer( size )
        if size > buffer_size then
            if size > max_buffer_size then
                return uint8_array_t( size )
            end

            buffer_size = math_max( size, buffer_size * 2 )
            buffer = uint8_array_t( buffer_size )
        end

        return buffer
    end

    -- NOTE: loops below do not allocate, so the GC cannot collect `str` while its data is read by pointer.

    function encode( str, str_length, encode_map, pad_byte )
        local remainder = str_length % 3
        local output = get_buffer( (str_length - remainder) / 3 * 4 + 4 )
        local source = ffi_cast( uint8_ptr_t, str )

        local length = 0

        for index = 0, str_length - remainder - 1, 3 do
            local uint8_1, uint8_2, uint8_3 = source[ index ], source[ index + 1 ], source[ index + 2 ]

            output[ length ] = encode_map[ rbit_rshift( uint8_1, 2 ) ]
            output[ length + 1 ] = encode_map[ rbit_bor( rbit_lshift( rbit_band( uint8_1, 0x03 ), 4 ), rbit_rshift( uint8_2, 4 ) ) ]
            output[ length + 2 ] = encode_map[ rbit_bor( rbit_lshift( rbit_band( uint8_2, 0x0F ), 2 ), rbit_rshift( uint8_3, 6 ) ) ]
            output[ length + 3 ] = encode_map[ rbit_band( uint8_3, 0x3F ) ]

            length = length + 4
        end

        if remainder ~= 0 then
            local index = str_length - remainder
            local uint8_1, uint8_2 = source[ index ], remainder == 2 and source[ index + 1 ] or 0

            output[ length ] = encode_map[ rbit_rshift( uint8_1, 2 ) ]
            output[ length + 1 ] = encode_map[ rbit_bor( rbit_lshift( rbit_band( uint8_1, 0x03 ), 4 ), rbit_rshift( uint8_2, 4 ) ) ]
            output[ length + 2 ] = encode_map[ rbit_lshift( rbit_band( uint8_2, 0x0F ), 2 ) ]

            if pad_byte == nil then
                length = length + tail_chars[ remainder ]
            else
                if remainder == 1 then
                    output[ length + 2 ] = pad_byte
                end

                output[ length + 3 ] = pad_byte
                length = length + 4
            end
        end

        return ffi_string( output, length )
    end

    function decode( str, data_length, decode_map )
        local remainder = data_length % 4
        local output = get_buffer( (data_length - remainder) / 4 * 3 + 3 )
        local source = ffi_cast( uint8_ptr_t, str )

        local length = 0

        for index = 0, data_length - remainder - 1, 4 do
            local value_1, value_2 = decode_map[ source[ index ] ], decode_map[ source[ index + 1 ] ]
            local value_3, value_4 = decode_map[ source[ index + 2 ] ], decode_map[ source[ index + 3 ] ]

            if rbit_bor( value_1, value_2, value_3, value_4 ) < 0 then
                return nil
            end

            output[ length ] = rbit_bor( rbit_lshift( value_1, 2 ), rbit_rshift( value_2, 4 ) )
            output[ length + 1 ] = rbit_bor( rbit_lshift( value_2, 4 ), rbit_rshift( value_3, 2 ) )
            output[ length + 2 ] = rbit_bor( rbit_lshift( value_3, 6 ), value_4 )

            length = length + 3
        end

        if remainder ~= 0 then
            local index = data_length - remainder

            local value_1, value_2 = decode_map[ source[ index ] ], decode_map[ source[ index + 1 ] ]
            local value_3 = remainder == 3 and decode_map[ source[ index + 2 ] ] or 0

            if rbit_bor( value_1, value_2, value_3 ) < 0 then
                return nil
            end

            output[ length ] = rbit_bor( rbit_lshift( value_1, 2 ), rbit_rshift( value_2, 4 ) )
            output[ length + 1 ] = rbit_bor( rbit_lshift( value_2, 4 ), rbit_rshift( value_3, 2 ) )

            length = length + tail_bytes[ remainder ]
        end

        return ffi_string( output, length )
    end

end

---@param base64_str string
---@param wrap integer
---@param eol string
---@return string
local function wrap_lines( base64_str, wrap, eol )
    ---@type integer
    local str_length = string_len( base64_str )

    if str_length <= wrap then
        return base64_str
    end

    local segments, segment_count = {}, 0

    for index = 1, str_length, wrap do
        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( base64_str, index, index + wrap - 1 )
    end

    return table_concat( segments, eol, 1, segment_count )
end

--- Decodes the base64 string or returns `nil` and the error message.
---
---@param base64_str string
---@param decode_map table<integer, integer> | ffi.cdata*
---@param pad_byte integer
---@return string | nil raw_str
---@return nil | string err_msg
local function try_decode( base64_str, decode_map, pad_byte )
    -- fast path, whitespace is never part of the alphabet, so wrapped strings always fall through to the slow path
    local data_length = get_data_length( base64_str, pad_byte )

    if data_length == 0 then
        return ""
    elseif data_length ~= nil then
        local raw_str = decode( base64_str, data_length, decode_map )
        if raw_str ~= nil then
            return raw_str
        end
    end

    local stripped_str = base64_str

    if string_find( stripped_str, "%s" ) ~= nil then
        stripped_str = string_gsub( stripped_str, "%s+", "" )
    end

    local err_msg
    data_length, err_msg = get_data_length( stripped_str, pad_byte )

    if data_length == nil then
        return nil, err_msg
    elseif data_length == 0 then
        return ""
    end

    local raw_str = decode( stripped_str, data_length, decode_map )

    if raw_str == nil then
        return nil, "string contains invalid character at position " .. find_invalid( base64_str, decode_map, pad_byte )
    end

    return raw_str
end

--- [SHARED AND MENU]
---
--- Encodes the specified string to base64.
---
---@param raw_str string The string to encode.
---@param options? dreamwork.std.base64.Options The base64 encoding options, default is the standard variant.
---@return string base64_str The encoded string.
function base64.encode( raw_str, options )
    local alphabet, pad_byte, wrap, eol

    if options == nil then
        if ffi == nil and util_Base64Encode ~= nil then
            return util_Base64Encode( raw_str, true ) or ""
        end

        alphabet, pad_byte = standard, 0x3D --[[ "=" ]]
    else
        alphabet, pad_byte, wrap, eol = get_options( options )
    end

    ---@type integer
    local str_length = string_len( raw_str )

    if str_length == 0 then
        return raw_str
    end

    local base64_str = encode( raw_str, str_length, alphabet[ 1 ], pad_byte )

    if wrap == nil then
        return base64_str
    end

    return wrap_lines( base64_str, wrap, eol )
end

--- [SHARED AND MENU]
---
--- Decodes the specified base64 encoded string.
---
--- Whitespace ( including line breaks ) is ignored, padding is optional but must be correct if present.
---
--- Throws an error if the string has invalid length, padding or characters.
---
---@param base64_str string The base64 encoded string to decode.
---@param options? dreamwork.std.base64.Options The base64 encoding options, default is the standard variant.
---@return string raw_str The decoded string.
function base64.decode( base64_str, options )
    local alphabet, pad_byte

    if options == nil then
        if ffi == nil and util_Base64Decode ~= nil then
            local raw_str = util_Base64Decode( base64_str )
            if raw_str ~= nil then
                return raw_str
            end
        end

        alphabet, pad_byte = standard, 0x3D --[[ "=" ]]
    else
        alphabet, pad_byte = get_options( options )
    end

    local raw_str, err_msg = try_decode( base64_str, alphabet[ 2 ], pad_byte or 0x3D --[[ "=" ]] )

    if raw_str == nil then
        error( err_msg, 2 )
    end

    return raw_str
end

--- [SHARED AND MENU]
---
--- Checks if the specified base64 encoded string is valid, follows the same rules as `base64.decode`.
---
---@param base64_str string The base64 encoded string to check.
---@param options? dreamwork.std.base64.Options The base64 encoding options, default is the standard variant.
---@return boolean is_valid `true` if the base64 string is valid, `false` otherwise
---@return nil | string err_msg The error message.
function base64.validate( base64_str, options )
    local alphabet, pad_byte

    if options == nil then
        alphabet, pad_byte = standard, 0x3D --[[ "=" ]]
    else
        alphabet, pad_byte = get_options( options )
    end

    if string_find( base64_str, "^%s*$" ) ~= nil then
        return false, "string cannot be empty"
    end

    local raw_str, err_msg = try_decode( base64_str, alphabet[ 2 ], pad_byte or 0x3D --[[ "=" ]] )

    if raw_str == nil then
        return false, err_msg
    end

    return true
end
