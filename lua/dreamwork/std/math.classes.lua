--[[

    TODO:

    https://wiki.facepunch.com/gmod/gui.ScreenToVector ( Vector.FromScreen(X,Y) )

    https://wiki.facepunch.com/gmod/util.AimVector

    https://wiki.facepunch.com/gmod/Global.LocalToWorld
    https://wiki.facepunch.com/gmod/Global.WorldToLocal

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


    https://wiki.facepunch.com/gmod/gui.ScreenToVector
    https://wiki.facepunch.com/gmod/Vector:ToScreen

]]

local _G = _G
local dreamwork = _G.dreamwork

---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_index = raw.index
local raw_get, raw_set = raw.get, raw.set

local class = std.class

local isNumber = std.isNumber
local setmetatable = std.setmetatable

local math = std.math
local math_abs = math.abs
local math_sqrt = math.sqrt
local math_lerp = math.lerp
local math_huge = math.huge
local math_floor = math.floor
local math_toFloat32 = math.toFloat32
local math_min, math_max = math.min, math.max
local math_atan2, math_deg = math.atan2, math.deg
local math_cos, math_sin, math_rad = math.cos, math.sin, math.rad

local string_format = std.string.format
local table_concat = std.table.concat

--- [SHARED AND MENU]
---
--- A 2D vector object.
---
---@class dreamwork.std.Vector2 : dreamwork.Object
---@field __class dreamwork.std.Vector2Class
---@operator add( dreamwork.std.Vector2 | number ): dreamwork.std.Vector2
---@operator sub( dreamwork.std.Vector2 | number ): dreamwork.std.Vector2
---@operator mul( dreamwork.std.Vector2 | number ): dreamwork.std.Vector2
---@operator div( dreamwork.std.Vector2 | number ): dreamwork.std.Vector2
---@operator unm: dreamwork.std.Vector2
---@field x number
---@field y number
local Vector2 = class.base( "Vector2" )

---@alias Vector2 dreamwork.std.Vector2

--- [SHARED AND MENU]
---
--- A 2D vector class.
---
---@class dreamwork.std.Vector2Class: dreamwork.std.Vector2
---@field __base dreamwork.std.Vector2
---@overload fun( x: number, y: number ): dreamwork.std.Vector2
local Vector2Class = class.create( Vector2 )
Vector2Class.origin = setmetatable( { 0, 0 }, Vector2 )
std.Vector2 = Vector2Class

--- [SHARED AND MENU]
---
--- A 3D vector object.
---
---@alias Vector3 dreamwork.std.Vector3
---@class dreamwork.std.Vector3 : dreamwork.Object
---@field __class dreamwork.std.Vector3Class
---@operator add( dreamwork.std.Vector3 | number ): dreamwork.std.Vector3
---@operator sub( dreamwork.std.Vector3 | number ): dreamwork.std.Vector3
---@operator mul( dreamwork.std.Vector3 | number ): dreamwork.std.Vector3
---@operator div( dreamwork.std.Vector3 | number ): dreamwork.std.Vector3
---@operator unm: dreamwork.std.Vector3
---@field x number
---@field y number
---@field z number
local Vector3 = class.base( "Vector3" )

--- [SHARED AND MENU]
---
--- A 3D vector class.
---
---@class dreamwork.std.Vector3Class: dreamwork.std.Vector3
---@field __base dreamwork.std.Vector3
---@overload fun( x: number, y: number, z: number ): dreamwork.std.Vector3
local Vector3Class = class.create( Vector3 )
Vector3Class.origin = setmetatable( { 0, 0, 0 }, Vector3 )
std.Vector3 = Vector3Class

--- [SHARED AND MENU]
---
--- A 3D angle object.
---
---@class dreamwork.std.Angle3 : dreamwork.Object
---@field __class dreamwork.std.Angle3Class
---@operator add( dreamwork.std.Angle3 | number ): dreamwork.std.Angle3
---@operator sub( dreamwork.std.Angle3 | number ): dreamwork.std.Angle3
---@operator mul( dreamwork.std.Angle3 | number ): dreamwork.std.Angle3
---@operator div( dreamwork.std.Angle3 | number ): dreamwork.std.Angle3
---@operator unm: dreamwork.std.Angle3
---@field pitch number
---@field yaw number
---@field roll number
local Angle3 = class.base( "Angle3" )

---@alias Angle3 dreamwork.std.Angle3

--- [SHARED AND MENU]
---
--- A 3D angle class.
---
---@class dreamwork.std.Angle3Class : dreamwork.std.Angle3
---@field __base dreamwork.std.Angle3
---@overload fun( pitch: number?, yaw: number?, roll: number? ): Angle3
local Angle3Class = class.create( Angle3 )
Angle3Class.zero = setmetatable( { 0, 0, 0 }, Angle3 )
std.Angle = Angle3Class

--- [SHARED AND MENU]
---
--- A 4x4 matrix object.
---
---@class dreamwork.std.VMatrix : dreamwork.Object
---@field __class dreamwork.std.VMatrixClass
local VMatrix = class.base( "VMatrix" )

---@diagnostic disable-next-line: duplicate-doc-alias
---@alias VMatrix dreamwork.std.VMatrix

--- [SHARED AND MENU]
---
--- A 4x4 matrix class.
---
---@class dreamwork.std.VMatrixClass : dreamwork.std.VMatrix
---@field __base dreamwork.std.VMatrix
---@overload fun( ...: number? ): VMatrix
local VMatrixClass = class.create( VMatrix )
std.VMatrix = VMatrixClass

do

    local debug = std.debug

    debug.registermetatable( "Vector3", Vector3 )

    do

        local Vector = _G.Vector
        if Vector ~= nil then

            dreamwork.transducers[ Vector3 ] = function( vec3 )
                return Vector( vec3[ 1 ], vec3[ 2 ], vec3[ 3 ] )
            end

        end

    end

    do

        local VECTOR = debug.findmetatable( "Vector" )
        if VECTOR ~= nil then

            ---@cast VECTOR Vector
            local Unpack = VECTOR.Unpack

            dreamwork.transducers[ VECTOR ] = function( vector )
                return setmetatable( { Unpack( vector ) }, Vector3 )
            end

        end

    end

    debug.registermetatable( "Angle3", Angle3 )

    do

        local Angle = _G.Angle
        if Angle ~= nil then

            dreamwork.transducers[ Angle3 ] = function( angle3 )
                return Angle( angle3[ 1 ], angle3[ 2 ], angle3[ 3 ] )
            end

        end

    end

    do

        local ANGLE = debug.findmetatable( "Angle" )
        if ANGLE ~= nil then

            ---@cast ANGLE Angle
            local Unpack = ANGLE.Unpack

            dreamwork.transducers[ ANGLE ] = function( angle )
                return setmetatable( { Unpack( angle ) }, Angle3 )
            end

        end

    end

    debug.registermetatable( "VMatrix", VMatrix )

    do

        local Matrix = _G.Matrix
        if Matrix ~= nil then

            dreamwork.transducers[ VMatrix ] = function( matrix )
                return Matrix( {
                    { matrix[ 1 ], matrix[ 2 ], matrix[ 3 ], matrix[ 4 ] },
                    { matrix[ 5 ], matrix[ 6 ], matrix[ 7 ], matrix[ 8 ] },
                    { matrix[ 9 ], matrix[ 10 ], matrix[ 11 ], matrix[ 12 ] },
                    { matrix[ 13 ], matrix[ 14 ], matrix[ 15 ], matrix[ 16 ] }
                } )
            end

        end

    end

    do

        local VMATRIX = debug.findmetatable( "VMatrix" )
        if VMATRIX ~= nil then

            ---@cast VMATRIX VMatrix
            local Unpack = VMATRIX.Unpack

            dreamwork.transducers[ VMATRIX ] = function( matrix )
                return VMatrixClass( Unpack( matrix ) )
            end

        end

    end

    do

        local debug_getmetatable = debug.getmetatable

        --- [SHARED AND MENU]
        ---
        --- Returns `true` if the value is a `Vector3`.
        ---
        ---@param value any The value.
        ---@return boolean is_vector3 `true` if the value is a `Vector3`, `false` otherwise.
        function std.isvector3( value )
            return debug_getmetatable( value ) == Vector3
        end

        --- [SHARED AND MENU]
        ---
        --- Returns `true` if the value is an `Angle3`.
        ---
        ---@param value any The value.
        ---@return boolean is_angle3 `true` if the value is an `Angle3`, `false` otherwise.
        function std.isangle3( value )
            return debug_getmetatable( value ) == Angle3
        end

    end

end

