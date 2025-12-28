local _G = _G

---@class dreamwork
local dreamwork = _G.dreamwork

---@class dreamwork.std
local std = dreamwork.std

if std.console then
    return
end

local LUA_SERVER = std.LUA_SERVER

local engine = dreamwork.engine
local engine_consoleCommandRun = engine.consoleCommandRun

--- [SHARED AND MENU]
---
--- The source engine console library.
---
---@class dreamwork.std.console
---@field visible boolean `true` if the console is visible, `false` otherwise.
local console = std.console or { visible = LUA_SERVER }
std.console = console

if std.LUA_MENU then

    --- [MENU]
    ---
    --- Shows the console.
    ---
    console.show = _G.gui.ShowConsole or function()
        engine_consoleCommandRun( "showconsole" )
    end

    --- [MENU]
    ---
    --- Hides the console.
    ---
    function console.hide()
        engine_consoleCommandRun( "hideconsole" )
    end

    --- [MENU]
    ---
    --- Toggles the console.
    ---
    function console.toggle()
        engine_consoleCommandRun( "toggleconsole" )
    end

end

if std.LUA_CLIENT_MENU then

    local gui_IsConsoleVisible = _G.gui.IsConsoleVisible or function() return false end

    local Visibility = console.Visibility or std.Hook( "console.Visibility" )
    console.Visibility = Visibility

    local visible = gui_IsConsoleVisible()
    console.visible = visible

    dreamwork.TickTimer0_25:attach( function()
        if visible ~= gui_IsConsoleVisible() then
            visible = not visible
            console.visible = visible
            Visibility:call( visible )
        end
    end, "std.console.visible" )

else

    console.Visibility = console.Visibility or std.Hook( "console.Visibility" )

end

do

    ---@diagnostic disable-next-line: undefined-field
    local console_write = _G.MsgC

    if console_write == nil then

        local table_concat = std.table.concat
        local isString = std.isString
        local print = std.print

        --- [SHARED AND MENU]
        ---
        --- Writes a message to the console.
        ---
        ---@param ... string The message to write to the console.
        function console_write( ... )
            local buffer, buffer_size = {}, 0
            local args = { ... }

            for i = 1, select( "#", ... ), 1 do
                local value = args[ i ]
                if isString( value ) then
                    buffer_size = buffer_size + 1
                    buffer[ buffer_size ] = value
                end
            end

            if buffer_size == 1 then
                print( buffer[ 1 ] )
            elseif buffer_size ~= 0 then
                print( table_concat( buffer, "", 1, buffer_size ) )
            end
        end
    end

    console.write = console_write

    --- [SHARED AND MENU]
    ---
    --- Writes a colored message to the console on a new line.
    ---
    ---@param ... string | Color The message to write to the console.
    function console.writeLine( ... )
        return console_write( ... ), console_write( "\n" )
    end

end

local existing_flags = {
    { "unregistered", 1 },
    { "development_only", 2 },
    { "game_dll", 4 },
    { "client_dll", 8 },
    { "hidden", 16 },
    { "protected", 32 },
    { "sponly", 64 },
    { "archive", 128 },
    { "notify", 256 },
    { "userinfo", 512 },
    { "cheat", 16384 },
    { "printable_only", 1024 },
    { "unlogged", 2048 },
    { "never_as_string", 4096 },
    { "replicated", 8192 },
    { "demo", 65536 },
    { "dont_record", 131072 },
    { "reload_materials", 1048576 },
    { "reload_textures", 2097152 },
    { "not_connected", 4194304 },
    { "material_system_thread", 8388608 },
    { "archive_xbox", 16777216 },
    { "accessible_from_threads", 33554432 },
    { "server_can_execute", 268435456 },
    { "server_cannot_query", 536870912 },
    { "clientcmd_can_execute", 1073741824 },
    { "material_thread_mask", 11534336 },
    { "lua_client", 262144 },
    { "lua_server", 524288 }
}

local existing_flag_count = #existing_flags

---@type table<string, integer>
local flag2integer = {}

