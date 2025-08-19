local dlg
local dlgSettings
local fgListenerCode
local bgListenerCode

-----------------------------------
--- APP PARAMETERS ---
-----------------------------------

---[Cached Data]-------------------
local cache = {
    fgColor = app.fgColor,
    fgAlpha = app.fgColor.alpha,
    bgColor = app.bgColor,
    bgAlpha = app.bgColor.alpha,
    lastColor = app.fgColor
}
---[Sets Cached Data]--------------
local function setData(id, value) cache[id] = value end
---[Gets Cached Data]--------------
local function getData(id) return cache[id] end

---[Settings]----------------------
local settings = {
    eyeDropper = {value = true, default = true},
    autoPick = {value = true, default = true},
    autoTemp = {value = false, default = false},
    lowTemp = {value = 215, default = 215},
    highTemp = {value = 50, default = 50},
    intensity = {value = 40, default = 40},
    peak = {value = 60, default = 60},
    sway = {value = 60, default = 60},
    slots = {value = 7, default = 7},
}
---[Get Settings Value]------------
local function getValue(id) return settings[id].value end
---[Get Default Value]-------------
local function getDefault(id) return settings[id].default end
---[Set Settings Value]------------
local function setValue(id, value) settings[id].value = value end

---[Color Palettes]----------------
local colorPalettes = {
    shade = { },
    lightness = { },
    saturation = { },
    hueShift = { },
---[Additional Palettes]-----------
    mixed = { },
    hueJump = { },
    complementary = { },
    triadic = { },
    tetradic = { },
}
---[Get Single Color]--------------
local function getColor(fg, color)
    local newColor = Color(color)

    if fg then newColor.alpha = getData("fgAlpha")
    else newColor.alpha = getData("bgAlpha") end
    return newColor
end
---[Creates a Display Color]-------
local function displayColor(color)
    local newColor = Color(color)
    newColor.alpha = 255
    return newColor
end
---[Get All Colors]----------------
local function getPaletteColors(id) return colorPalettes[id] end
---[Set Color at Index]------------
local function setPaletteColor(id, index, color) colorPalettes[id][index] = displayColor(color) end
-----------------------------------

-----------------------------------
--- COLOR CALCULATION ---
-----------------------------------
--- Helper functions:
local function lerp(first, second, by) return first * (1 - by) + second * by end

local function shiftHue(color, amount)
    local newColor = Color(color)
    newColor.hue = (newColor.hue + amount * 360) % 360
    return newColor
end

local function shiftSaturation(color, amount)
    local newColor = Color(color)
    if (amount > 0) then
        newColor.saturation = lerp(newColor.saturation, 1, amount)
        elseif (amount < 0) then
        newColor.saturation = lerp(newColor.saturation, 0, -amount)
    end
    return newColor
end

local function shiftLightness(color, amount)
    local newColor = Color(color)
    if (amount > 0) then
        newColor.lightness = lerp(newColor.lightness, 1, amount)
        elseif (amount < 0) then
        newColor.lightness = lerp(newColor.lightness, 0, -amount)
    end
    return newColor
end

local function shiftHSL(color, hue, saturation, lightness)
    return shiftHue(shiftSaturation(shiftLightness(color, lightness), saturation), hue)
end

local function mixColors(color1, color2, proportion)
    return Color {
        red = lerp(color1.red, color2.red, proportion),
        green = lerp(color1.green, color2.green, proportion),
        blue = lerp(color1.blue, color2.blue, proportion)
    }
end

local function shiftShading(color, factor, neg, hue, proportion)
    local intensity = getValue("intensity")
    local peak = getValue("peak")
    local hueShifted = Color(shiftHSL(color, 0, intensity / 100 * factor, peak / 100 * factor * neg))

    hueShifted.hue = hue
    return mixColors(color, hueShifted, proportion)
end

