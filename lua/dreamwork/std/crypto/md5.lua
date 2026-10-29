local std = dreamwork.std
local ffi = std.ffi

---@class dreamwork.std.crypto
local crypto = std.crypto

local class = std.class

local rbit = std.raw.bit
local rbit_bnot = rbit.bnot
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
--- MD5 object.
---
---@class dreamwork.std.crypto.MD5 : dreamwork.std.Object
---@field __class dreamwork.std.crypto.MD5Class
---@field protected a integer The first word of the hash state ( int32 ).
---@field protected b integer The second word of the hash state ( int32 ).
---@field protected c integer The third word of the hash state ( int32 ).
---@field protected d integer The fourth word of the hash state ( int32 ).
---@field protected message_length integer The total length of the message in bytes.
---@field protected buffer string The unprocessed tail of the message, less than 64 bytes.
local MD5 = class.base( "MD5" )

--- [SHARED AND MENU]
---
--- The class used to create new `MD5` hash calculation instances.
---
--- Computes a cryptographic 128-bit hash value.
---
--- Like other hash classes, it takes input data ( string ) and
--- produces a digest ( string ) — a fixed-size output string that
--- represents that data.
---
--- **MD5 is insecure**
---
--- Because of collision attacks,
--- attackers can find two different inputs
--- that produce the same hash.
---
--- This violates one of the basic principles
--- of a secure hash function - collision resistance.
---
---@class dreamwork.std.crypto.MD5Class : dreamwork.std.crypto.MD5, dreamwork.std.crypto.HashClass
---@field __base dreamwork.std.crypto.MD5
---@field digest fun( message: string, as_hex?: boolean ): string
---@field digest_size integer
---@field block_size integer
---@operator call: dreamwork.std.crypto.MD5
local MD5Class = class.create( MD5 )
crypto.MD5 = MD5Class

MD5Class.digest_size = 16
MD5Class.block_size = 64

