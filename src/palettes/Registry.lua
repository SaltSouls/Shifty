local ColorUtils = Import("src/gen/utils/ColorUtils.lua")

local createColor = ColorUtils.createColor

---@diagnostic disable: undefined-global

--------------------------------------------------------------------------------
-- Palettes Registry
--
-- Holds the current generated palettes, plus group ordering used by the UI.
--------------------------------------------------------------------------------

---@alias PaletteId
---| 'SHADE'
---| 'SATURATION'
---| 'LIGHTNESS'
---| 'HUE_SHIFT'
---| 'MIXED'
---| 'HUE_JUMP'
---| 'COMPLEMENTARY'
---| 'TRIADIC'
---| 'TETRADIC'

---@class Palettes
---@field REGISTRY table<PaletteId, Color[]>
---@field ORDER PaletteId[]
---@field BASE PaletteId[]
---@field EXTRA PaletteId[]
---@field newRegistry fun():table<PaletteId, Color[]>
---@field get fun(id:PaletteId):Color[]
---@field set fun(registry:table<PaletteId, Color[]>, id:PaletteId, index:integer, color:Color|table)
---@field replace fun(registry:table<PaletteId, Color[]>)
local Palettes = {}

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

Palettes.ORDER = {
    "SHADE",
    "LIGHTNESS",
    "SATURATION",
    "HUE_SHIFT",
    "MIXED",
    "HUE_JUMP",
    "COMPLEMENTARY",
    "TRIADIC",
    "TETRADIC"
}

Palettes.BASE = { "SHADE", "LIGHTNESS", "SATURATION", "HUE_SHIFT", "MIXED" }
Palettes.EXTRA = { "HUE_JUMP", "COMPLEMENTARY", "TRIADIC", "TETRADIC" }

function Palettes.newRegistry() return defaultRegistry() end
function Palettes.get(id) return Palettes.REGISTRY[id] end
function Palettes.set(registry, id, index, color) registry[id][index] = createColor(color) end
function Palettes.replace(registry) Palettes.REGISTRY = registry end

return Palettes
