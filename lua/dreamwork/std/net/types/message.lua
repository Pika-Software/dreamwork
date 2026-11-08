local dreamwork_engine = dreamwork.engine
local dreamwork_Logger = dreamwork.Logger

local dreamwork_getUpTime = dreamwork.getUpTime
local exceptions_call = dreamwork.exceptions.call

local engine_hook = dreamwork_engine.hook

local engine_console = dreamwork_engine.console
local console_commandRun = engine_console.commandRun
local console_commandRegister = engine_console.commandRegister

---@class dreamwork.std
local std = dreamwork.std

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local raw = std.raw
local raw_pairs = raw.pairs
local raw_index = raw.index
local raw_tonumber = raw.tonumber

local math = std.math
local math_max = math.max
local math_floor = math.floor

local string = std.string
local string_sub = string.sub
local string_byte = string.byte
local string_char = string.char
local string_format = string.format

local table = std.table
local table_concat = table.concat

local base64 = std.base64
local base64_encode = base64.encode
local base64_decode = base64.decode
local base64_validate = base64.validate

local class = std.class

local isTable = std.isTable
local isString = std.isString

local Emitter = std.Emitter
local BinaryReader = std.BinaryReader
local BinaryWriter = std.BinaryWriter

local LUA_SERVER = std.LUA_SERVER


--[[

        Message Transport

    Messages travel as hidden console commands, so they work where the `net` library doesn't:
    between the menu and the client states, and between the client and the server.

        client -> server    `RunConsoleCommand`, the client forwards unknown commands to the server
        server -> client    `Player:ConCommand`
        client -> menu      `RunConsoleCommand` into the shared console
        menu   -> client    `RunConsoleCommand` into the shared console

    Every side registers `dreamwork.inet.<receiving realm>.<name>`, the command names of
    the other realms are unknown to it, so the console passes them through to their owner.

        Packet Layout ( url-safe base64 of )

        sender realm ( 8 bit ), transfer id ( 8 bit ), index ( 16 bit ), count ( 16 bit ), data

    The whole message is built before sending and assembled completely before the handlers run,
    packets of one transfer arrive in order ( console commands are reliable ), a gap drops the transfer.

        Limits ( measured )

    The console line is limited to 510 characters ( measured both ways ), longer lines are refused by the engine:
    the sending client prints `Command too long... ignoring!`, the receiving client prints
    `CCommand::Tokenize: Encountered command which overflows the tokenizer buffer.. Skipping!`.

    The receiving command buffer holds ~8 kb per frame, commands over it are dropped ( the engine only prints
    `Cbuf_AddText: buffer overflow`, Lua is never told ),
    so packets are queued and paced by a per-frame byte budget.

    The client can run at a much lower frame rate than the server tick rate ( or hitch for seconds ),
    so the server also keeps at most `ack_window` packets in flight per player,
    the client acknowledges the received packets once per frame with `dreamwork.inet.ack <count>`.

    Unquoted arguments starting with `//` are eaten as comments, so the payload is always quoted.

--]]

--- The Lua state a message is sent from or to.
---
---@alias dreamwork.std.Message.Realm "server" | "client" | "menu"

--- The realm codes of the packet header to the realms.
---
---@type table<integer, dreamwork.std.Message.Realm>
local code2realm = {
    [ 0 ] = "server",
    [ 1 ] = "client",
    [ 2 ] = "menu"
}

--- The realms to the realm codes of the packet header.
---
---@type table<dreamwork.std.Message.Realm, integer>
local realm2code = {
    server = 0,
    client = 1,
    menu = 2
}

--- The realm of this Lua state.
---
---@type dreamwork.std.Message.Realm
local local_realm

if std.LUA_CLIENT then
    local_realm = "client"
elseif LUA_SERVER then
    local_realm = "server"
else
    local_realm = "menu"
end

local local_realm_code = realm2code[ local_realm ]

--- The realms that are allowed to send messages to this realm.
---
---@type table<integer, boolean>
local allowed_senders

if local_realm == "client" then
    allowed_senders = { [ 0 ] = true, [ 2 ] = true }
else
    allowed_senders = { [ 1 ] = true }
