local dreamwork_getUpTime = dreamwork.getUpTime

local dreamwork_engine = dreamwork.engine
local engine_hook = dreamwork_engine.hook

local vfs = dreamwork.vfs
local vfs_isFile = vfs.isFile
local vfs_watch = vfs.watch
local vfs_unwatch = vfs.unwatch

---@type garrysmod.engine
local glua_engine = dreamwork_engine.requireLibrary( "engine" )

---@type garrysmod.game
local glua_game = dreamwork_engine.requireLibrary( "game" )

---@class dreamwork.std
local std = dreamwork.std

local debug = std.debug
local debug_fempty = debug.fempty

local console = std.console
local console_Command = console.Command
local console_Variable = console.Variable

local uuid = std.uuid
local uuid_unique = uuid.unique

local futures = std.futures
local futures_sleep = futures.sleep

local menu = std.menu

local Event = std.Event
local Game_get = std.Game.get

local LUA_CLIENT = std.LUA_CLIENT
local LUA_SERVER = std.LUA_SERVER
local LUA_MENU = std.LUA_MENU


--- [SHARED AND MENU]
---
--- The game library.
---
--- ```lua
--- print( game.getTimeScale() ) -- 1
--- ```
---
---@class dreamwork.std.game
---@field frame_time number The time it takes to run one frame in seconds. **Client-only**
---@field frames_per_second number The number of frames per second. **Client-only**
---@field tick_time number The measured time between ticks in seconds, averaged over half a second, the menu imitates a tick every frame.
---@field ticks_per_second number The measured number of ticks per second, averaged over half a second, the menu imitates a tick every frame.
---@field tick_count integer The id of the last processed tick, the menu counts imitated ticks. **READ-ONLY**
local game = {}
std.game = game

--- [SHARED AND MENU]
---
--- Returns the time elapsed since the game was started, in seconds.
---
---@return number uptime The uptime of the game in seconds.
---@nodiscard
game.getUpTime = dreamwork.getUpTime

if LUA_CLIENT or LUA_SERVER then

    local game_GetTimeScale = glua_game.GetTimeScale or function() return 1 end
    local host_timescale = console_Variable.get( "host_timescale", "number" )

    --- [SHARED]
    ---
    --- Gets the time scale of the game.
    ---
    ---@return number timescale The current time scale of the game.
    ---@nodiscard
    function game.getTimeScale()
        return host_timescale.value * game_GetTimeScale()
    end

    if LUA_SERVER then
        game.setTimeScale = glua_game.SetTimeScale or debug_fempty
    end

end

do

    local engine_TickCount = glua_engine.TickCount

    if engine_TickCount == nil then
        local tick_count = 0

        function engine_TickCount()
            tick_count = tick_count + 1
            return tick_count + 1
        end
    end

    local window_start = dreamwork_getUpTime()
    local window_ticks = 0

    --- [SHARED AND MENU]
    ---
    --- Called every tick, after `game.tick_count` is updated, the menu imitates a tick every frame.
    ---
    local Tick = Event( "game.Tick" )
    game.Tick = Tick

    -- ticks can run back to back while the engine catches up,
    -- so the rate is measured over a window instead of a single tick
    engine_hook.catch( "Tick", "std.game.tick.capture", function()
        game.tick_count = engine_TickCount()
        window_ticks = window_ticks + 1

        local now = dreamwork_getUpTime()
        local elapsed = now - window_start

        if elapsed >= 0.5 then
            game.tick_time = elapsed / window_ticks
            game.ticks_per_second = window_ticks / elapsed

            window_start, window_ticks = now, 0
        end

        return Tick:call()
    end, 1000 )

    local tick_time = (glua_engine.TickInterval or debug_fempty)() or (1 / 60)

    game.tick_time = tick_time
    game.ticks_per_second = 1 / tick_time
    game.tick_count = engine_TickCount()

end

do

    --- [SHARED AND MENU]
    ---
    --- Called when the content of a game is mounted or unmounted, after its `path` is updated in the virtual file system.
    ---
    --- Arguments: `game: dreamwork.std.Game`, `is_mounted: boolean`.
    ---
    local Mount = Event( "game.Mount" )
    game.Mount = Mount

    ---@param game_info dreamwork.engine.mounts.GameInfo
    ---@param is_mounted boolean
    engine_hook.catch( "dreamwork.game.mount", "std.game.mount", function( game_info, is_mounted )
        -- games removed from the engine list are no longer supported
        local game_object = Game_get( game_info.depot )
        if game_object ~= nil then
            return Mount( game_object, is_mounted )
        end
    end )

end

if LUA_CLIENT or LUA_SERVER then

    game.getAbsoluteFrameTime = glua_engine.AbsoluteFrameTime

    --- [SHARED]
    ---
    --- Called when the game is shutting down.
    ---
    local ShutDown = Event( "game.ShutDown" )
    engine_hook.catch( "ShutDown", "std.game.shutdown", ShutDown, 2 )
    game.ShutDown = ShutDown

    -- game.getFrameNumber = FrameNumber

