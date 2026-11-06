local dreamwork_engine = dreamwork.engine
local dreamwork_Logger = dreamwork.Logger

local dreamwork_getUpTime = dreamwork.getUpTime
local exceptions_call = dreamwork.exceptions.call

local engine_hook = dreamwork_engine.hook

local engine_network = dreamwork_engine.network
local network_receive_id = engine_network.receive
local network_register = engine_network.register
local network_getID = engine_network.getID

---@class dreamwork.std
local std = dreamwork.std

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local raw = std.raw
local raw_pairs = raw.pairs
local raw_index = raw.index
local raw_tonumber = raw.tonumber

local math = std.math
local math_ceil = math.ceil
local math_floor = math.floor
local math_max = math.max
local math_min = math.min

local string = std.string
local string_len = string.len
local string_format = string.format
local string_sub = string.sub

local table = std.table
local table_concat = table.concat
local table_remove = table.remove

local console = std.console
local console_Variable = console.Variable

local class = std.class

local CRC32 = std.CRC32
local crc32_digest = CRC32.digest

local isTable = std.isTable

local Emitter = std.Emitter
local BinaryReader = std.BinaryReader
local BinaryWriter = std.BinaryWriter

local LUA_SERVER = std.LUA_SERVER


---@class garrysmod.net
local glua_net = dreamwork_engine.requireLibrary( "net" )

local net_Start = glua_net.Start
local net_WriteUInt = glua_net.WriteUInt
local net_WriteData = glua_net.WriteData
local net_ReadUInt = glua_net.ReadUInt
local net_ReadData = glua_net.ReadData


--[[

        Message Layout ( after the engine header )

        opcode ( 3 bit )
        |
        +-- SINGLE  ( reliable )    data
        +-- BEGIN   ( reliable )    transfer id ( 8 bit ), size ( 32 bit ), crc32 ( 32 bit ), segment size ( 16 bit )
        +-- SEGMENT ( unreliable )  transfer id ( 8 bit ), index ( 24 bit ), data
        +-- CANCEL  ( reliable )    transfer id ( 8 bit )
        +-- ACCEPT  ( reliable )    transfer id ( 8 bit )
        +-- ACK     ( unreliable )  transfer id ( 8 bit ), first missing index ( 24 bit ), word count ( 4 bit ), words ( 32 bit each )
        +-- FINISH  ( reliable )    transfer id ( 8 bit )
        +-- REJECT  ( reliable )    transfer id ( 8 bit )

        Transmission Loop

  Sender                    Receiver
    |                           |
    | - - - - BEGIN - - - - - > |   size + crc32 of the whole data
    | < - - - ACCEPT  - - - - - |   or REJECT if the receiver doesn't want it
    |                           |
    | - - - - SEGMENT - - - - > |   up to `window` segments in flight, paced over the rtt
    | - - - - SEGMENT - - - - > |
    | < - - - ACK - - - - - - - |   one per tick: everything before the first missing segment
    | - - - - SEGMENT - - - - > |   is received, plus a bitmap of the received segments after it,
    | < - - - ACK - - - - - - - |   so a lost ack is covered by the next one
    |           ...             |
    |                           |   segments that are not acknowledged in time are sent again,
    |                           |   holes behind newer acknowledged segments are sent again sooner
    |           ...             |
    | < - - - FINISH  - - - - - |   all segments received and crc32 matches
    |                           |

    Small data ( fits in one message ) is sent as a single reliable SINGLE message.

    Transfers to the same peer are queued, one runs at a time.

--]]

local OP_SINGLE = 0
local OP_BEGIN = 1
local OP_SEGMENT = 2
local OP_CANCEL = 3
local OP_ACCEPT = 4
local OP_ACK = 5
local OP_FINISH = 6
local OP_REJECT = 7

---
--- in bits
---
---@type integer
local opcode_size = 3

---
--- in bits
---
---@type integer
local transfer_id_size = 8

---
--- 24 bit with 1 kb segment ~= 16gb, but the size field limits it to 4gb anyway
---
--- in bits
---
---@type integer
local segment_index_size = 24

---
--- in bits
---
---@type integer
local ack_words_size = 4

---
--- 8 words, 256 segments after the first missing one
---
---@type integer
local max_ack_words = 8

---
--- unknown magical byte + engine header ( network id + unreliable ) + opcode
---
--- in bits
---
---@type integer
local message_header_size = 8 + engine_network.HeaderSize + opcode_size

---
--- in bytes
---
---@type integer
local single_capacity = math_floor( (((64 * 1024) - 1) * 8 - message_header_size) / 8 )

---
--- in bits
---
---@type integer
local segment_size_size = 16

---
--- the default segment size, fits into 1 kb message
---
--- in bytes
---
---@type integer
local default_segment_size = math_floor( (((1 * 1024) - 1) * 8 - message_header_size - transfer_id_size - segment_index_size) / 8 )

---
--- in bytes
---
---@type integer
local min_segment_size = 256

---
--- the segment message must fit into the message limit
---
--- in bytes
---
---@type integer
local max_segment_size = math_min( single_capacity - math_ceil( (transfer_id_size + segment_index_size) / 8 ), 0xFFFF )

---
--- the fallback data rate if the client has no `rate` info
---
--- in bytes per second
---
---@type integer
local default_rate = 30000

---
--- in seconds
---
---@type number
local ack_refresh_interval = 0.1

---
--- the reliable stream is slow ( ~77 kb/s measured over steam p2p, the segmented path did ~800 kb/s )
--- and blocks the control messages behind it, so only small data is sent as a single message
---
--- in bytes
---
---@type integer
local single_threshold = 8 * 1024

---
--- singles share the reliable channel buffer, a burst over it disconnects the peer
--- ( 8 x 60 kb in one tick were enough ), so singles are limited by a token bucket per peer,
--- data that doesn't fit is segmented and queued instead
---
--- in bytes
---
---@type integer
local single_burst = 64 * 1024

---
--- the part of the peer data rate that refills the single bucket
---
---@type number
local single_refill_share = 0.25

---
--- the refill is capped near the measured reliable stream speed
---
--- in bytes per second
---
---@type integer
local single_refill_limit = 48 * 1024

---
--- how much faster than `window / srtt` the segments are paced,
--- so the window can still grow
---
---@type number
local pacing_gain = 1.25

---
--- in bytes
---
---@type integer
local max_transfer_size = 0xFFFFFFFF

---
--- The prefix that makes network names unique enough.
---
--- NOTE: must not contain `\0`, the engine string table cuts names at it.
---
---@type string
local name_prefix = "\255\128\64"

---@class dreamwork.std.Network : dreamwork.std.Object
---@field __class dreamwork.std.NetworkClass
---@field id integer The engine ID of the network.
---@field name string The name of the network.
---@field receiver boolean `true` if the network accepts incoming messages.
---@field timeout number The number of seconds without any progress after which a transfer is aborted.
---@field window integer The maximum number of segments in flight.
---@field segment integer The size of outgoing segments in bytes.
---@field limit integer The maximum size of an incoming message in bytes.
local Network = class.base( "Network", true )

