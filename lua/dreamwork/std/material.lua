---@class dreamwork.std
local std = dreamwork.std

--[[

    TODO:

    https://wiki.facepunch.com/gmod/Global.Material

    https://wiki.facepunch.com/gmod/Global.CreateMaterial

    https://wiki.facepunch.com/gmod/Global.DynamicMaterial

    https://wiki.facepunch.com/gmod/Material_Parameters

]]

local Material = std.class.base( "Material" )

local MaterialClass = std.class.create( Material )
std.Material = MaterialClass
