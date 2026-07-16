# 01 — Basics: Values, Types, and Scope

> **Phase**: A (Core Language Literacy)  
> **Prerequisites**: None — this is the starting point  
> **Time Estimate**: 2–3 hours reading + 2–4 hours exercises  
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT (differences noted)

---

## Learning Objectives

After completing this chapter, you will be able to:

1. **Distinguish Lua's 8 runtime types** and explain which are reference vs. value types
2. **Write scope-correct code** using `local` appropriately and avoiding accidental globals
3. **Predict truthiness** of any Lua value in boolean context
4. **Explain version differences** in number representation (5.1 vs 5.3+)
5. **Identify performance implications** of string immutability and table references

---

## Core Types

Lua has 8 runtime types, divided into two categories:

### Value Types (copied by value)

| Type | Description | Notes |
|------|-------------|-------|
| `nil` | Absence of value | Only `nil` is `nil` type |
| `boolean` | `true` or `false` | Used in conditions |
| `number` | Numeric values | Integer or float (5.3+) |

### Reference Types (copied by reference)

| Type | Description | Notes |
|------|-------------|-------|
| `string` | Immutable character sequences | Interned for equality |
| `table` | Associative arrays | The only data structure |
| `function` | Callable code | First-class citizens |
| `thread` | Coroutine state | Independent execution |
| `userdata` | Opaque C data | Bridge to native code |

```lua
-- Checking types
print(type(nil))             -- "nil"
print(type(true))            -- "boolean"
print(type(42))              -- "number" (or "integer" in 5.3+)
print(type("hello"))         -- "string"
print(type({}))              -- "table"
print(type(function() end))  -- "function"
print(type(coroutine.create(function() end)))  -- "thread"
```

> **Version Note (5.3+)**: Lua 5.3 distinguishes integers from floats. `type(42)` returns `"integer"` and `type(3.14)` returns `"float"`. In 5.1 and 5.2, both return `"number"`.

---

## Truthiness Rules

Lua has simple but important rules for boolean evaluation:

```
Falsey values:  false, nil
Truthy values:  everything else (including 0, "", {}, function() end)
```

This differs from many languages:

| Language | Falsey Values |
|----------|---------------|
| Lua | `false`, `nil` |
| JavaScript | `false`, `null`, `undefined`, `0`, `""`, `NaN`, `[]` (arrays are truthy!) |
| Python | `False`, `None`, `0`, `""`, `[]`, `{}`, `set()` |
| Ruby | `false`, `nil` (same as Lua) |

### Practical Implications

```lua
-- Common pattern: provide default value
local name = input or "Anonymous"  -- Works if input is nil or false

-- But be careful: false is a valid value!
local config = options.debug or false  -- WRONG: always false if options.debug is false
local config = options.debug ~= nil and options.debug or false  -- CORRECT

-- Checking for nil specifically
if value == nil then ... end      -- Explicit
if value ~= nil then ... end      -- Explicit negative

-- Don't do this (fails for false, 0, "")
if value then ... end             -- Only checks truthiness
```

> **Pitfall**: The `or` pattern (`value or default`) fails when `false` is a meaningful value. Use explicit `nil` checks when `false` is valid input.

---

## Variables and Scope

### Local Variables (Preferred)

```lua
local x = 10        -- Function or block scope
local y = x + 5     -- Can reference earlier locals
```

**Why `local` is faster:**

1. **Register allocation**: Locals map to VM registers (direct access)
2. **No hash lookup**: Globals require `_ENV` table access
3. **Compiler optimization**: Local scope enables better optimization

### Global Variables (Use Sparingly)

```lua
global = 42         -- Actually _ENV["global"] = 42
```

Every global access is a table lookup:

```lua
-- This code:
print(math.sin(0))

-- Is actually:
_ENV["print"](_ENV["math"].sin(0))
```

### Block Scope

```lua
local x = 10

do
  local x = 20      -- New variable, shadows outer x
  print(x)          -- 20
end

print(x)            -- 10 (outer x unchanged)

-- Common pattern: limit variable lifetime
do
  local temp = compute_expensive()
  use(temp)
  -- temp goes out of scope, eligible for GC
end
```

### Function Scope

```lua
local function outer()
  local x = 1
  
  local function inner()
    print(x)        -- Can access outer's locals (upvalue)
  end
  
  inner()
end
```

---

## Number Representation

### Lua 5.1 and 5.2

