# Advanced Exercises

## Concept Reinforcement

1. **Schema Validation (Stage 17)** — `Hard`
   Build a `validate(schema, data)` function that recursively checks a table against a schema definition. The schema supports types (`"string"`, `"number"`, `"boolean"`, `"table"`), required/optional fields, and nested schemas. Return a list of all validation errors.
   ```lua
   local schema = { name = "string", age = "number", address = { city = "string", zip = "string" } }
   local ok, errs = validate(schema, { name = "Alice", age = "thirty" })
   -- ok = false, errs = {"age: expected number, got string"}
   ```
   **Hints:** Use `type(v)` comparisons for primitives. Recurse on nested table schemas. Track error paths with a stack.

2. **Dependency Injection (Stage 18)** — `Hard`
   Create a DI container with `register(name, factory)` and `resolve(name)`. Factories may return cached singletons or new instances (use a `cached = true` flag). Dependencies are resolved automatically when a factory's signature declares them via `debug.getinfo`:
   ```lua
   container:register("db", { cached = true }, function(config)
     return { execute = function(sql) return sql end }
   end)
   container:register("logger", { cached = true }, function(db)
     return { log = function(msg) db.execute("INSERT INTO logs") end }
   end)
   ```
   Detect circular dependencies at resolve time and raise a descriptive error with the cycle path (e.g., `"a -> b -> c -> a"`).

3. **Command Pattern (Stage 19)** — `Hard`
   Implement a transaction log using the Command pattern. Each command is a table with `execute(self)`, `undo(self)`, and `serialize(self)` methods. Build an `Invoker` that tracks history and supports `undo(n)` and `redo(n)`.
   - Serialize the log to a file as JSON and reload it from disk
   - Verify that `undo` after reload behaves identically to `undo` in memory
   - Handle edge cases: undo on empty history, redo beyond stack depth, serialize a command that references a closed-over upvalue

4. **Observer Pattern (Stage 20)** — `Hard`
   Build an `EventEmitter` that supports `on(event, handler)`, `off(event, handler)`, and `emit(event, ...)`. Add a `once(event, handler)` convenience that auto-removes after first fire.
   - Ensure handlers fire in registration order
   - A handler error must not prevent subsequent handlers from executing
   - Include a `listenerCount(event)` utility
   - Include `prependListener(event, handler)` to add a handler at the front of the queue

5. **Object Pool (Stage 21)** — `Hard`
   Implement a generic `Pool(factory, reset, maxSize)` that manages a fixed set of reusable objects.
   - Track `active`, `idle`, and `total` counts
   - When the pool is exhausted and `maxSize` is not yet reached, create a new object
   - If `maxSize` is reached, block the caller with a configurable timeout
   - Print pool statistics on each `acquire`/`release` call
   - Include a `drain(timeout)` method that waits for all active objects to be released
   - Include a `destroy()` method that forcibly closes all idle objects

6. **Pub-Sub System (Stage 22)** — `Hard`
   Build a publish-subscribe bus with wildcard topic matching.
   - `subscribe("db.>", handler)` matches `db.insert`, `db.update.row`, etc.
   - Wildcards: `>` matches any depth, `*` matches exactly one segment
   - Support `unsubscribe` and a `filter` function that rejects messages failing a predicate
   - Messages carry metadata: `{topic, timestamp, payload, source}`
   - Emit a `sys.subscribe` event whenever a new subscription is added
   - Include a `bus:history(topic_pattern, count)` returning the last N messages

7. **FSM Advanced (Stage 23)** — `Hard`
   Implement a hierarchical FSM where states can be nested (a state has a child FSM). When the parent transitions, all child states reset to their initial state.
   - Each state transition fires an `onEnter` and `onExit` hook
   - Validate the transition table at construction time — raise an error on unreachable states
   - Support a `currentPath()` method that returns the full state path like `"combat.melee"`
   - Support `force` flag to re-enter the current state without skipping hooks

8. **Data Pipeline (Stage 24)** — `Hard`
   Build a `Pipeline` that chains transformation stages: `Pipeline({trim, lowercase, split_words, deduplicate})`.
   - Each stage is a pure function `(data) -> data`
   - The pipeline supports `add_stage`, `remove_stage`, and `run`
   - Track per-stage execution count and average latency via built-in profiling hooks
   - Handle `nil` short-circuit gracefully (stage returns `nil` → pipeline stops)
   - Add a `dry_run` mode that prints what would happen without executing
   - Add a `pipeline:inspect(stage_name, fn)` to tap into intermediate results

