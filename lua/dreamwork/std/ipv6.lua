---@class dreamwork.std
local std               = dreamwork.std

local setmetatable      = std.setmetatable

local math              = std.math
local math_clamp        = math.clamp
local math_relative     = math.relative
local math_min          = math.min

local string            = std.string
local string_len        = string.len
local string_byte       = string.byte
local string_rep        = string.rep
local string_format     = string.format
local string_toNumber   = string.toNumber

local bit               = std.bit
local bit_bnot          = bit.bnot
local bit_rshift        = bit.rshift
local bit_lshift        = bit.lshift
local bit_unsign        = bit.unsign
local bit_band, bit_bor = bit.band, bit.bor

local table             = std.table
local table_concat      = table.concat

local class             = std.class

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- A object that representing IPv6 address.
---
---@class dreamwork.std.IPv6 : dreamwork.std.Object
---@field __class dreamwork.std.IPv6Class
---@field [ 1 ] integer
---@field [ 2 ] integer
---@field [ 3 ] integer
---@field [ 4 ] integer
---@field [ 5 ] integer
---@field [ 6 ] integer
---@field [ 7 ] integer
---@field [ 8 ] integer
local IPv6              = class.base( "IPv6", false )

---@protected
function IPv6:__new( group1, group2, group3, group4, group5, group6, group7, group8 )
    return setmetatable( {
        group1 or 0, group2 or 0, group3 or 0, group4 or 0,
        group5 or 0, group6 or 0, group7 or 0, group8 or 0
    }, IPv6 )
end

---@protected
---@return string
function IPv6:__tostring()
    local best_start, best_len = 0, 0
    local start = 0

    for i = 1, 8 do
        if self[ i ] == 0 then
            start = start ~= 0 and start or i

            local len = i - start + 1
            if len > best_len then
                best_start, best_len = start, len
            end
        else
            start = 0
        end
    end

    if best_len < 2 then
        return string_format(
            "%x:%x:%x:%x:%x:%x:%x:%x",
            self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ],
            self[ 5 ], self[ 6 ], self[ 7 ], self[ 8 ]
        )
    end

    local left, right

    if best_start > 1 then
        left = string_format( string_rep( "%x:", best_start - 1 ), unpack( self, 1, best_start - 1 ) )
    else
        left = ":"
    end

    local right_count = 8 - (best_start + best_len) + 1
    if right_count > 0 then
        right = string_format( string_rep( ":%x", right_count ), unpack( self, best_start + best_len, 8 ) )
    else
        right = ":"
    end

    return left .. right
end

---@protected
---@return string
function IPv6:__represent()
    return string_format( "IPv6: %p [%s]", self, self )
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Class that contains methods and properties for working with Internet Protocol v6 addresses as objects.
---
---@class dreamwork.std.IPv6Class : dreamwork.std.IPv6
---@field __base dreamwork.std.IPv6
---@overload fun( group1: integer?, group2: integer?, group3: integer?, group4: integer?, group5: integer?, group6: integer?, group7: integer?, group8: integer? ): dreamwork.std.IPv6
local IPv6Class = class.create( IPv6 )
std.IPv6 = IPv6Class

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

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Parses an IPv6 address string (with optional CIDR prefix) into a object
--- and a prefix length.
---
--- Handles the embedded "::" expansion and an optional trailing "/prefix".
---
---@param ipv6_str string The IPv6 address string, e.g. "2001:db8::1/32".
---@param start_position? integer
---@param end_position? integer
---@param str_length? integer
---@return dreamwork.std.IPv6 address
---@return integer mask Prefix length (0-128).
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

    ---@cast start_position integer

    if end_position == nil then
        end_position = str_length
    elseif end_position < 0 then
        end_position = math_relative( end_position, str_length )
    else
        end_position = math_min( end_position, str_length )
    end

    ---@cast end_position integer

    local mask = 128

    for index = start_position, end_position, 1 do
        if string_byte( ipv6_str, index, index ) == 0x2F --[[ / ]] then
            mask = math_clamp( string_toNumber( ipv6_str, 16, index + 1, end_position ) or 128, 0, 128 ) or 0
            end_position = index - 1
            break
        end
    end

    local double_colon_start = 0

    for index = start_position, end_position - 1, 1 do
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

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Compare two IPv6 addresses (length-8 uint16 arrays).
---
---@param a dreamwork.std.IPv6
---@param b dreamwork.std.IPv6
---@return (`-1` | `0` | `1`)
local function compare( a, b )
    for i = 1, 8 do
        if a[ i ] < b[ i ] then
            return -1
        elseif a[ i ] > b[ i ] then
            return 1
        end
    end

    return 0
