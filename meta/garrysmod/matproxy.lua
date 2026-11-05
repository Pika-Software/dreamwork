---@meta garrysmod.matproxy


--- [CLIENT]
---
--- The definition of a material proxy, see `matproxy.Add`.
---
---@class garrysmod.MatProxyData
---@field name string The name of the proxy, as used in the `.vmt` file.
---@field init ( fun( self: garrysmod.MatProxyData, material: garrysmod.Material, key_values: garrysmod.Material.KeyValues ) | nil ) Called once when the proxy is applied to a material, only called if `bind` is set.
---@field bind fun( self: garrysmod.MatProxyData, material: garrysmod.Material, entity: garrysmod.Entity ) Called every time the material is bound for rendering with the entity it is rendered on, required.

--- [CLIENT]
---
--- An active instance of a material proxy, a copy of its `garrysmod.MatProxyData` created per material.
---
---@class garrysmod.MatProxyInstance : garrysmod.MatProxyData
---@field Material garrysmod.Material The material the proxy is applied to.
---@field Values garrysmod.Material.KeyValues The `.vmt` shader parameters of the material.

--- [CLIENT]
---
--- A library that allows implementing custom [material proxies](https://developer.valvesoftware.com/wiki/Material_proxies) for materials.
---
--- Material proxies allow programmatically setting specific `.vmt` shader parameters on a per-entity basis,
--- rather than being global across all instances of a material.
---
--- You can find a tutorial for making colourable textures over at this [GitHub wiki](https://github.com/fgrg2801/gmod-colorable-playermodels/wiki).
---
---@class garrysmod.matproxy
---@field ProxyList table<string, garrysmod.MatProxyData> The registered proxies by name.
---@field ActiveList table<string, garrysmod.MatProxyInstance> The active proxy instances by their instance name.
matproxy = {}

--- [CLIENT]
---
--- Registers a material proxy.
---
--- If a proxy with the same name is already registered, it is replaced
--- and all its active instances are re-initialized.
---
--- > NOTE: The `name` and `bind` fields are required, the proxy is silently ignored without them.
--- > The `init` function won't run without `bind` set.
---
---@param proxy garrysmod.MatProxyData The information about the proxy.
function matproxy.Add( proxy ) end

--- [CLIENT]
---
--- Called by the engine from `OnBind`. Calls the `bind` method of the Lua material proxy.
---
---@param uname string The name of the active material proxy instance.
---@param material garrysmod.Material The material the proxy is being applied to.
---@param entity garrysmod.Entity The entity the material is applied to.
function matproxy.Call( uname, material, entity ) end

--- [CLIENT]
---
--- Called by the engine from `OnBind`. Creates an active instance of the proxy and calls its `init` method.
---
---@param name string The name of the material proxy.
---@param uname string The name for the active material proxy instance.
---@param material garrysmod.Material The material the material proxy is applied to.
---@param key_values garrysmod.Material.KeyValues The `.vmt` shader parameters of the material.
function matproxy.Init( name, uname, material, key_values ) end

--- [CLIENT]
---
--- Called by the engine to determine if a certain material proxy is registered in Lua.
---
---@param name string The name of the proxy in question.
---@return boolean is_registered `true` if a material proxy of the given name is registered.
function matproxy.ShouldOverrideProxy( name ) end
