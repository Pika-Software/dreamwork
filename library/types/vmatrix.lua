---@meta _

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
---@class VMatrix : Object
---@field __class VMatrixClass
---@operator add( VMatrix ): VMatrix
---@operator sub( VMatrix ): VMatrix
---@operator mul( Vector3 ): Vector3
---@operator mul( VMatrix ): VMatrix
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
local __VMatrix = {}

--- [SHARED AND MENU]
---
--- The class used to create new `VMatrix` instances.
---
--- ```lua
--- local identity = VMatrix() -- like `Matrix()` in Garry's Mod
--- local transform = VMatrix.fromAngle3( Angle3( 0, 90, 0 ), Vector3( 0, 0, 64 ) )
--- ```
---
---@class VMatrixClass : VMatrix
---@field __base VMatrix
---@overload fun( ...: number? ): VMatrix
VMatrix = {}

---@param value any
---@return boolean is_vmatrix
---@nodiscard
function isVMatrix(value) end

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
---@return VMatrix matrix The new matrix.
---@protected
function VMatrix:__new(m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44) end

--- Debug representation, the address and all rows with 2 decimals.
---
---@return string str The debug representation.
---@protected
function __VMatrix:__represent() end

--- String conversion, four rows separated by new lines, e.g. `1.000000 0.000000 0.000000 0.000000\n...`.
---
---@return string str The string representation.
---@protected
function __VMatrix:__tostring() end

--- Exact component-wise comparison, comparing with a non-matrix value returns `false`.
---
---@param other any The value to compare with.
---@return boolean is_equal `true` if both are matrices with equal values.
---@protected
function __VMatrix:__eq(other) end

--- [SHARED AND MENU]
---
--- Returns all 16 values of the matrix ( row by row ).
---
---@return number m11, number m12, number m13, number m14, number m21, number m22, number m23, number m24, number m31, number m32, number m33, number m34, number m41, number m42, number m43, number m44
---@nodiscard
function __VMatrix.unpack(self) end

--- [SHARED AND MENU]
---
--- Sets all 16 values of the matrix ( row by row ).
---
---@return VMatrix matrix The same matrix.
function __VMatrix.setUnpacked(self, m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44) end

--- [SHARED AND MENU]
---
--- Copies the values of another matrix into this matrix.
---
---@param matrix VMatrix The matrix to copy from.
---@return VMatrix matrix The same matrix.
function __VMatrix:set(matrix) end

--- [SHARED AND MENU]
---
--- Creates a new independent copy of the matrix.
---
---@param self VMatrix The matrix.
---@return VMatrix copy The new matrix.
---@nodiscard
function __VMatrix.copy(self) end

--- [SHARED AND MENU]
---
--- Creates a new independent copy of the matrix.
---
---@param self VMatrix The matrix.
---@return VMatrix copy The new matrix.
---@nodiscard
function __VMatrix.clone(self) end

--- [SHARED AND MENU]
---
--- Sets the matrix to identity ( no rotation, no translation, scale `1` ).
---
---@return VMatrix matrix The same matrix.
function __VMatrix:identity() end

--- [SHARED AND MENU]
---
--- Checks if the matrix is exactly identity.
---
---@return boolean is_identity `true` if the matrix is identity, `false` otherwise.
---@nodiscard
function __VMatrix:isIdentity() end

--- [SHARED AND MENU]
---
--- Sets all values of the matrix to zero.
---
---@return VMatrix matrix The same matrix.
function __VMatrix:zero() end

--- [SHARED AND MENU]
---
--- Checks if all values of the matrix are exactly zero.
---
---@return boolean is_zero `true` if the matrix is zero, `false` otherwise.
---@nodiscard
function __VMatrix:isZero() end

--- [SHARED AND MENU]
---
--- Checks if the matrix is equal to the given matrix with the given tolerance.
---
--- Each of the 16 values is compared separately.
---
---@param matrix VMatrix The matrix to check.
---@param tolerance number The maximum allowed difference per value.
---@return boolean is_near `true` if the matrices are equal within the tolerance, otherwise `false`.
---@nodiscard
function __VMatrix:isNear(matrix, tolerance) end

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
---@nodiscard
function __VMatrix:getField(row, column) end