---@class dreamwork.std.NetworkClass : dreamwork.std.Network, dreamwork.std.Class
---@field __base dreamwork.std.Network
---@overload fun( name: string, can_receive: boolean? ): dreamwork.std.Network
local NetworkClass = class.create( Network )
std.Network = NetworkClass

---@alias dreamwork.std.Network.ReceiveFn fun( network: dreamwork.std.Network, reader: dreamwork.std.BinaryReader, sender: garrysmod.Player | nil )
---@alias dreamwork.std.Network.ProgressFn fun( network: dreamwork.std.Network, peer: garrysmod.Player | nil, is_outgoing: boolean, done_bytes: integer, total_bytes: integer )
---@alias dreamwork.std.Network.StreamFn fun( network: dreamwork.std.Network, sender: garrysmod.Player | nil, chunk: string | nil, offset: integer, total: integer, success: boolean | nil )
---@alias dreamwork.std.Network.FinishFn fun( network: dreamwork.std.Network, success: boolean, peer: garrysmod.Player | nil )

---@type table<dreamwork.std.Network, string>
local network_identifiers = {}

---@type table<dreamwork.std.Network, integer>
local network_ids = {}

---@type table<dreamwork.std.Network, string>
local network_names = {}

---@type table<dreamwork.std.Network, boolean>
local receive_allowed = {}

---@type table<dreamwork.std.Network, number>
local timeouts = {}

---@type table<dreamwork.std.Network, integer>
local windows = {}

---@type table<dreamwork.std.Network, integer>
local limits = {}

---@type table<dreamwork.std.Network, integer>
local segment_sizes = {}

--- Network `"receive"`, `"stream"` and `"progress"` handlers.
local events = Emitter( "Network" )

---@type table<string, dreamwork.std.Network>
local networks = {}

---@type fun( network: dreamwork.std.Network, remaining_bits: integer, sender: ( garrysmod.Player | nil ) )
local network_receive

--- [SHARED]
---
--- Attaches a handler that is called when a message is fully received.
---
--- If the handler is already attached, it will not be attached twice.
---
---@param handler dreamwork.std.Network.ReceiveFn | dreamwork.std.Hook | dreamwork.std.Event The callback or callable object.
function Network:attach( handler )
    events:attach( self, "receive", handler )
end

--- [SHARED]
---
--- Attaches a handler that automatically detaches
--- itself right before being invoked, so it only ever runs once.
---
---@param handler dreamwork.std.Network.ReceiveFn | dreamwork.std.Hook | dreamwork.std.Event The callback or callable object.
function Network:once( handler )
    events:once( self, "receive", handler )
end

--- [SHARED]
---
--- Detaches a previously attached receive handler.
---
---@param handler dreamwork.std.Network.ReceiveFn | dreamwork.std.Hook | dreamwork.std.Event The exact handler reference.
---@return boolean removed `true` if the handler was attached.
function Network:detach( handler )
    return events:detach( self, "receive", handler )
end

--- [SHARED]
---
--- Removes every receive handler.
---
function Network:clear()
    events:clear( self, "receive" )
end

--- [SHARED]
---
--- Waits for the next fully received message.
---
---@return dreamwork.std.Network network The network.
---@return dreamwork.std.BinaryReader reader The reader of the message.
---@return garrysmod.Player | nil sender The sender, `nil` on the client.
---@async
function Network:await()
    return events:await( self, "receive" )
end

--- [SHARED]
---
--- Attaches a handler that receives incoming data in order, chunk by chunk, while it arrives.
---
--- `chunk` is the data starting at the zero-based byte `offset`,
--- after the last chunk the handler is called once more with `chunk = nil` and `success`,
--- `success` is `false` if the transfer failed ( timed out, cancelled or checksum mismatch ),
--- the chunks received before it should be discarded then.
---
--- If a network has only stream handlers, the received data is not kept in memory.
---
---@param handler dreamwork.std.Network.StreamFn | dreamwork.std.Hook | dreamwork.std.Event The callback or callable object.
function Network:stream( handler )
    events:attach( self, "stream", handler )
end

--- [SHARED]
---
--- Detaches a previously attached stream handler.
---
---@param handler dreamwork.std.Network.StreamFn | dreamwork.std.Hook | dreamwork.std.Event The exact handler reference.
---@return boolean removed `true` if the handler was attached.
function Network:unstream( handler )
    return events:detach( self, "stream", handler )
end

--- [SHARED]
---
--- Attaches a handler that is called on every transfer progress, both incoming and outgoing.
---
---@param handler dreamwork.std.Network.ProgressFn | dreamwork.std.Hook | dreamwork.std.Event The callback or callable object.
function Network:watch( handler )
    events:attach( self, "progress", handler )
end

--- [SHARED]
---
--- Detaches a previously attached progress handler.
---
---@param handler dreamwork.std.Network.ProgressFn | dreamwork.std.Hook | dreamwork.std.Event The exact handler reference.
---@return boolean removed `true` if the handler was attached.
function Network:unwatch( handler )
    return events:detach( self, "progress", handler )
end

---@param network dreamwork.std.Network
---@param data string
---@param sender garrysmod.Player | nil
local function perform_callbacks( network, data, sender )
    if events:count( network, "receive" ) == 0 then
        if events:count( network, "stream" ) ~= 0 then return end

        dreamwork_Logger:warn( "Network '%s' received %d bytes, but has no handlers attached.", network_names[ network ], string_len( data ) )
        return
    end

    events:emit( network, "receive", network, BinaryReader( data ), sender )
end

---@param network dreamwork.std.Network
---@param peer garrysmod.Player | nil
---@param is_outgoing boolean
---@param done_bytes integer
---@param total_bytes integer
local function perform_progress( network, peer, is_outgoing, done_bytes, total_bytes )
    events:emit( network, "progress", network, peer, is_outgoing, done_bytes, total_bytes )
end

--- The key of the server in the per-peer tables on the client.
local server_key = "server"

---@param peer garrysmod.Player | nil
---@return string
local function peer_tostring( peer )
    if peer == nil then
        return "server"
    end

    return string_format( "%s [%s]", peer:Nick(), peer:SteamID() )
end

---@param peer garrysmod.Player | nil
---@return boolean
local function peer_valid( peer )
    return peer == nil or peer:IsValid()
end

---@type fun( peer: garrysmod.Player | nil )
local message_send

--- Returns the data rate of the channel to the peer.
---
---@type fun( peer: garrysmod.Player | nil ): integer
local peer_rate

--- Returns the round trip time the acks see ( the engine latency + one tick ), `nil` if unknown.
---
---@type fun( peer: garrysmod.Player | nil ): number | nil
local peer_latency

--- Returns the number of bytes written to the reliable stream of the peer in the current tick, `0` if unknown.
---
---@type fun( peer: garrysmod.Player | nil ): integer
local peer_reliable_written

