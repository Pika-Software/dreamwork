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
local math_deg = math.deg
local math_rad = math.rad
local math_sqrt = math.sqrt
local math_atan2 = math.atan2
local math_cos, math_sin = math.cos, math.sin

local isNumber = std.isNumber
local setmetatable = std.setmetatable

--[[

    Vector2 structure:

        x, y : number

    When `std.ffi` is available, vectors are `struct { double x, y; }` cdata
    objects, otherwise they are plain tables with `x` and `y` keys.

    NOTE: In FFI mode `Vector2` is used as the `ffi.metatype` metatable, LuaJIT
    forbids modifying it after vectors start being used, so all methods must be
    defined in this file and must not be added to it from other files.

    Naming convention:

        `vec:name( ... )`    - modifies the vector in place and returns it.
        `vec:getName( ... )` - returns a new vector, the original stays unchanged.
        operators           - always return a new vector.

    ref: https://github.com/excessive/cpml/blob/master/modules/vec2.lua

]]

--- [SHARED AND MENU]
---
--- A 2D vector object, e.g. a screen position or a size.
---
--- Arithmetic operators work component-wise:
--- * `vec2 + vec2`, `vec2 + number`, `number + vec2` ( same for `-` and `*` )
--- * `vec2 / vec2`, `vec2 / number`
--- * `-vec2`
---
---@class dreamwork.std.Vector2 : dreamwork.std.Object
---@field __class dreamwork.std.Vector2Class
---@operator add( dreamwork.std.Vector2 | number ): dreamwork.std.Vector2
---@operator sub( dreamwork.std.Vector2 | number ): dreamwork.std.Vector2
---@operator mul( dreamwork.std.Vector2 | number ): dreamwork.std.Vector2
---@operator div( dreamwork.std.Vector2 | number ): dreamwork.std.Vector2
---@operator unm: dreamwork.std.Vector2
---@field x number The X coordinate.
---@field y number The Y coordinate.
local Vector2 = class.base( "Vector2", false )

--- [SHARED AND MENU]
---
--- The class used to create new `Vector2` instances.
---
--- ```lua
--- local vec = std.Vector2( 1, 2 )
--- local zero = std.Vector2()
--- ```
---
---@class dreamwork.std.Vector2Class : dreamwork.std.Vector2
---@field __base dreamwork.std.Vector2
---@field origin dreamwork.std.Vector2 The shared zero vector `( 0, 0 )`, **must not be modified**.
---@overload fun( x: number?, y: number? ): dreamwork.std.Vector2
local Vector2Class = class.create( Vector2 )
std.Vector2 = Vector2Class

--- Creates a new vector without any checks, all arguments must be numbers.
---
---@type fun( x: number, y: number ): dreamwork.std.Vector2
local Vector2_create

--- [SHARED AND MENU]
---
--- Returns `true` if the value is a `Vector2`.
---
--- In FFI mode only `Vector2` cdata objects are accepted.
---
---@type fun( value: any ): ( is_vector2: boolean )
local isVector2

if ffi == nil then

    ---@param x number
    ---@param y number
    ---@return dreamwork.std.Vector2
    function Vector2_create( x, y )
        return setmetatable( { x = x, y = y }, Vector2 )
    end

    ---@param value any
    ---@return boolean is_vector2
    function isVector2( value )
        return debug_getmetatable( value ) == Vector2
    end

else

    local ffi_istype = ffi.istype

    local Vector2_ctype = ffi.metatype( "struct { double x, y; }", Vector2 )

    ---@param x number
    ---@param y number
    ---@return dreamwork.std.Vector2
    function Vector2_create( x, y )
        ---@diagnostic disable-next-line: return-type-mismatch
        return Vector2_ctype( x, y )
    end

    ---@param value any
    ---@return boolean is_vector2
    function isVector2( value )
        return ffi_istype( Vector2_ctype, value )
    end

end

std.isVector2 = isVector2

