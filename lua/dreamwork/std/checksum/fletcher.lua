---@class dreamwork.std
local std = dreamwork.std

local string = std.string
local string_len = string.len
local string_byte = string.byte

local class = std.class

--- [SHARED AND MENU]
---
--- The Fletcher-16 checksum calculation object.
---
---@class dreamwork.std.Fletcher16 : dreamwork.std.Object
---@field __class dreamwork.std.Fletcher16Class
---@field DigestSize integer The size of the checksum in bytes.
---@field protected a integer The first part of the checksum.
---@field protected b integer The second part of the checksum.
local Fletcher16 = class.base( "Fletcher16", false )

Fletcher16.DigestSize = 2

---@alias Fletcher16 dreamwork.std.Fletcher16

---@protected
function Fletcher16:__init()
    self:reset()
end

--- [SHARED AND MENU]
---
--- Resets checksum to the initial value.
---
---@return dreamwork.std.Fletcher16 self
function Fletcher16:reset()
    self.a, self.b = 0, 0
    return self
end

--- [SHARED AND MENU]
---
--- Updates checksum with the specified string.
---
---@param raw_str string The string is used to update checksum.
---@return dreamwork.std.Fletcher16 self
function Fletcher16:update( raw_str )
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

        a, b = a % 0xFF, b % 0xFF
    end

    self.a, self.b = a, b
    return self
end

--- [SHARED AND MENU]
---
--- Finalizes checksum calculation and returns the resulting checksum.
---
---@return integer checksum The final checksum value, which is greater or equal to 0, and less than 2^16 (0x10000).
---@nodiscard
function Fletcher16:digest()
    return (self.b * 0x0100) + self.a
end

--- [SHARED AND MENU]
---
--- The class used to create new Fletcher-16 checksum calculation instances.
---
--- See [Fletcher's checksum](https://en.wikipedia.org/wiki/Fletcher%27s_checksum) for the definition of the Fletcher-16 checksum.
---
--- [Fletcher Online](https://www.convertcase.com/hashing/fletcher-checksum)
---
---@class dreamwork.std.Fletcher16Class : dreamwork.std.Fletcher16
---@field __base dreamwork.std.Fletcher16
---@overload fun(): dreamwork.std.Fletcher16
local Fletcher16Class = class.create( Fletcher16 )
std.Fletcher16 = Fletcher16Class

do

    local fletcher16 = Fletcher16Class()

    --- [SHARED AND MENU]
    ---
    --- Calculates the Fletcher-16 checksum of the specified string.
    ---
    ---@param raw_str string The string is used to calculate checksum.
    ---@return integer checksum The checksum value, which is greater or equal to 0, and less than 2^16 (0x10000).
    ---@nodiscard
    function Fletcher16Class.digest( raw_str )
        return fletcher16:reset():update( raw_str ):digest()
    end

end

--- [SHARED AND MENU]
---
--- The Fletcher-32 checksum calculation object.
---
---@class dreamwork.std.Fletcher32 : dreamwork.std.Fletcher16
---@field __parent dreamwork.std.Fletcher16
---@field __class dreamwork.std.Fletcher32Class
---@field protected pending integer | nil The trailing byte of an odd-length update, waiting for its pair.
local Fletcher32 = class.base( "Fletcher32", false, Fletcher16Class )

Fletcher32.DigestSize = 4

---@alias Fletcher32 dreamwork.std.Fletcher32

---@protected
function Fletcher32:__init()
    self:reset()
end

--- [SHARED AND MENU]
---
--- Resets checksum to the initial value.
---
---@return dreamwork.std.Fletcher32 self
function Fletcher32:reset()
    self.a, self.b = 0, 0
    self.pending = nil
    return self
end

--- [SHARED AND MENU]
---
--- Updates checksum with the specified string.
---
--- The data is processed as little-endian 16-bit words.
---
---@param raw_str string The string is used to update checksum.
---@return dreamwork.std.Fletcher32 self
function Fletcher32:update( raw_str )
    local str_length = string_len( raw_str )
    if str_length == 0 then
        return self
    end

    local a, b = self.a, self.b
    local position = 1

    local pending = self.pending
    if pending ~= nil then
        a = ( a + pending + string_byte( raw_str, 1, 1 ) * 0x100 ) % 0xFFFF
        b = ( b + a ) % 0xFFFF
        position = 2
    end

    -- last byte of the last complete 16-bit word
    local words_end = str_length - ( str_length - position + 1 ) % 2

    -- sums stay exact in doubles ( < 2^53 ), so modulo is only needed once per chunk
    for chunk_start = position, words_end, 0x1000 do
        local chunk_end = chunk_start + 0xFFF
        if chunk_end > words_end then
            chunk_end = words_end
        end

        local blocks_end = chunk_end - ( chunk_end - chunk_start + 1 ) % 8

        for index = chunk_start, blocks_end, 8 do
            local uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 = string_byte( raw_str, index, index + 7 )

            local uint16_1 = uint8_1 + uint8_2 * 0x100
            local uint16_2 = uint8_3 + uint8_4 * 0x100
            local uint16_3 = uint8_5 + uint8_6 * 0x100
            local uint16_4 = uint8_7 + uint8_8 * 0x100

            b = b + 4 * a + 4 * uint16_1 + 3 * uint16_2 + 2 * uint16_3 + uint16_4
            a = a + uint16_1 + uint16_2 + uint16_3 + uint16_4
        end

        for index = blocks_end + 1, chunk_end, 2 do
            local uint8_1, uint8_2 = string_byte( raw_str, index, index + 1 )
            a = a + uint8_1 + uint8_2 * 0x100
            b = b + a
        end

        a, b = a % 0xFFFF, b % 0xFFFF
    end

    if words_end < str_length then
        self.pending = string_byte( raw_str, str_length, str_length )
    else
        self.pending = nil
    end

    self.a, self.b = a, b
    return self
end

--- [SHARED AND MENU]
---
--- Finalizes checksum calculation and returns the resulting checksum.
---
--- A trailing odd byte is padded with zero.
---
---@return integer checksum The final checksum value, which is greater or equal to 0, and less than 2^32 (0x100000000).
---@nodiscard
function Fletcher32:digest()
    local a, b = self.a, self.b

    local pending = self.pending
    if pending ~= nil then
        a = (a + pending) % 0xFFFF
        b = (b + a) % 0xFFFF
    end

    return (b * 0x10000) + a
end

--- [SHARED AND MENU]
---
--- The class used to create new Fletcher-32 checksum calculation instances.
---
--- See [Fletcher's checksum](https://en.wikipedia.org/wiki/Fletcher%27s_checksum) for the definition of the Fletcher-32 checksum.
---
--- [Fletcher Online](https://www.convertcase.com/hashing/fletcher-checksum)
---
---@class dreamwork.std.Fletcher32Class : dreamwork.std.Fletcher32
---@field __parent dreamwork.std.Fletcher16Class
---@field __base dreamwork.std.Fletcher32
---@overload fun(): dreamwork.std.Fletcher32
local Fletcher32Class = class.create( Fletcher32 )
std.Fletcher32 = Fletcher32Class

do

    local fletcher32 = Fletcher32Class()

    --- [SHARED AND MENU]
    ---
    --- Calculates the Fletcher-32 checksum of the specified string.
    ---
    ---@param raw_str string The string is used to calculate checksum.
    ---@return integer checksum The checksum value, which is greater or equal to 0, and less than 2^32 (0x100000000).
    ---@nodiscard
    function Fletcher32Class.digest( raw_str )
        return fletcher32:reset():update( raw_str ):digest()
    end

end
