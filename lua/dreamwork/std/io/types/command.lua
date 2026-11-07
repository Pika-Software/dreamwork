local exceptions_call = dreamwork.exceptions.call
local dreamwork_engine = dreamwork.engine

local engine_hook = dreamwork_engine.hook

local engine_console = dreamwork_engine.console
local console_commandRun = engine_console.commandRun
local console_commandBlocked = engine_console.commandBlocked
local console_commandRegister = engine_console.commandRegister

local std = dreamwork.std

---@class dreamwork.std.console
local console = std.console

local raw = std.raw
local raw_index = raw.index

local debug = std.debug
local debug_fempty = debug.fempty

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local string = std.string
local string_sub = string.sub
local string_byte = string.byte
local string_format = string.format

local bit = std.bit
local bit_band = bit.band

local class = std.class

local type = std.type
local error = std.error
local tostring = std.tostring

local Emitter = std.Emitter

---@type table<dreamwork.std.console.Command | dreamwork.std.console.Variable, string>
local names = {}
gc_setTableRules( names, true, false )

---@type table<dreamwork.std.console.Command | dreamwork.std.console.Variable, string>
local descriptions = {}
gc_setTableRules( descriptions, true, false )

---@type table<dreamwork.std.console.Command | dreamwork.std.console.Variable, integer>
local flags = {}
gc_setTableRules( flags, true, false )

--- Command `"execute"` handlers.
local events = Emitter( "console.Command" )

---@type table<string, dreamwork.std.console.Command>
local commands = {}
gc_setTableRules( commands, false, true )

---@type table<dreamwork.std.console.Command, dreamwork.std.console.Command.AutoComplete>
local autocomplete = {}
gc_setTableRules( autocomplete, true, false )

--- [SHARED AND MENU]
---
--- The console command object.
---
---@class dreamwork.std.console.Command : dreamwork.std.Object
---@field __class dreamwork.std.console.Command
---@field name string The name of the command.
---@field description string The description of the command.
---@field flags integer The flags of the command.
---@field autocomplete dreamwork.std.console.Command.AutoComplete | nil The auto-complete function of the command.
local Command = class.base( "console.Command", true, nil )

---@return string
---@protected
function Command:__represent()
    return string_format( "%s: %p [%s]", type( self ), self, self.name )
end

---@param options dreamwork.std.console.CommandOptions
---@private
function Command:__init( options )
    local name = options.name
    local description = options.description or "description not provided"

    local int32_flags = console.flags( options.flags or 0, options )
    console_commandRegister( name, description, int32_flags )

    names[ self ] = name
    descriptions[ self ] = description
    flags[ self ] = int32_flags

    commands[ name ] = self
end

---@param key string
---@return any
---@protected
function Command:__index( key )
    if key == "name" then
        return names[ self ] or "unknown"
    elseif key == "description" then
        return descriptions[ self ] or "unknown"
    elseif key == "flags" then
        return flags[ self ] or 0
    elseif key == "autocomplete" then
        return autocomplete[ self ]
    end

    local int32_flag = console.flag( key )
    if int32_flag == nil then
        return raw_index( Command, key )
    end

    return bit_band( flags[ self ], int32_flag ) ~= 0
end

---@param key string
---@param value any
---@protected
function Command:__newindex( key, value )
    if key == "autocomplete" then
        std.checktype( 3, value, "function" )
        autocomplete[ self ] = value
        return
    end

    error( "attempt to write to read-only or non-existent field '" .. tostring( key ) .. "'", 2 )
end

--- [SHARED AND MENU]
---
--- The console command class.
---
---@class dreamwork.std.console.CommandClass : dreamwork.std.console.Command, dreamwork.std.Class
---@field __base dreamwork.std.console.Command
---@overload fun( options: dreamwork.std.console.CommandOptions ): dreamwork.std.console.Command
local CommandClass = class.create( Command )
console.Command = CommandClass

---@param name string
---@return dreamwork.std.console.Command | nil
---@protected
function CommandClass:__new( name )
    return commands[ name ]
end

--- [SHARED AND MENU]
---
--- Returns the console command with the given name.
---
---@return dreamwork.std.console.Command | nil obj The console command with the given name, or `nil` if it does not exist.
---@nodiscard
function CommandClass.get( name )
    return commands[ name ]
end

CommandClass.exists = engine_console.commandExists
CommandClass.run = console_commandRun

--- [SHARED AND MENU]
---
--- Runs the console command.
---
---@param ... string The arguments to pass to the console command.
function Command:run( ... )
    local name = names[ self ]
    if name == nil then return end

    console_commandRun( name, ... )
