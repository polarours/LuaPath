-- event-bus.lua
local M = {}

local Bus = {}
Bus.__index = Bus

function Bus.new()
  return setmetatable({ _subscribers = {} }, Bus)
end

-- Subscribe to a topic; handler receives payload
-- topic pattern: "plugin.*" matches "plugin.started", "plugin.stopped"
function Bus:subscribe(topic, handler)
  -- TODO
end

function Bus:unsubscribe(topic, handler)
  -- TODO
end

-- Emit: call all matching handlers; errors in one handler don't stop others
function Bus:emit(topic, payload)
  -- TODO: for each subscriber matching topic:
  --   pcall(subscriber.handler, payload)
end

M.Bus = Bus
M.new = Bus.new
return M
