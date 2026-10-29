local std = dreamwork.std

local raw = std.raw

local rbit = raw.bit
local rbit_bxor = rbit.bxor
local rbit_lshift = rbit.lshift

local math = std.math
local math_range = math.range

local table = std.table
local table_concat = table.concat

---@class dreamwork.std.string
local string = std.string
local string_sub = string.sub
local string_len = string.len
local string_char = string.char
local string_byte = string.byte

local bytepack = std.bytepack
local bytepack_readHex8 = bytepack.readHex8
local bytepack_writeHex8 = bytepack.writeHex8

do

    ---@type table<integer, string>
    local escape_sequences = {
        [ 0x5C ] = "\\\\",
        [ 0x07 ] = "\\a",
        [ 0x08 ] = "\\b",
        [ 0x0C ] = "\\f",
        [ 0x0A ] = "\\n",
        [ 0x0D ] = "\\r",
        [ 0x09 ] = "\\t",
        [ 0x0B ] = "\\v",
        [ 0x22 ] = "\\\"",
        [ 0x27 ] = "\\\'"
    }

    --- [SHARED AND MENU]
    ---
    --- Escapes special characters in a string.
    ---
    --- Within the given range, any byte that has a known escape sequence (e.g. newline, tab, quote, backslash etc.) is replaced with that sequence.
    ---
    --- Any other byte that is a control character (below `0x20`, or below `0x21` i.e. including the space
    --- character when `escape_spaces` is `true`) or is outside the printable ASCII range (`0x7F` and above) is replaced with a `\xHH` hexadecimal escape.
    ---
    --- All other bytes, and anything outside `start_position`/`end_position`, are left untouched.
    ---
    ---@see string.unescape
    ---
    ---@param str string The string to escape.
    ---@param escape_spaces? boolean Whether the space character (`0x20`) should also be escaped as `\x20`. Defaults to `false`.
    ---@param start_position? integer The position to start escaping from, inclusive. Negative values count from the end of the string. Defaults to `1` (the start of the string).
    ---@param end_position? integer The position to stop escaping at, inclusive. Negative values count from the end of the string. Defaults to the end of the string.
    ---@return string escaped_str The string with special characters escaped.
    ---@nodiscard
    function string.escape( str, escape_spaces, start_position, end_position )
        local str_length = string_len( str )
        if str_length == 0 then
            return str
        end

        local start_index, end_index = math_range( str_length, start_position, end_position )

        -- first byte not yet copied into `segments`, bytes before `start_position` are copied as is
        local sequence_position = 1
        local segments, segment_count = {}, 0

        local in_range = escape_spaces and 0x21 or 0x20

        for index = start_index, end_index, 1 do
            local uint8 = string_byte( str, index, index )
            local escape_sequence = escape_sequences[ uint8 ]
            if escape_sequence ~= nil then
                segment_count = segment_count + 1
                segments[ segment_count ] = string_sub( str, sequence_position, index - 1 ) .. escape_sequence
                sequence_position = index + 1
            elseif uint8 < in_range or uint8 > 0x7E then
                segment_count = segment_count + 1
                segments[ segment_count ] = string_sub( str, sequence_position, index - 1 ) .. string_char( 0x5C, 0x78, bytepack_writeHex8( uint8 ) )
                sequence_position = index + 1
            end
        end

        if segment_count == 0 then
            return str
        end

        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( str, sequence_position, str_length )

        return table_concat( segments, "", 1, segment_count )
    end

end

