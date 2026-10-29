---@meta _

---@class Module : Object
---@field file File
local Module = {}

function Module:__gc() end

---@class ModuleClass : Module
local ModuleClass = {}

---@class Package: Object
---@field __class PackageClass
---@field name string
---@field version Version
---@field prefix string
---@field commands table
local Package = {}

---@class PackageClass : Package
---@field __base Package
---@overload fun( name: string, version: ( string | Version ) ): Package
local PackageClass = {}

---@param name string
---@param version string
---@protected
function Package:__init(name, version) end

---@protected
function PackageClass:__new(name, version) end

function PackageClass.getName() end

function PackageClass.getMountName() end