--- Applies the 64 MD5 operations to the state using the given 16 words.
---
---@return integer a
---@return integer b
---@return integer c
---@return integer d
local function compress( a, b, c, d, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15 )
    local in_a, in_b, in_c, in_d = a, b, c, d

    -- constants above 0x7FFFFFFF are written as negative int32 values, this way every operand fits into int32
    -- and JIT narrows all additions that feed bit operations into plain wrapping int32 adds ( ~3x faster than doubles )
    -- no normalization between the steps is needed, in the interpreter values grow by at most 2^32 per step,
    -- so they stay exact in doubles and `rbit_lrotate` reduces them to 32 bits anyway

    a = rbit_lrotate( a + rbit_bxor( d, rbit_band( b, rbit_bxor( c, d ) ) ) + x0 - 0x28955b88, 7 ) + b
    d = rbit_lrotate( d + rbit_bxor( c, rbit_band( a, rbit_bxor( b, c ) ) ) + x1 - 0x173848aa, 12 ) + a
    c = rbit_lrotate( c + rbit_bxor( b, rbit_band( d, rbit_bxor( a, b ) ) ) + x2 + 606105819, 17 ) + d
    b = rbit_lrotate( b + rbit_bxor( a, rbit_band( c, rbit_bxor( d, a ) ) ) + x3 - 0x3e423112, 22 ) + c
    a = rbit_lrotate( a + rbit_bxor( d, rbit_band( b, rbit_bxor( c, d ) ) ) + x4 - 0x0a83f051, 7 ) + b
    d = rbit_lrotate( d + rbit_bxor( c, rbit_band( a, rbit_bxor( b, c ) ) ) + x5 + 1200080426, 12 ) + a
    c = rbit_lrotate( c + rbit_bxor( b, rbit_band( d, rbit_bxor( a, b ) ) ) + x6 - 0x57cfb9ed, 17 ) + d
    b = rbit_lrotate( b + rbit_bxor( a, rbit_band( c, rbit_bxor( d, a ) ) ) + x7 - 0x02b96aff, 22 ) + c
    a = rbit_lrotate( a + rbit_bxor( d, rbit_band( b, rbit_bxor( c, d ) ) ) + x8 + 1770035416, 7 ) + b
    d = rbit_lrotate( d + rbit_bxor( c, rbit_band( a, rbit_bxor( b, c ) ) ) + x9 - 0x74bb0851, 12 ) + a
    c = rbit_lrotate( c + rbit_bxor( b, rbit_band( d, rbit_bxor( a, b ) ) ) + x10 - 0x0000a44f, 17 ) + d
    b = rbit_lrotate( b + rbit_bxor( a, rbit_band( c, rbit_bxor( d, a ) ) ) + x11 - 0x76a32842, 22 ) + c
    a = rbit_lrotate( a + rbit_bxor( d, rbit_band( b, rbit_bxor( c, d ) ) ) + x12 + 1804603682, 7 ) + b
    d = rbit_lrotate( d + rbit_bxor( c, rbit_band( a, rbit_bxor( b, c ) ) ) + x13 - 0x02678e6d, 12 ) + a
    c = rbit_lrotate( c + rbit_bxor( b, rbit_band( d, rbit_bxor( a, b ) ) ) + x14 - 0x5986bc72, 17 ) + d
    b = rbit_lrotate( b + rbit_bxor( a, rbit_band( c, rbit_bxor( d, a ) ) ) + x15 + 1236535329, 22 ) + c

    a = rbit_lrotate( a + rbit_bxor( c, rbit_band( d, rbit_bxor( b, c ) ) ) + x1 - 0x09e1da9e, 5 ) + b
    d = rbit_lrotate( d + rbit_bxor( b, rbit_band( c, rbit_bxor( a, b ) ) ) + x6 - 0x3fbf4cc0, 9 ) + a
    c = rbit_lrotate( c + rbit_bxor( a, rbit_band( b, rbit_bxor( d, a ) ) ) + x11 + 643717713, 14 ) + d
    b = rbit_lrotate( b + rbit_bxor( d, rbit_band( a, rbit_bxor( c, d ) ) ) + x0 - 0x16493856, 20 ) + c
    a = rbit_lrotate( a + rbit_bxor( c, rbit_band( d, rbit_bxor( b, c ) ) ) + x5 - 0x29d0efa3, 5 ) + b
    d = rbit_lrotate( d + rbit_bxor( b, rbit_band( c, rbit_bxor( a, b ) ) ) + x10 + 38016083, 9 ) + a
    c = rbit_lrotate( c + rbit_bxor( a, rbit_band( b, rbit_bxor( d, a ) ) ) + x15 - 0x275e197f, 14 ) + d
    b = rbit_lrotate( b + rbit_bxor( d, rbit_band( a, rbit_bxor( c, d ) ) ) + x4 - 0x182c0438, 20 ) + c
    a = rbit_lrotate( a + rbit_bxor( c, rbit_band( d, rbit_bxor( b, c ) ) ) + x9 + 568446438, 5 ) + b
    d = rbit_lrotate( d + rbit_bxor( b, rbit_band( c, rbit_bxor( a, b ) ) ) + x14 - 0x3cc8f82a, 9 ) + a
    c = rbit_lrotate( c + rbit_bxor( a, rbit_band( b, rbit_bxor( d, a ) ) ) + x3 - 0x0b2af279, 14 ) + d
    b = rbit_lrotate( b + rbit_bxor( d, rbit_band( a, rbit_bxor( c, d ) ) ) + x8 + 1163531501, 20 ) + c
    a = rbit_lrotate( a + rbit_bxor( c, rbit_band( d, rbit_bxor( b, c ) ) ) + x13 - 0x561c16fb, 5 ) + b
    d = rbit_lrotate( d + rbit_bxor( b, rbit_band( c, rbit_bxor( a, b ) ) ) + x2 - 0x03105c08, 9 ) + a
    c = rbit_lrotate( c + rbit_bxor( a, rbit_band( b, rbit_bxor( d, a ) ) ) + x7 + 1735328473, 14 ) + d
    b = rbit_lrotate( b + rbit_bxor( d, rbit_band( a, rbit_bxor( c, d ) ) ) + x12 - 0x72d5b376, 20 ) + c

    a = rbit_lrotate( a + rbit_bxor( b, c, d ) + x5 - 0x0005c6be, 4 ) + b
    d = rbit_lrotate( d + rbit_bxor( a, b, c ) + x8 - 0x788e097f, 11 ) + a
    c = rbit_lrotate( c + rbit_bxor( d, a, b ) + x11 + 1839030562, 16 ) + d
    b = rbit_lrotate( b + rbit_bxor( c, d, a ) + x14 - 0x021ac7f4, 23 ) + c
    a = rbit_lrotate( a + rbit_bxor( b, c, d ) + x1 - 0x5b4115bc, 4 ) + b
    d = rbit_lrotate( d + rbit_bxor( a, b, c ) + x4 + 1272893353, 11 ) + a
    c = rbit_lrotate( c + rbit_bxor( d, a, b ) + x7 - 0x0944b4a0, 16 ) + d
    b = rbit_lrotate( b + rbit_bxor( c, d, a ) + x10 - 0x41404390, 23 ) + c
    a = rbit_lrotate( a + rbit_bxor( b, c, d ) + x13 + 681279174, 4 ) + b
    d = rbit_lrotate( d + rbit_bxor( a, b, c ) + x0 - 0x155ed806, 11 ) + a
    c = rbit_lrotate( c + rbit_bxor( d, a, b ) + x3 - 0x2b10cf7b, 16 ) + d
    b = rbit_lrotate( b + rbit_bxor( c, d, a ) + x6 + 76029189, 23 ) + c
    a = rbit_lrotate( a + rbit_bxor( b, c, d ) + x9 - 0x262b2fc7, 4 ) + b
    d = rbit_lrotate( d + rbit_bxor( a, b, c ) + x12 - 0x1924661b, 11 ) + a
    c = rbit_lrotate( c + rbit_bxor( d, a, b ) + x15 + 530742520, 16 ) + d
    b = rbit_lrotate( b + rbit_bxor( c, d, a ) + x2 - 0x3b53a99b, 23 ) + c

    a = rbit_lrotate( a + rbit_bxor( c, rbit_bor( b, rbit_bnot( d ) ) ) + x0 - 0x0bd6ddbc, 6 ) + b
    d = rbit_lrotate( d + rbit_bxor( b, rbit_bor( a, rbit_bnot( c ) ) ) + x7 + 1126891415, 10 ) + a
    c = rbit_lrotate( c + rbit_bxor( a, rbit_bor( d, rbit_bnot( b ) ) ) + x14 - 0x546bdc59, 15 ) + d
    b = rbit_lrotate( b + rbit_bxor( d, rbit_bor( c, rbit_bnot( a ) ) ) + x5 - 0x036c5fc7, 21 ) + c
    a = rbit_lrotate( a + rbit_bxor( c, rbit_bor( b, rbit_bnot( d ) ) ) + x12 + 1700485571, 6 ) + b
    d = rbit_lrotate( d + rbit_bxor( b, rbit_bor( a, rbit_bnot( c ) ) ) + x3 - 0x70f3336e, 10 ) + a
    c = rbit_lrotate( c + rbit_bxor( a, rbit_bor( d, rbit_bnot( b ) ) ) + x10 - 0x00100b83, 15 ) + d
    b = rbit_lrotate( b + rbit_bxor( d, rbit_bor( c, rbit_bnot( a ) ) ) + x1 - 0x7a7ba22f, 21 ) + c
    a = rbit_lrotate( a + rbit_bxor( c, rbit_bor( b, rbit_bnot( d ) ) ) + x8 + 1873313359, 6 ) + b
    d = rbit_lrotate( d + rbit_bxor( b, rbit_bor( a, rbit_bnot( c ) ) ) + x15 - 0x01d31920, 10 ) + a
    c = rbit_lrotate( c + rbit_bxor( a, rbit_bor( d, rbit_bnot( b ) ) ) + x6 - 0x5cfebcec, 15 ) + d
    b = rbit_lrotate( b + rbit_bxor( d, rbit_bor( c, rbit_bnot( a ) ) ) + x13 + 1309151649, 21 ) + c
    a = rbit_lrotate( a + rbit_bxor( c, rbit_bor( b, rbit_bnot( d ) ) ) + x4 - 0x08ac817e, 6 ) + b
    d = rbit_lrotate( d + rbit_bxor( b, rbit_bor( a, rbit_bnot( c ) ) ) + x11 - 0x42c50dcb, 10 ) + a
    c = rbit_lrotate( c + rbit_bxor( a, rbit_bor( d, rbit_bnot( b ) ) ) + x2 + 718787259, 15 ) + d
    b = rbit_lrotate( b + rbit_bxor( d, rbit_bor( c, rbit_bnot( a ) ) ) + x9 - 0x14792c6f, 21 ) + c

    return rbit_tobit( in_a + a ), rbit_tobit( in_b + b ), rbit_tobit( in_c + c ), rbit_tobit( in_d + d )
