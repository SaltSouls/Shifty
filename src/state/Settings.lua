-----------------------------------
-- Imports
-----------------------------------
local Cache = Import("src/state/Cache.lua")

local Settings = {}

-----------------------------------
-- Constants
-----------------------------------
Settings.maxHue = 360

-----------------------------------
-- Settings & Defaults
-----------------------------------
Settings.data = {
    -- Ordered list of setting ids that are intended to be resettable.
    defaultable = {
        "lowTemp",
        "highTemp",
        "intensity",
        "peak",
        "sway",
        "saturation",
        "lightness",
        "slots",
        "updateDelay"
    },

    -- All settings and their defaults.
    dropper      = { value = true, default = true },
    autoPick     = { value = true, default = true },
    autoTemp     = { value = true, default = true },
    autoHighTemp = { value = 50,   default = 50 },
    lowTemp      = { value = 215,  default = 215 },
    autoLowTemp  = { value = 215,  default = 215 },
    highTemp     = { value = 50,   default = 50 },
    tempBand     = { value = 40,   default = 40 },
    tempPull     = { value = 20,   default = 20 },
    intensity    = { value = 25,   default = 25 },
    peak         = { value = 50,   default = 50 },
    sway         = { value = 65,   default = 65 },
    saturation   = { value = 75,   default = 75 },
    lightness    = { value = 50,   default = 50 },
    slots        = { value = 7,    default = 7 },
    updateDelay  = { value = 75,   default = 75 }
}

-----------------------------------
-- Data Accessors
-----------------------------------
function Settings.getCache(id) return Cache.get(id) end
function Settings.setCache(id, value) Cache.set(id, value) end

function Settings.get(id) return Settings.data[id].value end
function Settings.set(id, value) Settings.data[id].value = value end

function Settings.getDefault(id) return Settings.data[id].default end

function Settings.getBaseColor()
    return Settings.getCache(Settings.getCache("selected") == "bg" and "bgColor" or "fgColor")
end

-- Gets proper temp color based on autoTemp setting
function Settings.getEffectiveTemp(id)
    if not Settings.get("autoTemp") then return Settings.get(id) end
    if id == "lowTemp" then return Settings.get("autoLowTemp") end
    if id == "highTemp" then return Settings.get("autoHighTemp") end
end

-- Grabs a snapshot of the current settings in order keep things deterministic,
-- and prevent weird behavior from occurring during palette generation.
function Settings.snapshot()
    local selected = Settings.getCache("selected")
    local fgColor  = Settings.getCache("fgColor")
    local bgColor  = Settings.getCache("bgColor")
    local base     = Settings.getCache(selected == "bg" and "bgColor" or "fgColor")

    return {
        -- cached colors
        fgColor   = fgColor,
        bgColor   = bgColor,
        fgAlpha   = Settings.getCache("fgAlpha"),
        bgAlpha   = Settings.getCache("bgAlpha"),
        selected  = selected,
        baseColor = base,

        -- settings
        slots        = Settings.get("slots"),
        autoTemp     = Settings.get("autoTemp"),
        lowTemp      = Settings.get("lowTemp"),
        highTemp     = Settings.get("highTemp"),
        autoLowTemp  = Settings.get("autoLowTemp"),
        autoHighTemp = Settings.get("autoHighTemp"),
        tempBand     = Settings.get("tempBand"),
        tempPull     = Settings.get("tempPull"),
        intensity    = Settings.get("intensity"),
        peak         = Settings.get("peak"),
        sway         = Settings.get("sway"),
        saturation   = Settings.get("saturation"),
        lightness    = Settings.get("lightness")
    }
end

return Settings
