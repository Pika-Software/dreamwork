---@class dreamwork.std
local std = dreamwork.std

---@diagnostic disable-next-line: undefined-field
local dofile = _G.include or _G.dofile

---@class dreamwork.std.gc
local gc = std.gc

local logger = dreamwork.Logger

-- dofile( "std/message.lua" )

dofile( "storage.lua" )
dofile( "factory.lua" )

do

    local loadbytecode = std.loadbytecode
    local loadstring = std.loadstring
    local file_read = std.fs.read

    --- [SHARED AND MENU]
    ---
    --- Loads a file as
    --- a lua code chunk in the specified environment
    --- and returns function as a compile result.
    ---
    ---@param file_path string The path to the file to read.
    ---@param is_bytecode boolean If `true`, the file will be loaded as a bytecode chunk.
    ---@param env table | nil The environment of compiled function.
    ---@return function | nil fn The compiled function.
    ---@return string | nil msg The error message.
    function std.loadfile( file_path, is_bytecode, env )
        local success, content = pcall( file_read, file_path )
        if success then
            if env == nil then
                env = getfenv( 2 )
            end

            if is_bytecode then
                return loadbytecode( content, env )
            else
                return loadstring( content, file_path, env )
            end
        else
            return nil, content
        end
    end

end

--[[

    TODO:

    FileReader     FileWriter       __init( file_path: string )
    file.Reader            file.Writer

    NetworkReader  NetworkWriter    __init( network_name: string )
    network.Reader         network.Writer
    net.Reader             net.Writer

    network.Message
    NetworkMessage
    net.Message

    net.MessageReader       net.MessageWriter

]]

dofile( "std/http.lua" )
dofile( "std/http.github.lua" )

dofile( "std/steam.lua" )
dofile( "std/steam.identifier.lua" )
dofile( "std/steam.workshop.lua" )

dofile( "std/addon.lua" )

dofile( "std/client.lua" )
dofile( "std/server.lua" )

if LUA_CLIENT_MENU then
    dofile( "std/menu.lua" )
    dofile( "std/window.lua" )
end

dofile( "std/level.lua" )

if LUA_CLIENT_SERVER then
    dofile( "std/physics.lua" )
    dofile( "std/model.lua" )

    dofile( "std/entity.lua" )
    -- dofile( "std/player.lua" ) -- deprecated, must be replaced in future with basic player controller

    dofile( "std/network.lua" )
end

-- TODO: NetTable class
dofile( "std/input.lua" )

if LUA_CLIENT_SERVER then
    dofile( "transport.lua" )
end

dreamwork.storage.init()

if LUA_CLIENT_SERVER then
    logger:info( "Preparing the transport to begin connection..." )
    dreamwork.transport.startup()
end

-- TODO: package manager start-up ( aka package loading )
