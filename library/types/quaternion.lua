---@meta _

--- [SHARED AND MENU]
---
--- A quaternion object, mostly used to represent rotations without gimbal lock.
---
--- Rotation quaternions must be unit length, `q` and `-q` represent the same rotation.
---
--- Operators:
--- * `quat * quat` - Hamilton product, `a * b` rotates by `b` first, then by `a`.
--- * `quat * vec3` - rotates the vector, returns a new `Vector3`.
--- * `quat / quat` - `a * b:getInverse()`, the rotation from `b` to `a`.
--- * `quat + quat`, `quat - quat` - component-wise.
--- * `quat +- number`, `number +- quat` - adds to / subtracts from the real part.
--- * `quat * number`, `number * quat`, `quat / number` - scales all components.
--- * `quat ^ number` - raises to the power ( scales the rotation angle ), `number ^ quat` - exponent.
--- * `-quat` - negates all components.
---
---@class Quaternion : Object
---@field __class QuaternionClass
---@operator add( Quaternion | number ): Quaternion
---@operator sub( Quaternion | number ): Quaternion
---@operator mul( Vector3 ): Vector3
---@operator mul( Quaternion | number ): Quaternion
---@operator div( Quaternion | number ): Quaternion
---@operator pow( number ): Quaternion
---@operator unm: Quaternion
---@field w number The real part ( `r` ), `cos( angle / 2 )` for rotations.
---@field x number The first imaginary part ( `i` ), `axis.x * sin( angle / 2 )` for rotations.
---@field y number The second imaginary part ( `j` ), `axis.y * sin( angle / 2 )` for rotations.
---@field z number The third imaginary part ( `k` ), `axis.z * sin( angle / 2 )` for rotations.
local __Quaternion = {}

--- [SHARED AND MENU]
---
--- The class used to create new `Quaternion` instances.
---
--- ```lua
--- local quat = Quaternion( 1, 0, 0, 0 ) -- identity, same as `Quaternion.identity()`
--- local rotation = Quaternion.fromAngles( 0, 90, 0 )
--- ```
---
---@class QuaternionClass : Quaternion
---@field __base Quaternion
---@overload fun( r: number?, i: number?, j: number?, k: number? ): Quaternion
Quaternion = {}

---@param value any
---@return boolean is_quaternion
---@nodiscard
function isQuaternion(value) end

--- Creates a new quaternion, missing components default to `0`.
---
--- Note that `Quaternion()` is a zero quaternion, not identity.
---
---@param r? number The real component ( `w` ), defaults to `0`.
---@param i? number The first imaginary component ( `x` ), defaults to `0`.
---@param j? number The second imaginary component ( `y` ), defaults to `0`.
---@param k? number The third imaginary component ( `z` ), defaults to `0`.
---@return Quaternion quat The new quaternion.
---@protected
function Quaternion:__new(r, i, j, k) end

--- Debug representation, e.g. `Quaternion: 0x01234567 [1.000000, 0.000000, 0.000000, 0.000000]`.
---
---@return string str The debug representation.
---@protected
function __Quaternion:__represent() end

--- String conversion in `w x y z` order, e.g. `1.000000 0.000000 0.000000 0.000000`.
---
---@return string str The string representation.
---@protected
function __Quaternion:__tostring() end

--- Exact component-wise comparison, comparing with a non-quaternion value returns `false`.
---
--- `q` and `-q` are not equal even though they represent the same rotation.
---
---@param other any The value to compare with.
---@return boolean is_equal `true` if both are quaternions with equal components.
---@protected
function __Quaternion:__eq(other) end

--- [SHARED AND MENU]
---
--- Returns the w ( r ), x ( i ), y ( j ), and z ( k ) components of the quaternion.
---
---@return number w The real component.
---@return number x The first imaginary component.
---@return number y The second imaginary component.
---@return number z The third imaginary component.
---@nodiscard
function __Quaternion:unpack() end

--- [SHARED AND MENU]
---
--- Sets the w ( r ), x ( i ), y ( j ), and z ( k ) components of the quaternion.
---
---@param w number The real component.
---@param x number The first imaginary component.
---@param y number The second imaginary component.
---@param z number The third imaginary component.
---@return Quaternion quat The same quaternion.
function __Quaternion:setUnpacked(w, x, y, z) end

