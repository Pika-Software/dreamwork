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
local math_clamp = math.clamp
local math_atan2 = math.atan2
local math_deg, math_rad = math.deg, math.rad
local math_cos, math_sin = math.cos, math.sin

local setmetatable = std.setmetatable

local isVector3 = std.isVector3
local Vector3Class = std.Vector3
local Angle3Class = std.Angle3
local QuaternionClass = std.Quaternion

--[[

    VMatrix structure ( Source engine `VMatrix`, row-major ):

        m11 m12 m13 m14 - row 1
        m21 m22 m23 m24 - row 2
        m31 m32 m33 m34 - row 3
        m41 m42 m43 m44 - row 4

    Columns 1, 2 and 3 are the forward, left and up directions,
    column 4 is the translation.

    Vectors are column vectors, so `A * B` means "transform by `B`, then by `A`".

    When `std.ffi` is available, matrices are `struct { double m11, ..., m44; }` cdata
    objects, otherwise they are plain tables with `m11` ... `m44` keys.

    NOTE: In FFI mode `VMatrix` is used as the `ffi.metatype` metatable, LuaJIT
    forbids modifying it after matrices start being used, so all methods must be
    defined in this file and must not be added to it from other files.

    Naming convention:

        `matrix:name( ... )`    - modifies the matrix in place and returns it.
        `matrix:getName( ... )` - returns a new object, the original stays unchanged.
        operators              - always return a new matrix ( or vector for `matrix * vec3` ).

    ref: https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/public/mathlib/vmatrix.h

    ref: https://github.com/excessive/cpml/blob/master/modules/mat4.lua

]]

--- [SHARED AND MENU]
---
--- A 4x4 transformation matrix object ( rotation, scale and translation ) in Source engine layout.
---
--- Operators:
--- * `matrix * matrix` - matrix product, `a * b` transforms by `b` first, then by `a`.
--- * `matrix * vec3` - transforms the point ( with translation ), returns a new `Vector3`.
--- * `matrix + matrix`, `matrix - matrix` - component-wise.
---
--- There is no division operator, use `getInverse` explicitly, it can fail for singular matrices.
---
---@class dreamwork.std.VMatrix : dreamwork.std.Object
---@field __class dreamwork.std.VMatrixClass
---@operator add( dreamwork.std.VMatrix ): dreamwork.std.VMatrix
---@operator sub( dreamwork.std.VMatrix ): dreamwork.std.VMatrix
---@operator mul( dreamwork.std.Vector3 ): dreamwork.std.Vector3
---@operator mul( dreamwork.std.VMatrix ): dreamwork.std.VMatrix
---@field m11 number Row 1, column 1 ( forward X ).
---@field m12 number Row 1, column 2 ( left X ).
---@field m13 number Row 1, column 3 ( up X ).
---@field m14 number Row 1, column 4 ( translation X ).
---@field m21 number Row 2, column 1 ( forward Y ).
---@field m22 number Row 2, column 2 ( left Y ).
---@field m23 number Row 2, column 3 ( up Y ).
---@field m24 number Row 2, column 4 ( translation Y ).
---@field m31 number Row 3, column 1 ( forward Z ).
---@field m32 number Row 3, column 2 ( left Z ).
---@field m33 number Row 3, column 3 ( up Z ).
---@field m34 number Row 3, column 4 ( translation Z ).
---@field m41 number Row 4, column 1, `0` for affine transforms.
---@field m42 number Row 4, column 2, `0` for affine transforms.
---@field m43 number Row 4, column 3, `0` for affine transforms.
---@field m44 number Row 4, column 4, `1` for affine transforms.
local VMatrix = class.base( "VMatrix", false )

--- [SHARED AND MENU]
---
--- The class used to create new `VMatrix` instances.
---
--- ```lua
--- local identity = std.VMatrix() -- like `Matrix()` in Garry's Mod
--- local transform = std.VMatrix.fromAngle3( std.Angle3( 0, 90, 0 ), std.Vector3( 0, 0, 64 ) )
--- ```
---
---@class dreamwork.std.VMatrixClass : dreamwork.std.VMatrix
---@field __base dreamwork.std.VMatrix
---@overload fun( ...: number? ): dreamwork.std.VMatrix
local VMatrixClass = class.create( VMatrix )
std.VMatrix = VMatrixClass

--- Creates a new matrix without any checks, all 16 arguments ( row by row ) must be numbers.
---
---@type fun( m11: number, m12: number, m13: number, m14: number, m21: number, m22: number, m23: number, m24: number, m31: number, m32: number, m33: number, m34: number, m41: number, m42: number, m43: number, m44: number ): dreamwork.std.VMatrix
local VMatrix_create

--- [SHARED AND MENU]
---
--- Returns `true` if the value is a `VMatrix`.
---
--- In FFI mode only `VMatrix` cdata objects are accepted.
---
---@type fun( value: any ): ( is_vmatrix: boolean )
local isVMatrix

if ffi == nil then

    ---@return dreamwork.std.VMatrix
    function VMatrix_create( m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44 )
        return setmetatable( {
            m11 = m11,
            m12 = m12,
            m13 = m13,
            m14 = m14,
            m21 = m21,
            m22 = m22,
            m23 = m23,
            m24 = m24,
            m31 = m31,
            m32 = m32,
            m33 = m33,
            m34 = m34,
            m41 = m41,
            m42 = m42,
            m43 = m43,
            m44 = m44
        }, VMatrix )
    end

    ---@param value any
    ---@return boolean is_vmatrix
    function isVMatrix( value )
        return debug_getmetatable( value ) == VMatrix
    end

else

    local ffi_istype = ffi.istype

    local VMatrix_ctype = ffi.metatype( "struct { double m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44; }", VMatrix )

    ---@return dreamwork.std.VMatrix
    function VMatrix_create( m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44 )
        ---@diagnostic disable-next-line: return-type-mismatch
        return VMatrix_ctype( m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44 )
    end

    ---@param value any
    ---@return boolean is_vmatrix
    function isVMatrix( value )
        return ffi_istype( VMatrix_ctype, value )
    end

