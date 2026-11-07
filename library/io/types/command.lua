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
---@class console.CommandClass : console.Command, Class
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
--- Attaches a handler called on every execution of the command, attaching the same handler twice is a no-op.
---
--- Handlers run in protected mode, one failing handler is reported and never stops the others.
---
---@param handler console.Command.Callback | Hook | Event The callback or callable object.
function Command:attach(handler) end

--- [SHARED AND MENU]
---
--- Attaches a one-shot handler, detached right before the next execution calls it.
---
---@param handler console.Command.Callback | Hook | Event The callback or callable object.
function Command:once(handler) end

--- [SHARED AND MENU]
---
--- Detaches a handler previously passed to `attach` or `once`.
---
---@param handler console.Command.Callback | Hook | Event The exact handler reference.
---@return boolean removed `true` if the handler was attached.
function Command:detach(handler) end

--- [SHARED AND MENU]
---
--- Removes every handler of the command, pending handlers of a running execution are skipped.
---
function Command:clear() end

--- [SHARED AND MENU]
---
--- Waits for the console command to be executed.
---
---@return console.Command command
---@return garrysmod.Player | nil client
---@return string[] args
---@return string argument_string
---@async
function Command:await() end
