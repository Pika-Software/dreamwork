---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_pairs = raw.pairs
local raw_tonumber = raw.tonumber

local math = std.math
local math_pi = math.pi

local string = std.string
local string_match = string.match
local string_format = string.format

local table = std.table
local table_range = table.range

local error = std.error
local isFunction = std.isFunction

local ValueError = std.ValueError


--- [CLIENT AND MENU]
---
--- Physical quantity kind used by `unit`.
---
--- Conversion is only allowed between units that share the same measure;
--- crossing measures (for example mass → volume) raises `ValueError`.
---
---@alias dreamwork.std.unit.Measure
---| "length" # Distance, including CSS reference lengths at 96 DPI (`px`, `pt`, `pc`, `q`).
---| "mass" # Mass / weight.
---| "volume" # Volume / capacity.
---| "area" # Surface area.
---| "temperature" # Thermodynamic temperature (`C` / `K` / `F` / `R`).
---| "time" # Duration.
---| "angle" # Plane angle.
---| "speed" # Linear speed / velocity.
---| "digital" # Digital information size (SI bit/byte and IEC bit/byte).

--- [CLIENT AND MENU]
---
--- Unit system name within a measure.
---
--- Examples: `"metric"`, `"imperial"`, `"SI"`, `"bit"`, `"byte"`, `"IECBit"`, `"IECByte"`.
--- Cross-system conversion uses per-measure anchor ratios or transforms.
---
---@alias dreamwork.std.unit.System string

--- [CLIENT AND MENU]
---
--- Unit abbreviations registered in `unit` (convert-units style).
---
--- Live viewport lengths (`vmin`, `vw`, …) are not part of this library;
--- resolve those with `PixelMap`.
---
---@alias dreamwork.std.unit.Type
---|# Length — metric (anchor: meter)
---| "nm" # Nanometer.
---| "um" # Micrometer; ASCII alias of `μm`.
---| "μm" # Micrometer.
---| "mm" # Millimeter.
---| "cm" # Centimeter.
---| "dm" # Decimeter.
---| "m" # Meter.
---| "km" # Kilometer.
---| "q" # Quarter-millimeter (`0.25` mm / CSS `q`).
---| "pc" # Pica (`1/6` in at 96 DPI).
---| "pt" # Point (`1/72` in at 96 DPI).
---| "px" # CSS reference pixel (`1/96` in).
---|# Length — imperial (anchor: foot)
---| "mil" # Thou; `1/1000` inch.
---| "in" # Inch.
---| "yd" # Yard.
---| "ft-us" # US survey foot.
---| "ft" # International foot.
---| "fathom" # Fathom.
---| "mi" # Statute mile.
---| "nMi" # Nautical mile.
---|# Mass — metric (anchor: gram)
---| "mcg" # Microgram.
---| "mg" # Milligram.
---| "g" # Gram.
---| "kg" # Kilogram.
---| "mt" # Metric tonne.
---|# Mass — imperial (anchor: pound)
---| "oz" # Ounce.
---| "lb" # Pound.
---| "st" # Stone.
---| "t" # US short ton.
---|# Volume — metric (anchor: litre)
---| "mm3" # Cubic millimeter.
---| "cm3" # Cubic centimeter.
---| "dm3" # Cubic decimeter (equal to `1` litre).
---| "ml" # Millilitre.
---| "cl" # Centilitre.
---| "dl" # Decilitre.
---| "l" # Litre.
---| "kl" # Kilolitre.
---| "Ml" # Megalitre.
---| "Gl" # Gigalitre.
---| "m3" # Cubic meter.
---| "km3" # Cubic kilometer.
---| "krm" # Swedish kryddmått (`1` ml).
---| "tsk" # Swedish tesked (`5` ml).
---| "msk" # Swedish matsked (`15` ml).
---| "kkp" # Swedish kaffekopp (`150` ml).
---| "glas" # Swedish glas (`200` ml).
---| "kanna" # Swedish kanna (`2.617` l).
---|# Volume — imperial (anchor: fluid ounce)
---| "tsp" # Teaspoon.
---| "Tbs" # Tablespoon.
---| "in3" # Cubic inch.
---| "fl-oz" # US fluid ounce.
---| "cup" # US cup.
---| "pnt" # US pint.
---| "qt" # US quart.
---| "gal" # US gallon.
---| "ft3" # Cubic foot.
---| "yd3" # Cubic yard.
---|# Area — metric (anchor: square meter)
---| "nm2" # Square nanometer.
---| "um2" # Square micrometer; ASCII alias of `μm2`.
---| "μm2" # Square micrometer.
---| "mm2" # Square millimeter.
---| "cm2" # Square centimeter.
---| "dm2" # Square decimeter.
---| "m2" # Square meter.
---| "a" # Are (`100` m²).
---| "ha" # Hectare.
---| "km2" # Square kilometer.
---|# Area — imperial (anchor: square foot)
---| "in2" # Square inch.
---| "yd2" # Square yard.
---| "ft2" # Square foot.
---| "ac" # Acre.
---| "mi2" # Square mile.
---|# Temperature — metric
---| "C" # Degree Celsius.
---| "K" # Kelvin.
---|# Temperature — imperial
---| "F" # Degree Fahrenheit.
---| "R" # Degree Rankine.
---|# Time — SI (anchor: second)
---| "ns" # Nanosecond.
---| "mu" # Microsecond.
---| "ms" # Millisecond.
---| "s" # Second.
---| "min" # Minute.
---| "h" # Hour.
---| "d" # Day.
---| "week" # Week.
---| "month" # Mean Gregorian month (`year / 12`).
---| "year" # Mean Gregorian year (`365.25` days).
---| "decade" # Ten years.
---| "century" # One hundred years.
---|# Angle — SI (anchor: degree)
---| "rad" # Radian.
---| "deg" # Degree.
---| "grad" # Gradian.
---| "arcmin" # Arcminute.
---| "arcsec" # Arcsecond.
---|# Speed — metric (anchor: km/h)
---| "m/s" # Metre per second.
---| "km/h" # Kilometre per hour.
---| "mm/h" # Millimeter per hour.
---|# Speed — imperial (anchor: mph)
---| "mph" # Mile per hour.
---| "knot" # Nautical mile per hour.
---| "ft/s" # Foot per second.
---| "ft/min" # Foot per minute.
---| "in/h" # Inch per hour.
---|# Digital — SI bit (anchor: bit)
---| "bit" # Bit.
---| "kb" # Kilobit (`10^3` bits).
---| "Mb" # Megabit (`10^6` bits).
---| "Gb" # Gigabit (`10^9` bits).
---| "Tb" # Terabit (`10^12` bits).
---|# Digital — SI byte (anchor: byte)
---| "byte" # Byte (`8` bits).
---| "kB" # Kilobyte (`10^3` bytes).
---| "MB" # Megabyte (`10^6` bytes).
---| "GB" # Gigabyte (`10^9` bytes).
---| "TB" # Terabyte (`10^12` bytes).
---|# Digital — IEC bit (anchor: kibibit)
---| "Kib" # Kibibit (`2^10` bits).
---| "Mib" # Mebibit (`2^20` bits).
---| "Gib" # Gibibit (`2^30` bits).
---| "Tib" # Tebibit (`2^40` bits).
---|# Digital — IEC byte (anchor: kibibyte)
---| "KiB" # Kibibyte (`2^10` bytes).
---| "MiB" # Mebibyte (`2^20` bytes).
---| "GiB" # Gibibyte (`2^30` bytes).
---| "TiB" # Tebibyte (`2^40` bytes).

