---@meta _

--- [SHARED AND MENU]
---
--- Represents an arbitrary-precision signed fixed-point decimal number.
---
--- A `BigFixed` object stores its value as a `BigInteger` mantissa together
--- with a `scale` (the number of digits kept after the decimal point).
--- The value represented is always `mantissa / 10^scale`.
---
--- Arithmetic between two `BigFixed` objects of different scales is always
--- performed at the wider (larger) of the two scales; multiplication and
--- division let you keep the receiver's scale (truncating, never rounding,
--- any extra digits produced by the operation).
---
---@class BigFixed : Object
---@field __class BigFixedClass
---@field mantissa BigInteger
---@field scale integer
---@operator add( any ): BigFixed
---@operator sub( any ): BigFixed
---@operator mul( any ): BigFixed
---@operator div( any ): BigFixed
---@operator unm: BigFixed
---@operator concat( any ): string
local __BigFixed = {}

--- [SHARED AND MENU]
---
--- The class used to create new `BigFixed` instances.
---
--- Arbitrary-precision fixed-point decimal type, backed by `BigInteger`.
---
---@class BigFixedClass : BigFixed
---@field __base BigFixed
---@field DEFAULT_SCALE integer
---@overload fun( value: ( BigFixed | BigInteger | string | number | nil ), scale: ( integer | nil ) ): BigFixed
BigFixed = {}

--- The number of fractional decimal digits used when no explicit scale is given.
BigFixed.DEFAULT_SCALE = 18

--- [SHARED AND MENU]
---
--- Checks whether the value is a `BigFixed`.
---
---@param value any The value to check.
---@return boolean is_bigfixed `true` if the value is a `BigFixed`, `false` otherwise.
---@nodiscard
function isBigFixed(value) end

function __BigFixed:setScale(scale) end

--- [SHARED AND MENU]
---
--- Returns the current scale ( number of fractional digits ) of the object.
---
---@return integer scale
---@nodiscard
function __BigFixed:getScale() end

---@param value BigFixed | BigInteger | string | number | nil
---@param scale integer | nil
---@protected
function __BigFixed:__init(value, scale) end

--- [SHARED AND MENU]
---
--- Creates a `BigFixed` object from the given value.
---
--- If `value` is already a `BigFixed` at the requested scale, it is
--- returned unchanged.
---
---@param value any The value to convert to a `BigFixed`.
---@param scale? integer The number of fractional digits to keep. Defaults to `BigFixed.DEFAULT_SCALE`.
---@return BigFixed obj
---@nodiscard
function toBigFixed(value, scale) end

--- [SHARED AND MENU]
---
--- Checks if a big fixed object is zero.
---
---@return boolean is_zero
---@nodiscard
function __BigFixed:isZero() end

--- [SHARED AND MENU]
---
--- Checks if a big fixed object is negative.
---
---@return boolean is_negative
---@nodiscard
function __BigFixed:isNegative() end

---@protected
function __BigFixed:__toboolean() end

--- [SHARED AND MENU]
---
--- Makes a copy of the `BigFixed` object.
---
---@return BigFixed new_obj
---@nodiscard
function __BigFixed:copy() end

--- [SHARED AND MENU]
---
--- Negates a big fixed object.
---
---@return BigFixed self
function __BigFixed:negate() end

--- [SHARED AND MENU]
---
--- Makes a big fixed object absolute ( removes the sign ).
---
---@return BigFixed self
function __BigFixed:abs() end

---@return BigFixed new_obj
---@protected
function __BigFixed:__unm() end

--- [SHARED AND MENU]
---
--- Compares the `BigFixed` with the given value.
---
--- Unlike the `==`, `<` and `<=` operators, this also works with plain Lua numbers and strings.
---
---@param value any The value to compare with ( converted into `BigFixed` ).
---@return `-1` | `0` | `1` result `-1` if `self < value`, `0` if equal, `1` if `self > value`.
---@nodiscard
function __BigFixed:compare(value) end

---@param value any
---@return boolean
---@protected
function __BigFixed:__eq(value) end

---@param value any
---@return boolean
---@protected
function __BigFixed:__lt(value) end

---@param value any
---@return boolean
---@protected
function __BigFixed:__le(value) end

--- [SHARED AND MENU]
---
--- Adds the given value to the current `BigFixed`, in place.
---
--- The result keeps the wider ( larger ) of the two scales; plain numbers,
--- strings and `BigInteger`s are converted at the receiver's scale.
---
---@param value any The second value to be converted into `BigFixed`.
---@return BigFixed self
function __BigFixed:add(value) end

---@param value any
---@return BigFixed new_obj
---@protected
function __BigFixed:__add(value) end

--- [SHARED AND MENU]
---
--- Subtracts the given value from the current `BigFixed`, in place.
---
---@param value any The second value to be converted into `BigFixed`.
---@return BigFixed self
function __BigFixed:sub(value) end

---@param value any
---@return BigFixed new_obj
---@protected
function __BigFixed:__sub(value) end

--- [SHARED AND MENU]
---
--- Multiplies the current `BigFixed` by the given value, in place.
---
--- The result is truncated back down to the receiver's original scale
--- ( it is not rounded ).
---
---@param value any The second value to be converted into `BigFixed`.
---@return BigFixed self
function __BigFixed:mul(value) end

---@param value any
---@return BigFixed new_obj
---@protected
function __BigFixed:__mul(value) end

--- [SHARED AND MENU]
---
--- Divides the current `BigFixed` by the given value, in place.
---
--- The quotient is computed with ( and truncated to ) the receiver's
--- current scale.
---
---@param value any The value to divide by ( converted into `BigFixed` ).
---@return BigFixed self
function __BigFixed:div(value) end

---@param value any
---@return BigFixed new_obj
---@protected
function __BigFixed:__div(value) end

--- [SHARED AND MENU]
---
--- Converts a `BigFixed` object to a `BigInteger`, truncating the fractional part.
---
---@return BigInteger obj
---@nodiscard
function __BigFixed:toBigInteger() end

--- [SHARED AND MENU]
---
--- Converts a `BigFixed` object to a decimal string.
---
---@return string str
---@nodiscard
function __BigFixed:toString() end

---@return string
---@protected
function __BigFixed:__tostring() end

---@return string
---@protected
function __BigFixed:__represent() end

---@param value any
---@return string
---@protected
function __BigFixed:__concat(value) end

--- [SHARED AND MENU]
---
--- Converts a `BigFixed` object to a Lua number ( precision loss is possible
--- for values that don't fit in a double ).
---
---@return number value
---@nodiscard
function __BigFixed:toNumber() end
