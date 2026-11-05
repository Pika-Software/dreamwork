---@meta garrysmod.entity


--- [SHARED]
---
--- This is a list of all available methods for all entities, which includes [Players](https://wiki.facepunch.com/gmod/Player), [Weapons](https://wiki.facepunch.com/gmod/Weapon), [NPCs](https://wiki.facepunch.com/gmod/NPC) and [Vehicles](https://wiki.facepunch.com/gmod/Vehicle).
--- For a list of possible members of [Scripted Entities](https://wiki.facepunch.com/gmod/Scripted_Entities) see [ENT Structure](https://wiki.facepunch.com/gmod/Structures/ENT).
---
---@class garrysmod.Entity : metatable
local Entity = {}

--- [SHARED]
---
--- Activates the entity. This needs to be used on some entities (like constraints) after being spawned.
---
--- > NOTE: For some entity types when this function is used after [Entity:SetModelScale](https://wiki.facepunch.com/gmod/Entity:SetModelScale), the physics object will be recreated with the new scale. [Source-sdk-2013](https://github.com/ValveSoftware/source-sdk-2013/blob/55ed12f8d1eb6887d348be03aee5573d44177ffb/mp/src/game/server/baseanimating.cpp#L321-L327).
--- >
--- > Calling this method after [Entity:SetModelScale](https://wiki.facepunch.com/gmod/Entity:SetModelScale) will recreate a new scaled `SOLID_VPHYSICS` [PhysObj](https://wiki.facepunch.com/gmod/PhysObj) on scripted entities. This can be a problem if you made a properly scaled [PhysObj](https://wiki.facepunch.com/gmod/PhysObj) of another kind (using [Entity:PhysicsInitSphere](https://wiki.facepunch.com/gmod/Entity:PhysicsInitSphere) for instance) or if you edited the [PhysObj](https://wiki.facepunch.com/gmod/PhysObj)'s properties. This is especially the behavior of the Sandbox spawn menu.
---
function Entity:Activate() end

--- [SHARED]
---
--- Add a callback function to a specific event. This is used instead of hooks to avoid calling empty functions unnecessarily.
---
--- This also allows you to use certain hooks in engine entities (non-scripted entities).
---
--- > WARNING: This method does not check if the function has already been added to this object before, so if you add the same callback twice, it will be run twice! Make sure to add your callback only once.
---
---@param hook string The hook name to hook onto. See [Entity Callbacks](https://wiki.facepunch.com/gmod/Entity_Callbacks)
---@param func function The function to call. It's arguments and return values will depend on the hook specified in the first argument.
---@return integer | nil callback_id The callback ID that was just added, which can later be used in [Entity:RemoveCallback](https://wiki.facepunch.com/gmod/Entity:RemoveCallback). Returns nothing if the passed callback function was invalid or when asking for a non-existent hook.
function Entity:AddCallback( hook, func ) end

--- [SHARED]
---
--- Applies an engine effect to an entity.
---
--- See also [Entity:IsEffectActive](https://wiki.facepunch.com/gmod/Entity:IsEffectActive) and  [Entity:RemoveEffects](https://wiki.facepunch.com/gmod/Entity:RemoveEffects).
---
---@param effect integer The effect to apply, see [Enums/EF](https://wiki.facepunch.com/gmod/Enums/EF).
function Entity:AddEffects( effect ) end

--- [SHARED]
---
--- Adds engine flags.
---
---@param flag integer Engine flag to add, see [Enums/EFL](https://wiki.facepunch.com/gmod/Enums/EFL)
function Entity:AddEFlags( flag ) end

--- [SHARED]
---
--- Adds flags to the entity.
---
---@param flag integer Flag to add, see [Enums/FL](https://wiki.facepunch.com/gmod/Enums/FL)
function Entity:AddFlags( flag ) end

--- [SERVER]
---
--- Adds a gesture animation to the entity and plays it.
---
--- See [Entity:AddGestureSequence](https://wiki.facepunch.com/gmod/Entity:AddGestureSequence) and [Entity:AddLayeredSequence](https://wiki.facepunch.com/gmod/Entity:AddLayeredSequence) for functions that takes sequences instead of [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entites!
---
--- > NOTE: (return value) If a layer has already been allocated for supplied [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT), it will return existing layer ID instead of allocating a new layer.
---
---@param activity integer The activity to play as the gesture. See [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
---@param autokill boolean? Automatically remove the gesture when it fully plays ([Entity:GetLayerCycle](https://wiki.facepunch.com/gmod/Entity:GetLayerCycle) reaches 1). Defaults to `true`.
---@return integer layer_id Layer ID of the started gesture, used to manipulate the played gesture by other functions.
function Entity:AddGesture( activity, autokill ) end

--- [SERVER]
---
--- Adds a gesture animation to the entity and plays it.
---
--- See [Entity:AddGesture](https://wiki.facepunch.com/gmod/Entity:AddGesture) for a function that takes [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
---
--- See also [Entity:AddLayeredSequence](https://wiki.facepunch.com/gmod/Entity:AddLayeredSequence).
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entites!
---
---@param sequence integer The sequence ID to play as the gesture. See [Entity:LookupSequence](https://wiki.facepunch.com/gmod/Entity:LookupSequence).
---@param autokill boolean? Automatically remove the gesture when it fully plays ([Entity:GetLayerCycle](https://wiki.facepunch.com/gmod/Entity:GetLayerCycle) reaches 1). Defaults to `true`.
---@return integer layer_id Layer ID of the started gesture, used to manipulate the played gesture by other functions.
function Entity:AddGestureSequence( sequence, autokill ) end

--- [SERVER]
---
--- Adds a gesture animation to the entity and plays it.
---
--- See [Entity:AddGestureSequence](https://wiki.facepunch.com/gmod/Entity:AddGestureSequence) for a function that doesn't take priority.
---
--- See [Entity:AddGesture](https://wiki.facepunch.com/gmod/Entity:AddGesture) for a function that takes [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entites!
---
---@param sequence integer The sequence ID to play as the gesture. See [Entity:LookupSequence](https://wiki.facepunch.com/gmod/Entity:LookupSequence).
---@param priority integer
---@return integer layer_id Layer ID of created layer
function Entity:AddLayeredSequence( sequence, priority ) end

--- [SHARED]
---
--- Adds solid flag(s) to the entity.
---
---@param flags integer The flag(s) to apply, see [Enums/FSOLID](https://wiki.facepunch.com/gmod/Enums/FSOLID).
function Entity:AddSolidFlags( flags ) end

--- [SHARED]
---
--- Adds a [PhysObj](https://wiki.facepunch.com/gmod/PhysObj)ect to the entity's motion controller so that [ENTITY:PhysicsSimulate](https://wiki.facepunch.com/gmod/ENTITY:PhysicsSimulate) will be called for given [PhysObj](https://wiki.facepunch.com/gmod/PhysObj)ect as well.
---
--- You must first create a motion controller with [Entity:StartMotionController](https://wiki.facepunch.com/gmod/Entity:StartMotionController).
---
--- You can remove added [PhysObj](https://wiki.facepunch.com/gmod/PhysObj)ects by using [Entity:RemoveFromMotionController](https://wiki.facepunch.com/gmod/Entity:RemoveFromMotionController).
---
--- > NOTE: Only works on a scripted [Entity](https://wiki.facepunch.com/gmod/Entity) of anim type
---
---@param phys_obj garrysmod.Physics The [PhysObj](https://wiki.facepunch.com/gmod/PhysObj) to add to the motion controller.
function Entity:AddToMotionController( phys_obj ) end

--- [SHARED]
---
--- Returns an angle based on the ones inputted that you can use to align an object.
---
--- > NOTE: This function doesn't change the angle of the entity on its own (see example).
---
---@param from garrysmod.Angle The angle you want to align from
---@param to garrysmod.Angle The angle you want to align to
---@return garrysmod.Angle angles The resulting aligned angle
function Entity:AlignAngles( from, to ) end

--- [SHARED]
---
--- Checks if the entity is considered alive.
---
--- Checks entity's internal life state variable. Does not check health, but it is generally expected the health to be 0 or below at the point of an entity being considered dead. This internally looks up the save value `m_lifeState`
---
---@return boolean is_alive Whether the entity is considered alive.
function Entity:Alive() end

--- [CLIENT]
---
--- Spawns a clientside ragdoll for the entity, positioning it in place of the original entity, and makes the entity invisible. It doesn't preserve flex values (face posing) as CSRagdolls don't support flex.
---
--- It does not work on players. Use [Player:CreateRagdoll](https://wiki.facepunch.com/gmod/Player:CreateRagdoll) instead.
---
--- The original entity is not removed, and neither are any ragdolls previously generated with this function.
---
--- To make the entity re-appear, run [Entity:SetNoDraw](https://wiki.facepunch.com/gmod/Entity:SetNoDraw)( false )
---
---@return garrysmod.Entity ragdoll The created ragdoll. (`class C_ClientRagdoll`)
function Entity:BecomeRagdollOnClient() end

--- [SERVER]
---
--- Dispatches blocked events to this entity's blocked handler. This function is only useful when interacting with entities like func_movelinear.
---
---@param entity garrysmod.Entity The entity that is blocking us
function Entity:Blocked( entity ) end

--- [SERVER]
---
--- Returns a centered vector of this entity, NPCs use this internally to aim at their targets.
---
--- > NOTE: This only works on players and NPCs.
---
---@param origin garrysmod.Vector The vector of where the the attack comes from.
---@param noisy boolean? Decides if it should return the centered vector with a random offset to it. Defaults to `false`.
---@return garrysmod.Vector position The centered vector.
function Entity:BodyTarget( origin, noisy ) end

--- [SHARED]
---
--- Returns whether the entity's bone has the flag or not.
---
---@param bone_id integer Bone ID to test flag of.
---@param flag integer The flag to test, see [Enums/BONE](https://wiki.facepunch.com/gmod/Enums/BONE)
---@return boolean has_flag Whether the bone has that flag or not
function Entity:BoneHasFlag( bone_id, flag ) end

--- [SHARED]
---
--- Returns the length between given bone's position and the position of given bone's parent.
---
---@param bone_id integer The ID of the bone you want the length of. You may want to get the length of the next bone ( boneID + 1 ) for decent results
---@return number length The length of the bone
function Entity:BoneLength( bone_id ) end

--- [SHARED]
---
--- Returns the distance between the center of the bounding box and the furthest bounding box corner.
---
---@return number bounding_radius The radius of the bounding box.
function Entity:BoundingRadius() end

--- [SERVER]
---
--- Clears all registered events for map I/O outputs on this entity. If a string is given, will use the string as a wildcard to limit removed outputs by name matches.
---
---@param output_name string? An optional string that will be used to limit removed outputs by name matches, supports wildcards.
function Entity:ClearAllOutputs( output_name ) end

--- [SHARED]
---
--- Resets all pose parameters such as aim_yaw, aim_pitch and rotation.
---
function Entity:ClearPoseParameters() end

--- [SHARED]
---
--- Declares that the collision rules of the entity have changed, and subsequent calls for [GM:ShouldCollide](https://wiki.facepunch.com/gmod/GM:ShouldCollide) with this entity may return a different value than they did previously.
---
--- > WARNING: This function must **not** be called inside of [GM:ShouldCollide](https://wiki.facepunch.com/gmod/GM:ShouldCollide). Instead, it must be called in advance when the condition is known to change.
---
--- > WARNING: Failure to use this function correctly will result in a crash of the physics engine.
---
function Entity:CollisionRulesChanged() end

--- [SHARED]
---
--- Same as [Entity:GetBoneMatrix](https://wiki.facepunch.com/gmod/Entity:GetBoneMatrix), but instead of returning a new matrix object, it copies the data to a given matrix.
---
--- This is measurably faster when accessing bone matrices a lot.
---
---@param bone_id integer The bone ID to retrieve matrix of, starting at index 0.
---@param data garrysmod.VMatrix The matrix to copy the bone matrix to.
function Entity:CopyBoneMatrix( bone_id, data ) end

--- [SERVER]
---
--- Creates bone followers based on the current entity model.
---
--- Bone followers are [Entities](https://wiki.facepunch.com/gmod/Entity) whose [Physics Objects](https://wiki.facepunch.com/gmod/PhysObj) follow a specific bone on another Entity's model.
--- This is what is used by `prop_dynamic` for things like big combine doors with multiple physics objects which follow the visual mesh of the door when it animates.
---
--- Be mindful that bone followers create a separate entity (`phys_bone_follower`) for each physics object.
---
--- You must call [Entity:UpdateBoneFollowers](https://wiki.facepunch.com/gmod/Entity:UpdateBoneFollowers) every tick for bone followers to update their positions.
---
--- > NOTE: This function only works on `anim`, `nextbot` and `ai` type entities.
---
---@param bone_whitelist table? If set, a whitelist of bone names to create bone followers for. If a models' bone name is not in this list, a bone follower entity will not be created for it.
function Entity:CreateBoneFollowers( bone_whitelist ) end

--- [SHARED]
---
--- Returns whether the entity was created by map or not.
---
---@return boolean is_created_by_map `true` if the entity was created by the map.
function Entity:CreatedByMap() end

--- [CLIENT]
---
--- Creates a clientside particle system attached to the entity. See also [Global.CreateParticleSystem](https://wiki.facepunch.com/gmod/Global.CreateParticleSystem)
---
--- > NOTE: The particle effect must be precached with [Global.PrecacheParticleSystem](https://wiki.facepunch.com/gmod/Global.PrecacheParticleSystem) and the file its from must be added via [game.AddParticles](https://wiki.facepunch.com/gmod/game.AddParticles) before it can be used!
---
---@param particle string The particle name to create
---@param attachment integer Attachment ID to attach the particle to
---@param options table? A table of tables ( IDs 1 to 64 ) having the following structure: * [number](https://wiki.facepunch.com/gmod/number) attachtype - The particle attach type. See [PATTACH](https://wiki.facepunch.com/gmod/Enums/PATTACH). **Default:** PATTACH_ABSORIGIN * [Entity](https://wiki.facepunch.com/gmod/Entity) entity - The parent entity? **Default:** NULL * [Vector](https://wiki.facepunch.com/gmod/Vector) position - The offset position for given control point. **Default:**  nil This only affects the control points of the particle effects and will do nothing if the effect doesn't use control points.
---@return userdata effect The created particle system.
function Entity:CreateParticleEffect( particle, attachment, options ) end

--- [CLIENT]
---
--- Draws the shadow of an entity.
---
function Entity:CreateShadow() end

--- [SERVER]
---
--- Whenever the entity is removed, entityToRemove will be removed also.
---
---@param entity_to_remove garrysmod.Entity The entity to be removed
function Entity:DeleteOnRemove( entity_to_remove ) end

--- [SERVER]
---
--- Destroys bone followers created by [Entity:CreateBoneFollowers](https://wiki.facepunch.com/gmod/Entity:CreateBoneFollowers).
---
--- > NOTE: This function only works on `anim` type entities.
---
function Entity:DestroyBoneFollowers() end

--- [CLIENT]
---
--- Removes the shadow for the entity.
---
--- The shadow will be recreated as soon as the entity wakes.
---
--- > NOTE: Doesn't affect shadows from flashlight/lamps/env_projectedtexture.
---
function Entity:DestroyShadow() end

--- [CLIENT]
---
--- Disables an active matrix. See [Entity:EnableMatrix](https://wiki.facepunch.com/gmod/Entity:EnableMatrix) for more info about active matrixes.
---
---@param matrix_type string The name of the matrix type to disable. Currently the only matrix type is `"RenderMultiply"`.
function Entity:DisableMatrix( matrix_type ) end

--- [SHARED]
---
--- Performs a trace attack towards the entity this function is called on, as if an invisible bullet is shot towards it. Visually identical to [Entity:TakeDamageInfo](https://wiki.facepunch.com/gmod/Entity:TakeDamageInfo).
---
--- > WARNING: Calling this function on the victim entity in [ENTITY:OnTakeDamage](https://wiki.facepunch.com/gmod/ENTITY:OnTakeDamage) can cause infinite loops.
---
--- > NOTE: This function correctly applies damage to [func_breakable_surf](https://developer.valvesoftware.com/wiki/Func_breakable_surf) entities, unlike [Entity:TakeDamageInfo](https://wiki.facepunch.com/gmod/Entity:TakeDamageInfo).
---
---@param damage_info garrysmod.DamageInfo The damage to apply.
---@param trace_res table Trace result to use to deal damage. See [Structures/TraceResult](https://wiki.facepunch.com/gmod/Structures/TraceResult)
---@param dir garrysmod.Vector? Direction of the attack. Defaults to `traceRes.HitNormal`.
function Entity:DispatchTraceAttack( damage_info, trace_res, dir ) end

--- [SERVER]
---
--- Dissolves the entity.
---
--- This function creates an `env_entity_dissolver` entity internally, which is parented to the target entity and remains until the entity is fully dissolved. Calling this function on an entity that is already dissolving will not create another `env_entity_dissolver` entity.
---
---@param type integer? Dissolve type. Should be one of the following values: | ID | Description | ||| | 0 | ENTITY_DISSOLVE_NORMAL | | 1 | ELECTRICAL| | 2 | ELECTRICAL_LIGHT | | 3 | ENTITY_DISSOLVE_CORE | Defaults to `0`.
---@param magnitude number? Magnitude of the dissolve effect, its effect depends on the dissolve type. Defaults to `0`.
---@param origin garrysmod.Vector? The origin for the dissolve effect, its effect depends on the dissolve type. Defaults to entity's origin.
---@param delay number? Delay until starting the dissolve, in seconds. There will be some particles produced during this time. Defaults to `0`.
function Entity:Dissolve( type, magnitude, origin, delay ) end

--- [SERVER]
---
--- This removes the argument entity from an ent's list of entities to 'delete on remove'
---
--- > NOTE: Also see [Entity:DeleteOnRemove](https://wiki.facepunch.com/gmod/Entity:DeleteOnRemove)
---
---@param entity_to_unremove garrysmod.Entity The entity to be removed from the list of entities to delete
function Entity:DontDeleteOnRemove( entity_to_unremove ) end

--- [CLIENT]
---
--- Draws the entity or model.
---
--- If called inside [ENTITY:Draw](https://wiki.facepunch.com/gmod/ENTITY:Draw) or [ENTITY:DrawTranslucent](https://wiki.facepunch.com/gmod/ENTITY:DrawTranslucent), it only draws the entity's model itself.
---
--- If called outside of those hooks, it will call both of said hooks depending on [Entity:GetRenderGroup](https://wiki.facepunch.com/gmod/Entity:GetRenderGroup), drawing the entire entity again.
---
--- When drawing an entity more than once per frame in different positions, you should call [Entity:SetupBones](https://wiki.facepunch.com/gmod/Entity:SetupBones) before each draw; Otherwise, the entity will retain its first drawn position.
---
--- > BUG: Using this with a map model ([game.GetWorld](https://wiki.facepunch.com/gmod/game.GetWorld)():[GetModel](https://wiki.facepunch.com/gmod/Entity:GetModel)()) crashes the game.
--- > See [issue #2688](https://github.com/Facepunch/garrysmod-issues/issues/2688).
---
---@param flags integer? The optional [STUDIO_](https://wiki.facepunch.com/gmod/Enums/STUDIO) flags, usually taken from [ENTITY:Draw](https://wiki.facepunch.com/gmod/ENTITY:Draw) and similar hooks. Defaults to `STUDIO_RENDER`.
function Entity:DrawModel( flags ) end

--- [SHARED]
---
--- Sets whether an entity's shadow should be drawn.
---
---@param should_draw boolean True to enable, false to disable shadow drawing.
function Entity:DrawShadow( should_draw ) end

--- [SERVER]
---
--- Move an entity down until it collides with something.
---
---@param mask integer? Trace mask. Defaults to `MASK_SOLID`.
---@param ignore_entity garrysmod.Entity? Trace ignore entity.
---@param max_dist number? Max trace dist. Defaults to `256`.
function Entity:DropToFloor( mask, ignore_entity, max_dist ) end

--- [SHARED]
---
--- Plays a sound on an entity. See also [Global.EmitSound](https://wiki.facepunch.com/gmod/Global.EmitSound) if you wish to play sounds without an entity.
---
--- If run clientside, the sound will only be heard locally.
--- If used on a player or NPC character with the mouth rigged, the character will "lip-sync" if the sound file contains lipsync data. See [this page](https://developer.valvesoftware.com/wiki/Choreography_creation/Lip_syncing) for more information.
---
--- > NOTE: When using this function with weapons, use the [Weapon](https://wiki.facepunch.com/gmod/Weapon) itself as the entity, not its owner!
---
--- > WARNING: Due to engine quirks, [sound scripts](https://developer.valvesoftware.com/wiki/Soundscripts) can't have their soundlevel, pitch, volume, or channel changed when played from an entity—the sound script parameters will override whatever you pass to this function.
--- >
--- > You can do one of these instead:
--- > * Use [sound.GetProperties](https://wiki.facepunch.com/gmod/sound.GetProperties) to select a sound from the script, and play the sound file directly.
--- > * For single-use sounds, you can pass the [SND_CHANGE_VOL](https://wiki.facepunch.com/gmod/Enums/SND) or [SND_CHANGE_PITCH](https://wiki.facepunch.com/gmod/Enums/SND) sound flags. However, this will change the volume or pitch of the sound if it's already playing, instead of starting the sound over or playing another instance.
--- > * Use [Global.EmitSound](https://wiki.facepunch.com/gmod/Global.EmitSound) with the entity parameter set to the [Entity:EntIndex](https://wiki.facepunch.com/gmod/Entity:EntIndex) of the entity you want to play the sound on.
---
--- > BUG: This does not respond to [Global.SuppressHostEvents](https://wiki.facepunch.com/gmod/Global.SuppressHostEvents).
--- > See [issue #2651](https://github.com/Facepunch/garrysmod-issues/issues/2651).
---
--- > WARNING: (`sound_name` argument) The string cannot have whitespace at the start or end. You can remove this with [string.Trim](https://wiki.facepunch.com/gmod/string.Trim).
---
---@param sound_name string The name of the sound to be played. This should either be a sound script name ([sound.Add](https://wiki.facepunch.com/gmod/sound.Add)) or a file path relative to the `sound/` folder. (so don't include `sound/`, and make note that it's not sound**s** when moving the sound file itself)
---@param sound_level integer? A modifier for the distance this sound will reach, acceptable range is 0 to 511. 100 means no adjustment to the level. See [Enums/SNDLVL](https://wiki.facepunch.com/gmod/Enums/SNDLVL) Defaults to `75`.
---@param pitch_percent integer? The pitch applied to the sound. The acceptable range is from 0 to 255. 100 means the pitch is not changed. Defaults to `100`.
---@param volume number? The volume, from 0 to 1. Defaults to `1`.
---@param channel integer? The sound channel, see [Enums/CHAN](https://wiki.facepunch.com/gmod/Enums/CHAN). Defaults to `CHAN_AUTO, CHAN_WEAPON for weapons`.
---@param sound_flags integer? The flags of the sound, see [Enums/SND](https://wiki.facepunch.com/gmod/Enums/SND) Defaults to `0`.
---@param dsp integer? The DSP preset for this sound. [DSP Presets](https://wiki.facepunch.com/gmod/DSP_Presets) Defaults to `1`.
---@param filter garrysmod.RecipientFilter? If set serverside, the sound will only be networked to the clients in the filter.
function Entity:EmitSound( sound_name, sound_level, pitch_percent, volume, channel, sound_flags, dsp, filter ) end

--- [SHARED]
---
--- Plays a sound of a step depending on the surface below the entity's foot.
---
--- It will use attachments `"RightFoot"` or `"LeftFoot"` to decide where to check the surface at. If the attachments do not exist, it will use regular Valve Biped skeleton bones. If they don't exist, it will fallback to the entity's origin.
---
---@param is_left_foot boolean Determines whether the step is a right foot or a left foot. This is used for certain NPCs such as Eli to determine what sound should be played. This also determines the position of the sound.
---@param volume number? The volume, from 0 to 1. Defaults to `1`.
function Entity:EmitStepSound( is_left_foot, volume ) end

--- [SERVER]
---
--- Toggles the constraints of this ragdoll entity on and off.
---
---@param toggle_constraints boolean Set to true to enable the constraints and false to disable them. Disabling constraints will delete the constraints.
function Entity:EnableConstraints( toggle_constraints ) end

--- [SHARED]
---
--- Flags an entity as using custom lua defined collisions. Fixes entities having spongy player collisions or not hitting traces, such as after [Entity:PhysicsFromMesh](https://wiki.facepunch.com/gmod/Entity:PhysicsFromMesh)
---
--- Internally identical to `Entity:AddSolidFlags( bit.bor( FSOLID_CUSTOMRAYTEST, FSOLID_CUSTOMBOXTEST ) )`
---
--- Do not confuse this function with [Entity:SetCustomCollisionCheck](https://wiki.facepunch.com/gmod/Entity:SetCustomCollisionCheck), they are not the same.
---
function Entity:EnableCustomCollisions() end

--- [CLIENT]
---
--- Can be used to apply a custom [VMatrix](https://wiki.facepunch.com/gmod/VMatrix) to the entity, mostly used for scaling the model by a [Vector](https://wiki.facepunch.com/gmod/Vector).
---
--- To disable it, use [Entity:DisableMatrix](https://wiki.facepunch.com/gmod/Entity:DisableMatrix).
---
--- If your old scales are wrong due to a recent update, use [Entity:SetLegacyTransform](https://wiki.facepunch.com/gmod/Entity:SetLegacyTransform) as a quick fix.
---
--- > NOTE: The matrix can also be modified to apply a custom rotation and offset via the [VMatrix:SetAngles](https://wiki.facepunch.com/gmod/VMatrix:SetAngles) and [VMatrix:SetTranslation](https://wiki.facepunch.com/gmod/VMatrix:SetTranslation) functions.
---
--- > BUG: This does not scale procedural bones, and disables inverse kinematics of the entity.
--- > See [issue #3502](https://github.com/Facepunch/garrysmod-issues/issues/3502).
---
---@param matrix_type string The name of the matrix type. Currently the only matrix type is `"RenderMultiply"`.
---@param matrix garrysmod.VMatrix The matrix to apply before drawing the entity.
function Entity:EnableMatrix( matrix_type, matrix ) end

--- [SHARED]
---
--- Gets the unique entity index of an entity.
---
--- > NOTE: Entity indices are marked as unused after deletion, and can be reused by newly-created entities
---
---@return integer index The index of the entity. `-1` for clientside-only or `0` for serverside-only and [NULL](https://wiki.facepunch.com/gmod/NULL) entities.
function Entity:EntIndex() end

--- [SERVER]
---
--- Extinguishes the entity if it is on fire.
---
--- Has no effect if called inside [GM:EntityTakeDamage](https://wiki.facepunch.com/gmod/GM:EntityTakeDamage) (and the attacker is the flame that's hurting the entity)
---
--- See also [Entity:Ignite](https://wiki.facepunch.com/gmod/Entity:Ignite).
---
function Entity:Extinguish() end

--- [SHARED]
---
--- Returns the direction a player, npc or ragdoll is looking as a world-oriented angle.
---
--- > BUG: This can return an incorrect value in vehicles (like pods, buggy, ...). **This bug has been fixed in the past but was causing many addons being broken, so the fix has been removed but applied to [Player:GetAimVector](https://wiki.facepunch.com/gmod/Player:GetAimVector) only**.
--- > See [issue #1150](https://github.com/Facepunch/garrysmod-issues/issues/1150).
---
--- > BUG: This may return local angles in jeeps when used with [Player:EnterVehicle](https://wiki.facepunch.com/gmod/Player:EnterVehicle). **A workaround is available in the second example.**
--- > See [issue #2620](https://github.com/Facepunch/garrysmod-issues/issues/2620).
---
---@return garrysmod.Angle angles Player's eye angle.
function Entity:EyeAngles() end

--- [SHARED]
---
--- Returns the position of an Player/NPC's view.
---
---@return garrysmod.Vector position View position of the entity.
function Entity:EyePos() end

--- [SHARED]
---
--- Searches the [Entity's](https://wiki.facepunch.com/gmod/Entity) model for a Body Group with a given name.
---
--- > NOTE: Weapons will return results from their viewmodels.
---
---@param name string The name to search for.
---@return integer body_group_id The [Body Group's ID](https://wiki.facepunch.com/gmod/Structures/BodyGroupData#id) or `-1` if no Body Group has the provided name.
function Entity:FindBodygroupByName( name ) end

--- [SERVER]
---
--- Searches the currently active layers for a layer playing animation with given activity.
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entites!
---
---@param activity integer The activity to search for. See [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
---@return integer layer_id A layer ID for given activity, or `-1` if not found.
function Entity:FindGestureLayer( activity ) end

--- [SERVER]
---
--- Searches the currently active layers for a layer playing animation with given sequence.
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entites!
---
---@param sequence_id integer The sequence ID to search for. See [Entity:LookupSequence](https://wiki.facepunch.com/gmod/Entity:LookupSequence).
---@return integer layer_id A layer ID for given sequence, or `-1` if not found.
function Entity:FindGestureSequenceLayer( sequence_id ) end

--- [SHARED]
---
--- Returns a transition from the given start and end sequence.
---
--- This function was only used by HL1 entities and NPCs, before the advent of sequence blending and gestures.
---
---@param current_sequence integer The currently playing sequence
---@param goal_sequence integer The goal sequence.
---@return integer sequence_id The transition sequence, -1 if not available.
function Entity:FindTransitionSequence( current_sequence, goal_sequence ) end

--- [SERVER]
---
--- Fires an entity's input, conforming to the map IO event queue system. You can find inputs for most entities on the [Valve Developer Wiki](https://developer.valvesoftware.com/wiki/Output)
---
--- See also [Entity:Input](https://wiki.facepunch.com/gmod/Entity:Input) for a function that bypasses the event queue and [GM:AcceptInput](https://wiki.facepunch.com/gmod/GM:AcceptInput).
---
---@param input string The name of the input to fire
---@param param string | number | boolean | nil The value to give to the input, can also be a [number](https://wiki.facepunch.com/gmod/number) or a [boolean](https://wiki.facepunch.com/gmod/boolean).
---@param delay number? Delay in seconds before firing Defaults to `0`.
---@param activator garrysmod.Entity? The entity that caused this input (i.e. the player who pushed a button)
---@param caller garrysmod.Entity? The entity that is triggering this input (i.e. the button that was pushed)
function Entity:Fire( input, param, delay, activator, caller ) end

--- [SHARED]
---
--- Fires a bullet.
---
--- When used in a  hook such as [WEAPON:Think](https://wiki.facepunch.com/gmod/WEAPON:Think) or [WEAPON:PrimaryAttack](https://wiki.facepunch.com/gmod/WEAPON:PrimaryAttack), it will use [Player:LagCompensation](https://wiki.facepunch.com/gmod/Player:LagCompensation) internally.
---
--- Lag compensation will not work if this function is called in a timer, regardless if the timer was made in a predicted hook.
---
--- Due to how `Entity:FireBullets` is set up internally, bullet tracers will always originate from the first attachment/index 1. This can be avoided by supplying your own tracer effect.
---
--- When firing bullets from a [Weapon](https://wiki.facepunch.com/gmod/Weapon), it is recommended to fire bullets from the weapon owner entity ([Player](https://wiki.facepunch.com/gmod/Player) or [NPC](https://wiki.facepunch.com/gmod/NPC)), not the [Weapon](https://wiki.facepunch.com/gmod/Weapon) itself.
---
---@param bullet_info garrysmod.Bullet The bullet data to be used. See the [Structures/Bullet](https://wiki.facepunch.com/gmod/Structures/Bullet).
---@param suppress_host_events boolean? Has the effect of encasing the FireBullets call in [Global.SuppressHostEvents](https://wiki.facepunch.com/gmod/Global.SuppressHostEvents), only works in multiplayer. Defaults to `false`.
function Entity:FireBullets( bullet_info, suppress_host_events ) end

--- [SHARED]
---
--- Makes an entity follow another entity's bone.
---
--- Internally this function calls [Entity:SetParent](https://wiki.facepunch.com/gmod/Entity:SetParent)( parent, boneid ), [Entity:AddEffects](https://wiki.facepunch.com/gmod/Entity:AddEffects)( EF_FOLLOWBONE
--- ) and sets an internal flag to always rebuild all bones.
---
--- > NOTE: If the entity vibrates or stops following the parent, you probably need to run [Entity:SetPredictable](https://wiki.facepunch.com/gmod/Entity:SetPredictable)( true ) clientside.
---
--- > WARNING: This function will not work if the target bone's parent bone is invalid or if the bone is not used by VERTEX LOD0
---
---@param parent garrysmod.Entity? The entity to follow the bone of. If unset, removes the FollowBone effect. Defaults to `NULL`.
---@param bone_id integer The bone to follow
function Entity:FollowBone( parent, bone_id ) end

--- [SHARED]
---
--- Forces the entity to be dropped, if it is being held by a player's Gravity Gun, Physics Gun or `+use` pickup.
---
--- See also [Player:DropObject](https://wiki.facepunch.com/gmod/Player:DropObject).
---
function Entity:ForcePlayerDrop() end

--- [SHARED]
---
--- Advances the cycle of an animated entity.
---
--- Animations that loop will automatically reset the cycle so you don't have to - ones that do not will stop animating once you reach the end of their sequence.
---
--- > WARNING: Do not call this function multiple times a frame, as it can cause unexpected results, such as animations playing at increased rate, etc.
--- >
--- > [NextBot:BodyMoveXY](https://wiki.facepunch.com/gmod/NextBot:BodyMoveXY) calls this internally, so do not call this function before or after [NextBot:BodyMoveXY](https://wiki.facepunch.com/gmod/NextBot:BodyMoveXY).
---
function Entity:FrameAdvance() end

--- [SHARED]
---
--- Returns the entity's velocity.
---
--- > NOTE: Actually binds to CBaseEntity::GetLocalVelocity() which retrieves the velocity of the entity due to its movement in the world from forces such as gravity. Does not include velocity from entity-on-entity collision.
---
---@return garrysmod.Vector velocity The velocity of the entity.
function Entity:GetAbsVelocity() end

--- [SHARED]
---
--- Gets the angles of given entity.
---
--- > BUG: This returns incorrect results for the local player clientside.
--- > See [issue #2764](https://github.com/Facepunch/garrysmod-issues/issues/2764).
---
--- > BUG: This will return the local player's [Global.EyeAngles](https://wiki.facepunch.com/gmod/Global.EyeAngles) in [rendering hooks](https://wiki.facepunch.com/gmod/3D_Rendering_Hooks).
--- > See [issue #3106](https://github.com/Facepunch/garrysmod-issues/issues/3106).
---
--- > BUG: This will return [Global.Angle](https://wiki.facepunch.com/gmod/Global.Angle)(0,0,0) in [rendering hooks](https://wiki.facepunch.com/gmod/3D_Rendering_Hooks) while paused in single-player.
--- > See [issue #3107](https://github.com/Facepunch/garrysmod-issues/issues/3107).
---
---@return garrysmod.Angle angles The angles of the entity.
function Entity:GetAngles() end

--- [SHARED]
---
--- Returns the amount of animations (not to be confused with sequences) the entity's model has. A sequence can consist of multiple animations.
---
--- See also [Entity:GetAnimInfo](https://wiki.facepunch.com/gmod/Entity:GetAnimInfo)
---
---@return integer anim_count The amount of animations the entity's model has.
function Entity:GetAnimCount() end

--- [SHARED]
---
--- Returns a table containing the number of frames, flags, name, and FPS of an entity's animation ID.
---
--- > NOTE: Animation ID is not the same as sequence ID. See [Entity:GetAnimCount](https://wiki.facepunch.com/gmod/Entity:GetAnimCount)
---
---@param anim_index integer The animation ID to look up, starting at 0.
---@return table | nil info Information about the animation, or `nil` if the index is out of bounds. A table with the following keys: * [string](https://wiki.facepunch.com/gmod/string) label - Animation name * [number](https://wiki.facepunch.com/gmod/number) fps - How many frames per second the animation should be played at * [number](https://wiki.facepunch.com/gmod/number) flags - [STUDIO_](https://github.com/ZeqMacaw/Crowbar/blob/0d46f3b6a694b74453db407c72c12a9685d8eb1d/Crowbar/Core/GameModel/SourceCommon/SourceMdlFileData/SourceMdlAnimationDesc.vb#L181) flags, such as looping * [number](https://wiki.facepunch.com/gmod/number) numframes - Number of frames the animation has
function Entity:GetAnimInfo( anim_index ) end

--- [CLIENT]
---
--- Returns the last time the entity had an animation update. Returns 0 if the entity doesn't animate.
---
---@return number anim_time The last time the entity had an animation update.
function Entity:GetAnimTime() end

--- [SHARED]
---
--- Returns the amount of time since last animation.
---
--- Works only on `CBaseAnimating` entities.
---
---@return number interval The amount of time since last animation.
function Entity:GetAnimTimeInterval() end

--- [SHARED]
---
--- Gets the orientation and position of the attachment by its ID, returns nothing if the attachment does not exist.
---
--- > NOTE: The update rate of this function is limited by the setting of ENT.AutomaticFrameAdvance for [Scripted Entities](https://wiki.facepunch.com/gmod/Scripted_Entities)!
---
--- > BUG: This will return improper values for viewmodels if used in [GM:CalcView](https://wiki.facepunch.com/gmod/GM:CalcView).
--- > See [issue #1255](https://github.com/Facepunch/garrysmod-issues/issues/1255).
---
---@param attachment_id integer The internal ID of the attachment.
---@return { Ang: garrysmod.Angle, Pos: garrysmod.Vector, Bone: integer } | nil attachment The table with angle and position of the attachment or `nil` if does not exist. See the [Structures/AngPos](https://wiki.facepunch.com/gmod/Structures/AngPos). Most notably, the table contains the keys `Ang` and `Pos` as well as `Bone`.
function Entity:GetAttachment( attachment_id ) end

--- [SHARED]
---
--- Returns a table containing all attachments of the given entity's model.
---
--- > BUG: This can have inconsistent results in single-player.
--- > See [issue #3167](https://github.com/Facepunch/garrysmod-issues/issues/3167).
---
---@return table attachments Attachment data. See [Structures/AttachmentData](https://wiki.facepunch.com/gmod/Structures/AttachmentData). Returns an empty table in case its model has no attachments or there's a some kind of other issue.
function Entity:GetAttachments() end

--- [SHARED]
---
--- Returns the entity's base velocity which is their velocity due to forces applied by other entities. This includes entity-on-entity collision or riding a treadmill.
---
---@return garrysmod.Vector velocity The base velocity of the entity.
function Entity:GetBaseVelocity() end

--- [SHARED]
---
--- Returns the blood color of this entity. This can be set with [Entity:SetBloodColor](https://wiki.facepunch.com/gmod/Entity:SetBloodColor).
---
---@return integer | nil blood_color Color from [Enums/BLOOD_COLOR](https://wiki.facepunch.com/gmod/Enums/BLOOD_COLOR) or [nil](https://wiki.facepunch.com/gmod/nil)
function Entity:GetBloodColor() end

--- [SHARED]
---
--- Returns the [Sub Model ID](https://wiki.facepunch.com/gmod/Structures/BodyGroupData#submodels) for the currently active [Sub Model](https://wiki.facepunch.com/gmod/Entity:GetSubModels) of the Body Group corresponding to the given [Body Group ID](https://wiki.facepunch.com/gmod/Structures/BodyGroupData#id).
---
--- > NOTE: Weapons will return results from their viewmodels.
---
---@param body_group_id integer The Body Group ID to retrieve the active Sub Model ID for. Body Group IDs start at `0`.
---@return integer sub_model_id The currently active Sub Model ID. Sub Model IDs start at `0`.
function Entity:GetBodygroup( body_group_id ) end

--- [SHARED]
---
--- Returns the number of [Sub Models](https://wiki.facepunch.com/gmod/Entity:GetSubModels) in the Body Group corresponding to a given [Body Group ID](https://wiki.facepunch.com/gmod/Structures/BodyGroupData#id) of the [Entity's](https://wiki.facepunch.com/gmod/Entity) model.
---
--- > NOTE: Weapons will return results from their viewmodels.
---
---@param body_group_id integer The Body Group ID to retrieve the Sub Model count of. Body Group IDs start at `0`.
---@return integer count The number of Sub Models in the Body Group.
function Entity:GetBodygroupCount( body_group_id ) end

--- [SHARED]
---
--- Retrieves the name of the Body Group corresponding to a given [Body Group ID](https://wiki.facepunch.com/gmod/Structures/BodyGroupData#id) on the [Entity's](https://wiki.facepunch.com/gmod/Entity) model.
---
--- > NOTE: Weapons will return results from their viewmodels.
---
---@param body_group_id integer The Body Group ID to get the name of.
---@return string name The name of the Body Group.
function Entity:GetBodygroupName( body_group_id ) end

--- [SHARED]
---
--- Returns a list of information about each Body Group present on the [Entity's](https://wiki.facepunch.com/gmod/Entity) model.
---
--- > NOTE: Weapons will return results from their viewmodels.
---
---@return table body_groups A table of Body Group information where each value is a [Structures/BodyGroupData](https://wiki.facepunch.com/gmod/Structures/BodyGroupData).
function Entity:GetBodyGroups() end

--- [SHARED]
---
--- Returns the contents of the specified bone.
---
---@param bone integer The bone id, starting at index 0. See [Entity:LookupBone](https://wiki.facepunch.com/gmod/Entity:LookupBone).
---@return integer contents The contents as a [Enums/CONTENTS](https://wiki.facepunch.com/gmod/Enums/CONTENTS) or 0 on failure.
function Entity:GetBoneContents( bone ) end

--- [SHARED]
---
--- Returns the value of the bone controller with the specified ID.
---
--- > NOTE: This is the precursor of pose parameters, and only works for Half Life 1: Source models supporting it.
---
---@param bone_id integer ID of the bone controller. Goes from 0 to 3.
---@return number value The value set on the bone controller.
function Entity:GetBoneController( bone_id ) end

--- [SHARED]
---
--- Returns the amount of bones in the entity.
---
--- > NOTE: Will return `0` for [Global.ClientsideModel](https://wiki.facepunch.com/gmod/Global.ClientsideModel) or undrawn entities until [Entity:SetupBones](https://wiki.facepunch.com/gmod/Entity:SetupBones) is called on the entity.
---
---@return integer count The amount of bones in given entity, starting at index 0.
function Entity:GetBoneCount() end

--- [SHARED]
---
--- Returns the transformation matrix of a given bone on the entity's model. The matrix contains the transformation used to position the bone in the world. It is not relative to the parent bone.
---
--- This is equivalent to constructing a [VMatrix](https://wiki.facepunch.com/gmod/VMatrix) using [Entity:GetBonePosition](https://wiki.facepunch.com/gmod/Entity:GetBonePosition).
---
--- See [Entity:CopyBoneMatrix](https://wiki.facepunch.com/gmod/Entity:CopyBoneMatrix) for a more performant version.
---
--- > BUG: This can return the server's matrix during server lag.
--- > See [issue #884](https://github.com/Facepunch/garrysmod-issues/issues/884).
---
--- > BUG: This can return garbage serverside or a 0,0,0 fourth column (represents position) for v49 models.
--- > See [issue #3285](https://github.com/Facepunch/garrysmod-issues/issues/3285).
---
---@param bone_id integer The bone ID to retrieve matrix of, starting at index 0. * Bones clientside and serverside will differ
---@return garrysmod.VMatrix | nil matrix The matrix * Some entities don't update animation every frame such as prop_physics and won't have accurate bone matrix.
function Entity:GetBoneMatrix( bone_id ) end

--- [SHARED]
---
--- Returns name of given bone id.
---
--- See [Entity:LookupBone](https://wiki.facepunch.com/gmod/Entity:LookupBone) for the inverse of this function.
---
---@param index integer ID of bone to lookup name of, starting at index 0.
---@return string name The name of given bone. * `"__INVALIDBONE__"` in case the name cannot be read or the index is out of range, or we failed or entity doesn't have a model.
function Entity:GetBoneName( index ) end

--- [SHARED]
---
--- Returns parent bone of given bone.
---
--- > NOTE: Will return -1 for [Global.ClientsideModel](https://wiki.facepunch.com/gmod/Global.ClientsideModel) until [Entity:SetupBones](https://wiki.facepunch.com/gmod/Entity:SetupBones) is called on the entity.
---
---@param bone integer The bone ID of the bone to get parent of, starting at index 0.
---@return integer parent_bone_id Parent bone ID or -1 if we failed for some reason.
function Entity:GetBoneParent( bone ) end

--- [SHARED]
---
--- Returns the position and angle of the given attachment, relative to the world.
---
--- > WARNING: This function can return entity's `GetPos()` instead if the entity doesn't have it's bone cache set up.
--- >
--- > To ensure the bone position is correct use this:
--- > ```lua
--- > local pos = ent:GetBonePosition(0)
--- > if pos == ent:GetPos() then
--- > pos = ent:GetBoneMatrix(0):GetTranslation()
--- > end
--- > ```
---
--- > NOTE: This function returns the bone position from the last tick, so if your framerate is higher than the server's tickrate it may appear to lag behind if used on a fast moving entity. You can fix this by using the bone's matrix instead:
--- > ```lua
--- > local matrix = entity:GetBoneMatrix(0)
--- > local pos = matrix:GetTranslation()
--- > local ang = matrix:GetAngles()
--- > ```
---
--- > BUG: This can return the server's position during server lag.
--- > See [issue #884](https://github.com/Facepunch/garrysmod-issues/issues/884).
---
--- > BUG: This can return garbage serverside or [Global.Vector](https://wiki.facepunch.com/gmod/Global.Vector)(0,0,0) for v49 models.
--- > See [issue #3285](https://github.com/Facepunch/garrysmod-issues/issues/3285).
---
--- > BUG: This can return garbage if a trace passed through the target bone during bone matrix access.
--- > See [issue #3739](https://github.com/Facepunch/garrysmod-issues/issues/3739).
---
---@param bone_index integer The bone index of the bone to get the position of, starting at index 0. See [Entity:LookupBone](https://wiki.facepunch.com/gmod/Entity:LookupBone).
---@return garrysmod.Vector position The bone's position relative to the world. It can return nothing if the requested bone is out of bounds, or the entity has no model.
---@return garrysmod.Angle angles The bone's angle relative to the world.
function Entity:GetBonePosition( bone_index ) end

--- [SHARED]
---
--- Returns the surface property of the specified bone. See [util.GetSurfaceData](https://wiki.facepunch.com/gmod/util.GetSurfaceData) for more details about what they are.
---
---@param bone integer The bone id, starting at index 0. See [Entity:LookupBone](https://wiki.facepunch.com/gmod/Entity:LookupBone).
---@return string surface_prop The surface property of the bone to be used with [util.GetSurfaceIndex](https://wiki.facepunch.com/gmod/util.GetSurfaceIndex) or an empty string on failure.
function Entity:GetBoneSurfaceProp( bone ) end

--- [SHARED]
---
--- Returns info about given plane of non-nodraw brush model surfaces of the entity's model. Works on worldspawn as well.
---
--- > WARNING: This only works on entities with brush models.
---
---@param id integer The index of the plane to get info of. Starts from 0.
---@return garrysmod.Vector origin The origin of the plane. This will be either the first vertex's position (if available) or the plane's normal multiplied by the plane's distance.
---@return garrysmod.Vector normal The normal of the plane.
---@return number distance The "distance" of the plane. The distance is the dot product of the plane's normal and the point it was initialized with.
function Entity:GetBrushPlane( id ) end

--- [SHARED]
---
--- Returns the amount of planes of non-nodraw brush model surfaces of the entity's model.
---
---@return integer count The amount of brush model planes of the entity's model. This will be 0 for any non-brush model.
function Entity:GetBrushPlaneCount() end

--- [SHARED]
---
--- Returns a table of brushes surfaces for brush model entities.
---
---@return table[] | nil surfaces A list of [SurfaceInfo](https://wiki.facepunch.com/gmod/SurfaceInfo) elements if the entity has a brush model, or `nil` otherwise.
function Entity:GetBrushSurfaces() end

--- [SHARED]
---
--- Returns the specified hook callbacks for this entity added with [Entity:AddCallback](https://wiki.facepunch.com/gmod/Entity:AddCallback)
---
--- The callbacks can then be removed with [Entity:RemoveCallback](https://wiki.facepunch.com/gmod/Entity:RemoveCallback).
---
---@param hook string The hook to retrieve the callbacks from, see [Entity Callbacks](https://wiki.facepunch.com/gmod/Entity_Callbacks) for the possible hooks.
---@return table callbacks A table containing the callbackid and function of all the callbacks for the specified hook
function Entity:GetCallbacks( hook ) end

--- [SHARED]
---
--- Gets the children of the entity - that is, every entity whose move parent is this entity.
---
--- > NOTE: This function returns [Entity:SetMoveParent](https://wiki.facepunch.com/gmod/Entity:SetMoveParent) children, **NOT** [Entity:SetParent](https://wiki.facepunch.com/gmod/Entity:SetParent)!
--- >
--- > [Entity:SetParent](https://wiki.facepunch.com/gmod/Entity:SetParent) however also calls [Entity:SetMoveParent](https://wiki.facepunch.com/gmod/Entity:SetMoveParent).
--- >
--- >
--- >
--- > This means that some entities in the returned list might have a NULL [Entity:GetParent](https://wiki.facepunch.com/gmod/Entity:GetParent).
--- >
--- > This also means that using this function on players will return their weapons on the client but not the server.
---
---@return garrysmod.Entity[] children A list of movement children entities
function Entity:GetChildren() end

--- [SHARED]
---
--- Returns the classname of a entity. This is often the name of the Lua file or folder containing the files for the entity
---
---@return string class The entity's classname
function Entity:GetClass() end

--- [SHARED]
---
--- Returns an entity's collision bounding box.
---
--- In most cases, this will return the same bounding box as [Entity:GetModelBounds](https://wiki.facepunch.com/gmod/Entity:GetModelBounds) unless the entity does not have a physics mesh or it has a [PhysObj](https://wiki.facepunch.com/gmod/PhysObj) different from the default.
---
--- Collision bounds can be previewed in singleplayer via `ent_bbox` console command, while looking at a desired entity and with `developer 1`. (Will appear as an orange wireframe box)
---
---@return garrysmod.Vector mins The minimum vector of the collision bounds, basically [Entity:OBBMins](https://wiki.facepunch.com/gmod/Entity:OBBMins).
---@return garrysmod.Vector maxs The maximum vector of the collision bounds, basically [Entity:OBBMaxs](https://wiki.facepunch.com/gmod/Entity:OBBMaxs).
function Entity:GetCollisionBounds() end

--- [SHARED]
---
--- Returns the entity's collision group
---
---@return integer collision_group The collision group. See [Enums/COLLISION_GROUP](https://wiki.facepunch.com/gmod/Enums/COLLISION_GROUP)
function Entity:GetCollisionGroup() end

--- [SHARED]
---
--- Returns the color the entity is set to without using a color object.
---
---@return integer r The red channel.
---@return integer g The green channel.
---@return integer b The blue channel.
---@return integer a The alpha channel.
function Entity:GetColor4Part() end

--- [SERVER]
---
--- Returns the two entities involved in a constraint ent, or nil if the entity is not a constraint.
---
---@return garrysmod.Entity entity1 The first constrained entity.
---@return garrysmod.Entity entity2 The second constrained entity.
function Entity:GetConstrainedEntities() end

--- [SERVER]
---
--- Returns the two entities physobjects involved in a constraint ent, or no value if the entity is not a constraint.
---
---@return garrysmod.Physics phys_obj1 The first constrained physics object.
---@return garrysmod.Physics phys_obj2 The second constrained physics object.
function Entity:GetConstrainedPhysObjects() end

--- [SHARED]
---
--- Returns entity's creation ID. Unlike [Entity:EntIndex](https://wiki.facepunch.com/gmod/Entity:EntIndex) or [Entity:MapCreationID](https://wiki.facepunch.com/gmod/Entity:MapCreationID).
---
--- It will increase up until value of `10 000 000`, at which point it will reset back to `0`.
---
--- > BUG: This returns `0` for clientside only entities, such as `class CLuaEffect`.
---
---@return integer creation_id The creation ID
function Entity:GetCreationID() end

--- [SHARED]
---
--- Returns the time the entity was created on, relative to [Global.CurTime](https://wiki.facepunch.com/gmod/Global.CurTime).
---
--- > BUG: This returns `0` for clientside only entities, such as `class CLuaEffect`.
---
---@return number creation_time The time the entity was created on.
function Entity:GetCreationTime() end

--- [SHARED]
---
--- Returns whether this entity uses custom collision check set by [Entity:SetCustomCollisionCheck](https://wiki.facepunch.com/gmod/Entity:SetCustomCollisionCheck).
---
---@return boolean enabled Whether this entity uses custom collision check or not
function Entity:GetCustomCollisionCheck() end

--- [SHARED]
---
--- Returns the frame of the currently played sequence. This will be a number between 0 and 1 as a representation of sequence progress.
---
---@return number cycle The frame of the currently played sequence
function Entity:GetCycle() end

--- [SHARED]
---
--- This is called internally by the [Entity:NetworkVar](https://wiki.facepunch.com/gmod/Entity:NetworkVar) system, you can use this in cases where using NetworkVar is not possible.
---
--- Get an angle stored in the datatable of the entity.
---
---@param key integer Goes from 0 to 31. Specifies what key to grab from datatable.
---@return garrysmod.Angle value Requested angle.
function Entity:GetDTAngle( key ) end

--- [SHARED]
---
--- This is called internally by the [Entity:NetworkVar](https://wiki.facepunch.com/gmod/Entity:NetworkVar) system, you can use this in cases where using NetworkVar is not possible.
---
--- Get a boolean stored in the datatable of the entity.
---
---@param key integer Goes from 0 to 31. Specifies what key to grab from datatable.
---@return boolean value Requested boolean.
function Entity:GetDTBool( key ) end

--- [SHARED]
---
--- This is called internally by the [Entity:NetworkVar](https://wiki.facepunch.com/gmod/Entity:NetworkVar) system, you can use this in cases where using NetworkVar is not possible.
---
--- Returns an entity stored in the datatable of the entity.
---
---@param key integer Goes from 0 to 31. Specifies what key to grab from datatable.
---@return garrysmod.Entity value Requested entity.
function Entity:GetDTEntity( key ) end

--- [SHARED]
---
--- This is called internally by the [Entity:NetworkVar](https://wiki.facepunch.com/gmod/Entity:NetworkVar) system, you can use this in cases where using NetworkVar is not possible.
---
--- Get a float stored in the datatable of the entity.
---
---@param key integer Goes from 0 to 31. Specifies what key to grab from datatable.
---@return number value Requested float.
function Entity:GetDTFloat( key ) end

--- [SHARED]
---
--- This is called internally by the [Entity:NetworkVar](https://wiki.facepunch.com/gmod/Entity:NetworkVar) system, you can use this in cases where using NetworkVar is not possible.
---
--- Get an integer stored in the datatable of the entity.
---
---@param key integer Goes from 0 to 31. Specifies what key to grab from datatable.
---@return integer value 32-bit signed integer
function Entity:GetDTInt( key ) end

--- [SHARED]
---
--- This is called internally by the [Entity:NetworkVar](https://wiki.facepunch.com/gmod/Entity:NetworkVar) system, you can use this in cases where using NetworkVar is not possible.
---
--- Get a string stored in the datatable of the entity.
---
---@param key integer Goes from 0 to 3. Specifies what key to grab from datatable.
---@return string value Requested string.
function Entity:GetDTString( key ) end

--- [SHARED]
---
--- This is called internally by the [Entity:NetworkVar](https://wiki.facepunch.com/gmod/Entity:NetworkVar) system, you can use this in cases where using NetworkVar is not possible.
---
--- Get a vector stored in the datatable of the entity.
---
---@param key integer Goes from 0 to 31. Specifies what key to grab from datatable.
---@return garrysmod.Vector value Requested vector.
function Entity:GetDTVector( key ) end

--- [SHARED]
---
--- Returns a bit flag of all engine effect flags of the entity.
---
---@return integer effects Engine effect flags, see [Enums/EF](https://wiki.facepunch.com/gmod/Enums/EF)
function Entity:GetEffects() end

--- [SHARED]
---
--- Returns a bit flag of all engine flags of the entity.
---
---@return integer flags Engine flags, see [Enums/EFL](https://wiki.facepunch.com/gmod/Enums/EFL)
function Entity:GetEFlags() end

--- [SHARED]
---
--- Returns the elasticity of this entity, used by some flying entities such as the Helicopter NPC to determine how much it should bounce around when colliding.
---
---@return number elasticity The elasticity.
function Entity:GetElasticity() end

--- [SHARED]
---
--- Returns all flags of given entity.
---
---@return integer flags Flags of given entity as a bitflag, see [Enums/FL](https://wiki.facepunch.com/gmod/Enums/FL)
function Entity:GetFlags() end

--- [SHARED]
---
--- Returns acceptable value range for the flex controller, as defined by the model.
---
--- Used with [Entity:SetFlexWeight](https://wiki.facepunch.com/gmod/Entity:SetFlexWeight).
---
---@param flex_id integer The ID of the flex to look up bounds of
---@return number min The minimum value for this flex
---@return number max The maximum value for this flex
function Entity:GetFlexBounds( flex_id ) end

--- [SHARED]
---
--- Returns the ID of the flex based on the beginning or the entire name.
---
---@param name string The name of the flex to get the ID of. Case sensitive.
---@return integer | nil flex_id The ID of flex * `nil` if no flex with given name was found
function Entity:GetFlexIDByName( name ) end

--- [SHARED]
---
--- Returns the flex controller name at given index.
---
---@param id integer The flex index to look up name of. The range is between `0` and [Entity:GetFlexNum](https://wiki.facepunch.com/gmod/Entity:GetFlexNum) - 1.
---@return string | nil name The flex name, or [no value](https://wiki.facepunch.com/gmod/no_value) if the requested ID is out of bounds.
function Entity:GetFlexName( id ) end

--- [SHARED]
---
--- Returns the number of flex controllers this entity's model has.
---
--- > NOTE: Please note that while this function can return the real number of flex controllers, the game supports only a certain amount due to networking limitations. See [Entity:SetFlexWeight](https://wiki.facepunch.com/gmod/Entity:SetFlexWeight).
---
---@return integer count The number of flexes.
function Entity:GetFlexNum() end

--- [SHARED]
---
--- Returns the flex scale of the entity.
---
---@return number scale The flex scale
function Entity:GetFlexScale() end

--- [SHARED]
---
--- Returns flex controller type or "category". Used internally by Faceposer to categorize flex controllers.
---
---@param id integer The flex index to look up type of. The range is between `0` and [Entity:GetFlexNum](https://wiki.facepunch.com/gmod/Entity:GetFlexNum) - 1.
---@return string | nil flex_type The flex type, or [no value](https://wiki.facepunch.com/gmod/no_value) if the requested ID is out of bounds.
function Entity:GetFlexType( id ) end

--- [SHARED]
---
--- Returns current weight ( value ) of given flex controller. Please see [Entity:SetFlexWeight](https://wiki.facepunch.com/gmod/Entity:SetFlexWeight) regarding limitations.
---
---@param flex_id integer The ID of the flex to get weight of
---@return number weight The current weight of the flex, or 0 if out of bounds.
function Entity:GetFlexWeight( flex_id ) end

--- [SHARED]
---
--- Returns the forward vector of the entity, as a normalized direction vector
---
---@return garrysmod.Vector direction The forward direction vector.
function Entity:GetForward() end

--- [SHARED]
---
--- Returns the friction modifier for this entity. Entities default to `1` (100%) and can be higher.
---
---@return number friction The friction multiplier.
function Entity:GetFriction() end

--- [SHARED]
---
--- Gets the gravity multiplier of the entity.
---
---@return number multiplier The gravity multiplier.
function Entity:GetGravity() end

--- [SHARED]
---
--- Returns the object the entity is standing on.
---
---@return garrysmod.Entity ground_entity The ground entity.
function Entity:GetGroundEntity() end

--- [SERVER]
---
--- Returns the entity's ground speed velocity, which is based on the entity's walk/run speed and/or the ground speed of their sequence ( [Entity:GetSequenceGroundSpeed](https://wiki.facepunch.com/gmod/Entity:GetSequenceGroundSpeed) ). Will return an empty [Vector](https://wiki.facepunch.com/gmod/Vector) if the entity isn't moving on the ground.
---
---@return garrysmod.Vector ground_speed_velocity The ground speed velocity.
function Entity:GetGroundSpeedVelocity() end

--- [SHARED]
---
--- Gets the bone the hit box is attached to.
---
---@param hitbox integer The number of the hit box.
---@param hitbox_set integer The number of the hit box set. This should be 0 in most cases. Numbering for these sets start from 0. The total amount of sets can be found with [Entity:GetHitBoxSetCount](https://wiki.facepunch.com/gmod/Entity:GetHitBoxSetCount).
---@return integer | nil bone_id The number of the bone. Will be nil if the hit box index was out of range.
function Entity:GetHitBoxBone( hitbox, hitbox_set ) end

--- [SHARED]
---
--- Gets the bounds (min and max corners) of a hit box.
---
---@param hitbox integer The number of the hit box.
---@param hitbox_set integer The hitbox set of the hit box. This should be 0 in most cases.
---@return garrysmod.Vector | nil mins Hit box mins. Will be nil if the hit box index was out of range.
---@return garrysmod.Vector | nil maxs Hit box maxs. Will be nil if the hit box index was out of range.
function Entity:GetHitBoxBounds( hitbox, hitbox_set ) end

--- [SHARED]
---
--- Gets how many hit boxes are in a given hit box set.
---
---@param hitbox_set integer The number of the hit box set.
---@return integer count The number of hit boxes.
function Entity:GetHitBoxCount( hitbox_set ) end

--- [SHARED]
---
--- Returns the number of hit box sets that an entity has. Functionally identical to [Entity:GetHitboxSetCount](https://wiki.facepunch.com/gmod/Entity:GetHitboxSetCount)
---
---@deprecated You should use [Entity:GetHitboxSetCount](https://wiki.facepunch.com/gmod/Entity:GetHitboxSetCount) instead.
---@return integer count The number of hit box sets.
function Entity:GetHitBoxGroupCount() end

--- [SHARED]
---
--- Gets the hit group of a given hitbox in a given hitbox set.
---
---@param hitbox integer The number of the hit box.
---@param hitbox_set integer The number of the hit box set. This should be 0 in most cases. Numbering for these sets start from 0. The total group count can be found with [Entity:GetHitBoxSetCount](https://wiki.facepunch.com/gmod/Entity:GetHitBoxSetCount).
---@return integer group The hitbox group of given hitbox. See [Enums/HITGROUP](https://wiki.facepunch.com/gmod/Enums/HITGROUP)
function Entity:GetHitBoxHitGroup( hitbox, hitbox_set ) end

--- [SHARED]
---
--- Returns entity's current hit box set
---
---@return integer | nil set_id The current hit box set id, or no value if the entity doesn't have hit boxes
---@return string | nil set_name The current hit box set name, or no value if the entity doesn't have hit boxes
function Entity:GetHitboxSet() end

--- [SHARED]
---
--- Returns the amount of hitbox sets in the entity.
---
---@return integer count The amount of hitbox sets in the entity.
function Entity:GetHitboxSetCount() end

--- [SHARED]
---
--- An interface for accessing internal key values on entities.
---
--- See [Entity:GetSaveTable](https://wiki.facepunch.com/gmod/Entity:GetSaveTable) for a more detailed explanation. See [Entity:SetSaveValue](https://wiki.facepunch.com/gmod/Entity:SetSaveValue) for the opposite of this function.
---
---@param variable_name string Name of variable corresponding to an entity save value.
---@return any value The internal variable value.
function Entity:GetInternalVariable( variable_name ) end

--- [SERVER]
---
--- Returns a table containing Hammer key values the entity has stored. **Not all key values will be accessible this way.** Use [GM:EntityKeyValue](https://wiki.facepunch.com/gmod/GM:EntityKeyValue) or [ENTITY:KeyValue](https://wiki.facepunch.com/gmod/ENTITY:KeyValue) to capture and store every key value.
---
--- Single key values can usually be retrieved with [Entity:GetInternalVariable](https://wiki.facepunch.com/gmod/Entity:GetInternalVariable).
---
--- Here's a list of keyvalues that will not appear in this list, as they are not stored/defined as actual keyvalues internally:
--- * rendercolor - [Entity:GetColor](https://wiki.facepunch.com/gmod/Entity:GetColor) (Only RGB)
--- * rendercolor32 - [Entity:GetColor](https://wiki.facepunch.com/gmod/Entity:GetColor) (RGBA)
--- * renderamt - [Entity:GetColor](https://wiki.facepunch.com/gmod/Entity:GetColor) (Alpha)
--- * disableshadows - [EF_NOSHADOW](https://wiki.facepunch.com/gmod/Enums/EF#EF_NOSHADOW)
--- * mins - [Entity:GetCollisionBounds](https://wiki.facepunch.com/gmod/Entity:GetCollisionBounds)
--- * maxs - [Entity:GetCollisionBounds](https://wiki.facepunch.com/gmod/Entity:GetCollisionBounds)
--- * disablereceiveshadows - [EF_NORECEIVESHADOW](https://wiki.facepunch.com/gmod/Enums/EF#EF_NORECEIVESHADOW)
--- * nodamageforces - [EFL_NO_DAMAGE_FORCES](https://wiki.facepunch.com/gmod/Enums/EFL#EFL_NO_DAMAGE_FORCES)
--- * angle - [Entity:GetAngles](https://wiki.facepunch.com/gmod/Entity:GetAngles)
--- * angles - [Entity:GetAngles](https://wiki.facepunch.com/gmod/Entity:GetAngles)
--- * origin - [Entity:GetPos](https://wiki.facepunch.com/gmod/Entity:GetPos)
--- * targetname - [Entity:GetName](https://wiki.facepunch.com/gmod/Entity:GetName)
---
---@return table key_values A table of key values.
function Entity:GetKeyValues() end

--- [SHARED]
---
--- Returns the animation cycle/frame for given layer.
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entities.
---
---@param layer_id integer The Layer ID
---@return number cycle The animation cycle/frame for given layer.
function Entity:GetLayerCycle( layer_id ) end

--- [SHARED]
---
--- Returns the duration of given layer.
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entities.
---
---@param layer_id integer The Layer ID
---@return number duration The duration of the layer
function Entity:GetLayerDuration( layer_id ) end

--- [SHARED]
---
--- Returns the layer playback rate. See also [Entity:GetLayerDuration](https://wiki.facepunch.com/gmod/Entity:GetLayerDuration).
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entities.
---
---@param layer_id integer The Layer ID
---@return number rate The current playback rate.
function Entity:GetLayerPlaybackRate( layer_id ) end

--- [SHARED]
---
--- Returns the sequence id of given layer.
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entities.
---
---@param layer_id integer The Layer ID.
---@return integer sequence_id The sequenceID of the layer.
function Entity:GetLayerSequence( layer_id ) end

--- [SHARED]
---
--- Returns the current weight of the layer. See [Entity:SetLayerWeight](https://wiki.facepunch.com/gmod/Entity:SetLayerWeight) for more information.
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entities.
---
---@param layer_id integer The Layer ID
---@return number weight The current weight of the layer
function Entity:GetLayerWeight( layer_id ) end

--- [SERVER]
---
--- Returns the entity that is being used as the light origin position for this entity.
---
---@return garrysmod.Entity entity The lighting entity. This will usually be NULL.
function Entity:GetLightingOriginEntity() end

--- [SHARED]
---
--- Returns the rotation of the entity relative to its parent entity.
---
---@return garrysmod.Angle angles The angles relative to the parent.
function Entity:GetLocalAngles() end

--- [SHARED]
---
--- Returns the non-VPhysics angular velocity of the entity relative to its parent entity.
---
---@return garrysmod.Angle velocity The local angular velocity.
function Entity:GetLocalAngularVelocity() end

--- [SHARED]
---
--- Returns entity's position relative to it's [Entity:GetParent](https://wiki.facepunch.com/gmod/Entity:GetParent).
---
--- See [Entity:GetPos](https://wiki.facepunch.com/gmod/Entity:GetPos) for the absolute position.
---
---@return garrysmod.Vector position The position relative to the parent.
function Entity:GetLocalPos() end

--- [SHARED]
---
--- Gets the entity's angle manipulation of the given bone. This is relative to the default angle, so the angle is zero when unmodified.
---
---@param bone_id integer The bone's ID
---@return garrysmod.Angle angles The entity's angle manipulation of the given bone.
function Entity:GetManipulateBoneAngles( bone_id ) end

--- [SHARED]
---
--- Returns the jiggle amount of the entity's bone.
---
--- See [Entity:ManipulateBoneJiggle](https://wiki.facepunch.com/gmod/Entity:ManipulateBoneJiggle) for more info.
---
---@param bone_id integer The bone ID
---@return integer jiggle_type The jiggle bone type, as set by [Entity:ManipulateBoneJiggle](https://wiki.facepunch.com/gmod/Entity:ManipulateBoneJiggle).
function Entity:GetManipulateBoneJiggle( bone_id ) end

--- [SHARED]
---
--- Gets the entity's position manipulation of the given bone. This is relative to the default position, so it is zero when unmodified.
---
---@param bone_id integer The bone's ID
---@return garrysmod.Vector position The entity's position manipulation of the given bone.
function Entity:GetManipulateBonePosition( bone_id ) end

--- [SHARED]
---
--- Gets the entity's scale manipulation of the given bone. Normal scale is Vector( 1, 1, 1 )
---
---@param bone_id integer The bone's ID
---@return garrysmod.Vector scale The entity's scale manipulation of the given bone
function Entity:GetManipulateBoneScale( bone_id ) end

--- [SHARED]
---
--- Returns the material override for this entity.
---
--- Returns an empty string if no material override exists. Use [Entity:GetMaterials](https://wiki.facepunch.com/gmod/Entity:GetMaterials) to list its default materials.
---
--- > BUG: The server's value takes priority on the client.
--- > See [issue #3362](https://github.com/Facepunch/garrysmod-issues/issues/3362).
---
---@return string material The material override path, or an empty string if none is set.
function Entity:GetMaterial() end

--- [SHARED]
---
--- Returns all materials of the entity's model.
---
--- This function is unaffected by [Entity:SetSubMaterial](https://wiki.facepunch.com/gmod/Entity:SetSubMaterial) as it returns the original materials.
---
--- > BUG: The table returned by this function will not contain materials if they are missing from the disk/repository. This means that if you are attempting to find the ID of a material to replace with [Entity:SetSubMaterial](https://wiki.facepunch.com/gmod/Entity:SetSubMaterial) and there are missing materials on the model, all subsequent materials will be offset in the table, meaning that the ID you are trying to get will be incorrect.
---
---@return string[] materials A table containing full paths to the materials of the model. For models, it's limited to `128` materials.
function Entity:GetMaterials() end

--- [SERVER]
---
--- Returns the [surface material type](https://developer.valvesoftware.com/wiki/Material_Types) of this entity.
---
--- This can be approximated clientside via [util.GetModelInfo](https://wiki.facepunch.com/gmod/util.GetModelInfo).
---
--- Internally, all this does is return `gamematerial` of the surface property on the first physics object of the entity. You can do this yourself using [PhysObj:GetMaterial](https://wiki.facepunch.com/gmod/PhysObj:GetMaterial) and [util.GetSurfaceData](https://wiki.facepunch.com/gmod/util.GetSurfaceData).
---
---@return integer material_type Surface material type. See [Enums/MAT](https://wiki.facepunch.com/gmod/Enums/MAT).
function Entity:GetMaterialType() end

--- [SHARED]
---
--- Returns the max health that the entity was given. It can be set via [Entity:SetMaxHealth](https://wiki.facepunch.com/gmod/Entity:SetMaxHealth).
---
---@return integer max_health Max health.
function Entity:GetMaxHealth() end

--- [SHARED]
---
--- Gets the model of given entity.
---
--- > BUG: This does not necessarily return the model's path, as is the case for brush and virtual models. This is intentional behaviour, however, there is currently no way to retrieve the actual file path.
--- >
--- > This also affects certain models that are edited by 3rd party programs after being compiled.
---
---@return string | nil model The entity's model. Will be a filesystem path for most models. This is guaranteed to be lower case. This will be [nil](https://wiki.facepunch.com/gmod/nil) for entities which cannot have models, such as point entities.
function Entity:GetModel() end

--- [SHARED]
---
--- Returns the entity's model bounds, not scaled by [Entity:SetModelScale](https://wiki.facepunch.com/gmod/Entity:SetModelScale).
---
--- These bounds are affected by all the animations the model has at compile time, if they go outside of the models' render bounds at any point.
--- See [Entity:GetModelRenderBounds](https://wiki.facepunch.com/gmod/Entity:GetModelRenderBounds) for just the render bounds of the model.
---
--- This is different than the collision bounds/hull, which are set via [Entity:SetCollisionBounds](https://wiki.facepunch.com/gmod/Entity:SetCollisionBounds).
---
---@return garrysmod.Vector mins The minimum vector of the bounds
---@return garrysmod.Vector maxs The maximum vector of the bounds
function Entity:GetModelBounds() end

--- [SHARED]
---
--- Returns the contents of the entity's current model.
---
---@return integer contents The contents of the entity's model. See [Enums/CONTENTS](https://wiki.facepunch.com/gmod/Enums/CONTENTS).
function Entity:GetModelContents() end

--- [CLIENT]
---
--- Gets the physics bone count of the entity's model. This is only applicable to `anim` type [Scripted Entities](https://wiki.facepunch.com/gmod/Scripted_Entities) with ragdoll models.
---
---@return integer count How many physics bones exist on the model.
function Entity:GetModelPhysBoneCount() end

--- [SHARED]
---
--- Gets the models radius.
---
--- > WARNING: (return value) This can return [nil](https://wiki.facepunch.com/gmod/nil) instead of a [number](https://wiki.facepunch.com/gmod/number) in some cases.
---
---@return number radius The radius of the model.
function Entity:GetModelRadius() end

--- [SHARED]
---
--- Returns the entity's model render bounds. Unlike [Entity:GetModelBounds](https://wiki.facepunch.com/gmod/Entity:GetModelBounds), bounds returning by this function will not be affected by animations (at compile time).
---
---@return garrysmod.Vector mins The minimum vector of the bounds
---@return garrysmod.Vector maxs The maximum vector of the bounds
function Entity:GetModelRenderBounds() end

--- [SHARED]
---
--- Gets the selected entity's model scale.
---
---@return number scale Scale of that entity's model.
function Entity:GetModelScale() end

--- [SERVER]
---
--- Returns the amount a momentary_rot_button entity is turned based on the given angle. 0 meaning completely turned closed, 1 meaning completely turned open.
---
--- > WARNING: This only works on momentary_rot_button entities.
---
---@param turn_angle garrysmod.Angle The angle of rotation to compare - usually should be [Entity:GetAngles](https://wiki.facepunch.com/gmod/Entity:GetAngles).
---@return number position The amount the momentary_rot_button is turned, ranging from 0 to 1, or nil if the entity is not a momentary_rot_button.
function Entity:GetMomentaryRotButtonPos( turn_angle ) end

--- [SHARED]
---
--- Returns the move collide type of the entity. The move collide is the way a physics object reacts to hitting an object - will it bounce, slide?
---
---@return integer move_collide The move collide type, see [Enums/MOVECOLLIDE](https://wiki.facepunch.com/gmod/Enums/MOVECOLLIDE)
function Entity:GetMoveCollide() end

--- [SHARED]
---
--- Returns the movement parent of this entity.
---
--- See [Entity:SetMoveParent](https://wiki.facepunch.com/gmod/Entity:SetMoveParent) for more info.
---
---@return garrysmod.Entity move_parent The movement parent of this entity.
function Entity:GetMoveParent() end

--- [SHARED]
---
--- Returns the entity's movetype
---
---@return integer move_type Move type. See [Enums/MOVETYPE](https://wiki.facepunch.com/gmod/Enums/MOVETYPE)
function Entity:GetMoveType() end

--- [SERVER]
---
--- Returns the "targetname" of this entity, typically used in map making and scripting to uniquely identify and target (hence 'targetname') an entity or a group of entities.
---
--- > WARNING: For players, this function is overwritten by [Player:GetName](https://wiki.facepunch.com/gmod/Player:GetName), which returns the player's nick name, not the target name.
---
---@return string name The name of the Entity
function Entity:GetName() end

--- [CLIENT]
---
--- Gets networked angles for entity.
---
---@return garrysmod.Angle angles The networked angles.
function Entity:GetNetworkAngles() end

--- [SHARED]
---
--- Retrieves a networked angle value at specified index on the entity that is set by [Entity:SetNetworked2Angle](https://wiki.facepunch.com/gmod/Entity:SetNetworked2Angle).
---
---@deprecated You should be using [Entity:GetNW2Angle](https://wiki.facepunch.com/gmod/Entity:GetNW2Angle) instead.
---@param key string The key that is associated with the value
---@param fallback garrysmod.Angle? The value to return if we failed to retrieve the value. (If it isn't set) Defaults to `Angle( 0, 0, 0 )`.
---@return garrysmod.Angle networked2_angle The value associated with the key
function Entity:GetNetworked2Angle( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked boolean value at specified index on the entity that is set by [Entity:SetNetworked2Bool](https://wiki.facepunch.com/gmod/Entity:SetNetworked2Bool).
---
---@deprecated You should be using [Entity:GetNW2Bool](https://wiki.facepunch.com/gmod/Entity:GetNW2Bool) instead.
---@param key string The key that is associated with the value
---@param fallback boolean? The value to return if we failed to retrieve the value. (If it isn't set) Defaults to `false`.
---@return boolean networked2_bool The value associated with the key
function Entity:GetNetworked2Bool( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked entity value at specified index on the entity that is set by [Entity:SetNetworked2Entity](https://wiki.facepunch.com/gmod/Entity:SetNetworked2Entity).
---
---@deprecated You should be using [Entity:GetNW2Entity](https://wiki.facepunch.com/gmod/Entity:GetNW2Entity) instead.
---@param key string The key that is associated with the value
---@param fallback garrysmod.Entity? The value to return if we failed to retrieve the value. (If it isn't set) Defaults to `NULL`.
---@return garrysmod.Entity networked2_entity The value associated with the key
function Entity:GetNetworked2Entity( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked float value at specified index on the entity that is set by [Entity:SetNetworked2Float](https://wiki.facepunch.com/gmod/Entity:SetNetworked2Float).
---
---@deprecated You should be using [Entity:GetNW2Float](https://wiki.facepunch.com/gmod/Entity:GetNW2Float) instead.
---@param key string The key that is associated with the value
---@param fallback number? The value to return if we failed to retrieve the value. (If it isn't set) Defaults to `0`.
---@return number networked2_float The value associated with the key
function Entity:GetNetworked2Float( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked integer (whole number) value that was previously set by [Entity:SetNetworked2Int](https://wiki.facepunch.com/gmod/Entity:SetNetworked2Int).
---
--- > WARNING: The integer has a 32 bit limit. Use [Entity:SetNWInt](https://wiki.facepunch.com/gmod/Entity:SetNWInt) and [Entity:GetNWInt](https://wiki.facepunch.com/gmod/Entity:GetNWInt) instead
---
---@deprecated You should be using [Entity:GetNW2Int](https://wiki.facepunch.com/gmod/Entity:GetNW2Int) instead.
---@param key string The key that is associated with the value
---@param fallback integer? The value to return if we failed to retrieve the value (If it isn't set). Defaults to `0`.
---@return integer networked2_int The value associated with the key
function Entity:GetNetworked2Int( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked string value at specified index on the entity that is set by [Entity:SetNetworked2String](https://wiki.facepunch.com/gmod/Entity:SetNetworked2String).
---
---@deprecated You should be using [Entity:GetNW2String](https://wiki.facepunch.com/gmod/Entity:GetNW2String) instead.
---@param key string The key that is associated with the value
---@param fallback string? The value to return if we failed to retrieve the value. (If it isn't set)
---@return string networked2_string The value associated with the key
function Entity:GetNetworked2String( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked value at specified index on the entity that is set by [Entity:SetNetworked2Var](https://wiki.facepunch.com/gmod/Entity:SetNetworked2Var).
---
---@deprecated You should be using [Entity:GetNW2Var](https://wiki.facepunch.com/gmod/Entity:GetNW2Var) instead.
---@param key string The key that is associated with the value
---@param fallback any? The value to return if we failed to retrieve the value. (If it isn't set)
---@return any networked2_var The value associated with the key
function Entity:GetNetworked2Var( key, fallback ) end

--- [SHARED]
---
--- Returns all the networked2 variables in an entity.
---
---@deprecated You should be using [Entity:GetNW2VarTable](https://wiki.facepunch.com/gmod/Entity:GetNW2VarTable) instead.
---@return table<string, any> vars Key-Value table of all networked2 variables.
function Entity:GetNetworked2VarTable() end

--- [SHARED]
---
--- Retrieves a networked vector value at specified index on the entity that is set by [Entity:SetNetworked2Vector](https://wiki.facepunch.com/gmod/Entity:SetNetworked2Vector).
---
---@deprecated You should be using [Entity:GetNW2Vector](https://wiki.facepunch.com/gmod/Entity:GetNW2Vector) instead.
---@param key string The key that is associated with the value
---@param fallback garrysmod.Vector? The value to return if we failed to retrieve the value. (If it isn't set) Defaults to `Vector( 0, 0, 0 )`.
---@return garrysmod.Vector networked2_vector The value associated with the key
function Entity:GetNetworked2Vector( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked angle value at specified index on the entity that is set by [Entity:SetNetworkedAngle](https://wiki.facepunch.com/gmod/Entity:SetNetworkedAngle).
---
---@deprecated You should use [Entity:GetNWAngle](https://wiki.facepunch.com/gmod/Entity:GetNWAngle) instead.
---@param key string The key that is associated with the value
---@param fallback garrysmod.Angle? The value to return if we failed to retrieve the value. ( If it isn't set ) Defaults to `Angle( 0, 0, 0 )`.
---@return garrysmod.Angle networked_angle The retrieved value
function Entity:GetNetworkedAngle( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked boolean value at specified index on the entity that is set by [Entity:SetNetworkedBool](https://wiki.facepunch.com/gmod/Entity:SetNetworkedBool).
---
---@deprecated You should use [Entity:GetNWBool](https://wiki.facepunch.com/gmod/Entity:GetNWBool) instead.
---@param key string The key that is associated with the value
---@param fallback boolean? The value to return if we failed to retrieve the value. ( If it isn't set ) Defaults to `false`.
---@return boolean networked_bool The retrieved value
function Entity:GetNetworkedBool( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked float value at specified index on the entity that is set by [Entity:SetNetworkedEntity](https://wiki.facepunch.com/gmod/Entity:SetNetworkedEntity).
---
---@deprecated You should use [Entity:GetNWEntity](https://wiki.facepunch.com/gmod/Entity:GetNWEntity) instead.
---@param key string The key that is associated with the value
---@param fallback garrysmod.Entity? The value to return if we failed to retrieve the value. ( If it isn't set ) Defaults to `NULL`.
---@return garrysmod.Entity networked_entity The retrieved value
function Entity:GetNetworkedEntity( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked float value at specified index on the entity that is set by [Entity:SetNetworkedFloat](https://wiki.facepunch.com/gmod/Entity:SetNetworkedFloat).
---
--- Seems to be the same as [Entity:GetNetworkedInt](https://wiki.facepunch.com/gmod/Entity:GetNetworkedInt).
---
---@deprecated You should use [Entity:GetNWFloat](https://wiki.facepunch.com/gmod/Entity:GetNWFloat) instead.
---@param key string The key that is associated with the value
---@param fallback number? The value to return if we failed to retrieve the value. ( If it isn't set ) Defaults to `0`.
---@return number networked_float The retrieved value
function Entity:GetNetworkedFloat( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked integer value at specified index on the entity that is set by [Entity:SetNetworkedInt](https://wiki.facepunch.com/gmod/Entity:SetNetworkedInt).
---
---@deprecated You should use [Entity:GetNWInt](https://wiki.facepunch.com/gmod/Entity:GetNWInt) instead.
---@param key string The key that is associated with the value
---@param fallback integer? The value to return if we failed to retrieve the value. ( If it isn't set ) Defaults to `0`.
---@return integer networked_int The retrieved value
function Entity:GetNetworkedInt( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked string value at specified index on the entity that is set by [Entity:SetNetworkedString](https://wiki.facepunch.com/gmod/Entity:SetNetworkedString).
---
---@deprecated You should use [Entity:GetNWString](https://wiki.facepunch.com/gmod/Entity:GetNWString) instead.
---@param key string The key that is associated with the value
---@param fallback string? The value to return if we failed to retrieve the value. ( If it isn't set )
---@return string networked_string The retrieved value
function Entity:GetNetworkedString( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked value at specified index on the entity that is set by [Entity:SetNetworkedVar](https://wiki.facepunch.com/gmod/Entity:SetNetworkedVar).
---
---@deprecated
---@param key string The key that is associated with the value
---@param fallback any? The value to return if we failed to retrieve the value. (If it isn't set)
---@return any networked_var The value associated with the key
function Entity:GetNetworkedVar( key, fallback ) end

--- [SHARED]
---
--- Returns all the networked variables in an entity.
---
---@deprecated You should be using [Entity:GetNWVarTable](https://wiki.facepunch.com/gmod/Entity:GetNWVarTable) instead.
---@return table<string, any> vars Key-Value table of all networked variables.
function Entity:GetNetworkedVarTable() end

--- [SHARED]
---
--- Retrieves a networked vector value at specified index on the entity that is set by [Entity:SetNetworkedVector](https://wiki.facepunch.com/gmod/Entity:SetNetworkedVector).
---
---@deprecated You should use [Entity:GetNWVector](https://wiki.facepunch.com/gmod/Entity:GetNWVector) instead.
---@param key string The key that is associated with the value
---@param fallback garrysmod.Vector? The value to return if we failed to retrieve the value. ( If it isn't set ) Defaults to `Vector( 0, 0, 0 )`.
---@return garrysmod.Vector networked_vector The retrieved value
function Entity:GetNetworkedVector( key, fallback ) end

--- [SHARED]
---
--- Gets networked origin for entity.
---
--- > NOTE: On the Client, this seems to return the position relative to the parent (if it has one). On the server-side this will return what you expect even if it has a parent.
---
---@return garrysmod.Vector origin The last received origin of the entity.
function Entity:GetNetworkOrigin() end

--- [SHARED]
---
--- Returns if the entity's rendering and transmitting has been disabled.
---
--- > NOTE: This is equivalent to calling [Entity:IsEffectActive](https://wiki.facepunch.com/gmod/Entity:IsEffectActive)( EF_NODRAW )
---
---@return boolean no_draw Whether the entity's rendering and transmitting has been disabled.
function Entity:GetNoDraw() end

--- [SHARED]
---
--- Returns the number of Body Groups that the [Entity's](https://wiki.facepunch.com/gmod/Entity) model contains.
---
--- > NOTE: Weapons will return results from their viewmodels.
---
---@return integer count The amount of Body Groups on the Entity's model.
function Entity:GetNumBodyGroups() end

--- [SHARED]
---
--- Returns the number of pose parameters this entity has.
---
---@return integer count Amount of pose parameters the entity has
function Entity:GetNumPoseParameters() end

--- [SHARED]
---
--- Retrieves a networked angle value at specified index on the entity that is set by [Entity:SetNW2Angle](https://wiki.facepunch.com/gmod/Entity:SetNW2Angle).
---
---@param key string The key that is associated with the value
---@param fallback garrysmod.Angle? The value to return if we failed to retrieve the value. (If it isn't set) Defaults to `Angle( 0, 0, 0 )`.
---@return garrysmod.Angle nw2_angle The value associated with the key
function Entity:GetNW2Angle( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked boolean value at specified index on the entity that is set by [Entity:SetNW2Bool](https://wiki.facepunch.com/gmod/Entity:SetNW2Bool).
---
---@param key string The key that is associated with the value
---@param fallback boolean? The value to return if we failed to retrieve the value. (If it isn't set) Defaults to `false`.
---@return boolean nw2_bool The value associated with the key
function Entity:GetNW2Bool( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked entity value at specified index on the entity that is set by [Entity:SetNW2Entity](https://wiki.facepunch.com/gmod/Entity:SetNW2Entity).
---
---@param key string The key that is associated with the value
---@param fallback garrysmod.Entity? The value to return if we failed to retrieve the value. (If it isn't set) Defaults to `NULL`.
---@return garrysmod.Entity nw2_entity The value associated with the key
function Entity:GetNW2Entity( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked float value at specified index on the entity that is set by [Entity:SetNW2Float](https://wiki.facepunch.com/gmod/Entity:SetNW2Float).
---
---@param key string The key that is associated with the value
---@param fallback number? The value to return if we failed to retrieve the value. (If it isn't set) Defaults to `0`.
---@return number nw2_float The value associated with the key
function Entity:GetNW2Float( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked integer (whole number) value that was previously set by [Entity:SetNW2Int](https://wiki.facepunch.com/gmod/Entity:SetNW2Int).
---
--- > WARNING: The integer has a 32 bit limit. Use [Entity:SetNWInt](https://wiki.facepunch.com/gmod/Entity:SetNWInt) and [Entity:GetNWInt](https://wiki.facepunch.com/gmod/Entity:GetNWInt) instead
---
---@param key string The key that is associated with the value
---@param fallback integer? The value to return if we failed to retrieve the value (If it isn't set). Defaults to `0`.
---@return integer nw2_int The value associated with the key
function Entity:GetNW2Int( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked string value at specified index on the entity that is set by [Entity:SetNW2String](https://wiki.facepunch.com/gmod/Entity:SetNW2String).
---
---@param key string The key that is associated with the value
---@param fallback string? The value to return if we failed to retrieve the value. (If it isn't set)
---@return string nw2_string The value associated with the key
function Entity:GetNW2String( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked value at specified index on the entity that is set by [Entity:SetNW2Var](https://wiki.facepunch.com/gmod/Entity:SetNW2Var).
---
---@param key string The key that is associated with the value
---@param fallback any? The value to return if we failed to retrieve the value. (If it isn't set)
---@return any nw2_var The value associated with the key
function Entity:GetNW2Var( key, fallback ) end

--- [SHARED]
---
--- Returns all the NW2 variables in an entity.
---
--- > BUG: This function will return keys with empty tables if the NW2Var is nil.
--- > See [issue #5396](https://github.com/Facepunch/garrysmod-issues/issues/5396).
---
---@return table<string, any> vars Key-Value table of all NW2 variables.
function Entity:GetNW2VarTable() end

--- [SHARED]
---
--- Retrieves a networked vector value at specified index on the entity that is set by [Entity:SetNW2Vector](https://wiki.facepunch.com/gmod/Entity:SetNW2Vector).
---
---@param key string The key that is associated with the value
---@param fallback garrysmod.Vector? The value to return if we failed to retrieve the value. (If it isn't set) Defaults to `Vector( 0, 0, 0 )`.
---@return garrysmod.Vector nw2_vector The value associated with the key
function Entity:GetNW2Vector( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked angle value at specified index on the entity that is set by [Entity:SetNWAngle](https://wiki.facepunch.com/gmod/Entity:SetNWAngle).
---
---@param key string The key that is associated with the value
---@param fallback garrysmod.Angle? The value to return if we failed to retrieve the value. (If it isn't set) Defaults to `Angle( 0, 0, 0 )`.
---@return garrysmod.Angle nw_angle The value associated with the key
function Entity:GetNWAngle( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked boolean value at specified index on the entity that is set by [Entity:SetNWBool](https://wiki.facepunch.com/gmod/Entity:SetNWBool).
---
---@param key string The key that is associated with the value
---@param fallback boolean? The value to return if we failed to retrieve the value. (If it isn't set) Defaults to `false`.
---@return boolean nw_bool The value associated with the key
function Entity:GetNWBool( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked entity value at specified index on the entity that is set by [Entity:SetNWEntity](https://wiki.facepunch.com/gmod/Entity:SetNWEntity).
---
---@param key string The key that is associated with the value
---@param fallback garrysmod.Entity? The value to return if we failed to retrieve the value. (If it isn't set) Defaults to `NULL`.
---@return garrysmod.Entity nw_entity The value associated with the key
function Entity:GetNWEntity( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked float value at specified index on the entity that is set by [Entity:SetNWFloat](https://wiki.facepunch.com/gmod/Entity:SetNWFloat).
---
---@param key string The key that is associated with the value
---@param fallback number? The value to return if we failed to retrieve the value. (If it isn't set) Defaults to `0`.
---@return number nw_float The value associated with the key
function Entity:GetNWFloat( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked integer (whole number) value that was previously set by [Entity:SetNWInt](https://wiki.facepunch.com/gmod/Entity:SetNWInt).
---
--- > BUG: This function will not round decimal values as it actually networks a float internally.
--- > See [issue #3374](https://github.com/Facepunch/garrysmod-issues/issues/3374).
---
---@param key string The key that is associated with the value
---@param fallback integer? The value to return if we failed to retrieve the value (If it isn't set). Defaults to `0`.
---@return integer nw_int The value associated with the key
function Entity:GetNWInt( key, fallback ) end

--- [SHARED]
---
--- Retrieves a networked string value at specified index on the entity that is set by [Entity:SetNWString](https://wiki.facepunch.com/gmod/Entity:SetNWString).
---
---@param key string The key that is associated with the value
---@param fallback string? The value to return if we failed to retrieve the value. (If it isn't set)
---@return string nw_string The value associated with the key
function Entity:GetNWString( key, fallback ) end

--- [SHARED]
---
--- Returns all the networked variables in an entity.
---
---@return table<string, any> vars Key-Value table of all networked variables.
function Entity:GetNWVarTable() end

--- [SHARED]
---
--- Retrieves a networked vector value at specified index on the entity that is set by [Entity:SetNWVector](https://wiki.facepunch.com/gmod/Entity:SetNWVector).
---
---@param key string The key that is associated with the value
---@param fallback garrysmod.Vector? The value to return if we failed to retrieve the value. (If it isn't set) Defaults to `Vector( 0, 0, 0 )`.
---@return garrysmod.Vector nw_vector The value associated with the key
function Entity:GetNWVector( key, fallback ) end

--- [SHARED]
---
--- Returns the owner entity of this entity. See [Entity:SetOwner](https://wiki.facepunch.com/gmod/Entity:SetOwner) for more info.
---
--- > NOTE: This function is generally used to disable physics interactions on projectiles being fired by their owner, but can also be used for normal ownership in case physics interactions are not involved at all. The Gravity gun will be able to pick up the entity even if the owner can't collide with it, the Physics gun however will not.
---
---@return garrysmod.Entity owner The owner entity of this entity.
function Entity:GetOwner() end

--- [SHARED]
---
--- Returns the parent entity of this entity.
---
---@return garrysmod.Entity parent The parent entity.
function Entity:GetParent() end

--- [SHARED]
---
--- Returns the attachment/bone index of the entity's parent. Returns 0 if the entity is not parented to an attachment/bone or if it isn't parented at all.
---
--- This is set by second argument of [Entity:SetParent](https://wiki.facepunch.com/gmod/Entity:SetParent) or the **SetParentAttachment** input.
---
--- > NOTE: (return value) Will return bone index instead of attachment index if the **EF_FOLLOWBONE** effect is active on the entity. See [Entity:IsEffectActive](https://wiki.facepunch.com/gmod/Entity:IsEffectActive).
---
---@return integer attachment_id The parented attachment/bone index
function Entity:GetParentAttachment() end

--- [SHARED]
---
--- If the entity is parented to an entity that has a model with multiple physics objects (like a ragdoll), this is used to retrieve what physics object number the entity is parented to on it's parent.
---
---@return integer | nil phys_num The physics object id, or nil if the entity has no parent
function Entity:GetParentPhysNum() end

--- [SHARED]
---
--- Returns the position and angle of the entity's move parent as a 3x4 matrix ([VMatrix](https://wiki.facepunch.com/gmod/VMatrix) is 4x4 so the fourth row goes unused). The first three columns store the angle as a [rotation matrix](https://en.wikipedia.org/wiki/Rotation_matrix), and the fourth column stores the position vector.
---
---@return garrysmod.VMatrix matrix The position and angle matrix. If the entity has no move parent, an identity matrix will be returned. If the entity is [parented to attachment](https://wiki.facepunch.com/gmod/Entity:GetParentAttachment) 0 or the parent isn't a BaseAnimating entity, the equivalent of [Entity](https://wiki.facepunch.com/gmod/Entity):[GetMoveParent()](https://wiki.facepunch.com/gmod/Entity:GetMoveParent):[GetWorldTransformMatrix()](https://wiki.facepunch.com/gmod/Entity:GetWorldTransformMatrix) will be returned.
function Entity:GetParentWorldTransformMatrix() end

--- [SHARED]
---
--- Returns whether the entity is persistent or not.
---
--- See [Entity:SetPersistent](https://wiki.facepunch.com/gmod/Entity:SetPersistent) for more information on persistence.
---
---@return boolean persistent True if the entity is set to be persistent.
function Entity:GetPersistent() end

--- [SERVER]
---
--- Returns player who is claiming kills of physics damage the entity deals.
---
--- > NOTE: (`time_limit` argument) Some entities such as the Combine Ball disregard the time limit and always return the physics attacker.
---
---@param time_limit number? The time to check if the entity was still a proper physics attacker. Defaults to `1`.
---@return garrysmod.Player attacker The player. If entity that was set is not a player, it will return NULL entity.
function Entity:GetPhysicsAttacker( time_limit ) end

--- [SHARED]
---
--- Returns the entity's physics object, if the entity has physics. Same as `ent:GetPhysicsObjectNum( 0 )`
---
--- > NOTE: Entities don't have clientside physics objects by default, so this will return `[NULL PHYSOBJ]` on the client in most cases.
---
---@return garrysmod.Physics physics_object The entity's physics object.
function Entity:GetPhysicsObject() end

--- [SHARED]
---
--- Returns the number of physics objects an entity has (usually 1 for non-ragdolls)
---
---@return integer count The number of physics objects.
function Entity:GetPhysicsObjectCount() end

--- [SHARED]
---
--- Returns a specific physics object from an entity with multiple [PhysObj](https://wiki.facepunch.com/gmod/PhysObj)ects (like ragdolls)
---
--- See also [Entity:TranslateBoneToPhysBone](https://wiki.facepunch.com/gmod/Entity:TranslateBoneToPhysBone).
---
---@param phys_num integer The number corresponding to the [PhysObj](https://wiki.facepunch.com/gmod/PhysObj) to grab. Starts at 0 with the max being 31.
---@return garrysmod.Physics phys_obj The physics object or nil if not found
function Entity:GetPhysicsObjectNum( phys_num ) end

--- [SHARED]
---
--- Returns the playback rate of the main sequence on this entity, with 1.0 being the default speed.
---
---@return number playback_rate The playback rate.
function Entity:GetPlaybackRate() end

--- [SHARED]
---
--- Gets the position of given entity in the world.
---
--- See [Entity:GetLocalPos](https://wiki.facepunch.com/gmod/Entity:GetLocalPos) for the position relative to the entity's [Entity:GetParent](https://wiki.facepunch.com/gmod/Entity:GetParent).
---
---@return garrysmod.Vector position The position of the entity.
function Entity:GetPos() end

--- [SHARED]
---
--- Returns the pose parameter value
---
--- > WARNING: (return value) This value will be from 0 - 1 on the client and from minimum range to maximum range on the server! You'll have to [remap](https://wiki.facepunch.com/gmod/math.Remap) this value clientside to [Entity:GetPoseParameterRange](https://wiki.facepunch.com/gmod/Entity:GetPoseParameterRange)'s returns if you want get the actual pose parameter value. See [Entity:SetPoseParameter](https://wiki.facepunch.com/gmod/Entity:SetPoseParameter)'s example.
---
---@param name string Pose parameter name to look up. Can also be a pose parameter ID.
---@return number value Value of given pose parameter.
function Entity:GetPoseParameter( name ) end

--- [SHARED]
---
--- Returns name of given pose parameter
---
---@param id integer Id of the pose paremeter
---@return string name Name of given pose parameter
function Entity:GetPoseParameterName( id ) end

--- [SHARED]
---
--- Returns pose parameter range
---
---@param id integer Pose parameter ID to look up. Can also be a pose parameter name.
---@return number min The minimum value
---@return number max The maximum value
function Entity:GetPoseParameterRange( id ) end

--- [CLIENT]
---
--- Returns whether this entity is predictable or not.
---
--- See [Entity:SetPredictable](https://wiki.facepunch.com/gmod/Entity:SetPredictable) for more information
---
---@return boolean predictable Whether this entity is predictable or not.
function Entity:GetPredictable() end

--- [SHARED]
---
--- Returns the entity which the ragdoll came from. The opposite of [Player:GetRagdollEntity](https://wiki.facepunch.com/gmod/Player:GetRagdollEntity).
---
---@return garrysmod.Entity ragdoll_owner The entity who owns the ragdoll.
function Entity:GetRagdollOwner() end

--- [CLIENT]
---
--- Returns render bounds of the entity as local vectors. Can be overridden by [Entity:SetRenderBounds](https://wiki.facepunch.com/gmod/Entity:SetRenderBounds).
---
--- If the render bounds are not inside players view, the entity will not be drawn!
---
---@return garrysmod.Vector mins The minimum vector of the bounds
---@return garrysmod.Vector maxs The maximum vector of the bounds.
function Entity:GetRenderBounds() end

--- [SHARED]
---
--- Returns current render FX of the entity.
---
---@return integer render_fx The current render FX of the entity. See [Enums/kRenderFx](https://wiki.facepunch.com/gmod/Enums/kRenderFx)
function Entity:GetRenderFX() end

--- [CLIENT]
---
--- Returns the render group of the entity.
---
---@return integer render_group The render group. See [Enums/RENDERGROUP](https://wiki.facepunch.com/gmod/Enums/RENDERGROUP)
function Entity:GetRenderGroup() end

--- [SHARED]
---
--- Returns the render mode of the entity.
---
---@return integer render_mode The render Mode. See [Enums/RENDERMODE](https://wiki.facepunch.com/gmod/Enums/RENDERMODE)
function Entity:GetRenderMode() end

--- [SHARED]
---
--- Returns the rightward vector of the entity, as a normalized direction vector
---
---@return garrysmod.Vector direction The right direction vector.
function Entity:GetRight() end

--- [SHARED]
---
--- Returns axis-aligned bounding box (AABB) of a orientated bounding box (OBB) based on entity's rotation.
---
---@param min garrysmod.Vector Minimum extent of an OBB in local coordinates.
---@param max garrysmod.Vector Maximum extent of an OBB in local coordinates.
---@return garrysmod.Vector mins Minimum extent of the AABB relative to entity's position.
---@return garrysmod.Vector maxs Maximum extent of the AABB relative to entity's position.
function Entity:GetRotatedAABB( min, max ) end

--- [SHARED]
---
--- Returns a table of save values for an entity.
---
--- These tables are not the same between the client and the server, and different entities may have different fields.
---
--- > NOTE: It is highly recommended to use [Entity:GetInternalVariable](https://wiki.facepunch.com/gmod/Entity:GetInternalVariable) for retrieving a single key of the save table for performance reasons.
---
--- You can get the list different fields an entity has by looking at it's source code (the 2013 SDK can be found [online](https://github.com/ValveSoftware/source-sdk-2013)). Accessible fields are defined by each `DEFINE_FIELD` and `DEFINE_KEYFIELD` inside the `DATADESC` block.
---
--- Take the headcrab, for example:
---
--- ```
--- BEGIN_DATADESC( CBaseHeadcrab )
--- // m_nGibCount - don't save
--- DEFINE_FIELD( m_bHidden, FIELD_BOOLEAN ),
--- DEFINE_FIELD( m_flTimeDrown, FIELD_TIME ),
--- DEFINE_FIELD( m_bCommittedToJump, FIELD_BOOLEAN ),
--- DEFINE_FIELD( m_vecCommittedJumpPos, FIELD_POSITION_VECTOR ),
--- DEFINE_FIELD( m_flNextNPCThink, FIELD_TIME ),
--- DEFINE_FIELD( m_flIgnoreWorldCollisionTime, FIELD_TIME ),
---
--- DEFINE_KEYFIELD( m_bStartBurrowed, FIELD_BOOLEAN, "startburrowed" ),
--- DEFINE_FIELD( m_bBurrowed, FIELD_BOOLEAN ),
--- DEFINE_FIELD( m_flBurrowTime, FIELD_TIME ),
--- DEFINE_FIELD( m_nContext, FIELD_INTEGER ),
--- DEFINE_FIELD( m_bCrawlFromCanister, FIELD_BOOLEAN ),
--- DEFINE_FIELD( m_bMidJump, FIELD_BOOLEAN ),
--- DEFINE_FIELD( m_nJumpFromCanisterDir, FIELD_INTEGER ),
--- DEFINE_FIELD( m_bHangingFromCeiling, FIELD_BOOLEAN ),
--- DEFINE_FIELD( m_flIlluminatedTime, FIELD_TIME ),
---
--- DEFINE_INPUTFUNC( FIELD_VOID, "Burrow", InputBurrow ),
--- DEFINE_INPUTFUNC( FIELD_VOID, "BurrowImmediate", InputBurrowImmediate ),
--- DEFINE_INPUTFUNC( FIELD_VOID, "Unburrow", InputUnburrow ),
--- DEFINE_INPUTFUNC( FIELD_VOID, "StartHangingFromCeiling", InputStartHangingFromCeiling ),
--- DEFINE_INPUTFUNC( FIELD_VOID, "DropFromCeiling", InputDropFromCeiling ),
---
--- // Function Pointers
--- DEFINE_THINKFUNC( EliminateRollAndPitch ),
--- DEFINE_THINKFUNC( ThrowThink ),
--- DEFINE_ENTITYFUNC( LeapTouch ),
--- END_DATADESC()
--- ```
---
--- * For each **DEFINE_FIELD**, the save table will have a key with name of **first** argument.
--- * For each **DEFINE_KEYFIELD**, the save table will have a key with name of the **third** argument.
---
---@param show_all boolean? If set, shows all variables, not just the ones marked for save/load system. Defaults to `false`.
---@return table save_table A table containing all save values in key/value format. The value may be a sequential table (starting with **1**) if the field in question is an array in engine.
function Entity:GetSaveTable( show_all ) end

--- [SHARED]
---
--- Return the index of the model sequence that is currently active for the entity.
---
---@return integer sequence The index of the model sequence.
function Entity:GetSequence() end

--- [SHARED]
---
--- Return activity id out of sequence id. Opposite of [Entity:SelectWeightedSequence](https://wiki.facepunch.com/gmod/Entity:SelectWeightedSequence).
---
---@param seq integer The sequence ID
---@return integer activity The activity ID, ie [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT)
function Entity:GetSequenceActivity( seq ) end

--- [SHARED]
---
--- Returns the activity name for the given sequence id.
---
---@param sequence_id integer The sequence id.
---@return string activity_name The [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT) as a string, returns "Not Found!" with an invalid sequence and "No model!" when no model is set.
function Entity:GetSequenceActivityName( sequence_id ) end

--- [SHARED]
---
--- Returns the amount of sequences ( animations ) the entity's model has.
---
---@return integer count The amount of sequences ( animations ) the entity's model has.
function Entity:GetSequenceCount() end

--- [SHARED]
---
--- Returns the ground speed of the entity's sequence.
---
---@param sequence_id integer The sequence ID.
---@return number speed The ground speed of this sequence.
function Entity:GetSequenceGroundSpeed( sequence_id ) end

--- [SHARED]
---
--- Returns a table of information about an entity's sequence.
---
---@param sequence_id integer The sequence id of the entity.
---@return table | nil info Table of information about the entity's sequence, or `nil` is ID is out of range. See [Structures/SequenceInfo](https://wiki.facepunch.com/gmod/Structures/SequenceInfo).
function Entity:GetSequenceInfo( sequence_id ) end

--- [SHARED]
---
--- Returns a list of all sequences ( animations ) the model has.
---
---@return table<integer, string> sequences The list of all sequences ( animations ) the model has. The indices start with 0!
function Entity:GetSequenceList() end

--- [SHARED]
---
--- Returns an entity's sequence move distance (the change in position over the course of the entire sequence).
---
--- See [Entity:GetSequenceMovement](https://wiki.facepunch.com/gmod/Entity:GetSequenceMovement) for a similar function with more options.
---
---@param sequence_id integer The sequence index.
---@return number distance The move distance of the sequence.
function Entity:GetSequenceMoveDist( sequence_id ) end

--- [SHARED]
---
--- Returns the delta movement and angles of a sequence of the entity's model.
---
---@param sequence_id integer The sequence index. See [Entity:LookupSequence](https://wiki.facepunch.com/gmod/Entity:LookupSequence).
---@param start_cycle number? The sequence start cycle. 0 is the start of the animation, 1 is the end. Defaults to `0`.
---@param end_cycle number? The sequence end cycle. 0 is the start of the animation, 1 is the end. Values like 2, etc are allowed. Defaults to `1`.
---@return boolean success Whether the operation was successful
---@return garrysmod.Vector delta_position The delta vector of the animation, how much the model's origin point moved.
---@return garrysmod.Angle delta_angles The delta angle of the animation.
function Entity:GetSequenceMovement( sequence_id, start_cycle, end_cycle ) end

--- [SERVER]
---
--- Returns the change in heading direction in between the start and the end of the sequence.
---
---@param seq integer The sequence index. See [Entity:LookupSequence](https://wiki.facepunch.com/gmod/Entity:LookupSequence).
---@return number yaw The yaw delta. Returns 99999 for no movement.
function Entity:GetSequenceMoveYaw( seq ) end

--- [SHARED]
---
--- Return the name of the sequence for the index provided.
--- Refer to [Entity:GetSequence](https://wiki.facepunch.com/gmod/Entity:GetSequence) to find the current active sequence on this entity.
---
--- See [Entity:LookupSequence](https://wiki.facepunch.com/gmod/Entity:LookupSequence) for a function that does the opposite.
---
---@param index integer The index of the sequence to look up.
---@return string name Name of the sequence, `"Unknown"` if it was out of bounds or `"Not Found!"` if -1 is provided.
function Entity:GetSequenceName( index ) end

--- [SHARED]
---
--- Returns an entity's sequence velocity at given animation frame.
---
---@param sequence_id integer The sequence index.
---@param cycle number The point in animation, from `0` to `1`.
---@return garrysmod.Vector velocity Velocity of the sequence at given point in the animation.
function Entity:GetSequenceVelocity( sequence_id, cycle ) end

--- [SHARED]
---
--- Returns if entity should create a server ragdoll on death or a client one.
---
---@return boolean should_server_ragdoll Returns true if ragdoll will be created on server, false if on client
function Entity:GetShouldServerRagdoll() end

--- [SHARED]
---
--- Returns the skin index of the current skin. Can be manipulated via [Entity:SetSkin](https://wiki.facepunch.com/gmod/Entity:SetSkin).
---
---@return integer skin Current skin index.
function Entity:GetSkin() end

--- [SHARED]
---
--- Returns solid type of an entity.
---
---@return integer solid The solid type. See the [Enums/SOLID](https://wiki.facepunch.com/gmod/Enums/SOLID).
function Entity:GetSolid() end

--- [SHARED]
---
--- Returns solid flag(s) of an entity.
---
---@return integer solid_flags The flag(s) of the entity, see [Enums/FSOLID](https://wiki.facepunch.com/gmod/Enums/FSOLID).
function Entity:GetSolidFlags() end

--- [SHARED]
---
--- Returns if we should show a spawn effect on spawn on this entity.
---
---@return boolean spawn_effect The flag to allow or disallow the spawn effect.
function Entity:GetSpawnEffect() end

--- [SHARED]
---
--- Returns the bitwise spawn flags used by the entity. These can be set by [Entity:SetKeyValue](https://wiki.facepunch.com/gmod/Entity:SetKeyValue).
---
---@return integer spawn_flags The spawn flags of the entity, see [SF_Enums](https://wiki.facepunch.com/gmod/Enums/SF).
function Entity:GetSpawnFlags() end

--- [SHARED]
---
--- Returns the material override for the given index.
---
--- Returns "" if no material override exists. Use [Entity:GetMaterials](https://wiki.facepunch.com/gmod/Entity:GetMaterials) to list it's default materials.
---
--- > BUG: The server's value takes priority on the client.
--- > See [issue #3362](https://github.com/Facepunch/garrysmod-issues/issues/3362).
---
---@param index integer The index of the sub material. Acceptable values are from 0 to 31.
---@return string material The material that overrides this index, if any.
function Entity:GetSubMaterial( index ) end

--- [SHARED]
---
--- Returns a list of models included into the entity's model in the .qc file.
---
---@return table[] sub_models The list of models included into the entity's model in the .qc file.
function Entity:GetSubModels() end

--- [SHARED]
---
--- Returns two vectors representing the minimum and maximum extent of the entity's axis-aligned bounding box for hitbox detection. In most cases, this will return the same bounding box as [Entity:WorldSpaceAABB](https://wiki.facepunch.com/gmod/Entity:WorldSpaceAABB) unless it was changed by [Entity:SetSurroundingBounds](https://wiki.facepunch.com/gmod/Entity:SetSurroundingBounds) or [Entity:SetSurroundingBoundsType](https://wiki.facepunch.com/gmod/Entity:SetSurroundingBoundsType).
---
---@return garrysmod.Vector mins The minimum vector for the entity's bounding box in world space.
---@return garrysmod.Vector maxs The maximum vector for the entity's bounding box in world space.
function Entity:GetSurroundingBounds() end

--- [SHARED]
---
--- Returns a [table](https://wiki.facepunch.com/gmod/table) that contains all lua-based key-value pairs saved on the [Entity](https://wiki.facepunch.com/gmod/Entity).
---
--- For retrieving engine-based key-value pairs, see [Entity:GetSaveTable](https://wiki.facepunch.com/gmod/Entity:GetSaveTable)
---
---@return table data A table of the lua data stored on the Entity, or `nil` if the Entity is NULL.
function Entity:GetTable() end

--- [SHARED]
---
--- Returns the last trace used in the collision callbacks such as [ENTITY:StartTouch](https://wiki.facepunch.com/gmod/ENTITY:StartTouch), [ENTITY:Touch](https://wiki.facepunch.com/gmod/ENTITY:Touch) and [ENTITY:EndTouch](https://wiki.facepunch.com/gmod/ENTITY:EndTouch).
---
--- > NOTE: This returns the last collision trace used, regardless of the entity that caused it. As such, it's only reliable when used in the hooks mentioned above
---
---@return garrysmod.Trace.output trace The [Structures/TraceResult](https://wiki.facepunch.com/gmod/Structures/TraceResult)
function Entity:GetTouchTrace() end

--- [SHARED]
---
--- Returns true if the TransmitWithParent flag is set or not.
---
---@return boolean transmit_with_parent Is the TransmitWithParent flag is set or not
function Entity:GetTransmitWithParent() end

--- [SHARED]
---
--- Returns the upward vector of the entity, as a normalized direction vector
---
---@return garrysmod.Vector direction The up direction vector.
function Entity:GetUp() end

--- [SHARED]
---
--- Returns the entity's velocity.
---
--- This returns the total velocity of the entity and is equal to local velocity + base velocity.
---
--- Clientside the velocity may be estimated for certain entities, such as physics based entities, instead of returning the "real" velocity from the server.
---
--- > BUG: This can become out-of-sync on the client if the server has been up for a long time.
--- > See [issue #774](https://github.com/Facepunch/garrysmod-issues/issues/774).
---
---@return garrysmod.Vector velocity The velocity of the entity.
function Entity:GetVelocity() end

--- [SERVER]
---
--- Returns ID of workshop addon that the entity is from.
---
---@deprecated The function **currently** does nothing and always returns nil
---@return integer workshop_id The workshop ID
function Entity:GetWorkshopID() end

--- [SHARED]
---
--- Returns the position and angle of the entity as a 3x4 matrix ([VMatrix](https://wiki.facepunch.com/gmod/VMatrix) is 4x4 so the fourth row goes unused). The first three columns store the angle as a [rotation matrix](https://en.wikipedia.org/wiki/Rotation_matrix), and the fourth column stores the position vector.
---
--- > BUG: This returns incorrect results for the angular component (columns 1-3) for the local player clientside.
--- > See [issue #2764](https://github.com/Facepunch/garrysmod-issues/issues/2764).
---
--- > BUG: This will use the local player's [Global.EyeAngles](https://wiki.facepunch.com/gmod/Global.EyeAngles) in [rendering hooks](https://wiki.facepunch.com/gmod/3D_Rendering_Hooks).
--- > See [issue #3106](https://github.com/Facepunch/garrysmod-issues/issues/3106).
---
--- > BUG: Columns 1-3 will be all 0 (angular component) in [rendering hooks](https://wiki.facepunch.com/gmod/3D_Rendering_Hooks) while paused in single-player.
--- > See [issue #3107](https://github.com/Facepunch/garrysmod-issues/issues/3107).
---
---@return garrysmod.VMatrix matrix The position and angle matrix.
function Entity:GetWorldTransformMatrix() end

--- [SHARED]
---
--- Causes the entity to break into its current models gibs, if it has any.
---
--- You must call [Entity:PrecacheGibs](https://wiki.facepunch.com/gmod/Entity:PrecacheGibs) on the entity before using this function, or it will not create any gibs.
---
--- If called on server, the gibs will be spawned on the currently connected clients and will not be synchronized. Otherwise the gibs will be spawned only for the client the function is called on.
---
--- > NOTE: this function will not remove or hide the entity it is called on.
--- > For more expensive version of this function see [Entity:GibBreakServer](https://wiki.facepunch.com/gmod/Entity:GibBreakServer).
---
---@param force garrysmod.Vector The force to apply to the created gibs.
---@param color garrysmod.Color? If set, this will be color of the broken gibs instead of the entity's color.
function Entity:GibBreakClient( force, color ) end

--- [SHARED]
---
--- Causes the entity to break into its current models gibs, if it has any.
---
--- You must call [Entity:PrecacheGibs](https://wiki.facepunch.com/gmod/Entity:PrecacheGibs) on the entity before using this function, or it will not create any gibs.
---
--- The gibs will be spawned on the server and be synchronized with all clients.
---
--- Note, that this function will not remove or hide the entity it is called on.
---
--- This function is affected by `props_break_max_pieces_perframe`, `props_break_max_pieces`, `prop_active_gib_limit` and `prop_active_gib_max_fade_time` console variables.
---
--- > WARNING: Large numbers of serverside gibs will cause lag.
--- >
--- > You can avoid this cost by spawning the gibs on the client using [Entity:GibBreakClient](https://wiki.facepunch.com/gmod/Entity:GibBreakClient)
---
--- > NOTE: Despite existing on client, it doesn't actually do anything on client.
---
---@param force garrysmod.Vector The force to apply to the created gibs
function Entity:GibBreakServer( force ) end

--- [SHARED]
---
--- Returns whether or not the bone manipulation functions have ever been called on given  entity.
---
--- Related functions are [Entity:ManipulateBonePosition](https://wiki.facepunch.com/gmod/Entity:ManipulateBonePosition), [Entity:ManipulateBoneAngles](https://wiki.facepunch.com/gmod/Entity:ManipulateBoneAngles), [Entity:ManipulateBoneJiggle](https://wiki.facepunch.com/gmod/Entity:ManipulateBoneJiggle), and [Entity:ManipulateBoneScale](https://wiki.facepunch.com/gmod/Entity:ManipulateBoneScale).
---
--- > BUG: This will return true if the entity's bones have ever been manipulated. Resetting the position/angles/jiggle/scaling to 0,0,0 will not affect this function.
--- > See [issue #3131](https://github.com/Facepunch/garrysmod-issues/issues/3131).
---
---@return boolean has_bone_manipulations True if the entity has been bone manipulated, false otherwise.
function Entity:HasBoneManipulations() end

--- [SHARED]
---
--- Returns whether or not the the entity has had flex manipulations performed with [Entity:SetFlexWeight](https://wiki.facepunch.com/gmod/Entity:SetFlexWeight) or [Entity:SetFlexScale](https://wiki.facepunch.com/gmod/Entity:SetFlexScale).
---
---@return boolean has_flex_manipulations True if the entity has flex manipulations, false otherwise.
function Entity:HasFlexManipulatior() end

--- [SHARED]
---
--- Returns whether this entity has the specified spawnflags bits set.
---
---@param spawn_flags integer The spawnflag bits to check, see [Enums/SF](https://wiki.facepunch.com/gmod/Enums/SF).
---@return boolean has_spawn_flags Whether the entity has that spawnflag set or not.
function Entity:HasSpawnFlags( spawn_flags ) end

--- [SERVER]
---
--- Returns the position of the head of this entity, NPCs use this internally to aim at their targets.
---
--- > NOTE: This only works on players and NPCs.
---
---@param origin garrysmod.Vector The vector of where the attack comes from.
---@return garrysmod.Vector position The head position.
function Entity:HeadTarget( origin ) end

--- [SHARED]
---
--- Returns the health of the entity.
---
---@return integer health The current health.
function Entity:Health() end

--- [SERVER]
---
--- Sets the entity on fire.
---
--- See also [Entity:Extinguish](https://wiki.facepunch.com/gmod/Entity:Extinguish).
---
---@param length number How long to keep the entity ignited, in seconds.
---@param radius number? The radius of the ignition, will ignite everything around the entity that is in this radius. Defaults to `0`.
function Entity:Ignite( length, radius ) end

--- [CLIENT]
---
--- Initializes this entity as being clientside only.
---
--- Only works on entities fully created clientside, and as such it currently has no use due to this being automatically called by [ents.CreateClientProp](https://wiki.facepunch.com/gmod/ents.CreateClientProp), [ents.CreateClientside](https://wiki.facepunch.com/gmod/ents.CreateClientside), [Global.ClientsideModel](https://wiki.facepunch.com/gmod/Global.ClientsideModel) and [Global.ClientsideScene](https://wiki.facepunch.com/gmod/Global.ClientsideScene).
---
---@deprecated This function got disabled and will always throw an error if it's used. This is the error: ``` [ERROR] InitializeAsClientEntity is deprecated and should no longer be used. ```
function Entity:InitializeAsClientEntity() end

--- [SERVER]
---
--- Fires input to the entity with the ability to make another entity responsible, bypassing the event queue system.
---
--- You should only use this function over [Entity:Fire](https://wiki.facepunch.com/gmod/Entity:Fire) if you know what you are doing.
---
--- See [Entity:Fire](https://wiki.facepunch.com/gmod/Entity:Fire) for a function that conforms to the internal map IO event queue and [GM:AcceptInput](https://wiki.facepunch.com/gmod/GM:AcceptInput) for a hook that can intercept inputs.
---
---@param input string The name of the input to fire
---@param activator garrysmod.Entity? The entity that caused this input (i.e. the player who pushed a button)
---@param caller garrysmod.Entity? The entity that is triggering this input (i.e. the button that was pushed)
---@param param string | number | boolean | nil The value to give to the input. Can be either a [string](https://wiki.facepunch.com/gmod/string), a [number](https://wiki.facepunch.com/gmod/number) or a [boolean](https://wiki.facepunch.com/gmod/boolean).
function Entity:Input( input, activator, caller, param ) end

--- [CLIENT]
---
--- Resets the entity's bone cache values in order to prepare for a model change.
---
--- This should be called after calling [Entity:SetPoseParameter](https://wiki.facepunch.com/gmod/Entity:SetPoseParameter).
---
function Entity:InvalidateBoneCache() end

--- [SERVER]
---
--- Returns if entity is constraint or not.
---
--- This also means that [Entity:GetConstrainedPhysObjects](https://wiki.facepunch.com/gmod/Entity:GetConstrainedPhysObjects). [Entity:GetConstrainedEntities](https://wiki.facepunch.com/gmod/Entity:GetConstrainedEntities) and  [Entity:SetPhysConstraintObjects](https://wiki.facepunch.com/gmod/Entity:SetPhysConstraintObjects) can be used on this entity.
---
--- > WARNING: For some constraint entities, such as `phys_spring`, `phys_slideconstraint`, `phys_torque` and `logic_collision_pair`, this function will return `false`!
---
---@return boolean is_constraint Is the entity a constraint or not
function Entity:IsConstraint() end

--- [SHARED]
---
--- Returns whether the entity is dormant or not.
---
--- Networked entities become dormant clientside when they leave the [PVS (Potential Visibility Set)](https://developer.valvesoftware.com/wiki/PVS "PVS - Valve Developer Community"). This typically means they are no longer visible by the local player, and will not receive updates from the server.
---
--- Server side, entities can only be dormant during level transitions by default.
---
---@return boolean is_dormant Whether the entity is dormant or not.
function Entity:IsDormant() end

--- [SHARED]
---
--- Returns whether an entity has engine effect applied or not.
---
---@param effect integer The effect to check for, see [Enums/EF](https://wiki.facepunch.com/gmod/Enums/EF).
---@return boolean is_effect_active Whether the entity has the engine effect applied or not.
function Entity:IsEffectActive( effect ) end

--- [SHARED]
---
--- Checks if given flag is set or not.
---
---@param flag integer The engine flag to test, see [Enums/EFL](https://wiki.facepunch.com/gmod/Enums/EFL)
---@return boolean is_set Is set or not
function Entity:IsEFlagSet( flag ) end

--- [SHARED]
---
--- Checks if given flag(s) is set or not.
---
---@param flag integer The engine flag(s) to test, see [Enums/FL](https://wiki.facepunch.com/gmod/Enums/FL)
---@return boolean is_set Is set or not
function Entity:IsFlagSet( flag ) end

--- [SERVER]
---
--- Returns whether the entity is in the world (not inside a wall or outside of the map).
---
--- > NOTE: Internally this function uses [util.IsInWorld](https://wiki.facepunch.com/gmod/util.IsInWorld), that means that this function only checks [Entity:GetPos](https://wiki.facepunch.com/gmod/Entity:GetPos) of the entity. If an entity is only partially inside a wall, or has a weird GetPos offset, this function may not give reliable output.
---
---@return boolean is_in_world False if the entity is inside a wall or outside of the map, true otherwise.
function Entity:IsInWorld() end

--- [SERVER]
---
--- Returns whether the entity is lag compensated or not.
---
---@return boolean is_lag_compensated Whether the entity is lag compensated or not.
function Entity:IsLagCompensated() end

--- [SHARED]
---
--- Returns true if the target is in line of sight.
---
--- > NOTE: This will only work when called on CBaseCombatCharacter entities. This includes players, NPCs, grenades, RPG rockets, crossbow bolts, and physics cannisters.
---
---@param target garrysmod.Vector The target to test. You can also supply an [Entity](https://wiki.facepunch.com/gmod/Entity) instead of a [Vector](https://wiki.facepunch.com/gmod/Vector)
---@return boolean is_line_of_sight_clear Returns true if the line of sight is clear
function Entity:IsLineOfSightClear( target ) end

--- [SHARED]
---
--- Determines if a given Entity is going to be removed at the start of the next tick.
---
--- This will return `true` for an [Entity](https://wiki.facepunch.com/gmod/Entity) after [Entity:Remove](https://wiki.facepunch.com/gmod/Entity:Remove) is called on it.
---
---@return boolean is_marked_for_deletion `true` if the Entity is going to be removed, `false` otherwise.
function Entity:IsMarkedForDeletion() end

--- [SHARED]
---
--- Checks if the entity is a [NextBot](https://wiki.facepunch.com/gmod/NextBot) or not.
---
---@return boolean is_next_bot Whether the entity is an NextBot entity or not.
function Entity:IsNextBot() end

--- [SHARED]
---
--- Checks if the entity is an [NPC](https://wiki.facepunch.com/gmod/NPC) or not.
---
--- This will return false for [NextBot](https://wiki.facepunch.com/gmod/NextBot)s, see [Entity:IsNextBot](https://wiki.facepunch.com/gmod/Entity:IsNextBot) for that.
---
---@return boolean is_npc Whether the entity is an NPC.
function Entity:IsNPC() end

--- [SHARED]
---
--- Returns whether the entity is on fire.
---
---@return boolean is_on_fire Whether the entity is on fire or not.
function Entity:IsOnFire() end

--- [SHARED]
---
--- Returns whether the entity is on ground or not.
---
--- Internally, this checks if [FL_ONGROUND](https://wiki.facepunch.com/gmod/Enums/FL) is set on the entity.
---
--- This function is an alias of [Entity:OnGround](https://wiki.facepunch.com/gmod/Entity:OnGround).
---
---@return boolean is_on_ground Whether the entity is on ground or not.
function Entity:IsOnGround() end

--- [SHARED]
---
--- Checks if the entity is a player or not.
---
---@return boolean is_player Whether the entity is a player.
function Entity:IsPlayer() end

--- [SERVER]
---
--- Returns true if the entity is being held by a player. Either by physics gun, gravity gun or use-key (+use).
---
--- > BUG: If multiple players are holding an object and one drops it, this will return false despite the object still being held.
--- > See [issue #2046](https://github.com/Facepunch/garrysmod-issues/issues/2046).
---
---@return boolean is_held `true` if a player is holding the entity.
function Entity:IsPlayerHolding() end

--- [SERVER]
---
--- Returns whether there's a gesture with the given activity being played.
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entites!
---
---@param activity integer The activity to test. See [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
---@return boolean is_playing_gesture Whether there's a gesture is given activity being played.
function Entity:IsPlayingGesture( activity ) end

--- [SHARED]
---
--- Returns whether a given point is within the entity's Orientated Bounding Box.
---
--- This relies on the entity having a collision mesh (not a physics object) and will be affected by `SOLID_NONE`.
---
---@param point garrysmod.Vector The point to test, in world space coordinates.
---@return boolean is_point_in_bounds Whether the point is within the entity's bounds.
function Entity:IsPointInBounds( point ) end

--- [SHARED]
---
--- Checks if the entity is a ragdoll, or became a ragdoll. Internally checks whether [kRenderFXRagdoll](kRenderFX) is set.
---
---@return boolean is_ragdoll Is ragdoll or not
function Entity:IsRagdoll() end

--- [SHARED]
---
--- Checks if the entity is a SENT or a built-in entity.
---
---@return boolean is_scripted Returns true if entity is scripted ( SENT ), false if not ( A built-in engine entity )
function Entity:IsScripted() end

--- [SHARED]
---
--- Returns whether the entity's current sequence is finished or not.
---
---@return boolean is_sequence_finished Whether the entity's sequence is finished or not.
function Entity:IsSequenceFinished() end

--- [SHARED]
---
--- Returns if the entity is solid or not.
--- Very useful for determining if the entity is a trigger or not.
---
---@return boolean is_solid Whether the entity is solid or not.
function Entity:IsSolid() end

--- [SHARED]
---
--- Returns whether the entity is a valid entity or not.
---
--- An entity is valid if:
--- * It is not a [NULL](https://wiki.facepunch.com/gmod/Global_Variables) entity
--- * It is not the worldspawn entity ([game.GetWorld](https://wiki.facepunch.com/gmod/game.GetWorld))
---
--- > NOTE: Instead of calling this method directly, it's a good idea to call the global [Global.IsValid](https://wiki.facepunch.com/gmod/Global.IsValid) instead, however if you're sure the variable you're using is always an entity object it's better to use this method
---
--- It will check whether the given variable contains an object (an Entity) or nothing at all for you. See examples.
---
--- > WARNING: NULL entities can still be assigned with key/value pairs, but they will be instantly negated. See example 3
---
--- This might be a cause for a lot of headache. Usually happening during networking etc., when completely valid entities suddenly become invalid on the client, but are never filtered with IsValid(). See [GM:InitPostEntity](https://wiki.facepunch.com/gmod/GM:InitPostEntity) for more details.
---
---@return boolean is_valid true if the entity is valid, false otherwise
function Entity:IsValid() end

--- [SHARED]
---
--- Returns whether the given layer ID is valid and exists on this entity.
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entities.
---
---@param layer_id integer The Layer ID
---@return boolean is_valid_layer Whether the given layer ID is valid and exists on this entity.
function Entity:IsValidLayer( layer_id ) end

--- [SHARED]
---
--- Checks if the entity is a vehicle or not.
---
---@return boolean is_vehicle Whether the entity is a vehicle.
function Entity:IsVehicle() end

--- [SHARED]
---
--- Checks if the entity is a weapon or not.
---
---@return boolean is_weapon Whether the entity is a weapon
function Entity:IsWeapon() end

--- [SHARED]
---
--- Returns if this entity is the map entity `Entity[0] worldspawn`.
---
---@return boolean is_world Whether this entity is the world entity.
function Entity:IsWorld() end

--- [SHARED]
---
--- Translates a vector relative to the entity's coordinate system into a worldspace vector.
---
---@param local_position garrysmod.Vector A local space vector.
---@return garrysmod.Vector world_position The corresponding worldspace vector.
function Entity:LocalToWorld( local_position ) end

--- [SHARED]
---
--- Translates an angle relative to the entity's coordinate system to a worldspace angle.
---
---@param local_angles garrysmod.Angle A local space angle.
---@return garrysmod.Angle world_angles The corresponding worldspace angle.
function Entity:LocalToWorldAngles( local_angles ) end

--- [SHARED]
---
--- Returns the attachment index of the given attachment name.
---
---@param attachment_name string The name of the attachment.
---@return integer attachment_id The attachment index, or 0 if the attachment does not exist and -1 if the model is invalid.
function Entity:LookupAttachment( attachment_name ) end

--- [SHARED]
---
--- Gets the bone index of the given bone name, returns `nil` if the bone does not exist.
---
--- > NOTE: When called on [Weapon](https://wiki.facepunch.com/gmod/Weapon)s equipped by any Player, this will return their viewmodel's bone index instead of worldmodel.
---
--- See [Entity:GetBoneName](https://wiki.facepunch.com/gmod/Entity:GetBoneName) for the inverse of this function.
---
---@param bone_name string The name of the bone. Common generic bones ( for player models and some HL2 models ): * ValveBiped.Bip01_Head1 * ValveBiped.Bip01_Spine * ValveBiped.Anim_Attachment_RH Common hand bones (left hand equivalents also available, replace _R_ with _L_) * ValveBiped.Bip01_R_Hand * ValveBiped.Bip01_R_Forearm * ValveBiped.Bip01_R_Foot * ValveBiped.Bip01_R_Thigh * ValveBiped.Bip01_R_Calf * ValveBiped.Bip01_R_Shoulder * ValveBiped.Bip01_R_Elbow
---@return integer | nil bone_id Index of the given bone name, or `nil` if the bone doesn't exist on the Entity.
function Entity:LookupBone( bone_name ) end

--- [SHARED]
---
--- Returns pose parameter ID from its name.
---
---@param name string Pose parameter name
---@return integer pose_parameter_id The ID of the given pose parameter name, if it exists, -1 otherwise
function Entity:LookupPoseParameter( name ) end

--- [SHARED]
---
--- Returns sequence ID from either sequence name or activity name. See [Entity:GetSequenceName](https://wiki.facepunch.com/gmod/Entity:GetSequenceName) for a function that does the opposite.
---
--- **Sequences** are animations tied to a specific model. Different models can have sequences with same names, but have different IDs.
--- Sequences can also be tied to certain activities ([Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT)), see [Entity:SelectWeightedSequence](https://wiki.facepunch.com/gmod/Entity:SelectWeightedSequence).
---
---@param name string Sequence name. Input string can alternatively be an activity name, to lookup an activity from its name and get a sequence as result.
---@return integer sequence_id Sequence ID for that name. This **will** differ for models with same sequence names. Will be `-1` when the sequence is invalid or not found.
---@return number duration The sequence duration, or `0` if the sequence is invalid or there's no sequence with given name on entity's current model.
function Entity:LookupSequence( name ) end

--- [SHARED]
---
--- Turns the [Entity:GetPhysicsObject](https://wiki.facepunch.com/gmod/Entity:GetPhysicsObject) into a physics shadow.
--- It's used internally for the Player's and NPC's physics object, and certain HL2 entities such as the crane.
---
--- A physics shadow can be used to have static entities that never move by setting both arguments to false.
---
--- > NOTE: Unlike [Entity:PhysicsInitShadow](https://wiki.facepunch.com/gmod/Entity:PhysicsInitShadow), this function doesn't remove the current physics object.
---
---@param allow_physics_movement boolean? Whether to allow the physics shadow to move under stress. Defaults to `true`.
---@param allow_physics_rotation boolean? Whether to allow the physics shadow to rotate under stress. Defaults to `true`.
function Entity:MakePhysicsObjectAShadow( allow_physics_movement, allow_physics_rotation ) end

--- [SHARED]
---
--- Sets custom bone angles.
---
--- > BUG: When used repeatedly serverside, this method is strongly discouraged due to the huge network traffic produced
--- >
--- > As of update `2024.10.29` this has been resolved. However, network traffic is still generated and should be taken into consideration.
--- > See [issue #5148](https://github.com/Facepunch/garrysmod-issues/issues/5148).
---
---@param bone_id integer Index of the bone you want to manipulate
---@param angles garrysmod.Angle Angle to apply. The angle is relative to the original bone angle, not relative to the world or the entity.
---@param networking boolean? boolean to network these changes (if called from server) Defaults to `true`.
function Entity:ManipulateBoneAngles( bone_id, angles, networking ) end

--- [SHARED]
---
--- Manipulates the bone's jiggle status. This allows non jiggly bones to become jiggly.
---
---@param bone_id integer Index of the bone you want to manipulate.
---@param type integer The jiggle bone type. There are currently the following options: * `0` = No jiggle override, use model default * `1` = Force jiggle, with hardcoded settings * `2` = Force disable jiggle bone
function Entity:ManipulateBoneJiggle( bone_id, type ) end

--- [SHARED]
---
--- Sets custom bone offsets.
---
---@param bone_id integer Index of the bone you want to manipulate.
---@param position garrysmod.Vector Position vector to apply. Note that the position is relative to the original bone position, not relative to the world or the entity.
---@param networking boolean? boolean to network these changes (if called from server) Defaults to `true`.
function Entity:ManipulateBonePosition( bone_id, position, networking ) end

--- [SHARED]
---
--- Sets custom bone scale.
---
--- > BUG: This does not scale procedural bones.
--- > See [issue #3502](https://github.com/Facepunch/garrysmod-issues/issues/3502).
---
--- > NOTE: This silently fails when given a Vector with nan values, hiding the vertices associated with the bone. See example below.
---
---@param bone_id integer Index of the bone you want to manipulate
---@param scale garrysmod.Vector Scale vector to apply. Note that the scale is relative to the original bone scale, not relative to the world or the entity.
function Entity:ManipulateBoneScale( bone_id, scale ) end

--- [SHARED]
---
--- Returns entity's map creation ID. Unlike [Entity:EntIndex](https://wiki.facepunch.com/gmod/Entity:EntIndex) or [Entity:GetCreationID](https://wiki.facepunch.com/gmod/Entity:GetCreationID), it will always be the same on same map, no matter how much you clean up or restart it.
---
--- It may change if the map is recompiled, even if no edits were made. It will definitely change if entities are added or removed from the map file.
---
--- To be used in conjunction with [ents.GetMapCreatedEntity](https://wiki.facepunch.com/gmod/ents.GetMapCreatedEntity). See also [Entity:CreatedByMap](https://wiki.facepunch.com/gmod/Entity:CreatedByMap).
---
--- > NOTE: (return value) If the ID exists, it is identical to the entity's order number as it appears in Lump 1 of the BSP file. It is believed to start at 1234 for some reason.
---
---@return integer creation_id The map creation ID or -1 if the entity is not compiled into the map.
function Entity:MapCreationID() end

--- [CLIENT]
---
--- Refreshes the shadow of the entity.
---
function Entity:MarkShadowAsDirty() end

--- [SHARED]
---
--- Fires the muzzle flash effect of the weapon the entity is carrying. This only creates a light effect and is often called alongside [Weapon:SendWeaponAnim](https://wiki.facepunch.com/gmod/Weapon:SendWeaponAnim)
---
function Entity:MuzzleFlash() end

--- [SHARED]
---
--- Performs a Ray-Orientated Bounding Box intersection from the given position to the origin of the OBBox with the entity and returns the hit position on the OBBox.
---
--- This relies on the entity having a collision mesh (not a physics object) and will be affected by `SOLID_NONE`
---
---@param position garrysmod.Vector The vector to start the intersection from.
---@return garrysmod.Vector position The nearest hit point of the entity's bounding box in world coordinates.
function Entity:NearestPoint( position ) end

--- [SHARED]
---
--- Controls when, relative to [Global.CurTime](https://wiki.facepunch.com/gmod/Global.CurTime), the [Entity](https://wiki.facepunch.com/gmod/Entity) will next run its Think function.
---
--- For [Scripted Entities](https://wiki.facepunch.com/gmod/Scripted_Entities), this is the [ENTITY:Think](https://wiki.facepunch.com/gmod/ENTITY:Think) function.
--- For engine entities, this is an internal function whose behavior will depend on the specific Entity type.
---
--- For a client-side equivalent, see [Entity:SetNextClientThink](https://wiki.facepunch.com/gmod/Entity:SetNextClientThink).
---
--- > BUG: This does not work with SWEPs or Nextbots.
--- > See [issue #3269](https://github.com/Facepunch/garrysmod-issues/issues/3269).
---
---@param timestamp number The timestamp, relative to [Global.CurTime](https://wiki.facepunch.com/gmod/Global.CurTime), when the next think should occur.
function Entity:NextThink( timestamp ) end

--- [SHARED]
---
--- Returns the center of an entity's collision bounding box as a local vector.
---
--- See also [Entity:GetCollisionBounds](https://wiki.facepunch.com/gmod/Entity:GetCollisionBounds), [Entity:OBBMins](https://wiki.facepunch.com/gmod/Entity:OBBMins) and [Entity:OBBMaxs](https://wiki.facepunch.com/gmod/Entity:OBBMaxs).
---
---@return garrysmod.Vector center The center of an entity's bounding box relative to its [Entity:GetPos](https://wiki.facepunch.com/gmod/Entity:GetPos).
function Entity:OBBCenter() end

--- [SHARED]
---
--- Returns the highest corner of an entity's collision bounding box as a local vector.
---
--- See also [Entity:GetCollisionBounds](https://wiki.facepunch.com/gmod/Entity:GetCollisionBounds), [Entity:OBBMins](https://wiki.facepunch.com/gmod/Entity:OBBMins) and [Entity:OBBCenter](https://wiki.facepunch.com/gmod/Entity:OBBCenter).
---
---@return garrysmod.Vector maxs The local position of the highest corner of the entity's oriented bounding box.
function Entity:OBBMaxs() end

--- [SHARED]
---
--- Returns the lowest corner of an entity's collision bounding box as a local vector.
---
--- See also [Entity:GetCollisionBounds](https://wiki.facepunch.com/gmod/Entity:GetCollisionBounds), [Entity:OBBMaxs](https://wiki.facepunch.com/gmod/Entity:OBBMaxs) and [Entity:OBBCenter](https://wiki.facepunch.com/gmod/Entity:OBBCenter).
---
---@return garrysmod.Vector mins The local position of the lowest corner of the entity's oriented bounding box.
function Entity:OBBMins() end

--- [SHARED]
---
--- Returns the entity's capabilities as a bitfield.
---
--- In the engine this function is mostly used to check the use type, the save/restore system and level transitions flags.
---
--- Even though the function is defined shared, it is not guaranteed to return the same value across states.
---
--- > NOTE: The enums for this are not currently implemented in Lua, however you can access the defines [here](https://github.com/ValveSoftware/source-sdk-2013/blob/55ed12f8d1eb6887d348be03aee5573d44177ffb/mp/src/game/shared/baseentity_shared.h#L21-L38).
---
---@return integer caps The bitfield, a combination of the [FCAP_](https://github.com/ValveSoftware/source-sdk-2013/blob/55ed12f8d1eb6887d348be03aee5573d44177ffb/mp/src/game/shared/baseentity_shared.h#L21-L38) flags.
function Entity:ObjectCaps() end

--- [SHARED]
---
--- Returns true if the entity is on the ground, and false if it isn't.
---
--- Internally, this checks if [FL_ONGROUND](https://wiki.facepunch.com/gmod/Enums/FL) is set on the entity. This is only updated for players and NPCs, and thus won't inherently work for other entities.
---
---@return boolean is_on_ground Whether the entity is on the ground or not.
function Entity:OnGround() end

--- [SERVER]
---
--- Tests whether the damage passes the entity filter.
---
--- This will call [ENTITY:PassesDamageFilter](https://wiki.facepunch.com/gmod/ENTITY:PassesDamageFilter) on scripted entities of the type "filter".
---
--- > NOTE: This function only works on entities of the type "filter". ( filter_* entities, including base game filter entites )
---
---@param damage_info garrysmod.DamageInfo The damage info to test
---@return boolean passes Whether the damage info passes the entity filter.
function Entity:PassesDamageFilter( damage_info ) end

--- [SERVER]
---
--- Tests whether the entity passes the entity filter.
---
--- This will call [ENTITY:PassesFilter](https://wiki.facepunch.com/gmod/ENTITY:PassesFilter) on scripted entities of the type "filter".
---
--- > NOTE: This function only works on entities of the type "filter". ( filter_* entities, including base game filter entites )
---
---@param caller garrysmod.Entity The initiator of the test. For example the trigger this filter entity is used in.
---@param entity garrysmod.Entity The entity to test against the entity filter.
---@return boolean passes Whether the entity info passes the entity filter.
function Entity:PassesFilter( caller, entity ) end

--- [SHARED]
---
--- Destroys the current physics object of an entity.
---
--- > NOTE: Cannot be used on a ragdoll or the world entity.
---
--- > WARNING: This function cannot be used when called from a physics callback.
---
function Entity:PhysicsDestroy() end

--- [SHARED]
---
--- Initializes the physics mesh of the entity from a triangle soup defined by a table of vertices. The resulting mesh is hollow, may contain holes, and always has a volume of 0.
---
--- While this is very useful for static geometry such as terrain displacements, it is advised to use [Entity:PhysicsInitConvex](https://wiki.facepunch.com/gmod/Entity:PhysicsInitConvex) or [Entity:PhysicsInitMultiConvex](https://wiki.facepunch.com/gmod/Entity:PhysicsInitMultiConvex) for moving solid objects instead.
---
--- [Entity:EnableCustomCollisions](https://wiki.facepunch.com/gmod/Entity:EnableCustomCollisions) needs to be called if you want players to collide with the entity correctly.
---
---@param vertices garrysmod.Vector[] A table of Vectors. Every 3 vertices define a triangle in the physics mesh Alternatively, you can input a table consisting of [Structures/MeshVertex](https://wiki.facepunch.com/gmod/Structures/MeshVertex) (only the `pos` element is taken into account).
---@param surfaceprop string? Physical material from [surfaceproperties.txt](https://github.com/Facepunch/garrysmod/blob/master/garrysmod/scripts/surfaceproperties.txt) or added with [physenv.AddSurfaceData](https://wiki.facepunch.com/gmod/physenv.AddSurfaceData). Defaults to `default`.
---@param mass_center_override garrysmod.Vector? If set, overwrites the center of mass for the created physics object.
---@return boolean | nil success Returns `true` on success, `nil` otherwise.
function Entity:PhysicsFromMesh( vertices, surfaceprop, mass_center_override ) end

--- [SHARED]
---
--- Initializes the [physics object](https://wiki.facepunch.com/gmod/Entity:GetPhysicsObject) of the entity using its current [model](https://wiki.facepunch.com/gmod/Entity:GetModel). Deletes the previous physics object if it existed and the new object creation was successful.
---
--- If the entity's current model has no physics mesh associated to it, no physics object will be created and the previous object will still exist, if applicable.
---
--- > NOTE: When called clientside, this will not create a valid [PhysObj](https://wiki.facepunch.com/gmod/PhysObj) if the model hasn't been [precached](https://wiki.facepunch.com/gmod/util.PrecacheModel) serverside.
--- >
--- > If successful, this function will automatically call [Entity:SetSolid](https://wiki.facepunch.com/gmod/Entity:SetSolid)( solidType ) and [Entity:SetSolidFlags](https://wiki.facepunch.com/gmod/Entity:SetSolidFlags)( 0 ).
---
--- > BUG: Clientside physics objects on serverside entities do not move properly in some cases. Physics objects should only created on the server or you will experience incorrect physgun beam position, prediction issues, and other unexpected behavior.
--- >
--- > A workaround is available on the [Entity:PhysicsInitConvex](https://wiki.facepunch.com/gmod/Entity:PhysicsInitConvex) page.
--- > See [issue #5060](https://github.com/Facepunch/garrysmod-issues/issues/5060).
---
--- > NOTE: (`solid_type` argument) Using `SOLID_NONE` will only delete the current physics object - it does not create a new one.
---
---@param solid_type integer The solid type of the physics object to create, see [Enums/SOLID](https://wiki.facepunch.com/gmod/Enums/SOLID). Should be `SOLID_VPHYSICS` in most cases.
---@param mass_center_override garrysmod.Vector? If set, overwrites the center of mass for the created physics object.
---@return boolean success Returns `true` on success, `false` otherwise.
function Entity:PhysicsInit( solid_type, mass_center_override ) end

--- [SHARED]
---
--- Makes the physics object of the entity a AABB.
---
--- This function will automatically destroy any previous physics objects and do the following:
--- * [Entity:SetSolid](https://wiki.facepunch.com/gmod/Entity:SetSolid)( `SOLID_BBOX` )
--- * [Entity:SetMoveType](https://wiki.facepunch.com/gmod/Entity:SetMoveType)( `MOVETYPE_VPHYSICS` )
--- * [Entity:SetCollisionBounds](https://wiki.facepunch.com/gmod/Entity:SetCollisionBounds)( `mins`, `maxs` )
---
--- > NOTE: If the volume of the resulting box is 0 (the mins and maxs are the same), the mins and maxs will be changed to [Global.Vector](https://wiki.facepunch.com/gmod/Global.Vector)( -1, -1, -1 ) and [Global.Vector](https://wiki.facepunch.com/gmod/Global.Vector)( 1, 1, 1 ), respectively.
---
--- > BUG: Clientside physics objects on serverside entities do not move properly in some cases. Physics objects should only created on the server or you will experience incorrect physgun beam position, prediction issues, and other unexpected behavior.
--- >
--- > A workaround is available on the [Entity:PhysicsInitConvex](https://wiki.facepunch.com/gmod/Entity:PhysicsInitConvex) page.
--- > See [issue #5060](https://github.com/Facepunch/garrysmod-issues/issues/5060).
---
---@param mins garrysmod.Vector The minimum position of the box. This is automatically ordered with the maxs.
---@param maxs garrysmod.Vector The maximum position of the box. This is automatically ordered with the mins.
---@param surfaceprop string? Physical material from [surfaceproperties.txt](https://github.com/Facepunch/garrysmod/blob/master/garrysmod/scripts/surfaceproperties.txt) or added with [physenv.AddSurfaceData](https://wiki.facepunch.com/gmod/physenv.AddSurfaceData). Defaults to `default`.
---@param mass_center_override garrysmod.Vector? If set, overwrites the center of mass for the created physics object.
---@return boolean | nil success Returns `true` on success, `nil` otherwise. This fails when the game cannot create any more [PhysCollide](https://wiki.facepunch.com/gmod/PhysCollide)s.
function Entity:PhysicsInitBox( mins, maxs, surfaceprop, mass_center_override ) end

--- [SHARED]
---
--- Initializes the physics mesh of the entity with a convex mesh defined by a table of points. The resulting mesh is the  of all the input points. If successful, the previous physics object will be removed.
---
--- This is the standard way of creating moving physics objects with a custom convex shape. For more complex, concave shapes, see [Entity:PhysicsInitMultiConvex](https://wiki.facepunch.com/gmod/Entity:PhysicsInitMultiConvex).
---
--- You may be expected to call [Entity:SetSolid](https://wiki.facepunch.com/gmod/Entity:SetSolid) with desired solid type **before** calling this function.
---
--- > BUG: Clientside physics objects on serverside entities do not move properly in some cases. Physics objects should only created on the server or you will experience incorrect physgun beam position, prediction issues, and other unexpected behavior.
--- >
--- > You can use the following workaround for movement, though clientside collisions will still be broken.
--- > ```
--- > function ENT:Think()
--- > if ( CLIENT ) then
--- > local physobj = self:GetPhysicsObject()
--- >
--- > if ( IsValid( physobj ) ) then
--- > physobj:SetPos( self:GetPos() )
--- > physobj:SetAngles( self:GetAngles() )
--- > end
--- > end
--- > end
--- > ```
--- > See [issue #5060](https://github.com/Facepunch/garrysmod-issues/issues/5060).
---
---@param points garrysmod.Vector[] A table of [Vector](https://wiki.facepunch.com/gmod/Vector)s, in local coordinates, to be used in the computation of the convex mesh. Order does not matter.
---@param surfaceprop string? Physical material from [surfaceproperties.txt](https://github.com/Facepunch/garrysmod/blob/master/garrysmod/scripts/surfaceproperties.txt) or added with [physenv.AddSurfaceData](https://wiki.facepunch.com/gmod/physenv.AddSurfaceData). Defaults to `default`.
---@param mass_center_override garrysmod.Vector? If set, overwrites the center of mass for the created physics object.
---@return boolean success Returns `true` on success, `false` otherwise.
function Entity:PhysicsInitConvex( points, surfaceprop, mass_center_override ) end

--- [SHARED]
---
--- An advanced version of [Entity:PhysicsInitConvex](https://wiki.facepunch.com/gmod/Entity:PhysicsInitConvex) which initializes a physics object from multiple convex meshes. This should be used for physics objects with a custom shape which cannot be represented by a single convex mesh.
---
--- If successful, the previous physics object will be removed.
---
--- You may be expected to call [Entity:SetSolid](https://wiki.facepunch.com/gmod/Entity:SetSolid) with desired solid type **before** calling this function.
---
--- > BUG: Clientside physics objects on serverside entities do not move properly in some cases. Physics objects should only created on the server or you will experience incorrect physgun beam position, prediction issues, and other unexpected behavior.
--- >
--- > A workaround is available on the [Entity:PhysicsInitConvex](https://wiki.facepunch.com/gmod/Entity:PhysicsInitConvex) page.
--- > See [issue #5060](https://github.com/Facepunch/garrysmod-issues/issues/5060).
---
---@param vertices garrysmod.Vector[][] A table consisting of tables of [Vector](https://wiki.facepunch.com/gmod/Vector)s. Each sub-table defines a set of points to be used in the computation of one convex mesh.
---@param surfaceprop string? Physical material from [surfaceproperties.txt](https://github.com/Facepunch/garrysmod/blob/master/garrysmod/scripts/surfaceproperties.txt) or added with [physenv.AddSurfaceData](https://wiki.facepunch.com/gmod/physenv.AddSurfaceData). Defaults to `default`.
---@param mass_center_override garrysmod.Vector? If set, overwrites the center of mass for the created physics object.
---@return boolean | nil success Returns `true` on success, `nil` otherwise.
function Entity:PhysicsInitMultiConvex( vertices, surfaceprop, mass_center_override ) end

--- [SHARED]
---
--- Initializes the entity's [physics object](https://wiki.facepunch.com/gmod/PhysObj) as a *physics shadow*. Physics shadows can react to the environment physically (see the arguments to the function), and can push other physics objects around, but are ultimately constrained to the entity's position and angles: the physics object will attempt to return to the entity's coordinates every simulation tick.
---
--- Internally, this creates a new physics object, copies the properties of the current physics object to it if one exists, and replaces the entity's physics object with the shadow. This is used internally for Player and NPC physics objects, certain HL2 entities such as the crane and barnacle tongue, parented physics entities, etc.
---
--- A physics shadow can be used to have static physics entities that never move by setting both arguments to false.
---
--- The created physics object will depend on the entity's solidity `SOLID_NONE` will not create a physics object, `SOLID_BBOX` will create a Axis-Aligned BBox one, `SOLID_OBB` will create Orientated Bounding Box one, and anything else will use the models' physics mesh.
---
--- See also [Structures/ShadowControlParams](https://wiki.facepunch.com/gmod/Structures/ShadowControlParams).
---
--- > BUG: Clientside physics objects on serverside entities do not move properly in some cases. Physics objects should only created on the server or you will experience incorrect physgun beam position, prediction issues, and other unexpected behavior.
--- >
--- > A workaround is available on the [Entity:PhysicsInitConvex](https://wiki.facepunch.com/gmod/Entity:PhysicsInitConvex) page.
--- > See [issue #5060](https://github.com/Facepunch/garrysmod-issues/issues/5060).
---
---@param allow_physics_movement boolean? Whether to allow the physics shadow to move under stress. Defaults to `true`.
---@param allow_physics_rotation boolean? Whether to allow the physics shadow to rotate under stress. Defaults to `true`.
---@return boolean success Return `true` on success, `false` otherwise.
function Entity:PhysicsInitShadow( allow_physics_movement, allow_physics_rotation ) end

--- [SHARED]
---
--- Makes the physics object of the entity a sphere.
---
--- This function will automatically destroy any previous physics objects and do the following:
--- * [Entity:SetSolid](https://wiki.facepunch.com/gmod/Entity:SetSolid)( `SOLID_BBOX` )
--- * [Entity:SetMoveType](https://wiki.facepunch.com/gmod/Entity:SetMoveType)( `MOVETYPE_VPHYSICS` )
---
--- > BUG: Clientside physics objects on serverside entities do not move properly in some cases. Physics objects should only created on the server or you will experience incorrect physgun beam position, prediction issues, and other unexpected behavior.
--- >
--- > A workaround is available on the [Entity:PhysicsInitConvex](https://wiki.facepunch.com/gmod/Entity:PhysicsInitConvex) page.
--- > See [issue #5060](https://github.com/Facepunch/garrysmod-issues/issues/5060).
---
---@param radius number The radius of the sphere.
---@param surfaceprop string? Physical material from [surfaceproperties.txt](https://github.com/Facepunch/garrysmod/blob/master/garrysmod/scripts/surfaceproperties.txt) or added with [physenv.AddSurfaceData](https://wiki.facepunch.com/gmod/physenv.AddSurfaceData). Defaults to `default`.
---@return boolean success Returns `true` on success, `false` otherwise
function Entity:PhysicsInitSphere( radius, surfaceprop ) end

--- [SHARED]
---
--- Initializes a static physics object of the entity using its [current model](https://wiki.facepunch.com/gmod/Entity:GetModel). If successful, the previous physics object is removed.
---
--- This is what used by entities such as `func_breakable`, `prop_dynamic`, `item_suitcharger`, `prop_thumper` and `npc_rollermine` while it is in its "buried" state in the Half-Life 2 Campaign.
---
--- If the entity's current model has no physics mesh associated to it, no physics object will be created.
---
--- > NOTE: This function will automatically call [Entity:SetSolid](https://wiki.facepunch.com/gmod/Entity:SetSolid)( `solidType` ).
---
--- > BUG: Clientside physics objects on serverside entities do not move properly in some cases. Physics objects should only created on the server or you will experience incorrect physgun beam position, prediction issues, and other unexpected behavior.
--- >
--- > A workaround is available on the [Entity:PhysicsInitConvex](https://wiki.facepunch.com/gmod/Entity:PhysicsInitConvex) page.
--- > See [issue #5060](https://github.com/Facepunch/garrysmod-issues/issues/5060).
---
---@param solid_type integer The solid type of the physics object to create, see [Enums/SOLID](https://wiki.facepunch.com/gmod/Enums/SOLID). Should be `SOLID_VPHYSICS` in most cases.
---@return boolean success Returns `true` on success, `false` otherwise. This will fail if the entity's current model has no associated physics mesh.
function Entity:PhysicsInitStatic( solid_type ) end

--- [SERVER]
---
--- Makes the entity play a .vcd scene. [All scenes from Half-Life 2](https://developer.valvesoftware.com/wiki/Half-Life_2_Scenes_List).
---
---@param scene string Filepath to scene.
---@param delay number? Delay in seconds until the scene starts playing. Defaults to `0`.
---@return number duration Estimated length of the scene.
---@return garrysmod.Entity scene The scene entity, removing which will stop the scene from continuing to play.
function Entity:PlayScene( scene, delay ) end

--- [SERVER]
---
--- Changes an entities angles so that it faces the target entity.
---
---@param target garrysmod.Entity The entity to face.
function Entity:PointAtEntity( target ) end

--- [SERVER]
---
--- Precaches gibs for the entity's model.
---
--- Normally this function should be ran when the entity is spawned, for example the [ENTITY:Initialize](https://wiki.facepunch.com/gmod/ENTITY:Initialize), after [Entity:SetModel](https://wiki.facepunch.com/gmod/Entity:SetModel) is called.
---
--- This is required for [Entity:GibBreakServer](https://wiki.facepunch.com/gmod/Entity:GibBreakServer) and [Entity:GibBreakClient](https://wiki.facepunch.com/gmod/Entity:GibBreakClient) to work.
---
---@return integer gib_count The amount of gibs the prop has
function Entity:PrecacheGibs() end

--- [SERVER]
---
--- Normalizes the ragdoll. This is used alongside Kinect in [Entity:SetRagdollBuildFunction](https://wiki.facepunch.com/gmod/Entity:SetRagdollBuildFunction), for more info see ragdoll_motion entity.
---
function Entity:RagdollSolve() end

--- [SERVER]
---
--- Sets the function to build the ragdoll. This is used alongside Kinect in [Entity:SetRagdollBuildFunction](https://wiki.facepunch.com/gmod/Entity:SetRagdollBuildFunction), for more info see ragdoll_motion entity.
---
function Entity:RagdollStopControlling() end

--- [SERVER]
---
--- Makes the physics objects follow the set bone positions. This is used alongside Kinect in [Entity:SetRagdollBuildFunction](https://wiki.facepunch.com/gmod/Entity:SetRagdollBuildFunction), for more info see ragdoll_motion entity.
---
function Entity:RagdollUpdatePhysics() end

--- [SHARED]
---
--- Removes (or deletes) a given [Entity](https://wiki.facepunch.com/gmod/Entity).
---
--- The Entity will continue to exist until the start of the next tick.
---
--- To check if an Entity will be removed in the next tick, see [Entity:IsMarkedForDeletion](https://wiki.facepunch.com/gmod/Entity:IsMarkedForDeletion)
---
function Entity:Remove() end

--- [SHARED]
---
--- Removes all decals from all surfaces of the given entity.
---
--- If you are looking to remove specific map decals, see [util.RemoveDecalsAt](https://wiki.facepunch.com/gmod/util.RemoveDecalsAt).
---
function Entity:RemoveAllDecals() end

--- [SERVER]
---
--- Removes and stops all gestures.
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entites!
---
--- > NOTE: Layer removal procedures aren't immediate. Layer removal functions actually manipulate [Entity:GetLayerWeight](https://wiki.facepunch.com/gmod/Entity:GetLayerWeight) down to 0, then remove the layer in next intervals. If the targeted layer's weight keeps changing, your layer will not be removed.
---
function Entity:RemoveAllGestures() end

--- [SHARED]
---
--- Removes a callback previously added with [Entity:AddCallback](https://wiki.facepunch.com/gmod/Entity:AddCallback)
---
---@param hook string The hook name to remove. See [Entity Callbacks](https://wiki.facepunch.com/gmod/Entity_Callbacks)
---@param callback_id integer The callback id previously retrieved with the return of [Entity:AddCallback](https://wiki.facepunch.com/gmod/Entity:AddCallback) or [Entity:GetCallbacks](https://wiki.facepunch.com/gmod/Entity:GetCallbacks)
function Entity:RemoveCallback( hook, callback_id ) end

--- [SHARED]
---
--- Removes an engine effect applied to an entity.
---
---@param effect integer The effect to remove, see [Enums/EF](https://wiki.facepunch.com/gmod/Enums/EF).
function Entity:RemoveEffects( effect ) end

--- [SHARED]
---
--- Removes specified engine flag
---
---@param flag integer The flag to remove, see [Enums/EFL](https://wiki.facepunch.com/gmod/Enums/EFL)
function Entity:RemoveEFlags( flag ) end

--- [SHARED]
---
--- Removes specified flag(s) from the entity
---
---@param flag integer The flag(s) to remove, see [Enums/FL](https://wiki.facepunch.com/gmod/Enums/FL)
function Entity:RemoveFlags( flag ) end

--- [SHARED]
---
--- Removes a [PhysObj](https://wiki.facepunch.com/gmod/PhysObj)ect from the entity's motion controller so that [ENTITY:PhysicsSimulate](https://wiki.facepunch.com/gmod/ENTITY:PhysicsSimulate) will no longer be called for given [PhysObj](https://wiki.facepunch.com/gmod/PhysObj)ect.
---
--- You must first create a motion controller with [Entity:StartMotionController](https://wiki.facepunch.com/gmod/Entity:StartMotionController).
---
--- > NOTE: Only works on a scripted [Entity](https://wiki.facepunch.com/gmod/Entity) of anim type
---
---@param phys_obj garrysmod.Physics The [PhysObj](https://wiki.facepunch.com/gmod/PhysObj) to remove from the motion controller.
function Entity:RemoveFromMotionController( phys_obj ) end

--- [SERVER]
---
--- Removes and stops the gesture with given activity. Same as [Entity:RemoveLayer](https://wiki.facepunch.com/gmod/Entity:RemoveLayer) with [Entity:FindGestureLayer](https://wiki.facepunch.com/gmod/Entity:FindGestureLayer).
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entites!
---
--- > NOTE: Layer removal procedures aren't immediate. Layer removal functions actually manipulate [Entity:GetLayerWeight](https://wiki.facepunch.com/gmod/Entity:GetLayerWeight) down to 0, then remove the layer in next intervals. If the targeted layer's weight keeps changing, your layer will not be removed.
---
---@param activity integer The activity remove. See [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
function Entity:RemoveGesture( activity ) end

--- [SERVER]
---
--- Breaks internal Ragdoll constrains, so you can for example separate an arm from the body of a ragdoll and preserve all physics.
---
--- The visual mesh will still stretch as if it was properly connected unless the ragdoll model is specifically designed to avoid that.
---
---@param num integer? Which constraint to break, values below 0 mean break them all Defaults to `-1`.
function Entity:RemoveInternalConstraint( num ) end

--- [SERVER]
---
--- Removes the given layer by ID. See also [Entity:RemoveGesture](https://wiki.facepunch.com/gmod/Entity:RemoveGesture).
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entites!
---
--- > NOTE: Layer removal procedures aren't immediate. Layer removal functions actually manipulate [Entity:GetLayerWeight](https://wiki.facepunch.com/gmod/Entity:GetLayerWeight) down to 0, then remove the layer in next intervals. If the targeted layer's weight keeps changing, your layer will not be removed.
---
---@param layer_id integer The layer ID to remove.
function Entity:RemoveLayer( layer_id ) end

--- [SHARED]
---
--- Removes solid flag(s) from the entity.
---
---@param flags integer The flag(s) to remove, see [Enums/FSOLID](https://wiki.facepunch.com/gmod/Enums/FSOLID).
function Entity:RemoveSolidFlags( flags ) end

--- [SHARED]
---
--- Plays an animation on the entity. This may not always work on engine entities.
---
--- > WARNING: This will not reset the animation on viewmodels, use [Entity:SendViewModelMatchingSequence](https://wiki.facepunch.com/gmod/Entity:SendViewModelMatchingSequence) instead.
---
--- > NOTE: This will not work properly if called directly after calling [Entity:SetModel](https://wiki.facepunch.com/gmod/Entity:SetModel). Consider waiting until the next Tick.
--- >
--- > Will not work on players due to the animations being reset every frame by the base gamemode animation system. See [GM:CalcMainActivity](https://wiki.facepunch.com/gmod/GM:CalcMainActivity).
--- >
--- > For custom scripted entities you will want to apply example from [ENTITY:Think](https://wiki.facepunch.com/gmod/ENTITY:Think) to make animations work.
---
--- > NOTE: (`sequence` argument) If set to a string, the function will automatically call [Entity:LookupSequence](https://wiki.facepunch.com/gmod/Entity:LookupSequence) to retrieve the sequence ID as a number.
---
---@param sequence integer | string The sequence to play. Also accepts strings.
function Entity:ResetSequence( sequence ) end

--- [SHARED]
---
--- Reset entity sequence info such as playback rate, ground speed, last event check, etc.
---
function Entity:ResetSequenceInfo() end

--- [SERVER]
---
--- Makes the entity/weapon respawn.
---
--- Only usable on HL2/HL:S pickups and any weapons. Seems to be buggy with weapons.
--- Very unreliable.
---
function Entity:Respawn() end

--- [SERVER]
---
--- Restarts the entity's animation gesture. If the given gesture is already playing, it will reset it and play it from the beginning.
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entites.
---
---@param activity integer The activity number to send to the entity. See [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT) and [Entity:GetSequenceActivity](https://wiki.facepunch.com/gmod/Entity:GetSequenceActivity)
---@param add_if_missing boolean? Add/start the gesture to if it has not been yet started. Defaults to `true`.
---@param autokill boolean?  Defaults to `true`.
function Entity:RestartGesture( activity, add_if_missing, autokill ) end

--- [SHARED]
---
--- Returns sequence ID corresponding to given activity ID.
---
--- Multiple sequences can be assigned to a single [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT), in which case a random one will be selected. This can be used for example to randomize idle animations (and is used for that by built-in weapons) without the need to code logic for this.
--- See also [Entity:SelectWeightedSequenceSeeded](https://wiki.facepunch.com/gmod/Entity:SelectWeightedSequenceSeeded).
---
--- Opposite of [Entity:GetSequenceActivity](https://wiki.facepunch.com/gmod/Entity:GetSequenceActivity).
---
--- Similar to [Entity:LookupSequence](https://wiki.facepunch.com/gmod/Entity:LookupSequence).
---
---@param act integer The activity ID, see [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
---@return integer sequence_id The sequence ID, or `-1` if not found.
function Entity:SelectWeightedSequence( act ) end

--- [SHARED]
---
--- Returns the sequence ID corresponding to given activity ID, and uses the provided seed for random selection. The seed should be the same server-side and client-side if used in a predicted environment.
---
--- See [Entity:SelectWeightedSequence](https://wiki.facepunch.com/gmod/Entity:SelectWeightedSequence) for a provided-seed version of this function.
---
---@param act integer The activity ID, see [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
---@param seed integer The seed to use for randomly selecting a sequence in the case the activity ID has multiple sequences bound to it. [Entity:SelectWeightedSequence](https://wiki.facepunch.com/gmod/Entity:SelectWeightedSequence) uses the same seed as [util.SharedRandom](https://wiki.facepunch.com/gmod/util.SharedRandom) internally for this.
---@return integer sequence_id The sequence ID, or `-1` if not found.
function Entity:SelectWeightedSequenceSeeded( act, seed ) end

--- [SHARED]
---
--- Sends sequence animation to the view model. It is recommended to use this for view model animations, instead of [Entity:ResetSequence](https://wiki.facepunch.com/gmod/Entity:ResetSequence).
---
--- This function is only usable on view models.
---
--- > NOTE: Predicted viewmodels will have their sequence and cycle reset during prediction checks, making this function appear to do nothing unless also called on the server.
---
---@param sequence_id integer The sequence ID returned by [Entity:LookupSequence](https://wiki.facepunch.com/gmod/Entity:LookupSequence) or  [Entity:SelectWeightedSequence](https://wiki.facepunch.com/gmod/Entity:SelectWeightedSequence).
function Entity:SendViewModelMatchingSequence( sequence_id ) end

--- [SHARED]
---
--- Returns length of currently played sequence.
---
--- > BUG: This will return incorrect results for weapons and viewmodels clientside in thirdperson.
--- > See [issue #2783](https://github.com/Facepunch/garrysmod-issues/issues/2783).
---
---@param sequence_id integer? A sequence ID to return the length specific sequence of instead of the entity's main/currently playing sequence.
---@return number duration The length of the sequence
function Entity:SequenceDuration( sequence_id ) end

--- [SHARED]
---
--- Sets the entity's velocity.
---
--- > NOTE: Actually binds to CBaseEntity::SetLocalVelocity() which sets the entity's velocity due to movement in the world from forces such as gravity. Does not include velocity from entity-on-entity collision or other world movement.
---
---@param velocity garrysmod.Vector The new velocity to set.
function Entity:SetAbsVelocity( velocity ) end

--- [SHARED]
---
--- Sets the angles of the entity.
---
--- > NOTE: To set a player's angles, use [Player:SetEyeAngles](https://wiki.facepunch.com/gmod/Player:SetEyeAngles) instead.
---
---@param angles garrysmod.Angle The new angles.
function Entity:SetAngles( angles ) end

--- [SHARED]
---
--- Sets a player's third-person animation. Despite the function existing for all entities, it will work only on players.
---
---@deprecated Leftover function from Goldsrc transition to set player's main sequence. It is never used after 9-way walk sequence blending since Team Fortress 2. You should be using [GM:CalcMainActivity](https://wiki.facepunch.com/gmod/GM:CalcMainActivity) or [Player:DoCustomAnimEvent](https://wiki.facepunch.com/gmod/Player:DoCustomAnimEvent) instead.
---@param player_anim integer Player animation, see [Enums/PLAYER](https://wiki.facepunch.com/gmod/Enums/PLAYER). Only types [PLAYER_ATTACK1](https://wiki.facepunch.com/gmod/Enums/PLAYER) and [PLAYER_RELOAD](https://wiki.facepunch.com/gmod/Enums/PLAYER) play holdtype specific gestures, other enums don't do anything.
function Entity:SetAnimation( player_anim ) end

--- [CLIENT]
---
--- Sets the start time (relative to [Global.CurTime](https://wiki.facepunch.com/gmod/Global.CurTime)) of the current animation, which is used to determine [Entity:GetCycle](https://wiki.facepunch.com/gmod/Entity:GetCycle). Should be less than CurTime to play an animation from the middle.
---
---@param time number The time the animation was supposed to begin.
function Entity:SetAnimTime( time ) end

--- [SHARED]
---
--- Parents the sprite to an attachment on another model.
---
--- Works only on `env_sprite` entities.
---
--- Despite existing on client, it doesn't actually do anything on client.
---
---@deprecated You should be using [Entity:SetParent](https://wiki.facepunch.com/gmod/Entity:SetParent) instead.
---@param entity garrysmod.Entity The entity to attach/parent to
---@param attachment integer The attachment ID to parent to
function Entity:SetAttachment( entity, attachment ) end

--- [SERVER]
---
--- Sets the blood color this entity uses.
---
---@param blood_color integer An integer corresponding to [Enums/BLOOD_COLOR](https://wiki.facepunch.com/gmod/Enums/BLOOD_COLOR).
function Entity:SetBloodColor( blood_color ) end

--- [SHARED]
---
--- Sets the currently active [Sub Model ID](https://wiki.facepunch.com/gmod/Structures/BodyGroupData#submodels) for the Body Group corresponding to the given [Body Group ID](https://wiki.facepunch.com/gmod/Structures/BodyGroupData#id) of the [Entity's](https://wiki.facepunch.com/gmod/Entity) model.
---
--- Bodygroups, for which [Entity:GetBodygroupCount](https://wiki.facepunch.com/gmod/Entity:GetBodygroupCount) returns `1` or less are considered invalid, and will have no effect in-game.
---
--- > NOTE: When used on a Weapon, this will modify its viewmodel.
---
---@param body_group_id integer The Body Group ID to set the Sub Model ID of. Body Group IDs start at `0`.
---@param sub_model_id integer The Sub Model ID to set as active for this Body Group. Sub Model IDs start at `0`.
function Entity:SetBodygroup( body_group_id, sub_model_id ) end

--- [SHARED]
---
--- Sets the [Entity's](https://wiki.facepunch.com/gmod/Entity) active Sub Models via a string of [Sub Model IDs](https://wiki.facepunch.com/gmod/Structures/BodyGroupData#submodels) in order from the first [Body Group ID](https://wiki.facepunch.com/gmod/Structures/BodyGroupData#id) to the last.
---
--- This is a convenience function for [Entity:SetBodygroup](https://wiki.facepunch.com/gmod/Entity:SetBodygroup).
---
--- > NOTE: When used on a Weapon, this will modify its viewmodel.
---
---@param sub_model_ids string The Sub Model IDs to activate for each Body Group on the Entity's model. The first character corresponds with Body Group ID `0`, the second character coressponds to Body Group ID `1`, etc. To support Body Groups with more than `0`-`9` options, values above `9` are represented using alphabetical characters starting with `a` and ending with `z`.
function Entity:SetBodyGroups( sub_model_ids ) end

--- [SHARED]
---
--- Sets the specified value on the bone controller with the given ID of this entity, it's used in HL1 to change the head rotation of NPCs, turret aiming and so on.
---
--- > NOTE: This is the precursor of pose parameters, and only works for Half Life 1: Source models supporting it.
---
---@param bone_controller_id integer The ID of the bone controller to set the value to. Goes from 0 to 3.
---@param value number The value to set on the specified bone controller.
function Entity:SetBoneController( bone_controller_id, value ) end

--- [SHARED]
---
--- Sets the bone matrix of given bone to given matrix. See also [Entity:GetBoneMatrix](https://wiki.facepunch.com/gmod/Entity:GetBoneMatrix). Will cause a uncatchable error when used on `__INVALIDBONE__` bones, see the examples on a way to prevent this.
---
--- > NOTE: Despite existing serverside, it does nothing.
---
---@param bone_id integer The ID of the bone
---@param matrix garrysmod.VMatrix The matrix to set.
function Entity:SetBoneMatrix( bone_id, matrix ) end

--- [CLIENT]
---
--- Sets the bone position and angles.
---
--- > NOTE (needs validation): For changes to happen, this must be called in a [rendering](https://wiki.facepunch.com/gmod/Render_Order) hook.
---
---@param bone_id integer The bone ID to manipulate
---@param position garrysmod.Vector The position to set
---@param angles garrysmod.Angle The angles to set
function Entity:SetBonePosition( bone_id, position, angles ) end

--- [SHARED]
---
--- Sets the collision bounds for the entity, which are used for triggers ([Entity:SetTrigger](https://wiki.facepunch.com/gmod/Entity:SetTrigger), [ENTITY:Touch](https://wiki.facepunch.com/gmod/ENTITY:Touch)), and collision (If [Entity:SetSolid](https://wiki.facepunch.com/gmod/Entity:SetSolid) set as [SOLID_BBOX](https://wiki.facepunch.com/gmod/Enums/SOLID)).
---
--- Input bounds are relative to [Entity:GetPos](https://wiki.facepunch.com/gmod/Entity:GetPos)!
--- See also [Entity:SetCollisionBoundsWS](https://wiki.facepunch.com/gmod/Entity:SetCollisionBoundsWS).
---
--- > NOTE: Player collision bounds are reset every frame to player's [Player:SetHull](https://wiki.facepunch.com/gmod/Player:SetHull) values.
---
---@param mins garrysmod.Vector The minimum vector of the bounds.
---@param maxs garrysmod.Vector The maximum vector of the bounds.
function Entity:SetCollisionBounds( mins, maxs ) end

--- [SHARED]
---
--- A convenience function that sets the collision bounds for the entity in world space coordinates by transforming given vectors to entity's local space and passing them to [Entity:SetCollisionBounds](https://wiki.facepunch.com/gmod/Entity:SetCollisionBounds)
---
---@param vec1 garrysmod.Vector The first vector of the bounds.
---@param vec2 garrysmod.Vector The second vector of the bounds.
function Entity:SetCollisionBoundsWS( vec1, vec2 ) end

--- [SHARED]
---
--- Sets the entity's collision group.
---
---@param group integer Collision group of the entity, see [Enums/COLLISION_GROUP](https://wiki.facepunch.com/gmod/Enums/COLLISION_GROUP)
function Entity:SetCollisionGroup( group ) end

--- [SHARED]
---
--- Sets the color of an entity without usage of a [Global.Color](https://wiki.facepunch.com/gmod/Global.Color) object.
---
---
---@param r integer The red channel.
---@param g integer The green channel.
---@param b integer The blue channel.
---@param a integer The alpha channel.
function Entity:SetColor4Part( r, g, b, a ) end

--- [SHARED]
---
--- Marks the entity to call [GM:ShouldCollide](https://wiki.facepunch.com/gmod/GM:ShouldCollide). Not to be confused with [Entity:EnableCustomCollisions](https://wiki.facepunch.com/gmod/Entity:EnableCustomCollisions).
---
--- > NOTE: Make sure to use [Entity:CollisionRulesChanged](https://wiki.facepunch.com/gmod/Entity:CollisionRulesChanged) after changing this value.
--- > Otherwise it can cause crashes.
---
---@param enable boolean Enable or disable the custom collision check
function Entity:SetCustomCollisionCheck( enable ) end

--- [SHARED]
---
--- Sets the progress of the current animation to a specific value between 0 and 1.
---
--- > BUG: Viewmodels overwrite their animation cycle every frame, for prediction/interpolation purposes.
--- > See [issue #3038](https://github.com/Facepunch/garrysmod-issues/issues/3038).
---
---@param value number The desired cycle value
function Entity:SetCycle( value ) end

--- [SHARED]
---
--- This is called internally by the [Entity:NetworkVar](https://wiki.facepunch.com/gmod/Entity:NetworkVar) system, you can use this in cases where using NetworkVar is not possible.
---
--- Sets the specified angle on the entity's datatable.
---
---@param key integer Goes from 0 to 31.
---@param value garrysmod.Angle The angle to write on the entity's datatable.
function Entity:SetDTAngle( key, value ) end

--- [SHARED]
---
--- This is called internally by the [Entity:NetworkVar](https://wiki.facepunch.com/gmod/Entity:NetworkVar) system, you can use this in cases where using NetworkVar is not possible.
---
--- Sets the specified bool on the entity's datatable.
---
---@param key integer Goes from 0 to 31.
---@param value boolean The boolean to write on the entity's metatable.
function Entity:SetDTBool( key, value ) end

--- [SHARED]
---
--- This is called internally by the [Entity:NetworkVar](https://wiki.facepunch.com/gmod/Entity:NetworkVar) system, you can use this in cases where using NetworkVar is not possible.
---
--- Sets the specified entity on this entity's datatable.
---
---@param key integer Goes from 0 to 31.
---@param value garrysmod.Entity The entity to write on this entity's datatable.
function Entity:SetDTEntity( key, value ) end

--- [SHARED]
---
--- This is called internally by the [Entity:NetworkVar](https://wiki.facepunch.com/gmod/Entity:NetworkVar) system, you can use this in cases where using NetworkVar is not possible.
---
--- Sets the specified float on the entity's datatable.
---
---@param key integer Goes from 0 to 31.
---@param value number The float to write on the entity's datatable.
function Entity:SetDTFloat( key, value ) end

--- [SHARED]
---
--- This is called internally by the [Entity:NetworkVar](https://wiki.facepunch.com/gmod/Entity:NetworkVar) system, you can use this in cases where using NetworkVar is not possible.
---
--- Sets the specified integer on the entity's datatable.
---
---@param key integer Goes from 0 to 31.
---@param value integer The integer to write on the entity's datatable. This will be cast to a 32-bit signed integer internally.
function Entity:SetDTInt( key, value ) end

--- [SHARED]
---
--- This is called internally by the [Entity:NetworkVar](https://wiki.facepunch.com/gmod/Entity:NetworkVar) system, you can use this in cases where using NetworkVar is not possible.
---
--- Sets the specified string on the entity's datatable.
---
--- > NOTE: The length of these strings are capped at 512 characters.
---
---@param key integer Goes from 0 to 3.
---@param value string The string to write on the entity's datatable, can't be more than 512 characters per string.
function Entity:SetDTString( key, value ) end

--- [SHARED]
---
--- This is called internally by the [Entity:NetworkVar](https://wiki.facepunch.com/gmod/Entity:NetworkVar) system, you can use this in cases where using NetworkVar is not possible.
---
--- Sets the specified vector on the entity's datatable.
---
---@param key integer Goes from 0 to 31.
---@param value garrysmod.Vector The vector to write on the entity's datatable.
function Entity:SetDTVector( key, value ) end

--- [SHARED]
---
--- Sets the elasticity of this entity, used by some flying entities such as the Helicopter NPC to determine how much it should bounce around when colliding.
---
---@param elasticity number The elasticity to set.
function Entity:SetElasticity( elasticity ) end

--- [SHARED]
---
--- Allows you to set the Start or End entity attachment for the rope.
---
---@param name string The name of the variable to modify. Accepted names are StartEntity and EndEntity.
---@param entity garrysmod.Entity The entity to apply to the specific attachment.
function Entity:SetEntity( name, entity ) end

--- [SHARED]
---
--- Sets the position an entity's eyes look toward. This works as an override for default behavior. Set to `0,0,0` to disable the override.
---
---@param position garrysmod.Vector For NPCs and all other entities except ragdolls - the **world position** for the entity to look towards For ragdolls specifically - a **local position** in front of their `eyes` attachment.
function Entity:SetEyeTarget( position ) end

--- [SHARED]
---
--- Sets the scale of all the flexes of this entity. See [Entity:SetFlexWeight](https://wiki.facepunch.com/gmod/Entity:SetFlexWeight).
---
---@param scale number The new flex scale to set to
function Entity:SetFlexScale( scale ) end

--- [SHARED]
---
--- Sets the weight/value of given flex controller.
---
--- Setting flex weights spawns an internal networked entity (one per entity face posed) to accommodate networking to clients.
---
--- > NOTE: Only `96` flex controllers can be set! Flex controllers on models with higher amounts will not be accessible.
---
---@param flex_id integer The ID of the flex to modify weight of.  The range is between `0` and [Entity:GetFlexNum](https://wiki.facepunch.com/gmod/Entity:GetFlexNum) - 1.
---@param weight number The new weight to set. The range is [0,1] for entities with [Entity:HasFlexManipulatior](https://wiki.facepunch.com/gmod/Entity:HasFlexManipulatior), and the model-defined input range otherwise ([Entity:GetFlexBounds](https://wiki.facepunch.com/gmod/Entity:GetFlexBounds)) Exceeding the range is allowed, and will amplify the effect (to possibly bad results), exactly like [Entity:SetFlexScale](https://wiki.facepunch.com/gmod/Entity:SetFlexScale) does.
function Entity:SetFlexWeight( flex_id, weight ) end

--- [SHARED]
---
--- Sets friction multiplier for this entity when sliding against a surface. Entities default to 1 (100%) and can be higher.
---
--- This may not affect all entities, but does work for players (the range is 0 to 10), as well as other entities using [MOVETYPE_STEP ](https://wiki.facepunch.com/gmod/Enums/MOVETYPE#MOVETYPE_STEP_)
---
--- This only multiplies the friction of the entity, to change the value itself use [PhysObj:SetMaterial](https://wiki.facepunch.com/gmod/PhysObj:SetMaterial).
---
---@param friction number Friction multiplier
function Entity:SetFriction( friction ) end

--- [SHARED]
---
--- Sets the gravity multiplier of the entity.
---
--- This may not affect affect all entities, but does affect players, and entities with [MOVETYPE_FLYGRAVITY](https://wiki.facepunch.com/gmod/Enums/MOVETYPE#MOVETYPE_FLYGRAVITY), such as projectiles.
---
---@param multiplier number By how much to multiply the gravity. `1` is normal gravity, `0.5` is half-gravity, etc.
function Entity:SetGravity( multiplier ) end

--- [SHARED]
---
--- Sets the ground the entity is standing on.
---
---@param entity garrysmod.Entity The ground entity.
function Entity:SetGroundEntity( entity ) end

--- [SHARED]
---
--- Sets the health of the entity.
---
--- > NOTE: You may want to take [Entity:GetMaxHealth](https://wiki.facepunch.com/gmod/Entity:GetMaxHealth) into account when calculating what to set health to, in case a gamemode has a different max health than 100.
--- > In some cases, setting health only serverside can cause hitches in movement, for example if something is modifying the player speed based on health.
--- > To solve this issue, it is better to set it shared in a predicted hook.
---
---@param new_health integer New health value.
function Entity:SetHealth( new_health ) end

--- [SHARED]
---
--- Sets the current Hitbox set for the entity.
---
---@param id integer The new hitbox set to set. Can be a name as a [string](https://wiki.facepunch.com/gmod/string), or the ID as a [number](https://wiki.facepunch.com/gmod/number). If the operation failed, the function will silently fail.
function Entity:SetHitboxSet( id ) end

--- [SHARED]
---
--- Enables or disable the inverse kinematic usage of this entity.
---
--- > WARNING: Calling this with false outside of [ENTITY:Initialize](https://wiki.facepunch.com/gmod/ENTITY:Initialize) requires a model change to take effect.
---
---@param use_ik boolean? The state of the IK. Defaults to `false`.
function Entity:SetIK( use_ik ) end

--- [SHARED]
---
--- Sets Hammer key values on an entity.
---
--- You can look up which entities have what key values on the [Valve Developer Community](https://developer.valvesoftware.com/wiki/) on entity pages. A  list of basic entities can be found [here](https://developer.valvesoftware.com/wiki/List_of_entities).
---
--- Alternatively you can look at the `.fgd` files shipped with Garry's Mod in the `bin/` folder with a text editor to see the key values as they appear in Hammer.
---
---@param key string The internal key name
---@param value string The value to set
function Entity:SetKeyValue( key, value ) end

--- [SERVER]
---
--- This allows the entity to be lag compensated during [Player:LagCompensation](https://wiki.facepunch.com/gmod/Player:LagCompensation).
---
--- > NOTE: Players are lag compensated by default and there's no need to call this function for them.
--- >
--- > It's best to not enable lag compensation on parented entities, as the system does not handle it that well ( they will be moved back but then the entity will lag behind ).
--- > Parented entities move back with the parent if it's lag compensated, so if you are making some kind of armor piece you shouldn't do anything.
---
--- As a side note for parented entities, if your entity can be shot at, keep in mind that its collision bounds need to be bigger than the bone's hitbox the entity is parented to, or hull/line traces ( such as the crowbar attack or bullets ) might not hit at all.
---
---@param enable boolean Whether the entity should be lag compensated or not.
function Entity:SetLagCompensated( enable ) end

--- [SERVER]
---
--- Sets the autokill flag on the layer, making the layer be automatically removed once the animation playback finishes.
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entites!
---
---@param layer_id integer The layer ID to change.
---@param auto_kill boolean Whether to set or unset the autokill flag.
function Entity:SetLayerAutokill( layer_id, auto_kill ) end

--- [SHARED]
---
--- Sets the interval the layer will fully blend in since startup, based on [Entity:GetLayerCycle](https://wiki.facepunch.com/gmod/Entity:GetLayerCycle). Setting this above 0 will enable internal blending of [Entity:GetLayerWeight](https://wiki.facepunch.com/gmod/Entity:GetLayerWeight).
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entites!
---
--- > BUG: Enabling this will prevent looping gestures with autokill disabled to be removed with [Entity:RemoveGesture](https://wiki.facepunch.com/gmod/Entity:RemoveGesture) or [Entity:RemoveAllGestures](https://wiki.facepunch.com/gmod/Entity:RemoveAllGestures) because layer removal functions mark the layer to decrement [Entity:GetLayerWeight](https://wiki.facepunch.com/gmod/Entity:GetLayerWeight) and unallocate layer ID in next frames if the layer weight is `0`, but blending functions will still keep manipulating layer weight.
--- >
--- > Therefore; before calling layer cleanup functions, make sure both [Entity:SetLayerBlendIn](https://wiki.facepunch.com/gmod/Entity:SetLayerBlendIn) and [Entity:SetLayerBlendOut](https://wiki.facepunch.com/gmod/Entity:SetLayerBlendOut) are set to `0`.
---
---@param layer_id integer The Layer ID
---@param blend_in number Blend range from 0 to 1.
function Entity:SetLayerBlendIn( layer_id, blend_in ) end

--- [SHARED]
---
--- Sets the interval the layer will fully blend out, based on [Entity:GetLayerCycle](https://wiki.facepunch.com/gmod/Entity:GetLayerCycle). Setting this above 0 will enable internal blending of [Entity:GetLayerWeight](https://wiki.facepunch.com/gmod/Entity:GetLayerWeight).
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entites!
---
--- > BUG: Enabling this will prevent looping gestures with autokill disabled to be removed with [Entity:RemoveGesture](https://wiki.facepunch.com/gmod/Entity:RemoveGesture) or [Entity:RemoveAllGestures](https://wiki.facepunch.com/gmod/Entity:RemoveAllGestures) because layer removal functions mark the layer to decrement [Entity:GetLayerWeight](https://wiki.facepunch.com/gmod/Entity:GetLayerWeight) and unallocate layer ID in next frames if the layer weight is `0`, but blending functions will still keep manipulating layer weight.
--- >
--- > Therefore; before calling layer cleanup functions, make sure both [Entity:SetLayerBlendIn](https://wiki.facepunch.com/gmod/Entity:SetLayerBlendIn) and [Entity:SetLayerBlendOut](https://wiki.facepunch.com/gmod/Entity:SetLayerBlendOut) are set to `0`.
---
---@param layer_id integer The Layer ID
---@param blend_out number Blend range from 0 to 1.
function Entity:SetLayerBlendOut( layer_id, blend_out ) end

--- [SHARED]
---
--- Sets the animation cycle/frame of given layer.
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entities.
---
---@param layer_id integer The Layer ID
---@param cycle number The new animation cycle/frame for given layer.
function Entity:SetLayerCycle( layer_id, cycle ) end

--- [SHARED]
---
--- Sets the duration of given layer. This internally overrides the [Entity:SetLayerPlaybackRate](https://wiki.facepunch.com/gmod/Entity:SetLayerPlaybackRate).
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entities.
---
--- > BUG: This stops layer playback if layer sequence conists of 1 frame. Use `Entity:SetLayerPlaybackRate(layerID,1/duration)` instead.
---
---@param layer_id integer The Layer ID
---@param duration number The new duration of the layer in seconds.
function Entity:SetLayerDuration( layer_id, duration ) end

--- [SERVER]
---
--- Sets whether the layer should loop or not.
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entites!
---
---@param layer_id integer The Layer ID
---@param loop boolean Whether the layer should loop or not.
function Entity:SetLayerLooping( layer_id, loop ) end

--- [SHARED]
---
--- Sets the layer playback rate. See also [Entity:SetLayerDuration](https://wiki.facepunch.com/gmod/Entity:SetLayerDuration).
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entities.
---
---@param layer_id integer The Layer ID
---@param rate number The new playback rate.
function Entity:SetLayerPlaybackRate( layer_id, rate ) end

--- [SERVER]
---
--- Sets the priority of given layer.
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entites!
---
---@param layer_id integer The Layer ID
---@param priority integer The new priority of the layer.
function Entity:SetLayerPriority( layer_id, priority ) end

--- [SHARED]
---
--- Sets the sequence of given layer.
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entities.
---
---@param layer_id integer The Layer ID.
---@param sequence_id integer The sequenceID to set. See [Entity:LookupSequence](https://wiki.facepunch.com/gmod/Entity:LookupSequence).
function Entity:SetLayerSequence( layer_id, sequence_id ) end

--- [SHARED]
---
--- Sets the layer weight. This influences how strongly the animation should be overriding the normal animations of the entity.
---
--- > NOTE: This function only works on [BaseAnimatingOverlay](https://wiki.facepunch.com/gmod/BaseAnimatingOverlay) entities.
---
--- > NOTE: Setting either [Entity:SetLayerBlendIn](https://wiki.facepunch.com/gmod/Entity:SetLayerBlendIn) or [Entity:SetLayerBlendOut](https://wiki.facepunch.com/gmod/Entity:SetLayerBlendOut) above 0 will turn on automatic weight blending, so you shouldn't be using this if you use any of above.
---
---@param layer_id integer The Layer ID
---@param weight number The new layer weight.
function Entity:SetLayerWeight( layer_id, weight ) end

--- [CLIENT]
---
--- This forces an entity to use the bone transformation behaviour from versions prior to **8 July 2014**.
---
--- This behaviour affects [Entity:EnableMatrix](https://wiki.facepunch.com/gmod/Entity:EnableMatrix) and [Entity:SetModelScale](https://wiki.facepunch.com/gmod/Entity:SetModelScale) and is incorrect, therefore this function be used exclusively as a quick fix for old scripts that rely on it.
---
---@param enabled boolean Whether the entity should use the old bone transformation behaviour or not.
function Entity:SetLegacyTransform( enabled ) end

--- [SERVER]
---
--- Sets the entity to be used as the light origin position for this entity.
---
---@param light_origin garrysmod.Entity The lighting entity.
function Entity:SetLightingOriginEntity( light_origin ) end

--- [SHARED]
---
--- Sets angles relative to angles of [Entity:GetParent](https://wiki.facepunch.com/gmod/Entity:GetParent)
---
---@param angles garrysmod.Angle The local angle
function Entity:SetLocalAngles( angles ) end

--- [SHARED]
---
--- Sets the entity's angular velocity (rotation speed).
---
---@param angular_velocity garrysmod.Angle The angular velocity to set.
function Entity:SetLocalAngularVelocity( angular_velocity ) end

--- [SHARED]
---
--- Sets local position relative to the parented position. This is for use with [Entity:SetParent](https://wiki.facepunch.com/gmod/Entity:SetParent) to offset position.
---
--- This is also used by NPCs for interpolated movement. If you use [Entity:SetPos](https://wiki.facepunch.com/gmod/Entity:SetPos) for step movement, your NPC will snap to position instead.
---
---@param position garrysmod.Vector The local position
function Entity:SetLocalPos( position ) end

--- [SHARED]
---
--- Sets the entity's local velocity which is their velocity due to movement in the world from forces such as gravity. Does not include velocity from entity-on-entity collision or other world movement.
---
--- > WARNING: Same as [Entity:SetAbsVelocity](https://wiki.facepunch.com/gmod/Entity:SetAbsVelocity), but clamps the given velocity, and is not recommended to be used because of that.
---
---@param velocity garrysmod.Vector The new velocity to set.
function Entity:SetLocalVelocity( velocity ) end

--- [CLIENT]
---
--- Sets the Level Of Detail model to use with this entity. This may not work for all models if the model doesn't include any LOD sub models.
---
--- This function works exactly like the clientside r_lod convar and takes priority over it.
---
---@param lod integer? The Level Of Detail model ID to use. -1 leaves the engine to automatically set the Level of Detail. The Level Of Detail may range from 0 to 8, with 0 being the highest quality and 8 the lowest. Defaults to `-1`.
function Entity:SetLOD( lod ) end

--- [SHARED]
---
--- Sets the rendering material override of the entity.
---
--- To set a Lua material created with [Global.CreateMaterial](https://wiki.facepunch.com/gmod/Global.CreateMaterial), just prepend a "!" to the material name.
---
--- If you wish to override a single material on the model, use [Entity:SetSubMaterial](https://wiki.facepunch.com/gmod/Entity:SetSubMaterial) instead.
---
--- > NOTE: To apply materials to models, that material **must** have **VertexLitGeneric** shader. For that reason you cannot apply map textures onto models, map textures use a different material shader - **LightmappedGeneric**, which can be used on brush entities.
---
--- > BUG: The server's value takes priority on the client.
--- > See [issue #3362](https://github.com/Facepunch/garrysmod-issues/issues/3362).
---
---@param material_name string New material name. Use an empty string ("") to reset to the default materials.
function Entity:SetMaterial( material_name ) end

--- [SERVER]
---
--- Sets the maximum health for entity. Note, that you can still set entity's health above this amount with [Entity:SetHealth](https://wiki.facepunch.com/gmod/Entity:SetHealth).
---
---@param max_health integer What the max health should be
function Entity:SetMaxHealth( max_health ) end

--- [SHARED]
---
--- Sets the model of the entity.
---
--- This does not update the physics of the entity - see [Entity:PhysicsInit](https://wiki.facepunch.com/gmod/Entity:PhysicsInit).
---
--- > WARNING: This silently fails when given an empty string.
---
---@param model_name string New model value.
function Entity:SetModel( model_name ) end

--- [SHARED]
---
--- Alter the model name returned by [Entity:GetModel](https://wiki.facepunch.com/gmod/Entity:GetModel). Does not affect the entity's actual model.
---
---@param model_name string The new model name.
function Entity:SetModelName( model_name ) end

--- [SHARED]
---
--- Uniformly scales the model of the entity, if the entity is a [Player](https://wiki.facepunch.com/gmod/Player) or an [NPC](https://wiki.facepunch.com/gmod/NPC) the hitboxes will be scaled as well.
---
--- To resize the entity non-uniformly, along any axis, use [Entity:EnableMatrix](https://wiki.facepunch.com/gmod/Entity:EnableMatrix) instead.
---
--- For some entities (Such as `prop_physics` and `anim` type [Scripted Entities](https://wiki.facepunch.com/gmod/Scripted_Entities)), calling [Entity:Activate](https://wiki.facepunch.com/gmod/Entity:Activate) after this will scale the collision bounds and [PhysObj](https://wiki.facepunch.com/gmod/PhysObj) as well; be wary as there's no optimization being done internally and highly complex collision models might crash the server.
---
--- Client-side trace detection seems to mess up if `deltaTime` is set to anything but zero. A very small decimal can be used instead of zero to solve this issue.
---
--- If your old scales are wrong, use [Entity:SetLegacyTransform](https://wiki.facepunch.com/gmod/Entity:SetLegacyTransform) as a quick fix.
---
--- > NOTE: If you do not want the physics to be affected by [Entity:Activate](https://wiki.facepunch.com/gmod/Entity:Activate), you can use [Entity:ManipulateBoneScale](https://wiki.facepunch.com/gmod/Entity:ManipulateBoneScale)`( 0, Vector( scale, scale, scale ) )` instead.
---
--- > BUG: On the client, `anim` types' collision testing prediction fails for changed model scales: you can use `cl_showerror 2` to see by how much. Essentially, the client will freak out when you stand/run past on a Scripted Entity or prop that has been modified using this method.
--- > See [issue #6405](https://github.com/Facepunch/garrysmod-issues/issues/6405).
---
--- > NOTE (needs validation): This disables IK.
---
---@param scale number A float to scale the model by. 0 will not draw anything. A number less than 0 will draw the model inverted.
---@param delta_time number? Transition time of the scale change, set to 0 to modify the scale right away. To avoid issues with client-side trace detection this must be set, and can be an extremely low number to mimic a value of 0 such as .000001. Defaults to `0`.
function Entity:SetModelScale( scale, delta_time ) end

--- [SHARED]
---
--- Sets the move collide type of the entity. The move collide is the way a physics object reacts to hitting an object - will it bounce, slide?
---
---@param move_collide_type integer The move collide type, see [Enums/MOVECOLLIDE](https://wiki.facepunch.com/gmod/Enums/MOVECOLLIDE)
function Entity:SetMoveCollide( move_collide_type ) end

--- [SHARED]
---
--- Sets the Movement Parent of an entity to another entity.
---
--- Similar to [Entity:SetParent](https://wiki.facepunch.com/gmod/Entity:SetParent), except the object's coordinates are not translated automatically before parenting.
---
--- Does nothing on client.
---
---@param parent garrysmod.Entity The entity to change this entity's Movement Parent to.
function Entity:SetMoveParent( parent ) end

--- [SHARED]
---
--- Sets the entity's move type. This should be called before initializing the physics object on the entity, unless it will override SetMoveType such as [Entity:PhysicsInitBox](https://wiki.facepunch.com/gmod/Entity:PhysicsInitBox).
---
--- Despite existing on client, it doesn't actually do anything on client.
---
---@param move_type integer The new movetype, see [Enums/MOVETYPE](https://wiki.facepunch.com/gmod/Enums/MOVETYPE)
function Entity:SetMoveType( move_type ) end

--- [SERVER]
---
--- Sets the mapping name of the entity.
---
---@param name string The name to set for the entity.
function Entity:SetName( name ) end

--- [CLIENT]
---
--- Alters the entity's perceived serverside angle on the client.
---
---@param angles garrysmod.Angle Networked angle.
function Entity:SetNetworkAngles( angles ) end

--- [SHARED]
---
--- Sets a networked angle value on the entity.
---
--- The value can then be accessed with [Entity:GetNetworked2Angle](https://wiki.facepunch.com/gmod/Entity:GetNetworked2Angle) both from client and server.
---
--- > WARNING: The value will only be updated clientside if the entity is or enters the clients PVS. use [Entity:SetNWAngle](https://wiki.facepunch.com/gmod/Entity:SetNWAngle) instead
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
--- > The value will only be networked if it isn't the same as the current value and unlike SetNW*
--- > the value will only be networked once and not every 10 seconds.
---
---@deprecated You should be using [Entity:SetNW2Angle](https://wiki.facepunch.com/gmod/Entity:SetNW2Angle) instead.
---@param key string The key to associate the value with
---@param value garrysmod.Angle The value to set
function Entity:SetNetworked2Angle( key, value ) end

--- [SHARED]
---
--- Sets a networked boolean value on the entity.
---
--- The value can then be accessed with [Entity:GetNetworked2Bool](https://wiki.facepunch.com/gmod/Entity:GetNetworked2Bool) both from client and server.
---
--- > WARNING: The value will only be updated clientside if the entity is or enters the clients PVS. use [Entity:SetNWBool](https://wiki.facepunch.com/gmod/Entity:SetNWBool) instead
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
--- > The value will only be networked if it isn't the same as the current value and unlike SetNW*
--- > the value will only be networked once and not every 10 seconds.
---
---@deprecated You should be using [Entity:SetNW2Bool](https://wiki.facepunch.com/gmod/Entity:SetNW2Bool) instead.
---@param key string The key to associate the value with
---@param value boolean The value to set
function Entity:SetNetworked2Bool( key, value ) end

--- [SHARED]
---
--- Sets a networked entity value on the entity.
---
--- The value can then be accessed with [Entity:GetNetworked2Entity](https://wiki.facepunch.com/gmod/Entity:GetNetworked2Entity) both from client and server.
---
--- > WARNING: The value will only be updated clientside if the entity is or enters the clients PVS. use [Entity:SetNWEntity](https://wiki.facepunch.com/gmod/Entity:SetNWEntity) instead
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
--- > The value will only be networked if it isn't the same as the current value and unlike SetNW*
--- > the value will only be networked once and not every 10 seconds.
---
---@deprecated You should be using [Entity:SetNW2Entity](https://wiki.facepunch.com/gmod/Entity:SetNW2Entity) instead.
---@param key string The key to associate the value with
---@param value garrysmod.Entity The value to set
function Entity:SetNetworked2Entity( key, value ) end

--- [SHARED]
---
--- Sets a networked float (number) value on the entity.
---
--- The value can then be accessed with [Entity:GetNetworked2Float](https://wiki.facepunch.com/gmod/Entity:GetNetworked2Float) both from client and server.
---
--- Unlike [Entity:SetNetworked2Int](https://wiki.facepunch.com/gmod/Entity:SetNetworked2Int), floats don't have to be whole numbers.
---
--- > WARNING: The value will only be updated clientside if the entity is or enters the clients PVS. use [Entity:SetNWFloat](https://wiki.facepunch.com/gmod/Entity:SetNWFloat) instead
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
--- > The value will only be networked if it isn't the same as the current value and unlike SetNW*
--- > the value will only be networked once and not every 10 seconds.
---
---@param key string The key to associate the value with
---@param value number The value to set
function Entity:SetNetworked2Float( key, value ) end

--- [SHARED]
---
--- Sets a networked integer (whole number) value on the entity.
---
--- The value can then be accessed with [Entity:GetNetworked2Int](https://wiki.facepunch.com/gmod/Entity:GetNetworked2Int) both from client and server.
---
--- See [Entity:SetNW2Float](https://wiki.facepunch.com/gmod/Entity:SetNW2Float) for numbers that aren't integers.
---
--- > WARNING: The value will only be updated clientside if the entity is or enters the clients PVS.
--- > The integer has a 32 bit limit. Use [Entity:SetNWInt](https://wiki.facepunch.com/gmod/Entity:SetNWInt) instead
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
--- > The value will only be networked if it isn't the same as the current value and unlike SetNW*
--- > the value will only be networked once and not every 10 seconds.
---
---@deprecated You should be using [Entity:SetNW2Int](https://wiki.facepunch.com/gmod/Entity:SetNW2Int) instead.
---@param key string The key to associate the value with
---@param value integer The value to set
function Entity:SetNetworked2Int( key, value ) end

--- [SHARED]
---
--- Sets a networked string value on the entity.
---
--- The value can then be accessed with [Entity:GetNetworked2String](https://wiki.facepunch.com/gmod/Entity:GetNetworked2String) both from client and server.
---
--- > WARNING: The value will only be updated clientside if the entity is or enters the clients PVS. use [Entity:SetNWString](https://wiki.facepunch.com/gmod/Entity:SetNWString) instead
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
--- > The value will only be networked if it isn't the same as the current value and unlike SetNW*
--- > the value will only be networked once and not every 10 seconds.
---
---@deprecated You should be using [Entity:SetNW2String](https://wiki.facepunch.com/gmod/Entity:SetNW2String) instead.
---@param key string The key to associate the value with
---@param value string The value to set, up to 511 characters.
function Entity:SetNetworked2String( key, value ) end

--- [SHARED]
---
--- Sets a networked value on the entity.
---
--- The value can then be accessed with [Entity:GetNetworked2Var](https://wiki.facepunch.com/gmod/Entity:GetNetworked2Var) both from client and server.
---
--- | Allowed Types   |
--- | --------------- |
--- | Angle           |
--- | Boolean         |
--- | Entity          |
--- | Float           |
--- | Int             |
--- | String          |
--- | Vector          |
---
--- > WARNING: Trying to network a type that is not listed above leads to the value not being networked!
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
--- > The value will only be networked if it isn't the same as the current value and unlike SetNW*
--- > the value will only ne networked once and not every 10 seconds.
---
---@deprecated You should be using [Entity:SetNW2Var](https://wiki.facepunch.com/gmod/Entity:SetNW2Var) instead.
---@param key string The key to associate the value with
---@param value any The value to set
function Entity:SetNetworked2Var( key, value ) end

--- [SHARED]
---
--- Sets a networked vector value on the entity.
---
--- The value can then be accessed with [Entity:GetNetworked2Vector](https://wiki.facepunch.com/gmod/Entity:GetNetworked2Vector) both from client and server.
---
--- > WARNING: The value will only be updated clientside if the entity is or enters the clients PVS. use [Entity:SetNWVector](https://wiki.facepunch.com/gmod/Entity:SetNWVector) instead
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
--- > The value will only be networked if it isn't the same as the current value and unlike SetNW*
--- > the value will only be networked once and not every 10 seconds.
---
---@deprecated You should be using [Entity:SetNW2Vector](https://wiki.facepunch.com/gmod/Entity:SetNW2Vector) instead.
---@param key string The key to associate the value with
---@param value garrysmod.Vector The value to set
function Entity:SetNetworked2Vector( key, value ) end

--- [SHARED]
---
--- Sets a networked angle value at specified index on the entity.
---
--- The value then can be accessed with [Entity:GetNetworkedAngle](https://wiki.facepunch.com/gmod/Entity:GetNetworkedAngle) both from client and server.
---
--- > NOTE: Running this function clientside will only set it clientside for the client it is called on.
---
---@deprecated You should use [Entity:SetNWAngle](https://wiki.facepunch.com/gmod/Entity:SetNWAngle) instead.
---@param key string The key to associate the value with
---@param value garrysmod.Angle? The value to set Defaults to `Angle( 0, 0, 0 )`.
function Entity:SetNetworkedAngle( key, value ) end

--- [SHARED]
---
--- Sets a networked boolean value at specified index on the entity.
---
--- The value then can be accessed with [Entity:GetNetworkedBool](https://wiki.facepunch.com/gmod/Entity:GetNetworkedBool) both from client and server.
---
--- > NOTE: Running this function clientside will only set it clientside for the client it is called on.
---
---@deprecated You should use [Entity:SetNWBool](https://wiki.facepunch.com/gmod/Entity:SetNWBool) instead.
---@param key string The key to associate the value with
---@param value boolean? The value to set Defaults to `false`.
function Entity:SetNetworkedBool( key, value ) end

--- [SHARED]
---
--- Sets a networked entity value at specified index on the entity.
---
--- The value then can be accessed with [Entity:GetNetworkedEntity](https://wiki.facepunch.com/gmod/Entity:GetNetworkedEntity) both from client and server.
---
--- > NOTE: Running this function clientside will only set it clientside for the client it is called on.
---
---@deprecated You should use [Entity:SetNWEntity](https://wiki.facepunch.com/gmod/Entity:SetNWEntity) instead.
---@param key string The key to associate the value with
---@param value garrysmod.Entity? The value to set Defaults to `NULL`.
function Entity:SetNetworkedEntity( key, value ) end

--- [SHARED]
---
--- Sets a networked float value at specified index on the entity.
---
--- The value then can be accessed with [Entity:GetNetworkedFloat](https://wiki.facepunch.com/gmod/Entity:GetNetworkedFloat) both from client and server.
---
--- Seems to be the same as [Entity:GetNetworkedInt](https://wiki.facepunch.com/gmod/Entity:GetNetworkedInt).
---
--- > NOTE: Running this function clientside will only set it clientside for the client it is called on.
---
---@deprecated You should use [Entity:SetNWFloat](https://wiki.facepunch.com/gmod/Entity:SetNWFloat) instead.
---@param key string The key to associate the value with
---@param value number? The value to set Defaults to `0`.
function Entity:SetNetworkedFloat( key, value ) end

--- [SHARED]
---
--- Sets a networked integer value at specified index on the entity.
---
--- The value then can be accessed with [Entity:GetNetworkedInt](https://wiki.facepunch.com/gmod/Entity:GetNetworkedInt) both from client and server.
---
--- > NOTE: Running this function clientside will only set it clientside for the client it is called on.
---
---@deprecated You should use [Entity:SetNWInt](https://wiki.facepunch.com/gmod/Entity:SetNWInt) instead.
---@param key string The key to associate the value with
---@param value integer? The value to set Defaults to `0`.
function Entity:SetNetworkedInt( key, value ) end

--- [SHARED]
---
--- Sets a networked number at the specified index on the entity.
---
---@deprecated You should be using [Entity:SetNWFloat](https://wiki.facepunch.com/gmod/Entity:SetNWFloat) instead.
---@param key string The index that the value is stored in.
---@param value number The value to network.
function Entity:SetNetworkedNumber( key, value ) end

--- [SHARED]
---
--- Sets a networked string value at specified index on the entity.
---
--- The value then can be accessed with [Entity:GetNetworkedString](https://wiki.facepunch.com/gmod/Entity:GetNetworkedString) both from client and server.
---
--- > NOTE: Running this function clientside will only set it clientside for the client it is called on.
---
---@deprecated You should use [Entity:SetNWString](https://wiki.facepunch.com/gmod/Entity:SetNWString) instead.
---@param key string The key to associate the value with
---@param value string? The value to set
function Entity:SetNetworkedString( key, value ) end

--- [SHARED]
---
--- Sets a networked value on the entity.
---
--- The value can then be accessed with [Entity:GetNetworkedVar](https://wiki.facepunch.com/gmod/Entity:GetNetworkedVar) both from client and server.
---
--- | Allowed Types   |
--- | --------------- |
--- | Angle           |
--- | Boolean         |
--- | Entity          |
--- | Float           |
--- | Int             |
--- | String          |
--- | Vector          |
---
--- > WARNING: Trying to network a type that is not listed above leads to the value not being networked!
--- > the value will only be updated clientside if the entity is or enters the clients PVS.
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
--- > The value will only be networked if it isn't the same as the current value and unlike SetNW*
--- > the value will only be networked once and not every 10 seconds.
---
---@deprecated
---@param key string The key to associate the value with
---@param value any The value to set
function Entity:SetNetworkedVar( key, value ) end

--- [SHARED]
---
--- Sets a networked vector value at specified index on the entity.
---
--- The value then can be accessed with [Entity:GetNetworkedVector](https://wiki.facepunch.com/gmod/Entity:GetNetworkedVector) both from client and server.
---
--- > NOTE: Running this function clientside will only set it clientside for the client it is called on.
---
---@deprecated You should use [Entity:SetNWVector](https://wiki.facepunch.com/gmod/Entity:SetNWVector) instead.
---@param key string The key to associate the value with
---@param value garrysmod.Vector? The value to set Defaults to `Vector( 0, 0, 0 )`.
function Entity:SetNetworkedVector( key, value ) end

--- [SHARED]
---
--- Virtually changes entity position for clients. Does almost the same thing as [Entity:SetPos](https://wiki.facepunch.com/gmod/Entity:SetPos) when used serverside.
---
--- > NOTE: Unlike [Entity:SetPos](https://wiki.facepunch.com/gmod/Entity:SetPos) it directly changes the position without checking for any unreasonable position.
---
---@param origin garrysmod.Vector The position to make clients think this entity is at.
function Entity:SetNetworkOrigin( origin ) end

--- [CLIENT]
---
--- Sets the next time the clientside [ENTITY:Think](https://wiki.facepunch.com/gmod/ENTITY:Think) is called.
---
---@param next_think number The next time, relative to [Global.CurTime](https://wiki.facepunch.com/gmod/Global.CurTime), to execute the [ENTITY:Think](https://wiki.facepunch.com/gmod/ENTITY:Think) clientside.
function Entity:SetNextClientThink( next_think ) end

--- [SHARED]
---
--- Sets if the entity's model should render at all.
---
--- If set on the server, this entity will no longer network to clients, and for all intents and purposes cease to exist clientside.
---
--- The entity can still be manually rendered via [Entity:DrawModel](https://wiki.facepunch.com/gmod/Entity:DrawModel) in appropriate hooks.
---
---@param should_not_draw boolean true disables drawing
function Entity:SetNoDraw( should_not_draw ) end

--- [SHARED]
---
--- Sets whether the entity is solid or not.
---
---@param is_not_solid boolean True will make the entity not solid, false will make it solid.
function Entity:SetNotSolid( is_not_solid ) end

--- [SHARED]
---
--- Sets a networked angle value on the entity.
---
--- The value can then be accessed with [Entity:GetNW2Angle](https://wiki.facepunch.com/gmod/Entity:GetNW2Angle) both from client and server.
---
--- > WARNING: The value will only be updated clientside if the entity is or enters the clients PVS. use [Entity:SetNWAngle](https://wiki.facepunch.com/gmod/Entity:SetNWAngle) instead
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
--- > The value will only be networked if it isn't the same as the current value and unlike SetNW*
--- > the value will only be networked once and not every 10 seconds.
---
---@param key string The key to associate the value with
---@param value garrysmod.Angle The value to set
function Entity:SetNW2Angle( key, value ) end

--- [SHARED]
---
--- Sets a networked boolean value on the entity.
---
--- The value can then be accessed with [Entity:GetNW2Bool](https://wiki.facepunch.com/gmod/Entity:GetNW2Bool) both from client and server.
---
--- > BUG: You should not use the NW2 System on entities that are based on a Lua Entity or else NW2Vars could get mixed up, updated multiple times or not be set.
--- > See [issue #5455](https://github.com/Facepunch/garrysmod-issues/issues/5455).
---
--- > WARNING: The value will only be updated clientside if the entity is or enters the clients PVS. use [Entity:SetNWBool](https://wiki.facepunch.com/gmod/Entity:SetNWBool) instead
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
--- > The value will only be networked if it isn't the same as the current value and unlike SetNW*
--- > the value will only be networked once and not every 10 seconds.
---
---@param key string The key to associate the value with
---@param value boolean The value to set
function Entity:SetNW2Bool( key, value ) end

--- [SHARED]
---
--- Sets a networked entity value on the entity.
---
--- The value can then be accessed with [Entity:GetNW2Entity](https://wiki.facepunch.com/gmod/Entity:GetNW2Entity) both from client and server.
---
--- > BUG: You should not use the NW2 System on entities that are based on a Lua Entity or else NW2Vars could get mixed up, updated multiple times or not be set.
--- > See [issue #5455](https://github.com/Facepunch/garrysmod-issues/issues/5455).
---
--- > WARNING: The value will only be updated clientside if the entity is or enters the clients PVS. use [Entity:SetNWEntity](https://wiki.facepunch.com/gmod/Entity:SetNWEntity) instead
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
--- > The value will only be networked if it isn't the same as the current value and unlike SetNW*
--- > the value will only be networked once and not every 10 seconds.
---
---@param key string The key to associate the value with
---@param value garrysmod.Entity The value to set
function Entity:SetNW2Entity( key, value ) end

--- [SHARED]
---
--- Sets a networked float (number) value on the entity.
---
--- The value can then be accessed with [Entity:GetNW2Float](https://wiki.facepunch.com/gmod/Entity:GetNW2Float) both from client and server.
---
--- Unlike [Entity:SetNW2Int](https://wiki.facepunch.com/gmod/Entity:SetNW2Int), floats don't have to be whole numbers.
---
--- > BUG: You should not use the NW2 System on entities that are based on a Lua Entity or else NW2Vars could get mixed up, updated multiple times or not be set.
--- > See [issue #5455](https://github.com/Facepunch/garrysmod-issues/issues/5455).
---
--- > WARNING: The value will only be updated clientside if the entity is or enters the clients PVS. use [Entity:SetNWFloat](https://wiki.facepunch.com/gmod/Entity:SetNWFloat) instead
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
--- > The value will only be networked if it isn't the same as the current value and unlike SetNW*
--- > the value will only be networked once and not every 10 seconds.
---
---@param key string The key to associate the value with
---@param value number The value to set
function Entity:SetNW2Float( key, value ) end

--- [SHARED]
---
--- Sets a networked integer (whole number) value on the entity.
---
--- The value can then be accessed with [Entity:GetNW2Int](https://wiki.facepunch.com/gmod/Entity:GetNW2Int) both from client and server.
---
--- See [Entity:SetNW2Float](https://wiki.facepunch.com/gmod/Entity:SetNW2Float) for numbers that aren't integers.
---
--- > BUG: You should not use the NW2 System on entities that are based on a Lua Entity or else NW2Vars could get mixed up, updated multiple times or not be set.
--- > See [issue #5455](https://github.com/Facepunch/garrysmod-issues/issues/5455).
---
--- > WARNING: The value will only be updated clientside if the entity is or enters the clients PVS.
--- > The integer has a 32 bit limit. Use [Entity:SetNWInt](https://wiki.facepunch.com/gmod/Entity:SetNWInt) instead
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
--- > The value will only be networked if it isn't the same as the current value and unlike SetNW*
--- > the value will only be networked once and not every 10 seconds.
---
---@param key string The key to associate the value with
---@param value integer The value to set
function Entity:SetNW2Int( key, value ) end

--- [SHARED]
---
--- Sets a networked string value on the entity.
---
--- The value can then be accessed with [Entity:GetNW2String](https://wiki.facepunch.com/gmod/Entity:GetNW2String) both from client and server.
---
--- > BUG: You should not use the NW2 System on entities that are based on a Lua Entity or else NW2Vars could get mixed up, updated multiple times or not be set.
--- > See [issue #5455](https://github.com/Facepunch/garrysmod-issues/issues/5455).
---
--- > WARNING: The value will only be updated clientside if the entity is or enters the clients PVS. use [Entity:SetNWString](https://wiki.facepunch.com/gmod/Entity:SetNWString) instead
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
--- > The value will only be networked if it isn't the same as the current value and unlike SetNW*
--- > the value will only be networked once and not every 10 seconds.
---
---@param key string The key to associate the value with, up to 1023 characters
---@param value string The value to set, up to 511 characters.
function Entity:SetNW2String( key, value ) end

--- [SHARED]
---
--- Sets a networked value on the entity.
---
--- The value can then be accessed with [Entity:GetNW2Var](https://wiki.facepunch.com/gmod/Entity:GetNW2Var) both from client and server.
---
--- | Allowed Types   |
--- | --------------- |
--- | Angle           |
--- | Boolean         |
--- | Entity          |
--- | Float           |
--- | Int             |
--- | String          |
--- | Vector          |
---
--- > WARNING: Trying to network a type that is not listed above leads to the value not being networked!
--- > the value will only be updated clientside if the entity is or enters the clients PVS.
---
--- > BUG: You should not use the NW2 System on entities that are based on a Lua Entity or else NW2Vars could get mixed up, updated multiple times or not be set.
--- > See [issue #5455](https://github.com/Facepunch/garrysmod-issues/issues/5455).
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
--- > The value will only be networked if it isn't the same as the current value and unlike SetNW*
--- > the value will only be networked once and not every 10 seconds.
---
---@param key string The key to associate the value with
---@param value any The value to set
function Entity:SetNW2Var( key, value ) end

--- [SHARED]
---
--- Sets a networked vector value on the entity.
---
--- The value can then be accessed with [Entity:GetNW2Vector](https://wiki.facepunch.com/gmod/Entity:GetNW2Vector) both from client and server.
---
--- > BUG: You should not use the NW2 System on entities that are based on a Lua Entity or else NW2Vars could get mixed up, updated multiple times or not be set.
--- > See [issue #5455](https://github.com/Facepunch/garrysmod-issues/issues/5455).
---
--- > WARNING: The value will only be updated clientside if the entity is or enters the clients PVS. use [Entity:SetNWVector](https://wiki.facepunch.com/gmod/Entity:SetNWVector) instead
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
--- > The value will only be networked if it isn't the same as the current value and unlike SetNW*
--- > the value will only be networked once and not every 10 seconds.
---
---@param key string The key to associate the value with
---@param value garrysmod.Vector The value to set
function Entity:SetNW2Vector( key, value ) end

--- [SHARED]
---
--- Sets a networked angle value on the entity.
---
--- The value can then be accessed with [Entity:GetNWAngle](https://wiki.facepunch.com/gmod/Entity:GetNWAngle) both from client and server.
---
--- > WARNING: There's a 4095 slots Network limit. If you need more, consider using the [net](https://wiki.facepunch.com/gmod/net) library or [Entity:SetNW2Angle](https://wiki.facepunch.com/gmod/Entity:SetNW2Angle). You should also consider the fact that you have way too many variables. You can learn more about this limit here: [Networking_Usage#nwlimits](https://wiki.facepunch.com/gmod/Networking_Usage#nwlimits)
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
---
---@param key string The key to associate the value with
---@param value garrysmod.Angle The value to set
function Entity:SetNWAngle( key, value ) end

--- [SHARED]
---
--- Sets a networked boolean value on the entity.
---
--- The value can then be accessed with [Entity:GetNWBool](https://wiki.facepunch.com/gmod/Entity:GetNWBool) both from client and server.
---
--- > WARNING: There's a 4096 slots Network limit. If you need more, consider using the [net](https://wiki.facepunch.com/gmod/net) library or [Entity:SetNW2Bool](https://wiki.facepunch.com/gmod/Entity:SetNW2Bool). You should also consider the fact that you have way too many variables. You can learn more about this limit here: [Networking_Usage#nwlimits](https://wiki.facepunch.com/gmod/Networking_Usage#nwlimits)
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
---
---@param key string The key to associate the value with
---@param value boolean The value to set
function Entity:SetNWBool( key, value ) end

--- [SHARED]
---
--- Sets a networked entity value on the entity.
---
--- The value can then be accessed with [Entity:GetNWEntity](https://wiki.facepunch.com/gmod/Entity:GetNWEntity) both from client and server.
---
--- > WARNING: There's a 4096 slots Network limit. If you need more, consider using the [net](https://wiki.facepunch.com/gmod/net) library or [Entity:SetNW2Entity](https://wiki.facepunch.com/gmod/Entity:SetNW2Entity). You should also consider the fact that you have way too many variables. You can learn more about this limit here: [Networking_Usage#nwlimits](https://wiki.facepunch.com/gmod/Networking_Usage#nwlimits)
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
---
---@param key string The key to associate the value with
---@param value garrysmod.Entity The value to set
function Entity:SetNWEntity( key, value ) end

--- [SHARED]
---
--- Sets a networked float (number) value on the entity.
---
--- The value can then be accessed with [Entity:GetNWFloat](https://wiki.facepunch.com/gmod/Entity:GetNWFloat) both from client and server.
---
--- Unlike [Entity:SetNWInt](https://wiki.facepunch.com/gmod/Entity:SetNWInt), floats don't have to be whole numbers.
---
--- > WARNING: There's a 4095 slots Network limit. If you need more, consider using the [net](https://wiki.facepunch.com/gmod/net) library or [Entity:SetNW2Float](https://wiki.facepunch.com/gmod/Entity:SetNW2Float). You should also consider the fact that you have way too many variables. You can learn more about this limit here: [Networking_Usage#nwlimits](https://wiki.facepunch.com/gmod/Networking_Usage#nwlimits)
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
---
---@param key string The key to associate the value with
---@param value number The value to set
function Entity:SetNWFloat( key, value ) end

--- [SHARED]
---
--- Sets a networked integer (whole number) value on the entity.
---
--- The value can then be accessed with [Entity:GetNWInt](https://wiki.facepunch.com/gmod/Entity:GetNWInt) both from client and server.
---
--- See [Entity:SetNWFloat](https://wiki.facepunch.com/gmod/Entity:SetNWFloat) for numbers that aren't integers.
---
--- > WARNING: There's a 4095 slots Network limit. If you need more, consider using the [net](https://wiki.facepunch.com/gmod/net) library or [Entity:SetNW2Int](https://wiki.facepunch.com/gmod/Entity:SetNW2Int). You should also consider the fact that you have way too many variables. You can learn more about this limit here: [Networking_Usage#nwlimits](https://wiki.facepunch.com/gmod/Networking_Usage#nwlimits)
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
---
--- > BUG: This function will not round decimal values as it actually networks a float internally.
--- > See [issue #3374](https://github.com/Facepunch/garrysmod-issues/issues/3374).
---
---@param key string The key to associate the value with
---@param value integer The value to set
function Entity:SetNWInt( key, value ) end

--- [SHARED]
---
--- Sets a networked string value on the entity.
---
--- The value can then be accessed with [Entity:GetNWString](https://wiki.facepunch.com/gmod/Entity:GetNWString) both from client and server.
---
--- > WARNING: There's a 4095 slots Network limit. If you need more, consider using the [net](https://wiki.facepunch.com/gmod/net) library or [Entity:SetNW2String](https://wiki.facepunch.com/gmod/Entity:SetNW2String). You should also consider the fact that you have way too many variables. You can learn more about this limit here: [Networking_Usage#nwlimits](https://wiki.facepunch.com/gmod/Networking_Usage#nwlimits)
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
---
---@param key string The key to associate the value with
---@param value string The value to set, up to 199 characters.
function Entity:SetNWString( key, value ) end

--- [SHARED]
---
--- > NOTE: Only one NWVarProxy can be set per-var
--- > Running this function will only set it for the realm it is called on.
---
--- Sets a function to be called when the NWVar changes.
---
---@param key string The key of the NWVar to add callback for.
---@param callback fun( ent: garrysmod.Entity, name: string, oldval: any, newval: any ) The function to be called when the NWVar changes.
function Entity:SetNWVarProxy( key, callback ) end

--- [SHARED]
---
--- Sets a networked vector value on the entity.
---
--- The value can then be accessed with [Entity:GetNWVector](https://wiki.facepunch.com/gmod/Entity:GetNWVector) both from client and server.
---
--- > WARNING: There's a 4095 slots Network limit. If you need more, consider using the [net](https://wiki.facepunch.com/gmod/net) library or [Entity:SetNW2Vector](https://wiki.facepunch.com/gmod/Entity:SetNW2Vector). You should also consider the fact that you have way too many variables. You can learn more about this limit here: [Networking_Usage#nwlimits](https://wiki.facepunch.com/gmod/Networking_Usage#nwlimits)
---
--- > NOTE: Running this function clientside will only set it for the client it is called on.
---
---@param key string The key to associate the value with
---@param value garrysmod.Vector The value to set
function Entity:SetNWVector( key, value ) end

--- [SHARED]
---
--- Sets the owner of this entity, disabling all physics interaction with it.
---
--- > NOTE: This function is generally used to disable physics interactions on projectiles being fired by their owner, but can also be used for normal ownership in case physics interactions are not involved at all. The Gravity gun will be able to pick up the entity even if the owner can't collide with it, the Physics gun however will not.
---
---@param owner garrysmod.Entity? The entity to be set as owner. Defaults to `NULL`.
function Entity:SetOwner( owner ) end

--- [SHARED]
---
--- Sets the parent of this entity, making it move with its parent. This will make the child entity non solid, nothing can interact with them, including traces (but [util.TraceHull](https://wiki.facepunch.com/gmod/util.TraceHull) will work).
---
--- All children of the parent get removed whenever it gets removed.
---
--- > NOTE: This does not work on [the world](https://wiki.facepunch.com/gmod/game.GetWorld).
---
--- > WARNING: This can cause undefined physics behavior when used on entities that don't support parenting. See the [Valve developer wiki](https://developer.valvesoftware.com/wiki/Entity_Hierarchy_(parenting)) for more information.
---
--- > NOTE: (`attachment_or_bone_id` argument) You must call [Entity:SetMoveType](https://wiki.facepunch.com/gmod/Entity:SetMoveType)( MOVETYPE_NONE ) on the child for this argument to have any effect!
---
--- > NOTE: (`attachment_or_bone_id` argument) Parenting to attachment IDs more than `255` is unsupported and will output a LUA error.
---
---@param parent garrysmod.Entity? The entity to parent to. Setting this to nil will clear the parent. Defaults to `NULL`.
---@param attachment_or_bone_id integer? The attachment or bone id to use when parenting. Defaults to -1 or whatever the parent had set previously. Use [Entity:AddEffects](https://wiki.facepunch.com/gmod/Entity:AddEffects)( EF_FOLLOWBONE ) to treat this argument as a Bone ID instead of an Attachment ID. Similar to [Entity:FollowBone](https://wiki.facepunch.com/gmod/Entity:FollowBone).
function Entity:SetParent( parent, attachment_or_bone_id ) end

--- [SHARED]
---
--- Sets the parent of an entity to another entity with the given physics bone number. Similar to [Entity:SetParent](https://wiki.facepunch.com/gmod/Entity:SetParent), except it is parented to a physbone. This function is useful mainly for ragdolls.
---
--- > NOTE: Despite this function being available server side, it doesn't actually do anything server side.
---
---@param bone integer Physics bone number to attach to. Use 0 for objects with only one physics bone. (See [Entity:GetPhysicsObjectNum](https://wiki.facepunch.com/gmod/Entity:GetPhysicsObjectNum))
function Entity:SetParentPhysNum( bone ) end

--- [SHARED]
---
--- Sets whether or not the given entity is persistent. A persistent entity will be saved on server shutdown and loaded back when the server starts up. Additionally, by default persistent entities cannot be grabbed with the physgun and tools cannot be used on them.
---
--- In sandbox, this can be set on an entity by opening the context menu, right clicking the entity, and choosing `"Make Persistent"`.
---
--- > NOTE: Persistence can only be enabled with the sbox_persist convar, which works as an identifier for the current set of persistent entities. An empty identifier (which is the default value) disables this feature.
---
---@param persist boolean Whether or not the entity should be persistent.
function Entity:SetPersistent( persist ) end

--- [SERVER]
---
--- When called on a constraint entity, sets the two physics objects to be constrained.
---
--- Usage is not recommended as the Constraint library provides easier ways to deal with constraints.
---
---@param phys1 garrysmod.Physics The first physics object to be constrained.
---@param phys2 garrysmod.Physics The second physics object to be constrained.
function Entity:SetPhysConstraintObjects( phys1, phys2 ) end

--- [SERVER]
---
--- Sets the player who gets credit if this entity kills something with physics damage within the time limit.
---
--- > NOTE: Only functional on props, "anim" type SENTs, vehicles and a few other select entities.
---
---@param attacker garrysmod.Player Player who gets the kills. Setting this to a non-player entity will not work.
---@param time_limit number? Time in seconds until the entity forgets its physics attacker and prevents it from getting the kill credit. Defaults to `5`.
function Entity:SetPhysicsAttacker( attacker, time_limit ) end

--- [SHARED]
---
--- Allows you to set how fast an entity's animation will play, with 1.0 being the default speed.
---
--- It is networked to clients, but limited to [-4,12] range when networking.
---
--- > NOTE: This function does not affect gestures.
--- > Use [Entity:SetLayerPlaybackRate](https://wiki.facepunch.com/gmod/Entity:SetLayerPlaybackRate) instead.
---
---@param speed number How fast the animation will play.
function Entity:SetPlaybackRate( speed ) end

--- [SHARED]
---
--- Moves the entity to the specified position.
---
--- Some entities, such as ragdolls, will continually reset their position. Consider using [PhysObj:SetPos](https://wiki.facepunch.com/gmod/PhysObj:SetPos) on every physics object to move ragdolls.
---
--- > NOTE: If the new position doesn't take effect right away, you can use [Entity:SetupBones](https://wiki.facepunch.com/gmod/Entity:SetupBones) to force it to do so. This issue is especially common when trying to render the same entity twice or more in a single frame at different positions.
---
--- > WARNING: Entities with [Entity:GetSolid](https://wiki.facepunch.com/gmod/Entity:GetSolid) of `SOLID_BBOX` will have their angles reset!
---
--- > BUG: This will fail inside of predicted functions called during player movement processing. This includes [WEAPON:PrimaryAttack](https://wiki.facepunch.com/gmod/WEAPON:PrimaryAttack) and [WEAPON:Think](https://wiki.facepunch.com/gmod/WEAPON:Think).
--- > See [issue #2447](https://github.com/Facepunch/garrysmod-issues/issues/2447).
---
---@param position garrysmod.Vector The position to move the entity to.
function Entity:SetPos( position ) end

--- [SHARED]
---
--- Sets the specified pose parameter to the specified value.
---
--- You should call [Entity:InvalidateBoneCache](https://wiki.facepunch.com/gmod/Entity:InvalidateBoneCache) after calling this function.
---
--- > NOTE: Avoid calling this in draw hooks, especially when animating things, as it might cause visual artifacts.
---
---@param pose_name string Name of the pose parameter. [Entity:GetPoseParameterName](https://wiki.facepunch.com/gmod/Entity:GetPoseParameterName) might come in handy here. Can also be a pose parameter ID.
---@param pose_value number The value to set the pose to.
function Entity:SetPoseParameter( pose_name, pose_value ) end

--- [CLIENT]
---
--- Sets whether an entity should be predictable or not.
--- When an entity is set as predictable, its DT vars can be changed during predicted hooks. This is useful for entities which can be controlled by player input.
---
--- Any datatable value that mismatches from the server will be overridden and a prediction error will be spewed.
---
--- Weapons are predictable by default, and the drive system uses this function to make the controlled prop predictable as well.
---
--- Visit  for a list of all predicted hooks, and the [Prediction](https://wiki.facepunch.com/gmod/Prediction) page.
--- For further technical information on the subject, visit [valve's wiki](https://developer.valvesoftware.com/wiki/Prediction).
---
--- > NOTE: This function resets the datatable variables everytime it's called, it should ideally be called when a player starts using the entity and when he stops
---
--- > NOTE: Entities set as predictable with this function will be unmarked when the user lags and receives a full packet update, to handle such case visit [GM:NotifyShouldTransmit](https://wiki.facepunch.com/gmod/GM:NotifyShouldTransmit)
---
---@param set_predictable boolean whether to make this entity predictable or not.
function Entity:SetPredictable( set_predictable ) end

--- [SERVER]
---
--- Prevents the server from sending any further information about the entity to a player.
---
--- > NOTE: You must also call this function on all entity's children. See [Entity:GetChildren](https://wiki.facepunch.com/gmod/Entity:GetChildren).
--- >
--- > [issue tracker](https://github.com/Facepunch/garrysmod-issues/issues/1736)
--- >
--- > [Entity:SetFlexScale](https://wiki.facepunch.com/gmod/Entity:SetFlexScale) and other flex/bone manipulation functions will create a child entity.
---
---@param target garrysmod.Player | garrysmod.RecipientFilter | garrysmod.Player[] The player to stop networking the entity to. Can also be a [CRecipientFilter](https://wiki.facepunch.com/gmod/CRecipientFilter) or a [table](https://wiki.facepunch.com/gmod/table) as of March 2024 to affect multiple players at once.
---@param stop_transmitting boolean true to stop the entity from networking, false to make it network again.
function Entity:SetPreventTransmit( target, stop_transmitting ) end

--- [SERVER]
---
--- Sets the bone angles. This is used alongside Kinect in [Entity:SetRagdollBuildFunction](https://wiki.facepunch.com/gmod/Entity:SetRagdollBuildFunction), for more info see ragdoll_motion entity.
---
---@param bone_id integer Bone ID
---@param angles garrysmod.Angle Angle to set
function Entity:SetRagdollAng( bone_id, angles ) end

--- [SERVER]
---
--- Sets the function to build the ragdoll. This is used alongside Kinect, for more info see `ragdoll_motion` entity in the game files.
---
---@param builder fun( ragdoll: garrysmod.Entity ) The build function.
function Entity:SetRagdollBuildFunction( builder ) end

--- [SERVER]
---
--- Sets the bone position. This is used alongside Kinect in [Entity:SetRagdollBuildFunction](https://wiki.facepunch.com/gmod/Entity:SetRagdollBuildFunction), for more info see ragdoll_motion entity.
---
---@param bone_id integer Bone ID
---@param position garrysmod.Vector Position to set
function Entity:SetRagdollPos( bone_id, position ) end

--- [CLIENT]
---
--- Sets the render bounds for the entity.
---
--- For world space coordinate alternative see [Entity:SetRenderBoundsWS](https://wiki.facepunch.com/gmod/Entity:SetRenderBoundsWS).
---
---@param mins garrysmod.Vector The minimum corner of the bounds, relative to origin of the entity.
---@param maxs garrysmod.Vector The maximum corner of the bounds, relative to origin of the entity.
---@param add garrysmod.Vector? If defined, adds this vector to maxs and subtracts this vector from mins. Defaults to `Vector( 0, 0, 0 )`.
function Entity:SetRenderBounds( mins, maxs, add ) end

--- [CLIENT]
---
--- Sets the render bounds for the entity in world space coordinates. For relative coordinates see [Entity:SetRenderBounds](https://wiki.facepunch.com/gmod/Entity:SetRenderBounds).
---
---@param mins garrysmod.Vector The minimum corner of the bounds, relative to origin of the world/map.
---@param maxs garrysmod.Vector The maximum corner of the bounds, relative to origin of the world/map.
---@param add garrysmod.Vector? If defined, adds this vector to maxs and subtracts this vector from mins. Defaults to `Vector( 0, 0, 0 )`.
function Entity:SetRenderBoundsWS( mins, maxs, add ) end

--- [CLIENT]
---
--- Used to specify a plane, past which an object will be visually clipped.
---
---@param plane_normal garrysmod.Vector The normal of the plane. Anything behind the normal will be clipped.
---@param plane_position number The position of the plane.
function Entity:SetRenderClipPlane( plane_normal, plane_position ) end

--- [CLIENT]
---
--- Enables the use of clipping planes to "cut" objects.
---
---@param enabled boolean Enable or disable clipping planes
function Entity:SetRenderClipPlaneEnabled( enabled ) end

--- [SHARED]
---
--- Sets entity's render FX. Requires the entitys rendermode to support transparency.
---
---@param render_fx integer The new render FX to set, see [Enums/kRenderFx](https://wiki.facepunch.com/gmod/Enums/kRenderFx)
function Entity:SetRenderFX( render_fx ) end

--- [SHARED]
---
--- Sets the render mode of the entity.
---
---@param render_mode integer New render mode to set, see [Enums/RENDERMODE](https://wiki.facepunch.com/gmod/Enums/RENDERMODE).
function Entity:SetRenderMode( render_mode ) end

--- [SHARED]
---
--- Sets a save value for an entity. You can see a full list of an entity's save values by creating it and printing [Entity:GetSaveTable](https://wiki.facepunch.com/gmod/Entity:GetSaveTable).
---
--- See [Entity:GetInternalVariable](https://wiki.facepunch.com/gmod/Entity:GetInternalVariable) for the opposite of this function.
---
---@param name string Name of the save value to set
---@param value any Value to set
---@return boolean success Key successfully set
function Entity:SetSaveValue( name, value ) end

--- [SHARED]
---
--- Sets the entity's model sequence.
---
--- If the specified sequence is already active, the animation will not be restarted. See [Entity:ResetSequence](https://wiki.facepunch.com/gmod/Entity:ResetSequence) for a function that restarts the animation even if it is already playing.
---
--- In some cases you want to run [Entity:ResetSequenceInfo](https://wiki.facepunch.com/gmod/Entity:ResetSequenceInfo) to make this function run.
---
--- > NOTE: This will not work properly if called directly after calling [Entity:SetModel](https://wiki.facepunch.com/gmod/Entity:SetModel). Consider waiting until the next Tick.
--- >
--- > Will not work on players due to the animations being reset every frame by the base gamemode animation system. See [GM:CalcMainActivity](https://wiki.facepunch.com/gmod/GM:CalcMainActivity).
--- >
--- > For custom scripted entities you will want to apply example from [ENTITY:Think](https://wiki.facepunch.com/gmod/ENTITY:Think) to make animations work.
---
---@param sequence integer | string The sequence to play. If set to a number, the input is treated as the sequence ID. If set to a string, the function will automatically call [Entity:LookupSequence](https://wiki.facepunch.com/gmod/Entity:LookupSequence) to retrieve the sequence ID.
---@return number duration The length of the sequence.
function Entity:SetSequence( sequence ) end

--- [SHARED]
---
--- Sets if entity should create a server ragdoll on death or a client one.
---
--- > NOTE: This is reset for players when they respawn ([Entity:Spawn](https://wiki.facepunch.com/gmod/Entity:Spawn)).
--- >
--- > Player ragdolls created with this enabled will have an owner set, see [Entity:SetOwner](https://wiki.facepunch.com/gmod/Entity:SetOwner) for more information on what effects this has.
---
---@param server_ragdoll boolean Set `true` if ragdoll should be created on server, `false` if on client.
function Entity:SetShouldServerRagdoll( server_ragdoll ) end

--- [SHARED]
---
--- Sets the skin of the entity.
---
--- [Entity:GetSkin](https://wiki.facepunch.com/gmod/Entity:GetSkin) returns current skin and [Entity:SkinCount](https://wiki.facepunch.com/gmod/Entity:SkinCount) returns amount of skins.
---
---@param skin_index integer 0-based index of the skin to use.
function Entity:SetSkin( skin_index ) end

--- [SHARED]
---
--- Sets the solidity of an entity.
---
---@param solid_type integer The solid type. See the [Enums/SOLID](https://wiki.facepunch.com/gmod/Enums/SOLID).
function Entity:SetSolid( solid_type ) end

--- [SHARED]
---
--- Sets solid flag(s) for the entity.
---
--- This overrides any other flags the entity might have had. See [Entity:AddSolidFlags](https://wiki.facepunch.com/gmod/Entity:AddSolidFlags) for adding flags.
---
---@param flags integer The flag(s) to set, see [Enums/FSOLID](https://wiki.facepunch.com/gmod/Enums/FSOLID).
function Entity:SetSolidFlags( flags ) end

--- [SHARED]
---
--- Sets whether the entity should use a spawn effect when it is created on the client.
---
--- See [Entity:GetSpawnEffect](https://wiki.facepunch.com/gmod/Entity:GetSpawnEffect) for more information on how the effect is applied.
---
--- > NOTE: This function will only have an effect when the entity spawns. After that it will do nothing even is set to true.
---
---@param spawn_effect boolean Sets if we should show a spawn effect.
function Entity:SetSpawnEffect( spawn_effect ) end

--- [SHARED]
---
--- Overrides a single material on the model of this entity.
---
--- To set a Lua material created with [Global.CreateMaterial](https://wiki.facepunch.com/gmod/Global.CreateMaterial), just prepend a `!` to the material name.
---
--- > NOTE (needs validation): The index argument limit seems to be larger than 0 to 31.
---
--- > BUG: The server's value takes priority on the client.
--- > See [issue #3362](https://github.com/Facepunch/garrysmod-issues/issues/3362).
---
--- > NOTE: (`index` argument) If called with no arguments, all sub materials will be reset.
---
---@param index integer? Index of the material to override, acceptable values are from `0` to `31`. Indexes are by [Entity:GetMaterials](https://wiki.facepunch.com/gmod/Entity:GetMaterials), but you have to subtract `1` from them.
---@param material string? The material to override the default one with. Set to [nil](https://wiki.facepunch.com/gmod/nil) to revert to default material.
function Entity:SetSubMaterial( index, material ) end

--- [SHARED]
---
--- Sets the axis-aligned bounding box (AABB) for an entity's hitbox detection.
---
--- See also [Entity:SetSurroundingBoundsType](https://wiki.facepunch.com/gmod/Entity:SetSurroundingBoundsType) (mutually exclusive).
---
---@param mins garrysmod.Vector Minimum extent of the AABB relative to entity's position.
---@param maxs garrysmod.Vector Maximum extent of the AABB relative to entity's position.
function Entity:SetSurroundingBounds( mins, maxs ) end

--- [SHARED]
---
--- Automatically sets the axis-aligned bounding box (AABB) for an entity's hitbox detection.
---
--- See also [Entity:SetSurroundingBounds](https://wiki.facepunch.com/gmod/Entity:SetSurroundingBounds) (mutually exclusive).
---
---@param bounds integer Bounds type of the entity, see [Enums/BOUNDS](https://wiki.facepunch.com/gmod/Enums/BOUNDS)
function Entity:SetSurroundingBoundsType( bounds ) end

--- [SHARED]
---
--- Changes the table that can be accessed by indexing an entity. Each entity starts with its own table by default.
---
---@param data table Table for the entity to use
function Entity:SetTable( data ) end

--- [SHARED]
---
--- When this flag is set the entity will only transmit to the player when its parent is transmitted. This is useful for things like viewmodel attachments since without this flag they will transmit to everyone (and cause the viewmodels to transmit to everyone too).
---
--- > NOTE: In the case of scripted entities, this will override [ENTITY:UpdateTransmitState](https://wiki.facepunch.com/gmod/ENTITY:UpdateTransmitState)
---
---@param enabled boolean Will set the TransmitWithParent flag on or off
function Entity:SetTransmitWithParent( enabled ) end

--- [SERVER]
---
--- Marks the entity as a trigger, so it will generate [ENTITY:StartTouch](https://wiki.facepunch.com/gmod/ENTITY:StartTouch), [ENTITY:Touch](https://wiki.facepunch.com/gmod/ENTITY:Touch) and [ENTITY:EndTouch](https://wiki.facepunch.com/gmod/ENTITY:EndTouch) callbacks.
---
--- Internally this is stored as [FSOLID_TRIGGER](https://wiki.facepunch.com/gmod/Enums/FSOLID) flag.
---
---@param is_trigger boolean Make the entity trigger or not
function Entity:SetTrigger( is_trigger ) end

--- [CLIENT]
---
--- Forces the entity to reconfigure its bones. You might need to call this after changing your model's scales or when manually drawing the entity multiple times at different positions.
---
--- > NOTE: This calls the BuildBonePositions callback added via [Entity:AddCallback](https://wiki.facepunch.com/gmod/Entity:AddCallback), so avoid calling this function inside it to prevent an infinite loop.
---
function Entity:SetupBones() end

--- [CLIENT]
---
--- Initializes the class names of an entity's phoneme mappings (mouth movement data). This is called by default with argument "phonemes" when a flex-based entity (such as an [NPC](https://wiki.facepunch.com/gmod/NPC)) is created.
---
--- > NOTE: TF2 phonemes can be accessed by using a path such as "player/scout/phonemes/phonemes" , check TF2's "tf2_misc_dir.vpk" with GCFScape for other paths, however it seems that TF2 sounds don't contain phoneme definitions anymore after being converted to mp3 and only rely on VCD animations, this needs to be further investigated
---
---@param file_root string The file prefix of the phoneme mappings (relative to "garrysmod/expressions/").
function Entity:SetupPhonemeMappings( file_root ) end

--- [SERVER]
---
--- Sets the use type of an entity, affecting how often [ENTITY:Use](https://wiki.facepunch.com/gmod/ENTITY:Use) will be called for Lua entities.
---
---@param use_type integer The use type to apply to the entity. See [Enums/_USE](https://wiki.facepunch.com/gmod/Enums/_USE).
function Entity:SetUseType( use_type ) end

--- [SHARED]
---
--- Sets the entity's velocity. For entities with physics, consider using [PhysObj:SetVelocity](https://wiki.facepunch.com/gmod/PhysObj:SetVelocity) on the [PhysObj](https://wiki.facepunch.com/gmod/PhysObj) of the entity.
---
--- > NOTE: Actually binds to CBaseEntity::SetBaseVelocity() which sets the entity's velocity due to forces applied by other entities.
---
--- > WARNING: If applied to a player, this will actually **ADD** velocity, not set it. (due to how movement code handles base velocity)
---
---@param velocity garrysmod.Vector The new velocity to set.
function Entity:SetVelocity( velocity ) end

--- [SHARED]
---
--- Sets the model and associated weapon to this viewmodel entity.
---
--- This is used internally when the player switches weapon.
---
--- > NOTE: View models are not drawn without a weapons associated to them.
---
--- > WARNING: This will silently fail if the entity is not a viewmodel.
---
---@param view_model string The model string to give to this viewmodel. Example: "models/weapons/c_smg1.mdl"
---@param weapon garrysmod.Weapon? The weapon entity to associate this viewmodel to. Defaults to `NULL`.
function Entity:SetWeaponModel( view_model, weapon ) end

--- [SHARED]
---
--- Returns the amount of skins the entity has.
---
--- To set the entity's skin, use [Entity:SetSkin](https://wiki.facepunch.com/gmod/Entity:SetSkin).
--- To retrieve the total number of skins without an entity, see [util.GetModelInfo](https://wiki.facepunch.com/gmod/util.GetModelInfo).
---
---@return integer skin_count The amount of skins the entity's model has.
function Entity:SkinCount() end

--- [CLIENT]
---
--- Moves the model instance from the source entity to this entity. This can be used to transfer decals that have been applied on one entity to another.
---
--- Both entities must have the same model.
---
---@param source_entity garrysmod.Entity Entity to move the model instance from.
---@return boolean success Whether the operation was successful or not
function Entity:SnatchModelInstance( source_entity ) end

--- [SHARED]
---
--- Initializes the entity and starts its networking. If called on a player, it will respawn them.
---
--- This calls [ENTITY:Initialize](https://wiki.facepunch.com/gmod/ENTITY:Initialize) on Lua-defined entities.
---
function Entity:Spawn() end

--- [SHARED]
---
--- Starts a "looping" sound. As with any other sound playing methods, this function expects the sound file to be looping itself and will not automatically loop a non looping sound file as one might expect.
---
--- This function is almost identical to [Global.CreateSound](https://wiki.facepunch.com/gmod/Global.CreateSound), with the exception of the sound being created in the STATIC channel and with normal attenuation.
---
--- See also [Entity:StopLoopingSound](https://wiki.facepunch.com/gmod/Entity:StopLoopingSound)
---
---@param sound_name string Sound to play. Can be either a sound script or a filepath.
---@return integer sound_id The ID number of started sound starting with 0, or -1 if we failed for some reason.
function Entity:StartLoopingSound( sound_name ) end

--- [SHARED]
---
--- Starts a motion controller in the physics engine tied to this entity's [PhysObj](https://wiki.facepunch.com/gmod/PhysObj), which enables the use of [ENTITY:PhysicsSimulate](https://wiki.facepunch.com/gmod/ENTITY:PhysicsSimulate).
---
--- The motion controller can later be destroyed via [Entity:StopMotionController](https://wiki.facepunch.com/gmod/Entity:StopMotionController).
---
--- Motion controllers are used internally to control other Entities' [PhysObj](https://wiki.facepunch.com/gmod/PhysObj)ects, such as the Gravity Gun, +use pickup and the Physics Gun.
---
--- This function should be called every time you recreate the Entity's [PhysObj](https://wiki.facepunch.com/gmod/PhysObj). Or alternatively you should call [Entity:AddToMotionController](https://wiki.facepunch.com/gmod/Entity:AddToMotionController) on the new [PhysObj](https://wiki.facepunch.com/gmod/PhysObj).
---
--- Also see [Entity:AddToMotionController](https://wiki.facepunch.com/gmod/Entity:AddToMotionController) and [Entity:RemoveFromMotionController](https://wiki.facepunch.com/gmod/Entity:RemoveFromMotionController).
---
--- > NOTE: Only works on a scripted [Entity](https://wiki.facepunch.com/gmod/Entity) of anim type.
---
function Entity:StartMotionController() end

--- [CLIENT]
---
--- Stops all particle effects parented to the entity and immediately destroys them.
---
function Entity:StopAndDestroyParticles() end

--- [SHARED]
---
--- Stops a sound created by [Entity:StartLoopingSound](https://wiki.facepunch.com/gmod/Entity:StartLoopingSound).
---
---@param sound_id integer The sound ID returned by [Entity:StartLoopingSound](https://wiki.facepunch.com/gmod/Entity:StartLoopingSound)
function Entity:StopLoopingSound( sound_id ) end

--- [SHARED]
---
--- Stops the motion controller created with [Entity:StartMotionController](https://wiki.facepunch.com/gmod/Entity:StartMotionController).
---
function Entity:StopMotionController() end

--- [CLIENT]
---
--- Stops all particle effects parented to the entity.
---
--- This is ran automatically on every client by [Entity:StopParticles](https://wiki.facepunch.com/gmod/Entity:StopParticles) if called on the server.
---
function Entity:StopParticleEmission() end

--- [SHARED]
---
--- Stops any attached to the entity .pcf particles using [Global.ParticleEffectAttach](https://wiki.facepunch.com/gmod/Global.ParticleEffectAttach) or [Global.ParticleEffect](https://wiki.facepunch.com/gmod/Global.ParticleEffect).
---
--- On client, this is the same as [Entity:StopParticleEmission](https://wiki.facepunch.com/gmod/Entity:StopParticleEmission). ( and you should use StopParticleEmission instead )
---
--- On server, this is the same as running [Entity:StopParticleEmission](https://wiki.facepunch.com/gmod/Entity:StopParticleEmission) on every client.
---
function Entity:StopParticles() end

--- [CLIENT]
---
--- Stops all particle effects parented to the entity with given name.
---
---@param name string The name of the particle to stop.
function Entity:StopParticlesNamed( name ) end

--- [CLIENT]
---
--- Stops all particle effects parented to the entity with given name on given attachment.
---
---@param name string The name of the particle to stop.
---@param attachment integer The attachment of the entity to stop particles on.
function Entity:StopParticlesWithNameAndAttachment( name, attachment ) end

--- [SHARED]
---
--- Stops emitting the given sound from the entity, especially useful for looping sounds.
---
--- Internally plays the sound with the [SND_STOP](https://wiki.facepunch.com/gmod/Enums/SND#SND_STOP) flag to stop the sound.
---
---@param sound_name string The name of the sound script or the filepath to stop playback of.
function Entity:StopSound( sound_name ) end

--- [SERVER]
---
--- Applies the specified amount of damage to the entity with [DMG_GENERIC](https://wiki.facepunch.com/gmod/Enums/DMG) flag.
---
--- > WARNING: Calling this function on the victim entity in [ENTITY:OnTakeDamage](https://wiki.facepunch.com/gmod/ENTITY:OnTakeDamage) can cause infinite loops.
---
--- > WARNING: This function does not seem to do any damage if you apply it to a player who is driving a prop_vehicle_jeep or prop_vehicle_jeep_old vehicle. You need to call it on the vehicle instead.
---
---@param damage_amount number The amount of damage to be applied.
---@param attacker garrysmod.Entity? The entity that initiated the attack that caused the damage.
---@param inflictor garrysmod.Entity? The entity that applied the damage, eg. a weapon.
function Entity:TakeDamage( damage_amount, attacker, inflictor ) end

--- [SERVER]
---
--- Applies the damage specified by the damage info to the entity.
---
--- > WARNING: Calling this function on the victim entity in [ENTITY:OnTakeDamage](https://wiki.facepunch.com/gmod/ENTITY:OnTakeDamage) can cause infinite loops.
---
--- > WARNING: This function does not seem to do any damage if you apply it to a player who is driving a prop_vehicle_jeep or prop_vehicle_jeep_old vehicle. You need to call it on the vehicle instead.
---
--- > NOTE: This function does not apply damage to [func_breakable_surf](https://developer.valvesoftware.com/wiki/Func_breakable_surf) entities correctly. To do this, you will need to use [Entity:DispatchTraceAttack](https://wiki.facepunch.com/gmod/Entity:DispatchTraceAttack) instead.
---
---@param damage_info garrysmod.DamageInfo The damage to apply.
function Entity:TakeDamageInfo( damage_info ) end

--- [SERVER]
---
--- Applies forces to our physics object in response to damage.
---
---@param damage_info garrysmod.DamageInfo The damageinfo to apply. Only [CTakeDamageInfo:GetDamageForce](https://wiki.facepunch.com/gmod/CTakeDamageInfo:GetDamageForce) and [CTakeDamageInfo:GetDamagePosition](https://wiki.facepunch.com/gmod/CTakeDamageInfo:GetDamagePosition) are used.
function Entity:TakePhysicsDamage( damage_info ) end

--- [SERVER]
---
--- Check if the given position or entity is within this entity's [PVS(Potential Visibility Set)](https://developer.valvesoftware.com/wiki/PVS "PVS - Valve Developer Community").
---
--- See also [Entity:IsDormant](https://wiki.facepunch.com/gmod/Entity:IsDormant).
---
--- > NOTE: The function won't take in to account [Global.AddOriginToPVS](https://wiki.facepunch.com/gmod/Global.AddOriginToPVS) and the like.
---
---@param test_point garrysmod.Vector | garrysmod.Entity [Entity](https://wiki.facepunch.com/gmod/Entity) or [Vector](https://wiki.facepunch.com/gmod/Vector) to test against. If an entity is given, this function will test using its bounding box.
---@return boolean in_pvs `true` if the testPoint is within our PVS.
function Entity:TestPVS( test_point ) end

--- [SHARED]
---
--- Returns the ID of a [PhysObj](https://wiki.facepunch.com/gmod/PhysObj) attached to the given bone.
---
--- See [Entity:TranslatePhysBoneToBone](https://wiki.facepunch.com/gmod/Entity:TranslatePhysBoneToBone) for reverse function.
---
---@param bone_id integer The ID of a bone to look up the "physics root" bone of.
---@return integer phys_bone_id The [PhysObj](https://wiki.facepunch.com/gmod/PhysObj) ID of the given bone to be used with [Entity:GetPhysicsObjectNum](https://wiki.facepunch.com/gmod/Entity:GetPhysicsObjectNum) or `-1` if we cannot translate for some reason, such as a model bone having no physics object associated with it.
function Entity:TranslateBoneToPhysBone( bone_id ) end

--- [SHARED]
---
--- Returns the boneID of the bone the given [PhysObj](https://wiki.facepunch.com/gmod/PhysObj) is attached to.
---
--- See [Entity:TranslateBoneToPhysBone](https://wiki.facepunch.com/gmod/Entity:TranslateBoneToPhysBone) for reverse function.
---
---@param phys_num integer The [PhysObj](https://wiki.facepunch.com/gmod/PhysObj) number on the entity
---@return integer bone_id The boneID of the bone the [PhysObj](https://wiki.facepunch.com/gmod/PhysObj) is attached to.
function Entity:TranslatePhysBoneToBone( phys_num ) end

--- [SERVER]
---
--- Updates positions of bone followers created by [Entity:CreateBoneFollowers](https://wiki.facepunch.com/gmod/Entity:CreateBoneFollowers).
---
--- This should be called every tick.
---
--- > NOTE: This function only works on `anim`, `nextbot` and `ai` type entities.
---
function Entity:UpdateBoneFollowers() end

--- [CLIENT]
---
--- Marks the render-to-texture (RTT) shadow of this entity as dirty, as well as any potential projected texture shadows related to this entity, so they will be updated as soon as possible.
---
function Entity:UpdateShadow() end

--- [SERVER]
---
--- Simulates a `+use` action on an entity.
---
---@param activator garrysmod.Entity The entity that caused this input. This will usually be the player who pressed their use key
---@param caller garrysmod.Entity? The entity responsible for the input. This will typically be the same as `activator` unless some other entity is acting as a proxy Defaults to `NULL`.
---@param use_type integer? Use type, see [Enums/USE](https://wiki.facepunch.com/gmod/Enums/USE). Defaults to `USE_ON`.
---@param value number? Any value. Defaults to `0`.
function Entity:Use( activator, caller, use_type, value ) end

--- [SHARED]
---
--- > NOTE: Does nothing on server.
---
--- Animations will be handled purely clientside instead of a fixed animtime, enabling interpolation. This does not affect layers and gestures.
---
function Entity:UseClientSideAnimation() end

--- [SHARED]
---
--- Enables or disables trigger bounds.
---
--- This will give the entity a "trigger box" that extends around its bounding box by boundSize units in X/Y and (boundSize / 2) in +Z (-Z remains the same).
--- The trigger box is world aligned and will work regardless of the object's solidity and collision group.
---
--- Valve use trigger boxes for all pickup items. Their bloat size is 24, a surprisingly large figure.
---
--- > NOTE: The trigger boxes can be made visible as a light blue box by using the **ent_bbox** console command while looking at the entity. Alternatively a classname or entity index can be used as the first argument.
--- >
--- > This requires **developer** to be set to **1**.
---
---@param enable boolean Enable or disable the bounds.
---@param bound_size number? The distance/size of the trigger bounds. Defaults to `0`.
function Entity:UseTriggerBounds( enable, bound_size ) end

--- [SHARED]
---
--- Returns the index of this view model, it can be used to identify which one of the player's view models this entity is.
---
---@return integer index View model index, ranges from 0 to 2, nil if the entity is not a view model
function Entity:ViewModelIndex() end

--- [SERVER]
---
--- Returns whether the target/given entity is visible from the this entity.
---
--- This is meant to be used only with NPCs.
---
--- Differences from a simple trace include:
--- * If target has `FL_NOTARGET`, returns `false`
--- * If `ai_ignoreplayers` is turned on and target is a player, returns `false`
--- * Reacts to `ai_LOS_mode`:
--- * * If `1`, does a simple trace with `COLLISION_GROUP_NONE` and `MASK_BLOCKLOS`
--- * * If not, does a trace with `MASK_BLOCKLOS_AND_NPCS` (- `CONTENTS_BLOCKLOS` is target is player) and a custom LOS filter (`CTraceFilterLOS`)
--- * Returns `true` if hits a vehicle the target is driving
---
---@param target garrysmod.Entity Entity to check for visibility to.
---@return boolean is_visible If the entities can see each other.
function Entity:Visible( target ) end

--- [SERVER]
---
--- Returns true if supplied vector is visible from the entity's line of sight.
---
--- This is achieved similarly to a trace.
---
---@param position garrysmod.Vector The position to check for visibility
---@return boolean is_visible `true` if the position is within line of sight.
function Entity:VisibleVec( position ) end

--- [SHARED]
---
--- Returns an integer that represents how deep in water the entity is.
---
---@return integer water_level The water level. * **0** - The entity isn't in water. * **1** - Slightly submerged (at least to the feet). * **2** - The majority of the entity is submerged (at least to the waist). * **3** - Completely submerged.
function Entity:WaterLevel() end

--- [SHARED]
---
--- Sets the activity of the entity's active weapon.
---
--- > NOTE: This does nothing on the client.
---
--- > NOTE: Only works for CBaseCombatCharacter entities, which includes players and NPCs.
---
---@param act integer Activity number. See [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
---@param duration number How long the animation should take in seconds.
function Entity:Weapon_SetActivity( act, duration ) end

--- [SHARED]
---
--- Calls and returns [WEAPON:TranslateActivity](https://wiki.facepunch.com/gmod/WEAPON:TranslateActivity) on the weapon the entity (player or NPC) carries.
---
--- > NOTE: Doesn't return anything on client, despite existing there.
---
---@param act integer The NPC activity to translate
---@return integer activity The translated activity. Defaults to `act` input when a translation doesn't exist.
function Entity:Weapon_TranslateActivity( act ) end

--- [SHARED]
---
--- Returns two vectors representing the minimum and maximum extent of the entity's axis-aligned bounding box (which is calculated from entity's collision bounds.
---
---@return garrysmod.Vector mins The minimum vector for the entity's bounding box in world space.
---@return garrysmod.Vector maxs The maximum vector for the entity's bounding box in world space.
function Entity:WorldSpaceAABB() end

--- [SHARED]
---
--- Returns the center of the entity according to its collision model.
---
---@return garrysmod.Vector center The center of the entity
function Entity:WorldSpaceCenter() end

--- [SHARED]
---
--- Translates a worldspace vector into a vector relative to the entity's coordinate system.
---
---@param world_position garrysmod.Vector A worldspace vector.
---@return garrysmod.Vector local_position The corresponding local space vector.
function Entity:WorldToLocal( world_position ) end

--- [SHARED]
---
--- Translates a worldspace angle into an angle relative to the entity's coordinate system.
---
---@param world_angles garrysmod.Angle A worldspace angle.
---@return garrysmod.Angle local_angles The corresponding local space angle.
function Entity:WorldToLocalAngles( world_angles ) end
