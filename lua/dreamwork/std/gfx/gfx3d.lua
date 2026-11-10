local dreamwork_engine = dreamwork.engine

---@class dreamwork.std
local std = dreamwork.std
local len = std.len

local debug = std.debug
local debug_fempty = debug.fempty


---@type garrysmod.render
local glua_render = dreamwork_engine.requireLibrary( "render" )

---@type garrysmod.cam
local glua_cam = dreamwork_engine.requireLibrary( "cam" )

local Vector3Proxy = dreamwork_engine.Vector3Proxy
local Angle3Proxy = dreamwork_engine.Angle3Proxy
local ColorProxy = dreamwork_engine.ColorProxy

local origin_proxy = Vector3Proxy()
local target_proxy = Vector3Proxy()
local mins_proxy = Vector3Proxy()
local maxs_proxy = Vector3Proxy()

local angles_proxy = Angle3Proxy()

local color_proxy = ColorProxy( 255, 255, 255, 255 )

--- Updates the shared color proxy, `nil` color means white, `nil` alpha means opaque.
---
---@param clr dreamwork.std.Color | nil
---@param alpha integer | nil
---@return garrysmod.Color
local function getColor( clr, alpha )
    color_proxy:update( clr or 0xFFFFFF )
    color_proxy.a = alpha or 255

    ---@diagnostic disable-next-line: return-type-mismatch
    return color_proxy
end

--- [CLIENT]
---
--- The library with powerful set of functions that let you control how the world and its contents are rendered.
---
--- It can also be used to draw some 3D client-side effects such as beams, boxes and spheres.
---
---@class dreamwork.std.gfx3d
---@field PixelShaders1 boolean `true` if the current settings and the system allow the usage of pixel shaders 1.4, `false` otherwise.
---@field PixelShaders2 boolean `true` if the current settings and the system allow the usage of pixel shaders 2.0, `false` otherwise.
---@field VertexShaders boolean `true` if the current settings and the system allow the usage of vertex shaders 1.1, `false` otherwise.
---@field DirectX number The supported DirectX level, 8 for DX8, 9 for DX9, 10 for DX10, 11 for DX11.
---@field HDR boolean `true` if the current settings and the system allow the usage of HDR, `false` otherwise.
local gfx3d = std.gfx3d or {}
std.gfx3d = gfx3d

gfx3d.PixelShaders1 = (glua_render.SupportsPixelShaders_1_4 or debug_fempty)() == true
gfx3d.PixelShaders2 = (glua_render.SupportsPixelShaders_2_0 or debug_fempty)() == true
gfx3d.VertexShaders = (glua_render.SupportsVertexShaders_2_0 or debug_fempty)() == true

do

    local directx_version = ((glua_render.GetDXLevel or debug_fempty)() or 80) * 0.1
    gfx3d.DirectX = directx_version
    gfx3d.HDR = directx_version >= 8

end

---@alias dreamwork.std.gfx3d.ModelFlags
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

-- TODO: add 3d render. functions

-- ref: https://github.com/luttje/glua-api-snippets/blob/lua-language-server-addon/library/render.lua
-- ref: https://github.com/luttje/glua-api-snippets/blob/lua-language-server-addon/library/cam.lua

gfx3d.clear = glua_render.Clear or debug_fempty

