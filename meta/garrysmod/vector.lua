---@meta garrysmod.vector


--- Creates a new Vector.
---
--- If called without arguments the vector is `(0, 0, 0)`, otherwise it is built from components, a copy of another vector, or a string such as `"1 2 3"`.
---
---@param x number | string | garrysmod.Vector | nil The X component, a string to parse, or a vector to copy.
---@param y number? The Y component.
---@param z number? The Z component.
---@return garrysmod.Vector vector The new vector.
function Vector( x, y, z ) end

--- Linearly interpolates between two vectors.
---
---@param fraction number The interpolation fraction, `0` gives `from` and `1` gives `to`.
---@param from garrysmod.Vector The start vector.
---@param to garrysmod.Vector The end vector.
---@return garrysmod.Vector result The interpolated vector.
function LerpVector( fraction, from, to ) end

--- Sorts the components of two vectors so that the first has the smallest values and the second the largest, in place.
---
---@param first garrysmod.Vector The first vector.
---@param second garrysmod.Vector The second vector.
function OrderVectors( first, second ) end

--- Converts a position and angle from local space to world space, relative to an origin.
---
---@param local_pos garrysmod.Vector The local position.
---@param local_angles garrysmod.Angle The local angles.
---@param origin_pos garrysmod.Vector The world origin position.
---@param origin_angles garrysmod.Angle The world origin angles.
---@return garrysmod.Vector position The world position.
---@return garrysmod.Angle angles The world angles.
function LocalToWorld( local_pos, local_angles, origin_pos, origin_angles ) end

--- Converts a position and angle from world space to local space, relative to an origin.
---
---@param world_pos garrysmod.Vector The world position.
---@param world_angles garrysmod.Angle The world angles.
---@param origin_pos garrysmod.Vector The world origin position.
---@param origin_angles garrysmod.Angle The world origin angles.
---@return garrysmod.Vector position The local position.
---@return garrysmod.Angle angles The local angles.
function WorldToLocal( world_pos, world_angles, origin_pos, origin_angles ) end

---@class garrysmod.Vector : metatable
---@field x number The X component.
---@field y number The Y component.
---@field z number The Z component.
---@field [1] number Alias of `x`.
---@field [2] number Alias of `y`.
---@field [3] number Alias of `z`.
---@operator add( garrysmod.Vector ): garrysmod.Vector
---@operator sub( garrysmod.Vector ): garrysmod.Vector
---@operator mul( number ): garrysmod.Vector
---@operator mul( garrysmod.Vector ): garrysmod.Vector
---@operator mul( garrysmod.VMatrix ): garrysmod.Vector
---@operator div( number ): garrysmod.Vector
---@operator unm: garrysmod.Vector
local Vector = {}

--- Adds the specified vector to this vector, in place.
---
---@param other garrysmod.Vector The vector to add.
function Vector:Add( other ) end

--- Returns the angle (direction) of the vector, with roll set to `0`.
---
---@return garrysmod.Angle angles The angle of the vector.
function Vector:Angle() end

--- Returns the angle of the vector, using the given up vector to determine the roll.
---
---@param up garrysmod.Vector The up direction.
---@return garrysmod.Angle angles The angle of the vector.
function Vector:AngleEx( up ) end

--- Returns the cross product of this vector and the given vector.
---
---@param other garrysmod.Vector The other vector.
---@return garrysmod.Vector cross The cross product.
function Vector:Cross( other ) end

--- Returns the distance between this vector and the given vector.
---
---@param other garrysmod.Vector The other vector.
---@return number distance The distance.
function Vector:Distance( other ) end

