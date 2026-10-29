---@meta _

---@class i18n
i18n = {}

---@param key string
---@param arguments string[] | table<string, string>
---@return string
---@nodiscard
function i18n.get(key, arguments) end

---@param key string
---@param value string
function i18n.set(key, value) end

---@param language_code string
function i18n.load(language_code) end
