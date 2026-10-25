local engine_hookCatch = dreamwork.engine.hookCatch
local dreamwork_getUpTime = dreamwork.getUpTime

---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_get = raw.get
local raw_pairs = raw.pairs
local raw_tonumber = raw.tonumber

local math = std.math
local math_ceil = math.ceil
local math_modf = math.modf
local math_trunc = math.trunc
local math_floor = math.floor
local math_log10 = math.log10

local os = std.os
local os_time = os.time
local os_date = os.date

local table = std.table
local table_concat = table.concat

local string = std.string
local string_sub = string.sub
local string_match = string.match
local string_lower = string.lower
local string_format = string.format
local string_gmatch = string.gmatch
local string_interpolate = string.interpolate

local error = std.error

---@param value number
---@return number
local function snap( value )
    local nearest = math_floor( value + 0.5 )

    local difference = value - nearest
    if difference < 0 then
        difference = -difference
    end

    if difference <= (value < 0 and -value or value) * 4.440892098500626e-16 then
        return nearest
    end

    return value
end


--- [SHARED AND MENU]
---
--- A library for working with time and date.
---
--- All timestamps are Unix timestamps (time since `1970-01-01T00:00:00Z` in the given unit)
--- and are always in UTC; the local timezone is only applied when a timestamp is turned into
--- a calendar date or a string, or parsed back from one (`time.parse`, `time.format`,
--- `time.toISOString`, ...).
---
--- By default the local timezone follows the host, including its daylight saving rules.
--- Assigning a different value to `time.zone` switches to a fixed UTC offset without DST.
---
---@class dreamwork.std.time
---@field zone number The standard (non-DST) UTC offset of the local timezone in hours, may be fractional (e.g. `5.5`). Assign a different value to use a fixed UTC offset instead of the host's timezone.
---@field dst boolean Whether the host's timezone is currently in daylight saving time.
---@field zone_dst number The UTC offset of the host's timezone during daylight saving time in hours, equal to `zone` if the host has no DST.
local time = {}
std.time = time

---@type table<string, number>
local unit_nanoseconds = {
    ns = 1,
    us = 1e3,
    ms = 1e6,
    s = 1e9,
    m = 6e10,
    h = 3.6e12,
    d = 8.64e13,
    w = 6.048e14,
    mo = 2.592e15,
    y = 3.1536e16
}

local transform
do

    -- exact integer ratios, `multipliers[ unit ][ target ]` if `unit` is larger than `target`, otherwise `divisors[ unit ][ target ]`

    ---@type table<string, table<string, number>>
    local multipliers = {}

    ---@type table<string, table<string, number>>
    local divisors = {}

    for unit, unit_ns in raw_pairs( unit_nanoseconds ) do
        local unit_multipliers, unit_divisors = {}, {}

        for target, target_ns in raw_pairs( unit_nanoseconds ) do
            if unit_ns >= target_ns then
                unit_multipliers[ target ] = unit_ns / target_ns
            else
                unit_divisors[ target ] = target_ns / unit_ns
            end
        end

        multipliers[ unit ] = unit_multipliers
        divisors[ unit ] = unit_divisors
    end

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
        if unit == nil then
            unit = "s"
        end

        if target == nil then
            target = "s"
        end

        if unit ~= target then
            local unit_multipliers = multipliers[ unit ]
            if unit_multipliers == nil then
                error( string_format( "unknown time unit '%s'", unit ), error_level == nil and 2 or error_level + 1 )
            end

            local multiplier = unit_multipliers[ target ]
            if multiplier == nil then
                local divisor = divisors[ unit ][ target ]
                if divisor == nil then
                    error( string_format( "unknown time unit '%s'", target ), error_level == nil and 2 or error_level + 1 )
                end

                timestamp = timestamp / divisor
            else
                timestamp = timestamp * multiplier

                if not as_float then
                    return math_trunc( snap( timestamp ) )
                end
            end
        elseif multipliers[ unit ] == nil then
            error( string_format( "unknown time unit '%s'", unit ), error_level == nil and 2 or error_level + 1 )
        end

        if as_float then
            return timestamp
        end

        return math_trunc( timestamp )
    end

end

--- [SHARED AND MENU]
---
--- Transforms a timestamp to a different unit.
---
--- A double holds ~16 significant digits, so a Unix timestamp in `ns` (`~1.7e18`) is only
--- precise to `~256ns`, and the same moment in float seconds to `~240ns`.
---
---@param timestamp number The timestamp to transform.
---@param unit? dreamwork.std.time.Unit The unit to transform the timestamp from, 's' by default.
---@param target? dreamwork.std.time.Unit The unit to transform the timestamp to, 's' by default.
---@param as_float? boolean Whether to return the timestamp as a float, `false` by default.
---@return number timestamp The transformed timestamp.
function time.transform( timestamp, unit, target, as_float )
    return transform( timestamp, unit, target, as_float, 2 )
end

--- Splits a timestamp into whole seconds and the sub-second remainder.
---
--- Seconds are floored, so the remainder is always positive (`-1.5s` is `-2s` and `500ms`).
---
---@param timestamp number
---@param unit? dreamwork.std.time.Unit
---@param error_level? integer
---@return integer seconds
---@return integer nanoseconds The sub-second remainder in nanoseconds. [0, 999999999]
local function split( timestamp, unit, error_level )
    local nanoseconds_per_unit = unit_nanoseconds[ unit or "s" ]
    if nanoseconds_per_unit == nil then
        error( string_format( "unknown time unit '%s'", unit ), (error_level or 1) + 1 )
    end

    local seconds, nanoseconds

    if nanoseconds_per_unit < 1e9 then
        -- integer `ms`/`us`/`ns` timestamps are split exactly
        local per_second = 1e9 / nanoseconds_per_unit
        seconds = math_floor( timestamp / per_second )
        nanoseconds = math_floor( (timestamp - (seconds * per_second)) * nanoseconds_per_unit + 0.5 )
    else
        local float = timestamp * (nanoseconds_per_unit / 1e9)
        seconds = math_floor( float )

        -- a double can't hold nanoseconds of large values (e.g. `1.7e9 + 0.001` is `...0.00099992`),
        -- so round to the finest decimal step it can represent
        local step = 1

        local ulp_ns = (float < 0 and -float or float) * 2.220446049250313e-7
        if ulp_ns > 0.5 then
            step = 10 ^ math_ceil( math_log10( ulp_ns ) )
        end

        nanoseconds = math_floor( (float - seconds) * 1e9 / step + 0.5 ) * step
    end

    if nanoseconds >= 1e9 then
        return seconds + 1, nanoseconds - 1e9
    end

    return seconds, nanoseconds
end

---@param year integer
---@param month integer
---@param day integer
---@return integer days
local function days_from_civil( year, month, day )
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

---@param days integer
---@return integer year
---@return integer month
---@return integer day
local function civil_from_days( days )
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

