local std = dreamwork.std

local string = std.string
local string_sub = string.sub
local string_byte = string.byte

local bit_band = std.bit.band
local raw_index = std.raw.index
local debug_fempty = std.debug.fempty
local futures_Future = std.futures.Future
local gc_setTableRules = std.gc.setTableRules
local table_removeByRange = std.table.removeByRange

local engine = dreamwork.engine
local engine_consoleCommandRun = engine.consoleCommandRun
local engine_consoleCommandRegister = engine.consoleCommandRegister

---@class dreamwork.std.console
local console = std.console

---@type table<dreamwork.std.console.Command | dreamwork.std.console.Variable, string>
local names = {}

gc_setTableRules( names, true, false )

---@type table<dreamwork.std.console.Command | dreamwork.std.console.Variable, string>
local descriptions = {}

gc_setTableRules( descriptions, true, false )

---@type table<dreamwork.std.console.Command | dreamwork.std.console.Variable, integer>
local flags = {}

gc_setTableRules( flags, true, false )

---@type table<dreamwork.std.console.Command | dreamwork.std.console.Variable, table>
local callbacks = {}

gc_setTableRules( callbacks, true, false )

---@type table<string, dreamwork.std.console.Command>
local commands = {}

gc_setTableRules( commands, false, true )

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- The console command object.
---
---@class dreamwork.std.console.Command : dreamwork.std.Object
---@field __class dreamwork.std.console.Command
local Command = std.class.base( "console.Command", true )

---@protected
function Command:__index( str_key )
    if str_key == "name" then
        return names[ self ] or "unknown"
    elseif str_key == "description" then
        return descriptions[ self ] or "unknown"
    elseif str_key == "flags" then
        return flags[ self ] or 0
    end

    local int32_flag = console.flag( str_key )
    if int32_flag == nil then
        return raw_index( Command, str_key )
    end

    return bit_band( flags[ self ], int32_flag ) ~= 0
end

do

    ---@param options dreamwork.std.console.Command.Options
    ---@private
    function Command:__init( options )
        local name = options.name
        local description = options.description or "description not provided"

        local int32_flags = console.flags( options.flags or 0, options )

        engine_consoleCommandRegister( name, description, int32_flags )

        names[ self ] = name
        descriptions[ self ] = description
        flags[ self ] = int32_flags
        callbacks[ self ] = {}
        commands[ name ] = self
    end

end

---@return string
---@protected
function Command:__tostring()
    return string.format( "console.Command: %p [%s][%s]", self, names[ self ], descriptions[ self ] )
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- The console command class.
---
---@class dreamwork.std.console.CommandClass : dreamwork.std.Class
---@field __base dreamwork.std.console.Command
---@overload fun( options: dreamwork.std.console.Command.Options ): dreamwork.std.console.Command
local CommandClass = std.class.create( Command )
console.Command = CommandClass

---@param name string
---@return dreamwork.std.console.Command
---@protected
function CommandClass:__new( name )
    return commands[ name ]
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns the console command with the given name.
---
---@return dreamwork.std.console.Command | nil obj The console command with the given name, or `nil` if it does not exist.
function CommandClass.get( name )
    return commands[ name ]
end

CommandClass.exists = engine.consoleCommandExists
CommandClass.run = engine_consoleCommandRun

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Runs the console command.
---
---@param ... string The arguments to pass to the console command.
function Command:run( ... )
    local name = names[ self ]
    if name ~= nil then
        engine_consoleCommandRun( name, ... )
    end
end

if std.LUA_CLIENT_MENU then

    local translateAlias = input ~= nil and input.TranslateAlias

    --- [CLIENT AND MENU]
    ---
    --- Translates a console command alias, basically reverse of the `alias` console command.
    ---
    ---@param str string The alias to lookup.
    ---@return string | nil cmd The command(s) this alias will execute if ran, or nil if the alias doesn't exist.
    function CommandClass.translateAlias( str )
        if translateAlias ~= nil then
            return translateAlias( str )
        end
    end

end

do

    ---@diagnostic disable-next-line: undefined-field
    local IsConCommandBlocked = IsConCommandBlocked

    --- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
    ---
    --- Checks if the console command is blacklisted.
    ---
    ---@param name string The name of the console command.
    ---@return boolean is_blacklisted `true` if the console command is blacklisted, `false` otherwise.
    local function isBlacklisted( name )
        if IsConCommandBlocked == nil then
            return false
        else
            return IsConCommandBlocked( name )
        end
    end

    CommandClass.isBlacklisted = isBlacklisted

    --- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
    ---
    --- Returns whether the console command is blacklisted.
    ---
    ---@return boolean is_blacklisted `true` if the console command is blacklisted, `false` otherwise.
    function Command:isBlacklisted()
        local name = names[ self ]
        if name == nil then
            return false
        else
            return isBlacklisted( name )
        end
    end

end

---@type table<dreamwork.std.console.Variable, boolean>
local in_call = {}

gc_setTableRules( in_call, true, false )

-- TODO: remove later
---@diagnostic disable-next-line: undefined-doc-name
---@alias dreamwork.std.console.Command.callback fun( command: dreamwork.std.console.Command, ply: dreamwork.std.Player, args: string[], argument_string: string )

---@class dreamwork.std.console.Command.query_data
---@field [1] boolean `true` to attach, `false` to detach.
---@field [2] any The identifier of the callback.
---@field [3] nil | dreamwork.std.console.Command.callback The callback function.
---@field [4] nil | boolean `true` to run once, `false` to run forever.

---@type table<dreamwork.std.console.Command, dreamwork.std.console.Command.query_data[]>
local queues = {}

