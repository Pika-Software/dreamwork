---@class dreamwork.engine
local dreamwork_engine = dreamwork.engine

local engine_hook = dreamwork_engine.hook
local hook_call = engine_hook.call

local detour = dreamwork.detour

--- [SHARED AND MENU]
---
--- Entity tracking.
---
--- Keeps a snapshot of `ents.GetAll` and calls the `dreamwork.entity.spawn`, `dreamwork.entity.destroy`
--- and `dreamwork.entity.registry` engine hooks when the engine's entity list changes.
---
---@class dreamwork.engine.entity
local entity_library = {}
dreamwork_engine.entity = entity_library


--- The engine `ents` library, created if the host engine doesn't provide it.
---
---@class garrysmod.ents
local ents = dreamwork_engine.requireLibrary( "ents" )

-- fallback for engines without `ents.GetAll`: always an empty list
if ents.GetAll == nil then
    ---@type garrysmod.Entity[]
    local woops = {}
    function ents.GetAll()
        return woops
    end
end

local ents_GetAll = ents.GetAll

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

--- Hooks the engine's `InvalidateInternalEntityCache`, which is called when entities are created or removed.
---
--- Compares the new `ents.GetAll` result with the previous snapshot,
--- calls `dreamwork.entity.spawn` / `dreamwork.entity.destroy` for each difference
--- and `dreamwork.entity.registry` once if anything changed. The original function is still called afterwards.
---
---@param is_player boolean `true` if the change was caused by a player entity.
detour.before( function( is_player )
    local new_entities = ents_GetAll()
    local new_count = #new_entities

    local has_changes = false

    ---@type table<garrysmod.Entity, integer>
    local new_map = {}

    for i = 1, new_count, 1 do
        local entity = new_entities[ i ]
        new_map[ entity ] = i

        if entity_map[ entity ] == nil then
            hook_call( "dreamwork.entity.spawn", entity, is_player )
            has_changes = true
        end
    end

    for i = 1, entity_count, 1 do
        local entity = entity_list[ i ]
        if new_map[ entity ] == nil then
            hook_call( "dreamwork.entity.destroy", entity, is_player )
            has_changes = true
        end
    end

    entity_list = new_entities
    entity_count = new_count
    entity_map = new_map

    if has_changes then
        hook_call( "dreamwork.entity.registry", new_entities, new_count )
    end
end, nil, "InvalidateInternalEntityCache" )

--- [SHARED AND MENU]
---
--- Returns the cached list of all entities and its size.
---
--- > NOTE: The returned table is the internal snapshot, do not modify it.
---
---@return garrysmod.Entity[] entities The list of all entities.
---@return integer entity_count The number of entities in the list.
---@nodiscard
function entity_library.getAll()
    return entity_list, entity_count
end
