---@diagnostic disable-next-line: undefined-global
local milliseconds_elapsed = SysTime or os.clock

local engine_hookCatch = dreamwork.engine.hookCatch

---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_get = raw.get
local raw_tonumber = raw.tonumber

local rbit = raw.bit
local rbit_bor = rbit.bor
local rbit_lshift = rbit.lshift

local math = std.math
local math_ceil = math.ceil
local math_modf = math.modf
local math_floor = math.floor

local os = std.os
local os_time = os.time
local os_date = os.date

local table = std.table
local table_concat = table.concat

local string = std.string
local string_byte = string.byte
local string_match = string.match
local string_lower = string.lower
local string_format = string.format
local string_gmatch = string.gmatch
local string_byteSplit = string.byteSplit
local string_interpolate = string.interpolate

local error = std.error


--- [SHARED AND MENU]
---
--- A library for working with time and date.
---
---@class dreamwork.std.time
---@field zone integer The timezone offset from UTC.
---@field dst boolean Whether the timezone is currently in daylight saving time.
---@field zone_dst integer The timezone offset from UTC during daylight saving time.
local time = {}
std.time = time

---@type integer
local zone = raw_tonumber( os_date( "%H", 0 ) ) - raw_tonumber( os_date( "!%H", 0 ) )
if (os_date( "%d", 0 ) - os_date( "!%d", 0 )) == 30 then
    zone = zone - 24
end

time.zone = zone
time.dst = ((raw_tonumber( os_date( "%z" ) ) * 0.01) - zone) ~= 0
time.zone_dst = zone + (time.dst and 1 or 0)


---@type integer
local current_utc_timestamp = os_time() - zone
local current_timestamp = current_utc_timestamp + (time.zone * 3600)

engine_hookCatch( "Tick", "dreamwork.std.time", function()
    current_utc_timestamp = os_time() - zone
    current_timestamp = current_utc_timestamp + (time.zone * 3600)
end )


