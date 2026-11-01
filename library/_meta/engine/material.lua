---@meta _


---@alias MaterialParameters
---| 1 # Makes the created material a `VertexLitGeneric`, so it can be applied to models. Default shader is `UnlitGeneric`.
---| 2 # Sets the `$nocull` to `1` in the created material.
---| 4 # Sets the `$alphatest` to `1` in the created material instead of `$vertexalpha` being set to `1`.
---| 8 # Generates Mipmaps for the imported texture, or sets **No Level Of Detail** and **No Mipmaps** if unset. This adjusts the material's dimensions to a power of 2.
---| 16 # Makes the image able to tile when used with non standard UV maps. Sets the `CLAMPS` and `CLAMPT` flags if unset.
---| 32 # If set does nothing, if unset - enables **Point Sampling (Texture Filtering)** on the material as well as adds the **No Level Of Detail** flag to it.
---| 64 # If set, the material will be given `$ignorez` flag, which is necessary for some rendering operations, such as render targets and 3d2d rendering.
