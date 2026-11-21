---@meta _

--- [SHARED AND MENU]
---
--- The os library, a GMod-safe subset of Lua's [os](http://www.lua.org/manual/5.1/manual.html#pdf-os).
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-os)
---
--- ```lua
--- print( os.difftime( 5, 2 ) ) -- 3
---
--- local timestamp = os.time( { year = 2026, month = 11, day = 21, hour = 10, min = 4, sec = 36 } )
--- print( os.date( "%Y-%m-%d %H:%M:%S", timestamp ) ) -- 2026-11-21 10:04:36
--- print( os.date( "today is %A, in %B", timestamp ) ) -- today is Saturday, in November
---
--- local date = os.date( "*t", timestamp )
--- print( date.year ) -- 2026
--- print( date.month ) -- 11
--- print( date.day ) -- 21
--- print( date.wday ) -- 7
---
--- print( os.getenv( "HOME" ) ) -- /home/ukdev
--- ```
---
---@class oslib
os = {}

function os.clock() end

function os.difftime(a, b) end

function os.date(fmt, timestamp) end

os.getenv = debug.fempty
