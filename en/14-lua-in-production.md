# 14 — Lua in Production

> **Phase**: E (Performance and Production Design)  
> **Prerequisites**: Chapter 13 — Patterns  
> **Time Estimate**: 2–3 hours reading + 2–4 hours exercises  
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT (differences noted)

---

## Learning Objectives

After completing this chapter, you will be able to:

1. **Design production Lua architectures** with proper host/script boundaries
2. **Implement sandboxing** to safely execute untrusted Lua scripts
3. **Handle observability** — logging, metrics, and error tracking across Lua/C boundaries
4. **Plan version upgrade strategies** for Lua version migrations
5. **Anticipate and mitigate production failure modes** specific to Lua

---

## Deployment Contexts

Lua excels in embedded scripting roles:

| Domain | Use Case | Example |
|--------|----------|---------|
| Game engines | Gameplay logic, UI, modding | World of Warcraft, Roblox |
| Embedded systems | Configuration, automation | Network appliances, IoT |
| Policy engines | Rule evaluation, access control | Firewalls, API gateways |
| Databases | Stored procedures, extensions | Redis (EVAL), OpenResty |
| Text processing | Filtering, transformation | Pandoc, Hammerspoon |

---

## Architecture Guidelines

### 1. Keep Host Authority in C/C++/Rust

```text
┌─────────────────────────────────┐
│  Host Application (C/C++/Rust)  │
│  - Resource management          │
│  - I/O authority                │
│  - Security boundaries          │
│  ┌───────────────────────────┐  │
│  │  Lua Scripts              │  │
│  │  - Game logic             │  │
│  │  - Configuration          │  │
│  │  - User extensions        │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

The host controls resources; Lua scripts operate within boundaries.

### 2. Expose Narrow API Surface

```lua
-- GOOD: Minimal API
local API = {
  get_player = function() return player end,
  log = function(msg) host_log(msg) end,
}

-- BAD: Expose everything
local API = {
  player = player,        -- Direct access to internals
  db = db_connection,     -- Database access!
  os = os,                -- Full system access!
}
```

### 3. Version Script APIs

```lua
-- api_v1.lua
local M = {}
M.get_player = function() return player end
return M

-- api_v2.lua (additive changes)
local v1 = require("api_v1")
local M = setmetatable({}, {__index = v1})
M.get_player_stats = function() return compute_stats(player) end
return M
```

### 4. Isolate Untrusted Scripts

```lua
-- Sandbox: create restricted environment
local function create_sandbox()
  local env = {
    print = print,
    string = string,
    math = math,
    table = table,
    -- No io, os, debug, package
  }
  return setmetatable(env, {__index = _G})
end
```

---

## Sandboxing

### What to Remove

```lua
-- Dangerous globals for untrusted code
local blocked = {
  "io", "os", "debug", "package",
  "loadfile", "dofile", "require",
  "rawget", "rawset", "rawequal", "rawlen",
  "setmetatable", "getmetatable",  -- Optional: depends on use case
  "pcall", "xpcall", "error",     -- Optional: may want to keep
}
```

### Resource Quotas

```lua
-- CPU step limiting
local function with_step_limit(fn, max_steps)
  local steps = 0
  debug.sethook(function()
    steps = steps + 1
    if steps > max_steps then
      error("step limit exceeded")
    end
  end, "", 1000)  -- Check every 1000 instructions

  local ok, err = pcall(fn)
  debug.sethook()  -- Remove hook
  return ok, err
end

-- Memory limiting
local function with_memory_limit(fn, max_kb)
  local before = collectgarbage("count")
  local ok, err = pcall(fn)
  collectgarbage("collect")
  local after = collectgarbage("count")
  if after - before > max_kb then
    return false, "memory limit exceeded"
  end
  return ok, err
end
```

### Sandboxed Execution

```lua
local function run_untrusted(code, sandbox_env, limits)
  local chunk, err = load(code, "untrusted", "t", sandbox_env)
  if not chunk then
    return nil, "parse error: " .. err
  end

  -- Apply CPU limit
  if limits.max_steps then
    local steps = 0
    debug.sethook(function()
      steps = steps + 1
      if steps > limits.max_steps then
        error("CPU limit exceeded")
      end
    end, "", 1000)
  end

  local ok, result = pcall(chunk)
  debug.sethook()  -- Always clean up

  if not ok then
    return nil, "runtime error: " .. tostring(result)
  end
  return result
end
```

---

## Observability

### Structured Logging

```lua
-- Logger with levels and structured data
local Logger = {}
Logger.__index = Logger

