---@meta garrysmod.steamworks


---@alias garrysmod.steamworks.ListType
---| "popular" # All invalid options equal this.
---| "trending"
---| "latest"
---| "friends"
---| "followed" # Items of people the player is following on Steam.
---| "friend_favs" # Favorites of the player's friends.
---| "favorite" # Player's favorites.


---@alias garrysmod.steamworks.ContentDescriptor
---| "general_mature"
---| "gore"
---| "suggestive"
---| "nudity"
---| "adult_only"


--- [CLIENT AND MENU]
---
--- Additional preview entry returned by `steamworks.FileInfo` when `extra_info` is set.
---
---@class garrysmod.steamworks.ExtraPreview
---@field type integer Type of additional preview. `0` = normal image, `1` = YouTube video ID.
---@field url string URL to the additional preview. Format depends on `type`.

--- [CLIENT AND MENU]
---
--- Result table passed to the `steamworks.GetList` callback.
---
---@class garrysmod.steamworks.ListResult
---@field totalresults integer Total number of matching workshop items.
---@field numresults integer Number of items returned in this page.
---@field results table<integer, string | number> Workshop item IDs for this page. Indexed from `0`.

--- [CLIENT AND MENU]
---
--- Table structure used by `steamworks.FileInfo`.
---
--- If `error` is set, no other data will be present in the response.
---
---@class garrysmod.steamworks.UGCFileInfo
---@field id integer The Workshop item ID.
---@field title string The title of the Workshop item.
---@field description string The description of the Workshop item. Limited to `255` characters by Steam unless `steamworks.FileInfo` is called with `extra_info` set.
---@field fileid number The internal File ID of the workshop item, if any.
---@field previewid number The internal File ID of the workshop item preview, if any.
---@field previewurl string A URL to the preview image of the workshop item.
---@field owner number The SteamID64 of the original uploader of the addon.
---@field created integer Unix timestamp of when the item was created.
---@field updated integer Unix timestamp of when the file was last updated.
---@field banned boolean Whether the file is banned or not.
---@field tags string Comma (`,`) separated list of tags, may be truncated to some length.
---@field size integer File size of the workshop item contents in bytes.
---@field previewsize integer Filesize of the preview file in bytes.
---@field installed boolean If the addon is subscribed, whether it is installed on the client and its files are accessible.
---@field disabled boolean If the addon is subscribed, whether it is disabled on the client.
---@field children ( string | number )[] A list of child Workshop Items for this item. For collections this will be sub-collections; for workshop items this will be the items they depend on.
---@field ownername string The "nice" name of the uploader, or `"Unnammed Player"` if the data could not be retrieved. Do not use this field; use `steamworks.RequestPlayerInfo` instead.
---@field error integer? If set, no other data will be present. Values above `0` are Steam error codes; values below `0` mean: `-1` failed to create query, `-2` failed to send query, `-3` received `0` or more than `1` result, `-4` failed to get item data, `-5` workshop item ID in the response is invalid, `-6` workshop item ID mismatches the requested file ID.
---@field up integer Number of "up" votes for this item.
---@field down integer Number of "down" votes for this item.
---@field total integer Number of total votes (up and down) for this item. This is **not** `up - down`.
---@field score number The up/down vote ratio for this item (`1` = every vote is up, `0.5` = half of the total votes are up, etc).
---@field content_descriptors garrysmod.steamworks.ContentDescriptor[] A list of Steam content descriptors for this Steam Workshop item.
---@field extra_previews garrysmod.steamworks.ExtraPreview[]? Additional previews when `steamworks.FileInfo` was called with `extra_info`.

---@alias UGCFileInfo garrysmod.steamworks.UGCFileInfo

--- [SHARED AND MENU]
---
--- Steamworks related functions.
---
---@class garrysmod.steamworks
steamworks = {}

--- [MENU]
---
--- Refreshes clients addons.
---
function steamworks.ApplyAddons() end

