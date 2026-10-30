---@class dreamwork.std
local std = dreamwork.std
local class = std.class

local ffi = std.ffi

local debug = std.debug
local debug_getmetatable = debug.getmetatable

local string = std.string
local string_format = string.format

local math = std.math
local math_abs = math.abs
local math_sqrt = math.sqrt
local math_atan2 = math.atan2
local math_deg, math_rad = math.deg, math.rad
local math_cos, math_sin = math.cos, math.sin
local math_angleNormalize = math.angleNormalize

local error = std.error
local isNumber = std.isNumber
local setmetatable = std.setmetatable

local Vector3Class = std.Vector3

--[[

    Angle3 structure ( Source engine `QAngle` ), all values are in degrees:

        pitch : number - rotation around the Y axis, positive pitch looks down
        yaw   : number - rotation around the Z axis, positive yaw turns left
        roll  : number - rotation around the X axis, positive roll tilts right

    Rotation order is yaw( Z ) * pitch( Y ) * roll( X ).

    When `std.ffi` is available, angles are `struct { double pitch, yaw, roll; }` cdata
    objects, otherwise they are plain tables with `pitch`, `yaw` and `roll` keys.

    NOTE: In FFI mode `Angle3` is used as the `ffi.metatype` metatable, LuaJIT
    forbids modifying it after angles start being used, so all methods must be
    defined in this file and must not be added to it from other files.

    Naming convention:

        `ang:name( ... )`    - modifies the angle in place and returns it.
        `ang:getName( ... )` - returns a new angle, the original stays unchanged.
        operators           - always return a new angle.

    TODO:

    https://wiki.facepunch.com/gmod/util.IsInWorld

    https://wiki.facepunch.com/gmod/util.IntersectRayWithOBB

    https://wiki.facepunch.com/gmod/util.IntersectRayWithPlane

    https://wiki.facepunch.com/gmod/util.IntersectRayWithSphere

    https://wiki.facepunch.com/gmod/util.IsBoxIntersectingSphere

    https://wiki.facepunch.com/gmod/util.IsOBBIntersectingOBB

    https://wiki.facepunch.com/gmod/util.IsPointInCone

    https://wiki.facepunch.com/gmod/util.IsRayIntersectingRay

    https://wiki.facepunch.com/gmod/util.IsSkyboxVisibleFromPoint

    https://wiki.facepunch.com/gmod/util.IsSphereIntersectingCone

    https://wiki.facepunch.com/gmod/util.IsSphereIntersectingSphere

]]

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
---@class dreamwork.std.Angle3 : dreamwork.std.Object
---@field __class dreamwork.std.Angle3Class
---@operator add( dreamwork.std.Angle3 | number ): dreamwork.std.Angle3
---@operator sub( dreamwork.std.Angle3 | number ): dreamwork.std.Angle3
---@operator mul( number ): dreamwork.std.Angle3
---@operator div( number ): dreamwork.std.Angle3
---@operator unm: dreamwork.std.Angle3
---@field pitch number Rotation around the Y axis in degrees, positive pitch looks down.
---@field yaw number Rotation around the Z axis in degrees, positive yaw turns left.
---@field roll number Rotation around the X axis in degrees, positive roll tilts right.
local Angle3 = class.base( "Angle3", false )

--- [SHARED AND MENU]
---
--- The class used to create new `Angle3` instances.
---
--- ```lua
--- local ang = std.Angle3( 0, 90, 0 ) -- looking left
--- local zero = std.Angle3()
--- ```
---
---@class dreamwork.std.Angle3Class : dreamwork.std.Angle3
---@field __base dreamwork.std.Angle3
---@field zero dreamwork.std.Angle3 The shared zero angle `( 0, 0, 0 )`, **must not be modified**.
---@overload fun( pitch: number?, yaw: number?, roll: number? ): dreamwork.std.Angle3
local Angle3Class = class.create( Angle3 )
std.Angle3 = Angle3Class

--- Creates a new angle without any checks, all arguments must be numbers.
---
---@type fun( pitch: number, yaw: number, roll: number ): dreamwork.std.Angle3
local Angle3_create

--- [SHARED AND MENU]
---
--- Returns `true` if the value is an `Angle3`.
---
--- In FFI mode only `Angle3` cdata objects are accepted.
---
---@type fun( value: any ): ( is_angle3: boolean )
local isAngle3

