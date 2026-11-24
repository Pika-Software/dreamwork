---@diagnostic disable: inject-field

local dreamwork_engine = dreamwork.engine
local engine_hook = dreamwork_engine.hook

local detour = dreamwork.detour

local engine_gui = dreamwork_engine.gui
local gui_panelCreate = engine_gui.panelCreate
local gui_panelIsValid = engine_gui.panelIsValid

local vfs = dreamwork.vfs
local vfs_isFile = vfs.isFile

---@class dreamwork.std
local std = dreamwork.std

local debug = std.debug
local debug_fempty = debug.fempty

local math = std.math
local math_clamp = math.clamp
local math_min = math.min

local ascii = std.ascii
local ascii_isAlnum = ascii.isAlnum

local string = std.string
local string_byte = string.byte
local string_match = string.match
local string_sub = string.sub
local string_trim = string.trim

local path = std.path
local path_join = path.join
local path_getDirectory = path.getDirectory
local path_getExtension = path.getExtension
local path_splitExtension = path.splitExtension
local path_normalizeSlashes = path.normalizeSlashes

local table = std.table
local table_clearKeys = table.clearKeys
local table_clearIndexes = table.clearIndexes

local console = std.console

local Event = std.Event

---@class dreamwork.std.menu
local menu = std.menu


local get_default_html = GetDefaultLoadingHTML or debug_fempty
local get_engine_file_count = NumDownloadables or debug_fempty
local get_engine_files = GetDownloadables or debug_fempty
local get_engine_status = GetLoadStatus or debug_fempty
local cancel_loading = CancelLoading or debug_fempty


--- FastDL / ServerDL: `12/340 - materials/concrete/floor.vtf is downloading`.
local FASTDL_FILE = "%w+/%w+ %- (.+) is downloading"

--- Workshop: `Downloading 'name' via Workshop`.
local WORKSHOP_FILE = "Downloading '(.-)' via Workshop"

--- Legacy FastDL: `Downloading materials/concrete/floor.vtf`.
local LEGACY_FILE = "Downloading (.+)"

--- Files the server listed that are not on disk yet.
---
---@type string[]
local pending = {}

--- Files from the last list that are already on disk.
---
---@type string[]
local downloaded = {}

--- File paths already reported through `FileDownloaded` during the current connection.
---
---@type table<string, boolean>
local known_downloaded = {}

local pending_count = 0
local downloaded_count = 0

--- How many pending files are checked against the disk per tick.
local PENDING_CHECKS_PER_TICK = 32

--- The next `pending` index to check, walks down and wraps around to the end.
local pending_cursor = 0

--- The engine file count the lists were built from, `0` before the first list.
local total_count = 0

--- The last engine file count seen, so an unchanged count is not scanned again.
---
---@type integer | nil
local seen_count = nil

--- The last status text announced, so the same line is not announced again.
---
---@type string | nil
local seen_status = nil


--- [MENU]
---
--- The game's loading screen while connecting to a server.
---
--- The engine only reports a status string and a flat list of files. This module
--- cleans those up, notices which files are already on disk, and announces the changes.
---
--- ```lua
--- print( std.menu.loading.getDefaultHTML() ) -- asset://garrysmod/html/loading.html
--- print( std.menu.loading.active ) -- false
--- ```
---
---@class dreamwork.std.menu.loading
---@field active boolean `true` while the loading screen is open.
local loading = menu.loading or { active = false }
menu.loading = loading

--- [MENU]
---
--- Called when the loading screen opens.
---
local Started = Event( "menu.loading.Started" )
loading.Started = Started

--- [MENU]
---
--- Called when the loading screen closes.
---
local Finished = Event( "menu.loading.Finished" )
loading.Finished = Finished

--- [MENU]
---
--- Called when the engine status text changes.
---
--- Arguments: `status: string`.
---
local StatusChanged = Event( "menu.loading.StatusChanged" )
loading.StatusChanged = StatusChanged

--- [MENU]
---
--- Called when the status text names a file that started downloading.
---
--- Arguments: `file_name: string`.
---
local FileDownloading = Event( "menu.loading.FileDownloading" )
loading.FileDownloading = FileDownloading

--- [MENU]
---
--- Called when a listed file is found on disk.
---
--- Each file is reported once per connection, a file that was already there is reported when the list is first scanned.
---
--- Arguments: `file_path: string`.
---
local FileDownloaded = Event( "menu.loading.FileDownloaded" )
loading.FileDownloaded = FileDownloaded

--- [MENU]
---
--- Called when the number of listed files still missing from disk changes.
---
--- Arguments: `remaining: integer`, `total: integer`.
---
local FilesChanged = Event( "menu.loading.FilesChanged" )
loading.FilesChanged = FilesChanged

