---@class dreamwork.std
local std = dreamwork.std

local ffi = std.ffi

local raw = std.raw

local math = std.math
local math_max = math.max

local string = std.string
local string_len = string.len
local string_sub, string_rep = string.sub, string.rep
local string_byte, string_char = string.byte, string.char

local ascii = std.ascii
local ascii_isGraphic = ascii.isGraphic

local table = std.table
local table_concat = table.concat

local rbit = raw.bit
local rbit_band, rbit_bor = rbit.band, rbit.bor
local rbit_lshift, rbit_rshift = rbit.lshift, rbit.rshift

local error = std.error


--- [SHARED AND MENU]
---
--- Base32 encoding/decoding library.
---
--- See https://en.wikipedia.org/wiki/Base32
---
---@class dreamwork.std.base32
local base32 = {}
std.base32 = base32

--- [SHARED AND MENU]
---
--- The base32 encoding/decoding alphabet, created by `base32.alphabet`.
---
---@class dreamwork.std.base32.Alphabet
---@field [1] table<integer, integer> | ffi.cdata* The encoding map, value ( 0 - 31 ) to character byte.
---@field [2] table<integer, integer> | ffi.cdata* The decoding map, character byte ( 0 - 255 ) to value, `-1` for characters outside the alphabet.

--- [SHARED AND MENU]
---
--- Creates a base32 alphabet with encoding and decoding maps.
---
---@param alphabet_str string The alphabet string, 32 unique characters without `=`.
---@return dreamwork.std.base32.Alphabet alphabet The alphabet.
function base32.alphabet( alphabet_str )
    if string_len( alphabet_str ) ~= 32 then
        error( "alphabet must be 32 characters long", 2 )
    end

    local encode_map, decode_map

    if ffi == nil then
        encode_map, decode_map = {}, {}

        for uint8 = 0, 255, 1 do
            decode_map[ uint8 ] = -1
        end
    else
        encode_map, decode_map = ffi.new( "uint8_t[32]" ), ffi.new( "int8_t[256]", -1 )
    end

    for index = 1, 32, 1 do
        local uint8 = string_byte( alphabet_str, index, index )

        if uint8 == 0x3D --[[ "=" ]] then
            error( "alphabet cannot contain padding character '=' [" .. index .. "]", 2 )
        elseif decode_map[ uint8 ] ~= -1 then
            if ascii_isGraphic( uint8 ) then
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

local standard = base32.alphabet( "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567" )
local extended = base32.alphabet( "0123456789ABCDEFGHIJKLMNOPQRSTUV" )

---@param alphabet "standard" | "extended" | dreamwork.std.base32.Alphabet | nil
---@return dreamwork.std.base32.Alphabet
local function get_alphabet( alphabet )
    if alphabet == nil or alphabet == "standard" then
        return standard
    elseif alphabet == "extended" then
        return extended
    end

    ---@cast alphabet dreamwork.std.base32.Alphabet
    return alphabet
end

--- Number of characters in the last incomplete block for each number of remaining bytes.
---
---@type table<integer, integer>
local tail_chars = { [ 0 ] = 0, [ 1 ] = 2, [ 2 ] = 4, [ 3 ] = 5, [ 4 ] = 7 }

--- Number of bytes in the last incomplete block for each number of remaining characters, `nil` for impossible lengths.
---
---@type table<integer, integer>
local tail_bytes = { [ 0 ] = 0, [ 2 ] = 1, [ 4 ] = 2, [ 5 ] = 3, [ 7 ] = 4 }

--- Splits 5 bytes into 8 values ( 0 - 31 ).
---
---@param uint8_1 integer
---@param uint8_2 integer
---@param uint8_3 integer
---@param uint8_4 integer
---@param uint8_5 integer
---@return integer, integer, integer, integer, integer, integer, integer, integer
local function encode_block( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5 )
    return rbit_rshift( uint8_1, 3 ),
        rbit_bor( rbit_lshift( rbit_band( uint8_1, 0x07 ), 2 ), rbit_rshift( uint8_2, 6 ) ),
        rbit_band( rbit_rshift( uint8_2, 1 ), 0x1F ),
        rbit_bor( rbit_lshift( rbit_band( uint8_2, 0x01 ), 4 ), rbit_rshift( uint8_3, 4 ) ),
        rbit_bor( rbit_lshift( rbit_band( uint8_3, 0x0F ), 1 ), rbit_rshift( uint8_4, 7 ) ),
        rbit_band( rbit_rshift( uint8_4, 2 ), 0x1F ),
        rbit_bor( rbit_lshift( rbit_band( uint8_4, 0x03 ), 3 ), rbit_rshift( uint8_5, 5 ) ),
        rbit_band( uint8_5, 0x1F )
