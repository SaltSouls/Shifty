-----------------------------------
-- Imports
-----------------------------------
local Settings   = Import("src/state/Settings.lua")
local ColorUtils = Import("src/gen/utils/ColorUtils.lua")
local Apply      = Import("src/palettes/Apply.lua")
local Render     = Import("src/ui/Render.lua")
local ShiftyApp  = Import("src/app/ShiftyApp.lua")

local Actions = {}

local function updateColor(cacheKey, color)
    local isFg = cacheKey == "fgColor"
    local alpha = Settings.getCache(isFg and "fgAlpha" or "bgAlpha")
    if isFg then Apply.fgColor(color, alpha)
    else Apply.bgColor(color, alpha) end
    Settings.setCache(cacheKey, color)
    Render.refreshMain()
end

local function getSelectedColorCacheKey()
    return Settings.getCache("selected") == "fg" and "fgColor" or "bgColor"
end

-----------------------------------
-- Palette shade click handling
-----------------------------------
function Actions.onPaletteShadeClick(ev)
    Settings.set("dropper", false)

    local color       = ev.color
    local mouseButton = ev.button

    if mouseButton == MouseButton.LEFT then
        updateColor("fgColor", color)
        Settings.setCache("selected", "fg")
        return
    end

    if mouseButton == MouseButton.RIGHT then
        updateColor("bgColor", color)
        Settings.setCache("selected", "bg")
        return
    end

    if mouseButton == MouseButton.MIDDLE then
        local cacheKey = getSelectedColorCacheKey()
        updateColor(cacheKey, color)
        ShiftyApp.requestRebuild(color)
        return
    end
end

-----------------------------------
-- Base palette control
-----------------------------------
function Actions.onBaseSwatchClick(ev)
    local color = ev.color
    if not color then return end

    -- Determine selection based on which swatch was clicked.
    local fg = Settings.getCache("fgColor")
    if ColorUtils.isSameColor(color, fg) then Settings.setCache("selected", "fg")
    else Settings.setCache("selected", "bg")
    end

    Settings.setCache("lastColor", color)
    ShiftyApp.requestRebuild(color)
end

function Actions.onGetClick()
    Settings.setCache("fgColor", app.fgColor)
    Settings.setCache("bgColor", app.bgColor)
    local baseColor = Settings.getBaseColor()
    ShiftyApp.requestRebuild(baseColor)
end

-----------------------------------
-- App event listeners
-----------------------------------
-- Updates palettes on FG or BG change when auto-pick is enabled.
function Actions.onFGorBGChange(isFg)
    return function()
        if Settings.get("dropper") and Settings.get("autoPick") then
            local color = isFg and app.fgColor or app.bgColor
            Settings.setCache(isFg and "fgColor" or "bgColor", color)
            Settings.setCache(isFg and "fgAlpha" or "bgAlpha", color.alpha)
            Settings.setCache("selected", isFg and "fg" or "bg")
            Settings.setCache("lastColor", color)
            ShiftyApp.requestRebuild(color)
        end

        -- Cache alpha values for FG and BG colors.
        Settings.setCache(isFg and "fgAlpha" or "bgAlpha", (isFg and app.fgColor or app.bgColor).alpha)
        Settings.set("dropper", true)
    end
end

return Actions