--- Drops a trailing `.bz2` or `.ztmp`, including one sitting in front of the rest of a status line.
---
--- `models/foo.vtf.bz2` becomes `models/foo.vtf`.
--- `models/foo.vtf.bz2 is downloading` becomes `models/foo.vtf is downloading`.
---
---@param text string
---@return string
local function strip_download_suffix( text )
    while true do
        local without, extension = path_splitExtension( text, false )

        local cut

        if string_sub( extension, 1, 3 ) == "bz2" then
            cut = 3
        elseif string_sub( extension, 1, 4 ) == "ztmp" then
            cut = 4
        else
            return text
        end

        local next_byte = string_byte( extension, cut + 1 )
        if next_byte ~= nil and ascii_isAlnum( next_byte ) then
            return text
        end

        text = without .. string_sub( extension, cut + 1 )
    end
end

---@param file_path string
---@return string file_path
local function normalize_file( file_path )
    file_path = strip_download_suffix( path_normalizeSlashes( file_path ) )

    -- workshop downloads are named `id.gma` and stored at `cache/workshop/id.gma`
    if path_getDirectory( file_path ) == nil then
        local extension = path_getExtension( file_path, false )
        if extension == "gma" or extension == "gmad" then
            return path_join( "cache/workshop", file_path )
        end
    end

    return file_path
end

---@param raw_files string[]
---@return string[] files
---@return integer file_count
local function normalize_files( raw_files )
    local file_count = #raw_files
    local files = {}

    for index = 1, file_count do
        files[ index ] = normalize_file( raw_files[ index ] )
    end

    return files, file_count
end

--- Pulls the downloaded file name out of a status line, when the line is about a download.
---
---@param status string
---@return string | nil file_name
local function file_from_status( status )
    local file_name = string_match( status, FASTDL_FILE )
        or string_match( status, WORKSHOP_FILE )
        or string_match( status, LEGACY_FILE )

    if file_name == "" then
        return nil
    end

    return file_name
end

---@param file_path string
local function mark_downloaded( file_path )
    downloaded_count = downloaded_count + 1
    downloaded[ downloaded_count ] = file_path

    if known_downloaded[ file_path ] == nil then
        known_downloaded[ file_path ] = true
        FileDownloaded:call( file_path )
    end
end

--- Rebuilds both lists from a fresh engine list.
---
--- Files already reported during this connection are trusted to still be on disk.
---
---@param files string[]
---@param file_count integer
---@param total integer
local function adopt_files( files, file_count, total )
    table_clearIndexes( pending, pending_count )
    table_clearIndexes( downloaded, downloaded_count )

    pending_count = 0
    downloaded_count = 0

    for index = 1, file_count do
        local file_path = files[ index ]

        if known_downloaded[ file_path ] ~= nil or vfs_isFile( "/game/" .. file_path ) then
            mark_downloaded( file_path )
        else
            pending_count = pending_count + 1
            pending[ pending_count ] = file_path
        end
    end

    pending_cursor = pending_count
    total_count = total

    FilesChanged:call( pending_count, total )
end

--- Checks up to `limit` pending files against the disk and moves the found ones to `downloaded`.
---
--- Walks the list backwards across calls, so every file gets rechecked without scanning the whole list each tick.
---
---@param limit integer
local function check_pending( limit )
    local changed = false

    for _ = 1, math_min( limit, pending_count ), 1 do
        if pending_count == 0 then break end

        if pending_cursor < 1 or pending_cursor > pending_count then
            pending_cursor = pending_count
        end

        local file_path = pending[ pending_cursor ]

        if vfs_isFile( "/game/" .. file_path ) then
            -- swap-remove, the order of `pending` is not kept
            pending[ pending_cursor ] = pending[ pending_count ]
            pending[ pending_count ] = nil
            pending_count = pending_count - 1

            mark_downloaded( file_path )
            changed = true
        end

        pending_cursor = pending_cursor - 1
    end

    if changed then
        FilesChanged:call( pending_count, total_count )
    end
end

local function reset_scan()
    table_clearIndexes( pending, pending_count )
    table_clearIndexes( downloaded, downloaded_count )
    table_clearKeys( known_downloaded )

    pending_count = 0
    downloaded_count = 0
    pending_cursor = 0
    total_count = 0
    seen_count = nil
    seen_status = nil
end

--- [MENU]
---
--- Returns the URL of the built-in loading page (`asset://garrysmod/html/loading.html`).
---
--- This is the page the game shows when the server has no loading URL of its own.
---
---@return string html_url The default loading page.
---@nodiscard
function loading.getDefaultHTML()
    return get_default_html()
end

--- [MENU]
---
--- Returns how many files the server wants the client to have.
---
---@return integer file_count The number of files, `0` when the engine reports none.
---@nodiscard
function loading.getFileCount()
    return get_engine_file_count() or 0
end

