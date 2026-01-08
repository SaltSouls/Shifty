local Scheduler = {}

-- Scheduler.create(delaySeconds, fn) -> function
--
-- Schedules rapid calls into a single delayed execution.
-- This is used to prevent UI controls (especially sliders) from triggering
-- expensive work dozens of times per drag.
--
-- How it works:
--   - Every call stores the most recent arguments.
--   - A timer is (re)started for `delaySeconds`.
--   - When the timer fires, `fn` is called ONCE with the latest arguments.
--     via Aseprite's timer mechanism.
function Scheduler.create(delaySeconds, fn)
    delaySeconds = tonumber(delaySeconds) or 0

    -- Scheduler disabled: call through directly.
    if delaySeconds <= 0 then
        return function(...) return fn(...) end
    end

    local timer = nil
    local pendingArgs = nil

    -- Returned wrapper that schedules calls to `fn`.
    return function(...)
        -- Save the latest arguments and restart timer to ensure execution settles.
        pendingArgs = { ... }
        if timer then
            timer:stop()
            timer = nil
        end

        timer = Timer {
            interval = delaySeconds,
            ontick = function()
                -- Capture & clear pending args first to avoid re-entrance issues.
                local args = pendingArgs
                pendingArgs = nil

                -- One-shot: stop and clear the timer before invoking fn.
                if timer then timer:stop() end
                timer = nil

                fn(table.unpack(args or {}))
            end
        }

        timer:start()
    end
end

return Scheduler