--- Creates a new vector, missing coordinates default to `0`.
---
---@param x? number The X coordinate, defaults to `0`.
---@param y? number The Y coordinate, defaults to `0`.
---@return dreamwork.std.Vector2 vec2 The new vector.
---@protected
function Vector2Class:__new( x, y )
    return Vector2_create( x or 0, y or 0 )
end

--- Debug representation, e.g. `Vector2: 0x01234567 [1.000000, 2.000000]`.
---
---@return string str The debug representation.
---@protected
function Vector2:__represent()
    return string_format( "Vector2: %p [%f, %f]", self, self.x, self.y )
end

--- String conversion, e.g. `1.000000 2.000000`.
---
---@return string str The string representation.
---@protected
function Vector2:__tostring()
    return string_format( "%f %f", self.x, self.y )
end

--- Exact component-wise comparison, comparing with a non-vector value returns `false`.
---
---@param other any The value to compare with.
---@return boolean is_equal `true` if both are vectors with equal coordinates.
---@protected
function Vector2:__eq( other )
    return isVector2( other ) and self.x == other.x and self.y == other.y
end

--- Writes the vector as two 32-bit floats ( precision is reduced to float ).
---
---@param writer dreamwork.std.BinaryWriter The writer.
---@protected
function Vector2:__serialize( writer )
    writer:writeFloat( self.x )
    writer:writeFloat( self.y )
end

--- Reads the vector from two 32-bit floats.
---
---@param reader dreamwork.std.BinaryReader The reader.
---@protected
function Vector2:__deserialize( reader )
    self.x = reader:readFloat()
    self.y = reader:readFloat()
end

--- [SHARED AND MENU]
---
--- Returns the x and y coordinates of the vector.
---
---@return number x The x coordinate of the vector.
---@return number y The y coordinate of the vector.
function Vector2:unpack()
    return self.x, self.y
end

--- [SHARED AND MENU]
---
--- Sets the x and y coordinates of the vector.
---
---@param x number The x coordinate of the vector.
---@param y number The y coordinate of the vector.
---@return dreamwork.std.Vector2 vec2 The same vector.
function Vector2:setUnpacked( x, y )
    self.x, self.y = x, y
    return self
end

--- [SHARED AND MENU]
---
--- Copies the coordinates of another vector into this vector.
---
---@param vector dreamwork.std.Vector2 The vector to copy from.
---@return dreamwork.std.Vector2 vec2 The same vector.
function Vector2:set( vector )
    self.x, self.y = vector.x, vector.y
    return self
end

--- [SHARED AND MENU]
---
--- Creates a new independent copy of the vector.
---
---@param self dreamwork.std.Vector2 The vector.
---@return dreamwork.std.Vector2 copy The new vector.
local function Vector2_copy( self )
    return Vector2_create( self.x, self.y )
end

Vector2.copy = Vector2_copy

--- [SHARED AND MENU]
---
--- Checks if all coordinates of the vector are exactly zero.
---
---@return boolean is_zero `true` if the vector is zero, `false` otherwise.
function Vector2:isZero()
    return self.x == 0 and self.y == 0
end

--- [SHARED AND MENU]
---
--- Sets all coordinates of the vector to zero.
---
---@return dreamwork.std.Vector2 vec2 The same vector.
function Vector2:zero()
    self.x, self.y = 0, 0
    return self
end

--- [SHARED AND MENU]
---
--- Checks if the vector is equal to the given vector with the given tolerance.
---
--- Each coordinate is compared separately: `|a.x - b.x| <= tolerance` and so on.
---
---@param vector dreamwork.std.Vector2 The vector to check.
---@param tolerance number The maximum allowed difference per coordinate.
---@return boolean is_near `true` if the vectors are equal within the tolerance, otherwise `false`.
function Vector2:isNear( vector, tolerance )
    return math_abs( self.x - vector.x ) <= tolerance and math_abs( self.y - vector.y ) <= tolerance
end

