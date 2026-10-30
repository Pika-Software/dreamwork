local dreamwork_getUpTime = dreamwork.getUpTime
local engine = dreamwork.engine

local std = dreamwork.std
local ffi = std.ffi

local gc = std.gc

local debug = std.debug
local debug_fempty = debug.fempty

local raw = std.raw
local raw_tostring = raw.tostring

local math = std.math
local math_floor = math.floor

local string = std.string
local string_sub, string_len = string.sub, string.len
local string_byte, string_rep = string.byte, string.rep

local table = std.table
local table_concat = table.concat

---@class dreamwork.std.crypto
local crypto = std.crypto

local SHA256_digest = crypto.SHA256.digest
local chacha20_encrypt = crypto.chacha20.encrypt


--- [SHARED AND MENU]
---
--- Cryptographically secure random generator, use it for secrets: session tokens, keys, nonces, salts.
---
--- Output comes from ChaCha20 with fast key erasure (the key is replaced after every refill),
--- so a leaked state does not reveal earlier output.
---
--- The key is seeded from the best available source, see `crypto.random.source`:
--- * `"os"` - the operating system generator (`RtlGenRandom` on Windows, `/dev/urandom` elsewhere),
---   needs `std.ffi`, the generator is reseeded from it on every refill.
--- * `"jitter"` - without `std.ffi` the seed is SHA-256 of high-resolution timer jitter, memory addresses
---   and clocks, and timer samples from every tick keep being mixed in. Strong in practice,
---   but not provable, feed extra entropy with `crypto.random.mix` when you have some.
---
--- Roughly 10 (FFI) to 30 (pure Lua) times slower than `math.random` per integer,
--- keep `math.random` for gameplay and identifiers.
---
---@class dreamwork.std.crypto.random
---@field source "os" | "jitter" The source the generator is seeded from.
local random = {}
crypto.random = random


---@type nil | fun( length: integer ): string | nil
local os_random

