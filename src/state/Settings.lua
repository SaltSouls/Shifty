local Cache = Import("src/state/Cache.lua")

---@diagnostic disable: undefined-global

--------------------------------------------------------------------------------
-- Settings
--
-- Central configuration store (in-memory) + validation helpers.
--
-- Notes:
-- - `Settings.data` entries follow: { value = <current>, default = <default> }
-- - Some values are "defaultable" and used by Reset.
--------------------------------------------------------------------------------

---@class ShiftySettingEntry
---@field value any
---@field default any

---@class Settings
---@field maxHue number
---@field data table<string, ShiftySettingEntry>|{defaultable:string[]}
---@field getCache fun(id:string):any
---@field setCache fun(id:string, value:any)
---@field get fun(id:string):any
---@field set fun(id:string, value:any)
---@field getDefault fun(id:string):any
---@field getBaseColor fun():Color
---@field getEffectiveTemp fun(id:'lowTemp'|'highTemp'):number
---@field ensureValue fun(id:string):any
---@field snapshot fun():ShiftySettingsSnapshot
local Settings  = {}

local _GShifty = _G
Settings.maxHue = 360

Settings.data   = {
    defaultable = {
        "lowTemp",
        "highTemp",
        "intensity",
        "peak",
        "sway",
        "saturation",
        "lightness",
        "updateDelay"
    },

    dropper      = { value = true, default = true },
    autoPick     = { value = true, default = true },
    autoTemp     = { value = true, default = true },
    lowTemp      = { value = 215, default = 215 },
    autoLowTemp  = { value = 215, default = 215 },
    highTemp     = { value = 50, default = 50 },
    autoHighTemp = { value = 50, default = 50 },
    pullDir      = { value = 0, default = 0 },
    tempPull     = { value = 20, default = 20 },
    intensity    = { value = 25, default = 25 },
    peak         = { value = 50, default = 50 },
    sway         = { value = 50, default = 50 },
    saturation   = { value = 75, default = 75 },
    lightness    = { value = 50, default = 50 },
    slots        = { value = 7, default = 7 },
    updateDelay  = { value = 25, default = 25 }
}

function Settings.getCache(id) return Cache.get(id) end
function Settings.setCache(id, value) Cache.set(id, value) end

function Settings.get(id) return Settings.data[id].value end
function Settings.set(id, value)
    Settings.data[id].value = value
    -- Save modified settings to plugin.preferences, except for autoTemp values.
    if _GShifty.SHIFTY_PREFS and Settings.data[id] ~= nil then
        local isAutoTemp = (id == "autoLowTemp" or id == "autoHighTemp")
        if not isAutoTemp then _GShifty.SHIFTY_PREFS[id] = value end
    end
end
function Settings.getDefault(id) return Settings.data[id].default end

function Settings.getBaseColor()
    return Settings.getCache(Settings.getCache("selected") == "bg" and "bgColor" or "fgColor")
end

function Settings.getEffectiveTemp(id)
    if not Settings.get("autoTemp") then return Settings.get(id) end
    if id == "lowTemp" then return Settings.get("autoLowTemp") end
    if id == "highTemp" then return Settings.get("autoHighTemp") end
end

--------------------------------------------------------------------------------
-- Validation
--------------------------------------------------------------------------------


local function isNumber(v) return type(v) == "number" end
local function isBoolean(v) return type(v) == "boolean" end
local function inRange(v, min, max) return isNumber(v) and v >= min and v <= max end
local function oneOf(v, ...)
    for i = 1, select("#", ...) do if v == select(i, ...) then return true end end
    return false
end

local validators = {
    dropper      = isBoolean,
    autoPick     = isBoolean,
    autoTemp     = isBoolean,

    lowTemp      = function(v) return inRange(v, 0, Settings.maxHue) end,
    highTemp     = function(v) return inRange(v, 0, Settings.maxHue) end,
    autoLowTemp  = function(v) return inRange(v, 0, Settings.maxHue) end,
    autoHighTemp = function(v) return inRange(v, 0, Settings.maxHue) end,

    pullDir      = function(v) return oneOf(v, -1, 0, 1) end,
    tempPull     = function(v) return inRange(v, 1, 360) end,

    intensity    = function(v) return inRange(v, 1, 100) end,
    peak         = function(v) return inRange(v, 1, 100) end,
    sway         = function(v) return inRange(v, 1, 100) end,
    saturation   = function(v) return inRange(v, 1, 100) end,
    lightness    = function(v) return inRange(v, 1, 100) end,

    slots        = function(v) return oneOf(v, 7, 9, 11, 15) end,
    updateDelay  = function(v) return inRange(v, 0, 250) end,
}

---Checks whether a value is valid for the given setting id.
---@param id string
---@param value any
---@return boolean
local function isValid(id, value)
    local validator = validators[id]
    if validator then return validator(value) end
    return value ~= nil
end

function Settings.ensureValue(id)
    local value = Settings.get(id)
    if value ~= nil and isValid(id, value) then return value end
    local default = Settings.getDefault(id)

    Settings.set(id, default)
    return default
end

--------------------------------------------------------------------------------
-- Snapshot
--------------------------------------------------------------------------------

---Creates a validated, read-only-ish view of settings used by the generator.
---
---The generator uses a snapshot so it doesn't have to read from Settings/Cache
---multiple times while values are changing (slider drags, auto-pick, etc.).
---@class ShiftySettingsSnapshot
---@field fgColor Color
---@field bgColor Color
---@field fgAlpha integer
---@field bgAlpha integer
---@field selected 'fg'|'bg'
---@field baseColor Color
---@field slots integer
---@field autoTemp boolean
---@field lowTemp number
---@field highTemp number
---@field autoLowTemp number
---@field autoHighTemp number
---@field pullDir number
---@field tempPull number
---@field intensity number
---@field peak number
---@field sway number
---@field saturation number
---@field lightness number
---@return ShiftySettingsSnapshot
function Settings.snapshot()
    local selected   = Settings.getCache("selected")
    local fgColor    = Settings.getCache("fgColor")
    local bgColor    = Settings.getCache("bgColor")
    local base       = Settings.getBaseColor()

    return {
        fgColor      = fgColor,
        bgColor      = bgColor,
        fgAlpha      = Settings.getCache("fgAlpha"),
        bgAlpha      = Settings.getCache("bgAlpha"),
        selected     = selected,
        baseColor    = base,

        slots        = Settings.ensureValue("slots"),
        autoTemp     = Settings.ensureValue("autoTemp"),
        lowTemp      = Settings.ensureValue("lowTemp"),
        highTemp     = Settings.ensureValue("highTemp"),
        autoLowTemp  = Settings.ensureValue("autoLowTemp"),
        autoHighTemp = Settings.ensureValue("autoHighTemp"),
        pullDir      = Settings.ensureValue("pullDir"),
        tempPull     = Settings.ensureValue("tempPull"),
        intensity    = Settings.ensureValue("intensity"),
        peak         = Settings.ensureValue("peak"),
        sway         = Settings.ensureValue("sway"),
        saturation   = Settings.ensureValue("saturation"),
        lightness    = Settings.ensureValue("lightness")
    }
end

return Settings
