---@class dreamwork.std
local std = _G.dreamwork.std

local string = std.string
local string_interpolate = string.interpolate

---@class dreamwork.std.i18n
local i18n = std.i18n or {}
std.i18n = i18n

---@type table<string, string>
local map = {}

---@param key string
---@param arguments string[] | table<string, string>
---@return string
function i18n.get( key, arguments )
    local value = map[ key ]
    if value == nil then
        return key
    end

    if arguments == nil then
        return value
    end

    return string_interpolate( value, arguments )
end

---@param key string
---@param value string
function i18n.set( key, value )
    map[ key ] = value
end

---@param language_code string
function i18n.load( language_code )

end

--[[
    TODO:

        https://github.com/alerque/fluent-lua
        https://github.com/Pika-Software/plib_translate
        https://wiki.facepunch.com/gmod/language
        https://projectfluent.org/

]]
