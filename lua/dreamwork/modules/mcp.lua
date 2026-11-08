---@class dreamwork
local dreamwork = dreamwork

local dreamwork_engine = dreamwork.engine
local dreamwork_Logger = dreamwork.Logger

local dreamwork_exceptions = dreamwork.exceptions
local exceptions_Sentinel = dreamwork_exceptions.Sentinel
local exceptions_tostring = dreamwork_exceptions.tostring

local engine_timer = dreamwork_engine.timer
local engine_timer_create = engine_timer.create
local engine_timer_remove = engine_timer.remove
local engine_timer_start = engine_timer.start
local engine_timer_stop = engine_timer.stop
local engine_hook = dreamwork_engine.hook

---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_pairs = raw.pairs
local raw_select = raw.select

local isTable = std.isTable
local isError = std.isError
local isString = std.isString
local isFunction = std.isFunction

local string = std.string
local string_find = string.find
local string_lower = string.lower
local string_format = string.format
local string_trimSpaces = string.trimSpaces

local table = std.table
local table_remove = table.remove
local table_unpack = table.unpack

local math = std.math
local math_min = math.min
local math_max = math.max
local math_floor = math.floor

local json = std.json
local json_serialize = json.serialize

local pcall = std.pcall
local tostring = std.tostring
local loadstring = std.loadstring

local Emitter = std.Emitter
local Network = std.Network

local LUA_SERVER = std.LUA_SERVER
local LUA_CLIENT = std.LUA_CLIENT


--- Max Lua payload accepted from the bridge / network (matches the native bridge).
local MAX_LUA_CODE_BYTES = 60 * 1024

--- Max screenshot payload accepted over the network (matches the native bridge).
local MAX_SCREENSHOT_BYTES = 1024 * 1024

--- Max length of a client target string.
local MAX_TARGET_BYTES = 256

--- Max entities returned by `gmod_entities`.
local MAX_ENTITY_LIMIT = 200

--- Seconds without a client response before the pending request fails.
local CLIENT_RESULT_TIMEOUT = 10

--- How often the native bridge command queue is polled.
local POLL_INTERVAL = 1

--- JPEG quality used by `render.Capture`.
local SCREENSHOT_QUALITY = 45

--- Network opcodes (one reliable Network message each; large payloads are segmented by `std.Network`).
local MSG_EXEC = 1
local MSG_EXEC_RESULT = 2
local MSG_SCREENSHOT = 3
local MSG_SCREENSHOT_RESULT = 4

--- Length prefix sizes used with BinaryWriter/Reader counted strings.
local ID_LENGTH_BITS = 16
local PAYLOAD_LENGTH_BITS = 32

