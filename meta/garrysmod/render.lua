---@meta garrysmod.render

--- [CLIENT]
---
--- Capture options for `render.Capture`.
---
---@class garrysmod.RenderCaptureData
---@field format `"jpeg"` | `"jpg"` | `"png"` | `"rgba"` | `"rgb"` | `"bgra"` Format of the capture.
---@field x integer X coordinate of the capture origin.
---@field y integer Y coordinate of the capture origin.
---@field w integer Width of the capture.
---@field h integer Height of the capture.
---@field quality integer? The quality of the capture. Affects jpeg only.
---@field alpha boolean? Set to `false` to capture an image with alpha channel set to fully opaque. Affects formats with alpha support (not `jpg`). Defaults to `true`.

--- [CLIENT]
---
--- Orthographic bounds used by `garrysmod.ViewData` / `garrysmod.ViewSetup`.
---
---@class garrysmod.ViewData.Ortho
---@field left number
---@field right number
---@field top number
---@field bottom number

--- [CLIENT]
---
--- Off-center projection offsets used by `garrysmod.ViewData` / `garrysmod.ViewSetup`.
---
--- Note that `top` and `bottom` are reversed.
---
---@class garrysmod.ViewData.OffCenter
---@field left number Where the left edge starts. Natural value is `0`.
---@field right number Where the right edge ends. Natural value is equal to viewport width.
---@field top number Where the bottom edge starts. Natural value is `0`.
---@field bottom number Where the top edge ends. Natural value is equal to viewport height.

--- [CLIENT]
---
--- Table structure used for `render.RenderView`.
---
--- Unless stated otherwise, the default values for all these keys would be inherited from the engine's
--- `CViewSetup` and do not have static representations.
---
---@class garrysmod.ViewData
---@field origin garrysmod.Vector? The view's original position.
---@field angles garrysmod.Angle? The view's angles.
---@field aspect number? Defaults to width divided by height.
---@field aspectratio number? Deprecated alias of `aspect`. Use `aspect` instead.
---@field x number? The x position of the viewport to render in. Defaults to `0`.
---@field y number? The y position of the viewport to render in. Defaults to `0`.
---@field w number? The width of the viewport to render in.
---@field h number? The height of the viewport to render in.
---@field drawhud boolean? Draw the HUD and call the hud painting related hooks. Defaults to `false`.
---@field drawmonitors boolean? Draw monitors. Defaults to `false`.
---@field drawviewmodel boolean? The weapon's viewmodel. Defaults to `true`.
---@field drawviewer boolean? Whether to force draw the local player or not. Defaults to `false`.
---@field viewmodelfov number? The viewmodel's FOV.
---@field fov number? The main view's FOV.
---@field ortho garrysmod.ViewData.Ortho? If set, renders the view orthogonally.
---@field ortholeft number? Deprecated. Use `ortho` table instead.
---@field orthoright number? Deprecated. Use `ortho` table instead.
---@field orthotop number? Deprecated. Use `ortho` table instead.
---@field orthobottom number? Deprecated. Use `ortho` table instead.
---@field znear number? The distance of the view's origin to the near clipping plane.
---@field zfar number? The distance of the view's origin to the far clipping plane.
---@field znearviewmodel number? The distance of the view's origin to the near clipping plane for the viewmodel.
---@field zfarviewmodel number? The distance of the view's origin to the far clipping plane for the viewmodel.
---@field dopostprocess boolean? Currently works identically to `bloomtone` (also overrides it if set to `false`). Defaults to `false`.
---@field bloomtone boolean? Disables default engine bloom and pauses the "brightness changes" on HDR maps. Defaults to `true`.
---@field viewid integer? Identifying which logical part of the scene an entity is being rendered in. See `VIEW` enums. Defaults to `0`.
---@field offcenter garrysmod.ViewData.OffCenter? Off-center projection offsets for zooming into a portion of the screen.

--- [CLIENT]
---
--- Table structure returned by `render.GetViewSetup`.
---
---@class garrysmod.ViewSetup
---@field viewid integer The current view id. See `VIEW` enums.
---@field origin garrysmod.Vector The view's origin/position.
---@field angles garrysmod.Angle The view's angles.
---@field aspect number Width divided by height.
---@field x number The x position of the viewport.
---@field y number The y position of the viewport.
---@field width number The width of the viewport.
---@field height number The height of the viewport.
---@field fov number The main view's FOV, adjusted for aspect ratio.
---@field fov_unscaled number The main view's FOV as the user setting.
---@field fovviewmodel number The viewmodel's FOV, adjusted for aspect ratio.
---@field fovviewmodel_unscaled number The viewmodel's FOV as the user setting.
---@field ortho garrysmod.ViewData.Ortho? Present if the current view is orthogonal.
---@field znear number The distance of the view's origin to the near clipping plane.
---@field zfar number The distance of the view's origin to the far clipping plane.
---@field znearviewmodel number The distance of the view's origin to the near clipping plane for the viewmodel.
---@field zfarviewmodel number The distance of the view's origin to the far clipping plane for the viewmodel.
---@field bloomtone boolean Whether default engine bloom and tonemapping are enabled at this instant for this view.
---@field subrect boolean Whether `m_bRenderToSubrectOfLargerScreen` is set for this view.
---@field offcenter garrysmod.ViewData.OffCenter? Off-center projection offsets when offscreen rendering is enabled.

--- [CLIENT]
---
--- Table structure used for `render.SetLocalModelLights`.
---
---@class garrysmod.LocalLight
---@field type integer? The type of the light source. See `MATERIAL_LIGHT` enums. Defaults to `MATERIAL_LIGHT_POINT`.
---@field color garrysmod.Vector? The color of the light source (`x` red, `y` green, `z` blue).
---@field pos garrysmod.Vector? The origin of the light in world coordinates.
---@field dir garrysmod.Vector? The direction of the light. Only required for directional and spot lights.
---@field range number? The maximum range of the light source. Usually left at `0` for infinite range.
---@field angularFalloff number? Angular falloff exponent for spot lights. Defaults to `5`.
---@field innerAngle number? The inner cone angle for spot lights, in degrees. Defaults to `45`.
---@field outerAngle number? The outer cone angle for spot lights, in degrees. Defaults to `45`.
---@field fiftyPercentDistance number? The distance at which the light will fade to 50% of its brightness.
---@field zeroPercentDistance number? The distance at which the light will completely fade out.
---@field quadraticFalloff number? Quadratic term of light falloff. Defaults to `0`.
---@field linearFalloff number? Linear term of light falloff. Defaults to `0`.
---@field constantFalloff number? Constant term of light falloff. Defaults to `1`.

--- [CLIENT AND MENU]
---
--- The render library is a powerful set of functions that let you control how the world and its contents are rendered.
--- It can also be used to draw some 3D clientside effects such as beams, boxes and spheres.
---
---@class garrysmod.render
render = {}

--- [CLIENT]
---
--- Adds a Beam Segment to the Beam started by `render.StartBeam`.
---
--- For more detailed information on Beams, as well as usage examples, see the `Beams Render Reference`.
---
---@param start_pos garrysmod.Vector Beam start position.
---@param width number The width of the beam.
---@param texture_end number The end coordinate of the texture used.
---@param color garrysmod.Color The color to be used.
function render.AddBeam( start_pos, width, texture_end, color ) end

--- [CLIENT]
---
--- Binds a given texture as a cubemap. The texture given must be a cubemap texture.
---
--- This is useful in context of drawing models manually (`Entity:DrawModel`), especially in GUI
--- applications.
---
---@param tex_name string|nil The path to the texture (`.vtf`) to use, e.g. `editor/cubemap`.  The function will automatically select the `.hdr` version of the texture based on player's current settings.  Set to `nil` to unbind a cubemap, which will result in pitch black cubemap.
function render.BindLocalCubemap( tex_name ) end

--- [CLIENT]
---
--- This function overrides the brush material for next render operations. It can be used with
--- `Entity:DrawModel`.
---
---@param mat garrysmod.Material?
function render.BrushMaterialOverride( mat ) end

