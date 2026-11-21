---@meta _

--- [SHARED AND MENU]
---
--- A table of glyph name to symbol.
---
--- Names are grouped by prefix. A `box_` symbol is one column wide: `box_horizontal`
--- is repeated along rules, `box_vertical` frames each text row, and `box_bullet`
--- marks a row of `art.keyValues`. A `tree_` string is one 4-column prefix of an
--- `art.tree` level.
---
---@class ascii.art.Scheme
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
---@class ascii.art.Line
---@field kind ascii.art.Kind Which part of the figure this line is.
---@field text string The whole line, scheme symbols included.
---@field content string? Inner text of a `text` line. `nil` on a rule.
---@field width integer Columns the inner text is padded to.

--- Which part of a figure a line is.
---
---@alias ascii.art.Kind
---| "top" # Top rule.
---| "divider" # Rule between sections, or under a grid heading.
---| "bottom" # Bottom rule.
---| "text" # A content row.

--- Which rule `art.rule` draws. `top` and `bottom` use the corners, `divider` uses the side tees.
---
---@alias ascii.art.Edge
---| "top" # Top rule, corner glyphs.
---| "divider" # Middle rule, side tees.
---| "bottom" # Bottom rule, corner glyphs.

--- Where `art.pad` adds the extra columns. A string that is already wider than the width is returned unchanged.
---
---@alias ascii.art.Alignment
---| "left" # Pad on the right. Default.
---| "center" # Pad both sides. An odd leftover column goes to the right.
---| "right" # Pad on the left.

--- [SHARED AND MENU]
---
--- A key and a value, drawn as one row of `art.keyValues`.
---
--- The key is drawn with a trailing `:`. The value is converted with `raw.tostring`.
---
---@class ascii.art.KeyValue
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
---@class ascii.art
---@field schemes ascii.art.Schemes Preset schemes, keyed by name.
---@field scheme ascii.art.Scheme Scheme used when a call omits one.
ascii.art = {}

--- [SHARED AND MENU]
---
--- Preset schemes, keyed by name.
---
---@class ascii.art.Schemes
---@field light ascii.art.Scheme Light box-drawing (`┌─┐`).
---@field heavy ascii.art.Scheme Heavy box-drawing (`┏━┓`).
---@field double ascii.art.Scheme Double box-drawing (`╔═╗`).
---@field rounded ascii.art.Scheme Rounded corners (`╭─╮`), light strokes otherwise.
---@field ascii ascii.art.Scheme ASCII (`+-+`). Lines up in the in-game console.

--- [SHARED AND MENU]
---
--- Preset schemes, keyed by name.
---
---@type ascii.art.Schemes
ascii.art.schemes = {}

--- ```
--- ┌───┐
--- │   │
--- ├───┤
--- └───┘
--- ```
ascii.art.schemes.light = {}

ascii.art.schemes.light.box_top_left = "┌"

ascii.art.schemes.light.box_top_right = "┐"

ascii.art.schemes.light.box_bottom_left = "└"

ascii.art.schemes.light.box_bottom_right = "┘"

ascii.art.schemes.light.box_left_tee = "├"

ascii.art.schemes.light.box_right_tee = "┤"

ascii.art.schemes.light.box_top_tee = "┬"

ascii.art.schemes.light.box_bottom_tee = "┴"

ascii.art.schemes.light.box_cross = "┼"

ascii.art.schemes.light.box_horizontal = "─"

ascii.art.schemes.light.box_vertical = "│"

ascii.art.schemes.light.box_bullet = "•"

ascii.art.schemes.light.tree_branch = "├── "

ascii.art.schemes.light.tree_last = "└── "

ascii.art.schemes.light.tree_pipe = "│   "

ascii.art.schemes.light.tree_blank = "    "

--- ```
--- ┏━━━┓
--- ┃   ┃
--- ┣━━━┫
--- ┗━━━┛
--- ```
ascii.art.schemes.heavy = {}

ascii.art.schemes.heavy.box_top_left = "┏"

ascii.art.schemes.heavy.box_top_right = "┓"

ascii.art.schemes.heavy.box_bottom_left = "┗"

ascii.art.schemes.heavy.box_bottom_right = "┛"

ascii.art.schemes.heavy.box_left_tee = "┣"

ascii.art.schemes.heavy.box_right_tee = "┫"

ascii.art.schemes.heavy.box_top_tee = "┳"

ascii.art.schemes.heavy.box_bottom_tee = "┻"

ascii.art.schemes.heavy.box_cross = "╋"

ascii.art.schemes.heavy.box_horizontal = "━"

