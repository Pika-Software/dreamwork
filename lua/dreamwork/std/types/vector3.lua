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
local math_tan = math.tan
local math_sqrt = math.sqrt
local math_atan2 = math.atan2
local math_deg, math_rad = math.deg, math.rad
local math_cos, math_sin = math.cos, math.sin
local math_min, math_max = math.min, math.max

local isNumber = std.isNumber
local setmetatable = std.setmetatable

--[[

    Source engine coordinate system ( right-handed, Z-up ):

        +X - forward
        +Y - left
        +Z - up

    Vector3 structure:

        x, y, z : number

    When `std.ffi` is available, vectors are `struct { double x, y, z; }` cdata
    objects, otherwise they are plain tables with `x`, `y` and `z` keys.

    NOTE: In FFI mode `Vector3` is used as the `ffi.metatype` metatable, LuaJIT
    forbids modifying it after vectors start being used, so all methods must be
    defined in this file and must not be added to it from other files.

    Naming convention:

        `vec:name( ... )`    - modifies the vector in place and returns it.
        `vec:getName( ... )` - returns a new vector, the original stays unchanged.
        operators           - always return a new vector.

    ref: https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/mathlib/mathlib_base.cpp

]]

--- [SHARED AND MENU]
---
--- A 3D vector object in Source engine coordinates.
---
--- Arithmetic operators work component-wise:
--- * `vec3 + vec3`, `vec3 + number`, `number + vec3` ( same for `-` and `*` )
--- * `vec3 / vec3`, `vec3 / number`
--- * `-vec3`
---
---@class dreamwork.std.Vector3 : dreamwork.std.Object
---@field __class dreamwork.std.Vector3Class
---@operator add( dreamwork.std.Vector3 | number ): dreamwork.std.Vector3
---@operator sub( dreamwork.std.Vector3 | number ): dreamwork.std.Vector3
---@operator mul( dreamwork.std.Vector3 | number ): dreamwork.std.Vector3
---@operator div( dreamwork.std.Vector3 | number ): dreamwork.std.Vector3
---@operator unm: dreamwork.std.Vector3
---@field x number The X coordinate ( forward ).
---@field y number The Y coordinate ( left ).
---@field z number The Z coordinate ( up ).
local Vector3 = class.base( "Vector3", false )

--- [SHARED AND MENU]
---
--- The class used to create new `Vector3` instances.
---
--- ```lua
--- local vec = std.Vector3( 1, 2, 3 )
--- local zero = std.Vector3()
--- ```
---
---@class dreamwork.std.Vector3Class : dreamwork.std.Vector3
---@field __base dreamwork.std.Vector3
---@field origin dreamwork.std.Vector3 The shared zero vector `( 0, 0, 0 )`, **must not be modified**.
---@overload fun( x: number?, y: number?, z: number? ): dreamwork.std.Vector3
local Vector3Class = class.create( Vector3 )
std.Vector3 = Vector3Class

--- Creates a new vector without any checks, all arguments must be numbers.
---
---@type fun( x: number, y: number, z: number ): dreamwork.std.Vector3
local Vector3_create

--- [SHARED AND MENU]
---
--- Returns `true` if the value is a `Vector3`.
---
--- In FFI mode only `Vector3` cdata objects are accepted.
---
---@type fun( value: any ): ( is_vector3: boolean )
local isVector3

if ffi == nil then

    ---@param x number
    ---@param y number
    ---@param z number
    ---@return dreamwork.std.Vector3
    function Vector3_create( x, y, z )
        return setmetatable( { x = x, y = y, z = z }, Vector3 )
    end

    ---@param value any
    ---@return boolean is_vector3
    ---@nodiscard
    function isVector3( value )
        return debug_getmetatable( value ) == Vector3
    end

else

    local ffi_istype = ffi.istype

    local Vector3_ctype = ffi.metatype( "struct { double x, y, z; }", Vector3 )

    ---@param x number
    ---@param y number
    ---@param z number
    ---@return dreamwork.std.Vector3
    function Vector3_create( x, y, z )
        ---@diagnostic disable-next-line: return-type-mismatch
        return Vector3_ctype( x, y, z )
    end

    ---@param value any
    ---@return boolean is_vector3
    ---@nodiscard
    function isVector3( value )
        return ffi_istype( Vector3_ctype, value )
    end

end

std.isVector3 = isVector3

--- Creates a new vector, missing coordinates default to `0`.
---
---@param x? number The X coordinate ( forward ), defaults to `0`.
---@param y? number The Y coordinate ( left ), defaults to `0`.
---@param z? number The Z coordinate ( up ), defaults to `0`.
---@return dreamwork.std.Vector3 vec3 The new vector.
---@protected
function Vector3Class:__new( x, y, z )
    return Vector3_create( x or 0, y or 0, z or 0 )
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

