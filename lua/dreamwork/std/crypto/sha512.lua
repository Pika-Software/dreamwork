local std = dreamwork.std
local ffi = std.ffi

---@class dreamwork.std.crypto
local crypto = std.crypto

local class = std.class

local rbit = std.raw.bit
local rbit_band, rbit_bor, rbit_bxor = rbit.band, rbit.bor, rbit.bxor
local rbit_lshift, rbit_rshift, rbit_tobit = rbit.lshift, rbit.rshift, rbit.tobit
local rbit_bswap, rbit_rrotate, rbit_tohex = rbit.bswap, rbit.rrotate, rbit.tohex

local string = std.string
local string_len = string.len
local string_rep = string.rep
local string_sub = string.sub
local string_format = string.format
local string_char, string_byte = string.char, string.byte

local table = std.table
local table_concat = table.concat

local math = std.math
local math_floor = math.floor

local type = std.type

--- [SHARED AND MENU]
---
--- SHA512 object.
---
---@class dreamwork.std.crypto.SHA512 : dreamwork.std.Object
---@field __class dreamwork.std.crypto.SHA512Class
---@field protected state integer[] | ffi.cdata* The hash state, 8 words as `hi, lo` pairs ( int32 high and uint32 low halves ) or `uint64_t[8]` if FFI is available.
---@field protected initial_state integer[] The initial hash state as `hi, lo` pairs.
---@field protected message_length integer The total length of the message in bytes.
---@field protected buffer string The unprocessed tail of the message, less than 128 bytes.
local SHA512 = class.base( "SHA512" )

--- [SHARED AND MENU]
---
--- The class used to create new `SHA512` hash calculation instances.
---
--- Secure Hash Algorithm 512-bit, part of the SHA-2 family.
---
--- Like other hash classes, it takes input data ( string )
--- and produces a digest ( string ) — a
--- fixed-size output string that represents that data.
---
---@class dreamwork.std.crypto.SHA512Class : dreamwork.std.crypto.SHA512, dreamwork.std.crypto.HashClass
---@field __base dreamwork.std.crypto.SHA512
---@field digest fun( message: string, as_hex?: boolean ): string
---@field digest_size integer
---@field block_size integer
---@operator call: dreamwork.std.crypto.SHA512
local SHA512Class = class.create( SHA512 )
crypto.SHA512 = SHA512Class

SHA512Class.digest_size = 64
SHA512Class.block_size = 128

--- The high halves of the round constants, 0-based.
---
--- Values above 0x7FFFFFFF are stored as negative int32 values, this way JIT keeps them in integer registers.
local K_hi = {
    [ 0 ] = 0x428a2f98,
    0x71374491,
    -0x4a3f0431,
    -0x164a245b,
    0x3956c25b,
    0x59f111f1,
    -0x6dc07d5c,
    -0x54e3a12b,
    -0x27f85568,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    -0x7f214e02,
    -0x6423f959,
    -0x3e640e8c,
    -0x1b64963f,
    -0x1041b87a,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    -0x67c1aeae,
    -0x57ce3993,
    -0x4ffcd838,
    -0x40a68039,
    -0x391ff40d,
    -0x2a586eb9,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    -0x7e3d36d2,
    -0x6d8dd37b,
    -0x5d40175f,
    -0x57e599b5,
    -0x3db47490,
    -0x3893ae5d,
    -0x2e6d17e7,
    -0x2966f9dc,
    -0x0bf1ca7b,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    -0x7b3787ec,
    -0x7338fdf8,
    -0x6f410006,
    -0x5baf9315,
    -0x41065c09,
    -0x398e870e,
    -0x35d8c132,
    -0x2e794739,
    -0x1525822a,
    -0x0a82b081,
    0x06f067aa,
    0x0a637dc5,
    0x113f9804,
    0x1b710b35,
    0x28db77f5,
    0x32caab7b,
    0x3c9ebe0a,
    0x431d67c4,
    0x4cc5d4be,
    0x597f299c,
    0x5fcb6fab,
    0x6c44198c
}