--- [CLIENT AND MENU]
---
--- Downloads a file from the supplied addon and saves it as a `.cache` file in `garrysmod/cache/` folder.
---
--- This is mostly used to download the preview image of the addon.
---
--- In case the retrieved file is an image and you need the `IMaterial`, use `AddonMaterial` with the path supplied from the callback.
---
--- > **NOTE**: You really should be using `steamworks.DownloadUGC` when downloading Steam Workshop items. This is a legacy function for preview images.
---
---@param workshop_preview_id string The Preview ID of workshop item.
---@param uncompress boolean Whether to uncompress the file or not, assuming it was compressed with LZMA. You will usually want to set this to `true`.
---@param result_callback fun( path: string ) The function to process retrieved data. `path` is the path to the downloaded file.
function steamworks.Download( workshop_preview_id, uncompress, result_callback ) end

--- [CLIENT AND MENU]
---
--- Downloads a Steam Workshop item and returns a path to its `.gma` file.
---
---@param workshop_id string The ID of workshop item to download. **NOT** a file ID.
---@param result_callback fun( path: string?, file: garrysmod.File? ) The function to process retrieved data. `path` contains a path to the saved file, or `nil` if the download failed. `file` is a file object pointing to the downloaded `.gma` file; the handle will be closed after the function exits.
function steamworks.DownloadUGC( workshop_id, result_callback ) end

--- [SHARED AND MENU]
---
--- Retrieves info about supplied Steam Workshop addon.
---
---@param workshop_item_id string The ID of Steam Workshop item.
---@param result_callback fun( data: garrysmod.steamworks.UGCFileInfo? ) The function to process retrieved data. `data` is the item info if the request succeeded, `nil` otherwise.
---@param extra_info boolean? If set, retrieves more info about the workshop item, such as longer description and additional preview images. Only use this if absolutely necessary. Defaults to `false`.
function steamworks.FileInfo( workshop_item_id, result_callback, extra_info ) end

--- [SHARED AND MENU]
---
--- Retrieves a customized list of Steam Workshop addons.
---
---@param type garrysmod.steamworks.ListType The type of items to retrieve.
---@param tags string[]? A table of tags to match.
---@param offset integer How much of results to skip from first one. Useful for pagination. Negative values are invalid.
---@param num_retrieve integer How many items to retrieve, up to `50` at a time. Negative values are invalid.
---@param days integer When getting `popular` or `trending` content from Steam, this determines a time period in days from `0` to `365`. If given `0`, will automatically choose a value (`7` for `trending`).
---@param user_id string? `"0"` to retrieve all addons, `"1"` to retrieve addons only published by you, or a valid SteamID64 of a user to get workshop items of. Defaults to `"0"`.
---@param result_callback fun( data: garrysmod.steamworks.ListResult? ) The function to process retrieved data. `data` is the list of items, or `nil` in case of error.
---@param search_text string? If given, will use the text to filter results.
function steamworks.GetList( type, tags, offset, num_retrieve, days, user_id, result_callback, search_text ) end

--- [CLIENT AND MENU]
---
--- Retrieves players name by their 64bit SteamID.
---
--- You must call `steamworks.RequestPlayerInfo` a decent amount of time before calling this function.
---
--- > **DEPRECATED**: You should use the callback of `steamworks.RequestPlayerInfo` instead.
---
---@param steam_id64 string The 64bit Steam ID (aka Community ID) of the player.
---@return string name The name of that player.
---@deprecated You should use the callback of `steamworks.RequestPlayerInfo` instead.
function steamworks.GetPlayerName( steam_id64 ) end

--- [CLIENT AND MENU]
---
--- Returns whenever the client is subscribed to the specified Steam Workshop item.
---
---@param workshop_item_id string The ID of the Steam Workshop item.
---@return boolean is_subscribed Whether the client is subscribed to the addon or not.
function steamworks.IsSubscribed( workshop_item_id ) end

--- [CLIENT AND MENU]
---
--- Opens the workshop website in the steam overlay browser.
---
function steamworks.OpenWorkshop() end

