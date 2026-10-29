---@meta _

--- [SHARED AND MENU]
---
--- Cryptographically secure random generator, use it for secrets: session tokens, keys, nonces, salts.
---
--- Output comes from ChaCha20 with fast key erasure (the key is replaced after every refill),
--- so a leaked state does not reveal earlier output.
---
--- The key is seeded from the best available source, see `crypto.random.source`:
--- * `"os"` - the operating system generator (`RtlGenRandom` on Windows, `/dev/urandom` elsewhere),
---   needs `ffi`, the generator is reseeded from it on every refill.
--- * `"jitter"` - without `ffi` the seed is SHA-256 of high-resolution timer jitter, memory addresses
---   and clocks, and timer samples from every tick keep being mixed in. Strong in practice,
---   but not provable, feed extra entropy with `crypto.random.mix` when you have some.
---
--- Roughly 10 (FFI) to 30 (pure Lua) times slower than `math.random` per integer,
--- keep `math.random` for gameplay and identifiers.
---
---@class crypto.random
---@field source "os" | "jitter" The source the generator is seeded from.
crypto.random = {}

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
function crypto.random.bytes(length) end

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
function crypto.random.integer(min, max) end

--- [SHARED AND MENU]
---
--- Returns a cryptographically secure random float in the range `[0, 1)` with full 53-bit precision.
---
---@return number value The random float.
---@nodiscard
function crypto.random.float() end

--- [SHARED AND MENU]
---
--- Mixes extra entropy into the generator, it can only make the output stronger.
---
--- Good inputs are things an attacker cannot see: timings of player input,
--- arrival times of net messages, secrets from a config file.
---
---@param data string | number The entropy to mix in.
function crypto.random.mix(data) end
