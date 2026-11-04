local glua_GetAPIManifest = GetAPIManifest

---@class dreamwork.std
local std = dreamwork.std

---@class dreamwork.std.http
local http = std.http

local json = std.json
local json_deserialize = json.deserialize

local setTimeout = std.setTimeout

local Future = std.Future


--- [MENU]
---
--- The Facepunch API library.
---
---@class dreamwork.std.http.facepunch
local facepunch = {}
http.facepunch = facepunch

--- [MENU]
---
--- Gets miscellaneous information from Facepunches API.
---
---@param timeout number? The timeout in seconds, `30` by default, `0` disables it.
---@return table data The data returned from the API.
---@nodiscard
---@async
function facepunch.getManifest( timeout )
    local f = Future()

    glua_GetAPIManifest( function( json_str )
        -- the timeout has already rejected the future
        if not f:isPending() then
            return
        end

        if json_str == nil then
            f:setError( "failed to get manifest from Facepunch API, unknown error" )
            return
        end

        local data = json_deserialize( json_str )
        if data == nil then
            f:setError( "failed to get manifest from Facepunch API, invalid JSON" )
        else
            f:setResult( data )
        end
    end )

    if timeout == nil then
        timeout = 30
    end

    if timeout > 0 then
        setTimeout( function()
            if f:isPending() then
                f:setError( "failed to get manifest from Facepunch API, timed out" )
            end
        end, timeout )
    end

    return f:await()
end
