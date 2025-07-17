local _G = _G
---@class gpm.std
local std = _G.gpm.std

local os = _G.os
local os_time = os.time
local os_date = os.date
local os_clock = os.clock

-- TODO: add utc argument for funcs that use os_date
-- TODO: https://github.com/Nak2/NikNaks/blob/main/lua/niknaks/modules/sh_datetime.lua

local math = std.math
local math_min = math.min
local math_floor = math.floor

local string = std.string
local string_byte, string_char = string.byte, string.char
local string_format = string.format
local string_sub = string.sub
local string_len = string.len

local table_concat = std.table.concat
local raw_tonumber = std.raw.tonumber

--- [SHARED AND MENU]
---
--- A library for working with time and date.
---
---@class gpm.std.time
local time = std.time or {}
std.time = time

---@alias gpm.std.time.Unit
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

---@alias gpm.std.time.Duration
---| "1ms 1us 1ns" One millisecond, one microsecond and one nanosecond.
---| "1h 1m 1s" One hour, one minute and one second.
---| "1y 1w 1d" One year, one week and one day.
---| "1w 1d" One week and one day.
---| "1y" One year.
---| string

local transform
do

    ---@type table<integer, fun( ts: number ): number>
    local transformation_map

    do

        local function ts_m1e_3( ts )
            return ts * 1e-3
        end

        local function ts_m1e_6( ts )
            return ts * 1e-6
        end

        local function ts_m1e3( ts )
            return ts * 1e3
        end

        local function ts_m1e6( ts )
            return ts * 1e6
        end

        local function ts_d60( ts )
            return ts / 60
        end

        transformation_map = {
            -- ns -> other
            [ 0x7375736E ] = ts_m1e_3, -- ns to us
            [ 0x736D736E ] = ts_m1e_6, -- ns to ms
            [ 0x73736E ]   = function( ts ) return ts * 1e-9 end,        -- ns to s
            [ 0x6D736E ]   = function( ts ) return ( ts * 1e-9 ) / 60 end,   -- ns to m
            [ 0x68736E ]   = function( ts ) return ( ts * 1e-9 ) / 3600 end, -- ns to h
            [ 0x64736E ]   = function( ts ) return ( ts * 1e-9 ) / 86400 end, -- ns to d
            [ 0x77736E ]   = function( ts ) return ( ts * 1e-9 ) / 604800 end, -- ns to w
            [ 0x6F6D736E ] = function( ts ) return ( ts * 1e-9 ) / 2592000 end, -- ns to mo
            [ 0x79736E ]   = function( ts ) return ( ts * 1e-9 ) / 31536000 end, -- ns to y

            -- us -> other
            [ 0x736E7375 ] = ts_m1e3,  -- us to ns
            [ 0x736D7375 ] = ts_m1e_3, -- us to ms
            [ 0x737375 ]   = ts_m1e_6, -- us to s
            [ 0x6D7375 ]   = function( ts ) return ( ts * 1e-6 ) / 60 end,   -- us to m
            [ 0x687375 ]   = function( ts ) return ( ts * 1e-6 ) / 3600 end, -- us to h
            [ 0x647375 ]   = function( ts ) return ( ts * 1e-6 ) / 86400 end, -- us to d
            [ 0x777375 ]   = function( ts ) return ( ts * 1e-6 ) / 604800 end, -- us to w
            [ 0x6F6D7375 ] = function( ts ) return ( ts * 1e-6 ) / 2592000 end, -- us to mo
            [ 0x797375 ]   = function( ts ) return ( ts * 1e-6 ) / 31536000 end, -- us to y

            -- ms -> other
            [ 0x736E736D ] = ts_m1e6,         -- ms to ns
            [ 0x7375736D ] = ts_m1e3,         -- ms to us
            [ 0x73736D ]   = ts_m1e_3, -- ms to s
            [ 0x6D736D ]   = function( ts ) return ( ts * 1e-3 ) / 60 end,   -- ms to m
            [ 0x68736D ]   = function( ts ) return ( ts * 1e-3 ) / 3600 end, -- ms to h
            [ 0x64736D ]   = function( ts ) return ( ts * 1e-3 ) / 86400 end, -- ms to d
            [ 0x77736D ]   = function( ts ) return ( ts * 1e-3 ) / 604800 end, -- ms to w
            [ 0x6F6D736D ] = function( ts ) return ( ts * 1e-3 ) / 2592000 end, -- ms to mo
            [ 0x79736D ]   = function( ts ) return ( ts * 1e-3 ) / 31536000 end, -- ms to y

            -- s -> other
            [ 0x736E0073 ] = function( ts ) return ts * 1e9 end,         -- s to ns
            [ 0x73750073 ] = ts_m1e6,         -- s to us
            [ 0x736D0073 ] = ts_m1e3,         -- s to ms
            [ 0x6D0073 ]   = ts_d60,          -- s to m
            [ 0x680073 ]   = function( ts ) return ts / 3600 end,        -- s to h
            [ 0x640073 ]   = function( ts ) return ts / 86400 end,       -- s to d
            [ 0x770073 ]   = function( ts ) return ts / 604800 end,      -- s to w
            [ 0x6F6D0073 ] = function( ts ) return ts / 2592000 end,     -- s to mo
            [ 0x790073 ]   = function( ts ) return ts / 31536000 end,    -- s to y

            -- m -> other
            [ 0x736E006D ] = function( ts ) return ( ts * 60 ) * 1e9 end,    -- m to ns
            [ 0x7375006D ] = function( ts ) return ( ts * 60 ) * 1e6 end,    -- m to us
            [ 0x736D006D ] = function( ts ) return ( ts * 60 ) * 1e3 end,    -- m to ms
            [ 0x73006D ]   = function( ts ) return ( ts * 60 ) end,          -- m to s
            [ 0x68006D ]   = ts_d60,          -- m to h
            [ 0x64006D ]   = function( ts ) return ts / 1440 end,        -- m to d
            [ 0x77006D ]   = function( ts ) return ts / 10080 end,       -- m to w
            [ 0x6F6D006D ] = function( ts ) return ts / 43200 end,       -- m to mo
            [ 0x79006D ]   = function( ts ) return ts / 525600 end,      -- m to y

            -- h -> other
            [ 0x736E0068 ] = function( ts ) return ( ts * 3600 ) * 1e9 end,  -- h to ns
            [ 0x73750068 ] = function( ts ) return ( ts * 3600 ) * 1e6 end,  -- h to us
            [ 0x736D0068 ] = function( ts ) return ( ts * 3600 ) * 1e3 end,  -- h to ms
            [ 0x730068 ]   = function( ts ) return ( ts * 3600 ) end,        -- h to s
            [ 0x6D0068 ]   = function( ts ) return ( ts * 60 ) end,          -- h to m
            [ 0x640068 ]   = function( ts ) return ts / 24 end,          -- h to d
            [ 0x770068 ]   = function( ts ) return ts / 168 end,         -- h to w
            [ 0x6F6D0068 ] = function( ts ) return ts / 720 end,         -- h to mo
            [ 0x790068 ]   = function( ts ) return ts / 8760 end,        -- h to y

            -- d -> other
            [ 0x736E0064 ] = function( ts ) return ( ts * 86400 ) * 1e9 end, -- d to ns
            [ 0x73750064 ] = function( ts ) return ( ts * 86400 ) * 1e6 end, -- d to us
            [ 0x736D0064 ] = function( ts ) return ( ts * 86400 ) * 1e3 end, -- d to ms
            [ 0x730064 ]   = function( ts ) return ( ts * 86400 ) end,       -- d to s
            [ 0x6D0064 ]   = function( ts ) return ts * 1440 end,        -- d to m
            [ 0x680064 ]   = function( ts ) return ts * 24 end,          -- d to h
            [ 0x770064 ]   = function( ts ) return ts / 7 end,           -- d to w
            [ 0x6F6D0064 ] = function( ts ) return ts / 30 end,          -- d to mo
            [ 0x790064 ]   = function( ts ) return ts / 365 end,         -- d to y

            -- w -> other
            [ 0x736E0077 ] = function( ts ) return ( ts * 604800 ) * 1e9 end, -- w to ns
            [ 0x73750077 ] = function( ts ) return ( ts * 604800 ) * 1e6 end, -- w to us
            [ 0x736D0077 ] = function( ts ) return ( ts * 604800 ) * 1e3 end, -- w to ms
            [ 0x730077 ]   = function( ts ) return ( ts * 604800 ) end,      -- w to s
            [ 0x6D0077 ]   = function( ts ) return ts * 10080 end,       -- w to m
            [ 0x680077 ]   = function( ts ) return ts * 168 end,         -- w to h
            [ 0x640077 ]   = function( ts ) return ts * 7 end,           -- w to d
            [ 0x6F6D0077 ] = function( ts ) return ts / 4.285714286 end, -- w to mo
            [ 0x790077 ]   = function( ts ) return ts / 52.142857143 end, -- w to y

            -- mo -> other
            [ 0x736E6F6D ] = function( ts ) return ( ts * 2592000 ) * 1e9 end, -- mo to ns
            [ 0x73756F6D ] = function( ts ) return ( ts * 2592000 ) * 1e6 end, -- mo to us
            [ 0x736D6F6D ] = function( ts ) return ( ts * 2592000 ) * 1e3 end, -- mo to ms
            [ 0x736F6D ]   = function( ts ) return ( ts * 2592000 ) end,     -- mo to s
            [ 0x6D6F6D ]   = function( ts ) return ts * 43200 end,       -- mo to m
            [ 0x686F6D ]   = function( ts ) return ts * 720 end,         -- mo to h
            [ 0x646F6D ]   = function( ts ) return ts * 30 end,          -- mo to d
            [ 0x776F6D ]   = function( ts ) return ts * 4.285714286 end, -- mo to w
            [ 0x796F6D ]   = function( ts ) return ts / 12 end,          -- mo to y

            -- y -> other
            [ 0x736E0079 ] = function( ts ) return ( ts * 31536000 ) * 1e9 end, -- y to ns
            [ 0x73750079 ] = function( ts ) return ( ts * 31536000 ) * 1e6 end, -- y to us
            [ 0x736D0079 ] = function( ts ) return ( ts * 31536000 ) * 1e3 end, -- y to ms
            [ 0x730079 ]   = function( ts ) return ( ts * 31536000 ) end,    -- y to s
            [ 0x6D0079 ]   = function( ts ) return ts * 525600 end,      -- y to m
            [ 0x680079 ]   = function( ts ) return ts * 8760 end,        -- y to h
            [ 0x640079 ]   = function( ts ) return ts * 365 end,         -- y to d
            [ 0x770079 ]   = function( ts ) return ts * 52.142857143 end, -- y to w
            [ 0x6F6D0079 ] = function( ts ) return ts * 12 end           -- y to mo
        }

    end

    local bit_lshift = bit.lshift
    local bit_bor = bit.bor

    --- [SHARED AND MENU]
    ---
    --- Transforms a timestamp from one unit to another.
    ---
    ---@param timestamp integer The timestamp to transform.
    ---@param unit? gpm.std.time.Unit The unit to transform the timestamp from, seconds by default.
    ---@param target? gpm.std.time.Unit The unit to transform the timestamp to, seconds by default.
    ---@param as_float? boolean Whether to return the timestamp as a float, `false` by default.
    ---@param error_level? integer The error level to use, 2 by default.
    ---@return number timestamp The transformed timestamp.
    function transform( timestamp, unit, target, as_float, error_level )
        local unit_uint8_1, unit_uint8_2
        if unit == nil then
            unit_uint8_1, unit_uint8_2 = 0x73 --[[ `s` ]], 0x0
        else

            unit_uint8_1, unit_uint8_2 = string_byte( unit, 1, 2 )

            if unit_uint8_1 == nil then
                error( "unit cannot be empty string", ( error_level or 1 ) + 1 )
            end

            if unit_uint8_2 == nil then
                unit_uint8_2 = 0x0
            end

        end

        local target_uint8_1, target_uint8_2
        if target == nil then
            target_uint8_1, target_uint8_2 = 0x73 --[[ `s` ]], 0x0
        else

            target_uint8_1, target_uint8_2 = string_byte( target, 1, 2 )

            if target_uint8_1 == nil then
                error( "target cannot be empty string", ( error_level or 1 ) + 1 )
            end

            if target_uint8_2 == nil then
                target_uint8_2 = 0x0
            end

        end

        if unit_uint8_1 ~= target_uint8_1 or unit_uint8_2 ~= target_uint8_2 then
            local transform_fn = transformation_map[ bit_bor(
                bit_lshift( target_uint8_2, 24 ),
                bit_lshift( target_uint8_1, 16 ),
                bit_lshift( unit_uint8_2, 8 ),
                unit_uint8_1
            ) ]

            if transform_fn == nil then
                error( "unknown transformation from '" .. unit .. "' to '" .. target .. "'", ( error_level or 1 ) + 1 )
            end

            timestamp = transform_fn( timestamp )
        end

        if as_float then
            return timestamp
        else
            return math_floor( timestamp )
        end
    end

