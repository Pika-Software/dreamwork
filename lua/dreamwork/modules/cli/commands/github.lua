local dreamwork_cli = dreamwork.cli
local std = dreamwork.std

local cli_error = dreamwork_cli.error
local cli_printHeader = dreamwork_cli.printHeader
local cli_complete = dreamwork_cli.complete
local cli_shift = dreamwork_cli.shift

local github = std.http.github
local github_config = github.config
local github_ratelimit = github.ratelimit
local github_getRateLimit = github.getRateLimit

local dreamwork_storage = dreamwork.storage
local storage_read = dreamwork_storage.read
local storage_write = dreamwork_storage.write
local storage_delete = dreamwork_storage.delete

local time_now = std.time.now
local tostring = std.tostring
local string_len = std.string.len
local string_format = std.string.format

--- The storage key of the Github API token.
local TOKEN_KEY = "dreamwork.github.token"

--- The default token, taken before the saved value is applied.
local TOKEN_DEFAULT = github_config.token

do
    local saved = storage_read( TOKEN_KEY )
    if saved ~= nil then
        github_config.token = saved
    end
end

--- [SHARED AND MENU]
---
--- The Github API commands, `dreamwork_sci github <command>`.
---
local github_group = dreamwork_cli.group( "github", "Github API commands." )

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

    return string_format( "<set, %d characters>", string_len( token ) )
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
            "token: " .. format_token( github_config.token )
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

github_group:register( "set_token", {
    description = "Shows or changes the Github API token, 'reset' restores the default. See https://github.com/settings/tokens",
    usage = "[token|reset]",
    on_run = function( _, args, argument_string )
        if args[ 1 ] == nil then
            cli_printHeader( { "token: " .. format_token( github_config.token ) }, "Github API" )
            return
        end

        if args[ 1 ] == "reset" and args[ 2 ] == nil then
            storage_delete( TOKEN_KEY )
            github_config.token = TOKEN_DEFAULT
            cli_printHeader( { "token: " .. format_token( github_config.token ) }, "Github API" )
            return
        end

        storage_write( TOKEN_KEY, argument_string )
        github_config.token = argument_string
        cli_printHeader( { "token: " .. format_token( github_config.token ) }, "Github API" )
    end,
    on_type = function( _, argument_string )
        local value, rest = cli_shift( argument_string )
        if rest ~= nil then
            return nil
        end

        return cli_complete( value, { "reset" } )
    end
} )
