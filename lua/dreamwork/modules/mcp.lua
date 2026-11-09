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
local raw_tonumber = raw.tonumber

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
local json_deserialize = json.deserialize

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

--- Seconds errors are collected after the first one before a waiting exec fails with all of them.
local ERROR_WINDOW = 1

--- Max distinct errors kept per window, repeats of a kept error only bump its `count`.
local MAX_WINDOW_ERRORS = 32

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

---@class dreamwork.mcp
---@field bridge gm_mcp | nil The native bridge table, server-only when loaded.
---@field respondResult fun( request_id: string?, ok: boolean, value: any ) Completes a waiting Lua exec with a value or error.
---@field respondError fun( request_id_or_message: string, message: string? ): boolean Fails the active or a specific waiting Lua exec.
---@field returnResult fun( value: any ): boolean Completes the active waiting exec, also asynchronously; scripts call it as the global `mcp.returnResult`.
local mcp = dreamwork.mcp or {}
dreamwork.mcp = mcp

---@class dreamwork.mcp.ErrorEntry
---@field message string The error message.
---@field realm string | nil The realm the error happened in.
---@field stack table[] | nil `OnLuaError`-like frames, top frame first.
---@field name string | nil The addon or source name.
---@field count integer How many times the error happened within the window.

-- the settings of the MCP module, set by the `mcp config` console command (`dreamwork_sci` / `dreamwork_cci`)

--- Server: `"1"` / `"0"` force the bridge on / off, `""` follows `developer` (`std.DEVELOPER ~= 0`).
---@type string
local enabled = ""

--- Server only.
---@type dreamwork.std.console.Variable<string>
local enabled_variable

--- Client: allow remote Lua execution from the MCP bridge.
local allow_exec = true

--- Client: allow remote screenshot capture from the MCP bridge.
local allow_capture = true

do

    local console_Variable = std.console.Variable

    if LUA_SERVER then
        enabled_variable = console_Variable( {
            name = "dreamwork_mcp_enabled",
            description = "When unset (reset), follows the developer convar; 1/0 (true/false) overrides. When 0, tool calls are rejected.",
            type = "string",
            default = "",
            archive = true,
            hidden = true
        } )

        enabled = enabled_variable.value
    end

    if LUA_CLIENT then
        ---@type dreamwork.std.console.Variable<boolean>
        local variable = console_Variable( {
            name = "dreamwork_mcp_allow_exec",
            description = "When false, this client refuses remote MCP Lua execution.",
            type = "boolean",
            default = true,
            archive = true,
            hidden = true
        } )

        allow_exec = variable.value

        variable:attach( function( _, value )
            allow_exec = value
        end )

        ---@type dreamwork.std.console.Variable<boolean>
        variable = console_Variable( {
            name = "dreamwork_mcp_allow_capture",
            description = "When false, this client refuses remote MCP screenshot capture.",
            type = "boolean",
            default = true,
            archive = true,
            hidden = true
        } )

        allow_capture = variable.value

        variable:attach( function( _, value )
            allow_capture = value
        end )
    end

end

--- [SERVER]
---
--- Resolves whether the bridge should accept commands.
--- Uses the `mcp_enabled` override when set; otherwise follows `std.DEVELOPER ~= 0`.
---
---@return boolean
function mcp.isEnabled()
    if enabled == "1" then
        return true
    elseif enabled == "0" then
        return false
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
---@return dreamwork.mcp.ErrorEntry
local function lua_error_entry( message, realm, stack, name )
    return {
        message = tostring( message ),
        realm = realm,
        stack = stack,
        name = name,
        count = 1
    }
end

--- Converts a dreamwork error into an `OnLuaError`-like error entry, top frame first.
---
---@param error_value dreamwork.std.Error | any
---@param realm string
---@return dreamwork.mcp.ErrorEntry
local function reported_error_entry( error_value, realm )
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

    return lua_error_entry( exceptions_tostring( error_value ), realm, stack, nil )
end

--- Errors collected per waiting request, in arrival order.
---@type table<string, dreamwork.mcp.ErrorEntry[]>
local error_windows = {}

--- `realm \0 message` -> entry, used to fold repeated errors into one entry.
---@type table<string, table<string, dreamwork.mcp.ErrorEntry>>
local error_lookups = {}

--- Distinct errors dropped after `MAX_WINDOW_ERRORS`.
---@type table<string, integer>
local error_dropped = {}

--- Realm-specific delivery of a finished window, set below.
---@type fun( request_id: string, payload: string )
local deliver_errors

