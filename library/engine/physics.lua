---@meta _

---@class physics
local physics = {}

---@class physics.collide
local collide = {}

collide.createFromModel = _G.CreatePhysCollidesFromModel

collide.createBox = _G.CreatePhysCollideBox

physics.collide = collide

---@type PhysObj
physics.object = nil

---@class physics.surface
local surface = {}

---
--- https://wiki.facepunch.com/gmod/Enums/MAT
---
--- https://developer.valvesoftware.com/wiki/Material_Types
---
---@type table<string, integer>
surface.Materials = nil

--- Adds surface properties to the game's physics environment.
---@param data SurfacePropertyData | table The surface data to be added.
function surface.add(data) end

physics.surface = surface

---@class physics.settings
---@field max_ovw_time number Maximum amount of seconds to precalculate collisions with world. ( Default: 1 )
---@field max_ovo_time number Maximum amount of seconds to precalculate collisions with objects. ( Default: 0.5 )
---@field max_collisions_per_tick number Maximum collision checks per tick.
--- Objects may penetrate after this many collision checks. ( Default: 50000 )
---@field max_object_collisions_pre_tick number Maximum collision per object per tick.
--- Object will be frozen after this many collisions (visual hitching vs. CPU cost). ( Default: 10 )
---@field max_velocity number Maximum world-space speed of an object in inches per second. ( Default: 4000 )
---@field max_angular_velocity number Maximum world-space rotational velocity in degrees per second. ( Default: 7200 )
---@field min_friction_mass number Minimum mass of an object to be affected by friction. ( Default: 10 )
---@field max_friction_mass number Maximum mass of an object to be affected by friction. ( Default: 2500 )
local settings = {}

physics.settings = settings
