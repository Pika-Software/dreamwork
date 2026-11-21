---@class dreamwork.std
local std = dreamwork.std

local math = std.math
local math_min = math.min
local math_max = math.max
local math_floor = math.floor
local math_clamp = math.clamp

local string = std.string
local string_rep = string.rep
local string_sub = string.sub
local string_byte = string.byte
local string_find = string.find
local string_format = string.format

local table = std.table
local table_concat = table.concat

local unicode = std.unicode
local unicode_wrap = unicode.wrap
local unicode_displayWidth = unicode.displayWidth

local raw = std.raw
local raw_tostring = raw.tostring

local server = std.server

local error = std.error
local isString = std.isString

---@class dreamwork.std.ascii
local ascii = std.ascii


--- [SHARED AND MENU]
---
--- A table of glyph name to symbol.
---
--- Names are grouped by prefix. A `box_` symbol is one column wide: `box_horizontal`
--- is repeated along rules, `box_vertical` frames each text row, and `box_bullet`
--- marks a row of `art.keyValues`. A `tree_` string is one 4-column prefix of an
--- `art.tree` level.
---
---@class dreamwork.std.ascii.art.Scheme
---@field box_top_left string Top-left corner.
---@field box_top_right string Top-right corner.
---@field box_bottom_left string Bottom-left corner.
---@field box_bottom_right string Bottom-right corner.
---@field box_left_tee string Left end of a horizontal divider (`├`).
---@field box_right_tee string Right end of a horizontal divider (`┤`).
---@field box_top_tee string Top end of a vertical divider (`┬`).
---@field box_bottom_tee string Bottom end of a vertical divider (`┴`).
---@field box_cross string Crossing of a horizontal and a vertical divider (`┼`).
---@field box_horizontal string Horizontal stroke, repeated along a rule.
---@field box_vertical string Vertical stroke.
---@field box_bullet string Marker placed in front of an `art.keyValues` row.
---@field tree_branch string Prefix of a node that has a sibling after it (`├── `).
---@field tree_last string Prefix of the last node under its parent (`└── `).
---@field tree_pipe string Continuation where a later sibling follows (`│   `).
---@field tree_blank string Continuation where the parent was the last sibling. Four spaces.

--- [SHARED AND MENU]
---
--- One rendered line of a figure.
---
--- `text` is the whole line, scheme symbols included. `content` is set on a `text`
--- line and is `nil` on a rule: the original row for `art.box`, `art.frame` and
--- `art.keyValues` (padding excluded), or the padded cells joined by the inner
--- strokes for `art.grid`. `width` is how many columns that inner area is padded to.
--- A rendered text line is `box_vertical`, a space, `width` columns, a space, `box_vertical`.
---
---@class dreamwork.std.ascii.art.Line
---@field kind dreamwork.std.ascii.art.Kind Which part of the figure this line is.
---@field text string The whole line, scheme symbols included.
---@field content string? Inner text of a `text` line. `nil` on a rule.
---@field width integer Columns the inner text is padded to.

--- Which part of a figure a line is.
---
---@alias dreamwork.std.ascii.art.Kind
---| "top" # Top rule.
---| "divider" # Rule between sections, or under a grid heading.
---| "bottom" # Bottom rule.
---| "text" # A content row.

--- Which rule `art.rule` draws. `top` and `bottom` use the corners, `divider` uses the side tees.
---
---@alias dreamwork.std.ascii.art.Edge
---| "top" # Top rule, corner glyphs.
---| "divider" # Middle rule, side tees.
---| "bottom" # Bottom rule, corner glyphs.

--- Where `art.pad` adds the extra columns. A string that is already wider than the width is returned unchanged.
---
---@alias dreamwork.std.ascii.art.Alignment
---| "left" # Pad on the right. Default.
---| "center" # Pad both sides. An odd leftover column goes to the right.
---| "right" # Pad on the left.

--- [SHARED AND MENU]
---
--- A key and a value, drawn as one row of `art.keyValues`.
---
--- The key is drawn with a trailing `:`. The value is converted with `raw.tostring`.
---
---@class dreamwork.std.ascii.art.KeyValue
---@field [1] string key Label, before the colon.
---@field [2] any value Converted with `raw.tostring`.

