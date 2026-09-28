---@meta dreamwork.std.steam.workshop


--- [SHARED AND MENU]
---
--- The Steam Workshop publication content type.
---
---@alias dreamwork.std.steam.workshop.Item.ContentType "addon" | "save" | "dupe" | "demo"

--- [SHARED AND MENU]
---
--- The Steam Workshop publication type.
---
---@alias dreamwork.std.steam.workshop.Item.Type "gamemode" | "map" | "weapon" | "vehicle" | "npc" | "entity" | "tool" | "effects" | "model" | "servercontent"

--- [SHARED AND MENU]
---
--- The Steam Workshop addon tag.
---
---@alias dreamwork.std.steam.workshop.Item.AddonTag "fun" | "roleplay" | "scenic" | "movie" | "realism" | "cartoon" | "water" | "comic" | "build"

--- [SHARED AND MENU]
---
--- The Steam Workshop dupe tag.
---
---@alias dreamwork.std.steam.workshop.Item.DupeTag "buildings" | "machines" | "posed" | "scenes" | "vehicles" | "other"

--- [SHARED AND MENU]
---
--- The Steam Workshop save tag.
---
---@alias dreamwork.std.steam.workshop.Item.SaveTag "buildings" | "courses" | "machines" | "scenes" | "other"

--- [SHARED AND MENU]
---
--- The Steam Workshop tag.
---
---@alias dreamwork.std.steam.workshop.Item.Tag dreamwork.std.steam.workshop.Item.ContentType | dreamwork.std.steam.workshop.Item.Type | dreamwork.std.steam.workshop.Item.AddonTag | dreamwork.std.steam.workshop.Item.DupeTag | dreamwork.std.steam.workshop.Item.SaveTag

--- [SHARED AND MENU]
---
--- The Steam Workshop search type.
---
---@alias dreamwork.std.steam.workshop.Item.SearchType "friendfavorite" | "subscribed" | "friends" | "favorite" | "trending" | "popular" | "latest" | "mine"

do

    --- The params table that was used in `Addon` search functions.
    ---@class dreamwork.std.steam.workshop.Item.SearchParams
    local search_params = {}

    --- The type of items to retrieve.
    ---@type dreamwork.std.steam.workshop.Item.SearchType?
    search_params.type = nil

    --- A table of tags to match.
    ---@type string[]?
    search_params.tags = nil

    --- How much of results to skip from first one.
    ---@type number?
    search_params.offset = 0

    --- How many items to retrieve, up to 50 at a time.
    ---@type number?
    search_params.count = 50

    --- This determines a time period, in range of days from 0 to 365.
    ---@type number?
    search_params.days = 365

    --- If specified, receives items from the workshop created by the owner of SteamID64.
    ---@type string?
    search_params.steamid64 = "0"

    --- If specified, retrieves items from your workshop, and also eliminates the 'steamid64' key.
    ---@type boolean?
    search_params.owned = false

    --- Response time, after which the function will be terminated with an error (default 30)
    ---@type number?
    search_params.timeout = 30

end

--- [SHARED AND MENU]
---
--- The Steam Workshop content descriptor.
---
---@alias dreamwork.std.steam.workshop.Warning "general_mature" | "gore" | "suggestive" | "nudity" | "adult_only"

--- [SHARED AND MENU]
---
--- Visibility of a Steam Workshop item.
---
---@alias dreamwork.std.steam.workshop.Visibility "public" | "friends-only" | "private" | "unlisted" | "developer-only" | "unknown"


