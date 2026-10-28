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
local string_match = string.match
local string_format = string.format
local string_char, string_byte = string.char, string.byte

local table = std.table
local table_concat = table.concat


--- [SHARED AND MENU]
---
--- Percent (URL/URI) encoding/decoding library.
---
--- Percent-encoding is a mechanism to encode 8-bit characters that have specific meaning in the context of URLs.
---
--- It is sometimes called **URL encoding**.
---
--- The encoding consists of substitution: A '%' followed by the hexadecimal representation of the ASCII value of the replace character.
---
--- See https://en.wikipedia.org/wiki/Percent-encoding & https://datatracker.ietf.org/doc/html/rfc3986#section-2.1
---
---@class dreamwork.std.percent
local percent = {}
std.percent = percent


--- [SHARED AND MENU]
---
--- Creates a character whitelist for the given pattern.
---
---@param pattern_str string The pattern.
---@param base? table The base table, optional.
---@return table<integer, boolean> whitelist The character whitelist.
---@nodiscard
function percent.whitelist( pattern_str, base )
    local whitelist = {}

    if base ~= nil then
        for uint8 in raw_pairs( base ) do
            whitelist[ uint8 ] = true
        end
    end

    pattern_str = "[" .. pattern_str .. "]"

    for uint8 = 0, 255, 1 do
        if string_match( string_char( uint8 ), pattern_str ) ~= nil then
            whitelist[ uint8 ] = true
        end
    end

    return whitelist
end

local default_whitelist = percent.whitelist( "%w%-_%.~" )

---@type table<integer, integer>
local hex_values = {}

for index = 0, 9, 1 do
    hex_values[ 0x30 + index ] = index -- 0-9
end

for index = 0, 5, 1 do
    hex_values[ 0x41 + index ] = 10 + index -- A-F
    hex_values[ 0x61 + index ] = 10 + index -- a-f
end

---@type fun( raw_str: string, whitelist: table<integer, boolean>, space_as_plus: boolean ): string
local encode

---@type fun( percent_str: string, plus_as_space: boolean, percent_str_length: integer ): string
local decode

if ffi == nil then

    --- Maps a byte to its `"%XX"` escape sequence
    ---@type table<integer, string>
    local escape_map = {}

    --- Maps a byte to its one character string
    ---@type table<integer, string>
    local char_map = {}

    for uint8 = 0, 255, 1 do
        escape_map[ uint8 ] = string_format( "%%%02X", uint8 )
        char_map[ uint8 ] = string_char( uint8 )
    end

    -- whitelisted runs are copied with `string.sub` instead of byte by byte

    function encode( raw_str, whitelist, space_as_plus )
        local raw_str_length = string_len( raw_str )
        local segments, segment_count = {}, 0
        local run_start = 1

        for position = 1, raw_str_length, 1 do
            local uint8 = string_byte( raw_str, position, position )
            if not whitelist[ uint8 ] then
                if run_start ~= position then
                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_sub( raw_str, run_start, position - 1 )
                end

                segment_count = segment_count + 1

                if space_as_plus and uint8 == 0x20 --[[ " " ]] then
                    segments[ segment_count ] = "+"
                else
                    segments[ segment_count ] = escape_map[ uint8 ]
                end

                run_start = position + 1
            end
        end

        if run_start == 1 then
            return raw_str
        end

        if run_start <= raw_str_length then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_sub( raw_str, run_start, raw_str_length )
        end

        return table_concat( segments, "", 1, segment_count )
    end

    function decode( percent_str, plus_as_space )
        local percent_str_length = string_len( percent_str )

        local segments, segment_count = {}, 0
        local position, run_start = 1, 1

        while position <= percent_str_length do
            local uint8 = string_byte( percent_str, position, position )
            if uint8 == 0x25 --[[ "%" ]] and position + 2 <= percent_str_length then
                local uint8_1, uint8_2 = string_byte( percent_str, position + 1, position + 2 )
                local value_1, value_2 = hex_values[ uint8_1 ], hex_values[ uint8_2 ]

                if value_1 == nil or value_2 == nil then
                    -- invalid sequences are kept as is
                    position = position + 1
                else
                    if run_start ~= position then
                        segment_count = segment_count + 1
                        segments[ segment_count ] = string_sub( percent_str, run_start, position - 1 )
                    end

                    segment_count = segment_count + 1
                    segments[ segment_count ] = char_map[ value_1 * 16 + value_2 ]

                    position = position + 3
                    run_start = position
                end
            elseif plus_as_space and uint8 == 0x2B --[[ "+" ]] then
                if run_start ~= position then
                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_sub( percent_str, run_start, position - 1 )
                end

                segment_count = segment_count + 1
                segments[ segment_count ] = " "

                position = position + 1
                run_start = position
            else
                position = position + 1
            end
        end

        if run_start == 1 then
            return percent_str
        end

        if run_start <= percent_str_length then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_sub( percent_str, run_start, percent_str_length )
        end

        return table_concat( segments, "", 1, segment_count )
    end