--- Debug representation, e.g. `Vector3: 0x01234567 [1.000000, 2.000000, 3.000000]`.
---
---@return string str The debug representation.
---@protected
function Vector3:__represent()
    return string_format( "Vector3: %p [%f, %f, %f]", self, self.x, self.y, self.z )
end

--- String conversion in Garry's Mod `Vector` format, e.g. `1.000000 2.000000 3.000000`.
---
---@return string str The string representation.
---@protected
function Vector3:__tostring()
    return string_format( "%f %f %f", self.x, self.y, self.z )
end

--- Exact component-wise comparison, comparing with a non-vector value returns `false`.
---
---@param other any The value to compare with.
---@return boolean is_equal `true` if both are vectors with equal coordinates.
---@protected
function Vector3:__eq( other )
    return isVector3( other ) and self.x == other.x and self.y == other.y and self.z == other.z
end

-- --- Writes the vector as three 32-bit floats ( precision is reduced to float ).
-- ---
-- ---@param writer dreamwork.std.BinaryWriter The writer.
-- ---@protected
-- function Vector3:__serialize( writer )
--     writer:writeFloat( self.x )
--     writer:writeFloat( self.y )
--     writer:writeFloat( self.z )
-- end

-- --- Reads the vector from three 32-bit floats.
-- ---
-- ---@param reader dreamwork.std.BinaryReader The reader.
-- ---@protected
-- function Vector3:__deserialize( reader )
--     self.x = reader:readFloat()
--     self.y = reader:readFloat()
--     self.z = reader:readFloat()
-- end

--- [SHARED AND MENU]
---
--- Returns the x, y, and z coordinates of the vector.
---
---@return number x The x coordinate of the vector.
---@return number y The y coordinate of the vector.
---@return number z The z coordinate of the vector.
---@nodiscard
function Vector3:unpack()
    return self.x, self.y, self.z
end

--- [SHARED AND MENU]
---
--- Sets the x, y, and z coordinates of the vector.
---
---@param x number The x coordinate of the vector.
---@param y number The y coordinate of the vector.
---@param z number The z coordinate of the vector.
---@return dreamwork.std.Vector3 vec3 The same vector.
function Vector3:setUnpacked( x, y, z )
    self.x, self.y, self.z = x, y, z
    return self
end

--- [SHARED AND MENU]
---
--- Copies the coordinates of another vector into this vector.
---
---@param vector dreamwork.std.Vector3 The vector to copy from.
---@return dreamwork.std.Vector3 vec3 The same vector.
function Vector3:set( vector )
    self.x, self.y, self.z = vector.x, vector.y, vector.z
    return self
end

--- [SHARED AND MENU]
---
--- Creates a new independent copy of the vector.
---
---@param self dreamwork.std.Vector3 The vector.
---@return dreamwork.std.Vector3 copy The new vector.
---@nodiscard
local function Vector3_copy( self )
    return Vector3_create( self.x, self.y, self.z )
end

Vector3.copy = Vector3_copy

--- [SHARED AND MENU]
---
--- Checks if all coordinates of the vector are exactly zero.
---
---@return boolean is_zero `true` if the vector is zero, `false` otherwise.
---@nodiscard
function Vector3:isZero()
    return self.x == 0 and self.y == 0 and self.z == 0
end

--- [SHARED AND MENU]
---
--- Sets all coordinates of the vector to zero.
---
---@return dreamwork.std.Vector3 vec3 The same vector.
function Vector3:zero()
    self.x, self.y, self.z = 0, 0, 0
    return self
end

--- [SHARED AND MENU]
---
--- Checks if the vector is equal to the given vector with the given tolerance.
---
--- Each coordinate is compared separately: `|a.x - b.x| <= tolerance` and so on.
---
---@param vector dreamwork.std.Vector3 The vector to check.
---@param tolerance number The maximum allowed difference per coordinate.
---@return boolean is_near `true` if the vectors are equal within the tolerance, otherwise `false`.
---@nodiscard
function Vector3:isNear( vector, tolerance )
    return math_abs( self.x - vector.x ) <= tolerance and
        math_abs( self.y - vector.y ) <= tolerance and
        math_abs( self.z - vector.z ) <= tolerance
end

--- [SHARED AND MENU]
---
--- Negates all coordinates of the vector.
---
---@return dreamwork.std.Vector3 vec3 The same vector, negated.
function Vector3:negate()
    self.x, self.y, self.z = -self.x, -self.y, -self.z
    return self
end

--- `-vec3`
---
---@return dreamwork.std.Vector3 negated The new vector.
---@protected
function Vector3:__unm()
    return Vector3_create( -self.x, -self.y, -self.z )
