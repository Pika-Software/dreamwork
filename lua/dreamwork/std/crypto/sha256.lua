local std = dreamwork.std
local ffi = std.ffi

---@class dreamwork.std.crypto
local crypto = std.crypto

local class = std.class

local rbit = std.raw.bit
local rbit_bswap = rbit.bswap
local rbit_rrotate = rbit.rrotate
local rbit_band, rbit_bor, rbit_bxor = rbit.band, rbit.bor, rbit.bxor
local rbit_lshift, rbit_rshift, rbit_tobit = rbit.lshift, rbit.rshift, rbit.tobit

local string = std.string
local string_len = string.len
local string_rep = string.rep
local string_sub = string.sub
local string_format = string.format
local string_char, string_byte = string.char, string.byte

local math = std.math
local math_floor = math.floor

local type = std.type


--- [SHARED AND MENU]
---
--- SHA256 object.
---
---@class dreamwork.std.crypto.SHA256 : dreamwork.std.Object
---@field __class dreamwork.std.crypto.SHA256Class
---@field protected h1 integer The first word of the hash state ( int32 ).
---@field protected h2 integer The second word of the hash state ( int32 ).
---@field protected h3 integer The third word of the hash state ( int32 ).
---@field protected h4 integer The fourth word of the hash state ( int32 ).
---@field protected h5 integer The fifth word of the hash state ( int32 ).
---@field protected h6 integer The sixth word of the hash state ( int32 ).
---@field protected h7 integer The seventh word of the hash state ( int32 ).
---@field protected h8 integer The eighth word of the hash state ( int32 ).
---@field protected message_length integer The total length of the message in bytes.
---@field protected buffer string The unprocessed tail of the message, less than 64 bytes.
local SHA256 = class.base( "SHA256" )

--- [SHARED AND MENU]
---
--- The class used to create new `SHA256` hash calculation instances.
---
--- Secure Hash Algorithm 256-bit, part of the SHA-2 family.
---
--- This hash algorithm is recommended because it is fast and secure.
---
--- Like other hash classes, it takes input data ( string )
--- and produces a digest ( string ) — a
--- fixed-size output string that represents that data.
---
---@class dreamwork.std.crypto.SHA256Class : dreamwork.std.crypto.SHA256, dreamwork.std.crypto.HashClass
---@field __base dreamwork.std.crypto.SHA256
---@field digest fun( message: string, as_hex?: boolean ): string
---@field digest_size integer
---@field block_size integer
---@operator call: dreamwork.std.crypto.SHA256
local SHA256Class = class.create( SHA256 )
crypto.SHA256 = SHA256Class

SHA256Class.digest_size = 32
SHA256Class.block_size = 64

