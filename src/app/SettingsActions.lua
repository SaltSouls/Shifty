local Settings   = Import("src/state/Settings.lua")
local ColorUtils = Import("src/gen/utils/ColorUtils.lua")
local Render     = Import("src/ui/Render.lua")
local ShiftyApp  = Import("src/app/ShiftyApp.lua")

---@diagnostic disable: undefined-global

--------------------------------------------------------------------------------
-- SettingsActions
--
-- Event handlers for the Settings dialog UI controls.
--------------------------------------------------------------------------------

---@class SettingsActions
local SettingsActions = {}

local getTemp         = ColorUtils.getTemp

--------------------------------------------------------------------------------
-- Toggle / Slider / Color Pickers
--------------------------------------------------------------------------------

---Toggles a boolean setting and triggers a rebuild.
---@param id string
---@return fun()
function SettingsActions.toggle(id)
    return function()
        if not SETTINGS_DLG then return end
        Settings.set(id, not Settings.get(id))

        if id == "autoTemp" and SETTINGS_DLG then
            local enabled = Settings.get("autoTemp")
            SETTINGS_DLG:modify { id = "autoLowTemp", visible = enabled }
            SETTINGS_DLG:modify { id = "autoHighTemp", visible = enabled }
            SETTINGS_DLG:modify { id = "-1", visible = enabled }
            SETTINGS_DLG:modify { id = "0", visible = enabled }
            SETTINGS_DLG:modify { id = "1", visible = enabled }
        end

        ShiftyApp.requestRebuild(Settings.getBaseColor())
    end
end

---Reads a numeric control value from the dialog and stores it.
---@param id string
---@return fun()
function SettingsActions.setNumber(id)
    return function()
        if not SETTINGS_DLG then return end
        local value = SETTINGS_DLG.data[id]

        Settings.set(id, value)
        ShiftyApp.requestRebuild(Settings.getBaseColor())
    end
end

---Sets the auto temp pull direction (radio group).
---@param n integer
---@return fun()
function SettingsActions.setPullDir(n)
    return function()
        Settings.set("pullDir", n)
        ShiftyApp.requestRebuild(Settings.getBaseColor())
    end
end

---Sets the swatch count per palette (radio group).
---@param n integer
---@return fun()
function SettingsActions.setSlots(n)
    return function()
        Settings.set("slots", n)
        ShiftyApp.requestRebuild(Settings.getBaseColor())
    end
end

---Updates debouncer delay for rebuild requests.
function SettingsActions.setUpdateDelay()
    if not SETTINGS_DLG then return end
    local value = SETTINGS_DLG.data.updateDelay

    Settings.set("updateDelay", value)
    ShiftyApp.setSchedulerDelay(value)
end

---Handles temperature color pickers.
---
---Aseprite's color widget can be edited by the user. We only treat it as a
---valid hue pick if the user hasn't changed the helper's SAT/L/L alpha values.
---@param id 'lowTemp'|'highTemp'
---@return fun()
function SettingsActions.setTempHue(id)
    return function()
        if not SETTINGS_DLG then return end
        local data  = SETTINGS_DLG.data[id]
        local sat   = data.saturation
        local light = data.lightness
        local alpha = data.alpha

        if data.hue == nil then data.hue = Settings.get(id) end
        Settings.set(id, data.hue)

        if sat ~= 1 or light ~= 0.5 or alpha ~= 255 then
            SETTINGS_DLG:modify { id = id, color = getTemp(data.hue) }
            return
        end

        ShiftyApp.requestRebuild(Settings.getBaseColor())
        Render.refreshAutoTemps()
    end
end

local function syncSetting(id)
    -- Keeps UI controls in sync when we programmatically change setting values.
    if not SETTINGS_DLG then return end
    local isTemp     = (id == "lowTemp" or id == "highTemp")
    local isAutoTemp = (id == "autoLowTemp" or id == "autoHighTemp")
    local isSlots    = (id == "slots")

    if isTemp or isAutoTemp then
        SETTINGS_DLG:modify { id = id, color = getTemp(Settings.get(id)) }
    elseif isSlots then
        local radioId = tostring(Settings.get("slots"))
        SETTINGS_DLG:modify { id = radioId, selected = true }
    else
        SETTINGS_DLG:modify { id = id, value = Settings.get(id) }
    end
end

--------------------------------------------------------------------------------
-- Reset
--------------------------------------------------------------------------------

---Resets all "defaultable" settings to their defaults and refreshes the UI.
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
