---@meta garrysmod.imesh


--- [CLIENT]
---
--- Creates a new empty engine mesh, fill it with `IMesh:BuildFromTriangles`.
---
--- > **NOTE**: `material` is only a hint for the vertex format, drawing still needs `render.SetMaterial`.
---
--- > **WARNING**: Doesn't work with `WorldVertexTransition` materials, `UnlitGeneric` works,
--- > `VertexLitGeneric` has shading issues.
---
---@param material garrysmod.Material? The material the mesh is meant to be drawn with.
---@param bone_weights integer? The number of bone weights per vertex, `2` enables `IMesh:DrawSkinned` ( dev branch ).
---@return garrysmod.IMesh imesh The new mesh.
function Mesh( material, bone_weights ) end

--- [CLIENT]
---
--- A static engine mesh, created by `Mesh`.
---
--- An `IMesh` holds at most 65535 vertices, split larger meshes into several.
--- Free the memory with `IMesh:Destroy` when the mesh is no longer needed.
---
---@class garrysmod.IMesh : metatable
local IMesh = {}

--- Fills the mesh with triangles, every 3 vertices make one triangle,
--- Source draws clockwise triangles as front faces.
---
--- > **WARNING**: When rebuilding a mesh that was built before, the new vertex count must match the old one.
---
---@param vertices garrysmod.MeshVertex[] The triangle corners.
function IMesh:BuildFromTriangles( vertices ) end

--- Deletes the mesh and frees the memory used by it.
function IMesh:Destroy() end

--- Draws the mesh with the active model matrix and the material set by `render.SetMaterial`.
---
--- > **NOTE**: `VertexLitGeneric` materials reuse the lighting of the previously drawn model,
--- > unless it is set with the `render` library ( e.g. `render.ResetModelLighting` ).
function IMesh:Draw() end

--- Draws the mesh with the active model matrix and the given bone matrices.
---
---@param bones garrysmod.VMatrix[] The bone matrices.
---@param multiply boolean? `true` to multiply the bones with the active model matrix.
function IMesh:DrawSkinned( bones, multiply ) end

--- Returns whether the mesh is valid ( not destroyed ).
---
---@return boolean is_valid `true` if the mesh can be drawn.
function IMesh:IsValid() end

--- [SHARED]
---
--- One vertex of `IMesh:BuildFromTriangles`, `util.GetModelMeshes`, `PhysObj:GetMesh` and `Entity:PhysicsFromMesh`
--- ( which only reads `pos` ). Not all fields are used by all shaders.
---
---@class garrysmod.MeshVertex
local MeshVertex = {}

--- The position in local space.
---
---@type garrysmod.Vector
MeshVertex.pos = nil

--- The unit normal, pointing away from the surface.
---
---@type garrysmod.Vector?
MeshVertex.normal = nil

--- The unit tangent, along the surface.
---
---@type garrysmod.Vector?
MeshVertex.tangent = nil

--- The cross product of the normal and the tangent.
---
---@type garrysmod.Vector?
MeshVertex.binormal = nil

--- The horizontal texture coordinate, `0` is the left edge, `1` the right edge.
---
---@type number?
MeshVertex.u = nil

--- The vertical texture coordinate, `0` is the top edge, `1` the bottom edge.
---
---@type number?
MeshVertex.v = nil

--- The secondary horizontal texture coordinate, only used by `IMesh:BuildFromTriangles`.
---
---@type number?
MeshVertex.u1 = nil

--- The secondary vertical texture coordinate, only used by `IMesh:BuildFromTriangles`.
---
---@type number?
MeshVertex.v1 = nil

--- The tint of the area around the vertex.
---
---@type garrysmod.Color?
MeshVertex.color = nil

--- Four shader specific numbers, many Source shaders read the tangent: `x, y, z, handedness`.
---
---@type number[]?
MeshVertex.userdata = nil
