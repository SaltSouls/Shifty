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

-----------------------------------
-- Path Functions
-----------------------------------
-- Relative path loading
local thisFile = debug.getinfo(1, "S").source:match("^@(.+)$")
local ROOT = app.fs.filePath(thisFile)
_G.ShiftyModules = _G.ShiftyModules or {}

-- File importing system
function Import(file)
    local fullPath = app.fs.joinPath(ROOT, file)
    if not ShiftyModules[fullPath] then ShiftyModules[fullPath] = dofile(fullPath) end
    return ShiftyModules[fullPath]
end

-----------------------------------
-- Version Loader
-----------------------------------
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

-----------------------------------
-- Imports
-----------------------------------
local Settings   = Import("src/state/Settings.lua")
local Shifty     = Import("src/ui/ShiftyDialog.lua")
local App = Import("src/app/ShiftyApp.lua")

-----------------------------------
-- Global Variables
-----------------------------------
_G.SHIFTY_DLG     = nil
_G.SETTINGS_DLG   = nil
_G.SHIFTY_VERSION = loadVersion()

-----------------------------------
-- Plugin Initialization
-----------------------------------
function init(plugin)
    plugin:newCommand {
        id      = "shifty",
        title   = "Shifty",
        group   = "view_screen",
        onclick = function()
            if not app.isUIAvailable then return end
            Shifty.start()
            App.rebuild(Settings.getCache("fgColor"))
        end
    }
end

function exit(plugin) end
