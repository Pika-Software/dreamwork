---@meta _

--- [SHARED AND MENU]
---
--- SHA256 object.
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
--- The class used to create new `SHA256` hash calculation instances.
---
--- Secure Hash Algorithm 256-bit, part of the SHA-2 family.
---
--- This hash algorithm is recommended because it is fast and secure.
---
--- Like other hash classes, it takes input data ( string )
--- and produces a digest ( string ) — a
--- fixed-size output string that represents that data.
---
---@class crypto.SHA256Class : crypto.SHA256, crypto.HashClass
---@field __base crypto.SHA256
---@field digest fun( message: string, as_hex?: boolean ): string
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
---@param as_hex? boolean If true, the result will be a hex string.
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
---@param as_hex? boolean If true, the result will be a hex string.
---@return string str_result The SHA256 string of the message.
---@nodiscard
function crypto.SHA256.digest(message, as_hex) end
