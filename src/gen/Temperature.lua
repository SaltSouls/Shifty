---@class Temperature
local Temperature = {}

--------------------------------------------------------------------------------
-- Temperature
--
-- Computes "auto" low/high temperature hues when Auto Temp is enabled.
--------------------------------------------------------------------------------

---Computes auto low/high hues.
---@param state ShiftySettingsSnapshot
---@param hue number Base hue in degrees.
---@param Calculator { temp: fun(hue:number, anchor:number, step:number):number }
---@return number? lowHue
---@return number? highHue
function Temperature.compute(state, hue, Calculator)
    if not state or not state.autoTemp then return nil, nil end
    if not hue or not Calculator or not Calculator.temp then return nil, nil end
    local step = state.tempPull

    local autoLowHue  = Calculator.temp(hue, state.lowTemp, step)
    local autoHighHue = Calculator.temp(hue, state.highTemp, step)
    return autoLowHue, autoHighHue
end

return Temperature
