
---@type dreamwork
local dreamwork = _G.dreamwork

---@type dreamwork.engine
local engine = dreamwork.engine

---@class dreamwork.std
local std = dreamwork.std
local raw = std.raw
local gc = std.gc

local LUA_CLIENT = std.LUA_CLIENT
local LUA_SERVER = std.LUA_SERVER

---@type dreamwork.std.string
local string = std.string

local futures_run = std.futures.run
local os_clock = os.clock

---@type dreamwork.std.math
local math = std.math
local math_ceil, math_floor = math.ceil, math.floor

local crc16_digest = std.checksum.CRC16.digest

---@class dreamwork.std.Network.Reader

---@class dreamwork.std.Network.Writer

---
--- in bits
---
---@type integer
local net_limit = ( ( 64 * 1024 ) - 1 ) * 8

---
--- in bits
---
---@type integer
local internal_header = 8 + -- unknown magical byte
    dreamwork.engine.NetworkHeaderSize + -- header ( network id ) + unreliable
    1 -- is complex

-- TODO: all network messages are byte strings, that will mean that it will fully builded before send and them fully received before perform readers

---@class dreamwork.std.Network : dreamwork.Object
---@field __class dreamwork.std.NetworkClass
---@field id integer
---@field name string
---@field receiver boolean
---@field receiving boolean
---@field sending boolean
---@field timeout number
local Network = std.class.base( "Network", true )

---@class dreamwork.std.NetworkClass : dreamwork.std.Network
---@field __base dreamwork.std.Network
---@overload fun( name: string, can_receive?: boolean ): dreamwork.std.Network
local NetworkClass = std.class.create( Network )
std.Network = NetworkClass


---@type table<string, dreamwork.std.Network>
local name_to_network = {}
gc.setTableRules( name_to_network, false, true )

---@param name string
---@return dreamwork.std.Network | nil object
---@protected
function NetworkClass:__new( name )
    return name_to_network[ name ]
end

---@class dreamwork.std.Network.Callback
---@field name string
---@field fn fun( network: dreamwork.std.Network, reader: dreamwork.std.pack.Reader, index: integer, total: integer )
---@field once boolean

---@type table<dreamwork.std.Network, string>
local network_to_name = {}
gc.setTableRules( network_to_name, true, false )

---@type table<dreamwork.std.Network, string>
local network_to_identifier = {}
gc.setTableRules( network_to_identifier, true, false )

---@type table<dreamwork.std.Network, integer>
local network_to_index = {}
gc.setTableRules( network_to_index, false, true )

---@type table<integer, dreamwork.std.Network>
local index_to_network = {}
gc.setTableRules( index_to_network, false, true )

---@type table<dreamwork.std.Network, boolean>
local network_receiver = {}
gc.setTableRules( network_receiver, true, false )

---@type table<dreamwork.std.Network, dreamwork.std.Network.Callback[]>
local network_callbacks = {}
gc.setTableRules( network_callbacks, true, false )

---@type table<dreamwork.std.Network, number>
local network_timeout = {}
gc.setTableRules( network_timeout, true, false )

---@type table<dreamwork.std.Network, boolean>
local network_receiving = {}
gc.setTableRules( network_receiving, true, false )

---@type table<dreamwork.std.Network, boolean>
local network_sending = {}
gc.setTableRules( network_sending, true, false )


---@param name string
---@protected
function Network:__init( name, can_receive )
    local network_name = "\255\128\64\0" .. name

    network_to_identifier[ self ] = network_name

    local network_id = engine.networkRegister( network_name )
    network_to_index[ self ] = network_id
    index_to_network[ network_id ] = self

    network_to_name[ self ] = name
    name_to_network[ name ] = self

    network_receiver[ self ] = can_receive == true

    network_callbacks[ self ] = { [ 0 ] = 0 }
    network_receiving[ self ] = false
    network_sending[ self ] = false
    network_timeout[ self ] = 1.0
end

