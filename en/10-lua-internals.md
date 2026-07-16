# 10 — Lua Internals

> **Phase**: D (Internals and Native Integration)  
> **Prerequisites**: Chapter 09 — Standard Library  
> **Time Estimate**: 3–4 hours reading + 3–5 hours exercises  
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT (differences noted)

---

## Learning Objectives

After completing this chapter, you will be able to:

1. **Explain Lua's VM architecture** — the pipeline from source to bytecode execution
2. **Understand the register-based bytecode model** and why it matters for performance
3. **Reason about garbage collection** — incremental vs generational, tuning, and pitfalls
4. **Explain closure and upvalue mechanics** — open vs closed upvalues
5. **Use internal knowledge to write faster Lua code**

---

## VM Architecture

Lua's execution pipeline:

```
Source code
    ↓
Lexer / Parser
    ↓
Abstract Syntax Tree (AST)
    ↓
Proto (Function Prototype)
    ↓
Bytecode
    ↓
VM Dispatch Loop
    ↓
Execution
```

### Key Data Structures

| Structure | Purpose |
|-----------|---------|
| `Proto` | Function prototype: constants, instructions, upvalue descriptors, debug info |
| `Closure` | Executable object binding a `Proto` + captured upvalues |
| `CallInfo` | Call frame metadata: function pointer, saved pc, stack base |
| `TValue` | Tagged value: type tag + payload (pointer or immediate) |
| `Table` | Hash table with array part |
| `GCObject` | Header for all garbage-collected objects |

---

## Register-Based Bytecode

Lua uses a **register-based** virtual machine, unlike stack-based VMs (JVM, CPython):

### Stack-Based (for comparison)

```
PUSH 1
PUSH 2
ADD        -- pops 2, pushes result
STORE x
```

### Lua Register-Based

```text
LOADK  R1, 1      -- R1 = 1
LOADK  R2, 2      -- R2 = 2
ADD    R0, R1, R2  -- R0 = R1 + R2
SETTABUP R0, x    -- _ENV.x = R0
```

### Why Register-Based?

- **Fewer instructions** for expressions (no push/pop for each operand)
- **Better locality** — temporaries stay in registers, not on a stack
- **Compiler optimization** — register allocation can reuse slots

Trade-off: instructions are wider (more encoding bits) and compiler complexity increases.

### Inspecting Bytecode

```bash
# Disassemble a Lua file
luac -l file.lua

# Output shows instruction format:
# main <file.lua:1> (7 instructions, 28 bytes)
# 1       [1]  LOADK     1  -1    ; 1
# 2       [1]  LOADK     2  -2    ; 2
# 3       [1]  ADD       0  1  2  ; R0 = R1 + R2
# ...
```

---

## Value Representation: Tagged Values

Every Lua value is represented as a **tagged value**:

```
TValue = {
  tag: type tag (nil, boolean, number, string, table, function, thread, userdata)
  value: payload (immediate scalar or pointer to GC object)
}
```

### Implications

- **Dynamic type checks** happen frequently (tag comparison)
- **Predictable types** in hot paths reduce branching
- **Number representation** differs by version (single float in 5.1, int+float in 5.3+)

### Number Representation (5.3+)

```lua
-- Lua 5.3+ uses two subtypes
print(math.type(42))      -- "integer" (stored as C long/int64)
print(math.type(3.14))    -- "float" (stored as C double)
print(math.type(42.0))    -- "float" (trailing .0 matters!)

-- Integer operations are faster when both operands are integers
-- Float operations use IEEE 754 double
```

---

## Closures and Upvalues

### Open vs Closed Upvalues

```lua
local function outer()
  local x = 10  -- This local is captured by inner

  local function inner()
    return x  -- x is an upvalue
  end

  return inner
end

local fn = outer()
-- At this point, x's frame has exited.
-- The upvalue is "closed" — value moved to upvalue object.
print(fn())  -- 10 (still accessible!)
```

