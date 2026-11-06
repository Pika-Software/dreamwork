---@class dreamwork.engine
local dreamwork_engine = dreamwork.engine
local engine_ConsoleVariable = dreamwork_engine.ConsoleVariable

local hook = dreamwork_engine.hook
local hook_call = hook.call
local hook_catch = hook.catch

local std = dreamwork.std

local raw = std.raw
local raw_get = raw.get
local raw_pairs = raw.pairs

local debug = std.debug
local debug_fempty = debug.fempty

local setmetatable = std.setmetatable
local error = std.error
local pcall = std.pcall


---@class dreamwork.engine.console
local console = {}
dreamwork_engine.console = console


--- [SHARED AND MENU]
---
--- Names of known Source engine and Garry's Mod console variables.
---
---@type string[]
local engine_variables = {
    -- server
    "hostname", "hostport", "hostip", "sv_password", "rcon_password", "sv_lan", "sv_region",
    "sv_tags", "sv_contact", "sv_visiblemaxplayers", "sv_loadingurl", "sv_downloadurl",
    "sv_allowupload", "sv_allowdownload", "sv_allowcslua", "sv_cheats", "sv_pausable",
    "sv_hibernate_think", "sv_timeout", "sv_kickerrornum", "sv_logecho", "sv_logfile",
    "sv_log_onefile", "sv_logbans", "sv_rcon_banpenalty", "sv_rcon_maxfailures",
    "sv_rcon_minfailures", "sv_rcon_minfailuretime", "sv_skyname", "gamemode",
    "skill", "deathmatch", "coop",

    -- networking
    "sv_minrate", "sv_maxrate", "sv_mincmdrate", "sv_maxcmdrate", "sv_minupdaterate",
    "sv_maxupdaterate", "sv_client_min_interp_ratio", "sv_client_max_interp_ratio",
    "sv_unlag", "sv_maxunlag", "net_maxfilesize",
    "rate", "cl_cmdrate", "cl_updaterate", "cl_interp", "cl_interp_ratio",
    "cl_predict", "cl_smooth", "cl_timeout", "cl_downloadfilter",

    -- movement & physics
    "sv_gravity", "sv_friction", "sv_stopspeed", "sv_accelerate", "sv_airaccelerate",
    "sv_wateraccelerate", "sv_waterfriction", "sv_maxvelocity", "sv_stepsize", "sv_bounce",
    "sv_rollangle", "sv_rollspeed", "sv_noclipspeed", "sv_noclipaccelerate",
    "sv_specaccelerate", "sv_specspeed", "sv_specnoclip", "sv_sticktoground",
    "sv_footsteps", "sv_playerpickupallowed", "sv_defaultdeployspeed",
    "sv_infinite_aux_power", "sv_robust_explosions",
    "phys_timescale", "phys_pushscale", "phys_impactforcescale", "phys_upimpactforcescale",
    "gmod_physiterations", "host_timescale", "host_framerate",

    -- gameplay
    "mp_falldamage", "mp_flashlight", "mp_footsteps", "mp_friendlyfire", "mp_forcecamera",
    "mp_timelimit", "mp_fraglimit", "mp_decals", "mp_show_voice_icons",
    "sv_alltalk", "sv_voiceenable", "sv_voicecodec",
    "ai_disabled", "ai_ignoreplayers", "ai_serverragdolls", "g_ragdoll_maxcount",
    "gmod_suit", "gmod_maxammo", "gmod_npcweapon",

    -- physgun
    "physgun_limited", "physgun_maxrange", "physgun_maxspeed", "physgun_maxangular",
    "physgun_timetoarrive", "physgun_DampingFactor", "physgun_teleportDistance",
    "physgun_wheelspeed", "physgun_halo", "physgun_drawbeams",

    -- sandbox
    "sbox_noclip", "sbox_godmode", "sbox_playershurtplayers", "sbox_weapons", "sbox_persist",
    "sbox_bonemanip_npc", "sbox_bonemanip_player", "sbox_bonemanip_misc",
    "sbox_maxprops", "sbox_maxragdolls", "sbox_maxvehicles", "sbox_maxeffects",
    "sbox_maxballoons", "sbox_maxnpcs", "sbox_maxdynamite", "sbox_maxlamps", "sbox_maxlights",
    "sbox_maxwheels", "sbox_maxthrusters", "sbox_maxhoverballs", "sbox_maxbuttons",
    "sbox_maxemitters", "sbox_maxsents", "sbox_maxcameras", "sbox_maxconstraints",
    "sbox_maxropeconstraints",

    -- player
    "name", "cl_playermodel", "cl_playercolor", "cl_weaponcolor", "cl_playerskin",
    "cl_playerbodygroups", "gmod_language", "gmod_toolmode", "gmod_drawhelp",
    "gmod_drawtooleffects",

    -- input
    "sensitivity", "m_pitch", "m_yaw", "m_filter", "m_rawinput",
    "cl_forwardspeed", "cl_sidespeed", "cl_backspeed", "cl_upspeed",
    "cl_yawspeed", "cl_pitchspeed",

    -- audio & voice
    "volume", "snd_musicvolume", "voice_enable", "voice_scale", "voice_loopback",

    -- video & rendering
    "fps_max", "fov_desired", "cl_drawhud", "cl_showfps", "cl_showpos", "net_graph",
    "cl_new_impact_effects", "mat_fullbright", "mat_wireframe", "mat_monitorgamma",
    "mat_picmip", "mat_specular", "mat_bloomscale", "mat_hdr_level", "mat_queue_mode",
    "r_3dsky", "r_drawviewmodel", "r_shadows", "r_decals", "r_drawdetailprops", "r_lod",
    "r_rootlod", "r_eyes", "r_teeth", "r_flex", "r_dynamic", "r_waterforceexpensive",
    "r_queued_ropes",

    -- multicore
    "gmod_mcore_test", "cl_threaded_bone_setup", "cl_threaded_client_leaf_system",
    "studio_queue_mode",

    -- console
    "developer", "con_enable", "con_drawnotify", "con_filter_enable",
    "con_filter_text", "con_filter_text_out"
}

