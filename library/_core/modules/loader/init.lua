---@meta _

--- [SHARED AND MENU]
---
--- Loads the package and returns the value returned by its entrypoint.
---
--- An installed package is used if its `{author}/{name}` is `user/repo` or it comes from the repository,
--- a missing one is installed from the repository (not on the client): the default branch without a range,
--- the newest version tag (`v1.0.0` or `1.0.0`) that matches the range otherwise, see `loader.install`.
---
--- The calling package starts to depend on the imported one, so it is unloaded when the imported one unloads.
---
--- ```lua
--- local my_lib = import( "user/my_lib" )          -- the default branch
--- local old_lib = import( "user/my_lib@^1.0.0" )  -- the newest tag that matches the range
--- local other = import( "https://github.com/user/other_lib@1.2.0" )
--- ```
---
---@param spec string `user/repo[@range]`, `host/user/repo[@range]` or `https://host/user/repo[@range]`.
---@return any exports The value returned by the entrypoint.
---@async
function import(spec) end

--- [SHARED AND MENU]
---
--- Runs the Lua file and returns its results, every call runs it again.
---
--- In a package the file must be inside of the package and runs as a new module,
--- relative paths are relative to the directory of the calling file.
---
---@param file_path string The path to the Lua file.
---@param ... any The arguments passed to the file.
---@return any ... The values returned by the file.
---@async
function dofile(file_path, ...) end

--- [SHARED AND MENU]
---
--- Runs the Lua module once and returns its result, the next calls return the same result.
---
--- In a package, dotted names (`utils.math`) are looked up in `lua/` of the package and paths (`./utils.lua`)
--- are relative to the calling file, only files of the package can be required and every package has its own modules.
---
--- Outside of packages, dotted names are looked up in `/game/lua` and paths are relative to the calling file.
---
---@param module_name string The name or the path of the module.
---@param ... any The arguments passed to the module when it runs for the first time.
---@return any result The value returned by the module, `true` if it returned nothing.
---@async
function require(module_name, ...) end
