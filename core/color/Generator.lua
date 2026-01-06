-----------------------------------
-- Imports
-----------------------------------
local Settings   = Import("core/Settings.lua")
local Palettes   = Import("core/color/Palettes.lua")
local ColorUtils = Import("core/color/utils/ColorUtils.lua")
local Calculator = Import("core/color/Calculator.lua")

-- Static imports
local maxHue       = Settings.maxHue
local getAsPercent = ColorUtils.getAsPercent

local Generator = {}

-----------------------------------
-- Generator Functions
-----------------------------------
-- Calculates color palettes for all palette types
function Generator.palettes(baseColor)
    local hueShiftSpread = 0.75
    local hueJumpSpread  = 3.0
    local lowTemp        = Settings.get("lowTemp")
    local highTemp       = Settings.get("highTemp")
    local sway           = getAsPercent("sway")
    local saturation     = getAsPercent("saturation")
    local light          = getAsPercent("lightness")
    local slots          = Settings.get("slots")

    Palettes.clear()

    local slotsMult = slots + 1

    for i = 1, slots do
        local targetHue = lowTemp
        local factor    = ((slots - 1) / 2 - i + 1) / ((slots - 1) / 2)
        local direction = -1

        -- Invert direction after reaching the middle
        if i >= slots / 2 then
            targetHue = highTemp
            factor    = -factor
            direction = 1
        end

        local proportion      = sway * factor
        local shadeColor      = Calculator.shade(baseColor, factor, direction, targetHue, proportion)
        local saturationColor = Calculator.shiftSaturation(baseColor, saturation * factor * direction)
        local lightnessColor  = Calculator.shiftLightness(baseColor, light * factor * direction)
        local hueShiftColor   = Calculator.shiftHue(baseColor, (((-(slotsMult / 2 - i) * hueShiftSpread) / slotsMult) * 2) / slotsMult)
        local hueJumpColor    = Calculator.shiftHue(baseColor, (((-(slotsMult / 2 - i) * hueJumpSpread)  / slotsMult) * 2) / slotsMult)
        local mixedColor      = Calculator.mix(Settings.getCache("fgColor"), Settings.getCache("bgColor"), (i - 1) / (slots - 1))

        Palettes.set("SHADE",      i, shadeColor)
        Palettes.set("SATURATION", i, saturationColor)
        Palettes.set("LIGHTNESS",  i, lightnessColor)
        Palettes.set("HUE_SHIFT",  i, hueShiftColor)
        Palettes.set("MIXED",      i, mixedColor)
        Palettes.set("HUE_JUMP",   i, hueJumpColor)

        if i == 1 then
            Palettes.set("MIXED", i, Settings.getCache("fgColor"))
        elseif i == math.floor(slotsMult / 2) then
            Palettes.set("SHADE",      i, baseColor)
            Palettes.set("SATURATION", i, baseColor)
            Palettes.set("LIGHTNESS",  i, baseColor)
            Palettes.set("HUE_SHIFT",  i, baseColor)
        elseif i == slots then
            Palettes.set("MIXED", i, Settings.getCache("bgColor"))
        end
    end

    Palettes.set("COMPLEMENTARY", 1, baseColor)
    Palettes.set("COMPLEMENTARY", 2, Calculator.shiftHue(baseColor, 0.5))

    Palettes.set("TRIADIC", 1, baseColor)
    Palettes.set("TRIADIC", 2, Calculator.shiftHue(baseColor, 120 / maxHue))
    Palettes.set("TRIADIC", 3, Calculator.shiftHue(baseColor, 240 / maxHue))

    Palettes.set("TETRADIC", 1, baseColor)
    Palettes.set("TETRADIC", 2, Calculator.shiftHue(baseColor,  90 / maxHue))
    Palettes.set("TETRADIC", 3, Calculator.shiftHue(baseColor, 180 / maxHue))
    Palettes.set("TETRADIC", 4, Calculator.shiftHue(baseColor, 270 / maxHue))
end

return Generator
