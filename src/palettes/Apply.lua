-----------------------------------
-- Apply
-----------------------------------
-- All side-effects that write to Aseprite (fg/bg colors, sprite palette, etc.)
-- should live here so generation and state stay clean.

local ColorUtils = Import("src/gen/utils/ColorUtils.lua")

-- Static imports
local createColor = ColorUtils.createColor

local Apply = {}

function Apply.fgColor(color, alpha) app.fgColor = createColor(color, alpha) end
function Apply.bgColor(color, alpha) app.bgColor = createColor(color, alpha) end

return Apply
