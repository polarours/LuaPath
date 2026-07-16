# 08 — Coroutines

> **Phase**: C (Concurrency and Runtime Surfaces)  
> **Prerequisites**: Chapter 07 — Error Handling  
> **Time Estimate**: 2–3 hours reading + 3–5 hours exercises  
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT (differences noted)

---

## Learning Objectives

After completing this chapter, you will be able to:

1. **Create and manage coroutines** through their full lifecycle (create → resume → yield → dead)
2. **Use `coroutine.wrap`** for iterator-style coroutine interfaces
3. **Build a cooperative task scheduler** using coroutines
4. **Understand yield/resume semantics** including value passing and error propagation
5. **Identify coroutine pitfalls** including C boundary yields and resource leaks

---

## What Are Coroutines?

Coroutines are **cooperative execution units** — they run voluntarily, yielding control at explicit points. Unlike threads, coroutines are scheduled by the program, not the OS.

Key properties:
- **Cooperative**: must explicitly yield; no preemption
- **Asymmetric**: yield suspends; resume continues
- **Stackful**: each coroutine has its own call stack
- **Lightweight**: much cheaper than OS threads

---

## Coroutine Lifecycle

```lua
local co = coroutine.create(function()
  for i = 1, 3 do
    coroutine.yield(i)  -- Suspend and return i
  end
  return "done"  -- Final return value
end)

-- Status: "suspended" → "running" → "suspended" → ... → "dead"
print(coroutine.status(co))  -- "suspended"

print(coroutine.resume(co))  -- true  1
print(coroutine.status(co))  -- "suspended"

print(coroutine.resume(co))  -- true  2
print(coroutine.resume(co))  -- true  3
print(coroutine.resume(co))  -- true  done (dead)
print(coroutine.resume(co))  -- false  cannot resume dead coroutine
```

### States

| State | Meaning |
|-------|---------|
| `"suspended"` | Created but not started, or yielded |
| `"running"` | Currently executing |
| `"dead"` | Finished or errored |

---

## Value Passing

Coroutines can pass values back and forth between resume and yield:

```lua
-- Yield sends values out; resume sends values in
local co = coroutine.create(function()
  local x = coroutine.yield("first yield")  -- Returns "first yield" to resume caller
  local y = coroutine.yield("second yield") -- Returns "second yield"
  return x + y  -- Final return
end)

local _, val = coroutine.resume(co)      -- val = "first yield"
local _, val = coroutine.resume(co, 10)  -- val = "second yield" (10 passed as x)
local _, val = coroutine.resume(co, 20)  -- val = 30 (10 + 20)
```

### Producer-Consumer Pattern

```lua
local function producer()
  for i = 1, 10 do
    coroutine.yield(i)  -- Produce value
  end
end

local function consumer(prod)
  while true do
    local ok, value = coroutine.resume(prod)
    if not ok or value == nil then break end
    print("Got: " .. value)
  end
end

consumer(coroutine.create(producer))
```

---

## coroutine.wrap

`coroutine.wrap` returns a **function** that resumes the coroutine. Errors propagate directly (not wrapped in `ok, err`):

```lua
local co = coroutine.wrap(function()
  for i = 1, 5 do
    coroutine.yield(i * 10)
  end
end)

print(co())  -- 10
print(co())  -- 20
print(co())  -- 30
print(co())  -- 40
print(co())  -- 50
print(co())  -- ERROR: cannot resume dead coroutine
```

### wrap vs. create

| Feature | `coroutine.create` | `coroutine.wrap` |
|---------|-------------------|------------------|
| Returns | Coroutine object | Iterator function |
| Error handling | `resume` returns `false, err` | Errors propagate directly |
| Use case | Full control | Simple iteration |

### Iterator with wrap

```lua
local function fibonacci()
  local a, b = 0, 1
  return coroutine.wrap(function()
    while true do
      coroutine.yield(a)
      a, b = b, a + b
    end
  end)
end

for i, fib in fibonacci() do
  if i > 10 then break end
  print(fib)
end
```

---

## Coroutine-Based Scheduler

