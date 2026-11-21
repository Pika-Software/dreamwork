local dreamwork_engine = dreamwork.engine
local engine_hook = dreamwork_engine.hook

local dreamwork_sandbox = dreamwork.sandbox
local sandbox_owner = dreamwork_sandbox.owner
local sandbox_claim = dreamwork_sandbox.claim
local sandbox_prefix = dreamwork_sandbox.prefix

---@type garrysmod.surface
local glua_surface = dreamwork_engine.requireLibrary( "surface" )
local surface_CreateFont = glua_surface.CreateFont

---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_pairs = raw.pairs
local raw_index = raw.index
local raw_tostring = raw.tostring

local string = std.string
local string_format = string.format

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local uuid = std.uuid
local uuid_unique = uuid.unique

local class = std.class

local error = std.error

local ViewportLayout_parse = std.ViewportLayout.parse

--- Weak keys: each `Font` -> its engine font name.
---
---@type table<dreamwork.std.Font, string>
local font_names = {}
gc_setTableRules( font_names, true, false )

--- Weak keys: each `Font` -> its size descriptor (`"<number><ViewportUnit>"`).
---
---@type table<dreamwork.std.Font, string>
local font_descriptors = {}
gc_setTableRules( font_descriptors, true, false )

--- Weak keys: each `Font` -> the engine font data passed to `surface.CreateFont`.
---
---@type table<dreamwork.std.Font, table>
local font_data = {}
gc_setTableRules( font_data, true, false )

--- Engine font name -> the `Font` that currently owns it.
---
--- Strong, engine fonts can't be freed, so their owners are rebuilt on every resize.
---
---@type table<string, dreamwork.std.Font>
local registry = {}

--- Engine font data keys writable through `Font` fields, `size` is handled separately.
---
---@type table<string, boolean>
local font_params = {
    font = true,
    weight = true,
    blursize = true,
    scanlines = true,
    extended = true,
    antialias = true,
    underline = true,
    italic = true,
    strikeout = true,
    symbol = true,
    rotary = true,
    shadow = true,
    additive = true,
    outline = true
}

--- [CLIENT AND MENU]
---
--- An engine font whose size is a display length (`"2vmin"`, `"12pt"`, `"16px"`, …)
--- resolved by `ViewportLayout.parse` and recreated when the window is resized.
---
--- Every font parameter is a field, writing one recreates the engine font right away,
--- so each write costs a `surface.CreateFont` call.
---
--- `size` is the length descriptor, `size_px` is its resolved size. Writing `size_px`
--- overrides the size until the next screen size change, which re-resolves `size`.
---
--- Fonts created by a package get its id as the prefix, `{id}::{name}`. and stop being rebuilt when it unloads.
---
--- Creating a font with an already used name replaces the previous owner,
--- the old object stops being rebuilt but keeps the name. Writing a field
--- of the old object makes it the owner again.
---
--- Construction and `size` writes raise `ValueError` if the descriptor cannot be parsed.
---
--- ```lua
--- local title = Font( "my_addon.title", {
---     font = "Roboto",
---     size = "3vmin",
---     weight = 700
--- } )
---
--- print( title.size_px ) -- floored pixels for "3vmin"
---
--- title.weight = 800 -- recreated with the new weight
--- title.size_px = 32 -- 32px until the next screen size change
--- title.size = "4vmin" -- recreated from the new descriptor
--- ```
---
---@class dreamwork.std.Font : dreamwork.std.Object
---@field __class dreamwork.std.FontClass The class used to construct this object.
---@field name string The engine font name, usable with `surface.SetFont`, `draw.SimpleText`, panels, etc. Read-only.
---@field size string The size as a length quantity string (`"<number><ViewportUnit>"`).
---@field size_px integer The current size in pixels, writes last until the next screen size change.
---@field font string The font source, a font name or a `.ttf` file name in `resource/fonts`.
---@field weight integer The font boldness.
---@field blursize integer The strength of the font blurring, must be > 0 to apply.
---@field scanlines integer The "scanline" interval, must be > 1 to apply.
---@field extended boolean Allows characters outside of Latin-1.
---@field antialias boolean Smooths the font.
---@field underline boolean Adds an underline.
---@field italic boolean Makes the font italic.
---@field strikeout boolean Adds a strike through.
---@field symbol boolean Enables the use of symbolic fonts such as Webdings.
---@field rotary boolean Seems to add a line in the middle of each letter.
---@field shadow boolean Adds shadow casting to the font.
---@field additive boolean Additive rendering.
---@field outline boolean Adds a black outline.
local Font = class.base( "Font", true )