do

    ---@protected
    ---@return string
    function Vector2:__tostring()
        return string_format( "Vector2: %p [%f, %f]", self, self[ 1 ], self[ 2 ] )
    end

    ---@protected
    ---@param x? number
    ---@param y? number
    function Vector2:__init( x, y )
        if x == nil then
            self[ 1 ] = 0
        else
            self[ 1 ] = math_toFloat32( x )
        end

        if y == nil then
            self[ 2 ] = 0
        else
            self[ 2 ] = math_toFloat32( y )
        end
    end

    ---@protected
    function Vector2:__index( key )
        if key == 1 or key == "x" then
            return raw_get( self, 1 )
        elseif key == 2 or key == "y" then
            return raw_get( self, 2 )
        else
            return raw_index( Vector2, key )
        end
    end

    ---@protected
    function Vector2:__newindex( key, value )
        if key == 1 or key == "x" then
            raw_set( self, 1, value )
        elseif key == 2 or key == "y" then
            raw_set( self, 2, value )
        end
    end

    ---@protected
    ---@param writer dreamwork.std.pack.Writer
    function Vector2:__serialize( writer )
        writer:writeFloat( self[ 1 ] )
        writer:writeFloat( self[ 2 ] )
    end

    ---@protected
    ---@param reader dreamwork.std.pack.Reader
    function Vector2:__deserialize( reader )
        self[ 1 ] = reader:readFloat()
        self[ 2 ] = reader:readFloat()
    end

    ---@protected
    ---@return string hash
    function Vector2:__tohash()
        return table_concat( self, "v", 1, 2 )
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the x and y coordinates of the vector.
    ---
    ---@return number x The x coordinate of the vector.
    ---@return number y The y coordinate of the vector.
    function Vector2:unpack()
        return self[ 1 ], self[ 2 ]
    end

    --- [SHARED AND MENU]
    ---
    --- Sets the x and y coordinates of the vector.
    ---
    ---@param x number The x coordinate of the vector.
    ---@param y number The y coordinate of the vector.
    function Vector2:setUnpacked( x, y )
        self[ 1 ] = math_toFloat32( x )
        self[ 2 ] = math_toFloat32( y )
    end

    --- [SHARED AND MENU]
    ---
    --- Creates a copy of the vector.
    ---
    ---@param self dreamwork.std.Vector2 The vector.
    ---@return dreamwork.std.Vector2 copy The copy of the vector.
    local function Vector2_copy( self )
        return setmetatable( { self[ 1 ], self[ 2 ] }, Vector2 )
    end

    Vector2.copy = Vector2_copy

    --- [SHARED AND MENU]
    ---
    --- Negates the vector.
    ---
    ---@return dreamwork.std.Vector2
    function Vector2:negate()
        self[ 1 ] = -self[ 1 ]
        self[ 2 ] = -self[ 2 ]
        return self
    end

    ---@protected
    function Vector2:__unm()
        return setmetatable( { -self[ 1 ], -self[ 2 ] }, Vector2 )
    end

    --- [SHARED AND MENU]
    ---
    --- Scales the vector.
    ---
    ---@param self dreamwork.std.Vector2 The vector to scale.
    ---@param scale number The scale factor.
    ---@return dreamwork.std.Vector2 vec2 The scaled vector.
    local function Vector2_scale( self, scale )
        if scale == 0 or scale ~= scale then
            self[ 1 ] = 0
            self[ 2 ] = 0
        elseif scale == math_huge then
            self[ 1 ] = math_huge
            self[ 2 ] = math_huge
        else
            self[ 1 ] = math_toFloat32( self[ 1 ] * scale )
            self[ 2 ] = math_toFloat32( self[ 2 ] * scale )
        end

        return self
    end

    Vector2.scale = Vector2_scale

    --- [SHARED AND MENU]
    ---
    --- Returns a scaled copy of the vector.
    ---
    ---@param scale number The scale factor.
    ---@return dreamwork.std.Vector2 vec2 The scaled copy of the vector.
    function Vector2:getScaled( scale )
        return Vector2_scale( Vector2_copy( self ), scale )
    end

    do

        --- [SHARED AND MENU]
        ---
        --- Adds the vector to another vector.
        ---
        ---@param self dreamwork.std.Vector2 The vector to add to.
        ---@param vector dreamwork.std.Vector2 The other vector.
        ---@return dreamwork.std.Vector2 vec2 The sum of the two vectors.
        local function Vector2_add( self, vector )
            self[ 1 ] = math_toFloat32( self[ 1 ] + vector[ 1 ] )
            self[ 2 ] = math_toFloat32( self[ 2 ] + vector[ 2 ] )
            return self
        end

        Vector2.add = Vector2_add

        ---@protected
        ---@param value dreamwork.std.Vector2 | number
        ---@return dreamwork.std.Vector2
        function Vector2:__add( value )
            if isNumber( value ) then
                ---@cast value number
                return setmetatable( {
                    math_toFloat32( self[ 1 ] + value ),
                    math_toFloat32( self[ 2 ] + value )
                }, Vector2 )
            else
                ---@cast value dreamwork.std.Vector2
                return Vector2_add( Vector2_copy( self ), value )
            end
        end

    end

    do

        --- [SHARED AND MENU]
        ---
        --- Subtracts the vector from another vector.
        ---
        ---@param self dreamwork.std.Vector2 The vector to subtract from.
        ---@param other dreamwork.std.Vector2 The other vector.
        ---@return dreamwork.std.Vector2 vec2 The difference of the two vectors.
        local function Vector2_subtract( self, other )
            self[ 1 ] = math_toFloat32( self[ 1 ] - other[ 1 ] )
            self[ 2 ] = math_toFloat32( self[ 2 ] - other[ 2 ] )
            return self
        end

        Vector2.subtract = Vector2_subtract

        ---@protected
        ---@param value dreamwork.std.Vector2 | number
        ---@return dreamwork.std.Vector2
        function Vector2:__sub( value )
            if isNumber( value ) then
                ---@cast value number
                return setmetatable( {
                    math_toFloat32( self[ 1 ] - value ),
                    math_toFloat32( self[ 2 ] - value )
                }, Vector2 )
            else
                ---@cast value dreamwork.std.Vector2
                return Vector2_subtract( Vector2_copy( self ), value )
            end
        end

    end

    do

        --- [SHARED AND MENU]
        ---
        --- Multiplies the vector by another vector or a number.
        ---
        ---@param self dreamwork.std.Vector2 The vector to multiply.
        ---@param vector dreamwork.std.Vector2 The other vector or a number.
        ---@return dreamwork.std.Vector2 multiplied_vector The product of the two vectors or the vector multiplied by a number.
        local function Vector2_multiply( self, vector )
            self[ 1 ] = math_toFloat32( self[ 1 ] * vector[ 1 ] )
            self[ 2 ] = math_toFloat32( self[ 2 ] * vector[ 2 ] )
            return self
        end

        Vector2.multiply = Vector2_multiply

        ---@protected
        ---@param value dreamwork.std.Vector2 | number
        ---@return dreamwork.std.Vector2
        function Vector2:__mul( value )
            if isNumber( value ) then
                ---@cast value number
                return Vector2_scale( Vector2_copy( self ), value )
            else
                ---@cast value dreamwork.std.Vector2
                return setmetatable( {
                    math_toFloat32( self[ 1 ] * value[ 1 ] ),
                    math_toFloat32( self[ 2 ] * value[ 2 ] )
                }, Vector2 )
            end
        end

    end

    do

        --- [SHARED AND MENU]
        ---
        --- Divides the vector by another vector or a number.
        ---
        ---@param self dreamwork.std.Vector2 The vector to divide.
        ---@param other dreamwork.std.Vector2 | number The other vector or a number.
        ---@return dreamwork.std.Vector2 vec2 The quotient of the two vectors or the vector divided by a number.
        local function Vector2_div( self, other )
            if isNumber( other ) then
                ---@cast other number
                return self:scale( 1 / other )
            else
                ---@cast other dreamwork.std.Vector2
                self[ 1 ] = math_toFloat32( self[ 1 ] / other[ 1 ] )
                self[ 2 ] = math_toFloat32( self[ 2 ] / other[ 2 ] )
            end

            return self
        end

        Vector2.div = Vector2_div

        ---@protected
        function Vector2:__div( other )
            return Vector2_div( Vector2_copy( self ), other )
        end

    end

    ---@protected
    function Vector2:__eq( vector )
        return self[ 1 ] == vector[ 1 ] and self[ 2 ] == vector[ 2 ]
    end

    --- [SHARED AND MENU]
    ---
    --- Calculates the distance between two vectors.
    ---
    ---@param vector dreamwork.std.Vector2 The other vector.
    ---@return number distance The distance between the two vectors.
    function Vector2:getDistance( vector )
        return ( math_sqrt( ( vector[ 1 ] - self[ 1 ] ) ^ 2 ) + ( vector[ 2 ] - self[ 2 ] ) ^ 2 )
    end

    do

        --- [SHARED AND MENU]
        ---
        --- Calculates the squared length of the vector.
        ---
        ---@param self dreamwork.std.Vector2 The vector to calculate the length of.
        ---@return number length The squared length of the vector.
        local function Vector2_getLengthSqr( self )
            return ( self[ 1 ] ^ 2 ) + ( self[ 2 ] ^ 2 )
        end

        Vector2.getLengthSqr = Vector2_getLengthSqr

        --- [SHARED AND MENU]
        ---
        --- Calculates the length of the vector.
        ---
        ---@param self dreamwork.std.Vector2 The vector to calculate the length of.
        ---@return number length The length of the vector.
        local function Vector2_getLength( self )
            return math_sqrt( Vector2_getLengthSqr( self ) )
        end

        Vector2.getLength = Vector2_getLength

        --- [SHARED AND MENU]
        ---
        --- Normalizes the vector.
        ---
        ---@param self dreamwork.std.Vector2 The vector to normalize.
        ---@return dreamwork.std.Vector2 vec2 The normalized vector.
        local function Vector2_normalize( self )
            local length = Vector2_getLength( self )
            if length == 0 then
                return self
            else
                return Vector2_scale( self, 1 / length )
            end
        end

        Vector2.normalize = Vector2_normalize

        --- [SHARED AND MENU]
        ---
        --- Returns a normalized copy of the vector.
        ---
        ---@return dreamwork.std.Vector2 normalized_vec2 The normalized copy of the vector.
        function Vector2:getNormalized()
            return Vector2_normalize( Vector2_copy( self ) )
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Checks if the vector is zero.
    ---
    ---@return boolean is_zero `true` if the vector is zero, `false` otherwise.
    function Vector2:isZero()
        return self[ 1 ] == 0 and self[ 2 ] == 0
    end

    --- [SHARED AND MENU]
    ---
    --- Sets the vector to zero.
    ---
    ---@return dreamwork.std.Vector2 vec2 The zero vector.
    function Vector2:zero()
        self[ 1 ] = 0
        self[ 2 ] = 0
        return self
    end

    --- [SHARED AND MENU]
    ---
    --- Calculates the dot product of two vectors.
    ---
    ---@param vector dreamwork.std.Vector2 The other vector.
    ---@return number dot_product The dot product of two vectors.
    function Vector2:dot( vector )
        return ( self[ 1 ] * vector[ 1 ] ) + ( self[ 2 ] * vector[ 2 ] )
    end

    --- [SHARED AND MENU]
    ---
    --- Calculates the cross product of two vectors.
    ---
    ---@param vector dreamwork.std.Vector2 The other vector.
    ---@return number cross_product The cross product of two vectors.
    function Vector2:cross( vector )
        return ( self[ 1 ] * vector[ 2 ] ) - ( self[ 2 ] * vector[ 1 ] )
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the angle of the vector.
    ---
    ---@param self dreamwork.std.Vector2 The vector to calculate the angle of.
    ---@param up? dreamwork.std.Vector2 The direction of the angle.
    ---@return number angle The angle of the vector.
    local function Vector2_getAngle( self, up )
        if up == nil then
            return 360 - math_deg( math_atan2( self[ 1 ], self[ 2 ] ) )
        else
            return Vector2_getAngle( up ) + Vector2_getAngle( self )
        end
    end

    Vector2.getAngle = Vector2_getAngle

    --- [SHARED AND MENU]
    ---
    --- Linear interpolation between two vectors.
    ---
    ---@param self dreamwork.std.Vector2 The vector.
    ---@param vector dreamwork.std.Vector2 The other vector.
    ---@param frac number The interpolation factor.
    ---@return dreamwork.std.Vector2 vec3 The interpolated vector.
    local function Vector2_lerpToVector( self, vector, frac )
        self[ 1 ] = math_lerp( frac, self[ 1 ], vector[ 1 ] )
        self[ 2 ] = math_lerp( frac, self[ 2 ], vector[ 2 ] )
        return self
    end

    Vector2.lerpToVector = Vector2_lerpToVector

    --- [SHARED AND MENU]
    ---
    --- Linear interpolation between two vectors.
    ---
    ---@param vector dreamwork.std.Vector2 The other vector.
    ---@param frac number The interpolation factor.
    ---@return dreamwork.std.Vector2 vec3 The interpolated vector.
    function Vector2:getLerpedToVector( vector, frac )
        return Vector2_lerpToVector( Vector2_copy( self ), vector, frac )
    end

    --- [SHARED AND MENU]
    ---
    --- Linear interpolation between vector and number.
    ---
    ---@param self dreamwork.std.Vector2 The vector.
    ---@param number number The other number.
    ---@param frac number The interpolation factor.
    ---@return dreamwork.std.Vector2 vec3 The interpolated vector.
    local function Vector2_lerpToNumber( self, number, frac )
        self[ 1 ] = math_lerp( frac, self[ 1 ], number )
        self[ 2 ] = math_lerp( frac, self[ 2 ], number )
        return self
    end

    Vector2.lerpToNumber = Vector2_lerpToNumber

    --- [SHARED AND MENU]
    ---
    --- Linear interpolation between vector and number.
    ---
    ---@param number number The other number.
    ---@param frac number The interpolation factor.
    ---@return dreamwork.std.Vector2 vec3 The interpolated vector.
    function Vector2:getLerpedToNumber( number, frac )
        return Vector2_lerpToNumber( Vector2_copy( self ), number, frac )
    end

