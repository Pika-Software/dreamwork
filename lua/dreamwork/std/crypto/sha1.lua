local std = dreamwork.std
local ffi = std.ffi

---@class dreamwork.std.crypto
local crypto = std.crypto

local class = std.class

local rbit = std.raw.bit
local rbit_bswap = rbit.bswap
local rbit_lrotate = rbit.lrotate
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
--- SHA1 object.
---
---@class dreamwork.std.crypto.SHA1 : dreamwork.std.Object
---@field __class dreamwork.std.crypto.SHA1Class
---@field protected h1 integer The first word of the hash state ( int32 ).
---@field protected h2 integer The second word of the hash state ( int32 ).
---@field protected h3 integer The third word of the hash state ( int32 ).
---@field protected h4 integer The fourth word of the hash state ( int32 ).
---@field protected h5 integer The fifth word of the hash state ( int32 ).
---@field protected message_length integer The total length of the message in bytes.
---@field protected buffer string The unprocessed tail of the message, less than 64 bytes.
local SHA1 = class.base( "SHA1" )

--- [SHARED AND MENU]
---
--- The class used to create new `SHA1` hash calculation instances.
---
--- Computes a cryptographic 160-bit hash value.
---
--- Like other hash classes, it takes input data ( string )
--- and produces a digest ( string ) — a
--- fixed-size output string that represents that data.
---
--- **SHA1 is insecure**
---
--- Because of collision attacks,
--- attackers can find two different inputs
--- that produce the same hash.
---
--- This violates one of the basic principles
--- of a secure hash function - collision resistance.
---
---@class dreamwork.std.crypto.SHA1Class : dreamwork.std.crypto.SHA1, dreamwork.std.crypto.HashClass
---@field __base dreamwork.std.crypto.SHA1
---@field digest fun( message: string, as_hex?: boolean ): string
---@field digest_size integer
---@field block_size integer
---@operator call: dreamwork.std.crypto.SHA1
local SHA1Class = class.create( SHA1 )
crypto.SHA1 = SHA1Class

SHA1Class.digest_size = 20
SHA1Class.block_size = 64