--- [SHARED AND MENU]
---
--- Copies the components of another quaternion into this quaternion.
---
---@param quaternion Quaternion The quaternion to copy from.
---@return Quaternion quat The same quaternion.
function __Quaternion:set(quaternion) end

--- [SHARED AND MENU]
---
--- Creates a new independent copy of the quaternion.
---
---@param self Quaternion The quaternion.
---@return Quaternion copy The new quaternion.
---@nodiscard
function __Quaternion.copy(self) end

--- [SHARED AND MENU]
---
--- Sets the quaternion to identity `( 1, 0, 0, 0 )`, which means no rotation.
---
---@return Quaternion quat The same quaternion.
function __Quaternion:identity() end

--- [SHARED AND MENU]
---
--- Checks if the quaternion is exactly identity `( 1, 0, 0, 0 )`.
---
--- `( -1, 0, 0, 0 )` also means no rotation, but is not identity.
---
---@return boolean is_identity `true` if the quaternion is identity, `false` otherwise.
---@nodiscard
function __Quaternion:isIdentity() end

--- [SHARED AND MENU]
---
--- Sets all components of the quaternion to zero.
---
--- A zero quaternion is not a valid rotation.
---
---@return Quaternion quat The same quaternion.
function __Quaternion:zero() end

--- [SHARED AND MENU]
---
--- Checks if all components of the quaternion are exactly zero.
---
---@return boolean is_zero `true` if the quaternion is zero, `false` otherwise.
---@nodiscard
function __Quaternion:isZero() end

--- [SHARED AND MENU]
---
--- Checks if the quaternion is real ( all imaginary components are zero ).
---
---@return boolean is_real `true` if the quaternion is real, `false` otherwise.
---@nodiscard
function __Quaternion:isReal() end

--- [SHARED AND MENU]
---
--- Checks if the quaternion is pure imaginary ( real component is zero ).
---
--- Unit pure imaginary quaternions are 180 degree rotations.
---
---@return boolean is_imaginary `true` if the quaternion is pure imaginary, `false` otherwise.
---@nodiscard
function __Quaternion:isImaginary() end

--- [SHARED AND MENU]
---
--- Checks if the quaternion is equal to the given quaternion with the given tolerance.
---
--- Each component is compared separately, `q` and `-q` are not near, compare `getAngle` of `a / b` to check rotations.
---
---@param quaternion Quaternion The quaternion to check.
---@param tolerance number The maximum allowed difference per component.
---@return boolean is_near `true` if the quaternions are equal within the tolerance, otherwise `false`.
---@nodiscard
function __Quaternion:isNear(quaternion, tolerance) end

--- [SHARED AND MENU]
---
--- Calculates the dot product of two quaternions.
---
--- For unit quaternions it is `cos( angle / 2 )` of the rotation between them, negative means they are more than 180 degrees apart.
---
---@param self Quaternion The quaternion.
---@param quaternion Quaternion The other quaternion.
---@return number dot_product The dot product of two quaternions.
---@nodiscard
function __Quaternion.dot(self, quaternion) end

--- [SHARED AND MENU]
---
--- Calculates the squared length ( norm ) of the quaternion.
---
--- Faster than `getLength`, `1` for unit quaternions.
---
---@param self Quaternion The quaternion.
---@return number length The squared length of the quaternion.
---@nodiscard
function __Quaternion.getLengthSqr(self) end

--- [SHARED AND MENU]
---
--- Calculates the length ( norm ) of the quaternion.
---
---@param self Quaternion The quaternion.
---@return number length The length of the quaternion.
---@nodiscard
function __Quaternion.getLength(self) end

--- [SHARED AND MENU]
---
--- Multiplies all components of the quaternion by the number.
---
--- Scaling does not change the rotation, but makes the quaternion non-unit.
---
---@param self Quaternion The quaternion.
---@param scale number The scale factor.
---@return Quaternion quat The same quaternion, scaled.
function __Quaternion.scale(self, scale) end

