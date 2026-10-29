---@meta _

--- [SHARED AND MENU]
---
--- Derives a password using the pbkdf2 algorithm.
---
--- See [PBKDF2](https://en.wikipedia.org/wiki/PBKDF2) for the algorithm.
---
---@param options pbkdf2.Options
---@return string pbkdf2_str The derived key as a binary string of `length` bytes.
---@nodiscard
function crypto.pbkdf2(options) end
