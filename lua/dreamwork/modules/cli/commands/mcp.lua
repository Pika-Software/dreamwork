local dreamwork_cli = dreamwork.cli
local std = dreamwork.std

local cli_error = dreamwork_cli.error
local cli_printHeader = dreamwork_cli.printHeader

local LUA_SERVER = std.LUA_SERVER
local LUA_CLIENT = std.LUA_CLIENT

local console_Variable = std.console.Variable

---@type dreamwork.mcp | nil
local mcp = dreamwork.mcp

-- the variables are created by `dreamwork.mcp`
local ENABLED_VARIABLE = "dreamwork_mcp_enabled"
local ALLOW_EXEC_VARIABLE = "dreamwork_mcp_allow_exec"
local ALLOW_CAPTURE_VARIABLE = "dreamwork_mcp_allow_capture"

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
            if LUA_SERVER then
                if console_Variable.getString( ENABLED_VARIABLE ) == "" then
                    lines[ #lines + 1 ] = "enabled: " .. format_bool( mcp.isEnabled() ) .. " (developer)"
                else
                    lines[ #lines + 1 ] = "enabled: " .. format_bool( mcp.isEnabled() )
                end

                lines[ #lines + 1 ] = "bridge: " .. ((mcp.bridge ~= nil) and "connected" or "missing")
            elseif LUA_CLIENT then
                lines[ #lines + 1 ] = "allow_exec: " .. format_bool( console_Variable.getBoolean( ALLOW_EXEC_VARIABLE ) )
                lines[ #lines + 1 ] = "allow_capture: " .. format_bool( console_Variable.getBoolean( ALLOW_CAPTURE_VARIABLE ) )
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

---@type dreamwork.cli.Setting[]
local settings = {}

if LUA_SERVER then
    settings[ #settings + 1 ] = {
        name = "enabled",
        variable = ENABLED_VARIABLE,
        type = "toggle"
    }
end

if LUA_CLIENT then
    settings[ #settings + 1 ] = {
        name = "allow_exec",
        variable = ALLOW_EXEC_VARIABLE,
        type = "boolean"
    }

    settings[ #settings + 1 ] = {
        name = "allow_capture",
        variable = ALLOW_CAPTURE_VARIABLE,
        type = "boolean"
    }
end

if #settings ~= 0 then
    mcp_group:settings( {
        name = "config",
        description = "Shows or changes MCP settings, 'reset' restores the default.",
        settings = settings
    } )
end
