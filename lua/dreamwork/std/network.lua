
---@class dreamwork.std
local std = _G.dreamwork.std


--- [SHARED]
---
---
---
---@class dreamwork.std.Network : dreamwork.std.Object
---@field __class dreamwork.std.NetworkClass
local Network = std.class.base( "Network" )

---@alias Network dreamwork.std.Network

---@protected
function Network:__init( name )

end

function Network:attach( fn, identifier, once )

end

function Network:detach( identifier )

end


function Network:open()

end

function Network:close()

end

function Network:commit( target )

end

function Network:rollback()

end


--- [SHARED]
---
---
---
---@class dreamwork.std.NetworkClass : dreamwork.std.Network
---@field __base dreamwork.std.Network
---@overload fun( name: string ): dreamwork.std.Network
local NetworkClass = std.class.create( Network )
std.Network = NetworkClass


-- if std.LUA_SERVER then

--     local msg = std.Message( "test" )

--     _G.test_msg = msg

--     msg:attach( function( self, sender, reader )
--         print( "received", reader:readDouble(), "from", sender )
--     end )

--     timer.Simple( 0, function()
--         ---@diagnostic disable-next-line: param-type-mismatch
--         msg:send( "hello from server", Entity( 1 ) )
--     end )

-- else

--     local msg = std.Message( "test" )

--     _G.test_msg = msg

--     local writer = std.pack.Writer()
--     writer:open()
--     writer:writeDouble( math.pi )

--     msg:send( writer:commit() )

--     msg:attach( function( self, sender, reader )
--         print( "received", reader:read(), "from", sender )
--     end )


-- end