--- [SHARED AND MENU]
---
--- Negates all coordinates of the vector.
---
---@return dreamwork.std.Vector2 vec2 The same vector, negated.
function Vector2:negate()
    self.x, self.y = -self.x, -self.y
    return self
end

--- `-vec2`
---
---@return dreamwork.std.Vector2 negated The new vector.
---@protected
function Vector2:__unm()
    return Vector2_create( -self.x, -self.y )
end

--- [SHARED AND MENU]
---
--- Multiplies all coordinates of the vector by the number.
---
---@param self dreamwork.std.Vector2 The vector.
---@param scale number The scale factor.
---@return dreamwork.std.Vector2 vec2 The same vector, scaled.
local function Vector2_scale( self, scale )
    self.x, self.y = self.x * scale, self.y * scale
    return self
end

Vector2.scale = Vector2_scale

--- [SHARED AND MENU]
---
--- Returns a scaled copy of the vector.
---
---@param scale number The scale factor.
---@return dreamwork.std.Vector2 scaled_vec2 The new vector.
function Vector2:getScaled( scale )
    return Vector2_create( self.x * scale, self.y * scale )
end

--- [SHARED AND MENU]
---
--- Adds another vector or a number ( to every coordinate ) to the vector.
---
---@param value dreamwork.std.Vector2 | number The other vector or a number.
---@return dreamwork.std.Vector2 vec2 The same vector, with the sum.
function Vector2:add( value )
    if isNumber( value ) then
        ---@cast value number
        self.x, self.y = self.x + value, self.y + value
    else
        ---@cast value dreamwork.std.Vector2
        self.x, self.y = self.x + value.x, self.y + value.y
    end

    return self
end

--- `vec2 + vec2`, `vec2 + number` and `number + vec2`.
---
---@param a dreamwork.std.Vector2 | number
---@param b dreamwork.std.Vector2 | number
---@return dreamwork.std.Vector2 sum The new vector.
---@protected
function Vector2.__add( a, b )
    if isNumber( a ) then
        ---@cast a number
        return Vector2_create( a + b.x, a + b.y )
    elseif isNumber( b ) then
        ---@cast b number
        return Vector2_create( a.x + b, a.y + b )
    end

    return Vector2_create( a.x + b.x, a.y + b.y )
end

--- [SHARED AND MENU]
---
--- Subtracts another vector or a number ( from every coordinate ) from the vector.
---
---@param value dreamwork.std.Vector2 | number The other vector or a number.
---@return dreamwork.std.Vector2 vec2 The same vector, with the difference.
function Vector2:sub( value )
    if isNumber( value ) then
        ---@cast value number
        self.x, self.y = self.x - value, self.y - value
    else
        ---@cast value dreamwork.std.Vector2
        self.x, self.y = self.x - value.x, self.y - value.y
    end

    return self
end

--- `vec2 - vec2`, `vec2 - number` and `number - vec2`.
---
---@param a dreamwork.std.Vector2 | number
---@param b dreamwork.std.Vector2 | number
---@return dreamwork.std.Vector2 difference The new vector.
---@protected
function Vector2.__sub( a, b )
    if isNumber( a ) then
        ---@cast a number
        return Vector2_create( a - b.x, a - b.y )
    elseif isNumber( b ) then
        ---@cast b number
        return Vector2_create( a.x - b, a.y - b )
    end

    return Vector2_create( a.x - b.x, a.y - b.y )
end

--- [SHARED AND MENU]
---
--- Multiplies the vector by another vector ( component-wise ) or a number.
---
---@param value dreamwork.std.Vector2 | number The other vector or a number.
---@return dreamwork.std.Vector2 vec2 The same vector, with the product.
function Vector2:mul( value )
    if isNumber( value ) then
        ---@cast value number
        self.x, self.y = self.x * value, self.y * value
    else
        ---@cast value dreamwork.std.Vector2
        self.x, self.y = self.x * value.x, self.y * value.y
    end

    return self
end

