---@meta _

--- The classful network class of an IPv4 address, see [Classful network](https://en.wikipedia.org/wiki/Classful_network).
---@alias IPv4.Class "A" | "B" | "C" | "D" | "E"

--- An IPv4 address stored as an unsigned 32-bit integer in host order, e.g. `127.0.0.1` is `0x7F000001`.
---@alias IPv4 integer

--- [SHARED AND MENU]
---
--- Provides utility functions for working with Internet Protocol v4 addresses as integers.
---
--- Addresses are plain unsigned 32-bit integers (`IPv4`), so they can be compared,
--- sorted and used as table keys directly.
---
--- Networks are described by a prefix length (`0-32`) or by a pair of network and broadcast addresses,
--- which can be obtained with `ipv4.cidr`.
---
---@class ipv4
ipv4 = {}

--- [SHARED AND MENU]
---
--- Returns the octets of an IPv4 address, from the most significant to the least significant.
---
--- ```lua
--- ipv4.octets( 0x7F000001 ) -- 127, 0, 0, 1
--- ```
---
---@param ip_address IPv4 The IP address.
---@return integer a The first octet. <0-255>
---@return integer b The second octet. <0-255>
---@return integer c The third octet. <0-255>
---@return integer d The fourth octet. <0-255>
---@nodiscard
function ipv4.octets(ip_address) end

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
---@return IPv4 ip_address The IP address.
---@nodiscard
function ipv4.fromOctets(a, b, c, d) end

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
---@return IPv4 ip_address The parsed IP address.
---@return integer prefix_length The CIDR prefix length. <0-32>, `32` if not specified.
---@nodiscard
function ipv4.parse(ipv4_str, start_position, end_position) end

--- [SHARED AND MENU]
---
--- Returns the string representation of an IPv4 address in dotted-decimal notation.
---
--- ```lua
--- ipv4.toString( 0x7F000001 ) -- "127.0.0.1"
--- ```
---
---@param ip_address IPv4 The IP address.
---@return string str The string representation of the IP address.
---@nodiscard
function ipv4.toString(ip_address) end

--- [SHARED AND MENU]
---
--- Returns the reverse DNS pointer (`in-addr.arpa`) of an IPv4 address.
---
--- ```lua
--- ipv4.reversePointer( 0x7F000001 ) -- "1.0.0.127.in-addr.arpa"
--- ```
---
---@param ip_address IPv4 The IP address.
---@return string ptr The reverse DNS pointer of the IP address.
---@nodiscard
function ipv4.reversePointer(ip_address) end

--- [SHARED AND MENU]
---
--- Returns the subnet mask address for a given CIDR prefix length.
---
--- ```lua
--- ipv4.fromPrefix( 24 ) -- 0xFFFFFF00 (255.255.255.0)
--- ```
---
---@param prefix_length integer The CIDR prefix length. <0-32>
---@return IPv4 mask_address The subnet mask address.
---@nodiscard
function ipv4.fromPrefix(prefix_length) end

--- [SHARED AND MENU]
---
--- Returns the network address and broadcast address for a given IPv4 address and CIDR prefix length.
---
--- ```lua
--- ipv4.cidr( ipv4.parse( "192.168.1.42/24" ) ) -- 192.168.1.0, 192.168.1.255
--- ```
---
---@param ip_address IPv4 The IP address.
---@param prefix_length integer The CIDR prefix length. <0-32>
---@return IPv4 network_address The network (first) address.
---@return IPv4 broadcast_address The broadcast (last) address.
---@nodiscard
function ipv4.cidr(ip_address, prefix_length) end

--- [SHARED AND MENU]
---
--- Returns the network address and broadcast address for a given IPv4 address and CIDR prefix length.
---
---@deprecated Use `ipv4.cidr` instead, this is a misspelled alias kept for compatibility.
---
---@param ip_address IPv4 The IP address.
---@param prefix_length integer The CIDR prefix length. <0-32>
---@return IPv4 network_address The network (first) address.
---@return IPv4 broadcast_address The broadcast (last) address.
---@nodiscard
function ipv4.cdir(ip_address, prefix_length) end

--- [SHARED AND MENU]
---
--- Returns the wildcard (inverted subnet mask) address of a network, e.g. `0.0.0.255` for a `/24` network.
---
---@param network_address IPv4 The network address.
---@param broadcast_address IPv4 The broadcast address.
---@return IPv4 wildcard_address The wildcard address.
---@nodiscard
function ipv4.wildcard(network_address, broadcast_address) end

--- [SHARED AND MENU]
---
--- Returns the subnet mask address of a network, e.g. `255.255.255.0` for a `/24` network.
---
---@param network_address IPv4 The network address.
---@param broadcast_address IPv4 The broadcast address.
---@return IPv4 mask_address The subnet mask address.
---@nodiscard
function ipv4.mask(network_address, broadcast_address) end

--- [SHARED AND MENU]
---
--- Returns the first and last usable host addresses of a network.
---
--- The network and broadcast addresses are excluded, so the result is meaningless for `/31` and `/32` networks.
---
---@param network_address IPv4 The network address.
---@param broadcast_address IPv4 The broadcast address.
---@return IPv4 first The first usable address in the network.
---@return IPv4 last The last usable address in the network.
---@nodiscard
function ipv4.range(network_address, broadcast_address) end

--- [SHARED AND MENU]
---
--- Returns the number of addresses in a network.
---
---@param network_address IPv4 The network address.
---@param broadcast_address IPv4 The broadcast address.
---@return integer total_count The total number of addresses in the network.
---@return integer usable_count The number of usable host addresses in the network, excluding the network and broadcast addresses.
---@nodiscard
function ipv4.count(network_address, broadcast_address) end

--- [SHARED AND MENU]
---
--- Returns whether an IP address is within a given network.
---
---@param ip_address IPv4 The IP address.
---@param network_address IPv4 The network address.
---@param broadcast_address IPv4 The broadcast address.
---@return boolean in_range `true` if the IP address is within the network, `false` otherwise.
---@nodiscard
function ipv4.inRange(ip_address, network_address, broadcast_address) end

--- [SHARED AND MENU]
---
--- Returns whether an IP address is a link-local address (`169.254.0.0/16`, [RFC 3927](https://datatracker.ietf.org/doc/html/rfc3927)).
---
ipv4.isLinkLocal = nil

--- [SHARED AND MENU]
---
--- Returns whether an IP address is a loopback address (`127.0.0.0/8`, [RFC 1122](https://datatracker.ietf.org/doc/html/rfc1122)).
---
ipv4.isLoopback = nil

--- [SHARED AND MENU]
---
--- Returns whether an IP address is a multicast address (`224.0.0.0/4`, [RFC 5771](https://datatracker.ietf.org/doc/html/rfc5771)).
---
ipv4.isMulticast = nil

--- [SHARED AND MENU]
---
--- Returns whether an IP address is reserved for future use (`240.0.0.0/4`, [RFC 1112](https://datatracker.ietf.org/doc/html/rfc1112)).
---
ipv4.isReserved = nil

--- [SHARED AND MENU]
---
--- Returns whether an IP address is in the shared address space used by carrier-grade NAT (`100.64.0.0/10`, [RFC 6598](https://datatracker.ietf.org/doc/html/rfc6598)).
---
ipv4.isShared = nil

--- [SHARED AND MENU]
---
--- Returns whether an IP address is reserved for network benchmarking (`198.18.0.0/15`, [RFC 2544](https://datatracker.ietf.org/doc/html/rfc2544)).
---
ipv4.isBenchmarking = nil

--- [SHARED AND MENU]
---
--- Returns whether an IP address is reserved for documentation and examples
--- (`192.0.2.0/24`, `198.51.100.0/24` and `203.0.113.0/24`, [RFC 5737](https://datatracker.ietf.org/doc/html/rfc5737)).
---
---@param ip_address IPv4 The IP address to check.
---@return boolean is_documentation `true` if the IP address is a documentation address, `false` otherwise.
---@nodiscard
function ipv4.isDocumentation(ip_address) end

--- [SHARED AND MENU]
---
--- Returns whether an IP address is the unspecified address (`0.0.0.0`).
---
---@param ip_address IPv4 The IP address to check.
---@return boolean is_unspecified `true` if the IP address is the unspecified address, `false` otherwise.
---@nodiscard
function ipv4.isUnspecified(ip_address) end

--- [SHARED AND MENU]
---
--- Returns whether an IP address is the limited broadcast address (`255.255.255.255`).
---
---@param ip_address IPv4 The IP address to check.
---@return boolean is_broadcast `true` if the IP address is the limited broadcast address, `false` otherwise.
---@nodiscard
function ipv4.isBroadcast(ip_address) end

---@class ip.ipv4.NetworkVar
---@field [1] IPv4 The network address.
---@field [2] IPv4 The broadcast address.

--- [SHARED AND MENU]
---
--- Returns whether the given IP address is private, i.e. not globally reachable.
---
--- Follows the [IANA IPv4 Special-Purpose Address Registry](https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml),
--- the same way as Python's `ipaddress.IPv4Address.is_private`.
---
--- The shared address space (`100.64.0.0/10`) is neither private nor public.
---
---@param ip_address IPv4 The IP address.
---@return boolean is_private `true` if the IP address is private, `false` otherwise.
---@nodiscard
function ipv4.isPrivate(ip_address) end

--- [SHARED AND MENU]
---
--- Returns whether the given IP address is public, i.e. not private.
---
--- Note that the shared address space (`100.64.0.0/10`) is considered public by this function.
---
---@param ip_address IPv4 The IP address.
---@return boolean is_public `true` if the IP address is public, `false` otherwise.
---@nodiscard
function ipv4.isPublic(ip_address) end

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
---@param ip_address IPv4 The IP address.
---@return IPv4.Class class The class of the IP address.
---@nodiscard
function ipv4.class(ip_address) end
