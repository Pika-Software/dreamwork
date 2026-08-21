---@type dreamwork
local dreamwork = dreamwork

local engine = dreamwork.engine

---@class dreamwork.std
local std = dreamwork.std

local class = std.class

---@class dreamwork.std.Entity : dreamwork.std.Object
local Entity = class.base( "Entity", true )

---@class dreamwork.std.EntityClass : dreamwork.std.Entity
local EntityClass = class.create( Entity )
std.Entity = EntityClass

-- ---@field ClientLimit integer The maximum number of clients that can connect to the server.
-- if std.LUA_CLIENT_SERVER then
--     engine.ClientLimit = game.MaxPlayers()
-- else
--     engine.ClientLimit = 0
-- end

-- ---@type table<Entity, integer>
-- local entity_indexes = {}

-- do

--     ---@type dreamwork.Metatable<Entity, integer>
--     local metatable = {}

--     local Entity_EntIndex = ENTITY.EntIndex

--     function metatable:__index( entity )
--         local index = Entity_EntIndex( entity )
--         self[ index ] = entity
--         return entity
--     end

--     setmetatable( entity_indexes, metatable )

-- end

-- ---@param entity Entity
-- ---@return integer index
-- function engine.getEntityIndex( entity )
--     return entity_indexes[ entity ]
-- end

-- engine_hookCatch( "dreamwork.entity.spawn", function( entity, is_player )
--     print( "EntityCreated: " .. tostring( entity ) .. " and it's " .. (is_player and "a player" or "a entity") )
-- end )

-- engine_hookCatch( "dreamwork.entity.destroy", function( entity, is_player )
--     print( "EntityRemoved: " .. tostring( entity ) .. " and it's " .. (is_player and "a player" or "a entity") )
-- end )

-- engine_hookCatch( "dreamwork.entity.count", function( _, old_count, _, new_count )
--     print( "EntityCountChanged: " .. tostring( old_count ) .. " -> " .. tostring( new_count ) )
-- end )

-- TODO: entity class