end

--- [SHARED AND MENU]
---
--- Multiplies all coordinates of the vector by the number.
---
---@param self dreamwork.std.Vector3 The vector.
---@param scale number The scale factor.
---@return dreamwork.std.Vector3 vec3 The same vector, scaled.
local function Vector3_scale( self, scale )
    self.x, self.y, self.z = self.x * scale, self.y * scale, self.z * scale
    return self
end

Vector3.scale = Vector3_scale

--- [SHARED AND MENU]
---
--- Returns a scaled copy of the vector.
---
---@param scale number The scale factor.
---@return dreamwork.std.Vector3 scaled_vec3 The scaled copy of the vector.
---@nodiscard
function Vector3:getScaled( scale )
    return Vector3_create( self.x * scale, self.y * scale, self.z * scale )
end

--- [SHARED AND MENU]
---
--- Adds another vector or a number ( to every coordinate ) to the vector.
---
---@param value dreamwork.std.Vector3 | number The other vector or a number.
---@return dreamwork.std.Vector3 vec3 The same vector, with the sum.
function Vector3:add( value )
    if isNumber( value ) then
        ---@cast value number
        self.x, self.y, self.z = self.x + value, self.y + value, self.z + value
    else
        ---@cast value dreamwork.std.Vector3
        self.x, self.y, self.z = self.x + value.x, self.y + value.y, self.z + value.z
    end

    return self
end

--- `vec3 + vec3`, `vec3 + number` and `number + vec3`.
---
---@param a dreamwork.std.Vector3 | number
---@param b dreamwork.std.Vector3 | number
---@return dreamwork.std.Vector3 sum The new vector.
---@protected
function Vector3.__add( a, b )
    if isNumber( a ) then
        ---@cast a number
        return Vector3_create( a + b.x, a + b.y, a + b.z )
    elseif isNumber( b ) then
        ---@cast b number
        return Vector3_create( a.x + b, a.y + b, a.z + b )
    else
        return Vector3_create( a.x + b.x, a.y + b.y, a.z + b.z )
    end
end

--- [SHARED AND MENU]
---
--- Subtracts another vector or a number ( from every coordinate ) from the vector.
---
---@param value dreamwork.std.Vector3 | number The other vector or a number.
---@return dreamwork.std.Vector3 vec3 The same vector, with the difference.
function Vector3:sub( value )
    if isNumber( value ) then
        ---@cast value number
        self.x, self.y, self.z = self.x - value, self.y - value, self.z - value
    else
        ---@cast value dreamwork.std.Vector3
        self.x, self.y, self.z = self.x - value.x, self.y - value.y, self.z - value.z
    end

    return self
end

--- `vec3 - vec3`, `vec3 - number` and `number - vec3`.
---
---@param a dreamwork.std.Vector3 | number
---@param b dreamwork.std.Vector3 | number
---@return dreamwork.std.Vector3 difference The new vector.
---@protected
function Vector3.__sub( a, b )
    if isNumber( a ) then
        ---@cast a number
        return Vector3_create( a - b.x, a - b.y, a - b.z )
    elseif isNumber( b ) then
        ---@cast b number
        return Vector3_create( a.x - b, a.y - b, a.z - b )
    end

    return Vector3_create( a.x - b.x, a.y - b.y, a.z - b.z )
end

--- [SHARED AND MENU]
---
--- Multiplies the vector by another vector ( component-wise ) or a number.
---
---@param value dreamwork.std.Vector3 | number The other vector or a number.
---@return dreamwork.std.Vector3 vec3 The same vector, with the product.
function Vector3:mul( value )
    if isNumber( value ) then
        ---@cast value number
        self.x, self.y, self.z = self.x * value, self.y * value, self.z * value
    else
        ---@cast value dreamwork.std.Vector3
        self.x, self.y, self.z = self.x * value.x, self.y * value.y, self.z * value.z
    end

    return self
end

--- `vec3 * vec3` ( component-wise ), `vec3 * number` and `number * vec3`.
---
---@param a dreamwork.std.Vector3 | number
---@param b dreamwork.std.Vector3 | number
---@return dreamwork.std.Vector3 product The new vector.
---@protected
function Vector3.__mul( a, b )
    if isNumber( a ) then
        ---@cast a number
        return Vector3_create( a * b.x, a * b.y, a * b.z )
    elseif isNumber( b ) then
        ---@cast b number
        return Vector3_create( a.x * b, a.y * b, a.z * b )
    else
        return Vector3_create( a.x * b.x, a.y * b.y, a.z * b.z )
    end
end

