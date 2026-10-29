---@meta _

---@alias gc.Type "Entity" | "EntityID" | "Player" | "UserID" | "AccountID"

---@alias gc.Instruction fun( object: any ): any

--- [SHARED AND MENU]
---
--- Sets up garbage collection for the given table by type.
---
---@param tbl table
---@param type_name gc.Type
---@param instruction gc.Instruction | nil
function gc.setup(tbl, type_name, instruction) end

---@class dreamwork.engine.ColorProxyClass : dreamwork.engine.ColorProxy
---@overload fun(r: number, g: number, b: number, a: number): dreamwork.engine.ColorProxy
ColorProxy = {}
