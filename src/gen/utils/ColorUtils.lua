---@class ColorUtils
local ColorUtils = {}

---@diagnostic disable: undefined-global

--------------------------------------------------------------------------------
-- ColorUtils
--
-- Small math/helpers used across palette generation.
--------------------------------------------------------------------------------

---Linear interpolation.
---@param first number
---@param second number
---@param by number 0..1
---@return number
function ColorUtils.lerp(first, second, by) return first * (1 - by) + second * by end

---Clamps a value to a range.
---@param value number
---@param min number
---@param max number
---@return number
function ColorUtils.clamp(value, min, max) return math.min(math.max(value, min), max) end

---Absolute distance between two numbers.
---@param a number
---@param b number
---@return number
function ColorUtils.getAbsDistance(a, b) return math.abs(a - b) end

function ColorUtils.getAsPercent(setting, mult)
    local clamp   = ColorUtils.clamp
    setting = tonumber(setting)
    mult    = tonumber(mult)

    setting = clamp(setting, 0, 100)
    return (setting * mult) / 100
end

---Creates a new Color instance based on `baseColor` with an optional alpha override.
---@param baseColor Color|table
---@param alphaOverride? integer
---@return Color
function ColorUtils.createColor(baseColor, alphaOverride)
    local newColor = Color(baseColor)
    newColor.alpha = alphaOverride or 255
    return newColor
end

---Compares HSL components (not RGB) for equality.
---@param color1 Color
---@param color2 Color
---@return boolean
function ColorUtils.isSameColor(color1, color2)
    return color1.hue == color2.hue and
           color1.saturation == color2.saturation and
           color1.lightness == color2.lightness
end

---Simple "distance" across hue/sat/light components.
---Used as a heuristic for lightness adjustment.
---@param color1 Color
---@param color2 Color
---@return number
function ColorUtils.getDistance(color1, color2)
    local hue   = ColorUtils.getAbsDistance(color1.hue, color2.hue)
    local sat   = ColorUtils.getAbsDistance(color1.saturation, color2.saturation)
    local light = ColorUtils.getAbsDistance(color1.lightness, color2.lightness)
    return (hue + sat + light)
end

---Returns a vivid swatch color for a given hue.
---@param hue number
---@return Color
function ColorUtils.getTemp(hue) return ColorUtils.createColor({ h = hue, s = 1, l = 0.5 }) end

return ColorUtils