do

    --- [SHARED AND MENU]
    ---
    --- The Steam Workshop item details.
    ---
    ---@class dreamwork.std.steam.workshop.ItemInfo
    local item_info = {}

    --- The ID of the item.
    ---
    ---@type string
    item_info.id = nil

    --- The title of the item.
    ---
    ---@type string
    item_info.title = nil

    --- The description of the item.
    ---
    ---@type string
    item_info.description = nil

    --- The visibility of the item.
    ---
    ---@type dreamwork.std.steam.workshop.Visibility
    item_info.visibility = nil

    --- The list of content descriptors for this item.
    ---
    ---@type dreamwork.std.steam.workshop.Warning[] | nil
    item_info.warnings = nil

    --- The tags of the item.
    ---
    ---@type dreamwork.std.steam.workshop.Item.Tag[]
    item_info.tags = nil

    --- If the addon is subscribed, this value represents whether it is installed on the client and its files are accessible, `false` otherwise.
    ---
    ---@type boolean
    item_info.installed = nil

    --- If the addon is subscribed, this value represents whether it is disabled on the client, `false` otherwise.
    ---
    ---@type boolean
    item_info.disabled = nil

    --- Whether the item is banned or not.
    ---
    ---@type boolean
    item_info.banned = nil

    --- The `steam.Identifier of the original uploader of the addon.
    ---
    ---@type dreamwork.std.steam.Identifier
    item_info.owner_id = nil

    --- The internal file ID of the item.
    ---
    ---@type integer
    item_info.file_id = nil

    --- The file size of the item in bytes.
    ---
    ---@type integer
    item_info.file_size = nil

    --- The internal preview ID of the item.
    ---
    ---@type integer
    item_info.preview_id = nil

    --- The URL to the preview image.
    ---
    ---@type string
    item_info.preview_url = nil

    --- The size of the preview image in bytes.
    ---
    ---@type integer
    item_info.preview_size = nil

    --- Unix timestamp of when the item was created
    ---@type integer
    item_info.created_at = nil

    --- Unix timestamp of when the file was last updated
    ---@type integer
    item_info.updated_at = nil

    --- A list of child Workshop Items for this item.
    ---
    --- For collections this will be sub-collections, for workshop items this will be the items they depend on.
    ---
    ---@type string[]
    item_info.children = nil

    --- If this key is set, no other data will be present in the response.
    ---
    --- Values above 0 represent Steam Error codes, values below 0 mean the following:
    --- * -1 means Failed to create query
    --- * -2 means Failed to send query
    --- * -3 means Received 0 or more than 1 result
    --- * -4 means Failed to get item data from the response
    --- * -5 means Workshop item ID in the response is invalid
    --- * -6 means Workshop item ID in response is mismatching the requested file ID
    ---@type integer
    item_info.error = nil

    --- Number of "up" votes for this item.
    ---@type number
    item_info.votes_up = nil

    --- Number of "down" votes for this item.
    ---@type number
    item_info.votes_down = nil

    --- Number of total votes (up and down) for this item. This is NOT `up - down`.
    ---@type number
    item_info.votes_total = nil

    --- The up down vote ratio for this item, i.e. `1` is when every vote is `up`, `0.5` is when half of the total votes are the up votes, etc.
    ---@type number
    item_info.votes_score = nil

end


do

    --- [SHARED AND MENU]
    ---
    --- A Steam API response.
    ---
    ---@class dreamwork.std.steam.workshop.Response
    local response = {}

    --- The reason why the request failed.
    ---
    --- Will be `nil` if `success` is `true`.
    ---
    ---@type string | nil
    response.reason = nil

end


do

    --- [SHARED AND MENU]
    ---
    --- Details of a Steam Workshop item.
    ---
    ---@class dreamwork.std.steam.workshop.Item.Details : dreamwork.std.steam.workshop.Response
    local details = {}

    --- The ID of the item in the Steam Workshop.
    ---
    ---@type string
    details.id = nil

    --- The title of the item.
    ---
    ---@type string
    details.title = nil

    --- The description of the item.
    ---
    ---@type string
    details.description = nil

    --- The URL to the preview image of the item.
    ---
    ---@type string
    details.preview_url = nil

    --- The visibility of the item.
    ---
    ---@type dreamwork.std.steam.workshop.Visibility
    details.visibility = nil

    --- The tags of the item.
    ---
    ---@type dreamwork.std.steam.workshop.Item.Tag[]
    details.tags = nil

    --- Whether the item is banned or not.
    ---
    ---@type boolean
    details.banned = nil

    --- The reason why the item is banned.
    ---
    --- `nil` if the item is not banned.
    ---
    ---@type string | nil
    details.ban_reason = nil

    --- The number of times the item has been favorited.
    ---
    ---@type integer
    details.favorited = nil

    --- The number of times the item has been subscribed to.
    ---
    ---@type integer
    details.subscriptions = nil

    --- The number of times the item has been viewed.
    ---
    ---@type integer
    details.views = nil

    --- The `steam.Identifier of the original uploader of the addon.
    ---
    ---@type dreamwork.std.steam.Identifier
    details.owner_id = nil

    --- The time, in unix format, when the item was created.
    ---
    ---@type number
    details.created_at = nil

    --- The time, in unix format, when the item was last updated.
    ---
    ---@type number
    details.updated_at = nil

    --- The internal name of the uploaded file.
    ---
    ---@type string
    details.file_name = nil

    --- The file size of the item in bytes.
    ---
    ---@type integer
    details.file_size = nil

    --- The URL to the file of the item.
    ---
    --- Mostly empty string.
    ---
    ---@type string
    details.file_url = nil

    --- The app id of the game using the item (usually same as creator_app_id).
    ---
    ---@type integer
    details.consumer_app_id = nil

    --- The app id of the tool used to upload it (e.g., GMod = 4000).
    ---
    ---@type integer
    details.creator_app_id = nil

    --- The content handle ID (internal Steam CDN ref).
    ---
    ---@type string
    details.hcontent_file = nil

    --- The content handle ID for the preview image.
    ---
    ---@type string
    details.hcontent_preview = nil

end


--- [SHARED AND MENU]
---
--- The type of a Steam Workshop item.
---
--- Ref: https://partner.steamgames.com/doc/api/ISteamRemoteStorage#EWorkshopFileType
---@alias dreamwork.std.steam.EWorkshopFileType "item" | "microtransaction" | "collection" | "artwork" | "video" | "screenshot" | "game" | "software" | "concept" | "web_guide" | "integrated_guide" | "merch" | "controller_binding" | "steamworks_access_invite" | "steam_video" | "game_managed_item"


do

    --- [SHARED AND MENU]
    ---
    --- Details of a Steam Workshop collection item.
    ---
    ---@class dreamwork.std.steam.workshop.Collection.Details.Item
    local item = {}

    --- The ID of the item in the Steam Workshop.
    ---
    ---@type string
    item.id = nil

    --- The type of the item.
    ---
    ---@type dreamwork.std.steam.EWorkshopFileType
    item.type = nil

    --- The order of the item in the collection.
    ---
    ---@type integer
    item.order = nil

end


do

    --- [SHARED AND MENU]
    ---
    --- Details of a Steam Workshop collection.
    ---
    ---@class dreamwork.std.steam.workshop.Collection.Details : dreamwork.std.steam.workshop.Response
    local details = {}

    --- The ID of the collection in the Steam Workshop.
    ---
    ---@type string
    details.id = nil

    --- The list of items in the collection or `nil` if request failed.
    ---
    --- The items are sorted in the order they are in the collection.
    ---
    ---@type dreamwork.std.steam.workshop.Collection.Details.Item[] | nil
    details.items = nil

end
