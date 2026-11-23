---@meta _

--- [SHARED AND MENU]
---
--- The Steam Workshop API library.
---
---@class steam.workshop
---@field available boolean `true` if the Steam Workshop API is available.
steam.workshop = {}

steam.workshop.available = true

---@class steam.workshop.WebTag
---@field tag string

---@class steam.workshop.WebFile
---@field result integer
---@field publishedfileid string
---@field title string | nil
---@field description string | nil
---@field preview_url string | nil
---@field visibility integer | nil
---@field tags steam.workshop.WebTag[] | nil
---@field banned integer | nil
---@field ban_reason string | nil
---@field lifetime_favorited integer | nil
---@field lifetime_subscriptions integer | nil
---@field views integer | nil
---@field creator string | nil
---@field time_created integer | nil
---@field time_updated integer | nil
---@field filename string | nil
---@field file_size integer | nil
---@field file_url string | nil
---@field consumer_app_id integer | nil
---@field creator_app_id integer | nil
---@field hcontent_file string | nil
---@field hcontent_preview string | nil

---@class steam.workshop.WebFileResponse
---@field result integer
---@field publishedfiledetails steam.workshop.WebFile[] | nil

---@class steam.workshop.WebChild
---@field publishedfileid string
---@field filetype integer
---@field sortorder integer

---@class steam.workshop.WebCollection
---@field result integer
---@field publishedfileid string
---@field children steam.workshop.WebChild[] | nil

---@class steam.workshop.WebCollectionResponse
---@field result integer
---@field collectiondetails steam.workshop.WebCollection[] | nil

--- Fields read from `steamworks.FileInfo` and from the Workshop Web API.
---
---@class steam.workshop.FilePayload
---@field tags string | steam.workshop.WebTag[] | nil
---@field content_descriptors garrysmod.steamworks.ContentDescriptor[] | nil
---@field children ( string | number )[] | nil
---@field title string | nil
---@field description string | nil
---@field visibility integer | nil
---@field installed boolean | nil
---@field disabled boolean | nil
---@field banned boolean | integer | nil
---@field ban_reason string | nil
---@field owner string | number | nil
---@field creator string | nil
---@field fileid string | number | nil
---@field file_id string | number | nil
---@field size integer | nil
---@field file_size integer | nil
---@field previewid string | number | nil
---@field preview_id string | number | nil
---@field previewurl string | nil
---@field preview_url string | nil
---@field previewsize integer | nil
---@field preview_size integer | nil
---@field created integer | nil
---@field time_created integer | nil
---@field created_at integer | nil
---@field updated integer | nil
---@field time_updated integer | nil
---@field updated_at integer | nil
---@field up number | nil
---@field votes_up number | nil
---@field down number | nil
---@field votes_down number | nil
---@field total number | nil
---@field votes_total number | nil
---@field score number | nil
---@field votes_score number | nil
---@field lifetime_favorited integer | nil
---@field favorited integer | nil
---@field lifetime_subscriptions integer | nil
---@field subscriptions integer | nil
---@field views integer | nil
---@field filename string | nil
---@field file_name string | nil
---@field file_url string | nil
---@field consumer_app_id integer | nil
---@field creator_app_id integer | nil
---@field hcontent_file string | nil
---@field hcontent_preview string | nil