--- The low halves of the round constants, 0-based.
local K_lo = {
    [ 0 ] = 0xd728ae22,
    0x23ef65cd,
    0xec4d3b2f,
    0x8189dbbc,
    0xf348b538,
    0xb605d019,
    0xaf194f9b,
    0xda6d8118,
    0xa3030242,
    0x45706fbe,
    0x4ee4b28c,
    0xd5ffb4e2,
    0xf27b896f,
    0x3b1696b1,
    0x25c71235,
    0xcf692694,
    0x9ef14ad2,
    0x384f25e3,
    0x8b8cd5b5,
    0x77ac9c65,
    0x592b0275,
    0x6ea6e483,
    0xbd41fbd4,
    0x831153b5,
    0xee66dfab,
    0x2db43210,
    0x98fb213f,
    0xbeef0ee4,
    0x3da88fc2,
    0x930aa725,
    0xe003826f,
    0x0a0e6e70,
    0x46d22ffc,
    0x5c26c926,
    0x5ac42aed,
    0x9d95b3df,
    0x8baf63de,
    0x3c77b2a8,
    0x47edaee6,
    0x1482353b,
    0x4cf10364,
    0xbc423001,
    0xd0f89791,
    0x0654be30,
    0xd6ef5218,
    0x5565a910,
    0x5771202a,
    0x32bbd1b8,
    0xb8d2d0c8,
    0x5141ab53,
    0xdf8eeb99,
    0xe19b48a8,
    0xc5c95a63,
    0xe3418acb,
    0x7763e373,
    0xd6b2b8a3,
    0x5defb2fc,
    0x43172f60,
    0xa1f0ab72,
    0x1a6439ec,
    0x23631e28,
    0xde82bde9,
    0xb2c67915,
    0xe372532b,
    0xea26619c,
    0x21c0c207,
    0xcde0eb1e,
    0xee6ed178,
    0x72176fba,
    0xa2c898a6,
    0xbef90dae,
    0x131c471b,
    0x23047d84,
    0x40c72493,
    0x15c9bebc,
    0x9c100d4c,
    0xcb3e42b6,
    0xfc657e2a,
    0x3ad6faec,
    0x4a475817
}

--- Processes a single 128-byte block, the state is updated in place.
---
---@type fun( str: string, offset: integer, state: integer[] | ffi.cdata* )
local transform

--- Creates a new state from the `hi, lo` pairs.
---
---@type fun( pairs: integer[] ): integer[] | ffi.cdata*
local new_state

--- Copies the state.
---
---@type fun( state: integer[] | ffi.cdata* ): integer[] | ffi.cdata*
local copy_state

--- Serializes the first `word_count` words of the state.
---
---@type fun( state: integer[] | ffi.cdata*, word_count: integer, as_hex?: boolean ): string
local serialize