--- [SHARED AND MENU]
---
--- Text figures drawn with ASCII or box-drawing characters.
---
--- Schemes, framed sections, labeled rows, grids, bars and trees. Width is measured in
--- terminal columns (`unicode.displayWidth`), so a wide character keeps the
--- frame aligned.
---
--- Presets live in `art.schemes`: `light`, `heavy`, `double`, `rounded` and `ascii`.
--- `art.scheme` is the one used when a call omits its scheme: `art.schemes.light` on a
--- dedicated server terminal, `art.schemes.ascii` everywhere else. The in-game console draws
--- box-drawing characters wider than the text, so the ASCII scheme is what lines up there.
--- Assigning `art.scheme` changes that default for later calls. `art.tree` reads the
--- `tree_` prefixes from the same scheme.
---
--- ```lua
--- print( ascii.art.bar( 0.3, 10, true ) ) -- ###-------
--- ```
---
---@class dreamwork.std.ascii.art
---@field schemes dreamwork.std.ascii.art.Schemes Preset schemes, keyed by name.
---@field scheme dreamwork.std.ascii.art.Scheme Scheme used when a call omits one.
local art = {}
ascii.art = art

--- [SHARED AND MENU]
---
--- Preset schemes, keyed by name.
---
---@class dreamwork.std.ascii.art.Schemes
---@field light dreamwork.std.ascii.art.Scheme Light box-drawing (`┌─┐`).
---@field heavy dreamwork.std.ascii.art.Scheme Heavy box-drawing (`┏━┓`).
---@field double dreamwork.std.ascii.art.Scheme Double box-drawing (`╔═╗`).
---@field rounded dreamwork.std.ascii.art.Scheme Rounded corners (`╭─╮`), light strokes otherwise.
---@field ascii dreamwork.std.ascii.art.Scheme ASCII (`+-+`). Lines up in the in-game console.

--- [SHARED AND MENU]
---
--- Preset schemes, keyed by name.
---
---@type dreamwork.std.ascii.art.Schemes
art.schemes = {
    --- ```
    --- ┌───┐
    --- │   │
    --- ├───┤
    --- └───┘
    --- ```
    light = {
        box_top_left = "┌",
        box_top_right = "┐",
        box_bottom_left = "└",
        box_bottom_right = "┘",
        box_left_tee = "├",
        box_right_tee = "┤",
        box_top_tee = "┬",
        box_bottom_tee = "┴",
        box_cross = "┼",
        box_horizontal = "─",
        box_vertical = "│",
        box_bullet = "•",
        tree_branch = "├── ",
        tree_last = "└── ",
        tree_pipe = "│   ",
        tree_blank = "    "
    },

    --- ```
    --- ┏━━━┓
    --- ┃   ┃
    --- ┣━━━┫
    --- ┗━━━┛
    --- ```
    heavy = {
        box_top_left = "┏",
        box_top_right = "┓",
        box_bottom_left = "┗",
        box_bottom_right = "┛",
        box_left_tee = "┣",
        box_right_tee = "┫",
        box_top_tee = "┳",
        box_bottom_tee = "┻",
        box_cross = "╋",
        box_horizontal = "━",
        box_vertical = "┃",
        box_bullet = "•",
        tree_branch = "┣━━ ",
        tree_last = "┗━━ ",
        tree_pipe = "┃   ",
        tree_blank = "    "
    },

    --- ```
    --- ╔═══╗
    --- ║   ║
    --- ╠═══╣
    --- ╚═══╝
    --- ```
    double = {
        box_top_left = "╔",
        box_top_right = "╗",
        box_bottom_left = "╚",
        box_bottom_right = "╝",
        box_left_tee = "╠",
        box_right_tee = "╣",
        box_top_tee = "╦",
        box_bottom_tee = "╩",
        box_cross = "╬",
        box_horizontal = "═",
        box_vertical = "║",
        box_bullet = "•",
        tree_branch = "╠══ ",
        tree_last = "╚══ ",
        tree_pipe = "║   ",
        tree_blank = "    "
    },

    --- Corners are arcs, the other strokes are the light set.
    ---
    --- ```
    --- ╭───╮
    --- │   │
    --- ├───┤
    --- ╰───╯
    --- ```
    rounded = {
        box_top_left = "╭",
        box_top_right = "╮",
        box_bottom_left = "╰",
        box_bottom_right = "╯",
        box_left_tee = "├",
        box_right_tee = "┤",
        box_top_tee = "┬",
        box_bottom_tee = "┴",
        box_cross = "┼",
        box_horizontal = "─",
        box_vertical = "│",
        box_bullet = "•",
        tree_branch = "├── ",
        tree_last = "└── ",
        tree_pipe = "│   ",
        tree_blank = "    "
    },

    --- Lines up in the in-game console.
    ---
    --- ```
    --- +-------+
    --- | hello |
    --- +-------+
    --- | world |
    --- +-------+
    --- ```
    ascii = {
        box_top_left = "+",
        box_top_right = "+",
        box_bottom_left = "+",
        box_bottom_right = "+",
        box_left_tee = "+",
        box_right_tee = "+",
        box_top_tee = "+",
        box_bottom_tee = "+",
        box_cross = "+",
        box_horizontal = "-",
        box_vertical = "|",
        box_bullet = "*",
        tree_branch = "|-- ",
        tree_last = "`-- ",
        tree_pipe = "|   ",
        tree_blank = "    "
    }
}

