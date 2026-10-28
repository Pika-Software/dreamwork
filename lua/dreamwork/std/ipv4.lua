---@class dreamwork.std
local std                         = dreamwork.std

local math                        = std.math
local math_clamp                  = math.clamp
local math_range                  = math.range

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
local bytepack_readUInt32         = bytepack.readUInt32BE
local bytepack_writeUInt32        = bytepack.writeUInt32BE

--- The classful network class of an IPv4 address, see [Classful network](https://en.wikipedia.org/wiki/Classful_network).
---@alias dreamwork.std.IPv4.Class "A" | "B" | "C" | "D" | "E"

--- An IPv4 address stored as an unsigned 32-bit integer in host order, e.g. `127.0.0.1` is `0x7F000001`.
---@alias dreamwork.std.IPv4 integer

--- [SHARED AND MENU]
---
--- Provides utility functions for working with Internet Protocol v4 addresses as integers.
---
--- Addresses are plain unsigned 32-bit integers (`dreamwork.std.IPv4`), so they can be compared,
--- sorted and used as table keys directly.
---
--- Networks are described by a prefix length (`0-32`) or by a pair of network and broadcast addresses,
--- which can be obtained with `ipv4.cidr`.
---
---@class dreamwork.std.ipv4
local ipv4                        = {}
std.ipv4                          = ipv4

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
--- Returns the octets of an IPv4 address, from the most significant to the least significant.
---
--- ```lua
--- ipv4.octets( 0x7F000001 ) -- 127, 0, 0, 1
--- ```
---
---@param ip_address dreamwork.std.IPv4 The IP address.
---@return integer a The first octet. <0-255>
---@return integer b The second octet. <0-255>
---@return integer c The third octet. <0-255>
---@return integer d The fourth octet. <0-255>
---@nodiscard
function ipv4.octets( ip_address )
    local d, c, b, a = bytepack_writeUInt32( ip_address )
    return a, b, c, d
end

--- [SHARED AND MENU]
---
--- Builds an IPv4 address from octets.
---
--- Octets out of the `0-255` range are clamped.
---
--- ```lua
--- ipv4.fromOctets( 127, 0, 0, 1 ) -- 0x7F000001
--- ```
---
---@param a integer The first octet. <0-255>
---@param b integer The second octet. <0-255>
---@param c integer The third octet. <0-255>
---@param d integer The fourth octet. <0-255>
---@return dreamwork.std.IPv4 ip_address The IP address.
---@nodiscard
local function fromOctets( a, b, c, d )
    return bytepack_readUInt32(
        math_clamp( d, 0, 255 ),
        math_clamp( c, 0, 255 ),
        math_clamp( b, 0, 255 ),
        math_clamp( a, 0, 255 )
    )
end

ipv4.fromOctets = fromOctets

--- [SHARED AND MENU]
---
--- Parses an IPv4 address string with an optional CIDR prefix length, e.g. `192.168.0.1/24`.
---
--- Each octet supports:
--- - **Hexadecimal**: prefixed with `0x` or `0X` (e.g., `0x7F`). Returns `0` if empty after prefix.
--- - **Octal**: prefixed with `0` followed by numbers (e.g., `0177`).
--- - **Decimal**: standard base-10 digits (e.g., `127`).
--- - **Empty/Missing**: returns `0` if the position is empty or invalid.
---
--- Addresses with fewer than 4 octets are accepted, the last given octet becomes the last octet
--- of the address, e.g. `127.1` is parsed as `127.0.0.1`.
---
--- Throws an error if an octet contains invalid characters, is out of range or there are more than 4 octets.
---
---@param ipv4_str string The IPv4 address string to parse.
---@param start_position? integer The start position in the ipv4 string.
---@param end_position? integer The end position in the ipv4 string.
---@return dreamwork.std.IPv4 ip_address The parsed IP address.
---@return integer prefix_length The CIDR prefix length. <0-32>, `32` if not specified.
---@nodiscard
function ipv4.parse( ipv4_str, start_position, end_position )
    local start_index, end_index = math_range( string_len( ipv4_str ), start_position, end_position )

    ---@type { [ 1 ]: integer, [ 2 ]: integer, [ 3 ]: integer, [ 4 ]: integer }
    local octets = { 0, 0, 0, 0 }

    ---@type integer
    local octet_index = 1

    local cdir_position = string_findByte( ipv4_str, 0x2F --[[ / ]], start_index, end_index )

    ::parse_octet::

    local octet_position = string_findByte( ipv4_str, 0x2E --[[ . ]], start_index, end_index )

    local octet_length
    if octet_position == nil then
        if cdir_position == nil then
            octet_length = (end_index - start_index) + 1
        else
            octet_length = cdir_position - start_index
        end
    else
        octet_length = octet_position - start_index
    end

    if octet_length > 0 then
        local octet = string_toNumber( ipv4_str, nil, start_index, start_index + (octet_length - 1) )
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

            start_index = octet_position + 1
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
        mask = math_clamp( string_toNumber( ipv4_str, 10, cdir_position + 1, end_index ) or 32, 0, 32 )
    end

    return fromOctets( octets[ 1 ], octets[ 2 ], octets[ 3 ], octets[ 4 ] ), mask
end

--- [SHARED AND MENU]
---
--- Returns the string representation of an IPv4 address in dotted-decimal notation.
---
--- ```lua
--- ipv4.toString( 0x7F000001 ) -- "127.0.0.1"
--- ```
---
---@param ip_address dreamwork.std.IPv4 The IP address.
---@return string str The string representation of the IP address.
---@nodiscard
function ipv4.toString( ip_address )
    local d, c, b, a = bytepack_writeUInt32( ip_address )
    return string_format( "%d.%d.%d.%d", a, b, c, d )
end

--- [SHARED AND MENU]
---
--- Returns the reverse DNS pointer (`in-addr.arpa`) of an IPv4 address.
---
--- ```lua
--- ipv4.reversePointer( 0x7F000001 ) -- "1.0.0.127.in-addr.arpa"
--- ```
---
---@param ip_address dreamwork.std.IPv4 The IP address.
---@return string ptr The reverse DNS pointer of the IP address.
---@nodiscard
function ipv4.reversePointer( ip_address )
    local d, c, b, a = bytepack_writeUInt32( ip_address )
    return string_format( "%d.%d.%d.%d.in-addr.arpa", d, c, b, a )
end

--- [SHARED AND MENU]
---
--- Returns the subnet mask address for a given CIDR prefix length.
---
--- ```lua
--- ipv4.fromPrefix( 24 ) -- 0xFFFFFF00 (255.255.255.0)
--- ```
---
---@param prefix_length integer The CIDR prefix length. <0-32>
---@return dreamwork.std.IPv4 mask_address The subnet mask address.
---@nodiscard
function ipv4.fromPrefix( prefix_length )
    return bit_unsign( bin_masks[ math_clamp( prefix_length, 0, 32 ) ] )
end

--- [SHARED AND MENU]
---
--- Returns the network address and broadcast address for a given IPv4 address and CIDR prefix length.
---
--- ```lua
--- ipv4.cidr( ipv4.parse( "192.168.1.42/24" ) ) -- 192.168.1.0, 192.168.1.255
--- ```
---
---@param ip_address dreamwork.std.IPv4 The IP address.
---@param prefix_length integer The CIDR prefix length. <0-32>
---@return dreamwork.std.IPv4 network_address The network (first) address.
---@return dreamwork.std.IPv4 broadcast_address The broadcast (last) address.
---@nodiscard
local function cidr( ip_address, prefix_length )
    local network_address   = bit_band( ip_address, bin_masks[ prefix_length ] )
    local broadcast_address = bit_bor( network_address, bin_inverted_masks[ prefix_length ] )

    return bit_unsign( network_address ), bit_unsign( broadcast_address )
end

ipv4.cidr = cidr

--- [SHARED AND MENU]
---
--- Returns the network address and broadcast address for a given IPv4 address and CIDR prefix length.
---
---@deprecated Use `ipv4.cidr` instead, this is a misspelled alias kept for compatibility.
---
---@param ip_address dreamwork.std.IPv4 The IP address.
---@param prefix_length integer The CIDR prefix length. <0-32>
---@return dreamwork.std.IPv4 network_address The network (first) address.
---@return dreamwork.std.IPv4 broadcast_address The broadcast (last) address.
---@nodiscard
function ipv4.cdir( ip_address, prefix_length )
    return cidr( ip_address, prefix_length )
end

--- [SHARED AND MENU]
---
--- Returns the wildcard (inverted subnet mask) address of a network, e.g. `0.0.0.255` for a `/24` network.
---
---@param network_address dreamwork.std.IPv4 The network address.
---@param broadcast_address dreamwork.std.IPv4 The broadcast address.
---@return dreamwork.std.IPv4 wildcard_address The wildcard address.
---@nodiscard
function ipv4.wildcard( network_address, broadcast_address )
    return bit_unsign( bit_bxor( network_address, broadcast_address ) )
end

--- [SHARED AND MENU]
---
--- Returns the subnet mask address of a network, e.g. `255.255.255.0` for a `/24` network.
---
---@param network_address dreamwork.std.IPv4 The network address.
---@param broadcast_address dreamwork.std.IPv4 The broadcast address.
---@return dreamwork.std.IPv4 mask_address The subnet mask address.
---@nodiscard
function ipv4.mask( network_address, broadcast_address )
    return bit_unsign( bit_bnot( bit_bxor( network_address, broadcast_address ) ) )
end

--- [SHARED AND MENU]
---
--- Returns the first and last usable host addresses of a network.
---
--- The network and broadcast addresses are excluded, so the result is meaningless for `/31` and `/32` networks.
---
---@param network_address dreamwork.std.IPv4 The network address.
---@param broadcast_address dreamwork.std.IPv4 The broadcast address.
---@return dreamwork.std.IPv4 first The first usable address in the network.
---@return dreamwork.std.IPv4 last The last usable address in the network.
---@nodiscard
function ipv4.range( network_address, broadcast_address )
    return network_address + 1, broadcast_address - 1
end

--- [SHARED AND MENU]
---
--- Returns the number of addresses in a network.
---
---@param network_address dreamwork.std.IPv4 The network address.
---@param broadcast_address dreamwork.std.IPv4 The broadcast address.
---@return integer total_count The total number of addresses in the network.
---@return integer usable_count The number of usable host addresses in the network, excluding the network and broadcast addresses.
---@nodiscard
function ipv4.count( network_address, broadcast_address )
    local diff = broadcast_address - network_address
    return diff + 1, diff - 1
end

do

    --- [SHARED AND MENU]
    ---
    --- Returns whether an IP address is within a given network.
    ---
    ---@param ip_address dreamwork.std.IPv4 The IP address.
    ---@param network_address dreamwork.std.IPv4 The network address.
    ---@param broadcast_address dreamwork.std.IPv4 The broadcast address.
    ---@return boolean in_range `true` if the IP address is within the network, `false` otherwise.
    ---@nodiscard
    local function inRange( ip_address, network_address, broadcast_address )
        return ip_address >= network_address and ip_address <= broadcast_address
    end

    ipv4.inRange = inRange

    ---@param str string The network address in CIDR notation.
    ---@return fun( ip_address: dreamwork.std.IPv4 ): boolean
    local function gen_in_range( str )
        local network_address, broadcast_address = cidr( ipv4.parse( str ) )
        return function( ip_address )
            return inRange( ip_address, network_address, broadcast_address )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Returns whether an IP address is a link-local address (`169.254.0.0/16`, [RFC 3927](https://datatracker.ietf.org/doc/html/rfc3927)).
    ---
    ipv4.isLinkLocal = gen_in_range( "169.254.0.0/16" )

    --- [SHARED AND MENU]
    ---
    --- Returns whether an IP address is a loopback address (`127.0.0.0/8`, [RFC 1122](https://datatracker.ietf.org/doc/html/rfc1122)).
    ---
    ipv4.isLoopback = gen_in_range( "127.0.0.0/8" )

    --- [SHARED AND MENU]
    ---
    --- Returns whether an IP address is a multicast address (`224.0.0.0/4`, [RFC 5771](https://datatracker.ietf.org/doc/html/rfc5771)).
    ---
    ipv4.isMulticast = gen_in_range( "224.0.0.0/4" )

    --- [SHARED AND MENU]
    ---
    --- Returns whether an IP address is reserved for future use (`240.0.0.0/4`, [RFC 1112](https://datatracker.ietf.org/doc/html/rfc1112)).
    ---
    ipv4.isReserved = gen_in_range( "240.0.0.0/4" )

    --- [SHARED AND MENU]
    ---
    --- Returns whether an IP address is in the shared address space used by carrier-grade NAT (`100.64.0.0/10`, [RFC 6598](https://datatracker.ietf.org/doc/html/rfc6598)).
    ---
    ipv4.isShared = gen_in_range( "100.64.0.0/10" )

    --- [SHARED AND MENU]
    ---
    --- Returns whether an IP address is reserved for network benchmarking (`198.18.0.0/15`, [RFC 2544](https://datatracker.ietf.org/doc/html/rfc2544)).
    ---
    ipv4.isBenchmarking = gen_in_range( "198.18.0.0/15" )

    local test_net_1 = gen_in_range( "192.0.2.0/24" )
    local test_net_2 = gen_in_range( "198.51.100.0/24" )
    local test_net_3 = gen_in_range( "203.0.113.0/24" )

    --- [SHARED AND MENU]
    ---
    --- Returns whether an IP address is reserved for documentation and examples
    --- (`192.0.2.0/24`, `198.51.100.0/24` and `203.0.113.0/24`, [RFC 5737](https://datatracker.ietf.org/doc/html/rfc5737)).
    ---
    ---@param ip_address dreamwork.std.IPv4 The IP address to check.
    ---@return boolean is_documentation `true` if the IP address is a documentation address, `false` otherwise.
    ---@nodiscard
    function ipv4.isDocumentation( ip_address )
        return test_net_1( ip_address ) or test_net_2( ip_address ) or test_net_3( ip_address )
    end

    --- [SHARED AND MENU]
    ---
    --- Returns whether an IP address is the unspecified address (`0.0.0.0`).
    ---
    ---@param ip_address dreamwork.std.IPv4 The IP address to check.
    ---@return boolean is_unspecified `true` if the IP address is the unspecified address, `false` otherwise.
    ---@nodiscard
    function ipv4.isUnspecified( ip_address )
        return ip_address == 0
    end

    --- [SHARED AND MENU]
    ---
    --- Returns whether an IP address is the limited broadcast address (`255.255.255.255`).
    ---
    ---@param ip_address dreamwork.std.IPv4 The IP address to check.
    ---@return boolean is_broadcast `true` if the IP address is the limited broadcast address, `false` otherwise.
    ---@nodiscard
    function ipv4.isBroadcast( ip_address )
        return ip_address == 0xFFFFFFFF
    end

    ---@class dreamwork.std.ip.ipv4.NetworkVar
    ---@field [1] dreamwork.std.IPv4 The network address.
    ---@field [2] dreamwork.std.IPv4 The broadcast address.

    ---@param ranges string[]
    ---@return dreamwork.std.ip.ipv4.NetworkVar[], integer
    local function network_ranges( ranges )
        local range_count = #ranges
        local result = {}

        for i = 1, range_count, 1 do
            result[ i ] = { cidr( ipv4.parse( ranges[ i ] ) ) }
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
    --- Returns whether the given IP address is private, i.e. not globally reachable.
    ---
    --- Follows the [IANA IPv4 Special-Purpose Address Registry](https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml),
    --- the same way as Python's `ipaddress.IPv4Address.is_private`.
    ---
    --- The shared address space (`100.64.0.0/10`) is neither private nor public.
    ---
    ---@param ip_address dreamwork.std.IPv4 The IP address.
    ---@return boolean is_private `true` if the IP address is private, `false` otherwise.
    ---@nodiscard
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

    ipv4.isPrivate = isPrivate

    --- [SHARED AND MENU]
    ---
    --- Returns whether the given IP address is public, i.e. not private.
    ---
    --- Note that the shared address space (`100.64.0.0/10`) is considered public by this function.
    ---
    ---@param ip_address dreamwork.std.IPv4 The IP address.
    ---@return boolean is_public `true` if the IP address is public, `false` otherwise.
    ---@nodiscard
    function ipv4.isPublic( ip_address )
        return not isPrivate( ip_address )
    end

    local classes = {
        { "A", ipv4.parse( "0.0.0.0" ),   ipv4.parse( "127.255.255.255" ) },
        { "B", ipv4.parse( "128.0.0.0" ), ipv4.parse( "191.255.255.255" ) },
        { "C", ipv4.parse( "192.0.0.0" ), ipv4.parse( "223.255.255.255" ) },
        { "D", ipv4.parse( "224.0.0.0" ), ipv4.parse( "239.255.255.255" ) },
        -- { "E", ipv4.parse( "240.0.0.0" ), ipv4.parse( "255.255.255.255" ) },
    }

    --- [SHARED AND MENU]
    ---
    --- Returns the [classful network](https://en.wikipedia.org/wiki/Classful_network) class of the given IP address.
    ---
    --- - `A`: `0.0.0.0` - `127.255.255.255`
    --- - `B`: `128.0.0.0` - `191.255.255.255`
    --- - `C`: `192.0.0.0` - `223.255.255.255`
    --- - `D`: `224.0.0.0` - `239.255.255.255` (multicast)
    --- - `E`: `240.0.0.0` - `255.255.255.255` (reserved)
    ---
    ---@param ip_address dreamwork.std.IPv4 The IP address.
    ---@return dreamwork.std.IPv4.Class class The class of the IP address.
    ---@nodiscard
    function ipv4.class( ip_address )
        for i = 1, 4, 1 do
            local data = classes[ i ]
            if inRange( ip_address, data[ 2 ], data[ 3 ] ) then
                return data[ 1 ]
            end
        end

        return "E"
    end

end