if ffi == nil then

    ---@param pitch number
    ---@param yaw number
    ---@param roll number
    ---@return dreamwork.std.Angle3
    function Angle3_create( pitch, yaw, roll )
        return setmetatable( { pitch = pitch, yaw = yaw, roll = roll }, Angle3 )
    end

    ---@param value any
    ---@return boolean is_angle3
    ---@nodiscard
    function isAngle3( value )
        return debug_getmetatable( value ) == Angle3
    end

else

    local ffi_istype = ffi.istype

    local Angle3_ctype = ffi.metatype( "struct { double pitch, yaw, roll; }", Angle3 )

    ---@param pitch number
    ---@param yaw number
    ---@param roll number
    ---@return dreamwork.std.Angle3
    function Angle3_create( pitch, yaw, roll )
        ---@diagnostic disable-next-line: return-type-mismatch
        return Angle3_ctype( pitch, yaw, roll )
    end

    ---@param value any
    ---@return boolean is_angle3
    ---@nodiscard
    function isAngle3( value )
        return ffi_istype( Angle3_ctype, value )
    end

end

std.isAngle3 = isAngle3

--- Creates a new angle, missing values default to `0`.
---
---@param pitch? number The pitch in degrees, defaults to `0`.
---@param yaw? number The yaw in degrees, defaults to `0`.
---@param roll? number The roll in degrees, defaults to `0`.
---@return dreamwork.std.Angle3 ang3 The new angle.
---@protected
function Angle3Class:__new( pitch, yaw, roll )
    return Angle3_create( pitch or 0, yaw or 0, roll or 0 )
end

--- Source `AngleMatrix`, returns the 3x3 rotation matrix ( row-major ) of the angle.
---@return number, number, number, number, number, number, number, number, number
local function angleMatrix( pitch, yaw, roll )
    local p, y, r = math_rad( pitch ), math_rad( yaw ), math_rad( roll )
    local sp, cp = math_sin( p ), math_cos( p )
    local sy, cy = math_sin( y ), math_cos( y )
    local sr, cr = math_sin( r ), math_cos( r )

    return cp * cy, sp * sr * cy - cr * sy, sp * cr * cy + sr * sy,
        cp * sy, sp * sr * sy + cr * cy, sp * cr * sy - sr * cy,
        -sp, sr * cp, cr * cp
end

--- Source `MatrixAngles`, returns pitch, yaw and roll of the 3x3 rotation matrix ( row-major ).
---@return number, number, number
local function matrixAngles( a11, a12, _, a21, a22, _, a31, a32, a33 )
    local xy_distance = math_sqrt( a11 * a11 + a21 * a21 )
    if xy_distance > 0.001 then
        return math_deg( math_atan2( -a31, xy_distance ) ), math_deg( math_atan2( a21, a11 ) ), math_deg( math_atan2( a32, a33 ) )
    end

    return math_deg( math_atan2( -a31, xy_distance ) ), math_deg( math_atan2( -a12, a22 ) ), 0
end

--- Debug representation, e.g. `Angle3: 0x01234567 [0.000000, 90.000000, 0.000000]`.
---
---@return string str The debug representation.
---@protected
function Angle3:__represent()
    return string_format( "Angle3: %p [%f, %f, %f]", self, self.pitch, self.yaw, self.roll )
end

--- String conversion in Garry's Mod `Angle` format, e.g. `0.000000 90.000000 0.000000`.
---
---@return string str The string representation.
---@protected
function Angle3:__tostring()
    return string_format( "%f %f %f", self.pitch, self.yaw, self.roll )
end

--- Exact component-wise comparison without normalization, comparing with a non-angle value returns `false`.
---
--- `( 0, 360, 0 )` and `( 0, 0, 0 )` are not equal, use `getNormalized` first if needed.
---
---@param other any The value to compare with.
---@return boolean is_equal `true` if both are angles with equal values.
---@protected
function Angle3:__eq( other )
    return isAngle3( other ) and self.pitch == other.pitch and self.yaw == other.yaw and self.roll == other.roll
end

---@param writer dreamwork.std.BinaryWriter
---@protected
function Angle3:__serialize( writer )
    writer:writeDouble( self.pitch )
    writer:writeDouble( self.yaw )
    writer:writeDouble( self.roll )
end

