---@meta _

--- [SHARED AND MENU]
---
--- An incremental SHA-512 hasher.
---
--- Feed data with `:update`, then read the 64-byte digest with `:digest`.
--- `:digest` does not finish the instance, so more `:update` calls can follow.
--- `:reset` restores the initial state for reuse.
---
--- ```lua
--- local sha = crypto.SHA512()
---
--- print( sha:update( "hi" ):digest( true ) ) -- 150a14ed5bea6cc731cf86c41566ac427a8db48ef1b9fd626664b3bfbb99071fa4c922f33dde38719b8c8354e2b7ab9d77e0e67fc12843920a712e73d558e197
--- ```
---
---@class crypto.SHA512 : Object
---@field __class crypto.SHA512Class
---@field protected state integer[] | ffi.cdata* The hash state, 8 words as `hi, lo` pairs ( int32 high and uint32 low halves ) or `uint64_t[8]` if FFI is available.
---@field protected initial_state integer[] The initial hash state as `hi, lo` pairs.
---@field protected message_length integer The total length of the message in bytes.
---@field protected buffer string The unprocessed tail of the message, less than 128 bytes.
local SHA512 = {}

--- [SHARED AND MENU]
---
--- The class used to create `SHA512` instances.
---
--- Secure Hash Algorithm 512-bit (SHA-2). Larger digest than SHA-256 for
--- checksums, integrity checks and keyed constructions such as HMAC.
---
--- One-shot hashing via `SHA512.digest`, or create an instance and stream with
--- `:update` / `:digest` / `:reset`.
---
--- ```lua
--- print( crypto.SHA512.digest( "hi", true ) ) -- 150a14ed5bea6cc731cf86c41566ac427a8db48ef1b9fd626664b3bfbb99071fa4c922f33dde38719b8c8354e2b7ab9d77e0e67fc12843920a712e73d558e197
--- ```
---
---@class crypto.SHA512Class : crypto.SHA512, crypto.HashClass
---@field __base crypto.SHA512
---@field digest fun( message: string, as_hex: boolean? ): string
---@field digest_size integer
---@field block_size integer
---@operator call: crypto.SHA512
crypto.SHA512 = {}

crypto.SHA512.digest_size = 64

crypto.SHA512.block_size = 128

SHA512.initial_state = {}

--- [SHARED AND MENU]
---
--- Resets the SHA512 object to its initial state.
---
--- This instance method resets the SHA512 object to its initial state.
---
--- It returns the SHA512 object for method chaining.
---
---@return crypto.SHA512 obj The reset SHA512 object.
function SHA512:reset() end

---@return string
---@protected
function SHA512:__represent() end

--- [SHARED AND MENU]
---
--- Updates the SHA512 object with the given string.
---
--- This instance method updates the SHA512 object with the given string.
---
--- It returns the SHA512 object for method chaining.
---
---@param str string The string to update the SHA512 object with.
---@return crypto.SHA512 obj The updated SHA512 object.
function SHA512:update(str) end

--- [SHARED AND MENU]
---
--- Calculates the SHA512 digest based on the current state or input of the object.
---
--- This instance method returns the SHA512 hash of the data associated with the object.
--- Useful when the SHA512 object has been incrementally updated with input data.
---
--- Does not change the state, so the object can be updated further.
---
---@param as_hex boolean? If true, the result will be a hex string.
---@return string str_result The SHA512 string of the message.
---@nodiscard
function SHA512:digest(as_hex) end

--- [SHARED AND MENU]
---
--- Computes the SHA512 digest of the given input string.
---
--- This static method takes a string and returns its SHA512 hash as a hexadecimal string.
--- Commonly used for checksums, data integrity validation, and password hashing.
---
---@param message string The message to compute SHA512 for.
---@param as_hex boolean? If true, the result will be a hex string.
---@return string str_result The SHA512 string of the message.
---@nodiscard
function crypto.SHA512.digest(message, as_hex) end
