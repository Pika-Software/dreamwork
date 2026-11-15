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


--- [SHARED AND MENU]
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

    detour.before( function()
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
                local is_player = debug_getmetatable( entity ) == engine_Player
                hook_call( "dreamwork.entity.spawn", entity, is_player )

                if is_player then
                    hook_call( "dreamwork.client.spawn", entity )
                end

                has_changes = true
            end

            max_index = math_max( max_index, Entity_EntIndex( entity ) )
        end

        engine_entity.index_bits = math_max( 1, rbit_width( max_index ) )

        for i = 1, entity_count, 1 do
            local entity = entity_list[ i ]
            if new_map[ entity ] == nil then
                local is_player = debug_getmetatable( entity ) == engine_Player
                hook_call( "dreamwork.entity.destroy", entity, is_player )

                if is_player then
                    hook_call( "dreamwork.client.destroy", entity )
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
    function engine_entity.getAll()
        return entity_list, entity_count
    end

    --- [SHARED AND MENU]
    ---
    ---
    ---
    ---@param fn fun( entity: garrysmod.Entity ): boolean?
    ---@return garrysmod.Entity | nil
    function engine_entity.peek( fn )
        for i = 1, entity_count, 1 do
            local entity = entity_list[ i ]
            if fn( entity ) then
                return entity
            end

            return nil
        end
    end

end