end

if std.LUA_CLIENT_MENU then

    ---@class dreamwork.GModInputLibrary
    ---@field TranslateAlias fun( str: string ): string | nil
    ---@diagnostic disable-next-line: undefined-global
    local glua_input = input

    local input_TranslateAlias = glua_input.TranslateAlias or debug_fempty

    --- [CLIENT AND MENU]
    ---
    --- Translates a console command alias, basically reverse of the `alias` console command.
    ---
    ---@param str string The alias to lookup.
    ---@return string | nil cmd The command(s) this alias will execute if ran, or nil if the alias doesn't exist.
    ---@nodiscard
    function CommandClass.translateAlias( str )
        return input_TranslateAlias( str )
    end

end

--- [SHARED AND MENU]
---
--- Checks if the console command is blacklisted.
---
---@param name string The name of the console command.
---@return boolean is_blacklisted `true` if the console command is blacklisted, `false` otherwise.
---@nodiscard
function CommandClass.isBlacklisted( name )
    return console_commandBlocked( name )
end

--- [SHARED AND MENU]
---
--- Returns whether the console command is blacklisted.
---
---@return boolean is_blacklisted `true` if the console command is blacklisted, `false` otherwise.
---@nodiscard
function Command:isBlacklisted()
    local name = names[ self ]
    if name == nil then
        return false
    end

    return console_commandBlocked( name )
end

--- [SHARED AND MENU]
---
--- Attaches a handler called on every execution of the command, attaching the same handler twice is a no-op.
---
--- Handlers run in protected mode, one failing handler is reported and never stops the others.
---
---@param handler dreamwork.std.console.Command.Callback | dreamwork.std.Hook | dreamwork.std.Event The callback or callable object.
function Command:attach( handler )
    events:attach( self, "execute", handler )
end

--- [SHARED AND MENU]
---
--- Attaches a one-shot handler, detached right before the next execution calls it.
---
---@param handler dreamwork.std.console.Command.Callback | dreamwork.std.Hook | dreamwork.std.Event The callback or callable object.
function Command:once( handler )
    events:once( self, "execute", handler )
end

--- [SHARED AND MENU]
---
--- Detaches a handler previously passed to `attach` or `once`.
---
---@param handler dreamwork.std.console.Command.Callback | dreamwork.std.Hook | dreamwork.std.Event The exact handler reference.
---@return boolean removed `true` if the handler was attached.
function Command:detach( handler )
    return events:detach( self, "execute", handler )
end

--- [SHARED AND MENU]
---
--- Removes every handler of the command, pending handlers of a running execution are skipped.
---
function Command:clear()
    events:clear( self )
end

--- [SHARED AND MENU]
---
--- Waits for the console command to be executed.
---
---@return dreamwork.std.console.Command command
---@return garrysmod.Player | nil client
---@return string[] args
---@return string argument_string
---@async
function Command:await()
    return events:await( self, "execute" )
end

---@param client garrysmod.Player | nil
---@param name string
---@param argument_string string
---@param args string[]
engine_hook.catch( "dreamwork.console.command.execute", "console.handle", function( client, name, args, argument_string )
    local command = commands[ name ]
    if command == nil then
        return nil
    end

    if string_byte( argument_string, 1 ) == 0x22 --[[ "\"" ]] and string_byte( argument_string, -1 ) == 0x22 --[[ "\"" ]] then
        argument_string = string_sub( argument_string, 2, -2 )
    end

    -- TODO: review this after client class will be created

    events:emit( command, "execute", command, client, args, argument_string )

    return true
end, -500 )

---@param name string
---@param argument_string string
---@param args string[]
engine_hook.catch( "dreamwork.console.command.autocomplete", "console.autocomplete", function( name, argument_string, args )
    local command = commands[ name ]
    if command == nil then return end

    local fn = autocomplete[ command ]
    if fn == nil then return end

    local success, value1, value2 = exceptions_call( fn, command, argument_string, args )
    if not success or value1 == nil then return end

    if value1 == false then
        return value2
    end

    local prefix = name .. " "

    ---@type string[]
    local suggestions = {}

    if value1 == true and value2 ~= nil then
        ---@cast value1 boolean
        ---@cast value2 string[]
        for i = 1, #value2, 1 do
            suggestions[ i ] = prefix .. value2[ i ]
        end

        return suggestions
    end

    ---@cast value1 string[]
    for i = 1, #value1, 1 do
        suggestions[ i ] = prefix .. value1[ i ]
    end

    return suggestions
end, -1000 )
