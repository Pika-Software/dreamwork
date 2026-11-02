---@class dreamwork.engine
local dreamwork_engine = dreamwork.engine

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
---
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

---@type fun( network_name: string ): integer | nil
local network_register = glua_util.AddNetworkString or debug_fempty

---@type fun( network_id: integer ): string | nil
local network_get_name = glua_util.NetworkIDToString or debug_fempty

---@type fun( network_name: string ): integer | nil
local network_get_id = glua_util.NetworkStringToID or debug_fempty

local full_header_size = network.HeaderSize

local header_size = full_header_size - 1 -- take unreliable flag

---@type table<string, integer>
local network_ids = {}

---@type table<integer, string>
local network_names = {}

---@type integer
local network_limit = (2 ^ header_size) - 1

setmetatable( network_ids, {
    __index = function( self, network_name )
        local network_id = network_get_id( network_name )

        if network_id == nil or network_id <= 0 or network_id > network_limit then
            return nil
        end

        network_names[ network_id ] = network_name
        self[ network_name ] = network_id
        return network_id
    end
} )

setmetatable( network_names, {
    __index = function( self, network_id )
        if network_id <= 0 or network_id > network_limit then
            return nil
        end

        local network_name = network_get_name( network_id )

        if network_name ~= nil then
            network_ids[ network_name ] = network_id
            self[ network_id ] = network_name
        end

        return network_name
    end
} )

--- [SHARED]
---
--- Get the names of all registered networks.
---
---@return string[] networks The names of the registered networks.
---@return integer network_count The number of registered networks.
---@nodiscard
function network.getNetworks()
    local networks, network_count = {}, 0

    for network_id = 1, network_limit, 1 do
        local network_name = network_get_name( network_id )
        if network_name == nil then
            break
        end

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
function network.getID( network_name )
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
        network_id = network_register( network_name )

        if network_id == nil then
            error( string_format( "Failed to register network '%s', unknown error.", network_name ), 2 )
        end

        network_names[ network_id ] = network_name
        network_ids[ network_name ] = network_id
    end

    return network_id
end

-- TODO: integration with https://github.com/RaphaelIT7/gmod-holylib/blob/main/example-scripts/networkchannel.lua


local net_WriteBool = glua_net.WriteBool
local net_ReadUInt = glua_net.ReadUInt
local net_ReadBit = glua_net.ReadBit

---@type table<string, fun( remaining_bits: integer, sender: ( garrysmod.Player | nil ), unreliable: boolean )>
local receivers = glua_net.Receivers or {}
glua_net.Receivers = receivers

--- Receivers are called as `fn( remaining_bits, sender, unreliable )`.
---
---@param remaining_bits integer
---@param sender garrysmod.Player
function glua_net.Incoming( remaining_bits, sender )
    local network_id = net_ReadUInt( header_size )
    local unreliable = net_ReadBit() == 1

    remaining_bits = remaining_bits - full_header_size

    local is_complete, block_size = hook_call( "dreamwork.network.message.incoming", network_id, unreliable, remaining_bits, sender )
    if is_complete == true then return end

    if block_size ~= nil then
        remaining_bits = remaining_bits - block_size
    end

    local network_name = network_names[ network_id ]
    if network_name == nil then
        if LUA_SERVER then
            dreamwork.Logger:warn( "Client '%s' was disconnected for sending an invalid network message. [ID: %d, %s]", sender:Nick(), network_id, unreliable and "UDP" or "TCP" )
            sender:Kick( string_format( "Server received an invalid network message. [ID: %d, %s]", network_id, unreliable and "UDP" or "TCP" ) )
        else
            dreamwork.Logger:warn( "Client received an invalid network message. [ID: %d, %s]", network_id, unreliable and "UDP" or "TCP" )
        end

        return
    end

    local fn = receivers[ string_lower( network_name ) ]
    if fn == nil then
        if LUA_SERVER then
            dreamwork.Logger:warn( "Client '%s' was disconnected for sending an unexpected network message. [ID: %d, Name: %s, %s]", sender:Nick(), network_id, network_name, unreliable and "UDP" or "TCP" )
            sender:Kick( string_format( "Server received an unexpected network message. [ID: %d, Name: %s, %s]", network_id, network_name, unreliable and "UDP" or "TCP" ) )
        else
            dreamwork.Logger:warn( "Client received an unexpected network message. [ID: %d, Name: %s, %s]", network_id, network_name, unreliable and "UDP" or "TCP" )
        end

        return
    end

    fn( remaining_bits, sender, unreliable )
end

if glua_net.Start ~= nil then

    ---@param fn fun( network_name: string, unreliable: boolean? )
    ---@param network_name string
    ---@param unreliable? boolean
    detour.attach( function( fn, network_name, unreliable )
        if network_ids[ network_name ] == nil then
            if LUA_SERVER then
                error( string_format( "Failed to start network message '%s', network does not exist.", network_name ), 2 )
            end

            dreamwork.Logger:error( "Client was disconnected for sending message using unregistered network. [Name: %s, %s]", network_name, (unreliable == true) and "UDP" or "TCP" )
            console_commandRun( "disconnect" )
            return
        end

        fn( network_name, unreliable )
        net_WriteBool( unreliable == true )
    end, glua_net, "Start" )

end
