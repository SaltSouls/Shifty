-----------------------------------
-- Imports
-----------------------------------
local Settings   = Import("src/state/Settings.lua")
local ColorUtils = Import("src/gen/utils/ColorUtils.lua")

-- Static imports
local maxHue       = Settings.maxHue
local clamp        = ColorUtils.clamp
local lerp         = ColorUtils.lerp
local getDistance  = ColorUtils.getDistance

local Calculator = {}

-----------------------------------
-- Shifting Functions
-----------------------------------
function Calculator.shiftHue(color, amount)
    local newColor = Color(color)
    local shifted  = newColor.hue + amount * maxHue
    newColor.hue   = (shifted % maxHue + maxHue) % maxHue
    return newColor
end

function Calculator.shiftSaturation(color, amount)
    local newColor   = Color(color)
    local saturation = newColor.saturation

    if amount > 0 then newColor.saturation = clamp(lerp(saturation, 1, amount), 0, 1)
    elseif amount < 0 then newColor.saturation = clamp(lerp(saturation, 0, -amount), 0, 1) end
    return newColor
end

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

-----------------------------------
-- Mixing Functions
-----------------------------------
function Calculator.mix(color1, color2, mixProportion)
    return Color {
        red   = clamp(lerp(color1.red, color2.red, mixProportion), 0, 255),
        green = clamp(lerp(color1.green, color2.green, mixProportion), 0, 255),
        blue  = clamp(lerp(color1.blue, color2.blue, mixProportion), 0, 255)
    }
end

-- Adjusts lightness value depending on color similarity and direction
local function adjustLight(color, shifted)
    local distance = getDistance(color, shifted)
    local lowShift  = 0.1
    local highShift = 0.5

    local normalized = clamp(distance / 100, 0, 1)
    local t = 1 - normalized
    t = t * t

    return lerp(lowShift, highShift, t)
end

-- NOTE: intensityPct and peakPct are optional overrides (0-1).
-- Passing these makes shading deterministic with respect to a Settings snapshot.
function Calculator.shade(baseColor, positionFactor, lightDirection, targetHue, mixProportion, intensityPct, peakPct)
    local shiftLightness = Calculator.shiftLightness
    local mixColors      = Calculator.mix
    local tempIntensity
    local tempPeak

    -- intensity is expected in the same scale as the old getAsPercent("intensity", 2)
    -- (i.e. 0..2).
    if intensityPct ~= nil then
        tempIntensity = clamp(tonumber(intensityPct) or 0, 0, 2)
    else
        tempIntensity = (clamp(tonumber(Settings.get("intensity")) or Settings.getDefault("intensity"), 0, 100) * 2) / 100
    end

    if peakPct ~= nil then
        tempPeak = clamp(tonumber(peakPct) or 0, 0, 1)
    else
        tempPeak = clamp(tonumber(Settings.get("peak")) or Settings.getDefault("peak"), 0, 100) / 100
    end

    -- How strong the hue/sat shift should be
    local function computeIntensityScale(intensity)
        local eased = intensity * intensity
        return lerp(0.1, 1.5, eased)
    end

    local function computeSaturationBoost(color)
        local sat = clamp(color.saturation or 100, 0, 100) / 100
        return lerp(0.7, 1.3, sat)
    end

    local intensityScale   = computeIntensityScale(tempIntensity)
    local saturationBoost  = computeSaturationBoost(baseColor)
    local shadeIntensity   = intensityScale * saturationBoost * positionFactor
    local peakOffset       = (tempPeak * 2 - 1) * positionFactor * lightDirection

    -- Apply hue / saturation / lightness shift
    local shiftedColor = shiftHSL(baseColor, targetHue, shadeIntensity, peakOffset)
    shiftedColor.hue   = targetHue

    -- Adjust lightness to keep perceived steps consistent
    local lightAdjustment = adjustLight(baseColor, shiftedColor)

    -- Mix original with shifted color, then apply lightness correction
    local mixedColor = mixColors(baseColor, shiftedColor, mixProportion)
    return shiftLightness(mixedColor, lightAdjustment * positionFactor * lightDirection)
end

-----------------------------------
-- Temperature Functions
-----------------------------------
-- normalizes hue distance
local function normHue(hue)
    hue = hue % maxHue
    if hue < 0 then hue = hue + maxHue end
    return hue
end

-- returns delta in [-180, 180)
local function shortestHueDelta(a, b)
    a = normHue(a)
    b = normHue(b)
    return (b - a + 540) % maxHue - 180
end

local function stepTowardHue(fromHue, toHue, step)
    local d = shortestHueDelta(fromHue, toHue)
    if math.abs(d) <= step then return normHue(toHue) end
    return normHue(fromHue + (d > 0 and step or -step))
end

function Calculator.temp(hue, anchorHue, band, step)
    hue = normHue(hue)
    anchorHue = normHue(anchorHue)
    band = clamp(band, 0, 180)
    step = clamp(step, 0, 180)

    local distance = shortestHueDelta(hue, anchorHue)
    local absDistance = math.abs(distance)

    if absDistance > band then
        local edgeHue = normHue(anchorHue - (distance > 0 and band or -band))
        return stepTowardHue(hue, edgeHue, step)
    end

    return stepTowardHue(hue, anchorHue, math.min(step, 3))
end

return Calculator
