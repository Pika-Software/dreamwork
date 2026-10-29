---@meta _

---@class Message : Object
---@field __class MessageClass
local __Message = {}

---@protected
function __Message:__init(name) end

---
---@param fn fun( message: Message, sender: any, reader: buffer.Reader )
function __Message:attach(fn) end

---@param data string
---@param pl garrysmod.Player?
function __Message:send(data, pl, realm) end

---@class MessageClass : Message
---@field __base Message
---@overload fun( name: string ): Message
Message = {}
