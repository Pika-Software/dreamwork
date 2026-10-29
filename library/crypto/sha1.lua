---@meta _

--- [SHARED AND MENU]
---
--- SHA1 object.
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
--- The class used to create new `SHA1` hash calculation instances.
---
--- Computes a cryptographic 160-bit hash value.
---
--- Like other hash classes, it takes input data ( string )
--- and produces a digest ( string ) — a
--- fixed-size output string that represents that data.
---
--- **SHA1 is insecure**
---
--- Because of collision attacks,
--- attackers can find two different inputs
--- that produce the same hash.
---
--- This violates one of the basic principles
--- of a secure hash function - collision resistance.
---
---@class crypto.SHA1Class : crypto.SHA1, crypto.HashClass
---@field __base crypto.SHA1
---@field digest fun( message: string, as_hex?: boolean ): string
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
---@param as_hex? boolean If true, the result will be a hex string.
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
---@param as_hex? boolean If true, the result will be a hex string.
---@return string str_result The SHA1 string of the message.
---@nodiscard
function crypto.SHA1.digest(message, as_hex) end
