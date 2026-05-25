---@class dreamwork
local dreamwork = dreamwork

-- TODO: globally replace all versions, steamids, url, etc. with their classes in dreamwork, e.g. std.URL, steam.Identifier
-- TODO: add https://eprosync.github.io/interstellar-docs/ support

--- [SHARED AND MENU]
---
--- dreamwork standard environment
---
---@class dreamwork.std
---@field SYSTEM_COUNTRY string The country code of the operating system. (ISO 3166-1 alpha-2)
---@field SYSTEM_HAS_BATTERY boolean `true` if the operating system has a battery, `false` if not.
---@field SYSTEM_BATTERY_LEVEL integer The battery level, from `0` to `100`.
---@field DEVELOPER integer A cached value of `developer` console variable.
---@field FRAME_TIME number The time it takes to run one frame in seconds. **Client-only**
---@field FPS number The number of frames per second. **Client-only**
local std = dreamwork.std
if std == nil then
    ---@class dreamwork.std
    std = {}
    dreamwork.std = std
end

---@diagnostic disable-next-line: undefined-field
local dofile = _G.include or _G.dofile
local error = _G.error

---@class dreamwork.std.gc
local gc = std.gc

local string = std.string

local isString = std.isString

local table_concat = std.table.concat

local time = std.time

local engine = dreamwork.engine
local engine_hookCall = engine.hookCall
local engine_hookCatch = engine.hookCatch

dofile( "std/game.lua" )

--- [SHARED AND MENU]
---
--- The compression libraries.
---
---@class dreamwork.std.compress
std.compress = std.compress or {}

dofile( "std/compress.deflate.lua" )
dofile( "std/compress.lzma.lua" )
dofile( "std/compress.lzw.lua" )

dofile( "std/timer.lua" )
dofile( "std/hook.lua" )
dofile( "std/url.lua" )

if dreamwork.TickTimer0_05 == nil then
    local timer = std.Timer( 0.05, 0, dreamwork.Prefix .. "::TickTimer0_05" )
    dreamwork.TickTimer0_05 = timer
    timer:start()
end

if dreamwork.TickTimer0_1 == nil then
    local timer = std.Timer( 0.1, 0, dreamwork.Prefix .. "::TickTimer0_1" )
    dreamwork.TickTimer0_1 = timer
    timer:start()
end

if dreamwork.TickTimer0_25 == nil then
    local timer = std.Timer( 0.25, 0, dreamwork.Prefix .. "::TickTimer0_25" )
    dreamwork.TickTimer0_25 = timer
    timer:start()
end

if dreamwork.TickTimer1 == nil then
    local timer = std.Timer( 1, 0, dreamwork.Prefix .. "::TickTimer1" )
    dreamwork.TickTimer1 = timer
    timer:start()
end

dofile( "std/console.lua" )
dofile( "std/console.logger.lua" )

local console_Variable = std.console.Variable

if LUA_SERVER then

    -- https://github.com/Facepunch/garrysmod-requests/issues/2793
    local sv_defaultdeployspeed = console_Variable.get( "sv_defaultdeployspeed", "number" )
    if sv_defaultdeployspeed ~= nil and sv_defaultdeployspeed.value == 4 then
        sv_defaultdeployspeed.value = 1
    end

    -- draw everything manually, don't use this crap
    local mp_show_voice_icons = console_Variable.get( "mp_show_voice_icons", "boolean" )
    if mp_show_voice_icons ~= nil and mp_show_voice_icons.value then
        mp_show_voice_icons.value = false
    end

end

local logger = std.console.Logger( {
    color = color_scheme.dreamwork_main,
    title = dreamwork.Prefix,
    interpolation = false
} )

dreamwork.Logger = logger

-- dofile( "std/message.lua" )
local std_metatable = getmetatable( std )

