---@meta _

--- [SHARED AND MENU]
---
--- The powerful math library.
---
---@class mathlib
---@field e number A variable containing the mathematical constant e. [`2.7182818284590`]
---@field ln2 number A variable containing the mathematical constant natural logarithm of 2. [`0.69314718055995`]
---@field nan number A variable containing number "not a number". [`nan`]
---@field pi number A variable containing the mathematical *π* constant. [`3.1415926535898`]
---@field huge number A variable that effectively represents infinity, in the sense that in any numerical comparison every number will be less than this. [`inf`]
---@field tiny number A variable that effectively represents negative infinity, in the sense that in any numerical comparison every number will be greater than this. [`-inf`]
---@field ln10 number A variable containing the mathematical constant natural logarithm of 10. (2.3025850929940)
---@field log10e number A variable containing the mathematical constant logarithm of 10 to the base e. (0.43429448190325)
---@field log2e number A variable containing the mathematical constant logarithm of 2 to the base e. (1.4426950408889)
---@field sqrt2 number A variable containing the mathematical constant square root of 2. (1.4142135623731)
---@field sqrt1_2 number A variable containing the mathematical constant square root of 1/2. (0.70710678118655)
---@field randomseed number A variable containing the current random seed and can be changed to set a new seed.
math = {}

--- [SHARED AND MENU]
---
--- Returns the cotangent of the given angle.
---
---@param x number The angle in radians.
---@return number cotangent The cotangent of the given angle.
---@nodiscard
function math.cot(x) end

--- [SHARED AND MENU]
---
--- Returns the arc tangent of y/x.
---
---@param y number The y coordinate.
---@param x number The x coordinate.
---@return number arc_tan The arc tangent of y/x.
---@nodiscard
function math.atan(y, x) end

