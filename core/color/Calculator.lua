-----------------------------------
-- Imports
-----------------------------------
local Settings   = Import("core/Settings.lua")
local ColorUtils = Import("core/color/utils/ColorUtils.lua")

-- Static imports
local maxHue       = Settings.maxHue
local clamp        = ColorUtils.clamp
local lerp         = ColorUtils.lerp
local getAsPercent = ColorUtils.getAsPercent
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

function Calculator.shade(baseColor, positionFactor, lightDirection, targetHue, mixProportion)
    local shiftLightness = Calculator.shiftLightness
    local mixColors      = Calculator.mix
    local tempIntensity  = getAsPercent("intensity", 2)
    local tempPeak       = getAsPercent("peak")

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
function Calculator.temp(hue, targetId)
    local newHue = hue
    local isWarm = targetId == "highTemp"
    local minHue = isWarm and 55 or 240
    local shift = isWarm and -100 or 100
    local rangeMin = 55
    local rangeMax = isWarm and 255 or 240

    -- Calculate hue values, dragging towards blue for cool and yellow for warm
    if hue >= rangeMin and hue <= rangeMax then
        newHue = isWarm and math.max(minHue, hue + shift) or math.min(minHue, hue + shift)
    else
        newHue = (hue - shift) % maxHue
        if isWarm and newHue > minHue and (hue < 55 or hue > 315) then newHue = minHue
        elseif not isWarm and newHue < minHue then newHue = minHue end
    end

    Settings.set(targetId, newHue)
end

return Calculator
