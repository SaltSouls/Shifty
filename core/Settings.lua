local Settings = {}

-----------------------------------
-- Variables
-----------------------------------
Settings.maxHue      = 360

-- Cached data
local cache = {
    fgColor   = app.fgColor,
    fgAlpha   = app.fgColor.alpha,
    bgColor   = app.bgColor,
    bgAlpha   = app.bgColor.alpha,
    lastColor = app.fgColor,
    selected  = "fg"
}

Settings.data = {
    -- Ordered list of defaultable setting ids
    defaultable = {
        "lowTemp",
        "highTemp",
        "intensity",
        "peak",
        "sway",
        "saturation",
        "lightness",
        "slots"
    },

    -- All settings and their defaults
    dropper    = { value = true, default = true },
    autoPick   = { value = true, default = true },
    autoTemp   = { value = true, default = true },
    lowTemp    = { value = 215,  default = 215 },
    highTemp   = { value = 50,   default = 50 },
    intensity  = { value = 25,   default = 25 },
    peak       = { value = 50,   default = 50 },
    sway       = { value = 65,   default = 65 },
    saturation = { value = 75,   default = 75 },
    lightness  = { value = 50,   default = 50 },
    slots      = { value = 7,    default = 7 }
}

-----------------------------------
-- Data Accessors
-----------------------------------
function Settings.getCache(id) return cache[id] end
function Settings.setCache(id, value) cache[id] = value end
function Settings.get(id) return Settings.data[id].value end
function Settings.set(id, value) Settings.data[id].value = value end
function Settings.getDefault(id) return Settings.data[id].default end

return Settings