if std_metatable == nil then

    ---@type table<string, fun( self: table ): any>
    local indexes = {}

    ---@type table<string, fun( self: table, value: any )>
    local newindexes = {}

    do

        local raw_set = raw.set

        std_metatable = {
            __indexes = indexes,
            __index = function( self, key )
                local fn = indexes[ key ]
                if fn ~= nil then
                    return fn( self )
                end
            end,
            __newindexes = newindexes,
            __newindex = function( self, key, value )
                local fn = newindexes[ key ]

                if fn == nil then
                    raw_set( self, key, value )
                    return
                end

                value = fn( self, value )

                if value ~= nil then
                    raw_set( self, key, value )
                end
            end
        }

        std.setmetatable( std, std_metatable )

    end

    do

        local developer = std.console.Variable.get( "developer", "integer" )
        if developer == nil then

            ---@private
            function indexes.DEVELOPER()
                return 1
            end

        else

            ---@private
            function indexes.DEVELOPER()
                return developer.value
            end

        end

    end

    ---@private
    function indexes.DST_TZ()
        if std.DST then
            return std.TZ + 1
        else
            return std.TZ
        end
    end

    if LUA_CLIENT then

        local time_elapsed = time.elapsed

        local frame_time = 0
        local fps = 0

        ---@private
        function indexes.FPS()
            return fps
        end

        ---@private
        function indexes.FRAME_TIME()
            return frame_time
        end

        local last_pre_render = 0

        engine_hookCatch( "PreRender", function()
            local elapsed_time = time_elapsed()

            if last_pre_render ~= 0 then
                frame_time = elapsed_time - last_pre_render
                fps = 1 / frame_time
            end

            last_pre_render = elapsed_time
        end, 1 )

    end

end

do

    local setTimeout = std.setTimeout

    ---@class dreamwork.std.futures
    local futures = std.futures

    --- [SHARED AND MENU]
    ---
    --- Puts current thread to sleep for given amount of seconds.
    ---
    ---@see dreamwork.std.futures.pending
    ---@see dreamwork.std.futures.wakeup
    ---@async
    ---@param seconds number
    function std.sleep( seconds )
        local co = futures.running()
        if co == nil then
            error( "`sleep` cannot be called from main thread!", 2 )
        end

        ---@cast co thread
        setTimeout( function()
            futures.wakeup( co )
        end, seconds )

        return futures.pending()
    end

    futures.sleep = std.sleep

end

