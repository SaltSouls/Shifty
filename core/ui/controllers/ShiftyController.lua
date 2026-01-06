-----------------------------------
-- Imports
-----------------------------------
local Settings   = Import("core/Settings.lua")
local ColorUtils = Import("core/color/utils/ColorUtils.lua")
local Palettes   = Import("core/color/Palettes.lua")
local Calculator = Import("core/color/Calculator.lua")
local Generator  = Import("core/color/Generator.lua")

-- Static imports
local createColor = ColorUtils.createColor
local getTemp     = ColorUtils.getTemp

local Controller = {}

-----------------------------------
-- Main Dlg Controllers
-----------------------------------
local function updateDisplay()
    if not SHIFTY_DLG then return end -- Don't update if not initialized

    -- Update base colors
    local fgDisplay = createColor(Settings.getCache("fgColor"))
    local bgDisplay = createColor(Settings.getCache("bgColor"))
    SHIFTY_DLG:modify { id = "base", colors = { fgDisplay, bgDisplay } }

    -- Update palette colors
    for _, id in ipairs(Palettes.ORDER) do SHIFTY_DLG:modify{ id = string.lower(tostring(id)), colors = Palettes.get(id) } end

end

local function autoTempUpdate(color)
    if not Settings.get("autoTemp") then return end
    local hue = color.hue
    Calculator.temp(hue, "lowTemp")
    Calculator.temp(hue, "highTemp")
end

local function updateTempDisplay()
    if not SETTINGS_DLG or not Settings.get("autoTemp") then return end
    SETTINGS_DLG:modify { id = "lowTemp",  color = getTemp(Settings.get("lowTemp")) }
    SETTINGS_DLG:modify { id = "highTemp", color = getTemp(Settings.get("highTemp")) }
end

-- Update palettes and refresh dialog
function Controller.updatePalettes(color)
    autoTempUpdate(color)
    Generator.palettes(color)
    updateTempDisplay()
    updateDisplay()
end

local function updateColor(id, color)
    local isFg = id == "fgColor"
    app[id] = createColor(color, Settings.getCache(isFg and "fgAlpha" or "bgAlpha"))
    Settings.setCache(id, color)
    updateDisplay()
end

local function getSelectedColorCacheKey()
    return Settings.getCache("selected") == "fg" and "fgColor" or "bgColor"
end

-- Update FG or BG color on click and optionally refresh palettes
function Controller.onShadesClick(ev)
    Settings.set("dropper", false)
    local color       = ev.color
    local mouseButton = ev.button

    if mouseButton == MouseButton.LEFT then
        updateColor("fgColor", color)
        Settings.setCache("selected", "fg")
        Settings.setCache("lastColor", color)
        return
    end

    if mouseButton == MouseButton.RIGHT then
        updateColor("bgColor", color)
        Settings.setCache("selected", "bg")
        Settings.setCache("lastColor", color)
        return
    end

    if mouseButton == MouseButton.MIDDLE then
        local cacheKey = getSelectedColorCacheKey()
        updateColor(cacheKey, color)
        Controller.updatePalettes(color)
        Settings.setCache("lastColor", color)
        return
    end
end

return Controller