do

    local cam_Start3D2D = glua_cam.Start3D2D or debug_fempty
    local cam_Start = glua_cam.Start or debug_fempty

    ---@class dreamwork.std.gfx3d.RenderView.offcenter
    ---@field left number Where the left edge starts, natural value is `0`.
    ---@field right number Where the right edge ends, natural value is equal to `w` (the width of the viewport).
    ---@field bottom number Where the bottom edge starts, natural value is `0`.
    ---@field top number Where the top edge ends, natural value is equal to `h` (the height of the viewport).

    ---@class dreamwork.std.gfx3d.RenderView
    ---@field origin dreamwork.std.Vector3 | nil The position to render from.
    ---@field angles dreamwork.std.Angle3 | nil The angles to render from.
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
    ---@field offcenter dreamwork.std.gfx3d.RenderView.offcenter | nil Controlls what portion of the screen to draw.

    ---@type garrysmod.RenderCamData
    ---@diagnostic disable-next-line: missing-fields
    local cam_data = { type = "3D" }

    --- [CLIENT]
    ---
    ---
    ---
    ---@param view dreamwork.std.gfx3d.RenderView
    function gfx3d.start( view )
        local origin = view.origin
        if origin == nil then
            cam_data.origin = nil
        else
            cam_data.origin = origin_proxy:update( origin )
        end

        local angles = view.angles
        if angles == nil then
            cam_data.angles = nil
        else
            cam_data.angles = angles_proxy:update( angles )
        end

        cam_data.fov = view.fov

        cam_data.x, cam_data.y = view.x, view.y
        cam_data.w, cam_data.h = view.w, view.h

        cam_data.znear, cam_data.zfar = view.znear, view.zfar

        cam_data.aspect = view.aspect
        cam_data.subrect = view.subrect
        cam_data.bloomtone = view.bloomtone

        ---@diagnostic disable-next-line: assign-type-mismatch
        cam_data.offcenter = view.offcenter

        cam_Start( cam_data )
    end

    gfx3d.stop = glua_cam.End3D or debug_fempty

    --- [CLIENT]
    ---
    ---
    ---
    ---@param origin dreamwork.std.Vector3
    ---@param angles dreamwork.std.Angle3
    ---@param scale number
    function gfx3d.start2d( origin, angles, scale )
        cam_Start3D2D( origin_proxy:update( origin ), angles_proxy:update( angles ), scale )
    end

    gfx3d.stop2d = glua_cam.End3D2D or debug_fempty

end

--- capture
--
-- glua_render.Capture
-- glua_render.CapturePixels
--

--- light
--
-- glua_render.SetLightmapTexture
--
--

--- material
--
-- glua_render.BrushMaterialOverride
-- glua_render.SetMaterial

