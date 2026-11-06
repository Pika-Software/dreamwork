---@class dreamwork.std
local std = dreamwork.std

local class = std.class

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local raw = std.raw
local raw_index = raw.index
local raw_pairs = raw.pairs
local raw_select = raw.select
local raw_tostring = raw.tostring

local string = std.string
local string_format = string.format

local table = std.table
local table_unpack = table.unpack
local table_concat = table.concat

local math = std.math
local math_huge = math.huge
local math_nan = math.nan

local type = std.type
local error = std.error
local setmetatable = std.setmetatable
local isTable = std.isTable
local isString = std.isString
local isNumber = std.isNumber
local isBoolean = std.isBoolean
local isFunction = std.isFunction
local isBigInteger = std.isBigInteger

local exceptions_call = dreamwork.exceptions.call

local json = std.json
local json_serialize = json.serialize
local json_deserialize = json.deserialize

local base64 = std.base64
local base64_encode = base64.encode
local base64_decode = base64.decode

local Future = std.Future
local WebClient = std.WebClient
local BigInteger = std.BigInteger
local ValueError = std.ValueError


--- [CLIENT AND MENU]
---
--- An error raised by the WebAssembly runtime (compile / link / trap / bad export access).
---
---@class dreamwork.std.WASMError : dreamwork.std.Error
---@field __class dreamwork.std.WASMErrorClass
---@field __parent dreamwork.std.Error
---@field message string | nil The error message reported by the browser.
local WASMError = class.base( "WASMError", false, std.Error )

--- [CLIENT AND MENU]
---
--- The class used to create new `WASMError` instances.
---
---@class dreamwork.std.WASMErrorClass : dreamwork.std.WASMError, dreamwork.std.ErrorClass
---@field __base dreamwork.std.WASMError
---@field __parent dreamwork.std.ErrorClass
---@overload fun( message: ( string | nil ) ): dreamwork.std.WASMError

---@type dreamwork.std.WASMErrorClass
local WASMErrorClass = class.create( WASMError ) --[[@as dreamwork.std.WASMErrorClass]]
std.WASMError = WASMErrorClass