for i = 1, existing_flag_count, 1 do
    local flag = existing_flags[ i ]
    flag2integer[ flag[ 1 ] ] = flag[ 2 ]
end

local bit_band = std.bit.band
local gc_setTableRules = std.gc.setTableRules

local string = std.string
local string_sub = string.sub
local string_format = string.format

local debug = std.debug
local debug_fempty = debug.fempty

local futures_Future = std.futures.Future
local setmetatable = std.setmetatable
local table_eject = std.table.eject
local pcall = std.pcall

local raw = std.raw
local raw_index = raw.index

do

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

    --- [SHARED AND MENU]
    ---
    --- The console command object.
    ---
    ---@class dreamwork.std.console.Command : dreamwork.Object
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
        elseif flag2integer[ str_key ] ~= nil then
            return bit_band( flags[ self ], flag2integer[ str_key ] ) ~= 0
        else
            return raw_index( Command, str_key )
        end
    end

    do

        local engine_consoleCommandRegister = engine.consoleCommandRegister

        ---@param options dreamwork.std.console.Command.Options
        ---@private
        function Command:__init( options )
            local name = options.name
            local description = options.description or "description not provided"

            local int32_flags = options.flags or 0

            for i = 1, existing_flag_count, 1 do
                local flag = existing_flags[ i ]
                if options[ flag[ 1 ] ] then
                    int32_flags = int32_flags + flag[ 2 ]
                end
            end

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
        return string_format( "console.Command: %p [%s][%s]", self, names[ self ], descriptions[ self ] )
    end

    --- [SHARED AND MENU]
    ---
    --- The console command class.
    ---
    ---@class dreamwork.std.console.CommandClass : dreamwork.Class
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
        if name ~= nil then
            engine_consoleCommandRun( name, ... )
        end
    end

    if std.LUA_CLIENT_MENU then

        local translateAlias = _G.input ~= nil and _G.input.TranslateAlias

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
        local IsConCommandBlocked = _G.IsConCommandBlocked

        --- [SHARED AND MENU]
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

        --- [SHARED AND MENU]
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

    --- [SHARED AND MENU]
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

    --- [SHARED AND MENU]
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
                    table_eject( lst, i, i + 2 )
                end

                break
            end
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Clears all callbacks from the `console.Command` object.
    ---
    function Command:clear()
        callbacks[ self ] = {}
        in_call[ self ] = nil
    end

    --- [SHARED AND MENU]
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

    local string_byte = string.byte

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
                        table_eject( lst, i - 1, i + 1 )
                    elseif lst[ i + 1 ] then
                        table_eject( lst, i - 1, i + 1 )
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

    --- [SHARED AND MENU]
    ---
    --- Returns the auto complete function for the console command or `nil` if it does not exist.
    ---
    ---@return dreamwork.std.console.Command.auto_complete_fn | nil
    function Command:getAutoComplete()
        return auto_complete[ self ]
    end

    --- [SHARED AND MENU]
    ---
    --- Returns `true` if the console command has an auto complete function.
    ---
    ---@return boolean
    function Command:hasAutoComplete()
        return auto_complete[ self ] ~= nil
    end

    --- [SHARED AND MENU]
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

end

