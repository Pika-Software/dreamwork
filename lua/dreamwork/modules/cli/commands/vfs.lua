local dreamwork_cli = dreamwork.cli
local std = dreamwork.std

local cli_write = dreamwork_cli.write
local cli_error = dreamwork_cli.error
local cli_printBox = dreamwork_cli.printBox
local cli_printHeader = dreamwork_cli.printHeader
local cli_shift = dreamwork_cli.shift
local cli_readNumber = dreamwork_cli.readNumber
local cli_toVFSPath = dreamwork_cli.toVFSPath
local cli_formatBytes = dreamwork_cli.formatBytes
local cli_parseArguments = dreamwork_cli.parseArguments
local cli_completeVFSPath = dreamwork_cli.completeVFSPath

local colors = dreamwork_cli.colors

local dreamwork_vfs = dreamwork.vfs
local vfs_size = dreamwork_vfs.size
local vfs_search = dreamwork_vfs.search
local vfs_getInfo = dreamwork_vfs.getInfo
local vfs_isExists = dreamwork_vfs.isExists
local vfs_readFile = dreamwork_vfs.readFile
local vfs_writeFile = dreamwork_vfs.writeFile
local vfs_deleteFile = dreamwork_vfs.deleteFile
local vfs_getWatchCount = dreamwork_vfs.getWatchCount

local path = std.path
local path_getExtension = path.getExtension

local string = std.string
local string_sub = string.sub
local string_diff = string.diff
local string_byte = string.byte
local string_match = string.match
local string_format = string.format
local string_escape = string.escape

local futures = std.futures
local futures_sleep = futures.sleep

-- `dreamwork.vfs` functions are called with `stack_level` 1, so their errors blame `pcall` and have no position
local pcall = std.pcall

local color_scheme = std.color.Scheme

local COLOR_BRANCH = color_scheme.suva_gray
local COLOR_FILE = color_scheme.light_gray
local COLOR_DIRECTORY = color_scheme.sandstone
local COLOR_MOUNT = color_scheme.dreamwork_info
local COLOR_VIRTUAL = color_scheme.suva_gray
local COLOR_WATCHED = color_scheme.dreamwork_warn


--- [SHARED AND MENU]
---
--- The virtual file system commands, `dreamwork_sci vfs <command>`.
---
local vfs_group = dreamwork_cli.group( "vfs", "Virtual file system commands." )

