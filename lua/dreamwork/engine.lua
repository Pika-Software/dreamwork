local _G = _G

---@class dreamwork
local dreamwork = _G.dreamwork

local std = dreamwork.std

local math = std.math
local debug = std.debug
local string = std.string

local MENU = std.MENU
local raw_pairs = std.raw.pairs
local debug_fempty = debug.fempty
local setmetatable = std.setmetatable
local table_insert = std.table.insert
local detour_attach = dreamwork.detour.attach

local transducers = dreamwork.transducers

local gameevent_Listen
if _G.gameevent == nil then
    gameevent_Listen = debug_fempty
else
    gameevent_Listen = _G.gameevent.Listen or debug_fempty
end

--- [SHARED AND MENU]
---
--- Source engine library.
---
---@class dreamwork.engine
---@field SupportedGames table<integer, dreamwork.engine.GameInfo> The list of games that are currently supported by the engine.
---@field GameList dreamwork.engine.GameInfo[] The list of currently mounted games.
---@field GameCount integer The length of the `GameList` array (`#GameList`).
---@field GameHash table<integer, dreamwork.engine.GameInfo> The hash of currently mounted games.
---@field AddonList dreamwork.engine.AddonInfo[] The list of currently mounted addons.
---@field AddonCount integer The length of the `AddonList` array (`#AddonList`).
---@field AddonHash table<string, dreamwork.engine.AddonInfo> The hash of currently mounted addons.
local engine = dreamwork.engine or {}
dreamwork.engine = engine

if engine.hookCatch == nil then

    local engine_hooks = {}

    local custom_calls = {
        AcceptInput = function( self, entity, input, activator, caller, value )
            entity, activator, caller = transducers[ entity ], transducers[ activator ], transducers[ caller ]

            for i = 1, #self, 1 do
                local allow = self[ i ]( entity, input, activator, caller, value )
                if allow ~= nil then return not allow end
            end
        end
    }

    do

        local metatable = {
            __call = function( self, ... )
                for i = 1, #self, 1 do
                    local a, b, c, d, e, f = self[ i ]( ... )
                    if a ~= nil then return a, b, c, d, e, f end
                end
            end
        }

        --- [SHARED AND MENU]
        ---
        --- Adds a callback to the `hookCatch` event.
        ---
        ---@param event_name string
        ---@param fn dreamwork.std.Hook | fun( ... ): ...
        ---@param index integer
        function engine.hookCatch( event_name, fn, index )
            local lst = engine_hooks[ event_name ]
            if lst == nil then
                lst = {}

                if custom_calls[ event_name ] == nil then
                    setmetatable( lst, metatable )
                else
                    setmetatable( lst, {
                        __call = custom_calls[ event_name ]
                    } )
                end

                engine_hooks[ event_name ] = lst
            end

            lst[ index ] = fn
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Calls a source engine event.
    ---
    ---@param event_name string
    ---@param ... any
    ---@return any, any, any, any, any, any
    local function engine_hookCall( event_name, ... )
        local lst = engine_hooks[ event_name ]
        if lst ~= nil then
            return lst( ... )
        end
    end

    engine.hookCall = engine_hookCall

    do

        local hook = _G.hook
        if hook == nil then
            ---@diagnostic disable-next-line: inject-field
            hook = {}; _G.hook = hook
        end

        if hook.Call == nil then
            ---@diagnostic disable-next-line: duplicate-set-field
            function hook.Call( event_name, _, ... )
                local lst = engine_hooks[ event_name ]
                if lst == nil then return end
                return lst( ... )
            end
        else
            hook.Call = detour_attach( hook.Call, function( fn, event_name, gamemode_table, ... )
                local lst = engine_hooks[ event_name ]
                if lst ~= nil then
                    local a, b, c, d, e, f = lst( ... )
                    if a ~= nil then
                        return a, b, c, d, e, f
                    end
                end

                return fn( event_name, gamemode_table, ... )
            end )
        end

    end

    if MENU then

        do

            local function listAddonPresets()
                engine_hookCall( "AddonPresetsLoaded", _G.LoadAddonPresets() )
            end

            if _G.ListAddonPresets == nil then
                _G.ListAddonPresets = listAddonPresets
            else
                _G.ListAddonPresets = detour_attach( _G.ListAddonPresets, function( fn )
                    listAddonPresets()
                    return fn()
                end )
            end

        end

        do

            ---@param server_name string
            ---@param loading_url string
            ---@param map_name string
            ---@param max_players integer
            ---@param player_steamid64 string
            ---@param gamemode_name string
            local function gameDetails( server_name, loading_url, map_name, max_players, player_steamid64, gamemode_name )
                engine_hookCall( "GameDetails", {
                    server_name = server_name,
                    loading_url = loading_url,
                    map_name = map_name,
                    max_players = max_players,
                    player_steamid64 = player_steamid64,
                    gamemode_name = gamemode_name
                } )
            end

            if _G.GameDetails == nil then
                _G.GameDetails = gameDetails
            else
                _G.GameDetails = detour_attach( _G.GameDetails, function( fn, ... )
                    gameDetails( ... )
                    return fn( ... )
                end )
            end

        end

    end

