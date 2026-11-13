---@meta garrysmod.surface


--- Font properties used by `surface.CreateFont`.
---
---@class garrysmod.FontData
---@field font string? The font source. Custom font files are stored in `resource/fonts/`. The length is limited to 31 characters maximum. This must be the actual 'nice' font name, not a file name (unless the client is running Linux or macOS). This also cannot be an already registered font. Default is `"Arial"`.
---@field extended boolean? Allow the font to display glyphs that are outside of the Latin-1 range. Unicode code points above `0xFFFF` are not supported. Currently has no effect on Linux (capped at `0xFF`). Default is `false`.
---@field size number? The font height in pixels. Range: `4` - `255`. Default is `13`.
---@field weight number? The font boldness. Default is `500`.
---@field blursize number? The strength of the font blurring. Range: `0` - `80`. Default is `0`.
---@field scanlines number? The "scanline" interval. Must be `> 1` to work. This setting is per blursize per font. Default is `0`.
---@field antialias boolean? Smooth the font. Default is `true`.
---@field underline boolean? Add an underline to the font. Default is `false`.
---@field italic boolean? Make the font italic. Default is `false`.
---@field strikeout boolean? Add a strike through. Default is `false`.
---@field symbol boolean? Enables the use of symbolic fonts such as Webdings. Default is `false`.
---@field rotary boolean? Seems to add a line in the middle of each letter. Default is `false`.
---@field shadow boolean? Add shadow casting to the font. Default is `false`.
---@field additive boolean? Additive rendering. Default is `false`.
---@field outline boolean? Add a black outline to the font. Does not work well with antialias, and only allows black 1-pixel outlines. Default is `false`.

--- Vertex information for use with `surface.DrawPoly`.
---
--- UV coordinates describe which part of a given texture should be drawn at a vertex. UV coords range from `0-1`, with `0` being top/left and `1` being bottom/right. If you're using a texture these are mandatory.
---
--- You must pass a table of tables with this structure. **You need to pass at least 3 points.**
--- Your points must be defined in a **clockwise order.** Otherwise, your shape will not render properly.
---
---@class garrysmod.PolygonVertex
---@field x number The x coordinate of the vertex.
---@field y number The y coordinate of the vertex.
---@field u number? The u texture coordinate of the vertex. Can be left blank.
---@field v number? The v texture coordinate of the vertex. Can be left blank.

--- Position and scissor information for the panel currently being drawn.
---
--- Returned by `surface.GetPanelPaintState`.
---
---@class garrysmod.PanelPaintState
---@field translate_x number The X coordinate for the top-left corner of the panel currently being drawn.
---@field translate_y number The Y coordinate for the top-left corner of the panel currently being drawn.
---@field scissor_left number The X coordinate for the left edge of the scissor rect that surrounds the panel currently being drawn.
---@field scissor_top number The Y coordinate for the top edge of the scissor rect that surrounds the panel currently being drawn.
---@field scissor_right number The X coordinate for the right edge of the scissor rect that surrounds the panel currently being drawn.
---@field scissor_bottom number The Y coordinate for the bottom edge of the scissor rect that surrounds the panel currently being drawn.
---@field scissor_enabled boolean Whether or not the panel currently being drawn has `render.SetScissorRect` active.

--- [CLIENT AND MENU]
---
--- The surface library allows you to draw text and shapes on the screen. Primarily used for making HUDs & custom GUI panels.
---
---@class garrysmod.surface
surface = {}

