local util_CRC

if util ~= nil then
    util_CRC = util.CRC
end

---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_tonumber = raw.tonumber

local rbit = raw.bit
local rbit_bxor = rbit.bxor
local rbit_reverse = rbit.reverse
local rbit_band, rbit_bor = rbit.band, rbit.bor
local rbit_lshift, rbit_rshift = rbit.lshift, rbit.rshift

local string = std.string
local string_len = string.len
local string_byte = string.byte

local class = std.class

---@type table<integer, integer>
local reverse8 = {}

for uint8 = 0, 255, 1 do
    reverse8[ uint8 ] = rbit_reverse( uint8, 0x08 )
end

---@param uint16 integer
---@return integer
local function reverse16( uint16 )
    return rbit_bor(
        rbit_lshift( reverse8[ rbit_band( uint16, 0xFF ) ], 8 ),
        reverse8[ rbit_band( rbit_rshift( uint16, 8 ), 0xFF ) ]
    )
end

---@param uint32 integer
---@return integer
local function reverse32( uint32 )
    return rbit_bor(
        rbit_lshift( reverse8[ rbit_band( uint32, 0xFF ) ], 24 ),
        rbit_lshift( reverse8[ rbit_band( rbit_rshift( uint32, 8 ), 0xFF ) ], 16 ),
        rbit_lshift( reverse8[ rbit_band( rbit_rshift( uint32, 16 ), 0xFF ) ], 8 ),
        reverse8[ rbit_rshift( uint32, 24 ) ]
    )
end

---@alias dreamwork.std.checksum.CRCTables table<integer, table<integer, integer>>

local tables_new
do

    ---@type table<integer, table<integer, dreamwork.std.checksum.CRCTables>>
    local normal_cache = { [ 8 ] = {}, [ 16 ] = {}, [ 32 ] = {} }

    ---@type table<integer, table<integer, dreamwork.std.checksum.CRCTables>>
    local reflected_cache = { [ 8 ] = {}, [ 16 ] = {}, [ 32 ] = {} }

    --- Returns the 8 lookup tables used to process 8 bytes per step ( slicing-by-8 ).
    ---
    --- `tables[ k ][ i ]` is the register after feeding byte `i` followed by `k` zero bytes.
    ---
    ---@param width integer The CRC width in bits: 8, 16 or 32.
    ---@param poly integer The polynomial.
    ---@param ref_in boolean `true` to build reflected ( LSB-first ) tables.
    ---@return dreamwork.std.checksum.CRCTables tables
    function tables_new( width, poly, ref_in )
        local cache = (ref_in and reflected_cache or normal_cache)[ width ]

        local tables = cache[ poly ]
        if tables ~= nil then
            return tables
        end

        ---@type table<integer, integer>
        local t0 = {}

        if ref_in then
            local reflected_poly = rbit_reverse( poly, width )

            for i = 0, 255, 1 do
                local value = i

                for _ = 1, 8, 1 do
                    if rbit_band( value, 1 ) == 0 then
                        value = rbit_rshift( value, 1 )
                    else
                        value = rbit_bxor( rbit_rshift( value, 1 ), reflected_poly )
                    end
                end

                t0[ i ] = value
            end
        else
            local shift = width - 8
            local top = rbit_lshift( 1, width - 1 )
            local mask = width == 32 and -1 or (rbit_lshift( 1, width ) - 1)

            for i = 0, 255, 1 do
                local value = rbit_lshift( i, shift )

                for _ = 1, 8, 1 do
                    if rbit_band( value, top ) == 0 then
                        value = rbit_lshift( value, 1 )
                    else
                        value = rbit_bxor( rbit_lshift( value, 1 ), poly )
                    end
                end

                t0[ i ] = rbit_band( value, mask )
            end
        end

        tables = { [ 0 ] = t0 }

        for k = 1, 7, 1 do
            local previous, current = tables[ k - 1 ], {}

            if ref_in then
                for i = 0, 255, 1 do
                    local value = previous[ i ]
                    current[ i ] = rbit_bxor( rbit_rshift( value, 8 ), t0[ rbit_band( value, 0xFF ) ] )
                end
            else
                local shift = width - 8
                local mask = width == 32 and -1 or (rbit_lshift( 1, width ) - 1)

                for i = 0, 255, 1 do
                    local value = previous[ i ]
                    current[ i ] = rbit_bxor( rbit_band( rbit_lshift( value, 8 ), mask ), t0[ rbit_rshift( value, shift ) ] )
                end
            end

            tables[ k ] = current
        end

        cache[ poly ] = tables
        return tables
    end

