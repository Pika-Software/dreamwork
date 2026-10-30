---@class dreamwork.std
local std = dreamwork.std

local ffi = std.ffi
local error = std.error

local raw = std.raw
local raw_type = raw.type

local rbit = raw.bit
local rbit_band, rbit_bor = rbit.band, rbit.bor
local rbit_lshift, rbit_rshift = rbit.lshift, rbit.rshift

local math = std.math
local math_min, math_max = math.min, math.max
local math_floor = math.floor

local table = std.table
local table_concat = table.concat
local table_unpack = table.unpack

local string = std.string
local string_len = string.len
local string_char = string.char
local string_byte = string.byte


--- [SHARED AND MENU]
---
--- Lempel–Ziv–Welch (LZW) is a universal lossless compression algorithm created by Abraham Lempel, Jacob Ziv, and Terry Welch.
---
---@class dreamwork.std.lzw
local lzw = {}
std.lzw = lzw

---@param options dreamwork.std.lzw.Options | nil
---@return dreamwork.std.lzw.Format | nil format
---@return nil | string error_message
local function get_format( options )
    if options == nil then
        options = {}
    elseif raw_type( options ) ~= "table" then
        return nil, "options must be a table"
    end

    local bit_order = options.bit_order
    if not (bit_order == nil or bit_order == "msb" or bit_order == "lsb") then
        return nil, "options.bit_order must be \"msb\" or \"lsb\""
    end

    local literal_bits = options.literal_bits or 8
    if not (raw_type( literal_bits ) == "number" and literal_bits % 1 == 0 and literal_bits >= 1 and literal_bits <= 8) then
        return nil, "options.literal_bits must be an integer from 1 to 8"
    end

    local literal_count = 2 ^ literal_bits
    local first = literal_count

    local clear
    if options.clear_code then
        clear, first = first, first + 1
    end

    local finish
    if options.end_code then
        finish, first = first, first + 1
    end

    local early = options.early_change and 1 or 0

    -- the smallest width that holds every reserved code without growing right away
    local min_width = literal_bits + 1
    while (first + early) >= (2 ^ min_width) do
        min_width = min_width + 1
    end

    local max_width = options.max_width or 16
    if not (raw_type( max_width ) == "number" and max_width % 1 == 0 and max_width >= min_width and max_width <= 16) then
        return nil, "options.max_width must be an integer from " .. min_width .. " to 16"
    end

    local on_full = options.on_full
    if not (on_full == nil or on_full == "reset" or on_full == "freeze") then
        return nil, "options.on_full must be \"reset\" or \"freeze\""
    end

    local symbol_bits, symbols, reverse, pad_byte = 8, nil, nil, nil

    local alphabet = options.alphabet
    if alphabet ~= nil then
        if raw_type( alphabet ) ~= "string" then
            return nil, "options.alphabet must be a string"
        end

        local alphabet_length = string_len( alphabet )

        symbol_bits = 1
        while 2 ^ symbol_bits < alphabet_length do
            symbol_bits = symbol_bits + 1
        end

        if (2 ^ symbol_bits) ~= alphabet_length or symbol_bits > 8 then
            return nil, "options.alphabet length must be a power of two from 2 to 256"
        end

        symbols, reverse = {}, {}

        for i = 1, alphabet_length, 1 do
            local byte = string_byte( alphabet, i )
            if reverse[ byte ] ~= nil then
                return nil, "options.alphabet has repeated characters"
            end

            symbols[ i - 1 ], reverse[ byte ] = byte, i - 1
        end

        local pad = options.pad
        if pad == nil then
            pad = "="
        end

        if pad ~= false then
            if not (raw_type( pad ) == "string" and string_len( pad ) == 1) then
                return nil, "options.pad must be a single character or false"
            end

            pad_byte = string_byte( pad )

            if reverse[ pad_byte ] ~= nil then
                return nil, "options.pad cannot be a character of options.alphabet"
            end
        end
    end

    -- characters per whole number of bytes, 4 for base64
    local pad_group = 8
    while pad_group % 2 == 0 and (pad_group / 2 * symbol_bits) % 8 == 0 do
        pad_group = pad_group / 2
    end

    return {
        msb = bit_order ~= "lsb",
        literal_count = literal_count,
        clear = clear,
        finish = finish,
        first = first,
        min_width = min_width,
        min_scale = 2 ^ min_width,
        max_scale = 2 ^ max_width,
        max_width = max_width,
        early = early,
        reset = on_full ~= "freeze",
        symbol_bits = symbol_bits,
        symbol_scale = 2 ^ symbol_bits,
        symbols = symbols,
        reverse = reverse,
        pad_byte = pad_byte,
        pad_group = pad_group
    }