--- [MENU]
---
--- Returns the files the server wants the client to have.
---
--- Download suffixes (`.bz2`, `.ztmp`) are removed, backslashes become slashes,
--- and a bare workshop addon name is rewritten to `cache/workshop/…`.
---
---@return string[] files The normalized file paths. Empty when the engine has no list.
---@return integer file_count The number of files the engine reports, `0` when it reports none.
---@nodiscard
function loading.getFiles()
    local raw_files = get_engine_files()
    local file_count = get_engine_file_count() or 0

    if raw_files == nil then
        return {}, file_count
    end

    return normalize_files( raw_files ), file_count
end

--- [MENU]
---
--- Returns the listed files that are not on disk yet.
---
--- The array is updated in place while the loading screen is open, its order is not kept.
---
---@return string[] files The files still missing.
---@return integer file_count The number of files still missing.
---@nodiscard
function loading.getPending()
    return pending, pending_count
end

--- [MENU]
---
--- Returns the listed files that are already on disk.
---
--- The array is updated in place while the loading screen is open.
---
---@return string[] files The files already on disk.
---@return integer file_count The number of files already on disk.
---@nodiscard
function loading.getDownloaded()
    return downloaded, downloaded_count
end

--- [MENU]
---
--- Returns the current join status.
---
--- Whitespace, `.bz2`, `.ztmp` and backslashes are removed, the same way the file list is cleaned.
---
---@return string status The status text, `""` when the engine has none.
---@nodiscard
function loading.getStatus()
    local status = get_engine_status()
    if status == nil or status == "" then
        return ""
    end

    return strip_download_suffix( path_normalizeSlashes( string_trim( status ) ) )
end

--- [MENU]
---
--- Stops joining the server.
---
loading.cancel = cancel_loading

--- [MENU]
---
--- Returns how much of the file list is already on disk.
---
--- The fraction is `downloaded / total`, clamped to `0..1`.
--- It stays `0` until the first list arrives while the screen is open,
--- and `1` when the screen is closed and the server asked for no files.
---
---@return number fraction From `0` to `1`.
---@return integer downloaded The number of listed files already on disk.
---@return integer total The number of files the server asked for.
---@nodiscard
function loading.getProgress()
    if total_count <= 0 then
        if loading.active then
            return 0, 0, 0
        end

        return 1, 0, 0
    end

    return math_clamp( downloaded_count / total_count, 0, 1 ), downloaded_count, total_count
end

---@param is_active boolean
local function set_active( is_active )
    if loading.active == is_active then return end

    loading.active = is_active

    if is_active then
        reset_scan()

        if console.visible then
            console.hide()
        end

        Started:call()
        return
    end

    -- report the files that finished since the last tick
    check_pending( pending_count )

    seen_count = nil
    seen_status = nil

    Finished:call()

    -- nothing is in flight anymore; files already on disk stay readable
    table_clearIndexes( pending, pending_count )
    pending_count = 0
end

---@param panel garrysmod.Panel | nil
---@return boolean
local function panel_is_valid( panel )
    return panel ~= nil and gui_panelIsValid( panel )
end

--- The permanent loading panel handed to the engine, it outlives every connection.
---
---@type garrysmod.Panel | nil
local load_panel = nil

-- the engine keeps the panel alive between connections and signals
-- the loading screen through `OnActivate` / `OnDeactivate` instead
---@param panel garrysmod.Panel
local function watch_panel( panel )
    local on_activate, on_deactivate = panel.OnActivate, panel.OnDeactivate

    function panel:OnActivate( ... )
        set_active( true )

        if on_activate ~= nil then
            return on_activate( self, ... )
        end
    end

    function panel:OnDeactivate( ... )
        if on_deactivate ~= nil then
            on_deactivate( self, ... )
        end

        set_active( false )
    end
end

-- wraps the menu's own `GetLoadPanel` when it was defined before dreamwork,
-- otherwise hands the engine an empty panel
detour.attach( function( get_load_panel )
    if panel_is_valid( load_panel ) then
        return load_panel
    end

    local panel = get_load_panel ~= nil and get_load_panel() or nil
    if not panel_is_valid( panel ) then
        panel = gui_panelCreate( "Panel" )
    end

    ---@cast panel garrysmod.Panel
    watch_panel( panel )
    load_panel = panel

    return panel
end, nil, "GetLoadPanel" )

engine_hook.catch( "Tick", "std.menu.loading", function()
    if not loading.active then return end

    local status = loading.getStatus()
    if status ~= "" and status ~= seen_status then
        seen_status = status

        local file_name = file_from_status( status )
        if file_name ~= nil then
            FileDownloading:call( file_name )
        end

        StatusChanged:call( status )
    end

    local total = get_engine_file_count()
    if total ~= nil and total ~= seen_count then
        seen_count = total

        if total ~= 0 then
            local raw_files = get_engine_files()
            if raw_files ~= nil then
                local files, file_count = normalize_files( raw_files )
                adopt_files( files, file_count, total )
                return
            end
        end
    end

    check_pending( PENDING_CHECKS_PER_TICK )
end )