end

--- Feeds a string into a CRC-8 register.
---
--- For 8-bit CRCs the reflected and normal algorithms share the same step, only the tables differ.
---
---@param value integer The current register value.
---@param raw_str string The input string.
---@param tables dreamwork.std.checksum.CRCTables
---@return integer value The new register value.
local function crc8_update( value, raw_str, tables )
    local t0, t1, t2, t3, t4, t5, t6, t7 = tables[ 0 ], tables[ 1 ], tables[ 2 ], tables[ 3 ], tables[ 4 ], tables[ 5 ], tables[ 6 ], tables[ 7 ]

    local str_length = string_len( raw_str )
    local blocks_end = str_length - str_length % 8

    for index = 1, blocks_end, 8 do
        local uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 = string_byte( raw_str, index, index + 7 )

        value = rbit_bxor(
            t7[ rbit_bxor( value, uint8_1 ) ], t6[ uint8_2 ], t5[ uint8_3 ], t4[ uint8_4 ],
            t3[ uint8_5 ], t2[ uint8_6 ], t1[ uint8_7 ], t0[ uint8_8 ]
        )
    end

    for index = blocks_end + 1, str_length, 1 do
        value = t0[ rbit_bxor( value, string_byte( raw_str, index, index ) ) ]
    end

    return value
end

--- Feeds a string into a CRC-16 register.
---
---@param value integer The current register value.
---@param raw_str string The input string.
---@param tables dreamwork.std.checksum.CRCTables
---@param ref_in boolean `true` if the register is reflected.
---@return integer value The new register value.
local function crc16_update( value, raw_str, tables, ref_in )
    local t0, t1, t2, t3, t4, t5, t6, t7 = tables[ 0 ], tables[ 1 ], tables[ 2 ], tables[ 3 ], tables[ 4 ], tables[ 5 ], tables[ 6 ], tables[ 7 ]

    local str_length = string_len( raw_str )
    local blocks_end = str_length - str_length % 8

    if ref_in then
        for index = 1, blocks_end, 8 do
            local uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 = string_byte( raw_str, index, index + 7 )

            value = rbit_bxor(
                t7[ rbit_bxor( rbit_band( value, 0xFF ), uint8_1 ) ], t6[ rbit_bxor( rbit_rshift( value, 8 ), uint8_2 ) ], t5[ uint8_3 ], t4[ uint8_4 ],
                t3[ uint8_5 ], t2[ uint8_6 ], t1[ uint8_7 ], t0[ uint8_8 ]
            )
        end

        for index = blocks_end + 1, str_length, 1 do
            value = rbit_bxor( rbit_rshift( value, 8 ), t0[ rbit_band( rbit_bxor( value, string_byte( raw_str, index, index ) ), 0xFF ) ] )
        end
    else
        for index = 1, blocks_end, 8 do
            local uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 = string_byte( raw_str, index, index + 7 )

            value = rbit_bxor(
                t7[ rbit_bxor( rbit_rshift( value, 8 ), uint8_1 ) ], t6[ rbit_bxor( rbit_band( value, 0xFF ), uint8_2 ) ], t5[ uint8_3 ], t4[ uint8_4 ],
                t3[ uint8_5 ], t2[ uint8_6 ], t1[ uint8_7 ], t0[ uint8_8 ]
            )
        end

        for index = blocks_end + 1, str_length, 1 do
            value = rbit_bxor( rbit_band( rbit_lshift( value, 8 ), 0xFFFF ), t0[ rbit_bxor( rbit_rshift( value, 8 ), string_byte( raw_str, index, index ) ) ] )
        end
    end

    return value
end

