local dreamwork_load = dreamwork.load

local std = dreamwork.std

local getfenv = std.getfenv

local debug = std.debug
local debug_initmetatable = debug.initmetatable

local LUA_CLIENT = std.LUA_CLIENT
local LUA_SERVER = std.LUA_SERVER
local LUA_MENU = std.LUA_MENU

--- [SHARED AND MENU]
---
--- Engine linking interface.
---
--- Glue between the framework and the host engine's native API: engine classes (`Entity`, `Player`, etc.),
--- and engine-backed modules such as console, hooks, networking and timers.
---
---@class dreamwork.engine
local engine = {}
dreamwork.engine = engine

--- [SHARED AND MENU]
---
--- Returns the library table with the given name from the environment of the calling function,
--- creating an empty one (and storing it in that environment) if it doesn't exist yet.
---
--- Used by the engine modules to extend a native library (e.g. `hook`, `timer`) or to define it
--- when the host engine doesn't provide one.
---
---@param name string The name of the library, e.g. `"timer"`.
---@param stack_level? integer The level of the function whose environment is used, `1` is the function that calls `requireLibrary`. Default is `1`.
---@return table library The existing or newly created library table.
function engine.requireLibrary( name, stack_level )
    if stack_level == nil then
        stack_level = 2
    else
        stack_level = stack_level + 1
    end

    local enviroment = getfenv( stack_level )

    local library = enviroment[ name ]
    if library == nil then
        library = {}; enviroment[ name ] = library
    end

    return library
end

--- The metatable of the engine `Entity` class, the base of all other entity classes.
---
---@class garrysmod.Entity
local Entity = debug_initmetatable( "Entity" )
engine.Entity = Entity

--- The metatable of the engine `Player` class.
---
---@class garrysmod.Player : garrysmod.Entity
local Player = debug_initmetatable( "Player" )
engine.Player = Player
Player.__parent = Entity

--- The metatable of the engine `Weapon` class.
---
---@class garrysmod.Weapon : garrysmod.Entity
local Weapon = debug_initmetatable( "Weapon" )
engine.Weapon = Weapon
Weapon.__parent = Entity

--- The metatable of the engine `Vehicle` class.
---
---@class garrysmod.Vehicle : garrysmod.Entity
local Vehicle = debug_initmetatable( "Vehicle" )
engine.Vehicle = Vehicle
Vehicle.__parent = Entity

--- The metatable of the engine `NPC` class.
---
---@class garrysmod.NPC : garrysmod.Entity
local NPC = debug_initmetatable( "NPC" )
NPC.__parent = Entity
engine.NPC = NPC

--- The metatable of the engine `NextBot` class.
---
---@class garrysmod.NextBot : garrysmod.Entity
local NextBot = debug_initmetatable( "NextBot" )
engine.NextBot = NextBot
NextBot.__parent = Entity

--- The metatable of the engine `ConVar` class.
---
---@class garrysmod.console.Variable
local ConsoleVariable = debug_initmetatable( "ConVar" )
engine.ConsoleVariable = ConsoleVariable

dreamwork_load( "modules/engine/hook.lua" )

-- TODO: effects | particles?
