---@meta holylib.filesystem


---@class holylib.filesystem
---@field AddSearchPath fun( system_path: string, mount: string, backwards: boolean? )
---@field AsyncRead fun( relative_path: string, mount: string, callback: garrysmod.file.AsyncReadCallback ): garrysmod.file.AsyncStatus
---@field CreateDir fun( relative_path: string, mount: string? )
---@field Delete fun( relative_path: string, mount: string? )
---@field Exists fun( relative_path: string, mount: string ): boolean
---@field Find fun( wildcard: string, mount: string, sorting_mode: garrysmod.file.SortingType ): ( string[] | nil ), ( string[] | nil )
---@field FullPathToRelativePath fun( system_path: string, mount: string? ): string | nil
---@field IsDir fun( relative_path: string, mount: string ): boolean
---@field Open fun( relative_path: string, mode: garrysmod.file.AccessType, mount: string ): dreamwork.GModFile | nil
---@field RelativePathToFullPath fun( relative_path: string, mount: string ): string | nil
---@field RemoveAllSearchPaths fun()
---@field RemoveSearchPath fun( system_path: string, mount: string )
---@field RemoveSearchPaths fun( mount: string )
---@field Rename fun( relative_path: string, new_path: string, mount: string? ): boolean
---@field Size fun( relative_path: string, mount: string ): -1 | integer
---@field Time fun( relative_path: string, mount: string ): 0 | 1 | integer
---@field TimeAccessed fun( relative_path: string, mount: string ): 0 | integer
---@field TimeCreated fun( relative_path: string, mount: string ): 0 | integer
filesystem = {}