--- Returns `true` if the channel to the peer is choking.
---
---@type fun( peer: garrysmod.Player | nil ): boolean
local peer_choked

if LUA_SERVER then

    ---@type dreamwork.std.console.Variable<integer>
    local sv_maxrate = console_Variable.get( "sv_maxrate", "integer" )

    ---@type dreamwork.std.console.Variable<integer>
    local sv_minrate = console_Variable.get( "sv_minrate", "integer" )

    -- HolyLib `gameserver` module, gives access to the net channels of the clients
    ---@diagnostic disable-next-line: undefined-global
    local glua_gameserver = gameserver

    if glua_gameserver == nil or glua_gameserver.GetClient == nil then

        ---@param peer garrysmod.Player
        ---@return integer
        function peer_rate( peer )
            local rate = peer:GetInfoNum( "rate", default_rate )

            local max_rate = sv_maxrate.value
            if max_rate > 0 and rate > max_rate then
                rate = max_rate
            end

            local min_rate = sv_minrate.value
            if rate < min_rate then
                rate = min_rate
            end

            return rate
        end

        function peer_latency()
            return nil
        end

        function peer_reliable_written()
            return 0
        end

        function peer_choked()
            return false
        end

    else

        local gameserver_GetTickInterval = glua_gameserver.GetTickInterval
        local gameserver_GetClient = glua_gameserver.GetClient

        local FLOW_OUTGOING = glua_gameserver.FLOW_OUTGOING

        ---@class dreamwork.std.Network.GameClient
        ---@field client holylib.CGameClient The HolyLib `GameClient`.
        ---@field reliable holylib.bf_write The reliable stream ( `bf_write` ) of the client.

        ---@type table<garrysmod.Player, dreamwork.std.Network.GameClient>
        local game_clients = {}
        gc_setTableRules( game_clients, true, false )

        ---@param peer garrysmod.Player
        ---@return dreamwork.std.Network.GameClient | nil
        local function game_client( peer )
            local entry = game_clients[ peer ]
            if entry ~= nil and entry.client:IsValid() then
                return entry
            end

            local client = gameserver_GetClient( peer:EntIndex() - 1 )
            if client == nil or not client:IsValid() then
                return nil
            end

            entry = {
                client = client,
                reliable = client:GetStreamReliable()
            }

            game_clients[ peer ] = entry
            return entry
        end

        ---@param peer garrysmod.Player
        ---@return integer
        function peer_rate( peer )
            local entry = game_client( peer )
            if entry == nil then
                return default_rate
            end

            -- already limited by `sv_maxrate` and `sv_minrate`
            return entry.client:GetRate()
        end

        ---@param peer garrysmod.Player
        ---@return number | nil
        function peer_latency( peer )
            local entry = game_client( peer )
            if entry == nil then
                return nil
            end

            local latency = entry.client:GetAvgLatency( FLOW_OUTGOING )
            if latency == nil or latency <= 0 then
                return nil
            end

            return latency + gameserver_GetTickInterval()
        end

        ---@param peer garrysmod.Player
        ---@return integer
        function peer_reliable_written( peer )
            local entry = game_client( peer )
            if entry == nil then
                return 0
            end

            return entry.reliable:GetNumBytesWritten()
        end

        ---@param peer garrysmod.Player
        ---@return boolean
        function peer_choked( peer )
            local entry = game_client( peer )
            return entry ~= nil and entry.client:GetChokedPackets() ~= 0
        end

    end

else

    ---@type dreamwork.std.console.Variable<integer>
    local rate_variable = console_Variable.get( "rate", "integer" )

    ---@return integer
    function peer_rate()
        return rate_variable.value
    end

    function peer_latency()
        return nil
    end

    function peer_reliable_written()
        return 0
    end

    function peer_choked()
        return false
    end

end

if LUA_SERVER then

    local net_Send = glua_net.Send

    ---@param peer garrysmod.Player
    function message_send( peer )
        net_Send( peer )
    end

else

    local net_SendToServer = glua_net.SendToServer

    function message_send()
        net_SendToServer()
    end

end

---@class dreamwork.std.Network.Bucket
---@field tokens number
---@field time number

---@type table<garrysmod.Player | string, dreamwork.std.Network.Bucket>
local single_buckets = {}
gc_setTableRules( single_buckets, true, false )

---@param peer garrysmod.Player | nil
---@param key garrysmod.Player | string
---@param size integer
---@return boolean allowed `true` if the data can be sent as a single message right now.
local function single_allowed( peer, key, size )
    local now = dreamwork_getUpTime()

    local bucket = single_buckets[ key ]
    if bucket == nil then
        bucket = { tokens = single_burst, time = now }
        single_buckets[ key ] = bucket
    else
        bucket.tokens = math_min( bucket.tokens + (now - bucket.time) * math_min( peer_rate( peer ) * single_refill_share, single_refill_limit ), single_burst )
        bucket.time = now
    end

    if bucket.tokens < size then
        return false
    end

    bucket.tokens = bucket.tokens - size
    return true
end

---@type fun( network: dreamwork.std.Network, peer: garrysmod.Player | nil, weight: integer, reason: string, ...: any )
local violation

---@type fun( peer: garrysmod.Player | nil, size: integer ): string | nil
local client_admit

---@type fun( peer: garrysmod.Player | nil, size: integer )
local client_release

if LUA_SERVER then

    ---
    --- strikes over it kick the client
    ---
    ---@type integer
    local max_strikes = 32

    ---
    --- strikes forgiven per second
    ---
    ---@type number
    local strike_decay = 2

    ---
    --- incoming transfers from one client over all networks
    ---
    ---@type integer
    local max_client_transfers = 16

    ---
    --- incoming bytes from one client over all networks
    ---
    ---@type integer
    local max_client_bytes = 256 * 1024 * 1024

    ---
    --- new transfers per second from one client
    ---
    ---@type number
    local begin_rate = 32

    ---@type integer
    local begin_burst = 64

    ---@class dreamwork.std.Network.Client
    ---@field strikes number
    ---@field strike_time number
    ---@field transfers integer
    ---@field bytes integer
    ---@field begins number
    ---@field begin_time number

    ---@type table<garrysmod.Player, dreamwork.std.Network.Client>
    local clients = {}
    gc_setTableRules( clients, true, false )

    ---@param peer garrysmod.Player
    ---@return dreamwork.std.Network.Client
    local function client_get( peer )
        local client = clients[ peer ]
        if client == nil then
            local now = dreamwork_getUpTime()

            client = {
                strikes = 0,
                strike_time = now,
                transfers = 0,
                bytes = 0,
                begins = begin_burst,
                begin_time = now
            }

            clients[ peer ] = client
        end

        return client
    end

    function violation( network, peer, weight, reason, ... )
        if peer == nil then return end

        local client = client_get( peer )
        local now = dreamwork_getUpTime()

        local strikes = math_max( client.strikes - (now - client.strike_time) * strike_decay, 0 ) + weight
        client.strikes = strikes
        client.strike_time = now

        local message = string_format( reason, ... )
        dreamwork_Logger:warn( "%s violated the protocol of network '%s': %s [%.0f/%d strikes]", peer_tostring( peer ), network_names[ network ], message, strikes, max_strikes )

        if strikes > max_strikes and peer:IsValid() then
            clients[ peer ] = nil
            peer:Kick( string_format( "Network protocol violation: %s", message ) )
        end
    end

    function client_admit( peer, size )
        ---@cast peer garrysmod.Player
        local client = client_get( peer )
        local now = dreamwork_getUpTime()

        local begins = math_min( client.begins + (now - client.begin_time) * begin_rate, begin_burst )
        client.begin_time = now

        if begins < 1 then
            client.begins = begins
            return "too many new transfers"
        end

        client.begins = begins - 1

        if client.transfers >= max_client_transfers then
            return string_format( "too many transfers at once, the limit is %d", max_client_transfers )
        end

        if client.bytes + size > max_client_bytes then
            return string_format( "too many bytes at once, the limit is %d bytes", max_client_bytes )
        end

        client.transfers = client.transfers + 1
        client.bytes = client.bytes + size
        return nil
    end

    function client_release( peer, size )
        local client = clients[ peer ]
        if client == nil then return end

        client.transfers = math_max( client.transfers - 1, 0 )
        client.bytes = math_max( client.bytes - size, 0 )
    end

