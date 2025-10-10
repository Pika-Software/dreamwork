local _G = _G

---@class dreamwork.std
local std = _G.dreamwork.std

local glua_render = _G.render

--- [CLIENT AND MENU]
---
--- The game's render library.
---@class dreamwork.std.render
local render = std.render or {}
std.render = render

-- TODO: add render/draw/surface functions

if std.CLIENT then
    render.getViewportWidth = render.getViewportWidth or _G.ScrW
    render.getViewportHeight = render.getViewportHeight or _G.ScrH

    do
        --- [CLIENT]
        ---
        --- Various fog rendering functions.
        ---@class dreamwork.std.render.fog
        local fog = render.fog or {}
        render.fog = fog
        fog.getMode = fog.getMode or glua_render.GetFogMode
        fog.setMode = fog.setMode or glua_render.FogMode
        fog.getColor = fog.getColor or glua_render.GetFogColor
        fog.setColor = fog.setColor or glua_render.FogColor
        fog.getDistances = fog.getDistances or glua_render.GetFogDistances
        fog.setStartDistance = fog.setStartDistance or glua_render.FogStart
        fog.setEndDistance = fog.setEndDistance or glua_render.FogEnd
        fog.getMaxDensity = fog.getMaxDensity or glua_render.GetFogMaxDensity
        fog.setMaxDensity = fog.setMaxDensity or glua_render.FogMaxDensity
        fog.setZ = fog.setZ or glua_render.SetFogZ
    end

    do
        --- [CLIENT]
        ---
        --- [Beam](https://wiki.facepunch.com/gmod/render_beams) rendering functions.
        ---@class dreamwork.std.render.beam
        local beam = render.beam or {}
        render.beam = beam
        beam.start = beam.start or glua_render.StartBeam
        beam.finish = beam.finish or glua_render.EndBeam
        beam.addSegment = beam.addSegment or glua_render.AddBeam
        beam.draw = beam.draw or glua_render.DrawBeam
    end

    render.setMaterial = render.setMaterial or glua_render.SetMaterial
    if not render.setColorMaterial then
        --- [CLIENT]
        ---
        --- Set the current drawing material to `color`
        --- or `color_ignorez` if `ignore_z` is set to true.
        ---@param ignore_z? boolean
        render.setColorMaterial = function(ignore_z)
            render.setMaterial(Material(ignore_z and "color_ignorez" or "color"))
        end
    end
    render.overrideEntityMaterial = render.overrideEntityMaterial or glua_render.MaterialOverride
    render.overrideEntityMaterialByIndex = render.overrideEntityMaterialByIndex or glua_render.MaterialOverrideByIndex
    render.overrideModelMaterial = render.overrideModelMaterial or glua_render.ModelMaterialOverride
    render.overrideBrushMaterial = render.overrideBrushMaterial or glua_render.BrushMaterialOverride
    render.overrideWorldMaterial = render.overrideWorldMaterial or glua_render.WorldMaterialOverride

    do
        --- [CLIENT]
        ---
        --- Stencil system functions
        ---@class dreamwork.std.render.stencil
        local stencil = render.stencil or {}
        render.stencil = stencil

        stencil.OPERATION = {
            KEEP = STENCILOPERATION_KEEP,
            ZERO = STENCILOPERATION_ZERO,
            REPLACE = STENCILOPERATION_REPLACE,
            INCRSAT = STENCILOPERATION_INCRSAT,
            DECRSAT = STENCILOPERATION_DECRSAT,
            INVERT = STENCILOPERATION_INVERT,
            INCR = STENCILOPERATION_INCR,
            DECR = STENCILOPERATION_DECR
        }

        if not stencil.enable then
            --- [CLIENT]
            ---
            --- Enable stencil system for future operations.
            stencil.enable = function() glua_render.SetStencilEnable(true) end
        end

        if not stencil.disable then
            --- [CLIENT]
            ---
            --- Disable stencil system for future operations.
            stencil.disable = function() glua_render.SetStencilEnable(false) end
        end

        stencil.clear = stencil.clear or glua_render.ClearStencil
        stencil.setCompareFunction = stencil.setCompareFunction or glua_render.SetStencilCompareFunction
        stencil.setFailOperation = stencil.setFailOperation or glua_render.SetStencilFailOperation
        stencil.setZFailOperation = stencil.setZFailOperation or glua_render.SetStencilZFailOperation
        stencil.setPassOperation = stencil.setPassOperation or glua_render.SetStencilPassOperation
        stencil.setTestMask = stencil.setTestMask or glua_render.SetStencilTestMask
        stencil.setWriteMask = stencil.setWriteMask or glua_render.SetStencilWriteMask
        stencil.setReferenceValue = stencil.setReferenceValue or glua_render.SetStencilReferenceValue
        stencil.clearBufferObey = stencil.clearBufferObey or glua_render.ClearBuffersObeyStencil
        stencil.clearBufferRect = stencil.clearBufferRect or glua_render.ClearStencilBufferRectangle
        stencil.performFullScreenOperation = stencil.performFullScreenOperation or glua_render.PerformFullScreenStencilOperation

        if not stencil.reset then
            local stencil_clear = stencil.clear
            local stencil_setWriteMask = stencil.setWriteMask
            local stencil_setTestMask = stencil.setTestMask
            local stencil_setPassOp = stencil.setPassOperation
            local stencil_setZFailOp = stencil.setFailOperation

            local op_keep = stencil.OPERATION.KEEP
            --- [CLIENT]
            ---
            --- Reset the stencil system to safe values.
            stencil.reset = function()
                stencil_clear()
                stencil_setWriteMask(255)
                stencil_setTestMask(255)
                stencil_setPassOp(op_keep)
                stencil_setZFailOp(op_keep)
            end
        end
    end

    do
        local glua_cam = _G.cam
        local r_getVPW, r_getVPH = render.getViewportWidth, render.getViewportHeight

        --- [CLIENT]
        ---
        --- Rendering context utilities
        ---@class dreamwork.std.render.context
        local context = render.context or {}
        render.context = context

        if not context.r2d then
            --- [CLIENT]
            ---
            --- Two-dimensional context
            ---@class dreamwork.std.render.context.r2d
            local r2d = {}
            context.r2d = r2d

            r2d.capturePixels = r2d.capturePixels or glua_render.CapturePixels
            r2d.readPixel = r2d.readPixel or glua_render.ReadPixel
            if not r2d.run then
                local gr_SetViewPort = glua_render.SetViewPort

                --- [CLIENT]
                ---
                --- Wraps the given function in 2D rendering context
                ---@param func function
                ---@param vpx? number viewport X origin. Default: 0
                ---@param vpy? number viewport Y origin. Default: 0
                ---@param vpw? number viewport width. Default: current viewport width
                ---@param vph? number viewport height. Default: current viewport height
                r2d.run = function(func, vpx, vpy, vpw, vph)
                    local w, h = r_getVPW(), r_getVPH() -- store previous viewport sizes
                    vpx, vpy, vpw, vph = vpx or 0, vpy or 0, vpw or w, vph or h
                    gr_SetViewPort(vpx, vpy, vpw, vph)
                    glua_cam.Start2D()
                    func()
                    glua_cam.End2D()
                    gr_SetViewPort(0, 0, w, h)
                end
            end
        end

        if not context.r3d then
            --- [CLIENT]
            ---
            --- Three-dimensional context
            ---@class dreamwork.std.render.context.r3d
            local r3d = {}
            context.r3d = r3d

            if not r3d.run then
                --- [CLIENT]
                ---
                --- Wraps the given function in 3D rendering context
                ---@param func function
                ---@param pos? dreamwork.std.Vector3 camera position. Default: current position
                ---@param ang? dreamwork.std.Angle3 camera angle. Default: current angle
                ---@param fov? number field of view. Default: current FOV
                ---@param vpx? number viewport X origin. Default: current vierport X origin
                ---@param vpy? number viewport Y origin. Default: current viewport Y origin
                ---@param vpw? number viewport width. Default: current viewport width
                ---@param vph? number viewport height. Default: current viewport height
                ---@param z_near? number near clipping plane distance. Default: current distance of near clip
                ---@param z_far? number far clipping plane distance. Default: current distance of far clip
                r3d.run = function(func, pos, ang, fov, vpx, vpy, vpw, vph, z_near, z_far)
                    glua_cam.Start3D(
                        pos and Vector(pos:unpack()), ang and Angle(ang:unpack()),
                        fov, vpx, vpy, vpw, vph, z_near, z_far)
                    func()
                    glua_cam.End3D()
                end
            end

            if not r3d.runOrtho then
                --- [CLIENT]
                ---
                --- Wraps the given function in 3D rendering context which uses orthographic projection
                ---@param func function
                ---@param left? number the left plane offset. Default: 0
                ---@param top? number the top plane offset. Default: 0
                ---@param right? number the right plane offset. Default: current viewport width
                ---@param bottom? number the bottom plane offset. Default: current viewport height
                r3d.runOrtho = function(func, left, top, right, bottom)
                    glua_cam.StartOrthoView(left or 0, top or 0, right or r_getVPW(), bottom or r_getVPH())
                    func()
                    glua_cam.EndOrthoView()
                end
            end
        end
    end
end