**Open upvalue**: Points to a local variable still on the stack (frame active).

**Closed upvalue**: Value has been copied/anchored into the upvalue object (frame exited).

```text
outer frame: local x
   ^
   | (open upvalue while outer is active)
inner closure

When outer returns:
   VM "closes" upvalues → value moved to upvalue object
   Inner closure still works, references closed upvalue
```

### Upvalue Lifecycle

1. **Creation**: When a closure is created, it captures referenced locals as open upvalues
2. **Sharing**: Multiple closures can share the same upvalue (same variable)
3. **Closing**: When the enclosing function returns, all open upvalues are closed
4. **GC**: Closed upvalues are garbage collected when no closure references them

### Performance Implications

```lua
-- BAD: Many closures = many upvalue objects
for i = 1, 10000 do
  local fn = function() return i end  -- New closure + upvalue each iteration
end

-- BETTER: Reduce closure creation
local functions = {}
for i = 1, 10000 do
  functions[i] = i  -- Just store the value, no closure needed
end
```

---

## Garbage Collection

Lua uses **automatic memory management** via garbage collection.

### Incremental Mark-and-Sweep

Default mode in Lua 5.1-5.3:

1. **Mark**: Trace from roots (globals, stack, registry) and mark reachable objects
2. **Sweep**: Reclaim unmarked objects
3. **Incremental**: Do small amounts of work per step to avoid long pauses

```
GC cycle:
  pause → mark → sweep → pause → ...
```

### Generational Mode (5.4)

Lua 5.4 adds generational GC:

- **Young generation**: Newly allocated objects, collected frequently
- **Old generation**: Objects surviving multiple collections, collected less often
- **Benefit**: Reduces GC work for workloads with many short-lived objects

```lua
-- Switch to generational mode (5.4)
collectgarbage("generational")

-- Or set step size
collectgarbage("setstepmul", 200)  -- Default is 200
```

### GC Tuning Parameters

| Parameter | Default | Effect |
|-----------|---------|--------|
| `pause` | 100 | How long GC waits before starting new cycle |
| `stepmul` | 200 | How aggressive GC steps are |
| `stepsize` | 10000 | Bytes per GC step |

```lua
-- Tune for low latency
collectgarbage("setpause", 50)     -- Start GC sooner
collectgarbage("setstepmul", 100)  -- Smaller steps

-- Tune for throughput
collectgarbage("setpause", 200)    -- Wait longer
collectgarbage("setstepmul", 400)  -- Bigger steps
```

### GC Metamethods

```lua
-- __gc for cleanup (tables: 5.2+, userdata: always)
local r = setmetatable({}, {
  __gc = function(self)
    print("Releasing: " .. tostring(self.name))
  end
})
r.name = "resource"

r = nil  -- Will be collected eventually
collectgarbage()  -- Force collection
-- Output: "Releasing: resource"
```

### Why GC Matters for Performance

```lua
-- BAD: Creates garbage every iteration
for i = 1, 1000000 do
  local t = {x = i, y = i * 2}  -- New table each iteration
  process(t)
end

-- BETTER: Reuse table
local t = {}
for i = 1, 1000000 do
  t.x = i
  t.y = i * 2
  process(t)
end

-- BEST: Avoid table entirely
for i = 1, 1000000 do
  process(i, i * 2)  -- No allocation
end
```

---

## String Interning

Lua **interns** (deduplicates) strings:

```lua
local a = "hello"
local b = "hello"
print(a == b)  -- true (same interned string)

-- String operations create new strings
local c = a .. " world"  -- New string, "hello" unchanged
```

### Implications

- **Equality checks** on strings are O(1) (pointer comparison)
- **Memory**: Many identical strings share one allocation
- **Allocation cost**: Creating many unique strings increases GC pressure

---

## Table Internals

### Array Part vs Hash Part