else

    function violation( network, _, _, reason, ... )
        dreamwork_Logger:warn( "The server violated the protocol of network '%s': %s", network_names[ network ], string_format( reason, ... ) )
    end

    function client_admit()
        return nil
    end

    function client_release()
    end

end

---@param network dreamwork.std.Network
---@param opcode integer
---@param unreliable boolean
local function message_start( network, opcode, unreliable )
    net_Start( network_identifiers[ network ], unreliable )
    net_WriteUInt( opcode, opcode_size )
end

--- Writes 32-bit unsigned integers in two halves, `WriteUInt` casts through a signed integer on some builds.
---
---@param value integer
local function write_uint32( value )
    net_WriteUInt( math_floor( value / 0x10000 ), 16 )
    net_WriteUInt( value % 0x10000, 16 )
end

---@return integer
local function read_uint32()
    return net_ReadUInt( 16 ) * 0x10000 + net_ReadUInt( 16 )
end

---@param network dreamwork.std.Network
---@param opcode integer
---@param transfer_id integer
---@param peer garrysmod.Player | nil
local function send_control( network, opcode, transfer_id, peer )
    message_start( network, opcode, false )
    net_WriteUInt( transfer_id, transfer_id_size )
    message_send( peer )
end

---@class dreamwork.std.Network.Outgoing
---@field network dreamwork.std.Network
---@field peer garrysmod.Player | nil
---@field key garrysmod.Player | string
---@field id integer
---@field data string
---@field size integer
---@field segment_size integer
---@field count integer
---@field acked boolean[]
---@field sent_at number[]
---@field resent boolean[]
---@field resent_count integer
---@field acked_count integer
---@field acked_bytes integer
---@field base integer The first unacknowledged segment.
---@field highest integer The highest acknowledged segment.
---@field window number
---@field slow_start boolean
---@field srtt number | nil
---@field srtt_seeded boolean | nil `true` while `srtt` is the handshake sample.
---@field rto number
---@field loss_time number
---@field credit number The number of segments that can be sent right now, refilled by pacing.
---@field pump_time number
---@field accepted boolean
---@field activity number
---@field start_time number
---@field callback dreamwork.std.Network.FinishFn | nil

---@class dreamwork.std.Network.Incoming
---@field network dreamwork.std.Network
---@field peer garrysmod.Player | nil
---@field key garrysmod.Player | string
---@field id integer
---@field size integer
---@field segment_size integer
---@field count integer
---@field checksum integer
---@field buffered boolean `true` if the segments are kept for the receive handlers.
---@field crc dreamwork.std.checksum.CRC32 | nil The running checksum of the delivered data, if not buffered.
---@field segments string[]
---@field received_flags boolean[]
---@field received integer
---@field received_bytes integer
---@field base integer The first missing segment, everything before it is delivered.
---@field highest integer The highest received segment.
---@field ack_pending boolean
---@field ack_time number
---@field activity number
---@field start_time number

---@class dreamwork.std.Network.Queued
---@field data string
---@field callback dreamwork.std.Network.FinishFn | nil

---@type table<dreamwork.std.Network, table<garrysmod.Player | string, dreamwork.std.Network.Outgoing>>
local outgoing = {}

---@type table<dreamwork.std.Network, table<garrysmod.Player | string, dreamwork.std.Network.Incoming>>
local incoming = {}

---@type table<dreamwork.std.Network, table<garrysmod.Player | string, dreamwork.std.Network.Queued[]>>
local queues = {}

---@type table<dreamwork.std.Network.Outgoing, boolean>
local active_outgoing = {}

---@type table<dreamwork.std.Network.Incoming, boolean>
local active_incoming = {}

---@type integer
local transfer_counter = 0

do

    ---@param name string
    ---@return dreamwork.std.Network | nil object
    ---@protected
    function NetworkClass:__new( name )
        return networks[ name ]
    end

    ---@return string
    ---@protected
    function Network:__represent()
        return string_format( "Network: %p [%d][%s]", self, network_ids[ self ], network_names[ self ] )
    end

    ---@param name string
    ---@param can_receive boolean?
    ---@protected
    function Network:__init( name, can_receive )
        local network_name = name_prefix .. name

        ---@type integer | nil
        local network_id

        if LUA_SERVER then
            network_id = network_register( network_name )
        else
            network_id = network_getID( network_name )
        end

        if network_id == nil then
            error( string_format( "Network '%s' is not registered on the server, create it on the server first.", name ), 3 )
        end

        network_identifiers[ self ] = network_name
        network_ids[ self ] = network_id
        network_names[ self ] = name
        networks[ name ] = self

        receive_allowed[ self ] = can_receive == true
        timeouts[ self ] = 15.0
        windows[ self ] = 64
        limits[ self ] = 64 * 1024 * 1024
        segment_sizes[ self ] = default_segment_size

        local outgoing_states = {}
        gc_setTableRules( outgoing_states, true, false )
        outgoing[ self ] = outgoing_states

        local incoming_states = {}
        gc_setTableRules( incoming_states, true, false )
        incoming[ self ] = incoming_states

        local queue_lists = {}
        gc_setTableRules( queue_lists, true, false )
        queues[ self ] = queue_lists

        ---@param remaining_bits integer
        ---@param sender garrysmod.Player | nil
        network_receive_id( network_id, function( remaining_bits, sender )
            network_receive( self, remaining_bits, sender )
        end )
    end

    ---@type table<string, table<dreamwork.std.Network, any>>
    local key_to_table = {
        name = network_names,
        id = network_ids,
        receiver = receive_allowed,
        timeout = timeouts,
        window = windows,
        limit = limits,
        segment = segment_sizes
    }

    ---@param key string
    ---@protected
    function Network:__index( key )
        local tbl = key_to_table[ key ]
        if tbl ~= nil then
            return tbl[ self ]
        end

        return raw_index( Network, key )
    end

    ---@param key string
    ---@param value any
    ---@protected
    function Network:__newindex( key, value )
        if key == "receiver" then
            receive_allowed[ self ] = value == true
        elseif key == "timeout" then
            timeouts[ self ] = math_max( raw_tonumber( value, 10 ) or 15.0, 1.0 )
        elseif key == "window" then
            windows[ self ] = math_max( math_min( math_floor( raw_tonumber( value, 10 ) or 64 ), 256 ), 1 )
        elseif key == "limit" then
            limits[ self ] = math_max( math_min( math_floor( raw_tonumber( value, 10 ) or 0 ), max_transfer_size ), 0 )
        elseif key == "segment" then
            segment_sizes[ self ] = math_max( math_min( math_floor( raw_tonumber( value, 10 ) or default_segment_size ), max_segment_size ), min_segment_size )
        else
            error( "attempt to modify read-only object", 2 )
        end
    end

