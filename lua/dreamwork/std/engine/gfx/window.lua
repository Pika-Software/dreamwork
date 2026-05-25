---@class dreamwork.std
local std = dreamwork.std
local _G = _G

--- [CLIENT AND MENU]
---
--- The game's window library.
---
---@class dreamwork.std.window
---@field width number The width of the game's window (in pixels).
---@field height number The height of the game's window (in pixels).
local window = std.window or { focus = true }
std.window = window

window.openFolder = window.openFolder or _G.OpenFolder or std.debug.fempty


local width, height = _G.ScrW(), _G.ScrH()
window.width, window.height = width, height

if window.SizeChanged == nil then

    local SizeChanged = std.Hook( "window.SizeChanged" )
    window.SizeChanged = SizeChanged

    dreamwork.engine.hookCatch( "OnScreenSizeChanged", function( old_width, old_height, new_width, new_height )
        width, height = new_width, new_height
        window.width, window.height = new_width, new_height
        SizeChanged( new_width, new_height, old_width, old_height )
    end, 1 )

end

local glua_system = _G.system
if glua_system ~= nil then

    window.isWindowed = window.isWindowed or glua_system.IsWindowed or function() return true end
    window.flash = window.flash or glua_system.FlashWindow or std.debug.fempty

    if window.isFullscreen == nil then

        local system_IsWindowed = window.isWindowed

        --- [CLIENT AND MENU]
        ---
        --- Returns whether the game window is fullscreen.
        ---
        ---@return boolean is_on `true` if the game window is fullscreen, `false` if not.
        function window.isFullscreen()
            return not system_IsWindowed()
        end

    end

end
