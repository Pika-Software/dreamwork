local dreamwork_cli = dreamwork.cli
local std = dreamwork.std

local storage_http = dreamwork.storage.http
local storage_http_prune = storage_http.prune

local http = std.http
local http_client_config = http.client.config
local http_github_config = http.github.config
local storage_http_config = storage_http.config


dreamwork_cli.settings( {
    name = "http_client",
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
        },
        {
            name = "github_token",
            key = "dreamwork.github.token",
            description = "The Github API token, see https://github.com/settings/tokens",
            target = http_github_config,
            field = "token",
            type = "string",
            secret = true
        }
    }
} )

-- once, with the saved limits
storage_http_prune()