--- Returns the squared distance between this vector and the given vector, faster than [Vector:Distance](https://wiki.facepunch.com/gmod/Vector:Distance).
---
---@param other garrysmod.Vector The other vector.
---@return number distance_sqr The squared distance.
function Vector:DistToSqr( other ) end

--- Divides this vector by the given number, in place.
---
---@param divisor number The number to divide by.
function Vector:Div( divisor ) end

--- Returns the dot product of this vector and the given vector.
---
---@param other garrysmod.Vector The other vector.
---@return number dot The dot product.
function Vector:Dot( other ) end

--- Alias of [Vector:Dot](https://wiki.facepunch.com/gmod/Vector:Dot).
---
---@param other garrysmod.Vector The other vector.
---@return number dot The dot product.
function Vector:DotProduct( other ) end

--- Returns a negated copy of the vector.
---
---@return garrysmod.Vector negated The negated vector.
function Vector:GetNegated() end

--- Returns a normalized copy of the vector.
---
---@return garrysmod.Vector normalized The normalized vector.
function Vector:GetNormal() end

--- Alias of [Vector:GetNormal](https://wiki.facepunch.com/gmod/Vector:GetNormal).
---
---@return garrysmod.Vector normalized The normalized vector.
function Vector:GetNormalized() end

--- Returns whether the vector is equal to the given vector within a tolerance.
---
---@param other garrysmod.Vector The other vector.
---@param tolerance number The maximum per-component difference.
---@return boolean is_equal `true` if the vectors are equal within the tolerance.
function Vector:IsEqualTol( other, tolerance ) end

--- Returns whether all components of the vector are zero.
---
---@return boolean is_zero `true` if the vector is zero.
function Vector:IsZero() end

--- Returns the length of the vector.
---
---@return number length The length.
function Vector:Length() end

--- Returns the length of the vector ignoring the Z component.
---
---@return number length The 2D length.
function Vector:Length2D() end

--- Returns the squared length of the vector ignoring the Z component.
---
---@return number length_sqr The squared 2D length.
function Vector:Length2DSqr() end

--- Returns the squared length of the vector, faster than [Vector:Length](https://wiki.facepunch.com/gmod/Vector:Length).
---
---@return number length_sqr The squared length.
function Vector:LengthSqr() end

--- Multiplies this vector by the given number, in place.
---
---@param scalar number The number to multiply by.
function Vector:Mul( scalar ) end

--- Normalizes the vector in place.
function Vector:Normalize() end

--- Sets each component of the vector to a random value in the given range.
---
---@param min number? The minimum value, `-1` by default.
---@param max number? The maximum value, `1` by default.
function Vector:Random( min, max ) end

--- Rotates the vector by the given angle, in place.
---
---@param rotation garrysmod.Angle The rotation to apply.
function Vector:Rotate( rotation ) end

--- Copies the components of the given vector into this vector.
---
---@param source garrysmod.Vector The vector to copy.
function Vector:Set( source ) end

--- Sets the components of the vector.
---
---@param x number The new X component.
---@param y number The new Y component.
---@param z number The new Z component.
function Vector:SetUnpacked( x, y, z ) end

--- Subtracts the specified vector from this vector, in place.
---
---@param other garrysmod.Vector The vector to subtract.
function Vector:Sub( other ) end

--- Converts the vector to a [Color](https://wiki.facepunch.com/gmod/Color), with components in the range `0` to `1` mapped to `0` to `255`.
---
---@return garrysmod.Color color The resulting color.
function Vector:ToColor() end

--- [CLIENT AND MENU]
---
--- Converts the vector from world space to screen coordinates, must be called in a 3D rendering context.
---
---@return { x: number, y: number, visible: boolean } data The screen position and whether the point is on screen.
function Vector:ToScreen() end

--- Returns the components of the vector.
---
---@return number x The X component.
---@return number y The Y component.
---@return number z The Z component.
function Vector:Unpack() end

--- Returns whether the vector is inside the axis-aligned box defined by the given corners.
---
---@param mins garrysmod.Vector The minimum corner of the box.
---@param maxs garrysmod.Vector The maximum corner of the box.
---@return boolean inside `true` if the vector is within the box.
function Vector:WithinAABox( mins, maxs ) end

--- Sets all components of the vector to zero.
function Vector:Zero() end