--- Closes the error window of the request and encodes its errors.
---
---@param request_id string
---@return string | nil payload `{ "errors": [ ... ], "dropped": n? }`, `nil` if no window is open.
local function take_errors( request_id )
    local entries = error_windows[ request_id ]
    if entries == nil then
        return nil
    end

    local dropped = error_dropped[ request_id ]

    error_windows[ request_id ] = nil
    error_lookups[ request_id ] = nil
    error_dropped[ request_id ] = nil

    engine_timer_remove( "dreamwork.mcp.errors." .. request_id )

    local ok, payload = pcall( json_serialize, {
        errors = entries,
        dropped = dropped ~= 0 and dropped or nil
    } )

    if ok and isString( payload ) then
        return payload
    end

    -- stack frames are not serializable, keep the messages
    for index = 1, #entries, 1 do
        entries[ index ].stack = nil
    end

    return json_serialize( {
        errors = entries,
        dropped = dropped ~= 0 and dropped or nil
    } )
end

---@param request_id string
local function flush_errors( request_id )
    local payload = take_errors( request_id )
    if payload ~= nil then
        deliver_errors( request_id, payload )
    end
end

--- Adds an error to the window of the request, opening it (and its flush timer) on the first error.
---
--- Repeats of a kept error are folded into it; `merge` takes the larger count instead of adding,
--- for batches that may repeat errors this window already saw through another path.
---
---@param request_id string
---@param entry dreamwork.mcp.ErrorEntry
---@param merge boolean?
local function collect_error( request_id, entry, merge )
    local entries = error_windows[ request_id ]
    if entries == nil then
        entries = {}
        error_windows[ request_id ] = entries
        error_lookups[ request_id ] = {}
        error_dropped[ request_id ] = 0

        engine_timer_create( "dreamwork.mcp.errors." .. request_id, ERROR_WINDOW, 1, function()
            flush_errors( request_id )
        end, true )
    end

    local key = tostring( entry.realm ) .. "\0" .. entry.message
    local lookup = error_lookups[ request_id ]

    local existing = lookup[ key ]
    if existing ~= nil then
        if merge then
            existing.count = math_max( existing.count, entry.count )
        else
            existing.count = existing.count + entry.count
        end

        return
    end

    local size = #entries
    if size >= MAX_WINDOW_ERRORS then
        error_dropped[ request_id ] = error_dropped[ request_id ] + 1
        return
    end

    entries[ size + 1 ] = entry
    lookup[ key ] = entry
end