end

do

    ---@protected
    function Vector3:__tostring()
        return string_format( "Vector3: %p [%f, %f, %f]", self, self[ 1 ], self[ 2 ], self[ 3 ] )
    end

    ---@protected
    ---@param x? number
    ---@param y? number
    ---@param z? number
    function Vector3:__init( x, y, z )
        if x == nil then
            self[ 1 ] = 0
        else
            self[ 1 ] = math_toFloat32( x )
        end

        if y == nil then
            self[ 2 ] = 0
        else
            self[ 2 ] = math_toFloat32( y )
        end

        if z == nil then
            self[ 3 ] = 0
        else
            self[ 3 ] = math_toFloat32( z )
        end
    end

    ---@protected
    function Vector3:__index( key )
        if key == 1 or key == "x" then
            return raw_get( self, 1 )
        elseif key == 2 or key == "y" then
            return raw_get( self, 2 )
        elseif key == 3 or key == "z" then
            return raw_get( self, 3 )
        else
            return raw_index( Vector3, key )
        end
    end

    ---@protected
    function Vector3:__newindex( key, value )
        if key == 1 or key == "x" then
            raw_set( self, 1, value )
        elseif key == 2 or key == "y" then
            raw_set( self, 2, value )
        elseif key == 3 or key == "z" then
            raw_set( self, 3, value )
        end
    end

    ---@protected
    ---@param writer dreamwork.std.pack.Writer
    function Vector3:__serialize( writer )
        writer:writeFloat( self[ 1 ] )
        writer:writeFloat( self[ 2 ] )
        writer:writeFloat( self[ 3 ] )
    end

    ---@protected
    ---@param reader dreamwork.std.pack.Reader
    function Vector3:__deserialize( reader )
        self[ 1 ] = reader:readFloat()
        self[ 2 ] = reader:readFloat()
        self[ 3 ] = reader:readFloat()
    end

    function Vector3:__tohash()
        return table_concat( self, "v", 1, 3 )
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the x, y, and z coordinates of the vector.
    ---
    ---@return number x The x coordinate of the vector.
    ---@return number y The y coordinate of the vector.
    ---@return number z The z coordinate of the vector.
    function Vector3:unpack()
        return self[ 1 ], self[ 2 ], self[ 3 ]
    end

    --- [SHARED AND MENU]
    ---
    --- Sets the x, y, and z coordinates of the vector.
    ---
    ---@param x number The x coordinate of the vector.
    ---@param y number The y coordinate of the vector.
    ---@param z number The z coordinate of the vector.
    function Vector3:setUnpacked( x, y, z )
        self[ 1 ] = x
        self[ 2 ] = y
        self[ 3 ] = z
    end

    --- [SHARED AND MENU]
    ---
    --- Creates a copy of the vector.
    ---
    ---@param self dreamwork.std.Vector3 The vector.
    ---@return dreamwork.std.Vector3 copy The copy of the vector.
    local function Vector3_copy( self )
        return setmetatable( { self[ 1 ], self[ 2 ], self[ 3 ] }, Vector3 )
    end

    Vector3.copy = Vector3_copy

    --- [SHARED AND MENU]
    ---
    --- Negates the vector.
    ---
    ---@return dreamwork.std.Vector3
    function Vector3:negate()
        self[ 1 ] = -self[ 1 ]
        self[ 2 ] = -self[ 2 ]
        self[ 3 ] = -self[ 3 ]
        return self
    end

    ---@protected
    ---@return dreamwork.std.Vector3
    function Vector3:__unm()
        return setmetatable( { -self[ 1 ], -self[ 2 ], -self[ 3 ] }, Vector3 )
    end

    --- [SHARED AND MENU]
    ---
    --- Scales the vector.
    ---
    ---@param self dreamwork.std.Vector3 The vector.
    ---@param scale number The scale factor.
    ---@return dreamwork.std.Vector3 vec3 The scaled vector.
    local function Vector3_scale( self, scale )
        if scale == 0 or scale ~= scale then
            self[ 1 ] = 0
            self[ 2 ] = 0
            self[ 3 ] = 0
        elseif scale == math_huge then
            self[ 1 ] = math_huge
            self[ 2 ] = math_huge
            self[ 3 ] = math_huge
        else
            self[ 1 ] = self[ 1 ] * scale
            self[ 2 ] = self[ 2 ] * scale
            self[ 3 ] = self[ 3 ] * scale
        end

        return self
    end

    Vector3.scale = Vector3_scale

    --- [SHARED AND MENU]
    ---
    --- Returns a scaled copy of the vector.
    ---
    ---@param scale number The scale factor.
    ---@return dreamwork.std.Vector3 scaled_vec3 The scaled copy of the vector.
    function Vector3:getScaled( scale )
        return Vector3_scale( Vector3_copy( self ), scale )
    end

    do

        --- [SHARED AND MENU]
        ---
        --- Adds the vector to another vector.
        ---
        ---@param self dreamwork.std.Vector3 The vector.
        ---@param vector dreamwork.std.Vector3 The other vector.
        ---@return dreamwork.std.Vector3 vec3 The sum of the two vectors.
        local function Vector3_add( self, vector )
            self[ 1 ] = math_toFloat32( self[ 1 ] + vector[ 1 ] )
            self[ 2 ] = math_toFloat32( self[ 2 ] + vector[ 2 ] )
            self[ 3 ] = math_toFloat32( self[ 3 ] + vector[ 3 ] )
            return self
        end

        Vector3.add = Vector3_add

        ---@protected
        ---@param vector dreamwork.std.Vector3
        function Vector3:__add( vector )
            return Vector3_add( Vector3_copy( self ), vector )
        end

    end

    do

        --- [SHARED AND MENU]
        ---
        --- Subtracts the vector from another vector.
        ---
        ---@param self dreamwork.std.Vector3 The vector.
        ---@param vector dreamwork.std.Vector3 The other vector.
        ---@return dreamwork.std.Vector3 vec3 The difference of the two vectors.
        local function Vector3_sub( self, vector )
            self[ 1 ] = math_toFloat32( self[ 1 ] - vector[ 1 ] )
            self[ 2 ] = math_toFloat32( self[ 2 ] - vector[ 2 ] )
            self[ 3 ] = math_toFloat32( self[ 3 ] - vector[ 3 ] )
            return self
        end

        Vector3.sub = Vector3_sub

        ---@protected
        ---@param vector dreamwork.std.Vector3
        function Vector3:__sub( vector )
            return Vector3_sub( Vector3_copy( self ), vector )
        end

    end

    do

        --- [SHARED AND MENU]
        ---
        --- Multiplies the vector by another vector or a number.
        ---
        ---@param self dreamwork.std.Vector3 The vector.
        ---@param value dreamwork.std.Vector3 | number The other vector or a number.
        ---@return dreamwork.std.Vector3 vec3 The product of the two vectors or the vector multiplied by a number.
        local function Vector3_mul( self, value )
            if isNumber( value ) then
                ---@cast value number
                Vector3_scale( self, value )
            else
                ---@cast value dreamwork.std.Vector3
                self[ 1 ] = math_toFloat32( self[ 1 ] * value[ 1 ] )
                self[ 2 ] = math_toFloat32( self[ 2 ] * value[ 2 ] )
                self[ 3 ] = math_toFloat32( self[ 3 ] * value[ 3 ] )
            end

            return self
        end

        Vector3.mul = Vector3_mul

        ---@protected
        ---@param value dreamwork.std.Vector3
        function Vector3:__mul( value )
            return Vector3_mul( Vector3_copy( self ), value )
        end

    end

    do

        --- [SHARED AND MENU]
        ---
        --- Divides the vector by another vector or a number.
        ---
        ---@param self dreamwork.std.Vector3 The vector.
        ---@param value dreamwork.std.Vector3 | number The other vector or a number.
        ---@return dreamwork.std.Vector3 vec3 The quotient of the two vectors or the vector divided by a number.
        local function Vector3_div( self, value )
            if isNumber( value ) then
                ---@cast value number
                return Vector3_scale( self, 1 / value )
            end

            ---@cast value dreamwork.std.Vector3
            self[ 1 ] = math_toFloat32( self[ 1 ] / value[ 1 ] )
            self[ 2 ] = math_toFloat32( self[ 2 ] / value[ 2 ] )
            self[ 3 ] = math_toFloat32( self[ 3 ] / value[ 3 ] )
            return self
        end

        Vector3.div = Vector3_div

        ---@protected
        ---@param value dreamwork.std.Vector3
        function Vector3:__div( value )
            return Vector3_div( Vector3_copy( self ), value )
        end

    end

    ---@protected
    ---@param vector dreamwork.std.Vector3
    ---@return boolean
    function Vector3:__eq( vector )
        return self[ 1 ] == vector[ 1 ] and self[ 2 ] == vector[ 2 ] and self[ 3 ] == vector[ 3 ]
    end

    --- [SHARED AND MENU]
    ---
    --- Calculates the distance between two vectors.
    ---
    ---@param vector dreamwork.std.Vector3 The other vector.
    ---@return number distance The distance between the two vectors.
    function Vector3:getDistance( vector )
        return math_sqrt( ( vector[ 1 ] - self[ 1 ] ) ^ 2 + ( vector[ 2 ] - self[ 2 ] ) ^ 2 + ( vector[ 3 ] - self[ 3 ] ) ^ 2 )
    end

    do

        --- [SHARED AND MENU]
        ---
        --- Calculates the squared length of the vector.
        ---
        ---@param self dreamwork.std.Vector3 The vector.
        ---@return number length The squared length of the vector.
        local function Vector3_getLengthSqr( self )
            return ( self[ 1 ] ^ 2 ) + ( self[ 2 ] ^ 2 ) + ( self[ 3 ] ^ 2 )
        end

        Vector3.getLengthSqr = Vector3_getLengthSqr

        --- [SHARED AND MENU]
        ---
        --- Calculates the length of the vector.
        ---
        ---@param self dreamwork.std.Vector3 The vector.
        ---@return number length The length of the vector.
        local function Vector3_getLength( self )
            return math_sqrt( Vector3_getLengthSqr( self ) )
        end

        Vector3.getLength = Vector3_getLength

        --- [SHARED AND MENU]
        ---
        --- Calculates the dot product of two vectors.
        ---
        ---@param self dreamwork.std.Vector3 The vector.
        ---@param vector dreamwork.std.Vector3 The other vector.
        ---@return number dot_product The dot product of two vectors.
        local function Vector3_dot( self, vector )
            return ( self[ 1 ] * vector[ 1 ] ) + ( self[ 2 ] * vector[ 2 ] ) + ( self[ 3 ] * vector[ 3 ] )
        end

        Vector3.dot = Vector3_dot

        --- [SHARED AND MENU]
        ---
        --- Calculates the cross product of two vectors.
        ---
        ---@param self dreamwork.std.Vector3 The vector.
        ---@param vector dreamwork.std.Vector3 The other vector.
        ---@return dreamwork.std.Vector3 cross_product The cross product of two vectors.
        local function Vector3_cross( self, vector )
            local x1, y1, z1 = self[ 1 ], self[ 2 ], self[ 3 ]
            local x2, y2, z2 = vector[ 1 ], vector[ 2 ], vector[ 3 ]

            return setmetatable( {
                y1 * z2 - z1 * y2,
                z1 * x2 - x1 * z2,
                x1 * y2 - y1 * x2
            }, Vector3 )
        end

        Vector3.cross = Vector3_cross

        --- [SHARED AND MENU]
        ---
        --- Normalizes the vector.
        ---
        ---@param self dreamwork.std.Vector3 The vector.
        ---@return dreamwork.std.Vector3 vec3 The normalized vector.
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
        --- Returns a normalized copy of the vector.
        ---
        ---@return dreamwork.std.Vector3 normalized_vec3 The normalized copy of the vector.
        function Vector3:getNormalized()
            return Vector3_normalize( Vector3_copy( self ) )
        end

        local math_asin = math.asin

        --- [SHARED AND MENU]
        ---
        --- Returns the angle of the vector.
        ---
        ---@param up? dreamwork.std.Vector3 The direction of the angle.
        ---@return dreamwork.std.Angle3 ang3 The angle of the vector.
        function Vector3:toAngle( up )
            if self[ 1 ] == 0 and self[ 2 ] == 0 and self[ 3 ] == 0 then
                return setmetatable( { 0, 0, 0 }, Angle3 )
            end

            local forward = Vector3_normalize( Vector3_copy( self ) )

            if up == nil then
                return setmetatable( {
                    math_deg( math_asin( -forward[ 3 ] ) ),
                    math_deg( math_atan2( forward[ 2 ], forward[ 1 ] ) ),
                    0
                }, Angle3 )
            end

            local right = Vector3_normalize( Vector3_cross( up, forward ) )
            local x1, y1 = forward[ 1 ], forward[ 2 ]

            return setmetatable( {
                math_deg( math_asin( -forward[ 3 ] ) ),
                math_deg( math_atan2( y1, x1 ) ),
                math_deg( math_atan2( right[ 3 ], ( x1 * right[ 2 ] ) - ( y1 * right[ 1 ] ) ) )
            }, Angle3 )
        end

        local math_acos = math.acos

        --- [SHARED AND MENU]
        ---
        --- Calculates the angle between two vectors.
        ---
        ---@param vector dreamwork.std.Vector3 The other vector.
        ---@return number degrees The angle between two vectors.
        function Vector3:getAngle( vector )
            return math_deg( math_acos( Vector3_dot( self, vector ) / ( Vector3_getLength( self ) * Vector3_getLength( vector ) ) ) )
        end

        --- [SHARED AND MENU]
        ---
        --- Projects the vector onto another vector.
        ---
        ---@param self dreamwork.std.Vector3 The vector.
        ---@param vector dreamwork.std.Vector3 The other vector.
        ---@return dreamwork.std.Vector3 vec3 The projected vector.
        local function Vector3_project( self, vector )
            local normalized = Vector3_normalize( Vector3_copy( vector ) )
            local dot = Vector3_dot( self, normalized )

            self[ 1 ] = math_toFloat32( normalized[ 1 ] * dot )
            self[ 2 ] = math_toFloat32( normalized[ 2 ] * dot )
            self[ 3 ] = math_toFloat32( normalized[ 3 ] * dot )

            return self
        end

        Vector3.project = Vector3_project

        --- [SHARED AND MENU]
        ---
        --- Returns a copy of the vector projected onto another vector.
        ---
        ---@param vector dreamwork.std.Vector3 The other vector.
        ---@return dreamwork.std.Vector3 projected_vec3 The projected vector.
        function Vector3:getProjected( vector )
            return Vector3_project( Vector3_copy( self ), vector )
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Checks if the vector is zero.
    ---
    ---@return boolean is_zero `true` if the vector is zero, `false` otherwise.
    function Vector3:isZero()
        return self[ 1 ] == 0 and
               self[ 2 ] == 0 and
               self[ 3 ] == 0
    end

    --- [SHARED AND MENU]
    ---
    --- Sets the vector to zero.
    ---
    ---@return dreamwork.std.Vector3 vec3 The zero vector.
    function Vector3:zero()
        self[ 1 ] = 0
        self[ 2 ] = 0
        self[ 3 ] = 0
        return self
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if the vector is within an axis-aligned box.
    ---
    ---@param vector dreamwork.std.Vector3 The other vector.
    ---@return boolean in_box `true` if the vector is within the box, `false` otherwise.
    function Vector3:withinAABox( vector )
        return not (
            self[ 1 ] < math_min( self[ 1 ], vector[ 1 ] ) or self[ 1 ] > math_max( self[ 1 ], vector[ 1 ] ) or
            self[ 2 ] < math_min( self[ 2 ], vector[ 2 ] ) or self[ 2 ] > math_max( self[ 2 ], vector[ 2 ] ) or
            self[ 3 ] < math_min( self[ 3 ], vector[ 3 ] ) or self[ 3 ] > math_max( self[ 3 ], vector[ 3 ] )
        )
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if the vector is equal to the given vector with the given tolerance.
    ---
    ---@param vector dreamwork.std.Vector3 The vector to check.
    ---@param tolerance number The tolerance to use.
    ---@return boolean is_near `true` if the vectors are equal, otherwise `false`.
    function Vector3:isNear( vector, tolerance )
        return math_abs( self[ 1 ] - vector[ 1 ] ) <= tolerance and
               math_abs( self[ 2 ] - vector[ 2 ] ) <= tolerance and
               math_abs( self[ 3 ] - vector[ 3 ] ) <= tolerance
    end

    do

        --- [SHARED AND MENU]
        ---
        --- Rotates the vector by the given angle.
        ---
        ---@param self dreamwork.std.Vector3 The vector to rotate.
        ---@param angle Angle3 The angle to rotate by.
        ---@return dreamwork.std.Vector3 vec3 The rotated vector.
        local function Vector3_rotate( self, angle )
            local pitch, yaw, roll = math_rad( angle[ 1 ] ), math_rad( angle[ 2 ] ), math_rad( angle[ 3 ] )
            local ysin, ycos, psin, pcos, rsin, rcos = math_sin( yaw ), math_cos( yaw ), math_sin( pitch ), math_cos( pitch ), math_sin( roll ), math_cos( roll )

            local psin_rsin, psin_rcos = psin * rsin, psin * rcos
            local x, y, z = self[ 1 ], self[ 2 ], self[ 3 ]

            self[ 1 ] = x * ( ycos * pcos ) + y * ( ycos * psin_rsin - ysin * rcos ) + z * ( ycos * psin_rcos + ysin * rsin )
            self[ 2 ] = x * ( ysin * pcos ) + y * ( ysin * psin_rsin + ycos * rcos ) + z * ( ysin * psin_rcos - ycos * rsin )
            self[ 3 ] = x * ( -psin ) + y * ( pcos * rsin ) + z * ( pcos * rcos )

            return self
        end

        Vector3.rotate = Vector3_rotate

        --- [SHARED AND MENU]
        ---
        --- Returns a copy of the vector rotated by the given angle.
        ---
        ---@param angle Angle3 The angle to rotate by.
        ---@return dreamwork.std.Vector3 rotated_vec3 The rotated vector.
        function Vector3:getRotated( angle )
            return Vector3_rotate( Vector3_copy( self ), angle )
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Linear interpolation between two vectors.
    ---
    ---@param vector dreamwork.std.Vector3 The other vector.
    ---@param frac number The interpolation factor.
    ---@return dreamwork.std.Vector3 vec3 The interpolated vector.
    function Vector3:lerpToVector( vector, frac )
        ---@cast vector dreamwork.std.Vector3
        self[ 1 ] = math_lerp( frac, self[ 1 ], vector[ 1 ] )
        self[ 2 ] = math_lerp( frac, self[ 2 ], vector[ 2 ] )
        self[ 3 ] = math_lerp( frac, self[ 3 ], vector[ 3 ] )
        return self
    end

    --- [SHARED AND MENU]
    ---
    --- Linear interpolation between vector and number.
    ---
    ---@param number number The other number.
    ---@param frac number The interpolation factor.
    ---@return dreamwork.std.Vector3 vec3 The interpolated vector.
    function Vector3:lerpToNumber( number, frac )
        self[ 1 ] = math_lerp( frac, self[ 1 ], number )
        self[ 2 ] = math_lerp( frac, self[ 2 ], number )
        self[ 3 ] = math_lerp( frac, self[ 3 ], number )
        return self
    end

