-----------------------------------
-- Imports
-----------------------------------
local Settings   = Import("src/state/Settings.lua")
local ColorUtils = Import("src/gen/utils/ColorUtils.lua")
local Render     = Import("src/ui/Render.lua")
local ShiftyApp  = Import("src/app/ShiftyApp.lua")

-- Static imports
local getTemp = ColorUtils.getTemp

local SettingsActions = {}

-- Toggle a boolean setting.
function SettingsActions.toggle(id)
    return function()
        if not SETTINGS_DLG then return end
        Settings.set(id, not Settings.get(id))

        -- autoTemp affects both the UI and the effective temperatures.
        if id == "autoTemp" and SETTINGS_DLG then
            local enabled = Settings.get("autoTemp")
            SETTINGS_DLG:modify { id = "autoLowTemp",  visible = enabled }
            SETTINGS_DLG:modify { id = "autoHighTemp", visible = enabled }
        end

        ShiftyApp.requestRebuild(Settings.getBaseColor())
    end
end

-- Set a numeric setting from the dialog widget value.
function SettingsActions.setNumber(id)
    return function()
        if not SETTINGS_DLG then return end
        local value = SETTINGS_DLG.data[id]

        Settings.set(id, value)
        ShiftyApp.requestRebuild(Settings.getBaseColor())
    end
end

-- UI update delay
function SettingsActions.setUpdateDelay()
    if not SETTINGS_DLG then return end
    local value = SETTINGS_DLG.data.updateDelay

    Settings.set("updateDelay", value)
    ShiftyApp.setSchedulerDelay(value)
end

-- For radio buttons / explicit slot values.
function SettingsActions.setSlots(n)
    return function()
        Settings.set("slots", n)
        ShiftyApp.requestRebuild(Settings.getBaseColor())
    end
end

-- Color picker for lowTemp/highTemp.
function SettingsActions.setTempHue(id)
    return function()
        if not SETTINGS_DLG then return end
        local data  = SETTINGS_DLG.data[id]
        local sat   = data.saturation
        local light = data.lightness
        local alpha = data.alpha

        -- Preserve the hue field while the user is editing.
        if data.hue == nil then data.hue = Settings.get(id) end
        Settings.set(id, data.hue)

        -- If the user tweaks S/L/A, don't treat it as a final hue selection.
        if sat ~= 1 or light ~= 0.5 or alpha ~= 255 then
            SETTINGS_DLG:modify { id = id, color = getTemp(data.hue) }
            return
        end

        ShiftyApp.requestRebuild(Settings.getBaseColor())
        Render.refreshAutoTemps()
    end
end

local function syncSetting(id)
    if not SETTINGS_DLG then return end
    local isTemp      = (id == "lowTemp" or id == "highTemp")
    local isAutoTemp  = (id == "autoLowTemp" or id == "autoHighTemp")
    local isSlots     = (id == "slots")

    if isTemp or isAutoTemp then
        SETTINGS_DLG:modify { id = id, color = getTemp(Settings.get(id)) }
    elseif isSlots then
        local radioId = tostring(Settings.get("slots"))
        SETTINGS_DLG:modify { id = radioId, selected = true }
    else SETTINGS_DLG:modify { id = id, value = Settings.get(id) } end
end

function SettingsActions.resetDefaults()
    if not SETTINGS_DLG then return end

    for _, id in ipairs(Settings.data.defaultable) do
        Settings.set(id, Settings.getDefault(id))
        syncSetting(id)
        if id == "updateDelay" then
            ShiftyApp.setSchedulerDelay(Settings.get("updateDelay"))
        end
    end

    ShiftyApp.requestRebuild(Settings.getBaseColor())
    Render.refreshAutoTemps()
end

return SettingsActions
