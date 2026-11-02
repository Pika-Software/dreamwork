---@meta _

--- [SHARED AND MENU]
---
--- A library for creating classes, implementing inheritance, and working with the object model in Lua.
---
--- A class consists of two tables:
--- * **base** ( `class.base` ) - the metatable of every object, holds methods and metamethods;
--- * **class** ( `class.create` ) - the callable table that creates objects, holds static fields.
---
---@class class
class = {}

---@alias Class.__inherited fun( parent: Class, child: Class )
---@alias Class.__new fun( cls: Class, ...: any? ): Object | nil
---@alias Object.__init fun( obj: Object, ...: any? )

--- [SHARED AND MENU]
---
--- A base for objects that were created by `class` library.
---
---@class Object : metatable
---@field __type string The name of object type. **READ ONLY**
---@field __class? Class The class of the object. **READ ONLY**
---@field __parent? Object The base of the parent class. **READ ONLY**
---@field __private? boolean `true` if objects of this base are `userdata`. **READ ONLY**
---@field __init? Object.__init A function that will be called when creating a new object and should be used as the constructor.
---@field private __template? userdata The userdata whose metatable is shared by all private objects.
---@field private __ancestors table<Object, boolean> The set of this base and all parent bases.

--- [SHARED AND MENU]
---
--- A general structure for every class that created with `class` library.
---
---@class Class : Object
---@field __base Object The base of the class. **READ ONLY**
---@field __parent? Class The parent of the class. **READ ONLY**
---@field __new? Class.__new A function that will be called instead of the default object creation, if it returns a non-`nil` value, it will be used as the result and `__init` will **not** be called.
---@field __inherited? Class.__inherited The function that will be called when the class or any of its children is inherited, it is not copied to children.

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
--- Checks if the value is an object created by a class.
---
--- Objects of a base that was never passed to `class.create` are not considered objects.
---
---@param value any The value to check for being an object.
---@return boolean is_object `true` if `value` is an object created by a class, `false` otherwise.
---@nodiscard
function isObject(value) end

--- [SHARED AND MENU]
---
--- Creates a new class base ( metatable ).
---
--- If `parent` is given, methods are looked up through the parent base,
--- and metamethods ( `__*` keys ) of the parent base are **copied** into the new base.
---
--- Notes:
--- * metamethods are copied once, at the moment of this call,
--- so the parent base must be fully defined before its children are created;
--- * `__index` is never copied, a parent with a custom `__index` function
--- requires the child to define its own `__index`;
--- * private objects are `userdata`, so they cannot store fields
--- and their data must be kept outside ( e.g. in a weak table ).
---
---@param name string The name of the class.
---@param private? boolean If `true`, objects will be `userdata` instead of `table`.
---@param parent? Class | unknown The parent class.
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
--- Creates a new class object without calling `__init`.
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
--- Static fields of the parent class ( including `__new`, except `__inherited` ) are copied into the new class,
--- then `__inherited` of every ancestor class is called, from the direct parent up to the root.
---
---@param base Object The base object, aka metatable.
---@return Class | unknown cls The class.
function class.create(base) end

--- [SHARED AND MENU]
---
--- Checks if the value is an instance of the given class or any of its children.
---
--- Plain metatables ( not created by `class.base` ) only match directly, without inheritance.
---
---@param obj any The object to check for being an instance of the given class.
---@param cls Class | Object The class or its base to check against.
---@return boolean is_instance `true` if `obj` is an instance of the given class, `false` otherwise.
---@nodiscard
function class.isInherited(obj, cls) end
