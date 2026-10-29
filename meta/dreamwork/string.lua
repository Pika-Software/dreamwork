---@meta dreamwork.std.string

---@class dreamwork.std.string.ByteMapRange
---@field leading_byte string The start byte of the range.
---@field trailing_byte string The end byte of the range.
---@field step_size integer? The step size for the range.

---@alias dreamwork.std.string.DifferenceType
---| 0 # String equal target one
---| 1 # String inserted in target
---| 2 # String removed from target

--- [SHARED AND MENU]
---
--- A single edit operation produced by `string.diff`, describing one contiguous run of
--- either unchanged, inserted, or removed characters.
---
---@class dreamwork.std.string.Difference
---@field type dreamwork.std.string.DifferenceType The kind of operation this run represents.
---@field start_position integer The 1-based start index of the run within `source`, inclusive.
---@field end_position integer The 1-based end index of the run within `source`, inclusive.
---@field source string The string the run's characters should be read from — either the original `source` (for `0` equal or `2` removed runs) or the `target` (for `1` inserted runs).
