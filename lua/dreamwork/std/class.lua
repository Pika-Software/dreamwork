---@class dreamwork.std
local std = _G.dreamwork.std

local string = std.string
local string_format = string.format

local debug = std.debug
local debug_newproxy = debug.newproxy
local debug_getmetavalue = debug.getmetavalue

local raw = std.raw
local raw_get, raw_set = raw.get, raw.set

local setmetatable = std.setmetatable

--- [SHARED AND MENU]
---
--- The class (OOP) library.
---
---@class dreamwork.std.class
local class = {}
std.class = class

---@alias dreamwork.Class.__inherited fun( parent: dreamwork.Class, child: dreamwork.Class )
---@alias dreamwork.Class.__new fun( cls: dreamwork.Class, ...: any? ): dreamwork.Object
---@alias dreamwork.Object.__init fun( obj: dreamwork.Object, ...: any? )

---@class dreamwork.Object
---@field private __type string The name of object type. **READ ONLY**
---@field private __init? dreamwork.Object.__init A function that will be called when creating a new object and should be used as the constructor.
---@field __class dreamwork.Class The class of the object. **READ ONLY**
---@field __parent? dreamwork.Object The parent of the object. **READ ONLY**
---@field protected __new? dreamwork.Class.__new A function that will be called when a new class is created and allows you to replace the result.
---@field protected __serialize? fun( obj: dreamwork.Object, writer: dreamwork.std.pack.Writer, data: any? )
---@field protected __deserialize? fun( obj: dreamwork.Object, reader: dreamwork.std.pack.Reader, data: any? )
---@field protected __tohash? fun( obj: dreamwork.Object ): string
---@field protected __tostring? fun( obj: dreamwork.Object ): string
---@field protected __tonumber? fun( obj: dreamwork.Object ): number
---@field protected __toboolean? fun( obj: dreamwork.Object ): boolean
---@field protected __tocolor? fun( obj: dreamwork.Object ): dreamwork.std.Color
---@field protected __tostring? fun( obj: dreamwork.Object ): string

---@diagnostic disable-next-line: duplicate-doc-alias
---@alias Object dreamwork.Object

---@class dreamwork.Class : dreamwork.Object
---@field __base dreamwork.Object The base of the class. **READ ONLY**
---@field __parent? dreamwork.Class The parent of the class. **READ ONLY**
---@field __private boolean If the class is private. **READ ONLY**
---@field private __inherited? dreamwork.Class.__inherited The function that will be called when the class is inherited.

---@diagnostic disable-next-line: duplicate-doc-alias
---@alias Class dreamwork.Class

---@type table<dreamwork.Object, userdata>
local templates = {}

std.gc.setTableRules( templates, true, false )

---@param obj dreamwork.Object The object to convert to a string.
---@return string str The string representation of the object.
local function __tostring( obj )
    return string_format( "%s: %p", debug_getmetavalue( obj, "__type" ) or "unknown", obj )
end

do

    local debug_getmetatable = debug.getmetatable
    local string_byte = string.byte
    local raw_pairs = raw.pairs

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
    ---@param parent? dreamwork.Class | unknown The parent of the class.
    ---@return dreamwork.Object base The base of the class.
    function class.base( name, private, parent )
        local base

        if private then
            local template = debug_newproxy( true )
            base = debug_getmetatable( template )

            if base == nil then
                error( "`userdata` metatable is missing, Lua environment is corrupted!" )
            end

            templates[ base ] = template

            raw_set( base, "__type", name )
            raw_set( base, "__private", true )
            raw_set( base, "__tostring", __tostring )
        else
            base = {
                __type = name,
                __tostring = __tostring
            }
        end

        base.__index = base

        if parent ~= nil then
            local parent_base = raw_get( parent, "__base" )
            if parent_base == nil then
                error( "Parent class has no `__base` variable.", 2 )
            end

            ---@cast parent_base dreamwork.Object
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
    ---@param base dreamwork.Object The base object, aka metatable.
    ---@param obj dreamwork.Object The object to initialize.
    ---@param ... any? Arguments to pass to the constructor.
    ---@return dreamwork.Object object The initialized object.
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
    ---@param base dreamwork.Object The base object, aka metatable.
    ---@return dreamwork.Object object The new object.
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

    ---@param self dreamwork.Class The class.
    ---@return dreamwork.Object object The new object.
    function class__call( self, ... )
        ---@type dreamwork.Object | nil
        local obj

        ---@type dreamwork.Class.__new | nil
        local new_fn = raw_get( self, "__new" )
        if new_fn ~= nil then
            obj = new_fn( self, ... )
        end

        if obj == nil then
            ---@type dreamwork.Object | nil
            local base = raw_get( self, "__base" )
            if base == nil then
                std.errorf( 2, false, "Class '%s' variable `__base` is missing, class creation failed.", self )
            else
                obj = class_init( base, class_new( base ), ... )
            end
        end

        ---@diagnostic disable-next-line: return-type-mismatch
        return obj
    end

end

--- [SHARED AND MENU]
---
--- Creates a new class from the given base.
---
---@param base dreamwork.Object The base object, aka metatable.
---@return dreamwork.Class | unknown cls The class.
function class.create( base )
    local cls = {}

    ---@type dreamwork.Class | nil
    local parent_class

    local parent_base = raw_get( base, "__parent" )
    if parent_base ~= nil then
        ---@cast parent_base dreamwork.Object
        parent_class = raw_get( parent_base, "__class" )

        if parent_class == nil then
            error( "Parent class has no `__class` variable.", 2 )
        end

        for key, value in pairs( parent_class ) do
            cls[ key ] = value
        end
    end

    raw_set( base, "__class", cls )

    setmetatable( cls, {
        __index = base,
        __call = class__call,
        __tostring = __tostring,
        __type = raw_get( base, "__type" ) .. "Class"
    } )

    raw_set( cls, "__parent", parent_class )
    raw_set( cls, "__base", base )

    if parent_class ~= nil then
        ---@type dreamwork.Class.__inherited | nil
        local inherited_fn = raw_get( parent_class, "__inherited" )
        if inherited_fn ~= nil then
            inherited_fn( parent_class, cls )
        end
    end

    return cls
end
