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

-- Perceptual-ish distance using linear RGB + luminance.
-- Returns ~0..2ish range (depends on colors).
function ColorUtils.toLinear(c8)
    local c = (c8 or 0) / 255
    if c <= 0.04045 then return c / 12.92 end
    return ((c + 0.055) / 1.055) ^ 2.4
end

function ColorUtils.luminance(color)
    local r = ColorUtils.toLinear(color.red)
    local g = ColorUtils.toLinear(color.green)
    local b = ColorUtils.toLinear(color.blue)
    -- Rec.709 / sRGB luminance
    return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

function ColorUtils.linearRgbDistance(a, b)
    local ar = ColorUtils.toLinear(a.red)
    local ag = ColorUtils.toLinear(a.green)
    local ab = ColorUtils.toLinear(a.blue)
    local br = ColorUtils.toLinear(b.red)
    local bg = ColorUtils.toLinear(b.green)
    local bb = ColorUtils.toLinear(b.blue)
    local dr = ar - br
    local dg = ag - bg
    local db = ab - bb
    return math.sqrt(dr*dr + dg*dg + db*db)
end

function ColorUtils.visualDistance(a, b)
    local lum = math.abs(ColorUtils.luminance(a) - ColorUtils.luminance(b))
    local rgb = ColorUtils.linearRgbDistance(a, b)
    -- Weighted so brightness separation matters more for ramps
    return (lum * 1.6) + rgb
end

---Returns a vivid swatch color for a given hue.
---@param hue number
---@return Color
function ColorUtils.getTemp(hue) return ColorUtils.createColor({ h = hue, s = 1, l = 0.5 }) end

return ColorUtils