--- [CLIENT AND MENU]
---
--- Static unit conversion library (convert-units style, no object allocation).
---
--- Units belong to a measure and a system. Conversion scales through each
--- system's anchor, applies optional `anchor_shift` (temperature), then bridges
--- systems when needed.
---
--- ```lua
--- unit.convert( 1, "l", "ml" )   -- 1000
--- unit.convert( 1, "lb", "kg" )  -- ~0.4536
--- unit.convert( 100, "C", "F" )  -- 212
---
--- local value, abbr = unit.parse( "10cm" ) -- 10, "cm"
---
--- unit.measures()               -- { "length", "mass", ... }, count
--- unit.possibilities( "mass" )  -- { "mcg", "mg", ... }, count
--- ```
---
---@class dreamwork.std.unit
local unit = {}
std.unit = unit

--- CSS reference pixel expressed in meters (`1 px = 1/96 in`).
local CSS_PX_METERS = 0.0254 / 96

--- [CLIENT AND MENU]
---
--- Internal definition of one registered unit abbreviation.
---
---@class dreamwork.std.unit.Definition
---@field measure dreamwork.std.unit.Measure The measure this unit belongs to.
---@field system dreamwork.std.unit.System The unit system inside that measure (for example `"metric"`).
---@field to_anchor number Multiplier from this unit into the system's anchor unit (`value * to_anchor`).
---@field anchor_shift number | nil Additive shift around the system anchor; used by temperature (`K`, `R`).

