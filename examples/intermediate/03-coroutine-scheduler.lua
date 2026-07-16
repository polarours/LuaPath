-- Example 3: Coroutine-based Task Scheduler
-- Chapter: 08-coroutines
-- Difficulty: Intermediate
-- Lua Version: 5.1+
--
-- Demonstrates: coroutine creation, scheduling, cooperative multitasking

local Scheduler = {}
Scheduler.__index = Scheduler

--- Create a new scheduler
-- @return scheduler instance
function Scheduler:new()
  local self = setmetatable({}, Scheduler)
  self.tasks = {}
  self.running = false
  return self
end

--- Spawn a new task
-- @param fn function to run as coroutine
-- @param ... arguments to pass to the function
-- @return coroutine reference
function Scheduler:spawn(fn, ...)
  local co = coroutine.create(fn)
  table.insert(self.tasks, {
    coroutine = co,
    status = "ready",
    wait_until = 0,
  })
  return co
end

--- Wait for specified time (yields)
-- @param seconds time to wait
function Scheduler:wait(seconds)
  coroutine.yield("wait", seconds)
end

--- Run the scheduler
-- @param duration how long to run (0 = forever)
function Scheduler:run(duration)
  self.running = true
  local start_time = os.time()
  
  while self.running and (#self.tasks > 0) do
    -- Check duration limit
    if duration > 0 and (os.time() - start_time) >= duration then
      break
    end
    
    local current_time = os.time()
    local i = 1
    
    while i <= #self.tasks do
      local task = self.tasks[i]
      
      -- Skip tasks that are waiting
      if task.wait_until > current_time then
        i = i + 1
        goto continue
      end
      
      -- Resume coroutine
      local status = coroutine.status(task.coroutine)
      
      if status == "suspended" then
        local success, result, param = coroutine.resume(task.coroutine)
        
        if not success then
          print(string.format("Task error: %s", param))
          table.remove(self.tasks, i)
          goto continue
        end
        
        -- Handle yield commands
        if result == "wait" then
          task.wait_until = current_time + (param or 0)
        end
        
        -- Check if coroutine finished
        if coroutine.status(task.coroutine) == "dead" then
          table.remove(self.tasks, i)
          goto continue
        end
        
      elseif status == "dead" then
        table.remove(self.tasks, i)
        goto continue
      end
      
      i = i + 1
      
      ::continue::
    end
    
    -- Small yield to avoid blocking
    if #self.tasks > 0 then
      -- In real implementation, use proper timing
    end
  end
end

--- Stop the scheduler
function Scheduler:stop()
  self.running = false
end

--- Get task count
-- @return number of active tasks
function Scheduler:task_count()
  return #self.tasks
end

-- Test
print("Coroutine Task Scheduler")
print("========================")

local scheduler = Scheduler:new()

-- Spawn tasks
scheduler:spawn(function()
  for i = 1, 3 do
    print(string.format("  Task A: iteration %d", i))
    scheduler:wait(1)
  end
  print("  Task A: complete")
end)

scheduler:spawn(function()
  for i = 1, 5 do
    print(string.format("  Task B: iteration %d", i))
    scheduler:wait(0.5)
  end
  print("  Task B: complete")
end)

scheduler:spawn(function()
  print("  Task C: starting")
  scheduler:wait(2)
  print("  Task C: done")
end)

print(string.format("Tasks spawned: %d", scheduler:task_count()))
print("\nRunning scheduler (simulated):")

-- Note: In this test, we're not using real timing
-- Real implementation would use proper delta time
scheduler:run(0)

print("\n✓ Scheduler test completed!")
