-- health.lua
local M = {}

-- Coroutine-based health check scheduler
function M.start(manager, interval)
  -- Run a coroutine that checks all services every `interval` seconds
  -- On failure: call manager:restart(name)
  -- TODO
end

return M
