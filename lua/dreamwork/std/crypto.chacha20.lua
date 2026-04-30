-- based on https://github.com/philanc/plc/blob/master/plc/chacha20.lua
local std = dreamwork.std

local bit = std.bit
local bit_bxor = bit.bxor
local bit_band, bit_bor = bit.band, bit.bor
local bit_lshift, bit_rshift = bit.lshift, bit.rshift

local futures_yield = std.futures.yield
local table_concat = std.table.concat
local math_max = math.max

local string = std.string
local string_rep = string.rep
local string_sub = string.sub
local string_len = string.len

---@class dreamwork.std.crypto
local crypto = std.crypto

local pack = std.pack
local pack_readUInt32 = pack.readUInt32
local pack_writeUInt32 = pack.writeUInt32

---@param state integer[]
---@param x integer
---@param y integer
---@param z integer
---@param w integer
local function quarter_round( state, x, y, z, w )
    local a, b, c, d = state[ x ], state[ y ], state[ z ], state[ w ]

    a = bit_band( a + b, 0xffffffff )

    local t = bit_bxor( d, a )
    d = bit_band( bit_bor( bit_lshift( t, 16 ), bit_rshift( t, 16 ) ), 0xffffffff )
    c = bit_band( c + d, 0xffffffff )

    t = bit_bxor( b, c )
    b = bit_band( bit_bor( bit_lshift( t, 12 ), bit_rshift( t, 20 ) ), 0xffffffff )
    a = bit_band( a + b, 0xffffffff )

    t = bit_bxor( d, a )
    d = bit_band( bit_bor( bit_lshift( t, 8 ), bit_rshift( t, 24 ) ), 0xffffffff )
    c = bit_band( c + d, 0xffffffff )

    t = bit_bxor( b, c )
    b = bit_band( bit_bor( bit_lshift( t, 7 ), bit_rshift( t, 25 ) ), 0xffffffff )

    state[ x ], state[ y ], state[ z ], state[ w ] = a, b, c, d
end

