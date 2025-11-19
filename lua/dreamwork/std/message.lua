local dreamwork = _G.dreamwork

---@class dreamwork.std
local std = dreamwork.std

local LUA_SERVER = std.LUA_SERVER

local console_Command = std.console.Command

local receiver_prefix

if std.LUA_CLIENT then
    receiver_prefix = "client"
elseif LUA_SERVER then
    receiver_prefix = "server"
elseif std.LUA_MENU then
    receiver_prefix = "menu"
else
    receiver_prefix = "unknown"
end

local sender2receivers = {
    client = { "server", "menu" },
    server = { "client" },
    menu = { "client" }
}

local messages = {}


---@class dreamwork.std.Message : dreamwork.Object
---@field __class dreamwork.std.MessageClass
local Message = std.class.base( "Message" )

local description = "Internal side-realm message, do not use."

local engine_consoleCommandRegister = dreamwork.engine.consoleCommandRegister

---@protected
function Message:__init( name )
    self.name = name

    local internal_name = "dreamwork.inet." .. receiver_prefix .. "." .. name
    engine_consoleCommandRegister( internal_name, description, 16 )
    messages[ internal_name ] = self

    self.fns = {}

end

dreamwork.engine.consoleCommandCatch( function( sender, name, args )
    local message = messages[ name ]
    if message ~= nil then

        if not LUA_SERVER then
            sender = nil
        end

        local reader = std.pack.Reader()
        reader:open( std.encoding.base64.decode( args[ 1 ] ) )
        for _, fn in pairs( message.fns ) do
            reader:seek( 0 )
            fn( message, sender, reader )
        end

        return true
    end
end, 1 )

---
---@param fn fun( message: dreamwork.std.Message, sender: any, reader: dreamwork.std.pack.Reader )
function Message:attach( fn )
    self.fns[ #self.fns + 1 ] = fn
end

---@param data string
---@param pl Player?
function Message:send( data, pl, realm )
    local prefixes = sender2receivers[ receiver_prefix ]
    if prefixes == nil then
        return
    end

    local hex_data = std.encoding.base64.encode( data )

    if LUA_SERVER then
        pl:ConCommand( "dreamwork.inet." .. (realm or "client") .. "." .. self.name .. " " .. hex_data )
        return
    end

    for i = 1, #prefixes, 1 do
        console_Command.run( "dreamwork.inet." .. prefixes[ i ] .. "." .. self.name, hex_data )
    end
end

---@alias Message dreamwork.std.Message

---@class dreamwork.std.MessageClass : dreamwork.std.Message
---@field __base dreamwork.std.Message
---@overload fun( name: string ): dreamwork.std.Message
local MessageClass = std.class.create( Message )
std.Message = MessageClass
