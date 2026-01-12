local ColorUtils  = Import("src/gen/utils/ColorUtils.lua")

local createColor = ColorUtils.createColor

---@diagnostic disable: undefined-global

--------------------------------------------------------------------------------
-- Apply
--
-- Small wrappers around `app.fgColor` / `app.bgColor` that preserve alpha.
--------------------------------------------------------------------------------

---@class Apply
local Apply = {}

---Sets the current foreground color.
---@param color Color|table
---@param alpha? integer
function Apply.fgColor(color, alpha) app.fgColor = createColor(color, alpha) end

---Sets the current background color.
---@param color Color|table
---@param alpha? integer
function Apply.bgColor(color, alpha) app.bgColor = createColor(color, alpha) end

return Apply