9. **Concurrency Patterns (Stage 25)** — `Hard`
   Using `coroutine.create`, `coroutine.resume`, and `coroutine.wrap`, implement a cooperative task scheduler with priorities.
   - Tasks are scheduled as `{fn = function, priority = 1..5, deadline = num}`
   - The scheduler runs higher-priority tasks first
   - If a task misses its deadline, move it to a `deadline_missed` queue and emit a warning
   - Include a `yield()` function that cooperatively yields control back to the scheduler
   - Add a `sleep(seconds)` that resumes the task after the given duration

10. **Code Generation (Stage 26)** — `Hard`
    Write a Lua metaprogram that reads a table schema and generates a module containing:
    - A constructor function
    - Field getters and setters (with type checking)
    - A `tostring` metamethod for debugging
    - A `validate` method that checks runtime values against the schema
    ```lua
    -- Input: { name = "string", age = "number" }
    -- Generated: local Person = {}; Person.new = function(t) ... end
    ```
    Output the generated Lua as a string and `load()` it to verify the generated code works.

11. **Memory Management (Stage 27)** — `Hard`
    Instrument the Lua GC by hooking `collectgarbage("setpause")` and `collectgarbage("setstepmul")`. Build a benchmark that:
    - Allocates N large tables (each ~1MB of nested data)
    - Measures pause time between allocation bursts
    - Reports peak memory, GC cycle count, and total GC time
    - Varies `stepmul` and `pause` to find optimal settings
    - Compare stock Lua vs LuaJIT if available
    - Document which parameter combinations minimize tail latency

12. **Deployment Patterns (Stage 28)** — `Hard`
    Create a `ServiceLoader` that discovers Lua modules in a directory tree, loads them by convention (`init.lua`), and exposes a unified API.
    - Each module declares metadata in a `__meta` table: `{name, version, dependencies = {}, config = {}}`
    - The loader validates dependency ordering topologically
    - Detects version conflicts (e.g., two modules require incompatible versions of the same dependency)
    - Provides a `status()` view of all loaded services with health checks
    - Support hot-reload by re-importing a module without restarting the host

---

## Mini Projects

### Project 1: Object Pool with Statistics (Stage 21)

Build a production-grade object pool for database connections (simulated).

**Requirements:**
- `Pool:create(config)` with `minSize`, `maxSize`, `idleTimeout`, `healthCheck`
- Track metrics: `acquire_count`, `release_count`, `timeout_count`, `error_count`
- Idle objects are reclaimed after `idleTimeout` seconds (use a timer coroutine)
- `healthCheck(conn)` runs before returning an object; unhealthy objects are discarded
- Expose `stats()` returning a snapshot table with all counters
- Handle concurrent `acquire` calls safely using coroutine-based yielding
- Add a `drain(timeout)` method that waits for all active objects to be released
- Add a `destroy()` method that closes all connections and stops the idle reaper

**Solution:**
```lua
local Pool = {}
Pool.__index = Pool

function Pool:create(config)
  local self = setmetatable({}, Pool)
  self._min = config.minSize or 1
  self._max = config.maxSize or 10
  self._idle_timeout = config.idleTimeout or 30
  self._health_check = config.healthCheck or function(c) return true end

  -- Metrics
  self._acquire_count = 0
  self._release_count = 0
  self._timeout_count = 0
  self._error_count = 0

  -- Pool state
  self._idle = {}        -- idle objects, keyed by object itself
  self._active = {}     -- objects handed out to callers
  self._reaper = nil    -- coroutine that reclaims idle objects

  -- Pre-create minSize objects
  for i = 1, self._min do
    local obj = config.factory and config.factory() or {}
    self._idle[obj] = true
  end

  -- Start idle reaper coroutine
  self._reaper = coroutine.create(function()
    while true do
      local deadline = os.clock() + self._idle_timeout
      while os.clock() < deadline do
        coroutine.yield()  -- wake periodically to check for destroy
      end
      -- Reclaim idle objects that have expired
      local now = os.clock()
      for obj in pairs(self._idle) do
        local expire = (obj._pool_expire or 0)
        if expire > 0 and now >= expire then
          self._idle[obj] = nil
          self._timeout_count = self._timeout_count + 1
          if config.dispose then config.dispose(obj) end
        end
      end
      -- Maintain minSize
      while #self._idle < self._min do
        local obj = config.factory and config.factory() or {}
        self._idle[obj] = true
      end
    end
  end)
  coroutine.resume(self._reaper)
  return self
end

function Pool:acquire(timeout)
  self._acquire_count = self._acquire_count + 1
  local deadline = timeout and (os.clock() + timeout) or math.huge

  while true do
    -- Try to find a healthy idle object
    for obj in pairs(self._idle) do
      local ok, err = pcall(self._health_check, obj)
      if ok and err then
        self._idle[obj] = nil
        self._active[obj] = true
        return obj
      else
        -- Unhealthy: discard and count as error
        self._idle[obj] = nil
        self._error_count = self._error_count + 1
        if self._dispose then self._dispose(obj) end
      end
    end

    -- No idle object available: create new one if under max
    if next(self._active) == nil and #self._idle < self._min then
      -- At min=0 edge case: create if under max
    end
    local total = self:count()
    if total < self._max then
      local obj = self._factory and self._factory() or {}
      self._active[obj] = true
      return obj
    end

    -- At capacity: wait for a release (yield to reaper)
    if os.clock() >= deadline then
      self._timeout_count = self._timeout_count + 1
      return nil, "acquire timed out"
    end
    coroutine.resume(self._reaper)
    -- Yield briefly to allow release() to run
    local co = coroutine.running()
    local ok = coroutine.yield()
    if not ok then return nil, "pool destroyed" end
  end
end

function Pool:release(obj)
  if not obj then return end
  self._release_count = self._release_count + 1
  self._active[obj] = nil

  -- Reset the object before returning to idle pool
  if self._reset then self._reset(obj) end

  -- Mark expiry time for idle timeout
  obj._pool_expire = os.clock() + self._idle_timeout
  self._idle[obj] = true
end

function Pool:stats()
  return {
    acquire_count = self._acquire_count,
    release_count = self._release_count,
    timeout_count = self._timeout_count,
    error_count   = self._error_count,
    idle = self:count(),
    active = 0,
  }
end

function Pool:count()
  local n = 0
  for _ in pairs(self._idle) do n = n + 1 end
  return n
end

function Pool:drain(timeout)
  local deadline = timeout and (os.clock() + timeout) or math.huge
  while next(self._active) do
    if os.clock() >= deadline then
      return false, "drain timed out"
    end
    coroutine.yield()
  end
  return true
end

function Pool:destroy()
  -- Stop reaper
  if self._reaper then
    coroutine.close(self._reaper)
    self._reaper = nil
  end
  -- Dispose all idle objects
  for obj in pairs(self._idle) do
    if self._dispose then self._dispose(obj) end
  end
  self._idle = {}
  self._active = {}
end
```

