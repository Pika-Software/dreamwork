---@meta _

--- [MENU]
---
--- The Facepunch API library.
---
---@class http.facepunch
http.facepunch = {}

--- [MENU]
---
--- Gets miscellaneous information from Facepunches API.
---
---@param timeout number? The timeout in seconds, `30` by default, `0` disables it.
---@return table data The data returned from the API.
---@nodiscard
---@async
function http.facepunch.getManifest(timeout) end