end

--- [SHARED AND MENU]
---
--- Transforms a timestamp to a different unit.
---
---@param timestamp integer The timestamp to transform.
---@param unit? gpm.std.time.Unit The unit to transform the timestamp from, seconds by default.
---@param target? gpm.std.time.Unit The unit to transform the timestamp to, seconds by default.
---@param as_float? boolean Whether to return the timestamp as a float.
---@return integer
function time.transform( timestamp, unit, target, as_float )
    return transform( timestamp, unit, target, as_float, 2 )
end

local seconds_elapsed = _G.SysTime or os_clock

--- [SHARED AND MENU]
---
--- Returns the time elapsed since lua was started.
---
---@param unit? gpm.std.time.Unit The unit to return the elapsed time in, seconds by default.
---@param as_float? boolean Whether to return the elapsed time as a float.
---@return number timestamp The elapsed time in the specified unit.
function time.elapsed( unit, as_float )
    if unit == "ns" then
        local float = seconds_elapsed() * 1e9
        if as_float then
            return float
        else
            return math_floor( float )
        end
    elseif unit == "us" then
        local float = seconds_elapsed() * 1e6
        if as_float then
            return float
        else
            return math_floor( float )
        end
    elseif unit == "ms" then
        local float = os_clock() * 1e3
        if as_float then
            return float
        else
            return math_floor( float )
        end
    elseif unit == "s" or unit == nil then
        local float = os_clock()
        if as_float then
            return float
        else
            return math_floor( float )
        end
    else
        return transform( os_clock(), "s", unit, as_float, 2 )
    end
