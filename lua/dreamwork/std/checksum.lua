---@type dreamwork
local dreamwork = _G.dreamwork

---@class dreamwork.std
local std = dreamwork.std

local bit = std.bit
local bit_bxor = bit.bxor
local bit_reverse = bit.reverse
local bit_band, bit_bor = bit.band, bit.bor
local bit_lshift, bit_rshift = bit.lshift, bit.rshift

local class = std.class

local string = std.string
local string_len = string.len
local string_byte = string.byte

--- [SHARED AND MENU]
---
--- The checksum calculation classes.
---
--- #### Tools
--- * [CRC Online](https://www.texttool.com/crc-online)
--- * [Adler32 Online](https://md5calc.com/hash/adler32)
--- * [Fletcher Online](https://www.convertcase.com/hashing/fletcher-checksum)
---
---@class dreamwork.std.checksum
local checksum = {}
std.checksum = checksum

--- [SHARED AND MENU]
---
--- The CRC-8 checksum calculation object.
---
---@class dreamwork.std.checksum.CRC8 : dreamwork.Object
---@field __class dreamwork.std.checksum.CRC8Class
---@field protected poly integer The polynomial is used to calculate checksum.
---@field protected init integer The initial value of checksum.
---@field protected ref_in boolean `true` if input checksum is reversed, otherwise `false`.
---@field protected ref_out boolean `true` if output checksum is reversed, otherwise `false`.
---@field protected xor_out integer | nil The value to be XORed with output checksum.
---@field protected value integer The current value of the checksum.
---@field DigestSize integer The size of the checksum in bytes.
local CRC8 = class.base( "checksum.CRC8", false )

CRC8.DigestSize = 1

---@alias CRC8 dreamwork.std.checksum.CRC8

---@param poly? integer The polynomial is used to calculate the checksum.
---@param init? integer The initial value of checksum.
---@param ref_in? boolean `true` if input checksum is reversed, otherwise `false`.
---@param ref_out? boolean `true` if output checksum is reversed, otherwise `false`.
---@param xor_out? integer The value to be XORed with the output checksum.
---@protected
function CRC8:__init( poly, init, ref_in, ref_out, xor_out )
    if poly == nil then
        self.poly = 0x07
    else
        self.poly = poly % 0x100
    end

    if init == nil then
        self.init = 0x00
    else
        self.init = init % 0x100
    end

    self.ref_in = ref_in == true
    self.ref_out = ref_out == true

    if xor_out ~= nil then
        self.xor_out = xor_out % 0x100
    end

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

do

    ---@type table<integer, table<integer, integer>>
    local crc8_lookup = {}

    setmetatable( crc8_lookup, {
        __index = function( self, poly )
            ---@type table<integer, integer>
            local hash_map = {}

            for i = 0, 255, 1 do
                local value = i

                for _ = 1, 8, 1 do
                    if bit_band( value, 0x80 ) == 0x00 then
                        value = bit_lshift( value, 0x01 )
                    else
                        value = bit_bxor( bit_lshift( value, 0x01 ), poly )
                    end
                end

                hash_map[ i ] = bit_band( value, 0xFF )
            end

            self[ poly ] = hash_map
            return hash_map
        end
    } )

    --- [SHARED AND MENU]
    ---
    --- Updates checksum with the specified string.
    ---
    ---@param raw_str string The string is used to update checksum.
    ---@return dreamwork.std.checksum.CRC8 self
    function CRC8:update( raw_str )
        local hash_map = crc8_lookup[ self.poly ]
        local ref_in = self.ref_in
        local value = self.value

        for index = 1, string_len( raw_str ), 1 do
            if ref_in then
                value = hash_map[ bit_bxor( value, bit_reverse( string_byte( raw_str, index, index ), 0x08 ) ) ]
            else
                value = hash_map[ bit_bxor( value, string_byte( raw_str, index, index ) ) ]
            end
        end

        self.value = value
        return self
    end

end

--- [SHARED AND MENU]
---
--- Finalizes checksum calculation and returns the resulting checksum.
---
---@return integer checksum The final checksum value, which is greater or equal to 0, and less than 2^8 (0x100).
function CRC8:digest()
    local value = self.value

    if self.ref_out then
        value = bit_reverse( value, 0x08 )
    end

    local xor_out = self.xor_out
    if xor_out ~= nil then
        value = bit_bxor( value, xor_out )
    end

    return bit_band( value, 0xFF )
end

--- [SHARED AND MENU]
---
--- The CRC-8 checksum calculation class.
---
--- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-8 checksum.
---
---@class dreamwork.std.checksum.CRC8Class : dreamwork.std.checksum.CRC8
---@field __base dreamwork.std.checksum.CRC8
---@overload fun( poly?: integer, init?: integer, ref_in?: boolean, ref_out?: boolean, xor_out?: integer ): dreamwork.std.checksum.CRC8
local CRC8Class = class.create( CRC8 )
checksum.CRC8 = CRC8Class

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
    return CRC8Class( poly, init, ref_in, ref_out, xor_out ):update( raw_str ):digest()
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
--- The CRC-16 checksum calculation object.
---
---@class dreamwork.std.checksum.CRC16 : dreamwork.std.checksum.CRC8
---@field __parent dreamwork.std.checksum.CRC8
---@field __class dreamwork.std.checksum.CRC16Class
---@field protected hash_key integer The hash key is used to generate the hash map.
---@field DigestSize integer The size of the checksum in bytes.
local CRC16 = class.base( "checksum.CRC16", false, CRC8Class )

CRC16.DigestSize = 2

---@alias CRC16 dreamwork.std.checksum.CRC16

---@param poly? integer The polynomial is used to calculate the CRC-8 checksum.
---@param init? integer The initial value of the CRC-8 checksum.
---@param ref_in? boolean `true` if the input CRC-8 checksum is reversed, otherwise `false`.
---@param ref_out? boolean `true` if the output CRC-8 checksum is reversed, otherwise `false`.
---@param xor_out? integer The value to be XORed with the output CRC-8 checksum.
---@protected
function CRC16:__init( poly, init, ref_in, ref_out, xor_out )
    if poly == nil then
        self.poly = 0x8005
    else
        self.poly = poly % 0x10000
    end

    if init == nil then
        self.init = 0x00
    else
        self.init = init % 0x10000
    end

    self.ref_in = ref_in == true
    self.ref_out = ref_out == true

    if xor_out ~= nil then
        self.xor_out = xor_out % 0x10000
    end

    self.hash_key = bit_bor(
        self.poly,
        self.ref_in and 0x10000 or 0x00,
        self.ref_out and 0x20000 or 0x00
    )

    self:reset()
end

do

    ---@type table<integer, table<integer, integer>>
    local crc16_lookup = {}

    setmetatable( crc16_lookup, {
        __index = function( self, uint17 )
            local ref_out = bit_band( uint17, 0x20000 ) ~= 0x00
            local ref_in = bit_band( uint17, 0x10000 ) ~= 0x00
            local poly = bit_band( uint17, 0xFFFF )

            ---@type table<integer, integer>
            local hash_map = {}

            for i = 0, 255, 1 do
                local value

                if ref_in then
                    value = bit_reverse( i, 0x08 )
                else
                    value = i
                end

                value = bit_lshift( value, 0x08 )

                for _ = 1, 8, 1 do
                    if bit_band( value, 0x8000 ) == 0x00 then
                        value = bit_lshift( value, 0x01 )
                    else
                        value = bit_bxor( bit_lshift( value, 0x01 ), poly )
                    end
                end

                value = bit_band( value, 0xFFFF )

                if ref_out then
                    value = bit_reverse( value, 0x10 )
                end

                hash_map[ i ] = value
            end

            self[ uint17 ] = hash_map
            return hash_map
        end
    } )

    --- [SHARED AND MENU]
    ---
    --- Updates checksum with the specified string.
    ---
    ---@param raw_str string The string is used to update checksum.
    ---@return dreamwork.std.checksum.CRC16 self
    function CRC16:update( raw_str )
        local hash_map = crc16_lookup[ self.hash_key ]
        local ref_in = self.ref_in
        local value = self.value

        for index = 1, string_len( raw_str ), 1 do
            if ref_in then
                value = bit_bxor( bit_rshift( value, 0x08 ), hash_map[ bit_band( bit_bxor( value, string_byte( raw_str, index, index ) ), 0xFF ) ] )
            else
                value = bit_bxor( bit_lshift( value, 0x08 ), hash_map[ bit_band( bit_bxor( bit_rshift( value, 0x08 ), string_byte( raw_str, index, index ) ), 0xFF ) ] )
            end
        end

        self.value = value
        return self
    end

end

--- [SHARED AND MENU]
---
--- Finalizes checksum calculation and returns the resulting checksum.
---
---@return integer checksum The final checksum value, which is greater or equal to 0, and less than 2^16 (0x10000).
function CRC16:digest()
    local value = self.value

    local xor_out = self.xor_out
    if xor_out ~= nil then
        value = bit_bxor( value, xor_out )
    end

    return bit_band( value, 0xFFFF )
end

--- [SHARED AND MENU]
---
--- The CRC-16 checksum calculation class.
---
--- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-16 checksum.
---
---@class dreamwork.std.checksum.CRC16Class : dreamwork.std.checksum.CRC16
---@field __parent dreamwork.std.checksum.CRC8Class
---@field __base dreamwork.std.checksum.CRC16
---@overload fun( poly?: integer, init?: integer, ref_in?: boolean, ref_out?: boolean, xor_out?: integer ): dreamwork.std.checksum.CRC16
local CRC16Class = class.create( CRC16 )
checksum.CRC16 = CRC16Class

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
    return CRC16Class( poly, init, ref_in, ref_out, xor_out ):update( raw_str ):digest()
end

--- [SHARED AND MENU]
---
--- The CRC-16 checksum class that uses MAXIM algorithm parameters.
---
---@return dreamwork.std.checksum.CRC16 object
function CRC16Class.MAXIM()
    return CRC16Class( 0x8005, 0x0000, true, true )
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
local CRC32 = class.base( "checksum.CRC32", false, CRC16Class )

CRC32.DigestSize = 4

---@alias CRC32 dreamwork.std.checksum.CRC32

---@param poly? integer The polynomial is used to calculate the CRC-8 checksum.
---@param init? integer The initial value of the CRC-8 checksum.
---@param ref_in? boolean `true` if the input CRC-8 checksum is reversed, otherwise `false`.
---@param ref_out? boolean `true` if the output CRC-8 checksum is reversed, otherwise `false`.
---@param xor_out? integer The value to be XORed with the output CRC-8 checksum.
---@protected
function CRC32:__init( poly, init, ref_in, ref_out, xor_out )
    if poly == nil then
        self.poly = 0x04C11DB7
    else
        self.poly = poly % 0x100000000
    end

    if init == nil then
        self.init = 0xFFFFFFFF
    else
        self.init = init % 0x100000000
    end

    self.ref_in = ref_in == true
    self.ref_out = ref_out == true

    if xor_out == nil then
        self.xor_out = 0xFFFFFFFF
    else
        self.xor_out = xor_out % 0x100000000
    end

    -- self.hash_key = bit_bor(
    --     self.poly,
    --     self.ref_in and 0x10000 or 0x00,
    --     self.ref_out and 0x20000 or 0x00
    -- )

    self:reset()
end

do

    ---@type table<integer, table<integer, integer>>
    local crc32_lookup = {}

    setmetatable( crc32_lookup, {
        __index = function( self, poly )
            local hash_map = {}

            for i = 0, 255, 1 do
                local value = bit_lshift( i, 0x18 )

                for _ = 1, 8, 1 do
                    if bit_band( value, 0x80000000 ) == 0 then
                        value = bit_lshift( value, 1 )
                    else
                        value = bit_bxor( bit_lshift( value, 1 ), poly )
                    end
                end

                hash_map[ i ] = value % 0x100000000
            end

            self[ poly ] = hash_map
            return hash_map
        end
    } )

    --- [SHARED AND MENU]
    ---
    --- Updates checksum with the specified string.
    ---
    ---@param raw_str string The string is used to update checksum.
    ---@return dreamwork.std.checksum.CRC32 self
    function CRC32:update( raw_str )
        local hash_map = crc32_lookup[ self.poly ]
        local ref_in = self.ref_in
        local value = self.value

        for index = 1, string_len( raw_str ), 1 do
            if ref_in then
                value = bit_bxor( bit_lshift( value, 8 ), hash_map[ bit_band( bit_bxor( bit_band( bit_rshift( value, 24 ), 0xFF ), bit_reverse( string_byte( raw_str, index, index ), 8 ) ), 0xFF ) ] )
            else
                value = bit_bxor( bit_lshift( value, 8 ), hash_map[ bit_band( bit_bxor( bit_band( bit_rshift( value, 24 ), 0xFF ), string_byte( raw_str, index, index ) ), 0xFF ) ] )
            end
        end

        self.value = value
        return self
    end

end

--- [SHARED AND MENU]
---
--- Finalizes checksum calculation and returns the resulting checksum.
---
---@return integer checksum The final checksum value, which is greater or equal to 0, and less than 2^32 (0x100000000).
function CRC32:digest()
    local value = self.value

    local ref_out = self.ref_out
    if ref_out then
        value = bit_reverse( value, 0x20 )
    end

    local xor_out = self.xor_out
    if xor_out ~= nil then
        value = bit_bxor( value, xor_out )
    end

    return value % 0x100000000
end


--- [SHARED AND MENU]
---
--- The CRC-32 checksum calculation class.
---
--- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-32 checksum.
---
---@class dreamwork.std.checksum.CRC32Class : dreamwork.std.checksum.CRC32
---@field __parent dreamwork.std.checksum.CRC16Class
---@field __base dreamwork.std.checksum.CRC32
---@overload fun( poly?: integer, init?: integer, ref_in?: boolean, ref_out?: boolean, xor_out?: integer ): dreamwork.std.checksum.CRC32
local CRC32Class = class.create( CRC32 )
checksum.CRC32 = CRC32Class

do

    local engine_CRC32 = dreamwork.engine.CRC32
    local raw_tonumber = std.raw.tonumber

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
        ref_in = ref_in ~= false
        ref_out = ref_out ~= false

        if init == nil then
            init = 0xFFFFFFFF
        else
            init = init % 0x100000000
        end

        if poly == nil then
            poly = 0x04C11DB7
        else
            poly = poly % 0x100000000
        end

        if xor_out == nil then
            xor_out = 0xFFFFFFFF
        else
            xor_out = xor_out % 0x100000000
        end

        if engine_CRC32 ~= nil and poly == 0x04C11DB7 and init == 0xFFFFFFFF and ref_in and ref_out and xor_out == 0xFFFFFFFF then
            return raw_tonumber( engine_CRC32( raw_str ) or 0, 10 ) or 0
        else
            return CRC32Class( poly, init, ref_in, ref_out, xor_out ):update( raw_str ):digest()
        end
    end

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

--- [SHARED AND MENU]
---
--- The Adler-32 checksum calculation object.
---
---@class dreamwork.std.checksum.Adler32 : dreamwork.Object
---@field __class dreamwork.std.checksum.Adler32Class
---@field DigestSize integer The size of the checksum in bytes.
---@field BlockSize integer The block size in bytes.
---@field private a integer The first part of the checksum.
---@field private b integer The second part of the checksum.
local Adler32 = std.class.base( "checksum.Adler32", false )

Adler32.DigestSize = 4
Adler32.BlockSize = 16

---@alias Adler32 dreamwork.std.checksum.Adler32

---@protected
function Adler32:__init()
    self:reset()
end

--- [SHARED AND MENU]
---
--- Resets checksum to the initial value.
---
---@return dreamwork.std.checksum.Adler32 self
function Adler32:reset()
    self.a, self.b = 1, 0
    return self
end

--- [SHARED AND MENU]
---
--- Updates checksum with the specified string.
---
---@param raw_str string The string is used to update checksum.
---@return dreamwork.std.checksum.Adler32 self
function Adler32:update( raw_str )
    local str_length = string_len( raw_str )
    if str_length == 0 then
        return self
    end

    local position = str_length % 16
    local a, b = self.a, self.b

    if position ~= 0 then
        if position == 1 then
            a = (
                a +
                string_byte( raw_str, 1, position )
            ) % 0xFFF1

            b = (
                b +
                a
            ) % 0xFFF1
        elseif position == 2 then
            local uint8_1, uint8_2 = string_byte( raw_str, 1, position )

            b = (
                b +
                2 * a +
                2 * uint8_1 +
                uint8_2
            ) % 0xFFF1

            a = (
                a +
                uint8_1 +
                uint8_2
            ) % 0xFFF1
        elseif position == 3 then
            local uint8_1, uint8_2, uint8_3 = string_byte( raw_str, 1, position )

            b = (
                b +
                3 * a +
                3 * uint8_1 +
                2 * uint8_2 +
                uint8_3
            ) % 0xFFF1

            a = (
                a +
                uint8_1 +
                uint8_2 +
                uint8_3
            ) % 0xFFF1
        elseif position == 4 then
            local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( raw_str, 1, position )

            b = (
                b +
                4 * a +
                4 * uint8_1 +
                3 * uint8_2 +
                2 * uint8_3 +
                uint8_4
            ) % 0xFFF1

            a = (
                a +
                uint8_1 +
                uint8_2 +
                uint8_3 +
                uint8_4
            ) % 0xFFF1
        elseif position == 5 then
            local uint8_1, uint8_2, uint8_3, uint8_4,
                uint8_5 = string_byte( raw_str, 1, position )

            b = (
                b +
                5 * a +
                5 * uint8_1 +
                4 * uint8_2 +
                3 * uint8_3 +
                2 * uint8_4 +
                uint8_5
            ) % 0xFFF1

            a = (
                a +
                uint8_1 +
                uint8_2 +
                uint8_3 +
                uint8_4 +
                uint8_5
            ) % 0xFFF1
        elseif position == 6 then
            local uint8_1, uint8_2, uint8_3, uint8_4,
                uint8_5, uint8_6 = string_byte( raw_str, 1, position )

            b = (
                b +
                6 * a +
                6 * uint8_1 +
                5 * uint8_2 +
                4 * uint8_3 +
                3 * uint8_4 +
                2 * uint8_5 +
                uint8_6
            ) % 0xFFF1

            a = (
                a +
                uint8_1 +
                uint8_2 +
                uint8_3 +
                uint8_4 +
                uint8_5 +
                uint8_6
            ) % 0xFFF1
        elseif position == 7 then
            local uint8_1, uint8_2, uint8_3, uint8_4,
                uint8_5, uint8_6, uint8_7 = string_byte( raw_str, 1, position )

            b = (
                b +
                7 * a +
                7 * uint8_1 +
                6 * uint8_2 +
                5 * uint8_3 +
                4 * uint8_4 +
                3 * uint8_5 +
                2 * uint8_6 +
                uint8_7
            ) % 0xFFF1

            a = (
                a +
                uint8_1 +
                uint8_2 +
                uint8_3 +
                uint8_4 +
                uint8_5 +
                uint8_6 +
                uint8_7
            ) % 0xFFF1
        elseif position == 8 then
            local uint8_1, uint8_2, uint8_3, uint8_4,
                uint8_5, uint8_6, uint8_7, uint8_8 = string_byte( raw_str, 1, position )

            b = (
                b +
                8 * a +
                8 * uint8_1 +
                7 * uint8_2 +
                6 * uint8_3 +
                5 * uint8_4 +
                4 * uint8_5 +
                3 * uint8_6 +
                2 * uint8_7 +
                uint8_8
            ) % 0xFFF1

            a = (
                a +
                uint8_1 +
                uint8_2 +
                uint8_3 +
                uint8_4 +
                uint8_5 +
                uint8_6 +
                uint8_7 +
                uint8_8
            ) % 0xFFF1
        elseif position == 9 then
            local uint8_1, uint8_2, uint8_3, uint8_4,
                uint8_5, uint8_6, uint8_7, uint8_8,
                    uint8_9 = string_byte( raw_str, 1, position )

            b = (
                b +
                9 * a +
                9 * uint8_1 +
                8 * uint8_2 +
                7 * uint8_3 +
                6 * uint8_4 +
                5 * uint8_5 +
                4 * uint8_6 +
                3 * uint8_7 +
                2 * uint8_8 +
                uint8_9
            ) % 0xFFF1

            a = (
                a +
                uint8_1 +
                uint8_2 +
                uint8_3 +
                uint8_4 +
                uint8_5 +
                uint8_6 +
                uint8_7 +
                uint8_8 +
                uint8_9
            ) % 0xFFF1
        elseif position == 10 then
            local uint8_1, uint8_2, uint8_3, uint8_4,
                uint8_5, uint8_6, uint8_7, uint8_8,
                    uint8_9, uint8_10 = string_byte( raw_str, 1, position )

            b = (
                b +
                10 * a +
                10 * uint8_1 +
                9 * uint8_2 +
                8 * uint8_3 +
                7 * uint8_4 +
                6 * uint8_5 +
                5 * uint8_6 +
                4 * uint8_7 +
                3 * uint8_8 +
                2 * uint8_9 +
                uint8_10
            ) % 0xFFF1

            a = (
                a +
                uint8_1 +
                uint8_2 +
                uint8_3 +
                uint8_4 +
                uint8_5 +
                uint8_6 +
                uint8_7 +
                uint8_8 +
                uint8_9 +
                uint8_10
            ) % 0xFFF1
        elseif position == 11 then
            local uint8_1, uint8_2, uint8_3, uint8_4,
                uint8_5, uint8_6, uint8_7, uint8_8,
                    uint8_9, uint8_10, uint8_11 = string_byte( raw_str, 1, position )

            b = (
                b +
                11 * a +
                11 * uint8_1 +
                10 * uint8_2 +
                9 * uint8_3 +
                8 * uint8_4 +
                7 * uint8_5 +
                6 * uint8_6 +
                5 * uint8_7 +
                4 * uint8_8 +
                3 * uint8_9 +
                2 * uint8_10 +
                uint8_11
            ) % 0xFFF1

            a = (
                a +
                uint8_1 +
                uint8_2 +
                uint8_3 +
                uint8_4 +
                uint8_5 +
                uint8_6 +
                uint8_7 +
                uint8_8 +
                uint8_9 +
                uint8_10 +
                uint8_11
            ) % 0xFFF1
        elseif position == 12 then
            local uint8_1, uint8_2, uint8_3, uint8_4,
                uint8_5, uint8_6, uint8_7, uint8_8,
                    uint8_9, uint8_10, uint8_11, uint8_12 = string_byte( raw_str, 1, position )

            b = (
                b +
                12 * a +
                12 * uint8_1 +
                11 * uint8_2 +
                10 * uint8_3 +
                9 * uint8_4 +
                8 * uint8_5 +
                7 * uint8_6 +
                6 * uint8_7 +
                5 * uint8_8 +
                4 * uint8_9 +
                3 * uint8_10 +
                2 * uint8_11 +
                uint8_12
            ) % 0xFFF1

            a = (
                a +
                uint8_1 +
                uint8_2 +
                uint8_3 +
                uint8_4 +
                uint8_5 +
                uint8_6 +
                uint8_7 +
                uint8_8 +
                uint8_9 +
                uint8_10 +
                uint8_11 +
                uint8_12
            ) % 0xFFF1
        elseif position == 13 then
            local uint8_1, uint8_2, uint8_3, uint8_4,
                uint8_5, uint8_6, uint8_7, uint8_8,
                    uint8_9, uint8_10, uint8_11, uint8_12,
                        uint8_13 = string_byte( raw_str, 1, position )

            b = (
                b +
                13 * a +
                13 * uint8_1 +
                12 * uint8_2 +
                11 * uint8_3 +
                10 * uint8_4 +
                9 * uint8_5 +
                8 * uint8_6 +
                7 * uint8_7 +
                6 * uint8_8 +
                5 * uint8_9 +
                4 * uint8_10 +
                3 * uint8_11 +
                2 * uint8_12 +
                uint8_13
            ) % 0xFFF1

            a = (
                a +
                uint8_1 +
                uint8_2 +
                uint8_3 +
                uint8_4 +
                uint8_5 +
                uint8_6 +
                uint8_7 +
                uint8_8 +
                uint8_9 +
                uint8_10 +
                uint8_11 +
                uint8_12 +
                uint8_13
            ) % 0xFFF1
        elseif position == 14 then
            local uint8_1, uint8_2, uint8_3, uint8_4,
                uint8_5, uint8_6, uint8_7, uint8_8,
                    uint8_9, uint8_10, uint8_11, uint8_12,
                        uint8_13, uint8_14 = string_byte( raw_str, 1, position )

            b = (
                b +
                14 * a +
                14 * uint8_1 +
                13 * uint8_2 +
                12 * uint8_3 +
                11 * uint8_4 +
                10 * uint8_5 +
                9 * uint8_6 +
                8 * uint8_7 +
                7 * uint8_8 +
                6 * uint8_9 +
                5 * uint8_10 +
                4 * uint8_11 +
                3 * uint8_12 +
                2 * uint8_13 +
                uint8_14
            ) % 0xFFF1

            a = (
                a +
                uint8_1 +
                uint8_2 +
                uint8_3 +
                uint8_4 +
                uint8_5 +
                uint8_6 +
                uint8_7 +
                uint8_8 +
                uint8_9 +
                uint8_10 +
                uint8_11 +
                uint8_12 +
                uint8_13 +
                uint8_14
            ) % 0xFFF1
        elseif position == 15 then
            local uint8_1, uint8_2, uint8_3, uint8_4,
                uint8_5, uint8_6, uint8_7, uint8_8,
                    uint8_9, uint8_10, uint8_11, uint8_12,
                        uint8_13, uint8_14, uint8_15 = string_byte( raw_str, 1, position )

            b = (
                b +
                15 * a +
                15 * uint8_1 +
                14 * uint8_2 +
                13 * uint8_3 +
                12 * uint8_4 +
                11 * uint8_5 +
                10 * uint8_6 +
                9 * uint8_7 +
                8 * uint8_8 +
                7 * uint8_9 +
                6 * uint8_10 +
                5 * uint8_11 +
                4 * uint8_12 +
                3 * uint8_13 +
                2 * uint8_14 +
                uint8_15
            ) % 0xFFF1

            a = (
                a +
                uint8_1 +
                uint8_2 +
                uint8_3 +
                uint8_4 +
                uint8_5 +
                uint8_6 +
                uint8_7 +
                uint8_8 +
                uint8_9 +
                uint8_10 +
                uint8_11 +
                uint8_12 +
                uint8_13 +
                uint8_14 +
                uint8_15
            ) % 0xFFF1
        end
    end

    str_length = str_length - 15
    position = position + 1

    ::perform_block::

    if position > str_length then
        self.a, self.b = a, b
        return self
    end

    local uint8_1, uint8_2, uint8_3, uint8_4,
        uint8_5, uint8_6, uint8_7, uint8_8,
        uint8_9, uint8_10, uint8_11, uint8_12,
        uint8_13, uint8_14, uint8_15, uint8_16 = string_byte( raw_str, position, position + 15 )

    b = (
        b +
        16 * a +
        16 * uint8_1 +
        15 * uint8_2 +
        14 * uint8_3 +
        13 * uint8_4 +
        12 * uint8_5 +
        11 * uint8_6 +
        10 * uint8_7 +
        9 * uint8_8 +
        8 * uint8_9 +
        7 * uint8_10 +
        6 * uint8_11 +
        5 * uint8_12 +
        4 * uint8_13 +
        3 * uint8_14 +
        2 * uint8_15 +
        uint8_16
    ) % 0xFFF1

    a = (
        a +
        uint8_1 +
        uint8_2 +
        uint8_3 +
        uint8_4 +
        uint8_5 +
        uint8_6 +
        uint8_7 +
        uint8_8 +
        uint8_9 +
        uint8_10 +
        uint8_11 +
        uint8_12 +
        uint8_13 +
        uint8_14 +
        uint8_15 +
        uint8_16
    ) % 0xFFF1

    position = position + 16
    ---@diagnostic disable-next-line: missing-return
    goto perform_block
end

--- [SHARED AND MENU]
---
--- Finalizes checksum calculation and returns the resulting checksum.
---
---@return integer checksum The final checksum value, which is greater or equal to 0, and less than 2^32 (0x100000000).
function Adler32:digest()
    return ( self.b * 0x10000 ) + self.a
end

--- [SHARED AND MENU]
---
--- The Adler-32 checksum calculation class.
---
--- See [RFC1950](https://tools.ietf.org/html/rfc1950) for the definition of the Adler-32 checksum.
---
---@class dreamwork.std.checksum.Adler32Class : dreamwork.std.checksum.Adler32
---@field __base dreamwork.std.checksum.Adler32
---@overload fun(): dreamwork.std.checksum.Adler32
local Adler32Class = class.create( Adler32 )
checksum.Adler32 = Adler32Class

do

    local adler32 = Adler32Class()

    --- [SHARED AND MENU]
    ---
    --- Calculates the Adler-32 checksum of the specified string.
    ---
    ---@param raw_str string The string is used to calculate checksum.
    function Adler32Class.digest( raw_str )
        return adler32:reset():update( raw_str ):digest()
    end

end

--- [SHARED AND MENU]
---
--- The Fletcher-16 checksum calculation object.
---
---@class dreamwork.std.checksum.Fletcher16 : dreamwork.Object
---@field __class dreamwork.std.checksum.Fletcher16Class
---@field DigestSize integer The size of the checksum in bytes.
---@field protected a integer The first part of the checksum.
---@field protected b integer The second part of the checksum.
local Fletcher16 = class.base( "checksum.Fletcher16", false )

Fletcher16.DigestSize = 2

---@alias Fletcher16 dreamwork.std.checksum.Fletcher16

---@protected
function Fletcher16:__init()
    self:reset()
end

--- [SHARED AND MENU]
---
--- Resets checksum to the initial value.
---
---@return dreamwork.std.checksum.Fletcher16 self
function Fletcher16:reset()
    self.a, self.b = 0, 0
    return self
end

--- [SHARED AND MENU]
---
--- Updates checksum with the specified string.
---
---@param raw_str string The string is used to update checksum.
---@return dreamwork.std.checksum.Fletcher16 self
function Fletcher16:update( raw_str )
    local a, b = self.a, self.b

    for i = 1, string_len( raw_str ), 1 do
        a = ( a + string_byte( raw_str, i, i ) ) % 0xFF
        b = ( b + a ) % 0xFF
    end

    self.a, self.b = a, b
    return self
end

--- [SHARED AND MENU]
---
--- Finalizes checksum calculation and returns the resulting checksum.
---
---@return integer checksum The final checksum value, which is greater or equal to 0, and less than 2^16 (0x10000).
function Fletcher16:digest()
    return ( self.b * 0x0100 ) + self.a
end

--- [SHARED AND MENU]
---
--- The Fletcher-16 checksum calculation class.
---
--- See [Fletcher's checksum](https://en.wikipedia.org/wiki/Fletcher%27s_checksum) for the definition of the Fletcher-16 checksum.
---
---@class dreamwork.std.checksum.Fletcher16Class : dreamwork.std.checksum.Fletcher16
---@field __base dreamwork.std.checksum.Fletcher16
---@overload fun(): dreamwork.std.checksum.Fletcher16
local Fletcher16Class = class.create( Fletcher16 )
checksum.Fletcher16 = Fletcher16Class

do

    local fletcher16 = Fletcher16Class()

    --- [SHARED AND MENU]
    ---
    --- Calculates the Fletcher-16 checksum of the specified string.
    ---
    ---@param raw_str string The string is used to calculate checksum.
    ---@return integer checksum The checksum value, which is greater or equal to 0, and less than 2^16 (0x10000).
    function Fletcher16Class.digest( raw_str )
        return fletcher16:reset():update( raw_str ):digest()
    end

end

--- [SHARED AND MENU]
---
--- The Fletcher-32 checksum calculation object.
---
---@class dreamwork.std.checksum.Fletcher32 : dreamwork.std.checksum.Fletcher16
---@field __parent dreamwork.std.checksum.Fletcher16
---@field __class dreamwork.std.checksum.Fletcher32Class
local Fletcher32 = class.base( "checksum.Fletcher32", false, Fletcher16Class )

Fletcher32.DigestSize = 4

---@alias Fletcher32 dreamwork.std.checksum.Fletcher32

---@protected
function Fletcher32:__init()
    self:reset()
end

--- [SHARED AND MENU]
---
--- Updates checksum with the specified string.
---
---@param raw_str string The string is used to update checksum.
---@return dreamwork.std.checksum.Fletcher32 self
function Fletcher32:update( raw_str )
    local a, b = self.a, self.b

    for i = 1, string_len( raw_str ), 1 do
        a = ( a + string_byte( raw_str, i, i ) ) % 0xFFFF
        b = ( b + a ) % 0xFFFF
    end

    self.a, self.b = a, b
    return self
end

--- [SHARED AND MENU]
---
--- Finalizes checksum calculation and returns the resulting checksum.
---
---@return integer checksum The final checksum value, which is greater or equal to 0, and less than 2^32 (0x100000000).
function Fletcher32:digest()
    return ( self.b * 0x10000 ) + self.a
end

--- [SHARED AND MENU]
---
--- The Fletcher-32 checksum calculation class.
---
--- See [Fletcher's checksum](https://en.wikipedia.org/wiki/Fletcher%27s_checksum) for the definition of the Fletcher-32 checksum.
---
---@class dreamwork.std.checksum.Fletcher32Class : dreamwork.std.checksum.Fletcher32
---@field __parent dreamwork.std.checksum.Fletcher16Class
---@field __base dreamwork.std.checksum.Fletcher32
---@overload fun(): dreamwork.std.checksum.Fletcher32
local Fletcher32Class = class.create( Fletcher32 )
checksum.Fletcher32 = Fletcher32Class

do

    local fletcher32 = Fletcher32Class()

    --- [SHARED AND MENU]
    ---
    --- Calculates the Fletcher-32 checksum of the specified string.
    ---
    ---@param raw_str string The string is used to calculate checksum.
    ---@return integer checksum The checksum value, which is greater or equal to 0, and less than 2^32 (0x100000000).
    function Fletcher32Class.digest( raw_str )
        return fletcher32:reset():update( raw_str ):digest()
    end

end