--- Main function:
local function calculateColors(baseColor)
    local lowTemp = getValue("lowTemp")
    local highTemp = getValue("highTemp")
    local sway = getValue("sway")
    local slots = getValue("slots")

    for i = 1, slots do
        --- Calculate color shift parameters
        local temp = lowTemp
        local factor = ((slots - 1) / 2 - i + 1) / ((slots - 1) / 2)
        local neg = -1
        if i > slots / 2 then
            temp = highTemp
            factor = (-1) * factor
            neg = 1
        end
        local proportion = sway / 100 * factor
        local slotsMult = slots + 1

        --- Shift colors based on presets
        local shadeColor = shiftShading(baseColor, factor, neg, temp, proportion)
        local lightnessColor = shiftLightness(baseColor, 0.4 * factor * neg)
        local saturationColor = shiftSaturation(baseColor, 0.75 * factor * neg)
        local hueShiftColor = shiftHue(baseColor, (slotsMult / 2 - i) * 1 / slotsMult * 2 / slotsMult)
        local mixedColor = mixColors(getData("fgColor"), getData("bgColor"), 1 / slotsMult * (i * 0.75))
        local hueJumpColor = shiftHue(baseColor, 1 / slotsMult * i)

        --- Set colors for use in UI
        setPaletteColor("shade", i, shadeColor)
        setPaletteColor("lightness", i, lightnessColor)
        setPaletteColor("saturation", i, saturationColor)
        setPaletteColor("hueShift", i, hueShiftColor)
        setPaletteColor("mixed", i, mixedColor)
        setPaletteColor("hueJump", i, hueJumpColor)

        --- Override colors for specific slots
        if i == 1 then
            setPaletteColor("mixed", i, getData("fgColor"))
        elseif i == slotsMult / 2 then
            setPaletteColor("shade", i, baseColor)
            setPaletteColor("lightness", i, baseColor)
            setPaletteColor("saturation", i, baseColor)
            setPaletteColor("hueShift", i, baseColor)
        elseif i == slots then
            setPaletteColor("mixed", i, getData("bgColor"))
        end
    end

    --- Create complementary color palettes
    setPaletteColor("complementary", 1, baseColor)
    setPaletteColor("complementary", 2, shiftHue(baseColor, 0.5))

    setPaletteColor("triadic", 1, baseColor)
    setPaletteColor("triadic", 2, shiftHue(baseColor, 120/360))
    setPaletteColor("triadic", 3, shiftHue(baseColor, 240/360))

    setPaletteColor("tetradic", 1, baseColor)
    setPaletteColor("tetradic", 2, shiftHue(baseColor, 90/360))
    setPaletteColor("tetradic", 3, shiftHue(baseColor, 180/360))
    setPaletteColor("tetradic", 4, shiftHue(baseColor, 270/360))
end


-----------------------------------
--- VALUE MANIPULATION ---
-----------------------------------
local function updateDialogData()
    if not dlg then return end
    --- Base Colors:
    dlg:modify{ id = "base", colors = { displayColor(getData("fgColor")), displayColor(getData("bgColor")) } }

    --- Tab 1:
    dlg:modify{ id = "shade", colors = getPaletteColors("shade") }
    dlg:modify{ id = "lightness", colors = getPaletteColors("lightness") }
    dlg:modify{ id = "saturation", colors = getPaletteColors("saturation") }
    dlg:modify{ id = "hueShift", colors = getPaletteColors("hueShift") }

    -- Tab 2:
    dlg:modify{ id = "mixed", colors = getPaletteColors("mixed") }
    dlg:modify{ id = "hueJump", colors = getPaletteColors("hueJump") }
    dlg:modify{ id = "complementary", colors = getPaletteColors("complementary") }
    dlg:modify{ id = "triadic", colors = getPaletteColors("triadic") }
    dlg:modify{ id = "tetradic", colors = getPaletteColors("tetradic") }
end

-----------------------------------
--- HELPER FUNCTIONS ---
-----------------------------------

local function calculateWarm(hue)
    local newHue = hue
    if (hue >= 55 and hue <= 255) then
        if (hue - 100) < 55 then newHue = 55
        else newHue = hue - 100 end

        setValue("highTemp", newHue)

    elseif (hue <= 256 or hue >= 54) then
        if (hue + 100) > 360 then newHue = (hue + 100) - 360
        else newHue = hue + 100 end

        if newHue > 55 and (hue < 55 or hue > 315) then newHue = 55 end

        setValue("highTemp", newHue)
    end
end

local function calculateCool(hue)
    local newHue = hue
    if (hue >= 55 and hue <= 240) then
        newHue = hue + 100
        if (newHue > 240) then newHue = 240 end
        setValue("lowTemp", newHue)

    elseif (hue <= 241 or hue >= 54) then
        if (hue - 100) < 0 then newHue = (hue + 360) - 100
        else newHue = hue - 100 end
        if newHue < 240 then newHue = 240 end

        setValue("lowTemp", newHue)
    end
end

local function getTempColor(color)
    return Color{ h = color, s = 1, l = 0.5, a = 255 }
end