end

--- Joins 8 values ( 0 - 31 ) into 5 bytes.
---
---@param value_1 integer
---@param value_2 integer
---@param value_3 integer
---@param value_4 integer
---@param value_5 integer
---@param value_6 integer
---@param value_7 integer
---@param value_8 integer
---@return integer, integer, integer, integer, integer
local function decode_block( value_1, value_2, value_3, value_4, value_5, value_6, value_7, value_8 )
    return rbit_bor( rbit_lshift( value_1, 3 ), rbit_rshift( value_2, 2 ) ),
        rbit_bor( rbit_lshift( rbit_band( value_2, 0x03 ), 6 ), rbit_lshift( value_3, 1 ), rbit_rshift( value_4, 4 ) ),
        rbit_bor( rbit_lshift( rbit_band( value_4, 0x0F ), 4 ), rbit_rshift( value_5, 1 ) ),
        rbit_bor( rbit_lshift( rbit_band( value_5, 0x01 ), 7 ), rbit_lshift( value_6, 2 ), rbit_rshift( value_7, 3 ) ),
        rbit_bor( rbit_lshift( rbit_band( value_7, 0x07 ), 5 ), value_8 )
end

--- Checks the length and padding of a base32 string.
---
---@param base32_str string
---@param ignore_padding? boolean
---@return integer | nil data_length The length without padding, or `nil` if the string is invalid.
---@return nil | string err_msg The error message.
local function get_data_length( base32_str, ignore_padding )
    local str_length = string_len( base32_str )

    if ignore_padding ~= true and str_length % 8 ~= 0 then
        return nil, "string length must be a multiple of 8"
    end

    local data_length = str_length

    while data_length ~= 0 and string_byte( base32_str, data_length, data_length ) == 0x3D --[[ "=" ]] do
        data_length = data_length - 1
    end

    local remainder = data_length % 8

    if tail_bytes[ remainder ] == nil then
        return nil, "string has invalid length"
    end

    local padding = str_length - data_length

    if padding ~= 0 and (data_length == 0 or padding ~= (8 - remainder) % 8) then
        return nil, "string has invalid padding"
    end

    return data_length
end

--- Returns the position of the first character outside the alphabet.
---
---@param base32_str string
---@param decode_map table<integer, integer> | ffi.cdata*
---@param data_length integer
---@return integer | nil
local function find_invalid( base32_str, decode_map, data_length )
    for index = 1, data_length, 1 do
        if decode_map[ string_byte( base32_str, index, index ) ] < 0 then
            return index
        end
    end
end

---@type fun( str: string, str_length: integer, encode_map: table<integer, integer> | ffi.cdata*, do_padding: boolean ): string
local encode

---@type fun( str: string, data_length: integer, decode_map: table<integer, integer> | ffi.cdata* ): string | nil
local decode