--- Adds a failure payload to the window of the request; `{ errors = [...] }` batches from a client window are merged.
---
---@param request_id string
---@param payload string
---@param realm string
local function collect_payload( request_id, payload, realm )
    if string_find( payload, "\"errors\":", 1, true ) ~= nil then
        local ok, batch = pcall( json_deserialize, payload )
        if ok and isTable( batch ) and isTable( batch.errors ) then
            local entries = batch.errors
            for index = 1, #entries, 1 do
                local value = entries[ index ]
                if isTable( value ) then
                    local entry = lua_error_entry( value.message, value.realm or realm, value.stack, value.name )
                    entry.count = math_max( 1, math_floor( raw_tonumber( value.count ) or 1 ) )
                    collect_error( request_id, entry, true )
                end
            end

            return
        end
    end

    collect_error( request_id, lua_error_entry( payload, realm, nil, nil ) )
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

    --- Request id of the Lua exec currently awaited by the native bridge (`mcp.returnResult`).
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
    ---@param realm string? The realm a failure came from, defaults to `"server"`.
    local function respond_lua_raw( request_id, ok, payload, realm )
        if request_id == nil or request_id == "" then
            return
        end

        -- an open error window owns the response: failures join it, results are dropped
        if error_windows[ request_id ] ~= nil then
            if not ok then
                collect_payload( request_id, payload, realm or "server" )
            end

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
    function mcp.respondResult( request_id, ok, value )
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

    ---@param request_id string
    ---@param payload string
    function deliver_errors( request_id, payload )
        clear_pending_exec( request_id )
        clear_active_exec( request_id )

        local reported, respond_err = pcall( bridge.respondError, request_id, payload )
        if not reported then
            report_error( "failed to report Lua errors to bridge (request=%s): %s", request_id, respond_err, {
                request_id = request_id
            } )
        end
    end

    --- [SERVER]
    ---
    --- Fails a waiting MCP Lua exec. Prefer this from console/error hooks over
    --- `respondResult( id, false, ... )` / `respondLua( id, false, ... )`.
    ---
    --- - `mcp.respondError( message )` — fail the active waiting server exec (if any).
    --- - `mcp.respondError( requestId, message )` — fail a specific waiting exec.
    ---
    --- The first error opens a `ERROR_WINDOW` second window; every error of the request in it
    --- is sent together as `{ "errors": [ ... ] }` when the window closes.
    ---
    --- Returns `true` if the error was queued for a request.
    ---
    ---@param request_id_or_message string
    ---@param message string | nil
    ---@return boolean queued
    function mcp.respondError( request_id_or_message, message )
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

        collect_payload( request_id, message, pending_exec[ request_id ] == nil and "server" or "client" )
        return true
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
    function mcp.getPlayers()
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
    function mcp.getEntities( class_filter, custom_check, limit )
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
    function mcp.resolvePlayer( target )
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
            mcp.respondResult( request_id, false, compile_error )
            return false, compile_error
        end

        local run_ok, run_result = pcall( chunk )
        if not run_ok then
            if request_id ~= nil and request_id ~= "" and active_exec_request_id == request_id then
                -- keep the window open for errors of timers / hooks the chunk already created
                collect_error( request_id, reported_error_entry( run_result, "server" ) )
            end

            return false, run_result
        end

        -- still active = neither `mcp.returnResult` nor an error answered it yet
        if run_result ~= nil and request_id ~= nil and request_id ~= "" and active_exec_request_id == request_id and error_windows[ request_id ] == nil then
            mcp.respondResult( request_id, true, run_result )
        end

        return true, nil
    end

    --- [SERVER]
    ---
    --- Completes the active waiting server exec with a value, also from timers / hooks after the chunk returned.
    ---
    --- Exposed to MCP scripts as the global `mcp.returnResult` (the native bridge table).
    ---
    ---@param value any
    ---@return boolean answered `false` if no exec is waiting.
    function mcp.returnResult( value )
        local request_id = active_exec_request_id
        if request_id == nil then
            return false
        end

        mcp.respondResult( request_id, true, value )
        return true
    end

    bridge.returnResult = mcp.returnResult

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

        local ply, resolve_error = mcp.resolvePlayer( target )
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

        local ply, resolve_error = mcp.resolvePlayer( command.target )
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
    function mcp.executeCommand( command )
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
            local players = mcp.getPlayers()
            mcp.respondResult( request_id, true, players )
            dreamwork_Logger:debug( "MCP: gmod_players returned %d player(s) (request=%s).", #players, request_id or "-" )
            return
        end

        if tool == "gmod_entities" then
            local snapshot = mcp.getEntities(
                command.classFilter or command.class_filter,
                command.customCheck or command.custom_check,
                command.limit
            )
            mcp.respondResult( request_id, true, snapshot )
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
        if sender == nil or not sender:IsValid() then return end

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
                respond_lua_raw( request_id, success, payload, "client" )
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

        local execute_ok, execute_error = pcall( mcp.executeCommand, command )
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
    --- Applies the effective enabled state without writing the `mcp_enabled` override.
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
    --- Sets the `mcp_enabled` override to `"1"` (overrides developer auto mode).
    ---
    ---@return boolean success
    function mcp.enable()
        -- set before the variable, so its change handler doesn't sync a second time
        enabled = "1"
        enabled_variable.value = "1"

        if not set_bridge_active( true ) then
            return false
        end

        events:emit( mcp, "enable" )
        return true
    end

    --- [SERVER]
    ---
    --- Stops accepting commands and advertises the disabled status.
    --- Sets the `mcp_enabled` override to `"0"` (overrides developer auto mode).
    ---
    function mcp.disable()
        enabled = "0"
        enabled_variable.value = "0"
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

        for request_id in raw_pairs( error_windows ) do
            flush_errors( request_id )
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
            collect_error( active_exec_request_id, reported_error_entry( error_value, "server" ) )
        end
    end, 2000 )

    -- Fail waiting execs on Lua errors that did not go through dreamwork (those are sentinels here).
    engine_hook.catch( "dreamwork.error.occurred", "modules.mcp.error", function( err, realm, stack, source, client )
        if err == exceptions_Sentinel then return end

        if client == nil then
            if active_exec_request_id ~= nil then
                collect_error( active_exec_request_id, lua_error_entry( err, realm, stack, source ) )
            end

            return
        end

        if not client:IsValid() then return end

        for request_id, pending_ply in raw_pairs( pending_exec ) do
            if pending_ply == client then
                collect_error( request_id, lua_error_entry( err, realm, stack, source ) )
            end
        end
    end )

    engine_hook.catch( "dreamwork.entity.destroy", "modules.mcp.entities", function( entity, is_player )
        if not is_player then return end

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

    -- Follow developer when the `mcp_enabled` override is unset.
    do
        local developer = std.console.Variable.get( "developer", "integer" )
        if developer ~= nil then
            developer:attach( function()
                if enabled == "" then
                    mcp.sync()
                end
            end )
        end
    end

    -- console, `server.cfg` and `mcp config enabled` changes
    enabled_variable:attach( function( _, value )
        if value ~= enabled then
            enabled = value
            mcp.sync()
        end
    end )

    mcp.sync()

    local status_ok, status = pcall( bridge.getStatus )
    local running = false

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

    --- Request id of the client Lua exec awaiting `mcp.returnResult` / a result payload.
    ---@type string | nil
    local active_client_request_id

    ---@param request_id string
    ---@param ok boolean
    ---@param payload string
    local function send_result( request_id, ok, payload )
        if request_id == nil or request_id == "" then return end

        -- an open error window owns the response: failures join it, results are dropped
        if error_windows[ request_id ] ~= nil then
            if not ok then
                collect_payload( request_id, payload, "client" )
            end

            return
        end

        if active_client_request_id == request_id then
            active_client_request_id = nil
        end

        local channel = get_network()
        if channel == nil then return end

        channel:transmit( function( _, writer )
            write_opcode( writer, MSG_EXEC_RESULT )
            write_request_id( writer, request_id )
            writer:writeBoolean( ok )
            write_payload( writer, payload or "" )
        end )
    end

    ---@param request_id string
    ---@param payload string
    function deliver_errors( request_id, payload )
        send_result( request_id, false, payload )
    end

    --- [CLIENT]
    ---
    --- Fails a waiting MCP Lua exec over the network.
    ---
    --- - `mcp.respondError( message )` — fail the active waiting exec (if any).
    --- - `mcp.respondError( requestId, message )` — fail a specific waiting exec.
    ---
    --- The first error opens a `ERROR_WINDOW` second window; every error of the request in it
    --- is sent together as `{ "errors": [ ... ] }` when the window closes.
    ---
    ---@param request_id_or_message string
    ---@param message string | nil
    ---@return boolean queued
    function mcp.respondError( request_id_or_message, message )
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

        collect_payload( request_id, message, "client" )
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
        if not allow_exec then
            send_result( request_id, false, "Client Lua execution is restricted." )
            return
        end

        local chunk, compile_error = compile_chunk( code, "dreamwork.mcp:client" )
        if chunk == nil then
            report_error( "client Lua compilation failed (request=%s, %d bytes): %s", request_id ~= "" and request_id or "-", #code, compile_error )
            send_result( request_id, false, tostring( compile_error ) )
            return
        end

        if request_id ~= "" then
            active_client_request_id = request_id
        end

        local run_ok, run_result = pcall( chunk )
        if not run_ok then
            report_error( "client Lua execution failed (request=%s, %d bytes): %s", request_id ~= "" and request_id or "-", #code, run_result )

            if request_id ~= "" and active_client_request_id == request_id then
                -- keep the window open for errors of timers / hooks the chunk already created
                collect_error( request_id, reported_error_entry( run_result, "client" ) )
            end

            return
        end

        -- still active = neither `mcp.returnResult` nor an error answered it yet
        if run_result ~= nil and request_id ~= "" and active_client_request_id == request_id and error_windows[ request_id ] == nil then
            mcp.returnResult( run_result )
        end
    end

    --- [CLIENT]
    ---
    --- Completes the active waiting client exec with a value, also from timers / hooks after the chunk returned.
    ---
    --- Exposed to MCP scripts as the global `mcp.returnResult`.
    ---
    ---@param value any
    ---@return boolean answered `false` if no exec is waiting.
    function mcp.returnResult( value )
        local request_id = active_client_request_id
        if request_id == nil then
            return false
        end

        local encoded, encode_error = encode_result( value )
        if encoded == nil then
            ---@cast encode_error string
            send_result( request_id, false, encode_error )
        else
            send_result( request_id, true, encoded )
        end

        return true
    end

    -- clients have no native bridge, scripts reach this module through the global name
    do
        local global_mcp = _G.mcp
        if global_mcp == nil then
            _G.mcp = mcp
        elseif global_mcp ~= mcp then
            global_mcp.returnResult = mcp.returnResult
        end
    end

    -- Fail the active waiting client exec with the original error, before it is replaced by the sentinel.
    engine_hook.catch( "dreamwork.error.report", "modules.mcp.error", function( error_value )
        if active_client_request_id ~= nil then
            collect_error( active_client_request_id, reported_error_entry( error_value, "client" ) )
        end
    end, 2000 )

    -- Fail the active waiting client exec on Lua errors that did not go through dreamwork.
    engine_hook.catch( "dreamwork.error.occurred", "modules.mcp.error", function( err, realm, stack, source )
        if err ~= exceptions_Sentinel and active_client_request_id ~= nil then
            collect_error( active_client_request_id, lua_error_entry( err, realm, stack, source ) )
        end
    end )

    ---@param request_id string
    local function capture_screenshot( request_id )
        if not allow_capture then
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

        if not allow_capture then
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
        dreamwork_Logger:info( "MCP: client handlers ready (network='%s', allow_exec=%s, allow_capture=%s).", channel.name, tostring( allow_exec ), tostring( allow_capture ) )
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
