---@meta _

---@class dreamwork.GModGUILibrary
---@field ShowConsole fun() | nil
---@field IsConsoleVisible ( fun(): boolean ) | nil
local glua_gui = {}

--- [SHARED AND MENU]
---
--- The source engine console library.
---
---@class console
---@field visible boolean `true` if the console is visible, `false` otherwise.
console = {}

--- [MENU]
---
--- Shows the console.
---
console.show = nil

--- [MENU]
---
--- Hides the console.
---
function console.hide() end

--- [MENU]
---
--- Toggles the console.
---
function console.toggle() end

--- [SHARED AND MENU]
---
--- Writes a message to the console.
---
---@param ... string | Color The message to write to the console.
function console.write(...) end

--- [SHARED AND MENU]
---
--- Writes a message to the console with new line after the text.
---
---@param ... string | Color The message to write to the console.
function console.writeLine(...) end

--- [SHARED AND MENU]
---
--- Clears the console output.
---
function console.clear() end

---@alias console.Flags
---| "unregistered"
---| "development_only"
---| "game_dll"
---| "client_dll"
---| "hidden"
---| "protected"
---| "sponly"
---| "archive"
---| "notify"
---| "userinfo"
---| "cheat"
---| "printable_only"
---| "unlogged"
---| "never_as_string"
---| "replicated"
---| "demo"
---| "dont_record"
---| "reload_materials"
---| "reload_textures"
---| "not_connected"
---| "material_system_thread"
---| "archive_xbox"
---| "accessible_from_threads"
---| "server_can_execute"
---| "server_cannot_query"
---| "clientcmd_can_execute"
---| "material_thread_mask"
---| "lua_client"
---| "lua_server"

---@class console.Flag
---@field [1] console.Flags
---@field [2] integer flag

--- [SHARED AND MENU]
---
--- Returns the integer flag value for the given flag name.
---
---
---@param flag_name console.Flags
---@return integer int32_flag
---@nodiscard
function console.flag(flag_name) end

--- [SHARED AND MENU]
---
--- Builds an integer flag value from the given flag map.
---
---@param int32_flags integer
---@param flag_map table<console.Flags, boolean>
---@return integer flag
---@nodiscard
function console.flags(int32_flags, flag_map) end
