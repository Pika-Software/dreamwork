local std = dreamwork.std

---@class dreamwork.std.console
local console = std.console

local engine = dreamwork.engine
local engine_hookCall = engine.hookCall
local engine_consoleCommandRun = engine.consoleCommandRun
local engine_consoleVariableGet = engine.consoleVariableGet
local engine_consoleVariableCreate = engine.consoleVariableCreate

local LUA_SERVER = std.LUA_SERVER

local debug = std.debug

local raw = std.raw
local raw_get = raw.get
local raw_set = raw.set
local raw_type = raw.type
local raw_index = raw.index
local raw_tonumber = raw.tonumber

local math = std.math
local math_floor = math.floor

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local string = std.string
local string_format = string.format

local rbit = raw.bit
local rbit_band = rbit.band

local class = std.class

local type = std.type
local error = std.error
local xpcall = std.xpcall
local tostring = std.tostring
local toboolean = std.toboolean
local represent = std.represent
local setmetatable = std.setmetatable

local Hook = std.Hook


---@diagnostic disable-next-line: undefined-doc-class
---@class dreamwork.GModConVar : ConVar
---@field GetInt fun( self: dreamwork.GModConVar ): integer
---@field GetBool fun( self: dreamwork.GModConVar ): boolean
---@field GetFloat fun( self: dreamwork.GModConVar ): number
---@field GetString fun( self: dreamwork.GModConVar ): string
---@field GetDefault fun( self: dreamwork.GModConVar ): string
---@field GetMin fun( self: dreamwork.GModConVar ): number
---@field GetMax fun( self: dreamwork.GModConVar ): number
---@field GetName fun( self: dreamwork.GModConVar ): string
---@field GetHelpText fun( self: dreamwork.GModConVar ): string
---@field GetFlags fun( self: dreamwork.GModConVar ): integer
---@field IsFlagSet fun( self: dreamwork.GModConVar, flag: integer ): boolean
local GModConVar = debug.findmetatable( "ConVar" ) or {}

local GModConVar_getInt = GModConVar.GetInt
local GModConVar_getBool = GModConVar.GetBool
local GModConVar_getFloat = GModConVar.GetFloat
local GModConVar_getString = GModConVar.GetString

local GModConVar_getName = GModConVar.GetName
local GModConVar_getDescription = GModConVar.GetHelpText

local GModConVar_getFlags = GModConVar.GetFlags
local GModConVar_isFlagSet = GModConVar.IsFlagSet

local GModConVar_getDefault = GModConVar.GetDefault
local GModConVar_getMin, GModConVar_getMax = GModConVar.GetMin, GModConVar.GetMax


---@type table<dreamwork.std.console.Variable, dreamwork.GModConVar>
local variable_to_gmodconvar = {}

---@type table<dreamwork.std.console.Variable, string>
local gmodconvar_names = {}

setmetatable( gmodconvar_names, {
    __index = function( self, variable )
        local cvar = variable_to_gmodconvar[ variable ]
        if cvar == nil then
            return "unknown"
        end

        local name = GModConVar_getName( cvar )
        self[ variable ] = name
        return name
    end,
    __mode = "k"
} )

