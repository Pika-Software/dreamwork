---@meta _

--- [SHARED AND MENU]
---
--- This library is implemented through table `os`.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-os)
---
---@class oslib
os = {}

function os.clock() end

function os.difftime(a, b) end

function os.date(fmt, timestamp) end

os.getenv = debug.fempty
