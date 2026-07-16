# Debugging Lua Code

> **Phase**: Cross-cutting  
> **Prerequisites**: Chapter 07 — Error Handling  
> **Time Estimate**: 2–3 hours  
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT

---

## Debugging Strategies

Lua doesn't have a built-in interactive debugger in the standard library (unlike Python or Ruby). Debugging relies on:

1. **print-based debugging** — the most common approach
2. **assert()** — catch problems early
3. **pcall/xpcall** — isolate and capture errors
4. **debug library** — runtime introspection
5. **external tools** — IDE debuggers, profilers

---

## print Debugging

The simplest and most universal approach:

```lua
-- Debug variable values
local function process(data)
  print("DEBUG: data =", data)
  print("DEBUG: type =", type(data))
  local result = transform(data)
  print("DEBUG: result =", result)
  return result
end
```

### Structured Debug Output

```lua
-- Prefix all debug output for easy filtering
local DEBUG = true
local function dbg(...)
  if DEBUG then
    local info = debug.getinfo(2, "n")
    local prefix = info and info.name or "?"
    print("[DEBUG " .. prefix .. "]", ...)
  end
end

-- Usage
local function compute(x)
  dbg("x =", x)
  return x * 2
end
```

### Table Inspection

```lua
-- Pretty-print a table
local function dump(t, indent)
  indent = indent or 0
  if type(t) ~= "table" then
    print(string.rep("  ", indent) .. tostring(t))
    return
  end
  print(string.rep("  ", indent) .. "{")
  for k, v in pairs(t) do
    local key = type(k) == "string" and k or "[" .. tostring(k) .. "]"
    if type(v) == "table" then
      print(string.rep("  ", indent + 1) .. key .. " =")
      dump(v, indent + 2)
    else
      print(string.rep("  ", indent + 1) .. key .. " = " .. tostring(v))
    end
  end
  print(string.rep("  ", indent) .. "}")
end
```

---

## assert() for Early Detection

Use `assert` to catch bugs at the point of origin:

```lua
-- Validate inputs at function boundaries
local function divide(a, b)
  assert(type(a) == "number", "a must be number")
  assert(type(b) == "number", "b must be number")
  assert(b ~= 0, "division by zero")
  return a / b
end
```

### assert vs if-then-error

```lua
-- assert is concise for precondition checks
assert(x ~= nil, "x is required")

-- Equivalent but verbose
if x == nil then
  error("x is required")
end
```

---

## pcall/xpcall for Error Isolation

```lua
-- pcall catches errors without crashing
local ok, result = pcall(function()
  return risky_operation()
end)

if not ok then
  print("Error caught:", result)
end

-- xpcall adds a traceback handler
local ok, msg = xpcall(function()
  error("something went wrong")
end, function(err)
  return debug.traceback("Error: " .. tostring(err), 2)
end)

if not ok then
  print(msg)
end
```

---

## debug Library

The `debug` library provides runtime introspection:

### debug.getinfo

```lua
-- Get information about a function
local function my_func() end
local info = debug.getinfo(my_func)
print("Name:", info.name)
print("Source:", info.source)
print("Line defined:", info.linedefined)
print("Params:", info.nparams)
```

### debug.getlocal / debug.setlocal

```lua
-- Inspect local variables in a stack frame
local function inspect_locals(level)
  local i = 1
  while true do
    local name, value = debug.getlocal(level, i)
    if not name then break end
    print(name, "=", value)
    i = i + 1
  end
end
```

### debug.traceback

```lua
-- Get a stack trace at any point
local function deep()
  return debug.traceback("stack trace", 2)
end

local function mid() return deep() end
print(mid())
```

### debug.sethook for Call Tracing

```lua
-- Trace all function calls
local call_count = 0
debug.sethook(function(event)
  if event == "call" then
    call_count = call_count + 1
    local info = debug.getinfo(2, "n")
    print(string.format("Call #%d: %s", call_count, info.name or "?"))
  end
end, "call")

-- Run code
some_function()

debug.sethook()  -- Remove hook
print("Total calls:", call_count)
```

---

## Common Debugging Patterns

### 1. Debug Wrapper

```lua
-- Wrap a function to add debug output
local function debug_wrap(fn, name)
  return function(...)
    print("CALL:", name, ...)
    local results = table.pack(fn(...))
    print("RETURN:", name, table.unpack(results, 1, results.n))
    return table.unpack(results, 1, results.n)
  end
end

local safe_div = debug_wrap(function(a, b)
  return a / b
end, "div")

safe_div(10, 2)  -- Prints call and return
safe_div(10, 0)  -- Prints error
```

### 2. Conditional Breakpoint

```lua
-- Stop at a specific condition
local function find_bug(data)
  for i, v in ipairs(data) do
    if v < 0 then
      print("BREAKPOINT: negative value at index", i, "=", v)
      print(debug.traceback())
      -- Inspect state here
    end
  end
end
```

### 3. Memory Monitoring

```lua
-- Track memory usage
local function mem_report(label)
  collectgarbage("collect")
  local kb = collectgarbage("count")
  print(string.format("[MEM] %s: %.1f KB", label, kb))
end

mem_report("before")
-- ... code ...
mem_report("after")
```

---

## IDE Debugging

### ZeroBrane Studio

- Set breakpoints in Lua code
- Step through execution
- Inspect variables in real time
- Supports local and remote debugging

### VS Code + Lua Extension

- `lua` extension by sumneko
- IntelliSense, debugging, linting
- Supports multiple Lua versions

---

## Profiling

### Built-in Profiling

```lua
-- Simple timing
local start = os.clock()
-- ... code ...
print(string.format("Elapsed: %.6f s", os.clock() - start))
```

### External Profilers

- **luaprofile**: Function-level profiling
- **luatrace**: Trace-based profiling
- **perf + FlameGraph**: System-level profiling

---

## Key Takeaways

- **print debugging** is the most common approach in Lua
- **assert** catches bugs at the point of origin
- **pcall/xpcall** isolates errors without crashing
- **debug library** provides introspection but adds overhead
- **Use structured debug output** (prefixed, filtered) for complex programs
- **IDE debuggers** (ZeroBrane, VS Code) provide breakpoints and step-through
- **Profile before optimizing** — measure first, then optimize