end

---
--- sender realm, transfer id, index and count
---
--- in bytes
---
---@type integer
local header_size = 6

---
--- the engine keeps lines of up to 510 characters ( measured both ways ), 10 are left for safety
---
--- in bytes
---
---@type integer
local max_line_length = 500

---
--- the receiving command buffer holds ~8 kb per frame,
--- the server budget is per player, the client and menu share one console, so their budget is global
---
--- in bytes
---
---@type integer
local frame_budget = LUA_SERVER and (4 * 1024) or (3 * 1024)

---
--- the count field is 16 bit
---
--- in packets
---
---@type integer
local max_packet_count = 0xFFFF

---
--- the packets the server keeps unacknowledged per player, must fit into the client command buffer
---
--- in packets
---
---@type integer
local ack_window = math_floor( 6000 / max_line_length )

---
--- the in-flight packets are forgotten after it, a dropped packet is never acknowledged
---
--- in seconds
---
---@type number
local ack_timeout = 1.0

--- The command the client acknowledges the packets of the server with.
---
---@type string
local ack_command = "dreamwork.inet.ack"

--- The packets are url-safe base64, so they never contain quotes or console separators.
---
---@type dreamwork.std.base64.Options
local base64_options = { variant = "urlsafe" }

--- The help text of the registered commands.
local description = "Internal dreamwork message channel, do not use."

--- [SHARED AND MENU]
---
--- A named channel that sends data through hidden console commands,
--- so it also works between the menu and the client states, where the `net` library doesn't.
---
--- The server sends to the client state of players, the client sends to the server or the menu,
--- the menu sends to the client. The data is split into url-safe base64 packets of one console
--- line each, paced by a per-frame byte budget, and is delivered to the handlers only when complete.
---
--- It is slow ( ~45 KiB/s with a 20 fps client ) and has no checksum, so prefer `std.Network`
--- for large data between the server and the client.
---
--- Every realm must create the message with the same name to receive it,
--- creating a message with the name of an existing one returns the existing object.
---
--- Messages to the same target are queued and sent in order.
---
---@class dreamwork.std.Message : dreamwork.std.Object
---@field __class dreamwork.std.MessageClass
---@field name string The name of the message, read-only.
---@field receiver boolean `true` if the message accepts incoming data, `false` by default.
---@field timeout number The number of seconds without a packet after which an incomplete incoming transfer is dropped, `15` by default, at least `1`.
---@field limit integer The maximum size of an incoming message in bytes, `256` KiB by default, `0` rejects everything.
local Message = class.base( "Message", true )

--- [SHARED AND MENU]
---
--- The class of `Message`, call it to create or get a message.
---
---@class dreamwork.std.MessageClass : dreamwork.std.Message, dreamwork.std.Class
---@field __base dreamwork.std.Message
---@overload fun( name: string, can_receive: boolean? ): dreamwork.std.Message
local MessageClass = class.create( Message )
std.Message = MessageClass

--- Called when a message is fully received.
---
--- `sender` is the player on the server and `nil` on the client and menu,
--- `realm` is the realm the message claims to come from.
---
---@alias dreamwork.std.Message.ReceiveFn fun( message: dreamwork.std.Message, reader: dreamwork.std.BinaryReader, sender: garrysmod.Player | nil, realm: dreamwork.std.Message.Realm )

--- Called when an outgoing message is finished.
---
--- `success` is `true` when the last packet is handed to the engine, the delivery is not confirmed,
--- `false` if it was aborted or the target player left.
---
---@alias dreamwork.std.Message.FinishFn fun( message: dreamwork.std.Message, success: boolean, target: garrysmod.Player | dreamwork.std.Message.Realm )

--- The names of the messages.
---
---@type table<dreamwork.std.Message, string>
local message_names = {}

--- The `receiver` values of the messages.
---
---@type table<dreamwork.std.Message, boolean>
local receive_allowed = {}

--- The `timeout` values of the messages, in seconds.
---
---@type table<dreamwork.std.Message, number>
local timeouts = {}

--- The `limit` values of the messages, in bytes.
---
---@type table<dreamwork.std.Message, integer>
local limits = {}