do

    local engine_consoleVariableGet = engine.consoleVariableGet

    local raw_tonumber = std.raw.tonumber
    local toboolean = std.toboolean
    local tostring = std.tostring

    local CONVAR = debug.findmetatable( "ConVar" ) or {}
    ---@cast CONVAR ConVar

    local convar_getMin, convar_getMax = CONVAR.GetMin, CONVAR.GetMax
    local convar_getDefault = CONVAR.GetDefault
    local convar_getString = CONVAR.GetString
    local convar_getFloat = CONVAR.GetFloat
    local convar_getBool = CONVAR.GetBool
    local convar_getInt = CONVAR.GetInt

    local math_floor = std.math.floor
    local raw_type = raw.type

    ---@type table<dreamwork.std.console.Variable, ConVar>
    local variable2convar = {}

    ---@type table<dreamwork.std.console.Variable, string>
    local names = {}

    do

        local convar_getName = CONVAR.GetName

        setmetatable( names, {
            __index = function( _, self )
                local cvar = variable2convar[ self ]
                if cvar == nil then
                    return "unknown"
                end

                local name = convar_getName( cvar )
                names[ self ] = name
                return name
            end,
            __mode = "k"
        } )

    end

    do

        local raw_get = raw.get

        setmetatable( variable2convar, {
            __index = function( _,  self )
                local name = raw_get( names, self )
                if name ~= nil then
                    local cvar = engine_consoleVariableGet( name )
                    variable2convar[ self ] = cvar
                    return cvar
                end
            end,
            __mode = "k"
        } )

    end

    ---@type table<dreamwork.std.console.Variable, string>
    local descriptions = {}

    do

        local convar_getDescription = CONVAR.GetHelpText

        setmetatable( descriptions, {
            __index = function( _, self )
                local cvar = variable2convar[ self ]
                if cvar == nil then
                    return "unknown"
                end

                local description = convar_getDescription( cvar )
                descriptions[ self ] = description
                return description
            end,
            __mode = "k"
        } )

    end

    ---@type table<dreamwork.std.console.Variable, dreamwork.std.console.Variable.type>
    local types = {}

    do

        local raw_set = raw.set

        ---@type table<dreamwork.std.console.Variable.type, boolean>
        local supported_types = {
            boolean = true,
            integer = true,
            number = true,
            string = true,
            float = true
        }

        setmetatable( types, {
            __index = function()
                return "string"
            end,
            __newindex = function( _, self, name )
                if supported_types[ name ] then
                    raw_set( types, self, name )
                end
            end,
            __mode = "k"
        } )

    end

    ---@type table<dreamwork.std.console.Variable, integer>
    local flags = {}

    do

        local convar_getFlags = CONVAR.GetFlags

        setmetatable( flags, {
            __index = function( _, self )
                local cvar = variable2convar[ self ]
                if cvar == nil then
                    return 0
                end

                local int32_flags = convar_getFlags( cvar )
                flags[ self ] = int32_flags
                return int32_flags
            end,
            __mode = "k"
        } )

    end

    ---@type table<string, boolean>
    local number_types = {
        integer = true,
        number = true,
        float = true
    }

    ---@type table<dreamwork.std.console.Variable, dreamwork.std.console.Variable.value>
    local defaults = {}

    setmetatable( defaults, {
        __index = function( _, variable )
            local cvar_type = types[ variable ]

            local cvar = variable2convar[ variable ]
            if cvar == nil then
                if number_types[ cvar_type ] then
                    return 0
                elseif cvar_type == "boolean" then
                    return false
                end

                return ""
            end

            local str_default = convar_getDefault( cvar )
            if number_types[ cvar_type ] then
                local float_default = raw_tonumber( str_default, 10 ) or 0

                if cvar_type == "integer" then
                    float_default = math_floor( float_default )
                end

                defaults[ variable ] = float_default
                return float_default
            elseif cvar_type == "boolean" then
                local bool_default = toboolean( str_default )
                defaults[ variable ] = bool_default
                return bool_default
            else
                defaults[ variable ] = str_default
                return str_default
            end
        end,
        __mode = "k"
    } )

    ---@type table<dreamwork.std.console.Variable, dreamwork.std.console.Variable.value>
    local values = {}

    setmetatable( values, {
        __index = function( _, variable )
            local cvar = variable2convar[ variable ]
            if cvar == nil then
                return defaults[ variable ]
            end

            local type = types[ variable ]
            if type == "float" or type == "number" then
                local float_value = convar_getFloat( cvar )
                values[ variable ] = float_value
                return float_value
            elseif type == "integer" then
                local integer_value = convar_getInt( cvar )
                values[ variable ] = integer_value
                return integer_value
            elseif type == "boolean" then
                local bool_value = convar_getBool( cvar )
                values[ variable ] = bool_value
                return bool_value
            else
                local str_value = convar_getString( cvar )
                values[ variable ] = str_value
                return str_value
            end
        end,
        __mode = "k"
    } )

    ---@type table<dreamwork.std.console.Variable, number>
    local mins = {}

    setmetatable( mins, {
        __index = function( _, variable )
            local cvar = variable2convar[ variable ]
            if cvar == nil then
                return nil
            end

            local float_min = convar_getMin( cvar )
            mins[ variable ] = float_min
            return float_min
        end,
        __mode = "k"
    } )

    ---@type table<dreamwork.std.console.Variable, number>
    local maxs = {}

    setmetatable( maxs, {
        __index = function( _, variable )
            local cvar = variable2convar[ variable ]
            if cvar == nil then
                return nil
            end

            local float_max = convar_getMax( cvar )
            maxs[ variable ] = float_max
            return float_max
        end,
        __mode = "k"
    } )

    ---@type table<string, dreamwork.std.console.Variable>
    local variables = {}

    gc_setTableRules( variables, false, true )

    ---@type table<dreamwork.std.console.Variable, table>
    local callbacks = {}

    gc_setTableRules( callbacks, true, false )

    --- [SHARED AND MENU]
    ---
    --- The console variable object.
    ---
    ---@class dreamwork.std.console.Variable : dreamwork.Object
    ---@field __class dreamwork.std.console.Variable
    local Variable = std.class.base( "console.Variable", true )

    ---@protected
    function Variable:__index( str_key )
        if str_key == "type" then
            return types[ self ]
        elseif str_key == "name" then
            return names[ self ]
        elseif str_key == "description" then
            return descriptions[ self ]
        elseif str_key == "flags" then
            return flags[ self ]
        elseif str_key == "default" then
            return defaults[ self ]
        elseif str_key == "min" then
            return mins[ self ]
        elseif str_key == "max" then
            return maxs[ self ]
        elseif str_key == "value" then
            return values[ self ]
        elseif flag2integer[ str_key ] ~= nil then
            return bit_band( flags[ self ], flag2integer[ str_key ] ) ~= 0
        else
            return raw_index( Variable, str_key )
        end
    end

    ---@protected
    function Variable:__newindex( str_key, value )
        if str_key == "value" then
            local cvar_type = types[ self ]
            if cvar_type == "boolean" then
                local bool_value = toboolean( value )
                engine_consoleCommandRun( names[ self ], bool_value and "1" or "0" )
                values[ self ] = bool_value
            elseif number_types[ cvar_type ] then
                local float_value = raw_tonumber( value, 10 ) or 0.0

                if cvar_type == "integer" then
                    float_value = math_floor( float_value )
                end

                engine_consoleCommandRun( names[ self ], string_format( "%f", float_value ) )
                values[ self ] = float_value
            else
                local str_value = tostring( value )
                engine_consoleCommandRun( names[ self ], str_value )
                values[ self ] = str_value
            end
        elseif str_key == "type" then
            types[ self ] = value
        else
            error( "attempt to modify unknown console variable property", 2 )
        end
    end

    do

        local engine_consoleVariableCreate = engine.consoleVariableCreate
        local arg = std.arg

        ---@param options dreamwork.std.console.Variable.Options
        ---@protected
        function Variable:__init( options )
            local str_name = options.name
            names[ self ] = str_name

            local cvar_type = options.type or "string"
            types[ self ] = cvar_type

            local cvar = engine_consoleVariableGet( str_name )
            if cvar == nil then
                local str_description = options.description or ""
                descriptions[ self ] = str_description

                local str_default = options.default

                if str_default == nil then
                    if cvar_type == "boolean" then
                        str_default = false
                    elseif number_types[ cvar_type ] then
                        str_default = 0
                    else
                        str_default = ""
                    end
                end

                local ok, error_msg = arg( str_default, "default", number_types[ cvar_type ] and "number" or cvar_type )

                if not ok then
                    error( error_msg, 3 )
                end

                if cvar_type == "boolean" then
                    str_default = str_default and "1" or "0"
                elseif number_types[ cvar_type ] then
                    str_default = tostring( str_default ) or "0"
                end

                ---@cast str_default string

                local int32_flags = options.flags or 0

                for i = 1, existing_flag_count, 1 do
                    local flag = existing_flags[ i ]
                    if options[ flag[ 1 ] ] then
                        int32_flags = int32_flags + flag[ 2 ]
                    end
                end

                flags[ self ] = int32_flags

                local int32_min = options.min or 0

                if cvar_type == "integer" then
                    int32_min = math_floor( int32_min )
                end

                mins[ self ] = int32_min

                local int32_max = options.max or 0

                if cvar_type == "integer" then
                    int32_max = math_floor( int32_max )
                end

                maxs[ self ] = int32_max

                cvar = engine_consoleVariableCreate( str_name, str_default, int32_flags, str_description, int32_min, int32_max )
            end

            if cvar == nil then
                error( "failed to create console variable, unknown error", 3 )
            else
                variable2convar[ self ] = cvar
            end

            callbacks[ self ] = {}
            variables[ str_name ] = self
        end
    end

    ---@return string
    ---@protected
    function Variable:__tostring()
        return string_format( "console.Variable: %p [%s][%s]", self, names[ self ], values[ self ] )
    end

    --- [SHARED AND MENU]
    ---
    --- The console variable class.
    ---
    ---@class dreamwork.std.console.VariableClass : dreamwork.std.console.Variable
    ---@field __base dreamwork.std.console.Variable
    ---@overload fun( options: dreamwork.std.console.Variable.Options ): dreamwork.std.console.Variable
    local VariableClass = console.Variable or dreamwork.std.class.create( Variable )
    console.Variable = VariableClass

    ---@param str_name string
    ---@return dreamwork.std.console.Variable?
    ---@protected
    function VariableClass:__new( str_name )
        return variables[ str_name ]
    end

    local engine_consoleVariableExists = engine.consoleVariableExists
    VariableClass.exists = engine_consoleVariableExists

    --- [SHARED AND MENU]
    ---
    --- Gets a `console.Variable` object by its name.
    ---
    ---@param str_name string The name of the console variable.
    ---@param cvar_type dreamwork.std.console.Variable.type The type of the console variable.
    ---@return dreamwork.std.console.Variable | nil variable The `console.Variable` object.
    function VariableClass.get( str_name, cvar_type )
        local variable = variables[ str_name ]
        if variable == nil then
            if not engine_consoleVariableExists( str_name ) then
                return nil
            end

            return VariableClass( {
                name = str_name,
                type = cvar_type,
                default = ( cvar_type == "boolean" or number_types[ cvar_type ] ) and 0 or "",
            } )
        end

        variable.type = cvar_type
        return variable
    end

    --- [SHARED AND MENU]
    ---
    --- Gets the value of the `console.Variable` object as a string.
    ---
    ---@param name string The name of the console variable.
    ---@return string value The value of the `console.Variable` object.
    function VariableClass.getString( name )
        local object = engine_consoleVariableGet( name )
        if object == nil then
            return ""
        else
            return convar_getString( object )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Gets the value of the `console.Variable` object as an integer.
    ---
    ---@param name string The name of the console variable.
    ---@return integer value The value of the `console.Variable` object.
    function VariableClass.getInteger( name )
        local object = engine_consoleVariableGet( name )
        if object == nil then
            return 0
        else
            return convar_getInt( object )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Gets the value of the `console.Variable` object as a float/double.
    ---
    ---@param name string The name of the console variable.
    ---@return number value The value of the `console.Variable` object.
    function VariableClass.getFloat( name )
        local object = engine_consoleVariableGet( name )
        if object == nil then
            return 0.0
        else
            return convar_getFloat( object )
        end
    end

    VariableClass.getNumber = VariableClass.getFloat

    --- [SHARED AND MENU]
    ---
    --- Gets the value of the `console.Variable` object as a boolean.
    ---
    ---@param name string The name of the console variable.
    ---@return boolean value The value of the `console.Variable` object.
    function VariableClass.getBoolean( name )
        local object = engine_consoleVariableGet( name )
        if object == nil then
            return false
        else
            return convar_getBool( object )
        end
    end

    VariableClass.getBool = VariableClass.getBoolean

    --- [SHARED AND MENU]
    ---
    --- Reverts the value of the `console.Variable` object to its default value.
    ---
    function Variable:revert()
        local name = names[ self ]
        if name ~= nil then
            engine_consoleCommandRun( name, self.default )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Reverts the value of the `console.Variable` object to its default value.
    ---
    ---@param name string The name of the console variable.
    function VariableClass.revert( name )
        local object = engine_consoleVariableGet( name )
        if object == nil then
            error( "Variable '" .. name .. "' does not exist.", 2 )
        else
            engine_consoleCommandRun( name, convar_getDefault( object ) )
        end
    end

    do

        local convar_getHelpText = CONVAR.GetHelpText

        --- [SHARED AND MENU]
        ---
        --- Gets the help text of the `console.Variable` object.
        ---
        ---@param name string The name of the console variable.
        ---@return string help The help text of the `console.Variable` object.
        function VariableClass.getDescription( name )
            local object = engine_consoleVariableGet( name )
            if object == nil then
                return ""
            else
                return convar_getHelpText( object )
            end
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Gets the default value of the `console.Variable` object.
    ---
    ---@param name string The name of the console variable.
    ---@return string default The default value of the `console.Variable` object.
    function VariableClass.getDefault( name )
        local object = engine_consoleVariableGet( name )
        if object == nil then
            return ""
        else
            return convar_getDefault( object )
        end
    end

    do

        local convar_getFlags = CONVAR.GetFlags

        --- [SHARED AND MENU]
        ---
        --- Gets the flags of the `console.Variable` object.
        ---
        ---@param name string The name of the console variable.
        ---@return integer flags The flags of the `console.Variable` object.
        local function getFlags( name )
            local object = engine_consoleVariableGet( name )
            if object == nil then
                return 0
            else
                return convar_getFlags( object )
            end
        end

        VariableClass.getFlags = getFlags

        --- [SHARED AND MENU]
        ---
        --- Sets the value of the `console.Variable` object.
        ---
        ---@param name string The name of the console variable.
        ---@param value dreamwork.std.console.Variable.value The value to set.
        function VariableClass.set( name, value )
            if bit_band( getFlags( name ), 8192 ) ~= 0 and not LUA_SERVER then
                error( "replicated convar is cannot be changed by client.", 2 )
            end

            local cvar_type = raw_type( value )
            if cvar_type == "boolean" then
                engine_consoleCommandRun( name, value and "1" or "0" )
            elseif cvar_type == "string" then
                engine_consoleCommandRun( name, value )
            elseif cvar_type == "float" or cvar_type == "number" then
                engine_consoleCommandRun( name, string_format( "%f", raw_tonumber( value, 10 ) or 0.0 ) )
            elseif cvar_type == "integer" then
                engine_consoleCommandRun( name, string_format( "%d", raw_tonumber( value, 10 ) or 0 ) )
            else
                error( "invalid value type, must be boolean, string, integer, float or number.", 2 )
            end
        end

    end

    do

        local convar_isFlagSet = CONVAR.IsFlagSet

        --- [SHARED AND MENU]
        ---
        --- Checks if the flag is set on the `console.Variable` object.
        ---
        ---@param name string The name of the console variable.
        ---@param flags integer The flags to check.
        ---@return boolean is_set `true` if the flag is set on the `console.Variable` object, `false` otherwise.
        function VariableClass.isFlagSet( name, flags )
            local object = engine_consoleVariableGet( name )
            if object == nil then
                return false
            else
                return convar_isFlagSet( object, flags )
            end
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Gets the minimum value of the `console.Variable` object.
    ---
    ---@param name string The name of the console variable.
    ---@return number minimum The minimum value of the `console.Variable` object.
    function VariableClass.getMin( name )
        local object = engine_consoleVariableGet( name )
        if object == nil then
            return 0
        else
            return convar_getMin( object )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Gets the maximum value of the `console.Variable` object.
    ---
    ---@param name string The name of the console variable.
    ---@return number maximum The maximum value of the `console.Variable` object.
    function VariableClass.getMax( name )
        local object = engine_consoleVariableGet( name )
        if object == nil then
            return 0
        else
            return convar_getMax( object )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the minimum and maximum values of the `console.Variable` object.
    ---
    ---@param name string The name of the console variable.
    ---@return number minimum The minimum value of the `console.Variable` object.
    ---@return number maximum The maximum value of the `console.Variable` object.
    function VariableClass.getBounds( name )
        local object = engine_consoleVariableGet( name )
        if object == nil then
            return 0, 0
        else
            return convar_getMin( object ), convar_getMax( object )
        end
    end

    ---@type table<dreamwork.std.console.Variable, boolean>
    local in_call = {}

    gc_setTableRules( in_call, true, false )

    ---@alias dreamwork.std.console.Variable.callback fun( variable: dreamwork.std.console.Variable, new_value: dreamwork.std.console.Variable.value )

    ---@class dreamwork.std.console.Variable.query_data : dreamwork.std.console.Command.query_data
    ---@field [3] nil | dreamwork.std.console.Variable.callback The callback function.

    ---@type table<dreamwork.std.console.Variable, dreamwork.std.console.Variable.query_data[]>
    local queues = {}

    gc_setTableRules( queues, true, false )

    --- [SHARED AND MENU]
    ---
    --- Attaches a callback to the `console.Variable` object.
    ---
    ---@param fn dreamwork.std.console.Variable.callback The callback function.
    ---@param identifier? any The identifier of the callback, default is `unnamed`.
    ---@param once? boolean `true` to run once, `false` to run forever, default is `false`.
    function Variable:attach( fn, identifier, once )
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

    --- [SHARED AND MENU]
    ---
    --- Detaches a callback from the `console.Variable` object.
    ---
    ---@param identifier any The identifier of the callback to detach.
    function Variable:detach( identifier )
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
                    table_eject( lst, i, i + 2 )
                end

                break
            end
        end
    end


    --- [SHARED AND MENU]
    ---
    --- Clears all callbacks from the `console.Variable` object.
    ---
    function Variable:clear()
        callbacks[ self ] = {}
        in_call[ self ] = nil
    end

    --- [SHARED AND MENU]
    ---
    --- Waits for the `console.Variable` object to change.
    ---
    ---@return dreamwork.std.console.Variable.value
    ---@async
    function Variable:wait()
        local future = futures_Future()

        self:attach( function( _, value )
            future:setResult( value )
        end, future, true )

        return future:await()
    end

    engine.hookCatch( "ConsoleVariableChanged", function( str_name, str_old, str_new )
        local variable = variables[ str_name ]
        if variable == nil then
            return
        end

        local cvar_type = variable.type
        local old_value, new_value

        if cvar_type == "boolean" then
            old_value, new_value = str_old == "1", str_new == "1"
        elseif number_types[ cvar_type ] then
            old_value, new_value = raw_tonumber( str_old, 10 ) or 0, raw_tonumber( str_new, 10 ) or 0
        else
            old_value, new_value = str_old, str_new
        end

        in_call[ variable ] = true
        values[ variable ] = old_value

        local lst = callbacks[ variable ]
        if lst ~= nil then
            for i = #lst - 1, 1, -3 do
                if in_call[ variable ] then
                    local success, err_msg = pcall( lst[ i ], variable, new_value )
                    if not success then
                        -- TODO: add error display here
                        std.printf( "[DreamWork] console variable callback error: %s", err_msg )
                        table_eject( lst, i - 1, i + 1 )
                    elseif lst[ i + 1 ] then
                        table_eject( lst, i - 1, i + 1 )
                    end
                else
                    break
                end
            end
        end

        values[ variable ] = new_value
        in_call[ variable ] = nil

        local queue = queues[ variable ]
        if queue ~= nil then
            queues[ variable ] = nil

            for i = 1, #queue, 1 do
                local tbl = queue[ i ]
                if tbl[ 1 ] then
                    variable:attach( tbl[ 2 ], tbl[ 3 ], tbl[ 4 ] )
                else
                    variable:detach( tbl[ 2 ] )
                end
            end
        end
    end )

end