-- Welcome message
do

    local name = "stranger"

    local cvar = std.console.Variable.get( LUA_SERVER and "hostname" or "name", "string" )
    if cvar ~= nil then
        ---@type string
        ---@diagnostic disable-next-line: assign-type-mismatch
        name = cvar.value
        if string.isEmpty( name ) or name == "unnamed" then
            name = "stranger"
        end
    end

    local splashes = {
        "We'll Sandblast these walls and paint them again ♪",
        ";fix these broken wings, then show me how to fly ♪",
        "And I feel like I could spread my wings and fly ♪",
        "They'll wait for me to fall under the pressure ♪",
        "nf2ca53pnz2caytfebzw6idfmfzxsidun4qho2lo * 0.5",
        "eW91dHViZS5jb20vd2F0Y2g/dj1kUXc0dzlXZ1hjUQ==",
        "Woah-oh-oh, tell me where you wanna go ♪",
        "Let's write our names here in the sky ♪",
        "We will have a great Future together.",
        "Millions of pieces without a tether ♪",
        "It always seems time is on the side ♪",
        "Why are we always looking for more ♪",
        "Never forget to finish your Task's!",
        "They'll wait for me to give it up ♪",
        "I don't care who I'm meant to be ♪",
        "Take it in and breathe the light ♪",
        "T2gsIHlvdSdyZSBhIHNtYXJ0IG9uZS4=",
        "I'm tired of these darker days ♪",
        "Don't worry, " .. name .. " :>",
        "Big Brother is watching you",
        "As we build it once agai1n ♪",
        "I'm turning the lights on ♪",
        "I'm calling out for help ♪",
        "I'll make you a promise.",
        "Flying over rooftops...",
        "Hello, " .. name .. "!",
        "Dream + Framework = <3",
        "We need more packages!",
        "Pew-pew-pew-pew-pew! ♪",
        "Play SOMA sometime;",
        "Where's fireworks!?",
        "Let the sun arise ♪",
        "Looking For More ♪",
        "I'm watching you.",
        "Faster than ever.",
        "Love Wins Again ♪",
        "Made with love <3",
        "I burn my sky ♪",
        "Blazing fast ☄",
        "Ancient Tech ♪",
        "Here For You ♪",
        "Good Enough ♪",
        "Manifest It ♪",
        "MAKE A MOVE ♪",
        "v" .. dreamwork.Version,
        "Hello World!",
        "all_the_same",
        "Star Glide ♪",
        "Once Again ♪",
        "Without Us ♪",
        "Data Loss ♪",
        "Sandblast ♪",
        "Now on LLS!",
        "That's me!",
        "I see you.",
        "Light Up ♪",
        "Majesty ♪",
        "Eat Me ♪",
        "FLY ♪"
    }

    local count = #splashes + 1
    splashes[ count ] = "Wow, there are over " .. (count - 1) .. " splashes here!"

    local scheme

    if std.SYSTEM_WINDOWS and false --[[ ha-ha microslop ]] then
        scheme = {
            "       / *    .      +                                                         ⣀⣀⣤⠤⢤⣀⠀ ",
            "  .   /                        /  '           '                         ⢀⣠⠴⠒⢋⣉⣀⣠⣄⣀⣈⡇   ",
            "     *   .         '          /           *                   ⠀⠀⠀⠀⣠⣴⣾⣯⠴⠚⠉⠉⠀⠀⠀⠀⣤⠏⣿      ",
            "   *    * %s                                                 ⠀⣠⣴⡿⠿⢛⠁⠁⣸⠀⠀⠀⠀⠀⣤⣾⠵⠚⠁      ",
            "'                +   +                    _|_     '    *  ⠀⣠⣴⠿⠋⠁⠀⠀⠀⠀⠘⣿⠀⣀⡠⠞⠛⠁⠂⠁⠀⠀      ",
            "       .                             .      |         ⠀⠀⣀⣴⠟⠋⠁⠀⠀⠀⠀⠐⠠⡤⣾⣙⣶⡶⠃⠀⠀⠀⠀⠀⠀⠀       ",
            "⠉                ____    o  +   .    +                ⣤⢾⣋⠉        __ ⡴⢿⢛⠃              ",
            "⠄       o       / __ \\_____ __  __ _ _ __ _____     ⣴⡼⢏⠑__  _____/ /__ ⢿               ",
            "⠂⠂      .      / / / /⠁⠁⠁//_ \\/ _` | '_ ` _ \\ \\ /\\ / / _  \\/ ___/ //_/                 ",
            "⠁   +       ⣀⣴/ /_/ / /⠞⠁/ __/ (_) | | | | | \\ V  V / (_) / /  / ,<                    ",
            "         ⣠⢴⣿⠟/_____/_/  ⠞\\___|\\__,_|_| |_| |_|\\_/\\_/ \\___/_/  /_/|_|                   ",
            "⠀⠀⠀⠀⠀⢀⡴⢏⡵⠛⠀⠀⠀⠀⠀⠀⠀⣀⣴⠞⠛                                                                  ",
            "⠀⠀⠀⣀⣼⠛⣲⡏⠁⠀⠀⠀⠀⠀⢀⣠⡾⠋⠉⠁⠁⠁        .-.    o  +   .    |                                     ",
            "⠀⠀⡴⠟⠀⢰⡯⠄⠀⠀⠀⠀⣠⢴⠟⠉ ⠁              ) )             --o--                                  ",
            "⠀⡾⠁⠁⠀⠘⠧⠤⢤⣤⠶⠏⠙⠁    *     *       '-´   ⠁   ⠁    ⠁  |                                    ",
            "⠘⣇⠂⢀⣀⣀⠤⠞⠋                                                                              ",
            "⠀⠈⠉⠉⠉     .      +                      *   '      '        +                          ",
            "╭────⋆⋅☆⋅⋆──────⋆⋅☆⋅⋆──────⋆⋅☆⋅⋆──────⋆⋅☆⋅⋆──ˎˊ˗                                       ",
            "┊  GitHub: https://github.com/Pika-Software                                            ",
            "┊  Discord: https://discord.gg/Gzak99XGvv                                              ",
            "┊  Website: https://p1ka.eu                                                            ",
            "┊  Developers: Pika Software                                                           ",
            "┊  License: MIT                                                                        ",
            "╰────⋆⋅☆⋅⋆──────⋆⋅☆⋅⋆──────⋆⋅☆⋅⋆──────⋆⋅☆⋅⋆──ˎˊ˗                                       "
        }
    else
        scheme = {
            "               /          .      +           /                                    ",
            "          .   *                             /  '           '     .                ",
            "   .             .             '           /           *                `         ",
            "                     +                    *        *                         .    ",
            "     '              /                                 _|_     '    *              ",
            "           ,       +            .            .         |              +     |     ",
            "            '       \\            \\                       .     '          --o--   ",
            "  `      * .         +            \\          ,                         '    |     ",
            "             ____                  \\        __        __            __            ",
            "    .       / __ \\ ____ __   __ __  __ ____\\  \\      /  /___  _____/ /__ ` .     .",
            "   /   .   / / / / __// _ \\ /  _` || '_ ` _ \\  \\ __ /  / _  \\/ ___/ //_/  `     / ",
            "  /   /   / /_/ / /  /  __//  (_) || | | | | \\  V  V  / (_) / /  / ,<\\         /  ",
            " *   *   /_____/_/   \\ ___|\\ __/__||_| |_| |_|\\ _/\\_/ \\ ___/_/  /_/|_|        /   ",
            "  ,                 .      +              \\                 '                *    ",
            "       +         \\  %s                                                  `          ",
            "  .               \\              *           \\               *              ,     ",
            "     .-.    `      *                          *        |         '                ",
            "      ) )               *     '                      --o--         ,   +          ",
            "     '-´                           *                   |                          ",
            "         '        +           *           *   '               +                   ",
            "|>|================================================= ` .                          ",
            "|=| -  GitHub:   https://github.com/Pika-Software  /  `                           ",
            "|<| - Discord:   https://discord.gg/Gzak99XGvv    /                               ",
            "|=| - Website:   https://p1ka.eu                 /                                ",
            "|<| - DevTeam:   Pika Software                  /                                 ",
            "|=| - License:   MIT                           /                                  ",
            "|>|___________________________________________/                                   "
        }
    end

    local welcome_art = string.gsub( table_concat( scheme, "\n", 1 ), "%%s" .. string.rep( " ", 50 - 1 ), "%%s" )
    local splash = splashes[ math.random( 1, count ) ]

    std.printfc( "\n" .. welcome_art .. "\n", string.pad( splash, 50, " ", nil, std.encoding.utf8.len( splash ) ) )

