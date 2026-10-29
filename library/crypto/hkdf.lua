---@meta _

--- [SHARED AND MENU]
---
--- HMAC-based Extract-and-Expand Key Derivation Function library.
---
--- Can be called directly as `crypto.hkdf( options )`, see `hkdf.derive`.
---
--- See [RFC 5869](https://datatracker.ietf.org/doc/html/rfc5869) for the algorithm.
---
---@class crypto.hkdf
---@overload fun( options: hkdf.Options ): string
crypto.hkdf = {}

--- [SHARED AND MENU]
---
--- HKDF-Extract step, computes a pseudorandom key (PRK) from the input keying material.
---
---@param hash crypto.HashClass The hash class to use, e.g. `crypto.SHA256`.
---@param key string The input keying material (IKM).
---@param salt? string The optional salt, default is a string of `digest_size` zero bytes.
---@return string prk The pseudorandom key as a binary string of `digest_size` bytes.
---@nodiscard
function crypto.hkdf.extract(hash, key, salt) end

--- [SHARED AND MENU]
---
--- HKDF-Expand step, expands the pseudorandom key into the output keying material (OKM).
---
---@param hash crypto.HashClass The hash class to use, e.g. `crypto.SHA256`.
---@param prk string The pseudorandom key, usually the result of `hkdf.extract`.
---@param info? string The optional context and application specific information, default is an empty string.
---@param length? integer The length of the output keying material in bytes, default is `digest_size`, must not exceed `255 * digest_size`.
---@return string okm The output keying material as a binary string of `length` bytes.
---@nodiscard
function crypto.hkdf.expand(hash, prk, info, length) end

--- [SHARED AND MENU]
---
--- Derives a key using the hkdf algorithm, extract and expand in one step.
---
---@param options hkdf.Options
---@return string hkdf_str The derived key as a binary string of `length` bytes.
---@nodiscard
function crypto.hkdf.derive(options) end