A cooperative scheduler runs coroutines in round-robin fashion:

```lua
local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new()
  return setmetatable({queue = {}, current = nil}, Scheduler)
end

function Scheduler:spawn(fn)
  local co = coroutine.create(fn)
  self.queue[#self.queue + 1] = co
  return co
end

function Scheduler:run()
  while #self.queue > 0 do
    self.current = table.remove(self.queue, 1)
    local ok, err = coroutine.resume(self.current)
    if not ok then
      print("Task error: " .. tostring(err))
    end
    -- Re-queue if not dead
    if coroutine.status(self.current) ~= "dead" then
      self.queue[#self.queue + 1] = self.current
    end
  end
end

-- Usage
local sched = Scheduler.new()
sched:spawn(function()
  for i = 1, 3 do
    print("Task A: " .. i)
    coroutine.yield()
  end
end)
sched:spawn(function()
  for i = 1, 3 do
    print("Task B: " .. i)
    coroutine.yield()
  end
end)
sched:run()
-- Output: A1, B1, A2, B2, A3, B3
```

### Adding Sleep (Timeout)

```lua
function Scheduler:sleep(seconds)
  local timer = os.clock() + seconds
  while os.clock() < timer do
    coroutine.yield()  -- Wait one tick
  end
end

sched:spawn(function()
  print("Start")
  sched:sleep(0.1)
  print("After 0.1s")
end)
```

---

## Asymmetric vs Symmetric Coroutines

Lua uses **asymmetric** coroutines (also called semi-coroutines):

- **Yield** can only be called from the coroutine itself
- **Resume** can only be called from outside

```lua
-- Asymmetric: yield from inside, resume from outside
local co = coroutine.create(function()
  coroutine.yield(42)  -- Must yield to caller
end)

coroutine.resume(co)  -- Must resume from outside
```

Symmetric coroutines (available in some languages) allow yielding to any coroutine directly. Lua's model requires a scheduler to mediate.

---

## Coroutine Patterns

### Generator

```lua
local function lines_from(file)
  return coroutine.wrap(function()
    for line in io.lines(file) do
      coroutine.yield(line)
    end
  end)
end

for line in lines_from("data.txt") do
  print(line)
end
```

### Channel (Bounded Queue)

```lua
local function channel()
  local buffer = {}
  local producer_done = false

  local function send(value)
    buffer[#buffer + 1] = value
    coroutine.yield()  -- Resume consumer
  end

  local function receive()
    while #buffer == 0 and not producer_done do
      coroutine.yield()  -- Resume producer
    end
    if #buffer > 0 then
      return table.remove(buffer, 1)
    end
    return nil
  end

  local function close()
    producer_done = true
  end

  return send, receive, close
end
```

### Coroutine-Based State Machine

```lua
local function state_machine()
  local states = {}
  local current = nil

  function states.idle()
    print("State: idle")
    coroutine.yield("wait")
    return "processing"
  end

  function states.processing()
    print("State: processing")
    coroutine.yield("work")
    return "idle"
  end

  current = states.idle
  while current do
    current = current()
  end
end

local co = coroutine.create(state_machine)
coroutine.resume(co)  -- "State: idle", returns "wait"
coroutine.resume(co)  -- "State: processing", returns "work"
coroutine.resume(co)  -- "State: idle", returns "wait"
```

### Parallel Iteration

```lua
local function par_iter(...)
  local coroutines = {}
  for _, fn in ipairs({...}) do
    coroutines[#coroutines + 1] = coroutine.create(fn)
  end

  return coroutine.wrap(function()
    while true do
      local any_alive = false
      for i, co in ipairs(coroutines) do
        if coroutine.status(co) ~= "dead" then
          any_alive = true
          local ok, val = coroutine.resume(co)
          if ok and val ~= nil then
            coroutine.yield(i, val)
          end
        end
      end
      if not any_alive then break end
    end
  end)
end
```

---

## Common Pitfalls

### 1. Yielding Across C Boundaries

Some C functions cannot yield. If a coroutine yields inside a C function, the program crashes:

