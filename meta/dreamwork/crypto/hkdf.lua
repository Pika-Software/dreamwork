---@meta dreamwork.std.crypto.hkdf


--- [SHARED AND MENU]
---
--- HKDF key derivation options.
---
---@class dreamwork.std.hkdf.Options
---@field hash dreamwork.std.crypto.HashClass The hash class to use, e.g. `std.crypto.SHA256`.
---@field key string The input keying material (IKM).
---@field salt string | nil The optional salt, default is a string of `digest_size` zero bytes.
---@field info string | nil The optional context and application specific information, default is an empty string.
---@field length integer | nil The length of the output keying material in bytes, default is `digest_size`, must not exceed `255 * digest_size`.