gc_setTableRules( queues, true, false )

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Adds a callback to the console command object.
---
---@param fn dreamwork.std.console.Command.callback The callback function.
---@param identifier? any The identifier of the callback, default is `unnamed`.
---@param once? boolean `true` to run once, `false` to run forever, default is `false`.
function Command:attach( fn, identifier, once )
    if identifier == nil then
        identifier = "nil"
    end

    if in_call[ self ] then
        local queue = queues[ self ]
        if queue == nil then
            queues[ self ] = {
                { true, identifier, fn, once == true }
            }
        else
            queue[ #queue + 1 ] = { true, identifier, fn, once == true }
        end

        return
    end

    local lst = callbacks[ self ]
    if lst == nil then
        return
    end

    local lst_length = #lst

    for i = 1, lst_length, 3 do
        if lst[ i ] == identifier then
            lst[ i + 1 ] = fn
            lst[ i + 2 ] = once == true
            return
        end
    end

    lst[ lst_length + 1 ] = identifier
    lst[ lst_length + 2 ] = fn
    lst[ lst_length + 3 ] = once == true
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Removes a callback from the console command object.
---
---@param identifier any The identifier of the callback to detach.
function Command:detach( identifier )
    if identifier == nil then
        identifier = "nil"
    end

    local lst = callbacks[ self ]
    if lst == nil then
        return
    end

    for i = 1, #lst, 3 do
        if lst[ i ] == identifier then
            if in_call[ self ] then
                lst[ i + 1 ] = debug_fempty

                local queue = queues[ self ]
                if queue == nil then
                    queues[ self ] = {
                        { false, identifier }
                    }
                else
                    queue[ #queue + 1 ] = { false, identifier }
                end
            else
                table_removeByRange( lst, i, i + 2 )
            end

            break
        end
    end
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Clears all callbacks from the `console.Command` object.
---
function Command:clear()
    callbacks[ self ] = {}
    in_call[ self ] = nil
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Waits for the console command to be executed.
---
---@async
function Command:wait()
    local future = futures_Future()

    self:attach( function( ... )
        return future:setResult( { ... } )
    end, future, true )

    return future:await()
end

engine.hookCatch( "ConsoleCommandExecuted", function( ply, name, args, argument_string )
    local command = commands[ name ]
    if command == nil then
        return nil
    end

    if string_byte( argument_string, 1 ) == 0x22 --[[ "\"" ]] and string_byte( argument_string, -1 ) == 0x22 --[[ "\"" ]] then
        argument_string = string_sub( argument_string, 2, -2 )
    end

    in_call[ command ] = true

    local lst = callbacks[ command ]
    if lst ~= nil then
        for i = #lst - 1, 1, -3 do
            if in_call[ command ] then
                local success, err_msg = pcall( lst[ i ], command, ply, args, argument_string )
                if not success then
                    -- TODO: replace with cool new errors that i make later
                    std.printf( "[DreamWork] console command callback error: %s", err_msg )
                    table_removeByRange( lst, i - 1, i + 1 )
                elseif lst[ i + 1 ] then
                    table_removeByRange( lst, i - 1, i + 1 )
                end
            else
                break
            end
        end
    end

    in_call[ command ] = nil

    local queue = queues[ command ]
    if queue ~= nil then
        queues[ command ] = nil

        for i = 1, #queue, 1 do
            local tbl = queue[ i ]
            if tbl[ 1 ] then
                command:attach( tbl[ 2 ], tbl[ 3 ], tbl[ 4 ] )
            else
                command:detach( tbl[ 2 ] )
            end
        end
    end

    return true
end, 1 )

---@type table<dreamwork.std.console.Command, function>
local auto_complete = {}

gc_setTableRules( auto_complete, true, false )

---@alias dreamwork.std.console.Command.simple_auto_complete_fn fun( command: dreamwork.std.console.Command, argument_string: string, args: string[] ): string[]
---@alias dreamwork.std.console.Command.extended_auto_complete_fn fun( command: dreamwork.std.console.Command, argument_string: string, args: string[] ): boolean, string[]
---@alias dreamwork.std.console.Command.auto_complete_fn dreamwork.std.console.Command.simple_auto_complete_fn | dreamwork.std.console.Command.extended_auto_complete_fn

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns the auto complete function for the console command or `nil` if it does not exist.
---
---@return dreamwork.std.console.Command.auto_complete_fn | nil
function Command:getAutoComplete()
    return auto_complete[ self ]
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns `true` if the console command has an auto complete function.
---
---@return boolean
function Command:hasAutoComplete()
    return auto_complete[ self ] ~= nil
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Sets the auto complete function for the console command.
---
---@param fn dreamwork.std.console.Command.auto_complete_fn | nil The auto complete function.
function Command:setAutoComplete( fn )
    auto_complete[ self ] = fn
end

engine.hookCatch( "ConsoleCommandAutocomplete", function( name, argument_string, args )
    local command = commands[ name ]
    if command == nil then
        return
    end

    ---@type dreamwork.std.console.Command.auto_complete_fn
    local fn = auto_complete[ command ]
    if fn == nil then
        return
    end

    local success, value1, value2 = pcall( fn, command, argument_string, args )
    if not success then
        -- TODO: replace with cool new errors that i make later
        std.printf( "[DreamWork] console command auto complete error: %s", value1 )
        return
    elseif value1 == nil then
        return
    end

    if value1 == false then
        return value2
    end

    ---@type string[]
    local suggestions = {}
    local prefix = name .. " "

    if value1 == true and value2 ~= nil then
        ---@cast value1 boolean
        ---@cast value2 string[]
        for i = 1, #value2, 1 do
            suggestions[ i ] = prefix .. value2[ i ]
        end
    else
        ---@cast value1 string[]
        for i = 1, #value1, 1 do
            suggestions[ i ] = prefix .. value1[ i ]
        end
    end

    return suggestions
end, 1 )