end

-- Codes are stored together with their width as `width * 0x10000 + code` and packed with 32-bit shifts,
-- which stay exact because at most 16 + 7 bits are ever buffered.
--
-- The decoder reads code `n` with the dictionary state after code `n - 1`, while the encoder
-- adds the entry for code `n` right after writing it, so the encoder runs one entry ahead
-- and checks its width against `next_code - 1`.
--
-- A decoder entry is always the previous string plus the first byte of the next one, which is already
-- in the output, so entries are ( offset, length ) slices of it and never need to be built.

---@type fun( raw_data: string, data_length: integer, format: dreamwork.std.lzw.Format ): string | nil, string | nil
local compress

---@type fun( compressed_data: string, format: dreamwork.std.lzw.Format ): string | nil, string | nil
local decompress

---@param byte integer
---@param index integer
---@return string
local function literal_error( byte, index )
    return "byte " .. byte .. " at position " .. index .. " does not fit into options.literal_bits"
end

if ffi == nil then

    local CHUNK_SIZE = 4096

    ---@param out integer[]
    ---@param out_length integer
    ---@return string
    local function bytes_to_string( out, out_length )
        if out_length <= CHUNK_SIZE then
            return string_char( table_unpack( out, 1, out_length ) )
        end

        local chunks, chunk_count = {}, 0

        for i = 1, out_length, CHUNK_SIZE do
            chunk_count = chunk_count + 1
            chunks[ chunk_count ] = string_char( table_unpack( out, i, math_min( i + CHUNK_SIZE - 1, out_length ) ) )
        end

        return table_concat( chunks, "", 1, chunk_count )
    end

    -- The compression hash table holds codes in the array part, `0` is an empty slot (codes of entries are above the literals),
    -- `keys[ code ]` is `prefix code * 256 + byte` of the entry and `positions[ code ]` is its slot,
    -- so a new dictionary only empties the slots it used, the dictionary holds at most 2^16 entries,
    -- so these are always kept.

    ---@type integer[]
    local slots = {}
    local slots_size = 0

    ---@type integer[]
    local keys, positions = {}, {}

    ---@param first integer
    ---@param next_code integer
    local function empty_slots( first, next_code )
        for code = first, next_code - 1, 1 do
            slots[ positions[ code ] ] = 0
        end
    end

    --- Packs codes into a string, every code is `width * 0x10000 + code`.
    ---
    ---@param codes integer[]
    ---@param count integer
    ---@param format dreamwork.std.lzw.Format
    ---@return string
    local function pack( codes, count, format )
        local symbol_bits = format.symbol_bits
        local symbol_mask = format.symbol_scale - 1

        ---@type integer[]
        local out = {}
        local out_length = 0

        local buffer, bits = 0, 0

        if format.msb then
            -- bits above the buffered ones are shifted out of 32 bits or masked off
            if symbol_bits == 8 then
                for i = 1, count, 1 do
                    local entry = codes[ i ]
                    local width = rbit_rshift( entry, 16 )

                    buffer = rbit_bor( rbit_lshift( buffer, width ), rbit_band( entry, 0xFFFF ) )
                    bits = bits + width

                    -- both bytes are always written, only the whole ones are kept
                    out[ out_length + 1 ] = rbit_band( rbit_rshift( buffer, bits - 8 ), 0xFF )
                    out[ out_length + 2 ] = rbit_band( rbit_rshift( buffer, bits - 16 ), 0xFF )

                    out_length = out_length + rbit_rshift( bits, 3 )
                    bits = rbit_band( bits, 7 )
                end
            else
                for i = 1, count, 1 do
                    local entry = codes[ i ]
                    local width = rbit_rshift( entry, 16 )

                    buffer = rbit_bor( rbit_lshift( buffer, width ), rbit_band( entry, 0xFFFF ) )
                    bits = bits + width

                    while bits >= symbol_bits do
                        bits = bits - symbol_bits

                        out_length = out_length + 1
                        out[ out_length ] = rbit_band( rbit_rshift( buffer, bits ), symbol_mask )
                    end
                end
            end

            if bits ~= 0 then
                out_length = out_length + 1
                out[ out_length ] = rbit_band( rbit_lshift( buffer, symbol_bits - bits ), symbol_mask )
            end
        else
            if symbol_bits == 8 then
                for i = 1, count, 1 do
                    local entry = codes[ i ]

                    buffer = rbit_bor( buffer, rbit_lshift( rbit_band( entry, 0xFFFF ), bits ) )
                    bits = bits + rbit_rshift( entry, 16 )

                    out[ out_length + 1 ] = rbit_band( buffer, 0xFF )
                    out[ out_length + 2 ] = rbit_band( rbit_rshift( buffer, 8 ), 0xFF )

                    local whole = rbit_rshift( bits, 3 )
                    out_length = out_length + whole

                    buffer = rbit_rshift( buffer, whole * 8 )
                    bits = rbit_band( bits, 7 )
                end
            else
                for i = 1, count, 1 do
                    local entry = codes[ i ]

                    buffer = rbit_bor( buffer, rbit_lshift( rbit_band( entry, 0xFFFF ), bits ) )
                    bits = bits + rbit_rshift( entry, 16 )

                    while bits >= symbol_bits do
                        out_length = out_length + 1
                        out[ out_length ] = rbit_band( buffer, symbol_mask )

                        buffer = rbit_rshift( buffer, symbol_bits )
                        bits = bits - symbol_bits
                    end
                end
            end

            if bits ~= 0 then
                out_length = out_length + 1
                out[ out_length ] = buffer
            end
        end

        local symbols = format.symbols
        if symbols ~= nil then
            for i = 1, out_length, 1 do
                out[ i ] = symbols[ out[ i ] ]
            end

            local pad_byte = format.pad_byte
            if pad_byte ~= nil then
                local pad_group = format.pad_group

                while out_length % pad_group ~= 0 do
                    out_length = out_length + 1
                    out[ out_length ] = pad_byte
                end
            end
        end

        return bytes_to_string( out, out_length )
    end

    function compress( raw_data, data_length, format )
        local literal_count, clear, finish, first = format.literal_count, format.clear, format.finish, format.first
        local min_scale, max_scale, early, reset = format.min_scale, format.max_scale, format.early, format.reset

        -- encoders that send clear codes stop one entry short, like giflib and libtiff do
        local limit = max_scale
        if clear ~= nil and reset then
            limit = limit - 1
        end

        ---@type integer[]
        local codes = {}
        local count = 0

        local min_tag = format.min_width * 0x10000
        local width_tag, width_scale = min_tag, min_scale

        if clear ~= nil then
            count = 1
            codes[ 1 ] = width_tag + clear
        end

        if data_length ~= 0 then
            local code = string_byte( raw_data, 1 )
            if code >= literal_count then
                return nil, literal_error( code, 1 )
            end

            -- a dictionary holds fewer entries than the input has bytes, the load factor is kept at or below 1/4
            local entries = math_min( data_length, limit - first )

            local size = 512
            while size < entries * 4 do
                size = size * 2
            end

            -- slots are `1` - `size`, filled in order to stay in the array part
            for slot = slots_size + 1, size, 1 do
                slots[ slot ] = 0
            end

            slots_size = math_max( slots_size, size )

            local slots, keys, positions = slots, keys, positions
            local slot_mask = size - 1

            local next_code = first

            -- without a clear code the decoder resets one code later, after reading the next code with the old width
            local reset_width = false

            local index = 1

            while index ~= data_length do
                local byte, key, slot, found

                -- the match is extended as long as it is in the dictionary, so the common case gets its own trace
                repeat
                    index = index + 1

                    byte = string_byte( raw_data, index )
                    if byte >= literal_count then
                        empty_slots( first, next_code )
                        return nil, literal_error( byte, index )
                    end

                    key = rbit_lshift( code, 8 ) + byte
                    slot = rbit_band( code * 2053 + byte * 40503, slot_mask ) + 1

                    found = slots[ slot ]
                    if found ~= 0 and keys[ found ] ~= key then
                        repeat
                            slot = rbit_band( slot, slot_mask ) + 1
                            found = slots[ slot ]
                        until found == 0 or keys[ found ] == key
                    end

                    if found == 0 then
                        break
                    end

                    code = found
                until index == data_length

                if found == 0 then
                    count = count + 1
                    codes[ count ] = width_tag + code

                    if reset_width then
                        width_tag, width_scale, reset_width = min_tag, min_scale, false
                    end

                    if next_code < limit then
                        slots[ slot ], keys[ next_code ], positions[ next_code ] = next_code, key, slot
                        next_code = next_code + 1

                        if width_scale < max_scale and next_code - 1 + early >= width_scale then
                            width_tag, width_scale = width_tag + 0x10000, width_scale * 2
                        end

                        if next_code == limit and reset then
                            empty_slots( first, next_code )
                            next_code = first

                            if clear == nil then
                                reset_width = true
                            else
                                count = count + 1
                                codes[ count ] = width_tag + clear

                                width_tag, width_scale = min_tag, min_scale
                            end
                        end
                    end

                    code = byte
                end
            end

            empty_slots( first, next_code )

            count = count + 1
            codes[ count ] = width_tag + code

            if reset_width then
                width_tag, width_scale = min_tag, min_scale
            end

            -- nothing is added after the last code, so the decoder is no longer one entry behind
            if width_scale < max_scale and next_code + early >= width_scale then
                width_tag = width_tag + 0x10000
            end
        end

        if finish ~= nil then
            count = count + 1
            codes[ count ] = width_tag + finish
        end

        return pack( codes, count, format )
    end

    function decompress( compressed_data, format )
        local literal_count, clear, finish, first = format.literal_count, format.clear, format.finish, format.first
        local min_width, min_scale, max_scale, early, reset = format.min_width, format.min_scale, format.max_scale, format.early, format.reset
        local msb, symbol_bits, reverse = format.msb, format.symbol_bits, format.reverse

        -- without a clear code a full dictionary starts over by itself
        local implicit_reset = reset and clear == nil

        local data_length = string_len( compressed_data )

        local pad_byte = format.pad_byte
        if pad_byte ~= nil then
            while data_length ~= 0 and string_byte( compressed_data, data_length ) == pad_byte do
                data_length = data_length - 1
            end
        end

        ---@type integer[]
        local out = {}
        local out_length = 0

        ---@type integer[]
        local offsets, lengths = {}, {}

        local width, width_scale, next_code = min_width, min_scale, first

        ---@type integer | nil
        local last_offset
        local last_length = 0

        -- whole bytes are read two at a time while there are two left, this keeps at most 15 + 16 bits
        local wide = symbol_bits == 8 and reverse == nil

        local buffer, bits = 0, 0
        local index = 1

        while true do
            local exhausted = false

            if bits < width and wide and index < data_length then
                local byte1, byte2 = string_byte( compressed_data, index, index + 1 )

                if msb then
                    buffer = rbit_bor( rbit_lshift( buffer, 16 ), rbit_lshift( byte1, 8 ), byte2 )
                else
                    buffer = rbit_bor( buffer, rbit_lshift( rbit_bor( byte1, rbit_lshift( byte2, 8 ) ), bits ) )
                end

                index, bits = index + 2, bits + 16
            end

            while bits < width do
                if index > data_length then
                    exhausted = true
                    break
                end

                local symbol = string_byte( compressed_data, index )

                if reverse ~= nil then
                    symbol = reverse[ symbol ]
                    if symbol == nil then
                        return nil, "corrupt compressed data: invalid character at position " .. index
                    end
                end

                index = index + 1

                if msb then
                    buffer = rbit_bor( rbit_lshift( buffer, symbol_bits ), symbol )
                else
                    buffer = rbit_bor( buffer, rbit_lshift( symbol, bits ) )
                end

                bits = bits + symbol_bits
            end

            -- the rest are padding bits
            if exhausted then
                break
            end

            bits = bits - width

            local code

            if msb then
                code = rbit_band( rbit_rshift( buffer, bits ), width_scale - 1 )
            else
                code = rbit_band( buffer, width_scale - 1 )
                buffer = rbit_rshift( buffer, width )
            end

            if code == clear then
                width, width_scale, next_code, last_offset = min_width, min_scale, first, nil
            elseif code == finish then
                break
            else
                local offset = out_length + 1
                local source, length

                if code < literal_count then
                    out[ offset ] = code
                    length = 1
                elseif code >= first and code < next_code then
                    source, length = offsets[ code ], lengths[ code ]
                elseif code == next_code and last_offset ~= nil and next_code < max_scale then
                    -- the entry is being defined by this very code, copying forward fills it in
                    source, length = last_offset, last_length + 1
                else
                    return nil, "corrupt compressed data: unknown code " .. code
                end

                if source ~= nil then
                    source = source - offset

                    for j = offset, offset + length - 1, 1 do
                        out[ j ] = out[ source + j ]
                    end
                end

                out_length = out_length + length

                if last_offset ~= nil and next_code < max_scale then
                    offsets[ next_code ], lengths[ next_code ] = last_offset, last_length + 1
                    next_code = next_code + 1

                    if implicit_reset and next_code == max_scale then
                        width, width_scale, next_code = min_width, min_scale, first
                    elseif width_scale < max_scale and next_code + early >= width_scale then
                        width, width_scale = width + 1, width_scale * 2
                    end
                end

                last_offset, last_length = offset, length
            end
        end

        return bytes_to_string( out, out_length )
    end

