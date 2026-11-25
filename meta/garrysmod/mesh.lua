---@meta garrysmod.mesh


--- Primitive type passed to `mesh.Begin` ([Enums/MATERIAL](https://wiki.facepunch.com/gmod/Enums/MATERIAL)).
---
--- The meaning of `primitive_count` depends on the type:
--- * `MATERIAL_POINTS` (`0`) — currently does nothing.
--- * `MATERIAL_LINES` (`1`) — number of lines; each line uses 2 vertices.
--- * `MATERIAL_TRIANGLES` (`2`) — number of triangles; each uses 3 vertices.
--- * `MATERIAL_TRIANGLE_STRIP` (`3`) — number of triangles; `vertex_count - 2`.
--- * `MATERIAL_LINE_STRIP` (`4`) — number of line segments.
--- * `MATERIAL_LINE_LOOP` (`5`) — like line strip, first and last vertices connect.
--- * `MATERIAL_POLYGON` (`6`) — number of vertices of the fan.
--- * `MATERIAL_QUADS` (`7`) — number of quads; each uses 4 vertices.
---
---@alias garrysmod.MeshPrimitiveType
---| 0 # `MATERIAL_POINTS`
---| 1 # `MATERIAL_LINES`
---| 2 # `MATERIAL_TRIANGLES`
---| 3 # `MATERIAL_TRIANGLE_STRIP`
---| 4 # `MATERIAL_LINE_STRIP`
---| 5 # `MATERIAL_LINE_LOOP`
---| 6 # `MATERIAL_POLYGON`
---| 7 # `MATERIAL_QUADS`

--- [CLIENT]
MATERIAL_POINTS = 0

--- [CLIENT]
MATERIAL_LINES = 1

--- [CLIENT]
MATERIAL_TRIANGLES = 2

--- [CLIENT]
MATERIAL_TRIANGLE_STRIP = 3

--- [CLIENT]
MATERIAL_LINE_STRIP = 4

--- [CLIENT]
MATERIAL_LINE_LOOP = 5

--- [CLIENT]
MATERIAL_POLYGON = 6

--- [CLIENT]
MATERIAL_QUADS = 7

--- [CLIENT]
---
--- Immediate-mode mesh builder.
---
--- Call `mesh.Begin`, set attributes (`Position`, `Normal`, …), push each vertex with
--- `AdvanceVertex`, then `mesh.End`. For meshes drawn every frame unchanged, prefer building
--- an `IMesh` once with `Mesh` / `IMesh:BuildFromTriangles` (or `mesh.Begin( imesh, … )`) and
--- calling `IMesh:Draw`.
---
---@class garrysmod.mesh
mesh = {}

--- [CLIENT]
---
--- Pushes the currently set vertex attributes into the mesh started with `mesh.Begin`.
---
function mesh.AdvanceVertex() end

--- [CLIENT]
---
--- Starts building a mesh of the given primitive type and count.
---
--- Pass an `IMesh` to write into a static mesh (at most `65535` vertices). Without it, a
--- dynamic mesh is built and drawn by `mesh.End` (at most `32768` vertices).
---
--- Rebuilds of an existing `IMesh` may only rewrite vertices; the vertex count must stay the same.
---
--- ```lua
--- render.SetMaterial( Material( "editor/wireframe" ) )
--- mesh.Begin( MATERIAL_TRIANGLES, 1 )
---     mesh.Position( 0, 0, 0 )
---     mesh.TexCoord( 0, 0, 0 )
---     mesh.AdvanceVertex()
---     mesh.Position( 10, 0, 0 )
---     mesh.TexCoord( 0, 1, 0 )
---     mesh.AdvanceVertex()
---     mesh.Position( 10, 10, 0 )
---     mesh.TexCoord( 0, 1, 1 )
---     mesh.AdvanceVertex()
--- mesh.End()
--- ```
---
---@overload fun(primitive_type: garrysmod.MeshPrimitiveType, primitive_count: integer)
---@param imesh garrysmod.IMesh The static mesh to fill or rewrite.
---@param primitive_type garrysmod.MeshPrimitiveType Primitive format, see `MATERIAL_*`.
---@param primitive_count integer Number of primitives; meaning depends on `primitive_type`.
function mesh.Begin( imesh, primitive_type, primitive_count ) end

--- [CLIENT]
---
--- Sets a bone weight for the next vertex (skinned meshes).
---
---@param index integer Slot index, `0` or `1`.
---@param matrix_id integer Bone matrix index into `IMesh:DrawSkinned`'s `bones` table minus `1` (`0`–`52`).
---@param weight number Influence of that bone, `0`–`1`.
function mesh.BoneData( index, matrix_id, weight ) end

--- [CLIENT]
---
--- Sets the color (`COLOR0`) for the next vertex.
---
---@param r integer Red, `0`–`255`.
---@param g integer Green, `0`–`255`.
---@param b integer Blue, `0`–`255`.
---@param a integer Alpha, `0`–`255`.
function mesh.Color( r, g, b, a ) end

--- [CLIENT]
---
--- Finishes the mesh started with `mesh.Begin`.
---
--- For a dynamic mesh (no `IMesh` passed to `Begin`), draws it immediately with the material
--- set by `render.SetMaterial`. For a static `IMesh`, only finishes writing; call `IMesh:Draw`.
---
function mesh.End() end

--- [CLIENT]
---
--- Sets the normal for the next vertex.
---
---@overload fun(x: number, y: number, z: number)
---@param normal garrysmod.Vector The vertex normal.
function mesh.Normal( normal ) end

--- [CLIENT]
---
--- Sets the position for the next vertex.
---
---@overload fun(x: number, y: number, z: number)
---@param position garrysmod.Vector The vertex position.
function mesh.Position( position ) end

--- [CLIENT]
---
--- Adds a colored quad (4 vertices) to the mesh started with `mesh.Begin`.
---
---@param vertex1 garrysmod.Vector First corner.
---@param vertex2 garrysmod.Vector Second corner.
---@param vertex3 garrysmod.Vector Third corner.
---@param vertex4 garrysmod.Vector Fourth corner.
---@param color garrysmod.Color Color of the four vertices.
function mesh.Quad( vertex1, vertex2, vertex3, vertex4, color ) end

--- [CLIENT]
---
--- Adds a colored axis-aligned quad centered at `position`, facing `normal`.
---
---@param position garrysmod.Vector Center of the quad.
---@param normal garrysmod.Vector Face normal.
---@param size_x number Width.
---@param size_y number Height.
---@param color garrysmod.Color Color of the four vertices.
function mesh.QuadEasy( position, normal, size_x, size_y, color ) end

--- [CLIENT]
---
--- Sets the specular color (`COLOR1`) for the next vertex.
---
--- Used by shaders such as `Lightmapped_4WayBlend`; the shader must be built with `VERTEX_SPECULAR`.
---
---@param r integer Red, `0`–`255`.
---@param g integer Green, `0`–`255`.
---@param b integer Blue, `0`–`255`.
---@param a integer Alpha, `0`–`255`.
function mesh.Specular( r, g, b, a ) end

--- [CLIENT]
---
--- Sets the S tangent (binormal) for the next vertex, used with bump mapping.
---
---@overload fun(x: number, y: number, z: number)
---@param tangent_s garrysmod.Vector The S tangent.
function mesh.TangentS( tangent_s ) end

--- [CLIENT]
---
--- Sets the T tangent for the next vertex, used with bump mapping.
---
---@overload fun(x: number, y: number, z: number)
---@param tangent_t garrysmod.Vector The T tangent.
function mesh.TangentT( tangent_t ) end

--- [CLIENT]
---
--- Sets texture coordinates for the next vertex.
---
--- Set `0` is the primary UV. Sets `1`–`7` need material support (e.g. `LightmappedGeneric`
--- uses set `1` for lightmaps).
---
---@param set integer Texture coordinate set, `0`–`7`.
---@param s number S (U) coordinate.
---@param t number? T (V) coordinate.
---@param u number? Optional third component.
---@param v number? Optional fourth component.
function mesh.TexCoord( set, s, t, u, v ) end

--- [CLIENT]
---
--- Sets four shader-specific numbers for the next vertex (often tangent `x, y, z, handedness`).
---
---@param tangent_x number First userdata component.
---@param tangent_y number Second userdata component.
---@param tangent_z number Third userdata component.
---@param tangent_handedness number Fourth userdata component.
function mesh.UserData( tangent_x, tangent_y, tangent_z, tangent_handedness ) end

--- [CLIENT]
---
--- Returns how many vertices have been pushed with `mesh.AdvanceVertex` since `mesh.Begin`.
---
---@return integer count The number of advanced vertices.
---@nodiscard
function mesh.VertexCount() end
