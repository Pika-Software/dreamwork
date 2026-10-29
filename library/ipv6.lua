---@meta _

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
---@class IPv6 : Object
---@field __class IPv6Class
---@field [ 1 ] integer The first group. <0-65535>
---@field [ 2 ] integer The second group. <0-65535>
---@field [ 3 ] integer The third group. <0-65535>
---@field [ 4 ] integer The fourth group. <0-65535>
---@field [ 5 ] integer The fifth group. <0-65535>
---@field [ 6 ] integer The sixth group. <0-65535>
---@field [ 7 ] integer The seventh group. <0-65535>
---@field [ 8 ] integer The eighth group. <0-65535>
local __IPv6 = {}

---@param group1? integer The first group. <0-65535>
---@param group2? integer The second group. <0-65535>
---@param group3? integer The third group. <0-65535>
---@param group4? integer The fourth group. <0-65535>
---@param group5? integer The fifth group. <0-65535>
---@param group6? integer The sixth group. <0-65535>
---@param group7? integer The seventh group. <0-65535>
---@param group8? integer The eighth group. <0-65535>
---@return IPv6
---@protected
function __IPv6:__new(group1, group2, group3, group4, group5, group6, group7, group8) end

---@protected
---@return string
function __IPv6:__tostring() end

---@protected
---@return string
function __IPv6:__represent() end

