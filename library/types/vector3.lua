---@meta _

--- [SHARED AND MENU]
---
--- A 3D vector object in Source engine coordinates.
---
--- Arithmetic operators work component-wise:
--- * `vec3 + vec3`, `vec3 + number`, `number + vec3` ( same for `-` and `*` )
--- * `vec3 / vec3`, `vec3 / number`
--- * `-vec3`
---
---@class Vector3 : Object
---@field __class Vector3Class
---@operator add( Vector3 | number ): Vector3
---@operator sub( Vector3 | number ): Vector3
---@operator mul( Vector3 | number ): Vector3
---@operator div( Vector3 | number ): Vector3
---@operator unm: Vector3
---@field x number The X coordinate ( forward ).
---@field y number The Y coordinate ( left ).
---@field z number The Z coordinate ( up ).
local __Vector3 = {}

--- [SHARED AND MENU]
---
--- The class used to create new `Vector3` instances.
---
--- ```lua
--- local vec = Vector3( 1, 2, 3 )
--- local zero = Vector3()
--- ```
---
---@class Vector3Class : Vector3
---@field __base Vector3
---@field origin Vector3 The shared zero vector `( 0, 0, 0 )`, **must not be modified**.
---@overload fun( x: number?, y: number?, z: number? ): Vector3
Vector3 = {}

---@param value any
---@return boolean is_vector3
---@nodiscard
function isVector3(value) end

--- Creates a new vector, missing coordinates default to `0`.
---
---@param x? number The X coordinate ( forward ), defaults to `0`.
---@param y? number The Y coordinate ( left ), defaults to `0`.
---@param z? number The Z coordinate ( up ), defaults to `0`.
---@return Vector3 vec3 The new vector.
---@protected
function Vector3:__new(x, y, z) end

--- Debug representation, e.g. `Vector3: 0x01234567 [1.000000, 2.000000, 3.000000]`.
---
---@return string str The debug representation.
---@protected
function __Vector3:__represent() end

--- String conversion in Garry's Mod `Vector` format, e.g. `1.000000 2.000000 3.000000`.
---
---@return string str The string representation.
---@protected
function __Vector3:__tostring() end

--- Exact component-wise comparison, comparing with a non-vector value returns `false`.
---
---@param other any The value to compare with.
---@return boolean is_equal `true` if both are vectors with equal coordinates.
---@protected
function __Vector3:__eq(other) end

---@param writer BinaryWriter
---@protected
function __Vector3:__serialize(writer) end

---@param reader BinaryReader
---@protected
function __Vector3:__deserialize(reader) end

--- [SHARED AND MENU]
---
--- Returns the x, y, and z coordinates of the vector.
---
---@return number x The x coordinate of the vector.
---@return number y The y coordinate of the vector.
---@return number z The z coordinate of the vector.
---@nodiscard
function __Vector3:unpack() end

--- [SHARED AND MENU]
---
--- Sets the x, y, and z coordinates of the vector.
---
---@param x number The x coordinate of the vector.
---@param y number The y coordinate of the vector.
---@param z number The z coordinate of the vector.
---@return Vector3 vec3 The same vector.
function __Vector3:setUnpacked(x, y, z) end

--- [SHARED AND MENU]
---
--- Copies the coordinates of another vector into this vector.
---
---@param vector Vector3 The vector to copy from.
---@return Vector3 vec3 The same vector.
function __Vector3:set(vector) end

--- [SHARED AND MENU]
---
--- Creates a new independent copy of the vector.
---
---@param self Vector3 The vector.
---@return Vector3 copy The new vector.
---@nodiscard
function __Vector3.copy(self) end

--- [SHARED AND MENU]
---
--- Checks if all coordinates of the vector are exactly zero.
---
---@return boolean is_zero `true` if the vector is zero, `false` otherwise.
---@nodiscard
function __Vector3:isZero() end

--- [SHARED AND MENU]
---
--- Sets all coordinates of the vector to zero.
---
---@return Vector3 vec3 The same vector.
function __Vector3:zero() end