**Usage example:**
```lua
local pool = Pool:create {
  minSize       = 2,
  maxSize       = 5,
  idleTimeout   = 5,
  factory       = function() return { id = math.random(1,9999) } end,
  healthCheck   = function(c) return c.id ~= nil end,
  reset         = function(c) c.query = nil end,
  dispose       = function(c) c.id = nil end,
}

local conn = pool:acquire()
print("acquired", conn.id)
pool:release(conn)
print("stats", next(pool:stats()))  -- verify stats keys exist
pool:destroy()
```

### Project 2: Pub-Sub with Wildcards (Stage 22)

Build a message bus supporting `device.>`, `device.{sensor_id}.reading`, and `device.*.error`.

**Requirements:**
- Subscribe with patterns: `bus:subscribe("device.37.>", handler)`
- Emit: `bus:emit("device.37.temperature", payload)`
- Wildcards: `>` matches any depth, `*` matches exactly one segment
- Support `bus:history(topic_pattern, count)` returning the last N messages
- Add a `bus:replay(topic_pattern, since)` that replives messages from a timestamp
- Each handler gets a numeric id; `bus:unsubscribe(id)` removes it
- Handle handler errors gracefully without breaking the dispatch loop
- Sort patterns by specificity before dispatching (fewer wildcards = higher priority)

**Test scenario:**
```lua
local bus = Bus:new()
local readings = {}
bus:subscribe("device.37.>", function(msg) table.insert(readings, msg.payload) end)
bus:subscribe("device.*.error", function(msg) print("ERROR: " .. msg.payload) end)

bus:emit("device.37.temperature", {value = 22.5})
bus:emit("device.37.humidity", {value = 65})
bus:emit("device.99.error", {message = "timeout"})
-- readings should contain both temperature and humidity
```

### Project 3: Hierarchical FSM (Stage 23)

Model a game entity's behavior as a nested state machine. The top-level states are `idle`, `combat`, and `flee`. `combat` contains sub-states: `melee`, `ranged`, `reload`. `idle` contains sub-states: `patrol` and `rest`.

**Requirements:**
- Transition rules at every level (e.g., `idle → combat` resets `combat` to its initial sub-state `melee`)
- Each state has `onEnter(entity)` and `onExit(entity)` hooks that modify the entity table
- Add a `transitionLog` recording every transition as `{from, to, timestamp}`
- Validate all transitions at build time; error on unreachable states
- Test with: `entity:transition("combat")` should enter `melee`; `entity:transition("reload")` should stay in `combat` but switch sub-state
- Support `entity:currentState()` returning the full path like `"combat.melee"`
- Support `entity:pathHistory()` returning the last N state paths

**State diagram:**
```
idle ──────┐
  ├─ patrol │
  └─ rest   │
            │ (onHit)         ┌── melee
            └──► combat ──────┤── ranged
                  │           └── reload
                  │ (onLowHp)
                  ▼
                 flee
```