--- [SHARED AND MENU]
---
--- Returns a scaled copy of the quaternion.
---
---@param scale number The scale factor.
---@return Quaternion scaled_quat The new quaternion.
---@nodiscard
function __Quaternion:getScaled(scale) end

--- [SHARED AND MENU]
---
--- Negates all components of the quaternion.
---
--- `q` and `-q` represent the same rotation.
---
---@return Quaternion quat The same quaternion, negated.
function __Quaternion:negate() end

--- `-quat`
---
---@return Quaternion negated The new quaternion.
---@protected
function __Quaternion:__unm() end

--- [SHARED AND MENU]
---
--- Scales the quaternion to the length of `1`.
---
--- Normalize after many multiplications to remove accumulated floating point errors.
---
--- Zero quaternion stays unchanged.
---
---@param self Quaternion The quaternion.
---@return Quaternion quat The same quaternion, normalized.
function __Quaternion.normalize(self) end

--- [SHARED AND MENU]
---
--- Returns a copy of the quaternion with the length of `1`.
---
--- Zero quaternion returns a zero copy.
---
---@return Quaternion normalized_quat The new quaternion.
---@nodiscard
function __Quaternion:getNormalized() end

--- [SHARED AND MENU]
---
--- Conjugates the quaternion ( negates the imaginary part ).
---
--- For unit quaternions the conjugate is the inverse rotation, faster than `invert`.
---
---@return Quaternion quat The same quaternion, conjugated.
function __Quaternion:conjugate() end

--- [SHARED AND MENU]
---
--- Returns the conjugate of the quaternion ( imaginary part negated ).
---
--- For unit quaternions the conjugate is the inverse rotation, faster than `getInverse`.
---
---@return Quaternion conjugated_quat The new quaternion.
---@nodiscard
function __Quaternion:getConjugate() end

--- [SHARED AND MENU]
---
--- Inverts the quaternion, so `q * q:getInverse()` is identity.
---
--- Works with non-unit quaternions, zero quaternion stays unchanged.
---
---@param self Quaternion The quaternion.
---@return Quaternion quat The same quaternion, inverted.
function __Quaternion.invert(self) end

--- [SHARED AND MENU]
---
--- Returns the inverse of the quaternion, so `q * q:getInverse()` is identity.
---
---@return Quaternion inverted_quat The new quaternion.
---@nodiscard
function __Quaternion:getInverse() end

--- [SHARED AND MENU]
---
--- Adds another quaternion ( component-wise ) or a real number ( to `w` only ) to the quaternion.
---
---@param self Quaternion The quaternion.
---@param value Quaternion | number The other quaternion or a real number.
---@return Quaternion quat The same quaternion, with the sum.
function __Quaternion.add(self, value) end

--- `quat + quat`, `quat + number` and `number + quat`, numbers are added to the real part.
---
---@param a Quaternion | number
---@param b Quaternion | number
---@return Quaternion sum The new quaternion.
---@protected
function __Quaternion.__add(a, b) end

--- [SHARED AND MENU]
---
--- Subtracts another quaternion ( component-wise ) or a real number ( from `w` only ) from the quaternion.
---
---@param self Quaternion The quaternion.
---@param value Quaternion | number The other quaternion or a real number.
---@return Quaternion quat The same quaternion, with the difference.
function __Quaternion.sub(self, value) end

--- `quat - quat`, `quat - number` and `number - quat`, numbers are applied to the real part.
---
---@param a Quaternion | number
---@param b Quaternion | number
---@return Quaternion difference The new quaternion.
---@protected
function __Quaternion.__sub(a, b) end

--- [SHARED AND MENU]
---
--- Multiplies the quaternion by another quaternion ( Hamilton product, `self = self * value` ) or by a number.
---
--- For rotations `a * b` means "rotate by `b`, then by `a`", use `premul` for the opposite order.
---
---@param self Quaternion The quaternion.
---@param value Quaternion | number The other quaternion or a number.
---@return Quaternion quat The same quaternion, with the product.
function __Quaternion.mul(self, value) end

--- [SHARED AND MENU]
---
--- Multiplies another quaternion by this quaternion ( `self = value * self` ).
---
--- For rotations it applies `value` after the current rotation.
---
---@param value Quaternion The other quaternion.
---@return Quaternion quat The same quaternion, with the product.
function __Quaternion:premul(value) end

