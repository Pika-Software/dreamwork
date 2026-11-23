---@meta _

--- [SHARED AND MENU]
---
--- An incremental SHA-1 hasher.
---
--- Feed data with `:update`, then read the 20-byte digest with `:digest`.
--- `:digest` does not finish the instance, so more `:update` calls can follow.
--- `:reset` restores the initial state for reuse.
---
--- ```lua
--- local sha = crypto.SHA1()
---
--- print( sha:update( "hi" ):digest( true ) ) -- c22b5f9178342609428d6f51b2c5af4c0bde6a42
--- ```
---
---@class crypto.SHA1 : Object
---@field __class crypto.SHA1Class
---@field protected h1 integer The first word of the hash state ( int32 ).
---@field protected h2 integer The second word of the hash state ( int32 ).
---@field protected h3 integer The third word of the hash state ( int32 ).
---@field protected h4 integer The fourth word of the hash state ( int32 ).
---@field protected h5 integer The fifth word of the hash state ( int32 ).
---@field protected message_length integer The total length of the message in bytes.
---@field protected buffer string The unprocessed tail of the message, less than 64 bytes.
local SHA1 = {}

--- [SHARED AND MENU]
---
--- The class used to create `SHA1` instances.
---
--- Secure Hash Algorithm 1, a 160-bit hash. Broken by collision attacks — do not
--- use for security. Prefer SHA-256 or newer; keep SHA-1 only where a protocol
--- still requires it.
---
--- One-shot hashing via `SHA1.digest`, or create an instance and stream with
--- `:update` / `:digest` / `:reset`.
---
--- ```lua
--- print( crypto.SHA1.digest( "hi", true ) ) -- c22b5f9178342609428d6f51b2c5af4c0bde6a42
--- ```
---
---@class crypto.SHA1Class : crypto.SHA1, crypto.HashClass
---@field __base crypto.SHA1
---@field digest fun( message: string, as_hex: boolean? ): string
---@field digest_size integer
---@field block_size integer
---@operator call: crypto.SHA1
crypto.SHA1 = {}

crypto.SHA1.digest_size = 20

crypto.SHA1.block_size = 64

--- [SHARED AND MENU]
---
--- Resets the SHA1 object to its initial state.
---
--- This instance method resets the SHA1 object to its initial state.
---
--- It returns the SHA1 object for method chaining.
---
---@return crypto.SHA1 obj The reset SHA1 object.
function SHA1:reset() end

---@return string
---@protected
function SHA1:__represent() end

--- [SHARED AND MENU]
---
--- Updates the SHA1 object with the given string.
---
--- This instance method updates the SHA1 object with the given string.
---
--- It returns the SHA1 object for method chaining.
---
---@param str string The string to update the SHA1 object with.
---@return crypto.SHA1 obj The updated SHA1 object.
function SHA1:update(str) end

--- [SHARED AND MENU]
---
--- Calculates the SHA1 digest based on the current state or input of the object.
---
--- This instance method returns the SHA1 hash of the data associated with the object.
--- Useful when the SHA1 object has been incrementally updated with input data.
---
--- Does not change the state, so the object can be updated further.
---
---@param as_hex boolean? If true, the result will be a hex string.
---@return string str_result The SHA1 string of the message.
---@nodiscard
function SHA1:digest(as_hex) end

--- [SHARED AND MENU]
---
--- Computes the SHA1 digest of the given input string.
---
--- This static method takes a string and returns its SHA1 hash as a hexadecimal string.
--- Commonly used for checksums, data integrity validation, and password hashing.
---
---@param message string The message to compute SHA1 for.
---@param as_hex boolean? If true, the result will be a hex string.
---@return string str_result The SHA1 string of the message.
---@nodiscard
function crypto.SHA1.digest(message, as_hex) end
