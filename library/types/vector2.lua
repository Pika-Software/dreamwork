---@meta _

--- [SHARED AND MENU]
---
--- A 2D vector object, e.g. a screen position or a size.
---
--- Arithmetic operators work component-wise:
--- * `vec2 + vec2`, `vec2 + number`, `number + vec2` ( same for `-` and `*` )
--- * `vec2 / vec2`, `vec2 / number`
--- * `-vec2`
---
---@class Vector2 : Object
---@field __class Vector2Class
---@operator add( Vector2 | number ): Vector2
---@operator sub( Vector2 | number ): Vector2
---@operator mul( Vector2 | number ): Vector2
---@operator div( Vector2 | number ): Vector2
---@operator unm: Vector2
---@field x number The X coordinate.
---@field y number The Y coordinate.
local __Vector2 = {}

--- [SHARED AND MENU]
---
--- The class used to create new `Vector2` instances.
---
--- ```lua
--- local vec = Vector2( 1, 2 )
--- local zero = Vector2()
--- ```
---
---@class Vector2Class : Vector2
---@field __base Vector2
---@field origin Vector2 The shared zero vector `( 0, 0 )`, **must not be modified**.
---@overload fun( x: number?, y: number? ): Vector2
Vector2 = {}

---@param value any
---@return boolean is_vector2
---@nodiscard
function isVector2(value) end

--- Creates a new vector, missing coordinates default to `0`.
---
---@param x? number The X coordinate, defaults to `0`.
---@param y? number The Y coordinate, defaults to `0`.
---@return Vector2 vec2 The new vector.
---@protected
function Vector2:__new(x, y) end

--- Debug representation, e.g. `Vector2: 0x01234567 [1.000000, 2.000000]`.
---
---@return string str The debug representation.
---@protected
function __Vector2:__represent() end

--- String conversion, e.g. `1.000000 2.000000`.
---
---@return string str The string representation.
---@protected
function __Vector2:__tostring() end

--- Exact component-wise comparison, comparing with a non-vector value returns `false`.
---
---@param other any The value to compare with.
---@return boolean is_equal `true` if both are vectors with equal coordinates.
---@protected
function __Vector2:__eq(other) end

--- Writes the vector as two 32-bit floats ( precision is reduced to float ).
---
---@param writer BinaryWriter The writer.
---@protected
function __Vector2:__serialize(writer) end

--- Reads the vector from two 32-bit floats.
---
---@param reader BinaryReader The reader.
---@protected
function __Vector2:__deserialize(reader) end

--- [SHARED AND MENU]
---
--- Returns the x and y coordinates of the vector.
---
---@return number x The x coordinate of the vector.
---@return number y The y coordinate of the vector.
---@nodiscard
function __Vector2:unpack() end

--- [SHARED AND MENU]
---
--- Sets the x and y coordinates of the vector.
---
---@param x number The x coordinate of the vector.
---@param y number The y coordinate of the vector.
---@return Vector2 vec2 The same vector.
function __Vector2:setUnpacked(x, y) end

--- [SHARED AND MENU]
---
--- Copies the coordinates of another vector into this vector.
---
---@param vector Vector2 The vector to copy from.
---@return Vector2 vec2 The same vector.
function __Vector2:set(vector) end

--- [SHARED AND MENU]
---
--- Creates a new independent copy of the vector.
---
---@param self Vector2 The vector.
---@return Vector2 copy The new vector.
---@nodiscard
function __Vector2.copy(self) end

--- [SHARED AND MENU]
---
--- Checks if all coordinates of the vector are exactly zero.
---
---@return boolean is_zero `true` if the vector is zero, `false` otherwise.
---@nodiscard
function __Vector2:isZero() end

--- [SHARED AND MENU]
---
--- Sets all coordinates of the vector to zero.
---
---@return Vector2 vec2 The same vector.
function __Vector2:zero() end

--- [SHARED AND MENU]
---
--- Checks if the vector is equal to the given vector with the given tolerance.
---
--- Each coordinate is compared separately: `|a.x - b.x| <= tolerance` and so on.
---
---@param vector Vector2 The vector to check.
---@param tolerance number The maximum allowed difference per coordinate.
---@return boolean is_near `true` if the vectors are equal within the tolerance, otherwise `false`.
---@nodiscard
function __Vector2:isNear(vector, tolerance) end

--- [SHARED AND MENU]
---
--- Negates all coordinates of the vector.
---
---@return Vector2 vec2 The same vector, negated.
function __Vector2:negate() end

--- `-vec2`
---
---@return Vector2 negated The new vector.
---@protected
function __Vector2:__unm() end

--- [SHARED AND MENU]
---
--- Multiplies all coordinates of the vector by the number.
---
---@param self Vector2 The vector.
---@param scale number The scale factor.
---@return Vector2 vec2 The same vector, scaled.
function __Vector2.scale(self, scale) end

--- [SHARED AND MENU]
---
--- Returns a scaled copy of the vector.
---
---@param scale number The scale factor.
---@return Vector2 scaled_vec2 The new vector.
---@nodiscard
function __Vector2:getScaled(scale) end

--- [SHARED AND MENU]
---
--- Adds another vector or a number ( to every coordinate ) to the vector.
---
---@param value Vector2 | number The other vector or a number.
---@return Vector2 vec2 The same vector, with the sum.
function __Vector2:add(value) end

--- `vec2 + vec2`, `vec2 + number` and `number + vec2`.
---
---@param a Vector2 | number
---@param b Vector2 | number
---@return Vector2 sum The new vector.
---@protected
function __Vector2.__add(a, b) end

