-- Example 7: Weak Tables
-- Chapter: 09-advanced
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Demonstrates: __mode = 'k'/'v'/'kv', object caching, finalizers

--- Create a cache with weak values
-- Entries can be garbage collected when no other references exist
-- @return cache table and stats function
local function create_weak_cache()
  local cache = {}
  setmetatable(cache, {__mode = "v"})

  local stats = function()
    local count = 0
    for _ in pairs(cache) do count = count + 1 end
    return count
  end

  return cache, stats
end

--- Create an object cache that deduplicates by ID
-- Uses weak values so unused objects can be collected
-- @return cache with get/put methods
local function create_object_cache()
  local cache = {}
  setmetatable(cache, {__mode = "v"})

  local api = {}

  function api.get(id)
    return cache[id]
  end

  function api.put(id, obj)
    cache[id] = obj
  end

  function api.size()
    local count = 0
    for _ in pairs(cache) do count = count + 1 end
    return count
  end

  return api
end

--- Simple observer pattern with weak references
-- Observers are weakly referenced, so they can be collected
-- @return subject table with attach/notify methods
local function create_subject()
  local observers = {}
  setmetatable(observers, {__mode = "k"})

  local subject = {}

  function subject:attach(observer)
    observers[observer] = true
    return function()
      observers[observer] = nil
    end
  end

  function subject:notify(event)
    for observer in pairs(observers) do
      if observer.on_event then
        observer:on_event(event)
      end
    end
  end

  function subject:observer_count()
    local count = 0
    for _ in pairs(observers) do count = count + 1 end
    return count
  end

  return subject
end

--- Demonstrate key weak tables
-- Keys can be garbage collected
local function demo_weak_keys()
  print("1. Weak Keys:")
  local weak_keys = {}
  setmetatable(weak_keys, {__mode = "k"})

  -- Create temporary table as key
  local key1 = {name = "first"}
  weak_keys[key1] = "value1"

  local key2 = {name = "second"}
  weak_keys[key2] = "value2"

  print(string.format("  Before GC: %d entries", #weak_keys))
  print(string.format("  key1 exists: %s", weak_keys[key1] ~= nil))
  print(string.format("  key2 exists: %s", weak_keys[key2] ~= nil))

  -- Allow key1 to be collected
  key1 = nil
  collectgarbage("collect")

  print(string.format("  After GC: %d entries", #weak_keys))
  print(string.format("  key1 exists: %s", weak_keys[{name = "first"}] ~= nil))
  print(string.format("  key2 exists: %s", weak_keys[key2] ~= nil))
end

--- Demonstrate value weak tables (caching)
local function demo_weak_values()
  print("\n2. Weak Values (Object Cache):")

  local cache, stats = create_weak_cache()

  -- Create objects
  local obj_a = {data = "A"}
  local obj_b = {data = "B"}
  local obj_c = {data = "C"}

  cache["a"] = obj_a
  cache["b"] = obj_b
  cache["c"] = obj_c

  print(string.format("  Before GC: %d cached objects", stats()))

  -- Release references to some objects
  obj_a = nil
  obj_b = nil
  collectgarbage("collect")

  print(string.format("  After GC: %d cached objects", stats()))
  print(string.format("  obj_c still in cache: %s", cache["c"] ~= nil))
end

--- Demonstrate object deduplication
local function demo_object_dedup()
  print("\n3. Object Deduplication:")

  local cache = create_object_cache()
  local id_counter = 0

  local function create_object(value)
    id_counter = id_counter + 1
    -- Check cache first
    local cached = cache.get(id_counter)
    if cached then
      print(string.format("  Reusing cached object %d", id_counter))
      return cached
    end
    -- Create new object
    local obj = {id = id_counter, value = value}
    cache.put(id_counter, obj)
    print(string.format("  Created new object %d", id_counter))
    return obj
  end

  -- Create some objects
  local obj1 = create_object("first")
  local obj2 = create_object("second")
  print(string.format("  Cache size: %d", cache.size()))

  -- Simulate some work
  collectgarbage("collect")
  print(string.format("  Cache size after GC: %d", cache.size()))

  -- Objects are still referenced, so they stay
  print(string.format("  obj1 still valid: %s", obj1 ~= nil))
  print(string.format("  obj2 still valid: %s", obj2 ~= nil))
end

--- Demonstrate observer pattern with weak refs
local function demo_observer_pattern()
  print("\n4. Observer Pattern with Weak References:")

  local subject = create_subject()

  -- Create observers
  local observer1 = {name = "Observer1"}
  local observer2 = {name = "Observer2"}

  function observer1:on_event(event)
    print(string.format("    [%s] received: %s", self.name, event))
  end

  function observer2:on_event(event)
    print(string.format("    [%s] received: %s", self.name, event))
  end

  -- Attach observers
  local detach1 = subject:attach(observer1)
  local detach2 = subject:attach(observer2)
  print(string.format("  Attached observers: %d", subject:observer_count()))

  -- Notify
  subject:notify("event1")

  -- Detach one observer
  detach1()
  print(string.format("  After detach: %d observers", subject:observer_count()))

  -- Notify again
  subject:notify("event2")

  -- Weak reference allows observer to be collected
  observer2 = nil
  collectgarbage("collect")
  print(string.format("  After GC: %d observers", subject:observer_count()))
end

--- Main function demonstrating weak tables
local function main()
  print("=== Weak Tables ===\n")

  demo_weak_keys()
  demo_weak_values()
  demo_object_dedup()
  demo_observer_pattern()

  -- 5. Finalizers (note: not supported in Lua 5.1)
  print("\n5. Finalizer Note:")
  print("  Finalizers (__gc metamethod) are only available in Lua 5.2+")
  print("  In Lua 5.1, use debug.setmetatable with __gc for similar behavior")

  print("\n✓ Weak table examples completed!")
end

-- Run the demonstration
main()
