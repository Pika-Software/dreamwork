---@meta garrysmod.ents


--- [CLIENT]
---
--- Extra optional settings for [ents.CreateClientRope](https://wiki.facepunch.com/gmod/ents.CreateClientRope).
---
---@class garrysmod.ClientRopeSettings
---@field slack number? How much extra rope to add to the length. Default is `0`.
---@field width number? Width of the rope. Default is `2`.
---@field segments integer? How many segments the rope should have. Default is `8`, valid range is `[2, 10]`.
---@field material string? Which material the rope should have. Default is `"cable/cable"`.
---@field nogravity integer? If set, the rope should have no gravity. Default is `0`.

--- [SHARED]
---
--- The ents library provides functions for creating and finding entities in the game.
---
---@class garrysmod.ents
ents = {}

--- [SERVER]
---
--- Creates an entity. This function will fail and return `NULL` if the networked-edict limit is hit (around **8176**), or the provided entity class doesn't exist.
---
--- > WARNING: Do not use before [GM:InitPostEntity](https://wiki.facepunch.com/gmod/GM:InitPostEntity) has been called, otherwise the server will crash!
--- > If you need to perform entity creation when the game starts, create a hook for `GM:InitPostEntity` and do it there.
---
---@param class string The classname of the entity to create.
---@return garrysmod.Entity entity The created entity, or `NULL` if failed.
function ents.Create( class ) end

--- [CLIENT]
---
--- Creates a clientside only prop with optional physics. See also [ClientsideModel](https://wiki.facepunch.com/gmod/Global.ClientsideModel) if physics is not needed.
---
--- For physics to work you're expected to use the `model` argument. A simple [Entity:SetModel](https://wiki.facepunch.com/gmod/Entity:SetModel) will not be enough — the [Entity:PhysicsInit](https://wiki.facepunch.com/gmod/Entity:PhysicsInit)* function will be needed.
---
--- > BUG: Parented clientside prop will become detached if the parent entity leaves the PVS. A workaround is available on its github page.
--- > See [issue #861](https://github.com/Facepunch/garrysmod-issues/issues/861).
---
---@param model string? The model for the entity to be created. Defaults to `"models/error.mdl"`.
---@return garrysmod.Entity entity Created entity (`C_PhysPropClientside`).
function ents.CreateClientProp( model ) end

--- [CLIENT]
---
--- Creates a clientside only rope, similar to those used by the Dog and Fast Zombie models from Half-Life 2.
---
--- Created ropes will be automatically cleaned up when one of the attached entities is removed.
---
--- > WARNING: It doesn't work exactly the same way as [constraint.CreateKeyframeRope](https://wiki.facepunch.com/gmod/constraint.CreateKeyframeRope) or [constraint.Rope](https://wiki.facepunch.com/gmod/constraint.Rope),
--- > you can see it when you try to use Slack with `constraint.CreateKeyframeRope` or `addlength` on `constraint.Rope`.
---
---@param ent1 garrysmod.Entity The first entity to attach the rope to.
---@param ent1_attach integer | garrysmod.Vector The attachment ID on the first entity to attach the rope to, or a local `Vector` relative to the first entity.
---@param ent2 garrysmod.Entity The second entity to attach the rope to.
---@param ent2_attach integer | garrysmod.Vector The attachment ID on the second entity to attach the rope to, or a local `Vector` relative to the second entity.
---@param extra garrysmod.ClientRopeSettings? Extra optional settings for the rope.
---@return garrysmod.Entity entity Created entity (`C_RopeKeyframe`).
function ents.CreateClientRope( ent1, ent1_attach, ent2, ent2_attach, extra ) end

--- [CLIENT]
---
--- Creates a clientside only scripted entity. The scripted entity must be of `"anim"` type.
---
---@param class string The class name of the entity to create.
---@return garrysmod.Entity entity Created entity.
function ents.CreateClientside( class ) end

--- [SHARED]
---
--- Returns a table of all entities along the ray. The ray does not stop on collisions, meaning it will go through walls/entities.
---
--- This function is capable of detecting clientside only entities by default.
---
--- This internally uses [spatial partitioning](https://en.wikipedia.org/wiki/Space_partitioning) to avoid looping through all entities.
---
---@param start_pos garrysmod.Vector The start position of the ray.
---@param end_pos garrysmod.Vector The end position of the ray.
---@param mins garrysmod.Vector? The mins corner of the ray.
---@param maxs garrysmod.Vector? The maxs corner of the ray.
---@return garrysmod.Entity[] entities Table of the found entities. There's a limit of `1024` entities.
function ents.FindAlongRay( start_pos, end_pos, mins, maxs ) end

--- [SHARED]
---
--- Gets all entities with the given class, supports wildcards.
---
--- This function returns a sequential table, meaning it should be looped with `ipairs` instead of `pairs` for efficiency reasons.
---
--- This works by iterating over all entities internally. Using this function is faster than `ents.GetAll` when you need to iterate over a specific class.
---
---@param class string The class of the entities to find, supports wildcards. Asterisks (`*`) are the only wildcard supported.
---@return garrysmod.Entity[] entities A table containing all found entities.
function ents.FindByClass( class ) end

--- [SHARED]
---
--- Gets all entities with the given model, supports wildcards.
---
--- This works internally by iterating over `ents.GetAll`.
---
---@param model string The model of the entities to find.
---@return garrysmod.Entity[] entities A table of all found entities.
function ents.FindByModel( model ) end

--- [SHARED]
---
--- Gets all entities with the given hammer targetname. This works internally by iterating over `ents.GetAll`.
---
--- Doesn't do anything on client.
---
---@param name string The targetname to look for.
---@return garrysmod.Entity[] entities A table of all found entities.
function ents.FindByName( name ) end

--- [SHARED]
---
--- Returns all entities within the specified box.
---
--- This internally uses a Spatial Partition to avoid looping through all entities, so it is more efficient than using `ents.GetAll` for this purpose.
---
--- > NOTE: Clientside entities will not be returned by this function. Serverside only entities without networked edicts (entity indexes), such as point logic or Constraints are not returned either.
---
---@param box_mins garrysmod.Vector The box minimum coordinates.
---@param box_maxs garrysmod.Vector The box maximum coordinates.
---@return garrysmod.Entity[] entities A table of all found entities.
function ents.FindInBox( box_mins, box_maxs ) end

--- [SHARED]
---
--- Finds and returns all entities within the specified cone. Only entities whose [Entity:WorldSpaceCenter](https://wiki.facepunch.com/gmod/Entity:WorldSpaceCenter) is within the cone are considered to be in it.
---
--- The "cone" is actually a conical "slice" of an axis-aligned box (see `ents.FindInBox`). Due to this, the entity may be farther than the specified range!
---
---@param origin garrysmod.Vector The tip of the cone.
---@param normal garrysmod.Vector Direction of the cone.
---@param range number The range of the cone/box around the origin. The function internally adds `1` to this argument before using it.
---@param angle_cos number The [cosine](https://wiki.facepunch.com/gmod/math.cos) of the angle between the center of the cone to its edges, which is half the overall angle of the cone. `1` makes a `0°` cone, `0.707` makes approximately `90°`, `0` makes `180°`, and so on.
---@return garrysmod.Entity[] entities A table of all found entities.
function ents.FindInCone( origin, normal, range, angle_cos ) end

--- [SERVER]
---
--- Finds all entities that lie within a [PVS (Potential Visibility Set)](https://developer.valvesoftware.com/wiki/PVS).
---
--- > NOTE: The function won't take in to account [AddOriginToPVS](https://wiki.facepunch.com/gmod/Global.AddOriginToPVS) and the like.
---
---@param view_point garrysmod.Entity | garrysmod.Vector Entity or Vector to find entities within the PVS of. If a player is given, this function will use the player's view entity.
---@return garrysmod.Entity[] entities The found entities.
function ents.FindInPVS( view_point ) end

--- [SHARED]
---
--- Gets all entities within the specified sphere.
---
--- This function internally calls [util.IsBoxIntersectingSphere](https://wiki.facepunch.com/gmod/util.IsBoxIntersectingSphere) for every entity on the map based on their Orientated Bounding Box.
---
---@param origin garrysmod.Vector Center of the sphere.
---@param radius number Radius of the sphere.
---@return garrysmod.Entity[] entities A table of all found entities.
function ents.FindInSphere( origin, radius ) end

--- [SERVER]
---
--- Fires a use event.
---
---@param target string Name of the target entity.
---@param activator garrysmod.Entity Activator of the event.
---@param caller garrysmod.Entity Caller of the event.
---@param use_type integer Use type. See the [USE](https://wiki.facepunch.com/gmod/Enums/USE) enums.
---@param value number This value is passed to [ENTITY:Use](https://wiki.facepunch.com/gmod/ENTITY:Use), but isn't used by any default entities in the engine.
function ents.FireTargets( target, activator, caller, use_type, value ) end

--- [SHARED]
---
--- Returns a table of all existing entities.
---
--- This function returns a sequential table, meaning it should be looped with `ipairs` instead of `pairs` for efficiency reasons.
---
---@return garrysmod.Entity[] entities Table of all existing entities.
function ents.GetAll() end

--- [SHARED]
---
--- Returns an entity by its index. Same as [Entity](https://wiki.facepunch.com/gmod/Global.Entity).
---
---@param ent_idx integer The index of the entity.
---@return garrysmod.Entity entity The entity if it exists, or `NULL` if it doesn't.
function ents.GetByIndex( ent_idx ) end

--- [SHARED]
---
--- Gives you the amount of currently existing entities.
---
--- Similar to `#ents.GetAll()` but with better performance since the entity table doesn't have to be generated.
--- If `ents.GetAll` is already being called for iteration, then using the `#` operator on the table will be faster than calling this function since it is JITted.
---
---@param include_kill_me boolean? Include entities with the `FL_KILLME` flag. This will skip an internal loop, and the function will be more efficient as a byproduct. Defaults to `false`.
---@return integer count Number of entities.
function ents.GetCount( include_kill_me ) end

--- [SERVER]
---
--- Returns the amount of networked entities, which is limited to `8192`.
---
--- `ents.Create` will fail somewhere between `8064` and `8176` - this can vary based on the amount of player slots on the server and other entities.
---
--- See also [MAX_EDICT_BITS](https://wiki.facepunch.com/gmod/Global_Variables#maxedictbits) global variable.
---
---@return integer count Number of networked entities.
function ents.GetEdictCount() end

--- [SHARED]
---
--- Returns entity that has given [Entity:MapCreationID](https://wiki.facepunch.com/gmod/Entity:MapCreationID).
---
--- This works internally by iterating over `ents.GetAll`.
---
---@param id integer Entity's creation id.
---@return garrysmod.Entity | nil entity Found entity, `nil` otherwise.
function ents.GetMapCreatedEntity( id ) end
