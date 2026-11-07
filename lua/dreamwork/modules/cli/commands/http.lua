local dreamwork_cli = dreamwork.cli
local std = dreamwork.std

local cli_error = dreamwork_cli.error
local cli_printHeader = dreamwork_cli.printHeader
local cli_complete = dreamwork_cli.complete
local cli_shift = dreamwork_cli.shift

local dreamwork_storage = dreamwork.storage
local storage_read = dreamwork_storage.read
local storage_write = dreamwork_storage.write
local storage_delete = dreamwork_storage.delete

local storage_http = dreamwork_storage.http
local storage_http_prune = storage_http.prune
local storage_http_config = storage_http.config

local http = std.http
local http_client_config = http.client.config

local github = http.github
local github_config = github.config
local github_ratelimit = github.ratelimit
local github_getRateLimit = github.getRateLimit

local time_now = std.time.now
local tostring = std.tostring
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
--- The http commands, `dreamwork_sci http <command>`.
---
local http_group = dreamwork_cli.group( "http", "Http client and API commands." )

http_group:settings( {
    name = "client",
    description = "Shows or changes the saved settings of the http client, 'reset' restores the default.",
    settings = {
        {
            name = "timeout",
            key = "dreamwork.http.timeout",
            description = "The default timeout for http requests in seconds.",
            target = http_client_config,
            field = "timeout",
            type = "number",
            min = 0,
            max = 300
        },
        {
            name = "cache_ttl",
            key = "dreamwork.http.cache.ttl",
            description = "The cache time to live for the dreamwork http library in minutes.",
            target = http_client_config,
            field = "cache_ttl",
            type = "number",
            min = 0,
            max = 40320
        },
        {
            name = "cache_entries",
            key = "dreamwork.http.cache.entries",
            description = "The maximum number of responses kept in the dreamwork http session cache, 0 disables it.",
            target = http_client_config,
            field = "cache_entries",
            type = "integer",
            min = 0,
            max = 65536
        },
        {
            name = "max_redirects",
            key = "dreamwork.http.max_redirects",
            description = "The default maximum number of redirects followed in Lua by the dreamwork http library (with cookies and chttp).",
            target = http_client_config,
            field = "max_redirects",
            type = "integer",
            min = 0,
            max = 100
        },
        {
            name = "cache_size",
            key = "dreamwork.http.cache_size",
            description = "The maximum size of cached content in KB, used for etag caching in http library.",
            target = storage_http_config,
            field = "cache_size",
            type = "integer",
            min = 0,
            max = 16384
        },
        {
            name = "cache_total_size",
            key = "dreamwork.http.cache_total_size",
            description = "The maximum total size of all cached content in KB, the oldest entries are removed first.",
            target = storage_http_config,
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
            target = storage_http_config,
            field = "cache_lifetime",
            type = "integer",
            min = 0,
            max = 3650,
            on_change = storage_http_prune
        }
    }
} )

-- once, with the saved limits
storage_http_prune()

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

github_group:register( "token", {
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
    on_type = function( _, _, argument_string )
        local value, rest = cli_shift( argument_string )
        if rest ~= nil then
            return nil
        end

        return cli_complete( value, { "reset" } )
    end
} )