--- Applies the 80 SHA1 operations to the state using the given 16 words.
---
---@return integer h1
---@return integer h2
---@return integer h3
---@return integer h4
---@return integer h5
local function compress( h1, h2, h3, h4, h5, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15 )
    local a, b, c, d, e = h1, h2, h3, h4, h5

    -- constants above 0x7FFFFFFF are written as negative int32 values, this way every operand fits into int32
    -- and JIT narrows all additions that feed bit operations into plain wrapping int32 adds ( ~3x faster than doubles )
    -- the message schedule is kept in a rolling window of 16 words, `x[t % 16]` is replaced in place

    e = e + rbit_lrotate( a, 5 ) + rbit_bxor( d, rbit_band( b, rbit_bxor( c, d ) ) ) + x0 + 0x5a827999
    b = rbit_lrotate( b, 30 )
    d = d + rbit_lrotate( e, 5 ) + rbit_bxor( c, rbit_band( a, rbit_bxor( b, c ) ) ) + x1 + 0x5a827999
    a = rbit_lrotate( a, 30 )
    c = c + rbit_lrotate( d, 5 ) + rbit_bxor( b, rbit_band( e, rbit_bxor( a, b ) ) ) + x2 + 0x5a827999
    e = rbit_lrotate( e, 30 )
    b = b + rbit_lrotate( c, 5 ) + rbit_bxor( a, rbit_band( d, rbit_bxor( e, a ) ) ) + x3 + 0x5a827999
    d = rbit_lrotate( d, 30 )
    a = a + rbit_lrotate( b, 5 ) + rbit_bxor( e, rbit_band( c, rbit_bxor( d, e ) ) ) + x4 + 0x5a827999
    c = rbit_lrotate( c, 30 )
    e = e + rbit_lrotate( a, 5 ) + rbit_bxor( d, rbit_band( b, rbit_bxor( c, d ) ) ) + x5 + 0x5a827999
    b = rbit_lrotate( b, 30 )
    d = d + rbit_lrotate( e, 5 ) + rbit_bxor( c, rbit_band( a, rbit_bxor( b, c ) ) ) + x6 + 0x5a827999
    a = rbit_lrotate( a, 30 )
    c = c + rbit_lrotate( d, 5 ) + rbit_bxor( b, rbit_band( e, rbit_bxor( a, b ) ) ) + x7 + 0x5a827999
    e = rbit_lrotate( e, 30 )
    b = b + rbit_lrotate( c, 5 ) + rbit_bxor( a, rbit_band( d, rbit_bxor( e, a ) ) ) + x8 + 0x5a827999
    d = rbit_lrotate( d, 30 )
    a = a + rbit_lrotate( b, 5 ) + rbit_bxor( e, rbit_band( c, rbit_bxor( d, e ) ) ) + x9 + 0x5a827999
    c = rbit_lrotate( c, 30 )
    e = e + rbit_lrotate( a, 5 ) + rbit_bxor( d, rbit_band( b, rbit_bxor( c, d ) ) ) + x10 + 0x5a827999
    b = rbit_lrotate( b, 30 )
    d = d + rbit_lrotate( e, 5 ) + rbit_bxor( c, rbit_band( a, rbit_bxor( b, c ) ) ) + x11 + 0x5a827999
    a = rbit_lrotate( a, 30 )
    c = c + rbit_lrotate( d, 5 ) + rbit_bxor( b, rbit_band( e, rbit_bxor( a, b ) ) ) + x12 + 0x5a827999
    e = rbit_lrotate( e, 30 )
    b = b + rbit_lrotate( c, 5 ) + rbit_bxor( a, rbit_band( d, rbit_bxor( e, a ) ) ) + x13 + 0x5a827999
    d = rbit_lrotate( d, 30 )
    a = a + rbit_lrotate( b, 5 ) + rbit_bxor( e, rbit_band( c, rbit_bxor( d, e ) ) ) + x14 + 0x5a827999
    c = rbit_lrotate( c, 30 )
    e = e + rbit_lrotate( a, 5 ) + rbit_bxor( d, rbit_band( b, rbit_bxor( c, d ) ) ) + x15 + 0x5a827999
    b = rbit_lrotate( b, 30 )
    x0 = rbit_lrotate( rbit_bxor( x13, x8, x2, x0 ), 1 )
    d = d + rbit_lrotate( e, 5 ) + rbit_bxor( c, rbit_band( a, rbit_bxor( b, c ) ) ) + x0 + 0x5a827999
    a = rbit_lrotate( a, 30 )
    x1 = rbit_lrotate( rbit_bxor( x14, x9, x3, x1 ), 1 )
    c = c + rbit_lrotate( d, 5 ) + rbit_bxor( b, rbit_band( e, rbit_bxor( a, b ) ) ) + x1 + 0x5a827999
    e = rbit_lrotate( e, 30 )
    x2 = rbit_lrotate( rbit_bxor( x15, x10, x4, x2 ), 1 )
    b = b + rbit_lrotate( c, 5 ) + rbit_bxor( a, rbit_band( d, rbit_bxor( e, a ) ) ) + x2 + 0x5a827999
    d = rbit_lrotate( d, 30 )
    x3 = rbit_lrotate( rbit_bxor( x0, x11, x5, x3 ), 1 )
    a = a + rbit_lrotate( b, 5 ) + rbit_bxor( e, rbit_band( c, rbit_bxor( d, e ) ) ) + x3 + 0x5a827999
    c = rbit_lrotate( c, 30 )

    x4 = rbit_lrotate( rbit_bxor( x1, x12, x6, x4 ), 1 )
    e = e + rbit_lrotate( a, 5 ) + rbit_bxor( b, c, d ) + x4 + 0x6ed9eba1
    b = rbit_lrotate( b, 30 )
    x5 = rbit_lrotate( rbit_bxor( x2, x13, x7, x5 ), 1 )
    d = d + rbit_lrotate( e, 5 ) + rbit_bxor( a, b, c ) + x5 + 0x6ed9eba1
    a = rbit_lrotate( a, 30 )
    x6 = rbit_lrotate( rbit_bxor( x3, x14, x8, x6 ), 1 )
    c = c + rbit_lrotate( d, 5 ) + rbit_bxor( e, a, b ) + x6 + 0x6ed9eba1
    e = rbit_lrotate( e, 30 )
    x7 = rbit_lrotate( rbit_bxor( x4, x15, x9, x7 ), 1 )
    b = b + rbit_lrotate( c, 5 ) + rbit_bxor( d, e, a ) + x7 + 0x6ed9eba1
    d = rbit_lrotate( d, 30 )
    x8 = rbit_lrotate( rbit_bxor( x5, x0, x10, x8 ), 1 )
    a = a + rbit_lrotate( b, 5 ) + rbit_bxor( c, d, e ) + x8 + 0x6ed9eba1
    c = rbit_lrotate( c, 30 )
    x9 = rbit_lrotate( rbit_bxor( x6, x1, x11, x9 ), 1 )
    e = e + rbit_lrotate( a, 5 ) + rbit_bxor( b, c, d ) + x9 + 0x6ed9eba1
    b = rbit_lrotate( b, 30 )
    x10 = rbit_lrotate( rbit_bxor( x7, x2, x12, x10 ), 1 )
    d = d + rbit_lrotate( e, 5 ) + rbit_bxor( a, b, c ) + x10 + 0x6ed9eba1
    a = rbit_lrotate( a, 30 )
    x11 = rbit_lrotate( rbit_bxor( x8, x3, x13, x11 ), 1 )
    c = c + rbit_lrotate( d, 5 ) + rbit_bxor( e, a, b ) + x11 + 0x6ed9eba1
    e = rbit_lrotate( e, 30 )
    x12 = rbit_lrotate( rbit_bxor( x9, x4, x14, x12 ), 1 )
    b = b + rbit_lrotate( c, 5 ) + rbit_bxor( d, e, a ) + x12 + 0x6ed9eba1
    d = rbit_lrotate( d, 30 )
    x13 = rbit_lrotate( rbit_bxor( x10, x5, x15, x13 ), 1 )
    a = a + rbit_lrotate( b, 5 ) + rbit_bxor( c, d, e ) + x13 + 0x6ed9eba1
    c = rbit_lrotate( c, 30 )
    x14 = rbit_lrotate( rbit_bxor( x11, x6, x0, x14 ), 1 )
    e = e + rbit_lrotate( a, 5 ) + rbit_bxor( b, c, d ) + x14 + 0x6ed9eba1
    b = rbit_lrotate( b, 30 )
    x15 = rbit_lrotate( rbit_bxor( x12, x7, x1, x15 ), 1 )
    d = d + rbit_lrotate( e, 5 ) + rbit_bxor( a, b, c ) + x15 + 0x6ed9eba1
    a = rbit_lrotate( a, 30 )
    x0 = rbit_lrotate( rbit_bxor( x13, x8, x2, x0 ), 1 )
    c = c + rbit_lrotate( d, 5 ) + rbit_bxor( e, a, b ) + x0 + 0x6ed9eba1
    e = rbit_lrotate( e, 30 )
    x1 = rbit_lrotate( rbit_bxor( x14, x9, x3, x1 ), 1 )
    b = b + rbit_lrotate( c, 5 ) + rbit_bxor( d, e, a ) + x1 + 0x6ed9eba1
    d = rbit_lrotate( d, 30 )
    x2 = rbit_lrotate( rbit_bxor( x15, x10, x4, x2 ), 1 )
    a = a + rbit_lrotate( b, 5 ) + rbit_bxor( c, d, e ) + x2 + 0x6ed9eba1
    c = rbit_lrotate( c, 30 )
    x3 = rbit_lrotate( rbit_bxor( x0, x11, x5, x3 ), 1 )
    e = e + rbit_lrotate( a, 5 ) + rbit_bxor( b, c, d ) + x3 + 0x6ed9eba1
    b = rbit_lrotate( b, 30 )
    x4 = rbit_lrotate( rbit_bxor( x1, x12, x6, x4 ), 1 )
    d = d + rbit_lrotate( e, 5 ) + rbit_bxor( a, b, c ) + x4 + 0x6ed9eba1
    a = rbit_lrotate( a, 30 )
    x5 = rbit_lrotate( rbit_bxor( x2, x13, x7, x5 ), 1 )
    c = c + rbit_lrotate( d, 5 ) + rbit_bxor( e, a, b ) + x5 + 0x6ed9eba1
    e = rbit_lrotate( e, 30 )
    x6 = rbit_lrotate( rbit_bxor( x3, x14, x8, x6 ), 1 )
    b = b + rbit_lrotate( c, 5 ) + rbit_bxor( d, e, a ) + x6 + 0x6ed9eba1
    d = rbit_lrotate( d, 30 )
    x7 = rbit_lrotate( rbit_bxor( x4, x15, x9, x7 ), 1 )
    a = a + rbit_lrotate( b, 5 ) + rbit_bxor( c, d, e ) + x7 + 0x6ed9eba1
    c = rbit_lrotate( c, 30 )

    x8 = rbit_lrotate( rbit_bxor( x5, x0, x10, x8 ), 1 )
    e = e + rbit_lrotate( a, 5 ) + rbit_bor( rbit_band( b, c ), rbit_band( d, rbit_bor( b, c ) ) ) + x8 - 0x70e44324
    b = rbit_lrotate( b, 30 )
    x9 = rbit_lrotate( rbit_bxor( x6, x1, x11, x9 ), 1 )
    d = d + rbit_lrotate( e, 5 ) + rbit_bor( rbit_band( a, b ), rbit_band( c, rbit_bor( a, b ) ) ) + x9 - 0x70e44324
    a = rbit_lrotate( a, 30 )
    x10 = rbit_lrotate( rbit_bxor( x7, x2, x12, x10 ), 1 )
    c = c + rbit_lrotate( d, 5 ) + rbit_bor( rbit_band( e, a ), rbit_band( b, rbit_bor( e, a ) ) ) + x10 - 0x70e44324
    e = rbit_lrotate( e, 30 )
    x11 = rbit_lrotate( rbit_bxor( x8, x3, x13, x11 ), 1 )
    b = b + rbit_lrotate( c, 5 ) + rbit_bor( rbit_band( d, e ), rbit_band( a, rbit_bor( d, e ) ) ) + x11 - 0x70e44324
    d = rbit_lrotate( d, 30 )
    x12 = rbit_lrotate( rbit_bxor( x9, x4, x14, x12 ), 1 )
    a = a + rbit_lrotate( b, 5 ) + rbit_bor( rbit_band( c, d ), rbit_band( e, rbit_bor( c, d ) ) ) + x12 - 0x70e44324
    c = rbit_lrotate( c, 30 )
    x13 = rbit_lrotate( rbit_bxor( x10, x5, x15, x13 ), 1 )
    e = e + rbit_lrotate( a, 5 ) + rbit_bor( rbit_band( b, c ), rbit_band( d, rbit_bor( b, c ) ) ) + x13 - 0x70e44324
    b = rbit_lrotate( b, 30 )
    x14 = rbit_lrotate( rbit_bxor( x11, x6, x0, x14 ), 1 )
    d = d + rbit_lrotate( e, 5 ) + rbit_bor( rbit_band( a, b ), rbit_band( c, rbit_bor( a, b ) ) ) + x14 - 0x70e44324
    a = rbit_lrotate( a, 30 )
    x15 = rbit_lrotate( rbit_bxor( x12, x7, x1, x15 ), 1 )
    c = c + rbit_lrotate( d, 5 ) + rbit_bor( rbit_band( e, a ), rbit_band( b, rbit_bor( e, a ) ) ) + x15 - 0x70e44324
    e = rbit_lrotate( e, 30 )
    x0 = rbit_lrotate( rbit_bxor( x13, x8, x2, x0 ), 1 )
    b = b + rbit_lrotate( c, 5 ) + rbit_bor( rbit_band( d, e ), rbit_band( a, rbit_bor( d, e ) ) ) + x0 - 0x70e44324
    d = rbit_lrotate( d, 30 )
    x1 = rbit_lrotate( rbit_bxor( x14, x9, x3, x1 ), 1 )
    a = a + rbit_lrotate( b, 5 ) + rbit_bor( rbit_band( c, d ), rbit_band( e, rbit_bor( c, d ) ) ) + x1 - 0x70e44324
    c = rbit_lrotate( c, 30 )
    x2 = rbit_lrotate( rbit_bxor( x15, x10, x4, x2 ), 1 )
    e = e + rbit_lrotate( a, 5 ) + rbit_bor( rbit_band( b, c ), rbit_band( d, rbit_bor( b, c ) ) ) + x2 - 0x70e44324
    b = rbit_lrotate( b, 30 )
    x3 = rbit_lrotate( rbit_bxor( x0, x11, x5, x3 ), 1 )
    d = d + rbit_lrotate( e, 5 ) + rbit_bor( rbit_band( a, b ), rbit_band( c, rbit_bor( a, b ) ) ) + x3 - 0x70e44324
    a = rbit_lrotate( a, 30 )
    x4 = rbit_lrotate( rbit_bxor( x1, x12, x6, x4 ), 1 )
    c = c + rbit_lrotate( d, 5 ) + rbit_bor( rbit_band( e, a ), rbit_band( b, rbit_bor( e, a ) ) ) + x4 - 0x70e44324
    e = rbit_lrotate( e, 30 )
    x5 = rbit_lrotate( rbit_bxor( x2, x13, x7, x5 ), 1 )
    b = b + rbit_lrotate( c, 5 ) + rbit_bor( rbit_band( d, e ), rbit_band( a, rbit_bor( d, e ) ) ) + x5 - 0x70e44324
    d = rbit_lrotate( d, 30 )
    x6 = rbit_lrotate( rbit_bxor( x3, x14, x8, x6 ), 1 )
    a = a + rbit_lrotate( b, 5 ) + rbit_bor( rbit_band( c, d ), rbit_band( e, rbit_bor( c, d ) ) ) + x6 - 0x70e44324
    c = rbit_lrotate( c, 30 )
    x7 = rbit_lrotate( rbit_bxor( x4, x15, x9, x7 ), 1 )
    e = e + rbit_lrotate( a, 5 ) + rbit_bor( rbit_band( b, c ), rbit_band( d, rbit_bor( b, c ) ) ) + x7 - 0x70e44324
    b = rbit_lrotate( b, 30 )
    x8 = rbit_lrotate( rbit_bxor( x5, x0, x10, x8 ), 1 )
    d = d + rbit_lrotate( e, 5 ) + rbit_bor( rbit_band( a, b ), rbit_band( c, rbit_bor( a, b ) ) ) + x8 - 0x70e44324
    a = rbit_lrotate( a, 30 )
    x9 = rbit_lrotate( rbit_bxor( x6, x1, x11, x9 ), 1 )
    c = c + rbit_lrotate( d, 5 ) + rbit_bor( rbit_band( e, a ), rbit_band( b, rbit_bor( e, a ) ) ) + x9 - 0x70e44324
    e = rbit_lrotate( e, 30 )
    x10 = rbit_lrotate( rbit_bxor( x7, x2, x12, x10 ), 1 )
    b = b + rbit_lrotate( c, 5 ) + rbit_bor( rbit_band( d, e ), rbit_band( a, rbit_bor( d, e ) ) ) + x10 - 0x70e44324
    d = rbit_lrotate( d, 30 )
    x11 = rbit_lrotate( rbit_bxor( x8, x3, x13, x11 ), 1 )
    a = a + rbit_lrotate( b, 5 ) + rbit_bor( rbit_band( c, d ), rbit_band( e, rbit_bor( c, d ) ) ) + x11 - 0x70e44324
    c = rbit_lrotate( c, 30 )

    x12 = rbit_lrotate( rbit_bxor( x9, x4, x14, x12 ), 1 )
    e = e + rbit_lrotate( a, 5 ) + rbit_bxor( b, c, d ) + x12 - 0x359d3e2a
    b = rbit_lrotate( b, 30 )
    x13 = rbit_lrotate( rbit_bxor( x10, x5, x15, x13 ), 1 )
    d = d + rbit_lrotate( e, 5 ) + rbit_bxor( a, b, c ) + x13 - 0x359d3e2a
    a = rbit_lrotate( a, 30 )
    x14 = rbit_lrotate( rbit_bxor( x11, x6, x0, x14 ), 1 )
    c = c + rbit_lrotate( d, 5 ) + rbit_bxor( e, a, b ) + x14 - 0x359d3e2a
    e = rbit_lrotate( e, 30 )
    x15 = rbit_lrotate( rbit_bxor( x12, x7, x1, x15 ), 1 )
    b = b + rbit_lrotate( c, 5 ) + rbit_bxor( d, e, a ) + x15 - 0x359d3e2a
    d = rbit_lrotate( d, 30 )
    x0 = rbit_lrotate( rbit_bxor( x13, x8, x2, x0 ), 1 )
    a = a + rbit_lrotate( b, 5 ) + rbit_bxor( c, d, e ) + x0 - 0x359d3e2a
    c = rbit_lrotate( c, 30 )
    x1 = rbit_lrotate( rbit_bxor( x14, x9, x3, x1 ), 1 )
    e = e + rbit_lrotate( a, 5 ) + rbit_bxor( b, c, d ) + x1 - 0x359d3e2a
    b = rbit_lrotate( b, 30 )
    x2 = rbit_lrotate( rbit_bxor( x15, x10, x4, x2 ), 1 )
    d = d + rbit_lrotate( e, 5 ) + rbit_bxor( a, b, c ) + x2 - 0x359d3e2a
    a = rbit_lrotate( a, 30 )
    x3 = rbit_lrotate( rbit_bxor( x0, x11, x5, x3 ), 1 )
    c = c + rbit_lrotate( d, 5 ) + rbit_bxor( e, a, b ) + x3 - 0x359d3e2a
    e = rbit_lrotate( e, 30 )
    x4 = rbit_lrotate( rbit_bxor( x1, x12, x6, x4 ), 1 )
    b = b + rbit_lrotate( c, 5 ) + rbit_bxor( d, e, a ) + x4 - 0x359d3e2a
    d = rbit_lrotate( d, 30 )
    x5 = rbit_lrotate( rbit_bxor( x2, x13, x7, x5 ), 1 )
    a = a + rbit_lrotate( b, 5 ) + rbit_bxor( c, d, e ) + x5 - 0x359d3e2a
    c = rbit_lrotate( c, 30 )
    x6 = rbit_lrotate( rbit_bxor( x3, x14, x8, x6 ), 1 )
    e = e + rbit_lrotate( a, 5 ) + rbit_bxor( b, c, d ) + x6 - 0x359d3e2a
    b = rbit_lrotate( b, 30 )
    x7 = rbit_lrotate( rbit_bxor( x4, x15, x9, x7 ), 1 )
    d = d + rbit_lrotate( e, 5 ) + rbit_bxor( a, b, c ) + x7 - 0x359d3e2a
    a = rbit_lrotate( a, 30 )
    x8 = rbit_lrotate( rbit_bxor( x5, x0, x10, x8 ), 1 )
    c = c + rbit_lrotate( d, 5 ) + rbit_bxor( e, a, b ) + x8 - 0x359d3e2a
    e = rbit_lrotate( e, 30 )
    x9 = rbit_lrotate( rbit_bxor( x6, x1, x11, x9 ), 1 )
    b = b + rbit_lrotate( c, 5 ) + rbit_bxor( d, e, a ) + x9 - 0x359d3e2a
    d = rbit_lrotate( d, 30 )
    x10 = rbit_lrotate( rbit_bxor( x7, x2, x12, x10 ), 1 )
    a = a + rbit_lrotate( b, 5 ) + rbit_bxor( c, d, e ) + x10 - 0x359d3e2a
    c = rbit_lrotate( c, 30 )
    x11 = rbit_lrotate( rbit_bxor( x8, x3, x13, x11 ), 1 )
    e = e + rbit_lrotate( a, 5 ) + rbit_bxor( b, c, d ) + x11 - 0x359d3e2a
    b = rbit_lrotate( b, 30 )
    x12 = rbit_lrotate( rbit_bxor( x9, x4, x14, x12 ), 1 )
    d = d + rbit_lrotate( e, 5 ) + rbit_bxor( a, b, c ) + x12 - 0x359d3e2a
    a = rbit_lrotate( a, 30 )
    x13 = rbit_lrotate( rbit_bxor( x10, x5, x15, x13 ), 1 )
    c = c + rbit_lrotate( d, 5 ) + rbit_bxor( e, a, b ) + x13 - 0x359d3e2a
    e = rbit_lrotate( e, 30 )
    x14 = rbit_lrotate( rbit_bxor( x11, x6, x0, x14 ), 1 )
    b = b + rbit_lrotate( c, 5 ) + rbit_bxor( d, e, a ) + x14 - 0x359d3e2a
    d = rbit_lrotate( d, 30 )
    x15 = rbit_lrotate( rbit_bxor( x12, x7, x1, x15 ), 1 )
    a = a + rbit_lrotate( b, 5 ) + rbit_bxor( c, d, e ) + x15 - 0x359d3e2a
    c = rbit_lrotate( c, 30 )

    return rbit_tobit( h1 + a ), rbit_tobit( h2 + b ), rbit_tobit( h3 + c ), rbit_tobit( h4 + d ), rbit_tobit( h5 + e )