---
--- [SHARED]
---
--- Dreamwork MCP: bridges the native [`mcp`](https://github.com/unknown-gd/gm_mcp) module to Garry's Mod
--- and shuttles client-side exec / screenshot traffic over `std.Network`.
---

--- Native `require( "mcp" )` library, captured before `dreamwork.mcp` shadows the global name.
---
---@type gm_mcp | nil
local bridge = LUA_SERVER and mcp or nil

--- `true` when the module is re-included (autorefresh), CLI settings are not re-applied then.
local is_reload = dreamwork.mcp ~= nil

---@class dreamwork.mcp
---@field config dreamwork.mcp.Config
---@field bridge gm_mcp | nil The native bridge table, server-only when loaded.
---@field respond_result fun( request_id: string?, ok: boolean, value: any ) Completes a waiting Lua exec with a value or error.
---@field respond_error fun( request_id_or_message: string, message: string? ): boolean Fails the active or a specific waiting Lua exec.
---@field return_result fun( value: any )? Set during a waiting exec so scripts can return a result asynchronously.
local mcp = dreamwork.mcp or {}
dreamwork.mcp = mcp

---@class dreamwork.mcp.Config
---@field enabled boolean | nil Server: accept and execute bridge commands. `nil` follows `developer` (`std.DEVELOPER ~= 0`).
---@field allow_exec boolean Client: allow remote Lua execution from the MCP bridge.
---@field allow_capture boolean Client: allow remote screenshot capture from the MCP bridge.

--- [SHARED]
---
--- The settings of the MCP module, set by the `mcp` console command (`dreamwork_sci` / `dreamwork_cci`).
---
---@type dreamwork.mcp.Config
local config = mcp.config or {
    enabled = nil,
    allow_exec = true,
    allow_capture = true
}

mcp.config = config

--- [SERVER]
---
--- Resolves whether the bridge should accept commands.
--- Uses `config.enabled` when set; otherwise follows `std.DEVELOPER ~= 0`.
---
---@return boolean
function mcp.isEnabled()
    if config.enabled ~= nil then
        return config.enabled == true
    end

    return std.DEVELOPER ~= 0
end

--- Error / lifecycle events: `"error"`, `"command"`, `"enable"`, `"disable"`.
local events = Emitter( "MCP" )

---@param handler fun( message: string, context: table? ) | dreamwork.std.Hook | dreamwork.std.Event
function mcp.onError( handler )
    events:attach( mcp, "error", handler )
end

---@param handler fun( message: string, context: table? ) | dreamwork.std.Hook | dreamwork.std.Event
---@return boolean
function mcp.offError( handler )
    return events:detach( mcp, "error", handler )
end

---@param fmt string
---@param ... any
local function format_error( fmt, ... )
    return string_format( fmt, ... )
end

--- Logs an error and notifies `mcp.onError` handlers.
---
--- The last argument may be a context table for handlers; it is not interpolated into `fmt`.
---
---@param fmt string
---@param ... any
local function report_error( fmt, ... )
    local arg_count = raw_select( "#", ... )
    ---@type table | nil
    local context

    if arg_count ~= 0 and isTable( raw_select( arg_count, ... ) ) then
        context = raw_select( arg_count, ... )
        arg_count = arg_count - 1
    end

    local message = fmt
    if arg_count ~= 0 then
        message = string_format( fmt, table_unpack( { ... }, 1, arg_count ) )
    end

    dreamwork_Logger:error( "MCP: %s", message )
    events:emit( mcp, "error", message, context )
end

--- Shared Network channel for client exec / screenshot traffic.
---@type dreamwork.std.Network | nil
local network

--- `false` once creation failed permanently (server did not register the channel).
---@type boolean
local network_unavailable = false

---@param silent boolean?
---@return dreamwork.std.Network | nil
local function get_network( silent )
    if network ~= nil or network_unavailable then
        return network
    end

    network = Network( "dreamwork.mcp", true )
    network.timeout = CLIENT_RESULT_TIMEOUT + 5
    network.limit = MAX_SCREENSHOT_BYTES + 64 * 1024
    return network
end

---@param writer dreamwork.std.BinaryWriter
---@param opcode integer
local function write_opcode( writer, opcode )
    writer:writeUInt( opcode, 8 )
end

---@param writer dreamwork.std.BinaryWriter
---@param request_id string
local function write_request_id( writer, request_id )
    writer:writeCountedString( request_id, ID_LENGTH_BITS )
end

---@param writer dreamwork.std.BinaryWriter
---@param payload string
local function write_payload( writer, payload )
    writer:writeCountedString( payload, PAYLOAD_LENGTH_BITS )
end

---@param reader dreamwork.std.BinaryReader
---@return integer
local function read_opcode( reader )
    return reader:readUInt( 8 )
end

---@param reader dreamwork.std.BinaryReader
---@return string
local function read_request_id( reader )
    return (reader:readCountedString( ID_LENGTH_BITS ))
end

---@param reader dreamwork.std.BinaryReader
---@return string
local function read_payload( reader )
    return (reader:readCountedString( PAYLOAD_LENGTH_BITS ))
end

---@param value any
---@return string | nil encoded
---@return string | nil err
local function encode_result( value )
    local ok, encoded = pcall( json_serialize, { value = value } )
    if not ok then
        return nil, "Lua result is not JSON serializable."
    end

    if not isString( encoded ) then
        return nil, "Lua result is not JSON serializable."
    end

    return encoded, nil
end

---@param message any
---@param realm string | nil
---@param stack table | nil
---@param name string | nil
---@return string
local function format_lua_error( message, realm, stack, name )
    return json_serialize( {
        message = message,
        realm = realm,
        stack = stack,
        name = name
    } )
end

--- Converts a dreamwork error into an `OnLuaError`-like JSON error, top frame first.
---
---@param error_value dreamwork.std.Error | any
---@param realm string
---@return string
local function format_reported_error( error_value, realm )
    ---@type table[] | nil
    local stack

    if isError( error_value ) then
        ---@cast error_value dreamwork.std.Error
        local error_stack = error_value.stack
        if error_stack ~= nil then
            stack = {}

            local size = error_stack.size
            for index = size, 1, -1 do
                local frame = error_stack[ index ]
                stack[ size - index + 1 ] = {
                    File = frame.source or frame.short_src,
                    Line = frame.currentline,
                    Function = frame.name
                }
            end
        end
    end

    return format_lua_error( exceptions_tostring( error_value ), realm, stack, nil )
end

---@param code string
---@param identifier string
---@return function | nil chunk
---@return string | nil err
local function compile_chunk( code, identifier )
    if not isString( code ) then
        return nil, "Lua code must be a string."
    end

    local code_length = #code

    if code_length > MAX_LUA_CODE_BYTES then
        return nil, format_error( "Lua code exceeds the %d byte limit.", MAX_LUA_CODE_BYTES )
    end

    if code_length == 0 then
        return nil, "Lua code is empty."
    end

    local ok, chunk = pcall( loadstring, code, identifier )
    if not ok then
        return nil, tostring( chunk )
    end

    if not isFunction( chunk ) then
        return nil, "Lua compiler returned an invalid chunk."
    end

    return chunk, nil
end

if LUA_SERVER then

    if bridge == nil or
        not isFunction( bridge.setStatus ) or
        not isFunction( bridge.getStatus ) or
        not isFunction( bridge.pollCommand ) or
        not isFunction( bridge.shutdown ) or
        not isFunction( bridge.isRunning ) or
        not isFunction( bridge.respondLua ) or
        not isFunction( bridge.respondError ) or
        not isFunction( bridge.respondScreenshot ) then
        report_error( "native bridge API is unavailable (require('mcp') did not export setStatus/pollCommand/respondLua/respondError/respondScreenshot)." )
        return
    end

    mcp.bridge = bridge

    local glua_player = dreamwork_engine.requireLibrary( "player" )
    local glua_ents = dreamwork_engine.requireLibrary( "ents" )
    local glua_team = dreamwork_engine.requireLibrary( "team" )

    local player_GetAll = glua_player.GetAll
    local ents_GetAll = glua_ents.GetAll
    local team_GetName = glua_team.GetName

    ---@type table<string, garrysmod.Player>
    local pending_exec = {}

    ---@type table<string, garrysmod.Player>
    local pending_screenshots = {}

    local POLL_TIMER_NAME = "dreamwork.mcp.poll"

    ---@type boolean
    local bridge_running = false

    --- Request id of the Lua exec currently awaited by the native bridge (`return_result`).
    ---@type string | nil
    local active_exec_request_id

    ---@param request_id string | nil
    local function set_active_exec( request_id )
        if isString( request_id ) and request_id ~= "" then
            active_exec_request_id = request_id
        end
    end

    ---@param request_id string | nil
    local function clear_active_exec( request_id )
        if request_id == nil or active_exec_request_id == request_id then
            active_exec_request_id = nil
        end
    end

    ---@param request_id string | nil
    ---@param ok boolean
    ---@param payload string
    local function respond_lua_raw( request_id, ok, payload )
        if request_id == nil or request_id == "" then
            return
        end

        clear_active_exec( request_id )

        local reported, respond_err = pcall( bridge.respondLua, request_id, ok, payload )
        if not reported then
            report_error( "failed to send Lua result (request=%s): %s", request_id, respond_err, {
                request_id = request_id
            } )
        end
    end

    ---@param request_id string | nil
    ---@param ok boolean
    ---@param value any
    function mcp.respond_result( request_id, ok, value )
        if not ok then
            respond_lua_raw( request_id, false, tostring( value ) )
            return
        end

        local encoded, encode_error = encode_result( value )
        if encoded == nil then
            ---@cast encode_error string
            respond_lua_raw( request_id, false, encode_error )
            return
        end

        respond_lua_raw( request_id, true, encoded )
    end

    ---@param request_id string
    ---@param ok boolean
    ---@param payload string
    local function respond_screenshot( request_id, ok, payload )
        local reported, respond_err = pcall( bridge.respondScreenshot, request_id, ok, payload )
        if not reported then
            report_error( "failed to send screenshot (request=%s): %s", request_id, respond_err, {
                request_id = request_id
            } )
        end
    end

    ---@param request_id string
    local function clear_pending_exec( request_id )
        pending_exec[ request_id ] = nil
        engine_timer_remove( "dreamwork.mcp.exec." .. request_id )
    end

    ---@param request_id string
    local function clear_pending_screenshot( request_id )
        pending_screenshots[ request_id ] = nil
        engine_timer_remove( "dreamwork.mcp.shot." .. request_id )
    end

    --- [SERVER]
    ---
    --- Fails a waiting MCP Lua exec. Prefer this from console/error hooks over
    --- `respond_result( id, false, ... )` / `respondLua( id, false, ... )`.
    ---
    --- - `mcp.respond_error( message )` — fail the active waiting server exec (if any).
    --- - `mcp.respond_error( requestId, message )` — fail a specific waiting exec.
    ---
    --- Returns `true` if a waiting MCP request was notified.
    ---
    ---@param request_id_or_message string
    ---@param message string | nil
    ---@return boolean delivered
    function mcp.respond_error( request_id_or_message, message )
        local request_id

        if message == nil then
            -- the native active id also covers client execs, so resolve it here
            request_id, message = active_exec_request_id, request_id_or_message
            if request_id == nil then
                return false
            end
        else
            request_id = request_id_or_message
            if request_id == "" then
                return false
            end
        end

        clear_pending_exec( request_id )
        clear_active_exec( request_id )

        local reported, delivered = pcall( bridge.respondError, request_id, message )
        if not reported then
            report_error( "failed to report Lua error to bridge (request=%s): %s", request_id, delivered, {
                request_id = request_id
            } )

            return false
        end

        return delivered == true
    end

    ---@param vector garrysmod.Vector
    ---@return { x: number, y: number, z: number }
    local function position( vector )
        return { x = vector.x, y = vector.y, z = vector.z }
    end

    ---@param ply garrysmod.Player
    ---@return string | nil
    local function active_weapon_class( ply )
        local weapon = ply:GetActiveWeapon()
        if weapon == nil or not weapon:IsValid() then
            return nil
        end

        return weapon:GetClass()
    end

    --- [SERVER]
    ---
    --- Snapshot of connected players for `gmod_players`.
    ---
    ---@return table[]
    function mcp.get_players()
        local players = {}
        local list = player_GetAll()

        for index = 1, #list, 1 do
            local ply = list[ index ]
            if ply ~= nil and ply:IsValid() then
                players[ #players + 1 ] = {
                    name = ply:Nick(),
                    steam_id = ply:SteamID(),
                    steam_id64 = ply:SteamID64(),
                    team = team_GetName( ply:Team() ),
                    team_id = ply:Team(),
                    alive = ply:Alive(),
                    health = ply:Health(),
                    armor = ply:Armor(),
                    position = position( ply:GetPos() ),
                    model = ply:GetModel(),
                    weapon = active_weapon_class( ply )
                }
            end
        end

        return players
    end

    --- [SERVER]
    ---
    --- Snapshot of entities for `gmod_entities`.
    ---
    ---@param class_filter string | nil
    ---@param custom_check string | nil
    ---@param limit integer | nil
    ---@return { entities: table[], truncated: boolean }
    function mcp.get_entities( class_filter, custom_check, limit )
        limit = math_min( math_max( math_floor( limit or 100 ), 1 ), MAX_ENTITY_LIMIT )

        local filter
        if class_filter ~= nil and class_filter ~= "" then
            filter = string_lower( class_filter )
        end

        ---@type ( fun( entity: garrysmod.Entity ): boolean ) | nil
        local check
        if custom_check ~= nil and custom_check ~= "" then
            if #custom_check > MAX_LUA_CODE_BYTES then
                error( format_error( "customCheck exceeds the %d byte limit.", MAX_LUA_CODE_BYTES ), 2 )
            end

            local factory, compile_error = compile_chunk(
                "return function( entity )\n" .. custom_check .. "\nend",
                "dreamwork.mcp:customCheck"
            )

            if factory == nil then
                error( "customCheck compilation failed: " .. tostring( compile_error ), 2 )
            end

            local ok, result = pcall( factory )
            if not ok or not isFunction( result ) then
                error( "customCheck must compile to a Lua function: " .. tostring( result ), 2 )
            end

            ---@diagnostic disable-next-line: cast-type-mismatch
            ---@cast result function

            check = result
        end

        local entities = {}
        local truncated = false
        local list = ents_GetAll()

        for index = 1, #list, 1 do
            local entity = list[ index ]
            if entity ~= nil and entity:IsValid() and not entity:IsPlayer() then
                local class = entity:GetClass()
                local matches = filter == nil or string_find( string_lower( class ), filter, 1, true ) ~= nil

                if matches and check ~= nil then
                    local ok, included = pcall( check, entity )
                    if not ok then
                        error( "customCheck failed: " .. tostring( included ), 2 )
                    end

                    matches = included == true
                end

                if matches then
                    if #entities >= limit then
                        truncated = true
                        break
                    end

                    entities[ #entities + 1 ] = {
                        index = entity:EntIndex(),
                        class = class,
                        model = entity:GetModel(),
                        position = position( entity:GetPos() )
                    }
                end
            end
        end

        return {
            entities = entities,
            truncated = truncated
        }
    end

    --- [SERVER]
    ---
    --- Resolves a player by nick, SteamID or SteamID64.
    ---
    ---@param target string
    ---@return garrysmod.Player | nil
    ---@return string | nil
    function mcp.resolve_player( target )
        if not isString( target ) then
            return nil, "client target must be a string."
        end

        local normalized = string_trimSpaces( target )
        if normalized == "" then
            return nil, "client target is empty."
        end

        if #normalized > MAX_TARGET_BYTES then
            return nil, format_error( "client target exceeds the %d byte limit.", MAX_TARGET_BYTES )
        end

        local lowered = string_lower( normalized )
        local matches = {}
        local list = player_GetAll()

        for index = 1, #list, 1 do
            local ply = list[ index ]
            if ply ~= nil and ply:IsValid() then
                if string_lower( ply:Nick() ) == lowered
                    or ply:SteamID() == normalized
                    or ply:SteamID64() == normalized then
                    matches[ #matches + 1 ] = ply
                end
            end
        end

        if #matches == 1 then
            return matches[ 1 ], nil
        end

        if #matches > 1 then
            return nil, "client target matches multiple players; use SteamID64."
        end

        return nil, "no connected player matches client target " .. normalized .. "."
    end

    ---@param code string
    ---@param identifier string
    ---@param request_id string | nil
    ---@return boolean success
    ---@return any err
    local function compile_and_run( code, identifier, request_id )
        local chunk, compile_error = compile_chunk( code, identifier )
        if chunk == nil then
            mcp.respond_result( request_id, false, compile_error )
            return false, compile_error
        end

        local previous_return = mcp.return_result
        local result_sent = false

        if request_id ~= nil and request_id ~= "" then
            ---@param value any
            function mcp.return_result( value )
                if result_sent then
                    return
                end

                result_sent = true
                mcp.respond_result( request_id, true, value )
            end
        end

        local run_ok, run_result = pcall( chunk )
        if not run_ok then
            if request_id ~= nil and request_id ~= "" and not result_sent then
                result_sent = true
                mcp.respond_result( request_id, false, tostring( run_result ) )
            end

            if request_id ~= nil and request_id ~= "" then
                mcp.return_result = previous_return
            end

            return false, run_result
        end

        if request_id ~= nil and request_id ~= "" and run_result ~= nil and not result_sent then
            result_sent = true
            mcp.respond_result( request_id, true, run_result )
        end

        if request_id ~= nil and request_id ~= "" then
            mcp.return_result = previous_return
        end

        return true, nil
    end

    ---@param code string
    ---@param target string
    ---@param request_id string | nil
    ---@return boolean
    ---@return string | nil
    local function send_exec_to_client( code, target, request_id )
        local lowered = string_lower( string_trimSpaces( target ) )

        if lowered == "all" or lowered == "tout le monde" then
            if request_id ~= nil and request_id ~= "" then
                return false, "return_result is not supported with target 'all'."
            end

            local list = player_GetAll()
            if #list == 0 then
                return false, "no connected players."
            end

            local channel = get_network()
            if channel == nil then
                return false, "MCP network channel is unavailable."
            end

            channel:transmit( function( _, writer )
                write_opcode( writer, MSG_EXEC )
                write_request_id( writer, "" )
                write_payload( writer, code )
            end, list )

            return true, nil
        end

        local ply, resolve_error = mcp.resolve_player( target )
        if ply == nil then
            return false, resolve_error
        end

        local channel = get_network()
        if channel == nil then
            return false, "MCP network channel is unavailable."
        end

        if request_id ~= nil and request_id ~= "" then
            clear_pending_exec( request_id )
            pending_exec[ request_id ] = ply

            local timer_name = "dreamwork.mcp.exec." .. request_id

            engine_timer_create( timer_name, CLIENT_RESULT_TIMEOUT, 1, function()
                if pending_exec[ request_id ] == ply then
                    clear_pending_exec( request_id )
                    respond_lua_raw( request_id, false, "Client Lua result timed out." )
                end
            end, true )
        end

        channel:transmit( function( _, writer )
            write_opcode( writer, MSG_EXEC )
            write_request_id( writer, request_id or "" )
            write_payload( writer, code )
        end, ply )

        return true, nil
    end

    ---@param command table
    local function request_screenshot( command )
        local request_id = command.requestId or command.request_id
        if not isString( request_id ) or request_id == "" then
            error( "screenshot request is missing its id", 2 )
        end

        local ply, resolve_error = mcp.resolve_player( command.target )
        if ply == nil then
            ---@cast resolve_error string
            respond_screenshot( request_id, false, resolve_error )
            return
        end

        local channel = get_network()
        if channel == nil then
            respond_screenshot( request_id, false, "MCP network channel is unavailable." )
            return
        end

        clear_pending_screenshot( request_id )
        pending_screenshots[ request_id ] = ply

        local timer_name = "dreamwork.mcp.shot." .. request_id

        engine_timer_create( timer_name, CLIENT_RESULT_TIMEOUT, 1, function()
            if pending_screenshots[ request_id ] == ply then
                clear_pending_screenshot( request_id )
                respond_screenshot( request_id, false, "Screenshot timed out." )
            end
        end, true )

        channel:transmit( function( _, writer )
            write_opcode( writer, MSG_SCREENSHOT )
            write_request_id( writer, request_id )
        end, ply )
    end

    --- [SERVER]
    ---
    --- Executes one command dequeued from the native bridge.
    ---
    ---@param command table
    function mcp.execute_command( command )
        if not isTable( command ) then
            error( "invalid MCP command", 2 )
        end

        local request_id = command.requestId or command.request_id

        if not mcp.isEnabled() then
            if isString( request_id ) and request_id ~= "" then
                local tool = command.tool or "exec_lua_code"
                if tool == "screenshot" then
                    respond_screenshot( request_id, false, "MCP is disabled." )
                else
                    respond_lua_raw( request_id, false, "MCP is disabled." )
                end
            end

            return
        end

        local tool = command.tool or "exec_lua_code"
        events:emit( mcp, "command", tool, command )
        dreamwork_Logger:debug( "MCP: command tool=%s state=%s request=%s target=%s", tool, tostring( command.state ), request_id or "-", tostring( command.target or "-" ) )

        if tool == "gmod_status" then
            return
        end

        if tool == "screenshot" then
            if command.state ~= "client" or not isString( command.target ) or string_trimSpaces( command.target ) == "" then
                error( "screenshot requires one client target", 2 )
            end

            request_screenshot( command )
            dreamwork_Logger:debug( "MCP: screenshot requested (target=%s, request=%s).", command.target, request_id or "-" )
            return
        end

        if tool == "gmod_players" then
            local players = mcp.get_players()
            mcp.respond_result( request_id, true, players )
            dreamwork_Logger:debug( "MCP: gmod_players returned %d player(s) (request=%s).", #players, request_id or "-" )
            return
        end

        if tool == "gmod_entities" then
            local snapshot = mcp.get_entities(
                command.classFilter or command.class_filter,
                command.customCheck or command.custom_check,
                command.limit
            )
            mcp.respond_result( request_id, true, snapshot )
            dreamwork_Logger:debug( "MCP: gmod_entities returned %d entit%s%s (request=%s).", #snapshot.entities, #snapshot.entities == 1 and "y" or "ies", snapshot.truncated and ", truncated" or "", request_id or "-" )
            return
        end

        if tool ~= "exec_lua_code" then
            error( "unknown MCP tool " .. tostring( tool ), 2 )
        end

        local code = command.code

        if not isString( command.state ) or not isString( code ) then
            error( "invalid exec_lua_code command", 2 )
        end

        local code_length = #code

        if command.state == "server" then
            set_active_exec( request_id )

            local executed, execute_error = compile_and_run( code, "dreamwork.mcp:server", request_id )
            if not executed then
                report_error( "server Lua execution failed (tool=%s, request=%s, %d bytes): %s", tool, request_id or "-", code_length, execute_error, {
                    tool = tool,
                    request_id = request_id
                } )
            else
                dreamwork_Logger:debug( "MCP: ran server Lua (tool=%s, request=%s, %d bytes).", tool, request_id or "-", code_length )
            end

            return
        end

        if command.state ~= "client" or not isString( command.target ) or string_trimSpaces( command.target ) == "" then
            error( "client exec_lua_code requires a target", 2 )
        end

        local sent, send_error = send_exec_to_client( code, command.target, request_id )
        if not sent then
            if isString( request_id ) and request_id ~= "" then
                respond_lua_raw( request_id, false, tostring( send_error ) )
            end

            report_error( "client Lua execution skipped (tool=%s, target=%s, request=%s, %d bytes): %s", tool, command.target, request_id or "-", code_length, send_error, {
                tool = tool,
                target = command.target,
                request_id = request_id
            } )
        else
            dreamwork_Logger:debug( "MCP: queued client Lua (tool=%s, target=%s, request=%s, %d bytes).", tool, command.target, request_id or "-", code_length )
        end
    end

    ---@param reader dreamwork.std.BinaryReader
    ---@param sender garrysmod.Player | nil
    local function on_network_receive( _, reader, sender )
        if sender == nil or not sender:IsValid() then
            return
        end

        local ok, err = pcall( function()
            local opcode = read_opcode( reader )

            if opcode == MSG_EXEC_RESULT then
                local request_id = read_request_id( reader )
                local success = reader:readBoolean()
                local payload = read_payload( reader )

                if pending_exec[ request_id ] ~= sender then
                    return nil
                end

                clear_pending_exec( request_id )
                respond_lua_raw( request_id, success, payload )
                return nil
            end

            if opcode == MSG_SCREENSHOT_RESULT then
                local request_id = read_request_id( reader )
                local success = reader:readBoolean()
                local payload = read_payload( reader )

                if pending_screenshots[ request_id ] ~= sender then
                    return nil
                end

                clear_pending_screenshot( request_id )

                if success then
                    local payload_size = #payload
                    if payload_size == 0 then
                        respond_screenshot( request_id, false, "Screenshot is empty." )
                    elseif payload_size > MAX_SCREENSHOT_BYTES then
                        respond_screenshot( request_id, false, format_error(
                            "Screenshot exceeds the %d byte limit.",
                            MAX_SCREENSHOT_BYTES
                        ) )
                    else
                        respond_screenshot( request_id, true, payload )
                    end
                else
                    respond_screenshot( request_id, false, payload )
                end
            end

            return nil
        end )

        if not ok then
            report_error( "failed to handle client message from %s [%s]: %s", sender:Nick(), sender:SteamID64(), err, {
                sender = sender:SteamID64()
            } )
        end
    end

    do
        local channel = get_network()
        if channel ~= nil then
            -- networks are shared by name, drop the receivers of previous module loads
            channel:clear()
            channel:attach( on_network_receive )
        end
    end

    local function poll_commands()
        if not bridge_running then
            return
        end

        local poll_ok, command = pcall( bridge.pollCommand )
        if not poll_ok then
            report_error( "failed to poll bridge command queue: %s", command )
            return
        end

        if command == nil then
            return
        end

        local execute_ok, execute_error = pcall( mcp.execute_command, command )
        if not execute_ok then
            local request_id = isTable( command ) and command.requestId or nil
            local tool_name = isTable( command ) and command.tool or "unknown"

            report_error( "bridge command failed (tool=%s, request=%s, state=%s, target=%s): %s", tool_name, request_id or "-", isTable( command ) and tostring( command.state ) or "-", isTable( command ) and tostring( command.target or "-" ) or "-", execute_error, {
                tool = isTable( command ) and command.tool or nil,
                request_id = request_id
            } )

            if isString( request_id ) and request_id ~= "" then
                local tool = command.tool or "exec_lua_code"
                if tool == "screenshot" then
                    respond_screenshot( request_id, false, tostring( execute_error ) )
                else
                    respond_lua_raw( request_id, false, tostring( execute_error ) )
                end
            end
        end
    end

    engine_timer_create( POLL_TIMER_NAME, POLL_INTERVAL, 0, poll_commands )

    ---@param active boolean
    ---@return boolean success
    local function set_bridge_active( active )
        if active then
            if not bridge_running then
                local status_ok, status_error = pcall( bridge.setStatus, true, "Garry's Mod is connected." )
                if not status_ok then
                    report_error( "failed to publish bridge status 'connected': %s", status_error )
                    return false
                end

                bridge_running = true

                engine_timer_start( POLL_TIMER_NAME )
                dreamwork_Logger:info( "MCP: bridge enabled (polling every %.2fs).", POLL_INTERVAL )
            else
                pcall( bridge.setStatus, true, "Garry's Mod is connected." )
                dreamwork_Logger:info( "MCP: bridge already running, status set to connected." )
            end

            return true
        end

        if bridge_running then
            pcall( bridge.setStatus, false, "MCP is disabled." )
        end

        dreamwork_Logger:info( "MCP: bridge disabled (commands will be rejected until re-enabled)." )
        return true
    end

    --- [SERVER]
    ---
    --- Applies the effective enabled state without writing `config.enabled`.
    --- Follows the override when set, otherwise `std.DEVELOPER`.
    ---
    ---@return boolean success
    function mcp.sync()
        local want = mcp.isEnabled()
        local ok = set_bridge_active( want )

        if want and ok then
            events:emit( mcp, "enable" )
        elseif not want then
            events:emit( mcp, "disable" )
        end

        return ok
    end

    --- [SERVER]
    ---
    --- Starts bridge polling and advertises the connected status.
    --- Forces `config.enabled = true` (overrides developer auto mode).
    ---
    ---@return boolean success
    function mcp.enable()
        config.enabled = true

        if not set_bridge_active( true ) then
            config.enabled = false
            return false
        end

        events:emit( mcp, "enable" )
        return true
    end

    --- [SERVER]
    ---
    --- Stops accepting commands and advertises the disabled status.
    --- Forces `config.enabled = false` (overrides developer auto mode).
    ---
    function mcp.disable()
        config.enabled = false
        set_bridge_active( false )
        events:emit( mcp, "disable" )
    end

    --- [SERVER]
    ---
    --- Tears down the bridge and timers.
    ---
    function mcp.shutdown()
        set_bridge_active( false )
        bridge_running = false
        clear_active_exec( nil )

        engine_timer_stop( POLL_TIMER_NAME )

        for request_id in raw_pairs( pending_exec ) do
            clear_pending_exec( request_id )
        end

        for request_id in raw_pairs( pending_screenshots ) do
            clear_pending_screenshot( request_id )
        end

        local shutdown_ok, shutdown_error = pcall( bridge.shutdown )
        if not shutdown_ok then
            report_error( "failed to shut down native bridge: %s", shutdown_error )
        else
            dreamwork_Logger:info( "MCP: native bridge shut down." )
        end
    end

    engine_hook.catch( "ShutDown", "modules.mcp.shutdown", function()
        mcp.shutdown()
    end )

    -- Fail the active waiting exec with the original error, before it is replaced by the sentinel.
    engine_hook.catch( "dreamwork.error.report", "modules.mcp.error", function( error_value )
        if active_exec_request_id ~= nil then
            mcp.respond_error( format_reported_error( error_value, "server" ) )
        end
    end, 2000 )

    -- Fail waiting execs on Lua errors that did not go through dreamwork (those are sentinels here).
    engine_hook.catch( "dreamwork.error.occurred", "modules.mcp.error", function( err, realm, stack, source, client )
        if err == exceptions_Sentinel then
            return
        end

        if client == nil then
            if active_exec_request_id ~= nil then
                mcp.respond_error( format_lua_error( err, realm, stack, source ) )
            end

            return
        end

        if not client:IsValid() then
            return
        end

        ---@type string[]
        local matched = {}
        local matched_count = 0

        for request_id, pending_ply in raw_pairs( pending_exec ) do
            if pending_ply == client then
                matched_count = matched_count + 1
                matched[ matched_count ] = request_id
            end
        end

        if matched_count == 0 then
            return
        end

        local message = format_lua_error( err, realm, stack, source )

        for index = 1, matched_count, 1 do
            mcp.respond_error( matched[ index ], message )
        end
    end )

    engine_hook.catch( "dreamwork.entity.destroy", "modules.mcp.entities", function( entity, is_player )
        if not is_player then
            return
        end

        ---@cast entity garrysmod.Player

        for request_id, ply in raw_pairs( pending_exec ) do
            if ply == entity then
                clear_pending_exec( request_id )
                respond_lua_raw( request_id, false, "Client disconnected." )
                dreamwork_Logger:debug( "MCP: cancelled pending Lua result (request=%s) after %s [%s] disconnected.", request_id, ply:Nick(), ply:SteamID64() )
            end
        end

        for request_id, ply in raw_pairs( pending_screenshots ) do
            if ply == entity then
                clear_pending_screenshot( request_id )
                respond_screenshot( request_id, false, "Client disconnected." )
                dreamwork_Logger:debug( "MCP: cancelled pending screenshot (request=%s) after %s [%s] disconnected.", request_id, ply:Nick(), ply:SteamID64() )
            end
        end
    end )

    -- Follow developer when `config.enabled` is unset.
    do
        local developer = std.console.Variable.get( "developer", "integer" )
        if developer ~= nil then
            developer:attach( function()
                if config.enabled == nil then
                    mcp.sync()
                end
            end )
        end
    end

    if is_reload then
        mcp.sync()
    else
        -- Initial enable/disable is applied from CLI settings (storage) right after this module loads.
        pcall( bridge.setStatus, false, "MCP is starting." )
    end

    local running = false
    local status_ok, status = pcall( bridge.getStatus )
    if status_ok and isTable( status ) then
        running = bridge.isRunning() == true
        dreamwork_Logger:info( "MCP: bridge module ready (listener %s, status='%s').", running and "running" or "stopped", tostring( status.message or "" ) )
    else
        dreamwork_Logger:info( "MCP: bridge module ready (unknown-gd/gm_mcp)." )
    end

end

if LUA_CLIENT then

    local gui_IsGameUIVisible = dreamwork_engine.requireLibrary( "gui" ).IsGameUIVisible or function() return false end
    local render_Capture = dreamwork_engine.requireLibrary( "render" ).Capture or std.debug.fempty

    local window = std.window

    ---@type string[]
    local pending_captures = {}

    --- Request id of the client Lua exec awaiting `mcp.return_result` / a result payload.
    ---@type string | nil
    local active_client_request_id

    ---@param request_id string
    ---@param ok boolean
    ---@param payload string
    local function send_result( request_id, ok, payload )
        if request_id == nil or request_id == "" then
            return
        end

        if active_client_request_id == request_id then
            active_client_request_id = nil
        end

        local channel = get_network()
        if channel == nil then
            return
        end

        channel:transmit( function( _, writer )
            write_opcode( writer, MSG_EXEC_RESULT )
            write_request_id( writer, request_id )
            writer:writeBoolean( ok )
            write_payload( writer, payload or "" )
        end )
    end

    --- [CLIENT]
    ---
    --- Fails a waiting MCP Lua exec over the network.
    ---
    --- - `mcp.respond_error( message )` — fail the active waiting exec (if any).
    --- - `mcp.respond_error( requestId, message )` — fail a specific waiting exec.
    ---
    ---@param request_id_or_message string
    ---@param message string | nil
    ---@return boolean delivered
    function mcp.respond_error( request_id_or_message, message )
        local request_id

        if message == nil then
            request_id, message = active_client_request_id, request_id_or_message
            if request_id == nil then
                return false
            end
        else
            request_id = request_id_or_message
            if request_id == "" then
                return false
            end
        end

        send_result( request_id, false, message )
        return true
    end

    ---@param request_id string
    ---@param ok boolean
    ---@param payload string
    local function send_screenshot_result( request_id, ok, payload )
        local channel = get_network()
        if channel == nil then
            return
        end

        channel:transmit( function( _, writer )
            write_opcode( writer, MSG_SCREENSHOT_RESULT )
            write_request_id( writer, request_id )
            writer:writeBoolean( ok )
            write_payload( writer, payload or "" )
        end )
    end

    ---@param code string
    ---@param request_id string
    local function execute_lua_code( code, request_id )
        if not config.allow_exec then
            send_result( request_id, false, "Client Lua execution is restricted." )
            return
        end

        local chunk, compile_error = compile_chunk( code, "dreamwork.mcp:client" )
        if chunk == nil then
            report_error( "client Lua compilation failed (request=%s, %d bytes): %s", request_id ~= "" and request_id or "-", #code, compile_error )
            send_result( request_id, false, tostring( compile_error ) )
            return
        end

        local previous_return = mcp.return_result
        local result_sent = false

        if request_id ~= "" then
            active_client_request_id = request_id

            ---@param value any
            function mcp.return_result( value )
                if result_sent then
                    return
                end

                result_sent = true

                local encoded, encode_error = encode_result( value )
                if encoded == nil then
                    ---@cast encode_error string
                    send_result( request_id, false, encode_error )
                    return
                end

                send_result( request_id, true, encoded )
            end
        end

        local run_ok, run_result = pcall( chunk )
        if not run_ok then
            report_error( "client Lua execution failed (request=%s, %d bytes): %s", request_id ~= "" and request_id or "-", #code, run_result )

            if request_id ~= "" and not result_sent then
                result_sent = true
                send_result( request_id, false, tostring( run_result ) )
            end

            if request_id ~= "" then
                mcp.return_result = previous_return
            end

            return
        end

        if request_id ~= "" and run_result ~= nil and not result_sent then
            result_sent = true

            local encoded, encode_error = encode_result( run_result )
            if encoded == nil then
                ---@cast encode_error string
                send_result( request_id, false, encode_error )
            else
                send_result( request_id, true, encoded )
            end
        end

        if request_id ~= "" then
            mcp.return_result = previous_return
        end
    end

    -- Fail the active waiting client exec with the original error, before it is replaced by the sentinel.
    engine_hook.catch( "dreamwork.error.report", "modules.mcp.error", function( error_value )
        if active_client_request_id ~= nil then
            mcp.respond_error( format_reported_error( error_value, "client" ) )
        end
    end, 2000 )

    -- Fail the active waiting client exec on Lua errors that did not go through dreamwork.
    engine_hook.catch( "dreamwork.error.occurred", "modules.mcp.error", function( err, realm, stack, source )
        if err ~= exceptions_Sentinel and active_client_request_id ~= nil then
            mcp.respond_error( format_lua_error( err, realm, stack, source ) )
        end
    end )

    ---@param request_id string
    local function capture_screenshot( request_id )
        if not config.allow_capture then
            send_screenshot_result( request_id, false, "Client screenshot capture is restricted." )
            return
        end

        if gui_IsGameUIVisible() then
            send_screenshot_result( request_id, false, "GMod cannot capture while the Escape menu is open." )
            return
        end

        pending_captures[ #pending_captures + 1 ] = request_id
    end

    engine_hook.catch( "PostRender", "modules.mcp.screenshot", function()
        local request_id = table_remove( pending_captures, 1 )
        if request_id == nil then
            return
        end

        if not config.allow_capture then
            send_screenshot_result( request_id, false, "Client screenshot capture is restricted." )
            return
        end

        local ok, data = pcall( render_Capture, {
            format = "jpeg",
            quality = SCREENSHOT_QUALITY,
            x = 0,
            y = 0,
            w = window.width,
            h = window.height
        } )

        if not ok then
            send_screenshot_result( request_id, false, "Screenshot capture failed: " .. tostring( data ) )
            return
        end

        if not isString( data ) or #data == 0 then
            send_screenshot_result( request_id, false, "GMod cannot capture while the Escape menu is open." )
            return
        end

        if #data > MAX_SCREENSHOT_BYTES then
            send_screenshot_result( request_id, false, format_error(
                "Screenshot exceeds the %d byte limit.",
                MAX_SCREENSHOT_BYTES
            ) )
            return
        end

        send_screenshot_result( request_id, true, data )
    end )

    ---@param channel dreamwork.std.Network
    local function attach_client_receiver( channel )
        -- networks are shared by name, drop the receivers of previous module loads
        channel:clear()

        channel:attach( function( _, reader )
            local ok, err = pcall( function()
                local opcode = read_opcode( reader )

                if opcode == MSG_EXEC then
                    local request_id = read_request_id( reader )
                    local code = read_payload( reader )
                    execute_lua_code( code, request_id )
                    return nil
                end

                if opcode == MSG_SCREENSHOT then
                    local request_id = read_request_id( reader )
                    if request_id == "" then
                        return nil
                    end

                    capture_screenshot( request_id )
                end

                return nil
            end )

            if not ok then
                report_error( "failed to handle server message (opcode read/exec): %s", err )
            end
        end )
    end

    local function try_bind_network( silent )
        network_unavailable = false
        local channel = get_network( silent )
        if channel == nil then
            return false
        end

        attach_client_receiver( channel )
        dreamwork_Logger:info( "MCP: client handlers ready (network='%s', allow_exec=%s, allow_capture=%s).", channel.name, tostring( config.allow_exec ), tostring( config.allow_capture ) )
        return true
    end

    if not try_bind_network( true ) then
        -- String table may not be ready yet, or the server has no MCP bridge.
        engine_hook.catch( "InitPostEntity", "modules.mcp.bind", function()
            if network ~= nil then
                return
            end

            if not try_bind_network( true ) then
                dreamwork_Logger:debug( "MCP: client handlers idle (server did not register network 'dreamwork.mcp')." )
            end
        end )
    end

end
