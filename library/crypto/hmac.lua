---@meta _

--- [SHARED AND MENU]
---
--- Hash-based Message Authentication Code library.
---
--- See [RFC 2104](https://datatracker.ietf.org/doc/html/rfc2104) for the algorithm.
---
--- [About HMAC](https://en.wikipedia.org/wiki/HMAC)
---@class crypto.hmac
crypto.hmac = {}

--- [SHARED AND MENU]
---
--- Normalizes the key to the block size of the hash function.
---
--- Keys longer than `block_size` are hashed first, shorter keys are padded with zero bytes.
---
---@param key string The key to normalize.
---@param digest_fn fun( data: string ): string The hash function to use.
---@param block_size integer The block size of the hash function.
---@return string normalized_key The key of exactly `block_size` bytes.
---@nodiscard
function crypto.hmac.normalizeKey(key, digest_fn, block_size) end

--- [SHARED AND MENU]
---
--- Computes the outer and inner pads of the key, `key ⊕ opad` and `key ⊕ ipad`.
---
--- The pads can be computed once and reused with `hmac.digestWithPads` for many messages under the same key.
---
---@param key string The key normalized by `hmac.normalizeKey`, must be exactly `block_size` bytes.
---@param block_size integer The block size of the hash function.
---@return string outer The outer pad.
---@return string inner The inner pad.
---@nodiscard
function crypto.hmac.pads(key, block_size) end

--- [SHARED AND MENU]
---
--- Computes hmac of the message using precomputed pads from `hmac.pads`.
---
---@param message string The message to compute hmac for.
---@param outer string The outer pad.
---@param inner string The inner pad.
---@param digest_fn fun( data: string, as_hex?: boolean ): string The hash function to use.
---@param as_hex? boolean `true` if the result should be a hex string, `false` otherwise.
---@return string hmac_str The hmac string of the message.
---@nodiscard
function crypto.hmac.digestWithPads(message, outer, inner, digest_fn, as_hex) end

--- [SHARED AND MENU]
---
--- Computes hmac of the message using the given hash function.
---
---@param message string The message to compute hmac for.
---@param key string The key to use.
---@param digest_fn fun( data: string, as_hex?: boolean ): string The hash function to use.
---@param block_size integer The block size of the hash function.
---@param as_hex? boolean `true` if the result should be a hex string, `false` otherwise.
---@return string hmac_str The hmac string of the message.
---@nodiscard
function crypto.hmac.digest(message, key, digest_fn, block_size, as_hex) end

--- [SHARED AND MENU]
---
--- Returns a function that computes hmac using the given hash class.
---
---@param hash crypto.HashClass The hash class to use, e.g. `crypto.SHA256`.
---@return fun( message: string, key: string, as_hex?: boolean ): string
---@nodiscard
function crypto.hmac.preset(hash) end

--- [SHARED AND MENU]
---
--- Computes a hmac using the MD5 hashing.
---
crypto.hmac.md5 = nil

--- [SHARED AND MENU]
---
--- Computes a hmac using the SHA-1 hashing.
---
crypto.hmac.sha1 = nil

--- [SHARED AND MENU]
---
--- Computes a hmac using the SHA-256 hashing.
---
crypto.hmac.sha256 = nil

--- [SHARED AND MENU]
---
--- Computes a hmac using the SHA-384 hashing.
---
crypto.hmac.sha384 = nil

--- [SHARED AND MENU]
---
--- Computes a hmac using the SHA-512 hashing.
---
crypto.hmac.sha512 = nil
