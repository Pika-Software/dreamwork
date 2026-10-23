---@meta garrysmod.util


--- [SHARED AND MENU]
---
--- This is the list of utility functions.
---
---@class garrysmod.util
util = {}

--- [SERVER]
---
--- Adds the specified string to a string table, which will cache it and network it to all clients automatically.
---
--- Whenever you want to create a net message with [net.Start](https://wiki.facepunch.com/gmod/net.Start), you must add the name of that message as a networked string via this function.
---
--- If the passed string already exists, nothing will happen and the ID of the existing item will be returned.
---
---@param network_name string Adds the specified string to the string table.
---@return integer network_id The id of the string that was added to the string table.
function util.AddNetworkString( network_name ) end

--- [CLIENT]
---
--- Function used to calculate aim vector from 2D screen position. It is used in SuperDOF calculate Distance.
---
--- Essentially a generic version of [gui.ScreenToVector](https://wiki.facepunch.com/gmod/gui.ScreenToVector).
---
---@param view_angles garrysmod.Angle View angles.
---@param view_fov integer View Field of View.
---@param x integer Mouse X position.
---@param y integer Mouse Y position.
---@param screen_width integer Screen width.
---@param screen_height integer Screen height.
---@return garrysmod.Vector direction Calculated aim vector.
function util.AimVector( view_angles, view_fov, x, y, screen_width, screen_height ) end

--- [SHARED AND MENU]
---
--- Decodes the specified string from base64.
---
---@param input_str string String to decode.
---@return string | nil decoded_str The raw bytes of the decoded string, or `nil` if the input is invalid.
function util.Base64Decode( input_str ) end

--- [SHARED AND MENU]
---
--- Encodes the specified string to base64.
---
---@param input_str string String to encode.
---@param inline boolean? `true` to disable RFC 2045 compliance (newline every 76th character).
---@return string encoded_str The base64 encoded string.
function util.Base64Encode( input_str, inline ) end

--- [SERVER]
---
--- Applies explosion damage to all entities in the specified radius.
---
--- Line of sight is checked, the damage falls off with the distance.
---
---@param inflictor garrysmod.Entity The entity that caused the damage.
---@param attacker garrysmod.Entity The entity that attacked.
---@param damage_origin garrysmod.Vector The center of the explosion.
---@param damage_radius number The radius in which entities will be damaged.
---@param damage number The amount of damage to be applied.
function util.BlastDamage( inflictor, attacker, damage_origin, damage_radius, damage ) end

--- [SERVER]
---
--- Applies spherical damage based on damage info to all entities in the specified radius.
---
---@param damage_info garrysmod.DamageInfo The information about the damage.
---@param damage_origin garrysmod.Vector Center of the spherical damage.
---@param damage_radius number The radius in which entities will be damaged.
function util.BlastDamageInfo( damage_info, damage_origin, damage_radius ) end

--- [SHARED AND MENU]
---
--- Compresses the given string using the [LZMA](https://en.wikipedia.org/wiki/LZMA) algorithm.
---
--- Use with [net.WriteData](https://wiki.facepunch.com/gmod/net.WriteData) and [net.ReadData](https://wiki.facepunch.com/gmod/net.ReadData) for networking and [util.Decompress](https://wiki.facepunch.com/gmod/util.Decompress) to decompress the data.
---
---@param decompressed_data string String to compress.
---@return string compressed_data The compressed string, or an empty string if the input string was zero length ("").
function util.Compress( decompressed_data ) end

--- [SHARED AND MENU]
---
--- Decompresses the given string using the [LZMA](https://en.wikipedia.org/wiki/LZMA) algorithm.
---
--- Used to decompress strings previously compressed with [util.Compress](https://wiki.facepunch.com/gmod/util.Compress).
---
--- When decompressing untrusted data (e.g. received from network), always specify `max_size` to prevent decompression bombs.
---
---@param compressed_data string The compressed string to decompress.
---@param max_size integer? The maximal size in bytes it will decompress.
---@return string | nil decompressed_data The original, decompressed string or `nil` on failure or invalid input.
function util.Decompress( compressed_data, max_size ) end

--- [SHARED AND MENU]
---
--- Generates the [CRC Checksum](https://en.wikipedia.org/wiki/Cyclic_redundancy_check) of the specified string.
---
--- This is **NOT** a hashing function. It is a checksum, typically used for error detection/data corruption detection.
---
---@param data string The string to calculate the checksum of.
---@return string checksum The unsigned 32 bit checksum.
function util.CRC( data ) end

--- [SHARED]
---
--- Performs a trace and paints a decal to the surface hit.
---
---@param name string The name of the decal to paint. Can be retrieved with [util.DecalMaterial](https://wiki.facepunch.com/gmod/util.DecalMaterial).
---@param start_pos garrysmod.Vector The start of the trace.
---@param end_pos garrysmod.Vector The end of the trace.
---@param filter ( garrysmod.Entity | garrysmod.Entity[] | nil ) If set, the decal will not be able to be placed on given entity. Can also be a table of entities.
function util.Decal( name, start_pos, end_pos, filter ) end

--- [CLIENT]
---
--- Performs a trace and paints a decal to the surface hit.
---
--- This function has trouble spanning across multiple brushes on the map.
---
---@param material garrysmod.Material The name of the decal to paint.
---@param entity garrysmod.Entity The entity to apply the decal to.
---@param position garrysmod.Vector The position of the decal.
---@param normal garrysmod.Vector The direction at which the decal should be painted. Usually the inverse of the surface normal.
---@param color garrysmod.Color The color of the decal. Uses 0-1 range.
---@param width integer The width scale of the decal.
---@param height integer The height scale of the decal.
function util.DecalEx( material, entity, position, normal, color, width, height ) end

--- [SHARED]
---
--- Gets the full material path by the decal name. Used with [util.DecalEx](https://wiki.facepunch.com/gmod/util.DecalEx).
---
--- If the decal has multiple materials defined, it will return a random one.
---
---@param decal_name string Name of the decal.
---@return string material_path Material path of the decal.
function util.DecalMaterial( decal_name ) end

--- [SHARED AND MENU]
---
--- Gets the distance between a line and a point in 3d space.
---
---@param line_start garrysmod.Vector Start of the line.
---@param line_end garrysmod.Vector End of the line.
---@param point_pos garrysmod.Vector The position of the point.
---@return number distance Distance from line.
---@return garrysmod.Vector nearest_point Nearest point on line.
---@return number distance_along_line Distance along line from start.
function util.DistanceToLine( line_start, line_end, point_pos ) end

--- [SHARED]
---
--- Creates an effect with the specified data.
---
---@param effect_name string The name of the effect to create.
---@param effect_data garrysmod.EffectData The effect data describing the effect.
---@param allow_override boolean? Whether Lua-defined effects should override engine-defined effects with the same name for this/single function call.
---@param ignore_prediction_or_recipient_filter ( boolean | garrysmod.RecipientFilter | nil ) Can either be a boolean to ignore the prediction filter or a [CRecipientFilter](https://wiki.facepunch.com/gmod/CRecipientFilter).
function util.Effect( effect_name, effect_data, allow_override, ignore_prediction_or_recipient_filter ) end

--- [SHARED]
---
--- Filters given text using Steam's filtering system based on the local client's settings.
---
---@param str string The string to filter.
---@param context integer? Filtering context. See [TEXT_FILTER](https://wiki.facepunch.com/gmod/Enums/TEXT_FILTER).
---@param player garrysmod.Player? Used to determine if the text should be filtered according to local user's Steam chat filtering settings.
---@return string filtered_str The filtered text.
function util.FilterText( str, context, player ) end

--- [MENU]
---
--- Converts the full path to a relative one.
---
---@param full_path string The full path to convert.
---@param fs_path string? The path the file is in. See [File Search Paths](https://wiki.facepunch.com/gmod/File_Search_Paths).
---@return string | nil relative_path The relative path, or `nil` if it can't be converted.
function util.FullPathToRelative_Menu( full_path, fs_path ) end

--- [SHARED]
---
--- Returns the ID of a custom model activity by its name.
---
---@param activity_name string The name of the activity.
---@return integer activity_id The ID of the activity, or `-1` if not found.
function util.GetActivityIDByName( activity_name ) end

--- [SHARED]
---
--- Returns the name of a model activity by its ID.
---
---@param activity_id integer The activity ID.
---@return string activity_name The name of the activity.
function util.GetActivityNameByID( activity_id ) end

--- [SHARED]
---
--- Returns the ID of a custom animation event by its name.
---
---@param event_name string The name of the animation event.
---@return integer event_id The ID of the animation event, or `-1` if not found.
function util.GetAnimEventIDByName( event_name ) end

--- [SHARED]
---
--- Returns the name of an animation event by its ID.
---
---@param event_id integer The animation event ID.
---@return string event_name The name of the animation event.
function util.GetAnimEventNameByID( event_id ) end

--- [SHARED]
---
--- Gets the information about the model.
---
--- This function will load and cache the model if it isn't already.
---
---@param model_path string The model path to retrieve information about.
---@return table | nil model_info The model info as a table, or `nil` if the model is invalid.
function util.GetModelInfo( model_path ) end

--- [SHARED]
---
--- Retrieves vertex, triangle, and bone data for the visual meshes of a given model.
---
---@param model_path string The full path to the model.
---@param lod integer? Which LOD to retrieve. `0` is the best quality, increasing the number lowers the quality.
---@param bodygroup_mask ( integer | string | nil ) Bodygroup combination for the model.
---@param skin integer? Skin number of the model.
---@return table | nil meshes The visual meshes of the model.
---@return table | nil bind_pose The bind pose of the model.
function util.GetModelMeshes( model_path, lod, bodygroup_mask, skin ) end

--- [SHARED]
---
--- Gets persistent data of an offline player using their SteamID.
---
---@param steam_id string SteamID of the player.
---@param name string Variable name to get the value of.
---@param default any The default value, in case there's nothing stored.
---@return string | any value The stored value, or `default` if nothing is stored.
function util.GetPData( steam_id, name, default ) end

--- [CLIENT]
---
--- Gets information about the sun position and obstruction or `nil` if there is no sun.
---
---@return table | nil sun_info The sun info.
function util.GetSunInfo() end

---@class garrysmod.SurfacePropertyData : metatable
---@field name string The name of the surface property, identical to util.GetSurfacePropName.
---@field hardnessFactor number How hard a surface is. If this is greater than or equal to another surfaces's hardThreshold, a hard impact sound will be used.
---@field hardThreshold number Hardness threshold for impact sounds. HitSurface.hardnessFactor >= InflictorSurface.hardThreshold - hard impact sound (depends on hardVelocityThreshold's value), HitSurface.hardnessFactor < InflictorSurface.hardThreshold - soft impact sound (always).
---@field hardVelocityThreshold number Velocity threshold for impact sounds. impactSpeed >= HitSurface.hardVelocityThreshold - hard impact sound (depends on hardThreshold's value), impactSpeed < HitSurface.hardVelocityThreshold - soft impact sound (always).
---@field reflectivity number Amount of sound reflected from the surface represented as a number 0.0 - 1.0. 0 - no reflection, 1 - fully reflected.
---@field roughnessFactor number How rough a surface is. If this is greater than or equal to another surfaces's roughThreshold, a rough scrape sound will be used.
---@field roughThreshold number Roughness threshold for friction sounds. HitSurface.roughnessFactor >= InflictorSurface.roughThreshold - rough friction sound, HitSurface.roughnessFactor < InflictorSurface.roughThreshold - soft friction sound.
---@field climbable number Indicates whether or not the surface is a ladder. Used to detect whether a player is on a ladder. 0 - false, > 0 - true.
---@field jumpFactor number Scalar multiplier for player jump height - or more accurately, applied z-axis velocity on a surface. For example, 1 - normal jump, 2 - twice as high, and 0.5 - half as high.
---@field material integer The surface material. See MAT enum.
---@field maxSpeedFactor number Scalar multiplier for player speed. Achieves this by multiplying CMoveData:SetMaxSpeed in GM:Move.
---@field dampening number This is the physical drag on an object when in contact with this surface (0 - x, 0 none to x a lot).
---@field density number Material density in kg / m^3 (water is 1000). If a surface's density is < 1000, it will float in water. This is used to calculate the total mass of an object.
---@field elasticity number Collision elasticity - used to compute coefficient of restitution represented as a number 0.0 - 1.0. 0.01 is soft, 1.0 is hard.
---@field friction number Physical friction used to slow entities touching the surface represented as a number 0.0 - 1.0. 0.01 is slick, 1.0 is completely rough.
---@field thickness number Material thickness. If this is 0, the material is not volumetrically solid, and thus the object mass will be calculated as "volume * 0.0254^3 * density" where 0.0254 is meters per inch. If non-zero, the mass will be "surfacearea * thickness * 0.0254^3 * density".
---@field breakSound string Sound to play when a prop or func_breakable is broken.
---@field bulletImpactSound string Bullet impact sound with this surface.
---@field impactHardSound string Physical impact sound when hitting surfaces hard.
---@field impactSoftSound string Physical impact sound when hitting surfaces softly.
---@field rollingSound string Unused sound.
---@field scrapeRoughSound string Friction sound when roughly scraping against an entity.
---@field scrapeSmoothSound string Friction sound when smoothly scraping against an entity.
---@field stepLeftSound string Footstep sound for left foot.
---@field stepRightSound string Footstep sound for right foot.
---@field strainSound string Unused sound.

--- [SHARED]
---
--- Returns data of a surface property at specified id.
---
---@param surface_id integer Surface property ID. You can get it from [TraceResult](https://wiki.facepunch.com/gmod/Structures/TraceResult) structure.
---@return garrysmod.SurfacePropertyData | nil surface_data The data or `nil` if the surface was not found.
function util.GetSurfaceData( surface_id ) end

--- [SHARED]
---
--- Returns the matching surface property index for the given surface property name.
---
---@param surface_name string The name of the surface.
---@return integer surface_id The surface property index, or `-1` if name doesn't correspond to a valid surface property.
function util.GetSurfaceIndex( surface_name ) end

--- [SHARED]
---
--- Returns the name of a surface property at given ID.
---
---@param surface_id integer Surface property ID. You can get it from [TraceResult](https://wiki.facepunch.com/gmod/Structures/TraceResult) structure.
---@return string surface_name The name or an empty string if the ID is not valid.
function util.GetSurfacePropName( surface_id ) end

--- [SHARED AND MENU]
---
--- Performs a "ray" box intersection and returns position, normal and the fraction.
---
---@param ray_start garrysmod.Vector Origin/start position of the ray.
---@param ray_delta garrysmod.Vector The ray vector itself. This can be thought of as: the ray end point relative to the start point.
---@param box_origin garrysmod.Vector The center of the box.
---@param box_angles garrysmod.Angle The angles of the box.
---@param box_mins garrysmod.Vector The min position of the box.
---@param box_maxs garrysmod.Vector The max position of the box.
---@return garrysmod.Vector | nil hit_pos Hit position, `nil` if not hit.
---@return garrysmod.Vector | nil normal Normal/direction vector, `nil` if not hit.
---@return number | nil fraction Fraction of trace used, `nil` if not hit.
function util.IntersectRayWithOBB( ray_start, ray_delta, box_origin, box_angles, box_mins, box_maxs ) end

--- [SHARED AND MENU]
---
--- Performs a ray-plane intersection and returns the hit position or `nil`.
---
---@param ray_origin garrysmod.Vector Origin/start position of the ray.
---@param ray_direction garrysmod.Vector The direction of the ray.
---@param plane_position garrysmod.Vector Any position of the plane.
---@param plane_normal garrysmod.Vector The normal vector of the plane.
---@return garrysmod.Vector | nil hit_pos The position of intersection, `nil` if not hit.
---@return number | nil distance The distance from the ray origin to the intersection, `nil` if not hit.
function util.IntersectRayWithPlane( ray_origin, ray_direction, plane_position, plane_normal ) end

--- [SHARED AND MENU]
---
--- Performs a ray-sphere intersection and returns the intersection positions or `nil`.
---
---@param ray_origin garrysmod.Vector Origin/start position of the ray.
---@param ray_delta garrysmod.Vector The end position of the ray relative to the start position. Equivalent of `direction * distance`.
---@param sphere_position garrysmod.Vector Any position of the sphere.
---@param sphere_radius number The radius of the sphere.
---@return number | nil entry_fraction The first intersection position along the ray, or `nil` if there is no intersection.
---@return number | nil exit_fraction The second intersection position along the ray, or `nil` if there is no intersection.
function util.IntersectRayWithSphere( ray_origin, ray_delta, sphere_position, sphere_radius ) end

--- [SHARED AND MENU]
---
--- Performs a ray-triangle intersection and returns the intersection position or `nil`.
---
---@param ray_origin garrysmod.Vector Origin/start position of the ray.
---@param ray_end garrysmod.Vector The end position of the ray relative to the start position.
---@param tri_a garrysmod.Vector The first vertex of the triangle.
---@param tri_b garrysmod.Vector The second vertex of the triangle.
---@param tri_c garrysmod.Vector The third vertex of the triangle.
---@param one_sided boolean? If `true`, only hits on the front face of the triangle are counted.
---@return garrysmod.Vector | nil hit_pos The position of intersection, `nil` if not hit.
---@return number | nil fraction The fraction of the ray used, `nil` if not hit.
function util.IntersectRayWithTriangle( ray_origin, ray_end, tri_a, tri_b, tri_c, one_sided ) end

--- [SHARED AND MENU]
---
--- Returns whether the two given axis-aligned boxes intersect.
---
---@param box1_min garrysmod.Vector The minimum extents of the first box.
---@param box1_max garrysmod.Vector The maximum extents of the first box.
---@param box2_min garrysmod.Vector The minimum extents of the second box.
---@param box2_max garrysmod.Vector The maximum extents of the second box.
---@return boolean is_intersecting `true` if the boxes intersect.
function util.IsBoxIntersectingBox( box1_min, box1_max, box2_min, box2_max ) end

--- [SHARED AND MENU]
---
--- Returns whether the given axis-aligned box and sphere intersect.
---
---@param box_min garrysmod.Vector The minimum extents of the box.
---@param box_max garrysmod.Vector The maximum extents of the box.
---@param sphere_position garrysmod.Vector The center of the sphere.
---@param sphere_radius number The radius of the sphere.
---@return boolean is_intersecting `true` if the box and the sphere intersect.
function util.IsBoxIntersectingSphere( box_min, box_max, sphere_position, sphere_radius ) end

--- [SHARED]
---
--- Checks if the specified position is within the world bounds.
---
---@param position garrysmod.Vector The position to check.
---@return boolean is_in_world Whether the vector is in world.
function util.IsInWorld( position ) end

--- [SHARED]
---
--- Checks if the model is loaded in the game.
---
---@param model_path string Name/Path of the model to check.
---@return boolean is_loaded `true` if the model is loaded in the game; otherwise `false`.
function util.IsModelLoaded( model_path ) end

--- [SHARED AND MENU]
---
--- Returns whether the two given oriented bounding boxes intersect.
---
---@param box1_origin garrysmod.Vector The center of the first box.
---@param box1_angles garrysmod.Angle The angles of the first box.
---@param box1_mins garrysmod.Vector The minimum extents of the first box.
---@param box1_maxs garrysmod.Vector The maximum extents of the first box.
---@param box2_origin garrysmod.Vector The center of the second box.
---@param box2_angles garrysmod.Angle The angles of the second box.
---@param box2_mins garrysmod.Vector The minimum extents of the second box.
---@param box2_maxs garrysmod.Vector The maximum extents of the second box.
---@param tolerance number Tolerance of the intersection test.
---@return boolean is_intersecting `true` if the boxes intersect.
function util.IsOBBIntersectingOBB( box1_origin, box1_angles, box1_mins, box1_maxs, box2_origin, box2_angles, box2_mins, box2_maxs, tolerance ) end

--- [SHARED AND MENU]
---
--- Returns whether a point is within a cone or not.
---
---@param point garrysmod.Vector The point to test.
---@param cone_origin garrysmod.Vector The tip of the cone.
---@param cone_axis garrysmod.Vector The direction of the cone.
---@param cone_sine number The angle of the cone in sine.
---@param cone_length number The length of the cone.
---@return boolean is_in_cone `true` if the point is within the cone.
function util.IsPointInCone( point, cone_origin, cone_axis, cone_sine, cone_length ) end

--- [SHARED AND MENU]
---
--- Returns whether two rays intersect.
---
---@param ray1_start garrysmod.Vector The start of the first ray.
---@param ray1_end garrysmod.Vector The end of the first ray.
---@param ray2_start garrysmod.Vector The start of the second ray.
---@param ray2_end garrysmod.Vector The end of the second ray.
---@return boolean is_intersecting `true` if the rays intersect.
---@return number ray1_fraction The fraction along the first ray at the closest point.
---@return number ray2_fraction The fraction along the second ray at the closest point.
function util.IsRayIntersectingRay( ray1_start, ray1_end, ray2_start, ray2_end ) end

--- [CLIENT]
---
--- Checks whether the skybox is visible from the point specified.
---
--- This will always return `true` in fullbright maps.
---
---@param position garrysmod.Vector The position to check the skybox visibility from.
---@return boolean is_visible Whether the skybox is visible from the position.
function util.IsSkyboxVisibleFromPoint( position ) end

--- [SHARED AND MENU]
---
--- Returns whether a sphere is intersecting a cone or not.
---
---@param sphere_center garrysmod.Vector The center of the sphere.
---@param sphere_radius number The radius of the sphere.
---@param cone_origin garrysmod.Vector The tip of the cone.
---@param cone_axis garrysmod.Vector The direction of the cone.
---@param cone_sine number The angle of the cone in sine.
---@param cone_cosine number The angle of the cone in cosine.
---@return boolean is_intersecting `true` if the sphere intersects the cone.
function util.IsSphereIntersectingCone( sphere_center, sphere_radius, cone_origin, cone_axis, cone_sine, cone_cosine ) end

--- [SHARED AND MENU]
---
--- Returns whether the two given spheres intersect.
---
---@param sphere1_position garrysmod.Vector The center of the first sphere.
---@param sphere1_radius number The radius of the first sphere.
---@param sphere2_position garrysmod.Vector The center of the second sphere.
---@param sphere2_radius number The radius of the second sphere.
---@return boolean is_intersecting `true` if the spheres intersect.
function util.IsSphereIntersectingSphere( sphere1_position, sphere1_radius, sphere2_position, sphere2_radius ) end

--- [SHARED]
---
--- Checks if the specified model is valid.
---
--- This function will precache the model as a side effect.
---
---@param model_path string Name/Path of the model to check.
---@return boolean is_valid Whether the model is valid or not.
function util.IsValidModel( model_path ) end

--- [SHARED]
---
--- Checks if the specified prop is valid and has a usable physics object.
---
---@param model_path string Name/Path of the model to check.
---@return boolean is_valid Returns `true` if the specified prop is valid; otherwise `false`.
function util.IsValidProp( model_path ) end

--- [SHARED]
---
--- Checks if the specified model name points to a valid ragdoll.
---
---@param ragdoll_path string Name/Path of the ragdoll model to check.
---@return boolean is_valid Returns `true` if the specified model name points to a valid ragdoll; otherwise `false`.
function util.IsValidRagdoll( ragdoll_path ) end

--- [SHARED AND MENU]
---
--- Converts a JSON string to a Lua table.
---
---@param json_str string The JSON string to convert.
---@param ignore_limits boolean? Ignore the depth and breadth limits, **use at your own risk!**
---@param ignore_conversions boolean? Ignore string to number key conversions.
---@return table | nil tbl The table containing converted information, or `nil` on failure.
function util.JSONToTable( json_str, ignore_limits, ignore_conversions ) end

--- [SHARED AND MENU]
---
--- Converts a Valve KeyValue string (typically from [util.TableToKeyValues](https://wiki.facepunch.com/gmod/util.TableToKeyValues)) to a Lua table.
---
--- Due to how tables work in Lua, keys will not preserve their order, nor will repeated keys be preserved.
---
---@param key_values string The KeyValue string to convert.
---@param uses_escape_sequences boolean? If set to `true`, will replace `\t`, `\n`, `\"` and `\\` in the input text with their escaped variants.
---@param preserve_key_case boolean? Whether we should preserve key case (may fail) or not (always lowercase).
---@return table tbl The converted table.
function util.KeyValuesToTable( key_values, uses_escape_sequences, preserve_key_case ) end

--- [SHARED AND MENU]
---
--- Similar to [util.KeyValuesToTable](https://wiki.facepunch.com/gmod/util.KeyValuesToTable) but it also preserves order of keys and repeated keys.
---
---@param key_values string The KeyValue string to convert.
---@param uses_escape_sequences boolean? If set to `true`, will replace `\t`, `\n`, `\"` and `\\` in the input text with their escaped variants.
---@param preserve_key_case boolean? Whether we should preserve key case (may fail) or not (always lowercase).
---@return { Key: string, Value: any }[] tbl The converted table.
function util.KeyValuesToTablePreserveOrder( key_values, uses_escape_sequences, preserve_key_case ) end

--- [SHARED AND MENU]
---
--- Generates the [MD5 Checksum](https://en.wikipedia.org/wiki/MD5) of the specified string.
---
--- MD5 is considered cryptographically broken and is known to be vulnerable to a variety of attacks.
---
---@param data string The string to calculate the checksum of.
---@return string hex_digest The MD5 checksum as a hex string.
function util.MD5( data ) end

--- [SHARED]
---
--- Returns the networked string associated with the given ID from the string table.
---
---@param network_id integer ID to get the associated string from.
---@return string | nil network_name The networked string, or `nil` if it wasn't found.
function util.NetworkIDToString( network_id ) end

--- [SHARED]
---
--- Returns the networked ID associated with the given string from the string table.
---
---@param network_name string String to get the associated networked ID from.
---@return integer network_id The networked ID of the string, or `0` if it hasn't been networked with [util.AddNetworkString](https://wiki.facepunch.com/gmod/util.AddNetworkString).
function util.NetworkStringToID( network_name ) end

--- [SHARED]
---
--- Creates a tracer effect with the given parameters.
---
---@param name string The name of the tracer effect.
---@param start_pos garrysmod.Vector The start position of the tracer.
---@param end_pos garrysmod.Vector The end position of the tracer.
---@param do_whiz boolean Play the hit miss (whiz) sound.
function util.ParticleTracer( name, start_pos, end_pos, do_whiz ) end

--- [SHARED]
---
--- Creates a tracer effect with the given parameters.
---
---@param name string The name of the tracer effect.
---@param start_pos garrysmod.Vector The start position of the tracer.
---@param end_pos garrysmod.Vector The end position of the tracer.
---@param do_whiz boolean Play the hit miss (whiz) sound.
---@param entity_index integer garrysmod.Entity index of the emitting entity.
---@param attachment_index integer Attachment index to be used as origin.
function util.ParticleTracerEx( name, start_pos, end_pos, do_whiz, entity_index, attachment_index ) end

---@class garrysmod.PixelVisHandle : userdata


--- [CLIENT]
---
--- Creates a new PixVis handle. See [util.PixelVisible](https://wiki.facepunch.com/gmod/util.PixelVisible).
---
---@return garrysmod.PixelVisHandle handle The PixVis handle.
function util.GetPixelVisibleHandle() end

--- [CLIENT]
---
--- Returns the visibility of a sphere in the world.
---
---@param position garrysmod.Vector The center of the visibility test.
---@param radius number The radius of the sphere to check for visibility.
---@param handle garrysmod.PixelVisHandle The PixVis handle created with [util.GetPixelVisibleHandle](https://wiki.facepunch.com/gmod/util.GetPixelVisibleHandle).
---@return number visibility Visibility, ranges from `0-1`. `0` when none of the area is visible, `1` when all of it is visible.
function util.PixelVisible( position, radius, handle ) end

--- [SHARED]
---
--- Returns the contents of the position specified.
---
---@param position garrysmod.Vector Position to get the contents sample from.
---@return integer contents Contents bitflag, see [CONTENTS](https://wiki.facepunch.com/gmod/Enums/CONTENTS).
function util.PointContents( position ) end

--- [SHARED]
---
--- Precaches a model for later use. Model is cached after being loaded once.
---
--- Modelprecache is limited to 8192 unique models. When it reaches the limit the game will crash.
---
---@param model_path string The model to precache.
function util.PrecacheModel( model_path ) end

--- [SHARED]
---
--- Precaches a sound for later use. Sound is cached after being loaded once.
---
--- This function does nothing, it is disabled on purpose.
---
---@param sound_name string The sound to precache.
function util.PrecacheSound( sound_name ) end

--- [MENU]
---
--- Converts a relative path to a full path on disk.
---
---@param file_path string The relative path to convert.
---@param mount_path string? The path the file is in. See [File Search Paths](https://wiki.facepunch.com/gmod/File_Search_Paths).
---@return string | nil full_path The full path, or `nil` if the file doesn't exist.
function util.RelativePathToFull_Menu( file_path, mount_path ) end

--- [MENU]
---
--- Returns the workshop addon that the given file belongs to.
---
---@param file_path string The relative file path.
---@return table | nil addon_info The addon info, or `nil` if the file is not from a workshop addon.
function util.RelativePathToGMA_Menu( file_path ) end

--- [SHARED]
---
--- Removes world decals within the given radius of the position. Does not affect decals on models.
---
---@param position garrysmod.Vector The position to remove decals around.
---@param distance number The radius in which decals will be removed.
---@param limit integer? Maximum amount of decals to remove, `0` for no limit.
---@param permanent boolean? Whether to remove permanent decals as well.
---@return integer removed_count The amount of decals removed.
function util.RemoveDecalsAt( position, distance, limit, permanent ) end

--- [SHARED]
---
--- Makes the screen shake.
---
--- The screen shake effect is rendered by modifying the view origin on the client. The view origin is used by [Global.EyePos](https://wiki.facepunch.com/gmod/Global.EyePos).
---
---@param position garrysmod.Vector The origin of the effect. Will only affect players within the radius.
---@param amplitude number The strength of the effect.
---@param frequency number The frequency of the effect in hz.
---@param duration number The duration of the effect in seconds.
---@param radius number The range from the origin within which views will be affected, in Hammer units.
---@param air_shake boolean? Whether players in the air should also be affected.
---@param filter garrysmod.RecipientFilter? If set, will only affect the given players. **SERVER** only.
function util.ScreenShake( position, amplitude, frequency, duration, radius, air_shake, filter ) end

--- [SHARED AND MENU]
---
--- Generates the [SHA-1 Checksum](https://en.wikipedia.org/wiki/SHA-1) of the specified string.
---
--- SHA-1 is considered cryptographically broken and is known to be vulnerable to a variety of attacks.
---
---@param data string The string to calculate the checksum of.
---@return string hex_digest The SHA-1 checksum as a hex string.
function util.SHA1( data ) end

--- [SHARED AND MENU]
---
--- Generates the [SHA-256 Checksum](https://en.wikipedia.org/wiki/SHA-2) of the specified string.
---
--- Unlike [util.MD5](https://wiki.facepunch.com/gmod/util.MD5) and [util.SHA1](https://wiki.facepunch.com/gmod/util.SHA1), this is the recommended hashing function.
---
---@param data string The string to calculate the checksum of.
---@return string hex_digest The SHA-256 checksum as a hex string.
function util.SHA256( data ) end

--- [SHARED]
---
--- Generates a random float value that should be the same on client and server.
---
--- This function is best used in a [Predicted Hook](https://wiki.facepunch.com/gmod/Prediction), it is not affected by [math.randomseed](https://wiki.facepunch.com/gmod/math.randomseed).
---
---@param unique_name string The seed for the random value.
---@param min number The minimum value of the random range.
---@param max number The maximum value of the random range.
---@param additional_seed integer? The additional seed.
---@return number random_value The generated random value.
function util.SharedRandom( unique_name, min, max, additional_seed ) end

--- [SERVER]
---
--- Adds a trail to the specified entity.
---
---@param entity garrysmod.Entity garrysmod.Entity to attach trail to.
---@param attachment_id integer Attachment ID of the entities model to attach trail to. If you are not sure, set this to `0`.
---@param color garrysmod.Color Color of the trail, use [Global.Color](https://wiki.facepunch.com/gmod/Global.Color).
---@param additive boolean Should the trail be additive or not.
---@param start_width number The start width of the trail.
---@param end_width number The end width of the trail.
---@param lifetime number How long it takes to transition from `start_width` to `end_width`.
---@param texture_resolution number The resolution of trails texture. A good value can be calculated using this formula: `1 / ( start_width + end_width ) * 0.5`.
---@param texture string Path to the texture to use as a trail.
---@return garrysmod.Entity trail garrysmod.Entity of created trail (`env_spritetrail`).
function util.SpriteTrail( entity, attachment_id, color, additive, start_width, end_width, lifetime, texture_resolution, texture ) end

--- [SHARED AND MENU]
---
--- Converts a SteamID64 to a SteamID.
---
--- Since this conversion is lossy, the account type and instance data will be lost.
---
---@param steam_id64 string The SteamID64 to convert.
---@return string steam_id The SteamID in `STEAM_0:0:0` format, or `STEAM_0:0:0` if the input is invalid.
function util.SteamIDFrom64( steam_id64 ) end

--- [SHARED AND MENU]
---
--- Converts a SteamID to a SteamID64.
---
---@param steam_id string The SteamID to convert.
---@return string steam_id64 The SteamID64, or `0` if the input is invalid.
function util.SteamIDTo64( steam_id ) end

--- [SHARED AND MENU]
---
--- Converts a table to a JSON string.
---
--- All keys are strings in the JSON format, so all keys will be converted to strings!
---
--- All integers will be converted to decimals (`5` -> `5.0`).
---
--- Entities, functions and other types that JSON cannot store are skipped.
---
---@param tbl table Table to convert.
---@param pretty_print boolean? Format and indent the JSON.
---@return string | nil json_str A JSON formatted string containing the serialized data, or `nil` on failure.
function util.TableToJSON( tbl, pretty_print ) end

--- [SHARED AND MENU]
---
--- Converts the given table into a Valve KeyValue string.
---
---@param tbl table The table to convert.
---@param root_key string? The root key name for the output KV table.
---@return string key_values The KeyValue string.
function util.TableToKeyValues( tbl, root_key ) end

--- [SHARED AND MENU]
---
--- Returns the time since this function has been last called.
---
---@return number elapsed Time since this function has been last called in ms.
function util.TimerCycle() end

--- [SHARED AND MENU]
---
--- Converts string or a number to a boolean, if possible.
---
---@deprecated You should use [Global.tobool](https://wiki.facepunch.com/gmod/Global.tobool) instead.
---
---@param input any A string or a number to convert.
---@return boolean value `false` if the input is equal to the string or boolean `false`, if the input is equal to the string or number `0`, or if the input is `nil`. Returns `true` otherwise.
function util.tobool( input ) end

---@class garrysmod.Trace.output
---@field Entity garrysmod.Entity The entity hit by the trace.
---@field Fraction number | 1 This indicates the how much of your trace length was used from 0-1 (resultLength/originalLength).
---@field FractionLeftSolid number | 0 number Given the trace started in a solid enviroment, this will return at what distance the trace left the solid from 0-1. Doesn't work if the trace hit a non-worldspawn entity.
---@field Hit boolean Indicates whether the trace hit something.
---@field HitBox integer | 0 The ID of the hitbox hit by the trace, or ID of the static prop hit in case of hitting the world.
---@field HitGroup integer | 0 HITGROUP enum describing what hitgroup the trace hit (not the same as HitBox).
---@field HitNoDraw boolean Indicates whenever the trace hit a no-draw brush.
---@field HitNonWorld boolean Indicates whenever the trace did not hit the world.
---@field HitNormal garrysmod.Vector The direction of the surface that was hit as a normal vector (vector with length of 1).
---@field HitPos garrysmod.Vector The position the trace stopped. This will be the provided endpos if the trace hit nothing.
---@field HitSky boolean Indicates whenever the trace hit the sky.
---@field HitTexture "**empty**" | "**displacement**" | "**studio**" | string The surface material (not texture) of whatever the trace hit. Will be **displacement** if the trace hit a displacement, and **studio** if it hit a prop. Default: "**empty**".
---@field HitWorld boolean Indicates whenever the trace hit the world.
---@field MatType integer | nil integer MAT enum of the material hit by the trace.
---@field Normal garrysmod.Vector The direction of the trace as a normal vector (vector with length of 1). Equivalent to: ( traceRes.HitPos - traceRes.StartPos ):Normalize()
---@field PhysicsBone integer | 0 The PhysObj ID that was hit. Used for Entity:GetPhysicsObjectNum.
---@field StartPos garrysmod.Vector The origin of the trace. Will match the provided startpos.
---@field SurfaceProps integer | 0 ID of hit surface property from scripts/surfaceproperties.txt. You can get the name using util.GetSurfacePropName. Used for CEffectData:SetSurfaceProp.
---@field StartSolid boolean Indicates whenever the trace started in a solid enviroment.
---@field AllSolid boolean True if the entire trace is inside a solid.
---@field SurfaceFlags integer | 0 The surface flags of the hit surface. See SURF enum.
---@field DispFlags integer | 0 The displacement flags of the hit surface. See DISPSURF enum.
---@field Contents integer | 0 The contents of the hit surface. See CONTENTS enum.
---@field HitBoxBone integer | nil BoneID on the model that the hit hitbox is attached to, if available.

---@class garrysmod.Trace
---@field start garrysmod.Vector The start position of the trace
---@field endpos garrysmod.Vector The end position of the trace
---@field maxs garrysmod.Vector The 3D vector local to the start/endpos with the highest values. This will represent the corner with the upper bounds of the box.
---@field mins garrysmod.Vector The 3D vector local to the start/endpos with the lowest (often negative) values. This will represent the corner with the lower bounds of the box.
---@field filter garrysmod.Entity | garrysmod.Entity[] | string[] | ( fun( entity: garrysmod.Entity ): boolean ) | nil Things the trace should not hit. Can be an entity, a table of entities, a table of entity classes or a function. **Using a function here is super slow. Try to avoid it.**
---@field mask integer The trace mask MASK enum. This determines what the trace should hit and what it shouldn't hit. A mask is a combination of CONTENTS enum - you can use these for more advanced masks.
---@field collisiongroup integer The collision group COLLISION_GROUP enum. This determines what the trace should hit in regards to the entity's collision group.
---@field ignoreworld boolean Should the trace ignore world or not
---@field output garrysmod.Trace.output | table | nil If set, the trace result will be written to the supplied table instead of returning a new table
---@field whitelist boolean Turns the filter field into a whitelist, if it is a table.
---@field hitclientonly boolean Enables traces to hit clientside only entities. Keep in mind that most naturally spawned entities are classified as debris, so extra mask values might be required.

--- [SHARED]
---
--- Runs a trace using the entity's collisionmodel between two points. This does not take the entity's angles into account and will trace its unrotated collisionmodel.
---
---@param trace_data garrysmod.Trace The trace data to use.
---@param entity garrysmod.Entity The entity to use.
---@return garrysmod.Trace.output trace_result Trace result.
function util.TraceEntity( trace_data, entity ) end

--- [SHARED]
---
--- Runs a trace using the entity's axis-aligned bounding box (`mins` and `maxs` from the trace data are ignored).
---
---@param trace_data Trace The trace data to use.
---@param entity garrysmod.Entity The entity to use.
---@return garrysmod.Trace.output trace_result Trace result.
function util.TraceEntityHull( trace_data, entity ) end

--- [SHARED]
---
--- Performs an AABB hull (axis-aligned bounding box, aka not rotated) trace with the given trace data.
---
--- This trace type cannot hit hitboxes.
---
---@param trace_data garrysmod.Trace The trace data to use.
---@return garrysmod.Trace.output trace_result Trace result.
function util.TraceHull( trace_data ) end

--- [SHARED]
---
--- Performs an infinitely thin, invisible ray trace (or "trace") in a line based on the input and returns a table that contains information about what, if anything, the trace line hit or intersected.
---
---@param trace_data garrysmod.Trace The trace data to use.
---@return garrysmod.Trace.output trace_result Trace result.
function util.TraceLine( trace_data ) end
