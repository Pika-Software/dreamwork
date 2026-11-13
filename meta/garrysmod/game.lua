---@meta garrysmod.game


--- [SHARED]
---
--- The attributes of an ammo type, see `game.AddAmmoType`.
---
---@class garrysmod.AmmoData
---@field name string The name of the ammo.
---@field dmgtype ( integer | nil ) The damage type, see `DMG` enums. Default is `DMG_BULLET`.
---@field tracer ( integer | nil ) The tracer type, see `TRACER` enums. Default is `TRACER_NONE`.
---@field plydmg ( number | string | nil ) The damage dealt to players, a console variable name can be used and the value then follows the variable. Default is `10`.
---@field npcdmg ( number | string | nil ) The damage dealt to NPCs, a console variable name can be used and the value then follows the variable. Default is `10`.
---@field force ( number | nil ) The force applied to hit entities. Default is `1000`.
---@field minsplash ( number | nil ) The minimum water splash size. Default is `0`.
---@field maxsplash ( number | nil ) The maximum water splash size. Default is `0`.
---@field maxcarry ( number | string | nil ) The maximum reserve ammo a player can carry, `-2` is infinite, a console variable name can be used. The `gmod_maxammo` console variable overrides it when above `0`, which it is by default. Default is `9999`.
---@field flags ( integer | nil ) The flags of the ammo type, see `AMMO` enums. Default is `0`.

--- [SHARED]
---
--- Information about the 3D skybox, see `game.Get3DSkyboxInfo`.
---
---@class garrysmod.Sky3DParams
---@field origin garrysmod.Vector The position of the `sky_camera` entity.
---@field scale number The scale of the 3D skybox.

--- [SHARED AND MENU]
---
--- The game library provides functions to access various features in the game's engine,
--- most of its functions are related to controlling the map.
---
---@class garrysmod.game
game = {}

