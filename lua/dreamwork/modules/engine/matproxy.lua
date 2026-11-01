---@class dreamwork.engine
local dreamwork_engine = dreamwork.engine

---@class garrysmod.matproxy
local glua_matproxy = dreamwork_engine.requireLibrary( "matproxy" )

---@type table<string, garrysmod.MatProxyData>
local proxy_list = glua_matproxy.ProxyList or {}
glua_matproxy.ProxyList = proxy_list

---@type table<string, garrysmod.MatProxyInstance>
local active_list = glua_matproxy.ActiveList or {}
glua_matproxy.ActiveList = active_list

-- TODO: matproxy
--
-- ref: https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/modules/matproxy.lua