--- The ID of the last started transfer of every message, wraps at 256.
---
---@type table<dreamwork.std.Message, integer>
local transfer_counters = {}

--- Message `"receive"` handlers.
local events = Emitter( "Message" )

--- The messages by their names.
---
---@type table<string, dreamwork.std.Message>
local messages = {}

--- The receiving command name to the message.
---
---@type table<string, dreamwork.std.Message>
local commands = {}

--- [SHARED AND MENU]
---
--- Attaches a handler that is called when a message is fully received.
---
--- If the handler is already attached, it will not be attached twice.
---
---@param handler dreamwork.std.Message.ReceiveFn | dreamwork.std.Hook | dreamwork.std.Event The callback or callable object.
function Message:attach( handler )
    events:attach( self, "receive", handler )
end

--- [SHARED AND MENU]
---
--- Attaches a handler that automatically detaches
--- itself right before being invoked, so it only ever runs once.
---
---@param handler dreamwork.std.Message.ReceiveFn | dreamwork.std.Hook | dreamwork.std.Event The callback or callable object.
function Message:once( handler )
    events:once( self, "receive", handler )
end

--- [SHARED AND MENU]
---
--- Detaches a previously attached receive handler.
---
---@param handler dreamwork.std.Message.ReceiveFn | dreamwork.std.Hook | dreamwork.std.Event The exact handler reference.
---@return boolean removed `true` if the handler was attached.
function Message:detach( handler )
    return events:detach( self, "receive", handler )
end

--- [SHARED AND MENU]
---
--- Removes every receive handler.
---
function Message:clear()
    events:clear( self, "receive" )
end

--- [SHARED AND MENU]
---
--- Waits for the next fully received message.
---
---@return dreamwork.std.Message message The message.
---@return dreamwork.std.BinaryReader reader The reader of the message.
---@return garrysmod.Player | nil sender The sender, `nil` on the client and menu.
---@return dreamwork.std.Message.Realm realm The realm the message claims to come from.
---@async
function Message:await()
    return events:await( self, "receive" )
end

--- Returns the console command that delivers the message to the realm.
---
---@param realm dreamwork.std.Message.Realm The receiving realm.
---@param name string The name of the message.
---@return string command
local function command_name( realm, name )
    return "dreamwork.inet." .. realm .. "." .. name
end

do

    ---@param name string The name of the message.
    ---@return dreamwork.std.Message | nil object The existing message with this name.
    ---@protected
    function MessageClass:__new( name )
        return messages[ name ]
    end

    ---@return string
    ---@protected
    function Message:__represent()
        return string_format( "Message: %p [%s]", self, message_names[ self ] )
    end

    ---@param name string The name of the message, must be the same in every realm.
    ---@param can_receive boolean? `true` if the message accepts incoming data, `false` by default.
    ---@protected
    function Message:__init( name, can_receive )
        message_names[ self ] = name
        receive_allowed[ self ] = can_receive == true
        timeouts[ self ] = 15.0
        limits[ self ] = 256 * 1024
        transfer_counters[ self ] = 0

        messages[ name ] = self

        local command = command_name( local_realm, name )
        console_commandRegister( command, description, 16 --[[ FCVAR_HIDDEN ]] )
        commands[ command ] = self
    end

    ---@type table<string, table<dreamwork.std.Message, any>>
    local key_to_table = {
        name = message_names,
        receiver = receive_allowed,
        timeout = timeouts,
        limit = limits
    }

    ---@param key string
    ---@protected
    function Message:__index( key )
        local tbl = key_to_table[ key ]
        if tbl ~= nil then
            return tbl[ self ]
        end

        return raw_index( Message, key )
    end

    ---@param key string
    ---@param value any
    ---@protected
    function Message:__newindex( key, value )
        if key == "receiver" then
            receive_allowed[ self ] = value == true
        elseif key == "timeout" then
            timeouts[ self ] = math_max( raw_tonumber( value, 10 ) or 15.0, 1.0 )
        elseif key == "limit" then
            limits[ self ] = math_max( math_floor( raw_tonumber( value, 10 ) or 0 ), 0 )
        else
            error( "attempt to modify read-only object", 2 )
        end
    end

