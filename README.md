# DreamWork — Garry's Mod Lua Runtime

> ⚠ **The project is still in development.** Expect unstable behaviour, bugs and API changes.

![under-construction](https://user-images.githubusercontent.com/2846578/50296605-d76e5780-0448-11e9-9e16-39917d203b98.gif)

## Description

DreamWork is a runtime and standard library for Garry's Mod Lua. It extends the
game's API and replaces slow native paths with optimised (LuaJIT-friendly) implementations.
It runs on the **server, client and main menu** realms. Everything is documented with
LuaLS annotations, so editors get full type hints.

After many years of hard work I can finally say that we have created a truly powerful runtime for developers ;p

API surface for `std.*` and related libraries lives in the source annotations (and stubs under [`meta/`](meta/)), not in this README.

Realm tags used below: `[SHARED]` = server + client, `[MENU]`, `[CLIENT]`, `[SERVER]`.

---

## Table of Contents

- [Packages](#packages)
- [File Transport](#file-transport)
- [Developer Tools](#developer-tools)
- [Optional Native Integrations](#optional-native-integrations)

---

## Packages

`dreamwork.loader` [SHARED] [MENU] is the package manager. A package is a directory or a `.zip` archive with `package.json` at its root.
Every Lua file runs in its own module environment, and the objects a package creates (hooks, timers, networks, servers, …) are cleaned up when it unloads.
On the server, client Lua is preprocessed by `sigil` (`#if LUA_SERVER` branches never leave the server) and sent with the [File Transport](#file-transport).

### Where packages come from

| Source                                     | Realms        | Notes                                                                                            |
| ------------------------------------------ | ------------- | ------------------------------------------------------------------------------------------------ |
| `addons/*/packages/*/package.json`         | server, menu  | Package folders, one addon (one git repository) holds as many as needed; the folder names do not matter. |
| `addons/*/packages/*.zip`                  | server, menu  | Package archives, `package.json` at the root of the archive.                                     |
| `packages/*/package.json`, `packages/*.zip` | server, menu | Package folders and archives in `garrysmod/packages`, outside of any addon.                      |
| `data_static/packages/*.zip.dat` of any addon | server, menu | `.zip` package archives inside Workshop addons, `.dat` is what the `gmad` whitelist allows there. |
| `data/dreamwork/packages/**`               | server, menu  | Archives downloaded from GitHub with `package install` or `import( "user/repo" )`, `package.json` at the root of the repository. |
| The server                                 | client        | The client runs only what the server sent.                                                       |

Packages are identified by `{author}/{name}@{version}` from their `package.json`, never by the folder or file name (`addons/my_addon/packages/libdd_test/package.json` with `"name": "my_lib"` is `{author}/my_lib@{version}`); `{author}` is the lowercase `author` with `_` in place of spaces and symbols, `"Pika Software"` is `pika_software`.
`package.json` right in a `packages` folder is ignored with a warning, every package goes into its own folder.
Several versions of the same package, and packages of the same name by different authors, can be installed side by side; the same id found twice keeps the first one (folders are found before archives).

> The engine keeps one file per path for all mounted addons, so two Workshop addons with the same `data_static/packages/<file>.zip.dat` hide each other. Give archives unique names: `package export` uses `{name}-{version}.zip.dat`.

```
garrysmod/addons/my_addon/packages/my_pkg/package.json
garrysmod/addons/my_addon/packages/my_pkg/lua/init.lua
garrysmod/addons/my_addon/packages/my_pkg/lua/cl_init.lua
garrysmod/addons/my_addon/packages/my_pkg/lua/client/hud.lua
garrysmod/addons/my_addon/packages/my_pkg/materials/my_pkg/icon.png
garrysmod/addons/my_addon/packages/my_lib/package.json
garrysmod/addons/my_addon/packages/my_lib/lua/init.lua
```

Every file of the package is kept in memory at `/packages/{author}/{name}@{version}` in the virtual file system, relative `File` and `Directory` paths of the package code point there.
Named objects created by a package (`Timer`, `Network`, `Message`, `NetTable`, `http.Server`, fonts, localizations) get the `{id}::` prefix, e.g. `pika_software/my_pkg@1.2.0::tick`, so packages never collide.
Nothing is mounted into the game (its file system mixes the files of every mount), so the engine does not load the materials, models or sounds of packages by itself.

### `package.json`

```json
{
    "name": "my_pkg",
    "version": "1.2.0",
    "author": "Pika Software",
    "license": "MIT",
    "description": "What the package does.",
    "repository": "user/my_pkg",
    "main": { "server": "lua/init.lua", "client": "lua/cl_init.lua" },
    "realms": [ "server", "client" ],
    "dependencies": {
        "pika_software/my_lib": "^1.0.0",
        "user/other_lib": "~2.1.0",
        "user/edge_lib": ""
    },
    "client_files": [ "lua/client/**", "lua/shared/*.lua", "materials/**" ],
    "color": "#4fc3f7"
}
```

| Field          | Type                    | Default                    | Description                                                                                                                                                                       |
| -------------- | ----------------------- | -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`         | string, **required**    |                            | Letters, digits, `_`, `-` and `.` (not only dots). With `author` it makes `{author}/{name}`, which `import( "author/name" )` finds among the installed packages.                   |
| `version`      | string, **required**    |                            | A [SemVer](https://semver.org/) version, a leading `v` is allowed (`v1.0.0` and `1.0.0` are the same package).                                                                    |
| `author`       | string                  | `"unknown"`                | The author, part of the package id and its folder, also written into exported `.gma` files.                                                                                       |
| `license`      | string                  | `"unknown"`                | The license.                                                                                                                                                                      |
| `description`  | string                  | `""`                       | The description, also written into exported `.gma` files.                                                                                                                         |
| `repository`   | string                  | the download source        | The repository of the package, `user/repo` or `https://github.com/user/repo`. Lets `import( "user/repo" )` find the installed package when `{author}/{name}` differs from it.      |
| `main`         | string or `{ [realm]: string }` | `"lua/init.lua"`   | The entrypoint, relative to the package root, must end with `.lua`. A string is used in every realm, a map picks the entrypoint per realm, see below. Its return value is what `import` gives to other packages. |
| `realms`       | string[]                | `[ "server", "client" ]`   | Where the package runs: `server`, `client`, `menu`. A package with `client` is sent to the clients even if it does not run on the server.                                         |
| `dependencies` | `{ [repo]: range }`     | `{}`                       | Packages loaded before this one, see below.                                                                                                                                       |
| `client_files` | string[]                | only the client entrypoint | Wildcards of the files sent to the clients, see below.                                                                                                                            |
| `color`        | string                  | the DreamWork color        | The title color of the package logger, a hex color code: `"#RGB"` or `"#RRGGBB"`, `#` is optional.                                                                                |

An invalid `package.json` (bad JSON, missing or invalid `name`/`version`, an entrypoint not ending with `.lua`, an unknown realm in `realms` or `main`, a realm from `realms` without an entrypoint in `main`, a dependency that is not `"user/repo": "range"`, a `client_files` entry that is not a string, a `color` that is not `#RGB` or `#RRGGBB`) is reported in the console and the package is skipped. Optional fields of the wrong type fall back to their defaults.

#### `main`

A string is the entrypoint of every realm. A map gives each realm its own entrypoint, like `init.lua` / `cl_init.lua` in gamemodes:

```json
"main": { "server": "lua/init.lua", "client": "lua/cl_init.lua", "menu": "lua/menu.lua" }
```

Every realm in `realms` needs an entrypoint, so a map without `menu` works with the default `realms` (`server` and `client`).
The client entrypoint is always sent to the clients, even if `client_files` does not match it.

#### Dependencies

Each key is the repository of the dependency, `user/repo` (or `https://github.com/user/repo`), each value is a version range, the same as `import( "user/repo@range" )`:

| Range                              | Installed package                                       | Missing package is downloaded from         |
| ---------------------------------- | ------------------------------------------------------- | ------------------------------------------ |
| `""`, `"*"`, `"latest"`            | Any version.                                            | The default branch.                        |
| `"^1.2.0"`, `"~1.2.0"`, `"1.2.x"`  | A version in the range.                                 | The newest version tag in the range.       |

Ranges are npm-style, also `>=1.2.3 <2.0.0`, `1.2.3 - 2.3.4` and `1.x \|\| >=2.5.0`.
An installed package matches when its `{author}/{name}` is `user/repo` (local packages), or it was downloaded from the repository, or its `repository` field names it.
A missing dependency is installed on the server and in the menu, see [Installing from GitHub](#installing-from-github).
The client never installs anything, it gets the dependencies from the server. A package fails to load if a dependency cannot be found.

#### `client_files`

Only the matching files are sent, so server-only code and data never leave the server. Without `client_files` the clients get only `package.json` and the client entrypoint, so a forgotten list never sends the whole project (e.g. a video next to the code); list everything else the client needs, like `lua/**` or `materials/**`.
The paths are relative to the package root (a leading `./` or `/` is ignored), the syntax is `std.path.wildcard`:

| Pattern          | Matches                                                                  |
| ---------------- | ------------------------------------------------------------------------ |
| `*`              | Any characters except `/`, e.g. `lua/*.lua`.                              |
| `**`             | Any characters, `**/` also matches no directory, e.g. `materials/**`.     |
| `?`              | One character except `/`.                                                 |
| `[abc]`, `[a-z]` | One character from the set, `[!a-z]` or `[^a-z]` negates it.              |
| `\x`             | The literal character, e.g. `\*`.                                         |

`package.json` and the client entrypoint (`main` or `main.client`) are always sent. `#include` is resolved on the server, so client files can include files that are not sent.

### Installing from GitHub

A package is imported by its repository [SERVER] [MENU]: `user/repo[@range]`. One repository is one package, with `package.json` at the repository root.

```lua
local my_lib = import( "user/my_lib" )          -- no range: the default branch
local old_lib = import( "user/my_lib@^1.0.0" )  -- a range: the newest version tag that matches it
local exact = import( "user/my_lib@1.2.0" )     -- the tag v1.2.0 or 1.2.0
```

1. **Installed first.** A package that is already installed and matches the range is used, nothing is downloaded: its `{author}/{name}` is `user/repo` (local packages), it was downloaded from the repository, or its `repository` field names it.
2. **The version.** Without a range the default branch is used. With a range the repository tags are fetched, the tags that are [SemVer](https://semver.org/) versions (`v1.2.0` or `1.2.0`, the `v` is dropped, other tags are ignored) are sorted, and the newest one that matches the range is picked. No matching tag is an error.
3. **`package.json` is checked before the download.** It is fetched from the repository root at that tag (or the default branch) and validated, its `version` must match the range.
4. **The download.** The archive is kept in `garrysmod/data/dreamwork/packages/{host}/{user}/{repo}/{tag}.dat` (`head.dat` for the default branch) and registered again on every start, so a tag is downloaded only once.

The client never downloads anything, it gets the packages from the server.

#### Repository URLs

| Spec                                        | Repository                           |
| ------------------------------------------- | ------------------------------------ |
| `user/repo`                                 | `https://github.com/user/repo`       |
| `github.com/user/repo`                      | `https://github.com/user/repo`       |
| `https://github.com/user/repo.git`          | `https://github.com/user/repo`       |

Without a scheme the scheme is `https`, without a host the host is `github.com`. The hosting service is chosen by the scheme and the host, only GitHub is supported for now. User and repository names are case-insensitive.

#### Publishing a package

1. Put `package.json` and the code at the root of a GitHub repository, e.g. `github.com/user/my_lib`.
2. Push it: the default branch is what `import( "user/my_lib" )` installs.
3. For versions, push tags with the version from `package.json`: `git tag v1.2.0 && git push --tags`. The `version` field must match the range, so keep the tag and the field the same.
4. Optional: set `"repository": "user/my_lib"` in `package.json` when its `{author}/{name}` is not `user/my_lib`, so installed copies (e.g. a Workshop export) are found by `import( "user/my_lib" )`.

#### Console and Lua

| Command (`dreamwork_sci` on the server, `dreamwork_cci` in the menu) | Lua                           | Description                                                                                                                   |
| --------------------------------------------- | ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| `package install <user/repo[@range]>`         | `loader.install( spec )`             | Finds or installs the package and loads it in this realm, returns the package and whether it is loaded.                       |
| `package upgrade [name[@range]]`              | `loader.upgrade( package )`          | A package from the default branch is downloaded again, a package from a tag gets the newest version tag (all packages from repositories without a name). The packages that depend on it are loaded again and pick the new version if their ranges allow it, then the old version is removed. |
| `package remove <name[@range]>`               | `loader.uninstall( package )`        | Unloads the package and the packages that depend on it, deletes its downloaded archive. The dependents are loaded again with another installed version that fits them, if there is one. Local packages (`addons/*/packages`) cannot be removed, delete their folders instead. |

A new commit on the default branch with the same `version` is the same package, bump `version` to make `package upgrade` replace it.

#### `loader.Repository`

The class behind all of it, for scripts that need more control:

```lua
local repository = dreamwork.loader.Repository( "user/my_lib" )

-- the SemVer tags, newest first: { { version = Version, tag = "v1.2.0" }, ... }
local releases, release_count = repository:getReleases()

-- the validated package.json of the tag (the default branch if `nil`), nothing is downloaded
local manifest = repository:fetchManifest( "v1.2.0" )

-- the `.zip` data of the tag (the default branch if `nil`) and the path it is kept at
local data, file_path = repository:download( "v1.2.0" )

-- installs the newest tag that matches the range (the default branch if `nil`) and registers it, without loading
local package = repository:install( "^1.0.0" )
```

`getReleases`, `fetchManifest`, `download` and `install` are async (they make GitHub requests) and raise errors on failure, call them from a coroutine and use `pcall` where a failure is expected.
GitHub limits unauthenticated API requests per IP, set a [personal access token](https://github.com/settings/tokens) in the `dreamwork_github_token` console variable to raise the limit.

### Exporting

`dreamwork_sci package export <name[@range]> [gma|zip]` [SERVER] [MENU] packs an installed package into `garrysmod/data/dreamwork/export/`:

- **`gma`** (default): `{name}-{version}.gma`, an addon ready for the Workshop with the archive at `data_static/packages/{name}-{version}.zip.dat`.
- **`zip`**: `{name}-{version}.zip.dat` (`data/` cannot hold `.zip`), rename it to `.zip` and drop it into `addons/*/packages/`.

Lua files are packed as they are, the clients still get them preprocessed. The same is available from Lua as `loader.pack( package )` and `loader.export( package, format )`.

## File Transport

`dreamwork.transport` [SHARED] delivers files from the server to the clients. The package manager sends client packages with it.

- The list of files (names, SHA-256 hashes and sizes) always goes over `std.Network`.
- A client asks only for the files it has no cached copy of. The server joins them into one **bundle**, compresses it and splits it into **segments**.
- Clients that miss the same files share one bundle, and the bundle of all files is made as soon as the files are ready.
- Clients cache files in `data/dreamwork/cache/transport` by hash, so only changed files are downloaded on the next connection.
  The cache is shared by every server. The local database keeps the CRC-32 of each cached file, checked on every use (CRC-32 is ~9x faster than SHA-256, about 1.3 GiB/s): a damaged file is downloaded again.
  Files not used for `dreamwork_transport_cache_lifetime` days, and the least recently used ones over `dreamwork_transport_cache_size`, are deleted after each update, the files used in the current session never are.
- Package files of 64 KiB or more (other than Lua) are sent as their own transport files, so a change of the package code does not download its videos, sounds or other large files again.
- With `http` and `static`, any segment that fails to download falls back to `network`, so a broken web server slows the download but never breaks it.

### Transports

Pick one with `dreamwork_transport` (or `dreamwork_sci transport config type <name>`). The change applies when the transport starts again (map change).

| Transport | Server needs                        | How segments travel                                                                                                                         |
| --------- | ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `network` | nothing                             | `std.Network` over the game connection. Works everywhere, but is the slowest and shares bandwidth with the game.                             |
| `http`    | HolyLib                             | `http.Server` inside srcds on `dreamwork_transport_http_port`. Segments are base64 (HolyLib cuts bodies at `\0`), so transfers are ~33% larger. |
| `static`  | a web server (Caddy, nginx, …)      | Raw segment files written to `data/dreamwork/transport/<bundle>-<index>.dat`, served by your web server. No HolyLib, no base64, not kept in RAM. |

### Performance

Measured on 2026-11-13: a fresh client download of a 16 MiB incompressible bundle (6 files, 8 segments of 2 MiB, 4 connections), client → Cloudflare → Caddy → srcds on one machine.

| Transport | Time         | Speed        | Notes                                                                                     |
| --------- | ------------ | ------------ | ----------------------------------------------------------------------------------------- |
| `network` | 32.8 s       | ~0.5 MiB/s   | Limited by the game's net channel, regardless of the connection speed.                     |
| `http`    | 3.1 s        | ~5.2 MiB/s   | 2.6 s on a repeat run, with the segments cached by Cloudflare. One of three runs stalled for ~60 s on a slow request. |
| `static`  | 2.32–2.36 s  | ~6.8 MiB/s   | Steady across runs, not cached by Cloudflare (`.dat` is not cached by default).             |

- Every HTTP request through a CDN costs about 0.5 s of round trip whatever its size, so the number of request rounds dominates. By default (`dreamwork_transport_segment_size 0`) a bundle is split into two segments per connection, 256 KiB to 4 MiB each.
- `dreamwork_transport_compression auto` compresses a sample with lzma and deflate and keeps the bundle uncompressed if neither saves 3%. Without HolyLib, lzma blocks the main thread, so bundles over 4 MiB use deflate.
- Bundles are kept in memory (`http`, `network`) or on disk (`static`) up to 256 MiB, and the least recently used ones are dropped first.

### Which one to use

- **`network`**: small packages, LAN servers (the game client refuses HTTP to private addresses), or hosts where you cannot run anything else.
- **`http`**: HolyLib is installed and you cannot run a web server. Put a reverse proxy or CDN in front and set `dreamwork_transport_http_url` and `dreamwork_transport_http_whitelist 0`, because the whitelist checks player IPs and sees only the proxy. `GET /dreamwork/health` reports whether the files are ready.
- **`static`**: you control the machine and already run a web server. It is the fastest and steadiest, and moves the transfer work out of srcds. It has no health route.

### Setting up `static`

1. Make the web server serve `garrysmod/data/dreamwork/transport` and set `dreamwork_transport_http_url` to its public URL. Without the URL the transport falls back to `network`.
2. The web server must be able to read the folder. srcds creates it as `drwxr--r--`, so run the web server as the same user, bind-mount the folder into its container, or fix the permissions.
3. Do not enable directory listing. Nothing checks who downloads, and the bundle names (random, known only to connected players) are the only protection.
4. Bundle names are never reused, so the segments can be cached forever. Missing segments should not be cached.
5. Cloudflare does not cache `.dat` by default. Add a Cache Rule for the path if you want the CDN to cache the segments.

Caddy:

```caddyfile
example.com {
	@dreamwork_segment {
		path /dreamwork/transport/*.dat
		file {
			root /path/to/garrysmod/data
		}
	}
	handle @dreamwork_segment {
		root * /path/to/garrysmod/data
		header Cache-Control "public, max-age=31536000, immutable"
		file_server
	}

	@dreamwork_missing path /dreamwork/transport/*.dat
	handle @dreamwork_missing {
		header Cache-Control "no-store"
		respond 404
	}
}
```

nginx:

```nginx
location ~ ^/dreamwork/transport/[0-9a-f]+-[0-9]+\.dat$ {
    root /path/to/garrysmod/data;
    add_header Cache-Control "public, max-age=31536000, immutable";
    try_files $uri =404;
}
```

```
dreamwork_transport static
dreamwork_transport_http_url https://example.com/dreamwork/transport/
```

### Console variables

| Variable                               | Default   | Description                                                                                          |
| -------------------------------------- | --------- | ---------------------------------------------------------------------------------------------------- |
| `dreamwork_transport`                  | `network` | `network`, `http` or `static`.                                                                       |
| `dreamwork_transport_http_connections` | `8`       | Segments a client downloads at once with `http` and `static` (1–16).                                 |
| `dreamwork_transport_http_url`         | empty     | The public URL of the segments. Optional for `http` (defaults to the server address and port), required for `static`. |
| `dreamwork_transport_http_port`        | `27080`   | The port of the `http` server.                                                                       |
| `dreamwork_transport_http_whitelist`   | `1`       | `http` only: serve only the IP addresses of connected players.                                       |
| `dreamwork_transport_compression`      | `auto`    | `auto`, `lzma`, `deflate`, `gzip` or `none`.                                                         |
| `dreamwork_transport_segment_size`     | `0`       | Segment size in bytes, `0` picks it from the bundle size and the connection count.                   |
| `dreamwork_transport_cache_lifetime`   | `30`      | Client: days a cached file is kept for since its last use, `0` keeps it forever.                     |
| `dreamwork_transport_cache_size`       | `2048`    | Client: size of the cache in MiB, the least recently used files go first, `0` is unlimited.          |

## Developer Tools

- **CLI**: `dreamwork_sci` (server) and `dreamwork_cci` (client and menu) console interfaces. They provide grouped commands with `help`, autocompletion and colored output:
  - `package`: install, upgrade, remove and export packages (see [Packages](#packages));
  - `vfs`: browse and manage the virtual file system;
  - `http` / `http github`: HTTP tools and the GitHub token and rate limit;
  - `transport`: shows and changes the [file transport](#file-transport) settings;
  - `mcp`: MCP bridge controls.
- **MCP bridge** (`modules/mcp.lua`): AI tooling through [gm_mcp](https://github.com/unknown-gd/gm_mcp). It can execute Lua on the server or clients, list entities and players, take screenshots and report collected errors.

## Optional Native Integrations

DreamWork works without any of these, but picks them up when they are installed:

| Module | Used for |
| ------ | -------- |
| [HolyLib](https://holylib.raphaelit7.com/) | FFI (`std.ffi`), `debug.getregistry`, threaded LZMA, `http.Server` / transport `http`, `os.getenv`, and fixed `newproxy`/`__gc` behaviour. |
| [`gm_getregistry`](https://github.com/wrefgtzweve/gm_getregistry) | `debug.getregistry` when HolyLib is not present. |
| [`reqwest`](https://github.com/WilliamVenner/gmsv_reqwest) / [`chttp`](https://github.com/timschumi/gmod-chttp) | Preferred HTTP clients (then the built-in `HTTP`). |
| [`gwsockets`](https://github.com/FredyH/GWSockets) / [`gm_tungstenite`](https://github.com/shockpast/gm_tungstenite) | Native WebSocket backends (then a `WebClient` / browser fallback on client and menu). |
| [`gm_asyncio`](https://github.com/Pika-Software/gm_asyncio) / [`gm_async_write`](https://github.com/WilliamVenner/gm_async_write) | Async file I/O for the VFS (`DATA` reads/writes). |
| [`gmsv_workshop`](https://github.com/WilliamVenner/gmsv_workshop) | Server-side Steam Workshop downloads (`steam.workshop`). |
| [`gmsv_serverstat`](https://github.com/WilliamVenner/gmsv_serverstat) | Server hardware / process stats (`std.server.hardware`). |
| [`gm_bytecode`](https://github.com/unknown-gd/gm_bytecode) | LuaJIT bytecode loading (`std.loadbytecode`). |
| [`gm_mcp`](https://github.com/unknown-gd/gm_mcp) | The MCP bridge. |

## Bugs and Suggestions

If you have an idea or find a bug, please open an issue.

## Documentation

All public APIs are annotated for [LuaLS](https://luals.github.io/). Type stubs for DreamWork,
Garry's Mod, HolyLib and LuaJIT are in [`meta/`](meta/).

## License

See [LICENSE](LICENSE).
