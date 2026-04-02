
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
local string_len = string.len

local os_clock = os.clock

---@type dreamwork.std.math
local math = std.math
local math_ceil, math_floor = math.ceil, math.floor

local crc16_digest = std.checksum.CRC16.digest

--[[

        Transmission Header

           is complex
         /  ( 1 bit )  \
        /               \
        true            false
        |               |
        total segments  segment
        ( 24 bit )
        |
        segment

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
    | - - < - - - < - - |   <- <- <- ( index, checksum )           [ receiver have to respond with data block checksum with specified timeout, if next data block not received, final block must be empty ( \0 ) ]
    |                   |

--]]

---
--- in bits
---
---@type integer
local internal_header = 8 + -- unknown magical byte
    dreamwork.engine.NetworkHeaderSize -- header ( network id ) + unreliable

---
--- net limit - header
---
--- in bits
---
---@type integer
local max_package_size = ( ( 64 * 1024 ) - 1 ) * 8 - internal_header

---
--- ( 2 ^ segment_index_size - 1 ) * segment size = max transmittion size in kbytes
---
--- 24 bit with 1 kb segment ~= 16gb is absolute limit ( im pretty sure nobody will need more data, its more that total game size in 8 times )
---
--- in bits
---
---@type integer
local segment_index_size = 24

---
--- segment size - header
---
--- in bits
---
---@type integer
local max_segment_size = ( ( 1 * 1024 ) - 1 ) * 8 - internal_header - segment_index_size

---
--- in bytes
---
---@type integer
local size_per_segment = math_floor( max_segment_size / 8 )

---
--- in bytes
---
---@type integer
local header_free_space = math_floor( ( max_package_size - ( segment_index_size + 1 --[[ is complex message (boolean) ]] ) ) / 8 )

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

    local network_id

    if LUA_SERVER then
        network_id = engine.networkRegister( network_name )
    else
        network_id = engine.networkGetID( network_name )
    end

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

---@class dreamwork.std.Network.Transmission.Initial
---@field segments_total integer

