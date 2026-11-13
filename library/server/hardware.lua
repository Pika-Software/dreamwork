---@meta _

--- [SERVER]
---
--- The hardware library, reports CPU and memory usage of the server machine and process.
---
--- Requires [gmsv_serverstat](https://github.com/WilliamVenner/gmsv_serverstat), all functions return zeros without it.
---
---@class server.hardware
---@field available boolean `true` if `gmsv_serverstat` is installed, `false` otherwise. **READ-ONLY**
---@field physical_cores integer The number of physical CPU cores, `1` if unknown. **READ-ONLY**
---@field logical_cores integer The number of logical CPU cores ( hardware threads ), `1` if unknown. **READ-ONLY**
---@field total_memory integer The total system memory in bytes, `0` if unknown. **READ-ONLY**
server.hardware = {}

server.hardware.available = false

server.hardware.physical_cores = 1

server.hardware.logical_cores = 1

server.hardware.total_memory = 0

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
function server.hardware.getCPUUsage(system_wide) end

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
function server.hardware.getMemoryUsage(system_wide) end
