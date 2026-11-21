---@class dreamwork
local dreamwork = dreamwork

local dreamwork_getUpTime = dreamwork.getUpTime

local dreamwork_engine = dreamwork.engine

local engine_hook = dreamwork_engine.hook
local hook_catch = engine_hook.catch
local hook_release = engine_hook.release

---@type garrysmod.cam
local glua_cam = dreamwork_engine.requireLibrary( "cam" )
local cam_Start = glua_cam.Start
local cam_End2D = glua_cam.End2D

---@type garrysmod.render
local glua_render = dreamwork_engine.requireLibrary( "render" )
local render_Clear = glua_render.Clear

local glua_surface = dreamwork_engine.requireLibrary( "surface" )
local surface_SetFont = glua_surface.SetFont
local surface_DrawRect = glua_surface.DrawRect
local surface_DrawText = glua_surface.DrawText
local surface_CreateFont = glua_surface.CreateFont
local surface_SetTextPos = glua_surface.SetTextPos
local surface_GetTextSize = glua_surface.GetTextSize
local surface_SetDrawColor = glua_surface.SetDrawColor
local surface_SetTextColor = glua_surface.SetTextColor
local surface_SetAlphaMultiplier = glua_surface.SetAlphaMultiplier

local cli_formatBytes = dreamwork.cli.formatBytes

---@class dreamwork.std
local std = dreamwork.std

local math = std.math
local math_cos = math.cos
local math_sin = math.sin
local math_abs = math.abs
local math_max = math.max
local math_min = math.min
local math_sqrt = math.sqrt
local math_floor = math.floor

local string = std.string
local string_byte = string.byte
local string_format = string.format

local table_concat = std.table.concat

local raw_pairs = std.raw.pairs

local window = std.window

local setTimeout = std.setTimeout
local tostring = std.tostring

---@type dreamwork.transport
local transport = dreamwork.transport

---@type dreamwork.loader
local loader = dreamwork.loader


--- [CLIENT]
---
--- The screen shown while the client receives packages from the server.
---
--- While it is fully visible the game does not render the world at all (`PreRender`),
--- the screen shows a pixel satellite sending pixel waves to a pixel moon, a progress bar
--- and the last steps, older ones fade out towards the bottom.
---
--- It appears only if receiving takes longer than a moment, and stays long enough to be seen.
---
--- While it is active the player stands still, `StartCommand` empties its commands.
---
---@class dreamwork.loading
local loading = dreamwork.loading or {}
dreamwork.loading = loading

--- Seconds of work before the screen starts to appear.
local SHOW_DELAY = 0.2

--- Seconds of fading in and out.
local FADE_TIME = 0.3

--- Seconds the screen stays at least once it appeared.
local MIN_VISIBLE = 1.0

--- The number of log lines, the last one is almost invisible.
local LOG_LINES = 10

--- The size of the scene in art pixels.
local SCENE_WIDTH, SCENE_HEIGHT = 128, 56

--- The identifier of the engine hooks.
local HOOK_ID = "modules.loading"

---@alias dreamwork.loading.Rect { [1]: integer, [2]: integer, [3]: integer, [4]: integer, [5]: integer, [6]: integer }

--- Turns the sprite rows into horizontal runs of the same color: `x, y, width, r, g, b`.
---
---@param rows string[]
---@param palette table<integer, integer[]>
---@return dreamwork.loading.Rect[] rects
---@return integer rect_count
local function compile_sprite( rows, palette )
    ---@type dreamwork.loading.Rect[]
    local rects = {}
    local rect_count = 0

    for y = 1, #rows, 1 do
        local row = rows[ y ]
        local x = 1
        local width = #row

        ::row_scanner::

        if x > width then
            goto next_row
        end

        do
            local uint8 = string_byte( row, x, x )
            local color = palette[ uint8 ]

            if color == nil then
                x = x + 1
                goto row_scanner
            end

            local run_end = x
            while run_end < width and string_byte( row, run_end + 1, run_end + 1 ) == uint8 do
                run_end = run_end + 1
            end

            rect_count = rect_count + 1
            rects[ rect_count ] = { x - 1, y - 1, run_end - x + 1, color[ 1 ], color[ 2 ], color[ 3 ] }

            x = run_end + 1
        end

        goto row_scanner

        ::next_row::
    end

    return rects, rect_count