--- Registered abbreviation -> definition.
---
---@type table<dreamwork.std.unit.Type, dreamwork.std.unit.Definition>
local unit_definitions = {}

--- Per-measure bridges between systems: `measure_anchors[measure][from][to]`.
--- Values are either a ratio (`number`) or a transform (`fun(value): number`).
---
---@type table<dreamwork.std.unit.Measure, table<dreamwork.std.unit.System, table<dreamwork.std.unit.System, number | fun( value: number ): number>>>
local measure_anchors = {}

--- Ordered measure names; index `[0]` stores the length.
---
---@type dreamwork.std.unit.Measure[]
local measure_list = { [ 0 ] = 0 }

--- Measure -> ordered unit abbreviations; each list stores its length at `[0]`.
---
---@type table<dreamwork.std.unit.Measure, dreamwork.std.unit.Type[]>
local measure_units = {}

--- Registers a single unit abbreviation and appends it to that measure's unit list.
---
---@param measure dreamwork.std.unit.Measure The measure the unit belongs to.
---@param system dreamwork.std.unit.System The system inside that measure.
---@param abbr dreamwork.std.unit.Type | string The unit abbreviation (lookup key).
---@param to_anchor number Multiplier into the system anchor (`1` of this unit = `to_anchor` anchor units).
---@param anchor_shift? number Optional additive shift around the system anchor.
local function define_unit( measure, system, abbr, to_anchor, anchor_shift )
    unit_definitions[ abbr ] = {
        measure = measure,
        system = system,
        to_anchor = to_anchor,
        anchor_shift = anchor_shift
    }

    local units = measure_units[ measure ]
    if units == nil then
        units = { [ 0 ] = 0 }
        measure_units[ measure ] = units

        local list_size = measure_list[ 0 ] + 1
        measure_list[ list_size ] = measure
        measure_list[ 0 ] = list_size
    end

    local unit_count = units[ 0 ] + 1
    units[ unit_count ] = abbr
    units[ 0 ] = unit_count
end

--- Registers every abbreviation in `definitions` under one measure/system.
---
---@param measure dreamwork.std.unit.Measure The measure the units belong to.
---@param system dreamwork.std.unit.System The system inside that measure.
---@param definitions table<string, number> Map of abbreviation -> `to_anchor` factor.
local function define_system( measure, system, definitions )
    for abbr, to_anchor in raw_pairs( definitions ) do
        define_unit( measure, system, abbr, to_anchor )
    end
end

do

    define_system( "length", "metric", {
        nm = 1e-9,
        um = 1e-6,
        [ "μm" ] = 1e-6,
        mm = 1e-3,
        cm = 1e-2,
        dm = 1e-1,
        m = 1,
        km = 1e3,
        q = 2.5e-4,
        pc = 0.0254 / 6,
        pt = 0.0254 / 72,
        px = CSS_PX_METERS
    } )

    define_system( "length", "imperial", {
        mil = 1 / 12000,
        [ "in" ] = 1 / 12,
        yd = 3,
        [ "ft-us" ] = 1.000002,
        ft = 1,
        fathom = 6,
        mi = 5280,
        nMi = 6076.12
    } )

    measure_anchors.length = {
        metric = { imperial = 3.28084 },
        imperial = { metric = 1 / 3.28084 }
    }

end

do

    define_system( "mass", "metric", {
        mcg = 1 / 1e6,
        mg = 1 / 1e3,
        g = 1,
        kg = 1e3,
        mt = 1e6
    } )

    define_system( "mass", "imperial", {
        oz = 1 / 16,
        lb = 1,
        st = 14,
        t = 2e3
    } )

    measure_anchors.mass = {
        metric = { imperial = 1 / 453.59237 },
        imperial = { metric = 453.59237 }
    }

end

do

    define_system( "volume", "metric", {
        mm3 = 1 / 1e6,
        cm3 = 1 / 1e3,
        dm3 = 1,
        ml = 1 / 1e3,
        cl = 1 / 100,
        dl = 1 / 10,
        l = 1,
        kl = 1e3,
        Ml = 1e6,
        Gl = 1e9,
        m3 = 1e3,
        km3 = 1e12,
        krm = 1 / 1e3,
        tsk = 5 / 1e3,
        msk = 15 / 1e3,
        kkp = 150 / 1e3,
        glas = 200 / 1e3,
        kanna = 2.617
    } )

    define_system( "volume", "imperial", {
        tsp = 1 / 6,
        Tbs = 1 / 2,
        in3 = 0.5541125541125541,
        [ "fl-oz" ] = 1,
        cup = 8,
        pnt = 16,
        qt = 32,
        gal = 128,
        ft3 = 957.5064935064935,
        yd3 = 25852.675324675325
    } )

    measure_anchors.volume = {
        metric = { imperial = 33.8140226 },
        imperial = { metric = 1 / 33.8140226 }
    }

