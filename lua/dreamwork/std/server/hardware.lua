local glua_serverstat = serverstat

local std = dreamwork.std

local math = std.math
local math_floor = math.floor


local unit         = std.unit
local unit_convert = unit.convert


local KIB_TO_BYTE = unit_convert( 1, "KiB", "byte" )
local MIB_TO_BYTE = unit_convert( 1, "MiB", "byte" )


---@class dreamwork.std.server
local server = std.server


--- [SERVER]
---
--- The hardware library, reports CPU and memory usage of the server machine and process.
---
--- Requires [gmsv_serverstat](https://github.com/WilliamVenner/gmsv_serverstat), all functions return zeros without it.
---
---@class dreamwork.std.server.hardware
---@field available boolean `true` if `gmsv_serverstat` is installed, `false` otherwise. **READ-ONLY**
---@field physical_cores integer The number of physical CPU cores, `1` if unknown. **READ-ONLY**
---@field logical_cores integer The number of logical CPU cores ( hardware threads ), `1` if unknown. **READ-ONLY**
---@field total_memory integer The total system memory in bytes, `0` if unknown. **READ-ONLY**
local hardware  = {}
server.hardware = hardware


--- Converts the system memory value of `gmsv_serverstat` ( KiB / 1000, not MiB ) to bytes.
---@param value number
---@return integer bytes
local function system_bytes( value )
    return math_floor( value * 1000 + 0.5 ) * KIB_TO_BYTE
end


if glua_serverstat == nil or glua_serverstat.realtime == nil then

    hardware.available = false
    hardware.physical_cores = 1
    hardware.logical_cores = 1
    hardware.total_memory = 0

    local function zero()
        return 0
    end

    local function zeros()
        return 0, 0
    end

    hardware.getCPUUsage = zero
    hardware.getMemoryUsage = zeros

    return

end

hardware.available = true

do

    local system = glua_serverstat.AllSystem()
    hardware.physical_cores = system.PhysicalCPUs
    hardware.logical_cores = system.LogicalCPUs
    hardware.total_memory = system_bytes( system.SystemTotalMemory )

end

local realtime = glua_serverstat.realtime
local realtime_AllSystem = realtime.AllSystem
local realtime_AllProcess = realtime.AllProcess

do

    local serverstat_ProcessCPUUsage = glua_serverstat.ProcessCPUUsage

    --- [SERVER]
    ---
    --- Returns the CPU usage of the server process or the whole system.
    ---
    --- The process usage is measured since the previous call ( made from any addon ),
    --- blocks for ~1ms, the first call returns `0`, calls in the same frame return `0`
    --- and one spike to `1` was seen on an idle server, average a few samples for alerts.
    ---
    --- The system usage is updated every 250ms in the background,
    --- the first call starts the updater and the first sample reports `1`.
    ---
    ---@param system_wide boolean? `true` to get the usage of the whole system, `false` by default.
    ---@return number usage The CPU usage from `0` to `1` as a fraction of all logical cores, multiply by `hardware.logical_cores` to get it in cores.
    ---@nodiscard
    function hardware.getCPUUsage( system_wide )
        if system_wide then
            return realtime_AllSystem().CPUUsage * 0.01
        end

        return serverstat_ProcessCPUUsage() * 0.01
    end

end

--- [SERVER]
---
--- Returns the memory usage of the server process ( resident set size ) or the whole system.
---
--- Updated every 250ms in the background, the first call starts the updater.
---
---@param system_wide boolean? `true` to get the used memory of the whole system, `false` by default.
---@return integer used The used memory in bytes.
---@return integer available The available system memory in bytes.
---@nodiscard
function hardware.getMemoryUsage( system_wide )
    local system = realtime_AllSystem()
    if system_wide then
        return system_bytes( system.MemoryUsage ), system_bytes( system.AvailableMemory )
    end

    return realtime_AllProcess().MemoryUsage * MIB_TO_BYTE, system_bytes( system.AvailableMemory )
end
