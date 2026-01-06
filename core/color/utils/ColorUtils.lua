-----------------------------------
-- Imports
-----------------------------------
local Settings = Import("core/Settings.lua")

local ColorUtils = {}

-----------------------------------
-- Color Utilities
-----------------------------------
function ColorUtils.lerp(first, second, by) return first * (1 - by) + second * by end
function ColorUtils.clamp(value, min, max) return math.min(math.max(value, min), max) end

-- Ensure settings are percentage based
function ColorUtils.getAsPercent(id, mult)
    local setting = Settings.get(id)
    local clamp   = ColorUtils.clamp
    setting = tonumber(setting) or Settings.getDefault(id)
    mult    = tonumber(mult) or 1

    setting = clamp(setting, 0, 100)
    return (setting * mult) / 100
end

-- Create a color with optional alpha override
function ColorUtils.createColor(baseColor, alphaOverride)
    local newColor = Color(baseColor)
    newColor.alpha = alphaOverride or 255
    return newColor
end

function ColorUtils.isSameColor(color1, color2)
    return color1.hue == color2.hue and
           color1.saturation == color2.saturation and
           color1.lightness == color2.lightness
end

-- Gets the distance between two colors
function ColorUtils.getDistance(color1, color2)
    local hue = math.abs(color1.hue - color2.hue)
    local sat = math.abs(color1.saturation - color2.saturation)
    local light = math.abs(color1.lightness - color2.lightness)
    return (hue + sat + light)
end

-- Gets the temperature based on hue
function ColorUtils.getTemp(hue) return ColorUtils.createColor({ h = hue, s = 1, l = 0.5 }) end

return ColorUtils
