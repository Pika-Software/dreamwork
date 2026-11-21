local dreamwork = dreamwork
local dreamwork_cli = dreamwork.cli

local cli_print = dreamwork_cli.print
local cli_error = dreamwork_cli.error
local cli_shift = dreamwork_cli.shift
local cli_complete = dreamwork_cli.complete
local cli_printHeader = dreamwork_cli.printHeader

local colors = dreamwork_cli.colors

local std = dreamwork.std

local string = std.string
local string_find = string.find
local string_sub = string.sub
local string_format = string.format
local string_rep = string.rep

local table = std.table
local table_sort = table.sort
local table_concat = table.concat

local pcall = std.pcall
local tostring = std.tostring

local ascii_art = std.ascii.art
local art_tree = ascii_art.tree


--- The order of the statuses in the `package ls` summary.
---
---@type dreamwork.PackageStatus[]
local STATUS_ORDER = { "loaded", "loading", "installed", "failed" }

--- [SHARED AND MENU]
---
--- The package manager commands, `dreamwork_sci package <command>` / `dreamwork_cci package <command>`, only `ls` exists on the client.
---
local packages_group = dreamwork_cli.group( "package", "Package manager commands." )

---@param package dreamwork.Package
---@return string
local function describe( package )
    local status = package.status
    if status == "failed" and package.error ~= nil then
        status = "failed: " .. tostring( package.error.message )
    end

    return string_format( "%s (%s)", package.id, status )
end

--- Finds the package by `name`, `author/name`, `name@range` or `author/name@range`.
---
---@param spec string
---@return dreamwork.Package | nil
local function find( spec )
    local name, selector = spec, nil

    local at = string_find( spec, "@", 1, true )
    if at ~= nil then
        name, selector = string_sub( spec, 1, at - 1 ), string_sub( spec, at + 1 )
    end

    local success, package = pcall( dreamwork.loader.findPackage, name, selector )
    if success then
        return package
    end

    return nil
end