end

-- TODO: rewrite

do

    ---@protected
    function Angle3:__tostring()
        return string_format( "Angle3: %p [%f, %f, %f]", self, self:unpack() )
    end

    ---@protected
    function Angle3:__init( pitch, yaw, roll )
        if pitch == nil then
            self[ 1 ] = 0
        else
            self[ 1 ] = math_toFloat32( pitch )
        end

        if yaw == nil then
            self[ 2 ] = 0
        else
            self[ 2 ] = math_toFloat32( yaw )
        end

        if roll == nil then
            self[ 3 ] = 0
        else
            self[ 3 ] = math_toFloat32( roll )
        end
    end

    ---@protected
    function Angle3:__index( key )
        if key == 1 or key == "pitch" or key == "p" then
            return raw_get( self, 1 )
        elseif key == 2 or key == "yaw" or key == "y" then
            return raw_get( self, 2 )
        elseif key == 3 or key == "roll" or key == "r" then
            return raw_get( self, 3 )
        else
            return raw_index( Angle3, key )
        end
    end

    ---@protected
    function Angle3:__newindex( key, value )
        if key == 1 or key == "pitch" or key == "p" then
            raw_set( self, 1, value )
        elseif key == 2 or key == "yaw" or key == "y" then
            raw_set( self, 2, value )
        elseif key == 3 or key == "roll" or key == "r" then
            raw_set( self, 3, value )
        end
    end

    ---@protected
    ---@param writer dreamwork.std.pack.Writer
    function Angle3:__serialize( writer )
        writer:writeUInt8( math_floor( ( self[ 1 ] + 90 ) / 180 * 255 + 0.5 ) )
        writer:writeUInt8( math_floor( self[ 2 ] / 360 * 255 + 0.5 ) )
        writer:writeUInt8( math_floor( ( self[ 3 ] + 180 ) / 360 * 255 + 0.5 ) )
    end

    ---@protected
    ---@param reader dreamwork.std.pack.Reader
    function Angle3:__deserialize( reader )
        self[ 1 ] = ( reader:readUInt8() / 255 * 180 ) - 90
        self[ 2 ] = reader:readUInt8() / 255 * 360
        self[ 3 ] = ( reader:readUInt8() / 255 * 360 ) - 180
    end

    ---@protected
    ---@return string
    function Angle3:__tohash()
        return table_concat( self, "a", 1, 3 )
    end

    --- [SHARED AND MENU]
    ---
    --- Unpacks the angle.
    ---
    ---@return number pitch The pitch angle.
    ---@return number yaw The yaw angle.
    ---@return number roll The roll angle.
    function Angle3:unpack()
        return self[ 1 ], self[ 2 ], self[ 3 ]
    end

    --- [SHARED AND MENU]
    ---
    --- Sets the angle from unpacked angles.
    ---
    ---@param pitch? number The pitch angle.
    ---@param yaw? number The yaw angle.
    ---@param roll? number The roll angle.
    ---@return dreamwork.std.Angle3 ang3 The angle.
    function Angle3:setUnpacked( pitch, yaw, roll )
        self[ 1 ] = pitch
        self[ 2 ] = yaw
        self[ 3 ] = roll
        return self
    end

    --- [SHARED AND MENU]
    ---
    --- Returns a copy of the angle.
    ---
    ---@param self dreamwork.std.Angle3 The angle.
    ---@return dreamwork.std.Angle3 copy A copy of the angle.
    local function Angle3_copy( self )
        return setmetatable( { self[ 1 ], self[ 2 ], self[ 3 ] }, Angle3 )
    end

    Angle3.copy = Angle3_copy

    do

        --- [SHARED AND MENU]
        ---
        --- Adds the angle.
        ---
        ---@param self dreamwork.std.Angle3 The angle.
        ---@param angle dreamwork.std.Angle3 The angle to add.
        ---@return dreamwork.std.Angle3 ang3 The sum of the angles.
        local function Angle3_add( self, angle )
            self[ 1 ] = self[ 1 ] + angle[ 1 ]
            self[ 2 ] = self[ 2 ] + angle[ 2 ]
            self[ 3 ] = self[ 3 ] + angle[ 3 ]
            return self
        end

        Angle3.add = Angle3_add

        ---@protected
        ---@param angle dreamwork.std.Angle3
        ---@return dreamwork.std.Angle3
        function Angle3:__add( angle )
            return Angle3_add( Angle3_copy( self ), angle )
        end

    end

    do

        --- [SHARED AND MENU]
        ---
        --- Subtracts the angle.
        ---
        ---@param self dreamwork.std.Angle3 The angle.
        ---@param angle dreamwork.std.Angle3 The angle to subtract.
        ---@return dreamwork.std.Angle3 ang3 The subtracted angle.
        local function Angle3_sub( self, angle )
            self[ 1 ] = self[ 1 ] - angle[ 1 ]
            self[ 2 ] = self[ 2 ] - angle[ 2 ]
            self[ 3 ] = self[ 3 ] - angle[ 3 ]
            return self
        end

        Angle3.sub = Angle3_sub

        ---@protected
        function Angle3:__sub( angle )
            return Angle3_sub( Angle3_copy( self ), angle )
        end

    end

    do

        --- [SHARED AND MENU]
        ---
        --- Multiplies the angle with a number or angle.
        ---
        ---@param self dreamwork.std.Angle3 The angle.
        ---@param angle number | dreamwork.std.Angle3 The angle to multiply with.
        ---@return dreamwork.std.Angle3 ang3 The multiplied angle.
        local function Angle3_mul( self, angle )
            if isNumber( angle ) then
                ---@cast angle number
                self[ 1 ] = self[ 1 ] * angle
                self[ 2 ] = self[ 2 ] * angle
                self[ 3 ] = self[ 3 ] * angle
            else
                ---@cast angle Angle3
                self[ 1 ] = self[ 1 ] * angle[ 1 ]
                self[ 2 ] = self[ 2 ] * angle[ 2 ]
                self[ 3 ] = self[ 3 ] * angle[ 3 ]
            end

            return self
        end

        Angle3.mul = Angle3_mul

        ---@protected
        ---@param angle dreamwork.std.Angle3
        ---@return dreamwork.std.Angle3
        function Angle3:__mul( angle )
            return Angle3_mul( Angle3_copy( self ), angle )
        end

    end

    do

        --- [SHARED AND MENU]
        ---
        --- Divides the angle with a number or angle.
        ---
        ---@param self dreamwork.std.Angle3 The angle.
        ---@param angle number | dreamwork.std.Angle3 The angle to divide with.
        ---@return dreamwork.std.Angle3 ang3 The divided angle.
        local function Angle3_div( self, angle )
            if isNumber( angle ) then
                self[ 1 ] = self[ 1 ] / angle
                self[ 2 ] = self[ 2 ] / angle
                self[ 3 ] = self[ 3 ] / angle
            else
                self[ 1 ] = self[ 1 ] / angle[ 1 ]
                self[ 2 ] = self[ 2 ] / angle[ 2 ]
                self[ 3 ] = self[ 3 ] / angle[ 3 ]
            end

            return self
        end

        Angle3.div = Angle3_div

        ---@protected
        function Angle3:__div( angle )
            return Angle3_div( Angle3_copy( self ), angle )
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Negates the angle.
    ---
    ---@return dreamwork.std.Angle3 ang3 The negated angle.
    function Angle3:negate()
        self[ 1 ] = -self[ 1 ]
        self[ 2 ] = -self[ 2 ]
        self[ 3 ] = -self[ 3 ]
        return self
    end

    ---@protected
    function Angle3:__unm()
        return setmetatable( { -self[ 1 ], -self[ 2 ], -self[ 3 ] }, Angle3 )
    end

    ---@protected
    function Angle3:__eq( angle )
        return self[ 1 ] == angle[ 1 ] and self[ 2 ] == angle[ 2 ] and self[ 3 ] == angle[ 3 ]
    end

    --- [SHARED AND MENU]
    ---
    --- Linearly interpolates the angle.
    ---
    ---@param angle dreamwork.std.Angle3 | number The other angle.
    ---@param frac number The interpolation factor.
    ---@return dreamwork.std.Angle3 ang3 The interpolated angle.
    function Angle3:lerp( angle, frac )
        if isNumber( angle ) then
            ---@cast angle number
            self[ 1 ] = math_lerp( frac, self[ 1 ], angle )
            self[ 2 ] = math_lerp( frac, self[ 2 ], angle )
            self[ 3 ] = math_lerp( frac, self[ 3 ], angle )
        else
            ---@cast angle Angle3
            self[ 1 ] = math_lerp( frac, self[ 1 ], angle[ 1 ] )
            self[ 2 ] = math_lerp( frac, self[ 2 ], angle[ 2 ] )
            self[ 3 ] = math_lerp( frac, self[ 3 ], angle[ 3 ] )
        end

        return self
    end

    --- [SHARED AND MENU]
    ---
    --- Returns a copy of the angle linearly interpolated between two angles.
    ---
    ---@param angle dreamwork.std.Angle3 | number  The other angle.
    ---@param frac number The interpolation factor.
    ---@return dreamwork.std.Angle3 lerped_vec3 The interpolated angle.
    function Angle3:getLerped( angle, frac )
        return self:copy():lerp( angle, frac )
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the forward direction of the angle.
    ---
    ---@return dreamwork.std.Vector3 forward_dir The forward direction of the angle.
    function Angle3:getForward()
        return setmetatable( { 1, 0, 0 }, Vector3 ):rotate( self )
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the backward direction of the angle.
    ---
    ---@return dreamwork.std.Vector3 backward_dir The backward direction of the angle.
    function Angle3:getBackward()
        return setmetatable( { -1, 0, 0 }, Vector3 ):rotate( self )
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the left direction of the angle.
    ---
    ---@return dreamwork.std.Vector3 left_dir The left direction of the angle.
    function Angle3:getLeft()
        return setmetatable( { 0, 1, 0 }, Vector3 ):rotate( self )
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the right direction of the angle.
    ---
    ---@return dreamwork.std.Vector3 right_dir The right direction of the angle.
    function Angle3:getRight()
        return setmetatable( { 0, -1, 0 }, Vector3 ):rotate( self )
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the up direction of the angle.
    ---
    ---@return dreamwork.std.Vector3 up_dir The up direction of the angle.
    function Angle3:getUp()
        return setmetatable( { 0, 0, 1 }, Vector3 ):rotate( self )
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the down direction of the angle.
    ---
    ---@return dreamwork.std.Vector3 down_dir The down direction of the angle.
    function Angle3:getDown()
        return setmetatable( { 0, 0, -1 }, Vector3 ):rotate( self )
    end

    do

        local math_angleNormalize = math.angleNormalize

        --- [SHARED AND MENU]
        ---
        --- Normalizes the angle.
        ---
        ---@return dreamwork.std.Angle3 ang3 The normalized angle.
        function Angle3:normalize()
            self[ 1 ] = math_angleNormalize( self[ 1 ] )
            self[ 2 ] = math_angleNormalize( self[ 2 ] )
            self[ 3 ] = math_angleNormalize( self[ 3 ] )
            return self
        end

        --- [SHARED AND MENU]
        ---
        --- Returns a normalized copy of the angle.
        ---
        ---@return dreamwork.std.Angle3 normalized_ang3 A normalized copy of the angle.
        function Angle3:getNormalized()
            return self:copy():normalize()
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Checks if the angle is within the given tolerance of the given angle.
    ---
    ---@param angle dreamwork.std.Angle3 The angle to check against.
    ---@param tolerance number The tolerance.
    ---@return boolean is_near `true` if the angle is within the given tolerance of the given angle.
    function Angle3:isNear( angle, tolerance )
        return math_abs( self[ 1 ] - angle[ 1 ] ) <= tolerance and
               math_abs( self[ 2 ] - angle[ 2 ] ) <= tolerance and
               math_abs( self[ 3 ] - angle[ 3 ] ) <= tolerance
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if the angle is zero.
    ---
    ---@return boolean is_zero `true` if the angle is zero, `false` otherwise.
    function Angle3:isZero()
        return self[ 1 ] == 0 and self[ 2 ] == 0 and self[ 3 ] == 0
    end

    --- [SHARED AND MENU]
    ---
    --- Sets the angle to zero.
    ---
    ---@return dreamwork.std.Angle3 ang3 The angle.
    function Angle3:zero()
        self[ 1 ] = 0
        self[ 2 ] = 0
        self[ 3 ] = 0
        return self
    end

    --- [SHARED AND MENU]
    ---
    --- Rotates the angle around the specified axis by the specified degrees.
    ---
    ---@param axis dreamwork.std.Vector3 The axis to rotate around as a normalized unit vector. When argument is not a unit vector, you will experience numerical offset errors in the rotated angle.
    ---@param rotation number The degrees to rotate around the specified axis.
    function Angle3:rotate( axis, rotation )



        return self
    end

