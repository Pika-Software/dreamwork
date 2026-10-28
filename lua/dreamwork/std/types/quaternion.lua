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
local math_exp, math_log = math.exp, math.log
local math_deg, math_rad = math.deg, math.rad
local math_cos, math_sin = math.cos, math.sin
local math_acos, math_atan2 = math.acos, math.atan2
local math_huge = math.huge

local isNumber = std.isNumber
local setmetatable = std.setmetatable

local isVector3 = std.isVector3
local Vector3Class = std.Vector3
local Angle3Class = std.Angle3

--[[

    Quaternion structure:

        w : number - real part ( r )
        x : number - imaginary part ( i )
        y : number - imaginary part ( j )
        z : number - imaginary part ( k )

    All angles are in degrees.

    Euler angles follow the Source engine convention ( same as `AngleQuaternion` ):
    q = yaw( Z ) * pitch( Y ) * roll( X )

    When `std.ffi` is available, quaternions are `struct { double w, x, y, z; }` cdata
    objects, otherwise they are plain tables with `w`, `x`, `y` and `z` keys.

    NOTE: In FFI mode `Quaternion` is used as the `ffi.metatype` metatable, LuaJIT
    forbids modifying it after quaternions start being used, so all methods must be
    defined in this file and must not be added to it from other files.

    Naming convention:

        `quat:name( ... )`    - modifies the quaternion in place and returns it.
        `quat:getName( ... )` - returns a new quaternion, the original stays unchanged.
        operators            - always return a new quaternion ( or vector for `quat * vec3` ).

    ref: https://github.com/thegrb93/StarfallEx/blob/master/lua/starfall/libs_sh/quaternion.lua
    ref: https://github.com/excessive/cpml/blob/master/modules/quat.lua

]]

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
---@class dreamwork.std.Quaternion : dreamwork.std.Object
---@field __class dreamwork.std.QuaternionClass
---@operator add( dreamwork.std.Quaternion | number ): dreamwork.std.Quaternion
---@operator sub( dreamwork.std.Quaternion | number ): dreamwork.std.Quaternion
---@operator mul( dreamwork.std.Vector3 ): dreamwork.std.Vector3
---@operator mul( dreamwork.std.Quaternion | number ): dreamwork.std.Quaternion
---@operator div( dreamwork.std.Quaternion | number ): dreamwork.std.Quaternion
---@operator pow( number ): dreamwork.std.Quaternion
---@operator unm: dreamwork.std.Quaternion
---@field w number The real part ( `r` ), `cos( angle / 2 )` for rotations.
---@field x number The first imaginary part ( `i` ), `axis.x * sin( angle / 2 )` for rotations.
---@field y number The second imaginary part ( `j` ), `axis.y * sin( angle / 2 )` for rotations.
---@field z number The third imaginary part ( `k` ), `axis.z * sin( angle / 2 )` for rotations.
local Quaternion = class.base( "Quaternion", false )

--- [SHARED AND MENU]
---
--- The class used to create new `Quaternion` instances.
---
--- ```lua
--- local quat = std.Quaternion( 1, 0, 0, 0 ) -- identity, same as `std.Quaternion.identity()`
--- local rotation = std.Quaternion.fromAngles( 0, 90, 0 )
--- ```
---
---@class dreamwork.std.QuaternionClass : dreamwork.std.Quaternion
---@field __base dreamwork.std.Quaternion
---@overload fun( r: number?, i: number?, j: number?, k: number? ): dreamwork.std.Quaternion
local QuaternionClass = class.create( Quaternion )
std.Quaternion = QuaternionClass

--- Creates a new quaternion without any checks, all arguments must be numbers.
---
---@type fun( w: number, x: number, y: number, z: number ): dreamwork.std.Quaternion
local Quaternion_create

--- [SHARED AND MENU]
---
--- Returns `true` if the value is a `Quaternion`.
---
--- In FFI mode only `Quaternion` cdata objects are accepted.
---
---@type fun( value: any ): ( is_quaternion: boolean )
local isQuaternion

if ffi == nil then

    ---@param w number
    ---@param x number
    ---@param y number
    ---@param z number
    ---@return dreamwork.std.Quaternion
    function Quaternion_create( w, x, y, z )
        return setmetatable( { w = w, x = x, y = y, z = z }, Quaternion )
    end

    ---@param value any
    ---@return boolean is_quaternion
    ---@nodiscard
    function isQuaternion( value )
        return debug_getmetatable( value ) == Quaternion
    end

else

    local ffi_istype = ffi.istype

    local Quaternion_ctype = ffi.metatype( "struct { double w, x, y, z; }", Quaternion )

    ---@param w number
    ---@param x number
    ---@param y number
    ---@param z number
    ---@return dreamwork.std.Quaternion
    function Quaternion_create( w, x, y, z )
        ---@diagnostic disable-next-line: return-type-mismatch
        return Quaternion_ctype( w, x, y, z )
    end

    ---@param value any
    ---@return boolean is_quaternion
    ---@nodiscard
    function isQuaternion( value )
        return ffi_istype( Quaternion_ctype, value )
    end

end

std.isQuaternion = isQuaternion

--- Creates a new quaternion, missing components default to `0`.
---
--- Note that `std.Quaternion()` is a zero quaternion, not identity.
---
---@param r? number The real component ( `w` ), defaults to `0`.
---@param i? number The first imaginary component ( `x` ), defaults to `0`.
---@param j? number The second imaginary component ( `y` ), defaults to `0`.
---@param k? number The third imaginary component ( `z` ), defaults to `0`.
---@return dreamwork.std.Quaternion quat The new quaternion.
---@protected
function QuaternionClass:__new( r, i, j, k )
    return Quaternion_create( r or 0, i or 0, j or 0, k or 0 )
end

--- Debug representation, e.g. `Quaternion: 0x01234567 [1.000000, 0.000000, 0.000000, 0.000000]`.
---
---@return string str The debug representation.
---@protected
function Quaternion:__represent()
    return string_format( "Quaternion: %p [%f, %f, %f, %f]", self, self.w, self.x, self.y, self.z )
