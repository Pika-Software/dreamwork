---@class dreamwork.std
local std                         = dreamwork.std

local math                        = std.math
local math_clamp                  = math.clamp
local math_relative               = math.relative
local math_min, math_max          = math.min, math.max

local string                      = std.string
local string_len                  = string.len
local string_format               = string.format
local string_findByte             = string.findByte
local string_toNumber             = string.toNumber

local bit                         = std.bit
local bit_bnot                    = bit.bnot
local bit_lshift                  = bit.lshift
local bit_unsign                  = bit.unsign
local bit_bxor, bit_band, bit_bor = bit.bxor, bit.band, bit.bor

local bytepack                    = std.bytepack
local bytepack_readUInt32         = bytepack.readUInt32
local bytepack_writeUInt32        = bytepack.writeUInt32

---@alias dreamwork.std.IPv4.Class "A" | "B" | "C" | "D" | "E"
---@alias dreamwork.std.IPv4 integer

---@alias dreamwork.std.IPv6 string

--- [SHARED AND MENU]
---
--- The Internet Protocol library.
---
---@class dreamwork.std.ip
local ip                          = {}
std.ip                            = ip

--- [SHARED AND MENU]
---
--- Provides utility functions for working with IPv4 addresses.
---
---@class dreamwork.std.ip.v4
local v4                          = {}
ip.v4                             = v4

local bin_masks                   = {}

for i = 0, 32, 1 do
    bin_masks[ i ] = bit_lshift( (2 ^ i) - 1, 32 - i )
end

local bin_inverted_masks = {}

for i = 0, 32, 1 do
    bin_inverted_masks[ i ] = bit_bxor( bin_masks[ i ], bin_masks[ 32 ] )
end

--- [SHARED AND MENU]
---
--- Returns the octets of an IPv4 address.
---
---@param ip_address dreamwork.std.IPv4 The IP address.
---@return integer a The first octet. <0-255>
---@return integer b The second octet. <0-255>
---@return integer c The third octet. <0-255>
---@return integer d The fourth octet. <0-255>
function v4.octets( ip_address )
    local d, c, b, a = bytepack_writeUInt32( ip_address )
    return a, b, c, d
end

--- [SHARED AND MENU]
---
--- Build IPv4 address from octets.
---
---@param a integer The first octet. <0-255>
---@param b integer The second octet. <0-255>
---@param c integer The third octet. <0-255>
---@param d integer The fourth octet. <0-255>
---@return dreamwork.std.IPv4
local function fromOctets( a, b, c, d )
    return bytepack_readUInt32(
        math_clamp( d, 0, 255 ),
        math_clamp( c, 0, 255 ),
        math_clamp( b, 0, 255 ),
        math_clamp( a, 0, 255 )
    )
end

v4.fromOctets = fromOctets

--- [SHARED AND MENU]
---
--- Parses an IPv4 address octets string into an IP address and subnet mask.
---
---  Supports:
--- - **Hexadecimal**: prefixed with `0x` or `0X` (e.g., `0x7F`). Returns `0` if empty after prefix.
--- - **Octal**: prefixed with `0` followed by numbers (e.g., `0177`).
--- - **Decimal**: standard base-10 digits (e.g., `127`).
--- - **Empty/Missing**: returns `0` if the position is empty or invalid.
---
---@param ipv4_str string The full IPv4 address string to parse.
---@param start_position? integer The start position in the ipv4 string.
---@param end_position? integer The end position in the ipv4 string.
---@param str_length? integer The length of the ipv4 string. Optionally, it should be used to speed up calculations.
---@return dreamwork.std.IPv4 ip_address The parsed IP address.
---@return integer mask The subnet mask.
function v4.parse( ipv4_str, start_position, end_position, str_length )
    if str_length == nil then
        str_length = string_len( ipv4_str )
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

    local octets = { 0, 0, 0, 0 }
    local octet_index = 1

    local cdir_position = string_findByte( ipv4_str, 0x2F --[[ / ]], start_position, end_position, end_position )

    ::parse_octet::

    local octet_position = string_findByte( ipv4_str, 0x2E --[[ . ]], start_position, end_position, end_position )

    local octet_length
    if octet_position == nil then
        if cdir_position == nil then
            octet_length = (end_position - start_position) + 1
        else
            octet_length = cdir_position - start_position
        end
    else
        octet_length = octet_position - start_position
    end

    if octet_length > 0 then
        local octet = string_toNumber( ipv4_str, nil, start_position, start_position + (octet_length - 1) )
        if octet == nil then
            std.errorf( 2, false, "invalid characters in ipv4 octet %d", octet_index )
        elseif octet > 255 then
            std.errorf( 2, false, "ipv4 octet %d out of range %d > 255", octet_index, octet )
        elseif octet < 0 then
            std.errorf( 2, false, "ipv4 octet %d cannot be negative", octet_index )
        else
            octets[ octet_index ] = math_clamp( octet, 0, 255 )
        end

        if octet_position ~= nil then
            if octet_index == 4 then
                std.errorf( 2, false, "too many ipv4 octets, max 4" )
            end

            start_position = octet_position + 1
            octet_index = octet_index + 1
            goto parse_octet
        end
    else
        octet_index = octet_index - 1
    end

    if octet_index ~= 4 then
        octets[ 4 ], octets[ octet_index ] = octets[ octet_index ], 0
    end

    local mask = 32

    if cdir_position ~= nil then
        mask = math_clamp( string_toNumber( ipv4_str, 10, cdir_position + 1, end_position ) or 32, 0, 32 )
    end

    return fromOctets( octets[ 1 ], octets[ 2 ], octets[ 3 ], octets[ 4 ] ), mask