--- Browser side of the runtime: loads one module per page and answers requests through `dwasm.*`.
---
--- Every request replies with `dwasm.reply( id, ok, payload )`, `payload` is a JSON array of results
--- (`{"i64":"..."}` for BigInt, `{"f":"NaN"}` for non-finite floats) or the error message.
local RUNTIME_HTML = [[<!DOCTYPE html><html><head><meta charset="utf-8"><script>
(function(){
var W={p:null,i:null,s:{}};
function b64d(s){var b=atob(s),n=b.length,u=new Uint8Array(n);for(var i=0;i<n;i++)u[i]=b.charCodeAt(i);return u}
function b64e(u){var s='';for(var i=0;i<u.length;i+=32768)s+=String.fromCharCode.apply(null,u.subarray(i,i+32768));return btoa(s)}
function enc(v){return JSON.stringify(v,function(k,x){if(typeof x==='bigint')return{i64:x.toString()};if(typeof x==='number'&&!isFinite(x))return{f:String(x)};return x})}
function msg(e){return(e&&e.message!==undefined)?((e.name&&e.name!=='Error'?e.name+': ':'')+e.message):String(e)}
function sigs(u){
var p=8,T=[],F=[],R={},V={127:'i32',126:'i64',125:'f32',124:'f64',123:'v128',112:'funcref',111:'externref'};
function b(){return u[p++]}
function n(){var r=0,s=1,x;do{x=u[p++];r+=(x&127)*s;s*=128}while(x&128);return r}
function str(){var l=n(),s=new TextDecoder().decode(u.subarray(p,p+l));p+=l;return s}
function vt(){var t=V[b()];if(!t)throw 0;return t}
function vec(f){var c=n(),a=[];for(var i=0;i<c;i++)a.push(f());return a}
function lim(){var f=b();n();if(f&1)n()}
try{while(p<u.length){var id=b(),sz=n(),e=p+sz;
if(id===1)T=vec(function(){if(b()!==96)throw 0;var a=vec(vt);return{p:a,r:vec(vt)}});
else if(id===2)vec(function(){str();str();var k=b();if(k===0)F.push(T[n()]);else if(k===1){b();lim()}else if(k===2)lim();else if(k===3){b();b()}else throw 0});
else if(id===3)vec(function(){F.push(T[n()])});
else if(id===7)vec(function(){var m=str(),k=b(),i=n();if(k===0&&F[i])R[m]=F[i]});
p=e}}catch(x){}
return R}
function ok(id,v){dwasm.reply(id,true,enc(v))}
function op(id,f){if(!W.p){dwasm.reply(id,false,'module is not loaded');return}W.p.then(function(){ok(id,f())}).catch(function(e){dwasm.reply(id,false,msg(e))})}
function ex(n,c,t){var v=W.i.exports[n];if(!(v instanceof c))throw new Error("export '"+n+"' is not a "+t);return v}
function mem(n){if(n)return ex(n,WebAssembly.Memory,'memory');var e=W.i.exports;for(var k in e)if(e[k] instanceof WebAssembly.Memory)return e[k];throw new Error('module exports no memory')}
window.__dw={
load:function(b,spec){
if(typeof WebAssembly!=='object'){dwasm.fail('WebAssembly is not supported by this browser (x86-64 Chromium branch required)');return}
var u=b64d(b);W.s=sigs(u);
W.p=WebAssembly.compile(u).then(function(mod){
var imp={};
WebAssembly.Module.imports(mod).forEach(function(d){
var m=imp[d.module]||(imp[d.module]={}),s=spec[d.module],v=s&&s[d.name];
if(v===true)m[d.name]=function(){dwasm.call(d.module,d.name,enc([].slice.call(arguments)))};
else if(typeof v==='string')m[d.name]=(0,eval)('('+v+')');
else if(d.kind==='function')m[d.name]=function(){throw new Error("missing import '"+d.module+"."+d.name+"'")}});
return WebAssembly.instantiate(mod,imp).then(function(inst){
W.i=inst;
dwasm.ready(JSON.stringify(WebAssembly.Module.exports(mod).map(function(d){var s=W.s[d.name];return(s&&d.kind==='function')?{name:d.name,kind:d.kind,params:s.p,results:s.r}:{name:d.name,kind:d.kind}})))})});
W.p.catch(function(e){dwasm.fail(msg(e))})},
call:function(id,n,a){op(id,function(){var f=W.i.exports[n];if(typeof f!=='function')throw new Error("export '"+n+"' is not a function");var s=W.s[n];if(s)for(var i=0;i<s.p.length;i++)if(s.p[i]==='i64')a[i]=BigInt(a[i]===undefined?0:a[i]);var r=f.apply(null,a);if(s)return s.r.length===0?[]:(s.r.length===1?[r]:r);return r===undefined?[]:(Array.isArray(r)?r:[r])})},
read:function(id,n,o,l){op(id,function(){return[b64e(new Uint8Array(mem(n).buffer,o,l))]})},
write:function(id,n,o,b){op(id,function(){new Uint8Array(mem(n).buffer).set(b64d(b),o);return[]})},
size:function(id,n){op(id,function(){return[mem(n).buffer.byteLength]})},
grow:function(id,n,d){op(id,function(){return[mem(n).grow(d)]})},
get:function(id,n){op(id,function(){return[ex(n,WebAssembly.Global,'global').value]})},
set:function(id,n,v){op(id,function(){var g=ex(n,WebAssembly.Global,'global');g.value=(typeof g.value==='bigint')?BigInt(v):v;return[]})}
};
})();
</script></head><body></body></html>]]


---@alias dreamwork.std.WASM.ValueType
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
---@class dreamwork.std.WASM.Export
---@field name string The export name.
---@field kind "function" | "memory" | "global" | "table" The export kind.
---@field params dreamwork.std.WASM.ValueType[] | nil Function parameter types.
---@field results dreamwork.std.WASM.ValueType[] | nil Function result types.

--- Lua side of an import: a Lua function (fire-and-forget, JS receives `undefined`)
--- or a JavaScript expression evaluated in the page (function, `WebAssembly.Memory`, `WebAssembly.Global`, ...).
---
---@alias dreamwork.std.WASM.Import fun( ...: any ) | string

---@alias dreamwork.std.WASM.Imports table<string, table<string, dreamwork.std.WASM.Import>>

---@alias dreamwork.std.WASM.Decoder fun( values: any[] ): any

--- Live instances by id, bridge callbacks resolve their owner through it so the
--- `WebClient` (kept alive by the engine panel) never holds the `WASM` object strongly.
---
---@type table<integer, dreamwork.std.WASM>
local instances = {}
gc_setTableRules( instances, false, true )

---@type integer
local instance_count = 0

---@type table<dreamwork.std.WASM, dreamwork.std.WebClient>
local clients = {}
gc_setTableRules( clients, true, false )

