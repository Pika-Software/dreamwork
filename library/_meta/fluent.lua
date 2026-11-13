---@meta _


--- [SHARED AND MENU]
---
--- The CLDR plural category.
---
---@alias fluent.Category "zero" | "one" | "two" | "few" | "many" | "other"

--- [SHARED AND MENU]
---
--- The CLDR plural rule, receives the plural operands of the absolute value:
--- * `n` - the absolute value;
--- * `i` - the integer digits;
--- * `v` - the number of visible fraction digits, with trailing zeros;
--- * `f` - the visible fraction digits, with trailing zeros;
--- * `t` - the visible fraction digits, without trailing zeros;
--- * `w` - the number of visible fraction digits, without trailing zeros.
---
---@alias fluent.PluralRule fun( n: number, i: number, v: integer, f: number, t: number, w: integer ): fluent.Category

--- [SHARED AND MENU]
---
--- The resolved value of an expression, strings or Fluent types ( `fluent.None`, `fluent.Number`, `fluent.DateTime` ).
---
---@alias fluent.Value string | FluentType

--- [SHARED AND MENU]
---
--- The value of a variable passed to `FluentBundle:formatPattern`,
--- numbers become `fluent.Number`, timestamps must be wrapped in `fluent.DateTime`.
---
---@alias fluent.Argument string | number | FluentType

--- [SHARED AND MENU]
---
--- The function callable from FTL, e.g. `{ NUMBER( $count, minimumFractionDigits: 2 ) }`.
---
--- Function names must be upper-case, the returned numbers are wrapped in `fluent.Number`.
---
---@alias fluent.Function fun( positional: fluent.Value[], named: table<string, fluent.Value> ): fluent.Value | number

--- [SHARED AND MENU]
---
--- The pattern, a plain string if it has no placeables.
---
---@alias fluent.Pattern string | fluent.PatternElement[]

---@alias fluent.PatternElement string | fluent.Expression

---@alias fluent.Expression fluent.StringLiteral | fluent.NumberLiteral | fluent.VariableReference | fluent.MessageReference | fluent.TermReference | fluent.FunctionReference | fluent.SelectExpression

---@alias fluent.Literal fluent.StringLiteral | fluent.NumberLiteral

--- [SHARED AND MENU]
---
--- The string literal, `"text"`.
---
---@class fluent.StringLiteral
---@field type "str"
---@field value string The unescaped text.

--- [SHARED AND MENU]
---
--- The number literal, `-1.50`.
---
---@class fluent.NumberLiteral
---@field type "num"
---@field value number The number.
---@field precision integer The number of fraction digits written in the source.
---@field options fluent.NumberOptions The formatting options keeping the written fraction digits, shared between literals.

--- [SHARED AND MENU]
---
--- The variable reference, `$name`.
---
---@class fluent.VariableReference
---@field type "var"
---@field name string The variable name, without `$`.

--- [SHARED AND MENU]
---
--- The message reference, `message` or `message.attribute`.
---
---@class fluent.MessageReference
---@field type "mesg"
---@field name string The message identifier.
---@field attribute string | nil The attribute name.

--- [SHARED AND MENU]
---
--- The term reference, `-term`, `-term.attribute` or `-term( name: "value" )`.
---
---@class fluent.TermReference
---@field type "term"
---@field name string The term identifier, without `-`.
---@field id string The term identifier, with `-`.
---@field attribute string | nil The attribute name.
---@field arguments fluent.CallArgument[] The arguments, only the named ones are visible to the term.

--- [SHARED AND MENU]
---
--- The function call, `FUNCTION( $value, name: "value" )`.
---
---@class fluent.FunctionReference
---@field type "func"
---@field name string The function name.
---@field arguments fluent.CallArgument[] The arguments.

---@alias fluent.CallArgument fluent.Expression | fluent.NamedArgument

--- [SHARED AND MENU]
---
--- The named argument, `name: "value"` or `name: 1`.
---
---@class fluent.NamedArgument
---@field type "narg"
---@field name string The argument name.
---@field value fluent.Literal The argument value.

--- [SHARED AND MENU]
---
--- The select expression, `{ $count -> [one] ... *[other] ... }`.
---
---@class fluent.SelectExpression
---@field type "select"
---@field selector fluent.Expression The selector.
---@field variants fluent.Variant[] The variants.
---@field star integer The index of the default variant.

--- [SHARED AND MENU]
---
--- The variant of the select expression, `[key] value`.
---
---@class fluent.Variant
---@field key fluent.Literal The key, an identifier is a string literal.
---@field value fluent.Pattern The value.

--- [SHARED AND MENU]
---
--- The message or the term.
---
---@class fluent.Message
---@field id string The identifier, terms start with `-`.
---@field value fluent.Pattern | nil The value, terms always have it.
---@field attributes table<string, fluent.Pattern> The attributes by their names.

--- [SHARED AND MENU]
---
--- The options of `FluentBundle`.
---
---@class fluent.BundleOptions
---@field functions table<string, fluent.Function> | nil The functions available to messages, in addition to `NUMBER` and `DATETIME`.
---@field use_isolating boolean | nil If `true`, placeables of complex patterns are wrapped in Unicode bidi isolation marks ( FSI, PDI ), `false` by default since Source fonts render them as boxes.
---@field transform ( fun( text: string ): string ) | nil The function applied to every text element of patterns.

