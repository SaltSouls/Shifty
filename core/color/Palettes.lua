-----------------------------------
-- Imports
-----------------------------------
local ColorUtils = Import("core/color/utils/ColorUtils.lua")

-- Static imports
local createColor = ColorUtils.createColor

local Palettes = {}

-----------------------------------
-- Palette Variables
-----------------------------------
-- All palettes
Palettes.REGISTRY = {
    SHADE         = { },
    SATURATION    = { },
    LIGHTNESS     = { },
    HUE_SHIFT     = { },
    MIXED         = { },
    HUE_JUMP      = { },
    COMPLEMENTARY = { },
    TRIADIC       = { },
    TETRADIC      = { }
}

-- An ordered list of all palettes
Palettes.ORDER = {
    "SHADE",
    "SATURATION",
    "LIGHTNESS",
    "HUE_SHIFT",
    "MIXED",
    "HUE_JUMP",
    "COMPLEMENTARY",
    "TRIADIC",
    "TETRADIC"
}

-- Ordered list by palette category
Palettes.BASE = { "SHADE", "SATURATION", "LIGHTNESS", "HUE_SHIFT", "MIXED" }
Palettes.EXTRA = { "HUE_JUMP", "COMPLEMENTARY", "TRIADIC", "TETRADIC" }

-----------------------------------
-- Data Accessors
-----------------------------------
function Palettes.get(id) return Palettes.REGISTRY[id] end
function Palettes.set(id, index, color) Palettes.REGISTRY[id][index] = createColor(color) end
function Palettes.clear() for _, id in ipairs(Palettes.ORDER) do Palettes.REGISTRY[id] = {} end end

return Palettes
