---@meta garrysmod.player


--- [SHARED]
---
--- This is a list of all methods only available for players. It is also possible to call [Entity](https://wiki.facepunch.com/gmod/Entity) functions on the Player.
---
---@class garrysmod.Player : garrysmod.Entity
local Player = {}

--- [SHARED]
---
--- Returns the player's AccountID part of their full SteamID.
---
--- Since this does not include other vital parts of the SteamID such as "Account Type" and "Account Instance", it should be avoided, as AccountIDs are finite, and can theoretically be the same for multiple valid accounts.
---
--- See [Player:SteamID](https://wiki.facepunch.com/gmod/Player:SteamID) for the text representation of the full SteamID.
--- See [Player:SteamID64](https://wiki.facepunch.com/gmod/Player:SteamID64) for a 64bit representation of the full SteamID.
---
--- > NOTE: In a `-multirun` environment, this will return `-1` for all "copies" of a player because they are not authenticated with Steam.
--- >
--- > For bots this will return values starting with `0` for the first bot, `1` for the second bot and so on.
---
---@return integer | nil account_id The AccountID of Player's SteamID.
function Player:AccountID() end

--- [SERVER]
---
--- Adds the provided amount to the player's death count.
---
---@param count integer The amount to add to the death count.
function Player:AddDeaths( count ) end

--- [SERVER]
---
--- Adds the provided amount to the player's frag/kill count.
---
---@param count integer The amount to add.
function Player:AddFrags( count ) end

--- [SHARED]
---
--- Plays a sequence directly from a sequence number, similar to [Player:AnimRestartGesture](https://wiki.facepunch.com/gmod/Player:AnimRestartGesture). This function has the advantage to play sequences that haven't been bound to an existing [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT)
---
--- > WARNING: This is not automatically networked. This function has to be called on the client to be seen by said client.
---
---@param slot integer Gesture slot using [Enums/GESTURE_SLOT](https://wiki.facepunch.com/gmod/Enums/GESTURE_SLOT)
---@param sequence_id integer The sequence ID to play, can be retrieved with [Entity:LookupSequence](https://wiki.facepunch.com/gmod/Entity:LookupSequence).
---@param cycle number The cycle to start the animation at, ranges from 0 to 1.
---@param autokill boolean? If the animation should not loop. true = stops the animation, false = the animation keeps playing. Defaults to `false`.
function Player:AddVCDSequenceToGestureSlot( slot, sequence_id, cycle, autokill ) end

--- [SHARED]
---
--- Checks if the player is alive.
---
--- Player specific implementation of [Entity:Alive](https://wiki.facepunch.com/gmod/Entity:Alive), the value is synchronized to the client.
---
---@return boolean is_alive Whether the player is alive
function Player:Alive() end

--- [SERVER]
---
--- Lets the player spray their decal without delay
---
---@param allow boolean Allow or disallow
function Player:AllowImmediateDecalPainting( allow ) end

--- [SHARED]
---
--- Resets player gesture in selected slot.
---
---@param slot integer Slot to reset. See the [Enums/GESTURE_SLOT](https://wiki.facepunch.com/gmod/Enums/GESTURE_SLOT).
function Player:AnimResetGestureSlot( slot ) end

--- [SHARED]
---
--- Restart a gesture on a player, within a gesture slot.
---
--- > WARNING: This is not automatically networked. This function has to be called on the client to be seen by said client.
---
---@param slot integer Gesture slot using [Enums/GESTURE_SLOT](https://wiki.facepunch.com/gmod/Enums/GESTURE_SLOT)
---@param activity integer The activity ( see [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT) ) or sequence that should be played
---@param autokill boolean? Whether the animation should be automatically stopped. true = stops the animation, false = the animation keeps playing/looping Defaults to `false`.
function Player:AnimRestartGesture( slot, activity, autokill ) end

--- [SHARED]
---
--- Restarts the main animation on the player, has the same effect as calling [Entity:SetCycle](https://wiki.facepunch.com/gmod/Entity:SetCycle)( 0 ).
---
function Player:AnimRestartMainSequence() end

--- [SHARED]
---
--- Sets the sequence of the animation playing in the given gesture slot.
---
---@param slot integer The gesture slot. See [Enums/GESTURE_SLOT](https://wiki.facepunch.com/gmod/Enums/GESTURE_SLOT)
---@param sequence_id integer Sequence ID to set.
function Player:AnimSetGestureSequence( slot, sequence_id ) end

--- [SHARED]
---
--- Sets the weight of the animation playing in the given gesture slot.
---
---@param slot integer The gesture slot. See [Enums/GESTURE_SLOT](https://wiki.facepunch.com/gmod/Enums/GESTURE_SLOT)
---@param weight number The weight this slot should be set to. Value must be ranging from 0 to 1.
function Player:AnimSetGestureWeight( slot, weight ) end

--- [SHARED]
---
--- Returns the player's armor.
---
---@return integer armor The player's armor.
function Player:Armor() end

--- [SERVER]
---
--- Bans the player from the server for a certain amount of minutes.
---
---@param minutes number Duration of the ban in minutes (0 is permanent)
---@param kick boolean? Whether to kick the player after banning them or not Defaults to `false`.
function Player:Ban( minutes, kick ) end

--- [SHARED]
---
--- Prints a string to the chatbox of the client.
---
--- > WARNING: Just like the [usermessage](https://wiki.facepunch.com/gmod/usermessage), this function is affected by the 255 byte limit!
---
---@param message string String to be printed
function Player:ChatPrint( message ) end

--- [SHARED]
---
--- Runs the [console command](https://wiki.facepunch.com/gmod/Console_commands) on the player. This does not work on bots.
---
--- If used clientside, always runs the command on the local player. You should use [Global.RunConsoleCommand](https://wiki.facepunch.com/gmod/Global.RunConsoleCommand) in client realm instead.
---
--- If you wish to directly modify the movement input of bots, use [GM:StartCommand](https://wiki.facepunch.com/gmod/GM:StartCommand) instead.
---
--- > NOTE: Some commands/convars are blocked from being run/changed using this function, usually to prevent harm/annoyance to clients. For a list of blocked commands, see [Blocked ConCommands](https://wiki.facepunch.com/gmod/Blocked_ConCommands).
---
--- > WARNING: If you use data that were received from a client, you should avoid using this function because semicolon (at least) allow the client to run arbitrary commands!
--- >
--- > For safety, you are urged to prefer using [Player:RunConsoleCommand](https://wiki.facepunch.com/gmod/Player:RunConsoleCommand) in this case.
---
---@param command string The console command to run.
---@param skip_queue boolean? Whether to skip the command queue and send the command immediately. Clientside only. Defaults to `false`.
function Player:ConCommand( command, skip_queue ) end

--- [SERVER]
---
--- Creates the player's death ragdoll entity and deletes the old one.
---
--- This is normally used when a player dies, to create their death ragdoll.
---
--- The ragdoll will be created with the player's properties such as [Position](https://wiki.facepunch.com/gmod/Entity:GetPos), [Angles](https://wiki.facepunch.com/gmod/Entity:GetAngles), [PlayerColor](https://wiki.facepunch.com/gmod/Player:GetPlayerColor), [Velocity](https://wiki.facepunch.com/gmod/Entity:GetVelocity) and [Model](https://wiki.facepunch.com/gmod/Entity:GetModel).
---
--- You can retrieve the entity this creates with [Player:GetRagdollEntity](https://wiki.facepunch.com/gmod/Player:GetRagdollEntity).
---
function Player:CreateRagdoll() end

--- [SERVER]
---
--- Disables the default player's crosshair. Can be reenabled with [Player:CrosshairEnable](https://wiki.facepunch.com/gmod/Player:CrosshairEnable). This will affect [WEAPON:DoDrawCrosshair](https://wiki.facepunch.com/gmod/WEAPON:DoDrawCrosshair).
---
function Player:CrosshairDisable() end

--- [SERVER]
---
--- Enables the player's crosshair, if it was previously disabled via [Player:CrosshairDisable](https://wiki.facepunch.com/gmod/Player:CrosshairDisable).
---
function Player:CrosshairEnable() end

--- [SHARED]
---
--- Returns whether the player is crouching or not ([FL_DUCKING](https://wiki.facepunch.com/gmod/Enums/FL) flag).
---
---@return boolean is_crouching Whether the player is crouching.
function Player:Crouching() end

--- [SHARED]
---
--- Returns the player's death count
---
---@return integer deaths The number of deaths the player has had.
function Player:Deaths() end

--- [SERVER]
---
--- Detonates all tripmines belonging to the player.
---
function Player:DetonateTripmines() end

--- [SERVER]
---
--- Disables world clicking for given player. See [Panel:SetWorldClicker](https://wiki.facepunch.com/gmod/Panel:SetWorldClicker) and [Player:IsWorldClickingDisabled](https://wiki.facepunch.com/gmod/Player:IsWorldClickingDisabled).
---
---@param disable boolean Whether the world clicking should be disabled.
function Player:DisableWorldClicking( disable ) end

--- [SHARED]
---
--- Sends a third person animation event to the player.
---
--- Calls [GM:DoAnimationEvent](https://wiki.facepunch.com/gmod/GM:DoAnimationEvent) with [PLAYERANIMEVENT_CUSTOM_GESTURE](https://wiki.facepunch.com/gmod/Enums/PLAYERANIMEVENT) as the event, data as the given data.
---
---@param data integer The data to send.
function Player:DoAnimationEvent( data ) end

--- [SHARED]
---
--- Starts the player's attack animation. The attack animation is determined by the weapon's HoldType.
---
--- Similar to other animation event functions, calls [GM:DoAnimationEvent](https://wiki.facepunch.com/gmod/GM:DoAnimationEvent) with [PLAYERANIMEVENT_ATTACK_PRIMARY](https://wiki.facepunch.com/gmod/Enums/PLAYERANIMEVENT) as the event and no extra data.
---
function Player:DoAttackEvent() end

--- [SHARED]
---
--- Sends a specified third person animation event to the player.
---
--- Calls [GM:DoAnimationEvent](https://wiki.facepunch.com/gmod/GM:DoAnimationEvent) with specified arguments.
---
---@param event integer The event to send. See [Enums/PLAYERANIMEVENT](https://wiki.facepunch.com/gmod/Enums/PLAYERANIMEVENT).
---@param data integer The data to send alongside the event.
function Player:DoCustomAnimEvent( event, data ) end

--- [SHARED]
---
--- Sends a third person reload animation event to the player.
---
--- Similar to other animation event functions, calls [GM:DoAnimationEvent](https://wiki.facepunch.com/gmod/GM:DoAnimationEvent) with [PLAYERANIMEVENT_RELOAD](https://wiki.facepunch.com/gmod/Enums/PLAYERANIMEVENT) as the event and no extra data.
---
function Player:DoReloadEvent() end

--- [SHARED]
---
--- Sends a third person secondary fire animation event to the player.
---
--- Similar to other animation event functions, calls [GM:DoAnimationEvent](https://wiki.facepunch.com/gmod/GM:DoAnimationEvent) with [PLAYERANIMEVENT_ATTACK_SECONDARY](https://wiki.facepunch.com/gmod/Enums/PLAYERANIMEVENT) as the event and no extra data.
---
function Player:DoSecondaryAttack() end

--- [SHARED]
---
--- Show/Hide the player's weapon's viewmodel.
---
---@param draw boolean Should draw
---@param index integer? Which view model to show/hide, 0-2. Defaults to `0`.
function Player:DrawViewModel( draw, index ) end

--- [SERVER]
---
--- Show/Hide the player's weapon's worldmodel.
---
---@param draw boolean Should draw
function Player:DrawWorldModel( draw ) end

--- [SERVER]
---
--- Drops the players' weapon of a specific class.
---
---@param class string The class to drop.
---@param target garrysmod.Vector? If set, launches the weapon at given position. There is a limit to how far it is willing to throw the weapon. Overrides velocity argument.
---@param velocity garrysmod.Vector? If set and previous argument is unset, launches the weapon with given velocity. If the velocity is higher than 400, it will be clamped to 400.
function Player:DropNamedWeapon( class, target, velocity ) end

--- [SERVER]
---
--- Drops any object the player is currently holding with either Gravity Gun, Physics Gun or `+use` (E key)
---
--- See also [Entity:ForcePlayerDrop](https://wiki.facepunch.com/gmod/Entity:ForcePlayerDrop).
---
---@param entity garrysmod.Entity? Only drop if the held entity is this entity. If left blank, drop any held entity.
function Player:DropObject( entity ) end

--- [SERVER]
---
--- Forces the player to drop the specified weapon
---
---@param weapon garrysmod.Weapon? Weapon to be dropped. If unset, will default to the currently equipped weapon.
---@param target garrysmod.Vector? If set, launches the weapon at given position. There is a limit to how far it is willing to throw the weapon. Overrides velocity argument.
---@param velocity garrysmod.Vector? If set and previous argument is unset, launches the weapon with given velocity. If the velocity is higher than 400, it will be clamped to 400.
function Player:DropWeapon( weapon, target, velocity ) end

--- [SERVER]
---
--- Force puts the player into a specified vehicle.
--- This **does not** bypass [GM:CanPlayerEnterVehicle](https://wiki.facepunch.com/gmod/GM:CanPlayerEnterVehicle).
---
---@param vehicle garrysmod.Vehicle Vehicle the player will enter
function Player:EnterVehicle( vehicle ) end

--- [SERVER]
---
--- Equips the player with the HEV suit.
---
--- Allows the player to zoom, walk slowly, sprint, pickup armor batteries, use the health and armor stations and also shows the HUD.
--- The player also emits a flatline sound on death, which can be overridden with [GM:PlayerDeathSound](https://wiki.facepunch.com/gmod/GM:PlayerDeathSound).
---
--- The player is automatically equipped with the suit on spawn, if you wish to stop that, use [Player:RemoveSuit](https://wiki.facepunch.com/gmod/Player:RemoveSuit).
---
---@param play_effects boolean? If set to `true`, play the suit glove admire animation if player is holding no weapons. Defaults to `false`.
function Player:EquipSuit( play_effects ) end

--- [SERVER]
---
--- Forces the player off the current ladder if they are on one.
---
function Player:ExitLadder() end

--- [SERVER]
---
--- Forces the player to exit the vehicle if they're in one.
---
--- This function will bypass [GM:CanExitVehicle](https://wiki.facepunch.com/gmod/GM:CanExitVehicle). See also [GM:PlayerLeaveVehicle](https://wiki.facepunch.com/gmod/GM:PlayerLeaveVehicle)
---
function Player:ExitVehicle() end

--- [SERVER]
---
--- Enables/Disables the player's flashlight.
---
--- [Player:CanUseFlashlight](https://wiki.facepunch.com/gmod/Player:CanUseFlashlight) must be true in order for the player's flashlight to be changed.
--- [GM:PlayerSwitchFlashlight](https://wiki.facepunch.com/gmod/GM:PlayerSwitchFlashlight) can block this function.
---
--- > NOTE: Added in [2025.11.12](https://gmod.facepunch.com/changelist/4026), the `gmod_flashlight` attachment is used as a source for the player's flashlight. In thirdperson, the playermodel and weapon worldmodel are checked; in firstperson, the viewmodel is checked. If the attachment isn't found, default engine functionality is used.
--- >
--- > The light sprite attached to the playermodel when the flashlight is on will also follow the playermodel's `gmod_flashlight` attachment if it exists.
---
---@param is_on boolean Turns the flashlight on/off
function Player:Flashlight( is_on ) end

--- [SHARED]
---
--- Returns true if the player's flashlight is on.
---
---@return boolean is_on Whether the player's flashlight is on.
function Player:FlashlightIsOn() end

--- [SHARED]
---
--- Returns the amount of frags a player has.
---
--- > NOTE: The value will change depending on the player's kill or suicide: +1 for a kill, -1 for a suicide.
---
---@return integer frags The amount of frags the player has.
function Player:Frags() end

--- [SHARED]
---
--- Returns the player's active weapon.
---
--- If used on a [Global.LocalPlayer](https://wiki.facepunch.com/gmod/Global.LocalPlayer)() and the player is spectating another player with `OBS_MODE_IN_EYE`, the weapon returned will be of the spectated player.
---
---@return garrysmod.Weapon weapon The weapon the player currently has equipped or NULL if the player doesn't have an active weapon eg. when they're dead.
function Player:GetActiveWeapon() end

--- [SERVER]
---
--- Returns the player's current activity.
---
---@return integer act The player's current activity. See [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
function Player:GetActivity() end

--- [SHARED]
---
--- Returns the direction that the player is aiming.
---
---@return garrysmod.Vector direction The direction vector of players aim
function Player:GetAimVector() end

--- [SHARED]
---
--- Returns true if the players' model is allowed to rotate around the pitch and roll axis.
---
---@return boolean allowed `true` if the model is allowed to rotate around the pitch and roll axis.
function Player:GetAllowFullRotation() end

--- [SHARED]
---
--- Returns whether the player is allowed to use their weapons in a vehicle or not.
---
---@return boolean allowed Whether the player is allowed to use their weapons in a vehicle or not.
function Player:GetAllowWeaponsInVehicle() end

--- [SHARED]
---
--- Returns a table of all ammo the player has.
---
---@return table<integer, integer> ammo A table of ammo IDs (see [game.GetAmmoName](https://wiki.facepunch.com/gmod/game.GetAmmoName)) to the amount of ammo the player has of this kind.
function Player:GetAmmo() end

--- [SHARED]
---
--- Gets the amount of ammo the player has.
---
---@param ammo_type integer | string The ammunition type, either an ammo ID or an ammo name.
---@return integer count The amount of ammo player has in reserve.
function Player:GetAmmoCount( ammo_type ) end

--- [SHARED]
---
--- Gets if the player will be pushed out of nocollided players.
---
---@return boolean avoid_players `true` if the player will be pushed out of nocollided players.
function Player:GetAvoidPlayers() end

--- [SHARED]
---
--- Returns true if the player is able to walk using the (default) alt key.
---
---@return boolean can_walk `true` if the player is able to walk.
function Player:GetCanWalk() end

--- [SHARED]
---
--- Determines whenever the player is allowed to use the zoom functionality.
---
---@return boolean can_zoom `true` if the player is allowed to zoom.
function Player:GetCanZoom() end

--- [SHARED]
---
--- Returns the player's class id.
---
---@return integer class_id The player's class id.
function Player:GetClassID() end

--- [SHARED]
---
--- Returns the crouched walk speed multiplier.
---
--- See also [Player:GetWalkSpeed](https://wiki.facepunch.com/gmod/Player:GetWalkSpeed) and [Player:SetCrouchedWalkSpeed](https://wiki.facepunch.com/gmod/Player:SetCrouchedWalkSpeed).
---
---@return number multiplier The crouched walk speed multiplier.
function Player:GetCrouchedWalkSpeed() end

--- [SHARED]
---
--- Returns the last command which was sent by the specified player. This can only be called on the player which [Global.GetPredictionPlayer](https://wiki.facepunch.com/gmod/Global.GetPredictionPlayer)() returns.
---
--- > NOTE: When called clientside in singleplayer during [WEAPON:Think](https://wiki.facepunch.com/gmod/WEAPON:Think), it will return nothing as the hook is not technically predicted in that instance. See the note on the page.
---
--- > BUG: This will fail in [GM:StartCommand](https://wiki.facepunch.com/gmod/GM:StartCommand).
--- > See [issue #3302](https://github.com/Facepunch/garrysmod-issues/issues/3302).
---
---@return garrysmod.UserCommand command The last user command.
function Player:GetCurrentCommand() end

--- [SHARED]
---
--- Gets the current applied view offset, which transitions between the player's standing and ducked view offset depending on their duck state.
---
--- Do not confuse with [Player:GetViewOffset](https://wiki.facepunch.com/gmod/Player:GetViewOffset) and [Player:GetViewOffsetDucked](https://wiki.facepunch.com/gmod/Player:GetViewOffsetDucked), which always return the standing or ducked offset respectively.
---
---@return garrysmod.Vector view_offset The actual view offset.
function Player:GetCurrentViewOffset() end

--- [SHARED]
---
--- Gets the entity the player is currently driving via the [drive](https://wiki.facepunch.com/gmod/drive) library.
---
---@return garrysmod.Entity entity The currently driven entity, or NULL entity
function Player:GetDrivingEntity() end

--- [SHARED]
---
--- Returns driving mode of the player. See [Entity Driving](https://wiki.facepunch.com/gmod/Entity_Driving).
---
---@return integer mode The drive mode ID or 0 if player doesn't use the drive system.
function Player:GetDrivingMode() end

--- [SHARED]
---
--- Returns a player's duck speed (in seconds)
---
---@return number duck_speed The duck speed, in seconds.
function Player:GetDuckSpeed() end

--- [SHARED]
---
--- Returns the entity the player is currently using, like func_tank mounted turrets or +use prop pickups.
---
---@return garrysmod.Entity entity Entity in use, or NULL entity otherwise. For +use prop pickups, this will be NULL clientside.
function Player:GetEntityInUse() end

--- [CLIENT]
---
--- Returns the color of a player's flashlight.
---
---@return garrysmod.Color color Flashlight color
function Player:GetFlashlightColor() end

--- [SHARED]
---
--- Returns the FOV of the player.
---
---@return number fov Field of view as a float
function Player:GetFOV() end

--- [CLIENT]
---
--- Returns the steam "relationship" towards the player.
---
---@return "friend" | "blocked" | "none" | "requested" | "error_nofriendid" status Should return one of four different things depending on their status on your friends list: "friend", "blocked", "none", "requested" or "error_nofriendid" for bots.
function Player:GetFriendStatus() end

--- [SHARED]
---
--- Gets the hands entity of a player
---
---@return garrysmod.Entity hands The hands entity if players has one
function Player:GetHands() end

--- [SHARED]
---
--- Returns the widget the player is hovering with their mouse.
---
---@return garrysmod.Entity widget The hovered widget.
function Player:GetHoveredWidget() end

--- [SHARED]
---
--- Retrieves the minimum and maximum [Vectors](https://wiki.facepunch.com/gmod/Vector) of the [Axis-Aligned Bounding Box (AABB)](https://en.wikipedia.org/wiki/Minimum_bounding_box) used for the [Player's](https://wiki.facepunch.com/gmod/Player) physics and movement [Hull Traces](https://wiki.facepunch.com/gmod/util.TraceHull).
---
--- See also: [Player:SetHull](https://wiki.facepunch.com/gmod/Player:SetHull), [Player:SetHullDuck](https://wiki.facepunch.com/gmod/Player:SetHullDuck), [Player:GetHullDuck](https://wiki.facepunch.com/gmod/Player:GetHullDuck)
---
---@return garrysmod.Vector mins The hull mins, the lowest corner of the Player's bounding box.
---@return garrysmod.Vector maxs The hull maxs, the highest corner of the Player's bounding box, opposite of the mins.
function Player:GetHull() end

--- [SHARED]
---
--- Retrieves the minimum and maximum [Vectors](https://wiki.facepunch.com/gmod/Vector) of the [Axis-Aligned Bounding Box (AABB)](https://en.wikipedia.org/wiki/Minimum_bounding_box) used for the [Player's](https://wiki.facepunch.com/gmod/Player) physics and movement [Hull Traces](https://wiki.facepunch.com/gmod/util.TraceHull) while they are crouching (or "Ducking").
---
--- See also: [Player:SetHullDuck](https://wiki.facepunch.com/gmod/Player:SetHullDuck), [Player:GetHull](https://wiki.facepunch.com/gmod/Player:GetHull), [Player:SetHull](https://wiki.facepunch.com/gmod/Player:SetHull)
---
---@return garrysmod.Vector mins The hull mins, the lowest corner of the Player's bounding box while crouching.
---@return garrysmod.Vector maxs The hull maxs, the highest corner of the Player's crouching bounding box, opposite of the mins.
function Player:GetHullDuck() end

--- [SHARED]
---
--- Retrieves the value of a client-side [ConVar](https://wiki.facepunch.com/gmod/ConVar). The [ConVar](https://wiki.facepunch.com/gmod/ConVar) must have a [FCVAR_USERINFO](https://wiki.facepunch.com/gmod/Enums/FCVAR) flag for this to work.
---
--- On client this function will return value of the local player, regardless of which player the function was called on!
---
--- See [Player:GetInfoNum](https://wiki.facepunch.com/gmod/Player:GetInfoNum) for the same function that automatically converts the string to a number.
---
--- > WARNING: (return value) The returned value is truncated to 259 bytes.
---
---@param convar_name string The name of the client-side [ConVar](https://wiki.facepunch.com/gmod/ConVar).
---@return string | nil value The value of the [ConVar](https://wiki.facepunch.com/gmod/ConVar). Will return empty string if the convar doesn't exist (when called on the server), or `nil` when called on client, or the convar is blacklisted, such as password convars (both realms).
function Player:GetInfo( convar_name ) end

--- [SHARED]
---
--- Retrieves the numeric value of a client-side convar, returns nil if value is not convertible to a number. The [ConVar](https://wiki.facepunch.com/gmod/ConVar) must have a [FCVAR_USERINFO](https://wiki.facepunch.com/gmod/Enums/FCVAR) flag for this to work.
---
---@param convar_name string The name of the [ConVar](https://wiki.facepunch.com/gmod/ConVar) to query the value of
---@param default number Default value if we failed to retrieve the number.
---@return number value The value of the [ConVar](https://wiki.facepunch.com/gmod/ConVar) or the default value
function Player:GetInfoNum( convar_name, default ) end

--- [SHARED]
---
--- Returns the jump power of the player
---
---@return number jump_power Jump power
function Player:GetJumpPower() end

--- [SHARED]
---
--- Returns the player's ladder climbing speed.
---
--- See [Player:GetWalkSpeed](https://wiki.facepunch.com/gmod/Player:GetWalkSpeed) for normal walking speed, [Player:GetRunSpeed](https://wiki.facepunch.com/gmod/Player:GetRunSpeed) for sprinting speed and [Player:GetSlowWalkSpeed](https://wiki.facepunch.com/gmod/Player:GetSlowWalkSpeed) for slow walking speed.
---
---@return number speed The ladder climbing speed.
function Player:GetLadderClimbSpeed() end

--- [SHARED]
---
--- Returns the timescale multiplier of the player movement.
---
---@return number timescale The timescale multiplier, defaults to `1`.
function Player:GetLaggedMovementValue() end

--- [SHARED]
---
--- Returns the maximum amount of armor the player should have. Default value is 100.
---
---@return integer max_armor The max armor value.
function Player:GetMaxArmor() end

--- [SHARED]
---
--- Returns the player's maximum movement speed.
---
--- See also [Player:SetMaxSpeed](https://wiki.facepunch.com/gmod/Player:SetMaxSpeed), [Player:GetWalkSpeed](https://wiki.facepunch.com/gmod/Player:GetWalkSpeed) and [Player:GetRunSpeed](https://wiki.facepunch.com/gmod/Player:GetRunSpeed).
---
---@return number speed The maximum movement speed the player can go at.
function Player:GetMaxSpeed() end

--- [SHARED]
---
--- Returns whenever the player is set not to collide with their teammates.
---
---@return boolean no_collide `true` if the player does not collide with their teammates.
function Player:GetNoCollideWithTeammates() end

--- [SHARED]
---
--- Returns the the observer mode of the player
---
---@return integer mode Observe mode of that player, see [Enums/OBS_MODE](https://wiki.facepunch.com/gmod/Enums/OBS_MODE).
function Player:GetObserverMode() end

--- [SHARED]
---
--- Returns the entity the player is currently observing.
---
--- Set using [Player:SpectateEntity](https://wiki.facepunch.com/gmod/Player:SpectateEntity).
---
---@return garrysmod.Entity target The entity the player is currently spectating, or [NULL](https://wiki.facepunch.com/gmod/Global_Variables) if the player has no target.
function Player:GetObserverTarget() end

--- [SHARED]
---
--- Returns a player's character model color.
---
--- The part of the model that is colored is determined by the model's materials, and is therefore different for each model.
---
--- See [Player:GetWeaponColor](https://wiki.facepunch.com/gmod/Player:GetWeaponColor) for the accompanying function for the weapon color.
---
--- > NOTE: Override this function clientside on any Entity (including a player) with a supported model set (such as default player models) and returned color will apply to the model. This is done via the `PlayerColor` [matproxy](https://wiki.facepunch.com/gmod/matproxy).
---
---@return garrysmod.Vector color The format is `Vector(r,g,b)`, and each color component should be between 0 and 1.
function Player:GetPlayerColor() end

--- [SHARED]
---
--- Returns a table containing player information.
---
---@return table info A table containing player information.
function Player:GetPlayerInfo() end

--- [SERVER]
---
--- Returns the preferred carry angles of an object, if any are set.
---
--- Calls [GM:GetPreferredCarryAngles](https://wiki.facepunch.com/gmod/GM:GetPreferredCarryAngles) with the target entity and returns the carry angles.
---
---@param carry_ent garrysmod.Entity Entity to retrieve the carry angles of.
---@return garrysmod.Angle | nil angles Carry angles or nil if the entity has no preferred carry angles.
function Player:GetPreferredCarryAngles( carry_ent ) end

--- [SHARED]
---
--- Returns the widget entity the player is using.
---
--- Having a pressed widget stops the player from firing their weapon to allow input to be passed onto the widget.
---
---@return garrysmod.Entity widget The pressed widget.
function Player:GetPressedWidget() end

--- [SHARED]
---
--- Returns the weapon the player previously had equipped.
---
--- > WARNING: (return value) This is not guaranteed to be a weapon entity so it should be checked with [Entity:IsWeapon](https://wiki.facepunch.com/gmod/Entity:IsWeapon) for safety.
---
---@return garrysmod.Entity weapon The previous weapon of the player.
function Player:GetPreviousWeapon() end

--- [SHARED]
---
--- Returns players screen punch effect angle. See [Player:ViewPunch](https://wiki.facepunch.com/gmod/Player:ViewPunch) and [Player:SetViewPunchAngles](https://wiki.facepunch.com/gmod/Player:SetViewPunchAngles)
---
---@deprecated You should use [Player:GetViewPunchAngles](https://wiki.facepunch.com/gmod/Player:GetViewPunchAngles) instead.
---@return garrysmod.Angle punch_angle The punch angle
function Player:GetPunchAngle() end

--- [SHARED]
---
--- Returns players death ragdoll. The ragdoll is created by [Player:CreateRagdoll](https://wiki.facepunch.com/gmod/Player:CreateRagdoll).
---
--- > NOTE: Calling [Entity:GetPos](https://wiki.facepunch.com/gmod/Entity:GetPos) server-side with this function then will return the position where [Player:CreateRagdoll](https://wiki.facepunch.com/gmod/Player:CreateRagdoll) was used, as it is a hl2mp_ragdoll which is a serverside point entity that creates a clientside ragdoll for everyone (opposed to prop_ragdoll that is serverside and networks).
---
---@return garrysmod.Entity ragdoll The ragdoll. Unlike normal clientside ragdolls (`C_ClientRagdoll`), this will be a `C_HL2MPRagdoll` on the client, and `hl2mp_ragdoll` on the server.
function Player:GetRagdollEntity() end

--- [SHARED]
---
--- Returns the render angles for the player.
---
---@return garrysmod.Angle angles The render angles of the player. Only **yaw** part of the angle seems to be present.
function Player:GetRenderAngles() end

--- [SHARED]
---
--- Returns the player's sprint speed.
---
--- See also [Player:SetRunSpeed](https://wiki.facepunch.com/gmod/Player:SetRunSpeed), [Player:GetWalkSpeed](https://wiki.facepunch.com/gmod/Player:GetWalkSpeed) and [Player:GetMaxSpeed](https://wiki.facepunch.com/gmod/Player:GetMaxSpeed).
---
---@return number speed The sprint speed
function Player:GetRunSpeed() end

--- [SHARED]
---
--- Returns the position of a Player's view
---
--- > NOTE: This is the same as calling [Entity:EyePos](https://wiki.facepunch.com/gmod/Entity:EyePos) on the player.
---
---@return garrysmod.Vector position The position of the player's view.
function Player:GetShootPos() end

--- [SHARED]
---
--- Returns the player's slow walking speed, which is activated via `+WALK` keybind.
---
--- See [Player:GetWalkSpeed](https://wiki.facepunch.com/gmod/Player:GetWalkSpeed) for normal walking speed, [Player:GetRunSpeed](https://wiki.facepunch.com/gmod/Player:GetRunSpeed) for sprinting speed and [Player:GetLadderClimbSpeed](https://wiki.facepunch.com/gmod/Player:GetLadderClimbSpeed) for ladder climb speed.
---
---@return number speed The slow walking speed.
function Player:GetSlowWalkSpeed() end

--- [SHARED]
---
--- Returns the maximum height player can step onto.
---
---@return number step_size The maximum height player can get up onto without jumping, in hammer units.
function Player:GetStepSize() end

--- [SHARED]
---
--- Returns the player's HEV suit power.
---
--- > BUG: This will only work for the local player when used clientside.
--- > See [issue #3449](https://github.com/Facepunch/garrysmod-issues/issues/3449).
---
---@return number power The current suit power.
function Player:GetSuitPower() end

--- [SERVER]
---
--- Returns the number of seconds that the player has been timing out for. You can check if a player is timing out with [Player:IsTimingOut](https://wiki.facepunch.com/gmod/Player:IsTimingOut).
---
--- > NOTE: This function is relatively useless because it is tied to the value of the `sv_timeout` ConVar, which is irrelevant to the description above. [This is not considered as a bug](https://discord.com/channels/565105920414318602/567617926991970306/748970396224585738).
---
---@return number seconds Timeout seconds.
function Player:GetTimeoutSeconds() end

--- [SHARED]
---
--- Returns a player's unduck speed (in seconds)
---
---@return number unduck_speed The unduck speed, in seconds.
function Player:GetUnDuckSpeed() end

--- [SHARED]
---
--- Returns the entity the player would use if they would press their `+use` keybind.
---
--- This will call [GM:FindUseEntity](https://wiki.facepunch.com/gmod/GM:FindUseEntity).
---
--- > NOTE: Because entity physics objects usually do not exist on the client, the client's use entity will resolve to whatever the crosshair is placed on within a little less than 72 units of the player's eye position. This differs from the entity returned by the server, which has fully physical use checking. See [util.TraceHull](https://wiki.facepunch.com/gmod/util.TraceHull).
--- >
--- > Issue tracker: [5027](https://github.com/Facepunch/garrysmod-issues/issues/5027)
--- > See [issue #5027](https://github.com/Facepunch/garrysmod-issues/issues/5027).
---
---@return garrysmod.Entity entity The entity that would be used or NULL.
function Player:GetUseEntity() end

--- [SHARED]
---
--- Returns the vehicle the player is driving.
---
---@return garrysmod.Vehicle vehicle The vehicle the player is currently driving, if any. Returns [NULL](https://wiki.facepunch.com/gmod/NULL) entity if the player is not driving.
function Player:GetVehicle() end

--- [SHARED]
---
--- Returns the entity the player is using to see from (such as the player itself, the camera, or another entity).
---
--- > NOTE: This function will not return the currently spectated entity. See [Player:GetObserverTarget](https://wiki.facepunch.com/gmod/Player:GetObserverTarget).
---
---@return garrysmod.Entity entity The entity the player is using to see from
function Player:GetViewEntity() end

--- [SHARED]
---
--- Returns the player's view model entity by the index.
--- Each player has 3 view models by default, but only the first one is used.
---
--- To use the other viewmodels in your SWEP, see [Entity:SetWeaponModel](https://wiki.facepunch.com/gmod/Entity:SetWeaponModel).
---
--- > NOTE: In the Client [realm](https://wiki.facepunch.com/gmod/States), other players' viewmodels are not available unless they are being spectated.
---
---@param index integer? optional index of the view model to return, can range from 0 to 2 Defaults to `0`.
---@return garrysmod.Entity view_model The view model entity
function Player:GetViewModel( index ) end

--- [SHARED]
---
--- Returns the view offset of the player, which equals the difference between the player's actual position and their view when standing.
---
--- See also [Player:GetViewOffsetDucked](https://wiki.facepunch.com/gmod/Player:GetViewOffsetDucked).
---
---@return garrysmod.Vector view_offset The view offset, local to the player's [Entity:GetPos](https://wiki.facepunch.com/gmod/Entity:GetPos).
function Player:GetViewOffset() end

--- [SHARED]
---
--- Returns the ducked view offset of the player, which equals the difference between the player's actual position and their view when ducked.
---
--- See also [Player:GetViewOffset](https://wiki.facepunch.com/gmod/Player:GetViewOffset).
---
---@return garrysmod.Vector view_offset The crouching view offset, local to the player's [Entity:GetPos](https://wiki.facepunch.com/gmod/Entity:GetPos).
function Player:GetViewOffsetDucked() end

--- [SHARED]
---
--- Returns players screen punch effect angle.
---
---@return garrysmod.Angle punch_angle The punch angle
function Player:GetViewPunchAngles() end

--- [SHARED]
---
--- Returns client's view punch velocity. See [Player:ViewPunch](https://wiki.facepunch.com/gmod/Player:ViewPunch) and [Player:SetViewPunchVelocity](https://wiki.facepunch.com/gmod/Player:SetViewPunchVelocity)
---
---@return garrysmod.Angle punch_velocity The current view punch angle velocity.
function Player:GetViewPunchVelocity() end

--- [CLIENT]
---
--- Returns the current voice volume scale for given player on client.
---
---@return number scale The voice volume scale, where 0 is 0% and 1 is 100%.
function Player:GetVoiceVolumeScale() end

--- [SHARED]
---
--- Returns the player's normal walking speed. Not sprinting, not slow walking. (+walk)
---
--- See also [Player:SetWalkSpeed](https://wiki.facepunch.com/gmod/Player:SetWalkSpeed), [Player:GetMaxSpeed](https://wiki.facepunch.com/gmod/Player:GetMaxSpeed) and [Player:GetRunSpeed](https://wiki.facepunch.com/gmod/Player:GetRunSpeed).
---
---@return number speed The normal walking speed.
function Player:GetWalkSpeed() end

--- [SHARED]
---
--- Returns the weapon for the specified class
---
---@param class_name string Class name of weapon
---@return garrysmod.Weapon weapon The weapon for the specified class, or NULL ENTITY if the player does not have this weapon.
function Player:GetWeapon( class_name ) end

--- [SHARED]
---
--- Returns a player's weapon color.
---
--- The part of the model that is colored is determined by the model itself, and is different for each model.
---
--- See [Player:GetPlayerColor](https://wiki.facepunch.com/gmod/Player:GetPlayerColor) for the accompanying function for the player character model color.
---
---@return garrysmod.Vector color The format is `Vector(r,g,b)`, and each color should be between 0 and 1.
function Player:GetWeaponColor() end

--- [SHARED]
---
--- Returns a table of the player's weapons.
---
--- > NOTE: This function returns a sequential table. Prefer to loop it with [Global.ipairs](https://wiki.facepunch.com/gmod/Global.ipairs) instead of the [Global.pairs](https://wiki.facepunch.com/gmod/Global.pairs) function.
---
---@return garrysmod.Weapon[] weapons All the weapons the player currently has.
function Player:GetWeapons() end

--- [SERVER]
---
--- Gives the player a weapon.
---
--- This function will call [GM:PlayerCanPickupWeapon](https://wiki.facepunch.com/gmod/GM:PlayerCanPickupWeapon). If that hook returns false, this function will do nothing.
---
--- > NOTE: While this function is meant for weapons/pickupables only, it is **not** restricted to weapons. Any entity can be spawned using this function, including NPCs and SENTs.
---
---@param weapon_class_name string Class name of weapon to give the player
---@param no_ammo boolean? Set to true to not give any ammo on weapon spawn. (Reserve ammo set by DefaultClip) Defaults to `false`.
---@return garrysmod.Weapon weapon The weapon given to the player, if one was given. It will return NULL if the player already has the weapon, or the weapon entity (entity with given classname) doesn't exist.
function Player:Give( weapon_class_name, no_ammo ) end

--- [SERVER]
---
--- Gives ammo to a player
---
---@param amount integer Amount of ammo
---@param ammo_type string | integer Type of ammo. This is a string for named ammo types, and a number for ammo ID. You can find a list of default ammo types [here](https://wiki.facepunch.com/gmod/Default_Ammo_Types).
---@param hide_popup boolean? Hide display popup when giving the ammo Defaults to `false`.
---@return integer given Ammo given.
function Player:GiveAmmo( amount, ammo_type, hide_popup ) end

--- [SHARED]
---
--- Returns if the player has the specified weapon
---
---@param class_name string Class name of the weapon
---@return boolean has_weapon True if the player has the weapon
function Player:HasWeapon( class_name ) end

--- [SHARED]
---
--- Returns if the player is in a vehicle
---
---@return boolean in_vehicle Whether the player is in a vehicle.
function Player:InVehicle() end

--- [SERVER]
---
--- Returns the player's IP address and connection port in ip:port form
---
--- > NOTE: Returns `Error!` for bots.
---
---@return string address The player's IP address and connection port
function Player:IPAddress() end

--- [SHARED]
---
--- Returns if the player is an bot or not
---
---@return boolean is_bot `true` if the player is a bot.
function Player:IsBot() end

--- [SERVER]
---
--- Returns true from the point when the player is sending client info but not fully in the game until they disconnect.
---
---@return boolean is_connected `true` if the player is connected.
function Player:IsConnected() end

--- [SHARED]
---
--- Used to find out if a player is currently 'driving' an entity (by which we mean 'right click > drive' ).
---
---@return boolean is_driving A value representing whether or not the player is 'driving' an entity.
function Player:IsDrivingEntity() end

--- [SERVER]
---
--- Returns whether the player identity was confirmed by the Steam network.
---
--- See also [GM:NetworkIDValidated](https://wiki.facepunch.com/gmod/GM:NetworkIDValidated).
---
---@return boolean is_authenticated Whether the player has been fully authenticated or not. This will always be true for singleplayer and the listen server host. This will always be false for bots.
function Player:IsFullyAuthenticated() end

--- [SHARED]
---
--- Returns if a player is the host of the current session.
---
---@return boolean is_host `true` if the player is the listen server host, `false` otherwise. This will always be `true` in single player, and `false` on a dedicated server.
function Player:IsListenServerHost() end

--- [CLIENT]
---
--- Returns whether or not the player is voice muted locally.
---
---@return boolean is_muted whether or not the player is muted locally.
function Player:IsMuted() end

--- [SHARED]
---
--- Returns true if the player is playing a taunt.
---
---@return boolean is_taunting Whether the player is playing a taunt.
function Player:IsPlayingTaunt() end

--- [SHARED]
---
--- Returns whenever the player is heard by the local player clientside, or if the player is speaking serverside.
---
---@return boolean is_speaking Is the player speaking or not.
function Player:IsSpeaking() end

--- [SHARED]
---
--- Returns whether the player is currently sprinting or not, specifically if they are holding their sprint key and are allowed to sprint.
---
--- This will not check if the player is currently sprinting into a wall. (i.e. holding their sprint key but not moving)
---
---@return boolean is_sprinting Is the player sprinting or not
function Player:IsSprinting() end

--- [SHARED]
---
--- Returns whenever the player is equipped with the suit item.
---
--- > BUG: This will only work for the local player when used clientside.
--- > See [issue #3449](https://github.com/Facepunch/garrysmod-issues/issues/3449).
---
---@return boolean is_equipped Is the suit equipped or not.
function Player:IsSuitEquipped() end

--- [SERVER]
---
--- Returns `true` if the player is timing out (i.e. is losing connection), `false` otherwise.
---
--- A player is considered timing out when more than 4 seconds has elapsed since a network packet was received from given player.
---
---@return boolean is_timing_out Whether the player is timing out.
function Player:IsTimingOut() end

--- [SHARED]
---
--- Returns whether the player is typing in their chat.
---
--- This may not work properly if the server uses a custom chatbox.
---
---@return boolean is_typing Whether the player is typing in their chat or not.
function Player:IsTyping() end

--- [CLIENT]
---
--- Returns if the player can be heard by the local player.
---
---@return boolean is_audible `true` if the player can be heard by the local player.
function Player:IsVoiceAudible() end

--- [SHARED]
---
--- Returns if the player currently walking. (`+walk` keybind)
---
---@return boolean is_walking `true` if the player is currently walking.
function Player:IsWalking() end

--- [SHARED]
---
--- Returns whether the player is using the world clicking feature, see [Panel:SetWorldClicker](https://wiki.facepunch.com/gmod/Panel:SetWorldClicker)
---
---@return boolean is_clicking Is the player world clicking or not.
function Player:IsWorldClicking() end

--- [SHARED]
---
--- Returns whether the world clicking is disabled for given player or not. See [Player:DisableWorldClicking](https://wiki.facepunch.com/gmod/Player:DisableWorldClicking).
---
---@return boolean is_disabled Whether the world clicking is disabled or not.
function Player:IsWorldClickingDisabled() end

--- [SHARED]
---
--- Returns whether a key is down. This is not networked to other players, meaning only the local client can see the keys they are pressing.
---
---@param key integer The key, see [Enums/IN](https://wiki.facepunch.com/gmod/Enums/IN)
---@return boolean is_down whether the key is down or not.
function Player:KeyDown( key ) end

--- [SHARED]
---
--- Gets whether a key was down one tick ago.
---
---@param key integer The key, see [Enums/IN](https://wiki.facepunch.com/gmod/Enums/IN)
---@return boolean was_down Whether the key was down one tick ago.
function Player:KeyDownLast( key ) end

--- [SHARED]
---
--- Gets whether a key was just pressed this tick.
---
---@param key integer Corresponds to an [Enums/IN](https://wiki.facepunch.com/gmod/Enums/IN). You can use [bit.bor](https://wiki.facepunch.com/gmod/bit.bor) here (see example 2)
---@return boolean is_pressed Whether the key was just pressed.
function Player:KeyPressed( key ) end

--- [SHARED]
---
--- Gets whether a key was just released this tick.
---
---@param key integer The key, see [Enums/IN](https://wiki.facepunch.com/gmod/Enums/IN)
---@return boolean is_released Whether the key was just released.
function Player:KeyReleased( key ) end

--- [SERVER]
---
--- Kicks the player from the server.
---
--- > NOTE: This can not be run before the player has fully joined in. Use [game.KickID](https://wiki.facepunch.com/gmod/game.KickID) for that.
---
--- > WARNING: (`reason` argument) This will be shortened to ~512 chars, though this includes the command itself and the player index so will realistically be more around ~498. It is recommended to avoid going near the limit to avoid truncation.
---
---@param reason string? Reason to show for disconnection. Defaults to `No reason given`.
function Player:Kick( reason ) end

--- [SERVER]
---
--- Kills a player and calls [GM:PlayerDeath](https://wiki.facepunch.com/gmod/GM:PlayerDeath).
---
function Player:Kill() end

--- [SERVER]
---
--- Kills a player without notifying the rest of the server.
---
--- This will call [GM:PlayerSilentDeath](https://wiki.facepunch.com/gmod/GM:PlayerSilentDeath) instead of [GM:PlayerDeath](https://wiki.facepunch.com/gmod/GM:PlayerDeath).
---
function Player:KillSilent() end

--- [SHARED]
---
--- This allows the server to mitigate the lag of the player by moving back all the entities that can be lag compensated to the time the player attacked with his weapon.
---
--- This technique is most commonly used on things that hit other entities instantaneously, such as traces.
---
--- > NOTE: [Entity:FireBullets](https://wiki.facepunch.com/gmod/Entity:FireBullets) calls this function internally.
---
--- Lag compensation only works for players and entities that have been enabled with [Entity:SetLagCompensated](https://wiki.facepunch.com/gmod/Entity:SetLagCompensated)
---
--- Despite being defined shared, it can only be used server-side in a [Predicted Hook](https://wiki.facepunch.com/gmod/~search?q=%3Cpredicted%3EYes).
---
--- > WARNING: This function NEEDS to be disabled after you're done with it or it will break the movement of the entities affected!
---
--- > BUG: Lag compensation does not support pose parameters.
--- > See [issue #3683](https://github.com/Facepunch/garrysmod-issues/issues/3683).
---
---@param lag_compensation boolean The state of the lag compensation, true to enable and false to disable.
function Player:LagCompensation( lag_compensation ) end

--- [SERVER]
---
--- Returns the hitgroup where the player was last hit.
---
---@return integer hitgroup Hitgroup, see [Enums/HITGROUP](https://wiki.facepunch.com/gmod/Enums/HITGROUP)
function Player:LastHitGroup() end

--- [SHARED]
---
--- Returns the direction a player is looking as a entity/local-oriented angle.
---
--- Unlike [Entity:EyeAngles](https://wiki.facepunch.com/gmod/Entity:EyeAngles), this function does not include angles of the Player's [Entity:GetParent](https://wiki.facepunch.com/gmod/Entity:GetParent).
---
--- > BUG: Does not work correctly clientside for non local players when in a vehicle. (validate: when parented in general?)
---
---@return garrysmod.Angle angles The local eye angles.
function Player:LocalEyeAngles() end

--- [SERVER]
---
--- Stops a player from using any inputs, such as moving, turning, or attacking. Key binds are still called. Similar to [Player:Freeze](https://wiki.facepunch.com/gmod/Player:Freeze) but the player takes no damage.
---
--- Adds the [FL_FROZEN](https://wiki.facepunch.com/gmod/Enums/FL) and [FL_GODMODE](https://wiki.facepunch.com/gmod/Enums/FL) flags to the player.
---
function Player:Lock() end

--- [SHARED]
---
--- Returns the position of a Kinect bone.
---
---@param bone integer Bone to get the position of. Must be from 0 to 19.
---@return garrysmod.Vector position Position of the bone.
function Player:MotionSensorPos( bone ) end

--- [SHARED]
---
--- Returns the player's nick name also known as display name, as it appears in Steam.
---
---@return string nick Player's nick name
function Player:Nick() end

--- [SERVER]
---
--- Returns the 64-bit SteamID aka CommunityID of the Steam Account that owns the Garry's Mod license this player is using. This is useful for detecting players using Steam Family Sharing.
---
--- If player is not using Steam Family Sharing, this will return the player's actual SteamID64().
---
--- > NOTE: This data will only be available after the player has fully authenticated with Steam. See [Player:IsFullyAuthenticated](https://wiki.facepunch.com/gmod/Player:IsFullyAuthenticated).
---
---@return string steam_id64 The 64bit SteamID
function Player:OwnerSteamID64() end

--- [SHARED]
---
--- Returns the percentage of packets lost by the client. It is not networked so it only returns 0 when run clientside.
---
---@return integer packet_loss Percentage of packets lost (0-100)
function Player:PacketLoss() end

--- [SERVER]
---
--- This makes the player hold (same as pressing `E` on a small prop) given entity.
---
--- Not to be confused with picking up items like ammo or health kits.
---
--- This picks up the passed entity regardless of its mass or distance from the player.
---
---@param entity garrysmod.Entity Entity to pick up.
function Player:PickupObject( entity ) end

--- [SERVER]
---
--- Forces the player to pickup an existing weapon entity. The player will not pick up the weapon if they already own a weapon of given type, or if the player could not normally have this weapon in their inventory.
---
--- This function **will** bypass [GM:PlayerCanPickupWeapon](https://wiki.facepunch.com/gmod/GM:PlayerCanPickupWeapon).
---
---@param weapon garrysmod.Weapon The weapon to try to pick up.
---@param ammo_only boolean? If set to true, the player will only attempt to pick up the ammo from the weapon. The weapon will not be picked up even if the player doesn't have a weapon of this type, and the weapon will be removed if the player picks up any ammo from it. Defaults to `false`.
---@return boolean success Whether the player succeeded in picking up the weapon or not.
function Player:PickupWeapon( weapon, ammo_only ) end

--- [SHARED]
---
--- Returns the player's ping to server.
---
---@return integer ping The player's ping.
function Player:Ping() end

--- [SERVER]
---
--- Plays the correct step sound according to what the player is staying on.
---
---@param volume number? Volume for the sound, in range from 0 to 1 Defaults to `1`.
function Player:PlayStepSound( volume ) end

--- [SHARED]
---
--- Displays a message either in their chat, console, or center of the screen. See also [Global.PrintMessage](https://wiki.facepunch.com/gmod/Global.PrintMessage).
---
--- > NOTE: When called serverside, this uses the archaic user message system (the [umsg](https://wiki.facepunch.com/gmod/umsg)) and hence is limited to ≈250 characters.
--- >
--- > `HUD_PRINTCENTER` will not work when this is called clientside.
---
---@param type integer Which type of message should be sent to the player ([Enums/HUD](https://wiki.facepunch.com/gmod/Enums/HUD)).
---@param message string Message to be sent to the player.
function Player:PrintMessage( type, message ) end

--- [SERVER]
---
--- Removes all ammo from a certain player
---
function Player:RemoveAllAmmo() end

--- [SERVER]
---
--- Removes all weapons and ammo from the player.
---
function Player:RemoveAllItems() end

--- [SHARED]
---
--- Removes the amount of the specified ammo from the player.
---
---@param ammo_count integer The amount of ammunition to remove.
---@param ammo_type string | integer The name of the ammunition to remove from. This can also be a [number](https://wiki.facepunch.com/gmod/number) ammoID.
function Player:RemoveAmmo( ammo_count, ammo_type ) end

--- [SERVER]
---
--- Strips the player's suit item.
---
function Player:RemoveSuit() end

--- [SHARED]
---
--- Resets both normal and duck hulls to their default values.
---
function Player:ResetHull() end

--- [SERVER]
---
--- Forces the player to say whatever the first argument is. Works on bots too.
---
--- > NOTE: This function ignores the default chat message cooldown
---
--- > WARNING: The argument can only contain 126 characters. [Source SDK 2013](https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/sp/src/game/server/client.cpp#L84-L86)
---
---@param text string The text to force the player to say.
---@param team_only boolean? Whether to send this message to our own team only. Defaults to `false`.
function Player:Say( text, team_only ) end

--- [SHARED]
---
--- Fades the screen
---
---@param flags integer Fade flags defined with [Enums/SCREENFADE](https://wiki.facepunch.com/gmod/Enums/SCREENFADE).
---@param color garrysmod.Color? The color of the screenfade Defaults to `color_white`.
---@param fade_time number Fade(in/out) effect transition time ( From no fade to full fade and vice versa ). This is limited to 7 bits integer part and 9 bits fractional part.
---@param fade_hold number Fade effect hold time. This is limited to 7 bits integer part and 9 bits fractional part.
function Player:ScreenFade( flags, color, fade_time, fade_hold ) end

--- [SERVER]
---
--- Sets the active weapon of the player by its class name.
---
--- > WARNING: This will switch the weapon out of prediction, causing delay on the client and [WEAPON:Deploy](https://wiki.facepunch.com/gmod/WEAPON:Deploy) and [WEAPON:Holster](https://wiki.facepunch.com/gmod/WEAPON:Holster) to be called out of prediction. Try using [CUserCmd:SelectWeapon](https://wiki.facepunch.com/gmod/CUserCmd:SelectWeapon) or [input.SelectWeapon](https://wiki.facepunch.com/gmod/input.SelectWeapon), instead.
---
--- > NOTE: This will trigger the weapon switch event and associated animations. To switch weapons silently, use [Player:SetActiveWeapon](https://wiki.facepunch.com/gmod/Player:SetActiveWeapon).
---
---@param class_name string The class name of the weapon to switch to. If the player doesn't have the specified weapon, nothing will happen. You can use [Player:Give](https://wiki.facepunch.com/gmod/Player:Give) to give the weapon first.
function Player:SelectWeapon( class_name ) end

--- [SERVER]
---
--- Executes a simple Lua string on the player.
---
--- > NOTE: If you need to use this function more than once consider using [net](https://wiki.facepunch.com/gmod/net) library. Send net message and make the entire code you want to execute in [net.Receive](https://wiki.facepunch.com/gmod/net.Receive) on client.
---
---@param script string The script to execute, limited to 6000 bytes.
function Player:SendLua( script ) end

--- [SERVER]
---
--- Sets the player's active weapon. You should use [CUserCmd:SelectWeapon](https://wiki.facepunch.com/gmod/CUserCmd:SelectWeapon) or [Player:SelectWeapon](https://wiki.facepunch.com/gmod/Player:SelectWeapon), instead in most cases.
---
--- This function will not trigger the weapon switch events or associated equip animations. It will bypass
--- [GM:PlayerSwitchWeapon](https://wiki.facepunch.com/gmod/GM:PlayerSwitchWeapon) and the currently active weapon's [WEAPON:Holster](https://wiki.facepunch.com/gmod/WEAPON:Holster) return value.
---
---@param weapon garrysmod.Weapon The weapon to equip.
function Player:SetActiveWeapon( weapon ) end

--- [SERVER]
---
--- Sets the player's activity.
---
---@param act integer The new activity to set. See [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
function Player:SetActivity( act ) end

--- [SHARED]
---
--- Set if the players' model is allowed to rotate around the pitch and roll axis.
---
---@param allowed boolean Allowed to rotate
function Player:SetAllowFullRotation( allowed ) end

--- [SERVER]
---
--- Allows player to use their weapons in a vehicle. You need to call this before entering a vehicle.
---
--- > BUG: Shooting in a vehicle fires two bullets.
--- > See [issue #1277](https://github.com/Facepunch/garrysmod-issues/issues/1277).
---
---@param allow boolean Show we allow player to use their weapons in a vehicle or not.
function Player:SetAllowWeaponsInVehicle( allow ) end

--- [SHARED]
---
--- Sets the amount of the specified ammo for the player.
---
---@param ammo_count integer The amount of ammunition to set.
---@param ammo_type integer | string The ammunition type, either an ammo ID or an ammo name. See [Default Ammo Types](https://wiki.facepunch.com/gmod/Default_Ammo_Types) for default values.
function Player:SetAmmo( ammo_count, ammo_type ) end

--- [SERVER]
---
--- Sets the player armor value.
---
--- See [GM:HandlePlayerArmorReduction](https://wiki.facepunch.com/gmod/GM:HandlePlayerArmorReduction) for a hook that allows manipulating what armor does.
---
---@param amount integer The amount to set the armor value of the player to.
function Player:SetArmor( amount ) end

--- [SHARED]
---
--- Pushes the player away from other players whenever the player inside another players' bounding box.
---
--- This avoidance is performed clientside by altering movement sent to server.
---
--- This applies to players within a single team. ([Player:Team](https://wiki.facepunch.com/gmod/Player:Team))
---
---@param avoid_players boolean Whether to avoid teammates, or not.
function Player:SetAvoidPlayers( avoid_players ) end

--- [SHARED]
---
--- Set if the player should be allowed to walk using the (default) alt key. (`+walk` keybind)
---
---@param can_walk boolean `true` allows the player to walk.
function Player:SetCanWalk( can_walk ) end

--- [SHARED]
---
--- Sets whether the player can use the HL2 suit zoom (`+zoom` bind) or not.
---
---@param can_zoom boolean Whether to make the player able or unable to zoom.
function Player:SetCanZoom( can_zoom ) end

--- [SHARED]
---
--- Sets the player's class id.
---
--- Use [player_manager.SetPlayerClass](https://wiki.facepunch.com/gmod/player_manager.SetPlayerClass) instead.
---
---@param class_id integer The class id the player is being set with.
function Player:SetClassID( class_id ) end

--- [SHARED]
---
--- Sets the crouched walk speed multiplier.
---
--- Has no effect for values above 1.
---
--- See also [Player:SetWalkSpeed](https://wiki.facepunch.com/gmod/Player:SetWalkSpeed) and [Player:GetCrouchedWalkSpeed](https://wiki.facepunch.com/gmod/Player:GetCrouchedWalkSpeed).
---
---@param speed number The walk speed multiplier that crouch speed should be.
function Player:SetCrouchedWalkSpeed( speed ) end

--- [SHARED]
---
--- Sets the **actual** view offset which equals the difference between the players actual position and their view when standing.
---
--- Do not confuse with [Player:SetViewOffset](https://wiki.facepunch.com/gmod/Player:SetViewOffset) and [Player:SetViewOffsetDucked](https://wiki.facepunch.com/gmod/Player:SetViewOffsetDucked)
---
---@param view_offset garrysmod.Vector The new view offset.
function Player:SetCurrentViewOffset( view_offset ) end

--- [SERVER]
---
--- Sets a player's death count
---
---@param death_count integer Number of deaths (positive or negative)
function Player:SetDeaths( death_count ) end

--- [SHARED]
---
--- Sets the driving entity and driving mode.
---
--- Use [drive.PlayerStartDriving](https://wiki.facepunch.com/gmod/drive.PlayerStartDriving) instead, see [Entity Driving](https://wiki.facepunch.com/gmod/Entity_Driving).
---
---@param driving_entity garrysmod.Entity? The entity the player should drive. Defaults to `NULL`.
---@param driving_mode integer The driving mode index.
function Player:SetDrivingEntity( driving_entity, driving_mode ) end

--- [SHARED]
---
--- Activates a given DSP (Digital Signal Processor) effect on all sounds that the player hears. This is equivalent to setting `dsp_player` convar on the player.
---
--- To apply a DSP effect to individual sounds, see [CSoundPatch:SetDSP](https://wiki.facepunch.com/gmod/CSoundPatch:SetDSP)
---
--- > NOTE: (`fast_reset` argument) **This only works clientside**
--- > If used serverside, a message will be displayed (`SetPlayerDSP: fastReset only valid from client`) in the server console.
---
---@param dsp_effect_id integer The index of the DSP sound filter to apply. For a list of the available IDs and their meaning, see [DSP Presets](https://wiki.facepunch.com/gmod/DSP_Presets).
---@param fast_reset boolean If set to true the sound filter will be removed faster.
function Player:SetDSP( dsp_effect_id, fast_reset ) end

--- [SHARED]
---
--- Sets how quickly a player ducks.
---
--- > BUG: This will not work for values >= 1.
--- > See [issue #2722](https://github.com/Facepunch/garrysmod-issues/issues/2722).
---
---@param duck_speed number How quickly the player will duck.
function Player:SetDuckSpeed( duck_speed ) end

--- [SHARED]
---
--- Sets the local angle of the player's view (may rotate body too if angular difference is large)
---
--- > NOTE: This function works differently when the player is in a vehicle. In that case passing `Angle(0, 90, 0)` will have the player look forward (out the windshield) and `Angle(0, 0, 0)` will have them look to the right.
---
---@param angles garrysmod.Angle Angle to set the view to
function Player:SetEyeAngles( angles ) end

--- [CLIENT]
---
--- Sets the color of a player's flashlight.
--- Can be used on other players.
---
---@param color garrysmod.Color? Flashlight color Defaults to `Color(255,255,255)`.
function Player:SetFlashlightColor( color ) end

--- [SHARED]
---
--- Set a player's FOV (Field Of View) over a certain amount of time.
---
--- This is meant to be called on the server or shared (for prediction), it will have no effect if called clientside only. You may want to use [GM:CalcView](https://wiki.facepunch.com/gmod/GM:CalcView) for that instead.
---
---@param fov number the angle of perception (FOV). Set to 0 to return to default user FOV. ( Which is ranging from 75 to 100, depending on user settings )
---@param time number? the time it takes to transition to the FOV expressed in a floating point. Defaults to `0`.
---@param requester garrysmod.Entity? The requester or "owner" of the zoom event. Only this entity will be able to change the player's FOV until it is set back to 0. Defaults to `self`.
function Player:SetFOV( fov, time, requester ) end

--- [SERVER]
---
--- Sets a player's frags (kills)
---
---@param frag_count integer Number of frags (positive or negative)
function Player:SetFrags( frag_count ) end

--- [SHARED]
---
--- Sets the hands entity of a player.
---
--- The hands entity is an entity introduced in Garry's Mod 13 and it's used to show the player's hands attached to the viewmodel.
--- This is similar to the approach used in L4D and CS:GO, for more information on how to implement this system in your gamemode visit [Using Viewmodel Hands](https://wiki.facepunch.com/gmod/Using_Viewmodel_Hands).
---
---@param hands garrysmod.Entity The hands entity to set
function Player:SetHands( hands ) end

--- [SHARED]
---
--- Sets the widget that is currently hovered by the player's mouse.
---
---@param widget garrysmod.Entity? The widget entity that the player is hovering. Defaults to `NULL`.
function Player:SetHoveredWidget( widget ) end

--- [SHARED]
---
--- Sets the size of the [Player's](https://wiki.facepunch.com/gmod/Player) [Axis-Aligned Bounding Box (AABB)](https://en.wikipedia.org/wiki/Minimum_bounding_box) used for physics and movement [Hull Traces](https://wiki.facepunch.com/gmod/util.TraceHull).
---
--- See also: [Player:GetHull](https://wiki.facepunch.com/gmod/Player:GetHull), [Player:SetHullDuck](https://wiki.facepunch.com/gmod/Player:SetHullDuck), [Player:GetHullDuck](https://wiki.facepunch.com/gmod/Player:GetHullDuck)
---
--- > NOTE: This value is **not** replicated automatically to clients and must be manually called in both the Server and Client [Realms](https://wiki.facepunch.com/gmod/States).
---
---@param mins garrysmod.Vector The hull mins, the lowest corner of the Player's bounding box.
---@param maxs garrysmod.Vector The hull maxs, the highest corner of the Player's bounding box, opposite of the mins.
function Player:SetHull( mins, maxs ) end

--- [SHARED]
---
--- Sets the size of the [Player's](https://wiki.facepunch.com/gmod/Player) [Axis-Aligned Bounding Box (AABB)](https://en.wikipedia.org/wiki/Minimum_bounding_box) used for physics and movement [Hull Traces](https://wiki.facepunch.com/gmod/util.TraceHull) while they are crouching (or "Ducking").
---
--- See also: [Player:GetHullDuck](https://wiki.facepunch.com/gmod/Player:GetHullDuck), [Player:GetHull](https://wiki.facepunch.com/gmod/Player:GetHull), [Player:SetHull](https://wiki.facepunch.com/gmod/Player:SetHull)
---
--- > NOTE: This value is **not** replicated automatically to clients and must be manually called in both the Server and Client [Realms](https://wiki.facepunch.com/gmod/States).
---
---@param mins garrysmod.Vector The hull mins, the lowest corner of the Player's bounding box while crouching.
---@param maxs garrysmod.Vector The hull maxs, the highest corner of the Player's crouching bounding box, opposite of the mins.
function Player:SetHullDuck( mins, maxs ) end

--- [SHARED]
---
--- Sets the jump power, eg. the velocity that will be applied to the player when they jump.
---
---@param jump_power number The new jump velocity.
function Player:SetJumpPower( jump_power ) end

--- [SHARED]
---
--- Sets the player's ladder climbing speed.
---
--- See [Player:SetWalkSpeed](https://wiki.facepunch.com/gmod/Player:SetWalkSpeed) for normal walking speed, [Player:SetRunSpeed](https://wiki.facepunch.com/gmod/Player:SetRunSpeed) for sprinting speed and [Player:SetSlowWalkSpeed](https://wiki.facepunch.com/gmod/Player:SetSlowWalkSpeed) for slow walking speed.
---
---@param speed number The ladder climbing speed.
function Player:SetLadderClimbSpeed( speed ) end

--- [SERVER]
---
--- Slows down the player movement simulation by the timescale, this is used internally in the HL2 weapon stripping sequence.
---
--- It achieves such behavior by multiplying the [Global.FrameTime](https://wiki.facepunch.com/gmod/Global.FrameTime) by the specified timescale at the start of the movement simulation and then restoring it afterwards.
---
--- > NOTE: This is reset to 1 on spawn.
--- >
--- > There is no weapon counterpart to this, you'll have to hardcode the multiplier in the weapon or call [Weapon:SetNextPrimaryFire](https://wiki.facepunch.com/gmod/Weapon:SetNextPrimaryFire) / [Weapon:SetNextSecondaryFire](https://wiki.facepunch.com/gmod/Weapon:SetNextSecondaryFire) manually.
---
---@param timescale number The timescale multiplier.
function Player:SetLaggedMovementValue( timescale ) end

--- [SERVER]
---
--- Sets the hitgroup where the player was last hit.
---
---@param hitgroup integer The hitgroup to set as the "last hit", see [Enums/HITGROUP](https://wiki.facepunch.com/gmod/Enums/HITGROUP).
function Player:SetLastHitGroup( hitgroup ) end

--- [SERVER]
---
--- Sets the maximum amount of armor the player should have. This affects default built-in armor pickups, but not [Player:SetArmor](https://wiki.facepunch.com/gmod/Player:SetArmor).
---
---@param max_armor integer The new max armor value.
function Player:SetMaxArmor( max_armor ) end

--- [SHARED]
---
--- Sets the maximum speed which the player can move at.
---
--- > NOTE: This is called automatically by the engine. If you wish to limit player speed without setting their run/sprint speeds, see [CMoveData:SetMaxClientSpeed](https://wiki.facepunch.com/gmod/CMoveData:SetMaxClientSpeed).
---
---@param speed number The maximum speed.
function Player:SetMaxSpeed( speed ) end

--- [CLIENT]
---
--- Sets if the player should be voicechat muted locally.
---
---@param mute boolean Mute or unmute.
function Player:SetMuted( mute ) end

--- [SHARED]
---
--- Sets whenever the player should not collide with their teammates, based on their [Player:Team](https://wiki.facepunch.com/gmod/Player:Team).
---
--- > NOTE: This will only work for teams with ID 1 to 4 due to internal Engine limitations.
---
--- > NOTE: This causes traces with [COLLISION_GROUP_PLAYER](https://wiki.facepunch.com/gmod/Enums/COLLISION_GROUP) to pass through players.
---
---@param should_not_collide boolean `true` to disable, `false` to enable collision.
function Player:SetNoCollideWithTeammates( should_not_collide ) end

--- [SERVER]
---
--- Sets the players visibility towards NPCs.
---
--- Internally this toggles the [FL_NOTARGET](https://wiki.facepunch.com/gmod/Enums/FL) flag, which you can manually test for using [Entity:IsFlagSet](https://wiki.facepunch.com/gmod/Entity:IsFlagSet)
---
---@param visibility boolean The visibility.
function Player:SetNoTarget( visibility ) end

--- [SHARED]
---
--- Sets the players observer mode. You must start the spectating first with [Player:Spectate](https://wiki.facepunch.com/gmod/Player:Spectate).
---
---@param mode integer Spectator mode using [Enums/OBS_MODE](https://wiki.facepunch.com/gmod/Enums/OBS_MODE).
function Player:SetObserverMode( mode ) end

--- [SHARED]
---
--- Sets the player model's color. The part of the model that is colored is determined by the model itself, and is different for each model.
---
---@param color garrysmod.Vector This is the color to be set. The format is Vector(r, g, b), and each color should be between 0 and 1.
function Player:SetPlayerColor( color ) end

--- [SHARED]
---
--- Sets the widget that is currently in use by the player's mouse.
---
--- Having a pressed widget stops the player from firing their weapon to allow input to be passed onto the widget.
---
---@param pressed_widget garrysmod.Entity? The widget the player is currently using. Defaults to `NULL`.
function Player:SetPressedWidget( pressed_widget ) end

--- [SHARED]
---
--- Sets the render angles of a player. Value set by this function is reset to player's angles ([Entity:GetAngles](https://wiki.facepunch.com/gmod/Entity:GetAngles)) right after [GM:UpdateAnimation](https://wiki.facepunch.com/gmod/GM:UpdateAnimation).
---
---@param angles garrysmod.Angle The new render angles to set
function Player:SetRenderAngles( angles ) end

--- [SHARED]
---
--- Sets the player's sprint speed.
---
--- See also [Player:GetRunSpeed](https://wiki.facepunch.com/gmod/Player:GetRunSpeed), [Player:SetWalkSpeed](https://wiki.facepunch.com/gmod/Player:SetWalkSpeed) and [Player:SetMaxSpeed](https://wiki.facepunch.com/gmod/Player:SetMaxSpeed).
---
--- > NOTE: player_default class run speed is: `400`
---
---@param run_speed number The new sprint speed when `sv_friction` is below `10`. Higher `sv_friction` values will result in slower speed. Has to be `7` or above or the player **won't** be able to move.
function Player:SetRunSpeed( run_speed ) end

--- [SHARED]
---
--- Sets the player's slow walking speed, which is activated via `+WALK` keybind.
---
--- See [Player:SetWalkSpeed](https://wiki.facepunch.com/gmod/Player:SetWalkSpeed) for normal walking speed, [Player:SetRunSpeed](https://wiki.facepunch.com/gmod/Player:SetRunSpeed) for sprinting speed and [Player:SetLadderClimbSpeed](https://wiki.facepunch.com/gmod/Player:SetLadderClimbSpeed) for ladder climb speed.
---
---@param speed number The new slow walking speed.
function Player:SetSlowWalkSpeed( speed ) end

--- [SHARED]
---
--- Sets the maximum height a player can step onto without jumping.
---
---@param step_height number The new maximum height the player can step onto without jumping
function Player:SetStepSize( step_height ) end

--- [SHARED]
---
--- Sets the player's HEV suit power.
---
--- > BUG: This will only work for the local player when used clientside.
--- > See [issue #3449](https://github.com/Facepunch/garrysmod-issues/issues/3449).
---
---@param power number The new suit power.
function Player:SetSuitPower( power ) end

--- [SHARED]
---
--- Sets whenever to suppress the pickup notification for the player.
---
---@param do_suppress boolean Whenever to suppress the notice or not.
function Player:SetSuppressPickupNotices( do_suppress ) end

--- [SERVER]
---
--- Sets the player to the chosen team. The value is networked to clients at reduced bit count (16 bits) as as a signed value, so the real range is [-32768, 32767].
---
--- Can be retrieved via [Player:Team](https://wiki.facepunch.com/gmod/Player:Team)
---
---@param team integer The team that the player is being set to.
function Player:SetTeam( team ) end

--- [SHARED]
---
--- Sets how quickly a player un-ducks
---
---@param un_duck_speed number How quickly the player will un-duck
function Player:SetUnDuckSpeed( un_duck_speed ) end

--- [SERVER]
---
--- Attaches the players view to the position and angles of the specified entity.
---
--- > NOTE: By default, the view is in first person and its model will not be rendered. [Player:SetObserverMode](https://wiki.facepunch.com/gmod/Player:SetObserverMode) can be used to enable drawing of view entity.
---
---@param view_entity garrysmod.Entity The entity to attach the player view to.
function Player:SetViewEntity( view_entity ) end

--- [SHARED]
---
--- Sets the **desired** view offset which equals the difference between the players actual position and their view when standing.
---
--- If you want to set **actual** view offset, use [Player:SetCurrentViewOffset](https://wiki.facepunch.com/gmod/Player:SetCurrentViewOffset)
---
--- See also [Player:SetViewOffsetDucked](https://wiki.facepunch.com/gmod/Player:SetViewOffsetDucked) for **desired** view offset when crouching.
---
---@param view_offset garrysmod.Vector The new desired view offset when standing.
function Player:SetViewOffset( view_offset ) end

--- [SHARED]
---
--- Sets the **desired** view offset which equals the difference between the players actual position and their view when crouching.
---
--- If you want to set **actual** view offset, use [Player:SetCurrentViewOffset](https://wiki.facepunch.com/gmod/Player:SetCurrentViewOffset)
---
--- See also [Player:SetViewOffset](https://wiki.facepunch.com/gmod/Player:SetViewOffset) for **desired** view offset when standing.
---
---@param view_offset garrysmod.Vector The new desired view offset when crouching.
function Player:SetViewOffsetDucked( view_offset ) end

--- [SHARED]
---
--- Sets client's view punch angle, but not the velocity. See [Player:ViewPunch](https://wiki.facepunch.com/gmod/Player:ViewPunch)
---
---@param punch_angle garrysmod.Angle The angle to set.
function Player:SetViewPunchAngles( punch_angle ) end

--- [SHARED]
---
--- Sets client's view punch velocity. See [Player:ViewPunch](https://wiki.facepunch.com/gmod/Player:ViewPunch) and [Player:SetViewPunchAngles](https://wiki.facepunch.com/gmod/Player:SetViewPunchAngles)
---
---@param punch_vel garrysmod.Angle The angle velocity to set.
function Player:SetViewPunchVelocity( punch_vel ) end

--- [CLIENT]
---
--- Sets the voice volume scale for given player on client. This value will persist from server to server, but will be reset when the game is shut down.
---
--- > NOTE: This doesn't work on bots, their scale will always be `1`. Does not work with multiruns.
---
---@param scale number The voice volume scale, where `0` is 0% and `1` is 100%.
function Player:SetVoiceVolumeScale( scale ) end

--- [SHARED]
---
--- Sets the player's normal walking speed. Not sprinting, not slow walking `+walk`.
---
--- See also [Player:SetSlowWalkSpeed](https://wiki.facepunch.com/gmod/Player:SetSlowWalkSpeed), [Player:GetWalkSpeed](https://wiki.facepunch.com/gmod/Player:GetWalkSpeed), [Player:SetCrouchedWalkSpeed](https://wiki.facepunch.com/gmod/Player:SetCrouchedWalkSpeed), [Player:SetMaxSpeed](https://wiki.facepunch.com/gmod/Player:SetMaxSpeed) and [Player:SetRunSpeed](https://wiki.facepunch.com/gmod/Player:SetRunSpeed).
---
--- > BUG: Using a speed of `0` can lead to prediction errors, and can cause players to move at sv_maxvelocity
--- > See [issue #2030](https://github.com/Facepunch/garrysmod-issues/issues/2030).
---
--- > NOTE: `player_default` class walk speed is: `200`.
---
---@param walk_speed number The new walk speed when `sv_friction` is below `10`. Higher `sv_friction` values will result in slower speed. Has to be `7` or above or the player **won't** be able to move.
function Player:SetWalkSpeed( walk_speed ) end

--- [SHARED]
---
--- Sets the player weapon's color. The part of the model that is colored is determined by the model itself, and is different for each model.
---
---@param color garrysmod.Vector This is the color to be set. The format is Vector(r,g,b), and each color should be between 0 and 1.
function Player:SetWeaponColor( color ) end

--- [CLIENT]
---
--- Returns whether the **local player's** player model will be drawn at the time the function is called.
---
--- Despite this being a method on a player object, this will always represent the state of the [local player](https://wiki.facepunch.com/gmod/Global.LocalPlayer), not of the player entity this method is used on.
---
---@return boolean should_draw `true` if the player's playermodel is visible
function Player:ShouldDrawLocalPlayer() end

--- [SERVER]
---
--- Sets whether the player's current weapon should drop on death.
---
--- > NOTE: This is reset on spawn to the [player class](https://wiki.facepunch.com/gmod/Player_Classes)'s **DropWeaponOnDie** field by [player_manager.OnPlayerSpawn](https://wiki.facepunch.com/gmod/player_manager.OnPlayerSpawn).
---
---@param drop boolean Whether to drop the player's current weapon or not
function Player:ShouldDropWeapon( drop ) end

--- [CLIENT]
---
--- Opens the player steam profile page in the steam overlay browser.
---
function Player:ShowProfile() end

--- [SERVER]
---
--- Signals the entity that it was dropped by the gravity gun.
---
---@param entity garrysmod.Entity Entity that was dropped.
function Player:SimulateGravGunDrop( entity ) end

--- [SERVER]
---
--- Signals the entity that it was picked up by the gravity gun. This call is only required if you want to simulate the situation of picking up objects.
---
---@param entity garrysmod.Entity The entity picked up
---@param lightning boolean? Whether or not to show lightning effects around the entity Defaults to `false`.
function Player:SimulateGravGunPickup( entity, lightning ) end

--- [SERVER]
---
--- Starts spectate mode for given player. This will also affect the players movetype in some cases.
---
--- [Player:UnSpectate](https://wiki.facepunch.com/gmod/Player:UnSpectate) should be used to remove the player from spectate mode, or call this with `OBS_MODE_NONE`.
---
--- > BUG: The player must be respawned, otherwise they will be able to walk through doors and become invincible. This will be fixed in a future update.
---
---@param mode integer Spectate mode, see [Enums/OBS_MODE](https://wiki.facepunch.com/gmod/Enums/OBS_MODE).
function Player:Spectate( mode ) end

--- [SERVER]
---
--- Makes the player spectate the entity.
---
--- To get the applied spectated entity, use [Player:GetObserverTarget](https://wiki.facepunch.com/gmod/Player:GetObserverTarget).
---
---@param entity garrysmod.Entity Entity to spectate.
function Player:SpectateEntity( entity ) end

--- [SERVER]
---
--- Makes a player spray their decal.
---
---@param spray_origin garrysmod.Vector The location to spray from
---@param spray_end_pos garrysmod.Vector The location to spray to
function Player:SprayDecal( spray_origin, spray_end_pos ) end

--- [SERVER]
---
--- Disables the sprint on the player.
---
function Player:SprintDisable() end

--- [SERVER]
---
--- Enables the sprint on the player.
---
function Player:SprintEnable() end

--- [SHARED]
---
--- Doesn't appear to do anything.
---
---@deprecated This appears to be a direct binding to internal functionality that is overridden by the engine every frame so calling these functions may not have any or expected effect.
function Player:StartSprinting() end

--- [SHARED]
---
--- When used in a [GM:SetupMove](https://wiki.facepunch.com/gmod/GM:SetupMove) hook, this function will force the player to walk, as well as preventing the player from sprinting.
---
---@deprecated This appears to be a direct binding to internal functionality that is overridden by the engine every frame so calling these functions may not have any or expected effect.
function Player:StartWalking() end

--- [SHARED]
---
--- Returns the player's SteamID.
---
--- See [Player:AccountID](https://wiki.facepunch.com/gmod/Player:AccountID) for a shorter version of the SteamID and [Player:SteamID64](https://wiki.facepunch.com/gmod/Player:SteamID64) for the full SteamID.
---
--- It is recommended to use [Player:SteamID64](https://wiki.facepunch.com/gmod/Player:SteamID64) over the other SteamID formats whenever possible.
---
--- > NOTE: In a `-multirun` environment, this will return `STEAM_ID_LAN` for all "copies" of a player because they are not authenticated with Steam.
--- >
--- > For Bots this will return `BOT`.
---
---@return string steam_id "Text" representation of the player's SteamID.
function Player:SteamID() end

--- [SHARED]
---
--- Returns the player's full **64-bit SteamID**, also known as **CommunityID**. Information on how data is packed into this value can be found [here](https://developer.valvesoftware.com/wiki/SteamID).
---
--- See [Player:AccountID](https://wiki.facepunch.com/gmod/Player:AccountID) for a function that returns only the Account ID part of the SteamID and [Player:SteamID](https://wiki.facepunch.com/gmod/Player:SteamID) for the text version of the SteamID.
---
--- > NOTE: In a `-multirun` environment, this will return `"0"` for all "copies" of a player because they are not authenticated with Steam.
--- >
--- > For bots, this will return `90071996842377216` (equivalent to `STEAM_0:0:0`) for the first bot to join.
--- >
--- > For each additional bot, the number increases by 1. So the next bot will be `90071996842377217` (`STEAM_0:1:0`) then `90071996842377218` (`STEAM_0:0:1`) and so on.
---
--- > NOTE: (return value) The return value is a string, not a number, since Lua's numbers are unable to store the entire 64bit numbers without data loss.
---
---@return string steam_id64 Player's 64-bit SteamID aka CommunityID.
function Player:SteamID64() end

--- [SHARED]
---
--- When used in a [GM:SetupMove](https://wiki.facepunch.com/gmod/GM:SetupMove) hook, this function will prevent the player from sprinting.
---
--- When +walk is engaged, the player will still be able to sprint to half speed (normal run speed) as opposed to full sprint speed without this function.
---
---@deprecated This appears to be a direct binding to internal functionality that is overridden by the engine every frame so calling these functions may not have any or expected effect.
function Player:StopSprinting() end

--- [SHARED]
---
--- When used in a [GM:SetupMove](https://wiki.facepunch.com/gmod/GM:SetupMove) hook, this function behaves unexpectedly by preventing the player from sprinting similar to [Player:StopSprinting](https://wiki.facepunch.com/gmod/Player:StopSprinting).
---
---@deprecated This appears to be a direct binding to internal functionality that is overridden by the engine every frame so calling these functions may not have any or expected effect.
function Player:StopWalking() end

--- [SERVER]
---
--- Turns off the zoom mode of the player. (+zoom console command)
---
--- Basically equivalent of entering "-zoom" into player's console.
---
function Player:StopZooming() end

--- [SERVER]
---
--- Removes all ammo from the player.
---
---@deprecated Alias of [Player:RemoveAllAmmo](https://wiki.facepunch.com/gmod/Player:RemoveAllAmmo)
function Player:StripAmmo() end

--- [SERVER]
---
--- Removes the specified weapon class from a certain player
---
--- > NOTE: this function will call the [Entity:OnRemove](https://wiki.facepunch.com/gmod/Entity:OnRemove) but if you try use [Entity:GetOwner](https://wiki.facepunch.com/gmod/Entity:GetOwner) it will return nil
---
---@param class_name string The weapon class to remove
function Player:StripWeapon( class_name ) end

--- [SERVER]
---
--- Removes all weapons from a certain player
---
function Player:StripWeapons() end

--- [SHARED]
---
--- Returns the player's team ID, set by [Player:SetTeam](https://wiki.facepunch.com/gmod/Player:SetTeam)
---
--- Returns 0 clientside when the game is not fully loaded.
---
---@return integer team The player's team's index number, as in the [Enums/TEAM](https://wiki.facepunch.com/gmod/Enums/TEAM) or a custom team defined in [team.SetUp](https://wiki.facepunch.com/gmod/team.SetUp).
function Player:Team() end

--- [SERVER]
---
--- Returns the time in seconds since the player connected.
---
--- Bots will always return value 0.
---
---@return number seconds How long this player was connected to the server for, in seconds.
function Player:TimeConnected() end

--- [SERVER]
---
--- Performs a trace hull and applies damage to the entities hit, returns the first entity hit.
---
--- > WARNING: Hitting the victim entity with this function in [ENTITY:OnTakeDamage](https://wiki.facepunch.com/gmod/ENTITY:OnTakeDamage) can cause infinite loops.
---
---@param start_pos garrysmod.Vector The start position of the hull trace.
---@param end_pos garrysmod.Vector The end position of the hull trace.
---@param mins garrysmod.Vector The minimum coordinates of the hull.
---@param maxs garrysmod.Vector The maximum coordinates of the hull.
---@param damage number The damage to be applied.
---@param damage_flags integer Bitflag specifying the damage type, see [Enums/DMG](https://wiki.facepunch.com/gmod/Enums/DMG).
---@param damage_force number The force to be applied to the hit object.
---@param damage_all_npcs boolean Whether to apply damage to all hit NPCs or not.
---@return garrysmod.Entity entity The hit entity
function Player:TraceHullAttack( start_pos, end_pos, mins, maxs, damage, damage_flags, damage_force, damage_all_npcs ) end

--- [SHARED]
---
--- Translates [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT) according to the holdtype of players currently held weapon.
---
---@param act integer The initial [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT)
---@return integer act Translated [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT)
function Player:TranslateWeaponActivity( act ) end

--- [SHARED]
---
--- Returns a 32 bit integer that remains constant for a player across joins/leaves and across different servers. This can be used when a string is inappropriate - e.g. in a database primary key.
---
--- > NOTE: In Singleplayer, this function will always return 1.
---
--- > BUG: In a `-multirun` environment, the value returned is different on the serverside and clientside.
--- > See [issue #6389](https://github.com/Facepunch/garrysmod-issues/issues/6389).
---
---@deprecated **This function has collisions,** where more than one player can have the same UniqueID. It is **highly** recommended to use [Player:SteamID64](https://wiki.facepunch.com/gmod/Player:SteamID64), [Player:SteamID](https://wiki.facepunch.com/gmod/Player:SteamID) or [Player:AccountID](https://wiki.facepunch.com/gmod/Player:AccountID) instead, which are guaranteed to be unique to each player.
---@return integer unique_id The player's Unique ID
function Player:UniqueID() end

--- [SERVER]
---
--- Unlocks the player movement if locked previously.
---
--- Will disable godmode for the player if locked previously.
---
function Player:UnLock() end

--- [SERVER]
---
--- Removes the player from the spectate mode entirely.
---
--- > BUG: The player must be respawned, otherwise they will be able to walk through doors and become invincible. This will be fixed in a future update.
---
function Player:UnSpectate() end

--- [SHARED]
---
--- Returns the player's user ID. This number will always be unique, but will reset if the player reconnects. (Always increments for each connecting player)
---
--- You can use [Global.Player](https://wiki.facepunch.com/gmod/Global.Player) global function to get a player by their user ID.
---
---@return integer user_id The player's user ID
function Player:UserID() end

--- [SHARED]
---
--- Simulates a push on the client's screen. This **adds** view punch velocity, and does not reset the current view punch angle, for which you can use [Player:SetViewPunchAngles](https://wiki.facepunch.com/gmod/Player:SetViewPunchAngles).
---
--- > NOTE: Despite being defined shared, it only functions when called server-side.
---
---@param punch_angle garrysmod.Angle The angle in which to push the player's screen.
function Player:ViewPunch( punch_angle ) end

--- [SHARED]
---
--- Resets the player's view punch (and the view punch velocity, read more at [Player:ViewPunch](https://wiki.facepunch.com/gmod/Player:ViewPunch)) effect back to normal.
---
---@param tolerance number? Reset all ViewPunch below this threshold. Defaults to `0`.
function Player:ViewPunchReset( tolerance ) end

--- [CLIENT]
---
--- Returns the players voice volume, how loud the player's voice communication currently is, as a number in range of [0,1].
---
---@return number volume The voice volume.
function Player:VoiceVolume() end

--- [SHARED]
---
--- The player library.
---
---@class garrysmod.player
player = {}

--- [SHARED]
---
--- Returns every player that is not a bot.
---
---@return garrysmod.Player[] players The human players.
function player.GetHumans() end