do

    ---@type table<integer, string>
    local unescape_sequences = {
        [ 0x5C ] = "\\",
        [ 0x61 ] = "\a",
        [ 0x62 ] = "\b",
        [ 0x66 ] = "\f",
        [ 0x6E ] = "\n",
        [ 0x72 ] = "\r",
        [ 0x74 ] = "\t",
        [ 0x76 ] = "\v",
        [ 0x22 ] = "\"",
        [ 0x27 ] = "\'"
    }

    --- [SHARED AND MENU]
    ---
    --- Unescapes special characters in a string.
    ---
    --- The inverse of `string.escape`.
    ---
    --- Within the given range, recognized escape sequences (e.g. `\n`, `\t`, `\"`, `\\` etc.)
    --- are converted back into their raw byte, and `\xHH` hexadecimal escapes are decoded into the byte they represent.
    ---
    --- Any other byte, and anything outside `start_position`/`end_position`, is left untouched.
    ---
    ---@see string.escape
    ---
    ---@param escaped_str string The string to unescape.
    ---@param start_position? integer The position to start unescaping from, inclusive. Negative values count from the end of the string. Defaults to `1` (the start of the string).
    ---@param end_position? integer The position to stop unescaping at, inclusive. Negative values count from the end of the string. Defaults to the end of the string.
    ---@return string str The unescaped string.
    ---@nodiscard
    function string.unescape( escaped_str, start_position, end_position )
        local str_length = string_len( escaped_str )
        if str_length == 0 then
            return escaped_str
        end

        local start_index, end_index = math_range( str_length, start_position, end_position )

        -- first byte not yet copied into `segments`, bytes before `start_position` are copied as is
        local copy_position = 1
        local segments, segment_count = {}, 0

        -- a sequence is at least 2 bytes long and has to fit into the range, so the last byte can't start one
        while start_index < end_index do
            if string_byte( escaped_str, start_index, start_index ) == 0x5C --[[ "\" ]] then
                local uint8_2 = string_byte( escaped_str, start_index + 1, start_index + 1 )

                ---@type string | nil
                local unescape_sequence

                -- unknown sequences are skipped as a whole and left as is
                local sequence_length = 2

                if uint8_2 == 0x78 --[[ "x" ]] then
                    if start_index + 3 <= end_index then
                        local decoded_uint8 = bytepack_readHex8( string_byte( escaped_str, start_index + 2, start_index + 3 ) )
                        if decoded_uint8 ~= nil then
                            unescape_sequence = string_char( decoded_uint8 )
                            sequence_length = 4
                        end
                    end
                else
                    unescape_sequence = unescape_sequences[ uint8_2 ]
                end

                if unescape_sequence ~= nil then
                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_sub( escaped_str, copy_position, start_index - 1 ) .. unescape_sequence
                    copy_position = start_index + sequence_length
                end

                start_index = start_index + sequence_length
            else
                start_index = start_index + 1
            end
        end

        if segment_count == 0 then
            return escaped_str
        end

        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( escaped_str, copy_position, str_length )

        return table_concat( segments, "", 1, segment_count )
    end

end


--- [SHARED AND MENU]
---
--- Returns the Fowler-Noll-Vo (FNV-0) [deprecated] hash of the string.
---
--- [Wiki Page](https://en.wikipedia.org/wiki/Fowler–Noll–Vo_hash_function)
---
---@param str string The string used to calculate the Fowler-Noll-Vo hash.
---@return integer hash_int The Fowler-Noll-Vo hash, which is greater or equal to 0, and less than 2^32 (0x100000000).
---@nodiscard
function string.fnv0( str )
    local hash_int = 0

    for index = 1, string_len( str ), 1 do
        hash_int = hash_int + rbit_lshift( hash_int, 1 ) + rbit_lshift( hash_int, 4 ) + rbit_lshift( hash_int, 7 ) + rbit_lshift( hash_int, 8 ) + rbit_lshift( hash_int, 24 )
        hash_int = rbit_bxor( hash_int, string_byte( str, index, index ) )
    end

    return hash_int % 0x100000000
end

--- [SHARED AND MENU]
---
--- Returns the Fowler-Noll-Vo (FNV-1) hash of the string.
---
--- [Wiki Page](https://en.wikipedia.org/wiki/Fowler–Noll–Vo_hash_function)
---
---@param str string The string used to calculate the Fowler-Noll-Vo hash.
---@return integer hash_int The Fowler-Noll-Vo hash, which is greater or equal to 0, and less than 2^32 (0x100000000).
---@nodiscard
function string.fnv1( str )
    local hash_int = 0x811c9dc5

    for index = 1, string_len( str ), 1 do
        hash_int = hash_int + rbit_lshift( hash_int, 1 ) + rbit_lshift( hash_int, 4 ) + rbit_lshift( hash_int, 7 ) + rbit_lshift( hash_int, 8 ) + rbit_lshift( hash_int, 24 )
        hash_int = rbit_bxor( hash_int, string_byte( str, index, index ) )
    end

    return hash_int % 0x100000000
end

--- [SHARED AND MENU]
---
--- Returns the Fowler-Noll-Vo (FNV-1a) hash of the string.
---
--- [Wiki Page](https://en.wikipedia.org/wiki/Fowler–Noll–Vo_hash_function)
---
---@param str string The string used to calculate the Fowler-Noll-Vo hash.
---@return integer hash_int The Fowler-Noll-Vo hash, which is greater or equal to 0, and less than 2^32 (0x100000000).
---@nodiscard
function string.fnv1a( str )
    local hash_int = 0x811c9dc5

    for index = 1, string_len( str ), 1 do
        hash_int = rbit_bxor( hash_int, string_byte( str, index, index ) )
        hash_int = hash_int + rbit_lshift( hash_int, 1 ) + rbit_lshift( hash_int, 4 ) + rbit_lshift( hash_int, 7 ) + rbit_lshift( hash_int, 8 ) + rbit_lshift( hash_int, 24 )
    end

    return hash_int % 0x100000000
end
