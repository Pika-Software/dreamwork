local dreamwork_cli = dreamwork.cli
local std = dreamwork.std

--- [SHARED]
---
--- The transport commands, `dreamwork_sci transport <command>` / `dreamwork_cci transport <command>`.
---
local transport_group = dreamwork_cli.group( "transport", "File transport from the server to the clients." )

-- the variables are created by `dreamwork.transport`, the http ones exist only on the server

---@type dreamwork.cli.Setting[]
local settings = {
    {
        name = "type",
        variable = "dreamwork_transport",
        type = "string",
        choices = { "network", "http", "static" }
    },
    {
        name = "http_connections",
        variable = "dreamwork_transport_http_connections",
        type = "integer"
    }
}

if std.LUA_SERVER then
    settings[ 3 ] = {
        name = "http_port",
        variable = "dreamwork_transport_http_port",
        type = "integer"
    }

    settings[ 4 ] = {
        name = "http_url",
        variable = "dreamwork_transport_http_url",
        type = "string"
    }

    settings[ 5 ] = {
        name = "http_whitelist",
        variable = "dreamwork_transport_http_whitelist",
        type = "boolean"
    }

    settings[ 6 ] = {
        name = "compression",
        variable = "dreamwork_transport_compression",
        type = "string",
        choices = { "auto", "lzma", "deflate", "gzip", "none" }
    }

    settings[ 7 ] = {
        name = "segment_size",
        variable = "dreamwork_transport_segment_size",
        type = "integer"
    }
end

transport_group:settings( {
    name = "config",
    description = "Shows or changes the settings of the transport, 'reset' restores the default. Changes apply when the transport starts again (map change).",
    settings = settings
} )