--- [SHARED AND MENU]
---
--- Divides the quaternion by another quaternion ( `self = self * value:getInverse()` ) or by a number.
---
--- For rotations `a / b` is the rotation that turns `b` into `a`.
---
--- Division by a zero number is not checked and results in `inf` / `nan` components.
---
---@param self Quaternion The quaternion.
---@param value Quaternion | number The divisor quaternion or number.
---@return Quaternion quat The same quaternion, divided.
function __Quaternion.div(self, value) end

--- [SHARED AND MENU]
---
--- Returns a copy of the vector rotated by the quaternion, same as `quat * vec3`.
---
--- Works with non-unit quaternions, zero quaternion returns an unrotated copy.
---
---@param self Quaternion The quaternion.
---@param vector Vector3 The vector to rotate.
---@return Vector3 rotated_vec3 The new vector.
---@nodiscard
function __Quaternion.getRotatedVector3(self, vector) end

--- [SHARED AND MENU]
---
--- Rotates the given vector by the quaternion in place.
---
--- Unlike other methods, this one modifies the **vector**, not the quaternion.
---
---@param vector Vector3 The vector to rotate.
---@return Vector3 vec3 The same vector, rotated.
function __Quaternion:rotateVector3(vector) end

--- `quat * quat` ( Hamilton product ), `quat * vec3` ( rotates the vector ), `quat * number` and `number * quat`.
---
---@param a Quaternion | number
---@param b Quaternion | number | Vector3
---@return Quaternion | Vector3 product The new quaternion, or the new vector for `quat * vec3`.
---@protected
function __Quaternion.__mul(a, b) end

--- `quat / quat`, `number / quat` ( both are `a * b:getInverse()` ) and `quat / number`.
---
---@param a Quaternion | number
---@param b Quaternion | number
---@return Quaternion quotient The new quaternion.
---@protected
function __Quaternion.__div(a, b) end

--- [SHARED AND MENU]
---
--- Raises `e` to the power of the quaternion.
---
--- For a pure imaginary `( 0, axis * angle / 2 )` it returns the rotation quaternion of `angle` radians around `axis`.
---
---@param self Quaternion The quaternion.
---@return Quaternion quat The same quaternion, exponentiated.
function __Quaternion.exp(self) end

--- [SHARED AND MENU]
---
--- Returns `e` raised to the power of the quaternion.
---
---@return Quaternion exp_quat The new quaternion.
---@nodiscard
function __Quaternion:getExp() end

--- [SHARED AND MENU]
---
--- Calculates the natural logarithm of the quaternion, the inverse of `exp`.
---
--- For unit quaternions the result is pure imaginary `( 0, axis * angle / 2 )`,
--- zero quaternion results in `( -inf, 0, 0, 0 )`.
---
---@param self Quaternion The quaternion.
---@return Quaternion quat The same quaternion, logarithm.
function __Quaternion.log(self) end

--- [SHARED AND MENU]
---
--- Returns the natural logarithm of the quaternion.
---
---@return Quaternion log_quat The new quaternion.
---@nodiscard
function __Quaternion:getLog() end

--- [SHARED AND MENU]
---
--- Raises the quaternion to the given power, same as `quat ^ exponent`.
---
--- For unit quaternions this scales the rotation angle, e.g. `0.5` returns half of the rotation.
---
---@param self Quaternion The quaternion.
---@param exponent number The exponent.
---@return Quaternion quat The same quaternion, raised to the power.
function __Quaternion.pow(self, exponent) end

--- [SHARED AND MENU]
---
--- Returns the quaternion raised to the given power.
---
---@param exponent number The exponent.
---@return Quaternion pow_quat The new quaternion.
---@nodiscard
function __Quaternion:getPow(exponent) end

--- `quat ^ number` ( power ) and `number ^ quat` ( exponent with the given base ).
---
---@param a Quaternion | number
---@param b Quaternion | number
---@return Quaternion power The new quaternion.
---@protected
function __Quaternion.__pow(a, b) end