--- Completes the first argument with the names and ids of the packages.
---
---@param filter ( fun( package: dreamwork.Package ): boolean )?
---@return fun( _: any, _: any, argument_string: string ): string[] | nil
local function complete_packages( filter )
    return function( _, _, argument_string )
        local typed, rest = cli_shift( argument_string )
        if rest ~= nil then
            return nil
        end

        ---@type string[]
        local names = {}

        local list, count = dreamwork.loader.getPackages()

        for index = 1, count, 1 do
            local package = list[ index ]
            if filter == nil or filter( package ) then
                names[ #names + 1 ] = package.name
                names[ #names + 1 ] = package.id
            end
        end

        table_sort( names )
        return cli_complete( typed, names )
    end
end

---@param package dreamwork.Package
---@return boolean
local function is_upgradable( package )
    return package.origin == "repository"
end

---@param package dreamwork.Package
---@return boolean
local function is_removable( package )
    return package.origin ~= "local"
end

---@param package dreamwork.Package
---@return dreamwork.std.Color
local function status_color( package )
    local status = package.status
    if status == "loaded" then
        return colors.value
    elseif status == "failed" then
        return colors.error
    end

    return colors.description
end

---@param package dreamwork.Package
---@return string
local function origin_of( package )
    local origin = package.origin
    if origin == "repository" then
        return package.repository or origin
    end

    return origin
end

--- Children of a package for `art.tree`, in the style of `npm ls`.
---
--- A package already on the path is `circular`. A package collected earlier is
--- `deduped` and its dependencies are not repeated.
---
---@param package dreamwork.Package
---@param path table<dreamwork.Package, boolean> The packages from the root to this one.
---@param seen table<dreamwork.Package, boolean> The packages collected before.
---@return dreamwork.Package[] | nil dependencies
---@return string | nil mark `"circular"` or `"deduped"`.
local function package_children( package, path, seen )
    if path[ package ] then
        return nil, "circular"
    end

    if seen[ package ] then
        return nil, "deduped"
    end

    seen[ package ] = true

    local dependencies = package:getDependencies()
    return dependencies
end

--- Writes the package id with the author and the version dimmed.
---
---@param package dreamwork.Package
local function write_id( package )
    local id = package.id

    local slash = string_find( id, "/", 1, true )
    if slash ~= nil then
        dreamwork_cli.write( string_sub( id, 1, slash ), colors.description )
    end

    dreamwork_cli.write( package.name, colors.name )
    dreamwork_cli.write( "@" .. tostring( package.version ), colors.value )
end

--- Prints the rows as aligned columns: the tree, the status and the origin, the errors of failed packages below them.
---
---@param rows dreamwork.std.ascii.art.TreeLine[]
local function print_rows( rows )
    local row_count = #rows

    local id_width, status_width = 0, 0

    for index = 1, row_count, 1 do
        local row = rows[ index ]

        ---@type dreamwork.Package
        local package = row.node

        -- each `tree_` prefix on the scheme is 4 columns; the root's two spaces sit on every line
        local width = row.depth * 4 + #package.id
        if width > id_width then
            id_width = width
        end

        local status_length = #package.status
        if status_length > status_width then
            status_width = status_length
        end
    end

    for index = 1, row_count, 1 do
        local row = rows[ index ]

        ---@type dreamwork.Package
        local package = row.node

        local status = package.status
        local width = row.depth * 4 + #package.id

        -- a new root, separated from the previous tree when it has dependencies
        if index ~= 1 and row.depth == 0 and rows[ index - 1 ].depth ~= 0 then
            dreamwork_cli.write( "\n" )
        end

        dreamwork_cli.write( row.prefix, colors.description )
        write_id( package )
        dreamwork_cli.write( string_rep( " ", id_width - width + 3 ) )

        local mark = row.mark
        if mark ~= nil then
            dreamwork_cli.write( "(" .. mark .. ")\n", mark == "circular" and colors.error or colors.description )
        else
            dreamwork_cli.write( status .. string_rep( " ", status_width - #status + 3 ), status_color( package ) )
            dreamwork_cli.write( origin_of( package ) .. "\n", colors.description )

            local error = package.error
            if status == "failed" and error ~= nil then
                dreamwork_cli.write( string_rep( " ", 6 + row.depth * 4 ) .. tostring( error.message ) .. "\n", colors.error )
            end
        end
    end
end

packages_group:register( "ls", {
    description = "Shows the packages as trees of their dependencies like `npm ls`, the roots are the packages nothing depends on, repeated packages are marked `(deduped)`. Dependencies are known once a package is loaded.",
    usage = "[name[@range]]",
    on_run = function( _, args )
        local spec = args[ 1 ]
        if spec ~= nil then
            local package = find( spec )
            if package == nil then
                cli_error( "Package '%s' is not installed.", spec )
                return
            end

            local rows = art_tree( { package }, package_children )
            print_rows( rows )
            return
        end

        local list, count = dreamwork.loader.getPackages()

        if count == 0 then
            cli_print( colors.description, "No packages are installed." )
            return
        end

        ---@type table<string, integer>
        local statuses = {}

        ---@type dreamwork.Package[]
        local roots = {}

        for index = 1, count, 1 do
            local package = list[ index ]

            local status = package.status
            statuses[ status ] = (statuses[ status ] or 0) + 1

            local _, dependent_count = package:getDependents()
            if dependent_count == 0 then
                roots[ #roots + 1 ] = package
            end
        end

        local rows = art_tree( roots, package_children )

        ---@type string[]
        local summary = {}

        for index = 1, #STATUS_ORDER, 1 do
            local status = STATUS_ORDER[ index ]
            local status_count = statuses[ status ]
            if status_count ~= nil then
                summary[ #summary + 1 ] = string_format( "%d %s", status_count, status )
            end
        end

        cli_printHeader( { table_concat( summary, ", " ) }, string_format( count == 1 and "%d package" or "%d packages", count ) )
        print_rows( rows )
    end,
    on_type = complete_packages()
} )

-- the other commands manage the packages, the client only receives them from the server
if std.LUA_CLIENT then return end

packages_group:register( "list", {
    description = "Lists the packages, where they come from and their status.",
    on_run = function()
        local list, count = dreamwork.loader.getPackages()

        cli_printHeader( { string_format( "%d package(s)", count ) }, "Packages" )

        for index = 1, count, 1 do
            local package = list[ index ]

            dreamwork_cli.write( "  " .. package.id, colors.name )
            dreamwork_cli.write( "  " .. package.status, status_color( package ) )
            dreamwork_cli.write( "  " .. origin_of( package ) .. "\n", colors.description )
        end
    end
} )

packages_group:register( "install", {
    description = "Installs the package from its repository and loads it: the default branch without a range, the newest version tag that matches the range otherwise.",
    usage = "<user/repo[@range]|https://github.com/user/repo[@range]>",
    ---@async
    on_run = function( _, args )
        local spec = args[ 1 ]
        if spec == nil then
            cli_error( "Missing <user/repo>." )
            return
        end

        local success, package, is_loaded = pcall( dreamwork.loader.install, spec )
        if not success then
            cli_error( "%s", tostring( package ) )
            return
        end

        ---@cast package dreamwork.Package

        if is_loaded then
            cli_print( colors.name, "Installed %s.", describe( package ) )
        elseif package.status == "failed" then
            cli_error( "Installed %s.", describe( package ) )
        else
            cli_print( colors.name, "Installed %s, it does not run in this realm.", describe( package ) )
        end
    end
} )

packages_group:register( "remove", {
    description = "Unloads the package and the packages that depend on it, deletes the downloaded archive.",
    usage = "<name[@range]>",
    on_run = function( _, args )
        local spec = args[ 1 ]
        if spec == nil then
            cli_error( "Missing <name>." )
            return
        end

        local package = find( spec )
        if package == nil then
            cli_error( "Package '%s' is not installed.", spec )
            return
        end

        local success, message = pcall( dreamwork.loader.uninstall, package )
        if not success then
            cli_error( "%s", tostring( message ) )
            return
        end

        cli_print( colors.name, "Removed %s.", package.id )
    end,
    on_type = complete_packages( is_removable )
} )

---@param package dreamwork.Package
---@return boolean
local function is_exportable( package )
    return package.origin ~= "server"
end

packages_group:register( "export", {
    description = "Packs the package into '/garrysmod/data/dreamwork/export': 'gma' (default) is a Workshop addon with the archive at 'data_static/packages/{name}-{version}.zip.dat', 'zip' is the archive itself saved as '.zip.dat'.",
    usage = "<name[@range]> [gma|zip]",
    ---@async
    on_run = function( _, args )
        local spec, format = args[ 1 ], args[ 2 ] or "gma"
        if spec == nil then
            cli_error( "Missing <name>." )
            return
        end

        if format ~= "gma" and format ~= "zip" then
            cli_error( "Unknown format '%s', expected 'gma' or 'zip'.", format )
            return
        end

        local package = find( spec )
        if package == nil then
            cli_error( "Package '%s' is not installed.", spec )
            return
        end

        local success, vfs_path = pcall( dreamwork.loader.export, package, format )
        if not success then
            cli_error( "%s", tostring( vfs_path ) )
            return
        end

        cli_print( colors.name, "Exported %s to '%s'.", package.id, vfs_path )
    end,
    on_type = function( _, _, argument_string )
        local typed, rest = cli_shift( argument_string )
        if rest == nil then
            return complete_packages( is_exportable )( nil, nil, argument_string )
        end

        local format, tail = cli_shift( rest )
        if tail ~= nil then
            return nil
        end

        return cli_complete( format, { "gma", "zip" }, nil, typed .. " " )
    end
} )

---@param package dreamwork.Package
---@async
local function upgrade( package )
    local success, newest, is_upgraded = pcall( dreamwork.loader.upgrade, package )
    if not success then
        cli_error( "%s: %s", package.id, tostring( newest ) )
    elseif is_upgraded then
        ---@cast newest dreamwork.Package
        cli_print( colors.name, "Upgraded %s to %s.", package.id, describe( newest ) )
    else
        cli_print( colors.description, "%s is up to date.", package.id )
    end
end

packages_group:register( "upgrade", {
    description = "Upgrades the package, or every package installed from a repository, to the newest version.",
    usage = "[name[@range]]",
    ---@async
    on_run = function( _, args )
        local spec = args[ 1 ]
        if spec ~= nil then
            local package = find( spec )
            if package == nil then
                cli_error( "Package '%s' is not installed.", spec )
                return
            end

            upgrade( package )
            return
        end

        local list, count = dreamwork.loader.getPackages()

        ---@type dreamwork.Package[]
        local upgradable = {}

        for index = 1, count, 1 do
            local package = list[ index ]
            if is_upgradable( package ) then
                upgradable[ #upgradable + 1 ] = package
            end
        end

        if #upgradable == 0 then
            cli_print( colors.description, "No packages are installed from repositories." )
            return
        end

        for index = 1, #upgradable, 1 do
            local package = upgradable[ index ]

            -- an earlier upgrade could have replaced it (two versions of the same repository)
            if dreamwork.loader.findPackage( package.name, tostring( package.version ) ) == package then
                upgrade( package )
            end
        end
    end,
    on_type = complete_packages( is_upgradable )
} )
