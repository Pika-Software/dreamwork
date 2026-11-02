---@meta dreamwork.std.url


--- [SHARED AND MENU]
---
--- The parsed parts of a URL, as returned by `URL.parse` and kept in `url.state`.
---
--- Unlike the `URL` fields, the values are not serialized: the host can be an
--- IPv4 integer or an `IPv6` object and the path is a list of segments.
---
---@class dreamwork.std.URL.State
---@field scheme string? The lowercase scheme without the `":"`, e.g. `"https"`.
---@field username string? The percent-encoded username.
---@field password string? The percent-encoded password.
---@field hostname string | dreamwork.std.IPv4 | dreamwork.std.IPv6 | nil The host: an ASCII domain or opaque host string, an IPv4 address, an IPv6 address or `nil` if the URL has no host.
---@field port integer? The port, `nil` when it is not given or is the default port of the scheme.
---@field path string | string[] | nil The percent-encoded path segments, or a string for opaque paths (`mailto:`, `data:`).
---@field fragment string? The percent-encoded fragment without the `"#"`.
---@field query string? The percent-encoded query without the `"?"`.
local URLState = {}