--- Feeds a string into a CRC-32 register.
---
---@param value integer The current register value.
---@param raw_str string The input string.
---@param tables dreamwork.std.checksum.CRCTables
---@param ref_in boolean `true` if the register is reflected.
---@return integer value The new register value.
local function crc32_update( value, raw_str, tables, ref_in )
    local t0, t1, t2, t3, t4, t5, t6, t7 = tables[ 0 ], tables[ 1 ], tables[ 2 ], tables[ 3 ], tables[ 4 ], tables[ 5 ], tables[ 6 ], tables[ 7 ]

    local str_length = string_len( raw_str )
    local blocks_end = str_length - str_length % 8

    if ref_in then
        for index = 1, blocks_end, 8 do
            local uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 = string_byte( raw_str, index, index + 7 )

            value = rbit_bxor( value, rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) ) )

            value = rbit_bxor(
                t7[ rbit_band( value, 0xFF ) ], t6[ rbit_band( rbit_rshift( value, 8 ), 0xFF ) ], t5[ rbit_band( rbit_rshift( value, 16 ), 0xFF ) ], t4[ rbit_rshift( value, 24 ) ],
                t3[ uint8_5 ], t2[ uint8_6 ], t1[ uint8_7 ], t0[ uint8_8 ]
            )
        end

        for index = blocks_end + 1, str_length, 1 do
            value = rbit_bxor( rbit_rshift( value, 8 ), t0[ rbit_band( rbit_bxor( value, string_byte( raw_str, index, index ) ), 0xFF ) ] )
        end
    else
        for index = 1, blocks_end, 8 do
            local uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 = string_byte( raw_str, index, index + 7 )

            value = rbit_bxor( value, rbit_bor( rbit_lshift( uint8_1, 24 ), rbit_lshift( uint8_2, 16 ), rbit_lshift( uint8_3, 8 ), uint8_4 ) )

            value = rbit_bxor(
                t7[ rbit_rshift( value, 24 ) ], t6[ rbit_band( rbit_rshift( value, 16 ), 0xFF ) ], t5[ rbit_band( rbit_rshift( value, 8 ), 0xFF ) ], t4[ rbit_band( value, 0xFF ) ],
                t3[ uint8_5 ], t2[ uint8_6 ], t1[ uint8_7 ], t0[ uint8_8 ]
            )
        end

        for index = blocks_end + 1, str_length, 1 do
            value = rbit_bxor( rbit_lshift( value, 8 ), t0[ rbit_bxor( rbit_rshift( value, 24 ), string_byte( raw_str, index, index ) ) ] )
        end
    end

    return value
end

--- [SHARED AND MENU]
---
--- The CRC-8 checksum calculation object.
---
---@class dreamwork.std.checksum.CRC8 : dreamwork.std.Object
---@field __class dreamwork.std.checksum.CRC8Class
---@field protected poly integer The polynomial is used to calculate checksum.
---@field protected init integer The initial value of checksum, reflected if `ref_in` is `true`.
---@field protected ref_in boolean `true` if input checksum is reversed, otherwise `false`.
---@field protected ref_out boolean `true` if output checksum is reversed, otherwise `false`.
---@field protected xor_out integer The value to be XORed with output checksum.
---@field protected tables dreamwork.std.checksum.CRCTables The lookup tables for the polynomial.
---@field protected value integer The current value of the checksum.
---@field DigestSize integer The size of the checksum in bytes.
local CRC8 = class.base( "CRC8", false )

CRC8.DigestSize = 1

---@param poly? integer
---@param init? integer
---@param ref_in? boolean
---@param ref_out? boolean
---@param xor_out? integer
---@return integer poly
---@return integer init The initial register value, reflected if `ref_in` is `true`.
---@return boolean ref_in
---@return boolean ref_out
---@return integer xor_out
local function crc8_parameters( poly, init, ref_in, ref_out, xor_out )
    if poly == nil then
        poly = 0x07
    else
        poly = poly % 0x100
    end

    if init == nil then
        init = 0x00
    else
        init = init % 0x100
    end

    ref_in = ref_in == true

    -- reflected algorithms keep the register in the reflected domain
    if ref_in then
        init = reverse8[ init ]
    end

    if xor_out == nil then
        xor_out = 0x00
    else
        xor_out = xor_out % 0x100
    end

    return poly, init, ref_in, ref_out == true, xor_out
end