--- Applies the 64 SHA256 operations to the state using the given 16 words.
---
---@return integer h1
---@return integer h2
---@return integer h3
---@return integer h4
---@return integer h5
---@return integer h6
---@return integer h7
---@return integer h8
local function compress( h1, h2, h3, h4, h5, h6, h7, h8, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15 )
    local a, b, c, d, e, f, g, h = h1, h2, h3, h4, h5, h6, h7, h8
    local t1

    -- constants above 0x7FFFFFFF are written as negative int32 values, this way every operand fits into int32
    -- and JIT narrows all additions that feed bit operations into plain wrapping int32 adds ( ~3x faster than doubles )
    -- the message schedule is kept in a rolling window of 16 words, `x[t % 16]` is replaced in place
    -- `rbit_tobit` on the new `a` / `e` keeps values exact in the interpreter, under JIT it is free

    t1 = h + rbit_bxor( rbit_rrotate( e, 6 ), rbit_rrotate( e, 11 ), rbit_rrotate( e, 25 ) ) + rbit_bxor( g, rbit_band( e, rbit_bxor( f, g ) ) ) + x0 + 0x428a2f98
    d = rbit_tobit( d + t1 )
    h = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( a, 2 ), rbit_rrotate( a, 13 ), rbit_rrotate( a, 22 ) ) + rbit_bor( rbit_band( a, b ), rbit_band( c, rbit_bor( a, b ) ) ) )

    t1 = g + rbit_bxor( rbit_rrotate( d, 6 ), rbit_rrotate( d, 11 ), rbit_rrotate( d, 25 ) ) + rbit_bxor( f, rbit_band( d, rbit_bxor( e, f ) ) ) + x1 + 0x71374491
    c = rbit_tobit( c + t1 )
    g = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( h, 2 ), rbit_rrotate( h, 13 ), rbit_rrotate( h, 22 ) ) + rbit_bor( rbit_band( h, a ), rbit_band( b, rbit_bor( h, a ) ) ) )

    t1 = f + rbit_bxor( rbit_rrotate( c, 6 ), rbit_rrotate( c, 11 ), rbit_rrotate( c, 25 ) ) + rbit_bxor( e, rbit_band( c, rbit_bxor( d, e ) ) ) + x2 - 0x4a3f0431
    b = rbit_tobit( b + t1 )
    f = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( g, 2 ), rbit_rrotate( g, 13 ), rbit_rrotate( g, 22 ) ) + rbit_bor( rbit_band( g, h ), rbit_band( a, rbit_bor( g, h ) ) ) )

    t1 = e + rbit_bxor( rbit_rrotate( b, 6 ), rbit_rrotate( b, 11 ), rbit_rrotate( b, 25 ) ) + rbit_bxor( d, rbit_band( b, rbit_bxor( c, d ) ) ) + x3 - 0x164a245b
    a = rbit_tobit( a + t1 )
    e = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( f, 2 ), rbit_rrotate( f, 13 ), rbit_rrotate( f, 22 ) ) + rbit_bor( rbit_band( f, g ), rbit_band( h, rbit_bor( f, g ) ) ) )

    t1 = d + rbit_bxor( rbit_rrotate( a, 6 ), rbit_rrotate( a, 11 ), rbit_rrotate( a, 25 ) ) + rbit_bxor( c, rbit_band( a, rbit_bxor( b, c ) ) ) + x4 + 0x3956c25b
    h = rbit_tobit( h + t1 )
    d = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( e, 2 ), rbit_rrotate( e, 13 ), rbit_rrotate( e, 22 ) ) + rbit_bor( rbit_band( e, f ), rbit_band( g, rbit_bor( e, f ) ) ) )

    t1 = c + rbit_bxor( rbit_rrotate( h, 6 ), rbit_rrotate( h, 11 ), rbit_rrotate( h, 25 ) ) + rbit_bxor( b, rbit_band( h, rbit_bxor( a, b ) ) ) + x5 + 0x59f111f1
    g = rbit_tobit( g + t1 )
    c = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( d, 2 ), rbit_rrotate( d, 13 ), rbit_rrotate( d, 22 ) ) + rbit_bor( rbit_band( d, e ), rbit_band( f, rbit_bor( d, e ) ) ) )

    t1 = b + rbit_bxor( rbit_rrotate( g, 6 ), rbit_rrotate( g, 11 ), rbit_rrotate( g, 25 ) ) + rbit_bxor( a, rbit_band( g, rbit_bxor( h, a ) ) ) + x6 - 0x6dc07d5c
    f = rbit_tobit( f + t1 )
    b = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( c, 2 ), rbit_rrotate( c, 13 ), rbit_rrotate( c, 22 ) ) + rbit_bor( rbit_band( c, d ), rbit_band( e, rbit_bor( c, d ) ) ) )

    t1 = a + rbit_bxor( rbit_rrotate( f, 6 ), rbit_rrotate( f, 11 ), rbit_rrotate( f, 25 ) ) + rbit_bxor( h, rbit_band( f, rbit_bxor( g, h ) ) ) + x7 - 0x54e3a12b
    e = rbit_tobit( e + t1 )
    a = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( b, 2 ), rbit_rrotate( b, 13 ), rbit_rrotate( b, 22 ) ) + rbit_bor( rbit_band( b, c ), rbit_band( d, rbit_bor( b, c ) ) ) )

    t1 = h + rbit_bxor( rbit_rrotate( e, 6 ), rbit_rrotate( e, 11 ), rbit_rrotate( e, 25 ) ) + rbit_bxor( g, rbit_band( e, rbit_bxor( f, g ) ) ) + x8 - 0x27f85568
    d = rbit_tobit( d + t1 )
    h = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( a, 2 ), rbit_rrotate( a, 13 ), rbit_rrotate( a, 22 ) ) + rbit_bor( rbit_band( a, b ), rbit_band( c, rbit_bor( a, b ) ) ) )

    t1 = g + rbit_bxor( rbit_rrotate( d, 6 ), rbit_rrotate( d, 11 ), rbit_rrotate( d, 25 ) ) + rbit_bxor( f, rbit_band( d, rbit_bxor( e, f ) ) ) + x9 + 0x12835b01
    c = rbit_tobit( c + t1 )
    g = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( h, 2 ), rbit_rrotate( h, 13 ), rbit_rrotate( h, 22 ) ) + rbit_bor( rbit_band( h, a ), rbit_band( b, rbit_bor( h, a ) ) ) )

    t1 = f + rbit_bxor( rbit_rrotate( c, 6 ), rbit_rrotate( c, 11 ), rbit_rrotate( c, 25 ) ) + rbit_bxor( e, rbit_band( c, rbit_bxor( d, e ) ) ) + x10 + 0x243185be
    b = rbit_tobit( b + t1 )
    f = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( g, 2 ), rbit_rrotate( g, 13 ), rbit_rrotate( g, 22 ) ) + rbit_bor( rbit_band( g, h ), rbit_band( a, rbit_bor( g, h ) ) ) )

    t1 = e + rbit_bxor( rbit_rrotate( b, 6 ), rbit_rrotate( b, 11 ), rbit_rrotate( b, 25 ) ) + rbit_bxor( d, rbit_band( b, rbit_bxor( c, d ) ) ) + x11 + 0x550c7dc3
    a = rbit_tobit( a + t1 )
    e = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( f, 2 ), rbit_rrotate( f, 13 ), rbit_rrotate( f, 22 ) ) + rbit_bor( rbit_band( f, g ), rbit_band( h, rbit_bor( f, g ) ) ) )

    t1 = d + rbit_bxor( rbit_rrotate( a, 6 ), rbit_rrotate( a, 11 ), rbit_rrotate( a, 25 ) ) + rbit_bxor( c, rbit_band( a, rbit_bxor( b, c ) ) ) + x12 + 0x72be5d74
    h = rbit_tobit( h + t1 )
    d = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( e, 2 ), rbit_rrotate( e, 13 ), rbit_rrotate( e, 22 ) ) + rbit_bor( rbit_band( e, f ), rbit_band( g, rbit_bor( e, f ) ) ) )

    t1 = c + rbit_bxor( rbit_rrotate( h, 6 ), rbit_rrotate( h, 11 ), rbit_rrotate( h, 25 ) ) + rbit_bxor( b, rbit_band( h, rbit_bxor( a, b ) ) ) + x13 - 0x7f214e02
    g = rbit_tobit( g + t1 )
    c = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( d, 2 ), rbit_rrotate( d, 13 ), rbit_rrotate( d, 22 ) ) + rbit_bor( rbit_band( d, e ), rbit_band( f, rbit_bor( d, e ) ) ) )

    t1 = b + rbit_bxor( rbit_rrotate( g, 6 ), rbit_rrotate( g, 11 ), rbit_rrotate( g, 25 ) ) + rbit_bxor( a, rbit_band( g, rbit_bxor( h, a ) ) ) + x14 - 0x6423f959
    f = rbit_tobit( f + t1 )
    b = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( c, 2 ), rbit_rrotate( c, 13 ), rbit_rrotate( c, 22 ) ) + rbit_bor( rbit_band( c, d ), rbit_band( e, rbit_bor( c, d ) ) ) )

    t1 = a + rbit_bxor( rbit_rrotate( f, 6 ), rbit_rrotate( f, 11 ), rbit_rrotate( f, 25 ) ) + rbit_bxor( h, rbit_band( f, rbit_bxor( g, h ) ) ) + x15 - 0x3e640e8c
    e = rbit_tobit( e + t1 )
    a = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( b, 2 ), rbit_rrotate( b, 13 ), rbit_rrotate( b, 22 ) ) + rbit_bor( rbit_band( b, c ), rbit_band( d, rbit_bor( b, c ) ) ) )

    x0 = rbit_tobit( x0 + rbit_bxor( rbit_rrotate( x14, 17 ), rbit_rrotate( x14, 19 ), rbit_rshift( x14, 10 ) ) + x9 + rbit_bxor( rbit_rrotate( x1, 7 ), rbit_rrotate( x1, 18 ), rbit_rshift( x1, 3 ) ) )
    t1 = h + rbit_bxor( rbit_rrotate( e, 6 ), rbit_rrotate( e, 11 ), rbit_rrotate( e, 25 ) ) + rbit_bxor( g, rbit_band( e, rbit_bxor( f, g ) ) ) + x0 - 0x1b64963f
    d = rbit_tobit( d + t1 )
    h = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( a, 2 ), rbit_rrotate( a, 13 ), rbit_rrotate( a, 22 ) ) + rbit_bor( rbit_band( a, b ), rbit_band( c, rbit_bor( a, b ) ) ) )

    x1 = rbit_tobit( x1 + rbit_bxor( rbit_rrotate( x15, 17 ), rbit_rrotate( x15, 19 ), rbit_rshift( x15, 10 ) ) + x10 + rbit_bxor( rbit_rrotate( x2, 7 ), rbit_rrotate( x2, 18 ), rbit_rshift( x2, 3 ) ) )
    t1 = g + rbit_bxor( rbit_rrotate( d, 6 ), rbit_rrotate( d, 11 ), rbit_rrotate( d, 25 ) ) + rbit_bxor( f, rbit_band( d, rbit_bxor( e, f ) ) ) + x1 - 0x1041b87a
    c = rbit_tobit( c + t1 )
    g = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( h, 2 ), rbit_rrotate( h, 13 ), rbit_rrotate( h, 22 ) ) + rbit_bor( rbit_band( h, a ), rbit_band( b, rbit_bor( h, a ) ) ) )

    x2 = rbit_tobit( x2 + rbit_bxor( rbit_rrotate( x0, 17 ), rbit_rrotate( x0, 19 ), rbit_rshift( x0, 10 ) ) + x11 + rbit_bxor( rbit_rrotate( x3, 7 ), rbit_rrotate( x3, 18 ), rbit_rshift( x3, 3 ) ) )
    t1 = f + rbit_bxor( rbit_rrotate( c, 6 ), rbit_rrotate( c, 11 ), rbit_rrotate( c, 25 ) ) + rbit_bxor( e, rbit_band( c, rbit_bxor( d, e ) ) ) + x2 + 0x0fc19dc6
    b = rbit_tobit( b + t1 )
    f = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( g, 2 ), rbit_rrotate( g, 13 ), rbit_rrotate( g, 22 ) ) + rbit_bor( rbit_band( g, h ), rbit_band( a, rbit_bor( g, h ) ) ) )

    x3 = rbit_tobit( x3 + rbit_bxor( rbit_rrotate( x1, 17 ), rbit_rrotate( x1, 19 ), rbit_rshift( x1, 10 ) ) + x12 + rbit_bxor( rbit_rrotate( x4, 7 ), rbit_rrotate( x4, 18 ), rbit_rshift( x4, 3 ) ) )
    t1 = e + rbit_bxor( rbit_rrotate( b, 6 ), rbit_rrotate( b, 11 ), rbit_rrotate( b, 25 ) ) + rbit_bxor( d, rbit_band( b, rbit_bxor( c, d ) ) ) + x3 + 0x240ca1cc
    a = rbit_tobit( a + t1 )
    e = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( f, 2 ), rbit_rrotate( f, 13 ), rbit_rrotate( f, 22 ) ) + rbit_bor( rbit_band( f, g ), rbit_band( h, rbit_bor( f, g ) ) ) )

    x4 = rbit_tobit( x4 + rbit_bxor( rbit_rrotate( x2, 17 ), rbit_rrotate( x2, 19 ), rbit_rshift( x2, 10 ) ) + x13 + rbit_bxor( rbit_rrotate( x5, 7 ), rbit_rrotate( x5, 18 ), rbit_rshift( x5, 3 ) ) )
    t1 = d + rbit_bxor( rbit_rrotate( a, 6 ), rbit_rrotate( a, 11 ), rbit_rrotate( a, 25 ) ) + rbit_bxor( c, rbit_band( a, rbit_bxor( b, c ) ) ) + x4 + 0x2de92c6f
    h = rbit_tobit( h + t1 )
    d = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( e, 2 ), rbit_rrotate( e, 13 ), rbit_rrotate( e, 22 ) ) + rbit_bor( rbit_band( e, f ), rbit_band( g, rbit_bor( e, f ) ) ) )

    x5 = rbit_tobit( x5 + rbit_bxor( rbit_rrotate( x3, 17 ), rbit_rrotate( x3, 19 ), rbit_rshift( x3, 10 ) ) + x14 + rbit_bxor( rbit_rrotate( x6, 7 ), rbit_rrotate( x6, 18 ), rbit_rshift( x6, 3 ) ) )
    t1 = c + rbit_bxor( rbit_rrotate( h, 6 ), rbit_rrotate( h, 11 ), rbit_rrotate( h, 25 ) ) + rbit_bxor( b, rbit_band( h, rbit_bxor( a, b ) ) ) + x5 + 0x4a7484aa
    g = rbit_tobit( g + t1 )
    c = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( d, 2 ), rbit_rrotate( d, 13 ), rbit_rrotate( d, 22 ) ) + rbit_bor( rbit_band( d, e ), rbit_band( f, rbit_bor( d, e ) ) ) )

    x6 = rbit_tobit( x6 + rbit_bxor( rbit_rrotate( x4, 17 ), rbit_rrotate( x4, 19 ), rbit_rshift( x4, 10 ) ) + x15 + rbit_bxor( rbit_rrotate( x7, 7 ), rbit_rrotate( x7, 18 ), rbit_rshift( x7, 3 ) ) )
    t1 = b + rbit_bxor( rbit_rrotate( g, 6 ), rbit_rrotate( g, 11 ), rbit_rrotate( g, 25 ) ) + rbit_bxor( a, rbit_band( g, rbit_bxor( h, a ) ) ) + x6 + 0x5cb0a9dc
    f = rbit_tobit( f + t1 )
    b = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( c, 2 ), rbit_rrotate( c, 13 ), rbit_rrotate( c, 22 ) ) + rbit_bor( rbit_band( c, d ), rbit_band( e, rbit_bor( c, d ) ) ) )

    x7 = rbit_tobit( x7 + rbit_bxor( rbit_rrotate( x5, 17 ), rbit_rrotate( x5, 19 ), rbit_rshift( x5, 10 ) ) + x0 + rbit_bxor( rbit_rrotate( x8, 7 ), rbit_rrotate( x8, 18 ), rbit_rshift( x8, 3 ) ) )
    t1 = a + rbit_bxor( rbit_rrotate( f, 6 ), rbit_rrotate( f, 11 ), rbit_rrotate( f, 25 ) ) + rbit_bxor( h, rbit_band( f, rbit_bxor( g, h ) ) ) + x7 + 0x76f988da
    e = rbit_tobit( e + t1 )
    a = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( b, 2 ), rbit_rrotate( b, 13 ), rbit_rrotate( b, 22 ) ) + rbit_bor( rbit_band( b, c ), rbit_band( d, rbit_bor( b, c ) ) ) )

    x8 = rbit_tobit( x8 + rbit_bxor( rbit_rrotate( x6, 17 ), rbit_rrotate( x6, 19 ), rbit_rshift( x6, 10 ) ) + x1 + rbit_bxor( rbit_rrotate( x9, 7 ), rbit_rrotate( x9, 18 ), rbit_rshift( x9, 3 ) ) )
    t1 = h + rbit_bxor( rbit_rrotate( e, 6 ), rbit_rrotate( e, 11 ), rbit_rrotate( e, 25 ) ) + rbit_bxor( g, rbit_band( e, rbit_bxor( f, g ) ) ) + x8 - 0x67c1aeae
    d = rbit_tobit( d + t1 )
    h = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( a, 2 ), rbit_rrotate( a, 13 ), rbit_rrotate( a, 22 ) ) + rbit_bor( rbit_band( a, b ), rbit_band( c, rbit_bor( a, b ) ) ) )

    x9 = rbit_tobit( x9 + rbit_bxor( rbit_rrotate( x7, 17 ), rbit_rrotate( x7, 19 ), rbit_rshift( x7, 10 ) ) + x2 + rbit_bxor( rbit_rrotate( x10, 7 ), rbit_rrotate( x10, 18 ), rbit_rshift( x10, 3 ) ) )
    t1 = g + rbit_bxor( rbit_rrotate( d, 6 ), rbit_rrotate( d, 11 ), rbit_rrotate( d, 25 ) ) + rbit_bxor( f, rbit_band( d, rbit_bxor( e, f ) ) ) + x9 - 0x57ce3993
    c = rbit_tobit( c + t1 )
    g = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( h, 2 ), rbit_rrotate( h, 13 ), rbit_rrotate( h, 22 ) ) + rbit_bor( rbit_band( h, a ), rbit_band( b, rbit_bor( h, a ) ) ) )

    x10 = rbit_tobit( x10 + rbit_bxor( rbit_rrotate( x8, 17 ), rbit_rrotate( x8, 19 ), rbit_rshift( x8, 10 ) ) + x3 + rbit_bxor( rbit_rrotate( x11, 7 ), rbit_rrotate( x11, 18 ), rbit_rshift( x11, 3 ) ) )
    t1 = f + rbit_bxor( rbit_rrotate( c, 6 ), rbit_rrotate( c, 11 ), rbit_rrotate( c, 25 ) ) + rbit_bxor( e, rbit_band( c, rbit_bxor( d, e ) ) ) + x10 - 0x4ffcd838
    b = rbit_tobit( b + t1 )
    f = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( g, 2 ), rbit_rrotate( g, 13 ), rbit_rrotate( g, 22 ) ) + rbit_bor( rbit_band( g, h ), rbit_band( a, rbit_bor( g, h ) ) ) )

    x11 = rbit_tobit( x11 + rbit_bxor( rbit_rrotate( x9, 17 ), rbit_rrotate( x9, 19 ), rbit_rshift( x9, 10 ) ) + x4 + rbit_bxor( rbit_rrotate( x12, 7 ), rbit_rrotate( x12, 18 ), rbit_rshift( x12, 3 ) ) )
    t1 = e + rbit_bxor( rbit_rrotate( b, 6 ), rbit_rrotate( b, 11 ), rbit_rrotate( b, 25 ) ) + rbit_bxor( d, rbit_band( b, rbit_bxor( c, d ) ) ) + x11 - 0x40a68039
    a = rbit_tobit( a + t1 )
    e = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( f, 2 ), rbit_rrotate( f, 13 ), rbit_rrotate( f, 22 ) ) + rbit_bor( rbit_band( f, g ), rbit_band( h, rbit_bor( f, g ) ) ) )

    x12 = rbit_tobit( x12 + rbit_bxor( rbit_rrotate( x10, 17 ), rbit_rrotate( x10, 19 ), rbit_rshift( x10, 10 ) ) + x5 + rbit_bxor( rbit_rrotate( x13, 7 ), rbit_rrotate( x13, 18 ), rbit_rshift( x13, 3 ) ) )
    t1 = d + rbit_bxor( rbit_rrotate( a, 6 ), rbit_rrotate( a, 11 ), rbit_rrotate( a, 25 ) ) + rbit_bxor( c, rbit_band( a, rbit_bxor( b, c ) ) ) + x12 - 0x391ff40d
    h = rbit_tobit( h + t1 )
    d = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( e, 2 ), rbit_rrotate( e, 13 ), rbit_rrotate( e, 22 ) ) + rbit_bor( rbit_band( e, f ), rbit_band( g, rbit_bor( e, f ) ) ) )

    x13 = rbit_tobit( x13 + rbit_bxor( rbit_rrotate( x11, 17 ), rbit_rrotate( x11, 19 ), rbit_rshift( x11, 10 ) ) + x6 + rbit_bxor( rbit_rrotate( x14, 7 ), rbit_rrotate( x14, 18 ), rbit_rshift( x14, 3 ) ) )
    t1 = c + rbit_bxor( rbit_rrotate( h, 6 ), rbit_rrotate( h, 11 ), rbit_rrotate( h, 25 ) ) + rbit_bxor( b, rbit_band( h, rbit_bxor( a, b ) ) ) + x13 - 0x2a586eb9
    g = rbit_tobit( g + t1 )
    c = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( d, 2 ), rbit_rrotate( d, 13 ), rbit_rrotate( d, 22 ) ) + rbit_bor( rbit_band( d, e ), rbit_band( f, rbit_bor( d, e ) ) ) )

    x14 = rbit_tobit( x14 + rbit_bxor( rbit_rrotate( x12, 17 ), rbit_rrotate( x12, 19 ), rbit_rshift( x12, 10 ) ) + x7 + rbit_bxor( rbit_rrotate( x15, 7 ), rbit_rrotate( x15, 18 ), rbit_rshift( x15, 3 ) ) )
    t1 = b + rbit_bxor( rbit_rrotate( g, 6 ), rbit_rrotate( g, 11 ), rbit_rrotate( g, 25 ) ) + rbit_bxor( a, rbit_band( g, rbit_bxor( h, a ) ) ) + x14 + 0x06ca6351
    f = rbit_tobit( f + t1 )
    b = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( c, 2 ), rbit_rrotate( c, 13 ), rbit_rrotate( c, 22 ) ) + rbit_bor( rbit_band( c, d ), rbit_band( e, rbit_bor( c, d ) ) ) )

    x15 = rbit_tobit( x15 + rbit_bxor( rbit_rrotate( x13, 17 ), rbit_rrotate( x13, 19 ), rbit_rshift( x13, 10 ) ) + x8 + rbit_bxor( rbit_rrotate( x0, 7 ), rbit_rrotate( x0, 18 ), rbit_rshift( x0, 3 ) ) )
    t1 = a + rbit_bxor( rbit_rrotate( f, 6 ), rbit_rrotate( f, 11 ), rbit_rrotate( f, 25 ) ) + rbit_bxor( h, rbit_band( f, rbit_bxor( g, h ) ) ) + x15 + 0x14292967
    e = rbit_tobit( e + t1 )
    a = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( b, 2 ), rbit_rrotate( b, 13 ), rbit_rrotate( b, 22 ) ) + rbit_bor( rbit_band( b, c ), rbit_band( d, rbit_bor( b, c ) ) ) )

    x0 = rbit_tobit( x0 + rbit_bxor( rbit_rrotate( x14, 17 ), rbit_rrotate( x14, 19 ), rbit_rshift( x14, 10 ) ) + x9 + rbit_bxor( rbit_rrotate( x1, 7 ), rbit_rrotate( x1, 18 ), rbit_rshift( x1, 3 ) ) )
    t1 = h + rbit_bxor( rbit_rrotate( e, 6 ), rbit_rrotate( e, 11 ), rbit_rrotate( e, 25 ) ) + rbit_bxor( g, rbit_band( e, rbit_bxor( f, g ) ) ) + x0 + 0x27b70a85
    d = rbit_tobit( d + t1 )
    h = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( a, 2 ), rbit_rrotate( a, 13 ), rbit_rrotate( a, 22 ) ) + rbit_bor( rbit_band( a, b ), rbit_band( c, rbit_bor( a, b ) ) ) )

    x1 = rbit_tobit( x1 + rbit_bxor( rbit_rrotate( x15, 17 ), rbit_rrotate( x15, 19 ), rbit_rshift( x15, 10 ) ) + x10 + rbit_bxor( rbit_rrotate( x2, 7 ), rbit_rrotate( x2, 18 ), rbit_rshift( x2, 3 ) ) )
    t1 = g + rbit_bxor( rbit_rrotate( d, 6 ), rbit_rrotate( d, 11 ), rbit_rrotate( d, 25 ) ) + rbit_bxor( f, rbit_band( d, rbit_bxor( e, f ) ) ) + x1 + 0x2e1b2138
    c = rbit_tobit( c + t1 )
    g = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( h, 2 ), rbit_rrotate( h, 13 ), rbit_rrotate( h, 22 ) ) + rbit_bor( rbit_band( h, a ), rbit_band( b, rbit_bor( h, a ) ) ) )

    x2 = rbit_tobit( x2 + rbit_bxor( rbit_rrotate( x0, 17 ), rbit_rrotate( x0, 19 ), rbit_rshift( x0, 10 ) ) + x11 + rbit_bxor( rbit_rrotate( x3, 7 ), rbit_rrotate( x3, 18 ), rbit_rshift( x3, 3 ) ) )
    t1 = f + rbit_bxor( rbit_rrotate( c, 6 ), rbit_rrotate( c, 11 ), rbit_rrotate( c, 25 ) ) + rbit_bxor( e, rbit_band( c, rbit_bxor( d, e ) ) ) + x2 + 0x4d2c6dfc
    b = rbit_tobit( b + t1 )
    f = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( g, 2 ), rbit_rrotate( g, 13 ), rbit_rrotate( g, 22 ) ) + rbit_bor( rbit_band( g, h ), rbit_band( a, rbit_bor( g, h ) ) ) )

    x3 = rbit_tobit( x3 + rbit_bxor( rbit_rrotate( x1, 17 ), rbit_rrotate( x1, 19 ), rbit_rshift( x1, 10 ) ) + x12 + rbit_bxor( rbit_rrotate( x4, 7 ), rbit_rrotate( x4, 18 ), rbit_rshift( x4, 3 ) ) )
    t1 = e + rbit_bxor( rbit_rrotate( b, 6 ), rbit_rrotate( b, 11 ), rbit_rrotate( b, 25 ) ) + rbit_bxor( d, rbit_band( b, rbit_bxor( c, d ) ) ) + x3 + 0x53380d13
    a = rbit_tobit( a + t1 )
    e = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( f, 2 ), rbit_rrotate( f, 13 ), rbit_rrotate( f, 22 ) ) + rbit_bor( rbit_band( f, g ), rbit_band( h, rbit_bor( f, g ) ) ) )

    x4 = rbit_tobit( x4 + rbit_bxor( rbit_rrotate( x2, 17 ), rbit_rrotate( x2, 19 ), rbit_rshift( x2, 10 ) ) + x13 + rbit_bxor( rbit_rrotate( x5, 7 ), rbit_rrotate( x5, 18 ), rbit_rshift( x5, 3 ) ) )
    t1 = d + rbit_bxor( rbit_rrotate( a, 6 ), rbit_rrotate( a, 11 ), rbit_rrotate( a, 25 ) ) + rbit_bxor( c, rbit_band( a, rbit_bxor( b, c ) ) ) + x4 + 0x650a7354
    h = rbit_tobit( h + t1 )
    d = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( e, 2 ), rbit_rrotate( e, 13 ), rbit_rrotate( e, 22 ) ) + rbit_bor( rbit_band( e, f ), rbit_band( g, rbit_bor( e, f ) ) ) )

    x5 = rbit_tobit( x5 + rbit_bxor( rbit_rrotate( x3, 17 ), rbit_rrotate( x3, 19 ), rbit_rshift( x3, 10 ) ) + x14 + rbit_bxor( rbit_rrotate( x6, 7 ), rbit_rrotate( x6, 18 ), rbit_rshift( x6, 3 ) ) )
    t1 = c + rbit_bxor( rbit_rrotate( h, 6 ), rbit_rrotate( h, 11 ), rbit_rrotate( h, 25 ) ) + rbit_bxor( b, rbit_band( h, rbit_bxor( a, b ) ) ) + x5 + 0x766a0abb
    g = rbit_tobit( g + t1 )
    c = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( d, 2 ), rbit_rrotate( d, 13 ), rbit_rrotate( d, 22 ) ) + rbit_bor( rbit_band( d, e ), rbit_band( f, rbit_bor( d, e ) ) ) )

    x6 = rbit_tobit( x6 + rbit_bxor( rbit_rrotate( x4, 17 ), rbit_rrotate( x4, 19 ), rbit_rshift( x4, 10 ) ) + x15 + rbit_bxor( rbit_rrotate( x7, 7 ), rbit_rrotate( x7, 18 ), rbit_rshift( x7, 3 ) ) )
    t1 = b + rbit_bxor( rbit_rrotate( g, 6 ), rbit_rrotate( g, 11 ), rbit_rrotate( g, 25 ) ) + rbit_bxor( a, rbit_band( g, rbit_bxor( h, a ) ) ) + x6 - 0x7e3d36d2
    f = rbit_tobit( f + t1 )
    b = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( c, 2 ), rbit_rrotate( c, 13 ), rbit_rrotate( c, 22 ) ) + rbit_bor( rbit_band( c, d ), rbit_band( e, rbit_bor( c, d ) ) ) )

    x7 = rbit_tobit( x7 + rbit_bxor( rbit_rrotate( x5, 17 ), rbit_rrotate( x5, 19 ), rbit_rshift( x5, 10 ) ) + x0 + rbit_bxor( rbit_rrotate( x8, 7 ), rbit_rrotate( x8, 18 ), rbit_rshift( x8, 3 ) ) )
    t1 = a + rbit_bxor( rbit_rrotate( f, 6 ), rbit_rrotate( f, 11 ), rbit_rrotate( f, 25 ) ) + rbit_bxor( h, rbit_band( f, rbit_bxor( g, h ) ) ) + x7 - 0x6d8dd37b
    e = rbit_tobit( e + t1 )
    a = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( b, 2 ), rbit_rrotate( b, 13 ), rbit_rrotate( b, 22 ) ) + rbit_bor( rbit_band( b, c ), rbit_band( d, rbit_bor( b, c ) ) ) )

    x8 = rbit_tobit( x8 + rbit_bxor( rbit_rrotate( x6, 17 ), rbit_rrotate( x6, 19 ), rbit_rshift( x6, 10 ) ) + x1 + rbit_bxor( rbit_rrotate( x9, 7 ), rbit_rrotate( x9, 18 ), rbit_rshift( x9, 3 ) ) )
    t1 = h + rbit_bxor( rbit_rrotate( e, 6 ), rbit_rrotate( e, 11 ), rbit_rrotate( e, 25 ) ) + rbit_bxor( g, rbit_band( e, rbit_bxor( f, g ) ) ) + x8 - 0x5d40175f
    d = rbit_tobit( d + t1 )
    h = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( a, 2 ), rbit_rrotate( a, 13 ), rbit_rrotate( a, 22 ) ) + rbit_bor( rbit_band( a, b ), rbit_band( c, rbit_bor( a, b ) ) ) )

    x9 = rbit_tobit( x9 + rbit_bxor( rbit_rrotate( x7, 17 ), rbit_rrotate( x7, 19 ), rbit_rshift( x7, 10 ) ) + x2 + rbit_bxor( rbit_rrotate( x10, 7 ), rbit_rrotate( x10, 18 ), rbit_rshift( x10, 3 ) ) )
    t1 = g + rbit_bxor( rbit_rrotate( d, 6 ), rbit_rrotate( d, 11 ), rbit_rrotate( d, 25 ) ) + rbit_bxor( f, rbit_band( d, rbit_bxor( e, f ) ) ) + x9 - 0x57e599b5
    c = rbit_tobit( c + t1 )
    g = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( h, 2 ), rbit_rrotate( h, 13 ), rbit_rrotate( h, 22 ) ) + rbit_bor( rbit_band( h, a ), rbit_band( b, rbit_bor( h, a ) ) ) )

    x10 = rbit_tobit( x10 + rbit_bxor( rbit_rrotate( x8, 17 ), rbit_rrotate( x8, 19 ), rbit_rshift( x8, 10 ) ) + x3 + rbit_bxor( rbit_rrotate( x11, 7 ), rbit_rrotate( x11, 18 ), rbit_rshift( x11, 3 ) ) )
    t1 = f + rbit_bxor( rbit_rrotate( c, 6 ), rbit_rrotate( c, 11 ), rbit_rrotate( c, 25 ) ) + rbit_bxor( e, rbit_band( c, rbit_bxor( d, e ) ) ) + x10 - 0x3db47490
    b = rbit_tobit( b + t1 )
    f = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( g, 2 ), rbit_rrotate( g, 13 ), rbit_rrotate( g, 22 ) ) + rbit_bor( rbit_band( g, h ), rbit_band( a, rbit_bor( g, h ) ) ) )

    x11 = rbit_tobit( x11 + rbit_bxor( rbit_rrotate( x9, 17 ), rbit_rrotate( x9, 19 ), rbit_rshift( x9, 10 ) ) + x4 + rbit_bxor( rbit_rrotate( x12, 7 ), rbit_rrotate( x12, 18 ), rbit_rshift( x12, 3 ) ) )
    t1 = e + rbit_bxor( rbit_rrotate( b, 6 ), rbit_rrotate( b, 11 ), rbit_rrotate( b, 25 ) ) + rbit_bxor( d, rbit_band( b, rbit_bxor( c, d ) ) ) + x11 - 0x3893ae5d
    a = rbit_tobit( a + t1 )
    e = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( f, 2 ), rbit_rrotate( f, 13 ), rbit_rrotate( f, 22 ) ) + rbit_bor( rbit_band( f, g ), rbit_band( h, rbit_bor( f, g ) ) ) )

    x12 = rbit_tobit( x12 + rbit_bxor( rbit_rrotate( x10, 17 ), rbit_rrotate( x10, 19 ), rbit_rshift( x10, 10 ) ) + x5 + rbit_bxor( rbit_rrotate( x13, 7 ), rbit_rrotate( x13, 18 ), rbit_rshift( x13, 3 ) ) )
    t1 = d + rbit_bxor( rbit_rrotate( a, 6 ), rbit_rrotate( a, 11 ), rbit_rrotate( a, 25 ) ) + rbit_bxor( c, rbit_band( a, rbit_bxor( b, c ) ) ) + x12 - 0x2e6d17e7
    h = rbit_tobit( h + t1 )
    d = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( e, 2 ), rbit_rrotate( e, 13 ), rbit_rrotate( e, 22 ) ) + rbit_bor( rbit_band( e, f ), rbit_band( g, rbit_bor( e, f ) ) ) )

    x13 = rbit_tobit( x13 + rbit_bxor( rbit_rrotate( x11, 17 ), rbit_rrotate( x11, 19 ), rbit_rshift( x11, 10 ) ) + x6 + rbit_bxor( rbit_rrotate( x14, 7 ), rbit_rrotate( x14, 18 ), rbit_rshift( x14, 3 ) ) )
    t1 = c + rbit_bxor( rbit_rrotate( h, 6 ), rbit_rrotate( h, 11 ), rbit_rrotate( h, 25 ) ) + rbit_bxor( b, rbit_band( h, rbit_bxor( a, b ) ) ) + x13 - 0x2966f9dc
    g = rbit_tobit( g + t1 )
    c = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( d, 2 ), rbit_rrotate( d, 13 ), rbit_rrotate( d, 22 ) ) + rbit_bor( rbit_band( d, e ), rbit_band( f, rbit_bor( d, e ) ) ) )

    x14 = rbit_tobit( x14 + rbit_bxor( rbit_rrotate( x12, 17 ), rbit_rrotate( x12, 19 ), rbit_rshift( x12, 10 ) ) + x7 + rbit_bxor( rbit_rrotate( x15, 7 ), rbit_rrotate( x15, 18 ), rbit_rshift( x15, 3 ) ) )
    t1 = b + rbit_bxor( rbit_rrotate( g, 6 ), rbit_rrotate( g, 11 ), rbit_rrotate( g, 25 ) ) + rbit_bxor( a, rbit_band( g, rbit_bxor( h, a ) ) ) + x14 - 0x0bf1ca7b
    f = rbit_tobit( f + t1 )
    b = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( c, 2 ), rbit_rrotate( c, 13 ), rbit_rrotate( c, 22 ) ) + rbit_bor( rbit_band( c, d ), rbit_band( e, rbit_bor( c, d ) ) ) )

    x15 = rbit_tobit( x15 + rbit_bxor( rbit_rrotate( x13, 17 ), rbit_rrotate( x13, 19 ), rbit_rshift( x13, 10 ) ) + x8 + rbit_bxor( rbit_rrotate( x0, 7 ), rbit_rrotate( x0, 18 ), rbit_rshift( x0, 3 ) ) )
    t1 = a + rbit_bxor( rbit_rrotate( f, 6 ), rbit_rrotate( f, 11 ), rbit_rrotate( f, 25 ) ) + rbit_bxor( h, rbit_band( f, rbit_bxor( g, h ) ) ) + x15 + 0x106aa070
    e = rbit_tobit( e + t1 )
    a = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( b, 2 ), rbit_rrotate( b, 13 ), rbit_rrotate( b, 22 ) ) + rbit_bor( rbit_band( b, c ), rbit_band( d, rbit_bor( b, c ) ) ) )

    x0 = rbit_tobit( x0 + rbit_bxor( rbit_rrotate( x14, 17 ), rbit_rrotate( x14, 19 ), rbit_rshift( x14, 10 ) ) + x9 + rbit_bxor( rbit_rrotate( x1, 7 ), rbit_rrotate( x1, 18 ), rbit_rshift( x1, 3 ) ) )
    t1 = h + rbit_bxor( rbit_rrotate( e, 6 ), rbit_rrotate( e, 11 ), rbit_rrotate( e, 25 ) ) + rbit_bxor( g, rbit_band( e, rbit_bxor( f, g ) ) ) + x0 + 0x19a4c116
    d = rbit_tobit( d + t1 )
    h = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( a, 2 ), rbit_rrotate( a, 13 ), rbit_rrotate( a, 22 ) ) + rbit_bor( rbit_band( a, b ), rbit_band( c, rbit_bor( a, b ) ) ) )

    x1 = rbit_tobit( x1 + rbit_bxor( rbit_rrotate( x15, 17 ), rbit_rrotate( x15, 19 ), rbit_rshift( x15, 10 ) ) + x10 + rbit_bxor( rbit_rrotate( x2, 7 ), rbit_rrotate( x2, 18 ), rbit_rshift( x2, 3 ) ) )
    t1 = g + rbit_bxor( rbit_rrotate( d, 6 ), rbit_rrotate( d, 11 ), rbit_rrotate( d, 25 ) ) + rbit_bxor( f, rbit_band( d, rbit_bxor( e, f ) ) ) + x1 + 0x1e376c08
    c = rbit_tobit( c + t1 )
    g = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( h, 2 ), rbit_rrotate( h, 13 ), rbit_rrotate( h, 22 ) ) + rbit_bor( rbit_band( h, a ), rbit_band( b, rbit_bor( h, a ) ) ) )

    x2 = rbit_tobit( x2 + rbit_bxor( rbit_rrotate( x0, 17 ), rbit_rrotate( x0, 19 ), rbit_rshift( x0, 10 ) ) + x11 + rbit_bxor( rbit_rrotate( x3, 7 ), rbit_rrotate( x3, 18 ), rbit_rshift( x3, 3 ) ) )
    t1 = f + rbit_bxor( rbit_rrotate( c, 6 ), rbit_rrotate( c, 11 ), rbit_rrotate( c, 25 ) ) + rbit_bxor( e, rbit_band( c, rbit_bxor( d, e ) ) ) + x2 + 0x2748774c
    b = rbit_tobit( b + t1 )
    f = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( g, 2 ), rbit_rrotate( g, 13 ), rbit_rrotate( g, 22 ) ) + rbit_bor( rbit_band( g, h ), rbit_band( a, rbit_bor( g, h ) ) ) )

    x3 = rbit_tobit( x3 + rbit_bxor( rbit_rrotate( x1, 17 ), rbit_rrotate( x1, 19 ), rbit_rshift( x1, 10 ) ) + x12 + rbit_bxor( rbit_rrotate( x4, 7 ), rbit_rrotate( x4, 18 ), rbit_rshift( x4, 3 ) ) )
    t1 = e + rbit_bxor( rbit_rrotate( b, 6 ), rbit_rrotate( b, 11 ), rbit_rrotate( b, 25 ) ) + rbit_bxor( d, rbit_band( b, rbit_bxor( c, d ) ) ) + x3 + 0x34b0bcb5
    a = rbit_tobit( a + t1 )
    e = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( f, 2 ), rbit_rrotate( f, 13 ), rbit_rrotate( f, 22 ) ) + rbit_bor( rbit_band( f, g ), rbit_band( h, rbit_bor( f, g ) ) ) )

    x4 = rbit_tobit( x4 + rbit_bxor( rbit_rrotate( x2, 17 ), rbit_rrotate( x2, 19 ), rbit_rshift( x2, 10 ) ) + x13 + rbit_bxor( rbit_rrotate( x5, 7 ), rbit_rrotate( x5, 18 ), rbit_rshift( x5, 3 ) ) )
    t1 = d + rbit_bxor( rbit_rrotate( a, 6 ), rbit_rrotate( a, 11 ), rbit_rrotate( a, 25 ) ) + rbit_bxor( c, rbit_band( a, rbit_bxor( b, c ) ) ) + x4 + 0x391c0cb3
    h = rbit_tobit( h + t1 )
    d = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( e, 2 ), rbit_rrotate( e, 13 ), rbit_rrotate( e, 22 ) ) + rbit_bor( rbit_band( e, f ), rbit_band( g, rbit_bor( e, f ) ) ) )

    x5 = rbit_tobit( x5 + rbit_bxor( rbit_rrotate( x3, 17 ), rbit_rrotate( x3, 19 ), rbit_rshift( x3, 10 ) ) + x14 + rbit_bxor( rbit_rrotate( x6, 7 ), rbit_rrotate( x6, 18 ), rbit_rshift( x6, 3 ) ) )
    t1 = c + rbit_bxor( rbit_rrotate( h, 6 ), rbit_rrotate( h, 11 ), rbit_rrotate( h, 25 ) ) + rbit_bxor( b, rbit_band( h, rbit_bxor( a, b ) ) ) + x5 + 0x4ed8aa4a
    g = rbit_tobit( g + t1 )
    c = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( d, 2 ), rbit_rrotate( d, 13 ), rbit_rrotate( d, 22 ) ) + rbit_bor( rbit_band( d, e ), rbit_band( f, rbit_bor( d, e ) ) ) )

    x6 = rbit_tobit( x6 + rbit_bxor( rbit_rrotate( x4, 17 ), rbit_rrotate( x4, 19 ), rbit_rshift( x4, 10 ) ) + x15 + rbit_bxor( rbit_rrotate( x7, 7 ), rbit_rrotate( x7, 18 ), rbit_rshift( x7, 3 ) ) )
    t1 = b + rbit_bxor( rbit_rrotate( g, 6 ), rbit_rrotate( g, 11 ), rbit_rrotate( g, 25 ) ) + rbit_bxor( a, rbit_band( g, rbit_bxor( h, a ) ) ) + x6 + 0x5b9cca4f
    f = rbit_tobit( f + t1 )
    b = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( c, 2 ), rbit_rrotate( c, 13 ), rbit_rrotate( c, 22 ) ) + rbit_bor( rbit_band( c, d ), rbit_band( e, rbit_bor( c, d ) ) ) )

    x7 = rbit_tobit( x7 + rbit_bxor( rbit_rrotate( x5, 17 ), rbit_rrotate( x5, 19 ), rbit_rshift( x5, 10 ) ) + x0 + rbit_bxor( rbit_rrotate( x8, 7 ), rbit_rrotate( x8, 18 ), rbit_rshift( x8, 3 ) ) )
    t1 = a + rbit_bxor( rbit_rrotate( f, 6 ), rbit_rrotate( f, 11 ), rbit_rrotate( f, 25 ) ) + rbit_bxor( h, rbit_band( f, rbit_bxor( g, h ) ) ) + x7 + 0x682e6ff3
    e = rbit_tobit( e + t1 )
    a = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( b, 2 ), rbit_rrotate( b, 13 ), rbit_rrotate( b, 22 ) ) + rbit_bor( rbit_band( b, c ), rbit_band( d, rbit_bor( b, c ) ) ) )

    x8 = rbit_tobit( x8 + rbit_bxor( rbit_rrotate( x6, 17 ), rbit_rrotate( x6, 19 ), rbit_rshift( x6, 10 ) ) + x1 + rbit_bxor( rbit_rrotate( x9, 7 ), rbit_rrotate( x9, 18 ), rbit_rshift( x9, 3 ) ) )
    t1 = h + rbit_bxor( rbit_rrotate( e, 6 ), rbit_rrotate( e, 11 ), rbit_rrotate( e, 25 ) ) + rbit_bxor( g, rbit_band( e, rbit_bxor( f, g ) ) ) + x8 + 0x748f82ee
    d = rbit_tobit( d + t1 )
    h = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( a, 2 ), rbit_rrotate( a, 13 ), rbit_rrotate( a, 22 ) ) + rbit_bor( rbit_band( a, b ), rbit_band( c, rbit_bor( a, b ) ) ) )

    x9 = rbit_tobit( x9 + rbit_bxor( rbit_rrotate( x7, 17 ), rbit_rrotate( x7, 19 ), rbit_rshift( x7, 10 ) ) + x2 + rbit_bxor( rbit_rrotate( x10, 7 ), rbit_rrotate( x10, 18 ), rbit_rshift( x10, 3 ) ) )
    t1 = g + rbit_bxor( rbit_rrotate( d, 6 ), rbit_rrotate( d, 11 ), rbit_rrotate( d, 25 ) ) + rbit_bxor( f, rbit_band( d, rbit_bxor( e, f ) ) ) + x9 + 0x78a5636f
    c = rbit_tobit( c + t1 )
    g = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( h, 2 ), rbit_rrotate( h, 13 ), rbit_rrotate( h, 22 ) ) + rbit_bor( rbit_band( h, a ), rbit_band( b, rbit_bor( h, a ) ) ) )

    x10 = rbit_tobit( x10 + rbit_bxor( rbit_rrotate( x8, 17 ), rbit_rrotate( x8, 19 ), rbit_rshift( x8, 10 ) ) + x3 + rbit_bxor( rbit_rrotate( x11, 7 ), rbit_rrotate( x11, 18 ), rbit_rshift( x11, 3 ) ) )
    t1 = f + rbit_bxor( rbit_rrotate( c, 6 ), rbit_rrotate( c, 11 ), rbit_rrotate( c, 25 ) ) + rbit_bxor( e, rbit_band( c, rbit_bxor( d, e ) ) ) + x10 - 0x7b3787ec
    b = rbit_tobit( b + t1 )
    f = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( g, 2 ), rbit_rrotate( g, 13 ), rbit_rrotate( g, 22 ) ) + rbit_bor( rbit_band( g, h ), rbit_band( a, rbit_bor( g, h ) ) ) )

    x11 = rbit_tobit( x11 + rbit_bxor( rbit_rrotate( x9, 17 ), rbit_rrotate( x9, 19 ), rbit_rshift( x9, 10 ) ) + x4 + rbit_bxor( rbit_rrotate( x12, 7 ), rbit_rrotate( x12, 18 ), rbit_rshift( x12, 3 ) ) )
    t1 = e + rbit_bxor( rbit_rrotate( b, 6 ), rbit_rrotate( b, 11 ), rbit_rrotate( b, 25 ) ) + rbit_bxor( d, rbit_band( b, rbit_bxor( c, d ) ) ) + x11 - 0x7338fdf8
    a = rbit_tobit( a + t1 )
    e = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( f, 2 ), rbit_rrotate( f, 13 ), rbit_rrotate( f, 22 ) ) + rbit_bor( rbit_band( f, g ), rbit_band( h, rbit_bor( f, g ) ) ) )

    x12 = rbit_tobit( x12 + rbit_bxor( rbit_rrotate( x10, 17 ), rbit_rrotate( x10, 19 ), rbit_rshift( x10, 10 ) ) + x5 + rbit_bxor( rbit_rrotate( x13, 7 ), rbit_rrotate( x13, 18 ), rbit_rshift( x13, 3 ) ) )
    t1 = d + rbit_bxor( rbit_rrotate( a, 6 ), rbit_rrotate( a, 11 ), rbit_rrotate( a, 25 ) ) + rbit_bxor( c, rbit_band( a, rbit_bxor( b, c ) ) ) + x12 - 0x6f410006
    h = rbit_tobit( h + t1 )
    d = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( e, 2 ), rbit_rrotate( e, 13 ), rbit_rrotate( e, 22 ) ) + rbit_bor( rbit_band( e, f ), rbit_band( g, rbit_bor( e, f ) ) ) )

    x13 = rbit_tobit( x13 + rbit_bxor( rbit_rrotate( x11, 17 ), rbit_rrotate( x11, 19 ), rbit_rshift( x11, 10 ) ) + x6 + rbit_bxor( rbit_rrotate( x14, 7 ), rbit_rrotate( x14, 18 ), rbit_rshift( x14, 3 ) ) )
    t1 = c + rbit_bxor( rbit_rrotate( h, 6 ), rbit_rrotate( h, 11 ), rbit_rrotate( h, 25 ) ) + rbit_bxor( b, rbit_band( h, rbit_bxor( a, b ) ) ) + x13 - 0x5baf9315
    g = rbit_tobit( g + t1 )
    c = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( d, 2 ), rbit_rrotate( d, 13 ), rbit_rrotate( d, 22 ) ) + rbit_bor( rbit_band( d, e ), rbit_band( f, rbit_bor( d, e ) ) ) )

    x14 = rbit_tobit( x14 + rbit_bxor( rbit_rrotate( x12, 17 ), rbit_rrotate( x12, 19 ), rbit_rshift( x12, 10 ) ) + x7 + rbit_bxor( rbit_rrotate( x15, 7 ), rbit_rrotate( x15, 18 ), rbit_rshift( x15, 3 ) ) )
    t1 = b + rbit_bxor( rbit_rrotate( g, 6 ), rbit_rrotate( g, 11 ), rbit_rrotate( g, 25 ) ) + rbit_bxor( a, rbit_band( g, rbit_bxor( h, a ) ) ) + x14 - 0x41065c09
    f = rbit_tobit( f + t1 )
    b = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( c, 2 ), rbit_rrotate( c, 13 ), rbit_rrotate( c, 22 ) ) + rbit_bor( rbit_band( c, d ), rbit_band( e, rbit_bor( c, d ) ) ) )

    x15 = rbit_tobit( x15 + rbit_bxor( rbit_rrotate( x13, 17 ), rbit_rrotate( x13, 19 ), rbit_rshift( x13, 10 ) ) + x8 + rbit_bxor( rbit_rrotate( x0, 7 ), rbit_rrotate( x0, 18 ), rbit_rshift( x0, 3 ) ) )
    t1 = a + rbit_bxor( rbit_rrotate( f, 6 ), rbit_rrotate( f, 11 ), rbit_rrotate( f, 25 ) ) + rbit_bxor( h, rbit_band( f, rbit_bxor( g, h ) ) ) + x15 - 0x398e870e
    e = rbit_tobit( e + t1 )
    a = rbit_tobit( t1 + rbit_bxor( rbit_rrotate( b, 2 ), rbit_rrotate( b, 13 ), rbit_rrotate( b, 22 ) ) + rbit_bor( rbit_band( b, c ), rbit_band( d, rbit_bor( b, c ) ) ) )

    return rbit_tobit( h1 + a ), rbit_tobit( h2 + b ), rbit_tobit( h3 + c ), rbit_tobit( h4 + d ),
        rbit_tobit( h5 + e ), rbit_tobit( h6 + f ), rbit_tobit( h7 + g ), rbit_tobit( h8 + h )