--- [CLIENT]
---
--- Captures a part of the current render target and returns the data as a binary string in the given
--- format.
---
--- Since the pixel buffer clears itself every frame, this will return a black screen outside of render
--- hooks. To capture the user's final view, use `GM:PostRender`. This will not capture the Steam
--- overlay or third-party injections (such as the Discord overlay, Overwolf, and advanced cheats) on
--- the user's screen.
---
--- > **WARNING**: In PNG mode, this function can produce unexpected result where foreground is rendered as transparent.
--- This is caused by `render.SetWriteDepthToDestAlpha` set to `true` when doing most of render operations, including rendering in `_rt_fullframefb`. If you want to capture render target's content as PNG image only for output quality, set `garrysmod.RenderCaptureData`'s `alpha` to `false` when capturing render targets with `render.SetWriteDepthToDestAlpha` set to `true`.
---
--- > **WARNING**: This function will return nil if escape menu is open.
---
---@param capture_data garrysmod.RenderCaptureData Parameters of the capture.
---@return string data Captured data as a binary string.
function render.Capture( capture_data ) end

--- [CLIENT]
---
--- Dumps the current render target and allows the pixels to be accessed by `render.ReadPixel`.
---
--- Capturing outside a render hook will return an image filled with `0 0 0 255`.
---
--- See also `render.Capture`.
---
function render.CapturePixels() end