---@type table<dreamwork.std.WASM, dreamwork.std.Future>
local loads = {}
gc_setTableRules( loads, true, false )

---@type table<dreamwork.std.WASM, dreamwork.std.WASM.Export[]>
local export_lists = {}
gc_setTableRules( export_lists, true, false )

---@type table<dreamwork.std.WASM, table<string, dreamwork.std.WASM.Export>>
local export_maps = {}
gc_setTableRules( export_maps, true, false )

---@type table<dreamwork.std.WASM, dreamwork.std.WASM.Imports>
local import_tables = {}
gc_setTableRules( import_tables, true, false )

---@type table<dreamwork.std.WASM, table<integer, dreamwork.std.Future>>
local pending_futures = {}
gc_setTableRules( pending_futures, true, false )

---@type table<dreamwork.std.WASM, table<integer, dreamwork.std.WASM.Decoder>>
local pending_decoders = {}
gc_setTableRules( pending_decoders, true, false )

---@type table<dreamwork.std.WASM, integer>
local request_counts = {}
gc_setTableRules( request_counts, true, false )

---@type table<dreamwork.std.WASM, table>
local export_proxies = {}
gc_setTableRules( export_proxies, true, false )


--- Converts a JS → Lua payload value (`{"i64":...}` / `{"f":...}` markers) into a Lua value.
---
---@param value any
---@return any
local function decode_value( value )
    if isTable( value ) then
        local i64 = value.i64
        if i64 ~= nil then
            return BigInteger( i64 )
        end

        local f = value.f
        if f == "NaN" then
            return math_nan
        elseif f == "Infinity" then
            return math_huge
        elseif f == "-Infinity" then
            return -math_huge
        end
    end

    return value
end

--- Decodes a JSON payload array into a Lua array, returns it and its length.
---
---@param payload string
---@return any[] values
---@return integer count
local function decode_values( payload )
    local values = json_deserialize( payload )

    ---@cast values any[]
    local count = #values

    for i = 1, count, 1 do
        values[ i ] = decode_value( values[ i ] )
    end

    return values, count
end

--- Encodes a Lua value as a JavaScript literal.
---
---@param value any
---@return string
local function encode_value( value )
    if isNumber( value ) then
        if value ~= value then
            return "NaN"
        elseif value == math_huge then
            return "Infinity"
        elseif value == -math_huge then
            return "-Infinity"
        end

        return string_format( "%.17g", value )
    elseif isBigInteger( value ) then
        return '"' .. value:toString( 10 ) .. '"'
    elseif value == nil then
        return "undefined"
    elseif isString( value ) or isBoolean( value ) then
        return json_serialize( value )
    end

    error( ValueError( value, "WASM values must be numbers, BigIntegers, strings, booleans or nil" ), 4 )
end

--- Export results: nothing, the single value, or an array for multi-value returns.
---
---@type dreamwork.std.WASM.Decoder
local function decode_results( values )
    local count = #values
    if count == 0 then
        return nil
    elseif count == 1 then
        return values[ 1 ]
    end

    return values
end

---@type dreamwork.std.WASM.Decoder
local function decode_first( values )
    return values[ 1 ]
end

---@type dreamwork.std.WASM.Decoder
local function decode_bytes( values )
    return base64_decode( values[ 1 ] )
end

---@type dreamwork.std.WASM.Decoder
local function decode_nothing()
    return nil
end

--- Fails every pending request (and the load) of `wasm` with `message`.
---
---@param wasm dreamwork.std.WASM
---@param message string
local function fail_all( wasm, message )
    local load = loads[ wasm ]
    if load ~= nil and load:isPending() then
        load:setError( message, WASMErrorClass )
    end

    local futures = pending_futures[ wasm ]
    if futures == nil then return end

    pending_futures[ wasm ] = {}
    pending_decoders[ wasm ] = {}

    for _, future in raw_pairs( futures ) do
        if future:isPending() then
            future:setError( message, WASMErrorClass )
        end
    end
end

--- Returns `true` while the hosting client of `wasm` is alive.
---
---@param wasm dreamwork.std.WASM
---@return boolean
local function is_alive( wasm )
    local client = clients[ wasm ]
    return client ~= nil and not client:isClosed()
end

--- Returns the live client of `wasm`; throws when closed.
---
---@param wasm dreamwork.std.WASM
---@return dreamwork.std.WebClient
local function require_client( wasm )
    if not is_alive( wasm ) then
        error( "WASM instance is closed", 3 )
    end

    return clients[ wasm ]
