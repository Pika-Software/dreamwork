---@meta _

---@class garrysmod.net
local glua_net = {}

--- [SHARED]
---
--- A named two-way channel between the server and the clients
--- built on top of the engine `net` library, without its 64 KiB message limit.
---
--- Data up to 8 KiB is usually sent as a single reliable message, larger data is split
--- into segments and streamed over the unreliable channel with acknowledgements,
--- retransmission, congestion control and a CRC32 check of the whole data.
---
--- Transfers to the same peer are queued, one runs at a time per network.
---
--- The network must be created on the server first, the client can only
--- open networks the server has registered. Creating a network with
--- the name of an existing one returns the existing object.
---
--- On the server, every client is limited in strikes, concurrent transfers
--- and bytes, protocol violations accumulate strikes and kick the client.
---
---@class Network : Object
---@field __class NetworkClass
---@field id integer The engine ID of the network, read-only.
---@field name string The name of the network without the internal prefix, read-only.
---@field receiver boolean `true` if the network accepts incoming messages, `false` by default.
---@field timeout number The number of seconds without any progress after which a transfer is aborted, `15` by default, at least `1`.
---@field window integer The maximum number of segments in flight, `64` by default, clamped to `[1, 256]`.
---@field segment integer The size of outgoing segments in bytes, by default fits into a 1 KiB message, at least `256` and at most what fits into one message.
---@field limit integer The maximum size of an incoming message in bytes, `64` MiB by default, `0` rejects everything.
local __Network = {}

--- [SHARED]
---
--- The class of `Network`, call it to create or get a network.
---
---@class NetworkClass : Network, Class
---@field __base Network
---@overload fun( name: string, can_receive: boolean? ): Network
Network = {}

--- Called when a message is fully received and its checksum matches.
---
--- `sender` is the player on the server and `nil` on the client.
---
---@alias Network.ReceiveFn fun( network: Network, reader: BinaryReader, sender: garrysmod.Player | nil )

--- Called on every transfer progress, both incoming and outgoing.
---
--- `peer` is the other side, the player on the server and `nil` on the client,
--- `is_outgoing` is `true` for sent data, `done_bytes` counts the received
--- or acknowledged bytes out of `total_bytes`.
---
---@alias Network.ProgressFn fun( network: Network, peer: garrysmod.Player | nil, is_outgoing: boolean, done_bytes: integer, total_bytes: integer )

--- Called for every chunk of incoming data in order, while it arrives.
---
--- `chunk` is the data at the zero-based byte `offset` out of `total` bytes.
--- The last call has `chunk = nil` and `success`, `offset` is the number of delivered bytes then.
---
---@alias Network.StreamFn fun( network: Network, sender: garrysmod.Player | nil, chunk: string | nil, offset: integer, total: integer, success: boolean | nil )

--- Called when an outgoing transmission is finished.
---
--- `success` is `false` if it was rejected, cancelled, timed out or the peer left.
---
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

--- The cached HolyLib net channel access of a player.
---
---@class Network.GameClient
---@field client holylib.CGameClient The HolyLib `GameClient`.
---@field reliable holylib.bf_write The reliable stream ( `bf_write` ) of the client.

--- The token bucket that limits single messages to one peer.
---
---@class Network.Bucket
---@field tokens number The number of bytes that can be sent as singles right now.
---@field time number The uptime of the last refill.

--- The limits of one client over all networks.
---
---@class Network.Client
---@field strikes number The protocol violation strikes, decaying over time.
---@field strike_time number The uptime of the last strike update.
---@field transfers integer The number of incoming transfers in progress.
---@field bytes integer The total size of incoming transfers in progress, in bytes.
---@field begins number The token bucket of new transfers.
---@field begin_time number The uptime of the last `begins` refill.

--- The sender side state of a segmented transfer.
---
---@class Network.Outgoing
---@field network Network The network of the transfer.
---@field peer garrysmod.Player | nil The receiver, `nil` on the client.
---@field key garrysmod.Player | string The key of the peer in the per-peer tables.
---@field id integer The transfer ID, `[0, 255]`.
---@field data string The whole data.
---@field size integer The size of the data in bytes.
---@field segment_size integer The size of every segment except the last one, in bytes.
---@field count integer The number of segments.
---@field acked boolean[] The acknowledged segments.
---@field sent_at number[] The uptime of the last send of every segment.
---@field resent boolean[] The segments that were sent more than once, excluded from rtt samples.
---@field resent_count integer The number of resends, for the log.
---@field acked_count integer The number of acknowledged segments.
---@field acked_bytes integer The number of acknowledged bytes.
---@field base integer The first unacknowledged segment.
---@field highest integer The highest acknowledged segment.
---@field window number The congestion window, in segments.
---@field slow_start boolean `true` until the first loss, the window grows by one per ack instead of one per window.
---@field srtt number | nil The smoothed round trip time in seconds, `nil` until accepted.
---@field srtt_seeded boolean | nil `true` while `srtt` is the handshake sample.
---@field rto number The retransmission timeout in seconds.
---@field loss_time number The uptime of the last window cut.
---@field credit number The number of segments that can be sent right now, refilled by pacing.
---@field pump_time number The uptime of the last pump, the base of the pacing refill.
---@field accepted boolean `true` once the receiver has accepted the transfer.
---@field activity number The uptime of the last progress, for the timeout.
---@field start_time number The uptime of the start.
---@field callback Network.FinishFn | nil The finish callback of `Network:send`.

--- The receiver side state of a segmented transfer.
---
---@class Network.Incoming
---@field network Network The network of the transfer.
---@field peer garrysmod.Player | nil The sender, `nil` on the client.
---@field key garrysmod.Player | string The key of the peer in the per-peer tables.
---@field id integer The transfer ID, `[0, 255]`.
---@field size integer The size of the data in bytes.
---@field segment_size integer The size of every segment except the last one, in bytes.
---@field count integer The number of segments.
---@field checksum integer The CRC32 of the whole data announced by the sender.
---@field buffered boolean `true` if the segments are kept for the receive handlers.
---@field crc checksum.CRC32 | nil The running checksum of the delivered data, if not buffered.
---@field segments string[] The received segments, the delivered ones are dropped if not buffered.
---@field received_flags boolean[] The received segments.
---@field received integer The number of received segments.
---@field received_bytes integer The number of received bytes.
---@field base integer The first missing segment, everything before it is delivered.
---@field highest integer The highest received segment.
---@field ack_pending boolean `true` if a segment arrived since the last ack.
---@field ack_time number The uptime of the last ack.
---@field activity number The uptime of the last received segment, for the timeout.
---@field start_time number The uptime of the start.

--- A transmission waiting for the running one to the same peer.
---
---@class Network.Queued
---@field data string The data to send.
---@field callback Network.FinishFn | nil The finish callback of `Network:send`.

---@param name string The name of the network.
---@return Network | nil object The existing network with this name.
---@protected
function Network:__new(name) end

---@return string
---@protected
function __Network:__represent() end

---@param name string The name of the network, must be unique.
---@param can_receive boolean? `true` if the network accepts incoming messages, `false` by default.
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
---@return boolean is_sending `true` if a transmission to the target is running.
---@nodiscard
function __Network:isSending(target) end

--- [SHARED]
---
--- Checks if the network is receiving data from the sender.
---
---@param sender garrysmod.Player? The sender player, required on the server, ignored on the client.
---@return boolean is_receiving `true` if a transmission from the sender is running.
---@nodiscard
function __Network:isReceiving(sender) end