local function getTempValues(color)
    local hue = color.hue
    calculateCool(hue)
    calculateWarm(hue)
    --- Update the dialog settings with the new values
    dlgSettings:modify{ id = "lowTemp", color = getTempColor(getValue("lowTemp")) }
    dlgSettings:modify{ id = "highTemp", color = getTempColor(getValue("highTemp")) }
end

---[Update single Color]-----------
local function updateColor(id, color)
    local fg = true
    if id == "bgColor" then fg = false end

    setData(id, color)
    app[id] = getColor(fg, color)
end
---[Update All Color Palettes]-----
local function updateColors(color)
    if getValue("autoTemp") then
        getTempValues(color)
    end
    calculateColors(color)
    updateDialogData()
end
-----------------------------------

local function resetValues()
    if not dlgSettings then return end
    setValue("autoPick", getDefault("autoPick"))
    setValue("autoTemp", getDefault("autoTemp"))
    setValue("lowTemp", getDefault("lowTemp"))
    setValue("highTemp", getDefault("highTemp"))
    setValue("intensity", getDefault("intensity"))
    setValue("peak", getDefault("peak"))
    setValue("sway", getDefault("sway"))
    setValue("slots", getDefault("slots"))

    dlgSettings:modify{ id = "autoPick", selected = getValue("autoPick") }
    dlgSettings:modify{ id = "autoTemp", selected = getValue("autoTemp") }
    dlgSettings:modify{ id = "lowTemp", color = getTempColor(getValue("lowTemp")) }
    dlgSettings:modify{ id = "highTemp", color = getTempColor(getValue("highTemp")) }
    dlgSettings:modify{ id = "intensity", value = getValue("intensity") }
    dlgSettings:modify{ id = "peak", value = getValue("peak") }
    dlgSettings:modify{ id = "sway", value = getValue("sway") }

    updateColors(getData("lastColor"))
end
-----------------------------------

local function onFBGChange(fg)
    return function()
        if (getValue("eyeDropper") and getValue("autoPick")) then
            local color = Color()
            if fg then
                color = app.fgColor
                setData("fgColor", color)
                setData("fgAlpha", color.alpha)

            else
                color = app.bgColor
                setData("bgColor", color)
                setData("bgAlpha", color.alpha)
            end
            setData("lastColor", color)
            updateColors(color)
        end

        --- Capture the current alpha value
        if fg then setData("fgAlpha", app.fgColor.alpha)
        else setData("bgAlpha", app.bgColor.alpha) end
        setValue("eyeDropper", true)
    end
end

local function onShadesClick(ev)
    setValue("eyeDropper", false)
    local color = ev.color
    local action = ev.button
    local leftClick = MouseButton.LEFT
    local rightClick = MouseButton.RIGHT
    local middleClick = MouseButton.MIDDLE

    if (action == leftClick) then updateColor("fgColor", color)
    elseif (action == middleClick) then
        if getData("fgColor") == getData("lastColor") then updateColor("fgColor", color)
        else updateColor("bgColor", color) end

        setData("lastColor", color)
        updateColors(color)
    elseif (action == rightClick) then updateColor("bgColor", color)
    end
end

local function showHelp()
    app.alert{
        title="Help",
        text={
            "Tool Description:",
            "- Base: Clicking on a base color changes the generated palette.",
            "- \"Get\": Updates base colors using current FG/BG and regenerates shades.",
            "",
            "Mouse Actions on any swatch:",
            "- Left Click: Set the swatch color as FG.",
            "- Right Click: Set the swatch color as BG.",
            "- Middle Click: Set the color depending on the last changed (FG or BG) and regenerate.",
            "",
            "Advanced Controls:",
            "- Temp. Dark/Light: Adjust warm/cool hue shifts for dark/light shades.",
            "- Intensity: Adds a saturation gradient to the shades.",
            "- Peak: Controls how bright the lightest shades get.",
            "- Sway: Adjusts how strongly the temperature shifts affect the colors.",
            "- Slots: Changes the number of generated color swatches.",
            "",
            "Color Options (Chromatic): Shows harmonic color combinations (Compl., Triad, Tetrad) to inspire color relationships.",
            "",
            "Auto Pick: If enabled, changes in FG/BG automatically update the palette.",
            "Advanced: Shows or hides advanced controls.",
            "",
            "Reset: Returns parameters to their default values."
        }
    }
end