end

if LUA_CLIENT or LUA_MENU then

    local last_call = dreamwork_getUpTime()

    game.frame_time = 1 / 60
    game.frames_per_second = 60

    engine_hook.catch( "Think", "std.game.frame.capture", function()
        local elapsed_time = dreamwork_getUpTime()

        local frame_time = elapsed_time - last_call
        last_call = elapsed_time

        game.frame_time = frame_time
        game.frames_per_second = 1 / frame_time
    end, 1000 )

end

if LUA_CLIENT or LUA_MENU then

    if LUA_MENU then

        game.connect = JoinServer or dreamwork_engine.requireLibrary( "permissions" ).Connect

        --- [CLIENT AND MENU]
        ---
        --- Disconnects the client from the server.
        ---
        function game.disconnect()
            menu.run( "Disconnect" )
        end

        game.isConnected = IsInGame
        game.isConnecting = IsInLoading

    else

        game.connect = dreamwork_engine.requireLibrary( "permissions" ).AskToConnect

        --- [CLIENT AND MENU]
        ---
        --- Disconnects the client from the server.
        ---
        function game.disconnect()
            console_Command.run( "disconnect" )
        end

        --- [CLIENT AND MENU]
        ---
        --- Checks if the client is connected to the server.
        ---
        --- > **NOTE**: It always returns `true` on the client.
        ---
        ---@return boolean bool The `true` if connected, `false` if not.
        ---@nodiscard
        function game.isConnected() return true end

        --- [CLIENT AND MENU]
        ---
        --- Checks if the client has connected to the server (looks at the loading screen).
        ---
        --- NOTE: It always returns `false` on the client.
        ---@return boolean bool The `true` if connecting, `false` if not.
        ---@nodiscard
        function game.isConnecting() return false end

    end

    if game.connect == nil then

        --- [CLIENT AND MENU]
        ---
        --- Connects client to the specified server.
        ---
        ---@param address string? The address of the server. ( IP:Port like `127.0.0.1:27015` )
        function game.connect( address )
            console_Command.run( "connect", address )
        end

    end

    local SCREENSHOT_DIRECTORY = "/garrysmod/screenshots/"

    --- Seconds `game.screenshot` waits for the engine to write the file.
    local SCREENSHOT_TIMEOUT = 5

    --- Seconds between the checks of the screenshot file.
    local SCREENSHOT_POLL_INTERVAL = 0.05

    ---@param uuid_str string
    ---@return boolean
    local function is_free( uuid_str )
        return not vfs_isFile( SCREENSHOT_DIRECTORY .. uuid_str .. ".jpg" )
    end

    --- [CLIENT AND MENU]
    ---
    --- Takes a JPEG screenshot via the `jpeg` console command and saves it to `/garrysmod/screenshots/` under a unique UUID file name.
    ---
    --- Waits until the engine writes the file, it takes a few frames after the command.
    ---
    --- > **NOTE**: On the client it fails while the main menu is open, because the screenshot would capture the menu instead of the game.
    ---
    ---@param quality integer? The JPEG quality, from `1` to `100`. Defaults to `90`.
    ---@return boolean success `true` if the screenshot was taken, `false` if the main menu is open or the file did not appear in time.
    ---@return string path_or_error The path of the screenshot file on success, or the error message on failure.
    ---@async
    function game.screenshot( quality )
        if LUA_CLIENT and menu.visible then
            return false, "The menu is open, can't take a screenshot."
        end

        local file_name = uuid_unique( is_free )
        local file_path = SCREENSHOT_DIRECTORY .. file_name .. ".jpg"

        -- the engine writes the file outside of `vfs`, only a watch makes it visible
        vfs_watch( file_path )
        console_Command.run( "jpeg", file_name, quality or 90 )

        local deadline = dreamwork_getUpTime() + SCREENSHOT_TIMEOUT

        -- the command is queued and the file is written a few frames later (3 frames in the menu),
        -- `futures.sleep( 0 )` can resume within the same frame, before the watch had a chance to see it
        ::wait_for_file::

        futures_sleep( SCREENSHOT_POLL_INTERVAL )

        if vfs_isFile( file_path ) then
            vfs_unwatch( file_path )
            return true, file_path
        end

        if dreamwork_getUpTime() < deadline then
            goto wait_for_file
        end

        vfs_unwatch( file_path )
        return false, "The screenshot file was not written in time."
    end

end

-- TODO: complete the library

-- if LUA_CLIENT then
--     game.getTimeoutInfo = GetTimeoutInfo
-- end

-- if LUA_CLIENT or LUA_SERVER then
--     game.getDifficulty = glua_game.GetSkillLevel
-- end

-- if LUA_SERVER then
--     game.setDifficulty = game.setDifficulty or glua_game.SetSkillLevel
-- end