--- [SHARED AND MENU]
---
--- Divides the vector by another vector ( component-wise ) or a number.
---
--- Modifies the vector in place, division by zero is not checked and results in `inf` / `nan` components.
---
---@param value dreamwork.std.Vector3 | number The divisor vector or number.
---@return dreamwork.std.Vector3 vec3 The same vector, divided.
function Vector3:div( value )
    if isNumber( value ) then
        ---@cast value number
        self.x, self.y, self.z = self.x / value, self.y / value, self.z / value
    else
        ---@cast value dreamwork.std.Vector3
        self.x, self.y, self.z = self.x / value.x, self.y / value.y, self.z / value.z
    end

    return self
end

--- `vec3 / number`, `vec3 / vec3` and `number / vec3` ( component-wise ).
---
---@param a dreamwork.std.Vector3 | number
---@param b dreamwork.std.Vector3 | number
---@return dreamwork.std.Vector3 quotient The new vector.
---@protected
function Vector3.__div( a, b )
    if isNumber( a ) then
        ---@cast a number
        return Vector3_create( a / b.x, a / b.y, a / b.z )
    elseif isNumber( b ) then
        ---@cast b number
        return Vector3_create( a.x / b, a.y / b, a.z / b )
    end

    return Vector3_create( a.x / b.x, a.y / b.y, a.z / b.z )
end

--- [SHARED AND MENU]
---
--- Calculates the dot product of two vectors.
---
---@param self dreamwork.std.Vector3 The vector.
---@param vector dreamwork.std.Vector3 The other vector.
---@return number dot_product The dot product of two vectors.
---@nodiscard
local function Vector3_dot( self, vector )
    return self.x * vector.x + self.y * vector.y + self.z * vector.z
end

Vector3.dot = Vector3_dot

--- [SHARED AND MENU]
---
--- Calculates the cross product of two vectors ( `self x vector` ).
---
--- The result is perpendicular to both vectors, e.g. `forward x left = up`.
---
---@param vector dreamwork.std.Vector3 The other vector.
---@return dreamwork.std.Vector3 cross_product The new vector.
---@nodiscard
function Vector3:cross( vector )
    local x1, y1, z1 = self.x, self.y, self.z
    local x2, y2, z2 = vector.x, vector.y, vector.z
    return Vector3_create( y1 * z2 - z1 * y2, z1 * x2 - x1 * z2, x1 * y2 - y1 * x2 )
end

--- [SHARED AND MENU]
---
--- Calculates the squared length of the vector.
---
--- Faster than `getLength`, use it to compare lengths.
---
---@param self dreamwork.std.Vector3 The vector.
---@return number length The squared length of the vector.
---@nodiscard
local function Vector3_getLengthSqr( self )
    local x, y, z = self.x, self.y, self.z
    return x * x + y * y + z * z
end

Vector3.getLengthSqr = Vector3_getLengthSqr

--- [SHARED AND MENU]
---
--- Calculates the length of the vector.
---
---@param self dreamwork.std.Vector3 The vector.
---@return number length The length of the vector.
---@nodiscard
local function Vector3_getLength( self )
    return math_sqrt( Vector3_getLengthSqr( self ) )
end

Vector3.getLength = Vector3_getLength

--- [SHARED AND MENU]
---
--- Calculates the squared length of the vector in the XY plane ( ignoring Z ).
---
---@return number length The squared 2D length of the vector.
---@nodiscard
function Vector3:getLength2DSqr()
    local x, y = self.x, self.y
    return x * x + y * y
end

--- [SHARED AND MENU]
---
--- Calculates the length of the vector in the XY plane ( ignoring Z ).
---
---@return number length The 2D length of the vector.
---@nodiscard
function Vector3:getLength2D()
    local x, y = self.x, self.y
    return math_sqrt( x * x + y * y )
end

--- [SHARED AND MENU]
---
--- Calculates the squared distance between two vectors.
---
--- Faster than `getDistance`, use it to compare distances.
---
---@param vector dreamwork.std.Vector3 The other vector.
---@return number distance The squared distance between the two vectors.
---@nodiscard
function Vector3:getDistanceSqr( vector )
    local x, y, z = vector.x - self.x, vector.y - self.y, vector.z - self.z
    return x * x + y * y + z * z
end

--- [SHARED AND MENU]
---
--- Calculates the distance between two vectors.
---
---@param vector dreamwork.std.Vector3 The other vector.
---@return number distance The distance between the two vectors.
---@nodiscard
function Vector3:getDistance( vector )
    local x, y, z = vector.x - self.x, vector.y - self.y, vector.z - self.z
    return math_sqrt( x * x + y * y + z * z )
end

