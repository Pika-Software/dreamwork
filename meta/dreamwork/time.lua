---@meta dreamwork.std.time


---@alias dreamwork.std.time.Unit
---| "ns" Nanoseconds
---| "us" Microseconds
---| "ms" Milliseconds
---| "s" Seconds
---| "m" Minutes
---| "h" Hours
---| "d" Days
---| "w" Weeks
---| "mo" Months
---| "y" Years


---@alias dreamwork.std.time.DurationString
---| "1ms 1us 1ns" One millisecond, one microsecond and one nanosecond.
---| "1h 1m 1s" One hour, one minute and one second.
---| "1y 1w 1d" One year, one week and one day.
---| "1w 1d" One week and one day.
---| "1y" One year.
---| string


---@class dreamwork.std.time
local time = {}


return time
