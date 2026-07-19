-- Example 16: Memory Profiling
-- Chapter: 12-performance
-- Difficulty: Advanced
-- Lua Version: 5.1+
-- Demonstrates memory tracking, allocation analysis, and optimization techniques

local MemoryProfiler = {}
MemoryProfiler.__index = MemoryProfiler

function MemoryProfiler.new()
  local self = setmetatable({}, MemoryProfiler)
  self.snapshots = {}
  self.allocations = {}
  return self
end

-- Take a memory snapshot
function MemoryProfiler:snapshot(label)
  collectgarbage("collect")
  collectgarbage("collect")
  
  local mem = collectgarbage("count") * 1024  -- Convert to bytes
  table.insert(self.snapshots, {
    label = label,
    memory = mem,
    time = os.clock(),
    objects = self:count_objects(),
  })
  return mem
end

-- Count objects by type
function MemoryProfiler:count_objects()
  local counts = {}
  local seen = {}
  
  local function scan(val)
    if type(val) ~= "table" or seen[val] then return end
    seen[val] = true
    
    local t = type(val)
    counts[t] = (counts[t] or 0) + 1
    
    for k, v in pairs(val) do
      if type(v) == "table" then
        scan(v)
      end
    end
  end
  
  -- Scan known roots
  scan(_G)
  scan(getmetatable(getmetatable({})))
  
  return counts
end

-- Track allocations in a function
function MemoryProfiler:track(name, fn)
  collectgarbage("collect")
  local before = collectgarbage("count") * 1024
  
  local results = table.pack(fn())
  
  collectgarbage("collect")
  local after = collectgarbage("count") * 1024
  
  local allocation = after - before
  table.insert(self.allocations, {
    name = name,
    allocation = allocation,
    time = os.clock(),
  })
  
  return table.unpack(results, 1, results.n)
end

-- Print summary
function MemoryProfiler:summary()
  print("\n=== Memory Profile Summary ===\n")
  
  -- Snapshots
  print("Snapshots:")
  for i, snap in ipairs(self.snapshots) do
    if i > 1 then
      local delta = snap.memory - self.snapshots[i-1].memory
      print(string.format("  %s: %.2f KB (delta: %.2f KB)", 
        snap.label, snap.memory / 1024, delta / 1024))
    else
      print(string.format("  %s: %.2f KB", snap.label, snap.memory / 1024))
    end
  end
  
  -- Allocations
  print("\nAllocations:")
  local total = 0
  for _, alloc in ipairs(self.allocations) do
    print(string.format("  %s: %.2f KB", alloc.name, alloc.allocation / 1024))
    total = total + alloc.allocation
  end
  print(string.format("  Total: %.2f KB", total / 1024))
  
  -- Object counts
  print("\nObject Counts:")
  for i, snap in ipairs(self.snapshots) do
    if i == #self.snapshots then
      for t, count in pairs(snap.objects) do
        print(string.format("  %s: %d", t, count))
      end
    end
  end
end

-- Main demonstration
local function main()
  print("=== Memory Profiling Example ===\n")
  
  local profiler = MemoryProfiler.new()
  
  -- Baseline
  profiler:snapshot("baseline")
  
  -- Allocate some tables
  profiler:track("allocate tables", function()
    local t = {}
    for i = 1, 1000 do
      t[i] = {id = i, data = string.rep("x", 100)}
    end
    return t
  end)
  
  profiler:snapshot("after tables")
  
  -- Create closures
  profiler:track("create closures", function()
    local closures = {}
    for i = 1, 500 do
      local x = i
      closures[i] = function() return x end
    end
    return closures
  end)
  
  profiler:snapshot("after closures")
  
  -- Create strings
  profiler:track("create strings", function()
    local strings = {}
    for i = 1, 1000 do
      strings[i] = string.format("item_%d", i)
    end
    return strings
  end)
  
  profiler:snapshot("after strings")
  
  -- Print summary
  profiler:summary()
  
  -- Demonstrate optimization
  print("\n=== Optimization Techniques ===\n")
  
  -- Technique 1: Table reuse
  print("1. Table Reuse:")
  local t = {}
  profiler:track("reuse table", function()
    for i = 1, 1000 do
      t.x = i
      t.y = i * 2
    end
  end)
  
  -- Technique 2: String building
  print("2. String Building:")
  profiler:track("string concat", function()
    local result = ""
    for i = 1, 100 do
      result = result .. tostring(i)
    end
    return result
  end)
  
  profiler:track("table.concat", function()
    local parts = {}
    for i = 1, 100 do
      parts[i] = tostring(i)
    end
    return table.concat(parts)
  end)
  
  -- Technique 3: Weak references
  print("3. Weak References:")
  local cache = setmetatable({}, {__mode = "k"})
  profiler:track("weak cache", function()
    for i = 1, 1000 do
      local key = {id = i}
      cache[key] = string.rep("data", 100)
    end
  end)
  
  -- Final summary
  profiler:snapshot("final")
  profiler:summary()
  
  print("\n=== Done ===")
end

main()