end

--- [SHARED AND MENU]
---
--- Returns the network address and boardcast address for a given IPv4 address and subnet mask.
---
---@param ip_address dreamwork.std.IPv4 The IP address.
---@param mask integer The subnet mask.
---@return dreamwork.std.IPv4 network_address The parsed network address.
---@return dreamwork.std.IPv4 boardcast_address The parsed boardcast address.
function v4.cdir( ip_address, mask )
    local network_address   = bit_band( ip_address, bin_masks[ mask ] )
    local boardcast_address = bit_bor( network_address, bin_inverted_masks[ mask ] )

    return bit_unsign( network_address ), bit_unsign( boardcast_address )
end

--- [SHARED AND MENU]
---
--- Returns the wildcard address of a network address and boardcast address.
---
---@param network_address dreamwork.std.IPv4 The network address.
---@param boardcast_address dreamwork.std.IPv4 The boardcast address.
---@return dreamwork.std.IPv4 wildcard_address The wildcard address.
function v4.wildcard( network_address, boardcast_address )
    return bit_bxor( network_address, boardcast_address )
end

--- [SHARED AND MENU]
---
--- Returns the mask of a network address and boardcast address.
---
---@param network_address dreamwork.std.IPv4 The network address.
---@param boardcast_address dreamwork.std.IPv4 The boardcast address.
---@return dreamwork.std.IPv4 mask_address The mask of the network address and boardcast address.
function v4.mask( network_address, boardcast_address )
    return bit_bnot( bit_bxor( network_address, boardcast_address ) )
end

--- [SHARED AND MENU]
---
--- Returns the range of an IPv4 address range.
---
---@param network_address dreamwork.std.IPv4 The network address.
---@param boardcast_address dreamwork.std.IPv4 The boardcast address.
---@return dreamwork.std.IPv4 first The first address in the range.
---@return dreamwork.std.IPv4 last The last address in the range.
function v4.range( network_address, boardcast_address )
    return network_address + 1, boardcast_address - 1
end

--- [SHARED AND MENU]
---
--- Returns the number of addresses in an IPv4 address range.
---
---@param network_address dreamwork.std.IPv4 The network address.
---@param boardcast_address dreamwork.std.IPv4 The boardcast address.
---@return dreamwork.std.IPv4 total_count The total number of addresses in the range.
---@return dreamwork.std.IPv4 usable_count The number of usable addresses in the range.
function v4.count( network_address, boardcast_address )
    local diff = boardcast_address - network_address
    return diff + 1, diff - 1
end

--- [SHARED AND MENU]
---
--- Returns the string representation of an IPv4 address.
---
---@param ip_address dreamwork.std.IPv4 The IP address.
---@return string str The string representation of the IP address.
function v4.toString( ip_address )
    local d, c, b, a = bytepack_writeUInt32( ip_address )
    return string_format( "%d.%d.%d.%d", a, b, c, d )
end

--- [SHARED AND MENU]
---
--- Returns the reverse pointer of an IPv4 address.
---
---@param ip_address dreamwork.std.IPv4 The IP address.
---@return string str The reverse pointer of the IP address.
function v4.reversePointer( ip_address )
    local d, c, b, a = bytepack_writeUInt32( ip_address )
    return string_format( "%d.%d.%d.%d.in-addr.arpa", a, b, c, d )
end

