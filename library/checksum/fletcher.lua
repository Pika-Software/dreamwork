---@meta _

--- [SHARED AND MENU]
---
--- The Fletcher-16 checksum calculation object.
---
---@class Fletcher16 : Object
---@field __class Fletcher16Class
---@field DigestSize integer The size of the checksum in bytes.
---@field protected a integer The first part of the checksum.
---@field protected b integer The second part of the checksum.
local __Fletcher16 = {}

__Fletcher16.DigestSize = 2

---@protected
function __Fletcher16:__init() end

--- [SHARED AND MENU]
---
--- Resets checksum to the initial value.
---
---@return Fletcher16 self
function __Fletcher16:reset() end

--- [SHARED AND MENU]
---
--- Updates checksum with the specified string.
---
---@param raw_str string The string is used to update checksum.
---@return Fletcher16 self
function __Fletcher16:update(raw_str) end

--- [SHARED AND MENU]
---
--- Finalizes checksum calculation and returns the resulting checksum.
---
---@return integer checksum The final checksum value, which is greater or equal to 0, and less than 2^16 (0x10000).
---@nodiscard
function __Fletcher16:digest() end

--- [SHARED AND MENU]
---
--- The class used to create new Fletcher-16 checksum calculation instances.
---
--- See [Fletcher's checksum](https://en.wikipedia.org/wiki/Fletcher%27s_checksum) for the definition of the Fletcher-16 checksum.
---
--- [Fletcher Online](https://www.convertcase.com/hashing/fletcher-checksum)
---
---@class Fletcher16Class : Fletcher16
---@field __base Fletcher16
---@overload fun(): Fletcher16
Fletcher16 = {}

--- [SHARED AND MENU]
---
--- Calculates the Fletcher-16 checksum of the specified string.
---
---@param raw_str string The string is used to calculate checksum.
---@return integer checksum The checksum value, which is greater or equal to 0, and less than 2^16 (0x10000).
---@nodiscard
function Fletcher16.digest(raw_str) end

--- [SHARED AND MENU]
---
--- The Fletcher-32 checksum calculation object.
---
---@class Fletcher32 : Fletcher16
---@field __parent Fletcher16
---@field __class Fletcher32Class
---@field protected pending integer | nil The trailing byte of an odd-length update, waiting for its pair.
local __Fletcher32 = {}

__Fletcher32.DigestSize = 4

---@protected
function __Fletcher32:__init() end

--- [SHARED AND MENU]
---
--- Resets checksum to the initial value.
---
---@return Fletcher32 self
function __Fletcher32:reset() end

--- [SHARED AND MENU]
---
--- Updates checksum with the specified string.
---
--- The data is processed as little-endian 16-bit words.
---
---@param raw_str string The string is used to update checksum.
---@return Fletcher32 self
function __Fletcher32:update(raw_str) end

--- [SHARED AND MENU]
---
--- Finalizes checksum calculation and returns the resulting checksum.
---
--- A trailing odd byte is padded with zero.
---
---@return integer checksum The final checksum value, which is greater or equal to 0, and less than 2^32 (0x100000000).
---@nodiscard
function __Fletcher32:digest() end

--- [SHARED AND MENU]
---
--- The class used to create new Fletcher-32 checksum calculation instances.
---
--- See [Fletcher's checksum](https://en.wikipedia.org/wiki/Fletcher%27s_checksum) for the definition of the Fletcher-32 checksum.
---
--- [Fletcher Online](https://www.convertcase.com/hashing/fletcher-checksum)
---
---@class Fletcher32Class : Fletcher32
---@field __parent Fletcher16Class
---@field __base Fletcher32
---@overload fun(): Fletcher32
Fletcher32 = {}

--- [SHARED AND MENU]
---
--- Calculates the Fletcher-32 checksum of the specified string.
---
---@param raw_str string The string is used to calculate checksum.
---@return integer checksum The checksum value, which is greater or equal to 0, and less than 2^32 (0x100000000).
---@nodiscard
function Fletcher32.digest(raw_str) end
