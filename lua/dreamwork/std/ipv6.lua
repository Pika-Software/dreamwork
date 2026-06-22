---@class dreamwork.std
local std                         = dreamwork.std

local math                        = std.math
local math_clamp                  = math.clamp
local math_relative               = math.relative
local math_min, math_max          = math.min, math.max

local string                      = std.string
local string_len                  = string.len
local string_byte                 = string.byte
local string_format               = string.format
local string_findByte             = string.findByte
local string_toNumber             = string.toNumber

local bit                         = std.bit
local bit_bnot                    = bit.bnot
local bit_rshift                  = bit.rshift
local bit_lshift                  = bit.lshift
local bit_unsign                  = bit.unsign
local bit_bxor, bit_band, bit_bor = bit.bxor, bit.band, bit.bor

local class                       = std.class

--[[
    IPv6 is represented as two 32-bit Lua integers (high, low), each covering
    two 16-bit groups (hextets).  hi holds groups 1-4, lo holds groups 5-8.

    Group layout inside a 32-bit word:
        bits 31-16 = first group
        bits 15-0  = second group

    Where "group" index N (1-based, left to right):
        hi -> groups 1-2  (bits 31-16 and 15-0 of hi)
        lo -> groups 3-4  (bits 31-16 and 15-0 of lo)
        ... etc.

    Because Lua's bit library works on 32-bit signed integers we store groups
    as 16-bit values packed into 32-bit ints and use bit_unsign where a
    non-negative result is required.
]]

--- An IPv6 address is a table of four 16-bit unsigned integers (host groups 1-8,
--- two groups per cell stored separately for clarity, or just store all 8 groups).

--- For simplicity we represent an IPv6 address as a plain array of 8 integers,
--- each in [0, 65535], indexed 1-8 (most significant first).

---@class dreamwork.std.IPv6 : dreamwork.std.Object
---@field __class dreamwork.std.IPv6Class
local IPv6 = class.base( "IPv6", false )

---@protected
---@return string
function IPv6:__tostring()
    return string_format( "%04x:%04x:%04x:%04x:%04x:%04x:%04x:%04x", self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ], self[ 5 ], self[ 6 ], self[ 7 ], self[ 8 ] )
end

---@protected
---@return string
function IPv6:__represent()
    return string_format( "IPv6: %p [%04x:%04x:%04x:%04x:%04x:%04x:%04x:%04x]", self, self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ], self[ 5 ], self[ 6 ], self[ 7 ], self[ 8 ] )
end

--- [SHARED AND MENU]
---
--- Class that contains methods and properties for working with Internet Protocol v6 addresses as objects.
---
---@class dreamwork.std.IPv6Class : dreamwork.std.IPv6
---@field __base dreamwork.std.IPv6
---@field [ 1 ] integer
---@field [ 2 ] integer
---@field [ 3 ] integer
---@field [ 4 ] integer
---@field [ 5 ] integer
---@field [ 6 ] integer
---@field [ 7 ] integer
---@field [ 8 ] integer
local IPv6Class = class.create( IPv6 )
std.IPv6 = IPv6

---@param str string
---@param str_start integer
---@param str_end integer
---@param stack_level integer
local function parse_number( str, str_start, str_end, stack_level )
    stack_level = stack_level + 1

    local integer = string_toNumber( str, 16, str_start, str_end )
    if integer == nil then
        std.errorf( stack_level, false, "invalid characters in ipv6 group %d:%d", str_start, str_end )
    elseif integer < 0 then
        std.errorf( stack_level, false, "ipv6 group %d:%d cannot be negative", str_start, str_end )
    elseif integer > 65535 then
        std.errorf( stack_level, false, "ipv6 group %d:%d out of range %d > 65535", str_start, str_end, integer )
    end

    return integer
end

---@param str string
---@param str_start integer
---@param str_end integer
---@param stack_level integer
local function parse_group( str, str_start, str_end, stack_level )
    stack_level       = stack_level + 1

    ---@type integer[]
    local groups      = {}

    ---@type integer
    local group_count = 0

    if ((str_end - str_start) + 1) ~= 0 then
        local segment_start = str_start
        local index = str_start

        ::group_parse_loop::

        if string_byte( str, index, index ) == 0x3A --[[ : ]] then
            group_count = group_count + 1
            groups[ group_count ] = parse_number( str, segment_start, index - 1, stack_level )
            segment_start = index + 1
        end

        if index == str_end then
            group_count = group_count + 1
            groups[ group_count ] = parse_number( str, segment_start, index, stack_level )
        else
            index = index + 1
            goto group_parse_loop
        end
    end

    return groups, group_count
end

--- Split a colon-separated hex string into an array of group values.
--- Handles the embedded "::" expansion and an optional trailing "/prefix".
---
---@param ipv6_str string
---@param start_position? integer
---@param end_position? integer
---@param str_length? integer
---@return dreamwork.std.IPv6 groups   Length-8 array of uint16
---@return integer   mask     Prefix length 0-128
function IPv6Class.parse( ipv6_str, start_position, end_position, str_length )
    if str_length == nil then
        str_length = string_len( ipv6_str )
    end

    if start_position == nil then
        start_position = 1
    elseif start_position < 0 then
        start_position = math_relative( start_position, str_length )
    else
        start_position = math_min( start_position, str_length )
    end

    if end_position == nil then
        end_position = str_length
    elseif end_position < 0 then
        end_position = math_relative( end_position, str_length )
    else
        end_position = math_min( end_position, str_length )
    end

    local mask = 128

    for index = start_position, end_position, 1 do
        if string_byte( ipv6_str, index, index ) == 0x2F --[[ / ]] then
            mask = math_clamp( string_toNumber( ipv6_str, 16, index + 1, end_position ) or 128, 0, 128 ) or 0
            end_position = index - 1
            break
        end
    end

    local double_colon_start = 0

    for index = start_position, end_position, 2 do
        local uint8_1, uint8_2 = string_byte( ipv6_str, index, index + 1 )
        if uint8_1 == 0x3A --[[ : ]] and uint8_2 == 0x3A --[[ : ]] then
            double_colon_start = index
            break
        end
    end

    if double_colon_start == 0 then
        local groups, group_count = parse_group( ipv6_str, start_position, end_position, 2 )
        if group_count ~= 8 then
            std.errorf( 2, false, "ipv6 address must have strictly 8 groups, got %d", group_count )
        end

        setmetatable( groups, IPv6 )
        return groups, mask
    end

    local left_groups, left_group_count   = parse_group( ipv6_str, start_position, double_colon_start - 1, 2 )
    local right_groups, right_group_count = parse_group( ipv6_str, double_colon_start + 2, end_position, 2 )

    local total_group_count               = left_group_count + right_group_count
    if total_group_count > 8 then
        std.errorf( 2, false, "too many ipv6 groups, max 8" )
    end

    ---@type integer[]
    local groups = {}

    ---@type integer
    local group_count = 0

    for i = 1, left_group_count, 1 do
        group_count = group_count + 1
        groups[ group_count ] = left_groups[ i ]
    end

    for i = 1, 8 - total_group_count, 1 do
        group_count = group_count + 1
        groups[ group_count ] = 0
    end

    for i = 1, right_group_count, 1 do
        group_count = group_count + 1
        groups[ group_count ] = right_groups[ i ]
    end

    setmetatable( groups, IPv6 )
    return groups, mask
end