end

std.isVMatrix = isVMatrix

--- Creates a new matrix from 16 values ( row by row ).
---
--- Without arguments creates an identity matrix ( like `Matrix()` in Garry's Mod ),
--- otherwise missing values default to `0`.
---
---@param m11 number?
---@param m12 number?
---@param m13 number?
---@param m14 number?
---@param m21 number?
---@param m22 number?
---@param m23 number?
---@param m24 number?
---@param m31 number?
---@param m32 number?
---@param m33 number?
---@param m34 number?
---@param m41 number?
---@param m42 number?
---@param m43 number?
---@param m44 number?
---@return dreamwork.std.VMatrix matrix The new matrix.
---@protected
function VMatrixClass:__new( m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44 )
    if m11 == nil and m12 == nil and m13 == nil and m14 == nil and m21 == nil and m22 == nil and m23 == nil and m24 == nil and
        m31 == nil and m32 == nil and m33 == nil and m34 == nil and m41 == nil and m42 == nil and m43 == nil and m44 == nil then
        return VMatrix_create( 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 )
    end

    return VMatrix_create(
        m11 or 0, m12 or 0, m13 or 0, m14 or 0,
        m21 or 0, m22 or 0, m23 or 0, m24 or 0,
        m31 or 0, m32 or 0, m33 or 0, m34 or 0,
        m41 or 0, m42 or 0, m43 or 0, m44 or 0
    )
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

--- Debug representation, the address and all rows with 2 decimals.
---
---@return string str The debug representation.
---@protected
function VMatrix:__represent()
    return string_format( "VMatrix: %p\n[\n%.2f %.2f %.2f %.2f,\n%.2f %.2f %.2f %.2f,\n%.2f %.2f %.2f %.2f,\n%.2f %.2f %.2f %.2f\n]", self,
        self.m11, self.m12, self.m13, self.m14,
        self.m21, self.m22, self.m23, self.m24,
        self.m31, self.m32, self.m33, self.m34,
        self.m41, self.m42, self.m43, self.m44
    )
end

--- String conversion, four rows separated by new lines, e.g. `1.000000 0.000000 0.000000 0.000000\n...`.
---
---@return string str The string representation.
---@protected
function VMatrix:__tostring()
    return string_format( "%f %f %f %f\n%f %f %f %f\n%f %f %f %f\n%f %f %f %f",
        self.m11, self.m12, self.m13, self.m14,
        self.m21, self.m22, self.m23, self.m24,
        self.m31, self.m32, self.m33, self.m34,
        self.m41, self.m42, self.m43, self.m44
    )
end

--- Exact component-wise comparison, comparing with a non-matrix value returns `false`.
---
---@param other any The value to compare with.
---@return boolean is_equal `true` if both are matrices with equal values.
---@protected
function VMatrix:__eq( other )
    return isVMatrix( other ) and
        self.m11 == other.m11 and self.m12 == other.m12 and self.m13 == other.m13 and self.m14 == other.m14 and
        self.m21 == other.m21 and self.m22 == other.m22 and self.m23 == other.m23 and self.m24 == other.m24 and
        self.m31 == other.m31 and self.m32 == other.m32 and self.m33 == other.m33 and self.m34 == other.m34 and
        self.m41 == other.m41 and self.m42 == other.m42 and self.m43 == other.m43 and self.m44 == other.m44
end

--- [SHARED AND MENU]
---
--- Returns all 16 values of the matrix ( row by row ).
---
---@return number m11, number m12, number m13, number m14, number m21, number m22, number m23, number m24, number m31, number m32, number m33, number m34, number m41, number m42, number m43, number m44
local function VMatrix_unpack( self )
    return self.m11, self.m12, self.m13, self.m14,
        self.m21, self.m22, self.m23, self.m24,
        self.m31, self.m32, self.m33, self.m34,
        self.m41, self.m42, self.m43, self.m44
end

VMatrix.unpack = VMatrix_unpack

--- [SHARED AND MENU]
---
--- Sets all 16 values of the matrix ( row by row ).
---
---@return dreamwork.std.VMatrix matrix The same matrix.
local function VMatrix_setUnpacked( self, m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44 )
    self.m11, self.m12, self.m13, self.m14 = m11, m12, m13, m14
    self.m21, self.m22, self.m23, self.m24 = m21, m22, m23, m24
    self.m31, self.m32, self.m33, self.m34 = m31, m32, m33, m34
    self.m41, self.m42, self.m43, self.m44 = m41, m42, m43, m44
    return self
end

VMatrix.setUnpacked = VMatrix_setUnpacked

-- --- Writes the matrix as sixteen 32-bit floats row by row ( precision is reduced to float ).
-- ---
-- ---@param writer dreamwork.std.BinaryWriter The writer.
-- ---@protected
-- function VMatrix:__serialize( writer )
--     writer:writeFloat( self.m11 ); writer:writeFloat( self.m12 ); writer:writeFloat( self.m13 ); writer:writeFloat( self.m14 )
--     writer:writeFloat( self.m21 ); writer:writeFloat( self.m22 ); writer:writeFloat( self.m23 ); writer:writeFloat( self.m24 )
--     writer:writeFloat( self.m31 ); writer:writeFloat( self.m32 ); writer:writeFloat( self.m33 ); writer:writeFloat( self.m34 )
--     writer:writeFloat( self.m41 ); writer:writeFloat( self.m42 ); writer:writeFloat( self.m43 ); writer:writeFloat( self.m44 )
-- end

-- --- Reads the matrix from sixteen 32-bit floats row by row.
-- ---
-- ---@param reader dreamwork.std.BinaryReader The reader.
-- ---@protected
-- function VMatrix:__deserialize( reader )
--     self.m11 = reader:readFloat(); self.m12 = reader:readFloat(); self.m13 = reader:readFloat(); self.m14 = reader:readFloat()
--     self.m21 = reader:readFloat(); self.m22 = reader:readFloat(); self.m23 = reader:readFloat(); self.m24 = reader:readFloat()
--     self.m31 = reader:readFloat(); self.m32 = reader:readFloat(); self.m33 = reader:readFloat(); self.m34 = reader:readFloat()
--     self.m41 = reader:readFloat(); self.m42 = reader:readFloat(); self.m43 = reader:readFloat(); self.m44 = reader:readFloat()
-- end

--- [SHARED AND MENU]
---
--- Copies the values of another matrix into this matrix.
---
---@param matrix dreamwork.std.VMatrix The matrix to copy from.
---@return dreamwork.std.VMatrix matrix The same matrix.
function VMatrix:set( matrix )
    return VMatrix_setUnpacked( self, VMatrix_unpack( matrix ) )
end

--- [SHARED AND MENU]
---
--- Creates a new independent copy of the matrix.
---
---@param self dreamwork.std.VMatrix The matrix.
---@return dreamwork.std.VMatrix copy The new matrix.
local function VMatrix_copy( self )
    return VMatrix_create( VMatrix_unpack( self ) )
end

VMatrix.copy = VMatrix_copy
VMatrix.clone = VMatrix_copy

--- [SHARED AND MENU]
---
--- Sets the matrix to identity ( no rotation, no translation, scale `1` ).
---
---@return dreamwork.std.VMatrix matrix The same matrix.
function VMatrix:identity()
    return VMatrix_setUnpacked( self, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 )
end

--- [SHARED AND MENU]
---
--- Checks if the matrix is exactly identity.
---
---@return boolean is_identity `true` if the matrix is identity, `false` otherwise.
function VMatrix:isIdentity()
    return self.m11 == 1 and self.m12 == 0 and self.m13 == 0 and self.m14 == 0 and
        self.m21 == 0 and self.m22 == 1 and self.m23 == 0 and self.m24 == 0 and
        self.m31 == 0 and self.m32 == 0 and self.m33 == 1 and self.m34 == 0 and
        self.m41 == 0 and self.m42 == 0 and self.m43 == 0 and self.m44 == 1
end

--- [SHARED AND MENU]
---
--- Sets all values of the matrix to zero.
---
---@return dreamwork.std.VMatrix matrix The same matrix.
function VMatrix:zero()
    return VMatrix_setUnpacked( self, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 )
end

--- [SHARED AND MENU]
---
--- Checks if all values of the matrix are exactly zero.
---
---@return boolean is_zero `true` if the matrix is zero, `false` otherwise.
function VMatrix:isZero()
    return self.m11 == 0 and self.m12 == 0 and self.m13 == 0 and self.m14 == 0 and
        self.m21 == 0 and self.m22 == 0 and self.m23 == 0 and self.m24 == 0 and
        self.m31 == 0 and self.m32 == 0 and self.m33 == 0 and self.m34 == 0 and
        self.m41 == 0 and self.m42 == 0 and self.m43 == 0 and self.m44 == 0
end

--- [SHARED AND MENU]
---
--- Checks if the matrix is equal to the given matrix with the given tolerance.
---
--- Each of the 16 values is compared separately.
---
---@param matrix dreamwork.std.VMatrix The matrix to check.
---@param tolerance number The maximum allowed difference per value.
---@return boolean is_near `true` if the matrices are equal within the tolerance, otherwise `false`.
function VMatrix:isNear( matrix, tolerance )
    return math_abs( self.m11 - matrix.m11 ) <= tolerance and math_abs( self.m12 - matrix.m12 ) <= tolerance and
        math_abs( self.m13 - matrix.m13 ) <= tolerance and math_abs( self.m14 - matrix.m14 ) <= tolerance and
        math_abs( self.m21 - matrix.m21 ) <= tolerance and math_abs( self.m22 - matrix.m22 ) <= tolerance and
        math_abs( self.m23 - matrix.m23 ) <= tolerance and math_abs( self.m24 - matrix.m24 ) <= tolerance and
        math_abs( self.m31 - matrix.m31 ) <= tolerance and math_abs( self.m32 - matrix.m32 ) <= tolerance and
        math_abs( self.m33 - matrix.m33 ) <= tolerance and math_abs( self.m34 - matrix.m34 ) <= tolerance and
        math_abs( self.m41 - matrix.m41 ) <= tolerance and math_abs( self.m42 - matrix.m42 ) <= tolerance and
        math_abs( self.m43 - matrix.m43 ) <= tolerance and math_abs( self.m44 - matrix.m44 ) <= tolerance
end

do

    ---@type string[]
    local fields = {
        "m11", "m12", "m13", "m14",
        "m21", "m22", "m23", "m24",
        "m31", "m32", "m33", "m34",
        "m41", "m42", "m43", "m44"
    }

    --- [SHARED AND MENU]
    ---
    --- Returns the value of the matrix at the given row and column.
    ---
    --- Same as `VMatrix:GetField` in Garry's Mod, out of range indices are clamped to [1, 4].
    ---
    --- Slower than accessing the fields directly ( `matrix.m23` ).
    ---
    ---@param row integer The row, from 1 to 4.
    ---@param column integer The column, from 1 to 4.
    ---@return number value The value.
    function VMatrix:getField( row, column )
        return self[ fields[ (math_clamp( row, 1, 4 ) - 1) * 4 + math_clamp( column, 1, 4 ) ] ]
    end

    --- [SHARED AND MENU]
    ---
    --- Sets the value of the matrix at the given row and column.
    ---
    --- Same as `VMatrix:SetField` in Garry's Mod, out of range indices are clamped to [1, 4].
    ---
    ---@param row integer The row, from 1 to 4.
    ---@param column integer The column, from 1 to 4.
    ---@param value number The value.
    ---@return dreamwork.std.VMatrix matrix The same matrix.
    function VMatrix:setField( row, column, value )
        self[ fields[ (math_clamp( row, 1, 4 ) - 1) * 4 + math_clamp( column, 1, 4 ) ] ] = value
        return self
    end

end

--- Stores `a * b` into `result`, any of the matrices can be the same object.
---@param result dreamwork.std.VMatrix
---@param a dreamwork.std.VMatrix
---@param b dreamwork.std.VMatrix
---@return dreamwork.std.VMatrix
local function multiply( result, a, b )
    local a11, a12, a13, a14, a21, a22, a23, a24, a31, a32, a33, a34, a41, a42, a43, a44 = VMatrix_unpack( a )
    local b11, b12, b13, b14, b21, b22, b23, b24, b31, b32, b33, b34, b41, b42, b43, b44 = VMatrix_unpack( b )

    return VMatrix_setUnpacked( result,
        a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41,
        a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42,
        a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43,
        a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44,

        a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41,
        a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42,
        a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43,
        a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44,

        a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41,
        a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42,
        a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43,
        a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44,

        a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41,
        a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42,
        a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43,
        a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44
    )
end

--- [SHARED AND MENU]
---
--- Multiplies the matrix by another matrix ( `self = self * matrix` ).
---
--- Same as `VMatrix:Mul` in Garry's Mod, `matrix` is applied before the current transform.
---
---@param matrix dreamwork.std.VMatrix The other matrix.
---@return dreamwork.std.VMatrix matrix The same matrix, with the product.
function VMatrix:mul( matrix )
    return multiply( self, self, matrix )
end

VMatrix.multiply = VMatrix.mul

--- [SHARED AND MENU]
---
--- Multiplies another matrix by the matrix ( `self = matrix * self` ).
---
--- `matrix` is applied after the current transform.
---
---@param matrix dreamwork.std.VMatrix The other matrix.
---@return dreamwork.std.VMatrix matrix The same matrix, with the product.
function VMatrix:premul( matrix )
    return multiply( self, matrix, self )
end

--- [SHARED AND MENU]
---
--- Transforms the point by the matrix ( rotation, scale and translation ), same as `matrix * vec3`.
---
--- The fourth row is ignored ( no perspective divide ).
---
---@param self dreamwork.std.VMatrix The matrix.
---@param vector dreamwork.std.Vector3 The point.
---@return dreamwork.std.Vector3 vec3 The new transformed point.
local function VMatrix_transformPoint( self, vector )
    local x, y, z = vector.x, vector.y, vector.z
    return Vector3Class(
        self.m11 * x + self.m12 * y + self.m13 * z + self.m14,
        self.m21 * x + self.m22 * y + self.m23 * z + self.m24,
        self.m31 * x + self.m32 * y + self.m33 * z + self.m34
    )
end

VMatrix.transformPoint = VMatrix_transformPoint

--- [SHARED AND MENU]
---
--- Transforms the direction by the matrix ( rotation and scale, without translation ).
---
--- The result is not normalized if the matrix has scale.
---
---@param vector dreamwork.std.Vector3 The direction.
---@return dreamwork.std.Vector3 vec3 The new transformed direction.
function VMatrix:transformDirection( vector )
    local x, y, z = vector.x, vector.y, vector.z
    return Vector3Class(
        self.m11 * x + self.m12 * y + self.m13 * z,
        self.m21 * x + self.m22 * y + self.m23 * z,
        self.m31 * x + self.m32 * y + self.m33 * z
    )
end

--- `matrix * matrix` ( matrix product ) and `matrix * vec3` ( transforms the point ).
---
---@param a dreamwork.std.VMatrix
---@param b dreamwork.std.VMatrix | dreamwork.std.Vector3
---@return dreamwork.std.VMatrix | dreamwork.std.Vector3 product The new matrix, or the new vector for `matrix * vec3`.
---@protected
function VMatrix.__mul( a, b )
    if isVector3( b ) then
        ---@cast b dreamwork.std.Vector3
        return VMatrix_transformPoint( a, b )
    end

    ---@cast b dreamwork.std.VMatrix
    return multiply( VMatrix_create( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ), a, b )
end

--- `matrix + matrix` ( component-wise ).
---
---@param a dreamwork.std.VMatrix
---@param b dreamwork.std.VMatrix
---@return dreamwork.std.VMatrix sum The new matrix.
---@protected
function VMatrix.__add( a, b )
    return VMatrix_create(
        a.m11 + b.m11, a.m12 + b.m12, a.m13 + b.m13, a.m14 + b.m14,
        a.m21 + b.m21, a.m22 + b.m22, a.m23 + b.m23, a.m24 + b.m24,
        a.m31 + b.m31, a.m32 + b.m32, a.m33 + b.m33, a.m34 + b.m34,
        a.m41 + b.m41, a.m42 + b.m42, a.m43 + b.m43, a.m44 + b.m44
    )
end

--- `matrix - matrix` ( component-wise ).
---
---@param a dreamwork.std.VMatrix
---@param b dreamwork.std.VMatrix
---@return dreamwork.std.VMatrix difference The new matrix.
---@protected
function VMatrix.__sub( a, b )
    return VMatrix_create(
        a.m11 - b.m11, a.m12 - b.m12, a.m13 - b.m13, a.m14 - b.m14,
        a.m21 - b.m21, a.m22 - b.m22, a.m23 - b.m23, a.m24 - b.m24,
        a.m31 - b.m31, a.m32 - b.m32, a.m33 - b.m33, a.m34 - b.m34,
        a.m41 - b.m41, a.m42 - b.m42, a.m43 - b.m43, a.m44 - b.m44
    )
end

--- [SHARED AND MENU]
---
--- Transposes the matrix ( swaps rows and columns ).
---
--- For pure rotation matrices the transpose is the inverse.
---
---@param self dreamwork.std.VMatrix The matrix.
---@return dreamwork.std.VMatrix matrix The same matrix, transposed.
local function VMatrix_transpose( self )
    local m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44 = VMatrix_unpack( self )
    return VMatrix_setUnpacked( self, m11, m21, m31, m41, m12, m22, m32, m42, m13, m23, m33, m43, m14, m24, m34, m44 )
end

VMatrix.transpose = VMatrix_transpose

--- [SHARED AND MENU]
---
--- Returns a transposed copy of the matrix.
---
---@return dreamwork.std.VMatrix transposed_matrix The new matrix.
function VMatrix:getTransposed()
    return VMatrix_transpose( VMatrix_copy( self ) )
end

do

    --- Returns 2x2 sub-determinants used by the determinant and the inverse.
    local function subDeterminants( a11, a12, a13, a14, a21, a22, a23, a24, a31, a32, a33, a34, a41, a42, a43, a44 )
        return a11 * a22 - a21 * a12, a11 * a23 - a21 * a13, a11 * a24 - a21 * a14,
            a12 * a23 - a22 * a13, a12 * a24 - a22 * a14, a13 * a24 - a23 * a14,
            a31 * a42 - a41 * a32, a31 * a43 - a41 * a33, a31 * a44 - a41 * a34,
            a32 * a43 - a42 * a33, a32 * a44 - a42 * a34, a33 * a44 - a43 * a34
    end

    --- [SHARED AND MENU]
    ---
    --- Calculates the determinant of the matrix.
    ---
    --- `1` for rotation matrices, `0` for singular ( non-invertible ) matrices, negative if the matrix mirrors.
    ---
    ---@return number determinant The determinant.
    function VMatrix:getDeterminant()
        local s0, s1, s2, s3, s4, s5, c0, c1, c2, c3, c4, c5 = subDeterminants( VMatrix_unpack( self ) )
        return s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0
    end

    --- [SHARED AND MENU]
    ---
    --- Inverts the matrix ( full 4x4 inverse ).
    ---
    --- Same as `VMatrix:Invert` in Garry's Mod, the matrix stays unchanged if it can't be inverted.
    ---
    --- Use `invertTR` for rotation + translation matrices, it is faster and always succeeds.
    ---
    ---@param self dreamwork.std.VMatrix The matrix.
    ---@return boolean success `true` if the matrix was inverted, `false` if the matrix is singular.
    local function VMatrix_invert( self )
        local a11, a12, a13, a14, a21, a22, a23, a24, a31, a32, a33, a34, a41, a42, a43, a44 = VMatrix_unpack( self )
        local s0, s1, s2, s3, s4, s5, c0, c1, c2, c3, c4, c5 = subDeterminants( a11, a12, a13, a14, a21, a22, a23, a24, a31, a32, a33, a34, a41, a42, a43, a44 )

        local determinant = s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0
        if determinant == 0 or determinant ~= determinant then
            return false
        end

        local d = 1 / determinant

        VMatrix_setUnpacked( self,
            (a22 * c5 - a23 * c4 + a24 * c3) * d,
            (-a12 * c5 + a13 * c4 - a14 * c3) * d,
            (a42 * s5 - a43 * s4 + a44 * s3) * d,
            (-a32 * s5 + a33 * s4 - a34 * s3) * d,

            (-a21 * c5 + a23 * c2 - a24 * c1) * d,
            (a11 * c5 - a13 * c2 + a14 * c1) * d,
            (-a41 * s5 + a43 * s2 - a44 * s1) * d,
            (a31 * s5 - a33 * s2 + a34 * s1) * d,

            (a21 * c4 - a22 * c2 + a24 * c0) * d,
            (-a11 * c4 + a12 * c2 - a14 * c0) * d,
            (a41 * s4 - a42 * s2 + a44 * s0) * d,
            (-a31 * s4 + a32 * s2 - a34 * s0) * d,

            (-a21 * c3 + a22 * c1 - a23 * c0) * d,
            (a11 * c3 - a12 * c1 + a13 * c0) * d,
            (-a41 * s3 + a42 * s1 - a43 * s0) * d,
            (a31 * s3 - a32 * s1 + a33 * s0) * d
        )

        return true
    end

    VMatrix.invert = VMatrix_invert

    --- [SHARED AND MENU]
    ---
    --- Returns the inverse of the matrix ( full 4x4 inverse ).
    ---
    --- Same as `VMatrix:GetInverse` in Garry's Mod.
    ---
    ---@return dreamwork.std.VMatrix | nil inverted_matrix The new matrix, or `nil` if the matrix is singular.
    function VMatrix:getInverse()
        local matrix = VMatrix_copy( self )
        if VMatrix_invert( matrix ) then
            return matrix
        end

        return nil
    end

end

--- [SHARED AND MENU]
---
--- Inverts the matrix, assuming it only contains rotation and translation ( no scale ).
---
--- Same as `VMatrix:InvertTR` in Garry's Mod, much faster than `invert`,
--- but the result is wrong for scaled or skewed matrices. The fourth row is reset to `0 0 0 1`.
---
---@param self dreamwork.std.VMatrix The matrix.
---@return dreamwork.std.VMatrix matrix The same matrix, inverted.
local function VMatrix_invertTR( self )
    local m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34 = VMatrix_unpack( self )

    return VMatrix_setUnpacked( self,
        m11, m21, m31, -(m11 * m14 + m21 * m24 + m31 * m34),
        m12, m22, m32, -(m12 * m14 + m22 * m24 + m32 * m34),
        m13, m23, m33, -(m13 * m14 + m23 * m24 + m33 * m34),
        0, 0, 0, 1
    )
end

VMatrix.invertTR = VMatrix_invertTR

--- [SHARED AND MENU]
---
--- Returns the inverse of the matrix, assuming it only contains rotation and translation ( no scale ).
---
--- Same as `VMatrix:GetInverseTR` in Garry's Mod.
---
---@return dreamwork.std.VMatrix inverted_matrix The new matrix.
function VMatrix:getInverseTR()
    return VMatrix_invertTR( VMatrix_copy( self ) )
end

--- [SHARED AND MENU]
---
--- Returns the forward direction of the matrix ( first column ).
---
--- Same as `VMatrix:GetForward` in Garry's Mod, not normalized if the matrix has scale.
---
---@return dreamwork.std.Vector3 forward_dir The new vector.
function VMatrix:getForward()
    return Vector3Class( self.m11, self.m21, self.m31 )
end

--- [SHARED AND MENU]
---
--- Sets the forward direction of the matrix ( first column ).
---
--- Same as `VMatrix:SetForward` in Garry's Mod.
---
---@param vector dreamwork.std.Vector3 The forward direction.
---@return dreamwork.std.VMatrix matrix The same matrix.
function VMatrix:setForward( vector )
    self.m11, self.m21, self.m31 = vector.x, vector.y, vector.z
    return self
end

--- [SHARED AND MENU]
---
--- Returns the left direction of the matrix ( second column ).
---
---@return dreamwork.std.Vector3 left_dir The new vector.
function VMatrix:getLeft()
    return Vector3Class( self.m12, self.m22, self.m32 )
end

--- [SHARED AND MENU]
---
--- Sets the left direction of the matrix ( second column ).
---
---@param vector dreamwork.std.Vector3 The left direction.
---@return dreamwork.std.VMatrix matrix The same matrix.
function VMatrix:setLeft( vector )
    self.m12, self.m22, self.m32 = vector.x, vector.y, vector.z
    return self
end

--- [SHARED AND MENU]
---
--- Returns the right direction of the matrix ( negated second column ).
---
--- Same as `VMatrix:GetRight` in Garry's Mod.
---
---@return dreamwork.std.Vector3 right_dir The new vector.
function VMatrix:getRight()
    return Vector3Class( -self.m12, -self.m22, -self.m32 )
end

--- [SHARED AND MENU]
---
--- Sets the right direction of the matrix ( stored negated in the second column ).
---
--- Same as `VMatrix:SetRight` in Garry's Mod.
---
---@param vector dreamwork.std.Vector3 The right direction.
---@return dreamwork.std.VMatrix matrix The same matrix.
function VMatrix:setRight( vector )
    self.m12, self.m22, self.m32 = -vector.x, -vector.y, -vector.z
    return self
end

--- [SHARED AND MENU]
---
--- Returns the up direction of the matrix ( third column ).
---
--- Same as `VMatrix:GetUp` in Garry's Mod.
---
---@return dreamwork.std.Vector3 up_dir The new vector.
function VMatrix:getUp()
    return Vector3Class( self.m13, self.m23, self.m33 )
end

--- [SHARED AND MENU]
---
--- Sets the up direction of the matrix ( third column ).
---
--- Same as `VMatrix:SetUp` in Garry's Mod.
---
---@param vector dreamwork.std.Vector3 The up direction.
---@return dreamwork.std.VMatrix matrix The same matrix.
function VMatrix:setUp( vector )
    self.m13, self.m23, self.m33 = vector.x, vector.y, vector.z
    return self
end

--- [SHARED AND MENU]
---
--- Returns the translation of the matrix ( fourth column ).
---
--- Same as `VMatrix:GetTranslation` in Garry's Mod.
---
---@return dreamwork.std.Vector3 translation The new vector.
function VMatrix:getTranslation()
    return Vector3Class( self.m14, self.m24, self.m34 )
end

--- [SHARED AND MENU]
---
--- Sets the translation of the matrix ( fourth column ), rotation and scale stay unchanged.
---
--- Same as `VMatrix:SetTranslation` in Garry's Mod.
---
---@param vector dreamwork.std.Vector3 The translation.
---@return dreamwork.std.VMatrix matrix The same matrix.
function VMatrix:setTranslation( vector )
    self.m14, self.m24, self.m34 = vector.x, vector.y, vector.z
    return self
end

--- [SHARED AND MENU]
---
--- Translates the matrix by the given vector in local space ( `self = self * T` ).
---
--- Same as `VMatrix:Translate` in Garry's Mod, the offset is rotated and scaled by the matrix,
--- use `setTranslation` to move in world space.
---
---@param vector dreamwork.std.Vector3 The local offset.
---@return dreamwork.std.VMatrix matrix The same matrix, translated.
function VMatrix:translate( vector )
    local x, y, z = vector.x, vector.y, vector.z

    self.m14 = self.m11 * x + self.m12 * y + self.m13 * z + self.m14
    self.m24 = self.m21 * x + self.m22 * y + self.m23 * z + self.m24
    self.m34 = self.m31 * x + self.m32 * y + self.m33 * z + self.m34
    self.m44 = self.m41 * x + self.m42 * y + self.m43 * z + self.m44

    return self
end

--- [SHARED AND MENU]
---
--- Scales the translation of the matrix by the given number.
---
--- Same as `VMatrix:ScaleTranslation` in Garry's Mod.
---
---@param scale number The scale factor.
---@return dreamwork.std.VMatrix matrix The same matrix.
function VMatrix:scaleTranslation( scale )
    self.m14, self.m24, self.m34 = self.m14 * scale, self.m24 * scale, self.m34 * scale
    return self
end

--- [SHARED AND MENU]
---
--- Returns the unpacked Euler angles ( pitch, yaw, roll ) of the matrix in degrees.
---
--- Same as `MatrixAngles` in Source engine, allocation free alternative to `getAngles`.
---
--- Assumes the matrix has no scale, at pitch `±90` ( gimbal lock ) roll is always `0`.
---
---@param self dreamwork.std.VMatrix The matrix.
---@return number pitch The pitch in degrees.
---@return number yaw The yaw in degrees.
---@return number roll The roll in degrees.
local function VMatrix_unpackAngles( self )
    local a11, a21, a31 = self.m11, self.m21, self.m31

    local xy_distance = math_sqrt( a11 * a11 + a21 * a21 )
    if xy_distance > 0.001 then
        return math_deg( math_atan2( -a31, xy_distance ) ), math_deg( math_atan2( a21, a11 ) ), math_deg( math_atan2( self.m32, self.m33 ) )
    end

    return math_deg( math_atan2( -a31, xy_distance ) ), math_deg( math_atan2( -self.m12, self.m22 ) ), 0
end

VMatrix.unpackAngles = VMatrix_unpackAngles

--- [SHARED AND MENU]
---
--- Returns the rotation of the matrix as an angle.
---
--- Same as `VMatrix:GetAngles` in Garry's Mod, values are in range [-180, 180].
---
---@return dreamwork.std.Angle3 ang3 The new angle.
function VMatrix:getAngles()
    return Angle3Class( VMatrix_unpackAngles( self ) )
end

--- [SHARED AND MENU]
---
--- Sets the rotation of the matrix from the angle, translation and the fourth row stay unchanged.
---
--- Same as `VMatrix:SetAngles` in Garry's Mod, any existing scale is lost.
---
---@param angle dreamwork.std.Angle3 The angle.
---@return dreamwork.std.VMatrix matrix The same matrix.
function VMatrix:setAngles( angle )
    self.m11, self.m12, self.m13,
    self.m21, self.m22, self.m23,
    self.m31, self.m32, self.m33 = angleMatrix( angle.pitch, angle.yaw, angle.roll )
    return self
end

--- [SHARED AND MENU]
---
--- Rotates the matrix by the given angle in local space ( `self = self * R` ).
---
--- Same as `VMatrix:Rotate` in Garry's Mod, translation stays unchanged.
---
---@param angle dreamwork.std.Angle3 The angle.
---@return dreamwork.std.VMatrix matrix The same matrix, rotated.
function VMatrix:rotate( angle )
    local r11, r12, r13, r21, r22, r23, r31, r32, r33 = angleMatrix( angle.pitch, angle.yaw, angle.roll )

    local a11, a12, a13 = self.m11, self.m12, self.m13
    local a21, a22, a23 = self.m21, self.m22, self.m23
    local a31, a32, a33 = self.m31, self.m32, self.m33
    local a41, a42, a43 = self.m41, self.m42, self.m43

    self.m11, self.m12, self.m13 = a11 * r11 + a12 * r21 + a13 * r31, a11 * r12 + a12 * r22 + a13 * r32, a11 * r13 + a12 * r23 + a13 * r33
    self.m21, self.m22, self.m23 = a21 * r11 + a22 * r21 + a23 * r31, a21 * r12 + a22 * r22 + a23 * r32, a21 * r13 + a22 * r23 + a23 * r33
    self.m31, self.m32, self.m33 = a31 * r11 + a32 * r21 + a33 * r31, a31 * r12 + a32 * r22 + a33 * r32, a31 * r13 + a32 * r23 + a33 * r33
    self.m41, self.m42, self.m43 = a41 * r11 + a42 * r21 + a43 * r31, a41 * r12 + a42 * r22 + a43 * r32, a41 * r13 + a42 * r23 + a43 * r33

    return self
end

--- [SHARED AND MENU]
---
--- Scales the matrix by the given vector in local space ( `self = self * S` ).
---
--- Same as `VMatrix:Scale` in Garry's Mod, multiplies the forward, left and up columns, translation stays unchanged.
---
---@param vector dreamwork.std.Vector3 The scale per axis.
---@return dreamwork.std.VMatrix matrix The same matrix, scaled.
function VMatrix:scale( vector )
    local x, y, z = vector.x, vector.y, vector.z

    self.m11, self.m12, self.m13 = self.m11 * x, self.m12 * y, self.m13 * z
    self.m21, self.m22, self.m23 = self.m21 * x, self.m22 * y, self.m23 * z
    self.m31, self.m32, self.m33 = self.m31 * x, self.m32 * y, self.m33 * z
    self.m41, self.m42, self.m43 = self.m41 * x, self.m42 * y, self.m43 * z

    return self
end

--- [SHARED AND MENU]
---
--- Returns the scale of the matrix ( lengths of the forward, left and up columns ).
---
--- Always positive, mirroring is not detected ( check `getDeterminant` for that ).
---
---@return dreamwork.std.Vector3 scale The new vector.
function VMatrix:getScale()
    local m11, m12, m13 = self.m11, self.m12, self.m13
    local m21, m22, m23 = self.m21, self.m22, self.m23
    local m31, m32, m33 = self.m31, self.m32, self.m33

    return Vector3Class(
        math_sqrt( m11 * m11 + m21 * m21 + m31 * m31 ),
        math_sqrt( m12 * m12 + m22 * m22 + m32 * m32 ),
        math_sqrt( m13 * m13 + m23 * m23 + m33 * m33 )
    )
end

--- [SHARED AND MENU]
---
--- Sets the scale of the matrix while preserving the rotation and translation.
---
--- Columns with zero length stay zero, since their direction is unknown.
---
---@param vector dreamwork.std.Vector3 The new scale per axis.
---@return dreamwork.std.VMatrix matrix The same matrix.
function VMatrix:setScale( vector )
    local m11, m12, m13 = self.m11, self.m12, self.m13
    local m21, m22, m23 = self.m21, self.m22, self.m23
    local m31, m32, m33 = self.m31, self.m32, self.m33

    local sx = math_sqrt( m11 * m11 + m21 * m21 + m31 * m31 )
    if sx ~= 0 then
        sx = vector.x / sx
        self.m11, self.m21, self.m31 = m11 * sx, m21 * sx, m31 * sx
    end

    local sy = math_sqrt( m12 * m12 + m22 * m22 + m32 * m32 )
    if sy ~= 0 then
        sy = vector.y / sy
        self.m12, self.m22, self.m32 = m12 * sy, m22 * sy, m32 * sy
    end

    local sz = math_sqrt( m13 * m13 + m23 * m23 + m33 * m33 )
    if sz ~= 0 then
        sz = vector.z / sz
        self.m13, self.m23, self.m33 = m13 * sz, m23 * sz, m33 * sz
    end

    return self
end

--- [SHARED AND MENU]
---
--- Checks if the matrix is a rotation matrix ( forward, left and up columns are normalized and perpendicular ).
---
--- Same as `VMatrix:IsRotationMatrix` in Garry's Mod, translation is ignored.
---
---@param tolerance? number The tolerance, defaults to `1e-3`.
---@return boolean is_rotation_matrix `true` if the matrix is a rotation matrix, `false` otherwise.
function VMatrix:isRotationMatrix( tolerance )
    tolerance = tolerance or 1e-3

    local m11, m12, m13 = self.m11, self.m12, self.m13
    local m21, m22, m23 = self.m21, self.m22, self.m23
    local m31, m32, m33 = self.m31, self.m32, self.m33

    return math_abs( m11 * m11 + m21 * m21 + m31 * m31 - 1 ) <= tolerance and
        math_abs( m12 * m12 + m22 * m22 + m32 * m32 - 1 ) <= tolerance and
        math_abs( m13 * m13 + m23 * m23 + m33 * m33 - 1 ) <= tolerance and
        math_abs( m11 * m12 + m21 * m22 + m31 * m32 ) <= tolerance and
        math_abs( m11 * m13 + m21 * m23 + m31 * m33 ) <= tolerance and
        math_abs( m12 * m13 + m22 * m23 + m32 * m33 ) <= tolerance
end

--- [SHARED AND MENU]
---
--- Returns the rotation of the matrix as a quaternion, scale and translation are ignored.
---
---@return dreamwork.std.Quaternion quat The new unit quaternion.
function VMatrix:toQuaternion()
    return QuaternionClass.fromVMatrix( self )
end

--- [SHARED AND MENU]
---
--- Interpolates the matrix to the target matrix.
---
--- Rotation is interpolated with quaternion slerp ( shortest path ), scale, translation and the fourth row linearly.
---
---@param t number The interpolation factor for translation, scale and the fourth row, `0` keeps the matrix, `1` sets it to the target.
---@param target dreamwork.std.VMatrix The target matrix.
---@param t_angle? number The interpolation factor for rotation, defaults to `t`.
---@return dreamwork.std.VMatrix matrix The same matrix, interpolated.
function VMatrix:lerp( t, target, t_angle )
    if t_angle == nil then
        t_angle = t
    end

    local scale1, scale2 = self:getScale(), target:getScale()
    local sx = scale1.x + (scale2.x - scale1.x) * t
    local sy = scale1.y + (scale2.y - scale1.y) * t
    local sz = scale1.z + (scale2.z - scale1.z) * t

    local a11, a12, a13, a21, a22, a23, a31, a32, a33 = QuaternionClass.fromVMatrix( self ):slerp( QuaternionClass.fromVMatrix( target ), t_angle ):unpackMatrix()

    self.m11, self.m12, self.m13 = a11 * sx, a12 * sy, a13 * sz
    self.m21, self.m22, self.m23 = a21 * sx, a22 * sy, a23 * sz
    self.m31, self.m32, self.m33 = a31 * sx, a32 * sy, a33 * sz

    self.m14 = self.m14 + (target.m14 - self.m14) * t
    self.m24 = self.m24 + (target.m24 - self.m24) * t
    self.m34 = self.m34 + (target.m34 - self.m34) * t

    self.m41 = self.m41 + (target.m41 - self.m41) * t
    self.m42 = self.m42 + (target.m42 - self.m42) * t
    self.m43 = self.m43 + (target.m43 - self.m43) * t
    self.m44 = self.m44 + (target.m44 - self.m44) * t

    return self
end

--- [SHARED AND MENU]
---
--- Creates a new rotation matrix from the angle and the optional translation.
---
--- Same as `AngleMatrix` in Source engine.
---
---@param angle dreamwork.std.Angle3 The angle.
---@param translation? dreamwork.std.Vector3 The translation, defaults to `( 0, 0, 0 )`.
---@return dreamwork.std.VMatrix matrix The new matrix.
function VMatrixClass.fromAngle3( angle, translation )
    local a11, a12, a13, a21, a22, a23, a31, a32, a33 = angleMatrix( angle.pitch, angle.yaw, angle.roll )

    if translation == nil then
        return VMatrix_create( a11, a12, a13, 0, a21, a22, a23, 0, a31, a32, a33, 0, 0, 0, 0, 1 )
    end

    return VMatrix_create( a11, a12, a13, translation.x, a21, a22, a23, translation.y, a31, a32, a33, translation.z, 0, 0, 0, 1 )
end

--- [SHARED AND MENU]
---
--- Creates a new rotation matrix from the quaternion and the optional translation.
---
--- Same as `QuaternionMatrix` in Source engine, works with non-unit quaternions.
---
---@param quaternion dreamwork.std.Quaternion The quaternion.
---@param translation? dreamwork.std.Vector3 The translation, defaults to `( 0, 0, 0 )`.
---@return dreamwork.std.VMatrix matrix The new matrix.
function VMatrixClass.fromQuaternion( quaternion, translation )
    local a11, a12, a13, a21, a22, a23, a31, a32, a33 = quaternion:unpackMatrix()

    if translation == nil then
        return VMatrix_create( a11, a12, a13, 0, a21, a22, a23, 0, a31, a32, a33, 0, 0, 0, 0, 1 )
    end

    return VMatrix_create( a11, a12, a13, translation.x, a21, a22, a23, translation.y, a31, a32, a33, translation.z, 0, 0, 0, 1 )
end