---@class dreamwork.std.Network.Transmission.Final
---@field segments_received integer
---@field checksum integer

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
    ---@field client Player

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

        for i = outgoing_activity[ 0 ], 1, -1 do
            local thread_data = outgoing_activity[ i ]
            if time_used > thread_data.time then
                local client = thread_data.client
                if client:IsValid() then
                    coroutine.resume( thread_data.thread, false )
                else
                    dreamwork.Logger:warn( "Transmission '%s' terminated, client '%s' disconnected.", thread_data.thread, client )
                    outgoing_activity[ 0 ] = outgoing_activity[ 0 ] - 1
                    table.remove( outgoing_activity, i )
                end
            end
        end
    end )

    ---@param network dreamwork.std.Network
    ---@param client Player
    local function update_outgoing( network, client )
        local network_id = network_to_index[ network ]

        local thread = outgoing_transmissions[ client ][ network_id ]
        if thread == nil then
            error( "Failed to update outgoing transmission, thread not found", 2 )
        end

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
            time = os_clock() + network.timeout,
            client = client
        }
    end

    ---@param client Player
    ---@param network dreamwork.std.Network
    local function kill_outgoing( network, client )
        local network_id = network_to_index[ network ]

        local outgoing_thread = outgoing_transmissions[ client ][ network_id ]
        if outgoing_thread == nil then return end

        outgoing_transmissions[ client ][ network_id ] = nil

        local thread_count = outgoing_activity[ 0 ]

        for i = thread_count, 1, -1 do
            if outgoing_activity[ i ].thread == outgoing_thread then
                outgoing_activity[ 0 ] = thread_count - 1
                table.remove( outgoing_activity, i )
                break
            end
        end
    end

    local function abort_transmission( network, client )
        if not network_sending[ network ] then return end
        network_sending[ network ] = false

        kill_outgoing( network, client )

        net.Start( network_to_identifier[ network ], false )
        net.Send( client )
    end

    ---@param network dreamwork.std.Network
    ---@param client Player
    ---@param segments string[]
    ---@param total_segments integer
    ---@async
    local function complex_transmission( network, client, segments, total_segments )
        local network_name = network_to_identifier[ network ]

        network_sending[ network ] = true

        net.Start( network_name, false )

        net.WriteBool( true )
        net.WriteUInt( total_segments, segment_index_size )

        net.Send( client )

        dreamwork.Logger:info( "Sended a handshake for a new transmission, waiting for confirmation... [complex: yes, id: %d, target: %s]", network_to_index[ network ], client )

        local checksum = std.checksum.CRC32()

        local segment_checksum = 0
        local index = 0
        local segment

        ::next_segment::

        index = index + 1
        segment = segments[ index ]

        segment_checksum = crc16_digest( segment )
        checksum:update( segment )

        ::send_segment::

        net.Start( network_name, true )

        net.WriteUInt( index, segment_index_size )
        net.WriteData( segment )

        net.Send( client )

        dreamwork.Logger:debug( "Sended segment %d/%d [%d bytes, target: %s, segment checksum: 0x%x]", index, total_segments, string_len( segment ), client, segment_checksum )

        update_outgoing( network, client )

        local persisted = coroutine.yield()

        if persisted then
            if index ~= net.ReadUInt( segment_index_size ) then
                dreamwork.Logger:warn( "wrong segment index" )
                goto send_segment
            end

            if segment_checksum ~= net.ReadUInt( 16 ) then
                dreamwork.Logger:warn( "wrong segment checksum" )
                goto send_segment
            end

            dreamwork.Logger:info( "delivered segment %d/%d [%d bytes]", index, total_segments, string_len( segment ) )

            if index < total_segments then
                goto next_segment
            end

            abort_transmission( network, client )

            dreamwork.Logger:info( "transmission finished, delivered %d bytes, checksum: 0x%x", string_len( table.concat( segments ) ), checksum:digest() )
            return
        end

        dreamwork.Logger:warn( "timeout" )
        goto send_segment
    end

    ---@param network dreamwork.std.Network
    ---@param data string
    ---@param client Player
    local function transmit( network, data, client )
        print()
        dreamwork.Logger:info( "Started transmission for %s", client )

        local length = string_len( data )
        dreamwork.Logger:debug( "total size %d bytes", length )

        if header_free_space < length then
            if network_sending[ network ] then
                abort_transmission( network, client )
            end

            local segments, segment_count = string.divide( data, size_per_segment )
            dreamwork.Logger:debug( "transmitting %d segments by %d bytes", segment_count, size_per_segment )

            local outgoing_thread = coroutine.create( complex_transmission )
            outgoing_transmissions[ client ][ network_to_index[ network ] ] = outgoing_thread

            local success, err_msg = coroutine.resume( outgoing_thread, network, client, segments, segment_count )
            if success then
                network_sending[ network ] = true
            else
                error( err_msg, 2 )
            end

            return
        end

        net.Start( network_to_identifier[ network ], false )

        net.WriteBool( false )
        net.WriteData( data )

        net.Send( client )

        dreamwork.Logger:info( "transmission finished" )
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
            local thread_data = incoming_activity[ i ]
            if time_used > thread_data.time then
                coroutine.resume( thread_data.thread, false )
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
                table.remove( incoming_activity, i )
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

        net.WriteUInt( segment_index, segment_index_size )
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
        local checksum = std.checksum.CRC32()

        ---@type string[]
        local segments = {}

        ---@type integer
        local segment_checksum = 0

        ---@type string | nil
        local segment = nil

        ---@type integer
        local segment_index = 0

        ::await_response::

        local persisted, message_length, index = coroutine.yield( checksum )

        if persisted then
            if segment == nil then
                segment_index = index
            elseif index ~= segment_index then
                segments[ segment_index ] = segment
                checksum:update( segment )

                dreamwork.Logger:debug( "delivered segment %d/%d [%d bytes, checksum: 0x%x]", segment_index, total_segments, string_len( segment ), segment_checksum )

                perform_callbacks( network, segments, segment_index, total_segments )

                if index == 0 then
                    goto await_response
                end

                segment_index = index
            end

            segment = net.ReadData( math_ceil( message_length / 8 ) )
            segment_checksum = crc16_digest( segment )

            send_checksum( network, network_name, segment_index, segment_checksum )
        else
            send_checksum( network, network_name, segment_index, segment_checksum )
            dreamwork.Logger:warn( "timeout" )
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
                local success, err_msg = coroutine.resume( incoming_thread, true, message_length, net.ReadUInt( segment_index_size ) )
                if not success then
                    dreamwork.Logger:error( "Failed to resume transmission: %s", err_msg )
                    abort_receiving( network )
                end

                return true
            end

            local success, checksum = coroutine.resume( incoming_thread, true, 0, 0 )

            if success then
                ---@cast checksum dreamwork.std.checksum.CRC32
                dreamwork.Logger:debug( "Transmission finished, completing... [complex: yes, id: %d, checksum: 0x%x]", network_id, checksum:digest() )
            else
                ---@cast checksum string
                dreamwork.Logger:error( "Failed to finish transmission: %s", checksum )
            end

            abort_receiving( network )

            return true
        end

        if message_length == 0 then
            dreamwork.Logger:error( "Sender sended abort message without transmission, ignoring... [complex: yes, id: %d]", network_id )
            return false
        end

        local is_complex = net.ReadBool()
        message_length = message_length - 1

        if unreliable then
            dreamwork.Logger:error( "Server attempted to send a data segment without a handshake, disconnecting... [complex: %s, id: %d]", is_complex and "yes" or "no", network_id )
            return true
        end

        if is_complex then
            if network_receiving[ network ] then
                abort_receiving( network )
            end

            local total_segments = net.ReadUInt( segment_index_size )
            message_length = message_length - segment_index_size

            dreamwork.Logger:debug( "Received a handshake for a new transmission, preparing to receive... [complex: yes, id: %d, segments: %d]", network_id, total_segments )

            local incoming_thread = coroutine.create( complex_receiving )
            incoming_transmissions[ network_id ] = incoming_thread

            local success, err_msg = coroutine.resume( incoming_thread, network, total_segments )
            if success then
                network_receiving[ network ] = true
            else
                dreamwork.Logger:error( "Failed to resume transmission: %s", err_msg )
            end

            return true
        end

        dreamwork.Logger:info( "Received a handshake for a new transmission, preparing to receive... [complex: %s, id: %d]", is_complex and "yes" or "no", network_id )
        perform_callbacks( network, { [ 0 ] = 1, net.ReadData( math_ceil( message_length / 8 ) ) }, 1, 1 )

        return true
    end, 2 )

