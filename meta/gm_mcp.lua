---@meta gm_mcp

--- [SERVER]
---
--- Queued command dequeued by `mcp.pollCommand`.
---
--- Produced by the native bridge after an MCP tool request arrives on `127.0.0.1:17905`
--- (override with `GM_MCP_HOST` / `GM_MCP_PORT`).
---
---@class gm_mcp.Command
---@field tool "exec_lua_code" | "gmod_players" | "gmod_entities" | "screenshot" | "gmod_status" | string The MCP tool that produced the command.
---@field state "server" | "client" | string Execution side. Screenshots are always `"client"`; listing tools are `"server"`.
---@field code string Lua source for `exec_lua_code`, or a placeholder token for other tools (`"players"`, `"entities"`, `"screenshot"`).
---@field target string | nil Client nick, SteamID or SteamID64. Required for client `exec_lua_code` and `screenshot`.
---@field classFilter string | nil Optional case-insensitive substring for `gmod_entities`.
---@field customCheck string | nil Optional Lua body for `gmod_entities`; the entity is available as `entity`, return `true` to include it.
---@field limit number | nil Max entities for `gmod_entities` (`1`–`200`, default `100`).
---@field requestId string | nil Correlation id for `respondLua` / `respondScreenshot` when the MCP client waits for a result.
---@field returnResult boolean `true` when the MCP client waits for a Lua / JSON result.

--- [SERVER]
---
--- Connection status snapshot from `mcp.getStatus`.
---
---@class gm_mcp.Status
---@field connected boolean `true` when Garry's Mod is advertised as ready.
---@field message string Human-readable status shown to the MCP client.

--- [SERVER]
---
--- Native MCP bridge from [unknown-gd/gm_mcp](https://github.com/unknown-gd/gm_mcp).
---
--- Available after `require( "mcp" )` (`gmsv_mcp_*`). Opens a localhost TCP JSON listener (default `127.0.0.1:17905`) for the Node / Bun MCP server, queues tool commands for Lua, and blocks the HTTP handlers until `respondLua` / `respondScreenshot` complete (or time out).
---
--- ```lua
--- require( "mcp" )
---
--- mcp.setStatus( true, "Garry's Mod is connected." )
---
--- timer.Create( "mcp_poll", 0.1, 0, function()
---     local command = mcp.pollCommand()
---     if command == nil then return end
---     -- run the tool, then:
---     -- mcp.respondLua( command.requestId, true, json )
---     -- mcp.respondScreenshot( command.requestId, true, jpeg_bytes )
--- end )
--- ```
---
--- Limits enforced by the bridge: Lua code / `customCheck` ≤ `60 KiB`, screenshot ≤ `1 MiB`, entity `limit` ≤ `200`, target / `classFilter` ≤ `256` bytes. Screenshot and Lua-result waits time out after `10` seconds.
---
--- [View documents](https://github.com/unknown-gd/gm_mcp)
---
---@class gm_mcp
mcp = {}

--- [SERVER]
---
--- Publishes the connection status answered by the MCP `gmod_status` tool / `{"action":"status"}` probe.
---
---@param connected boolean `true` when Garry's Mod is ready to handle tool commands.
---@param message string Human-readable status shown to the MCP client.
function mcp.setStatus( connected, message ) end

--- [SERVER]
---
--- Returns the last status published with `mcp.setStatus`.
---
---@return gm_mcp.Status status
---@nodiscard
function mcp.getStatus() end

--- [SERVER]
---
--- Returns whether the localhost TCP bridge listener is running.
---
---@return boolean running
---@nodiscard
function mcp.isRunning() end

--- [SERVER]
---
--- Stops the localhost listener, clears the command queue and fails any pending screenshot / Lua-result waiters.
---
--- Also runs automatically from the module's `gmod13_close` destructor.
---
function mcp.shutdown() end

--- [SERVER]
---
--- Pops the next queued tool command, or returns `nil` when the queue is empty.
---
--- Poll regularly (e.g. every `0.1` s). `requestId` is set when the bridge is waiting for `respondLua` or `respondScreenshot`.
---
---@return gm_mcp.Command | nil command The next command, or `nil`.
---@nodiscard
function mcp.pollCommand() end

--- [SERVER]
---
--- Completes a pending Lua / JSON tool result waited on by the bridge.
---
--- When `ok` is `true`, `payload` must be the JSON string produced by the addon (typically `{"value":...}`). When `ok` is `false`, `payload` is the error message string.
---
---@param requestId string The `requestId` from `pollCommand`.
---@param ok boolean `true` if the tool succeeded.
---@param payload string Encoded success JSON, or an error message when `ok` is `false`.
function mcp.respondLua( requestId, ok, payload ) end

--- [SERVER]
---
--- Fails a waiting Lua exec with a console / runtime error (not a normal `respondLua` path).
---
--- - `mcp.respondError( message )` — fail the active polled exec, if any.
--- - `mcp.respondError( requestId, message )` — fail that specific pending exec.
---
--- Returns `true` if a waiting MCP request was notified. Prefer this from `OnLuaError` /
--- `OnClientLuaError` hooks instead of `respondLua( id, false, ... )`.
---
---@param requestIdOrMessage string Request id when failing a specific wait, or the error message when failing the active wait.
---@param message string | nil Error message when the first argument is a request id.
---@return boolean delivered
function mcp.respondError( requestIdOrMessage, message ) end

--- [SERVER]
---
--- Completes a pending screenshot waited on by the bridge.
---
--- When `ok` is `true`, `payload` must be the raw JPEG bytes (empty or over `1 MiB` is rejected by the bridge). When `ok` is `false`, `payload` is the error message string.
---
---@param requestId string The `requestId` from `pollCommand`.
---@param ok boolean `true` if the capture succeeded.
---@param payload string JPEG binary string, or an error message when `ok` is `false`.
function mcp.respondScreenshot( requestId, ok, payload ) end