function Logger.new(name)
  return setmetatable({name = name}, Logger)
end

function Logger:log(level, message, data)
  local entry = {
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    level = level,
    logger = self.name,
    message = message,
    data = data,
  }
  -- Send to host logging system
  host_log(json_encode(entry))
end

function Logger:info(msg, data) self:log("info", msg, data) end
function Logger:warn(msg, data) self:log("warn", msg, data) end
function Logger:error(msg, data) self:log("error", msg, data) end
```

### Error Tracking

```lua
-- Capture errors with context
local function with_error_tracking(fn, context)
  return xpcall(fn, function(err)
    return {
      error = tostring(err),
      traceback = debug.traceback("", 2),
      context = context,
      timestamp = os.time(),
    }
  end)
end
```

### Execution Metrics

```lua
-- Track script execution statistics
local metrics = {
  calls = 0,
  errors = 0,
  total_time = 0,
}

local function tracked_execute(fn)
  local start = os.clock()
  metrics.calls = metrics.calls + 1
  local ok, err = pcall(fn)
  local elapsed = os.clock() - start
  metrics.total_time = metrics.total_time + elapsed
  if not ok then
    metrics.errors = metrics.errors + 1
  end
  return ok, err, elapsed
end
```

---

## Version Upgrade Strategy

### Compatibility Test Corpus

```lua
-- tests/compat/5_1.lua
local tests = {}
function tests.test_setfenv()
  -- Only runs on 5.1
  if _VERSION ~= "Lua 5.1" then return true end
  -- Test setfenv behavior
  return true
end

-- tests/compat/5_3.lua
function tests.test_integers()
  if _VERSION < "Lua 5.3" then return true end
  -- Test integer division, bitwise operators
  return 5 // 2 == 2
end
```

### Feature-Gating

```lua
-- Gate version-specific features
local feature = {}

if _VERSION >= "Lua 5.3" then
  function feature.integer_division(a, b)
    return a // b
  end
else
  function feature.integer_division(a, b)
    return math.floor(a / b)
  end
end

if _VERSION >= "Lua 5.4" then
  function feature.close_variable(resource)
    -- Use <close> attribute
  end
end
```

### API Contracts

```lua
-- Freeze API with semantic versioning
-- api/compat.lua
local M = {}

-- v1.0.0: initial API
function M.get_player() return player end

-- v1.1.0: added get_player_stats (additive, non-breaking)
function M.get_player_stats() return compute_stats(player) end

-- v2.0.0: breaking change (major version bump)
-- M.get_player() now returns a proxy, not direct reference
```

---

## Failure Modes

### 1. GC Spikes

```lua
-- Problem: Burst allocation causes GC pause
local function burst_alloc()
  local t = {}
  for i = 1, 1000000 do
    t[i] = {x = i, y = i * 2}  -- 1M tables!
  end
  return t
end

-- Mitigation: Spread allocation over time
local function gradual_alloc()
  local t = {}
  for i = 1, 1000000 do
    t[i] = {x = i, y = i * 2}
    if i % 10000 == 0 then
      collectgarbage("step", 100)  -- Small GC steps
    end
  end
  return t
