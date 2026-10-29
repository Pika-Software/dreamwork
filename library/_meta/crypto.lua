---@meta _


--- [SHARED AND MENU]
---
--- The static fields shared by all hash classes, e.g. `crypto.SHA256`.
---
---@class crypto.HashClass
---@field digest fun( message: string, as_hex?: boolean ): string Computes the digest of the given message.
---@field digest_size integer The size of the digest in bytes.
---@field block_size integer The block size of the hash function in bytes.
