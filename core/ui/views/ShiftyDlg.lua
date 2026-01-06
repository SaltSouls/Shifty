-----------------------------------
-- Imports
-----------------------------------
local Settings    = Import("core/Settings.lua")
local ColorUtils  = Import("core/color/utils/ColorUtils.lua")
local Palettes    = Import("core/color/Palettes.lua")
local Controller  = Import("core/ui/controllers/ShiftyController.lua")
local SettingsDlg = Import("core/ui/views/SettingsDlg.lua")

-- Static imports
local createColor = ColorUtils.createColor
local isSameColor = ColorUtils.isSameColor

local ShiftyDlg = {}

-----------------------------------
-- Dialog Functions
-----------------------------------
function ShiftyDlg.start()
    local success, err = pcall(function()
        local fgColor = createColor(Settings.getCache("fgColor"))
        local bgColor = createColor(Settings.getCache("bgColor"))

        -----------------------------------
        -- Listener Functions
        -----------------------------------
        -- Updates palettes on FG or BG change
        local function onFBGChange(isFg)
            return function()
            if Settings.get("dropper") and Settings.get("autoPick") then
                local color = isFg and app.fgColor or app.bgColor
                Settings.setCache(isFg and "fgColor" or "bgColor", color)
                Settings.setCache(isFg and "fgAlpha" or "bgAlpha", color.alpha)
                Settings.setCache("selected", isFg and "fg" or "bg")
                Settings.setCache("lastColor", color)
                Controller.updatePalettes(color)
            end
            -- Cache alpha values for FG and BG colors
            Settings.setCache(isFg and "fgAlpha" or "bgAlpha", (isFg and app.fgColor or app.bgColor).alpha)
            Settings.set("dropper", true)
            end
        end

        -- Enable/Disable FG/BG color listeners
        local fgListenerCode = app.events:on('fgcolorchange', onFBGChange(true))
        local bgListenerCode = app.events:on('bgcolorchange', onFBGChange(false))
        local function disableListeners()
            app.events:off(fgListenerCode)
            app.events:off(bgListenerCode)
        end

        SHIFTY_DLG = Dialog { title = "Shifty", onclose = disableListeners }
        SHIFTY_DLG
            :separator { text = "Base Colors:" }
            :shades { id = "base", colors = { fgColor, bgColor }, onclick = function(ev)
                    local color = ev.color
                    if isSameColor(color, Settings.getCache("fgColor")) then Settings.setCache("selected", "fg")
                    else Settings.setCache("selected", "bg") end
                    Settings.setCache("lastColor", color)
                    Controller.updatePalettes(color)
                end
            }
            :button { id = "get", text = "&Get", onclick = function()
                    Settings.setCache("fgColor", app.fgColor)
                    Settings.setCache("bgColor", app.bgColor)
                    local baseColor = Settings.getCache(Settings.getCache("selected") == "bg" and "bgColor" or "fgColor")
                    Settings.setCache("lastColor", baseColor)
                    Controller.updatePalettes(baseColor)
                end
            }
            :tab { id = "basePalettes", text = "Base Palettes" }

        for _, id in ipairs(Palettes.BASE) do
            SHIFTY_DLG:shades { id = string.lower(tostring(id)), onclick = Controller.onShadesClick }:newrow()
        end

        SHIFTY_DLG:tab { id = "extraPalettes", text = "Extra Palettes" }

        for _, id in ipairs(Palettes.EXTRA) do
            SHIFTY_DLG:shades { id = string.lower(tostring(id)), onclick = Controller.onShadesClick }:newrow()
        end

        SHIFTY_DLG
            :endtabs {}
            :button { id = "settings", text = "&Settings", onclick = SettingsDlg.open }
            :separator { text = "version: " .. SHIFTY_VERSION }
            :show { wait = false }

        local bounds = SHIFTY_DLG.bounds
        SHIFTY_DLG.bounds = Rectangle { bounds.x, bounds.y, 176, bounds.height }
    end)
    if not success then app.alert { title = "Error", text = "Failed to create dialog: " .. tostring(err) } end
end

return ShiftyDlg