--- [MENU]
---
--- Publishes dupes, saves or demos to workshop.
---
--- > **INTERNAL**: This is used internally - although you're able to use it you probably shouldn't.
---
---@param filename string Path to the file to upload.
---@param image string Path to the image to use as icon.
---@param name string Name of the Workshop submission.
---@param desc string Description of the Workshop submission.
---@param tags string[] The workshop tags to apply.
---@param callback fun( file_id: number?, error: string? ) Callback for when the publishing process finishes. On success, `file_id` is set; on failure, `error` is the error message.
---@param file_id number? If set, the file ID to update.
---@param changelist string? List of changes when updating an item. Defaults to `"None given."`.
function steamworks.Publish( filename, image, name, desc, tags, callback, file_id, changelist ) end

--- [CLIENT AND MENU]
---
--- Requests information of the player with SteamID64 for later use with `steamworks.GetPlayerName`.
---
---@param steam_id64 string The 64bit Steam ID of player.
---@param callback fun( name: string ) A callback function with the data when it arrives. `name` is the player's name.
function steamworks.RequestPlayerInfo( steam_id64, callback ) end

--- [MENU]
---
--- Sets the workshop item as "completed" by the player.
--- There will be a visual indicator on the Steam Workshop for completed items.
---
---@param workshop_id string The Steam Workshop item id.
---@return string workshop_id Whatever you have put in as first argument.
function steamworks.SetFileCompleted( workshop_id ) end

--- [MENU]
---
--- Sets whether you have played this addon or not.
--- This will be shown to the user in the Steam Workshop itself.
---
---@param workshop_id string The Steam Workshop item ID.
---@return string workshop_id Whatever you have put in as first argument.
function steamworks.SetFilePlayed( workshop_id ) end

--- [MENU]
---
--- Sets if an addon should be enabled or disabled. Call `steamworks.ApplyAddons` afterwards to update.
---
---@param workshop_item_id string The ID of the Steam Workshop item we should enable/disable.
---@param should_mount boolean `true` to enable the item, `false` to disable.
function steamworks.SetShouldMountAddon( workshop_item_id, should_mount ) end

--- [CLIENT AND MENU]
---
--- Returns whenever the specified Steam Workshop addon will be mounted or not.
---
---@param workshop_item_id string The ID of the Steam Workshop.
---@return boolean should_mount Whether the workshop item will be mounted or not.
function steamworks.ShouldMountAddon( workshop_item_id ) end

--- [MENU]
---
--- Subscribes to the specified workshop addon. Call `steamworks.ApplyAddons` afterwards to update.
---
--- > **INTERNAL**: This is used internally - although you're able to use it you probably shouldn't.
---
---@param workshop_item_id string The ID of the Steam Workshop item we should subscribe to.
function steamworks.Subscribe( workshop_item_id ) end

--- [MENU]
---
--- Unsubscribes to the specified workshop addon. Call `steamworks.ApplyAddons` afterwards to update.
---
--- This function should **never** be called without a user's consent and should not be called if the addon is currently in use
--- (aka: the user is not in the main menu) as it may result in unexpected behaviour.
---
--- > **INTERNAL**: This is used internally - although you're able to use it you probably shouldn't.
---
---@param workshop_item_id string The ID of the Steam Workshop item we should unsubscribe from.
function steamworks.Unsubscribe( workshop_item_id ) end

--- [CLIENT AND MENU]
---
--- Opens the workshop website for specified Steam Workshop item in the Steam overlay browser.
---
---@param workshop_item_id string The ID of workshop item.
function steamworks.ViewFile( workshop_item_id ) end

--- [MENU]
---
--- Makes the user vote for the specified addon.
---
--- > **INTERNAL**: This is used internally - although you're able to use it you probably shouldn't.
---
---@param workshop_item_id string The ID of workshop item.
---@param up_or_down boolean Sets if the user should vote up/down. `true` makes them upvote, `false` down.
function steamworks.Vote( workshop_item_id, up_or_down ) end

--- [CLIENT AND MENU]
---
--- Retrieves vote info of supplied addon.
---
--- > **DEPRECATED**: Use data from `steamworks.FileInfo` instead.
---
---@param workshop_item_id string The ID of workshop item.
---@param result_callback fun( data: garrysmod.steamworks.UGCFileInfo ) The function to process retrieved data.
---@deprecated Use data from `steamworks.FileInfo` instead.
function steamworks.VoteInfo( workshop_item_id, result_callback ) end
