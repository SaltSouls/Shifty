local Temperature = {}

-----------------------------------
-- Temperature Derivation
-----------------------------------
-- Computes auto-derived low/high temperature hues based on a base hue.
--
-- Params:
--  state: Settings.snapshot() table
--  hue:   baseColor.hue
--  Calculator: Calculator module (passed in to avoid import cycles)
--
-- Returns:
--  autoLowHue, autoHighHue (numbers) or nil, nil if autoTemp disabled.
function Temperature.compute(state, hue, Calculator)
    if not state or not state.autoTemp then return nil, nil end
    if not hue or not Calculator or not Calculator.temp then return nil, nil end

    local band = state.tempBand
    local step = state.tempPull

    local autoLowHue  = Calculator.temp(hue, state.lowTemp,  band, step)
    local autoHighHue = Calculator.temp(hue, state.highTemp, band, step)
    return autoLowHue, autoHighHue
end

return Temperature
