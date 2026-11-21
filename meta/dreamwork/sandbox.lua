---@meta dreamwork.sandbox


--- [SHARED AND MENU]
---
--- The owner of sandboxed code, a package, see `dreamwork.sandbox.bind`.
---
---@class dreamwork.sandbox.Owner
---@field id string The id of the owner, `{author}/{name}@{version}` for packages, named objects get the `{id}::` prefix.
---@field root string The absolute virtual path of the root directory with every file of the owner, relative `File` and `Directory` paths point into it.
---@field handlers table<function, dreamwork.sandbox.Attachment[]> The attached handlers, weak keys.
---@field objects table<any, fun( object: any )> The claimed objects and their release functions, weak keys.

--- [SHARED AND MENU]
---
--- A handler attached by an owner, detached when the owner is released.
---
---@class dreamwork.sandbox.Attachment
---@field [1] fun( target: any, a: any, b: any, c: any ) The detach function.
---@field [2] any The emitter, event or hook.
---@field [3] any
---@field [4] any
---@field [5] any