--- [SHARED AND MENU]
---
--- Calculates the squared distance between two vectors in the XY plane ( ignoring Z ).
---
---@param vector dreamwork.std.Vector3 The other vector.
---@return number distance The squared 2D distance between the two vectors.
---@nodiscard
function Vector3:getDistance2DSqr( vector )
    local x, y = vector.x - self.x, vector.y - self.y
    return x * x + y * y
end

--- [SHARED AND MENU]
---
--- Calculates the distance between two vectors in the XY plane ( ignoring Z ).
---
---@param vector dreamwork.std.Vector3 The other vector.
---@return number distance The 2D distance between the two vectors.
---@nodiscard
function Vector3:getDistance2D( vector )
    local x, y = vector.x - self.x, vector.y - self.y
    return math_sqrt( x * x + y * y )
end

--- [SHARED AND MENU]
---
--- Scales the vector to the length of `1`.
---
--- Zero vector stays unchanged.
---
---@param self dreamwork.std.Vector3 The vector.
---@return dreamwork.std.Vector3 vec3 The same vector, normalized.
local function Vector3_normalize( self )
    local length = Vector3_getLength( self )
    if length == 0 then
        return self
    else
        return Vector3_scale( self, 1 / length )
    end
end

Vector3.normalize = Vector3_normalize

--- [SHARED AND MENU]
---
--- Returns a copy of the vector with the length of `1`.
---
--- Zero vector returns a zero copy.
---
---@return dreamwork.std.Vector3 normalized_vec3 The new vector.
---@nodiscard
function Vector3:getNormalized()
    return Vector3_normalize( Vector3_copy( self ) )
end

--- [SHARED AND MENU]
---
--- Calculates the angle between two vectors in degrees.
---
--- Vectors do not have to be normalized, the result is in range [0, 180].
---
--- Not to be confused with `toAngle3`, which returns the direction of the vector as an angle.
---
---@param vector dreamwork.std.Vector3 The other vector.
---@return number degrees The angle between two vectors.
---@nodiscard
function Vector3:getAngle( vector )
    local x1, y1, z1 = self.x, self.y, self.z
    local x2, y2, z2 = vector.x, vector.y, vector.z

    local cx, cy, cz = y1 * z2 - z1 * y2, z1 * x2 - x1 * z2, x1 * y2 - y1 * x2
    return math_deg( math_atan2( math_sqrt( cx * cx + cy * cy + cz * cz ), x1 * x2 + y1 * y2 + z1 * z2 ) )
end

--- [SHARED AND MENU]
---
--- Projects the vector onto the direction of another vector.
---
--- `vector` does not have to be normalized, projecting onto a zero vector results in a zero vector.
---
---@param self dreamwork.std.Vector3 The vector.
---@param vector dreamwork.std.Vector3 The direction to project onto.
---@return dreamwork.std.Vector3 vec3 The same vector, projected.
local function Vector3_project( self, vector )
    local length_sqr = Vector3_getLengthSqr( vector )
    if length_sqr == 0 then
        return self:zero()
    end

    local scale = Vector3_dot( self, vector ) / length_sqr
    self.x, self.y, self.z = vector.x * scale, vector.y * scale, vector.z * scale
    return self
end

Vector3.project = Vector3_project

--- [SHARED AND MENU]
---
--- Returns a copy of the vector projected onto another vector.
---
---@param vector dreamwork.std.Vector3 The direction to project onto.
---@return dreamwork.std.Vector3 projected_vec3 The new vector.
---@nodiscard
function Vector3:getProjected( vector )
    return Vector3_project( Vector3_copy( self ), vector )
end

--- [SHARED AND MENU]
---
--- Reflects the vector from the plane with the given normal ( `v - 2 * dot( v, n ) * n` ).
---
--- Useful for bouncing velocities from surfaces, e.g. with a trace hit normal.
---
---@param self dreamwork.std.Vector3 The vector.
---@param normal dreamwork.std.Vector3 The plane normal, must be normalized.
---@return dreamwork.std.Vector3 vec3 The same vector, reflected.
local function Vector3_reflect( self, normal )
    local scale = 2 * Vector3_dot( self, normal )
    self.x, self.y, self.z = self.x - normal.x * scale, self.y - normal.y * scale, self.z - normal.z * scale
    return self
end

Vector3.reflect = Vector3_reflect

--- [SHARED AND MENU]
---
--- Returns a copy of the vector reflected from the plane with the given normal.
---
---@param normal dreamwork.std.Vector3 The plane normal, must be normalized.
---@return dreamwork.std.Vector3 reflected_vec3 The new vector.
---@nodiscard
function Vector3:getReflected( normal )
    return Vector3_reflect( Vector3_copy( self ), normal )
end