### Project 4: Data Pipeline (Stage 24)

Build a configurable ETL pipeline that processes CSV data.

**Requirements:**
- Stages: `parse_csv`, `filter_rows(predicate)`, `map_columns(transform)`, `aggregate(group_by, reducer)`, `output_csv`
- Each stage is a function receiving a list of tables and returning a list of tables
- `Pipeline:compose(stages)` chains stages; returns a new pipeline
- Add profiling: `pipeline:run(data)` prints per-stage row count in / out and time
- Handle errors: if a stage throws, catch and continue with a `dead_letter` log
- Test with synthetic CSV data (10 rows) covering edge cases: empty strings, missing fields, numeric strings
- Support `pipeline:inspect(stage_name, fn)` to tap into intermediate results
- Support `pipeline:skip(stage_name)` to bypass a stage without removing it

**Starter skeleton:**
```lua
local Pipeline = {}
Pipeline.__index = Pipeline

function Pipeline:new(stages)
  return setmetatable({_stages = stages or {}, _dead_letter = {}, _profile = {}}, Pipeline)
end

function Pipeline:run(data)
  local current = data
  for i, stage in ipairs(self._stages) do
    local t0 = os.clock()
    current = stage(current)
    self._profile[i] = {name = stage.name or ("stage_" .. i), time = os.clock() - t0}
  end
  return current
end
```

---

## Debugging Tasks

1. **Schema Validation — False Negatives** — `Hard`
   Your schema validator accepts `{name = 123}` against schema `{name = "string"}`. Find the bug: you wrote `type(v) == schema[k]` instead of comparing `type(v)` against the schema's type string for that key. Fix it and add test cases for nested tables, arrays, and union types like `"string|number"`.

2. **Object Pool — Resource Leak** — `Hard`
   Your pool leaks objects: `acquire` returns an object but `release` never decrements the active count. The bug is that `release` checks `obj == nil` before decrementing, but `release` receives the object reference (which is never nil). Trace the reference counting logic and fix the decrement. Add a test that acquires and releases 1000 times and asserts `stats().active == 0`.

3. **Pub-Sub — Wildcard Ordering** — `Hard`
   Your wildcard matcher processes `>` before `*`, causing `device.37.reading` to match `device.> ` instead of `device.*.reading`. The bug is in the matching priority: the most specific pattern should win. Refactor to sort patterns by specificity (fewer wildcards = more specific) before dispatching. Add a test that asserts handler execution order.

4. **Hierarchical FSM — Re-entrant Transition** — `Hard`
   Calling `entity:transition("combat")` while already in `combat` causes infinite recursion because `onEnter` of `combat` calls `transition("melee")`, which triggers `onExit("combat")` again. Add a guard: if transitioning to the current state, skip `onExit`/`onEnter` unless the transition specifies `force = true`. Write a test that transitions to the same state and verifies no infinite loop.

5. **Data Pipeline — Silent Data Loss** — `Hard`
   A stage returns `nil` instead of `{}` for an empty result. The pipeline interprets `nil` as "continue with unchanged data" instead of "stop processing." The bug is in the `run` loop: `result = stage(result)` should check for `nil` and either short-circuit or replace with `{}`. Fix and add a regression test with a stage that deliberately returns `nil`.

6. **Memory Management — GC Stall** — `Hard`
   Your benchmark shows a 2-second pause when `collectgarbage()` runs between bursts. The root cause is that `setstepmul` is set too low (100 instead of 200), so GC falls behind during allocation. Tune the parameters and verify the pause drops below 200ms on a synthetic workload. Document the optimal settings and explain why they work.

---

## Open-Ended Design Questions

1. How would you enforce schema validation at the boundary of an embedded Lua host without imposing runtime overhead on trusted internal code? Discuss trade-offs between static analysis, runtime guards, and load-time assertions.

2. A pub-sub system with wildcard matching scales poorly with many subscribers. What data structure (trie, hash-based, bitmask) would you use for pattern matching, and how would you benchmark the trade-off between memory and lookup speed?

3. In a hierarchical FSM, how do you handle cross-level transitions (e.g., a sub-state in `combat` directly transitioning to a sub-state in `idle`) without breaking the encapsulation of each level's transition table?

4. When building a data pipeline in Lua, how do you decide between coroutine-based generators (lazy evaluation) and list-based stages (eager evaluation)? What are the implications for memory usage and error propagation?

5. A deployment loader discovers conflicting module versions at startup. Should it hard-fail, use the newest version, or allow per-service version overrides? What contract should modules declare to make this choice safe?

6. How would you test a code generator that produces Lua modules? Consider property-based testing, fuzzing the schema input, and comparing generated output against hand-written reference implementations. What invariants must always hold?
