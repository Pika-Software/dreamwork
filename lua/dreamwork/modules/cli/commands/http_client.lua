local dreamwork_engine = dreamwork.engine
local dreamwork_cli = dreamwork.cli
local dreamwork_std = dreamwork.std

local dreamwork_storage = dreamwork.storage
local storage_read = dreamwork_storage.read
local storage_write = dreamwork_storage.write
local storage_delete = dreamwork_storage.delete

local storage_http = dreamwork_storage.http
local storage_http_prune = storage_http.prune

local engine_console = dreamwork_engine.console
local console_message = engine_console.message
local console_messageColored = engine_console.messageColored

local http = dreamwork_std.http

local raw = dreamwork_std.raw
local raw_tonumber = raw.tonumber
local raw_tostring = raw.tostring

local string = dreamwork_std.string
local string_sub = string.sub
local string_len = string.len
local string_match = string.match
local string_format = string.format

local math_floor = dreamwork_std.math.floor

local color_scheme = dreamwork_std.color.Scheme
local COLOR_NAME = color_scheme.dreamwork_info
local COLOR_VALUE = color_scheme.light_gray
local COLOR_DESCRIPTION = color_scheme.suva_gray
local COLOR_ERROR = color_scheme.dreamwork_warn


---@class dreamwork.cli.http_client.Setting
---@field name string The name typed in the command.
---@field key string The key of the saved value in `dreamwork.storage`.
---@field description string
---@field target table The config table that receives the value.
---@field field string The field of the config table.
---@field type "number" | "integer" | "string"
---@field min? number
---@field max? number
---@field secret? boolean If `true`, the value is never printed.
---@field on_change? fun() Called after the value was changed.
---@field default? number | string Taken from the config table before the saved value is applied.

---@type dreamwork.cli.http_client.Setting[]
local settings = {
    {
        name = "timeout",
        key = "dreamwork.http.timeout",
        description = "The default timeout for http requests in seconds.",
        target = http.client.config,
        field = "timeout",
        type = "number",
        min = 0,
        max = 300
    },
    {
        name = "cache_ttl",
        key = "dreamwork.http.cache.ttl",
        description = "The cache time to live for the dreamwork http library in minutes.",
        target = http.client.config,
        field = "cache_ttl",
        type = "number",
        min = 0,
        max = 40320
    },
    {
        name = "cache_entries",
        key = "dreamwork.http.cache.entries",
        description = "The maximum number of responses kept in the dreamwork http session cache, 0 disables it.",
        target = http.client.config,
        field = "cache_entries",
        type = "integer",
        min = 0,
        max = 65536
    },
    {
        name = "max_redirects",
        key = "dreamwork.http.max_redirects",
        description = "The default maximum number of redirects followed in Lua by the dreamwork http library (with cookies and chttp).",
        target = http.client.config,
        field = "max_redirects",
        type = "integer",
        min = 0,
        max = 100
    },
    {
        name = "cache_size",
        key = "dreamwork.http.cache_size",
        description = "The maximum size of cached content in KB, used for etag caching in http library.",
        target = storage_http.config,
        field = "cache_size",
        type = "integer",
        min = 0,
        max = 16384
    },
    {
        name = "cache_total_size",
        key = "dreamwork.http.cache_total_size",
        description = "The maximum total size of all cached content in KB, the oldest entries are removed first.",
        target = storage_http.config,
        field = "cache_total_size",
        type = "integer",
        min = 0,
        max = 1048576,
        on_change = storage_http_prune
    },
    {
        name = "cache_lifetime",
        key = "dreamwork.http.cache_lifetime",
        description = "The number of days cached content is kept for, 0 keeps it forever.",
        target = storage_http.config,
        field = "cache_lifetime",
        type = "integer",
        min = 0,
        max = 3650,
        on_change = storage_http_prune
    },
    {
        name = "github_token",
        key = "dreamwork.github.token",
        description = "The Github API token, see https://github.com/settings/tokens",
        target = http.github.config,
        field = "token",
        type = "string",
        secret = true
    }
}

local setting_count = #settings

---@type table<string, dreamwork.cli.http_client.Setting>
local setting_by_name = {}

for index = 1, setting_count, 1 do
    local setting = settings[ index ]
    setting_by_name[ setting.name ] = setting
end

