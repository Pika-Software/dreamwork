---@meta garrysmod


--- [SHARED AND MENU]
---
--- Returns the current synchronous server uptime in seconds (to at least 4 decimal places).
---
--- This value is affected by various factors such as:
--- - `host_timescale` - engine convar that affects the speed of the game
--- - [game.GetTimeScale](https://wiki.facepunch.com/gmod/game.GetTimeScale)
--- - `sv_pausable` - engine convar that pauses server
--- - if server empty (no players connected) - server will pause and not update time
---
--- You should use this function for timing in-game events but not for real-world events.
---
---@return number server_uptime Time synced with the game server.
function CurTime() end

--- [SHARED AND MENU]
---
--- Returns the current asynchronous server uptime in seconds (to at least 4 decimal places).
---
--- This will not be synced with the players current clock allowing you to get
--- [Global.CurTime](https://wiki.facepunch.com/gmod/Global.CurTime)
--- without interference from [Prediction](https://wiki.facepunch.com/gmod/Prediction).
---
---@return number async_server_uptime The asynchronous server uptime in seconds.
function UnPredictedCurTime() end

--- [SHARED AND MENU]
---
--- Returns a highly accurate time in seconds since the start up, ideal for benchmarking. Unlike [Global.RealTime](https://wiki.facepunch.com/gmod/Global.RealTime),
---
--- this value will be updated any time the function is called, allowing for sub-think precision.
---
---@return number engine_uptime Engine uptime in seconds.
function SysTime() end

--- [SHARED AND MENU]
---
--- This function will compile the code argument as lua code and return a function that will execute that code.
---
--- Please note that this function will not automatically execute the given code after compiling it.
---
---@param code string The code to compile.
---@param identifier string An identifier in case an error is thrown.
---@param handleError boolean If `false` this function will return an error string instead of throwing an error.
---@return function | string result
function CompileString( code, identifier, handleError ) end
