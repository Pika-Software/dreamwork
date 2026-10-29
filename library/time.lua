---@meta _

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
---@class time
---@field zone number The standard (non-DST) UTC offset of the local timezone in hours, may be fractional (e.g. `5.5`). Assign a different value to use a fixed UTC offset instead of the host's timezone.
---@field dst boolean Whether the host's timezone is currently in daylight saving time.
---@field zone_dst number The UTC offset of the host's timezone during daylight saving time in hours, equal to `zone` if the host has no DST.
time = {}

--- [SHARED AND MENU]
---
--- Transforms a timestamp to a different unit.
---
--- A double holds ~16 significant digits, so a Unix timestamp in `ns` (`~1.7e18`) is only
--- precise to `~256ns`, and the same moment in float seconds to `~240ns`.
---
---@param timestamp number The timestamp to transform.
---@param unit? time.Unit The unit to transform the timestamp from, 's' by default.
---@param target? time.Unit The unit to transform the timestamp to, 's' by default.
---@param as_float? boolean Whether to return the timestamp as a float, `false` by default.
---@return number timestamp The transformed timestamp.
---@nodiscard
function time.transform(timestamp, unit, target, as_float) end

---@type number
time.zone = nil

--- [SHARED AND MENU]
---
--- Returns the UTC offset of the local timezone at the given moment, in seconds.
---
--- Follows the host's timezone including its DST rules, or `time.zone` as a fixed offset if it was changed.
---
---@param timestamp? number The Unix timestamp in seconds, current time by default.
---@return integer offset The UTC offset in seconds, e.g. `7200` for `+02:00`.
---@nodiscard
function time.offset(timestamp) end

--- [SHARED AND MENU]
---
--- Returns the time elapsed since lua/game was started.
---
---@param unit? time.Unit The unit to return the elapsed time in, 's' by default.
---@param as_float? boolean Whether to return the elapsed time as a float, `true` by default.
---@return number timestamp The elapsed time in the specified unit.
---@nodiscard
function time.elapsed(unit, as_float) end

--- [SHARED AND MENU]
---
--- Returns the time elapsed since the last call to this function (or since the library was loaded).
---
---@param unit? time.Unit The unit to return the elapsed time in, 's' by default.
---@param as_float? boolean Whether to return the elapsed time as a float, `true` by default.
---@return number delta The elapsed time in the specified unit.
function time.tick(unit, as_float) end

--- [SHARED AND MENU]
---
--- Returns the current Unix timestamp (UTC) in the specified unit.
---
---@param unit? time.Unit The unit to return the current time in, `s` by default.
---@param as_float? boolean Whether to return the timestamp as a float, `false` by default.
---@return integer | number timestamp The current timestamp in the specified unit.
---@nodiscard
function time.now(unit, as_float) end

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
---@nodiscard
function time.daysFromCivil(year, month, day) end

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
---@nodiscard
function time.civilFromDays(days) end

--- [SHARED AND MENU]
---
--- Checks if a year is a leap year, following the Gregorian rule: divisible by `4`, except
--- century years (divisible by `100`), unless also divisible by `400`.
---
---@param year? integer The year to check, the current local year by default.
---@return boolean is_leap_year Returns `true` if the year is a leap year, otherwise `false`.
---@nodiscard
function time.isLeapYear(year) end

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
---@nodiscard
function time.daysInMonth(month, year) end

--- [SHARED AND MENU]
---
--- Returns the number of days in a given year, accounting for leap years.
---
---@param year? integer The year to get the number of days in, the current year by default.
---@return integer days_in_year The number of days in the year, `365` or `366`.
---@nodiscard
function time.daysInYear(year) end

--- [SHARED AND MENU]
---
--- Returns the ordinal day of the year for a given civil (Gregorian) date, where
--- `January 1st` is `1`.
---
---@param year? integer The calendar year, the current year by default.
---@param month? integer The calendar month (`1`-`12`), the current month by default.
---@param day? integer The calendar day of the month, the current day by default.
---@return integer day_of_year The day of the year (`1`-`366`).
---@nodiscard
function time.dayOfYear(year, month, day) end

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
---@nodiscard
function time.weekdayFromDays(days) end

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
---@nodiscard
function time.weekdayFromCivil(year, month, day) end

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
---@nodiscard
function time.weekdayDifference(x, y) end

--- [SHARED AND MENU]
---
--- Returns the next weekday after the given one, wrapping from `6` (Saturday) back to `0`
--- (Sunday).
---
---@param weekday integer The current weekday index (`0`-`6`).
---@return integer next_weekday The following weekday index (`0`-`6`).
---@nodiscard
function time.nextWeekday(weekday) end

