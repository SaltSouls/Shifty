-----------------------------------
-- Settings Dialog (UI)
-----------------------------------
local Settings        = Import("src/state/Settings.lua")
local ColorUtils      = Import("src/gen/utils/ColorUtils.lua")
local SettingsActions = Import("src/app/SettingsActions.lua")
local HelpDialog      = Import("src/ui/HelpDialog.lua")

local SettingsDialog = {}

function SettingsDialog.open()
    SETTINGS_DLG     = Dialog { title = "Settings", parent = SHIFTY_DLG }
    local low        = ColorUtils.getTemp(Settings.get("lowTemp"))
    local high       = ColorUtils.getTemp(Settings.get("highTemp"))
    local autoLow    = ColorUtils.getTemp(Settings.get("autoLowTemp"))
    local autoHigh   = ColorUtils.getTemp(Settings.get("autoHighTemp"))
    local slotsValue = Settings.get("slots")
    local updateDelay = Settings.get("updateDelay")

    SETTINGS_DLG
        :check { id = "autoPick", text = "Auto Pick", selected = Settings.get("autoPick"), onclick = SettingsActions.toggle("autoPick") }
        :check { id = "autoTemp", text = "Auto Temp", selected = Settings.get("autoTemp"), onclick = SettingsActions.toggle("autoTemp") }
        :separator { text = "Shade Settings:" }
        :label { text = "Cool" }
        :label { text = "Warm" }
        :color { id = "lowTemp", label = "Temps:", color = low, onchange = SettingsActions.setTempHue("lowTemp") }
        :color { id = "highTemp", color = high, onchange = SettingsActions.setTempHue("highTemp") }:newrow()
        :color { id = "autoLowTemp", label = "Display:", color = autoLow, enabled = false, visible = Settings.get("autoTemp") }
        :color { id = "autoHighTemp", color = autoHigh, enabled = false, visible = Settings.get("autoTemp") }
        :separator {}
        :slider { id = "intensity", label = "Intensity:", min = 1, max = 100, value = Settings.get("intensity"), onchange = SettingsActions.setNumber("intensity") }
        :slider { id = "peak", label = "Peak:", min = 1, max = 100, value = Settings.get("peak"), onchange = SettingsActions.setNumber("peak") }
        :slider { id = "sway", label = "Sway:", min = 1, max = 100, value = Settings.get("sway"), onchange = SettingsActions.setNumber("sway") }
        :separator { text = "Other Settings:" }
        :slider { id = "lightness", label = "Light:", min = 1, max = 100, value = Settings.get("lightness"), onchange = SettingsActions.setNumber("lightness") }
        :slider { id = "saturation", label = "Saturation:", min = 1, max = 100, value = Settings.get("saturation"), onchange = SettingsActions.setNumber("saturation") }
        :separator { text = "UI Settings:" }
        :radio { id = "7",  label = "Slots:", text = "7", selected = (slotsValue == 7),  onclick = SettingsActions.setSlots(7) }
        :radio { id = "9",  text = "9", selected = (slotsValue == 9),  onclick = SettingsActions.setSlots(9) }
        :radio { id = "11", text = "11", selected = (slotsValue == 11), onclick = SettingsActions.setSlots(11) }
        :radio { id = "15", text = "15", selected = (slotsValue == 15), onclick = SettingsActions.setSlots(15) }
        :slider { id = "updateDelay", label = "Update Delay (ms):", min = 0, max = 250, value = updateDelay, onchange = SettingsActions.setUpdateDelay }
        :separator {}
        :button { text = "&Reset", onclick = SettingsActions.resetDefaults }
        :button { text = "&Help", onclick = HelpDialog.show }
        :show { wait = false }
end

return SettingsDialog