--- `vec2 * vec2` ( component-wise ), `vec2 * number` and `number * vec2`.
---
---@param a dreamwork.std.Vector2 | number
---@param b dreamwork.std.Vector2 | number
---@return dreamwork.std.Vector2 product The new vector.
---@protected
function Vector2.__mul( a, b )
    if isNumber( a ) then
        ---@cast a number
        return Vector2_create( a * b.x, a * b.y )
    elseif isNumber( b ) then
        ---@cast b number
        return Vector2_create( a.x * b, a.y * b )
    end

    return Vector2_create( a.x * b.x, a.y * b.y )
end

--- [SHARED AND MENU]
---
--- Divides the vector by another vector ( component-wise ) or a number.
---
--- Modifies the vector in place, division by zero is not checked and results in `inf` / `nan` components.
---
---@param value dreamwork.std.Vector2 | number The divisor vector or number.
---@return dreamwork.std.Vector2 vec2 The same vector, divided.
function Vector2:div( value )
    if isNumber( value ) then
        ---@cast value number
        self.x, self.y = self.x / value, self.y / value
    else
        ---@cast value dreamwork.std.Vector2
        self.x, self.y = self.x / value.x, self.y / value.y
    end

    return self
end

--- `vec2 / number` and `vec2 / vec2` ( component-wise ), `number / vec2` is not supported.
---
--- e.g. `position / screen_size` converts pixels into the [0, 1] range.
---
---@param value dreamwork.std.Vector2 | number The divisor vector or number.
---@return dreamwork.std.Vector2 quotient The new vector.
---@protected
function Vector2:__div( value )
    if isNumber( value ) then
        ---@cast value number
        return Vector2_create( self.x / value, self.y / value )
    end

    ---@cast value dreamwork.std.Vector2
    return Vector2_create( self.x / value.x, self.y / value.y )
end

--- [SHARED AND MENU]
---
--- Calculates the dot product of two vectors.
---
---@param vector dreamwork.std.Vector2 The other vector.
---@return number dot_product The dot product of two vectors.
function Vector2:dot( vector )
    return self.x * vector.x + self.y * vector.y
end

--- [SHARED AND MENU]
---
--- Calculates the 2D cross product ( Z component of the 3D cross product ) of two vectors.
---
--- Positive if `vector` is counter-clockwise from the vector, negative if clockwise, zero if parallel.
---
---@param vector dreamwork.std.Vector2 The other vector.
---@return number cross_product The cross product of two vectors.
function Vector2:cross( vector )
    return self.x * vector.y - self.y * vector.x
end

--- [SHARED AND MENU]
---
--- Calculates the squared length of the vector.
---
--- Faster than `getLength`, use it to compare lengths.
---
---@param self dreamwork.std.Vector2 The vector.
---@return number length The squared length of the vector.
local function Vector2_getLengthSqr( self )
    local x, y = self.x, self.y
    return x * x + y * y
end

Vector2.getLengthSqr = Vector2_getLengthSqr

--- [SHARED AND MENU]
---
--- Calculates the length of the vector.
---
---@param self dreamwork.std.Vector2 The vector.
---@return number length The length of the vector.
local function Vector2_getLength( self )
    return math_sqrt( Vector2_getLengthSqr( self ) )
end

Vector2.getLength = Vector2_getLength

--- [SHARED AND MENU]
---
--- Calculates the squared distance between two vectors.
---
--- Faster than `getDistance`, use it to compare distances.
---
---@param vector dreamwork.std.Vector2 The other vector.
---@return number distance The squared distance between the two vectors.
function Vector2:getDistanceSqr( vector )
    local x, y = vector.x - self.x, vector.y - self.y
    return x * x + y * y
end

--- [SHARED AND MENU]
---
--- Calculates the distance between two vectors.
---
---@param vector dreamwork.std.Vector2 The other vector.
---@return number distance The distance between the two vectors.
function Vector2:getDistance( vector )
    local x, y = vector.x - self.x, vector.y - self.y
    return math_sqrt( x * x + y * y )
end

