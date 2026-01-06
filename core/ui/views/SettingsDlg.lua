-----------------------------------
-- Imports
-----------------------------------
local Settings   = Import("core/Settings.lua")
local ColorUtils = Import("core/color/utils/ColorUtils.lua")
local Controller = Import("core/ui/controllers/SettingsController.lua")
local HelpDlg    = Import("core/ui/views/HelpDlg.lua")

local SettingsDlg = {}

-----------------------------------
-- Dialog Functions
-----------------------------------
function SettingsDlg.open()
    SETTINGS_DLG     = Dialog { title = "Settings", parent = SHIFTY_DLG }
    local low        = ColorUtils.getTemp(Settings.get("lowTemp"))
    local high       = ColorUtils.getTemp(Settings.get("highTemp"))
    local slotsValue = Settings.get("slots")

    SETTINGS_DLG
        :check { id = "autoPick", text = "Auto Pick", selected = Settings.get("autoPick"), onclick = Controller.update("autoPick", true) }
        :check { id = "autoTemp", text = "Auto Temp", selected = Settings.get("autoTemp"), onclick = Controller.update("autoTemp", true) }
        :separator { text = "Shade Settings:" }
        :label { text = "Cool" }
        :label { text = "Warm" }
        :color { id = "lowTemp", label = "Temps:", color = low, onchange = Controller.updateTemp("lowTemp") }
        :color { id = "highTemp", color = high, onchange = Controller.updateTemp("highTemp") }
        :separator {}
        :slider { id = "intensity", label = "Intensity:", min = 1, max = 100, value = Settings.get("intensity"), onchange = Controller.update("intensity") }
        :slider { id = "peak", label = "Peak:", min = 1, max = 100, value = Settings.get("peak"), onchange = Controller.update("peak") }
        :slider { id = "sway", label = "Sway:", min = 1, max = 100, value = Settings.get("sway"), onchange = Controller.update("sway") }
        :separator { text = "Other Settings:" }
        :slider { id = "lightness", label = "Light:", min = 1, max = 100, value = Settings.get("lightness"), onchange = Controller.update("lightness") }
        :slider { id = "saturation", label = "Saturation:", min = 1, max = 100, value = Settings.get("saturation"), onchange = Controller.update("saturation") }
        :separator {}
        :radio { id = "7",  label = "Slots:", text = "7", selected = (slotsValue == 7),  onclick = Controller.update("slots", false, 7) }
        :radio { id = "9",  text = "9", selected = (slotsValue == 9),  onclick = Controller.update("slots", false, 9) }
        :radio { id = "11", text = "11", selected = (slotsValue == 11), onclick = Controller.update("slots", false, 11) }
        :radio { id = "15", text = "15", selected = (slotsValue == 15), onclick = Controller.update("slots", false, 15) }
        :separator {}
        :button { text = "&Reset", onclick = Controller.reset }
        :button { text = "&Help", onclick = HelpDlg.show }
        :show { wait = false }
end

return SettingsDlg
