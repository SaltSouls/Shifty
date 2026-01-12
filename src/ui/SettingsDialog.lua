local Settings        = Import("src/state/Settings.lua")
local ColorUtils      = Import("src/gen/utils/ColorUtils.lua")
local SettingsActions = Import("src/app/SettingsActions.lua")
local HelpDialog      = Import("src/ui/HelpDialog.lua")

---@diagnostic disable: undefined-global

--------------------------------------------------------------------------------
-- SettingsDialog
--
-- Builds the advanced settings dialog and wires controls to SettingsActions.
--------------------------------------------------------------------------------

---@class SettingsDialog
local SettingsDialog  = {}

local toggle          = SettingsActions.toggle
local setTempHue      = SettingsActions.setTempHue
local setNumber       = SettingsActions.setNumber
local setPullDir      = SettingsActions.setPullDir
local setSlots        = SettingsActions.setSlots
local setUpdateDelay  = SettingsActions.setUpdateDelay

---Opens the Settings dialog (child of the main Shifty dialog).
function SettingsDialog.open()
    local success, err = pcall(function()
        local dlg

        -- Disable the settings button while the dialog is open.
        if SHIFTY_DLG then SHIFTY_DLG:modify { id = "settings", enabled = false } end

        -- Re-enable the settings button when the Settings dialog closes.
        local function enableSettings()
            return function()
                if not SETTINGS_DLG == dlg then return end
                SETTINGS_DLG = nil
                if not SHIFTY_DLG then return end

                SHIFTY_DLG:modify {
                    id = "settings",
                    enabled = true
                }
            end
        end

        dlg = Dialog {
            title = "Settings",
            parent = SHIFTY_DLG,
            onclose = enableSettings()
        }

        SETTINGS_DLG      = dlg
        local low         = ColorUtils.getTemp(Settings.get("lowTemp"))
        local high        = ColorUtils.getTemp(Settings.get("highTemp"))
        local autoLow     = ColorUtils.getTemp(Settings.get("autoLowTemp"))
        local autoHigh    = ColorUtils.getTemp(Settings.get("autoHighTemp"))
        local pullDir     = Settings.get("pullDir")
        local slotsValue  = Settings.get("slots")
        local updateDelay = Settings.get("updateDelay")

        SETTINGS_DLG
            :check {
                id = "autoPick",
                text = "Auto Pick",
                selected = Settings.get("autoPick"),
                onclick = toggle("autoPick")
            }
            :check {
                id = "autoTemp",
                text = "Auto Temp",
                selected = Settings.get("autoTemp"),
                onclick = toggle("autoTemp")
            }
            :separator { text = "Shade Settings:" }
            :label     { text = "Cool" }
            :label     { text = "Warm" }
            :color {
                id = "lowTemp",
                label = "Temps:",
                color = low,
                onchange = setTempHue("lowTemp")
            }
            :color {
                id = "highTemp",
                color = high,
                onchange = setTempHue("highTemp")
            }:newrow()
            :color {
                id = "autoLowTemp",
                label = "Display:",
                color = autoLow,
                enabled = false,
                visible = Settings.get("autoTemp")
            }
            :color {
                id = "autoHighTemp",
                color = autoHigh,
                enabled = false,
                visible = Settings.get("autoTemp")
            }
            :radio {
                id = "-1",
                label = "Pull:",
                text = "left",
                selected = (pullDir == -1),
                onclick = setPullDir(-1),
                visible = Settings.get("autoTemp")
            }
            :radio {
                id = "0",
                text = "auto",
                selected = (pullDir == 0),
                onclick = setPullDir(0),
                visible = Settings.get("autoTemp")
            }
            :radio {
                id = "1",
                text = "right",
                selected = (pullDir == 1),
                onclick = setPullDir(1),
                visible = Settings.get("autoTemp")
            }
            :separator {}
            :slider {
                id = "intensity",
                label = "Intensity:",
                min = 1,
                max = 100,
                value = Settings.get("intensity"),
                onchange = setNumber("intensity")
            }
            :slider {
                id = "peak",
                label = "Peak:",
                min = 1,
                max = 100,
                value = Settings.get("peak"),
                onchange = setNumber("peak")
            }
            :slider {
                id = "sway",
                label = "Sway:",
                min = 1,
                max = 100,
                value = Settings.get("sway"),
                onchange = setNumber("sway")
            }
            :separator { text = "Other Settings:" }
            :slider {
                id = "lightness",
                label = "Light:",
                min = 1,
                max = 100,
                value = Settings.get("lightness"),
                onchange = setNumber("lightness")
            }
            :slider {
                id = "saturation",
                label = "Saturation:",
                min = 1,
                max = 100,
                value = Settings.get("saturation"),
                onchange = setNumber("saturation")
            }
            :separator { text = "UI Settings:" }
            :radio {
                id = "7",
                label = "Slots:",
                text = "7",
                selected = (slotsValue == 7),
                onclick = setSlots(7)
            }
            :radio {
                id = "9",
                text = "9",
                selected = (slotsValue == 9),
                onclick = setSlots(9)
            }
            :radio {
                id = "11",
                text = "11",
                selected = (slotsValue == 11),
                onclick = setSlots(11)
            }
            :radio {
                id = "15",
                text = "15",
                selected = (slotsValue == 15),
                onclick = setSlots(15)
            }
            :slider {
                id = "updateDelay",
                label = "Update Delay (ms):",
                min = 0,
                max = 250,
                value = updateDelay,
                onchange = setUpdateDelay
            }
            :separator {}
            :button {
                text = "&Reset",
                onclick = SettingsActions.resetDefaults
            }
            :button {
                text = "&Help",
                onclick = HelpDialog.show
            }
            :show { wait = false }
    end)

    if not success then app.alert { title = "Error", text = "Failed to create dialog: " .. tostring(err) } end
end

return SettingsDialog
