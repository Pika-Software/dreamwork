---@meta _

--- [SHARED AND MENU]
---
--- An incremental SHA-256 hasher.
---
--- Feed data with `:update`, then read the 32-byte digest with `:digest`.
--- `:digest` does not finish the instance, so more `:update` calls can follow.
--- `:reset` restores the initial state for reuse.
---
--- ```lua
--- local sha = crypto.SHA256()
---
--- print( sha:update( "hi" ):digest( true ) ) -- 8f434346648f6b96df89dda901c5176b10a6d83961dd3c1ac88b59b2dc327aa4
--- ```
---
---@class crypto.SHA256 : Object
---@field __class crypto.SHA256Class
---@field protected h1 integer The first word of the hash state ( int32 ).
---@field protected h2 integer The second word of the hash state ( int32 ).
---@field protected h3 integer The third word of the hash state ( int32 ).
---@field protected h4 integer The fourth word of the hash state ( int32 ).
---@field protected h5 integer The fifth word of the hash state ( int32 ).
---@field protected h6 integer The sixth word of the hash state ( int32 ).
---@field protected h7 integer The seventh word of the hash state ( int32 ).
---@field protected h8 integer The eighth word of the hash state ( int32 ).
---@field protected message_length integer The total length of the message in bytes.
---@field protected buffer string The unprocessed tail of the message, less than 64 bytes.
local SHA256 = {}

--- [SHARED AND MENU]
---
--- The class used to create `SHA256` instances.
---
--- Secure Hash Algorithm 256-bit (SHA-2). Fast and collision-resistant for
--- checksums, integrity checks and keyed constructions such as HMAC.
---
--- One-shot hashing via `SHA256.digest`, or create an instance and stream with
--- `:update` / `:digest` / `:reset`.
---
--- ```lua
--- print( crypto.SHA256.digest( "hi", true ) ) -- 8f434346648f6b96df89dda901c5176b10a6d83961dd3c1ac88b59b2dc327aa4
--- ```
---
---@class crypto.SHA256Class : crypto.SHA256, crypto.HashClass
---@field __base crypto.SHA256
---@field digest fun( message: string, as_hex: boolean? ): string
---@field digest_size integer
---@field block_size integer
---@operator call: crypto.SHA256
crypto.SHA256 = {}

crypto.SHA256.digest_size = 32

crypto.SHA256.block_size = 64

--- [SHARED AND MENU]
---
--- Resets the SHA256 object to its initial state.
---
--- This instance method resets the SHA256 object to its initial state.
---
--- It returns the SHA256 object for method chaining.
---
---@return crypto.SHA256 obj The reset SHA256 object.
function SHA256:reset() end

---@return string
---@protected
function SHA256:__represent() end

--- [SHARED AND MENU]
---
--- Updates the SHA256 object with the given string.
---
--- This instance method updates the SHA256 object with the given string.
---
--- It returns the SHA256 object for method chaining.
---
---@param str string The string to update the SHA256 object with.
---@return crypto.SHA256 obj The updated SHA256 object.
function SHA256:update(str) end

--- [SHARED AND MENU]
---
--- Calculates the SHA256 digest based on the current state or input of the object.
---
--- This instance method returns the SHA256 hash of the data associated with the object.
--- Useful when the SHA256 object has been incrementally updated with input data.
---
--- Does not change the state, so the object can be updated further.
---
---@param as_hex boolean? If true, the result will be a hex string.
---@return string str_result The SHA256 string of the message.
---@nodiscard
function SHA256:digest(as_hex) end

--- [SHARED AND MENU]
---
--- Computes the SHA256 digest of the given input string.
---
--- This static method takes a string and returns its SHA256 hash as a hexadecimal string.
--- Commonly used for checksums, data integrity validation, and password hashing.
---
---@param message string The message to compute SHA256 for.
---@param as_hex boolean? If true, the result will be a hex string.
---@return string str_result The SHA256 string of the message.
---@nodiscard
function crypto.SHA256.digest(message, as_hex) end
