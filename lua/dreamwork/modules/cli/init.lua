---@class dreamwork
local dreamwork = dreamwork
local std = dreamwork.std

local dreamwork_engine = dreamwork.engine
local engine_console = dreamwork_engine.console

local console_message = engine_console.message
local console_messageColored = engine_console.messageColored

local console = std.console
local console_Command = console.Command
local console_Variable = console.Variable

local dreamwork_vfs = dreamwork.vfs
local vfs_search = dreamwork_vfs.search


local raw = std.raw
local raw_pairs = raw.pairs
local raw_tonumber = raw.tonumber
local raw_tostring = raw.tostring
local tostring = std.tostring

local string = std.string
local string_sub = string.sub
local string_byte = string.byte
local string_find = string.find
local string_gmatch = string.gmatch
local string_lower = string.lower
local string_match = string.match
local string_format = string.format
local string_rep = string.rep

local utf8_len = std.utf8.len

local table = std.table
local table_sort = table.sort
local table_concat = table.concat
local table_slice = table.slice

local path = std.path
local path_normalize = path.normalize

local math = std.math
local math_ceil = math.ceil
local math_floor = math.floor

local pcall = std.pcall
local raw_select = raw.select
local class = std.class
local class_isInherited = class.isInherited

local LUA_SERVER = std.LUA_SERVER

local dreamwork_load = dreamwork.load


--- [SHARED AND MENU]
---
--- Command-line interface of Dreamwork.
---
--- The server one is `dreamwork_sci` (server console interface), the client and menu one is `dreamwork_cci` (client console interface).
---
--- Commands are registered in groups, the root group is `cli.root`, every group has its own `help` command.
---
---@class dreamwork.cli
local cli = dreamwork.cli or {}
dreamwork.cli = cli

---@class dreamwork.cli.Command
---@field description? string The description shown by `help`.
---@field usage? string The arguments shown by `help`, e.g. `[path] [max_depth]`.
---@field on_run async fun( self: dreamwork.cli.Command, args: string[], argument_string: string ) Called with the arguments after the name of the command, always inside `futures.run`.
---@field on_type? fun( self: dreamwork.cli.Command, args: string[], argument_string: string ): string[] | nil Returns the suggestions for the typed arguments, each one replaces the whole `argument_string`.

--- [SHARED AND MENU]
---
--- The colors used by the commands.
---
local colors = {
    name = std.color.Scheme.dreamwork_info,
    value = std.color.Scheme.light_gray,
    description = std.color.Scheme.suva_gray,
    error = std.color.Scheme.dreamwork_warn
}

cli.colors = colors

--- [SHARED AND MENU]
---
--- The maximal number of suggestions returned by `cli.complete`.
---
local SUGGESTION_LIMIT = 64
cli.SUGGESTION_LIMIT = SUGGESTION_LIMIT

