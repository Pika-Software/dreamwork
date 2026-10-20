---@meta garrysmod.file

---@class garrysmod.File

---@alias garrysmod.file.AsyncStatus
---| -8 # file name is not part of the file system; please try another one
---| -7 # please retry later (network problems, etc)
---| -6 # hard subsystem failure
---| -5 # read parameters are invalid for unbuffered I/O
---| -4 # read error on file
---| -3 # write error on file
---| -2 # write parameters are invalid for unbuffered I/O
---| -1 # file could not be opened (bad path, not exist, etc)
---|  0 # successfully completed
---|  1 # has been properly queued and awaiting for service
---|  2 # is being accessed
---|  3 # has been interrupted by caller
---|  4 # has not yet been queued

---@alias garrysmod.file.AsyncReadCallback
---| fun( relative_path: string, mount: string, status: garrysmod.file.AsyncStatus, data: ( string | nil ) )

---@alias garrysmod.file.AccessType
---| "rb" # read-only, binary
---| "wb" # write-only, binary
---| "ab" # append-only, binary

---@alias garrysmod.file.SortingType
---| "nameasc"
---| "namedesc"
---| "dateasc"
---| "datedesc"

---@class garrysmod.file
---@field AsyncRead fun( relative_path: string, mount: string, callback: garrysmod.file.AsyncReadCallback, sync_read: boolean? ): garrysmod.file.AsyncStatus
---@field CreateDir fun( relative_path: string )
---@field Delete fun( relative_path: string, mount: string ): boolean
---@field Exists fun( relative_path: string, mount: string ): boolean
---@field Find fun( wildcard: string, mount: string, sorting_mode: garrysmod.file.SortingType ): ( string[] | nil ), ( string[] | nil )
---@field IsDir fun( relative_path: string, mount: string ): boolean
---@field Open fun( relative_path: string, mode: garrysmod.file.AccessType, mount: string ): garrysmod.File | nil
---@field Rename fun( relative_path: string, new_path: string ): boolean
---@field Size fun( relative_path: string, mount: string ): -1 | integer
---@field Time fun( relative_path: string, mount: string ): 0 | 1 | integer
file = {}
