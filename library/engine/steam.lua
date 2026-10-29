---@meta _

--- [SHARED AND MENU]
---
--- Steam API library.
---
---@class steam
steam = {}

--- [CLIENT AND MENU]
---
--- The game achievement library.
---
---@class game.achievement
local achievement = {}

--- [CLIENT AND MENU]
---
--- Returns information about an achievement (name, description, value, etc.)
---
---@param id number The ID of achievement to retrieve name of. Note  IDs start from 0, not 1.
---@return table | nil table Returns nil if the ID is invalid.
function achievement.get(id) end

--- [CLIENT AND MENU]
---
--- Checks if an achievement with the given ID exists.
---
---@param id number
---@return boolean exist Returns true if the achievement exists.
---@nodiscard
function achievement.exists(id) end

--- [CLIENT AND MENU]
---
--- Returns information about all achievements.
---
---@return table achievement_list The list of all achievements.
---@return number achievement_count The count of achievements.
---@nodiscard
function achievement.getAll() end

--- [CLIENT AND MENU]
---
--- Returns the name of the player with the given Steam ID.
---
---@param id steam.Identifier The SteamID of the player.
---@param timeout? number The timeout in seconds, if `nil` then the default timeout will be used.
---@return string name The name of the player.
---@nodiscard
---@async
function steam.getUserName(id, timeout) end

--- [SHARED AND MENU]
---
--- The Steam Workshop API library.
---
---@class steam.workshop
local workshop = {}

steam.workshop = workshop

--- [SHARED AND MENU]
---
--- Checks if the given Steam Workshop item ID is valid.
---
---@param id? string
---@return boolean
---@nodiscard
function workshop.isValidID(id) end

--- [SHARED AND MENU]
---
--- Returns the details of a Steam Workshop collection's.
---
---@param ids string[] The Steam Workshop item ID's.
---@param id_count? integer The number of Steam Workshop item ID's.
---@param timeout? number The timeout in seconds, if `nil` then the default timeout will be used.
---@return steam.workshop.Collection.Details[] items The details of the Steam Workshop collections.
---@return integer item_count The number of Steam Workshop collections.
---@nodiscard
---@async
function workshop.getCollectionDetails(ids, id_count, timeout) end

--- [SHARED AND MENU]
---
--- Returns the details of a Steam Workshop item's.
---
---@param ids string[] The Steam Workshop item ID's.
---@param id_count? integer The number of Steam Workshop item ID's.
---@param timeout? number The timeout in seconds, if `nil` then the default timeout will be used.
---@return steam.workshop.Item.Details[] items The details of the Steam Workshop items.
---@return integer item_count The number of Steam Workshop items.
---@nodiscard
---@async
function workshop.getItemDetails(ids, id_count, timeout) end

--- [SHARED AND MENU]
---
--- Fetches a detailed information about a specific Steam Workshop item or collection.
---
---@param wsid string The workshop ID of the item/collection.
---@param timeout? number The timeout in seconds, if `nil` then the default timeout will be used.
---@return steam.workshop.ItemInfo info The details of the item/collection.
---@nodiscard
---@async
function workshop.fetchInfo(wsid, timeout) end

--- [CLIENT AND MENU]
---
--- Returns whether the addon should be mounted on local server start-up.
---
---@param wsid string The workshop ID of the addon.
---@return boolean `true` if the addon is enabled, `false` otherwise.
---@nodiscard
---@see steam.workshop.setAddonEnabled
function workshop.isAddonEnabled(wsid) end

--- [CLIENT AND MENU]
---
--- Returns whether the publication is subscribed.
---
---@param wsid string The workshop ID of the addon.
---@return boolean `true` if client has subscribed to the item, `false` otherwise.
---@nodiscard
---@see steam.workshop.setItemSubscribed
function workshop.isItemSubscribed(wsid) end

--- [CLIENT AND MENU]
---
--- Opens the page of the addon in the Steam Workshop.
---
---@param wsid string The workshop ID of the addon.
function workshop.openPage(wsid) end

--- [MENU]
---
--- Downloads the icon of the Steam Workshop item and returns the absolute path to the file.
---
---@param wsid string The workshop ID of the addon.
---@param uncompress? boolean Whether the icon should be uncompressed, `true` by default.
---@param timeout? number The timeout in seconds, if `nil` then the default timeout will be used.
---@return string file_path The absolute path to the icon file.
---@async
function workshop.downloadIcon(wsid, uncompress, timeout) end

