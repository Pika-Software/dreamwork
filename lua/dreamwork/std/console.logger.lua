local std = _G.dreamwork.std

---@class dreamwork.std.console
local console = std.console

local color_scheme = std.Color.scheme
local realm_color = color_scheme.realm

local realm_text

if std.LUA_MENU then
    realm_text = "[Main Menu] "
elseif std.LUA_CLIENT then
    realm_text = "[ Client ]  "
elseif std.LUA_SERVER then
    realm_text = "[ Server ]  "
else
    realm_text = "[ Unknown ] "
end

--- [SHARED AND MENU]
---
--- The logger object.
---
---@alias Logger dreamwork.std.console.Logger
---@class dreamwork.std.console.Logger : dreamwork.Object
---@field __class dreamwork.std.console.LoggerClass
---@field title string The logger title.
---@field title_color dreamwork.std.Color The logger title color.
---@field text_color dreamwork.std.Color The logger text color.
---@field interpolation boolean The logger interpolation.
---@field debug_fn fun( dreamwork.std.console.Logger ): boolean The logger debug function.
local Logger = std.class.base( "console.Logger" )

--- [SHARED AND MENU]
---
--- The logger class.
---
---@class dreamwork.std.console.LoggerClass : dreamwork.std.console.Logger
---@field __base dreamwork.std.console.Logger
---@overload fun( options: dreamwork.std.console.Logger.Options? ) : dreamwork.std.console.Logger
local LoggerClass = std.class.create( Logger )
console.Logger = LoggerClass

local developer_cvar = console.Variable.get( "developer", "number" )
local default_debug_fn

if developer_cvar == nil then

    function default_debug_fn()
        return true
    end

else

    function default_debug_fn()
        return developer_cvar.value ~= 0
    end

end

local white_color = color_scheme.white
local primary_text_color = color_scheme.text_primary
local secondary_text_color = color_scheme.text_secondary

---@protected
function Logger:__init( options )
    if options == nil then
        self.title = "unknown"
        self.title_color = white_color
        self.text_color = primary_text_color
        self.interpolation = true
        self.debug_fn = default_debug_fn
    else
        local title = options.title
        if title == nil then
            self.title = "unknown"
        else
            self.title = title
        end

        local color = options.color
        if color == nil then
            self.title_color = color_white
        else
            self.title_color = color
        end

        local text_color = options.text_color
        if text_color == nil then
            self.text_color = primary_text_color
        else
            self.text_color = text_color
        end

        local interpolation = options.interpolation
        if interpolation == nil then
            self.interpolation = true
        else
            self.interpolation = interpolation == true
        end

        local debug_fn = options.debug
        if debug_fn == nil then
            self.debug_fn = default_debug_fn
        else
            self.debug_fn = debug_fn
        end
    end
end

local write_log
do

    local console_write = console.write
    local time_format = std.time.format
    local tostring = std.tostring

    local string = std.string
    local string_len, string_sub = string.len, string.sub
    local string_format, string_gsub = string.format, string.gsub

    --- [SHARED AND MENU]
    ---
    --- Logs a message.
    ---@param color Color The log level color.
    ---@param level string The log level name.
    ---@param str string The log message.
    ---@param ... any The log message arguments to format/interpolate.
    function write_log( object, color, level, str, ... )
        if object.interpolation then
            local args = { ... }
            for index = 1, select( '#', ... ), 1 do
                args[ tostring( index ) ] = tostring( args[ index ] )
            end

            str = string_gsub( str, "{([0-9]+)}", args )
        else
            str = string_format( str, ... )
        end

        local title = object.title

        local title_length = string_len( title )
        if title_length > 64 then
            title = string_sub( title, 1, 64 )
            title_length = 64
            object.title = title
        end

        if ( string_len( str ) + title_length ) > 950 then
            str = string_sub( str, 1, 950 - title_length ) .. "..."
        end

        console_write( secondary_text_color, time_format( "{day}-{month}-{year} {hours}:{minutes}:{seconds}.{milliseconds} " ), realm_color, realm_text, color, level, secondary_text_color, " --> ", object.title_color, title, secondary_text_color, " : ", object.text_color, str .. "\n")
    end

    Logger.log = write_log

end

do

    local info_color = color_scheme.dreamwork_info

    --- [SHARED AND MENU]
    ---
    --- Logs an info message.
    function Logger:info( ... )
        return write_log( self, info_color, "INFO ", ... )
    end

end

do

    local warn_color = color_scheme.dreamwork_warn

    --- [SHARED AND MENU]
    ---
    --- Logs a warning message.
    function Logger:warn( ... )
        return write_log( self, warn_color, "WARN ", ... )
    end

end

do

    local error_color = color_scheme.dreamwork_error

    --- [SHARED AND MENU]
    ---
    --- Logs an error message.
    function Logger:error( ... )
        return write_log( self, error_color, "ERROR", ... )
    end

end

do

    local debug_color = color_scheme.dreamwork_debug

    --- [SHARED AND MENU]
    ---
    --- Logs a debug message.
    function Logger:debug( ... )
        if self.debug_fn( self ) then
            return write_log( self, debug_color, "DEBUG", ... )
        end
    end

end
