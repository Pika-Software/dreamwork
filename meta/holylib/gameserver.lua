---@meta holylib.gameserver


-- ConVars:
--   holylib_gameserver_disablespawnsafety (default 0)
--     Allows players to spawn on slots above 128. WILL cause stability and many other issues.
--   holylib_gameserver_connectionlesspackethook (default 1)
--     Enables the HolyLib:ProcessConnectionlessPacket hook.
--   holylib_gameserver_rawclients (default 0)
--     Empty CGameClients are still considered valid. Highly discouraged, it removes IsValid checks
--     and calling functions on empty slots may expose garbage or crash.
--   holylib_gameserver_maxplayers (default 128)
--     Max players. Going above 128 results in queue slots (players can join but not spawn).
--   sv_filter_nobanresponse (default 0)
--     A blocked ip won't be informed that it is blocked.


--- [SERVER]
---
--- This library exposes the engine's `CBaseServer` and `CBaseClient`.
---
--- It also allows going above 128 players (as queue slots), singleplayer servers,
--- creating custom net channels and sending connectionless packets.
---
---@class holylib.gameserver
gameserver = {}

--- [SERVER]
---
--- returns current number of clients
---
---@return integer result
function gameserver.GetNumClients() end

--- [SERVER]
---
--- returns current number of attached HLTV proxies
---
---@return integer result
function gameserver.GetNumProxies() end

--- [SERVER]
---
--- returns current number of fake clients/bots
---
---@return integer result
function gameserver.GetNumFakeClients() end

--- [SERVER]
---
--- returns current client limit
---
---@return integer result
function gameserver.GetMaxClients() end

--- [SERVER]
---
--- returns the udp port the server is running on.
---
---@return integer result
function gameserver.GetUDPPort() end

--- [SERVER]
---
--- Returns the CGameClient at that player slot or `nil` on failure.
---
---@param playerSlot integer
---@return holylib.CGameClient | nil result
function gameserver.GetClient( playerSlot ) end

--- [SERVER]
---
--- Returns the CGameClient for the given userID or `nil` on failure.
---
---@param userID integer
---@return holylib.CGameClient | nil result
function gameserver.GetClientByUserID( userID ) end

--- [SERVER]
---
--- Returns the CGameClient for the given steamID or `nil` on failure. (steamID not steamID64!)
---
---@param steamID string
---@return holylib.CGameClient | nil result
function gameserver.GetClientBySteamID( steamID ) end

--- [SERVER]
---
--- Returns client count for iteration of `gameserver.GetClient`
---
--- > **NOTE**: This will include inactive `CGameClient`'s since the engine re-uses them and doesn't delete them on disconnect.
--- > If you want to get the count of active client's use `gameserver.GetNumClients()`
---
---@return integer result
function gameserver.GetClientCount() end

--- [SERVER]
---
--- Returns current CPU usage: number [0-1]
---
---@return number result
function gameserver.GetCPUUsage() end

--- [SERVER]
---
--- Returns a table that contains all game clients. It will return `nil` on failure.
---
---@return holylib.CGameClient[] | nil result
function gameserver.GetAll() end

--- [SERVER]
---
--- Returns the current time/curtime
---
---@return number result
function gameserver.GetTime() end

--- [SERVER]
---
--- Returns the current tick
---
---@return integer result
function gameserver.GetTick() end

--- [SERVER]
---
--- Returns the current tick interval
---
---@return number result
function gameserver.GetTickInterval() end

--- [SERVER]
---
--- Returns the current server/host name.
--- Should be the same as `GetConVar("hostname"):GetString()`
---
---@return string result
function gameserver.GetName() end

--- [SERVER]
---
--- Returns the current map name
---
---@return string result
function gameserver.GetMapName() end

--- [SERVER]
---
---@return integer result
function gameserver.GetSpawnCount() end

--- [SERVER]
---
---@return integer result
function gameserver.GetNumClasses() end

--- [SERVER]
---
---@return integer result
function gameserver.GetClassBits() end

--- [SERVER]
---
---@return boolean result
function gameserver.IsActive() end

--- [SERVER]
---
---@return boolean result
function gameserver.IsLoading() end

--- [SERVER]
---
---@return boolean result
function gameserver.IsDedicated() end

--- [SERVER]
---
---@return boolean result
function gameserver.IsPaused() end

--- [SERVER]
---
---@return boolean result
function gameserver.IsMultiplayer() end

--- [SERVER]
---
---@return boolean result
function gameserver.IsPausable() end

--- [SERVER]
---
---@return boolean result
function gameserver.IsHLTV() end

--- [SERVER]
---
--- Returns the current server password.
---
---@return string result
function gameserver.GetPassword() end

