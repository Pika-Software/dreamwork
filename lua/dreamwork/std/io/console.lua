local sendfile = dreamwork.sendfile
local dofile = dreamwork.dofile

---@class GModGUI
---@field ShowConsole fun() | nil
---@field IsConsoleVisible ( fun(): boolean ) | nil
---@diagnostic disable-next-line: undefined-global
local glua_gui = gui or {}

local engine = dreamwork.engine
local engine_consoleMessage = engine.consoleMessage
local engine_consoleMessageColored = engine.consoleMessageColored

---@class dreamwork.std
local std = dreamwork.std

local isNumber = std.isNumber

--- [SHARED AND MENU]
---
--- The source engine console library.
---
---@class dreamwork.std.console
---@field visible boolean `true` if the console is visible, `false` otherwise.
local console = std.console or {
    visible = std.LUA_SERVER,
}

std.console = console

if std.LUA_MENU then

    local engine_consoleCommandRun = dreamwork.engine.consoleCommandRun

    --- [MENU]
    ---
    --- Shows the console.
    ---
    console.show = glua_gui.ShowConsole or function()
        engine_consoleCommandRun( "showconsole" )
    end

    --- [MENU]
    ---
    --- Hides the console.
    ---
    function console.hide()
        engine_consoleCommandRun( "hideconsole" )
    end

    --- [MENU]
    ---
    --- Toggles the console.
    ---
    function console.toggle()
        engine_consoleCommandRun( "toggleconsole" )
    end

end

console.VisibilityHook = std.Hook( "console.VisibilityHook" )

if std.LUA_CLIENT_MENU then

    local gui_IsConsoleVisible = glua_gui.IsConsoleVisible or function() return false end

    local visible = gui_IsConsoleVisible()
    console.visible = visible

    dreamwork.TickTimer0_25:attach( function()
        if visible ~= gui_IsConsoleVisible() then
            visible = not visible
            console.visible = visible
            console.VisibilityHook:call( visible )
        end
    end, "std.console.visible" )

end

do

    --- [SHARED AND MENU]
    ---
    --- Writes a message to the console.
    ---
    ---@param ... string | dreamwork.std.Color The message to write to the console.
    local function console_write( ... )
        ---@type dreamwork.std.Color
        local color = 0xFFFFFF

        for i = 1, select( "#", ... ), 1 do
            ---@type string | dreamwork.std.Color
            local value = select( i, ... )
            if isNumber( value ) then
                ---@cast value integer
                color = value
            else
                ---@cast value string
                (color == 0xFFFFFF and engine_consoleMessage and engine_consoleMessageColored)( value, color )
            end
        end
    end

    console.write = console_write

    --- [SHARED AND MENU]
    ---
    --- Writes a message to the console with new line after the text.
    ---
    ---@param ... string | dreamwork.std.Color The message to write to the console.
    function console.writeLine( ... )
        console_write( ... )
        engine_consoleMessage( "\n" )
    end

    if std.LUA_SERVER then

        --- [SHARED AND MENU]
        ---
        --- Clears the console output.
        ---
        function console.clear()
            engine_consoleMessage( "\27[2J\27[H" ) -- ANSI escape codes to clear the screen and move the cursor to the top-left corner.
        end

    end

end

do

    ---@alias dreamwork.std.console.Flags
    ---| "unregistered"
    ---| "development_only"
    ---| "game_dll"
    ---| "client_dll"
    ---| "hidden"
    ---| "protected"
    ---| "sponly"
    ---| "archive"
    ---| "notify"
    ---| "userinfo"
    ---| "cheat"
    ---| "printable_only"
    ---| "unlogged"
    ---| "never_as_string"
    ---| "replicated"
    ---| "demo"
    ---| "dont_record"
    ---| "reload_materials"
    ---| "reload_textures"
    ---| "not_connected"
    ---| "material_system_thread"
    ---| "archive_xbox"
    ---| "accessible_from_threads"
    ---| "server_can_execute"
    ---| "server_cannot_query"
    ---| "clientcmd_can_execute"
    ---| "material_thread_mask"
    ---| "lua_client"
    ---| "lua_server"

    ---@class dreamwork.std.console.Flag
    ---@field [1] dreamwork.std.console.Flags
    ---@field [2] integer flag

    ---@type dreamwork.std.console.Flag[]
    local existing_flags = {
        { "unregistered",            1 },
        { "development_only",        2 },
        { "game_dll",                4 },
        { "client_dll",              8 },
        { "hidden",                  16 },
        { "protected",               32 },
        { "sponly",                  64 },
        { "archive",                 128 },
        { "notify",                  256 },
        { "userinfo",                512 },
        { "cheat",                   16384 },
        { "printable_only",          1024 },
        { "unlogged",                2048 },
        { "never_as_string",         4096 },
        { "replicated",              8192 },
        { "demo",                    65536 },
        { "dont_record",             131072 },
        { "reload_materials",        1048576 },
        { "reload_textures",         2097152 },
        { "not_connected",           4194304 },
        { "material_system_thread",  8388608 },
        { "archive_xbox",            16777216 },
        { "accessible_from_threads", 33554432 },
        { "server_can_execute",      268435456 },
        { "server_cannot_query",     536870912 },
        { "clientcmd_can_execute",   1073741824 },
        { "material_thread_mask",    11534336 },
        { "lua_client",              262144 },
        { "lua_server",              524288 }
    }

    local existing_flag_count = #existing_flags

    ---@type table<string, integer>
    local flag_to_integer = {}

    for i = 1, existing_flag_count, 1 do
        local flag = existing_flags[ i ]
        flag_to_integer[ flag[ 1 ] ] = flag[ 2 ]
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the integer flag value for the given flag name.
    ---
    ---
    ---@param flag_name dreamwork.std.console.Flags
    ---@return integer int32_flag
    function console.flag( flag_name )
        return flag_to_integer[ flag_name ]
    end

    --- [SHARED AND MENU]
    ---
    --- Builds an integer flag value from the given flag map.
    ---
    ---@param int32_flags integer
    ---@param flag_map table<dreamwork.std.console.Flags, boolean>
    ---@return integer flag
    function console.flags( int32_flags, flag_map )
        for i = 1, existing_flag_count, 1 do
            local flag = existing_flags[ i ]
            if flag_map[ flag[ 1 ] ] then
                int32_flags = int32_flags + flag[ 2 ]
            end
        end

        return int32_flags
    end

end

-- engine console variable class
dofile( "dreamwork/std/io/console/variable.lua" )
sendfile( "dreamwork/std/io/console/variable.lua" )

-- engine console command class
dofile( "dreamwork/std/io/console/command.lua" )
sendfile( "dreamwork/std/io/console/command.lua" )

-- engine console logger class
dofile( "dreamwork/std/io/console/logger.lua" )
sendfile( "dreamwork/std/io/console/logger.lua" )

if not std.LUA_SERVER then
    function console.clear()
        console.Command.run( "clear" ) -- fuck facepunch
    end
end