--- [SHARED AND MENU]
---
--- The state of the single `FluentBundle:formatPattern` call, passed to `FluentType:toString`.
---
---@class fluent.Scope
---@field bundle FluentBundle The bundle that formats the pattern.
---@field args table<string, fluent.Argument> | nil The variables passed by the developer.
---@field errors Error[] | nil The list collecting the errors, errors are thrown if `nil`.
---@field params table<string, fluent.Value> | nil The named arguments of the term being resolved.
---@field dirty table<fluent.PatternElement[], boolean> The patterns being resolved, used to detect cycles.
---@field placeables integer The number of placeables resolved so far.

--- [SHARED AND MENU]
---
--- The options of `fluent.Number` and `NUMBER`, a subset of `Intl.NumberFormat` options.
---
--- `style` and `currency` can be set only from Lua, translators can not change them.
---
---@class fluent.NumberOptions
---@field style "decimal" | "percent" | "currency" | nil The formatting style, `"decimal"` by default.
---@field currency string | nil The ISO 4217 currency code, e.g. `"USD"`, required by the `"currency"` style.
---@field currencyDisplay "symbol" | "narrowSymbol" | "code" | "name" | nil How the currency is displayed, `"symbol"` by default, `"name"` falls back to the code.
---@field useGrouping boolean | "always" | "auto" | "min2" | "true" | "false" | nil Whether the integer digits are grouped, locale dependent ( `"auto"` ) by default.
---@field minimumIntegerDigits integer | nil The minimum number of integer digits, `1` by default.
---@field minimumFractionDigits integer | nil The minimum number of fraction digits, `0` by default ( `2` for most currencies ).
---@field maximumFractionDigits integer | nil The maximum number of fraction digits, `3` by default ( `0` for percents, `2` for most currencies ).
---@field minimumSignificantDigits integer | nil The minimum number of significant digits, `1` by default, overrides the fraction digits.
---@field maximumSignificantDigits integer | nil The maximum number of significant digits, `21` by default, overrides the fraction digits.
---@field type "cardinal" | "ordinal" | nil The plural rule used to select variants, `"cardinal"` by default.

--- [SHARED AND MENU]
---
--- The options of `fluent.DateTime` and `DATETIME`, a subset of `Intl.DateTimeFormat` options.
---
--- The component options pick the closest locale style:
--- * `weekday` - `"full"` date;
--- * `month: "long"` - `"long"` date;
--- * `month: "short"` - `"medium"` date;
--- * `year`, `month` or `day` - `"short"` date;
--- * `second` - `"medium"` time;
--- * `hour` or `minute` - `"short"` time.
---
--- `timeZone` can be set only from Lua, translators can not change it.
---
---@class fluent.DateTimeOptions
---@field dateStyle "full" | "long" | "medium" | "short" | nil The date style.
---@field timeStyle "full" | "long" | "medium" | "short" | nil The time style, `"long"` and `"full"` are the same as `"medium"`.
---@field weekday string | nil Shows the weekday.
---@field year string | nil Shows the year.
---@field month string | nil Shows the month.
---@field day string | nil Shows the day.
---@field hour string | nil Shows the hour.
---@field minute string | nil Shows the minute.
---@field second string | nil Shows the second.
---@field hour12 boolean | "true" | "false" | nil Overrides the locale 12/24-hour clock.
---@field timeZone string | nil `"UTC"` formats the UTC time, any other value or `nil` formats the local time.

--- [SHARED AND MENU]
---
--- The formatting data of the locale.
---
--- Date and time patterns contain `{token}` placeholders:
--- * `{d}`, `{dd}` - the day, `{dd}` is zero padded;
--- * `{M}`, `{MM}` - the month number, `{MM}` is zero padded;
--- * `{MMM}`, `{MMMM}` - the short and full month name;
--- * `{y}`, `{yy}` - the full and two-digit year;
--- * `{E}`, `{EEEE}` - the short and full weekday name;
--- * `{H}`, `{HH}` - the 24-hour hour, `{HH}` is zero padded;
--- * `{h}`, `{hh}` - the 12-hour hour, `{hh}` is zero padded;
--- * `{mm}`, `{ss}` - the zero padded minute and second;
--- * `{a}` - the day period, `am` or `pm`.
---
---@class fluent.Locale
---@field tag string The locale tag, e.g. `"pt-BR"`.
---@field decimal string The decimal separator.
---@field group string The grouping separator.
---@field minus string The minus sign.
---@field minimum_grouping integer The minimum number of digits in the leading group, `2` means `1000` is not grouped.
---@field primary_group integer The size of the lowest group of the integer digits.
---@field secondary_group integer | nil The size of higher groups, `primary_group` if `nil`.
---@field percent string The percent pattern, `#` is the number, e.g. `"# %"`.
---@field currency string The currency pattern, `#` is the number, `¤` is the currency, e.g. `"¤#"`.
---@field cardinal fluent.PluralRule The cardinal plural rule, `1 file`, `2 files`.
---@field ordinal fluent.PluralRule The ordinal plural rule, `1st`, `2nd`.
---@field date table<string, string> The date patterns by styles, `short` is required, missing styles fall back to `short`.
---@field time table<string, string> The time patterns by styles, `short` and `medium` are required.
---@field datetime string The pattern joining the date and the time, `{date}` and `{time}` are the patterns.
---@field months string[] The full month names, used by `{MMMM}`.
---@field months_short string[] The short month names, used by `{MMM}`.
---@field weekdays string[] The full weekday names, Sunday first, used by `{EEEE}`.
---@field weekdays_short string[] The short weekday names, Sunday first, used by `{E}`.
---@field am string The before noon day period.
---@field pm string The after noon day period.