```
Table {
  array: {value, value, ...}      -- Contiguous integer keys starting at 1
  hash:  {key → value, ...}       -- Everything else
  sizearray: number of array slots
  lsizenode: log2 of hash size
}
```

### Table Growth

When a table needs more space:

1. **Array part**: Doubles in size
2. **Hash part**: Doubles in size
3. Elements are rehashed/moved

```lua
-- Pre-allocation hints (5.3+)
local t = {}
for i = 1, 10000 do
  t[i] = i  -- Table grows incrementally
end

-- Better: pre-allocate
local t = table.create(10000)  -- 5.3+ only
for i = 1, 10000 do
  t[i] = i
end
```

---

## Common Pitfalls

### 1. Assuming GC Runs at Predictable Times

```lua
-- DON'T: Rely on immediate collection
local t = {big_data}
t = nil
-- big_data is NOT guaranteed to be freed here
collectgarbage()  -- Force it, but still not guaranteed timing
```

### 2. Ignoring Allocation Pressure

```lua
-- BAD: High allocation rate
for i = 1, 1000000 do
  local s = string.format("item_%d", i)  -- New string each iteration
end

-- BETTER: Reuse or avoid
local parts = {}
for i = 1, 1000000 do
  parts[i] = "item_" .. i  -- Still allocates, but fewer
end
```

### 3. Assuming Integer Arithmetic (5.1)

```lua
-- Lua 5.1: All numbers are floats
local x = 10000000000000001
print(x == x + 1)  -- true! (precision loss)

-- Lua 5.3+: Integer arithmetic is exact (within int64 range)
-- local x = 10000000000000001LL  -- integer literal (5.3+ only)
-- print(x == x + 1)  -- false (correct!)
```

### 4. Closure Over Loop Variable (Revisited)

```lua
-- Classic: all closures share one variable
local fns = {}
for i = 1, 5 do
  fns[i] = function() return i end  -- All return 5
end

-- Fix: local copy per iteration
for i = 1, 5 do
  local j = i
  fns[i] = function() return j end
end
```

### 5. Not Understanding String Immutability

```lua
-- Strings are immutable — every operation creates a new one
local s = ""
for i = 1, 10000 do
  s = s .. "x"  -- O(n²) — creates 10000 intermediate strings
end

-- Use table.concat for O(n) string building
local parts = {}
for i = 1, 10000 do
  parts[i] = "x"
end
local s = table.concat(parts)
```

---

## Best Practices

### 1. Measure Before Optimizing

```lua
-- Use os.clock for profiling
local start = os.clock()
-- ... hot code ...
local elapsed = os.clock() - start
print(string.format("Elapsed: %.6f seconds", elapsed))
```

### 2. Reduce Table Churn

```lua
-- Reuse tables in hot paths
local temp = {}
local function process(x, y)
  temp.x = x
  temp.y = y
  return compute(temp)
end
```

### 3. Cache Globals

```lua
-- Module-level caching
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt

local function compute(x, y)
  return sqrt(sin(x)^2 + cos(y)^2)
end
```

### 4. Use Integer Arithmetic When Possible (5.3+)

```lua
-- Integer operations are faster than float
local sum = 0
for i = 1, 1000000 do
  sum = sum + i  -- Integer addition
end

-- Avoid implicit float conversion
local x = 10 / 2    -- 5.0 (float)
local y = 10 // 2   -- 5 (integer, faster)
```

### 5. Profile with GC Statistics

```lua
-- Monitor GC pressure
collectgarbage("collect")
local before = collectgarbage("count")
-- ... code ...
collectgarbage("collect")
local after = collectgarbage("count")
print(string.format("Allocated: %.1f KB", after - before))
```

---

## Version Notes

### Lua 5.1

- Single number type (float)
- No `math.type`
- Incremental GC only
- `setfenv`/`getfenv` for environment manipulation
- `string.dump` for bytecode inspection

### Lua 5.3