---@param uuid_str string
---@return boolean
local function is_unique( uuid_str )
    return registry[ uuid_str ] == nil
end

--- Stops rebuilding the font of an unloaded package, engine fonts can't be freed.
---
---@param font dreamwork.std.Font
local function release( font )
    local name = font_names[ font ]
    if registry[ name ] == font then
        registry[ name ] = nil
    end
end

---@param options dreamwork.std.Font.Options
---@protected
function Font:__init( options )
    local descriptor = options.size

    -- raises `ValueError` before anything is registered
    local size_px = ViewportLayout_parse( descriptor )

    local name = options.name
    if name == nil then
        name = uuid_unique( is_unique )
    end

    local owner = sandbox_owner( 2 )
    if owner ~= nil then
        name = sandbox_prefix( owner, name )
        sandbox_claim( owner, self, release )
    end

    local data = {
        font = options.font or "Arial",
        size = size_px,
        weight = options.weight or 500,
        blursize = options.blursize or 0,
        scanlines = options.scanlines or 0,
        extended = options.extended ~= false,
        antialias = options.antialias ~= false,
        underline = options.underline == true,
        italic = options.italic == true,
        strikeout = options.strikeout == true,
        symbol = options.symbol == true,
        rotary = options.rotary == true,
        shadow = options.shadow == true,
        additive = options.additive == true,
        outline = options.outline == true
    }

    font_names[ self ] = name
    font_descriptors[ self ] = descriptor
    font_data[ self ] = data

    registry[ name ] = self

    surface_CreateFont( name, data )
end

---@param key string The field name being read.
---@return any value
---@protected
function Font:__index( key )
    if key == "size" then
        return font_descriptors[ self ]
    elseif key == "size_px" then
        return font_data[ self ].size
    elseif key == "name" then
        return font_names[ self ]
    elseif font_params[ key ] then
        return font_data[ self ][ key ]
    end

    return raw_index( Font, key )
end

---@param key string
---@param value any
---@protected
function Font:__newindex( key, value )
    local data = font_data[ self ]

    if key == "size" then
        data.size = ViewportLayout_parse( value )
        font_descriptors[ self ] = value
    elseif key == "size_px" then
        data.size = value
    elseif font_params[ key ] then
        data[ key ] = value
    else
        error( string_format( "attempt to modify read-only Font property '%s'", raw_tostring( key ) ), 2 )
    end

    local name = font_names[ self ]
    registry[ name ] = self

    surface_CreateFont( name, data )
end

--- [CLIENT AND MENU]
---
--- The class used to create `Font` instances.
---
---@class dreamwork.std.FontClass : dreamwork.std.Font, dreamwork.std.Class
---@field __base dreamwork.std.Font The instance prototype shared by all `Font` objects.
---@overload fun( options: dreamwork.std.Font.Options ): dreamwork.std.Font
std.Font = class.create( Font )

-- runs after `gfx.window.resolution` ( priority `1` ), so `window` size is already updated
engine_hook.catch( "OnScreenSizeChanged", "gfx.font.resolution", function()
    for name, font in raw_pairs( registry ) do
        local data = font_data[ font ]
        data.size = ViewportLayout_parse( font_descriptors[ font ] )
        surface_CreateFont( name, data )
    end
end )

-- TODO: rework this class, required manual render and own fonts, gmod ones is f*cking broken :c
