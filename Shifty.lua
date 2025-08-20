-- SHIFTY:
-- Script for generating color shifted palettes based on the PyxelEdit feature. 
--
-- This script is a collaborative effort by the Aseprite community and is provided
-- at no cost. If you have been forced to pay for this script, it is a scam, and
-- the page should be reported to the one of the active maintainers.
--
-- Version: 6.0.0
--
-- Credits:
-- David Capello    - Aseprite
-- domjon           - v1.0.0-2.0.0
-- yashar98         - v3.0
-- Daeyangae        - v3.1.0
-- hoelzlmanuel     - v4.0.0
-- GerryLCDF        - v5.0.0-5.0.5
-- TwinSouls        - v6.0.0

do
    -----------------------------------
    -- App Variables
    -----------------------------------
    -- Global constants
    local MAX_HUE = 360
    local SHIFTY, SETTINGS

    -- Cached data
    local cache = {
        fgColor = app.fgColor,
        fgAlpha = app.fgColor.alpha,
        bgColor = app.bgColor,
        bgAlpha = app.bgColor.alpha,
        lastColor = app.fgColor,
        selected = "fg"
    }

    -- Settings with default and current values
    local settings = {
        eyeDropper = {value = true, default = true},
        autoPick = {value = true, default = true},
        autoTemp = {value = true, default = true},
        lowTemp = {value = 215, default = 215},
        highTemp = {value = 50, default = 50},
        intensity = {value = 50, default = 50},
        peak = {value = 50, default = 50},
        sway = {value = 65, default = 65},
        saturation = {value = 75, default = 75},
        light = {value = 50, default = 50},
        slots = {value = 7, default = 7}
    }

    -- Color palettes
    local palettes = {
        shade = {},
        lightness = {},
        saturation = {},
        hueShift = {},
        mixed = {},
        hueJump = {},
        complementary = {},
        triadic = {},
        tetradic = {}
    }

    -----------------------------------
    -- Data Accessors
    -----------------------------------
    local function setData(id, value) cache[id] = value end
    local function getData(id) return cache[id] end
    local function getValue(id) return settings[id].value end
    local function setValue(id, value) settings[id].value = value end

    -----------------------------------
    -- Color Utilities
    -----------------------------------
    -- Create a color with optional alpha override
    local function createColor(baseColor, alphaOverride)
        local newColor = Color(baseColor)
        newColor.alpha = alphaOverride or 255
        return newColor
    end

    local function isSameColor(color1, color2)
        return color1.hue == color2.hue and
               color1.saturation == color2.saturation and
               color1.lightness == color2.lightness
    end

    -- Gets the distance between two colors
    local function getDistance(color1, color2)
        local hue = math.abs(color1.hue - color2.hue)
        local sat = math.abs(color1.saturation - color2.saturation)
        local light = math.abs(color1.lightness - color2.lightness)
        return (hue + sat + light)
    end

    local function setPaletteColor(id, index, color) palettes[id][index] = createColor(color) end
    local function clearPalettes() for id, _ in pairs(palettes) do palettes[id] = {} end end
    local function getPaletteColors(id) return palettes[id] end

    -----------------------------------
    -- Color Calculation Helpers
    -----------------------------------
    local function lerp(first, second, by) return first * (1 - by) + second * by end
    local function clamp(value, min, max) return math.min(math.max(value, min), max) end

    local function shiftHue(color, amount)
        local newColor = Color(color)
        local shifted = newColor.hue + amount * MAX_HUE
        newColor.hue = (shifted % MAX_HUE + MAX_HUE) % MAX_HUE
        return newColor
    end

    local function shiftSaturation(color, amount)
        local newColor = Color(color)
        local saturation = newColor.saturation
        if amount > 0 then newColor.saturation = clamp(lerp(saturation, 1, amount), 0, 1)
        elseif amount < 0 then newColor.saturation = clamp(lerp(saturation, 0, -amount), 0, 1) end
        return newColor
    end

    local function shiftLightness(color, amount)
        local newColor = Color(color)
        local lightness = newColor.lightness
        if amount > 0 then newColor.lightness = clamp(lerp(lightness, 1, amount), 0, 1)
        elseif amount < 0 then newColor.lightness = clamp(lerp(lightness, 0, -amount), 0, 1) end
        return newColor
    end

    local function shiftHSL(color, hue, saturation, lightness)
        return shiftHue(shiftSaturation(shiftLightness(color, lightness), saturation), hue)
    end

    local function mixColors(color1, color2, proportion)
        return Color {
            red = clamp(lerp(color1.red, color2.red, proportion), 0, 255),
            green = clamp(lerp(color1.green, color2.green, proportion), 0, 255),
            blue = clamp(lerp(color1.blue, color2.blue, proportion), 0, 255)
        }
    end

    local function shiftShading(color, factor, direction, hue, proportion)
        local intensity = getValue("intensity") / 100 * factor
        local peak = getValue("peak") / 100 * factor * direction
        local highShift = 0.5
        local midShift = 0.25
        local lowShift = 0.1

        -- Adjust lightness value depending on color similarity
        local hueShifted = Color(shiftHSL(color, 0, intensity, peak))
        hueShifted.hue = hue
        local distance = getDistance(color, hueShifted)
        local light = distance <= 25 and highShift
            or (distance >= 100 or distance <= 50 ) and midShift
            or distance <= 100 and lowShift or 0
        return shiftLightness(mixColors(color, hueShifted, proportion), light * factor * direction)
    end

    -----------------------------------
    -- Main Color Calculation
    -----------------------------------
    local function calculateColors(baseColor)
        local lowTemp = getValue("lowTemp")
        local highTemp = getValue("highTemp")
        local sway = getValue("sway") / 100
        local light = getValue("light") / 100
        local saturation = getValue("saturation") / 100
        local slots = getValue("slots")

        clearPalettes() -- Prepare palettes

        for i = 1, slots do
            local slotsMult = slots + 1
            local targetHue = lowTemp
            local factor = ((slots - 1) / 2 - i + 1) / ((slots - 1) / 2)
            local direction = -1
            -- Invert variables for lighter shades
            if i >= slots / 2 then
                targetHue = highTemp
                factor = -factor
                direction = 1
            end
            local proportion = sway * factor

            -- Calculate palette colors
            local shadeColor = shiftShading(baseColor, factor, direction, targetHue, proportion)
            local lightnessColor = shiftLightness(baseColor, light * factor * direction)
            local saturationColor = shiftSaturation(baseColor, saturation * factor * direction)
            local hueShiftColor = shiftHue(baseColor, -(slotsMult / 2 - i) * 0.75 / slotsMult * 2 / slotsMult)
            local mixedColor = mixColors(getData("fgColor"), getData("bgColor"), (i - 1) / (slots - 1))
            local hueJumpColor = shiftHue(baseColor, -(slotsMult / 2 - i) * 3 / slotsMult * 2 / slotsMult)

            setPaletteColor("shade", i, shadeColor)
            setPaletteColor("lightness", i, lightnessColor)
            setPaletteColor("saturation", i, saturationColor)
            setPaletteColor("hueShift", i, hueShiftColor)
            setPaletteColor("mixed", i, mixedColor)
            setPaletteColor("hueJump", i, hueJumpColor)

            -- Override specific slots
            if i == 1 then
                setPaletteColor("mixed", i, getData("fgColor"))
            elseif i == math.floor(slotsMult / 2) then
                setPaletteColor("shade", i, baseColor)
                setPaletteColor("lightness", i, baseColor)
                setPaletteColor("saturation", i, baseColor)
                setPaletteColor("hueShift", i, baseColor)
            elseif i == getValue("slots") then
                setPaletteColor("mixed", i, getData("bgColor"))
            end
        end

        -- Harmonic palettes
        setPaletteColor("complementary", 1, baseColor)
        setPaletteColor("complementary", 2, shiftHue(baseColor, 0.5))

        setPaletteColor("triadic", 1, baseColor)
        setPaletteColor("triadic", 2, shiftHue(baseColor, 120 / MAX_HUE))
        setPaletteColor("triadic", 3, shiftHue(baseColor, 240 / MAX_HUE))

        setPaletteColor("tetradic", 1, baseColor)
        setPaletteColor("tetradic", 2, shiftHue(baseColor, 90 / MAX_HUE))
        setPaletteColor("tetradic", 3, shiftHue(baseColor, 180 / MAX_HUE))
        setPaletteColor("tetradic", 4, shiftHue(baseColor, 270 / MAX_HUE))
    end

    -----------------------------------
    -- Temperature Calculation
    -----------------------------------
    local function getTempColor(hue) return createColor({ h = hue, s = 1, l = 0.5 }) end

    -- Calculate hue for temperature based on the type
    local function calculateHue(hue, targetId)
        local newHue = hue
        local isWarm = targetId == "highTemp"
        local minHue = isWarm and 55 or 240
        local shift = isWarm and -100 or 100
        local rangeMin = 55
        local rangeMax = isWarm and 255 or 240

        -- Calculate hue values, dragging towards blue for cool and yellow for warm
        if hue >= rangeMin and hue <= rangeMax then
            newHue = isWarm and math.max(minHue, hue + shift) or math.min(minHue, hue + shift)
        else
            newHue = (hue - shift) % MAX_HUE
            if isWarm and newHue > minHue and (hue < 55 or hue > 315) then newHue = minHue
            elseif not isWarm and newHue < minHue then newHue = minHue end
        end

        setValue(targetId, newHue)
    end

    local function updateTempValues(color)
        local hue = color.hue
        calculateHue(hue, "lowTemp")
        calculateHue(hue, "highTemp")
        if not SETTINGS then return end -- Don't update if not initialized
        SETTINGS:modify { id = "lowTemp", color = getTempColor(getValue("lowTemp")) }
        SETTINGS:modify { id = "highTemp", color = getTempColor(getValue("highTemp")) }
    end

    -----------------------------------
    -- Event Handlers
    -----------------------------------
    local function updateDialog()
        if not SHIFTY then return end
        -- Update base colors
        local fgDisplay = createColor(getData("fgColor"))
        local bgDisplay = createColor(getData("bgColor"))
        SHIFTY:modify { id = "base", colors = { fgDisplay, bgDisplay } }

        -- Update palette colors
        for paletteId, _ in pairs(palettes) do SHIFTY:modify { id = paletteId, colors = getPaletteColors(paletteId) } end
    end

    local function updateColor(id, color)
        local isFg = id == "fgColor"
        app[id] = createColor(color, getData(isFg and "fgAlpha" or "bgAlpha"))
        setData(id, color)
    end

    -- Update palettes and refresh dialog
    local function updatePalettes(color)
        if getValue("autoTemp") then
            updateTempValues(color)
        end
        calculateColors(color)
        updateDialog()
    end

    -- Update FG or BG color on click and optionally refresh palettes
    local function onShadesClick(ev)
        setValue("eyeDropper", false)
        local color = ev.color
        local action = ev.button
        local leftClick = MouseButton.LEFT
        local rightClick = MouseButton.RIGHT
        local middleClick = MouseButton.MIDDLE

        if action == leftClick then
            updateColor("fgColor", color)
            setData("selected", "fg")
        elseif action == middleClick then
            local id = getData("selected") == "fg" and "fgColor" or "bgColor"
            updateColor(id, color)
            updatePalettes(color)
        elseif action == rightClick then
            updateColor("bgColor", color)
            setData("selected", "bg")
        end
        setData("lastColor", color)
    end

    -----------------------------------
    -- Dialog Helper Functions
    -----------------------------------
    local function updateTemp(id)
        return function()
            if getValue("autoTemp") then return end
            local SHIFTYData = SETTINGS.data[id]
            local sat = SHIFTYData.saturation
            local light = SHIFTYData.lightness
            local alpha = SHIFTYData.alpha

            if SHIFTYData.hue == nil then SHIFTYData.hue = getValue(id) end
            setValue(id, SHIFTYData.hue)
            if sat ~= 1 or light ~= 0.5 or alpha ~= 255 then
                SETTINGS:modify { id = id, color = getTempColor(SHIFTYData.hue) }
                return
            end
            updatePalettes(getData("lastColor"))
        end
    end

    local function updateValue(id, amount)
        return function()
            if amount ~= nil then setValue(id, amount)
            else setValue(id, SETTINGS.data[id]) end
            updatePalettes(getData("lastColor"))
        end
    end

    local function updateCheckBox(id)
        return function()
            setValue(id, not getValue(id))
        end
    end

    local function resetValues()
        if not SETTINGS then return end
        for id, setting in pairs(settings) do
            local notAutoChecks = id ~= "autoPick" and id ~= "autoTemp"
            if notAutoChecks then setValue(id, setting.default) end
        end

        SETTINGS:modify { id = "lowTemp", color = getTempColor(getValue("lowTemp")) }
        SETTINGS:modify { id = "highTemp", color = getTempColor(getValue("highTemp")) }
        SETTINGS:modify { id = "intensity", value = getValue("intensity") }
        SETTINGS:modify { id = "peak", value = getValue("peak") }
        SETTINGS:modify { id = "sway", value = getValue("sway") }
        SETTINGS:modify { id = "saturation", value = getValue("saturation") }
        SETTINGS:modify { id = "light", value = getValue("light") }
        SETTINGS:modify { id = "7", selected = true }
        updatePalettes(getData("lastColor"))
    end

    -----------------------------------
    -- Dialog Handlers
    -----------------------------------
    local function showHelp()
        app.alert {
            title = "Help",
            text = {
                "Controls:",
                "- Left Click: Sets the swatch color as FG.",
                "- Right Click: Sets the swatch color as BG.",
                "- Middle Click: Sets FG or BG (based on last selected) and regenerates palettes.",
                "- Base Swatches: Click to select FG (left) or BG (right) as the palette base.",
                "- Get Button: Updates base colors from current FG/BG and regenerates palettes.",
                "- Settings Button: Opens advanced settings dialog.",
                "- Reset Button: Restores settings to their default values.",
                "- Help Button: Shows this dialog.",
                "",
                "Palettes:",
                "- Base Palettes:",
                "  1. Shade (hue/temperature shifts)",
                "  2. Lightness",
                "  3. Saturation",
                "  4. Hue Shift (minor shifts in hue)",
                "  5. Mixed (FG/BG blend)",
                "- Extra Palettes:",
                "  1. Hue Jump (major shifts in hue)",
                "  (harmonic color schemes)",
                "  2. Complementary",
                "  3. Triadic",
                "  4. Tetradic",
                "",
                "Settings (Advanced):",
                "- Auto Pick: Automatically updates palettes when FG/BG changes.",
                "- Auto Temp: Automatically adjusts warm/cool hues based on base color.",
                "- Cool/Warm Temps: Set hues for dark/light shade shifts.",
                "- Intensity (1-200): Controls saturation gradient in shades.",
                "- Peak (1-100): Adjusts brightness of lightest shades.",
                "- Sway (1-100): Sets strength of temperature-based hue shifts.",
                "- Saturation (25-100): Adjusts intensity of saturation gradient.",
                "- Light (25-100): Adjusts intensity of lightness gradient.",
                "- Slots (7-15): Number of swatches per palette.",
                ""
            }
        }
    end

    local function createSettingsDialog()
        SETTINGS = Dialog{ title = "Settings", parent = SHIFTY }
        local low = getTempColor(getValue("lowTemp"))
        local high = getTempColor(getValue("highTemp"))

        SETTINGS
            :check { id = "autoPick", text = "Auto Pick", selected = getValue("autoPick"), onclick = updateCheckBox("autoPick") }
            :check { id = "autoTemp", text = "Auto Temp", selected = getValue("autoTemp"), onclick = updateCheckBox("autoTemp") }
            :separator { text = "Shade Settings:" }
            :label { text = "Cool" }
            :label { text = "Warm" }
            :color { id = "lowTemp", label = "Temps:", color = low, onchange = updateTemp("lowTemp") }
            :color { id = "highTemp", color = high, onchange = updateTemp("highTemp") }
            :separator {}
            :slider { id = "intensity", label = "Intensity:", min = 1, max = 200, value = getValue("intensity"), onchange = updateValue("intensity") }
            :slider { id = "peak", label = "Peak:", min = 1, max = 100, value = getValue("peak"), onchange = updateValue("peak") }
            :slider { id = "sway", label = "Sway:", min = 1, max = 100, value = getValue("sway"), onchange = updateValue("sway") }
            :separator { text = "Other Settings:" }
            :slider { id = "light", label = "Light:", min = 25, max = 100, value = getValue("light"), onchange = updateValue("light") }
            :slider { id = "saturation", label = "Saturation:", min = 25, max = 100, value = getValue("saturation"), onchange = updateValue("saturation") }
            :separator {}
            :radio { id = "7", label = "Slots:", text = "7", selected = true, onclick = updateValue("slots", 7) }
            :radio { id = "9", text = "9", onclick = updateValue("slots", 9) }
            :radio { id = "11", text = "11", onclick = updateValue("slots", 11) }
            :radio { id = "15", text = "15", onclick = updateValue("slots", 15) }
            :separator {}
            :button { text = "&Reset", onclick = resetValues }
            :button { text = "&Help", onclick = showHelp }
            :show { wait = false }
    end

    local function createDialog()
        local success, err = pcall(function()
        local fgColor = createColor(getData("fgColor"))
        local bgColor = createColor(getData("bgColor"))

        -----------------------------------
        -- Listener Functions
        -----------------------------------
        -- Updates palettes on FG or BG change
        local function onFBGChange(isFg)
            return function()
                if getValue("eyeDropper") and getValue("autoPick") then
                    local color = isFg and app.fgColor or app.bgColor
                    setData(isFg and "fgColor" or "bgColor", color)
                    setData(isFg and "fgAlpha" or "bgAlpha", color.alpha)
                    setData("selected", isFg and "fg" or "bg")
                    setData("lastColor", color)
                    updatePalettes(color)
                end
                -- Cache alpha values for FG and BG colors
                setData(isFg and "fgAlpha" or "bgAlpha", (isFg and app.fgColor or app.bgColor).alpha)
                setValue("eyeDropper", true)
            end
        end

        -- Enable/Disable FG/BG color listeners
        local fgListenerCode = app.events:on('fgcolorchange', onFBGChange(true))
        local bgListenerCode = app.events:on('bgcolorchange', onFBGChange(false))
        local function disableListeners()
            app.events:off(fgListenerCode)
            app.events:off(bgListenerCode)
        end

        SHIFTY = Dialog { title = "Shifty", onclose = disableListeners }
        SHIFTY
            :separator { text = "Base Colors:" }
            :shades { id = "base", colors = { fgColor, bgColor }, onclick = function(ev)
                    setData("selected", isSameColor(getData("lastColor"), getData("fgColor")) and "fg" or "bg")
                    setData("lastColor", ev.color)
                    updatePalettes(ev.color)
                end
            }
            :button { id = "get", text = "&Get", onclick = function()
                    setData("fgColor", app.fgColor)
                    setData("bgColor", app.bgColor)
                    local baseColor = getData(getData("selected") == "bg" and "bgColor" or "fgColor")
                    setData("lastColor", baseColor)
                    updatePalettes(baseColor)
                end
            }
            :tab { id = "basePalettes", text = "Base Palettes" }
            :shades { id = "shade", onclick = onShadesClick }:newrow()
            :shades { id = "lightness", onclick = onShadesClick }:newrow()
            :shades { id = "saturation", onclick = onShadesClick }:newrow()
            :shades { id = "hueShift", onclick = onShadesClick }:newrow()
            :shades { id = "mixed", onclick = onShadesClick }:newrow()
            :tab { id = "extraPalettes", text = "Extra Palettes" }
            :shades { id = "hueJump", onclick = onShadesClick }:newrow()
            :shades { id = "complementary", onclick = onShadesClick }:newrow()
            :shades { id = "triadic", onclick = onShadesClick }:newrow()
            :shades { id = "tetradic", onclick = onShadesClick }:newrow()
            :endtabs {}
            :button { id = "settings", text = "&Settings", onclick = createSettingsDialog }
            :separator { text = "version: 6.0.0" }
            :show { wait = false }

            local bounds = SHIFTY.bounds
            SHIFTY.bounds = Rectangle { bounds.x, bounds.y, 176, bounds.height }
        end)
        if not success then app.alert { title = "Error", text = "Failed to create dialog: " .. tostring(err) } end
    end

    createDialog()
    updatePalettes(getData("fgColor"))
end