--- [SHARED AND MENU]
---
--- Normalized linear interpolation ( nlerp ) between two quaternions along the shortest path.
---
--- Faster than `slerp`, but the rotation speed is not constant over `frac`.
---
---@param self Quaternion The quaternion.
---@param quaternion Quaternion The target quaternion.
---@param frac number The interpolation factor, `0` keeps the quaternion, `1` sets it to the target.
---@return Quaternion quat The same quaternion, interpolated and normalized.
function __Quaternion.lerp(self, quaternion, frac) end

--- [SHARED AND MENU]
---
--- Returns a normalized linear interpolation ( nlerp ) between two quaternions along the shortest path.
---
---@param quaternion Quaternion The target quaternion.
---@param frac number The interpolation factor, `0` keeps the quaternion, `1` sets it to the target.
---@return Quaternion lerped_quat The new quaternion.
---@nodiscard
function __Quaternion:getLerped(quaternion, frac) end

--- [SHARED AND MENU]
---
--- Spherical linear interpolation ( slerp ) between two unit quaternions along the shortest path.
---
--- Rotates with a constant speed over `frac`, falls back to `lerp` for almost equal quaternions.
---
---@param self Quaternion The quaternion, must be normalized.
---@param quaternion Quaternion The target quaternion, must be normalized.
---@param frac number The interpolation factor, `0` keeps the quaternion, `1` sets it to the target.
---@return Quaternion quat The same quaternion, interpolated.
function __Quaternion.slerp(self, quaternion, frac) end

--- [SHARED AND MENU]
---
--- Returns a spherical linear interpolation ( slerp ) between two unit quaternions along the shortest path.
---
---@param quaternion Quaternion The target quaternion, must be normalized.
---@param frac number The interpolation factor, `0` keeps the quaternion, `1` sets it to the target.
---@return Quaternion slerped_quat The new quaternion.
---@nodiscard
function __Quaternion:getSlerped(quaternion, frac) end

--- [SHARED AND MENU]
---
--- Returns the rotation angle of the quaternion in degrees.
---
--- Works with non-unit quaternions.
---
---@param full? boolean If `true`, returns angle in range [0, 360], otherwise in range [-180, 180].
---@return number degrees The rotation angle.
---@nodiscard
function __Quaternion:getAngle(full) end

--- [SHARED AND MENU]
---
--- Returns the rotation axis of the quaternion.
---
--- Returns `( 0, 0, 1 )` if the quaternion has no rotation.
---
---@return Vector3 axis The new normalized vector.
---@nodiscard
function __Quaternion:getAxis() end

--- [SHARED AND MENU]
---
--- Returns the unpacked 3x3 rotation matrix ( row-major ) of the quaternion.
---
--- Allocation free alternative to `toVMatrix`, columns are the forward, left and up directions.
---
---@return number m11
---@return number m12
---@return number m13
---@return number m21
---@return number m22
---@return number m23
---@return number m31
---@return number m32
---@return number m33
---@nodiscard
function __Quaternion:unpackMatrix() end

--- [SHARED AND MENU]
---
--- Returns the forward direction ( rotated `+X` ) of the quaternion.
---
---@return Vector3 forward_dir The new normalized direction.
---@nodiscard
function __Quaternion:getForward() end

--- [SHARED AND MENU]
---
--- Returns the left direction ( rotated `+Y` ) of the quaternion.
---
---@return Vector3 left_dir The new normalized direction.
---@nodiscard
function __Quaternion:getLeft() end

--- [SHARED AND MENU]
---
--- Returns the right direction ( rotated `-Y` ) of the quaternion.
---
---@return Vector3 right_dir The new normalized direction.
---@nodiscard
function __Quaternion:getRight() end

--- [SHARED AND MENU]
---
--- Returns the up direction ( rotated `+Z` ) of the quaternion.
---
---@return Vector3 up_dir The new normalized direction.
---@nodiscard
function __Quaternion:getUp() end