--- [SHARED AND MENU]
---
--- Checks if the vector is equal to the given vector with the given tolerance.
---
--- Each coordinate is compared separately: `|a.x - b.x| <= tolerance` and so on.
---
---@param vector Vector3 The vector to check.
---@param tolerance number The maximum allowed difference per coordinate.
---@return boolean is_near `true` if the vectors are equal within the tolerance, otherwise `false`.
---@nodiscard
function __Vector3:isNear(vector, tolerance) end

--- [SHARED AND MENU]
---
--- Negates all coordinates of the vector.
---
---@return Vector3 vec3 The same vector, negated.
function __Vector3:negate() end

--- `-vec3`
---
---@return Vector3 negated The new vector.
---@protected
function __Vector3:__unm() end

--- [SHARED AND MENU]
---
--- Multiplies all coordinates of the vector by the number.
---
---@param self Vector3 The vector.
---@param scale number The scale factor.
---@return Vector3 vec3 The same vector, scaled.
function __Vector3.scale(self, scale) end

--- [SHARED AND MENU]
---
--- Returns a scaled copy of the vector.
---
---@param scale number The scale factor.
---@return Vector3 scaled_vec3 The scaled copy of the vector.
---@nodiscard
function __Vector3:getScaled(scale) end

--- [SHARED AND MENU]
---
--- Adds another vector or a number ( to every coordinate ) to the vector.
---
---@param value Vector3 | number The other vector or a number.
---@return Vector3 vec3 The same vector, with the sum.
function __Vector3:add(value) end

--- `vec3 + vec3`, `vec3 + number` and `number + vec3`.
---
---@param a Vector3 | number
---@param b Vector3 | number
---@return Vector3 sum The new vector.
---@protected
function __Vector3.__add(a, b) end

--- [SHARED AND MENU]
---
--- Subtracts another vector or a number ( from every coordinate ) from the vector.
---
---@param value Vector3 | number The other vector or a number.
---@return Vector3 vec3 The same vector, with the difference.
function __Vector3:sub(value) end

--- `vec3 - vec3`, `vec3 - number` and `number - vec3`.
---
---@param a Vector3 | number
---@param b Vector3 | number
---@return Vector3 difference The new vector.
---@protected
function __Vector3.__sub(a, b) end

--- [SHARED AND MENU]
---
--- Multiplies the vector by another vector ( component-wise ) or a number.
---
---@param value Vector3 | number The other vector or a number.
---@return Vector3 vec3 The same vector, with the product.
function __Vector3:mul(value) end

--- `vec3 * vec3` ( component-wise ), `vec3 * number` and `number * vec3`.
---
---@param a Vector3 | number
---@param b Vector3 | number
---@return Vector3 product The new vector.
---@protected
function __Vector3.__mul(a, b) end

--- [SHARED AND MENU]
---
--- Divides the vector by another vector ( component-wise ) or a number.
---
--- Modifies the vector in place, division by zero is not checked and results in `inf` / `nan` components.
---
---@param value Vector3 | number The divisor vector or number.
---@return Vector3 vec3 The same vector, divided.
function __Vector3:div(value) end

--- `vec3 / number`, `vec3 / vec3` and `number / vec3` ( component-wise ).
---
---@param a Vector3 | number
---@param b Vector3 | number
---@return Vector3 quotient The new vector.
---@protected
function __Vector3.__div(a, b) end

--- [SHARED AND MENU]
---
--- Calculates the dot product of two vectors.
---
---@param self Vector3 The vector.
---@param vector Vector3 The other vector.
---@return number dot_product The dot product of two vectors.
---@nodiscard
function __Vector3.dot(self, vector) end

--- [SHARED AND MENU]
---
--- Calculates the cross product of two vectors ( `self x vector` ).
---
--- The result is perpendicular to both vectors, e.g. `forward x left = up`.
---
---@param vector Vector3 The other vector.
---@return Vector3 cross_product The new vector.
---@nodiscard
function __Vector3:cross(vector) end

