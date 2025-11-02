local _G = _G
local dreamwork = _G.dreamwork

---@class dreamwork.std
local std = dreamwork.std

local LUA_CLIENT_MENU = std.LUA_CLIENT_MENU
local gc_setTableRules = std.debug.gc.setTableRules

---@type table<dreamwork.std.Client, Player>
local entities = {}
gc_setTableRules( entities, true, true )

---@type table<dreamwork.std.Client, string>
local names = {}
gc_setTableRules( names, true, false )

---@class dreamwork.std.Client : dreamwork.std.Object
local Client = std.class.base( "Client", true )

---@class dreamwork.std.ClientClass : dreamwork.std.Client
local ClientClass = std.class.create( Client )
-- std.Client = ClientClass

function Client:__init( name, steam_id )

end

function Client:runConsoleCommand()

end

function Client:getSteamIdentifier()

end

function ClientClass.getAll( ignore_bots, ignore_humans )

end

function ClientClass.findByName( name )

end

--- [SHARED AND MENU]
---
---@class dreamwork.std.client
local client = std.client or {}
std.client = client

function client.getAll()

end

-- client.getServerTime = client.getServerTime or _G.CurTime

if LUA_CLIENT_MENU then

    function client.getLocal()

    end

    local console = std.console
    local console_Command = console.Command

    --- [CLIENT AND MENU]
    ---
    --- Retry connection to last server.
    function client.retry()
        console_Command.run( "retry" )
    end

    if std.LUA_MENU then

        client.connect = _G.JoinServer or _G.permissions.Connect

        --- [CLIENT AND MENU]
        ---
        --- Disconnects the client from the server.
        ---
        function client.disconnect()
            std.menu.run( "Disconnect" )
        end

        client.isConnected = _G.IsInGame
        client.isConnecting = _G.IsInLoading

    else

        client.connect = _G.permissions.AskToConnect

        --- [CLIENT AND MENU]
        ---
        --- Disconnects the client from the server.
        ---
        function client.disconnect()
            console_Command.run( "disconnect" )
        end

        --- [CLIENT AND MENU]
        ---
        --- Checks if the client is connected to the server.
        ---
        --- NOTE: It always returns `true` on the client.
        ---@return boolean bool The `true` if connected, `false` if not.
        ---@diagnostic disable-next-line: duplicate-set-field
        function client.isConnected() return true end

        --- [CLIENT AND MENU]
        ---
        --- Checks if the client has connected to the server (looks at the loading screen).
        ---
        --- NOTE: It always returns `false` on the client.
        ---@return boolean bool The `true` if connecting, `false` if not.
        ---@diagnostic disable-next-line: duplicate-set-field
        function client.isConnecting() return false end

    end

    if client.connect == nil then

        --- [CLIENT AND MENU]
        ---
        --- Connects client to the specified server.
        ---
        ---@param address string? The address of the server. ( IP:Port like `127.0.0.1:27015` )
        ---@diagnostic disable-next-line: duplicate-set-field
        function client.connect( address )
            console_Command.run( "connect", address )
        end

    end

    --- [CLIENT AND MENU]
    ---
    --- Take a screenshot.
    ---
    ---@param quality integer The quality of the screenshot (0-100), only used if `useTGA` is `false`.
    ---@param file_name string The name of the screenshot.
    function client.screenshot( quality, file_name )
        if std.menu.visible then
            return false, "The menu is open, can't take a screenshot."
        end

        if file_name == nil then
            file_name = std.level.name
        end

        local files = std.fs.select( "/garrysmod/screenshots", file_name .. "*.jpg" )
        local last_one = files[ #files ]
        local screenshot_count = 0

        if last_one ~= nil then
            screenshot_count = ( std.tonumber( std.string.sub( std.path.splitExtension( last_one.name, false ), #file_name + 2 ), 10 ) or 0 ) + 1
        end

        file_name = std.string.format( "%s_%04d", file_name, screenshot_count )
        console_Command.run( "jpeg", file_name, quality or 90 )

        return true, "/garrysmod/screenshots/" .. file_name .. ".jpg"
    end

end
