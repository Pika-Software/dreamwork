---@meta _

---@alias checksum.CRCTables table<integer, table<integer, integer>>

--- [SHARED AND MENU]
---
--- The CRC-8 checksum calculation object.
---
---@class checksum.CRC8 : Object
---@field __class checksum.CRC8Class
---@field protected poly integer The polynomial is used to calculate checksum.
---@field protected init integer The initial value of checksum, reflected if `ref_in` is `true`.
---@field protected ref_in boolean `true` if input checksum is reversed, otherwise `false`.
---@field protected ref_out boolean `true` if output checksum is reversed, otherwise `false`.
---@field protected xor_out integer The value to be XORed with output checksum.
---@field protected tables checksum.CRCTables The lookup tables for the polynomial.
---@field protected value integer The current value of the checksum.
---@field DigestSize integer The size of the checksum in bytes.
local __CRC8 = {}

__CRC8.DigestSize = 1

---@param poly? integer
---@param init? integer
---@param ref_in? boolean
---@param ref_out? boolean
---@param xor_out? integer
---@protected
function __CRC8:__init(poly, init, ref_in, ref_out, xor_out) end

--- [SHARED AND MENU]
---
--- Resets checksum to the initial value.
---
---@return checksum.CRC8 self
function __CRC8:reset() end

--- [SHARED AND MENU]
---
--- Updates checksum with the specified string.
---
---@param raw_str string The string is used to update checksum.
---@return checksum.CRC8 self
function __CRC8:update(raw_str) end

--- [SHARED AND MENU]
---
--- Finalizes checksum calculation and returns the resulting checksum.
---
---@return integer checksum The final checksum value, which is greater or equal to 0, and less than 2^8 (0x100).
---@nodiscard
function __CRC8:digest() end