do

    --- [SHARED AND MENU]
    ---
    --- Writes the text into the console without a new line.
    ---
    ---@param text string The text.
    ---@param color dreamwork.std.Color? The color, the default console color if `nil`.
    local function write( text, color )
        if color == nil then
            console_message( text )
        else
            console_messageColored( text, color )
        end
    end

    cli.write = write

    --- [SHARED AND MENU]
    ---
    --- Prints the line into the console, the text is formatted only when arguments are given.
    ---
    ---@param color dreamwork.std.Color | nil The color, the default console color if `nil`.
    ---@param fmt string The text or the format string.
    ---@param ... any The arguments of the format string.
    local function print( color, fmt, ... )
        if raw_select( "#", ... ) ~= 0 then
            fmt = string_format( fmt, ... )
        end

        write( fmt .. "\n", color )
    end

    cli.print = print

    --- [SHARED AND MENU]
    ---
    --- Prints the line into the console with the error color.
    ---
    ---@param fmt string The text or the format string.
    ---@param ... any The arguments of the format string.
    function cli.error( fmt, ... )
        print( colors.error, fmt, ... )
    end

    ---@class dreamwork.cli.BoxStyle
    ---@field top_left string
    ---@field top_right string
    ---@field bottom_left string
    ---@field bottom_right string
    ---@field middle_left string
    ---@field middle_right string
    ---@field horizontal string
    ---@field vertical string

    --- The dedicated server console is a terminal, it draws box-drawing characters as wide as the text,
    --- the in-game console (client, menu and the listen server host) draws them with a wider fallback font.
    ---
    ---@type boolean
    local is_terminal = false

    if LUA_SERVER then
        local glua_game = dreamwork_engine.requireLibrary( "game" )
        is_terminal = glua_game.IsDedicated ~= nil and glua_game.IsDedicated() == true
    end

    ---@type dreamwork.cli.BoxStyle
    local box_style

    if is_terminal then
        box_style = {
            top_left = "┌",
            top_right = "┐",
            bottom_left = "└",
            bottom_right = "┘",
            middle_left = "├",
            middle_right = "┤",
            horizontal = "─",
            vertical = "│"
        }
    else
        box_style = {
            top_left = "+",
            top_right = "+",
            bottom_left = "+",
            bottom_right = "+",
            middle_left = "+",
            middle_right = "+",
            horizontal = "-",
            vertical = "|"
        }
    end

    ---@param str string
    ---@return integer
    local function text_width( str )
        -- lax, so broken UTF-8 still has a width
        return utf8_len( str, nil, nil, true ) or #str
    end

    --- [SHARED AND MENU]
    ---
    --- The maximal width of the text in boxes, longer lines are wrapped.
    ---
    local BOX_WIDTH = 64
    cli.BOX_WIDTH = BOX_WIDTH

    --- [SHARED AND MENU]
    ---
    --- Wraps the text into lines no longer than the width, words longer than the width are split.
    ---
    ---@param text string The text, without new lines.
    ---@param width integer The maximal width of a line in characters.
    ---@param lines string[]? The lines to append to, a new table if `nil`.
    ---@return string[] lines The lines.
    ---@return integer line_count The number of lines.
    local function wrap( text, width, lines )
        if lines == nil then
            lines = {}
        end

        local line_count = #lines

        local line, line_width = "", 0

        for word in string_gmatch( text, "%S+" ) do
            local word_width = text_width( word )

            -- too long for any line, split by bytes, paths are the usual case
            if word_width > width then
                if line_width ~= 0 then
                    line_count = line_count + 1
                    lines[ line_count ] = line
                end

                for position = 1, #word, width do
                    line_count = line_count + 1
                    lines[ line_count ] = string_sub( word, position, position + width - 1 )
                end

                line = lines[ line_count ]
                line_count = line_count - 1
                line_width = text_width( line )
            elseif line_width == 0 then
                line, line_width = word, word_width
            elseif line_width + 1 + word_width > width then
                line_count = line_count + 1
                lines[ line_count ] = line
                line, line_width = word, word_width
            else
                line, line_width = line .. " " .. word, line_width + 1 + word_width
            end
        end

        line_count = line_count + 1
        lines[ line_count ] = line

        return lines, line_count
    end

    cli.wrap = wrap

    --- [SHARED AND MENU]
    ---
    --- Prints the lines inside of the box, the width is taken from the longest line, lines longer than `cli.BOX_WIDTH` are wrapped.
    ---
    --- When `title` is given, it fills a separated top part of the box.
    ---
    --- The dedicated server console uses box-drawing characters, the in-game console draws them with a wider fallback font,
    --- so it gets an ASCII border.
    ---
    --- ```
    --- ┌───────────────┐    +---------------+
    --- │ title         │    | title         |
    --- ├───────────────┤    +---------------+
    --- │ first line    │    | first line    |
    --- │ second line   │    | second line   |
    --- └───────────────┘    +---------------+
    --- ```
    ---
    ---@param lines string[] The lines, without new lines.
    ---@param title string? The title shown in the separated top part of the box.
    ---@param color dreamwork.std.Color? The color of the text, `cli.colors.name` if `nil`.
    ---@param border_color dreamwork.std.Color? The color of the border, `cli.colors.description` if `nil`.
    function cli.printBox( lines, title, color, border_color )
        color = color or colors.name
        border_color = border_color or colors.description

        ---@type string[]
        local title_lines = {}
        local title_count = 0

        if title ~= nil and title ~= "" then
            title_lines, title_count = wrap( title, BOX_WIDTH )
        end

        ---@type string[]
        local wrapped = {}
        local line_count = 0

        for index = 1, #lines, 1 do
            wrapped, line_count = wrap( lines[ index ], BOX_WIDTH, wrapped )
        end

        lines = wrapped

        ---@type integer[]
        local title_widths = {}
        ---@type integer[]
        local widths = {}
        local max_width = 0

        for index = 1, title_count, 1 do
            local width = text_width( title_lines[ index ] )
            title_widths[ index ] = width

            if width > max_width then
                max_width = width
            end
        end

        for index = 1, line_count, 1 do
            local width = text_width( lines[ index ] )
            widths[ index ] = width

            if width > max_width then
                max_width = width
            end
        end

        local horizontal = string_rep( box_style.horizontal, max_width + 2 )
        local vertical = box_style.vertical

        write( box_style.top_left .. horizontal .. box_style.top_right .. "\n", border_color )

        for index = 1, title_count, 1 do
            write( vertical .. " ", border_color )
            write( title_lines[ index ] .. string_rep( " ", max_width - title_widths[ index ] ), color )
            write( " " .. vertical .. "\n", border_color )
        end

        if title_count ~= 0 and line_count ~= 0 then
            write( box_style.middle_left .. horizontal .. box_style.middle_right .. "\n", border_color )
        end

        for index = 1, line_count, 1 do
            write( vertical .. " ", border_color )
            write( lines[ index ] .. string_rep( " ", max_width - widths[ index ] ), color )
            write( " " .. vertical .. "\n", border_color )
        end

        write( box_style.bottom_left .. horizontal .. box_style.bottom_right .. "\n", border_color )
    end

    --- [SHARED AND MENU]
    ---
    --- Prints the lines inside of the box with an empty line after it, separates the header from the content.
    ---
    ---@param lines string[] The lines, without new lines.
    ---@param title string? The title shown in the separated top part of the box.
    ---@param color dreamwork.std.Color? The color of the text, `cli.colors.name` if `nil`.
    ---@param border_color dreamwork.std.Color? The color of the border, `cli.colors.description` if `nil`.
    function cli.printHeader( lines, title, color, border_color )
        cli.printBox( lines, title, color, border_color )
        write( "\n" )
    end