-- Helper functions
local function updateTemp(id)
    return function()
        --- Don't allow updating if auto temp is enabled
        if getValue("autoTemp") then return end

        --- Update temperature value
        local dlgData = (dlgSettings.data[id])
        if dlgData.hue == nil then dlgData.hue = getValue(id) end
        setValue(id, dlgData.hue)
        local sat = dlgData.saturation
        local light = dlgData.lightness
        local alpha = dlgData.alpha
        local notHueChanged = (sat ~= 1 or light ~= 0.5 or alpha ~= 255)

        --- Ensure only hue changes trigger Updates
        if notHueChanged then
            dlgSettings:modify{ id = id, color = getTempColor(dlgData.hue) }
            return
        end
        updateColors(getData("lastColor"))
    end
end

local function updateValue(id)
    return function()
        local value = dlgSettings.data[id]
        setValue(id, value)
        updateColors(getData("lastColor"))
    end
end

local function updateCheckBox(id)
    return function ()
        setValue(id, (not getValue(id)))
    end
end

local function Settings()
    dlgSettings = Dialog("Settings")
    local low = getTempColor(getValue("lowTemp"))
    local high = getTempColor(getValue("highTemp"))

    dlgSettings :check{ id = "autoPick", text = "Auto Pick", selected = getValue("autoPick"), onclick = updateCheckBox("autoPick") }
                :check{ id = "autoTemp", text = "Auto Temp", selected = getValue("autoTemp"), onclick = updateCheckBox("autoTemp") }
                :separator{"Shade Settings:"}
                :label{ text = "Cool" }
                :label{ text = "Warm" }
                :color{ id = "lowTemp", label = "Temps:", color = low, onchange = updateTemp("lowTemp") }
                :color{ id = "highTemp", color = high, onchange = updateTemp("highTemp") }
                :separator{}
                :slider{ id = "intensity", label = "Intensity:", min = 1, max = 200, value = getValue("intensity"), onchange = updateValue("intensity") }
                :slider{ id = "peak", label = "Peak:", min = 1, max = 100, value = getValue("peak"), onchange = updateValue("peak") }
                :slider{ id = "sway", label = "Sway:", min = 1, max = 100, value = getValue("sway"), onchange = updateValue("sway") }
                :separator{}
                :button{ text = "Reset", onclick = resetValues }
                :button{ text = "Help", onclick = showHelp }
                :show{ wait = false }
end

local function disableListeners()
    app.events:off(fgListenerCode)
    app.events:off(bgListenerCode)
end

local function createDialog()
    dlg = Dialog{ title = "Shifty", onclose = disableListeners }
    dlg :separator("Base Colors:")
        :shades{ id = "base", colors = { displayColor(getData("fgColor")), displayColor(getData("bgColor")) },
            onclick = function(ev)
                setData("lastColor", ev.color)
                updateColors(ev.color)
            end
        }
        :button{ id = "get", text = "Get", onclick = function()
                setData("fgColor", app.fgColor)
                setData("bgColor", app.bgColor)

                if getData("lastColor") == getData("bgColor") then
                    print("Updated `lastColor` to `bgColor`: Get Button")
                    setData("lastColor", app.bgColor)
                    updateColors(getData("bgColor"))
                else
                    setData("lastColor", app.fgColor)
                    updateColors(getData("fgColor"))
                end
            end
        }
        -- Base Palettes
        :tab{ id="basePalettes", text="Base Palettes" }
        :shades{ id = "shade", onclick = onShadesClick }:newrow()
        :shades{ id = "lightness", onclick = onShadesClick }:newrow()
        :shades{ id = "saturation", onclick = onShadesClick }:newrow()
        :shades{ id = "hueShift", onclick = onShadesClick }:newrow()
        :shades{ id = "mixed", onclick = onShadesClick }:newrow()

        -- Additional Palettes
        :tab{ id="extraPalettes", text="Extra Palettes" }
        :shades{ id = "hueJump", onclick = onShadesClick }:newrow()
        :shades{ id = "complementary", onclick = onShadesClick }:newrow()
        :shades{ id = "triadic", onclick = onShadesClick }:newrow()
        :shades{ id = "tetradic", onclick = onShadesClick }:newrow()
        :endtabs{}
        :button{ id = "settings", text = "Settings", onclick = Settings }
        :show{ wait = false }

        local bounds = dlg.bounds
        dlg.bounds = Rectangle{ bounds.x, bounds.y, 176, bounds.height }
end

fgListenerCode = app.events:on('fgcolorchange', onFBGChange(true))
bgListenerCode = app.events:on('bgcolorchange', onFBGChange(false))

createDialog()
calculateColors(getData("fgColor"))
updateDialogData()
