---@meta _

--- [SHARED AND MENU]
---
--- MD5 object.
---
---@class crypto.MD5 : Object
---@field __class crypto.MD5Class
---@field protected a integer The first word of the hash state ( int32 ).
---@field protected b integer The second word of the hash state ( int32 ).
---@field protected c integer The third word of the hash state ( int32 ).
---@field protected d integer The fourth word of the hash state ( int32 ).
---@field protected message_length integer The total length of the message in bytes.
---@field protected buffer string The unprocessed tail of the message, less than 64 bytes.
local MD5 = {}

--- [SHARED AND MENU]
---
--- The class used to create new `MD5` hash calculation instances.
---
--- Computes a cryptographic 128-bit hash value.
---
--- Like other hash classes, it takes input data ( string ) and
--- produces a digest ( string ) — a fixed-size output string that
--- represents that data.
---
--- **MD5 is insecure**
---
--- Because of collision attacks,
--- attackers can find two different inputs
--- that produce the same hash.
---
--- This violates one of the basic principles
--- of a secure hash function - collision resistance.
---
---@class crypto.MD5Class : crypto.MD5, crypto.HashClass
---@field __base crypto.MD5
---@field digest fun( message: string, as_hex?: boolean ): string
---@field digest_size integer
---@field block_size integer
---@operator call: crypto.MD5
crypto.MD5 = {}

crypto.MD5.digest_size = 16

crypto.MD5.block_size = 64

--- [SHARED AND MENU]
---
--- Resets the MD5 object to its initial state.
---
--- This instance method resets the MD5 object to its initial state.
---
--- It returns the MD5 object for method chaining.
---
---@return crypto.MD5 obj The reset MD5 object.
function MD5:reset() end

---@return string
---@protected
function MD5:__represent() end

--- [SHARED AND MENU]
---
--- Updates the MD5 object with the given string.
---
--- This instance method updates the MD5 object with the given string.
---
--- It returns the MD5 object for method chaining.
---
---@param str string The string to update the MD5 object with.
---@return crypto.MD5 obj The updated MD5 object.
function MD5:update(str) end

--- [SHARED AND MENU]
---
--- Calculates the MD5 digest based on the current state or input of the object.
---
--- This instance method returns the MD5 hash of the data associated with the object.
--- Useful when the MD5 object has been incrementally updated with input data.
---
--- Does not change the state, so the object can be updated further.
---
---@param as_hex? boolean If true, the result will be a hex string.
---@return string str_result The MD5 string of the message.
---@nodiscard
function MD5:digest(as_hex) end

--- [SHARED AND MENU]
---
--- Computes the MD5 digest of the given input string.
---
--- This static method takes a string and returns its MD5 hash as a hexadecimal string.
--- Commonly used for checksums, data integrity validation, and password hashing.
---
---@param message string The message to compute MD5 for.
---@param as_hex? boolean If true, the result will be a hex string.
---@return string str_result The MD5 string of the message.
---@nodiscard
function crypto.MD5.digest(message, as_hex) end
