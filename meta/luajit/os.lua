---@meta os

---
---
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-os)
---
---@class oslib
os = {}

---
---Returns an approximation of the amount in seconds of CPU time used by the program.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-os.clock)
---
---@return number
---@nodiscard
function os.clock() end

---@class osdate : osdateparam
---
---four digits
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-osdate.year)
---
---@field year  integer
---
---1-12
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-osdate.month)
---
---@field month integer
---
---1-31
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-osdate.day)
---
---@field day   integer
---
---0-23
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-osdate.hour)
---
---@field hour  integer
---
---0-59
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-osdate.min)
---
---@field min   integer
---
---0-61
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-osdate.sec)
---
---@field sec   integer
---
---weekday, 1–7, Sunday is 1
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-osdate.wday)
---
---@field wday  integer
---
---day of the year, 1–366
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-osdate.yday)
---
---@field yday  integer
---
---daylight saving flag, a boolean
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-osdate.isdst)
---
---@field isdst boolean?

--- [SHARED AND MENU]
---
--- Returns a string or a table containing date and time, formatted according to the given string format.
---
--- If format starts with '!', then the date is formatted in Coordinated Universal Time.
---
--- If format is not "*t" or "!*t", then date returns the date as a string,
--- formatted according to the same rules as the C function strftime.
---
--- When called without arguments, date returns a reasonable date and time representation that depends on
--- the host system and on the current locale (that is, `os.date()` is equivalent to `os.date("%c")`).
---
--- | Key  | Description                           | Example                   |
--- |:-----|:--------------------------------------|:--------------------------|
--- | `%a` | Abbreviated weekday name              | `Wed`                     |
--- | `%A` | Full weekday name                     | `Wednesday`               |
--- | `%b` | Abbreviated month name                | `Sep`                     |
--- | `%B` | Full month name                       | `September`               |
--- | `%c` | Locale-appropriate date and time      | **Platform value**        |
--- | `%d` | Day of the month [01-31]              | `16`                      |
--- | `%H` | Hour, using a 24-hour clock [00-23]   | `23`                      |
--- | `%I` | Hour, using a 12-hour clock [01-12]   | `11`                      |
--- | `%j` | Day of the year [001-365]             | `259`                     |
--- | `%m` | Month [01-12]                         | `09`                      |
--- | `%M` | Minute [00-59]                        | `48`                      |
--- | `%p` | Either `am` or `pm`                   | `pm`                      |
--- | `%S` | Second [00-60]                        | `10`                      |
--- | `%w` | Weekday [0-6 = Sunday-Saturday]       | `3`                       |
--- | `%W` | Week of the year [00-53]              | `37`                      |
--- | `%x` | Date (Same as %m/%d/%y)               | `09/16/98`                |
--- | `%X` | Time (Same as %H:%M:%S)               | `23:48:10`                |
--- | `%y` | Two-digit year [00-99]                | `98`                      |
--- | `%Y` | Full year                             | `1998`                    |
--- | `%z` | Timezone                              | `-0300`                   |
--- | `%%` | A percent sign                        | `%`                       |
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-os.date)
---
---@param fmt? string The format string, if not provided, "%c" is used.
---@param timestamp? integer The timestamp to format, if not provided, the current time is used.
---@return string time_str The formatted date and time string.
---@overload fun( fmt: ( "*t" | "!*t" ), timestamp: integer? ): osdate
---@nodiscard
function os.date( fmt, timestamp ) end

---
---Returns the difference, in seconds, from time `t1` to time `t2`.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-os.difftime)
---
---@param t2 integer
---@param t1 integer
---@return integer
---@nodiscard
function os.difftime( t2, t1 ) end

---
---Passes `command` to be executed by an operating system shell.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-os.execute)
---
---@param command? string
---@return true?     suc
---@return exitcode? exitcode
---@return integer?  code
function os.execute( command ) end

---
---Calls the ISO C function `exit` to terminate the host program.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-os.exit)
---
---@param code?  boolean|integer
---@param close? boolean
function os.exit( code, close ) end

---
---Returns the value of the process environment variable `varname`.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-os.getenv)
---
---@param varname string
---@return string?
---@nodiscard
function os.getenv( varname ) end

---
---Deletes the file with the given name.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-os.remove)
---
---@param filename string
---@return true? suc
---@return string? errmsg
---@return integer? errcode
function os.remove( filename ) end

---
---Renames the file or directory named `oldname` to `newname`.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-os.rename)
---
---@param oldname string
---@param newname string
---@return true? suc
---@return string? errmsg
---@return integer? errcode
function os.rename( oldname, newname ) end

---@alias localecategory
---|>"all"
---| "collate"
---| "ctype"
---| "monetary"
---| "numeric"
---| "time"

---
---Sets the current locale of the program.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-os.setlocale)
---
---@param locale    string|nil
---@param category? localecategory
---@return string localecategory
function os.setlocale( locale, category ) end

---@class osdateparam
---
---four digits
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-osdate.year)
---
---@field year  integer|string
---
---1-12
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-osdate.month)
---
---@field month integer|string
---
---1-31
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-osdate.day)
---
---@field day   integer|string
---
---0-23
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-osdate.hour)
---
---@field hour  (integer|string)?
---
---0-59
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-osdate.min)
---
---@field min   (integer|string)?
---
---0-61
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-osdate.sec)
---
---@field sec   (integer|string)?
---
---weekday, 1–7, Sunday is 1
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-osdate.wday)
---
---@field wday  (integer|string)?
---
---day of the year, 1–366
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-osdate.yday)
---
---@field yday  (integer|string)?
---
---daylight saving flag, a boolean
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-osdate.isdst)
---
---@field isdst boolean?

---
---Returns the current time when called without arguments, or a time representing the local date and time specified by the given table.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-os.time)
---
---@param date? osdateparam
---@return integer
---@nodiscard
function os.time( date ) end

---
---Returns a string with a file name that can be used for a temporary file.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-os.tmpname)
---
---@return string
---@nodiscard
function os.tmpname() end

return os
