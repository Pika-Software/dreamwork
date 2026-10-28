---@class dreamwork.std
local std = dreamwork.std

local string = std.string
local string_len = string.len
local string_byte = string.byte

local class = std.class

--- [SHARED AND MENU]
---
--- The Adler-32 checksum calculation object.
---
---@class dreamwork.std.Adler32 : dreamwork.std.Object
---@field __class dreamwork.std.Adler32Class
---@field DigestSize integer The size of the checksum in bytes.
---@field BlockSize integer The block size in bytes.
---@field protected a integer The first part of the checksum.
---@field protected b integer The second part of the checksum.
local Adler32 = class.base( "Adler32", false )

Adler32.DigestSize = 4
Adler32.BlockSize = 8

---@alias Adler32 dreamwork.std.Adler32

---@protected
function Adler32:__init()
    self:reset()
end

--- [SHARED AND MENU]
---
--- Resets checksum to the initial value.
---
---@return dreamwork.std.Adler32 self
function Adler32:reset()
    self.a, self.b = 1, 0
    return self
end

--- [SHARED AND MENU]
---
--- Updates checksum with the specified string.
---
---@param raw_str string The string is used to update checksum.
---@return dreamwork.std.Adler32 self
function Adler32:update( raw_str )
    local str_length = string_len( raw_str )
    local a, b = self.a, self.b

    -- sums stay exact in doubles ( < 2^53 ), so modulo is only needed once per chunk
    for chunk_start = 1, str_length, 0x1000 do
        local chunk_end = chunk_start + 0xFFF
        if chunk_end > str_length then
            chunk_end = str_length
        end

        local blocks_end = chunk_end - ( chunk_end - chunk_start + 1 ) % 8

        for index = chunk_start, blocks_end, 8 do
            local uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 = string_byte( raw_str, index, index + 7 )

            b = b + 8 * a + 8 * uint8_1 + 7 * uint8_2 + 6 * uint8_3 + 5 * uint8_4 + 4 * uint8_5 + 3 * uint8_6 + 2 * uint8_7 + uint8_8
            a = a + uint8_1 + uint8_2 + uint8_3 + uint8_4 + uint8_5 + uint8_6 + uint8_7 + uint8_8
        end

        for index = blocks_end + 1, chunk_end, 1 do
            a = a + string_byte( raw_str, index, index )
            b = b + a
        end

        a, b = a % 0xFFF1, b % 0xFFF1
    end

    self.a, self.b = a, b
    return self
end

--- [SHARED AND MENU]
---
--- Finalizes checksum calculation and returns the resulting checksum.
---
---@return integer checksum The final checksum value, which is greater or equal to 0, and less than 2^32 (0x100000000).
---@nodiscard
function Adler32:digest()
    return (self.b * 0x10000) + self.a
end

--- [SHARED AND MENU]
---
--- The class used to create new Adler-32 checksum calculation instances.
---
--- See [RFC1950](https://tools.ietf.org/html/rfc1950) for the definition of the Adler-32 checksum.
---
--- [Adler32 Online](https://md5calc.com/hash/adler32)
---
---@class dreamwork.std.Adler32Class : dreamwork.std.Adler32
---@field __base dreamwork.std.Adler32
---@overload fun(): dreamwork.std.Adler32
local Adler32Class = class.create( Adler32 )
std.Adler32 = Adler32Class

do

    local adler32 = Adler32Class()

    --- [SHARED AND MENU]
    ---
    --- Calculates the Adler-32 checksum of the specified string.
    ---
    ---@param raw_str string The string is used to calculate checksum.
    ---@return integer checksum The checksum value, which is greater or equal to 0, and less than 2^32 (0x100000000).
    ---@nodiscard
    function Adler32Class.digest( raw_str )
        return adler32:reset():update( raw_str ):digest()
    end

end
