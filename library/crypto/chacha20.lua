---@meta _

--- [SHARED AND MENU]
---
--- ChaCha20 stream cipher library, the IETF variant with a 96-bit nonce and a 32-bit block counter.
---
--- Encryption and decryption are the same operation, the data is XORed with the keystream.
---
--- A key and nonce pair must never be used twice, otherwise both plaintexts can be recovered.
--- If nonces are random, prefer `crypto.xchacha20`, its 192-bit nonce is safe to generate randomly.
---
--- ChaCha20 alone does not authenticate the data, use a MAC ( e.g. `crypto.hmac` ) over the ciphertext to detect tampering.
---
--- See [RFC 8439](https://datatracker.ietf.org/doc/html/rfc8439) for the algorithm.
---
---@class crypto.chacha20
crypto.chacha20 = {}

crypto.chacha20.key_size = 32

crypto.chacha20.nonce_size = 12

crypto.chacha20.block_size = 64

--- [SHARED AND MENU]
---
--- Encrypts or decrypts the data with ChaCha20.
---
--- The data can be processed in parts: each part except the last must be a multiple of 64 bytes long,
--- and `counter` of the next part is `counter + #part / 64`.
---
---@param data string The plaintext to encrypt or the ciphertext to decrypt.
---@param key string The 32-byte key.
---@param nonce string The 12-byte nonce.
---@param counter? integer The initial block counter, default is `0`.
---@return string result The ciphertext or plaintext, same length as `data`.
---@nodiscard
function crypto.chacha20.encrypt(data, key, nonce, counter) end

--- [SHARED AND MENU]
---
--- Computes a single 64-byte ChaCha20 keystream block.
---
---@param key string The 32-byte key.
---@param nonce string The 12-byte nonce.
---@param counter? integer The block counter, default is `0`.
---@return string block The 64-byte keystream block.
---@nodiscard
function crypto.chacha20.block(key, nonce, counter) end

--- [SHARED AND MENU]
---
--- XChaCha20 stream cipher library, ChaCha20 with a 192-bit nonce.
---
--- The nonce is large enough to be generated randomly for every message.
---
--- Encryption and decryption are the same operation, the data is XORed with the keystream.
---
--- XChaCha20 alone does not authenticate the data, use a MAC ( e.g. `crypto.hmac` ) over the ciphertext to detect tampering.
---
--- See [draft-irtf-cfrg-xchacha](https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-xchacha) for the algorithm.
---
---@class crypto.xchacha20
crypto.xchacha20 = {}

crypto.xchacha20.key_size = 32

crypto.xchacha20.nonce_size = 24

crypto.xchacha20.block_size = 64

--- [SHARED AND MENU]
---
--- Derives a 32-byte subkey from the key and a 16-byte nonce with HChaCha20.
---
---@param key string The 32-byte key.
---@param nonce string The 16-byte nonce.
---@return string subkey The 32-byte subkey.
---@nodiscard
function crypto.xchacha20.hchacha20(key, nonce) end

--- [SHARED AND MENU]
---
--- Encrypts or decrypts the data with XChaCha20.
---
--- The data can be processed in parts: each part except the last must be a multiple of 64 bytes long,
--- and `counter` of the next part is `counter + #part / 64`.
---
---@param data string The plaintext to encrypt or the ciphertext to decrypt.
---@param key string The 32-byte key.
---@param nonce string The 24-byte nonce.
---@param counter? integer The initial block counter, default is `0`.
---@return string result The ciphertext or plaintext, same length as `data`.
---@nodiscard
function crypto.xchacha20.encrypt(data, key, nonce, counter) end
