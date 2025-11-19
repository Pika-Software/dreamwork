---@class dreamwork.std
local std = _G.dreamwork.std


--- [SHARED AND MENU]
---
--- The audio stream object.
---
---@class dreamwork.std.AudioStream : dreamwork.Object
---@field __class dreamwork.std.AudioStreamClass
local AudioStream = std.class.base( "AudioStream" )

---@class dreamwork.std.AudioStreamClass : dreamwork.std.AudioStream
---@field __base dreamwork.std.AudioStream
---@overload fun(): dreamwork.std.AudioStream
local AudioStreamClass = std.class.create( AudioStream )
std.AudioStream = AudioStreamClass

do

    local function fromURL( self, url )

    end

    local function fromFile( self, path )

    end

    ---@protected
    function AudioStream:__init( location )
        if std.isurl( location ) then
            fromURL( self, location )
        else
            fromFile( self, location )
        end
    end

end

-- TODO: https://github.com/thegrb93/StarfallEx/blob/master/lua/starfall/libs_cl/bass.lua