end

if math.randomseed == 0 then
    math.randomseed = time.now( "ms", false )
end

dofile( "std/fs.lua" )
dofile( "std/sqlite.lua" )

dofile( "storage.lua" )
dofile( "factory.lua" )

logger:info( "Started with %d game(s) and %d addon(s).", engine.GameCount, engine.AddonCount )

---@param game_info dreamwork.engine.GameInfo
---@param is_mounted boolean
engine_hookCatch( "GameMounted", function( game_info, is_mounted )
    logger:debug( "Game '%s' (AppID: %d) was %s.", game_info.folder, game_info.depot, is_mounted and "mounted" or "unmounted" )
end, 1 )

---@param addon_info dreamwork.engine.AddonInfo
---@param is_mounted boolean
engine_hookCatch( "AddonMounted", function( addon_info, is_mounted )
    logger:debug( "Addon '%s' (%d) was %s.", addon_info.title, addon_info.index, is_mounted and "mounted" or "unmounted" )
end, 1 )

do

    local changes_timeout = std.Timer( 0.5, 1, dreamwork.Prefix .. "::ContentWatcher" )

    local function perform_synchronization()
        logger:debug( "Game content change triggered, synchronization..." )
        time.tick( "ms", false )

        local game_changes, addon_changes = engine.hookCall( "GameContentUpdate" )

        if game_changes == 0 and addon_changes == 0 then
            logger:debug( "No changes found, skipped." )
        else
            logger:debug( "Synchronization finished with %d game(s) and %d addon(s) in %d ms.", game_changes, addon_changes, time.tick( "ms", false ) )
        end
    end

    changes_timeout:attach( perform_synchronization )
    perform_synchronization()

    engine_hookCatch( "GameContentChanged", function()
        changes_timeout:start()
    end, 1 )