end

--- Formats the player or the realm for the log.
---
---@param target garrysmod.Player | dreamwork.std.Message.Realm
---@return string
local function target_tostring( target )
    if isString( target ) then
        ---@cast target dreamwork.std.Message.Realm
        return target
    end

    ---@cast target garrysmod.Player
    return string_format( "%s [%s]", target:Nick(), target:SteamID() )
end

--[[

    Outgoing

--]]

--- An outgoing transfer, split into packets up front.
---
---@class dreamwork.std.Message.Outgoing
---@field message dreamwork.std.Message The message of the transfer.
---@field target garrysmod.Player | dreamwork.std.Message.Realm The target player on the server, the target realm otherwise.
---@field command string The receiving console command.
---@field packets string[] The encoded packets, the sent ones are dropped.
---@field count integer The number of packets.
---@field sent integer The number of sent packets.
---@field callback dreamwork.std.Message.FinishFn | nil The finish callback of `Message:send`.

--- The queues of outgoing transfers, keyed by the target player on the server or the target realm.
---
---@type table<garrysmod.Player | dreamwork.std.Message.Realm, dreamwork.std.Message.Outgoing[]>
local queues = {}
gc_setTableRules( queues, true, false )

--- The bytes sent in this frame, keyed like `queues` on the server, `shared_key` on the client and menu.
---
---@type table<garrysmod.Player | string, integer>
local spent = {}
gc_setTableRules( spent, true, false )

--- The budget key of the client and menu, they share one console.
local shared_key = "shared"

--- Calls the finish callback of the transfer.
---
---@param transfer dreamwork.std.Message.Outgoing
---@param success boolean
local function outgoing_finish( transfer, success )
    local callback = transfer.callback
    if callback ~= nil then
        exceptions_call( callback, transfer.message, success, transfer.target )
    end
end

--- Checks if the player is still connected, realms are always valid.
---
---@param target garrysmod.Player | dreamwork.std.Message.Realm
---@return boolean
local function target_valid( target )
    ---@cast target garrysmod.Player
    return isString( target ) or target:IsValid()
end

--- Drops the queue of the target, every transfer in it fails.
---
---@param key garrysmod.Player | dreamwork.std.Message.Realm
local function queue_flush( key )
    local queue = queues[ key ]
    if queue == nil then return end

    queues[ key ] = nil

    for i = 1, #queue, 1 do
        outgoing_finish( queue[ i ], false )
    end
end

--- The unacknowledged packets, keyed by the target player.
---
---@type table<garrysmod.Player, integer>
local inflight = {}
gc_setTableRules( inflight, true, false )

--- The last time the in-flight packets of the target player made progress.
---
---@type table<garrysmod.Player, number>
local inflight_times = {}
gc_setTableRules( inflight_times, true, false )

--- Runs the receiving command with the packet, on the server it is counted as in flight.
---
---@type fun( transfer: dreamwork.std.Message.Outgoing, packet: string )
local packet_send

if LUA_SERVER then

    function packet_send( transfer, packet )
        local target = transfer.target
        ---@cast target garrysmod.Player

        local count = inflight[ target ] or 0
        if count == 0 then
            inflight_times[ target ] = dreamwork_getUpTime()
        end

        inflight[ target ] = count + 1

        target:ConCommand( transfer.command .. " \"" .. packet .. "\"" )
    end

else

    function packet_send( transfer, packet )
        console_commandRun( transfer.command, packet )
    end

end

