-- Example 14: Weak References
-- Chapter: 05-gc-and-metatables
-- Difficulty: Intermediate
-- Lua Version: 5.1+
--
-- Demonstrates: __mode='k', __mode='v', __mode='kv', weak tables, GC interaction

--- Weak keys: table entries die when the key has no other references
local function demo_weak_keys()
  print("=== Weak Keys (__mode='k') ===")

  local weak_keys = setmetatable({}, {__mode = "k"})

  do
    local key_obj = {id = "session_1"}
    weak_keys[key_obj] = "some data"
    print("  With reference: entry exists = " .. tostring(weak_keys[key_obj] ~= nil))
  end
  collectgarbage("collect")
  print("  After GC (key collected): entry exists = " .. tostring(next(weak_keys) ~= nil))

  -- Persistent keys survive
  local persistent = {id = "session_2"}
  weak_keys[persistent] = "kept data"
  collectgarbage("collect")
  print("  Persistent key still alive: " .. tostring(weak_keys[persistent] ~= nil))
end

--- Weak values: entries die when the value has no other references
local function demo_weak_values()
  print("\n=== Weak Values (__mode='v') ===")

  local weak_values = setmetatable({}, {__mode = "v"})

  -- Store objects with weak values
  weak_values["cache_a"] = {data = "short lived"}
  weak_values["cache_b"] = {data = "also short lived"}

  print("  Before GC: cache_a exists = " .. tostring(weak_values["cache_a"] ~= nil))
  print("  Before GC: cache_b exists = " .. tostring(weak_values["cache_b"] ~= nil))

  -- Drop our only external references (if any)
  collectgarbage("collect")
  collectgarbage("collect")

  print("  After GC: cache_a exists = " .. tostring(weak_values["cache_a"] ~= nil))
  print("  After GC: cache_b exists = " .. tostring(weak_values["cache_b"] ~= nil))
end

--- Weak keys and values: both sides can be collected
local function demo_weak_kv()
  print("\n=== Weak Keys + Values (__mode='kv') ===")

  local weak_kv = setmetatable({}, {__mode = "kv"})

  do
    local key = {name = "temp_key"}
    local val = {name = "temp_val"}
    weak_kv[key] = val
    print("  Before GC: entry = " .. tostring(weak_kv[key] ~= nil))
  end

  collectgarbage("collect")
  print("  After GC: entry = " .. tostring(next(weak_kv) ~= nil))
end

--- Memory-sensitive cache using weak values
local function demo_cache_pattern()
  print("\n=== Memory-Sensitive Cache ===")

  local Cache = {}
  Cache.__index = Cache

  function Cache.new(max_size)
    local self = setmetatable({}, Cache)
    self._store = setmetatable({}, {__mode = "v"})
    self._count = 0
    self._max = max_size
    return self
  end

  function Cache:get(key)
    return self._store[key]
  end

  function Cache:put(key, value)
    if self._store[key] == nil then
      self._count = self._count + 1
    end
    self._store[key] = value
  end

  function Cache:stats()
    local alive = 0
    for _ in pairs(self._store) do alive = alive + 1 end
    return alive, self._count
  end

  local cache = Cache.new(100)

  -- Populate cache
  for i = 1, 5 do
    cache:put("key_" .. i, {value = i * 100})
  end
  local alive, total = cache:stats()
  print("  After insert: alive=" .. alive .. ", total_inserted=" .. total)

  -- Simulate losing references to cached objects
  collectgarbage("collect")
  alive, total = cache:stats()
  print("  After GC: alive=" .. alive .. ", total_inserted=" .. total)

  -- Keep one reference alive
  local kept = cache:get("key_3")
  collectgarbage("collect")
  alive, total = cache:stats()
  print("  With one ref held: alive=" .. alive)
end

--- Observer pattern: weak table prevents memory leaks
local function demo_observer_pattern()
  print("\n=== Observer Cleanup ===")

  local Signal = {}
  Signal.__index = Signal

  function Signal.new()
    return setmetatable({_listeners = setmetatable({}, {__mode = "k"})}, Signal)
  end

  function Signal:on(observer, callback)
    self._listeners[observer] = callback
  end

  function Signal:emit(event)
    for observer, callback in pairs(self._listeners) do
      callback(observer, event)
    end
    return self:count()
  end

  function Signal:count()
    local n = 0
    for _ in pairs(self._listeners) do n = n + 1 end
    return n
  end

  local signal = Signal.new()

  -- Create observers
  do
    local a = setmetatable({_name = "observer_A"}, {__index = {handle = function(self, e) print("    A got: " .. e) end}})
    local b = setmetatable({_name = "observer_B"}, {__index = {handle = function(self, e) print("    B got: " .. e) end}})
    signal:on(a, a.handle)
    signal:on(b, b.handle)

    print("  Before GC: " .. signal:emit("hello") .. " listeners")
  end

  collectgarbage("collect")
  print("  After GC: " .. signal:emit("world") .. " listeners")
  print("  Dead observers are silently removed from weak table")
end

--- Finalizer pattern using __gc metamethod
local function demo_finalizer()
  print("\n=== Finalizer Pattern ===")

  local Tracker = {}
  Tracker.__index = Tracker
  Tracker._count = 0

  function Tracker.new(name)
    Tracker._count = Tracker._count + 1
    local self = setmetatable({_name = name}, Tracker)
    return self
  end

  function Tracker:__gc()
    print("  Finalizer called for: " .. self._name)
  end

  -- Create and discard objects
  do
    local t1 = Tracker.new("resource_A")
    local t2 = Tracker.new("resource_B")
    print("  Created tracker objects")
  end

  collectgarbage("collect")
  print("  GC cycle complete")
end

--- Practical: weak-keyed memoization
local function demo_memoization()
  print("\n=== Weak-Key Memoization ===")

  local memo = setmetatable({}, {__mode = "k"})

  local function expensive_compute(obj)
    -- Check memo first
    local cached = memo[obj]
    if cached then
      print("    Cache hit for " .. tostring(obj.id))
      return cached
    end

    -- Simulate expensive work
    local result = obj.id .. "_computed"
    memo[obj] = result
    print("    Computed and cached: " .. result)
    return result
  end

  local a = {id = "obj_A"}
  local b = {id = "obj_B"}

  print("  First call:")
  expensive_compute(a)
  expensive_compute(b)

  print("  Second call (cached):")
  expensive_compute(a)

  print("  After creating fresh reference:")
  local c = {id = "obj_A"}
  expensive_compute(c)

  print("  Key insight: different objects with same data must be computed separately")
end

function main()
  print("Weak References Examples")
  print("=======================")

  demo_weak_keys()
  demo_weak_values()
  demo_weak_kv()
  demo_cache_pattern()
  demo_observer_pattern()
  demo_finalizer()
  demo_memoization()

  print("\nKey takeaways:")
  print("  - __mode='k': weak keys (entries die when keys are collected)")
  print("  - __mode='v': weak values (entries die when values are collected)")
  print("  - __mode='kv': both sides weak")
  print("  - Weak tables prevent memory leaks in caches and observer patterns")
  print("  - __gc metamethod provides finalization on collection")
end

main()
