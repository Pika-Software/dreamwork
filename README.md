# dreamwork meta

Generated [LuaLS](https://luals.github.io) definitions for the dreamwork `std` environment,
do not edit this branch by hand, it is rebuilt from `main` by `.github/workflows/meta.yml`.

Packages run inside `dreamwork.std`, so everything is declared as a global here:
`std.print` is `print`, `dreamwork.std.Queue` is `Queue`, and so on.

## Usage

Add the `library` folder of this branch to your workspace libraries, e.g. in `.luarc.json`:

```json
{
    "runtime.version": "LuaJIT",
    "workspace.library": [ "path/to/dreamwork-meta/library" ]
}
```

or clone the branch into a LuaLS addons folder, it is a valid addon (`config.json` + `library`).

Source commit: `3c9f974261613c0b1803526d41ec9af2412ae601`
