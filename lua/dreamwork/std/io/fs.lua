local glua_file = file or {}

---@class dreamwork.std
local std = dreamwork.std

local LUA_CLIENT = std.LUA_CLIENT
local LUA_SERVER = std.LUA_SERVER
local LUA_MENU = std.LUA_MENU

local pcall = std.pcall

local debug = std.debug
local debug_fempty = debug.fempty

local string = std.string

local console = std.console

local file_Time = glua_file.Time or function() return 0 end
local file_Find = glua_file.Find or function() return {}, {} end
local file_Size = glua_file.Size or function() return 0 end
local file_Open = glua_file.Open or debug_fempty
local file_IsDir = glua_file.IsDir or function() return false end
local file_Exists = glua_file.Exists or function() return false end
local file_Delete = glua_file.Delete or debug_fempty
local file_CreateDir = glua_file.CreateDir or debug_fempty

do

    local glua_require = require or debug_fempty

    local SYSTEM_WINDOWS = std.SYSTEM_WINDOWS
    local SYSTEM_LINUX = std.SYSTEM_LINUX
    local SYSTEM_X32 = std.SYSTEM_X32

    local jit_edge = std.jit.edge

    local head = "lua/bin/gm" .. (LUA_CLIENT and "cl" or "sv") .. "_"
    local tail = "_" .. std.SYSTEM_NAME

    --- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
    ---
    --- Checks if a binary module is available and can be loaded.
    ---
    ---@param name string The binary module name.
    ---@return boolean installed `true` if binary module is available, `false` otherwise.
    ---@return string abs_path The absolute path to binary module.
    local function lookupbinary( name )
        local file_path = head .. name .. tail

        local dll_path = file_path .. ".dll"
        if file_Exists( dll_path, "MOD" ) then
            return true, "/garrysmod/" .. dll_path
        end

        local so_path = file_path .. ".so"
        if file_Exists( so_path, "MOD" ) then
            return true, "/garrysmod/" .. so_path
        end

        if jit_edge and SYSTEM_LINUX and SYSTEM_X32 then
            file_path = head .. name .. "_linux32"

            dll_path = file_path .. ".dll"
            if file_Exists( dll_path, "MOD" ) then
                return true, "/garrysmod/" .. dll_path
            end

            so_path = file_path .. ".so"
            if file_Exists( so_path, "MOD" ) then
                return true, "/garrysmod/" .. so_path
            end
        end

        return false, "/garrysmod/" .. file_path .. (SYSTEM_WINDOWS and ".dll" or ".so")
    end

    std.lookupbinary = lookupbinary

    local sv_allowcslua

    if LUA_SERVER then
        sv_allowcslua = console.Variable.get( "sv_allowcslua", "boolean" )
    end

    --- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
    ---
    --- Loads a binary module if available.
    ---
    ---@param name string The binary module name, for example: "chttp".
    ---@return boolean success `true` if binary module is successfully installed, `false` otherwise.
    function std.loadbinary( name )
        if lookupbinary( name ) then
            if sv_allowcslua ~= nil and sv_allowcslua.value then
                sv_allowcslua.value = false
            end

            return pcall( glua_require, name )
        end

        return false
    end

end

---@class dreamwork.std.fs.MountInfo
---@field writable boolean If `true` mount allows creating directories inside.
---@field writable_extensions table<string, boolean> The extension map of allowed extensions to write.
---@field deletable boolean If `true` mount allows deleting files and directories.

---@type table<string, dreamwork.std.fs.MountInfo>
local mount_infos = {
    [ "DATA" ] = {
        writable = true,
        deletable = true,
        writable_extensions = {
            -- Taken from https://wiki.facepunch.com/gmod/file.Write
            txt = true,
            dat = true,
            json = true,
            xml = true,
            csv = true,
            dem = true,
            vcd = true,
            gma = true,
            mdl = true,
            phy = true,
            vvd = true,
            vtx = true,
            ani = true,
            vtf = true,
            vmt = true,
            png = true,
            jpg = true,
            jpeg = true,
            mp3 = true,
            wav = true,
            ogg = true
        }
    },
    [ "MOD" ] = {
        writable = false,
        deletable = LUA_MENU,
        writable_extensions = {}
    }
}

---@type table<string, boolean>
local restricted_names = {
    [ "^dreamwork_tmp$.dat" ] = true,
    [ ".." ] = true,
    [ "." ] = true,
    [ "" ] = true
}


-- TODO: https://wiki.facepunch.com/gmod/resource.AddFile & https://wiki.facepunch.com/gmod/resource.AddSingleFile
-- TODO: https://wiki.facepunch.com/gmod/Global.AddCSLuaFile

-- TODO: https://github.com/RaphaelIT7/gmod-holylib#filesystem
