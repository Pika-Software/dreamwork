---@class dreamwork.engine
local dreamwork_engine = dreamwork.engine
local dreamwork_Logger = dreamwork.Logger

local engine_hook = dreamwork_engine.hook
local hook_call = engine_hook.call

local engine_console = dreamwork_engine.console
local console_commandRun = engine_console.commandRun

local detour = dreamwork.detour

local std = dreamwork.std

local debug = std.debug
local debug_fempty = debug.fempty

local string = std.string
local string_lower = string.lower
local string_format = string.format

local LUA_SERVER = std.LUA_SERVER


--- [SHARED]
---
--- Network message engine, wraps Garry's Mod `net` / `util` networking.
---
--- Registers named channels, maps them to IDs, and dispatches incoming packets
--- through ID or name receivers (taking priority over `net.Receivers`).
---
--- Each message header is `HeaderSize` bits: the network ID plus an unreliable flag.
--- Unregistered or unexpected traffic is kicked/logged unless a
--- `dreamwork.network.message.unhandled` hook handles it first.
---
---@class dreamwork.engine.network
---@field HeaderSize integer The size of the network header in bits.
local network = {}
dreamwork_engine.network = network

--- [SHARED]
---
--- unsigned short ( 2 byte / 16 bit / 0-65535, 0 is reserved )
---
--- wiki says that we have only 4095 slots...
--- i don't care, i will use absolute header limit
--- because f*ck you garry
---
--- it have additional bit for unreliable flag so it will be 17 bits in total
---
---@type integer
network.HeaderSize = 16 + 1

---@class garrysmod.util
local glua_util = dreamwork_engine.requireLibrary( "util" )

---@class garrysmod.net
local glua_net = dreamwork_engine.requireLibrary( "net" )

local net_Abort = glua_net.Abort or debug_fempty
local net_SendToServer = glua_net.SendToServer or debug_fempty
local net_Send, net_Broadcast = glua_net.Send or debug_fempty, glua_net.Broadcast

local net_ReadBit, net_WriteBit = glua_net.ReadBit or function() return 0 end, glua_net.WriteBit or debug_fempty
local net_ReadInt, net_WriteInt = glua_net.ReadInt or function() return 0 end, glua_net.WriteInt or debug_fempty
local net_ReadUInt, net_WriteUInt = glua_net.ReadUInt or function() return 0 end, glua_net.WriteUInt or debug_fempty

local net_ReadData, net_WriteData = glua_net.ReadData or function() return "" end, glua_net.WriteData or debug_fempty

---@alias dreamwork.engine.network.Receiver fun( remaining_bits: integer, sender: ( garrysmod.Player | nil ), unreliable: boolean )

---@type table<string, dreamwork.engine.network.Receiver>
local receivers = glua_net.Receivers or {}
glua_net.Receivers = receivers

---@type fun( network_name: string ): integer | nil
local util_AddNetworkString = glua_util.AddNetworkString or debug_fempty

---@type fun( network_id: integer ): string | nil
local util_NetworkIDToString = glua_util.NetworkIDToString or debug_fempty

---@type fun( network_name: string ): integer | nil
local util_NetworkStringToID = glua_util.NetworkStringToID or debug_fempty

local FULL_HEADER_SIZE = network.HeaderSize

local HEADER_SIZE = FULL_HEADER_SIZE - 1 -- take unreliable flag

---@type table<string, integer>
local network_ids = {}

---@type table<integer, string>
local network_names = {}

---@type integer
local NETWORK_LIMIT = (2 ^ HEADER_SIZE) - 1

setmetatable( network_ids, {
    __index = function( self, network_name )
        local network_id = util_NetworkStringToID( network_name )

        if network_id == nil or network_id <= 0 or network_id > NETWORK_LIMIT then
            return nil
        end

        network_names[ network_id ] = network_name
        self[ network_name ] = network_id
        return network_id
    end
} )

setmetatable( network_names, {
    __index = function( self, network_id )
        if network_id <= 0 or network_id > NETWORK_LIMIT then
            return nil
        end

        local network_name = util_NetworkIDToString( network_id )

        if network_name ~= nil then
            network_ids[ network_name ] = network_id
            self[ network_id ] = network_name
        end

        return network_name
    end
} )

function network.readBit()
    return net_ReadBit() == 1
end

network.writeBit = net_WriteBit

network.readInt = net_ReadInt
network.writeInt = net_WriteInt

network.readUInt = net_ReadUInt
network.writeUInt = net_WriteUInt

network.readData = net_ReadData
network.writeData = net_WriteData

network.readFloat = glua_net.ReadFloat or function() return 0.0 end
network.writeFloat = glua_net.WriteFloat or debug_fempty

network.readDouble = glua_net.ReadDouble or function() return 0.0 end
network.writeDouble = glua_net.WriteDouble or debug_fempty

network.readString = glua_net.ReadString or function() return "" end
network.writeString = glua_net.WriteString or debug_fempty

if LUA_SERVER then
    network.broadcast = net_Broadcast
    network.send = net_Send
else
    network.send = net_SendToServer
end

network.abort = net_Abort

--- [SHARED]
---
--- Get the names of all registered networks.
---
---@return string[] networks The names of the registered networks.
---@return integer network_count The number of registered networks.
---@nodiscard
function network.getNetworks()
    ---@type string[]
    local networks = {}
    local network_count = 0

    for network_id = 1, NETWORK_LIMIT, 1 do
        local network_name = util_NetworkIDToString( network_id )
        if network_name == nil then break end

        network_ids[ network_name ] = network_id
        network_names[ network_id ] = network_name

        network_count = network_count + 1
        networks[ network_count ] = network_name
    end

    return networks, network_count
end