--- [SHARED AND MENU]
---
--- Calculates the squared length of the vector.
---
--- Faster than `getLength`, use it to compare lengths.
---
---@param self Vector3 The vector.
---@return number length The squared length of the vector.
---@nodiscard
function __Vector3.getLengthSqr(self) end

--- [SHARED AND MENU]
---
--- Calculates the length of the vector.
---
---@param self Vector3 The vector.
---@return number length The length of the vector.
---@nodiscard
function __Vector3.getLength(self) end

--- [SHARED AND MENU]
---
--- Calculates the squared length of the vector in the XY plane ( ignoring Z ).
---
---@return number length The squared 2D length of the vector.
---@nodiscard
function __Vector3:getLength2DSqr() end

--- [SHARED AND MENU]
---
--- Calculates the length of the vector in the XY plane ( ignoring Z ).
---
---@return number length The 2D length of the vector.
---@nodiscard
function __Vector3:getLength2D() end

--- [SHARED AND MENU]
---
--- Calculates the squared distance between two vectors.
---
--- Faster than `getDistance`, use it to compare distances.
---
---@param vector Vector3 The other vector.
---@return number distance The squared distance between the two vectors.
---@nodiscard
function __Vector3:getDistanceSqr(vector) end

--- [SHARED AND MENU]
---
--- Calculates the distance between two vectors.
---
---@param vector Vector3 The other vector.
---@return number distance The distance between the two vectors.
---@nodiscard
function __Vector3:getDistance(vector) end

--- [SHARED AND MENU]
---
--- Calculates the squared distance between two vectors in the XY plane ( ignoring Z ).
---
---@param vector Vector3 The other vector.
---@return number distance The squared 2D distance between the two vectors.
---@nodiscard
function __Vector3:getDistance2DSqr(vector) end

--- [SHARED AND MENU]
---
--- Calculates the distance between two vectors in the XY plane ( ignoring Z ).
---
---@param vector Vector3 The other vector.
---@return number distance The 2D distance between the two vectors.
---@nodiscard
function __Vector3:getDistance2D(vector) end

--- [SHARED AND MENU]
---
--- Scales the vector to the length of `1`.
---
--- Zero vector stays unchanged.
---
---@param self Vector3 The vector.
---@return Vector3 vec3 The same vector, normalized.
function __Vector3.normalize(self) end

--- [SHARED AND MENU]
---
--- Returns a copy of the vector with the length of `1`.
---
--- Zero vector returns a zero copy.
---
---@return Vector3 normalized_vec3 The new vector.
---@nodiscard
function __Vector3:getNormalized() end

--- [SHARED AND MENU]
---
--- Calculates the angle between two vectors in degrees.
---
--- Vectors do not have to be normalized, the result is in range [0, 180].
---
--- Not to be confused with `toAngle3`, which returns the direction of the vector as an angle.
---
---@param vector Vector3 The other vector.
---@return number degrees The angle between two vectors.
---@nodiscard
function __Vector3:getAngle(vector) end

--- [SHARED AND MENU]
---
--- Projects the vector onto the direction of another vector.
---
--- `vector` does not have to be normalized, projecting onto a zero vector results in a zero vector.
---
---@param self Vector3 The vector.
---@param vector Vector3 The direction to project onto.
---@return Vector3 vec3 The same vector, projected.
function __Vector3.project(self, vector) end

--- [SHARED AND MENU]
---
--- Returns a copy of the vector projected onto another vector.
---
---@param vector Vector3 The direction to project onto.
---@return Vector3 projected_vec3 The new vector.
---@nodiscard
function __Vector3:getProjected(vector) end

--- [SHARED AND MENU]
---
--- Reflects the vector from the plane with the given normal ( `v - 2 * dot( v, n ) * n` ).
---
--- Useful for bouncing velocities from surfaces, e.g. with a trace hit normal.
---
---@param self Vector3 The vector.
---@param normal Vector3 The plane normal, must be normalized.
---@return Vector3 vec3 The same vector, reflected.
function __Vector3.reflect(self, normal) end