--- [SHARED AND MENU]
---
--- Checks if the vector is within an axis-aligned box, borders included.
---
--- The corners of the box do not have to be ordered.
---
--- Same as `Vector:WithinAABox` in Garry's Mod.
---
---@param box_start dreamwork.std.Vector3 The first corner of the box.
---@param box_end dreamwork.std.Vector3 The second corner of the box.
---@return boolean in_box `true` if the vector is within the box, `false` otherwise.
---@nodiscard
function Vector3:withinAABox( box_start, box_end )
    local x, y, z = self.x, self.y, self.z
    local x1, y1, z1 = box_start.x, box_start.y, box_start.z
    local x2, y2, z2 = box_end.x, box_end.y, box_end.z

    return x >= math_min( x1, x2 ) and x <= math_max( x1, x2 ) and
        y >= math_min( y1, y2 ) and y <= math_max( y1, y2 ) and
        z >= math_min( z1, z2 ) and z <= math_max( z1, z2 )
end

--- [SHARED AND MENU]
---
--- Rotates the vector by the given angle.
---
--- Same as `VectorRotate` in Source engine and `Vector:Rotate` in Garry's Mod.
---
---@param self dreamwork.std.Vector3 The vector to rotate.
---@param angle dreamwork.std.Angle3 The angle to rotate by.
---@return dreamwork.std.Vector3 vec3 The same vector, rotated.
local function Vector3_rotate( self, angle )
    local a11, a12, a13, a21, a22, a23, a31, a32, a33 = angleMatrix( angle.pitch, angle.yaw, angle.roll )
    local x, y, z = self.x, self.y, self.z

    self.x = a11 * x + a12 * y + a13 * z
    self.y = a21 * x + a22 * y + a23 * z
    self.z = a31 * x + a32 * y + a33 * z

    return self
end

Vector3.rotate = Vector3_rotate

--- [SHARED AND MENU]
---
--- Returns a copy of the vector rotated by the given angle.
---
---@param angle dreamwork.std.Angle3 The angle to rotate by.
---@return dreamwork.std.Vector3 rotated_vec3 The new vector.
---@nodiscard
function Vector3:getRotated( angle )
    return Vector3_rotate( Vector3_copy( self ), angle )
end

--- [SHARED AND MENU]
---
--- Linear interpolation between the vector and another vector or a number.
---
--- `frac` of `0` keeps the vector, `1` sets it to the target, values outside [0, 1] extrapolate.
---
---@param self dreamwork.std.Vector3 The vector.
---@param target dreamwork.std.Vector3 | number The target vector or a number ( used for every coordinate ).
---@param frac number The interpolation factor.
---@return dreamwork.std.Vector3 vec3 The same vector, interpolated.
local function Vector3_lerp( self, target, frac )
    local x, y, z = self.x, self.y, self.z

    if isNumber( target ) then
        ---@cast target number
        self.x, self.y, self.z = x + (target - x) * frac, y + (target - y) * frac, z + (target - z) * frac
    else
        ---@cast target dreamwork.std.Vector3
        self.x, self.y, self.z = x + (target.x - x) * frac, y + (target.y - y) * frac, z + (target.z - z) * frac
    end

    return self
end

Vector3.lerp = Vector3_lerp
Vector3.lerpToVector = Vector3_lerp
Vector3.lerpToNumber = Vector3_lerp

--- [SHARED AND MENU]
---
--- Returns a copy of the vector linearly interpolated to another vector or a number.
---
---@param self dreamwork.std.Vector3 The vector.
---@param target dreamwork.std.Vector3 | number The target vector or a number ( used for every coordinate ).
---@param frac number The interpolation factor.
---@return dreamwork.std.Vector3 lerped_vec3 The new vector.
---@nodiscard
local function Vector3_getLerped( self, target, frac )
    return Vector3_lerp( Vector3_copy( self ), target, frac )
end

Vector3.getLerped = Vector3_getLerped
Vector3.getLerpedToVector = Vector3_getLerped
Vector3.getLerpedToNumber = Vector3_getLerped

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
---@param up? dreamwork.std.Vector3 The up direction, used to calculate roll.
---@return dreamwork.std.Angle3 ang3 The new angle.
---@nodiscard
function Vector3:toAngle3( up )
    local x, y, z = self.x, self.y, self.z

    if up == nil then
        local pitch, yaw

        if x == 0 and y == 0 then
            yaw = 0

            if z > 0 then
                pitch = 270
            else
                pitch = 90
            end
        else
            yaw = math_deg( math_atan2( y, x ) )
            if yaw < 0 then
                yaw = yaw + 360
            end

            pitch = math_deg( math_atan2( -z, math_sqrt( x * x + y * y ) ) )
            if pitch < 0 then
                pitch = pitch + 360
            end
        end

        return std.Angle3( pitch, yaw, 0 )
    end

    -- left = up x forward
    local ux, uy, uz = up.x, up.y, up.z
    local lx, ly, lz = uy * z - uz * y, uz * x - ux * z, ux * y - uy * x

    local left_length = math_sqrt( lx * lx + ly * ly + lz * lz )
    if left_length ~= 0 then
        lx, ly, lz = lx / left_length, ly / left_length, lz / left_length
    end

    local xy_distance = math_sqrt( x * x + y * y )
    if xy_distance > 0.001 then
        return std.Angle3(
            math_deg( math_atan2( -z, xy_distance ) ),
            math_deg( math_atan2( y, x ) ),
            math_deg( math_atan2( lz, ly * x - lx * y ) )
        )
    else
        return std.Angle3(
            math_deg( math_atan2( -z, xy_distance ) ),
            math_deg( math_atan2( -lx, ly ) ),
            0
        )
    end
