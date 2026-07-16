# 12 — Performance

> **Phase**: E (Performance and Production Design)  
> **Prerequisites**: Chapter 11 — Lua C API  
> **Time Estimate**: 2–3 hours reading + 3–5 hours exercises  
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT (differences noted)

---

## Learning Objectives

After completing this chapter, you will be able to:

1. **Profile Lua code** and identify real bottlenecks (not guessed ones)
2. **Reduce allocation pressure** by reusing tables, strings, and closures
3. **Optimize table access** patterns for cache-friendly performance
4. **Tune garbage collection** for latency vs throughput trade-offs
5. **Leverage LuaJIT** optimizations and understand what breaks JIT traces

---

## Profiling First

> **Rule**: Never optimize without measuring. Profile, identify the bottleneck, then optimize.

### os.clock Profiling

```lua
local function bench(fn, iterations)
  iterations = iterations or 1000000
  local start = os.clock()
  for i = 1, iterations do fn(i) end
  local elapsed = os.clock() - start
  print(string.format("Elapsed: %.4fs (%.1f ns/op)", elapsed, elapsed / iterations * 1e9))
  return elapsed
end

bench(function(i) return i * 2 end)
```

### Profile with debug.getinfo

```lua
local function profile_fn()
  local info = debug.getinfo(1, "S")
  print("Source: " .. info.source)
  print("Lines: " .. info.linedefined .. "-" .. info.lastlinedefined)
end
```

### External Profilers

- **LuaProfiler**: Function-level profiling
- **luatrace**: Trace-based profiling
- **perf + FlameGraph**: System-level profiling with Lua debug hooks

---

## Table Optimization

### Dense Arrays

```lua
-- GOOD: Dense array — contiguous memory, cache-friendly
local items = {}
for i = 1, 10000 do
  items[i] = i * 2
end

-- BAD: Sparse table — hash part, poor cache behavior
local items = {}
items[1] = "a"
items[10000] = "b"
-- Iteration is slow; #items is undefined
```

### Pre-Shape Tables

```lua
-- BAD: Grows incrementally (multiple reallocations)
local t = {}
for i = 1, 10000 do
  t[i] = i
end

-- GOOD: Pre-allocate (5.3+: table.create)
local t = table.create(10000)
for i = 1, 10000 do
  t[i] = i
end

-- GOOD: Initialize with known size via constructor
local t = {nil, nil, nil, nil, nil}  -- 5 slots
```

### Avoid Mixed Key Types

```lua
-- BAD: Forces hash part for all access
local t = {}
t[1] = "a"
t[2] = "b"
t.name = "test"  -- Switches to hash part?

-- BETTER: Keep array-only tables pure
local array = {1, 2, 3, 4, 5}
local record = {name = "test", value = 42}
```

---

## Local vs Global Access

```lua
-- SLOW: Global lookup every iteration
for i = 1, 1000000 do
  local x = math.sin(i)  -- _ENV["math"]["sin"]
end

-- FAST: Local caching
local sin = math.sin
for i = 1, 1000000 do
  local x = sin(i)  -- VM register access
end
```

### Cache Hierarchy

```lua
-- Local is fastest
local function fast()
  local sin = math.sin
  return sin(1)
end

-- Upvalue is second (still faster than global)
local sin = math.sin
local function medium()
  return sin(1)
end

-- Global is slowest
local function slow()
  return math.sin(1)
end
```

> **When to cache**: Only in verified hot paths. Micro-optimizing cold code adds complexity without benefit.

---

## Allocation Patterns

### Table Reuse

```lua
-- BAD: Allocates every call
local function process(x, y)
  return {x = x, y = y, result = x + y}
end

-- BETTER: Reuse table
local temp = {}
local function process(x, y)
  temp.x = x
  temp.y = y
  temp.result = x + y
  return temp
end

-- BEST: No allocation
local function process(x, y)
  return x, y, x + y
end
```

### String Building

```lua
-- BAD: O(n²) — creates intermediate strings
local result = ""
for i = 1, 10000 do
  result = result .. tostring(i)
end

-- GOOD: O(n) — single allocation
local parts = {}
for i = 1, 10000 do
  parts[i] = tostring(i)
end
local result = table.concat(parts)
```

### Closure Avoidance

```lua
-- BAD: New closure each iteration
for i = 1, 1000 do
  timer.after(1, function() process(i) end)
end

-- GOOD: Shared closure with parameter
local function make_callback(i)
  return function() process(i) end
end
for i = 1, 1000 do
  timer.after(1, make_callback(i))
end

-- BETTER: Avoid closure entirely if possible
for i = 1, 1000 do
  timer.after(1, process, i)  -- Pass as argument
end
```

---

## Function Call Overhead

