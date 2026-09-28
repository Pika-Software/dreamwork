---@meta dreamwork.std.material


---@alias dreamwork.std.Material.Shader.name string
---| "accumbuff5sample"
---| "Aftershock_dx9"
---| "Bik"
---| "Bik_dx80"
---| "Bik_dx81"
---| "Bloom"
---| "BlurFilterX"
---| "BlurFilterX_DX80"
---| "BlurFilterY"
---| "BlurFilterY_DX80"
---| "BufferClearObeyStencil_DX8"
---| "BufferClearObeyStencil_DX9"
---| "Cable_DX8"
---| "Cable_DX9"
---| "Cloak_DX90"
---| "ColorCorrection"
---| "Core_DX80"
---| "Core_DX90"
---| "DebugDrawEnvmapMask"
---| "DebugMorphAccumulator"
---| "DebugMRTTexture"
---| "DebugNormalMap"
---| "DebugTextureView_dx9"
---| "DecalBaseTimesLightmapAlphaBlendSelfIllum_DX8"
---| "DecalBaseTimesLightmapAlphaBlendSelfIllum_DX9"
---| "DecalModulate_dx9"
---| "DepthWrite" Used for writting depth buffer — render.GetResolvedFullFrameDepth.
---| "Downsample"
---| "Downsample_nohdr"
---| "Downsample_nohdr_DX80"
---| "Engine_Post_dx9"
---| "EyeGlint_dx9"
---| "EyeRefract_dx9"
---| "Eyes_dx6"
---| "Eyes_dx8"
---| "Eyes_dx9"
---| "Fillrate"
---| "floatcombine"
---| "floatcombine_autoexpose"
---| "floattoscreen"
---| "floattoscreen_vanilla"
---| "GooInGlass"
---| "HDRCombineTo16Bit"
---| "HDRSelectRange"
---| "hsl_filmgrain_pass1"
---| "hsl_filmgrain_pass2"
---| "HSV"
---| "IntroScreenSpaceEffect"
---| "IntroScreenSpaceEffect_dx80"
---| "LightmappedGeneric" The shader used for world brushes.
---| "LightmappedGeneric_Decal"
---| "LightmappedGeneric_DX8"
---| "LightmappedReflective" Used for reflective surfaces such as wet floor.
---| "LightmappedReflective_DX90"
---| "Modulate"
---| "Modulate_DX8"
---| "Modulate_DX9"
---| "MorphAccumulate_DX9"
---| "MorphWeight_DX9"
---| "MotionBlur_dx9"
---| "Occlusion_DX8"
---| "Occlusion_DX9"
---| "Overlay_Fit"
---| "Portal_DX60"
---| "Portal_DX80"
---| "Portal_DX90"
---| "PortalRefract_dx8"
---| "PortalRefract_dx9"
---| "PortalStaticOverlay"
---| "PortalStaticOverlay"
---| "PortalStaticOverlay_DX60"
---| "Predator_DX80"
---| "Refract"
---| "Refract_DX80"
---| "Refract_DX90"
---| "Sample4x4"
---| "Sample4x4_Blend"
---| "screenspace_general" Wrapper for providing custom pixel (and in some games vector) shaders.
---| "screenspace_general_dx8"
---| "screenspace_general_dx9"
---| "sfm_blurfilterx_shader"
---| "sfm_blurfiltery_shader"
---| "sfm_downsample_shader"
---| "sfm_integercombine_shader"
---| "Shadow"
---| "Shadow_DX8"
---| "ShadowBuild_DX8"
---| "ShadowBuild_DX9"
---| "ShadowModel_DX8"
---| "ShadowModel_DX9"
---| "ShatteredGlass"
---| "ShatteredGlass_DX8"
---| "showz" Depth buffer debugger.
---| "Sky_DX9"
---| "Sky_HDR_DX9"
---| "Sprite_DX8"
---| "Sprite_DX9"
---| "Spritecard"
---| "Spritecard_DX8"
---| "Teeth_DX6"
---| "Teeth_DX8"
---| "Teeth_DX9"
---| "TreeLeaf"
---| "UnlitGeneric" The shader used for GUI materials.
---| "UnlitGeneric_DX8"
---| "UnlitTwoTexture_DX8"
---| "UnlitTwoTexture_DX9"
---| "VertexLitGeneric" The shader used for models.
---| "VertexLitGeneric_DX8"
---| "VolumeClouds_dx9"
---| "VortWarp_dx8"
---| "VortWarp_DX9"
---| "Water_DX81"
---| "Water_DX90"
---| "WindowImposter_DX80"
---| "WindowImposter_DX90"
---| "Wireframe_DX8"
---| "Wireframe_DX9"
---| "WorldTwoTextureBlend"
---| "WorldTwoTextureBlend_DX8"
---| "WorldVertexAlpha_DX8"
---| "WorldVertexTransition_DX8"
---| "WorldVertexTransition_DX9"
---| "WriteStencil_DX8"
---| "WriteStencil_DX9"
---| "WriteZ_DX8"
---| "WriteZ_DX9"
---| "YUV"


--- [SHARED AND MENU]
---
--- https://developer.valvesoftware.com/wiki/Category:Shader_parameters
---
---@class dreamwork.std.Material.Shader.parameters
local shader_parameters = {}

---@type string | nil
shader_parameters[ "$basetexture" ] = nil

---@type string | nil
shader_parameters[ "$basetexture2" ] = nil

---@type VMatrix | nil
shader_parameters[ "$basetexturetransform" ] = nil

---@type VMatrix | nil
shader_parameters[ "$basetexturetransform2" ] = nil

---@type integer | nil
shader_parameters[ "$frame" ] = nil

---@type integer | nil
shader_parameters[ "$frame2" ] = nil

---@type string | nil
shader_parameters[ "$surfaceprop" ] = nil

-- TODO: https://developer.valvesoftware.com/wiki/Category:Shader_parameters ->>

shader_parameters[ "$decal" ] = nil
shader_parameters[ "$decalscale" ] = nil
shader_parameters[ "$modelmaterial" ] = nil
shader_parameters[ "$decalfadeduration" ] = nil
shader_parameters[ "$decalfadetime" ] = nil
shader_parameters[ "$decalsecondpass" ] = nil
shader_parameters[ "$fogscale" ] = nil
shader_parameters[ "$splatter" ] = nil
shader_parameters[ "$detail" ] = nil
shader_parameters[ "$detailtexturetransform" ] = nil
shader_parameters[ "$detailscale" ] = nil
shader_parameters[ "$detailblendfactor" ] = nil
shader_parameters[ "$detailblendmode" ] = nil
shader_parameters[ "$detailtint" ] = nil
shader_parameters[ "$detailframe" ] = nil
shader_parameters[ "$detail_alpha_mask_base_texture" ] = nil
shader_parameters[ "$detail2" ] = nil
shader_parameters[ "$detailscale2" ] = nil
shader_parameters[ "$detailblendfactor2" ] = nil
shader_parameters[ "$detailframe2" ] = nil
shader_parameters[ "$detailtint2" ] = nil

---@type boolean | nil
shader_parameters[ "$model" ] = nil


---@class dreamwork.std.Material.Shader
---@field name dreamwork.std.Material.Shader.name | nil
---@field parameters dreamwork.std.Material.Shader.parameters | nil