end

--- String conversion in `w x y z` order, e.g. `1.000000 0.000000 0.000000 0.000000`.
---
---@return string str The string representation.
---@protected
function Quaternion:__tostring()
    return string_format( "%f %f %f %f", self.w, self.x, self.y, self.z )
end

--- Exact component-wise comparison, comparing with a non-quaternion value returns `false`.
---
--- `q` and `-q` are not equal even though they represent the same rotation.
---
---@param other any The value to compare with.
---@return boolean is_equal `true` if both are quaternions with equal components.
---@protected
function Quaternion:__eq( other )
    return isQuaternion( other ) and self.w == other.w and self.x == other.x and self.y == other.y and self.z == other.z
end

-- --- Writes the quaternion as four 32-bit floats in `w x y z` order ( precision is reduced to float ).
-- ---
-- ---@param writer dreamwork.std.BinaryWriter The writer.
-- ---@protected
-- function Quaternion:__serialize( writer )
--     writer:writeFloat( self.w )
--     writer:writeFloat( self.x )
--     writer:writeFloat( self.y )
--     writer:writeFloat( self.z )
-- end

-- --- Reads the quaternion from four 32-bit floats in `w x y z` order.
-- ---
-- ---@param reader dreamwork.std.BinaryReader The reader.
-- ---@protected
-- function Quaternion:__deserialize( reader )
--     self.w = reader:readFloat()
--     self.x = reader:readFloat()
--     self.y = reader:readFloat()
--     self.z = reader:readFloat()
-- end

--- [SHARED AND MENU]
---
--- Returns the w ( r ), x ( i ), y ( j ), and z ( k ) components of the quaternion.
---
---@return number w The real component.
---@return number x The first imaginary component.
---@return number y The second imaginary component.
---@return number z The third imaginary component.
---@nodiscard
function Quaternion:unpack()
    return self.w, self.x, self.y, self.z
end

--- [SHARED AND MENU]
---
--- Sets the w ( r ), x ( i ), y ( j ), and z ( k ) components of the quaternion.
---
---@param w number The real component.
---@param x number The first imaginary component.
---@param y number The second imaginary component.
---@param z number The third imaginary component.
---@return dreamwork.std.Quaternion quat The same quaternion.
function Quaternion:setUnpacked( w, x, y, z )
    self.w, self.x, self.y, self.z = w, x, y, z
    return self
end

--- [SHARED AND MENU]
---
--- Copies the components of another quaternion into this quaternion.
---
---@param quaternion dreamwork.std.Quaternion The quaternion to copy from.
---@return dreamwork.std.Quaternion quat The same quaternion.
function Quaternion:set( quaternion )
    self.w, self.x, self.y, self.z = quaternion.w, quaternion.x, quaternion.y, quaternion.z
    return self
end

--- [SHARED AND MENU]
---
--- Creates a new independent copy of the quaternion.
---
---@param self dreamwork.std.Quaternion The quaternion.
---@return dreamwork.std.Quaternion copy The new quaternion.
---@nodiscard
local function Quaternion_copy( self )
    return Quaternion_create( self.w, self.x, self.y, self.z )
end

Quaternion.copy = Quaternion_copy

--- [SHARED AND MENU]
---
--- Sets the quaternion to identity `( 1, 0, 0, 0 )`, which means no rotation.
---
---@return dreamwork.std.Quaternion quat The same quaternion.
function Quaternion:identity()
    self.w, self.x, self.y, self.z = 1, 0, 0, 0
    return self
end

--- [SHARED AND MENU]
---
--- Checks if the quaternion is exactly identity `( 1, 0, 0, 0 )`.
---
--- `( -1, 0, 0, 0 )` also means no rotation, but is not identity.
---
---@return boolean is_identity `true` if the quaternion is identity, `false` otherwise.
---@nodiscard
function Quaternion:isIdentity()
    return self.w == 1 and self.x == 0 and self.y == 0 and self.z == 0
end

--- [SHARED AND MENU]
---
--- Sets all components of the quaternion to zero.
---
--- A zero quaternion is not a valid rotation.
---
---@return dreamwork.std.Quaternion quat The same quaternion.
function Quaternion:zero()
    self.w, self.x, self.y, self.z = 0, 0, 0, 0
    return self
end

--- [SHARED AND MENU]
---
--- Checks if all components of the quaternion are exactly zero.
---
---@return boolean is_zero `true` if the quaternion is zero, `false` otherwise.
---@nodiscard
function Quaternion:isZero()
    return self.w == 0 and self.x == 0 and self.y == 0 and self.z == 0
end

--- [SHARED AND MENU]
---
--- Checks if the quaternion is real ( all imaginary components are zero ).
---
---@return boolean is_real `true` if the quaternion is real, `false` otherwise.
---@nodiscard
function Quaternion:isReal()
    return self.x == 0 and self.y == 0 and self.z == 0
end

--- [SHARED AND MENU]
---
--- Checks if the quaternion is pure imaginary ( real component is zero ).
---
--- Unit pure imaginary quaternions are 180 degree rotations.
---
---@return boolean is_imaginary `true` if the quaternion is pure imaginary, `false` otherwise.
---@nodiscard
function Quaternion:isImaginary()
    return self.w == 0
end

--- [SHARED AND MENU]
---
--- Checks if the quaternion is equal to the given quaternion with the given tolerance.
---
--- Each component is compared separately, `q` and `-q` are not near, compare `getAngle` of `a / b` to check rotations.
---
---@param quaternion dreamwork.std.Quaternion The quaternion to check.
---@param tolerance number The maximum allowed difference per component.
---@return boolean is_near `true` if the quaternions are equal within the tolerance, otherwise `false`.
---@nodiscard
function Quaternion:isNear( quaternion, tolerance )
    return math_abs( self.w - quaternion.w ) <= tolerance and
        math_abs( self.x - quaternion.x ) <= tolerance and
        math_abs( self.y - quaternion.y ) <= tolerance and
        math_abs( self.z - quaternion.z ) <= tolerance
