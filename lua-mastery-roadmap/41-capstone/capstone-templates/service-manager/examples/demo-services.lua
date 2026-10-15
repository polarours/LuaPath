-- demo-services.lua
-- Simulated service manager demo (no real processes)
local service        = require "src.service"
local manager        = require "src.manager"
local restart_policy = require "src.restart-policy"
local logger         = require "src.logger"
local dashboard      = require "src.dashboard"

local log = logger.new("/tmp/service-manager.log")
log:info("demo", "starting service manager")

local svcs = {
  service.Service.new {
    name = "web", command = "echo web", restart = {max_retries=5, backoff="exponential"}
  },
  service.Service.new {
    name = "cache", command = "echo cache", restart = {max_retries=3, backoff="linear", interval=2}
  }
}

local mgr = manager.Manager.new(svcs)
local status = mgr:start_all()

for name, s in pairs(status) do
  print(name, s.running and "running" or "stopped")
end

-- Show dashboard
for name, info in pairs(dashboard.all(mgr)) do
  print(name, "restarts:", info.restart_count)
end

log:info("demo", "service manager initialized")
print("demo complete")