end

---@param b dreamwork.std.IPv6
---@return boolean
---@protected
function IPv6:__eq( b )
    return compare( self, b ) == 0
end

---@param b dreamwork.std.IPv6
---@return boolean
---@protected
function IPv6:__lt( b )
    return compare( self, b ) == -1
end

---@param b dreamwork.std.IPv6
---@return boolean
---@protected
function IPv6:__le( b )
    return compare( self, b ) <= 0
end

---@return integer
---@protected
function IPv6:__len()
    return 8
end

---@return dreamwork.std.IPv6
---@protected
function IPv6:__unm()
    return setmetatable( {
        bit_bnot( self[ 1 ] ) % 0x10000,
        bit_bnot( self[ 2 ] ) % 0x10000,
        bit_bnot( self[ 3 ] ) % 0x10000,
        bit_bnot( self[ 4 ] ) % 0x10000,
        bit_bnot( self[ 5 ] ) % 0x10000,
        bit_bnot( self[ 6 ] ) % 0x10000,
        bit_bnot( self[ 7 ] ) % 0x10000,
        bit_bnot( self[ 8 ] ) % 0x10000
    }, IPv6 )
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
---
---
---@param network dreamwork.std.IPv6
---@param broadcast dreamwork.std.IPv6
function IPv6:inRange( network, broadcast )
    return compare( self, network ) >= 0 and compare( self, broadcast ) <= 0
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Build a length-8 uint16 mask from a prefix length (0-128).
---
---@param prefix integer
---@return dreamwork.std.IPv6
local function fromPrefix( prefix )
    local mask = {}

    for i = 1, 8, 1 do
        local bits = math_clamp( prefix - (i - 1) * 16, 0, 16 )
        local value = 0

        if bits == 16 then
            value = 0xFFFF
        elseif bits == 0 then
            value = 0x0000
        else
            value = bit_unsign( bit_bnot( bit_rshift( 0xFFFF, bits ) ) ) % 0x10000
        end

        mask[ i ] = value
    end

    setmetatable( mask, IPv6 )
    return mask
end

IPv6Class.fromPrefix = fromPrefix

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns the network address and broadcast (last) address for a given IPv6
--- address and prefix length.
---
---@param mask integer Prefix length (0-128).
---@return dreamwork.std.IPv6 network_address
---@return dreamwork.std.IPv6 broadcast_address
function IPv6:cidr( mask )
    local prefix            = fromPrefix( mask )

    local network_address   = {}
    local broadcast_address = {}

    for i = 1, 8 do
        network_address[ i ] = bit_band( self[ i ], prefix[ i ] ) % 0x10000
        broadcast_address[ i ] = bit_bor( network_address[ i ], bit_bnot( prefix[ i ] ) % 0x10000 ) % 0x10000
    end

    setmetatable( network_address, IPv6 )
    setmetatable( broadcast_address, IPv6 )

    return network_address, broadcast_address
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns the reverse DNS pointer (ip6.arpa) for an IPv6 address.
---
---@return string ptr
function IPv6:reversePointer()
    local nibbles = {}

    for i = 8, 1, -1 do
        local g = self[ i ]

        nibbles[ 9 - i ] = string_format(
            "%x.%x.%x.%x",
            bit_band( g, 0xF ),
            bit_band( bit_rshift( g, 4 ), 0xF ),
            bit_band( bit_rshift( g, 8 ), 0xF ),
            bit_band( bit_rshift( g, 12 ), 0xF )
        )
    end

    return table_concat( nibbles, "." ) .. ".ip6.arpa"
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns whether the address is the unspecified address (::).
---
---@return boolean is_unspecified
function IPv6:isUnspecified()
    for i = 1, 8 do
        if self[ i ] ~= 0 then
            return false
        end
    end

    return true
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns whether the address is the loopback address (::1).
---
---@return boolean is_loopback
function IPv6:isLoopback()
    for i = 1, 7 do
        if self[ i ] ~= 0 then return false end
    end

    return self[ 8 ] == 1
end

