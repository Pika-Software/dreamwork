---@class dreamwork.std
local std = dreamwork.std

local ffi = std.ffi
local raw = std.raw

local rbit = raw.bit
local rbit_lshift, rbit_rshift = rbit.lshift, rbit.rshift
local rbit_band, rbit_bor, rbit_bxor = rbit.band, rbit.bor, rbit.bxor

local bitpack = std.bitpack
local bitpack_reverse = bitpack.reverse

local math = std.math
local math_ceil = math.ceil
local math_huge = math.huge
local math_min, math_max = math.min, math.max

local table = std.table
local table_sort = table.sort
local table_concat = table.concat
local table_unpack = table.unpack

local string = std.string
local string_len = string.len
local string_sub = string.sub
local string_byte = string.byte
local string_char = string.char

local error = std.error


--- [SHARED AND MENU]
---
--- DEFLATE is a lossless compression format that combines LZ77 and Huffman coding, it is used by zlib, gzip, PNG and ZIP.
---
--- Produces and consumes raw [DEFLATE](https://www.rfc-editor.org/rfc/rfc1951) streams (no header, no checksum)
--- compatible with zlib's `deflate` / `inflate` with negative window bits, see `std.zlib` for the zlib format.
---
---@class dreamwork.std.deflate
local deflate = {}
std.deflate = deflate

local WINDOW_SIZE = 0x8000
local WINDOW_MASK = 0x7FFF

local HASH_BITS = 15
local HASH_MASK = rbit_lshift( 1, HASH_BITS ) - 1
local HASH_SHIFT = 5 -- 3 bytes are shifted out of the hash, `ceil( HASH_BITS / 3 )`

local MIN_MATCH = 3
local MAX_MATCH = 258

--- A match of 3 bytes further than this is not worth it, its distance takes more bits than the literals.
local TOO_FAR = 4096

--- The number of literals and matches in one block, the same as zlib's default.
local BLOCK_SYMBOLS = 0x4000

--- The size of stored block parts.
local MAX_STORED = 0xFFFF

-- Settings of compression levels, the same as zlib's: `{ good_length, max_lazy, nice_length, max_chain, lazy }`
--
-- * `good_length` - the chain is cut to a quarter once a match is at least this long
-- * `max_lazy` - lazy matching stops looking for a better match once a match is at least this long,
--   without lazy matching the positions inside of matches longer than this are not hashed
-- * `nice_length` - the chain search stops once a match is at least this long
-- * `max_chain` - the maximum number of positions checked in the chain
-- * `lazy` - checks if the next position has a longer match before taking a match
local LEVELS = {
    { 4,  4,   8,   4,    false },
    { 4,  5,   16,  8,    false },
    { 4,  6,   32,  32,   false },
    { 4,  4,   16,  16,   true },
    { 8,  16,  32,  32,   true },
    { 8,  16,  128, 128,  true },
    { 8,  32,  128, 256,  true },
    { 32, 128, 258, 1024, true },
    { 32, 258, 258, 4096, true }
}

local LENGTH_BASE = { [ 0 ] = 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258 }
local LENGTH_EXTRA = { [ 0 ] = 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0 }

local DISTANCE_BASE = { [ 0 ] = 1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577 }
local DISTANCE_EXTRA = { [ 0 ] = 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13 }

--- The order code length code lengths are stored in.
local CODE_LENGTH_ORDER = { 16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15 }

--- Match length ( 3 - 258 ) to its literal/length symbol ( 257 - 285 ).
---@type integer[]
local LENGTH_SYMBOLS = { [ 0 ] = 0, 0, 0 }

--- Match distance ( 1 - 32768 ) to its distance code ( 0 - 29 ).
---@type integer[]
local DISTANCE_CODES = {}

for code = 0, 28, 1 do
    local base = LENGTH_BASE[ code ]
    for length = base, math_min( base + rbit_lshift( 1, LENGTH_EXTRA[ code ] ) - 1, MAX_MATCH ), 1 do
        LENGTH_SYMBOLS[ length ] = 257 + code
    end
end

-- 258 has its own code, 284 with all extra bits set would be 258 too
LENGTH_SYMBOLS[ MAX_MATCH ] = 285

for code = 0, 29, 1 do
    local base = DISTANCE_BASE[ code ]
    for distance = base, base + rbit_lshift( 1, DISTANCE_EXTRA[ code ] ) - 1, 1 do
        DISTANCE_CODES[ distance ] = code
    end
end

--- Reverses the order of the lowest `bit_count` bits, Huffman codes are packed starting from their highest bit.
---@param code integer
---@param bit_count integer
---@return integer
local function reverse_bits( code, bit_count )
    return rbit_rshift( bitpack_reverse( rbit_band( code, 0xFF ) ) * 0x100 + bitpack_reverse( rbit_rshift( code, 8 ) ), 16 - bit_count )
end

-- Buffers are zero-based, FFI `uint8_t[?]` and `int32_t[?]` arrays when FFI is available, Lua tables otherwise,
-- the same code works with both.

---@alias dreamwork.std.deflate.Bytes ffi.cdata* | integer[]

---@type fun( size: integer ): dreamwork.std.deflate.Bytes, integer
local get_bytes

---@type fun( bytes: dreamwork.std.deflate.Bytes, length: integer, size: integer ): dreamwork.std.deflate.Bytes, integer
local grow_bytes

---@type fun( bytes: dreamwork.std.deflate.Bytes, offset: integer, length: integer ): string
local bytes_to_string

---@type fun( bytes: dreamwork.std.deflate.Bytes, offset: integer, str: string, index: integer, length: integer )
local copy_string

---@type fun( bytes: dreamwork.std.deflate.Bytes, length: integer )
local release_bytes

---@type fun( size: integer ): ffi.cdata* | integer[]
local new_integers

---@type fun( bytes: dreamwork.std.deflate.Bytes, length: integer, source: integer, count: integer )
local copy_match

if ffi == nil then

    --- Bytes per `string.char` call, has to stay well below the C stack limit
    local CHUNK_SIZE = 4096

    --- Larger tables are temporary, so memory isn't held after one big call.
    local max_buffer_size = 0x40000

    -- tables grow by themselves, so the capacity is never reached,
    -- one is kept between calls, so it does not have to grow every time
    local buffer = {}

    function get_bytes( size )
        if size > max_buffer_size then
            return {}, math_huge
        end

        return buffer, math_huge
    end

    function grow_bytes( bytes )
        return bytes, math_huge
    end

    function release_bytes( bytes, length )
        if bytes == buffer and length > max_buffer_size then
            buffer = {}
        end
    end

    function bytes_to_string( bytes, offset, length )
        if length <= CHUNK_SIZE then
            return string_char( table_unpack( bytes, offset, offset + length - 1 ) )
        end

        local chunks, chunk_count = {}, 0
        local last = offset + length - 1

        for i = offset, last, CHUNK_SIZE do
            chunk_count = chunk_count + 1
            chunks[ chunk_count ] = string_char( table_unpack( bytes, i, math_min( i + CHUNK_SIZE - 1, last ) ) )
        end

        return table_concat( chunks, "", 1, chunk_count )
    end

    function copy_string( bytes, offset, str, index, length )
        offset = offset - index

        for i = index, index + length - 1, 1 do
            bytes[ offset + i ] = string_byte( str, i )
        end
    end

    function new_integers( size )
        local integers = {}

        for i = 0, size - 1, 1 do
            integers[ i ] = 0
        end

        return integers
    end

    function copy_match( bytes, length, source, count )
        for i = 0, count - 1, 1 do
            bytes[ length + i ] = bytes[ source + i ]
        end
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

    local buffer_size = 0x1000
    local buffer = uint8_array_t( buffer_size )

    function get_bytes( size )
        if size > buffer_size then
            if size > max_buffer_size then
                return uint8_array_t( size ), size
            end

            buffer_size = math_max( size, buffer_size * 2 )
            buffer = uint8_array_t( buffer_size )
        end

        return buffer, buffer_size
    end

    function grow_bytes( bytes, length, size )
        local grown = uint8_array_t( size )
        ffi_copy( grown, bytes, length )
        return grown, size
    end

    function bytes_to_string( bytes, offset, length )
        return ffi_string( bytes + offset, length )
    end

    -- the buffer never grows
    function release_bytes()
    end

    function copy_string( bytes, offset, str, index, length )
        ffi_copy( bytes + offset, ffi_cast( uint8_ptr_t, str ) + (index - 1), length )
    end

    function new_integers( size )
        return int32_array_t( size )
    end

    -- 4 bytes at a time, up to 3 bytes past the end are overwritten
    function copy_match( bytes, length, source, count )
        for i = 0, count - 1, 4 do
            bytes[ length + i ] = bytes[ source + i ]
            bytes[ length + i + 1 ] = bytes[ source + i + 1 ]
            bytes[ length + i + 2 ] = bytes[ source + i + 2 ]
            bytes[ length + i + 3 ] = bytes[ source + i + 3 ]
        end
    end

end

--- Builds length limited Huffman code lengths for the frequencies,
--- with the in-place algorithm by Alistair Moffat and Jyrki Katajainen and the length limit of miniz.
---
--- At least two symbols get a code, even if they are not used, like zlib does,
--- some decoders do not accept a code with a single symbol.
---
---@param frequencies integer[]
---@param symbol_count integer
---@param max_length integer
---@param lengths integer[]
local function build_lengths( frequencies, symbol_count, max_length, lengths )
    -- frequency * 512 + symbol, sorted by frequency, then by symbol
    ---@type integer[]
    local sorted = {}
    local used = 0

    for symbol = 0, symbol_count - 1, 1 do
        lengths[ symbol ] = 0

        local frequency = frequencies[ symbol ]
        if frequency ~= 0 then
            used = used + 1
            sorted[ used ] = frequency * 512 + symbol
        end
    end

    if used < 2 then
        local symbol = used == 0 and 0 or sorted[ 1 ] % 512
        lengths[ symbol ] = 1
        lengths[ symbol == 0 and 1 or 0 ] = 1
        return
    end

    table_sort( sorted )

    -- `nodes` are frequencies, then parent indexes, then depths
    ---@type integer[]
    local nodes = {}

    for i = 1, used, 1 do
        nodes[ i - 1 ] = rbit_rshift( sorted[ i ], 9 )
    end

    nodes[ 0 ] = nodes[ 0 ] + nodes[ 1 ]

    local root, leaf = 0, 2

    for next_node = 1, used - 2, 1 do
        if leaf >= used or nodes[ root ] < nodes[ leaf ] then
            nodes[ next_node ] = nodes[ root ]
            nodes[ root ] = next_node
            root = root + 1
        else
            nodes[ next_node ] = nodes[ leaf ]
            leaf = leaf + 1
        end

        if leaf >= used or (root < next_node and nodes[ root ] < nodes[ leaf ]) then
            nodes[ next_node ] = nodes[ next_node ] + nodes[ root ]
            nodes[ root ] = next_node
            root = root + 1
        else
            nodes[ next_node ] = nodes[ next_node ] + nodes[ leaf ]
            leaf = leaf + 1
        end
    end

    nodes[ used - 2 ] = 0

    for next_node = used - 3, 0, -1 do
        nodes[ next_node ] = nodes[ nodes[ next_node ] ] + 1
    end

    ---@type integer[]
    local length_counts = {}

    for length = 1, max_length, 1 do
        length_counts[ length ] = 0
    end

    do

        local available, used_nodes, depth = 1, 0, 0
        local next_node = used - 1
        root = used - 2

        while available > 0 do
            while root >= 0 and nodes[ root ] == depth do
                used_nodes = used_nodes + 1
                root = root - 1
            end

            while available > used_nodes do
                -- deeper leaves are cut to the limit and fixed below
                local length = math_min( depth, max_length )
                length_counts[ length ] = length_counts[ length ] + 1

                next_node = next_node - 1
                available = available - 1
            end

            available = 2 * used_nodes
            depth = depth + 1
            used_nodes = 0
        end

    end

    -- the cut leaves over-subscribe the code, every step moves the overflow by one leaf
    local total = 0

    for length = 1, max_length, 1 do
        total = total + rbit_lshift( length_counts[ length ], max_length - length )
    end

    local full = rbit_lshift( 1, max_length )

    while total ~= full do
        length_counts[ max_length ] = length_counts[ max_length ] - 1

        for length = max_length - 1, 1, -1 do
            if length_counts[ length ] ~= 0 then
                length_counts[ length ] = length_counts[ length ] - 1
                length_counts[ length + 1 ] = length_counts[ length + 1 ] + 2
                break
            end
        end

        total = total - 1
    end

    -- the most frequent symbols get the shortest codes
    local index = used

    for length = 1, max_length, 1 do
        for _ = 1, length_counts[ length ], 1 do
            lengths[ sorted[ index ] % 512 ] = length
            index = index - 1
        end
    end
end

---@type integer[]
local next_codes = {}

--- Builds canonical Huffman codes with reversed bits from the code lengths.
---
---@param lengths integer[]
---@param symbol_count integer
---@param codes integer[]
local function build_codes( lengths, symbol_count, codes )
    for length = 0, 15, 1 do
        next_codes[ length ] = 0
    end

    for symbol = 0, symbol_count - 1, 1 do
        local length = lengths[ symbol ]
        next_codes[ length ] = next_codes[ length ] + 1
    end

    local code = 0
    next_codes[ 0 ] = 0

    for length = 1, 15, 1 do
        local count = next_codes[ length ]
        next_codes[ length ] = code
        code = (code + count) * 2
    end

    for symbol = 0, symbol_count - 1, 1 do
        local length = lengths[ symbol ]
        if length == 0 then
            codes[ symbol ] = 0
        else
            local next_code = next_codes[ length ]
            next_codes[ length ] = next_code + 1
            codes[ symbol ] = reverse_bits( next_code, length )
        end
    end
end

--- Builds codes of all match lengths with their extra bits for the literal/length code.
---
---@param literal_codes integer[]
---@param literal_lengths integer[]
---@param length_codes integer[]
---@param length_bits integer[]
local function build_length_codes( literal_codes, literal_lengths, length_codes, length_bits )
    for length = MIN_MATCH, MAX_MATCH, 1 do
        local symbol = LENGTH_SYMBOLS[ length ]
        local code = symbol - 257
        local bit_count = literal_lengths[ symbol ]

        length_codes[ length ] = rbit_bor( literal_codes[ symbol ], rbit_lshift( length - LENGTH_BASE[ code ], bit_count ) )
        length_bits[ length ] = bit_count + LENGTH_EXTRA[ code ]
    end
end

---@type integer[]
local FIXED_LITERAL_LENGTHS = {}

---@type integer[]
local FIXED_DISTANCE_LENGTHS = {}

do

    for symbol = 0, 287, 1 do
        FIXED_LITERAL_LENGTHS[ symbol ] = (symbol < 144 and 8) or (symbol < 256 and 9) or (symbol < 280 and 7) or 8
    end

    for code = 0, 31, 1 do
        FIXED_DISTANCE_LENGTHS[ code ] = 5
    end

end

-- Compression --

---@class dreamwork.std.deflate.Writer
---@field bytes dreamwork.std.deflate.Bytes
---@field length integer
---@field capacity integer
---@field bit_buffer integer
---@field bit_count integer

---@param writer dreamwork.std.deflate.Writer
---@param size integer
local function reserve( writer, size )
    local required = writer.length + size
    if required > writer.capacity then
        writer.bytes, writer.capacity = grow_bytes( writer.bytes, writer.length, math_max( required, writer.capacity * 2 ) )
    end
end

--- Writes up to 24 bits, bytes have to be reserved.
---
---@param writer dreamwork.std.deflate.Writer
---@param value integer
---@param bit_count integer
local function write_bits( writer, value, bit_count )
    local bit_buffer = rbit_bor( writer.bit_buffer, rbit_lshift( value, writer.bit_count ) )
    bit_count = writer.bit_count + bit_count

    local bytes, length = writer.bytes, writer.length

    while bit_count >= 8 do
        bytes[ length ] = rbit_band( bit_buffer, 0xFF )
        length = length + 1

        bit_buffer = rbit_rshift( bit_buffer, 8 )
        bit_count = bit_count - 8
    end

    writer.bit_buffer, writer.bit_count = bit_buffer, bit_count
    writer.length = length
end

--- Writes the stored blocks of the bytes from `index` to `last`, the last of them is final if `is_last` is `true`.
---
---@param writer dreamwork.std.deflate.Writer
---@param data string
---@param index integer
---@param last integer
---@param is_last boolean
local function write_stored( writer, data, index, last, is_last )
    local remaining = last - index + 1

    reserve( writer, remaining + 5 * (math_ceil( remaining / MAX_STORED ) + 1) + 1 )

    repeat
        local size = math_min( remaining, MAX_STORED )
        remaining = remaining - size

        write_bits( writer, (is_last and remaining == 0) and 1 or 0, 3 )

        local bytes, length = writer.bytes, writer.length

        if writer.bit_count ~= 0 then
            bytes[ length ] = writer.bit_buffer
            length = length + 1
        end

        bytes[ length ] = rbit_band( size, 0xFF )
        bytes[ length + 1 ] = rbit_rshift( size, 8 )
        bytes[ length + 2 ] = rbit_band( rbit_bxor( size, 0xFFFF ), 0xFF )
        bytes[ length + 3 ] = rbit_rshift( rbit_bxor( size, 0xFFFF ), 8 )

        copy_string( bytes, length + 4, data, index, size )

        writer.length = length + 4 + size
        writer.bit_buffer, writer.bit_count = 0, 0

        index = index + size
    until remaining == 0
end

--- Writes literals and matches with the codes, and the end of the block.
---
--- Every code is added to at most 7 bits that are left over, then all whole bytes are taken out of the buffer,
--- three bytes are always written, so the buffer never holds more than 31 bits.
---
---@param writer dreamwork.std.deflate.Writer
---@param items integer[]
---@param item_count integer
---@param literal_codes integer[]
---@param literal_lengths integer[]
---@param length_codes integer[]
---@param length_bits integer[]
---@param distance_codes integer[]
---@param distance_lengths integer[]
local function write_items( writer, items, item_count, literal_codes, literal_lengths, length_codes, length_bits, distance_codes, distance_lengths )
    local bytes, length = writer.bytes, writer.length
    local bit_buffer, bit_count = writer.bit_buffer, writer.bit_count

    for i = 0, item_count - 1, 1 do
        local item = items[ i ]

        if item < 256 then
            bit_buffer = rbit_bor( bit_buffer, rbit_lshift( literal_codes[ item ], bit_count ) )
            bit_count = bit_count + literal_lengths[ item ]
        else
            local match_length = rbit_band( item, 0x1FF )

            bit_buffer = rbit_bor( bit_buffer, rbit_lshift( length_codes[ match_length ], bit_count ) )
            bit_count = bit_count + length_bits[ match_length ]

            bytes[ length ] = rbit_band( bit_buffer, 0xFF )
            bytes[ length + 1 ] = rbit_band( rbit_rshift( bit_buffer, 8 ), 0xFF )
            bytes[ length + 2 ] = rbit_band( rbit_rshift( bit_buffer, 16 ), 0xFF )

            local whole = rbit_rshift( bit_count, 3 )
            length = length + whole
            bit_buffer = rbit_rshift( bit_buffer, whole * 8 )
            bit_count = rbit_band( bit_count, 7 )

            local distance = rbit_rshift( item, 9 )
            local code = DISTANCE_CODES[ distance ]

            bit_buffer = rbit_bor( bit_buffer, rbit_lshift( distance_codes[ code ], bit_count ) )
            bit_count = bit_count + distance_lengths[ code ]

            bytes[ length ] = rbit_band( bit_buffer, 0xFF )
            bytes[ length + 1 ] = rbit_band( rbit_rshift( bit_buffer, 8 ), 0xFF )
            bytes[ length + 2 ] = rbit_band( rbit_rshift( bit_buffer, 16 ), 0xFF )

            whole = rbit_rshift( bit_count, 3 )
            length = length + whole
            bit_buffer = rbit_rshift( bit_buffer, whole * 8 )
            bit_count = rbit_band( bit_count, 7 )

            bit_buffer = rbit_bor( bit_buffer, rbit_lshift( distance - DISTANCE_BASE[ code ], bit_count ) )
            bit_count = bit_count + DISTANCE_EXTRA[ code ]
        end

        bytes[ length ] = rbit_band( bit_buffer, 0xFF )
        bytes[ length + 1 ] = rbit_band( rbit_rshift( bit_buffer, 8 ), 0xFF )
        bytes[ length + 2 ] = rbit_band( rbit_rshift( bit_buffer, 16 ), 0xFF )

        local whole = rbit_rshift( bit_count, 3 )
        length = length + whole
        bit_buffer = rbit_rshift( bit_buffer, whole * 8 )
        bit_count = rbit_band( bit_count, 7 )
    end

    writer.bytes, writer.length = bytes, length
    writer.bit_buffer, writer.bit_count = bit_buffer, bit_count

    write_bits( writer, literal_codes[ 256 ], literal_lengths[ 256 ] )
end

---@type integer[]
local FIXED_LITERAL_CODES = {}

---@type integer[]
local FIXED_DISTANCE_CODES = {}

---@type integer[]
local FIXED_LENGTH_CODES = {}

---@type integer[]
local FIXED_LENGTH_BITS = {}

build_codes( FIXED_LITERAL_LENGTHS, 288, FIXED_LITERAL_CODES )
build_codes( FIXED_DISTANCE_LENGTHS, 32, FIXED_DISTANCE_CODES )
build_length_codes( FIXED_LITERAL_CODES, FIXED_LITERAL_LENGTHS, FIXED_LENGTH_CODES, FIXED_LENGTH_BITS )

-- Block buffers, shared between calls.
--
-- Items are literals ( 0 - 255 ) and matches ( `distance * 512 + length` ).

local items = new_integers( BLOCK_SYMBOLS )

local literal_frequencies = new_integers( 288 )
local distance_frequencies = new_integers( 32 )

---@type integer[]
local literal_lengths, literal_codes = {}, {}

---@type integer[]
local distance_lengths, distance_codes = {}, {}

---@type integer[]
local length_codes, length_bits = {}, {}

---@type integer[]
local code_length_frequencies, code_length_lengths, code_length_codes = {}, {}, {}

--- The code lengths of both codes, then their run-length encoding, `symbol + extra bits * 32`.
---@type integer[]
local all_lengths, length_runs = {}, {}

--- Run-length encodes the code lengths and counts the frequencies of code length symbols.
---
---@param length_count integer
---@return integer run_count
local function encode_lengths( length_count )
    for symbol = 0, 18, 1 do
        code_length_frequencies[ symbol ] = 0
    end

    local run_count = 0
    local index = 0

    while index < length_count do
        local length = all_lengths[ index ]

        local run = 1
        while index + run < length_count and all_lengths[ index + run ] == length do
            run = run + 1
        end

        index = index + run

        if length == 0 then
            while run >= 11 do
                local size = math_min( run, 138 )
                run = run - size

                run_count = run_count + 1
                length_runs[ run_count ] = 18 + (size - 11) * 32
                code_length_frequencies[ 18 ] = code_length_frequencies[ 18 ] + 1
            end

            if run >= 3 then
                run_count = run_count + 1
                length_runs[ run_count ] = 17 + (run - 3) * 32
                code_length_frequencies[ 17 ] = code_length_frequencies[ 17 ] + 1
                run = 0
            end
        else
            run_count = run_count + 1
            length_runs[ run_count ] = length
            code_length_frequencies[ length ] = code_length_frequencies[ length ] + 1
            run = run - 1

            while run >= 3 do
                local size = math_min( run, 6 )
                run = run - size

                run_count = run_count + 1
                length_runs[ run_count ] = 16 + (size - 3) * 32
                code_length_frequencies[ 16 ] = code_length_frequencies[ 16 ] + 1
            end
        end

        for _ = 1, run, 1 do
            run_count = run_count + 1
            length_runs[ run_count ] = length
            code_length_frequencies[ length ] = code_length_frequencies[ length ] + 1
        end
    end

    return run_count
end

--- Writes the block of items as the smallest of stored, fixed and dynamic blocks.
---
---@param writer dreamwork.std.deflate.Writer
---@param data string
---@param first integer The index of the first byte of the block.
---@param last integer The index of the last byte of the block.
---@param item_count integer
---@param is_last boolean
---@param strategy integer `1` for fixed codes only
local function write_block( writer, data, first, last, item_count, is_last, strategy )
    literal_frequencies[ 256 ] = 1

    -- extra bits are the same for fixed and dynamic codes
    local extra_bits = 0

    for code = 0, 28, 1 do
        extra_bits = extra_bits + literal_frequencies[ 257 + code ] * LENGTH_EXTRA[ code ]
    end

    for code = 0, 29, 1 do
        extra_bits = extra_bits + distance_frequencies[ code ] * DISTANCE_EXTRA[ code ]
    end

    local fixed_size = 3 + extra_bits

    for symbol = 0, 285, 1 do
        fixed_size = fixed_size + literal_frequencies[ symbol ] * FIXED_LITERAL_LENGTHS[ symbol ]
    end

    for code = 0, 29, 1 do
        fixed_size = fixed_size + distance_frequencies[ code ] * 5
    end

    local dynamic_size = math_huge
    local literal_count, distance_count, code_length_count, run_count

    if strategy ~= 1 then
        build_lengths( literal_frequencies, 286, 15, literal_lengths )
        build_lengths( distance_frequencies, 30, 15, distance_lengths )

        literal_count = 286
        while literal_count > 257 and literal_lengths[ literal_count - 1 ] == 0 do
            literal_count = literal_count - 1
        end

        distance_count = 30
        while distance_count > 1 and distance_lengths[ distance_count - 1 ] == 0 do
            distance_count = distance_count - 1
        end

        for symbol = 0, literal_count - 1, 1 do
            all_lengths[ symbol ] = literal_lengths[ symbol ]
        end

        for code = 0, distance_count - 1, 1 do
            all_lengths[ literal_count + code ] = distance_lengths[ code ]
        end

        run_count = encode_lengths( literal_count + distance_count )
        build_lengths( code_length_frequencies, 19, 7, code_length_lengths )

        code_length_count = 19
        while code_length_count > 4 and code_length_lengths[ CODE_LENGTH_ORDER[ code_length_count ] ] == 0 do
            code_length_count = code_length_count - 1
        end

        dynamic_size = 3 + 14 + code_length_count * 3 + extra_bits
            + code_length_frequencies[ 16 ] * 2 + code_length_frequencies[ 17 ] * 3 + code_length_frequencies[ 18 ] * 7

        for symbol = 0, 18, 1 do
            dynamic_size = dynamic_size + code_length_frequencies[ symbol ] * code_length_lengths[ symbol ]
        end

        for symbol = 0, 285, 1 do
            dynamic_size = dynamic_size + literal_frequencies[ symbol ] * literal_lengths[ symbol ]
        end

        for code = 0, 29, 1 do
            dynamic_size = dynamic_size + distance_frequencies[ code ] * distance_lengths[ code ]
        end
    end

    -- stored blocks start at a byte and take 4 bytes of lengths per 65535 bytes
    local byte_count = last - first + 1
    local stored_size = (strategy == 1) and math_huge or (byte_count + 5 * math_max( 1, math_ceil( byte_count / MAX_STORED ) )) * 8

    if stored_size <= fixed_size and stored_size <= dynamic_size then
        write_stored( writer, data, first, last, is_last )
    else
        -- codes are written before the buffer is flushed, 3 bytes past the end
        reserve( writer, rbit_rshift( math_min( fixed_size, dynamic_size ), 3 ) + 8 )

        if fixed_size <= dynamic_size then
            write_bits( writer, is_last and 3 or 2, 3 )
            write_items( writer, items, item_count, FIXED_LITERAL_CODES, FIXED_LITERAL_LENGTHS, FIXED_LENGTH_CODES, FIXED_LENGTH_BITS, FIXED_DISTANCE_CODES, FIXED_DISTANCE_LENGTHS )
        else
            write_bits( writer, is_last and 5 or 4, 3 )
            write_bits( writer, literal_count - 257, 5 )
            write_bits( writer, distance_count - 1, 5 )
            write_bits( writer, code_length_count - 4, 4 )

            for i = 1, code_length_count, 1 do
                write_bits( writer, code_length_lengths[ CODE_LENGTH_ORDER[ i ] ], 3 )
            end

            build_codes( code_length_lengths, 19, code_length_codes )

            for i = 1, run_count, 1 do
                local run = length_runs[ i ]
                local symbol = rbit_band( run, 31 )

                write_bits( writer, code_length_codes[ symbol ], code_length_lengths[ symbol ] )

                if symbol == 16 then
                    write_bits( writer, rbit_rshift( run, 5 ), 2 )
                elseif symbol == 17 then
                    write_bits( writer, rbit_rshift( run, 5 ), 3 )
                elseif symbol == 18 then
                    write_bits( writer, rbit_rshift( run, 5 ), 7 )
                end
            end

            build_codes( literal_lengths, 286, literal_codes )
            build_codes( distance_lengths, 30, distance_codes )
            build_length_codes( literal_codes, literal_lengths, length_codes, length_bits )

            write_items( writer, items, item_count, literal_codes, literal_lengths, length_codes, length_bits, distance_codes, distance_lengths )
        end
    end

    for symbol = 0, 287, 1 do
        literal_frequencies[ symbol ] = 0
    end

    for code = 0, 31, 1 do
        distance_frequencies[ code ] = 0
    end
end

-- The hash chains keep the last position of every hash in `heads` and the previous position with the same hash
-- in `chains[ position % 32768 ]`, both are shared between calls.
--
-- Positions are stored with a base that grows with every call, so entries left over from previous calls
-- always look further away than the window and never have to be cleared.

local heads = new_integers( HASH_MASK + 1 )
local chains = new_integers( WINDOW_SIZE )

local next_base = WINDOW_SIZE + 1

---@alias dreamwork.std.deflate.Input string | ffi.cdata*

--- Returns the input of `find_match`, the string itself or a pointer to its bytes.
---@type fun( data: string ): dreamwork.std.deflate.Input
local get_input

---@type fun( input: dreamwork.std.deflate.Input, base: integer, position: integer, candidate: integer, best_length: integer, max_length: integer, nice_length: integer, chain_length: integer ): integer, integer
local find_match

-- HolyLib's `ffi.cast` is a regular C function that is not compiled, ~25 times slower than `string.byte`
if ffi == nil or not std.jit.isFFI( ffi.cast ) then

    function get_input( data )
        return data
    end

    --- Finds the longest match of the position in the hash chain, starting with the candidate.
    ---
    ---@param data string
    ---@param base integer
    ---@param position integer
    ---@param candidate integer
    ---@param best_length integer Only longer matches are taken.
    ---@param max_length integer
    ---@param nice_length integer
    ---@param chain_length integer
    ---@return integer best_length
    ---@return integer best_start
    function find_match( data, base, position, candidate, best_length, max_length, nice_length, chain_length )
        local limit = position - WINDOW_SIZE
        local best_start = 0

        local first, second = string_byte( data, position, position + 1 )
        local scan_end1, scan_end = string_byte( data, position + best_length - 1, position + best_length )

        repeat
            local match_end1, match_end = string_byte( data, candidate + best_length - 1, candidate + best_length )

            if match_end == scan_end and match_end1 == scan_end1 then
                local candidate_first, candidate_second = string_byte( data, candidate, candidate + 1 )

                if candidate_first == first and candidate_second == second then
                    local length = 2
                    while length < max_length and string_byte( data, position + length ) == string_byte( data, candidate + length ) do
                        length = length + 1
                    end

                    if length > best_length then
                        best_length, best_start = length, candidate

                        if length >= nice_length then
                            break
                        end

                        scan_end1, scan_end = string_byte( data, position + length - 1, position + length )
                    end
                end
            end

            chain_length = chain_length - 1
            if chain_length == 0 then
                break
            end

            candidate = chains[ rbit_band( candidate, WINDOW_MASK ) ] - base
        until candidate <= limit

        return best_length, best_start
    end

else

    local ffi_cast = ffi.cast

    local uint8_ptr_t = ffi.typeof( "const uint8_t *" )
    local uint16_ptr_t = ffi.typeof( "const uint16_t *" )
    local int32_ptr_t = ffi.typeof( "const int32_t *" )

    --- Returns a pointer to the bytes of the string that is indexed from `1`.
    function get_input( data )
        return ffi_cast( uint8_ptr_t, data ) - 1
    end

    -- the same as above, with 2 bytes loaded at once and matches compared 4 bytes at a time
    function find_match( input, base, position, candidate, best_length, max_length, nice_length, chain_length )
        local limit = position - WINDOW_SIZE
        local best_start = 0

        local start_pair = ffi_cast( uint16_ptr_t, input + position )[ 0 ]
        local end_pair = ffi_cast( uint16_ptr_t, input + position + best_length - 1 )[ 0 ]

        repeat
            if ffi_cast( uint16_ptr_t, input + candidate + best_length - 1 )[ 0 ] == end_pair and ffi_cast( uint16_ptr_t, input + candidate )[ 0 ] == start_pair then
                local length = 2

                while length <= max_length - 4 and ffi_cast( int32_ptr_t, input + position + length )[ 0 ] == ffi_cast( int32_ptr_t, input + candidate + length )[ 0 ] do
                    length = length + 4
                end

                while length < max_length and input[ position + length ] == input[ candidate + length ] do
                    length = length + 1
                end

                if length > best_length then
                    best_length, best_start = length, candidate

                    if length >= nice_length then
                        break
                    end

                    end_pair = ffi_cast( uint16_ptr_t, input + position + length - 1 )[ 0 ]
                end
            end

            chain_length = chain_length - 1
            if chain_length == 0 then
                break
            end

            candidate = chains[ rbit_band( candidate, WINDOW_MASK ) ] - base
        until candidate <= limit

        return best_length, best_start
    end

end

---@param writer dreamwork.std.deflate.Writer
---@param data string
---@param data_length integer
---@param start integer
---@param settings table
---@param strategy integer
local function compress_lazy( writer, data, data_length, start, settings, strategy )
    local good_length, max_lazy, nice_length, max_chain = settings[ 1 ], settings[ 2 ], settings[ 3 ], settings[ 4 ]
    local filtered = strategy == 2

    local base = next_base
    if base + data_length + WINDOW_SIZE > 0x7FFFFFFF then
        for i = 0, HASH_MASK, 1 do
            heads[ i ] = 0
        end

        for i = 0, WINDOW_MASK, 1 do
            chains[ i ] = 0
        end

        base = WINDOW_SIZE + 1
    end

    next_base = base + data_length + WINDOW_SIZE + 1

    local input = get_input( data )

    -- the last position that has 3 bytes to hash
    local hash_limit = data_length - 2

    local hash = 0
    if data_length >= 2 then
        hash = rbit_band( rbit_bxor( rbit_lshift( string_byte( data, 1 ), HASH_SHIFT ), string_byte( data, 2 ) ), HASH_MASK )
    end

    -- the dictionary is only hashed
    for position = 1, math_min( start - 1, hash_limit ), 1 do
        hash = rbit_band( rbit_bxor( rbit_lshift( hash, HASH_SHIFT ), string_byte( data, position + 2 ) ), HASH_MASK )
        chains[ rbit_band( position, WINDOW_MASK ) ] = heads[ hash ]
        heads[ hash ] = base + position
    end

    local item_count = 0
    local block_first = start

    local position = start
    local match_available = false
    local match_length, match_start = 2, 0

    while position <= data_length do
        local candidate = -WINDOW_SIZE

        if position <= hash_limit then
            hash = rbit_band( rbit_bxor( rbit_lshift( hash, HASH_SHIFT ), string_byte( data, position + 2 ) ), HASH_MASK )

            local head = heads[ hash ]
            candidate = head - base

            chains[ rbit_band( position, WINDOW_MASK ) ] = head
            heads[ hash ] = base + position
        end

        local previous_length, previous_start = match_length, match_start
        match_length = 2

        if previous_length < max_lazy and candidate > position - WINDOW_SIZE then
            local max_length = math_min( data_length - position + 1, MAX_MATCH )

            if previous_length < max_length then
                match_length, match_start = find_match( input, base, position, candidate, previous_length, max_length, math_min( nice_length, max_length ),
                    previous_length >= good_length and rbit_rshift( max_chain, 2 ) or max_chain )

                if match_length <= 5 and (filtered or (match_length == 3 and position - match_start > TOO_FAR)) then
                    match_length = 2
                end
            end
        end

        if previous_length >= MIN_MATCH and match_length <= previous_length then
            local distance = position - 1 - previous_start

            items[ item_count ] = distance * 512 + previous_length
            item_count = item_count + 1

            local symbol = LENGTH_SYMBOLS[ previous_length ]
            literal_frequencies[ symbol ] = literal_frequencies[ symbol ] + 1

            local code = DISTANCE_CODES[ distance ]
            distance_frequencies[ code ] = distance_frequencies[ code ] + 1

            -- the match started at the previous position, which is hashed already
            local last = position + previous_length - 2

            for inserted = position + 1, math_min( last, hash_limit ), 1 do
                hash = rbit_band( rbit_bxor( rbit_lshift( hash, HASH_SHIFT ), string_byte( data, inserted + 2 ) ), HASH_MASK )
                chains[ rbit_band( inserted, WINDOW_MASK ) ] = heads[ hash ]
                heads[ hash ] = base + inserted
            end

            position = last + 1
            match_available = false
            match_length = 2

            if item_count == BLOCK_SYMBOLS then
                write_block( writer, data, block_first, position - 1, item_count, false, strategy )
                block_first, item_count = position, 0
            end
        elseif match_available then
            local byte = string_byte( data, position - 1 )

            items[ item_count ] = byte
            item_count = item_count + 1

            literal_frequencies[ byte ] = literal_frequencies[ byte ] + 1
            position = position + 1

            if item_count == BLOCK_SYMBOLS then
                write_block( writer, data, block_first, position - 2, item_count, false, strategy )
                block_first, item_count = position - 1, 0
            end
        else
            match_available = true
            position = position + 1
        end
    end

    if match_available then
        local byte = string_byte( data, position - 1 )

        items[ item_count ] = byte
        item_count = item_count + 1

        literal_frequencies[ byte ] = literal_frequencies[ byte ] + 1
    end

    write_block( writer, data, block_first, data_length, item_count, true, strategy )
end

---@param writer dreamwork.std.deflate.Writer
---@param data string
---@param data_length integer
---@param start integer
---@param settings table
---@param strategy integer
local function compress_fast( writer, data, data_length, start, settings, strategy )
    local max_insert, nice_length, max_chain = settings[ 2 ], settings[ 3 ], settings[ 4 ]

    local base = next_base
    if base + data_length + WINDOW_SIZE > 0x7FFFFFFF then
        for i = 0, HASH_MASK, 1 do
            heads[ i ] = 0
        end

        for i = 0, WINDOW_MASK, 1 do
            chains[ i ] = 0
        end

        base = WINDOW_SIZE + 1
    end

    next_base = base + data_length + WINDOW_SIZE + 1

    local input = get_input( data )

    local hash_limit = data_length - 2

    local hash = 0
    if data_length >= 2 then
        hash = rbit_band( rbit_bxor( rbit_lshift( string_byte( data, 1 ), HASH_SHIFT ), string_byte( data, 2 ) ), HASH_MASK )
    end

    for position = 1, math_min( start - 1, hash_limit ), 1 do
        hash = rbit_band( rbit_bxor( rbit_lshift( hash, HASH_SHIFT ), string_byte( data, position + 2 ) ), HASH_MASK )
        chains[ rbit_band( position, WINDOW_MASK ) ] = heads[ hash ]
        heads[ hash ] = base + position
    end

    local item_count = 0
    local block_first = start

    local position = start

    while position <= data_length do
        local candidate = -WINDOW_SIZE

        if position <= hash_limit then
            hash = rbit_band( rbit_bxor( rbit_lshift( hash, HASH_SHIFT ), string_byte( data, position + 2 ) ), HASH_MASK )

            local head = heads[ hash ]
            candidate = head - base

            chains[ rbit_band( position, WINDOW_MASK ) ] = head
            heads[ hash ] = base + position
        end

        local match_length, match_start = 0, 0

        if candidate > position - WINDOW_SIZE then
            local max_length = math_min( data_length - position + 1, MAX_MATCH )
            if max_length >= MIN_MATCH then
                match_length, match_start = find_match( input, base, position, candidate, 2, max_length, math_min( nice_length, max_length ), max_chain )
            end
        end

        if match_length >= MIN_MATCH then
            local distance = position - match_start

            items[ item_count ] = distance * 512 + match_length
            item_count = item_count + 1

            local symbol = LENGTH_SYMBOLS[ match_length ]
            literal_frequencies[ symbol ] = literal_frequencies[ symbol ] + 1

            local code = DISTANCE_CODES[ distance ]
            distance_frequencies[ code ] = distance_frequencies[ code ] + 1

            local next_position = position + match_length

            if match_length <= max_insert then
                for inserted = position + 1, math_min( next_position - 1, hash_limit ), 1 do
                    hash = rbit_band( rbit_bxor( rbit_lshift( hash, HASH_SHIFT ), string_byte( data, inserted + 2 ) ), HASH_MASK )
                    chains[ rbit_band( inserted, WINDOW_MASK ) ] = heads[ hash ]
                    heads[ hash ] = base + inserted
                end
            elseif next_position < data_length then
                -- the positions inside of the match are skipped, the hash starts over
                hash = rbit_band( rbit_bxor( rbit_lshift( string_byte( data, next_position ), HASH_SHIFT ), string_byte( data, next_position + 1 ) ), HASH_MASK )
            end

            position = next_position
        else
            local byte = string_byte( data, position )

            items[ item_count ] = byte
            item_count = item_count + 1

            literal_frequencies[ byte ] = literal_frequencies[ byte ] + 1
            position = position + 1
        end

        if item_count == BLOCK_SYMBOLS then
            write_block( writer, data, block_first, position - 1, item_count, false, strategy )
            block_first, item_count = position, 0
        end
    end

    write_block( writer, data, block_first, data_length, item_count, true, strategy )
end

--- Only literals, or only runs of the previous byte ( matches with the distance `1` ).
---
---@param writer dreamwork.std.deflate.Writer
---@param data string
---@param data_length integer
---@param start integer
---@param strategy integer
---@param runs boolean
local function compress_simple( writer, data, data_length, start, strategy, runs )
    local item_count = 0
    local block_first = start

    local position = start

    while position <= data_length do
        local byte = string_byte( data, position )
        local run = 0

        if runs and position > 1 and string_byte( data, position - 1 ) == byte then
            local max_length = math_min( data_length - position + 1, MAX_MATCH )

            run = 1
            while run < max_length and string_byte( data, position + run ) == byte do
                run = run + 1
            end
        end

        if run >= MIN_MATCH then
            items[ item_count ] = 512 + run
            item_count = item_count + 1

            local symbol = LENGTH_SYMBOLS[ run ]
            literal_frequencies[ symbol ] = literal_frequencies[ symbol ] + 1
            distance_frequencies[ 0 ] = distance_frequencies[ 0 ] + 1

            position = position + run
        else
            items[ item_count ] = byte
            item_count = item_count + 1

            literal_frequencies[ byte ] = literal_frequencies[ byte ] + 1
            position = position + 1
        end

        if item_count == BLOCK_SYMBOLS then
            write_block( writer, data, block_first, position - 1, item_count, false, strategy )
            block_first, item_count = position, 0
        end
    end

    write_block( writer, data, block_first, data_length, item_count, true, strategy )
end

local STRATEGIES = {
    default = 0,
    fixed = 1,
    filtered = 2,
    huffman_only = 3,
    rle = 4
}

--- [SHARED AND MENU]
---
--- Compresses a string into a raw DEFLATE stream.
---
---@param raw_data string The string to compress.
---@param options? dreamwork.std.deflate.Options The compression options.
---@return string compressed_data The compressed string.
---@nodiscard
function deflate.compress( raw_data, options )
    local level, strategy, dictionary = 6, 0, nil

    if options ~= nil then
        if options.level ~= nil then
            level = options.level
            if not (level % 1 == 0 and level >= 0 and level <= 9) then
                error( "options.level must be an integer from 0 to 9", 2 )
            end
        end

        if options.strategy ~= nil then
            strategy = STRATEGIES[ options.strategy ]
            if strategy == nil then
                error( "options.strategy must be \"default\", \"filtered\", \"huffman_only\", \"rle\" or \"fixed\"", 2 )
            end
        end

        dictionary = options.dictionary
    end

    local start = 1

    if dictionary ~= nil then
        local dictionary_length = string_len( dictionary )
        if dictionary_length > WINDOW_SIZE then
            dictionary, dictionary_length = string_sub( dictionary, -WINDOW_SIZE ), WINDOW_SIZE
        end

        if dictionary_length ~= 0 then
            raw_data = dictionary .. raw_data
            start = dictionary_length + 1
        end
    end

    local data_length = string_len( raw_data )

    local bytes, capacity = get_bytes( data_length - start + 1 + 0x400 )

    ---@type dreamwork.std.deflate.Writer
    local writer = {
        bytes = bytes,
        length = 0,
        capacity = capacity,
        bit_buffer = 0,
        bit_count = 0
    }

    if level == 0 then
        write_stored( writer, raw_data, start, data_length, true )
    elseif strategy == 3 or strategy == 4 then
        compress_simple( writer, raw_data, data_length, start, strategy, strategy == 4 )
    else
        local settings = LEVELS[ level ]
        if settings[ 5 ] then
            compress_lazy( writer, raw_data, data_length, start, settings, strategy )
        else
            compress_fast( writer, raw_data, data_length, start, settings, strategy )
        end
    end

    local length = writer.length

    if writer.bit_count ~= 0 then
        writer.bytes[ length ] = writer.bit_buffer
        length = length + 1
    end

    local compressed_data = bytes_to_string( writer.bytes, 0, length )
    release_bytes( writer.bytes, length )

    return compressed_data
end

-- Decompression --

-- Decoding table entries are `( value * 8 + kind ) * 16 + bit count`, the bit count is how many bits the code takes,
-- the value is a byte for literals, `base * 16 + extra bits` for lengths and distances,
-- and `offset * 16 + index bits` for links to the second level tables of codes longer than the first level index.

local LITERAL = 0
local LENGTH = 1
local END_OF_BLOCK = 2
local LINK = 3
local INVALID = 4
local DISTANCE = 5

local INVALID_ENTRY = INVALID * 16

local LITERAL_BITS = 10
local LITERAL_MASK = rbit_lshift( 1, LITERAL_BITS ) - 1

local DISTANCE_BITS = 8
local DISTANCE_MASK = rbit_lshift( 1, DISTANCE_BITS ) - 1

local CODE_LENGTH_BITS = 7
local CODE_LENGTH_MASK = rbit_lshift( 1, CODE_LENGTH_BITS ) - 1

---@type integer[]
local LITERAL_VALUES = {}

---@type integer[]
local DISTANCE_VALUES = {}

---@type integer[]
local CODE_LENGTH_VALUES = {}

do

    for symbol = 0, 255, 1 do
        LITERAL_VALUES[ symbol ] = symbol * 8 + LITERAL
    end

    LITERAL_VALUES[ 256 ] = END_OF_BLOCK

    for code = 0, 28, 1 do
        LITERAL_VALUES[ 257 + code ] = (LENGTH_BASE[ code ] * 16 + LENGTH_EXTRA[ code ]) * 8 + LENGTH
    end

    LITERAL_VALUES[ 286 ], LITERAL_VALUES[ 287 ] = INVALID, INVALID

    for code = 0, 29, 1 do
        DISTANCE_VALUES[ code ] = (DISTANCE_BASE[ code ] * 16 + DISTANCE_EXTRA[ code ]) * 8 + DISTANCE
    end

    DISTANCE_VALUES[ 30 ], DISTANCE_VALUES[ 31 ] = INVALID, INVALID

    for symbol = 0, 18, 1 do
        CODE_LENGTH_VALUES[ symbol ] = symbol * 8 + LITERAL
    end

end

---@type integer[]
local length_counts = {}

--- Builds the two level decoding table of the code lengths, like zlib's `inflate_table`.
---
--- Codes with a single 1 bit code are the only incomplete codes allowed (`allow_single`),
--- codes without any symbols make tables that only have invalid entries.
---
---@param lengths integer[]
---@param first integer
---@param symbol_count integer
---@param values integer[]
---@param root_bits integer
---@param decoding_table integer[]
---@param allow_single boolean
---@return boolean | nil success
---@return nil | string error_message
local function build_table( lengths, first, symbol_count, values, root_bits, decoding_table, allow_single )
    for length = 0, 15, 1 do
        length_counts[ length ] = 0
    end

    for symbol = first, first + symbol_count - 1, 1 do
        local length = lengths[ symbol ]
        length_counts[ length ] = length_counts[ length ] + 1
    end

    local root_size = rbit_lshift( 1, root_bits )

    for i = 0, root_size - 1, 1 do
        decoding_table[ i ] = INVALID_ENTRY
    end

    local max_length = 15
    while max_length ~= 0 and length_counts[ max_length ] == 0 do
        max_length = max_length - 1
    end

    if max_length == 0 then
        return true
    end

    local left = 1

    for length = 1, 15, 1 do
        left = left * 2 - length_counts[ length ]
        if left < 0 then
            return nil, "over-subscribed code lengths"
        end
    end

    if left > 0 and not (allow_single and max_length == 1) then
        return nil, "incomplete code lengths"
    end

    local code = 0
    length_counts[ 0 ] = 0

    for length = 1, 15, 1 do
        code = (code + length_counts[ length - 1 ]) * 2
        next_codes[ length ] = code
    end

    -- codes that fit into the first level fill every entry that starts with them
    for symbol = 0, symbol_count - 1, 1 do
        local length = lengths[ first + symbol ]
        if length ~= 0 and length <= root_bits then
            local next_code = next_codes[ length ]
            next_codes[ length ] = next_code + 1

            local entry = values[ symbol ] * 16 + length

            for i = reverse_bits( next_code, length ), root_size - 1, rbit_lshift( 1, length ) do
                decoding_table[ i ] = entry
            end
        end
    end

    -- longer codes are in canonical order, so the codes of every first level prefix go one after another,
    -- the second level table of the prefix is sized to fit all of them
    local next_offset = root_size
    local table_prefix, table_offset, table_end = -1, 0, 0

    for length = root_bits + 1, max_length, 1 do
        local sub_length = length - root_bits
        local step = rbit_lshift( 1, sub_length )

        for symbol = 0, symbol_count - 1, 1 do
            if lengths[ first + symbol ] == length then
                local next_code = next_codes[ length ]
                next_codes[ length ] = next_code + 1

                local prefix = rbit_rshift( next_code, sub_length )

                if prefix ~= table_prefix then
                    local table_bits = sub_length
                    left = step

                    while table_bits + root_bits < max_length do
                        left = left - length_counts[ table_bits + root_bits ]
                        if left <= 0 then
                            break
                        end

                        table_bits = table_bits + 1
                        left = left * 2
                    end

                    table_prefix, table_offset = prefix, next_offset
                    table_end = table_offset + rbit_lshift( 1, table_bits )
                    next_offset = table_end

                    for i = table_offset, table_end - 1, 1 do
                        decoding_table[ i ] = INVALID_ENTRY
                    end

                    decoding_table[ reverse_bits( prefix, root_bits ) ] = ((table_offset * 16 + table_bits) * 8 + LINK) * 16 + root_bits
                end

                local entry = values[ symbol ] * 16 + sub_length

                for i = table_offset + reverse_bits( rbit_band( next_code, step - 1 ), sub_length ), table_end - 1, step do
                    decoding_table[ i ] = entry
                end

                length_counts[ length ] = length_counts[ length ] - 1
            end
        end
    end

    return true
end

-- Second level tables take at most 1504 entries for literals/lengths and 384 for distances,
-- a complete code needs `n + 1` codes for a table of `n` bits.
local literal_table = new_integers( 4096 )
local distance_table = new_integers( 1024 )

local code_length_table = new_integers( 128 )

local FIXED_LITERAL_TABLE = new_integers( rbit_lshift( 1, LITERAL_BITS ) )
local FIXED_DISTANCE_TABLE = new_integers( rbit_lshift( 1, DISTANCE_BITS ) )

build_table( FIXED_LITERAL_LENGTHS, 0, 288, LITERAL_VALUES, LITERAL_BITS, FIXED_LITERAL_TABLE, false )
build_table( FIXED_DISTANCE_LENGTHS, 0, 32, DISTANCE_VALUES, DISTANCE_BITS, FIXED_DISTANCE_TABLE, false )

--- Reads 16 more bits, bytes past the end of the data are zeros.
---
---@param data string
---@param position integer
---@param bit_buffer integer
---@param bit_count integer
---@return integer position
---@return integer bit_buffer
---@return integer bit_count
local function refill( data, position, bit_buffer, bit_count )
    local uint8_1, uint8_2 = string_byte( data, position, position + 1 )
    return position + 2, rbit_bor( bit_buffer, rbit_lshift( (uint8_1 or 0) + (uint8_2 or 0) * 0x100, bit_count ) ), bit_count + 16
end

---@type integer[]
local code_lengths = {}

--- Reads the code lengths of a dynamic block and builds its tables.
---
---@param data string
---@param position integer
---@param bit_buffer integer
---@param bit_count integer
---@return integer | nil position
---@return integer | string bit_buffer The bit buffer, or the error message.
---@return integer? bit_count
local function read_dynamic_tables( data, position, bit_buffer, bit_count )
    if bit_count < 16 then
        position, bit_buffer, bit_count = refill( data, position, bit_buffer, bit_count )
    end

    local literal_count = rbit_band( bit_buffer, 0x1F ) + 257
    local distance_count = rbit_band( rbit_rshift( bit_buffer, 5 ), 0x1F ) + 1
    local code_length_count = rbit_band( rbit_rshift( bit_buffer, 10 ), 0xF ) + 4

    bit_buffer = rbit_rshift( bit_buffer, 14 )
    bit_count = bit_count - 14

    if literal_count > 286 or distance_count > 30 then
        return nil, "too many length or distance symbols"
    end

    for i = 1, 19, 1 do
        local length = 0

        if i <= code_length_count then
            if bit_count < 16 then
                position, bit_buffer, bit_count = refill( data, position, bit_buffer, bit_count )
            end

            length = rbit_band( bit_buffer, 7 )
            bit_buffer = rbit_rshift( bit_buffer, 3 )
            bit_count = bit_count - 3
        end

        code_lengths[ CODE_LENGTH_ORDER[ i ] ] = length
    end

    local success, error_message = build_table( code_lengths, 0, 19, CODE_LENGTH_VALUES, CODE_LENGTH_BITS, code_length_table, false )
    if not success then
        return nil, "invalid code length code: " .. error_message
    end

    local length_count = literal_count + distance_count
    local index = 0

    while index < length_count do
        if bit_count < 16 then
            position, bit_buffer, bit_count = refill( data, position, bit_buffer, bit_count )
        end

        local entry = code_length_table[ rbit_band( bit_buffer, CODE_LENGTH_MASK ) ]
        if entry == INVALID_ENTRY then
            return nil, "invalid code length code"
        end

        local entry_bits = rbit_band( entry, 15 )
        bit_buffer = rbit_rshift( bit_buffer, entry_bits )
        bit_count = bit_count - entry_bits

        local symbol = rbit_rshift( entry, 7 )

        if symbol < 16 then
            code_lengths[ index ] = symbol
            index = index + 1
        else
            local length, repeat_count = 0, 0

            if symbol == 16 then
                if index == 0 then
                    return nil, "repeated code length without a previous one"
                end

                length = code_lengths[ index - 1 ]
                repeat_count = 3 + rbit_band( bit_buffer, 3 )

                bit_buffer = rbit_rshift( bit_buffer, 2 )
                bit_count = bit_count - 2
            elseif symbol == 17 then
                repeat_count = 3 + rbit_band( bit_buffer, 7 )

                bit_buffer = rbit_rshift( bit_buffer, 3 )
                bit_count = bit_count - 3
            else
                repeat_count = 11 + rbit_band( bit_buffer, 0x7F )

                bit_buffer = rbit_rshift( bit_buffer, 7 )
                bit_count = bit_count - 7
            end

            if index + repeat_count > length_count then
                return nil, "repeated code lengths past the end"
            end

            for i = index, index + repeat_count - 1, 1 do
                code_lengths[ i ] = length
            end

            index = index + repeat_count
        end
    end

    if code_lengths[ 256 ] == 0 then
        return nil, "missing end-of-block code"
    end

    success, error_message = build_table( code_lengths, 0, literal_count, LITERAL_VALUES, LITERAL_BITS, literal_table, true )
    if not success then
        return nil, "invalid literal/length code: " .. error_message
    end

    success, error_message = build_table( code_lengths, literal_count, distance_count, DISTANCE_VALUES, DISTANCE_BITS, distance_table, true )
    if not success then
        return nil, "invalid distance code: " .. error_message
    end

    return position, bit_buffer, bit_count
end

--- Decodes literals and matches until the end of the block.
---
---@param data string
---@param position_limit integer The data is truncated if the position is past it.
---@param position integer
---@param bit_buffer integer
---@param bit_count integer
---@param bytes dreamwork.std.deflate.Bytes
---@param length integer
---@param capacity integer
---@param literals integer[]
---@param distances integer[]
---@return integer | nil position
---@return integer | string bit_buffer The bit buffer, or the error message.
---@return integer? bit_count
---@return dreamwork.std.deflate.Bytes? bytes
---@return integer? length
---@return integer? capacity
local function inflate_block( data, position_limit, position, bit_buffer, bit_count, bytes, length, capacity, literals, distances )
    while true do
        if bit_count < 16 then
            position, bit_buffer, bit_count = refill( data, position, bit_buffer, bit_count )

            if position > position_limit then
                return nil, "truncated data"
            end
        end

        local entry = literals[ rbit_band( bit_buffer, LITERAL_MASK ) ]
        local kind = rbit_band( rbit_rshift( entry, 4 ), 7 )

        if kind == LINK then
            bit_buffer = rbit_rshift( bit_buffer, LITERAL_BITS )
            bit_count = bit_count - LITERAL_BITS

            local link = rbit_rshift( entry, 7 )
            entry = literals[ rbit_rshift( link, 4 ) + rbit_band( bit_buffer, rbit_lshift( 1, rbit_band( link, 15 ) ) - 1 ) ]
            kind = rbit_band( rbit_rshift( entry, 4 ), 7 )
        end

        local entry_bits = rbit_band( entry, 15 )
        bit_buffer = rbit_rshift( bit_buffer, entry_bits )
        bit_count = bit_count - entry_bits

        if kind == LITERAL then
            if length == capacity then
                bytes, capacity = grow_bytes( bytes, length, capacity * 2 )
            end

            bytes[ length ] = rbit_rshift( entry, 7 )
            length = length + 1
        elseif kind == LENGTH then
            local value = rbit_rshift( entry, 7 )
            local extra = rbit_band( value, 15 )

            if bit_count < 16 then
                position, bit_buffer, bit_count = refill( data, position, bit_buffer, bit_count )
            end

            local match_length = rbit_rshift( value, 4 ) + rbit_band( bit_buffer, rbit_lshift( 1, extra ) - 1 )
            bit_buffer = rbit_rshift( bit_buffer, extra )
            bit_count = bit_count - extra

            if bit_count < 16 then
                position, bit_buffer, bit_count = refill( data, position, bit_buffer, bit_count )
            end

            entry = distances[ rbit_band( bit_buffer, DISTANCE_MASK ) ]
            kind = rbit_band( rbit_rshift( entry, 4 ), 7 )

            if kind == LINK then
                bit_buffer = rbit_rshift( bit_buffer, DISTANCE_BITS )
                bit_count = bit_count - DISTANCE_BITS

                local link = rbit_rshift( entry, 7 )
                entry = distances[ rbit_rshift( link, 4 ) + rbit_band( bit_buffer, rbit_lshift( 1, rbit_band( link, 15 ) ) - 1 ) ]
                kind = rbit_band( rbit_rshift( entry, 4 ), 7 )
            end

            if kind ~= DISTANCE then
                return nil, "invalid distance code"
            end

            entry_bits = rbit_band( entry, 15 )
            bit_buffer = rbit_rshift( bit_buffer, entry_bits )
            bit_count = bit_count - entry_bits

            value = rbit_rshift( entry, 7 )
            extra = rbit_band( value, 15 )

            if bit_count < 16 then
                position, bit_buffer, bit_count = refill( data, position, bit_buffer, bit_count )
            end

            local distance = rbit_rshift( value, 4 ) + rbit_band( bit_buffer, rbit_lshift( 1, extra ) - 1 )
            bit_buffer = rbit_rshift( bit_buffer, extra )
            bit_count = bit_count - extra

            if distance > length then
                return nil, "invalid distance too far back"
            end

            if length + match_length + 3 > capacity then
                bytes, capacity = grow_bytes( bytes, length, math_max( capacity * 2, length + match_length + 3 ) )
            end

            -- forward copy, so a match that overlaps itself repeats its bytes
            copy_match( bytes, length, length - distance, match_length )

            length = length + match_length
        elseif kind == END_OF_BLOCK then
            return position, bit_buffer, bit_count, bytes, length, capacity
        else
            return nil, "invalid literal/length code"
        end
    end
end

--- [SHARED AND MENU]
---
--- Decompresses a raw DEFLATE stream.
---
--- Throws an error on malformed or truncated data; call via `pcall()` when processing untrusted input.
---
--- The stream may be followed by other data (like the zlib or gzip trailer),
--- the second return value is the position right after the stream.
---
---@param compressed_data string The DEFLATE stream to decompress.
---@param dictionary? string The preset dictionary the data was compressed with.
---@param start_position? integer The position of the stream in the string, `1` by default.
---@return string decompressed_data The decompressed string.
---@return integer end_position The position of the first byte after the stream.
---@nodiscard
function deflate.decompress( compressed_data, dictionary, start_position )
    if start_position == nil then
        start_position = 1
    elseif not (start_position % 1 == 0 and start_position >= 1) then
        error( "start_position must be a positive integer", 2 )
    end

    local data_length = string_len( compressed_data )

    -- the bit buffer may read up to 4 bytes past the end of a valid stream
    local position_limit = data_length + 5

    local dictionary_length = 0
    if dictionary ~= nil then
        dictionary_length = string_len( dictionary )
        if dictionary_length > WINDOW_SIZE then
            dictionary, dictionary_length = string_sub( dictionary, -WINDOW_SIZE ), WINDOW_SIZE
        end
    end

    local bytes, capacity = get_bytes( dictionary_length + math_max( (data_length - start_position + 1) * 4, 0x1000 ) )
    local length = 0

    if dictionary_length ~= 0 then
        ---@cast dictionary string
        copy_string( bytes, 0, dictionary, 1, dictionary_length )
        length = dictionary_length
    end

    local position, bit_buffer, bit_count = start_position, 0, 0

    while true do
        if bit_count < 16 then
            position, bit_buffer, bit_count = refill( compressed_data, position, bit_buffer, bit_count )
        end

        local is_last = rbit_band( bit_buffer, 1 ) == 1
        local block_type = rbit_band( rbit_rshift( bit_buffer, 1 ), 3 )

        bit_buffer = rbit_rshift( bit_buffer, 3 )
        bit_count = bit_count - 3

        -- the bit buffer, or the error message
        ---@type integer | string
        local result

        if block_type == 0 then
            -- the rest of the byte is skipped, buffered whole bytes go back to the data
            position = position - rbit_rshift( bit_count, 3 )
            bit_buffer, bit_count = 0, 0

            local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( compressed_data, position, position + 3 )
            if uint8_4 == nil then
                error( "corrupt DEFLATE data: truncated stored block", 2 )
            end

            local size = uint8_1 + uint8_2 * 0x100
            if rbit_bxor( size, 0xFFFF ) ~= uint8_3 + uint8_4 * 0x100 then
                error( "corrupt DEFLATE data: invalid stored block lengths", 2 )
            end

            position = position + 4

            if position + size - 1 > data_length then
                error( "corrupt DEFLATE data: truncated stored block", 2 )
            end

            if length + size > capacity then
                bytes, capacity = grow_bytes( bytes, length, math_max( capacity * 2, length + size ) )
            end

            copy_string( bytes, length, compressed_data, position, size )

            length = length + size
            position = position + size
        else
            -- `nil` on errors
            local next_position, next_bit_count, next_bytes, next_length, next_capacity

            if block_type == 1 then
                next_position, result, next_bit_count, next_bytes, next_length, next_capacity = inflate_block( compressed_data, position_limit, position, bit_buffer, bit_count, bytes, length, capacity, FIXED_LITERAL_TABLE, FIXED_DISTANCE_TABLE )
            elseif block_type == 2 then
                next_position, result, next_bit_count = read_dynamic_tables( compressed_data, position, bit_buffer, bit_count )

                if next_position ~= nil then
                    ---@cast result integer
                    ---@cast next_bit_count integer
                    next_position, result, next_bit_count, next_bytes, next_length, next_capacity = inflate_block( compressed_data, position_limit, next_position, result, next_bit_count, bytes, length, capacity, literal_table, distance_table )
                end
            else
                error( "corrupt DEFLATE data: invalid block type", 2 )
            end

            if next_position == nil then
                error( "corrupt DEFLATE data: " .. result, 2 )
            end

            ---@cast next_bit_count integer
            ---@cast next_bytes dreamwork.std.deflate.Bytes
            ---@cast next_length integer
            ---@cast next_capacity integer

            position, bit_count, bytes, length, capacity = next_position, next_bit_count, next_bytes, next_length, next_capacity

            ---@cast result integer
            bit_buffer = result
        end

        if is_last then
            break
        end
    end

    -- the last byte of the stream is partially read, whole bytes in the buffer are not a part of it
    local end_position = position - rbit_rshift( bit_count, 3 )
    if end_position > data_length + 1 then
        error( "corrupt DEFLATE data: truncated data", 2 )
    end

    local decompressed_data = bytes_to_string( bytes, dictionary_length, length - dictionary_length )
    release_bytes( bytes, length )

    return decompressed_data, end_position
end
