local engine = dreamwork.engine
local vfs = dreamwork.vfs
local std = dreamwork.std
local cli = dreamwork.cli

local raw = std.raw
local raw_tonumber = raw.tonumber

local string = std.string
local string_sub = string.sub
local string_len = string.len
local string_byte = string.byte
local string_match = string.match
local string_format = string.format

local path = std.path
local path_normalize = path.normalize

local pcall = std.pcall

do

    local engine_consoleMessage = engine.consoleMessage
    local engine_consoleMessageColored = engine.consoleMessageColored

    local vfs_search = vfs.search

    local vfs_isExists = vfs.isExists
    local vfs_getInfo = vfs.getInfo
    local vfs_getWatchCount = vfs.getWatchCount

    local color_scheme = std.color.Scheme

    local COLOR_BRANCH = color_scheme.suva_gray
    local COLOR_FILE = color_scheme.light_gray
    local COLOR_DIRECTORY = color_scheme.sandstone
    local COLOR_MOUNT = color_scheme.dreamwork_info
    local COLOR_VIRTUAL = color_scheme.suva_gray
    local COLOR_WATCHED = color_scheme.dreamwork_warn

    --- The maximal number of suggested paths.
    local SUGGESTION_LIMIT = 64

    ---@param vfs_path string
    ---@param name string
    ---@return string
    local function child_path( vfs_path, name )
        if vfs_path == "/" then
            return "/" .. name
        end

        return vfs_path .. "/" .. name
    end

    ---@param vfs_path string
    ---@param label string The name of the file or directory, or the path for the first printed one.
    ---@param is_directory boolean
    local function print_node( vfs_path, label, is_directory )
        if is_directory then
            if vfs_path ~= "/" then
                label = label .. "/"
            end

            engine_consoleMessageColored( label, COLOR_DIRECTORY )
        else
            engine_consoleMessageColored( label, COLOR_FILE )
        end

        local info = vfs_getInfo( vfs_path )
        if info ~= nil then
            if info.is_virtual then
                engine_consoleMessageColored( " [virtual]", COLOR_VIRTUAL )
            elseif info.is_mount_root then
                local search_directory = info.search_directory
                if search_directory ~= "" then
                    search_directory = ":" .. search_directory
                end

                local access
                if info.writable then
                    access = "rw"
                elseif info.deletable then
                    access = "rd"
                else
                    access = "ro"
                end

                engine_consoleMessageColored( string_format( " ['%s'%s][%s]", info.search_path, search_directory, access ), COLOR_MOUNT )
            end
        end

        local watch_count = vfs_getWatchCount( vfs_path )
        if watch_count ~= 0 then
            engine_consoleMessageColored( string_format( " [watched x%d]", watch_count ), COLOR_WATCHED )
        end

        engine_consoleMessage( "\n" )
    end

    --- Prints the children of the directory, directories go first, the number of printed files and directories is returned for the summary.
    ---
    ---@param vfs_path string
    ---@param prefix string
    ---@param depth integer
    ---@param max_depth integer
    ---@return integer node_count
    local function print_children( vfs_path, prefix, depth, max_depth )
        local files, file_count, directories, directory_count = vfs_search( vfs_path )

        local child_count = directory_count + file_count
        if child_count == 0 then
            return 0
        end

        if depth >= max_depth then
            engine_consoleMessageColored( string_format( "%s└─ ... %d more\n", prefix, child_count ), COLOR_BRANCH )
            return 0
        end

        local node_count = child_count

        for index = 1, child_count, 1 do
            local is_last = index == child_count
            local is_directory = index <= directory_count

            local name
            if is_directory then
                name = directories[ index ]
            else
                name = files[ index - directory_count ]
            end

            engine_consoleMessageColored( prefix .. (is_last and "└─ " or "├─ "), COLOR_BRANCH )

            local child_vfs_path = child_path( vfs_path, name )
            print_node( child_vfs_path, name, is_directory )

            if is_directory then
                node_count = node_count + print_children( child_vfs_path, prefix .. (is_last and "   " or "│  "), depth + 1, max_depth )
            end
        end

        return node_count
    end

    --- Returns the absolute normalized path of the typed path, paths without the leading slash start at the root.
    ---
    ---@param path_to string
    ---@return string vfs_path
    local function to_vfs_path( path_to )
        if string_byte( path_to, 1, 1 ) ~= 0x2F --[[ / ]] then
            path_to = "/" .. path_to
        end

        return path_normalize( path_to, false )
    end

    cli.register( "vfs_preview", {
        description = "Prints the tree of the virtual file system with mounts and watches.",
        usage = "[path] [max_depth]",
        on_run = function( args )
            local vfs_path = "/"

            local path_to = args[ 1 ]
            if path_to ~= nil then
                vfs_path = to_vfs_path( path_to )
            end

            local max_depth = 2

            local depth_string = args[ 2 ]
            if depth_string ~= nil then
                local depth_value = raw_tonumber( depth_string, 10 )
                if depth_value == nil or depth_value < 0 or depth_value ~= depth_value then
                    engine_consoleMessageColored( string_format( "'%s' is not a valid depth.\n", depth_string ), COLOR_WATCHED )
                    return
                end

                max_depth = depth_value
            end

            local exists, is_directory = vfs_isExists( vfs_path )
            if not exists then
                engine_consoleMessageColored( string_format( "'%s' does not exist.\n", vfs_path ), COLOR_WATCHED )
                return
            end

            print_node( vfs_path, vfs_path, is_directory )

            local node_count = 1
            if is_directory then
                node_count = node_count + print_children( vfs_path, "", 0, max_depth )
            end

            engine_consoleMessageColored( string_format( "%d nodes printed\n", node_count ), COLOR_BRANCH )
        end,
        on_type = function( _, argument_string )
            -- only the path is completed
            if string_match( argument_string, "%s" ) ~= nil then
                return nil
            end

            local typed_directory, name_prefix = string_match( argument_string, "^(.*/)([^/]*)$" )
            if typed_directory == nil then
                typed_directory, name_prefix = "", argument_string
            end

            local success, files, file_count, directories, directory_count = pcall( vfs_search, to_vfs_path( typed_directory ) )
            if not success then
                return nil
            end

            local prefix_length = string_len( name_prefix )

            ---@type string[]
            local suggestions = {}
            local suggestion_count = 0

            for index = 1, directory_count, 1 do
                local name = directories[ index ]
                if string_sub( name, 1, prefix_length ) == name_prefix then
                    suggestion_count = suggestion_count + 1
                    suggestions[ suggestion_count ] = typed_directory .. name .. "/"

                    if suggestion_count == SUGGESTION_LIMIT then
                        return suggestions
                    end
                end
            end

            for index = 1, file_count, 1 do
                local name = files[ index ]
                if string_sub( name, 1, prefix_length ) == name_prefix then
                    suggestion_count = suggestion_count + 1
                    suggestions[ suggestion_count ] = typed_directory .. name

                    if suggestion_count == SUGGESTION_LIMIT then
                        return suggestions
                    end
                end
            end

            return suggestions
        end
    } )

end
