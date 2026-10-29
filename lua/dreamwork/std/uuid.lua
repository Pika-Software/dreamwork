---@class dreamwork.std
local std = dreamwork.std

local math = std.math
local math_floor = math.floor
local math_random = math.random

local string = std.string
local string_len = string.len
local string_byte = string.byte
local string_match = string.match
local string_format = string.format

local raw = std.raw

local rbit = raw.bit
local rbit_band, rbit_bor = rbit.band, rbit.bor

local time = std.time
local time_now = time.now

local base16 = std.base16
local base16_decode = base16.decode

local crypto = std.crypto
local crypto_MD5 = crypto.MD5
local crypto_SHA1 = crypto.SHA1

local MD5_digest = crypto_MD5.digest
local SHA1_digest = crypto_SHA1.digest

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
---@class dreamwork.std.uuid
local uuid = {}
std.uuid = uuid

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
local function parse( uuid_str )
    local uuid_str_length = string_len( uuid_str )

    if uuid_str_length == 36 then
        local part_1, part_2, part_3, part_4, part_5 = string_match( uuid_str, "^(%x%x%x%x%x%x%x%x)%-(%x%x%x%x)%-(%x%x%x%x)%-(%x%x%x%x)%-(%x%x%x%x%x%x%x%x%x%x%x%x)$" )
        if part_1 == nil then
            return nil
        end

        return base16_decode( part_1 .. part_2 .. part_3 .. part_4 .. part_5 )
    end

    if uuid_str_length == 32 and string_match( uuid_str, "^%x+$" ) ~= nil then
        return base16_decode( uuid_str )
    end

    return nil
end

uuid.parse = parse

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
function uuid.toString( uuid_bytes )
    if string_len( uuid_bytes ) ~= 16 then
        error( "UUID must be exactly 16 bytes", 2 )
    end

    return string_format( "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x", string_byte( uuid_bytes, 1, 16 ) )
end

--- Returns the 16 raw bytes of a namespace given as a UUID string or as raw bytes.
---
---@param namespace string
---@return string | nil
local function namespace_bytes( namespace )
    if string_len( namespace ) == 16 then
        return namespace
    end

    return parse( namespace )
end

--- Formats the first 16 bytes of a digest as a name-based UUID of the given version.
---
---@param digest string
---@param version integer
---@return string
local function format_digest( digest, version )
    local uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8, uint8_9, uint8_10, uint8_11, uint8_12, uint8_13, uint8_14, uint8_15, uint8_16 = string_byte( digest, 1, 16 )

    return string_format( "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
        uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, rbit_bor( rbit_band( uint8_7, 0x0F ), version ),
        uint8_8, rbit_bor( rbit_band( uint8_9, 0x3F ), 0x80 ),
        uint8_10, uint8_11, uint8_12, uint8_13, uint8_14, uint8_15, uint8_16
    )
end

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
function uuid.v3( namespace, name )
    local raw_namespace = namespace_bytes( namespace )
    if raw_namespace == nil then
        error( "invalid namespace UUID format", 2 )
    end

    return format_digest( MD5_digest( raw_namespace .. name, false ), 0x30 )
end

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
function uuid.v5( namespace, name )
    local raw_namespace = namespace_bytes( namespace )
    if raw_namespace == nil then
        error( "invalid namespace UUID format", 2 )
    end

    return format_digest( SHA1_digest( raw_namespace .. name, false ), 0x50 )
end

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
function uuid.v4()
    return string_format( "%08x-%04x-%04x-%04x-%04x%08x",
        math_random( 0, 0xFFFFFFFF ),
        math_random( 0, 0xFFFF ),
        0x4000 + math_random( 0, 0x0FFF ),
        0x8000 + math_random( 0, 0x3FFF ),
        math_random( 0, 0xFFFF ),
        math_random( 0, 0xFFFFFFFF )
    )
end

do

    -- last generated (timestamp, sequence) pair, keeps `uuid.v7()` strictly increasing within the process
    local last_timestamp, last_sequence = 0, -1

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
    function uuid.v7( timestamp )
        local sequence

        if timestamp == nil then
            local milliseconds = time_now( "s", true ) * 1000

            timestamp = math_floor( milliseconds )
            sequence = math_floor( (milliseconds - timestamp) * 0x1000 )

            if timestamp < last_timestamp or (timestamp == last_timestamp and sequence <= last_sequence) then
                timestamp, sequence = last_timestamp, last_sequence + 1

                if sequence > 0xFFF then
                    timestamp, sequence = timestamp + 1, 0
                end
            end

            last_timestamp, last_sequence = timestamp, sequence
        else
            sequence = math_random( 0, 0xFFF )
        end

        local timestamp_high = math_floor( timestamp / 0x10000 )

        return string_format( "%08x-%04x-%04x-%04x-%04x%08x",
            timestamp_high,
            timestamp - timestamp_high * 0x10000,
            0x7000 + sequence,
            0x8000 + math_random( 0, 0x3FFF ),
            math_random( 0, 0xFFFF ),
            math_random( 0, 0xFFFFFFFF )
        )
    end

end

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
function uuid.v8( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8, uint8_9, uint8_10, uint8_11, uint8_12, uint8_13, uint8_14, uint8_15, uint8_16 )
    -- out of range bytes are wrapped, so the output always keeps the 8-4-4-4-12 layout
    return string_format(
        "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
        rbit_band( uint8_1 or 0, 0xFF ), rbit_band( uint8_2 or 0, 0xFF ), rbit_band( uint8_3 or 0, 0xFF ),
        rbit_band( uint8_4 or 0, 0xFF ), rbit_band( uint8_5 or 0, 0xFF ), rbit_band( uint8_6 or 0, 0xFF ),
        rbit_bor( rbit_band( uint8_7 or 0, 0x0F ), 0x80 ), rbit_band( uint8_8 or 0, 0xFF ),
        rbit_bor( rbit_band( uint8_9 or 0, 0x3F ), 0x80 ), rbit_band( uint8_10 or 0, 0xFF ),
        rbit_band( uint8_11 or 0, 0xFF ), rbit_band( uint8_12 or 0, 0xFF ), rbit_band( uint8_13 or 0, 0xFF ),
        rbit_band( uint8_14 or 0, 0xFF ), rbit_band( uint8_15 or 0, 0xFF ), rbit_band( uint8_16 or 0, 0xFF )
    )
end

do

    -- `time.now()` at load plus 32 random bits, keeps identifiers apart between sessions and machines
    local session_time, session_random = time_now(), math_random( 0, 0xFFFFFFFF )
    local counter = -1

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
    function uuid.unique()
        counter = counter + 1

        if counter > 0xFFFFFFFF then
            session_time, session_random, counter = time_now(), math_random( 0, 0xFFFFFFFF ), 0
        end

        return string_format( "%08x%08x%08x", session_time, session_random, counter )
    end

end
