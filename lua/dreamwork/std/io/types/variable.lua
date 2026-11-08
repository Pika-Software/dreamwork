local dreamwork_engine = dreamwork.engine
local engine_hook = dreamwork_engine.hook

local std = dreamwork.std

---@class dreamwork.std.console
local console = std.console

local engine_console = dreamwork_engine.console
local console_variableGet = engine_console.variableGet
local console_variableGetValue = engine_console.variableGetValue
local console_variableSetValue = engine_console.variableSetValue
local console_variableCreate = engine_console.variableCreate
local console_variableRemove = engine_console.variableRemove
local console_variableExists = engine_console.variableExists

local LUA_SERVER = std.LUA_SERVER

local debug = std.debug
local debug_getmetatable = debug.getmetatable

local raw = std.raw
local raw_get = raw.get
local raw_set = raw.set
local raw_index = raw.index

local math = std.math
local math_floor = math.floor
local math_trunc = math.trunc
local math_clamp = math.clamp

local string = std.string
local string_format = string.format
local string_toNumber = string.toNumber

local rbit = raw.bit
local rbit_band = rbit.band

local class = std.class

local type = std.type
local error = std.error
local isNumber = std.isNumber
local tostring = std.tostring
local toboolean = std.toboolean
local setmetatable = std.setmetatable

local Emitter = std.Emitter
local Boolean = std.Boolean
local String = std.String


local ConsoleVariable = dreamwork_engine.ConsoleVariable

local ConsoleVariable_GetName = ConsoleVariable.GetName
local ConsoleVariable_GetHelpText = ConsoleVariable.GetHelpText

local ConsoleVariable_GetFlags = ConsoleVariable.GetFlags
local ConsoleVariable_IsFlagSet = ConsoleVariable.IsFlagSet

local ConsoleVariable_GetDefault = ConsoleVariable.GetDefault
local ConsoleVariable_GetMin, ConsoleVariable_GetMax = ConsoleVariable.GetMin, ConsoleVariable.GetMax

---@param value string | number
---@return number
local function parse_number( value )
    if isNumber( value ) then
        ---@cast value number

        if value ~= value then
            return 0
        end

        return value
    end

    ---@cast value string

    local number = string_toNumber( value )
    if number == nil or number ~= number then -- `tonumber( s, 10 )` accepts "nan"
        return 0
    end

    return number
end

--- Parses a console variable string the way the engine does:
--- `GetInt` truncates toward zero and `GetBool` is `GetInt() ~= 0`.
---
---@param str string
---@param cvar_type dreamwork.std.console.VariableType
---@return dreamwork.std.console.VariableValue
local function parse_value( str, cvar_type )
    if cvar_type == "string" then
        return str
    end

    local number = parse_number( str )

    if cvar_type == "integer" then
        return math_trunc( number )
    elseif cvar_type == "boolean" then
        return number >= 1 or number <= -1
    end

    return number
end


---@type table<dreamwork.std.console.Variable, garrysmod.console.Variable>
local variable_cvars = {}

---@type table<dreamwork.std.console.Variable, string>
local variable_names = {}

setmetatable( variable_names, {
    __index = function( self, variable )
        local cvar = variable_cvars[ variable ]
        if cvar == nil then
            return "unknown"
        end

        local name = ConsoleVariable_GetName( cvar )
        self[ variable ] = name
        return name
    end,
    __mode = "k"
} )