--- [SHARED AND MENU]
---
--- A Steam Workshop item (published file).
---
--- Identity-cached: `workshop.Item( id )` returns the same object for the same id.
---
--- Call `:fetch()` to hydrate metadata from Steam.
---
---@class steam.workshop.Item : Object
---@field __class steam.workshop.ItemClass
---@field id string The Steam Workshop published-file id.
---@field title string | nil
---@field description string | nil
---@field visibility steam.workshop.Visibility | nil
---@field warnings steam.workshop.Warning[] | nil
---@field tags steam.workshop.Item.Tag[] | nil
---@field installed boolean | nil
---@field disabled boolean | nil
---@field banned boolean | nil
---@field ban_reason string | nil
---@field owner_id steam.Identifier | nil
---@field file_id string | integer | nil
---@field file_size integer | nil
---@field file_name string | nil
---@field file_url string | nil
---@field preview_id string | integer | nil
---@field preview_url string | nil
---@field preview_size integer | nil
---@field created_at integer | nil
---@field updated_at integer | nil
---@field children string[] | nil
---@field votes_up number | nil
---@field votes_down number | nil
---@field votes_total number | nil
---@field votes_score number | nil
---@field favorited integer | nil
---@field subscriptions integer | nil
---@field views integer | nil
---@field consumer_app_id integer | nil
---@field creator_app_id integer | nil
---@field hcontent_file string | nil
---@field hcontent_preview string | nil
---@field url string Steam Workshop page for this item.
---@field enabled boolean Whether the engine should mount this item. Writable on the server and in the menu.
---@field subscribed boolean Whether the local client is subscribed. Writable in the menu, and on the server when set to `true`.
local Item = {}

--- [SHARED AND MENU]
---
--- The class used to create or get `Item` objects.
---
---@class steam.workshop.ItemClass : steam.workshop.Item, Class
---@field __base steam.workshop.Item
---@overload fun( id: any ): steam.workshop.Item
local ItemClass = {}

steam.workshop.Item = ItemClass

---@param id any
---@return steam.workshop.Item | nil
---@protected
function ItemClass:__new(id) end

---@return string
---@nodiscard
---@protected
function Item:__represent() end

---@param key string
---@return any
---@protected
function Item:__index(key) end

---@param key string
---@param value any
---@protected
function Item:__newindex(key, value) end

---@param id any
---@protected
function Item:__init(id) end

--- [SHARED AND MENU]
---
--- Fetches metadata for this item from Steam and hydrates the object.
---
---@param seconds number? Timeout in seconds, `30` by default.
---@return steam.workshop.Item self
---@async
function Item:fetch(seconds) end

--- [SHARED AND MENU]
---
--- Fetches multiple items from the Steam Web API and hydrates identity-cached objects.
---
---@param ids string[] Workshop item ids.
---@param id_count integer? Number of ids, `#ids` by default.
---@param timeout number? Timeout in seconds.
---@return steam.workshop.Item[] items
---@return integer item_count
---@nodiscard
---@async
function ItemClass.fetchMany(ids, id_count, timeout) end

--- [SHARED AND MENU]
---
--- Downloads this item's `.gma` from the Steam Workshop.
---
---@param seconds number? Timeout in seconds, `30` by default.
---@return string file_path Absolute path to the downloaded `.gma`.
---@async
function Item:download(seconds) end

--- [CLIENT AND MENU]
---
--- Downloads the preview icon and returns an absolute path to the file.
---
---@param uncompress boolean? `true` by default.
---@param seconds number? Timeout in seconds, `30` by default.
---@return string file_path
---@async
function Item:downloadIcon(uncompress, seconds) end

--- [MENU]
---
--- Publishes a file to the Steam Workshop and returns the new item.
---
---@param file_path string Absolute path to the addon file.
---@param image_path string Absolute path to the preview image.
---@param title string
---@param description string?
---@param tags string[]
---@param change_log string?
---@param seconds number | false | nil
---@return steam.workshop.Item item
---@nodiscard
---@async
function ItemClass.publish(file_path, image_path, title, description, tags, change_log, seconds) end

--- [MENU]
---
--- Updates this Workshop publication.
---
---@param file_path string Absolute path to the addon file.
---@param image_path string Absolute path to the preview image.
---@param title string
---@param description string?
---@param tags string[]
---@param change_log string?
---@param seconds number | false | nil
---@return steam.workshop.Item self
---@async
function Item:update(file_path, image_path, title, description, tags, change_log, seconds) end