end

--- Processes a single 64-byte block.
---
---@type fun( str: string, offset: integer, h1: integer, h2: integer, h3: integer, h4: integer, h5: integer, h6: integer, h7: integer, h8: integer ): integer, integer, integer, integer, integer, integer, integer, integer
local transform

if ffi == nil then

    ---@param str string
    ---@param offset integer The 0-based byte offset of the block.
    function transform( str, offset, h1, h2, h3, h4, h5, h6, h7, h8 )
        -- every word is built right after its bytes are read, otherwise 64 live bytes run JIT out of spill slots
        local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 1, offset + 4 )
        local x0 = rbit_bor( rbit_lshift( uint8_1, 24 ), rbit_lshift( uint8_2, 16 ), rbit_lshift( uint8_3, 8 ), uint8_4 )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 5, offset + 8 )
        local x1 = rbit_bor( rbit_lshift( uint8_1, 24 ), rbit_lshift( uint8_2, 16 ), rbit_lshift( uint8_3, 8 ), uint8_4 )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 9, offset + 12 )
        local x2 = rbit_bor( rbit_lshift( uint8_1, 24 ), rbit_lshift( uint8_2, 16 ), rbit_lshift( uint8_3, 8 ), uint8_4 )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 13, offset + 16 )
        local x3 = rbit_bor( rbit_lshift( uint8_1, 24 ), rbit_lshift( uint8_2, 16 ), rbit_lshift( uint8_3, 8 ), uint8_4 )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 17, offset + 20 )
        local x4 = rbit_bor( rbit_lshift( uint8_1, 24 ), rbit_lshift( uint8_2, 16 ), rbit_lshift( uint8_3, 8 ), uint8_4 )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 21, offset + 24 )
        local x5 = rbit_bor( rbit_lshift( uint8_1, 24 ), rbit_lshift( uint8_2, 16 ), rbit_lshift( uint8_3, 8 ), uint8_4 )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 25, offset + 28 )
        local x6 = rbit_bor( rbit_lshift( uint8_1, 24 ), rbit_lshift( uint8_2, 16 ), rbit_lshift( uint8_3, 8 ), uint8_4 )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 29, offset + 32 )
        local x7 = rbit_bor( rbit_lshift( uint8_1, 24 ), rbit_lshift( uint8_2, 16 ), rbit_lshift( uint8_3, 8 ), uint8_4 )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 33, offset + 36 )
        local x8 = rbit_bor( rbit_lshift( uint8_1, 24 ), rbit_lshift( uint8_2, 16 ), rbit_lshift( uint8_3, 8 ), uint8_4 )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 37, offset + 40 )
        local x9 = rbit_bor( rbit_lshift( uint8_1, 24 ), rbit_lshift( uint8_2, 16 ), rbit_lshift( uint8_3, 8 ), uint8_4 )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 41, offset + 44 )
        local x10 = rbit_bor( rbit_lshift( uint8_1, 24 ), rbit_lshift( uint8_2, 16 ), rbit_lshift( uint8_3, 8 ), uint8_4 )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 45, offset + 48 )
        local x11 = rbit_bor( rbit_lshift( uint8_1, 24 ), rbit_lshift( uint8_2, 16 ), rbit_lshift( uint8_3, 8 ), uint8_4 )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 49, offset + 52 )
        local x12 = rbit_bor( rbit_lshift( uint8_1, 24 ), rbit_lshift( uint8_2, 16 ), rbit_lshift( uint8_3, 8 ), uint8_4 )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 53, offset + 56 )
        local x13 = rbit_bor( rbit_lshift( uint8_1, 24 ), rbit_lshift( uint8_2, 16 ), rbit_lshift( uint8_3, 8 ), uint8_4 )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 57, offset + 60 )
        local x14 = rbit_bor( rbit_lshift( uint8_1, 24 ), rbit_lshift( uint8_2, 16 ), rbit_lshift( uint8_3, 8 ), uint8_4 )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 61, offset + 64 )
        local x15 = rbit_bor( rbit_lshift( uint8_1, 24 ), rbit_lshift( uint8_2, 16 ), rbit_lshift( uint8_3, 8 ), uint8_4 )

        return compress( h1, h2, h3, h4, h5, h6, h7, h8, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15 )
    end