end

if std.DEVELOPER == 0 then return end

local n = NetworkClass( "test", LUA_CLIENT )

if SERVER then

    concommand.Add( "testss", function( pl )
        n:transmit( function( self, writer )
            local data = file.Read( "moff3.jpg", "GAME" )
            dreamwork.Logger:info( "sending: %d bytes", #data )
            writer:writeCountedString( data, 32 )
        end, pl )
    end )

else

    local start_time

    local fraction = 0

    local material

    local time_history = { [ 0 ] = 0 }

    local speed_str = ""

    local total_seg, cur_seg = 1, 1
    local last_segment_time = 0

    timer.Create( "speeddy", 1, 0, function()
        local history_size = time_history[ 0 ]

        if history_size > 1 then
            local average = ( time_history[ history_size - 1 ] + time_history[ history_size ] ) * 0.5
            speed_str = string.format( "per segment: %.2fs\nremaining: %.2fs\n%.2fkb/s", average, average * ( total_seg - cur_seg ), ( ( 1 / average ) * size_per_segment ) / 125 )
        end
    end )

    n:attach( function( self, reader, index, total )
        total_seg, cur_seg = total, index

        if index == 1 then
            start_time = os.clock()
        end

        local time = os.clock()

        local history_size = time_history[ 0 ] + 1
        time_history[ history_size ] = time - last_segment_time
        time_history[ 0 ] = history_size

        last_segment_time = time

        fraction = math.clamp( index / total, 0, 1 )

        -- dreamwork.Logger:debug( "received segment %d/%d, took %f s", index, total, std.time.tick() )

        if index == total then
            local data = reader:readCountedString( 32 ) or ""
            dreamwork.Logger:info( "transmission finished, received %d bytes, took %f s", #data, os.clock() - start_time )

            local file_name = std.uuid.v7() .. ".png"

            file.Write( file_name, data )

            material = Material( "data/" .. file_name )
        end
    end )

    hook.Add( "HUDPaint", "YEEE", function()
        if fraction == 0 then return end
        local x = ScrW() - 512

        surface.SetDrawColor( 33, 33, 33, 200 )
        surface.DrawRect( x, 0, 256, 320 )

        surface.DrawRect( x + 16, 16, 224, 32 )
        surface.DrawRect( x + 16, 64, 224, 240 )

        if material ~= nil then
            surface.SetDrawColor( 255, 255, 255 )
            surface.SetMaterial( material )
            surface.DrawTexturedRect( x + 16, 64, 224, 240 )
        end

        surface.SetDrawColor( 100, 100, 255 )
        surface.DrawRect( x + 16, 16, 224 * fraction, 32 )

        draw.DrawText( speed_str, "DermaLarge", x, 320, color_white, TEXT_ALIGN_LEFT )

        -- surface.SetFont( "DermaLarge" )
        -- surface.SetTextColor( 255, 255, 255, 255 )
        -- surface.SetTextPos( x + 32, 32 )
        -- surface.DrawText( speed_str )
    end )

end

engine.hookCatch( "IncomingNetworkMessage", function( network_id, unreliable, message_length )
    dreamwork.Logger:debug( "Received message, id: %d, unreliable: %s, message_length: %d", network_id, unreliable and "true" or "false", message_length )
end, 1 )