Single `number` type, typically IEEE 754 double-precision float:

```lua
-- Lua 5.1
print(type(42))       -- "number"
print(type(3.14))     -- "number"
print(42 == 42.0)     -- true (same value)
```

**Implications:**
- Integers > 2^53 lose precision
- No integer-specific operations
- Bitwise operations require `bit32` library or external module

### Lua 5.3 and Later

Dual representation: `integer` and `float`:

```lua
-- Lua 5.3+
print(type(42))       -- "integer"
print(type(3.14))     -- "float"
print(42 == 42.0)     -- true (coerced for comparison)

-- Integer division
print(5 // 2)         -- 2 (integer result)
print(5 / 2)          -- 2.5 (float result)

-- Bitwise operators
print(5 | 3)          -- 7 (bitwise OR)
print(5 & 3)          -- 1 (bitwise AND)
print(5 ~ 3)          -- 6 (bitwise XOR)
print(~5)             -- -6 (bitwise NOT)
print(5 << 1)         -- 10 (left shift)
print(5 >> 1)         -- 2 (right shift)
```

> **Version Note**: LuaJIT uses a single number type but provides FFI for C-style integers (`ffi.cast("int", 42)`).

---

## Strings

### Immutability

Strings in Lua are immutable. Operations create new strings:

```lua
local s = "hello"
local t = s .. " world"  -- Creates new string, s unchanged
print(s)                  -- "hello"
print(t)                  -- "hello world"
```

### Performance Implications

**Inefficient** — O(n²) allocations:

```lua
local result = ""
for i = 1, 10000 do
  result = result .. i .. ", "  -- Creates new string each iteration!
end
```

**Efficient** — O(n) allocations:

```lua
local parts = {}
for i = 1, 10000 do
  parts[#parts + 1] = tostring(i)
  parts[#parts + 1] = ", "
end
local result = table.concat(parts)  -- Single allocation
```

### String Interning

Lua interns (deduplicates) string literals:

```lua
local a = "hello"
local b = "hello"
print(a == b)             -- true (same interned string)
print(rawequal(a, b))     -- true for equal strings in Lua

local c = string.rep("h", 5)  -- "hhhhh"
print(c == "hello")           -- false (different content)
```

---

## Tables: Reference Semantics

Tables are reference types. Assignment copies the reference, not the contents:

```lua
local a = {x = 1}
local b = a          -- b references same table as a
b.x = 2

print(a.x)           -- 2 (a affected by change to b!)
print(b.x)           -- 2
print(a == b)        -- true (same object)
```

### Identity vs. Equality

```lua
local a = {1, 2, 3}
local b = {1, 2, 3}

print(a == b)        -- false (different objects, same content)
print(a ~= b)        -- true

-- To compare contents, you must iterate:
local function deep_equal(x, y)
  if type(x) ~= type(y) then return false end
  if type(x) ~= "table" then return x == y end
  
  for k, v in pairs(x) do
    if not deep_equal(v, y[k]) then return false end
  end
  for k, v in pairs(y) do
    if not deep_equal(x[k], v) then return false end
  end
  return true
end

print(deep_equal(a, b))  -- true (same content)
```

---

## Common Pitfalls

### 1. Accidental Globals

```lua
-- BUG: Missing 'local'
function compute()
  result = 42  -- Creates global!
  return result
end

-- FIX: Always use local
function compute()
  local result = 42
  return result
end
```

**Detection**: Use `luac -l` or enable strict mode:

```lua
-- Strict mode (Lua 5.2+)
setmetatable(_G, {
  __newindex = function(_, name)
    error("Attempt to write to global: " .. name, 2)
  end
})
```

### 2. Assuming `0` is Falsey

```lua
-- BUG: 0 is truthy in Lua
if count ~= 0 then  -- Correct
  process()
end

-- WRONG:
if count then  -- Fails when count is 0!
  process()
end
```

### 3. Table Comparison with `==`

```lua
-- BUG: Comparing references, not content
local a = {1, 2, 3}
local b = {1, 2, 3}

if a == b then  -- Always false!
  print("same")
end

-- FIX: Compare contents explicitly
```

### 4. String Concatenation in Loops

