# DreamWork — Garry's Mod Lua Runtime

> ⚠ **The project is still in development.** Expect unstable behaviour, bugs and API changes.

![under-construction](https://user-images.githubusercontent.com/2846578/50296605-d76e5780-0448-11e9-9e16-39917d203b98.gif)

## Description

DreamWork is a runtime and standard library for Garry's Mod Lua. It extends the
game's API and replaces slow native paths with optimised (LuaJIT-friendly) implementations.
It runs on the **server, client and main menu** realms. Everything is documented with
LuaLS annotations, so editors get full type hints.

After many years of hard work I can finally say that we have created a truly powerful runtime for developers ;p

Each feature below is marked with the realms it runs in:
`[SHARED]` = server + client, `[MENU]`, `[CLIENT]`, `[SERVER]`.

---

## Table of Contents

- [Core](#core)
- [Object Model & Data Structures](#object-model--data-structures)
- [Events & Async](#events--async)
- [Math & Geometry](#math--geometry)
- [Text & Encodings](#text--encodings)
- [Binary Data](#binary-data)
- [Data Formats](#data-formats)
- [Compression & Archives](#compression--archives)
- [Checksums & Cryptography](#checksums--cryptography)
- [Networking](#networking)
- [Steam](#steam)
- [Files & Storage](#files--storage)
- [Console](#console)
- [Graphics & UI](#graphics--ui)
- [Web & WebAssembly](#web--webassembly)
- [Lua Tooling](#lua-tooling)
- [Developer Tools](#developer-tools)
- [Optional Native Integrations](#optional-native-integrations)

---

## Core

| Module                                  | Description                                                                                                                                      |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `dreamwork.load`                        | Realm-aware file loader. It handles `include`/`AddCSLuaFile`, with a `dofile` fallback.                                                          |
| `std.raw`                               | Metatable-free primitives (`raw.index`, `raw.pairs`, `raw.tonumber`, …).                                                                         |
| `std` type metatables                   | `Nil`, `Boolean`, `Number`, `Integer`, `String`, `Function`, `Thread` metatables, plus type checks and conversions (`toboolean`, `tonumber`, …). |
| `std.debug`                             | Extended debug library.                                                                                                                          |
| `std.gc` / `gc.ext`                     | Garbage-collector control, table rules and automatic cleanup of tracked tables when engine objects are destroyed.                                |
| `std.jit` / `std.ffi`                   | JIT control, plus the LuaJIT FFI when the host allows it (e.g. through HolyLib).                                                                 |
| `std.os`, `std.coroutine`               | Wrappers over the standard libraries with extensions.                                                                                            |
| `std.table`, `std.string`, `std.vararg` | Extended standard libraries: key paths, interpolation, FNV hashes, vararg slicing, …                                                             |
| `std.ascii`                             | Byte classification helpers (letters, digits, whitespace, …).                                                                                    |
| `std.bit`, `raw.ext`                    | Bit operations: arithmetic shift, bit reversal, signed/unsigned conversion.                                                                      |
| `std.Symbol`, `std.null`                | Interned, identity-compared unique identifiers.                                                                                                  |
| `detour`                                | Runtime patching/hooking of engine functions. Hooking a function twice replaces the first hook instead of stacking.                              |
| `exceptions` / `std.Error`              | Error classes with captured call stacks that skip hidden frames, and a central error pipeline.                                                   |

## Object Model & Data Structures

- **`std.class`**: classes with inheritance, `__init`, private and protected members, and full LuaLS typing (see [`classes.md`](classes.md)).
- **`std.Stack`**: LIFO. **`std.Queue`**: FIFO/deque. **`std.Node`**: tree. All three can be serialized.
- **`std.Mixin`**: an ordered chain of transformer functions.
- **`std.Version`**: [SemVer 2.0.0](https://semver.org/) parsing, comparison and ranges.
- **`std.URL`**: a [WHATWG URL Standard](https://url.spec.whatwg.org/) parser with relative resolution and lazily computed fields.
- **`std.uuid`**: [RFC 9562](https://www.rfc-editor.org/rfc/rfc9562) UUID generation, parsing and formatting.
- **`std.ipv4` / `std.IPv6`**: IP address parsing and formatting ([RFC 5952](https://datatracker.ietf.org/doc/html/rfc5952)), plus networks, prefixes and classful networks.

## Events & Async

- **`std.Hook`**: a named, prioritized event pipeline with stages and return values.
- **`std.Event`**: a lighter hook with priorities but no stages or return values.
- **`std.Emitter`**: a minimal per-class event registry.
- **`std.Timer`** and the engine timer module: heap-scheduled named timers, driven by `timer` or `Think`.
- **`std.futures`**: Python-style futures and async/await on coroutines (`futures.run`, `Future:await`, …).
- **Engine hook bridge**: maps `GM:*` hooks and Source game events to DreamWork events, sorted by priority.

## Math & Geometry

- **`std.math`**: an extended math library (integer checks, clamping, interpolation, …).
- **`std.Vector2`, `std.Vector3`, `std.Angle3`**: component-wise operators in Source engine conventions.
- **`std.Quaternion`**: rotations without gimbal lock.
- **`std.VMatrix`**: 4×4 transformation matrices (rotation, scale, translation, inverse).
- **`std.BigInteger`**: arbitrary-precision signed integers.
- **`std.BigFixed`**: arbitrary-precision fixed-point decimals.
- **`std.color`**: color conversion and manipulation.
- **`std.unit`**: physical unit conversion (mass, temperature, length, data sizes in SI/IEC, …).
- **`std.time`**: Unix timestamps in any unit, timezones, and date parsing and formatting (ISO 8601, …).

## Text & Encodings

- **`std.utf8`**: a strict rewrite of Lua's `utf8` (Unicode Table 3-7 validation) with extra functions.
- **`std.utf16`, `std.utf32`**: string manipulation in UTF-16 and UTF-32.
- **`std.unicode`**: code point properties and scalar value checks.
- **`std.base16`, `std.base32`, `std.base64`**: encoders and decoders with custom alphabets.
- **`std.percent`**: URL percent-encoding ([RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986)).
- **`std.punycode`**: Punycode ([RFC 3492](https://datatracker.ietf.org/doc/html/rfc3492)).

## Binary Data

- **`std.bitpack`**: reads and writes bit fields in integers and bytes.
- **`std.bytepack`**: packs and unpacks numbers (8–64 bit ints, floats, fixed-point) as bytes.
- **`std.pack`**: the same over strings, plus null-terminated strings and bit-level reads.
- **`std.BinaryReader` / `std.BinaryWriter`**: bit-addressable cursors. They use the same LSB-first layout as Source's `bf_read`/`bf_write`, and can switch between big and little endian.

## Data Formats

- **`std.json`**: a strict [RFC 8259](https://datatracker.ietf.org/doc/html/rfc8259) JSON encoder and decoder with a depth limit.
- **`std.vdf`**: Valve KeyValues (VDF) parsing and serialization.
- **`std.XMLNode`**: XML parsing and building.
- **`std.HTMLNode`**: HTML parsing and building with an ordered, DOM-like child list.

## Compression & Archives

| Library / Class | Description                                                                                                      |
| --------------- | ---------------------------------------------------------------------------------------------------------------- |
| `std.deflate`   | Raw DEFLATE ([RFC 1951](https://www.rfc-editor.org/rfc/rfc1951)) with streaming `Compress`/`Decompress` classes. |
| `std.zlib`      | zlib streams ([RFC 1950](https://www.rfc-editor.org/rfc/rfc1950)).                                               |
| `std.gzip`      | gzip streams ([RFC 1952](https://www.rfc-editor.org/rfc/rfc1952)).                                               |
| `std.lz4`       | LZ4 block format.                                                                                                |
| `std.lzw`       | Variable-width LZW.                                                                                              |
| `std.lzma`      | LZMA in the `util.Compress` format. With HolyLib, calls made from a coroutine run on a separate thread.          |
| `Zip`           | ZIP archives: read and write, deflate and LZMA entries, ZIP64, extended timestamps.                              |
| `Tar`           | Tar archives: read and write.                                                                                    |
| `Addon`         | Garry's Mod `.gma` archives: read, write and mount, with `gmad` type, tag and wildcard rules.                    |

## Checksums & Cryptography

- **Checksums**: CRC-8/16/32, Adler-32, Fletcher-16/32.
- **Hashes**: `MD5`, `SHA1`, `SHA256`, `SHA384`, `SHA512`. All are incremental hash classes.
- **`crypto.hmac`**: HMAC ([RFC 2104](https://datatracker.ietf.org/doc/html/rfc2104)).
- **`crypto.pbkdf2`**: PBKDF2 password derivation.
- **`crypto.hkdf`**: HKDF key derivation ([RFC 5869](https://datatracker.ietf.org/doc/html/rfc5869)).
- **`crypto.chacha20`**: the ChaCha20 stream cipher ([RFC 8439](https://datatracker.ietf.org/doc/html/rfc8439)).
- **`crypto.random`**: a cryptographically secure random generator (ChaCha20 with fast key erasure) for tokens, keys, nonces and salts.
- **String hashes**: FNV-0, FNV-1 and FNV-1a.

## Networking

| Feature          | Realm         | Description                                                                                                                                                            |
| ---------------- | ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `std.Network`    | SHARED        | A named two-way server↔client channel with no 64 KiB limit. Large payloads are segmented and streamed with ACKs, retransmission, congestion control and a CRC32 check. |
| `std.Message`    | SHARED + MENU | Messages over console/user-message channels. It is the only route that reaches the **menu** state (server → client → menu).                                            |
| `std.http`       | SHARED + MENU | An async HTTP client with response caching, form encoding and an [RFC 6265](https://datatracker.ietf.org/doc/html/rfc6265) `CookieJar`.                                |
| HTTP backends    | SHARED + MENU | Picks the best available backend: `reqwest`, then `chttp`, then the built-in `HTTP`.                                                                                   |
| `http.Server`    | SERVER        | An HTTP server with routes and timeouts (requires HolyLib).                                                                                                            |
| `http.github`    | SHARED + MENU | A GitHub API client that handles rate limits.                                                                                                                          |
| `http.facepunch` | MENU          | The Facepunch API.                                                                                                                                                     |
| `std.WebSocket`  | SHARED + MENU | A WebSocket client with reconnect backoff and graceful close. The backend is `gwsockets`, or a headless browser on client and menu.                                    |

## Steam

- **`std.steam`**: Steam API helpers, `EResult` messages and `SteamError`.
- **`steam.Identifier`**: SteamID parsing and conversion (SteamID, Steam3, SteamID64, universes, account types, instances).
- **`steam.achievements`**: Garry's Mod achievements (client and menu).

## Files & Storage

- **`vfs`**: a virtual file system. Paths are absolute from the game root and relative paths resolve against the calling file. It layers search paths overlayfs-style (writes go to a memory layer on top), and uses async I/O where available.
- **`std.fs`**: `File` and `Directory` objects. The same path always returns the same object.
- **`std.path`**: POSIX-style path manipulation that never touches the disk.
- **`std.sqlite`**: a wrapper for the local SQLite database.
- **`storage`**: persistent key/value storage backed by SQLite, with JSON values and an in-memory read cache.
- **Mounts tracking**: tracks mounted games and addons, and fires `dreamwork.game.mount` events.

## Console

- **`std.console`**: console output, visibility events and command execution.
- **`console.Variable`**: console variables (ConVars) that parse values the way the engine does and fire change events.
- **`console.Command`**: console commands with execute handlers and autocompletion.
- **`console.Logger`**: colored, leveled loggers.

## Graphics & UI

Client and menu only.

- **`std.window`**: window size and focus state.
- **`std.ViewportLayout`**: CSS-like display units (`px`, `vw`, `vh`, `vmin`, …) resolved against the window size.

## Web & WebAssembly

Client and menu only.

- **`std.WebClient`**: a headless Chromium/Awesomium browser. It can navigate to a URL or HTML, run JavaScript and read DOM snapshots.
- **`std.WASM`**: runs WebAssembly modules inside a `WebClient`. Exports are async, `i64` values map to `BigInteger`, and imports can be JavaScript or Lua functions.

## Lua Tooling

- **`lua.lexer`**: a fast Lua 5.1 / LuaJIT tokenizer that stores tokens in flat arrays.
- **`lua.parser`**: builds an AST and raises `SyntaxError` with locations.
- **`lua.generator`**: turns an AST back into Lua source and adds parentheses automatically.
- **`sigil`** ("Code Fabric"): a Lua preprocessor with macros, includes and pre-build code transformations.

## Developer Tools

- **CLI**: `dreamwork_sci` (server) and `dreamwork_cci` (client and menu) console interfaces. They provide grouped commands with `help`, autocompletion and colored output:
  - `vfs`: browse and manage the virtual file system;
  - `http` / `http github`: HTTP tools and the GitHub token and rate limit;
  - `mcp`: MCP bridge controls.
- **MCP bridge** (`modules/mcp.lua`): AI tooling through [gm_mcp](https://github.com/unknown-gd/gm_mcp). It can execute Lua on the server or clients, list entities and players, take screenshots and report collected errors.

## Optional Native Integrations

DreamWork works without any of these, but picks them up when they are installed:

| Module                                     | Used for                                                                           |
| ------------------------------------------ | ---------------------------------------------------------------------------------- |
| [HolyLib](https://holylib.raphaelit7.com/) | FFI access, threaded LZMA, the HTTP server, and fixed `newproxy`/`__gc` behaviour. |
| `reqwest` / `chttp`                        | Better HTTP clients.                                                               |
| `gwsockets`                                | Native WebSocket backend.                                                          |
| `gmsv_workshop`                            | Workshop access on the server.                                                     |
| `gm_mcp`                                   | The MCP bridge.                                                                    |

## Bugs and Suggestions

If you have an idea or find a bug, please open an issue.

## Documentation

All public APIs are annotated for [LuaLS](https://luals.github.io/). Type stubs for DreamWork,
Garry's Mod, HolyLib and LuaJIT are in [`meta/`](meta/). The class system is described in
[`classes.md`](classes.md). Full documentation is in progress.

## License

See [LICENSE](LICENSE).