end

--- Sends `__dw.<method>( id, <arguments> )` to the page and returns the reply future.
---
---@param wasm dreamwork.std.WASM
---@param decoder dreamwork.std.WASM.Decoder
---@param method string
---@param arguments string Already encoded JS arguments, after the request id.
---@return dreamwork.std.Future
local function request( wasm, decoder, method, arguments )
    local client = require_client( wasm )

    local id = (request_counts[ wasm ] or 0) + 1
    request_counts[ wasm ] = id

    local future = Future()
    pending_futures[ wasm ][ id ] = future
    pending_decoders[ wasm ][ id ] = decoder

    client:run( string_format( "__dw.%s(%d,%s)", method, id, arguments ) )

    return future
end

--- Encodes an optional memory export name as a JS literal.
---
---@param name string | nil
---@return string
local function encode_memory( name )
    if name == nil then
        return "null"
    end

    return json_serialize( name )
end


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
---@class dreamwork.std.WASM : dreamwork.std.Object
---@field __class dreamwork.std.WASMClass
---@field exports table<string, async fun( ...: any ): ...: any> Async callable proxy: `wasm.exports.add( 2, 3 )` behaves like `wasm:call( "add", 2, 3 )`.
---@field client dreamwork.std.WebClient | nil The hosting `WebClient`, `nil` once closed.
local WASM = class.base( "WASM", true, nil )

---@type table<string, function>
local exports_metatable = {}

---@param proxy table
---@param name string
---@return function
function exports_metatable.__index( proxy, name )
    local holder = proxy[ exports_metatable ]

    local fn = function( ... )
        local wasm = holder[ 1 ]
        if wasm == nil then
            error( "WASM instance was collected", 2 )
        end

        return wasm:call( name, ... )
    end

    proxy[ name ] = fn
    return fn
end

---@param key string
---@return any
---@protected
function WASM:__index( key )
    if key == "exports" then
        local proxy = export_proxies[ self ]
        if proxy == nil then
            -- the proxy is a value of a weak-keyed table, it must reference `self` weakly
            local holder = { self }
            gc_setTableRules( holder, false, true )

            proxy = { [ exports_metatable ] = holder }
            setmetatable( proxy, exports_metatable )
            export_proxies[ self ] = proxy
        end

        return proxy
    elseif key == "client" then
        local client = clients[ self ]
        if client ~= nil and not client:isClosed() then
            return client
        end

        return nil
    end

    return raw_index( WASM, key )
end

---@return string
---@protected
function WASM:__represent()
    local load = loads[ self ]

    local status
    if not is_alive( self ) then
        status = "closed"
    elseif load:isPending() then
        status = "loading"
    elseif load:error() ~= nil then
        status = "failed"
    else
        status = "ready"
    end

    return string_format( "%s: %p [%s]", type( self ), self, status )
end