--- [SHARED AND MENU]
---
--- Returns a copy of the vector reflected from the plane with the given normal.
---
---@param normal Vector3 The plane normal, must be normalized.
---@return Vector3 reflected_vec3 The new vector.
---@nodiscard
function __Vector3:getReflected(normal) end

--- [SHARED AND MENU]
---
--- Checks if the vector is within an axis-aligned box, borders included.
---
--- The corners of the box do not have to be ordered.
---
--- Same as `Vector:WithinAABox` in Garry's Mod.
---
---@param box_start Vector3 The first corner of the box.
---@param box_end Vector3 The second corner of the box.
---@return boolean in_box `true` if the vector is within the box, `false` otherwise.
---@nodiscard
function __Vector3:withinAABox(box_start, box_end) end

--- [SHARED AND MENU]
---
--- Rotates the vector by the given angle.
---
--- Same as `VectorRotate` in Source engine and `Vector:Rotate` in Garry's Mod.
---
---@param self Vector3 The vector to rotate.
---@param angle Angle3 The angle to rotate by.
---@return Vector3 vec3 The same vector, rotated.
function __Vector3.rotate(self, angle) end

--- [SHARED AND MENU]
---
--- Returns a copy of the vector rotated by the given angle.
---
---@param angle Angle3 The angle to rotate by.
---@return Vector3 rotated_vec3 The new vector.
---@nodiscard
function __Vector3:getRotated(angle) end

--- [SHARED AND MENU]
---
--- Linear interpolation between the vector and another vector or a number.
---
--- `frac` of `0` keeps the vector, `1` sets it to the target, values outside [0, 1] extrapolate.
---
---@param self Vector3 The vector.
---@param target Vector3 | number The target vector or a number ( used for every coordinate ).
---@param frac number The interpolation factor.
---@return Vector3 vec3 The same vector, interpolated.
function __Vector3.lerp(self, target, frac) end

--- [SHARED AND MENU]
---
--- Linear interpolation between the vector and another vector or a number.
---
--- `frac` of `0` keeps the vector, `1` sets it to the target, values outside [0, 1] extrapolate.
---
---@param self Vector3 The vector.
---@param target Vector3 | number The target vector or a number ( used for every coordinate ).
---@param frac number The interpolation factor.
---@return Vector3 vec3 The same vector, interpolated.
function __Vector3.lerpToVector(self, target, frac) end

--- [SHARED AND MENU]
---
--- Linear interpolation between the vector and another vector or a number.
---
--- `frac` of `0` keeps the vector, `1` sets it to the target, values outside [0, 1] extrapolate.
---
---@param self Vector3 The vector.
---@param target Vector3 | number The target vector or a number ( used for every coordinate ).
---@param frac number The interpolation factor.
---@return Vector3 vec3 The same vector, interpolated.
function __Vector3.lerpToNumber(self, target, frac) end

--- [SHARED AND MENU]
---
--- Returns a copy of the vector linearly interpolated to another vector or a number.
---
---@param self Vector3 The vector.
---@param target Vector3 | number The target vector or a number ( used for every coordinate ).
---@param frac number The interpolation factor.
---@return Vector3 lerped_vec3 The new vector.
---@nodiscard
function __Vector3.getLerped(self, target, frac) end

--- [SHARED AND MENU]
---
--- Returns a copy of the vector linearly interpolated to another vector or a number.
---
---@param self Vector3 The vector.
---@param target Vector3 | number The target vector or a number ( used for every coordinate ).
---@param frac number The interpolation factor.
---@return Vector3 lerped_vec3 The new vector.
---@nodiscard
function __Vector3.getLerpedToVector(self, target, frac) end

--- [SHARED AND MENU]
---
--- Returns a copy of the vector linearly interpolated to another vector or a number.
---
---@param self Vector3 The vector.
---@param target Vector3 | number The target vector or a number ( used for every coordinate ).
---@param frac number The interpolation factor.
---@return Vector3 lerped_vec3 The new vector.
---@nodiscard
function __Vector3.getLerpedToNumber(self, target, frac) end