---@param poly? integer
---@param init? integer
---@param ref_in? boolean
---@param ref_out? boolean
---@param xor_out? integer
---@protected
function CRC8:__init( poly, init, ref_in, ref_out, xor_out )
    poly, init, ref_in, ref_out, xor_out = crc8_parameters( poly, init, ref_in, ref_out, xor_out )

    self.poly, self.init, self.ref_in, self.ref_out, self.xor_out = poly, init, ref_in, ref_out, xor_out
    self.tables = tables_new( 8, poly, ref_in )

    self:reset()
end

--- [SHARED AND MENU]
---
--- Resets checksum to the initial value.
---
---@return dreamwork.std.checksum.CRC8 self
function CRC8:reset()
    self.value = self.init
    return self
end

--- [SHARED AND MENU]
---
--- Updates checksum with the specified string.
---
---@param raw_str string The string is used to update checksum.
---@return dreamwork.std.checksum.CRC8 self
function CRC8:update( raw_str )
    self.value = crc8_update( self.value, raw_str, self.tables )
    return self
end

---@param value integer
---@param ref_in boolean
---@param ref_out boolean
---@param xor_out integer
---@return integer
local function crc8_finalize( value, ref_in, ref_out, xor_out )
    if ref_in ~= ref_out then
        value = reverse8[ value ]
    end

    return rbit_bxor( value, xor_out )
end

--- [SHARED AND MENU]
---
--- Finalizes checksum calculation and returns the resulting checksum.
---
---@return integer checksum The final checksum value, which is greater or equal to 0, and less than 2^8 (0x100).
function CRC8:digest()
    return crc8_finalize( self.value, self.ref_in, self.ref_out, self.xor_out )
end

