---@meta _

--- [SHARED AND MENU]
---
--- The logger object.
---
---@class console.Logger : Object
---@field __class console.LoggerClass
---@field title string The logger title.
---@field title_color Color The logger title color.
---@field text_color Color The logger text color.
---@field interpolation boolean The logger interpolation.
---@field debug_fn fun( console.Logger ): boolean The logger debug function.
local Logger = {}

--- [SHARED AND MENU]
---
--- The logger class.
---
--- ```lua
--- local logger = console.Logger( { title = "game" } )
--- print( logger.title ) -- game
---
--- logger:info( "test %d %s %f", 1, 2, 3 ) -- 21-11-2026 09:41:52.909 [ Server ] INFO  --> game : test 1 2 3.000000
--- ```
---
---@class console.LoggerClass : console.Logger, Class
---@field __base console.Logger
---@overload fun( options: console.LoggerOptions? ) : console.Logger
console.Logger = {}

---@protected
function Logger:__init(options) end

--- [SHARED AND MENU]
---
--- Logs a message.
---@param color Color The log level color.
---@param level string The log level name.
---@param fmt string The log message.
---@param ... any The log message arguments to format/interpolate.
function Logger.log(object, color, level, fmt, ...) end

--- [SHARED AND MENU]
---
--- Logs an info message.
---
function Logger:info(...) end

--- [SHARED AND MENU]
---
--- Logs a warning message.
---
function Logger:warn(...) end

--- [SHARED AND MENU]
---
--- Logs an error message.
---
function Logger:error(...) end

--- [SHARED AND MENU]
---
--- Logs a debug message.
---
function Logger:debug(...) end
