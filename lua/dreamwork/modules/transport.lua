---@class dreamwork
local dreamwork = dreamwork

local dreamwork_engine = dreamwork.engine
local engine_nextTick = dreamwork_engine.nextTick

local engine_hook = dreamwork_engine.hook

local dreamwork_exceptions = dreamwork.exceptions
local exceptions_call = dreamwork_exceptions.call

local vfs = dreamwork.vfs
local vfs_size = vfs.size
local vfs_isFile = vfs.isFile
local vfs_readFile = vfs.readFile
local vfs_writeFile = vfs.writeFile
local vfs_deleteFile = vfs.deleteFile
local vfs_search = vfs.search
local vfs_createDirectory = vfs.createDirectory

local dreamwork_getUpTime = dreamwork.getUpTime

---@class dreamwork.std
local std = dreamwork.std

local LUA_SERVER = std.LUA_SERVER

local Client = std.Client

local raw = std.raw
local raw_pairs = raw.pairs
local raw_tonumber = raw.tonumber

local string = std.string
local string_sub = string.sub
local string_match = string.match
local string_format = string.format

local table = std.table
local table_sort = table.sort
local table_concat = table.concat

local math = std.math
local math_min = math.min
local math_max = math.max
local math_ceil = math.ceil
local math_floor = math.floor
local math_random = math.random

local futures = std.futures
local futures_run = futures.run
local futures_wakeup = futures.wakeup
local futures_pending = futures.pending

local coroutine = std.coroutine
local coroutine_running = coroutine.running

local console = std.console
local console_Variable = console.Variable

local crypto = std.crypto
local crypto_SHA256 = crypto.SHA256
local SHA256_digest = crypto_SHA256.digest

local CRC32 = std.CRC32
local CRC32_digest = CRC32.digest

local time = std.time
local time_now = time.now

local json = std.json
local json_serialize = json.serialize

local base64 = std.base64
local base64_encode = base64.encode
local base64_decode = base64.decode

local deflate = std.deflate
local gzip = std.gzip

local lzma = std.lzma
local lzma_compress = lzma.compress
local lzma_decompress = lzma.decompress

local http = std.http
local http_request = http.client.request

local server = std.server

local ipv4_toString = std.ipv4.toString

local Event = std.Event
local Future = std.Future
local NetworkClass = std.Network

local pcall = std.pcall
local setTimeout = std.setTimeout
local clearTimeout = std.clearTimeout


--- [SHARED]
---
--- Delivers files from the server to the clients, the package manager sends client bundles with it.
---
--- The list of files (names, SHA-256 hashes and sizes) always goes over `std.Network`.
--- The client asks for the files it has no cache of, the server puts their contents into one bundle,
--- compresses it (see `dreamwork_transport_compression`) and splits it into segments
--- (see `dreamwork_transport_segment_size`), the segments are downloaded with the transport selected by `dreamwork_transport`:
---
--- * `network` - `std.Network`, works everywhere;
--- * `http` - `std.http.Server` on the server (HolyLib) and `std.http.client` on the client,
---   `dreamwork_transport_http_connections` segments at once, segments that fail to download fall back to `network`.
---   Only connected players can download (see `dreamwork_transport_http_whitelist`),
---   the segments are sent as base64 (HolyLib cuts binary content at `\0`).
---   `GET /dreamwork/health` is open for monitors: `200` with `{ "status": "ok", "ready", "revision", "files", "uptime" }`,
---   `503` with `"status": "starting"` until the server has its files ready.
---   The game client refuses requests to private addresses, so on LAN set `dreamwork_transport_http_url`
---   to a public address or the files come over `network`.
--- * `static` - the segments are written to `/garrysmod/data/dreamwork/transport` as `<bundle>-<index>.dat`
---   and a web server installed in the system (Caddy, nginx) serves that directory at `dreamwork_transport_http_url`,
---   the clients download them like with `http`, but without base64 and without HolyLib.
---   Nothing checks who downloads, the bundle names are known only to connected players,
---   so do not let the web server list the directory. The files are not in memory, the `network` fallback reads them.
---
--- Bundles are kept on the server (the bundle of all files is made as soon as the files are ready),
--- so clients that miss the same files share one bundle.
---
--- Clients keep downloaded files in `/garrysmod/data/dreamwork/cache/transport` by their hashes,
--- so only changed files are downloaded on the next connection. `dreamwork.storage.transport` keeps their CRC-32,
--- checked on every use (a damaged file is downloaded again), and their last use: files not used for
--- `dreamwork_transport_cache_lifetime` days, or the least recently used ones over `dreamwork_transport_cache_size`, are deleted.
--- The cache is shared by every server, files used in the current session are never deleted.
---
---@class dreamwork.transport
---@field Updated dreamwork.std.Event Called on the client with `table<string, dreamwork.transport.File>` when the files from the server change.
---@field Receiving dreamwork.std.Event Called on the client when files start to download, with `dreamwork.transport.ManifestEntry[]`, their count, their total size in bytes and the transport of the server (`"http"`, `"static"` or `"network"`).
---@field Progress dreamwork.std.Event Called on the client while files download, with the downloaded bytes and the total bytes, compressed bytes are scaled to the size of the files.
---@field Received dreamwork.std.Event Called on the client for every downloaded file, with its `dreamwork.transport.ManifestEntry`, the transport that delivered it (`"http"`, `"static"`, or `"network"` if any segment of the bundle came over the network) and `true` if it was received.
local transport = dreamwork.transport or {}
dreamwork.transport = transport

--- [SHARED]
---
--- A file delivered by the transport.
---
---@class dreamwork.transport.File
---@field name string The name of the file.
---@field content string The content of the file.
---@field hash string The SHA-256 hash of the content, lowercase hex.
---@field size integer The size of the content in bytes.

---@type dreamwork.std.Event
local Updated = transport.Updated or Event( "transport.Updated" )
transport.Updated = Updated

---@type dreamwork.std.console.Variable<string>
local selected_transport = console_Variable( {
    name = dreamwork.selectVariableName( "transport" ),
    description = "The transport that sends files to the clients: 'network', 'http' (requires HolyLib on the server) or 'static' (a web server serves 'data/dreamwork/transport' at 'dreamwork_transport_http_url').",
    type = "string",
    default = "network",
    replicated = true,
    archive = true,
    hidden = true,
    notify = true
} )

---@type dreamwork.std.console.Variable<integer>
local http_connections = console_Variable( {
    name = dreamwork.selectVariableName( "transport_http_connections" ),
    description = "The number of segments the clients download at once with the 'http' and 'static' transports.",
    type = "integer",
    default = 8,
    min = 1,
    max = 16,
    replicated = true,
    archive = true,
    hidden = true,
    notify = true
} )

--- The path of the segments on the http server, followed by `<bundle>-<index>.bin`.
---
--- The extension lets CDNs like Cloudflare cache the segments without extra rules.
---
---@type string
local HTTP_ROUTE = "/dreamwork/transport/"

--- The extension of the segment files of the `static` transport, one that `file.Write` allows.
---
---@type string
local STATIC_EXTENSION = ".dat"

--- The path of the health check, open for everyone.
---
---@type string
local HEALTH_ROUTE = "/dreamwork/health"

--- The directory of downloaded files on the client.
---
---@type string
local CACHE_DIRECTORY = "/garrysmod/data/dreamwork/cache/transport"

-- client -> server: send the list of files
local OPCODE_REQUEST = 1

-- server -> client: the list of files
local OPCODE_MANIFEST = 2

-- client -> server: make the bundle of the files by their hashes
local OPCODE_BUNDLE = 3

-- server -> client: the bundle is ready
local OPCODE_BUNDLE_INFO = 4

-- server -> client: the list of files changed
local OPCODE_UPDATE = 5

-- client -> server: send the segments of the bundle
local OPCODE_SEGMENTS = 6

-- server -> client: the segment of the bundle
local OPCODE_SEGMENT = 7

--- The compressions of the bundles by their numbers in `OPCODE_BUNDLE_INFO`.
---
---@type table<integer, string>
local COMPRESSION_NAMES = {
    [ 0 ] = "none",
    [ 1 ] = "lzma",
    [ 2 ] = "deflate",
    [ 3 ] = "gzip"
}

