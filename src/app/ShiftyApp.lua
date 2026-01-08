-----------------------------------
-- Imports
-----------------------------------
local Settings    = Import("src/state/Settings.lua")
local Palettes    = Import("src/palettes/Registry.lua")
local Generator   = Import("src/gen/Generator.lua")
local Calculator  = Import("src/gen/Calculator.lua")
local Temperature = Import("src/gen/Temperature.lua")
local Render      = Import("src/ui/Render.lua")
local Scheduler   = Import("src/app/Scheduler.lua")

local ShiftyApp = {}


-- Update scheduler for rebuilding UI elements
local requestRebuild

local function rebuildRequestFn()
    local ms = Settings.get("updateDelay") or 0
    if ms <= 0 then return function(baseColor) ShiftyApp.rebuild(baseColor) end end
    return Scheduler.create(ms / 1000, function(baseColor) ShiftyApp.rebuild(baseColor) end)
end

requestRebuild = rebuildRequestFn()

-----------------------------------
-- Rebuild Pipeline
-----------------------------------
-- 1) Snapshot inputs
-- 2) Derive auto temps (if enabled)
-- 3) Generate palettes (pure)
-- 4) Replace palette registry (atomic)
-- 5) Refresh UI
function ShiftyApp.rebuild(baseColor)
    baseColor = baseColor or Settings.getCache("lastColor") or Settings.getBaseColor()
    if not baseColor then return end
    Settings.setCache("lastColor", baseColor)

    local state = Settings.snapshot()
    -- Allow generation from a clicked palette color without changing selection.
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

-- Update debounce behavior when the user changes UI responsiveness.
function ShiftyApp.setSchedulerDelay(_) requestRebuild = rebuildRequestFn() end

-- Public API for UI/controllers
function ShiftyApp.requestRebuild(baseColor) requestRebuild(baseColor) end

return ShiftyApp