end

---@param state dreamwork.std.Network.Outgoing | dreamwork.std.Network.Incoming
---@param index integer
---@return integer length
local function segment_length( state, index )
    local count = state.count
    if index == count then
        return state.size - (count - 1) * state.segment_size
    end

    return state.segment_size
end

---@type fun( network: dreamwork.std.Network, data: string, peer: garrysmod.Player | nil, key: garrysmod.Player | string, callback: dreamwork.std.Network.FinishFn | nil )
local transmit_start

---@param network dreamwork.std.Network
---@param key garrysmod.Player | string
---@param peer garrysmod.Player | nil
local function transmit_next( network, key, peer )
    local queue = queues[ network ][ key ]
    if queue == nil then return end

    -- singles finish right away, so keep going until a segmented transfer takes the slot
    while outgoing[ network ][ key ] == nil do
        local queued = table_remove( queue, 1 )
        if queued == nil then
            queues[ network ][ key ] = nil
            return
        end

        transmit_start( network, queued.data, peer, key, queued.callback )
    end
end

---@param network dreamwork.std.Network
---@param key garrysmod.Player | string
---@param peer garrysmod.Player | nil
local function queue_flush( network, key, peer )
    local queue = queues[ network ][ key ]
    if queue == nil then return end

    queues[ network ][ key ] = nil

    for i = 1, #queue, 1 do
        local callback = queue[ i ].callback
        if callback ~= nil then
            exceptions_call( callback, network, false, peer )
        end
    end
end

---@param state dreamwork.std.Network.Outgoing
---@param success boolean
local function outgoing_finish( state, success )
    active_outgoing[ state ] = nil

    local network, key, peer = state.network, state.key, state.peer

    local states = outgoing[ network ]
    if states[ key ] == state then
        states[ key ] = nil
    end

    -- the next one starts first, so new transfers from the callback are queued behind it
    if peer_valid( peer ) then
        transmit_next( network, key, peer )
    else
        queue_flush( network, key, peer )
    end

    local callback = state.callback
    if callback ~= nil then
        exceptions_call( callback, network, success, peer )
    end
end

---@param state dreamwork.std.Network.Outgoing
---@param reason string
local function outgoing_cancel( state, reason )
    if peer_valid( state.peer ) then
        send_control( state.network, OP_CANCEL, state.id, state.peer )
    end

    dreamwork_Logger:warn( "Transmission #%d of network '%s' to %s was cancelled: %s [%d/%d segments, %d resent]", state.id, network_names[ state.network ], peer_tostring( state.peer ), reason, state.acked_count, state.count, state.resent_count )
    outgoing_finish( state, false )
end

---@param state dreamwork.std.Network.Incoming
local function incoming_detach( state )
    active_incoming[ state ] = nil

    local states = incoming[ state.network ]
    if states[ state.key ] == state then
        states[ state.key ] = nil
    end

    client_release( state.peer, state.size )
end

---@param state dreamwork.std.Network.Incoming
---@param success boolean
local function incoming_close( state, success )
    incoming_detach( state )

    local network = state.network

    events:emit( network, "stream", network, state.peer, nil, state.received_bytes, state.size, success )
end

---@param state dreamwork.std.Network.Incoming
---@param reason string
local function incoming_reject( state, reason )
    if peer_valid( state.peer ) then
        send_control( state.network, OP_REJECT, state.id, state.peer )
    end

    dreamwork_Logger:warn( "Receiving #%d of network '%s' from %s was aborted: %s [%d/%d segments]", state.id, network_names[ state.network ], peer_tostring( state.peer ), reason, state.received, state.count )
    incoming_close( state, false )
end

---@param state dreamwork.std.Network.Outgoing
---@param index integer
local function send_segment( state, index )
    local offset = (index - 1) * state.segment_size
    local length = segment_length( state, index )

    message_start( state.network, OP_SEGMENT, true )
    net_WriteUInt( state.id, transfer_id_size )
    net_WriteUInt( index, segment_index_size )
    net_WriteData( string_sub( state.data, offset + 1, offset + length ), length )
    message_send( state.peer )
end

---@param state dreamwork.std.Network.Outgoing
---@param now number
local function outgoing_pump( state, now )
    local acked, sent_at, resent = state.acked, state.sent_at, state.resent
    local highest = state.highest
    local rto = state.rto

    -- a hole behind newer acknowledged segments is most likely lost
    local srtt = state.srtt
    local fast_rto = (srtt == nil) and rto or math_min( srtt * 1.5, rto )

    local lost = false

    -- the channel can't send more right now, whatever is written would be dropped,
    -- the window isn't cut, choke happens without congestion too and real losses cut it anyway
    if peer_choked( state.peer ) then
        state.pump_time = now
        return
    end

    -- pacing, the window is spread over the rtt instead of a burst in one tick,
    -- and never faster than the data rate of the channel
    local window = state.window
    local elapsed = now - state.pump_time
    state.pump_time = now

    local credit = state.credit
    if srtt == nil then
        credit = window
    else
        credit = credit + math_min( window * pacing_gain * elapsed / srtt, peer_rate( state.peer ) * elapsed / state.segment_size )
    end

    if credit > window then
        credit = window
    end

    for index = state.base, math_min( state.base + math_floor( window ) - 1, state.count ), 1 do
        if credit < 1 then break end

        if not acked[ index ] then
            local time = sent_at[ index ]
            if time == nil or (now - time) >= ((index < highest) and fast_rto or rto) then
                credit = credit - 1

                if time ~= nil then
                    resent[ index ] = true
                    state.resent_count = state.resent_count + 1
                    lost = true
                end

                send_segment( state, index )
                sent_at[ index ] = now
            end
        end
    end

    state.credit = credit

    -- one window cut per rto, many segments time out together
    if lost and (now - state.loss_time) >= rto then
        state.loss_time = now
        state.slow_start = false
        state.window = math_max( state.window * 0.5, 1 )
        state.rto = math_min( rto * 1.5, 3.0 )
    end