do

    local raw_index = raw.index

    ---@typa table<string, table<dreamwork.std.Network, any>>
    local key_to_table = {
        [ "name" ] = network_to_name,
        [ "timeout" ] = network_timeout,
        [ "receiver" ] = network_receiver,
        [ "receiving" ] = network_receiving,
        [ "sending" ] = network_sending,
        [ "id" ] = network_to_index
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

end

---@param key string
---@param value any
---@protected
function Network:__newindex( key, value )
    if key == "timeout" then
        network_timeout[ self ] = math.max( raw.tonumber( value or 1.0, 10 ) or 1.0, 0.1 )
    elseif key == "receiver" then
        network_receiver[ self ] = value == true
    end

    error( "attempt to modify read-only object", 2 )
end

---@return string
---@protected
function Network:__tostring()
    return string.format( "Network: %p [%d][%s]", self, network_to_index[ self ], network_to_name[ self ] )
end

---@param fn fun( network: dreamwork.std.Network, reader: dreamwork.std.pack.Reader, index: integer, total: integer )
---@param identifier? string
---@param once? boolean
function Network:attach( fn, identifier, once )
    local callbacks = network_callbacks[ self ]
    local callback_count = callbacks[ 0 ]

    if identifier == nil then
        identifier = "nil"
    end

    for i = 1, callback_count, 1 do
        local callback = callbacks[ i ]
        if callback.name == identifier then
            callback.fn = fn
            callback.once = once == true
            return
        end
    end

    callback_count = callback_count + 1

    callbacks[ callback_count ] = {
        once = once == true,
        name = identifier,
        fn = fn
    }

    callbacks[ 0 ] = callback_count
end

---@param identifier? string
function Network:detach( identifier )
    local callbacks = network_callbacks[ self ]
    local callback_count = callbacks[ 0 ]

    if identifier == nil then
        identifier = "nil"
    end

    for i = 1, callback_count, 1 do
        local callback = callbacks[ i ]
        if callback.name == identifier then
            callbacks[ 0 ] = callback_count - 1
            table.remove( callbacks, i )
            break
        end
    end
end


--[[

        Transmission Loop

  Sender            Receiver
    |                   |
    |               await data
    |                   |
    | Segment sent (UDP)|   -> -> -> ( index, data )        [ sender have to repeat attepts of sending data block with specified timeout, if checksum not received or mismatch ]
    | - - > - - - > - - |
    |                   |                 \ | /
await respond           |                  \|/
    |                   |                   |
    | Segment info (UDP)|
    | - - < - - - < - - |   <- <- <- ( checksum )           [ receiver have to respond with data block checksum with specified timeout, if next data block not received, final block must be empty ( \0 ) ]
    |                   |

--]]


---@class dreamwork.std.Network.Transmission.Initial
---@field segments_total integer

---@class dreamwork.std.Network.Transmission.Final
---@field segments_received integer
---@field checksum integer

--[[

        network message

            ( 1 bit )
        is complex message
        |            |
        true        false
        |            |
    block_count      body
    ( 16 bit )
        |
        body


--]]

---
--- in bits
---
---@type integer
local max_package_size = net_limit - internal_header


---
--- in bytes
---
---@type integer
local header_free_space = math_floor( ( max_package_size - ( 1 ) ) / 8 )

---@param bytes integer
---@return integer block_count
local function get_block_count( bytes )
    if bytes > 0 then
        return math_ceil(
            math_ceil( bytes * 8 ) / max_package_size
        )
    end

    return 1
end

---@param network dreamwork.std.Network
---@param segments string[]
---@param index integer
---@param total integer
local function perform_callbacks( network, segments, index, total )
    local callbacks = network_callbacks[ network ]

    local reader = std.pack.Reader()
    reader:open( table.concat( segments, "", 1, index ) )

    for i = 1, callbacks[ 0 ], 1 do
        reader:seek( 0 )
        callbacks[ i ].fn( network, reader, index, total )
    end

    reader:close()
end

if LUA_SERVER then

    ---@class dreamwork.std.Network.Transmission.Activity
    ---@field thread thread
    ---@field time number

    ---@type dreamwork.std.Network.Transmission.Activity[]
    local outgoing_activity = { [ 0 ] = 0 }

    ---@type table<Player, table<integer, thread>>
    local outgoing_transmissions = {}

    setmetatable( outgoing_transmissions, {
        __index = function( self, pl )
            local threads = {}
            self[ pl ] = threads
            return threads
        end,
        __mode = "k"
    } )

    engine.hookCatch( "Think", function()
        local time_used = os_clock()

        for i = 1, outgoing_activity[ 0 ], 1 do
            local activity = outgoing_activity[ i ]
            if time_used > activity.time then
                coroutine.resume( activity.thread, false )
            end
        end
    end )

    ---@param network dreamwork.std.Network
    ---@param thread thread
    local function update_outgoing( network, thread )
        local thread_count = outgoing_activity[ 0 ]

        for i = thread_count, 1, -1 do
            if outgoing_activity[ i ].thread == thread then
                outgoing_activity[ i ].time = os_clock() + network.timeout
                return
            end
        end

        thread_count = thread_count + 1
        outgoing_activity[ 0 ] = thread_count

        outgoing_activity[ thread_count ] = {
            thread = thread,
            time = os_clock() + network.timeout
        }
    end

    ---@param client Player
    ---@param network_id integer
    local function kill_outgoing( client, network_id )
        local outgoing_thread = outgoing_transmissions[ client ][ network_id ]
        if outgoing_thread == nil then return end

        outgoing_transmissions[ client ][ network_id ] = nil

        local thread_count = outgoing_activity[ 0 ]

        for i = thread_count, 1, -1 do
            if outgoing_activity[ i ].thread == outgoing_thread then
                outgoing_activity[ 0 ] = thread_count - 1
                outgoing_activity[ i ] = nil
                break
            end
        end
    end

    local function abort_transmission( network, client )
        if not network_sending[ network ] then return end
        network_sending[ network ] = false

        kill_outgoing( client, network_to_index[ network ] )

        net.Start( network_to_identifier[ network ], false )
        net.Send( client )
    end

    ---@param network dreamwork.std.Network
    ---@param client Player
    ---@param segments string[]
    ---@param segment_count integer
    ---@async
    local function complex_transmission( network, client, segments, segment_count )
        local network_name = network_to_identifier[ network ]

        network_sending[ network ] = true

        net.Start( network_name, false )

        net.WriteBool( true )
        net.WriteUInt( segment_count, 16 )

        net.Send( client )

        dreamwork.Logger:debug( "Sended a handshake for a new transmission, waiting for confirmation... [complex: yes, id: %d, target: %s]", network_to_index[ network ], client )

        local checksum = 0
        local index = 0
        local segment

        ::next_segment::

        index = index + 1
        segment = segments[ index ]
        checksum = crc16_digest( segment )

        ::send_segment::

        net.Start( network_name, true )
        net.WriteData( segment )
        net.Send( client )

        dreamwork.Logger:debug( "Sended segment %d/%d [%d bytes, target: %s, checksum: %x]", index, segment_count, string.len( segment ), client, checksum )

        update_outgoing( network, coroutine.running() )

        local persisted = coroutine.yield()

        if persisted then
            if index ~= net.ReadUInt( 16 ) then
                print( "wrong data index" )
                goto send_segment
            end

            if checksum ~= net.ReadUInt( 16 ) then
                print( "wrong checksum" )
                goto send_segment
            end

            dreamwork.Logger:debug( "delivered segment %d/%d [%d bytes]", index, segment_count, string.len( segment ) )

            if index < segment_count then
                goto next_segment
            end

            abort_transmission( network, client )

            dreamwork.Logger:debug( "transmission finished" )
            return
        end

        dreamwork.Logger:debug( "timeout" )
        goto send_segment
    end

    ---@param network dreamwork.std.Network
    ---@param data string
    ---@param client Player
    local function transmit( network, data, client )
        print()
        dreamwork.Logger:debug( "Started transmission for %s", client )

        local length = string.len( data )
        dreamwork.Logger:debug( "total size %d bytes", length )

        if header_free_space < length then
            if network_sending[ network ] then
                abort_transmission( network, client )
            else
                network_sending[ network ] = true
            end

            local total = get_block_count( length )
            dreamwork.Logger:debug( "total segments %d", total )

            local segment_size = math.floor( length / total )
            dreamwork.Logger:debug( "segment size %d bytes", segment_size )

            local segments, segment_count = string.divide( data, segment_size )
            dreamwork.Logger:debug( "transmitting %d segments", segment_count )

            local outgoing_thread = coroutine.create( complex_transmission )

            local success, err_msg = coroutine.resume( outgoing_thread, network, client, segments, segment_count )
            if not success then
                error( err_msg, 2 )
            end

            outgoing_transmissions[ client ][ network_to_index[ network ] ] = outgoing_thread
            return
        end

        net.Start( network_to_identifier[ network ], false )

        net.WriteBool( false )
        net.WriteData( data )

        net.Send( client )

        dreamwork.Logger:debug( "transmission finished" )
    end

    ---@param fn fun( network: dreamwork.std.Network, writer: dreamwork.std.pack.Writer )
    ---@param client Player
    ---@return thread | nil
    function Network:transmit( fn, client )
        local writer = std.pack.Writer()
        writer:open()

        fn( self, writer )

        transmit( self, writer:flush(), client )
    end

    ---@param network_id integer
    ---@param unreliable boolean
    ---@param message_length integer
    ---@param sender Player | nil
    engine.hookCatch( "IncomingNetworkMessage", function( network_id, unreliable, message_length, sender )
        local networks = outgoing_transmissions[ sender ]
        if networks ~= nil and unreliable then
            local outgoing_thread = networks[ network_id ]
            if outgoing_thread ~= nil then
                local success, err_msg = coroutine.resume( outgoing_thread, true )
                if not success then
                    dreamwork.Logger:error( "Failed to resume transmission: %s", err_msg )
                end

                return true
            end
        end

        return false
    end, 2 )

end

---@class dreamwork.std.Network.Transmission.Segment
---@field segments string[]>
---@field checksum dreamwork.std.checksum.CRC16
---@field total integer

if LUA_CLIENT then

    ---@type table<integer, thread>
    local incoming_transmissions = {}
    gc.setTableRules( incoming_transmissions, false, true )

    ---@type dreamwork.std.Network.Transmission.Activity[]
    local incoming_activity = { [ 0 ] = 0 }

    engine.hookCatch( "Think", function()
        local time_used = os_clock()

        for i = 1, incoming_activity[ 0 ], 1 do
            local activity = incoming_activity[ i ]
            if time_used > activity.time then
                coroutine.resume( activity.thread, false )
            end
        end
    end )

    ---@param network dreamwork.std.Network
    ---@param thread thread
    local function update_incoming( network, thread )
        local thread_count = incoming_activity[ 0 ]

        for i = thread_count, 1, -1 do
            if incoming_activity[ i ].thread == thread then
                incoming_activity[ i ].time = os_clock() + network.timeout
                return
            end
        end

        thread_count = thread_count + 1
        incoming_activity[ 0 ] = thread_count

        incoming_activity[ thread_count ] = {
            thread = thread,
            time = os_clock() + network.timeout
        }
    end

    ---@param network_id integer
    local function kill_incoming( network_id )
        local incoming_thread = incoming_transmissions[ network_id ]
        if incoming_thread == nil then return end

        incoming_transmissions[ network_id ] = nil

        local thread_count = incoming_activity[ 0 ]

        for i = thread_count, 1, -1 do
            if incoming_activity[ i ].thread == incoming_thread then
                incoming_activity[ 0 ] = thread_count - 1
                incoming_activity[ i ] = nil
                break
            end
        end
    end

    ---@param network dreamwork.std.Network
    ---@param network_name string
    ---@param segment_index integer
    ---@param segment_checksum integer
    local function send_checksum( network, network_name, segment_index, segment_checksum )
        net.Start( network_name, true )
        net.WriteUInt( segment_index, 16 )
        net.WriteUInt( segment_checksum, 16 )
        net.SendToServer()

        update_incoming( network, coroutine.running() )
    end

    local function abort_receiving( network )
        if not network_receiving[ network ] then return end
        network_receiving[ network ] = false

        kill_incoming( network_to_index[ network ] )
    end

    ---@param network dreamwork.std.Network
    ---@param total_segments integer
    local function complex_receiving( network, total_segments )
        local network_name = network_to_identifier[ network ]
        local checksum = std.checksum.CRC16()

        ---@type string[]
        local segments = {}

        ---@type integer
        local segment_count = 0

        ---@type integer
        local segment_checksum = 0

        ::await_response::

        local persisted, message_length = coroutine.yield( segment_count == total_segments )

        if persisted then
            local data = net.ReadData( math.ceil( message_length / 8 ) )

            segment_count = segment_count + 1
            segments[ segment_count ] = data

            segment_checksum = crc16_digest( data )
            checksum:update( data )

            send_checksum( network, network_name, segment_count, segment_checksum )
            perform_callbacks( network, segments, segment_count, total_segments )
        else
            send_checksum( network, network_name, segment_count, segment_checksum )
            dreamwork.Logger:debug( "timeout" )
        end

        goto await_response
    end

    ---@param network_id integer
    ---@param unreliable boolean
    ---@param message_length integer
    engine.hookCatch( "IncomingNetworkMessage", function( network_id, unreliable, message_length )
        local network = index_to_network[ network_id ]
        if network == nil then return false end

        if not network_receiver[ network ] then
            dreamwork.Logger:warn( "Server attempted to send a message to a network that is not receiving, disconnecting... [id: %d]", network_id )
            return false
        end

        if network_receiving[ network ] then
            local incoming_thread = incoming_transmissions[ network_id ]
            if incoming_thread == nil then
                dreamwork.Logger:error( "Thread not found, possibly a memory corruption, disconnecting... [complex: yes, id: %d]", network_id )
                abort_receiving( network )
                return true
            end

            if unreliable then
                local success, result = coroutine.resume( incoming_thread, true, message_length )
                if success and not result then return true end
            end

            dreamwork.Logger:debug( "Transmission finished, completing... [complex: yes, id: %d]", network_id )
            abort_receiving( network )
            return true
        end

        if unreliable then
            dreamwork.Logger:error( "Server attempted to send a data segment without a handshake, disconnecting... [complex: %s, id: %d]", is_complex and "yes" or "no", network_id )
            return true
        end

        if message_length == 0 then
            dreamwork.Logger:error( "Sender sended abort message without transmission, ignoring... [complex: yes, id: %d]", network_id )
            return false
        end

        local is_complex = net.ReadBool()
        message_length = message_length - 1

        if is_complex then
            dreamwork.Logger:debug( "Received a handshake for a new transmission, preparing to receive... [complex: yes, id: %d]", network_id )

            local incoming_thread = coroutine.create( complex_receiving )
            local success, err_msg = coroutine.resume( incoming_thread, network, net.ReadUInt( 16 ) )

            if success then
                incoming_transmissions[ network_id ] = incoming_thread
                network_receiving[ network ] = true
            else
                dreamwork.Logger:error( "Failed to resume transmission: %s", err_msg )
            end

            return true
        end

        dreamwork.Logger:debug( "Received a handshake for a new transmission, preparing to receive... [complex: %s, id: %d]", is_complex and "yes" or "no", network_id )
        perform_callbacks( network, { [ 0 ] = 1, net.ReadData( math.ceil( message_length / 8 ) ) }, 1, 1 )

        return true
    end, 2 )

end

local n = NetworkClass( "test", LUA_CLIENT )

if SERVER then

    concommand.Add( "testss", function( pl )
        n:transmit( function( self, writer )
            local data = file.Read( "rwd2rjdb3htb1.gif", "GAME" )
            dreamwork.Logger:debug( "sending: %d bytes", #data )
            writer:writeCountedString( data, 32 )
        end, pl )
    end )

else

    local start_time

    n:attach( function( self, reader, index, total )
        if index == 1 then
            start_time = os.clock()
        end

        dreamwork.Logger:debug( "received segment %d/%d, took %f s", index, total, std.time.tick() )

        if index == total then
            dreamwork.Logger:debug( "transmission finished, received %d bytes, took %f s", #reader:readCountedString( 32 ), os.clock() - start_time )
        end
    end )

end

engine.hookCatch( "IncomingNetworkMessage", function( network_id, unreliable, message_length )
    dreamwork.Logger:debug( "Received message, id: %d, unreliable: %s, message_length: %d", network_id, unreliable and "true" or "false", message_length )
end, 1 )