local transform
do

    ---@param ts number
    ---@return number
    local function ts_m1e_3( ts )
        return ts / 1e3
    end

    ---@param ts number
    ---@return number
    local function ts_m1e_6( ts )
        return ts / 1e6
    end

    ---@param ts integer
    ---@return number
    local function ts_m1e3( ts )
        return ts * 1e3
    end

    ---@param ts number
    ---@return number
    local function ts_m1e6( ts )
        return ts * 1e6
    end

    ---@param ts number
    ---@return number
    local function ts_d60( ts )
        return ts / 60
    end

    ---@type table<integer, fun( ts: number ): number>
    local transformation_map = {
        -- nanoseconds (ns)
        [ 0x7375736E ] = ts_m1e_3,                                         -- ns to us
        [ 0x736D736E ] = ts_m1e_6,                                         -- ns to ms
        [ 0x73736E ]   = function( ts ) return ts * 1e-9 end,              -- ns to s
        [ 0x6D736E ]   = function( ts ) return (ts * 1e-9) / 60 end,       -- ns to m
        [ 0x68736E ]   = function( ts ) return (ts * 1e-9) / 3600 end,     -- ns to h
        [ 0x64736E ]   = function( ts ) return (ts * 1e-9) / 86400 end,    -- ns to d
        [ 0x77736E ]   = function( ts ) return (ts * 1e-9) / 604800 end,   -- ns to w
        [ 0x6F6D736E ] = function( ts ) return (ts * 1e-9) / 2592000 end,  -- ns to mo
        [ 0x79736E ]   = function( ts ) return (ts * 1e-9) / 31536000 end, -- ns to y

        -- microseconds (us)
        [ 0x736E7375 ] = ts_m1e3,                                          -- us to ns
        [ 0x736D7375 ] = ts_m1e_3,                                         -- us to ms
        [ 0x737375 ]   = ts_m1e_6,                                         -- us to s
        [ 0x6D7375 ]   = function( ts ) return (ts * 1e-6) / 60 end,       -- us to m
        [ 0x687375 ]   = function( ts ) return (ts * 1e-6) / 3600 end,     -- us to h
        [ 0x647375 ]   = function( ts ) return (ts * 1e-6) / 86400 end,    -- us to d
        [ 0x777375 ]   = function( ts ) return (ts * 1e-6) / 604800 end,   -- us to w
        [ 0x6F6D7375 ] = function( ts ) return (ts * 1e-6) / 2592000 end,  -- us to mo
        [ 0x797375 ]   = function( ts ) return (ts * 1e-6) / 31536000 end, -- us to y

        -- milliseconds (ms)
        [ 0x736E736D ] = ts_m1e6,                                          -- ms to ns
        [ 0x7375736D ] = ts_m1e3,                                          -- ms to us
        [ 0x73736D ]   = ts_m1e_3,                                         -- ms to s
        [ 0x6D736D ]   = function( ts ) return (ts * 1e-3) / 60 end,       -- ms to m
        [ 0x68736D ]   = function( ts ) return (ts * 1e-3) / 3600 end,     -- ms to h
        [ 0x64736D ]   = function( ts ) return (ts * 1e-3) / 86400 end,    -- ms to d
        [ 0x77736D ]   = function( ts ) return (ts * 1e-3) / 604800 end,   -- ms to w
        [ 0x6F6D736D ] = function( ts ) return (ts * 1e-3) / 2592000 end,  -- ms to mo
        [ 0x79736D ]   = function( ts ) return (ts * 1e-3) / 31536000 end, -- ms to y

        -- seconds (s)
        [ 0x736E0073 ] = function( ts ) return ts * 1e9 end,      -- s to ns
        [ 0x73750073 ] = ts_m1e6,                                 -- s to us
        [ 0x736D0073 ] = ts_m1e3,                                 -- s to ms
        [ 0x6D0073 ]   = ts_d60,                                  -- s to m
        [ 0x680073 ]   = function( ts ) return ts / 3600 end,     -- s to h
        [ 0x640073 ]   = function( ts ) return ts / 86400 end,    -- s to d
        [ 0x770073 ]   = function( ts ) return ts / 604800 end,   -- s to w
        [ 0x6F6D0073 ] = function( ts ) return ts / 2592000 end,  -- s to mo
        [ 0x790073 ]   = function( ts ) return ts / 31536000 end, -- s to y

        -- minutes (m)
        [ 0x736E006D ] = function( ts ) return (ts * 60) * 1e9 end, -- m to ns
        [ 0x7375006D ] = function( ts ) return (ts * 60) * 1e6 end, -- m to us
        [ 0x736D006D ] = function( ts ) return (ts * 60) * 1e3 end, -- m to ms
        [ 0x73006D ]   = function( ts ) return (ts * 60) end,       -- m to s
        [ 0x68006D ]   = ts_d60,                                    -- m to h
        [ 0x64006D ]   = function( ts ) return ts / 1440 end,       -- m to d
        [ 0x77006D ]   = function( ts ) return ts / 10080 end,      -- m to w
        [ 0x6F6D006D ] = function( ts ) return ts / 43200 end,      -- m to mo
        [ 0x79006D ]   = function( ts ) return ts / 525600 end,     -- m to y

        -- hours (h)
        [ 0x736E0068 ] = function( ts ) return (ts * 3600) * 1e9 end, -- h to ns
        [ 0x73750068 ] = function( ts ) return (ts * 3600) * 1e6 end, -- h to us
        [ 0x736D0068 ] = function( ts ) return (ts * 3600) * 1e3 end, -- h to ms
        [ 0x730068 ]   = function( ts ) return (ts * 3600) end,       -- h to s
        [ 0x6D0068 ]   = function( ts ) return (ts * 60) end,         -- h to m
        [ 0x640068 ]   = function( ts ) return ts / 24 end,           -- h to d
        [ 0x770068 ]   = function( ts ) return ts / 168 end,          -- h to w
        [ 0x6F6D0068 ] = function( ts ) return ts / 720 end,          -- h to mo
        [ 0x790068 ]   = function( ts ) return ts / 8760 end,         -- h to y

        -- days (d)
        [ 0x736E0064 ] = function( ts ) return (ts * 86400) * 1e9 end, -- d to ns
        [ 0x73750064 ] = function( ts ) return (ts * 86400) * 1e6 end, -- d to us
        [ 0x736D0064 ] = function( ts ) return (ts * 86400) * 1e3 end, -- d to ms
        [ 0x730064 ]   = function( ts ) return (ts * 86400) end,       -- d to s
        [ 0x6D0064 ]   = function( ts ) return ts * 1440 end,          -- d to m
        [ 0x680064 ]   = function( ts ) return ts * 24 end,            -- d to h
        [ 0x770064 ]   = function( ts ) return ts / 7 end,             -- d to w
        [ 0x6F6D0064 ] = function( ts ) return ts / 30 end,            -- d to mo
        [ 0x790064 ]   = function( ts ) return ts / 365 end,           -- d to y

        -- weeks (w)
        [ 0x736E0077 ] = function( ts ) return (ts * 604800) * 1e9 end, -- w to ns
        [ 0x73750077 ] = function( ts ) return (ts * 604800) * 1e6 end, -- w to us
        [ 0x736D0077 ] = function( ts ) return (ts * 604800) * 1e3 end, -- w to ms
        [ 0x730077 ]   = function( ts ) return (ts * 604800) end,       -- w to s
        [ 0x6D0077 ]   = function( ts ) return ts * 10080 end,          -- w to m
        [ 0x680077 ]   = function( ts ) return ts * 168 end,            -- w to h
        [ 0x640077 ]   = function( ts ) return ts * 7 end,              -- w to d
        [ 0x6F6D0077 ] = function( ts ) return ts / 4.285714286 end,    -- w to mo
        [ 0x790077 ]   = function( ts ) return ts / 52.142857143 end,   -- w to y

        -- months (mo)
        [ 0x736E6F6D ] = function( ts ) return (ts * 2592000) * 1e9 end, -- mo to ns
        [ 0x73756F6D ] = function( ts ) return (ts * 2592000) * 1e6 end, -- mo to us
        [ 0x736D6F6D ] = function( ts ) return (ts * 2592000) * 1e3 end, -- mo to ms
        [ 0x736F6D ]   = function( ts ) return (ts * 2592000) end,       -- mo to s
        [ 0x6D6F6D ]   = function( ts ) return ts * 43200 end,           -- mo to m
        [ 0x686F6D ]   = function( ts ) return ts * 720 end,             -- mo to h
        [ 0x646F6D ]   = function( ts ) return ts * 30 end,              -- mo to d
        [ 0x776F6D ]   = function( ts ) return ts * 4.285714286 end,     -- mo to w
        [ 0x796F6D ]   = function( ts ) return (ts * 30) / 365 end,      -- mo to y

        -- years (y)
        [ 0x736E0079 ] = function( ts ) return (ts * 31536000) * 1e9 end, -- y to ns
        [ 0x73750079 ] = function( ts ) return (ts * 31536000) * 1e6 end, -- y to us
        [ 0x736D0079 ] = function( ts ) return (ts * 31536000) * 1e3 end, -- y to ms
        [ 0x730079 ]   = function( ts ) return (ts * 31536000) end,       -- y to s
        [ 0x6D0079 ]   = function( ts ) return ts * 525600 end,           -- y to m
        [ 0x680079 ]   = function( ts ) return ts * 8760 end,             -- y to h
        [ 0x640079 ]   = function( ts ) return ts * 365 end,              -- y to d
        [ 0x770079 ]   = function( ts ) return ts * 52.142857143 end,     -- y to w
        [ 0x6F6D0079 ] = function( ts ) return (ts * 365) / 30 end        -- y to mo
    }

    --- [SHARED AND MENU]
    ---
    --- Transforms a timestamp from one unit to another.
    ---
    ---@param timestamp number The timestamp to transform.
    ---@param unit? dreamwork.std.time.Unit The unit to transform the timestamp from, 's' by default.
    ---@param target? dreamwork.std.time.Unit The unit to transform the timestamp to, 's' by default.
    ---@param as_float? boolean Whether to return the timestamp as a float, `false` by default.
    ---@param error_level? integer The error level to use, 2 by default.
    ---@return number timestamp The transformed timestamp.
    function transform( timestamp, unit, target, as_float, error_level )
        if error_level == nil then
            error_level = 2
        else
            error_level = error_level + 1
        end

        local unit_uint8_1, unit_uint8_2
        if unit == nil then
            unit_uint8_1, unit_uint8_2 = 0x73 --[[ `s` ]], 0x0
        else

            local unit_uint8_3
            unit_uint8_1, unit_uint8_2, unit_uint8_3 = string_byte( unit, 1, 3 )

            if unit_uint8_1 == nil then
                error( "unit cannot be empty string", error_level )
            elseif unit_uint8_3 ~= nil then
                error( "unit cannot be longer than 2 characters", error_level )
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
                error( "target cannot be empty string", error_level )
            elseif target_uint8_2 == nil then
                target_uint8_2 = 0x0
            end

        end

        ---@cast target_uint8_1 integer

        if unit_uint8_1 ~= target_uint8_1 or unit_uint8_2 ~= target_uint8_2 then
            local transform_fn = transformation_map[ rbit_bor(
                rbit_lshift( target_uint8_2, 24 ),
                rbit_lshift( target_uint8_1, 16 ),
                rbit_lshift( unit_uint8_2, 8 ),
                unit_uint8_1
            ) ]

            if transform_fn == nil then
                error( string_format( "required transformation from '%s' to '%s' does not exist", unit or "s", target or "s" ), error_level )
            end

            ---@cast transform_fn fun( ts: number ): number
            timestamp = transform_fn( timestamp )
        end

        if as_float then
            return timestamp
        end

        return (math_modf( timestamp ))
    end