engine_variables[ 0 ] = #engine_variables
console.EngineVariables = engine_variables

do

    local IsConCommandBlocked = IsConCommandBlocked or function() return false end
    local AddConsoleCommand = AddConsoleCommand or debug_fempty
    local RunConsoleCommand = RunConsoleCommand or function( name, ... )
        raw.print( "dreamwork.engine.console.execute", name, ... )
    end

    --- [SHARED AND MENU]
    ---
    --- Run console command.
    ---
    ---@overload fun( name: string, ...: string? )
    console.commandRun = RunConsoleCommand

    ---@type table<string, boolean>
    local exists_commands = {}

    ---@type table<string, boolean>
    local blocked_commands = {}

    setmetatable( blocked_commands, {
        ---@param self table<string, boolean>
        ---@param name string
        __index = function( self, name )
            local is_blocked = IsConCommandBlocked( name ) == true
            self[ name ] = is_blocked
            return is_blocked
        end,
    } )

    --- [SHARED AND MENU]
    ---
    --- Checks if the console command was registered through `engine.consoleCommandRegister`.
    ---
    --- This only knows about commands registered through this module, not commands that are
    --- built into the engine or were added by other code, so a `false` result doesn't mean the
    --- command doesn't exist in the engine.
    ---
    ---@param name string The name of the console command.
    ---@return boolean exists `true` if the console command was registered through this module, `false` otherwise.
    ---@nodiscard
    function console.commandExists( name )
        return exists_commands[ name ] ~= nil
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if the console command is blocked, as reported by the engine's
    --- `IsConCommandBlocked` (the engine's list of commands it refuses to run from Lua).
    ---
    --- The answer for each name is cached after the first check. Where `IsConCommandBlocked`
    --- isn't available, nothing is considered blocked.
    ---
    ---@param name string The name of the console command.
    ---@return boolean blocked `true` if the console command is blocked, `false` otherwise.
    ---@nodiscard
    function console.commandBlocked( name )
        return blocked_commands[ name ]
    end

    --- [SHARED AND MENU]
    ---
    --- Tells the engine to register a console command.
    ---
    --- Registering is only done once per name: if the command was already registered through
    --- this function, the call does nothing, and the new `description` and `flags` are ignored.
    ---
    ---@param name string The name of the console command.
    ---@param description string The description of the console command.
    ---@param flags integer The bit flags of the console command (a combination of `FCVAR_*` values).
    function console.commandRegister( name, description, flags )
        if exists_commands[ name ] == nil then
            AddConsoleCommand( name, description, flags )
            exists_commands[ name ] = true
        end
    end

end

do

    local ConVarExists = ConVarExists or debug_fempty
    local CreateConVar = CreateConVar or debug_fempty

    local get_console_variable
    local set_console_variable
    local remove_console_variable

    local cvar = cvar
    if cvar ~= nil then
        get_console_variable = cvar.Find
        set_console_variable = cvar.SetValue
        remove_console_variable = cvar.Unregister
    end

    if get_console_variable == nil then
        get_console_variable = GetConVar_Internal or GetConVar or debug_fempty
    end

    if remove_console_variable == nil then
        remove_console_variable = debug_fempty
    end

    --- [SHARED AND MENU]
    ---
    --- A registry of used console variables, mapped by their names to their ConVar objects (engine `userdata`).
    ---
    ---@type table<string, garrysmod.console.Variable>
    local console_variables = {}

    if set_console_variable == nil then

        local console_commandBlocked = console.commandBlocked
        local console_commandRun = console.commandRun

        local ConsoleVariable_GetString = engine_ConsoleVariable.GetString
        local ConsoleVariable_SetString = engine_ConsoleVariable.SetString

        ---@param name string
        ---@param value string
        ---@return boolean success
        function set_console_variable( name, value )
            if console_commandBlocked( name ) then
                return false
            end

            local variable = console_variables[ name ]
            if variable ~= nil and pcall( ConsoleVariable_SetString, variable, value ) then
                return ConsoleVariable_GetString( variable ) == value
            end

            -- engine variables refuse `SetString`, and console commands
            -- are queued, so the new value can't be confirmed here
            if variable ~= nil or ConVarExists( name ) then
                console_commandRun( name, value )
                return true
            end

            return false
        end

    end

    ---@type metatable<string, garrysmod.console.Variable>
    local metatable = {
        __mode = "v"
    }

    ---@type table<string, boolean>
    local blacklist = {}

    ---@param name string
    ---@protected
    function metatable:__index( name )
        if blacklist[ name ] then
            return nil
        end

        local console_variable = get_console_variable( name )
        if console_variable == nil then
            if ConVarExists( name ) then
                blacklist[ name ] = true
            end

            return nil
        end

        console_variables[ name ] = console_variable

        return console_variable
    end

    setmetatable( console_variables, metatable )
    console.Variables = console_variables

    --- [SHARED AND MENU]
    ---
    --- Gets a console variable's C object (userdata) by name.
    ---
    --- Existing console variables are loaded from the engine on first use and cached. Returns
    --- `nil` if no such console variable exists, or if it exists but the engine doesn't hand out
    --- its object.
    ---
    ---@see dreamwork.engine.console.variableCreate
    ---@see dreamwork.engine.console.variableRemove
    ---@see dreamwork.engine.console.variableExists
    ---
    ---@param name string The name of the console variable.
    ---@return garrysmod.console.Variable? cvar The console variable object, or `nil`.
    ---@nodiscard
    function console.variableGet( name )
        return console_variables[ name ]
    end

    --- [SHARED AND MENU]
    ---
    --- Sets the value of a console variable by name.
    ---
    --- With HolyLib's `cvar.SetValue` the value is set directly, even for variables protected
    --- by `sv_cheats`. Otherwise Lua-created variables are set through their object, and the
    --- rest (engine and blocked-for-Lua variables) fall back to running `<name> <value>` as a
    --- console command. Commands are queued by the engine, so in that case the value is applied
    --- later, and the result only tells that the command was sent.
    ---
    --- Without HolyLib, variables whose command is blocked by the engine (see
    --- `engine.console.commandBlocked`) and variables that don't exist are never touched.
    ---
    ---@see dreamwork.engine.console.variableGet
    ---@see dreamwork.engine.console.variableExists
    ---
    ---@param name string The name of the console variable.
    ---@param value string The new value of the console variable.
    ---@return boolean success `true` if the value was set (or the command to set it was sent), `false` otherwise.
    function console.variableSet( name, value )
        return set_console_variable( name, value )
    end

    --- [SHARED AND MENU]
    ---
    --- Creates a console variable and returns its C object (userdata).
    ---
    --- If a console variable with this name is already available through the registry, that
    --- existing object is returned as is and `default`, `flags`, `description`, `min` and `max`
    --- are ignored. Since the registry loads existing console variables lazily, this also
    --- covers ones that already exist in the engine.
    ---
    --- Raises an error (reported at the caller's level) if the engine has a console variable
    --- with this name but its object can't be obtained, or if the engine refuses to create it.
    ---
    ---@see dreamwork.engine.console.variableGet
    ---@see dreamwork.engine.console.variableRemove
    ---@see dreamwork.engine.console.variableExists
    ---
    ---@param name string The name of the console variable.
    ---@param default string The default value of the console variable.
    ---@param flags integer? The flags of the console variable (a combination of `FCVAR_*` values).
    ---@param description string? The description of the console variable.
    ---@param min number? The minimum value of the console variable.
    ---@param max number? The maximum value of the console variable.
    ---@return garrysmod.console.Variable cvar The console variable object.
    function console.variableCreate( name, default, flags, description, min, max )
        ---@type garrysmod.console.Variable | nil
        local variable = console_variables[ name ]
        if variable == nil then
            if ConVarExists( name ) then
                error( "console variable creation failed, already exists", 2 )
            end

            variable = CreateConVar( name, default, flags, description, min, max )
            if variable == nil then
                error( "console variable creation failed, restricted by the engine", 2 )
            end

            console_variables[ name ] = variable
        end

        return variable
    end

    --- [SHARED AND MENU]
    ---
    --- Removes a console variable that was registered through the engine module.
    ---
    --- Only variables tracked in the module's `console_variables` registry can be removed. If
    --- `name` isn't in it, nothing is touched and `false` is returned, so built-in console
    --- variables and ones created elsewhere are protected from this function.
    ---
    --- Otherwise the variable is removed from the engine, and the result tells you whether
    --- the removal actually took effect: `true` if the console variable no longer exists
    --- afterwards, `false` if it is still there.
    ---
    ---@see dreamwork.engine.console.variableGet
    ---@see dreamwork.engine.console.variableCreate
    ---@see dreamwork.engine.console.variableExists
    ---
    ---@param name string The name of the console variable.
    ---@return boolean success `true` if the console variable no longer exists after the call, `false` if it wasn't registered here or couldn't be removed.
    function console.variableRemove( name )
        if console_variables[ name ] == nil then
            return false
        end

        -- console_variables[ name ] = nil
        remove_console_variable( name )

        return not ConVarExists( name )
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if a console variable with the given name exists, whether it was registered
    --- through the engine module or comes from the engine itself.
    ---
    --- Unlike `engine.console.variableRemove`, which only acts on variables in the module's
    --- `console_variables` registry, this also reports built-in console variables and ones
    --- created elsewhere, since it falls back to the engine's own `ConVarExists` check.
    ---
    ---@see dreamwork.engine.console.variableGet
    ---@see dreamwork.engine.console.variableCreate
    ---@see dreamwork.engine.console.variableRemove
    ---
    ---@param name string The name of the console variable.
    ---@return boolean exists `true` if the console variable is registered in the module or exists in the engine, `false` otherwise.
    ---@nodiscard
    function console.variableExists( name )
        return console_variables[ name ] ~= nil or ConVarExists( name )
    end

    --- [SHARED AND MENU]
    ---
    --- Gets the names of all console variables known to the engine module.
    ---
    --- Lua can't enumerate the engine's console variables, so the result is assembled from
    --- two sources:
    ---
    --- * a built-in list of known Source engine and Garry's Mod console variables, filtered
    --- to the ones that exist in the current realm;
    --- * every console variable in the module's `console_variables` registry, that is, ones
    --- created with `engine.console.variableCreate` or loaded through `engine.console.variableGet`.
    ---
    --- Each name appears at most once. Console variables created elsewhere and never looked up
    --- through the module (e.g. by other addons via `CreateConVar`) are not included unless
    --- they're on the built-in list. The order of the names is not specified.
    ---
    ---@see dreamwork.engine.console.variableGet
    ---@see dreamwork.engine.console.variableExists
    ---
    ---@return string[] variables The names of the console variables.
    ---@return integer variable_count The number of names in `variables`.
    ---@nodiscard
    function console.variableGetAll()
        local variables = {}
        local variable_count = 0

        for i = 1, engine_variables[ 0 ], 1 do
            local name = engine_variables[ i ]
            if raw_get( console_variables, name ) == nil and ConVarExists( name ) then
                variable_count = variable_count + 1
                variables[ variable_count ] = name
            end
        end

        for name in raw_pairs( console_variables ) do
            variable_count = variable_count + 1
            variables[ variable_count ] = name
        end

        return variables, variable_count
    end

end


do

    ---@type table<string, string>
    local values = {}

    hook_catch( "server_cvar", "dreamwork.console.variable.change", function( data )
        local name, new_value = data.cvarname, data.cvarvalue
        local old_value = values[ name ]

        if old_value == nil then
            local variable = console.variableGet( name )
            if variable ~= nil then
                old_value = variable:GetDefault()
            end

            values[ name ] = old_value or ""
        else
            values[ name ] = new_value
        end

        hook_call( "dreamwork.console.variable.change", name, old_value, new_value )
    end, -1000 )

end

do

    ---@type fun( msg: string )
    local Msg = _G.Msg or _G.print
    local math_min = math.min

    local utf8 = std.utf8
    local utf8_sub, utf8_len = utf8.sub, utf8.len

    --- [SHARED AND MENU]
    ---
    --- Prints the given arguments to the console.
    ---
    ---@param str string The string to print.
    function console.message( str )
        local index, str_length = 1, utf8_len( str, nil, nil, true )

        while str_length ~= 0 do
            -- https://developer.valvesoftware.com/wiki/Developer_Console_Control
            -- by Retr0 ( 989 characters per message )
            local segment_length = math_min( 989, str_length )
            Msg( utf8_sub( str, index, index + segment_length - 1, true ) )
            str_length = str_length - segment_length
            index = index + segment_length
        end
    end

    ---@type fun( color: { r: integer, g: integer, b: integer, a: integer }, msg: string )
    local MsgC = _G.MsgC
    if MsgC == nil then
        console.messageColored = console.message
    else

        local color_buffer = dreamwork_engine.ColorProxy( 255, 255, 255, 255 )

        --- [SHARED AND MENU]
        ---
        --- Prints the given arguments to the console.
        ---
        ---@param str string The string to print.
        ---@param color dreamwork.std.Color The color to print the string with.
        function console.messageColored( str, color )
            local index, str_length = 1, utf8_len( str, nil, nil, true )
            color_buffer:update( color or 0xFFFFFF )

            while str_length ~= 0 do
                -- https://developer.valvesoftware.com/wiki/Developer_Console_Control
                -- by Retr0 ( 989 characters per message )
                local segment_length = math_min( 989, str_length )
                MsgC( color_buffer, utf8_sub( str, index, index + segment_length - 1, true ) )
                str_length = str_length - segment_length
                index = index + segment_length
            end
        end

    end

end