end

--- [SHARED AND MENU]
---
--- Modifies the given vectors so that all of vector2's axis are larger than vector1's by switching them around.
---
--- Also known as ordering vectors.
---
---@param mins dreamwork.std.Vector3 The first vector to modify.
---@param maxs dreamwork.std.Vector3 The second vector to modify.
function Vector3Class.order( mins, maxs )
    local x1, y1, z1 = mins[ 1 ], mins[ 2 ], mins[ 3 ]
    local x2, y2, z2 = maxs[ 1 ], maxs[ 2 ], maxs[ 3 ]

    mins[ 1 ], mins[ 2 ], mins[ 3 ] = math_min( x1, x2 ), math_min( y1, y2 ), math_min( z1, z2 )
    maxs[ 1 ], maxs[ 2 ], maxs[ 3 ] = math_max( x1, x2 ), math_max( y1, y2 ), math_max( z1, z2 )

    return mins, maxs
end

--- [SHARED AND MENU]
---
--- Returns a new vector from world position and world angle.
---
---@param position dreamwork.std.Vector3 The local position.
---@param angle dreamwork.std.Angle3 The local angle.
---@param world_position dreamwork.std.Vector3 The world position.
---@param world_angle dreamwork.std.Angle3 The world angle.
---@return dreamwork.std.Vector3 vec3 The new vector.
---@return dreamwork.std.Angle3 ang3 The new angle.
function Vector3Class.translateToLocal( position, angle, world_position, world_angle )
    -- TODO: implement this function