end

-- the satellite: solar panels above and below the body, the dish faces the moon

---@type table<integer, integer[]>
local satellite_palette = {
    [ 0x6C --[[ l ]] ] = { 112, 158, 240 },
    [ 0x50 --[[ P ]] ] = { 58, 98, 190 },
    [ 0x70 --[[ p ]] ] = { 36, 62, 132 },
    [ 0x73 --[[ s ]] ] = { 112, 114, 126 },
    [ 0x47 --[[ G ]] ] = { 214, 218, 228 },
    [ 0x67 --[[ g ]] ] = { 160, 166, 180 },
    [ 0x64 --[[ d ]] ] = { 98, 104, 120 },
    [ 0x57 --[[ W ]] ] = { 232, 234, 240 },
    [ 0x77 --[[ w ]] ] = { 176, 180, 192 },
    [ 0x61 --[[ a ]] ] = { 255, 206, 96 }
}

local satellite_rects, satellite_rect_count = compile_sprite( {
    "lPpPpPpPl.....",
    "PpPpPpPpP.....",
    "pPpPpPpPp.....",
    "....s.........",
    "....s.......W.",
    ".GGGGGGG...W..",
    ".GgggggdW.W...",
    ".GgggggdW.w...",
    ".GgggggdssWssa",
    ".GgggggdW.w...",
    ".GgggggdW.W...",
    ".ddddddd...W..",
    "....s.......W.",
    "....s.........",
    "pPpPpPpPp.....",
    "PpPpPpPpP.....",
    "lPpPpPpPl....."
}, satellite_palette )

--- The position of the satellite in the scene, the blinking light and the feed horn the waves start at.
local SATELLITE_X, SATELLITE_Y = 10, 19
local LIGHT_X, LIGHT_Y = 3, 7
local FEED_X, FEED_Y = 13, 8

--- The moon, its center and radius in art pixels.
local MOON_X, MOON_Y, MOON_RADIUS = 104, 27, 16

---@type dreamwork.loading.Rect[]
local moon_rects

---@type integer
local moon_rect_count

---@type integer[][]
local moon_ring = {}

