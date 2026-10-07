---@type fun( name: string ): boolean
---@diagnostic disable-next-line: undefined-global
local IsConCommandBlocked = IsConCommandBlocked or function( str ) return false end

local std = dreamwork.std

---@class dreamwork.std.console
local console = std.console

local engine = dreamwork.engine
local engine_hookCall = engine.hookCall
local engine_consoleCommandRun = engine.consoleCommandRun
local engine_consoleCommandRegister = engine.consoleCommandRegister

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
local represent = std.represent
local setmetatable = std.setmetatable

local Hook = std.Hook

---@type table<dreamwork.std.console.Command | dreamwork.std.console.Variable, string>
local names = {}
gc_setTableRules( names, true, false )

---@type table<dreamwork.std.console.Command | dreamwork.std.console.Variable, string>
local descriptions = {}
gc_setTableRules( descriptions, true, false )

---@type table<dreamwork.std.console.Command | dreamwork.std.console.Variable, integer>
local flags = {}
gc_setTableRules( flags, true, false )

---@type table<dreamwork.std.console.Command, dreamwork.std.Hook<dreamwork.std.console.Command>>
local hooks = {}

setmetatable( hooks, {
    __index = function( self, command )
        local hook = Hook( represent( command ) )
        self[ command ] = hook
        return hook
    end,
    __mode = "k"
} )

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

---@return string
---@protected
function Command:__tostring()
    return string_format( "%s: %p [%s]", type( self ), self, names[ self ] )
end

---@param options dreamwork.std.console.CommandOptions
---@private
function Command:__init( options )
    local name = options.name
    local description = options.description or "description not provided"

    local int32_flags = console.flags( options.flags or 0, options )
    engine_consoleCommandRegister( name, description, int32_flags )

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
    end

    error( "attempt to write to read-only or non-existent field '" .. tostring( key ) .. "'", 2 )
end

--- [SHARED AND MENU]
---
--- The console command class.
---
---@class dreamwork.std.console.CommandClass : dreamwork.std.Class
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
function CommandClass.get( name )
    return commands[ name ]
end

CommandClass.exists = engine.consoleCommandExists
CommandClass.run = engine_consoleCommandRun

--- [SHARED AND MENU]
---
--- Runs the console command.
---
---@param ... string The arguments to pass to the console command.
function Command:run( ... )
    local name = names[ self ]
    if name == nil then return end

    engine_consoleCommandRun( name, ... )
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
local function isBlacklisted( name )
    return IsConCommandBlocked( name )
end

CommandClass.isBlacklisted = isBlacklisted

--- [SHARED AND MENU]
---
--- Returns whether the console command is blacklisted.
---
---@return boolean is_blacklisted `true` if the console command is blacklisted, `false` otherwise.
function Command:isBlacklisted()
    local name = names[ self ]
    if name == nil then
        return false
    end

    return isBlacklisted( name )
end

--- [SHARED AND MENU]
---
--- Attaches a handler function to the given stage of the hook.
--- If the handler is already attached to that stage, only its priority is
--- updated (when a new one is supplied); it will not be attached twice.
---
--- If the hook is currently running, the change is deferred and applied once
--- the hook finishes running.
---
---@param handler fun( client: Player, args: string[], argument_string: string )
function Command:attach( handler )
    hooks[ self ]:attach( "peek", handler )
end

--- [SHARED AND MENU]
---
--- Attaches a handler function to the hook that automatically detaches
--- itself right before being invoked, so it only ever runs once.
---
---@param handler fun( client: Player, args: string[], argument_string: string )
function Command:once( handler )
    hooks[ self ]:once( "peek", handler )
end

--- [SHARED AND MENU]
---
--- Detaches a previously attached handler from the given stage of the hook.
--- If the hook is currently running, the handler is replaced with a no-op and
--- the actual removal is deferred until the hook finishes running.
---
---@param handler fun( client: Player, args: string[], argument_string: string )
function Command:detach( handler )
    hooks[ self ]:detach( "peek", handler )
end

--- [SHARED AND MENU]
---
--- Cancels the hook if it is currently running, and removes every handler,
--- resetting their priority tables as well.
---
function Command:clear()
    hooks[ self ]:clear()
end

--- [SHARED AND MENU]
---
--- Waits for the console command to be executed.
---
---@async
function Command:await()
    return hooks[ self ]:await( "peek" )
end

---@param error_value string | dreamwork.std.Error
local function error_handler( error_value )
    return engine_hookCall( "dreamwork.lua.error", error_value, 2 )
end

engine.hookCatch( "dreamwork.console.command.execute", "console.handle", function( client, name, args, argument_string )
    local command = commands[ name ]
    if command == nil then
        return nil
    end

    if string_byte( argument_string, 1 ) == 0x22 --[[ "\"" ]] and string_byte( argument_string, -1 ) == 0x22 --[[ "\"" ]] then
        argument_string = string_sub( argument_string, 2, -2 )
    end

    -- TODO: review this after client class will be created
    local hook = hooks[ command ]
    xpcall( hook.call, error_handler, hook, client, args, argument_string )

    return true
end, -500 )

engine.hookCatch( "dreamwork.console.command.autocomplete", "console.autocomplete", function( name, argument_string, args )
    local command = commands[ name ]
    if command == nil then return end

    local fn = autocomplete[ command ]
    if fn == nil then return end

    local success, value1, value2 = xpcall( fn, error_handler, command, argument_string, args )
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
