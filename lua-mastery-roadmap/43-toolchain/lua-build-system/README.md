# Stage 43.1: Lua Build System

**Level**: Advanced  
**Description**: Build a task-based build system using Lua metatables and dependency graphs. Learn to write Lua tasks that can be executed in dependency order, with proper caching and incremental build support.

## Prerequisites

- Stage 05 — Metatables
- Stage 03 — Functions (closures)
- Stage 12 — Performance

## Project Structure

```
43-toolchain/lua-build-system/
├── README.md
├── README.zh-CN.md
├── src/
│   └── build.lua          — Core build system implementation
├── examples/
│   └── simple.lua         — Example build script
└── tests/
    └── build_test.lua     — Build system correctness tests
```

## Implementation

The build system should support:

1. **Task definition** — Define tasks with dependencies using metatables
2. **Dependency resolution** — Topological sort of task dependencies
3. **Incremental builds** — Skip tasks whose inputs haven't changed
4. **Caching** — Store task outputs with timestamps

### Core Module (`src/build.lua`)

```lua
local Build = {}
Build.__index = Build

function Build.new()
  return setmetatable({
    tasks = {},
    executed = {},
    cache = {},
  }, Build)
end

function Build:task(name, dependencies, fn)
  self.tasks[name] = {
    name = name,
    dependencies = dependencies or {},
    fn = fn,
    timestamp = os.time(),
    output = nil,
  }
  return self
end

function Build:resolve_order(name)
  -- Topological sort with cycle detection
  local order = {}
  local visiting = {}
  local visited = {}

  local function visit(name)
    if visiting[name] then error("Cycle detected") end
    if visited[name] then return end
    visiting[name] = true
    for _, dep in ipairs(self.tasks[name].dependencies or {}) do
      visit(dep)
    end
    visited[name] = true
    table.insert(order, name)
    visiting[name] = nil
  end

  for name in pairs(self.tasks) do
    visit(name)
  end

  return order
end

function Build:execute(name)
  local task = self.tasks[name]
  if not task then error("Unknown task: " .. name) end

  -- Check if task needs to be re-executed (cache check)
  local cached = self.cache[name]
  if cached and os.time() - cached.time < 3600 then
    -- Optimistic cache: skip if within reasonable time
    -- In production, check input file timestamps
  end

  -- Execute dependencies first
  for _, dep in ipairs(task.dependencies or {}) do
    self:execute(dep)
  end

  -- Execute task
  local ok, result = pcall(task.fn, self)
  if not ok then error("Task " .. name .. " failed: " .. result) end
  task.output = result
  self.cache[name] = { time = os.time(), output = result }
  return result
end

return Build
```

### Example (`examples/simple.lua`)

```lua
local Build = require("src.build")

local b = Build.new()

b:task("clean", {}, function()
  print("Cleaning...")
  return true
end)

b:task("compile", {"clean"}, function()
  print("Compiling...")
  return { files = {"main.o"} }
end)

b:task("link", {"compile"}, function()
  print("Linking...")
  return { exe = "app" }
end)

print("Result: " .. b:execute("link")[1])
```

## Time Estimate

8–12 hours
