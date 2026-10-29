---@meta dreamwork.std.console


---@alias dreamwork.std.console.VariableType "boolean" | "string" | "integer" | "number"
---@alias dreamwork.std.console.VariableValue boolean | number | string | integer


---@alias dreamwork.std.console.Command.SimpleAutoComplete fun( command: dreamwork.std.console.Command, argument_string: string, args: string[] ): string[]
---@alias dreamwork.std.console.Command.FullAutoComplete fun( command: dreamwork.std.console.Command, argument_string: string, args: string[] ): boolean, string[]
---@alias dreamwork.std.console.Command.AutoComplete dreamwork.std.console.Command.SimpleAutoComplete | dreamwork.std.console.Command.FullAutoComplete


---@class dreamwork.std.console.Command : dreamwork.std.Object
local Command = {}

---
--- The name of the console command/variable.
---
--- **READ-ONLY**
---
---@type string
Command.name = nil

---
--- The help text of the console command/variable.
---
--- **READ-ONLY**
---
---@type string?
Command.description = nil

---
--- The console command/variable flags.
---
--- Used in engine internally.
---
--- Links:
--- - [C++ Code](https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/sp/src/public/tier1/iconvar.h#L39)
--- - [Valve Wiki](https://developer.valvesoftware.com/wiki/Developer_Console_Control#The_FCVAR_flags)
--- - [Facepunch Wiki](https://wiki.facepunch.com/gmod/Enums/FCVAR)
---
--- **READ-ONLY**
---
---@type integer?
Command.flags = nil

---
--- If this is set, don't add to linked list, etc.
---
--- **READ-ONLY**
---
---@type boolean?
Command.unregistered = nil

---
--- Hidden in released products.
---
--- Flag is removed automatically if `ALLOW_DEVELOPMENT_CVARS` is defined in C++.
---
--- **READ-ONLY**
---
---@type boolean?
Command.development_only = nil

---
--- Defined by the game DLL.
---
--- **READ-ONLY**
---
---@type boolean?
Command.game_dll = nil

---
--- Defined by the client DLL.
---
--- **READ-ONLY**
---
---@type boolean?
Command.client_dll = nil

---
--- Doesn't appear in find or autocomplete.
---
--- Like `development_only`, but can't be compiled out.
---
--- **READ-ONLY**
---
---@type boolean?
Command.hidden = nil

---
--- It's a server cvar, but we don't send the data since it's a password, etc.
---
--- Sends `1` if it's not bland/zero, `0` otherwise as value.
---
--- **READ-ONLY**
---
---@type boolean?
Command.protected = nil

---
--- This cvar cannot be changed by clients connected to a multiplayer server.
---
--- **READ-ONLY**
---
---@type boolean?
Command.sponly = nil

---
--- Save the cvar value into either `client.vdf` or `server.vdf`.
---
--- **READ-ONLY**
---
---@type boolean?
Command.archive = nil

---
--- For server-side cvars, notifies all players with blue chat text when the value gets changed, also makes the convar appear in [A2S_RULES](https://developer.valvesoftware.com/wiki/Server_queries#A2S_RULES).
---
--- **READ-ONLY**
---
---@type boolean?
Command.notify = nil

---
--- For client-side commands, sends the value to the server.
---
--- **READ-ONLY**
---
---@type boolean?
Command.userinfo = nil

---
--- In multiplayer, prevents this command/variable from being used unless the server has `sv_cheats` turned on.
---
--- If a client connects to a server where cheats are disabled (which is the default), all client side console variables labeled as `cheat` are reverted to their default values and can't be changed as long as the client stays connected.
---
--- Console commands marked as `cheat` can't be executed either.
---
--- As a general rule of thumb, any client-side command that isn't specifically meant to be configured by users should be marked with this flag, as even the most harmless looking commands can sometimes be misused to cheat.
---
--- For server-side only commands you can be more lenient, since these would have no effect when changed by connected clients anyway.
---
--- **READ-ONLY**
---
---@type boolean?
Command.cheat = nil

---
--- This cvar's string cannot contain unprintable characters ( e.g., used for player name etc ).
---
--- **READ-ONLY**
---
---@type boolean?
Command.printable_only = nil

---
--- If this is a server-side, don't log changes to the log file / console if we are creating a log.
---
--- **READ-ONLY**
---
---@type boolean?
Command.unlogged = nil

---
--- Tells the engine to never print this console variable as a string.
---
--- This is used for variables which may contain control characters.
---
--- **READ-ONLY**
---
---@type boolean?
Command.never_as_string = nil

---
--- When set on a console variable, all connected clients will be forced to match the server-side value.
---
--- This should be used for shared code where it's important that both sides run the exact same path using the same data.
---
--- (e.g. predicted movement/weapons, game rules)
---
--- **READ-ONLY**
---
---@type boolean?
Command.replicated = nil

---
--- When starting to record a demo file, explicitly adds the value of this console variable to the recording to ensure a correct playback.
---
--- **READ-ONLY**
---
---@type boolean?
Command.demo = nil

---
--- Opposite of `DEMO`, ensures the cvar is not recorded in demos.
---
--- **READ-ONLY**
---
---@type boolean?
Command.dont_record = nil

---
--- If set and this variable changes, it forces a material reload.
---
--- **READ-ONLY**
---
---@type boolean?
Command.reload_materials = nil

---
--- If set and this variable changes, it forces a texture reload.
---
--- **READ-ONLY**
---
---@type boolean?
Command.reload_textures = nil

---
--- Prevents this variable from being changed while the client is currently in a server, due to the possibility of exploitation of the command (e.g. `fps_max`).
---
--- **READ-ONLY**
---
---@type boolean?
Command.not_connected = nil

---
--- Indicates this cvar is read from the material system thread.
---
--- **READ-ONLY**
---
---@type boolean?
Command.material_system_thread = nil

---
--- Like `archive`, but for [Xbox 360](https://de.wikipedia.org/wiki/Xbox_360).
---
--- Needless to say, this is not particularly useful to most modders.
---
--- Save the cvar value into `config.vdf` on XBox.
---
--- **READ-ONLY**
---
---@type boolean?
Command.archive_xbox = nil

---
--- Used as a debugging tool necessary to check material system thread convars.
---
--- **READ-ONLY**
---
---@type boolean?
Command.accessible_from_threads = nil

---
--- The server is allowed to execute this command on clients via `ClientCommand/NET_StringCmd/CBaseClientState::ProcessStringCmd`.
---
--- **READ-ONLY**
---
---@type boolean?
Command.server_can_execute = nil

---
--- If this is set, then the server is not allowed to query this cvar's value (via `IServerPluginHelpers::StartQueryCvarValue`).
---
--- **READ-ONLY**
---
---@type boolean?
Command.server_cannot_query = nil

---
--- `IVEngineClient::ClientCmd` is allowed to execute this command.
---
--- **READ-ONLY**
---
---@type boolean?
Command.clientcmd_can_execute = nil

---
--- Summary of `reload_materials`, `reload_textures` and `material_system_thread`.
---
--- **READ-ONLY**
---
---@type boolean?
Command.material_thread_mask = nil

---
--- Sets automatically on all cvars and console commands created by the `client` Lua state.
---
--- **READ-ONLY**
---
---@type boolean?
Command.lua_client = nil

---
--- Sets automatically on all cvars and console commands created by the `server` Lua state.
---
--- **READ-ONLY**
---
---@type boolean?
Command.lua_server = nil


--- [SHARED AND MENU]
---
--- Table used by `console.Command` class constructor.
---
---@class dreamwork.std.console.CommandOptions
local CommandOptions = {}

---
--- The name of the console command/variable.
---
---@type string
CommandOptions.name = nil

---
--- The help text of the console command/variable.
---
---@type string?
CommandOptions.description = nil

---
--- The console command/variable flags.
---
--- Used in engine internally.
---
--- [C++ Code](https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/sp/src/public/tier1/iconvar.h#L39)
---
--- [Valve Wiki](https://developer.valvesoftware.com/wiki/Developer_Console_Control#The_FCVAR_flags)
---
--- [Facepunch Wiki](https://wiki.facepunch.com/gmod/Enums/FCVAR)
---
---@type integer?
CommandOptions.flags = nil

---
--- If this is set, don't add to linked list, etc.
---
---@type boolean?
CommandOptions.unregistered = nil

---
--- Hidden in released products.
---
--- Flag is removed automatically if `ALLOW_DEVELOPMENT_CVARS` is defined in C++.
---
---@type boolean?
CommandOptions.development_only = nil

---
--- Defined by the game DLL.
---
---@type boolean?
CommandOptions.game_dll = nil

---
--- Defined by the client DLL.
---
---@type boolean?
CommandOptions.client_dll = nil

---
--- Doesn't appear in find or autocomplete.
---
--- Like `development_only`, but can't be compiled out.
---
---@type boolean?
CommandOptions.hidden = nil

---
--- It's a server cvar, but we don't send the data since it's a password, etc.
---
--- Sends `1` if it's not bland/zero, `0` otherwise as value.
---
---@type boolean?
CommandOptions.protected = nil

---
--- This cvar cannot be changed by clients connected to a multiplayer server.
---
---@type boolean?
CommandOptions.sponly = nil

---
--- Save the cvar value into either `client.vdf` or `server.vdf`.
---
---@type boolean?
CommandOptions.archive = nil

---
--- For server-side cvars, notifies all players with blue chat text when the value gets changed, also makes the convar appear in [A2S_RULES](https://developer.valvesoftware.com/wiki/Server_queries#A2S_RULES).
---
---@type boolean?
CommandOptions.notify = nil

---
--- For client-side commands, sends the value to the server.
---
---@type boolean?
CommandOptions.userinfo = nil

---
--- In multiplayer, prevents this command/variable from being used unless the server has `sv_cheats` turned on.
---
--- If a client connects to a server where cheats are disabled (which is the default), all client side console variables labeled as `cheat` are reverted to their default values and can't be changed as long as the client stays connected.
---
--- Console commands marked as `cheat` can't be executed either.
---
--- As a general rule of thumb, any client-side command that isn't specifically meant to be configured by users should be marked with this flag, as even the most harmless looking commands can sometimes be misused to cheat.
---
--- For server-side only commands you can be more lenient, since these would have no effect when changed by connected clients anyway.
---
---@type boolean?
CommandOptions.cheat = nil

---
--- This cvar's string cannot contain unprintable characters ( e.g., used for player name etc ).
---
---@type boolean?
CommandOptions.printable_only = nil

---
--- If this is a server-side, don't log changes to the log file / console if we are creating a log.
---
---@type boolean?
CommandOptions.unlogged = nil

---
--- Tells the engine to never print this console variable as a string.
---
--- This is used for variables which may contain control characters.
---
---@type boolean?
CommandOptions.never_as_string = nil

---
--- When set on a console variable, all connected clients will be forced to match the server-side value.
---
--- This should be used for shared code where it's important that both sides run the exact same path using the same data.
---
--- (e.g. predicted movement/weapons, game rules)
---
---@type boolean?
CommandOptions.replicated = nil

---
--- When starting to record a demo file, explicitly adds the value of this console variable to the recording to ensure a correct playback.
---
---@type boolean?
CommandOptions.demo = nil

---
--- Opposite of `DEMO`, ensures the cvar is not recorded in demos.
---
---@type boolean?
CommandOptions.dont_record = nil

---
--- If set and this variable changes, it forces a material reload.
---
---@type boolean?
CommandOptions.reload_materials = nil

---
--- If set and this variable changes, it forces a texture reload.
---
---@type boolean?
CommandOptions.reload_textures = nil

---
--- Prevents this variable from being changed while the client is currently in a server, due to the possibility of exploitation of the command (e.g. `fps_max`).
---
---@type boolean?
CommandOptions.not_connected = nil

---
--- Indicates this cvar is read from the material system thread.
---
---@type boolean?
CommandOptions.material_system_thread = nil

---
--- Like `archive`, but for [Xbox 360](https://de.wikipedia.org/wiki/Xbox_360).
---
--- Needless to say, this is not particularly useful to most modders.
---
--- Save the cvar value into `config.vdf` on XBox.
---
---@type boolean?
CommandOptions.archive_xbox = nil

---
--- Used as a debugging tool necessary to check material system thread convars.
---
---@type boolean?
CommandOptions.accessible_from_threads = nil

---
--- The server is allowed to execute this command on clients via `ClientCommand/NET_StringCmd/CBaseClientState::ProcessStringCmd`.
---
---@type boolean?
CommandOptions.server_can_execute = nil

---
--- If this is set, then the server is not allowed to query this cvar's value (via `IServerPluginHelpers::StartQueryCvarValue`).
---
---@type boolean?
CommandOptions.server_cannot_query = nil

---
--- `IVEngineClient::ClientCmd` is allowed to execute this command.
---
---@type boolean?
CommandOptions.clientcmd_can_execute = nil

---
--- Summary of `reload_materials`, `reload_textures` and `material_system_thread`.
---
---@type boolean?
CommandOptions.material_thread_mask = nil

---
--- Set automatically on all cvars and console commands created by the `client` Lua state.
---
---@type boolean?
CommandOptions.lua_client = nil

---
--- Set automatically on all cvars and console commands created by the `server` Lua state.
---
---@type boolean?
CommandOptions.lua_server = nil


--- [SHARED AND MENU]
---
--- Table used by `console.Variable` class constructor.
---
---@class dreamwork.std.console.VariableOptions : dreamwork.std.console.CommandOptions
local VariableOptions = {}

---
--- The type of the console variable.
---
---@type dreamwork.std.console.VariableType?
VariableOptions.type = nil

---
--- The default value of the console variable.
---
---@type dreamwork.std.console.VariableValue?
VariableOptions.default = nil

---
--- The minimal value of the console variable.
---
---@type number?
VariableOptions.min = nil

---
--- The maximum value of the console variable.
---
---@type number?
VariableOptions.max = nil


---@class dreamwork.std.console.Variable : dreamwork.std.console.Command
local Variable = {}

---
--- The type of the console variable.
---
---@type dreamwork.std.console.VariableType
Variable.type = nil

---
--- The default value of the console variable.
---
--- **READ-ONLY**
---
---@type dreamwork.std.console.VariableValue
Variable.default = nil

---
--- The value of the console variable.
---
---@type dreamwork.std.console.VariableValue
Variable.value = nil

---
--- The minimal value of the console variable.
---
--- **READ-ONLY**
---
---@type number | nil
Variable.min = nil

---
--- The maximum value of the console variable.
---
--- **READ-ONLY**
---
---@type number | nil
Variable.max = nil


--- [SHARED AND MENU]
---
--- Table used by `console.Logger` constructor.
---
---@class dreamwork.std.console.LoggerOptions
local LoggerOptions = {}

---
--- The title of the logger.
---
---@type string | nil
LoggerOptions.title = nil

---
--- The color of the title.
---
---@type dreamwork.std.Color | nil
LoggerOptions.color = nil

---
--- The color of the text.
---
---@type dreamwork.std.Color | nil
LoggerOptions.text_color = nil

---
--- Whether to interpolate the message.
---
---@type boolean | nil
LoggerOptions.interpolation = nil

---
--- The developer mode check function.
---
---@type ( fun(): boolean ) | nil
LoggerOptions.debug = nil