```lua
-- Function calls have overhead — inline in hot paths
local function hot_loop()
  local sum = 0
  for i = 1, 1000000 do
    sum = sum + i  -- Inlined
  end
  return sum
end

-- vs. function-heavy version (slower)
local function add(a, b) return a + b end
local function hot_loop()
  local sum = 0
  for i = 1, 1000000 do
    sum = add(sum, i)  -- Function call overhead
  end
  return sum
end
```

### Method Calls

```lua
-- Colon syntax has slightly more overhead than dot
local obj = {value = 0}
function obj:inc() self.value = self.value + 1 end  -- self is implicit
function obj.inc(self) self.value = self.value + 1 end  -- Same thing

-- In hot loops, consider direct function calls
local function inc_obj(obj)
  obj.value = obj.value + 1
end
```

---

## GC Tuning

### When GC Matters

GC overhead is significant when:
- High allocation rate (many short-lived objects)
- Large heap (GC scans more memory)
- Latency-sensitive (GC pauses cause frame drops)

### Tuning Parameters

```lua
-- Check current settings
print(collectgarbage("getpause"))    -- Default: 100
print(collectgarbage("getstepmul"))  -- Default: 200

-- Low-latency settings
collectgarbage("setpause", 50)      -- Start GC sooner
collectgarbage("setstepmul", 100)   -- Smaller steps

-- High-throughput settings
collectgarbage("setpause", 200)     -- Wait longer
collectgarbage("setstepmul", 400)   -- Bigger steps
```

### Generational Mode (5.4)

```lua
-- Switch to generational (good for many short-lived objects)
collectgarbage("generational")

-- Switch back to incremental
collectgarbage("incremental")
```

### Monitoring GC

```lua
-- Track GC statistics
local before = collectgarbage("count")
-- ... run code ...
collectgarbage("collect")
local after = collectgarbage("count")
print(string.format("Heap: %.1f KB → %.1f KB", before, after))
```

---

## LuaJIT Optimization

### What JIT Traces Well

```lua
-- GOOD: Simple, predictable loops
local sum = 0
for i = 1, 1000000 do
  sum = sum + i
end

-- GOOD: Monomorphic function calls
local sin = math.sin
for i = 1, 1000000 do
  local x = sin(i)
end
```

### What Breaks JIT Traces

```lua
-- BAD: Polymorphic types (different types in same trace)
local function process(x)
  return x + 1  -- Works for numbers, breaks for strings
end
process(1)
process("hello")  -- Trace guard failure!

-- BAD: Excessive function calls
for i = 1, 1000000 do
  helper1(helper2(helper3(i)))  -- Too many calls to inline
end

-- BAD: Metamethod-heavy patterns
local t = setmetatable({}, {
  __index = function(_, k) return compute(k) end
})
for i = 1, 1000000 do
  local v = t[i]  -- __index on every access
end
```

### FFI Performance

```lua
-- LuaJIT FFI: direct C access without wrapper overhead
local ffi = require("ffi")
ffi.cdef[[
  typedef struct { double x, y; } Point;
  double sqrt(double x);
]]

local p = ffi.new("Point", 3.0, 4.0)
local dist = ffi.C.sqrt(p.x * p.x + p.y * p.y)  -- Direct C call
```

---

## Common Pitfalls

### 1. Micro-Benchmarking Cold Code

```lua
-- WRONG: Benchmarking trivial code
local start = os.clock()
local x = 1 + 1  -- This is meaningless
print(os.clock() - start)

-- RIGHT: Benchmark realistic workloads
local start = os.clock()
for i = 1, 1000000 do
  process_real_data(data)
end
print(os.clock() - start)
```

### 2. Ignoring Allocation Rate

```lua
-- This looks fast but generates massive GC pressure
local function hot_path()
  local t = {}
  for i = 1, 100 do
    t[i] = {x = i, y = i * 2}  -- 100 tables + 100 sub-tables
  end
  return t
end
```

### 3. Optimizing Without Measuring

```lua
-- "I heard locals are faster" — but is it your bottleneck?
-- Profile first! Maybe the bottleneck is I/O, not computation.
```

### 4. Over-Caching

```lua
-- BAD: Caching everything adds complexity
local _sin = math.sin
local _cos = math.cos
local _tan = math.tan
local _sqrt = math.sqrt
-- ... 50 more cached values

-- GOOD: Only cache what's actually in hot paths
local sin = math.sin  -- Used 1000000 times per frame
```

### 5. Not Warmup-Testing JIT

```lua
-- LuaJIT needs warmup — first iterations are interpreted
local function bench()
  local sum = 0
  for i = 1, 1000000 do
    sum = sum + i
  end
  return sum
end

-- WRONG: Only run once
bench()  -- First run is slow (interpreted)

-- RIGHT: Warm up, then measure
bench()  -- Warmup
local start = os.clock()
bench()  -- Actual measurement
print(os.clock() - start)
```

---

## Best Practices

### 1. Profile Before Optimizing

```lua
-- Always measure first
local start = os.clock()
-- ... hot code ...
print("Time: " .. (os.clock() - start) .. "s")
```