end

--- [SHARED AND MENU]
---
--- Calculates the dot product of two quaternions.
---
--- For unit quaternions it is `cos( angle / 2 )` of the rotation between them, negative means they are more than 180 degrees apart.
---
---@param self dreamwork.std.Quaternion The quaternion.
---@param quaternion dreamwork.std.Quaternion The other quaternion.
---@return number dot_product The dot product of two quaternions.
---@nodiscard
local function Quaternion_dot( self, quaternion )
    return self.w * quaternion.w + self.x * quaternion.x + self.y * quaternion.y + self.z * quaternion.z
end

Quaternion.dot = Quaternion_dot

--- [SHARED AND MENU]
---
--- Calculates the squared length ( norm ) of the quaternion.
---
--- Faster than `getLength`, `1` for unit quaternions.
---
---@param self dreamwork.std.Quaternion The quaternion.
---@return number length The squared length of the quaternion.
---@nodiscard
local function Quaternion_getLengthSqr( self )
    local w, x, y, z = self.w, self.x, self.y, self.z
    return w * w + x * x + y * y + z * z
end

Quaternion.getLengthSqr = Quaternion_getLengthSqr

--- [SHARED AND MENU]
---
--- Calculates the length ( norm ) of the quaternion.
---
---@param self dreamwork.std.Quaternion The quaternion.
---@return number length The length of the quaternion.
---@nodiscard
local function Quaternion_getLength( self )
    return math_sqrt( Quaternion_getLengthSqr( self ) )
end

Quaternion.getLength = Quaternion_getLength

--- [SHARED AND MENU]
---
--- Multiplies all components of the quaternion by the number.
---
--- Scaling does not change the rotation, but makes the quaternion non-unit.
---
---@param self dreamwork.std.Quaternion The quaternion.
---@param scale number The scale factor.
---@return dreamwork.std.Quaternion quat The same quaternion, scaled.
local function Quaternion_scale( self, scale )
    self.w, self.x, self.y, self.z = self.w * scale, self.x * scale, self.y * scale, self.z * scale
    return self
end

Quaternion.scale = Quaternion_scale

--- [SHARED AND MENU]
---
--- Returns a scaled copy of the quaternion.
---
---@param scale number The scale factor.
---@return dreamwork.std.Quaternion scaled_quat The new quaternion.
---@nodiscard
function Quaternion:getScaled( scale )
    return Quaternion_create( self.w * scale, self.x * scale, self.y * scale, self.z * scale )
end

--- [SHARED AND MENU]
---
--- Negates all components of the quaternion.
---
--- `q` and `-q` represent the same rotation.
---
---@return dreamwork.std.Quaternion quat The same quaternion, negated.
function Quaternion:negate()
    self.w, self.x, self.y, self.z = -self.w, -self.x, -self.y, -self.z
    return self
end

--- `-quat`
---
---@return dreamwork.std.Quaternion negated The new quaternion.
---@protected
function Quaternion:__unm()
    return Quaternion_create( -self.w, -self.x, -self.y, -self.z )
end

--- [SHARED AND MENU]
---
--- Scales the quaternion to the length of `1`.
---
--- Normalize after many multiplications to remove accumulated floating point errors.
---
--- Zero quaternion stays unchanged.
---
---@param self dreamwork.std.Quaternion The quaternion.
---@return dreamwork.std.Quaternion quat The same quaternion, normalized.
local function Quaternion_normalize( self )
    local length = Quaternion_getLength( self )
    if length == 0 then
        return self
    end

    return Quaternion_scale( self, 1 / length )
end

Quaternion.normalize = Quaternion_normalize

--- [SHARED AND MENU]
---
--- Returns a copy of the quaternion with the length of `1`.
---
--- Zero quaternion returns a zero copy.
---
---@return dreamwork.std.Quaternion normalized_quat The new quaternion.
---@nodiscard
function Quaternion:getNormalized()
    return Quaternion_normalize( Quaternion_copy( self ) )
end

--- [SHARED AND MENU]
---
--- Conjugates the quaternion ( negates the imaginary part ).
---
--- For unit quaternions the conjugate is the inverse rotation, faster than `invert`.
---
---@return dreamwork.std.Quaternion quat The same quaternion, conjugated.
function Quaternion:conjugate()
    self.x, self.y, self.z = -self.x, -self.y, -self.z
    return self
end

--- [SHARED AND MENU]
---
--- Returns the conjugate of the quaternion ( imaginary part negated ).
---
--- For unit quaternions the conjugate is the inverse rotation, faster than `getInverse`.
---
---@return dreamwork.std.Quaternion conjugated_quat The new quaternion.
---@nodiscard
function Quaternion:getConjugate()
    return Quaternion_create( self.w, -self.x, -self.y, -self.z )
end

--- [SHARED AND MENU]
---
--- Inverts the quaternion, so `q * q:getInverse()` is identity.
---
--- Works with non-unit quaternions, zero quaternion stays unchanged.
---
---@param self dreamwork.std.Quaternion The quaternion.
---@return dreamwork.std.Quaternion quat The same quaternion, inverted.
local function Quaternion_invert( self )
    local length_sqr = Quaternion_getLengthSqr( self )
    if length_sqr == 0 then
        return self
    end

    local inverse_length_sqr = 1 / length_sqr

    self.w = self.w * inverse_length_sqr
    self.x = -self.x * inverse_length_sqr
    self.y = -self.y * inverse_length_sqr
    self.z = -self.z * inverse_length_sqr

    return self
end

Quaternion.invert = Quaternion_invert

--- [SHARED AND MENU]
---
--- Returns the inverse of the quaternion, so `q * q:getInverse()` is identity.
---
---@return dreamwork.std.Quaternion inverted_quat The new quaternion.
---@nodiscard
function Quaternion:getInverse()
    return Quaternion_invert( Quaternion_copy( self ) )
