---@meta dreamwork.vfs


---@class dreamwork.vfs.MountInfo
---@field writable boolean If `true`, files and directories can be created and written.
---@field deletable boolean If `true`, files and directories can be deleted.
---@field extensions table<string, boolean> | nil The map of extensions allowed to write, `nil` allows any extension.

---@class dreamwork.vfs.Mount
---@field path string The absolute virtual path of the mount.
---@field search_path string The search path, e.g. `MOD`, `DATA` or `hl2`.
---@field search_directory string The directory inside of the search path, empty string for its root.
---@field writable boolean If `true`, files and directories can be created and written.
---@field deletable boolean If `true`, files and directories can be deleted.
---@field extensions table<string, boolean> | nil The map of extensions allowed to write, `nil` allows any extension.
---@field node dreamwork.vfs.Node The root directory of the mount.

---@class dreamwork.vfs.WatchContent
---@field count integer The number of files and directories.
---@field names string[] The names of files and directories.
---@field directories boolean[] `true` for directories, `false` for files.
---@field times integer[] The last modification times of files, `-1` if the file was not checked yet, `0` for directories.
---@field sizes integer[] The sizes of files in bytes, `-1` if the file was not checked yet, `0` for directories.
---@field indexes table<string, integer> The indexes of the names.
---@field overlay_count integer The number of mount roots, intermediate directories and memory files at the start, they shadow the search path and are not checked.
---@field search_path string | nil The search path of the directory, `nil` for intermediate directories.
---@field relative_path string The path of the directory inside of the search path.

---@class dreamwork.vfs.Watch
---@field count integer The number of `vfs.watch` calls without `vfs.unwatch`.
---@field exists boolean `true` if the path existed at the last check.
---@field is_directory boolean `true` if the path was a directory at the last check.
---@field time integer The last modification time of the file.
---@field size integer The size of the file in bytes.
---@field content dreamwork.vfs.WatchContent | nil The content of the directory, `nil` if the path is not a directory.
---@field checked number The uptime of the last check.

---@alias dreamwork.vfs.Storage
---| "mount" # Provided by the search path of a mount, the mount fields are set.
---| "memory" # A memory file or directory, the upper layer created where the search path is read-only or there is none.
---| "none" # An intermediate directory created on the way to mount points, it holds nothing by itself.

---@class dreamwork.vfs.Info
---@field mount_path string | nil The absolute virtual path of the mount, `nil` for intermediate directories.
---@field search_path string | nil The search path, e.g. `MOD`, `DATA` or `hl2`, `nil` for intermediate directories.
---@field search_directory string | nil The directory inside of the search path, empty string for its root, `nil` for intermediate directories.
---@field relative_path string | nil The path of the file or directory inside of the search path, `nil` for intermediate directories.
---@field storage dreamwork.vfs.Storage Where the file or directory is stored.
---@field is_mount_root boolean `true` if the path is the root directory of the mount.
---@field writable boolean If `true`, files and directories can be created, written and deleted.
---@field deletable boolean If `true`, files and directories can be deleted.