--- [SHARED AND MENU]
---
--- Returns `m` and `e` such that `x = m2e`, `e` is an integer and the absolute value of `m` is in the range ((0.5, 1) (or zero when x is zero).
---
--- Used to split the number value into a normalized fraction and an exponent.
--- Two values are returned: the first is a multiplier in the range
--- `1/2` (inclusive) to `1` (exclusive) and the second is an integer exponent.
---
--- The result is such that `x = m*2^e`.
---
---@param x number The number to split.
---@return number m The normalized fraction.
---@return number e The exponent.
---@nodiscard
function math.frexp(x) end

--- [SHARED AND MENU]
---
--- Takes a normalised number and returns the floating point representation.
---
--- Effectively it returns the result of `normalizedFraction * 2.0 ^ exponent`.
---
---@see math.frexp opposite function
---@param x number The base value.
---@param exponent number The exponent.
---@return number float The floating point representation.
---@nodiscard
function math.ldexp(x, exponent) end

--- [SHARED AND MENU]
---
--- Checks if a number is an unsigned integer.
---
---@param x number The number to check.
---@return boolean is_uint `true` if the number is an integer, otherwise `false`.
---@nodiscard
function math.isUnsignedInteger(x) end

--- [SHARED AND MENU]
---
--- Checks if a number is an signed integer.
---
---@param x number The number to check.
---@return boolean is_int `true` if the number is an integer, otherwise `false`.
---@nodiscard
function math.isInteger(x) end

--- [SHARED AND MENU]
---
--- Checks if a number is a float point number.
---
---@param x number The number to check.
---@return boolean is_float `true` if the number is a float, otherwise `false`.
---@nodiscard
function math.isFloat(x) end

--- [SHARED AND MENU]
---
--- Checks if a number is positive or negative infinity.
---
---@param x number The number to check.
---@return boolean is_inf `true` if the number is positive or negative infinity, otherwise `false`.
---@nodiscard
function math.isInf(x) end

--- [SHARED AND MENU]
---
--- Checks if a number is NaN.
---
---@param x number The number to check.
---@return boolean is_nan `true` if the number is NaN, otherwise `false`.
---@nodiscard
function math.isNaN(x) end

--- [SHARED AND MENU]
---
--- Checks if a number is finite.
---
---@param x number The number to check.
---@return boolean is_finite `true` if the number is finite, otherwise `false`.
---@nodiscard
function math.isFinite(x) end

--- [SHARED AND MENU]
---
--- Checks if a number is divisible by another number without remainder.
---
---@param a number The first number to check.
---@param b number The second number to check.
---@return boolean is_divideable `true` if the first number is divisible by the second number, otherwise `false`.
---@nodiscard
function math.isDivideable(a, b) end

--- [SHARED AND MENU]
---
--- Checks if a number is even.
---
---@param x number The number to check.
---@return boolean is_even `true` if the number is even, otherwise `false`.
---@nodiscard
function math.isEven(x) end

--- [SHARED AND MENU]
---
--- Checks if a number is odd.
---
---@param x number The number to check.
---@return boolean is_odd `true` if the number is odd, otherwise `false`.
---@nodiscard
function math.isOdd(x) end

--- [SHARED AND MENU]
---
--- Checks if a number is positive.
---
---@param x number The number to check.
---@return boolean is_positive `true` if the number is positive, otherwise `false`.
---@nodiscard
function math.isPositive(x) end

--- [SHARED AND MENU]
---
--- Checks if a number is negative.
---
---@param x number The number to check.
---@return boolean is_negative `true` if the number is negative, otherwise `false`.
---@nodiscard
function math.isNegative(x) end

--- [SHARED AND MENU]
---
--- Check if a value is a power-of-two.
---
---@param x number The number to check.
---@return boolean is_pot `true` if a number is a valid power-of-two, otherwise `false`.
---@nodiscard
function math.isPowerOfTwo(x) end

--- [SHARED AND MENU]
---
--- Rounds the given value to the nearest whole number or to the given decimal places.
---
---@param number number The number to round.
---@param decimals? integer The number of decimal places to round to.
---@return number rounded The rounded number.
---@nodiscard
function math.round(number, decimals) end

--- [SHARED AND MENU]
---
--- Returns the smallest integer greater than or equal to the given number.
---
---@param number number The number to round.
---@param step number The step size to round to.
---@return number snapped The rounded number.
---@nodiscard
function math.snap(number, step) end

--- [SHARED AND MENU]
---
--- Returns the integer part of the given number, rounding towards zero.
---
--- > **NOTE**: Same result as `(math.modf( x ))`, but `math.modf` is ~10x slower under JIT.
---
---@param x number The number to truncate.
---@return integer truncated The integer part of the number.
---@nodiscard
function math.trunc(x) end

--- [SHARED AND MENU]
---
--- Wraps a number to keep it within a specific minimum and maximum range.
---
---@param value number The number to wrap.
---@param min number The lower limit of the wrap range.
---@param max number The upper limit of the wrap range.
---@return number wrapped The number wrapped within [min, max).
---@nodiscard
function math.wrap(value, min, max) end

--- [SHARED AND MENU]
---
--- Returns the natural logarithm of the given number.
---
---@param x number The number to calculate the logarithm of.
---@return number log The natural logarithm of the number.
---@nodiscard
function math.log1p(x) end

--- [SHARED AND MENU]
---
--- Returns the base 2 logarithm of the given number.
---
---@param x number The number to calculate the logarithm of.
---@return number log2 The base 2 logarithm of the number.
---@nodiscard
function math.log2(x) end

--- [SHARED AND MENU]
---
--- Returns a random floating point number in the range [a, b).
---
---@param a number The minimum value.
---@param b number The maximum value.
---@return number float The random floating point number.
---@nodiscard
function math.randomf(a, b) end

--- [SHARED AND MENU]
---
--- Returns the square root of the sum of squares of its arguments.
---
---@param numbers number[] The numbers to calculate the square root of.
---@param number_count integer? The number of numbers to calculate the square root of.
---@return number value The square root of the sum of squares of its arguments.
---@nodiscard
function math.hypot(numbers, number_count) end

--- [SHARED AND MENU]
---
--- Returns the cube root of the given number.
---
---@param x number The number to calculate the cube root of.
---@return number cube The cube root of the number.
---@nodiscard
function math.cbrt(x) end

--- [SHARED AND MENU]
---
--- Returns the root of a given number with a given base.
---
---@param a number The number to calculate the root of.
---@param b number The base of the root.
---@return number root The root of the number.
---@nodiscard
function math.root(a, b) end

--- [SHARED AND MENU]
---
--- Gradually approaches the target value by the specified amount.
---
---@param current number The current value.
---@param target number The target value.
---@param change number The amount that the current value is allowed to change by to approach the target.
---@return number approached The approached value.
---@nodiscard
function math.approach(current, target, change) end

--- [SHARED AND MENU]
---
--- Clamps a number between a minimum and maximum value.
---
---@param number number The number to clamp.
---@param min number The minimum value.
---@param max number The maximum value.
---@return number clamped The clamped number.
---@nodiscard
function math.clamp(number, min, max) end

--- [SHARED AND MENU]
---
--- Performs a linear interpolation from the start number to the end number.
---
---@param fraction number The fraction of the way between the start and end numbers.
---@param from number The start number.
---@param to number The end number.
---@return number lerped The interpolated value.
---@nodiscard
function math.lerp(fraction, from, to) end

--- [SHARED AND MENU]
---
--- Performs an inverse linear interpolation from the start number to the end number.
---
---@param result number The interpolated value.
---@param from number The start number.
---@param to number The end number.
---@return number lerped The fraction of the way between the start and end numbers.
---@nodiscard
function math.ilerp(result, from, to) end

--- [SHARED AND MENU]
---
--- Performs a smooth interpolation from the start number to the end number.
---
---@param previous number The previous value.
---@param next number The next value.
---@param alpha number The amount of smoothing.
---@return number value The interpolated value.
---@nodiscard
function math.smooth(previous, next, alpha) end

--- [SHARED AND MENU]
---
--- Remaps a number from one range to another.
---
---@param number number The number to remap.
---@param inMin number The minimum value of the input range.
---@param inMax number The maximum value of the input range.
---@param outMin number The minimum value of the output range.
---@param outMax number The maximum value of the output range.
---@return number value The remapped value.
---@nodiscard
function math.remap(number, inMin, inMax, outMin, outMax) end

--- [SHARED AND MENU]
---
--- Checks if a number is in a range.
---
---@param number number The number to check.
---@param from number The minimum value of the range.
---@param to number The maximum value of the range.
---@return boolean in_range `true` if the number is in the range, otherwise `false`.
---@nodiscard
function math.inRange(number, from, to) end

--- [SHARED AND MENU]
---
--- Calculates the angle between two points.
---
---@param x1 number The x coordinate of the first point.
---@param y1 number The y coordinate of the first point.
---@param x2 number The x coordinate of the second point.
---@param y2 number The y coordinate of the second point.
---@return number angle The angle between the two points.
---@nodiscard
function math.angle(x1, y1, x2, y2) end

--- [SHARED AND MENU]
---
--- Returns the normalised angle between two points.
---
---@param angle number The angle to normalise.
---@return number normalised The normalised angle.
---@nodiscard
function math.angleNormalize(angle) end

--- [SHARED AND MENU]
---
--- Returns the difference between two angles.
---
---@param a number The first angle.
---@param b number The second angle.
---@return number diff The difference between the angles.
---@nodiscard
function math.angleDifference(a, b) end

--- [SHARED AND MENU]
---
--- Calculates the magnitude (distance) between two points.
---
---@param x1 number The x coordinate of the first point.
---@param y1 number The y coordinate of the first point.
---@param x2 number The x coordinate of the second point.
---@param y2 number The y coordinate of the second point.
---@return number magnitude The magnitude between the two points.
---@nodiscard
function math.magnitude(x1, y1, x2, y2) end

--- [SHARED AND MENU]
---
--- Calculates the direction between two points.
---
---@param x1 number The x coordinate of the first point.
---@param y1 number The y coordinate of the first point.
---@param x2 number The x coordinate of the second point.
---@param y2 number The y coordinate of the second point.
---@return number x The x coordinate of the direction.
---@return number y The y coordinate of the direction.
---@nodiscard
function math.direction(x1, y1, x2, y2) end

--- [SHARED AND MENU]
---
--- Calculates the euclidean modulus.
---
---@param numerator number The numerator.
---@param denominator number The denominator.
---@return number mod The euclidean modulus.
---@nodiscard
function math.euclideanMod(numerator, denominator) end

--- [SHARED AND MENU]
---
--- Check if value is equal or greater than threshold.
---
--- **NOTE**: This is useful to mitigate [accuracy issues in floating point numbers](https://en.wikipedia.org/wiki/Floating-point_arithmetic#Accuracy_problems).
---
--- Examples:
--- ```lua
--- local a = 10
--- local b = 13.3
---
--- if math.threshold( a - b, 4 ) then
---     print( "yes" )
--- else
---     print( "no" )
--- end
---
--- -- print: `no` because difference between a and b is not so far from 4
--- ```
---
---@param x number The number to check.
---@param threshold number? The maximum difference between numbers at which they are considered equal; by default `1e-8`.
---@return boolean is_greater_equal `true` if the numbers are equal or greater, otherwise `false`.
---@nodiscard
function math.threshold(x, threshold) end

--- [SHARED AND MENU]
---
--- Check if value is equal or less than threshold.
---
--- **NOTE**: This is useful to mitigate [accuracy issues in floating point numbers](https://en.wikipedia.org/wiki/Floating-point_arithmetic#Accuracy_problems).
---
--- Examples:
--- ```lua
--- local a = 10
--- local b = 13.3
---
--- if math.tolerance( a - b, 4 ) then
---     print( "yes" )
--- else
---     print( "no" )
--- end
---
--- -- print: `yes` because difference between a and b is near of 4
--- ```
---
---@param x number The number to check.
---@param threshold number? The maximum difference between numbers at which they are considered equal; by default `1e-8`.
---@return boolean is_nearly_equal `true` if the numbers are equal or less, otherwise `false`.
---@nodiscard
function math.tolerance(x, threshold) end

--- [SHARED AND MENU]
---
--- Returns `x` if its absolute value is equal to or greater than `size`, otherwise returns `0`.
---
---@param x number The number to check.
---@param size number The minimum allowed absolute value before snapping to 0.
---@return number result The original number, or 0.
---@nodiscard
function math.lower(x, size) end

--- [SHARED AND MENU]
---
--- Returns `x` if its absolute value is equal to or less than `size`, otherwise returns `0`.
---
--- Useful for ignoring extreme spikes or outliers in values.
---
---@param x number The number to check.
---@param size number The maximum allowed absolute value before snapping to 0.
---@return number result The original number, or 0.
---@nodiscard
function math.upper(x, size) end

--- [SHARED AND MENU]
---
--- Returns x with the same sign as y.
---
---@generic T : number | integer
---@param x T The number to copy the sign of.
---@param y number The number to get the sign from.
---@return T number The number with the sign of y.
---@nodiscard
function math.copySign(x, y) end

--- [SHARED AND MENU]
---
--- Converts an integer with a sign to an unsigned integer.
---
---@generic T : number | integer
---@param x T The number to convert.
---@param bit_count integer The bit count of the unsigned integer.
---@return T unsigned The unsigned integer.
---@nodiscard
function math.toUInt(x, bit_count) end

--- [SHARED AND MENU]
---
--- Converts an signed integer with a sign to an integer.
---
---@generic T : number | integer
---@param x T The number to convert.
---@param bit_count integer The bit count of the signed integer.
---@return T signed The integer with a sign.
---@nodiscard
function math.toInt(x, bit_count) end

--- [SHARED AND MENU]
---
--- Converts a number to a 32-bit unsigned integer.
---
---@generic T : number | integer
---@param x T The number to convert.
---@return T unsigned The 32-bit unsigned integer.
---@nodiscard
function math.toUInt32(x) end

--- [SHARED AND MENU]
---
--- Converts a number to a 32-bit signed integer.
---
---@generic T : number | integer
---@param x T The number to convert.
---@return T signed The 32-bit signed integer.
---@nodiscard
function math.toInt32(x) end

--- [SHARED AND MENU]
---
--- Converts a number to a float32.
---
---@param number number The number to convert.
---@return number float The float32 number.
---@nodiscard
function math.toFloat32(number) end

--- [SHARED AND MENU]
---
--- Returns a function that bucketizes a number.
---
---@generic T : number | integer
---@param y T The bucket size.
---@return fun( x: number ): T bucketizer The bucketizer function.
---@nodiscard
function math.bucketize(y) end

--- [SHARED AND MENU]
---
--- Translate a relative position, negative means back from end.
---
---@param position integer The position to check.
---@param length integer The length to check.
---@param fallback? integer The fallback position.
---@return integer relative The relative position.
---@nodiscard
function math.relative(position, length, fallback) end

--- [SHARED AND MENU]
---
--- Normalizes a `start_position`/`end_position` pair against `length`, same rules as `string.sub`.
---
--- Negative positions count back from the end, `start_position` is clamped to `>= 1` and `end_position` to `[0, length]`.
---
--- An empty range is returned as `start_position > end_position`.
---
---@param length integer The length of the sequence.
---@param start_position? integer The start position, defaults to `1`.
---@param end_position? integer The end position, defaults to `length`.
---@return integer start_position The normalized start position.
---@return integer end_position The normalized end position.
---@nodiscard
function math.range(length, start_position, end_position) end

--- [SHARED AND MENU]
---
--- Returns the length of the integer.
---
---@param x integer The integer to check.
---@return integer length The length of the integer.
---@nodiscard
function math.len(x) end

--- [SHARED AND MENU]
---
--- Returns the floor division of two numbers.
---
---@generic T: number | any
---@param a T The first number.
---@param b T The second number.
---@return T x The floor division of the two numbers.
---@nodiscard
function math.fdiv(a, b) end

--- [SHARED AND MENU]
---
--- The math easing functions.
---
---@class math.ease
local ease = {}

math.ease = ease

--- [SHARED AND MENU]
---
--- Eases in using `math.sin`.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.sineIn(fraction) end

--- [SHARED AND MENU]
---
--- Eases out using `math.sin`.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.sineOut(fraction) end

--- [SHARED AND MENU]
---
--- Eases in and out using `math.sin`.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.sineInOut(fraction) end

--- [SHARED AND MENU]
---
--- Eases in by squaring the fraction.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.quadIn(fraction) end

--- [SHARED AND MENU]
---
--- Eases out by squaring the fraction.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.quadOut(fraction) end

--- [SHARED AND MENU]
---
--- Eases in and out by squaring the fraction.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.quadInOut(fraction) end

--- [SHARED AND MENU]
---
--- Eases in by cubing the fraction.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.cubicIn(fraction) end

--- [SHARED AND MENU]
---
--- Eases out by cubing the fraction.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.cubicOut(fraction) end

--- [SHARED AND MENU]
---
--- Eases in and out by cubing the fraction.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.cubicInOut(fraction) end

--- [SHARED AND MENU]
---
--- Eases in by raising the fraction to the power of 4.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.quartIn(fraction) end

--- [SHARED AND MENU]
---
--- Eases out by raising the fraction to the power of 4.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.quartOut(fraction) end

--- [SHARED AND MENU]
---
--- Eases in and out by raising the fraction to the power of 4.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.quartInOut(fraction) end

--- [SHARED AND MENU]
---
--- Eases in by raising the fraction to the power of 5.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.quintIn(fraction) end

--- [SHARED AND MENU]
---
--- Eases out by raising the fraction to the power of 5.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.quintOut(fraction) end

--- [SHARED AND MENU]
---
--- Eases in and out by raising the fraction to the power of 5.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.quintInOut(fraction) end

--- [SHARED AND MENU]
---
--- Eases in using an exponential equation with a base of 2 and where the fraction is used in the exponent.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.expoIn(fraction) end

--- [SHARED AND MENU]
---
--- Eases out using an exponential equation with a base of 2 and where the fraction is used in the exponent.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.expoOut(fraction) end

--- [SHARED AND MENU]
---
--- Eases in and out using an exponential equation with a base of 2 and where the fraction is used in the exponent.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.expoInOut(fraction) end

--- [SHARED AND MENU]
---
--- Eases in using a circular function.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.circIn(fraction) end

--- [SHARED AND MENU]
---
--- Eases out using a circular function.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.circOut(fraction) end

--- [SHARED AND MENU]
---
--- Eases in and out using a circular function.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.circInOut(fraction) end

--- [SHARED AND MENU]
---
--- Eases in by reversing the direction of the ease slightly before returning.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.backIn(fraction) end

--- [SHARED AND MENU]
---
--- Eases out by reversing the direction of the ease slightly before finishing.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.backOut(fraction) end

--- [SHARED AND MENU]
---
--- Eases in and out by reversing the direction of the ease slightly before returning on both ends.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.backInOut(fraction) end

--- [SHARED AND MENU]
---
--- Eases in like a rubber band.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.elasticIn(fraction) end

--- [SHARED AND MENU]
---
--- Eases out like a rubber band.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.elasticOut(fraction) end

--- [SHARED AND MENU]
---
--- Eases in and out like a rubber band.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.elasticInOut(fraction) end

--- [SHARED AND MENU]
---
--- Eases in like a bouncy ball.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.bounceIn(fraction) end

--- [SHARED AND MENU]
---
--- Eases out like a bouncy ball.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.bounceOut(fraction) end

--- [SHARED AND MENU]
---
--- Eases in and out like a bouncy ball.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
---@nodiscard
function ease.bounceInOut(fraction) end