--- [SHARED AND MENU]
---
--- Sets the value of the matrix at the given row and column.
---
--- Same as `VMatrix:SetField` in Garry's Mod, out of range indices are clamped to [1, 4].
---
---@param row integer The row, from 1 to 4.
---@param column integer The column, from 1 to 4.
---@param value number The value.
---@return VMatrix matrix The same matrix.
function __VMatrix:setField(row, column, value) end

--- [SHARED AND MENU]
---
--- Multiplies the matrix by another matrix ( `self = self * matrix` ).
---
--- Same as `VMatrix:Mul` in Garry's Mod, `matrix` is applied before the current transform.
---
---@param matrix VMatrix The other matrix.
---@return VMatrix matrix The same matrix, with the product.
function __VMatrix:mul(matrix) end

--- [SHARED AND MENU]
---
--- Multiplies another matrix by the matrix ( `self = matrix * self` ).
---
--- `matrix` is applied after the current transform.
---
---@param matrix VMatrix The other matrix.
---@return VMatrix matrix The same matrix, with the product.
function __VMatrix:premul(matrix) end

--- [SHARED AND MENU]
---
--- Transforms the point by the matrix ( rotation, scale and translation ), same as `matrix * vec3`.
---
--- The fourth row is ignored ( no perspective divide ).
---
---@param self VMatrix The matrix.
---@param vector Vector3 The point.
---@return Vector3 vec3 The new transformed point.
---@nodiscard
function __VMatrix.transformPoint(self, vector) end

--- [SHARED AND MENU]
---
--- Transforms the direction by the matrix ( rotation and scale, without translation ).
---
--- The result is not normalized if the matrix has scale.
---
---@param vector Vector3 The direction.
---@return Vector3 vec3 The new transformed direction.
---@nodiscard
function __VMatrix:transformDirection(vector) end

--- `matrix * matrix` ( matrix product ) and `matrix * vec3` ( transforms the point ).
---
---@param a VMatrix
---@param b VMatrix | Vector3
---@return VMatrix | Vector3 product The new matrix, or the new vector for `matrix * vec3`.
---@nodiscard
---@protected
function __VMatrix.__mul(a, b) end

--- `matrix + matrix` ( component-wise ).
---
---@param a VMatrix
---@param b VMatrix
---@return VMatrix sum The new matrix.
---@protected
function __VMatrix.__add(a, b) end

--- `matrix - matrix` ( component-wise ).
---
---@param a VMatrix
---@param b VMatrix
---@return VMatrix difference The new matrix.
---@protected
function __VMatrix.__sub(a, b) end

--- [SHARED AND MENU]
---
--- Transposes the matrix ( swaps rows and columns ).
---
--- For pure rotation matrices the transpose is the inverse.
---
---@param self VMatrix The matrix.
---@return VMatrix matrix The same matrix, transposed.
function __VMatrix.transpose(self) end

--- [SHARED AND MENU]
---
--- Returns a transposed copy of the matrix.
---
---@return VMatrix transposed_matrix The new matrix.
---@nodiscard
function __VMatrix:getTransposed() end

--- [SHARED AND MENU]
---
--- Calculates the determinant of the matrix.
---
--- `1` for rotation matrices, `0` for singular ( non-invertible ) matrices, negative if the matrix mirrors.
---
---@return number determinant The determinant.
---@nodiscard
function __VMatrix:getDeterminant() end

--- [SHARED AND MENU]
---
--- Inverts the matrix ( full 4x4 inverse ).
---
--- Same as `VMatrix:Invert` in Garry's Mod, the matrix stays unchanged if it can't be inverted.
---
--- Use `invertTR` for rotation + translation matrices, it is faster and always succeeds.
---
---@param self VMatrix The matrix.
---@return boolean success `true` if the matrix was inverted, `false` if the matrix is singular.
function __VMatrix.invert(self) end

--- [SHARED AND MENU]
---
--- Returns the inverse of the matrix ( full 4x4 inverse ).
---
--- Same as `VMatrix:GetInverse` in Garry's Mod.
---
---@return VMatrix | nil inverted_matrix The new matrix, or `nil` if the matrix is singular.
---@nodiscard
function __VMatrix:getInverse() end

--- [SHARED AND MENU]
---
--- Inverts the matrix, assuming it only contains rotation and translation ( no scale ).
---
--- Same as `VMatrix:InvertTR` in Garry's Mod, much faster than `invert`,
--- but the result is wrong for scaled or skewed matrices. The fourth row is reset to `0 0 0 1`.
---
---@param self VMatrix The matrix.
---@return VMatrix matrix The same matrix, inverted.
function __VMatrix.invertTR(self) end