end

--- Source `ScaleFOVByWidthRatio`, returns tangent of the half of the horizontal fov.
---
--- Source fov is defined for 4:3 screens and gets widened for other aspect ratios.
---@param fov number
---@param screen_width number
---@param screen_height number
---@return number
local function getHalfFovTangent( fov, screen_width, screen_height )
    return math_tan( math_rad( fov ) * 0.5 ) * ((screen_width / screen_height) * 0.75)
end

--- [SHARED AND MENU]
---
--- Converts the world position to the screen position.
---
--- Like `Vector:ToScreen` in Garry's Mod, but the view is passed explicitly.
---
--- Positions behind the view are still projected ( mirrored ) with `visible` set to `false`,
--- a position exactly in the view plane returns the screen center.
---
---@param view_origin dreamwork.std.Vector3 The view origin.
---@param view_angle dreamwork.std.Angle3 The view angle.
---@param view_fov number The view fov in degrees ( 4:3 based, like `fov_desired` ).
---@param screen_width number The screen width in pixels.
---@param screen_height number The screen height in pixels.
---@return number x The x position on the screen, `0` is the left edge.
---@return number y The y position on the screen, `0` is the top edge.
---@return boolean visible `true` if the position is in front of the view, `false` otherwise.
---@nodiscard
function Vector3:toScreen( view_origin, view_angle, view_fov, screen_width, screen_height )
    local a11, a12, a13, a21, a22, a23, a31, a32, a33 = angleMatrix( view_angle.pitch, view_angle.yaw, view_angle.roll )
    local dx, dy, dz = self.x - view_origin.x, self.y - view_origin.y, self.z - view_origin.z

    local forward = dx * a11 + dy * a21 + dz * a31
    local left = dx * a12 + dy * a22 + dz * a32
    local up = dx * a13 + dy * a23 + dz * a33

    local center_x, center_y = screen_width * 0.5, screen_height * 0.5
    local distance = center_x / getHalfFovTangent( view_fov, screen_width, screen_height )

    if forward == 0 then
        return center_x, center_y, false
    end

    local scale = distance / forward
    return center_x - left * scale, center_y - up * scale, forward > 0
end

--- [SHARED AND MENU]
---
--- Returns the view direction from the screen position.
---
--- Same as `util.AimVector` and `gui.ScreenToVector` in Garry's Mod.
---
---@param view_angle dreamwork.std.Angle3 The view angle.
---@param view_fov number The view fov in degrees ( 4:3 based, like `fov_desired` ).
---@param x number The x position on the screen, `0` is the left edge.
---@param y number The y position on the screen, `0` is the top edge.
---@param screen_width number The screen width in pixels.
---@param screen_height number The screen height in pixels.
---@return dreamwork.std.Vector3 direction The new normalized direction vector.
---@nodiscard
function Vector3Class.fromScreen( view_angle, view_fov, x, y, screen_width, screen_height )
    local a11, a12, a13, a21, a22, a23, a31, a32, a33 = angleMatrix( view_angle.pitch, view_angle.yaw, view_angle.roll )

    local center_x, center_y = screen_width * 0.5, screen_height * 0.5
    local distance = center_x / getHalfFovTangent( view_fov, screen_width, screen_height )

    -- left = -right, so screen x goes against the left vector
    local left, up = center_x - x, center_y - y

    return Vector3_normalize( Vector3Class(
        a11 * distance + a12 * left + a13 * up,
        a21 * distance + a22 * left + a23 * up,
        a31 * distance + a32 * left + a33 * up
    ) )
end