end

--- [SHARED AND MENU]
---
--- Returns a new vector from local position and local angle.
---
---@param local_position dreamwork.std.Vector3 The local position.
---@param local_angle dreamwork.std.Angle3 The local angle.
---@param world_position dreamwork.std.Vector3 The world position.
---@param world_angle dreamwork.std.Angle3 The world angle.
---@return dreamwork.std.Vector3 vec3 The new vector.
---@return dreamwork.std.Angle3 ang3 The new angle.
function Vector3Class.translateToWorld( local_position, local_angle, world_position, world_angle )
    -- TODO: implement this function

end

--- [SHARED AND MENU]
---
--- Returns a new vector from screen position.
---
---@param view_angle dreamwork.std.Angle3 The view angle.
---@param view_fov number The view fov.
---@param x number The x position.
---@param y number The y position.
---@param screen_width number The screen width.
---@param screen_height number The screen height.
---@return dreamwork.std.Vector3 direction The view direction.
function Vector3Class.fromScreen( view_angle, view_fov, x, y, screen_width, screen_height )
    -- TODO: implement this function
end

-- for i = 0, 100, 25 do
--     local vx = i / 100
--     for j = 0, 100, 25 do
--         local vy = j / 100
--         for k = 0, 100, 25 do
--             local vz = k / 100
--             for rotation = 0, 360, 45 do
--                 local ap, ay, ar = 0, 0, 0

