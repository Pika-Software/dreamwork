---@meta dreamwork.std.pbkdf2


--- [SHARED AND MENU]
---
--- The options for the pbkdf2 function.
---
---@class dreamwork.std.pbkdf2.Options
local options = {}

---
--- The input password or passphrase to derive a key from.
---
--- Not limited in length, but longer passphrases are usually stronger.
---
---@type string
options.password = nil

---
--- A unique, random value added to the password before hashing.
---
--- Prevents rainbow table attacks.
---
--- Common size: `16` to `32 bytes.
---
---@type string
options.salt = nil

---
--- Number of hashing iterations, higher values make brute-force attacks harder.
---
--- Recommended minimums:
--- * `100,000+` for general applications.
--- * `300,000+` for secure storage (as of 2024 recommendations).
---
--- Default value: `4096`
---
---@type integer | nil
options.iterations = 4096

---
--- Desired length of the derived key (in bytes).
---
--- Default value: `16`
---
---@type integer | nil
options.length = 16

---
--- The hash algorithm class to use for the key derivation.
---
---@type dreamwork.std.HashClass
options.hash = nil