---@param reader dreamwork.std.BinaryReader
---@protected
function Angle3:__deserialize( reader )
    self.pitch = reader:readDouble( true )
    self.yaw = reader:readDouble( true )
    self.roll = reader:readDouble( true )
end

--- [SHARED AND MENU]
---
--- Returns the pitch, yaw and roll of the angle.
---
---@return number pitch The pitch in degrees.
---@return number yaw The yaw in degrees.
---@return number roll The roll in degrees.
---@nodiscard
function Angle3:unpack()
    return self.pitch, self.yaw, self.roll
end

--- [SHARED AND MENU]
---
--- Sets the pitch, yaw and roll of the angle.
---
---@param pitch number The pitch in degrees.
---@param yaw number The yaw in degrees.
---@param roll number The roll in degrees.
---@return dreamwork.std.Angle3 ang3 The same angle.
function Angle3:setUnpacked( pitch, yaw, roll )
    self.pitch, self.yaw, self.roll = pitch, yaw, roll
    return self
end

--- [SHARED AND MENU]
---
--- Copies the values of another angle into this angle.
---
---@param angle dreamwork.std.Angle3 The angle to copy from.
---@return dreamwork.std.Angle3 ang3 The same angle.
function Angle3:set( angle )
    self.pitch, self.yaw, self.roll = angle.pitch, angle.yaw, angle.roll
    return self
end

--- [SHARED AND MENU]
---
--- Creates a new independent copy of the angle.
---
---@param self dreamwork.std.Angle3 The angle.
---@return dreamwork.std.Angle3 copy The new angle.
---@nodiscard
local function Angle3_copy( self )
    return Angle3_create( self.pitch, self.yaw, self.roll )
end

Angle3.copy = Angle3_copy

--- [SHARED AND MENU]
---
--- Checks if all values of the angle are exactly zero.
---
---@return boolean is_zero `true` if the angle is zero, `false` otherwise.
---@nodiscard
function Angle3:isZero()
    return self.pitch == 0 and self.yaw == 0 and self.roll == 0
end

--- [SHARED AND MENU]
---
--- Sets all values of the angle to zero.
---
---@return dreamwork.std.Angle3 ang3 The same angle.
function Angle3:zero()
    self.pitch, self.yaw, self.roll = 0, 0, 0
    return self
end

--- [SHARED AND MENU]
---
--- Checks if the angle is equal to the given angle with the given tolerance.
---
--- Values are compared as is, without normalization, so `359` and `-1` are not near.
---
---@param angle dreamwork.std.Angle3 The angle to check against.
---@param tolerance number The maximum allowed difference per value in degrees.
---@return boolean is_near `true` if the angles are equal within the tolerance, otherwise `false`.
---@nodiscard
function Angle3:isNear( angle, tolerance )
    return math_abs( self.pitch - angle.pitch ) <= tolerance and
        math_abs( self.yaw - angle.yaw ) <= tolerance and
        math_abs( self.roll - angle.roll ) <= tolerance
end

--- [SHARED AND MENU]
---
--- Negates all values of the angle.
---
---@return dreamwork.std.Angle3 ang3 The same angle, negated.
function Angle3:negate()
    self.pitch, self.yaw, self.roll = -self.pitch, -self.yaw, -self.roll
    return self
end

--- `-ang3`
---
---@return dreamwork.std.Angle3 negated The new angle.
---@protected
function Angle3:__unm()
    return Angle3_create( -self.pitch, -self.yaw, -self.roll )
end

--- [SHARED AND MENU]
---
--- Adds another angle or a number ( to every value ) to the angle.
---
---@param value dreamwork.std.Angle3 | number The other angle or a number of degrees.
---@return dreamwork.std.Angle3 ang3 The same angle, with the sum.
function Angle3:add( value )
    if isNumber( value ) then
        ---@cast value number
        self.pitch, self.yaw, self.roll = self.pitch + value, self.yaw + value, self.roll + value
    else
        ---@cast value dreamwork.std.Angle3
        self.pitch, self.yaw, self.roll = self.pitch + value.pitch, self.yaw + value.yaw, self.roll + value.roll
    end

    return self
end

--- `ang3 + ang3`, `ang3 + number` and `number + ang3`.
---
---@param a dreamwork.std.Angle3 | number
---@param b dreamwork.std.Angle3 | number
---@return dreamwork.std.Angle3 sum The new angle.
---@protected
function Angle3.__add( a, b )
    if isNumber( a ) then
        ---@cast a number
        return Angle3_create( a + b.pitch, a + b.yaw, a + b.roll )
    elseif isNumber( b ) then
        ---@cast b number
        return Angle3_create( a.pitch + b, a.yaw + b, a.roll + b )
    end

    return Angle3_create( a.pitch + b.pitch, a.yaw + b.yaw, a.roll + b.roll )
