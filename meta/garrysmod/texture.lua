---@meta garrysmod.texture


--- [SHARED AND MENU]
---
--- An object representing a game texture, such as those loaded from a `.vtf` file.
---
--- Do not confuse with `IMaterial`. Materials use textures. Game uses materials.
---
--- Returned by `IMaterial:GetTexture`.
---
---@class garrysmod.Texture : metatable
local Texture = {}

--- [SHARED AND MENU]
---
--- Invokes the generator of the texture.
--- Reloads file based textures from disk and clears render target textures.
---
function Texture:Download() end

--- [SHARED AND MENU]
---
--- Returns the color of the specified pixel, only works for textures created from PNG files.
---
---@param x integer The x coordinate.
---@param y integer The y coordinate.
---@return garrysmod.Color color The color of the pixel.
function Texture:GetColor( x, y ) end

--- [SHARED AND MENU]
---
--- Returns the true unmodified height of the texture.
---
---@return integer height The unmodified height in pixels.
function Texture:GetMappingHeight() end

--- [SHARED AND MENU]
---
--- Returns the true unmodified width of the texture.
---
---@return integer width The unmodified width in pixels.
function Texture:GetMappingWidth() end

--- [SHARED AND MENU]
---
--- Returns the name of the texture, in most cases the path.
---
---@return string name The name of the texture.
function Texture:GetName() end

--- [SHARED AND MENU]
---
--- Returns the number of animation frames in this texture.
---
---@return integer count The number of animation frames.
function Texture:GetNumAnimationFrames() end

--- [SHARED AND MENU]
---
--- Returns the modified height of the texture, this value may be affected by mipmapping and other factors.
---
---@return integer height The modified height in pixels.
function Texture:Height() end

--- [SHARED AND MENU]
---
--- Returns whether the texture failed to load.
---
--- > NOTE: The "error" texture is a valid texture, and therefore this function will return `false` when used on it.
--- > Use `Texture:IsErrorTexture` instead.
---
---@return boolean is_error `true` if the texture was not loaded successfully.
function Texture:IsError() end

--- [SHARED AND MENU]
---
--- Returns whether the texture is the error texture (pink and black checkerboard pattern).
---
---@return boolean is_error_texture `true` if the texture is the error texture.
function Texture:IsErrorTexture() end

--- [SHARED AND MENU]
---
--- Returns the modified width of the texture, this value may be affected by mipmapping and other factors.
---
---@return integer width The modified width in pixels.
function Texture:Width() end