if ffi == nil then

    function encode( str, str_length, encode_map, do_padding )
        local segments, segment_count = {}, 0
        local remainder = str_length % 5

        for index = 1, str_length - remainder, 5 do
            local value_1, value_2, value_3, value_4, value_5, value_6, value_7, value_8 = encode_block( string_byte( str, index, index + 4 ) )

            segment_count = segment_count + 1
            segments[ segment_count ] = string_char(
                encode_map[ value_1 ], encode_map[ value_2 ], encode_map[ value_3 ], encode_map[ value_4 ],
                encode_map[ value_5 ], encode_map[ value_6 ], encode_map[ value_7 ], encode_map[ value_8 ]
            )
        end

        if remainder ~= 0 then
            local index = str_length - remainder + 1
            local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, index, str_length )
            local value_1, value_2, value_3, value_4, value_5, value_6, value_7 = encode_block( uint8_1, uint8_2 or 0, uint8_3 or 0, uint8_4 or 0, 0 )

            local char_count = tail_chars[ remainder ]

            segment_count = segment_count + 1
            segments[ segment_count ] = string_sub( string_char(
                encode_map[ value_1 ], encode_map[ value_2 ], encode_map[ value_3 ], encode_map[ value_4 ],
                encode_map[ value_5 ], encode_map[ value_6 ], encode_map[ value_7 ]
            ), 1, char_count )

            if do_padding then
                segment_count = segment_count + 1
                segments[ segment_count ] = string_rep( "=", 8 - char_count )
            end
        end

        return table_concat( segments, "", 1, segment_count )
    end

    function decode( str, data_length, decode_map )
        local segments, segment_count = {}, 0
        local remainder = data_length % 8

        for index = 1, data_length - remainder, 8 do
            local uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 = string_byte( str, index, index + 7 )

            local value_1, value_2, value_3, value_4 = decode_map[ uint8_1 ], decode_map[ uint8_2 ], decode_map[ uint8_3 ], decode_map[ uint8_4 ]
            local value_5, value_6, value_7, value_8 = decode_map[ uint8_5 ], decode_map[ uint8_6 ], decode_map[ uint8_7 ], decode_map[ uint8_8 ]

            if rbit_bor( value_1, value_2, value_3, value_4, value_5, value_6, value_7, value_8 ) < 0 then
                return nil
            end

            segment_count = segment_count + 1
            segments[ segment_count ] = string_char( decode_block( value_1, value_2, value_3, value_4, value_5, value_6, value_7, value_8 ) )
        end

        if remainder ~= 0 then
            local index = data_length - remainder + 1
            local uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7 = string_byte( str, index, data_length )

            local value_1, value_2 = decode_map[ uint8_1 ], decode_map[ uint8_2 ]
            local value_3, value_4 = uint8_3 and decode_map[ uint8_3 ] or 0, uint8_4 and decode_map[ uint8_4 ] or 0
            local value_5, value_6, value_7 = uint8_5 and decode_map[ uint8_5 ] or 0, uint8_6 and decode_map[ uint8_6 ] or 0, uint8_7 and decode_map[ uint8_7 ] or 0

            if rbit_bor( value_1, value_2, value_3, value_4, value_5, value_6, value_7 ) < 0 then
                return nil
            end

            segment_count = segment_count + 1
            segments[ segment_count ] = string_sub( string_char( decode_block( value_1, value_2, value_3, value_4, value_5, value_6, value_7, 0 ) ), 1, tail_bytes[ remainder ] )
        end

        return table_concat( segments, "", 1, segment_count )
    end

else

    local ffi_cast = ffi.cast
    local ffi_string = ffi.string

    local uint8_ptr_t = ffi.typeof( "const uint8_t *" )
    local uint8_array_t = ffi.typeof( "uint8_t[?]" )

    -- larger outputs get a temporary buffer, so memory isn't held after one big call
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

    -- loops below do not allocate, so the GC cannot collect `str` while its data is read by pointer

    function encode( str, str_length, encode_map, do_padding )
        local remainder = str_length % 5
        local output = get_buffer( (str_length - remainder) * 8 / 5 + 8 )
        local source = ffi_cast( uint8_ptr_t, str )

        local length = 0

        for index = 0, str_length - remainder - 1, 5 do
            local value_1, value_2, value_3, value_4, value_5, value_6, value_7, value_8 = encode_block( source[ index ], source[ index + 1 ], source[ index + 2 ], source[ index + 3 ], source[ index + 4 ] )

            output[ length ] = encode_map[ value_1 ]
            output[ length + 1 ] = encode_map[ value_2 ]
            output[ length + 2 ] = encode_map[ value_3 ]
            output[ length + 3 ] = encode_map[ value_4 ]
            output[ length + 4 ] = encode_map[ value_5 ]
            output[ length + 5 ] = encode_map[ value_6 ]
            output[ length + 6 ] = encode_map[ value_7 ]
            output[ length + 7 ] = encode_map[ value_8 ]

            length = length + 8
        end

        if remainder ~= 0 then
            local index = str_length - remainder

            local value_1, value_2, value_3, value_4, value_5, value_6, value_7 = encode_block(
                source[ index ],
                remainder > 1 and source[ index + 1 ] or 0,
                remainder > 2 and source[ index + 2 ] or 0,
                remainder > 3 and source[ index + 3 ] or 0,
                0
            )

            output[ length ] = encode_map[ value_1 ]
            output[ length + 1 ] = encode_map[ value_2 ]
            output[ length + 2 ] = encode_map[ value_3 ]
            output[ length + 3 ] = encode_map[ value_4 ]
            output[ length + 4 ] = encode_map[ value_5 ]
            output[ length + 5 ] = encode_map[ value_6 ]
            output[ length + 6 ] = encode_map[ value_7 ]

            local char_count = tail_chars[ remainder ]

            if do_padding then
                for padding_index = length + char_count, length + 7, 1 do
                    output[ padding_index ] = 0x3D --[[ "=" ]]
                end

                length = length + 8
            else
                length = length + char_count
            end
        end

        return ffi_string( output, length )
    end

    function decode( str, data_length, decode_map )
        local remainder = data_length % 8
        local output = get_buffer( (data_length - remainder) * 5 / 8 + 5 )
        local source = ffi_cast( uint8_ptr_t, str )

        local length = 0

        for index = 0, data_length - remainder - 1, 8 do
            local value_1, value_2, value_3, value_4 = decode_map[ source[ index ] ], decode_map[ source[ index + 1 ] ], decode_map[ source[ index + 2 ] ], decode_map[ source[ index + 3 ] ]
            local value_5, value_6, value_7, value_8 = decode_map[ source[ index + 4 ] ], decode_map[ source[ index + 5 ] ], decode_map[ source[ index + 6 ] ], decode_map[ source[ index + 7 ] ]

            if rbit_bor( value_1, value_2, value_3, value_4, value_5, value_6, value_7, value_8 ) < 0 then
                return nil
            end

            local uint8_1, uint8_2, uint8_3, uint8_4, uint8_5 = decode_block( value_1, value_2, value_3, value_4, value_5, value_6, value_7, value_8 )

            output[ length ] = uint8_1
            output[ length + 1 ] = uint8_2
            output[ length + 2 ] = uint8_3
            output[ length + 3 ] = uint8_4
            output[ length + 4 ] = uint8_5

            length = length + 5
        end

        if remainder ~= 0 then
            local index = data_length - remainder

            local value_1, value_2 = decode_map[ source[ index ] ], decode_map[ source[ index + 1 ] ]
            local value_3, value_4 = remainder > 2 and decode_map[ source[ index + 2 ] ] or 0, remainder > 3 and decode_map[ source[ index + 3 ] ] or 0
            local value_5 = remainder > 4 and decode_map[ source[ index + 4 ] ] or 0
            local value_6, value_7 = remainder > 5 and decode_map[ source[ index + 5 ] ] or 0, remainder > 6 and decode_map[ source[ index + 6 ] ] or 0

            if rbit_bor( value_1, value_2, value_3, value_4, value_5, value_6, value_7 ) < 0 then
                return nil
            end

            local uint8_1, uint8_2, uint8_3, uint8_4 = decode_block( value_1, value_2, value_3, value_4, value_5, value_6, value_7, 0 )

            output[ length ] = uint8_1
            output[ length + 1 ] = uint8_2
            output[ length + 2 ] = uint8_3
            output[ length + 3 ] = uint8_4

            length = length + tail_bytes[ remainder ]
        end

        return ffi_string( output, length )
    end

