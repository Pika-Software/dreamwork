---@class dreamwork.engine
local dreamwork_engine = dreamwork.engine

---@class garrysmod.ents
local glua_ents = dreamwork_engine.requireLibrary( "ents" )

if glua_ents.GetAll == nil then
    ---@type garrysmod.Entity[]
    local woops = {}
    function glua_ents.GetAll()
        return woops
    end
end

local engine_Entity = dreamwork_engine.Entity
local engine_Player = dreamwork_engine.Player
local Entity_EntIndex = engine_Entity.EntIndex

local engine_hook = dreamwork_engine.hook
local hook_call = engine_hook.call

local detour = dreamwork.detour

local std = dreamwork.std

local raw = std.raw

local rbit = raw.bit
local rbit_width = rbit.width

local debug = std.debug
local debug_getmetatable = debug.getmetatable

local math = std.math
local math_max = math.max


--- [SHARED]
---
---
---
---@class dreamwork.engine.entity
---@field index_bits integer The number of bits needed to encode the highest known entity index ( 1 to 32 ), updated on every registry change.
local engine_entity = { index_bits = 1 }
dreamwork_engine.entity = engine_entity

do

    local ents_GetAll = glua_ents.GetAll

    --- The entity list as of the last registry update.
    ---
    ---@type garrysmod.Entity[]
    local entity_list = ents_GetAll()

    --- The number of entities in `entity_list`.
    ---
    ---@type integer
    local entity_count = #entity_list

    --- The entity to index lookup of `entity_list`, used to detect spawned and destroyed entities.
    ---
    ---@type table<garrysmod.Entity, integer>
    local entity_map = {}

    for i = 1, entity_count, 1 do
        entity_map[ entity_list[ i ] ] = i
    end

    --- [SHARED]
    ---
    --- Rebuilds the cached entity list from `ents.GetAll`.
    ---
    --- Entities that appeared call `dreamwork.entity.spawn` ( and `dreamwork.client.spawn` for players ),
    --- entities that disappeared call `dreamwork.entity.destroy` ( and `dreamwork.client.destroy` for players ).
    --- `dreamwork.entity.registry` is called once when the list changed.
    ---
    --- The engine runs this from `InvalidateInternalEntityCache`.
    ---
    --- Call it when an entity is already valid but not registered yet,
    --- so the cache catches up without waiting for the engine.
    ---
    function engine_entity.update()
        local new_entities = ents_GetAll()
        local new_count = #new_entities

        local has_changes = false
        local max_index = 0

        ---@type table<garrysmod.Entity, integer>
        local new_map = {}

        for i = 1, new_count, 1 do
            local entity = new_entities[ i ]
            new_map[ entity ] = i

            if entity_map[ entity ] == nil then
                local is_client = debug_getmetatable( entity ) == engine_Player
                hook_call( "dreamwork.entity.spawn", entity, is_client )

                if is_client then
                    hook_call( "dreamwork.entity.client.spawn", entity )
                end

                has_changes = true
            end

            max_index = math_max( max_index, Entity_EntIndex( entity ) )
        end

        engine_entity.index_bits = math_max( 1, rbit_width( max_index ) )

        for i = 1, entity_count, 1 do
            local entity = entity_list[ i ]
            if new_map[ entity ] == nil then
                local is_client = debug_getmetatable( entity ) == engine_Player
                hook_call( "dreamwork.entity.destroy", entity, is_client )

                if is_client then
                    hook_call( "dreamwork.entity.client.destroy", entity )
                end

                has_changes = true
            end
        end

        entity_list = new_entities
        entity_count = new_count
        entity_map = new_map

        if has_changes then
            hook_call( "dreamwork.entity.registry", new_entities, new_count )
        end
    end

    detour.before( engine_entity.update, nil, "InvalidateInternalEntityCache" )

    --- [SHARED]
    ---
    --- Returns the cached list of all entities and its size.
    ---
    --- > **NOTE**: The returned table is the internal snapshot, do not modify it.
    ---
    ---@return garrysmod.Entity[] entities The list of all entities.
    ---@return integer entity_count The number of entities in the list.
    ---@nodiscard
    function engine_entity.getAll()
        return entity_list, entity_count
    end

    --- [SHARED]
    ---
    --- Checks if the entity is in the cached entity list, i.e. its `dreamwork.entity.spawn` event has been called.
    ---
    --- > **NOTE**: An engine entity can be valid before it is registered. The list follows the engine entity cache, and `update` rebuilds it immediately.
    ---
    ---@param entity garrysmod.Entity The entity to check.
    ---@return boolean is_registered `true` if the entity is in the cached entity list, `false` otherwise.
    ---@nodiscard
    function engine_entity.isRegistered( entity )
        return entity_map[ entity ] ~= nil
    end

    --- [SHARED]
    ---
    --- Returns the first entity of the cached entity list that matches the predicate.
    ---
    --- Entities are checked in the order of `getAll`, the search stops at the first match.
    ---
    ---@param fn fun( entity: garrysmod.Entity ): boolean? The predicate, a truthy result selects the entity.
    ---@return garrysmod.Entity | nil entity The first matching entity, or `nil` if none matches.
    ---@nodiscard
    function engine_entity.find( fn )
        for i = 1, entity_count, 1 do
            local entity = entity_list[ i ]
            if fn( entity ) then
                return entity
            end
        end

        return nil
    end

end