setmetatable( variable_cvars, {
    __index = function( self, variable )
        local name = raw_get( variable_names, variable )
        if name == nil then
            return nil
        end

        local cvar = console_variableGet( name )
        self[ variable ] = cvar
        return cvar
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.console.Variable, string>
local variable_descriptions = {}

setmetatable( variable_descriptions, {
    __index = function( self, variable )
        local cvar = variable_cvars[ variable ]
        if cvar == nil then
            return "unknown"
        end

        local description = ConsoleVariable_GetHelpText( cvar )
        self[ variable ] = description
        return description
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.console.Variable, dreamwork.std.console.VariableType>
local variable_types = {}

do

    ---@type table<dreamwork.std.console.VariableType, boolean>
    local supported_types = {
        boolean = true,
        integer = true,
        number = true,
        string = true
    }

    setmetatable( variable_types, {
        __index = function()
            return "string"
        end,
        __newindex = function( self, variable, cvar_type )
            if supported_types[ cvar_type ] then
                raw_set( self, variable, cvar_type )
            end
        end,
        __mode = "k"
    } )

end

---@type table<dreamwork.std.console.Variable, integer>
local variable_flags = {}

setmetatable( variable_flags, {
    __index = function( self, variable )
        local cvar = variable_cvars[ variable ]
        if cvar == nil then
            return 0
        end

        local flags = ConsoleVariable_GetFlags( cvar )
        self[ variable ] = flags
        return flags
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.console.Variable, dreamwork.std.console.VariableValue>
local variable_defaults = {}

setmetatable( variable_defaults, {
    __index = function( self, variable )
        local cvar_type = variable_types[ variable ]

        local cvar = variable_cvars[ variable ]
        if cvar == nil then
            if cvar_type == "integer" or cvar_type == "number" then
                return 0
            elseif cvar_type == "boolean" then
                return false
            end

            return ""
        end

        local default = parse_value( ConsoleVariable_GetDefault( cvar ), cvar_type )
        self[ variable ] = default
        return default
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.console.Variable, dreamwork.std.console.VariableValue>
local variable_values = {}

setmetatable( variable_values, {
    __index = function( self, variable )
        if variable_cvars[ variable ] == nil then
            return variable_defaults[ variable ]
        end

        local value = parse_value( console_variableGetValue( variable_names[ variable ] ), variable_types[ variable ] )
        self[ variable ] = value
        return value
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.console.Variable, ( number | nil )>
local variable_mins = {}

setmetatable( variable_mins, {
    __index = function( self, variable )
        local cvar = variable_cvars[ variable ]
        if cvar == nil then
            return nil
        end

        local min = ConsoleVariable_GetMin( cvar )
        self[ variable ] = min
        return min
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.console.Variable, ( number | nil )>
local variable_maxs = {}

setmetatable( variable_maxs, {
    __index = function( self, variable )
        local cvar = variable_cvars[ variable ]
        if cvar == nil then
            return nil
        end

        local max = ConsoleVariable_GetMax( cvar )
        self[ variable ] = max
        return max
    end,
    __mode = "k"
} )

--- Variable `"change"` handlers.
local events = Emitter( "console.Variable" )

---@type table<string, dreamwork.std.console.Variable>
local named_variables = {}


--- [SHARED AND MENU]
---
--- The console variable object.
---
---@class dreamwork.std.console.Variable<T> : dreamwork.std.Object
---@field __class dreamwork.std.console.Variable
---@field value T The value of the variable.
---@field type dreamwork.std.console.VariableType The type of the variable (e.g., "int", "string").
---@field name string The name of the variable.
---@field description string The description of the variable.
---@field flags integer The flags of the variable.
---@field default T The default value of the variable.
---@field min T | nil The minimum value of the variable (if applicable).
---@field max T | nil The maximum value of the variable (if applicable).
local Variable = class.base( "console.Variable", true, nil )

---@return string
---@protected
function Variable:__represent()
    return string_format( "%s: %p [%s][%s]", type( self ), self, self.name, self.type )
end

---@param key string
---@return any
---@protected
function Variable:__index( key )
    if key == "type" then
        return variable_types[ self ]
    elseif key == "name" then
        return variable_names[ self ]
    elseif key == "description" then
        return variable_descriptions[ self ]
    elseif key == "flags" then
        return variable_flags[ self ]
    elseif key == "default" then
        return variable_defaults[ self ]
    elseif key == "min" then
        return variable_mins[ self ]
    elseif key == "max" then
        return variable_maxs[ self ]
    elseif key == "value" then
        return variable_values[ self ]
    end

    local flag = console.flag( key )
    if flag == nil then
        return raw_index( Variable, key )
    end

    return rbit_band( variable_flags[ self ], flag ) ~= 0
end

---@param key string
---@param value any
---@protected
function Variable:__newindex( key, value )
    if key == "value" then
        -- `variable_values` is updated by the change hook, right away when the value
        -- is set directly, or once the engine runs the queued console command
        local cvar_type = variable_types[ self ]
        if cvar_type == "boolean" then
            console_variableSetValue( variable_names[ self ], toboolean( value ) and "1" or "0" )
        elseif cvar_type == "integer" then
            console_variableSetValue( variable_names[ self ], string_format( "%d", math_trunc( math_clamp( parse_number( value ), -2147483648, 2147483647 ) ) ) )
        elseif cvar_type == "number" then
            console_variableSetValue( variable_names[ self ], string_format( "%f", parse_number( value ) ) )
        else
            console_variableSetValue( variable_names[ self ], tostring( value ) )
        end
    elseif key == "type" then
        variable_types[ self ] = value

        -- parsed with the old type
        variable_values[ self ] = nil
        variable_defaults[ self ] = nil
    else
        error( "attempt to modify unknown console variable property", 2 )
    end
end

-- ---@protected
-- function Variable:__gc()
--     console_variableRemove( variable_names[ self ] )
-- end

---@param options dreamwork.std.console.VariableOptions
---@protected
function Variable:__init( options )
    local name = options.name
    variable_names[ self ] = name

    local cvar_type = options.type or "string"
    variable_types[ self ] = cvar_type

    local cvar = console_variableGet( name )
    if cvar == nil then
        local description = options.description or ""
        variable_descriptions[ self ] = description

        local default = options.default

        if default == nil then
            if cvar_type == "boolean" then
                default = false
            elseif cvar_type == "integer" or cvar_type == "number" then
                default = 0
            else
                default = ""
            end
        end

        local default_type = type( default )
        if default_type ~= cvar_type and not (default_type == "integer" and cvar_type == "number") then
            error( string_format( "default type (%s) does not match variable type (%s)", default_type, cvar_type ), 3 )
        end

        ---@type string
        local default_string

        if cvar_type == "boolean" then
            default_string = default and "1" or "0"
        else
            default_string = tostring( default )
        end

        local flags = console.flags( options.flags or 0, options )
        variable_flags[ self ] = flags

        local min, max

        if cvar_type ~= "string" then
            min = options.min

            if min ~= nil and cvar_type == "integer" then
                min = math_floor( min )
            elseif cvar_type == "boolean" then
                min = 0
            end

            max = options.max

            if max ~= nil and cvar_type == "integer" then
                max = math_floor( max )
            elseif cvar_type == "boolean" then
                max = 1
            end

            variable_mins[ self ], variable_maxs[ self ] = min, max
        end

        cvar = console_variableCreate( name, default_string, flags, description, min, max )
    end

    if cvar == nil then
        error( "failed to create console variable, unknown error", 3 )
    else
        variable_cvars[ self ] = cvar
    end

    named_variables[ name ] = self
end

--- [SHARED AND MENU]
---
--- The console variable class.
---
---@class dreamwork.std.console.VariableClass : dreamwork.std.console.Variable, dreamwork.std.Class
---@field __base dreamwork.std.console.Variable
---@overload fun( options: dreamwork.std.console.VariableOptions ): dreamwork.std.console.Variable
local VariableClass = class.create( Variable )
console.Variable = VariableClass

---@param name string
---@return dreamwork.std.console.Variable?
---@protected
function VariableClass:__new( name )
    return named_variables[ name ]
end

VariableClass.exists = console_variableExists

--- [SHARED AND MENU]
---
--- Gets a `console.Variable` object by its name.
---
---@param name string The name of the console variable.
---@param cvar_type dreamwork.std.console.VariableType The type of the console variable.
---@return dreamwork.std.console.Variable variable The `console.Variable` object.
---@nodiscard
---@overload fun( name: string, cvar_type: "boolean"): dreamwork.std.console.Variable<boolean>
---@overload fun( name: string, cvar_type: "integer"): dreamwork.std.console.Variable<integer>
---@overload fun( name: string, cvar_type: "number"): dreamwork.std.console.Variable<number>
---@overload fun( name: string, cvar_type: "string"): dreamwork.std.console.Variable<string>
function VariableClass.get( name, cvar_type )
    local variable = named_variables[ name ]
    if variable == nil then
        if not console_variableExists( name ) then
            error( "console variable '" .. name .. "' does not exist", 2 )
        end

        local options = {
            name = name,
            type = cvar_type
        }

        if cvar_type == "boolean" then
            options.default = false
        elseif cvar_type == "number" or cvar_type == "integer" then
            options.default = 0
        else
            options.default = ""
        end

        return VariableClass( options )
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
---@nodiscard
function VariableClass.getString( name )
    return console_variableGetValue( name )
end

--- [SHARED AND MENU]
---
--- Gets the value of the `console.Variable` object as an integer.
---
---@param name string The name of the console variable.
---@return integer value The value of the `console.Variable` object.
---@nodiscard
function VariableClass.getInteger( name )
    return math_trunc( parse_number( console_variableGetValue( name ) ) )
end

--- [SHARED AND MENU]
---
--- Gets the value of the `console.Variable` object as a float/double.
---
---@param name string The name of the console variable.
---@return number value The value of the `console.Variable` object.
---@nodiscard
function VariableClass.getFloat( name )
    return parse_number( console_variableGetValue( name ) )
end

VariableClass.getNumber = VariableClass.getFloat

--- [SHARED AND MENU]
---
--- Gets the value of the `console.Variable` object as a boolean.
---
---@param name string The name of the console variable.
---@return boolean value The value of the `console.Variable` object.
---@nodiscard
function VariableClass.getBoolean( name )
    local number = parse_number( console_variableGetValue( name ) )
    return number >= 1 or number <= -1
end

VariableClass.getBool = VariableClass.getBoolean

--- [SHARED AND MENU]
---
--- Reverts the value of the `console.Variable` object to its default value.
---
---@generic T
---@param self dreamwork.std.console.Variable<T>
---@return T default The default value of the `console.Variable` object.
function Variable:revert()
    local default = self.default
    self.value = default
    return default
end

--- [SHARED AND MENU]
---
--- Reverts the value of the `console.Variable` object to its default value.
---
---@param name string The name of the console variable.
---@return boolean success `true` if the value was set (or the command to set it was sent), `false` otherwise.
function VariableClass.revert( name )
    local cvar = console_variableGet( name )
    if cvar == nil then
        error( "Variable '" .. name .. "' does not exist.", 2 )
    end

    return console_variableSetValue( name, ConsoleVariable_GetDefault( cvar ) )
end

--- [SHARED AND MENU]
---
--- Gets the help text of the `console.Variable` object.
---
---@param name string The name of the console variable.
---@return string help The help text of the `console.Variable` object.
---@nodiscard
function VariableClass.getDescription( name )
    local cvar = console_variableGet( name )
    if cvar == nil then
        return ""
    end

    return ConsoleVariable_GetHelpText( cvar )
end

--- [SHARED AND MENU]
---
--- Gets the default value of the `console.Variable` object.
---
---@param name string The name of the console variable.
---@return string default The default value of the `console.Variable` object.
---@nodiscard
function VariableClass.getDefault( name )
    local cvar = console_variableGet( name )
    if cvar == nil then
        return ""
    end

    return ConsoleVariable_GetDefault( cvar )
end

do

    --- [SHARED AND MENU]
    ---
    --- Gets the flags of the `console.Variable` object.
    ---
    ---@param name string The name of the console variable.
    ---@return integer flags The flags of the `console.Variable` object.
    ---@nodiscard
    local function get_flags( name )
        local cvar = console_variableGet( name )
        if cvar == nil then
            return 0
        end

        return ConsoleVariable_GetFlags( cvar )
    end

    VariableClass.getFlags = get_flags

    --- [SHARED AND MENU]
    ---
    --- Sets the value of the `console.Variable` object.
    ---
    ---@param name string The name of the console variable.
    ---@param value dreamwork.std.console.VariableValue The value to set.
    ---@return boolean success `true` if the value was set (or the command to set it was sent), `false` otherwise.
    function VariableClass.set( name, value )
        if rbit_band( get_flags( name ), 8192 ) ~= 0 and not LUA_SERVER then
            error( "replicated convar is cannot be changed by client.", 2 )
        end

        local value_metatable = debug_getmetatable( value )

        if value_metatable == Boolean then
            ---@cast value boolean
            return console_variableSetValue( name, value and "1" or "0" )
        elseif value_metatable == String then
            ---@cast value string
            return console_variableSetValue( name, value )
        elseif (value % 1) == 0 then
            ---@cast value integer
            return console_variableSetValue( name, string_format( "%d", math_clamp( value, -2147483648, 2147483647 ) ) )
        end

        ---@cast value number
        return console_variableSetValue( name, string_format( "%f", value ) )
    end

end

--- [SHARED AND MENU]
---
--- Checks if the flag is set on the `console.Variable` object.
---
---@param name string The name of the console variable.
---@param flags integer The flags to check.
---@return boolean is_set `true` if the flag is set on the `console.Variable` object, `false` otherwise.
---@nodiscard
function VariableClass.isFlagSet( name, flags )
    local cvar = console_variableGet( name )
    if cvar == nil then
        return false
    end

    return ConsoleVariable_IsFlagSet( cvar, flags )
end

--- [SHARED AND MENU]
---
--- Gets the minimum value of the `console.Variable` object.
---
---@param name string The name of the console variable.
---@return number minimum The minimum value of the `console.Variable` object.
---@nodiscard
function VariableClass.getMin( name )
    local cvar = console_variableGet( name )
    if cvar == nil then
        return 0
    end

    return ConsoleVariable_GetMin( cvar )
end

--- [SHARED AND MENU]
---
--- Gets the maximum value of the `console.Variable` object.
---
---@param name string The name of the console variable.
---@return number maximum The maximum value of the `console.Variable` object.
---@nodiscard
function VariableClass.getMax( name )
    local cvar = console_variableGet( name )
    if cvar == nil then
        return 0
    end

    return ConsoleVariable_GetMax( cvar )
end

--- [SHARED AND MENU]
---
--- Returns the minimum and maximum values of the `console.Variable` object.
---
---@param name string The name of the console variable.
---@return number minimum The minimum value of the `console.Variable` object.
---@return number maximum The maximum value of the `console.Variable` object.
---@nodiscard
function VariableClass.getBounds( name )
    local cvar = console_variableGet( name )
    if cvar == nil then
        return 0, 0
    end

    return ConsoleVariable_GetMin( cvar ), ConsoleVariable_GetMax( cvar )
end

--- [SHARED AND MENU]
---
--- Attaches a handler called on every change of the variable, attaching the same handler twice is a no-op.
---
--- Handlers run in protected mode, one failing handler is reported and never stops the others.
--- While they run `variable.value` still holds the old value, the new one is passed as `value`.
---
---@generic T
---@param self dreamwork.std.console.Variable<T>
---@param handler fun( variable: dreamwork.std.console.Variable<T>, value: T ) | dreamwork.std.Hook | dreamwork.std.Event The callback or callable object.
function Variable:attach( handler )
    events:attach( self, "change", handler )
end

--- [SHARED AND MENU]
---
--- Attaches a one-shot handler, detached right before the next change calls it.
---
---@generic T
---@param self dreamwork.std.console.Variable<T>
---@param handler fun( variable: dreamwork.std.console.Variable<T>, value: T ) | dreamwork.std.Hook | dreamwork.std.Event The callback or callable object.
function Variable:once( handler )
    events:once( self, "change", handler )
end

--- [SHARED AND MENU]
---
--- Detaches a handler previously passed to `attach` or `once`.
---
---@generic T
---@param self dreamwork.std.console.Variable<T>
---@param handler fun( variable: dreamwork.std.console.Variable<T>, value: T ) | dreamwork.std.Hook | dreamwork.std.Event The exact handler reference.
---@return boolean removed `true` if the handler was attached.
function Variable:detach( handler )
    return events:detach( self, "change", handler )
end

--- [SHARED AND MENU]
---
--- Removes every handler of the variable, pending handlers of a running change are skipped.
---
function Variable:clear()
    events:clear( self )
end

--- [SHARED AND MENU]
---
--- Waits for the `console.Variable` object to change.
---
---@generic T
---@param self dreamwork.std.console.Variable<T>
---@return dreamwork.std.console.Variable<T> variable
---@return T new_value
---@async
function Variable:await()
    return events:await( self, "change" )
end

---@param name string
---@param old_string string
---@param new_string string
engine_hook.catch( "dreamwork.console.variable.change", "console.variable.change", function( name, old_string, new_string )
    local variable = named_variables[ name ]
    if variable == nil then return end

    local cvar_type = variable_types[ variable ]
    local new_value = parse_value( new_string, cvar_type )

    variable_values[ variable ] = parse_value( old_string, cvar_type )

    events:emit( variable, "change", variable, new_value )

    variable_values[ variable ] = new_value
end, -1000 )
