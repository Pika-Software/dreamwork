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
