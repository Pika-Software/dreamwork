-- TODO: Globally replace all versions, steamids, url, etc. with their classes in dreamwork, e.g. std.URL, steam.Identifier
-- TODO: Add https://eprosync.github.io/interstellar-docs support

---@class dreamwork.std
---@field SYSTEM_COUNTRY string The country code of the operating system. (ISO 3166-1 alpha-2)
---@field SYSTEM_HAS_BATTERY boolean `true` if the operating system has a battery, `false` if not.
---@field SYSTEM_BATTERY_LEVEL integer The battery level, from `0` to `100`.
local std = dreamwork.std

---@diagnostic disable-next-line: undefined-field
local dofile = _G.include or _G.dofile

---@class dreamwork.std.gc
local gc = std.gc

local string = std.string

local time = std.time

local engine = dreamwork.engine
local engine_hookCatch = engine.hookCatch

local logger = dreamwork.Logger

-- dofile( "std/message.lua" )

dofile( "std/fs.lua" )
dofile( "std/sqlite.lua" )

dofile( "storage.lua" )
dofile( "factory.lua" )

do

    local changes_timeout = std.Timer( 0.5, 1, dreamwork.Prefix .. "::ContentWatcher" )

    local function perform_synchronization()
        logger:debug( "Game content change triggered, synchronization..." )
        time.tick( "ms", false )

        local game_changes, addon_changes = engine.hookCall( "GameContentUpdate" )

        if game_changes == 0 and addon_changes == 0 then
            logger:debug( "No changes found, skipped." )
        else
            logger:debug( "Synchronization finished with %d game(s) and %d addon(s) in %d ms.", game_changes, addon_changes, time.tick( "ms", false ) )
        end
    end

    changes_timeout:attach( perform_synchronization )
    perform_synchronization()

    engine_hookCatch( "GameContentChanged", function()
        changes_timeout:start()
    end, 1 )

end

dofile( "std/i18n.lua" )
dofile( "std/game.hooks.lua" )
dofile( "std/audio_stream.lua" )

-- https://github.com/willox/gmbc
if std.loadbinary( "gmbc" ) then
    logger:info( "'gmbc' was loaded & connected as LuaJIT bytecode compiler." )
else
    logger:warn( "'gmbc' is missing, bytecode compilation not available." )
end

do

    ---@diagnostic disable-next-line: undefined-field
    local gmbc_load_bytecode = _G.gmbc_load_bytecode
    local loadstring = std.loadstring
    local file_read = std.fs.read
    local pcall = std.pcall

    --- [SHARED AND MENU]
    ---
    --- Loads a string as
    --- a bytecode chunk in the specified environment
    --- and returns function as a compile result.
    ---
    ---@param bytecode string The luajit bytecode chunk.
    ---@param env table | nil The environment of compiled function.
    ---@return function | nil fn The compiled function.
    ---@return string | nil msg The error message.
    local function loadbytecode( bytecode, env )
        local success, result = pcall( gmbc_load_bytecode, bytecode )
        if success then
            setfenv( result, env or getfenv( 2 ) )
            return result, nil
        else
            return nil, result
        end
    end

    std.loadbytecode = loadbytecode

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

---@diagnostic disable-next-line: undefined-field
local glua_system = _G.system

if glua_system ~= nil then

    do

        local system_GetCountry = glua_system.GetCountry
        if system_GetCountry == nil then
            std.SYSTEM_COUNTRY = "gb"
        else
            function std_metatable.__indexes.SYSTEM_COUNTRY()
                local iso_3166_1_alpha_2 = string.lower( system_GetCountry() )
                std.SYSTEM_COUNTRY = iso_3166_1_alpha_2
                return iso_3166_1_alpha_2
            end
        end

    end

    if glua_system.BatteryPower ~= nil then

        local system_BatteryPower = glua_system.BatteryPower

        local battery_power = 0

        local function update_battery()
            if battery_power ~= system_BatteryPower() then
                battery_power = system_BatteryPower()
                if battery_power == 255 then
                    std.SYSTEM_HAS_BATTERY = false
                    std.SYSTEM_BATTERY_LEVEL = 100
                else
                    std.SYSTEM_HAS_BATTERY = true
                    std.SYSTEM_BATTERY_LEVEL = battery_power
                end
            end
        end

        update_battery()

        dreamwork.TickTimer1:attach( update_battery, "dreamwork::battery" )

    end

    if LUA_CLIENT_MENU then

        local system_HasFocus = glua_system.HasFocus
        if system_HasFocus ~= nil then

            ---@class dreamwork.std.window
            ---@field focus boolean `true` if the game's window has focus, `false` otherwise.
            local window = std.window

            local has_focus = system_HasFocus()
            window.focus = has_focus

            dreamwork.TickTimer0_05:attach( function()
                if has_focus ~= system_HasFocus() then
                    has_focus = not has_focus
                    window.focus = has_focus
                end
            end, "dreamwork::window_focus" )

        end

    end

end

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