--- Completes the first argument as a path, a leading quote is kept.
---
---@param argument_string string
---@return string[] | nil
local function complete_first_path( _, _, argument_string )
    local typed, rest = cli_shift( argument_string )
    if rest ~= nil then
        return nil
    end

    if string_byte( typed, 1, 1 ) ~= 0x22 --[[ " ]] then
        return cli_completeVFSPath( typed )
    end

    local suggestions = cli_completeVFSPath( string_sub( typed, 2 ) )
    if suggestions == nil then
        return nil
    end

    for index = 1, #suggestions, 1 do
        suggestions[ index ] = "\"" .. suggestions[ index ]
    end

    return suggestions
end

do

    --- The tree is collected first, so the header with the node count can go on top.
    ---
    ---@type ( string | dreamwork.std.Color | false )[]
    local segments = {}
    local segment_count = 0

    ---@param text string
    ---@param color dreamwork.std.Color?
    local function emit( text, color )
        segments[ segment_count + 1 ] = text
        segments[ segment_count + 2 ] = color or false
        segment_count = segment_count + 2
    end

    local function flush()
        for index = 1, segment_count, 2 do
            local color = segments[ index + 1 ]
            if color == false then
                ---@diagnostic disable-next-line: param-type-mismatch
                cli_write( segments[ index ] )
            else
                ---@diagnostic disable-next-line: param-type-mismatch
                cli_write( segments[ index ], color )
            end

            segments[ index ], segments[ index + 1 ] = nil, nil
        end

        segment_count = 0
    end

    ---@param vfs_path string
    ---@param name string
    ---@return string
    local function child_path( vfs_path, name )
        if vfs_path == "/" then
            return "/" .. name
        end

        return vfs_path .. "/" .. name
    end

    -- statistics of the printed tree, reset on every run
    local directory_count, file_count, total_size, collapsed_count, mount_count, watched_count = 0, 0, 0, 0, 0, 0

    ---@param info dreamwork.vfs.Info
    ---@return string
    local function format_access( info )
        if info.writable then
            return "rw"
        elseif info.deletable then
            return "rd"
        else
            return "ro"
        end
    end

    ---@param vfs_path string
    ---@param label string The name of the file or directory, or the path for the first printed one.
    ---@param is_directory boolean
    local function print_node( vfs_path, label, is_directory )
        if is_directory then
            if vfs_path ~= "/" then
                label = label .. "/"
            end

            emit( label, COLOR_DIRECTORY )
        else
            emit( label, COLOR_FILE )

            -- directories are not measured, their size is recursive
            local size = vfs_size( vfs_path )
            total_size = total_size + size

            emit( " " .. cli_formatBytes( size ), COLOR_BRANCH )
        end

        local info = vfs_getInfo( vfs_path )
        if info ~= nil then
            local storage = info.storage
            if storage == "memory" then
                emit( " [memory]", COLOR_VIRTUAL )
            elseif storage == "none" then
                emit( " [intermediate]", COLOR_VIRTUAL )
            elseif info.is_mount_root then
                mount_count = mount_count + 1

                local search_directory = info.search_directory
                if search_directory ~= "" then
                    search_directory = ":" .. search_directory
                end

                emit( string_format( " ['%s'%s][%s]", info.search_path, search_directory, format_access( info ) ), COLOR_MOUNT )
            end
        end

        local watch_count = vfs_getWatchCount( vfs_path )
        if watch_count ~= 0 then
            watched_count = watched_count + 1
            emit( string_format( " [watched x%d]", watch_count ), COLOR_WATCHED )
        end

        emit( "\n" )
    end

    --- Prints the children of the directory, directories go first.
    ---
    ---@param vfs_path string
    ---@param prefix string
    ---@param depth integer
    ---@param max_depth integer
    local function print_children( vfs_path, prefix, depth, max_depth )
        local files, child_file_count, directories, child_directory_count = vfs_search( vfs_path )

        local child_count = child_directory_count + child_file_count
        if child_count == 0 then
            return
        end

        if depth >= max_depth then
            collapsed_count = collapsed_count + child_count
            emit( string_format( "%s└─ ... %d more\n", prefix, child_count ), COLOR_BRANCH )
            return
        end

        directory_count = directory_count + child_directory_count
        file_count = file_count + child_file_count

        for index = 1, child_count, 1 do
            local is_last = index == child_count
            local is_directory = index <= child_directory_count

            local name
            if is_directory then
                name = directories[ index ]
            else
                name = files[ index - child_directory_count ]
            end

            emit( prefix .. (is_last and "└─ " or "├─ "), COLOR_BRANCH )

            local child_vfs_path = child_path( vfs_path, name )
            print_node( child_vfs_path, name, is_directory )

            if is_directory then
                futures_sleep( 0.05 )
                print_children( child_vfs_path, prefix .. (is_last and "   " or "│  "), depth + 1, max_depth )
            end
        end
    end

    --- Describes the mount that provides the path.
    ---
    ---@param vfs_path string
    ---@return string
    local function describe_mount( vfs_path )
        local info = vfs_getInfo( vfs_path )
        if info == nil or info.storage ~= "mount" then
            if info ~= nil and info.storage == "memory" then
                return "Mount: none, kept in memory"
            end

            return "Mount: none, intermediate directory"
        end

        local search_directory = info.search_directory
        if search_directory ~= nil and search_directory ~= "" then
            search_directory = ":" .. search_directory
        else
            search_directory = ""
        end

        return string_format( "Mount: '%s' -> '%s'%s [%s]", info.mount_path, info.search_path, search_directory, format_access( info ) )
    end

    vfs_group:register( "tree", {
        description = "Prints the tree of the virtual file system with mounts and watches.",
        usage = "[path] [max_depth]",
        on_run = function( _, _, argument_string )
            local args = cli_parseArguments( argument_string )

            local path_to = args[ 1 ]
            local vfs_path = path_to == nil and "/" or cli_toVFSPath( path_to )

            local max_depth = cli_readNumber( args, 2, 2, 0, 255, true )
            if max_depth == nil then return end

            local exists, is_directory = vfs_isExists( vfs_path )
            if not exists then
                cli_error( "'%s' does not exist.", vfs_path )
                return
            end

            -- a failed search could leave the previous tree behind
            segment_count = 0
            directory_count, file_count, total_size, collapsed_count, mount_count, watched_count = 0, 0, 0, 0, 0, 0

            print_node( vfs_path, vfs_path, is_directory )

            if is_directory then
                print_children( vfs_path, "", 0, max_depth )
            else
                file_count = 1
            end

            local depth_line = string_format( "Max depth %d", max_depth )
            if collapsed_count ~= 0 then
                depth_line = depth_line .. string_format( ", %d more not expanded", collapsed_count )
            end

            if mount_count ~= 0 then
                depth_line = depth_line .. string_format( ", %d mounts", mount_count )
            end

            if watched_count ~= 0 then
                depth_line = depth_line .. string_format( ", %d watched", watched_count )
            end

            cli_printHeader( {
                describe_mount( vfs_path ),
                string_format( "%d directories, %d files, %s", directory_count, file_count, cli_formatBytes( total_size ) ),
                depth_line
            }, vfs_path )

            flush()
        end,
        on_type = complete_first_path
    } )

end

vfs_group:register( "read", {
    description = "Prints the content of the file, like 'cat'.",
    usage = "<path> [max_bytes]",
    on_run = function( _, _, argument_string )
        local args = cli_parseArguments( argument_string )

        local path_to = args[ 1 ]
        if path_to == nil then
            cli_error( "The path is required, see '%s help preview'.", vfs_group.path )
            return
        end

        local max_bytes = cli_readNumber( args, 2, 16384, 1, 16777216, true )
        if max_bytes == nil then return end

        local vfs_path = cli_toVFSPath( path_to )

        local exists, is_directory = vfs_isExists( vfs_path )
        if not exists then
            cli_error( "'%s' does not exist.", vfs_path )
            return
        elseif is_directory then
            cli_error( "'%s' is a directory, see '%s help tree'.", vfs_path, vfs_group.path )
            return
        end

        local success, data = pcall( vfs_readFile, vfs_path, false, 1 )
        if not success then
            cli_error( "%s", data )
            return
        end

        ---@cast data string

        local data_length = #data

        local shown_length = data_length
        if shown_length > max_bytes then
            shown_length = max_bytes
        end

        local size_line
        if shown_length == data_length then
            size_line = string_format( "%d bytes", data_length )
        else
            size_line = string_format( "%d of %d bytes shown", shown_length, data_length )
        end

        cli_printHeader( { size_line }, vfs_path )

        cli_write( "```" .. path_getExtension( vfs_path ) .. "\n", COLOR_BRANCH )
        cli_write( string_escape( data, false ), colors.value )

        cli_write( "\n```", COLOR_BRANCH )

        if shown_length ~= 0 and string_byte( data, shown_length, shown_length ) ~= 0x0A --[[ \n ]] then
            cli_write( "\n" )
        end
    end,
    on_type = complete_first_path
} )

do

    local DATA_PATH = "/garrysmod/data"
    local DATA_PREFIX = DATA_PATH .. "/"
    local DATA_PREFIX_LENGTH = #DATA_PREFIX

    --- The maximal size of the previous content that is diffed, the diff is O(ND), so big rewrites are slow.
    local DIFF_LIMIT = 65536

    --- Checks that the path is inside of `/garrysmod/data/`, and that the closest existing node comes from the `DATA` search path,
    --- since mounts nested inside of `/garrysmod/data/` can point anywhere.
    ---
    ---@param vfs_path string The normalized path.
    ---@return boolean allowed
    local function check_data_path( vfs_path )
        if string_sub( vfs_path, 1, DATA_PREFIX_LENGTH ) ~= DATA_PREFIX then
            cli_error( "'%s' is restricted, only files inside of '%s' are allowed.", vfs_path, DATA_PREFIX )
            return false
        end

        local existing_path = vfs_path

        ::existing_lookup::

        local info = vfs_getInfo( existing_path )
        if info == nil then
            existing_path = string_match( existing_path, "^(.+)/[^/]*$" )
            if existing_path ~= nil then
                goto existing_lookup
            end
        end

        if info == nil or info.search_path ~= "DATA" then
            cli_error( "'%s' is restricted, it is not provided by the 'DATA' search path.", vfs_path )
            return false
        end

        return true
    end

    ---@type table<dreamwork.std.string.DifferenceType, dreamwork.std.Color>
    local diff_colors = {
        [ 0 ] = colors.value,
        [ 1 ] = color_scheme.green,
        [ 2 ] = color_scheme.red
    }

    vfs_group:register( "write", {
        description = "Writes the file, replaces the existing one, only inside of '" .. DATA_PREFIX .. "'.",
        usage = "<path> <content>",
        on_run = function( _, _, argument_string )
            local args, arg_count = cli_parseArguments( argument_string )
            if arg_count < 2 then
                cli_error( "The path and the content are required, see '%s help write'.", vfs_group.path )
                return
            elseif arg_count > 2 then
                cli_error( "Too many arguments, put the content in double quotes, '\\n' is a new line." )
                return
            end

            local vfs_path = cli_toVFSPath( args[ 1 ] )
            if not check_data_path( vfs_path ) then return end

            local exists, is_directory = vfs_isExists( vfs_path )
            if is_directory then
                cli_error( "'%s' is a directory.", vfs_path )
                return
            end

            -- a new file is diffed against an empty string
            ---@type string | nil
            local old_content = ""

            if exists then
                local read_success, data = pcall( vfs_readFile, vfs_path, false, 1 )
                old_content = read_success and data or nil
            end

            local content = args[ 2 ]

            local success, message = pcall( vfs_writeFile, vfs_path, content, false, 1 )
            if not success then
                cli_error( "%s", message )
                return
            end

            local header = { string_format( "%s, %d bytes", exists and "replaced" or "created", #content ) }

            if old_content == nil then
                header[ 2 ] = "The previous content could not be read, no diff."
            elseif #old_content > DIFF_LIMIT then
                header[ 2 ] = string_format( "The previous content is larger than %d bytes, no diff.", DIFF_LIMIT )
            else
                cli_printHeader( header, vfs_path )

                cli_write( "```" .. path_getExtension( vfs_path ) .. "\n", COLOR_BRANCH )

                local diff_ops, diff_op_count = string_diff( old_content, content )

                for i = 1, diff_op_count, 1 do
                    local diff_op = diff_ops[ i ]
                    local diff_type = diff_op.type
                    cli_write( string_escape( string_sub( diff_op.source, diff_op.start_position, diff_op.end_position ), diff_type ~= 0 ), diff_colors[ diff_type ] )
                end

                cli_write( "\n```\n", COLOR_BRANCH )
                return
            end

            cli_printBox( header, vfs_path )
        end,
        on_type = complete_first_path
    } )

    vfs_group:register( "delete", {
        description = "Deletes the file, only inside of '" .. DATA_PREFIX .. "'.",
        usage = "<path>",
        on_run = function( _, _, argument_string )
            local path_to = cli_parseArguments( argument_string )[ 1 ]
            if path_to == nil then
                cli_error( "The path is required, see '%s help delete'.", vfs_group.path )
                return
            end

            local vfs_path = cli_toVFSPath( path_to )
            if not check_data_path( vfs_path ) then return end

            local exists, is_directory = vfs_isExists( vfs_path )
            if not exists then
                cli_error( "'%s' does not exist.", vfs_path )
                return
            elseif is_directory then
                cli_error( "'%s' is a directory, only files can be deleted.", vfs_path )
                return
            end

            local read_success, old_content = pcall( vfs_readFile, vfs_path, false, 1 )

            local success, message = pcall( vfs_deleteFile, vfs_path, false, 1 )
            if not success then
                cli_error( "%s", message )
                return
            end

            if not read_success then
                cli_printBox( { "deleted", "The content could not be read, no diff." }, vfs_path )
                return
            end

            ---@cast old_content string

            local old_length = #old_content

            local header = { string_format( "deleted, %d bytes", old_length ) }

            if old_length > DIFF_LIMIT then
                header[ 2 ] = string_format( "The content is larger than %d bytes, no diff.", DIFF_LIMIT )
                cli_printBox( header, vfs_path )
                return
            end

            -- the deleted file is diffed against an empty string
            cli_printHeader( header, vfs_path )

            cli_write( "```" .. path_getExtension( vfs_path ) .. "\n", COLOR_BRANCH )

            local diff_ops, diff_op_count = string_diff( old_content, "" )

            for i = 1, diff_op_count, 1 do
                local diff_op = diff_ops[ i ]
                local diff_type = diff_op.type
                cli_write( string_escape( string_sub( diff_op.source, diff_op.start_position, diff_op.end_position ), diff_type ~= 0 ), diff_colors[ diff_type ] )
            end

            cli_write( "\n```\n", COLOR_BRANCH )
        end,
        on_type = complete_first_path
    } )

end
