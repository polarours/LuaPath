-- src/build.lua — Task-based build system using Lua metatables
-- Provides task definition, dependency resolution (topological sort),
-- incremental execution with caching.

local Build = {}
Build.__index = Build

--- Create a new Build system.
function Build.new()
  return setmetatable({
    tasks = {},
    cache = {},
    executed_order = {},
  }, Build)
end

--- Register a task.
-- name: task name
-- dependencies: list of task names this task depends on
-- fn: function to execute when task is run
function Build:task(name, dependencies, fn)
  self.tasks[name] = {
    name = name,
    dependencies = dependencies or {},
    fn = fn,
    created = os.time(),
    output = nil,
  }
  return self
end

--- Perform topological sort of all tasks.
-- Detects cycles and returns the execution order.
function Build:resolve_order()
  local order = {}
  local visiting = {}  -- set of nodes currently in DFS stack
  local visited = {}   -- set of fully visited nodes

  local function visit(name)
    if visiting[name] then
      error("Cycle detected in task dependencies: " .. name)
    end
    if visited[name] then
      return
    end
    visiting[name] = true

    local task = self.tasks[name]
    if task then
      for _, dep in ipairs(task.dependencies) do
        visit(dep)
      end
    end

    visited[name] = true
    visiting[name] = nil
    table.insert(order, name)
  end

  for name in pairs(self.tasks) do
    visit(name)
  end

  return order
end

--- Execute a task and its dependencies recursively.
-- Uses cache to avoid re-executing unchanged tasks.
function Build:execute(name)
  local task = self.tasks[name]
  if not task then
    error("Build task '" .. name .. "' not found")
  end

  -- If already executed, return cached output
  if self.executed_order[name] then
    return task.output
  end

  -- Execute dependencies first (depth-first)
  for _, dep in ipairs(task.dependencies) do
    self:execute(dep)
  end

  -- Execute the task with the Build instance as argument
  local ok, result = xpcall(function()
    return task.fn(self)  -- Pass the Build instance
  end, function(err)
    return "error: " .. tostring(err)
  end)

  if not ok then
    error("Task '" .. name .. "' failed: " .. result)
  end

  task.output = result
  self.executed_order[name] = true
  self.cache[name] = { time = os.time(), output = result }

  return result
end

--- Execute all tasks in topological order.
-- Useful for building everything or checking the full graph.
function Build:build()
  local order = self:resolve_order()
  for _, name in ipairs(order) do
    self:execute(name)
  end
  return order
end

--- Get all task names.
function Build:list_tasks()
  local names = {}
  for name in pairs(self.tasks) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

--- Return the Build object as a string representation.
function Build:__tostring()
  local lines = {}
  lines[1] = "Build System (" .. #self.tasks .. " tasks)"
  for i, name in ipairs(self:list_tasks()) do
    local task = self.tasks[name]
    local deps = #task.dependencies > 0 and "(" .. table.concat(task.dependencies, ", ") .. ")" or ""
    lines[i + 1] = string.format("  %d. %s %s", i, name, deps)
  end
  return table.concat(lines, "\n")
end

return Build