--- [MENU]
---
--- Marks this item as completed.
function Item:markAsCompleted() end

--- [MENU]
---
--- Marks this item as played.
function Item:markAsPlayed() end

--- [MENU]
---
--- Votes for this item.
---
---@param upvote boolean `true` to vote up, `false` to vote down.
function Item:vote(upvote) end

--- [SHARED AND MENU]
---
--- Searches the Workshop and returns matching items.
---
---@param params steam.workshop.Item.SearchParams
---@param seconds number?
---@return steam.workshop.Item[] items
---@return integer item_count
---@return integer total
---@nodiscard
---@async
function ItemClass.search(params, seconds) end

--- [SHARED AND MENU]
---
--- Performs a quick search for publications.
---
---@param wtype steam.workshop.Item.SearchType?
---@param wtags string[]?
---@param woffset integer?
---@param timeout number?
---@return steam.workshop.Item[] items
---@return integer item_count
---@return integer total
---@nodiscard
---@async
function ItemClass.quickSearch(wtype, wtags, woffset, timeout) end

--- [SHARED AND MENU]
---
--- Returns publications published by the local Steam user.
---
---@param wtype steam.workshop.Item.SearchType?
---@param wtags string[]?
---@param woffset integer?
---@param timeout number?
---@return steam.workshop.Item[] items
---@return integer item_count
---@return integer total
---@nodiscard
---@async
function ItemClass.getPublished(wtype, wtags, woffset, timeout) end

--- [SHARED AND MENU]
---
--- A Steam Workshop collection.
---
--- Identity-cached: `workshop.Collection( id )` returns the same object for the same id.
---
--- Call `:fetch()` to hydrate children from the Steam Web API.
---
---@class steam.workshop.Collection : Object
---@field __class steam.workshop.CollectionClass
---@field id string The Steam Workshop collection id.
---@field items steam.workshop.Item[] | nil Ordered child items.
---@field item_count integer | nil
local Collection = {}

--- [SHARED AND MENU]
---
--- The class used to create or get `Collection` objects.
---
---@class steam.workshop.CollectionClass : steam.workshop.Collection, Class
---@field __base steam.workshop.Collection
---@overload fun( id: any ): steam.workshop.Collection
local CollectionClass = {}

---@cast CollectionClass steam.workshop.CollectionClass
steam.workshop.Collection = CollectionClass

---@param id any
---@return steam.workshop.Collection | nil
---@protected
function CollectionClass:__new(id) end

---@return string
---@nodiscard
---@protected
function Collection:__represent() end

---@param key string
---@return any
---@protected
function Collection:__index(key) end

---@return fun( collection: steam.workshop.Collection, key: any ): integer | nil, steam.workshop.Item | nil
---@protected
function Collection:__pairs() end

---@param id any
---@protected
function Collection:__init(id) end

--- [SHARED AND MENU]
---
--- Fetches this collection's children from the Steam Web API and hydrates the object.
---
---@param timeout number? Timeout in seconds.
---@return steam.workshop.Collection self
---@async
function Collection:fetch(timeout) end

--- [SHARED AND MENU]
---
--- Fetches multiple collections and returns identity-cached objects.
---
---@param ids string[] Workshop collection ids.
---@param id_count integer? Number of ids, `#ids` by default.
---@param timeout number? Timeout in seconds.
---@return steam.workshop.Collection[] collections
---@return integer collection_count
---@nodiscard
---@async
function CollectionClass.fetchMany(ids, id_count, timeout) end

--- [SERVER AND MENU]
---
--- Refreshes the engine addon system so it picks up addon changes.
---
--- Applies local Workshop addon changes after `enabled` or `subscribed` is set.
---
function steam.workshop.apply() end

--- [SERVER]
---
--- Clears the engine addon system, removing active addons.
---
--- Uses HolyLib `addonsystem.Clear`.
function steam.workshop.clear() end