ascii.art.schemes.heavy.box_vertical = "┃"

ascii.art.schemes.heavy.box_bullet = "•"

ascii.art.schemes.heavy.tree_branch = "┣━━ "

ascii.art.schemes.heavy.tree_last = "┗━━ "

ascii.art.schemes.heavy.tree_pipe = "┃   "

ascii.art.schemes.heavy.tree_blank = "    "

--- ```
--- ╔═══╗
--- ║   ║
--- ╠═══╣
--- ╚═══╝
--- ```
ascii.art.schemes.double = {}

ascii.art.schemes.double.box_top_left = "╔"

ascii.art.schemes.double.box_top_right = "╗"

ascii.art.schemes.double.box_bottom_left = "╚"

ascii.art.schemes.double.box_bottom_right = "╝"

ascii.art.schemes.double.box_left_tee = "╠"

ascii.art.schemes.double.box_right_tee = "╣"

ascii.art.schemes.double.box_top_tee = "╦"

ascii.art.schemes.double.box_bottom_tee = "╩"

ascii.art.schemes.double.box_cross = "╬"

ascii.art.schemes.double.box_horizontal = "═"

ascii.art.schemes.double.box_vertical = "║"

ascii.art.schemes.double.box_bullet = "•"

ascii.art.schemes.double.tree_branch = "╠══ "

ascii.art.schemes.double.tree_last = "╚══ "

ascii.art.schemes.double.tree_pipe = "║   "

ascii.art.schemes.double.tree_blank = "    "

--- Corners are arcs, the other strokes are the light set.
---
--- ```
--- ╭───╮
--- │   │
--- ├───┤
--- ╰───╯
--- ```
ascii.art.schemes.rounded = {}

ascii.art.schemes.rounded.box_top_left = "╭"

ascii.art.schemes.rounded.box_top_right = "╮"

ascii.art.schemes.rounded.box_bottom_left = "╰"

ascii.art.schemes.rounded.box_bottom_right = "╯"

ascii.art.schemes.rounded.box_left_tee = "├"

ascii.art.schemes.rounded.box_right_tee = "┤"

ascii.art.schemes.rounded.box_top_tee = "┬"

ascii.art.schemes.rounded.box_bottom_tee = "┴"

ascii.art.schemes.rounded.box_cross = "┼"

ascii.art.schemes.rounded.box_horizontal = "─"

ascii.art.schemes.rounded.box_vertical = "│"

ascii.art.schemes.rounded.box_bullet = "•"

ascii.art.schemes.rounded.tree_branch = "├── "

ascii.art.schemes.rounded.tree_last = "└── "

ascii.art.schemes.rounded.tree_pipe = "│   "

ascii.art.schemes.rounded.tree_blank = "    "

--- Lines up in the in-game console.
---
--- ```
--- +-------+
--- | hello |
--- +-------+
--- | world |
--- +-------+
--- ```
ascii.art.schemes.ascii = {}

ascii.art.schemes.ascii.box_top_left = "+"

ascii.art.schemes.ascii.box_top_right = "+"

ascii.art.schemes.ascii.box_bottom_left = "+"

ascii.art.schemes.ascii.box_bottom_right = "+"

ascii.art.schemes.ascii.box_left_tee = "+"

ascii.art.schemes.ascii.box_right_tee = "+"

ascii.art.schemes.ascii.box_top_tee = "+"

ascii.art.schemes.ascii.box_bottom_tee = "+"

ascii.art.schemes.ascii.box_cross = "+"

ascii.art.schemes.ascii.box_horizontal = "-"

ascii.art.schemes.ascii.box_vertical = "|"

ascii.art.schemes.ascii.box_bullet = "*"

ascii.art.schemes.ascii.tree_branch = "|-- "

ascii.art.schemes.ascii.tree_last = "`-- "

ascii.art.schemes.ascii.tree_pipe = "|   "

ascii.art.schemes.ascii.tree_blank = "    "

--- [SHARED AND MENU]
---
--- Scheme used when a call omits one.
---
--- `art.schemes.light` on a dedicated server terminal. `art.schemes.ascii` on a listen server and
--- in the in-game console, where box-drawing characters are wider than the text.
--- Replacing this field changes the default for later calls.
---
---@type ascii.art.Scheme
ascii.art.scheme = nil

--- [SHARED AND MENU]
---
--- One node visited by `art.tree`.
---
--- `prefix` is the branches before the node, including the two spaces every root
--- line starts with. `depth` is the number of levels above the node, `0` for a root.
--- `mark` is the second return of the children callback. The children are not
--- walked when it is set.
---
---@class ascii.art.TreeLine
---@field prefix string Branches before the node.
---@field depth integer Levels above this node. `0` for a root.
---@field node any The node from `roots` or from the children callback.
---@field mark string? Second return of the children callback. The children are not walked when this is set.