do

    --- [SHARED AND MENU]
    ---
    --- Returns whether an IP address is within a given range.
    ---
    ---@param ip_address dreamwork.std.IPv4 The IP address.
    ---@param network_address dreamwork.std.IPv4 The network address.
    ---@param boardcast_address dreamwork.std.IPv4 The boardcast address.
    ---@return boolean in_range Whether the IP address is within the range.
    local function inRange( ip_address, network_address, boardcast_address )
        return ip_address >= network_address and ip_address <= boardcast_address
    end

    v4.inRange = inRange

    ---@param str string The network address in CIDR notation.
    ---@return fun( ip_address: dreamwork.std.IPv4 ): boolean
    local function gen_in_range( str )
        local network_address, boardcast_address = v4.cdir( v4.parse( str ) )
        return function( ip_address )
            return inRange( ip_address, network_address, boardcast_address )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Returns whether an IP address is a link-local address.
    ---
    v4.isLinkLocal = gen_in_range( "169.254.0.0/16" )

    --- [SHARED AND MENU]
    ---
    --- Returns whether an IP address is a loopback address.
    ---
    v4.isLoopback = gen_in_range( "127.0.0.0/8" )

    --- [SHARED AND MENU]
    ---
    --- Returns whether an IP address is a multicast address.
    ---
    v4.isMulticast = gen_in_range( "224.0.0.0/4" )

    --- [SHARED AND MENU]
    ---
    --- Returns whether an IP address is reserved.
    ---
    v4.isReserved = gen_in_range( "240.0.0.0/4" )

    --- [SHARED AND MENU]
    ---
    --- Returns whether an IP address is the unspecified address.
    ---
    ---@param ip_address dreamwork.std.IPv4 The IP address to check.
    ---@return boolean Whether the IP address is the unspecified address.
    function v4.isUnspecified( ip_address )
        return ip_address == 0
    end

    ---@class dreamwork.std.ip.v4.NetworkVar
    ---@field [1] dreamwork.std.IPv4 The network address.
    ---@field [2] dreamwork.std.IPv4 The broadcast address.

    ---@param ranges string[]
    ---@return dreamwork.std.ip.v4.NetworkVar[], integer
    local function network_ranges( ranges )
        local range_count = #ranges
        local result = {}

        for i = 1, range_count, 1 do
            result[ i ] = { v4.cdir( v4.parse( ranges[ i ] ) ) }
        end

        return result, range_count
    end

    local private_ranges, private_count = network_ranges( {
        "0.0.0.0/8",
        "10.0.0.0/8",
        "127.0.0.0/8",
        "169.254.0.0/16",
        "172.16.0.0/12",
        "192.0.0.0/24",
        "192.0.0.170/31",
        "192.0.2.0/24",
        "192.168.0.0/16",
        "198.18.0.0/15",
        "198.51.100.0/24",
        "203.0.113.0/24",
        "240.0.0.0/4",
        "255.255.255.255/32",
    } )

    local private_range_exceptions, exception_count = network_ranges( {
        "192.0.0.9/32",
        "192.0.0.10/32",
        "100.64.0.0/10",
    } )

    --- [SHARED AND MENU]
    ---
    --- Returns whether the given IP address is private.
    ---
    ---@param ip_address dreamwork.std.IPv4 The IP address.
    ---@return boolean is_private Whether the IP address is private.
    local function isPrivate( ip_address )
        for i = 1, exception_count, 1 do
            local data = private_range_exceptions[ i ]
            if inRange( ip_address, data[ 1 ], data[ 2 ] ) then
                return false
            end
        end

        for i = 1, private_count, 1 do
            local data = private_ranges[ i ]
            if inRange( ip_address, data[ 1 ], data[ 2 ] ) then
                return true
            end
        end

        return false
    end

    v4.isPrivate = isPrivate

    --- [SHARED AND MENU]
    ---
    --- Returns whether the given IP address is public.
    ---
    ---@param ip_address dreamwork.std.IPv4 The IP address.
    ---@return boolean is_public Whether the IP address is public.
    function v4.isPublic( ip_address )
        return not isPrivate( ip_address )
    end

    local classes = {
        { "A", v4.parse( "0.0.0.0" ),   v4.parse( "127.255.255.255" ) },
        { "B", v4.parse( "128.0.0.0" ), v4.parse( "191.255.255.255" ) },
        { "C", v4.parse( "192.0.0.0" ), v4.parse( "223.255.255.255" ) },
        { "D", v4.parse( "224.0.0.0" ), v4.parse( "239.255.255.255" ) },
        -- { "E", v4.parse( "240.0.0.0" ), v4.parse( "255.255.255.255" ) },
    }

    --- [SHARED AND MENU]
    ---
    --- Returns the class of the given IP address.
    ---
    ---@param ip_address dreamwork.std.IPv4
    ---@return dreamwork.std.IPv4.Class
    function v4.class( ip_address )
        for i = 1, 4, 1 do
            local data = classes[ i ]
            if inRange( ip_address, data[ 2 ], data[ 3 ] ) then
                return data[ 1 ]
            end
        end

        return "E"
    end

