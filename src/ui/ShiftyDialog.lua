-----------------------------------
-- Shifty Dialog (UI)
-----------------------------------
local Settings      = Import("src/state/Settings.lua")
local ColorUtils    = Import("src/gen/utils/ColorUtils.lua")
local Palettes      = Import("src/palettes/Registry.lua")
local Actions       = Import("src/app/Actions.lua")
local SettingsDialog = Import("src/ui/SettingsDialog.lua")

-- Static imports
local createColor = ColorUtils.createColor

local ShiftyDialog = {}

function ShiftyDialog.start()
    local success, err = pcall(function()
        local fgColor = createColor(Settings.getCache("fgColor"))
        local bgColor = createColor(Settings.getCache("bgColor"))

        -----------------------------------
        -- Listener Functions
        -----------------------------------
        local fgListenerCode = app.events:on("fgcolorchange", Actions.onFGorBGChange(true))
        local bgListenerCode = app.events:on("bgcolorchange", Actions.onFGorBGChange(false))

        local function disableListeners()
            app.events:off(fgListenerCode)
            app.events:off(bgListenerCode)
        end

        SHIFTY_DLG = Dialog { title = "Shifty", onclose = disableListeners }
        SHIFTY_DLG
            :separator { text = "Base Colors:" }
            :shades {
                id = "base",
                colors = { fgColor, bgColor },
                onclick = Actions.onBaseSwatchClick
            }
            :button { id = "get", text = "&Get", onclick = Actions.onGetClick }
            :tab { id = "basePalettes", text = "Base Palettes" }

        for _, id in ipairs(Palettes.BASE) do
            SHIFTY_DLG:shades { id = string.lower(tostring(id)), onclick = Actions.onPaletteShadeClick }:newrow()
        end

        SHIFTY_DLG:tab { id = "extraPalettes", text = "Extra Palettes" }

        for _, id in ipairs(Palettes.EXTRA) do
            SHIFTY_DLG:shades { id = string.lower(tostring(id)), onclick = Actions.onPaletteShadeClick }:newrow()
        end

        SHIFTY_DLG
            :endtabs {}
            :button { id = "settings", text = "&Settings", onclick = SettingsDialog.open }
            :separator { text = "version: " .. SHIFTY_VERSION }
            :show { wait = false }

        local bounds = SHIFTY_DLG.bounds
        SHIFTY_DLG.bounds = Rectangle { bounds.x, bounds.y, 176, bounds.height }
    end)

    if not success then
        app.alert { title = "Error", text = "Failed to create dialog: " .. tostring(err) }
    end
end

return ShiftyDialog
