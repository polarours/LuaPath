# 07 — Error Handling

> **Phase**: B (Meta Layer and Architecture)  
> **Prerequisites**: Chapter 06 — Modules  
> **Time Estimate**: 2–3 hours reading + 2–4 hours exercises  
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT (differences noted)

---

## Learning Objectives

After completing this chapter, you will be able to:

1. **Use `pcall` and `xpcall`** to catch and handle errors safely
2. **Choose between error styles** — throw (exception) vs. return (result) — and apply them consistently
3. **Propagate errors with context** using stack traces and error wrapping
4. **Design error taxonomies** with machine-readable codes and human-readable messages
5. **Set error boundaries** at module or task edges to prevent cascading failures

---

## Lua's Error Model

Lua uses **non-local jumps** for error handling. When `error()` is called, Lua unwinds the stack until it finds a `pcall` or `xpcall` handler.

```lua
-- error() throws — execution stops here
function dangerous()
  error("something went wrong")
end

-- Without pcall, this crashes the program
dangerous()  -- ERROR: something went wrong
```

### error() Levels

The second argument to `error()` controls the stack level reported:

```lua
local function helper()
  error("bad input", 2)  -- Reports error at caller's level
end

local function wrapper()
  helper()
end

wrapper()  -- Error points to wrapper(), not helper()
```

| Level | Meaning |
|-------|---------|
| 1 (default) | Points to the `error()` call itself |
| 2 | Points to the function that called `error()` |
| 0 | No position information |

---

## Protected Calls: `pcall`

`pcall` calls a function in protected mode. If the function throws, `pcall` catches it:

```lua
-- pcall returns: success, result_or_error
local ok, result = pcall(function()
  return 42
end)
print(ok, result)  -- true  42

local ok, err = pcall(function()
  error("boom")
end)
print(ok, err)  -- false  boom
```

### pcall with Arguments

```lua
local function divide(a, b)
  if b == 0 then error("division by zero") end
  return a / b
end

local ok, result = pcall(divide, 10, 2)
print(ok, result)  -- true  5

local ok, err = pcall(divide, 10, 0)
print(ok, err)  -- false  division by zero
```

### pcall Limitations

- No custom error handler (gets raw error message)
- No access to the stack trace at throw time
- Cannot resume after error in the same coroutine

```lua
-- Limitation: no traceback
local ok, err = pcall(function()
  local function a() error("fail") end
  local function b() a() end
  b()
end)
print(err)  -- "fail" (no trace of a() or b())
```

---

## Extended Protected Calls: `xpcall`

`xpcall` adds a **message handler** that processes the error before `xpcall` returns:

```lua
local function trace_handler(err)
  return debug.traceback(err, 2)
end

local ok, msg = xpcall(function()
  local function a() error("fail") end
  local function b() a() end
  b()
end, trace_handler)

print(ok)   -- false
print(msg)  -- fail
            -- stack traceback:
            --   [string "..."]:4: in function <...:3>
            --   [string "..."]:5: in function <...:4>
            --   ...
```

### Custom Error Processors

```lua
-- Add context to errors
local function context_handler(err)
  return string.format("[%s] %s", os.date("%H:%M:%S"), tostring(err))
end

local ok, msg = xpcall(function()
  error("disk full")
end, context_handler)

print(msg)  -- "[14:32:05] disk full"
```

---

## Error Styles

### Result Style (Expected Failures)

Return `nil, error_message` for failures that are part of normal operation:

```lua
local function parse_number(s)
  local n = tonumber(s)
  if n == nil then
    return nil, "not a number: " .. tostring(s)
  end
  return n
end

local value, err = parse_number("abc")
if not value then
  print("Error: " .. err)  -- Error: not a number: abc
end
```

**When to use**: I/O operations, parsing, user input, network calls — anything that fails regularly.

### Exception Style (Unexpected Failures)

Throw errors for conditions that should never happen:

```lua
local function get_player(id)
  local player = db.find_player(id)
  if not player then
    error("player not found: " .. tostring(id))
  end
  return player
end

-- This is a bug if it happens — programmer error
local player = get_player(invalid_id)  -- Should crash to surface the bug
```

**When to use**: Programming errors, invariant violations, impossible states.

### Mixing Styles

```lua
-- GOOD: Clear separation
local function read_config(path)
  local file, err = io.open(path, "r")  -- Result style: I/O can fail
  if not file then
    return nil, "cannot open: " .. err
  end

  local content = file:read("*a")
  file:close()

  if not content then
    return nil, "cannot read: " .. path
  end

  local config = parse_config(content)
  if not config then
    error("corrupt config file: " .. path)  -- Exception: parse failure = bug
  end

  return config
end
```

---

## Error Propagation

### Wrapping with Context

Add context when re-throwing errors:

```lua
local function load_user_config(path)
  local config, err = read_config(path)
  if not config then
    return nil, "load_user_config failed: " .. (err or "unknown error")
  end
  return config
end

local function init_app()
  local config, err = load_user_config("app.conf")
  if not config then
    return nil, "init_app: " .. err
  end
  -- ...
  return true
end
```