### 2. Use Representative Workloads

```lua
-- Benchmark with real data sizes
local data = load_production_data()  -- Not just {1, 2, 3}
bench(function() process(data) end)
```

### 3. Track Memory Footprint

```lua
local before = collectgarbage("count")
-- ... code ...
collectgarbage("collect")
local after = collectgarbage("count")
print(string.format("Memory: %.1f KB", after))
```

### 4. Keep Optimization Notes

```lua
-- Document what you changed and why
-- Before: 15ms/frame, 500KB alloc/frame
-- After: 8ms/frame, 50KB alloc/frame
-- Change: Reused temp tables in particle system
```

### 5. Measure p50 and p95

```lua
-- Don't just measure average — check tail latency
local samples = {}
for i = 1, 100 do
  local start = os.clock()
  -- ... hot code ...
  samples[i] = os.clock() - start
end
table.sort(samples)
print("p50: " .. samples[50])
print("p95: " .. samples[95])
print("p99: " .. samples[99])
```

---

## Version Notes

### Lua 5.1

- Single number type (float only)
- No `table.create`
- No native bitwise operators (use `bit32` library)
- GC is incremental only

### Lua 5.3

- Integer arithmetic is faster (native int64)
- Bitwise operators are native (faster than `bit32`)
- `table.create` for pre-allocation
- `math.type` for number subtype checking

### Lua 5.4

- Generational GC mode (better for allocation-heavy workloads)
- `__close` for deterministic resource cleanup
- Integer division is slightly optimized

### LuaJIT

- JIT traces are very fast for simple, predictable code
- FFI eliminates C wrapper overhead
- Some patterns break traces: polymorphism, heavy metamethods, deep call chains
- Always warm up before benchmarking

---

## Knowledge Check

<details>
<summary>1. Why is <code>table.concat</code> faster than string concatenation in loops?</summary>

String concatenation `..` creates a new string every iteration (O(n²) total). `table.concat` builds an array of parts (O(n)) then joins them once (O(n)).
</details>

<details>
<summary>2. When should you cache globals as locals?</summary>

Only in verified hot paths. Caching adds complexity. Profile first — if the bottleneck isn't global lookup, caching doesn't help.
</details>

<details>
<summary>3. What breaks LuaJIT trace compilation?</summary>

Polymorphic types (different types in same code path), excessive function calls, metamethod-heavy patterns, and unpredictable control flow.
</details>

<details>
<summary>4. How do you reduce GC pressure?</summary>

Reuse tables instead of creating new ones. Avoid short-lived allocations in hot loops. Use `table.concat` for string building. Consider generational GC (5.4) for allocation-heavy workloads.
</details>

<details>
<summary>5. Why warm up before benchmarking LuaJIT?</summary>

The first iterations are interpreted (not JIT-compiled). Warmup allows the JIT to trace and compile hot loops before you measure performance.
</details>

---

## Key Takeaways

- **Profile first**: never optimize without measuring
- **Dense arrays** are faster than hash tables for sequential access
- **Local caching** helps in hot paths but adds complexity
- **Reuse tables** to reduce allocation pressure and GC pauses
- **`table.concat`** is O(n); string `..` in loops is O(n²)
- **GC tuning** trades latency for throughput
- **LuaJIT** needs warmup; avoid patterns that break traces
- **Track p50/p95 latency**, not just averages

---

## Exercises

### Beginner (30–60 min)

1. **Local Cache Benchmark**: Compare `math.sin` (global) vs local-cached `sin` over 1M iterations. Report the speedup.

2. **String Builder**: Benchmark `..` concatenation vs `table.concat` for building a 10K-character string. Measure time and allocation.

3. **GC Monitor**: Write a function that reports heap size before and after a code block.

### Intermediate (1–2 hours)

4. **Table Pre-allocation**: Compare incremental table growth vs `table.create` for building a 100K-element array. Measure time and GC count.

5. **Closure Avoidance**: Refactor a closure-heavy function to minimize closure creation. Benchmark before/after.

6. **Profiler**: Build a simple profiler using `debug.sethook` that counts function calls and time per function.

### Advanced (2–4 hours)

7. **Allocation Profiler**: Track allocation patterns over time, identifying which functions allocate the most.

8. **GC Benchmark**: Compare incremental vs generational GC (5.4) on a workload with 10M short-lived objects. Measure pause times.

---

## Example Code

Runnable examples for this chapter:
- `examples/advanced/03-object-pool.lua` — Table reuse pattern
- `examples/advanced/01-ecs-system.lua` — Performance-conscious design

---

## Further Reading

- [Lua 5.4 Reference Manual — Section 11](https://www.lua.org/manual/5.4/manual.html#11)
- [Programming in Lua (4th ed.) — Chapter 24–25](https://www.lua.org/pil/)
- [LuaJIT Performance Guide](https://luajit.org/perf.html)
- [Next Chapter: 13 — Patterns](13-patterns.md)
