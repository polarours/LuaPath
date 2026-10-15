-- restart-policy.lua
local M = {}

local RestartPolicy = {}
RestartPolicy.__index = RestartPolicy

function RestartPolicy.new(config)
  -- config: {max_retries, backoff ("exponential"|"linear"), interval}
  -- TODO
end

function RestartPolicy:next_delay(attempt)
  -- exponential: min(2^attempt, 30)
  -- linear:      attempt * interval
  -- TODO
end

function RestartPolicy:can_restart(attempt)
  return attempt <= self.max_retries
end

M.RestartPolicy = RestartPolicy
return M