end

--- [SHARED AND MENU]
---
--- Subtracts another angle or a number ( from every value ) from the angle.
---
---@param value dreamwork.std.Angle3 | number The other angle or a number of degrees.
---@return dreamwork.std.Angle3 ang3 The same angle, with the difference.
function Angle3:sub( value )
    if isNumber( value ) then
        ---@cast value number
        self.pitch, self.yaw, self.roll = self.pitch - value, self.yaw - value, self.roll - value
    else
        ---@cast value dreamwork.std.Angle3
        self.pitch, self.yaw, self.roll = self.pitch - value.pitch, self.yaw - value.yaw, self.roll - value.roll
    end

    return self
end

--- `ang3 - ang3`, `ang3 - number` and `number - ang3`.
---
---@param a dreamwork.std.Angle3 | number
---@param b dreamwork.std.Angle3 | number
---@return dreamwork.std.Angle3 difference The new angle.
---@protected
function Angle3.__sub( a, b )
    if isNumber( a ) then
        ---@cast a number
        return Angle3_create( a - b.pitch, a - b.yaw, a - b.roll )
    elseif isNumber( b ) then
        ---@cast b number
        return Angle3_create( a.pitch - b, a.yaw - b, a.roll - b )
    end

    return Angle3_create( a.pitch - b.pitch, a.yaw - b.yaw, a.roll - b.roll )
end

--- [SHARED AND MENU]
---
--- Multiplies all values of the angle by the number.
---
---@param self dreamwork.std.Angle3 The angle.
---@param scale number The scale factor.
---@return dreamwork.std.Angle3 ang3 The same angle, scaled.
local function Angle3_mul( self, scale )
    self.pitch, self.yaw, self.roll = self.pitch * scale, self.yaw * scale, self.roll * scale
    return self
end

Angle3.mul = Angle3_mul
Angle3.scale = Angle3_mul

--- `ang3 * number` and `number * ang3`, `ang3 * ang3` raises an error.
---
---@param a dreamwork.std.Angle3 | number
---@param b dreamwork.std.Angle3 | number
---@return dreamwork.std.Angle3 product The new angle.
---@protected
function Angle3.__mul( a, b )
    if isNumber( a ) then
        ---@cast a number
        ---@cast b dreamwork.std.Angle3
        return Angle3_create( a * b.pitch, a * b.yaw, a * b.roll )
    elseif isNumber( b ) then
        ---@cast a dreamwork.std.Angle3
        ---@cast b number
        return Angle3_create( a.pitch * b, a.yaw * b, a.roll * b )
    end

    -- without this check `a.pitch * b` would call `__mul( number, angle )` and nest angles silently
    error( "attempt to multiply two angles, only `ang3 * number` is supported", 2 )
end

--- [SHARED AND MENU]
---
--- Divides all values of the angle by the number.
---
--- Division by zero is not checked and results in `inf` / `nan` values.
---
---@param divisor number The divisor.
---@return dreamwork.std.Angle3 ang3 The same angle, divided.
function Angle3:div( divisor )
    self.pitch, self.yaw, self.roll = self.pitch / divisor, self.yaw / divisor, self.roll / divisor
    return self
end

--- `ang3 / number`, both `ang3 / ang3` and `number / ang3` raise an error.
---
---@param a dreamwork.std.Angle3 | number
---@param b dreamwork.std.Angle3 | number
---@return dreamwork.std.Angle3 quotient The new angle.
---@protected
function Angle3.__div( a, b )
    if isNumber( b ) then
        ---@cast a dreamwork.std.Angle3
        ---@cast b number
        return Angle3_create( a.pitch / b, a.yaw / b, a.roll / b )
    end

    error( "attempt to divide by an angle", 2 )
end

