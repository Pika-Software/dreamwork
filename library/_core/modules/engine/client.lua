---@meta _

--- [SHARED]
---
--- A client of the server, a player that is connecting or connected.
---
--- A client exists from the moment it starts connecting, before its player entity,
--- its data is collected from the engine hooks, game events and the player entity.
---
--- Fields are read-only and can be `nil` until they are known:
--- * `name` is updated with the `dreamwork.client.renamed` hook.
--- * `steam_id` is `nil` for bots, it is set with the `dreamwork.client.identified` hook.
--- * `ip` and `port` are only known on the server, `ip` is `0x7F000001` ( 127.0.0.1 ) without `port` for the listen server host.
---
--- The object stays readable after the client disconnects, but it is not returned by `get` anymore.
---
---@class Client : Object
---@field __class ClientClass
---@field stage Client.Stage The current connection stage of the client.
---@field steam_id steam.Identifier | nil The Steam ID of the client, `nil` for bots and until it is known.
---@field user_id integer The user ID of the client, unique during the map.
---@field entity_id integer | nil The entity index of the player entity of the client.
---@field ip IPv4 | nil The IPv4 address of the client as an unsigned 32-bit integer, see `ipv4`, always `nil` on the client.
---@field port integer | nil The port of the client, always `nil` on the client.
---@field name string | nil The name of the client, `nil` until it is known.
---@field is_bot boolean `true` if the client is a bot.
---@field is_initialized boolean `true` if the player entity of the client is valid on the client and it can send and receive network messages. On the server a client is initialized by its first user command that is not forced, which the client sends after `InitPostEntity`. On the client the local client is initialized in `InitPostEntity`, the others once the server reports them.
---@field is_connected boolean `true` until the client disconnects.
local __Client = {}

--- [SHARED]
---
--- The class of `Client`, call it with a user ID to get the client.
---
---@class ClientClass : Client, Class
---@field __base Client
---@overload fun( user_id: integer ): Client
Client = {}

---@return string
---@protected
function __Client:__represent() end

---@param key string
---@return any
---@protected
function __Client:__index(key) end

---@param key string
---@protected
function __Client:__newindex(key) end

--- Deserialized objects share the data of their client, so they are equal to it.
---
---@param other Client
---@return boolean
---@protected
function __Client:__eq(other) end

--- Writes the player entity index of the client, `0` if it is not known yet.
---
---@param writer BinaryWriter The writer to write to.
---@protected
function __Client:__serialize(writer) end

--- Reads the player entity index written by `__serialize`, the object becomes a view of the client with the index.
---
--- An unknown index gives a disconnected client without data, e.g. the client left before the message arrived.
---
--- > NOTE: The object is equal (`==`) to the client, but it is a different key in tables.
---
---@param reader BinaryReader The reader to read from.
---@protected
function __Client:__deserialize(reader) end

---@param user_id integer
---@return Client | nil
---@protected
function Client:__new(user_id) end

--- [SHARED]
---
--- Checks if the client is the local one, the game client itself on the client,
--- the host on a listen server or in single-player.
---
---@return boolean is_local `true` if the client is the local one, `false` otherwise.
---@nodiscard
function __Client:isLocal() end

--- [SHARED]
---
--- Returns the client with the user ID.
---
---@param user_id integer The user ID.
---@return Client | nil client The client, or `nil` if there is no connected client with the user ID.
---@nodiscard
function Client.get(user_id) end

--- [SHARED]
---
--- Returns the local client, see `Client:isLocal`.
---
--- > NOTE: Always `nil` on a dedicated server.
---
---@return Client | nil client The local client, or `nil` if it is not known yet.
---@nodiscard
function Client.getLocal() end

--- [SHARED]
---
--- Returns the connected clients in the order of their connection.
---
---@param ignore_bots boolean? If `true`, bots are skipped.
---@param ignore_humans boolean? If `true`, humans are skipped.
---@return Client[] client_list The new list of the clients.
---@return integer client_count The number of the clients in the list.
---@nodiscard
function Client.getAll(ignore_bots, ignore_humans) end

--- [SHARED]
---
--- Finds a connected client by its name.
---
--- An exact match is preferred, otherwise the first client whose name contains `name`, ignoring the case.
---
---@param name string The name or a part of it.
---@return Client | nil client The found client, or `nil` if there is none.
---@nodiscard
function Client.findByName(name) end

--- [SHARED]
---
--- Finds a connected client by its Steam ID.
---
--- Matches on the account ID (`identifier.id`), so any `steam.Identifier` form
--- for the same account works. Bots and clients without a known Steam ID are skipped.
---
---@param identifier steam.Identifier The Steam ID to search for.
---@return Client | nil client The found client, or `nil` if there is none.
---@nodiscard
function Client.findBySteamId(identifier) end

--- [SHARED]
---
--- Returns the number of connected clients, optionally filtering by type.
---
--- Without filters this is the same as the length returned by `getAll`.
--- Spawned bots and humans are counted separately from connecting clients
--- ( announced, but not yet at the `spawned` stage ).
---
---@param ignore_bots boolean? If `true`, spawned bots are skipped.
---@param ignore_humans boolean? If `true`, spawned humans are skipped.
---@param ignore_connecting boolean? If `true`, connecting clients are skipped.
---@return integer client_count The number of matching clients.
---@nodiscard
function Client.getCount(ignore_bots, ignore_humans, ignore_connecting) end

--- [SHARED]
---
--- Runs a console command on the client.
---
--- On the server it works for any client with a player entity,
--- on the client only for the local one.
---
--- > NOTE: The arguments are quoted, so they cannot contain `"`.
---
---@param command string The name of the console command.
---@param ... string The arguments of the console command.
---@return boolean is_sent `true` if the command was sent, `false` if the client cannot run it.
function __Client:runConsoleCommand(command, ...) end

--- [SHARED]
---
--- Reconnects the client to the server.
---
---@return boolean success `true` if the reconnect was sent, `false` if the client cannot reconnect.
function __Client:reconnect() end

--- [SHARED]
---
--- Reconnects the client to the server.
---
--- Runs `retry` via `Client:runConsoleCommand`.
--- On the server it needs a player entity, on the client only the local one.
---
---@return boolean success `true` if the reconnect was sent, `false` if the client cannot reconnect.
function __Client:reconnect() end

--- [SHARED]
---
--- Disconnects the client from the server.
---
---@param reason string? The reason to disconnect the client with.
---@param silent boolean? If `true`, silently closes the net channel and sends no disconnect to the client. Defaults to `false`, ignored without HolyLib.
---@return boolean success `true` if the client was successfully disconnected.
function __Client:disconnect(reason, silent) end