end

--- Processes a single 64-byte block.
---
---@type fun( str: string, offset: integer, a: integer, b: integer, c: integer, d: integer ): integer, integer, integer, integer
local transform

if ffi == nil or not ffi.abi( "le" ) then

    ---@param str string
    ---@param offset integer The 0-based byte offset of the block.
    function transform( str, offset, a, b, c, d )
        -- every word is built right after its bytes are read, otherwise 64 live bytes run JIT out of spill slots
        local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 1, offset + 4 )
        local x0 = rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 5, offset + 8 )
        local x1 = rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 9, offset + 12 )
        local x2 = rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 13, offset + 16 )
        local x3 = rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 17, offset + 20 )
        local x4 = rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 21, offset + 24 )
        local x5 = rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 25, offset + 28 )
        local x6 = rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 29, offset + 32 )
        local x7 = rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 33, offset + 36 )
        local x8 = rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 37, offset + 40 )
        local x9 = rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 41, offset + 44 )
        local x10 = rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 45, offset + 48 )
        local x11 = rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 49, offset + 52 )
        local x12 = rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 53, offset + 56 )
        local x13 = rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 57, offset + 60 )
        local x14 = rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 61, offset + 64 )
        local x15 = rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) )
        return compress( a, b, c, d, x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15 )
    end