--- [SHARED AND MENU]
---
--- Linearly interpolates the angle ( component-wise, without normalization ).
---
--- Interpolating from `350` to `10` goes the long way through `180`,
--- normalize both angles or use `Quaternion:slerp` for the shortest rotation.
---
---@param self dreamwork.std.Angle3 The angle.
---@param target dreamwork.std.Angle3 | number The target angle or a number of degrees ( used for every value ).
---@param frac number The interpolation factor, `0` keeps the angle, `1` sets it to the target.
---@return dreamwork.std.Angle3 ang3 The same angle, interpolated.
local function Angle3_lerp( self, target, frac )
    local pitch, yaw, roll = self.pitch, self.yaw, self.roll

    if isNumber( target ) then
        ---@cast target number
        self.pitch, self.yaw, self.roll = pitch + (target - pitch) * frac, yaw + (target - yaw) * frac, roll + (target - roll) * frac
    else
        ---@cast target dreamwork.std.Angle3
        self.pitch, self.yaw, self.roll = pitch + (target.pitch - pitch) * frac, yaw + (target.yaw - yaw) * frac, roll + (target.roll - roll) * frac
    end

    return self
end

Angle3.lerp = Angle3_lerp

--- [SHARED AND MENU]
---
--- Returns a copy of the angle linearly interpolated to another angle or a number.
---
---@param target dreamwork.std.Angle3 | number The target angle or a number of degrees ( used for every value ).
---@param frac number The interpolation factor, `0` keeps the angle, `1` sets it to the target.
---@return dreamwork.std.Angle3 lerped_ang3 The new angle.
---@nodiscard
function Angle3:getLerped( target, frac )
    return Angle3_lerp( Angle3_copy( self ), target, frac )
end

--- [SHARED AND MENU]
---
--- Normalizes the angle, all values will be in range [-180, 180).
---
--- Same as `Angle:Normalize` in Garry's Mod.
---
---@param self dreamwork.std.Angle3 The angle.
---@return dreamwork.std.Angle3 ang3 The same angle, normalized.
local function Angle3_normalize( self )
    self.pitch = math_angleNormalize( self.pitch )
    self.yaw = math_angleNormalize( self.yaw )
    self.roll = math_angleNormalize( self.roll )
    return self
end

Angle3.normalize = Angle3_normalize

--- [SHARED AND MENU]
---
--- Returns a normalized copy of the angle, all values will be in range [-180, 180).
---
---@return dreamwork.std.Angle3 normalized_ang3 The new angle.
---@nodiscard
function Angle3:getNormalized()
    return Angle3_normalize( Angle3_copy( self ) )
end

--- [SHARED AND MENU]
---
--- Returns the forward, right and up directions of the angle at once.
---
--- Same as `AngleVectors` in Source engine, faster than calling `getForward`, `getRight` and `getUp` separately.
---
---@return dreamwork.std.Vector3 forward_dir The new normalized forward direction.
---@return dreamwork.std.Vector3 right_dir The new normalized right direction.
---@return dreamwork.std.Vector3 up_dir The new normalized up direction.
---@nodiscard
function Angle3:getVectors()
    local a11, a12, a13, a21, a22, a23, a31, a32, a33 = angleMatrix( self.pitch, self.yaw, self.roll )
    return Vector3Class( a11, a21, a31 ), Vector3Class( -a12, -a22, -a32 ), Vector3Class( a13, a23, a33 )
end

--- [SHARED AND MENU]
---
--- Returns the forward direction of the angle, roll does not affect it.
---
--- Same as `Angle:Forward` in Garry's Mod.
---
---@return dreamwork.std.Vector3 forward_dir The new normalized direction.
---@nodiscard
function Angle3:getForward()
    local p, y = math_rad( self.pitch ), math_rad( self.yaw )
    local cp = math_cos( p )
    return Vector3Class( cp * math_cos( y ), cp * math_sin( y ), -math_sin( p ) )
end

--- [SHARED AND MENU]
---
--- Returns the backward direction of the angle ( negated forward ).
---
---@return dreamwork.std.Vector3 backward_dir The new normalized direction.
---@nodiscard
function Angle3:getBackward()
    local p, y = math_rad( self.pitch ), math_rad( self.yaw )
    local cp = math_cos( p )
    return Vector3Class( -cp * math_cos( y ), -cp * math_sin( y ), math_sin( p ) )
end

--- [SHARED AND MENU]
---
--- Returns the right direction of the angle.
---
--- Same as `Angle:Right` in Garry's Mod.
---
---@return dreamwork.std.Vector3 right_dir The new normalized direction.
---@nodiscard
function Angle3:getRight()
    local _, a12, _, _, a22, _, _, a32 = angleMatrix( self.pitch, self.yaw, self.roll )
    return Vector3Class( -a12, -a22, -a32 )
