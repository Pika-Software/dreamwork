---@meta gm_serverstat


--- [SERVER]
---
--- Resource usage of the system and the server process, returned by `serverstat.All`.
---
---@class serverstat.All : serverstat.System, serverstat.Process

--- [SERVER]
---
--- Resource usage of the system, returned by `serverstat.AllSystem`.
---
---@class serverstat.System
---@field SystemCPUUsage number The system CPU usage in percents.
---@field SystemMemoryUsage number The used system memory in KiB / 1000.
---@field SystemTotalMemory number The total system memory in KiB / 1000.
---@field SystemAvailableMemory number The available system memory in KiB / 1000.
---@field PhysicalCPUs integer The number of physical CPU cores, `0` if unknown.
---@field LogicalCPUs integer The number of logical CPU cores ( hardware threads ).

--- [SERVER]
---
--- Resource usage of the server process, returned by `serverstat.AllProcess`.
---
---@class serverstat.Process
---@field ProcessCPUUsage number The process CPU usage in percents of all logical cores.
---@field ProcessMemoryUsage number The process memory usage in MiB.

--- [SERVER]
---
--- Resource usage of the system and the server process, returned by `serverstat.realtime.All`.
---
---@class serverstat.realtime.All
---@field System serverstat.realtime.System
---@field Process serverstat.realtime.Process

--- [SERVER]
---
--- Resource usage of the system, returned by `serverstat.realtime.AllSystem`.
---
---@class serverstat.realtime.System
---@field CPUUsage number The system CPU usage in percents.
---@field MemoryUsage number The used system memory in KiB / 1000.
---@field AvailableMemory number The available system memory in KiB / 1000.

--- [SERVER]
---
--- Resource usage of the server process, returned by `serverstat.realtime.AllProcess`.
---
---@class serverstat.realtime.Process
---@field CPUUsage number The process CPU usage in percents of all logical cores, broken ( often `0` ).
---@field MemoryUsage number The process memory usage in MiB.