--- [SHARED AND MENU]
---
--- Returns the string representation of the address in compressed [RFC 5952](https://datatracker.ietf.org/doc/html/rfc5952) form.
---
--- Same as `tostring( address )`.
---
--- ```lua
--- IPv6( 0x2001, 0xdb8, 0, 0, 0, 0, 0, 1 ):toString() -- "2001:db8::1"
--- ```
---
---@return string str The string representation of the address.
---@nodiscard
function __IPv6:toString() end

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
function __IPv6:groups() end

--- [SHARED AND MENU]
---
--- Class that contains methods and properties for working with Internet Protocol v6 addresses as objects.
---
--- Calling the class creates a new address from its groups, missing groups are `0`.
---
--- ```lua
--- local address = IPv6( 0x2001, 0xdb8, 0, 0, 0, 0, 0, 1 )
--- print( address ) -- 2001:db8::1
--- ```
---
---@class IPv6Class : IPv6
---@field __base IPv6
---@overload fun( group1: integer?, group2: integer?, group3: integer?, group4: integer?, group5: integer?, group6: integer?, group7: integer?, group8: integer? ): IPv6
IPv6 = {}

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
---@return IPv6 address The parsed IP address.
---@return integer prefix_length The CIDR prefix length. <0-128>, `128` if not specified.
---@nodiscard
function IPv6.parse(ipv6_str, start_position, end_position) end

---@param b IPv6
---@return boolean
---@protected
function __IPv6:__eq(b) end

---@param b IPv6
---@return boolean
---@protected
function __IPv6:__lt(b) end

---@param b IPv6
---@return boolean
---@protected
function __IPv6:__le(b) end

---@return integer
---@protected
function __IPv6:__len() end

--- Returns the bitwise NOT of the address.
---
---@return IPv6
---@protected
function __IPv6:__unm() end

--- [SHARED AND MENU]
---
--- Returns whether the address is within a given network.
---
--- ```lua
--- local network, broadcast = IPv6.parse( "2001:db8::" ):cidr( 32 )
--- IPv6.parse( "2001:db8::1" ):inRange( network, broadcast ) -- true
--- ```
---
---@param network IPv6 The network (first) address.
---@param broadcast IPv6 The last address of the network.
---@return boolean in_range `true` if the address is within the network, `false` otherwise.
---@nodiscard
function __IPv6:inRange(network, broadcast) end

--- [SHARED AND MENU]
---
--- Returns the network mask address for a given CIDR prefix length.
---
--- ```lua
--- print( IPv6.fromPrefix( 64 ) ) -- ffff:ffff:ffff:ffff::
--- ```
---
---@param prefix integer The CIDR prefix length. <0-128>
---@return IPv6 mask_address The network mask address.
---@nodiscard
function IPv6.fromPrefix(prefix) end

--- [SHARED AND MENU]
---
--- Returns the network address and the last address of the network for a given CIDR prefix length.
---
--- IPv6 has no broadcast, the "broadcast" address is just the last address of the network.
---
--- ```lua
--- local address, prefix_length = IPv6.parse( "2001:db8::1/32" )
--- local network, broadcast = address:cidr( prefix_length ) -- 2001:db8::, 2001:db8:ffff:ffff:ffff:ffff:ffff:ffff
--- ```
---
---@param mask integer The CIDR prefix length. <0-128>
---@return IPv6 network_address The network (first) address.
---@return IPv6 broadcast_address The last address of the network.
---@nodiscard
function __IPv6:cidr(mask) end

--- [SHARED AND MENU]
---
--- Returns the reverse DNS pointer (`ip6.arpa`) of the address.
---
--- ```lua
--- IPv6.parse( "2001:db8::1" ):reversePointer()
--- -- "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa"
--- ```
---
---@return string ptr The reverse DNS pointer of the address.
---@nodiscard
function __IPv6:reversePointer() end

--- [SHARED AND MENU]
---
--- Returns whether the address is the unspecified address (`::`).
---
---@return boolean is_unspecified `true` if the address is the unspecified address, `false` otherwise.
---@nodiscard
function __IPv6:isUnspecified() end

--- [SHARED AND MENU]
---
--- Returns whether the address is the loopback address (`::1`).
---
---@return boolean is_loopback `true` if the address is the loopback address, `false` otherwise.
---@nodiscard
function __IPv6:isLoopback() end

--- [SHARED AND MENU]
---
--- Returns whether the address is a multicast address (`ff00::/8`, [RFC 4291](https://datatracker.ietf.org/doc/html/rfc4291)).
---
__IPv6.isMulticast = nil

--- [SHARED AND MENU]
---
--- Returns whether the address is a link-local unicast address (`fe80::/10`, [RFC 4291](https://datatracker.ietf.org/doc/html/rfc4291)).
---
__IPv6.isLinkLocal = nil

--- [SHARED AND MENU]
---
--- Returns whether the address is a site-local unicast address (`fec0::/10`).
---
--- Site-local addresses are deprecated by [RFC 3879](https://datatracker.ietf.org/doc/html/rfc3879), but still recognized.
---
__IPv6.isSiteLocal = nil

--- [SHARED AND MENU]
---
--- Returns whether the address is a unique-local address (`fc00::/7`, [RFC 4193](https://datatracker.ietf.org/doc/html/rfc4193)).
---
__IPv6.isUniqueLocal = nil

--- [SHARED AND MENU]
---
--- Returns whether the address is reserved for documentation and examples (`2001:db8::/32`, [RFC 3849](https://datatracker.ietf.org/doc/html/rfc3849)).
---
__IPv6.isDocumentation = nil

--- [SHARED AND MENU]
---
--- Returns whether the address is reserved for network benchmarking (`2001:2::/48`, [RFC 5180](https://datatracker.ietf.org/doc/html/rfc5180)).
---
__IPv6.isBenchmarking = nil

--- [SHARED AND MENU]
---
--- Returns whether the address is a discard-only address (`100::/64`, [RFC 6666](https://datatracker.ietf.org/doc/html/rfc6666)).
---
__IPv6.isDiscard = nil

--- [SHARED AND MENU]
---
--- Returns whether the address is a 6to4 address (`2002::/16`, [RFC 3056](https://datatracker.ietf.org/doc/html/rfc3056)).
---
__IPv6.is6to4 = nil

--- [SHARED AND MENU]
---
--- Returns whether the address is a Teredo address (`2001::/32`, [RFC 4380](https://datatracker.ietf.org/doc/html/rfc4380)).
---
__IPv6.isTeredo = nil

--- [SHARED AND MENU]
---
--- Returns whether the address is an IPv4-mapped IPv6 address (`::ffff:a.b.c.d`, [RFC 4291](https://datatracker.ietf.org/doc/html/rfc4291)).
---
---@return boolean is_ipv4_mapped `true` if the address is an IPv4-mapped address, `false` otherwise.
---@nodiscard
function __IPv6:isIPv4Mapped() end

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
function __IPv6:isIPv4Compatible() end

--- [SHARED AND MENU]
---
--- Returns whether the address belongs to a private or local-use range.
---
--- Includes the unspecified, loopback, link-local, site-local, unique-local and discard-only addresses.
---
---@return boolean is_private `true` if the address is private, `false` otherwise.
---@nodiscard
function __IPv6:isPrivate() end

--- [SHARED AND MENU]
---
--- Returns whether the address belongs to a special-purpose range.
---
--- Includes the documentation, benchmarking, IPv4-mapped, IPv4-compatible, 6to4 and Teredo addresses.
---
---@return boolean is_reserved `true` if the address is reserved, `false` otherwise.
---@nodiscard
function __IPv6:isReserved() end

--- [SHARED AND MENU]
---
--- Returns whether the address is a global unicast address.
---
--- Any address that is not multicast, unspecified, loopback, link-local, site-local or unique-local.
---
---@return boolean is_global_unicast `true` if the address is a global unicast address, `false` otherwise.
---@nodiscard
function __IPv6:isGlobalUnicast() end

--- [SHARED AND MENU]
---
--- Returns whether the address is globally routable, i.e. a global unicast address that is not reserved.
---
---@return boolean is_public `true` if the address is public, `false` otherwise.
---@nodiscard
function __IPv6:isPublic() end

--- [SHARED AND MENU]
---
--- Extracts the embedded IPv4 address from an IPv4-mapped or IPv4-compatible address.
---
--- The last two groups are always returned as an IPv4 address, even if the address is
--- not IPv4-mapped or IPv4-compatible, so validate the address before calling this method.
---
--- ```lua
--- local address = IPv6.parse( "::ffff:7f00:1" )
--- if address:isIPv4Mapped() then
---     print( ipv4.toString( address:toIPv4() ) ) -- 127.0.0.1
--- end
--- ```
---
---@see IPv6.isIPv4Mapped
---@see IPv6.isIPv4Compatible
---
---@return IPv4 ipv4_address The embedded IPv4 address.
---@nodiscard
function __IPv6:toIPv4() end

--- [SHARED AND MENU]
---
--- Creates an IPv4-mapped IPv6 address (`::ffff:a.b.c.d`) from an IPv4 address.
---
--- ```lua
--- print( IPv6.fromIPv4( 0x7F000001 ) ) -- ::ffff:7f00:1
--- ```
---
---@param ipv4_address IPv4 The IPv4 address.
---@return IPv6 ipv6_address The IPv4-mapped IPv6 address.
---@nodiscard
function IPv6.fromIPv4(ipv4_address) end