end

dofile( "std/i18n.lua" )
dofile( "std/game.hooks.lua" )
dofile( "std/audio_stream.lua" )

-- https://github.com/willox/gmbc
if std.loadbinary( "gmbc" ) then
    logger:info( "'gmbc' was loaded & connected as LuaJIT bytecode compiler." )
else
    logger:warn( "'gmbc' is missing, bytecode compilation not available." )
end

do

    ---@diagnostic disable-next-line: undefined-field
    local gmbc_load_bytecode = _G.gmbc_load_bytecode

    ---@diagnostic disable-next-line: undefined-field
    local CompileString = _G.CompileString

    local getfenv, setfenv = std.getfenv, std.setfenv
    local file_read = std.fs.read
    local pcall = std.pcall

    --- [SHARED AND MENU]
    ---
    --- Loads a string as
    --- a lua code chunk in the specified environment
    --- and returns function as a compile result.
    ---
    ---@param lua_code string The lua code chunk.
    ---@param chunk_name string | nil The lua code chunk name.
    ---@param env table | nil The environment of compiled function.
    ---@return function | nil fn The compiled function.
    ---@return string | nil msg The error message.
    local function loadstring( lua_code, chunk_name, env )
        local fn = CompileString( lua_code, chunk_name or "=(loadstring)", false )
        if fn == nil then
            return nil, "lua code compilation failed"
        elseif isString( fn ) then
            ---@diagnostic disable-next-line: cast-type-mismatch
            ---@cast fn string
            return nil, fn
        else
            setfenv( fn, env or getfenv( 2 ) )
            return fn
        end
    end

    std.loadstring = loadstring

    --- [SHARED AND MENU]
    ---
    --- Loads a string as
    --- a bytecode chunk in the specified environment
    --- and returns function as a compile result.
    ---
    ---@param bytecode string The luajit bytecode chunk.
    ---@param env table | nil The environment of compiled function.
    ---@return function | nil fn The compiled function.
    ---@return string | nil msg The error message.
    local function loadbytecode( bytecode, env )
        local success, result = pcall( gmbc_load_bytecode, bytecode )
        if success then
            setfenv( result, env or getfenv( 2 ) )
            return result, nil
        else
            return nil, result
        end
    end

    std.loadbytecode = loadbytecode

    --- [SHARED AND MENU]
    ---
    --- Loads a file as
    --- a lua code chunk in the specified environment
    --- and returns function as a compile result.
    ---
    ---@param file_path string The path to the file to read.
    ---@param is_bytecode boolean If `true`, the file will be loaded as a bytecode chunk.
    ---@param env table | nil The environment of compiled function.
    ---@return function | nil fn The compiled function.
    ---@return string | nil msg The error message.
    function std.loadfile( file_path, is_bytecode, env )
        local success, content = pcall( file_read, file_path )
        if success then
            if env == nil then
                env = getfenv( 2 )
            end

            if is_bytecode then
                return loadbytecode( content, env )
            else
                return loadstring( content, file_path, env )
            end
        else
            return nil, content
        end
    end