end

--- [SHARED AND MENU]
---
--- Adds another quaternion ( component-wise ) or a real number ( to `w` only ) to the quaternion.
---
---@param self dreamwork.std.Quaternion The quaternion.
---@param value dreamwork.std.Quaternion | number The other quaternion or a real number.
---@return dreamwork.std.Quaternion quat The same quaternion, with the sum.
local function Quaternion_add( self, value )
    if isNumber( value ) then
        ---@cast value number
        self.w = self.w + value
    else
        ---@cast value dreamwork.std.Quaternion
        self.w, self.x, self.y, self.z = self.w + value.w, self.x + value.x, self.y + value.y, self.z + value.z
    end

    return self
end

Quaternion.add = Quaternion_add

--- `quat + quat`, `quat + number` and `number + quat`, numbers are added to the real part.
---
---@param a dreamwork.std.Quaternion | number
---@param b dreamwork.std.Quaternion | number
---@return dreamwork.std.Quaternion sum The new quaternion.
---@protected
function Quaternion.__add( a, b )
    if isNumber( a ) then
        ---@cast b dreamwork.std.Quaternion
        return Quaternion_add( Quaternion_copy( b ), a )
    end

    ---@cast a dreamwork.std.Quaternion
    return Quaternion_add( Quaternion_copy( a ), b )
end

--- [SHARED AND MENU]
---
--- Subtracts another quaternion ( component-wise ) or a real number ( from `w` only ) from the quaternion.
---
---@param self dreamwork.std.Quaternion The quaternion.
---@param value dreamwork.std.Quaternion | number The other quaternion or a real number.
---@return dreamwork.std.Quaternion quat The same quaternion, with the difference.
local function Quaternion_sub( self, value )
    if isNumber( value ) then
        ---@cast value number
        self.w = self.w - value
    else
        ---@cast value dreamwork.std.Quaternion
        self.w, self.x, self.y, self.z = self.w - value.w, self.x - value.x, self.y - value.y, self.z - value.z
    end

    return self
end

Quaternion.sub = Quaternion_sub

--- `quat - quat`, `quat - number` and `number - quat`, numbers are applied to the real part.
---
---@param a dreamwork.std.Quaternion | number
---@param b dreamwork.std.Quaternion | number
---@return dreamwork.std.Quaternion difference The new quaternion.
---@protected
function Quaternion.__sub( a, b )
    if isNumber( a ) then
        ---@cast a number
        ---@cast b dreamwork.std.Quaternion
        return Quaternion_create( a - b.w, -b.x, -b.y, -b.z )
    end

    ---@cast a dreamwork.std.Quaternion
    return Quaternion_sub( Quaternion_copy( a ), b )
end

--- Hamilton product of two unpacked quaternions.
---@return number, number, number, number
local function hamilton( w1, x1, y1, z1, w2, x2, y2, z2 )
    return w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2,
        w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2,
        w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2,
        w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2
end

--- [SHARED AND MENU]
---
--- Multiplies the quaternion by another quaternion ( Hamilton product, `self = self * value` ) or by a number.
---
--- For rotations `a * b` means "rotate by `b`, then by `a`", use `premul` for the opposite order.
---
---@param self dreamwork.std.Quaternion The quaternion.
---@param value dreamwork.std.Quaternion | number The other quaternion or a number.
---@return dreamwork.std.Quaternion quat The same quaternion, with the product.
local function Quaternion_mul( self, value )
    if isNumber( value ) then
        ---@cast value number
        return Quaternion_scale( self, value )
    end

    ---@cast value dreamwork.std.Quaternion
    self.w, self.x, self.y, self.z = hamilton( self.w, self.x, self.y, self.z, value.w, value.x, value.y, value.z )
    return self
end

Quaternion.mul = Quaternion_mul

--- [SHARED AND MENU]
---
--- Multiplies another quaternion by this quaternion ( `self = value * self` ).
---
--- For rotations it applies `value` after the current rotation.
---
---@param value dreamwork.std.Quaternion The other quaternion.
---@return dreamwork.std.Quaternion quat The same quaternion, with the product.
function Quaternion:premul( value )
    self.w, self.x, self.y, self.z = hamilton( value.w, value.x, value.y, value.z, self.w, self.x, self.y, self.z )
    return self
end

--- [SHARED AND MENU]
---
--- Divides the quaternion by another quaternion ( `self = self * value:getInverse()` ) or by a number.
---
--- For rotations `a / b` is the rotation that turns `b` into `a`.
---
--- Division by a zero number is not checked and results in `inf` / `nan` components.
---
---@param self dreamwork.std.Quaternion The quaternion.
---@param value dreamwork.std.Quaternion | number The divisor quaternion or number.
---@return dreamwork.std.Quaternion quat The same quaternion, divided.
local function Quaternion_div( self, value )
    if isNumber( value ) then
        ---@cast value number
        return Quaternion_scale( self, 1 / value )
    end

    ---@cast value dreamwork.std.Quaternion
    return Quaternion_mul( self, Quaternion_invert( Quaternion_copy( value ) ) )
end

Quaternion.div = Quaternion_div

--- Rotates unpacked vector by the quaternion, works with non-unit quaternions.
---@return number, number, number
local function rotate( w, i, j, k, x, y, z )
    local length_sqr = w * w + i * i + j * j + k * k
    if length_sqr == 0 then
        return x, y, z
    end

    -- uv = u x v
    local uvx = j * z - k * y
    local uvy = k * x - i * z
    local uvz = i * y - j * x

    -- uuv = u x uv
    local uuvx = j * uvz - k * uvy
    local uuvy = k * uvx - i * uvz
    local uuvz = i * uvy - j * uvx

    local scale = 2 / length_sqr

    return x + (uvx * w + uuvx) * scale,
        y + (uvy * w + uuvy) * scale,
        z + (uvz * w + uuvz) * scale
end