---@param cidr_str string
---@return fun( ip_address: dreamwork.std.IPv6 ): boolean
local function gen_in_range( cidr_str )
    local address, prefix = IPv6Class.parse( cidr_str )
    local network, broadcast = address:cidr( prefix )

    return function( ip_address )
        return ip_address:inRange( network, broadcast )
    end
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns whether the address is a multicast address (ff00::/8).
---
IPv6.isMulticast = gen_in_range( "ff00::/8" )

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns whether the address is a link-local unicast address (fe80::/10).
---
IPv6.isLinkLocal = gen_in_range( "fe80::/10" )

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns whether the address is a site-local unicast address (fec0::/10).
--- Note: deprecated by RFC 3879 but still recognisable.
---
IPv6.isSiteLocal = gen_in_range( "fec0::/10" )

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns whether the address is a unique-local address (fc00::/7, RFC 4193).
---
IPv6.isUniqueLocal = gen_in_range( "fc00::/7" )

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns whether the address is a documentation / example address
--- (2001:db8::/32, RFC 3849).
---
IPv6.isDocumentation = gen_in_range( "2001:db8::/32" )

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns whether the address is a 6to4 address
--- (2002::/16, RFC 3056).
---
IPv6.is6to4 = gen_in_range( "2002::/16" )

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns whether the address is a Teredo address
--- (2001::/32, RFC 4380).
---
IPv6.isTeredo = gen_in_range( "2001::/32" )

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns whether the address is an IPv4-mapped IPv6 address
--- (::ffff:a.b.c.d).
---
---@return boolean
function IPv6:isIPv4Mapped()
    return self[ 1 ] == 0
        and self[ 2 ] == 0
        and self[ 3 ] == 0
        and self[ 4 ] == 0
        and self[ 5 ] == 0
        and self[ 6 ] == 0xFFFF
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns whether the address is an IPv4-compatible IPv6 address
--- (::a.b.c.d).
--- Note: deprecated by RFC 4291.
---
---@return boolean
function IPv6:isIPv4Compatible()
    return self[ 1 ] == 0
        and self[ 2 ] == 0
        and self[ 3 ] == 0
        and self[ 4 ] == 0
        and self[ 5 ] == 0
        and self[ 6 ] == 0
        and not self:isUnspecified()
        and not self:isLoopback()
end

local discard_net, discard_last = IPv6Class.parse( "100::" ):cidr( 64 )

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns whether the address belongs to a private/local-use range.
---
---@return boolean
function IPv6:isPrivate()
    return self:isUnspecified()
        or self:isLoopback()
        or self:isLinkLocal()
        or self:isSiteLocal()
        or self:isUniqueLocal()
        or self:inRange( discard_net, discard_last )
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns whether the address belongs to a special-purpose range.
---
---@return boolean
function IPv6:isReserved()
    return self:isDocumentation()
        or self:isIPv4Mapped()
        or self:isIPv4Compatible()
        or self:is6to4()
        or self:isTeredo()
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns whether the address is a global unicast address.
---
---@return boolean
function IPv6:isGlobalUnicast()
    return not self:isMulticast()
        and not self:isUnspecified()
        and not self:isLoopback()
        and not self:isLinkLocal()
        and not self:isSiteLocal()
        and not self:isUniqueLocal()
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns whether the address is globally routable.
---
---@return boolean
function IPv6:isPublic()
    return self:isGlobalUnicast()
        and not self:isReserved()
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Extracts the embedded IPv4 address from an IPv4-mapped or
--- IPv4-compatible IPv6 address and returns it as a v4-style uint32.
---
--- This function always return IPv4 address even if address is not IPv4-mapped or
--- IPv4-compatible.
---
--- So I recommend to validate address before calling this method.
---
---@see IPv6:isIPv4Mapped()
---@see IPv6:isIPv4Compatible()
---
---@return dreamwork.std.IPv4 ipv4_address
function IPv6:toIPv4()
    return bit_unsign( bit_bor( bit_lshift( self[ 7 ], 0x10 ), bit_band( self[ 8 ], 0xFFFF ) ) )
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Constructs an IPv4-mapped IPv6 address (::ffff:a.b.c.d) from a v4 uint32.
---
---@param ipv4_address dreamwork.std.IPv4
---@return dreamwork.std.IPv6 ipv6_address
function IPv6Class.fromIPv4( ipv4_address )
    return setmetatable( {
        0, 0, 0, 0, 0,
        0xFFFF,
        bit_band( bit_rshift( ipv4_address, 0x10 ), 0xFFFF ),
        bit_band( ipv4_address, 0xFFFF ),
    }, IPv6 )
end
