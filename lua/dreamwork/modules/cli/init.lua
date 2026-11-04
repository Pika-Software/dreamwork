---@class dreamwork
local dreamwork = dreamwork
local std = dreamwork.std

local dreamwork_engine = dreamwork.engine
local engine_console = dreamwork_engine.console

local console_message = engine_console.message
local console_messageColored = engine_console.messageColored

local console = std.console
local console_Command = console.Command

local raw = std.raw
local raw_pairs = raw.pairs
local raw_tonumber = raw.tonumber

local string = std.string
local string_sub = string.sub
local string_len = string.len
local string_match = string.match
local string_format = string.format

local table = std.table
local table_sort = table.sort

local color_scheme = std.color.Scheme
local COLOR_NAME = color_scheme.dreamwork_info
local COLOR_DESCRIPTION = color_scheme.suva_gray
local COLOR_ERROR = color_scheme.dreamwork_warn

local math = std.math
local math_ceil = math.ceil
local math_floor = math.floor

local LUA_SERVER = std.LUA_SERVER

local dreamwork_load = dreamwork.load


--- [SHARED AND MENU]
---
--- Command-line interface of Dreamwork.
---
--- The server one is `dreamwork_sci` (server console interface), the client and menu one is `dreamwork_cci` (client console interface).
---
---@class dreamwork.cli
local cli = dreamwork.cli or {}
dreamwork.cli = cli

local console_command = console_Command( {
    name = LUA_SERVER and "dreamwork_sci" or "dreamwork_cci",
    description = LUA_SERVER and "Dreamwork server console interface." or "Dreamwork client console interface."
} )

cli.Command = console_command
console_command:clear()

---@class dreamwork.cli.Command
---@field description? string The description shown by `help`.
---@field usage? string The arguments shown by `help`, e.g. `[path] [max_depth]`.
---@field on_run fun( args: string[] ) Called with the arguments after the name of the command.
---@field on_type? fun( args: string[], argument_string: string ): string[] | nil Returns the suggestions for the typed arguments, each one replaces the whole `argument_string`.

---@type table<string, dreamwork.cli.Command>
local commands = {}

--- Returns the sorted names of the commands that start with the prefix.
---
---@param prefix string
---@return string[] names
---@return integer name_count
local function find_names( prefix )
    ---@type string[]
    local names = {}
    local name_count = 0

    local prefix_length = string_len( prefix )

    for name in raw_pairs( commands ) do
        if string_sub( name, 1, prefix_length ) == prefix then
            name_count = name_count + 1
            names[ name_count ] = name
        end
    end

    table_sort( names )
    return names, name_count
end

local HELP_PAGE_SIZE = 8

---@param page integer
local function print_help( page )
    local names, name_count = find_names( "" )

    local page_count = math_ceil( name_count / HELP_PAGE_SIZE )
    if page_count < 1 then
        page_count = 1
    end

    if page > page_count then
        page = page_count
    elseif page < 1 then
        page = 1
    end

    console_messageColored( string_format( "Usage: %s <command> [arguments]\n", console_command.name ), COLOR_DESCRIPTION )

    local first = (page - 1) * HELP_PAGE_SIZE + 1
    local last = first + HELP_PAGE_SIZE - 1
    if last > name_count then
        last = name_count
    end

    for index = first, last, 1 do
        local name = names[ index ]
        local command = commands[ name ]

        console_message( "  " )
        console_messageColored( name, COLOR_NAME )

        local usage = command.usage
        if usage ~= nil then
            console_message( " " .. usage )
        end

        local description = command.description
        if description ~= nil then
            console_messageColored( " - " .. description, COLOR_DESCRIPTION )
        end

        console_message( "\n" )
    end

    console_messageColored( string_format( "\nPage %d/%d (%d commands)\n", page, page_count, name_count ), COLOR_NAME )

    if page < page_count then
        console_messageColored( string_format( "Use '%s help %d' to see the next page.\n", console_command.name, page + 1 ), COLOR_DESCRIPTION )
    elseif page_count > 1 then
        console_messageColored( string_format( "Use '%s help <page>' to see another page.\n", console_command.name ), COLOR_DESCRIPTION )
    end
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

console_command:attach( function( self, client, args, argument_string )
    if not is_allowed( client ) then return end

    -- no command is a fallback to the first page of `help`
    local name = args[ 1 ] or "help"

    local command = commands[ name ]
    if command == nil then
        console_messageColored( string_format( "Unknown command '%s', see '%s help'.\n", name, self.name ), COLOR_ERROR )
        return
    end

    ---@type string[]
    local command_args = {}

    for index = 2, #args, 1 do
        command_args[ index - 1 ] = args[ index ]
    end

    command.on_run( command_args )
end )

function console_command:autocomplete( argument_string, args )
    local name, rest = string_match( argument_string, "^%s*(%S*)(.*)$" )

    -- still typing the name of the command
    if rest == "" then
        local names, name_count = find_names( name )
        if name_count == 0 then
            return nil
        end

        return names
    end

    local command = commands[ name ]
    if command == nil then
        return nil
    end

    local on_type = command.on_type
    if on_type == nil then
        return nil
    end

    ---@type string[]
    local command_args = {}

    for index = 2, #args, 1 do
        command_args[ index - 1 ] = args[ index ]
    end

    local suggestions = on_type( command_args, string_match( rest, "^%s*(.*)$" ) )
    if suggestions == nil then
        return nil
    end

    local prefix = name .. " "

    for index = 1, #suggestions, 1 do
        suggestions[ index ] = prefix .. suggestions[ index ]
    end

    return suggestions
end

--- [SHARED AND MENU]
---
--- Registers the command, replaces the command with the same name.
---
---@param name string The name of the command, must not contain spaces.
---@param command dreamwork.cli.Command The command.
function cli.register( name, command )
    commands[ name ] = command
end

--- [SHARED AND MENU]
---
--- Unregisters the command.
---
---@param name string The name of the command.
function cli.unregister( name )
    commands[ name ] = nil
end

cli.register( "help", {
    description = "Lists the commands, " .. HELP_PAGE_SIZE .. " per page.",
    usage = "[page]",
    on_run = function( args )
        local page = 1

        local page_str = args[ 1 ]
        if page_str ~= nil then
            local page_value = raw_tonumber( page_str, 10 )
            if page_value == nil or page_value ~= page_value or page_value > 0xFFFF then
                console_messageColored( "Invalid page number.\n", COLOR_ERROR )
                return
            end

            page = math_floor( page_value )
        end

        print_help( page )
    end
} )

dreamwork_load( "modules/cli/commands/debug.lua" )
dreamwork_load( "modules/cli/commands/http_client.lua" )
