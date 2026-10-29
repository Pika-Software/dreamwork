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

function gfx3d.drawSprite() end

--- [CLIENT]
---
---
---
---@param start_position Vector3
---@param end_position Vector3
---@param width number
---@param texture_end number
---@param color Color
function gfx3d.drawBeam(start_position, end_position, width, texture_start, texture_end, color, alpha) end

function gfx3d.drawBox() end

function gfx3d.drawLine() end

function gfx3d.drawSphere() end

---@class gfx3d.ComplexBeamSegment
---@field origin Vector3
---@field width number
---@field texture_end number
---@field color Color

--- [CLIENT]
---
---
---
---@param segments gfx3d.ComplexBeamSegment[]
function gfx3d.drawComplexBeam(segments, segment_count) end
