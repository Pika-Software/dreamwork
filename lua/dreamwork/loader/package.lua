local _G = _G

---@class dreamwork
local dreamwork = _G.dreamwork

local std = dreamwork.std
local class = std.class
local Version = std.Version

---@class dreamwork.Package: dreamwork.Object
---@field __class dreamwork.PackageClass
---@field name string
---@field version Version
---@field prefix string
---@field commands table
local Package = class.base( "Package", true )

---@class dreamwork.PackageClass: dreamwork.Package
---@field __base dreamwork.Package
---@overload fun( name: string, version: string | Version ): Package
local PackageClass = class.create( Package )
dreamwork.Package = PackageClass

local cache = {}

--[[

    Package: {
        name: string
        prefix: string
        version: Version
        environment: table ( _ENV )
    }

    https://stackoverflow.com/questions/12021461/lua-setfenv-vs-env

]]

---@param name string
---@param version string | Version
---@protected
function Package:__init( name, version )
    local prefix = name .. "@" .. version
    self.prefix = prefix

    self.version = Version( version )

    package.console_variables = {}
    package.console_commands = {}
    cache[ prefix ] = self
end

---@protected
function PackageClass:__new( name, version )
    return cache[ name .. "@" .. version ]
end

local debug_getmetatable = std.debug.getmetatable
local debug_getfmain = std.debug.getfmain
local getfenv = std.getfenv
local raw_get = std.raw.get

function PackageClass.getName()
    local fn = debug_getfmain()
    if fn ~= nil then
        local fenv = getfenv( fn )
        if fenv ~= nil then
            local metatable = debug_getmetatable( fenv )
            if metatable ~= nil then
                return raw_get( metatable, "__package" )
            end
        end
    end

    return "base"
end

function PackageClass.getMountName()
    local fn = debug_getfmain()
    if fn ~= nil then
        local fenv = getfenv( fn )
        if fenv ~= nil then
            local metatable = debug_getmetatable( fenv )
            if metatable ~= nil then
                return raw_get( metatable, "__mount" )
            end
        end
    end

    return "GAME"
end
