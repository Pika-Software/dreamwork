local dreamwork_getUpTime = dreamwork.getUpTime
local dreamwork_engine = dreamwork.engine
local dreamwork_Logger = dreamwork.Logger

local engine_timer = dreamwork_engine.timer
local engine_hook = dreamwork_engine.hook
local hook_call = engine_hook.call

---@class dreamwork.std
local std = dreamwork.std

local debug = std.debug
local debug_fempty = debug.fempty

local math = std.math
local math_floor = math.floor

local time = std.time

local LUA_SERVER = std.LUA_SERVER
local LUA_CLIENT = std.LUA_CLIENT

do

    ---@class dreamwork.std
    ---@field SYSTEM_COUNTRY string The country code of the operating system. (ISO 3166-1 alpha-2)
    ---@field SYSTEM_HAS_BATTERY boolean `true` if the operating system has a battery, `false` if not.
    ---@field SYSTEM_BATTERY_LEVEL garrysmod.system.BatteryPower The battery level, from `0` to `100`.

    ---@type garrysmod.system
    local glua_system         = dreamwork_engine.requireLibrary( "system" )
    local system_BatteryPower = glua_system.BatteryPower

    std.SYSTEM_COUNTRY        = string.lower( (glua_system.GetCountry or debug_fempty)() or "eu" )

    std.SYSTEM_HAS_BATTERY    = false
    std.SYSTEM_BATTERY_LEVEL  = 100

    if system_BatteryPower ~= nil then

        ---@type number
        local previous_value

        engine_timer.create( "modules.engine.events.battery", 1.5, 0, function()
            local value = system_BatteryPower() or 255
            if previous_value == value then return end

            previous_value = value

            if value == 255 then
                std.SYSTEM_HAS_BATTERY = false
                std.SYSTEM_BATTERY_LEVEL = 100
                return
            end

            if value == 0 then
                std.SYSTEM_HAS_BATTERY = true
                std.SYSTEM_BATTERY_LEVEL = 0
                return
            end

            std.SYSTEM_HAS_BATTERY = true
            std.SYSTEM_BATTERY_LEVEL = math_floor( value / 100 )
        end, true )

    end

end

if LUA_CLIENT then

    local last_call = dreamwork_getUpTime()

    std.FRAME_TIME = 1 / 60
    std.FPS = 60

    engine_hook.catch( "PreRender", "modules.engine.events.frame.capture", function()
        local elapsed_time = dreamwork_getUpTime()

        local frame_time = elapsed_time - last_call
        last_call = elapsed_time

        std.FRAME_TIME = frame_time
        std.FPS = 1 / frame_time
    end, 1000 )

end

engine_hook.catch( "OnLuaError", "modules.engine.events.error", function( error_message, realm, stack, source )
    hook_call( "dreamwork.error.occurred", error_message, realm, stack, source, nil )
end, 1000 )

if LUA_SERVER then

    engine_hook.catch( "OnClientLuaError", "modules.engine.events.error", function( error_message, client, stack, source )
        hook_call( "dreamwork.error.occurred", error_message, "client", stack, source, client )
    end, 1000 )

end

---@param game_info dreamwork.engine.mounts.GameInfo
---@param is_mounted boolean
engine_hook.catch( "dreamwork.game.mount", "modules.engine.events.content.logs", function( game_info, is_mounted )
    dreamwork_Logger:debug( "Game '%s' (AppID: %d) was %s.", game_info.folder, game_info.depot, is_mounted and "mounted" or "unmounted" )
end )

---@param addon_info dreamwork.engine.mounts.AddonInfo
---@param is_mounted boolean
engine_hook.catch( "dreamwork.addon.mount", "modules.engine.events.content.logs", function( addon_info, is_mounted )
    dreamwork_Logger:debug( "Addon '%s' (ID: %s) was %s.", addon_info.title, addon_info.folder, is_mounted and "mounted" or "unmounted" )
end )

do

    local timer_name = dreamwork.Prefix .. "::ContentWatcher"

    local function perform_synchronization()
        dreamwork_Logger:debug( "Game content change triggered, synchronization..." )
        time.tick( "ms", false )

        local game_changes, addon_changes = engine_hook.call( "dreamwork.content.update" )

        if game_changes == 0 and addon_changes == 0 then
            dreamwork_Logger:debug( "No changes found, skipped." )
        else
            dreamwork_Logger:debug( "Synchronization finished with %d game(s) and %d addon(s) in %d ms.", game_changes, addon_changes, time.tick( "ms", false ) )
        end
    end

    engine_timer.create( timer_name, 0.5, 1, perform_synchronization )
    perform_synchronization()

    engine_hook.catch( "GameContentChanged", "modules.engine.events.content.update", function()
        engine_timer.start( timer_name )
    end, -1000 )

end

dreamwork_Logger:info( "%d game(s) and %d add-on(s) mounted to game.", dreamwork_engine.mounts.GameCount, dreamwork_engine.mounts.AddonCount )