---@param binary string The raw `.wasm` module bytes.
---@param imports dreamwork.std.WASM.Imports? Import object, `{ env = { log = function( x ) end, now = "() => Date.now()" } }`.
---@protected
function WASM:__init( binary, imports )
    ---@type table<string, table<string, boolean | string>>
    local spec = {}

    if imports ~= nil then
        for module_name, entries in raw_pairs( imports ) do
            if not (isString( module_name ) and isTable( entries )) then
                error( ValueError( module_name, "WASM import modules must map names to tables" ), 3 )
            end

            local module_spec = {}

            for name, value in raw_pairs( entries ) do
                if isFunction( value ) then
                    module_spec[ name ] = true
                elseif isString( value ) then
                    module_spec[ name ] = value
                else
                    error( ValueError( value, string_format( "import '%s.%s' must be a Lua function or a JavaScript expression", module_name, raw_tostring( name ) ) ), 3 )
                end
            end

            spec[ module_name ] = module_spec
        end
    end

    instance_count = instance_count + 1
    local uid = instance_count
    instances[ uid ] = self

    loads[ self ] = Future()
    pending_futures[ self ] = {}
    pending_decoders[ self ] = {}
    import_tables[ self ] = imports or {}

    local client = WebClient()
    clients[ self ] = client

    -- Bridge callbacks capture `uid` only, see `instances`.

    client:bind( "dwasm.ready", function( exports_json )
        local wasm = instances[ uid ]
        if wasm == nil then return end

        local list = json_deserialize( exports_json )

        ---@cast list dreamwork.std.WASM.Export[]

        ---@type table<string, dreamwork.std.WASM.Export>
        local map = {}

        for i = 1, #list, 1 do
            local export = list[ i ]
            map[ export.name ] = export
        end

        export_lists[ wasm ] = list
        export_maps[ wasm ] = map

        local load = loads[ wasm ]
        if load:isPending() then
            load:setResult( true )
        end
    end )

    client:bind( "dwasm.fail", function( message )
        local wasm = instances[ uid ]
        if wasm == nil then return end

        local load = loads[ wasm ]
        if load:isPending() then
            load:setError( message, WASMErrorClass )
        end
    end )

    client:bind( "dwasm.reply", function( id, success, payload )
        local wasm = instances[ uid ]
        if wasm == nil then return end

        local futures = pending_futures[ wasm ]
        local future = futures[ id ]
        if future == nil then return end

        local decoders = pending_decoders[ wasm ]
        local decoder = decoders[ id ]

        futures[ id ] = nil
        decoders[ id ] = nil

        if not future:isPending() then return end

        if success then
            future:setResult( decoder( (decode_values( payload )) ) )
        else
            future:setError( payload, WASMErrorClass )
        end
    end )

    client:bind( "dwasm.call", function( module_name, name, arguments_json )
        local wasm = instances[ uid ]
        if wasm == nil then return end

        local entries = import_tables[ wasm ][ module_name ]
        local fn = entries and entries[ name ]

        if isFunction( fn ) then
            ---@cast fn function
            local values, count = decode_values( arguments_json )
            exceptions_call( fn, table_unpack( values, 1, count ) )
        end
    end )

    client:attach( "destroy", function()
        local wasm = instances[ uid ]
        if wasm ~= nil then
            fail_all( wasm, "WASM instance was closed" )
        end
    end )

    client.html = RUNTIME_HTML
    client:run( string_format( "__dw.load(%s,%s)", json_serialize( base64_encode( binary ) ), json_serialize( spec ) ) )
end

--- Closes the hosting client when the object is collected.
---
---@protected
function WASM:__gc()
    local client = clients[ self ]
    if client ~= nil then
        client:close()
    end
end

--- [CLIENT AND MENU]
---
--- Returns `true` while the hosting client is alive.
---
---@return boolean is_valid
---@nodiscard
function WASM:__isvalid()
    return is_alive( self )
end

--- [CLIENT AND MENU]
---
--- Returns `true` once the module is compiled and instantiated.
---
---@return boolean is_ready
---@nodiscard
function WASM:isReady()
    local load = loads[ self ]
    return load:isFinished() and load:error() == nil and is_alive( self )
end

--- [CLIENT AND MENU]
---
--- Returns the `Future` resolved once the module is instantiated, failed with a `WASMError`
--- on compile / link errors.
---
---@return dreamwork.std.Future<boolean> future
---@nodiscard
function WASM:getLoadFuture()
    return loads[ self ]
end

--- [CLIENT AND MENU]
---
--- Waits until the module is instantiated; throws a `WASMError` if compiling or linking failed.
---
---@return dreamwork.std.WASM self
---@async
function WASM:await()
    loads[ self ]:await()
    return self
end

--- [CLIENT AND MENU]
---
--- Returns the module exports, `nil` until ready. Do not modify the returned tables.
---
---@return dreamwork.std.WASM.Export[] | nil exports
---@nodiscard
function WASM:getExports()
    return export_lists[ self ]
end

--- [CLIENT AND MENU]
---
--- Returns the description of the export `name`, `nil` if missing or not ready yet.
---
---@param name string
---@return dreamwork.std.WASM.Export | nil export
---@nodiscard
function WASM:getExport( name )
    local map = export_maps[ self ]
    if map ~= nil then
        return map[ name ]
    end

    return nil
end

--- [CLIENT AND MENU]
---
--- Calls the exported function `name`, returning a `Future` with its result
--- (`nil`, the single value, or an array for multi-value returns).
---
--- Calls made before the module is ready are queued in the page.
---
---@param name string The export name.
---@param ... any Arguments: numbers, `BigInteger`s (`i64`), strings or booleans.
---@return dreamwork.std.Future future
function WASM:invoke( name, ... )
    local count = raw_select( "#", ... )

    ---@type any[]
    local arguments = { ... }

    for i = 1, count, 1 do
        arguments[ i ] = encode_value( arguments[ i ] )
    end

    return request( self, decode_results, "call", json_serialize( name ) .. ",[" .. table_concat( arguments, ",", 1, count ) .. "]" )
