## How to use this class system:

### 1. Define base class (basically a metatable for our cars)

```lua
---@class my_lib.Car : dreamwork.Object           <-- do not forget to inherit from dreamwork.std.Object
---@field __class my_lib.CarClass
local Car = class.base( "Car" )

---@protected               <-- do not forget to add protected so __init won't be shown
function Car:__init()
    self.speed = 0
    self.color = 0xFF0000
end
```

### 2. Define a class, which will be used to create a Car

```lua
--- [SHARED AND MENU] <-- dont forget specify realm where your class avalible
---
--- The class used to create new `Car` instances.
---
---@class my_lib.CarClass : my_lib.Car      <-- do not forget to inherit from base
---@field __base my_lib.Car
---@overload fun(): my_lib.Car
local CarClass = class.create( Car )
std.Car = CarClass
```

### 3. Create a new car

```lua
local car = std.Car()
print( car.__type ) -- Car
print( std.Car.__type == car.__type ) -- true
print( car.speed ) -- 0
```

### 4. Inherit from the Car class

```lua
---@class my_lib.Truck : my_lib.Car
---@field __class my_lib.TruckClass
---@field __parent my_lib.Car               <-- now we need to define the parent, so LuaLS can know how to access our parent
local Truck = class.base( "Truck", false, std.Car )

--- [SHARED AND MENU]
---
--- The class used to create new `Truck` instances.
---
---@class my_lib.TruckClass : my_libstd.Truck
---@field __base my_lib.Truck
---@field __parent my_lib.CarClass
---@overload fun(): my_lib.Truck
local TruckClass = class.create( Truck )
std.Truck = TruckClass
```

## Class Template

```lua

---@class dreamwork.std.Template : dreamwork.std.Object
---@field __class dreamwork.std.TemplateClass
local Template = class.base( "Template" )

---@protected
function Template:__init()

end

--- [SHARED AND MENU]
---
--- The class used to create new `Template` instances.
---
---@class dreamwork.std.TemplateClass : dreamwork.std.Template
---@field __base dreamwork.std.Template
---@overload fun(): dreamwork.std.Template
local TemplateClass = class.create( Template )
std.Template = TemplateClass

---@class dreamwork.std.TemplateChild : dreamwork.std.Template
---@field __class dreamwork.std.TemplateChildClass
---@field __parent dreamwork.std.Template
local TemplateChild = class.base( "TemplateChild", false, std.Template )

--- [SHARED AND MENU]
---
--- The class used to create new `TemplateChild` instances.
---
---@class dreamwork.std.TemplateChildClass : dreamwork.std.TemplateChild
---@field __base dreamwork.std.TemplateChild
---@field __parent dreamwork.std.TemplateClass
---@overload fun(): TemplateChild
local TemplateChildClass = class.create( TemplateChild )
std.TemplateChild = TemplateChildClass

```
