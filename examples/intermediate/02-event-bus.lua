-- Example 2: Event Bus with Unsubscribe
-- Chapter: 13-patterns
-- Difficulty: Intermediate
-- Lua Version: 5.1+
--
-- Demonstrates: event system, weak tables, subscription management

local EventBus = {}
EventBus.__index = EventBus

--- Create a new event bus
-- @return event bus instance
function EventBus:new()
  local self = setmetatable({}, EventBus)
  self.handlers = {}
  self.subscriptions = {}  -- Track subscriptions for cleanup
  return self
end

--- Subscribe to an event
-- @param event event name
-- @param callback function to call
-- @return subscription id for unsubscribing
function EventBus:on(event, callback)
  if not self.handlers[event] then
    self.handlers[event] = {}
  end
  
  local sub_id = tostring(callback) .. tostring(os.time())
  self.handlers[event][sub_id] = callback
  self.subscriptions[sub_id] = event
  
  return sub_id
end

--- Subscribe with weak reference (auto-cleanup)
-- @param event event name
-- @param callback function to call
-- @return subscription id
function EventBus:on_weak(event, callback)
  if not self.handlers[event] then
    self.handlers[event] = setmetatable({}, {__mode = "v"})
  end
  
  local sub_id = tostring(callback) .. tostring(os.time())
  self.handlers[event][sub_id] = callback
  self.subscriptions[sub_id] = event
  
  return sub_id
end

--- Unsubscribe from an event
-- @param sub_id subscription id from on()
-- @return true if unsubscribed, false if not found
function EventBus:off(sub_id)
  local event = self.subscriptions[sub_id]
  if not event then
    return false
  end
  
  if self.handlers[event] then
    self.handlers[event][sub_id] = nil
  end
  self.subscriptions[sub_id] = nil
  
  return true
end

--- Emit an event
-- @param event event name
-- @param ... arguments to pass to handlers
function EventBus:emit(event, ...)
  local handlers = self.handlers[event]
  if not handlers then
    return
  end
  
  -- Copy handlers to avoid issues with modifications during iteration
  local to_call = {}
  for sub_id, handler in pairs(handlers) do
    to_call[sub_id] = handler
  end
  
  for sub_id, handler in pairs(to_call) do
    -- Check if handler is still valid (for weak tables)
    if type(handler) == "function" then
      local success, err = pcall(handler, ...)
      if not success then
        print(string.format("Event handler error (%s): %s", event, err))
      end
    end
  end
end

--- Get subscription count for an event
-- @param event event name
-- @return number of subscribers
function EventBus:count(event)
  if not self.handlers[event] then
    return 0
  end
  
  local count = 0
  for _, _ in pairs(self.handlers[event]) do
    count = count + 1
  end
  return count
end

--- Clear all subscriptions
function EventBus:clear()
  self.handlers = {}
  self.subscriptions = {}
end

-- Test
print("Event Bus Test")
print("==============")

local bus = EventBus:new()

-- Subscribe
local sub1 = bus:on("update", function(dt)
  print(string.format("  Handler 1: update dt=%.3f", dt))
end)

local sub2 = bus:on("update", function(dt)
  print(string.format("  Handler 2: update dt=%.3f", dt))
end)

print(string.format("Subscribers to 'update': %d", bus:count("update")))

-- Emit
print("\nEmitting 'update' event:")
bus:emit("update", 0.016)

-- Unsubscribe
print(string.format("\nUnsubscribing handler 1: %s", bus:off(sub1)))
print(string.format("Subscribers to 'update': %d", bus:count("update")))

-- Emit again
print("\nEmitting 'update' event after unsubscribe:")
bus:emit("update", 0.032)

-- Test error handling
print("\nTesting error handling:")
bus:on("error_test", function()
  error("Intentional error!")
end)

bus:emit("error_test")  -- Should not crash
print("Event bus survived error!")

-- Test weak references
print("\nTesting weak references:")
local weak_handler = function() print("  Weak handler called") end
bus:on_weak("weak_event", weak_handler)
print(string.format("Subscribers to 'weak_event': %d", bus:count("weak_event")))

-- After garbage collection, weak reference may be collected
collectgarbage("collect")
print("After collectgarbage() - weak ref may be cleared")

print("\n✓ Event bus tests completed!")
