-- TODO: implement wrapper/library
--
-- ref: https://github.com/FredyH/GWSockets
--
-- ref: https://github.com/shockpast/gm_tungstenite
--
-- ref: https://github.com/thegrb93/StarfallEx/blob/master/lua/starfall/libs_cl/websocket.lua
--

local std = dreamwork.std

local class = std.class


---@class dreamwork.std.WebSocket : dreamwork.std.Object
---@field __class dreamwork.std.WebSocketClass
local WebSocket = class.base( "WebSocket", true, nil )

function WebSocket:__init( url )
    self.url = url
end

---@class dreamwork.std.WebSocketClass : dreamwork.std.WebSocket
---@field __base dreamwork.std.WebSocket
local WebSocketClass = class.create( WebSocket )