--- [SERVER]
---
--- System and process resource usage from the [gmsv_serverstat](https://github.com/WilliamVenner/gmsv_serverstat) binary module, based on [sysinfo](https://github.com/GuillaumeGomez/sysinfo).
---
--- Available after `require( "serverstat" )`.
---
--- Units differ from the README: CPU usage is in percents ( `0..100` ), not `0..1`,
--- and system memory is in KiB / 1000 ( sysinfo kB / 1024 ), not MiB.
---
--- Some functions block the main thread while gathering the data, some only on the first call,
--- and CPU usage is `0` on the first call and cached for 200ms; use `serverstat.async` or `serverstat.realtime` in hot code.
---
--- ```lua
--- require( "serverstat" )
--- local system = serverstat.realtime.AllSystem()
--- print( system.CPUUsage .. "%", system.MemoryUsage, system.AvailableMemory )
--- ```
---
---@class serverstat
serverstat = {}

--- [SERVER]
---
--- Returns the CPU usage of the server process since the previous call ( made from any addon ).
---
--- Blocks for ~1ms, the first call returns `0`, calls in the same frame return `0`.
---
---@return number usage The CPU usage in percents of all logical cores.
---@nodiscard
function serverstat.ProcessCPUUsage() end

--- [SERVER]
---
--- Returns the memory usage ( resident set size ) of the server process.
---
---@return number usage The used process memory in MiB.
---@nodiscard
function serverstat.ProcessMemoryUsage() end

--- [SERVER]
---
--- Returns the CPU usage of the whole system.
---
---@return number usage The CPU usage in percents.
---@nodiscard
function serverstat.SystemCPUUsage() end

--- [SERVER]
---
--- Returns the used memory of the whole system.
---
---@return number used The used system memory in KiB / 1000.
---@nodiscard
function serverstat.SystemMemoryUsage() end

--- [SERVER]
---
--- Returns the total memory installed in the system.
---
---@return number total The total system memory in KiB / 1000.
---@nodiscard
function serverstat.SystemTotalMemory() end

--- [SERVER]
---
--- Returns the available memory of the whole system.
---
---@return number available The available system memory in KiB / 1000.
---@nodiscard
function serverstat.SystemAvailableMemory() end

--- [SERVER]
---
--- Returns the number of **logical** CPU cores.
---
--- Swapped with `serverstat.LogicalCPUs` by a module bug, `serverstat.AllSystem().PhysicalCPUs` is correct.
---
---@return integer count The number of logical CPU cores.
---@nodiscard
function serverstat.PhysicalCPUs() end

--- [SERVER]
---
--- Returns the number of **physical** CPU cores, `0` if unknown.
---
--- Swapped with `serverstat.PhysicalCPUs` by a module bug, `serverstat.AllSystem().LogicalCPUs` is correct.
---
---@return integer count The number of physical CPU cores.
---@nodiscard
function serverstat.LogicalCPUs() end

--- [SERVER]
---
--- Returns all resource usage of the system and the server process.
---
---@return serverstat.All data A new flat table keyed by the getter names.
---@nodiscard
function serverstat.All() end

--- [SERVER]
---
--- Returns all resource usage of the system.
---
---@return serverstat.System data A new table keyed by the getter names.
---@nodiscard
function serverstat.AllSystem() end

--- [SERVER]
---
--- Returns all resource usage of the server process.
---
---@return serverstat.Process data A new table keyed by the getter names.
---@nodiscard
function serverstat.AllProcess() end

--- [SERVER]
---
--- Non-blocking versions of the `serverstat` getters.
---
--- The data is gathered on a worker thread and passed to the callback on the main thread,
--- with the same value and units as the blocking version.
---
---@class serverstat.async
serverstat.async = {}

--- [SERVER]
---
--- Async version of `serverstat.ProcessCPUUsage`.
---
---@param callback fun( usage: number )
function serverstat.async.ProcessCPUUsage( callback ) end

--- [SERVER]
---
--- Async version of `serverstat.ProcessMemoryUsage`.
---
---@param callback fun( usage: number )
function serverstat.async.ProcessMemoryUsage( callback ) end

--- [SERVER]
---
--- Async version of `serverstat.SystemCPUUsage`.
---
---@param callback fun( usage: number )
function serverstat.async.SystemCPUUsage( callback ) end

--- [SERVER]
---
--- Async version of `serverstat.SystemMemoryUsage`.
---
---@param callback fun( used: number )
function serverstat.async.SystemMemoryUsage( callback ) end

--- [SERVER]
---
--- Async version of `serverstat.SystemTotalMemory`.
---
---@param callback fun( total: number )
function serverstat.async.SystemTotalMemory( callback ) end

--- [SERVER]
---
--- Async version of `serverstat.SystemAvailableMemory`.
---
---@param callback fun( available: number )
function serverstat.async.SystemAvailableMemory( callback ) end

--- [SERVER]
---
--- Async version of `serverstat.PhysicalCPUs`, passes the number of **logical** CPU cores ( same bug ).
---
---@param callback fun( count: integer )
function serverstat.async.PhysicalCPUs( callback ) end

--- [SERVER]
---
--- Async version of `serverstat.LogicalCPUs`, passes the number of **physical** CPU cores ( same bug ).
---
---@param callback fun( count: integer )
function serverstat.async.LogicalCPUs( callback ) end

--- [SERVER]
---
--- Async version of `serverstat.All`.
---
---@param callback fun( data: serverstat.All )
function serverstat.async.All( callback ) end

--- [SERVER]
---
--- Async version of `serverstat.AllSystem`.
---
---@param callback fun( data: serverstat.System )
function serverstat.async.AllSystem( callback ) end

--- [SERVER]
---
--- Async version of `serverstat.AllProcess`.
---
---@param callback fun( data: serverstat.Process )
function serverstat.async.AllProcess( callback ) end

--- [SERVER]
---
--- Non-blocking getters that return the last values refreshed in the background.
---
--- The data is refreshed every 250ms by the `gmsv_serverstat_realtime` timer,
--- which is created on the first call of any realtime function and runs until shutdown.
---
--- `All`, `AllSystem` and `AllProcess` return the table shared with other addons,
--- it is replaced ( not updated ) on each refresh; use the `Copy` versions to mutate it.
---
--- Total memory and CPU counts are missing here, they are constant.
---
---@class serverstat.realtime
serverstat.realtime = {}

--- [SERVER]
---
--- Starts ( or restarts ) the refresh timer.
---
--- Not required, the timer starts on the first call of any realtime function.
function serverstat.realtime.Start() end

--- [SERVER]
---
--- Stops the refresh timer, the getters keep returning the last values.
function serverstat.realtime.Stop() end

--- [SERVER]
---
--- Sets the refresh interval, restarts the timer if it is running.
---
---@param seconds number The interval in seconds, `0.25` by default, must be `>= 0`.
function serverstat.realtime.SetInterval( seconds ) end

--- [SERVER]
---
--- Returns the last CPU usage of the server process.
---
---@return number usage The CPU usage in percents of all logical cores, broken ( often `0` ).
---@nodiscard
function serverstat.realtime.ProcessCPUUsage() end

--- [SERVER]
---
--- Returns the last memory usage ( resident set size ) of the server process.
---
---@return number usage The used process memory in MiB.
---@nodiscard
function serverstat.realtime.ProcessMemoryUsage() end

--- [SERVER]
---
--- Returns the last CPU usage of the whole system.
---
---@return number usage The CPU usage in percents.
---@nodiscard
function serverstat.realtime.SystemCPUUsage() end

--- [SERVER]
---
--- Returns the last used memory of the whole system.
---
---@return number used The used system memory in KiB / 1000.
---@nodiscard
function serverstat.realtime.SystemMemoryUsage() end

--- [SERVER]
---
--- Returns the last available memory of the whole system.
---
---@return number available The available system memory in KiB / 1000.
---@nodiscard
function serverstat.realtime.SystemAvailableMemory() end

--- [SERVER]
---
--- Returns the last resource usage of the system and the server process.
---
---@return serverstat.realtime.All data The shared table, do not mutate.
---@nodiscard
function serverstat.realtime.All() end

--- [SERVER]
---
--- Returns the last resource usage of the system.
---
---@return serverstat.realtime.System data The shared table, do not mutate.
---@nodiscard
function serverstat.realtime.AllSystem() end

--- [SERVER]
---
--- Returns the last resource usage of the server process.
---
---@return serverstat.realtime.Process data The shared table, do not mutate.
---@nodiscard
function serverstat.realtime.AllProcess() end

--- [SERVER]
---
--- Returns a copy of `serverstat.realtime.All`.
---
---@return serverstat.realtime.All data A new table, safe to mutate.
---@nodiscard
function serverstat.realtime.AllCopy() end

--- [SERVER]
---
--- Returns a copy of `serverstat.realtime.AllSystem`.
---
---@return serverstat.realtime.System data A new table, safe to mutate.
---@nodiscard
function serverstat.realtime.AllSystemCopy() end

--- [SERVER]
---
--- Returns a copy of `serverstat.realtime.AllProcess`.
---
---@return serverstat.realtime.Process data A new table, safe to mutate.
---@nodiscard
function serverstat.realtime.AllProcessCopy() end
