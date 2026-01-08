-----------------------------------
-- UI Render Helpers
-----------------------------------
local Settings   = Import("src/state/Settings.lua")
local ColorUtils = Import("src/gen/utils/ColorUtils.lua")
local Palettes   = Import("src/palettes/Registry.lua")

local Render = {}

-- Static imports
local getTemp     = ColorUtils.getTemp
local createColor = ColorUtils.createColor

-- Refreshes the main Shifty dialog (base swatches + palette grids).
function Render.refreshMain()
    if not SHIFTY_DLG then return end

    local fgDisplay = createColor(Settings.getCache("fgColor"))
    local bgDisplay = createColor(Settings.getCache("bgColor"))
    SHIFTY_DLG:modify { id = "base", colors = { fgDisplay, bgDisplay } }

    for _, id in ipairs(Palettes.ORDER) do
        SHIFTY_DLG:modify { id = string.lower(tostring(id)), colors = Palettes.get(id) }
    end
end

-- Refreshes the auto-temp display swatches in the Settings dialog.
function Render.refreshAutoTemps()
    if not SETTINGS_DLG or not Settings.get("autoTemp") then return end
    SETTINGS_DLG:modify { id = "autoLowTemp",  color = getTemp(Settings.get("autoLowTemp")) }
    SETTINGS_DLG:modify { id = "autoHighTemp", color = getTemp(Settings.get("autoHighTemp")) }
end

return Render
