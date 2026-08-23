-- Example 03: Cooperative Task Scheduler
-- Project: 03-task-scheduler
-- Difficulty: Intermediate-Advanced
-- Lua Version: 5.1+
--
-- Demonstrates: coroutines, cooperative multitasking, round-robin scheduling,
--               yield-based sleep, task cancellation, timeout management

local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler:new()
  local self = setmetatable({}, Scheduler)
  self.tasks = {}
  self.next_id = 1
  self.running = false
  return self
end

function Scheduler:spawn(fn)
  local id = self.next_id
  self.next_id = self.next_id + 1
  self.tasks[id] = {
    co = coroutine.create(fn),
    wake_time = 0,
    cancelled = false,
  }
  return id
end

function Scheduler:sleep(seconds)
  coroutine.yield("sleep", seconds)
end

function Scheduler:cancel(task_id)
  local task = self.tasks[task_id]
  if task then task.cancelled = true end
end

function Scheduler:_step(deadline)
  local any_active = false
  for id, task in pairs(self.tasks) do
    if deadline and os.clock() >= deadline then
      print("\n  [scheduler] timeout reached!")
      self.tasks = {}
      self.running = false
      return false
    end
    if not task.cancelled then
      any_active = true
      local now = os.clock()
      if now >= task.wake_time then
        local ok, cmd, param = coroutine.resume(task.co)
        if not ok then
          print(string.format("  [task %d] error: %s", id, tostring(cmd)))
          self.tasks[id] = nil
        elseif coroutine.status(task.co) == "dead" then
          self.tasks[id] = nil
        elseif cmd == "sleep" then
          task.wake_time = now + (param or 0)
        end
      end
    else
      self.tasks[id] = nil
    end
  end
  return any_active
end

function Scheduler:run()
  self.running = true
  while self.running do
    if not self:_step(nil) then break end
  end
  self.running = false
end

function Scheduler:run_with_timeout(seconds)
  self.running = true
  local deadline = os.clock() + seconds
  while self.running do
    if not self:_step(deadline) then break end
  end
  self.running = false
end

local function main()
  print("Cooperative Task Scheduler")
  print("=========================\n")

  local sched = Scheduler:new()

  sched:spawn(function()
    for i = 1, 4 do
      print(string.format("  [producer] producing item %d", i))
      sched:sleep(0.3)
    end
    print("  [producer] done")
  end)

  sched:spawn(function()
    for i = 1, 4 do
      print(string.format("  [consumer] consuming item %d", i))
      sched:sleep(0.5)
    end
    print("  [consumer] done")
  end)

  sched:spawn(function()
    sched:sleep(1.0)
    print("  [watchdog] cancelling producer early!")
    sched:cancel(1)
  end)

  print("Running with timeout (2s limit):\n")
  sched:run_with_timeout(2)

  print("\nDemo complete!")
end

main()

return Scheduler
