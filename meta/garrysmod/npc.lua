---@meta garrysmod.npc


--- [SHARED]
---
--- This is a list of all methods only available for NPCs. It is also possible to call [Entity](https://wiki.facepunch.com/gmod/Entity) functions on NPCs.
---
---@class garrysmod.NPC : garrysmod.Entity
local NPC = {}

--- [SERVER]
---
--- Makes the NPC like, hate, feel neutral towards, or fear the entity in question. If you want to setup relationship towards a certain entity `class`, use [NPC:AddRelationship](https://wiki.facepunch.com/gmod/NPC:AddRelationship).
---
--- > NOTE: NPCs do not see [NextBot](https://wiki.facepunch.com/gmod/NextBot)s by default. This can be fixed by adding the [FL_OBJECT](https://wiki.facepunch.com/gmod/Enums/FL) flag to the NextBot.
---
---@param target garrysmod.Entity The entity for the relationship to be applied to.
---@param disposition integer A [Enums/D](https://wiki.facepunch.com/gmod/Enums/D) representing the relationship type.
---@param priority number? How strong the relationship is. Higher values mean higher priority over relationships with lower priority. Defaults to `0`.
function NPC:AddEntityRelationship( target, disposition, priority ) end

--- [SERVER]
---
--- Changes how an NPC feels towards another NPC.  If you want to setup relationship towards a certain `entity`, use [NPC:AddEntityRelationship](https://wiki.facepunch.com/gmod/NPC:AddEntityRelationship).
---
--- > WARNING: Avoid using this in [GM:OnEntityCreated](https://wiki.facepunch.com/gmod/GM:OnEntityCreated) to prevent crashing due to infinite loops. This function may create an entity with given class and delete it immediately after.
---
---@param relationstring string A string representing how the relationship should be set up. Should be formatted as `"npc_class `[Enums/D](https://wiki.facepunch.com/gmod/Enums/D)` numberPriority"`.
function NPC:AddRelationship( relationstring ) end

--- [SERVER]
---
--- Advances the NPC on its path to the next waypoint.
---
--- > WARNING: Calling this on an NPC without any route will result in an instant crash.
---
function NPC:AdvancePath() end

--- [SERVER]
---
--- Force an NPC to play their Alert sound.
---
function NPC:AlertSound() end

--- [SERVER]
---
--- Executes any movement the current sequence may have.
---
---@param interval number This is a good place to use [Entity:GetAnimTimeInterval](https://wiki.facepunch.com/gmod/Entity:GetAnimTimeInterval).
---@param target garrysmod.Entity?  Defaults to `NULL`.
---@return boolean moved `true` if any movement was performed.
function NPC:AutoMovement( interval, target ) end

--- [SERVER]
---
--- Become a ragdoll and remove the entity. Internally handles serverside/clientside ragdoll creation, momentum calculation, triggering ragdoll creation hooks / events and cloning entity's bone transforms to the created ragdoll.
---
---@param info garrysmod.DamageInfo Damage info passed from an onkilled event
---@return garrysmod.Entity | nil ragdoll The created serverside ragdoll, nil if failed or a clientside ragdoll created.
function NPC:BecomeRagdoll( info ) end

--- [SERVER]
---
--- Adds a capability to the NPC.
---
---@param capabilities integer Capabilities to add, see [Enums/CAP](https://wiki.facepunch.com/gmod/Enums/CAP).
function NPC:CapabilitiesAdd( capabilities ) end

--- [SERVER]
---
--- Removes all of Capabilities the NPC has.
---
function NPC:CapabilitiesClear() end

--- [SERVER]
---
--- Returns the NPC's capabilities along the ones defined on its weapon.
---
---@return integer capabilities The capabilities as a bitflag. See [Enums/CAP](https://wiki.facepunch.com/gmod/Enums/CAP)
function NPC:CapabilitiesGet() end

--- [SERVER]
---
--- Checks whether the NPC has the specified capabilities.
---
---@param capabilities integer Capabilities to check, see [Enums/CAP](https://wiki.facepunch.com/gmod/Enums/CAP).
function NPC:CapabilitiesHas( capabilities ) end

--- [SERVER]
---
--- Remove a certain capability.
---
---@param capabilities integer Capabilities to remove, see [Enums/CAP](https://wiki.facepunch.com/gmod/Enums/CAP)
function NPC:CapabilitiesRemove( capabilities ) end

--- [SERVER]
---
--- Returns the NPC relationship class. This is mostly used to tell NPCs who should be attacking who.
---
--- Do not confuse with [Entity:GetClass](https://wiki.facepunch.com/gmod/Entity:GetClass)!
---
---@return integer class The NPC class. See [Enums/CLASS](https://wiki.facepunch.com/gmod/Enums/CLASS).
function NPC:Classify() end

--- [SERVER]
---
--- Resets the [NPC:GetBlockingEntity](https://wiki.facepunch.com/gmod/NPC:GetBlockingEntity).
---
function NPC:ClearBlockingEntity() end

--- [SERVER]
---
--- Clears out the specified [Enums/COND](https://wiki.facepunch.com/gmod/Enums/COND) on this NPC.
---
---@param condition integer The [Enums/COND](https://wiki.facepunch.com/gmod/Enums/COND) to clear out.
function NPC:ClearCondition( condition ) end

--- [SERVER]
---
--- Clears the Enemy from the NPC's memory, effectively forgetting it until met again with either the NPC vision or with [NPC:UpdateEnemyMemory](https://wiki.facepunch.com/gmod/NPC:UpdateEnemyMemory).
---
---@param enemy garrysmod.Entity? The enemy to mark Defaults to `GetEnemy()`.
function NPC:ClearEnemyMemory( enemy ) end

--- [SERVER]
---
--- Clears the NPC's current expression which can be set with [NPC:SetExpression](https://wiki.facepunch.com/gmod/NPC:SetExpression).
---
function NPC:ClearExpression() end

--- [SERVER]
---
--- Clears the current NPC goal or target.
---
function NPC:ClearGoal() end

--- [SERVER]
---
--- Stops the current schedule that the NPC is doing.
---
function NPC:ClearSchedule() end

--- [SERVER]
---
--- Returns the ID of a given condition by name. Opposite of [NPC:ConditionName](https://wiki.facepunch.com/gmod/NPC:ConditionName).
---
--- This is useful for custom conditions defined by engine NPCs, such as `COND_ZOMBIE_RELEASECRAB` for zombies, and `COND_COMBINE_ON_FIRE` for Combine Soldiers.
---
---@param condition_name string The condition name.
---@return integer condition_id The condition ID, see [Enums/COND](https://wiki.facepunch.com/gmod/Enums/COND). Custom conditions will have a "randomly" assigned IDs, which will change with each game session.
function NPC:ConditionID( condition_name ) end

--- [SERVER]
---
--- Translates condition ID to a string. For the opposite process, see [NPC:ConditionID](https://wiki.facepunch.com/gmod/NPC:ConditionID).
---
---@param condition integer The NPCs condition ID, see [Enums/COND](https://wiki.facepunch.com/gmod/Enums/COND)
---@return string condition_name A human understandable string equivalent of that condition.
function NPC:ConditionName( condition ) end

--- [SERVER]
---
--- Returns the way the NPC "feels" about a given entity. See [NPC:AddEntityRelationship](https://wiki.facepunch.com/gmod/NPC:AddEntityRelationship).
---
--- > NOTE: For `ai` type entities, this will return [ENTITY:GetRelationship](https://wiki.facepunch.com/gmod/ENTITY:GetRelationship). If it returns `nil` or for engine NPCs, this will return whatever was last set by [NPC:AddEntityRelationship](https://wiki.facepunch.com/gmod/NPC:AddEntityRelationship). As a last resort, engine will decide on the disposition based on this NPC's [NPC:Classify](https://wiki.facepunch.com/gmod/NPC:Classify).
---
---@param entity garrysmod.Entity The entity to test our disposition towards.
---@return integer disposition The NPCs disposition, see [Enums/D](https://wiki.facepunch.com/gmod/Enums/D).
---@return number priority The NPCs disposition priority.
function NPC:Disposition( entity ) end

--- [SERVER]
---
--- Forces the NPC to drop the specified weapon.
---
---@param weapon garrysmod.Weapon? Weapon to be dropped. If unset, will default to the currently equipped weapon.
---@param target garrysmod.Vector? If set, launches the weapon at given position. There is a limit to how far it is willing to throw the weapon. Overrides velocity argument.
---@param velocity garrysmod.Vector? If set and previous argument is unset, launches the weapon with given velocity. If the velocity is higher than 400, it will be clamped to 400.
function NPC:DropWeapon( weapon, target, velocity ) end

--- [SERVER]
---
--- Makes an NPC exit a scripted sequence, if one is playing.
---
function NPC:ExitScriptedSequence() end

--- [SERVER]
---
--- Force an NPC to play its Fear sound.
---
function NPC:FearSound() end

--- [SERVER]
---
--- Force an NPC to play its FoundEnemy sound.
---
function NPC:FoundEnemySound() end

--- [SHARED]
---
--- Returns the weapon the NPC is currently carrying, or [NULL](https://wiki.facepunch.com/gmod/Global_Variables).
---
---@return garrysmod.Entity weapon The NPCs current weapon
function NPC:GetActiveWeapon() end

--- [SERVER]
---
--- Returns the NPC's current activity.
---
---@return integer activity Current activity, see [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
function NPC:GetActivity() end

--- [SERVER]
---
--- Returns the aim vector of the NPC. NPC alternative of [Player:GetAimVector](https://wiki.facepunch.com/gmod/Player:GetAimVector).
---
--- > NOTE: If the NPC has both [NPC:GetEnemy](https://wiki.facepunch.com/gmod/NPC:GetEnemy) and [NPC:GetActiveWeapon](https://wiki.facepunch.com/gmod/NPC:GetActiveWeapon), engine will automatically call [ENTITY:GetAttackSpread](https://wiki.facepunch.com/gmod/ENTITY:GetAttackSpread) to add random spread degrees to the return value.
---
---@return garrysmod.Vector aim_vector The aim direction of the NPC, usually a noisy direction to it's [NPC:GetEnemy](https://wiki.facepunch.com/gmod/NPC:GetEnemy). This will default to [Entity:GetForward](https://wiki.facepunch.com/gmod/Entity:GetForward) when there's no enemy. Thus, [NPC:GetCurrentWeaponProficiency](https://wiki.facepunch.com/gmod/NPC:GetCurrentWeaponProficiency) will be used.
function NPC:GetAimVector() end

--- [SERVER]
---
--- Returns the activity to be played when the NPC arrives at its goal
---
---@return integer arrival_activity The arrival activity. See [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
function NPC:GetArrivalActivity() end

--- [SERVER]
---
--- Returns the direction from the NPC origin to its current navigational destination.
---
---@return garrysmod.Vector arrival_direction The arrival direction.
function NPC:GetArrivalDirection() end

--- [SERVER]
---
--- Returns NPC arrival distance, set by [NPC:SetArrivalDistance](https://wiki.facepunch.com/gmod/NPC:SetArrivalDistance).
---
---@return number distance The current arrival distance.
function NPC:GetArrivalDistance() end

--- [SERVER]
---
--- Returns the sequence to be played when the NPC arrives at its goal.
---
---@return integer arrival_sequence Sequence ID to be played, or -1 if there's no sequence.
function NPC:GetArrivalSequence() end

--- [SERVER]
---
--- Returns NPC arrival speed, set by [NPC:SetArrivalSpeed](https://wiki.facepunch.com/gmod/NPC:SetArrivalSpeed).
---
---@return number speed The current arrival peed.
function NPC:GetArrivalSpeed() end

--- [SERVER]
---
--- Returns the most dangerous/closest sound hint based on the NPCs location and the types of sounds it can sense.
---
---@param types integer The types of sounds to choose from. See [SOUND_ enums](https://wiki.facepunch.com/gmod/Enums/SOUND)
---@return table | nil hint A table with [SoundHintData](https://wiki.facepunch.com/gmod/Structures/SoundHintData) structure or `nil` if no sound hints are nearby.
function NPC:GetBestSoundHint( types ) end

--- [SERVER]
---
--- Returns the entity blocking the NPC along its path.
---
---@return garrysmod.Entity blocking_entity Blocking entity
function NPC:GetBlockingEntity() end

--- [SERVER]
---
--- Returns the goal type for current navigation path.
---
---@return integer goal_type The goal type. See [Enums/GOALTYPE](https://wiki.facepunch.com/gmod/Enums/GOALTYPE).
function NPC:GetCurGoalType() end

--- [SERVER]
---
--- Returns the NPC's current schedule.
---
---@return integer schedule The NPCs schedule, see [Enums/SCHED](https://wiki.facepunch.com/gmod/Enums/SCHED) or -1 if we failed for some reason
function NPC:GetCurrentSchedule() end

--- [SERVER]
---
--- Returns how proficient (skilled) an NPC is with its current weapon.
---
---@return integer proficiency NPC's proficiency for current weapon. See [Enums/WEAPON_PROFICIENCY](https://wiki.facepunch.com/gmod/Enums/WEAPON_PROFICIENCY).
function NPC:GetCurrentWeaponProficiency() end

--- [SERVER]
---
--- Gets the NPC's current waypoint position (where NPC is currently moving towards), if any is available.
---
---@return garrysmod.Vector position The position of the current NPC waypoint.
function NPC:GetCurWaypointPos() end

--- [SERVER]
---
--- Returns the entity that this NPC is trying to fight.
---
--- > BUG: This returns nil if the NPC has no enemy. You should use [Global.IsValid](https://wiki.facepunch.com/gmod/Global.IsValid) (which accounts for nil and NULL) on the return to verify validity of the enemy.
--- > See [issue #3132](https://github.com/Facepunch/garrysmod-issues/issues/3132).
---
---@return garrysmod.NPC enemy The enemy NPC.
function NPC:GetEnemy() end

--- [SERVER]
---
--- Returns the first time an NPC's enemy was seen by the NPC.
---
---@param enemy garrysmod.Entity? The enemy to check. Defaults to `GetEnemy()`.
---@return number time First time the given enemy was seen.
function NPC:GetEnemyFirstTimeSeen( enemy ) end

--- [SERVER]
---
--- Returns the last known position of an NPC's enemy.
---
--- Similar to [NPC:GetEnemyLastSeenPos](https://wiki.facepunch.com/gmod/NPC:GetEnemyLastSeenPos), but the known position will be a few seconds ahead of the last seen position.
---
---@param enemy garrysmod.Entity? The enemy to check. Defaults to `GetEnemy()`.
---@return garrysmod.Vector position The last known position.
function NPC:GetEnemyLastKnownPos( enemy ) end

--- [SERVER]
---
--- Returns the last seen position of an NPC's enemy.
---
--- Similar to [NPC:GetEnemyLastKnownPos](https://wiki.facepunch.com/gmod/NPC:GetEnemyLastKnownPos), but the known position will be a few seconds ahead of the last seen position.
---
---@param enemy garrysmod.Entity? The enemy to check. Defaults to `GetEnemy()`.
---@return garrysmod.Vector position The last seen position.
function NPC:GetEnemyLastSeenPos( enemy ) end

--- [SERVER]
---
--- Returns the last time an NPC's enemy was seen by the NPC.
---
---@param enemy garrysmod.Entity? The enemy to check. Defaults to `GetEnemy()`.
---@return number time Last time the given enemy was seen.
function NPC:GetEnemyLastTimeSeen( enemy ) end

--- [SERVER]
---
--- Returns the expression file the NPC is currently playing.
---
---@return string file_path The file path of the expression.
function NPC:GetExpression() end

--- [SERVER]
---
--- Returns the eye direction of the NPC.
---
---@return garrysmod.Vector eye_direction The eye direction.
function NPC:GetEyeDirection() end

--- [SERVER]
---
--- Returns the Field Of View of the NPC. See [NPC:SetFOV](https://wiki.facepunch.com/gmod/NPC:SetFOV).
---
---@return number fov The FOV for the NPC in degrees.
function NPC:GetFOV() end

--- [SERVER]
---
--- Returns the position we are trying to reach, if any.
---
---@return garrysmod.Vector position The position we are trying to reach.
function NPC:GetGoalPos() end

--- [SERVER]
---
--- Returns the entity we are trying to reach, if any.
---
---@return garrysmod.Entity target The entity we are trying to reach, or `NULL`.
function NPC:GetGoalTarget() end

--- [SERVER]
---
--- Returns the 2D head direction of the NPC.
---
---@return garrysmod.Vector head_direction The head direction.
function NPC:GetHeadDirection() end

--- [SERVER]
---
--- Returns NPCs hull type set by [NPC:SetHullType](https://wiki.facepunch.com/gmod/NPC:SetHullType).
---
---@return integer hull_type Hull type, see [Enums/HULL](https://wiki.facepunch.com/gmod/Enums/HULL)
function NPC:GetHullType() end

--- [SERVER]
---
--- Returns the ideal activity the NPC currently wants to achieve.
---
--- > NOTE: By default, base NPCs will automatically attempt to play a sequence bound to the ideal activity. To prevent ideal activity from overriding NPC's active sequence, set this to `ACT_DO_NOT_DISTURB`.
---
---@return integer ideal_activity The ideal activity. [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
function NPC:GetIdealActivity() end

--- [SERVER]
---
--- Returns the ideal move acceleration of the NPC.
---
---@return number acceleration The ideal move acceleration.
function NPC:GetIdealMoveAcceleration() end

--- [SERVER]
---
--- Returns the ideal move speed of the NPC.
---
---@return number speed The ideal move speed.
function NPC:GetIdealMoveSpeed() end

--- [SERVER]
---
--- Returns the ideal sequence the NPC currently wants to achieve.
---
---@return integer ideal_sequence The ideal sequence, specific to the NPCs model.
function NPC:GetIdealSequence() end

--- [SERVER]
---
--- Returns the ideal yaw (left right rotation) for this NPC at this moment.
---
---@return number yaw The ideal yaw.
function NPC:GetIdealYaw() end

--- [SERVER]
---
--- Returns all known enemies this NPC has. The enemy table is updated with [NPC:UpdateEnemyMemory](https://wiki.facepunch.com/gmod/NPC:UpdateEnemyMemory) and [NPC:ClearEnemyMemory](https://wiki.facepunch.com/gmod/NPC:ClearEnemyMemory), meaning other entities may be in enemies list even though your NPC doesn't hate it.
---
--- See also [NPC:GetKnownEnemyCount](https://wiki.facepunch.com/gmod/NPC:GetKnownEnemyCount)
---
---@return garrysmod.Entity[] enemies Table of entities that this NPC knows as enemies.
function NPC:GetKnownEnemies() end

--- [SERVER]
---
--- Returns known enemy count of this NPC.
---
--- See also [NPC:GetKnownEnemies](https://wiki.facepunch.com/gmod/NPC:GetKnownEnemies)
---
---@return integer count Amount of entities that this NPC knows as enemies.
function NPC:GetKnownEnemyCount() end

--- [SERVER]
---
--- Returns the last registered or memorized position of the NPC. When using scheduling, the NPC will focus on navigating to the last position via nodes.
---
--- See [NPC:SetLastPosition](https://wiki.facepunch.com/gmod/NPC:SetLastPosition).
---
---@return garrysmod.Vector position Where the NPC's last position was set to.
function NPC:GetLastPosition() end

--- [SERVER]
---
--- Returns [Global.CurTime](https://wiki.facepunch.com/gmod/Global.CurTime) based time since this NPC last received damage from given enemy. The last damage time is set when [NPC:MarkTookDamageFromEnemy](https://wiki.facepunch.com/gmod/NPC:MarkTookDamageFromEnemy) is called.
---
---@param enemy garrysmod.Entity? The enemy to test. Defaults to currently active enemy ([NPC:GetEnemy](https://wiki.facepunch.com/gmod/NPC:GetEnemy))
---@return number time Time since this NPC last received damage from given enemy.
function NPC:GetLastTimeTookDamageFromEnemy( enemy ) end

--- [SERVER]
---
--- Returns NPCs max view distance. An NPC will not be able to see enemies outside of this distance.
---
---@return number distance The maximum distance the NPC can see at.
function NPC:GetMaxLookDistance() end

--- [SERVER]
---
--- Returns how far should the NPC look ahead in its route.
---
---@return number distance How far the NPC checks ahead of its route.
function NPC:GetMinMoveCheckDist() end

--- [SERVER]
---
--- Returns how far before the NPC can come to a complete stop.
---
---@param min_result number? The minimum value that will be returned by this function. Defaults to `10`.
---@return number distance The minimum stop distance.
function NPC:GetMinMoveStopDist( min_result ) end

--- [SERVER]
---
--- Returns the movement delay for given NPC.
---
--- See [NPC:SetMoveDelay](https://wiki.facepunch.com/gmod/NPC:SetMoveDelay).
---
---@return number delay The movement delay.
function NPC:GetMoveDelay() end

--- [SERVER]
---
--- Returns the current timestep the internal NPC motor is working on.
---
---@return number interval The current timestep.
function NPC:GetMoveInterval() end

--- [SERVER]
---
--- Returns the NPC's current movement activity.
---
---@return integer activity Current NPC movement activity, see [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
function NPC:GetMovementActivity() end

--- [SERVER]
---
--- Returns the index of the sequence the NPC uses to move.
---
---@return integer sequence_id The movement sequence index
function NPC:GetMovementSequence() end

--- [SERVER]
---
--- Returns the current move velocity of the NPC.
---
---@return garrysmod.Vector velocity The current move velocity of the NPC.
function NPC:GetMoveVelocity() end

--- [SERVER]
---
--- Returns the NPC's navigation type.
---
---@return integer nav_type The nav type. See [Enums/NAV](https://wiki.facepunch.com/gmod/Enums/NAV).
function NPC:GetNavType() end

--- [SERVER]
---
--- Returns the nearest member of the squad the NPC is in.
---
---@return garrysmod.NPC member The nearest member of the squad the NPC is in.
function NPC:GetNearestSquadMember() end

--- [SERVER]
---
--- Gets the NPC's next waypoint position, where NPC will be moving after reaching current waypoint, if any is available.
---
---@return garrysmod.Vector position The position of the next NPC waypoint.
function NPC:GetNextWaypointPos() end

--- [SERVER]
---
--- Returns the NPC's state.
---
---@return integer state The NPC's current state, see [Enums/NPC_STATE](https://wiki.facepunch.com/gmod/Enums/NPC_STATE).
function NPC:GetNPCState() end

--- [SERVER]
---
--- Returns the distance the NPC is from Target Goal.
---
---@return number distance The number of hammer units the NPC is away from the Goal.
function NPC:GetPathDistanceToGoal() end

--- [SERVER]
---
--- Returns the amount of time it will take for the NPC to get to its Target Goal.
---
---@return number time The amount of time to get to the target goal.
function NPC:GetPathTimeToGoal() end

--- [SERVER]
---
--- Returns the shooting position of the NPC, i.e. where their bullets would come from, etc.
---
--- If the NPC does not overwrite this, it will return [Entity:GetPos](https://wiki.facepunch.com/gmod/Entity:GetPos).
---
---@return garrysmod.Vector position The NPC's shooting position.
function NPC:GetShootPos() end

--- [SERVER]
---
--- Returns the current squad name of the NPC, as set via [NPC:SetSquad](https://wiki.facepunch.com/gmod/NPC:SetSquad).
---
---@return string | nil name The squad name, or `nil` if the NPC is not in a squad.
function NPC:GetSquad() end

--- [SERVER]
---
--- Returns NPC step height.
---
---@return number height The current step height.
function NPC:GetStepHeight() end

--- [SERVER]
---
--- Returns the NPC's current target set by [NPC:SetTarget](https://wiki.facepunch.com/gmod/NPC:SetTarget).
---
--- > BUG: This returns nil if the NPC has no target. You should use [Global.IsValid](https://wiki.facepunch.com/gmod/Global.IsValid) (which accounts for nil and NULL) on the return to verify validity of the target.
--- > See [issue #3132](https://github.com/Facepunch/garrysmod-issues/issues/3132).
---
---@return garrysmod.Entity target Target entity
function NPC:GetTarget() end

--- [SERVER]
---
--- Returns the status of the current task.
---
---@return integer status The status. See [Enums/TASKSTATUS](https://wiki.facepunch.com/gmod/Enums/TASKSTATUS).
function NPC:GetTaskStatus() end

--- [SERVER]
---
--- Returns [Global.CurTime](https://wiki.facepunch.com/gmod/Global.CurTime) based time since the enemy was reacquired, meaning it is currently in Line of Sight of the NPC.
---
---@param enemy garrysmod.Entity? The enemy to test. Defaults to currently active enemy ([NPC:GetEnemy](https://wiki.facepunch.com/gmod/NPC:GetEnemy))
---@return number time Time enemy was last reacquired.
function NPC:GetTimeEnemyLastReacquired( enemy ) end

--- [SERVER]
---
--- Returns the view offset of the NPC. Set by [NPC:SetViewOffset](https://wiki.facepunch.com/gmod/NPC:SetViewOffset).
---
---@return garrysmod.Vector view_offset The view offset of the NPC.
function NPC:GetViewOffset() end

--- [SERVER]
---
--- Returns a specific weapon the NPC owns.
---
---@param class_name string A classname of the weapon to try to get.
---@return garrysmod.Weapon weapon The weapon for the specified class, or NULL of the NPC doesn't have given weapon.
function NPC:GetWeapon( class_name ) end

--- [SERVER]
---
--- Returns a table of the NPC's weapons.
---
---@return garrysmod.Weapon[] weapons A list of the weapons the NPC currently has.
function NPC:GetWeapons() end

--- [SERVER]
---
--- Used to give a weapon to an already spawned NPC.
---
---@param weapon string Class name of the weapon to equip to the NPC.
---@return garrysmod.Weapon weapon The weapon entity given to the NPC.
function NPC:Give( weapon ) end

--- [SERVER]
---
--- Returns whether or not the NPC has the given condition.
---
---@param condition integer The condition index, see [Enums/COND](https://wiki.facepunch.com/gmod/Enums/COND).
---@return boolean has_condition True if the NPC has the given condition, false otherwise.
function NPC:HasCondition( condition ) end

--- [SERVER]
---
--- Polls the enemy memory to check if the given entity has eluded us or not.
---
---@param enemy garrysmod.Entity? The enemy to test. Defaults to `GetEnemy()`.
---@return boolean eluded If the enemy has eluded us.
function NPC:HasEnemyEluded( enemy ) end

--- [SERVER]
---
--- Polls the enemy memory to check if the NPC has any memory of given enemy.
---
---@param enemy garrysmod.Entity? The entity to test. Defaults to `GetEnemy()`.
---@return boolean has_memory If we have any memory on given enemy.
function NPC:HasEnemyMemory( enemy ) end

--- [SERVER]
---
--- Returns true if the current navigation has an obstacle, this is different from [NPC:GetBlockingEntity](https://wiki.facepunch.com/gmod/NPC:GetBlockingEntity), this is for virtual navigation obstacles put by AI's local navigation system to prevent movement to the marked area, forcing NPC to steer around, [for example](https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/server/hl2/npc_playercompanion.cpp#L2897).
---
---@return boolean has_obstacles `true` if the current navigation has an obstacle.
function NPC:HasObstacles() end

--- [SERVER]
---
--- Force an NPC to play their Idle sound.
---
function NPC:IdleSound() end

--- [SERVER]
---
--- Makes the NPC ignore given entity/enemy until given time.
---
---@param enemy garrysmod.Entity The enemy to ignore.
---@param until_time number How long to ignore the enemy for. This will be compared to [Global.CurTime](https://wiki.facepunch.com/gmod/Global.CurTime), so your value should be based on it.
function NPC:IgnoreEnemyUntil( enemy, until_time ) end

--- [SERVER]
---
--- Returns whether the NPC is currently crouching or not. Citizens and Combine Soldiers are capable of this behavior by default.
---
---@return boolean is_crouching Whether the NPC is currently crouching.
function NPC:IsCrouching() end

--- [SERVER]
---
--- Returns whether or not the NPC is performing the given schedule.
---
---@param schedule integer The schedule number, see [Enums/SCHED](https://wiki.facepunch.com/gmod/Enums/SCHED).
---@return boolean is_current True if the NPC is performing the given schedule, false otherwise.
function NPC:IsCurrentSchedule( schedule ) end

--- [SERVER]
---
--- Returns whether the current navigational waypoint is the final one.
---
---@return boolean is_goal Whether the current navigational waypoint is the final one.
function NPC:IsCurWaypointGoal() end

--- [SERVER]
---
--- Returns whether the NPC is facing their ideal yaw. See [NPC:SetIdealYaw](https://wiki.facepunch.com/gmod/NPC:SetIdealYaw), [NPC:GetIdealYaw](https://wiki.facepunch.com/gmod/NPC:GetIdealYaw) and [NPC:SetIdealYawAndUpdate](https://wiki.facepunch.com/gmod/NPC:SetIdealYawAndUpdate).
---
---@return boolean is_facing Whether the NPC is facing their ideal yaw.
function NPC:IsFacingIdealYaw() end

--- [SERVER]
---
--- Returns whether the NPC has an active goal.
---
---@return boolean is_active Whether the NPC has an active goal or not.
function NPC:IsGoalActive() end

--- [SERVER]
---
--- Tests whether a position or an NPC is in the view cone of the NPC.
---
---@param position garrysmod.Vector The position to test.
---@return boolean in_view_cone If the given position is in the view cone.
function NPC:IsInViewCone( position ) end

--- [SERVER]
---
--- Returns if the current movement is locked on the Yaw axis.
---
---@return boolean is_locked Whether the movement is yaw locked or not.
function NPC:IsMoveYawLocked() end

--- [SERVER]
---
--- Returns whether the NPC is moving or not.
---
---@return boolean is_moving Whether the NPC is moving or not.
function NPC:IsMoving() end

--- [SERVER]
---
--- Checks if the NPC is running an **ai_goal**. ( e.g. An npc_citizen NPC following the Player. )
---
---@return boolean is_running Returns true if running an ai_goal, otherwise returns false.
function NPC:IsRunningBehavior() end

--- [SERVER]
---
--- Returns whether the current NPC is the leader of the squad it is in.
---
---@return boolean is_leader Whether the NPC is the leader of the squad or not.
function NPC:IsSquadLeader() end

--- [SERVER]
---
--- Returns the "forgettable" status for a given enemy, as set by [NPC:SetUnforgettable](https://wiki.facepunch.com/gmod/NPC:SetUnforgettable), or by internal logic of engine NPCs.
---
---@param enemy garrysmod.Entity Enemy entity to check.
---@return boolean is_unforgettable Whether the given enemy is unforgettable (`true`) or not.
function NPC:IsUnforgettable( enemy ) end

--- [SERVER]
---
--- Returns true if the entity was remembered as unreachable. The memory is updated automatically from following engine tasks if they failed:
--- * TASK_GET_CHASE_PATH_TO_ENEMY
--- * TASK_GET_PATH_TO_ENEMY_LKP
--- * TASK_GET_PATH_TO_INTERACTION_PARTNER
--- * TASK_ANTLIONGUARD_GET_CHASE_PATH_ENEMY_TOLERANCE
--- * SCHED_FAIL_ESTABLISH_LINE_OF_FIRE - Combine NPCs, also when failing to change their enemy
---
---@param test_entity garrysmod.Entity The entity to test.
---@return boolean is_unreachable `true` if the entity is unreachable.
function NPC:IsUnreachable( test_entity ) end

--- [SERVER]
---
--- Force an NPC to play their LostEnemy sound.
---
function NPC:LostEnemySound() end

--- [SERVER]
---
--- Tries to achieve our ideal animation state, playing any transition sequences that we need to play to get there.
---
function NPC:MaintainActivity() end

--- [SERVER]
---
--- Causes the NPC to temporarily forget the current enemy and switch on to a better one.
---
---@param enemy garrysmod.Entity? The enemy to mark Defaults to `GetEnemy()`.
function NPC:MarkEnemyAsEluded( enemy ) end

--- [SERVER]
---
--- Marks the NPC as took damage from given entity.
---
--- See also [NPC:GetLastTimeTookDamageFromEnemy](https://wiki.facepunch.com/gmod/NPC:GetLastTimeTookDamageFromEnemy).
---
---@param enemy garrysmod.Entity? The enemy to mark. Defaults to currently active enemy ([NPC:GetEnemy](https://wiki.facepunch.com/gmod/NPC:GetEnemy))
function NPC:MarkTookDamageFromEnemy( enemy ) end

--- [SERVER]
---
--- Executes a climb move.
---
--- Related functions are [NPC:MoveClimbStart](https://wiki.facepunch.com/gmod/NPC:MoveClimbStart) and [NPC:MoveClimbStop](https://wiki.facepunch.com/gmod/NPC:MoveClimbStop).
---
---@param destination garrysmod.Vector The destination of the climb.
---@param direction garrysmod.Vector The direction of the climb.
---@param distance number The distance.
---@param yaw number The yaw angle.
---@param nodes_left integer Amount of climb nodes left?
---@return integer result The result. See [Enums/AIMR](https://wiki.facepunch.com/gmod/Enums/AIMR).
function NPC:MoveClimbExec( destination, direction, distance, yaw, nodes_left ) end

--- [SERVER]
---
--- Starts a climb move.
---
--- Related functions are [NPC:MoveClimbExec](https://wiki.facepunch.com/gmod/NPC:MoveClimbExec) and [NPC:MoveClimbStop](https://wiki.facepunch.com/gmod/NPC:MoveClimbStop).
---
---@param destination garrysmod.Vector The destination of the climb.
---@param direction garrysmod.Vector The direction of the climb.
---@param distance number The distance.
---@param yaw number The yaw angle.
function NPC:MoveClimbStart( destination, direction, distance, yaw ) end

--- [SERVER]
---
--- Stops a climb move.
---
--- Related functions are [NPC:MoveClimbExec](https://wiki.facepunch.com/gmod/NPC:MoveClimbExec) and [NPC:MoveClimbStart](https://wiki.facepunch.com/gmod/NPC:MoveClimbStart).
---
function NPC:MoveClimbStop() end

--- [SERVER]
---
--- Similar to other `NPC:Move*` functions, invokes internal code to move the NPC to a given location.
---
--- Meant to be used within [ENTITY:OverrideMove](https://wiki.facepunch.com/gmod/ENTITY:OverrideMove).
---
---@param position garrysmod.Vector The position we want to reach.
---@param target_entity garrysmod.Entity? Used to test whether we hit the move target when deciding success.
---@param yaw number? Target Yaw angle at the end of the move. -1 to keep original yaw. Defaults to `-1`.
---@param as_far_as_can boolean? Whether to move as far as possible. Defaults to `true`.
---@param test_z boolean? Also test the Z axis of the target position and NPC position to decide success. Defaults to `true`.
---@return integer result Whether the movement succeeded or not. `AIMotorMoveResult_t` enum: * AIM_FAILED = 0 * AIM_SUCCESS = 1 * AIM_PARTIAL_HIT_NPC = 2 * AIM_PARTIAL_HIT_WORLD = 3 * AIM_PARTIAL_HIT_TARGET = 4
function NPC:MoveGroundStep( position, target_entity, yaw, as_far_as_can, test_z ) end

--- [SERVER]
---
--- Executes a jump move.
---
--- Related functions are [NPC:MoveJumpStart](https://wiki.facepunch.com/gmod/NPC:MoveJumpStart) and [NPC:MoveJumpStop](https://wiki.facepunch.com/gmod/NPC:MoveJumpStop).
---
---@return integer result The result. See [Enums/AIMR](https://wiki.facepunch.com/gmod/Enums/AIMR).
function NPC:MoveJumpExec() end

--- [SERVER]
---
--- Starts a jump move.
---
--- Related functions are [NPC:MoveJumpExec](https://wiki.facepunch.com/gmod/NPC:MoveJumpExec) and [NPC:MoveJumpStop](https://wiki.facepunch.com/gmod/NPC:MoveJumpStop).
---
---@param velocity garrysmod.Vector The jump velocity.
function NPC:MoveJumpStart( velocity ) end

--- [SERVER]
---
--- Stops a jump move.
---
--- Related functions are [NPC:MoveJumpExec](https://wiki.facepunch.com/gmod/NPC:MoveJumpExec) and [NPC:MoveJumpStart](https://wiki.facepunch.com/gmod/NPC:MoveJumpStart).
---
---@return integer result The result. See [Enums/AIMR](https://wiki.facepunch.com/gmod/Enums/AIMR).
function NPC:MoveJumpStop() end

--- [SERVER]
---
--- Makes the NPC walk toward the given position. The NPC will return to the player after amount of time set by **player_squad_autosummon_time** [ConVar](https://wiki.facepunch.com/gmod/ConVar).
---
--- Only works on Citizens (npc_citizen) and is a part of the Half-Life 2 squad system.
---
--- The NPC **must** be in the player's squad for this to work.
---
---@param position garrysmod.Vector The target position for the NPC to walk to.
function NPC:MoveOrder( position ) end

--- [SERVER]
---
--- Pauses the NPC movement?
---
--- Related functions are [NPC:MoveStart](https://wiki.facepunch.com/gmod/NPC:MoveStart), [NPC:MoveStop](https://wiki.facepunch.com/gmod/NPC:MoveStop) and [NPC:ResetMoveCalc](https://wiki.facepunch.com/gmod/NPC:ResetMoveCalc).
---
function NPC:MovePause() end

--- [SERVER]
---
--- Starts NPC movement?
---
--- Related functions are [NPC:MoveStop](https://wiki.facepunch.com/gmod/NPC:MoveStop), [NPC:MovePause](https://wiki.facepunch.com/gmod/NPC:MovePause) and [NPC:ResetMoveCalc](https://wiki.facepunch.com/gmod/NPC:ResetMoveCalc).
---
function NPC:MoveStart() end

--- [SERVER]
---
--- Stops the NPC movement?
---
--- Related functions are [NPC:MoveStart](https://wiki.facepunch.com/gmod/NPC:MoveStart), [NPC:MovePause](https://wiki.facepunch.com/gmod/NPC:MovePause) and [NPC:ResetMoveCalc](https://wiki.facepunch.com/gmod/NPC:ResetMoveCalc).
---
function NPC:MoveStop() end

--- [SERVER]
---
--- Picks random node around given vector, around specified length, using dir as search direction start. Works similarly to [NPC:NavSetRandomGoal](https://wiki.facepunch.com/gmod/NPC:NavSetRandomGoal), but you can decide any position you want as a search starting point rather than your NPC.
---
---@param position garrysmod.Vector The origin to calculate a path from.
---@param length number The target length of the path to calculate.
---@param direction garrysmod.Vector The direction in which to look for a new path end goal.
---@return boolean success Whether path generation was successful or not.
function NPC:NavSetGoal( position, length, direction ) end

--- [SERVER]
---
--- Creates a path to closest node at given position. This won't actually force the NPC to move.
---
--- > NOTE: This will call either [NPC:TaskComplete](https://wiki.facepunch.com/gmod/NPC:TaskComplete) or [NPC:TaskFail](https://wiki.facepunch.com/gmod/NPC:TaskFail) for the current schedule and task, forcing the current task to progress to next task or fail.
---
--- See also [NPC:NavSetRandomGoal](https://wiki.facepunch.com/gmod/NPC:NavSetRandomGoal).
---
---@param position garrysmod.Vector The position to calculate a path to.
---@return boolean success Whether path generation was successful or not.
function NPC:NavSetGoalPos( position ) end

--- [SERVER]
---
--- Set the goal target for an NPC.
---
--- This will call either [NPC:TaskComplete](https://wiki.facepunch.com/gmod/NPC:TaskComplete) or [NPC:TaskFail](https://wiki.facepunch.com/gmod/NPC:TaskFail) for the current schedule and task, forcing the current task to progress to next task or fail.
---
---@param target garrysmod.Entity The targeted entity to set the goal to.
---@param offset garrysmod.Vector? The offset to apply to the targeted entity's position. Defaults to `Vector( 0, 0, 0 )`.
---@return boolean success Whether path generation was successful or not
function NPC:NavSetGoalTarget( target, offset ) end

--- [SERVER]
---
--- Creates a random path of specified minimum length between a closest start node and random node in the specified direction. This won't actually force the NPC to move.
---
---@param min_path_length number Minimum length of path in units
---@param direction garrysmod.Vector Unit vector pointing in the direction of the target random node
---@return boolean success Whether path generation was successful or not
function NPC:NavSetRandomGoal( min_path_length, direction ) end

--- [SERVER]
---
--- Sets a goal in x, y offsets for the NPC to wander to
---
---@param x_offset number X offset
---@param y_offset number Y offset
---@return boolean success Whether path generation was successful or not
function NPC:NavSetWanderGoal( x_offset, y_offset ) end

--- [SERVER]
---
--- Forces the NPC to pickup an existing weapon entity. The NPC will not pick up the weapon if they already own a weapon of given type, or if the NPC could not normally have this weapon in their inventory.
---
---@param weapon garrysmod.Weapon The weapon to try to pick up.
---@return boolean success Whether the NPC succeeded in picking up the weapon or not.
function NPC:PickupWeapon( weapon ) end

--- [SERVER]
---
--- Forces the NPC to play a sentence from scripts/sentences.txt
---
---@param sentence string The sentence string to speak.
---@param delay number Delay in seconds until the sentence starts playing.
---@param volume number The volume of the sentence, from 0 to 1.
---@return integer sentence_index Returns the sentence index, -1 if the sentence couldn't be played.
function NPC:PlaySentence( sentence, delay, volume ) end

--- [SERVER]
---
--- Makes the NPC remember an entity or an enemy as unreachable, for a specified amount of time. Use [NPC:IsUnreachable](https://wiki.facepunch.com/gmod/NPC:IsUnreachable) to check if an entity is still unreachable.
---
---@param entity garrysmod.Entity The entity to mark as unreachable.
---@param time number? For how long to remember the entity as unreachable. Negative values will act as `3` seconds. Defaults to `3`.
function NPC:RememberUnreachable( entity, time ) end

--- [SERVER]
---
--- Removes conditions to ignore for the this NPC.
---
---@param conditions integer[]? Ignore conditions to remove, see [Enums/COND](https://wiki.facepunch.com/gmod/Enums/COND). If omitted, removes all ignore conditions.
function NPC:RemoveIgnoreConditions( conditions ) end

--- [SERVER]
---
--- Resets the ideal activity of the NPC. See also [NPC:SetIdealActivity](https://wiki.facepunch.com/gmod/NPC:SetIdealActivity).
---
---@param act integer The new activity. See [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
function NPC:ResetIdealActivity( act ) end

--- [SERVER]
---
--- Resets all the movement calculations.
---
--- Related functions are [NPC:MoveStart](https://wiki.facepunch.com/gmod/NPC:MoveStart), [NPC:MovePause](https://wiki.facepunch.com/gmod/NPC:MovePause) and [NPC:MoveStop](https://wiki.facepunch.com/gmod/NPC:MoveStop).
---
function NPC:ResetMoveCalc() end

--- [SERVER]
---
--- Starts an engine task.
---
--- Used internally by the [ai_task](https://wiki.facepunch.com/gmod/ai_task).
---
---@param task_id integer The task ID, see [ai_task.h](https://github.com/ValveSoftware/source-sdk-2013/blob/55ed12f8d1eb6887d348be03aee5573d44177ffb/mp/src/game/server/ai_task.h#L89-L502)
---@param task_data number The task data.
function NPC:RunEngineTask( task_id, task_data ) end

--- [SERVER]
---
--- Forces the NPC to switch to a specific weapon the NPC owns. See [NPC:GetWeapons](https://wiki.facepunch.com/gmod/NPC:GetWeapons).
---
---@param weapon string | garrysmod.Weapon A classname of the weapon or a [Weapon](https://wiki.facepunch.com/gmod/Weapon) entity to switch to.
function NPC:SelectWeapon( weapon ) end

--- [SERVER]
---
--- Stops any sounds (speech) the NPC is currently playing.
---
--- Equivalent to `Entity:EmitSound( "AI_BaseNPC.SentenceStop" )`
---
function NPC:SentenceStop() end

--- [SERVER]
---
--- Sets the NPC's current activity.
---
---@param act integer The new activity to set, see [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
function NPC:SetActivity( act ) end

--- [SERVER]
---
---
---@param act integer See [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
function NPC:SetArrivalActivity( act ) end

--- [SERVER]
---
--- Sets the direction from the NPC origin to its current navigational destination.
---
---@param direction garrysmod.Vector The new arrival direction.
function NPC:SetArrivalDirection( direction ) end

--- [SERVER]
---
--- Sets the distance to goal at which the NPC should stop moving and continue to other business such as doing the rest of their tasks in a schedule.
---
---@param distance number The distance to goal that is close enough for the NPC
function NPC:SetArrivalDistance( distance ) end

--- [SERVER]
---
--- Sets the sequence to be played when the NPC arrives at its goal.
---
---@param sequence_id integer See [Entity:LookupSequence](https://wiki.facepunch.com/gmod/Entity:LookupSequence).
function NPC:SetArrivalSequence( sequence_id ) end

--- [SERVER]
---
--- Sets the arrival speed? of the NPC
---
---@param speed number The new arrival speed
function NPC:SetArrivalSpeed( speed ) end

--- [SERVER]
---
--- Sets an NPC condition.
---
---@param condition integer The condition index, see [Enums/COND](https://wiki.facepunch.com/gmod/Enums/COND).
function NPC:SetCondition( condition ) end

--- [SERVER]
---
--- Sets the weapon proficiency of an NPC (how skilled an NPC is with its current weapon).
---
---@param proficiency integer The proficiency for the NPC's current weapon. See [Enums/WEAPON_PROFICIENCY](https://wiki.facepunch.com/gmod/Enums/WEAPON_PROFICIENCY).
function NPC:SetCurrentWeaponProficiency( proficiency ) end

--- [SERVER]
---
--- Sets the target for an NPC.
---
---@param enemy garrysmod.Entity The enemy that the NPC should target
---@param new_enemy boolean? Calls [NPC:SetCondition](https://wiki.facepunch.com/gmod/NPC:SetCondition)(COND.NEW_ENEMY) if the new enemy is valid and not equal to the last enemy. Defaults to `true`.
function NPC:SetEnemy( enemy, new_enemy ) end

--- [SERVER]
---
--- Sets the NPC's .vcd expression. Similar to [Entity:PlayScene](https://wiki.facepunch.com/gmod/Entity:PlayScene) except the scene is looped until it's interrupted by default NPC behavior or [NPC:ClearExpression](https://wiki.facepunch.com/gmod/NPC:ClearExpression).
---
---@param file_path string The expression filepath.
---@return number duration Default duration of assigned expression, in seconds.
function NPC:SetExpression( file_path ) end

--- [SERVER]
---
--- Forces given NPC to crouch, if it is able to do so. Only Citizens and Combine Soldiers can by default.
---
---@param force boolean Whether to force the NPC to crouch or not. `false` clears the "force crouch" flag, but does not guarantee to force the NPC to stand back up.
function NPC:SetForceCrouch( force ) end

--- [SERVER]
---
--- Sets the Field Of View of the NPC, for use with such functions as [NPC:IsInViewCone](https://wiki.facepunch.com/gmod/NPC:IsInViewCone). it is also used internally by the NPC for enemy detection, etc.
---
---@param fov number The new FOV for the NPC in degrees.
function NPC:SetFOV( fov ) end

--- [SERVER]
---
--- Updates the NPC's hull and physics hull in order to match its model scale. [Entity:SetModelScale](https://wiki.facepunch.com/gmod/Entity:SetModelScale) seems to take care of this regardless.
---
function NPC:SetHullSizeNormal() end

--- [SERVER]
---
--- Sets the hull type for the NPC.
---
---@param hull_type integer Hull type. See [Enums/HULL](https://wiki.facepunch.com/gmod/Enums/HULL)
function NPC:SetHullType( hull_type ) end

--- [SERVER]
---
--- Sets the ideal activity the NPC currently wants to achieve. This is most useful for custom SNPCs.
---
---@param activity integer The ideal activity to set. [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
function NPC:SetIdealActivity( activity ) end

--- [SERVER]
---
--- Sets the ideal sequence the NPC currently wants to achieve. This is most useful for custom SNPCs.
---
---@param sequence_id integer The ideal sequence to set. [Entity:LookupSequence](https://wiki.facepunch.com/gmod/Entity:LookupSequence).
function NPC:SetIdealSequence( sequence_id ) end

--- [SERVER]
---
--- Sets the ideal yaw angle (left-right rotation) for the NPC. Does not actually force the NPC to start turning in that direction. See [NPC:UpdateYaw](https://wiki.facepunch.com/gmod/NPC:UpdateYaw), [NPC:GetIdealYaw](https://wiki.facepunch.com/gmod/NPC:GetIdealYaw) and [NPC:SetIdealYawAndUpdate](https://wiki.facepunch.com/gmod/NPC:SetIdealYawAndUpdate).
---
---@param angle number The aim direction to set, the `yaw` component.
function NPC:SetIdealYaw( angle ) end

--- [SERVER]
---
--- Sets the ideal yaw angle (left-right rotation) for the NPC and forces them to turn to that angle.
---
---@param angle number The aim direction to set, the `yaw` component.
---@param speed number? The turn speed. Special values are: * `-1` - Calculate automatically * `-2` - Keep the previous yaw speed Defaults to `-1`.
function NPC:SetIdealYawAndUpdate( angle, speed ) end

--- [SERVER]
---
--- Sets conditions to ignore, which would normally interrupt an Engine-based schedule. Specified conditions will still be set, will call [ENTITY:OnCondition](https://wiki.facepunch.com/gmod/ENTITY:OnCondition) and can be returned by [NPC:HasCondition](https://wiki.facepunch.com/gmod/NPC:HasCondition), but they will no longer interrupt the Engine schedule.
---
---@param conditions integer[] Conditions to ignore, see [Enums/COND](https://wiki.facepunch.com/gmod/Enums/COND). The table must be sequential, numerical and values must correspond to condition enums.
---@param size integer Number of conditions to include in the ignored conditions table. Set this to the size of ignored conditions table to ignore all specified conditions.
function NPC:SetIgnoreConditions( conditions, size ) end

--- [SERVER]
---
--- Sets the last registered or memorized position for this NPC. When using scheduling, the NPC will focus on navigating to the last position via nodes.
---
--- > NOTE: The navigation requires ground nodes to function properly, otherwise the NPC could only navigate in a small area. (https://developer.valvesoftware.com/wiki/Info_node)
---
---@param position garrysmod.Vector Where the NPC's last position will be set.
function NPC:SetLastPosition( position ) end

--- [SERVER]
---
--- Sets NPC's max view distance. An NPC will not be able to see enemies outside of this distance.
---
---@param distance number New maximum distance the NPC can see at. Default is 2048 and 6000 for long range NPCs such as the sniper.
function NPC:SetMaxLookDistance( distance ) end

--- [SERVER]
---
--- Sets how long to try rebuilding path before failing task.
---
---@param time number How long to try rebuilding path before failing task
function NPC:SetMaxRouteRebuildTime( time ) end

--- [SERVER]
---
--- Sets the movement delay for given NPC.
---
--- See [NPC:GetMoveDelay](https://wiki.facepunch.com/gmod/NPC:GetMoveDelay).
---
---@param delay number The amount of time in seconds to delay movement by.
function NPC:SetMoveDelay( delay ) end

--- [SERVER]
---
--- Sets the timestep the internal NPC motor is working on.
---
---@param time number The new timestep.
function NPC:SetMoveInterval( time ) end

--- [SERVER]
---
--- Sets the activity the NPC uses when it moves.
---
---@param activity integer The movement activity, see [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
function NPC:SetMovementActivity( activity ) end

--- [SERVER]
---
--- Sets the sequence the NPC navigation path uses for speed calculation. Doesn't seem to have any visible effect on NPC movement or actively playing sequence.
---
--- To be able to use this, first set [NPC:SetIdealActivity](https://wiki.facepunch.com/gmod/NPC:SetIdealActivity) to `ACT_DO_NOT_DISTURB`, set this to any sequence with root motion data and call [Entity:SetSequence](https://wiki.facepunch.com/gmod/Entity:SetSequence) on your desired sequence. As long as your NPC's [NPC:GetMovementSequence](https://wiki.facepunch.com/gmod/NPC:GetMovementSequence) has root motion data, your NPC will move to navigation point even though your NPC's [Entity:GetSequence](https://wiki.facepunch.com/gmod/Entity:GetSequence) doesn't have any motion.
---
---@param sequence_id integer The movement sequence index
function NPC:SetMovementSequence( sequence_id ) end

--- [SERVER]
---
--- Sets the move velocity of the NPC
---
---@param velocity garrysmod.Vector The new movement velocity.
function NPC:SetMoveVelocity( velocity ) end

--- [SERVER]
---
--- Sets whether the current movement should locked on the Yaw axis or not.
---
---@param lock boolean Whether the movement should yaw locked or not.
function NPC:SetMoveYawLocked( lock ) end

--- [SERVER]
---
--- Sets the navigation type of the NPC.
---
---@param nav_type integer The new nav type. See [Enums/NAV](https://wiki.facepunch.com/gmod/Enums/NAV).
function NPC:SetNavType( nav_type ) end

--- [SERVER]
---
--- Sets the state the NPC is in to help it decide on a ideal schedule.
---
---@param state integer New NPC state, see [Enums/NPC_STATE](https://wiki.facepunch.com/gmod/Enums/NPC_STATE)
function NPC:SetNPCState( state ) end

--- [SERVER]
---
--- Sets the NPC's current schedule.
---
---@param schedule integer The NPC schedule, see [Enums/SCHED](https://wiki.facepunch.com/gmod/Enums/SCHED).
function NPC:SetSchedule( schedule ) end

--- [SERVER]
---
--- Assigns the NPC to a new squad. A squad can have up to 16 NPCs. NPCs in a single squad should be friendly to each other.
---
--- See also [ai.GetSquadMembers](https://wiki.facepunch.com/gmod/ai.GetSquadMembers) and [NPC:GetSquad](https://wiki.facepunch.com/gmod/NPC:GetSquad).
---
--- NPCs within the same squad are meant to function more effectively, tactics wise.
---
---@param name string? The new squad name to set. Do not provide this argument to reset the squad.
function NPC:SetSquad( name ) end

--- [SERVER]
---
--- Sets the SNPC step height.
---
--- > NOTE: This only works for [scripted NPCs](https://wiki.facepunch.com/gmod/Scripted_Entities).
---
---@param height number The new step height. Default is 18 Hammer Units.
function NPC:SetStepHeight( height ) end

--- [SERVER]
---
--- Sets the NPC's target. This is used in some engine schedules.
---
---@param entity garrysmod.Entity The target of the NPC.
function NPC:SetTarget( entity ) end

--- [SERVER]
---
--- Sets the status of the current task.
---
---@param status integer The status. See [Enums/TASKSTATUS](https://wiki.facepunch.com/gmod/Enums/TASKSTATUS).
function NPC:SetTaskStatus( status ) end

--- [SERVER]
---
--- Sets given entity as an unforgettable enemy. The state can be retrieved via [NPC:IsUnforgettable](https://wiki.facepunch.com/gmod/NPC:IsUnforgettable).
---
---@param enemy garrysmod.Entity The enemy entity to set.
---@param unforgettable boolean? Whether the enemy should be unforgettable. Defaults to `true`.
function NPC:SetUnforgettable( enemy, unforgettable ) end

--- [SERVER]
---
--- Sets the view offset of the NPC. Player alternative of [Player:SetViewOffset](https://wiki.facepunch.com/gmod/Player:SetViewOffset).
---
--- This affects NPC's [NPC:GetShootPos](https://wiki.facepunch.com/gmod/NPC:GetShootPos).
---
---@param view_offset garrysmod.Vector The view offset to set.
function NPC:SetViewOffset( view_offset ) end

--- [SERVER]
---
--- Forces the NPC to start an engine task, this has different results for every NPC.
---
---@param task_id integer The id of the task to start, see [ai_task.h](https://github.com/ValveSoftware/source-sdk-2013/blob/55ed12f8d1eb6887d348be03aee5573d44177ffb/mp/src/game/server/ai_task.h#L89-L502)
---@param task_data number The task data as a float, not all tasks make use of it.
function NPC:StartEngineTask( task_id, task_data ) end

--- [SERVER]
---
--- Resets the NPC's movement animation and velocity. Does not actually stop the NPC from moving.
---
---@param immediate boolean? Whether to stop moving even when currently active goal doesn't want us to. Defaults to `true`.
function NPC:StopMoving( immediate ) end

--- [SERVER]
---
--- Cancels [NPC:MoveOrder](https://wiki.facepunch.com/gmod/NPC:MoveOrder) basically.
---
--- Only works on Citizens (npc_citizen) and is a part of the Half-Life 2 squad system.
---
--- The NPC **must** be in the player's squad for this to work.
---
---@param target garrysmod.Entity Must be a player, does nothing otherwise.
function NPC:TargetOrder( target ) end

--- [SERVER]
---
--- Marks the current NPC task as completed.
---
--- This is meant to be used alongside [NPC:TaskFail](https://wiki.facepunch.com/gmod/NPC:TaskFail) to complete or fail custom Lua defined tasks. ([Schedule:AddTask](https://wiki.facepunch.com/gmod/Schedule:AddTask))
---
function NPC:TaskComplete() end

--- [SERVER]
---
--- Marks the current NPC task as failed.
---
--- This is meant to be used alongside [NPC:TaskComplete](https://wiki.facepunch.com/gmod/NPC:TaskComplete) to complete or fail custom Lua defined tasks. ([Schedule:AddTask](https://wiki.facepunch.com/gmod/Schedule:AddTask))
---
---@param fail_reason string Fail reason to be passed onto [ENTITY:OnTaskFailed](https://wiki.facepunch.com/gmod/ENTITY:OnTaskFailed). The fail reason can also be seen when the NPC's `ent_text` is active.
function NPC:TaskFail( fail_reason ) end

--- [SERVER]
---
--- Force the NPC to update information on the supplied enemy, as if it had line of sight to it.
---
---@param enemy garrysmod.Entity The enemy to update.
---@param position garrysmod.Vector The last known position of the enemy.
function NPC:UpdateEnemyMemory( enemy, position ) end

--- [SERVER]
---
--- Updates the turn activity. Basically applies the turn animations depending on the current turn yaw.
---
function NPC:UpdateTurnActivity() end

--- [SERVER]
---
--- Forces the NPC to turn to their ideal yaw angle. See [NPC:SetIdealYaw](https://wiki.facepunch.com/gmod/NPC:SetIdealYaw) and [NPC:SetIdealYawAndUpdate](https://wiki.facepunch.com/gmod/NPC:SetIdealYawAndUpdate).
---
---@param speed number? The turn speed. Special values are: * `-1` - Calculate automatically * `-2` - Keep the previous yaw speed Defaults to `-1`.
function NPC:UpdateYaw( speed ) end

--- [SERVER]
---
--- > NOTE: This function only works on `ai` type [SENTs](Scripted_Entities).
---
---@return boolean success If we succeeded setting the behavior.
function NPC:UseActBusyBehavior() end

--- [SERVER]
---
--- Enables the AI's [Assault Behavior](https://developer.valvesoftware.com/wiki/Assault "Assault Behavior") when an `ai_goal_assault` is set for this SENT.
---
--- > NOTE: This function only works on `ai` type [SENTs](Scripted_Entities).
---
---@return boolean success Whether the action succeeded.
function NPC:UseAssaultBehavior() end

--- [SERVER]
---
--- > NOTE: This function only works on `ai` type [SENTs](Scripted_Entities).
---
---@return boolean success If we succeeded setting the behavior.
function NPC:UseFollowBehavior() end

--- [SERVER]
---
--- Orders the SNPC to control any nearby `func_tank`s looking for an NPC to operate itself, if available.
---
--- > NOTE: This function only works on `ai` type [SENTs](Scripted_Entities).
---
---@return boolean success Whether the action succeeded.
function NPC:UseFuncTankBehavior() end

--- [SERVER]
---
--- Enables the AI's [Lead Behavior](https://developer.valvesoftware.com/wiki/ai_goal_lead "Lead Behavior") when an `ai_goal_lead` is set for this SENT.
---
--- > NOTE: This function only works on `ai` type [SENTs](Scripted_Entities).
---
---@return boolean success Whether the action succeeded.
function NPC:UseLeadBehavior() end

--- [SERVER]
---
--- Undoes the other `Use*Behavior` functions.
---
--- > NOTE: This function only works on `ai` type [SENTs](Scripted_Entities).
---
function NPC:UseNoBehavior() end