end

local engine_hookCall = engine.hookCall

local create_catch_fn
do

    local math_clamp = math.clamp

    ---@param lst table
    function create_catch_fn( lst )
        ---@param fn dreamwork.std.Hook | function
        ---@param priority integer | nil
        return function( fn, priority )
            if priority == nil then
                table_insert( lst, #lst + 1, fn )
            else
                table_insert( lst, math_clamp( priority, 1, #lst + 1 ), fn )
            end
        end
    end

end

if engine.consoleCommandCatch == nil then

    local lst = {}

    ---@alias dreamwork.engine.consoleCommandCatch_fn fun( ply: Player, cmd: string, args: string[], argument_string: string ): boolean?

    --- [SHARED AND MENU]
    ---
    --- Adds a callback to the `consoleCommandCatch` event.
    ---
    ---@overload fun( fn: dreamwork.std.Hook | dreamwork.engine.consoleCommandCatch_fn, priority?: integer )
    engine.consoleCommandCatch = create_catch_fn( lst )

    ---@param ply Player
    ---@param cmd string
    ---@param args string[]
    ---@param argument_string string
    local function run_callbacks( ply, cmd, args, argument_string )
        for i = 1, #lst, 1 do
            local result = lst[ i ]( ply, cmd, args, argument_string )
            if result ~= nil then
                return result ~= false
            end
        end

        return nil
    end

    local concommand = _G.concommand
    if concommand == nil then
        ---@diagnostic disable-next-line: inject-field
        concommand = {}; _G.concommand = concommand
    end

    if concommand.Run == nil then
        ---@diagnostic disable-next-line: duplicate-set-field
        function concommand.Run( ply, cmd, args, argument_string )
            local exists = run_callbacks( ply, cmd, args, argument_string ) == true

            if not exists then
                dreamwork.Logger:error( "Catched attempt to run unknown console command: '%s'", cmd )
            end

            return exists
        end
    else
        concommand.Run = detour_attach( concommand.Run, function( fn, ply, cmd, args, argument_string )
            local result = run_callbacks( ply, cmd, args, argument_string )
            if result == nil then
                return fn( ply, cmd, args, argument_string )
            else
                return result
            end
        end )
    end

end

if engine.consoleCommandAutoCompleteCatch == nil then

    local lst = {}

    ---@alias dreamwork.engine.consoleCommandAutoCompleteCatch_fn fun( cmd: string, argument_string: string, args: string[] ): string[]?

    --- [SHARED AND MENU]
    ---
    --- Adds a callback to the `consoleCommandAutoCompleteCatch` event.
    ---
    ---@overload fun( fn: dreamwork.std.Hook | dreamwork.engine.consoleCommandAutoCompleteCatch_fn, priority?: integer )
    engine.consoleCommandAutoCompleteCatch = create_catch_fn( lst )

    local function run_callbacks( cmd, argument_string, args )
        for i = 1, #lst, 1 do
            local result = lst[ i ]( cmd, argument_string, args )
            if result ~= nil then
                return result
            end
        end
    end

    local concommand = _G.concommand
    if concommand == nil then
        ---@diagnostic disable-next-line: inject-field
        concommand = {}; _G.concommand = concommand
    end

    if concommand.AutoComplete == nil then
        concommand.AutoComplete = run_callbacks
    else
        concommand.AutoComplete = detour_attach( concommand.AutoComplete, function( fn, cmd, argument_string, args )
            local result = run_callbacks( cmd, argument_string, args )
            if result == nil then
                return fn( cmd, argument_string, args )
            else
                return result
            end
        end )
    end

end

if engine.consoleVariableGet == nil or engine.consoleVariableCreate == nil or engine.consoleVariableExists == nil then

    local GetConVar_Internal = _G.GetConVar_Internal or debug_fempty
    local ConVarExists = _G.ConVarExists or debug_fempty
    local CreateConVar = _G.CreateConVar or debug_fempty

    ---@type table<string, ConVar>
    local cache = {}

    debug.gc.setTableRules( cache, false, true )

    --- [SHARED AND MENU]
    ---
    --- Get console variable C object (userdata).
    ---
    ---@param name string The name of the console variable.
    ---@return ConVar? cvar The console variable object.
    function engine.consoleVariableGet( name )
        local value = cache[ name ]
        if value == nil then
            value = GetConVar_Internal( name )
            cache[ name ] = value
        end

        return value
    end

    --- [SHARED AND MENU]
    ---
    --- Create console variable C object (userdata).
    ---
    ---@param name string The name of the console variable.
    ---@param default string The default value of the console variable.
    ---@param flags? integer The flags of the console variable.
    ---@param description? string The description of the console variable.
    ---@param min? number The minimum value of the console variable.
    ---@param max? number The maximum value of the console variable.
    ---@return ConVar? cvar The console variable object.
    function engine.consoleVariableCreate( name, default, flags, description, min, max )
        local value = cache[ name ]
        if value == nil then
            ---@diagnostic disable-next-line: param-type-mismatch
            value = CreateConVar( name, default, flags, description, min, max )
            cache[ name ] = value
        end

        return value
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if the console variable exists.
    ---
    ---@param name string The name of the console variable.
    ---@return boolean exists `true` if the console variable exists, `false` otherwise.
    function engine.consoleVariableExists( name )
        return cache[ name ] ~= nil or ConVarExists( name )
    end

end

if engine.consoleCommandRegister == nil or engine.consoleCommandExists == nil then

    local commands = {}

    if _G.AddConsoleCommand == nil then
        _G.AddConsoleCommand = debug_fempty
    else
        _G.AddConsoleCommand = detour_attach( _G.AddConsoleCommand, function( fn, name, description, flags )
            if commands[ name ] == nil then
                commands[ name ] = true
                fn( name, description, flags )
            end
        end )
    end

    engine.consoleCommandRegister = _G.AddConsoleCommand

    --- [SHARED AND MENU]
    ---
    --- Checks if the console command exists.
    ---
    ---@param name string The name of the console command.
    ---@return boolean exists `true` if the console command exists, `false` otherwise.
    function engine.consoleCommandExists( name )
        return commands[ name ] ~= nil
    end

end

if engine.consoleCommandRun == nil then

    --- [SHARED AND MENU]
    ---
    --- Run console command.
    ---
    ---@param name string The name of the console command.
    ---@param ... string? The arguments of the console command.
    engine.consoleCommandRun = _G.RunConsoleCommand or function( name, ... )
        std.print( "engine.consoleCommandRun", name, ... )
    end

end

if engine.consoleVariableCatch == nil then

    local lst = {}

    --- [SHARED AND MENU]
    ---
    --- Adds a callback to the `consoleVariableCatch` event.
    ---
    ---@overload fun( fn: dreamwork.std.Hook | fun( str_name: string, str_old: string, str_new: string ), priority?: integer ): dreamwork.std.Hook
    engine.consoleVariableCatch = create_catch_fn( lst )

    ---@param str_name string
    ---@param str_old string
    ---@param str_new string
    local function run_callbacks( str_name, str_old, str_new )
        for i = 1, #lst, 1 do
            lst[ i ]( str_name, str_old, str_new )
        end
    end

    local cvars = _G.cvars
    if cvars == nil then
        ---@diagnostic disable-next-line: inject-field
        cvars = {}; _G.cvars = cvars
    end

    if cvars.OnConVarChanged == nil then
        cvars.OnConVarChanged = run_callbacks
    else
        cvars.OnConVarChanged = detour_attach( cvars.OnConVarChanged, function( fn, str_name, str_old, str_new )
            run_callbacks( str_name, str_old, str_new )
            return fn( str_name, str_old, str_new )
        end )
    end

    gameevent_Listen( "server_cvar" )

    local engine_consoleVariableGet = engine.consoleVariableGet
    local values = {}

    engine.hookCatch( "server_cvar", function( data )
        local str_name, str_new = data.cvarname, data.cvarvalue

        local str_old = values[ str_name ]
        if str_old == nil then
            local convar = engine_consoleVariableGet( str_name )
            if convar == nil then return end

            str_old = convar:GetDefault()
            values[ str_name ] = str_old
        else
            values[ str_name ] = str_new
        end

        run_callbacks( str_name, str_old, str_new )
    end, 1 )

end

do

    local string_sub, string_len = string.sub, string.len
    local Msg = _G.Msg or std.print
    local math_min = math.min
    local MsgC = _G.MsgC

    --- [SHARED AND MENU]
    ---
    --- Prints the given arguments to the console.
    ---
    ---@param str string The string to print.
    function engine.consoleMessage( str )
        local index, str_length = 1, string_len( str )

        while str_length ~= 0 do
            -- https://developer.valvesoftware.com/wiki/Developer_Console_Control
            -- by Retr0 ( 989 characters per message )
            local segment_length = math_min( 989, str_length )
            Msg( string_sub( str, index, index + segment_length ) )
            str_length = str_length - segment_length
            index = index + segment_length
        end
    end

    if MsgC == nil then

        engine.consoleMessageColored = engine.consoleMessage

    else

        local white_color = std.Color.scheme.white

        --- [SHARED AND MENU]
        ---
        --- Prints the given arguments to the console.
        ---
        ---@param str string The string to print.
        ---@param color dreamwork.std.Color The color to print the string with.
        ---@diagnostic disable-next-line: duplicate-set-field
        function engine.consoleMessageColored( str, color )
            local index, str_length = 1, string_len( str )

            if color == nil then
                color = white_color
            end

            while str_length ~= 0 do
                -- https://developer.valvesoftware.com/wiki/Developer_Console_Control
                -- by Retr0 ( 989 characters per message )
                local segment_length = math_min( 989, str_length )
                MsgC( color, string_sub( str, index, index + segment_length ) )
                str_length = str_length - segment_length
                index = index + segment_length
            end
        end

    end

end

if engine.entityCreationCatch == nil then

    local lst = {}

    ---@alias dreamwork.engine.entityCreationCatch_fn fun( name: string ): table | nil

    --- [SHARED AND MENU]
    ---
    --- Adds a callback to the `entityCreationCatch` event.
    ---
    ---@overload fun( fn: dreamwork.std.Hook | dreamwork.engine.entityCreationCatch_fn, priority?: integer ): dreamwork.std.Hook
    engine.entityCreationCatch = create_catch_fn( lst )

    ---@param name string
    local function run_callbacks( name )
        for i = 1, #lst, 1 do
            local tbl = lst[ i ]( name )
            if tbl ~= nil then
                return tbl
            end

            return nil
        end
    end

    local scripted_ents = _G.scripted_ents
    if scripted_ents == nil then
        ---@diagnostic disable-next-line: inject-field
        scripted_ents = {}; _G.scripted_ents = scripted_ents
    end

    if scripted_ents.Get == nil then
        scripted_ents.Get = run_callbacks
    else
        scripted_ents.Get = detour_attach( scripted_ents.Get, function( fn, name )
            local tbl = run_callbacks( name )
            if tbl == nil then
                return fn( name )
            else
                return tbl
            end
        end )
    end

    if scripted_ents.OnLoaded == nil then
        ---@diagnostic disable-next-line: duplicate-set-field
        function scripted_ents.OnLoaded( name )
            engine_hookCall( "EntityLoaded", name )
        end
    else
        scripted_ents.OnLoaded = detour_attach( scripted_ents.OnLoaded, function( fn, name )
            engine_hookCall( "EntityLoaded", name )
            return fn( name )
        end )
    end

end

if engine.weaponCreationCatch == nil then

    local lst = {}

    ---@alias dreamwork.engine.weaponCreationCatch_fn fun( name: string ): table | nil

    --- [SHARED AND MENU]
    ---
    --- Adds a callback to the `weaponCreationCatch` event.
    ---
    ---@overload fun( fn: dreamwork.std.Hook | dreamwork.engine.weaponCreationCatch_fn, priority?: integer ): dreamwork.std.Hook
    engine.weaponCreationCatch = create_catch_fn( lst )

    ---@param name string
    local function run_callbacks( name )
        for i = 1, #lst, 1 do
            local tbl = lst[ i ]( name )
            if tbl ~= nil then
                return tbl
            end
        end
    end

    local weapons = _G.weapons
    if weapons == nil then
        ---@diagnostic disable-next-line: inject-field
        weapons = {}; _G.weapons = weapons
    end

    if weapons.Get == nil then

        weapons.Get = run_callbacks

    else

        weapons.Get = detour_attach( weapons.Get, function( fn, name )
            local tbl = run_callbacks( name )
            if tbl == nil then
                return fn( name )
            else
                return tbl
            end
        end )

    end

    if weapons.OnLoaded == nil then

        ---@param name string
        ---@diagnostic disable-next-line: duplicate-set-field
        function weapons.OnLoaded( name )
            engine_hookCall( "WeaponLoaded", name )
        end

    else

        ---@param name string
        weapons.OnLoaded = detour_attach( weapons.OnLoaded, function( fn, name )
            engine_hookCall( "WeaponLoaded", name )
            return fn( name )
        end )

    end

end

if engine.effectCreationCatch == nil then

    local lst = {}

    ---@alias dreamwork.engine.effectCreationCatch_fn fun( name: string ): table | nil

    --- [SHARED AND MENU]
    ---
    --- Adds a callback to the `effectCreationCatch` event.
    ---
    ---@overload fun( fn: dreamwork.std.Hook | dreamwork.engine.effectCreationCatch_fn, priority?: integer ): dreamwork.std.Hook
    engine.effectCreationCatch = create_catch_fn( lst )

    ---@param name string
    local function run_callbacks( name )
        for i = 1, #lst, 1 do
            local tbl = lst[ i ]( name )
            if tbl ~= nil then
                return tbl
            end
        end
    end

    local effects = _G.effects
    if effects == nil then
        ---@diagnostic disable-next-line: inject-field
        effects = {}; _G.effects = effects
    end

    if effects.Create == nil then
        effects.Create = run_callbacks
    else
        effects.Create = detour_attach( effects.Create, function( fn, name )
            local tbl = run_callbacks( name )
            if tbl == nil then
                return fn( name )
            else
                return tbl
            end
        end )
    end

end

if engine.gamemodeCreationCatch == nil then

    local lst = {}

    ---@alias dreamwork.engine.gamemodeCreationCatch_fn fun( name: string ): table | nil

    --- [SHARED AND MENU]
    ---
    --- Adds a callback to the `gamemodeCreationCatch` event.
    ---
    ---@overload fun( fn: dreamwork.std.Hook | dreamwork.engine.gamemodeCreationCatch_fn, priority?: integer ): dreamwork.std.Hook
    engine.gamemodeCreationCatch = create_catch_fn( lst )

    local gamemode = _G.gamemode
    if gamemode == nil then
        ---@diagnostic disable-next-line: inject-field
        gamemode = {}; _G.gamemode = gamemode
    end

    if gamemode.Get == nil then

        local gamemodes = {}

        ---@param name string
        ---@diagnostic disable-next-line: duplicate-set-field
        function gamemode.Get( name )
            for i = 1, #lst, 1 do
                local tbl = lst[ i ]( name )
                if tbl ~= nil then
                    return tbl
                end
            end

            return gamemodes[ name ]
        end

        if gamemode.Register == nil then

            ---@param gm table
            ---@param name string
            ---@param base_name string
            ---@diagnostic disable-next-line: duplicate-set-field
            function gamemode.Register( gm, name, base_name )
                gamemodes[ name ] = {
                    FolderName = gm.FolderName,
                    Name = gm.Name or name,
                    Folder = gm.Folder,
                    Base = base_name
                }
            end

        end


    else

        gamemode.Get = detour_attach( gamemode.Get, function( fn, name )
            for i = 1, #lst, 1 do
                local tbl = lst[ i ]( name )
                if tbl ~= nil then
                    return tbl
                end
            end

            return fn( name )
        end )

        gamemode.Register = gamemode.Register or debug_fempty

    end

end

do

    local getGames, getAddons

    local glua_engine = _G.engine
    if glua_engine ~= nil then
        getGames = glua_engine.GetGames
        getAddons = glua_engine.GetAddons
    end

    if getGames == nil then
        getGames = debug_fempty
    end

    if getAddons == nil then
        getAddons = debug_fempty
    end

    ---@class dreamwork.engine.GameInfo
    ---@field depot integer The game's Steam Depot ID.
    ---@field folder string The game's mount folder name.
    ---@field title string The game's title.
    ---@field owned boolean Whether the game is owned or not.
    ---@field mounted boolean Whether the game is mounted or not.
    ---@field installed boolean Whether the game is installed or not.
    ---@field index integer The game's index in the game list.

    ---@class dreamwork.engine.AddonInfo
    ---@field downloaded boolean Whether the addon is downloaded or not.
    ---@field size integer The addon's size in bytes.
    ---@field file string The absolute path to the addon's `.gma` file.
    ---@field mounted boolean Whether the addon is mounted or not.
    ---@field updated integer The addon's last update time in Unix timestamp.
    ---@field models integer The addon's model count.
    ---@field title string The addon's title.
    ---@field tags string The addon's tags.
    ---@field wsid string The addon's Steam Workshop ID.
    ---@field timeadded integer The addon's time added, in Unix timestamp.
    ---@field index integer The addon's index in the addon list.
    ---@field folder string The addon's folder name.

    ---@type table<integer, dreamwork.engine.GameInfo>
    local supported_games = {}
    engine.SupportedGames = supported_games

    ---@type dreamwork.engine.GameInfo[], integer, table<integer, dreamwork.engine.GameInfo>
    local actual_game_list, actual_game_count, actual_game_hash = {}, 0, {}

    ---@type dreamwork.engine.AddonInfo[], integer, table<string, dreamwork.engine.AddonInfo>
    local actual_addon_list, actual_addon_count, actual_addon_hash = {}, 0, {}

    engine.GameList, engine.GameCount, engine.GameHash = actual_game_list, actual_game_count, actual_game_hash
    engine.AddonList, engine.AddonCount, engine.AddonHash = actual_addon_list, actual_addon_count, actual_addon_hash

    --- [SHARED AND MENU]
    ---
    --- Updates the game and addon lists and returns actual.
    ---
    ---@return integer game_changes The number of game content changes.
    ---@return integer addon_changes The number of addon content changes.
    function engine.SyncContent()
        ---@type dreamwork.engine.GameInfo[], dreamwork.engine.AddonInfo[]
        local game_list, addon_list = getGames() or {}, getAddons() or {}
        local game_count, addon_count = #game_list, #addon_list

        local game_hash, addon_hash = {}, {}

        -- Supported Games - Cleanup
        for app_id in raw_pairs( supported_games ) do
            supported_games[ app_id ] = nil
        end

        local game_changes = 0

        -- Mounted & Supported Games - Sync
        for i = 1, game_count, 1 do
            local game_info = game_list[ i ]
            game_info.index = i

            local app_id = game_info.depot
            supported_games[ app_id ] = game_info

            if game_info.installed and game_info.mounted then
                if actual_game_hash[ app_id ] == nil then
                    engine_hookCall( "GameMounted", game_info )
                    game_changes = game_changes + 1
                end

                game_hash[ app_id ] = game_info
            end
        end

        for i = 1, actual_game_count, 1 do
            local game_info = actual_game_list[ i ]
            if actual_addon_hash[ game_info.depot ] ~= nil and game_hash[ game_info.depot ] == nil then
                engine_hookCall( "GameUnmounted", game_info )
                game_changes = game_changes + 1
            end
        end

        -- Game List - Cleanup
        for i = 1, actual_game_count, 1 do
            actual_game_list[ i ] = nil
        end

        --- Game List - Sync
        actual_game_count = game_count

        for i = 1, game_count, 1 do
            actual_game_list[ i ] = game_list[ i ]
        end

        -- Game Hash - Cleanup
        for app_id in raw_pairs( actual_game_hash ) do
            actual_game_hash[ app_id ] = nil
        end

        -- Game Hash - Sync
        for app_id, game_info in raw_pairs( game_hash ) do
            actual_game_hash[ app_id ] = game_info
        end

        local addon_changes = 0

        -- Mounted Addons - Sync
        for i = 1, addon_count, 1 do
            local addon_info = addon_list[ i ]
            addon_info.index = i

            local addon_title = addon_info.title
            addon_hash[ addon_title ] = addon_info

            if addon_info.mounted and actual_addon_hash[ addon_title ] == nil then
                engine_hookCall( "AddonMounted", addon_info )
                addon_changes = addon_changes + 1
            end
        end

        for i = 1, actual_addon_count, 1 do
            local addon_info = actual_addon_list[ i ]
            if actual_game_hash[ addon_info.title ] ~= nil and addon_hash[ addon_info.title ] == nil then
                engine_hookCall( "AddonUnmounted", addon_info )
                addon_changes = addon_changes + 1
            end
        end

        -- Addon List - Cleanup
        for i = 1, actual_addon_count, 1 do
            actual_addon_list[ i ] = nil
        end

        -- Addon List - Sync
        actual_addon_count = addon_count

        for i = 1, addon_count, 1 do
            actual_addon_list[ i ] = addon_list[ i ]
        end

        -- Addon Hash - Cleanup
        for addon_title in raw_pairs( actual_addon_hash ) do
            actual_addon_hash[ addon_title ] = nil
        end

        -- Addon Hash - Sync
        for addon_title, addon_info in raw_pairs( addon_hash ) do
            actual_addon_hash[ addon_title ] = addon_info
        end

        return game_changes, addon_changes
    end

end

local entity_meta = debug.findmetatable( "Entity" )
if entity_meta == nil then
    entity_meta = {}
    debug.registermetatable( "Entity", entity_meta, true )
end

if entity_meta.__gc == nil then
    function entity_meta.__gc( entity_userdata )
        engine_hookCall( "EntityGC", entity_userdata )
    end
else
    entity_meta.__gc = detour_attach( entity_meta.__gc, function( fn, entity_userdata )
        engine_hookCall( "EntityGC", entity_userdata )
        fn( entity_userdata )
    end )
end

local player_meta = debug.findmetatable( "Player" )
if player_meta == nil then
    player_meta = {}
    debug.registermetatable( "Player", player_meta, true )
end

if player_meta.__gc == nil then
    function player_meta.__gc( player_userdata )
        engine_hookCall( "EntityGC", player_userdata )
    end
else
    player_meta.__gc = detour_attach( player_meta.__gc, function( fn, player_userdata )
        engine_hookCall( "EntityGC", player_userdata )
        fn( player_userdata )
    end )
end

local weapon_meta = debug.findmetatable( "Weapon" )
if weapon_meta == nil then
    weapon_meta = {}
    debug.registermetatable( "Weapon", weapon_meta, true )
end

if weapon_meta.__gc == nil then
    function weapon_meta.__gc( weapon_userdata )
        engine_hookCall( "EntityGC", weapon_userdata )
    end
else
    weapon_meta.__gc = detour_attach( weapon_meta.__gc, function( fn, weapon_userdata )
        engine_hookCall( "EntityGC", weapon_userdata )
        fn( weapon_userdata )
    end )
end

local vehicle_meta = debug.findmetatable( "Vehicle" )
if vehicle_meta == nil then
    vehicle_meta = {}
    debug.registermetatable( "Vehicle", vehicle_meta, true )
end

if vehicle_meta.__gc == nil then
    function vehicle_meta.__gc( vehicle_userdata )
        engine_hookCall( "EntityGC", vehicle_userdata )
    end
else
    vehicle_meta.__gc = detour_attach( vehicle_meta.__gc, function( fn, vehicle_userdata )
        engine_hookCall( "EntityGC", vehicle_userdata )
        fn( vehicle_userdata )
    end )
end

local npc_meta = debug.findmetatable( "NPC" )
if npc_meta == nil then
    npc_meta = {}
    debug.registermetatable( "NPC", npc_meta, true )
end

if npc_meta.__gc == nil then
    function npc_meta.__gc( npc_userdata )
        engine_hookCall( "EntityGC", npc_userdata )
    end
else
    npc_meta.__gc = detour_attach( npc_meta.__gc, function( fn, npc_userdata )
        engine_hookCall( "EntityGC", npc_userdata )
        fn( npc_userdata )
    end )
end

local nextbot_meta = debug.findmetatable( "NextBot" )
if nextbot_meta == nil then
    nextbot_meta = {}
    debug.registermetatable( "NextBot", nextbot_meta, true )
end

if nextbot_meta.__gc == nil then
    function nextbot_meta.__gc( nextbot_userdata )
        engine_hookCall( "EntityGC", nextbot_userdata )
    end
else
    nextbot_meta.__gc = detour_attach( nextbot_meta.__gc, function( fn, nextbot_userdata )
        engine_hookCall( "EntityGC", nextbot_userdata )
        fn( nextbot_userdata )
    end )
end

local glua_util = _G.util

if std.SHARED and engine.networkRegister == nil then

    local add_fn = glua_util ~= nil and glua_util.AddNetworkString or debug_fempty
    local get_id_fn = glua_util ~= nil and glua_util.NetworkStringToID or debug_fempty
    local get_name_fn = glua_util ~= nil and glua_util.NetworkIDToString or debug_fempty

    ---@type table<string, integer>
    local id2name = {}

    ---@type table<integer, string>
    local name2id = {}

    setmetatable( id2name, {
        __index = function( _, name )
            local id = get_id_fn( name ) or 0

            if id ~= 0 then
                id2name[ name ] = id
                name2id[ id ] = name
            end

            return id
        end
    } )

    setmetatable( name2id, {
        __index = function( _, id )
            local name = get_name_fn( id )

            if name ~= nil then
                id2name[ name ] = id
                name2id[ id ] = name
            end

            return name
        end
    } )

    --- [SHARED AND MENU]
    ---
    --- Get all the registered networks.
    ---
    ---@return string[] networks The registered networks.
    function engine.getNetworks()
        local lst = {}

        for name in raw_pairs( id2name ) do
            lst[ #lst + 1 ] = name
        end

        return lst
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if the network exists.
    ---
    ---@return boolean exists `true` if the network exists, `false` otherwise.
    function engine.networkMessageExists( name )
        return id2name[ name ] ~= 0
    end

    --- [SHARED AND MENU]
    ---
    --- Get the ID of the network from its name.
    ---
    ---@param name string The name of the network.
    ---@return integer | nil id The ID of the network, or `nil` if the network does not exist.
    function engine.networkGetID( name )
        local id = id2name[ name ]
        if id ~= 0 then
            return id
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Get the name of the network from its ID.
    ---
    ---@param id integer The ID of the network message.
    ---@return string | nil name The name of the network message, or `nil` if the network message does not exist.
    function engine.networkGetName( id )
        return name2id[ id ]
    end

    --- [SHARED AND MENU]
    ---
    --- Registers a network.
    ---
    function engine.networkRegister( name )
        if id2name[ name ] == 0 then
            local id = add_fn( name ) or 0
            name2id[ id ] = name
            id2name[ name ] = id
        end
    end

end

if glua_util ~= nil then
    engine.MD5 = glua_util.MD5
    engine.CRC32 = glua_util.CRC
    engine.SHA1 = glua_util.SHA1
    engine.SHA256 = glua_util.SHA256
end

if engine.loadMaterial == nil then

    ---@alias dreamwork.engine.ImageParameters
    ---| `1` Makes the created material a `VertexLitGeneric`, so it can be applied to models. Default shader is `UnlitGeneric`.
    ---| `2` Sets the `$nocull` to `1` in the created material.
    ---| `4` Sets the `$alphatest` to `1` in the created material instead of `$vertexalpha` being set to `1`.
    ---| `8` Generates Mipmaps for the imported texture, or sets **No Level Of Detail** and **No Mipmaps** if unset. This adjusts the material's dimensions to a power of 2.
    ---| `16` Makes the image able to tile when used with non standard UV maps. Sets the `CLAMPS` and `CLAMPT` flags if unset.
    ---| `32` If set does nothing, if unset - enables **Point Sampling (Texture Filtering)** on the material as well as adds the **No Level Of Detail** flag to it.
    ---| `64` If set, the material will be given `$ignorez` flag, which is necessary for some rendering operations, such as render targets and 3d2d rendering.
    ---| `128` Unused.
    ---| integer

    local material_fn = _G.Material
    local upvalues = debug.getupvalues( material_fn )

    if upvalues.C_Material == nil then

        local bitpack = std.pack.bits
        local bitpack_toString = bitpack.toString
        local bitpack_writeUInt = bitpack.writeUInt

        --- [SHARED AND MENU]
        ---
        --- Loads a material from the file.
        ---
        ---@param file_path string The path to the file to read.
        ---@param parameters dreamwork.engine.ImageParameters The parameters.
        ---@return IMaterial material The material.
        ---@return number time_taken The time taken to load the material.
        function engine.loadMaterial( file_path, parameters )
            return material_fn( file_path, bitpack_toString( bitpack_writeUInt( parameters, 8 ), 8, false ) )
        end

    else
        engine.loadMaterial = upvalues.C_Material
    end

end

-- TODO: matproxy
-- TODO: effects | particles?