else

    local ffi_cast = ffi.cast

    local uint8_ptr_t = ffi.typeof( "const uint8_t *" )
    local int32_ptr_t = ffi.typeof( "const int32_t *" )

    -- little endian only, so words can be read directly from the string memory
    ---@param str string
    ---@param offset integer The 0-based byte offset of the block.
    function transform( str, offset, a, b, c, d )
        local x = ffi_cast( int32_ptr_t, ffi_cast( uint8_ptr_t, str ) + offset )
        return compress( a, b, c, d,
            x[ 0 ], x[ 1 ], x[ 2 ], x[ 3 ], x[ 4 ], x[ 5 ], x[ 6 ], x[ 7 ],
            x[ 8 ], x[ 9 ], x[ 10 ], x[ 11 ], x[ 12 ], x[ 13 ], x[ 14 ], x[ 15 ]
        )
    end

end

--- Processes all complete 64-byte blocks of the string starting from the given offset.
---
---@param str string
---@param offset integer The 0-based byte offset.
---@param str_length integer
---@return integer offset The offset of the first unprocessed byte.
---@return integer a
---@return integer b
---@return integer c
---@return integer d
local function process( str, offset, str_length, a, b, c, d )
    local last_offset = str_length - 64

    while offset <= last_offset do
        a, b, c, d = transform( str, offset, a, b, c, d )
        offset = offset + 64
    end

    return offset, a, b, c, d
end

--- Pads the tail of the message, processes the final block(s) and returns the digest.
---
---@param tail string The unprocessed tail of the message, less than 64 bytes.
---@param message_length integer The total length of the message in bytes.
---@param as_hex? boolean
---@return string
local function finalize( tail, message_length, a, b, c, d, as_hex )
    local rbit_count_low = (message_length % 0x20000000) * 8
    local rbit_count_high = math_floor( message_length / 0x20000000 )

    local block = tail .. "\128" .. string_rep( "\0", (55 - string_len( tail )) % 64 ) .. string_char(
        rbit_band( rbit_count_low, 0xFF ), rbit_band( rbit_rshift( rbit_count_low, 8 ), 0xFF ), rbit_band( rbit_rshift( rbit_count_low, 16 ), 0xFF ), rbit_rshift( rbit_count_low, 24 ),
        rbit_band( rbit_count_high, 0xFF ), rbit_band( rbit_rshift( rbit_count_high, 8 ), 0xFF ), rbit_band( rbit_rshift( rbit_count_high, 16 ), 0xFF ), rbit_rshift( rbit_count_high, 24 )
    )

    a, b, c, d = transform( block, 0, a, b, c, d )

    if string_len( block ) == 128 then
        a, b, c, d = transform( block, 64, a, b, c, d )
    end

    if as_hex then
        return string_format( "%08x%08x%08x%08x",
            rbit_bswap( a ) % 0x100000000,
            rbit_bswap( b ) % 0x100000000,
            rbit_bswap( c ) % 0x100000000,
            rbit_bswap( d ) % 0x100000000
        )
    end

    return string_char(
        rbit_band( a, 0xFF ), rbit_band( rbit_rshift( a, 8 ), 0xFF ), rbit_band( rbit_rshift( a, 16 ), 0xFF ), rbit_rshift( a, 24 ),
        rbit_band( b, 0xFF ), rbit_band( rbit_rshift( b, 8 ), 0xFF ), rbit_band( rbit_rshift( b, 16 ), 0xFF ), rbit_rshift( b, 24 ),
        rbit_band( c, 0xFF ), rbit_band( rbit_rshift( c, 8 ), 0xFF ), rbit_band( rbit_rshift( c, 16 ), 0xFF ), rbit_rshift( c, 24 ),
        rbit_band( d, 0xFF ), rbit_band( rbit_rshift( d, 8 ), 0xFF ), rbit_band( rbit_rshift( d, 16 ), 0xFF ), rbit_rshift( d, 24 )
    )