--- [SHARED AND MENU]
---
--- Encrypts a plain text using chacha20.
---
--- See https://en.wikipedia.org/wiki/ChaCha20 for the algorithm.
---
---@param plain_text string The plain text to encrypt/decrypt.
---@param key string The key used for encryption/decryption. ( must be 32 bytes )
---@param nonce_str string The nonce used for encryption/decryption. ( must be 12 bytes )
---@param counter integer The initial counter. ( must be int32 )
---@return AsyncIterator<number, string | nil> iterator The progress iterator that returns the progress percentage and string result on completion.
---@see dreamwork.std.crypto.xchacha20
---@async
local function chacha20( plain_text, key, nonce_str, counter )
    local k1, k2, k3, k4 = pack_readUInt32( key, false, 1 ), pack_readUInt32( key, false, 5 ),
        pack_readUInt32( key, false, 9 ), pack_readUInt32( key, false, 13 )

    local k5, k6, k7, k8 = pack_readUInt32( key, false, 17 ), pack_readUInt32( key, false, 21 ),
        pack_readUInt32( key, false, 25 ), pack_readUInt32( key, false, 29 )

    local n1, n2, n3 = pack_readUInt32( nonce_str, false, 1 ), pack_readUInt32( nonce_str, false, 5 ),
        pack_readUInt32( nonce_str, false, 9 )

    local text_length = string_len( plain_text )

    local length_remainder = text_length % 64
    text_length = text_length - length_remainder

    local blocks, block_count = {}, 0

    local progress_multiplier = 1 / text_length

    for pointer = 1, text_length, 64 do
        local state = {
            0x61707865, 0x3320646e, 0x79622d32, 0x6b206574,
            k1, k2, k3, k4,
            k5, k6, k7, k8,
            counter, n1, n2, n3
        }

        for _ = 1, 10, 1 do
            quarter_round( state, 1, 5, 9, 13 )
            quarter_round( state, 2, 6, 10, 14 )
            quarter_round( state, 3, 7, 11, 15 )
            quarter_round( state, 4, 8, 12, 16 )
            quarter_round( state, 1, 6, 11, 16 )
            quarter_round( state, 2, 7, 12, 13 )
            quarter_round( state, 3, 8, 9, 14 )
            quarter_round( state, 4, 5, 10, 15 )
        end

        -- first block
        block_count = block_count + 1
        ---@diagnostic disable-next-line: param-type-mismatch
        blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( plain_text, false, pointer ), bit_band( 0x61707865 + state[ 1 ], 0xffffffff ) ), false )

        block_count = block_count + 1
        ---@diagnostic disable-next-line: param-type-mismatch
        blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( plain_text, false, pointer + 4 ), bit_band( 0x3320646e + state[ 2 ], 0xffffffff ) ), false )

        block_count = block_count + 1
        ---@diagnostic disable-next-line: param-type-mismatch
        blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( plain_text, false, pointer + 8 ), bit_band( 0x79622d32 + state[ 3 ], 0xffffffff ) ), false )

        block_count = block_count + 1
        ---@diagnostic disable-next-line: param-type-mismatch
        blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( plain_text, false, pointer + 12 ), bit_band( 0x6b206574 + state[ 4 ], 0xffffffff ) ), false )

        -- second block
        block_count = block_count + 1
        ---@diagnostic disable-next-line: param-type-mismatch
        blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( plain_text, false, pointer + 16 ), bit_band( k1 + state[ 5 ], 0xffffffff ) ), false )

        block_count = block_count + 1
        ---@diagnostic disable-next-line: param-type-mismatch
        blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( plain_text, false, pointer + 20 ), bit_band( k2 + state[ 6 ], 0xffffffff ) ), false )

        block_count = block_count + 1
        ---@diagnostic disable-next-line: param-type-mismatch
        blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( plain_text, false, pointer + 24 ), bit_band( k3 + state[ 7 ], 0xffffffff ) ), false )

        block_count = block_count + 1
        ---@diagnostic disable-next-line: param-type-mismatch
        blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( plain_text, false, pointer + 28 ), bit_band( k4 + state[ 8 ], 0xffffffff ) ), false )

        -- third block
        block_count = block_count + 1
        ---@diagnostic disable-next-line: param-type-mismatch
        blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( plain_text, false, pointer + 32 ), bit_band( k5 + state[ 9 ], 0xffffffff ) ), false )

        block_count = block_count + 1
        ---@diagnostic disable-next-line: param-type-mismatch
        blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( plain_text, false, pointer + 36 ), bit_band( k6 + state[ 10 ], 0xffffffff ) ), false )

        block_count = block_count + 1
        ---@diagnostic disable-next-line: param-type-mismatch
        blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( plain_text, false, pointer + 40 ), bit_band( k7 + state[ 11 ], 0xffffffff ) ), false )

        block_count = block_count + 1
        ---@diagnostic disable-next-line: param-type-mismatch
        blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( plain_text, false, pointer + 44 ), bit_band( k8 + state[ 12 ], 0xffffffff ) ), false )

        -- fourth block
        block_count = block_count + 1
        ---@diagnostic disable-next-line: param-type-mismatch
        blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( plain_text, false, pointer + 48 ), bit_band( counter + state[ 13 ], 0xffffffff ) ), false )

        block_count = block_count + 1
        ---@diagnostic disable-next-line: param-type-mismatch
        blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( plain_text, false, pointer + 52 ), bit_band( n1 + state[ 14 ], 0xffffffff ) ), false )

        block_count = block_count + 1
        ---@diagnostic disable-next-line: param-type-mismatch
        blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( plain_text, false, pointer + 56 ), bit_band( n2 + state[ 15 ], 0xffffffff ) ), false )

        block_count = block_count + 1
        ---@diagnostic disable-next-line: param-type-mismatch
        blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( plain_text, false, pointer + 60 ), bit_band( n3 + state[ 16 ], 0xffffffff ) ), false )

        counter = counter + 1
        futures_yield( math_max( (pointer * progress_multiplier) - 0.01, 0.01 ), nil )
    end

    if length_remainder == 0 then
        futures_yield( 1, table_concat( blocks, "", 1, block_count ) )
    else
        local state = {
            0x61707865, 0x3320646e, 0x79622d32, 0x6b206574,
            k1, k2, k3, k4,
            k5, k6, k7, k8,
            counter, n1, n2, n3
        }

        for _ = 1, 10, 1 do
            quarter_round( state, 1, 5, 9, 13 )
            quarter_round( state, 2, 6, 10, 14 )
            quarter_round( state, 3, 7, 11, 15 )
            quarter_round( state, 4, 8, 12, 16 )
            quarter_round( state, 1, 6, 11, 16 )
            quarter_round( state, 2, 7, 12, 13 )
            quarter_round( state, 3, 8, 9, 14 )
            quarter_round( state, 4, 5, 10, 15 )
        end

        local zeros_count = math.ceil( length_remainder * 0.25 ) * 4 - length_remainder
        local segment = string_sub( plain_text, text_length + 1, text_length + length_remainder ) .. string_rep( "\0", zeros_count )
        local segment_length = length_remainder + zeros_count

        -- first block
        block_count = block_count + 1
        ---@diagnostic disable-next-line: param-type-mismatch
        blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( segment, false, 1 ), bit_band( 0x61707865 + state[ 1 ], 0xffffffff ) ), false )

        if segment_length >= 8 then
            block_count = block_count + 1
            ---@diagnostic disable-next-line: param-type-mismatch
            blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( segment, false, 5 ), bit_band( 0x3320646e + state[ 2 ], 0xffffffff ) ), false )
        end

        if segment_length >= 12 then
            block_count = block_count + 1
            ---@diagnostic disable-next-line: param-type-mismatch
            blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( segment, false, 9 ), bit_band( 0x79622d32 + state[ 3 ], 0xffffffff ) ), false )
        end

        if segment_length >= 16 then
            block_count = block_count + 1
            ---@diagnostic disable-next-line: param-type-mismatch
            blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( segment, false, 13 ), bit_band( 0x6b206574 + state[ 4 ], 0xffffffff ) ), false )
        end

        -- second block
        if segment_length >= 20 then
            block_count = block_count + 1
            ---@diagnostic disable-next-line: param-type-mismatch
            blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( segment, false, 17 ), bit_band( k1 + state[ 5 ], 0xffffffff ) ), false )
        end

        if segment_length >= 24 then
            block_count = block_count + 1
            ---@diagnostic disable-next-line: param-type-mismatch
            blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( segment, false, 21 ), bit_band( k2 + state[ 6 ], 0xffffffff ) ), false )
        end

        if segment_length >= 28 then
            block_count = block_count + 1
            ---@diagnostic disable-next-line: param-type-mismatch
            blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( segment, false, 25 ), bit_band( k3 + state[ 7 ], 0xffffffff ) ), false )
        end

        if segment_length >= 32 then
            block_count = block_count + 1
            ---@diagnostic disable-next-line: param-type-mismatch
            blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( segment, false, 29 ), bit_band( k4 + state[ 8 ], 0xffffffff ) ), false )
        end

        -- third block
        if segment_length >= 36 then
            block_count = block_count + 1
            ---@diagnostic disable-next-line: param-type-mismatch
            blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( segment, false, 33 ), bit_band( k5 + state[ 9 ], 0xffffffff ) ), false )
        end

        if segment_length >= 40 then
            block_count = block_count + 1
            ---@diagnostic disable-next-line: param-type-mismatch
            blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( segment, false, 37 ), bit_band( k6 + state[ 10 ], 0xffffffff ) ), false )
        end

        if segment_length >= 44 then
            block_count = block_count + 1
            ---@diagnostic disable-next-line: param-type-mismatch
            blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( segment, false, 41 ), bit_band( k7 + state[ 11 ], 0xffffffff ) ), false )
        end

        if segment_length >= 48 then
            block_count = block_count + 1
            ---@diagnostic disable-next-line: param-type-mismatch
            blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( segment, false, 45 ), bit_band( k8 + state[ 12 ], 0xffffffff ) ), false )
        end

        -- fourth block
        if segment_length >= 52 then
            block_count = block_count + 1
            ---@diagnostic disable-next-line: param-type-mismatch
            blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( segment, false, 49 ), bit_band( counter + state[ 13 ], 0xffffffff ) ), false )
        end

        if segment_length >= 56 then
            block_count = block_count + 1
            ---@diagnostic disable-next-line: param-type-mismatch
            blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( segment, false, 53 ), bit_band( n1 + state[ 14 ], 0xffffffff ) ), false )
        end

        if segment_length >= 60 then
            block_count = block_count + 1
            ---@diagnostic disable-next-line: param-type-mismatch
            blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( segment, false, 57 ), bit_band( n2 + state[ 15 ], 0xffffffff ) ), false )
        end

        if segment_length >= 64 then
            block_count = block_count + 1
            ---@diagnostic disable-next-line: param-type-mismatch
            blocks[ block_count ] = pack_writeUInt32( bit_bxor( pack_readUInt32( segment, false, 61 ), bit_band( n3 + state[ 16 ], 0xffffffff ) ), false )
        end

        futures_yield( 1, string_sub( table_concat( blocks, "", 1, block_count ), 1, text_length + length_remainder ) )
    end

