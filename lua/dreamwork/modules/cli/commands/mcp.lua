local dreamwork_cli = dreamwork.cli
local std = dreamwork.std

local cli_error = dreamwork_cli.error
local cli_printHeader = dreamwork_cli.printHeader

local LUA_SERVER = std.LUA_SERVER
local LUA_CLIENT = std.LUA_CLIENT

---@type dreamwork.mcp | nil
local mcp = dreamwork.mcp

--- [SHARED]
---
--- MCP commands, `dreamwork_sci mcp <command>` / `dreamwork_cci mcp <command>`.
---
local mcp_group = dreamwork_cli.group( "mcp", "Model Context Protocol (unknown-gd/gm_mcp) controls." )

---@param value boolean
---@return string
local function format_bool( value )
    return value and "true" or "false"
end

mcp_group:register( "status", {
    description = "Shows whether MCP is loaded and the current config flags.",
    on_run = function()
        local loaded = mcp ~= nil

        ---@type string[]
        local lines = {
            "loaded: " .. format_bool( loaded )
        }

        if mcp == nil then
            if LUA_SERVER then
                lines[ #lines + 1 ] = "enabled: false"
                lines[ #lines + 1 ] = "bridge: missing"
            elseif LUA_CLIENT then
                lines[ #lines + 1 ] = "allow_exec: false"
                lines[ #lines + 1 ] = "allow_capture: false"
            end
        else
            local config = mcp.config

            if LUA_SERVER then
                if config ~= nil and config.enabled == nil then
                    lines[ #lines + 1 ] = "enabled: " .. format_bool( mcp.isEnabled() ) .. " (developer)"
                else
                    lines[ #lines + 1 ] = "enabled: " .. format_bool( config ~= nil and config.enabled == true )
                end

                lines[ #lines + 1 ] = "bridge: " .. ((mcp.bridge ~= nil) and "connected" or "missing")
            elseif LUA_CLIENT then
                lines[ #lines + 1 ] = "allow_exec: " .. format_bool( config == nil or config.allow_exec ~= false )
                lines[ #lines + 1 ] = "allow_capture: " .. format_bool( config == nil or config.allow_capture ~= false )
            end
        end

        cli_printHeader( lines, "MCP" )

        if not loaded then
            if LUA_SERVER then
                cli_error( "MCP module is not loaded (native mcp binary missing)." )
            else
                cli_error( "MCP module is not loaded on this client." )
            end
        end
    end
} )

if mcp == nil then
    return
end

local config = mcp.config

---@type dreamwork.cli.Setting[]
local settings = {}

if LUA_SERVER then
    settings[ #settings + 1 ] = {
        name = "enabled",
        key = "dreamwork.mcp.enabled",
        description = "When unset (reset), follows the developer convar; true/false overrides. When false, tool calls are rejected.",
        target = config,
        field = "enabled",
        type = "boolean",
        on_change = function( value )
            if value == nil then
                mcp.sync()
            elseif value then
                mcp.enable()
            else
                mcp.disable()
            end
        end
    }
end

if LUA_CLIENT then
    settings[ #settings + 1 ] = {
        name = "allow_exec",
        key = "dreamwork.mcp.allow_exec",
        description = "When false, this client refuses remote MCP Lua execution.",
        target = config,
        field = "allow_exec",
        type = "boolean"
    }

    settings[ #settings + 1 ] = {
        name = "allow_capture",
        key = "dreamwork.mcp.allow_capture",
        description = "When false, this client refuses remote MCP screenshot capture.",
        target = config,
        field = "allow_capture",
        type = "boolean"
    }
end

if #settings ~= 0 then
    mcp_group:settings( {
        name = "config",
        description = "Shows or changes saved MCP settings, 'reset' restores the default.",
        settings = settings
    } )
end

if LUA_SERVER then
    -- Apply saved override, or follow developer when unset.
    if config.enabled == true then
        mcp.enable()
    elseif config.enabled == false then
        mcp.disable()
    else
        mcp.sync()
    end
end
