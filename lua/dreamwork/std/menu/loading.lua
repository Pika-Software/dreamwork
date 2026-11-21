local std = dreamwork.std

---@class dreamwork.std.menu
local menu = std.menu


-- --- [MENU]
-- ---
-- --- The game's menu loading ( connecting to the server ) module.
-- ---
-- ---@class dreamwork.std.menu.loading
-- local loading = menu.loading or {}
-- menu.loading = loading

-- loading.getDefaultURL = GetDefaultLoadingHTML

-- -- TODO: rename getDefaultURL

-- loading.getFileCount = NumDownloadables
-- loading.getFiles = GetDownloadables

-- -- TODO: custom getFiles (files, file_count)

-- loading.getStatus = GetLoadStatus
-- loading.cancel = CancelLoading

-- -- TODO: Add getProgress
-- -- TODO: https://github.com/Pika-Software/atmosphere/blob/master/lua/menu/atmosphere/components/loading.lua

-- GetFileCount = NumDownloadables
-- GetFiles = GetDownloadables
-- GetStatus = GetLoadStatus
-- Cancel = CancelLoading

-- TODO: implement using references

-- do

--     local downloadableFiles = {}
--     local downloadedFiles = {}
--     local isLoading = false
--     local filesCount = nil
--     local status = nil

--     function GetDownloadablesFiles()
--         return downloadableFiles
--     end

--     function GetDownloadedFiles()
--         return downloadedFiles
--     end

--     function IsActive()
--         return isLoading
--     end

--     hook.Add( 'LoadingStarted', 'atmosphere.loading', function()
--         table_Empty( downloadedFiles )

--         if console.IsVisible() then
--             console.Hide()
--         end

--         isLoading = true
--     end )

--     hook.Add( 'LoadingFinished', 'atmosphere.loading', function()
--         isLoading = false
--         filesCount = nil
--         status = nil

--         table_Empty( downloadableFiles )
--     end )

--     hook.Add( 'Think', 'atmosphere.loading', function()
--         if not isLoading then return end

--         do

--             local current = GetStatus()
--             if ( current and current ~= status ) then
--                 status = current

--                 local fileName = string.match( current, '%w+/%w+ [-] (.+) is downloading' )
--                 if ( fileName ~= nil ) then
--                     -- New FastDL/ServerDL format
--                     hook.Run( 'FileDownloading', fileName )
--                 elseif string.match( current, 'Downloading ' ) then
--                     if string.match( current, 'via Workshop' ) then
--                         current = string.Replace( current, '\' via Workshop', '' )
--                         current = string.Replace( current, 'Downloading \'', '' )
--                     end

--                     -- WorkshopDL and old FastDL
--                     hook.Run( 'FileDownloading', string.Replace( current, 'Downloading ', '' ) )
--                 end

--                 hook.Run( 'LoadingStatusChanged', current )
--             end

--         end

--         do

--             local current = GetFileCount()
--             if ( current and filesCount ~= current ) then
--                 filesCount = current

--                 if ( current == 0 ) then return end

--                 local files = GetFiles()
--                 if not files then return end

--                 table_Empty( downloadableFiles )
--                 table_Empty( downloadedFiles )

--                 local remain = 0
--                 for _, filePath in ipairs( files ) do
--                     filePath = string.Replace( filePath, '.bz2', '' )
--                     filePath = string.Replace( filePath, '.ztmp', '' )
--                     filePath = string.Replace( filePath, '\\', '/' )

--                     if ( string.match( filePath, '^(%w+).gma[d]?$' ) ~= nil ) then
--                         filePath = 'cache/workshop/' .. filePath
--                     end

--                     if filesystem.Exists( filePath, 'GAME' ) then
--                         downloadedFiles[ #downloadedFiles + 1 ] = filePath
--                         hook.Run( 'FileDownloaded', filePath )
--                         continue
--                     end

--                     downloadableFiles[ #downloadableFiles + 1 ] = filePath
--                     remain = remain + 1
--                 end

--                 hook.Run( 'DownloadablesCountChanged', remain, current )
--             end

--         end
--     end )

-- end

-- function GetPanel()
--     if not IsValid( Panel ) then
--         Panel = ui.Create( 'Loading Screen' )
--     end

--     return Panel
-- end

-- function IsVisible()
--     local panel = GetPanel()
--     if IsValid( panel ) then
--         return panel:IsVisible()
--     end

--     return false
-- end

-- -- Server Information
-- hook.Add( 'GameDetails', 'atmosphere.loading', function( ... )
--     local panel = GetPanel()
--     if not IsValid( panel ) then return end

--     local loadingPanel = panel.LoadingScreen
--     if not IsValid( loadingPanel ) then return end

--     loadingPanel:RunEvent( 'gameDetails', ... )
-- end )

-- -- Loading Events
-- hook.Add( 'DownloadablesCountChanged', 'atmosphere.loading', function( remain, total )
--     local panel = GetPanel()
--     if not IsValid( panel ) then return end

--     local loadingPanel = panel.LoadingScreen
--     if not IsValid( loadingPanel ) then return end

--     loadingPanel:RunEvent( 'downloadablesCountChanged', remain, total )
-- end )

-- hook.Add( 'FileDownloading', 'atmosphere.loading', function( fileName )
--     local panel = GetPanel()
--     if not IsValid( panel ) then return end

--     local loadingPanel = panel.LoadingScreen
--     if not IsValid( loadingPanel ) then return end

--     loadingPanel:RunEvent( 'fileDownloading', fileName )
-- end )

-- hook.Add( 'FileDownloaded', 'atmosphere.loading', function( filePath )
--     local panel = GetPanel()
--     if not IsValid( panel ) then return end

--     local loadingPanel = panel.LoadingScreen
--     if not IsValid( loadingPanel ) then return end

--     loadingPanel:RunEvent( 'fileDownloaded', filePath )
-- end )

-- hook.Add( 'LoadingStatusChanged', 'atmosphere.loading', function( status )
--     local panel = GetPanel()
--     if not IsValid( panel ) then return end

--     local loadingPanel = panel.LoadingScreen
--     if not IsValid( loadingPanel ) then return end

--     loadingPanel:RunEvent( 'statusChanged', status )
-- end )

-- -- Engine Hooks
-- hook.Add( 'RunJSOnLoading', 'atmosphere.loading', function( str )
--     local panel = GetPanel()
--     if not IsValid( panel ) then return end

--     local loadingPanel = panel.LoadingScreen
--     if not IsValid( loadingPanel ) then return end

--     loadingPanel:RunEvent( 'runJavaScript', str )
-- end )

-- hook.Add( 'GameIsLoading', 'atmosphere.loading', function()
--     local panel = GetPanel()
--     if IsValid( panel ) then
--         return panel.Connecting
--     end

--     return false
-- end )

-- hook.Add( 'GetLoadingPanel', 'atmosphere.loading', function()
--     local panel = GetPanel()
--     if IsValid( panel ) then
--         return panel
--     end
-- end )