--- Converts the typed or saved string into the value of the setting.
---
---@param setting dreamwork.cli.http_client.Setting
---@param str string
---@return number | string | nil value The value, or `nil` if the string is invalid.
---@return string | nil error_message The reason why the string is invalid.
local function parse_value( setting, str )
    if setting.type == "string" then
        return str, nil
    end

    local value = raw_tonumber( str, 10 )
    if value == nil or value ~= value then
        return nil, "is not a number"
    end

    if setting.type == "integer" and math_floor( value ) ~= value then
        return nil, "is not an integer"
    end

    local min, max = setting.min, setting.max
    if (min ~= nil and value < min) or (max ~= nil and value > max) then
        return nil, string_format( "is out of range [%s, %s]", raw_tostring( min ), raw_tostring( max ) )
    end

    return value, nil
end

---@param setting dreamwork.cli.http_client.Setting
---@param value number | string
---@return string
local function format_value( setting, value )
    if setting.type ~= "string" then
        return raw_tostring( value )
    end

    ---@cast value string

    if setting.secret then
        if value == "" then
            return "<not set>"
        end

        return string_format( "<set, %d characters>", string_len( value ) )
    end

    return "\"" .. value .. "\""
end

---@param setting dreamwork.cli.http_client.Setting
local function print_setting( setting )
    local value = setting.target[ setting.field ]

    console_messageColored( "  " .. setting.name, COLOR_NAME )
    console_messageColored( " = " .. format_value( setting, value ), COLOR_VALUE )

    if value == setting.default then
        console_messageColored( " (default)", COLOR_DESCRIPTION )
    elseif not setting.secret then
        console_messageColored( " (default " .. format_value( setting, setting.default ) .. ")", COLOR_DESCRIPTION )
    end

    console_message( "\n" )
    console_messageColored( "    " .. setting.description .. "\n", COLOR_DESCRIPTION )
end

---@param setting dreamwork.cli.http_client.Setting
---@param value number | string
local function apply_value( setting, value )
    local target, field = setting.target, setting.field
    if target[ field ] == value then
        return
    end

    target[ field ] = value

    local on_change = setting.on_change
    if on_change ~= nil then
        on_change()
    end
end

-- defaults are taken before the saved values are applied
for index = 1, setting_count, 1 do
    local setting = settings[ index ]
    setting.default = setting.target[ setting.field ]

    local saved = storage_read( setting.key )
    if saved ~= nil then
        local value, error_message = parse_value( setting, saved )
        if value == nil then
            dreamwork.Logger:warn( "Saved value of 'http_client %s' %s, the default is used.", setting.name, error_message )
        else
            setting.target[ setting.field ] = value
        end
    end
end

-- once, with the saved limits
storage_http_prune()

dreamwork_cli.register( "http_client", {
    description = "Shows or changes the saved settings of the http client, 'reset' restores the default.",
    usage = "[name] [value|reset]",
    on_run = function( args )
        local name = args[ 1 ]
        if name == nil then
            for index = 1, setting_count, 1 do
                print_setting( settings[ index ] )
            end

            return
        end

        local setting = setting_by_name[ name ]
        if setting == nil then
            console_messageColored( string_format( "Unknown setting '%s', see '%s http_client'.\n", name, dreamwork_cli.Command.name ), COLOR_ERROR )
            return
        end

        local str = args[ 2 ]
        if str == nil then
            print_setting( setting )
            return
        end

        if str == "reset" then
            storage_delete( setting.key )
            apply_value( setting, setting.default )
            print_setting( setting )
            return
        end

        local value, error_message = parse_value( setting, str )
        if value == nil then
            console_messageColored( string_format( "'%s' %s.\n", str, error_message ), COLOR_ERROR )
            return
        end

        storage_write( setting.key, raw_tostring( value ) )
        apply_value( setting, value )
        print_setting( setting )
    end,
    on_type = function( _, argument_string )
        local name, rest = string_match( argument_string, "^(%S*)(.*)$" )

        if rest == "" then
            local name_length = string_len( name )

            ---@type string[]
            local suggestions = {}
            local suggestion_count = 0

            for index = 1, setting_count, 1 do
                local setting_name = settings[ index ].name
                if string_sub( setting_name, 1, name_length ) == name then
                    suggestion_count = suggestion_count + 1
                    suggestions[ suggestion_count ] = setting_name
                end
            end

            return suggestions
        end

        if setting_by_name[ name ] == nil then
            return nil
        end

        return { name .. " reset" }
    end
} )
