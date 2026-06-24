---@class dreamwork.std
local std = dreamwork.std

local isCallable = std.isCallable
local pcall = std.pcall

local class = std.class

local table = std.table
local table_removeByValue = table.removeByValue

---@generic A, B, C, D, E, F
---@class dreamwork.std.Mixin : dreamwork.std.Object
---@field depth integer
---@overload fun( a: A, b: B, c: C, d: D, e: E, f: F ): A, B, C, D, E, F
---@diagnostic disable-next-line: assign-type-mismatch
local Mixin = class.base( "Mixin", false )

function Mixin:__init()
    self.depth = 0
end

---@generic A, B, C, D, E, F
---@param mixer fun( a: A, b: B, c: C, d: D, e: E, f: F ): (A | any), (B | any), (C | any), (D | any), (E | any), (F | any)
---@return integer depth
function Mixin:attach( mixer )
    assert( isCallable( mixer ), "attempt to use not callable value as Mixin mixer" )

    local depth = self.depth

    table_removeByValue( self, mixer, depth )
    depth = depth + 1

    self[ depth ] = mixer
    self.depth = depth

    return depth
end

---@generic A, B, C, D, E, F
---@param mixer fun( a: A, b: B, c: C, d: D, e: E, f: F ): (A | any), (B | any), (C | any), (D | any), (E | any), (F | any)
---@return boolean
function Mixin:detach( mixer )
    assert( isCallable( mixer ), "attempt to use not callable value as Mixin mixer" )

    local depth = self.depth
    if table_removeByValue( self, mixer, depth ) ~= nil then
        self.depth = depth - 1
        return true
    end

    return false
end

---@generic A, B, C, D, E, F
---@param mixer fun( a: A, b: B, c: C, d: D, e: E, f: F ): (A | any), (B | any), (C | any), (D | any), (E | any), (F | any)
function Mixin:__add( mixer )
    self:attach( mixer )
    return self
end

---@generic A, B, C, D, E, F
---@param mixer fun( a: A, b: B, c: C, d: D, e: E, f: F ): (A | any), (B | any), (C | any), (D | any), (E | any), (F | any)
function Mixin:__sub( mixer )
    self:detach( mixer )
    return self
end

---@generic A, B, C, D, E, F
---@param a A
---@param b B
---@param c C
---@param d D
---@param e E
---@param f F
---@return A, B, C, D, E, F
function Mixin:__call( a, b, c, d, e, f )
    for i = 1, self.depth, 1 do
        local success, r1, r2, r3, r4, r5, r6 = pcall( self[ i ], a, b, c, d, e, f )
        if success then
            a, b, c, d, e, f = r1 or a, r2 or b, r3 or c, r4 or d, r5 or e, r6 or f
        else
            std.error( r1, 2, true )
        end
    end

    return a, b, c, d, e, f
end

---@class dreamwork.std.MixinClass : dreamwork.std.Mixin
---@overload fun(): dreamwork.std.Mixin
---@diagnostic disable-next-line: param-type-mismatch
local MixinClass = class.create( Mixin )
std.Mixin = MixinClass