else

    local ffi_cast = ffi.cast
    local ffi_copy = ffi.copy
    local ffi_string = ffi.string

    local uint8_ptr_t = ffi.typeof( "const uint8_t *" )
    local uint8_array_t = ffi.typeof( "uint8_t[?]" )
    local int32_array_t = ffi.typeof( "int32_t[?]" )

    --- Larger buffers are temporary, so memory isn't held after one big call.
    local max_buffer_size = 0x100000

    local bytes_size = 256
    local bytes = uint8_array_t( bytes_size )

    ---@param size integer
    ---@return ffi.cdata* buffer `uint8_t[?]`
    local function get_bytes( size )
        if size > bytes_size then
            if size > max_buffer_size then
                return uint8_array_t( size )
            end

            bytes_size = math_max( size, bytes_size * 2 )
            bytes = uint8_array_t( bytes_size )
        end

        return bytes
    end

    local codes_size = 256
    local codes = int32_array_t( codes_size )

    ---@param size integer
    ---@return ffi.cdata* buffer `int32_t[?]`
    local function get_codes( size )
        if size > codes_size then
            if size * 4 > max_buffer_size then
                return int32_array_t( size )
            end

            codes_size = math_max( size, codes_size * 2 )
            codes = int32_array_t( codes_size )
        end

        return codes
    end

    -- The compression hash table holds codes, `0` is an empty slot (codes of entries are above the literals),
    -- `keys[ code ]` is `prefix code * 256 + byte` of the entry and `positions[ code ]` is its slot,
    -- so a new dictionary only empties the slots it used, the dictionary holds at most 2^16 entries,
    -- so these are always kept.
    local uint16_array_t = ffi.typeof( "uint16_t[?]" )

    local slots_size = 512
    local slots = uint16_array_t( slots_size )

    local keys_size = 512
    local keys = int32_array_t( keys_size )
    local positions = int32_array_t( keys_size )

    ---@param first integer
    ---@param next_code integer
    local function empty_slots( first, next_code )
        for code = first, next_code - 1, 1 do
            slots[ positions[ code ] ] = 0
        end
    end

    -- decoder entries are ( offset, length ) pairs, they are always written before they are read,
    -- so this is never cleared
    local entries_size = 1024
    local entries = int32_array_t( entries_size )

    --- Packs codes into a string, every code is `width * 0x10000 + code`.
    ---
    ---@param codes ffi.cdata* `int32_t[?]`
    ---@param count integer
    ---@param format dreamwork.std.lzw.Format
    ---@return string
    local function pack( codes, count, format )
        local symbol_bits, pad_group = format.symbol_bits, format.pad_group
        local symbol_mask = format.symbol_scale - 1

        -- 2 spare bytes for the bytes that are written ahead
        local out = get_bytes( math_floor( count * format.max_width / symbol_bits ) + 3 + pad_group )
        local out_length = 0

        local buffer, bits = 0, 0

        if format.msb then
            -- bits above the buffered ones are shifted out of 32 bits or masked off
            if symbol_bits == 8 then
                for i = 0, count - 1, 1 do
                    local entry = codes[ i ]
                    local width = rbit_rshift( entry, 16 )

                    buffer = rbit_bor( rbit_lshift( buffer, width ), rbit_band( entry, 0xFFFF ) )
                    bits = bits + width

                    -- both bytes are always written, only the whole ones are kept
                    out[ out_length ] = rbit_rshift( buffer, bits - 8 )
                    out[ out_length + 1 ] = rbit_rshift( buffer, bits - 16 )

                    out_length = out_length + rbit_rshift( bits, 3 )
                    bits = rbit_band( bits, 7 )
                end
            else
                for i = 0, count - 1, 1 do
                    local entry = codes[ i ]
                    local width = rbit_rshift( entry, 16 )

                    buffer = rbit_bor( rbit_lshift( buffer, width ), rbit_band( entry, 0xFFFF ) )
                    bits = bits + width

                    while bits >= symbol_bits do
                        bits = bits - symbol_bits

                        out[ out_length ] = rbit_band( rbit_rshift( buffer, bits ), symbol_mask )
                        out_length = out_length + 1
                    end
                end
            end

            if bits ~= 0 then
                out[ out_length ] = rbit_band( rbit_lshift( buffer, symbol_bits - bits ), symbol_mask )
                out_length = out_length + 1
            end
        else
            if symbol_bits == 8 then
                for i = 0, count - 1, 1 do
                    local entry = codes[ i ]

                    buffer = rbit_bor( buffer, rbit_lshift( rbit_band( entry, 0xFFFF ), bits ) )
                    bits = bits + rbit_rshift( entry, 16 )

                    out[ out_length ] = buffer
                    out[ out_length + 1 ] = rbit_rshift( buffer, 8 )

                    local whole = rbit_rshift( bits, 3 )
                    out_length = out_length + whole

                    buffer = rbit_rshift( buffer, whole * 8 )
                    bits = rbit_band( bits, 7 )
                end
            else
                for i = 0, count - 1, 1 do
                    local entry = codes[ i ]

                    buffer = rbit_bor( buffer, rbit_lshift( rbit_band( entry, 0xFFFF ), bits ) )
                    bits = bits + rbit_rshift( entry, 16 )

                    while bits >= symbol_bits do
                        out[ out_length ] = rbit_band( buffer, symbol_mask )
                        out_length = out_length + 1

                        buffer = rbit_rshift( buffer, symbol_bits )
                        bits = bits - symbol_bits
                    end
                end
            end

            if bits ~= 0 then
                out[ out_length ] = buffer
                out_length = out_length + 1
            end
        end

        local symbols = format.symbols
        if symbols ~= nil then
            for i = 0, out_length - 1, 1 do
                out[ i ] = symbols[ out[ i ] ]
            end

            local pad_byte = format.pad_byte
            if pad_byte ~= nil then
                while out_length % pad_group ~= 0 do
                    out[ out_length ] = pad_byte
                    out_length = out_length + 1
                end
            end
        end

        return ffi_string( out, out_length )
    end

    function compress( raw_data, data_length, format )
        local literal_count, clear, finish, first = format.literal_count, format.clear, format.finish, format.first
        local min_scale, max_scale, early, reset = format.min_scale, format.max_scale, format.early, format.reset

        -- encoders that send clear codes stop one entry short, like giflib and libtiff do
        local limit = max_scale
        if clear ~= nil and reset then
            limit = limit - 1
        end

        -- one code per byte at most, plus a clear code after every full dictionary, the first clear, the last and the end codes
        local codes = get_codes( data_length + math_floor( data_length / (limit > first and limit - first or 1) ) + 3 )
        local count = 0

        local min_tag = format.min_width * 0x10000
        local width_tag, width_scale = min_tag, min_scale

        if clear ~= nil then
            codes[ 0 ] = width_tag + clear
            count = 1
        end

        if data_length ~= 0 then
            local input = ffi_cast( uint8_ptr_t, raw_data )

            local code = input[ 0 ]
            if code >= literal_count then
                return nil, literal_error( code, 1 )
            end

            -- a dictionary holds fewer entries than the input has bytes, the load factor is kept at or below 1/4
            local entries = math_min( data_length, limit - first )

            local size = 512
            while size < entries * 4 do
                size = size * 2
            end

            if slots_size < size then
                slots_size = size
                slots = uint16_array_t( slots_size )
            end

            if keys_size < limit then
                keys_size = limit
                keys, positions = int32_array_t( keys_size ), int32_array_t( keys_size )
            end

            local slots, keys, positions = slots, keys, positions
            local slot_mask = size - 1

            local next_code = first

            -- without a clear code the decoder resets one code later, after reading the next code with the old width
            local reset_width = false

            local index = 1

            while index ~= data_length do
                local byte, key, slot, found

                -- the match is extended as long as it is in the dictionary, so the common case gets its own trace
                repeat
                    byte = input[ index ]
                    if byte >= literal_count then
                        empty_slots( first, next_code )
                        return nil, literal_error( byte, index + 1 )
                    end

                    index = index + 1

                    key = rbit_lshift( code, 8 ) + byte
                    slot = rbit_band( code * 2053 + byte * 40503, slot_mask )

                    found = slots[ slot ]
                    if found ~= 0 and keys[ found ] ~= key then
                        repeat
                            slot = rbit_band( slot + 1, slot_mask )
                            found = slots[ slot ]
                        until found == 0 or keys[ found ] == key
                    end

                    if found == 0 then
                        break
                    end

                    code = found
                until index == data_length

                if found == 0 then
                    codes[ count ] = width_tag + code
                    count = count + 1

                    if reset_width then
                        width_tag, width_scale, reset_width = min_tag, min_scale, false
                    end

                    if next_code < limit then
                        slots[ slot ], keys[ next_code ], positions[ next_code ] = next_code, key, slot
                        next_code = next_code + 1

                        if width_scale < max_scale and next_code - 1 + early >= width_scale then
                            width_tag, width_scale = width_tag + 0x10000, width_scale * 2
                        end

                        if next_code == limit and reset then
                            empty_slots( first, next_code )
                            next_code = first

                            if clear == nil then
                                reset_width = true
                            else
                                codes[ count ] = width_tag + clear
                                count = count + 1

                                width_tag, width_scale = min_tag, min_scale
                            end
                        end
                    end

                    code = byte
                end
            end

            empty_slots( first, next_code )

            codes[ count ] = width_tag + code
            count = count + 1

            if reset_width then
                width_tag, width_scale = min_tag, min_scale
            end

            -- nothing is added after the last code, so the decoder is no longer one entry behind
            if width_scale < max_scale and next_code + early >= width_scale then
                width_tag = width_tag + 0x10000
            end
        end

        if finish ~= nil then
            codes[ count ] = width_tag + finish
            count = count + 1
        end

        return pack( codes, count, format )
    end

    function decompress( compressed_data, format )
        local literal_count, clear, finish, first = format.literal_count, format.clear, format.finish, format.first
        local min_width, min_scale, max_scale, early, reset = format.min_width, format.min_scale, format.max_scale, format.early, format.reset
        local msb, symbol_bits, reverse = format.msb, format.symbol_bits, format.reverse

        -- without a clear code a full dictionary starts over by itself
        local implicit_reset = reset and clear == nil

        local data_length = string_len( compressed_data )

        local pad_byte = format.pad_byte
        if pad_byte ~= nil then
            while data_length ~= 0 and string_byte( compressed_data, data_length ) == pad_byte do
                data_length = data_length - 1
            end
        end

        local input = ffi_cast( uint8_ptr_t, compressed_data )

        local capacity = data_length * 3 + 256
        local out = get_bytes( capacity )
        local out_length = 0

        if entries_size < max_scale * 2 then
            entries_size = max_scale * 2
            entries = int32_array_t( entries_size )
        end

        local entries = entries

        local width, width_scale, next_code = min_width, min_scale, first

        ---@type integer | nil
        local last_offset
        local last_length = 0

        -- whole bytes are read two at a time while there are two left, this keeps at most 15 + 16 bits
        local wide = symbol_bits == 8 and reverse == nil

        local buffer, bits = 0, 0
        local index = 0

        while true do
            local exhausted = false

            if bits < width and wide and index + 1 < data_length then
                if msb then
                    buffer = rbit_bor( rbit_lshift( buffer, 16 ), rbit_lshift( input[ index ], 8 ), input[ index + 1 ] )
                else
                    buffer = rbit_bor( buffer, rbit_lshift( rbit_bor( input[ index ], rbit_lshift( input[ index + 1 ], 8 ) ), bits ) )
                end

                index, bits = index + 2, bits + 16
            end

            while bits < width do
                if index == data_length then
                    exhausted = true
                    break
                end

                local symbol = input[ index ]

                if reverse ~= nil then
                    symbol = reverse[ symbol ]
                    if symbol == nil then
                        return nil, "corrupt compressed data: invalid character at position " .. (index + 1)
                    end
                end

                index = index + 1

                if msb then
                    buffer = rbit_bor( rbit_lshift( buffer, symbol_bits ), symbol )
                else
                    buffer = rbit_bor( buffer, rbit_lshift( symbol, bits ) )
                end

                bits = bits + symbol_bits
            end

            -- the rest are padding bits
            if exhausted then
                break
            end

            bits = bits - width

            local code

            if msb then
                code = rbit_band( rbit_rshift( buffer, bits ), width_scale - 1 )
            else
                code = rbit_band( buffer, width_scale - 1 )
                buffer = rbit_rshift( buffer, width )
            end

            if code == clear then
                width, width_scale, next_code, last_offset = min_width, min_scale, first, nil
            elseif code == finish then
                break
            else
                local offset = out_length
                local source, length

                if code < literal_count then
                    length = 1
                elseif code >= first and code < next_code then
                    source, length = entries[ code * 2 ], entries[ code * 2 + 1 ]
                elseif code == next_code and last_offset ~= nil and next_code < max_scale then
                    -- the entry is being defined by this very code, copying forward fills it in
                    source, length = last_offset, last_length + 1
                else
                    return nil, "corrupt compressed data: unknown code " .. code
                end

                out_length = offset + length

                -- entries are copied 4 bytes at a time, up to 3 bytes past the end are overwritten by the next one
                if out_length + 3 > capacity then
                    repeat
                        capacity = capacity * 2
                    until capacity >= out_length + 3

                    local grown = uint8_array_t( capacity )
                    ffi_copy( grown, out, offset )
                    out = grown
                end

                if source == nil then
                    out[ offset ] = code
                else
                    source = source - offset

                    -- stores are in order, so an entry that overlaps itself is still filled in correctly
                    for j = offset, out_length - 1, 4 do
                        out[ j ] = out[ source + j ]
                        out[ j + 1 ] = out[ source + j + 1 ]
                        out[ j + 2 ] = out[ source + j + 2 ]
                        out[ j + 3 ] = out[ source + j + 3 ]
                    end
                end

                if last_offset ~= nil and next_code < max_scale then
                    entries[ next_code * 2 ], entries[ next_code * 2 + 1 ] = last_offset, last_length + 1
                    next_code = next_code + 1

                    if implicit_reset and next_code == max_scale then
                        width, width_scale, next_code = min_width, min_scale, first
                    elseif width_scale < max_scale and next_code + early >= width_scale then
                        width, width_scale = width + 1, width_scale * 2
                    end
                end

                last_offset, last_length = offset, length
            end
        end

        return ffi_string( out, out_length )
    end

