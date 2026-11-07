local dreamwork_engine = dreamwork.engine
local engine_requireLibrary = dreamwork_engine.requireLibrary

local detour = dreamwork.detour

local engine_hook = dreamwork_engine.hook
local hook_call = engine_hook.call

local std = dreamwork.std

local LUA_SERVER = std.LUA_SERVER
local LUA_CLIENT = std.LUA_CLIENT
local LUA_MENU = std.LUA_MENU

local raw = std.raw
local raw_pairs = raw.pairs

local debug = std.debug
local debug_fempty = debug.fempty


if LUA_MENU then

    detour.before( function()
        ---@diagnostic disable-next-line: undefined-field
        hook_call( "dreamwork.addon.presets", (_G.LoadAddonPresets or debug_fempty)() )
    end, _G, "ListAddonPresets" )

    ---@param server_name string
    ---@param loading_url string
    ---@param map_name string
    ---@param max_players integer
    ---@param player_steamid64 string
    ---@param gamemode_name string
    detour.before( function( server_name, loading_url, map_name, max_players, player_steamid64, gamemode_name )
        hook_call( "dreamwork.server.details", {
            server_name = server_name,
            loading_url = loading_url,
            map_name = map_name,
            max_players = max_players,
            player_steamid64 = player_steamid64,
            gamemode_name = gamemode_name
        } )
    end, _G, "GameDetails" )

end

do

    ---@class garrysmod.hook
    local glua_hook = engine_requireLibrary( "hook" )

    detour.simple( function( event_name, _, ... )
        return hook_call( event_name, ... )
    end, glua_hook, "Call" )

end

do

    ---@class garrysmod.concommand
    local concommand = engine_requireLibrary( "concommand" )

    local fallback_exists = concommand.Run ~= nil

    ---@param ply garrysmod.Player
    ---@param cmd string
    ---@param args string[]
    ---@param argument_string string
    detour.simple( function( ply, cmd, args, argument_string )
        local is_command_found = hook_call( "dreamwork.console.command.execute", ply, cmd, args, argument_string ) == true
        if not is_command_found then
            if fallback_exists then
                return nil
            end

            dreamwork.Logger:error( "Catched attempt to run unknown console command '%s %s' by %s.", cmd, argument_string or "", ply )
        end

        return is_command_found
    end, concommand, "Run" )

    ---@param cmd string
    ---@param argument_string string
    ---@param args string[]
    ---@return string[] | nil
    detour.simple( function( cmd, argument_string, args )
        return hook_call( "dreamwork.console.command.autocomplete", cmd, argument_string, args )
    end, concommand, "AutoComplete" )

end

do

    ---@class garrysmod.cvars
    local cvars = engine_requireLibrary( "cvars" )

    ---@param name string
    ---@param old_value string
    ---@param new_value string
    detour.before( function( name, old_value, new_value )
        hook_call( "dreamwork.console.variable.change", name, old_value, new_value )
    end, cvars, "OnConVarChanged" )

end

if LUA_SERVER or LUA_CLIENT then

    do

        ---@class garrysmod.gamemode
        local gamemode = engine_requireLibrary( "gamemode" )

        if gamemode.Get == nil then

            ---@type table<string, table>
            local gamemodes = {}

            ---@param name string
            ---@return table | nil
            ---@nodiscard
            function gamemode.Get( name )
                local tbl = gamemodes[ name ]
                return hook_call( "dreamwork.gamemode.select", name, tbl ) or tbl
            end

            if gamemode.Register == nil then

                ---@param gm table
                ---@param name string
                ---@param base_name string
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

            ---@param name string
            ---@return table | nil
            detour.attach( function( fn, name )
                ---@diagnostic disable-next-line: need-check-nil
                local tbl = fn( name )
                return hook_call( "dreamwork.gamemode.select", name, tbl ) or tbl
            end, gamemode, "Get" )

            gamemode.Register = gamemode.Register or debug_fempty

        end

    end

    do

        local entity_metatables = {
            dreamwork_engine.Entity,
            dreamwork_engine.Player,
            dreamwork_engine.Weapon,
            dreamwork_engine.Vehicle,
            dreamwork_engine.NPC,
            dreamwork_engine.NextBot,
        }

        for i = 1, #entity_metatables, 1 do
            local metatable = entity_metatables[ i ]
            detour.before( function( entity_userdata )
                hook_call( "dreamwork.entity.gc", entity_userdata )
            end, metatable, "__gc" )
        end

    end

    do

        ---@class garrysmod.scripted_ents
        local scripted_ents = engine_requireLibrary( "scripted_ents" )

        ---@param name string
        ---@param output table | nil
        ---@return table | nil
        detour.simple( function( name, output )
            return hook_call( "dreamwork.entity.create", name, output )
        end, scripted_ents, "Get" )

        ---@type table<string, metatable>
        local SEntList = debug.getupvalues( scripted_ents.GetStored ).SEntList

        detour.before( function()
            for class_name, metatable in raw_pairs( SEntList ) do
                hook_call( "dreamwork.entity.load", class_name, metatable )
            end
        end, scripted_ents, "OnLoaded" )
    end

    do

        ---@class garrysmod.weapons
        local weapons = engine_requireLibrary( "weapons" )

        ---@param name string
        ---@param output table | nil
        ---@return table | nil
        detour.simple( function( name, output )
            return hook_call( "dreamwork.weapon.create", name, output )
        end, weapons, "Get" )

        ---@type table<string, metatable>
        local WeaponList = debug.getupvalues( weapons.GetStored ).WeaponList

        detour.before( function()
            for class_name, metatable in raw_pairs( WeaponList ) do
                hook_call( "dreamwork.weapon.load", class_name, metatable )
            end
        end, weapons, "OnLoaded" )

    end

    do

        ---@class garrysmod.effects
        local effects = engine_requireLibrary( "effects" )

        ---@param name string
        ---@param output table | nil
        ---@return table | nil
        detour.simple( function( name, output )
            return hook_call( "dreamwork.effect.create", name, output )
        end, effects, "Create" )

        -- TODO: register?

    end

end
