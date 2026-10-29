---@meta _

--- [SHARED AND MENU]
---
--- The UUID library, generates, parses and formats [RFC 9562](https://www.rfc-editor.org/rfc/rfc9562) UUIDs.
---
--- All generators return the canonical form: 36 lower-case characters, `xxxxxxxx-xxxx-Mxxx-Nxxx-xxxxxxxxxxxx`,
--- where `M` is the version digit and `N` is the variant digit (`8`, `9`, `a` or `b`).
---
--- Which one to use:
--- * `uuid.v7` - time-ordered, the default choice for record identifiers and anything stored or sorted.
--- * `uuid.v4` - fully random, when the creation time must not be visible.
--- * `uuid.v5` / `uuid.v3` - deterministic, the same namespace and name always give the same UUID.
--- * `uuid.v8` - custom layout, the caller provides the bytes.
--- * `uuid.unique` - not a UUID, the fastest process-unique identifier for cache files and temporary keys.
---
--- Random parts come from `math.random`, which is not cryptographically secure:
--- the generated values are unique, but can be predicted, so never use them as secrets
--- (session tokens, password reset links, API keys).
---
---@class uuid
uuid = {}

--- [SHARED AND MENU]
---
--- The RFC 9562 namespace for fully qualified domain names, for use with `uuid.v3` and `uuid.v5`.
---
--- ```lua
--- uuid.v5( uuid.NAMESPACE_DNS, "www.example.com" ) -- "2ed6657d-e927-568b-95e1-2665a8aea6a2"
--- ```
---
uuid.NAMESPACE_DNS = "6ba7b810-9dad-11d1-80b4-00c04fd430c8"

--- [SHARED AND MENU]
---
--- The RFC 9562 namespace for URLs, for use with `uuid.v3` and `uuid.v5`.
---
uuid.NAMESPACE_URL = "6ba7b811-9dad-11d1-80b4-00c04fd430c8"

--- [SHARED AND MENU]
---
--- The RFC 9562 namespace for ISO object identifiers (OIDs), for use with `uuid.v3` and `uuid.v5`.
---
uuid.NAMESPACE_OID = "6ba7b812-9dad-11d1-80b4-00c04fd430c8"

--- [SHARED AND MENU]
---
--- The RFC 9562 namespace for X.500 distinguished names (DER or text), for use with `uuid.v3` and `uuid.v5`.
---
uuid.NAMESPACE_X500 = "6ba7b814-9dad-11d1-80b4-00c04fd430c8"

--- [SHARED AND MENU]
---
--- Parses a UUID string into its 16 raw bytes (big-endian, as stored on the wire).
---
--- Accepts the canonical (`8-4-4-4-12`) and the plain (32 hex digits) forms, in any letter case.
--- Braces, URNs (`urn:uuid:...`) and surrounding whitespace are rejected.
---
--- Any version is accepted, so it also works as a validator.
---
--- ```lua
--- uuid.parse( "6ba7b810-9dad-11d1-80b4-00c04fd430c8" ) -- "\x6B\xA7\xB8\x10..." (16 bytes)
--- uuid.parse( "6BA7B8109DAD11D180B400C04FD430C8" )     -- same bytes
--- uuid.parse( "not a uuid" )                           -- nil
--- ```
---
---@param uuid_str string The UUID string to parse.
---@return string | nil uuid_bytes The 16 raw bytes, or `nil` if the string is not a valid UUID.
---@nodiscard
function uuid.parse(uuid_str) end

--- [SHARED AND MENU]
---
--- Formats 16 raw bytes as a canonical (`8-4-4-4-12`, lower-case) UUID string, the inverse of `uuid.parse`.
---
--- The bytes are used as-is, version and variant bits are not touched.
---
--- ```lua
--- uuid.toString( uuid.parse( "6BA7B810-9DAD-11D1-80B4-00C04FD430C8" ) ) -- "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
--- uuid.toString( string.rep( "\0", 16 ) )                               -- "00000000-0000-0000-0000-000000000000"
--- ```
---
---@param uuid_bytes string The 16 raw bytes, errors on any other length.
---@return string uuid_str The UUID string.
---@nodiscard
function uuid.toString(uuid_bytes) end

--- [SHARED AND MENU]
---
--- Generates a UUID version 3 (name-based, MD5).
---
--- The UUID is the MD5 hash of the namespace bytes followed by the name,
--- so the same namespace and name always give the same UUID, on any machine.
---
--- Prefer `uuid.v5` for new identifiers, v3 exists for compatibility with systems that already use it.
---
--- ```lua
--- uuid.v3( uuid.NAMESPACE_DNS, "www.example.com" ) -- "5df41881-3aed-3515-88a7-2f4a814cf09e"
--- ```
---
---@param namespace string The namespace UUID string (see `uuid.NAMESPACE_*`), or its 16 raw bytes from `uuid.parse`, errors if invalid.
---@param name string The name to hash within the namespace.
---@return string uuid_str A UUID v3 string.
---@nodiscard
function uuid.v3(namespace, name) end

--- [SHARED AND MENU]
---
--- Generates a UUID version 5 (name-based, SHA-1).
---
--- The UUID is the first 16 bytes of the SHA-1 hash of the namespace bytes followed by the name,
--- so the same namespace and name always give the same UUID, on any machine.
---
--- Useful for stable identifiers derived from existing keys, e.g. a UUID per SteamID or per file path.
--- Anyone who knows the namespace and the name can compute the UUID, so it is not a secret.
---
--- ```lua
--- local NAMESPACE_PLAYERS = uuid.parse( "a6c3c5f0-2b1e-4c7d-9f00-6d3e5b2a1c90" ) -- your own namespace, parsed once
---
--- uuid.v5( uuid.NAMESPACE_DNS, "www.example.com" ) -- "2ed6657d-e927-568b-95e1-2665a8aea6a2"
--- uuid.v5( NAMESPACE_PLAYERS, "STEAM_0:1:12345" )   -- same result every time
--- ```
---
---@param namespace string The namespace UUID string (see `uuid.NAMESPACE_*`), or its 16 raw bytes from `uuid.parse`, errors if invalid.
---@param name string The name to hash within the namespace.
---@return string uuid_str A UUID v5 string.
---@nodiscard
function uuid.v5(namespace, name) end

--- [SHARED AND MENU]
---
--- Generates a UUID version 4 (random).
---
--- 122 of the 128 bits are random, the remaining 6 hold the version and the variant.
--- Unlike `uuid.v7`, it reveals nothing about when it was created, but it does not sort by creation time
--- and scatters database index writes.
---
--- The bits come from `math.random`, unique in practice, but predictable, never use it as a secret.
---
--- ```lua
--- uuid.v4() -- e.g. "3f2b8c1e-9a4d-4e7f-b215-0c6d8e9fa123"
--- ```
---
---@return string uuid_str A UUID v4 string.
---@nodiscard
function uuid.v4() end

--- [SHARED AND MENU]
---
--- Generates a UUID version 7 (time-ordered).
---
--- The first 48 bits are the UNIX time in milliseconds, so UUIDs sort by creation time
--- both as strings and as bytes, which keeps database indexes compact. The default choice for record identifiers.
---
--- Layout: `tttttttt-tttt-7sss-Nrrr-rrrrrrrrrrrr`
--- * `t` - 48-bit timestamp in milliseconds.
--- * `s` - 12 bits, without a `timestamp` the sub-millisecond fraction of the current time
---   (RFC 9562, section 6.2, method 3), bumped when needed, so UUIDs generated by this process
---   are strictly increasing, even within the same millisecond or when the clock goes backwards.
---   With a `timestamp` they are random.
--- * `N`, `r` - variant and 62 random bits from `math.random`.
---
--- The creation time can be read back from the UUID, use `uuid.v4` when that must stay hidden.
---
--- ```lua
--- uuid.v7()                -- e.g. "019a326a-047b-7801-9c4f-5a6e0b1d2c3f"
--- uuid.v7( 1761782400123 ) -- "019a326a-047b-7xxx-..." (random tail)
--- ```
---
---@param timestamp? integer The UNIX timestamp in milliseconds (`0`..`2^48 - 1`), defaults to the current time.
---@return string uuid_str A UUID v7 string.
---@nodiscard
function uuid.v7(timestamp) end

--- [SHARED AND MENU]
---
--- Returns a UUID version 8 (custom) string from the given bytes.
---
--- UUID v8 carries application-defined data, only the version and variant bits are fixed,
--- so 122 bits are free: the low 4 bits of `uint8_7`, the low 6 bits of `uint8_9` and all other bytes.
---
--- Missing bytes default to `0`, out of range values are wrapped to their allowed bits.
---
--- ```lua
--- uuid.v8()                         -- "00000000-0000-8000-8000-000000000000"
--- uuid.v8( 0xDE, 0xAD, 0xBE, 0xEF ) -- "deadbeef-0000-8000-8000-000000000000"
--- ```
---
---@param uint8_1? integer Unsigned byte (0..255)
---@param uint8_2? integer Unsigned byte (0..255)
---@param uint8_3? integer Unsigned byte (0..255)
---@param uint8_4? integer Unsigned byte (0..255)
---@param uint8_5? integer Unsigned byte (0..255)
---@param uint8_6? integer Unsigned byte (0..255)
---@param uint8_7? integer Unsigned byte (0..15)
---@param uint8_8? integer Unsigned byte (0..255)
---@param uint8_9? integer Unsigned byte (0..63)
---@param uint8_10? integer Unsigned byte (0..255)
---@param uint8_11? integer Unsigned byte (0..255)
---@param uint8_12? integer Unsigned byte (0..255)
---@param uint8_13? integer Unsigned byte (0..255)
---@param uint8_14? integer Unsigned byte (0..255)
---@param uint8_15? integer Unsigned byte (0..255)
---@param uint8_16? integer Unsigned byte (0..255)
---@return string uuid_str A UUID v8 string.
---@nodiscard
function uuid.v8(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8, uint8_9, uint8_10, uint8_11, uint8_12, uint8_13, uint8_14, uint8_15, uint8_16) end

--- [SHARED AND MENU]
---
--- Returns a fast, process-unique identifier (24 lower-case hex digits).
---
--- It is not a UUID, layout: `ssssssssrrrrrrrrcccccccc`
--- * `s` - load time of the library in seconds, fixed per session.
--- * `r` - 32 random bits, fixed per session.
--- * `c` - 32-bit counter, increments on every call.
---
--- Identifiers never repeat within the process, sort in creation order
--- and practically never collide between sessions or machines.
--- They are trivially predictable, never use them as secrets.
---
--- Use it for cache file names, temporary keys and similar, prefer `uuid.v7` when the value must be a standard UUID.
---
--- ```lua
--- uuid.unique() -- e.g. "6902aa806ae3cad800000000"
--- uuid.unique() -- e.g. "6902aa806ae3cad800000001"
--- ```
---
---@return string id The unique identifier.
---@nodiscard
function uuid.unique() end
