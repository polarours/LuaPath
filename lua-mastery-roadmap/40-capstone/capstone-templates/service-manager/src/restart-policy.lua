-- restart-policy.lua
-- Restart policy: how many times a service may be restarted, and how long to
-- wait between attempts.
local M = {}

local RestartPolicy = {}
RestartPolicy.__index = RestartPolicy

--- Create a policy.
-- @param config table {max_retries, backoff ("exponential"|"linear"), interval}
-- @return table the policy
function RestartPolicy.new(config)
  config = config or {}
  return setmetatable({
    max_retries = config.max_retries or 3,
    backoff = config.backoff or "exponential",
    interval = config.interval or 1,
  }, RestartPolicy)
end

--- How long to wait before the given restart attempt.
-- Exponential backoff doubles the delay each time and is capped at 30
-- seconds; linear backoff multiplies the attempt number by the interval.
-- @param attempt number the attempt number, starting at 1
-- @return number the delay in seconds
function RestartPolicy:next_delay(attempt)
  if self.backoff == "linear" then
    return attempt * self.interval
  end
  local delay = 2 ^ attempt
  if delay > 30 then
    delay = 30
  end
  return delay
end

--- Whether another restart is allowed.
-- @param attempt number the attempt number
-- @return boolean
function RestartPolicy:can_restart(attempt)
  return attempt <= self.max_retries
end

M.RestartPolicy = RestartPolicy
return M