do

    --- From the lit side to the dark side.
    ---
    ---@type integer[][]
    local tones = {
        { 236, 232, 216 },
        { 208, 204, 188 },
        { 172, 168, 154 },
        { 126, 123, 114 },
        { 88, 86, 82 }
    }

    --- `dx, dy, radius` relative to the center.
    ---
    ---@type integer[][]
    local craters = {
        { -6, -6, 3 },
        { 4, 3, 4 },
        { -7, 7, 2 },
        { 7, -9, 2 },
        { -1, 10, 2 },
        { 10, 4, 2 }
    }

    ---@type string[]
    local rows = {}

    -- the tones are encoded as digits, so the moon is compiled like a sprite
    ---@type table<integer, integer[]>
    local palette = {}

    for index = 1, #tones, 1 do
        palette[ 0x30 + index ] = tones[ index ]
    end

    local diameter = MOON_RADIUS * 2 + 1

    for y = 0, diameter - 1, 1 do
        local dy = y - MOON_RADIUS

        ---@type string[]
        local chars = {}

        for x = 0, diameter - 1, 1 do
            local dx = x - MOON_RADIUS
            local distance = math_sqrt( dx * dx + dy * dy )

            if distance > MOON_RADIUS + 0.35 then
                chars[ x + 1 ] = "."
            else
                -- lit from the upper left, where the satellite is
                local light = (-dx * 0.75 - dy * 0.45) / MOON_RADIUS

                local tone
                if light > 0.45 then
                    tone = 1
                elseif light > 0 then
                    tone = 2
                elseif light > -0.45 then
                    tone = 3
                else
                    tone = 4
                end

                for crater_index = 1, #craters, 1 do
                    local crater = craters[ crater_index ]
                    local cx, cy = dx - crater[ 1 ], dy - crater[ 2 ]
                    local crater_distance = math_sqrt( cx * cx + cy * cy )

                    if crater_distance <= crater[ 3 ] then
                        -- the rim away from the light catches it
                        if crater_distance > crater[ 3 ] - 1 and cx + cy > 0 then
                            tone = math_max( 1, tone - 1 )
                        else
                            tone = math_min( 5, tone + 1 )
                        end
                    end
                end

                -- the edge is a bit darker, so the disc does not look flat
                if distance > MOON_RADIUS - 1 then
                    tone = math_min( 5, tone + 1 )
                end

                chars[ x + 1 ] = tostring( tone )
            end
        end

        rows[ y + 1 ] = table_concat( chars )
    end

    moon_rects, moon_rect_count = compile_sprite( rows, palette )

    -- the glow ring around the moon while it receives
    local ring_radius = MOON_RADIUS + 3
    for y = -ring_radius - 1, ring_radius + 1, 1 do
        for x = -ring_radius - 1, ring_radius + 1, 1 do
            if math_abs( math_sqrt( x * x + y * y ) - ring_radius ) < 0.5 then
                moon_ring[ #moon_ring + 1 ] = { x, y }
            end
        end
    end

end

--- `x, y, speed, phase`, placed once with a small generator, so they never jump.
---
---@type number[][]
local stars = {}

do

    local seed = 0x5EED

    ---@return number
    local function random()
        seed = (seed * 1103515245 + 12345) % 0x80000000
        return seed / 0x80000000
    end

    for index = 1, 80, 1 do
        stars[ index ] = {
            math_floor( random() * SCENE_WIDTH ),
            math_floor( random() * SCENE_HEIGHT ),
            0.6 + random() * 2.4,
            random() * 6.28
        }
    end

end

---@class dreamwork.loading.Line
---@field text string
---@field color integer[]

local COLOR_TEXT = { 196, 204, 222 }
local COLOR_GOOD = { 132, 232, 160 }
local COLOR_BAD = { 255, 112, 112 }
local COLOR_ACCENT = { 120, 230, 255 }

--- The log, the newest line first.
---
---@type dreamwork.loading.Line[]
local lines = {}

--- `true` while packages are being received or loaded.
local is_active = false

--- When the current work started, shifted while the screen fades in again.
local began_at = 0.0

--- When the screen first appeared, `nil` while it is hidden.
---
---@type number | nil
local shown_at = nil

--- When the work finished.
local finished_at = 0.0

--- `true` while the engine hooks are attached.
local is_hooked = false

local file_count, files_done = 0, 0
local bytes_total, bytes_done = 0, 0
local load_total, load_done = 0, 0

--- The transport the files come over, `nil` until known.
---
---@type string | nil
local transport_name = nil

--- The fraction shown by the bar, it follows the real one smoothly.
local shown_fraction = 0.0
local last_frame = 0.0

---@param text string
---@param color integer[]?
local function log( text, color )
    for index = LOG_LINES, 2, -1 do
        lines[ index ] = lines[ index - 1 ]
    end

    lines[ 1 ] = { text = text, color = color or COLOR_TEXT }
end

---@param now number
---@return number alpha
local function get_alpha( now )
    local fade_in = (now - began_at - SHOW_DELAY) / FADE_TIME

    if is_active then
        if fade_in <= 0 then
            return 0
        end

        if shown_at == nil then
            shown_at = now
        end

        return math_min( 1, fade_in )
    end

    if shown_at == nil then
        return 0
    end

    local fade_out = (now - math_max( finished_at, shown_at + MIN_VISIBLE )) / FADE_TIME
    if fade_out <= 0 then
        return math_max( 0, math_min( 1, fade_in ) )
    end

    return math_max( 0, math_min( 1, fade_in, 1 - fade_out ) )
end

---@return number
local function get_fraction()
    local download_weight = bytes_total > 0 and 0.7 or 0

    local fraction = 0
    if bytes_total > 0 then
        fraction = download_weight * math_min( 1, bytes_done / bytes_total )
    end

    if load_total > 0 then
        fraction = fraction + (1 - download_weight) * (load_done / load_total)
    elseif not is_active then
        fraction = 1
    end

    return fraction
end

local font_unit = 0

---@param unit integer
local function update_fonts( unit )
    if font_unit == unit then
        return
    end

    font_unit = unit

    surface_CreateFont( "dreamwork.loading.label", {
        font = "Courier New",
        size = math_max( 14, unit * 3 ),
        weight = 700,
        antialias = true
    } )

    surface_CreateFont( "dreamwork.loading.log", {
        font = "Courier New",
        size = math_max( 12, math_floor( unit * 2.4 ) ),
        weight = 500,
        antialias = true
    } )
end

---@param rects dreamwork.loading.Rect[]
---@param count integer
---@param x integer
---@param y integer
---@param unit integer
local function draw_rects( rects, count, x, y, unit )
    for index = 1, count, 1 do
        local rect = rects[ index ]
        surface_SetDrawColor( rect[ 4 ], rect[ 5 ], rect[ 6 ], 255 )
        surface_DrawRect( x + rect[ 1 ] * unit, y + rect[ 2 ] * unit, rect[ 3 ] * unit, unit )
    end
end

---@param text string
---@param x integer
---@param y integer
---@param color integer[]
---@param alpha integer
local function draw_text( text, x, y, color, alpha )
    surface_SetTextColor( color[ 1 ], color[ 2 ], color[ 3 ], alpha )
    surface_SetTextPos( x, y )
    surface_DrawText( text )
end

---@param now number
local function draw( now )
    local width, height = window.width, window.height

    local unit = math_max( 2, math_floor( math_min( width * 0.55 / SCENE_WIDTH, height * 0.42 / SCENE_HEIGHT ) ) )
    update_fonts( unit )

    local scene_x = math_floor( (width - SCENE_WIDTH * unit) * 0.5 )
    local scene_y = math_max( unit * 2, math_floor( height * 0.44 - SCENE_HEIGHT * unit ) )

    surface_SetDrawColor( 7, 8, 16, 255 )
    surface_DrawRect( 0, 0, width, height )

    -- stars
    for index = 1, #stars, 1 do
        local star = stars[ index ]
        local brightness = 0.25 + 0.75 * math_abs( math_sin( now * star[ 3 ] + star[ 4 ] ) )
        surface_SetDrawColor( 210, 220, 255, math_floor( brightness * 200 ) )
        surface_DrawRect( scene_x + star[ 1 ] * unit, scene_y + star[ 2 ] * unit, unit, unit )
    end

    -- the moon and its glow while data arrives
    local moon_left, moon_top = scene_x + (MOON_X - MOON_RADIUS) * unit, scene_y + (MOON_Y - MOON_RADIUS) * unit

    local glow = math_floor( (0.35 + 0.35 * math_sin( now * 3 )) * 255 )
    surface_SetDrawColor( COLOR_ACCENT[ 1 ], COLOR_ACCENT[ 2 ], COLOR_ACCENT[ 3 ], glow )

    for index = 1, #moon_ring, 1 do
        local point = moon_ring[ index ]
        surface_DrawRect( scene_x + (MOON_X + point[ 1 ]) * unit, scene_y + (MOON_Y + point[ 2 ]) * unit, unit, unit )
    end

    draw_rects( moon_rects, moon_rect_count, moon_left, moon_top, unit )

    -- the satellite floats a little
    local bob = math_floor( math_sin( now * 1.6 ) + 0.5 )
    local satellite_x, satellite_y = scene_x + SATELLITE_X * unit, scene_y + (SATELLITE_Y + bob) * unit
    draw_rects( satellite_rects, satellite_rect_count, satellite_x, satellite_y, unit )

    if now % 1 < 0.5 then
        surface_SetDrawColor( 255, 72, 72, 255 )
        surface_DrawRect( satellite_x + LIGHT_X * unit, satellite_y + LIGHT_Y * unit, unit, unit )
    end

    -- waves from the feed horn to the moon
    local emitter_x, emitter_y = SATELLITE_X + FEED_X + 1, SATELLITE_Y + bob + FEED_Y
    local distance = MOON_X - MOON_RADIUS - 2 - emitter_x

    for wave = 0, 3, 1 do
        local radius = (now * 24 + wave * distance * 0.25) % distance
        if radius > 2 then
            local alpha = math_floor( 255 * math_min( 1, radius / 6 ) * (1 - radius / distance * 0.75) )
            surface_SetDrawColor( COLOR_ACCENT[ 1 ], COLOR_ACCENT[ 2 ], COLOR_ACCENT[ 3 ], alpha )

            local spread = math_min( 0.6, 6 / radius + 0.25 )
            local step = 0.8 / radius
            local last_x, last_y = nil, nil

            local angle = -spread
            while angle <= spread do
                local x = emitter_x + math_floor( math_cos( angle ) * radius + 0.5 )
                local y = emitter_y + math_floor( math_sin( angle ) * radius + 0.5 )

                if x ~= last_x or y ~= last_y then
                    surface_DrawRect( scene_x + x * unit, scene_y + y * unit, unit, unit )
                    last_x, last_y = x, y
                end

                angle = angle + step
            end
        end
    end

    -- pixels of data flying along the waves
    for packet = 0, 5, 1 do
        local offset = (now * 38 + packet * distance / 6) % distance
        local y = emitter_y + math_floor( math_sin( offset * 0.35 + packet ) * 1.5 + 0.5 )

        if packet % 2 == 0 then
            surface_SetDrawColor( 255, 236, 150, 255 )
        else
            surface_SetDrawColor( 255, 255, 255, 230 )
        end

        surface_DrawRect( scene_x + (emitter_x + offset) * unit, scene_y + y * unit, unit, unit )
    end

    -- the label and the progress bar
    local delta = now - last_frame
    last_frame = now

    shown_fraction = shown_fraction + (get_fraction() - shown_fraction) * math_min( 1, delta * 6 )

    local bar_width = SCENE_WIDTH * unit
    local label_y = scene_y + SCENE_HEIGHT * unit + unit * 2

    ---@type string
    local label

    ---@type string
    local details

    if load_total > 0 and (load_done < load_total or is_active) then
        label = "Loading packages"
        details = string_format( "%d/%d", load_done, load_total )
    elseif bytes_total > 0 and is_active then
        label = transport_name == nil and "Receiving packages" or ( "Receiving packages via " .. transport_name )
        details = string_format( "%d/%d  %s / %s", files_done, file_count, cli_formatBytes( bytes_done ), cli_formatBytes( bytes_total ) )
    else
        label = is_active and "Preparing" or "Ready"
        details = ""
    end

    details = string_format( "%s  %d%%", details, math_floor( shown_fraction * 100 + 0.5 ) )

    surface_SetFont( "dreamwork.loading.label" )
    local _, label_height = surface_GetTextSize( label )
    local details_width = surface_GetTextSize( details )

    draw_text( label, scene_x, label_y, COLOR_TEXT, 255 )
    draw_text( details, scene_x + bar_width - details_width, label_y, COLOR_ACCENT, 255 )

    local bar_y = label_y + label_height + unit
    local bar_height = unit * 5

    surface_SetDrawColor( 86, 98, 132, 255 )
    surface_DrawRect( scene_x, bar_y, bar_width, bar_height )

    surface_SetDrawColor( 12, 14, 26, 255 )
    surface_DrawRect( scene_x + unit, bar_y + unit, bar_width - unit * 2, bar_height - unit * 2 )

    local inner_width = bar_width - unit * 4
    local fill_width = math_floor( inner_width * shown_fraction / unit ) * unit

    if fill_width > 0 then
        surface_SetDrawColor( COLOR_ACCENT[ 1 ], COLOR_ACCENT[ 2 ], COLOR_ACCENT[ 3 ], 255 )
        surface_DrawRect( scene_x + unit * 2, bar_y + unit * 2, fill_width, unit )

        surface_SetDrawColor( 60, 150, 200, 255 )
        surface_DrawRect( scene_x + unit * 2, bar_y + unit * 3, fill_width, unit )
    end

    -- the log, every next line fades more
    surface_SetFont( "dreamwork.loading.log" )

    local line_y = bar_y + bar_height + unit * 2

    for index = 1, LOG_LINES, 1 do
        local line = lines[ index ]
        if line == nil then
            break
        end

        local alpha = math_floor( 255 * (1 - (index - 1) / LOG_LINES) )
        if alpha <= 10 then
            break
        end

        draw_text( line.text, scene_x, line_y, line.color, alpha )

        local _, text_height = surface_GetTextSize( line.text )
        line_y = line_y + text_height + math_floor( unit * 0.5 )
    end
end

local release_hooks

--- Stops rendering the game and draws the screen while it is fully visible.
---
---@return boolean | nil should_suppress
local function pre_render()
    local now = dreamwork_getUpTime()
    if get_alpha( now ) < 1 then
        return nil
    end

    render_Clear( 7, 8, 16, 255, true, true )

    cam_Start( { type = "2D" } )
    draw( now )
    cam_End2D()

    return true
end

--- Draws the screen over the game while it fades in or out.
local function draw_overlay()
    local now = dreamwork_getUpTime()

    local alpha = get_alpha( now )
    if alpha >= 1 then
        return
    end

    if alpha <= 0 then
        if not is_active and (shown_at == nil or now > finished_at) then
            -- hooks are not released while the engine walks them
            setTimeout( release_hooks, 0 )
        end

        return
    end

    surface_SetAlphaMultiplier( alpha )
    draw( now )
    surface_SetAlphaMultiplier( 1 )
end

function release_hooks()
    if is_active or not is_hooked then
        return
    end

    if get_alpha( dreamwork_getUpTime() ) > 0 then
        return
    end

    is_hooked = false
    shown_at = nil

    hook_release( "PreRender", HOOK_ID )
    hook_release( "DrawOverlay", HOOK_ID )
end

---@param _ garrysmod.Player
---@param cmd garrysmod.UserCommand
local function start_command( _, cmd )
    cmd:ClearMovement()
    cmd:ClearButtons()
    cmd:SetImpulse( 0 )
    cmd:SetMouseWheel( 0 )
end

--- Keeps the player still while the screen is active.
---
---@param is_frozen boolean
local function set_frozen( is_frozen )
    if ( loading.IsFrozen == true ) == is_frozen then
        return
    end

    loading.IsFrozen = is_frozen

    if is_frozen then
        hook_catch( "StartCommand", HOOK_ID, start_command )
    else
        hook_release( "StartCommand", HOOK_ID )
    end
end

-- the reloaded screen is not active, the player can move again
set_frozen( false )

--- [CLIENT]
---
--- Shows the screen (after a short delay), does nothing if it is already shown.
---
function loading.begin()
    if is_active then
        return
    end

    local now = dreamwork_getUpTime()

    if shown_at ~= nil then
        -- fading out, the screen comes back from where it is
        began_at = now - SHOW_DELAY - FADE_TIME * get_alpha( now )
    else
        began_at = now
        lines = {}
        file_count, files_done = 0, 0
        bytes_total, bytes_done = 0, 0
        load_total, load_done = 0, 0
        transport_name = nil
        shown_fraction = 0
    end

    is_active = true
    last_frame = now

    set_frozen( true )

    if not is_hooked then
        is_hooked = true
        hook_catch( "PreRender", HOOK_ID, pre_render )
        hook_catch( "DrawOverlay", HOOK_ID, draw_overlay )
    end
end

--- [CLIENT]
---
--- Hides the screen once it was visible long enough.
---
function loading.finish()
    if not is_active then
        return
    end

    is_active = false
    finished_at = dreamwork_getUpTime()

    set_frozen( false )
end

--- [CLIENT]
---
--- Adds the line on top of the log of the screen, `color` is `{ r, g, b }`.
---
---@type fun( text: string, color: integer[]? )
loading.log = log

--- [CLIENT]
---
--- Returns `true` while the screen is visible.
---
---@return boolean is_visible
---@nodiscard
function loading.isVisible()
    return is_hooked and get_alpha( dreamwork_getUpTime() ) > 0
end

---@param entries dreamwork.transport.ManifestEntry[]
---@param count integer
---@param total integer
---@param name string?
local function on_receiving( entries, count, total, name )
    loading.begin()

    file_count, files_done = file_count + count, files_done
    bytes_total = bytes_total + total
    transport_name = name

    if name == nil then
        log( string_format( "Receiving %d file(s), %s", count, cli_formatBytes( total ) ), COLOR_ACCENT )
    else
        log( string_format( "Receiving %d file(s), %s via %s", count, cli_formatBytes( total ), name ), COLOR_ACCENT )
    end

    for index = 1, math_min( count, 3 ), 1 do
        log( "  " .. entries[ index ].name )
    end
end

---@param done integer
---@param total integer
local function on_progress( done, total )
    if is_active and total > 0 then
        bytes_done = (bytes_total - total) + done
    end
end

---@param entry dreamwork.transport.ManifestEntry
---@param method string
---@param success boolean
local function on_received( entry, method, success )
    if not is_active then
        return
    end

    files_done = files_done + 1

    -- segments that fall back to the network change the transport
    if transport_name ~= method then
        transport_name = method
        log( "Switched to " .. method, COLOR_ACCENT )
    end

    if success then
        log( string_format( "Received %s  %s  %s", entry.name, cli_formatBytes( entry.size ), method ), COLOR_GOOD )
    else
        log( string_format( "Lost %s", entry.name ), COLOR_BAD )
    end
end

---@param count integer
local function on_synchronizing( count )
    if count == 0 then
        return
    end

    loading.begin()

    load_total = load_total + count
end

---@param package dreamwork.Package
local function on_package_loading( package )
    if is_active then
        log( "Loading " .. package.id )
    end
end

---@param package dreamwork.Package
local function on_package_loaded( package )
    if is_active then
        load_done = math_min( load_total, load_done + 1 )
        log( "Loaded " .. package.id, COLOR_GOOD )
    end
end

---@param package dreamwork.Package
---@param error_object dreamwork.std.Error
local function on_package_failed( package, error_object )
    if is_active then
        load_done = math_min( load_total, load_done + 1 )
        log( string_format( "%s failed: %s", package.id, tostring( error_object.message ) ), COLOR_BAD )
    end
end

local function on_synchronized()
    if is_active then
        load_done = load_total
        log( "Ready", COLOR_ACCENT )
        loading.finish()
    end
end

-- the handlers of the previous instance are replaced, the events outlive reloads
do

    ---@type table<dreamwork.std.Event, function>
    local handlers = {
        [ transport.Receiving ] = on_receiving,
        [ transport.Progress ] = on_progress,
        [ transport.Received ] = on_received,
        [ loader.Synchronizing ] = on_synchronizing,
        [ loader.PackageLoading ] = on_package_loading,
        [ loader.PackageLoaded ] = on_package_loaded,
        [ loader.PackageFailed ] = on_package_failed,
        [ loader.Synchronized ] = on_synchronized
    }

    ---@type table<dreamwork.std.Event, function> | nil
    local previous = loading.Handlers
    if previous ~= nil then
        for event, handler in raw_pairs( previous ) do
            event:detach( handler )
        end
    end

    loading.Handlers = handlers

    for event, handler in raw_pairs( handlers ) do
        event:attach( handler )
    end

end

--- [CLIENT]
---
--- Shows the screen with made-up progress for the duration, to see how it looks.
---
---@param duration number? The duration in seconds, `6` by default.
function loading.preview( duration )
    duration = duration or 6

    local names = { "my_lib@1.0.0", "ui_kit@0.4.2", "net_tools@2.1.0" }

    ---@type dreamwork.transport.ManifestEntry[]
    local entries = {}
    local total = 0

    for index = 1, #names, 1 do
        local size = 40000 * index
        entries[ index ] = { name = names[ index ], hash = "", size = size }
        total = total + size
    end

    on_receiving( entries, #entries, total, "http" )

    local half = duration * 0.6

    for index = 1, #entries, 1 do
        setTimeout( function()
            on_progress( math_floor( total * index / #entries ), total )
            on_received( entries[ index ], index == #entries and "network" or "http", true )
        end, half * index / #entries )
    end

    setTimeout( function()
        on_synchronizing( #names )
    end, half )

    for index = 1, #names, 1 do
        local step = half + (duration - half) * (index - 0.5) / #names

        setTimeout( function()
            log( "Loading " .. names[ index ] )
        end, step - 0.2 )

        setTimeout( function()
            load_done = math_min( load_total, load_done + 1 )
            log( "Loaded " .. names[ index ], COLOR_GOOD )
        end, step )
    end

    setTimeout( on_synchronized, duration )
end