else

    local ffi_cast = ffi.cast

    local uint8_ptr_t = ffi.typeof( "const uint8_t *" )
    local int32_ptr_t = ffi.typeof( "const int32_t *" )

    if ffi.abi( "le" ) then

        -- words are big endian, so on little endian systems they are byte-swapped after reading
        ---@param str string
        ---@param offset integer The 0-based byte offset of the block.
        function transform( str, offset, h1, h2, h3, h4, h5, h6, h7, h8 )
            local x = ffi_cast( int32_ptr_t, ffi_cast( uint8_ptr_t, str ) + offset )
            return compress( h1, h2, h3, h4, h5, h6, h7, h8,
                rbit_bswap( x[ 0 ] ), rbit_bswap( x[ 1 ] ), rbit_bswap( x[ 2 ] ), rbit_bswap( x[ 3 ] ),
                rbit_bswap( x[ 4 ] ), rbit_bswap( x[ 5 ] ), rbit_bswap( x[ 6 ] ), rbit_bswap( x[ 7 ] ),
                rbit_bswap( x[ 8 ] ), rbit_bswap( x[ 9 ] ), rbit_bswap( x[ 10 ] ), rbit_bswap( x[ 11 ] ),
                rbit_bswap( x[ 12 ] ), rbit_bswap( x[ 13 ] ), rbit_bswap( x[ 14 ] ), rbit_bswap( x[ 15 ] )
            )
        end

    else

        ---@param str string
        ---@param offset integer The 0-based byte offset of the block.
        function transform( str, offset, h1, h2, h3, h4, h5, h6, h7, h8 )
            local x = ffi_cast( int32_ptr_t, ffi_cast( uint8_ptr_t, str ) + offset )
            return compress( h1, h2, h3, h4, h5, h6, h7, h8,
                x[ 0 ], x[ 1 ], x[ 2 ], x[ 3 ], x[ 4 ], x[ 5 ], x[ 6 ], x[ 7 ],
                x[ 8 ], x[ 9 ], x[ 10 ], x[ 11 ], x[ 12 ], x[ 13 ], x[ 14 ], x[ 15 ]
            )
        end

    end

