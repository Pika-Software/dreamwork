---@class dreamwork
local dreamwork = _G.dreamwork
local std = dreamwork.std

local string = std.string
local string_len = string.len
local string_match = string.match
local string_findByte = string.findByte
local string_byteSplit = string.byteSplit

local table = std.table
local table_concat = table.concat

--- [SHARED AND MENU]
---
--- Dreamwork Code Fabric
---
--- Library for code pre-build and exclusive features.
---
---@class dreamwork.factory
local factory = dreamwork.factory or {}
dreamwork.factory = factory

--[[

    TODO: Concept

    #if defined( SERVER )

        server.tickrate.set( 60 )

    #else

        #include( "./client.lua" )

    #endif

]]

--[[

    https://www.geeksforgeeks.org/cpp/cpp-preprocessors-and-directives/
    https://github.com/ReFreezed/LuaPreprocess



    <name> - always a string, if string is empty then causes an #error
    <value> - always a string, if string is empty, then the value is `nil`
    <code> - always a string, if string is empty then causes an #error


    > variables:

    #global <name> <value> -> defines a global variable, accessible in all files

    #local <name> <value> -> defines a local variable, accessible only in the current file

    #define -> #local <name> <value>

    #undef -> #local <name>


    > conditions:

    #if / #elif / #else / #endif -> separate lua compilation with a condition, aka #if <code> / #elif <code> / #else / #endif

    #ifdef / #ifndef -> just checks that a variable not equal to nil (exists), aka #ifdef <name> / #ifndef <name>


    > binary modules:

    #load <file_path> -> preloads the specified binary module, do nothing if the module is already loaded


    > insertion:

    #include <file_path> <ignore if already included> -> inserts the contents of the file into the current file, do nothing if the file is already included
    #compile / #endcompile -> separate lua compilation, if return result not nil then the result will be included as string in code


    > notices:

    #info <message> -> produces an information notice

    #warn <message> -> produces a warning notice

    #error <message> -> halts compilation process and produces an error notice

    #debug <message> -> produces a debug notice


--]]


---@class dreamwork.factory.PreprocessorStatement
---@field locals table<string, string>
---@field lines string[]
---@field line integer

---@class dreamwork.factory.PreprocessorResult
---@field lines table<integer, integer>
---@field line_count integer
---@field code string

---@alias dreamwork.factory.PreprocessorDirective fun( statement: dreamwork.factory.PreprocessorStatement, parameters: string ): string | nil

---@type integer
local exclamation_mark = 0x23 --[[ # ]]

---@type table<string, dreamwork.factory.PreprocessorDirective>
local directives = {}