--                 print( Angle3Class( ap, ay, ar ):rotate( Vector3Class( vx, vy, vz ), rotation ) ) -- 0 -0 -90

--                 local a = _G.Angle( ap, ay, ar )
--                 a:RotateAroundAxis( _G.Vector( vx, vy, vz ), rotation )
--                 print( a )
--             end
--         end
--     end
-- end

-- do

--     local m = Matrix(
--         {
--             {1, 1, 1, 1},
--             {1, 1, 1, 1},
--             {1, 1, 1, 1},
--             {1, 1, 1, 1}
--         }
--     )

--     m:Identity()

--     m:Mul( Matrix(
--         {
--             {2, 0, 0, 0},
--             {0, 0, 0, 0},
--             {0, 0, 0, 0},
--             {0, 0, 0, 0}
--         }
--     ) )

--     m:Translate( Vector( 1, 2, 1 ) )

--     print( m )


-- end

--[[

    VMatrix structrue:

    {

        [  1 ] [  2 ] [  3 ] [  4 ] : number[] - row1
        [  5 ] [  6 ] [  7 ] [  8 ] : number[] - row2
        [  9 ] [ 10 ] [ 11 ] [ 12 ] : number[] - row3
        [ 13 ] [ 14 ] [ 15 ] [ 16 ] : number[] - row4

    }

--]]