--- [SHARED AND MENU]
---
--- Returns the inverse of the matrix, assuming it only contains rotation and translation ( no scale ).
---
--- Same as `VMatrix:GetInverseTR` in Garry's Mod.
---
---@return VMatrix inverted_matrix The new matrix.
---@nodiscard
function __VMatrix:getInverseTR() end

--- [SHARED AND MENU]
---
--- Returns the forward direction of the matrix ( first column ).
---
--- Same as `VMatrix:GetForward` in Garry's Mod, not normalized if the matrix has scale.
---
---@return Vector3 forward_dir The new vector.
---@nodiscard
function __VMatrix:getForward() end

--- [SHARED AND MENU]
---
--- Sets the forward direction of the matrix ( first column ).
---
--- Same as `VMatrix:SetForward` in Garry's Mod.
---
---@param vector Vector3 The forward direction.
---@return VMatrix matrix The same matrix.
function __VMatrix:setForward(vector) end

--- [SHARED AND MENU]
---
--- Returns the left direction of the matrix ( second column ).
---
---@return Vector3 left_dir The new vector.
---@nodiscard
function __VMatrix:getLeft() end

--- [SHARED AND MENU]
---
--- Sets the left direction of the matrix ( second column ).
---
---@param vector Vector3 The left direction.
---@return VMatrix matrix The same matrix.
function __VMatrix:setLeft(vector) end

--- [SHARED AND MENU]
---
--- Returns the right direction of the matrix ( negated second column ).
---
--- Same as `VMatrix:GetRight` in Garry's Mod.
---
---@return Vector3 right_dir The new vector.
---@nodiscard
function __VMatrix:getRight() end

--- [SHARED AND MENU]
---
--- Sets the right direction of the matrix ( stored negated in the second column ).
---
--- Same as `VMatrix:SetRight` in Garry's Mod.
---
---@param vector Vector3 The right direction.
---@return VMatrix matrix The same matrix.
function __VMatrix:setRight(vector) end

--- [SHARED AND MENU]
---
--- Returns the up direction of the matrix ( third column ).
---
--- Same as `VMatrix:GetUp` in Garry's Mod.
---
---@return Vector3 up_dir The new vector.
---@nodiscard
function __VMatrix:getUp() end

--- [SHARED AND MENU]
---
--- Sets the up direction of the matrix ( third column ).
---
--- Same as `VMatrix:SetUp` in Garry's Mod.
---
---@param vector Vector3 The up direction.
---@return VMatrix matrix The same matrix.
function __VMatrix:setUp(vector) end

--- [SHARED AND MENU]
---
--- Returns the translation of the matrix ( fourth column ).
---
--- Same as `VMatrix:GetTranslation` in Garry's Mod.
---
---@return Vector3 translation The new vector.
---@nodiscard
function __VMatrix:getTranslation() end

--- [SHARED AND MENU]
---
--- Sets the translation of the matrix ( fourth column ), rotation and scale stay unchanged.
---
--- Same as `VMatrix:SetTranslation` in Garry's Mod.
---
---@param vector Vector3 The translation.
---@return VMatrix matrix The same matrix.
function __VMatrix:setTranslation(vector) end

--- [SHARED AND MENU]
---
--- Translates the matrix by the given vector in local space ( `self = self * T` ).
---
--- Same as `VMatrix:Translate` in Garry's Mod, the offset is rotated and scaled by the matrix,
--- use `setTranslation` to move in world space.
---
---@param vector Vector3 The local offset.
---@return VMatrix matrix The same matrix, translated.
function __VMatrix:translate(vector) end

--- [SHARED AND MENU]
---
--- Scales the translation of the matrix by the given number.
---
--- Same as `VMatrix:ScaleTranslation` in Garry's Mod.
---
---@param scale number The scale factor.
---@return VMatrix matrix The same matrix.
function __VMatrix:scaleTranslation(scale) end

--- [SHARED AND MENU]
---
--- Returns the unpacked Euler angles ( pitch, yaw, roll ) of the matrix in degrees.
---
--- Same as `MatrixAngles` in Source engine, allocation free alternative to `getAngles`.
---
--- Assumes the matrix has no scale, at pitch `±90` ( gimbal lock ) roll is always `0`.
---
---@param self VMatrix The matrix.
---@return number pitch The pitch in degrees.
---@return number yaw The yaw in degrees.
---@return number roll The roll in degrees.
---@nodiscard
function __VMatrix.unpackAngles(self) end