end

---@param state dreamwork.std.Network.Incoming
---@param now number
local function send_ack( state, now )
    state.ack_pending = false
    state.ack_time = now

    local base, received_flags = state.base, state.received_flags

    local word_count = math_min( math_ceil( (state.highest - base) / 32 ), max_ack_words )
    if word_count < 0 then
        word_count = 0
    end

    message_start( state.network, OP_ACK, true )
    net_WriteUInt( state.id, transfer_id_size )
    net_WriteUInt( base, segment_index_size )
    net_WriteUInt( word_count, ack_words_size )

    local index = base + 1

    for _ = 1, word_count, 1 do
        local word, bit_value = 0, 1

        for _ = 1, 32, 1 do
            if received_flags[ index ] then
                word = word + bit_value
            end

            index = index + 1
            bit_value = bit_value * 2
        end

        write_uint32( word )
    end

    message_send( state.peer )
end

---@param network dreamwork.std.Network
---@param data string
---@param peer garrysmod.Player | nil
---@param key garrysmod.Player | string
---@param callback dreamwork.std.Network.FinishFn | nil
function transmit_start( network, data, peer, key, callback )
    local size = string_len( data )

    if size == 0 or (size <= single_threshold and (peer_reliable_written( peer ) + size) <= single_burst and single_allowed( peer, key, size )) then
        message_start( network, OP_SINGLE, false )

        if size ~= 0 then
            net_WriteData( data, size )
        end

        message_send( peer )

        dreamwork_Logger:debug( "Sent %d bytes to %s using network '%s'.", size, peer_tostring( peer ), network_names[ network ] )
        perform_progress( network, peer, true, size, size )

        if callback ~= nil then
            exceptions_call( callback, network, true, peer )
        end

        return
    end

    transfer_counter = (transfer_counter + 1) % 256

    local segment_size = segment_sizes[ network ]
    local now = dreamwork_getUpTime()

    ---@type dreamwork.std.Network.Outgoing
    local state = {
        network = network,
        peer = peer,
        key = key,
        id = transfer_counter,
        data = data,
        size = size,
        segment_size = segment_size,
        count = math_ceil( size / segment_size ),
        acked = {},
        sent_at = {},
        resent = {},
        resent_count = 0,
        acked_count = 0,
        acked_bytes = 0,
        base = 1,
        highest = 0,
        window = 4,
        slow_start = true,
        rto = 0.5,
        loss_time = 0,
        credit = 0,
        pump_time = now,
        accepted = false,
        activity = now,
        start_time = now,
        callback = callback
    }

    outgoing[ network ][ key ] = state
    active_outgoing[ state ] = true

    message_start( network, OP_BEGIN, false )
    net_WriteUInt( state.id, transfer_id_size )
    write_uint32( size )
    write_uint32( crc32_digest( data ) )
    net_WriteUInt( segment_size, segment_size_size )
    message_send( peer )

    dreamwork_Logger:debug( "Transmission #%d of network '%s' to %s started, %d bytes in %d segments.", state.id, network_names[ network ], peer_tostring( peer ), size, state.count )
end

---@param network dreamwork.std.Network
---@param data string
---@param peer garrysmod.Player | nil
---@param callback dreamwork.std.Network.FinishFn | nil
local function transmit( network, data, peer, callback )
    local key = peer or server_key

    if outgoing[ network ][ key ] == nil then
        transmit_start( network, data, peer, key, callback )
        return
    end

    local queue = queues[ network ][ key ]
    if queue == nil then
        queue = {}
        queues[ network ][ key ] = queue
    end

    queue[ #queue + 1 ] = {
        data = data,
        callback = callback
    }
end

---@param network dreamwork.std.Network
---@param data string
---@param target garrysmod.Player | garrysmod.Player[] | nil
---@param callback dreamwork.std.Network.FinishFn | nil
local function transmit_to( network, data, target, callback )
    if string_len( data ) > max_transfer_size then
        error( string_format( "Transmission is too large, %d bytes is more than the limit of %d bytes.", string_len( data ), max_transfer_size ), 3 )
    end

    if not LUA_SERVER then
        transmit( network, data, nil, callback )
    elseif target == nil then
        error( "Target player is required on the server.", 3 )
    elseif isTable( target ) then
        ---@cast target garrysmod.Player[]
        for i = 1, #target, 1 do
            transmit( network, data, target[ i ], callback )
        end
    else
        ---@cast target garrysmod.Player
        transmit( network, data, target, callback )
    end
end

--- [SHARED]
---
--- Sends the data to the target.
---
--- Small data is sent as a single reliable message,
--- larger data is split into segments and streamed with acknowledgements.
---
--- If the target is already receiving a transmission from this network, the data is queued behind it.
---
---@param data string The data to send.
---@param target ( garrysmod.Player | garrysmod.Player[] )? The target player(s), required on the server, ignored on the client.
---@param callback dreamwork.std.Network.FinishFn? The callback that is called when the transmission is finished or failed.
function Network:send( data, target, callback )
    transmit_to( self, data, target, callback )
end

--- [SHARED]
---
--- Builds the data with a binary writer and sends it to the target.
---
---@param fn fun( network: dreamwork.std.Network, writer: dreamwork.std.BinaryWriter ) The function that writes the data.
---@param target ( garrysmod.Player | garrysmod.Player[] )? The target player(s), required on the server, ignored on the client.
---@param callback dreamwork.std.Network.FinishFn? The callback that is called when the transmission is finished or failed.
function Network:transmit( fn, target, callback )
    local writer = BinaryWriter()
    fn( self, writer )
    transmit_to( self, writer:compile(), target, callback )
end

--- [SHARED]
---
--- Cancels the outgoing transmission to the target and all queued ones.
---
---@param target garrysmod.Player? The target player, required on the server, ignored on the client.
---@return boolean cancelled `true` if anything was cancelled.
function Network:abort( target )
    local key = (LUA_SERVER and target) or server_key
    local peer = LUA_SERVER and target or nil

    local had_queue = queues[ self ][ key ] ~= nil
    queue_flush( self, key, peer )

    local state = outgoing[ self ][ key ]
    if state == nil then
        return had_queue
    end

    outgoing_cancel( state, "aborted" )
    return true
end

--- [SHARED]
---
--- Checks if the network is sending data to the target.
---
---@param target garrysmod.Player? The target player, required on the server, ignored on the client.
---@return boolean is_sending
---@nodiscard
function Network:isSending( target )
    return outgoing[ self ][ (LUA_SERVER and target) or server_key ] ~= nil
end

--- [SHARED]
---
--- Checks if the network is receiving data from the sender.
---
---@param sender garrysmod.Player? The sender player, required on the server, ignored on the client.
---@return boolean is_receiving
---@nodiscard
function Network:isReceiving( sender )
    return incoming[ self ][ (LUA_SERVER and sender) or server_key ] ~= nil
end

