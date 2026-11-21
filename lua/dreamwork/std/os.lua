local HolyLib = HolyLib
local glua_os = os

---@class dreamwork.std
local std = dreamwork.std
local debug = std.debug


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
---@class dreamwork.std.os : oslib
local os = {
    clock = glua_os.clock,
    difftime = glua_os.difftime,
    time = glua_os.time,
    date = glua_os.date,
    getenv = os.getenv,
    exit = os.exit
}

std.os = os

if os.clock == nil then
    os.clock = SysTime or CurTime

    if os.clock == nil then
        local int = 0

        function os.clock()
            int = int + 1 -- well, we cooked
            return int
        end
    end
end

if os.time == nil then
    os.time = os.clock
end

if os.difftime == nil then
    function os.difftime( a, b )
        return a - b
    end
end

if os.date == nil then
    function os.date( fmt, timestamp )
        if fmt == "*t" or fmt == "!*t" then
            return {}
        end

        ---@diagnostic disable-next-line: return-type-mismatch
        return "<os.date is missing>"
    end
end

if HolyLib ~= nil and HolyLib.GetEnvironmentValue ~= nil then
    os.getenv = HolyLib.GetEnvironmentValue
else
    os.getenv = debug.fempty
end