--- [SHARED]
---
--- Checks if the network exists.
---
---@param network_name string The name of the network.
---@return boolean exists `true` if the network exists, `false` otherwise.
---@nodiscard
function network.exists( network_name )
    return network_ids[ network_name ] ~= nil
end

--- [SHARED]
---
--- Get the ID of the network from its name.
---
---@param network_name string The name of the network.
---@return integer | nil network_id The ID of the network, or `nil` if the network does not exist.
---@nodiscard
function network.getId( network_name )
    return network_ids[ network_name ]
end

--- [SHARED]
---
--- Get the name of the network from its ID.
---
---@param network_id integer The ID of the network message.
---@return string | nil network_name The name of the network message, or `nil` if the network message does not exist.
---@nodiscard
function network.getName( network_id )
    return network_names[ network_id ]
end

--- [SHARED]
---
--- Register a new network message or returns the ID of an existing one.
---
---@param network_name string The name of the network message.
---@return integer network_id The ID of the network message.
function network.register( network_name )
    local network_id = network_ids[ network_name ]
    if network_id == nil then
        if not LUA_SERVER then
            error( "Networks can only be registered on the server.", 2 )
        end

        ---@type integer
        ---@diagnostic disable-next-line: assign-type-mismatch
        network_id = util_AddNetworkString( network_name )

        if network_id == nil then
            error( string_format( "Failed to register network '%s', unknown error.", network_name ), 2 )
        end

        network_names[ network_id ] = network_name
        network_ids[ network_name ] = network_id
    end

    return network_id
end

-- TODO: integration with https://github.com/RaphaelIT7/gmod-holylib/blob/main/example-scripts/networkchannel.lua

---@type table<integer, dreamwork.engine.network.Receiver>
local id_receivers = {}

---@type table<string, dreamwork.engine.network.Receiver>
local name_receivers = {}

--- [SHARED]
---
--- Sets the receiver of the network by its ID.
---
--- Takes priority over receivers from `net.Receive`.
---
---@param network_id integer | string The ID of the network.
---@param fn dreamwork.engine.network.Receiver | nil The receiver, `nil` to remove it.
function network.receiveById( network_id, fn )
    id_receivers[ network_id ] = fn
end

---@param name string
---@param fn dreamwork.engine.network.Receiver | nil
function network.receiveByName( name, fn )
    name_receivers[ string_lower( name ) ] = fn
end

---@param network_id integer
---@param network_name string | nil
---@param reason "unknown" | "unexpected"
---@param unreliable boolean
---@param remaining_bits integer
---@param sender garrysmod.Player | nil
local function message_unhandled( network_id, network_name, reason, unreliable, remaining_bits, sender )
    if hook_call( "dreamwork.network.message.unhandled", network_id, network_name, reason, unreliable, remaining_bits, sender ) then return end

    local protocol = unreliable and "UDP" or "TCP"

    if reason == "unknown" then
        if LUA_SERVER then
            ---@cast sender garrysmod.Player
            dreamwork_Logger:warn( "Client '%s' was disconnected for sending an invalid network message. [ID: %d, %s]", sender:Nick(), network_id, protocol )
            sender:Kick( string_format( "Server received an invalid network message. [ID: %d, %s]", network_id, protocol ) )
        else
            dreamwork_Logger:warn( "Client received an invalid network message. [ID: %d, %s]", network_id, protocol )
        end
    elseif LUA_SERVER then
        ---@cast sender garrysmod.Player
        dreamwork_Logger:warn( "Client '%s' was disconnected for sending an unexpected network message. [ID: %d, Name: %s, %s]", sender:Nick(), network_id, network_name, protocol )
        sender:Kick( string_format( "Server received an unexpected network message. [ID: %d, Name: %s, %s]", network_id, network_name, protocol ) )
    else
        dreamwork_Logger:warn( "Client received an unexpected network message. [ID: %d, Name: %s, %s]", network_id, network_name, protocol )
    end
end

--- Receivers are called as `fn( remaining_bits, sender, unreliable )`.
---
---@param remaining_bits integer
---@param sender garrysmod.Player | nil
function glua_net.Incoming( remaining_bits, sender )
    local network_id = net_ReadUInt( HEADER_SIZE )
    local unreliable = net_ReadBit() == 1

    remaining_bits = remaining_bits - FULL_HEADER_SIZE

    if hook_call( "dreamwork.network.message.incoming", network_id, unreliable, remaining_bits, sender ) ~= nil then return end

    local fn = id_receivers[ network_id ]
    if fn == nil then
        local network_name = network_names[ network_id ]
        if network_name == nil then
            message_unhandled( network_id, nil, "unknown", unreliable, remaining_bits, sender )
            return
        end

        local lowered_name = string_lower( network_name )

        fn = name_receivers[ lowered_name ] or receivers[ lowered_name ]
        if fn == nil then
            message_unhandled( network_id, lowered_name, "unexpected", unreliable, remaining_bits, sender )
            return
        end
    end

    fn( remaining_bits, sender, unreliable )
end

if glua_net.Start == nil then
    network.start = debug_fempty
else

    ---@param fn fun( network_name: string, unreliable: boolean? )
    ---@param network_name string
    ---@param unreliable boolean?
    detour.attach( function( fn, network_name, unreliable )
        if network_ids[ network_name ] == nil then
            if LUA_SERVER then
                error( string_format( "Failed to start network message '%s', network does not exist.", network_name ), 2 )
            end

            dreamwork_Logger:error( "Client was disconnected for sending message using unregistered network. [Name: %s, %s]", network_name, (unreliable == true) and "UDP" or "TCP" )
            console_commandRun( "disconnect" )
            return
        end

        fn( network_name, unreliable )
        net_WriteBit( unreliable == true )
    end, glua_net, "Start" )

    network.start = glua_net.Start

end