--- [SHARED]
---
--- Adds a new ammo type to the game.
---
--- You can find a list of default ammo types [here](https://wiki.facepunch.com/gmod/Default_Ammo_Types).
---
--- > WARNING: This function **must** be called on both the client and server in `GM:Initialize` or you will have unexpected problems.
---
--- > NOTE: There is a limit of 256 ammo types, including the default ones.
---
---@param ammo_data garrysmod.AmmoData The attributes of the ammo.
function game.AddAmmoType( ammo_data ) end

--- [SHARED]
---
--- Registers a new decal.
---
--- > WARNING: There's a rather low limit of around 256 for decal materials that may be registered and they are not cleared on map load.
---
---@param decal_name string The name of the decal.
---@param material_name string | string[] The material to be used for the decal, may also be a list of material names, in which case a random material from that list will be chosen every time the decal is placed.
function game.AddDecal( decal_name, material_name ) end

--- [SHARED]
---
--- Loads a particle file. Individual particle systems will still need to be precached with `PrecacheParticleSystem`.
---
--- > NOTE: You will still need to call this function clientside regardless if you create the particle effects serverside.
---
---@param file_path string The path of the file to add, must be a `.pcf` file.
function game.AddParticles( file_path ) end

--- [SHARED]
---
--- Consider using `game.GetAmmoTypes` and `game.GetAmmoData` instead.
---
--- Called by the engine to retrieve the ammo types.
---
---@return garrysmod.AmmoData[] ammo_types All ammo types registered via `game.AddAmmoType`, sorted by their name.
function game.BuildAmmoTypes() end

--- [SHARED]
---
--- Removes most entities, and then respawns entities created by the map, as if the map was just loaded.
---
--- There are certain exclusions, such as players or weapons held by players, soundscapes and others.
--- `EFL_KEEP_ON_RECREATE_ENTITIES` can be set on entities to preserve them through a map cleanup.
---
--- On the client it will remove decals, sounds, gibs, dead NPCs, and entities created via `ents.CreateClientProp`.
--- This function is ran on all clients from the server automatically, when it is called on the server.
---
--- This function calls `GM:PreCleanupMap` before cleaning up the map and `GM:PostCleanupMap` after cleaning up the map.
---
--- Beware of calling this function in hooks that may be called on map clean up (such as `ENTITY:StartTouch`) to avoid infinite loops.
---
--- Calling this destroys all BASS streams.
---
--- > NOTE: The `EFL_KEEP_ON_RECREATE_ENTITIES` flag doesn't prevent an entity from being recreated,
--- > which means flagged entities will be duplicated since they are both kept and recreated.
---
---@param dont_send_to_clients boolean? If set to `true`, don't run this function on all clients.
---@param extra_filters string[]? The entity classes not to reset during cleanup.
---@param callback ( fun() )? If set, delays the map cleanup until the end of a server tick, allowing bypassing the entity limit on maps with large amounts of them (otherwise the entities will not be cleaned up until the end of the server tick). The function is called after the map cleanup has been performed.
function game.CleanUpMap( dont_send_to_clients, extra_filters, callback ) end

--- [SERVER]
---
--- Runs a console command.
--- Make sure to add a newline (`"\n"`) at the end of the command.
---
--- > WARNING: If you use data that was received from a client, you should avoid using this function
--- > because newline and semicolon (at least) allow the client to run arbitrary commands!
--- > For safety, you are urged to prefer using `RunConsoleCommand` in this case.
---
---@param command string The command and arguments to be ran.
function game.ConsoleCommand( command ) end

--- [SHARED]
---
--- Returns information about the currently active 3D skybox.
---
---@return garrysmod.Sky3DParams | nil info The 3D skybox info, or `nil` if the map has no 3D skybox or the function is called too soon during server start up.
function game.Get3DSkyboxInfo() end

--- [SHARED]
---
--- Returns the damage type of the given ammo type.
---
---@param id integer The ammo ID to retrieve the damage type of, starts from `1`.
---@return integer damage_type The damage type, see `DMG` enums.
function game.GetAmmoDamageType( id ) end

--- [SHARED]
---
--- Returns the ammo data for the given ID.
---
---@param id integer The ID of the ammo type to look up the data for.
---@return garrysmod.AmmoData data The ammo data.
function game.GetAmmoData( id ) end

--- [SHARED]
---
--- Returns the ammo bullet force that is applied when an entity is hit by a bullet of the given ammo type.
---
---@param id integer The ammo ID to retrieve the force of, starts from `1`.
---@return number force The ammo force.
function game.GetAmmoForce( id ) end

--- [SHARED]
---
--- Returns the ammo type ID for the given ammo type name.
---
--- See `game.GetAmmoName` for reverse.
---
---@param name string The name of the ammo type to look up the ID of.
---@return integer id The ammo type ID, or `-1` if not found.
function game.GetAmmoID( name ) end

--- [SHARED]
---
--- Returns the real maximum amount of ammo of the given ammo ID, regardless of the setting of the `gmod_maxammo` console variable.
---
---@param id integer The ammo type ID.
---@return integer max The maximum amount of reserve ammo a player can hold of this ammo type.
function game.GetAmmoMax( id ) end

--- [SHARED]
---
--- Returns the ammo name for the given ammo type ID.
---
--- See `game.GetAmmoID` for reverse.
---
---@param id integer The ammo ID to retrieve the name of, starts from `1`.
---@return string | nil name The name of the ammo type, `nil` if the ID is invalid.
function game.GetAmmoName( id ) end

--- [SHARED]
---
--- Returns the damage the given ammo type should do to NPCs.
---
---@param id integer The ammo ID to retrieve the damage info of, starts from `1`.
---@return number damage The damage dealt to NPCs.
function game.GetAmmoNPCDamage( id ) end

--- [SHARED]
---
--- Returns the damage the given ammo type should do to players.
---
---@param id integer The ammo ID to retrieve the damage info of, starts from `1`.
---@return number damage The damage dealt to players.
function game.GetAmmoPlayerDamage( id ) end

--- [SHARED]
---
--- Returns a list of all ammo types currently registered.
---
---@return table<integer, string> ammo_types The ammo types, the keys are ammo IDs, the values are the names associated with those IDs.
function game.GetAmmoTypes() end

--- [SERVER]
---
--- Returns the counter of a Global State.
---
--- See [Global States](https://wiki.facepunch.com/gmod/Global_States) for more information and a list of default global states.
---
---@param name string The name of the Global State.
---@return integer count The value of the given Global State, `0` if the global state doesn't exist.
function game.GetGlobalCounter( name ) end

--- [SERVER]
---
--- Returns whether a Global State is off, active or dead (inactive).
---
--- See [Global States](https://wiki.facepunch.com/gmod/Global_States) for more information and a list of default global states.
---
---@param name string The name of the Global State to retrieve the state of.
---@return integer state The state of the Global State, see `GLOBAL` enums. `GLOBAL_DEAD` is returned if the global state doesn't exist.
function game.GetGlobalState( name ) end

--- [SHARED]
---
--- Returns the public IP address and port of the current server.
--- This will return the IP/port that you are connecting through when ran clientside.
---
--- > NOTE: Returns `"loopback"` in singleplayer.
---
--- > NOTE: Returns `"0.0.0.0:<port>"` on the server when called too early, including in `GM:Initialize` and `GM:InitPostEntity`.
--- > This bug seems to only happen the first time a server is launched, and will return the correct value after switching maps.
---
---@return "loopback" | string address The IP address and port in the format `"x.x.x.x:x"`.
function game.GetIPAddress() end

--- [SHARED AND MENU]
---
--- Returns the name of the current map, without a file extension.
--- On the menu state, returns `"menu"`.
---
--- > WARNING: In multiplayer this does not return the current map in the `CLIENT` realm before `GM:Initialize`.
---
---@return string name The name of the current map, without a file extension.
function game.GetMap() end

--- [SERVER]
---
--- Returns the current map change count for the server.
---
--- This is useful to determine whether the current map is the initial map,
--- or whether a `changelevel` (using the `map` command is also detected) has occurred at any point in the server's session.
---
---@return integer count The current map change count, starts at `1`.
function game.GetMapChangeCount() end

--- [SERVER]
---
--- Returns the next map that would be loaded according to the file that is set by the `mapcyclefile` console variable.
---
---@return string | nil name The name of the next map, `nil` if called too early.
function game.GetMapNext() end

--- [SERVER]
---
--- Returns the revision and BSP version of the current map.
---
--- Map revision is the amount of times the map file was saved in Hammer at the time of the map being compiled.
--- This is useful to detect when a map has changed.
---
--- > NOTE: Not to be confused with the [VBSP version](https://developer.valvesoftware.com/wiki/Source_BSP_File_Format#Versions).
---
---@return integer revision The revision of the currently loaded map.
---@return integer version The BSP version.
function game.GetMapVersion() end

--- [SHARED]
---
--- Returns the difficulty level of the game.
---
--- > TIP: You can use this function in your scripted NPCs or Nextbots to make them stronger,
--- > however, it is a good idea to lock powerful attacks behind the highest difficulty instead of just increasing the health.
---
--- > NOTE: Internally this is tied to the gamerules entity,
--- > so you'll have to wait until `GM:InitPostEntity` is called to return the skill level.
---
---@return integer level The difficulty level: Easy (`1`), Normal (`2`), Hard (`3`).
function game.GetSkillLevel() end

--- [SHARED]
---
--- Returns the time scale set with `game.SetTimeScale`.
---
--- If you want to get the value of `host_timescale`, use:
--- ```lua
--- local timescale = GetConVar( "host_timescale" ):GetFloat()
--- ```
---
---@return number time_scale The time scale.
function game.GetTimeScale() end

--- [SHARED]
---
--- Returns the wind's velocity at a given position, as influenced by current map's [env_wind](https://developer.valvesoftware.com/wiki/Env_wind) entities.
---
--- See [env_wind_shared.cpp](https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/env_wind_shared.cpp#L255-L258) for how it's calculated.
---
---@param position garrysmod.Vector? The point to get the wind speed at.
--- If specified, wind controllers with `windradius` other than `-1` will be taken into account, if the point is within their radius.
--- If omitted, only the global wind controller will be used (if one exists).
--- This argument will be ignored on the `CLIENT` realm and will be treated as `nil`, because the position of `env_wind` is not currently networked to clients.
---@return garrysmod.Vector velocity `windDir * windSpeed` - the current wind direction multiplied by the current total wind speed.
function game.GetWindSpeed( position ) end

--- [SHARED]
---
--- Returns the `worldspawn` entity.
---
---@return garrysmod.Entity world The world.
function game.GetWorld() end

--- [SHARED]
---
--- Returns whether the server is a dedicated server.
---
---@return boolean is_dedicated `true` if the server is dedicated, `false` if it is a listen server or a singleplayer game.
function game.IsDedicated() end

--- [SERVER]
---
--- Kicks a player from the server. This can be ran before the player has spawned.
---
---@param id string The `Player:UserID`, `Player:SteamID` or `Player:SteamID64` of the player to kick, uses SteamID32 e.g. `STEAM_0:0:00000000`.
---@param reason string? The reason to display to the player, this can span across multiple lines.
--- This will be shortened to ~512 chars, though this includes the command itself and the player index so it will realistically be more around ~483.
--- It is recommended to avoid going near the limit to avoid truncation.
function game.KickID( id, reason ) end

--- [SERVER]
---
--- Loads the next map according to the `nextlevel` console variable, or from the current `mapcyclefile` set by the respective console variable.
---
function game.LoadNextMap() end

--- [SERVER]
---
--- Returns the map load type of the current map.
---
--- After changing the map with the console command `changelevel`, `"newgame"` is returned.
--- With `changelevel2` (single player only), `"transition"` is returned.
---
---@return "newgame" | "loadgame" | "transition" | "background" load_type The load type.
function game.MapLoadType() end

--- [SHARED]
---
--- Returns the maximum amount of players (including bots) that the server can have.
---
---@return integer max_players The maximum amount of players.
function game.MaxPlayers() end

--- [SHARED]
---
--- Mounts a GMA addon from the disk.
--- Can be used with `steamworks.DownloadUGC`.
---
--- > NOTE: Any error models currently loaded that the mounted addon provides will be reloaded.
--- > Any error materials currently loaded that the mounted addon provides will **not** be reloaded.
--- > That means that this cannot be used to fix missing map materials, as the map materials are loaded before you are able to call this.
---
---@param path string The location of the GMA file to mount, retrieved from `steamworks.DownloadUGC` or relative to the `garrysmod/` directory (ignores mounting). This file does not have to end with the `.gma` extension, but will be interpreted as a GMA.
---@return boolean success `true` if the addon was mounted.
---@return string[] files If successful, a list of files that have been mounted.
function game.MountGMA( path ) end

--- [SHARED]
---
--- Removes all the clientside ragdolls.
--- On the server, it will remove all `prop_ragdoll`s that have the `SF_RAGDOLLPROP_USE_LRU_RETIREMENT` (`4096`) spawnflag.
---
function game.RemoveRagdolls() end

--- [SERVER]
---
--- Sets the counter of a Global State.
---
--- See [Global States](https://wiki.facepunch.com/gmod/Global_States) for more information and a list of default global states.
---
---@param name string The name of the Global State, it will be created if it does not exist.
---@param count integer The value to set for that Global State.
function game.SetGlobalCounter( name, count ) end

--- [SERVER]
---
--- Sets whether a Global State is off, active or dead (inactive).
---
--- See [Global States](https://wiki.facepunch.com/gmod/Global_States) for more information and a list of default global states.
---
---@param name string The name of the Global State, it will be created if it does not exist.
---@param state integer The state of the Global State, see `GLOBAL` enums.
function game.SetGlobalState( name, state ) end

--- [SERVER]
---
--- Sets the difficulty level of the game, can be retrieved with `game.GetSkillLevel`.
---
--- This will automatically change whenever the `skill` console variable is modified serverside.
---
---@param level integer The difficulty level: Easy (`1`), Normal (`2`), Hard (`3`).
function game.SetSkillLevel( level ) end

--- [SERVER]
---
--- Sets the time scale of the game logic.
---
--- To slow down or speed up the movement of a specific player, use `Player:SetLaggedMovementValue` instead.
---
--- See `physenv.SetTimeScale` if you wish to only scale the physics timescale.
---
--- This function is meant to remove the need of using the `host_timescale` console variable, which is cheat protected.
--- The true timescale will be `host_timescale` multiplied by `game.GetTimeScale`.
---
--- Like `host_timescale`, this method does not affect sounds, if you wish to change that, look into `GM:EntityEmitSound`.
---
---@param time_scale number The new timescale, minimum value is `0.001` and maximum is `5`.
function game.SetTimeScale( time_scale ) end

--- [SHARED]
---
--- Returns whether the current session is a single player game.
---
---@return boolean is_singleplayer `true` if the session is a single player game.
function game.SinglePlayer() end

--- [SERVER]
---
--- Returns the name of the entity that should be used as the player start position.
---
--- This is not the same thing as spawn points (see `GM:PlayerSelectSpawn` for that),
--- this is used to properly transit the player between maps, and therefore will only be set
--- after a level change via a `trigger_changelevel` entity in singleplayer.
---
---@return string name The name of the entity that should be used as the start position.
function game.StartSpot() end