end

--- [SHARED AND MENU]
---
--- Transforms a timestamp to a different unit.
---
---@param timestamp number The timestamp to transform.
---@param unit? dreamwork.std.time.Unit The unit to transform the timestamp from, 's' by default.
---@param target? dreamwork.std.time.Unit The unit to transform the timestamp to, 's' by default.
---@param as_float? boolean Whether to return the timestamp as a float, `false` by default.
---@return number timestamp The transformed timestamp.
function time.transform( timestamp, unit, target, as_float )
    return transform( timestamp, unit, target, as_float, 2 )
end

--- [SHARED AND MENU]
---
--- Returns the time elapsed since lua/game was started.
---
---@param unit? dreamwork.std.time.Unit The unit to return the elapsed time in, 's' by default.
---@param as_float? boolean Whether to return the elapsed time as a float, `true` by default.
---@return number timestamp The elapsed time in the specified unit.
function time.elapsed( unit, as_float )
    if unit == "s" or unit == nil then
        local float = milliseconds_elapsed()
        if as_float ~= false then
            return float
        end

        return math_floor( float )
    elseif unit == "ms" then
        local float = milliseconds_elapsed() * 1e3
        if as_float ~= false then
            return float
        end

        return math_floor( float )
    elseif unit == "us" then
        local float = milliseconds_elapsed() * 1e6
        if as_float ~= false then
            return float
        end

        return math_floor( float )
    elseif unit == "ns" then
        local float = milliseconds_elapsed() * 1e9
        if as_float ~= false then
            return float
        end

        return math_floor( float )
    end

    return transform( milliseconds_elapsed(), "s", unit, as_float ~= false, 2 )
end

do

    ---@type number
    local previous_time = 0

    --- [SHARED AND MENU]
    ---
    --- Returns the time elapsed since the last call to this function.
    ---
    ---@param unit? dreamwork.std.time.Unit The unit to return the elapsed time in, 's' by default.
    ---@param as_float? boolean Whether to return the elapsed time as a float, `true` by default.
    ---@return number delta The elapsed time in the specified unit.
    function time.tick( unit, as_float )
        local elapsed = milliseconds_elapsed()

        local delta = transform( elapsed - previous_time, nil, unit, as_float ~= false, 2 )
        previous_time = elapsed

        return delta
    end

end

--- [SHARED AND MENU]
---
--- Returns the current time in the specified unit.
---
---@param unit? dreamwork.std.time.Unit The unit to return the current time in, `s` by default.
---@param as_float? boolean Whether to return the timestamp as a float, `false` by default.
---@return integer | number timestamp The current timestamp in the specified unit.
local function now( unit, as_float )
    local timestamp = current_timestamp
    if not as_float and (unit == nil or unit == "s") then
        return timestamp
    end

    return transform( timestamp + (milliseconds_elapsed() % 1), nil, unit, as_float, 2 )
end

time.now = now

--- based on Howard Hinnant's "days_from_civil" algorithm
---
--- http://howardhinnant.github.io/date_algorithms.html#days_from_civil
---
--- https://gist.github.com/socantre/c9dfcc5bd106a601d395
---
---@param year? integer
---@param month? integer
---@param day? integer
---@return integer
function time.daysFromCivil( year, month, day )
    if year == nil or month == nil or day == nil then
        local timestamp_data = os_date( "!*t", current_timestamp )

        if year == nil then
            year = timestamp_data.year
        end

        if month == nil then
            month = timestamp_data.month
        end

        if day == nil then
            day = timestamp_data.day
        end
    end

    if month > 2 then
        month = month - 3
    else
        year = year - 1
        month = month + 9
    end

    local era = math_floor( year / 400 )
    local yoe = year - (era * 400)
    local doy = math_floor( (153 * month + 2) / 5 ) + day - 1
    local doe = (yoe * 365) + math_floor( yoe / 4 ) - math_floor( yoe / 100 ) + doy

    return (era * 146097) + doe - 719468
end