-- `os.time` with UTC fields reads them as local standard time (`isdst = false`), the difference is the standard offset
---@type integer
local host_std_offset
do
    local timestamp = os_time()
    host_std_offset = timestamp - os_time( os_date( "!*t", timestamp ) )
end

---@type number
local host_zone = host_std_offset / 3600

--- Returns the host's UTC offset (including DST) at the given moment, in seconds,
--- and whether the host is in DST at that moment.
---
---@type fun( timestamp: number ): integer, boolean
local host_offset
do

    ---@type table<integer, integer>
    local offsets = {}

    ---@type table<integer, boolean>
    local dsts = {}

    local cache_size = 0

    -- DST transitions happen on 15 minute boundaries
    function host_offset( timestamp )
        local bucket = math_floor( timestamp / 900 )

        local offset = offsets[ bucket ]
        if offset ~= nil then
            return offset, dsts[ bucket ]
        end

        local bucket_timestamp = bucket * 900
        local is_dst = false

        local date = os_date( "*t", bucket_timestamp )
        if date == nil then
            -- out of the host's `time_t` range
            offset = host_std_offset
        else
            offset = (days_from_civil( date.year, date.month, date.day ) * 86400 + date.hour * 3600 + date.min * 60 + date.sec) - bucket_timestamp
            is_dst = date.isdst == true
        end

        if cache_size == 512 then
            offsets, dsts, cache_size = {}, {}, 0
        end

        offsets[ bucket ] = offset
        dsts[ bucket ] = is_dst
        cache_size = cache_size + 1

        return offset, is_dst
    end

end

time.zone = host_zone

do

    local timestamp = os_time()
    local year = civil_from_days( math_floor( (timestamp + host_std_offset) / 86400 ) )

    -- one of January and July is in DST for both hemispheres
    local dst_offset = host_offset( days_from_civil( year, 1, 1 ) * 86400 )
    if dst_offset == host_std_offset then
        dst_offset = host_offset( days_from_civil( year, 7, 1 ) * 86400 )
    end

    local _, is_dst = host_offset( timestamp )
    time.dst = is_dst
    time.zone_dst = dst_offset / 3600

end

--- Returns the local UTC offset at the given moment, in seconds.
---
---@param timestamp number The Unix timestamp in seconds.
---@return integer offset
local function get_offset( timestamp )
    local zone = time.zone
    if zone == host_zone then
        return (host_offset( timestamp ))
    end

    return math_floor( zone * 3600 + 0.5 )
end

--- [SHARED AND MENU]
---
--- Returns the UTC offset of the local timezone at the given moment, in seconds.
---
--- Follows the host's timezone including its DST rules, or `time.zone` as a fixed offset if it was changed.
---
---@param timestamp? number The Unix timestamp in seconds, current time by default.
---@return integer offset The UTC offset in seconds, e.g. `7200` for `+02:00`.
function time.offset( timestamp )
    return get_offset( timestamp or os_time() )
end

--- Converts local wall-clock seconds (local date and time as if it were UTC) to a Unix timestamp.
---
---@param local_seconds number
---@return number timestamp
local function local_to_utc( local_seconds )
    return local_seconds - get_offset( local_seconds - get_offset( local_seconds ) )
end

---@param offset integer
---@param separator string
---@return string
local function format_offset( offset, separator )
    local sign = "+"
    if offset < 0 then
        sign, offset = "-", -offset
    end

    local minutes = math_floor( offset / 60 )
    return string_format( "%s%02d%s%02d", sign, math_floor( minutes / 60 ), separator, minutes % 60 )
end

--- Returns the current time in seconds with sub-second precision.
---
--- `os.time` only has whole seconds, so the fraction comes from the uptime clock, anchored to
--- the moment `os.time` ticks. The estimate is always kept within `[os.time(), os.time() + 1)`,
--- so it never runs ahead of the wall clock and does not go backwards.
---
---@type fun(): number
local wall_clock
do

    local clock_delta = os_time() - dreamwork_getUpTime()

    function wall_clock()
        local uptime = dreamwork_getUpTime()
        local seconds = os_time()

        local estimate = uptime + clock_delta
        if estimate < seconds or estimate >= seconds + 1 then
            clock_delta = seconds - uptime
            return seconds
        end

        return estimate
    end

end

engine_hookCatch( "Tick", "dreamwork.std.time", function()
    -- frequent sampling keeps the sub-second anchor precise
    wall_clock()

    if time.zone == host_zone then
        local _, is_dst = host_offset( os_time() )
        time.dst = is_dst
    end
end )

--- [SHARED AND MENU]
---
--- Returns the time elapsed since lua/game was started.
---
---@param unit? dreamwork.std.time.Unit The unit to return the elapsed time in, 's' by default.
---@param as_float? boolean Whether to return the elapsed time as a float, `true` by default.
---@return number timestamp The elapsed time in the specified unit.
function time.elapsed( unit, as_float )
    if unit == "s" or unit == nil then
        local float = dreamwork_getUpTime()
        if as_float ~= false then
            return float
        end

        return math_floor( snap( float ) )
    elseif unit == "ms" then
        local float = dreamwork_getUpTime() * 1e3
        if as_float ~= false then
            return float
        end

        return math_floor( snap( float ) )
    elseif unit == "us" then
        local float = dreamwork_getUpTime() * 1e6
        if as_float ~= false then
            return float
        end

        return math_floor( snap( float ) )
    elseif unit == "ns" then
        local float = dreamwork_getUpTime() * 1e9
        if as_float ~= false then
            return float
        end

        return math_floor( snap( float ) )
    end

    return transform( dreamwork_getUpTime(), "s", unit, as_float ~= false, 2 )
end

do

    ---@type number
    local previous_time = dreamwork_getUpTime()

    --- [SHARED AND MENU]
    ---
    --- Returns the time elapsed since the last call to this function (or since the library was loaded).
    ---
    ---@param unit? dreamwork.std.time.Unit The unit to return the elapsed time in, 's' by default.
    ---@param as_float? boolean Whether to return the elapsed time as a float, `true` by default.
    ---@return number delta The elapsed time in the specified unit.
    function time.tick( unit, as_float )
        local elapsed = dreamwork_getUpTime()

        local delta = transform( elapsed - previous_time, nil, unit, as_float ~= false, 2 )
        previous_time = elapsed

        return delta
    end

end

--- [SHARED AND MENU]
---
--- Returns the current Unix timestamp (UTC) in the specified unit.
---
---@param unit? dreamwork.std.time.Unit The unit to return the current time in, `s` by default.
---@param as_float? boolean Whether to return the timestamp as a float, `false` by default.
---@return integer | number timestamp The current timestamp in the specified unit.
local function now( unit, as_float )
    if unit == nil or unit == "s" then
        if as_float then
            return wall_clock()
        end

        return os_time()
    end

    return transform( wall_clock(), "s", unit, as_float, 2 )
end

time.now = now