--- Sends the queued packets of the target within the frame budget.
---
---@param key garrysmod.Player | dreamwork.std.Message.Realm
local function queue_pump( key )
    local queue = queues[ key ]
    if queue == nil then return end

    if not target_valid( key ) then
        queue_flush( key )
        return
    end

    local budget_key = LUA_SERVER and key or shared_key

    ::transfer_pump::

    local transfer = queue[ 1 ]
    local used = spent[ budget_key ] or 0

    while used < frame_budget and transfer.sent < transfer.count and (inflight[ key ] or 0) < ack_window do
        local index = transfer.sent + 1
        local packet = transfer.packets[ index ]

        transfer.packets[ index ] = nil
        transfer.sent = index

        packet_send( transfer, packet )
        used = used + #transfer.command + #packet + 3
    end

    -- callbacks can send more, so the budget is stored before them
    spent[ budget_key ] = used

    if transfer.sent ~= transfer.count then return end

    local length = #queue

    for i = 1, length - 1, 1 do
        queue[ i ] = queue[ i + 1 ]
    end

    queue[ length ] = nil

    if length == 1 and queues[ key ] == queue then
        queues[ key ] = nil
    end

    outgoing_finish( transfer, true )

    if queue[ 1 ] ~= nil and queues[ key ] == queue then
        goto transfer_pump
    end
end

