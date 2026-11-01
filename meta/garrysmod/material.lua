---@meta garrysmod.material


--- [SHARED AND MENU]
---
--- Either returns the material with the given name, or loads the material interpreting the first argument as the path.
---
--- ## .png, .jpg and other image formats
---
--- This function is capable of loading `.png` or `.jpg` images, generating a texture and material for them on the fly.
---
--- PNG, JPEG, GIF, and TGA files will work, but only if they have the `.png` or `.jpg` file extensions
--- (even if the actual image format doesn't match the file extension).
---
--- Use `AddonMaterial` for image files with the `.cache` file extension (from `steamworks.Download`).
---
--- While images are no longer scaled to power of 2 sizes (8, 16, 32, 64, 128, etc.) since February 2019,
--- it is still a good practice for things like icons.
---
--- > WARNING: Server-side, this function can consistently return an invalid material (with `__error`) depending on the file type loaded.
---
--- > WARNING: This function is very expensive when used in rendering hooks or in operations requiring very frequent calls.
--- > It is a good idea to cache the material in a variable.
---
---@param file_path string The material name or path relative to the `garrysmod/` folder. `!` for Lua created materials.
---@param params? string Space separated keywords that add material parameters, only works for `.png` or `.jpg` image files:
--- * `vertexlitgeneric` - makes the material a `VertexLitGeneric` so it can be applied to models and receive lighting, the default shader is `UnlitGeneric`.
--- * `nocull` - sets `$nocull` to `1`, so the back side of the texture is always drawn.
--- * `alphatest` - sets `$alphatest` to `1` instead of `$vertexalpha`, making alpha fully opaque or fully transparent.
--- * `mips` - generates mipmaps for the texture (and resizes it to a power of two), without it the level of detail and mipmaps are disabled.
--- * `noclamp` - allows the texture to tile, useful for custom UV mapping and `surface.DrawTexturedRectUV`.
--- * `smooth` - when not set, enables point sampling and the "no level of detail" flag.
--- * `ignorez` - adds the `$ignorez` flag, needed for some rendering operations such as render targets and 3D2D.
---@return garrysmod.Material material The generated material.
---@return number time_took How long it took for the function to run, in seconds.
function Material( file_path, params ) end

--- [SHARED AND MENU]
---
--- The key values of a material, as returned by `Material:GetKeyValues` and accepted by `CreateMaterial`.
---
--- Keys are Valve [shader parameters](https://developer.valvesoftware.com/wiki/Category:List_of_Shader_Parameters)
--- starting with `$` (the available ones depend on the material's shader), and the `Proxies` table.
---
--- Only the common parameters are listed here (and which of them apply depends on the shader),
--- any other shader parameter can be set the same way.
---
--- > NOTE: Textures are given by name (see `Texture:GetName`), not as `garrysmod.Texture` objects,
--- > and have to be loaded with `Material` first.
---
--- > NOTE: Many boolean parameters are stored as bits of `$flags` (see [Material Flags](https://wiki.facepunch.com/gmod/Material_Flags)),
--- > use `0`/`1` for them.
---
---@class garrysmod.Material.KeyValues
---@field ["$basetexture"] ( string | nil ) The name of the base (albedo) texture.
---@field ["$basetexturetransform"] ( string | nil ) The transform matrix of the base texture, e.g. `"center .5 .5 scale 2 2 rotate 0 translate 0 0"`.
---@field ["$frame"] ( integer | nil ) The current animation frame of the base texture.
---@field ["$color"] ( garrysmod.Vector | string | nil ) The color tint, e.g. `"[1 1 1]"`.
---@field ["$color2"] ( garrysmod.Vector | string | nil ) The second color tint, applied on top of `$color`.
---@field ["$alpha"] ( number | nil ) The overall opacity, `0` to `1`, requires `$translucent`.
---@field ["$surfaceprop"] ( string | nil ) The surface property name, e.g. `"concrete"`.
---@field ["$flags"] ( integer | nil ) The material flags bit field, see [Material Flags](https://wiki.facepunch.com/gmod/Material_Flags).
---@field ["$flags2"] ( integer | nil ) The second material flags bit field, read-only at runtime.
---@field ["$flags_defined"] ( integer | nil ) The bit field of the flags defined by the material file.
---@field ["$flags_defined2"] ( integer | nil ) The bit field of the second flags defined by the material file.
---@field ["$reflectivity"] ( garrysmod.Vector | string | nil ) The color the surface reflects, used by the lighting tools.
---@field ["$model"] ( integer | nil ) `1` if the material is used on models.
---@field ["$translucent"] ( integer | nil ) `1` to use the `$basetexture` alpha channel for per-pixel opacity.
---@field ["$alphatest"] ( integer | nil ) `1` for fully opaque or fully transparent alpha (hard edges).
---@field ["$additive"] ( integer | nil ) `1` to add the material's color to the pixels beneath it.
---@field ["$vertexcolor"] ( integer | nil ) `1` to use the vertex color (e.g. `Entity:SetColor`, `surface.SetDrawColor`).
---@field ["$vertexalpha"] ( integer | nil ) `1` to use the vertex alpha.
---@field ["$nocull"] ( integer | nil ) `1` to draw both sides of the surface (disables backface culling).
---@field ["$nofog"] ( integer | nil ) `1` to disable fog on the material.
---@field ["$ignorez"] ( integer | nil ) `1` to draw the material ignoring depth.
---@field ["$nodecal"] ( integer | nil ) `1` to prevent decals from being applied.
---@field ["$decal"] ( integer | nil ) `1` if the material is a decal.
---@field ["$selfillum"] ( integer | nil ) `1` to make the material self-illuminated.
---@field ["$halflambert"] ( integer | nil ) `1` to use half-lambert lighting (softer shading).
---@field ["$znearer"] ( integer | nil ) `1` to draw the material closer to the camera in the depth buffer.
---@field ["$flat"] ( integer | nil ) `1` to disable lighting variations on the surface.
---@field ["$wireframe"] ( integer | nil ) `1` to draw the material as a wireframe.
---@field ["$nolod"] ( integer | nil ) `1` to disable the level of detail and mipmaps.
---@field ["$no_draw"] ( integer | nil ) `1` to not draw the material.
---@field ["$no_fullbright"] ( integer | nil ) `1` to disable the fullbright rendering mode.
---@field ["$multipass"] ( integer | nil ) `1` to render the material in multiple passes.
---@field ["$allowalphatocoverage"] ( integer | nil ) `1` to allow alpha to coverage (anti-aliased alpha tested edges).
---@field ["$alphatestreference"] ( number | nil ) The alpha value, `0` to `1`, above which `$alphatest` pixels are drawn.
---@field ["$distancealpha"] ( integer | nil ) `1` to enable distance field alpha (for sharp scaled text and icons).
---@field ["$softedges"] ( integer | nil ) `1` to enable soft edges on the surface.
---@field ["$edgesoftnessstart"] ( number | nil ) The start of the soft edge fade.
---@field ["$edgesoftnessend"] ( number | nil ) The end of the soft edge fade.
---@field ["$blendtintbybasealpha"] ( integer | nil ) `1` to apply the tint only where the base texture alpha says so.
---@field ["$bumpmap"] ( string | nil ) The name of the normal map.
---@field ["$bumpframe"] ( integer | nil ) The current animation frame of the normal map.
---@field ["$bumptransform"] ( string | nil ) The transform matrix of the normal map.
---@field ["$ssbump"] ( integer | nil ) `1` if the normal map is a self-shadowed bump map.
---@field ["$nodiffusebumplighting"] ( integer | nil ) `1` to not use the normal map for diffuse lighting.
---@field ["$envmap"] ( string | nil ) The name of the environment map (cubemap), `"env_cubemap"` to use the map's cubemap.
---@field ["$envmapmask"] ( string | nil ) The name of the texture that masks the environment map.
---@field ["$envmapmaskframe"] ( integer | nil ) The current animation frame of the environment map mask.
---@field ["$envmaptint"] ( garrysmod.Vector | string | nil ) The color tint of the environment map.
---@field ["$envmapcontrast"] ( number | nil ) The contrast of the environment map.
---@field ["$envmapsaturation"] ( number | nil ) The saturation of the environment map.
---@field ["$envmapfresnel"] ( number | nil ) The fresnel effect strength on the environment map.
---@field ["$envmapanisotropy"] ( integer | nil ) `1` to enable anisotropic environment map reflections.
---@field ["$basealphaenvmapmask"] ( integer | nil ) `1` to use the base texture alpha as the environment map mask.
---@field ["$normalmapalphaenvmapmask"] ( integer | nil ) `1` to use the normal map alpha as the environment map mask.
---@field ["$phong"] ( integer | nil ) `1` to enable phong (specular) shading.
---@field ["$phongexponent"] ( number | nil ) The sharpness of the phong highlights.
---@field ["$phongexponenttexture"] ( string | nil ) The name of the texture that controls the phong exponent.
---@field ["$phongboost"] ( number | nil ) The strength of the phong highlights.
---@field ["$phongtint"] ( garrysmod.Vector | string | nil ) The color tint of the phong highlights.
---@field ["$phongfresnelranges"] ( garrysmod.Vector | string | nil ) The fresnel ranges of the phong highlights, e.g. `"[0 0.5 1]"`.
---@field ["$phongalbedotint"] ( integer | nil ) `1` to tint the phong highlights by the base texture.
---@field ["$basemapalphaphongmask"] ( integer | nil ) `1` to use the base texture alpha as the phong mask.
---@field ["$lightwarptexture"] ( string | nil ) The name of the light warp texture (for toon-like shading).
---@field ["$rimlight"] ( integer | nil ) `1` to enable rim lighting.
---@field ["$rimlightexponent"] ( number | nil ) The sharpness of the rim light.
---@field ["$rimlightboost"] ( number | nil ) The strength of the rim light.
---@field ["$detail"] ( string | nil ) The name of the detail texture.
---@field ["$detailscale"] ( number | nil ) The scale of the detail texture.
---@field ["$detailblendfactor"] ( number | nil ) The blend factor of the detail texture, `0` to `1`.
---@field ["$detailblendmode"] ( integer | nil ) The blend mode of the detail texture.
---@field ["$detailtint"] ( garrysmod.Vector | string | nil ) The color tint of the detail texture.
---@field ["$detailframe"] ( integer | nil ) The current animation frame of the detail texture.
---@field ["$selfillumtint"] ( garrysmod.Vector | string | nil ) The color tint of the self-illumination.
---@field ["$selfillummask"] ( string | nil ) The name of the texture that masks the self-illumination.
---@field ["$selfillumfresnel"] ( integer | nil ) `1` to apply a fresnel effect to the self-illumination.
---@field ["$seamless_scale"] ( number | nil ) The scale of the seamless (triplanar) mapping, `0` to disable.
---@field ["$tintmasktexture"] ( string | nil ) The name of the texture that masks the color tint.
---@field ["$treesway"] ( integer | nil ) `1` to make the material sway like a tree.
---@field ["$depthblend"] ( integer | nil ) `1` to blend the material with the depth of the scene behind it.
---@field ["$linearwrite"] ( integer | nil ) `1` to write colors in linear space.
---@field ["$decalscale"] ( number | nil ) The scale of the decal.
---@field ["$scale"] ( garrysmod.Vector | string | nil ) The scale of the material, used by some shaders.
---@field Proxies ( table<string, table<string, any>> | nil ) The material proxies by name, each with its own settings (only one instance of each proxy is possible).
---@field [string] any
local MaterialKeyValues = {}

--- [SHARED AND MENU]
---
--- A Material object. It represents a game material, similarly to how a `.vmt` file does,
--- which are in fact loaded into an `IMaterial` object.
---
--- In most cases the game works with materials as far as file paths go.
--- Materials then point to different `garrysmod.Texture` objects (`.vtf` files) they might be using.
--- They are not the same and cannot be interchanged.
---
--- A material object can be created with `Material` or `CreateMaterial`.
---
---@class garrysmod.Material : metatable
local Material = {}

--- [SHARED AND MENU]
---
--- Returns the color of the specified pixel of the `$basetexture`, only works for materials created from PNG files.
---
--- Basically identical to `Texture:GetColor` used on `Material:GetTexture( "$basetexture" )`.
---
---@param x integer The x coordinate.
---@param y integer The y coordinate.
---@return garrysmod.Color color The color of the pixel.
function Material:GetColor( x, y ) end

--- [SHARED AND MENU]
---
--- Returns the specified material value as a float, or `nil` if the value is not set.
---
---@param name string The name of the material value.
---@return number | nil value The value as a float.
function Material:GetFloat( name ) end

--- [SHARED AND MENU]
---
--- Returns the specified material value as an integer, rounds the value if it's a float, or `nil` if the value is not set.
---
--- > NOTE: Certain material flags such as `$model` are stored in the `$flags` variable
--- > and cannot be directly retrieved with this function, see [Material Flags](https://wiki.facepunch.com/gmod/Material_Flags).
---
---@param name string The name of the material integer.
---@return integer | nil value The value as an integer.
function Material:GetInt( name ) end

--- [SHARED]
---
--- Gets all the key values defined for the material.
---
---@return garrysmod.Material.KeyValues key_values The material's key values.
function Material:GetKeyValues() end

--- [SHARED]
---
--- Returns the specified material matrix, or `nil` if the value is not set or is not a matrix.
---
---@param name string The name of the material matrix.
---@return garrysmod.VMatrix | nil matrix The matrix.
function Material:GetMatrix( name ) end

--- [SHARED AND MENU]
---
--- Returns the name of the material, in most cases the path.
---
---@return string name The material name or path.
function Material:GetName() end

--- [SHARED AND MENU]
---
--- Returns the name of the material's shader.
---
--- > WARNING: This function does not work serverside on Linux SRCDS and always returns `shader_error`.
--- > This bug is fixed on the `dev` beta and in the next update.
---
---@return string shader The name of the currently loaded shader for this material, or `shader_error` if the material has no loaded shader.
--- It is not guaranteed to be in any specific capitalization, so case insensitive checks are advised.
function Material:GetShader() end

--- [SHARED AND MENU]
---
--- Returns the specified material string, or `nil` if the value is not set or if the value can not be converted to a string.
---
---@param name string The name of the material string.
---@return string | nil value The value as a string.
function Material:GetString( name ) end

--- [SHARED AND MENU]
---
--- Returns a texture based on the passed shader parameter.
---
---@param param string The [shader parameter](https://developer.valvesoftware.com/wiki/Category:List_of_Shader_Parameters) to retrieve, this should normally be `$basetexture`.
---@return garrysmod.Texture | nil texture The value of the shader parameter, `nil` if the parameter doesn't exist.
function Material:GetTexture( param ) end

--- [SHARED AND MENU]
---
--- Returns the specified material vector, or `nil` if the value is not set.
---
--- See also `Material:GetVectorLinear`.
---
---@param name string The name of the material vector.
---@return garrysmod.Vector | nil vector The color vector.
function Material:GetVector( name ) end

--- [SHARED AND MENU]
---
--- Returns the specified material vector as a 4 component vector.
---
---@param name string The name of the material vector to retrieve.
---@return number x The x component of the vector.
---@return number y The y component of the vector.
---@return number z The z component of the vector.
---@return number w The w component of the vector.
function Material:GetVector4D( name ) end

--- [SHARED AND MENU]
---
--- Returns the specified material linear color vector, or `nil` if the value is not set.
---
--- See [gamma correction](https://en.wikipedia.org/wiki/Gamma_correction).
---
--- See also `Material:GetVector`.
---
---@param name string The name of the material vector.
---@return garrysmod.Vector | nil vector The linear color vector.
function Material:GetVectorLinear( name ) end

--- [SHARED AND MENU]
---
--- Returns the height of the member texture set for `$basetexture`.
---
---@return integer height The height of the base texture.
function Material:Height() end

--- [SHARED AND MENU]
---
--- Returns whether the material failed to load from disk, i.e. is the error material (`___error`).
---
---@return boolean is_error `true` if this material is the error material.
function Material:IsError() end

--- [SHARED AND MENU]
---
--- Recomputes the material's snapshot.
--- This needs to be called if you have changed variables on your material and it isn't changing.
---
--- > NOTE: This function is slow, so try to call it only when needed!
---
function Material:Recompute() end

--- [MENU]
---
--- **INTERNAL**: This is used by the Background to change the image.
---
--- Changes the material into the given image.
---
---@param path string The path to an image.
function Material:SetDynamicImage( path ) end

--- [SHARED AND MENU]
---
--- Sets the specified material float to the specified float, does nothing on a type mismatch.
---
--- Unlike `Material:SetInt`, this function **does not** call `Material:Recompute` internally.
---
---@param name string The name of the material float.
---@param value number The new float value.
function Material:SetFloat( name, value ) end

--- [SHARED AND MENU]
---
--- Sets the specified material value to the specified integer, does nothing on a type mismatch.
---
--- Calls `Material:Recompute` internally.
---
--- > NOTE: Certain material flags such as `$model` are stored in the `$flags` variable
--- > and cannot be directly set with this function, see [Material Flags](https://wiki.facepunch.com/gmod/Material_Flags).
---
---@param name string The name of the material integer.
---@param value integer The new integer value.
function Material:SetInt( name, value ) end

--- [SHARED]
---
--- Sets the specified material value to the specified matrix, does nothing on a type mismatch.
---
---@param name string The name of the material matrix.
---@param matrix garrysmod.VMatrix The new matrix.
function Material:SetMatrix( name, matrix ) end

--- [SHARED AND MENU]
---
--- The functionality of this function was removed due to the amount of crashes it caused.
---
---@param shader_name string The name of the shader.
---@deprecated This function does nothing.
function Material:SetShader( shader_name ) end

--- [SHARED AND MENU]
---
--- Sets the specified material value to the specified string, does nothing on a type mismatch.
---
---@param name string The name of the material string.
---@param value string The new string.
function Material:SetString( name, value ) end

--- [SHARED AND MENU]
---
--- Sets the specified material texture to the specified texture, does nothing on a type mismatch.
---
--- Calls `Material:Recompute` internally.
---
---@param name string The name of the keyvalue on the material to store the texture on.
---@param texture garrysmod.Texture | string The new texture, this can also be a string - the name of the new texture.
function Material:SetTexture( name, texture ) end

--- [SHARED AND MENU]
---
--- Unsets the value for the specified material value.
---
---@param name string The name of the material value to be unset.
function Material:SetUndefined( name ) end

--- [SHARED AND MENU]
---
--- Sets the specified material vector to the specified vector, does nothing on a type mismatch.
---
---@param name string The name of the material vector.
---@param vector garrysmod.Vector The new vector.
function Material:SetVector( name, vector ) end

--- [SHARED AND MENU]
---
--- Sets the specified material vector to the specified 4 component vector, does nothing on a type mismatch.
---
---@param name string The name of the material vector.
---@param x number The x component of the new vector.
---@param y number The y component of the new vector.
---@param z number The z component of the new vector.
---@param w number The w component of the new vector.
function Material:SetVector4D( name, x, y, z, w ) end

--- [SHARED AND MENU]
---
--- Returns the width of the member texture set for `$basetexture`.
---
---@return integer width The width of the base texture.
function Material:Width() end