end

do

    define_system( "area", "metric", {
        nm2 = 1e-18,
        um2 = 1e-12,
        [ "μm2" ] = 1e-12,
        mm2 = 1 / 1e6,
        cm2 = 1 / 1e4,
        dm2 = 1 / 100,
        m2 = 1,
        a = 100,
        ha = 1e4,
        km2 = 1e6
    } )

    define_system( "area", "imperial", {
        in2 = 1 / 144,
        yd2 = 9,
        ft2 = 1,
        ac = 43560,
        mi2 = 27878400
    } )

    measure_anchors.area = {
        metric = { imperial = 10.7639 },
        imperial = { metric = 1 / 10.7639 }
    }

end

do

    define_unit( "temperature", "metric", "C", 1, 0 )
    define_unit( "temperature", "metric", "K", 1, 273.15 )
    define_unit( "temperature", "imperial", "F", 1 )
    define_unit( "temperature", "imperial", "R", 1, 459.67 )

    measure_anchors.temperature = {
        metric = {
            imperial = function( celsius )
                return celsius * 9 / 5 + 32
            end
        },
        imperial = {
            metric = function( fahrenheit )
                return (fahrenheit - 32) * 5 / 9
            end
        }
    }

end

do

    define_system( "time", "SI", {
        ns = 1 / 1e9,
        mu = 1 / 1e6,
        ms = 1 / 1e3,
        s = 1,
        min = 60,
        h = 3.6e3,
        d = 8.64e4,
        week = 6.048e5,
        month = 3.15576e7 / 12,
        year = 3.15576e7,
        decade = 3.15576e8,
        century = 3.15576e9
    } )

end

do

    define_system( "angle", "SI", {
        rad = 180 / math_pi,
        deg = 1,
        grad = 9 / 10,
        arcmin = 1 / 60,
        arcsec = 1 / 3600
    } )

end

do

    define_system( "speed", "metric", {
        [ "m/s" ] = 3.6,
        [ "km/h" ] = 1,
        [ "mm/h" ] = 1e-6
    } )

    define_system( "speed", "imperial", {
        mph = 1,
        knot = 1.150779,
        [ "ft/s" ] = 0.681818,
        [ "ft/min" ] = 1.13636e-2,
        [ "in/h" ] = 1.578e-5
    } )

    measure_anchors.speed = {
        metric = { imperial = 1 / 1.609344 },
        imperial = { metric = 1.609344 }
    }

end

do

    define_system( "digital", "bit", {
        bit = 1,
        kb = 1e3,
        Mb = 1e6,
        Gb = 1e9,
        Tb = 1e12
    } )

    define_system( "digital", "byte", {
        byte = 1,
        kB = 1e3,
        MB = 1e6,
        GB = 1e9,
        TB = 1e12
    } )

    define_system( "digital", "IECBit", {
        Kib = 1,
        Mib = 1024,
        Gib = 1.048576e6,
        Tib = 1.073741824e9
    } )

    define_system( "digital", "IECByte", {
        KiB = 1,
        MiB = 1024,
        GiB = 1.048576e6,
        TiB = 1.073741824e9
    } )

    measure_anchors.digital = {
        bit = {
            byte = 1.25e-1,
            IECBit = 9.765625e-4,
            IECByte = 1.220703125e-4
        },
        byte = {
            bit = 8,
            IECBit = 7.8125e-3,
            IECByte = 9.765625e-4
        },
        IECBit = {
            bit = 1024,
            byte = 1.28e2,
            IECByte = 1.25e-1
        },
        IECByte = {
            bit = 8.192e3,
            byte = 1024,
            IECBit = 8
        }
    }

end


