---@meta _

--- [SHARED AND MENU]
---
--- A 3D angle object ( pitch, yaw, roll in degrees ) in Source engine convention.
---
--- Arithmetic operators work component-wise:
--- * `ang3 + ang3`, `ang3 + number`, `number + ang3` ( same for `-` )
--- * `ang3 * number`, `number * ang3`, `ang3 / number`
--- * `-ang3`
---
--- Multiplying or dividing two angles is not supported, it has no geometric meaning.
---
---@class Angle3 : Object
---@field __class Angle3Class
---@operator add( Angle3 | number ): Angle3
---@operator sub( Angle3 | number ): Angle3
---@operator mul( number ): Angle3
---@operator div( number ): Angle3
---@operator unm: Angle3
---@field pitch number Rotation around the Y axis in degrees, positive pitch looks down.
---@field yaw number Rotation around the Z axis in degrees, positive yaw turns left.
---@field roll number Rotation around the X axis in degrees, positive roll tilts right.
local __Angle3 = {}

--- [SHARED AND MENU]
---
--- The class used to create new `Angle3` instances.
---
--- ```lua
--- local ang = Angle3( 0, 90, 0 ) -- looking left
--- local zero = Angle3()
--- ```
---
---@class Angle3Class : Angle3
---@field __base Angle3
---@field zero Angle3 The shared zero angle `( 0, 0, 0 )`, **must not be modified**.
---@overload fun( pitch: number?, yaw: number?, roll: number? ): Angle3
Angle3 = {}

---@param value any
---@return boolean is_angle3
---@nodiscard
function isAngle3(value) end

--- Creates a new angle, missing values default to `0`.
---
---@param pitch? number The pitch in degrees, defaults to `0`.
---@param yaw? number The yaw in degrees, defaults to `0`.
---@param roll? number The roll in degrees, defaults to `0`.
---@return Angle3 ang3 The new angle.
---@protected
function Angle3:__new(pitch, yaw, roll) end

--- Debug representation, e.g. `Angle3: 0x01234567 [0.000000, 90.000000, 0.000000]`.
---
---@return string str The debug representation.
---@protected
function __Angle3:__represent() end

--- String conversion in Garry's Mod `Angle` format, e.g. `0.000000 90.000000 0.000000`.
---
---@return string str The string representation.
---@protected
function __Angle3:__tostring() end

--- Exact component-wise comparison without normalization, comparing with a non-angle value returns `false`.
---
--- `( 0, 360, 0 )` and `( 0, 0, 0 )` are not equal, use `getNormalized` first if needed.
---
---@param other any The value to compare with.
---@return boolean is_equal `true` if both are angles with equal values.
---@protected
function __Angle3:__eq(other) end

--- [SHARED AND MENU]
---
--- Returns the pitch, yaw and roll of the angle.
---
---@return number pitch The pitch in degrees.
---@return number yaw The yaw in degrees.
---@return number roll The roll in degrees.
---@nodiscard
function __Angle3:unpack() end

--- [SHARED AND MENU]
---
--- Sets the pitch, yaw and roll of the angle.
---
---@param pitch number The pitch in degrees.
---@param yaw number The yaw in degrees.
---@param roll number The roll in degrees.
---@return Angle3 ang3 The same angle.
function __Angle3:setUnpacked(pitch, yaw, roll) end

--- [SHARED AND MENU]
---
--- Copies the values of another angle into this angle.
---
---@param angle Angle3 The angle to copy from.
---@return Angle3 ang3 The same angle.
function __Angle3:set(angle) end

--- [SHARED AND MENU]
---
--- Creates a new independent copy of the angle.
---
---@param self Angle3 The angle.
---@return Angle3 copy The new angle.
---@nodiscard
function __Angle3.copy(self) end

--- [SHARED AND MENU]
---
--- Checks if all values of the angle are exactly zero.
---
---@return boolean is_zero `true` if the angle is zero, `false` otherwise.
---@nodiscard
function __Angle3:isZero() end

--- [SHARED AND MENU]
---
--- Sets all values of the angle to zero.
---
---@return Angle3 ang3 The same angle.
function __Angle3:zero() end

