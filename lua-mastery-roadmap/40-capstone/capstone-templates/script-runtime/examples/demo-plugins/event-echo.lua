-- event-echo.lua
-- Plugin that echoes the events it receives.
--
-- A plugin is a module with an `on_init`, `on_tick` and `on_destroy` hook.
-- The host hands the plugin its configuration in `on_init`; when that
-- configuration carries the runtime's event bus, the plugin subscribes to a
-- topic and echoes every payload it is sent.
local M = {}

local bus = nil
local topic = nil
local seen = 0

--- Called once when the plugin is loaded.
-- @param config table the host configuration; `config.bus` is the event bus
-- and `config.topic` the topic to subscribe to
function M.on_init(config)
  config = config or {}
  bus = config.bus
  topic = config.topic or "app.*"

  if bus and bus.subscribe then
    bus:subscribe(topic, function(payload)
      M.on_event(payload)
    end)
    print("[event-echo] subscribed to " .. topic)
  else
    print("[event-echo] no event bus in the configuration")
  end
end

--- Handle one event.
-- @param payload any the event payload
function M.on_event(payload)
  seen = seen + 1
  print(string.format("[event-echo] #%d %s", seen, tostring(payload)))
end

--- Called every frame.
-- @param dt number seconds since the last tick
function M.on_tick(dt)
  -- The plugin is event driven: there is nothing to do per frame.
end

--- Called when the plugin is unloaded.
function M.on_destroy()
  print(string.format("[event-echo] destroyed after %d events", seen))
end

M.name = "event-echo"
M.version = "1.0.0"
return M
