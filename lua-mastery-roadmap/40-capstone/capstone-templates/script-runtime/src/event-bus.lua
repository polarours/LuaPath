-- event-bus.lua
-- Publish/subscribe with topic wildcards.
local M = {}

local Bus = {}
Bus.__index = Bus

--- Whether a topic pattern matches a concrete topic.
-- A pattern that contains "*" matches every topic starting with the text
-- in front of the star, so "plugin.*" matches "plugin.started" and
-- "plugin.stopped". A pattern without a star has to match exactly.
-- @param pattern string the subscription pattern
-- @param topic string the topic being emitted
-- @return boolean
local function matches(pattern, topic)
  if pattern == topic then return true end
  local prefix = pattern:match("^(.-)%*")
  if prefix and topic:sub(1, #prefix) == prefix then return true end
  return false
end

function Bus.new()
  return setmetatable({ _subscribers = {} }, Bus)
end

--- Subscribe to a topic; handler receives payload
-- topic pattern: "plugin.*" matches "plugin.started", "plugin.stopped"
-- @param topic string the topic pattern
-- @param handler function called with the payload
function Bus:subscribe(topic, handler)
  self._subscribers[#self._subscribers + 1] = { topic = topic, handler = handler }
end

--- Remove a subscription.
-- @param topic string the topic pattern
-- @param handler function the handler to remove; nil removes every handler
--   subscribed to the topic
function Bus:unsubscribe(topic, handler)
  for i = #self._subscribers, 1, -1 do
    local entry = self._subscribers[i]
    if entry.topic == topic and (handler == nil or entry.handler == handler) then
      table.remove(self._subscribers, i)
    end
  end
end

--- Emit: call all matching handlers; errors in one handler don't stop others
-- @param topic string the topic
-- @param payload any the payload handed to the handlers
-- @return number the number of handlers that raised an error
function Bus:emit(topic, payload)
  local failures = 0
  -- Iterate over a copy: a handler is allowed to subscribe or unsubscribe.
  local subscribers = {}
  for i, entry in ipairs(self._subscribers) do
    subscribers[i] = entry
  end
  for _, entry in ipairs(subscribers) do
    if matches(entry.topic, topic) then
      local ok = pcall(entry.handler, payload)
      if not ok then
        failures = failures + 1
      end
    end
  end
  return failures
end

M.matches = matches
M.Bus = Bus
M.new = Bus.new
return M
