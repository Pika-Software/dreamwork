---@class dreamwork.std
local std = _G.dreamwork.std

local debug = std.debug
local string = std.string

local debug_newproxy = debug.newproxy
local setmetatable = std.setmetatable
local raw_get = std.raw.get

--- [SHARED AND MENU]
---
--- The class (OOP) library.
---
---@class dreamwork.std.class
local class = {}
std.class = class

---@alias dreamwork.std.Class.__inherited fun( parent: dreamwork.std.Class, child: dreamwork.std.Class )
---@alias dreamwork.std.Object.__new fun( cls: dreamwork.std.Class, ...: any? ): dreamwork.std.Object
---@alias dreamwork.std.Object.__init fun( obj: dreamwork.std.Object, ...: any? )

---@class dreamwork.std.Object
---@field private __type string The name of object type. **READ ONLY**
---@field private __init? dreamwork.std.Object.__init A function that will be called when creating a new object and should be used as the constructor.
---@field __class dreamwork.std.Class The class of the object. **READ ONLY**
---@field __parent? dreamwork.std.Object The parent of the object. **READ ONLY**
---@field protected __new? dreamwork.std.Object.__new A function that will be called when a new class is created and allows you to replace the result.
---@field protected __serialize? fun( obj: dreamwork.std.Object, writer: dreamwork.std.pack.Writer, data: any? )
---@field protected __deserialize? fun( obj: dreamwork.std.Object, reader: dreamwork.std.pack.Reader, data: any? )
---@field protected __tohash? fun( obj: dreamwork.std.Object ): string
---@field protected __tostring? fun( obj: dreamwork.std.Object ): string
---@field protected __tonumber? fun( obj: dreamwork.std.Object ): number
---@field protected __toboolean? fun( obj: dreamwork.std.Object ): boolean
---@field protected __tocolor? fun( obj: dreamwork.std.Object ): dreamwork.std.Color

---@alias Object dreamwork.std.Object

---@class dreamwork.std.Class : dreamwork.std.Object
---@field __base dreamwork.std.Object The base of the class. **READ ONLY**
---@field __parent? dreamwork.std.Class The parent of the class. **READ ONLY**
---@field __private boolean If the class is private. **READ ONLY**
---@field private __inherited? dreamwork.std.Class.__inherited The function that will be called when the class is inherited.

---@alias Class dreamwork.std.Class

---@type table<dreamwork.std.Object, userdata>
local templates = {}

debug.gc.setTableRules( templates, true, false )

do

    local debug_getmetavalue = debug.getmetavalue
    local debug_getmetatable = debug.getmetatable
    local string_byte = string.byte
    local raw_pairs = std.raw.pairs

    ---@param obj dreamwork.std.Object The object to convert to a string.
    ---@return string str The string representation of the object.
    local function base__tostring( obj )
        return string.format( "%s: %p", debug_getmetavalue( obj, "__type" ) or "unknown", obj )
    end

    ---@type table<string, boolean>
    local meta_blacklist = {
        __private = true,
        __class = true,
        __base = true,
        __type = true,
        __init = true
    }

    --- [SHARED AND MENU]
    ---
    --- Creates a new class base ( metatable ).
    ---
    ---@param name string The name of the class.
    ---@param private? boolean If the class is private.
    ---@param parent? dreamwork.std.Class | unknown The parent of the class.
    ---@return dreamwork.std.Object base The base of the class.
    function class.base( name, private, parent )
        local base

        if private then
            local template = debug_newproxy( true )
            base = debug_getmetatable( template )

            if base == nil then
                error( "`userdata` metatable is missing, Lua environment is corrupted!" )
            end

            templates[ base ] = template

            base.__type = name
            base.__private = true
            base.__tostring = base__tostring
        else
            base = {
                __type = name,
                __tostring = base__tostring
            }
        end

        base.__index = base

        if parent ~= nil then
            local parent_base = raw_get( parent, "__base" )
            if parent_base == nil then
                error( "Parent class has no `__base` variable.", 2 )
            end

            ---@cast parent_base dreamwork.std.Object
            base.__parent = parent_base
            setmetatable( base, { __index = parent_base } )

            -- copy metamethods from parent
            for key, value in raw_pairs( parent_base ) do
                local uint8_1, uint8_2 = string_byte( key, 1, 2 )
                if ( uint8_1 == 0x5F --[[ "_" ]] and uint8_2 == 0x5F --[[ "_" ]] ) and not ( key == "__index" and value == parent_base ) and not meta_blacklist[ key ] then
                    base[ key ] = value
                end
            end
        end

        return base
    end

