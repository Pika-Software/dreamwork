local dreamwork_engine = dreamwork.engine
local engine_hook = dreamwork_engine.hook

local engine_Player = dreamwork_engine.Player
local engine_Entity = dreamwork_engine.Entity

local std = dreamwork.std

local raw = std.raw
local raw_set = raw.set
local raw_next = raw.next

local isType = std.isType
local errorf = std.errorf


---@class dreamwork.std.gc
local gc = std.gc

---
--- The kind of object whose destruction clears the tracked table.
---
---@alias dreamwork.std.gc.Type
---| "Entity" # The entity object, any removed entity.
---| "EntityID" # The entity index (`integer`), any removed networked entity.
---| "Player" # The player object, any removed player.
---| "UserID" # The player user id (`integer`), any removed player.
---| "SteamID32" # The player Steam steam id32 (`integer`), any removed non-bot player.

--- Maps the destroyed object to the key that must be removed from the tracked table.
---
--- Returning `nil` or `false` falls back to the destroyed object itself.
---
---@alias dreamwork.std.gc.Instruction fun( object: garrysmod.Entity | garrysmod.Player | integer ): any

--- Tracked tables by type, each tracked table maps to its instruction or `false`.
---
--- Keys are weak, so tracking does not keep tables alive.
---
---@type table<dreamwork.std.gc.Type, table<table, dreamwork.std.gc.Instruction | false>>
local track_list = {}

do

    local types = { "Entity", "EntityID", "Player", "UserID", "SteamID32" }

    for i = 1, #types, 1 do
        local tables = {}
        gc.setTableRules( tables, true, false )
        track_list[ types[ i ] ] = tables
    end

end

--- [SHARED]
---
--- Registers the table for automatic cleanup: when an object of the given type is destroyed,
--- its key is removed from the table with `raw.set`, bypassing `__newindex`.
---
--- Calling it again with the same table and type replaces the instruction,
--- one table can be registered for several types.
---
--- > NOTE: The registry does not keep the table alive, but LuaJIT weak tables are not ephemerons,
--- > so an `instruction` that captures `tbl` as an upvalue keeps it alive forever.
---
--- > NOTE: The `instruction` is called during the entity removal and must not call `gc.setup` or raise errors,
--- > an error skips the cleanup of the remaining tables.
---
---@param tbl table The table to clean up.
---@param type_name dreamwork.std.gc.Type The type of objects used as keys in the table.
---@param instruction dreamwork.std.gc.Instruction? The function that maps the destroyed object to the key, by default the object itself is the key.
function gc.setup( tbl, type_name, instruction )
    local tables = track_list[ type_name ]
    if tables == nil then
        errorf( "unknown gc type '%s'", type_name )
    end

    tables[ tbl ] = instruction or false
end

--- [SHARED]
---
--- Stops the automatic cleanup of the table for the given type.
---
---@param tbl table The table to stop cleaning up.
---@param type_name dreamwork.std.gc.Type The type the table was registered with.
function gc.unsetup( tbl, type_name )
    local tables = track_list[ type_name ]
    if tables == nil then
        errorf( "unknown gc type '%s'", type_name )
    end

    tables[ tbl ] = nil
end

---@param type_name dreamwork.std.gc.Type
---@param object garrysmod.Entity | garrysmod.Player | integer
local function object_destroyed( type_name, object )
    for tbl, instruction in raw_next, track_list[ type_name ] do
        local key
        if instruction then
            key = instruction( object )
        end

        raw_set( tbl, key or object, nil )
    end
end

do

    local Player_AccountID = engine_Player.AccountID
    local Player_UserID = engine_Player.UserID
    local Player_IsBot = engine_Player.IsBot

    local Entity_EntIndex = engine_Entity.EntIndex

    -- the lowest priority, so other handlers still can read the data of the removed entity
    engine_hook.catch( "EntityRemoved", "gc.setup", function( entity, is_full_update )
        -- the client may recreate the same entity object after a full update
        if is_full_update then return end

        object_destroyed( "Entity", entity )

        -- clientside entities share the index -1
        local index = Entity_EntIndex( entity )
        if index > 0 then
            object_destroyed( "EntityID", index )
        end

        if isType( entity, engine_Player ) then
            ---@cast entity garrysmod.Player

            object_destroyed( "Player", entity )
            object_destroyed( "UserID", Player_UserID( entity ) )

            if not Player_IsBot( entity ) then
                local steamid32 = Player_AccountID( entity )
                if steamid32 ~= nil then
                    object_destroyed( "SteamID32", steamid32 )
                end
            end
        end
    end, -1000 )

end
