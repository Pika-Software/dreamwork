---@meta garrysmod.vmatrix


---@class garrysmod.VMatrix : metatable
---@operator add( garrysmod.VMatrix ): garrysmod.VMatrix
---@operator sub( garrysmod.VMatrix ): garrysmod.VMatrix
---@operator mul( garrysmod.VMatrix ): garrysmod.VMatrix
---@operator mul( garrysmod.Vector ): garrysmod.Vector
local VMatrix = {}

--- Adds the specified matrix to this matrix, component-wise.
---
---@param other garrysmod.VMatrix The matrix to add.
function VMatrix:Add( other ) end

--- Returns the rotation of the matrix as an angle.
---
---@return garrysmod.Angle angles The rotation of the matrix.
function VMatrix:GetAngles() end

--- Returns the number at the specified row and column.
---
---@param row integer The row, from 1 to 4.
---@param column integer The column, from 1 to 4.
---@return number value The number at the specified position.
function VMatrix:GetField( row, column ) end

--- Returns the forward direction of the matrix (first column).
---
---@return garrysmod.Vector forward The forward direction.
function VMatrix:GetForward() end

--- Returns the inverse of the matrix.
---
---@return garrysmod.VMatrix? inverse The inverse matrix, or `nil` if the matrix is not invertible.
function VMatrix:GetInverse() end

--- Returns the inverse of a matrix that only contains translation and rotation, faster than [VMatrix:GetInverse](https://wiki.facepunch.com/gmod/VMatrix:GetInverse).
---
---@return garrysmod.VMatrix? inverse The inverse matrix, or `nil` on failure.
function VMatrix:GetInverseTR() end

--- Returns the right direction of the matrix (negated second column).
---
---@return garrysmod.Vector right The right direction.
function VMatrix:GetRight() end

--- Returns the scale of the matrix.
---
---@return garrysmod.Vector scale The scale of the matrix.
function VMatrix:GetScale() end

--- Returns the translation (position) of the matrix.
---
---@return garrysmod.Vector translation The translation of the matrix.
function VMatrix:GetTranslation() end

--- Returns the up direction of the matrix (third column).
---
---@return garrysmod.Vector up The up direction.
function VMatrix:GetUp() end

--- Turns the matrix into the identity matrix.
function VMatrix:Identity() end

--- Inverts the matrix in place.
---
---@return boolean success `true` on success.
function VMatrix:Invert() end

--- Inverts in place a matrix that only contains translation and rotation, faster than [VMatrix:Invert](https://wiki.facepunch.com/gmod/VMatrix:Invert).
function VMatrix:InvertTR() end

--- Returns whether the matrix is the identity matrix.
---
---@return boolean is_identity `true` if the matrix is the identity matrix.
function VMatrix:IsIdentity() end

--- Returns whether the matrix is a pure rotation matrix.
---
---@return boolean is_rotation `true` if the matrix is a rotation matrix.
function VMatrix:IsRotationMatrix() end

--- Rotates the matrix by the given angle.
---
---@param rotation garrysmod.Angle The rotation to apply.
function VMatrix:Rotate( rotation ) end

--- Scales the matrix by the given vector.
---
---@param scale garrysmod.Vector The scale to apply.
function VMatrix:Scale( scale ) end

--- Scales the translation part of the matrix by the given number.
---
---@param scale number The scale factor.
function VMatrix:ScaleTranslation( scale ) end

--- Copies the values of the given matrix into this matrix.
---
---@param source garrysmod.VMatrix The matrix to copy.
function VMatrix:Set( source ) end

--- Sets the rotation of the matrix.
---
---@param angles garrysmod.Angle The new rotation.
function VMatrix:SetAngles( angles ) end

--- Sets the number at the specified row and column.
---
---@param row integer The row, from 1 to 4.
---@param column integer The column, from 1 to 4.
---@param value number The new value.
function VMatrix:SetField( row, column, value ) end

--- Sets the forward direction of the matrix (first column).
---
---@param forward garrysmod.Vector The new forward direction.
function VMatrix:SetForward( forward ) end

--- Sets the right direction of the matrix (negated second column).
---
---@param right garrysmod.Vector The new right direction.
function VMatrix:SetRight( right ) end

--- Sets the scale of the matrix.
---
---@param scale garrysmod.Vector The new scale.
function VMatrix:SetScale( scale ) end

--- Sets the translation (position) of the matrix.
---
---@param translation garrysmod.Vector The new translation.
function VMatrix:SetTranslation( translation ) end

--- Sets the up direction of the matrix (third column).
---
---@param up garrysmod.Vector The new up direction.
function VMatrix:SetUp( up ) end

--- Subtracts the specified matrix from this matrix, component-wise.
---
---@param other garrysmod.VMatrix The matrix to subtract.
function VMatrix:Sub( other ) end

--- Returns the matrix as a 4x4 table of rows.
---
---@return number[][] rows The rows of the matrix.
function VMatrix:ToTable() end

--- Translates the matrix by the given vector.
---
---@param translation garrysmod.Vector The translation to apply.
function VMatrix:Translate( translation ) end

--- Sets all components of the matrix to zero.
function VMatrix:Zero() end


--- [SHARED AND MENU]
---
--- Creates a new VMatrix.
---
--- If `data` is omitted the matrix is the identity matrix, otherwise it is a copy of the given VMatrix or is built from a 4x4 table of rows.
---
---@param data garrysmod.VMatrix | number[][] | nil The matrix to copy, or a 4x4 table of rows.
---@return garrysmod.VMatrix matrix The new matrix.
function Matrix( data ) end
