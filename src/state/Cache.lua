-----------------------------------
-- Cache
-----------------------------------
-- Transient runtime state (not intended to be persisted).

local Cache = {}

-- Cached data
local cache = {
    fgColor   = app.fgColor,
    fgAlpha   = app.fgColor.alpha,
    bgColor   = app.bgColor,
    bgAlpha   = app.bgColor.alpha,
    lastColor = app.fgColor,
    selected  = "fg"
}

function Cache.get(id) return cache[id] end
function Cache.set(id, value) cache[id] = value end

return Cache