--- [MENU]
---
--- Sets whether the addon should be mounted on local server start-up.
---
---@param wsid string The workshop ID of the addon.
---@param enabled boolean `true` to enable the addon, `false` to disable it.
---@see steam.workshop.isAddonEnabled
---@see steam.workshop.reload
function workshop.setAddonEnabled(wsid, enabled) end

--- [MENU]
---
--- Subscribes or unsubscribes the publication.
---
---@param wsid string The workshop ID of the addon.
---@param subscribed boolean `true` to subscribe, `false` to unsubscribe.
---@see steam.workshop.isItemSubscribed
---@see steam.workshop.reload
function workshop.setItemSubscribed(wsid, subscribed) end

--- [MENU]
---
--- Refreshes local Steam Workshop addons.
---
--- This function should be called after changing the list of enabled addons.
---
---@see steam.workshop.isAddonEnabled
---@see steam.workshop.setItemSubscribed
function workshop.reload() end

--- [MENU]
---
--- Marks the Steam Workshop item as completed.
---
---@param wsid string The workshop ID of the addon.
function workshop.markAsCompleted(wsid) end

--- [MENU]
---
--- Marks the Steam Workshop item as played.
---
---@param wsid string The workshop ID of the addon.
function workshop.markAsPlayed(wsid) end

--- [MENU]
---
--- Votes for the Steam Workshop item.
---
---@param wsid string The workshop ID of the addon.
---@param vote boolean `true` to vote for, `false` to vote against.
function workshop.vote(wsid, vote) end

--- [SHARED AND MENU]
---
--- Downloads the item from the Steam Workshop.
---
---@param wsid string The workshop ID of the addon.
---@param timeout number The timeout in seconds, if `nil` then the default timeout will be used.
---@return string file_path The absolute path to the downloaded addon `.gma`.
---@async
function workshop.download(wsid, timeout) end

--- [SHARED AND MENU]
---
--- Performs a search for publications.
---
---@param params steam.workshop.Item.SearchParams The search parameters.
---@param timeout number The timeout in seconds, if `nil` then the default timeout will be used.
---@return string[] ids The IDs of the found publications.
---@return integer id_count The length of the `ids` array (`#ids`).
---@return integer total The total number of found publications.
---@nodiscard
---@async
function workshop.search(params, timeout) end

--- [SHARED AND MENU]
---
--- Performs a quick search for publications.
---
---@param wtype steam.workshop.Item.SearchType The type of the search.
---@param wtags string[]? The tags of the search.
---@param woffset integer? The offset of the search.
---@param timeout number? The timeout in seconds of the search, if `nil` then the default timeout will be used.
---@return string[] items The found publications.
---@return integer item_count The length of the publications found array (`#publications`).
---@return integer total The total number of publications found.
---@nodiscard
---@async
function workshop.qickSearch(wtype, wtags, woffset, timeout) end

--- [SHARED AND MENU]
---
--- Returns a list of publications published by the client.
---
---@param wtype steam.workshop.Item.SearchType The type of the search.
---@param wtags string[]? The tags of the search.
---@param woffset integer? The offset of the search.
---@param timeout number? The timeout in seconds of the search, if `nil` then the default timeout will be used.
---@return string[] ids The found publications IDs.
---@return integer item_count The length of the publications found array (`#publications`).
---@return integer total The total number of publications found.
---@nodiscard
---@async
function workshop.getPublished(wtype, wtags, woffset, timeout) end

--- [MENU]
---
--- Publishes file to Steam Workshop.
---
---@param filePath string The absolute path to the addon file.
---@param imagePath string The absolute path to the image file.
---@param title string The title of the addon.
---@param description string? The description of the addon.
---@param tags string[] The tags for the addon.
---@param changeLog string? The changelog of the publication.
---@param timeout number | nil | false The timeout in seconds, if `nil` then the default timeout will be used.
---@return string workshop_id The workshop ID of the published addon.
---@async
function workshop.publishItem(filePath, imagePath, title, description, tags, changeLog, timeout) end

--- [MENU]
---
--- Updates an file on Steam Workshop.
---
---@param filePath string The absolute path to the addon file.
---@param imagePath string The absolute path to the image file.
---@param title string The title of the addon.
---@param description? string The description of the addon.
---@param tags string[] The tags for the addon.
---@param wsid string The workshop ID of the addon.
---@param changeLog string? The changelog of the publication.
---@param timeout number | nil | false The timeout in seconds, if `nil` then the default timeout will be used.
---@return boolean success `true` if the update was successful, `false` otherwise.
---@async
function workshop.updateItem(filePath, imagePath, title, description, tags, wsid, changeLog, timeout) end