end

do

    local loadstring = std.loadstring
    local math_floor = math.floor
    local math_max = math.max
    local arg = std.arg

    local empty_env = {}

    --- [SHARED AND MENU]
    ---
    --- Creates a function that accepts a variable
    --- number of arguments and returns them in
    --- the order of the specified indices.
    ---
    --- | `junction(...)` call | `fjn(...)` call | result `...` |
    --- | ---------------------|-----------------|--------------|
    --- | `junction(1)`        | `(A, B, C)`     | `A`          |
    --- | `junction(2)`        | `(A, B, C)`     | `B`          |
    --- | `junction(3)`        | `(A, B, C)`     | `C`          |
    --- | `junction(2, 1)`     | `(A, B, C)`     | `B, A`       |
    --- | `junction(3, 1, 2)`  | `(X, Y, Z)`     | `Z, X, Y`    |
    ---
    ---@param ... integer The indices of arguments to return.
    ---@return function fjn The created junction function.
    function std.junction( ... )
        local out_arg_count = select( '#', ... )
        local out_args = { ... }

        local in_arg_count = 0

        for i = 1, out_arg_count, 1 do
            local value = out_args[ i ]
            local valid, err_msg = arg( value, i, "number" )

            if valid then
                out_args[ i ] = math_floor( value )
                in_arg_count = math_max( in_arg_count, value )
            else
                error( err_msg, 2 )
            end
        end

        local locals, local_count = {}, 0

        for i = 1, in_arg_count, 1 do
            local_count = local_count + 1
            locals[ local_count ] = "a" .. i
        end

        local returns, return_count = {}, 0

        for i = 1, out_arg_count, 1 do
            return_count = return_count + 1
            returns[ return_count ] = "a" .. out_args[ i ]
        end

        local fn, err_msg = loadstring( "local " .. table_concat( locals, ",", 1, local_count ) .. " = ...\r\nreturn " .. table_concat( returns, ",", 1, return_count ), "junction", empty_env )
        if fn == nil then
            error( err_msg, 2 )
        end

        return fn
    end

end

--[[

    TODO:

    FileReader     FileWriter       __init( file_path: string )
    file.Reader            file.Writer

    NetworkReader  NetworkWriter    __init( network_name: string )
    network.Reader         network.Writer
    net.Reader             net.Writer

    network.Message
    NetworkMessage
    net.Message

    net.MessageReader       net.MessageWriter

]]
dofile( "std/http.lua" )
dofile( "std/http.github.lua" )

dofile( "std/steam.lua" )
dofile( "std/steam.identifier.lua" )
dofile( "std/steam.workshop.lua" )

dofile( "std/addon.lua" )

---@diagnostic disable-next-line: undefined-field
local glua_system = _G.system

if glua_system ~= nil then

    do

        local system_GetCountry = glua_system.GetCountry
        if system_GetCountry == nil then
            std.SYSTEM_COUNTRY = "gb"
        else
            function std_metatable.__indexes.SYSTEM_COUNTRY()
                local iso_3166_1_alpha_2 = string.lower( system_GetCountry() )
                std.SYSTEM_COUNTRY = iso_3166_1_alpha_2
                return iso_3166_1_alpha_2
            end
        end

    end

    if glua_system.BatteryPower ~= nil then

        local system_BatteryPower = glua_system.BatteryPower

        local battery_power = 0

        local function update_battery()
            if battery_power ~= system_BatteryPower() then
                battery_power = system_BatteryPower()
                if battery_power == 255 then
                    std.SYSTEM_HAS_BATTERY = false
                    std.SYSTEM_BATTERY_LEVEL = 100
                else
                    std.SYSTEM_HAS_BATTERY = true
                    std.SYSTEM_BATTERY_LEVEL = battery_power
                end
            end
        end

        update_battery()

        dreamwork.TickTimer1:attach( update_battery, "dreamwork::battery" )

    end

    if LUA_CLIENT_MENU then

        local system_HasFocus = glua_system.HasFocus
        if system_HasFocus ~= nil then

            ---@class dreamwork.std.window
            ---@field focus boolean `true` if the game's window has focus, `false` otherwise.
            local window = std.window

            local has_focus = system_HasFocus()
            window.focus = has_focus

            dreamwork.TickTimer0_05:attach( function()
                if has_focus ~= system_HasFocus() then
                    has_focus = not has_focus
                    window.focus = has_focus
                end
            end, "dreamwork::window_focus" )

        end

    end