---@type table<integer, fun( network: dreamwork.std.Network, peer: garrysmod.Player | nil, key: garrysmod.Player | string, transfer_id: integer, remaining_bits: integer )>
local handlers = {}

-- receiver side

handlers[ OP_BEGIN ] = function( network, peer, key, transfer_id, remaining_bits )
    if remaining_bits < (64 + segment_size_size) then
        violation( network, peer, 8, "malformed BEGIN" )
        return
    end

    local size = read_uint32()
    local checksum = read_uint32()
    local segment_size = net_ReadUInt( segment_size_size )

    local previous = incoming[ network ][ key ]
    if previous ~= nil then
        dreamwork_Logger:debug( "Receiving #%d of network '%s' from %s was replaced by #%d.", previous.id, network_names[ network ], peer_tostring( peer ), transfer_id )
        incoming_close( previous, false )
    end

    if not receive_allowed[ network ] then
        send_control( network, OP_REJECT, transfer_id, peer )
        violation( network, peer, 4, "transfer to a network that is not receiving" )
        return
    end

    if segment_size < min_segment_size or segment_size > max_segment_size or math_ceil( size / segment_size ) > 0xFFFFFF then
        send_control( network, OP_REJECT, transfer_id, peer )
        violation( network, peer, 8, "invalid segment size of %d bytes", segment_size )
        return
    end

    if size == 0 or size > limits[ network ] then
        send_control( network, OP_REJECT, transfer_id, peer )
        violation( network, peer, 4, "transfer of %d bytes, the limit is %d bytes", size, limits[ network ] )
        return
    end

    local admit_error = client_admit( peer, size )
    if admit_error ~= nil then
        send_control( network, OP_REJECT, transfer_id, peer )
        violation( network, peer, 1, admit_error )
        return
    end

    -- without receive handlers the data is only streamed, so it isn't kept
    local buffered = events:count( network, "receive" ) ~= 0 or events:count( network, "stream" ) == 0

    local now = dreamwork_getUpTime()

    ---@type dreamwork.std.Network.Incoming
    local state = {
        network = network,
        peer = peer,
        key = key,
        id = transfer_id,
        size = size,
        segment_size = segment_size,
        count = math_ceil( size / segment_size ),
        checksum = checksum,
        buffered = buffered,
        crc = (not buffered) and CRC32() or nil,
        segments = {},
        received_flags = {},
        received = 0,
        received_bytes = 0,
        base = 1,
        highest = 0,
        ack_pending = false,
        ack_time = now,
        activity = now,
        start_time = now
    }

    incoming[ network ][ key ] = state
    active_incoming[ state ] = true

    send_control( network, OP_ACCEPT, transfer_id, peer )

    dreamwork_Logger:debug( "Receiving #%d of network '%s' from %s started, %d bytes in %d segments.", transfer_id, network_names[ network ], peer_tostring( peer ), size, state.count )
end

handlers[ OP_SEGMENT ] = function( network, peer, key, transfer_id, remaining_bits )
    -- stale segments of a finished or replaced transfer are expected
    local state = incoming[ network ][ key ]
    if state == nil or state.id ~= transfer_id then return end

    if remaining_bits < segment_index_size then
        violation( network, peer, 8, "malformed SEGMENT" )
        return
    end

    local index = net_ReadUInt( segment_index_size )

    local count = state.count
    if index < 1 or index > count then
        violation( network, peer, 4, "segment %d is out of range [1, %d]", index, count )
        return
    end

    -- duplicates mean the sender missed an ack
    state.ack_pending = true

    local received_flags = state.received_flags
    if received_flags[ index ] then return end

    local length = math_floor( (remaining_bits - segment_index_size) / 8 )

    if length ~= segment_length( state, index ) then
        violation( network, peer, 4, "segment %d has a wrong size of %d bytes", index, length )
        return
    end

    local segments = state.segments

    received_flags[ index ] = true
    segments[ index ] = net_ReadData( length )

    local received = state.received + 1
    state.received = received
    state.received_bytes = state.received_bytes + length
    state.activity = dreamwork_getUpTime()

    if index > state.highest then
        state.highest = index
    end

    -- in-order delivery to the stream handlers
    local base = state.base
    if index == base then
        local buffered, crc = state.buffered, state.crc

        repeat
            events:emit( network, "stream", network, peer, segments[ base ], (base - 1) * state.segment_size, state.size )

            if not buffered then
                ---@cast crc dreamwork.std.checksum.CRC32
                crc:update( segments[ base ] )
                segments[ base ] = nil
            end

            base = base + 1
        until not received_flags[ base ]

        state.base = base
    end

    perform_progress( network, peer, false, state.received_bytes, state.size )

    if received ~= count then return end

    -- the closing call of the streams must know the result, so it is called below
    incoming_detach( state )

    ---@type string | nil
    local data

    ---@type integer
    local data_checksum

    if state.buffered then
        data = table_concat( segments, "", 1, count )
        data_checksum = crc32_digest( data )
    else
        data_checksum = state.crc:digest()
    end

    local success = data_checksum == state.checksum

    if success then
        send_control( network, OP_FINISH, transfer_id, peer )
        dreamwork_Logger:debug( "Receiving #%d of network '%s' from %s finished, %d bytes in %.2f seconds.", transfer_id, network_names[ network ], peer_tostring( peer ), state.size, state.activity - state.start_time )
    else
        send_control( network, OP_REJECT, transfer_id, peer )
        dreamwork_Logger:error( "Receiving #%d of network '%s' from %s failed, checksum mismatch.", transfer_id, network_names[ network ], peer_tostring( peer ) )
    end

    events:emit( network, "stream", network, peer, nil, state.received_bytes, state.size, success )

    if success and data ~= nil then
        perform_callbacks( network, data, peer )
    end
end

handlers[ OP_CANCEL ] = function( network, peer, key, transfer_id )
    local state = incoming[ network ][ key ]
    if state == nil or state.id ~= transfer_id then return end

    dreamwork_Logger:debug( "Receiving #%d of network '%s' from %s was cancelled by the sender.", transfer_id, network_names[ network ], peer_tostring( peer ) )
    incoming_close( state, false )
end

-- sender side

handlers[ OP_ACCEPT ] = function( network, peer, key, transfer_id )
    local state = outgoing[ network ][ key ]
    if state == nil or state.id ~= transfer_id then return end

    local now = dreamwork_getUpTime()

    state.accepted = true
    state.activity = now
    state.pump_time = now

    -- the first rtt comes from the engine or the handshake, so pacing and rto don't start blind,
    -- the handshake went through the reliable stream that can be clogged, so the first real sample replaces it
    local srtt = peer_latency( peer ) or (now - state.start_time)
    state.srtt = srtt
    state.srtt_seeded = true
    state.rto = math_min( math_max( srtt * 2 + 0.03, 0.06 ), 3.0 )

    -- the first window goes out right away
    state.credit = state.window
end

