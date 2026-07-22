-- Example 23: Event System
-- Chapter: 11-event-system
-- Difficulty: Advanced
-- Lua Version: 5.1+

-- Demonstrates: publish/subscribe, event emitter, handler management

local function main()
  print("=== Event System Demo ===\n")

  -- Event emitter
  local EventEmitter = {}
  EventEmitter.__index = EventEmitter

  function EventEmitter.new()
    return setmetatable({handlers = {}}, EventEmitter)
  end

  function EventEmitter:on(event, handler)
    if not self.handlers[event] then
      self.handlers[event] = {}
    end
    self.handlers[event][#self.handlers[event] + 1] = handler
    return function()
      for i, h in ipairs(self.handlers[event]) do
        if h == handler then
          table.remove(self.handlers[event], i)
          return
        end
      end
    end
  end

  function EventEmitter:emit(event, ...)
    local handlers = self.handlers[event] or {}
    for _, handler in ipairs(handlers) do
      handler(...)
    end
  end

  -- Usage
  local emitter = EventEmitter.new()

  emitter:on("data", function(chunk)
    print("Received:", chunk)
  end)

  emitter:on("data", function(chunk)
    print("Processing:", chunk:upper())
  end)

  local unsub = emitter:on("done", function()
    print("Done!")
  end)

  print("Emitting 'data':")
  emitter:emit("data", "hello")

  print("\nEmitting 'done':")
  emitter:emit("done")

  print("\nUnsubscribe and emit again:")
  unsub()
  emitter:emit("done")  -- Nothing printed

  print("\n=== Done ===")
end

main()