--- [SHARED AND MENU]
---
--- Returns a copy of the vector rotated by the quaternion, same as `quat * vec3`.
---
--- Works with non-unit quaternions, zero quaternion returns an unrotated copy.
---
---@param self dreamwork.std.Quaternion The quaternion.
---@param vector dreamwork.std.Vector3 The vector to rotate.
---@return dreamwork.std.Vector3 rotated_vec3 The new vector.
---@nodiscard
local function Quaternion_getRotatedVector3( self, vector )
    return Vector3Class( rotate( self.w, self.x, self.y, self.z, vector.x, vector.y, vector.z ) )
end

Quaternion.getRotatedVector3 = Quaternion_getRotatedVector3

--- [SHARED AND MENU]
---
--- Rotates the given vector by the quaternion in place.
---
--- Unlike other methods, this one modifies the **vector**, not the quaternion.
---
---@param vector dreamwork.std.Vector3 The vector to rotate.
---@return dreamwork.std.Vector3 vec3 The same vector, rotated.
function Quaternion:rotateVector3( vector )
    vector.x, vector.y, vector.z = rotate( self.w, self.x, self.y, self.z, vector.x, vector.y, vector.z )
    return vector
end

--- `quat * quat` ( Hamilton product ), `quat * vec3` ( rotates the vector ), `quat * number` and `number * quat`.
---
---@param a dreamwork.std.Quaternion | number
---@param b dreamwork.std.Quaternion | number | dreamwork.std.Vector3
---@return dreamwork.std.Quaternion | dreamwork.std.Vector3 product The new quaternion, or the new vector for `quat * vec3`.
---@protected
function Quaternion.__mul( a, b )
    if isNumber( a ) then
        ---@cast a number
        ---@cast b dreamwork.std.Quaternion
        return Quaternion_scale( Quaternion_copy( b ), a )
    elseif isVector3( b ) then
        ---@cast a dreamwork.std.Quaternion
        ---@cast b dreamwork.std.Vector3
        return Quaternion_getRotatedVector3( a, b )
    end

    ---@cast a dreamwork.std.Quaternion
    ---@cast b dreamwork.std.Quaternion | number
    return Quaternion_mul( Quaternion_copy( a ), b )
end

--- `quat / quat`, `number / quat` ( both are `a * b:getInverse()` ) and `quat / number`.
---
---@param a dreamwork.std.Quaternion | number
---@param b dreamwork.std.Quaternion | number
---@return dreamwork.std.Quaternion quotient The new quaternion.
---@protected
function Quaternion.__div( a, b )
    if isNumber( a ) then
        ---@cast a number
        ---@cast b dreamwork.std.Quaternion
        return Quaternion_scale( Quaternion_invert( Quaternion_copy( b ) ), a )
    end

    ---@cast a dreamwork.std.Quaternion
    return Quaternion_div( Quaternion_copy( a ), b )
end

--- [SHARED AND MENU]
---
--- Raises `e` to the power of the quaternion.
---
--- For a pure imaginary `( 0, axis * angle / 2 )` it returns the rotation quaternion of `angle` radians around `axis`.
---
---@param self dreamwork.std.Quaternion The quaternion.
---@return dreamwork.std.Quaternion quat The same quaternion, exponentiated.
local function Quaternion_exp( self )
    local x, y, z = self.x, self.y, self.z
    local imaginary_length = math_sqrt( x * x + y * y + z * z )
    local real_exp = math_exp( self.w )

    self.w = real_exp * math_cos( imaginary_length )

    if imaginary_length == 0 then
        self.x, self.y, self.z = 0, 0, 0
    else
        local scale = real_exp * math_sin( imaginary_length ) / imaginary_length
        self.x, self.y, self.z = x * scale, y * scale, z * scale
    end

    return self
end

Quaternion.exp = Quaternion_exp

--- [SHARED AND MENU]
---
--- Returns `e` raised to the power of the quaternion.
---
---@return dreamwork.std.Quaternion exp_quat The new quaternion.
---@nodiscard
function Quaternion:getExp()
    return Quaternion_exp( Quaternion_copy( self ) )
end

--- [SHARED AND MENU]
---
--- Calculates the natural logarithm of the quaternion, the inverse of `exp`.
---
--- For unit quaternions the result is pure imaginary `( 0, axis * angle / 2 )`,
--- zero quaternion results in `( -inf, 0, 0, 0 )`.
---
---@param self dreamwork.std.Quaternion The quaternion.
---@return dreamwork.std.Quaternion quat The same quaternion, logarithm.
local function Quaternion_log( self )
    local w, x, y, z = self.w, self.x, self.y, self.z

    local imaginary_length_sqr = x * x + y * y + z * z
    local length = math_sqrt( w * w + imaginary_length_sqr )

    if length == 0 then
        self.w, self.x, self.y, self.z = -math_huge, 0, 0, 0
        return self
    end

    self.w = math_log( length )

    if imaginary_length_sqr == 0 then
        self.x, self.y, self.z = 0, 0, 0
    else
        local imaginary_length = math_sqrt( imaginary_length_sqr )
        local scale = math_atan2( imaginary_length, w ) / imaginary_length
        self.x, self.y, self.z = x * scale, y * scale, z * scale
    end

    return self
end

Quaternion.log = Quaternion_log

--- [SHARED AND MENU]
---
--- Returns the natural logarithm of the quaternion.
---
---@return dreamwork.std.Quaternion log_quat The new quaternion.
---@nodiscard
function Quaternion:getLog()
    return Quaternion_log( Quaternion_copy( self ) )
end

--- [SHARED AND MENU]
---
--- Raises the quaternion to the given power, same as `quat ^ exponent`.
---
--- For unit quaternions this scales the rotation angle, e.g. `0.5` returns half of the rotation.
---
---@param self dreamwork.std.Quaternion The quaternion.
---@param exponent number The exponent.
---@return dreamwork.std.Quaternion quat The same quaternion, raised to the power.
local function Quaternion_pow( self, exponent )
    return Quaternion_exp( Quaternion_scale( Quaternion_log( self ), exponent ) )
end