do

    ---@protected
    function VMatrixClass:__new( r1c1, r1c2, r1c3, r1c4, r2c1, r2c2, r2c3, r2c4, r3c1, r3c2, r3c3, r3c4, r4c1, r4c2, r4c3, r4c4 )
        return setmetatable( {
            r1c1 or 0, r1c2 or 0, r1c3 or 0, r1c4 or 0,
            r2c1 or 0, r2c2 or 0, r2c3 or 0, r2c4 or 0,
            r3c1 or 0, r3c2 or 0, r3c3 or 0, r3c4 or 0,
            r4c1 or 0, r4c2 or 0, r4c3 or 0, r4c4 or 0
        }, VMatrix )
    end

    ---@protected
    function VMatrix:__tostring()
        return string.format( "VMatrix: %p\n[\n%.2f %.2f %.2f %.2f,\n%.2f %.2f %.2f %.2f,\n%.2f %.2f %.2f %.2f,\n%.2f %.2f %.2f %.2f\n]", self, self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ], self[ 5 ], self[ 6 ], self[ 7 ], self[ 8 ], self[ 9 ], self[ 10 ], self[ 11 ], self[ 12 ], self[ 13 ], self[ 14 ], self[ 15 ], self[ 16 ] )
    end

    ---@return dreamwork.std.VMatrix
    function VMatrix:identity()
        self[  1 ], self[  2 ], self[  3 ], self[  4 ] = 1, 0, 0, 0
        self[  5 ], self[  6 ], self[  7 ], self[  8 ] = 0, 1, 0, 0
        self[  9 ], self[ 10 ], self[ 11 ], self[ 12 ] = 0, 0, 1, 0
        self[ 13 ], self[ 14 ], self[ 15 ], self[ 16 ] = 0, 0, 0, 1
        return self
    end

    function VMatrix:isIdentity()
        return
            self[  1 ] == 1 and self[  2 ] == 0 and self[  3 ] == 0 and self[  4 ] == 0 and
            self[  5 ] == 0 and self[  6 ] == 1 and self[  7 ] == 0 and self[  8 ] == 0 and
            self[  9 ] == 0 and self[ 10 ] == 0 and self[ 11 ] == 1 and self[ 12 ] == 0 and
            self[ 13 ] == 0 and self[ 14 ] == 0 and self[ 15 ] == 0 and self[ 16 ] == 1
    end

    ---@return dreamwork.std.VMatrix
    function VMatrix:copy()
        return VMatrixClass( self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ], self[ 5 ], self[ 6 ], self[ 7 ], self[ 8 ], self[ 9 ], self[ 10 ], self[ 11 ], self[ 12 ], self[ 13 ], self[ 14 ], self[ 15 ], self[ 16 ] )
    end

    ---@param matrix dreamwork.std.VMatrix
    ---@return dreamwork.std.VMatrix
    function VMatrix:multiply( matrix )
        self[ 1 ] = self[ 1 ] * matrix[ 1 ] + self[ 2 ] * matrix[ 5 ] + self[ 3 ] * matrix[ 9 ] + self[ 4 ] * matrix[ 13 ]
        self[ 2 ] = self[ 1 ] * matrix[ 2 ] + self[ 2 ] * matrix[ 6 ] + self[ 3 ] * matrix[ 10 ] + self[ 4 ] * matrix[ 14 ]
        self[ 3 ] = self[ 1 ] * matrix[ 3 ] + self[ 2 ] * matrix[ 7 ] + self[ 3 ] * matrix[ 11 ] + self[ 4 ] * matrix[ 15 ]
        self[ 4 ] = self[ 1 ] * matrix[ 4 ] + self[ 2 ] * matrix[ 8 ] + self[ 3 ] * matrix[ 12 ] + self[ 4 ] * matrix[ 16 ]

        self[ 5 ] = self[ 5 ] * matrix[ 1 ] + self[ 6 ] * matrix[ 5 ] + self[ 7 ] * matrix[ 9 ] + self[ 8 ] * matrix[ 13 ]
        self[ 6 ] = self[ 5 ] * matrix[ 2 ] + self[ 6 ] * matrix[ 6 ] + self[ 7 ] * matrix[ 10 ] + self[ 8 ] * matrix[ 14 ]
        self[ 7 ] = self[ 5 ] * matrix[ 3 ] + self[ 6 ] * matrix[ 7 ] + self[ 7 ] * matrix[ 11 ] + self[ 8 ] * matrix[ 15 ]
        self[ 8 ] = self[ 5 ] * matrix[ 4 ] + self[ 6 ] * matrix[ 8 ] + self[ 7 ] * matrix[ 12 ] + self[ 8 ] * matrix[ 16 ]

        self[ 9 ] = self[ 9 ] * matrix[ 1 ] + self[ 10 ] * matrix[ 5 ] + self[ 11 ] * matrix[ 9 ] + self[ 12 ] * matrix[ 13 ]
        self[ 10 ] = self[ 9 ] * matrix[ 2 ] + self[ 10 ] * matrix[ 6 ] + self[ 11 ] * matrix[ 10 ] + self[ 12 ] * matrix[ 14 ]
        self[ 11 ] = self[ 9 ] * matrix[ 3 ] + self[ 10 ] * matrix[ 7 ] + self[ 11 ] * matrix[ 11 ] + self[ 12 ] * matrix[ 15 ]
        self[ 12 ] = self[ 9 ] * matrix[ 4 ] + self[ 10 ] * matrix[ 8 ] + self[ 11 ] * matrix[ 12 ] + self[ 12 ] * matrix[ 16 ]

        self[ 13 ] = self[ 13 ] * matrix[ 1 ] + self[ 14 ] * matrix[ 5 ] + self[ 15 ] * matrix[ 9 ] + self[ 16 ] * matrix[ 13 ]
        self[ 14 ] = self[ 13 ] * matrix[ 2 ] + self[ 14 ] * matrix[ 6 ] + self[ 15 ] * matrix[ 10 ] + self[ 16 ] * matrix[ 14 ]
        self[ 15 ] = self[ 13 ] * matrix[ 3 ] + self[ 14 ] * matrix[ 7 ] + self[ 15 ] * matrix[ 11 ] + self[ 16 ] * matrix[ 15 ]
        self[ 16 ] = self[ 13 ] * matrix[ 4 ] + self[ 14 ] * matrix[ 8 ] + self[ 15 ] * matrix[ 12 ] + self[ 16 ] * matrix[ 16 ]

        return self
    end

    ---@return dreamwork.std.Vector3
    function VMatrix:getForward()
        return std.Vector3( self[ 1 ], self[ 5 ], self[ 9 ] )
    end

    ---@param vector dreamwork.std.Vector3
    ---@return dreamwork.std.VMatrix
    function VMatrix:setForward( vector )
        self[ 1 ], self[ 5 ], self[ 9 ] = vector[ 1 ], vector[ 2 ], vector[ 3 ]
        return self
    end

    ---@return dreamwork.std.Vector3
    function VMatrix:getLeft()
        return std.Vector3( self[ 2 ], self[ 6 ], self[ 10 ] )
    end

    ---@param vector dreamwork.std.Vector3
    ---@return dreamwork.std.VMatrix
    function VMatrix:setLeft( vector )
        self[ 2 ], self[ 6 ], self[ 10 ] = vector[ 1 ], vector[ 2 ], vector[ 3 ]
        return self
    end

    ---@return dreamwork.std.Vector3
    function VMatrix:getUp()
        return std.Vector3( self[ 3 ], self[ 7 ], self[ 11 ] )
    end

    ---@param vector dreamwork.std.Vector3
    ---@return dreamwork.std.VMatrix
    function VMatrix:setUp( vector )
        self[ 3 ], self[ 7 ], self[ 11 ] = vector[ 1 ], vector[ 2 ], vector[ 3 ]
        return self
    end

    ---@return dreamwork.std.Vector3
    function VMatrix:getTranslation()
        return std.Vector3( self[ 4 ], self[ 8 ], self[ 12 ] )
    end

    ---@param vector dreamwork.std.Vector3
    ---@return dreamwork.std.VMatrix
    function VMatrix:setTranslation( vector )
        self[ 4 ], self[ 8 ], self[ 12 ] = vector[ 1 ], vector[ 2 ], vector[ 3 ]
        return self
    end

    ---@param vector dreamwork.std.Vector3
    ---@return dreamwork.std.VMatrix
    function VMatrix:translate( vector )
        return self:multiply( VMatrixClass():identity():setTranslation( vector ) )
    end

    ---@param row integer
    ---@param column integer
    ---@return number
    function VMatrix:getField( row, column )
        return self[ ( math.clamp( row, 1, 4 ) - 1 ) * 4 + math.clamp( column, 1, 4 ) ]
    end

    ---@param row integer
    ---@param column integer
    ---@param value number
    ---@return dreamwork.std.VMatrix
    function VMatrix:setField( row, column, value )
        self[ ( math.clamp( row, 1, 4 ) - 1 ) * 4 + math.clamp( column, 1, 4 ) ] = value
        return self
    end

    function VMatrix:inverse()
        local mat = {
            [ 1 ] = {
                self[ 1 ], self[ 2 ], self[ 3 ], self[ 4 ], 1, 0, 0, 0
            },
            [ 2 ] = {
                self[ 5 ], self[ 6 ], self[ 7 ], self[ 8 ], 0, 1, 0, 0
            },
            [ 3 ] = {
                self[ 9 ], self[ 10 ], self[ 11 ], self[ 12 ], 0, 0, 1, 0
            },
            [ 4 ] = {
                self[ 13 ], self[ 14 ], self[ 15 ], self[ 16 ], 0, 0, 0, 1
            }
        }

        local rowMap = { 1, 2, 3, 4 }

        -- Row reduction
        for iRow = 1, 4 do
            local fLargest = 0.00001
            local iLargest = -1

            for iTest = iRow, 4 do
                local fTest = math.abs( mat[ rowMap[ iTest ] ][ iRow ] )
                if fTest > fLargest then
                    iLargest = iTest
                    fLargest = fTest
                end
            end

            if iLargest == -1 then
                return false, nil
            end

            -- Swap rows
            rowMap[iLargest], rowMap[iRow] = rowMap[iRow], rowMap[iLargest]
            local pRow = mat[rowMap[iRow]]

            -- Normalize row
            local mul = 1.0 / pRow[ iRow ]
            for j = 1, 8, 1 do
                pRow[ j ] = pRow[ j ] * mul
            end

            pRow[ iRow ] = 1.0

            -- Eliminate column
            for i = 1, 4 do
                if i ~= iRow then
                    local pScaleRow = mat[rowMap[i]]
                    local mul = -pScaleRow[iRow]
                    for j = 1, 8 do
                        pScaleRow[j] = pScaleRow[j] + pRow[j] * mul
                    end

                    pScaleRow[iRow] = 0.0
                end
            end
        end


        -- Extract inverse matrix
        local dst = {}

        for i = 1, 4 do
            dst[ i ] = {}
            local pIn = mat[ rowMap[ i ] ]
            for j = 1, 4 do
                dst[ i ][ j ] = pIn[ j + 4 ]
            end
        end

        return true, dst
    end

    --- [SHARED AND MENU]
    ---
    --- Does a fast inverse, assuming the matrix only contains translation and rotation.
    function VMatrix:inverseTranslation()

        local dst = VMatrixClass(
            self[ 1 ], self[ 2 ], self[ 3 ], 0,
            self[ 5 ], self[ 6 ], self[ 7 ], 0,
            self[ 9 ], self[ 10 ], self[ 11 ], 0,
            0, 0, 0, 0
        )
    end

end

-- print( VMatrixClass():identity():copy():multiply( VMatrixClass( 2 ) ):translate( std.Vector3( 1, 2, 1 )) )

--[[

    TODO: make serealizers
        Vec3 as Nak2 checked must be writed as 3 floats but this required more tests i guess
        Same for Vec2

]]