See [Strings](#strings) above for the efficient pattern.

---

## Best Practices

### 1. Default to `local`

```lua
-- Good habit
local function helper() end  -- Not visible outside module
local TEMP = {}              -- Reusable temp table
```

### 2. Explicit Module Return

```lua
-- mymodule.lua
local M = {}

function M.public() end

local function private() end

return M  -- Explicit, clear
```

### 3. Document Table Shape

```lua
-- Clear contract
local player = {
  id = 1,
  name = "Hero",
  position = {x = 100, y = 200},  -- {x: number, y: number}
  health = 100,                    -- [0, 100]
}
```

### 4. Cache Globals in Hot Paths

```lua
-- Module-level caching
local sin = math.sin
local cos = math.cos

local function compute()
  for i = 1, 1000000 do
    local x = sin(i)  -- Direct access, not _ENV lookup
  end
end
```

---

## Knowledge Check

Test your understanding:

<details>
<summary>1. What does <code>type(0)</code> return?</summary>

`"number"` (Lua 5.1-5.2) or `"integer"` (Lua 5.3+). Zero is a valid number, not falsey.
</details>

<details>
<summary>2. What is the output of <code>print(nil or false or 0 or "" or "end")</code>?</summary>

`0`. The `or` operator returns the first truthy value. `nil` and `false` are falsey, `0` is truthy.
</details>

<details>
<summary>3. Why is <code>local x = math.sin</code> faster than using <code>math.sin</code> directly?</summary>

`local` variables are stored in VM registers. `math.sin` requires two table lookups: `_ENV["math"]` then `["sin"]`.
</details>

<details>
<summary>4. What's wrong with: <code>if value or default then use(value) end</code>?</summary>

If `value` is `false` but meaningful, the condition still passes and `use(false)` is called. Use explicit `nil` check: `if value ~= nil then use(value) else use(default) end`.
</details>

<details>
<summary>5. In Lua 5.3+, what is <code>type(5 // 2)</code>?</summary>

`"integer"`. The `//` operator performs integer division and returns an integer.
</details>

---

## Version Summary

| Feature | Lua 5.1 | Lua 5.3 | Lua 5.4 | LuaJIT |
|---------|---------|---------|---------|--------|
| Number types | 1 (float) | 2 (int, float) | 2 (int, float) | 1 (float) + FFI |
| Integer division | ✗ | `//` | `//` | `//` (extension) |
| Bitwise operators | ✗ | ✓ | ✓ | ✓ (extension) |
| `_ENV` | ✗ | ✓ | ✓ | Partial |
| `setfenv`/`getfenv` | ✓ | ✗ | ✗ | ✓ |

---

## Exercises

### Beginner (30–60 min)

1. **Moving Average**: Write a function that computes the moving average of an array. Use only `local` variables.

2. **Trim Function**: Implement `trim(s)` that removes leading and trailing whitespace. Handle edge cases: `nil`, empty string, all-whitespace.

3. **Global Detection**: Create a script that demonstrates an accidental global bug, then fix it.

### Intermediate (1–2 hours)

4. **Type-Safe Defaults**: Write a function `get_with_default(table, key, default)` that correctly handles when `default` might be `false` or `nil`.

5. **String Builder**: Implement a `StringBuilder` module with `append()`, `clear()`, and `toString()` methods. Compare performance with naive concatenation.

### Advanced (2–4 hours)

6. **Deep Equality**: Implement `deep_equal(a, b)` that handles circular references. Document limitations.

7. **Strict Mode Module**: Create a module that provides strict global detection with configurable whitelist.

---

## Key Takeaways

- **8 types**: `nil`, `boolean`, `number`, `string`, `table`, `function`, `thread`, `userdata`
- **Truthiness**: Only `false` and `nil` are falsey; `0` and `""` are truthy
- **Scope**: Use `local` by default; globals are `_ENV` lookups
- **Strings**: Immutable; use `table.concat` for building strings in loops
- **Tables**: Reference semantics; `==` compares identity, not content
- **Version awareness**: Number types and operators differ in 5.3+

---

## Further Reading

- [Lua 5.4 Reference Manual — Section 2](https://www.lua.org/manual/5.4/manual.html#2)
- [Lua 5.1 Reference Manual — Section 2](https://www.lua.org/manual/5.1/manual.html#2)
- [Programming in Lua (4th ed.) — Chapter 1–3](https://www.lua.org/pil/)
- [Next Chapter: 02 — Control Flow](02-control-flow.md)

---

## Example Code

Runnable examples for this chapter are in:
- `examples/beginner/01-moving-average.lua`
- `examples/beginner/02-trim-function.lua`
- `examples/beginner/04-clamp-lerp.lua`
