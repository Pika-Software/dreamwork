---@class dreamwork.std
local std               = dreamwork.std

local setmetatable      = std.setmetatable

local math              = std.math
local math_clamp        = math.clamp
local math_range        = math.range

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

--- [SHARED AND MENU]
---
--- An object that represents an Internet Protocol v6 address as eight 16-bit groups.
---
--- Groups are stored in the array part of the object, `address[ 1 ]` is the most significant group.
---
--- Supports `tostring` (compressed [RFC 5952](https://datatracker.ietf.org/doc/html/rfc5952) form),
--- comparison operators (`==`, `<`, `<=`), the length operator (`#address` is always `8`)
--- and unary minus (`-address` is the bitwise NOT of the address).
---
---@class dreamwork.std.IPv6 : dreamwork.std.Object
---@field __class dreamwork.std.IPv6Class
---@field [ 1 ] integer The first group. <0-65535>
---@field [ 2 ] integer The second group. <0-65535>
---@field [ 3 ] integer The third group. <0-65535>
---@field [ 4 ] integer The fourth group. <0-65535>
---@field [ 5 ] integer The fifth group. <0-65535>
---@field [ 6 ] integer The sixth group. <0-65535>
---@field [ 7 ] integer The seventh group. <0-65535>
---@field [ 8 ] integer The eighth group. <0-65535>
local IPv6              = class.base( "IPv6", false )

---@param group1? integer The first group. <0-65535>
---@param group2? integer The second group. <0-65535>
---@param group3? integer The third group. <0-65535>
---@param group4? integer The fourth group. <0-65535>
---@param group5? integer The fifth group. <0-65535>
---@param group6? integer The sixth group. <0-65535>
---@param group7? integer The seventh group. <0-65535>
---@param group8? integer The eighth group. <0-65535>
---@return dreamwork.std.IPv6
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

--- [SHARED AND MENU]
---
--- Returns the string representation of the address in compressed [RFC 5952](https://datatracker.ietf.org/doc/html/rfc5952) form.
---
--- Same as `tostring( address )`.
---
--- ```lua
--- std.IPv6( 0x2001, 0xdb8, 0, 0, 0, 0, 0, 1 ):toString() -- "2001:db8::1"
--- ```
---
---@return string str The string representation of the address.
---@nodiscard
function IPv6:toString()
    return IPv6.__tostring( self )
end

--- [SHARED AND MENU]
---
--- Returns the groups of the address, from the most significant to the least significant.
---
---@return integer group1 The first group. <0-65535>
---@return integer group2 The second group. <0-65535>
---@return integer group3 The third group. <0-65535>
---@return integer group4 The fourth group. <0-65535>
---@return integer group5 The fifth group. <0-65535>
---@return integer group6 The sixth group. <0-65535>
---@return integer group7 The seventh group. <0-65535>
---@return integer group8 The eighth group. <0-65535>
---@nodiscard
function IPv6:groups()
    return self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ], self[ 5 ], self[ 6 ], self[ 7 ], self[ 8 ]
end

--- [SHARED AND MENU]
---
--- Class that contains methods and properties for working with Internet Protocol v6 addresses as objects.
---
--- Calling the class creates a new address from its groups, missing groups are `0`.
---
--- ```lua
--- local address = std.IPv6( 0x2001, 0xdb8, 0, 0, 0, 0, 0, 1 )
--- print( address ) -- 2001:db8::1
--- ```
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

--- [SHARED AND MENU]
---
--- Parses an IPv6 address string with an optional CIDR prefix length, e.g. `2001:db8::1/32`.
---
--- Handles the `::` zero-groups compression.
---
--- Embedded IPv4 notation (`::ffff:1.2.3.4`) and zone indices (`fe80::1%eth0`) are not supported.
---
--- Throws an error if a group contains invalid characters, is out of range or the address has a wrong number of groups.
---
---@param ipv6_str string The IPv6 address string to parse.
---@param start_position? integer The start position in the ipv6 string.
---@param end_position? integer The end position in the ipv6 string.
---@return dreamwork.std.IPv6 address The parsed IP address.
---@return integer prefix_length The CIDR prefix length. <0-128>, `128` if not specified.
---@nodiscard
function IPv6Class.parse( ipv6_str, start_position, end_position )
    local start_index, end_index = math_range( string_len( ipv6_str ), start_position, end_position )

    local mask = 128

    for index = start_index, end_index, 1 do
        if string_byte( ipv6_str, index, index ) == 0x2F --[[ / ]] then
            mask = math_clamp( string_toNumber( ipv6_str, 10, index + 1, end_index ) or 128, 0, 128 )
            end_index = index - 1
            break
        end
    end

    local double_colon_start = 0

    for index = start_index, end_index - 1, 1 do
        local uint8_1, uint8_2 = string_byte( ipv6_str, index, index + 1 )
        if uint8_1 == 0x3A --[[ : ]] and uint8_2 == 0x3A --[[ : ]] then
            double_colon_start = index
            break
        end
    end

    if double_colon_start == 0 then
        local groups, group_count = parse_group( ipv6_str, start_index, end_index, 2 )
        if group_count ~= 8 then
            std.errorf( 2, false, "ipv6 address must have strictly 8 groups, got %d", group_count )
        end

        setmetatable( groups, IPv6 )
        return groups, mask
    end

    local left_groups, left_group_count   = parse_group( ipv6_str, start_index, double_colon_start - 1, 2 )
    local right_groups, right_group_count = parse_group( ipv6_str, double_colon_start + 2, end_index, 2 )

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

--- Compares two IPv6 addresses group by group.
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

--- Returns the bitwise NOT of the address.
---
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

--- [SHARED AND MENU]
---
--- Returns whether the address is within a given network.
---
--- ```lua
--- local network, broadcast = std.IPv6.parse( "2001:db8::" ):cidr( 32 )
--- std.IPv6.parse( "2001:db8::1" ):inRange( network, broadcast ) -- true
--- ```
---
---@param network dreamwork.std.IPv6 The network (first) address.
---@param broadcast dreamwork.std.IPv6 The last address of the network.
---@return boolean in_range `true` if the address is within the network, `false` otherwise.
---@nodiscard
function IPv6:inRange( network, broadcast )
    return compare( self, network ) >= 0 and compare( self, broadcast ) <= 0
end

--- [SHARED AND MENU]
---
--- Returns the network mask address for a given CIDR prefix length.
---
--- ```lua
--- print( std.IPv6.fromPrefix( 64 ) ) -- ffff:ffff:ffff:ffff::
--- ```
---
---@param prefix integer The CIDR prefix length. <0-128>
---@return dreamwork.std.IPv6 mask_address The network mask address.
---@nodiscard
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

--- [SHARED AND MENU]
---
--- Returns the network address and the last address of the network for a given CIDR prefix length.
---
--- IPv6 has no broadcast, the "broadcast" address is just the last address of the network.
---
--- ```lua
--- local address, prefix_length = std.IPv6.parse( "2001:db8::1/32" )
--- local network, broadcast = address:cidr( prefix_length ) -- 2001:db8::, 2001:db8:ffff:ffff:ffff:ffff:ffff:ffff
--- ```
---
---@param mask integer The CIDR prefix length. <0-128>
---@return dreamwork.std.IPv6 network_address The network (first) address.
---@return dreamwork.std.IPv6 broadcast_address The last address of the network.
---@nodiscard
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

--- [SHARED AND MENU]
---
--- Returns the reverse DNS pointer (`ip6.arpa`) of the address.
---
--- ```lua
--- std.IPv6.parse( "2001:db8::1" ):reversePointer()
--- -- "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa"
--- ```
---
---@return string ptr The reverse DNS pointer of the address.
---@nodiscard
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

--- [SHARED AND MENU]
---
--- Returns whether the address is the unspecified address (`::`).
---
---@return boolean is_unspecified `true` if the address is the unspecified address, `false` otherwise.
---@nodiscard
function IPv6:isUnspecified()
    for i = 1, 8 do
        if self[ i ] ~= 0 then
            return false
        end
    end

    return true
end

--- [SHARED AND MENU]
---
--- Returns whether the address is the loopback address (`::1`).
---
---@return boolean is_loopback `true` if the address is the loopback address, `false` otherwise.
---@nodiscard
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

--- [SHARED AND MENU]
---
--- Returns whether the address is a multicast address (`ff00::/8`, [RFC 4291](https://datatracker.ietf.org/doc/html/rfc4291)).
---
IPv6.isMulticast = gen_in_range( "ff00::/8" )

--- [SHARED AND MENU]
---
--- Returns whether the address is a link-local unicast address (`fe80::/10`, [RFC 4291](https://datatracker.ietf.org/doc/html/rfc4291)).
---
IPv6.isLinkLocal = gen_in_range( "fe80::/10" )

--- [SHARED AND MENU]
---
--- Returns whether the address is a site-local unicast address (`fec0::/10`).
---
--- Site-local addresses are deprecated by [RFC 3879](https://datatracker.ietf.org/doc/html/rfc3879), but still recognized.
---
IPv6.isSiteLocal = gen_in_range( "fec0::/10" )

--- [SHARED AND MENU]
---
--- Returns whether the address is a unique-local address (`fc00::/7`, [RFC 4193](https://datatracker.ietf.org/doc/html/rfc4193)).
---
IPv6.isUniqueLocal = gen_in_range( "fc00::/7" )

--- [SHARED AND MENU]
---
--- Returns whether the address is reserved for documentation and examples (`2001:db8::/32`, [RFC 3849](https://datatracker.ietf.org/doc/html/rfc3849)).
---
IPv6.isDocumentation = gen_in_range( "2001:db8::/32" )

--- [SHARED AND MENU]
---
--- Returns whether the address is reserved for network benchmarking (`2001:2::/48`, [RFC 5180](https://datatracker.ietf.org/doc/html/rfc5180)).
---
IPv6.isBenchmarking = gen_in_range( "2001:2::/48" )

--- [SHARED AND MENU]
---
--- Returns whether the address is a discard-only address (`100::/64`, [RFC 6666](https://datatracker.ietf.org/doc/html/rfc6666)).
---
IPv6.isDiscard = gen_in_range( "100::/64" )

--- [SHARED AND MENU]
---
--- Returns whether the address is a 6to4 address (`2002::/16`, [RFC 3056](https://datatracker.ietf.org/doc/html/rfc3056)).
---
IPv6.is6to4 = gen_in_range( "2002::/16" )

--- [SHARED AND MENU]
---
--- Returns whether the address is a Teredo address (`2001::/32`, [RFC 4380](https://datatracker.ietf.org/doc/html/rfc4380)).
---
IPv6.isTeredo = gen_in_range( "2001::/32" )

--- [SHARED AND MENU]
---
--- Returns whether the address is an IPv4-mapped IPv6 address (`::ffff:a.b.c.d`, [RFC 4291](https://datatracker.ietf.org/doc/html/rfc4291)).
---
---@return boolean is_ipv4_mapped `true` if the address is an IPv4-mapped address, `false` otherwise.
---@nodiscard
function IPv6:isIPv4Mapped()
    return self[ 1 ] == 0
        and self[ 2 ] == 0
        and self[ 3 ] == 0
        and self[ 4 ] == 0
        and self[ 5 ] == 0
        and self[ 6 ] == 0xFFFF
end

--- [SHARED AND MENU]
---
--- Returns whether the address is an IPv4-compatible IPv6 address (`::a.b.c.d`).
---
--- IPv4-compatible addresses are deprecated by [RFC 4291](https://datatracker.ietf.org/doc/html/rfc4291).
---
--- The unspecified (`::`) and loopback (`::1`) addresses are not considered IPv4-compatible.
---
---@return boolean is_ipv4_compatible `true` if the address is an IPv4-compatible address, `false` otherwise.
---@nodiscard
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

--- [SHARED AND MENU]
---
--- Returns whether the address belongs to a private or local-use range.
---
--- Includes the unspecified, loopback, link-local, site-local, unique-local and discard-only addresses.
---
---@return boolean is_private `true` if the address is private, `false` otherwise.
---@nodiscard
function IPv6:isPrivate()
    return self:isUnspecified()
        or self:isLoopback()
        or self:isLinkLocal()
        or self:isSiteLocal()
        or self:isUniqueLocal()
        or self:isDiscard()
end

--- [SHARED AND MENU]
---
--- Returns whether the address belongs to a special-purpose range.
---
--- Includes the documentation, benchmarking, IPv4-mapped, IPv4-compatible, 6to4 and Teredo addresses.
---
---@return boolean is_reserved `true` if the address is reserved, `false` otherwise.
---@nodiscard
function IPv6:isReserved()
    return self:isDocumentation()
        or self:isBenchmarking()
        or self:isIPv4Mapped()
        or self:isIPv4Compatible()
        or self:is6to4()
        or self:isTeredo()
end

--- [SHARED AND MENU]
---
--- Returns whether the address is a global unicast address.
---
--- Any address that is not multicast, unspecified, loopback, link-local, site-local or unique-local.
---
---@return boolean is_global_unicast `true` if the address is a global unicast address, `false` otherwise.
---@nodiscard
function IPv6:isGlobalUnicast()
    return not self:isMulticast()
        and not self:isUnspecified()
        and not self:isLoopback()
        and not self:isLinkLocal()
        and not self:isSiteLocal()
        and not self:isUniqueLocal()
end

--- [SHARED AND MENU]
---
--- Returns whether the address is globally routable, i.e. a global unicast address that is not reserved.
---
---@return boolean is_public `true` if the address is public, `false` otherwise.
---@nodiscard
function IPv6:isPublic()
    return self:isGlobalUnicast()
        and not self:isReserved()
end

--- [SHARED AND MENU]
---
--- Extracts the embedded IPv4 address from an IPv4-mapped or IPv4-compatible address.
---
--- The last two groups are always returned as an IPv4 address, even if the address is
--- not IPv4-mapped or IPv4-compatible, so validate the address before calling this method.
---
--- ```lua
--- local address = std.IPv6.parse( "::ffff:7f00:1" )
--- if address:isIPv4Mapped() then
---     print( std.ipv4.toString( address:toIPv4() ) ) -- 127.0.0.1
--- end
--- ```
---
---@see dreamwork.std.IPv6.isIPv4Mapped
---@see dreamwork.std.IPv6.isIPv4Compatible
---
---@return dreamwork.std.IPv4 ipv4_address The embedded IPv4 address.
---@nodiscard
function IPv6:toIPv4()
    return bit_unsign( bit_bor( bit_lshift( self[ 7 ], 0x10 ), bit_band( self[ 8 ], 0xFFFF ) ) )
end

--- [SHARED AND MENU]
---
--- Creates an IPv4-mapped IPv6 address (`::ffff:a.b.c.d`) from an IPv4 address.
---
--- ```lua
--- print( std.IPv6.fromIPv4( 0x7F000001 ) ) -- ::ffff:7f00:1
--- ```
---
---@param ipv4_address dreamwork.std.IPv4 The IPv4 address.
---@return dreamwork.std.IPv6 ipv6_address The IPv4-mapped IPv6 address.
---@nodiscard
function IPv6Class.fromIPv4( ipv4_address )
    return setmetatable( {
        0, 0, 0, 0, 0,
        0xFFFF,
        bit_band( bit_rshift( ipv4_address, 0x10 ), 0xFFFF ),
        bit_band( ipv4_address, 0xFFFF ),
    }, IPv6 )
end
