-- SHIFTY:
-- Script for generating color shifted palettes based on the PyxelEdit feature.
--
-- This script is a collaborative effort by the Aseprite community and is provided
-- at no cost. If you have been forced to pay for this script, it is a scam, and
-- the page should be reported to one of the active maintainers.
--
-- Version: 7.0.0
--
-- Credits:
-- David Capello    - Aseprite
-- domjon           - v1.0.0-2.0.0
-- yashar98         - v3.0.0
-- Daeyangae        - v3.1.0
-- hoelzlmanuel     - v4.0.0
-- GerryLCDF        - v5.0.0-5.0.5
-- TwinSouls        - v6.0.0-7.0.0

--------------------------------------------------------------------------------
-- EmmyLua / LuaLS notes
--
-- This project runs inside Aseprite's Lua runtime.
-- Aseprite provides globals like: `app`, `Color`, `Dialog`, `Timer`, `Rectangle`.
-- These annotations exist to improve autocomplete + static checking.
--------------------------------------------------------------------------------

---@diagnostic disable: undefined-global

---@class ShiftyGlobal
---@field SHIFTY_DLG Dialog|nil
---@field SETTINGS_DLG Dialog|nil
---@field SHIFTY_VERSION string

---@type ShiftyGlobal
local _GShifty = _G

local thisFile = debug.getinfo(1, "S").source:match("^@(.+)$")
local ROOT = app.fs.filePath(app.fs.filePath(thisFile))
_GShifty.ShiftyModules = _GShifty.ShiftyModules or {}

--------------------------------------------------------------------------------
-- Module Loader
--------------------------------------------------------------------------------

---Loads and memoizes a Shifty module (relative to project root).
---
---Aseprite uses a single Lua state for scripts; caching prevents duplicate
---`dofile()` calls when modules are imported from different entry points.
---@param file string Relative path from project root.
---@return any module The returned value from `dofile()`.
function Import(file)
    local fullPath = app.fs.joinPath(ROOT, file)
    if not ShiftyModules[fullPath] then ShiftyModules[fullPath] = dofile(fullPath) end
    return ShiftyModules[fullPath]
end

local Settings = Import("src/state/Settings.lua")
local Shifty   = Import("src/ui/ShiftyDialog.lua")
local App      = Import("src/app/ShiftyApp.lua")

local function readFile(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local contents = file:read("*a")
    file:close()
    return contents
end

local function loadVersion()
    local pkgPath = app.fs.joinPath(ROOT, "package.json")
    local contents = readFile(pkgPath)
    if not contents then return "0.0.0" end

    local version = contents:match('"version"%s*:%s*"([^"]+)"')
    return version or "0.0.0"
end

_GShifty.SHIFTY_DLG     = nil
_GShifty.SETTINGS_DLG   = nil
_GShifty.SHIFTY_VERSION = loadVersion()

--------------------------------------------------------------------------------
-- Aseprite Plugin Hooks
--------------------------------------------------------------------------------

---@class PluginCommandSpec
---@field id string
---@field title string
---@field group string
---@field onclick fun()

---@class Plugin
---@field newCommand fun(self: Plugin, spec: PluginCommandSpec)

---Aseprite entry point.
---@param plugin Plugin
function init(plugin)
    -- Persist Settings across sessions.
    _GShifty.SHIFTY_PREFS = plugin.preferences

    -- Load validated plugin settings into app settings.
    for id, entry in pairs(Settings.data) do
        if type(entry) ~= "table" and entry.default == nil then goto continue end

        local saved = plugin.preferences[id]
        if saved ~= nil then Settings.set(id, saved) end
        Settings.ensureValue(id)
        ::continue::
    end

    -- Apply persisted scheduler delay immediately.
    App.setSchedulerDelay(Settings.get("updateDelay"))

    plugin:newCommand {
        id      = "shifty",
        title   = "Shifty",
        group   = "view_screen",
        onclick = function()
            if not app.isUIAvailable then return end
            Shifty.start()
            App.rebuild(Settings.getCache("fgColor"))
        end,
        onenabled=function()
            if not app.sprite then return false end
            if SHIFTY_DLG then return false end
            return true
        end
    }
end

---Aseprite exit hook.
---@param plugin Plugin
function exit(plugin) end
