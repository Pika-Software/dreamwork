---@meta _

--- The Lua state a message is sent from or to.
---
---@alias Message.Realm "server" | "client" | "menu"

--- [SHARED AND MENU]
---
--- A named channel that sends data through hidden console commands,
--- so it also works between the menu and the client states, where the `net` library doesn't.
---
--- The server sends to the client state of players, the client sends to the server or the menu,
--- the menu sends to the client. The data is split into url-safe base64 packets of one console
--- line each, paced by a per-frame byte budget, and is delivered to the handlers only when complete.
---
--- It is slow ( ~45 KiB/s with a 20 fps client ) and has no checksum, so prefer `Network`
--- for large data between the server and the client.
---
--- Every realm must create the message with the same name to receive it,
--- creating a message with the name of an existing one returns the existing object.
---
--- Messages to the same target are queued and sent in order.
---
---@class Message : Object
---@field __class MessageClass
---@field name string The name of the message, read-only.
---@field receiver boolean `true` if the message accepts incoming data, `false` by default.
---@field timeout number The number of seconds without a packet after which an incomplete incoming transfer is dropped, `15` by default, at least `1`.
---@field limit integer The maximum size of an incoming message in bytes, `256` KiB by default, `0` rejects everything.
local __Message = {}

--- [SHARED AND MENU]
---
--- The class of `Message`, call it to create or get a message.
---
---@class MessageClass : Message, Class
---@field __base Message
---@overload fun( name: string, can_receive: boolean? ): Message
Message = {}

--- Called when a message is fully received.
---
--- `sender` is the player on the server and `nil` on the client and menu,
--- `realm` is the realm the message claims to come from.
---
---@alias Message.ReceiveFn fun( message: Message, reader: BinaryReader, sender: garrysmod.Player | nil, realm: Message.Realm )

--- Called when an outgoing message is finished.
---
--- `success` is `true` when the last packet is handed to the engine, the delivery is not confirmed,
--- `false` if it was aborted or the target player left.
---
---@alias Message.FinishFn fun( message: Message, success: boolean, target: garrysmod.Player | Message.Realm )

--- [SHARED AND MENU]
---
--- Attaches a handler that is called when a message is fully received.
---
--- If the handler is already attached, it will not be attached twice.
---
---@param handler Message.ReceiveFn | Hook | Event The callback or callable object.
function __Message:attach(handler) end

--- [SHARED AND MENU]
---
--- Attaches a handler that automatically detaches
--- itself right before being invoked, so it only ever runs once.
---
---@param handler Message.ReceiveFn | Hook | Event The callback or callable object.
function __Message:once(handler) end

--- [SHARED AND MENU]
---
--- Detaches a previously attached receive handler.
---
---@param handler Message.ReceiveFn | Hook | Event The exact handler reference.
---@return boolean removed `true` if the handler was attached.
function __Message:detach(handler) end

--- [SHARED AND MENU]
---
--- Removes every receive handler.
---
function __Message:clear() end

--- [SHARED AND MENU]
---
--- Waits for the next fully received message.
---
---@return Message message The message.
---@return BinaryReader reader The reader of the message.
---@return garrysmod.Player | nil sender The sender, `nil` on the client and menu.
---@return Message.Realm realm The realm the message claims to come from.
---@async
function __Message:await() end

---@param name string The name of the message.
---@return Message | nil object The existing message with this name.
---@protected
function Message:__new(name) end

---@return string
---@protected
function __Message:__represent() end

---@param name string The name of the message, must be the same in every realm.
---@param can_receive boolean? `true` if the message accepts incoming data, `false` by default.
---@protected
function __Message:__init(name, can_receive) end

---@param key string
---@protected
function __Message:__index(key) end

---@param key string
---@param value any
---@protected
function __Message:__newindex(key, value) end

--- An outgoing transfer, split into packets up front.
---
---@class Message.Outgoing
---@field message Message The message of the transfer.
---@field target garrysmod.Player | Message.Realm The target player on the server, the target realm otherwise.
---@field command string The receiving console command.
---@field packets string[] The encoded packets, the sent ones are dropped.
---@field count integer The number of packets.
---@field sent integer The number of sent packets.
---@field callback Message.FinishFn | nil The finish callback of `Message:send`.

--- [SHARED AND MENU]
---
--- Sends the data to the target.
---
--- The data is split into console command packets that are paced over frames,
--- the ~8 kb per frame console limit makes it slow ( ~45 kb/s with a 20 fps client ), so prefer `Network`
--- for large data between the server and the client.
---
--- The server sends to the client state of the target players,
--- the client sends to `"server"` ( default ) or `"menu"`, the menu sends to the client.
---
--- Messages to the same target are queued and sent in order.
---
---@param data string The data to send.
---@param target ( garrysmod.Player | garrysmod.Player[] | Message.Realm )? The target player(s) on the server, the target realm on the client, ignored in the menu.
---@param callback Message.FinishFn? The callback that is called when the last packet is handed to the engine, or the target left.
function __Message:send(data, target, callback) end

--- [SHARED AND MENU]
---
--- Builds the data with a binary writer and sends it to the target.
---
---@param fn fun( message: Message, writer: BinaryWriter ) The function that writes the data.
---@param target ( garrysmod.Player | garrysmod.Player[] | Message.Realm )? The target player(s) on the server, the target realm on the client, ignored in the menu.
---@param callback Message.FinishFn? The callback that is called when the last packet is handed to the engine, or the target left.
function __Message:transmit(fn, target, callback) end

--- [SHARED AND MENU]
---
--- Cancels the outgoing transfers of this message to the target, the packets already sent are not recalled.
---
---@param target ( garrysmod.Player | Message.Realm )? The target player on the server, the target realm on the client, ignored in the menu.
---@return boolean cancelled `true` if anything was cancelled.
function __Message:abort(target) end

--- [SHARED AND MENU]
---
--- Checks if the message has queued outgoing packets to the target.
---
---@param target ( garrysmod.Player | Message.Realm )? The target player on the server, the target realm on the client, ignored in the menu.
---@return boolean is_sending `true` if a transfer of this message to the target is queued.
---@nodiscard
function __Message:isSending(target) end

--- An incomplete incoming transfer.
---
---@class Message.Incoming
---@field id integer The transfer ID, `[0, 255]`.
---@field count integer The number of packets.
---@field next integer The zero-based index of the expected packet.
---@field chunks string[] The received data chunks.
---@field size integer The number of received bytes.
---@field activity number The uptime of the last received packet, for the timeout.

--- [SHARED AND MENU]
---
--- Checks if the message is receiving data from the sender.
---
---@param sender ( garrysmod.Player | Message.Realm )? The sender player on the server, the sender realm on the client, ignored in the menu.
---@return boolean is_receiving `true` if an incomplete transfer from the sender is in progress.
---@nodiscard
function __Message:isReceiving(sender) end