end

--- [SHARED AND MENU]
---
--- Returns the current time in the specified unit.
---
---@param unit? gpm.std.time.Unit The unit to return the current time in, seconds by default.
---@param as_float? boolean Whether to return the timestamp as a float.
---@return integer timestamp The current timestamp in the specified unit.
local function now( unit, as_float )
    local timestamp = os_time()

    if unit == nil or unit == "s" then
        return timestamp
    elseif unit == "ms" or unit == "us" or unit == "ns" then
        timestamp = timestamp + ( seconds_elapsed() % 1 )
    end

    return transform( timestamp, nil, unit, as_float, 2 )
end

time.now = now

do

    local string_gmatch = string.gmatch

    ---@param duration_str gpm.std.time.Duration The duration string to convert.
    ---@param unit? gpm.std.time.Unit The unit to convert the duration to, seconds by default.
    ---@param as_float? boolean Whether to return the duration as a float.
    ---@param error_level? integer The error level to use, 2 by default.
    ---@return integer timestamp The duration in the specified unit.
    local function duration( duration_str, unit, as_float, error_level )
        local seconds, milliseconds, microseconds, nanoseconds = 0, 0, 0, 0

        for number_str, unit_str in string_gmatch( duration_str, "(%-?%d+%.?%d*)(%l*)" ) do
            local integer = raw_tonumber( number_str, 10 )

            if unit_str == "s" then
                seconds = seconds + integer
            elseif unit_str == "ms" then
                milliseconds = milliseconds + integer
            elseif unit_str == "us" then
                microseconds = microseconds + integer
            elseif unit_str == "ns" then
                nanoseconds = nanoseconds + integer
            else
                seconds = seconds + transform( integer, unit_str, "s", as_float, ( error_level or 1 ) + 1 )
            end
        end

        if unit == "ms" then
            local float = seconds * 1e3 + milliseconds + microseconds * 1e-3 + nanoseconds * 1e-6

            if as_float then
                return float
            else
                return math_floor( float )
            end
        elseif unit == "us" then
            local float = seconds * 1e6 + milliseconds * 1e3 + microseconds + nanoseconds * 1e-3

            if as_float then
                return float
            else
                return math_floor( float )
            end
        elseif unit == "ns" then
            local float = seconds * 1e9 + milliseconds * 1e6 + microseconds * 1e3 + nanoseconds

            if as_float then
                return float
            else
                return math_floor( float )
            end
        end

        return transform( seconds + nanoseconds * 1e-9 + microseconds * 1e-6 + milliseconds * 1e-3, nil, unit, as_float, 2 )
    end

    --- [SHARED AND MENU]
    ---
    --- Converts a duration string to the specified unit.
    ---
    --- The duration string can have the following units: `ns`, `us`, `ms`, `s`, `m`, `h`, `d`, `w`, `y`.
    ---
    --- | Suffix | Name         | Value                         |
    --- |--------|--------------|-------------------------------|
    --- | `ns`     | Nanosecond   | 1 / 1,000,000,000 seconds   |
    --- | `us`     | Microsecond  | 1 / 1,000,000 seconds       |
    --- | `ms`     | Millisecond  | 1 / 1,000 seconds           |
    --- | `s`      | Second       | 1 second                    |
    --- | `m`      | Minute       | 60 seconds                  |
    --- | `h`      | Hour         | 60 minutes                  |
    --- | `d`      | Day          | 24 hours                    |
    --- | `w`      | Week         | 7 days                      |
    --- | `mo`     | Month        | ~30 days                    |
    --- | `y`      | Year         | 365 days                    |
    ---
    ---@param duration_str gpm.std.time.Duration The duration string to convert.
    ---@param unit gpm.std.time.Unit The unit to convert the duration to.
    ---@param as_float? boolean Whether to return the duration as a float.
    ---@return integer timestamp The duration in the specified unit.
    function time.duration( duration_str, unit, as_float )
        return duration( duration_str, unit, as_float, 2 )
    end

    --- [SHARED AND MENU]
    ---
    --- Adds a duration to a timestamp.
    ---
    --- The duration string can have the following units: `ns`, `us`, `ms`, `s`, `m`, `h`, `d`, `w`, `y`.
    ---
    --- | Suffix | Name         | Value                         |
    --- |--------|--------------|-------------------------------|
    --- | `ns`     | Nanosecond   | 1 / 1,000,000,000 seconds   |
    --- | `us`     | Microsecond  | 1 / 1,000,000 seconds       |
    --- | `ms`     | Millisecond  | 1 / 1,000 seconds           |
    --- | `s`      | Second       | 1 second                    |
    --- | `m`      | Minute       | 60 seconds                  |
    --- | `h`      | Hour         | 60 minutes                  |
    --- | `d`      | Day          | 24 hours                    |
    --- | `w`      | Week         | 7 days                      |
    --- | `mo`     | Month        | ~30 days                    |
    --- | `y`      | Year         | 365 days                    |
    ---
    ---@param timestamp integer The timestamp to add the duration to.
    ---@param unit? gpm.std.time.Unit The unit to add the duration to, seconds by default.
    ---@param duration_str gpm.std.time.Duration The duration string to add.
    ---@param as_float? boolean Whether to return the timestamp as a float.
    ---@return integer
    function time.add( timestamp, unit, duration_str, as_float )
        return timestamp + duration( duration_str, unit, as_float, 2 )
    end

    --- [SHARED AND MENU]
    ---
    --- Subtracts a duration from a timestamp.
    ---
    --- The duration string can have the following units: `ns`, `us`, `ms`, `s`, `m`, `h`, `d`, `w`, `y`.
    ---
    --- | Suffix | Name         | Value                         |
    --- |--------|--------------|-------------------------------|
    --- | `ns`     | Nanosecond   | 1 / 1,000,000,000 seconds   |
    --- | `us`     | Microsecond  | 1 / 1,000,000 seconds       |
    --- | `ms`     | Millisecond  | 1 / 1,000 seconds           |
    --- | `s`      | Second       | 1 second                    |
    --- | `m`      | Minute       | 60 seconds                  |
    --- | `h`      | Hour         | 60 minutes                  |
    --- | `d`      | Day          | 24 hours                    |
    --- | `w`      | Week         | 7 days                      |
    --- | `mo`     | Month        | ~30 days                    |
    --- | `y`      | Year         | 365 days                    |
    ---
    ---@param timestamp integer The timestamp to subtract the duration from.
    ---@param unit? gpm.std.time.Unit The unit to subtract the duration from, seconds by default.
    ---@param duration_str gpm.std.time.Duration The duration string to subtract.
    ---@param as_float? boolean Whether to return the timestamp as a float.
    ---@return integer
    function time.sub( timestamp, unit, duration_str, as_float )
        return timestamp - duration( duration_str, unit, as_float, 2 )
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Splits a timestamp into seconds, milliseconds, microseconds and nanoseconds.
    ---
    ---@param timestamp integer
    ---@param unit? gpm.std.time.Unit
    ---@param error_level? integer
    ---@return integer seconds
    ---@return integer milliseconds
    ---@return integer microseconds
    ---@return integer nanoseconds
    local function split( timestamp, unit, error_level )
        error_level = ( error_level or 1 ) + 1

        local seconds = transform( timestamp, unit, "s", false, error_level )
        timestamp = timestamp - transform( seconds, "s", unit, true, error_level )

        local milliseconds = transform( timestamp, unit, "ms", false, error_level )
        timestamp = timestamp - transform( milliseconds, "ms", unit, true, error_level )

        local microseconds = transform( timestamp, unit, "us", false, error_level )
        timestamp = timestamp - transform( microseconds, "us", unit, true, error_level )

        return seconds, milliseconds, microseconds, transform( timestamp, unit, "ns", false, error_level )
    end

    --- [SHARED AND MENU]
    ---
    --- Represents a date and time.
    ---
    ---@class gpm.std.time.Date
    ---@field summer_time boolean Is the date in summer time?
    ---@field week_day integer The day of the week.
    ---@field milliseconds integer The number of milliseconds.
    ---@field microseconds integer The number of microseconds.
    ---@field nanoseconds integer The number of nanoseconds.
    ---@field hours12 integer The number of hours in 12-hour format.
    ---@field hours integer The number of hours.
    ---@field minutes integer The number of minutes.
    ---@field seconds integer The number of seconds.
    ---@field period "AM" | "PM" The period of the day.
    ---@field day integer The day of the month.
    ---@field month integer The month of the year.
    ---@field year integer The year.
    ---@field year_day integer The day of the year.
    ---@field year_week integer The week number of the year.
    ---@field timezone integer The timezone offset.

    --- [SHARED AND MENU]
    ---
    --- Returns a table with the date and time components.
    ---
    ---@param timestamp integer The timestamp to parse.
    ---@param unit? gpm.std.time.Unit The unit to parse the timestamp from, seconds by default.
    ---@return gpm.std.time.Date date_tbl The date and time components.
    function time.parse( timestamp, unit )
        local seconds, milliseconds, microseconds, nanoseconds = split( timestamp, unit, 2 )

        local tbl = os_date( "*t", seconds )
        ---@cast tbl table

        tbl.summer_time = tbl.isdst
        tbl.isdst = nil

        tbl.week_day = ( tbl.wday + 5 ) % 7 + 1
        tbl.wday = nil

        tbl.year_day = tbl.yday
        tbl.yday = nil

        tbl.milliseconds = milliseconds or 0
        tbl.microseconds = microseconds or 0
        tbl.nanoseconds = nanoseconds or 0

        tbl.hours = tbl.hour
        tbl.hour = nil

        tbl.minutes = tbl.min
        tbl.min = nil

        tbl.seconds = tbl.sec
        tbl.sec = nil

        ---@diagnostic disable-next-line: param-type-mismatch
        local values = string.byteSplit( os_date( "%I;%p;%W;%z", seconds ), 0x3B )

        tbl.hours12 = tonumber( values[ 1 ], 10 ) or 0
        tbl.period = values[ 2 ] or "AM"

        tbl.year_week = ( tonumber( values[ 3 ], 10 ) or 0 ) + 1

        local timezone = tonumber( values[ 4 ], 10 ) or 0

        if timezone ~= 0 then
            timezone = timezone * 0.01
        end

        tbl.timezone = timezone

        return tbl
    end

    local duration_units = {
        { 31536000, "y" },
        { 2592000, "mo" },
        { 604800, "w" },
        { 86400, "d" },
        { 3600, "h" },
        { 60, "m" }
    }

    --- [SHARED AND MENU]
    ---
    --- Converts a number of seconds to a duration string.
    ---
    --- The duration string can have the following units: `ns`, `us`, `ms`, `s`, `m`, `h`, `d`, `w`, `y`.
    ---
    --- | Suffix | Name         | Value                         |
    --- |--------|--------------|-------------------------------|
    --- | `ns`     | Nanosecond   | 1 / 1,000,000,000 seconds     |
    --- | `us`     | Microsecond  | 1 / 1,000,000 seconds         |
    --- | `ms`     | Millisecond  | 1 / 1,000 seconds             |
    --- | `s`      | Second       | 1 second                      |
    --- | `m`      | Minute       | 60 seconds                    |
    --- | `h`      | Hour         | 60 minutes                    |
    --- | `d`      | Day          | 24 hours                      |
    --- | `w`      | Week         | 7 days                        |
    --- | `mo`     | Month        | ~30 days                      |
    --- | `y`      | Year         | 365 days                      |
    ---
    ---@param timestamp integer The timestamp to convert.
    ---@param unit? gpm.std.time.Unit The unit to convert the timestamp to, seconds by default.
    ---@return string duration_str The duration string.
    function time.string( timestamp, unit )
        local seconds, milliseconds, microseconds, nanoseconds = split( timestamp, unit, 2 )
        local segments, segment_count = {}, 0

        if seconds ~= 0 then

            for i = 1, 6, 1 do
                local lst = duration_units[ i ]

                local value = lst[ 1 ]
                if seconds >= value then
                    local count = math_floor( seconds / value )
                    seconds = seconds - ( count * value )

                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_format( "%d%s", count, lst[ 2 ] )
                end

                if seconds <= 0 then
                    break
                end
            end

        end

        if seconds ~= 0 then
            local second_count = math_floor( seconds )
            if second_count > 0 then
                seconds = seconds - second_count

                segment_count = segment_count + 1
                segments[ segment_count ] = string_format( "%ds", second_count )
            end
        end

        if milliseconds ~= 0 then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_format( "%03dms", milliseconds )
        end

        if microseconds ~= 0 then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_format( "%03dus", microseconds )
        end

        if nanoseconds ~= 0 then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_format( "%03dns", nanoseconds )
        end

        return table_concat( segments, " ", 1, segment_count )
    end

    ---@type table<string, string>
    local keys = {
        -- %d	Day of the month [01-31]	16
        day = "%d",
        -- %j	Day of the year [001-365]	259
        day_of_year = "%j",

        -- %m	Month [01-12]	09
        month = "%m",
        -- %B	Full month name	September
        month_name = "%B",
        -- %b	Abbreviated month name	Sep
        month_short_name = "%b",

        -- %Y	Full year	1998
        year = "%Y",
        -- %y	Two-digit year [00-99]	98
        year_short = "%y",

        -- %H	Hour, using a 24-hour clock [00-23]	23
        hours = "%H",
        -- %M	Minute [00-59]	48
        minutes = "%M",
        -- %S	Second [00-60]	10
        seconds = "%S",

        -- %I	Hour, using a 12-hour clock [01-12]	11
        hours12 = "%I",
        -- %p	Either am or pm	pm
        period = "%p",

        -- %w	Weekday [0-6 = Sunday-Saturday]	3
        week_day = "%w",
        -- %A	Full weekday name	Wednesday
        week_day_name = "%A",
        -- %a	Abbreviated weekday name	Wed
        week_day_short_name = "%a",

        -- %W	Week of the year [00-53]	37
        year_week = "%W",

        -- %z	Timezone	-0300
        timezone = "%z",

        -- %X	Time (Same as %H:%M:%S)	23:48:10
        time = "%X",
        -- %x	Date (Same as %m/%d/%y)	09/16/98
        date = "%x",

        -- %c	Locale-appropriate date and time	Varies by platform and language settings
        date_time = "%c"
    }

    --- [SHARED AND MENU]
    ---
    --- Converts a timestamp to a formatted string.
    ---
    --- ### Format Keys
    --- | Key                     | Description                                            | Example                    |
    --- |-------------------------|--------------------------------------------------------|----------------------------|
    --- | `{week_day}`            | Weekday number [0–6, Sunday = 0]                       | `3`                        |
    --- | `{week_day_name}`       | Full weekday name                                      | `Wednesday`                |
    --- | `{week_day_short_name}` | Abbreviated weekday name                               | `Wed`                      |
    --- | `{day}`                 | Day of the month [01–31]                               | `16`                       |
    --- | `{day_of_year}`         | Day of the year [001–365]                              | `259`                      |
    --- | `{month}`               | Month number [01–12]                                   | `09`                       |
    --- | `{month_name}`          | Full month name                                        | `September`                |
    --- | `{month_short_name}`    | Abbreviated month name                                 | `Sep`                      |
    --- | `{year}`                | Full year                                              | `1998`                     |
    --- | `{year_week}`           | Week number of the year [00–53]                        | `37`                       |
    --- | `{year_short}`          | Two-digit year [00–99]                                 | `98`                       |
    --- | `{hours}`               | Hour in 24-hour format [00–23]                         | `23`                       |
    --- | `{minutes}`             | Minute [00–59]                                         | `48`                       |
    --- | `{seconds}`             | Second [00–60] (leap second included)                  | `10`                       |
    --- | `{hours12}`             | Hour in 12-hour format [01–12]                         | `11`                       |
    --- | `{period}`              | AM or PM                                               | `pm`                       |
    --- | `{date}`                | Localized date (same as `{month}/{day}/{year}`)        | `09/16/98`                 |
    --- | `{time}`                | Localized time (same as `{hours}:{minutes}:{seconds}`) | `23:48:10`                 |
    --- | `{date_time}`           | Localized full date and time                           | `Wed Sep 16 23:48:10 1998` |
    --- | `{timezone}`            | Timezone offset                                        | `-0300`                    |
    ---
    ---@param fmt string The format string.
    ---@param timestamp? integer The timestamp to format.
    ---@param unit? gpm.std.time.Unit The timestamp unit, seconds by default.
    ---@return string str The formatted string.
    function time.format( fmt, timestamp, unit )
        local seconds, milliseconds, microseconds, nanoseconds = split( timestamp or now( unit, true ), unit, 2 )

        ---@type string[]
        local segments = {}

        ---@type integer
        local segment_count = 0

        ---@type integer
        local fmt_length = string_len( fmt ) + 1

        ---@type integer
        local position = 1

        while position ~= fmt_length do
            local uint8 = string_byte( fmt, position, position )
            if uint8 == nil then
                break
            elseif uint8 == 0x25 --[[ "%" ]] then
                segment_count = segment_count + 1
                segments[ segment_count ] = string_sub( fmt, position, position + 1 )
                position = math_min( position + 2, fmt_length )
            elseif uint8 == 0x7B --[[ "{" ]] then

                ---@type integer?
                local bracket_position

                for i = position + 1, fmt_length, 1 do
                    if string_byte( fmt, i, i ) == 0x7D --[[ "}" ]] then
                        bracket_position = i
                        break
                    end
                end

                if bracket_position == nil then
                    error( string_format( "missing '}' at position %d", position ), 2 )
                end

                ---@type string
                local key = string_sub( fmt, position + 1, bracket_position - 1 )

                if key == "nanoseconds" then
                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_format( "%03d", nanoseconds )
                elseif key == "microseconds" then
                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_format( "%03d", microseconds )
                elseif key == "milliseconds" then
                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_format( "%03d", milliseconds )
                else

                    local pattern_str = keys[ key ]
                    if pattern_str == nil then
                        error( string_format( "unknown value name - '%s'", key ), 2 )
                    end

                    segment_count = segment_count + 1
                    ---@diagnostic disable-next-line: assign-type-mismatch
                    segments[ segment_count ] = os_date( pattern_str, seconds )

                end

                position = math_min( bracket_position + 1, fmt_length )
            else

                ---@type integer?
                local bracket_position

                for i = position + 1, fmt_length, 1 do
                    if string_byte( fmt, i, i ) == 0x7B --[[ "{" ]] then
                        bracket_position = i
                        break
                    end
                end

                if bracket_position == nil then
                    bracket_position = fmt_length
                end

                bracket_position = bracket_position - 1

                if position == bracket_position then
                    position = position + 1
                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_char( uint8 )
                else
                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_sub( fmt, position, bracket_position )
                    position = math_min( bracket_position + 2, fmt_length )
                end
            end
        end

        return table_concat( segments, "", 1, segment_count )
    end

end
