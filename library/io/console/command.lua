---@meta _

--- [SHARED AND MENU]
---
--- The console command object.
---
---@class console.Command : Object
---@field __class console.Command
---@field name string The name of the command.
---@field description string The description of the command.
---@field flags integer The flags of the command.
---@field autocomplete console.Command.AutoComplete | nil The auto-complete function of the command.
local Command = {}

---@return string
---@protected
function Command:__represent() end

---@param key string
---@return any
---@protected
function Command:__index(key) end

---@param key string
---@param value any
---@protected
function Command:__newindex(key, value) end

--- [SHARED AND MENU]
---
--- The console command class.
---
---@class console.CommandClass : Class
---@field __base console.Command
---@overload fun( options: console.CommandOptions ): console.Command
console.Command = {}

---@param name string
---@return console.Command | nil
---@protected
function console.Command:__new(name) end

--- [SHARED AND MENU]
---
--- Returns the console command with the given name.
---
---@return console.Command | nil obj The console command with the given name, or `nil` if it does not exist.
---@nodiscard
function console.Command.get(name) end

--- [SHARED AND MENU]
---
--- Runs the console command.
---
---@param ... string The arguments to pass to the console command.
function Command:run(...) end

---@class dreamwork.GModInputLibrary
---@field TranslateAlias fun( str: string ): string | nil
local glua_input = {}

--- [CLIENT AND MENU]
---
--- Translates a console command alias, basically reverse of the `alias` console command.
---
---@param str string The alias to lookup.
---@return string | nil cmd The command(s) this alias will execute if ran, or nil if the alias doesn't exist.
---@nodiscard
function console.Command.translateAlias(str) end

--- [SHARED AND MENU]
---
--- Checks if the console command is blacklisted.
---
---@param name string The name of the console command.
---@return boolean is_blacklisted `true` if the console command is blacklisted, `false` otherwise.
---@nodiscard
function console.Command.isBlacklisted(name) end

--- [SHARED AND MENU]
---
--- Returns whether the console command is blacklisted.
---
---@return boolean is_blacklisted `true` if the console command is blacklisted, `false` otherwise.
---@nodiscard
function Command:isBlacklisted() end

--- [SHARED AND MENU]
---
--- Attaches a handler function to the given stage of the hook.
--- If the handler is already attached to that stage, only its priority is
--- updated (when a new one is supplied); it will not be attached twice.
---
--- If the hook is currently running, the change is deferred and applied once
--- the hook finishes running.
---
---@param handler fun( client: garrysmod.Player, args: string[], argument_string: string )
function Command:attach(handler) end

--- [SHARED AND MENU]
---
--- Attaches a handler function to the hook that automatically detaches
--- itself right before being invoked, so it only ever runs once.
---
---@param handler fun( client: garrysmod.Player, args: string[], argument_string: string )
function Command:once(handler) end

--- [SHARED AND MENU]
---
--- Detaches a previously attached handler from the given stage of the hook.
--- If the hook is currently running, the handler is replaced with a no-op and
--- the actual removal is deferred until the hook finishes running.
---
---@param handler fun( client: garrysmod.Player, args: string[], argument_string: string )
function Command:detach(handler) end

--- [SHARED AND MENU]
---
--- Cancels the hook if it is currently running, and removes every handler,
--- resetting their priority tables as well.
---
function Command:clear() end

--- [SHARED AND MENU]
---
--- Waits for the console command to be executed.
---
---@async
function Command:await() end