if ffi == nil then

    -- 64-bit words are stored as pairs of 32-bit halves:
    -- `hi` is a signed int32 ( only used in bit operations and wrapped by `rbit_tobit` ),
    -- `lo` is an unsigned value in [ 0, 2^32 ), so the carry of an addition is `( sum - sum % 2^32 ) / 2^32`

    --- The message schedule of the current block, reused between blocks.
    local W_hi, W_lo = {}, {}

    for t = 0, 79, 1 do
        W_hi[ t ], W_lo[ t ] = 0, 0
    end

    --- Unlike SHA256, the 80 rounds are processed in a loop,
    --- fully unrolled 64-bit pair arithmetic runs JIT out of spill slots.
    ---
    ---@param str string
    ---@param offset integer The 0-based byte offset of the block.
    ---@param state integer[] The hash state, see `SHA512.state`.
    function transform( str, offset, state )
        for t = 0, 15, 1 do
            local uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 = string_byte( str, offset + 1, offset + 8 )
            W_hi[ t ] = rbit_bor( rbit_lshift( uint8_1, 24 ), rbit_lshift( uint8_2, 16 ), rbit_lshift( uint8_3, 8 ), uint8_4 )
            W_lo[ t ] = ((uint8_5 * 0x100 + uint8_6) * 0x100 + uint8_7) * 0x100 + uint8_8
            offset = offset + 8
        end

        for t = 16, 79, 1 do
            -- sigma0 = ror( x, 1 ) ^ ror( x, 8 ) ^ shr( x, 7 )
            local x_hi, x_lo = W_hi[ t - 15 ], W_lo[ t - 15 ]

            local s0_hi = rbit_bxor( rbit_bor( rbit_rshift( x_hi, 1 ), rbit_lshift( x_lo, 31 ) ), rbit_bor( rbit_rshift( x_hi, 8 ), rbit_lshift( x_lo, 24 ) ), rbit_rshift( x_hi, 7 ) )
            local s0_lo = rbit_bxor( rbit_bor( rbit_rshift( x_lo, 1 ), rbit_lshift( x_hi, 31 ) ), rbit_bor( rbit_rshift( x_lo, 8 ), rbit_lshift( x_hi, 24 ) ), rbit_bor( rbit_rshift( x_lo, 7 ), rbit_lshift( x_hi, 25 ) ) )

            -- sigma1 = ror( x, 19 ) ^ ror( x, 61 ) ^ shr( x, 6 )
            x_hi, x_lo = W_hi[ t - 2 ], W_lo[ t - 2 ]

            local s1_hi = rbit_bxor( rbit_bor( rbit_rshift( x_hi, 19 ), rbit_lshift( x_lo, 13 ) ), rbit_bor( rbit_rshift( x_lo, 29 ), rbit_lshift( x_hi, 3 ) ), rbit_rshift( x_hi, 6 ) )
            local s1_lo = rbit_bxor( rbit_bor( rbit_rshift( x_lo, 19 ), rbit_lshift( x_hi, 13 ) ), rbit_bor( rbit_rshift( x_hi, 29 ), rbit_lshift( x_lo, 3 ) ), rbit_bor( rbit_rshift( x_lo, 6 ), rbit_lshift( x_hi, 26 ) ) )

            local lo = s1_lo % 0x100000000 + W_lo[ t - 7 ] + s0_lo % 0x100000000 + W_lo[ t - 16 ]
            local w_lo = lo % 0x100000000

            W_lo[ t ] = w_lo
            W_hi[ t ] = rbit_tobit( s1_hi + W_hi[ t - 7 ] + s0_hi + W_hi[ t - 16 ] + (lo - w_lo) / 0x100000000 )
        end

        local a_hi, a_lo, b_hi, b_lo, c_hi, c_lo, d_hi, d_lo = state[ 1 ], state[ 2 ], state[ 3 ], state[ 4 ], state[ 5 ], state[ 6 ], state[ 7 ], state[ 8 ]
        local e_hi, e_lo, f_hi, f_lo, g_hi, g_lo, h_hi, h_lo = state[ 9 ], state[ 10 ], state[ 11 ], state[ 12 ], state[ 13 ], state[ 14 ], state[ 15 ], state[ 16 ]

        for t = 0, 79, 1 do
            -- Sigma1 = ror( e, 14 ) ^ ror( e, 18 ) ^ ror( e, 41 )
            local S1_hi = rbit_bxor( rbit_bor( rbit_rshift( e_hi, 14 ), rbit_lshift( e_lo, 18 ) ), rbit_bor( rbit_rshift( e_hi, 18 ), rbit_lshift( e_lo, 14 ) ), rbit_bor( rbit_rshift( e_lo, 9 ), rbit_lshift( e_hi, 23 ) ) )
            local S1_lo = rbit_bxor( rbit_bor( rbit_rshift( e_lo, 14 ), rbit_lshift( e_hi, 18 ) ), rbit_bor( rbit_rshift( e_lo, 18 ), rbit_lshift( e_hi, 14 ) ), rbit_bor( rbit_rshift( e_hi, 9 ), rbit_lshift( e_lo, 23 ) ) )

            -- Ch = g ^ ( e & ( f ^ g ) )
            local ch_hi = rbit_bxor( g_hi, rbit_band( e_hi, rbit_bxor( f_hi, g_hi ) ) )
            local ch_lo = rbit_bxor( g_lo, rbit_band( e_lo, rbit_bxor( f_lo, g_lo ) ) )

            local lo = h_lo + S1_lo % 0x100000000 + ch_lo % 0x100000000 + K_lo[ t ] + W_lo[ t ]
            local t1_lo = lo % 0x100000000
            local t1_hi = h_hi + S1_hi + ch_hi + K_hi[ t ] + W_hi[ t ] + (lo - t1_lo) / 0x100000000

            -- Sigma0 = ror( a, 28 ) ^ ror( a, 34 ) ^ ror( a, 39 )
            local S0_hi = rbit_bxor( rbit_bor( rbit_rshift( a_hi, 28 ), rbit_lshift( a_lo, 4 ) ), rbit_bor( rbit_rshift( a_lo, 2 ), rbit_lshift( a_hi, 30 ) ), rbit_bor( rbit_rshift( a_lo, 7 ), rbit_lshift( a_hi, 25 ) ) )
            local S0_lo = rbit_bxor( rbit_bor( rbit_rshift( a_lo, 28 ), rbit_lshift( a_hi, 4 ) ), rbit_bor( rbit_rshift( a_hi, 2 ), rbit_lshift( a_lo, 30 ) ), rbit_bor( rbit_rshift( a_hi, 7 ), rbit_lshift( a_lo, 25 ) ) )

            -- Maj = ( a & b ) | ( c & ( a | b ) )
            local maj_hi = rbit_bor( rbit_band( a_hi, b_hi ), rbit_band( c_hi, rbit_bor( a_hi, b_hi ) ) )
            local maj_lo = rbit_bor( rbit_band( a_lo, b_lo ), rbit_band( c_lo, rbit_bor( a_lo, b_lo ) ) )

            h_hi, h_lo, g_hi, g_lo, f_hi, f_lo = g_hi, g_lo, f_hi, f_lo, e_hi, e_lo

            lo = d_lo + t1_lo
            e_lo = lo % 0x100000000
            e_hi = rbit_tobit( d_hi + t1_hi + (lo - e_lo) / 0x100000000 )

            d_hi, d_lo, c_hi, c_lo, b_hi, b_lo = c_hi, c_lo, b_hi, b_lo, a_hi, a_lo

            lo = t1_lo + S0_lo % 0x100000000 + maj_lo % 0x100000000
            a_lo = lo % 0x100000000
            a_hi = rbit_tobit( t1_hi + S0_hi + maj_hi + (lo - a_lo) / 0x100000000 )
        end

        local lo

        lo = state[ 2 ] + a_lo; a_lo = lo % 0x100000000; state[ 1 ], state[ 2 ] = rbit_tobit( state[ 1 ] + a_hi + (lo - a_lo) / 0x100000000 ), a_lo
        lo = state[ 4 ] + b_lo; b_lo = lo % 0x100000000; state[ 3 ], state[ 4 ] = rbit_tobit( state[ 3 ] + b_hi + (lo - b_lo) / 0x100000000 ), b_lo
        lo = state[ 6 ] + c_lo; c_lo = lo % 0x100000000; state[ 5 ], state[ 6 ] = rbit_tobit( state[ 5 ] + c_hi + (lo - c_lo) / 0x100000000 ), c_lo
        lo = state[ 8 ] + d_lo; d_lo = lo % 0x100000000; state[ 7 ], state[ 8 ] = rbit_tobit( state[ 7 ] + d_hi + (lo - d_lo) / 0x100000000 ), d_lo
        lo = state[ 10 ] + e_lo; e_lo = lo % 0x100000000; state[ 9 ], state[ 10 ] = rbit_tobit( state[ 9 ] + e_hi + (lo - e_lo) / 0x100000000 ), e_lo
        lo = state[ 12 ] + f_lo; f_lo = lo % 0x100000000; state[ 11 ], state[ 12 ] = rbit_tobit( state[ 11 ] + f_hi + (lo - f_lo) / 0x100000000 ), f_lo
        lo = state[ 14 ] + g_lo; g_lo = lo % 0x100000000; state[ 13 ], state[ 14 ] = rbit_tobit( state[ 13 ] + g_hi + (lo - g_lo) / 0x100000000 ), g_lo
        lo = state[ 16 ] + h_lo; h_lo = lo % 0x100000000; state[ 15 ], state[ 16 ] = rbit_tobit( state[ 15 ] + h_hi + (lo - h_lo) / 0x100000000 ), h_lo
    end

    function new_state( pairs )
        return {
            pairs[ 1 ], pairs[ 2 ], pairs[ 3 ], pairs[ 4 ], pairs[ 5 ], pairs[ 6 ], pairs[ 7 ], pairs[ 8 ],
            pairs[ 9 ], pairs[ 10 ], pairs[ 11 ], pairs[ 12 ], pairs[ 13 ], pairs[ 14 ], pairs[ 15 ], pairs[ 16 ]
        }
    end

    copy_state = new_state

    function serialize( state, word_count, as_hex )
        local parts = {}

        if as_hex then
            for i = 1, word_count * 2, 2 do
                parts[ #parts + 1 ] = string_format( "%08x%08x", state[ i ] % 0x100000000, state[ i + 1 ] )
            end
        else
            for i = 1, word_count * 2, 1 do
                local value = state[ i ]
                parts[ i ] = string_char( rbit_band( rbit_rshift( value, 24 ), 0xFF ), rbit_band( rbit_rshift( value, 16 ), 0xFF ), rbit_band( rbit_rshift( value, 8 ), 0xFF ), rbit_band( value, 0xFF ) )
            end
        end

        return table_concat( parts )
    end

else

    -- LuaJIT 2.1 bit operations and arithmetic work on `uint64_t` values natively,
    -- under JIT the boxed values are sunk, so it is ~4x faster than the 32-bit pairs

    local ffi_cast, ffi_copy, ffi_string = ffi.cast, ffi.copy, ffi.string

    local uint64_t = ffi.typeof( "uint64_t" )
    local uint8_ptr_t = ffi.typeof( "const uint8_t *" )
    local uint64_ptr_t = ffi.typeof( "const uint64_t *" )
    local uint64_array_t = ffi.typeof( "uint64_t[?]" )

    local is_little_endian = ffi.abi( "le" )

    --- Joins the 32-bit halves into a `uint64_t` value.
    ---
    --- Multiplication instead of `lshift( hi, 32 )`, because some addons ( e.g. glua-patches )
    --- replace the global `bit.lshift` / `bit.rshift` with versions that return `0` for shifts above 31.
    ---
    ---@param hi integer
    ---@param lo integer
    ---@return ffi.cdata*
    local function join( hi, lo )
        return ffi_cast( uint64_t, hi % 0x100000000 ) * 0x100000000 + lo
    end

    --- Converts `hi, lo` pairs to `uint64_t` values.
    ---
    ---@param pairs integer[]
    ---@param array ffi.cdata*
    ---@param first integer The index of the first pair.
    ---@param count integer The number of pairs.
    ---@return ffi.cdata*
    local function from_pairs( pairs, array, first, count )
        for i = 0, count - 1, 1 do
            local index = first + i * 2
            array[ i ] = join( pairs[ index ], pairs[ index + 1 ] )
        end

        return array
    end

    local K = uint64_array_t( 80 )

    for t = 0, 79, 1 do
        K[ t ] = join( K_hi[ t ], K_lo[ t ] )
    end

    local W = uint64_array_t( 80 )

    -- 8 rounds per iteration, so the variables are renamed instead of rotated,
    -- rotating 8 `uint64_t` values in a loop is "NYI: PHI shuffling too complex"
    function transform( str, offset, state )
        local x = ffi_cast( uint64_ptr_t, ffi_cast( uint8_ptr_t, str ) + offset )

        if is_little_endian then
            for t = 0, 15, 1 do
                W[ t ] = rbit_bswap( x[ t ] )
            end
        else
            for t = 0, 15, 1 do
                W[ t ] = x[ t ]
            end
        end

        for t = 16, 79, 1 do
            local w15, w2 = W[ t - 15 ], W[ t - 2 ]
            W[ t ] = W[ t - 16 ] + rbit_bxor( rbit_rrotate( w15, 1 ), rbit_rrotate( w15, 8 ), rbit_rshift( w15, 7 ) ) + W[ t - 7 ] + rbit_bxor( rbit_rrotate( w2, 19 ), rbit_rrotate( w2, 61 ), rbit_rshift( w2, 6 ) )
        end

        local a, b, c, d, e, f, g, h = state[ 0 ], state[ 1 ], state[ 2 ], state[ 3 ], state[ 4 ], state[ 5 ], state[ 6 ], state[ 7 ]

        for t = 0, 79, 8 do
            local t1

            t1 = h + rbit_bxor( rbit_rrotate( e, 14 ), rbit_rrotate( e, 18 ), rbit_rrotate( e, 41 ) ) + rbit_bxor( g, rbit_band( e, rbit_bxor( f, g ) ) ) + K[ t ] + W[ t ]
            d = d + t1
            h = t1 + rbit_bxor( rbit_rrotate( a, 28 ), rbit_rrotate( a, 34 ), rbit_rrotate( a, 39 ) ) + rbit_bor( rbit_band( a, b ), rbit_band( c, rbit_bor( a, b ) ) )

            t1 = g + rbit_bxor( rbit_rrotate( d, 14 ), rbit_rrotate( d, 18 ), rbit_rrotate( d, 41 ) ) + rbit_bxor( f, rbit_band( d, rbit_bxor( e, f ) ) ) + K[ t + 1 ] + W[ t + 1 ]
            c = c + t1
            g = t1 + rbit_bxor( rbit_rrotate( h, 28 ), rbit_rrotate( h, 34 ), rbit_rrotate( h, 39 ) ) + rbit_bor( rbit_band( h, a ), rbit_band( b, rbit_bor( h, a ) ) )

            t1 = f + rbit_bxor( rbit_rrotate( c, 14 ), rbit_rrotate( c, 18 ), rbit_rrotate( c, 41 ) ) + rbit_bxor( e, rbit_band( c, rbit_bxor( d, e ) ) ) + K[ t + 2 ] + W[ t + 2 ]
            b = b + t1
            f = t1 + rbit_bxor( rbit_rrotate( g, 28 ), rbit_rrotate( g, 34 ), rbit_rrotate( g, 39 ) ) + rbit_bor( rbit_band( g, h ), rbit_band( a, rbit_bor( g, h ) ) )

            t1 = e + rbit_bxor( rbit_rrotate( b, 14 ), rbit_rrotate( b, 18 ), rbit_rrotate( b, 41 ) ) + rbit_bxor( d, rbit_band( b, rbit_bxor( c, d ) ) ) + K[ t + 3 ] + W[ t + 3 ]
            a = a + t1
            e = t1 + rbit_bxor( rbit_rrotate( f, 28 ), rbit_rrotate( f, 34 ), rbit_rrotate( f, 39 ) ) + rbit_bor( rbit_band( f, g ), rbit_band( h, rbit_bor( f, g ) ) )

            t1 = d + rbit_bxor( rbit_rrotate( a, 14 ), rbit_rrotate( a, 18 ), rbit_rrotate( a, 41 ) ) + rbit_bxor( c, rbit_band( a, rbit_bxor( b, c ) ) ) + K[ t + 4 ] + W[ t + 4 ]
            h = h + t1
            d = t1 + rbit_bxor( rbit_rrotate( e, 28 ), rbit_rrotate( e, 34 ), rbit_rrotate( e, 39 ) ) + rbit_bor( rbit_band( e, f ), rbit_band( g, rbit_bor( e, f ) ) )

            t1 = c + rbit_bxor( rbit_rrotate( h, 14 ), rbit_rrotate( h, 18 ), rbit_rrotate( h, 41 ) ) + rbit_bxor( b, rbit_band( h, rbit_bxor( a, b ) ) ) + K[ t + 5 ] + W[ t + 5 ]
            g = g + t1
            c = t1 + rbit_bxor( rbit_rrotate( d, 28 ), rbit_rrotate( d, 34 ), rbit_rrotate( d, 39 ) ) + rbit_bor( rbit_band( d, e ), rbit_band( f, rbit_bor( d, e ) ) )

            t1 = b + rbit_bxor( rbit_rrotate( g, 14 ), rbit_rrotate( g, 18 ), rbit_rrotate( g, 41 ) ) + rbit_bxor( a, rbit_band( g, rbit_bxor( h, a ) ) ) + K[ t + 6 ] + W[ t + 6 ]
            f = f + t1
            b = t1 + rbit_bxor( rbit_rrotate( c, 28 ), rbit_rrotate( c, 34 ), rbit_rrotate( c, 39 ) ) + rbit_bor( rbit_band( c, d ), rbit_band( e, rbit_bor( c, d ) ) )

            t1 = a + rbit_bxor( rbit_rrotate( f, 14 ), rbit_rrotate( f, 18 ), rbit_rrotate( f, 41 ) ) + rbit_bxor( h, rbit_band( f, rbit_bxor( g, h ) ) ) + K[ t + 7 ] + W[ t + 7 ]
            e = e + t1
            a = t1 + rbit_bxor( rbit_rrotate( b, 28 ), rbit_rrotate( b, 34 ), rbit_rrotate( b, 39 ) ) + rbit_bor( rbit_band( b, c ), rbit_band( d, rbit_bor( b, c ) ) )
        end

        state[ 0 ], state[ 1 ], state[ 2 ], state[ 3 ] = state[ 0 ] + a, state[ 1 ] + b, state[ 2 ] + c, state[ 3 ] + d
        state[ 4 ], state[ 5 ], state[ 6 ], state[ 7 ] = state[ 4 ] + e, state[ 5 ] + f, state[ 6 ] + g, state[ 7 ] + h
    end

    function new_state( pairs )
        return from_pairs( pairs, uint64_array_t( 8 ), 1, 8 )
    end

    function copy_state( state )
        local copy = uint64_array_t( 8 )
        ffi_copy( copy, state, 64 )
        return copy
    end

    local output = uint64_array_t( 8 )

    function serialize( state, word_count, as_hex )
        if as_hex then
            local parts = {}

            for i = 1, word_count, 1 do
                parts[ i ] = rbit_tohex( state[ i - 1 ], 16 )
            end

            return table_concat( parts )
        end

        if is_little_endian then
            for i = 0, word_count - 1, 1 do
                output[ i ] = rbit_bswap( state[ i ] )
            end
        else
            ffi_copy( output, state, word_count * 8 )
        end

        return ffi_string( output, word_count * 8 )
    end

end

--- Processes all complete 128-byte blocks of the string starting from the given offset.
---
---@param str string
---@param offset integer The 0-based byte offset.
---@param str_length integer
---@param state integer[] | ffi.cdata*
---@return integer offset The offset of the first unprocessed byte.
local function process( str, offset, str_length, state )
    local last_offset = str_length - 128

    while offset <= last_offset do
        transform( str, offset, state )
        offset = offset + 128
    end

    return offset
end

--- Pads the tail of the message, processes the final block(s) and returns the digest.
---
--- The state is modified, pass a copy if it is still needed.
---
---@param tail string The unprocessed tail of the message, less than 128 bytes.
---@param message_length integer The total length of the message in bytes.
---@param state integer[] | ffi.cdata*
---@param word_count integer The number of 64-bit words in the digest, 8 for SHA512 and 6 for SHA384.
---@param as_hex? boolean
---@return string
local function finalize( tail, message_length, state, word_count, as_hex )
    local bit_count_low = (message_length % 0x20000000) * 8
    local bit_count_high = math_floor( message_length / 0x20000000 )

    -- the length is 128-bit, upper 64 bits are always zero
    local block = tail .. "\128" .. string_rep( "\0", (111 - string_len( tail )) % 128 + 8 ) .. string_char(
        rbit_rshift( bit_count_high, 24 ), rbit_band( rbit_rshift( bit_count_high, 16 ), 0xFF ), rbit_band( rbit_rshift( bit_count_high, 8 ), 0xFF ), rbit_band( bit_count_high, 0xFF ),
        rbit_rshift( bit_count_low, 24 ), rbit_band( rbit_rshift( bit_count_low, 16 ), 0xFF ), rbit_band( rbit_rshift( bit_count_low, 8 ), 0xFF ), rbit_band( bit_count_low, 0xFF )
    )

    transform( block, 0, state )

    if string_len( block ) == 256 then
        transform( block, 128, state )
    end

    return serialize( state, word_count, as_hex )
end

SHA512.initial_state = {
    0x6a09e667, 0xf3bcc908, -0x4498517b, 0x84caa73b, 0x3c6ef372, 0xfe94f82b, -0x5ab00ac6, 0x5f1d36f1,
    0x510e527f, 0xade682d1, -0x64fa9774, 0x2b3e6c1f, 0x1f83d9ab, 0xfb41bd6b, 0x5be0cd19, 0x137e2179
}

--- [SHARED AND MENU]
---
--- Resets the SHA512 object to its initial state.
---
--- This instance method resets the SHA512 object to its initial state.
---
--- It returns the SHA512 object for method chaining.
---
---@return dreamwork.std.crypto.SHA512 obj The reset SHA512 object.
function SHA512:reset()
    self.state = new_state( self.initial_state )

    self.message_length = 0
    self.buffer = ""

    return self
end

SHA512.__init = SHA512.reset

---@return string
---@protected
function SHA512:__represent()
    return string_format( "%s: %p [%d]", type( self ), self, self.message_length )
end

--- [SHARED AND MENU]
---
--- Updates the SHA512 object with the given string.
---
--- This instance method updates the SHA512 object with the given string.
---
--- It returns the SHA512 object for method chaining.
---
---@param str string The string to update the SHA512 object with.
---@return dreamwork.std.crypto.SHA512 obj The updated SHA512 object.
function SHA512:update( str )
    local str_length = string_len( str )
    if str_length == 0 then
        return self
    end

    self.message_length = self.message_length + str_length

    local buffer = self.buffer
    local required = 128 - string_len( buffer )

    if str_length < required then
        self.buffer = buffer .. str
        return self
    end

    local state = self.state
    local offset = 0

    -- complete the buffered block without copying the whole string
    if required ~= 128 then
        transform( buffer .. string_sub( str, 1, required ), 0, state )
        offset = required
    end

    offset = process( str, offset, str_length, state )
    self.buffer = string_sub( str, offset + 1 )

    return self
end

--- [SHARED AND MENU]
---
--- Calculates the SHA512 digest based on the current state or input of the object.
---
--- This instance method returns the SHA512 hash of the data associated with the object.
--- Useful when the SHA512 object has been incrementally updated with input data.
---
--- Does not change the state, so the object can be updated further.
---
---@param as_hex? boolean If true, the result will be a hex string.
---@return string str_result The SHA512 string of the message.
---@nodiscard
function SHA512:digest( as_hex )
    return finalize( self.buffer, self.message_length, copy_state( self.state ), self.__class.digest_size * 0.125, as_hex )
end

SHA512.__tostring = SHA512.digest

--- [SHARED AND MENU]
---
--- Computes the SHA512 digest of the given input string.
---
--- This static method takes a string and returns its SHA512 hash as a hexadecimal string.
--- Commonly used for checksums, data integrity validation, and password hashing.
---
---@param message string The message to compute SHA512 for.
---@param as_hex? boolean If true, the result will be a hex string.
---@return string str_result The SHA512 string of the message.
---@nodiscard
function SHA512Class.digest( message, as_hex )
    local message_length = string_len( message )

    local state = new_state( SHA512.initial_state )

    local offset = process( message, 0, message_length, state )
    return finalize( string_sub( message, offset + 1 ), message_length, state, 8, as_hex )
end