end

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
function WASM:call( name, ... )
    local result = self:invoke( name, ... ):await()

    local export = self:getExport( name )
    if export ~= nil and export.results ~= nil and #export.results > 1 then
        ---@cast result any[]
        return table_unpack( result, 1, #export.results )
    end

    return result
end

--- [CLIENT AND MENU]
---
--- Reads `length` bytes of linear memory starting at `offset`.
---
---@param offset integer The byte offset.
---@param length integer The number of bytes.
---@param memory string? The memory export name, defaults to the first exported memory.
---@return dreamwork.std.Future<string> future
function WASM:readFuture( offset, length, memory )
    return request( self, decode_bytes, "read", string_format( "%s,%d,%d", encode_memory( memory ), offset, length ) )
end

--- [CLIENT AND MENU]
---
--- Reads `length` bytes of linear memory starting at `offset`.
---
---@param offset integer The byte offset.
---@param length integer The number of bytes.
---@param memory string? The memory export name, defaults to the first exported memory.
---@return string data
---@async
function WASM:read( offset, length, memory )
    return self:readFuture( offset, length, memory ):await()
end

--- [CLIENT AND MENU]
---
--- Writes `data` into linear memory at `offset`.
---
---@param offset integer The byte offset.
---@param data string The bytes to write.
---@param memory string? The memory export name, defaults to the first exported memory.
---@return dreamwork.std.Future future
function WASM:writeFuture( offset, data, memory )
    return request( self, decode_nothing, "write", string_format( "%s,%d,%s", encode_memory( memory ), offset, json_serialize( base64_encode( data ) ) ) )
end

--- [CLIENT AND MENU]
---
--- Writes `data` into linear memory at `offset` and waits until it is written.
---
---@param offset integer The byte offset.
---@param data string The bytes to write.
---@param memory string? The memory export name, defaults to the first exported memory.
---@async
function WASM:write( offset, data, memory )
    self:writeFuture( offset, data, memory ):await()
end

--- [CLIENT AND MENU]
---
--- Returns the linear memory size in bytes.
---
---@param memory string? The memory export name, defaults to the first exported memory.
---@return integer size
---@async
function WASM:getMemorySize( memory )
    return request( self, decode_first, "size", encode_memory( memory ) ):await()
end

--- [CLIENT AND MENU]
---
--- Grows linear memory by `pages` 64 KiB pages, returns the previous size in pages.
---
---@param pages integer The number of pages to add.
---@param memory string? The memory export name, defaults to the first exported memory.
---@return integer previous_pages
---@async
function WASM:growMemory( pages, memory )
    return request( self, decode_first, "grow", string_format( "%s,%d", encode_memory( memory ), pages ) ):await()
end

--- [CLIENT AND MENU]
---
--- Returns the value of the exported global `name`.
---
---@param name string The global export name.
---@return number | dreamwork.std.BigInteger value
---@async
function WASM:getGlobal( name )
    return request( self, decode_first, "get", json_serialize( name ) ):await()
end

--- [CLIENT AND MENU]
---
--- Sets the value of the exported mutable global `name`.
---
---@param name string The global export name.
---@param value number | dreamwork.std.BigInteger The new value.
---@async
function WASM:setGlobal( name, value )
    request( self, decode_nothing, "set", json_serialize( name ) .. "," .. encode_value( value ) ):await()
end

--- [CLIENT AND MENU]
---
--- Destroys the hosting client, pending requests fail with a `WASMError`.
---
function WASM:close()
    local client = clients[ self ]
    if client ~= nil then
        client:close()
    end

    fail_all( self, "WASM instance was closed" )
end

--- [CLIENT AND MENU]
---
--- The class used to create new `WASM` instances.
---
--- ```lua
--- local wasm = std.WASM( file.read( "add.wasm" ), {
---     env = {
---         log = function( value ) print( "wasm says", value ) end, -- Lua, fire-and-forget
---         now = "() => Date.now()" -- JavaScript expression
---     }
--- } )
---
--- std.futures.run( function()
---     wasm:await()
---     print( wasm.exports.add( 2, 3 ) ) -- 5
---     print( wasm:read( 0, 16 ) )
--- end )
--- ```
---
---@class dreamwork.std.WASMClass : dreamwork.std.WASM, dreamwork.std.Class
---@field __base dreamwork.std.WASM
---@overload fun( binary: string, imports: dreamwork.std.WASM.Imports? ): dreamwork.std.WASM
std.WASM = class.create( WASM )