--- [SHARED AND MENU]
---
--- Returns the unpacked Euler angles ( pitch, yaw, roll ) of the quaternion in degrees.
---
--- Same as `QuaternionAngles` in Source engine, allocation free alternative to `getAngles`.
---
--- At pitch `±90` ( gimbal lock ) roll is always `0` and the whole rotation goes into yaw.
---
---@param self Quaternion The quaternion.
---@return number pitch The pitch in degrees.
---@return number yaw The yaw in degrees.
---@return number roll The roll in degrees.
---@nodiscard
function __Quaternion.unpackAngles(self) end

--- [SHARED AND MENU]
---
--- Returns the rotation of the quaternion as an angle.
---
--- Same as `QuaternionAngles` in Source engine, values are in range [-180, 180].
---
---@param self Quaternion The quaternion.
---@return Angle3 ang3 The new angle.
---@nodiscard
function __Quaternion.getAngles(self) end

--- [SHARED AND MENU]
---
--- Returns the rotation of the quaternion as an angle.
---
--- Same as `QuaternionAngles` in Source engine, values are in range [-180, 180].
---
---@param self Quaternion The quaternion.
---@return Angle3 ang3 The new angle.
---@nodiscard
function __Quaternion.toAngle3(self) end

--- [SHARED AND MENU]
---
--- Returns the rotation of the quaternion as a matrix without translation.
---
--- Same as `QuaternionMatrix` in Source engine.
---
---@return VMatrix matrix The new rotation matrix.
---@nodiscard
function __Quaternion:toVMatrix() end

--- [SHARED AND MENU]
---
--- Creates a new identity quaternion `( 1, 0, 0, 0 )`, which means no rotation.
---
---@return Quaternion quat The new quaternion.
---@nodiscard
function Quaternion.identity() end

--- [SHARED AND MENU]
---
--- Creates a new quaternion from the given Euler angles in degrees.
---
--- Same as `AngleQuaternion` in Source engine.
---
---@param pitch number The pitch in degrees.
---@param yaw number The yaw in degrees.
---@param roll number The roll in degrees.
---@return Quaternion quat The new unit quaternion.
---@nodiscard
function Quaternion.fromAngles(pitch, yaw, roll) end

--- [SHARED AND MENU]
---
--- Creates a new quaternion from the given angle.
---
--- Same as `AngleQuaternion` in Source engine.
---
---@param angle Angle3 The angle.
---@return Quaternion quat The new unit quaternion.
---@nodiscard
function Quaternion.fromAngle3(angle) end

--- [SHARED AND MENU]
---
--- Creates a new quaternion from the rotation around the given axis ( right-hand rule ).
---
--- Same as `AxisAngleQuaternion` in Source engine, zero axis returns identity.
---
---@param axis Vector3 The rotation axis, does not have to be normalized.
---@param degrees number The rotation angle in degrees.
---@return Quaternion quat The new unit quaternion.
---@nodiscard
function Quaternion.fromAxisAngle(axis, degrees) end

--- [SHARED AND MENU]
---
--- Creates a new quaternion that rotates the `from` direction to the `to` direction along the shortest arc.
---
--- Vectors do not have to be normalized, opposite directions rotate 180 degrees around any perpendicular axis,
--- zero vectors return identity.
---
---@param from Vector3 The source direction.
---@param to Vector3 The target direction.
---@return Quaternion quat The new unit quaternion.
---@nodiscard
function Quaternion.fromVectors(from, to) end

--- [SHARED AND MENU]
---
--- Creates a new quaternion from the unpacked 3x3 rotation matrix ( row-major ).
---
--- Same as `MatrixQuaternion` in Source engine, scale of the matrix is removed first.
---
---@param a11 number
---@param a12 number
---@param a13 number
---@param a21 number
---@param a22 number
---@param a23 number
---@param a31 number
---@param a32 number
---@param a33 number
---@return Quaternion quat The new unit quaternion.
---@nodiscard
function Quaternion.fromMatrix(a11, a12, a13, a21, a22, a23, a31, a32, a33) end

--- [SHARED AND MENU]
---
--- Creates a new quaternion from the rotation part of the given matrix.
---
--- Same as `MatrixQuaternion` in Source engine, scale and translation of the matrix are ignored.
---
---@param matrix VMatrix The matrix.
---@return Quaternion quat The new unit quaternion.
---@nodiscard
function Quaternion.fromVMatrix(matrix) end