else

    local ffi_cast = ffi.cast
    local ffi_string = ffi.string

    local rbit = raw.bit
    local rbit_bor = rbit.bor
    local rbit_band = rbit.band
    local rbit_lshift = rbit.lshift
    local rbit_rshift = rbit.rshift

    local uint8_ptr_t = ffi.typeof( "const uint8_t *" )
    local uint8_array_t = ffi.typeof( "uint8_t[?]" )

    -- Maps a nibble to its upper-case hex character
    local hex_chars = uint8_array_t( 16 )

    for nibble = 0, 15, 1 do
        hex_chars[ nibble ] = string_byte( string_format( "%X", nibble ), 1, 1 )
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

    -- loops below do not allocate, so the GC cannot collect the string while its data is read by pointer.

    function encode( raw_str, whitelist, space_as_plus )
        local raw_str_length = string_len( raw_str )
        local output = get_buffer( raw_str_length * 3 )

        local source = ffi_cast( uint8_ptr_t, raw_str )
        local length = 0

        for index = 0, raw_str_length - 1, 1 do
            local uint8 = source[ index ]
            if whitelist[ uint8 ] then
                output[ length ] = uint8
                length = length + 1
            elseif space_as_plus and uint8 == 0x20 --[[ " " ]] then
                output[ length ] = 0x2B --[[ "+" ]]
                length = length + 1
            else
                output[ length ] = 0x25 --[[ "%" ]]
                output[ length + 1 ] = hex_chars[ rbit_rshift( uint8, 4 ) ]
                output[ length + 2 ] = hex_chars[ rbit_band( uint8, 0x0F ) ]
                length = length + 3
            end
        end

        return ffi_string( output, length )
    end

    function decode( percent_str, plus_as_space )
        local percent_str_length = string_len( percent_str )
        local output = get_buffer( percent_str_length )

        local source = ffi_cast( uint8_ptr_t, percent_str )
        local length, index = 0, 0

        -- a "%" this close to the end can't start a full sequence
        local escape_limit = percent_str_length - 2

        while index < percent_str_length do
            local uint8 = source[ index ]
            if uint8 == 0x25 --[[ "%" ]] and index < escape_limit then
                local value_1, value_2 = decode_map[ source[ index + 1 ] ], decode_map[ source[ index + 2 ] ]
                if rbit_bor( value_1, value_2 ) < 0 then
                    -- invalid sequences are kept as is
                    output[ length ] = uint8
                    index = index + 1
                else
                    output[ length ] = rbit_bor( rbit_lshift( value_1, 4 ), value_2 )
                    index = index + 3
                end
            elseif plus_as_space and uint8 == 0x2B --[[ "+" ]] then
                output[ length ] = 0x20 --[[ " " ]]
                index = index + 1
            else
                output[ length ] = uint8
                index = index + 1
            end

            length = length + 1
        end

        return ffi_string( output, length )
    end

end

--- [SHARED AND MENU]
---
--- Encodes the specified string to percent encoding.
---
--- Bytes not in the whitelist are encoded as `"%XX"` (upper-case hex),
--- spaces are encoded as `"+"` unless `ignore_spaces` is `true`.
---
--- ```lua
--- percent.encode( "a b&c" ) -- "a+b%26c"
--- percent.encode( "a b&c", nil, true ) -- "a%20b%26c"
--- ```
---
---@param raw_str string The string to encode.
---@param whitelist? table<integer, boolean> The character whitelist, bytes in it are left as is, optional.
---@param ignore_spaces? boolean If `true`, spaces are encoded as `"%20"` instead of `"+"`, optional.
---@return string percent_str The encoded string.
---@nodiscard
function percent.encode( raw_str, whitelist, ignore_spaces )
    return encode( raw_str, whitelist or default_whitelist, ignore_spaces ~= true )
end

--- [SHARED AND MENU]
---
--- Decodes the specified string from percent encoding.
---
--- Invalid or incomplete `"%"` sequences are kept as is.
---
--- ```lua
--- percent.decode( "a+b%26c" ) -- "a b&c"
--- percent.decode( "a+b%26c", true ) -- "a+b&c"
--- ```
---
---@param percent_str string The string to decode.
---@param ignore_spaces? boolean If `true`, `"+"` is kept as is instead of being decoded as a space, optional.
---@return string raw_str The decoded string.
---@nodiscard
function percent.decode( percent_str, ignore_spaces )
    return decode( percent_str, ignore_spaces ~= true )
end

--- [SHARED AND MENU]
---
--- Validates the specified percent string.
---
--- A valid string contains only whitelisted bytes, complete `"%XX"` sequences
--- and, unless `ignore_spaces` is `true`, `"+"`.
---
---@param percent_str string The percent string to validate.
---@param whitelist? table<integer, boolean> The character whitelist, optional.
---@param ignore_spaces? boolean If `true`, `"+"` is not allowed unless whitelisted, optional.
---@return boolean is_valid `true` if the percent string is valid, otherwise `false`.
---@return nil | string err_msg The error message.
---@nodiscard
function percent.validate( percent_str, whitelist, ignore_spaces )
    if whitelist == nil then
        whitelist = default_whitelist
    end

    local percent_str_length = string_len( percent_str )
    local plus_as_space = ignore_spaces ~= true
    local position = 1

    while position <= percent_str_length do
        local uint8 = string_byte( percent_str, position, position )
        if uint8 == 0x25 --[[ "%" ]] then
            if position + 2 > percent_str_length then
                return false, "incomplete percent sequence at position " .. position
            end

            local uint8_1, uint8_2 = string_byte( percent_str, position + 1, position + 2 )
            if hex_values[ uint8_1 ] == nil or hex_values[ uint8_2 ] == nil then
                return false, "invalid percent sequence at position " .. position
            end

            position = position + 3
        elseif whitelist[ uint8 ] or (plus_as_space and uint8 == 0x2B --[[ "+" ]]) then
            position = position + 1
        else
            return false, "invalid character at position " .. position
        end
    end

    return true
end
