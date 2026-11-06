---@meta _

--- [CLIENT AND MENU]
---
--- An error raised by the WebAssembly runtime (compile / link / trap / bad export access).
---
---@class WASMError : Error
---@field __class WASMErrorClass
---@field __parent Error
---@field message string | nil The error message reported by the browser.
local __WASMError = {}

--- [CLIENT AND MENU]
---
--- The class used to create new `WASMError` instances.
---
---@class WASMErrorClass : WASMError, ErrorClass
---@field __base WASMError
---@field __parent ErrorClass
---@overload fun( message: ( string | nil ) ): WASMError

---@type WASMErrorClass
WASMError = nil

---@alias WASM.ValueType
---| "i32"
---| "i64" # Arrives in Lua as `BigInteger`; accepts `BigInteger`, integers or decimal strings.
---| "f32"
---| "f64"
---| "v128" # Not callable from JavaScript.
---| "funcref"
---| "externref"

--- [CLIENT AND MENU]
---
--- Description of one module export.
---
--- `params` / `results` are present for functions when the module type section could be parsed.
---
---@class WASM.Export
---@field name string The export name.
---@field kind "function" | "memory" | "global" | "table" The export kind.
---@field params WASM.ValueType[] | nil Function parameter types.
---@field results WASM.ValueType[] | nil Function result types.

--- Lua side of an import: a Lua function (fire-and-forget, JS receives `undefined`)
--- or a JavaScript expression evaluated in the page (function, `WebAssembly.Memory`, `WebAssembly.Global`, ...).
---
---@alias WASM.Import fun( ...: any ) | string

---@alias WASM.Imports table<string, table<string, WASM.Import>>

---@alias WASM.Decoder fun( values: any[] ): any

--- [CLIENT AND MENU]
---
--- A WebAssembly module instantiated inside a headless `WebClient` (Chromium).
---
--- Every call crosses the CEF bridge, which is asynchronous: methods marked `@async` must run inside
--- a coroutine (`futures.run`), the `invoke` / `*Future` style methods return a `Future` for plain callbacks.
---
--- Values: `i32` / `f32` / `f64` are Lua numbers, `i64` is a `BigInteger` (integers and
--- decimal strings are accepted as arguments). Multi-value results come back as an array.
---
--- Imports are either JavaScript expressions (evaluated in the page) or Lua functions; Lua imports
--- are fire-and-forget, the bridge cannot return a value to WebAssembly synchronously, so they act
--- as `undefined` (`0` for numeric results, a trap for `i64`).
---
--- Requires the x86-64 (Chromium) branch of Garry's Mod, Awesomium has no WebAssembly.
---
---@class WASM : Object
---@field __class WASMClass
---@field exports table<string, async fun( ...: any ): ...: any> Async callable proxy: `wasm.exports.add( 2, 3 )` behaves like `wasm:call( "add", 2, 3 )`.
---@field client WebClient | nil The hosting `WebClient`, `nil` once closed.
local __WASM = {}

---@param key string
---@return any
---@protected
function __WASM:__index(key) end

---@return string
---@protected
function __WASM:__represent() end

---@param binary string The raw `.wasm` module bytes.
---@param imports WASM.Imports? Import object, `{ env = { log = function( x ) end, now = "() => Date.now()" } }`.
---@protected
function __WASM:__init(binary, imports) end

--- Closes the hosting client when the object is collected.
---
---@protected
function __WASM:__gc() end

--- [CLIENT AND MENU]
---
--- Returns `true` while the hosting client is alive.
---
---@return boolean is_valid
---@nodiscard
function __WASM:__isvalid() end

--- [CLIENT AND MENU]
---
--- Returns `true` once the module is compiled and instantiated.
---
---@return boolean is_ready
---@nodiscard
function __WASM:isReady() end

--- [CLIENT AND MENU]
---
--- Returns the `Future` resolved once the module is instantiated, failed with a `WASMError`
--- on compile / link errors.
---
---@return Future<boolean> future
---@nodiscard
function __WASM:getLoadFuture() end

--- [CLIENT AND MENU]
---
--- Waits until the module is instantiated; throws a `WASMError` if compiling or linking failed.
---
---@return WASM self
---@async
function __WASM:await() end