--- [SHARED AND MENU]
---
--- Scheme used when a call omits one.
---
--- `art.schemes.light` on a dedicated server terminal. `art.schemes.ascii` on a listen server and
--- in the in-game console, where box-drawing characters are wider than the text.
--- Replacing this field changes the default for later calls.
---
---@type dreamwork.std.ascii.art.Scheme
art.scheme = (std.LUA_SERVER and server.dedicated) and art.schemes.light or art.schemes.ascii

--- [SHARED AND MENU]
---
--- One node visited by `art.tree`.
---
--- `prefix` is the branches before the node, including the two spaces every root
--- line starts with. `depth` is the number of levels above the node, `0` for a root.
--- `mark` is the second return of the children callback. The children are not
--- walked when it is set.
---
---@class dreamwork.std.ascii.art.TreeLine
---@field prefix string Branches before the node.
---@field depth integer Levels above this node. `0` for a root.
---@field node any The node from `roots` or from the children callback.
---@field mark string? Second return of the children callback. The children are not walked when this is set.

--- Pads `text` with spaces out to `width` columns.
---
--- A string that is already at least `width` columns wide is returned unchanged,
--- so a fixed width never cuts a row.
---
---@param text string
---@param width integer
---@param alignment dreamwork.std.ascii.art.Alignment
---@return string padded
---@nodiscard
local function align( text, width, alignment )
    local missing = width - unicode_displayWidth( text, nil, nil, true )
    if missing <= 0 then
        return text
    end

    if alignment == "right" then
        return string_rep( " ", missing ) .. text
    elseif alignment == "center" then
        local left = math_floor( missing * 0.5 )
        return string_rep( " ", left ) .. text .. string_rep( " ", missing - left )
    end

    return text .. string_rep( " ", missing )
end

--- Splits `text` on `\n`. A `\r` before a `\n` is dropped. A trailing newline yields a final empty line.
---
---@param text string
---@return string[] lines
---@nodiscard
local function split_lines( text )
    ---@type string[]
    local lines = {}

    local count = 0
    local length = #text
    local start_index = 1

    while start_index <= length do
        local newline = string_find( text, "\n", start_index, true )
        if newline == nil then
            count = count + 1
            lines[ count ] = string_sub( text, start_index, length )
            return lines
        end

        local end_index = newline - 1
        if end_index >= start_index and string_byte( text, end_index, end_index ) == 0x0D then
            end_index = end_index - 1
        end

        count = count + 1
        lines[ count ] = string_sub( text, start_index, end_index )
        start_index = newline + 1
    end

    count = count + 1
    lines[ count ] = ""
    return lines
end

--- One rule, corners or side tees included. The stroke between them is `width + 2` columns,
--- the two extra columns being the spaces that sit inside a text row.
---
---@param scheme dreamwork.std.ascii.art.Scheme
---@param width integer
---@param edge dreamwork.std.ascii.art.Edge
---@return string rule
---@nodiscard
local function rule_text( scheme, width, edge )
    local span = string_rep( scheme.box_horizontal, width + 2 )

    if edge == "top" then
        return scheme.box_top_left .. span .. scheme.box_top_right
    elseif edge == "bottom" then
        return scheme.box_bottom_left .. span .. scheme.box_bottom_right
    end

    return scheme.box_left_tee .. span .. scheme.box_right_tee
end