end

--- Processes all complete 64-byte blocks of the string starting from the given offset.
---
---@param str string
---@param offset integer The 0-based byte offset.
---@param str_length integer
---@return integer offset The offset of the first unprocessed byte.
---@return integer h1
---@return integer h2
---@return integer h3
---@return integer h4
---@return integer h5
---@return integer h6
---@return integer h7
---@return integer h8
local function process( str, offset, str_length, h1, h2, h3, h4, h5, h6, h7, h8 )
    local last_offset = str_length - 64

    while offset <= last_offset do
        h1, h2, h3, h4, h5, h6, h7, h8 = transform( str, offset, h1, h2, h3, h4, h5, h6, h7, h8 )
        offset = offset + 64
    end

    return offset, h1, h2, h3, h4, h5, h6, h7, h8
end

--- Pads the tail of the message, processes the final block(s) and returns the digest.
---
---@param tail string The unprocessed tail of the message, less than 64 bytes.
---@param message_length integer The total length of the message in bytes.
---@param as_hex? boolean
---@return string
local function finalize( tail, message_length, h1, h2, h3, h4, h5, h6, h7, h8, as_hex )
    local bit_count_low = (message_length % 0x20000000) * 8
    local bit_count_high = math_floor( message_length / 0x20000000 )

    local block = tail .. "\128" .. string_rep( "\0", (55 - string_len( tail )) % 64 ) .. string_char(
        rbit_rshift( bit_count_high, 24 ), rbit_band( rbit_rshift( bit_count_high, 16 ), 0xFF ), rbit_band( rbit_rshift( bit_count_high, 8 ), 0xFF ), rbit_band( bit_count_high, 0xFF ),
        rbit_rshift( bit_count_low, 24 ), rbit_band( rbit_rshift( bit_count_low, 16 ), 0xFF ), rbit_band( rbit_rshift( bit_count_low, 8 ), 0xFF ), rbit_band( bit_count_low, 0xFF )
    )

    h1, h2, h3, h4, h5, h6, h7, h8 = transform( block, 0, h1, h2, h3, h4, h5, h6, h7, h8 )

    if string_len( block ) == 128 then
        h1, h2, h3, h4, h5, h6, h7, h8 = transform( block, 64, h1, h2, h3, h4, h5, h6, h7, h8 )
    end

    if as_hex then
        return string_format( "%08x%08x%08x%08x%08x%08x%08x%08x",
            h1 % 0x100000000,
            h2 % 0x100000000,
            h3 % 0x100000000,
            h4 % 0x100000000,
            h5 % 0x100000000,
            h6 % 0x100000000,
            h7 % 0x100000000,
            h8 % 0x100000000
        )
    end

    return string_char(
        rbit_rshift( h1, 24 ), rbit_band( rbit_rshift( h1, 16 ), 0xFF ), rbit_band( rbit_rshift( h1, 8 ), 0xFF ), rbit_band( h1, 0xFF ),
        rbit_rshift( h2, 24 ), rbit_band( rbit_rshift( h2, 16 ), 0xFF ), rbit_band( rbit_rshift( h2, 8 ), 0xFF ), rbit_band( h2, 0xFF ),
        rbit_rshift( h3, 24 ), rbit_band( rbit_rshift( h3, 16 ), 0xFF ), rbit_band( rbit_rshift( h3, 8 ), 0xFF ), rbit_band( h3, 0xFF ),
        rbit_rshift( h4, 24 ), rbit_band( rbit_rshift( h4, 16 ), 0xFF ), rbit_band( rbit_rshift( h4, 8 ), 0xFF ), rbit_band( h4, 0xFF ),
        rbit_rshift( h5, 24 ), rbit_band( rbit_rshift( h5, 16 ), 0xFF ), rbit_band( rbit_rshift( h5, 8 ), 0xFF ), rbit_band( h5, 0xFF ),
        rbit_rshift( h6, 24 ), rbit_band( rbit_rshift( h6, 16 ), 0xFF ), rbit_band( rbit_rshift( h6, 8 ), 0xFF ), rbit_band( h6, 0xFF ),
        rbit_rshift( h7, 24 ), rbit_band( rbit_rshift( h7, 16 ), 0xFF ), rbit_band( rbit_rshift( h7, 8 ), 0xFF ), rbit_band( h7, 0xFF ),
        rbit_rshift( h8, 24 ), rbit_band( rbit_rshift( h8, 16 ), 0xFF ), rbit_band( rbit_rshift( h8, 8 ), 0xFF ), rbit_band( h8, 0xFF )
    )
