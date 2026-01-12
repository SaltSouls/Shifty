local Settings    = Import("src/state/Settings.lua")
local Palettes    = Import("src/palettes/Registry.lua")
local Generator   = Import("src/gen/Generator.lua")
local Calculator  = Import("src/gen/Calculator.lua")
local Temperature = Import("src/gen/Temperature.lua")
local Render      = Import("src/ui/Render.lua")
local Scheduler   = Import("src/app/Scheduler.lua")

---@diagnostic disable: undefined-global

--------------------------------------------------------------------------------
-- ShiftyApp
--
-- Orchestrates palette generation + UI refreshes.
-- (Settings -> Temperature -> Generator -> Registry -> Render)
--------------------------------------------------------------------------------

---@class ShiftyApp
---@field rebuild fun(baseColor?: Color)
---@field requestRebuild fun(baseColor?: Color)
---@field setSchedulerDelay fun(ms:number)
local ShiftyApp = {}

local requestRebuild

---Builds a rebuild function that optionally debounces based on `updateDelay`.
---
---When delay is > 0 we wrap rebuild in a scheduler that resets its timer on each
---call (slider drag friendly).
---@return fun(baseColor?: Color)
local function rebuildRequestFn()
    local ms = Settings.get("updateDelay") or 0
    if ms <= 0 then return function(baseColor) ShiftyApp.rebuild(baseColor) end end
    return Scheduler.create(ms / 1000, function(baseColor) ShiftyApp.rebuild(baseColor) end)
end

requestRebuild = rebuildRequestFn()

---Regenerates all palette groups using the current settings snapshot.
---@param baseColor? Color If omitted, uses last/base cached colors.
function ShiftyApp.rebuild(baseColor)
    baseColor = baseColor or Settings.getCache("lastColor") or Settings.getBaseColor()
    if not baseColor then return end
    Settings.setCache("lastColor", baseColor)

    local state     = Settings.snapshot()
    state.baseColor = baseColor

    local autoLow, autoHigh = Temperature.compute(state, baseColor.hue, Calculator)
    if autoLow and autoHigh then
        Settings.set("autoLowTemp", autoLow)
        Settings.set("autoHighTemp", autoHigh)
        state.autoLowTemp  = autoLow
        state.autoHighTemp = autoHigh
    end

    local registry = Generator.generate(state)
    Palettes.replace(registry)

    Render.refreshAutoTemps()
    Render.refreshMain()
end

---Recomputes the debounced rebuild function after the delay setting changes.
---@param _ number The delay in ms (unused; read from settings).
function ShiftyApp.setSchedulerDelay(_) requestRebuild = rebuildRequestFn() end

---Requests a rebuild, optionally debounced by the current `updateDelay`.
---@param baseColor? Color
function ShiftyApp.requestRebuild(baseColor) requestRebuild(baseColor) end

return ShiftyApp
