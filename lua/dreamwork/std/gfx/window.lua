---@class dreamwork.GModSystemLib
---@field IsWindowed fun(): boolean
---@field FlashWindow fun()
---@diagnostic disable-next-line: undefined-global
local glua_system = system or {}
local system_IsWindowed = glua_system.IsWindowed or function() return true end
local system_FlashWindow = glua_system.FlashWindow or function() print( "dw: window flash" ) end

---@type fun(): number
---@diagnostic disable-next-line: undefined-global
local ScrW = ScrW or function() return 0 end

---@type fun(): number
---@diagnostic disable-next-line: undefined-global
local ScrH = ScrH or function() return 0 end


---@class dreamwork.std
local std = dreamwork.std


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

    dreamwork.engine.hookCatch( "OnScreenSizeChanged", "screen.size.change", function( old_width, old_height, new_width, new_height )
        width, height = new_width, new_height
        window.width, window.height = new_width, new_height
        SizeChanged( new_width, new_height, old_width, old_height )
    end, 1 )

end

window.isWindowed = system_IsWindowed
window.flash = system_FlashWindow

--- [CLIENT AND MENU]
---
--- Returns whether the game window is fullscreen.
---
---@return boolean is_on `true` if the game window is fullscreen, `false` if not.
function window.isFullscreen()
    return not system_IsWindowed()
end

local system_HasFocus = glua_system.HasFocus
if system_HasFocus ~= nil then

    local has_focus = system_HasFocus()
    window.focus = has_focus

    dreamwork.TickTimer0_05:attach( function()
        if has_focus ~= system_HasFocus() then
            has_focus = not has_focus
            window.focus = has_focus
        end
    end, "dreamwork::window_focus" )

end