end

--- [SHARED AND MENU]
---
--- Resets the SHA256 object to its initial state.
---
--- This instance method resets the SHA256 object to its initial state.
---
--- It returns the SHA256 object for method chaining.
---
---@return dreamwork.std.crypto.SHA256 obj The reset SHA256 object.
function SHA256:reset()
    self.h1, self.h2, self.h3, self.h4, self.h5, self.h6, self.h7, self.h8 = 0x6a09e667, -0x4498517b, 0x3c6ef372, -0x5ab00ac6, 0x510e527f, -0x64fa9774, 0x1f83d9ab, 0x5be0cd19

    self.message_length = 0
    self.buffer = ""

    return self
end

SHA256.__init = SHA256.reset

---@return string
---@protected
function SHA256:__represent()
    return string_format( "%s: %p [%d]", type( self ), self, self.message_length )
end

--- [SHARED AND MENU]
---
--- Updates the SHA256 object with the given string.
---
--- This instance method updates the SHA256 object with the given string.
---
--- It returns the SHA256 object for method chaining.
---
---@param str string The string to update the SHA256 object with.
---@return dreamwork.std.crypto.SHA256 obj The updated SHA256 object.
function SHA256:update( str )
    local str_length = string_len( str )
    if str_length == 0 then
        return self
    end

    self.message_length = self.message_length + str_length

    local buffer = self.buffer
    local required = 64 - string_len( buffer )

    if str_length < required then
        self.buffer = buffer .. str
        return self
    end

    local h1, h2, h3, h4, h5, h6, h7, h8 = self.h1, self.h2, self.h3, self.h4, self.h5, self.h6, self.h7, self.h8
    local offset = 0

    -- complete the buffered block without copying the whole string
    if required ~= 64 then
        h1, h2, h3, h4, h5, h6, h7, h8 = transform( buffer .. string_sub( str, 1, required ), 0, h1, h2, h3, h4, h5, h6, h7, h8 )
        offset = required
    end

    offset, h1, h2, h3, h4, h5, h6, h7, h8 = process( str, offset, str_length, h1, h2, h3, h4, h5, h6, h7, h8 )

    self.h1, self.h2, self.h3, self.h4, self.h5, self.h6, self.h7, self.h8 = h1, h2, h3, h4, h5, h6, h7, h8
    self.buffer = string_sub( str, offset + 1 )

    return self