--- [SHARED AND MENU]
---
--- Returns the rotation of the matrix as an angle.
---
--- Same as `VMatrix:GetAngles` in Garry's Mod, values are in range [-180, 180].
---
---@return Angle3 ang3 The new angle.
---@nodiscard
function __VMatrix:getAngles() end

--- [SHARED AND MENU]
---
--- Sets the rotation of the matrix from the angle, translation and the fourth row stay unchanged.
---
--- Same as `VMatrix:SetAngles` in Garry's Mod, any existing scale is lost.
---
---@param angle Angle3 The angle.
---@return VMatrix matrix The same matrix.
function __VMatrix:setAngles(angle) end

--- [SHARED AND MENU]
---
--- Rotates the matrix by the given angle in local space ( `self = self * R` ).
---
--- Same as `VMatrix:Rotate` in Garry's Mod, translation stays unchanged.
---
---@param angle Angle3 The angle.
---@return VMatrix matrix The same matrix, rotated.
function __VMatrix:rotate(angle) end

--- [SHARED AND MENU]
---
--- Scales the matrix by the given vector in local space ( `self = self * S` ).
---
--- Same as `VMatrix:Scale` in Garry's Mod, multiplies the forward, left and up columns, translation stays unchanged.
---
---@param vector Vector3 The scale per axis.
---@return VMatrix matrix The same matrix, scaled.
function __VMatrix:scale(vector) end

--- [SHARED AND MENU]
---
--- Returns the scale of the matrix ( lengths of the forward, left and up columns ).
---
--- Always positive, mirroring is not detected ( check `getDeterminant` for that ).
---
---@return Vector3 scale The new vector.
---@nodiscard
function __VMatrix:getScale() end

--- [SHARED AND MENU]
---
--- Sets the scale of the matrix while preserving the rotation and translation.
---
--- Columns with zero length stay zero, since their direction is unknown.
---
---@param vector Vector3 The new scale per axis.
---@return VMatrix matrix The same matrix.
function __VMatrix:setScale(vector) end

--- [SHARED AND MENU]
---
--- Checks if the matrix is a rotation matrix ( forward, left and up columns are normalized and perpendicular ).
---
--- Same as `VMatrix:IsRotationMatrix` in Garry's Mod, translation is ignored.
---
---@param tolerance? number The tolerance, defaults to `1e-3`.
---@return boolean is_rotation_matrix `true` if the matrix is a rotation matrix, `false` otherwise.
---@nodiscard
function __VMatrix:isRotationMatrix(tolerance) end

--- [SHARED AND MENU]
---
--- Returns the rotation of the matrix as a quaternion, scale and translation are ignored.
---
---@return Quaternion quat The new unit quaternion.
---@nodiscard
function __VMatrix:toQuaternion() end

--- [SHARED AND MENU]
---
--- Interpolates the matrix to the target matrix.
---
--- Rotation is interpolated with quaternion slerp ( shortest path ), scale, translation and the fourth row linearly.
---
---@param t number The interpolation factor for translation, scale and the fourth row, `0` keeps the matrix, `1` sets it to the target.
---@param target VMatrix The target matrix.
---@param t_angle? number The interpolation factor for rotation, defaults to `t`.
---@return VMatrix matrix The same matrix, interpolated.
function __VMatrix:lerp(t, target, t_angle) end

--- [SHARED AND MENU]
---
--- Creates a new rotation matrix from the angle and the optional translation.
---
--- Same as `AngleMatrix` in Source engine.
---
---@param angle Angle3 The angle.
---@param translation? Vector3 The translation, defaults to `( 0, 0, 0 )`.
---@return VMatrix matrix The new matrix.
---@nodiscard
function VMatrix.fromAngle3(angle, translation) end

--- [SHARED AND MENU]
---
--- Creates a new rotation matrix from the quaternion and the optional translation.
---
--- Same as `QuaternionMatrix` in Source engine, works with non-unit quaternions.
---
---@param quaternion Quaternion The quaternion.
---@param translation? Vector3 The translation, defaults to `( 0, 0, 0 )`.
---@return VMatrix matrix The new matrix.
---@nodiscard
function VMatrix.fromQuaternion(quaternion, translation) end