--- [CLIENT AND MENU]
---
--- Creates a new font.
---
--- To prevent the font from displaying incorrectly when using the `outline` setting, set `antialias` to `false`. This will ensure the text properly fills out the entire outline.
---
--- Be sure to check the [List of Default Fonts](https://wiki.facepunch.com/gmod/Default_Fonts) first! Those fonts can be used without using this function.
---
--- See also [Finding the Font Name](https://wiki.facepunch.com/gmod/Finding_the_Font_Name).
---
--- > **WARNING**: Due to the static nature of fonts, do **NOT** create the font more than once. You should only be creating them once, it is recommended to create them at the top of your script. Do not use this function within `GM:HUDPaint` or any other hook!
--- >
--- > Define fonts that you will actually use, as fonts are very taxing on performance and will cause crashes! Do not create fonts for every size.
---
---@param font_name string The new font name.
---@param font_data garrysmod.FontData The font properties.
function surface.CreateFont( font_name, font_data ) end

--- [CLIENT AND MENU]
---
--- Draws a hollow circle, made of lines. For a filled circle, see examples for `surface.DrawPoly`.
---
---@param origin_x number The center x integer coordinate.
---@param origin_y number The center y integer coordinate.
---@param radius number The radius of the circle.
---@param r integer The red value of the color to draw the circle with.
---@param g integer The green value of the color to draw the circle with.
---@param b integer The blue value of the color to draw the circle with.
---@param a integer? The alpha value of the color to draw the circle with. Defaults to `255`.
---@overload fun(origin_x: number, origin_y: number, radius: number, color: garrysmod.Color)
function surface.DrawCircle( origin_x, origin_y, radius, r, g, b, a ) end

--- [CLIENT AND MENU]
---
--- Draws a line from one point to another.
---
---@param start_x number The start x float coordinate.
---@param start_y number The start y float coordinate.
---@param end_x number The end x float coordinate.
---@param end_y number The end y float coordinate.
function surface.DrawLine( start_x, start_y, end_x, end_y ) end

--- [CLIENT AND MENU]
---
--- Draws a hollow box with a given border width.
---
---@param x number The start x integer coordinate.
---@param y number The start y integer coordinate.
---@param w number The integer width.
---@param h number The integer height.
---@param thickness number? The thickness of the outlined box border. Defaults to `1`.
function surface.DrawOutlinedRect( x, y, w, h, thickness ) end

--- [CLIENT AND MENU]
---
--- Draws a textured polygon (secretly a triangle fan) with a maximum of `4096` vertices.
--- Only works properly with convex polygons. You may try to render concave polygons, but there is no guarantee that things wont get messed up.
---
--- Unlike most surface library functions, non-integer coordinates are not rounded.
---
--- > **WARNING**: You must reset the drawing color and texture before calling the function to ensure consistent results.
---
---@param vertices garrysmod.PolygonVertex[] A table containing integer vertices. **The vertices must be in clockwise order.**
function surface.DrawPoly( vertices ) end

--- [CLIENT AND MENU]
---
--- Draws a solid rectangle on the screen.
---
---@param x number The X integer co-ordinate.
---@param y number The Y integer co-ordinate.
---@param width number The integer width of the rectangle.
---@param height number The integer height of the rectangle.
function surface.DrawRect( x, y, width, height ) end

--- [CLIENT AND MENU]
---
--- Draw the specified text on the screen, using the previously set position (`surface.SetTextPos`), font (`surface.SetFont`) and color (`surface.SetTextColor`). This function does **not** handle newlines.
---
--- This function moves the text position by the length of the drawn text - this can be used to change text properties (such as font or color) without having to manually recalculate the text position.
---
---@param text string The text to be rendered.
---@param force_additive boolean? `true` to force text to render additive, `false` to force not additive, `nil` to use font's value. When additive rendering is enabled, the rendered text pixels will be added to the existing screen pixels, rather than replacing them outright. This means black text will be invisible, and drawing on a pure white background will be impossible.
function surface.DrawText( text, force_additive ) end

--- [CLIENT AND MENU]
---
--- Draw a textured rectangle with the given position and dimensions on the screen, using the current active texture set with `surface.SetMaterial`. It is also affected by `surface.SetDrawColor`.
---
--- See also [render.SetMaterial](https://wiki.facepunch.com/gmod/render.SetMaterial) and [render.DrawScreenQuadEx](https://wiki.facepunch.com/gmod/render.DrawScreenQuadEx).
--- See also `surface.DrawTexturedRectUV` and `surface.DrawTexturedRectRotated`.
---
---@param x number The X integer co-ordinate.
---@param y number The Y integer co-ordinate.
---@param width number The integer width of the rectangle.
---@param height number The integer height of the rectangle.
function surface.DrawTexturedRect( x, y, width, height ) end

--- [CLIENT AND MENU]
---
--- Draws a textured rectangle with a repeated or partial texture.
---
--- This is identical to `surface.DrawTexturedRectUV`, but does not suffer from internal UV adjustments made by the engine. It is a separate function to prevent issues with existing content that manually adjusts for the internal UV adjustments.
---
--- For all intents and purposes, this function should be used over its predecessor.
---
---@param x number The X integer coordinate.
---@param y number The Y integer coordinate.
---@param width number The integer width of the rectangle.
---@param height number The integer height of the rectangle.
---@param start_u number The U texture mapping of the rectangle origin.
---@param start_v number The V texture mapping of the rectangle origin.
---@param end_u number The U texture mapping of the rectangle end.
---@param end_v number The V texture mapping of the rectangle end.
function surface.DrawTexturedRectRawUV( x, y, width, height, start_u, start_v, end_u, end_v ) end

--- [CLIENT AND MENU]
---
--- Draw a textured rotated rectangle with the given position and dimensions and angle on the screen, using the current active texture.
---
--- See also `surface.DrawTexturedRectUV` and `surface.DrawTexturedRect`.
---
---@param x number The X integer co-ordinate, representing the center of the rectangle.
---@param y number The Y integer co-ordinate, representing the center of the rectangle.
---@param width number The integer width of the rectangle.
---@param height number The integer height of the rectangle.
---@param rotation number The rotation of the rectangle, in degrees.
function surface.DrawTexturedRectRotated( x, y, width, height, rotation ) end

--- [CLIENT AND MENU]
---
--- Draws a textured rectangle with a repeated or partial texture.
---
--- `u` and `v` refer to texture coordinates.
--- * `(u, v) = (0, 0)` is the top left
--- * `(u, v) = (1, 0)` is the top right
--- * `(u, v) = (1, 1)` is the bottom right
--- * `(u, v) = (0, 1)` is the bottom left
---
--- Using a start point of `(1, 0)` and an end point of `(0, 1)`, you can draw an image flipped horizontally, same goes with other directions. Going above `1` will tile the texture. Negative values are allowed as well.
---
--- See also `surface.DrawTexturedRect`, `surface.DrawTexturedRectRotated` and `surface.DrawTexturedRectRawUV`.
---
--- > **NOTE**: If you are using a `.png` image, you need supply the `"noclamp"` flag as second parameter for [Material](https://wiki.facepunch.com/gmod/Global.Material) if you intend to use tiling.
---
--- > **NOTE**: If you find that `surface.DrawTexturedRectUV` is getting your texture coordinates `(u0, v0)`, `(u1, v1)` wrong and you're rendering with a material created with [CreateMaterial](https://wiki.facepunch.com/gmod/Global.CreateMaterial), try adjusting them with:
--- > ```lua
--- > local du = 0.5 / 32 -- half pixel anticorrection
--- > local dv = 0.5 / 32 -- half pixel anticorrection
--- > local u0, v0 = ( u0 - du ) / ( 1 - 2 * du ), ( v0 - dv ) / ( 1 - 2 * dv )
--- > local u1, v1 = ( u1 - du ) / ( 1 - 2 * du ), ( v1 - dv ) / ( 1 - 2 * dv )
--- > ```
--- > `surface.DrawTexturedRectUV` tries to correct the texture coordinates by half a pixel and computes the correction using `IMaterial:GetMappingWidth()` / `GetMappingHeight()`. If the material was created without a `$basetexture`, then those use the width and height of the error material (`32x32`).
---
--- > **BUG**: The UV offsets might require (sub-)pixel correction for accurate tiling results.
--- > See [issue #3173](https://github.com/Facepunch/garrysmod-issues/issues/3173).
---
---@param x number The X integer coordinate.
---@param y number The Y integer coordinate.
---@param width number The integer width of the rectangle.
---@param height number The integer height of the rectangle.
---@param start_u number The U texture mapping of the rectangle origin.
---@param start_v number The V texture mapping of the rectangle origin.
---@param end_u number The U texture mapping of the rectangle end.
---@param end_v number The V texture mapping of the rectangle end.
function surface.DrawTexturedRectUV( x, y, width, height, start_u, start_v, end_u, end_v ) end

--- [CLIENT AND MENU]
---
--- Returns the current alpha multiplier affecting drawing operations. This is set by `surface.SetAlphaMultiplier` or by the game engine in certain other cases.
---
---@return number multiplier The multiplier ranging from `0` to `1`.
function surface.GetAlphaMultiplier() end

--- [CLIENT AND MENU]
---
--- Returns the current color affecting draw operations.
---
---@return garrysmod.Color color The color that drawing operations will use.
function surface.GetDrawColor() end

--- [CLIENT]
---
--- Returns the [HUD icon](https://github.com/Facepunch/garrysmod/blob/master/garrysmod/scripts/hud_textures.txt) TextureID of a texture with the specified name.
---
--- You probably want to use [Material](https://wiki.facepunch.com/gmod/Global.Material) and `surface.SetMaterial`.
---
---@param name string The name of the texture.
---@return integer texture_id The texture ID, for use with `surface.SetTexture`.
function surface.GetHUDTexture( name ) end

--- [CLIENT]
---
--- Retrieves the position and [ScissorRect](https://wiki.facepunch.com/gmod/render.SetScissorRect) information for the panel that is currently being drawn.
---
--- When using the surface library (and, by extension, the draw library) inside of the [PANEL:Paint](https://wiki.facepunch.com/gmod/PANEL:Paint) function, the origin (the on-screen position of `(0,0)`) is automatically shifted to the top-left corner of the panel to make it easier to draw the panel's contents. Additionally, `render.SetScissorRect` is used to clip (or "mask") all drawn content to within the boundaries of the panel. This function returns the information used by the surface library about the current panel's origin and scissor rect.
---
---@return garrysmod.PanelPaintState paint_state A table containing the position and scissor rect boundaries for the panel currently being drawn.
function surface.GetPanelPaintState() end

--- [CLIENT]
---
--- Retrieves the currently active scissor rect for the surface library. A faster, narrower version of `surface.GetPanelPaintState`.
---
--- Useful for retrieving current panel's culling from `PANEL:Paint`.
---
--- This does **NOT** return values set by `render.SetScissorRect`.
---
---@return boolean active Whether the scissor rect is active or not. If `false`, the following values should be ignored.
---@return number left Left edge of the scissor rect.
---@return number top Top edge of the scissor rect.
---@return number right Right edge of the scissor rect.
---@return number bottom Bottom edge of the scissor rect.
function surface.GetScissorRect() end

--- [CLIENT AND MENU]
---
--- Returns the current color affecting text draw operations.
---
---@return garrysmod.Color color The color that text drawing operations will use.
function surface.GetTextColor() end

--- [CLIENT AND MENU]
---
--- Returns the X and Y co-ordinate that has been set with `surface.SetTextPos` or changed by `surface.DrawText`.
---
---@return number x The X integer co-ordinate.
---@return number y The Y integer co-ordinate.
function surface.GetTextPos() end

--- [CLIENT AND MENU]
---
--- Returns the width and height (in pixels) of the given text with the font that has been set with `surface.SetFont`.
---
--- > **NOTE**: Takes into account new lines, the returned height is for the entire text, but `surface.DrawText` does not!
---
---@param text string The string to check the size of.
---@return number width Width of the provided text.
---@return number height Height of the provided text.
function surface.GetTextSize( text ) end

--- [CLIENT AND MENU]
---
--- Returns the texture id of the material with the given name/path, for use with `surface.SetTexture`.
---
--- Opposite version of this function is `surface.GetTextureNameByID`.
---
--- > **NOTE**: This function will not work with `.png` or `.jpg` images. For that, see [Material](https://wiki.facepunch.com/gmod/Global.Material). You will probably want to use it regardless.
---
---@param name_or_path string Name or path of the texture. The path must be to a `.vmt` file (a material), not to `.vtf` (a texture)!
---@return integer texture_id The texture ID.
function surface.GetTextureID( name_or_path ) end

--- [CLIENT AND MENU]
---
--- Returns name/path of texture by ID. Opposite version of this function is `surface.GetTextureID`.
---
---@param id integer ID of texture.
---@return string name Returns name/path of texture.
function surface.GetTextureNameByID( id ) end

--- [CLIENT AND MENU]
---
--- Returns the size of the texture with the associated texture ID.
---
--- For `.png`/`.jpg` textures loaded with [Material](https://wiki.facepunch.com/gmod/Global.Material) you can use the `$realheight` and `$realwidth` material parameters ([IMaterial:GetInt](https://wiki.facepunch.com/gmod/IMaterial:GetInt)) to get the size of the image.
---
---@param texture_id integer The texture ID, returned by `surface.GetTextureID`.
---@return number width The texture width.
---@return number height The texture height.
function surface.GetTextureSize( texture_id ) end

--- [CLIENT AND MENU]
---
--- Play a sound file directly on the client (such as UI sounds, etc).
---
--- > **NOTE**: Valid sample rates: **11025 Hz, 22050 Hz and 44100 Hz**, otherwise you may see messages like `Unsupported 32-bit wave file your_sound.wav` and `Invalid sample rate (48000) for sound 'your_sound.wav'`.
---
---@param soundfile string The path to the sound file. This should either be a sound script name ([sound.Add](https://wiki.facepunch.com/gmod/sound.Add)) or a file path relative to the `sound/` folder. (Make note that it's not `sounds`)
function surface.PlaySound( soundfile ) end

--- [CLIENT AND MENU]
---
--- Sets the alpha multiplier that will influence all upcoming drawing operations.
---
--- See also [render.SetBlend](https://wiki.facepunch.com/gmod/render.SetBlend).
---
---@param multiplier number The multiplier ranging from `0` to `1`.
function surface.SetAlphaMultiplier( multiplier ) end

--- [CLIENT AND MENU]
---
--- Set the color of any future shapes to be drawn, can be set by either using R, G, B, A as separate values or by passing a `Color`.
---
--- > **NOTE**: The alpha value may not work properly if you're using a material without `$vertexalpha`.
---
--- > **NOTE**: Due to post processing and gamma correction the color you set with this function may appear differently when rendered. This problem does not occur on materials drawn with `surface.DrawTexturedRect`.
---
---@param r integer The red value of color.
---@param g integer The green value of color.
---@param b integer The blue value of color.
---@param a integer? The alpha value of color. Defaults to `255`.
---@overload fun(color: garrysmod.Color) A `Color` object/table to read the color from. This is slower than providing four numbers. You could use `Color:Unpack` to address this. You should also cache your color objects if you wish to use them, for performance reasons.
function surface.SetDrawColor( r, g, b, a ) end

--- [CLIENT AND MENU]
---
--- Set the current font to be used for text operations later.
---
--- The fonts must first be created with `surface.CreateFont` or be one of the [Default Fonts](https://wiki.facepunch.com/gmod/Default_Fonts).
---
---@param font_name string The name of the font to use.
function surface.SetFont( font_name ) end

--- [CLIENT AND MENU]
---
--- Sets the material to be used in all upcoming draw operations using the surface library.
---
--- Not to be confused with [render.SetMaterial](https://wiki.facepunch.com/gmod/render.SetMaterial).
---
--- If you need to unset the texture, use the [draw.NoTexture](https://wiki.facepunch.com/gmod/draw.NoTexture) convenience function.
---
--- > **WARNING**: [Material](https://wiki.facepunch.com/gmod/Global.Material) function calls are expensive to be done inside this function or inside rendering context, you should be caching the results of `Material` calls.
---
--- > **NOTE**: When using `render.PushRenderTarget` or `render.SetRenderTarget`, the material should have the `$ignorez` flag set to make it visible. If the material is not used in 3D rendering, it is probably safe to add it with:
--- > ```lua
--- > material:SetInt( "$flags", bit.bor( material:GetInt( "$flags" ), 32768 ) )
--- > ```
--- > If using `Material`, simply use the `ignorez` parameter.
---
---@param material garrysmod.Material The material to be used. Unlike `surface.SetTexture`, this uses a material object rather than a texture ID.
function surface.SetMaterial( material ) end

--- [CLIENT AND MENU]
---
--- Set the color of any future text to be drawn, can be set by either using R, G, B, A as separate values or by passing a `Color`.
---
---@param r integer The red value of color.
---@param g integer The green value of color.
---@param b integer The blue value of color.
---@param a integer? The alpha value of color. Defaults to `255`.
---@overload fun(color: garrysmod.Color) A `Color` object/table to read the color from. This is slower than providing four numbers. You could use `Color:Unpack` to address this. You should also cache your color objects if you wish to use them, for performance reasons.
function surface.SetTextColor( r, g, b, a ) end

--- [CLIENT AND MENU]
---
--- Set the top-left position to draw any future text at.
---
---@param x number The X integer co-ordinate.
---@param y number The Y integer co-ordinate.
function surface.SetTextPos( x, y ) end

--- [CLIENT AND MENU]
---
--- Sets the texture to be used in all upcoming draw operations using the surface library.
---
--- This is a legacy method, and should probably not be used, see `surface.SetMaterial` and [IMaterial](https://wiki.facepunch.com/gmod/IMaterial) for a better alternative.
---
---@param texture_id integer The ID of the texture to draw with returned by `surface.GetTextureID`.
function surface.SetTexture( texture_id ) end
