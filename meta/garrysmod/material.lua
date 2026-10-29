---@meta garrysmod.material


---@class garrysmod.Material : metatable


--- [SHARED AND MENU]
---
--- Either returns the material with the given name, or loads the material interpreting the first argument as the path.
---
--- ## .png, .jpg and other image formats
---
--- This function is capable to loading `.png` or `.jpg` images, generating a texture and material for them on the fly.
---
--- PNG, JPEG, GIF, and TGA files will work, but only if they have the `.png` or `.jpg` file extensions (even if the actual image format doesn't match the file extension)
---
--- Use [Global.AddonMaterial](https://wiki.facepunch.com/gmod/Global.AddonMaterial) for image files with the `.cache` file extension. (from [steamworks.Download](https://wiki.facepunch.com/gmod/steamworks.Download))
---
--- While images are no longer scaled to Power of 2 (sizes of 8, 16, 32, 64, 128, etc.) sizes since February 2019, it is still a good practice for things like icons, etc.
---
--- **WARNING**: Server-side, this function can consistently return an invalid material (with '__error') depending on the file type loaded.
---
--- **WARNING**: This function is very expensive when used in rendering hooks or in operations requiring very frequent calls. It is a good idea to cache the material in a variable (like in the examples).
---
--- [View wiki](https://wiki.facepunch.com/gmod/Global.Material)
---
---@param file_path string The material name or path relative to the `garrysmod/` folder. `!` for Lua created materials.
---@param params string | nil A string containing space separated keywords, feature only works for `.png` or `.jpg` image files.
---@return garrysmod.Material material Generated material.
---@return number time_took How long it took for the function to run in seconds.
function Material( file_path, params ) end
