---@meta garrysmod.angle


--- Creates a new Angle.
---
--- If called without arguments the angle is `(0, 0, 0)`, otherwise it is built from components, a copy of another angle, or a string such as `"1 2 3"`.
---
---@param pitch number | string | garrysmod.Angle | nil The pitch, a string to parse, or an angle to copy.
---@param yaw number? The yaw.
---@param roll number? The roll.
---@return garrysmod.Angle angle The new angle.
function Angle( pitch, yaw, roll ) end

--- Linearly interpolates between two angles, taking the shortest path.
---
---@param fraction number The interpolation fraction, `0` gives `from` and `1` gives `to`.
---@param from garrysmod.Angle The start angle.
---@param to garrysmod.Angle The end angle.
---@return garrysmod.Angle result The interpolated angle.
function LerpAngle( fraction, from, to ) end

--- Returns an angle with random components in the given range.
---
---@param min number? The minimum value, `-90` by default.
---@param max number? The maximum value, `90` by default.
---@return garrysmod.Angle angle A random angle.
function AngleRand( min, max ) end

---@class garrysmod.Angle : metatable
---@field p number The pitch component.
---@field y number The yaw component.
---@field r number The roll component.
---@field pitch number Alias of `p`.
---@field yaw number Alias of `y`.
---@field roll number Alias of `r`.
---@field [1] number Alias of `p`.
---@field [2] number Alias of `y`.
---@field [3] number Alias of `r`.
---@operator add( garrysmod.Angle ): garrysmod.Angle
---@operator sub( garrysmod.Angle ): garrysmod.Angle
---@operator mul( number ): garrysmod.Angle
---@operator div( number ): garrysmod.Angle
---@operator unm: garrysmod.Angle
local Angle = {}

--- Adds the specified angle to this angle, in place.
---
---@param other garrysmod.Angle The angle to add.
function Angle:Add( other ) end

--- Returns the forward direction of the angle.
---
---@return garrysmod.Vector forward The forward vector.
function Angle:Forward() end

--- Returns whether the angle is equal to the given angle within a tolerance.
---
---@param other garrysmod.Angle The other angle.
---@param tolerance number The maximum per-component difference.
---@return boolean is_equal `true` if the angles are equal within the tolerance.
function Angle:IsEqualTol( other, tolerance ) end

--- Returns whether all components of the angle are zero.
---
---@return boolean is_zero `true` if the angle is zero.
function Angle:IsZero() end

--- Multiplies this angle by the given number, in place.
---
---@param scalar number The number to multiply by.
function Angle:Mul( scalar ) end

--- Normalizes the angle in place, wrapping each component into the range `-180` to `180`.
function Angle:Normalize() end

--- Sets each component of the angle to a random value in the given range.
---
---@param min number? The minimum value, `-90` by default.
---@param max number? The maximum value, `90` by default.
function Angle:Random( min, max ) end

--- Returns the right direction of the angle.
---
---@return garrysmod.Vector right The right vector.
function Angle:Right() end

--- Rotates the angle around the given axis, in place.
---
---@param axis garrysmod.Vector The axis to rotate around.
---@param rotation number The rotation in degrees.
function Angle:RotateAroundAxis( axis, rotation ) end

--- Copies the components of the given angle into this angle.
---
---@param source garrysmod.Angle The angle to copy.
function Angle:Set( source ) end

--- Sets the components of the angle.
---
---@param pitch number The new pitch.
---@param yaw number The new yaw.
---@param roll number The new roll.
function Angle:SetUnpacked( pitch, yaw, roll ) end

--- Snaps the given component to the nearest multiple of the given number, in place.
---
---@param component string The component to snap: `"p"`, `"y"` or `"r"`.
---@param step number The step to snap to.
---@return garrysmod.Angle self The same angle.
function Angle:SnapTo( component, step ) end

--- Subtracts the specified angle from this angle, in place.
---
---@param other garrysmod.Angle The angle to subtract.
function Angle:Sub( other ) end

--- Returns the components of the angle.
---
---@return number pitch The pitch.
---@return number yaw The yaw.
---@return number roll The roll.
function Angle:Unpack() end

--- Returns the up direction of the angle.
---
---@return garrysmod.Vector up The up vector.
function Angle:Up() end

--- Sets all components of the angle to zero.
function Angle:Zero() end
