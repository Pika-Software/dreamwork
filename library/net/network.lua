---@meta _

---@class garrysmod.net
local glua_net = {}

---@class Network : Object
---@field __class NetworkClass
---@field id integer The engine ID of the network.
---@field name string The name of the network.
---@field receiver boolean `true` if the network accepts incoming messages.
---@field timeout number The number of seconds without any progress after which a transfer is aborted.
---@field window integer The maximum number of segments in flight.
---@field segment integer The size of outgoing segments in bytes.
---@field limit integer The maximum size of an incoming message in bytes.
local __Network = {}

---@class NetworkClass : Network, Class
---@field __base Network
---@overload fun( name: string, can_receive: boolean? ): Network
Network = {}

---@alias Network.ReceiveFn fun( network: Network, reader: BinaryReader, sender: garrysmod.Player | nil )
---@alias Network.ProgressFn fun( network: Network, peer: garrysmod.Player | nil, is_outgoing: boolean, done_bytes: integer, total_bytes: integer )
---@alias Network.StreamFn fun( network: Network, sender: garrysmod.Player | nil, chunk: string | nil, offset: integer, total: integer, success: boolean | nil )
---@alias Network.FinishFn fun( network: Network, success: boolean, peer: garrysmod.Player | nil )

--- [SHARED]
---
--- Attaches a handler that is called when a message is fully received.
---
--- If the handler is already attached, it will not be attached twice.
---
---@param handler Network.ReceiveFn | Hook | Event The callback or callable object.
function __Network:attach(handler) end

--- [SHARED]
---
--- Attaches a handler that automatically detaches
--- itself right before being invoked, so it only ever runs once.
---
---@param handler Network.ReceiveFn | Hook | Event The callback or callable object.
function __Network:once(handler) end

--- [SHARED]
---
--- Detaches a previously attached receive handler.
---
---@param handler Network.ReceiveFn | Hook | Event The exact handler reference.
---@return boolean removed `true` if the handler was attached.
function __Network:detach(handler) end

--- [SHARED]
---
--- Removes every receive handler.
---
function __Network:clear() end

--- [SHARED]
---
--- Waits for the next fully received message.
---
---@return Network network The network.
---@return BinaryReader reader The reader of the message.
---@return garrysmod.Player | nil sender The sender, `nil` on the client.
---@async
function __Network:await() end

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
---@param handler Network.StreamFn | Hook | Event The callback or callable object.
function __Network:stream(handler) end

--- [SHARED]
---
--- Detaches a previously attached stream handler.
---
---@param handler Network.StreamFn | Hook | Event The exact handler reference.
---@return boolean removed `true` if the handler was attached.
function __Network:unstream(handler) end

--- [SHARED]
---
--- Attaches a handler that is called on every transfer progress, both incoming and outgoing.
---
---@param handler Network.ProgressFn | Hook | Event The callback or callable object.
function __Network:watch(handler) end

--- [SHARED]
---
--- Detaches a previously attached progress handler.
---
---@param handler Network.ProgressFn | Hook | Event The exact handler reference.
---@return boolean removed `true` if the handler was attached.
function __Network:unwatch(handler) end

---@class Network.GameClient
---@field client holylib.CGameClient The HolyLib `GameClient`.
---@field reliable holylib.bf_write The reliable stream ( `bf_write` ) of the client.

---@class Network.Bucket
---@field tokens number
---@field time number

---@class Network.Client
---@field strikes number
---@field strike_time number
---@field transfers integer
---@field bytes integer
---@field begins number
---@field begin_time number

---@class Network.Outgoing
---@field network Network
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
---@field callback Network.FinishFn | nil

---@class Network.Incoming
---@field network Network
---@field peer garrysmod.Player | nil
---@field key garrysmod.Player | string
---@field id integer
---@field size integer
---@field segment_size integer
---@field count integer
---@field checksum integer
---@field buffered boolean `true` if the segments are kept for the receive handlers.
---@field crc checksum.CRC32 | nil The running checksum of the delivered data, if not buffered.
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

---@class Network.Queued
---@field data string
---@field callback Network.FinishFn | nil

---@param name string
---@return Network | nil object
---@protected
function Network:__new(name) end

---@return string
---@protected
function __Network:__represent() end

---@param name string
---@param can_receive boolean?
---@protected
function __Network:__init(name, can_receive) end

---@param key string
---@protected
function __Network:__index(key) end

---@param key string
---@param value any
---@protected
function __Network:__newindex(key, value) end

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
---@param callback Network.FinishFn? The callback that is called when the transmission is finished or failed.
function __Network:send(data, target, callback) end

--- [SHARED]
---
--- Builds the data with a binary writer and sends it to the target.
---
---@param fn fun( network: Network, writer: BinaryWriter ) The function that writes the data.
---@param target ( garrysmod.Player | garrysmod.Player[] )? The target player(s), required on the server, ignored on the client.
---@param callback Network.FinishFn? The callback that is called when the transmission is finished or failed.
function __Network:transmit(fn, target, callback) end

--- [SHARED]
---
--- Cancels the outgoing transmission to the target and all queued ones.
---
---@param target garrysmod.Player? The target player, required on the server, ignored on the client.
---@return boolean cancelled `true` if anything was cancelled.
function __Network:abort(target) end

--- [SHARED]
---
--- Checks if the network is sending data to the target.
---
---@param target garrysmod.Player? The target player, required on the server, ignored on the client.
---@return boolean is_sending
---@nodiscard
function __Network:isSending(target) end

--- [SHARED]
---
--- Checks if the network is receiving data from the sender.
---
---@param sender garrysmod.Player? The sender player, required on the server, ignored on the client.
---@return boolean is_receiving
---@nodiscard
function __Network:isReceiving(sender) end