end

--- [SHARED AND MENU]
---
--- Calculates the SHA256 digest based on the current state or input of the object.
---
--- This instance method returns the SHA256 hash of the data associated with the object.
--- Useful when the SHA256 object has been incrementally updated with input data.
---
--- Does not change the state, so the object can be updated further.
---
---@param as_hex? boolean If true, the result will be a hex string.
---@return string str_result The SHA256 string of the message.
---@nodiscard
function SHA256:digest( as_hex )
    return finalize( self.buffer, self.message_length, self.h1, self.h2, self.h3, self.h4, self.h5, self.h6, self.h7, self.h8, as_hex )
end

SHA256.__tostring = SHA256.digest

if util == nil or util.SHA256 == nil then

    --- [SHARED AND MENU]
    ---
    --- Computes the SHA256 digest of the given input string.
    ---
    --- This static method takes a string and returns its SHA256 hash as a hexadecimal string.
    --- Commonly used for checksums, data integrity validation, and password hashing.
    ---
    ---@param message string The message to compute SHA256 for.
    ---@param as_hex? boolean If true, the result will be a hex string.
    ---@return string str_result The SHA256 string of the message.
    ---@nodiscard
    function SHA256Class.digest( message, as_hex )
        local message_length = string_len( message )
        local offset, h1, h2, h3, h4, h5, h6, h7, h8 = process( message, 0, message_length, 0x6a09e667, -0x4498517b, 0x3c6ef372, -0x5ab00ac6, 0x510e527f, -0x64fa9774, 0x1f83d9ab, 0x5be0cd19 )
        return finalize( string_sub( message, offset + 1 ), message_length, h1, h2, h3, h4, h5, h6, h7, h8, as_hex )
    end

else

    local base16_decode = std.base16.decode
    local util_SHA256 = util.SHA256

    --- [SHARED AND MENU]
    ---
    --- Computes the SHA256 digest of the given input string.
    ---
    --- This static method takes a string and returns its SHA256 hash as a hexadecimal string.
    --- Commonly used for checksums, data integrity validation, and password hashing.
    ---
    ---@param message string The message to compute SHA256 for.
    ---@param as_hex? boolean If true, the result will be a hex string.
    ---@return string str_result The SHA256 string of the message.
    ---@nodiscard
    function SHA256Class.digest( message, as_hex )
        local hex_str = util_SHA256( message )
        if as_hex then
            return hex_str
        end

        return base16_decode( hex_str )
    end

end
