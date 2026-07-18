---@class dreamwork.std
local std = dreamwork.std

-- https://holylib.raphaelit7.com/util
local holylib_CompressLZ4 = util ~= nil and util.CompressLZ4
local holylib_DecompressLZ4 = util ~= nil and util.DecompressLZ4

--- [SHARED AND MENU]
---
--- LZ4 is lossless compression algorithm, providing compression speed > 500 MB/s per core (>0.15 Bytes/cycle).
---
--- [Source Code](https://github.com/RiskoZS/llz4)
---
--- Author: [RiskoZS](https://github.com/RiskoZS)
---
--- Edited by Unknown Developer
---
---@class dreamwork.std.lz4
local lz4 = {}
std.lz4 = lz4

local bit = std.bit
local bit_band, bit_bor = bit.band, bit.bor
local bit_lshift, bit_rshift = bit.lshift, bit.rshift

local string = std.string
local string_sub = string.sub
local string_char = string.char
local string_byte = string.byte

local table = std.table
local table_concat = table.concat

local bytepack = std.bytepack
local bytepack_readUInt32 = bytepack.readUInt32

local MIN_MATCH = 4 -- A sequence is 3 bytes, so it has to encode at least 4 to have any use
local MIN_LENGTH = 13
local MIN_TRAILING_LITERALS = 5
local MISS_COUNTER_BITS = 6 -- Lower values = the step is incremented sooner
local HASH_SHIFT = 32 - 16  -- 32 - # of bits in the hash
local MAX_DISTANCE = 0xFFFF -- Maximum offset that can fit into two bytes

local LIT_COUNT_BITS = 4
local LIT_COUNT_MASK = bit_lshift( 1, LIT_COUNT_BITS ) - 1

local MATCH_LEN_BITS = 4
local MATCH_LEN_MASK = bit_lshift( 1, MATCH_LEN_BITS ) - 1

-- The hash multiplier used below, split into 16-bit halves so that the
-- 32x32 -> 32 bit multiplication can be performed without exceeding
-- Lua's 2^53 exact-integer precision (a plain `sequence * 2654435761`
-- can be as large as ~1.14e19, which silently loses precision and
-- produces a corrupted hash before the bit ops ever see it).
local HASH_MULT = 2654435761
local HASH_MULT_LO = bit_band( HASH_MULT, 0xFFFF )
local HASH_MULT_HI = bit_rshift( HASH_MULT, 16 )

--- Computes `( sequence * 2654435761 ) mod 2^32` without precision loss,
--- then returns the top bits used as the hash table index.
---@param sequence integer
---@return integer
local function hashSequence( sequence )
    local seqLo = bit_band( sequence, 0xFFFF )
    local seqHi = bit_rshift( sequence, 16 )

    -- low*low stays as-is; the cross terms only need their low 16 bits
    -- (anything beyond that would only affect bits >= 32, which are
    -- discarded anyway), keeping every intermediate value well under 2^53.
    local lowLow = seqLo * HASH_MULT_LO
    local cross = bit_band( seqHi * HASH_MULT_LO + seqLo * HASH_MULT_HI, 0xFFFF )
    local product32 = lowLow + bit_lshift( cross, 16 )

    return bit_rshift( product32, HASH_SHIFT )
end

if holylib_CompressLZ4 == nil then

    --- [SHARED AND MENU]
    ---
    --- Compresses a string using the LZ4 block format.
    ---
    ---@param data string The string to compress.
    ---@param acceleration? integer A positive integer, defaults to 1. Higher values may increase the compression speed, especially on incompressible data, at the cost of compression efficiency.
    ---@return string The compressed data as a string.
    function lz4.compress( data, acceleration )
        if acceleration == nil then
            acceleration = 1
        else
            assert( acceleration >= 1, "acceleration must be an integer >= 1" )
        end

        local hashTable = {}
        local out, outNext = {}, 1

        local index, dataLen = 1, #data -- 1-indexed
        local nextUnencodedPos = index  -- Sometimes called the "anchor" in other implementations

        if dataLen >= MIN_LENGTH then
            -- The lower MISS_COUNTER_BITS bits are the miss counter, upper bits are the step. The step
            -- starts at `acceleration` and increments every time the miss counter overflows.
            local stepAndMissCounterInit = bit_lshift( acceleration, MISS_COUNTER_BITS )
            local stepAndMissCounter = stepAndMissCounterInit

            while index + MIN_MATCH <= dataLen - MIN_TRAILING_LITERALS do
                local sequence = bytepack_readUInt32( string_byte( data, index, index + 3 ) )
                local hash = hashSequence( sequence )

                -- local hash = bit_rshift( sequence * 2654435761, HASH_SHIFT )
                -- ^ This is awfully simple for a hash function, but it's fast and seems to give pretty good results. The
                -- magic constant was taken from https://github.com/lz4/lz4/blob/836decd8a898475dcd21ed46768157f4420c9dd2/lib/lz4.c#L782

                -- Check and update match
                local matchPos = hashTable[ hash ]
                hashTable[ hash ] = index

                -- Determine if there is a match in range
                if not matchPos or index - matchPos > MAX_DISTANCE or bytepack_readUInt32( string_byte( data, matchPos, matchPos + 3 ) ) ~= sequence then
                    index = index + bit_rshift( stepAndMissCounter, MISS_COUNTER_BITS ) -- Extract and add the step part
                    stepAndMissCounter = stepAndMissCounter + 1
                    goto lz4_compress_loop
                end

                stepAndMissCounter = stepAndMissCounterInit

                -- Calculate literal count and offset
                local literalCount = index - nextUnencodedPos
                local matchOffset = index - matchPos

                -- Try to extend backwards
                while literalCount > 0 and matchPos > 1 and string_byte( data, index - 1 ) == string_byte( data, matchPos - 1 ) do
                    literalCount = literalCount - 1
                    index = index - 1
                    matchPos = matchPos - 1
                end

                -- Skip the 4 bytes we already matched
                index = index + MIN_MATCH
                matchPos = matchPos + MIN_MATCH

                -- Determine match length
                -- NOTE: matchLength does not include minMatch; it is added during decoding
                local matchLength = index
                while index <= dataLen - MIN_TRAILING_LITERALS and string_byte( data, index ) == string_byte( data, matchPos ) do
                    index = index + 1
                    matchPos = matchPos + 1
                end

                matchLength = index - matchLength

                -- Write token
                local token = bit_bor(
                    bit_lshift(
                        (literalCount < LIT_COUNT_MASK) and literalCount or LIT_COUNT_MASK,
                        MATCH_LEN_BITS ),
                    (matchLength < MATCH_LEN_MASK) and matchLength or MATCH_LEN_MASK
                )

                out[ outNext ] = string_char( token )
                outNext = outNext + 1

                -- Write literal count
                local remaining = literalCount - LIT_COUNT_MASK
                while remaining >= 0xFF do
                    out[ outNext ] = "\255"
                    outNext = outNext + 1
                    remaining = remaining - 0xFF
                end

                if remaining >= 0 then
                    out[ outNext ] = string_char( remaining )
                    outNext = outNext + 1
                end

                -- Write literals (single string_sub for the whole run, out is only
                -- ever concatenated at the end so no per-byte indexing is needed here)
                if literalCount ~= 0 then
                    out[ outNext ] = string_sub( data, nextUnencodedPos, nextUnencodedPos + (literalCount - 1) )
                    outNext = outNext + 1
                end

                -- Write offset (little-endian)
                out[ outNext ] = string_char( bit_band( matchOffset, 0xFF ) )
                out[ outNext + 1 ] = string_char( bit_rshift( matchOffset, 8 ) )
                outNext = outNext + 2

                -- Write match length
                remaining = matchLength - MATCH_LEN_MASK
                while remaining >= 0xFF do
                    out[ outNext ] = "\255"
                    outNext = outNext + 1
                    remaining = remaining - 0xFF
                end

                if remaining >= 0 then
                    out[ outNext ] = string_char( remaining )
                    outNext = outNext + 1
                end

                -- Move the anchor
                nextUnencodedPos = index

                ::lz4_compress_loop::
            end
        end

        -- Write remaining token (only literals, match length is 0)
        local literalCount = dataLen - nextUnencodedPos + 1
        local token = bit_lshift( (literalCount < LIT_COUNT_MASK) and literalCount or LIT_COUNT_MASK, MATCH_LEN_BITS )
        out[ outNext ] = string_char( token )
        outNext = outNext + 1

        -- Write remaining literal count
        local remaining = literalCount - LIT_COUNT_MASK
        while remaining >= 0xFF do
            out[ outNext ] = "\255"
            outNext = outNext + 1
            remaining = remaining - 0xFF
        end

        if remaining >= 0 then
            out[ outNext ] = string_char( remaining )
            outNext = outNext + 1
        end

        -- Write remaining literals
        out[ outNext ] = string_sub( data, nextUnencodedPos )

        return table_concat( out )
    end

else
    lz4.compress = holylib_CompressLZ4
end

if holylib_DecompressLZ4 == nil then

    --- [SHARED AND MENU]
    ---
    --- Decompresses a string that was compressed using the LZ4 block format. If any
    --- issue is encountered during decompression, this function will throw an
    --- error; call via `pcall()` when processing untrusted input.
    ---
    ---@param data string The string to decompress.
    ---@return string The decompressed string.
    function lz4.decompress( data )
        local out, outNext = {}, 1

        local index = 1 -- 1 - indexed
        local dataLen = #data

        while index <= dataLen do
            local token = string_byte( data, index )
            index = index + 1

            -- Literals --
            local literalCount = bit_rshift( token, MATCH_LEN_BITS )

            -- Read literal count
            if literalCount == LIT_COUNT_MASK then
                repeat
                    local lenPart = string_byte( data, index )
                    index = index + 1
                    literalCount = literalCount + lenPart
                until lenPart < 0xFF
            end

            -- Copy literals (if any)
            for i = 0, literalCount - 1, 1 do
                local j = index + i
                out[ outNext + i ] = string_sub( data, j, j )
            end

            outNext = outNext + literalCount
            index = index + literalCount

            if index > dataLen then
                break -- This was the last sequence (which has no match part)
            end

            -- Match --
            local matchLength = bit_band( token, MATCH_LEN_MASK )

            local offsetA, offsetB = string_byte( data, index, index + 1 )
            local matchOffset = offsetA + bit_lshift( offsetB, 8 )
            index = index + 2

            assert( matchOffset ~= 0, "corrupt LZ4 data: zero match offset" )

            -- Read match length
            if matchLength == MATCH_LEN_MASK then
                repeat
                    local lenPart = string_byte( data, index )
                    matchLength = matchLength + lenPart
                    index = index + 1
                until lenPart < 0xFF
            end

            matchLength = matchLength + MIN_MATCH

            -- Copy match
            for i = 0, matchLength - 1 do
                out[ outNext + i ] = out[ outNext - matchOffset + i ]
            end

            outNext = outNext + matchLength
        end

        return table_concat( out )
    end

else
    lz4.decompress = holylib_DecompressLZ4
end
