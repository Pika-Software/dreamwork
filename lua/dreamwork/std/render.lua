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
    --- [CLIENT]
    ---
    --- Various fog rendering functions.
    ---@class dreamwork.std.render.fog
    render.fog = render.fog or {}
    render.fog.getMode = render.fog.getMode or glua_render.GetFogMode
    render.fog.setMode = render.fog.setMode or glua_render.FogMode
    render.fog.getColor = render.fog.getColor or glua_render.GetFogColor
    render.fog.setColor = render.fog.setColor or glua_render.FogColor
    render.fog.getDistances = render.fog.getDistances or glua_render.GetFogDistances
    render.fog.setStartDistance = render.fog.setStartDistance or glua_render.FogStart
    render.fog.setEndDistance = render.fog.setEndDistance or glua_render.FogEnd
    render.fog.getMaxDensity = render.fog.getMaxDensity or glua_render.GetFogMaxDensity
    render.fog.setMaxDensity = render.fog.setMaxDensity or glua_render.FogMaxDensity
    render.fog.setZ = render.fog.setZ or glua_render.SetFogZ

    --- [CLIENT]
    ---
    --- [Beam](https://wiki.facepunch.com/gmod/render_beams) rendering functions.
    ---@class dreamwork.std.render.beam
    render.beam = render.beam or {}
    render.beam.start = render.beam.start or glua_render.StartBeam
    render.beam.finish = render.beam.finish or glua_render.EndBeam
    render.beam.addSegment = render.beam.addSegment or glua_render.AddBeam
    render.beam.draw = render.beam.draw or glua_render.DrawBeam

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
end
