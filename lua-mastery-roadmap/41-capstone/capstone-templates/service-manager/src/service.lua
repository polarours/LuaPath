-- service.lua
local M = {}

local Service = {}
Service.__index = Service

function Service.new(config)
  -- Validate: name, command must be strings
  -- Default restart policy: {max_retries=5, backoff="exponential"}
  -- TODO
end

function Service:is_running()
  -- TODO: track state
end

M.Service = Service
return M