Quaternion.pow = Quaternion_pow

--- [SHARED AND MENU]
---
--- Returns the quaternion raised to the given power.
---
---@param exponent number The exponent.
---@return dreamwork.std.Quaternion pow_quat The new quaternion.
---@nodiscard
function Quaternion:getPow( exponent )
    return Quaternion_pow( Quaternion_copy( self ), exponent )
end

--- `quat ^ number` ( power ) and `number ^ quat` ( exponent with the given base ).
---
---@param a dreamwork.std.Quaternion | number
---@param b dreamwork.std.Quaternion | number
---@return dreamwork.std.Quaternion power The new quaternion.
---@protected
function Quaternion.__pow( a, b )
    if isNumber( a ) then
        ---@cast a number
        ---@cast b dreamwork.std.Quaternion
        return Quaternion_exp( Quaternion_scale( Quaternion_copy( b ), math_log( a ) ) )
    end

    ---@cast a dreamwork.std.Quaternion
    ---@cast b number
    return Quaternion_pow( Quaternion_copy( a ), b )
end

--- [SHARED AND MENU]
---
--- Normalized linear interpolation ( nlerp ) between two quaternions along the shortest path.
---
--- Faster than `slerp`, but the rotation speed is not constant over `frac`.
---
---@param self dreamwork.std.Quaternion The quaternion.
---@param quaternion dreamwork.std.Quaternion The target quaternion.
---@param frac number The interpolation factor, `0` keeps the quaternion, `1` sets it to the target.
---@return dreamwork.std.Quaternion quat The same quaternion, interpolated and normalized.
local function Quaternion_lerp( self, quaternion, frac )
    local w2, x2, y2, z2 = quaternion.w, quaternion.x, quaternion.y, quaternion.z

    if Quaternion_dot( self, quaternion ) < 0 then
        w2, x2, y2, z2 = -w2, -x2, -y2, -z2
    end

    local w1, x1, y1, z1 = self.w, self.x, self.y, self.z

    self.w = w1 + (w2 - w1) * frac
    self.x = x1 + (x2 - x1) * frac
    self.y = y1 + (y2 - y1) * frac
    self.z = z1 + (z2 - z1) * frac

    return Quaternion_normalize( self )
end

Quaternion.lerp = Quaternion_lerp

--- [SHARED AND MENU]
---
--- Returns a normalized linear interpolation ( nlerp ) between two quaternions along the shortest path.
---
---@param quaternion dreamwork.std.Quaternion The target quaternion.
---@param frac number The interpolation factor, `0` keeps the quaternion, `1` sets it to the target.
---@return dreamwork.std.Quaternion lerped_quat The new quaternion.
---@nodiscard
function Quaternion:getLerped( quaternion, frac )
    return Quaternion_lerp( Quaternion_copy( self ), quaternion, frac )
end

--- [SHARED AND MENU]
---
--- Spherical linear interpolation ( slerp ) between two unit quaternions along the shortest path.
---
--- Rotates with a constant speed over `frac`, falls back to `lerp` for almost equal quaternions.
---
---@param self dreamwork.std.Quaternion The quaternion, must be normalized.
---@param quaternion dreamwork.std.Quaternion The target quaternion, must be normalized.
---@param frac number The interpolation factor, `0` keeps the quaternion, `1` sets it to the target.
---@return dreamwork.std.Quaternion quat The same quaternion, interpolated.
local function Quaternion_slerp( self, quaternion, frac )
    local w2, x2, y2, z2 = quaternion.w, quaternion.x, quaternion.y, quaternion.z

    local dot = Quaternion_dot( self, quaternion )
    if dot < 0 then
        w2, x2, y2, z2 = -w2, -x2, -y2, -z2
        dot = -dot
    end

    -- quaternions are almost equal, fallback to nlerp
    if dot > 0.9995 then
        return Quaternion_lerp( self, quaternion, frac )
    end

    local theta = math_acos( dot )
    local inverse_sin = 1 / math_sin( theta )

    local s1 = math_sin( (1 - frac) * theta ) * inverse_sin
    local s2 = math_sin( frac * theta ) * inverse_sin

    self.w = self.w * s1 + w2 * s2
    self.x = self.x * s1 + x2 * s2
    self.y = self.y * s1 + y2 * s2
    self.z = self.z * s1 + z2 * s2

    return self
end

Quaternion.slerp = Quaternion_slerp

--- [SHARED AND MENU]
---
--- Returns a spherical linear interpolation ( slerp ) between two unit quaternions along the shortest path.
---
---@param quaternion dreamwork.std.Quaternion The target quaternion, must be normalized.
---@param frac number The interpolation factor, `0` keeps the quaternion, `1` sets it to the target.
---@return dreamwork.std.Quaternion slerped_quat The new quaternion.
---@nodiscard
function Quaternion:getSlerped( quaternion, frac )
    return Quaternion_slerp( Quaternion_copy( self ), quaternion, frac )
end

--- [SHARED AND MENU]
---
--- Returns the rotation angle of the quaternion in degrees.
---
--- Works with non-unit quaternions.
---
---@param full? boolean If `true`, returns angle in range [0, 360], otherwise in range [-180, 180].
---@return number degrees The rotation angle.
---@nodiscard
function Quaternion:getAngle( full )
    local x, y, z = self.x, self.y, self.z

    local degrees = math_deg( 2 * math_atan2( math_sqrt( x * x + y * y + z * z ), self.w ) )
    if not full and degrees > 180 then
        degrees = degrees - 360
    end

    return degrees
end

--- [SHARED AND MENU]
---
--- Returns the rotation axis of the quaternion.
---
--- Returns `( 0, 0, 1 )` if the quaternion has no rotation.
---
---@return dreamwork.std.Vector3 axis The new normalized vector.
---@nodiscard
function Quaternion:getAxis()
    local x, y, z = self.x, self.y, self.z

    local length = math_sqrt( x * x + y * y + z * z )
    if length == 0 then
        return Vector3Class( 0, 0, 1 )
    end

    return Vector3Class( x / length, y / length, z / length )