end

--- [SHARED AND MENU]
---
--- Returns the left direction of the angle ( negated right ).
---
---@return dreamwork.std.Vector3 left_dir The new normalized direction.
---@nodiscard
function Angle3:getLeft()
    local _, a12, _, _, a22, _, _, a32 = angleMatrix( self.pitch, self.yaw, self.roll )
    return Vector3Class( a12, a22, a32 )
end

--- [SHARED AND MENU]
---
--- Returns the up direction of the angle.
---
--- Same as `Angle:Up` in Garry's Mod.
---
---@return dreamwork.std.Vector3 up_dir The new normalized direction.
---@nodiscard
function Angle3:getUp()
    local _, _, a13, _, _, a23, _, _, a33 = angleMatrix( self.pitch, self.yaw, self.roll )
    return Vector3Class( a13, a23, a33 )
end

--- [SHARED AND MENU]
---
--- Returns the down direction of the angle ( negated up ).
---
---@return dreamwork.std.Vector3 down_dir The new normalized direction.
---@nodiscard
function Angle3:getDown()
    local _, _, a13, _, _, a23, _, _, a33 = angleMatrix( self.pitch, self.yaw, self.roll )
    return Vector3Class( -a13, -a23, -a33 )
end

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
---@param self dreamwork.std.Angle3 The angle.
---@param axis dreamwork.std.Vector3 The world axis to rotate around, must be normalized.
---@param degrees number The degrees to rotate around the axis.
---@return dreamwork.std.Angle3 ang3 The same angle, rotated.
local function Angle3_rotate( self, axis, degrees )
    local x, y, z = axis.x, axis.y, axis.z

    -- Source `MatrixBuildRotationAboutAxis`
    local radians = math_rad( degrees )
    local s, c = math_sin( radians ), math_cos( radians )
    local t = 1 - c

    local r11, r12, r13 = x * x * t + c, x * y * t - z * s, x * z * t + y * s
    local r21, r22, r23 = x * y * t + z * s, y * y * t + c, y * z * t - x * s
    local r31, r32, r33 = x * z * t - y * s, y * z * t + x * s, z * z * t + c

    local a11, a12, a13, a21, a22, a23, a31, a32, a33 = angleMatrix( self.pitch, self.yaw, self.roll )

    self.pitch, self.yaw, self.roll = matrixAngles(
        r11 * a11 + r12 * a21 + r13 * a31, r11 * a12 + r12 * a22 + r13 * a32, r11 * a13 + r12 * a23 + r13 * a33,
        r21 * a11 + r22 * a21 + r23 * a31, r21 * a12 + r22 * a22 + r23 * a32, r21 * a13 + r22 * a23 + r23 * a33,
        r31 * a11 + r32 * a21 + r33 * a31, r31 * a12 + r32 * a22 + r33 * a32, r31 * a13 + r32 * a23 + r33 * a33
    )

    return self
end

Angle3.rotate = Angle3_rotate

--- [SHARED AND MENU]
---
--- Returns a copy of the angle rotated around the specified world axis by the specified degrees.
---
--- See `Angle3:rotate` for the rotation direction.
---
---@param axis dreamwork.std.Vector3 The world axis to rotate around, must be normalized.
---@param degrees number The degrees to rotate around the axis.
---@return dreamwork.std.Angle3 rotated_ang3 The new angle.
---@nodiscard
function Angle3:getRotated( axis, degrees )
    return Angle3_rotate( Angle3_copy( self ), axis, degrees )
end

--- [SHARED AND MENU]
---
--- Returns the rotation of the angle as a quaternion.
---
--- Same as `AngleQuaternion` in Source engine.
---
---@return dreamwork.std.Quaternion quat The new unit quaternion.
---@nodiscard
function Angle3:toQuaternion()
    return std.Quaternion.fromAngle3( self )
end

--- [SHARED AND MENU]
---
--- Returns the rotation of the angle as a matrix without translation.
---
--- Same as `AngleMatrix` in Source engine.
---
---@return dreamwork.std.VMatrix matrix The new rotation matrix.
---@nodiscard
function Angle3:toVMatrix()
    return std.VMatrix.fromAngle3( self )
end

Angle3Class.zero = Angle3Class( 0, 0, 0 )
