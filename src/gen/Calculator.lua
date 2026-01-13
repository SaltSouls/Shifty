local Settings   = Import("src/state/Settings.lua")
local ColorUtils = Import("src/gen/utils/ColorUtils.lua")

---@diagnostic disable: undefined-global

--------------------------------------------------------------------------------
-- Calculator
--
-- Color operations used by generators:
-- - HSL shifting (hue/saturation/lightness)
-- - RGB mixing
-- - Temperature shading helpers
--------------------------------------------------------------------------------

---@class Calculator
local Calculator     = {}

local maxHue         = Settings.maxHue
local clamp          = ColorUtils.clamp
local lerp           = ColorUtils.lerp
local getAbsDistance = ColorUtils.getAbsDistance
local getDistance    = ColorUtils.getDistance

--------------------------------------------------------------------------------
-- HSL Shifts
--------------------------------------------------------------------------------

---Shifts a color's hue by a normalized amount.
---@param color Color
---@param amount number Normalized hue shift (1.0 = 360°).
---@return Color
function Calculator.shiftHue(color, amount)
    local newColor = Color(color)
    local shifted  = newColor.hue + amount * maxHue
    newColor.hue   = (shifted % maxHue + maxHue) % maxHue
    return newColor
end

---Shifts a color's saturation towards 1 (positive) or 0 (negative).
---@param color Color
---@param amount number -1..1
---@return Color
function Calculator.shiftSaturation(color, amount)
    local newColor   = Color(color)
    local saturation = newColor.saturation

    if amount > 0 then newColor.saturation = clamp(lerp(saturation, 1, amount), 0, 1)
    elseif amount < 0 then newColor.saturation = clamp(lerp(saturation, 0, -amount), 0, 1) end
    return newColor
end

---Shifts a color's lightness towards 1 (positive) or 0 (negative).
---@param color Color
---@param amount number -1..1
---@return Color
function Calculator.shiftLightness(color, amount)
    local newColor  = Color(color)
    local lightness = newColor.lightness

    if amount > 0 then newColor.lightness = clamp(lerp(lightness, 1, amount), 0, 1)
    elseif amount < 0 then newColor.lightness = clamp(lerp(lightness, 0, -amount), 0, 1) end
    return newColor
end

local function shiftHSL(color, hue, saturation, lightness)
    local shiftHue        = Calculator.shiftHue
    local shiftSaturation = Calculator.shiftSaturation
    local shiftLightness  = Calculator.shiftLightness

    return shiftHue(shiftSaturation(shiftLightness(color, lightness), saturation), hue)
end

--------------------------------------------------------------------------------
-- Mixing
--------------------------------------------------------------------------------

---Linearly mixes two colors in RGB space.
---@param color1 Color
---@param color2 Color
---@param mixProportion number 0..1
---@return Color
function Calculator.mix(color1, color2, mixProportion)
    return Color {
        red = clamp(lerp(color1.red, color2.red, mixProportion), 0, 255),
        green = clamp(lerp(color1.green, color2.green, mixProportion), 0, 255),
        blue = clamp(lerp(color1.blue, color2.blue, mixProportion), 0, 255)
    }
end

--------------------------------------------------------------------------------
-- Shade Generation
--------------------------------------------------------------------------------

local function adjustLight(color, shifted)
    local lowShift   = 0.3
    local highShift  = 0.7
    local distance   = getDistance(color, shifted)
    local normalized = clamp(distance / 100, 0, 1)
    local t          = 1 - normalized
    t                = t * t

    return lerp(lowShift, highShift, t)
end

---Builds a shade swatch by shifting hue/temp, applying intensity/peak curves,
---then mixing with base to keep the ramp coherent.
---@param baseColor Color
---@param positionFactor number -1..1 (where in the ramp this swatch sits)
---@param lightDirection number -1 or 1
---@param targetHue number Target hue in degrees
---@param mixProportion number 0..1 mix weight between base and shifted
---@param intensityPct number 0..2 (already scaled)
---@param peakPct number 0..1 (already scaled)
---@return Color
function Calculator.shade(baseColor, positionFactor, lightDirection, targetHue, mixProportion, intensityPct, peakPct)
    local shiftLightness = Calculator.shiftLightness
    local mixColors      = Calculator.mix
    local tempIntensity  = clamp(tonumber(intensityPct), 0, 2)
    local tempPeak       = clamp(tonumber(peakPct), 0, 1)

    local function computeIntensityScale(intensity)
        local eased = intensity * intensity
        return lerp(0.1, 1.5, eased)
    end

    local function computeSaturationBoost(color)
        local sat = clamp(color.saturation or 1, 0, 1)
        return lerp(0.7, 1.3, sat)
    end

    local intensityScale  = computeIntensityScale(tempIntensity)
    local saturationBoost = computeSaturationBoost(baseColor)
    local shadeIntensity  = intensityScale * saturationBoost * positionFactor
    local peakOffset      = (tempPeak * 2 - 1) * positionFactor * lightDirection

    local shiftedColor    = shiftHSL(baseColor, targetHue, shadeIntensity, peakOffset)
    shiftedColor.hue      = targetHue

    local lightAdjustment = adjustLight(baseColor, shiftedColor)

    local mixedColor      = mixColors(baseColor, shiftedColor, mixProportion)
    return shiftLightness(mixedColor, lightAdjustment * positionFactor * lightDirection)
end

--------------------------------------------------------------------------------
-- Temperature Pull
--------------------------------------------------------------------------------

-- The "auto temp" feature gently moves the configured cool/warm anchors
-- toward the current base hue. This keeps shading consistent when the user
-- picks a new base color.

local function wrapHue(hue) return (hue % maxHue) end

local function getHueDistance(hue, target)
    hue        = wrapHue(hue)
    target     = wrapHue(target)
    local diff = getAbsDistance(target, hue)

    return math.min(diff, maxHue - diff)
end

local function getHueDirection(hue, target)
    hue    = wrapHue(hue)
    target = wrapHue(target)

    if hue == target then return 0 end
    local up = (target - hue) % maxHue
    return (up <= maxHue / 2) and 1 or -1
end

local function stepHue(hue, target, step, dir)
    hue            = wrapHue(hue)
    target         = wrapHue(target)
    if dir == 0 then dir = getHueDirection(hue, target) end
    local minStep  = step
    local distance = getHueDistance(hue, target)

    if distance == 0 then return hue end
    if distance <= minStep then return target end

    local maxStep   = step * 6
    local easeRange = step * 8
    local t         = math.min(distance / easeRange, 1)
    local eased     = t * t

    local move      = minStep + ((maxStep - minStep) * eased)
    move            = math.min(move, distance)
    return wrapHue(hue + (move * dir))
end

---Moves `hue` towards `anchor` by a variable step.
---@param hue number Current hue.
---@param anchor number Target/anchor hue.
---@param step number Base step size (higher = stronger pull).
---@return number newHue
function Calculator.temp(hue, anchor, step, dir)
    hue    = tonumber(hue) or 0
    anchor = tonumber(anchor) or 0
    step   = tonumber(step) or 0
    dir    = tonumber(dir) or 0

    return stepHue(hue, anchor, step, dir)
end

return Calculator
