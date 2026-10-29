---@meta _

--- [SHARED AND MENU]
---
--- The Adler-32 checksum calculation object.
---
---@class Adler32 : Object
---@field __class Adler32Class
---@field DigestSize integer The size of the checksum in bytes.
---@field BlockSize integer The block size in bytes.
---@field protected a integer The first part of the checksum.
---@field protected b integer The second part of the checksum.
local __Adler32 = {}

__Adler32.DigestSize = 4

__Adler32.BlockSize = 8

---@protected
function __Adler32:__init() end

--- [SHARED AND MENU]
---
--- Resets checksum to the initial value.
---
---@return Adler32 self
function __Adler32:reset() end

--- [SHARED AND MENU]
---
--- Updates checksum with the specified string.
---
---@param raw_str string The string is used to update checksum.
---@return Adler32 self
function __Adler32:update(raw_str) end

--- [SHARED AND MENU]
---
--- Finalizes checksum calculation and returns the resulting checksum.
---
---@return integer checksum The final checksum value, which is greater or equal to 0, and less than 2^32 (0x100000000).
---@nodiscard
function __Adler32:digest() end

--- [SHARED AND MENU]
---
--- The class used to create new Adler-32 checksum calculation instances.
---
--- See [RFC1950](https://tools.ietf.org/html/rfc1950) for the definition of the Adler-32 checksum.
---
--- [Adler32 Online](https://md5calc.com/hash/adler32)
---
---@class Adler32Class : Adler32
---@field __base Adler32
---@overload fun(): Adler32
Adler32 = {}

--- [SHARED AND MENU]
---
--- Calculates the Adler-32 checksum of the specified string.
---
---@param raw_str string The string is used to calculate checksum.
---@return integer checksum The checksum value, which is greater or equal to 0, and less than 2^32 (0x100000000).
---@nodiscard
function Adler32.digest(raw_str) end