--- [CLIENT AND MENU]
---
--- Clears the current render target and the specified buffers.
---
--- > **BUG** (#2085): This sets the alpha incorrectly for `surface` draw calls for render targets.
---
---@param r number Red component to clear to.
---@param g number Green component to clear to.
---@param b number Blue component to clear to.
---@param a number Alpha component to clear to.
---@param clear_depth boolean? Clear the depth. Defaults to `false`.
---@param clear_stencil boolean? Clear the stencil. Defaults to `false`.
function render.Clear( r, g, b, a, clear_depth, clear_stencil ) end

--- [CLIENT AND MENU]
---
--- Tests every pixel of the active `Render Target` against the current Stencil configuration and sets
--- the Color Channel values and, optionally, the Depth Buffer values for every pixel that passes.
---
--- For more detailed information on the Stencil system, including usage examples, see the `Stencils
--- Render Reference` page
---
--- > **NOTE**: This function does **not** clear the Stencil Buffer on its own.
--- If you would like to clear the Stencil Buffer, you can use `render.ClearStencil`.
---
---@param red number The red Color Channel value for each pixel that is cleared. Must be an integer value in the range 0-255 (`byte`).
---@param green number The green Color Channel value for each pixel that is cleared. Must be an integer value in the range 0-255 (`byte`).
---@param blue number The blue Color Channel value for each pixel that is cleared. Must be an integer value in the range 0-255 (`byte`).
---@param alpha number The alpha (translucency) Color Channel value for each pixel that is cleared. Must be an integer value in the range 0-255 (`byte`).
---@param clear_depth boolean If true, reset the Depth Buffer values.
function render.ClearBuffersObeyStencil( red, green, blue, alpha, clear_depth ) end

--- [CLIENT AND MENU]
---
--- Resets the depth buffer.
---
---@param clear_stencil boolean? Whether to also clear the stencil buffer. Defaults to `true`.
function render.ClearDepth( clear_stencil ) end

--- [CLIENT AND MENU]
---
--- Sets the Stencil Buffer value to `0` for all pixels in the currently active `Render Target`.
---
--- For more detailed information on the Stencil system, including usage examples, see the `Stencils
--- Render Reference` page.
---
function render.ClearStencil() end

--- [CLIENT AND MENU]
---
--- Sets the Stencil Buffer value for every pixel in a given rectangle to a given value.
---
--- This is **not** affected by `render.SetStencilWriteMask`.
---
--- For more detailed information on the Stencil system, including usage examples, see the `Stencils
--- Render Reference` page.
---
---@param start_x number The X coordinate of the top left corner of the rectangle to be cleared.
---@param start_y number The Y coordinate of the top left corner of the rectangle to be cleared.
---@param end_x number The X coordinate of the bottom right corner of the rectangle to be cleared. **Note:** Unlike some other rectangle-based functions, this is **not** the width of the rectangle.
---@param end_y number The Y coordinate of the bottom right corner of the rectangle to be cleared. **Note:** Unlike some other rectangle-based functions, this is **not** the height of the rectangle.
---@param stencil_buffer_value number The Stencil Buffer value that all pixels within the rectangle will be set to.
function render.ClearStencilBufferRectangle( start_x, start_y, end_x, end_y, stencil_buffer_value ) end

--- [CLIENT]
---
--- Calculates the lighting caused by dynamic lights (such as `DynamicLight` and the Light Sandbox
--- tool) for the specified surface. This will not include map ambient light.
---
--- See also `render.ComputeLighting` for a function that also includes map's ambient lighting.
---
---@param position garrysmod.Vector The position to sample from.
---@param normal garrysmod.Vector The normal of the surface.
---@return garrysmod.Vector color The combined color as a vector.
function render.ComputeDynamicLighting( position, normal ) end

--- [CLIENT]
---
--- Calculates the light color at a certain position.
---
--- This includes both ambient light and dynamic light.
---
--- See `render.ComputeDynamicLighting` for dynamic light only.
---
--- See `render.GetAmbientLightColor` for map-wide ambient color.
---
---@param position garrysmod.Vector The position to get the light at.
---@param normal garrysmod.Vector? The direction of an imaginary surface to get the light at.  Pointing away from walls will get the lighting the wall receives. Pointing towards walls will not.
---@return garrysmod.Vector color The combined color as a vector.
function render.ComputeLighting( position, normal ) end

--- [CLIENT]
---
--- Calculates diameter of a 3D sphere on a 2D screen.
---
---@param point garrysmod.Vector The position of the sphere in 3D space.
---@param radius number The radius of the sphere in 3D space.
---@return number value The diameter of the sphere in 2D screen space.
function render.ComputePixelDiameterOfSphere( point, radius ) end

--- [CLIENT]
---
--- Copies the currently active Render Target to the specified texture.
---
--- > **WARNING**: This does not copy the Depth buffer, no method for that is known at this moment so a common workaround is to store the source texture somewhere else, perform your drawing operations, save the result somewhere else and reapply the source texture.
---
---@param target garrysmod.Texture The texture to copy to.
function render.CopyRenderTargetToTexture( target ) end

--- [CLIENT AND MENU]
---
--- Sets the cull mode. The culling mode defines how back faces are culled when rendering geometry.
---
---@param cull_mode number Cullmode, see `MATERIAL_CULLMODE`.
function render.CullMode( cull_mode ) end

--- [CLIENT]
---
--- Set's the depth range of the upcoming render.
---
--- > **NOTE**: Viewmodels get drawn with a depth range of `0` to `0.1` instead of the normal `0` to `1`. Incorrectly resetting the value can cause rendering issues.
---
---@param depthmin number The minimum depth of the upcoming render. `0.0` = render normally; `1.0` = render nothing.
---@param depthmax number The maximum depth of the upcoming render. `0.0` = render everything (through walls); `1.0` = render normally.
function render.DepthRange( depthmin, depthmax ) end

--- [CLIENT]
---
--- Draws a single-segment Beam made out of a textured, billboarded quad stretching between two points.
---
--- For more detailed information, including usage examples, see the `Beams Render Reference`.
---
---@param start_pos garrysmod.Vector The Beam's start position.
---@param end_pos garrysmod.Vector The Beam's end position.
---@param width number The width of the Beam.
---@param texture_start number The starting coordinate of the Beam's texture.
---@param texture_end number The end coordinate of the Beam's texture.
---@param color garrysmod.Color? What `Color` to tint the Beam. Defaults to `Color( 255, 255, 255 )`.
function render.DrawBeam( start_pos, end_pos, width, texture_start, texture_end, color ) end

--- [CLIENT]
---
--- Draws a box in 3D space.
---
---@param position garrysmod.Vector Origin of the box.
---@param angles garrysmod.Angle Orientation of the box.
---@param mins garrysmod.Vector Start position of the box, relative to origin.
---@param maxs garrysmod.Vector End position of the box, relative to origin.
---@param color garrysmod.Color? The color of the box. Defaults to `Color( 255, 255, 255 )`.
function render.DrawBox( position, angles, mins, maxs, color ) end

--- [CLIENT]
---
--- Draws a line in 3D space.
---
---@param start_pos garrysmod.Vector Line start position in world coordinates.
---@param end_pos garrysmod.Vector Line end position in world coordinates.
---@param color garrysmod.Color? The color to be used. Uses `Color`. Defaults to `Color( 255, 255, 255 )`.
---@param write_z boolean? Whether or not to consider the Z buffer. If false, the line will be drawn over everything currently drawn, if true, the line will be drawn with depth considered, as if it were a regular object in 3D space.  Enabling this option will cause the line to ignore the color's alpha. Defaults to `false`.
function render.DrawLine( start_pos, end_pos, color, write_z ) end

--- [CLIENT]
---
--- Draws 2 connected triangles. Expects material to be set by `render.SetMaterial`.
---
---@param vert1 garrysmod.Vector First vertex.
---@param vert2 garrysmod.Vector The second vertex.
---@param vert3 garrysmod.Vector The third vertex.
---@param vert4 garrysmod.Vector The fourth vertex.
---@param color garrysmod.Color? The color of the quad. Defaults to `Color( 255, 255, 255 )`.
function render.DrawQuad( vert1, vert2, vert3, vert4, color ) end

--- [CLIENT]
---
--- Draws a quad. Expects material to be set by `render.SetMaterial`.
---
---@param position garrysmod.Vector Origin of the sprite.
---@param normal garrysmod.Vector The face direction of the quad.
---@param width number The width of the quad.
---@param height number The height of the quad.
---@param color garrysmod.Color The color of the quad.
---@param rotation number? The rotation of the quad counter-clockwise in degrees around the normal axis. In other words, the quad will always face the same way but this will rotate its corners. Defaults to `0`.
function render.DrawQuadEasy( position, normal, width, height, color, rotation ) end

--- [CLIENT]
---
--- Draws the current material set by `render.SetMaterial` to the whole screen. The color cannot be
--- customized.
---
--- See also `render.DrawScreenQuadEx`.
---
---@param apply_poster boolean? If set to true, when rendering a poster the quad will be properly drawn in parts in the poster. This is used internally by some Post Processing effects. Certain special textures (frame buffer like textures) do not need this adjustment. Defaults to `false`.
function render.DrawScreenQuad( apply_poster ) end

--- [CLIENT]
---
--- Draws the current material set by `render.SetMaterial` to the area specified. Color cannot be
--- customized.
---
--- See also `render.DrawScreenQuad`.
---
---@param start_x number X start position of the rect.
---@param start_y number Y start position of the rect.
---@param width number Width of the rect.
---@param height number Height of the rect.
function render.DrawScreenQuadEx( start_x, start_y, width, height ) end

--- [CLIENT]
---
--- Draws a sphere in 3D space. The material previously set with `render.SetMaterial` will be applied
--- the sphere's surface.
---
--- See also `render.DrawWireframeSphere` for a wireframe equivalent.
---
---@param position garrysmod.Vector Position of the sphere.
---@param radius number Radius of the sphere. Negative radius will make the sphere render inwards rather than outwards.
---@param longitude_steps number The number of longitude steps. This controls the quality of the sphere. Higher quality will lower performance significantly. 50 is a good number to start with.
---@param latitude_steps number The number of latitude steps. This controls the quality of the sphere. Higher quality will lower performance significantly. 50 is a good number to start with.
---@param color garrysmod.Color? The color of the sphere. Defaults to `Color( 255, 255, 255 )`.
function render.DrawSphere( position, radius, longitude_steps, latitude_steps, color ) end

--- [CLIENT]
---
--- Draws a sprite in 3D space.
---
---@param position garrysmod.Vector Position of the sprite.
---@param width number Width of the sprite.
---@param height number Height of the sprite.
---@param color garrysmod.Color? Color of the sprite. Defaults to `Color( 255, 255, 255 )`.
function render.DrawSprite( position, width, height, color ) end

--- [CLIENT]
---
--- Draws a wireframe box in 3D space.
---
---@param position garrysmod.Vector Position of the box.
---@param angle garrysmod.Angle Angles of the box.
---@param mins garrysmod.Vector The lowest corner of the box.
---@param maxs garrysmod.Vector The highest corner of the box.
---@param color garrysmod.Color? The color of the box. Defaults to `Color( 255, 255, 255 )`.
---@param write_z boolean? Sets whenever to write to the zBuffer. Defaults to `false`.
function render.DrawWireframeBox( position, angle, mins, maxs, color, write_z ) end

--- [CLIENT]
---
--- Draws a wireframe sphere in 3d space.
---
---@param position garrysmod.Vector Position of the sphere.
---@param radius number The size of the sphere.
---@param longitude_steps number The amount of longitude steps. The larger this number is, the smoother the sphere is.
---@param latitude_steps number The amount of latitude steps. The larger this number is, the smoother the sphere is.
---@param color garrysmod.Color? The color of the wireframe. Defaults to `Color( 255, 255, 255 )`.
---@param write_z boolean? Whether or not to consider the Z buffer. If false, the wireframe will be drawn over everything currently drawn. If true, it will be drawn with depth considered, as if it were a regular object in 3D space. Defaults to `false`.
function render.DrawWireframeSphere( position, radius, longitude_steps, latitude_steps, color, write_z ) end

--- [CLIENT AND MENU]
---
--- Sets the status of the clip renderer, returning previous state.
---
--- > **WARNING**: To prevent unintended rendering behavior of other mods/the game, you must reset the clipping state to its previous value.
---
---@param state boolean New clipping state.
---@return boolean was_enabled Whether clipping was previously enabled.
function render.EnableClipping( state ) end

--- [CLIENT]
---
--- Ends the beam mesh of a beam started with `render.StartBeam`.
---
--- For more detailed information on Beams, as well as usage examples, see the `Beams Render Reference`.
---
function render.EndBeam() end

--- [CLIENT]
---
--- Sets the color of the fog.
---
---@param red number Red channel of the fog color, 0 - 255.
---@param green number Green channel of the fog color, 0 - 255.
---@param blue number Blue channel of the fog color, 0 - 255.
function render.FogColor( red, green, blue ) end

--- [CLIENT]
---
--- Sets the at which the fog reaches its max density.
---
---@param distance number The distance at which the fog reaches its max density.  If used in `GM:SetupSkyboxFog`, this value **must** be scaled by the first argument of the hook
function render.FogEnd( distance ) end

--- [CLIENT]
---
--- Sets the maximum density of the fog.
---
---@param max_density number The maximum density of the fog, 0-1.
function render.FogMaxDensity( max_density ) end

--- [CLIENT]
---
--- Sets the mode of fog.
---
---@param fog_mode integer Fog mode, see `MATERIAL_FOG`.
function render.FogMode( fog_mode ) end

--- [CLIENT]
---
--- Sets the distance at which the fog starts showing up.
---
---@param fog_start number The distance at which the fog starts showing up. If used in `GM:SetupSkyboxFog`, this value **must** be scaled by the first argument of the hook
function render.FogStart( fog_start ) end

--- [CLIENT]
---
--- Returns the ambient color intensity of the map, basically the color the sky emits.
---
--- This is used by the engine to calculate shadow color using the following formula: `ambientLight * 3
--- + Vector( 0.3, 0.3, 0.3 )`
---
--- See also `render.ComputeLighting`.
---
---@return garrysmod.Vector color The ambient light color as a vector.
function render.GetAmbientLightColor() end

--- [CLIENT]
---
--- Returns the current alpha blending.
---
---@return number blend The current blending factor from `0` to `1`.
function render.GetBlend() end

--- [CLIENT]
---
--- > **INTERNAL**: You can use `GetRenderTargetEx` if you need to create a Render Target
---
--- Returns the Render Target texture that is used internally for the `DrawBloom` `Post Processing`
--- effect.
---
---@return garrysmod.Texture texture The bloom texture.
function render.GetBloomTex0() end

--- [CLIENT]
---
--- > **INTERNAL**: You probably want to just use a custom render target. See `GetRenderTargetEx`.
---
--- Returns the Render Target texture used internally for the `Blur` `Post Processing` effect.
---
--- Despite its name, this function is not used for the `DrawBloom` effect.
---
---@return garrysmod.Texture texture The bloom texture.
function render.GetBloomTex1() end

--- [CLIENT]
---
--- Returns the current color modulation values as normals.
---
---@return number r Red multiplier.
---@return number g Green multiplier.
---@return number b Blue multiplier.
function render.GetColorModulation() end

--- [CLIENT AND MENU]
---
--- Returns the maximum available directX version.
---
---@return integer dx_level The current DirectX level.
function render.GetDXLevel() end

--- [CLIENT]
---
--- Returns the current fog color.
---
---@return number r Red channel.
---@return number g Green channel.
---@return number b Blue channel.
function render.GetFogColor() end

--- [CLIENT]
---
--- Returns the fog start and end distance.
---
---@return number fog_start The starting distance of the fog.
---@return number fog_end The ending distance of the fog.
---@return number fog_z The Z distance used by `MATERIAL_FOG_LINEAR_BELOW_FOG_Z`.
function render.GetFogDistances() end

--- [CLIENT]
---
--- Get the maximum density of the fog.
---
---@return number max_density The maximum fog density.
function render.GetFogMaxDensity() end

--- [CLIENT]
---
--- Returns the current fog mode.
---
---@return integer fog_mode Fog mode. See `MATERIAL_FOG` enums.
function render.GetFogMode() end

--- [CLIENT]
---
--- Returns the full screen depth texture.
---
--- > **DEPRECATED**: Alias of `render.GetPowerOfTwoTexture` in practice.
---
---@return garrysmod.Texture texture The fullscreen depth texture.
---@deprecated Alias of `render.GetPowerOfTwoTexture` in practice.
function render.GetFullScreenDepthTexture() end

--- [CLIENT AND MENU]
---
--- Returns whether HDR is currently enabled or not. This takes into account hardware support, current
--- map and current client settings.
---
---@return boolean hdr_enabled Whether HDR is enabled.
function render.GetHDREnabled() end

--- [CLIENT]
---
--- Gets the light exposure on the specified position.
---
--- This is effectively the same as `render.ComputeLighting` without the `normal` argument provided.
---
--- > **DEPRECATED**: Same as `render.ComputeLighting` without the `normal` argument provided, so just use that
---
---@param position garrysmod.Vector The position of the surface to get the light from.
---@return garrysmod.Vector color The lighting combined with ambient color as a vector.
---@deprecated Same as `render.ComputeLighting` without the `normal` argument provided, so just use that
function render.GetLightColor( position ) end

--- [CLIENT]
---
--- > **INTERNAL**: You probably want to just use a custom render target. See `GetRenderTargetEx`.
---
--- Returns the first render target texture that is used internally for Motion Blur and Frame Blend
--- post processing effects.
---
---@return garrysmod.Texture texture The motion blur texture.
function render.GetMoBlurTex0() end

--- [CLIENT]
---
--- > **INTERNAL**: You probably want to just use a custom render target. See `GetRenderTargetEx`.
---
--- Returns the second render target texture that is used internally for Motion Blur and Frame Blend
--- post processing effects.
---
---@return garrysmod.Texture texture The motion blur texture.
function render.GetMoBlurTex1() end

--- [CLIENT]
---
--- > **INTERNAL**: You probably want to just use a custom render target. See `GetRenderTargetEx`.
---
--- Returns the first render target texture that was used internally for Morph post processing effect
---
--- The post processing effect was removed from the base game at some point during development of
--- Garry's Mod 13, but can still be found as a community mod:
--- https://steamcommunity.com/sharedfiles/filedetails/?id=501088470
---
---@return garrysmod.Texture texture The morph texture.
function render.GetMorphTex0() end

--- [CLIENT]
---
--- > **INTERNAL**: You probably want to just use a custom render target. See `GetRenderTargetEx`.
---
--- Returns the second render target texture that was used internally for Morph post processing effect.
---
--- See `render.GetMorphTex0` for more information..
---
---@return garrysmod.Texture texture The morph texture.
function render.GetMorphTex1() end

--- [CLIENT]
---
--- Returns the Power Of Two Frame Buffer texture.
---
---@return garrysmod.Texture texture The power-of-two texture.
function render.GetPowerOfTwoTexture() end

--- [CLIENT]
---
--- Alias of `render.GetPowerOfTwoTexture`.
---
--- > **DEPRECATED**: Alias of `render.GetPowerOfTwoTexture`.
---
---@return garrysmod.Texture texture The refract texture.
---@deprecated Alias of `render.GetPowerOfTwoTexture`.
function render.GetRefractTexture() end

--- [CLIENT]
---
--- Returns the currently active render target.
---
--- Instead of saving the current render target using this function and restoring to it later, it is
--- generally better practice to use `render.PushRenderTarget` and `render.PopRenderTarget`.
---
---@return garrysmod.Texture? texture The current active render target.
function render.GetRenderTarget() end

--- [CLIENT]
---
--- Returns the `_rt_ResolvedFullFrameDepth` texture for SSAO depth. It will only be updated if
--- `GM:NeedsDepthPass` returns true. Depth is written using the `Shaders/DepthWrite` by rendering
--- scene a second time, using [SSAO_DepthPass
--- function](https://github.com/ValveSoftware/source-sdk-2013/blob/11a677c349b149b2f77184dc903e6bb17f8d
--- f69b/src/game/client/viewrender.cpp#L5576).
---
---@return garrysmod.Texture texture The resolved full frame depth texture.
function render.GetResolvedFullFrameDepth() end

--- [CLIENT]
---
--- Obtain an `garrysmod.Texture` of the screen. You must call `render.UpdateScreenEffectTexture` in order to
--- update this texture with the currently rendered scene.
---
--- This texture is mainly used within `GM:RenderScreenspaceEffects`.
---
---@param texture_index number? Max index is 3, but engine only creates the first two for you. Defaults to `0`.
---@return garrysmod.Texture texture The screen effect texture.
function render.GetScreenEffectTexture( texture_index ) end

--- [CLIENT]
---
--- Returns the first quarter sized frame buffer texture.
---
---@return garrysmod.Texture texture The small texture.
function render.GetSmallTex0() end

--- [CLIENT]
---
--- Returns the second quarter sized frame buffer texture.
---
---@return garrysmod.Texture texture The small texture.
function render.GetSmallTex1() end

--- [CLIENT]
---
--- Returns a floating point texture (RGBA16161616F format) the same resolution as the screen.
---
--- > **NOTE**: The `gmodscreenspace` doesn't behave as expected when drawing a floating-point texture to an integer texture (e.g. the default render target). Use an UnlitGeneric material instead
---
---@return garrysmod.Texture texture The floating point texture.
function render.GetSuperFPTex() end

--- [CLIENT]
---
--- See `render.GetSuperFPTex`.
---
---@return garrysmod.Texture texture The floating point texture.
function render.GetSuperFPTex2() end

--- [CLIENT]
---
--- Performs a render trace and returns the color of the surface hit, this uses a low res version of
--- the texture.
---
---@param start_pos garrysmod.Vector The start position to trace from.
---@param end_pos garrysmod.Vector The end position of the trace.
---@return garrysmod.Vector color The surface color.
function render.GetSurfaceColor( start_pos, end_pos ) end

--- [CLIENT]
---
--- Returns a vector representing linear tone mapping scale. See `render.SetToneMappingScaleLinear` for
--- details.
---
---@return garrysmod.Vector scales The tonemapping scales (`X` output, `Y` lightmap, `Z` reflection).
function render.GetToneMappingScaleLinear() end

--- [CLIENT]
---
--- Returns the current view setup.
---
---@param no_player boolean? If `true`, returns the `view->GetViewSetup`, if `false` - returns `view->GetPlayerViewSetup`. Defaults to `false`.
---@return garrysmod.ViewSetup setup Current view setup.
function render.GetViewSetup( no_player ) end

--- [CLIENT]
---
--- Lets you know when a screenshot is being taken during rendering hooks.
---
--- This is useful to hide certain visual elements from screenshots, such as debug overlays, helper
--- objects, etc.
---
---@return boolean is_taking_screenshot Returns `true` when a screenshot is being taken.
function render.IsTakingScreenshot() end

--- [CLIENT]
---
--- Sets the render material override for all next calls of `Entity:DrawModel`. Also overrides
--- `render.MaterialOverrideByIndex`.
---
--- See `render.WorldMaterialOverride`, `render.BrushMaterialOverride` and
--- `render.ModelMaterialOverride` for similar functions.
---
--- > **WARNING**: In certain scenarios such as during entity's shadow pass, using this function can cause unexpected side effects. See example below on how to deal with this.
---
---@param material garrysmod.Material? The material to use as override, use `nil` to disable.
function render.MaterialOverride( material ) end

--- [CLIENT]
---
--- Similar to `render.MaterialOverride`, but overrides the materials per index. For simple entities
--- you may want to just use `Entity:SetSubMaterial`.
---
--- `render.MaterialOverride` overrides effects of this function.
---
---@param index number? The index of the material to override, in range of 0 to 31. `nil` will reset all overrides.
---@param material garrysmod.Material? The material to override with, `nil` will reset the override for given index.
function render.MaterialOverrideByIndex( index, material ) end

--- [CLIENT AND MENU]
---
--- Returns the maximum texture height the renderer can handle.
---
---@return integer height The maximum texture height.
function render.MaxTextureHeight() end

--- [CLIENT AND MENU]
---
--- Returns the maximum texture width the renderer can handle.
---
---@return integer width The maximum texture width.
function render.MaxTextureWidth() end

--- [CLIENT]
---
--- Forces all future draw operations to use a specific `garrysmod.Material`.
---
--- Because this is independent of a specific `Entity`, it can be used to change materials on static
--- models that are part of maps.
---
--- > **WARNING**: In certain scenarios such as during entity's shadow pass, using this function can cause unexpected side effects. See example on `render.MaterialOverride` about dealing with this.
---
---@param material garrysmod.Material? The `garrysmod.Material` that will be used for all upcoming draw operations, or `nil` to stop overriding.
function render.ModelMaterialOverride( material ) end

--- [CLIENT AND MENU]
---
--- Overrides the write behaviour of all next rendering operations towards the alpha channel of the
--- current render target.
---
--- See also `render.OverrideBlend`.
---
--- > **NOTE**: Doing `surface` draw calls with alpha set to 0 is a no-op and will never have any effect.
---
---@param enable boolean Enable or disable the override.
---@param should_write boolean? If the previous argument is true, sets whether the next rendering operations should write to the alpha channel or not. Has no effect if the previous argument is false.
function render.OverrideAlphaWriteEnable( enable, should_write ) end

---@overload fun( enabled: boolean, source_color_multiplier: integer, destination_color_multiplier: integer, color_blending_function: integer, source_alpha_multiplier: integer?, destination_alpha_multiplier: integer?, alpha_blending_function: integer? )
---@overload fun( enabled: boolean )
--- [CLIENT AND MENU]
---
--- Overrides the way that the final color and alpha is calculated for each pixel affected by upcoming
--- draw operations.
---
--- When a draw operation is performed, the rendering system examines each pixel that is affected by
--- the draw operation and determines its new color by combining (or "Blending") the pixel's current
--- color (Called the "Destination" or "Dst" color) with the new color produced by the draw operation
--- (Called the "Source" or "Src" color.)
---
--- This function allows you to control the way that those two colors (The Source and Destination) are
--- combined to produce the final pixel color.
---
--- It's important to know that while `Color` use values in the range `(0-255)`, the color and alpha
--- values used here are normalized to the range `(0-1)` so that they can be multiplied together to
--- produce a value that is still in the range `(0-1)`.
---
---@param enabled boolean Set to `true` to enable Blend Overrides.
---@param source_multiplier integer This determines which value each affected pixel's **Source color and alpha** will be multiplied by before they are sent to the Blending Function. One of the `BLEND` enums.
---@param destination_multiplier integer This determines which value each affected pixel's **Destination color and alpha** will be multiplied by before they are sent to the Blending Function. One of the `BLEND` enums.
---@param blending_function integer After the Source and Destination color and alpha have been multiplied against their corresponding multipliers, they are passed to the Blending Function which combines them into the final color and alpha for the pixel. One of the `BLENDFUNC` enums.
function render.OverrideBlend( enabled, source_multiplier, destination_multiplier, blending_function ) end

--- [CLIENT AND MENU]
---
--- Overrides the internal graphical functions used to determine the final color and alpha of a
--- rendered texture.
---
--- See also `render.OverrideAlphaWriteEnable`.
---
--- > **NOTE**: Doing `surface` draw calls with alpha set to 0 is a no-op and will never have any effect.
---
--- > **DEPRECATED**: Use `render.OverrideBlend` instead.
---
---@param enabled boolean true to enable, false to disable. No other arguments are required when disabling.
---@param src_blend number The source color blend function `BLEND`. Determines how a rendered texture's final color should be calculated.
---@param dest_blend number
---@param src_blend_alpha number? The source alpha blend function `BLEND`. Determines how a rendered texture's final alpha should be calculated.
---@param dest_blend_alpha number?
---@deprecated Use `render.OverrideBlend` instead.
function render.OverrideBlendFunc( enabled, src_blend, dest_blend, src_blend_alpha, dest_blend_alpha ) end

--- [CLIENT AND MENU]
---
--- Overrides the write behaviour of all next rendering operations towards the color channel of the
--- current render target.
---
---@param enable boolean Enable or disable the override.
---@param should_write boolean If the previous argument is true, sets whether the next rendering operations should write to the color channel or not. Anything drawn after will still write to depth if enabled and shouldWrite is false.
function render.OverrideColorWriteEnable( enable, should_write ) end

--- [CLIENT AND MENU]
---
--- Overrides the write behaviour of all next rendering operations towards the depth buffer.
---
---@param enable boolean Enable or disable the override.
---@param should_write boolean If the previous argument is true, sets whether the next rendering operations should write to the depth buffer or not. Has no effect if the previous argument is false.
function render.OverrideDepthEnable( enable, should_write ) end

--- [CLIENT AND MENU]
---
--- Performs a Stencil operation on every pixel in the active `Render Target` without performing a draw
--- operation.
---
--- For more detailed information on the Stencil system, including usage examples, see the `Stencils
--- Render Reference` page.
---
function render.PerformFullScreenStencilOperation() end

--- [CLIENT AND MENU]
---
--- Removes the current active clipping plane from the clip plane stack.
---
function render.PopCustomClipPlane() end

--- [CLIENT AND MENU]
---
--- Pops (Removes) the texture filter most recently pushed (Added) onto the magnification texture
--- filter stack.
---
--- This function should only be called *after* a magnification filter has been pushed via
--- `render.PushFilterMag`.
---
--- For more detailed information and a usage example, see `the texture minification and magnification
--- render reference.`
---
function render.PopFilterMag() end

--- [CLIENT AND MENU]
---
--- Pops (Removes) the texture filter most recently pushed (Added) onto the minification texture filter
--- stack.
---
--- This function should only be called *after* a minification filter has been pushed via
--- `render.PushFilterMin()`.
---
--- For more detailed information and a usage example, see `the texture minification and magnification
--- render reference.`
---
function render.PopFilterMin() end

--- [CLIENT]
---
--- Pops the current flashlight mode from the flashlight mode stack.
---
function render.PopFlashlightMode() end

--- [CLIENT]
---
--- Pops the last render target and viewport from the RT stack and sets them as the current render
--- target and viewport.
---
--- This is should be called to restore the previous render target and viewport after a call to
--- `render.PushRenderTarget`.
---
function render.PopRenderTarget() end

--- [CLIENT AND MENU]
---
--- Pushes a new clipping plane of the clip plane stack and sets it as active.
---
--- > **BUG** (#2687): A max of 2 clip planes are supported on Linux/POSIX, and 6 on Windows.
---
---@param normal garrysmod.Vector The normal of the clipping plane.
---@param distance number The distance of the plane from the world origin. You can use `Vector:Dot` between the normal and any point on the plane to find this.
function render.PushCustomClipPlane( normal, distance ) end

--- [CLIENT AND MENU]
---
--- Pushes (Adds) a texture filter onto the magnification texture filter stack.
--- This will modify how textures are stretched to sizes larger than their native resolution for
--- upcoming rendering and drawing operations.
--- For a version of this same function that modifies filtering for texture sizes smaller than their
--- native resolution, see `render.PushFilterMin`
---
--- Always be sure to call `render.PopFilterMag` afterwards to avoid texture filtering problems.
---
--- For more detailed information and a usage example, see `the texture minification and magnification
--- render reference.`
---
--- If current texture has more than 1 mipmap, this also sets the mipmap filter.
---
---@param tex_filter_type number The texture filter to use. For available options, see `TEXFILTER`.
function render.PushFilterMag( tex_filter_type ) end

--- [CLIENT AND MENU]
---
--- Pushes (Adds) a texture filter onto the minification texture filter stack.
--- This will modify how textures are compressed to a lower resolution than their native resolution for
--- upcoming rendering and drawing operations.
--- For a version of this same function that modifies filtering for texture sizes larger than their
--- native resolution, see `render.PushFilterMag()`
---
--- Always be sure to call `render.PopFilterMin()` afterwards to avoid texture filtering problems.
---
--- For more detailed information and a usage example, see `the texture minification and magnification
--- render reference.`
---
---@param tex_filter_type number The texture filter to use. For available options, see `TEXFILTER`.
function render.PushFilterMin( tex_filter_type ) end

--- [CLIENT]
---
--- Enables the flashlight projection for the upcoming rendering.
---
--- > **DEPRECATED**: This will leave models lit under specific conditions. You should use `render.RenderFlashlights` which is meant as a direct replacement for this function.
---
---@param enable boolean? Whether the flashlight mode should be enabled or disabled. Defaults to `false`.
---@deprecated This will leave models lit under specific conditions. You should use `render.RenderFlashlights` which is meant as a direct replacement for this function.
function render.PushFlashlightMode( enable ) end

--- [CLIENT]
---
--- Pushes the current render target and viewport to the RT stack then sets a new current render target
--- and viewport. If the viewport is not specified, the dimensions of the render target are used
--- instead.
---
--- This is similar to a call to `render.SetRenderTarget` and `render.SetViewPort` where the current
--- render target and viewport have been saved beforehand, except the viewport isn't clipped to screen
--- bounds.
---
--- See also `render.PopRenderTarget`.
---
--- > **NOTE**: If you want to render to the render target in 2d mode and it is not the same size as the screen, use `cam.Start2D` and `cam.End2D`.
---
--- > **NOTE**: If the render target is bigger than the screen, rendering done with the surface library will be clipped to the screen bounds unless you call `DisableClipping`
---
---@param texture garrysmod.Texture? The new render target to be used. Can be set to `nil` to push the main game frame buffer.
---@param x number? X origin of the viewport. Defaults to `0`.
---@param y number? Y origin of the viewport. Defaults to `0`.
---@param w number? Width of the viewport. Defaults to `texture:Width()`.
---@param h number? Height of the viewport. Defaults to `texture:Height()`.
function render.PushRenderTarget( texture, x, y, w, h ) end

--- [CLIENT]
---
--- Reads the color of the specified pixel from the RenderTarget sent by `render.CapturePixels`
---
---@param x number The x coordinate.
---@param y number The y coordinate.
---@return number r The red channel value.
---@return number g The green channel value.
---@return number b The blue channel value.
---@return number? a The alpha channel value, or no value if the render target has no alpha channel.
function render.ReadPixel( x, y ) end

--- [CLIENT]
---
--- This applies the changes made to map lighting using `engine.LightStyle`.
---
---@param do_static_props boolean? When true, this will also apply lighting changes to static props. This is really slow on large maps. Defaults to `false`.
---@param update_static_lighting boolean? Forces all props to update their static lighting. Can be slow. Defaults to `false`.
function render.RedownloadAllLightmaps( do_static_props, update_static_lighting ) end

--- [CLIENT]
---
--- Renders additive flashlights on an `IMesh`, a direct replacement for `render.PushFlashlightMode`.
---
---@param render_func function The function that renders the `IMesh`, or a model.
function render.RenderFlashlights( render_func ) end

--- [CLIENT]
---
--- Renders the HUD on the screen.
---
---@param x number X position for the HUD draw origin.
---@param y number Y position for the HUD draw origin.
---@param w number Width of the HUD draw.
---@param h number Height of the HUD draw.
function render.RenderHUD( x, y, w, h ) end

--- [CLIENT]
---
--- Renders the scene with the specified viewData to the current active render target.
---
--- > **BUG** (#1330): Static props and LODs are rendered improperly due to incorrectly perceived distance.
---
--- > **BUG**: Using render.RenderView on a RenderTarget texture in a 3d context like SWEP:PostDrawViewModel() while drawing the RenderTarget texture causes screen flickers.
---
---@param view garrysmod.ViewData? The view data to be used in the rendering. Any missing value is assumed to be that of the current view.
function render.RenderView( view ) end

--- [CLIENT]
---
--- Resets the model lighting to the specified color.
---
--- It has the same effect as calling `render.SetModelLighting` for every direction with given color.
---
---@param r number The red part of the color, 0-1.
---@param g number The green part of the color, 0-1.
---@param b number The blue part of the color, 0-1.
function render.ResetModelLighting( r, g, b ) end

--- [CLIENT]
---
--- Resets the HDR tone multiplier to the specified value.
---
--- This will only work on HDR maps, and the value will automatically fade to what it was ( or whatever
--- `render.SetGoalToneMappingScale` is ) if called only once.
---
---@param scale number The value which should be used as multiplier.
function render.ResetToneMappingScale( scale ) end

--- [CLIENT]
---
--- Sets the ambient lighting for any upcoming render operation.
---
---@param r number The red part of the color, 0-1.
---@param g number The green part of the color, 0-1.
---@param b number The blue part of the color, 0-1.
function render.SetAmbientLight( r, g, b ) end

--- [CLIENT]
---
--- Sets the alpha blending (or transparency) for upcoming render operations.
---
--- See `render.SetColorModulation` for the function to affect RGB color channels.
---
--- By itself, this will cause visible overlapping on parts of a model that are in front of other parts
--- of the same model.
--- For a solution to this, see the examples below.
---
--- > **BUG** (#3166): This does not affect non-model `render.Draw*` functions.
---
--- > **NOTE**: If a material has the [$alphatest](https://developer.valvesoftware.com/wiki/$alphatest) flag enabled then this function might not behave as expected because alpha will be binary, this has a default cutoff of `0.7`.
---
---@param blending number The alpha (transparency) for upcoming draw operations. A value in the range `(0-1)` where `0` is fully transparent, `0.5` is 50% visible, and `1` is fully opaque.
function render.SetBlend( blending ) end

--- [CLIENT]
---
--- Sets the color modulation for upcoming render operations, such as rendering models.
---
--- The values can exceed 1 for stronger effect.
---
--- See `render.SetBlend` for the function to affect alpha channel.
---
---@param r number The red channel multiplier normal ranging from 0-1.
---@param g number The green channel multiplier normal ranging from 0-1.
---@param b number The blue channel multiplier normal ranging from 0-1.
function render.SetColorModulation( r, g, b ) end

--- [CLIENT]
---
--- If the `fog mode` is set to `MATERIAL_FOG`, the fog will only be rendered below the specified
--- height.
---
---@param fog_z number The fog Z.
function render.SetFogZ( fog_z ) end

--- [CLIENT]
---
--- Sets the goal HDR tone mapping scale.
---
--- Use this in a rendering/think hook as it is reset every frame.
---
---@param scale number The target scale.
function render.SetGoalToneMappingScale( scale ) end

--- [CLIENT]
---
--- Sets lighting mode when rendering something.
---
--- > **NOTE**: **Do not forget to restore the default value** to avoid unexpected behavior, like the world and the HUD/UI being affected.
---
---@param mode number Lighting render mode.  Possible values are: * 0 - Default. * 1 - Total fullbright, similar to `mat_fullbright 1` but excluding some weapon view models. * 2 - Increased brightness(?), models look fullbright.
function render.SetLightingMode( mode ) end

--- [CLIENT]
---
--- Sets lighting origin for the current model.
---
---@param lighting_origin garrysmod.Vector The position which will be used to calculate lighting for the current model.
function render.SetLightingOrigin( lighting_origin ) end

--- [CLIENT]
---
--- Sets the texture to be used as the lightmap in upcoming rendering operations. This is required when
--- rendering meshes using a material with a lightmapped shader such as `LightmappedGeneric`.
---
---@param tex garrysmod.Texture The texture to be used as the lightmap.
function render.SetLightmapTexture( tex ) end

--- [CLIENT]
---
--- Sets up the local lighting for any upcoming render operation. Up to 4 local lights can be defined,
--- with one of three different types (point, directional, spot).
---
--- Disables all local lights if called with no arguments.
---
--- See also `render.SetModelLighting` for "lightbox" lighting. They are not mutually exclusive.
---
---@param lights garrysmod.LocalLight[]? A table containing up to 4 light sources. Defaults to `{}`.
function render.SetLocalModelLights( lights ) end

--- [CLIENT]
---
--- Sets the material to be used in any upcoming render operation using the `render`.
---
--- Not to be confused with `surface.SetMaterial`.
---
---@param mat garrysmod.Material The material to be used.
function render.SetMaterial( mat ) end

--- [CLIENT]
---
--- Sets up the ambient lighting for any upcoming render operation. Ambient lighting can be seen as a
--- cube enclosing the object to be drawn, each of its faces representing a directional light source
--- that shines towards the object. Thus, there is a total of six different light sources that can be
--- configured separately.
---
--- Light color components are not restricted to a specific range (i.e. 0-1), instead, higher values
--- will result in a brighter light.
---
--- `render.ResetModelLighting` will set all 6 directions at once.
--- See also `render.SetLocalModelLights`.
---
---@param light_direction integer The light source to edit, see `BOX`.
---@param red number The red component of the light color. In range of [0,1]
---@param green number The green component of the light color. In range of [0,1]
---@param blue number The blue component of the light color. In range of [0,1]
function render.SetModelLighting( light_direction, red, green, blue ) end

--- [CLIENT]
---
--- Sets the render target to the specified rt.
---
---@param texture garrysmod.Texture The new render target to be used.
function render.SetRenderTarget( texture ) end

--- [CLIENT]
---
--- Sets the render target with the specified index of `COLOR[n]` to the specified rt, allowing you to
--- work with [Multiple Render Targets (MRT)](https://learn.microsoft.com/en-us/windows/win32/direct3d9/
--- multiple-render-targets). Since standard shaders don't use MRT, you might find this useful at
--- `Shaders/screenspace_general`.
---
--- > **NOTE**: MRT doesn't work with 2D render functions like `render.DrawScreenQuad`. Instead, you can render a `render.DrawQuad` using `cam.Start2D`.
---
--- > **WARNING**: If you try to render with MSAA and set the main RenderTarget with another RenderTarget, nothing will be rendered.
---
--- [Link to Direct3D 9 documentation on MRT](https://learn.microsoft.com/en-us/windows/win32/direct3d9/
--- multiple-render-targets#:~:text=No%20antialiasing%20is%20supported)
---
--- `Multiple render targets have the following restrictions:`
--- * *No antialiasing is supported.*
---
---@param rt_index number The index of output `COLOR[n]` [semantics](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-semantics) from pixel-shader. Min: `0`, max: `3`.
---@param texture garrysmod.Texture? The new render target to be used.
function render.SetRenderTargetEx( rt_index, texture ) end

--- [CLIENT AND MENU]
---
--- Sets a scissoring rectangle which limits the drawing area. (otherwise known as clipping)
---
---@param start_x number X start coordinate of the scissor rectangle in screen-space coordinates.
---@param start_y number Y start coordinate of the scissor rectangle in screen-space coordinates.
---@param end_x number X end coordinate of the scissor rectangle in screen-space coordinates.
---@param end_y number Y end coordinate of the scissor rectangle in screen-space coordinates.
---@param enable boolean Enable or disable the scissor rect.
function render.SetScissorRect( start_x, start_y, end_x, end_y, enable ) end

--- [CLIENT]
---
--- Sets the shadow color.
---
---@param red number The red channel of the shadow color.
---@param green number The green channel of the shadow color.
---@param blue number The blue channel of the shadow color.
function render.SetShadowColor( red, green, blue ) end

--- [CLIENT]
---
--- Sets the shadow projection direction.
---
---@param shadow_directions garrysmod.Vector The new shadow direction.
function render.SetShadowDirection( shadow_directions ) end

--- [CLIENT]
---
--- Sets the maximum shadow projection range.
---
---@param shadow_distance number The new maximum shadow distance.
function render.SetShadowDistance( shadow_distance ) end

--- [CLIENT]
---
--- Sets whether all shadow rendering should be disabled.
---
--- Internally sets `r_shadows_gamecontrol` convar, exactly like `shadow_control` does via its
--- `SetShadowsDisabled` input.
---
---@param disable boolean `true` to disable shadows, `false` to enable.
function render.SetShadowsDisabled( disable ) end

--- [CLIENT AND MENU]
---
--- Sets the Compare Function that all pixels affected by a draw operation will have their Stencil
--- Buffer value tested against.
---
--- When not set to a static value like NEVER or ALWAYS, the Stencil Buffer value corresponding to each
--- affected pixel will be compared against the current `Reference Value`.
---
--- Pixels that **Pass** the Compare Function check move on to the Depth Test, which determines if the
--- draw operation will ultimately be allowed to overwrite the pixel's Color Channel, Stencil Buffer,
--- and Depth Buffer values.
---
--- Pixels that **Fail** the Compare Function check have the `Fail Operation` performed on their
--- Stencil Buffer value and do **not** have any of their Render Target layers modified by the draw
--- operation.
---
--- For more detailed information on the Stencil system, including usage examples, see the `Stencils
--- Render Reference` page.
---
---@param compare_function integer The Compare Function that each affected pixel's Stencil Buffer value will be evaluated against during a draw operation. See `STENCILCOMPARISONFUNCTION` enums.
function render.SetStencilCompareFunction( compare_function ) end

--- [CLIENT AND MENU]
---
--- Enables or disables the Stencil system for future draw operations.
---
--- While enabled, all pixels affected by draw operations will have their corresponding values in the
--- active `Render Target's` Stencil Buffer compared against the current `Reference Value` and their
--- current Depth Buffer value compared against the depth of the corresponding pixel from the draw
--- operation.
--- Depending on the outcomes of these comparisons, one of either the `Pass`, `Fail`, or `Z-Fail`
--- operations is performed on the pixel's Stencil Buffer value.
--- A pixel will only be updated in the active `Render Target` if the `Pass Operation` is performed.
---
--- For more detailed information on the Stencil system, including usage examples, see the `Stencils
--- Render Reference` page.
---
--- > **NOTE**: The Stencil system's configuration does **not** reset automatically.
--- To prevent unexpected behavior, always manually ensure that the Stencil system is configured appropriately for your use-case after enabling it.
---
---@param new_state boolean The new state.
function render.SetStencilEnable( new_state ) end

--- [CLIENT AND MENU]
---
--- Sets the `STENCILOPERATION` that will be performed on the Stencil Buffer values of pixels affected
--- by draw operations if the `Compare Function` did **not** `Pass` the pixel.
---
--- For more detailed information on the Stencil system, including usage examples, see the `Stencils
--- Render Reference` page.
---
---@param fail_operation integer The Stencil Operation to be performed if the Compare Function does not Pass a pixel. See `STENCILOPERATION` enums.
function render.SetStencilFailOperation( fail_operation ) end

--- [CLIENT AND MENU]
---
--- Sets the `STENCILOPERATION` that will be performed on the Stencil Buffer values of pixels affected
--- by draw operations if the `Compare Function` Passes the pixel.
---
--- For more detailed information on the Stencil system, including usage examples, see the `Stencils
--- Render Reference` page.
---
---@param pass_operation integer The Stencil Operation to be performed if the Compare Function Passes a pixel. See `STENCILOPERATION` enums.
function render.SetStencilPassOperation( pass_operation ) end

--- [CLIENT AND MENU]
---
--- Sets the Stencil system's Reference Value which is compared against each pixel's corresponding
--- Stencil Buffer value in the `Compare Function` and can be used to modify the Stencil Buffer value
--- of those same pixels in the `Pass`, `Fail`, and `Z Fail` operations.
---
--- For more detailed information on the Stencil system, including usage examples, see the `Stencils
--- Render Reference` page.
---
---@param reference_value number The value that the Compare function and the pass, fail, and z-fail operations will use. This is an 8-bit (`byte`) unsigned integer value in the range [`0-255`].
function render.SetStencilReferenceValue( reference_value ) end

--- [CLIENT AND MENU]
---
--- Sets the unsigned 8-bit (`byte`) bitflag mask that will be bitwise ANDed with all values as they
--- are read (tested) from the Stencil Buffer
---
--- This can be considered a "niche" Stencil function as it is not required for many Stencil use-cases.
---
--- This is a companion function to `render.SetStencilWriteMask` which modifies Stencil Buffer values
--- as they are written.
---
--- For more detailed information on the Stencil system, including usage examples, see the `Stencils
--- Render Reference` page.
---
---@param bit_mask number The 8-bit (`byte`) mask. Set to `255` to make no change to read Stencil Buffer values.
function render.SetStencilTestMask( bit_mask ) end

--- [CLIENT AND MENU]
---
--- Sets the unsigned 8-bit (`byte`) bitflag mask that will be bitwise ANDed with all values as they
--- are written to the Stencil Buffer
---
--- This can be considered a "niche" Stencil function as it is not required for many Stencil use-cases.
---
--- This is a companion function to `render.SetStencilTestMask` which modifies Stencil Buffer values as
--- they are read.
---
--- For more detailed information on the Stencil system, including usage examples, see the `Stencils
--- Render Reference` page.
---
---@param bit_mask number The 8-bit (`byte`) mask. Set to `255` to make no change to written Stencil Buffer values.
function render.SetStencilWriteMask( bit_mask ) end

--- [CLIENT AND MENU]
---
--- Sets the `STENCILOPERATION` that will be performed on the Stencil Buffer values of pixels affected
--- by draw operations if the `Compare Function` Passed a given pixel, but it did **not** Pass the
--- Depth Test.
---
--- For more detailed information on the Stencil system, including usage examples, see the `Stencils
--- Render Reference` page.
---
---@param z_fail_operation integer The Stencil Operation to be performed if the Compare Function Passes a pixel, but the pixel fails the Depth Test. See `STENCILOPERATION` enums.
function render.SetStencilZFailOperation( z_fail_operation ) end

--- [CLIENT]
---
--- Sets the tone mapping scale for upcoming rendering operations.
---
---@param scales garrysmod.Vector The tonemapping scales. * X - Output scale. * Y - Lightmap scale. * Z - Reflection map scale.
function render.SetToneMappingScaleLinear( scales ) end

--- [CLIENT AND MENU]
---
--- Changes the view port position and size. The values will be clamped to the game's screen resolution.
---
--- If you are looking to render something to a texture (render target), you should use
--- `render.PushRenderTarget`.
---
--- > **NOTE**: This function will override values of `ScrW` and `ScrH` with the ones you set.
---
---@param x number X origin of the view port.
---@param y number Y origin of the view port.
---@param w number Width of the view port.
---@param h number Height of the view port.
function render.SetViewPort( x, y, w, h ) end

--- [CLIENT]
---
--- Sets the internal parameter **INT_RENDERPARM_WRITE_DEPTH_TO_DESTALPHA**.
---
---@param enable boolean
function render.SetWriteDepthToDestAlpha( enable ) end

--- [CLIENT]
---
--- Swaps the frame buffers/cycles the frame. In other words, this updates the screen.
---
--- If you take a really long time during a single frame render, it is a good idea to use this and let
--- the user know that the game isn't stuck.
---
function render.Spin() end

--- [CLIENT]
---
--- Begin drawing a multi-segment Beam.
---
--- For more detailed information on Beams, as well as usage examples, see the `Beams Render Reference`.
---
---@param segment_count number The number of Beam Segments that this multi-segment Beam will contain.
function render.StartBeam( segment_count ) end

--- [CLIENT AND MENU]
---
--- Returns if the current settings and the system allow the usage of pixel shaders 1.4.
---
---@return boolean supported Whether Pixel Shaders 1.4 are supported.
function render.SupportsPixelShaders_1_4() end

--- [CLIENT AND MENU]
---
--- Returns if the current settings and the system allow the usage of pixel shaders 2.0.
---
---@return boolean supported Whether Pixel Shaders 2.0 are supported.
function render.SupportsPixelShaders_2_0() end

--- [CLIENT AND MENU]
---
--- Returns if the current settings and the system allow the usage of vertex shaders 2.0.
---
---@return boolean supported Whether Vertex Shaders 2.0 are supported.
function render.SupportsVertexShaders_2_0() end

--- [CLIENT]
---
--- Allows suppressing model lighting for any upcoming model render operation.
--- Lighting then can be manually set up via various functions such as `render.SetModelLighting`.
---
--- > **BUG** (#4070): This does not affect `IMesh`es.
---
---@param suppress_lighting boolean True to suppress false to enable.
function render.SuppressEngineLighting( suppress_lighting ) end

--- [CLIENT]
---
--- Enables HDR tone mapping which influences the brightness.
---
function render.TurnOnToneMapping() end

--- [CLIENT]
---
--- Updates the texture returned by `render.GetFullScreenDepthTexture`.
---
--- Silently fails if `render.SupportsPixelShaders_2_0` returns false.
---
---@return garrysmod.Texture texture The fullscreen depth texture.
function render.UpdateFullScreenDepthTexture() end

--- [CLIENT]
---
--- Updates the power of two texture.
---
---@return garrysmod.Texture texture The power-of-two texture.
function render.UpdatePowerOfTwoTexture() end

--- [CLIENT]
---
--- Pretty much alias of `render.UpdatePowerOfTwoTexture` but does not return the texture.
---
function render.UpdateRefractTexture() end

--- [CLIENT]
---
--- Copies the entire screen to the screen effect texture, which can be acquired via
--- `render.GetScreenEffectTexture`. This function is mainly intended to be used in
--- `GM:RenderScreenspaceEffects`.
---
---@param texture_index number? Texture index to update. Max index is 3, but engine only creates the first two for you. Defaults to `0`.
function render.UpdateScreenEffectTexture( texture_index ) end

--- [CLIENT]
---
--- This function overrides all map materials for one frame.
---
---@param mat garrysmod.Material?
function render.WorldMaterialOverride( mat ) end