end
```

### 2. Coroutine Leaks

```lua
-- Problem: Coroutines that never finish
local leaked = {}
local function spawn_leaky(fn)
  local co = coroutine.create(fn)
  leaked[#leaked + 1] = co
  -- Never cleaned up!
end

-- Mitigation: Track and cancel
local function spawn_tracked(fn, cancel_flag)
  local co = coroutine.create(function()
    while not cancel_flag.cancelled do
      fn()
      coroutine.yield()
    end
  end)
  return co, function() cancel_flag.cancelled = true end
end
```

### 3. ABI Mismatch

```lua
-- Problem: C module compiled for wrong Lua version
-- Solution: Version checks at load time
local function safe_require(modname)
  local ok, mod = pcall(require, modname)
  if not ok then
    error("Failed to load " .. modname .. ": " .. tostring(mod))
  end
  if mod._VERSION and mod._VERSION ~= _VERSION then
    error(modname .. " compiled for " .. mod._VERSION .. ", running " .. _VERSION)
  end
  return mod
end
```

### 4. Silent Behavior Drift

```lua
-- Problem: Metatable mutation changes behavior silently
local config = {debug = false}
local mt = {__index = config}

-- Later, somewhere:
config.debug = true  -- Changes behavior globally!

-- Mitigation: Deep freeze config
local function freeze(t)
  return setmetatable({}, {
    __index = t,
    __newindex = function()
      error("attempt to modify frozen table")
    end,
  })
end

local frozen_config = freeze(config)
```

---

## Testing Strategies

### Unit Testing

```lua
-- Simple test framework
local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("PASS: " .. name)
  else
    print("FAIL: " .. name .. " - " .. tostring(err))
  end
end

test("addition", function()
  assert(1 + 1 == 2)
end)

test("string concat", function()
  assert("hello" .. " " .. "world" == "hello world")
end)
```

### Integration Testing

```lua
-- Test Lua scripts through host API
local function test_script()
  local env = create_sandbox()
  local result, err = run_untrusted([[
    local player = API.get_player()
    player.hp = player.hp - 10
    return player.hp
  ]], env, {max_steps = 10000})

  assert(result == 90, "Expected 90, got " .. tostring(result))
end
```

### Property-Based Testing

```lua
-- Generate random inputs and verify properties
local function property(name, generator, check, iterations)
  iterations = iterations or 1000
  for i = 1, iterations do
    local input = generator()
    local ok, err = pcall(check, input)
    if not ok then
      error(name .. " failed on input: " .. tostring(input) .. " - " .. tostring(err))
    end
  end
  print("PASS: " .. name .. " (" .. iterations .. " iterations)")
end

property("add commutative", function()
  return {math.random(1000), math.random(1000)}
end, function(t)
  assert(t[1] + t[2] == t[2] + t[1])
end)
```

---

## Common Pitfalls

### 1. Not Sandboxing User Scripts

```lua
-- DANGEROUS: Full access
local chunk = load(user_code)
chunk()  -- Can do anything!

-- SAFE: Sandboxed
local env = create_sandbox()
local chunk = load(user_code, "user", "t", env)
chunk()
```

### 2. Ignoring Error Context

```lua
-- BAD: Lost error context
pcall(dangerous_function)

-- GOOD: Preserved context
xpcall(dangerous_function, function(err)
  return debug.traceback("Error: " .. tostring(err), 2)
end)
```

### 3. Not Monitoring GC

```lua
-- BAD: Surprise GC pauses
-- No monitoring, no warning

-- GOOD: Track GC pressure
local gc_before = collectgarbage("count")
-- ... run script ...
local gc_after = collectgarbage("count")
if gc_after - gc_before > 1000 then
  log.warn("High GC pressure", {before = gc_before, after = gc_after})
end
```

### 4. Assuming Deterministic Finalization

```lua
-- BAD: Relying on __gc for cleanup
local r = make_resource()
r = nil  -- Not guaranteed to be freed!
-- __gc may run much later

-- GOOD: Explicit cleanup
local r = make_resource()
r:close()  -- Deterministic
```

### 5. Hardcoding Lua Version Assumptions

```lua
-- BAD: Assumes 5.3+ features
local x = 5 // 2  -- Fails on 5.1

-- GOOD: Version-aware code
local function intdiv(a, b)
  if _VERSION >= "Lua 5.3" then
    return a // b
  else
    return math.floor(a / b)
  end
end
```

---

## Best Practices

### 1. Keep Deterministic Paths Pure

```lua
-- Pure function: same input → same output, no side effects
local function calculate_damage(attack, defense)
  return math.max(1, attack - defense)
end

-- Impure: depends on external state
local function get_random_damage()
  return math.random(1, 100)  -- Non-deterministic!
end
```

### 2. Ship Microbenchmarks

```lua
-- Include benchmarks with hot-path modules
local bench = require("bench")

bench("movement_system", function()
  for i = 1, 10000 do
    movement_system(entities, 0.016)
  end
end)
```

### 3. Test Under Memory Pressure

```lua
-- Simulate low-memory conditions
local function stress_test(fn)
  -- Set aggressive GC
  collectgarbage("setpause", 10)
  collectgarbage("setstepmul", 50)

  local ok, err = pcall(fn)

  -- Restore defaults
  collectgarbage("setpause", 100)
  collectgarbage("setstepmul", 200)

  return ok, err
end
```

### 4. Code Review Checklist

- [ ] No `io`/`os` in untrusted script paths
- [ ] All `pcall` results checked
- [ ] No string concatenation in hot loops
- [ ] Tables reused where possible
- [ ] Error messages include context
- [ ] No reliance on `__gc` for deterministic cleanup
- [ ] Version-specific code gated with `_VERSION` checks

### 5. Document Failure Modes

```lua
--- Process user script safely
-- Known failure modes:
--   - CPU limit exceeded (step counter)
--   - Memory limit exceeded (GC count)
--   - Parse error (invalid Lua syntax)
--   - Runtime error (script bug)
-- Recovery: returns nil, error table with code and message
local function process_script(code)
  -- ...
end
```

---

## Version Notes

### Lua 5.1

- `setfenv`/`getfenv` for sandboxing
- No `__gc` for tables
- Widely deployed (many C modules compiled for 5.1)

### Lua 5.2/5.3

- `setmetatable` with `__gc` on tables (5.2+)
- `table.pack`/`table.unpack` for varargs
- Integer type (5.3+) — may affect existing code
- `bit32` removed in 5.3 (use native operators)

### Lua 5.4

- Generational GC — better for allocation-heavy workloads
- `__close` for deterministic resource cleanup
- `coroutine.close` for explicit coroutine cleanup
- Breaking changes from 5.3 (see migration guide)

### LuaJIT

- Lua 5.1 compatible (not 5.3/5.4)
- FFI for C interop without wrappers
- Excellent performance for traceable code
- Some patterns break JIT traces

---

## Knowledge Check

<details>
<summary>1. What should a sandbox remove from the Lua environment?</summary>

At minimum: `io`, `os`, `debug`, `package`, `loadfile`, `dofile`, `require`. Optionally: `rawget`/`rawset`, `setmetatable`/`getmetatable`, depending on trust level.
</details>

<details>
<summary>2. How do you prevent GC spikes in production?</summary>

Spread allocations over time with periodic `collectgarbage("step")`. Reuse tables. Use generational GC (5.4) for allocation-heavy workloads. Monitor GC pressure.
</details>

<details>
<summary>3. Why version-gate Lua features?</summary>

Different Lua versions have incompatible features (integer division in 5.3+, `__close` in 5.4). Gating ensures code works across versions without runtime errors.
</details>

<details>
<summary>4. What is the host/script boundary, and why does it matter?</summary>

The host (C/C++/Rust) controls resources and security. Lua scripts operate within boundaries set by the host. Violating this (e.g., giving scripts `os.execute`) creates security risks.
</details>

<details>
<summary>5. Why shouldn't you rely on <code>__gc</code> for cleanup?</summary>

GC timing is non-deterministic. Objects may be collected immediately, much later, or never in a single session. Use explicit `close()` methods for deterministic cleanup.
</details>

---

## Key Takeaways

- **Host authority**: C/C++/Rust controls resources; Lua operates within boundaries
- **Narrow API surface**: expose only what scripts need
- **Sandboxing**: remove `io`/`os`/`debug` for untrusted code
- **Resource quotas**: CPU steps, memory limits, timeouts
- **Observability**: structured logging, error tracking, execution metrics
- **Version gating**: feature-detect with `_VERSION` checks
- **Failure modes**: GC spikes, coroutine leaks, ABI mismatch, behavior drift
- **Testing**: unit, integration, property-based, stress tests
- **Never rely on `__gc`** for deterministic cleanup

---

## Exercises

### Beginner (30–60 min)

1. **Sandbox Builder**: Create `create_sandbox(options)` that returns a restricted environment. Options control which libraries are available.

2. **Error Reporter**: Implement `run_safe(code)` that executes Lua code and returns structured error reports with tracebacks.

3. **Metrics Collector**: Build a simple metrics module that tracks function call counts and execution times.

### Intermediate (1–2 hours)

4. **Resource Limiter**: Implement a coroutine-based execution environment with CPU step limits and memory limits.

5. **Version Adapter**: Create a compatibility layer that provides consistent API across Lua 5.1, 5.3, and 5.4.

6. **Log Aggregator**: Build a logging system that batches and sends structured logs to a host callback.

### Advanced (2–4 hours)

7. **Script Hot-Reload**: Implement a development-mode system that detects script changes and reloads without restarting the host.

8. **Production Monitor**: Build a monitoring dashboard that tracks Lua script health: execution time, error rates, GC pressure, memory usage.

---

## Example Code

Runnable examples for this chapter:
- `examples/advanced/02-sandbox-environment.lua` — Sandboxed execution
- `examples/advanced/03-object-pool.lua` — Production-ready object reuse

---

## Further Reading

- [Lua 5.4 Reference Manual](https://www.lua.org/manual/5.4/)
- [Programming in Lua (4th ed.)](https://www.lua.org/pil/)
- [Lua in Practice](https://www.amazon.com/Lua-Practice-Ricardo-Fabricio-Ordines/dp/1784394594)
- [Game AI Pro — Lua Scripting](https://www.gameaipro.com/)