--- [SHARED AND MENU]
---
--- Returns the number of terminal columns `text` takes.
---
--- This is `unicode.displayWidth` with invalid UTF-8 counted as U+FFFD, which is
--- the same measure `art.pad`, `art.box` and `art.grid` use.
---
---@see unicode.displayWidth
---
---@param text string The text to measure.
---@return integer width The width of `text` in columns.
---@nodiscard
function ascii.art.width(text) end

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
---@param alignment ascii.art.Alignment? The side to pad. `"left"` when `nil`.
---@return string padded `text` padded out to `width` columns, or `text` when it is already wider.
---@nodiscard
function ascii.art.pad(text, width, alignment) end

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
---@see unicode.wrap
---
---@param text string The text to wrap.
---@param width integer? The maximum width of a line, in columns.
---@return string[] lines The wrapped lines, in order.
---@nodiscard
function ascii.art.wrap(text, width) end

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
---@see ascii.art.row
---
---@param width integer Inner width in columns, `0` or more.
---@param edge ascii.art.Edge Which rule to draw.
---@param scheme ascii.art.Scheme? Symbols to use. `art.scheme` when `nil`.
---@return string rule The rule, end glyphs included.
---@nodiscard
function ascii.art.rule(width, edge, scheme) end

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
---@see ascii.art.rule
---
---@param content string The inner text, with no scheme symbols.
---@param width integer Inner width in columns, `0` or more.
---@param scheme ascii.art.Scheme? Symbols to use. `art.scheme` when `nil`.
---@return string row The row, vertical strokes included.
---@nodiscard
function ascii.art.row(content, width, scheme) end

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
---@see ascii.art.frame
---@see ascii.art.keyValues
---@see ascii.art.grid
---
---@param sections string[][] Rows grouped into sections. A section is one list of inner texts.
---@param width integer? Inner width in columns. The widest row when `nil`.
---@param scheme ascii.art.Scheme? Symbols to use. `art.scheme` when `nil`.
---@return ascii.art.Line[] lines The top rule, the rows, a divider between sections, and the bottom rule.
---@nodiscard
function ascii.art.box(sections, width, scheme) end

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
---@see ascii.art.box
---@see ascii.art.wrap
---
---@param lines string | string[] The text, or rows that are already split.
---@param width integer? Inner width in columns. The widest row when `nil`.
---@param scheme ascii.art.Scheme? Symbols to use. `art.scheme` when `nil`.
---@return ascii.art.Line[] lines The framed block.
---@nodiscard
function ascii.art.frame(lines, width, scheme) end

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
---@see ascii.art.box
---
---@param sections ascii.art.KeyValue[][] Labeled rows, grouped into sections.
---@param key_width integer? Columns reserved for the key and its colon. `12` when `nil`.
---@param value_width integer? Columns reserved for the value. `40` when `nil`.
---@param scheme ascii.art.Scheme? Symbols to use. `art.scheme` when `nil`.
---@return ascii.art.Line[] lines The framed rows.
---@nodiscard
function ascii.art.keyValues(sections, key_width, value_width, scheme) end

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
---@see ascii.art.box
---
---@param rows string[][] Cells, one list per row. A missing cell is drawn empty.
---@param widths integer[]? Column widths. Measured from the cells when `nil`, and for each column whose width is `nil`.
---@param scheme ascii.art.Scheme? Symbols to use. `art.scheme` when `nil`.
---@param heading boolean? Draw a divider under the first row when a second row exists. `false` when `nil`.
---@return ascii.art.Line[] lines The framed grid.
---@nodiscard
function ascii.art.grid(rows, widths, scheme, heading) end

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
---@param scheme ascii.art.Scheme? Symbols to use. `art.scheme` when `nil`.
---@return ascii.art.TreeLine[] lines One line per visited node, parents before their children.
---@nodiscard
function ascii.art.tree(roots, children, scheme) end

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
function ascii.art.bar(ratio, width, force_ascii) end

--- [SHARED AND MENU]
---
--- Joins rendered lines into one string.
---
--- Lines are separated by `\n`. There is no trailing newline. An empty list
--- returns an empty string.
---
---@param lines ascii.art.Line[] The lines, as returned by `art.box`, `art.frame`, `art.keyValues` or `art.grid`.
---@return string figure The figure as one string.
---@nodiscard
function ascii.art.render(lines) end