```lua
-- BROKEN: io.read is C, cannot yield inside it
local co = coroutine.create(function()
  print(io.read())  -- May crash if yielded inside
end)

-- SAFE: Use Lua-level I/O or yield outside C calls
local co = coroutine.create(function()
  local line = io.read()  -- I/O completes before yield
  coroutine.yield(line)   -- Yield is safe here
end)
```

> **Lua 5.4 note**: More C functions support yielding in 5.4, but not all. Check documentation.

### 2. Forgetting to Re-queue

```lua
-- BUG: Lost coroutine after yield
local co = coroutine.create(function()
  for i = 1, 3 do
    print(i)
    coroutine.yield()
  end
end)

coroutine.resume(co)  -- Prints 1
-- Forgot to re-queue! Coroutine is now lost.
```

### 3. Error Propagation

```lua
-- Errors in coroutines don't propagate to main thread
local co = coroutine.create(function()
  error("boom")
end)

local ok, err = coroutine.resume(co)
print(ok)   -- false
print(err)  -- boom

-- But: errors in wrap() DO propagate
local co = coroutine.wrap(function()
  error("boom")
end)
co()  -- ERROR: boom (crashes caller)
```

### 4. Resource Leaks

```lua
-- Coroutines that never finish hold resources
local function leaky()
  while true do
    coroutine.yield()  -- Never returns → never GC'd until explicitly killed
  end
end

-- FIX: Add cancellation
local function cancellable()
  local cancelled = false
  return function()
    while not cancelled do
      coroutine.yield()
    end
  end, function() cancelled = true end
end
```

### 5. Non-Deterministic Scheduling

```lua
-- BUG: Queue order depends on spawn order
sched:spawn(function() print("A") coroutine.yield() print("A2") end)
sched:spawn(function() print("B") coroutine.yield() print("B2") end)
-- A, B, A2, B2 — but if B spawns A inside, order changes

-- FIX: Document scheduling policy explicitly
```

---

## Best Practices

### 1. Model Explicit Await Points

```lua
-- GOOD: Clear yield points
function task()
  local data = fetch_data()    -- Yield point (I/O)
  local result = process(data) -- No yield (CPU)
  send_result(result)          -- Yield point (network)
end

-- BAD: Hidden yield points
function task()
  helper()  -- Where does this yield? Who knows!
end
```

### 2. Keep Coroutine State Minimal

```lua
-- GOOD: State lives outside coroutine
local function worker(state)
  while state.running do
    local item = state.queue:pop()
    if item then
      process(item)
    end
    coroutine.yield()
  end
end

-- BAD: State buried inside coroutine
local function worker()
  local queue = ...  -- Where did this come from?
  local running = true  -- How to stop?
end
```

### 3. Separate Scheduler from Task Logic

```lua
-- Task code: no knowledge of scheduler
local function my_task()
  for i = 1, 10 do
    do_work(i)
    coroutine.yield()  -- Generic yield, no scheduler dependency
  end
end

-- Scheduler: handles scheduling policy
local sched = Scheduler.new()
sched:spawn(my_task)
sched:run()  -- Scheduler decides when to run
```

### 4. Add Timeouts

```lua
function Scheduler:run_with_timeout(timeout)
  local start = os.clock()
  while #self.queue > 0 do
    if os.clock() - start > timeout then
      print("Scheduler timeout")
      break
    end
    -- ... normal run logic
  end
end
```

### 5. Document Coroutine Contracts

```lua
--- Fetch data from remote API
-- Yields: waits for network response
-- Resumes with: response data
-- Errors: on network failure
-- @return table response data
function fetch_remote(url)
  -- ...
  coroutine.yield()  -- Wait for response
  return response
end
```

---

## Version Notes

### Lua 5.1

- `coroutine.wrap` errors propagate directly
- `coroutine.yield` cannot cross C boundaries at all
- `coroutine.resume` returns `true, values...` on success

### Lua 5.2/5.3

- `coroutine.resume` with multiple returns preserves all values
- `coroutine.yield` can cross some C boundaries (more functions are yieldable)
- `coroutine.isyieldable(co)` checks if a coroutine can yield

