---@meta garrysmod.cam


--- Render context type for [cam.Start](https://wiki.facepunch.com/gmod/cam.Start) /
--- [Structures/RenderCamData](https://wiki.facepunch.com/gmod/Structures/RenderCamData).
---
---@alias garrysmod.RenderCamData.Type
---| "2D" # No additional arguments are required.
---| "3D" # Only `origin` and `angles` are needed; all other parameters are optional.


--- Off-center projection offsets for [Structures/RenderCamData](https://wiki.facepunch.com/gmod/Structures/RenderCamData).
---
--- Controls what portion of the screen to draw (`all floats`).
---
---@class garrysmod.RenderCamData.OffCenter
---@field left number
---@field right number
---@field bottom number
---@field top number


--- [CLIENT]
---
--- Used for [cam.Start](https://wiki.facepunch.com/gmod/cam.Start).
---
--- Unless stated otherwise, the default values for all these keys would be inherited from the engine's
--- current `CViewSetup` and do not have static representations.
---
--- See [Structures/RenderCamData](https://wiki.facepunch.com/gmod/Structures/RenderCamData).
---
---@class garrysmod.RenderCamData
---@field x number? The x position of the view port.
---@field y number? The y position of the view port.
---@field w number? The width of the view port.
---@field h number? The height of the view port.
---@field type garrysmod.RenderCamData.Type? The type of cam. Defaults to `"3D"`.
---@field origin garrysmod.Vector? The position to render from.
---@field angles garrysmod.Angle? The angles to render from.
---@field fov number? The field of view.
---@field aspect number? The aspect ratio of the view port (note that this is **not** set to `w/h` by default).
---@field zfar number? The distance to the far clipping plane.
---@field znear number? The distance to the near clipping plane.
---@field subrect boolean? Set to `true` if this is to draw into a subrect of the larger screen.
---@field bloomtone boolean? `m_bDoBloomAndToneMapping`. Defaults to `false`.
---@field offcenter garrysmod.RenderCamData.OffCenter? Portion of the screen to draw.
---@field ortho garrysmod.Orthographic? If set, makes the view/camera orthogonal.


--- [CLIENT]
---
--- This directs all drawing to be done to a certain 2D or 3D plane or position, until the corresponding
--- "End" function is called.
---
--- The matrix functions exist, but are mostly unusable unless you're familiar with the source engine's
--- layout for each aspect.
---
--- Open Source (Lua) wrappers such as `cam.Start2D` / `cam.Start3D` are omitted; use `cam.Start`.
---
---@class garrysmod.cam
cam = {}

--- [CLIENT]
---
--- Shakes the screen at a certain position.
---
---@param pos garrysmod.Vector Origin of the shake.
---@param angles garrysmod.Angle Angles of the shake.
---@param factor number The shake factor.
function cam.ApplyShake( pos, angles, factor ) end

--- [CLIENT]
---
--- Switches the renderer back to the previous drawing mode from a 3D context.
---
--- This function is an alias of [cam.End3D](https://wiki.facepunch.com/gmod/cam.End3D).
---
function cam.End() end

--- [CLIENT]
---
--- Switches the renderer back to the previous drawing mode from a 2D context.
---
function cam.End2D() end

--- [CLIENT]
---
--- Switches the renderer back to the previous drawing mode from a 3D context.
---
function cam.End3D() end

--- [CLIENT]
---
--- Switches the renderer back to the previous drawing mode from a 3D2D context.
---
function cam.End3D2D() end

--- [CLIENT]
---
--- Switches the renderer back to the previous drawing mode from a 3D orthographic rendering context.
---
function cam.EndOrthoView() end

--- [CLIENT]
---
--- Returns a copy of the model matrix that is at the top of the stack.
---
--- > **NOTE**: Editing the matrix **will not** edit the current view. To do so, you will have to use
--- > [cam.PushModelMatrix](https://wiki.facepunch.com/gmod/cam.PushModelMatrix).
---
---@return garrysmod.VMatrix matrix The currently active model matrix.
function cam.GetModelMatrix() end

--- [CLIENT]
---
--- Returns a copy of the projection matrix. Also see
--- [cam.GetViewMatrix](https://wiki.facepunch.com/gmod/cam.GetViewMatrix).
---
--- Will return Identity matrix in 2D Render context. In this case use
--- [cam.Start3D](https://wiki.facepunch.com/gmod/cam.Start3D). See
--- [Render Hook Order](https://wiki.facepunch.com/gmod/Render_Order).
---
---@return garrysmod.VMatrix matrix The currently active projection matrix.
function cam.GetProjectionMatrix() end

--- [CLIENT]
---
--- Returns a copy of the view matrix. Also see
--- [cam.GetProjectionMatrix](https://wiki.facepunch.com/gmod/cam.GetProjectionMatrix).
---
--- Will return Identity matrix in 2D Render context. In this case use
--- [cam.Start3D](https://wiki.facepunch.com/gmod/cam.Start3D). See
--- [Render Hook Order](https://wiki.facepunch.com/gmod/Render_Order).
---
---@return garrysmod.VMatrix matrix The currently active view matrix.
function cam.GetViewMatrix() end

--- [CLIENT]
---
--- Tells the renderer to ignore the depth buffer and draw any upcoming operation "ontop" of everything
--- that was drawn yet.
---
--- This is identical to calling `render.DepthRange( 0, 0.01 )` for `true` and
--- `render.DepthRange( 0, 1 )` for `false`. See
--- [render.DepthRange](https://wiki.facepunch.com/gmod/render.DepthRange).
---
---@param ignore_z boolean Determines whenever to ignore the depth buffer or not.
function cam.IgnoreZ( ignore_z ) end

--- [CLIENT]
---
--- Removes the currently active model matrix (pushed previously with
--- [cam.PushModelMatrix](https://wiki.facepunch.com/gmod/cam.PushModelMatrix)) from the stack and
--- reinstates the previous one.
---
function cam.PopModelMatrix() end

--- [CLIENT]
---
--- Pushes the specified matrix onto the render matrix stack. Each pushed matrix must be popped via
--- [cam.PopModelMatrix](https://wiki.facepunch.com/gmod/cam.PopModelMatrix).
---
--- When used in [PANEL:Paint](https://wiki.facepunch.com/gmod/PANEL:Paint), if you want to rely on the
--- top-left position of the panel, you must use
--- [VMatrix:Translate](https://wiki.facepunch.com/gmod/VMatrix:Translate) with the `(0, 0)` position of
--- the panel relative to the screen.
---
--- If trying to use it with [cam.Start3D2D](https://wiki.facepunch.com/gmod/cam.Start3D2D), set
--- `multiply` to `true`, since **cam.Start3D2D** pushes its own model matrix.
---
---@param matrix garrysmod.VMatrix The matrix to push.
---@param multiply boolean? If set, multiplies given matrix with currently active matrix ([cam.GetModelMatrix](https://wiki.facepunch.com/gmod/cam.GetModelMatrix)) before pushing. Defaults to `false`.
function cam.PushModelMatrix( matrix, multiply ) end

--- [CLIENT]
---
--- Sets up a new rendering context. This is an extended version of
--- [cam.Start3D](https://wiki.facepunch.com/gmod/cam.Start3D) and
--- [cam.Start2D](https://wiki.facepunch.com/gmod/cam.Start2D). Must be finished by
--- [cam.End3D](https://wiki.facepunch.com/gmod/cam.End3D) or
--- [cam.End2D](https://wiki.facepunch.com/gmod/cam.End2D).
---
--- > **BUG**: This will not update current view properties for 3D contexts. See
--- > [issue #2682](https://github.com/Facepunch/garrysmod-issues/issues/2682).
---
---@param data garrysmod.RenderCamData Render context config. See [Structures/RenderCamData](https://wiki.facepunch.com/gmod/Structures/RenderCamData).
function cam.Start( data ) end

--- [CLIENT]
---
--- Sets up the model transformation matrix to draw 2D content in 3D space and pushes it into the stack
--- ([cam.PushModelMatrix](https://wiki.facepunch.com/gmod/cam.PushModelMatrix)).
---
--- Matrix formula:
---
--- ```lua
--- local m = Matrix()
--- m:SetAngles( angles )
--- m:SetTranslation( pos )
--- m:SetScale( Vector( scale, -scale, 1 ) )
--- ```
---
--- > **WARNING**: This must be closed by [cam.End3D2D](https://wiki.facepunch.com/gmod/cam.End3D2D). If
--- > not done so, unexpected issues might arise.
---
--- [render.SetToneMappingScaleLinear](https://wiki.facepunch.com/gmod/render.SetToneMappingScaleLinear)
--- may be of use when dealing with bloom.
---
---@param pos garrysmod.Vector Origin of the 3D2D context, ie. the top left corner, `(0, 0)`.
---@param angles garrysmod.Angle Angles of the 3D2D context. `+x` in the 2D context corresponds to `+x` of the angle (its forward direction). `+y` in the 2D context corresponds to `-y` of the angle (its right direction).
---@param scale number The scale of the render context. If scale is `1` then `1` pixel in 2D context will equal to `1` unit in 3D context.
function cam.Start3D2D( pos, angles, scale ) end

--- [CLIENT]
---
--- Sets up a new 3D context using orthographic projection.
---
---@param left_offset number The left plane offset.
---@param top_offset number The top plane offset.
---@param right_offset number The right plane offset.
---@param bottom_offset number The bottom plane offset.
function cam.StartOrthoView( left_offset, top_offset, right_offset, bottom_offset ) end
