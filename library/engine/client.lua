---@meta _

---@class client
client = {}

---@class Client : Object
local Instance = {}

---@class Client : Object
local Client = {}

---@class ClientClass : Client
local ClientClass = {}

function Client:__init(name, steam_id) end

function Client:runConsoleCommand() end

function Client:getSteamIdentifier() end

function ClientClass.getAll(ignore_bots, ignore_humans) end

function ClientClass.findByName(name) end

--- [SHARED AND MENU]
---
---@class client
client = {}

function client.getAll() end

function client.getLocal() end

--- [CLIENT AND MENU]
---
--- Retry connection to last server.
function client.retry() end

--- [CLIENT AND MENU]
---
--- Disconnects the client from the server.
---
function client.disconnect() end

--- [CLIENT AND MENU]
---
--- Checks if the client is connected to the server.
---
--- NOTE: It always returns `true` on the client.
---@return boolean bool The `true` if connected, `false` if not.
---@nodiscard
function client.isConnected() end

--- [CLIENT AND MENU]
---
--- Checks if the client has connected to the server (looks at the loading screen).
---
--- NOTE: It always returns `false` on the client.
---@return boolean bool The `true` if connecting, `false` if not.
---@nodiscard
function client.isConnecting() end

--- [CLIENT AND MENU]
---
--- Connects client to the specified server.
---
---@param address string? The address of the server. ( IP:Port like `127.0.0.1:27015` )
function client.connect(address) end

--- [CLIENT AND MENU]
---
--- Take a screenshot.
---
---@param quality integer The quality of the screenshot (0-100), only used if `useTGA` is `false`.
---@param file_name string The name of the screenshot.
function client.screenshot(quality, file_name) end
