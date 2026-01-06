-----------------------------------
-- Imports
-----------------------------------
local Settings         = Import("core/Settings.lua")
local ColorUtils       = Import("core/color/utils/ColorUtils.lua")
local ShiftyController = Import("core/ui/controllers/ShiftyController.lua")

-- Static imports
local getTemp = ColorUtils.getTemp
local updatePalettes = ShiftyController.updatePalettes

local Controller = {}

-----------------------------------
-- Setting Dlg Controllers
-----------------------------------
-- Updates dialog value
function Controller.update(id, checkbox, amount)
    return function()
        local data = SETTINGS_DLG.data[id]
        if checkbox then Settings.set(id, not Settings.get(id))
        else
            if amount ~= nil then Settings.set(id, amount)
            else Settings.set(id, data) end
            updatePalettes(Settings.getCache("lastColor"))
        end
    end
end

function Controller.updateTemp(id)
    return function()
        if Settings.get("autoTemp") then return end
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
        updatePalettes(Settings.getCache("lastColor"))
    end
end

local function syncSetting(id)
    local isTemp  = id == "lowTemp" or id == "highTemp"
    local isSlots = id == "slots"
    if not SETTINGS_DLG then return end

    if isTemp then SETTINGS_DLG:modify { id = id, color = getTemp(Settings.get(id)) }
    elseif isSlots then
        local radioId = tostring(Settings.get("slots"))
        SETTINGS_DLG:modify { id = radioId, selected = true }
    else SETTINGS_DLG:modify { id = id, value = Settings.get(id) } end
end

function Controller.reset()
    if not SETTINGS_DLG then return end

    for _, id in ipairs(Settings.data.defaultable) do
        local isTemp = id == "lowTemp" or id == "highTemp"
        if isTemp then
            if not Settings.get("autoTemp") then
                Settings.set(id, Settings.getDefault(id))
                syncSetting(id)
            end
        else Settings.set(id, Settings.getDefault(id)) end
        syncSetting(id)
    end
    updatePalettes(Settings.getCache("lastColor"))
end

return Controller