end

--- [SHARED AND MENU]
---
--- Provides utility functions for working with IPv6 addresses.
---
---@class dreamwork.std.ip.v6
local v6 = {}
ip.v6 = v6

    -- Reverse the 32-nibble array
    local rev = {}
    for i = 32, 1, -1 do
        rev[ #rev + 1 ] = nibbles[ i ]
    end

    return table.concat( rev, "." ) .. ".ip6.arpa"
end

--- [SHARED AND MENU]
---
--- Returns the wildcard mask (host mask) for a given prefix length.
---
---@param mask integer  Prefix length (0-128).
---@return dreamwork.std.IPv6 wildcard
function v6.wildcardMask( mask )
    local m = build_prefix_mask( mask )
    local wc = {}
    for i = 1, 8 do
        wc[ i ] = bit_bnot( m[ i ] ) % 0x10000
    end

    return wc
end

--- [SHARED AND MENU]
---
--- Returns the first usable and last usable addresses in the subnet.
--- For IPv6 there is no concept of a reserved broadcast address, so the
--- range spans the entire subnet (network through last address).
---
---@param network_address dreamwork.std.IPv6 The network address.
---@param last_address    dreamwork.std.IPv6 The last address.
---@return dreamwork.std.IPv6 first
---@return dreamwork.std.IPv6 last
function v6.range( network_address, last_address )
    return network_address, last_address
end

--- [SHARED AND MENU]
---
--- Returns whether an IPv6 address is within the given network range.
---
---@param ip_address      dreamwork.std.IPv6
---@param network_address dreamwork.std.IPv6
---@param last_address    dreamwork.std.IPv6
---@return boolean
function v6.inRange( ip_address, network_address, last_address )
    return v6_in_range( ip_address, network_address, last_address )
end

-- ──────────────────────────────────────────────────
-- Address type predicates
-- ──────────────────────────────────────────────────

--- Helper: build a closure that tests membership in a CIDR block.
---@param cidr_str string
---@return fun( ip_address: dreamwork.std.IPv6 ): boolean
local function gen_in_range( cidr_str )
    local addr, prefix = split_v6( cidr_str )
    local net, last    = v6.cidr( addr, prefix )

    return function( ip_address )
        return v6_in_range( ip_address, net, last )
    end
end

--- [SHARED AND MENU]
---
--- Returns whether the address is the unspecified address (::).
---
---@param ip_address dreamwork.std.IPv6
---@return boolean
function v6.isUnspecified( ip_address )
    for i = 1, 8 do
        if ip_address[ i ] ~= 0 then return false end
    end

    return true
end

--- [SHARED AND MENU]
---
--- Returns whether the address is the loopback address (::1).
---
---@param ip_address dreamwork.std.IPv6
---@return boolean
function v6.isLoopback( ip_address )
    for i = 1, 7 do
        if ip_address[ i ] ~= 0 then return false end
    end

    return ip_address[ 8 ] == 1
end

--- [SHARED AND MENU]
---
--- Returns whether the address is a multicast address (ff00::/8).
---
v6.isMulticast = gen_in_range( "ff00::/8" )

--- [SHARED AND MENU]
---
--- Returns whether the address is a link-local unicast address (fe80::/10).
---
v6.isLinkLocal = gen_in_range( "fe80::/10" )

--- [SHARED AND MENU]
---
--- Returns whether the address is a site-local unicast address (fec0::/10).
--- Note: deprecated by RFC 3879 but still recognisable.
---
v6.isSiteLocal = gen_in_range( "fec0::/10" )

--- [SHARED AND MENU]
---
--- Returns whether the address is a unique-local address (fc00::/7, RFC 4193).
---
v6.isUniqueLocal = gen_in_range( "fc00::/7" )

--- [SHARED AND MENU]
---
--- Returns whether the address is an IPv4-mapped IPv6 address (::ffff:0:0/96).
---
v6.isIPv4Mapped = gen_in_range( "::ffff:0:0/96" )

--- [SHARED AND MENU]
---
--- Returns whether the address is an IPv4-compatible IPv6 address (::/96).
--- Note: deprecated by RFC 4291.
---
v6.isIPv4Compatible = gen_in_range( "::/96" )

--- [SHARED AND MENU]
---
--- Returns whether the address is a documentation / example address.
--- Covers 2001:db8::/32 (RFC 3849).
---
v6.isDocumentation = gen_in_range( "2001:db8::/32" )


-- TODO: ipv6