### Structured Errors

Return structured error objects instead of plain strings:

```lua
local function make_error(code, message, details)
  return {
    code = code,
    message = message,
    details = details,
    traceback = debug.traceback("", 2),
  }
end

local function parse_json(text)
  if type(text) ~= "string" then
    return nil, make_error("E_TYPE", "expected string", {got = type(text)})
  end
  if text == "" then
    return nil, make_error("E_EMPTY", "empty input")
  end
  -- ...
end

local result, err = parse_json(42)
if err then
  print(err.code)      -- "E_TYPE"
  print(err.message)   -- "expected string"
  print(err.details.got)  -- "number"
end
```

---

## Assertion

`assert` is a convenience for throwing on false conditions:

```lua
-- assert(condition, message) throws if condition is false/nil
local config = assert(load_config("app.conf"), "failed to load config")
local n = assert(tonumber(input), "invalid number: " .. tostring(input))
```

### assert vs. Manual Check

```lua
-- Equivalent:
assert(type(x) == "number", "x must be number")

-- To:
if type(x) ~= "number" then
  error("x must be number")
end
```

> **Use assert for precondition checks.** It's concise and makes the contract explicit.

---

## Error Boundaries

Define where errors are caught and how they propagate:

```
┌─────────────────────────────────────┐
│  Application Layer                  │
│  (catches all errors, reports)      │
│  ┌────────────────────────────────┐ │
│  │  Module Layer                  │ │
│  │  (result-style for I/O,        │ │
│  │   exception-style for bugs)    │ │
│  │  ┌──────────────────────────┐  │ │
│  │  │  Core Logic              │  │ │
│  │  │  (throws on bugs)        │  │ │
│  │  └──────────────────────────┘  │ │
│  └────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Top-Level Handler

```lua
local function main()
  local ok, err = xpcall(run_app, function(e)
    return debug.traceback(tostring(e), 2)
  end)

  if not ok then
    io.stderr:write("Fatal error:\n" .. tostring(err) .. "\n")
    os.exit(1)
  end
end

main()
```

### Coroutine Error Boundaries

```lua
local function run_task(task_fn)
  return coroutine.create(function()
    local ok, err = pcall(task_fn)
    if not ok then
      -- Log and terminate coroutine cleanly
      log.error("Task failed: " .. tostring(err))
    end
  end)
end
```

---

## debug Library for Errors

### debug.traceback

Get a stack trace at any point:

```lua
local function deep()
  return debug.traceback("stack trace", 2)
end

local function mid() return deep() end
local function shallow() return mid() end

print(shallow())
-- stack traceback:
--   [string "..."]:5: in function 'deep'
--   [string "..."]:8: in function 'mid'
--   [string "..."]:9: in function 'shallow'
```

### debug.getinfo

Get information about a function's location:

```lua
local function my_func() end
local info = debug.getinfo(my_func)
print(info.what)    -- "Lua"
print(info.source)  -- "@..."
print(info.linedefined)  -- Line where function was defined
```

---

## Common Pitfalls

### 1. Swallowing Errors

```lua
-- BAD: Error disappears
local ok, err = pcall(risky_operation)
-- ok is false, but we never check it!

-- GOOD: Always handle the result
local ok, err = pcall(risky_operation)
if not ok then
  log.error("Operation failed: " .. tostring(err))
  return nil, err
end
```

### 2. Losing Stack Context

```lua
-- BAD: No context added
local function process()
  local data = assert(read_data())  -- Error message: "file not found"
  return transform(data)
end

-- GOOD: Add context
local function process()
  local data, err = read_data()
  if not data then
    return nil, "process: " .. (err or "read_data failed")
  end
  return transform(data)
end
```

### 3. Using Errors for Control Flow

```lua
-- BAD: Error for expected case
local function find_item(items, target)
  for _, item in ipairs(items) do
    if item == target then return item end
  end
  error("not found")  -- This is expected, not exceptional!
end

-- GOOD: Return nil for expected cases
local function find_item(items, target)
  for _, item in ipairs(items) do
    if item == target then return item end
  end
  return nil  -- Not found is normal
end
```

### 4. Not Using xpcall When Tracebacks Matter

```lua
-- pcall: no traceback
local ok, err = pcall(function()
  helper_function()  -- Error inside helper
end)
-- err = "something went wrong" (where?)

-- xpcall: full traceback
local ok, err = xpcall(function()
  helper_function()
end, debug.traceback)
-- err = "something went wrong\nstack traceback:\n  ..."
```

### 5. Error Objects Without Codes

```lua
-- BAD: Hard to match programmatically
if err == "file not found" then ... end  -- Fragile string matching

-- GOOD: Structured errors
if err and err.code == "E_FILE_NOT_FOUND" then ... end
```

---

## Best Practices

### 1. Define Error Categories

```lua
-- error_codes.lua
return {
  E_PARSE        = "E_PARSE",
  E_IO           = "E_IO",
  E_STATE        = "E_STATE",
  E_TYPE         = "E_TYPE",
  E_NETWORK      = "E_NETWORK",
  E_AUTH         = "E_AUTH",
}
```

### 2. Add Context Before Rethrowing

```lua
local function do_something()
  local result, err = lower_level_operation()
  if not result then
    return nil, "do_something: " .. err
  end
  return result
