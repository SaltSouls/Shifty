---@diagnostic disable: undefined-global

--------------------------------------------------------------------------------
-- HelpDialog
--------------------------------------------------------------------------------

---@class HelpDlg
local HelpDlg = {}

---Shows a static help popup.
function HelpDlg.show()
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
            "- Pull (left/auto/right): Sets direction to pull hue in when using auto temp.",
            "- Intensity (1-100): Controls saturation gradient in shades.",
            "- Peak (1-100): Adjusts brightness of lightest shades.",
            "- Sway (1-100): Sets strength of temperature-based hue shifts.",
            "- Saturation (1-100): Adjusts intensity of saturation gradient.",
            "- Light (1-100): Adjusts intensity of lightness gradient.",
            "- Slots (7/9/11/15): Number of swatches generated per palette.",
            "- Update Delay (ms): Delay before regenerating palettes when sliders change.",
            "   (Higher Update Delay values reduce CPU usage while tweaking sliders.)"
        }
    }
end

return HelpDlg