end

local class__call
do

    --- [SHARED AND MENU]
    ---
    --- This function is optional and can be used to re-initialize the object.
    ---
    --- Calls the base initialization function, <b>if it exists</b>, and returns the given object.
    ---
    ---@param base dreamwork.std.Object The base object, aka metatable.
    ---@param obj dreamwork.std.Object The object to initialize.
    ---@param ... any? Arguments to pass to the constructor.
    ---@return dreamwork.std.Object object The initialized object.
    local function class_init( base, obj, ... )
        local init_fn = raw_get( base, "__init" )
        if init_fn ~= nil then
            init_fn( obj, ... )
        end

        return obj
    end

    class.init = class_init

    --- [SHARED AND MENU]
    ---
    --- Creates a new class object.
    ---
    ---@param base dreamwork.std.Object The base object, aka metatable.
    ---@return dreamwork.std.Object object The new object.
    local function class_new( base )
        if raw_get( base, "__private" ) then
            ---@diagnostic disable-next-line: return-type-mismatch
            return debug_newproxy( templates[ base ] )
        end

        local obj = {}
        setmetatable( obj, base )
        return obj
    end

    class.new = class_new

    ---@param self dreamwork.std.Class The class.
    ---@return dreamwork.std.Object object The new object.
    function class__call( self, ... )
        ---@type dreamwork.std.Object | nil
        local base = raw_get( self, "__base" )
        if base == nil then
            error( "Class variable `__base` is missing, class creation failed.", 2 )
        end

        ---@type dreamwork.std.Object | nil
        local obj

        ---@type dreamwork.std.Object.__new | nil
        local new_fn = raw_get( base, "__new" )
        if new_fn ~= nil then
            obj = new_fn( self, ... )
        end

        if obj == nil then
            obj = class_new( base )
        end

        return class_init( base, obj, ... )
    end

end

---@param cls dreamwork.std.Class The class.
---@return string str The string representation of the class.
local function class__tostring( cls )
    return string.format( "%sClass: %p", raw_get( raw_get( cls, "__base" ), "__type" ), cls )
end

local raw_set = std.raw.set

--- [SHARED AND MENU]
---
--- Creates a new class from the given base.
---
---@param base dreamwork.std.Object The base object, aka metatable.
---@return dreamwork.std.Class | unknown cls The class.
function class.create( base )
    local cls = {
        __base = base
    }

    local parent_base = raw_get( base, "__parent" )
    if parent_base ~= nil then
        ---@cast parent_base dreamwork.std.Object
        cls.__parent = parent_base.__class

        ---@type dreamwork.std.Class | nil
        local parent = raw_get( parent_base, "__class" )
        if parent == nil then
            error( "Parent class has no `__class` variable.", 2 )
        else
            ---@type dreamwork.std.Class.__inherited | nil
            local inherited_fn = raw_get( parent, "__inherited" )
            if inherited_fn ~= nil then
                inherited_fn( parent, cls )
            end
        end
    end

    setmetatable( cls, {
        __index = base,
        __call = class__call,
        __tostring = class__tostring,
        __type = raw_get( base, "__type" ) .. "Class"
    } )

    ---@cast cls dreamwork.std.Object

    raw_set( base, "__class", cls )
    return cls
end