---@param days? integer
---@return integer year
---@return integer month
---@return integer day
function time.civilFromDays( days )
    if days == nil then
        local timestamp_data = os_date( "!*t", current_timestamp )
        return timestamp_data.year, timestamp_data.month, timestamp_data.day
    end

    days = days + 719468

    local era = math_floor( days / 146097 )
    local doe = days - (era * 146097) -- [0, 146096]

    local yoe = math_floor(
        (doe - math_floor( doe / 1460 ) +
            math_floor( doe / 36524 ) -
            math_floor( doe / 146096 )) / 365 ) -- [0, 399]

    local year = yoe + (era * 400)

    local doy = doe - ((365 * yoe) + math_floor( yoe / 4 ) - math_floor( yoe / 100 )) -- [0, 365]
    local mp = math_floor( (5 * doy + 2) / 153 )                                      -- [0, 11]
    local day = doy - math_floor( (153 * mp + 2) / 5 ) + 1                            -- [1, 31]
    local month = (mp < 10) and (mp + 3) or (mp - 9)                                  -- [1, 12]

    if month <= 2 then
        year = year + 1
    end

    return year, month, day
end

--- [SHARED AND MENU]
---
--- Checks if a year is a leap year.
---
---@param year? integer The year to check, the current year by default.
---@return boolean is_leap_year Returns `true` if the year is a leap year, otherwise `false`.
local function isLeapYear( year )
    if year == nil then
        year = os_date( "!*t", current_utc_timestamp + (time.zone * 3600) ).year
    end

    return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
end

time.isLeapYear = isLeapYear

---@type table<integer, integer>
local common_year_month_days = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

--- [SHARED AND MENU]
---
--- Returns the number of days in a given month of a given year, accounting for leap years.
---
--- The result is always in the range `[28, 31]`.
---
--- `month` is wrapped into the valid `[1, 12]` range via modulo before use, so out-of-range
--- values (e.g. `13` or `0`) are normalized rather than erroring.
---
---@param month? integer The month to get the number of days in (`1`–`12`), the current month by default.
---@param year? integer The year to get the number of days in, the current year by default.
---@return integer days_in_month The number of days in the month.
local function daysInMonth( month, year )
    if month == nil or year == nil then
        local timestamp_data = os_date( "!*t", current_timestamp )

        if month == nil then
            month = timestamp_data.month
        else
            month = (month - 1) % 12 + 1
        end

        if year == nil then
            year = timestamp_data.year
        end
    else
        month = (month - 1) % 12 + 1
    end

    if month == 2 and isLeapYear( year ) then
        return 29
    end

    return common_year_month_days[ month ]
end

time.daysInMonth = daysInMonth

---@param days integer
---@return integer weekday
function time.weekdayFromDays( days )
    return (days + 4) % 7
end

---@param x integer
---@param y integer
---@return integer difference
function time.weekdayDifference( x, y )
    return (x - y) % 7
end

---@param weekday integer
---@return integer next_weekday
function time.nextWeekday( weekday )
    return (weekday + 1) % 7
end

---@param weekday integer
---@return integer previous_weekday
function time.prevWeekday( weekday )
    return (weekday - 1) % 7
end

--- [SHARED AND MENU]
---
--- Splits a timestamp into seconds, milliseconds, microseconds and nanoseconds.
---
---@param timestamp integer
---@param unit? dreamwork.std.time.Unit
---@param error_level? integer
---@return integer seconds
---@return integer milliseconds
---@return integer microseconds
---@return integer nanoseconds
local function split( timestamp, unit, error_level )
    error_level = (error_level or 1) + 1

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
---@param duration_str dreamwork.std.time.DurationString The duration string to convert.
---@param unit? dreamwork.std.time.Unit The unit to convert the duration to, 's' by default.
---@param as_float? boolean Whether to return the duration as a float, `false` by default.
---@return integer timestamp The duration in the specified unit.
local function fromDuration( duration_str, unit, as_float )
    local seconds, milliseconds, microseconds, nanoseconds = 0, 0, 0, 0

    for number_str, unit_str in string_gmatch( duration_str, "(%-?%d*%.?%d+)(%l*)" ) do
        local value = raw_tonumber( number_str ) or 0

        if unit_str == "s" then
            seconds = seconds + value
        elseif unit_str == "ms" then
            milliseconds = milliseconds + value
        elseif unit_str == "us" then
            microseconds = microseconds + value
        elseif unit_str == "ns" then
            nanoseconds = nanoseconds + value
        else
            seconds = seconds + transform( value, unit_str, "s", true, 2 )
        end
    end

    if unit == "ms" then
        local float = (seconds * 1e3) + milliseconds + (microseconds / 1e3) + (nanoseconds / 1e6)

        if as_float then
            return float
        end

        return math_floor( float )
    elseif unit == "us" then
        local float = (seconds * 1e6) + (milliseconds * 1e3) + microseconds + (nanoseconds / 1e3)

        if as_float then
            return float
        end

        return math_floor( float )
    elseif unit == "ns" then
        local float = (seconds * 1e9) + (milliseconds * 1e6) + (microseconds * 1e3) + nanoseconds

        if as_float then
            return float
        end

        return math_floor( float )
    end

    return transform( seconds + (nanoseconds / 1e9) + (microseconds / 1e6) + (milliseconds / 1e3), nil, unit, as_float, 2 )
end

time.fromDuration = fromDuration

