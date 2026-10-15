-- manager.lua
local M = {}

local Manager = {}
Manager.__index = Manager

function Manager.new(services)
  -- services: list of Service objects
  -- TODO: track start time, restart counts
end

function Manager:start_all()
  -- Start each service, return { [name] = status }
  -- TODO
end

function Manager:stop_all()
  -- Stop all services gracefully
  -- TODO
end

function Manager:restart(service_name)
  -- Stop and restart one service, apply backoff
  -- TODO
end

M.Manager = Manager
return M
