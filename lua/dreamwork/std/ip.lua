---@class dreamwork.std
local std = dreamwork.std

local math = std.math
local math_clamp = math.clamp

local string = std.string
local string_len = string.len
local string_format = string.format
local string_findByte = string.findByte
local string_toNumber = string.toNumber

local bit = std.bit
local bit_bnot = bit.bnot
local bit_lshift = bit.lshift
local bit_unsign = bit.unsign
local bit_bxor, bit_band, bit_bor = bit.bxor, bit.band, bit.bor

local bytepack = std.bytepack
local bytepack_readUInt32 = bytepack.readUInt32
local bytepack_writeUInt32 = bytepack.writeUInt32

---@alias dreamwork.std.IPv4 integer
---@alias dreamwork.std.IPv6 string

--- [SHARED AND MENU]
---
--- The Internet Protocol library.
---
---@class dreamwork.std.ip
local ip = {}
std.ip = ip

--- [SHARED AND MENU]
---
--- Provides utility functions for working with IPv4 addresses.
---
---@class dreamwork.std.ip.v4
local v4 = {}
ip.v4 = v4

local bin_masks = {}

for i = 0, 32, 1 do
    bin_masks[ i ] = bit_lshift( (2 ^ i) - 1, 32 - i )
end

local bin_inverted_masks = {}

for i = 0, 32, 1 do
    bin_inverted_masks[ i ] = bit_bxor( bin_masks[ i ], bin_masks[ 32 ] )
end

--- [SHARED AND MENU]
---
--- Parses an IPv4 address string into an IP address and subnet mask.
---
---@param str string The IPv4 address string to parse.
---@return dreamwork.std.IPv4 ip_address The parsed IP address.
---@return integer mask The subnet mask.
function v4.parse( str )
    local octets = { 0, 0, 0, 0 }
    local octet_index = 1

    local str_length = string_len( str )
    local std_index = 1

    local cdir_position = string_findByte( str, 0x2F --[[ / ]], std_index, str_length, str_length )

    ::parse_octet::

    local octet_position = string_findByte( str, 0x2E --[[ . ]], std_index, str_length, str_length )

    local octet_length
    if octet_position == nil then
        if cdir_position == nil then
            octet_length = str_length - std_index + 1
        else
            octet_length = cdir_position - std_index
        end
    else
        octet_length = octet_position - std_index
    end

    if octet_length == 0 then
        std.errorf( 2, false, "Octet %d is cannot be empty!", octet_index )
    end

    if octet_length > 3 then
        std.errorf( 2, false, "Octet %d cannot be longer than 3 characters.", octet_index )
    end

    octets[ octet_index ] = math_clamp( string_toNumber( str, 10, std_index, std_index + octet_length - 1 ) or 0, 0, 255 )

    if octet_position ~= nil and octet_index ~= 4 then
        octet_index = octet_index + 1
        std_index = octet_position + 1
        goto parse_octet
    end

    if octet_index ~= 4 then
        octets[ 4 ], octets[ octet_index ] = octets[ octet_index ], 0
    end

    local mask = 32

    if cdir_position ~= nil then
        mask = math_clamp( string_toNumber( str, 10, cdir_position + 1, str_length ) or 32, 0, 32 )
    end

    return bytepack_readUInt32( octets[ 4 ], octets[ 3 ], octets[ 2 ], octets[ 1 ] ), mask
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
--- Returns the octets of an IPv4 address.
---
---@param ip_address dreamwork.std.IPv4 The IP address.
---@return dreamwork.std.IPv4 a The first octet.
---@return dreamwork.std.IPv4 b The second octet.
---@return dreamwork.std.IPv4 c The third octet.
---@return dreamwork.std.IPv4 d The fourth octet.
function v4.octets( ip_address )
    local d, c, b, a = bytepack_writeUInt32( ip_address )
    return a, b, c, d
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

    ---@class dreamwork.std.ip.v4.Network
    ---@field [1] dreamwork.std.IPv4 The network address.
    ---@field [2] dreamwork.std.IPv4 The broadcast address.

    ---@param ranges string[] The network ranges.
    ---@return dreamwork.std.ip.v4.Network[] The network ranges.
    ---@return integer range_count The number of network ranges.
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

end

---@class dreamwork.std.ip.v6
local v6 = {}
ip.v6 = v6

-- TODO: ipv6