end

--- Returns the unpacked 3x3 rotation matrix of the quaternion, works with non-unit quaternions.
---@return number, number, number, number, number, number, number, number, number
local function toMatrix( w, x, y, z )
    local length_sqr = w * w + x * x + y * y + z * z

    local s = 0
    if length_sqr ~= 0 then
        s = 2 / length_sqr
    end

    local xx, yy, zz = x * x * s, y * y * s, z * z * s
    local xy, xz, yz = x * y * s, x * z * s, y * z * s
    local wx, wy, wz = w * x * s, w * y * s, w * z * s

    return 1 - (yy + zz), xy - wz, xz + wy,
        xy + wz, 1 - (xx + zz), yz - wx,
        xz - wy, yz + wx, 1 - (xx + yy)
end

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
function Quaternion:unpackMatrix()
    return toMatrix( self.w, self.x, self.y, self.z )
end

--- [SHARED AND MENU]
---
--- Returns the forward direction ( rotated `+X` ) of the quaternion.
---
---@return dreamwork.std.Vector3 forward_dir The new normalized direction.
---@nodiscard
function Quaternion:getForward()
    local a11, _, _, a21, _, _, a31 = toMatrix( self.w, self.x, self.y, self.z )
    return Vector3Class( a11, a21, a31 )
end

--- [SHARED AND MENU]
---
--- Returns the left direction ( rotated `+Y` ) of the quaternion.
---
---@return dreamwork.std.Vector3 left_dir The new normalized direction.
---@nodiscard
function Quaternion:getLeft()
    local _, a12, _, _, a22, _, _, a32 = toMatrix( self.w, self.x, self.y, self.z )
    return Vector3Class( a12, a22, a32 )
end

--- [SHARED AND MENU]
---
--- Returns the right direction ( rotated `-Y` ) of the quaternion.
---
---@return dreamwork.std.Vector3 right_dir The new normalized direction.
---@nodiscard
function Quaternion:getRight()
    local _, a12, _, _, a22, _, _, a32 = toMatrix( self.w, self.x, self.y, self.z )
    return Vector3Class( -a12, -a22, -a32 )
end

--- [SHARED AND MENU]
---
--- Returns the up direction ( rotated `+Z` ) of the quaternion.
---
---@return dreamwork.std.Vector3 up_dir The new normalized direction.
---@nodiscard
function Quaternion:getUp()
    local _, _, a13, _, _, a23, _, _, a33 = toMatrix( self.w, self.x, self.y, self.z )
    return Vector3Class( a13, a23, a33 )
end

--- [SHARED AND MENU]
---
--- Returns the unpacked Euler angles ( pitch, yaw, roll ) of the quaternion in degrees.
---
--- Same as `QuaternionAngles` in Source engine, allocation free alternative to `getAngles`.
---
--- At pitch `±90` ( gimbal lock ) roll is always `0` and the whole rotation goes into yaw.
---
---@param self dreamwork.std.Quaternion The quaternion.
---@return number pitch The pitch in degrees.
---@return number yaw The yaw in degrees.
---@return number roll The roll in degrees.
---@nodiscard
local function Quaternion_unpackAngles( self )
    local a11, a12, _, a21, a22, _, a31, a32, a33 = toMatrix( self.w, self.x, self.y, self.z )

    local xy_distance = math_sqrt( a11 * a11 + a21 * a21 )

    if xy_distance > 0.001 then
        return math_deg( math_atan2( -a31, xy_distance ) ),
            math_deg( math_atan2( a21, a11 ) ),
            math_deg( math_atan2( a32, a33 ) )
    end

    -- gimbal lock
    return math_deg( math_atan2( -a31, xy_distance ) ),
        math_deg( math_atan2( -a12, a22 ) ),
        0
end

Quaternion.unpackAngles = Quaternion_unpackAngles

--- [SHARED AND MENU]
---
--- Returns the rotation of the quaternion as an angle.
---
--- Same as `QuaternionAngles` in Source engine, values are in range [-180, 180].
---
---@param self dreamwork.std.Quaternion The quaternion.
---@return dreamwork.std.Angle3 ang3 The new angle.
---@nodiscard
local function Quaternion_getAngles( self )
    return Angle3Class( Quaternion_unpackAngles( self ) )
end

Quaternion.getAngles = Quaternion_getAngles
Quaternion.toAngle3 = Quaternion_getAngles

--- [SHARED AND MENU]
---
--- Returns the rotation of the quaternion as a matrix without translation.
---
--- Same as `QuaternionMatrix` in Source engine.
---
---@return dreamwork.std.VMatrix matrix The new rotation matrix.
---@nodiscard
function Quaternion:toVMatrix()
    local a11, a12, a13, a21, a22, a23, a31, a32, a33 = toMatrix( self.w, self.x, self.y, self.z )

    return std.VMatrix(
        a11, a12, a13, 0,
        a21, a22, a23, 0,
        a31, a32, a33, 0,
        0, 0, 0, 1
    )
end

--- [SHARED AND MENU]
---
--- Creates a new identity quaternion `( 1, 0, 0, 0 )`, which means no rotation.
---
---@return dreamwork.std.Quaternion quat The new quaternion.
---@nodiscard
function QuaternionClass.identity()
    return Quaternion_create( 1, 0, 0, 0 )
end

--- [SHARED AND MENU]
---
--- Creates a new quaternion from the given Euler angles in degrees.
---
--- Same as `AngleQuaternion` in Source engine.
---
---@param pitch number The pitch in degrees.
---@param yaw number The yaw in degrees.
---@param roll number The roll in degrees.
---@return dreamwork.std.Quaternion quat The new unit quaternion.
---@nodiscard
local function QuaternionClass_fromAngles( pitch, yaw, roll )
    local p, y, r = math_rad( pitch ) * 0.5, math_rad( yaw ) * 0.5, math_rad( roll ) * 0.5

    local sp, cp = math_sin( p ), math_cos( p )
    local sy, cy = math_sin( y ), math_cos( y )
    local sr, cr = math_sin( r ), math_cos( r )

    return Quaternion_create(
        cy * cp * cr + sy * sp * sr,
        cy * cp * sr - sy * sp * cr,
        cy * sp * cr + sy * cp * sr,
        sy * cp * cr - cy * sp * sr
    )
