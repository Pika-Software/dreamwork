---@meta garrysmod.console


--- [SHARED AND MENU]
---
--- An object returned by [Global.CreateConVar](https://wiki.facepunch.com/gmod/Global.CreateConVar) or [Global.GetConVar](https://wiki.facepunch.com/gmod/Global.GetConVar).
---
--- It represents a given console variable.
---
---@class garrysmod.console.Variable : metatable
local Variable = {}

--- [SHARED AND MENU]
---
--- Tries to convert the current string value of a ConVar to a boolean.
---
---@return boolean value The boolean value of the console variable. If the variable is numeric and not 0, the result will be `true`. Otherwise the result will be `false`.
function Variable:GetBool() end

--- [SHARED AND MENU]
---
--- Returns the default value of the ConVar.
---
---@return string default The default value of the console variable.
function Variable:GetDefault() end

--- [SHARED AND MENU]
---
--- Returns the [FCVAR](https://wiki.facepunch.com/gmod/Enums/FCVAR) flags of the ConVar.
---
---@return integer flags The bitflag of the console variable.
function Variable:GetFlags() end

--- [SHARED AND MENU]
---
--- Attempts to convert the ConVar value to a float.
---
---@return number value The float value of the console variable. If the value cannot be converted to a float, it will return `0`.
function Variable:GetFloat() end

--- [SHARED AND MENU]
---
--- Returns the help text assigned to that convar.
---
---@return string description The help text.
function Variable:GetHelpText() end

--- [SHARED AND MENU]
---
--- Attempts to convert the ConVar value to an integer.
---
---@return integer value The integer value of the console variable. If it fails to convert to an integer, it will return `0`. All float/decimal values will be rounded down. (With `math.floor`)
function Variable:GetInt() end

--- [SHARED AND MENU]
---
--- Returns the maximum value of the ConVar.
---
---@return number max The maximum value of the console variable.
function Variable:GetMax() end

--- [SHARED AND MENU]
---
--- Returns the minimum value of the ConVar.
---
---@return number min The minimum value of the console variable.
function Variable:GetMin() end

--- [SHARED AND MENU]
---
--- Returns the name of the ConVar.
---
---@return string name The name of the console variable.
function Variable:GetName() end

--- [SHARED AND MENU]
---
--- Returns the current ConVar value as a string.
---
---@return string value The current console variable value as a string.
function Variable:GetString() end

--- [SHARED AND MENU]
---
--- Returns whether the specified flag is set on the ConVar.
---
---@param flag integer The [FCVAR](https://wiki.facepunch.com/gmod/Enums/FCVAR) flag to test.
---@return boolean is_set Whether the flag is set or not.
function Variable:IsFlagSet( flag ) end

--- [SHARED AND MENU]
---
--- Reverts ConVar to its default value.
---
function Variable:Revert() end

--- [SHARED AND MENU]
---
--- Sets a ConVar's value to `1` or `0` based on the input boolean.
---
--- This can only be ran on ConVars created from within Lua.
---
---@param value boolean Value to set the ConVar to.
function Variable:SetBool( value ) end

--- [SHARED AND MENU]
---
--- Sets a ConVar's value to the input number.
---
--- This can only be ran on ConVars created from within Lua.
---
---@param value number Value to set the ConVar to.
function Variable:SetFloat( value ) end

--- [SHARED AND MENU]
---
--- Sets a ConVar's value to the input number after converting it to an integer.
---
--- This can only be ran on ConVars created from within Lua.
---
---@param value integer Value to set the ConVar to.
function Variable:SetInt( value ) end

--- [SHARED AND MENU]
---
--- Sets a ConVar's value to the input string.
---
--- This can only be ran on ConVars created from within Lua.
---
---@param value string Value to set the ConVar to.
function Variable:SetString( value ) end

--- [SHARED AND MENU]
---
--- Creates a console variable (ConVar), in general these are for things like gamemode/server settings.
---
--- Do not use the `FCVAR_NEVER_AS_STRING` and `FCVAR_REPLICATED` flags together, as this can cause the console variable to have strange values on the client.
---
---@param name string Name of the ConVar. This cannot be a name of an engine console command or console variable. It will throw an error if it is.
---@param value string Default value of the convar.
---@param flags ( integer | integer[] | nil ) Flags of the convar, see [FCVAR](https://wiki.facepunch.com/gmod/Enums/FCVAR), either as bitflag or as table.
---@param description ( string | nil ) The help text to show in the console.
---@param min_value ( number | nil ) If set, the ConVar cannot be changed to a number lower than this value.
---@param max_value ( number | nil ) If set, the ConVar cannot be changed to a number higher than this value.
---@return garrysmod.console.Variable | nil cvar The convar created.
function CreateConVar( name, value, flags, description, min_value, max_value ) end

--- [SHARED AND MENU]
---
--- Gets the ConVar with the specified name.
---
--- This function uses [Global.GetConVar_Internal](https://wiki.facepunch.com/gmod/Global.GetConVar_Internal) internally, but caches the result in Lua for quicker lookups.
---
---@param name string Name of the ConVar to get.
---@return garrysmod.console.Variable | nil cvar The ConVar object, or `nil` if no such ConVar was found.
function GetConVar( name ) end

--- [SHARED AND MENU]
---
--- Gets the ConVar with the specified name. This function doesn't cache the convar.
---
---@param name string Name of the ConVar to get.
---@return garrysmod.console.Variable | nil cvar The ConVar object, or `nil` if no such ConVar was found.
function GetConVar_Internal( name ) end

--- [SHARED AND MENU]
---
--- Returns whether a ConVar with the given name exists or not.
---
---@param name string Name of the ConVar.
---@return boolean exists `true` if the ConVar exists, `false` otherwise.
function ConVarExists( name ) end

--- [SHARED AND MENU]
---
--- Gets the numeric value ConVar with the specified name.
---
---@deprecated Store the ConVar object retrieved with [Global.GetConVar](https://wiki.facepunch.com/gmod/Global.GetConVar) and call [ConVar:GetInt](https://wiki.facepunch.com/gmod/ConVar:GetInt) or [ConVar:GetFloat](https://wiki.facepunch.com/gmod/ConVar:GetFloat) on it.
---
---@param name string Name of the ConVar to get.
---@return number value The ConVar's value.
function GetConVarNumber( name ) end

--- [SHARED AND MENU]
---
--- Gets the string value ConVar with the specified name.
---
---@deprecated Store the ConVar object retrieved with [Global.GetConVar](https://wiki.facepunch.com/gmod/Global.GetConVar) and call [ConVar:GetString](https://wiki.facepunch.com/gmod/ConVar:GetString) on it.
---
---@param name string Name of the ConVar to get.
---@return string value The ConVar's value.
function GetConVarString( name ) end

--- [SHARED AND MENU]
---
--- Tells the engine to register a console command.
---
--- If the command was ran, the engine calls [concommand.Run](https://wiki.facepunch.com/gmod/concommand.Run).
---
---@param name string The name of the console command to add.
---@param description string The help text.
---@param flags integer Concommand modifier flags. See [FCVAR](https://wiki.facepunch.com/gmod/Enums/FCVAR).
function AddConsoleCommand( name, description, flags ) end

--- [SHARED AND MENU]
---
--- Runs a console command.
---
--- Make sure to also check out [Player:ConCommand](https://wiki.facepunch.com/gmod/Player:ConCommand) on the client and [game.ConsoleCommand](https://wiki.facepunch.com/gmod/game.ConsoleCommand) on the server.
---
--- Due to the way this function works, the command will not be executed on the same tick but on the next one.
---
---@param name string The command to run.
---@param ... string Arguments for the command, each argument is converted to a string.
function RunConsoleCommand( name, ... ) end

--- [SHARED AND MENU]
---
--- Returns whether a console command is blocked.
---
---@param name string The name of the console command.
---@return boolean is_blocked Whether the command is blocked.
function IsConCommandBlocked( name ) end

--- [SHARED AND MENU]
---
--- The concommand library is used to create console commands which can be used to network (basic) information & events between the client and the server.
---
---@class garrysmod.concommand
concommand = {}

--- [SHARED AND MENU]
---
--- Called by the engine when a console command registered with [Global.AddConsoleCommand](https://wiki.facepunch.com/gmod/Global.AddConsoleCommand) is ran.
---
---@param pl garrysmod.Player The player who ran the console command, or a NULL entity if ran from the server console.
---@param cmd string The console command name.
---@param args string[] The arguments of the console command.
---@param argument_string string The arguments of the console command as a single string.
---@return boolean is_found Whether the console command was found and executed.
function concommand.Run( pl, cmd, args, argument_string ) end

--- [CLIENT AND MENU]
---
--- Called by the engine when the user is typing a console command to get its autocompletion suggestions.
---
---@param cmd string The console command name.
---@param argument_string string The arguments of the console command as a single string.
---@param args string[] The arguments of the console command.
---@return string[] | nil suggestions The autocompletion suggestions.
function concommand.AutoComplete( cmd, argument_string, args ) end
