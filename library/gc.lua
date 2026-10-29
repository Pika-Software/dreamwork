---@meta _

--- [SHARED AND MENU]
---
--- Lua manages memory automatically by running a garbage collector to collect all dead objects (that is, objects that are no longer accessible from Lua).
---
--- All memory used by Lua is subject to automatic management: strings, tables, userdata, functions, threads, internal structures, etc.
---
---@class gc
gc = {}

--- [SHARED AND MENU]
---
--- Performs a full garbage-collection cycle.
---
function gc.collect() end

--- [SHARED AND MENU]
---
--- The value has a fractional part, so that it multiplied by 1024 gives the exact number of bytes in use by Lua (except for overflows).
---
---@return number count The total memory in use by Lua in Kbytes.
---@nodiscard
function gc.getMemory() end

--- [SHARED AND MENU]
---
--- Stops automatic execution of the garbage collector.
--- The collector will run only when explicitly invoked, until a call to restart it.
---
function gc.stop() end

--- [SHARED AND MENU]
---
--- Restarts automatic execution of the garbage collector.
---
function gc.restart() end

--- [SHARED AND MENU]
---
--- Returns a boolean that tells whether the collector is running (i.e., not stopped).
---
---@return boolean is_running Returns true if the collector is running, false otherwise.
---@nodiscard
function gc.isRunning() end

--- [SHARED AND MENU]
---
--- The garbage-collector pause controls how long the collector waits before starting a new cycle.
--- Larger values make the collector less aggressive.
---
--- Values smaller than 100 mean the collector will not wait to start a new cycle.
--- A value of 200 means that the collector waits for the total memory in use to double before starting a new cycle.
---
---@param value number The new value for the pause of the collector.
---@return number pause_value The previous value for pause.
function gc.setPause(value) end

--- [SHARED AND MENU]
---
--- The garbage-collector step multiplier controls the relative speed of the collector relative to memory allocation.
--- Larger values make the collector more aggressive but also increase the size of each incremental step.
---
--- You should not use values smaller than 100, because they make the collector too slow and can result in the collector never finishing a cycle.
--- The default is 200, which means that the collector runs at "twice" the speed of memory allocation.
---
---@param size number With a zero value, the collector will perform one basic (indivisible) step. For non-zero values, the collector will perform as if that amount of memory (in KBytes) had been allocated by Lua.
---@return boolean finished Returns `true` if the step finished a collection cycle.
function gc.setStep(size) end

--- [SHARED AND MENU]
---
--- If you set the step multiplier to a very large number (larger than 10% of the maximum number of bytes that the program may use), the collector behaves like a stop-the-world collector.
--- If you then set the pause to 200, the collector behaves as in old Lua versions, doing a complete collection every time Lua doubles its memory usage.
---
---@param value number The new value for the step multiplier of the collector.
---@return number previous_value The previous value for step.
function gc.setStepMultiplier(value) end

--- [SHARED AND MENU]
---
--- Returns info about the garbage collector rules for the given table.
---
---@param tbl table The table to query.
---@return boolean key_mode `true` if key c ollection is allowed, `false` otherwise.
---@return boolean value_mode `true` if value collection is allowed, `false` otherwise.
---@nodiscard
function gc.getTableRules(tbl) end

--- [SHARED AND MENU]
---
--- Sets the garbage-collector rules for the given table.
---
---@param tbl table The table to set the rules for.
---@param key? boolean `true` if key collection is allowed, `false` otherwise.
---@param value? boolean `true` if value collection is allowed, `false` otherwise.
function gc.setTableRules(tbl, key, value) end