--- [CLIENT AND MENU]
---
--- Converts `value` from `from_unit` into `to_unit` within one measure.
---
--- Raises `ValueError` when either abbreviation is unknown, the measures differ,
--- or no system bridge exists between the two systems.
---
--- ```lua
--- unit.convert( 1, "l", "ml" )  -- 1000
--- unit.convert( 100, "C", "F" ) -- 212
--- unit.convert( 1, "lb", "kg" ) -- ~0.4536
--- ```
---
---@param value number The numeric magnitude expressed in `from_unit`.
---@param from_unit dreamwork.std.unit.Type | string The source unit abbreviation.
---@param to_unit dreamwork.std.unit.Type | string The destination unit abbreviation.
---@return number converted The value expressed in `to_unit`.
---@nodiscard
function unit.convert( value, from_unit, to_unit )
    if from_unit == to_unit then
        return value
    end

    local source = unit_definitions[ from_unit ]
    if source == nil then
        error( ValueError( from_unit, "unsupported unit" ), 2 )
    end

    local target = unit_definitions[ to_unit ]
    if target == nil then
        error( ValueError( to_unit, "unsupported unit" ), 2 )
    end

    if source.measure ~= target.measure then
        error( ValueError( to_unit, string_format( "cannot convert incompatible measures of %s and %s", source.measure, target.measure ) ), 2 )
    end

    local result = value * source.to_anchor

    local source_shift = source.anchor_shift
    if source_shift ~= nil then
        result = result - source_shift
    end

    if source.system ~= target.system then
        local systems = measure_anchors[ source.measure ]
        local from_system = systems and systems[ source.system ]
        local bridge = from_system and from_system[ target.system ]

        if bridge == nil then
            error( ValueError( to_unit, string_format( "missing anchor between %s and %s", source.system, target.system ) ), 2 )
        end

        if isFunction( bridge ) then
            ---@cast bridge fun( value: number ): number
            result = bridge( result )
        else
            ---@cast bridge number
            result = result * bridge
        end
    end

    local target_shift = target.anchor_shift
    if target_shift ~= nil then
        result = result + target_shift
    end

    return result / target.to_anchor
end

--- [CLIENT AND MENU]
---
--- Parses a quantity string such as `"10cm"`, `"1.5ft-us"`, or `"100C"`.
---
--- Raises `ValueError` with `"missing magnitude"`, `"missing unit type"`, or
--- `"unsupported unit"` when the descriptor cannot be parsed.
---
--- ```lua
--- local value, abbr = unit.parse( "10cm" ) -- 10, "cm"
--- ```
---
---@param descriptor string The quantity string to parse (`"<number><unit>"`).
---@return number magnitude The numeric part of the descriptor.
---@return dreamwork.std.unit.Type unit_type The unit abbreviation.
---@nodiscard
function unit.parse( descriptor )
    local magnitude_str, unit_type = string_match( descriptor, "^([%+%-]?%d*%.?%d+)(.*)$" )
    if magnitude_str == nil then
        error( ValueError( descriptor, "missing magnitude" ), 2 )
    end

    if unit_type == nil or unit_type == "" then
        error( ValueError( descriptor, "missing unit type" ), 2 )
    end

    if unit_definitions[ unit_type ] == nil then
        error( ValueError( unit_type, "unsupported unit" ), 2 )
    end

    ---@cast unit_type dreamwork.std.unit.Type

    return raw_tonumber( magnitude_str ) or 0, unit_type
end

--- [CLIENT AND MENU]
---
--- Returns a copy of the configured measure names in registration order.
---
--- ```lua
--- local measures, count = unit.measures()
--- -- measures = { "length", "mass", "volume", ... }
--- ```
---
---@return dreamwork.std.unit.Measure[] measures A new list of configured measure names (1-based, no `[0]` length slot).
---@return integer measure_count The number of measure names in the returned list.
---@nodiscard
function unit.measures()
    return table_range( measure_list, 0, nil, measure_list[ 0 ] )
end

--- [CLIENT AND MENU]
---
--- Lists unit abbreviations available for conversion.
---
--- When `measure` is set, only that measure's units are returned.
--- When omitted, every configured unit across all measures is returned.
--- An unknown measure raises `ValueError`.
---
--- ```lua
--- local mass_units, count = unit.possibilities( "mass" ) -- { "mcg", "mg", "g", ... }, count
--- local all_units = unit.possibilities()                 -- every configured unit
--- ```
---
---@param measure? dreamwork.std.unit.Measure Optional measure filter.
---@return dreamwork.std.unit.Type[] unit_types A new list of matching unit abbreviations (1-based, no `[0]` length slot).
---@return integer unit_count The number of matching unit abbreviations.
---@nodiscard
function unit.possibilities( measure )
    if measure ~= nil then
        local units = measure_units[ measure ]
        if units == nil then
            error( ValueError( measure, "unknown measure" ), 2 )
        end

        return table_range( units, 0, nil, units[ 0 ] )
    end

    ---@type dreamwork.std.unit.Type[]
    local output = {}

    ---@type integer
    local count = 0

    for i = 1, measure_list[ 0 ], 1 do
        local units = measure_units[ measure_list[ i ] ]
        for j = 1, units[ 0 ], 1 do
            count = count + 1
            output[ count ] = units[ j ]
        end
    end

    return output, count
end