--- [SHARED AND MENU]
---
--- Swaps coordinates of the given vectors in place, so every coordinate of `mins` is less than or equal to the same coordinate of `maxs`.
---
--- Same as `OrderVectors` in Garry's Mod, useful for building bounding boxes from two arbitrary corners.
---
---@param mins dreamwork.std.Vector3 The first corner, becomes the minimum corner.
---@param maxs dreamwork.std.Vector3 The second corner, becomes the maximum corner.
---@return dreamwork.std.Vector3 mins The same `mins` vector.
---@return dreamwork.std.Vector3 maxs The same `maxs` vector.
function Vector3Class.order( mins, maxs )
    local x1, y1, z1 = mins.x, mins.y, mins.z
    local x2, y2, z2 = maxs.x, maxs.y, maxs.z

    mins.x, mins.y, mins.z = math_min( x1, x2 ), math_min( y1, y2 ), math_min( z1, z2 )
    maxs.x, maxs.y, maxs.z = math_max( x1, x2 ), math_max( y1, y2 ), math_max( z1, z2 )

    return mins, maxs
end

--- [SHARED AND MENU]
---
--- Translates the world position and angle into the local coordinate system.
---
--- Same as `WorldToLocal` in Garry's Mod.
---
---@param position dreamwork.std.Vector3 The world position.
---@param angle dreamwork.std.Angle3 The world angle.
---@param world_position dreamwork.std.Vector3 The origin of the local coordinate system.
---@param world_angle dreamwork.std.Angle3 The angle of the local coordinate system.
---@return dreamwork.std.Vector3 vec3 The new local position vector.
---@return dreamwork.std.Angle3 ang3 The new local angle.
---@nodiscard
function Vector3Class.translateToLocal( position, angle, world_position, world_angle )
    local w11, w12, w13, w21, w22, w23, w31, w32, w33 = angleMatrix( world_angle.pitch, world_angle.yaw, world_angle.roll )
    local a11, a12, a13, a21, a22, a23, a31, a32, a33 = angleMatrix( angle.pitch, angle.yaw, angle.roll )

    local dx, dy, dz = position.x - world_position.x, position.y - world_position.y, position.z - world_position.z

    -- transpose( W ) * A
    return Vector3Class(
        w11 * dx + w21 * dy + w31 * dz,
        w12 * dx + w22 * dy + w32 * dz,
        w13 * dx + w23 * dy + w33 * dz
    ), std.Angle3( matrixAngles(
        w11 * a11 + w21 * a21 + w31 * a31, w11 * a12 + w21 * a22 + w31 * a32, w11 * a13 + w21 * a23 + w31 * a33,
        w12 * a11 + w22 * a21 + w32 * a31, w12 * a12 + w22 * a22 + w32 * a32, w12 * a13 + w22 * a23 + w32 * a33,
        w13 * a11 + w23 * a21 + w33 * a31, w13 * a12 + w23 * a22 + w33 * a32, w13 * a13 + w23 * a23 + w33 * a33
    ) )
end

--- [SHARED AND MENU]
---
--- Translates the local position and angle into the world coordinate system.
---
--- Same as `LocalToWorld` in Garry's Mod.
---
---@param local_position dreamwork.std.Vector3 The local position.
---@param local_angle dreamwork.std.Angle3 The local angle.
---@param world_position dreamwork.std.Vector3 The origin of the local coordinate system.
---@param world_angle dreamwork.std.Angle3 The angle of the local coordinate system.
---@return dreamwork.std.Vector3 vec3 The new world position vector.
---@return dreamwork.std.Angle3 ang3 The new world angle.
---@nodiscard
function Vector3Class.translateToWorld( local_position, local_angle, world_position, world_angle )
    local w11, w12, w13, w21, w22, w23, w31, w32, w33 = angleMatrix( world_angle.pitch, world_angle.yaw, world_angle.roll )
    local a11, a12, a13, a21, a22, a23, a31, a32, a33 = angleMatrix( local_angle.pitch, local_angle.yaw, local_angle.roll )

    local x, y, z = local_position.x, local_position.y, local_position.z

    -- W * A
    return Vector3Class(
        world_position.x + w11 * x + w12 * y + w13 * z,
        world_position.y + w21 * x + w22 * y + w23 * z,
        world_position.z + w31 * x + w32 * y + w33 * z
    ), std.Angle3( matrixAngles(
        w11 * a11 + w12 * a21 + w13 * a31, w11 * a12 + w12 * a22 + w13 * a32, w11 * a13 + w12 * a23 + w13 * a33,
        w21 * a11 + w22 * a21 + w23 * a31, w21 * a12 + w22 * a22 + w23 * a32, w21 * a13 + w22 * a23 + w23 * a33,
        w31 * a11 + w32 * a21 + w33 * a31, w31 * a12 + w32 * a22 + w33 * a32, w31 * a13 + w32 * a23 + w33 * a33
    ) )
end

Vector3Class.origin = Vector3Class( 0, 0, 0 )
