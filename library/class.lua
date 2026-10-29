---@meta _

--- [SHARED AND MENU]
---
--- A library for creating classes, implementing inheritance, and working with the object model in Lua.
---
---@class class
class = {}

---@alias Class.__inherited fun( parent: Class, child: Class )
---@alias Class.__new fun( cls: Class, ...: any? ): Object
---@alias Object.__init fun( obj: Object, ...: any? )

--- [SHARED AND MENU]
---
--- A base for objects were created by `class` library.
---
---@class Object : metatable
---@field __type string The name of object type. **READ ONLY**
---@field __class? Class  The class of the object. **READ ONLY**
---@field __parent? Object The parent of the object. **READ ONLY**
---@field __init? Object.__init A function that will be called when creating a new object and should be used as the constructor.
---@field __new? Class.__new A function that will be called when a new class is created and allows you to replace the result.

--- [SHARED AND MENU]
---
--- A general structure for every class that created with `class` library.
---
---@class Class : Object
---@field __base Object The base of the class. **READ ONLY**
---@field __parent? Class The parent of the class. **READ ONLY**
---@field __private boolean If the class is private. **READ ONLY**
---@field __inherited? Class.__inherited The function that will be called when the class is inherited.

--- [SHARED AND MENU]
---
--- Checks if the value is a class.
---
---@param value any The value to check for being a class.
---@return boolean is_class `true` if `value` is a class, `false` otherwise.
---@nodiscard
function isClass(value) end

--- [SHARED AND MENU]
---
--- Checks if the value is a object created by class.
---
---@param value any The value to check for being a object.
---@return boolean is_object `true` is `value` is a object created by class, `false` otherwise.
---@nodiscard
function isObject(value) end

--- [SHARED AND MENU]
---
--- Creates a new class base ( metatable ).
---
---@param name string The name of the class.
---@param private? boolean If the class is private.
---@param parent? Class | unknown The parent of the class.
---@return Object base The base of the class.
---@nodiscard
function class.base(name, private, parent) end

--- [SHARED AND MENU]
---
--- This function is optional and can be used to re-initialize the object.
---
--- Calls the base initialization function, <b>if it exists</b>, and returns the given object.
---
---@param base Object The base object, aka metatable.
---@param obj Object The object to initialize.
---@param ... any? Arguments to pass to the constructor.
---@return Object object The initialized object.
---@nodiscard
function class.init(base, obj, ...) end

--- [SHARED AND MENU]
---
--- Creates a new class object.
---
---@generic T : Object
---@param base T The base object, aka metatable.
---@return T obj The new object.
---@nodiscard
function class.new(base) end

--- [SHARED AND MENU]
---
--- Creates a new class from the given base.
---
---@param base Object The base object, aka metatable.
---@return Class | unknown cls The class.
function class.create(base) end

--- [SHARED AND MENU]
---
--- Checks if the value is an instance of the given class.
---
---@param obj Object The object to check for being an instance of the given class.
---@param cls Class | Object The class to check against.
---@return boolean is_instance `true` if `obj` is an instance of the given class, `false` otherwise.
---@nodiscard
function class.isInherited(obj, cls) end
