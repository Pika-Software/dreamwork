local glua_util = util

local holylib_CompressLZ4, holylib_DecompressLZ4
if glua_util ~= nil then
    holylib_CompressLZ4 = glua_util.CompressLZ4
    holylib_DecompressLZ4 = glua_util.DecompressLZ4
end

---@class dreamwork.std
local std = dreamwork.std

local error = std.error

local rbit = std.raw.bit
local rbit_band, rbit_bor = rbit.band, rbit.bor
local rbit_lshift, rbit_rshift = rbit.lshift, rbit.rshift

local math = std.math
local math_min = math.min

local string = std.string
local string_len = string.len
local string_sub = string.sub
local string_char = string.char
local string_byte = string.byte

local table = std.table
local table_concat = table.concat
local table_unpack = table.unpack


--- [SHARED AND MENU]
---
--- LZ4 is lossless compression algorithm, providing compression speed > 500 MB/s per core (>0.15 Bytes/cycle).
---
--- Produces and consumes raw [LZ4 blocks](https://github.com/lz4/lz4/blob/dev/doc/lz4_Block_format.md)
--- (no frame header, no checksum, no stored size) compatible with the reference `LZ4_compress_fast` / `LZ4_decompress_safe`.
---
---@class dreamwork.std.lz4
local lz4 = {}
std.lz4 = lz4


local MIN_MATCH = 4         -- A sequence is 3 bytes, so it has to encode at least 4 to have any use
local MFLIMIT = 12          -- The last match must start at least 12 bytes before the end of the block
local LAST_LITERALS = 5     -- The last 5 bytes of the block are always literals
local MISS_COUNTER_BITS = 6 -- Lower values = the step is incremented sooner
local HASH_BITS = 16
local HASH_SHIFT = 32 - HASH_BITS
local MAX_DISTANCE = 0xFFFF -- Maximum offset that can fit into two bytes

local LIT_COUNT_BITS = 4
local LIT_COUNT_MASK = rbit_lshift( 1, LIT_COUNT_BITS ) - 1

local MATCH_LEN_BITS = 4
local MATCH_LEN_MASK = rbit_lshift( 1, MATCH_LEN_BITS ) - 1

-- The hash is `( sequence * 2654435761 ) mod 2^32 >> HASH_SHIFT`, the magic constant was taken from
-- https://github.com/lz4/lz4/blob/836decd8a898475dcd21ed46768157f4420c9dd2/lib/lz4.c#L782
--
-- A plain `sequence * 2654435761` can be as large as ~1.14e19, which silently loses precision,
-- so the sequence and the multiplier are split into 16-bit halves: low*low stays as-is and the
-- cross terms only matter modulo 2^16 (`rbit.lshift` drops the rest), keeping everything below 2^53.
local HASH_MULT_LO = 0x79B1 -- 2654435761 & 0xFFFF
local HASH_MULT_HI = 0x9E37 -- 2654435761 >> 16

--- Writes the extra bytes of a literal count / match length that did not fit into the token.
---@param out string[]
---@param output_size integer
---@param remaining integer
---@return integer
local function writeLength( out, output_size, remaining )
    while remaining >= 0xFF do
        output_size = output_size + 1
        out[ output_size ] = "\255"
        remaining = remaining - 0xFF
    end

    output_size = output_size + 1
    out[ output_size ] = string_char( remaining )

    return output_size
end

if holylib_CompressLZ4 == nil then

    -- Shared between calls and pre-filled so it stays a dense array (no rehashing, no `nil` checks).
    -- Positions are stored with a per-call base that keeps growing, so entries left over from
    -- previous calls always look further away than MAX_DISTANCE and never have to be cleared.
    local hashTable = {}
    local hashBase = 0

    for i = 0, rbit_lshift( 1, HASH_BITS ) - 1, 1 do
        hashTable[ i ] = -MAX_DISTANCE - 1
    end

    --- [SHARED AND MENU]
    ---
    --- Compresses a string into a raw LZ4 block.
    ---
    --- The block does not store the uncompressed size, keep it alongside
    --- the block if the receiving side needs to know it in advance.
    ---
    ---@param data string The string to compress.
    ---@param acceleration? integer A positive integer, defaults to `1`. Higher values may increase the compression speed, especially on incompressible data, at the cost of compression efficiency.
    ---@return string compressed The compressed data as a string.
    ---@nodiscard
    function lz4.compress( data, acceleration )
        if acceleration == nil then
            acceleration = 1
        elseif not (acceleration >= 1) then
            error( "acceleration must be an integer >= 1", 2 )
        end

        ---@type string[]
        local output = {}
        local output_size = 0

        local index, dataLen = 1, string_len( data ) -- 1-indexed
        local nextUnencodedPos = index               -- Sometimes called the "anchor" in other implementations

        local mfLimit = dataLen - MFLIMIT + 1        -- Last index a match may start at
        local matchLimit = dataLen - LAST_LITERALS   -- Last index a match may cover

        local base = hashBase
        if base > 0x10000000000000 then -- 2^52, keeps the stored positions exact
            for i = 0, rbit_lshift( 1, HASH_BITS ) - 1, 1 do
                hashTable[ i ] = -MAX_DISTANCE - 1
            end

            base = 0
        end

        hashBase = base + dataLen + MAX_DISTANCE + 1

        -- The lower MISS_COUNTER_BITS bits are the miss counter, upper bits are the step. The step
        -- starts at `acceleration` and increments every time the miss counter overflows.
        local stepAndMissCounterInit = rbit_lshift( acceleration, MISS_COUNTER_BITS )
        local stepAndMissCounter = stepAndMissCounterInit

        while index <= mfLimit do
            local b1, b2, b3, b4 = string_byte( data, index, index + 3 )

            local seqLo = b3 * 0x100 + b4
            local hash = rbit_rshift( seqLo * HASH_MULT_LO + rbit_lshift( (b1 * 0x100 + b2) * HASH_MULT_LO + seqLo * HASH_MULT_HI, 16 ), HASH_SHIFT )

            -- Check and update match
            local matchPos = hashTable[ hash ] - base
            hashTable[ hash ] = base + index

            -- Determine if there is a match in range
            if index - matchPos > MAX_DISTANCE then
                index = index + rbit_rshift( stepAndMissCounter, MISS_COUNTER_BITS ) -- Extract and add the step part
                stepAndMissCounter = stepAndMissCounter + 1
                goto lz4_compress_loop
            end

            do
                -- Hash collision check
                local m1, m2, m3, m4 = string_byte( data, matchPos, matchPos + 3 )
                if m1 ~= b1 or m2 ~= b2 or m3 ~= b3 or m4 ~= b4 then
                    index = index + rbit_rshift( stepAndMissCounter, MISS_COUNTER_BITS )
                    stepAndMissCounter = stepAndMissCounter + 1
                    goto lz4_compress_loop
                end
            end

            stepAndMissCounter = stepAndMissCounterInit

            do
                local matchOffset = index - matchPos

                -- Try to extend backwards
                while index > nextUnencodedPos and matchPos > 1 and string_byte( data, index - 1 ) == string_byte( data, matchPos - 1 ) do
                    index = index - 1
                    matchPos = matchPos - 1
                end

                local literalCount = index - nextUnencodedPos

                -- Skip the 4 bytes we already matched
                index = index + MIN_MATCH
                matchPos = matchPos + MIN_MATCH

                -- Determine match length
                -- NOTE: matchLength does not include MIN_MATCH; it is added during decoding
                local matchStart = index
                while index <= matchLimit and string_byte( data, index ) == string_byte( data, matchPos ) do
                    index = index + 1
                    matchPos = matchPos + 1
                end

                local matchLength = index - matchStart

                -- Write token
                output_size = output_size + 1
                output[ output_size ] = string_char( rbit_bor(
                    rbit_lshift( literalCount < LIT_COUNT_MASK and literalCount or LIT_COUNT_MASK, MATCH_LEN_BITS ),
                    matchLength < MATCH_LEN_MASK and matchLength or MATCH_LEN_MASK
                ) )

                -- Write literal count
                if literalCount >= LIT_COUNT_MASK then
                    output_size = writeLength( output, output_size, literalCount - LIT_COUNT_MASK )
                end

                -- Write literals
                if literalCount ~= 0 then
                    output_size = output_size + 1
                    output[ output_size ] = string_sub( data, nextUnencodedPos, nextUnencodedPos + literalCount - 1 )
                end

                -- Write offset (little-endian)
                output_size = output_size + 1
                output[ output_size ] = string_char( rbit_band( matchOffset, 0xFF ), rbit_rshift( matchOffset, 8 ) )


                -- Write match length
                if matchLength >= MATCH_LEN_MASK then
                    output_size = writeLength( output, output_size, matchLength - MATCH_LEN_MASK )
                end

                -- Move the anchor
                nextUnencodedPos = index

                -- Remember a position inside the match, improves the ratio on repetitive data
                local p = index - 2
                if p <= mfLimit then
                    local p1, p2, p3, p4 = string_byte( data, p, p + 3 )
                    local pLo = p3 * 0x100 + p4
                    hashTable[ rbit_rshift( pLo * HASH_MULT_LO + rbit_lshift( (p1 * 0x100 + p2) * HASH_MULT_LO + pLo * HASH_MULT_HI, 16 ), HASH_SHIFT ) ] = base + p
                end
            end

            ::lz4_compress_loop::
        end

        -- Write remaining token (only literals, match length is 0)
        local literalCount = dataLen - nextUnencodedPos + 1

        output_size = output_size + 1
        output[ output_size ] = string_char( rbit_lshift( literalCount < LIT_COUNT_MASK and literalCount or LIT_COUNT_MASK, MATCH_LEN_BITS ) )

        -- Write remaining literal count
        if literalCount >= LIT_COUNT_MASK then
            output_size = writeLength( output, output_size, literalCount - LIT_COUNT_MASK )
        end

        -- Write remaining literals
        output_size = output_size + 1
        output[ output_size ] = string_sub( data, nextUnencodedPos )

        return table_concat( output, "", 1, output_size )
    end

else
    lz4.compress = holylib_CompressLZ4
end

if holylib_DecompressLZ4 == nil then

    --- Bytes per `string.char` call, has to stay well below the C stack limit
    local CHUNK_SIZE = 4096

    --- [SHARED AND MENU]
    ---
    --- Decompresses a raw LZ4 block.
    ---
    --- Throws an error on malformed input (truncated lengths/literals, offsets pointing
    --- before the start of the output, a block not ending with literals); call via `pcall()`
    --- when processing untrusted input.
    ---
    --- LZ4 blocks carry no checksum, so corrupted data may still decode into wrong output,
    --- and a block cut exactly at a sequence boundary is indistinguishable from a shorter valid block.
    ---
    ---@param data string The LZ4 block to decompress.
    ---@return string decompressed The decompressed string.
    ---@nodiscard
    function lz4.decompress( data )
        ---@type byte[]
        local output = {}
        local output_size = 0

        local index = 1 -- 1-indexed
        local dataLen = string_len( data )

        while index <= dataLen do
            local token = string_byte( data, index )
            index = index + 1

            -- Literals --
            local literalCount = rbit_rshift( token, MATCH_LEN_BITS )

            -- Read literal count
            if literalCount == LIT_COUNT_MASK then
                repeat
                    local lenPart = string_byte( data, index )
                    if lenPart == nil then
                        error( "corrupt LZ4 data: truncated literal length", 2 )
                    end

                    index = index + 1
                    literalCount = literalCount + lenPart
                until lenPart ~= 0xFF
            end

            -- Copy literals (if any)
            local literalEnd = index + literalCount - 1
            if literalEnd > dataLen then
                error( "corrupt LZ4 data: literals exceed input", 2 )
            end

            for j = index, literalEnd, 1 do
                output_size = output_size + 1
                output[ output_size ] = string_byte( data, j )
            end

            index = literalEnd + 1

            if index > dataLen then
                break -- This was the last sequence (which has no match part)
            end

            -- Match
            if index == dataLen then
                error( "corrupt LZ4 data: truncated match offset", 2 )
            end

            local offsetA, offsetB = string_byte( data, index, index + 1 )
            local matchStart = output_size - (offsetA + offsetB * 0x100)
            index = index + 2

            if matchStart < 0 or matchStart == output_size then
                error( "corrupt LZ4 data: invalid match offset", 2 )
            end

            -- Read match length
            local matchLength = rbit_band( token, MATCH_LEN_MASK )
            if matchLength == MATCH_LEN_MASK then
                repeat
                    local lenPart = string_byte( data, index )
                    if lenPart == nil then
                        error( "corrupt LZ4 data: truncated match length", 2 )
                    end

                    index = index + 1
                    matchLength = matchLength + lenPart
                until lenPart ~= 0xFF
            end

            matchLength = matchLength + MIN_MATCH

            -- Copy match (byte by byte, source and destination may overlap)
            for i = 1, matchLength, 1 do
                output[ output_size + i ] = output[ matchStart + i ]
            end

            output_size = output_size + matchLength

            if index > dataLen then
                error( "corrupt LZ4 data: block must end with literals", 2 )
            end
        end

        if output_size <= CHUNK_SIZE then
            return string_char( table_unpack( output, 1, output_size ) )
        end

        ---@type string[]
        local chunks = {}
        local chunk_count = 0

        for i = 1, output_size, CHUNK_SIZE do
            chunk_count = chunk_count + 1
            chunks[ chunk_count ] = string_char( table_unpack( output, i, math_min( i + CHUNK_SIZE - 1, output_size ) ) )
        end

        return table_concat( chunks, "", 1, chunk_count )
    end

else
    lz4.decompress = holylib_DecompressLZ4
end
