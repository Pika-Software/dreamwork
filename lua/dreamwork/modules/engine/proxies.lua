---@class dreamwork.engine
local dreamwork_engine = dreamwork.engine

local std = dreamwork.std

local class = std.class

local debug = std.debug
local debug_fempty = debug.fempty

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local string = std.string
local string_format = string.format

local color = std.color
local color_toRGB = color.toRGB


do

    --- [SHARED AND MENU]
    ---
    --- Mutable RGBA color table that mirrors a `dreamwork.std.Color`, for passing to engine functions expecting a color table.
    ---
    ---@class dreamwork.engine.ColorProxy : dreamwork.std.Object
    ---@field r integer Red channel, `0`-`255`.
    ---@field g integer Green channel, `0`-`255`.
    ---@field b integer Blue channel, `0`-`255`.
    ---@field a integer Alpha channel, `0`-`255`.
    local ColorProxy = class.base( "dreamwork.engine.ColorProxy", false )

    --- Creates the color proxy, missing channels default to `0` (alpha to `255`).
    ---
    ---@param r integer? Red channel.
    ---@param g integer? Green channel.
    ---@param b integer? Blue channel.
    ---@param a integer? Alpha channel.
    ---@protected
    function ColorProxy:__init( r, g, b, a )
        self.r = r or 0
        self.g = g or 0
        self.b = b or 0
        self.a = a or 255
    end

    --- Returns the color as `"r, g, b, a"`.
    ---
    ---@return string
    ---@protected
    function ColorProxy:__tostring()
        return string_format( "%d, %d, %d, %d", self.r, self.g, self.b, self.a )
    end

    --- Returns a debug representation of the color proxy.
    ---
    ---@return string
    ---@protected
    function ColorProxy:__represent()
        return string_format( "ColorProxy: %p [%s]", self, self )
    end

    ---@type table<dreamwork.engine.ColorProxy, dreamwork.std.Color>
    local cache = {}
    gc_setTableRules( cache, true, false )

    --- [SHARED AND MENU]
    ---
    --- Updates the color proxy with a new color.
    ---
    --- Skipped if the proxy was last updated with the same color object. Only the RGB channels are copied, alpha is left unchanged.
    ---
    ---@param clr dreamwork.std.Color The color to copy channels from.
    function ColorProxy:update( clr )
        if cache[ self ] == clr then return end

        self.r, self.g, self.b = color_toRGB( clr )
        cache[ self ] = clr
    end

    --- [SHARED AND MENU]
    ---
    --- Color proxy class, call it to create a new `dreamwork.engine.ColorProxy`.
    ---
    ---@class dreamwork.engine.ColorProxyClass : dreamwork.engine.ColorProxy, dreamwork.std.Class
    ---@overload fun( r: number, g: number, b: number, a: number ): dreamwork.engine.ColorProxy
    dreamwork_engine.ColorProxy = class.create( ColorProxy )

end

do

    local glua_Vector = Vector
    if glua_Vector ~= nil then

        local engine_Vector = dreamwork_engine.Vector

        ---@type fun( self: garrysmod.Vector, x: number, y: number, z: number )
        local Vector_SetUnpacked = engine_Vector.SetUnpacked or debug_fempty

        --- [SHARED AND MENU]
        ---
        --- Reusable engine `Vector` that mirrors a `dreamwork.std.Vector3`, for passing to engine functions expecting a `Vector`.
        ---
        ---@class dreamwork.engine.Vector3Proxy : dreamwork.std.Object
        ---@field value garrysmod.Vector The engine vector.
        local Vector3Proxy = class.base( "dreamwork.engine.Vector3Proxy", false )

        --- Creates the vector proxy, missing coordinates default to `0`.
        ---
        ---@param x number? The x coordinate.
        ---@param y number? The y coordinate.
        ---@param z number? The z coordinate.
        ---@protected
        function Vector3Proxy:__init( x, y, z )
            self.value = glua_Vector( x or 0, y or 0, z or 0 )
        end

        --- Returns the vector as `"x, y, z"`.
        ---
        ---@return string
        ---@protected
        function Vector3Proxy:__tostring()
            local value = self.value
            return string_format( "%f, %f, %f", value[ 1 ], value[ 2 ], value[ 3 ] )
        end

        --- Returns a debug representation of the vector proxy.
        ---
        ---@return string
        ---@protected
        function Vector3Proxy:__represent()
            return string_format( "Vector3Proxy: %p [%s]", self, self )
        end

        --- [SHARED AND MENU]
        ---
        --- Copies the coordinates of the vector into the engine vector.
        ---
        ---@param vec3 dreamwork.std.Vector3 The vector to copy coordinates from.
        ---@return garrysmod.Vector value The updated engine vector.
        function Vector3Proxy:update( vec3 )
            local value = self.value
            Vector_SetUnpacked( value, vec3.x, vec3.y, vec3.z )
            return value
        end

        --- [SHARED AND MENU]
        ---
        --- Vector proxy class, call it to create a new `dreamwork.engine.Vector3Proxy`.
        ---
        ---@class dreamwork.engine.Vector3ProxyClass : dreamwork.engine.Vector3Proxy, dreamwork.std.Class
        ---@overload fun( x: number?, y: number?, z: number? ): dreamwork.engine.Vector3Proxy
        dreamwork_engine.Vector3Proxy = class.create( Vector3Proxy )

    end

end

