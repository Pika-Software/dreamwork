---@class dreamwork.std
local std = dreamwork.std

-- do

--     ---@type garrysmod.hook
--     local glua_hook = dreamwork_engine.requireLibrary( "hook" )
--     local hook_Run = glua_hook.Run or debug_fempty

--     --- [SHARED AND MENU]
--     ---
--     --- Returns the title of the gamemode in the server browser.
--     ---
--     ---@return string title The title of the gamemode.
--     ---@nodiscard
--     function server.getGamemodeTitle()
--         return hook_Run( "GetGameDescription" ) or (GM or GAMEMODE or {}).Title or "unknown"
--     end

--     if LUA_SERVER then

--         ---@type string | nil
--         local title = nil

--         engine_hook_catch( "GetGameDescription", "std.server.title", function()
--             return title
--         end, 1000 )

--         --- [SERVER]
--         ---
--         --- Sets the title of the gamemode in the server browser.
--         ---
--         ---@param str string? The title to set, `nil` to restore the gamemode title.
--         function server.setGamemodeTitle( str )
--             title = str
--         end

--     end

-- end


-- TODO: gamemode objects ( `server.getGamemode`, `server.setGamemode` ) return with the `Gamemode` class,
-- see `std/engine/gamemode.lua` and the `dreamwork.gamemode.select` hook.


-- - gmod_sneak_attack: If set to 0 disables HL2's sneak attack, where headshotting
--     NPCs that haven't seen the player would result in an instant kill.

-- - sv_infinite_aux_power: This boolean ConVar enables/disables infinite suit power on the server. (For usual only on Half-Life 2 and modifications)
--     when sv_infinite_aux_power is non-zero players will have infinitive suit power.

-- - lua_networkvar_bytespertick: Allows you to control how many bytes are networked each tick.
--     This should affect all NW functions. not NW2


-- https://github.com/Pika-Software/ash/blob/main/lua/ash/shared.lua#L54-L70

-- https://wiki.facepunch.com/gmod/Blocked_ConCommands

-- https://developer.valvesoftware.com/wiki/Console_Command_List

-- ---@alias Gamemode dreamwork.std.Gamemode
-- ---@class dreamwork.std.Gamemode : dreamwork.std.Object
-- ---@field __class dreamwork.std.GamemodeClass
-- ---@field name string
-- local Gamemode = std.class.base( "Gamemode" )

-- ---@protected
-- function Gamemode:__init()

-- end

-- ---@class dreamwork.std.GamemodeClass : dreamwork.std.Gamemode, dreamwork.std.Class
-- ---@field __base dreamwork.std.Gamemode
-- ---@overload fun(): Gamemode
-- local GamemodeClass = std.class.create( Gamemode )
-- std.Gamemode = GamemodeClass

-- TODO: make gamemode class and gamemode handler

-- dreamwork.engine.hook.catch( "GamemodeLoaded", function()
--     -- -- https://github.com/Facepunch/garrysmod-requests/issues/2793
--     -- local sv_defaultdeployspeed = console_Variable.get( "sv_defaultdeployspeed", "number" )
--     -- if sv_defaultdeployspeed ~= nil and sv_defaultdeployspeed.value == 4 then
--     --     sv_defaultdeployspeed.value = 1
--     -- end

--     -- -- draw everything manually, don't use this crap
--     -- local mp_show_voice_icons = console_Variable.get( "mp_show_voice_icons", "boolean" )
--     -- if mp_show_voice_icons ~= nil and mp_show_voice_icons.value then
--     --     mp_show_voice_icons.value = false
--     -- end
-- end )