end

--- [SHARED AND MENU]
---
--- Splits the first argument from the argument string.
---
---@param argument_string string The argument string.
---@return string head The first argument, can be empty.
---@return string | nil tail The arguments after the first one, `nil` if the first argument is still being typed.
function cli.shift( argument_string )
    local head, separator, tail = string_match( argument_string, "^%s*(%S*)(%s*)(.*)$" )
    if separator == "" then
        return head, nil
    end

    return head, tail
end

local cli_shift = cli.shift

---@type table<string, string>
local escapes = {
    [ "n" ] = "\n",
    [ "t" ] = "\t",
    [ "r" ] = "\r",
    [ "\"" ] = "\"",
    [ "\\" ] = "\\"
}

--- [SHARED AND MENU]
---
--- Splits the argument string into arguments, unlike the engine it keeps `:` and other special characters.
---
--- Arguments in double quotes keep the spaces and support `\n`, `\t`, `\r`, `\"` and `\\` escapes,
--- an unterminated quote takes the rest of the string, backslashes outside of quotes are kept as is.
---
--- ```lua
--- cli.parseArguments( [[add "/garrysmod/data/a b.txt" "line 1\nline 2"]] ) -- { "add", "/garrysmod/data/a b.txt", "line 1\nline 2" }, 3
--- ```
---
---@param argument_string string The argument string.
---@return string[] args The arguments.
---@return integer arg_count The number of arguments.
function cli.parseArguments( argument_string )
    ---@type string[]
    local args = {}
    local arg_count = 0

    local position = 1

    ::argument_parser::

    local start = string_find( argument_string, "%S", position )
    if start == nil then
        return args, arg_count
    end

    local argument

    if string_byte( argument_string, start, start ) == 0x22 --[[ " ]] then
        ---@type string[]
        local buffer = {}
        local buffer_size = 0

        position = start + 1

        ::quote_parser::

        local stop = string_find( argument_string, "[\"\\]", position )
        if stop == nil then
            buffer_size = buffer_size + 1
            buffer[ buffer_size ] = string_sub( argument_string, position )
            position = #argument_string + 1
        else
            buffer_size = buffer_size + 1
            buffer[ buffer_size ] = string_sub( argument_string, position, stop - 1 )

            if string_byte( argument_string, stop, stop ) == 0x5C --[[ \ ]] then
                local escaped = string_sub( argument_string, stop + 1, stop + 1 )

                buffer_size = buffer_size + 1
                buffer[ buffer_size ] = escapes[ escaped ] or ("\\" .. escaped)

                position = stop + 2
                goto quote_parser
            end

            position = stop + 1
        end

        argument = table_concat( buffer, "", 1, buffer_size )
    else
        local stop = string_find( argument_string, "%s", start ) or (#argument_string + 1)
        argument = string_sub( argument_string, start, stop - 1 )
        position = stop
    end

    arg_count = arg_count + 1
    args[ arg_count ] = argument

    ---@diagnostic disable-next-line: missing-return
    goto argument_parser
end

--- [SHARED AND MENU]
---
--- Converts the typed string into a number.
---
---@param str string The typed string.
---@param min number? The minimal value.
---@param max number? The maximal value.
---@param is_integer boolean? If `true`, fractional values are rejected.
---@return number | nil value The number, or `nil` if the string is invalid.
---@return string | nil reason The reason why the string is invalid, e.g. `is not a number`.
function cli.parseNumber( str, min, max, is_integer )
    local value = raw_tonumber( str, 10 )

    -- `tonumber` accepts "nan"
    if value == nil or value ~= value then
        return nil, "is not a number"
    end

    if is_integer and math_floor( value ) ~= value then
        return nil, "is not an integer"
    end

    if (min ~= nil and value < min) or (max ~= nil and value > max) then
        return nil, string_format( "is out of range [%s, %s]", raw_tostring( min or "-inf" ), raw_tostring( max or "inf" ) )
    end

    return value, nil
end

local cli_parseNumber = cli.parseNumber

---@type string[]
local byte_units = { "B", "KiB", "MiB", "GiB", "TiB" }

--- [SHARED AND MENU]
---
--- Formats the number of bytes with binary units, e.g. `512 B`, `1.50 KiB`, `12.04 MiB`.
---
---@param bytes number The number of bytes.
---@return string str The formatted size.
function cli.formatBytes( bytes )
    if bytes < 1024 then
        return string_format( "%d B", bytes )
    end

    local unit = 1

    ::unit_scaler::

    bytes = bytes / 1024
    unit = unit + 1

    if bytes >= 1024 and unit < 5 then
        goto unit_scaler
    end

    return string_format( "%.2f %s", bytes, byte_units[ unit ] )
end

--- [SHARED AND MENU]
---
--- Reads the optional number argument, prints the error if it is invalid.
---
--- ```lua
--- local depth = cli.readNumber( args, 2, 2, 0, 255, true )
--- if depth == nil then return end
--- ```
---
---@param args string[] The arguments.
---@param index integer The index of the argument.
---@param default number The value used when the argument is missing.
---@param min number? The minimal value.
---@param max number? The maximal value.
---@param is_integer boolean? If `true`, fractional values are rejected.
---@return number | nil value The number, or `nil` if the argument is invalid and the error was printed.
function cli.readNumber( args, index, default, min, max, is_integer )
    local str = args[ index ]
    if str == nil then
        return default
    end

    local value, reason = cli_parseNumber( str, min, max, is_integer )
    if value == nil then
        cli.error( "'%s' %s.", str, reason )
    end

    return value
end

local cli_readNumber = cli.readNumber

--- [SHARED AND MENU]
---
--- Appends the names that start with the prefix to the suggestions, stops at `cli.SUGGESTION_LIMIT` suggestions.
---
---@param prefix string The typed prefix.
---@param names string[] The candidate names.
---@param suggestions string[]? The suggestions to append to, a new table if `nil`.
---@param head string? The text added before every suggested name.
---@param tail string? The text added after every suggested name.
---@return string[] suggestions
function cli.complete( prefix, names, suggestions, head, tail )
    if suggestions == nil then
        suggestions = {}
    end

    local suggestion_count = #suggestions
    if suggestion_count >= SUGGESTION_LIMIT then
        return suggestions
    end

    head, tail = head or "", tail or ""

    local prefix_length = #prefix

    for index = 1, #names, 1 do
        local name = names[ index ]
        if string_sub( name, 1, prefix_length ) == prefix then
            suggestion_count = suggestion_count + 1
            suggestions[ suggestion_count ] = head .. name .. tail

            if suggestion_count == SUGGESTION_LIMIT then
                break
            end
        end
    end

    return suggestions
end

local cli_complete = cli.complete

--- [SHARED AND MENU]
---
--- Returns the absolute normalized path of the typed path, paths without the leading slash start at the root.
---
---@param path_to string The typed path.
---@return string vfs_path
function cli.toVFSPath( path_to )
    if string_byte( path_to, 1, 1 ) ~= 0x2F --[[ / ]] then
        path_to = "/" .. path_to
    end

    return path_normalize( path_to, false )
end

local cli_toVFSPath = cli.toVFSPath

--- [SHARED AND MENU]
---
--- Returns the suggestions for the typed virtual file system path, directories go first and end with a slash.
---
--- Suggestions always start with `/`, a path typed without it is completed as an absolute one.
---
---@param typed string The typed path.
---@param directories_only boolean? If `true`, files are not suggested.
---@return string[] | nil suggestions The suggestions, or `nil` if the typed directory does not exist.
function cli.completeVFSPath( typed, directories_only )
    if string_byte( typed, 1, 1 ) ~= 0x2F --[[ / ]] then
        typed = "/" .. typed
    end

    local typed_directory, name_prefix = string_match( typed, "^(.*/)([^/]*)$" )

    local success, files, _, directories = pcall( vfs_search, cli_toVFSPath( typed_directory ) )
    if not success then
        return nil
    end

    local suggestions = cli_complete( name_prefix, directories, nil, typed_directory, "/" )

    if not directories_only then
        cli_complete( name_prefix, files, suggestions, typed_directory )
    end

    return suggestions
end

local HELP_PAGE_SIZE = 8

--- The `help` command of every group.
---
---@class dreamwork.cli.HelpCommand : dreamwork.std.Object, dreamwork.cli.Command
---@field __class dreamwork.cli.HelpCommandClass
---@field group dreamwork.cli.Group The group listed by the command.
local HelpCommand = class.base( "cli.HelpCommand", false )

HelpCommand.description = "Lists the commands, " .. HELP_PAGE_SIZE .. " per page, or describes the command."
HelpCommand.usage = "[page|command]"

---@param group dreamwork.cli.Group
---@protected
function HelpCommand:__init( group )
    self.group = group
end

---@class dreamwork.cli.HelpCommandClass : dreamwork.cli.HelpCommand, dreamwork.std.Class
---@field __base dreamwork.cli.HelpCommand
---@overload fun( group: dreamwork.cli.Group ): dreamwork.cli.HelpCommand
local HelpCommandClass = class.create( HelpCommand )

--- [SHARED AND MENU]
---
--- The group of commands, dispatches the first argument to the command with that name.
---
---@class dreamwork.cli.Group : dreamwork.std.Object, dreamwork.cli.Command
---@field __class dreamwork.cli.GroupClass
---@field path string The full typed path of the group, e.g. `dreamwork_sci` or `dreamwork_sci vfs`.
---@field commands table<string, dreamwork.cli.Command> The commands by name.
local Group = class.base( "cli.Group", false )

Group.usage = "<command> [arguments]"

---@param path_to string The full typed path of the group.
---@param description string? The description shown by `help`.
---@protected
function Group:__init( path_to, description )
    self.path = path_to
    self.description = description
    self.commands = { help = HelpCommandClass( self ) }
end

--- [SHARED AND MENU]
---
--- The class of command groups, created groups are not registered anywhere, see `Group:group` for nested ones.
---
---@class dreamwork.cli.GroupClass : dreamwork.cli.Group, dreamwork.std.Class
---@field __base dreamwork.cli.Group
---@overload fun( path_to: string, description: string? ): dreamwork.cli.Group
local GroupClass = class.create( Group )
cli.Group = GroupClass

--- [SHARED AND MENU]
---
--- Registers the command, replaces the command with the same name.
---
---@param name string The name of the command, must not contain spaces.
---@param command dreamwork.cli.Command The command.
---@return dreamwork.cli.Command command The same command.
function Group:register( name, command )
    self.commands[ name ] = command
    return command
end

--- [SHARED AND MENU]
---
--- Unregisters the command.
---
---@param name string The name of the command.
function Group:unregister( name )
    self.commands[ name ] = nil
end

--- [SHARED AND MENU]
---
--- Creates and registers the nested group, e.g. `dreamwork_sci <name> <command>`.
---
---@param name string The name of the group, must not contain spaces.
---@param description string? The description shown by `help`.
---@return dreamwork.cli.Group group The nested group.
function Group:group( name, description )
    local group = GroupClass( self.path .. " " .. name, description )
    self.commands[ name ] = group
    return group
end

--- [SHARED AND MENU]
---
--- Returns the sorted names of the commands.
---
---@return string[] names
---@return integer name_count
function Group:getNames()
    ---@type string[]
    local names = {}
    local name_count = 0

    for name in raw_pairs( self.commands ) do
        name_count = name_count + 1
        names[ name_count ] = name
    end

    table_sort( names )
    return names, name_count
end

--- [SHARED AND MENU]
---
--- Prints the page of the command list.
---
---@param page integer The page, clamped to the existing pages.
function Group:printHelp( page )
    local names, name_count = self:getNames()
    local commands = self.commands

    local page_count = math_ceil( name_count / HELP_PAGE_SIZE )
    if page_count < 1 then
        page_count = 1
    end

    if page > page_count then
        page = page_count
    elseif page < 1 then
        page = 1
    end

    ---@type string[]
    local header = {}

    if self.description ~= nil then
        header[ 1 ] = self.description
    end

    header[ #header + 1 ] = string_format( "Page %d/%d, %d commands", page, page_count, name_count )
    cli.printHeader( header, "Usage: " .. self.path .. " <command> [arguments]" )

    local first = (page - 1) * HELP_PAGE_SIZE + 1
    local last = first + HELP_PAGE_SIZE - 1
    if last > name_count then
        last = name_count
    end

    local number_width = #raw_tostring( last )

    for index = first, last, 1 do
        local name = names[ index ]
        local command = commands[ name ]

        console_message( string_format( "  %" .. number_width .. "d. ", index ) )
        console_messageColored( name, colors.name )

        local usage = command.usage
        if usage ~= nil then
            console_message( " " .. usage )
        end

        local description = command.description
        if description ~= nil then
            console_messageColored( " - " .. description, colors.description )
        end

        console_message( "\n" )
    end

    if page < page_count then
        cli.print( colors.description, "\nUse '%s help %d' to see the next page.", self.path, page + 1 )
    elseif page_count > 1 then
        cli.print( colors.description, "\nUse '%s help <page>' to see another page.", self.path )
    end
end

--- [SHARED AND MENU]
---
--- Prints the usage and the description of the command, nested groups print their command list.
---
---@param name string The name of the command.
function Group:printUsage( name )
    local command = self.commands[ name ]
    if command == nil then
        cli.error( "Unknown command '%s', see '%s help'.", name, self.path )
        return
    end

    if class_isInherited( command, Group ) then
        ---@cast command dreamwork.cli.Group
        command:printHelp( 1 )
        return
    end

    local usage = command.usage
    local title = usage == nil and ("Usage: " .. self.path .. " " .. name) or ("Usage: " .. self.path .. " " .. name .. " " .. usage)

    ---@type string[]
    local lines = {}

    local description = command.description
    if description ~= nil then
        lines[ 1 ] = description
    end

    cli.printBox( lines, title )
end

---@param args string[]
---@param argument_string string
function Group:on_run( args, argument_string )
    -- no command is a fallback to the first page of `help`
    local name = args[ 1 ] or "help"

    local command = self.commands[ name ]
    if command == nil then
        cli.error( "Unknown command '%s', see '%s help'.", name, self.path )
        return
    end

    local _, tail = cli_shift( argument_string )
    command:on_run( table_slice( args, 2 ), tail or "" )
end

---@param args string[]
---@param argument_string string
---@return string[] | nil
function Group:on_type( args, argument_string )
    local name, tail = cli_shift( argument_string )

    -- still typing the name of the command
    if tail == nil then
        local suggestions = cli_complete( name, (self:getNames()) )
        if suggestions[ 1 ] == nil then
            return nil
        end

        return suggestions
    end

    local command = self.commands[ name ]
    if command == nil or command.on_type == nil then
        return nil
    end

    local suggestions = command:on_type( table_slice( args, 2 ), tail )
    if suggestions == nil then
        return nil
    end

    local prefix = name .. " "

    for index = 1, #suggestions, 1 do
        suggestions[ index ] = prefix .. suggestions[ index ]
    end

    return suggestions
end

---@param args string[]
function HelpCommand:on_run( args )
    local group = self.group

    local str = args[ 1 ]
    if str ~= nil and raw_tonumber( str, 10 ) == nil then
        group:printUsage( str )
        return
    end

    local page = cli_readNumber( args, 1, 1, 1, 0xFFFF, true )
    if page ~= nil then
        group:printHelp( page )
    end
end

---@param argument_string string
---@return string[] | nil
function HelpCommand:on_type( _, argument_string )
    local name, tail = cli_shift( argument_string )
    if tail ~= nil then
        return nil
    end

    return cli_complete( name, (self.group:getNames()) )
end

--- Players can send server console commands too, so on the server only the console and the listen server host are accepted.
---
---@param client garrysmod.Player | nil
---@return boolean
local function is_allowed( client )
    if not LUA_SERVER or client == nil or not client:IsValid() then
        return true
    end

    return client:IsListenServerHost()
end

local futures_run = std.futures.run

local console_command = console_Command( {
    name = LUA_SERVER and "dreamwork_sci" or "dreamwork_cci",
    description = LUA_SERVER and "Dreamwork server console interface." or "Dreamwork client console interface."
} )

cli.Command = console_command
console_command:clear()

--- [SHARED AND MENU]
---
--- The root group, `dreamwork_sci` on the server and `dreamwork_cci` on the client and menu.
---
local root = GroupClass( console_command.name )
cli.root = root

console_command:attach( function( _, client, args, argument_string )
    if is_allowed( client ) then
        futures_run( root.on_run, function( ok, err )
            if not ok then
                cli.error( "%s", tostring( err ) )
            end

            console_messageColored( "\n" .. dreamwork.Copyright .. "\n\n", colors.description )
        end, root, args, argument_string )
    end
end )

function console_command:autocomplete( argument_string, args )
    return root:on_type( args, argument_string )
end

--- [SHARED AND MENU]
---
--- Registers the command in the root group, replaces the command with the same name.
---
---@param name string The name of the command, must not contain spaces.
---@param command dreamwork.cli.Command The command.
---@return dreamwork.cli.Command command The same command.
function cli.register( name, command )
    return root:register( name, command )
end

--- [SHARED AND MENU]
---
--- Unregisters the command from the root group.
---
---@param name string The name of the command.
function cli.unregister( name )
    root:unregister( name )
end

--- [SHARED AND MENU]
---
--- Creates and registers the group in the root group.
---
---@param name string The name of the group, must not contain spaces.
---@param description string? The description shown by `help`.
---@return dreamwork.cli.Group group The group.
function cli.group( name, description )
    return root:group( name, description )
end

do

    local cli_write = cli.write
    local cli_print = cli.print
    local cli_error = cli.error

    ---@alias dreamwork.cli.Setting.Type "number" | "integer" | "string" | "boolean" | "toggle"
    ---@alias dreamwork.cli.Setting.Value number | string | boolean | nil

    --- A setting is a console variable created by its library, the command only shows and changes it.
    ---
    ---@class dreamwork.cli.Setting
    ---@field name string The name typed in the command.
    ---@field variable string The name of the console variable.
    ---@field type dreamwork.cli.Setting.Type The type of the value, `toggle` is `true`, `false` or `nil` kept in a string variable as `"1"`, `"0"` or `""`.
    ---@field secret? boolean If `true`, the value is never printed.

    ---@type table<string, boolean>
    local booleans = {
        [ "true" ] = true,
        [ "false" ] = false,
        [ "on" ] = true,
        [ "off" ] = false,
        [ "yes" ] = true,
        [ "no" ] = false,
        [ "1" ] = true,
        [ "0" ] = false
    }

    ---@type string[]
    local boolean_names = { "true", "false" }

    ---@type string[]
    local reset_names = { "reset" }

    --- Returns the console variable of the setting.
    ---
    --- Looked up on every use, a reloaded library creates a new variable object.
    ---
    ---@param setting dreamwork.cli.Setting
    ---@return dreamwork.std.console.Variable
    local function get_variable( setting )
        local setting_type = setting.type
        if setting_type == "toggle" then
            setting_type = "string"
        end

        ---@cast setting_type dreamwork.std.console.VariableType

        return console_Variable.get( setting.variable, setting_type )
    end

    --- Converts the typed string into the value of the setting.
    ---
    ---@param setting dreamwork.cli.Setting
    ---@param variable dreamwork.std.console.Variable
    ---@param str string
    ---@return dreamwork.cli.Setting.Value | nil value The value, or `nil` if the string is invalid.
    ---@return string | nil reason The reason why the string is invalid.
    local function parse_value( setting, variable, str )
        local setting_type = setting.type

        if setting_type == "string" then
            return str, nil
        elseif setting_type == "boolean" or setting_type == "toggle" then
            local value = booleans[ string_lower( str ) ]
            if value == nil then
                return nil, "is not a boolean"
            end

            return value, nil
        end

        return cli_parseNumber( str, variable.min, variable.max, setting_type == "integer" )
    end

    --- Converts the value of the console variable into the value of the setting.
    ---
    ---@param setting dreamwork.cli.Setting
    ---@param value number | string | boolean
    ---@return dreamwork.cli.Setting.Value
    local function from_variable( setting, value )
        if setting.type == "toggle" then
            ---@cast value string
            return booleans[ string_lower( value ) ]
        end

        return value
    end

    --- Converts the value of the setting into the value of the console variable.
    ---
    ---@param setting dreamwork.cli.Setting
    ---@param value dreamwork.cli.Setting.Value
    ---@return number | string | boolean
    local function to_variable( setting, value )
        if setting.type == "toggle" then
            if value == nil then
                return ""
            end

            return value and "1" or "0"
        end

        ---@cast value number | string | boolean
        return value
    end

    ---@param setting dreamwork.cli.Setting
    ---@param value dreamwork.cli.Setting.Value
    ---@return string
    local function format_value( setting, value )
        if value == nil then
            return "none"
        end

        if setting.type ~= "string" then
            return raw_tostring( value )
        end

        ---@cast value string

        if setting.secret then
            if value == "" then
                return "<not set>"
            end

            return string_format( "<set, %d characters>", #value )
        end

        return "\"" .. value .. "\""
    end

    ---@param setting dreamwork.cli.Setting
    local function print_setting( setting )
        local variable = get_variable( setting )
        local value, default = from_variable( setting, variable.value ), from_variable( setting, variable.default )

        cli_write( "  " .. setting.name, colors.name )
        cli_write( " = " .. format_value( setting, value ), colors.value )

        if value == default then
            cli_write( " (default)", colors.description )
        elseif not setting.secret then
            cli_write( " (default " .. format_value( setting, default ) .. ")", colors.description )
        end

        if variable.replicated then
            cli_write( " (replicated)", colors.description )
        end

        cli_write( "\n" )
        cli_print( colors.description, "    " .. variable.description )
    end

    --- [SHARED AND MENU]
    ---
    --- The command that shows and changes console variables of the libraries.
    ---
    --- `<name>` lists the settings, `<name> <setting>` shows one, `<name> <setting> <value>` changes it and `<name> <setting> reset` restores the default.
    ---
    --- Replicated variables are read-only on the client.
    ---
    ---@class dreamwork.cli.Settings : dreamwork.std.Object, dreamwork.cli.Command
    ---@field __class dreamwork.cli.SettingsClass
    ---@field path string The full typed path of the command, e.g. `dreamwork_sci http client`.
    ---@field list dreamwork.cli.Setting[] The settings in the listed order.
    ---@field names string[] The names of the settings in the listed order.
    ---@field by_name table<string, dreamwork.cli.Setting> The settings by name.
    local Settings = class.base( "cli.Settings", false )

    Settings.usage = "[setting] [value|reset]"

    ---@class dreamwork.cli.SettingsOptions
    ---@field name string The name of the command, must not contain spaces.
    ---@field description string The description shown by `help`.
    ---@field settings dreamwork.cli.Setting[] The settings in the listed order.

    ---@param path_to string The full typed path of the command.
    ---@param options dreamwork.cli.SettingsOptions The options of the command.
    ---@protected
    function Settings:__init( path_to, options )
        local list = options.settings

        ---@type string[]
        local names = {}

        ---@type table<string, dreamwork.cli.Setting>
        local by_name = {}

        for index = 1, #list, 1 do
            local setting = list[ index ]
            local setting_name = setting.name

            names[ index ] = setting_name
            by_name[ setting_name ] = setting
        end

        self.description = options.description
        self.path = path_to
        self.list = list
        self.names = names
        self.by_name = by_name
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the setting with the name.
    ---
    ---@param name string The name of the setting.
    ---@return dreamwork.cli.Setting | nil setting
    function Settings:get( name )
        return self.by_name[ name ]
    end

    --- [SHARED AND MENU]
    ---
    --- Parses the value and sets the console variable of the setting.
    ---
    ---@param name string The name of the setting.
    ---@param str string The value as typed in the console.
    ---@return boolean success `true` if the value was applied.
    ---@return string | nil reason The reason why the value was not applied.
    function Settings:set( name, str )
        local setting = self.by_name[ name ]
        if setting == nil then
            return false, "is not a setting"
        end

        local variable = get_variable( setting )
        if variable.replicated and not LUA_SERVER then
            return false, "is replicated from the server"
        end

        local value, reason = parse_value( setting, variable, str )
        if value == nil then
            return false, reason
        end

        variable.value = to_variable( setting, value )
        return true, nil
    end

    --- [SHARED AND MENU]
    ---
    --- Reverts the console variable of the setting to its default.
    ---
    ---@param name string The name of the setting.
    ---@return boolean success `true` if the default was applied.
    ---@return string | nil reason The reason why the default was not applied.
    function Settings:reset( name )
        local setting = self.by_name[ name ]
        if setting == nil then
            return false, "is not a setting"
        end

        local variable = get_variable( setting )
        if variable.replicated and not LUA_SERVER then
            return false, "is replicated from the server"
        end

        variable:revert()
        return true, nil
    end

    ---@param args string[]
    ---@param argument_string string
    function Settings:on_run( args, argument_string )
        local name = args[ 1 ]
        if name == nil then
            local list = self.list

            ---@type string[]
            local header = {}

            local description = self.description
            if description ~= nil then
                header[ 1 ] = description
            end

            header[ #header + 1 ] = string_format( "%d settings", #list )
            cli.printHeader( header, "Usage: " .. self.path .. " " .. self.usage )

            for index = 1, #list, 1 do
                print_setting( list[ index ] )
            end

            return
        end

        local setting = self.by_name[ name ]
        if setting == nil then
            cli_error( "Unknown setting '%s', see '%s'.", name, self.path )
            return
        end

        local str = args[ 2 ]
        if str == nil then
            print_setting( setting )
            return
        end

        if str == "reset" then
            local success, reason = self:reset( name )
            if not success then
                cli_error( "'%s' %s.", name, reason )
                return
            end

            print_setting( setting )
            return
        end

        -- strings keep the spaces
        if setting.type == "string" then
            local _, tail = cli_shift( argument_string )
            str = tail or str
        end

        local success, reason = self:set( name, str )
        if not success then
            cli_error( "'%s' %s.", str, reason )
            return
        end

        print_setting( setting )
    end

    ---@param argument_string string
    ---@return string[] | nil
    function Settings:on_type( _, argument_string )
        local name, tail = cli_shift( argument_string )
        if tail == nil then
            return cli_complete( name, self.names )
        end

        local setting = self.by_name[ name ]
        if setting == nil then
            return nil
        end

        local value_prefix, rest = cli_shift( tail )
        if rest ~= nil then
            return nil
        end

        local head = name .. " "

        local suggestions = cli_complete( value_prefix, reset_names, nil, head )

        local setting_type = setting.type
        if setting_type == "boolean" or setting_type == "toggle" then
            cli_complete( value_prefix, boolean_names, suggestions, head )
        end

        return suggestions
    end

    --- [SHARED AND MENU]
    ---
    --- The class of settings commands, created commands are not registered anywhere, see `Group:settings`.
    ---
    ---@class dreamwork.cli.SettingsClass : dreamwork.cli.Settings, dreamwork.std.Class
    ---@field __base dreamwork.cli.Settings
    ---@overload fun( path_to: string, options: dreamwork.cli.SettingsOptions ): dreamwork.cli.Settings
    local SettingsClass = class.create( Settings )
    cli.Settings = SettingsClass

    --- [SHARED AND MENU]
    ---
    --- Creates and registers the settings command, the console variables must already exist.
    ---
    ---@param options dreamwork.cli.SettingsOptions The options of the command.
    ---@return dreamwork.cli.Settings settings
    function Group:settings( options )
        local name = options.name

        local settings = SettingsClass( self.path .. " " .. name, options )
        self.commands[ name ] = settings
        return settings
    end

    --- [SHARED AND MENU]
    ---
    --- Creates and registers the settings command in the root group.
    ---
    ---@param options dreamwork.cli.SettingsOptions The options of the command.
    ---@return dreamwork.cli.Settings settings
    function cli.settings( options )
        return root:settings( options )
    end

end

dreamwork_load( "modules/cli/commands/vfs.lua" )
dreamwork_load( "modules/cli/commands/http.lua" )
dreamwork_load( "modules/cli/commands/mcp.lua", false, not std.LUA_CLIENT_SERVER )