--- [SHARED AND MENU]
---
--- Subtracts another vector or a number ( from every coordinate ) from the vector.
---
---@param value Vector2 | number The other vector or a number.
---@return Vector2 vec2 The same vector, with the difference.
function __Vector2:sub(value) end

--- `vec2 - vec2`, `vec2 - number` and `number - vec2`.
---
---@param a Vector2 | number
---@param b Vector2 | number
---@return Vector2 difference The new vector.
---@protected
function __Vector2.__sub(a, b) end

--- [SHARED AND MENU]
---
--- Multiplies the vector by another vector ( component-wise ) or a number.
---
---@param value Vector2 | number The other vector or a number.
---@return Vector2 vec2 The same vector, with the product.
function __Vector2:mul(value) end

--- `vec2 * vec2` ( component-wise ), `vec2 * number` and `number * vec2`.
---
---@param a Vector2 | number
---@param b Vector2 | number
---@return Vector2 product The new vector.
---@protected
function __Vector2.__mul(a, b) end

--- [SHARED AND MENU]
---
--- Divides the vector by another vector ( component-wise ) or a number.
---
--- Modifies the vector in place, division by zero is not checked and results in `inf` / `nan` components.
---
---@param value Vector2 | number The divisor vector or number.
---@return Vector2 vec2 The same vector, divided.
function __Vector2:div(value) end

--- `vec2 / number`, `vec2 / vec2` and `number / vec2` ( component-wise ).
---
--- e.g. `position / screen_size` converts pixels into the [0, 1] range.
---
---@param a Vector2 | number
---@param b Vector2 | number
---@return Vector2 quotient The new vector.
---@protected
function __Vector2.__div(a, b) end

--- [SHARED AND MENU]
---
--- Calculates the dot product of two vectors.
---
---@param vector Vector2 The other vector.
---@return number dot_product The dot product of two vectors.
---@nodiscard
function __Vector2:dot(vector) end

--- [SHARED AND MENU]
---
--- Calculates the 2D cross product ( Z component of the 3D cross product ) of two vectors.
---
--- Positive if `vector` is counter-clockwise from the vector, negative if clockwise, zero if parallel.
---
---@param vector Vector2 The other vector.
---@return number cross_product The cross product of two vectors.
---@nodiscard
function __Vector2:cross(vector) end

--- [SHARED AND MENU]
---
--- Calculates the squared length of the vector.
---
--- Faster than `getLength`, use it to compare lengths.
---
---@param self Vector2 The vector.
---@return number length The squared length of the vector.
---@nodiscard
function __Vector2.getLengthSqr(self) end

--- [SHARED AND MENU]
---
--- Calculates the length of the vector.
---
---@param self Vector2 The vector.
---@return number length The length of the vector.
---@nodiscard
function __Vector2.getLength(self) end

--- [SHARED AND MENU]
---
--- Calculates the squared distance between two vectors.
---
--- Faster than `getDistance`, use it to compare distances.
---
---@param vector Vector2 The other vector.
---@return number distance The squared distance between the two vectors.
---@nodiscard
function __Vector2:getDistanceSqr(vector) end

--- [SHARED AND MENU]
---
--- Calculates the distance between two vectors.
---
---@param vector Vector2 The other vector.
---@return number distance The distance between the two vectors.
---@nodiscard
function __Vector2:getDistance(vector) end

--- [SHARED AND MENU]
---
--- Scales the vector to the length of `1`.
---
--- Zero vector stays unchanged.
---
---@param self Vector2 The vector.
---@return Vector2 vec2 The same vector, normalized.
function __Vector2.normalize(self) end

--- [SHARED AND MENU]
---
--- Returns a copy of the vector with the length of `1`.
---
--- Zero vector returns a zero copy.
---
---@return Vector2 normalized_vec2 The new vector.
---@nodiscard
function __Vector2:getNormalized() end

--- [SHARED AND MENU]
---
--- Returns the angle of the vector in degrees, measured clockwise from the `+y` axis in range ( 0, 360 ].
---
--- If `up` is given, its angle is added to the result.
---
---@param self Vector2 The vector.
---@param up? Vector2 The direction of the angle.
---@return number degrees The angle of the vector.
---@nodiscard
function __Vector2.getAngle(self, up) end

--- [SHARED AND MENU]
---
--- Rotates the vector counter-clockwise ( from `+x` towards `+y` ) by the given degrees.
---
---@param self Vector2 The vector.
---@param degrees number The rotation angle.
---@return Vector2 vec2 The same vector, rotated.
function __Vector2.rotate(self, degrees) end

--- [SHARED AND MENU]
---
--- Returns a copy of the vector rotated counter-clockwise ( from `+x` towards `+y` ) by the given degrees.
---
---@param degrees number The rotation angle.
---@return Vector2 rotated_vec2 The new vector.
---@nodiscard
function __Vector2:getRotated(degrees) end

--- [SHARED AND MENU]
---
--- Linear interpolation between the vector and another vector or a number.
---
--- `frac` of `0` keeps the vector, `1` sets it to the target, values outside [0, 1] extrapolate.
---
---@param self Vector2 The vector.
---@param target Vector2 | number The target vector or a number ( used for every coordinate ).
---@param frac number The interpolation factor.
---@return Vector2 vec2 The same vector, interpolated.
function __Vector2.lerp(self, target, frac) end

--- [SHARED AND MENU]
---
--- Returns a copy of the vector linearly interpolated to another vector or a number.
---
---@param self Vector2 The vector.
---@param target Vector2 | number The target vector or a number ( used for every coordinate ).
---@param frac number The interpolation factor.
---@return Vector2 lerped_vec2 The new vector.
---@nodiscard
function __Vector2.getLerped(self, target, frac) end