--- [SHARED AND MENU]
---
--- Checks if the angle is equal to the given angle with the given tolerance.
---
--- Values are compared as is, without normalization, so `359` and `-1` are not near.
---
---@param angle Angle3 The angle to check against.
---@param tolerance number The maximum allowed difference per value in degrees.
---@return boolean is_near `true` if the angles are equal within the tolerance, otherwise `false`.
---@nodiscard
function __Angle3:isNear(angle, tolerance) end

--- [SHARED AND MENU]
---
--- Negates all values of the angle.
---
---@return Angle3 ang3 The same angle, negated.
function __Angle3:negate() end

--- `-ang3`
---
---@return Angle3 negated The new angle.
---@protected
function __Angle3:__unm() end

--- [SHARED AND MENU]
---
--- Adds another angle or a number ( to every value ) to the angle.
---
---@param value Angle3 | number The other angle or a number of degrees.
---@return Angle3 ang3 The same angle, with the sum.
function __Angle3:add(value) end

--- `ang3 + ang3`, `ang3 + number` and `number + ang3`.
---
---@param a Angle3 | number
---@param b Angle3 | number
---@return Angle3 sum The new angle.
---@protected
function __Angle3.__add(a, b) end

--- [SHARED AND MENU]
---
--- Subtracts another angle or a number ( from every value ) from the angle.
---
---@param value Angle3 | number The other angle or a number of degrees.
---@return Angle3 ang3 The same angle, with the difference.
function __Angle3:sub(value) end

--- `ang3 - ang3`, `ang3 - number` and `number - ang3`.
---
---@param a Angle3 | number
---@param b Angle3 | number
---@return Angle3 difference The new angle.
---@protected
function __Angle3.__sub(a, b) end

--- [SHARED AND MENU]
---
--- Multiplies all values of the angle by the number.
---
---@param self Angle3 The angle.
---@param scale number The scale factor.
---@return Angle3 ang3 The same angle, scaled.
function __Angle3.mul(self, scale) end

--- [SHARED AND MENU]
---
--- Multiplies all values of the angle by the number.
---
---@param self Angle3 The angle.
---@param scale number The scale factor.
---@return Angle3 ang3 The same angle, scaled.
function __Angle3.scale(self, scale) end

--- `ang3 * number` and `number * ang3`, `ang3 * ang3` raises an error.
---
---@param a Angle3 | number
---@param b Angle3 | number
---@return Angle3 product The new angle.
---@protected
function __Angle3.__mul(a, b) end

--- [SHARED AND MENU]
---
--- Divides all values of the angle by the number.
---
--- Division by zero is not checked and results in `inf` / `nan` values.
---
---@param divisor number The divisor.
---@return Angle3 ang3 The same angle, divided.
function __Angle3:div(divisor) end

--- `ang3 / number`, both `ang3 / ang3` and `number / ang3` raise an error.
---
---@param a Angle3 | number
---@param b Angle3 | number
---@return Angle3 quotient The new angle.
---@protected
function __Angle3.__div(a, b) end

--- [SHARED AND MENU]
---
--- Linearly interpolates the angle ( component-wise, without normalization ).
---
--- Interpolating from `350` to `10` goes the long way through `180`,
--- normalize both angles or use `Quaternion:slerp` for the shortest rotation.
---
---@param self Angle3 The angle.
---@param target Angle3 | number The target angle or a number of degrees ( used for every value ).
---@param frac number The interpolation factor, `0` keeps the angle, `1` sets it to the target.
---@return Angle3 ang3 The same angle, interpolated.
function __Angle3.lerp(self, target, frac) end

--- [SHARED AND MENU]
---
--- Returns a copy of the angle linearly interpolated to another angle or a number.
---
---@param target Angle3 | number The target angle or a number of degrees ( used for every value ).
---@param frac number The interpolation factor, `0` keeps the angle, `1` sets it to the target.
---@return Angle3 lerped_ang3 The new angle.
---@nodiscard
function __Angle3:getLerped(target, frac) end

