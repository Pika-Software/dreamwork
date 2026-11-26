---@class dreamwork
local dreamwork = dreamwork

---@class dreamwork.std
local std = dreamwork.std

-- the client only receives packages from the server
if std.LUA_CLIENT then return end

local vfs = dreamwork.vfs
local vfs_writeFile = vfs.writeFile

local string = std.string
local string_gsub = string.gsub
local string_lower = string.lower
local string_format = string.format

local tostring = std.tostring
local error = std.error

local Zip = std.Zip
local AddonClass = std.Addon

---@class dreamwork.loader
local loader = dreamwork.loader

local internal = loader.Internal
local package_states = internal.package_states
local source_files = internal.source_files
local source_read = internal.source_read


--- [SERVER AND MENU]
---
--- Export: packs packages into `.zip` archives and `.gma` addons for the Workshop.
---

--- The folder of exported packages.
---
---@type string
local EXPORT_DIRECTORY = "/garrysmod/data/dreamwork/export"

---@alias dreamwork.loader.ExportFormat
---| "gma" # A `.gma` addon with the archive at `data_static/packages/{name}-{version}.zip.dat`, allowed by the Workshop whitelist.
---| "zip" # The `.zip` archive, saved as `.zip.dat` since `DATA` does not allow `.zip`.

--- [SERVER AND MENU]
---
--- Packs the files of the package into a `.zip` archive with `package.json` at its root.
---
--- Lua files are packed as they are, not preprocessed. Hidden files are skipped.
---
---@param package dreamwork.Package The package.
---@return string data The `.zip` data.
---@async
function loader.pack( package )
    local source = package_states[ package ].source
    if source.preprocessed then
        error( string_format( "'%s' came from the server, its Lua files are already preprocessed", package.id ), 2 )
    end

    local zip = Zip()

    local files, file_count = source_files( source )

    for index = 1, file_count, 1 do
        local file_path = files[ index ]
        zip:addFile( file_path, source_read( source, file_path ) )
    end

    return zip:compile()
end

--- [SERVER AND MENU]
---
--- Exports the package into `/garrysmod/data/dreamwork/export`, the files are named `{name}-{version}`, the author is not a part of them.
---
--- `gma` gives an addon ready for the Workshop, the archive is placed at `data_static/packages/{name}-{version}.zip.dat`,
--- the package manager reads it from there when the addon is mounted.
--- `zip` gives the archive itself, saved as `{name}-{version}.zip.dat`, rename it to `.zip`
--- and put it into `/garrysmod/packages` or `/garrysmod/addons/*/packages` to install it.
---
---@param package dreamwork.Package The package.
---@param format dreamwork.loader.ExportFormat? The format, `gma` by default.
---@return string vfs_path The absolute virtual path of the exported file.
---@async
function loader.export( package, format )
    local data = loader.pack( package )

    local state = package_states[ package ]

    -- the version may have `+` build metadata
    local file_name = string_gsub( state.name .. "-" .. tostring( state.version ), "[^%w%._%-]", "_" )

    if format == "zip" then
        local vfs_path = EXPORT_DIRECTORY .. "/" .. file_name .. ".zip.dat"
        vfs_writeFile( vfs_path, data )
        return vfs_path
    end

    local manifest = state.manifest

    local addon = AddonClass()
    addon.title = state.name
    addon.description = manifest.description
    addon.author = manifest.author
    addon.type = "tool"
    addon.tags = { "build" }

    -- the engine keeps one file per path for all mounted addons, the version keeps different versions apart
    addon:addFile( "data_static/packages/" .. string_lower( file_name ) .. ".zip.dat", data )

    local is_allowed, reason = addon:isAllowed()
    if not is_allowed then
        error( string_format( "'%s' cannot be exported: %s", state.id, reason ), 2 )
    end

    local vfs_path = EXPORT_DIRECTORY .. "/" .. file_name .. ".gma"
    vfs_writeFile( vfs_path, addon:compile() )
    return vfs_path
end