- Dual number type (integer + float)
- Native bitwise operators
- `math.type` for number subtype checking
- `table.move` for element transfer
- `string.format` supports integer-specific format specifiers

### Lua 5.4

- Generational GC mode
- `__close` variable attribute (to-be-closed)
- `coroutine.close` for explicit coroutine cleanup
- `warn` function for warning messages
- `integer division` improvements

### LuaJIT

- JIT compiler traces hot loops
- Trace-based optimization (inlining, dead code elimination)
- FFI for direct C interop
- Some patterns break JIT traces (too many guards, polymorphism)

---

## Knowledge Check

<details>
<summary>1. Why is register-based bytecode faster than stack-based for many expressions?</summary>

Register-based instructions reference operands directly, avoiding push/pop overhead. Expressions like `a + b * c` compile to fewer instructions because intermediate results stay in registers.
</details>

<details>
<summary>2. What's the difference between open and closed upvalues?</summary>

Open upvalues point to local variables still on the active stack. Closed upvalues have copied the value into the upvalue object after the enclosing function returned.
</details>

<details>
<summary>3. Why is generational GC better for allocation-heavy workloads?</summary>

It collects young objects (likely to die soon) more frequently, reducing the total work needed. Old objects are collected less often since they're more likely to persist.
</details>

<details>
<summary>4. Why are local variables faster than globals?</summary>

Locals are stored in VM registers (direct access). Globals require table lookups through `_ENV` — two hash lookups per access (`_ENV["math"]["sin"]`).
</details>

<details>
<summary>5. What causes string interning, and when is it a problem?</summary>

Lua deduplicates identical strings. This saves memory but means creating many unique strings (e.g., in string concatenation) allocates new interned strings, increasing GC pressure.
</details>

---

## Key Takeaways

- **Register-based VM**: fewer instructions, better locality than stack machines
- **Tagged values**: dynamic type checks; predictable types help performance
- **Open/closed upvalues**: closures capture by reference; values are anchored on scope exit
- **Incremental GC**: small steps avoid long pauses; generational mode (5.4) for allocation-heavy work
- **String interning**: equality is O(1) but unique strings increase GC pressure
- **Table internals**: array part for dense integers, hash part for everything else
- **Integer arithmetic** (5.3+): faster than float; use `//` for integer division

---

## Exercises

### Beginner (30–60 min)

1. **Bytecode Inspection**: Use `luac -l` to disassemble simple functions. Identify the opcodes for variable access, arithmetic, and function calls.

2. **GC Monitor**: Write a function that reports `collectgarbage("count")` before and after a code block to measure allocation.

3. **String Allocation**: Compare allocation rates of string concatenation vs `table.concat` for building large strings.

### Intermediate (1–2 hours)

4. **Upvalue Inspector**: Write a function `get_upvalues(fn)` that returns the names and values of a function's upvalues (use the `debug` library).

5. **Table Shape Analysis**: Create a tool that reports the array/hash part sizes of a table using `debug.getinfo` or internal heuristics.

6. **GC Stress Test**: Compare incremental vs generational GC performance on a workload with many short-lived objects.

### Advanced (2–4 hours)

7. **Bytecode Compiler**: Write a simple expression compiler that outputs Lua bytecode for arithmetic expressions.

8. **Memory Profiler**: Build a profiler that tracks allocation patterns over time, identifying hotspots.

---

## Example Code

Runnable examples for this chapter:
- `examples/advanced/01-ecs-system.lua` — Performance-conscious table usage
- `examples/advanced/03-object-pool.lua` — GC-aware object reuse

---

## Further Reading

- [Lua 5.4 Reference Manual — Section 1](https://www.lua.org/manual/5.4/manual.html#1)
- [The Evolution of Lua (PDF)](https://www.lua.org/doc/record.pdf)
- [Programming in Lua (4th ed.) — Chapter 30](https://www.lua.org/pil/)
- [Next Chapter: 11 — Lua C API](11-lua-c-api.md)