--- [SHARED AND MENU]
---
--- Scales the vector to the length of `1`.
---
--- Zero vector stays unchanged.
---
---@param self dreamwork.std.Vector2 The vector.
---@return dreamwork.std.Vector2 vec2 The same vector, normalized.
local function Vector2_normalize( self )
    local length = Vector2_getLength( self )
    if length == 0 then
        return self
    end

    return Vector2_scale( self, 1 / length )
end

Vector2.normalize = Vector2_normalize

--- [SHARED AND MENU]
---
--- Returns a copy of the vector with the length of `1`.
---
--- Zero vector returns a zero copy.
---
---@return dreamwork.std.Vector2 normalized_vec2 The new vector.
function Vector2:getNormalized()
    return Vector2_normalize( Vector2_copy( self ) )
end

--- [SHARED AND MENU]
---
--- Returns the angle of the vector in degrees, measured clockwise from the `+y` axis in range ( 0, 360 ].
---
--- If `up` is given, its angle is added to the result.
---
---@param self dreamwork.std.Vector2 The vector.
---@param up? dreamwork.std.Vector2 The direction of the angle.
---@return number degrees The angle of the vector.
local function Vector2_getAngle( self, up )
    if up == nil then
        return 360 - math_deg( math_atan2( self.x, self.y ) )
    end

    return Vector2_getAngle( up ) + Vector2_getAngle( self )
end

Vector2.getAngle = Vector2_getAngle

--- [SHARED AND MENU]
---
--- Rotates the vector counter-clockwise ( from `+x` towards `+y` ) by the given degrees.
---
---@param self dreamwork.std.Vector2 The vector.
---@param degrees number The rotation angle.
---@return dreamwork.std.Vector2 vec2 The same vector, rotated.
local function Vector2_rotate( self, degrees )
    local radians = math_rad( degrees )
    local s, c = math_sin( radians ), math_cos( radians )
    local x, y = self.x, self.y

    self.x, self.y = x * c - y * s, x * s + y * c
    return self
end

Vector2.rotate = Vector2_rotate

--- [SHARED AND MENU]
---
--- Returns a copy of the vector rotated counter-clockwise ( from `+x` towards `+y` ) by the given degrees.
---
---@param degrees number The rotation angle.
---@return dreamwork.std.Vector2 rotated_vec2 The new vector.
function Vector2:getRotated( degrees )
    return Vector2_rotate( Vector2_copy( self ), degrees )
end

--- [SHARED AND MENU]
---
--- Linear interpolation between the vector and another vector or a number.
---
--- `frac` of `0` keeps the vector, `1` sets it to the target, values outside [0, 1] extrapolate.
---
---@param self dreamwork.std.Vector2 The vector.
---@param target dreamwork.std.Vector2 | number The target vector or a number ( used for every coordinate ).
---@param frac number The interpolation factor.
---@return dreamwork.std.Vector2 vec2 The same vector, interpolated.
local function Vector2_lerp( self, target, frac )
    local x, y = self.x, self.y

    if isNumber( target ) then
        ---@cast target number
        self.x, self.y = x + (target - x) * frac, y + (target - y) * frac
    else
        ---@cast target dreamwork.std.Vector2
        self.x, self.y = x + (target.x - x) * frac, y + (target.y - y) * frac
    end

    return self
end

Vector2.lerp = Vector2_lerp

--- [SHARED AND MENU]
---
--- Returns a copy of the vector linearly interpolated to another vector or a number.
---
---@param self dreamwork.std.Vector2 The vector.
---@param target dreamwork.std.Vector2 | number The target vector or a number ( used for every coordinate ).
---@param frac number The interpolation factor.
---@return dreamwork.std.Vector2 lerped_vec2 The new vector.
local function Vector2_getLerped( self, target, frac )
    return Vector2_lerp( Vector2_copy( self ), target, frac )
end

Vector2.getLerped = Vector2_getLerped

Vector2Class.origin = Vector2Class( 0, 0 )
