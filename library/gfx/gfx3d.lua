---@meta _

--- [CLIENT]
---
--- The library with powerful set of functions that let you control how the world and its contents are rendered.
---
--- It can also be used to draw some 3D client-side effects such as beams, boxes and spheres.
---
---@class gfx3d
---@field PixelShaders1 boolean `true` if the current settings and the system allow the usage of pixel shaders 1.4, `false` otherwise.
---@field PixelShaders2 boolean `true` if the current settings and the system allow the usage of pixel shaders 2.0, `false` otherwise.
---@field VertexShaders boolean `true` if the current settings and the system allow the usage of vertex shaders 1.1, `false` otherwise.
---@field DirectX number The supported DirectX level, 8 for DX8, 9 for DX9, 10 for DX10, 11 for DX11.
---@field HDR boolean `true` if the current settings and the system allow the usage of HDR, `false` otherwise.
gfx3d = {}

---@alias gfx3d.ModelFlags
---| 1 STUDIO_RENDER # The current render is for opaque renderables only.
---| 2 STUDIO_VIEWXFORMATTACHMENTS # Applies view-space transforms to model attachments (used for attachment positioning/rendering in view models).
---| 4 STUDIO_DRAWTRANSLUCENTSUBMODELS # The current render is for translucent renderables only.
---| 8 STUDIO_TWOPASS # The current render is for both opaque and translucent renderables.
---| 16 STUDIO_STATIC_LIGHTING # Uses precomputed/static lighting instead of dynamic lighting.
---| 32 STUDIO_WIREFRAME Renders the model in wireframe mode.
---| 64 STUDIO_ITEM_BLINK Enables blinking/item highlight effect.
---| 128 STUDIO_NOSHADOWS # Prevents the model from casting or receiving shadows.
---| 256 STUDIO_WIREFRAME_VCOLLIDE # Renders the vcollide/collision mesh in wireframe mode.
---| 1024 STUDIO_SKIP_FLEXES # Do not update/apply flexes.
---| 16777216 STUDIO_GENERATE_STATS # Not a studio flag, but used to flag when we want studio stats.
---| 134217728 STUDIO_SSAODEPTHTEXTURE # Not a studio flag, but used to flag model as using SSAO depth material override.
---| 268435456 STUDIO_SKIP_DECALS # Do not render decals.
---| 1073741824 STUDIO_SHADOWDEPTHTEXTURE # Not a studio flag, but used to flag model as using shadow depth material override.
---| 2147483648 STUDIO_TRANSPARENCY # Not a studio flag, but used to flag model as a non-sorting brush model.

---@class gfx3d.RenderView.offcenter
---@field left number Where the left edge starts, natural value is `0`.
---@field right number Where the right edge ends, natural value is equal to `w` (the width of the viewport).
---@field bottom number Where the bottom edge starts, natural value is `0`.
---@field top number Where the top edge ends, natural value is equal to `h` (the height of the viewport).

---@class gfx3d.RenderView
---@field origin Vector3 | nil The position to render from.
---@field angles Angle3 | nil The angles to render from.
---@field fov integer | nil The field of view of the view port.
---@field x integer | nil The x position of the view port
---@field y integer | nil The y position of the view port
---@field w integer | nil The width of the view port.
---@field h integer | nil The height of the view port.
---@field znear number | nil The distance to the near clipping plane.
---@field zfar number | nil The distance to the far clipping plane.
---@field aspect number | nil The aspect ratio of the view port (Note that this is NOT set to `w/h` by default).
---@field subrect boolean | nil Allow draw into a subrect of the larger screen.
---@field bloomtone boolean | nil Controlls default engine bloom, tonemapping and "brightness changes" on HDR maps.
---@field offcenter gfx3d.RenderView.offcenter | nil Controlls what portion of the screen to draw.

--- [CLIENT]
---
---
---
---@param view gfx3d.RenderView
function gfx3d.start(view) end

--- [CLIENT]
---
---
---
---@param origin Vector3
---@param angles Angle3
---@param scale number
function gfx3d.start2d(origin, angles, scale) end

--- [CLIENT]
---
--- Draws a sprite in 3D space.
---
---@param origin Vector3 The position of the sprite.
---@param width number The width of the sprite.
---@param height number The height of the sprite.
---@param color Color? The color of the sprite, white by default.
---@param alpha integer? The alpha of the sprite, `255` by default.
function gfx3d.drawSprite(origin, width, height, color, alpha) end

--- [CLIENT]
---
--- Draws a straight beam.
---
---@param start_position Vector3 The start of the beam.
---@param end_position Vector3 The end of the beam.
---@param width number The width of the beam.
---@param texture_start number The texture coordinate at the start of the beam.
---@param texture_end number The texture coordinate at the end of the beam.
---@param color Color? The color of the beam, white by default.
---@param alpha integer? The alpha of the beam, `255` by default.
function gfx3d.drawBeam(start_position, end_position, width, texture_start, texture_end, color, alpha) end

--- [CLIENT]
---
--- Draws a box, solid or wireframe.
---
---@param origin Vector3 The origin of the box.
---@param angles Angle3 The orientation of the box.
---@param mins Vector3 The local minimum bounds.
---@param maxs Vector3 The local maximum bounds.
---@param color Color? The color of the box, white by default.
---@param alpha integer? The alpha of the box, `255` by default.
---@param wireframe boolean? If `true`, draws only the edges of the box.
---@param write_z boolean? If `true`, the wireframe writes to the depth buffer (wireframe only).
function gfx3d.drawBox(origin, angles, mins, maxs, color, alpha, wireframe, write_z) end

--- [CLIENT]
---
--- Draws a line between two points.
---
---@param start_position Vector3 The start of the line.
---@param end_position Vector3 The end of the line.
---@param color Color? The color of the line, white by default.
---@param alpha integer? The alpha of the line, `255` by default.
---@param write_z boolean? If `true`, the line writes to the depth buffer.
function gfx3d.drawLine(start_position, end_position, color, alpha, write_z) end

--- [CLIENT]
---
--- Draws a sphere, solid or wireframe.
---
---@param origin Vector3 The center of the sphere.
---@param radius number The radius of the sphere.
---@param longitude_steps integer The number of longitude steps.
---@param latitude_steps integer The number of latitude steps.
---@param color Color? The color of the sphere, white by default.
---@param alpha integer? The alpha of the sphere, `255` by default.
---@param wireframe boolean? If `true`, draws only the edges of the sphere.
---@param write_z boolean? If `true`, the wireframe writes to the depth buffer (wireframe only).
function gfx3d.drawSphere(origin, radius, longitude_steps, latitude_steps, color, alpha, wireframe, write_z) end

---@class gfx3d.ComplexBeamSegment
---@field origin Vector3
---@field width number
---@field texture_end number
---@field color Color | nil
---@field alpha integer | nil

--- [CLIENT]
---
--- Draws a beam made of multiple segments.
---
---@param segments gfx3d.ComplexBeamSegment[] The beam segments.
---@param segment_count integer? The number of segments to draw, defaults to the length of `segments`.
function gfx3d.drawComplexBeam(segments, segment_count) end