end

QuaternionClass.fromAngles = QuaternionClass_fromAngles

--- [SHARED AND MENU]
---
--- Creates a new quaternion from the given angle.
---
--- Same as `AngleQuaternion` in Source engine.
---
---@param angle dreamwork.std.Angle3 The angle.
---@return dreamwork.std.Quaternion quat The new unit quaternion.
---@nodiscard
function QuaternionClass.fromAngle3( angle )
    return QuaternionClass_fromAngles( angle.pitch, angle.yaw, angle.roll )
end

--- [SHARED AND MENU]
---
--- Creates a new quaternion from the rotation around the given axis ( right-hand rule ).
---
--- Same as `AxisAngleQuaternion` in Source engine, zero axis returns identity.
---
---@param axis dreamwork.std.Vector3 The rotation axis, does not have to be normalized.
---@param degrees number The rotation angle in degrees.
---@return dreamwork.std.Quaternion quat The new unit quaternion.
---@nodiscard
function QuaternionClass.fromAxisAngle( axis, degrees )
    local x, y, z = axis.x, axis.y, axis.z

    local length = math_sqrt( x * x + y * y + z * z )
    if length == 0 then
        return Quaternion_create( 1, 0, 0, 0 )
    end

    local half_angle = math_rad( degrees ) * 0.5
    local scale = math_sin( half_angle ) / length

    return Quaternion_create( math_cos( half_angle ), x * scale, y * scale, z * scale )
end

--- [SHARED AND MENU]
---
--- Creates a new quaternion that rotates the `from` direction to the `to` direction along the shortest arc.
---
--- Vectors do not have to be normalized, opposite directions rotate 180 degrees around any perpendicular axis,
--- zero vectors return identity.
---
---@param from dreamwork.std.Vector3 The source direction.
---@param to dreamwork.std.Vector3 The target direction.
---@return dreamwork.std.Quaternion quat The new unit quaternion.
---@nodiscard
function QuaternionClass.fromVectors( from, to )
    local x1, y1, z1 = from.x, from.y, from.z
    local x2, y2, z2 = to.x, to.y, to.z

    local length = math_sqrt( (x1 * x1 + y1 * y1 + z1 * z1) * (x2 * x2 + y2 * y2 + z2 * z2) )
    if length == 0 then
        return Quaternion_create( 1, 0, 0, 0 )
    end

    local w = length + (x1 * x2 + y1 * y2 + z1 * z2)

    -- opposite directions, rotate 180 degrees around any orthogonal axis
    if w < 1e-6 * length then
        if math_abs( x1 ) > math_abs( z1 ) then
            return Quaternion_normalize( Quaternion_create( 0, -y1, x1, 0 ) )
        end

        return Quaternion_normalize( Quaternion_create( 0, 0, -z1, y1 ) )
    end

    return Quaternion_normalize( Quaternion_create( w, y1 * z2 - z1 * y2, z1 * x2 - x1 * z2, x1 * y2 - y1 * x2 ) )
end

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
---@return dreamwork.std.Quaternion quat The new unit quaternion.
---@nodiscard
local function QuaternionClass_fromMatrix( a11, a12, a13, a21, a22, a23, a31, a32, a33 )
    -- remove scale from the columns
    local sx = math_sqrt( a11 * a11 + a21 * a21 + a31 * a31 )
    if sx ~= 0 then a11, a21, a31 = a11 / sx, a21 / sx, a31 / sx end

    local sy = math_sqrt( a12 * a12 + a22 * a22 + a32 * a32 )
    if sy ~= 0 then a12, a22, a32 = a12 / sy, a22 / sy, a32 / sy end

    local sz = math_sqrt( a13 * a13 + a23 * a23 + a33 * a33 )
    if sz ~= 0 then a13, a23, a33 = a13 / sz, a23 / sz, a33 / sz end

    local trace = a11 + a22 + a33
    local w, x, y, z

    if trace > 0 then
        local s = 0.5 / math_sqrt( trace + 1 )
        w, x, y, z = 0.25 / s, (a32 - a23) * s, (a13 - a31) * s, (a21 - a12) * s
    elseif a11 > a22 and a11 > a33 then
        local s = 2 * math_sqrt( 1 + a11 - a22 - a33 )
        w, x, y, z = (a32 - a23) / s, 0.25 * s, (a12 + a21) / s, (a13 + a31) / s
    elseif a22 > a33 then
        local s = 2 * math_sqrt( 1 + a22 - a11 - a33 )
        w, x, y, z = (a13 - a31) / s, (a12 + a21) / s, 0.25 * s, (a23 + a32) / s
    else
        local s = 2 * math_sqrt( 1 + a33 - a11 - a22 )
        w, x, y, z = (a21 - a12) / s, (a13 + a31) / s, (a23 + a32) / s, 0.25 * s
    end

    return Quaternion_normalize( Quaternion_create( w, x, y, z ) )
end

QuaternionClass.fromMatrix = QuaternionClass_fromMatrix

--- [SHARED AND MENU]
---
--- Creates a new quaternion from the rotation part of the given matrix.
---
--- Same as `MatrixQuaternion` in Source engine, scale and translation of the matrix are ignored.
---
---@param matrix dreamwork.std.VMatrix The matrix.
---@return dreamwork.std.Quaternion quat The new unit quaternion.
---@nodiscard
function QuaternionClass.fromVMatrix( matrix )
    return QuaternionClass_fromMatrix(
        matrix.m11, matrix.m12, matrix.m13,
        matrix.m21, matrix.m22, matrix.m23,
        matrix.m31, matrix.m32, matrix.m33
    )
end