end

crypto.chacha20 = chacha20

--- [SHARED AND MENU]
---
--- Encrypts a plain text using xchacha20.
---
--- See https://en.wikipedia.org/wiki/ChaCha20 for the algorithm.
---
---@param plain_text string The text to encrypt.
---@param key string The key used for encryption. ( must be 32 bytes )
---@param nonce string The nonce used for encryption. ( must be 24 bytes )
---@param counter integer The initial counter. ( must be int32 )
---@return AsyncIterator<number, string | nil> iterator The progress iterator that returns the progress percentage and string result on completion.
---@see dreamwork.std.crypto.chacha20
---@async
function crypto.xchacha20( plain_text, key, nonce, counter )
    local state = {
        0x61707865, 0x3320646e, 0x79622d32, 0x6b206574,

        pack_readUInt32( key, false, 1 ),
        pack_readUInt32( key, false, 5 ),
        pack_readUInt32( key, false, 9 ),
        pack_readUInt32( key, false, 13 ),

        pack_readUInt32( key, false, 17 ),
        pack_readUInt32( key, false, 21 ),
        pack_readUInt32( key, false, 25 ),
        pack_readUInt32( key, false, 29 ),

        pack_readUInt32( nonce, false, 1 ),
        pack_readUInt32( nonce, false, 5 ),
        pack_readUInt32( nonce, false, 9 ),
        pack_readUInt32( nonce, false, 13 )
    }

    for _ = 1, 10, 1 do
        quarter_round( state, 1, 5, 9, 13 )
        quarter_round( state, 2, 6, 10, 14 )
        quarter_round( state, 3, 7, 11, 15 )
        quarter_round( state, 4, 8, 12, 16 )
        quarter_round( state, 1, 6, 11, 16 )
        quarter_round( state, 2, 7, 12, 13 )
        quarter_round( state, 3, 8, 9, 14 )
        quarter_round( state, 4, 5, 10, 15 )
    end

    chacha20(
        plain_text,
        table_concat( {
            pack_writeUInt32( state[ 1 ], false ),
            pack_writeUInt32( state[ 2 ], false ),
            pack_writeUInt32( state[ 3 ], false ),
            pack_writeUInt32( state[ 4 ], false ),

            pack_writeUInt32( state[ 13 ], false ),
            pack_writeUInt32( state[ 14 ], false ),
            pack_writeUInt32( state[ 15 ], false ),
            pack_writeUInt32( state[ 16 ], false )
        }, "", 1, 8 ),
        "\0\0\0\0" .. string_sub( nonce, 17, 24 ),
        counter
    )
end