setmetatable( variable_to_gmodconvar, {
    __index = function( self, variable )
        local name = raw_get( gmodconvar_names, variable )
        if name == nil then
            return nil
        end

        local cvar = engine_consoleVariableGet( name )
        self[ variable ] = cvar
        return cvar
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.console.Variable, string>
local gmodconvar_descriptions = {}

setmetatable( gmodconvar_descriptions, {
    __index = function( self, variable )
        local cvar = variable_to_gmodconvar[ variable ]
        if cvar == nil then
            return "unknown"
        end

        local description = GModConVar_getDescription( cvar )
        self[ variable ] = description
        return description
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.console.Variable, dreamwork.std.console.VariableType>
local types = {}

do

    ---@type table<dreamwork.std.console.VariableType, boolean>
    local supported_types = {
        boolean = true,
        integer = true,
        number = true,
        string = true
    }

    setmetatable( types, {
        __index = function()
            return "string"
        end,
        __newindex = function( self, variable, name )
            if supported_types[ name ] then
                raw_set( self, variable, name )
            end
        end,
        __mode = "k"
    } )

end

---@type table<dreamwork.std.console.Variable, integer>
local gmodconvar_flags = {}

setmetatable( gmodconvar_flags, {
    __index = function( self, variable )
        local cvar = variable_to_gmodconvar[ variable ]
        if cvar == nil then
            return 0
        end

        local int32_flags = GModConVar_getFlags( cvar )
        self[ variable ] = int32_flags
        return int32_flags
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.console.Variable, dreamwork.std.console.VariableValue>
local gmodconvar_defaults = {}

setmetatable( gmodconvar_defaults, {
    __index = function( self, variable )
        local cvar_type = types[ variable ]

        local cvar = variable_to_gmodconvar[ variable ]
        if cvar == nil then
            if cvar_type == "integer" or cvar_type == "number" then
                return 0
            elseif cvar_type == "boolean" then
                return false
            end

            return ""
        end

        local str_default = GModConVar_getDefault( cvar )

        if cvar_type == "integer" or cvar_type == "number" then
            local float_default = raw_tonumber( str_default, 10 ) or 0

            if cvar_type == "integer" then
                float_default = math_floor( float_default )
            end

            self[ variable ] = float_default
            return float_default
        elseif cvar_type == "boolean" then
            local bool_default = toboolean( str_default )
            self[ variable ] = bool_default
            return bool_default
        end

        self[ variable ] = str_default
        return str_default
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.console.Variable, dreamwork.std.console.VariableValue>
local values = {}

setmetatable( values, {
    __index = function( self, variable )
        local cvar = variable_to_gmodconvar[ variable ]
        if cvar == nil then
            return gmodconvar_defaults[ variable ]
        end

        local type_str = types[ variable ]

        if type_str == "number" then
            local float_value = GModConVar_getFloat( cvar )
            self[ variable ] = float_value
            return float_value
        elseif type_str == "integer" then
            local integer_value = GModConVar_getInt( cvar )
            self[ variable ] = integer_value
            return integer_value
        elseif type_str == "boolean" then
            local bool_value = GModConVar_getBool( cvar )
            self[ variable ] = bool_value
            return bool_value
        end

        local str_value = GModConVar_getString( cvar )
        self[ variable ] = str_value
        return str_value
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.console.Variable, ( number | nil )>
local mins = {}

setmetatable( mins, {
    __index = function( self, variable )
        local cvar = variable_to_gmodconvar[ variable ]
        if cvar == nil then
            return nil
        end

        local float_min = GModConVar_getMin( cvar )
        self[ variable ] = float_min
        return float_min
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.console.Variable, ( number | nil )>
local maxs = {}

setmetatable( maxs, {
    __index = function( self, variable )
        local cvar = variable_to_gmodconvar[ variable ]
        if cvar == nil then
            return nil
        end

        local float_max = GModConVar_getMax( cvar )
        self[ variable ] = float_max
        return float_max
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.console.Variable, dreamwork.std.Hook<dreamwork.std.console.VariableValue>>
local hooks = {}

setmetatable( hooks, {
    __index = function( self, variable )
        local hook = Hook( represent( variable ) )
        self[ variable ] = hook
        return hook
    end,
    __mode = "k"
} )

---@type table<string, dreamwork.std.console.Variable>
local variables = {}

gc_setTableRules( variables, false, true )


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

---@param str_key string
---@return any
---@protected
function Variable:__index( str_key )
    if str_key == "type" then
        return types[ self ]
    elseif str_key == "name" then
        return gmodconvar_names[ self ]
    elseif str_key == "description" then
        return gmodconvar_descriptions[ self ]
    elseif str_key == "flags" then
        return gmodconvar_flags[ self ]
    elseif str_key == "default" then
        return gmodconvar_defaults[ self ]
    elseif str_key == "min" then
        return mins[ self ]
    elseif str_key == "max" then
        return maxs[ self ]
    elseif str_key == "value" then
        return values[ self ]
    end

    local int32_flag = console.flag( str_key )
    if int32_flag == nil then
        return raw_index( Variable, str_key )
    end

    return rbit_band( gmodconvar_flags[ self ], int32_flag ) ~= 0
end

---@param str_key string
---@param value any
---@protected
function Variable:__newindex( str_key, value )
    if str_key == "value" then
        local cvar_type = types[ self ]
        if cvar_type == "boolean" then
            local bool_value = toboolean( value )
            engine_consoleCommandRun( gmodconvar_names[ self ], bool_value and "1" or "0" )
            values[ self ] = bool_value
        elseif cvar_type == "integer" or cvar_type == "number" then
            local float_value = raw_tonumber( value, 10 ) or 0.0
            if cvar_type == "integer" then
                float_value = math_floor( float_value )
            end

            engine_consoleCommandRun( gmodconvar_names[ self ], string_format( "%f", float_value ) )
            values[ self ] = float_value
        else
            local str_value = tostring( value )
            engine_consoleCommandRun( gmodconvar_names[ self ], str_value )
            values[ self ] = str_value
        end
    elseif str_key == "type" then
        types[ self ] = value
    else
        error( "attempt to modify unknown console variable property", 2 )
    end
end

---@param options dreamwork.std.console.VariableOptions
---@protected
function Variable:__init( options )
    local str_name = options.name
    gmodconvar_names[ self ] = str_name

    local cvar_type = options.type or "string"
    types[ self ] = cvar_type

    local cvar = engine_consoleVariableGet( str_name )
    if cvar == nil then
        local str_description = options.description or ""
        gmodconvar_descriptions[ self ] = str_description

        local str_default = options.default

        if str_default == nil then
            if cvar_type == "boolean" then
                str_default = false
            elseif cvar_type == "integer" or cvar_type == "number" then
                str_default = 0
            else
                str_default = ""
            end
        end

        local default_type = type( str_default )
        if default_type ~= cvar_type then
            error( string_format( "default type (%s) does not match variable type (%s)", default_type, cvar_type ), 3 )
        end

        if cvar_type == "boolean" then
            str_default = str_default and "1" or "0"
        elseif cvar_type == "integer" or cvar_type == "number" then
            str_default = tostring( str_default ) or "0"
        else
            str_default = tostring( str_default ) or ""
        end

        ---@cast str_default string

        local int32_flags = console.flags( options.flags or 0, options )
        gmodconvar_flags[ self ] = int32_flags

        local int32_min, int32_max

        if cvar_type ~= "string" then
            int32_min = options.min

            if int32_min ~= nil and cvar_type == "integer" then
                int32_min = math_floor( int32_min )
            elseif cvar_type == "boolean" then
                int32_min = 0
            end

            int32_max = options.max

            if int32_max ~= nil and cvar_type == "integer" then
                int32_max = math_floor( int32_max )
            elseif cvar_type == "boolean" then
                int32_max = 1
            end

            mins[ self ], maxs[ self ] = int32_min, int32_max
        end

        cvar = engine_consoleVariableCreate( str_name, str_default, int32_flags, str_description, int32_min, int32_max )
    end

    if cvar == nil then
        error( "failed to create console variable, unknown error", 3 )
    else
        variable_to_gmodconvar[ self ] = cvar
    end

    variables[ str_name ] = self
end

---@return string
---@protected
function Variable:__tostring()
    return string_format( "console.Variable: %p [%s][%s]", self, gmodconvar_names[ self ], values[ self ] )
end

--- [SHARED AND MENU]
---
--- The console variable class.
---
---@class dreamwork.std.console.VariableClass : dreamwork.std.console.Variable
---@field __base dreamwork.std.console.Variable
---@overload fun( options: dreamwork.std.console.VariableOptions ): dreamwork.std.console.Variable
local VariableClass = class.create( Variable )
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
---@param cvar_type dreamwork.std.console.VariableType The type of the console variable.
---@return dreamwork.std.console.Variable variable The `console.Variable` object.
---@overload fun( str_name: string, cvar_type: "boolean"): dreamwork.std.console.Variable<boolean>
---@overload fun( str_name: string, cvar_type: "integer"): dreamwork.std.console.Variable<integer>
---@overload fun( str_name: string, cvar_type: "number"): dreamwork.std.console.Variable<number>
---@overload fun( str_name: string, cvar_type: "string"): dreamwork.std.console.Variable<string>
function VariableClass.get( str_name, cvar_type )
    local variable = variables[ str_name ]
    if variable == nil then
        if not engine_consoleVariableExists( str_name ) then
            error( "console variable '" .. str_name .. "' does not exist", 2 )
        end

        local params = {
            name = str_name,
            type = cvar_type
        }

        if cvar_type == "boolean" then
            params.default = false
        elseif cvar_type == "number" or cvar_type == "integer" then
            params.default = 0
        else
            params.default = ""
        end

        return VariableClass( params )
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
        return GModConVar_getString( object )
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
        return GModConVar_getInt( object )
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
        return GModConVar_getFloat( object )
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
        return GModConVar_getBool( object )
    end
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
function VariableClass.revert( name )
    local object = engine_consoleVariableGet( name )
    if object == nil then
        error( "Variable '" .. name .. "' does not exist.", 2 )
    end

    engine_consoleCommandRun( name, GModConVar_getDefault( object ) )
end

do

    local GModConVar_getHelpText = GModConVar.GetHelpText

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
        end

        return GModConVar_getHelpText( object )
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
    end

    return GModConVar_getDefault( object )
end

do

    local GModConVar_getFlags = GModConVar.GetFlags

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
        end

        return GModConVar_getFlags( object )
    end

    VariableClass.getFlags = getFlags

    --- [SHARED AND MENU]
    ---
    --- Sets the value of the `console.Variable` object.
    ---
    ---@param name string The name of the console variable.
    ---@param value dreamwork.std.console.VariableValue The value to set.
    function VariableClass.set( name, value )
        if rbit_band( getFlags( name ), 8192 ) ~= 0 and not LUA_SERVER then
            error( "replicated convar is cannot be changed by client.", 2 )
        end

        local cvar_type = raw_type( value )
        if cvar_type == "boolean" then
            ---@cast value boolean
            engine_consoleCommandRun( name, value and "1" or "0" )
        elseif cvar_type == "string" then
            ---@cast value string
            engine_consoleCommandRun( name, value )
        elseif cvar_type == "number" then
            ---@cast value number | integer

            if (value % 1) == 0 then
                ---@cast value integer
                engine_consoleCommandRun( name, string_format( "%d", value ) )
            else
                ---@cast value number
                engine_consoleCommandRun( name, string_format( "%f", value ) )
            end
        end

        error( "invalid value type, must be boolean, string, integer or number.", 2 )
    end

end

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
    end

    return GModConVar_isFlagSet( object, flags )
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
    end

    return GModConVar_getMin( object )
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
    end

    return GModConVar_getMax( object )
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
    end

    return GModConVar_getMin( object ), GModConVar_getMax( object )
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
---@generic T
---@param self dreamwork.std.console.Variable<T>
---@param handler dreamwork.std.Hook<T> | dreamwork.std.Mixin<T> | fun( value: T )
function Variable:attach( handler )
    hooks[ self ]:attach( "peek", handler )
end

--- [SHARED AND MENU]
---
--- Attaches a handler function to the hook that automatically detaches
--- itself right before being invoked, so it only ever runs once.
---
---@generic T
---@param self dreamwork.std.console.Variable<T>
---@param handler dreamwork.std.Hook<T> | dreamwork.std.Mixin<T> | fun( value: T )
function Variable:once( handler )
    hooks[ self ]:once( "peek", handler )
end

--- [SHARED AND MENU]
---
--- Detaches a previously attached handler from the given stage of the hook.
--- If the hook is currently running, the handler is replaced with a no-op and
--- the actual removal is deferred until the hook finishes running.
---
---@param handler dreamwork.std.Hook<T> | dreamwork.std.Mixin<T> | fun( value: T )
function Variable:detach( handler )
    hooks[ self ]:detach( "peek", handler )
end

--- [SHARED AND MENU]
---
--- Cancels the hook if it is currently running, and removes every handler,
--- resetting their priority tables as well.
---
function Variable:clear()
    hooks[ self ]:clear()
end

--- [SHARED AND MENU]
---
--- Waits for the `console.Variable` object to change.
---
---@generic T
---@param self dreamwork.std.console.Variable<T>
---@return T new_value
---@async
function Variable:await()
    return hooks[ self ]:await( "peek" )
end

---@param error_value string | dreamwork.std.Error
local function error_handler( error_value )
    return engine_hookCall( "dreamwork.lua.error", error_value, 2 )
end

engine.hookCatch( "dreamwork.console.variable.change", "variable.change", function( str_name, str_old, str_new )
    local variable = variables[ str_name ]
    if variable == nil then return end

    local cvar_type = variable.type
    local old_value, new_value

    if cvar_type == "boolean" then
        old_value, new_value = str_old == "1", str_new == "1"
    elseif cvar_type == "integer" or cvar_type == "number" then
        old_value, new_value = raw_tonumber( str_old, 10 ) or 0, raw_tonumber( str_new, 10 ) or 0
    else
        old_value, new_value = str_old, str_new
    end

    values[ variable ] = old_value

    local hook = hooks[ variable ]
    xpcall( hook.call, error_handler, hook, new_value )

    values[ variable ] = new_value
end, -1000 )