### Lua 5.4

- More C functions support yielding (including `tostring`, `pcall`)
- `coroutine.close(co)` closes a coroutine and runs any to-be-closed variables
- Better error messages for yield/resume mismatches

```lua
-- Lua 5.4: close coroutine explicitly
-- local co = coroutine.create(function()
--   local <close> resource = acquire()
--   coroutine.yield()
--   -- resource released on close
-- end)
-- coroutine.resume(co)
-- coroutine.close(co)  -- Releases resource
```

### LuaJIT

- Coroutines are very efficient (lightweight stack switching)
- JIT traces work across yield/resume boundaries in some cases
- Avoid yielding inside JIT-traced code for best performance

---

## Knowledge Check

<details>
<summary>1. What's the difference between <code>coroutine.create</code> and <code>coroutine.wrap</code>?</summary>

`create` returns a coroutine object; errors in `resume` are returned as `false, err`. `wrap` returns a function; errors propagate directly to the caller.
</details>

<details>
<summary>2. How do values flow between resume and yield?</summary>

`resume(co, v1, v2)` sends v1, v2 into the coroutine. Inside, `coroutine.yield(x, y)` sends x, y back to the resume caller. The first `resume` sends values as arguments to the coroutine function.
</details>

<details>
<summary>3. Why can't you yield across all C function calls?</summary>

C functions don't have Lua stacks that can be suspended. Lua can only yield at Lua-level call boundaries. Some C functions (in 5.2+) are explicitly marked as yieldable.
</details>

<details>
<summary>4. What happens if a coroutine errors and you use <code>wrap</code>?</summary>

The error propagates directly to the caller of the wrap function, like a normal function error. It's not caught — it crashes the caller unless the caller uses pcall.
</details>

<details>
<summary>5. How do you stop a coroutine that loops forever?</summary>

There's no built-in cancel. Set a flag (shared upvalue or table field) that the coroutine checks each iteration. Or use `coroutine.close` (5.4+) to force-close it.
</details>

---

## Key Takeaways

- **Cooperative**: coroutines yield voluntarily; no preemption
- **Asymmetric**: yield from inside, resume from outside
- **Value passing**: resume sends values in, yield sends values out
- **Scheduler**: round-robin re-queue after each yield
- **wrap vs create**: wrap for iteration, create for full control
- **C boundary**: can't yield inside most C functions
- **Error handling**: create uses ok/err, wrap propagates directly
- **Resource management**: add cancellation flags or use `coroutine.close` (5.4)

---

## Exercises

### Beginner (30–60 min)

1. **Fibonacci Generator**: Create a coroutine that yields Fibonacci numbers indefinitely. Consume the first 20.

2. **Countdown**: Write a coroutine that yields remaining seconds from N to 0, then returns "done".

3. **Batch Processor**: Use a coroutine to process items in batches of N, yielding between batches.

### Intermediate (1–2 hours)

4. **Cooperative Scheduler**: Build a scheduler with `spawn`, `run`, and `sleep` (tick-based). Run 5 tasks concurrently.

5. **Channel**: Implement a bounded channel with `send` and `receive` that blocks (yields) when full/empty.

6. **Pipeline**: Create a 3-stage pipeline (parse → transform → validate) where each stage is a coroutine. Data flows through channels.

### Advanced (2–4 hours)

7. **Coroutine Pool**: Build a worker pool that distributes tasks across N coroutines with load balancing.

8. **Event Loop**: Implement a minimal event loop using coroutines that handles timers, I/O readiness, and channel messages.

---

## Example Code

Runnable examples for this chapter:
- `examples/intermediate/03-coroutine-scheduler.lua` — Full cooperative scheduler
- `examples/beginner/01-moving-average.lua` — Coroutine-based stream processing

---

## Further Reading

- [Lua 5.4 Reference Manual — Section 2.6](https://www.lua.org/manual/5.4/manual.html#2.6)
- [Programming in Lua (4th ed.) — Chapter 9, 24](https://www.lua.org/pil/)
- [Next Chapter: 09 — Standard Library](09-standard-library.md)