do

    local render_DrawSprite = glua_render.DrawSprite or debug_fempty

    --- [CLIENT]
    ---
    --- Draws a sprite in 3D space.
    ---
    ---@param origin dreamwork.std.Vector3 The position of the sprite.
    ---@param width number The width of the sprite.
    ---@param height number The height of the sprite.
    ---@param color dreamwork.std.Color? The color of the sprite, white by default.
    ---@param alpha integer? The alpha of the sprite, `255` by default.
    function gfx3d.drawSprite( origin, width, height, color, alpha )
        render_DrawSprite( origin_proxy:update( origin ), width, height, getColor( color, alpha ) )
    end

    local render_DrawBeam = glua_render.DrawBeam or debug_fempty

    --- [CLIENT]
    ---
    --- Draws a straight beam.
    ---
    ---@param start_position dreamwork.std.Vector3 The start of the beam.
    ---@param end_position dreamwork.std.Vector3 The end of the beam.
    ---@param width number The width of the beam.
    ---@param texture_start number The texture coordinate at the start of the beam.
    ---@param texture_end number The texture coordinate at the end of the beam.
    ---@param color dreamwork.std.Color? The color of the beam, white by default.
    ---@param alpha integer? The alpha of the beam, `255` by default.
    function gfx3d.drawBeam( start_position, end_position, width, texture_start, texture_end, color, alpha )
        render_DrawBeam( origin_proxy:update( start_position ), target_proxy:update( end_position ), width, texture_start, texture_end, getColor( color, alpha ) )
    end

    local render_DrawWireframeBox = glua_render.DrawWireframeBox or debug_fempty
    local render_DrawBox = glua_render.DrawBox or debug_fempty

    --- [CLIENT]
    ---
    --- Draws a box, solid or wireframe.
    ---
    ---@param origin dreamwork.std.Vector3 The origin of the box.
    ---@param angles dreamwork.std.Angle3 The orientation of the box.
    ---@param mins dreamwork.std.Vector3 The local minimum bounds.
    ---@param maxs dreamwork.std.Vector3 The local maximum bounds.
    ---@param color dreamwork.std.Color? The color of the box, white by default.
    ---@param alpha integer? The alpha of the box, `255` by default.
    ---@param wireframe boolean? If `true`, draws only the edges of the box.
    ---@param write_z boolean? If `true`, the wireframe writes to the depth buffer (wireframe only).
    function gfx3d.drawBox( origin, angles, mins, maxs, color, alpha, wireframe, write_z )
        if wireframe then
            render_DrawWireframeBox( origin_proxy:update( origin ), angles_proxy:update( angles ), mins_proxy:update( mins ), maxs_proxy:update( maxs ), getColor( color, alpha ), write_z == true )
        else
            render_DrawBox( origin_proxy:update( origin ), angles_proxy:update( angles ), mins_proxy:update( mins ), maxs_proxy:update( maxs ), getColor( color, alpha ) )
        end
    end

    local render_DrawLine = glua_render.DrawLine or debug_fempty

    --- [CLIENT]
    ---
    --- Draws a line between two points.
    ---
    ---@param start_position dreamwork.std.Vector3 The start of the line.
    ---@param end_position dreamwork.std.Vector3 The end of the line.
    ---@param color dreamwork.std.Color? The color of the line, white by default.
    ---@param alpha integer? The alpha of the line, `255` by default.
    ---@param write_z boolean? If `true`, the line writes to the depth buffer.
    function gfx3d.drawLine( start_position, end_position, color, alpha, write_z )
        render_DrawLine( origin_proxy:update( start_position ), target_proxy:update( end_position ), getColor( color, alpha ), write_z == true )
    end

    local render_DrawWireframeSphere = glua_render.DrawWireframeSphere or debug_fempty
    local render_DrawSphere = glua_render.DrawSphere or debug_fempty

    --- [CLIENT]
    ---
    --- Draws a sphere, solid or wireframe.
    ---
    ---@param origin dreamwork.std.Vector3 The center of the sphere.
    ---@param radius number The radius of the sphere.
    ---@param longitude_steps integer The number of longitude steps.
    ---@param latitude_steps integer The number of latitude steps.
    ---@param color dreamwork.std.Color? The color of the sphere, white by default.
    ---@param alpha integer? The alpha of the sphere, `255` by default.
    ---@param wireframe boolean? If `true`, draws only the edges of the sphere.
    ---@param write_z boolean? If `true`, the wireframe writes to the depth buffer (wireframe only).
    function gfx3d.drawSphere( origin, radius, longitude_steps, latitude_steps, color, alpha, wireframe, write_z )
        if wireframe then
            render_DrawWireframeSphere( origin_proxy:update( origin ), radius, longitude_steps, latitude_steps, getColor( color, alpha ), write_z == true )
        else
            render_DrawSphere( origin_proxy:update( origin ), radius, longitude_steps, latitude_steps, getColor( color, alpha ) )
        end
    end

    -- glua_render.DrawQuad
    -- glua_render.DrawQuadEasy

end

do

    local render_StartBeam = glua_render.StartBeam or debug_fempty
    local render_AddBeam = glua_render.AddBeam or debug_fempty
    local render_EndBeam = glua_render.EndBeam or debug_fempty

    ---@class dreamwork.std.gfx3d.ComplexBeamSegment
    ---@field origin dreamwork.std.Vector3
    ---@field width number
    ---@field texture_end number
    ---@field color dreamwork.std.Color | nil
    ---@field alpha integer | nil

    --- [CLIENT]
    ---
    --- Draws a beam made of multiple segments.
    ---
    ---@param segments dreamwork.std.gfx3d.ComplexBeamSegment[] The beam segments.
    ---@param segment_count integer? The number of segments to draw, defaults to the length of `segments`.
    function gfx3d.drawComplexBeam( segments, segment_count )
        if segment_count == nil then
            segment_count = len( segments )
        end

        render_StartBeam( segment_count )

        for i = 1, segment_count do
            local segment = segments[ i ]
            render_AddBeam( origin_proxy:update( segment.origin ), segment.width, segment.texture_end, getColor( segment.color, segment.alpha ) )
        end

        render_EndBeam()
    end

end


-- TODO: rewrite this crap into normat push/pop scissor call https://gitlab.com/DBotThePony/DLib/-/blob/develop/lua_src/dlib/extensions/render.lua?ref_type=heads