--- [SHARED AND MENU]
---
--- Normalizes the angle, all values will be in range [-180, 180).
---
--- Same as `Angle:Normalize` in Garry's Mod.
---
---@param self Angle3 The angle.
---@return Angle3 ang3 The same angle, normalized.
function __Angle3.normalize(self) end

--- [SHARED AND MENU]
---
--- Returns a normalized copy of the angle, all values will be in range [-180, 180).
---
---@return Angle3 normalized_ang3 The new angle.
---@nodiscard
function __Angle3:getNormalized() end

--- [SHARED AND MENU]
---
--- Returns the forward, right and up directions of the angle at once.
---
--- Same as `AngleVectors` in Source engine, faster than calling `getForward`, `getRight` and `getUp` separately.
---
---@return Vector3 forward_dir The new normalized forward direction.
---@return Vector3 right_dir The new normalized right direction.
---@return Vector3 up_dir The new normalized up direction.
---@nodiscard
function __Angle3:getVectors() end

--- [SHARED AND MENU]
---
--- Returns the forward direction of the angle, roll does not affect it.
---
--- Same as `Angle:Forward` in Garry's Mod.
---
---@return Vector3 forward_dir The new normalized direction.
---@nodiscard
function __Angle3:getForward() end

--- [SHARED AND MENU]
---
--- Returns the backward direction of the angle ( negated forward ).
---
---@return Vector3 backward_dir The new normalized direction.
---@nodiscard
function __Angle3:getBackward() end

--- [SHARED AND MENU]
---
--- Returns the right direction of the angle.
---
--- Same as `Angle:Right` in Garry's Mod.
---
---@return Vector3 right_dir The new normalized direction.
---@nodiscard
function __Angle3:getRight() end

--- [SHARED AND MENU]
---
--- Returns the left direction of the angle ( negated right ).
---
---@return Vector3 left_dir The new normalized direction.
---@nodiscard
function __Angle3:getLeft() end

--- [SHARED AND MENU]
---
--- Returns the up direction of the angle.
---
--- Same as `Angle:Up` in Garry's Mod.
---
---@return Vector3 up_dir The new normalized direction.
---@nodiscard
function __Angle3:getUp() end

--- [SHARED AND MENU]
---
--- Returns the down direction of the angle ( negated up ).
---
---@return Vector3 down_dir The new normalized direction.
---@nodiscard
function __Angle3:getDown() end

--- [SHARED AND MENU]
---
--- Rotates the angle around the specified world axis by the specified degrees.
---
--- Same as `Angle:RotateAroundAxis` in Garry's Mod, rotation follows the right-hand rule:
--- * around `ang:getUp()` positive degrees turn left ( add yaw ).
--- * around `ang:getRight()` positive degrees look up ( subtract pitch ).
--- * around `ang:getForward()` positive degrees tilt right ( add roll ).
---
--- The result is not normalized.
---
---@param self Angle3 The angle.
---@param axis Vector3 The world axis to rotate around, must be normalized.
---@param degrees number The degrees to rotate around the axis.
---@return Angle3 ang3 The same angle, rotated.
function __Angle3.rotate(self, axis, degrees) end

--- [SHARED AND MENU]
---
--- Returns a copy of the angle rotated around the specified world axis by the specified degrees.
---
--- See `Angle3:rotate` for the rotation direction.
---
---@param axis Vector3 The world axis to rotate around, must be normalized.
---@param degrees number The degrees to rotate around the axis.
---@return Angle3 rotated_ang3 The new angle.
---@nodiscard
function __Angle3:getRotated(axis, degrees) end

--- [SHARED AND MENU]
---
--- Returns the rotation of the angle as a quaternion.
---
--- Same as `AngleQuaternion` in Source engine.
---
---@return Quaternion quat The new unit quaternion.
---@nodiscard
function __Angle3:toQuaternion() end

--- [SHARED AND MENU]
---
--- Returns the rotation of the angle as a matrix without translation.
---
--- Same as `AngleMatrix` in Source engine.
---
---@return VMatrix matrix The new rotation matrix.
---@nodiscard
function __Angle3:toVMatrix() end
