---@class dreamwork.std
local std = dreamwork.std

local ffi = std.ffi

local raw = std.raw
local raw_pairs = raw.pairs

local math = std.math
local math_max = math.max

local string = std.string
local string_len = string.len
local string_sub = string.sub
local string_format = string.format
local string_byte, string_char = string.byte, string.char
local string_find, string_gsub = string.find, string.gsub

local table = std.table
local table_concat = table.concat


--- [SHARED AND MENU]
---
--- Base16 (hexadecimal) encoding/decoding library.
---
--- See https://en.wikipedia.org/wiki/Hexadecimal
---
---@class dreamwork.std.base16
local base16 = {}
std.base16 = base16

---@type table<integer, integer>
local hex_values = {}

for index = 0, 9, 1 do
    hex_values[ 0x30 + index ] = index -- 0-9
end

for index = 0, 5, 1 do
    hex_values[ 0x41 + index ] = 10 + index -- A-F
    hex_values[ 0x61 + index ] = 10 + index -- a-f
end

---@type fun( str: string ): string
local encode

---@type fun( str: string ): string
local decode

if ffi == nil then

    --- Maps a byte to its two hex characters
    ---@type table<integer, string>
    local encode_map = {}

    for uint8 = 0, 255, 1 do
        encode_map[ uint8 ] = string_format( "%02X", uint8 )
    end

    --- Maps two hex characters ( `uint8_1 * 256 + uint8_2` ) to the decoded byte as a string
    ---@type table<integer, string>
    local decode_map = {}

    for uint8_1, value_1 in raw_pairs( hex_values ) do
        for uint8_2, value_2 in raw_pairs( hex_values ) do
            decode_map[ uint8_1 * 256 + uint8_2 ] = string_char( value_1 * 16 + value_2 )
        end
    end

    function encode( str )
        local segments, segment_count = {}, 0

        for index = 1, string_len( str ), 1 do
            segment_count = segment_count + 1
            segments[ segment_count ] = encode_map[ string_byte( str, index, index ) ]
        end

        return table_concat( segments, "", 1, segment_count )
    end

    function decode( str )
        local str_length = string_len( str )
        local segments, segment_count = {}, 0

        for index = 1, str_length - 1, 2 do
            local uint8_1, uint8_2 = string_byte( str, index, index + 1 )
            segment_count = segment_count + 1
            segments[ segment_count ] = decode_map[ uint8_1 * 256 + uint8_2 ] or string_char( uint8_1, uint8_2 )
        end

        if str_length % 2 == 1 then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_sub( str, str_length, str_length )
        end

        return table_concat( segments, "", 1, segment_count )
    end

else

    local ffi_cast = ffi.cast
    local ffi_string = ffi.string

    local rbit = raw.bit
    local rbit_bor = rbit.bor
    local rbit_lshift = rbit.lshift

    local uint8_ptr_t = ffi.typeof( "const uint8_t *" )
    local uint16_ptr_t = ffi.typeof( "uint16_t *" )
    local uint8_array_t = ffi.typeof( "uint8_t[?]" )

    -- Maps a byte to its two hex characters packed in native byte order.
    local encode_map = ffi.new( "uint16_t[256]" )
    local is_little_endian = ffi.abi( "le" )

    for uint8 = 0, 255, 1 do
        local uint8_1, uint8_2 = string_byte( string_format( "%02X", uint8 ), 1, 2 )

        if is_little_endian then
            encode_map[ uint8 ] = uint8_2 * 256 + uint8_1
        else
            encode_map[ uint8 ] = uint8_1 * 256 + uint8_2
        end
    end

    -- Maps a hex character to its value, `-1` for non-hex characters
    local decode_map = ffi.new( "int8_t[256]", -1 )

    for uint8, value in raw_pairs( hex_values ) do
        decode_map[ uint8 ] = value
    end

    -- Larger outputs get a temporary buffer, so memory isn't held after one big call
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

    -- loops below do not allocate, so the GC cannot collect `str` while its data is read by pointer.

    function encode( str )
        local str_length = string_len( str )
        local output = get_buffer( str_length * 2 )

        local source = ffi_cast( uint8_ptr_t, str )
        local target = ffi_cast( uint16_ptr_t, output )

        for index = 0, str_length - 1, 1 do
            target[ index ] = encode_map[ source[ index ] ]
        end

        return ffi_string( output, str_length * 2 )
    end

    function decode( str )
        local str_length = string_len( str )
        local output = get_buffer( str_length )

        local source = ffi_cast( uint8_ptr_t, str )
        local length = 0

        for index = 0, str_length - 2, 2 do
            local uint8_1, uint8_2 = source[ index ], source[ index + 1 ]
            local value_1, value_2 = decode_map[ uint8_1 ], decode_map[ uint8_2 ]

            if rbit_bor( value_1, value_2 ) < 0 then
                output[ length ] = uint8_1
                output[ length + 1 ] = uint8_2
                length = length + 2
            else
                output[ length ] = rbit_bor( rbit_lshift( value_1, 4 ), value_2 )
                length = length + 1
            end
        end

        if str_length % 2 == 1 then
            output[ length ] = source[ str_length - 1 ]
            length = length + 1
        end

        return ffi_string( output, length )
    end

end

--- [SHARED AND MENU]
---
--- Encodes the specified string to base16 (upper-case).
---
---@param raw_str string The string to encode.
---@return string base16_str The encoded string.
function base16.encode( raw_str )
    if string_byte( raw_str, 1 ) == nil then
        return raw_str
    end

    return encode( raw_str )
end

--- [SHARED AND MENU]
---
--- Decodes the specified base16 string to a string.
---
--- Pairs that are not valid hex digits and a trailing odd character are copied as-is, use `base16.validate` to reject them.
---
---@param base16_str string The base16 string to decode.
---@param start_position? integer The start position of the base16 string, default is `1`.
---@param end_position? integer The end position of the base16 string, default is the length of the base16 string.
---@return string raw_str The decoded string.
function base16.decode( base16_str, start_position, end_position )
    if string_byte( base16_str, 1 ) == nil then
        return base16_str
    end

    return decode( base16_str )
end

--- [SHARED AND MENU]
---
--- Validates the specified base16 string.
---
---@param base16_str string The base16 string to validate.
---@return boolean is_valid `true` if the base16 string is valid, otherwise `false`.
---@return nil | string err_msg The error message.
function base16.validate( base16_str )
    local str_length = string_len( base16_str )

    if str_length == 0 then
        return false, "string cannot be empty"
    end

    if str_length % 2 ~= 0 then
        return false, "string length must be even"
    end

    if string_find( base16_str, "[^0-9A-Fa-f]" ) ~= nil then
        return false, "string contains invalid characters"
    end

    return true
end

--- [SHARED AND MENU]
---
--- Escapes the specified base16 string.
---
--- Escape sequence: `\xXX`
---
---@param base16_str string The base16 string to escape.
---@return string base16_escape_str The escaped base16 string.
function base16.escape( base16_str )
    if string_byte( base16_str, 1 ) == nil then
        return base16_str
    end

    return (string_gsub( base16_str, "..?", "\\x%0" ))
end

--- [SHARED AND MENU]
---
--- Unescapes the specified base16 string.
---
--- Unescape sequence: `\xXX`
---
---@param base16_escape_str string The base16 string to unescape.
---@return string base16_str The unescaped base16 string.
function base16.unescape( base16_escape_str )
    if string_byte( base16_escape_str, 1 ) == nil then
        return base16_escape_str
    end

    return (string_gsub( base16_escape_str, "\\x(..?)", "%1" ))
end