end

--- [SHARED AND MENU]
---
--- Encodes the specified string to base32.
---
---@param raw_str string The string to encode.
---@param ignore_padding? boolean Whether to ignore padding.
---@param alphabet? "standard" | "extended" | dreamwork.std.base32.Alphabet The alphabet to use.
---@return string base32_str The encoded string.
function base32.encode( raw_str, ignore_padding, alphabet )
    local str_length = string_len( raw_str )

    if str_length == 0 then
        return raw_str
    end

    return encode( raw_str, str_length, get_alphabet( alphabet )[ 1 ], ignore_padding ~= true )
end

--- [SHARED AND MENU]
---
--- Decodes the specified base32 encoded string.
---
--- Throws an error if the string has invalid length, padding or characters.
---
---@param base32_str string The base32 encoded string to decode.
---@param ignore_padding? boolean Whether padding is optional.
---@param alphabet? "standard" | "extended" | dreamwork.std.base32.Alphabet The alphabet to use.
---@return string raw_str The decoded string.
function base32.decode( base32_str, ignore_padding, alphabet )
    local data_length, err_msg = get_data_length( base32_str, ignore_padding )

    if data_length == nil then
        error( err_msg, 2 )
    elseif data_length == 0 then
        return ""
    end

    local decode_map = get_alphabet( alphabet )[ 2 ]

    local raw_str = decode( base32_str, data_length, decode_map )

    if raw_str == nil then
        error( "string contains invalid character at position " .. find_invalid( base32_str, decode_map, data_length ), 2 )
    end

    return raw_str
end

--- [SHARED AND MENU]
---
--- Checks if the specified base32 encoded string is valid.
---
---@param base32_str string The base32 encoded string to check.
---@param ignore_padding? boolean Whether padding is optional.
---@param alphabet? "standard" | "extended" | dreamwork.std.base32.Alphabet The alphabet to use.
---@return boolean is_valid `true` if the base32 string is valid, `false` otherwise
---@return nil | string err_msg The error message.
function base32.validate( base32_str, ignore_padding, alphabet )
    local data_length, err_msg = get_data_length( base32_str, ignore_padding )

    if data_length == nil then
        return false, err_msg
    elseif data_length == 0 then
        return false, "string cannot be empty"
    end

    if find_invalid( base32_str, get_alphabet( alphabet )[ 2 ], data_length ) ~= nil then
        return false, "string contains invalid characters"
    end

    return true
end