end

--- [SHARED AND MENU]
---
--- Compresses a string using variable-width LZW, the format is set by the options.
---
---@param raw_data string The string to compress.
---@param options? dreamwork.std.lzw.Options The format options.
---@return string compressed_data The compressed string.
---@nodiscard
function lzw.compress( raw_data, options )
    local format, error_message = get_format( options )
    if format == nil then
        error( error_message, 2 )
    end

    local compressed_data
    compressed_data, error_message = compress( raw_data, string_len( raw_data ), format )

    if compressed_data == nil then
        error( error_message, 2 )
    end

    return compressed_data
end

--- [SHARED AND MENU]
---
--- Decompresses a variable-width LZW string, the options must match the compression ones.
---
--- Without an end code the bits that do not form a whole code are ignored,
--- so formats with codes narrower than a character should use one.
---
---@param compressed_data string The string to decompress.
---@param options? dreamwork.std.lzw.Options The format options.
---@return string decompressed_data The decompressed string.
---@nodiscard
function lzw.decompress( compressed_data, options )
    local format, error_message = get_format( options )
    if format == nil then
        error( error_message, 2 )
    end

    local decompressed_data
    decompressed_data, error_message = decompress( compressed_data, format )

    if decompressed_data == nil then
        error( error_message, 2 )
    end

    return decompressed_data
end