---@param state dreamwork.std.Network.Outgoing
---@param index integer
---@return number | nil sent_at The time the segment was sent, if it is a valid rtt sample.
local function outgoing_ack( state, index )
    local acked = state.acked
    if acked[ index ] then return nil end

    acked[ index ] = true

    state.acked_count = state.acked_count + 1
    state.acked_bytes = state.acked_bytes + segment_length( state, index )

    if index > state.highest then
        state.highest = index
    end

    -- karn's algorithm, resent segments give ambiguous samples
    if state.resent[ index ] then
        return nil
    end

    return state.sent_at[ index ]
end

handlers[ OP_ACK ] = function( network, peer, key, transfer_id, remaining_bits )
    local state = outgoing[ network ][ key ]
    if state == nil or state.id ~= transfer_id or remaining_bits < (segment_index_size + ack_words_size) then return end

    local ack_base = net_ReadUInt( segment_index_size )
    local word_count = net_ReadUInt( ack_words_size )

    local count = state.count
    if ack_base < 1 or ack_base > count + 1 or word_count > max_ack_words or remaining_bits < (segment_index_size + ack_words_size + word_count * 32) then return end

    local acked_count = state.acked_count

    ---@type number
    local sample_time = 0

    for index = state.base, ack_base - 1, 1 do
        local sent_at = outgoing_ack( state, index )
        if sent_at ~= nil and sent_at > sample_time then
            sample_time = sent_at
        end
    end

    for word_index = 0, word_count - 1, 1 do
        local word = read_uint32()
        local index = ack_base + 1 + word_index * 32

        while word ~= 0 and index <= count do
            local bit_value = word % 2
            word = (word - bit_value) * 0.5

            if bit_value == 1 then
                local sent_at = outgoing_ack( state, index )
                if sent_at ~= nil and sent_at > sample_time then
                    sample_time = sent_at
                end
            end

            index = index + 1
        end
    end

    local newly_acked = state.acked_count - acked_count
    if newly_acked == 0 then return end

    local now = dreamwork_getUpTime()
    state.activity = now

    -- the newest segment gives the freshest sample
    if sample_time ~= 0 then
        local sample = now - sample_time

        local srtt = state.srtt
        if srtt == nil or state.srtt_seeded then
            srtt = sample
            state.srtt_seeded = false
        else
            srtt = srtt * 0.875 + sample * 0.125
        end

        state.srtt = srtt
        state.rto = math_min( math_max( srtt * 2 + 0.03, 0.06 ), 3.0 )
    end

    local window = state.window
    if state.slow_start then
        window = window + newly_acked
    else
        window = window + newly_acked / window
    end

    state.window = math_min( window, windows[ network ] )

    local acked, base = state.acked, state.base
    while acked[ base ] do
        base = base + 1
    end

    state.base = base

    perform_progress( network, peer, true, state.acked_bytes, state.size )
end

handlers[ OP_FINISH ] = function( network, peer, key, transfer_id )
    local state = outgoing[ network ][ key ]
    if state == nil or state.id ~= transfer_id then return end

    local elapsed = dreamwork_getUpTime() - state.start_time
    dreamwork_Logger:debug( "Transmission #%d of network '%s' to %s finished, %d bytes in %.2f seconds (%.2f KiB/s), window %.1f, srtt %.0f ms, %d/%d segments resent.", transfer_id, network_names[ network ], peer_tostring( peer ), state.size, elapsed, (state.size / 1024) / math_max( elapsed, 0.001 ), state.window, (state.srtt or 0) * 1000, state.resent_count, state.count )

    outgoing_finish( state, true )
end

handlers[ OP_REJECT ] = function( network, peer, key, transfer_id )
    local state = outgoing[ network ][ key ]
    if state == nil or state.id ~= transfer_id then return end

    dreamwork_Logger:warn( "Transmission #%d of network '%s' to %s was rejected by the receiver.", transfer_id, network_names[ network ], peer_tostring( peer ) )
    outgoing_finish( state, false )
end

---@param network dreamwork.std.Network
---@param remaining_bits integer
---@param sender garrysmod.Player | nil
function network_receive( network, remaining_bits, sender )
    if not LUA_SERVER then
        sender = nil
    end

    if remaining_bits < opcode_size then
        violation( network, sender, 8, "empty message" )
        return
    end

    local opcode = net_ReadUInt( opcode_size )
    remaining_bits = remaining_bits - opcode_size

    if opcode == OP_SINGLE then
        if not receive_allowed[ network ] then
            violation( network, sender, 4, "message to a network that is not receiving" )
            return
        end

        local length = math_floor( remaining_bits / 8 )

        if length > limits[ network ] then
            violation( network, sender, 4, "message of %d bytes, the limit is %d bytes", length, limits[ network ] )
            return
        end

        local data = (length == 0) and "" or net_ReadData( length )

        perform_progress( network, sender, false, length, length )

        events:emit( network, "stream", network, sender, data, 0, length )
        events:emit( network, "stream", network, sender, nil, length, length, true )

        perform_callbacks( network, data, sender )
        return
    end

    if remaining_bits < transfer_id_size then
        violation( network, sender, 8, "malformed message" )
        return
    end

    local transfer_id = net_ReadUInt( transfer_id_size )

    handlers[ opcode ]( network, sender, sender or server_key, transfer_id, remaining_bits - transfer_id_size )
end

---@type dreamwork.std.Network.Outgoing[] | dreamwork.std.Network.Incoming[]
local tick_states = {}

engine_hook.catch( "Tick", "dreamwork.std.Network", function()
    local now = dreamwork_getUpTime()

    -- callbacks can start new transfers, so the sets are not modified while iterating
    local state_count = 0

    for state in raw_pairs( active_outgoing ) do
        state_count = state_count + 1
        tick_states[ state_count ] = state
    end

    for i = 1, state_count, 1 do
        local state = tick_states[ i ]
        tick_states[ i ] = nil

        ---@cast state dreamwork.std.Network.Outgoing

        if not active_outgoing[ state ] then
            -- removed by a callback of another state
        elseif not peer_valid( state.peer ) then
            outgoing_finish( state, false )
        elseif (now - state.activity) > timeouts[ state.network ] then
            outgoing_cancel( state, "timed out" )
        elseif state.accepted then
            outgoing_pump( state, now )
        end
    end

    state_count = 0

    for state in raw_pairs( active_incoming ) do
        state_count = state_count + 1
        tick_states[ state_count ] = state
    end

    for i = 1, state_count, 1 do
        local state = tick_states[ i ]
        tick_states[ i ] = nil

        ---@cast state dreamwork.std.Network.Incoming

        if not active_incoming[ state ] then
            -- removed by a callback of another state
        elseif not peer_valid( state.peer ) then
            incoming_close( state, false )
        elseif (now - state.activity) > timeouts[ state.network ] then
            incoming_reject( state, "timed out" )
        elseif state.ack_pending or (state.received ~= 0 and (now - state.ack_time) >= ack_refresh_interval) then
            -- the refresh repairs lost acks without waiting for the sender to resend
            send_ack( state, now )
        end
    end
end )