end

--- Processes a single 64-byte block.
---
---@type fun( str: string, offset: integer, h1: integer, h2: integer, h3: integer, h4: integer, h5: integer ): integer, integer, integer, integer, integer
local transform

if ffi == nil then

    ---@param str string
    ---@param offset integer The 0-based byte offset of the block.
    function transform( str, offset, h1, h2, h3, h4, h5 )
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
        return compress( h1, h2, h3, h4, h5, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15 )
    end

else

    local ffi_cast = ffi.cast

    local uint8_ptr_t = ffi.typeof( "const uint8_t *" )
    local int32_ptr_t = ffi.typeof( "const int32_t *" )

    if ffi.abi( "le" ) then

        -- words are big endian, so on little endian systems they are byte-swapped after reading
        ---@param str string
        ---@param offset integer The 0-based byte offset of the block.
        function transform( str, offset, h1, h2, h3, h4, h5 )
            local x = ffi_cast( int32_ptr_t, ffi_cast( uint8_ptr_t, str ) + offset )
            return compress( h1, h2, h3, h4, h5,
                rbit_bswap( x[ 0 ] ), rbit_bswap( x[ 1 ] ), rbit_bswap( x[ 2 ] ), rbit_bswap( x[ 3 ] ),
                rbit_bswap( x[ 4 ] ), rbit_bswap( x[ 5 ] ), rbit_bswap( x[ 6 ] ), rbit_bswap( x[ 7 ] ),
                rbit_bswap( x[ 8 ] ), rbit_bswap( x[ 9 ] ), rbit_bswap( x[ 10 ] ), rbit_bswap( x[ 11 ] ),
                rbit_bswap( x[ 12 ] ), rbit_bswap( x[ 13 ] ), rbit_bswap( x[ 14 ] ), rbit_bswap( x[ 15 ] )
            )
        end

    else

        ---@param str string
        ---@param offset integer The 0-based byte offset of the block.
        function transform( str, offset, h1, h2, h3, h4, h5 )
            local x = ffi_cast( int32_ptr_t, ffi_cast( uint8_ptr_t, str ) + offset )
            return compress( h1, h2, h3, h4, h5,
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
local function process( str, offset, str_length, h1, h2, h3, h4, h5 )
    local last_offset = str_length - 64

    while offset <= last_offset do
        h1, h2, h3, h4, h5 = transform( str, offset, h1, h2, h3, h4, h5 )
        offset = offset + 64
    end

    return offset, h1, h2, h3, h4, h5
end

--- Pads the tail of the message, processes the final block(s) and returns the digest.
---
---@param tail string The unprocessed tail of the message, less than 64 bytes.
---@param message_length integer The total length of the message in bytes.
---@param as_hex? boolean
---@return string
local function finalize( tail, message_length, h1, h2, h3, h4, h5, as_hex )
    local bit_count_low = (message_length % 0x20000000) * 8
    local bit_count_high = math_floor( message_length / 0x20000000 )

    local block = tail .. "\128" .. string_rep( "\0", (55 - string_len( tail )) % 64 ) .. string_char(
        rbit_rshift( bit_count_high, 24 ), rbit_band( rbit_rshift( bit_count_high, 16 ), 0xFF ), rbit_band( rbit_rshift( bit_count_high, 8 ), 0xFF ), rbit_band( bit_count_high, 0xFF ),
        rbit_rshift( bit_count_low, 24 ), rbit_band( rbit_rshift( bit_count_low, 16 ), 0xFF ), rbit_band( rbit_rshift( bit_count_low, 8 ), 0xFF ), rbit_band( bit_count_low, 0xFF )
    )

    h1, h2, h3, h4, h5 = transform( block, 0, h1, h2, h3, h4, h5 )

    if string_len( block ) == 128 then
        h1, h2, h3, h4, h5 = transform( block, 64, h1, h2, h3, h4, h5 )
    end

    if as_hex then
        return string_format( "%08x%08x%08x%08x%08x",
            h1 % 0x100000000,
            h2 % 0x100000000,
            h3 % 0x100000000,
            h4 % 0x100000000,
            h5 % 0x100000000
        )
    end

    return string_char(
        rbit_rshift( h1, 24 ), rbit_band( rbit_rshift( h1, 16 ), 0xFF ), rbit_band( rbit_rshift( h1, 8 ), 0xFF ), rbit_band( h1, 0xFF ),
        rbit_rshift( h2, 24 ), rbit_band( rbit_rshift( h2, 16 ), 0xFF ), rbit_band( rbit_rshift( h2, 8 ), 0xFF ), rbit_band( h2, 0xFF ),
        rbit_rshift( h3, 24 ), rbit_band( rbit_rshift( h3, 16 ), 0xFF ), rbit_band( rbit_rshift( h3, 8 ), 0xFF ), rbit_band( h3, 0xFF ),
        rbit_rshift( h4, 24 ), rbit_band( rbit_rshift( h4, 16 ), 0xFF ), rbit_band( rbit_rshift( h4, 8 ), 0xFF ), rbit_band( h4, 0xFF ),
        rbit_rshift( h5, 24 ), rbit_band( rbit_rshift( h5, 16 ), 0xFF ), rbit_band( rbit_rshift( h5, 8 ), 0xFF ), rbit_band( h5, 0xFF )
    )
end

--- [SHARED AND MENU]
---
--- Resets the SHA1 object to its initial state.
---
--- This instance method resets the SHA1 object to its initial state.
---
--- It returns the SHA1 object for method chaining.
---
---@return dreamwork.std.crypto.SHA1 obj The reset SHA1 object.
function SHA1:reset()
    self.h1, self.h2, self.h3, self.h4, self.h5 = 0x67452301, -0x10325477, -0x67452302, 0x10325476, -0x3c2d1e10

    self.message_length = 0
    self.buffer = ""

    return self
end

SHA1.__init = SHA1.reset

---@return string
---@protected
function SHA1:__represent()
    return string_format( "%s: %p [%d]", type( self ), self, self.message_length )
end

--- [SHARED AND MENU]
---
--- Updates the SHA1 object with the given string.
---
--- This instance method updates the SHA1 object with the given string.
---
--- It returns the SHA1 object for method chaining.
---
---@param str string The string to update the SHA1 object with.
---@return dreamwork.std.crypto.SHA1 obj The updated SHA1 object.
function SHA1:update( str )
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

    local h1, h2, h3, h4, h5 = self.h1, self.h2, self.h3, self.h4, self.h5
    local offset = 0

    -- complete the buffered block without copying the whole string
    if required ~= 64 then
        h1, h2, h3, h4, h5 = transform( buffer .. string_sub( str, 1, required ), 0, h1, h2, h3, h4, h5 )
        offset = required
    end

    offset, h1, h2, h3, h4, h5 = process( str, offset, str_length, h1, h2, h3, h4, h5 )

    self.h1, self.h2, self.h3, self.h4, self.h5 = h1, h2, h3, h4, h5
    self.buffer = string_sub( str, offset + 1 )

    return self
end

--- [SHARED AND MENU]
---
--- Calculates the SHA1 digest based on the current state or input of the object.
---
--- This instance method returns the SHA1 hash of the data associated with the object.
--- Useful when the SHA1 object has been incrementally updated with input data.
---
--- Does not change the state, so the object can be updated further.
---
---@param as_hex? boolean If true, the result will be a hex string.
---@return string str_result The SHA1 string of the message.
---@nodiscard
function SHA1:digest( as_hex )
    return finalize( self.buffer, self.message_length, self.h1, self.h2, self.h3, self.h4, self.h5, as_hex )
end

SHA1.__tostring = SHA1.digest

if util == nil or util.SHA1 == nil then

    --- [SHARED AND MENU]
    ---
    --- Computes the SHA1 digest of the given input string.
    ---
    --- This static method takes a string and returns its SHA1 hash as a hexadecimal string.
    --- Commonly used for checksums, data integrity validation, and password hashing.
    ---
    ---@param message string The message to compute SHA1 for.
    ---@param as_hex? boolean If true, the result will be a hex string.
    ---@return string str_result The SHA1 string of the message.
    ---@nodiscard
    function SHA1Class.digest( message, as_hex )
        local message_length = string_len( message )
        local offset, h1, h2, h3, h4, h5 = process( message, 0, message_length, 0x67452301, -0x10325477, -0x67452302, 0x10325476, -0x3c2d1e10 )
        return finalize( string_sub( message, offset + 1 ), message_length, h1, h2, h3, h4, h5, as_hex )
    end

else

    local base16_decode = std.base16.decode
    local util_SHA1 = util.SHA1

    --- [SHARED AND MENU]
    ---
    --- Computes the SHA1 digest of the given input string.
    ---
    --- This static method takes a string and returns its SHA1 hash as a hexadecimal string.
    --- Commonly used for checksums, data integrity validation, and password hashing.
    ---
    ---@param message string The message to compute SHA1 for.
    ---@param as_hex? boolean If true, the result will be a hex string.
    ---@return string str_result The SHA1 string of the message.
    ---@nodiscard
    function SHA1Class.digest( message, as_hex )
        local hex_str = util_SHA1( message )
        if as_hex then
            return hex_str
        end

        return base16_decode( hex_str )
    end

end