--- [SHARED AND MENU]
---
--- Returns the weekday before the given one, wrapping from `0` (Sunday) back to `6`
--- (Saturday).
---
---@param weekday integer The current weekday index (`0`-`6`).
---@return integer previous_weekday The preceding weekday index (`0`-`6`).
---@nodiscard
function time.prevWeekday(weekday) end

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
---@nodiscard
function time.monthWeekday(weekday, index, month, year) end

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
---@nodiscard
function time.lastMonthWeekday(weekday, month, year) end

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
---@nodiscard
function time.isoWeek(year, month, day) end

--- [SHARED AND MENU]
---
--- Returns the number of ISO 8601 weeks in a given ISO week-numbering year.
---
--- A year has `53` ISO weeks if it starts on a Thursday, or if it is a leap year that starts
--- on a Wednesday; otherwise it has `52`.
---
---@param year? integer The ISO week-numbering year, the current year by default.
---@return integer weeks The number of ISO weeks in the year, `52` or `53`.
---@nodiscard
function time.isoWeeksInYear(year) end

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
---@nodiscard
function time.timestampFromCivil(year, month, day, hour, minute, second) end

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
---@nodiscard
function time.civilFromTimestamp(timestamp) end

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
---@param duration_str time.DurationString The duration string to convert.
---@param unit? time.Unit The unit to convert the duration to, 's' by default.
---@param as_float? boolean Whether to return the duration as a float, `false` by default.
---@return integer timestamp The duration in the specified unit.
---@nodiscard
function time.fromDuration(duration_str, unit, as_float) end

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
---@param unit? time.Unit The unit to convert the timestamp to, 's' by default.
---@return string duration_str The duration string.
---@nodiscard
function time.toDuration(timestamp, unit) end

--- [SHARED AND MENU]
---
--- Represents a date and time info.
---
---@class time.DateInfo
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
---@param unit? time.Unit The unit to parse the timestamp from, 's' by default.
---@param in_utc? boolean Whether to return the date in UTC instead of local time, `false` by default.
---@return time.DateInfo date_info The date and time components.
---@nodiscard
function time.parse(timestamp, unit, in_utc) end

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
---@param unit? time.Unit The unit of the timestamp, 's' by default.
---@param duration_str time.DurationString The duration string to add.
---@param as_float? boolean Whether to return the timestamp as a float, `false` by default.
---@return number new_timestamp
---@nodiscard
function time.add(timestamp, unit, duration_str, as_float) end

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
---@param unit? time.Unit The unit of the timestamp, 's' by default.
---@param duration_str time.DurationString The duration string to subtract.
---@param as_float? boolean Whether to return the timestamp as a float, `false` by default.
---@return number new_timestamp
---@nodiscard
function time.sub(timestamp, unit, duration_str, as_float) end

---@class time.FormatBuffer : metatable
---@field [ 0 ] boolean in_utc
---@field [ 1 ] integer seconds
---@field [ 2 ] integer nanoseconds sub-second remainder
---@field [ 5 ] time.DateInfo | nil
local FormatBuffer = {}

---@param key string
---@protected
function FormatBuffer:__index(key) end

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
---@param unit? time.Unit The timestamp unit, 's' by default.
---@param in_utc? boolean Use UTC instead of local timezone, `false` by default.
---@return string str The formatted string.
---@nodiscard
function time.format(fmt, timestamp, unit, in_utc) end

--- [SHARED AND MENU]
---
--- Converts a timestamp to an RFC 2822 date-time string, for example `Mon, 15 Jan 2024 10:30:00 +0000`.
---
--- This is the format used by email headers ( `Date:` ) and HTTP's obsolete `rfc1123-date`,
--- and is also what JavaScript's `Date.prototype.toString()` timezone-less variants are based on.
---
---@param timestamp? integer The timestamp to convert, current time by default.
---@param unit? time.Unit The unit of `timestamp`, `s` by default.
---@param in_utc? boolean Whether to format the string in UTC, `false` by default.
---@return string str The RFC 2822 date-time string.
---@nodiscard
function time.toRFC2822(timestamp, unit, in_utc) end

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
---@param unit? time.Unit The unit of `timestamp`, `s` by default.
---@param in_utc? boolean Whether to format the string in UTC ( with a `Z` suffix ), `false` by default.
---@return string str The JS-like date-time string.
---@nodiscard
function time.toISOString(timestamp, unit, in_utc) end

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
---@param unit? time.Unit The unit to return the timestamp in, `s` by default.
---@param as_float? boolean Whether to return the timestamp as a float, `false` by default.
---@return number timestamp The unix timestamp in the specified unit.
---@nodiscard
function time.fromISOString(str, unit, as_float) end

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
---@param unit? time.Unit The unit to return the timestamp in, `s` by default.
---@param as_float? boolean Whether to return the timestamp as a float, `false` by default.
---@return number timestamp The unix timestamp in the specified unit.
---@nodiscard
function time.fromRFC2822(str, unit, as_float) end