--- [SHARED AND MENU]
---
--- The class used to create new CRC-8 checksum calculation instances.
---
--- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-8 checksum.
---
--- [CRC Online](https://www.texttool.com/crc-online)
---
---@class dreamwork.std.checksum.CRC8Class : dreamwork.std.checksum.CRC8
---@field __base dreamwork.std.checksum.CRC8
---@overload fun( poly?: integer, init?: integer, ref_in?: boolean, ref_out?: boolean, xor_out?: integer ): dreamwork.std.checksum.CRC8
local CRC8Class = class.create( CRC8 )
std.CRC8 = CRC8Class

--- [SHARED AND MENU]
---
--- Calculates the CRC-8 checksum of the specified string.
---
---@param raw_str string The string is used to calculate checksum.
---@param poly? integer The polynomial is used to calculate checksum.
---@param init? integer The initial value of checksum.
---@param ref_in? boolean `true` if input checksum is reversed, otherwise `false`.
---@param ref_out? boolean `true` if output checksum is reversed, otherwise `false`.
---@param xor_out? integer The value to be XORed with output checksum.
---@return integer checksum The CRC-8 checksum, which is greater or equal to 0, and less than 2^8 (0x100).
function CRC8Class.digest( raw_str, poly, init, ref_in, ref_out, xor_out )
    poly, init, ref_in, ref_out, xor_out = crc8_parameters( poly, init, ref_in, ref_out, xor_out )
    return crc8_finalize( crc8_update( init, raw_str, tables_new( 8, poly, ref_in ) ), ref_in, ref_out, xor_out )
end

--- [SHARED AND MENU]
---
--- The CRC-8 checksum class that uses MAXIM algorithm parameters.
---
---@return dreamwork.std.checksum.CRC8 object
function CRC8Class.MAXIM()
    return CRC8Class( 0x31, 0x00, true, true )
end

--- [SHARED AND MENU]
---
--- The CRC-8 checksum class that uses ROHC algorithm parameters.
---
---@return dreamwork.std.checksum.CRC8 object
function CRC8Class.ROHC()
    return CRC8Class( 0x07, 0xFF, true, true )
end

--- [SHARED AND MENU]
---
--- The CRC-8 checksum class that uses CDMA2000 algorithm parameters.
---
---@return dreamwork.std.checksum.CRC8 object
function CRC8Class.CDMA2000()
    return CRC8Class( 0x9B, 0xFF, false, false )
end

--- [SHARED AND MENU]
---
--- The class used to create new CRC-16 checksum calculation instances.
---
---@class dreamwork.std.checksum.CRC16 : dreamwork.std.checksum.CRC8
---@field __parent dreamwork.std.checksum.CRC8
---@field __class dreamwork.std.checksum.CRC16Class
---@field DigestSize integer The size of the checksum in bytes.
local CRC16 = class.base( "CRC16", false, CRC8Class )

CRC16.DigestSize = 2

---@param poly? integer
---@param init? integer
---@param ref_in? boolean
---@param ref_out? boolean
---@param xor_out? integer
---@return integer poly
---@return integer init The initial register value, reflected if `ref_in` is `true`.
---@return boolean ref_in
---@return boolean ref_out
---@return integer xor_out
local function crc16_parameters( poly, init, ref_in, ref_out, xor_out )
    if poly == nil then
        poly = 0x8005
    else
        poly = poly % 0x10000
    end

    if init == nil then
        init = 0x0000
    else
        init = init % 0x10000
    end

    ref_in = ref_in == true

    -- reflected algorithms keep the register in the reflected domain
    if ref_in then
        init = reverse16( init )
    end

    if xor_out == nil then
        xor_out = 0x0000
    else
        xor_out = xor_out % 0x10000
    end

    return poly, init, ref_in, ref_out == true, xor_out
end

---@param poly? integer
---@param init? integer
---@param ref_in? boolean
---@param ref_out? boolean
---@param xor_out? integer
---@protected
function CRC16:__init( poly, init, ref_in, ref_out, xor_out )
    poly, init, ref_in, ref_out, xor_out = crc16_parameters( poly, init, ref_in, ref_out, xor_out )

    self.poly, self.init, self.ref_in, self.ref_out, self.xor_out = poly, init, ref_in, ref_out, xor_out
    self.tables = tables_new( 16, poly, ref_in )

    self:reset()
end

--- [SHARED AND MENU]
---
--- Updates checksum with the specified string.
---
---@param raw_str string The string is used to update checksum.
---@return dreamwork.std.checksum.CRC16 self
function CRC16:update( raw_str )
    self.value = crc16_update( self.value, raw_str, self.tables, self.ref_in )
    return self
end

---@param value integer
---@param ref_in boolean
---@param ref_out boolean
---@param xor_out integer
---@return integer
local function crc16_finalize( value, ref_in, ref_out, xor_out )
    if ref_in ~= ref_out then
        value = reverse16( value )
    end

    return rbit_bxor( value, xor_out )
end

--- [SHARED AND MENU]
---
--- Finalizes checksum calculation and returns the resulting checksum.
---
---@return integer checksum The final checksum value, which is greater or equal to 0, and less than 2^16 (0x10000).
function CRC16:digest()
    return crc16_finalize( self.value, self.ref_in, self.ref_out, self.xor_out )
end

--- [SHARED AND MENU]
---
--- The class used to create new CRC-16 checksum calculation instances.
---
--- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-16 checksum.
---
--- [CRC Online](https://www.texttool.com/crc-online)
---
---@class dreamwork.std.checksum.CRC16Class : dreamwork.std.checksum.CRC16
---@field __parent dreamwork.std.checksum.CRC8Class
---@field __base dreamwork.std.checksum.CRC16
---@overload fun( poly?: integer, init?: integer, ref_in?: boolean, ref_out?: boolean, xor_out?: integer ): dreamwork.std.checksum.CRC16
local CRC16Class = class.create( CRC16 )
std.CRC16 = CRC16Class

-- CRC-8 presets are copied from the parent class, but would return CRC-8 objects
CRC16Class.ROHC = nil
CRC16Class.CDMA2000 = nil

--- [SHARED AND MENU]
---
--- Calculates the CRC-16 checksum of the specified string.
---
---@param raw_str string The string is used to calculate checksum.
---@param poly? integer The polynomial is used to calculate checksum.
---@param init? integer The initial value is used to calculate checksum.
---@param ref_in? boolean Whether to reflect the input data before processing.
---@param ref_out? boolean Whether to reflect the output data after processing.
---@param xor_out? integer The XOR value is used to calculate checksum.
---@return integer checksum The CRC-16 checksum, which is greater or equal to 0, and less than 2^16 (0x10000).
function CRC16Class.digest( raw_str, poly, init, ref_in, ref_out, xor_out )
    poly, init, ref_in, ref_out, xor_out = crc16_parameters( poly, init, ref_in, ref_out, xor_out )
    return crc16_finalize( crc16_update( init, raw_str, tables_new( 16, poly, ref_in ), ref_in ), ref_in, ref_out, xor_out )
end

--- [SHARED AND MENU]
---
--- The CRC-16 checksum class that uses MAXIM algorithm parameters.
---
---@return dreamwork.std.checksum.CRC16 object
function CRC16Class.MAXIM()
    return CRC16Class( 0x8005, 0x0000, true, true, 0xFFFF )
end

--- [SHARED AND MENU]
---
--- The CRC-16 checksum class that uses XMODEM algorithm parameters.
---
---@return dreamwork.std.checksum.CRC16 object
function CRC16Class.XMODEM()
    return CRC16Class( 0x1021, 0x0000, false, false )
end

--- [SHARED AND MENU]
---
--- The CRC-16 checksum class that uses USB algorithm parameters.
---
---@return dreamwork.std.checksum.CRC16 object
function CRC16Class.USB()
    return CRC16Class( 0x8005, 0xFFFF, true, true, 0xFFFF )
end

--- [SHARED AND MENU]
---
--- The CRC-32 checksum calculation object.
---
---@class dreamwork.std.checksum.CRC32 : dreamwork.std.checksum.CRC16
---@field __parent dreamwork.std.checksum.CRC16
---@field __class dreamwork.std.checksum.CRC32Class
---@field DigestSize integer The size of the checksum in bytes.
local CRC32 = class.base( "CRC32", false, CRC16Class )

CRC32.DigestSize = 4

---@param poly? integer
---@param init? integer
---@param ref_in? boolean
---@param ref_out? boolean
---@param xor_out? integer
---@return integer poly
---@return integer init The initial register value, NOT reflected.
---@return boolean ref_in
---@return boolean ref_out
---@return integer xor_out
local function crc32_parameters( poly, init, ref_in, ref_out, xor_out )
    if poly == nil then
        poly = 0x04C11DB7
    else
        poly = poly % 0x100000000
    end

    if init == nil then
        init = 0xFFFFFFFF
    else
        init = init % 0x100000000
    end

    if xor_out == nil then
        xor_out = 0xFFFFFFFF
    else
        xor_out = xor_out % 0x100000000
    end

    return poly, init, ref_in ~= false, ref_out ~= false, xor_out
end

---@param poly? integer
---@param init? integer
---@param ref_in? boolean
---@param ref_out? boolean
---@param xor_out? integer
---@protected
function CRC32:__init( poly, init, ref_in, ref_out, xor_out )
    poly, init, ref_in, ref_out, xor_out = crc32_parameters( poly, init, ref_in, ref_out, xor_out )

    -- reflected algorithms keep the register in the reflected domain
    if ref_in then
        init = reverse32( init )
    end

    self.poly, self.init, self.ref_in, self.ref_out, self.xor_out = poly, init, ref_in, ref_out, xor_out
    self.tables = tables_new( 32, poly, ref_in )

    self:reset()
end

--- [SHARED AND MENU]
---
--- Updates checksum with the specified string.
---
---@param raw_str string The string is used to update checksum.
---@return dreamwork.std.checksum.CRC32 self
function CRC32:update( raw_str )
    self.value = crc32_update( self.value, raw_str, self.tables, self.ref_in )
    return self
end

---@param value integer
---@param ref_in boolean
---@param ref_out boolean
---@param xor_out integer
---@return integer
local function crc32_finalize( value, ref_in, ref_out, xor_out )
    if ref_in ~= ref_out then
        value = reverse32( value )
    end

    return rbit_bxor( value, xor_out ) % 0x100000000
end

--- [SHARED AND MENU]
---
--- Finalizes checksum calculation and returns the resulting checksum.
---
---@return integer checksum The final checksum value, which is greater or equal to 0, and less than 2^32 (0x100000000).
function CRC32:digest()
    return crc32_finalize( self.value, self.ref_in, self.ref_out, self.xor_out )
end

--- [SHARED AND MENU]
---
--- The class used to create new CRC-32 checksum calculation instances.
---
--- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-32 checksum.
---
--- [CRC Online](https://www.texttool.com/crc-online)
---
---@class dreamwork.std.checksum.CRC32Class : dreamwork.std.checksum.CRC32
---@field __parent dreamwork.std.checksum.CRC16Class
---@field __base dreamwork.std.checksum.CRC32
---@overload fun( poly?: integer, init?: integer, ref_in?: boolean, ref_out?: boolean, xor_out?: integer ): dreamwork.std.checksum.CRC32
local CRC32Class = class.create( CRC32 )
std.CRC32 = CRC32Class

-- CRC-16 presets are copied from the parent class, but would return CRC-16 objects
CRC32Class.MAXIM = nil
CRC32Class.XMODEM = nil
CRC32Class.USB = nil

--- [SHARED AND MENU]
---
--- Calculates the CRC-32 checksum of the specified string.
---
---@param raw_str string The string is used to calculate checksum.
---@param poly? integer The polynomial is used to calculate checksum.
---@param init? integer The initial value is used to calculate checksum.
---@param ref_in? boolean Whether to reflect the input data before processing.
---@param ref_out? boolean Whether to reflect the output data after processing.
---@param xor_out? integer The XOR value is used to calculate checksum.
---@return integer checksum The CRC-32 checksum, which is greater or equal to 0, and less than 2^32 (0x100000000).
function CRC32Class.digest( raw_str, poly, init, ref_in, ref_out, xor_out )
    poly, init, ref_in, ref_out, xor_out = crc32_parameters( poly, init, ref_in, ref_out, xor_out )

    if util_CRC ~= nil and poly == 0x04C11DB7 and init == 0xFFFFFFFF and ref_in and ref_out and xor_out == 0xFFFFFFFF then
        return raw_tonumber( util_CRC( raw_str ) or 0, 10 ) or 0
    end

    if ref_in then
        init = reverse32( init )
    end

    return crc32_finalize( crc32_update( init, raw_str, tables_new( 32, poly, ref_in ), ref_in ), ref_in, ref_out, xor_out )
end

--- [SHARED AND MENU]
---
--- The CRC-32 checksum class that uses BZIP2 algorithm parameters.
---
---@return dreamwork.std.checksum.CRC32 object
function CRC32Class.BZIP2()
    return CRC32Class( 0x04C11DB7, 0xFFFFFFFF, false, false, 0xFFFFFFFF )
end

--- [SHARED AND MENU]
---
--- The CRC-32 checksum class that uses Castagnoli/C algorithm parameters.
---
---@return dreamwork.std.checksum.CRC32 object
function CRC32Class.C()
    return CRC32Class( 0x1EDC6F41, 0xFFFFFFFF, true, true, 0xFFFFFFFF )
end

--- [SHARED AND MENU]
---
--- The CRC-32 checksum class that uses D algorithm parameters.
---
---@return dreamwork.std.checksum.CRC32 object
function CRC32Class.D()
    return CRC32Class( 0xA833982B, 0xFFFFFFFF, true, true, 0xFFFFFFFF )
end

--- [SHARED AND MENU]
---
--- The CRC-32 checksum class that uses JamCRC algorithm parameters.
---
---@return dreamwork.std.checksum.CRC32 object
function CRC32Class.JAMCRC()
    return CRC32Class( 0x04C11DB7, 0xFFFFFFFF, true, true, 0x00000000 )
end

--- [SHARED AND MENU]
---
--- The CRC-32 checksum class that uses MPEG-2 algorithm parameters.
---
---@return dreamwork.std.checksum.CRC32 object
function CRC32Class.MPEG2()
    return CRC32Class( 0x04C11DB7, 0xFFFFFFFF, false, false, 0x00000000 )
end

--- [SHARED AND MENU]
---
--- The CRC-32 checksum class that uses POSIX algorithm parameters.
---
---@return dreamwork.std.checksum.CRC32 object
function CRC32Class.POSIX()
    return CRC32Class( 0x04C11DB7, 0x00000000, false, false, 0xFFFFFFFF )
end

--- [SHARED AND MENU]
---
--- The CRC-32 checksum class that uses Q algorithm parameters.
---
---@return dreamwork.std.checksum.CRC32 object
function CRC32Class.Q()
    return CRC32Class( 0x814141AB, 0x00000000, false, false, 0x00000000 )
end

--- [SHARED AND MENU]
---
--- The CRC-32 checksum class that uses XFER algorithm parameters.
---
---@return dreamwork.std.checksum.CRC32 object
function CRC32Class.XFER()
    return CRC32Class( 0x000000AF, 0x00000000, false, false, 0x00000000 )
end