--- Splits the data into packets and queues them to the target.
---
---@param message dreamwork.std.Message
---@param data string
---@param target garrysmod.Player | dreamwork.std.Message.Realm The queue key.
---@param realm dreamwork.std.Message.Realm The receiving realm.
---@param callback dreamwork.std.Message.FinishFn | nil
local function transmit( message, data, target, realm, callback )
    local command = command_name( realm, message_names[ message ] )

    -- every 4 characters of base64 carry 3 bytes, the line is `command "packet"`
    local packet_size = math_floor( (max_line_length - #command - 3) / 4 ) * 3 - header_size
    if packet_size < 1 then
        error( string_format( "Message name '%s' is too long.", message_names[ message ] ), 3 )
    end

    local data_length = #data

    local count = math_max( math_floor( (data_length + packet_size - 1) / packet_size ), 1 )
    if count > max_packet_count then
        error( string_format( "Message '%s' data is too large ( %d bytes, max %d ).", message_names[ message ], data_length, max_packet_count * packet_size ), 3 )
    end

    local transfer_id = (transfer_counters[ message ] + 1) % 256
    transfer_counters[ message ] = transfer_id

    local count_hi, count_lo = math_floor( count / 256 ), count % 256

    ---@type string[]
    local packets = {}

    for index = 0, count - 1, 1 do
        local offset = index * packet_size

        local header = string_char( local_realm_code, transfer_id, math_floor( index / 256 ), index % 256, count_hi, count_lo )
        packets[ index + 1 ] = base64_encode( header .. string_sub( data, offset + 1, offset + packet_size ), base64_options )
    end

    ---@type dreamwork.std.Message.Outgoing
    local transfer = {
        message = message,
        target = target,
        command = command,
        packets = packets,
        count = count,
        sent = 0,
        callback = callback
    }

    local queue = queues[ target ]
    if queue == nil then
        queues[ target ] = { transfer }
    else
        queue[ #queue + 1 ] = transfer
    end

    queue_pump( target )
end

--- Resolves the target of `Message:send` and transmits to every player or the realm.
---
---@param message dreamwork.std.Message
---@param data string
---@param target ( garrysmod.Player | garrysmod.Player[] | dreamwork.std.Message.Realm )?
---@param callback dreamwork.std.Message.FinishFn | nil
local function transmit_to( message, data, target, callback )
    if LUA_SERVER then
        if target == nil then
            error( "Target player(s) are required on the server.", 3 )
        end

        if isTable( target ) then
            ---@cast target garrysmod.Player[]
            for i = 1, #target, 1 do
                transmit( message, data, target[ i ], "client", callback )
            end

            return
        end

        ---@cast target garrysmod.Player
        transmit( message, data, target, "client", callback )
        return
    end

    if local_realm == "menu" then
        transmit( message, data, "client", "client", callback )
        return
    end

    ---@cast target dreamwork.std.Message.Realm | nil
    if target == nil then
        target = "server"
    end

    if target ~= "server" and target ~= "menu" then
        error( string_format( "Unknown target realm '%s', the client can send to 'server' or 'menu'.", target ), 3 )
    end

    transmit( message, data, target, target, callback )
end

--- [SHARED AND MENU]
---
--- Sends the data to the target.
---
--- The data is split into console command packets that are paced over frames,
--- the ~8 kb per frame console limit makes it slow ( ~45 kb/s with a 20 fps client ), so prefer `std.Network`
--- for large data between the server and the client.
---
--- The server sends to the client state of the target players,
--- the client sends to `"server"` ( default ) or `"menu"`, the menu sends to the client.
---
--- Messages to the same target are queued and sent in order.
---
---@param data string The data to send.
---@param target ( garrysmod.Player | garrysmod.Player[] | dreamwork.std.Message.Realm )? The target player(s) on the server, the target realm on the client, ignored in the menu.
---@param callback dreamwork.std.Message.FinishFn? The callback that is called when the last packet is handed to the engine, or the target left.
function Message:send( data, target, callback )
    transmit_to( self, data, target, callback )
end

--- [SHARED AND MENU]
---
--- Builds the data with a binary writer and sends it to the target.
---
---@param fn fun( message: dreamwork.std.Message, writer: dreamwork.std.BinaryWriter ) The function that writes the data.
---@param target ( garrysmod.Player | garrysmod.Player[] | dreamwork.std.Message.Realm )? The target player(s) on the server, the target realm on the client, ignored in the menu.
---@param callback dreamwork.std.Message.FinishFn? The callback that is called when the last packet is handed to the engine, or the target left.
function Message:transmit( fn, target, callback )
    local writer = BinaryWriter()
    fn( self, writer )
    transmit_to( self, writer:compile(), target, callback )
end

--- Returns the queue key of the target, the default realm if it is `nil` outside the server.
---
---@param target ( garrysmod.Player | dreamwork.std.Message.Realm )?
---@return garrysmod.Player | dreamwork.std.Message.Realm | nil
local function target_key( target )
    if LUA_SERVER or target ~= nil then
        return target
    end

    if local_realm == "menu" then
        return "client"
    end

    return "server"
end

--- [SHARED AND MENU]
---
--- Cancels the outgoing transfers of this message to the target, the packets already sent are not recalled.
---
---@param target ( garrysmod.Player | dreamwork.std.Message.Realm )? The target player on the server, the target realm on the client, ignored in the menu.
---@return boolean cancelled `true` if anything was cancelled.
function Message:abort( target )
    local key = target_key( target )
    if key == nil then return false end

    local queue = queues[ key ]
    if queue == nil then return false end

    ---@type dreamwork.std.Message.Outgoing[]
    local cancelled = {}

    local length = 0

    for i = 1, #queue, 1 do
        local transfer = queue[ i ]
        if transfer.message == self then
            cancelled[ #cancelled + 1 ] = transfer
        else
            length = length + 1
            queue[ length ] = transfer
        end
    end

    for i = #queue, length + 1, -1 do
        queue[ i ] = nil
    end

    if length == 0 then
        queues[ key ] = nil
    end

    for i = 1, #cancelled, 1 do
        outgoing_finish( cancelled[ i ], false )
    end

    return cancelled[ 1 ] ~= nil
end

--- [SHARED AND MENU]
---
--- Checks if the message has queued outgoing packets to the target.
---
---@param target ( garrysmod.Player | dreamwork.std.Message.Realm )? The target player on the server, the target realm on the client, ignored in the menu.
---@return boolean is_sending `true` if a transfer of this message to the target is queued.
---@nodiscard
function Message:isSending( target )
    local queue = queues[ target_key( target ) ]
    if queue == nil then return false end

    for i = 1, #queue, 1 do
        if queue[ i ].message == self then
            return true
        end
    end

    return false
end

--[[

    Incoming

--]]

--- An incomplete incoming transfer.
---
---@class dreamwork.std.Message.Incoming
---@field id integer The transfer ID, `[0, 255]`.
---@field count integer The number of packets.
---@field next integer The zero-based index of the expected packet.
---@field chunks string[] The received data chunks.
---@field size integer The number of received bytes.
---@field activity number The uptime of the last received packet, for the timeout.

--- The incomplete incoming transfers, keyed by the sender player on the server or the sender realm.
---
---@type table<dreamwork.std.Message, table<garrysmod.Player | dreamwork.std.Message.Realm, dreamwork.std.Message.Incoming>>
local incoming = {}
gc_setTableRules( incoming, true, false )

--- The number of incomplete incoming transfers over all messages, the timeout check is skipped at `0`.
---
---@type integer
local incoming_count = 0

--- Drops the incomplete transfer from the sender.
---
---@param message dreamwork.std.Message
---@param key garrysmod.Player | dreamwork.std.Message.Realm
local function incoming_remove( message, key )
    local states = incoming[ message ]
    if states == nil or states[ key ] == nil then return end

    states[ key ] = nil
    incoming_count = incoming_count - 1
end

--- [SHARED AND MENU]
---
--- Checks if the message is receiving data from the sender.
---
---@param sender ( garrysmod.Player | dreamwork.std.Message.Realm )? The sender player on the server, the sender realm on the client, ignored in the menu.
---@return boolean is_receiving `true` if an incomplete transfer from the sender is in progress.
---@nodiscard
function Message:isReceiving( sender )
    local states = incoming[ self ]
    return states ~= nil and states[ target_key( sender ) ] ~= nil
end

--- The packets received from the server since the last acknowledgement.
---
---@type integer
local unacknowledged = 0

--- Decodes an incoming packet and assembles the transfer, the handlers are called when it is complete.
---
---@param message dreamwork.std.Message
---@param sender garrysmod.Player | nil The sender player on the server, `nil` otherwise.
---@param encoded string The base64 packet.
local function message_receive( message, sender, encoded )
    if not base64_validate( encoded, base64_options ) then
        dreamwork_Logger:debug( "Message '%s' received a malformed packet.", message_names[ message ] )
        return
    end

    local packet = base64_decode( encoded, base64_options )
    if #packet < header_size then
        dreamwork_Logger:debug( "Message '%s' received a truncated packet.", message_names[ message ] )
        return
    end

    local realm_code, transfer_id, index_hi, index_lo, count_hi, count_lo = string_byte( packet, 1, header_size )

    if realm_code == 0 and local_realm == "client" then
        unacknowledged = unacknowledged + 1
    end

    if not allowed_senders[ realm_code ] then
        dreamwork_Logger:debug( "Message '%s' received a packet from the unexpected realm #%d.", message_names[ message ], realm_code )
        return
    end

    local realm = code2realm[ realm_code ]

    ---@type garrysmod.Player | dreamwork.std.Message.Realm
    local key = sender or realm

    local index = index_hi * 256 + index_lo
    local count = count_hi * 256 + count_lo

    local states = incoming[ message ]
    if states == nil then
        states = {}
        gc_setTableRules( states, true, false )
        incoming[ message ] = states
    end

    ---@type dreamwork.std.Message.Incoming | nil
    local state = states[ key ]

    if index == 0 then
        if state ~= nil then
            dreamwork_Logger:debug( "Receiving #%d of message '%s' from %s was replaced by #%d.", state.id, message_names[ message ], target_tostring( key ), transfer_id )
            incoming_remove( message, key )
            state = nil
        end

        if not receive_allowed[ message ] then
            dreamwork_Logger:warn( "Message '%s' is not receiving, %s tried to send to it.", message_names[ message ], target_tostring( key ) )
            return
        end

        local packet_size = #packet - header_size

        if count == 0 or (count > 1 and (count - 1) * packet_size > limits[ message ]) then
            dreamwork_Logger:warn( "Message '%s' rejected %d packets from %s, the limit is %d bytes.", message_names[ message ], count, target_tostring( key ), limits[ message ] )
            return
        end

        if count == 1 then
            if packet_size > limits[ message ] then
                dreamwork_Logger:warn( "Message '%s' rejected %d bytes from %s, the limit is %d bytes.", message_names[ message ], packet_size, target_tostring( key ), limits[ message ] )
                return
            end

            if events:count( message, "receive" ) == 0 then
                dreamwork_Logger:warn( "Message '%s' received %d bytes, but has no handlers attached.", message_names[ message ], packet_size )
                return
            end

            events:emit( message, "receive", message, BinaryReader( string_sub( packet, header_size + 1 ) ), sender, realm )
            return
        end

        ---@type dreamwork.std.Message.Incoming
        state = {
            id = transfer_id,
            count = count,
            next = 0,
            chunks = {},
            size = 0,
            activity = 0
        }

        states[ key ] = state
        incoming_count = incoming_count + 1
    elseif state == nil then
        -- the start was dropped or rejected
        return
    end

    if state.id ~= transfer_id or state.next ~= index or state.count ~= count then
        dreamwork_Logger:debug( "Receiving #%d of message '%s' from %s lost packet %d.", state.id, message_names[ message ], target_tostring( key ), state.next )
        incoming_remove( message, key )
        return
    end

    local chunk = string_sub( packet, header_size + 1 )
    local size = state.size + #chunk

    if size > limits[ message ] then
        dreamwork_Logger:warn( "Message '%s' rejected more than %d bytes from %s.", message_names[ message ], limits[ message ], target_tostring( key ) )
        incoming_remove( message, key )
        return
    end

    index = index + 1

    state.chunks[ index ] = chunk
    state.size = size
    state.next = index
    state.activity = dreamwork_getUpTime()

    if index ~= count then return end

    incoming_remove( message, key )

    if events:count( message, "receive" ) == 0 then
        dreamwork_Logger:warn( "Message '%s' received %d bytes, but has no handlers attached.", message_names[ message ], size )
        return
    end

    events:emit( message, "receive", message, std.BinaryReader( table_concat( state.chunks, "", 1, count ) ), sender, realm )
end

if LUA_SERVER then
    console_commandRegister( ack_command, description, 16 --[[ FCVAR_HIDDEN ]] )
end

engine_hook.catch( "dreamwork.console.command.execute", "net.message.class", function( sender, name, args )
    local message = commands[ name ]
    if message == nil then
        if LUA_SERVER and name == ack_command and sender ~= nil then
            local count = inflight[ sender ]
            local acknowledged = raw_tonumber( args[ 1 ], 10 )

            -- `> 0` also rejects nan
            if count ~= nil and acknowledged ~= nil and acknowledged > 0 then
                inflight[ sender ] = math_max( count - math_floor( acknowledged ), 0 )
                inflight_times[ sender ] = dreamwork_getUpTime()
                queue_pump( sender )
            end

            return true
        end

        return nil
    end

    local encoded = args[ 1 ]
    if encoded ~= nil then
        message_receive( message, LUA_SERVER and sender or nil, encoded )
    end

    return true
end, -1000 )

--- The reusable list of queue keys pumped in `Think`.
---
---@type ( garrysmod.Player | dreamwork.std.Message.Realm )[]
local pump_keys = {}

engine_hook.catch( "Think", "net.message.class", function()
    for key in raw_pairs( spent ) do
        spent[ key ] = nil
    end

    -- callbacks can queue to new targets, so `queues` is not modified while iterating
    local key_count = 0

    for key in raw_pairs( queues ) do
        key_count = key_count + 1
        pump_keys[ key_count ] = key
    end

    for i = 1, key_count, 1 do
        local key = pump_keys[ i ]
        pump_keys[ i ] = nil
        queue_pump( key )
    end

    local now = dreamwork_getUpTime()

    if LUA_SERVER then
        for target, count in raw_pairs( inflight ) do
            if not target:IsValid() then
                inflight[ target ] = nil
            elseif count ~= 0 and (now - inflight_times[ target ]) > ack_timeout then
                -- a dropped packet is never acknowledged, the window is reopened
                dreamwork_Logger:debug( "Message packets to %s were not acknowledged in time.", target_tostring( target ) )
                inflight[ target ] = 0
            end
        end
    elseif unacknowledged ~= 0 then
        console_commandRun( ack_command, string_format( "%d", unacknowledged ) )
        unacknowledged = 0
    end

    if incoming_count == 0 then return end

    for message, states in raw_pairs( incoming ) do
        local timeout = timeouts[ message ]

        for key, state in raw_pairs( states ) do
            if not target_valid( key ) or (now - state.activity) > timeout then
                dreamwork_Logger:debug( "Receiving #%d of message '%s' from %s timed out.", state.id, message_names[ message ], target_tostring( key ) )
                incoming_remove( message, key )
            end
        end
    end
end )