end

--- [SHARED AND MENU]
---
--- Resets the MD5 object to its initial state.
---
--- This instance method resets the MD5 object to its initial state.
---
--- It returns the MD5 object for method chaining.
---
---@return dreamwork.std.crypto.MD5 obj The reset MD5 object.
function MD5:reset()
    self.a, self.b, self.c, self.d = 0x67452301, -0x10325477, -0x67452302, 0x10325476

    self.message_length = 0
    self.buffer = ""

    return self
end

MD5.__init = MD5.reset

---@return string
---@protected
function MD5:__represent()
    return string_format( "%s: %p [%d]", type( self ), self, self.message_length )
end

--- [SHARED AND MENU]
---
--- Updates the MD5 object with the given string.
---
--- This instance method updates the MD5 object with the given string.
---
--- It returns the MD5 object for method chaining.
---
---@param str string The string to update the MD5 object with.
---@return dreamwork.std.crypto.MD5 obj The updated MD5 object.
function MD5:update( str )
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

    local a, b, c, d = self.a, self.b, self.c, self.d
    local offset = 0

    -- complete the buffered block without copying the whole string
    if required ~= 64 then
        a, b, c, d = transform( buffer .. string_sub( str, 1, required ), 0, a, b, c, d )
        offset = required
    end

    offset, a, b, c, d = process( str, offset, str_length, a, b, c, d )

    self.a, self.b, self.c, self.d = a, b, c, d
    self.buffer = string_sub( str, offset + 1 )

    return self
end

--- [SHARED AND MENU]
---
--- Calculates the MD5 digest based on the current state or input of the object.
---
--- This instance method returns the MD5 hash of the data associated with the object.
--- Useful when the MD5 object has been incrementally updated with input data.
---
--- Does not change the state, so the object can be updated further.
---
---@param as_hex? boolean If true, the result will be a hex string.
---@return string str_result The MD5 string of the message.
---@nodiscard
function MD5:digest( as_hex )
    return finalize( self.buffer, self.message_length, self.a, self.b, self.c, self.d, as_hex )
end

MD5.__tostring = MD5.digest

if util == nil or util.MD5 == nil then

    --- [SHARED AND MENU]
    ---
    --- Computes the MD5 digest of the given input string.
    ---
    --- This static method takes a string and returns its MD5 hash as a hexadecimal string.
    --- Commonly used for checksums, data integrity validation, and password hashing.
    ---
    ---@param message string The message to compute MD5 for.
    ---@param as_hex? boolean If true, the result will be a hex string.
    ---@return string str_result The MD5 string of the message.
    ---@nodiscard
    function MD5Class.digest( message, as_hex )
        local message_length = string_len( message )
        local offset, a, b, c, d = process( message, 0, message_length, 0x67452301, -0x10325477, -0x67452302, 0x10325476 )
        return finalize( string_sub( message, offset + 1 ), message_length, a, b, c, d, as_hex )
    end

else

    local base16_decode = std.base16.decode
    local util_MD5 = util.MD5

    --- [SHARED AND MENU]
    ---
    --- Computes the MD5 digest of the given input string.
    ---
    --- This static method takes a string and returns its MD5 hash as a hexadecimal string.
    --- Commonly used for checksums, data integrity validation, and password hashing.
    ---
    ---@param message string The message to compute MD5 for.
    ---@param as_hex? boolean If true, the result will be a hex string.
    ---@return string str_result The MD5 string of the message.
    ---@nodiscard
    function MD5Class.digest( message, as_hex )
        local hex_str = util_MD5( message )
        if as_hex then
            return hex_str
        end

        return base16_decode( hex_str )
    end

end