--- [CLIENT AND MENU]
---
--- Returns the module exports, `nil` until ready. Do not modify the returned tables.
---
---@return WASM.Export[] | nil exports
---@nodiscard
function __WASM:getExports() end

--- [CLIENT AND MENU]
---
--- Returns the description of the export `name`, `nil` if missing or not ready yet.
---
---@param name string
---@return WASM.Export | nil export
---@nodiscard
function __WASM:getExport(name) end

--- [CLIENT AND MENU]
---
--- Calls the exported function `name`, returning a `Future` with its result
--- (`nil`, the single value, or an array for multi-value returns).
---
--- Calls made before the module is ready are queued in the page.
---
---@param name string The export name.
---@param ... any Arguments: numbers, `BigInteger`s (`i64`), strings or booleans.
---@return Future future
function __WASM:invoke(name, ...) end

--- [CLIENT AND MENU]
---
--- Calls the exported function `name` and waits for its results.
---
--- ```lua
--- futures.run( function()
---     print( wasm:call( "add", 2, 3 ) ) -- 5
--- end )
--- ```
---
---@param name string The export name.
---@param ... any Arguments: numbers, `BigInteger`s (`i64`), strings or booleans.
---@return any ... The results, multi-value returns are unpacked.
---@async
function __WASM:call(name, ...) end

--- [CLIENT AND MENU]
---
--- Reads `length` bytes of linear memory starting at `offset`.
---
---@param offset integer The byte offset.
---@param length integer The number of bytes.
---@param memory string? The memory export name, defaults to the first exported memory.
---@return Future<string> future
function __WASM:readFuture(offset, length, memory) end

--- [CLIENT AND MENU]
---
--- Reads `length` bytes of linear memory starting at `offset`.
---
---@param offset integer The byte offset.
---@param length integer The number of bytes.
---@param memory string? The memory export name, defaults to the first exported memory.
---@return string data
---@async
function __WASM:read(offset, length, memory) end

--- [CLIENT AND MENU]
---
--- Writes `data` into linear memory at `offset`.
---
---@param offset integer The byte offset.
---@param data string The bytes to write.
---@param memory string? The memory export name, defaults to the first exported memory.
---@return Future future
function __WASM:writeFuture(offset, data, memory) end

--- [CLIENT AND MENU]
---
--- Writes `data` into linear memory at `offset` and waits until it is written.
---
---@param offset integer The byte offset.
---@param data string The bytes to write.
---@param memory string? The memory export name, defaults to the first exported memory.
---@async
function __WASM:write(offset, data, memory) end

--- [CLIENT AND MENU]
---
--- Returns the linear memory size in bytes.
---
---@param memory string? The memory export name, defaults to the first exported memory.
---@return integer size
---@async
function __WASM:getMemorySize(memory) end

--- [CLIENT AND MENU]
---
--- Grows linear memory by `pages` 64 KiB pages, returns the previous size in pages.
---
---@param pages integer The number of pages to add.
---@param memory string? The memory export name, defaults to the first exported memory.
---@return integer previous_pages
---@async
function __WASM:growMemory(pages, memory) end

--- [CLIENT AND MENU]
---
--- Returns the value of the exported global `name`.
---
---@param name string The global export name.
---@return number | BigInteger value
---@async
function __WASM:getGlobal(name) end

--- [CLIENT AND MENU]
---
--- Sets the value of the exported mutable global `name`.
---
---@param name string The global export name.
---@param value number | BigInteger The new value.
---@async
function __WASM:setGlobal(name, value) end

--- [CLIENT AND MENU]
---
--- Destroys the hosting client, pending requests fail with a `WASMError`.
---
function __WASM:close() end

--- [CLIENT AND MENU]
---
--- The class used to create new `WASM` instances.
---
--- ```lua
--- local wasm = WASM( file.read( "add.wasm" ), {
---     env = {
---         log = function( value ) print( "wasm says", value ) end, -- Lua, fire-and-forget
---         now = "() => Date.now()" -- JavaScript expression
---     }
--- } )
---
--- futures.run( function()
---     wasm:await()
---     print( wasm.exports.add( 2, 3 ) ) -- 5
---     print( wasm:read( 0, 16 ) )
--- end )
--- ```
---
---@class WASMClass : WASM, Class
---@field __base WASM
---@overload fun( binary: string, imports: WASM.Imports? ): WASM
WASM = {}
