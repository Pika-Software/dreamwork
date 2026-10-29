---@meta holylib.luathreads


--- [SHARED AND MENU]
---
--- This library lets you create extra, independent Lua interfaces **LuaInterface** objects
--- that can run their own code on a separate thread instead of sharing the main gamemode's Lua state.
---
--- This is useful to run heavy Lua code without blocking the main server thread.
---
---@class holylib.luathreads
luathreads = {}


--- [SHARED AND MENU]
---
--- This class represents a completely separate Lua interface (its own Lua state), created with `luathreads.CreateInterface`.
---
--- It can run its own code on a separate thread, independently from the main gamemode's Lua state.
---
--- > **NOTE**: Unlike most other HolyLib classes, this object is **not** automatically garbage collected.
--- > It's destroyed when HolyLib (or the Lua state that created it) shuts down.
---
---@class holylib.LuaInterface
local LuaInterface = {}

--- [SHARED AND MENU]
---
--- Returns weather this object is valid or not.
---
---@return boolean is_valid Returns `true` if this object is valid.
function LuaInterface:IsValid() end

--- [SHARED AND MENU]
---
--- Returns the lua table used by `__newindex` and `__index`.
---
---@return table luaTable Returns the Lua table.
function LuaInterface:GetTable() end

--- [SHARED AND MENU]
---
--- Returns whether this interface currently has its own dedicated thread running.
---
---@see holylib.LuaInterface.EnableThinking
---
---@return boolean hasThread Returns `true` if the interface has its own thread.
function LuaInterface:CanThink() end

--- [SHARED AND MENU]
---
--- Enables or disables this interface's own dedicated thread.
---
--- While enabled, the interface will continuously run its queued
--- tasks on its own thread, instead of needing `LuaInterface:RunTasks()`
--- to be called manually.
---
---@param enable boolean `true` to create and start the thread, `false` to stop and destroy it.
function LuaInterface:EnableThinking( enable ) end

--- [SHARED AND MENU]
---
--- Returns the name of this interface.
---
---@see holylib.LuaInterface.SetName
---
---@return string | "NONAME" name Name of the interface, `"NONAME"` by default.
function LuaInterface:GetName() end

--- [SHARED AND MENU]
---
--- Sets the name of this interface, which can later be used
--- with `luathreads.FindInterface()` to find it again.
---
---@param name string The new name of the interface.
function LuaInterface:SetName( name ) end

--- [SHARED AND MENU]
---
--- Queues this interface's pending tasks to run once
--- on HolyLib's `holylib_luathreads_threadpool` thread pool.
---
--- > **NOTE**: Does nothing if the interface already has its own dedicated thread running.
---
---@see holylib.LuaInterface.EnableThinking
---
function LuaInterface:RunTasks() end

--- [SHARED AND MENU]
---
--- Queues the given code to be run inside this interface.
---
--- The code only actually runs once this interface's tasks are executed,
--- either by its own thread
---
---@see holylib.LuaInterface.EnableThinking
---
---@see holylib.LuaInterface.RunTasks
---
---@param lua_code string The code to run in interface.
function LuaInterface:RunString( lua_code ) end

--- [SHARED AND MENU]
---
--- Creates a new, independent Lua interface.
---
--- It won't run on its own thread until `LuaInterface:EnableThinking( enabled )` is called,
--- or `LuaInterface:RunTasks()` is used to run its queued tasks on HolyLib's
--- thread pool instead.
---
---@return holylib.LuaInterface interface The newly created interface.
function luathreads.CreateInterface() end

--- [SHARED AND MENU]
---
--- Finds a `LuaInterface` by its name.
---
---@see holylib.LuaInterface.SetName
---
---@param name string Name of the interface to look for.
---@return holylib.LuaInterface | nil The found interface, or `nil` if none matched.
function luathreads.FindInterface( name ) end

--- [SHARED AND MENU]
---
--- Returns every currently existing `LuaInterface`.
---
---@return holylib.LuaInterface[] interfaces Table containing every existing `LuaInterface`
function luathreads.GetInterfaces() end