--- [SHARED AND MENU]
---
--- Returns the angle that points in the direction of the vector.
---
--- Same as `VectorAngles` in Source engine and `Vector:Angle` / `Vector:AngleEx` in Garry's Mod:
--- * without `up`, pitch and yaw are in range [0, 360) and roll is always 0,
---   e.g. `( 0, 0, 1 )` returns `( 270, 0, 0 )`.
--- * with `up`, roll is calculated from the given up direction and angles are in range [-180, 180].
---
--- The vector does not have to be normalized.
---
---@param up? Vector3 The up direction, used to calculate roll.
---@return Angle3 ang3 The new angle.
---@nodiscard
function __Vector3:toAngle3(up) end

--- [SHARED AND MENU]
---
--- Converts the world position to the screen position.
---
--- Like `Vector:ToScreen` in Garry's Mod, but the view is passed explicitly.
---
--- Positions behind the view are still projected ( mirrored ) with `visible` set to `false`,
--- a position exactly in the view plane returns the screen center.
---
---@param view_origin Vector3 The view origin.
---@param view_angle Angle3 The view angle.
---@param view_fov number The view fov in degrees ( 4:3 based, like `fov_desired` ).
---@param screen_width number The screen width in pixels.
---@param screen_height number The screen height in pixels.
---@return number x The x position on the screen, `0` is the left edge.
---@return number y The y position on the screen, `0` is the top edge.
---@return boolean visible `true` if the position is in front of the view, `false` otherwise.
---@nodiscard
function __Vector3:toScreen(view_origin, view_angle, view_fov, screen_width, screen_height) end

--- [SHARED AND MENU]
---
--- Returns the view direction from the screen position.
---
--- Same as `util.AimVector` and `gui.ScreenToVector` in Garry's Mod.
---
---@param view_angle Angle3 The view angle.
---@param view_fov number The view fov in degrees ( 4:3 based, like `fov_desired` ).
---@param x number The x position on the screen, `0` is the left edge.
---@param y number The y position on the screen, `0` is the top edge.
---@param screen_width number The screen width in pixels.
---@param screen_height number The screen height in pixels.
---@return Vector3 direction The new normalized direction vector.
---@nodiscard
function Vector3.fromScreen(view_angle, view_fov, x, y, screen_width, screen_height) end

--- [SHARED AND MENU]
---
--- Swaps coordinates of the given vectors in place, so every coordinate of `mins` is less than or equal to the same coordinate of `maxs`.
---
--- Same as `OrderVectors` in Garry's Mod, useful for building bounding boxes from two arbitrary corners.
---
---@param mins Vector3 The first corner, becomes the minimum corner.
---@param maxs Vector3 The second corner, becomes the maximum corner.
---@return Vector3 mins The same `mins` vector.
---@return Vector3 maxs The same `maxs` vector.
function Vector3.order(mins, maxs) end

--- [SHARED AND MENU]
---
--- Translates the world position and angle into the local coordinate system.
---
--- Same as `WorldToLocal` in Garry's Mod.
---
---@param position Vector3 The world position.
---@param angle Angle3 The world angle.
---@param world_position Vector3 The origin of the local coordinate system.
---@param world_angle Angle3 The angle of the local coordinate system.
---@return Vector3 vec3 The new local position vector.
---@return Angle3 ang3 The new local angle.
---@nodiscard
function Vector3.translateToLocal(position, angle, world_position, world_angle) end

--- [SHARED AND MENU]
---
--- Translates the local position and angle into the world coordinate system.
---
--- Same as `LocalToWorld` in Garry's Mod.
---
---@param local_position Vector3 The local position.
---@param local_angle Angle3 The local angle.
---@param world_position Vector3 The origin of the local coordinate system.
---@param world_angle Angle3 The angle of the local coordinate system.
---@return Vector3 vec3 The new world position vector.
---@return Angle3 ang3 The new world angle.
---@nodiscard
function Vector3.translateToWorld(local_position, local_angle, world_position, world_angle) end