do

    ---@type table<integer, string>[]
    local duration_units = {
        { 31536000, "y" },
        { 2592000,  "mo" },
        { 604800,   "w" },
        { 86400,    "d" },
        { 3600,     "h" },
        { 60,       "m" }
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
    ---@param unit? dreamwork.std.time.Unit The unit to convert the timestamp to, 's' by default.
    ---@return string duration_str The duration string.
    function time.toDuration( timestamp, unit )
        local seconds, milliseconds, microseconds, nanoseconds = split( timestamp, unit, 2 )
        local segments, segment_count = {}, 0

        if seconds ~= 0 then
            for i = 1, 6, 1 do
                local lst = duration_units[ i ]

                local value = lst[ 1 ]
                if seconds >= value then
                    local count = math_floor( seconds / value )
                    seconds = seconds - (count * value)

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

        if segment_count == 0 then
            return "0s"
        end

        return table_concat( segments, " ", 1, segment_count )
    end

end


do

    --- [SHARED AND MENU]
    ---
    --- Represents a date and time info.
    ---
    ---@class dreamwork.std.time.DateInfo
    ---@field day integer The day of the month. [1-31]
    ---@field month integer The month of the year. [1-12]
    ---@field year integer The year.
    ---
    ---@field year_day integer The day of the year. [1–366]
    ---@field year_week integer The week number of the year. [0-53]
    ---@field month_week integer The week number of the month. [1-4]
    ---@field weekday integer The day of the week. [0-6]
    ---
    ---@field hours integer The number of hours. [0-23]
    ---@field minutes integer The number of minutes. [0-59]
    ---@field seconds integer The number of seconds. [0-59]
    ---
    ---@field hours12 integer The number of hours in 12-hour format. [1-12]
    ---@field period "AM" | "PM" The period of the day.
    ---
    ---@field is_dst boolean Is the date in summer time (daylight saving)?
    ---
    ---@field milliseconds integer The number of milliseconds. [0-999]
    ---@field microseconds integer The number of microseconds. [0-999]
    ---@field nanoseconds integer The number of nanoseconds. [0-999]

    --- [SHARED AND MENU]
    ---
    --- Returns a table with the date and time components.
    ---
    ---@param timestamp? number The timestamp to parse.
    ---@param unit? dreamwork.std.time.Unit The unit to parse the timestamp from, 's' by default.
    ---@param in_utc? boolean Whether the timestamp is in UTC, `false` by default.
    ---@return dreamwork.std.time.DateInfo date_info The date and time components.
    function time.parse( timestamp, unit, in_utc )
        local seconds, milliseconds, microseconds, nanoseconds = split( timestamp or now( unit, true ), unit, 2 )
        in_utc = in_utc == true

        local osdate = os_date( in_utc and "!*t" or "*t", seconds )
        local month_day = osdate.day

        ---@diagnostic disable-next-line: param-type-mismatch
        local values = string_byteSplit( os_date( in_utc and "!%I;%p;%W" or "%I;%p;%W", seconds ), 0x3B --[[ ";" ]] )

        return {
            day = month_day,
            year = osdate.year,
            month = osdate.month,

            year_day = osdate.yday,
            year_week = (tonumber( values[ 3 ], 10 ) or 0) + 1,
            month_week = math_ceil( month_day / 7 ),
            weekday = (osdate.wday + 5) % 7,

            hours12 = tonumber( values[ 1 ], 10 ) or 0,
            period = values[ 2 ] or "AM",

            is_dst = osdate.isdst,

            hours = osdate.hour,
            minutes = osdate.min,
            seconds = osdate.sec,

            milliseconds = milliseconds or 0,
            microseconds = microseconds or 0,
            nanoseconds = nanoseconds or 0
        }
    end

end

do

    ---@param seconds_timestamp number
    ---@param seconds_duration number
    ---@param unit? dreamwork.std.time.Unit
    ---@param as_float? boolean
    ---@return number new_timestamp
    local function shift( seconds_timestamp, seconds_duration, unit, as_float )
        local timestamp_seconds, timestamp_remainder = math_modf( seconds_timestamp )
        local duration_seconds, duration_remainder = math_modf( seconds_duration )

        local duration_years = math_modf( duration_seconds / 31536000 )
        duration_seconds = duration_seconds - (duration_years * 31536000)

        local duration_months = math_modf( duration_seconds / 2592000 )
        duration_seconds = duration_seconds - (duration_months * 2592000)

        local duration_days = math_modf( duration_seconds / 86400 )
        duration_seconds = duration_seconds - (duration_days * 86400)

        if not (duration_years == 0 and duration_months == 0 and duration_days == 0) then
            local timestamp_data = os_date( "*t", timestamp_seconds )

            timestamp_data.year = timestamp_data.year + duration_years
            timestamp_data.month = timestamp_data.month + duration_months
            timestamp_data.day = timestamp_data.day + duration_days
            timestamp_data.isdst = nil

            timestamp_seconds = os_time( timestamp_data )
        end

        return transform( timestamp_seconds + timestamp_remainder + duration_remainder, "s", unit, as_float, 2 )
    end

    --- [SHARED AND MENU]
    ---
    --- Adds a duration to a timestamp.
    ---
    --- The duration string can have the following units:
    --- `ns`, `us`, `ms`, `s`, `m`, `h`, `d`, `w`, `y`.
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
    ---@param timestamp number The timestamp to add the duration to.
    ---@param unit? dreamwork.std.time.Unit The unit to add the duration to, 's' by default.
    ---@param duration_str dreamwork.std.time.DurationString The duration string to add.
    ---@param as_float? boolean Whether to return the timestamp as a float, `false` by default.
    ---@return number new_timestamp
    function time.add( timestamp, unit, duration_str, as_float )
        return shift( transform( timestamp or now( unit, as_float ), unit, "s", true, 2 ), fromDuration( duration_str, "s", true ), unit, as_float )
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
    ---@param timestamp number The timestamp to subtract the duration from.
    ---@param unit? dreamwork.std.time.Unit The unit to subtract the duration from, 's' by default.
    ---@param duration_str dreamwork.std.time.DurationString The duration string to subtract.
    ---@param as_float? boolean Whether to return the timestamp as a float, `false` by default.
    ---@return number new_timestamp
    function time.sub( timestamp, unit, duration_str, as_float )
        return shift( transform( timestamp or now( unit, as_float ), unit, "s", true, 2 ), -fromDuration( duration_str, "s", true ), unit, as_float )
    end

end

do

    ---@type table<string, string>
    local keys = {
        -- %d	Day of the month [01-31]	16
        day = "%d",
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
        -- %W	Week of the year [00-53]	37
        year_week = "%W",
        -- %j	Day of the year [001-365]	259
        year_day = "%j",

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
        weekday = "%w",
        -- %A	Full weekday name	Wednesday
        weekday_name = "%A",
        -- %a	Abbreviated weekday name	Wed
        weekday_short_name = "%a",

        -- %z	Timezone	-0300
        timezone = "%z",

        -- %X	Time (Same as %H:%M:%S)	23:48:10
        time = "%X",
        -- %x	Date (Same as %m/%d/%y)	09/16/98
        date = "%x",

        -- %c	Locale-appropriate date and time	Varies by platform and language settings
        date_time = "%c"
    }

    ---@class dreamwork.std.time.FormatBuffer : dreamwork.std.Metatable
    ---@field [ 1 ] integer seconds
    ---@field seconds string
    ---@field [ 2 ] integer milliseconds
    ---@field milliseconds string
    ---@field [ 3 ] integer microseconds
    ---@field microseconds string
    ---@field [ 4 ] integer nanoseconds
    ---@field nanoseconds string
    ---@field timezone string
    local FormatBuffer = {}

    ---@type table<string, integer>
    local key_to_index = {
        milliseconds = 2,
        microseconds = 3,
        nanoseconds = 4
    }

    ---@param key string
    ---@protected
    function FormatBuffer:__index( key )
        if key == "milliseconds" or key == "microseconds" or key == "nanoseconds" then
            local value = string_format( "%03d", raw_get( self, key_to_index[ key ] ) or 0 )
            ---@diagnostic disable-next-line: assign-type-mismatch
            self[ key ] = value
            return value
        end

        if key == "timezone" then
            local timezone

            local value = time.zone * 0x64
            if value < 0 then
                timezone = string_format( "-%04d", -value )
            else
                timezone = string_format( "+%04d", value )
            end

            self.timezone = timezone
            return timezone
        end

        local pattern_str = keys[ key ]
        if pattern_str == nil then
            error( string_format( "unknown value name - '%s'", key ), 4 )
        end

        local value

        if raw_get( self, 0 ) --[[ in_utc ]] then
            value = os_date( "!" .. pattern_str, raw_get( self, 1 ) )
        else
            value = os_date( pattern_str, raw_get( self, 1 ) )
        end

        ---@diagnostic disable-next-line: assign-type-mismatch
        self[ key ] = value
        return value
    end

    --- [SHARED AND MENU]
    ---
    --- Converts a timestamp to a formatted string.
    ---
    --- ### Format Keys
    --- | Key                     | Description                                            | Example                    |
    --- |-------------------------|--------------------------------------------------------|----------------------------|
    --- | `{day}`                 | Day of the month [01–31]                               | `16`                       |
    --- | `{weekday}`             | Weekday number [0–6, Sunday = 0]                       | `3`                        |
    --- | `{weekday_name}`        | Full weekday name                                      | `Wednesday`                |
    --- | `{weekday_short_name}`  | Abbreviated weekday name                               | `Wed`                      |
    --- | `{month}`               | Month number [01–12]                                   | `09`                       |
    --- | `{month_name}`          | Full month name                                        | `September`                |
    --- | `{month_short_name}`    | Abbreviated month name                                 | `Sep`                      |
    --- | `{year}`                | Full year                                              | `1998`                     |
    --- | `{year_day}`            | Day of the year [001–365]                              | `259`                      |
    --- | `{year_week}`           | Week number of the year [00–53]                        | `37`                       |
    --- | `{year_short}`          | Two-digit year [00–99]                                 | `98`                       |
    --- | `{hours}`               | Hour in 24-hour format [00–23]                         | `23`                       |
    --- | `{minutes}`             | Minute [00–59]                                         | `48`                       |
    --- | `{seconds}`             | Second [00–60] (leap second included)                  | `10`                       |
    --- | `{milliseconds}`        | Millisecond [000–999]                                  | `010`                      |
    --- | `{microseconds}`        | Microsecond [000–999]                                  | `010`                      |
    --- | `{nanoseconds}`         | Nanosecond [000–999]                                   | `010`                      |
    --- | `{hours12}`             | Hour in 12-hour format [01–12]                         | `11`                       |
    --- | `{period}`              | AM or PM                                               | `pm`                       |
    --- | `{date}`                | Localized date (same as `{month}/{day}/{year}`)  | `09/16/98`                 |
    --- | `{time}`                | Localized time (same as `{hours}:{minutes}:{seconds}`) | `23:48:10`                 |
    --- | `{date_time}`           | Localized full date and time                           | `Wed Sep 16 23:48:10 1998` |
    --- | `{timezone}`            | Timezone offset                                        | `-0300`                    |
    ---
    ---@param fmt string The format string.
    ---@param timestamp? integer The timestamp to format.
    ---@param unit? dreamwork.std.time.Unit The timestamp unit, 's' by default.
    ---@param in_utc? boolean Use UTC instead of local timezone, `false` by default.
    ---@return string str The formatted string.
    function time.format( fmt, timestamp, unit, in_utc )
        return string_interpolate( fmt, setmetatable( { [ 0 ] = in_utc, split( timestamp or now( unit, true ), unit, 2 ) }, FormatBuffer ) )
    end

end

--- [SHARED AND MENU]
---
--- Converts a timestamp to an RFC 2822 date-time string, for example `Mon, 15 Jan 2024 10:30:00 +0000`.
---
--- This is the format used by email headers ( `Date:` ) and HTTP's obsolete `rfc1123-date`,
--- and is also what JavaScript's `Date.prototype.toString()` timezone-less variants are based on.
---
---@param timestamp? integer The timestamp to convert, current time by default.
---@param unit? dreamwork.std.time.Unit The unit of `timestamp`, `s` by default.
---@param in_utc? boolean Whether to format the string in UTC, `false` by default.
---@return string str The RFC 2822 date-time string.
function time.toRFC2822( timestamp, unit, in_utc )
    if timestamp == nil then
        timestamp = now( unit, false )
    end

    ---@type integer
    local seconds_timestamp

    if unit == nil or unit == "s" then
        seconds_timestamp = timestamp
    else
        seconds_timestamp = transform( timestamp, unit, "s", false, 2 )
    end

    if in_utc then
        return os_date( "!%a, %d %b %Y %H:%M:%S +0000", seconds_timestamp )
    end

    local date_string = os_date( "%a, %d %b %Y %H:%M:%S", seconds_timestamp )
    local timezone = time.zone

    if timezone < 0 then
        return date_string .. string_format( " -%02d00", -timezone )
    end

    return date_string .. string_format( " +%02d00", timezone )
end

--- [SHARED AND MENU]
---
--- Converts a timestamp to a JS-like ( ISO 8601 ) date-time string,
--- for example `2024-01-15T10:30:00.000Z` or `2024-01-15T10:30:00.000-05:00` with timezone offset.
---
--- The output is compatible with JavaScript's `Date.prototype.toISOString()` /
--- `JSON.stringify( new Date() )`, and can be parsed back with `time.fromISOString`.
---
---@param timestamp? integer The timestamp to convert, current time by default.
---@param unit? dreamwork.std.time.Unit The unit of `timestamp`, `s` by default.
---@param in_utc? boolean Whether to format the string in UTC ( with a `Z` suffix ), `false` by default.
---@return string str The JS-like date-time string.
function time.toISOString( timestamp, unit, in_utc )
    if timestamp == nil then
        timestamp = now( unit, false )
    end

    ---@type string
    local milliseconds_string

    ---@type integer
    local seconds_timestamp
    if unit == nil or unit == "s" then
        seconds_timestamp = timestamp
    else
        seconds_timestamp = transform( timestamp, unit, "s", false, 2 )

        if unit == "ns" or unit == "us" or unit == "ms" then
            milliseconds_string = string_format( ".%03d", math_floor( timestamp ) - (seconds_timestamp * 1e3) )
        end
    end

    ---@type string
    local timezone_string

    ---@type string
    local date_string

    if in_utc then
        date_string = os_date( "!%Y-%m-%dT%H:%M:%S", seconds_timestamp )
        timezone_string = "Z"
    else

        date_string = os_date( "%Y-%m-%dT%H:%M:%S", seconds_timestamp )

        local timezone = time.zone
        if timezone < 0 then
            timezone_string = string_format( "-%02d:00", -timezone )
        else
            timezone_string = string_format( "+%02d:00", timezone )
        end

    end

    if milliseconds_string == nil then
        return date_string .. timezone_string
    end

    return date_string .. milliseconds_string .. timezone_string
end

--- [SHARED AND MENU]
---
--- Parses a JS-like ( ISO 8601 ) date-time string, as produced by JavaScript's
--- `Date.prototype.toISOString()` / `JSON.stringify( new Date() )`, and converts it to a unix timestamp.
---
--- Supported formats ( matching JavaScript's `Date Time String Format` ):
--- * `2024-01-15T10:30:00.000Z` - UTC, with milliseconds
--- * `2024-01-15T10:30:00Z` - UTC, without milliseconds
--- * `2024-01-15T10:30:00.000+02:00` / `2024-01-15T10:30:00+0200` - explicit offset
--- * `2024-01-15T10:30:00` - no timezone info, interpreted using the library's local timezone ( `std.TZ` )
--- * `2024-01-15` - date only, interpreted as UTC midnight, matching JavaScript's behaviour
---
---@param str string The JS-like date-time string to parse.
---@param unit? dreamwork.std.time.Unit The unit to return the timestamp in, `s` by default.
---@param as_float? boolean Whether to return the timestamp as a float, `false` by default.
---@return number timestamp The unix timestamp in the specified unit.
function time.fromISOString( str, unit, as_float )
    local year_str, month_str, day_str, rest = string_match( str, "^(%d%d%d%d)%-(%d%d)%-(%d%d)(.*)$" )
    if year_str == nil or month_str == nil or day_str == nil then
        error( string_format( "invalid date-time string - '%s'", str ), 2 )
    end

    ---@cast rest string

    local year = raw_tonumber( year_str, 10 ) or 0
    local month = raw_tonumber( month_str, 10 ) or 0
    local day = raw_tonumber( day_str, 10 ) or 0

    local hours, minutes, seconds, fraction, tz_str = 0, 0, 0, nil, nil

    if rest ~= "" then
        local hours_str, minutes_str, seconds_str, milliseconds_string, tz = string_match( rest, "^[T ](%d%d):(%d%d):?(%d?%d?)%.?(%d*)(.*)$" )
        if hours_str == nil or minutes_str == nil or seconds_str == nil then
            error( string_format( "invalid date-time string - '%s'", str ), 2 )
        end

        hours, minutes = raw_tonumber( hours_str, 10 ), raw_tonumber( minutes_str, 10 )
        seconds = s ~= "" and raw_tonumber( seconds_str, 10 ) or 0
        fraction = milliseconds_string
        tz_str = tz
    end

    local offset_seconds

    if rest == "" then
        -- date-only strings are interpreted as UTC, matching JavaScript's behaviour
        offset_seconds = 0
    elseif tz_str == nil or tz_str == "" then
        -- no timezone info, interpreted using the library's local timezone, matching JavaScript's behaviour
        offset_seconds = time.zone * 3600
    elseif tz_str == "Z" or tz_str == "z" then
        offset_seconds = 0
    else
        local sign, offset_hours, offset_minutes = string_match( tz_str, "^([%+%-])(%d%d):?(%d%d)$" )
        if sign == nil then
            error( string_format( "invalid timezone offset - '%s'", tz_str ), 2 )
        end

        offset_seconds = raw_tonumber( offset_hours, 10 ) * 3600 + raw_tonumber( offset_minutes, 10 ) * 60

        if sign == "-" then
            offset_seconds = -offset_seconds
        end
    end

    local milliseconds = 0

    if fraction ~= nil and fraction ~= "" then
        local digit_count = #fraction

        milliseconds = raw_tonumber( fraction, 10 ) or 0

        if digit_count >= 3 then
            for _ = 1, digit_count - 3 do
                milliseconds = math_floor( milliseconds / 10 )
            end
        else
            for _ = 1, 3 - digit_count do
                milliseconds = milliseconds * 10
            end
        end
    end

    return transform( os_time( {
        year = year,
        month = month,
        day = day,
        hour = hours,
        min = minutes,
        sec = seconds,
    } ) - offset_seconds, "s", unit, as_float, 2 )
end

do

    ---@type table<string, integer>
    local month_map = {
        [ 7233898 ] = 1,
        [ 6448486 ] = 2,
        [ 7496045 ] = 3,
        [ 7499873 ] = 4,
        [ 7954797 ] = 5,
        [ 7239018 ] = 6,
        [ 7107946 ] = 7,
        [ 6780257 ] = 8,
        [ 7366003 ] = 9,
        [ 7627631 ] = 10,
        [ 7761774 ] = 11,
        [ 6514020 ] = 12
    }

    ---@type table<string, integer>
    local rfc2822_timezones = {
        [ 66 ] = 7200,
        [ 83 ] = -21600,
        [ 68 ] = 14400,
        [ 5526341 ] = -18000,
        [ 69 ] = 18000,
        [ 84 ] = -25200,
        [ 78 ] = -3600,
        [ 5526349 ] = -25200,
        [ 71 ] = 25200,
        [ 5526339 ] = -21600,
        [ 87 ] = -36000,
        [ 72 ] = 28800,
        [ 73 ] = 32400,
        [ 70 ] = 21600,
        [ 89 ] = -43200,
        [ 86 ] = -32400,
        [ 75 ] = 36000,
        [ 5524807 ] = 0,
        [ 5522501 ] = -14400,
        [ 21589 ] = 0,
        [ 76 ] = 39600,
        [ 5522499 ] = -18000,
        [ 77 ] = 43200,
        [ 5522509 ] = -21600,
        [ 79 ] = -7200,
        [ 5526352 ] = -28800,
        [ 5522512 ] = -25200,
        [ 65 ] = 3600,
        [ 80 ] = -10800,
        [ 81 ] = -14400,
        [ 88 ] = -39600,
        [ 90 ] = 0,
        [ 82 ] = -18000,
        [ 67 ] = 10800,
        [ 85 ] = -28800,
    }

    --- [SHARED AND MENU]
    ---
    --- Parses an RFC 2822 date-time string ( as used in email `Date:` headers, for example
    --- `Mon, 15 Jan 2024 10:30:00 +0000` ) and converts it to a unix timestamp.
    ---
    --- The weekday name, the seconds and the timezone are all optional. The timezone can be
    --- a numeric offset ( `+0200`, `-0500` ), or one of the named zones `UT`, `GMT`, `UTC`, `EST`,
    --- `EDT`, `CST`, `CDT`, `MST`, `MDT`, `PST`, `PDT`. A missing or unrecognised timezone is
    --- treated as UTC, per RFC 2822's handling of the obsolete military zones.
    ---
    ---@param str string The RFC 2822 date-time string to parse.
    ---@param unit? dreamwork.std.time.Unit The unit to return the timestamp in, `s` by default.
    ---@param as_float? boolean Whether to return the timestamp as a float, `false` by default.
    ---@return number timestamp The unix timestamp in the specified unit.
    function time.fromRFC2822( str, unit, as_float )
        local day_str, month_str, year_str, hours_str, minutes_str, seconds_str, zone_str =
            string_match( str, "^%a+,%s*(%d%d?)%s+(%a+)%s+(%d%d+)%s+(%d%d):(%d%d):?(%d?%d?)%s*([^%s]*)$" )

        if day_str == nil or month_str == nil or year_str == nil or hours_str == nil or minutes_str == nil or seconds_str == nil then
            error( string_format( "invalid date-time string - '%s'", str ), 2 )
        end

        ---@cast zone_str string

        local mu8_1, mu8_2, mu8_3 = string_byte( string_lower( month_str ), 1, 3 )

        local month = month_map[ rbit_bor(
            rbit_lshift( mu8_3 or 0, 16 ),
            rbit_lshift( mu8_2 or 0, 8 ),
            mu8_1 or 0
        ) ]

        if month == nil then
            error( string_format( "invalid month name - '%s'", month_str ), 2 )
        end

        local day = raw_tonumber( day_str, 10 ) or 0
        local year = raw_tonumber( year_str, 10 ) or 0
        local hours = raw_tonumber( hours_str, 10 ) or 0
        local minutes = raw_tonumber( minutes_str, 10 ) or 0
        local seconds = raw_tonumber( seconds_str, 10 ) or 0

        -- obsolete 2-digit year rule
        if year < 100 then
            year = year + (year < 50 and 2000 or 1900)
        end

        local offset_seconds = 0

        if not (zone_str == nil or string_byte( zone_str, 1, 1 ) == nil) then
            local sign, offset_hours, offset_minutes = string_match( zone_str, "^([%+%-])(%d%d)(%d%d)$" )
            if sign == nil then
                -- unrecognised names ( including the obsolete military zones ) are treated as UTC
                local zu8_1, zu8_2, zu8_3 = string_byte( string_lower( zone_str ), 1, 3 )

                offset_seconds = rfc2822_timezones[ rbit_bor(
                    rbit_lshift( zu8_3 or 0, 16 ),
                    rbit_lshift( zu8_2 or 0, 8 ),
                    zu8_1 or 0
                ) ] or 0
            else
                offset_seconds = (raw_tonumber( offset_hours, 10 ) * 3600) +
                    (raw_tonumber( offset_minutes, 10 ) * 60)

                if string_byte( sign, 1, 1 ) == 0x2D --[[ - ]] then
                    offset_seconds = -offset_seconds
                end
            end
        end

        return transform(
            os_time( {
                day = day,
                month = month,
                year = year,
                hour = hours,
                min = minutes,
                sec = seconds,
            } ) - offset_seconds,
            "s",
            unit,
            as_float,
            2
        )
    end

end

local tm = time.add( time.now( "s", true ), "s", "1d", true )

-- local tm = time.now( "s", true )

std.printTable( time.parse( tm ) )
-- print( "ymd:", td.year, td.month, td.day )
-- print( "time:", td.hours, td.minutes, td.seconds, td.milliseconds )

-- local tms = now( "s", true ) - now( "s", false )
-- print( transform( tms, "s", "ms", false ) )
-- print( transform( tms, "s", "us", false ) )
-- print( transform( tms, "s", "ns", false ) )

-- print( "days: ", time.transform( tm, "s", "d", true ) )

-- print( "cdays: ", days_from_civil( td.year, td.month, td.day ) )


-- print( "-10: ", days_from_civil( 2026 - 10, 10, 03 ) )
-- print( "26: ", days_from_civil( 2026, 10, 03 ) )