--- [SHARED AND MENU]
---
--- The class used to create new CRC-8 checksum calculation instances.
---
--- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-8 checksum.
---
--- [CRC Online](https://www.texttool.com/crc-online)
---
---@class checksum.CRC8Class : checksum.CRC8
---@field __base checksum.CRC8
---@overload fun( poly?: integer, init?: integer, ref_in?: boolean, ref_out?: boolean, xor_out?: integer ): checksum.CRC8
CRC8 = {}

--- [SHARED AND MENU]
---
--- Calculates the CRC-8 checksum of the specified string.
---
---@param raw_str string The string is used to calculate checksum.
---@param poly? integer The polynomial is used to calculate checksum.
---@param init? integer The initial value of checksum.
---@param ref_in? boolean `true` if input checksum is reversed, otherwise `false`.
---@param ref_out? boolean `true` if output checksum is reversed, otherwise `false`.
---@param xor_out? integer The value to be XORed with output checksum.
---@return integer checksum The CRC-8 checksum, which is greater or equal to 0, and less than 2^8 (0x100).
---@nodiscard
function CRC8.digest(raw_str, poly, init, ref_in, ref_out, xor_out) end

--- [SHARED AND MENU]
---
--- The CRC-8 checksum class that uses MAXIM algorithm parameters.
---
---@return checksum.CRC8 object
---@nodiscard
function CRC8.MAXIM() end

--- [SHARED AND MENU]
---
--- The CRC-8 checksum class that uses ROHC algorithm parameters.
---
---@return checksum.CRC8 object
---@nodiscard
function CRC8.ROHC() end

--- [SHARED AND MENU]
---
--- The CRC-8 checksum class that uses CDMA2000 algorithm parameters.
---
---@return checksum.CRC8 object
---@nodiscard
function CRC8.CDMA2000() end

--- [SHARED AND MENU]
---
--- The class used to create new CRC-16 checksum calculation instances.
---
---@class checksum.CRC16 : checksum.CRC8
---@field __parent checksum.CRC8
---@field __class checksum.CRC16Class
---@field DigestSize integer The size of the checksum in bytes.
local __CRC16 = {}

__CRC16.DigestSize = 2

---@param poly? integer
---@param init? integer
---@param ref_in? boolean
---@param ref_out? boolean
---@param xor_out? integer
---@protected
function __CRC16:__init(poly, init, ref_in, ref_out, xor_out) end

--- [SHARED AND MENU]
---
--- Updates checksum with the specified string.
---
---@param raw_str string The string is used to update checksum.
---@return checksum.CRC16 self
function __CRC16:update(raw_str) end

--- [SHARED AND MENU]
---
--- Finalizes checksum calculation and returns the resulting checksum.
---
---@return integer checksum The final checksum value, which is greater or equal to 0, and less than 2^16 (0x10000).
---@nodiscard
function __CRC16:digest() end

--- [SHARED AND MENU]
---
--- The class used to create new CRC-16 checksum calculation instances.
---
--- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-16 checksum.
---
--- [CRC Online](https://www.texttool.com/crc-online)
---
---@class checksum.CRC16Class : checksum.CRC16
---@field __parent checksum.CRC8Class
---@field __base checksum.CRC16
---@overload fun( poly?: integer, init?: integer, ref_in?: boolean, ref_out?: boolean, xor_out?: integer ): checksum.CRC16
CRC16 = {}

CRC16.ROHC = nil

CRC16.CDMA2000 = nil

--- [SHARED AND MENU]
---
--- Calculates the CRC-16 checksum of the specified string.
---
---@param raw_str string The string is used to calculate checksum.
---@param poly? integer The polynomial is used to calculate checksum.
---@param init? integer The initial value is used to calculate checksum.
---@param ref_in? boolean Whether to reflect the input data before processing.
---@param ref_out? boolean Whether to reflect the output data after processing.
---@param xor_out? integer The XOR value is used to calculate checksum.
---@return integer checksum The CRC-16 checksum, which is greater or equal to 0, and less than 2^16 (0x10000).
---@nodiscard
function CRC16.digest(raw_str, poly, init, ref_in, ref_out, xor_out) end

--- [SHARED AND MENU]
---
--- The CRC-16 checksum class that uses MAXIM algorithm parameters.
---
---@return checksum.CRC16 object
---@nodiscard
function CRC16.MAXIM() end

--- [SHARED AND MENU]
---
--- The CRC-16 checksum class that uses XMODEM algorithm parameters.
---
---@return checksum.CRC16 object
---@nodiscard
function CRC16.XMODEM() end

--- [SHARED AND MENU]
---
--- The CRC-16 checksum class that uses USB algorithm parameters.
---
---@return checksum.CRC16 object
---@nodiscard
function CRC16.USB() end

--- [SHARED AND MENU]
---
--- The CRC-32 checksum calculation object.
---
---@class checksum.CRC32 : checksum.CRC16
---@field __parent checksum.CRC16
---@field __class checksum.CRC32Class
---@field DigestSize integer The size of the checksum in bytes.
local __CRC32 = {}

__CRC32.DigestSize = 4

---@param poly? integer
---@param init? integer
---@param ref_in? boolean
---@param ref_out? boolean
---@param xor_out? integer
---@protected
function __CRC32:__init(poly, init, ref_in, ref_out, xor_out) end

--- [SHARED AND MENU]
---
--- Updates checksum with the specified string.
---
---@param raw_str string The string is used to update checksum.
---@return checksum.CRC32 self
function __CRC32:update(raw_str) end

--- [SHARED AND MENU]
---
--- Finalizes checksum calculation and returns the resulting checksum.
---
---@return integer checksum The final checksum value, which is greater or equal to 0, and less than 2^32 (0x100000000).
---@nodiscard
function __CRC32:digest() end

--- [SHARED AND MENU]
---
--- The class used to create new CRC-32 checksum calculation instances.
---
--- See https://en.wikipedia.org/wiki/Cyclic_redundancy_check for the definition of the CRC-32 checksum.
---
--- [CRC Online](https://www.texttool.com/crc-online)
---
---@class checksum.CRC32Class : checksum.CRC32
---@field __parent checksum.CRC16Class
---@field __base checksum.CRC32
---@overload fun( poly?: integer, init?: integer, ref_in?: boolean, ref_out?: boolean, xor_out?: integer ): checksum.CRC32
CRC32 = {}

CRC32.MAXIM = nil

CRC32.XMODEM = nil

CRC32.USB = nil

--- [SHARED AND MENU]
---
--- Calculates the CRC-32 checksum of the specified string.
---
---@param raw_str string The string is used to calculate checksum.
---@param poly? integer The polynomial is used to calculate checksum.
---@param init? integer The initial value is used to calculate checksum.
---@param ref_in? boolean Whether to reflect the input data before processing.
---@param ref_out? boolean Whether to reflect the output data after processing.
---@param xor_out? integer The XOR value is used to calculate checksum.
---@return integer checksum The CRC-32 checksum, which is greater or equal to 0, and less than 2^32 (0x100000000).
---@nodiscard
function CRC32.digest(raw_str, poly, init, ref_in, ref_out, xor_out) end

--- [SHARED AND MENU]
---
--- The CRC-32 checksum class that uses BZIP2 algorithm parameters.
---
---@return checksum.CRC32 object
---@nodiscard
function CRC32.BZIP2() end

--- [SHARED AND MENU]
---
--- The CRC-32 checksum class that uses Castagnoli/C algorithm parameters.
---
---@return checksum.CRC32 object
---@nodiscard
function CRC32.C() end

--- [SHARED AND MENU]
---
--- The CRC-32 checksum class that uses D algorithm parameters.
---
---@return checksum.CRC32 object
---@nodiscard
function CRC32.D() end

--- [SHARED AND MENU]
---
--- The CRC-32 checksum class that uses JamCRC algorithm parameters.
---
---@return checksum.CRC32 object
---@nodiscard
function CRC32.JAMCRC() end

--- [SHARED AND MENU]
---
--- The CRC-32 checksum class that uses MPEG-2 algorithm parameters.
---
---@return checksum.CRC32 object
---@nodiscard
function CRC32.MPEG2() end

--- [SHARED AND MENU]
---
--- The CRC-32 checksum class that uses POSIX algorithm parameters.
---
---@return checksum.CRC32 object
---@nodiscard
function CRC32.POSIX() end

--- [SHARED AND MENU]
---
--- The CRC-32 checksum class that uses Q algorithm parameters.
---
---@return checksum.CRC32 object
---@nodiscard
function CRC32.Q() end

--- [SHARED AND MENU]
---
--- The CRC-32 checksum class that uses XFER algorithm parameters.
---
---@return checksum.CRC32 object
---@nodiscard
function CRC32.XFER() end
