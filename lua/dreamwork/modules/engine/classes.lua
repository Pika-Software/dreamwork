---@class dreamwork.engine
local dreamwork_engine = dreamwork.engine

local std = dreamwork.std

local class = std.class

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
    ---@param r? integer Red channel.
    ---@param g? integer Green channel.
    ---@param b? integer Blue channel.
    ---@param a? integer Alpha channel.
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
        return string_format( "ColorProxy: %p [%d, %d, %d, %d]", self.r, self.g, self.b, self.a )
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
    ---@class dreamwork.engine.ColorProxyClass : dreamwork.engine.ColorProxy
    ---@overload fun( r: number, g: number, b: number, a: number ): dreamwork.engine.ColorProxy
    dreamwork_engine.ColorProxy = class.create( ColorProxy )

end

do

    local Matrix = Matrix
    if Matrix ~= nil then

        -- ---@class dreamwork.engine.VMatrixProxy : dreamwork.std.Object
        -- local VMatrixProxy = class.base( "dreamwork.engine.VMatrixProxy", true )

        -- function VMatrixProxy:update()

        -- end

        -- ---@class dreamwork.engine.VMatrixProxyClass : dreamwork.engine.VMatrixProxy
        -- ---@overload fun(): dreamwork.engine.VMatrixProxy
        -- local VMatrixProxyClass = class.create( VMatrixProxy )

        -- local VMatrix = Matrix

        -- function VMatrixProxyClass:__new()
        --     return VMatrix()
        -- end

        -- TODO: VMatrixProxy

    end

end
