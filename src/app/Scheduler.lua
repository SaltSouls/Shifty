---@diagnostic disable: undefined-global

--------------------------------------------------------------------------------
-- Scheduler
--
-- Creates a debounce-style wrapper around a function using Aseprite's Timer.
--------------------------------------------------------------------------------

---@class Scheduler
local Scheduler = {}

---Creates a debounced wrapper.
---
---If `delaySeconds <= 0`, this returns a pass-through function.
---If `delaySeconds > 0`, each call restarts the timer; only the last call runs.
---@param delaySeconds number
---@param fn fun(...:any)
---@return fun(...:any)
---@public
function Scheduler.create(delaySeconds, fn)
    delaySeconds = tonumber(delaySeconds) or 0
    if delaySeconds <= 0 then return function(...)
        return fn(...) end
    end

    local timer       = nil
    local pendingArgs = nil

    return function(...)
        pendingArgs = { ... }
        if timer then
            timer:stop()
            timer = nil
        end

        -- Timer is recreated each call to ensure we reliably reset interval.
        timer = Timer {
            interval = delaySeconds,
            ontick = function()
                local args  = pendingArgs
                pendingArgs = nil
                if timer then timer:stop() end
                timer = nil
                fn(table.unpack(args or {}))
            end }
        timer:start()
    end
end

return Scheduler
