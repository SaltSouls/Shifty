local Cache = {}

---@diagnostic disable: undefined-global

--------------------------------------------------------------------------------
-- Cache
--
-- Runtime-only state that mirrors Aseprite app state (FG/BG colors, alpha, etc.).
-- This is intentionally separate from `Settings` so we can safely persist user
-- options while still tracking transient session data.
--------------------------------------------------------------------------------

---@class ShiftyCache
---@field fgColor Color
---@field fgAlpha integer
---@field bgColor Color
---@field bgAlpha integer
---@field lastColor Color
---@field selected 'fg'|'bg'

---@type ShiftyCache
local cache

cache = {
    fgColor   = app.fgColor,
    fgAlpha   = app.fgColor.alpha,
    bgColor   = app.bgColor,
    bgAlpha   = app.bgColor.alpha,
    lastColor = app.fgColor,
    selected  = "fg"
}

---Gets a cached value.
---@param id keyof ShiftyCache
---@return any
function Cache.get(id) return cache[id] end

---Sets a cached value.
---@param id keyof ShiftyCache
---@param value any
function Cache.set(id, value) cache[id] = value end

return Cache