--- One content row, vertical strokes and the inner spaces included.
---
---@param scheme dreamwork.std.ascii.art.Scheme
---@param content string
---@param width integer
---@return string row
---@nodiscard
local function row_text( scheme, content, width )
    return scheme.box_vertical .. " " .. align( content, width, "left" ) .. " " .. scheme.box_vertical
end

---@param kind dreamwork.std.ascii.art.Kind
---@param text string
---@param content string | nil
---@param width integer
---@return dreamwork.std.ascii.art.Line
---@nodiscard
local function new_line( kind, text, content, width )
    return {
        kind = kind,
        text = text,
        content = content,
        width = width
    }
end

---@param lines dreamwork.std.ascii.art.Line[]
---@param kind dreamwork.std.ascii.art.Kind
---@param text string
---@param content string | nil
---@param width integer
local function push_line( lines, kind, text, content, width )
    lines[ #lines + 1 ] = new_line( kind, text, content, width )
end

---@param scheme dreamwork.std.ascii.art.Scheme
---@param column_widths integer[]
---@param left string
---@param joint string
---@param right string
---@return string rule
---@nodiscard
local function grid_rule( scheme, column_widths, left, joint, right )
    ---@type string[]
    local parts = {}
    local part_count = 1
    parts[ 1 ] = left

    for column_index = 1, #column_widths, 1 do
        if column_index ~= 1 then
            part_count = part_count + 1
            parts[ part_count ] = joint
        end

        part_count = part_count + 1
        parts[ part_count ] = string_rep( scheme.box_horizontal, column_widths[ column_index ] + 2 )
    end

    part_count = part_count + 1
    parts[ part_count ] = right

    return table_concat( parts, "", 1, part_count )
end

---@param scheme dreamwork.std.ascii.art.Scheme
---@param column_widths integer[]
---@param cells string[]
---@return string text
---@return string content
---@nodiscard
local function grid_row( scheme, column_widths, cells )
    ---@type string[]
    local parts = {}
    local part_count = 0

    for column_index = 1, #column_widths, 1 do
        if column_index ~= 1 then
            part_count = part_count + 1
            parts[ part_count ] = " " .. scheme.box_vertical .. " "
        end

        part_count = part_count + 1
        parts[ part_count ] = align( cells[ column_index ] or "", column_widths[ column_index ], "left" )
    end

    local content = table_concat( parts, "", 1, part_count )
    return scheme.box_vertical .. " " .. content .. " " .. scheme.box_vertical, content
end

--- Widest row in `sections`, in columns.
---
---@param sections string[][]
---@return integer width
---@nodiscard
local function measure_sections( sections )
    local width = 0

    for section_index = 1, #sections, 1 do
        local section = sections[ section_index ]

        for line_index = 1, #section, 1 do
            width = math_max( width, unicode_displayWidth( section[ line_index ], nil, nil, true ) )
        end
    end

    return width
end

--- [SHARED AND MENU]
---
--- Returns the number of terminal columns `text` takes.
---
--- This is `unicode.displayWidth` with invalid UTF-8 counted as U+FFFD, which is
--- the same measure `art.pad`, `art.box` and `art.grid` use.
---
---@see dreamwork.std.unicode.displayWidth
---
---@param text string The text to measure.
---@return integer width The width of `text` in columns.
---@nodiscard
function art.width( text )
    return unicode_displayWidth( text, nil, nil, true )
end

--- [SHARED AND MENU]
---
--- Pads `text` with spaces until it is `width` columns wide.
---
--- `alignment` picks the side that grows. `"center"` splits the gap in half and
--- puts a leftover column on the right. A string that is already wider than `width`
--- is returned unchanged.
---
---@param text string The text to pad.
---@param width integer The target width, in columns.
---@param alignment dreamwork.std.ascii.art.Alignment? The side to pad. `"left"` when `nil`.
---@return string padded `text` padded out to `width` columns, or `text` when it is already wider.
---@nodiscard
function art.pad( text, width, alignment )
    if alignment == nil or alignment == "left" then
        return align( text, width, "left" )
    elseif alignment == "right" or alignment == "center" then
        return align( text, width, alignment )
    end

    error( string_format( "unknown alignment '%s'", raw_tostring( alignment ) ), 2 )
end

--- [SHARED AND MENU]
---
--- Splits `text` into lines no wider than `width` columns.
---
--- Existing newlines are kept: each line is wrapped on its own. A `\r` before a
--- `\n` is dropped, and a trailing newline yields a final empty line. Breaking
--- follows `unicode.wrap`: on the last ASCII space that fits, or mid-word when a
--- single word is wider than `width`. A wide character that does not fit on its
--- own can still make a line longer than `width`.
---
--- When `width` is `nil` or less than `1`, the text is only split on newlines.
---
---@see dreamwork.std.unicode.wrap
---
---@param text string The text to wrap.
---@param width integer? The maximum width of a line, in columns.
---@return string[] lines The wrapped lines, in order.
---@nodiscard
function art.wrap( text, width )
    local rows = split_lines( text )
    if width == nil or width <= 0 then
        return rows
    end

    ---@type string[]
    local wrapped = {}
    local count = 0

    for index = 1, #rows, 1 do
        local parts = split_lines( unicode_wrap( rows[ index ], width, nil, nil, true ) )

        for part_index = 1, #parts, 1 do
            count = count + 1
            wrapped[ count ] = parts[ part_index ]
        end
    end

    return wrapped
end

--- [SHARED AND MENU]
---
--- Builds one horizontal rule.
---
--- `width` is the inner width, the same number passed to `art.box`. The stroke
--- between the end glyphs is two columns wider than that, matching the spaces
--- inside a text row.
---
--- ```
--- ┌─────────┐  -- edge "top",     width 7
--- ├─────────┤  -- edge "divider", width 7
--- └─────────┘  -- edge "bottom",  width 7
--- ```
---
---@see dreamwork.std.ascii.art.row
---
---@param width integer Inner width in columns, `0` or more.
---@param edge dreamwork.std.ascii.art.Edge Which rule to draw.
---@param scheme dreamwork.std.ascii.art.Scheme? Symbols to use. `art.scheme` when `nil`.
---@return string rule The rule, end glyphs included.
---@nodiscard
function art.rule( width, edge, scheme )
    if edge == "top" or edge == "divider" or edge == "bottom" then
        if scheme == nil then
            scheme = art.scheme
        end

        return rule_text( scheme, width, edge )
    end

    error( string_format( "unknown edge '%s'", raw_tostring( edge ) ), 2 )
end

--- [SHARED AND MENU]
---
--- Builds one text row.
---
--- The row is a vertical stroke, a space, `content` padded on the right out to
--- `width` columns, a space, and a vertical stroke. `content` wider than `width`
--- is not cut, so the row sticks out past a rule of the same width.
---
--- ```
--- │ hello   │  -- content "hello", width 7
--- ```
---
---@see dreamwork.std.ascii.art.rule
---
---@param content string The inner text, with no scheme symbols.
---@param width integer Inner width in columns, `0` or more.
---@param scheme dreamwork.std.ascii.art.Scheme? Symbols to use. `art.scheme` when `nil`.
---@return string row The row, vertical strokes included.
---@nodiscard
function art.row( content, width, scheme )
    if scheme == nil then
        scheme = art.scheme
    end

    return row_text( scheme, content, width )
end

--- [SHARED AND MENU]
---
--- Frames sections of rows.
---
--- Each section is a list of rows already split on newlines. A divider is drawn
--- between sections. `width` is the inner width; when it is `nil` the box is as
--- wide as the longest row. Short rows are padded on the right. A row wider than
--- `width` is kept whole, and that line sticks out past the rules.
---
--- ```
--- ┌───────────────┐
--- │ section one   │
--- ├───────────────┤
--- │ section two   │
--- └───────────────┘
--- ```
---
---@see dreamwork.std.ascii.art.frame
---@see dreamwork.std.ascii.art.keyValues
---@see dreamwork.std.ascii.art.grid
---
---@param sections string[][] Rows grouped into sections. A section is one list of inner texts.
---@param width integer? Inner width in columns. The widest row when `nil`.
---@param scheme dreamwork.std.ascii.art.Scheme? Symbols to use. `art.scheme` when `nil`.
---@return dreamwork.std.ascii.art.Line[] lines The top rule, the rows, a divider between sections, and the bottom rule.
---@nodiscard
function art.box( sections, width, scheme )
    if scheme == nil then
        scheme = art.scheme
    end

    ---@type integer
    local inner_width

    if width == nil then
        inner_width = measure_sections( sections )
    else
        inner_width = width
    end

    ---@type dreamwork.std.ascii.art.Line[]
    local lines = {}

    push_line( lines, "top", rule_text( scheme, inner_width, "top" ), nil, inner_width )

    for section_index = 1, #sections, 1 do
        if section_index ~= 1 then
            push_line( lines, "divider", rule_text( scheme, inner_width, "divider" ), nil, inner_width )
        end

        local section = sections[ section_index ]
        for line_index = 1, #section, 1 do
            local content = section[ line_index ]
            push_line( lines, "text", row_text( scheme, content, inner_width ), content, inner_width )
        end
    end

    push_line( lines, "bottom", rule_text( scheme, inner_width, "bottom" ), nil, inner_width )

    return lines
end

--- [SHARED AND MENU]
---
--- Frames one block of text.
---
--- `lines` is either a list of rows or one string split with `art.wrap` rules for
--- newlines (no width limit, so only newline splitting). The result is a box with
--- a single section and no divider.
---
--- ```
--- ┌──────────┐
--- │ one line │
--- │ another  │
--- └──────────┘
--- ```
---
---@see dreamwork.std.ascii.art.box
---@see dreamwork.std.ascii.art.wrap
---
---@param lines string | string[] The text, or rows that are already split.
---@param width integer? Inner width in columns. The widest row when `nil`.
---@param scheme dreamwork.std.ascii.art.Scheme? Symbols to use. `art.scheme` when `nil`.
---@return dreamwork.std.ascii.art.Line[] lines The framed block.
---@nodiscard
function art.frame( lines, width, scheme )
    ---@type string[]
    local rows

    if isString( lines ) then
        ---@cast lines string
        rows = split_lines( lines )
    else
        ---@cast lines string[]
        rows = lines
    end

    return art.box( { rows }, width, scheme )
end

--- [SHARED AND MENU]
---
--- Frames labeled rows.
---
--- Each row is a key and a value. The key is drawn with a trailing `:`, padded on
--- the right out to `key_width`, then the value is padded out to `value_width`.
--- A bullet from the scheme is written in front. Sections are separated by a divider.
---
--- A key or a value that is wider than its column is not cut. The box grows to the
--- longest row when that happens, because the inner width is measured from the
--- formatted rows.
---
--- ```
--- ┌─────────────────────┐
--- │ • Lua:    5.1       │
--- │ • Realm:  client    │
--- ├─────────────────────┤
--- │ • Branch: unknown   │
--- └─────────────────────┘
--- ```
---
---@see dreamwork.std.ascii.art.box
---
---@param sections dreamwork.std.ascii.art.KeyValue[][] Labeled rows, grouped into sections.
---@param key_width integer? Columns reserved for the key and its colon. `12` when `nil`.
---@param value_width integer? Columns reserved for the value. `40` when `nil`.
---@param scheme dreamwork.std.ascii.art.Scheme? Symbols to use. `art.scheme` when `nil`.
---@return dreamwork.std.ascii.art.Line[] lines The framed rows.
---@nodiscard
function art.keyValues( sections, key_width, value_width, scheme )
    key_width = key_width or 12
    value_width = value_width or 40

    if scheme == nil then
        scheme = art.scheme
    end

    ---@type string[][]
    local formatted = {}

    for section_index = 1, #sections, 1 do
        local rows = sections[ section_index ]

        ---@type string[]
        local lines = {}

        for row_index = 1, #rows, 1 do
            local entry = rows[ row_index ]
            lines[ row_index ] = string_format(
                "%s %s%s",
                scheme.box_bullet,
                align( entry[ 1 ] .. ":", key_width, "left" ),
                align( raw_tostring( entry[ 2 ] ), value_width, "left" )
            )
        end

        formatted[ section_index ] = lines
    end

    return art.box( formatted, nil, scheme )
end

--- [SHARED AND MENU]
---
--- Frames a grid of cells.
---
--- Each row is a list of cell strings. `widths` gives the column widths in
--- columns; a missing width, or a `nil` `widths`, is the widest cell in that
--- column. Cells are padded on the right. A cell wider than its column is not
--- cut, and that row sticks out past the rules.
---
--- Vertical strokes are drawn between columns. When `heading` is `true` and there
--- is more than one row, a divider is drawn under the first row, with a cross
--- where it meets a vertical stroke.
---
--- ```
--- ┌──────┬────────┐
--- │ Lua  │ Realm  │
--- ├──────┼────────┤
--- │ 5.1  │ client │
--- └──────┴────────┘
--- ```
---
---@see dreamwork.std.ascii.art.box
---
---@param rows string[][] Cells, one list per row. A missing cell is drawn empty.
---@param widths integer[]? Column widths. Measured from the cells when `nil`, and for each column whose width is `nil`.
---@param scheme dreamwork.std.ascii.art.Scheme? Symbols to use. `art.scheme` when `nil`.
---@param heading boolean? Draw a divider under the first row when a second row exists. `false` when `nil`.
---@return dreamwork.std.ascii.art.Line[] lines The framed grid.
---@nodiscard
function art.grid( rows, widths, scheme, heading )
    if scheme == nil then
        scheme = art.scheme
    end

    local row_count = #rows
    local column_count = 0

    if widths ~= nil then
        column_count = #widths
    end

    for row_index = 1, row_count, 1 do
        column_count = math_max( column_count, #rows[ row_index ] )
    end

    if column_count == 0 then
        return art.box( {}, 0, scheme )
    end

    ---@type integer[]
    local column_widths = {}

    for column_index = 1, column_count, 1 do
        local given = nil
        if widths ~= nil then
            given = widths[ column_index ]
        end

        if given == nil then
            local measured = 0

            for row_index = 1, row_count, 1 do
                local cell = rows[ row_index ][ column_index ]
                if cell ~= nil then
                    measured = math_max( measured, unicode_displayWidth( cell, nil, nil, true ) )
                end
            end

            column_widths[ column_index ] = measured
        else
            column_widths[ column_index ] = given
        end
    end

    local inner_width = 0
    local vertical_width = unicode_displayWidth( scheme.box_vertical, nil, nil, true )

    for column_index = 1, column_count, 1 do
        if column_index ~= 1 then
            inner_width = inner_width + 2 + vertical_width
        end

        inner_width = inner_width + column_widths[ column_index ]
    end

    ---@type dreamwork.std.ascii.art.Line[]
    local lines = {}

    push_line( lines, "top", grid_rule( scheme, column_widths, scheme.box_top_left, scheme.box_top_tee, scheme.box_top_right ), nil, inner_width )

    for row_index = 1, row_count, 1 do
        if heading == true and row_index == 2 then
            push_line( lines, "divider", grid_rule( scheme, column_widths, scheme.box_left_tee, scheme.box_cross, scheme.box_right_tee ), nil, inner_width )
        end

        local text, content = grid_row( scheme, column_widths, rows[ row_index ] )
        push_line( lines, "text", text, content, inner_width )
    end

    push_line( lines, "bottom", grid_rule( scheme, column_widths, scheme.box_bottom_left, scheme.box_bottom_tee, scheme.box_bottom_right ), nil, inner_width )

    return lines
end

---@generic T
---@param lines dreamwork.std.ascii.art.TreeLine[]
---@param node T
---@param children fun( node: T, path: table<T, boolean>, seen: table<T, boolean> ): T[] | nil, string | nil
---@param scheme dreamwork.std.ascii.art.Scheme
---@param indent string Prefix of the lines below `node`.
---@param branch string Prefix of the `node` line.
---@param depth integer Levels above `node`.
---@param path table<T, boolean>
---@param seen table<T, boolean>
local function walk_tree( lines, node, children, scheme, indent, branch, depth, path, seen )
    local kids, mark = children( node, path, seen )

    lines[ #lines + 1 ] = {
        prefix = branch,
        depth = depth,
        node = node,
        mark = mark
    }

    if kids == nil or mark ~= nil then
        return
    end

    path[ node ] = true
    depth = depth + 1

    local count = #kids

    for index = 1, count, 1 do
        if index == count then
            walk_tree( lines, kids[ index ], children, scheme, indent .. scheme.tree_blank, indent .. scheme.tree_last, depth, path, seen )
        else
            walk_tree( lines, kids[ index ], children, scheme, indent .. scheme.tree_pipe, indent .. scheme.tree_branch, depth, path, seen )
        end
    end

    path[ node ] = nil
end

--- [SHARED AND MENU]
---
--- Walks `roots` depth-first and returns one line per visited node.
---
--- `children` receives the node, the ancestors (`path`) and the table the
--- callback uses to record nodes (`seen`). Both tables are keyed by the node.
--- Return the child list to walk them, or `nil` and a mark to stop: the mark is
--- stored on the line and the children are not visited. An empty list is a leaf.
--- `seen` is shared by every root. `path` holds only the ancestors, so it is
--- empty when a root is visited. The node is added to `path` after `children`
--- returns and removed after its children are walked.
---
--- A root line has the prefix `"  "` and depth `0`. Each level below adds one
--- `tree_` prefix, which is 4 columns. Those two spaces are on every line, so
--- the columns that change with depth are `depth * 4`.
---
--- ```
---   root
---   ├── left
---   └── right
---       └── leaf
--- ```
---
---@generic T
---@param roots T[] Nodes drawn at depth `0`, in order.
---@param children fun( node: T, path: table<T, boolean>, seen: table<T, boolean> ): T[] | nil, string | nil Returns the children to walk, or `nil` and a mark to stop.
---@param scheme dreamwork.std.ascii.art.Scheme? Symbols to use. `art.scheme` when `nil`.
---@return dreamwork.std.ascii.art.TreeLine[] lines One line per visited node, parents before their children.
---@nodiscard
function art.tree( roots, children, scheme )
    if scheme == nil then
        scheme = art.scheme
    end

    ---@type dreamwork.std.ascii.art.TreeLine[]
    local lines = {}

    local path, seen = {}, {}
    local count = #roots

    for index = 1, count, 1 do
        walk_tree( lines, roots[ index ], children, scheme, "  ", "  ", 0, path, seen )
    end

    return lines
end

-- One eighth of a cell, from 1/8 to 7/8. A full cell is U+2588, drawn separately.
---@type string[]
local eighths = {
    "▏",
    "▎",
    "▍",
    "▌",
    "▋",
    "▊",
    "▉"
}

--- [SHARED AND MENU]
---
--- Draws a horizontal bar `width` columns long, filled in proportion to `ratio`.
---
--- `ratio` is clamped to `0`..`1`. The filled length is `ratio * width`, rounded
--- to the nearest column. With the unicode bar the remainder of a column is
--- rounded to the nearest eighth (`▏ ▎ ▍ ▌ ▋ ▊ ▉ █`), and the empty part is `░`.
--- The ASCII bar uses `#` for a filled column and `-` for an empty one.
---
--- `ascii` defaults to `true` when `art.scheme` is `art.schemes.ascii`.
--- A `width` of `0` or less returns an empty string.
---
--- ```
--- ███░░░░░░░  -- ratio 0.3, width 10
--- ###-------  -- ratio 0.3, width 10, ascii
--- ```
---
---@param ratio number Share of the bar to fill, from `0` to `1`.
---@param width integer Length of the bar, in columns.
---@param force_ascii boolean? Use `#` and `-`. Unicode block characters when `nil` and `art.scheme` is not `art.schemes.ascii`.
---@return string bar The bar, `width` columns long, or `""` when `width` is `0` or less.
---@nodiscard
function art.bar( ratio, width, force_ascii )
    if width <= 0 then
        return ""
    end

    if force_ascii == nil then
        force_ascii = art.scheme == art.schemes.ascii
    end

    local steps = force_ascii and 1 or 8
    local limit = width * steps

    local units = math_min( limit, math_floor( math_clamp( ratio, 0, 1 ) * limit + 0.5 ) )

    local full = math_floor( units / steps )
    local partial = units - full * steps

    local bar = force_ascii and string_rep( "#", full ) or string_rep( "█", full )
    local filled = full

    if not force_ascii and partial ~= 0 then
        bar = bar .. eighths[ partial ]
        filled = filled + 1
    end

    local empty = width - filled
    if empty > 0 then
        return bar .. string_rep( force_ascii and "-" or "░", empty )
    end

    return bar
end

--- [SHARED AND MENU]
---
--- Joins rendered lines into one string.
---
--- Lines are separated by `\n`. There is no trailing newline. An empty list
--- returns an empty string.
---
---@param lines dreamwork.std.ascii.art.Line[] The lines, as returned by `art.box`, `art.frame`, `art.keyValues` or `art.grid`.
---@return string figure The figure as one string.
---@nodiscard
function art.render( lines )
    local line_count = #lines
    if line_count == 0 then
        return ""
    end

    ---@type string[]
    local parts = {}

    for index = 1, line_count, 1 do
        parts[ index ] = lines[ index ].text
    end

    return table_concat( parts, "\n", 1, line_count )
end