do

    local glua_Angle = Angle
    if glua_Angle ~= nil then

        local engine_Angle = dreamwork_engine.Angle

        ---@type fun( self: garrysmod.Angle, pitch: number, yaw: number, roll: number )
        local Angle_SetUnpacked = engine_Angle.SetUnpacked or debug_fempty

        --- [SHARED AND MENU]
        ---
        --- Reusable engine `Angle` that mirrors a `dreamwork.std.Angle3`, for passing to engine functions expecting an `Angle`.
        ---
        ---@class dreamwork.engine.Angle3Proxy : dreamwork.std.Object
        ---@field value garrysmod.Angle The engine angle.
        local Angle3Proxy = class.base( "dreamwork.engine.Angle3Proxy", false )

        --- Creates the angle proxy, missing angles default to `0`.
        ---
        ---@param pitch number? The pitch in degrees.
        ---@param yaw number? The yaw in degrees.
        ---@param roll number? The roll in degrees.
        ---@protected
        function Angle3Proxy:__init( pitch, yaw, roll )
            self.value = glua_Angle( pitch or 0, yaw or 0, roll or 0 )
        end

        --- Returns the angle as `"pitch, yaw, roll"`.
        ---
        ---@return string
        ---@protected
        function Angle3Proxy:__tostring()
            local value = self.value
            return string_format( "%f, %f, %f", value[ 1 ], value[ 2 ], value[ 3 ] )
        end

        --- Returns a debug representation of the angle proxy.
        ---
        ---@return string
        ---@protected
        function Angle3Proxy:__represent()
            return string_format( "Angle3Proxy: %p [%s]", self, self )
        end

        --- [SHARED AND MENU]
        ---
        --- Copies the pitch, yaw and roll of the angle into the engine angle.
        ---
        ---@param ang3 dreamwork.std.Angle3 The angle to copy values from.
        ---@return garrysmod.Angle value The updated engine angle.
        function Angle3Proxy:update( ang3 )
            local value = self.value
            Angle_SetUnpacked( value, ang3.pitch, ang3.yaw, ang3.roll )
            return value
        end

        --- [SHARED AND MENU]
        ---
        --- Angle proxy class, call it to create a new `dreamwork.engine.Angle3Proxy`.
        ---
        ---@class dreamwork.engine.Angle3ProxyClass : dreamwork.engine.Angle3Proxy, dreamwork.std.Class
        ---@overload fun( pitch: number?, yaw: number?, roll: number? ): dreamwork.engine.Angle3Proxy
        dreamwork_engine.Angle3Proxy = class.create( Angle3Proxy )

    end

end

do

    local glua_Matrix = Matrix
    if glua_Matrix ~= nil then

        local engine_VMatrix = dreamwork_engine.VMatrix

        ---@type fun( self: garrysmod.VMatrix ): number, number, number, number, number, number, number, number, number, number, number, number, number, number, number, number
        local VMatrix_Unpack = engine_VMatrix.Unpack or debug_fempty

        ---@type fun( self: garrysmod.VMatrix, m11: number, m12: number, m13: number, m14: number, m21: number, m22: number, m23: number, m24: number, m31: number, m32: number, m33: number, m34: number, m41: number, m42: number, m43: number, m44: number )
        local VMatrix_SetUnpacked = engine_VMatrix.SetUnpacked or debug_fempty

        --- [SHARED AND MENU]
        ---
        --- Reusable engine `VMatrix` that mirrors a `dreamwork.std.VMatrix`, for passing to engine functions expecting a `VMatrix`.
        ---
        ---@class dreamwork.engine.VMatrixProxy : dreamwork.std.Object
        ---@field value garrysmod.VMatrix The engine matrix.
        local VMatrixProxy = class.base( "dreamwork.engine.VMatrixProxy", false )

        --- Creates the matrix proxy, starts as identity.
        ---
        ---@protected
        function VMatrixProxy:__init()
            self.value = glua_Matrix()
        end

        --- Returns the matrix as 4 rows of `"m11, m12, m13, m14"`.
        ---
        ---@return string
        ---@protected
        function VMatrixProxy:__tostring()
            return string_format( "%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f", VMatrix_Unpack( self.value ) )
        end

        --- Returns a debug representation of the matrix proxy.
        ---
        ---@return string
        ---@protected
        function VMatrixProxy:__represent()
            return string_format( "VMatrixProxy: %p [%s]", self, self )
        end

        --- [SHARED AND MENU]
        ---
        --- Copies all 16 values of the matrix into the engine matrix.
        ---
        ---@param matrix dreamwork.std.VMatrix The matrix to copy values from.
        ---@return garrysmod.VMatrix value The updated engine matrix.
        function VMatrixProxy:update( matrix )
            local value = self.value

            VMatrix_SetUnpacked( value,
                matrix.m11, matrix.m12, matrix.m13, matrix.m14,
                matrix.m21, matrix.m22, matrix.m23, matrix.m24,
                matrix.m31, matrix.m32, matrix.m33, matrix.m34,
                matrix.m41, matrix.m42, matrix.m43, matrix.m44
            )

            return value
        end

        --- [SHARED AND MENU]
        ---
        --- Matrix proxy class, call it to create a new `dreamwork.engine.VMatrixProxy`.
        ---
        ---@class dreamwork.engine.VMatrixProxyClass : dreamwork.engine.VMatrixProxy, dreamwork.std.Class
        ---@overload fun(): dreamwork.engine.VMatrixProxy
        dreamwork_engine.VMatrixProxy = class.create( VMatrixProxy )

    end

end
