-- dashboard.lua
local M = {}

-- Query manager state
function M.status(manager, service_name)
  -- Returns {running=bool, uptime_secs, restart_count, last_error}
  -- TODO
end

function M.all(manager)
  -- Returns { [name] = status_table }
  -- TODO
end

return M
