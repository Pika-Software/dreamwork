---@meta _

--- [SHARED AND MENU]
---
--- The game library.
---
---@class game
---@field frame_time number The time it takes to run one frame in seconds. **Client-only**
---@field frames_per_second number The number of frames per second. **Client-only**
---@field tick_time number The measured time between ticks in seconds, averaged over half a second, the menu imitates a tick every frame.
---@field ticks_per_second number The measured number of ticks per second, averaged over half a second, the menu imitates a tick every frame.
---@field tick_count integer The id of the last processed tick, the menu counts imitated ticks. **READ-ONLY**
game = {}

--- [SHARED AND MENU]
---
--- Returns the time elapsed since the game was started, in seconds.
---
---@return number uptime The uptime of the game in seconds.
---@nodiscard
function game.getUpTime() end

--- [SHARED]
---
--- Gets the time scale of the game.
---
---@return number timescale The current time scale of the game.
---@nodiscard
function game.getTimeScale() end

--- [SHARED AND MENU]
---
--- Called every tick, after `game.tick_count` is updated, the menu imitates a tick every frame.
---
---@type Event
game.Tick = nil

--- [SHARED AND MENU]
---
--- Called when the content of a game is mounted or unmounted, after its `path` is updated in the virtual file system.
---
--- Arguments: `game: Game`, `is_mounted: boolean`.
---
---@type Event
game.Mount = nil

--- [SHARED]
---
--- Called when the game is shutting down.
---
---@type Event
game.ShutDown = nil

game.frames_per_second = 60

--- [CLIENT AND MENU]
---
--- Disconnects the client from the server.
---
function game.disconnect() end

--- [CLIENT AND MENU]
---
--- Checks if the client is connected to the server.
---
--- > **NOTE**: It always returns `true` on the client.
---
---@return boolean bool The `true` if connected, `false` if not.
---@nodiscard
function game.isConnected() end

--- [CLIENT AND MENU]
---
--- Checks if the client has connected to the server (looks at the loading screen).
---
--- NOTE: It always returns `false` on the client.
---@return boolean bool The `true` if connecting, `false` if not.
---@nodiscard
function game.isConnecting() end

--- [CLIENT AND MENU]
---
--- Connects client to the specified server.
---
---@param address string? The address of the server. ( IP:Port like `127.0.0.1:27015` )
function game.connect(address) end
