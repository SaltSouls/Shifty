---@diagnostic disable: undefined-global

--------------------------------------------------------------------------------
-- Scheduler
--
-- Creates a task scheduler using Aseprite's Timer to ensure execution delay.
--------------------------------------------------------------------------------

---@class Scheduler
local Scheduler = {}

---Creates a task scheduler.
---
---If `delaySeconds <= 0`, this returns a pass-through function.
---If `delaySeconds > 0`, each call restarts the timer; only the last call runs.
---@param delaySeconds number
---@param fn fun(...:any)
---@return fun(...:any)
---@public
function Scheduler.create(delaySeconds, fn)
    delaySeconds = tonumber(delaySeconds) or 0
    if delaySeconds <= 0 then return function(...) return fn(...) end end

    local timer       = nil
    local pendingArgs = nil

    return function(...)
        -- Create a table of current tasks attempting execution,
        -- and reset timer on receiving new tasks.
        pendingArgs = { ... }
        if timer then
            timer:stop()
            timer = nil
        end

        -- Configure timer with set delay and to only unpack tasks
        -- after said delay is up; then clear self.
        timer = Timer {
            interval = delaySeconds,
            ontick   = function()
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
