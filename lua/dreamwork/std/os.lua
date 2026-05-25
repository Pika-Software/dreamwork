---@class dreamwork.std
local std = dreamwork.std

--- [SHARED AND MENU]
---
--- This library is implemented through table `os`.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-os)
---
---@class dreamwork.std.os
local os = {
    ---@diagnostic disable-next-line: undefined-global
    clock = os.clock or SysTime,
    date = os.date or std.debug.fempty,
    difftime = os.difftime or function( a, b )
        return a - b
    end,
    ---@diagnostic disable-next-line: undefined-global
    time = os.time or CurTime,
}

std.os = os
