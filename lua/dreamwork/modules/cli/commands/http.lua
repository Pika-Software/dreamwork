local dreamwork_cli = dreamwork.cli

local cli_error = dreamwork_cli.error
local cli_shift = dreamwork_cli.shift
local cli_complete = dreamwork_cli.complete
local cli_printHeader = dreamwork_cli.printHeader

local std = dreamwork.std

local console = std.console
local console_Variable = console.Variable

local http = std.http

local github = http.github
local github_ratelimit = github.ratelimit
local github_getRateLimit = github.getRateLimit

local time_now = std.time.now
local tostring = std.tostring
local string_format = std.string.format

--- The Github API token variable, created by `std.http.github`.
local TOKEN_VARIABLE = "dreamwork_github_token"

--- [SHARED AND MENU]
---
--- The http commands, `dreamwork_sci http <command>`.
---
local http_group = dreamwork_cli.group( "http", "Http client and API commands." )

http_group:settings( {
    name = "client",
    description = "Shows or changes the settings of the http client, 'reset' restores the default.",
    settings = {
        {
            name = "timeout",
            variable = "dreamwork_http_timeout",
            type = "number"
        },
        {
            name = "timeout_grace",
            variable = "dreamwork_http_timeout_grace",
            type = "number"
        },
        {
            name = "cache_ttl",
            variable = "dreamwork_http_cache_ttl",
            type = "number"
        },
        {
            name = "cache_entries",
            variable = "dreamwork_http_cache_entries",
            type = "integer"
        },
        {
            name = "max_redirects",
            variable = "dreamwork_http_max_redirects",
            type = "integer"
        },
        {
            name = "cache_size",
            variable = "dreamwork_http_cache_size",
            type = "integer"
        },
        {
            name = "cache_total_size",
            variable = "dreamwork_http_cache_total_size",
            type = "integer"
        },
        {
            name = "cache_lifetime",
            variable = "dreamwork_http_cache_lifetime",
            type = "integer"
        }
    }
} )

--- [SHARED AND MENU]
---
--- The Github API commands, `dreamwork_sci http github <command>`.
---
local github_group = http_group:group( "github", "Github API commands." )

--- Formats the seconds left until the unix time `reset`.
---
---@param reset integer
---@return string
local function format_reset( reset )
    local left = reset - time_now()
    if left <= 0 then
        return "reset"
    elseif left < 60 then
        return string_format( "resets in %ds", left )
    end

    return string_format( "resets in %dm %ds", (left - left % 60) / 60, left % 60 )
end

--- Formats the token for display, without printing the secret.
---
---@param token string
---@return string
local function format_token( token )
    if token == "" then
        return "<not set>"
    end

    return string_format( "<set, %d characters>", #token )
end

--- The resources of the `/rate_limit` response that are shown.
---
---@type string[]
local resources = { "core", "search", "code_search", "graphql" }

github_group:register( "status", {
    description = "Shows the token state and the rate limits of the Github API.",
    ---@async
    on_run = function()
        ---@type string[]
        local lines = {
            "token: " .. format_token( console_Variable.getString( TOKEN_VARIABLE ) )
        }

        local ok, data = github_getRateLimit()
        if not ok then
            -- the last state seen on a response is still useful
            if github_ratelimit.remaining ~= nil then
                lines[ #lines + 1 ] = string_format( "last known: %d/%d left, %s", github_ratelimit.remaining, github_ratelimit.limit, format_reset( github_ratelimit.reset or 0 ) )
            end

            cli_printHeader( lines, "Github API" )
            cli_error( "%s", tostring( data ) )
            return
        end

        ---@cast data table
        local data_resources = data.resources or {}

        local core = data_resources.core
        if core ~= nil then
            lines[ #lines + 1 ] = string_format( "limit: %d requests per hour", core.limit )
        end

        for index = 1, #resources, 1 do
            local name = resources[ index ]
            local resource = data_resources[ name ]

            if resource ~= nil then
                lines[ #lines + 1 ] = string_format( "%s: %d/%d left, %s", name, resource.remaining, resource.limit, format_reset( resource.reset ) )
            end
        end

        cli_printHeader( lines, "Github API" )
    end
} )

github_group:register( "token", {
    description = "Shows or changes the Github API token, 'reset' restores the default. See https://github.com/settings/tokens",
    usage = "[token|reset]",
    on_run = function( _, args, argument_string )
        if args[ 1 ] == nil then
            cli_printHeader( { "token: " .. format_token( console_Variable.getString( TOKEN_VARIABLE ) ) }, "Github API" )
            return
        end

        local variable = console_Variable.get( TOKEN_VARIABLE, "string" )

        if args[ 1 ] == "reset" and args[ 2 ] == nil then
            variable:revert()
        else
            variable.value = argument_string
        end

        cli_printHeader( { "token: " .. format_token( variable.value ) }, "Github API" )
    end,
    on_type = function( _, _, argument_string )
        local value, rest = cli_shift( argument_string )
        if rest ~= nil then
            return nil
        end

        return cli_complete( value, { "reset" } )
    end
} )