--- Returns the current local date.
---
---@return integer year
---@return integer month
---@return integer day
local function today()
    local timestamp = os_time()
    return civil_from_days( math_floor( (timestamp + get_offset( timestamp )) / 86400 ) )
end

--- [SHARED AND MENU]
---
--- Converts a civil (Gregorian) calendar date into a day count relative to the Unix epoch
--- (`1970-01-01`), i.e. the same scale as `days` in `time.civilFromDays` and
--- `time.weekdayFromDays` — negative for dates before the epoch, `0` for the epoch date
--- itself, positive after.
---
--- Based on Howard Hinnant's "days_from_civil" algorithm, which is valid for any year
--- representable by the host's integer type, correctly accounting for the Gregorian leap
--- year rule (including the century/400-year exceptions) without needing a lookup table.
---
--- See [howardhinnant date algorithms](http://howardhinnant.github.io/date_algorithms.html#days_from_civil) and  [socantre lua port](https://gist.github.com/socantre/c9dfcc5bd106a601d395).
---
---@param year? integer The calendar year. Defaults to the current local year.
---@param month? integer The calendar month (`1`-`12`). Defaults to the current local month.
---@param day? integer The calendar day of the month. Defaults to the current local day.
---@return integer days The number of days since the Unix epoch (`1970-01-01`).
function time.daysFromCivil( year, month, day )
    if year == nil or month == nil or day == nil then
        local current_year, current_month, current_day = today()

        if year == nil then
            year = current_year
        end

        if month == nil then
            month = current_month
        end

        if day == nil then
            day = current_day
        end
    end

    return days_from_civil( year, month, day )
end

--- [SHARED AND MENU]
---
--- Converts a day count relative to the Unix epoch (`1970-01-01`), as produced by
--- `time.daysFromCivil`, back into a civil (Gregorian) calendar year, month, and day. The
--- inverse of `time.daysFromCivil`.
---
--- Based on Howard Hinnant's "civil_from_days" algorithm, the counterpart to
--- `daysFromCivil`'s "days_from_civil".
---
---@param days? integer The number of days since the Unix epoch. If omitted, the current local date is returned.
---@return integer year The calendar year.
---@return integer month The calendar month (`1`-`12`).
---@return integer day The calendar day of the month.
function time.civilFromDays( days )
    if days == nil then
        return today()
    end

    return civil_from_days( days )
end

--- [SHARED AND MENU]
---
--- Checks if a year is a leap year, following the Gregorian rule: divisible by `4`, except
--- century years (divisible by `100`), unless also divisible by `400`.
---
---@param year? integer The year to check, the current local year by default.
---@return boolean is_leap_year Returns `true` if the year is a leap year, otherwise `false`.
local function isLeapYear( year )
    if year == nil then
        year = today()
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
        local current_year, current_month = today()

        if month == nil then
            month = current_month
        end

        if year == nil then
            year = current_year
        end
    end

    month = (month - 1) % 12 + 1

    if month == 2 and isLeapYear( year ) then
        return 29
    end

    return common_year_month_days[ month ]
end

time.daysInMonth = daysInMonth

--- [SHARED AND MENU]
---
--- Returns the number of days in a given year, accounting for leap years.
---
---@param year? integer The year to get the number of days in, the current year by default.
---@return integer days_in_year The number of days in the year, `365` or `366`.
function time.daysInYear( year )
    return isLeapYear( year ) and 366 or 365
end

--- [SHARED AND MENU]
---
--- Returns the ordinal day of the year for a given civil (Gregorian) date, where
--- `January 1st` is `1`.
---
---@param year? integer The calendar year, the current year by default.
---@param month? integer The calendar month (`1`-`12`), the current month by default.
---@param day? integer The calendar day of the month, the current day by default.
---@return integer day_of_year The day of the year (`1`-`366`).
function time.dayOfYear( year, month, day )
    if year == nil or month == nil or day == nil then
        local current_year, current_month, current_day = today()

        if year == nil then
            year = current_year
        end

        if month == nil then
            month = current_month
        end

        if day == nil then
            day = current_day
        end
    end

    return days_from_civil( year, month, day ) - days_from_civil( year, 1, 1 ) + 1
end

--- [SHARED AND MENU]
---
--- Returns the day of the week for a given day count relative to the Unix epoch, as produced
--- by `time.daysFromCivil`.
---
--- The result is a `0`-based weekday index in `[0, 6]`, matching the convention used by
--- `time.nextWeekday`/`time.prevWeekday`/`time.weekdayDifference`; `1970-01-01` (`days == 0`)
--- was a Thursday, which is why the calculation offsets by `4` before taking the modulo.
---
---@param days integer The number of days since the Unix epoch.
---@return integer weekday The `0`-based weekday index (`0` = Sunday, `6` = Saturday) for that day.
function time.weekdayFromDays( days )
    return (days + 4) % 7
end

--- [SHARED AND MENU]
---
--- Returns the day of the week for a given civil (Gregorian) date.
---
--- Shortcut for `time.weekdayFromDays( time.daysFromCivil( year, month, day ) )`.
---
---@param year? integer The calendar year, the current year by default.
---@param month? integer The calendar month (`1`-`12`), the current month by default.
---@param day? integer The calendar day of the month, the current day by default.
---@return integer weekday The `0`-based weekday index (`0` = Sunday, `6` = Saturday) for that date.
function time.weekdayFromCivil( year, month, day )
    return (time.daysFromCivil( year, month, day ) + 4) % 7
end

--- [SHARED AND MENU]
---
--- Returns the number of days to add to weekday `y` to reach weekday `x`, both given as
--- `0`-based weekday indices in `[0, 6]` (the same convention as `time.weekdayFromDays`).
---
--- The result is always in `[0, 6]`: `0` if `x` and `y` are the same weekday, otherwise the
--- forward (wrapping) distance from `y` to `x`.
---
---@param x integer The target weekday index (`0`-`6`).
---@param y integer The starting weekday index (`0`-`6`).
---@return integer difference The number of days forward from `y` to reach `x`, in `[0, 6]`.
function time.weekdayDifference( x, y )
    return (x - y) % 7
end

--- [SHARED AND MENU]
---
--- Returns the next weekday after the given one, wrapping from `6` (Saturday) back to `0`
--- (Sunday).
---
---@param weekday integer The current weekday index (`0`-`6`).
---@return integer next_weekday The following weekday index (`0`-`6`).
function time.nextWeekday( weekday )
    return (weekday + 1) % 7
end

--- [SHARED AND MENU]
---
--- Returns the weekday before the given one, wrapping from `0` (Sunday) back to `6`
--- (Saturday).
---
---@param weekday integer The current weekday index (`0`-`6`).
---@return integer previous_weekday The preceding weekday index (`0`-`6`).
function time.prevWeekday( weekday )
    return (weekday - 1) % 7
end

--- [SHARED AND MENU]
---
--- Returns the `index`-th occurrence of a given weekday in a given month of a given year,
--- e.g. "the second Sunday of March 2026".
---
--- Based on Howard Hinnant's `year_month_weekday`: takes the first day of the month,
--- steps forward by the distance from that day's weekday to `weekday`, then adds whole weeks.
---
--- `month` is wrapped into the valid `[1, 12]` range via modulo before use, the same way
--- `time.daysInMonth` does.
---
--- Negative `index` values count from the end of the month instead: `-1` is the last
--- occurrence (same as `time.lastMonthWeekday`), `-2` the second-to-last, and so on.
---
--- If the month has no such occurrence (e.g. a 5th Monday in a month that only has four),
--- or `index` is `0`, `nil` is returned.
---
--- See [howardhinnant date](https://howardhinnant.github.io/date/date.html#year_month_weekday).
---
---@param weekday integer The `0`-based weekday index (`0` = Sunday, `6` = Saturday) to look for.
---@param index integer The `1`-based occurrence of `weekday` within the month (`1`-`5`), or a negative index counting from the end of the month (`-1`-`-5`).
---@param month? integer The month to search in (`1`–`12`), the current month by default.
---@param year? integer The year to search in, the current year by default.
---@return integer | nil day The day of the month (`1`-`31`) of the `index`-th occurrence of `weekday`, or `nil` if the month has no such occurrence.
---@return integer | nil days The same date as a day count relative to the Unix epoch, as produced by `time.daysFromCivil`, or `nil` if the month has no such occurrence.
function time.monthWeekday( weekday, index, month, year )
    if month == nil or year == nil then
        local current_year, current_month = today()

        if month == nil then
            month = current_month
        end

        if year == nil then
            year = current_year
        end
    end

    if index == 0 then
        return nil, nil
    end

    month = (month - 1) % 12 + 1

    if index < 0 then
        local last_day = daysInMonth( month, year )
        local days = days_from_civil( year, month, last_day )
        local offset = ((days + 4) % 7 - weekday) % 7 + (-index - 1) * 7

        local day = last_day - offset
        if day < 1 then
            return nil, nil
        end

        return day, days - offset
    end

    local days = days_from_civil( year, month, 1 )
    local offset = (weekday - (days + 4) % 7) % 7 + (index - 1) * 7

    local day = 1 + offset
    if day > daysInMonth( month, year ) then
        return nil, nil
    end

    return day, days + offset
end

--- [SHARED AND MENU]
---
--- Returns the last occurrence of a given weekday in a given month of a given year,
--- e.g. "the last Sunday of March 2026".
---
--- Based on Howard Hinnant's `year_month_weekday_last`: takes the last day of the month,
--- then steps back by the forward distance from `weekday` to that day's weekday.
---
--- `month` is wrapped into the valid `[1, 12]` range via modulo before use, the same way
--- `time.daysInMonth` does.
---
--- See [howardhinnant date](https://howardhinnant.github.io/date/date.html#year_month_weekday_last).
---
---@param weekday integer The `0`-based weekday index (`0` = Sunday, `6` = Saturday) to look for.
---@param month? integer The month to search in (`1`–`12`), the current month by default.
---@param year? integer The year to search in, the current year by default.
---@return integer day The day of the month (`22`-`31`) of the last occurrence of `weekday`.
---@return integer days The same date as a day count relative to the Unix epoch, as produced by `time.daysFromCivil`.
function time.lastMonthWeekday( weekday, month, year )
    if month == nil or year == nil then
        local current_year, current_month = today()

        if month == nil then
            month = current_month
        end

        if year == nil then
            year = current_year
        end
    end

    month = (month - 1) % 12 + 1

    local last_day = daysInMonth( month, year )
    local days = days_from_civil( year, month, last_day )
    local offset = ((days + 4) % 7 - weekday) % 7

    return last_day - offset, days - offset
end

--- [SHARED AND MENU]
---
--- Returns the ISO 8601 week-numbering year and week number for a given civil (Gregorian) date.
---
--- ISO weeks start on Monday, and week `1` is the week containing the year's first Thursday
--- (equivalently, the week containing `January 4th`). Because of that, the first few days of
--- January may belong to the last week of the previous ISO year, and the last few days of
--- December may belong to week `1` of the next one — which is why the ISO year is returned
--- alongside the week.
---
--- See [ISO week date](https://en.wikipedia.org/wiki/ISO_week_date).
---
---@param year? integer The calendar year, the current year by default.
---@param month? integer The calendar month (`1`-`12`), the current month by default.
---@param day? integer The calendar day of the month, the current day by default.
---@return integer iso_year The ISO week-numbering year, which may differ from `year` by one near year boundaries.
---@return integer week The ISO week number (`1`-`53`).
---@return integer iso_weekday The ISO weekday (`1` = Monday, `7` = Sunday).
function time.isoWeek( year, month, day )
    local days = time.daysFromCivil( year, month, day )

    -- 0 = Monday, 6 = Sunday
    local weekday = (days + 3) % 7

    -- the ISO year of a week is the year its Thursday falls in
    local thursday = days - weekday + 3
    local iso_year = civil_from_days( thursday )

    return iso_year, math_floor( (thursday - days_from_civil( iso_year, 1, 1 )) / 7 ) + 1, weekday + 1
end

--- [SHARED AND MENU]
---
--- Returns the number of ISO 8601 weeks in a given ISO week-numbering year.
---
--- A year has `53` ISO weeks if it starts on a Thursday, or if it is a leap year that starts
--- on a Wednesday; otherwise it has `52`.
---
---@param year? integer The ISO week-numbering year, the current year by default.
---@return integer weeks The number of ISO weeks in the year, `52` or `53`.
function time.isoWeeksInYear( year )
    if year == nil then
        year = today()
    end

    local weekday = (days_from_civil( year, 1, 1 ) + 4) % 7
    if weekday == 4 or (weekday == 3 and isLeapYear( year )) then
        return 53
    end

    return 52
end

--- [SHARED AND MENU]
---
--- Converts a civil (Gregorian) date and time of day into a Unix timestamp in seconds.
---
--- Unlike `os.time`, this is pure arithmetic: the result is not affected by the host's local
--- timezone or DST settings, and works for any year, including those before `1970`.
--- The date and time are treated as UTC; subtract `time.offset()` to convert from local time.
---
---@param year? integer The calendar year, the current year by default.
---@param month? integer The calendar month (`1`-`12`), the current month by default.
---@param day? integer The calendar day of the month, the current day by default.
---@param hour? integer The hour (`0`-`23`), `0` by default.
---@param minute? integer The minute (`0`-`59`), `0` by default.
---@param second? number The second (`0`-`59`), `0` by default; may be fractional.
---@return number timestamp The Unix timestamp in seconds.
function time.timestampFromCivil( year, month, day, hour, minute, second )
    return time.daysFromCivil( year, month, day ) * 86400 + (hour or 0) * 3600 + (minute or 0) * 60 + (second or 0)
end

--- [SHARED AND MENU]
---
--- Converts a Unix timestamp in seconds into a civil (Gregorian) date and time of day.
--- The inverse of `time.timestampFromCivil`.
---
--- Like `time.timestampFromCivil`, this is pure arithmetic and is not affected by the host's
--- local timezone; the result is in UTC, add `time.offset( timestamp )` to get local time.
---
---@param timestamp? number The Unix timestamp in seconds, current time by default.
---@return integer year The calendar year.
---@return integer month The calendar month (`1`-`12`).
---@return integer day The calendar day of the month.
---@return integer hour The hour (`0`-`23`).
---@return integer minute The minute (`0`-`59`).
---@return number second The second (`0`-`59`), fractional if `timestamp` was.
---@return integer weekday The `0`-based weekday index (`0` = Sunday, `6` = Saturday).
function time.civilFromTimestamp( timestamp )
    if timestamp == nil then
        timestamp = wall_clock()
    end

    local days = math_floor( timestamp / 86400 )
    local seconds = timestamp - (days * 86400)

    local year, month, day = civil_from_days( days )
    local hour = math_floor( seconds / 3600 )
    seconds = seconds - (hour * 3600)

    local minute = math_floor( seconds / 60 )

    return year, month, day, hour, minute, seconds - (minute * 60), (days + 4) % 7
end

--- [SHARED AND MENU]
---
--- Converts a duration string to the specified unit.
---
--- The duration string can have the following units: `ns`, `us`, `ms`, `s`, `m`, `h`, `d`, `w`, `y`.
--- Numbers without a unit are seconds.
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

        if unit_str == "s" or unit_str == "" then
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

        return math_floor( snap( float ) )
    elseif unit == "us" then
        local float = (seconds * 1e6) + (milliseconds * 1e3) + microseconds + (nanoseconds / 1e3)

        if as_float then
            return float
        end

        return math_floor( snap( float ) )
    elseif unit == "ns" then
        local float = (seconds * 1e9) + (milliseconds * 1e6) + (microseconds * 1e3) + nanoseconds

        if as_float then
            return float
        end

        return math_floor( snap( float ) )
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
    --- Negative durations have every segment negated (`-1m -30s`), so they parse back with `time.fromDuration`.
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
        local sign = ""

        if timestamp < 0 then
            sign, timestamp = "-", -timestamp
        end

        local seconds, nanoseconds = split( timestamp, unit, 2 )

        local segments, segment_count = {}, 0

        local milliseconds = math_floor( nanoseconds / 1e6 )
        nanoseconds = nanoseconds - (milliseconds * 1e6)

        local microseconds = math_floor( nanoseconds / 1e3 )
        nanoseconds = nanoseconds - (microseconds * 1e3)

        for i = 1, 6, 1 do
            if seconds <= 0 then
                break
            end

            local lst = duration_units[ i ]

            local value = lst[ 1 ]
            if seconds >= value then
                local count = math_floor( seconds / value )
                seconds = seconds - (count * value)

                segment_count = segment_count + 1
                segments[ segment_count ] = string_format( "%s%d%s", sign, count, lst[ 2 ] )
            end
        end

        if seconds > 0 then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_format( "%s%ds", sign, seconds )
        end

        if milliseconds ~= 0 then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_format( "%s%03dms", sign, milliseconds )
        end

        if microseconds ~= 0 then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_format( "%s%03dus", sign, microseconds )
        end

        if nanoseconds ~= 0 then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_format( "%s%03dns", sign, nanoseconds )
        end

        if segment_count == 0 then
            return "0s"
        end

        return table_concat( segments, " ", 1, segment_count )
    end

end

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
---@field year_week integer The week number of the year, with Monday as the first day of the week; days before the first Monday are in week `0`. [0-53]
---@field month_week integer The week number of the month. [1-5]
---@field weekday integer The day of the week, `0` is Sunday. [0-6]
---
---@field hours integer The number of hours. [0-23]
---@field minutes integer The number of minutes. [0-59]
---@field seconds integer The number of seconds. [0-59]
---
---@field hours12 integer The number of hours in 12-hour format. [1-12]
---@field period "AM" | "PM" The period of the day.
---
---@field is_dst boolean Is the date in summer time (daylight saving)?
---@field offset integer The UTC offset of the date in seconds, `0` for UTC.
---
---@field milliseconds integer The number of milliseconds. [0-999]
---@field microseconds integer The number of microseconds. [0-999]
---@field nanoseconds integer The number of nanoseconds. [0-999]

--- [SHARED AND MENU]
---
--- Returns a table with the date and time components.
---
---@param timestamp? number The timestamp to parse, current time by default.
---@param unit? dreamwork.std.time.Unit The unit to parse the timestamp from, 's' by default.
---@param in_utc? boolean Whether to return the date in UTC instead of local time, `false` by default.
---@return dreamwork.std.time.DateInfo date_info The date and time components.
function time.parse( timestamp, unit, in_utc )
    local seconds, nanoseconds = split( timestamp or now( unit, true ), unit, 2 )

    local milliseconds = math_floor( nanoseconds / 1e6 )
    nanoseconds = nanoseconds - (milliseconds * 1e6)

    local microseconds = math_floor( nanoseconds / 1e3 )
    nanoseconds = nanoseconds - (microseconds * 1e3)

    local offset, is_dst = 0, false
    if in_utc ~= true then
        if time.zone == host_zone then
            offset, is_dst = host_offset( seconds )
        else
            offset = get_offset( seconds )
        end
    end

    local local_seconds = seconds + offset

    local days = math_floor( local_seconds / 86400 )
    local day_seconds = local_seconds - (days * 86400)

    local year, month, day = civil_from_days( days )
    local year_day = days - days_from_civil( year, 1, 1 ) + 1
    local weekday = (days + 4) % 7

    local hours = math_floor( day_seconds / 3600 )
    day_seconds = day_seconds - (hours * 3600)

    local minutes = math_floor( day_seconds / 60 )

    local hours12 = hours % 12
    if hours12 == 0 then
        hours12 = 12
    end

    -- conditionals inside the constructor abort the JIT trace ( "register coalescing too complex" )
    local period = "AM"
    if hours >= 12 then
        period = "PM"
    end

    return {
        day = day,
        year = year,
        month = month,

        year_day = year_day,
        year_week = math_floor( (year_day + 6 - (weekday + 6) % 7) / 7 ),
        month_week = math_ceil( day / 7 ),
        weekday = weekday,

        hours12 = hours12,
        period = period,

        is_dst = is_dst,
        offset = offset,

        hours = hours,
        minutes = minutes,
        seconds = day_seconds - (minutes * 60),

        milliseconds = milliseconds,
        microseconds = microseconds,
        nanoseconds = nanoseconds
    }
end

do

    --- Calendar shift by whole months in local time, keeping the wall-clock time and clamping
    --- the day to the target month (`Jan 31 + 1mo` is `Feb 28/29`).
    ---
    ---@param seconds integer
    ---@param months integer
    ---@return integer seconds
    local function add_months( seconds, months )
        local local_seconds = seconds + get_offset( seconds )

        local days = math_floor( local_seconds / 86400 )
        local day_seconds = local_seconds - (days * 86400)

        local year, month, day = civil_from_days( days )

        month = month - 1 + months
        year = year + math_floor( month / 12 )
        month = month % 12 + 1

        local month_days = daysInMonth( month, year )
        if day > month_days then
            day = month_days
        end

        return local_to_utc( days_from_civil( year, month, day ) * 86400 + day_seconds )
    end

    ---@param timestamp number | nil
    ---@param unit dreamwork.std.time.Unit | nil
    ---@param duration_str dreamwork.std.time.DurationString
    ---@param as_float boolean | nil
    ---@param sign integer
    ---@return number new_timestamp
    local function shift( timestamp, unit, duration_str, as_float, sign )
        if timestamp == nil then
            timestamp = now( unit, as_float )
        end

        local months, delta = 0, 0

        for number_str, unit_str in string_gmatch( duration_str, "(%-?%d*%.?%d+)(%l*)" ) do
            local value = raw_tonumber( number_str ) or 0

            if unit_str == "y" or unit_str == "mo" then
                local whole, fraction = math_modf( value )
                months = months + whole * (unit_str == "y" and 12 or 1)

                if fraction ~= 0 then
                    delta = delta + transform( fraction, unit_str, unit, true, 3 )
                end
            else
                delta = delta + transform( value, unit_str == "" and "s" or unit_str, unit, true, 3 )
            end
        end

        if months ~= 0 then
            local seconds = split( timestamp, unit, 3 )
            timestamp = timestamp + transform( add_months( seconds, sign * months ) - seconds, "s", unit, true, 3 )
        end

        timestamp = timestamp + (sign * delta)

        if as_float then
            return timestamp
        end

        return math_trunc( timestamp )
    end

    --- [SHARED AND MENU]
    ---
    --- Adds a duration to a timestamp.
    ---
    --- The duration string can have the following units:
    --- `ns`, `us`, `ms`, `s`, `m`, `h`, `d`, `w`, `y`.
    ---
    --- `mo` and `y` are calendar months and years in local time: the wall-clock time is kept
    --- and the day is clamped to the target month (`Jan 31 + 1mo` is `Feb 28/29`).
    --- All other units are exact amounts of time.
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
    --- | `mo`     | Month        | 1 calendar month            |
    --- | `y`      | Year         | 1 calendar year             |
    ---
    ---@param timestamp? number The timestamp to add the duration to, current time by default.
    ---@param unit? dreamwork.std.time.Unit The unit of the timestamp, 's' by default.
    ---@param duration_str dreamwork.std.time.DurationString The duration string to add.
    ---@param as_float? boolean Whether to return the timestamp as a float, `false` by default.
    ---@return number new_timestamp
    function time.add( timestamp, unit, duration_str, as_float )
        return shift( timestamp, unit, duration_str, as_float, 1 )
    end

    --- [SHARED AND MENU]
    ---
    --- Subtracts a duration from a timestamp.
    ---
    --- The duration string can have the following units: `ns`, `us`, `ms`, `s`, `m`, `h`, `d`, `w`, `y`.
    ---
    --- `mo` and `y` are calendar months and years in local time: the wall-clock time is kept
    --- and the day is clamped to the target month (`Mar 31 - 1mo` is `Feb 28/29`).
    --- All other units are exact amounts of time.
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
    --- | `mo`     | Month        | 1 calendar month            |
    --- | `y`      | Year         | 1 calendar year             |
    ---
    ---@param timestamp? number The timestamp to subtract the duration from, current time by default.
    ---@param unit? dreamwork.std.time.Unit The unit of the timestamp, 's' by default.
    ---@param duration_str dreamwork.std.time.DurationString The duration string to subtract.
    ---@param as_float? boolean Whether to return the timestamp as a float, `false` by default.
    ---@return number new_timestamp
    function time.sub( timestamp, unit, duration_str, as_float )
        return shift( timestamp, unit, duration_str, as_float, -1 )
    end

end

do

    ---@type table<string, string>
    local number_formats = {
        -- Day of the month [01-31]	16
        day = "%02d",
        -- Month [01-12]	09
        month = "%02d",
        -- Full year	1998
        year = "%d",
        -- Week of the year [00-53]	37
        year_week = "%02d",
        -- Day of the year [001-366]	259
        year_day = "%03d",
        -- Hour, using a 24-hour clock [00-23]	23
        hours = "%02d",
        -- Minute [00-59]	48
        minutes = "%02d",
        -- Second [00-59]	10
        seconds = "%02d",
        -- Hour, using a 12-hour clock [01-12]	11
        hours12 = "%02d",
        -- Weekday [0-6 = Sunday-Saturday]	3
        weekday = "%d"
    }

    -- locale-dependent values are left to `os.date`
    ---@type table<string, string>
    local os_date_formats = {
        -- %B	Full month name	September
        month_name = "!%B",
        -- %b	Abbreviated month name	Sep
        month_short_name = "!%b",
        -- %A	Full weekday name	Wednesday
        weekday_name = "!%A",
        -- %a	Abbreviated weekday name	Wed
        weekday_short_name = "!%a",
        -- %X	Time (Same as %H:%M:%S)	23:48:10
        time = "!%X",
        -- %x	Date (Same as %m/%d/%y)	09/16/98
        date = "!%x",
        -- %c	Locale-appropriate date and time	Varies by platform and language settings
        datetime = "!%c"
    }

    ---@class dreamwork.std.time.FormatBuffer : metatable
    ---@field [ 0 ] boolean in_utc
    ---@field [ 1 ] integer seconds
    ---@field [ 2 ] integer nanoseconds sub-second remainder
    ---@field [ 5 ] dreamwork.std.time.DateInfo | nil
    local FormatBuffer = {}

    ---@type table<string, integer>
    local key_to_divisor = {
        milliseconds = 1e6,
        microseconds = 1e3,
        nanoseconds = 1
    }

    ---@param key string
    ---@protected
    function FormatBuffer:__index( key )
        local value

        local divisor = key_to_divisor[ key ]
        if divisor ~= nil then
            value = string_format( "%03d", math_floor( raw_get( self, 2 ) / divisor ) % 1000 )
        else
            local date_info = raw_get( self, 5 )
            if date_info == nil then
                date_info = time.parse( raw_get( self, 1 ), "s", raw_get( self, 0 ) )
                self[ 5 ] = date_info
            end

            local number_format = number_formats[ key ]
            if number_format ~= nil then
                value = string_format( number_format, date_info[ key ] )
            elseif key == "year_short" then
                value = string_format( "%02d", date_info.year % 100 )
            elseif key == "period" then
                value = date_info.period
            elseif key == "timezone" then
                value = format_offset( date_info.offset, "" )
            else
                local os_date_format = os_date_formats[ key ]
                if os_date_format == nil then
                    error( string_format( "unknown value name - '%s'", key ), 4 )
                end

                value = os_date( os_date_format, raw_get( self, 1 ) + date_info.offset )
            end
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
    --- | `{year_day}`            | Day of the year [001–366]                              | `259`                      |
    --- | `{year_week}`           | Week number of the year, Monday first [00–53]          | `37`                       |
    --- | `{year_short}`          | Two-digit year [00–99]                                 | `98`                       |
    --- | `{hours}`               | Hour in 24-hour format [00–23]                         | `23`                       |
    --- | `{minutes}`             | Minute [00–59]                                         | `48`                       |
    --- | `{seconds}`             | Second [00–59]                                         | `10`                       |
    --- | `{milliseconds}`        | Millisecond [000–999]                                  | `010`                      |
    --- | `{microseconds}`        | Microsecond [000–999]                                  | `010`                      |
    --- | `{nanoseconds}`         | Nanosecond [000–999]                                   | `010`                      |
    --- | `{hours12}`             | Hour in 12-hour format [01–12]                         | `11`                       |
    --- | `{period}`              | AM or PM                                               | `PM`                       |
    --- | `{date}`                | Localized date (same as `{month}/{day}/{year}`)  | `09/16/98`                 |
    --- | `{time}`                | Localized time (same as `{hours}:{minutes}:{seconds}`) | `23:48:10`                 |
    --- | `{datetime}`           | Localized full date and time                           | `Wed Sep 16 23:48:10 1998` |
    --- | `{timezone}`            | Timezone offset, `+0000` in UTC                        | `-0300`                    |
    ---
    ---@param fmt string The format string.
    ---@param timestamp? integer The timestamp to format.
    ---@param unit? dreamwork.std.time.Unit The timestamp unit, 's' by default.
    ---@param in_utc? boolean Use UTC instead of local timezone, `false` by default.
    ---@return string str The formatted string.
    function time.format( fmt, timestamp, unit, in_utc )
        return string_interpolate( fmt, setmetatable( { [ 0 ] = in_utc == true, split( timestamp or now( unit, true ), unit, 2 ) }, FormatBuffer ) )
    end

end

do

    ---@type table<integer, string>
    local weekday_names = { [ 0 ] = "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }

    ---@type table<integer, string>
    local month_names = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

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
        ---@type integer
        local seconds

        if timestamp == nil then
            seconds = os_time()
        else
            seconds = split( timestamp, unit, 2 )
        end

        local offset = 0
        if not in_utc then
            offset = get_offset( seconds )
        end

        local local_seconds = seconds + offset

        local days = math_floor( local_seconds / 86400 )
        local day_seconds = local_seconds - (days * 86400)

        local year, month, day = civil_from_days( days )

        local hours = math_floor( day_seconds / 3600 )
        day_seconds = day_seconds - (hours * 3600)

        local minutes = math_floor( day_seconds / 60 )

        return string_format( "%s, %02d %s %04d %02d:%02d:%02d %s",
            weekday_names[ (days + 4) % 7 ], day, month_names[ month ], year,
            hours, minutes, day_seconds - (minutes * 60),
            format_offset( offset, "" )
        )
    end

end

do

    ---@param year integer
    ---@param month integer
    ---@param day integer
    ---@param hours integer
    ---@param minutes integer
    ---@param seconds integer
    ---@param milliseconds integer | nil
    ---@param offset integer | nil
    ---@return string
    local function write_iso( year, month, day, hours, minutes, seconds, milliseconds, offset )
        if milliseconds == nil then
            if offset == nil then
                return string_format( "%04d-%02d-%02dT%02d:%02d:%02dZ", year, month, day, hours, minutes, seconds )
            end

            return string_format( "%04d-%02d-%02dT%02d:%02d:%02d%s", year, month, day, hours, minutes, seconds, format_offset( offset, ":" ) )
        end

        if offset == nil then
            return string_format( "%04d-%02d-%02dT%02d:%02d:%02d.%03dZ", year, month, day, hours, minutes, seconds, milliseconds )
        end

        return string_format( "%04d-%02d-%02dT%02d:%02d:%02d.%03d%s", year, month, day, hours, minutes, seconds, milliseconds, format_offset( offset, ":" ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Converts a timestamp to a JS-like ( ISO 8601 ) date-time string,
    --- for example `2024-01-15T10:30:00.000Z` or `2024-01-15T10:30:00.000-05:00` with timezone offset.
    ---
    --- Milliseconds are included if `unit` is `ms`, `us` or `ns`, or if `timestamp` has a fraction.
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

        local seconds, nanoseconds = split( timestamp, unit, 2 )

        ---@type integer | nil
        local milliseconds

        if unit == "ms" or unit == "us" or unit == "ns" or timestamp % 1 ~= 0 then
            milliseconds = math_floor( nanoseconds / 1e6 )
        end

        local offset, local_seconds
        if in_utc then
            local_seconds = seconds
        else
            offset = get_offset( seconds )
            local_seconds = seconds + offset
        end

        local days = math_floor( local_seconds / 86400 )
        local day_seconds = local_seconds - (days * 86400)

        local year, month, day = civil_from_days( days )

        local hours = math_floor( day_seconds / 3600 )
        day_seconds = day_seconds - (hours * 3600)

        local minutes = math_floor( day_seconds / 60 )

        return write_iso( year, month, day, hours, minutes, day_seconds - (minutes * 60), milliseconds, offset )
    end

end

do

    ---@type table<string, integer>
    local fraction_digits = { ms = 3, us = 6, ns = 9 }

    --- [SHARED AND MENU]
    ---
    --- Parses a JS-like ( ISO 8601 ) date-time string, as produced by JavaScript's
    --- `Date.prototype.toISOString()` / `JSON.stringify( new Date() )`, and converts it to a unix timestamp.
    ---
    --- Supported formats ( matching JavaScript's `Date Time String Format` ):
    --- * `2024-01-15T10:30:00.000Z` - UTC, with milliseconds
    --- * `2024-01-15T10:30:00Z` - UTC, without milliseconds
    --- * `2024-01-15T10:30:00.000+02:00` / `2024-01-15T10:30:00+0200` - explicit offset
    --- * `2024-01-15T10:30Z` - without seconds
    --- * `2024-01-15T10:30:00` - no timezone info, interpreted as local time ( DST-aware )
    --- * `2024-01-15` - date only, interpreted as UTC midnight, matching JavaScript's behaviour
    ---
    --- A space can be used instead of `T`. Fractions of any length are supported, digits beyond
    --- the precision of `unit` are truncated.
    ---
    ---@param str string The JS-like date-time string to parse.
    ---@param unit? dreamwork.std.time.Unit The unit to return the timestamp in, `s` by default.
    ---@param as_float? boolean Whether to return the timestamp as a float, `false` by default.
    ---@return number timestamp The unix timestamp in the specified unit.
    function time.fromISOString( str, unit, as_float )
        local year_str, month_str, day_str, rest = string_match( str, "^(%d%d%d%d)%-(%d%d)%-(%d%d)(.*)$" )
        if year_str == nil then
            error( string_format( "invalid date-time string - '%s'", str ), 2 )
        end

        local year = raw_tonumber( year_str, 10 ) or 1970
        local month = raw_tonumber( month_str, 10 ) or 1
        local day = raw_tonumber( day_str, 10 ) or 1

        if month < 1 or month > 12 or day < 1 or day > daysInMonth( month, year ) then
            error( string_format( "invalid date-time string - '%s'", str ), 2 )
        end

        local seconds = days_from_civil( year, month, day ) * 86400

        ---@type string | nil
        local fraction_str

        -- date-only strings are interpreted as UTC, matching JavaScript's behaviour
        if rest ~= "" then
            local hours_str, minutes_str, time_rest = string_match( rest, "^[T ](%d%d):(%d%d)(.*)$" )
            if hours_str == nil then
                error( string_format( "invalid date-time string - '%s'", str ), 2 )
            end

            local hours = raw_tonumber( hours_str, 10 )
            local minutes = raw_tonumber( minutes_str, 10 )
            local additional_seconds = 0

            local seconds_str, seconds_rest = string_match( time_rest, "^:(%d%d)(.*)$" )
            if seconds_str ~= nil then
                additional_seconds = raw_tonumber( seconds_str, 10 ) or additional_seconds
                time_rest = seconds_rest

                local digits_str, fraction_rest = string_match( time_rest, "^[%.,](%d+)(.*)$" )
                if digits_str ~= nil then
                    fraction_str, time_rest = digits_str, fraction_rest
                end
            end

            if hours > 23 or minutes > 59 or additional_seconds > 59 then
                error( string_format( "invalid date-time string - '%s'", str ), 2 )
            end

            seconds = seconds + (hours * 3600) + (minutes * 60) + additional_seconds

            if time_rest == "" then
                seconds = local_to_utc( seconds )
            elseif not (time_rest == "Z" or time_rest == "z") then
                local sign, offset_hours_str, offset_minutes_str = string_match( time_rest, "^([%+%-])(%d%d):?(%d%d)$" )
                if sign == nil then
                    error( string_format( "invalid timezone offset - '%s'", time_rest ), 2 )
                end

                local offset_hours = raw_tonumber( offset_hours_str, 10 )
                local offset_minutes = raw_tonumber( offset_minutes_str, 10 )

                if offset_hours > 23 or offset_minutes > 59 then
                    error( string_format( "invalid timezone offset - '%s'", time_rest ), 2 )
                end

                local offset = (offset_hours * 3600) + (offset_minutes * 60)

                if sign == "-" then
                    seconds = seconds + offset
                else
                    seconds = seconds - offset
                end
            end
        end

        if fraction_str == nil then
            return transform( seconds, "s", unit, as_float, 2 )
        end

        local digits = fraction_digits[ unit ]
        if digits == nil then
            return transform( seconds + raw_tonumber( "0." .. fraction_str, 10 ), "s", unit, as_float, 2 )
        end

        -- integer math, so `.123` is exactly `123ms`
        local timestamp = seconds * (10 ^ digits) + raw_tonumber( string_sub( fraction_str .. "000000000", 1, digits ), 10 )

        if as_float and #fraction_str > digits then
            timestamp = timestamp + raw_tonumber( "0." .. string_sub( fraction_str, digits + 1 ), 10 )
        end

        return timestamp
    end

end

do

    ---@type table<string, integer>
    local month_map = {
        jan = 1,
        feb = 2,
        mar = 3,
        apr = 4,
        may = 5,
        jun = 6,
        jul = 7,
        aug = 8,
        sep = 9,
        oct = 10,
        nov = 11,
        dec = 12
    }

    -- military zones are treated as `-0000` ( unknown, UTC ) per RFC 2822 section 4.3
    ---@type table<string, integer>
    local rfc2822_timezones = {
        ut = 0,
        utc = 0,
        gmt = 0,
        est = -18000,
        edt = -14400,
        cst = -21600,
        cdt = -18000,
        mst = -25200,
        mdt = -21600,
        pst = -28800,
        pdt = -25200
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
        local day_str, month_str, year_str, hours_str, minutes_str, rest = string_match(
            string_match( str, "^%s*%a+,%s*(.*)$" ) or str,
            "^%s*(%d%d?)%s+(%a+)%s+(%d%d+)%s+(%d%d):(%d%d)(.*)$"
        )

        if day_str == nil then
            error( string_format( "invalid date-time string - '%s'", str ), 2 )
        end

        local month = month_map[ string_lower( string_sub( month_str, 1, 3 ) ) ]
        if month == nil then
            error( string_format( "invalid month name - '%s'", month_str ), 2 )
        end

        local year = raw_tonumber( year_str, 10 ) or 1970

        -- obsolete 2 and 3-digit year rules
        if year < 50 and #year_str == 2 then
            year = year + 2000
        elseif year < 1000 then
            year = year + 1900
        end

        local day = raw_tonumber( day_str, 10 ) or 1

        local hours = raw_tonumber( hours_str, 10 ) or 0
        local minutes = raw_tonumber( minutes_str, 10 ) or 0
        local seconds = 0

        local seconds_str, seconds_rest = string_match( rest, "^:(%d%d)(.*)$" )
        if seconds_str ~= nil then
            seconds = raw_tonumber( seconds_str, 10 ) or seconds
            rest = seconds_rest
        end

        -- trailing comments like `(UTC)` are ignored
        local zone_str, trailing = string_match( rest, "^%s*([%w%+%-]*)%s*(.-)$" )
        if not (trailing == "" or string_match( trailing, "^%(.*%)$" ) ~= nil) then
            error( string_format( "invalid date-time string - '%s'", str ), 2 )
        end

        -- `60` is a leap second
        if day < 1 or day > daysInMonth( month, year ) or hours > 23 or minutes > 59 or seconds > 60 then
            error( string_format( "invalid date-time string - '%s'", str ), 2 )
        end

        local offset = 0

        if zone_str ~= "" then
            local sign, offset_hours, offset_minutes = string_match( zone_str, "^([%+%-])(%d%d)(%d%d)$" )
            if sign == nil then
                if string_match( zone_str, "^%a+$" ) == nil then
                    error( string_format( "invalid timezone - '%s'", zone_str ), 2 )
                end

                -- unrecognised names ( including the obsolete military zones ) are treated as UTC
                offset = rfc2822_timezones[ string_lower( zone_str ) ] or 0
            else
                offset = (raw_tonumber( offset_hours, 10 ) * 3600) + (raw_tonumber( offset_minutes, 10 ) * 60)

                if sign == "-" then
                    offset = -offset
                end
            end
        end

        return transform(
            days_from_civil( year, month, day ) * 86400 + (hours * 3600) + (minutes * 60) + seconds - offset,
            "s", unit, as_float, 2
        )
    end

end
