---@meta _

---
--- The kind of object whose destruction clears the tracked table.
---
---@alias gc.Type
---| "Entity" # The entity object, any removed entity.
---| "EntityID" # The entity index (`integer`), any removed networked entity.
---| "Player" # The player object, any removed player.
---| "UserID" # The player user id (`integer`), any removed player.
---| "SteamID32" # The player Steam steam id32 (`integer`), any removed non-bot player.

--- Maps the destroyed object to the key that must be removed from the tracked table.
---
--- Returning `nil` or `false` falls back to the destroyed object itself.
---
---@alias gc.Instruction fun( object: garrysmod.Entity | garrysmod.Player | integer ): any

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
---@param type_name gc.Type The type of objects used as keys in the table.
---@param instruction? gc.Instruction The function that maps the destroyed object to the key, by default the object itself is the key.
function gc.setup(tbl, type_name, instruction) end

--- [SHARED]
---
--- Stops the automatic cleanup of the table for the given type.
---
---@param tbl table The table to stop cleaning up.
---@param type_name gc.Type The type the table was registered with.
function gc.unsetup(tbl, type_name) end