--- [SERVER]
---
--- Sets the max client count.
--- Should do nothing.
---
---@param maxClients integer
function gameserver.SetMaxClients( maxClients ) end

--- [SERVER]
---
--- Pauses/Unpauses the server.
---
--- > **NOTE**: Verify if this actually works
---
---@param paused? boolean Defaults to `false`.
function gameserver.SetPaused( paused ) end

--- [SERVER]
---
--- Sets the server password.
---
---@param password string
function gameserver.SetPassword( password ) end

--- [SERVER]
---
--- Sends a custom net message to all clients.
--- This function allows you send any netmessage you want.
--- You should know what your doing since this function doesn't validate anything.
--- You can find all valid types in the [protocol.h](https://github.com/RaphaelIT7/gmod-holylib/blob/main/source/sourcesdk/protocol.h#L86-L145)
---
--- > **NOTE**: This was formerly known as `HolyLib.BroadcastCustomMessage`
---
--- Example usage, we enable `sv_cheats` clientside while having it disabled serverside.
---
--- ```lua
--- local bf = bitbuf.CreateWriteBuffer(64) -- Create a 64 bytes buffer.
---
--- bf:WriteByte(1) -- How many convars were sending
--- bf:WriteString("sv_cheats") -- ConVar name
--- bf:WriteString("1") -- ConVar value
---
--- -- You can use CBaseClient:SendNetMsg to send it to specific clients.
--- gameserver.BroadcastMessage(5, "NET_SetConVar", bf) -- 5 = net_SetConVar / net message type.
--- ```
---
---@param type integer
---@param name string
---@param buffer holylib.bf_write
function gameserver.BroadcastMessage( type, name, buffer ) end

--- [SERVER]
---
--- Sends out a connectionless packet to the target ip.
--- Returns the length of the sent data or `-1` on failure.
---
--- > **NOTE**: It's expected that **YOU** already added the connectionless header, this was done to not have to copy the buffer.
--- > `bf:WriteLong(-1) -- Write this as the first thing. This is the CONNECTIONLESS_HEADER`
---
--- Example on how to send a loopback packet:
---
--- ```lua
--- hook.Add("HolyLib:ProcessConnectionlessPacket", "LoopbackExample", function(bf, ip)
--- 	if ip != "loopback" then return end
---
--- 	print("We got our own packet: " .. bf:ReadString())
--- 	return true
--- end)
---
--- local bf = bitbuf.CreateWriteBuffer(64)
--- bf:WriteLong(-1)
--- bf:WriteString("Hello World")
---
--- -- We use NS_CLIENT as a socket because then the packet is queued into the Server loopback queue.
--- gameserver.SendConnectionlessPacket(bf, "loopback:" .. gameserver.GetUDPPort(), false, gameserver.NS_CLIENT)
--- ```
---
---@param bf holylib.bf_write
---@param ip string The target ip. Format `ip:port`.
---@param useDNS? boolean Defaults to `false`.
---@param socket? integer Defaults to `NS_SERVER`.
---@return integer result
function gameserver.SendConnectionlessPacket( bf, ip, useDNS, socket ) end

--- [SERVER]
---
--- Creates a fake client or returns `nil` on failure
---
---@param name string
---@return holylib.CGameClient | nil result
function gameserver.CreateFakeClient( name ) end

--- [SERVER]
---
--- Creates a new client or returns `nil` on failure
--- Use this only if you know what you're doing, as if you lose track of the client, you'll leak memory!
--- A client once created is never meant to be deleted.
--- Use `CBaseClient:AddToQueueList` or `CBaseClient:AddToServerList` to register the client into the proper list unless you're manually controlling them!
---
---@return holylib.CGameClient | nil result
function gameserver.CreateNewClient() end

--- [SERVER]
---
--- Searches if there is a `CGameClient` with the given address already and returns their object OR attempts to create a new client.
---
---@param address string
---@param useDNS? boolean Defaults to `false`.
---@param noQueueClients? boolean Defaults to `false`.
---@return holylib.CGameClient | nil result
function gameserver.GetFreeClient( address, useDNS, noQueueClients ) end

--- [SERVER]
---
--- Searches if there is a queue `CGameClient` with the given address already and returns their object OR attempts to create a new queue client.
---
---@param address string
---@param useDNS? boolean Defaults to `false`.
---@return holylib.CGameClient | nil result
function gameserver.GetFreeQueueClient( address, useDNS ) end

--- [SERVER]
---
--- Returns the server's socket
---
---@return integer result
function gameserver.GetSocket() end

--- [SERVER]
---
--- Creates a net channel for the given ip.
--- Returns the channel or `nil` on failure.
---
---@param ip string The target ip. Format `ip:port`.
---@param useDNS? boolean Defaults to `false`.
---@param protocolVersion? integer Defaults to `1`.
---@param socket? integer Defaults to `NS_SERVER`.
---@return holylib.CNetChan | nil result
function gameserver.CreateNetChannel( ip, useDNS, protocolVersion, socket ) end

--- [SERVER]
---
--- Removes/Destroys a net channel invalidating it.
---
---@param channel holylib.CNetChan
---@return holylib.CNetChan result
function gameserver.RemoveNetChannel( channel ) end

--- [SERVER]
---
--- Returns a table containing all net channels created by gameserver.CreateNetChannel.
---
---@return holylib.CNetChan[] result
function gameserver.GetCreatedNetChannels() end

--- [SERVER]
---
--- Client socket.
---
---@type integer
gameserver.NS_CLIENT = 0

--- [SERVER]
---
--- Server socket.
---
---@type integer
gameserver.NS_SERVER = 1

--- [SERVER]
---
--- HLTV socket.
---
---@type integer
gameserver.NS_HLTV = 2

--- [SERVER]
---
--- Outgoing flow
---
---@type integer
gameserver.FLOW_OUTGOING = 0

--- [SERVER]
---
--- Incoming flow
---
---@type integer
gameserver.FLOW_INCOMING = 1


--- [SERVER]
---
--- This class represents a client.
---
---@class holylib.CBaseClient
local CBaseClient = {}

--- [SERVER]
---
--- Internally implemented and will set the values into the lua table.
---
---@param key string
---@param value any
function CBaseClient:__newindex( key, value ) end

--- [SERVER]
---
--- Internally searches first in the metatable table for the key.
--- If it fails to find it, it will search in the lua table before returning.
--- If you try to get multiple values from the lua table, just use `CBaseClient:GetTable()`.
---
---@param key string
---@return any result
function CBaseClient:__index( key ) end

--- [SERVER]
---
--- Returns the lua table of this object.
--- You can store variables into it.
---
---@return table result
function CBaseClient:GetTable() end

--- [SERVER]
---
--- Returns the slot of the client. Use this for `sourcetv.GetClient`.
---
---@return integer result
function CBaseClient:GetPlayerSlot() end

--- [SERVER]
---
--- Returns the userid of the client.
---
---@return integer result
function CBaseClient:GetUserID() end

--- [SERVER]
---
--- Returns the name of the client.
---
---@return string result
function CBaseClient:GetName() end

--- [SERVER]
---
--- Returns the steamid of the client.
---
---@return string result
function CBaseClient:GetSteamID() end

--- [SERVER]
---
--- Reconnects the client.
function CBaseClient:Reconnect() end

--- [SERVER]
---
--- Prints the given message into the client's console.
---
--- > **NOTE**: It **won't** add `\n` to the end, you have to add it yourself.
---
---@param message string
function CBaseClient:ClientPrint( message ) end

--- [SERVER]
---
--- Returns `true` if the client is still valid.
---
--- > **IMPORTANT**: This function obeys `holylib_gameserver_rawclients` so a empty slot is treated as Invalid!
---
---@return boolean result
function CBaseClient:IsValid() end

--- [SERVER]
---
--- Returns `true` if the client is truly invalid.
--- It can return `false` meaning the pointer internally is just an empty client, while `CBaseClient:IsValid` returns `false`.
---
--- > **IMPORTANT**: This function does **NOT** obey `holylib_gameserver_rawclients` and exists for code to know if the object internally has a valid `CBaseClient` but is empty.
---
---@return boolean result
function CBaseClient:IsInvalid() end

--- [SERVER]
---
--- Sends the given code to the client to be executed.
--- Returns `true` on success.
---
--- > **NOTE**: This function was readded back experimentally. It wasn't tested yet. It's still broken but doesn't crash
---
---@param code string
---@return boolean result
function CBaseClient:SendLua( code ) end

--- [SERVER]
---
--- Fires/sends the gameevent to this specific client.
---
---@param event any The `IGameEvent` to send (gameevent module, not documented in meta yet).
function CBaseClient:FireEvent( event ) end

--- [SERVER]
---
--- Returns the friend id.
---
---@return integer result
function CBaseClient:GetFriendsID() end

--- [SERVER]
---
--- Returns the friend name.
---
---@return string result
function CBaseClient:GetFriendsName() end

--- [SERVER]
---
--- Returns the client challenge number.
---
---@return integer result
function CBaseClient:GetClientChallenge() end

--- [SERVER]
---
---@param reportClient? boolean Defaults to `false`.
function CBaseClient:SetReportThisFakeClient( reportClient ) end

--- [SERVER]
---
---@return boolean result
function CBaseClient:ShouldReportThisFakeClient() end

--- [SERVER]
---
--- Inactivates the client.
---
--- > **WARNING**: Know what your doing when using it!
function CBaseClient:Inactivate() end

--- [SERVER]
---
--- Disconnects the client.
---
---@param reason string
---@param silent? boolean Silently closes the net channel and sends no disconnect to the client. Defaults to `false`.
---@param nogameevent? boolean Stops the `player_disconnect` event from being created. Defaults to `false`.
function CBaseClient:Disconnect( reason, silent, nogameevent ) end

--- [SERVER]
---
---@param rate integer
function CBaseClient:SetRate( rate ) end

--- [SERVER]
---
---@return integer result
function CBaseClient:GetRate() end

--- [SERVER]
---
---@return number value1
---@return number value2
function CBaseClient:GetRemoteFramerate() end

--- [SERVER]
---
--- Normally, the update rate is controlled by the client's `cl_updaterate` and this controlls how many snapshots per second are sent to clients.
--- Snapshots are quite expensive- so you could force it to a lower value, which can help performance noticeably.
---
---@param rate integer
function CBaseClient:SetUpdateRate( rate ) end

--- [SERVER]
---
---@return integer result
function CBaseClient:GetUpdateRate() end

--- [SERVER]
---
--- Clear the client/frees the CBaseClient for the next player to use.
---
--- > **WARNING**: Know what your doing when using it!
function CBaseClient:Clear() end

--- [SERVER]
function CBaseClient:DemoRestart() end

--- [SERVER]
---
---@return integer result
function CBaseClient:GetMaxAckTickCount() end

--- [SERVER]
---
--- Executes the given command as if the client himself ran it.
---
---@param command string
function CBaseClient:ExecuteStringCommand( command ) end

--- [SERVER]
---
--- Same as `gameserver.BroadcastMessage` but it only sends it to the specific player.
---
--- > **NOTE**: This function was formerly known as `HolyLib.SendCustomMessage`
---
---@param type integer
---@param name string
---@param buffer holylib.bf_write
function CBaseClient:SendNetMsg( type, name, buffer ) end

--- [SERVER]
---
---@return boolean result
function CBaseClient:IsConnected() end

--- [SERVER]
---
---@return boolean result
function CBaseClient:IsSpawned() end

--- [SERVER]
---
---@return boolean result
function CBaseClient:IsActive() end

--- [SERVER]
---
---@return integer result
function CBaseClient:GetSignonState() end

--- [SERVER]
---
---@return boolean result
function CBaseClient:IsFakeClient() end

--- [SERVER]
---
---@return boolean result
function CBaseClient:IsHLTV() end

--- [SERVER]
---
--- Works like `voicechat.IsHearingClient` but only takes the direct player slot.
---
---@param playerSlot integer
---@return boolean result
function CBaseClient:IsHearingClient( playerSlot ) end

--- [SERVER]
---
--- Works like `voicechat.IsProximityHearingClient` but only takes the direct player slot.
---
---@param playerSlot integer
---@return boolean result
function CBaseClient:IsProximityHearingClient( playerSlot ) end

--- [SERVER]
---
---@param playloadSize integer
function CBaseClient:SetMaxRoutablePayloadSize( playloadSize ) end

--- [SERVER]
---
---@param tick integer
function CBaseClient:UpdateAcknowledgedFramecount( tick ) end

--- [SERVER]
---
---@param tick integer
---@return boolean result
function CBaseClient:ShouldSendMessages( tick ) end

--- [SERVER]
function CBaseClient:UpdateSendState() end

--- [SERVER]
---
--- Sets the SignOnState for the given client.
--- Returns `true` on success.
---
--- > **NOTE**: This function does normally **not** directly set the SignOnState.
--- > Instead it calls the responsible function for the given SignOnState like for `SIGNONSTATE_PRESPAWN` it will call `SpawnPlayer` on the client.
--- > Set the `rawSet` to `true` if you want to **directly** set the SignOnState.
---
--- > **NOTE**: This function was formerly known as `HolyLib.SetSignOnState`
---
---@param signOnState integer
---@param spawnCount? integer Defaults to `0`.
---@param rawSet? boolean Defaults to `false`.
---@return boolean result
function CBaseClient:SetSignonState( signOnState, spawnCount, rawSet ) end

--- [SERVER]
---
---@param buffer holylib.bf_write
function CBaseClient:UpdateUserSettings( buffer ) end

--- [SERVER]
function CBaseClient:SendServerInfo() end

--- [SERVER]
---
--- Fills and sends the server info.
--- This function allows you to specify the client index that is sent out or it falls back to the normal one.
--- This function intentionally does not clamp the clientIndex when unsafe code is enabled because who knows what you may try- you got all the freedom.
---
---@param clientIndex? integer Defaults to `-1`.
function CBaseClient:FillServerInfo( clientIndex ) end

--- [SERVER]
function CBaseClient:SendSignonData() end

--- [SERVER]
function CBaseClient:SpawnPlayer() end

--- [SERVER]
function CBaseClient:ActivatePlayer() end

--- [SERVER]
---
--- Sets the new name of the client.
---
---@param name string
function CBaseClient:SetName( name ) end

--- [SERVER]
---
---@param convar string
---@param value string
function CBaseClient:SetUserCVar( convar, value ) end

--- [SERVER]
function CBaseClient:FreeBaselines() end

--- [SERVER]
---
--- Forces the client to go through a full update(also fires the gameevent).
function CBaseClient:OnRequestFullUpdate() end

--- [SERVER]
---
--- Sets the SteamID of the client.
--- Returns `true` on success.
---
--- > **NOTE**: Gmod seamingly has some backup code inside `CBaseClient::ProcessClientInfo`,
--- > that kicks a player with `Server connection error, please try again` if they don't have a valid steamid.
---
---@param steamID64 string
---@return boolean result
function CBaseClient:SetSteamID( steamID64 ) end

--- [SERVER]
---
--- Returns `true` if the client has a net channel.
--- This is useful for example, when working with fake clients and using `sv_stressbots`
---
---@return boolean result
function CBaseClient:HasNetChannel() end

--- [SERVER]
---
--- Moves the client it's called on into the target client.
--- This function calls HolyLib's internal `MoveCGameClientIntoCGameClient` which will move all values, patch the net channel, and reconnect the client.
---
---@param targetClient holylib.CBaseClient
function CBaseClient:MoveIntoClient( targetClient ) end

--- [SERVER]
---
--- Adds the client to the queue list, allowing the queue system to use the slot!
function CBaseClient:AddToQueueList() end

--- [SERVER]
---
--- Adds the client to the server list, treating it like a usable game client!
function CBaseClient:AddToServerList() end

--- [SERVER]
---
--- Removes the client from both server and queue list, meaning nothing will use the client!
--- Use this only if you know what you're doing, as if you lose track of the client, you'll leak memory!
--- A client once created is never meant to be deleted.
function CBaseClient:RemoveFromAllLists() end

--- [SERVER]
---
---@return boolean result
function CBaseClient:GetProcessingMessages() end

--- [SERVER]
---
---@return boolean result
function CBaseClient:GetClearedDuringProcessing() end

--- [SERVER]
---
---@return integer result
function CBaseClient:GetOutSequenceNr() end

--- [SERVER]
---
---@return integer result
function CBaseClient:GetInSequenceNr() end

--- [SERVER]
---
---@return integer result
function CBaseClient:GetOutSequenceNrAck() end

--- [SERVER]
---
---@return integer result
function CBaseClient:GetOutReliableState() end

--- [SERVER]
---
---@return integer result
function CBaseClient:GetInReliableState() end

--- [SERVER]
---
---@return number result
function CBaseClient:GetChokedPackets() end

--- [SERVER]
---
--- Returns the reliable stream used by net messages.
---
---@return holylib.bf_write result
function CBaseClient:GetStreamReliable() end

--- [SERVER]
---
--- Returns the unreliable stream used by net messages.
---
---@return holylib.bf_write result
function CBaseClient:GetStreamUnreliable() end

--- [SERVER]
---
--- Returns the voice stream used by the voice chat.
---
---@return holylib.bf_write result
function CBaseClient:GetStreamVoice() end

--- [SERVER]
---
---@return integer result
function CBaseClient:GetStreamSocket() end

--- [SERVER]
---
---@return integer result
function CBaseClient:GetMaxReliablePayloadSize() end

--- [SERVER]
---
---@return number result
function CBaseClient:GetLastReceived() end

--- [SERVER]
---
---@return number result
function CBaseClient:GetConnectTime() end

--- [SERVER]
---
---@return number result
function CBaseClient:GetClearTime() end

--- [SERVER]
---
---@return number result
function CBaseClient:GetTimeout() end

--- [SERVER]
---
--- Sets the time in seconds before the client is marked as timing out.
---
---@param seconds number
function CBaseClient:SetTimeout( seconds ) end

--- [SERVER]
---
--- Transmit any pending data to the client.
--- Returns `true` on success.
---
--- > **WARNING**: Transmitting data to the client causes the client's prediction to **reset and cause prediction errors!**.
---
--- Exampe usage of this function:
---
--- ```lua
--- concommand.Add("nukechannel", function(ply)
--- 	local string = ""
--- 	for k = 1, 65532 do
--- 		string = string .. "a"
--- 	end
--- 	util.AddNetworkString("Example")
--- 	for k = 1, 10 do
--- 		net.Start("Example", false)
--- 			net.WriteString(string)
--- 		net.Broadcast()
--- 		gameserver.GetClient(ply:EntIndex()-1):Transmit() -- Forces the message to be transmitted directly avoiding a overflow.
--- 	end
--- end)
--- ```
---
---@param onlyReliable? boolean Defaults to `false`.
---@param freeSubChannels? boolean Marks all sub channels as freed, allowing data to be transmitted again. This is a possible speed improvement, but fragments may get lost and cause issues, so it is unsafe. Defaults to `false`.
---@return boolean result
function CBaseClient:Transmit( onlyReliable, freeSubChannels ) end

--- [SERVER]
---
--- Processes all pending incoming net messages.
--- Returns `true` on success.
---
---@return boolean result
function CBaseClient:ProcessStream() end

--- [SERVER]
---
--- Resizes the specified buffer to the given size in bytes.
---
--- > **NOTE**: All data inside that stream is discarded, make sure everything was sent out.
---
--- Example usage of this function.
---
--- ```lua
--- concommand.Add("biggerBuffer", function(ply)
--- 	local client = gameserver.GetClient(ply:EntIndex()-1)
--- 	client:Transmit() -- Send everything out or else we lose data
--- 	client:SetMaxBufferSize(true, 524288) -- We resize the reliable stream
--- end)
--- ```
---
---@param reliable? boolean Defaults to `false`.
---@param bytes integer
---@param voice? boolean Defaults to `false`.
function CBaseClient:SetMaxBufferSize( reliable, bytes, voice ) end

--- [SERVER]
---
--- Returns the max routable payload size - this is the MTU for packets before they are fragmented!
---
---@return integer result
function CBaseClient:GetMaxRoutablePayloadSize() end

--- [SERVER]
---
--- Returns the time they connected.
---
---@return number result
function CBaseClient:GetTimeConnected() end

--- [SERVER]
---
--- Returns the average latency for the given flow. (Use the `gameserver.FLOW_` enums!)
---
---@param flow integer
---@return number result
function CBaseClient:GetAvgLatency( flow ) end

--- [SERVER]
---
--- Returns the average loss for the given flow. (Use the `gameserver.FLOW_` enums!)
---
---@param flow integer
---@return number result
function CBaseClient:GetAvgLoss( flow ) end

--- [SERVER]
---
--- This class inherits `CBaseClient`.
---
---@class holylib.CGameClient : holylib.CBaseClient
local CGameClient = {}

--- [SERVER]
---
--- Returns the a formatted string.
--- Format: `CGameClient [%i][%s]`
--- `%i` -> UserID
--- `%s` -> ClientName
---
--- > **IMPORTANT**: If it returns `CGameClient [EMPTY]` it means the object has no client connected and is basically **invalid** depending on `holylib_gameserver_rawclients` at the current time!
---
---@return string result
function CGameClient:__tostring() end

--- [SERVER]
---
--- This class represents a net channel.
---
---@class holylib.CNetChan
local CNetChan = {}

--- [SERVER]
---
--- Returns the a formatted string.
--- Format: `CNetChan [%s]`
--- `%s` -> channel name[ip:port]
---
---@return string result
function CNetChan:__tostring() end

--- [SERVER]
---
--- Internally implemented and will set the values into the lua table.
---
---@param key string
---@param value any
function CNetChan:__newindex( key, value ) end

--- [SERVER]
---
--- Internally searches first in the metatable table for the key.
--- If it fails to find it, it will search in the lua table before returning.
--- If you try to get multiple values from the lua table, just use `CNetChan:GetTable()`.
---
---@param key string
---@return any result
function CNetChan:__index( key ) end

--- [SERVER]
---
--- Returns the lua table of this object.
--- You can store variables into it.
---
---@return table result
function CNetChan:GetTable() end

--- [SERVER]
---
--- Returns `true` if the channel is still valid.
---
---@return boolean result
function CNetChan:IsValid() end

--- [SERVER]
---
---@param flow integer
---@return number result
function CNetChan:GetAvgLoss( flow ) end

--- [SERVER]
---
---@param flow integer
---@return number result
function CNetChan:GetAvgChoke( flow ) end

--- [SERVER]
---
---@param flow integer
---@return number result
function CNetChan:GetAvgData( flow ) end

--- [SERVER]
---
---@param flow integer
---@return number result
function CNetChan:GetAvgLatency( flow ) end

--- [SERVER]
---
---@param flow integer
---@return number result
function CNetChan:GetAvgPackets( flow ) end

--- [SERVER]
---
---@return integer result
function CNetChan:GetChallengeNr() end

--- [SERVER]
---
--- Returns the Address as `ip:port`
---
---@return string result
function CNetChan:GetAddress() end

--- [SERVER]
---
---@return integer result
function CNetChan:GetDataRate() end

--- [SERVER]
---
---@return integer result
function CNetChan:GetDropNumber() end

--- [SERVER]
function CNetChan:SetChoked() end

--- [SERVER]
---
--- If `true` files will be transmitted using a single fragment.
---
---@param backgroundTransmission? boolean Defaults to `false`.
function CNetChan:SetFileTransmissionMode( backgroundTransmission ) end

--- [SERVER]
---
--- If `true` enables compression.
---
---@param compression? boolean Defaults to `false`.
function CNetChan:SetCompressionMode( compression ) end

--- [SERVER]
---
---@param rate integer
function CNetChan:SetDataRate( rate ) end

--- [SERVER]
---
---@return number result
function CNetChan:GetTime() end

--- [SERVER]
---
---@return number result
function CNetChan:GetTimeConnected() end

--- [SERVER]
---
---@return number result
function CNetChan:GetTimeoutSeconds() end

--- [SERVER]
---
---@return number result
function CNetChan:GetTimeSinceLastReceived() end

--- [SERVER]
---
---@param flow integer
---@return integer result
function CNetChan:GetTotalData( flow ) end

--- [SERVER]
---
---@return integer result
function CNetChan:GetBufferSize() end

--- [SERVER]
---
---@return integer result
function CNetChan:GetProtocolVersion() end

--- [SERVER]
---
--- Returns the name of the channel.
--- Normally `ip:port`
---
---@return string result
function CNetChan:GetName() end

--- [SERVER]
---
--- Returns `true` if it's currently processing messages.
---
---@return boolean result
function CNetChan:GetProcessingMessages() end

--- [SERVER]
---
---@return boolean result
function CNetChan:GetClearedDuringProcessing() end

--- [SERVER]
---
---@return integer result
function CNetChan:GetOutSequenceNr() end

--- [SERVER]
---
---@return integer result
function CNetChan:GetInSequenceNr() end

--- [SERVER]
---
---@return integer result
function CNetChan:GetOutSequenceNrAck() end

--- [SERVER]
---
---@return integer result
function CNetChan:GetOutReliableState() end

--- [SERVER]
---
---@return integer result
function CNetChan:GetInReliableState() end

--- [SERVER]
---
---@return number result
function CNetChan:GetChokedPackets() end

--- [SERVER]
---
--- Returns the reliable stream used by net messages.
---
---@return holylib.bf_write result
function CNetChan:GetStreamReliable() end

--- [SERVER]
---
--- Returns the unreliable stream used by net messages.
---
---@return holylib.bf_write result
function CNetChan:GetStreamUnreliable() end

--- [SERVER]
---
--- Returns the voice stream used by the voice chat.
---
---@return holylib.bf_write result
function CNetChan:GetStreamVoice() end

--- [SERVER]
---
---@return integer result
function CNetChan:GetStreamSocket() end

--- [SERVER]
---
---@return integer result
function CNetChan:GetMaxReliablePayloadSize() end

--- [SERVER]
---
---@return number result
function CNetChan:GetLastReceived() end

--- [SERVER]
---
---@return number result
function CNetChan:GetConnectTime() end

--- [SERVER]
---
---@return number result
function CNetChan:GetClearTime() end

--- [SERVER]
---
---@return number result
function CNetChan:GetTimeout() end

--- [SERVER]
---
--- Sets the time in seconds before the channel is marked as timing out.
---
---@param seconds number
function CNetChan:SetTimeout( seconds ) end

--- [SERVER]
---
--- Transmit any pending data to the channel.
--- Returns `true` on success.
---
---@param onlyReliable? boolean Defaults to `false`.
---@param fragments? integer Defaults to `-1`.
---@param freeSubChannels? boolean Marks all sub channels as freed, allowing data to be transmitted again. This is a possible speed improvement, but fragments may get lost and cause issues, so it is unsafe. Defaults to `false`.
---@return boolean result
function CNetChan:Transmit( onlyReliable, fragments, freeSubChannels ) end

--- [SERVER]
---
--- Processes all pending incoming net messages.
--- Returns `true` on success.
---
---@return boolean result
function CNetChan:ProcessStream() end

--- [SERVER]
---
--- Resizes the specified buffer to the given size in bytes.
---
--- > **NOTE**: All data inside that stream is discarded, make sure everything was sent out.
---
---@param reliable? boolean Defaults to `false`.
---@param bytes integer
---@param voice? boolean Defaults to `false`.
function CNetChan:SetMaxBufferSize( reliable, bytes, voice ) end

--- [SERVER]
---
--- Shuts down the channel.
---
---@param reason? string Defaults to `nil`.
function CNetChan:Shutdown( reason ) end

--- [SERVER]
---
--- Sends out the given buffer as a message.
---
---@param buffer holylib.bf_write
---@param reliable? boolean Defaults to `false`.
function CNetChan:SendMessage( buffer, reliable ) end

--- [SERVER]
---
--- Sets the callback function for any incoming messages.
---
---@param callback fun( channel: holylib.CNetChan, buffer: holylib.bf_read, length: integer )
function CNetChan:SetMessageCallback( callback ) end

--- [SERVER]
---
--- Returns the current message callback function.
---
---@return function | nil result
function CNetChan:GetMessageCallback() end

--- [SERVER]
---
--- Sets the callback function for when the connection was established.
---
---@param callback fun( channel: holylib.CNetChan )
function CNetChan:SetConnectionStartCallback( callback ) end

--- [SERVER]
---
--- Returns the current connection start callback function.
---
---@return function | nil result
function CNetChan:GetConnectionStartCallback() end

--- [SERVER]
---
--- Sets the callback function for when a connection is closed.
---
---@param callback fun( channel: holylib.CNetChan, reason: string )
function CNetChan:SetConnectionClosingCallback( callback ) end

--- [SERVER]
---
--- Returns the current connection closing callback function.
---
---@return function | nil result
function CNetChan:GetConnectionClosingCallback() end

--- [SERVER]
---
--- Sets the callback function for when a connection has crashed.
---
---@param callback fun( channel: holylib.CNetChan, reason: string )
function CNetChan:SetConnectionCrashedCallback( callback ) end

--- [SERVER]
---
--- Returns the current connection crashed callback function.
---
---@return function | nil result
function CNetChan:GetConnectionCrashedCallback() end

--- [SERVER]
---
---@return number value1
---@return number value2
function CNetChan:GetRemoteFramerate() end

--- [SERVER]
---
--- Hooks added by the `gameserver` module, used through `hook.Add`.
---
---@class holylib.gameserver.hooks
local hooks = {}

--- [SERVER]
---
--- Called when the engine is about to change the client's SignonState.
---
---@param client holylib.CGameClient
---@param state integer
---@param spawnCount integer
---@return boolean | nil stop Return `true` to stop the engine.
function hooks.OnSetSignonState( client, state, spawnCount ) end

--- [SERVER]
---
--- Called when the client's net channel is overflowed.
---
--- ```lua
--- hook.Add("HolyLib:OnChannelOverflow", "Example", function(client)
--- 	local bf = client:GetStreamReliable()
--- 	file.Write("stream.txt", bf:GetData())
--- 	bf:Reset() -- Reset the stream, data may get lost, but the client won't be dropped
--- 	return true -- Return true to stop the engine from disconnecting the client
--- end)
--- ```
---
---@param client holylib.CGameClient
---@return boolean | nil stop Return `true` to stop the engine from disconnecting the client.
function hooks.OnChannelOverflow( client ) end

--- [SERVER]
---
--- Called **after** a player was moved to a different slot.
--- This happens when a player on a player slot above 128 tries to spawn.
---
--- Players above slot 128 are unstable and can only exist stably as a `CGameClient`.
--- If a `CBasePlayer` entity is created on a slot above 128, expect stability issues.
---
---@param oldPlayerSlot integer
---@param newPlayerSlot integer
function hooks.OnPlayerChangedSlot( oldPlayerSlot, newPlayerSlot ) end

--- [SERVER]
---
--- Called when a client disconnects.
---
---@param client holylib.CGameClient
function hooks.OnClientDisconnect( client ) end

--- [SERVER]
---
--- Called when a connectionless packet is received.
---
--- Won't be called if `holylib_gameserver_connectionlesspackethook` is set to `0`.
---
---@see holylib.gameserver.SendConnectionlessPacket
---
---@param buffer holylib.bf_read
---@param ip string
---@return boolean | nil handled Return `true` to mark the packet as handled.
function hooks.ProcessConnectionlessPacket( buffer, ip ) end

--- [SERVER]
---
--- Called when a client is marked as timing out.
---
---@param client holylib.CBaseClient
---@return number | nil extension Return a time in seconds to extend the timeout duration. `0` or below lets the client be kicked normally.
function hooks.OnClientTimeout( client ) end

--- [SERVER]
---
--- Called when a client attempts to execute a console command.
---
---@param client holylib.CGameClient
---@param command string
---@return boolean | nil block Return `true` to block/cancel execution.
function hooks.OnClientExecuteStringCommand( client, command ) end

--- [SERVER]
---
--- Called when the engine is searching for a free client slot.
---
---@param address string
---@return holylib.CBaseClient | nil client Return your own client, or `nil` to let the engine handle the selection.
function hooks.GetFreeClient( address ) end
