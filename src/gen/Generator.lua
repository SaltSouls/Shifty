-----------------------------------
-- Imports
-----------------------------------
local Settings   = Import("src/state/Settings.lua")
local Palettes   = Import("src/palettes/Registry.lua")
local ColorUtils = Import("src/gen/utils/ColorUtils.lua")
local Calculator = Import("src/gen/Calculator.lua")

-- Static imports
local maxHue = Settings.maxHue
local clamp  = ColorUtils.clamp

local Generator = {}

local constraints = {
    hueShiftSpread = 0.75,
    hueJumpSpread  = 3.0
}

-----------------------------------
-- Generator Functions
-----------------------------------
-- Pure generation step.
-- Takes a Settings.snapshot() table and returns a full palette registry.
function Generator.generate(state)
    local lowTemp    = state.autoTemp and state.autoLowTemp or state.lowTemp
    local highTemp   = state.autoTemp and state.autoHighTemp or state.highTemp

    -- Percent-based settings are stored 0-100 in Settings.
    -- Converting them here keeps generation fully determined by the snapshot.
    local sway       = clamp(tonumber(state.sway) or 0, 0, 100) / 100
    local saturation = clamp(tonumber(state.saturation) or 0, 0, 100) / 100
    local light      = clamp(tonumber(state.lightness) or 0, 0, 100) / 100
    local intensity  = (clamp(tonumber(state.intensity) or 0, 0, 100) * 2) / 100
    local peak       = clamp(tonumber(state.peak) or 0, 0, 100) / 100
    local slots      = state.slots

    local baseColor  = state.baseColor
    local fgColor    = state.fgColor
    local bgColor    = state.bgColor

    local registry = Palettes.newRegistry()

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
        local shadeColor      = Calculator.shade(baseColor, factor, direction, targetHue, proportion, intensity, peak)
        local saturationColor = Calculator.shiftSaturation(baseColor, saturation * factor * direction)
        local lightnessColor  = Calculator.shiftLightness(baseColor, light * factor * direction)
        local hueShiftColor   = Calculator.shiftHue(baseColor, (((-(slotsMult / 2 - i) * constraints.hueShiftSpread) / slotsMult) * 2) / slotsMult)
        local hueJumpColor    = Calculator.shiftHue(baseColor, (((-(slotsMult / 2 - i) * constraints.hueJumpSpread)  / slotsMult) * 2) / slotsMult)
        local mixedColor      = Calculator.mix(fgColor, bgColor, (i - 1) / (slots - 1))

        Palettes.set(registry, "SHADE",      i, shadeColor)
        Palettes.set(registry, "SATURATION", i, saturationColor)
        Palettes.set(registry, "LIGHTNESS",  i, lightnessColor)
        Palettes.set(registry, "HUE_SHIFT",  i, hueShiftColor)
        Palettes.set(registry, "MIXED",      i, mixedColor)
        Palettes.set(registry, "HUE_JUMP",   i, hueJumpColor)

        if i == 1 then
            Palettes.set(registry, "MIXED", i, fgColor)
        elseif i == math.floor(slotsMult / 2) then
            Palettes.set(registry, "SHADE",      i, baseColor)
            Palettes.set(registry, "SATURATION", i, baseColor)
            Palettes.set(registry, "LIGHTNESS",  i, baseColor)
            Palettes.set(registry, "HUE_SHIFT",  i, baseColor)
        elseif i == slots then
            Palettes.set(registry, "MIXED", i, bgColor)
        end
    end

    Palettes.set(registry, "COMPLEMENTARY", 1, baseColor)
    Palettes.set(registry, "COMPLEMENTARY", 2, Calculator.shiftHue(baseColor, 0.5))

    Palettes.set(registry, "TRIADIC", 1, baseColor)
    Palettes.set(registry, "TRIADIC", 2, Calculator.shiftHue(baseColor, 120 / maxHue))
    Palettes.set(registry, "TRIADIC", 3, Calculator.shiftHue(baseColor, 240 / maxHue))

    Palettes.set(registry, "TETRADIC", 1, baseColor)
    Palettes.set(registry, "TETRADIC", 2, Calculator.shiftHue(baseColor,  90 / maxHue))
    Palettes.set(registry, "TETRADIC", 3, Calculator.shiftHue(baseColor, 180 / maxHue))
    Palettes.set(registry, "TETRADIC", 4, Calculator.shiftHue(baseColor, 270 / maxHue))

    return registry
end

return Generator
