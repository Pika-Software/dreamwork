---@class dreamwork.engine
local dreamwork_engine = dreamwork.engine

---@type garrysmod.system
local glua_system = dreamwork_engine.requireLibrary( "system" )
local system_HasFocus = glua_system.HasFocus


---@class dreamwork.std
local std = dreamwork.std

local debug = std.debug
local debug_fempty = debug.fempty


--- [CLIENT AND MENU]
---
--- The game's window library.
---
---@class dreamwork.std.window
---@field width number The width of the game's window (in pixels).
---@field height number The height of the game's window (in pixels).
---@field focus boolean `true` if the game's window has focus, `false` otherwise.
local window = std.window or { focus = true }
std.window = window


local width, height = ScrW(), ScrH()
window.width, window.height = width, height

if window.SizeChanged == nil then

    local SizeChanged = std.Hook( "window.SizeChanged" )
    window.SizeChanged = SizeChanged

    dreamwork.engine.hook.catch( "OnScreenSizeChanged", "screen.size.change", function( old_width, old_height, new_width, new_height )
        width, height = new_width, new_height
        window.width, window.height = new_width, new_height
        SizeChanged( new_width, new_height, old_width, old_height )
    end, 1 )

end

if system_HasFocus ~= nil then

    local has_focus = system_HasFocus()
    window.focus = has_focus

    dreamwork.TickTimer[ 0.25 ]:attach( function()
        if has_focus ~= system_HasFocus() then
            has_focus = not has_focus
            window.focus = has_focus
        end
    end )

end

window.flash = glua_system.FlashWindow or debug_fempty

do

    local system_IsWindowed = glua_system.IsWindowed or function() return true end
    window.isWindowed = system_IsWindowed


    --- [CLIENT AND MENU]
    ---
    --- Returns whether the game window is fullscreen.
    ---
    ---@return boolean is_on `true` if the game window is fullscreen, `false` if not.
    ---@nodiscard
    function window.isFullscreen()
        return not system_IsWindowed()
    end

end
