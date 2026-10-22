# Intermediate Exercises — Solutions

Reference solutions for the intermediate exercise set: 13 concept exercises,
4 mini projects, 6 debugging tasks and 6 open-ended design questions.
Every code block here runs on Lua 5.1 through 5.5 and on LuaJIT.

---

## Exercise Reference

| Section | Exercises |
|---------|-----------|
| [Metatables and Metamethods](intermediate.md#metatables-and-metamethods) | 1 Read-only table proxy · 2 Arithmetic operator overloading |
| [Module Patterns](intermediate.md#module-patterns) | 3 Module with private state · 4 Circular dependency resolution |
| [Coroutines and Scheduling](intermediate.md#coroutines-and-scheduling) | 5 Producer-consumer pipeline · 6 Cooperative round-robin scheduler |
| [Error Handling Patterns](intermediate.md#error-handling-patterns) | 7 Error accumulator · 8 Assert-with-context |
| [Iterators and Generators](intermediate.md#iterators-and-generators) | 9 Sliding window iterator · 10 Stateful generator |
| [String Patterns](intermediate.md#string-patterns) | 11 INI section parser |
| [Table Operations](intermediate.md#table-operations) | 12 Deep merge |
| [Functions and Closures](intermediate.md#functions-and-closures) | 13 Partial application |
| [Mini Projects](intermediate.md#mini-projects) | P1 Cache System with TTL · P2 Finite State Machine · P3 Event System · P4 Test Framework Basics |
| [Debugging Tasks](intermediate.md#debugging-tasks) | D1 Infinite recursion in `__index` · D2 Coroutine starvation · D3 Module re-initialization bug · D4 Shared metatable mutation · D5 Closure loop capture · D6 In-place sort side effect |
| [Open-Ended Design Questions](intermediate.md#open-ended-design-questions) | Q1 Error philosophy · Q2 Event bus memory management · Q3 Scheduler observability · Q4 Configuration layering · Q5 State machine scalability · Q6 Test isolation |

---

## Exercise 1: Read-only table proxy

**Task**: Implement `readonly(t)` returning a proxy table whose reads pass through to the original table and whose writes raise an error through `__newindex`.

**Solution**:

```lua
-- Read-only proxy: reads fall through to the original table,
-- writes are rejected by __newindex.
local function readonly(t)
  local proxy = {}
  local mt = {
    __index = t,                        -- reads are served by the original table
    __newindex = function(_, key, value)
      error(string.format("attempt to modify a read-only table (key %q)",
        tostring(key)), 2)
    end,
    __metatable = "read-only",          -- getmetatable cannot expose the real mt
  }
  return setmetatable(proxy, mt)
end

local r = readonly({ a = 1 })
print(r.a)                              --> 1

local ok, err = pcall(function() r.a = 2 end)
assert(not ok, "writing to a read-only table must fail")
assert(tostring(err):find("read%-only"), tostring(err))

-- The original table is untouched.
assert(r.a == 1)
assert(getmetatable(r) == "read-only")
```

**Key points**:
- The proxy holds no data of its own: `__index` is the original table, so every read is a normal lookup on it.
- `__newindex` fires on *every* assignment, because the proxy table itself is always empty — even for keys that exist in the original.
- The original table stays mutable; only the view handed to callers is frozen.
- `__metatable` hides the real metatable, so `getmetatable` cannot be used to tamper with the proxy.
- Raising with level `2` points the error at the caller of the assignment, not at the metamethod.

## Exercise 2: Arithmetic operator overloading

**Task**: Build a `Vec2` type with `__add`, `__sub`, `__mul` (scalar) and `__eq` metamethods, and a `__tostring` that renders `Vec2(x, y)`.

**Solution**:

```lua
-- Vec2: a small vector type driven by one shared metatable.
local Vec2 = {}

local mt = {
  __add = function(a, b)
    return Vec2.new(a.x + b.x, a.y + b.y)
  end,
  __sub = function(a, b)
    return Vec2.new(a.x - b.x, a.y - b.y)
  end,
  __mul = function(a, b)
    -- scalar * vector, vector * scalar, and vector * vector
    if type(a) == "number" then return Vec2.new(a * b.x, a * b.y) end
    if type(b) == "number" then return Vec2.new(a.x * b, a.y * b) end
    return Vec2.new(a.x * b.x, a.y * b.y)
  end,
  __eq = function(a, b)
    return a.x == b.x and a.y == b.y
  end,
  __tostring = function(v)
    return string.format("Vec2(%g, %g)", v.x, v.y)
  end,
}

function Vec2.new(x, y)
  return setmetatable({ x = x, y = y }, mt)
end

local v = Vec2.new(1, 2) + Vec2.new(3, 4)
print(tostring(v))                     --> Vec2(4, 6)
assert(tostring(v) == "Vec2(4, 6)")

local d = Vec2.new(10, 20) - Vec2.new(1, 2)
assert(d.x == 9 and d.y == 18)

local scaled = Vec2.new(1, 2) * 3
assert(scaled.x == 3 and scaled.y == 6)

local scaled2 = 3 * Vec2.new(1, 2)
assert(scaled2.x == 3 and scaled2.y == 6)

assert(Vec2.new(1, 2) == Vec2.new(1, 2))
assert(Vec2.new(1, 2) ~= Vec2.new(2, 1))
```

**Key points**:
- All instances share one metatable, so `__eq` is reachable: Lua only calls it when both operands use the same handler.
- `__mul` has to inspect both operands — Lua tries the left operand's handler first, then the right one's, so `3 * v` arrives as `__mul(3, v)`.
- `__tostring` controls both `print(v)` and `tostring(v)`; `%g` renders integers and floats without a trailing `.0`.
- Operators always return a *new* vector; instances stay immutable in practice.
- `__eq` is only consulted when the raw comparison already failed, so equal vectors must be distinct tables.

## Exercise 3: Module with private state

**Task**: Create a module using the revealing-module pattern that exports `get()`, `set()` and `reset()` while keeping the backing store unreachable from outside.

**Solution**:

```lua
-- Revealing-module pattern: the backing store lives in the closure
-- and is never exposed through the returned table.
local function new_counter_module()
  local store = { count = 0 }          -- private state

  local M = {}

  function M.get()
    return store.count
  end

  function M.set(value)
    store.count = value
    return value
  end

  function M.reset()
    store.count = 0
  end

  return M
end

local counter = new_counter_module()

counter.set(42)
assert(counter.get() == 42)
counter.reset()
assert(counter.get() == 0)

-- The backing store cannot be reached from the outside.
assert(rawget(counter, "store") == nil)
assert(counter.store == nil)
assert(rawget(counter, "count") == nil)

-- Writing to the exported table does not touch the private state.
counter.count = 999
assert(counter.get() == 0)
```

**Key points**:
- The state lives in a local of the module closure; only the three functions can reach it.
- `rawget` confirms nothing was stashed on the exported table under a guessable name.
- Because the exported table has no `__newindex`, stray writes create a new field and leave `store` alone.
- The same shape works for a real module: build the module inside a `do ... end` block or a function and `return M`.

## Exercise 4: Circular dependency resolution

**Task**: Refactor two mutually dependent modules `a` and `b` so both load without errors, using a lazy-init pattern that resolves cross references on first use.

**Solution**:

```lua
-- Lazy module registry. A module only reaches for another module inside a
-- function body, so the load order stops mattering.
local registry = {}

local function register(name, factory)
  registry[name] = { factory = factory, value = nil, loaded = false }
end

local function require_module(name)
  local entry = registry[name]
  if not entry then
    error("module not found: " .. tostring(name), 2)
  end
  if not entry.loaded then
    entry.loaded = true                -- set first: a cycle cannot loop forever
    entry.value = entry.factory()
  end
  return entry.value
end

-- Module a: reaches for b only when greet() is called.
register("a", function()
  local a = {}
  function a.name() return "a" end
  function a.greet()
    return "a greets " .. require_module("b").name()
  end
  return a
end)

-- Module b: reaches for a only when greet() is called.
register("b", function()
  local b = {}
  function b.name() return "b" end
  function b.greet()
    return "b greets " .. require_module("a").name()
  end
  return b
end)

-- Both modules load successfully, in any order.
local a = require_module("a")
local b = require_module("b")
assert(a.name() == "a")
assert(b.name() == "b")

-- Cross references resolve on first use.
assert(a.greet() == "a greets b")
assert(b.greet() == "b greets a")
```

**Key points**:
- The circular reference lives inside function bodies, so it is resolved at call time, not at load time.
- `require_module` memoises the instance, so repeated lookups return the same table.
- The `loaded` flag is set *before* the factory runs, which turns an accidental load-time cycle into a bounded recursion instead of an infinite loop.
- The same idea in the standard library is `require` plus `package.loaded`, with forward declarations at the top of a module.

## Exercise 5: Producer-consumer pipeline

**Task**: Build a pipeline where a producer coroutine yields batches of data and a consumer coroutine processes them, passing values in both directions with `coroutine.resume`.

**Solution**:

```lua
-- Producer/consumer pipeline: the producer yields batches, the consumer
-- prints every item and acknowledges each batch, so values travel both ways.
local function producer(total, batch_size)
  return coroutine.create(function()
    local batch = {}
    for i = 1, total do
      batch[#batch + 1] = i
      if #batch == batch_size then
        local ack = coroutine.yield(batch)
        if ack ~= "ack" then
          error("producer expected an ack, got " .. tostring(ack))
        end
        batch = {}
      end
    end
    if #batch > 0 then
      local ack = coroutine.yield(batch)
      if ack ~= "ack" then
        error("producer expected an ack, got " .. tostring(ack))
      end
    end
    return nil
  end)
end

local function consumer(prod)
  return coroutine.create(function()
    local ok, batch = coroutine.resume(prod)          -- start the producer
    if not ok then error(batch, 0) end

    local processed = 0
    while batch ~= nil do
      for _, item in ipairs(batch) do
        processed = processed + 1
        print("consumer processed item " .. tostring(item))
      end
      -- Acknowledge the batch and pull the next one in the same resume.
      local ok2, next_batch = coroutine.resume(prod, "ack")
      if not ok2 then error(next_batch, 0) end
      batch = next_batch
    end
    return processed
  end)
end

local prod = producer(10, 3)
local cons = consumer(prod)

local ok, processed = coroutine.resume(cons)
assert(ok, tostring(processed))
assert(processed == 10)
assert(coroutine.status(prod) == "dead")
assert(coroutine.status(cons) == "dead")
```

**Key points**:
- `coroutine.resume(co, value)` delivers `value` to the suspended `coroutine.yield`, which returns it to the producer.
- One `resume` both acknowledges the current batch and fetches the next one — the producer keeps running until it yields again.
- The pipeline ends when the producer returns: `resume` then yields `true` with no payload, so the consumer sees `nil` and stops.
- `coroutine.status` confirms that both ends finished cleanly instead of being left suspended.
- The producer is the one that owns the data; the consumer never mutates the batch, it only reads it.

## Exercise 6: Cooperative round-robin scheduler

**Task**: Implement a scheduler that runs N coroutines round-robin, giving each a time slice measured in yields and requeueing a coroutine whose slice is used up.

**Solution**:

```lua
-- Round-robin scheduler with a time slice (counted in yields) per task.
local function schedule(tasks, quantum)
  local queue = {}
  for i = 1, #tasks do
    queue[i] = { name = tasks[i].name, co = coroutine.create(tasks[i].fn), used = 0 }
  end

  local tick = 0
  while #queue > 0 do
    local task = table.remove(queue, 1)   -- take the task at the head
    tick = tick + 1

    local ok, err = coroutine.resume(task.co, tick)
    if not ok then error(err, 0) end

    if coroutine.status(task.co) == "dead" then
      -- the task finished: it is simply not requeued
    elseif task.used + 1 >= quantum then
      task.used = 0
      table.insert(queue, task)          -- slice used up: preempt, requeue at the back
    else
      task.used = task.used + 1
      table.insert(queue, 1, task)        -- slice left: keep it running at the front
    end
  end
end

local log = {}
local function make_task(name, steps)
  return function()
    for _ = 1, steps do
      log[#log + 1] = name
      coroutine.yield(name)
    end
  end
end

schedule({
  { name = "a", fn = make_task("a", 3) },
  { name = "b", fn = make_task("b", 3) },
  { name = "c", fn = make_task("c", 3) },
}, 2)                                     -- two yields per slice

print(table.concat(log, " "))

local counts = { a = 0, b = 0, c = 0 }
for _, name in ipairs(log) do counts[name] = counts[name] + 1 end
assert(#log == 9)
assert(counts.a == 3 and counts.b == 3 and counts.c == 3)

-- The first slice of each task starts in round-robin order.
assert(log[1] == "a" and log[3] == "b" and log[5] == "c")

-- The output interleaves the tasks instead of running them one after another.
local first_c, last_a
for i, name in ipairs(log) do
  if name == "c" and not first_c then first_c = i end
  if name == "a" then last_a = i end
end
assert(first_c < last_a, "the tasks must interleave")
```

**Key points**:
- The queue holds one entry per task; the head runs, and the slice decides whether it stays at the head or moves to the back.
- A task that finishes is dropped instead of being requeued.
- `coroutine.resume` reports the error of a failed task as `false, message`, which the scheduler turns into a real error.
- Fairness comes from the slice, not from the number of tasks: every task gets the same budget of yields per turn.
- A coroutine that never yields cannot be preempted — the scheduler only regains control when the coroutine gives it up.

## Exercise 7: Error accumulator

**Task**: Write `pcall_accumulate(fns)` that calls every function with `pcall` and returns one `{ok=..., result=..., error=...}` record per function.

**Solution**:

```lua
-- Collect the outcome of every call instead of letting one failure
-- abort the whole batch.
local function pcall_accumulate(fns)
  local results = {}
  for i = 1, #fns do
    local ok, value = pcall(fns[i])
    if ok then
      results[i] = { ok = true, result = value }
    else
      results[i] = { ok = false, error = value }
    end
  end
  return results
end

local fns = {
  function() return 42 end,
  function() error("boom") end,
  function() return "fine" end,
  function() error({ code = 500 }) end,
}

local results = pcall_accumulate(fns)

assert(#results == 4)                    -- the batch survived every failure
assert(results[1].ok == true and results[1].result == 42)
assert(results[2].ok == false and tostring(results[2].error):find("boom"))
assert(results[3].ok == true and results[3].result == "fine")
assert(results[4].ok == false and results[4].error.code == 500)
```

**Key points**:
- `pcall` returns `false` plus the error value, so the failure is data and never escapes the loop.
- The error value may be a string *or* a table; keeping it verbatim lets the caller inspect `code`, `reason` and friends.
- Success and failure are stored in separate fields, so a successful `false` or `nil` result is not confused with an error.
- The result list is positional: entry `i` always belongs to `fns[i]`.

## Exercise 8: Assert-with-context

**Task**: Build `assertf(condition, fmt, ...)` that raises a formatted error message including the file and line of the failed assertion.

**Solution**:

```lua
-- assert with a formatted message plus the call site of the failing check.
local function assertf(condition, fmt, ...)
  if condition then
    return condition
  end

  local info = debug.getinfo(2, "Sl")   -- the caller of assertf
  local where = "unknown location"
  if info then
    where = string.format("%s:%d", info.short_src, info.currentline or 0)
  end

  local message
  if type(fmt) == "string" and select("#", ...) > 0 then
    message = string.format(fmt, ...)
  else
    message = tostring(fmt)
  end

  error(string.format("assertion failed at %s: %s", where, message), 0)
end

-- A passing assertion returns quietly.
assertf(1 + 1 == 2, "arithmetic is broken")

local call_line
local ok, err = pcall(function()
  call_line = debug.getinfo(1, "l").currentline + 1
  assertf(1 == 2, "value %d must be positive", -1)
end)

assert(not ok)
assert(err:find("assertion failed at") ~= nil, err)
assert(err:find("value %-1 must be positive") ~= nil, err)
assert(err:find(":" .. call_line .. ":") ~= nil, "wrong line in: " .. err)
print(err)
```

**Key points**:
- `debug.getinfo(2, "Sl")` returns the caller of `assertf`: `short_src` is the file, `currentline` the line of the call.
- Level `2` is one step above `assertf` itself; level `1` would point inside the helper.
- `select("#", ...)` tells whether extra arguments were passed, so a plain message is never run through `string.format`.
- `error(msg, 0)` keeps the message exactly as built — the location is already part of it.
- The check belongs in a plain Lua function: a C frame between the caller and `assertf` would hide the real source location.

## Exercise 9: Sliding window iterator

**Task**: Implement `window(xs, k)` returning an iterator that yields the successive k-sized windows over a list.

**Solution**:

```lua
-- Sliding window iterator: every call returns the next k-sized window.
local function window(xs, k)
  k = k or 1
  if k < 1 then
    error("window size must be >= 1", 2)
  end

  local n = #xs
  local i = 0

  return function()
    i = i + 1
    if i + k - 1 > n then
      return nil                        -- no further windows
    end
    local w = {}
    for j = 0, k - 1 do
      w[j + 1] = xs[i + j]
    end
    return w
  end
end

local windows = {}
for w in window({ 1, 2, 3, 4, 5 }, 3) do
  windows[#windows + 1] = w
end

assert(#windows == 3)
assert(table.concat(windows[1], ",") == "1,2,3")
assert(table.concat(windows[2], ",") == "2,3,4")
assert(table.concat(windows[3], ",") == "3,4,5")

-- Edge cases: one-element windows, and a window wider than the list.
local single = 0
for _ in window({ 1, 2, 3 }, 1) do single = single + 1 end
assert(single == 3)

local none = 0
for _ in window({ 1, 2 }, 3) do none = none + 1 end
assert(none == 0)
```

**Key points**:
- The window start lives in an upvalue of the returned closure, so the iterator keeps its own position.
- Each window is a fresh table, so a caller that modifies it cannot corrupt the source list.
- The iterator returns `nil` when the window would run past the end, which terminates the generic `for`.
- A generic `for` calls the closure with two ignored arguments, so the state stays entirely in the upvalue.
- The cost is O(k) per window, so the whole traversal is O(n * k).

## Exercise 10: Stateful generator

**Task**: Build `make_counter(start, step)` returning a function whose successive calls produce the next value of the sequence.

**Solution**:

```lua
-- A generator: each call returns the next value and advances the state.
local function make_counter(start, step)
  start = start or 0
  step = step or 1

  local value = start
  return function()
    local current = value
    value = value + step
    return current
  end
end

local c = make_counter(0, 2)
assert(c() == 0)
assert(c() == 2)
assert(c() == 4)

-- Every generator keeps its own state.
local c1 = make_counter(0, 1)
local c2 = make_counter(100, 5)
assert(c1() == 0)
assert(c2() == 100)
assert(c1() == 1)
assert(c2() == 105)
```

**Key points**:
- The mutable `value` is captured by the closure; each call reads it and then advances it.
- The value is returned *before* the update, which is why the first call yields `start` and not `start + step`.
- Two generators never share state — each call to `make_counter` creates a fresh upvalue.
- The same shape generalises to any sequence: strings, table entries, or a filtered list.

## Exercise 11: INI section parser

**Task**: Parse a string with `[section]` headers and `key=value` pairs into a nested table `{section = {key = value}}`.

**Solution**:

```lua
-- Minimal INI parser: [section] headers plus key = value pairs.
local function parse_ini(text)
  local result = {}
  local section = nil

  for line in (text .. "\n"):gmatch("(.-)\r?\n") do
    local trimmed = line:match("^%s*(.-)%s*$")

    if trimmed ~= "" and trimmed:sub(1, 1) ~= "#" then
      local name = trimmed:match("^%[(.+)%]$")
      if name then
        section = name
        result[section] = result[section] or {}
      else
        local key, value = trimmed:match("^(%w+)%s*=%s*(.*)$")
        if key then
          if not section then
            error("key '" .. key .. "' appears before any section", 0)
          end
          result[section][key] = value
        end
      end
    end
  end

  return result
end

local cfg = parse_ini("[db]\nhost=localhost\nport=5432")
assert(cfg.db.host == "localhost")
assert(cfg.db.port == "5432")

-- Several sections, comments and stray spaces.
local cfg2 = parse_ini([[
# a comment
[db]
host = localhost
port = 5432

[cache]
ttl=60
]])
assert(cfg2.db.host == "localhost")
assert(cfg2.db.port == "5432")
assert(cfg2.cache.ttl == "60")
```

**Key points**:
- The line loop uses `(.-)\r?\n` so both LF and CRLF input works; the trailing newline is added to flush the last line.
- `^%s*(.-)%s*$` trims the line before it is classified.
- `%[(.+)%]$` captures a section header, `^(%w+)%s*=%s*(.*)$` captures a key and its value.
- The value pattern uses `(.*)`, not `(.+)`, so an empty value is accepted.
- The current section is tracked in a local; keys without a section are rejected instead of silently landing in the wrong place.

## Exercise 12: Deep merge

**Task**: Implement `deep_merge(base, override)` that merges recursively, so a nested table in `override` is merged into the matching table of `base` instead of replacing it.

**Solution**:

```lua
-- Recursive merge: nested tables are merged, not replaced.
-- Merges into base in place and returns it.
local function deep_merge(base, override)
  for key, value in pairs(override) do
    if type(value) == "table" then
      if type(base[key]) == "table" then
        deep_merge(base[key], value)     -- both sides are tables: merge them
      else
        base[key] = value                -- no table to merge into: take the new value
      end
    else
      base[key] = value
    end
  end
  return base
end

local base = { a = 1, b = { c = 2 } }
local merged = deep_merge(base, { b = { d = 3 } })

assert(merged.a == 1)
assert(merged.b.c == 2)
assert(merged.b.d == 3)

-- A non-table value in override wins over the value in base.
local cfg = deep_merge({ port = 80, debug = false }, { port = 5432 })
assert(cfg.port == 5432 and cfg.debug == false)
```

**Key points**:
- The merge is driven by `type(value) == "table"`: only tables are merged recursively, everything else is overwritten.
- The merge happens in place, so `base` is updated and returned; copy the inputs first when the original must survive.
- A table in `override` whose counterpart in `base` is missing (or not a table) is assigned as a whole.
- Values coming from `override` are shared by reference — deep-copy them if the caller may mutate them later.
- The recursion depth follows the nesting of the data, so cyclic tables would loop forever.

## Exercise 13: Partial application

**Task**: Implement `partial(fn, ...)` returning a new function with the leading arguments pre-bound.

**Solution**:

```lua
-- Partial application: bind the leading arguments of a function.
local unpack = unpack or table.unpack      -- global in 5.1, table.unpack in 5.2+

local function partial(fn, ...)
  local bound = { ... }
  local bound_count = select("#", ...)      -- the count keeps trailing nils

  return function(...)
    local args = {}
    for i = 1, bound_count do
      args[i] = bound[i]
    end

    local extra = { ... }
    local extra_count = select("#", ...)
    for i = 1, extra_count do
      args[bound_count + i] = extra[i]
    end

    return fn(unpack(args, 1, bound_count + extra_count))
  end
end

local add = partial(function(a, b) return a + b end, 10)
assert(add(5) == 15)

local greet = partial(string.format, "Hello, %s!")
assert(greet("Ada") == "Hello, Ada!")

local join3 = partial(function(a, b, c) return a .. b .. c end, "x", "y")
assert(join3("z") == "xyz")
```

**Key points**:
- The bound arguments live in the upvalues of the returned closure; each call appends its own arguments.
- `select("#", ...)` counts the arguments, so a trailing `nil` is not lost the way `{...}` would lose it.
- `unpack(args, 1, n)` passes exactly `n` values, which keeps `nil` holes in the argument list.
- `local unpack = unpack or table.unpack` bridges the 5.1 global and the 5.2+ table field.
- The result is a normal function: it can be stored, passed on and combined with other partial applications.

---

## Project 1: Cache System with TTL

**Task**: Build a key-value cache that evicts entries after a configurable time-to-live — `Cache.new(ttl_seconds)`, `cache:get(key)`, `cache:set(key, value)`, `cache:cleanup()`, `cache:keys()`.

**Solution**:

```lua
-- Project 1: cache with a time-to-live.
-- Every entry is stored as {value = ..., created = ...}; an entry is
-- expired once os.time() - created >= ttl.

local Cache = {}
Cache.__index = Cache

--- Create a cache whose entries live for ttl_seconds.
-- @param ttl_seconds number of seconds an entry stays valid
-- @return cache table with get/set/cleanup/keys
function Cache.new(ttl_seconds)
  assert(type(ttl_seconds) == "number" and ttl_seconds > 0,
         "ttl_seconds must be a positive number")
  return setmetatable({ entries = {}, ttl = ttl_seconds }, Cache)
end

--- Return the value stored under key, or nil when it is missing or expired.
-- @param key cache key
-- @return stored value or nil
function Cache:get(key)
  local entry = self.entries[key]
  if entry == nil then
    return nil
  end
  if os.time() - entry.created >= self.ttl then
    self.entries[key] = nil            -- drop the stale entry on access
    return nil
  end
  return entry.value
end

--- Store value under key and restart its time-to-live.
-- @param key cache key
-- @param value value to store
-- @return the cache itself
function Cache:set(key, value)
  self.entries[key] = { value = value, created = os.time() }
  return self
end

--- Remove every expired entry.
-- @return number of entries removed
function Cache:cleanup()
  local now = os.time()
  local removed = 0
  for key, entry in pairs(self.entries) do
    if now - entry.created >= self.ttl then
      self.entries[key] = nil
      removed = removed + 1
    end
  end
  return removed
end

--- Return the sorted list of keys that are still valid.
-- @return array of live keys
function Cache:keys()
  local now = os.time()
  local keys = {}
  for key, entry in pairs(self.entries) do
    if now - entry.created < self.ttl then
      keys[#keys + 1] = key
    end
  end
  table.sort(keys)
  return keys
end

-- Tests. os.time() has one-second resolution, so the clock is replaced by a
-- controllable one instead of sleeping.
local real_time = os.time
local now = 1000
os.time = function() return now end

local cache = Cache.new(10)
cache:set("a", 1)
cache:set("b", 2)

assert(cache:get("a") == 1)
assert(cache:get("missing") == nil)
assert(table.concat(cache:keys(), ",") == "a,b")

now = now + 5                              -- still fresh
assert(cache:get("a") == 1)

now = now + 5                              -- 10 seconds old: expired
assert(cache:get("a") == nil)
assert(cache:get("b") == nil)
assert(#cache:keys() == 0)

-- cleanup() removes expired entries in bulk
cache:set("c", 3)
now = now + 20
assert(cache:cleanup() == 1)
assert(#cache:keys() == 0)

-- set() restarts the time-to-live of an existing key
cache:set("d", 4)
now = now + 9
cache:set("d", 5)
now = now + 2
assert(cache:get("d") == 5)

os.time = real_time
print("cache: all tests passed")
```

**Key points**:
- Each entry is `{value = ..., created = ...}`; the TTL is a property of the cache, not of the entry, so one `Cache` instance can be recreated with a different `ttl_seconds`.
- Expiry is checked on access (`get`), in bulk (`cleanup`) and when listing (`keys`), so a stale entry is never handed out even if `cleanup` was never called.
- `os.time()` has one-second resolution — a `ttl` below one second is not observable; use `os.clock()` if sub-second precision matters.
- `set` overwrites the whole entry, which resets `created` and therefore refreshes the TTL.
- Removing entries while iterating with `pairs` is safe here: only existing fields are set to `nil`, which is explicitly allowed by the manual.

---

## Project 2: Finite State Machine

**Task**: Implement a generic FSM library — `FSM.new(states, initial)`, `fsm:transition(event)`, `fsm:current()` — raising an error on invalid transitions.

**Solution**:

```lua
-- Project 2: table-driven finite state machine.
-- states maps a state name to a table of event -> next state.

local FSM = {}
FSM.__index = FSM

--- Create a state machine.
-- @param states table: state name -> {event = next state}
-- @param initial name of the initial state
-- @return fsm table with current/transition
function FSM.new(states, initial)
  assert(type(states) == "table", "states must be a table")
  assert(states[initial] ~= nil, "unknown initial state: " .. tostring(initial))
  return setmetatable({ states = states, state = initial }, FSM)
end

--- Name of the state the machine is in.
-- @return state name
function FSM:current()
  return self.state
end

--- Apply an event to the current state.
-- @param event event name
-- @return the new state name
function FSM:transition(event)
  local allowed = self.states[self.state]
  local next_state = allowed and allowed[event]
  if next_state == nil then
    error(string.format("invalid transition: event %q is not allowed in state %q",
                        tostring(event), tostring(self.state)), 2)
  end
  self.state = next_state
  return self.state
end

-- Tests: idle -> loading -> done | error, with start/finish/fail/retry.
local fsm = FSM.new({
  idle    = { start = "loading" },
  loading = { finish = "done", fail = "error" },
  done    = {},
  error   = { retry = "idle" },
}, "idle")

assert(fsm:current() == "idle")
assert(fsm:transition("start") == "loading")
assert(fsm:current() == "loading")
assert(fsm:transition("finish") == "done")
assert(fsm:current() == "done")

-- An event that the current state does not accept raises an error.
local ok, err = pcall(function() fsm:transition("start") end)
assert(not ok)
assert(tostring(err):find("invalid transition", 1, true) ~= nil)

-- The error state and the retry event.
local fsm2 = FSM.new({
  idle    = { start = "loading" },
  loading = { finish = "done", fail = "error" },
  done    = {},
  error   = { retry = "idle" },
}, "idle")
fsm2:transition("start")
assert(fsm2:transition("fail") == "error")
assert(fsm2:current() == "error")
assert(fsm2:transition("retry") == "idle")

-- An unknown initial state is rejected when the machine is built.
assert(not pcall(function() FSM.new({ idle = {} }, "missing") end))

print("fsm: all tests passed")
```

**Key points**:
- The transition table is plain data: `states[state][event] = next_state`. Adding a state or an event means adding a table entry, not changing code.
- `transition` is the only mutator, so "which state am I in" and "is this transition legal" are answered in one place.
- The error is raised with level `2`, so the message points at the caller of `transition` instead of at the library internals.
- An event that maps to `nil` is invalid; a state with an empty table (`done = {}`) is a legal terminal state.
- `current()` returns the state name only — adding `on_enter`/`on_exit` callbacks later means attaching them to the state table, not changing the API.

---

## Project 3: Event System

**Task**: Build a publish/subscribe event bus with wildcard support — `EventBus.new()`, `bus:on(pattern, handler)`, `bus:emit(event, ...)`, `bus:off(pattern, handler)` — where `"user.*"` matches `"user.created"`.

**Solution**:

```lua
-- Project 3: publish/subscribe event bus.
-- A pattern is either an exact event name ("user.created") or an event name
-- with a trailing wildcard ("user.*", "*"), which matches every event that
-- starts with the part before the star.

local EventBus = {}
EventBus.__index = EventBus

--- Create an empty event bus.
-- @return bus table with on/off/emit
function EventBus.new()
  return setmetatable({ subscriptions = {} }, EventBus)
end

--- Does pattern cover event?
-- @param pattern subscription pattern
-- @param event event name
-- @return boolean
local function matches(pattern, event)
  if pattern == event then
    return true
  end
  if pattern:sub(-1) == "*" then
    local prefix = pattern:sub(1, -2)       -- "user.*" -> "user."
    return event:sub(1, #prefix) == prefix
  end
  return false
end

--- Subscribe a handler to a pattern.
-- @param pattern subscription pattern
-- @param handler function called as handler(event, ...)
-- @return the handler, so it can be passed to off() later
function EventBus:on(pattern, handler)
  assert(type(pattern) == "string", "pattern must be a string")
  assert(type(handler) == "function", "handler must be a function")
  table.insert(self.subscriptions, { pattern = pattern, handler = handler })
  return handler
end

--- Remove subscriptions.
-- @param pattern pattern to remove
-- @param handler handler to remove; nil removes every handler of the pattern
-- @return number of subscriptions removed
function EventBus:off(pattern, handler)
  local kept = {}
  local removed = 0
  for _, sub in ipairs(self.subscriptions) do
    if sub.pattern == pattern and (handler == nil or sub.handler == handler) then
      removed = removed + 1
    else
      kept[#kept + 1] = sub
    end
  end
  self.subscriptions = kept                  -- the old table is dropped, so
  return removed                             -- no handler reference is leaked
end

--- Dispatch an event to every matching handler, in subscription order.
-- @param event event name
-- @param ... extra arguments passed to the handlers
-- @return number of handlers called
function EventBus:emit(event, ...)
  local called = 0
  for _, sub in ipairs(self.subscriptions) do
    if matches(sub.pattern, event) then
      sub.handler(event, ...)
      called = called + 1
    end
  end
  return called
end

-- Tests.
local bus = EventBus.new()
local log = {}

local exact = bus:on("user.created", function(event, id)
  log[#log + 1] = "exact:" .. event .. ":" .. tostring(id)
end)
local wildcard = bus:on("user.*", function(event)
  log[#log + 1] = "wild:" .. event
end)
bus:on("*", function(event)
  log[#log + 1] = "all:" .. event
end)

assert(bus:emit("user.created", 42) == 3)
assert(#log == 3)
assert(log[1] == "exact:user.created:42")   -- subscription order is kept
assert(log[2] == "wild:user.created")
assert(log[3] == "all:user.created")

-- A wildcard does not match a different prefix.
log = {}
assert(bus:emit("order.created") == 1)
assert(log[1] == "all:order.created")

-- off() detaches the handler: it is not called any more ...
log = {}
assert(bus:off("user.*", wildcard) == 1)
assert(bus:emit("user.created", 42) == 2)
assert(log[1] == "exact:user.created:42")
assert(log[2] == "all:user.created")

-- ... and it is not referenced by the bus any more.
assert(#bus.subscriptions == 2)

-- off() without a handler removes every subscription of that pattern.
bus:on("temp", function() end)
bus:on("temp", function() end)
assert(bus:off("temp") == 2)
assert(#bus.subscriptions == 2)

print("event bus: all tests passed")
```

**Key points**:
- All subscriptions live in one ordered list, so `emit` calls the handlers in *global subscription order* — not grouped per pattern. Handlers of `"user.*"` and `"user.created"` therefore interleave exactly as they were registered.
- A pattern is matched by a plain prefix test; `"user.*"` matches `"user.created"` and `"user.created.v2"`, but not `"user"`. The bare pattern `"*"` matches every event.
- `on` returns the handler so the caller can pass it to `off`; `off` rebuilds the list instead of leaving holes, so a removed handler is no longer referenced by the bus (no leak).
- `off(pattern, nil)` removes every handler of a pattern, which is the bulk-unsubscribe operation.
- `emit` returns the number of handlers called, which is enough to test dispatch without inspecting the internal list.
- Handler errors are not caught here: a failing handler aborts the dispatch. Wrap the call in `pcall` if the bus must survive handler failures.

---

## Project 4: Test Framework Basics

**Task**: Implement a minimal `describe`/`it`/`assert` test runner — `describe(name, fn)`, `it(name, fn)`, `assert.eq(a, b)`, `assert.truthy(v)`, `assert.errors(fn)`, `run_all()`.

**Solution**:

```lua
-- Project 4: a minimal describe/it/assert runner.
-- The runner keeps the real assert in builtin_assert and shadows it with an
-- assert object that carries the eq/truthy/errors helpers.

local builtin_assert = assert

--- Render a value for a failure message.
-- @param value any value
-- @return string
local function show(value)
  if type(value) == "string" then
    return string.format("%q", value)
  end
  return tostring(value)
end

-- The learner-facing assertion object.
local assert = {}

--- Assert that two values are equal.
-- @param actual value under test
-- @param expected expected value
function assert.eq(actual, expected)
  if actual ~= expected then
    error(string.format("expected %s, got %s", show(expected), show(actual)), 2)
  end
  return true
end

--- Assert that a value is truthy.
-- @param value value under test
function assert.truthy(value)
  if not value then
    error(string.format("expected a truthy value, got %s", show(value)), 2)
  end
  return true
end

--- Assert that a function raises an error, and return the error.
-- @param fn function that must fail
-- @return the error message
function assert.errors(fn)
  local ok, err = pcall(fn)
  if ok then
    error("expected the function to raise an error, but it returned normally", 2)
  end
  return err
end

local suites = {}
local current

--- Group tests under a name.
-- @param name suite name
-- @param fn function that calls it()
function describe(name, fn)
  local suite = { name = name, tests = {} }
  suites[#suites + 1] = suite
  local previous = current
  current = suite
  local ok, err = pcall(fn)                  -- a broken describe body must not
  current = previous                        -- abort the whole run
  if not ok then
    suite.tests[#suite.tests + 1] = {
      name = "describe body failed",
      fn = function() error(err, 0) end,
    }
  end
end

--- Register a test in the current suite.
-- @param name test name
-- @param fn test body
function it(name, fn)
  builtin_assert(current, "it() must be called inside describe()")
  current.tests[#current.tests + 1] = { name = name, fn = fn }
end

--- Run every registered test.
-- @return number of passed tests, number of failed tests
function run_all()
  local passed, failed = 0, 0
  for _, suite in ipairs(suites) do
    print(suite.name)
    for _, test in ipairs(suite.tests) do
      local ok, err = pcall(test.fn)        -- each test is isolated
      if ok then
        passed = passed + 1
        print("  ok   " .. test.name)
      else
        failed = failed + 1
        print("  FAIL " .. test.name .. ": " .. tostring(err))
      end
    end
  end
  print(string.format("\n%d passed, %d failed", passed, failed))
  return passed, failed
end

-- Tests for the framework itself.
describe("assert helpers", function()
  it("eq accepts equal values", function()
    assert.eq(1, 1)
    assert.eq("lua", "lua")
  end)

  it("eq reports the expected and the actual value", function()
    local ok, err = pcall(function() assert.eq("actual", "expected") end)
    builtin_assert(not ok)
    builtin_assert(tostring(err):find("expected", 1, true) ~= nil)
    builtin_assert(tostring(err):find("actual", 1, true) ~= nil)
  end)

  it("truthy accepts truthy values", function()
    assert.truthy(1)
    assert.truthy("x")
  end)

  it("truthy rejects nil and false", function()
    builtin_assert(not pcall(function() assert.truthy(nil) end))
    builtin_assert(not pcall(function() assert.truthy(false) end))
  end)

  it("errors returns the raised message", function()
    local err = assert.errors(function() error("boom") end)
    builtin_assert(tostring(err):find("boom", 1, true) ~= nil)
  end)

  it("errors fails when the function does not raise", function()
    builtin_assert(not pcall(function()
      assert.errors(function() return 1 end)
    end))
  end)
end)

describe("runner", function()
  it("collected the suites", function()
    builtin_assert(#suites >= 1)
  end)

  it("counts every test", function()
    builtin_assert(#suites[1].tests >= 1)
  end)
end)

local passed, failed = run_all()
builtin_assert(failed == 0)
builtin_assert(passed > 0)

print("test framework: all tests passed")
```

**Key points**:
- `describe` only collects tests, `run_all` executes them: the suite bodies run at load time, the test bodies run later. That keeps registration cheap and the output ordered.
- `it` is only valid inside `describe`; the `builtin_assert` in `it` catches a misplaced call at registration time instead of at run time.
- `pcall` isolates three different things: a failing test body, a failing `describe` body (recorded as a failing test instead of aborting the run) and the assertion helpers themselves.
- The failure message of `assert.eq` prints the expected value first and the actual value second, so a red test says what was wanted and what was produced.
- `assert` is a local table in this chunk, shadowing the global `assert`; the real one is kept as `builtin_assert` for the framework's own checks. In a real project the object would live in a module, not in a global.
- `run_all` returns the two counters, so a CI script can fail the build on `failed > 0`.

---

## Debugging Task 1: Infinite recursion in `__index`

**Task**: Explain why an `__index` that indexes the same table loops, and what the correct `__index` pattern is.

**Buggy code**:

```lua
local mt = {}
mt.__index = function(t, k) return t[k] end
local t = setmetatable({}, mt)
print(t.foo)  -- stack overflow
```

**Fixed code**:

```lua
-- __index must resolve a key somewhere else: another table, or a function
-- that reads another table. It must never index the object it is attached
-- to.
local defaults = { greeting = "hello" }

local mt = {
  __index = function(_, key)
    return defaults[key]
  end,
}

local t = setmetatable({}, mt)
print(t.greeting)   --> hello
print(t.missing)    --> nil

-- A table-valued __index is fine too, as long as that table is not the
-- metatable itself.
local base = { a = 1 }
local mt2 = { __index = base }
local t2 = setmetatable({}, mt2)
print(t2.a)         --> 1

-- The real infinite recursion: __index indexes the same table again, so the
-- metatable dispatch never reaches a raw value. The C stack runs out and
-- Lua raises a catchable "stack overflow" error.
local function make_recursive()
  local bad = {}
  bad.__index = function(tbl, key)
    return tbl[key]
  end
  return setmetatable({}, bad)
end

local ok, err = pcall(function()
  return make_recursive().missing
end)
print(ok, err)     --> false  ... stack overflow ...
```

**Why it happens**:
- As written, the snippet does not even recurse: the scope of a local starts *after* its declaration, so the `mt` inside the table constructor still refers to the global `mt`, which is `nil`. The metatable ends up with `__index = nil` and `print(t.foo)` prints `nil` — verified on Lua 5.1.5, 5.4.9, 5.5.1 and LuaJIT 2.1, no stack overflow.
- Even a real self-reference (`mt.__index = mt`) would not recurse. A table-valued `__index` performs exactly one more lookup on that table, and `mt` has no metatable of its own, so the lookup ends with `nil`.
- The genuine infinite recursion needs `__index` to be a *function* that indexes the same table again (`__index = function(t, k) return t[k] end`). The metatable dispatch then re-enters the metamethod forever and the C stack is exhausted — Lua turns that into a catchable `stack overflow` error, as the `pcall` in the fixed code shows.
- The correct pattern is to keep the lookup *outside* the object: `__index` points at a separate defaults table, or is a function that reads one. Read-only proxies and class instances both use that shape.
- A shared `__index` table is the normal way to implement a class: `Account.__index = Account` works because `Account` is a *different* table from the instances that carry it as their metatable.

---

## Debugging Task 2: Coroutine starvation

**Task**: A scheduler runs 3 coroutines but one never yields and monopolizes the CPU — diagnose the starvation and propose a fix.

**Buggy code**:

```lua
-- A round-robin scheduler that hands out slices without bounding the work
-- inside a slice.
local progress = 0                 -- shared by all tasks: work done so far

local function new_worker(name, steps)
  return coroutine.create(function()
    for step = 1, steps do
      progress = progress + 1
      coroutine.yield()
    end
  end)
end

-- The hog: it never yields, so a single resume() call runs the whole
-- workload and the scheduler gets no control back in between.
local function new_hog(work)
  return coroutine.create(function()
    for i = 1, work do
      local x = i * 2                  -- busy work, no yield
    end
    progress = progress + work
  end)
end

local function run_buggy(tasks)
  local log = {}
  local queue = tasks
  while #queue > 0 do
    local task = table.remove(queue, 1)
    log[#log + 1] = string.format("slice -> %-9s (progress %d)", task.name, progress)
    local ok, err = coroutine.resume(task.co)
    if not ok then
      log[#log + 1] = task.name .. " error: " .. tostring(err)
    end
    if coroutine.status(task.co) == "dead" then
      log[#log + 1] = string.format("%-9s finished (progress %d)", task.name, progress)
    else
      log[#log + 1] = string.format("%-9s yielded (progress %d)", task.name, progress)
      table.insert(queue, task)         -- requeue for the next round
    end
  end
  return log
end

local log = run_buggy({
  { name = "hog",      co = new_hog(200000) },
  { name = "worker-a", co = new_worker("worker-a", 2) },
  { name = "worker-b", co = new_worker("worker-b", 2) },
})

for _, line in ipairs(log) do
  print(line)
end

-- The hog got the first slice and ran its whole workload inside it, so
-- the workers only got their first slice once all 200000 units were done.
local first_worker_slice
for _, line in ipairs(log) do
  if line:find("worker", 1, true) then
    first_worker_slice = line
    break
  end
end
assert(first_worker_slice:find("progress 200000", 1, true) ~= nil)
```

**Fixed code**:

```lua
-- FIX: every slice gets an instruction budget.
--
-- debug.sethook() installs a count hook on the coroutine: it fires every
-- `step` VM instructions and can abort the coroutine by raising an error.
-- That is the only way to preempt a coroutine that never yields.
--
-- LuaJIT does not call debug hooks from JIT compiled code, so the JIT is
-- switched off (and its traces dropped) for this measurement. On the
-- reference interpreters the branch is simply not taken.
local jitlib = rawget(_G, "jit")
if jitlib and jitlib.off and jitlib.flush then
  jitlib.off()
  jitlib.flush()
end

local STEP = 100                -- hook granularity, in VM instructions
local SLOW_SLICE = 0.05         -- wall-clock watchdog, in seconds

--- Resume a coroutine with an instruction budget.
-- @param co coroutine
-- @param budget instructions allowed in this slice
-- @return ok, err, instructions used, soft limit exceeded
local function resume_with_budget(co, budget)
  local used = 0
  local over = false
  debug.sethook(co, function()
    used = used + STEP
    if used > budget * 2 then
      error("hard limit exceeded", 0)     -- abort the coroutine
    elseif used > budget then
      over = true                          -- used more than its quantum
    end
  end, "", STEP)
  local started = os.clock()
  local ok, err = coroutine.resume(co)
  local elapsed = os.clock() - started
  debug.sethook(co)                       -- remove the hook again
  return ok, err, used, over, elapsed
end

--- Run the tasks round-robin, penalising tasks that exceed their budget.
-- @param tasks array of {name = ..., co = ..., budget = ...}
-- @return log lines, number of violations
local function run(tasks)
  local log = {}
  local queue = tasks
  local violations = 0

  while #queue > 0 do
    local task = table.remove(queue, 1)
    local ok, err, used, over, elapsed = resume_with_budget(task.co, task.budget)

    if not ok then
      violations = violations + 1
      log[#log + 1] = task.name .. ": terminated (" .. tostring(err) .. ")"
      -- PENALTY: a task that ignores its budget loses the right to run
    elseif over or elapsed > SLOW_SLICE then
      violations = violations + 1
      task.budget = math.max(STEP, math.floor(task.budget / 2))
      log[#log + 1] = task.name .. ": over budget, budget reduced to " .. task.budget
      table.insert(queue, task)            -- and pushed to the back
    elseif coroutine.status(task.co) == "dead" then
      log[#log + 1] = task.name .. ": finished"
    else
      table.insert(queue, task)
    end
  end

  return log, violations
end

local function new_worker(name, steps)
  return coroutine.create(function()
    for step = 1, steps do
      coroutine.yield(name .. " step " .. step)
    end
  end)
end

local function new_hog(work)
  return coroutine.create(function()
    for i = 1, work do
      local x = i * 2
    end
  end)
end

-- A task that yields often but still burns a lot of CPU per slice.
local function new_greedy(work, steps)
  return coroutine.create(function()
    for step = 1, steps do
      for i = 1, work do
        local x = i * 2
      end
      coroutine.yield("greedy step " .. step)
    end
  end)
end

local log, violations = run({
  { name = "hog",      co = new_hog(200000),        budget = 2000 },
  { name = "worker-a", co = new_worker("worker-a", 2), budget = 1000000 },
  { name = "worker-b", co = new_worker("worker-b", 2), budget = 1000000 },
  { name = "greedy",   co = new_greedy(30000, 2),   budget = 50000 },
})

for _, line in ipairs(log) do
  print(line)
end
print("violations: " .. violations)

-- The hog is terminated inside its first slice, so the other tasks run
-- while it is still pending.
local hog_stopped = false
for _, line in ipairs(log) do
  if line:find("hog: terminated", 1, true) then
    hog_stopped = true
  end
end
assert(hog_stopped, "the hog must be stopped inside its first slice")
assert(violations >= 1)

if jitlib and jitlib.on then
  jitlib.on()                              -- give the JIT back
end
```

**Why it happens**:
- `coroutine.resume` only returns when the coroutine yields or dies. A coroutine that never yields therefore blocks the scheduler *inside a single resume call*: the scheduler is not running at all, so no amount of round-robin bookkeeping can help.
- Round-robin fairness is measured in slices, not in time. A scheduler that hands out slices without bounding the work inside a slice has no fairness guarantee — the hog's first slice contains 100% of its workload, and every other task is starved until it finishes.
- Detection: install a count hook on the coroutine with `debug.sethook(co, hook, "", count)`. The hook fires every `count` VM instructions of that coroutine and can abort it by raising an error, which is the only way to preempt a coroutine that never yields. Measuring the slice with `os.clock()` adds a wall-clock signal for tasks that yield often but still take a long time.
- Penalty: on a violation either terminate the coroutine or demote it — halve its quantum and push it to the back of the queue, as the fixed code does for the greedy task. Count the violations per task; a task that trips the limit repeatedly is a bug in that task, not in the scheduler.
- LuaJIT caveat: LuaJIT does not call debug hooks from JIT compiled code, so the hook fires once instead of once per `count` instructions and the budget is never enforced. The fixed code therefore switches the JIT off (`jit.off()` plus `jit.flush()` to drop the traces that were already compiled) and gives it back at the end; on the reference interpreters the branch is not taken. Scoping the switch to the task functions (`jit.off(func, true)`) is the better production variant.
- Limit: the hook counts Lua VM instructions, so a single long C call (a huge `string.rep`, a slow I/O call) cannot be interrupted in-process. The only complete remedy for untrusted work is to isolate it in another process.

---

## Debugging Task 3: Module re-initialization bug

**Task**: A module keeps its state in a local; after `package.loaded` is cleared and `require` is called again the state resets — what does `require` guarantee about single initialization?

**Buggy code**:

```lua
-- The module keeps its state in a local, so the state lives exactly as long
-- as the module instance that require() cached.
package.preload["counter"] = function()
  local count = 0
  local M = {}
  function M.increment() count = count + 1; return count end
  function M.value() return count end
  return M
end

package.loaded["counter"] = nil            -- start from a clean cache
local counter = require("counter")

counter.increment()
counter.increment()
print("before reload:", counter.value())   --> 2

-- Clearing the cache entry makes require() run the chunk again ...
package.loaded["counter"] = nil
local reloaded = require("counter")
-- ... and the module starts over with a fresh local:
print("after reload:", reloaded.value())    --> 0  (the state is gone)
print("same instance:", tostring(reloaded == counter))  --> false
```

**Fixed code**:

```lua
-- FIX: keep the state in a registry that outlives the package.loaded entry.
-- The registry lives in _G, so a reload of the module finds the state that
-- is already there and returns the very same instance.
local registry = {}
rawset(_G, "__APP_STATE__", registry)

package.preload["counter"] = function()
  local M = registry["counter"]
  if M == nil then
    local count = 0
    M = {}
    function M.increment() count = count + 1; return count end
    function M.value() return count end
    registry["counter"] = M                -- publish the instance
  end
  return M
end

package.loaded["counter"] = nil
local counter = require("counter")
counter.increment()
counter.increment()
assert(counter.value() == 2)

-- Reloading the module keeps the same instance and the same state.
package.loaded["counter"] = nil
local reloaded = require("counter")
assert(reloaded == counter)                -- same instance
assert(reloaded.value() == 2)              -- state survived the reload
assert(reloaded.increment() == 3)          -- and it is still usable

-- A module that owns no state needs no registry: require() already
-- guarantees that its chunk runs once per cache entry.
package.preload["pure"] = function()
  return { hello = function() return "hi" end }
end
package.loaded["pure"] = nil
local first = require("pure")
local second = require("pure")
assert(first == second)                   -- the cached value is reused

print("module state: all tests passed")
```

**Why it happens**:
- `require` guarantees exactly two things: the loader is called at most once while `package.loaded[name]` holds a value, and the value returned by the loader is cached and handed to every later `require`. That is all — it is a cache, not a state manager.
- `package.loaded[name] = nil` removes the cache entry, so the next `require` runs the chunk again. A fresh chunk means fresh locals, so a module that keeps its state in a local starts from scratch. The old instance is not corrupted; it is simply no longer the module.
- The failure mode is therefore a *split brain*: the application holds the old table, `require` hands out a new one, and code that mixes the two sees two different states.
- The fix is to move the state out of the module's locals into an owner that outlives the cache entry — a registry in `_G`, a table owned by the application, or any other long-lived store. The module then looks the state up on load and reuses it, which is what the fixed code does with `registry["counter"]`.
- A hot-reload workflow should do the same thing explicitly: create the new instance, copy the state over from the old one, and only then replace the cache entry.
- If the module holds no state, none of this is needed — the cached value is reused, and the same module name always yields the same table.

---

## Debugging Task 4: Shared metatable mutation

**Task**: Two instances share one metatable and mutating one instance's metatable affects the other — identify the mistake and fix it.

**Buggy code**:

```lua
-- BUG: the class table doubles as the shared metatable, and the instance
-- method stores per-instance data inside it.
local Point = {}
Point.__index = Point

function Point.new(x, y)
  local self = { x = x, y = y }
  setmetatable(self, Point)              -- every instance shares this metatable
  return self
end

function Point:setLabel(text)
  getmetatable(self).label = text        -- writes into the SHARED metatable
  return self
end

function Point:describe()
  return string.format("(%s,%s) label=%s", tostring(self.x), tostring(self.y),
                        tostring(getmetatable(self).label))
end

local a = Point.new(1, 2)
local b = Point.new(3, 4)

a:setLabel("A")
print(b:describe())   -- BUG: "(3,4) label=A" -- b was corrupted through a
```

**Fixed code**:

```lua
-- FIX 1 (preferred): per-instance data lives in the instance table, the
-- metatable stays shared and read-only.
local Point = {}
Point.__index = Point

function Point.new(x, y)
  return setmetatable({ x = x, y = y, label = nil }, Point)
end

function Point:setLabel(text)
  self.label = text
  return self
end

function Point:describe()
  return string.format("(%s,%s) label=%s", tostring(self.x), tostring(self.y),
                        tostring(self.label))
end

local a = Point.new(1, 2)
local b = Point.new(3, 4)

a:setLabel("A")
assert(a:describe() == "(1,2) label=A")
assert(b:describe() == "(3,4) label=nil")   -- b is untouched
assert(getmetatable(a) == getmetatable(b))  -- the metatable is still shared

-- FIX 2: when the metamethods themselves must differ per instance, give the
-- instance its own metatable: a copy of the shared one.
local function new_isolated(x, y)
  local meta = {}
  for k, v in pairs(Point) do meta[k] = v end    -- copy the class table
  local self = setmetatable({ x = x, y = y }, meta)
  self.setLabel = function(self, text)
    getmetatable(self).label = text             -- only this instance's copy
    return self
  end
  return self
end

local c = new_isolated(5, 6)
local d = new_isolated(7, 8)
c.setLabel(c, "C")

assert(getmetatable(c) ~= getmetatable(d))      -- separate metatables
assert(getmetatable(c).label == "C")
assert(getmetatable(d).label == nil)            -- d is unaffected
assert(Point.label == nil)                      -- the class table is untouched

print("metatable: all tests passed")
```

**Why it happens**:
- A metatable is just a table, and `setmetatable(self, Point)` gives every instance a *reference to the same table*. Anything written into that table is visible to all instances — and to the class itself.
- The mistake is not the shared metatable itself, it is the *per-instance data stored inside it*. `getmetatable(self).label = text` writes into the class table, so the label of the last instance to call `setLabel` is the label of all of them.
- Fix 1 is the rule to remember: per-instance state belongs in the instance table (`self.label = text`); the metatable holds behaviour, not data. A shared metatable is then both correct and the cheapest option — one metatable for the whole class.
- Fix 2 is for the case where the metamethods really must differ per instance (a different comparison function, a per-instance cache). Then the instance gets its own metatable, copied from the class, so mutating it cannot affect the class or the other instances.
- `getmetatable(obj)` is the escape hatch that makes the bug visible: two objects that are supposed to be independent return the *same* metatable, so anything stored there is shared state.
- The same trap appears with `__index` functions that cache results in the metatable, and with classes that store their instance list in the class table.

---

## Debugging Task 5: Closure loop capture

**Task**: Explain what the closures created inside a `for` body capture, and give a version-independent fix.

**Buggy code**:

```lua
local fns = {}
for i = 1, 5 do
  fns[i] = function() return i end
end
print(fns[1](), fns[3]())  -- prints 1, 3 — every iteration gets its own `i`
```

**Fixed code**:

```lua
-- FIX: bind the value to a fresh local of the loop body. This is the
-- portable idiom and it does not depend on the scoping rules of the
-- running Lua version.
local fns = {}
for i = 1, 5 do
  local j = i
  fns[i] = function() return j end
end

assert(fns[1]() == 1)
assert(fns[3]() == 3)
assert(fns[5]() == 5)

-- The genuine "closures capture the variable, not the value" bug is
-- version-independent: here every closure shares one local, so all of them
-- report the final value.
local i = 0
local shared = {}
while i < 3 do
  i = i + 1
  shared[i] = function() return i end
end
assert(shared[1]() == 3 and shared[2]() == 3 and shared[3]() == 3)

-- The fix for that case: take a snapshot of the value.
i = 0
local fixed = {}
while i < 3 do
  i = i + 1
  local snapshot = i
  fixed[i] = function() return snapshot end
end
assert(fixed[1]() == 1 and fixed[2]() == 2 and fixed[3]() == 3)

print("closure capture: all tests passed")
```

**Why it happens**:
- The comment in the exercise is wrong for the numeric `for` loop: the snippet prints `1 3`, not `5 5`. Verified on Lua 5.1.5, 5.4.9, 5.5.1 and LuaJIT 2.1.
- The Lua 5.1 manual states the numeric `for` as `while ... do local v = var; <block>; var = var + step end` — the control variable is declared *inside* the loop body, so every iteration has its own variable. The Lua 5.4 manual says the same ("a new variable local to the loop body"), and the only change 5.4 made to the numeric `for` was that the control variable no longer wraps around on integer overflow. There is no 5.1-versus-5.3/5.4 difference here.
- The real rule is the one the exercise is aiming at: a closure captures a *variable*, not a value, and it sees every later change of that variable. The version-independent reproduction is a local that several closures share — the `while` loop above, where all three closures report `3` on every version tested.
- `local j = i` inside the loop body is the fix that works everywhere: it creates a fresh variable (upvalue) per iteration whose value never changes afterwards. It costs one local per iteration, and it is the form to use when the captured value must be a snapshot.
- The same hazard exists outside loops: any local that is captured by more than one closure and then modified afterwards is shared state. Capture a copy, or capture a table and put the per-closure data in it.

---

## Debugging Task 6: In-place sort side effect

**Task**: `table.sort` mutates its input, so a function that sorts a list silently modifies the caller's data — how can the caller's data be protected, and what does it cost?

**Buggy code**:

```lua
-- BUG: table.sort sorts in place, so the caller's table is reordered.
local function sort_by_name(items)
  table.sort(items, function(a, b) return a.name < b.name end)
  return items
end

local inventory = {
  { name = "carol" },
  { name = "alice" },
  { name = "bob" },
}

local sorted = sort_by_name(inventory)

print(inventory[1].name)   -- BUG: "alice" -- the caller's order is gone
print(sorted[1].name)      --> "alice"
print(#inventory)          --> 3
```

**Fixed code**:

```lua
-- FIX: copy the list before sorting it.
local function sort_by_name(items)
  local copy = {}
  for i = 1, #items do
    copy[i] = items[i]
  end
  table.sort(copy, function(a, b) return a.name < b.name end)
  return copy
end

local inventory = {
  { name = "carol" },
  { name = "alice" },
  { name = "bob" },
}

local sorted = sort_by_name(inventory)

assert(inventory[1].name == "carol")   -- the caller's data is untouched
assert(inventory[2].name == "alice")
assert(sorted[1].name == "alice")      -- the sorted list is a new table
assert(sorted ~= inventory)

-- Alternative: sort an index permutation. The payload is not copied at all
-- and the original order stays available.
local function sorted_indices(items)
  local order = {}
  for i = 1, #items do
    order[i] = i
  end
  table.sort(order, function(i, j) return items[i].name < items[j].name end)
  return order
end

local order = sorted_indices(inventory)
assert(inventory[1].name == "carol")
assert(inventory[order[1]].name == "alice")
assert(#order == #inventory)

-- Alternative: make the mutation explicit in the API.
local function sort_in_place(items)
  table.sort(items, function(a, b) return a.name < b.name end)
  return items
end

local owned = { { name = "bob" }, { name = "alice" } }
sort_in_place(owned)
assert(owned[1].name == "alice")

print("sort: all tests passed")
```

**Why it happens**:
- `table.sort` rearranges the table it is given; it is not a pure function. Returning the same table after sorting means the caller receives an object that is still aliased by the input, so both names point at one sorted table.
- The copy in the fixed code is *shallow*: the elements themselves are shared with the caller. A comparator that mutates an element still corrupts the caller's data — that needs a deep copy, which costs proportionally more.
- The price of the copy is O(n) time and O(n) extra memory per call. `table.sort` itself is O(n log n), so for a large list the copy is a constant-factor cost, not a change in complexity — but it is paid on every call, and it doubles the peak memory of the list.
- Sorting an index permutation has the same O(n) memory but copies no payload, and it keeps the original order available; the price is a comparator that works on indices and an extra indirection on every access.
- The third option is to make the contract explicit: a function called `sort_in_place` documents that it mutates its argument, and the caller keeps a reference to the result. That is free, but it only works when every caller knows the rule.
- Whichever contract is chosen, it should be visible in the name: `sort_by_name` that copies and `sort_by_name_in_place` that mutates cannot be mixed up by accident.

---

## Design Question 1: Error philosophy

*When should a module return `nil, err` versus raising `error()`? Consider API ergonomics, caller responsibility, and debuggability.*

**Answer**:

The dividing line is **"can the caller do something different?"** If the caller has a recovery action — retry, fall back, report to a user, skip the record — return `nil, err`. If the failure means "this program is wrong and no continuation is meaningful", raise. Everything else is a preference, and preferences should be applied consistently within a codebase, not per call site.

`nil, err` composes; `error()` destroys the return channel. A returning API nests naturally (`local v, e = parse(read(f))`), while a raising API forces every intermediate layer to wrap the call in `pcall` just to forward the message — which turns a data-flow problem into control-flow plumbing, and re-raising with `error(err, 0)` produces a *new* traceback that no longer points at the original failure. The cheapness of `pcall` is not the real cost; the cost is that every call site becomes two lines and every layer becomes a potential message-mangler. That is why libraries should default to returning.

`error()` still wins in three specific cases. First, **programmer errors**: a wrong argument type is a bug, and failing at the boundary keeps the stack trace pointing at the real culprit instead of at a `nil` dereference three frames later that nobody traced back to the missing check. `assert(type(x) == "table", "x must be a table")` is the right tool there. Second, **broken invariants** — "the queue is non-empty here" must never be false, and returning `nil, err` for it just creates a second code path that nobody tests. Third, **failures that must not be ignorable**: a forgotten `if not result then` check turns a clean error message into an unrelated crash later.

The Lua-specific details that decide the mechanics: `error(msg)` defaults to level 1, which blames the line *inside your module* — use level 2 to blame the caller for argument errors, and level 0 for messages you have already decorated. `nil` versus `false` matters for the failure test: `if not result then` treats a legitimate `false` result as a failure, so pick one convention (`nil` means failure, or `false` means failure) and never mix them. Structured error objects survive `pcall` unchanged, so `error({code = "ENOENT", ...})` lets callers branch on a machine-readable code — but only if you add a `__tostring` metamethod, otherwise the message renders as `table: 0x...`. And `error()` inside a coroutine is *local*: the coroutine dies, `coroutine.resume` returns `false, err`, and the program keeps running — which means "raise or return" is partly a question of which boundary owns the failure.

```lua
-- A module offering both styles, plus a structured error type.
local M = {}

-- Soft failure: the caller can branch and do something different.
function M.parse(text)
  if type(text) ~= "string" or text == "" then
    return nil, "expected a non-empty string"
  end
  return { value = text }
end

-- Hard failure: a broken contract. Level 2 blames the caller, not this file.
function M.parse_strict(text)
  local ok, res = M.parse(text)
  if not ok then
    error(res, 2)
  end
  return res
end

-- Structured errors survive pcall, but need __tostring to stay printable.
local Err = {}
function Err.__tostring(self)
  return self.code .. ": " .. self.message
end

function M.fail(code, message)
  error(setmetatable({ code = code, message = message }, Err), 0)
end

-- pcall keeps the error object intact.
local ok, err = pcall(function() M.fail("ENOENT", "no such file") end)
assert(ok == false)
assert(err.code == "ENOENT")
print(tostring(err))                          --> ENOENT: no such file

-- Inside a coroutine, error() is a local failure: resume returns false, err.
local co = coroutine.create(function() M.fail("EBADF", "bad descriptor") end)
local cok, cerr = coroutine.resume(co)
assert(cok == false)
assert(cerr.code == "EBADF")

-- The boundary that keeps a traceback: debug.traceback cannot stringify a
-- non-string error value, so normalise it first.
local function run(f)
  return xpcall(f, function(e)
    return debug.traceback(tostring(e), 2)
  end)
end
local rok, rerr = run(function() M.parse_strict(42) end)
assert(rok == false)
print(rerr)                                    -- message + traceback
```

**In practice**:
- Return `nil, err` (or `false, err`) for input validation and lookup misses inside library modules; reserve `error()`/`assert` for broken invariants and wrong argument types.
- Use `error(msg, 2)` for argument errors and `error(msg, 0)` for pre-formatted messages; the default level 1 blames your own file.
- Return a structured error table with a `__tostring` metamethod if callers need to branch on an error code.
- Capture the traceback once at the boundary: `xpcall(f, function(e) return debug.traceback(tostring(e), 2) end)` — `debug.traceback` alone cannot handle a non-string error value: handed a table it returns the table itself, and a `nil` error yields `nil` on 5.1/LuaJIT, so you lose the traceback entirely.
- In a coroutine, treat `error()` as a local failure that `coroutine.resume` turns into `false, err`; decide which layer converts it back into a return value.
- Never call `os.exit` inside a library: it terminates the process without running `__gc` finalizers, so pending cleanup is lost, whereas `error()` unwinds and leaves reclamation to the garbage collector.

## Design Question 2: Event bus memory management

*How would you design an event bus API to prevent handler leaks? What mechanisms clean up handlers when subscribers are garbage collected?*

**Answer**:

The leak has a fixed shape: the bus holds a strong reference to the handler closure, the closure captures the subscriber as an upvalue, so the subscriber can never be collected while the bus is alive. Lua's mark-and-sweep GC does not break this, because the whole graph is reachable from the bus — and the bus is usually reachable from `package.loaded`, which means it is reachable from every later `require` in the process.

The position that fixes it: **the bus must not own its subscribers; the subscriber owns its subscriptions.** The bus stores handlers in tables with `__mode = "v"` (weak values), so a handler stays alive only while something else — normally the subscriber — still references it. When the subscriber dies, the handler becomes unreachable, the weak table drops the entry, and both are collected in the same cycle. The non-obvious consequence is that the API must hand the subscriber a strong handle on the handler it registered: if `bus:on("tick", fn)` is called and the caller drops `fn` immediately, the subscription can evaporate at the next collection. So `on()` returns a token, and "keep the token for as long as you want the subscription" is part of the contract.

Each cleanup mechanism has a distinct failure mode, which is why production buses usually offer more than one:
- **Weak values** (`__mode = "v"`) are automatic but GC-timed: a dead subscriber may still receive one final event before the collection runs. Fine for UI and plugin systems, surprising for accounting code.
- **Weak keys** (`__mode = "k"`) work when the registry is keyed by the subscriber object. They do not free a handler whose upvalue is the subscriber if something else still holds the handler.
- **Explicit unsubscription** is deterministic and GC-independent. This is the only mechanism that works uniformly for tables in Lua 5.1 and LuaJIT, because `__gc` finalizers there run **only for userdata** — a table's `__gc` metamethod is simply never called. If you want finalizer-based cleanup in 5.1, the subscription itself must be userdata.
- **Scoped subscriptions** tie a group of handlers to an owning object and close the whole scope at once, which is usually how UI screens and request handlers should be released.

Two further Lua-specific leak sources deserve attention in the design. First, the **`_ENV` upvalue**: in 5.2+ a chunk's environment is a normal upvalue, so a handler defined at the top level of a module captures that module's environment, and with it any module-level cache or registry the environment holds. Second, **`package.loaded` caching**: a module-level bus table survives every reload and every test, so the bus instance should live in a local with an exported factory, and tests should clear `package.loaded["bus"] = nil` deliberately.

```lua
-- The bus holds handlers weakly; the subscriber owns its subscription.
local Bus = {}
Bus.__index = Bus

function Bus.new()
  return setmetatable({ handlers = {}, next_id = 0 }, Bus)
end

function Bus:on(event, fn)
  local list = self.handlers[event]
  if not list then
    list = setmetatable({}, { __mode = "v" })   -- the bus holds handlers weakly
    self.handlers[event] = list
  end
  self.next_id = self.next_id + 1
  local id = self.next_id
  list[id] = fn
  -- The token keeps fn alive: the subscriber must hold the token, otherwise
  -- the weak entry may vanish at the next collection.
  local token = { event = event, id = id, fn = fn }
  token.off = function() list[id] = nil end
  return token
end

function Bus:emit(event, ...)
  local list = self.handlers[event]
  if not list then return 0 end
  local n = 0
  for _, fn in pairs(list) do
    fn(...)
    n = n + 1
  end
  return n
end

local function attach(bus)
  local subscriber = { calls = 0 }
  subscriber.token = bus:on("tick", function()
    subscriber.calls = subscriber.calls + 1
  end)
  return subscriber
end

local bus = Bus.new()
local sub = attach(bus)
assert(bus:emit("tick") == 1)
assert(sub.calls == 1)

sub = nil                       -- the subscriber is now unreachable
collectgarbage("collect")
collectgarbage("collect")       -- closure dies first, subscriber after it
assert(bus:emit("tick") == 0)   -- the weak entry evaporated

-- Deterministic alternative: no GC involved.
local bus2 = Bus.new()
local sub2 = attach(bus2)
sub2.token.off()
assert(bus2:emit("tick") == 0)
```

**In practice**:
- Store handlers in per-event tables with `__mode = "v"`, and return a token that holds the handler; document "keep the token" as part of the `on()` contract.
- Provide `token.off()` for deterministic removal; prefer it in tests and in shutdown paths.
- Do not rely on `__gc` for tables — Lua 5.1 and LuaJIT never call it; use explicit `close()` methods or userdata-based subscriptions.
- Avoid capturing the module environment in handlers (the `_ENV` upvalue pins module state) and avoid capturing `self` wholesale when a small slice will do.
- Keep the bus instance in a module local with an exported factory; do not stash it in `package.loaded` if you need per-test buses.
- Treat "the handler vanished" as normal behaviour, not a bug: guard the call site when a subscription may outlive its owner.

## Design Question 3: Scheduler observability

*What metrics prove a coroutine scheduler is healthy in production? How would you detect starvation, excessive context switching, or unbounded queue growth?*

**Answer**:

Instrument at three levels — the turn (one `coroutine.resume`), the coroutine (its whole lifetime), and the queue (the scheduler) — and export counters for the first two and gauges for the third. A healthy scheduler has bounded queue depth, bounded turn latency and a fair distribution of waiting time; each of those is a number you can chart.

The first Lua-specific fact shapes everything: `coroutine.resume` is **cooperative**, so a coroutine that never yields cannot be preempted by the scheduler — there is no OS thread to interrupt it. The only way to bound a runaway coroutine is to run it under a **debug hook**: `debug.sethook(co, hook, "", 1)` installs a count hook on that specific thread (the optional thread argument exists in 5.1 and LuaJIT), and raising an error inside the hook aborts the coroutine. That converts starvation from "the process hangs forever" into "one coroutine dies with a budget error" — and it simultaneously produces the metric you need. The hook is per-thread, so each coroutine can get its own instruction budget without affecting the others. The price is performance: an active count hook keeps that thread in the interpreter, so treat budget enforcement as a debug-build or last-resort feature, not a normal-mode one.

The metrics that actually matter: **turn latency** (wall time per `resume`, p50/p99/max — the max is the starvation signal); **queue depth** at each turn, as a maximum plus a trend, because a depth that only grows means producers outrun consumers; **context switches per second** and switches per unit of work, since too many switches means coroutines yield too finely and too few means long unresponsive turns; **wait time per coroutine** since it was last scheduled, which is the real fairness metric — a coroutine whose wait grows without bound is starving even when the queue is short; **budget violations** counted by the hook; **errors per coroutine id**, because `coroutine.resume` returns `false, err` and a scheduler that ignores the first return value turns a failing coroutine into an infinite retry loop; and **GC pause cost**, since an incremental collection (`collectgarbage("step")`) inside one turn keeps the latency spike inside a single turn's budget instead of stalling the whole queue.

The detection rules follow directly: starvation is a turn over the wall-clock budget or a hook budget violation; excessive switching is switches/second above a baseline you measured on real traffic; unbounded growth is `depth` non-decreasing over a window while throughput stays flat — the queue is not draining. A per-coroutine cap on consecutive yields without progress catches the subtler case of a coroutine that yields constantly but does no work.

```lua
-- A scheduler that measures what actually breaks in production.
local function newScheduler(opts)
  opts = opts or {}
  return {
    ready = {},                    -- FIFO queue of suspended coroutines
    live = 0,
    stats = {
      switches = 0, errors = 0, budget_exceeded = 0,
      max_depth = 0, max_turn = 0, total_turn = 0,
    },
    quantum = opts.quantum or 10000,   -- instructions allowed per turn
  }
end

local function schedule(sched, fn)
  local co = coroutine.create(fn)
  sched.live = sched.live + 1
  table.insert(sched.ready, co)
  return co
end

local function run(sched)
  while #sched.ready > 0 do
    local co = table.remove(sched.ready, 1)
    local depth = #sched.ready + 1
    if depth > sched.stats.max_depth then sched.stats.max_depth = depth end

    -- Instruction budget: the only way to stop a coroutine that never yields.
    local budget = sched.quantum
    debug.sethook(co, function()
      budget = budget - 1
      if budget <= 0 then
        debug.sethook(co)                  -- drop the hook before unwinding
        error("instruction budget exceeded", 0)
      end
    end, "", 1)

    local t0 = os.clock()
    local ok, err = coroutine.resume(co)
    local elapsed = os.clock() - t0
    debug.sethook(co)

    sched.stats.switches = sched.stats.switches + 1
    sched.stats.total_turn = sched.stats.total_turn + elapsed
    if elapsed > sched.stats.max_turn then sched.stats.max_turn = elapsed end

    if not ok then
      sched.stats.errors = sched.stats.errors + 1
      if type(err) == "string" and string.find(err, "budget", 1, true) then
        sched.stats.budget_exceeded = sched.stats.budget_exceeded + 1
      end
    end

    local status = coroutine.status(co)
    if status == "dead" then
      sched.live = sched.live - 1
    elseif status == "suspended" then
      table.insert(sched.ready, co)         -- yielded: back of the queue
    end
  end
end

local sched = newScheduler({ quantum = 5000 })

schedule(sched, function()
  for i = 1, 10 do
    coroutine.yield(i)
  end
end)

schedule(sched, function()
  while true do end          -- never yields: the classic starvation case
end)

run(sched)

assert(sched.stats.switches > 0)
assert(sched.stats.errors == 1)            -- the runaway coroutine was killed
assert(sched.stats.budget_exceeded == 1)
assert(sched.stats.max_depth >= 1)
```

**In practice**:
- Export counters (`switches`, `errors`, `budget_exceeded`) and gauges (`depth`, `live coroutines`); counters reset on scrape, gauges do not.
- Tag each coroutine with an id at creation so every metric can be attributed to a workload, not just to the scheduler.
- Install `debug.sethook(co, ...)` with a count mask only in debug builds or where a hard per-coroutine budget is a requirement; remember the JIT/interpreter cost.
- Always handle the `false, err` return of `coroutine.resume`: count it, park or kill the coroutine, never retry blindly.
- Use `os.clock()` for CPU cost per turn and a wall-clock source for latency; `os.clock()` alone hides a scheduler that is blocked rather than busy.
- Call `collectgarbage("step")` between turns so a collection cycle cannot blow the latency budget of every coroutine at once.

## Design Question 4: Configuration layering

*Design a system merging defaults, file, environment variables, and CLI flags. What merge semantics apply at each layer? How do you handle type conflicts?*

**Answer**:

The order is **defaults < file < environment < CLI flags**: later layers override earlier ones. The interesting part is what "override" means per value shape, and that is decided by the shape of the value rather than by the layer:
- **Scalars** (string, number, boolean): replace; last layer wins.
- **Maps**: deep merge per key, not wholesale replacement — `retry = {count = 5}` in a file must not erase `retry.backoff` from the defaults.
- **Arrays**: replace wholesale. Index-wise merging is never what the user meant; if concatenation is desired for a specific key, make it an explicit rule for that key.
- **Deletion**: Lua tables cannot store `nil`, so "explicitly unset" has no natural representation. A unique sentinel value (a table) that a layer can set is the only way to express "drop this key".

Type conflicts arise because the environment and the CLI can only carry strings, while the file carries real booleans and numbers. The resolution is to **coerce against the type of the value already present**: the defaults are the schema. If the current value is a number, `tonumber` the incoming string; if it is a boolean, parse the truthy set (`1/true/yes/on` versus `0/false/no/off`); if the coercion fails, record a conflict naming both layers instead of silently falling back to the default — a typo in a flag should be an error, not a quiet default.

Each layer has its own Lua-specific detail. The **defaults** table doubles as the schema: it types the values and defines the set of legal keys. The **file** layer should be data, not code; note that `loadfile` executes Lua and returns `nil, err` on failure rather than raising, which is itself an argument for a data format. The **environment** layer has two traps: `os.getenv` returns `nil` when a variable is unset but `""` when it is set to an empty string, and those are different states; and Lua has no portable way to enumerate the environment, so this layer needs an explicit key mapping (`APP_PORT` → `port`) rather than a scan. The **CLI** layer has a genuine Lua oddity: the standalone interpreter does **not** parse your script's flags. In the main chunk `arg[0]` is the script name and `arg[1]`, `arg[2]`, … are the script's arguments in order — `--verbose` arrives as the plain string `"--verbose"`, so writing the flag parser is your job. The **negative** indices of `arg` (`arg[-1]`, `arg[-2]`, …) hold the *interpreter's* own options and program name, not your script's flags, so mining them to rebuild a command line is a mistake. Worse, `arg` only exists for the main chunk, so a library that reads the global `arg` cannot be tested; pass the argument vector in as a parameter.

Finally, the merge itself must never mutate its base. The defaults live in a module-level local, and a merge that writes into the base corrupts the schema for every later call — the second call inherits the first call's overrides. Copy on merge, and copy nested tables too, because tables are references: a shallow assignment shares mutable state with the source layer. Relatedly, use `rawget` to tell "explicitly set" apart from "inherited from the defaults" when a `__index` defaults chain is in play.

```lua
-- Layered configuration: defaults < file < environment < CLI.
local UNSET = setmetatable({}, { __tostring = function() return "<unset>" end })

local DEFAULTS = {
  host = "127.0.0.1",
  port = 8080,
  verbose = false,
  retry = { count = 3, backoff = 0.5 },
  plugins = { "auth", "log" },
}

local function deepCopy(t)
  local out = {}
  for k, v in pairs(t) do
    if type(v) == "table" then out[k] = deepCopy(v) else out[k] = v end
  end
  return out
end

local function isArray(t)
  local n = 0
  for k in pairs(t) do
    if type(k) ~= "number" then return false end
    n = n + 1
  end
  return n == #t
end

local function merge(base, over)
  local out = deepCopy(base)                    -- never mutate the shared defaults
  for k, v in pairs(over) do
    if v == UNSET then
      out[k] = nil                              -- explicit "delete this key"
    elseif type(v) == "table" and type(out[k]) == "table" and not isArray(v) then
      out[k] = merge(out[k], v)                 -- maps merge per key
    else
      out[k] = v                                -- scalars and arrays replace
    end
  end
  return out
end

local function coerce(value, sample)
  if type(sample) == "boolean" then
    if type(value) == "boolean" then return value end
    local s = string.lower(tostring(value))
    if s == "1" or s == "true" or s == "yes" or s == "on" then return true end
    if s == "0" or s == "false" or s == "no" or s == "off" then return false end
    return nil, "not a boolean: " .. tostring(value)
  elseif type(sample) == "number" then
    if type(value) == "number" then return value end
    local n = tonumber(value)
    if n then return n end
    return nil, "not a number: " .. tostring(value)
  end
  return value
end

local function applyLayer(cfg, layer, source)
  local conflicts = {}
  local out = deepCopy(cfg)
  for k, v in pairs(layer) do
    if v == UNSET then
      out[k] = nil
    elseif type(out[k]) == "boolean" or type(out[k]) == "number" then
      local coerced, err = coerce(v, out[k])
      if coerced == nil then
        conflicts[#conflicts + 1] = source .. ":" .. k .. " " .. err
      else
        out[k] = coerced
      end
    else
      out[k] = v
    end
  end
  return out, conflicts
end

local function parseArgv(argv)
  local opts, positional = {}, {}
  local i = 1
  while i <= #argv do
    local a = argv[i]
    local name, value = a:match("^%-%-(%w[%w%-_]*)=(.*)$")
    if name then
      opts[name] = value
    elseif a:match("^%-%-") then
      opts[a:sub(3)] = true
    else
      positional[#positional + 1] = a
    end
    i = i + 1
  end
  return opts, positional
end

-- file layer
local cfg = merge(DEFAULTS, { port = 9000, retry = { count = 5 }, plugins = { "auth" } })
assert(cfg.port == 9000)
assert(cfg.retry.count == 5 and cfg.retry.backoff == 0.5)   -- maps merge per key
assert(#cfg.plugins == 1 and cfg.plugins[1] == "auth")      -- arrays replace

-- environment layer: strings only, coerced against the default types
local conflicts
cfg, conflicts = applyLayer(cfg, { port = "7000", verbose = "yes" }, "env")
assert(cfg.port == 7000 and cfg.verbose == true)
assert(#conflicts == 0)

-- CLI layer
local cli = parseArgv({ "--port=8081", "--verbose" })
cfg = applyLayer(cfg, cli, "cli")
assert(cfg.port == 8081)

-- a type conflict is reported, not silently defaulted
local _, bad = applyLayer(cfg, { port = "not-a-number" }, "env")
assert(#bad == 1)

-- explicit deletion
local pruned = merge(cfg, { plugins = UNSET })
assert(pruned.plugins == nil)

-- the defaults were never mutated
assert(DEFAULTS.port == 8080 and DEFAULTS.retry.count == 3)
```

**In practice**:
- Merge in the order defaults < file < env < CLI, each layer merged into a *copy* of the accumulated result.
- Deep-merge maps, replace arrays, and use a sentinel value for explicit deletion since `nil` cannot be stored in a table.
- Coerce env and CLI strings against the type of the current value; collect all conflicts and report them together.
- Never mutate the defaults table, and deep-copy nested tables when merging — tables are references.
- Pass the CLI argument vector into the config module instead of reading the global `arg`; and remember that Lua does not parse your script's flags — `--verbose` reaches you as an ordinary string in `arg[1]`, `arg[2]`, …, while the negative indices hold the interpreter's own options.
- Distinguish "unset" from "set to empty" for environment variables: `os.getenv` returns `nil` versus `""`.
- Use `rawget` to distinguish a key that was explicitly set from one inherited through a `__index` defaults chain.

## Design Question 5: State machine scalability

*At 20+ states and 50+ transitions, the transition table becomes unwieldy. What structural patterns keep it maintainable? Consider hierarchical states and table-driven design.*

**Answer**:

Scale problems come from mixing the *graph* and the *logic* in one function, not from the graph being large. So the rule is: **the transition graph is data, the transition behaviour is a small set of named functions.** A table-driven machine keeps `transitions[state][event] = target`, so adding a state is adding a row and adding an event is adding a column; the table stays diffable and reviewable, and it can be validated mechanically.

Three structural patterns do most of the work. **Separate the graph from the behaviour**: `guards[event](ctx)` decides eligibility, `actions[event](ctx)` performs the effect, and the dispatcher stays a handful of lines. Without this split every new conditional lands inside the dispatcher and its branch count grows without bound. **Hierarchical states** keep the table small: a child state inherits its parent's outgoing transitions, and lookup walks the parent chain until it finds the event. Ten substates that all abort to `IDLE` declare that transition once on the shared parent. **Wildcard targets** handle the cross-cutting events (`RESET`, `ABORT`, `TIMEOUT`) that mean the same thing everywhere, instead of repeating them in every state's row.

Because the specification is data, it can be **validated at construction**: every target state must exist, every guard and action name must resolve to a function, every parent chain must terminate, and no parent cycle may exist. A table-driven machine that self-checks on load cannot be misconfigured in production — it fails at startup with a precise message instead of at 3 a.m. in a rare transition. Keep the dispatcher dumb: resolve the target, run the guard, run the action, switch state. All complexity belongs in the named functions the table points at, and when several states need the same event with different rules, key the guard by source state (`guards[event][from]`) instead of growing one giant function.

The anti-patterns to avoid are equally concrete: the "god switch" (`if state == "A" then ... elseif state == "B" then ...`), where every new state edits one enormous function and no two transitions can share behaviour; encoding the graph in code (`if event == "START_" .. state`), which cannot be validated; storing behaviour *inside* the graph (an event mapping to a function), which destroys the graph's comparability and serialisability; and using `__index` chains to resolve transitions, because the fallback then becomes invisible at the call site.

Lua-specific notes: an FSM is naturally a table with a metatable — `__index` for read-only state constants and `__tostring` for debugging output are good uses, but neither should participate in transition resolution. Use `setmetatable` per instance; a shared metatable is fine as long as it holds only methods and never mutable state, otherwise two machines share their state.

```lua
-- A hierarchical, table-driven state machine.
local SPEC = {
  states = {                                -- set of known states
    IDLE = true, RUNNING = true, STOPPING = true,
    CRASHED = true, RECOVERING = true,
  },
  parent = { RECOVERING = "RUNNING" },       -- RECOVERING inherits RUNNING's edges
  initial = "IDLE",
  transitions = {
    IDLE     = { START = "RUNNING" },
    RUNNING  = { FAIL = "CRASHED", PAUSE = "STOPPING" },
    STOPPING = { STOPPED = "IDLE" },
    CRASHED  = { RESET = "IDLE" },
  },
  guards = {
    START = function(ctx) return ctx.ready == true end,
  },
  actions = {
    START = function(ctx) ctx.starts = ctx.starts + 1 end,
  },
}

local function validate(spec)
  for state, edges in pairs(spec.transitions) do
    assert(spec.states[state], "unknown source state: " .. tostring(state))
    for event, target in pairs(edges) do
      assert(spec.states[target], "unknown target state: " .. tostring(target))
      local g = spec.guards[event]
      assert(not g or type(g) == "function", "guard must be a function: " .. event)
      local a = spec.actions[event]
      assert(not a or type(a) == "function", "action must be a function: " .. event)
    end
  end
  -- every parent chain must terminate and contain no cycle
  for state in pairs(spec.states) do
    local seen, cur = {}, state
    while cur do
      assert(not seen[cur], "parent cycle at state: " .. tostring(cur))
      seen[cur] = true
      cur = spec.parent[cur]
    end
  end
end

-- A handler may be a single function or a per-source-state table.
local function pick(map, event, state)
  local h = map and map[event]
  if type(h) == "table" then return h[state] end
  return h
end

local FSM = {}
FSM.__index = FSM

local function newFSM(spec)
  validate(spec)
  return setmetatable({ spec = spec, state = spec.initial, ctx = { starts = 0 } }, FSM)
end

function FSM:resolve(event)
  local state, seen = self.state, {}
  while state and not seen[state] do
    seen[state] = true
    local edges = self.spec.transitions[state]
    if edges and edges[event] then return edges[event] end
    state = self.spec.parent[state]            -- inherit from the parent state
  end
  return nil
end

function FSM:fire(event)
  local target = self:resolve(event)
  if not target then
    return false, "event '" .. event .. "' is invalid in state '" .. self.state .. "'"
  end
  local guard = pick(self.spec.guards, event, self.state)
  if guard and not guard(self.ctx) then
    return false, "guard rejected '" .. event .. "'"
  end
  local action = pick(self.spec.actions, event, self.state)
  if action then action(self.ctx) end
  self.state = target
  return true
end

local fsm = newFSM(SPEC)
fsm.ctx.ready = false
assert(fsm:fire("START") == false)              -- guard rejects
fsm.ctx.ready = true
assert(fsm:fire("START") == true)
assert(fsm.state == "RUNNING")
assert(fsm.ctx.starts == 1)

-- hierarchy: RECOVERING inherits RUNNING's FAIL transition
fsm.state = "RECOVERING"
assert(fsm:fire("FAIL") == true)
assert(fsm.state == "CRASHED")
```

**In practice**:
- Keep `transitions`, `guards` and `actions` in three separate tables; the graph stays pure data and the behaviour stays testable.
- Model hierarchy with an explicit `parent` map and a lookup loop with a visited set, instead of an `__index` chain.
- Validate the whole specification at startup: unknown targets, missing handlers, parent cycles — fail at load time, not in a rare transition.
- Use wildcard targets for cross-cutting events (`RESET`, `ABORT`) rather than repeating them in every state row.
- Keep `fire()` down to a few lines; put the behaviour in named functions, and key per-state rules by source state when they diverge.
- Give each instance its own metatable if the metatable ever holds state; a shared metatable must contain methods only.

## Design Question 6: Test isolation

*How do you ensure Lua tests don't share state through globals or module-level locals? What patterns enforce isolation without a separate Lua state per test?*

**Answer**:

There are four contamination sources in a single Lua state, and each needs a different remedy. **Globals** in `_G`: one test writes `_G.cache = {}` and the next one reads it. **Module-level locals**: a module cached in `package.loaded` keeps its state between tests — and clearing `package.loaded[name] = nil` only prevents reuse, it does not undo side effects the module performed at load time (spawning a coroutine, opening a file, registering a signal handler). **Environments**: a function's environment is part of its identity, so if a test swaps the environment of a module's function (with `setfenv` in 5.1/LuaJIT, or the `env` argument of `load` in 5.2+) the change persists for every later test unless it is restored. **Shared singletons**: a timer, a connection pool or a scheduler that survives the test body.

The remedy to reach for first is structural rather than defensive: **give modules a factory, not a singleton**. If `Counter.new()` returns a fresh instance with its own state, module-level state becomes instance state and there is nothing to reset — no teardown, no `package.loaded` surgery, no ordering dependency. When a singleton is unavoidable, give it an explicit `reset()`/`close()` that clears its tables, stops its coroutines and closes its handles, and call it in teardown.

Three complementary mechanisms cover the rest. **Snapshot and restore `_G`** around each test: copy the globals before the test, then afterwards delete any global the test added and restore any it changed. This catches the "test added a global" case that a plain restore of the original values misses, and it is cheap for the small global sets typical of a test suite. **Sandbox the test body**: load the test chunk with a fresh environment table whose `__index` is `_G`, so global *writes* land in the sandbox and vanish with it while global *reads* still see the real globals. The two implementations differ — `setfenv(chunk, env)` on 5.1/LuaJIT, `load(src, name, "t", env)` on 5.2+ — so feature-detect once in a helper rather than sprinkling version checks through the suite. **Clean up what outlives the test**: every coroutine, file handle and timer the test creates must be closed in teardown, because a suspended coroutine pins every upvalue on its stack — that is both a cross-test leak and a source of "old" values mysteriously appearing in the next test.

Finally, the harness itself must be hermetic: never call `os.exit` inside a test (it kills the process and reports nothing — use `xpcall` and print a summary), and remember that in 5.4 `warn("@on")` redirects warnings to a handler so a test can capture them, while on 5.1/LuaJIT `warn` does not exist at all and must be feature-detected. If you ever need bulletproof process-level isolation, the fallback is a separate Lua state per test *file* (a subprocess per file) — slower, but it removes the whole class of problems.

```lua
-- 1. Snapshot and restore the global table around one test.
local function snapshotGlobals()
  local saved = {}
  for k, v in pairs(_G) do saved[k] = v end
  return saved
end

local function restoreGlobals(saved)
  for k in pairs(_G) do
    if saved[k] == nil then _G[k] = nil end
  end
  for k, v in pairs(saved) do _G[k] = v end
end

local saved = snapshotGlobals()
_G.leaked = "oops"
assert(rawget(_G, "leaked") == "oops")
restoreGlobals(saved)
assert(rawget(_G, "leaked") == nil)

-- 2. Run a test body in its own environment.
local function loadInEnv(src, name, env)
  if setfenv then                              -- Lua 5.1 / LuaJIT
    local chunk = assert(loadstring(src, name))
    setfenv(chunk, env)
    return chunk
  end
  return assert(load(src, name, "t", env))     -- Lua 5.2+
end

local sandbox = setmetatable({}, { __index = _G })
local run = loadInEnv("scratch = 1; return scratch", "sandbox-test", sandbox)
assert(run() == 1)
assert(rawget(_G, "scratch") == nil)          -- the global never touched _G
assert(sandbox.scratch == 1)

-- 3. Prefer fresh instances over module singletons.
local Counter = {}
Counter.__index = Counter

function Counter.new()
  return setmetatable({ count = 0 }, Counter)
end

function Counter:inc()
  self.count = self.count + 1
  return self.count
end

local a, b = Counter.new(), Counter.new()
a:inc()
assert(a.count == 1 and b.count == 0)         -- no shared state
```

**In practice**:
- Prefer fresh instances (`Module.new()`); use snapshot/restore of `_G` as a safety net and sandbox environments for tests that really must touch globals.
- Feature-detect `setfenv`/`loadstring` (5.1, LuaJIT) versus `load(src, name, "t", env)` (5.2+) once, in a single helper.
- Give every module a `reset()`/`close()` and call it in teardown; clearing `package.loaded` alone does not undo load-time side effects.
- Close coroutines, file handles and timers in teardown — a suspended coroutine pins every upvalue it holds.
- Never call `os.exit` in a test; wrap the body in `xpcall` and print a summary instead.
- Use `warn` only behind a feature check (`if warn then warn("@on") end`), since it does not exist on 5.1/LuaJIT.
