-----------------------------------
-- Imports
-----------------------------------
local ColorUtils = Import("src/gen/utils/ColorUtils.lua")

-- Static imports
local createColor = ColorUtils.createColor

local Palettes = {}

-----------------------------------
-- Palette Variables
-----------------------------------
-- All palettes
local function defaultRegistry()
    return {
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
end

Palettes.REGISTRY = defaultRegistry()

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
function Palettes.newRegistry() return defaultRegistry() end
function Palettes.get(id) return Palettes.REGISTRY[id] end
function Palettes.set(registry, id, index, color) registry[id][index] = createColor(color) end
function Palettes.replace(registry) Palettes.REGISTRY = registry end

return Palettes