--- The numbers of the compressions in `OPCODE_BUNDLE_INFO`.
---
---@type table<string, integer>
local COMPRESSION_IDS = {}

for compression_id, name in raw_pairs( COMPRESSION_NAMES ) do
    COMPRESSION_IDS[ name ] = compression_id
end

--- The bits of the compression number, room for 8 compressions.
local COMPRESSION_BITS = 3

--- [SHARED]
---
--- Returns the files: the files given to the transport on the server, the last received files on the client.
---
---@return table<string, dreamwork.transport.File> files The files by their names, do not modify.
---@nodiscard
function transport.getFiles()
    return transport.Files or {}
end

if LUA_SERVER then

    -- the clients get the port and the url with the list of files

    ---@type dreamwork.std.console.Variable<integer>
    local http_port = console_Variable( {
        name = dreamwork.selectVariableName( "transport_http_port" ),
        description = "The port of the 'http' transport server.",
        default = 27080,
        min = 1,
        max = 65535,
        archive = true,
        type = "integer"
    } )

    ---@type dreamwork.std.console.Variable<string>
    local http_url = console_Variable( {
        name = dreamwork.selectVariableName( "transport_http_url" ),
        description = "The public URL of the 'http' transport files (e.g. behind a reverse proxy), the address of the server and 'dreamwork_transport_http_port' by default. Required by the 'static' transport, the URL the web server serves 'data/dreamwork/transport' at.",
        default = "",
        archive = true,
        type = "string"
    } )

    ---@type dreamwork.std.console.Variable<boolean>
    local http_whitelist = console_Variable( {
        name = dreamwork.selectVariableName( "transport_http_whitelist" ),
        description = "If enabled, only the IP addresses of connected players can download from the 'http' transport. Disable it behind a reverse proxy or CDN, the bundle names in the URLs are known only to connected players.",
        default = true,
        archive = true,
        type = "boolean"
    } )

    ---@type dreamwork.std.console.Variable<string>
    local compression = console_Variable( {
        name = dreamwork.selectVariableName( "transport_compression" ),
        description = "The compression of the bundles: 'auto' (the smallest of 'lzma' and 'deflate' on a sample, or 'none' if they do not help), 'lzma', 'deflate', 'gzip' or 'none'.",
        default = "auto",
        archive = true,
        type = "string"
    } )

    ---@type dreamwork.std.console.Variable<integer>
    local segment_size = console_Variable( {
        name = dreamwork.selectVariableName( "transport_segment_size" ),
        description = "The size of the bundle segments in bytes, '0' splits the compressed bundle into two segments per 'http' connection, from 256 KiB to 4 MiB.",
        default = 0,
        min = 0,
        max = 0x4000000,
        archive = true,
        type = "integer"
    } )

    --- The directory of the segment files of the `static` transport.
    local STATIC_DIRECTORY = "/garrysmod/data/dreamwork/transport"

    --- Changes of the format make new bundle names, so CDNs never mix them.
    local BUNDLE_VERSION = 1

    --- The bundles are dropped from the oldest used while they take more memory.
    local MAX_BUNDLE_MEMORY = 0x10000000

    --- The time a compressor runs before it waits for the next tick, in seconds.
    local TICK_BUDGET = 0.004

    --- The input of the stream compressors is added in parts of this size.
    local STREAM_SLICE = 0x8000

    --- `auto` compresses this many slices of this size from the bundle to pick the compression.
    local SAMPLE_SLICE = 0x40000
    local SAMPLE_SLICES = 4

    --- `auto` keeps the bundle uncompressed unless the sample is at least 3% smaller.
    local SAMPLE_GAIN = 0.97

    --- Without HolyLib lzma runs on the main thread, larger bundles use deflate instead.
    local LZMA_SYNC_LIMIT = 0x400000

    local DEFLATE_LEVEL = 6
    local LZMA_LEVEL = 5

    ---@type garrysmod.util
    local glua_util = dreamwork_engine.requireLibrary( "util" )
    local is_lzma_async = glua_util.AsyncCompress ~= nil

    -- the files, the revision and the ready flag survive a reload of the transport

    ---@type table<string, dreamwork.transport.File>
    local files = transport.Files or {}
    transport.Files = files

    ---@type table<string, dreamwork.transport.File>
    local files_by_hash = {}

    for _, file in raw_pairs( files ) do
        files_by_hash[ file.hash ] = file
    end

    --- The revision of the file list, changes with every change.
    ---
    ---@type integer
    local revision = transport.Revision or 0

    --- `false` until the files are ready, clients wait for it.
    ---
    ---@type boolean
    local is_ready = transport.Ready == true

    --- [SERVER]
    ---
    --- The contents of files joined and compressed, split into segments.
    ---
    ---@class dreamwork.transport.Bundle
    ---@field key string The SHA-256 of the hashes of the files and the settings, lowercase hex.
    ---@field id string The name of the bundle in URLs and messages, unique for every bundle made.
    ---@field method string The compression: `"none"`, `"lzma"`, `"deflate"` or `"gzip"`.
    ---@field size integer The size of the joined contents in bytes.
    ---@field compressed_size integer The size of the compressed bundle in bytes.
    ---@field segment_size integer The size of every segment but the last one, in bytes.
    ---@field segment_count integer
    ---@field segments string[] The parts of the compressed bundle, empty if `stored`.
    ---@field stored boolean `true` if the segments are in the files of the `static` transport.
    ---@field encoded table<integer, string> The segments in base64 for the `http` transport, made on the first request.
    ---@field memory integer The bytes of the segments and their base64.
    ---@field used number The uptime of the last use.

    -- the bundles survive a reload of the transport, the clients can be downloading them

    ---@type table<string, dreamwork.transport.Bundle>
    local bundles_by_key = transport.Bundles or {}
    transport.Bundles = bundles_by_key

    ---@type table<string, dreamwork.transport.Bundle>
    local bundles_by_id = {}

    --- The bytes of all bundles.
    local bundle_memory = 0

    for _, bundle in raw_pairs( bundles_by_key ) do
        bundles_by_id[ bundle.id ] = bundle
        bundle_memory = bundle_memory + bundle.memory
    end

    --- The bundles being made by their keys, the futures give the bundle or `nil`.
    ---
    ---@type table<string, dreamwork.std.Future>
    local building = {}

    ---@type dreamwork.std.Network | nil
    local network

    --- The transport the clients are told about: `"network"`, `"http"` or `"static"`.
    local active_transport = "network"

    --- `true` while the change notification is scheduled.
    local update_scheduled = false

    --- Waits for the next tick.
    ---
    ---@async
    local function yield_tick()
        local co = coroutine_running()
        ---@cast co thread

        engine_nextTick( function()
            futures_wakeup( co )
        end )

        futures_pending()
    end

    --- Compresses the data with the stream compressor, a part every tick.
    ---
    ---@param compressor dreamwork.std.deflate.Compressor
    ---@param data string
    ---@return string compressed_data
    ---@async
    local function compress_stream( compressor, data )
        local started = dreamwork_getUpTime()

        for position = 1, #data, STREAM_SLICE do
            compressor:update( string_sub( data, position, position + (STREAM_SLICE - 1) ) )

            if dreamwork_getUpTime() - started > TICK_BUDGET then
                yield_tick()
                started = dreamwork_getUpTime()
            end
        end

        return compressor:flush()
    end

    --- Returns `true` if lzma does not freeze the server on data of the size.
    ---
    ---@param size integer
    ---@return boolean
    local function is_lzma_usable( size )
        return is_lzma_async or size <= LZMA_SYNC_LIMIT
    end

    ---@param method string
    ---@param data string
    ---@return string compressed_data
    ---@async
    local function compress( method, data )
        if method == "lzma" then
            -- a dictionary as large as the data (up to 16 MiB) finds repeats across the files
            local dictionary_size = 0x10000
            while dictionary_size < #data and dictionary_size < 0x1000000 do
                dictionary_size = dictionary_size * 2
            end

            return lzma_compress( data, LZMA_LEVEL, dictionary_size )
        elseif method == "deflate" then
            return compress_stream( deflate.Compressor( { level = DEFLATE_LEVEL } ), data )
        elseif method == "gzip" then
            return compress_stream( gzip.Compressor( { level = DEFLATE_LEVEL } ), data )
        end

        return data
    end

    --- Returns slices from the whole data, or the data itself if it is small.
    ---
    ---@param data string
    ---@return string sample
    local function take_sample( data )
        local length = #data
        if length <= SAMPLE_SLICE * SAMPLE_SLICES then
            return data
        end

        ---@type string[]
        local slices = {}
        local step = (length - SAMPLE_SLICE) / (SAMPLE_SLICES - 1)

        for index = 1, SAMPLE_SLICES, 1 do
            local start = math_floor( step * (index - 1) ) + 1
            slices[ index ] = string_sub( data, start, start + (SAMPLE_SLICE - 1) )
        end

        return table_concat( slices, "", 1, SAMPLE_SLICES )
    end

    --- Picks the compression with the smallest sample.
    ---
    ---@param data string
    ---@return string method
    ---@return string | nil compressed_data The compressed data if the sample was the whole data.
    ---@async
    local function select_method( data )
        local sample = take_sample( data )

        local best_method, best_data = "none", nil
        local best_size = #sample * SAMPLE_GAIN

        if is_lzma_usable( #data ) then
            local compressed_data = compress( "lzma", sample )
            if #compressed_data < best_size then
                best_method, best_data, best_size = "lzma", compressed_data, #compressed_data
            end
        end

        local compressed_data = compress( "deflate", sample )
        if #compressed_data < best_size then
            best_method, best_data = "deflate", compressed_data
        end

        if sample ~= data then
            best_data = nil
        end

        return best_method, best_data
    end

    ---@param id string
    ---@param index integer
    ---@return string
    local function segment_path( id, index )
        return string_format( "%s/%s-%d%s", STATIC_DIRECTORY, id, index, STATIC_EXTENSION )
    end

    --- Deletes the segment files of the bundle, the missing ones are ignored.
    ---
    ---@param bundle dreamwork.transport.Bundle
    local function delete_segments( bundle )
        local id = bundle.id

        for index = 1, bundle.segment_count, 1 do
            pcall( vfs_deleteFile, segment_path( id, index ), true )
        end
    end

    --- Writes the segments into files for the `static` transport and drops them from memory.
    ---
    ---@param bundle dreamwork.transport.Bundle
    ---@async
    local function store_segments( bundle )
        local id, segments = bundle.id, bundle.segments

        for index = 1, bundle.segment_count, 1 do
            vfs_writeFile( segment_path( id, index ), segments[ index ] )
        end

        bundle.segments = {}
        bundle.stored = true
    end

    --- Returns the segment of the bundle, read from its file if it is stored.
    ---
    ---@param bundle dreamwork.transport.Bundle
    ---@param index integer
    ---@return string | nil segment `nil` if there is no such segment.
    local function read_segment( bundle, index )
        if not bundle.stored then
            return bundle.segments[ index ]
        end

        if index < 1 or index > bundle.segment_count then
            return nil
        end

        local success, data = pcall( vfs_readFile, segment_path( bundle.id, index ), true )
        if success then
            return data
        end

        return nil
    end

    ---@param bundle dreamwork.transport.Bundle
    local function drop_bundle( bundle )
        bundles_by_key[ bundle.key ] = nil
        bundles_by_id[ bundle.id ] = nil
        bundle_memory = bundle_memory - bundle.memory

        if bundle.stored then
            delete_segments( bundle )
        end
    end

    --- Drops the least recently used bundles, except the given one, while they take too much memory.
    ---
    ---@param kept dreamwork.transport.Bundle
    local function trim_bundles( kept )
        ::bundle_trimmer::

        if bundle_memory > MAX_BUNDLE_MEMORY then
            local oldest

            for _, bundle in raw_pairs( bundles_by_key ) do
                if bundle ~= kept and (oldest == nil or bundle.used < oldest.used) then
                    oldest = bundle
                end
            end

            if oldest ~= nil then
                drop_bundle( oldest )
                goto bundle_trimmer
            end
        end
    end

    --- Joins, compresses and splits the contents.
    ---
    ---@param key string
    ---@param contents string[]
    ---@param count integer
    ---@return dreamwork.transport.Bundle
    ---@async
    local function build_bundle( key, contents, count )
        local started = dreamwork_getUpTime()

        local data = table_concat( contents, "", 1, count )
        local size = #data

        local method, compressed_data = compression.value, nil

        if method == "auto" then
            method, compressed_data = select_method( data )
        elseif method == "lzma" then
            if not is_lzma_usable( size ) then
                method = "deflate"
            end
        elseif method ~= "deflate" and method ~= "gzip" then
            method = "none"
        end

        if compressed_data == nil then
            compressed_data = compress( method, data )
        end

        ---@diagnostic disable-next-line: cast-local-type
        data = nil

        local compressed_size = #compressed_data

        local part_size = segment_size.value
        if part_size == 0 then
            -- every request costs a round trip (~0.5 s behind a CDN), two rounds of requests are enough to hide the slow ones
            part_size = math_min( math_max( math_ceil( compressed_size / (http_connections.value * 2) ), 0x40000 ), 0x400000 )
        end

        ---@type string[]
        local segments = {}
        local segment_count = math_ceil( compressed_size / part_size )

        for index = 1, segment_count, 1 do
            segments[ index ] = string_sub( compressed_data, (index - 1) * part_size + 1, index * part_size )
        end

        ---@type dreamwork.transport.Bundle
        local bundle = {
            key = key,
            id = string_format( "%s%08x", string_sub( key, 1, 24 ), math_random( 0, 0x7FFFFFFF ) ),
            method = method,
            size = size,
            compressed_size = compressed_size,
            segment_size = part_size,
            segment_count = segment_count,
            segments = segments,
            stored = false,
            encoded = {},
            memory = compressed_size,
            used = dreamwork_getUpTime()
        }

        dreamwork.Logger:debug( "Transport bundle %s: %d file(s), %d -> %d bytes (%s), %d segment(s), made in %.2f s.", bundle.id, count, size, compressed_size, method, segment_count, dreamwork_getUpTime() - started )

        return bundle
    end

    --- Returns the key of the bundle of the files with the current settings.
    ---
    ---@param hashes string[] The hashes of the files, sorted, without duplicates.
    ---@param count integer
    ---@return string key
    local function bundle_key( hashes, count )
        -- the bundles of `static` are in files, the others are in memory
        return SHA256_digest( string_format( "%d|%s|%d|%s|", BUNDLE_VERSION, compression.value, segment_size.value, active_transport == "static" and "files" or "memory" ) .. table_concat( hashes, ",", 1, count ), true )
    end

    --- Returns the hashes of all files, sorted.
    ---
    ---@return string[] hashes
    ---@return integer count
    local function all_hashes()
        ---@type string[]
        local hashes = {}
        local count = 0

        for hash in raw_pairs( files_by_hash ) do
            count = count + 1
            hashes[ count ] = hash
        end

        table_sort( hashes )
        return hashes, count
    end

    --- Returns the bundle of the files, made once for the same files and settings.
    ---
    ---@param hashes string[] The hashes of the files, sorted, without duplicates, all known.
    ---@param count integer
    ---@return dreamwork.transport.Bundle | nil bundle The bundle, `nil` if it could not be made.
    ---@async
    local function get_bundle( hashes, count )
        local key = bundle_key( hashes, count )

        local bundle = bundles_by_key[ key ]
        if bundle ~= nil then
            bundle.used = dreamwork_getUpTime()
            return bundle
        end

        local future = building[ key ]
        if future ~= nil then
            return future:await()
        end

        future = Future()
        building[ key ] = future

        ---@type string[]
        local contents = {}

        for index = 1, count, 1 do
            contents[ index ] = files_by_hash[ hashes[ index ] ].content
        end

        local success, result = pcall( build_bundle, key, contents, count )

        -- the files are written before the clients get the name of the bundle
        if success and active_transport == "static" then
            local stored, message = pcall( store_segments, result )
            if not stored then
                delete_segments( result )
                ---@diagnostic disable-next-line: cast-local-type
                success, result = false, message
            end
        end

        building[ key ] = nil

        if not success then
            dreamwork.Logger:error( "Transport bundle of %d file(s) failed: %s", count, result )
            future:setResult( nil )
            return nil
        end

        ---@cast result dreamwork.transport.Bundle

        bundles_by_key[ key ] = result
        bundles_by_id[ result.id ] = result
        bundle_memory = bundle_memory + result.memory
        trim_bundles( result )

        future:setResult( result )
        return result
    end

    --- The key of the bundle of all files that could not be made, new clients are let in anyway,
    --- they would wait forever otherwise.
    ---
    ---@type string | nil
    local failed_key

    --- Makes the bundle of all files, the one every new client asks for.
    ---
    ---@async
    local function prepare_bundle()
        local hashes, count = all_hashes()
        if count ~= 0 and get_bundle( hashes, count ) == nil then
            failed_key = bundle_key( hashes, count )
        end
    end

    --- [SERVER]
    ---
    --- Checks if new clients can download the files right away: the files are ready
    --- and the bundle of all files is made with the current settings.
    ---
    --- With no files there is nothing to download, so a pending notification of that
    --- empty list does not delay joins. `CheckPassword` rejects until this is true,
    --- and the loader schedules that notification even when it published nothing.
    ---
    ---@return boolean is_prepared
    ---@nodiscard
    function transport.isPrepared()
        if network == nil or not is_ready then
            return false
        end

        local hashes, count = all_hashes()
        if count == 0 then
            return true
        end

        -- the bundle of the files that are about to be replaced is not worth downloading
        if update_scheduled then
            return false
        end

        local key = bundle_key( hashes, count )
        return bundles_by_key[ key ] ~= nil or key == failed_key
    end

    local function notify()
        update_scheduled = false

        if network == nil or not is_ready then
            return
        end

        futures_run( prepare_bundle )

        ---@type dreamwork.std.Client[]
        local targets = {}
        local target_count = 0

        -- every initialized client runs the transport, the ones that are still loading ask by themselves
        local clients, client_count = Client.getAll( true )

        for index = 1, client_count, 1 do
            local client = clients[ index ]
            if client.is_initialized then
                target_count = target_count + 1
                targets[ target_count ] = client
            end
        end

        if target_count == 0 then
            return
        end

        network:transmit( function( _, writer )
            writer:writeUInt( OPCODE_UPDATE, 8 )
            writer:writeUInt( revision, 32 )
        end, targets )
    end

    --- Changes come in batches (a package with its dependencies), the clients are told once.
    local function changed()
        revision = (revision + 1) % 0x100000000
        transport.Revision = revision

        if not update_scheduled then
            update_scheduled = true
            setTimeout( notify, 0.5 )
        end
    end

    --- [SERVER]
    ---
    --- Adds the file, a file with the same name is replaced.
    ---
    ---@param name string The name of the file, must not contain `\0`.
    ---@param content string The content of the file.
    function transport.addFile( name, content )
        local previous = files[ name ]
        if previous ~= nil then
            files_by_hash[ previous.hash ] = nil
        end

        ---@type dreamwork.transport.File
        local file = {
            name = name,
            content = content,
            hash = SHA256_digest( content, true ),
            size = #content
        }

        files[ name ] = file
        files_by_hash[ file.hash ] = file

        changed()
    end

    --- [SERVER]
    ---
    --- Removes the file.
    ---
    ---@param name string The name of the file.
    ---@return boolean removed `true` if the file existed.
    function transport.delFile( name )
        local file = files[ name ]
        if file == nil then
            return false
        end

        files[ name ] = nil

        if files_by_hash[ file.hash ] == file then
            files_by_hash[ file.hash ] = nil
        end

        changed()
        return true
    end

    --- [SERVER]
    ---
    --- Marks the files as ready, clients that connected earlier wait for it.
    ---
    ---@param ready boolean `true` when the files are ready.
    function transport.setReady( ready )
        is_ready = ready == true
        transport.Ready = is_ready

        if is_ready then
            changed()
        end
    end

    ---@param current_network dreamwork.std.Network
    ---@param sender dreamwork.std.Client
    local function send_manifest( current_network, sender )
        local transport_name = active_transport

        current_network:transmit( function( _, writer )
            writer:writeUInt( OPCODE_MANIFEST, 8 )
            writer:writeUInt( revision, 32 )
            writer:writeBoolean( is_ready )
            writer:writeString( transport_name )
            writer:writeUInt( http_port.value, 16 )
            writer:writeString( http_url.value )

            local count = 0
            for _ in raw_pairs( files ) do
                count = count + 1
            end

            writer:writeUInt( count, 16 )

            for name, file in raw_pairs( files ) do
                writer:writeString( name )
                writer:writeString( file.hash )
                writer:writeUInt( file.size, 32 )
            end
        end, sender )
    end

    --- Makes the bundle and tells the client about it.
    ---
    ---@param current_network dreamwork.std.Network
    ---@param sender dreamwork.std.Client
    ---@param ticket integer
    ---@param hashes string[]
    ---@param count integer
    ---@async
    local function send_bundle( current_network, sender, ticket, hashes, count )
        local bundle

        -- a file changed after the manifest was sent, the client gets the new one with the update
        local is_known = true
        for index = 1, count, 1 do
            if files_by_hash[ hashes[ index ] ] == nil then
                is_known = false
                break
            end
        end

        if is_known then
            bundle = get_bundle( hashes, count )
        end

        if not sender.is_connected then
            return
        end

        current_network:transmit( function( _, writer )
            writer:writeUInt( OPCODE_BUNDLE_INFO, 8 )
            writer:writeUInt( ticket, 32 )

            -- an empty name tells the client there is no bundle
            if bundle == nil then
                writer:writeString( "" )
                return
            end

            writer:writeString( bundle.id )
            writer:writeUInt( COMPRESSION_IDS[ bundle.method ], COMPRESSION_BITS )
            writer:writeUInt( bundle.size, 32 )
            writer:writeUInt( bundle.compressed_size, 32 )
            writer:writeUInt( bundle.segment_size, 32 )
            writer:writeUInt( bundle.segment_count, 32 )
        end, sender )
    end

    ---@param current_network dreamwork.std.Network
    ---@param sender dreamwork.std.Client
    ---@param reader dreamwork.std.BinaryReader
    local function receive_bundle( current_network, sender, reader )
        local ticket = reader:readUInt( 32 )

        ---@type string[]
        local hashes = {}
        local count = 0

        ---@type table<string, boolean>
        local seen = {}

        for _ = 1, reader:readUInt( 16 ), 1 do
            local hash = reader:readString()
            if not seen[ hash ] then
                seen[ hash ] = true
                count = count + 1
                hashes[ count ] = hash
            end
        end

        table_sort( hashes )

        futures_run( send_bundle, nil, current_network, sender, ticket, hashes, count )
    end

    ---@param current_network dreamwork.std.Network
    ---@param sender dreamwork.std.Client
    ---@param reader dreamwork.std.BinaryReader
    local function send_segments( current_network, sender, reader )
        local id = reader:readString()

        local segment_count = 1

        local bundle = bundles_by_id[ id ]
        if bundle ~= nil then
            bundle.used = dreamwork_getUpTime()
            segment_count = bundle.segment_count
        end

        -- an unknown bundle gets one answer that it is gone
        for _ = 1, math_min( reader:readUInt( 32 ), segment_count ), 1 do
            local index = reader:readUInt( 32 )

            local segment
            if bundle ~= nil then
                segment = read_segment( bundle, index )
            end

            current_network:transmit( function( _, writer )
                writer:writeUInt( OPCODE_SEGMENT, 8 )
                writer:writeString( id )
                writer:writeUInt( index, 32 )

                -- `false` tells the client the bundle is gone
                if segment == nil then
                    writer:writeBoolean( false )
                else
                    writer:writeBoolean( true )
                    writer:writeCountedString( segment, 32 )
                end
            end, sender )
        end
    end

    ---@param current_network dreamwork.std.Network
    ---@param reader dreamwork.std.BinaryReader
    ---@param sender dreamwork.std.Client | nil
    local function receive( current_network, reader, sender )
        if sender == nil then
            return
        end

        local opcode = reader:readUInt( 8 )
        if opcode == OPCODE_REQUEST then
            send_manifest( current_network, sender )
        elseif opcode == OPCODE_BUNDLE then
            receive_bundle( current_network, sender, reader )
        elseif opcode == OPCODE_SEGMENTS then
            send_segments( current_network, sender, reader )
        end
    end

    ---@return dreamwork.std.http.Server
    local function create_http_server()
        return http.Server( "dreamwork.transport" )
    end

    --- Starts the http server of the `http` transport.
    ---
    ---@return boolean success
    local function start_http()
        if http.Server == nil then
            return false
        end

        local success, result = pcall( create_http_server )
        if not success then
            dreamwork.Logger:warn( "The 'http' transport cannot start: %s", result )
            return false
        end

        ---@cast result dreamwork.std.http.Server

        local is_whitelisted = http_whitelist.value

        -- every made bundle has its own name, so without the whitelist a CDN can keep the segments
        local cache_control = is_whitelisted and "private, no-store" or "public, max-age=31536000, immutable"

        result:get( HTTP_ROUTE .. ":segment", function( request, response )
            local id, index = string_match( request:getPathParam( "segment" ) or "", "^(%x+)%-(%d+)%.bin$" )

            local bundle, segment, segment_index
            if id ~= nil then
                bundle = bundles_by_id[ id ]
                if bundle ~= nil then
                    segment_index = raw_tonumber( index, 10 )
                    segment = bundle.segments[ segment_index ]
                end
            end

            if segment == nil then
                response:setHeader( "Cache-Control", "no-store" )
                response:send( 404, "Not Found" )
                return
            end

            ---@cast bundle dreamwork.transport.Bundle
            ---@cast segment_index integer

            bundle.used = dreamwork_getUpTime()

            -- HolyLib cuts the content at the first `\0`, so the segments go as base64
            local encoded = bundle.encoded[ segment_index ]
            if encoded == nil then
                encoded = base64_encode( segment )
                bundle.encoded[ segment_index ] = encoded

                bundle.memory = bundle.memory + #encoded
                bundle_memory = bundle_memory + #encoded
            end

            response:setHeader( "Cache-Control", cache_control )
            response:send( 200, encoded, "text/plain" )
        end, is_whitelisted )

        -- monitors are not players, so it is never whitelisted, `503` until the files are ready
        result:get( HEALTH_ROUTE, function( _, response )
            local file_count = 0
            for _ in raw_pairs( files ) do
                file_count = file_count + 1
            end

            response:setHeader( "Cache-Control", "no-store" )
            response:send( is_ready and 200 or 503, json_serialize( {
                status = is_ready and "ok" or "starting",
                ready = is_ready,
                revision = revision,
                files = file_count,
                uptime = dreamwork_getUpTime()
            }, false ), "application/json" )
        end )

        result:start( "0.0.0.0", http_port.value )

        return true
    end

    --- Prepares the directory of the `static` transport, the files of unknown bundles are deleted.
    ---
    ---@return boolean success
    local function start_static()
        if http_url.value == "" then
            dreamwork.Logger:warn( "The 'static' transport needs 'dreamwork_transport_http_url', the URL the web server serves '%s' at.", STATIC_DIRECTORY )
            return false
        end

        local success, message = pcall( vfs_createDirectory, STATIC_DIRECTORY )
        if not success then
            dreamwork.Logger:warn( "The 'static' transport cannot create '%s': %s", STATIC_DIRECTORY, message )
            return false
        end

        local names, name_count = vfs_search( STATIC_DIRECTORY, "*" )

        -- the bundles of the previous instance stay, the clients can be downloading them
        for index = 1, name_count, 1 do
            local name = names[ index ]
            local id = string_match( name, "^(%x+)%-%d+%.%w+$" )

            local bundle = id ~= nil and bundles_by_id[ id ] or nil
            if bundle == nil or not bundle.stored then
                pcall( vfs_deleteFile, STATIC_DIRECTORY .. "/" .. name, true )
            end
        end

        return true
    end

    --- [SERVER]
    ---
    --- Starts the transport, called by the package manager.
    ---
    function transport.startup()
        if network ~= nil then
            return
        end

        transport.Started = true

        network = NetworkClass( "dreamwork.transport", true )
        network:clear()
        network:attach( receive )

        -- the server of the previous instance still listens on the port
        local HTTPServer = http.Server
        if HTTPServer ~= nil then
            local success, previous = pcall( HTTPServer.findByName, "dreamwork.transport" )
            if success and previous ~= nil then
                previous:destroy()
            end
        end

        local name = selected_transport.value
        if name == "http" and start_http() then
            active_transport = "http"
            dreamwork.Logger:info( "The 'http' transport is listening on port %d.", http_port.value )
        elseif name == "static" and start_static() then
            active_transport = "static"
            dreamwork.Logger:info( "The 'static' transport writes the segments to '%s', served at '%s'.", STATIC_DIRECTORY, http_url.value )
        elseif name ~= "network" then
            if name ~= "http" and name ~= "static" then
                dreamwork.Logger:warn( "Unknown transport '%s', falling back to 'network'.", name )
            end

            selected_transport:revert()
        end

        -- a reloaded transport has the files ready already
        if is_ready then
            futures_run( prepare_bundle )
        end

        -- a client that joins earlier would wait in the loading screen for the files
        engine_hook.catch( "CheckPassword", "modules.transport", function()
            if not transport.isPrepared() then
                return false, string_format( "%s : The server is preparing its files, try again in a few seconds.", dreamwork.Prefix )
            end
        end )
    end

else

    --- The files of the last applied manifest.
    ---
    ---@type table<string, dreamwork.transport.File>
    transport.Files = {}

    ---@type dreamwork.std.Event
    local Receiving = transport.Receiving or Event( "transport.Receiving" )
    transport.Receiving = Receiving

    ---@type dreamwork.std.Event
    local Progress = transport.Progress or Event( "transport.Progress" )
    transport.Progress = Progress

    ---@type dreamwork.std.Event
    local Received = transport.Received or Event( "transport.Received" )
    transport.Received = Received

    --- The time to wait for the server to make the bundle, in seconds.
    local BUNDLE_TIMEOUT = 300

    --- The time without new segments from the network before it is given up, in seconds.
    local STALL_TIMEOUT = 60

    --- The http transport is given up after this many failed segments in a row.
    local MAX_HTTP_FAILURES = 3

    --- The bytes of segments asked over the network at once (at least one segment), more are asked as they come,
    --- so other messages and the next download do not wait behind the whole bundle.
    local NETWORK_WINDOW = 0x200000

    --- The bytes of all files being downloaded.
    local progress_total = 0

    ---@class dreamwork.transport.ManifestEntry
    ---@field name string
    ---@field hash string
    ---@field size integer

    ---@class dreamwork.transport.Manifest
    ---@field revision integer
    ---@field ready boolean
    ---@field transport string
    ---@field port integer
    ---@field url string
    ---@field entries dreamwork.transport.ManifestEntry[]
    ---@field entry_count integer

    --- [CLIENT]
    ---
    --- The bundle being downloaded.
    ---
    ---@class dreamwork.transport.Download
    ---@field ticket integer The number of the bundle request, answers to older requests are ignored.
    ---@field thread thread | nil The coroutine waiting for the download, `nil` once woken up.
    ---@field id string | nil The name of the bundle, `""` if the server has none, `nil` until the server answers.
    ---@field method string
    ---@field size integer
    ---@field compressed_size integer
    ---@field segment_size integer
    ---@field segment_count integer
    ---@field segments table<integer, string | boolean> The received segments, `true` once given to the decompressor.
    ---@field received integer The number of received segments.
    ---@field done_bytes integer The bytes of the received segments.
    ---@field reported_bytes integer The bytes of the last progress report.
    ---@field decompressor dreamwork.std.deflate.Decompressor | nil The decompressor of the segments, given in order as they come.
    ---@field next_segment integer The segment the decompressor needs next.
    ---@field is_corrupt boolean `true` if the decompressor failed.
    ---@field is_lost boolean `true` if the server has no bundle anymore.
    ---@field used_network boolean `true` if any segment came over the network.
    ---@field next_index integer The next segment for the http workers.
    ---@field workers integer The number of running http workers.
    ---@field is_fetching boolean `true` while the http workers are waited for.
    ---@field http_failures integer The failed http segments in a row.
    ---@field failed integer[] The segments that the http workers failed.
    ---@field failed_count integer
    ---@field requested table<integer, boolean> The segments asked over the network and not received yet.
    ---@field waiting integer The number of `requested` segments.
    ---@field queue integer[] The segments to ask over the network.
    ---@field queue_count integer
    ---@field queue_position integer The next segment of `queue` to ask.

    ---@type dreamwork.std.Network | nil
    local network

    --- The revision of the applied manifest, `-1` before the first one.
    local applied_revision = -1

    --- The manifest that arrived while the previous one was applied.
    ---
    ---@type dreamwork.transport.Manifest | nil
    local pending_manifest

    local is_applying = false

    --- The number of the last bundle request, continued by a reloaded transport,
    --- so the downloads of the previous instance never take the answers to the new one.
    local last_ticket = transport.Ticket or 0

    --- The bundle the segments go to.
    ---
    ---@type dreamwork.transport.Download | nil
    local current_download

    --- Counts the file as downloaded (or not) and tells about it.
    ---
    ---@param entry dreamwork.transport.ManifestEntry
    ---@param method string
    ---@param success boolean
    local function file_done( entry, method, success )
        Received:call( entry, method, success )
    end

    --- Tells about the progress, the compressed bytes are scaled to the size of the files.
    ---
    ---@param download dreamwork.transport.Download
    ---@param done_bytes integer
    local function report_progress( download, done_bytes )
        -- the partial bytes of a network message count its header too, so the progress never goes back
        local compressed_size = download.compressed_size
        if compressed_size ~= 0 and progress_total ~= 0 and done_bytes > download.reported_bytes then
            download.reported_bytes = done_bytes
            Progress:call( math_min( math_floor( progress_total * (done_bytes / compressed_size) ), progress_total ), progress_total )
        end
    end

    --- Waits until `wake` or the timeout.
    ---
    ---@param download dreamwork.transport.Download
    ---@param seconds number
    ---@async
    local function wait( download, seconds )
        local co = coroutine_running()
        ---@cast co thread

        download.thread = co

        local timeout_id = setTimeout( function()
            if download.thread == co then
                download.thread = nil
                futures_wakeup( co )
            end
        end, seconds )

        futures_pending()

        download.thread = nil
        clearTimeout( timeout_id )
    end

    ---@param download dreamwork.transport.Download
    local function wake( download )
        local co = download.thread
        if co ~= nil then
            download.thread = nil
            futures_wakeup( co )
        end
    end

    ---@type dreamwork.std.console.Variable<integer>
    local cache_lifetime = console_Variable( {
        name = dreamwork.selectVariableName( "transport_cache_lifetime" ),
        description = "The number of days the files downloaded from servers are kept for since their last use, '0' keeps them forever.",
        type = "integer",
        default = 30,
        min = 0,
        max = 3650,
        archive = true,
        hidden = true
    } )

    ---@type dreamwork.std.console.Variable<integer>
    local cache_size = console_Variable( {
        name = dreamwork.selectVariableName( "transport_cache_size" ),
        description = "The size of all files downloaded from servers in MiB, the least recently used ones are deleted first, '0' does not limit it.",
        type = "integer",
        default = 2048,
        min = 0,
        max = 1048576,
        archive = true,
        hidden = true
    } )

    local dreamwork_storage = dreamwork.storage
    local storage_transport = dreamwork_storage.transport

    --- The start of this session, the cleanup never deletes the files used since.
    local session_start = transport.SessionStart or time_now( "ms", false )
    transport.SessionStart = session_start

    ---@param hash string
    ---@return string
    local function cache_path( hash )
        return CACHE_DIRECTORY .. "/" .. hash .. ".dat"
    end

    --- Deletes the cached file and its record.
    ---
    ---@param hash string
    local function drop_cache( hash )
        pcall( vfs_deleteFile, cache_path( hash ), true )
        exceptions_call( storage_transport.delete, hash )
    end

    --- Writes the downloaded file into the cache.
    ---
    ---@param hash string
    ---@param content string
    ---@async
    local function write_cache( hash, content )
        if exceptions_call( vfs_writeFile, cache_path( hash ), content ) then
            exceptions_call( storage_transport.write, hash, #content, CRC32_digest( content ) )
        end
    end

    --- Returns the cached file, checked by its size and CRC-32, and marks it as used.
    ---
    ---@param entry dreamwork.transport.ManifestEntry
    ---@return dreamwork.transport.File | nil
    ---@async
    local function read_cache( entry )
        local hash = entry.hash

        local file_path = cache_path( hash )
        if not vfs_isFile( file_path ) then
            return nil
        end

        if vfs_size( file_path ) ~= entry.size then
            drop_cache( hash )
            return nil
        end

        local success, content = pcall( vfs_readFile, file_path )
        if not success or #content ~= entry.size then
            return nil
        end

        local record = storage_transport.read( hash )
        if record == nil then
            -- cached before the records existed, checked once with its hash
            if SHA256_digest( content, true ) ~= hash then
                drop_cache( hash )
                return nil
            end

            exceptions_call( storage_transport.write, hash, entry.size, CRC32_digest( content ) )
        elseif record.size ~= entry.size or CRC32_digest( content ) ~= record.checksum then
            dreamwork.Logger:warn( "Transport cache of '%s' is damaged, it is downloaded again.", entry.name )
            drop_cache( hash )
            return nil
        else
            exceptions_call( storage_transport.touch, hash )
        end

        ---@type dreamwork.transport.File
        return {
            name = entry.name,
            content = content,
            hash = entry.hash,
            size = entry.size
        }
    end

    --- Returns the base URL of the segments, `nil` if the server cannot be reached over http.
    ---
    ---@param manifest dreamwork.transport.Manifest
    ---@return string | nil
    local function http_base( manifest )
        local url = manifest.url
        if url ~= "" then
            if string_sub( url, -1 ) ~= "/" then
                url = url .. "/"
            end

            return url
        end

        -- the web server of `static` has no default address
        if manifest.transport == "static" then
            return nil
        end

        return string_format( "http://%s:%d%s", ipv4_toString( server.ipv4 ), manifest.port, HTTP_ROUTE )
    end

    ---@param download dreamwork.transport.Download
    ---@param index integer
    ---@return integer
    local function segment_length( download, index )
        if index < download.segment_count then
            return download.segment_size
        end

        return download.compressed_size - (download.segment_count - 1) * download.segment_size
    end

    --- Asks the server for the next queued segments, up to `NETWORK_WINDOW` bytes at once.
    ---
    ---@param download dreamwork.transport.Download
    local function request_segments( download )
        local current_network = network
        if current_network == nil or download.is_lost or download.is_corrupt then
            return
        end

        ---@type integer[]
        local indices = {}
        local count = 0

        local queue, queue_count = download.queue, download.queue_count
        local position = download.queue_position

        local requested, segments = download.requested, download.segments
        local free = math_max( 1, math_floor( NETWORK_WINDOW / download.segment_size ) ) - download.waiting

        while count < free and position <= queue_count do
            local index = queue[ position ]
            position = position + 1

            -- the http workers that outlived their timeout can still bring segments
            if segments[ index ] == nil then
                requested[ index ] = true

                count = count + 1
                indices[ count ] = index
            end
        end

        download.queue_position = position

        if count == 0 then
            return
        end

        download.waiting = download.waiting + count

        current_network:transmit( function( _, writer )
            writer:writeUInt( OPCODE_SEGMENTS, 8 )
            writer:writeString( download.id )
            writer:writeUInt( count, 32 )

            for index = 1, count, 1 do
                writer:writeUInt( indices[ index ], 32 )
            end
        end )
    end

    local add_segment

    --- Keeps the segment, asks for more segments over the network and wakes the download once they all came.
    ---
    ---@param download dreamwork.transport.Download
    ---@param index integer
    ---@param data string
    local function store_segment( download, index, data )
        local requested = download.requested

        local is_requested = requested[ index ] == true
        if is_requested then
            requested[ index ] = nil
            download.waiting = download.waiting - 1
        end

        -- a late http segment can come before or after it was asked over the network
        if download.segments[ index ] == nil then
            add_segment( download, index, data )
        end

        if is_requested then
            request_segments( download )

            if download.waiting == 0 then
                wake( download )
            end
        end
    end

    --- Keeps the segment and gives the segments that are in order to the decompressor.
    ---
    ---@param download dreamwork.transport.Download
    ---@param index integer
    ---@param data string
    function add_segment( download, index, data )
        local segments = download.segments
        segments[ index ] = data

        download.received = download.received + 1
        download.done_bytes = download.done_bytes + #data
        report_progress( download, download.done_bytes )

        local decompressor = download.decompressor
        if decompressor == nil then
            return
        end

        local next_segment = download.next_segment

        ::segment_feeder::

        local segment = segments[ next_segment ]
        if segment ~= nil and not download.is_corrupt then
            ---@cast segment string

            -- the segment is not kept once the decompressor has it
            segments[ next_segment ] = true
            next_segment = next_segment + 1

            if not pcall( decompressor.update, decompressor, segment ) then
                download.is_corrupt = true
            end

            goto segment_feeder
        end

        download.next_segment = next_segment
    end

    --- Downloads segments over http until there are none left.
    ---
    ---@param download dreamwork.transport.Download
    ---@param base string
    ---@param is_static boolean `true` if the segments are the files of the `static` transport, sent as they are, not in base64.
    ---@async
    local function http_worker( download, base, is_static )
        local prefix = base .. download.id .. "-"
        local extension = is_static and STATIC_EXTENSION or ".bin"

        ::segment_fetcher::

        local index = download.next_index
        if index <= download.segment_count and download.http_failures < MAX_HTTP_FAILURES and not download.is_corrupt then
            download.next_index = index + 1

            local success, response = pcall( http_request, {
                method = "GET",
                url = prefix .. index .. extension,
                timeout = 120
            } )

            local data
            if success and response.status == 200 then
                ---@type string | nil
                local content = response.body

                if not is_static then
                    local decoded
                    decoded, content = pcall( base64_decode, content )
                    if not decoded then
                        content = nil
                    end
                end

                if content ~= nil and #content == segment_length( download, index ) then
                    data = content
                end
            end

            if data == nil then
                download.http_failures = download.http_failures + 1

                local failed_count = download.failed_count + 1
                download.failed[ failed_count ] = index
                download.failed_count = failed_count
            else
                download.http_failures = 0
                store_segment( download, index, data )
            end

            goto segment_fetcher
        end

        local workers = download.workers - 1
        download.workers = workers

        if workers == 0 and download.is_fetching then
            wake( download )
        end
    end

    --- Downloads the segments over http, `dreamwork_transport_http_connections` at once.
    ---
    ---@param download dreamwork.transport.Download
    ---@param base string
    ---@param is_static boolean
    ---@async
    local function download_http( download, base, is_static )
        local worker_count = math_min( http_connections.value, download.segment_count )

        download.next_index = 1
        download.workers = worker_count
        download.is_fetching = true

        for _ = 1, worker_count, 1 do
            futures_run( http_worker, nil, download, base, is_static )
        end

        -- the requests time out by themselves, the timeout here is the last resort
        if download.workers ~= 0 then
            wait( download, 120 * math_ceil( download.segment_count / worker_count ) + STALL_TIMEOUT )
        end

        -- the workers that are still running after the timeout leave their segments to the network
        download.next_index = download.segment_count + 1
        download.is_fetching = false
    end

    --- Downloads the missing segments over the network.
    ---
    ---@param download dreamwork.transport.Download
    ---@async
    local function download_network( download )
        if network == nil then
            return
        end

        local queue = download.queue
        local count = 0

        local segments = download.segments

        for index = 1, download.segment_count, 1 do
            if segments[ index ] == nil then
                count = count + 1
                queue[ count ] = index
            end
        end

        if count == 0 then
            return
        end

        download.queue_count = count
        download.queue_position = 1
        download.used_network = true

        request_segments( download )

        if download.waiting == 0 then
            return
        end

        -- the network gives up on stalled transfers, here it is given up when nothing comes for a while
        ::segment_waiter::

        local received = download.received
        wait( download, STALL_TIMEOUT )

        if download.waiting ~= 0 and not download.is_lost and not download.is_corrupt and download.received ~= received then
            goto segment_waiter
        end
    end

    --- Decompresses the received segments.
    ---
    ---@param download dreamwork.transport.Download
    ---@return string | nil data The joined contents of the files, `nil` if they cannot be decompressed.
    ---@async
    local function unpack_bundle( download )
        local decompressor = download.decompressor
        if decompressor ~= nil then
            if download.is_corrupt then
                return nil
            end

            local success, data = pcall( decompressor.flush, decompressor )
            if not success then
                return nil
            end

            return data
        end

        local data = table_concat( download.segments, "", 1, download.segment_count )

        if download.method == "lzma" then
            local success, decompressed_data = pcall( lzma_decompress, data )
            if not success then
                return nil
            end

            return decompressed_data
        end

        return data
    end

    --- Downloads the bundle of the files and keeps the files in the cache.
    ---
    ---@param manifest dreamwork.transport.Manifest
    ---@param hashes string[] The hashes of the files, sorted, without duplicates.
    ---@param count integer
    ---@param entries_by_hash table<string, dreamwork.transport.ManifestEntry[]>
    ---@param files table<string, dreamwork.transport.File>
    ---@async
    local function download_bundle( manifest, hashes, count, entries_by_hash, files )
        local current_network = network

        last_ticket = (last_ticket + 1) % 0x100000000
        transport.Ticket = last_ticket

        local ticket = last_ticket

        ---@type dreamwork.transport.Download
        local download = {
            ticket = ticket,
            method = "none",
            size = 0,
            compressed_size = 0,
            segment_size = 0,
            segment_count = 0,
            segments = {},
            received = 0,
            done_bytes = 0,
            reported_bytes = 0,
            next_segment = 1,
            is_corrupt = false,
            is_lost = false,
            used_network = false,
            next_index = 1,
            workers = 0,
            is_fetching = false,
            http_failures = 0,
            failed = {},
            failed_count = 0,
            requested = {},
            waiting = 0,
            queue = {},
            queue_count = 0,
            queue_position = 1
        }

        ---@type string | nil
        local data

        if current_network ~= nil then
            current_download = download

            current_network:transmit( function( _, writer )
                writer:writeUInt( OPCODE_BUNDLE, 8 )
                writer:writeUInt( ticket, 32 )
                writer:writeUInt( count, 16 )

                for index = 1, count, 1 do
                    writer:writeString( hashes[ index ] )
                end
            end )

            wait( download, BUNDLE_TIMEOUT )

            local id = download.id
            local method = download.method

            if id == nil or id == "" then
                dreamwork.Logger:error( "Transport did not get the bundle of %d file(s) from the server.", count )
            elseif method == "deflate" or method == "gzip" or method == "lzma" or method == "none" then
                if method == "deflate" then
                    download.decompressor = deflate.Decompressor()
                elseif method == "gzip" then
                    download.decompressor = gzip.Decompressor()
                end

                local transport_name = manifest.transport
                if (transport_name == "http" or transport_name == "static") and download.segment_count ~= 0 then
                    local base = http_base( manifest )
                    if base ~= nil then
                        download_http( download, base, transport_name == "static" )
                    end
                end

                if not download.is_corrupt then
                    download_network( download )
                end

                if download.received == download.segment_count then
                    data = unpack_bundle( download )
                end

                if data == nil then
                    dreamwork.Logger:error( "Transport failed to receive the bundle '%s' (%s, %d of %d segment(s)).", id, method, download.received, download.segment_count )
                elseif #data ~= download.size then
                    dreamwork.Logger:error( "Transport received the bundle '%s' of %d bytes, expected %d.", id, #data, download.size )
                    data = nil
                end
            else
                dreamwork.Logger:error( "Transport got the bundle '%s' with unknown compression '%s'.", id, method )
            end

            if current_download == download then
                current_download = nil
            end
        end

        local method = download.used_network and "network" or manifest.transport
        local position = 1

        for index = 1, count, 1 do
            local hash = hashes[ index ]
            local entries = entries_by_hash[ hash ]

            local size = entries[ 1 ].size
            local content

            if data ~= nil then
                content = string_sub( data, position, position + (size - 1) )
                position = position + size

                if SHA256_digest( content, true ) == hash then
                    write_cache( hash, content )
                else
                    dreamwork.Logger:error( "Transport received damaged '%s'.", entries[ 1 ].name )
                    content = nil
                end
            end

            for entry_index = 1, #entries, 1 do
                local entry = entries[ entry_index ]

                if content ~= nil then
                    files[ entry.name ] = {
                        name = entry.name,
                        content = content,
                        hash = hash,
                        size = size
                    }
                end

                file_done( entry, method, content ~= nil )
            end
        end
    end

    --- Deletes the cached files that are too old or over the size limit, and the files without a record
    --- (cached before the records existed and not used since, or not written completely).
    local function prune_cache()
        local hashes, hash_count = storage_transport.prune( session_start, cache_lifetime.value * 86400000, cache_size.value * 0x100000 )

        for index = 1, hash_count, 1 do
            pcall( vfs_deleteFile, cache_path( hashes[ index ] ), true )
        end

        local success, names, name_count = pcall( vfs_search, CACHE_DIRECTORY, "*.dat" )
        if not success then
            return
        end

        local orphan_count = 0

        for index = 1, name_count, 1 do
            local hash = string_match( names[ index ], "^(%x+)%.dat$" )
            if hash == nil or storage_transport.read( hash ) == nil then
                orphan_count = orphan_count + 1
                pcall( vfs_deleteFile, CACHE_DIRECTORY .. "/" .. names[ index ], true )
            end
        end

        if hash_count + orphan_count ~= 0 then
            dreamwork.Logger:debug( "Transport cache cleanup: %d old file(s) and %d file(s) without a record deleted.", hash_count, orphan_count )
        end
    end

    ---@param manifest dreamwork.transport.Manifest
    ---@async
    local function apply_manifest( manifest )
        ---@type table<string, dreamwork.transport.File>
        local files = {}

        ---@type dreamwork.transport.ManifestEntry[]
        local missing = {}
        local missing_count = 0

        ---@type string[]
        local hashes = {}
        local hash_count = 0

        ---@type table<string, dreamwork.transport.ManifestEntry[]>
        local entries_by_hash = {}

        local total_bytes = 0
        local entries = manifest.entries

        for index = 1, manifest.entry_count, 1 do
            local entry = entries[ index ]

            local file = read_cache( entry )
            if file == nil then
                missing_count = missing_count + 1
                missing[ missing_count ] = entry

                -- files with the same content are downloaded once
                local hash = entry.hash
                local same = entries_by_hash[ hash ]
                if same == nil then
                    entries_by_hash[ hash ] = { entry }

                    hash_count = hash_count + 1
                    hashes[ hash_count ] = hash

                    total_bytes = total_bytes + entry.size
                else
                    same[ #same + 1 ] = entry
                end
            else
                files[ entry.name ] = file
            end
        end

        if missing_count ~= 0 then
            progress_total = total_bytes
            Receiving:call( missing, missing_count, total_bytes, manifest.transport )

            table_sort( hashes )
            download_bundle( manifest, hashes, hash_count, entries_by_hash, files )
        end

        applied_revision = manifest.revision
        transport.Files = files
        Updated:call( files )

        -- the files of this manifest are marked as used already
        exceptions_call( prune_cache )
    end

    ---@param manifest dreamwork.transport.Manifest
    local function apply( manifest )
        if is_applying then
            pending_manifest = manifest
            return
        end

        is_applying = true

        futures_run( apply_manifest, function()
            is_applying = false

            local next_manifest = pending_manifest
            if next_manifest ~= nil then
                pending_manifest = nil
                apply( next_manifest )
            end
        end, manifest )
    end

    local function request()
        if network ~= nil then
            network:transmit( function( _, writer )
                writer:writeUInt( OPCODE_REQUEST, 8 )
            end )
        end
    end

    ---@param reader dreamwork.std.BinaryReader
    local function receive_manifest( reader )
        ---@type dreamwork.transport.Manifest
        local manifest = {
            revision = reader:readUInt( 32 ),
            ready = reader:readBoolean(),
            transport = reader:readString(),
            port = reader:readUInt( 16 ),
            url = reader:readString(),
            entries = {},
            entry_count = 0
        }

        -- the server tells about the ready files with an update
        if not manifest.ready or manifest.revision == applied_revision then
            return
        end

        local entries = manifest.entries
        local count = reader:readUInt( 16 )

        for index = 1, count, 1 do
            entries[ index ] = {
                name = reader:readString(),
                hash = reader:readString(),
                size = reader:readUInt( 32 )
            }
        end

        manifest.entry_count = count
        apply( manifest )
    end

    ---@param reader dreamwork.std.BinaryReader
    local function receive_bundle_info( reader )
        local download = current_download
        if download == nil or download.id ~= nil or reader:readUInt( 32 ) ~= download.ticket then
            return
        end

        local id = reader:readString()
        download.id = id

        if id ~= "" then
            local compression_id = reader:readUInt( COMPRESSION_BITS )
            download.method = COMPRESSION_NAMES[ compression_id ] or string_format( "#%d", compression_id )
            download.size = reader:readUInt( 32 )
            download.compressed_size = reader:readUInt( 32 )
            download.segment_size = reader:readUInt( 32 )
            download.segment_count = reader:readUInt( 32 )
        end

        wake( download )
    end

    ---@param reader dreamwork.std.BinaryReader
    local function receive_segment( reader )
        local download = current_download
        if download == nil or reader:readString() ~= download.id then
            return
        end

        local index = reader:readUInt( 32 )

        if not reader:readBoolean() then
            download.is_lost = true
            wake( download )
            return
        end

        if not download.requested[ index ] then
            return
        end

        local data = reader:readCountedString( 32 )
        if #data ~= segment_length( download, index ) then
            return
        end

        store_segment( download, index, data )

        if download.is_corrupt then
            wake( download )
        end
    end

    ---@param _ dreamwork.std.Network
    ---@param reader dreamwork.std.BinaryReader
    local function receive( _, reader )
        local opcode = reader:readUInt( 8 )
        if opcode == OPCODE_MANIFEST then
            receive_manifest( reader )
        elseif opcode == OPCODE_BUNDLE_INFO then
            receive_bundle_info( reader )
        elseif opcode == OPCODE_SEGMENT then
            receive_segment( reader )
        elseif opcode == OPCODE_UPDATE then
            if reader:readUInt( 32 ) ~= applied_revision then
                request()
            end
        end
    end

    ---@return dreamwork.std.Network
    local function open_network()
        return NetworkClass( "dreamwork.transport", true )
    end

    --- Reports the progress of the segment being received over the network.
    ---
    ---@param _ dreamwork.std.Network
    ---@param _peer dreamwork.std.Client | nil
    ---@param is_outgoing boolean
    ---@param done_bytes integer
    local function watch_progress( _, _peer, is_outgoing, done_bytes )
        local download = current_download
        if not is_outgoing and download ~= nil and download.waiting ~= 0 then
            report_progress( download, download.done_bytes + done_bytes )
        end
    end

    --- Opens the network and asks the server for the files.
    local function connect()
        if network == nil then
            -- the server registers the network, the client can only open it
            local success, result = pcall( open_network )
            if not success then
                dreamwork.Logger:warn( "The server has no transport, packages from the server are not available." )
                return
            end

            ---@cast result dreamwork.std.Network

            network = result
            result.limit = 0x40000000

            result:clear()
            result:attach( receive )

            -- networks are kept by name, the watcher of a reloaded transport is replaced
            local previous_watcher = transport.Watcher
            if previous_watcher ~= nil then
                result:unwatch( previous_watcher )
            end

            transport.Watcher = watch_progress
            result:watch( watch_progress )
        end

        request()
    end

    --- [CLIENT]
    ---
    --- Asks the server for the files once the client is initialized, called by the package manager.
    ---
    function transport.startup()
        transport.Started = true

        ---@param client dreamwork.std.Client
        engine_hook.catch( "dreamwork.client.initialized", "modules.transport.connect", function( client )
            if client:isLocal() then
                connect()
            end
        end )

        -- started after the initialization (reload)
        local client = Client.getLocal()
        if client ~= nil and client.is_initialized then
            connect()
        end
    end

end

-- a reloaded transport starts again by itself, the package manager started the previous one
if transport.Started then
    transport.startup()
end
