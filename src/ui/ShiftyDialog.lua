local Settings       = Import("src/state/Settings.lua")
local ColorUtils     = Import("src/gen/utils/ColorUtils.lua")
local Palettes       = Import("src/palettes/Registry.lua")
local Actions        = Import("src/app/Actions.lua")
local SettingsDialog = Import("src/ui/SettingsDialog.lua")

---@diagnostic disable: undefined-global

--------------------------------------------------------------------------------
-- ShiftyDialog
--
-- Builds the main Shifty dialog (base swatches + palette tabs).
--------------------------------------------------------------------------------

---@class ShiftyDialog
local ShiftyDialog        = {}

local createColor         = ColorUtils.createColor
local onFGorBGChange      = Actions.onFGorBGChange
local onBaseSwatchClick   = Actions.onBaseSwatchClick
local onGetClick          = Actions.onGetClick
local onPaletteShadeClick = Actions.onPaletteShadeClick

---Adds a list of palette shade rows to the given dialog.
---@param dlg Dialog
---@param paletteIds table<string>
local function addPaletteRows(dlg, paletteIds)
    for _, id in ipairs(paletteIds) do
        dlg:shades {
            id = string.lower(tostring(id)),
            onclick = onPaletteShadeClick,
        }:newrow()
    end
end

---Creates (or recreates) the main dialog and starts FG/BG listeners.
---
---The listeners are removed on close to avoid leaking handlers across runs.
function ShiftyDialog.start()
    local success, err = pcall(function()
        local dlg
        local fgColor = createColor(Settings.getCache("fgColor"))
        local bgColor = createColor(Settings.getCache("bgColor"))

        -- `app.events:on` returns a listener id used to unregister via `off`.
        local fgListenerCode = app.events:on("fgcolorchange", onFGorBGChange(true))
        local bgListenerCode = app.events:on("bgcolorchange", onFGorBGChange(false))

        -- Ensure everything unregisters/closes upon app closure
        local function cleanup()
            app.events:off(fgListenerCode)
            app.events:off(bgListenerCode)
            if not SETTINGS_DLG then return end
            SETTINGS_DLG:close()
        end

        dlg = Dialog {
            title   = "Shifty",
            onclose = cleanup
        }

        SHIFTY_DLG = dlg
        SHIFTY_DLG
            :separator { text = "Base Colors:" }
            :shades {
                id      = "base",
                colors  = { fgColor, bgColor },
                onclick = onBaseSwatchClick
            }
            :button {
                id      = "get",
                text    = "&Get",
                onclick = onGetClick
            }
            :tab {
                id      = "basePalettes",
                text    = "Base Palettes"
            }

        addPaletteRows(SHIFTY_DLG, Palettes.BASE)

        SHIFTY_DLG
            :tab {
                id      = "extraPalettes",
                text    = "Extra Palettes"
            }

        addPaletteRows(SHIFTY_DLG, Palettes.EXTRA)

        SHIFTY_DLG:endtabs {}
            :button {
                id      = "settings",
                text    = "&Settings",
                onclick = SettingsDialog.open
            }
            :separator { text = "version: " .. SHIFTY_VERSION }
            :show      { wait = false }

        -- Set bounds when creating dialog to ensure nice/compact display.
        local bounds      = SHIFTY_DLG.bounds
        SHIFTY_DLG.bounds = Rectangle { bounds.x, bounds.y, 176, bounds.height }
    end)

    if not success then app.alert {
        title = "Error",
        text  = "Failed to create dialog: " .. tostring(err)
    } end
end

return ShiftyDialog