end
```

### 3. Keep Failure Boundaries at Module Edges

```lua
-- Module boundary catches and wraps
function M.process(input)
  local ok, result = pcall(internal_process, input)
  if not ok then
    return nil, {code = "E_INTERNAL", message = tostring(result)}
  end
  return result
end
```

### 4. Use assert for Preconditions

```lua
function M.transfer(from, to, amount)
  assert(type(amount) == "number", "amount must be number")
  assert(amount > 0, "amount must be positive")
  assert(from.balance >= amount, "insufficient funds")
  -- Transfer logic
end
```

### 5. Log Before Rethrowing

```lua
local function handle_request(req)
  local result, err = process(req)
  if not result then
    log.warn("Request failed", {error = err, request = req.id})
    return nil, err  -- Still propagate to caller
  end
  return result
end
```

---

## Version Notes

### Lua 5.1

- `pcall` and `xpcall` available
- `error()` level 0 not available
- `debug.traceback` available

### Lua 5.2/5.3

- `pcall` can yield (coroutine-safe in 5.2+)
- `xpcall` message handler receives the error
- Level 0 in `error()` available

### Lua 5.4

- `error()` with level 0 omits position information entirely
- `pcall` with multiple returns preserves all values on success

### LuaJIT

- `pcall`/`xpcall` performance is good
- JIT traces may be aborted on error paths
- Avoid heavy error handling in hot loops

---

## Knowledge Check

<details>
<summary>1. What's the difference between <code>pcall</code> and <code>xpcall</code>?</summary>

`pcall(fn)` catches errors but gives you only the raw error. `xpcall(fn, handler)` lets you process the error through a handler function before it's returned, enabling tracebacks and error wrapping.
</details>

<details>
<summary>2. When should you use error style vs. result style?</summary>

Use error/exception style for programming bugs and invariant violations (should never happen). Use result style (return nil, err) for expected failures like I/O errors, parsing failures, or missing data.
</details>

<details>
<summary>3. Why is <code>error("msg", 2)</code> better than <code>error("msg")</code> in helper functions?</summary>

Level 2 makes the error point to the caller of the helper, not the helper itself. This gives users a more useful location for debugging.
</details>

<details>
<summary>4. What problem does error wrapping solve?</summary>

Without wrapping, error messages lose context about where they originated. Wrapping adds the calling function's name, creating a chain: "init: load_config: read_file: no such file".
</details>

<details>
<summary>5. Why shouldn't you use errors for control flow?</summary>

`pcall` is expensive (saves/restores stack). Throwing for expected cases (like "item not found") wastes resources and obscures real bugs. Use `return nil` for expected failures.
</details>

---

## Key Takeaways

- **`pcall`** catches errors; **`xpcall`** adds a message handler
- **Result style**: `return nil, err` for expected failures
- **Exception style**: `error()` for programming bugs
- **Add context** when propagating errors up the call stack
- **Structured errors** with codes enable programmatic handling
- **Error boundaries** should be at module or task edges
- **`assert`** is concise for precondition checks
- **Never swallow errors** — always handle the `ok, err` return

---

## Exercises

### Beginner (30–60 min)

1. **Safe Division**: Write `safe_divide(a, b)` that returns `nil, "division by zero"` instead of throwing.

2. **Retry**: Implement `retry(fn, n)` that calls `fn` up to `n` times, returning the first success or the last error.

3. **Assert Helpers**: Create `assert_type(x, t)` and `assert_positive(n)` that throw descriptive errors.

### Intermediate (1–2 hours)

4. **Structured Error**: Design an `Error` class with `code`, `message`, `details`, and `traceback`. Write `wrap_error(err, context)` to add context.

5. **Error Aggregator**: Build a collector that gathers multiple errors during a batch operation and returns them all at once.

6. **Circuit Breaker**: Implement a circuit breaker that stops calling a failing function after N errors, recovering after a timeout.

### Advanced (2–4 hours)

7. **Error Recovery**: Write a `recover(fn, fallback)` function that catches errors from `fn` and calls `fallback` with the error, allowing graceful degradation.

8. **Error Middleware**: Design an error handling middleware chain (like HTTP middleware) where each layer can inspect, log, transform, or re-throw errors.

---

## Example Code

Runnable examples for this chapter:
- `examples/intermediate/02-event-bus.lua` — Error handling in event dispatch
- `examples/advanced/02-sandbox-environment.lua` — pcall-based sandboxing

---

## Further Reading

- [Lua 5.4 Reference Manual — Section 2.3](https://www.lua.org/manual/5.4/manual.html#2.3)
- [Programming in Lua (4th ed.) — Chapter 8](https://www.lua.org/pil/)
- [Next Chapter: 08 — Coroutines](08-coroutines.md)