if ffi ~= nil then
    local ffi_new, ffi_string = ffi.new, ffi.string

    if std.SYSTEM_WINDOWS then
        pcall( ffi.cdef, "uint8_t __stdcall SystemFunction036( void* buffer, unsigned long length );" )

        -- symbol lookups can throw (missing export, sandboxed FFI), so they are resolved inside pcall
        local success, RtlGenRandom = pcall( function()
            return ffi.load( "advapi32" ).SystemFunction036
        end )

        if success then
            function os_random( length )
                local buffer = ffi_new( "uint8_t[?]", length )
                if RtlGenRandom( buffer, length ) == 0 then
                    return nil
                end

                return ffi_string( buffer, length )
            end
        end
    else
        pcall( ffi.cdef, "typedef struct FILE FILE;" )
        pcall( ffi.cdef, "FILE* fopen( const char* path, const char* mode );" )
        pcall( ffi.cdef, "size_t fread( void* buffer, size_t size, size_t count, FILE* stream );" )

        -- symbol lookups can throw (HolyLib's LuaJIT sandboxes `ffi.C`), so they are resolved inside pcall
        local success, handle, fread = pcall( function()
            local C = ffi.C
            ---@diagnostic disable-next-line: redundant-return-value
            return C.fopen( "/dev/urandom", "rb" ), C.fread
        end )

        if success and handle ~= nil then
            -- the handle stays open for the whole session, it is reused by every read
            function os_random( length )
                local buffer = ffi_new( "uint8_t[?]", length )
                if fread( buffer, 1, length, handle ) ~= length then
                    return nil
                end

                return ffi_string( buffer, length )
            end
        end
    end

    -- a source that loads but does not deliver is treated as missing
    if os_random ~= nil then
        local success, bytes = pcall( os_random, 32 )
        if not (success and bytes ~= nil and string_len( bytes ) == 32) then
            os_random = nil
        end
    end
end

random.source = os_random == nil and "jitter" or "os"


--- Returns the low 32 bits of the uptime clock in nanoseconds, the most noisy part of it.
---
---@return integer
local function clock_sample()
    return math_floor( (dreamwork_getUpTime() * 1e9) % 0x100000000 )
end

--- Collects entropy without help from the operating system: timer jitter of many tiny allocations,
--- randomized memory addresses (ASLR) and every clock the environment has.
---
---@return string
local function collect_entropy()
    local samples, length = {}, 0

    -- each sample is the time after a small allocation, its duration depends on caches,
    -- interrupts, the scheduler and the garbage collector, the low nanosecond digits are unpredictable
    local sink
    for index = 1, 2048, 1 do
        sink = { index, sink }

        if index % 64 == 0 then
            sink = nil
        end

        length = length + 1
        samples[ length ] = clock_sample()
    end

    length = length + 1
    samples[ length ] = raw_tostring( {} ) .. raw_tostring( samples ) .. raw_tostring( debug_fempty ) .. raw_tostring( string_byte )

    length = length + 1
    samples[ length ] = os.time()

    length = length + 1
    samples[ length ] = os.clock()

    length = length + 1
    samples[ length ] = gc.getMemory()

    length = length + 1
    samples[ length ] = math.random( 0, 0xFFFFFFFF )

    -- Garry's Mod clocks, absent in some realms
    for _, name in ipairs( { "SysTime", "RealTime", "CurTime", "FrameTime", "UnPredictedCurTime" } ) do
        local fn = _G[ name ]
        if fn ~= nil then
            length = length + 1
            samples[ length ] = fn()
        end
    end

    length = length + 1
    samples[ length ] = clock_sample()

    return table_concat( samples, ",", 1, length )
end

local key = SHA256_digest( (os_random ~= nil and os_random( 32 ) or "") .. collect_entropy(), false )

-- entropy waiting to be mixed into the key on the next refill
local pending, pending_length = {}, 0

if os_random == nil then
    -- tick timings depend on the frame and network load, which is outside of the attacker's view
    engine.hookCatch( "Tick", "dreamwork.crypto.random", function()
        if pending_length < 256 then
            pending_length = pending_length + 1
            pending[ pending_length ] = clock_sample()
        end
    end )
end

-- 12 blocks per refill: 32 bytes become the next key, 736 bytes are handed out
local refill_zeros = string_rep( "\0", 64 * 12 )
local zero_nonce = string_rep( "\0", 12 )

local buffer, buffer_position, buffer_length = "", 1, 0

local function refill()
    if os_random ~= nil then
        key = SHA256_digest( key .. (os_random( 32 ) or collect_entropy()), false )
    elseif pending_length ~= 0 then
        key = SHA256_digest( key .. table_concat( pending, ",", 1, pending_length ), false )
        pending_length = 0
    end

    -- the key changes on every refill, so a constant nonce and counter never repeat a keystream
    local stream = chacha20_encrypt( refill_zeros, key, zero_nonce, 0 )

    key = string_sub( stream, 1, 32 )
    buffer, buffer_position, buffer_length = stream, 33, 768
end

--- [SHARED AND MENU]
---
--- Returns the given number of cryptographically secure random bytes.
---
--- ```lua
--- local session_key = crypto.random.bytes( 32 )
--- local token = base16.encode( crypto.random.bytes( 16 ) ) -- 32 hex digits, 128 bits
--- ```
---
---@param length integer The number of bytes, a non-negative integer.
---@return string bytes The random bytes.
---@nodiscard
local function random_bytes( length )
    if length < 0 or length % 1 ~= 0 then
        error( "length must be a non-negative integer", 2 )
    end

    if length == 0 then
        return ""
    end

    local available = buffer_length - buffer_position + 1
    if length <= available then
        local position = buffer_position
        buffer_position = position + length
        return string_sub( buffer, position, position + length - 1 )
    end

    local parts, part_count = {}, 0

    while length ~= 0 do
        if buffer_position > buffer_length then
            refill()
        end

        local chunk_length = buffer_length - buffer_position + 1
        if chunk_length > length then
            chunk_length = length
        end

        part_count = part_count + 1
        parts[ part_count ] = string_sub( buffer, buffer_position, buffer_position + chunk_length - 1 )

        buffer_position = buffer_position + chunk_length
        length = length - chunk_length
    end

    return table_concat( parts, "", 1, part_count )
end

random.bytes = random_bytes

--- [SHARED AND MENU]
---
--- Returns a cryptographically secure random integer in the range `[min, max]`, without modulo bias.
---
--- ```lua
--- crypto.random.integer( 0, 9 )      -- one digit of a PIN
--- crypto.random.integer( 1, 2 ^ 48 ) -- largest supported range
--- ```
---
---@param min integer The smallest value.
---@param max integer The largest value, at most `2^48` above `min`.
---@return integer value The random integer.
---@nodiscard
function random.integer( min, max )
    if min % 1 ~= 0 or max % 1 ~= 0 or max < min then
        error( "min and max must be integers with min <= max", 2 )
    end

    local range = max - min + 1
    if range > 0x1000000000000 then
        error( "range must not exceed 2^48", 2 )
    end

    if range == 1 then
        return min
    end

    local space = range > 0x100000000 and 0x1000000000000 or 0x100000000

    -- values from the incomplete last copy of the range are rejected, so every result is equally likely
    local limit = space - space % range

    while true do
        local value

        if space == 0x100000000 then
            local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( random_bytes( 4 ), 1, 4 )
            value = ((uint8_1 * 0x100 + uint8_2) * 0x100 + uint8_3) * 0x100 + uint8_4
        else
            local uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6 = string_byte( random_bytes( 6 ), 1, 6 )
            value = ((((uint8_1 * 0x100 + uint8_2) * 0x100 + uint8_3) * 0x100 + uint8_4) * 0x100 + uint8_5) * 0x100 + uint8_6
        end

        if value < limit then
            return min + value % range
        end
    end
end

--- [SHARED AND MENU]
---
--- Returns a cryptographically secure random float in the range `[0, 1)` with full 53-bit precision.
---
---@return number value The random float.
---@nodiscard
function random.float()
    local uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7 = string_byte( random_bytes( 7 ), 1, 7 )

    -- 21 high bits and 32 low bits, 53 in total, each part is exact in a double
    local high = ((uint8_1 % 0x20) * 0x100 + uint8_2) * 0x100 + uint8_3
    local low = ((uint8_4 * 0x100 + uint8_5) * 0x100 + uint8_6) * 0x100 + uint8_7

    return (high * 0x100000000 + low) / 0x20000000000000
end

--- [SHARED AND MENU]
---
--- Mixes extra entropy into the generator, it can only make the output stronger.
---
--- Good inputs are things an attacker cannot see: timings of player input,
--- arrival times of net messages, secrets from a config file.
---
---@param data string | number The entropy to mix in.
function random.mix( data )
    key = SHA256_digest( key .. raw_tostring( data ) .. clock_sample(), false )
    buffer_position = buffer_length + 1
end