end

dofile( "std/client.lua" )
dofile( "std/server.lua" )

if LUA_CLIENT_MENU then
    dofile( "std/menu.lua" )
    dofile( "std/window.lua" )
end

dofile( "std/level.lua" )

if LUA_CLIENT_SERVER then
    dofile( "std/physics.lua" )
    dofile( "std/model.lua" )

    dofile( "std/entity.lua" )
    -- dofile( "std/player.lua" ) -- deprecated, must be replaced in future with basic player controller

    dofile( "std/network.lua" )
end

-- TODO: NetTable class
dofile( "std/input.lua" )

if std.LUA_VERSION ~= "Lua 5.1" then
    logger:warn( "Lua version changed, possible unpredictable behavior. (" .. std.LUA_VERSION .. ")" )
end

if LUA_CLIENT_SERVER then
    dofile( "transport.lua" )
end

logger:info( "Start-up time: %.2f ms.", (os_clock() - dreamwork.StartTime) * 1000 )

dreamwork.storage.init()

if LUA_CLIENT_SERVER then
    logger:info( "Preparing the transport to begin connection..." )
    dreamwork.transport.startup()
end

do
    local start_time = os_clock()
    std.gc.collect()
    logger:info( "Clean-up time: %.2f ms.", (os_clock() - start_time) * 1000 )
end

-- TODO: package manager start-up ( aka package loading )

-- TODO: put https://wiki.facepunch.com/gmod/Global.IsFirstTimePredicted somewhere
-- TODO: put https://wiki.facepunch.com/gmod/Global.RecipientFilter somewhere
-- TODO: put https://wiki.facepunch.com/gmod/Global.ClientsideScene somewhere
-- TODO: put https://wiki.facepunch.com/gmod/util.ScreenShake somewhere
-- TODO: put https://wiki.facepunch.com/gmod/Global.AddonMaterial somewhere
-- TODO: put _G.util.ScreenShake somewhere or remove

-- TODO: Write "VideoRecorder" class ( https://wiki.facepunch.com/gmod/video.Record )

--[[

    TODO: return missing functions

    -- dofile - missing in glua
    -- require - broken in glua

]]


-- TODO: plugins support
--[[

    -- TODO

    concepts

    local utf8 = import "utf8"
    local custom_utf8 = import "package.utf8"

    local ... = dofile( "./path.to.lua", ... )


                            gmod <-------\

                            /\          ||
                            ||          ||

    [ LAYER 1 ] - dreamwork.std -> dreamwork.engine

        /\
        ||

    [ LAYER 2 ] - package with __package object

        /\
        ||

    [ LAYER 3 ] - file/module with __dir and __file objects

    {

        dependencies:
            cool_lib: >= 1.0.0

    }

    local cool_lib = import "cool_lib"

    dofile( "file.lua" ) - ./file.lua

    dofile( "/garrysmod/gamemodes/sandbox/file.lua" )




    Addon 1:

        MY_LIST = {}


    Addon 2:

        local addon1 = import "addon1"

        local lst = addon1.MY_LIST

        lst[ #lst + 1 ] = "addon2"


]]
