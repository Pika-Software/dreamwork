---@meta _

---@class Network : Object
---@field __class NetworkClass
---@field id integer
---@field name string
---@field receiver boolean
---@field receiving boolean
---@field sending boolean
---@field timeout number
local __Network = {}

---@class NetworkClass : Network
---@field __base Network
---@overload fun( name: string, can_receive?: boolean ): Network
Network = {}

---@class Network.Callback
---@field name string
---@field fn fun( network: Network, reader: buffer.Reader, index: integer, total: integer )
---@field once boolean
---@type table<Network, Network.Callback[]>
local receive_callbacks = {}

---@param fn fun( network: Network, reader: buffer.Reader, index: integer, total: integer )
---@param identifier? string
---@param once? boolean
function __Network:attach(fn, identifier, once) end

---@param identifier? string
function __Network:detach(identifier) end

---@param name string
---@return Network | nil object
---@protected
function Network:__new(name) end

---@return string
---@protected
function __Network:__tostring() end

---@param name string
---@protected
function __Network:__init(name, can_receive) end

---@param key string
---@protected
function __Network:__index(key) end

---@param key string
---@param value any
---@protected
function __Network:__newindex(key, value) end

---@class Network.Thread
---@field owner garrysmod.Player | nil
---@field value thread
---@field time number
---@type Network.Thread[]
local outgoing_activity = {}

---@param fn fun( network: Network, writer: buffer.Writer )
---@param client garrysmod.Player
---@return thread | nil
function __Network:transmit(fn, client) end

---@class Network.Transmission.Segment
---@field segments string[]>
---@field checksum checksum.CRC16
---@field total integer
