# 02 — Control Flow: Conditionals, Loops, and Iteration

> **Phase**: A (Core Language Literacy)  
> **Prerequisites**: Chapter 01 — Basics  
> **Time Estimate**: 2–3 hours reading + 2–4 hours exercises  
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT (differences noted)

---

## Learning Objectives

After completing this chapter, you will be able to:

1. **Write correct conditionals** using Lua's truthiness rules and guard patterns
2. **Choose appropriate loop constructs** (numeric `for`, generic `for`, `while`, `repeat`)
3. **Create custom iterators** using closures and coroutines
4. **Avoid iteration pitfalls** including table modification during iteration
5. **Structure loop exits** using `break` and early returns effectively

---

## Conditionals

### If-Then-Else Structure

Lua's conditional syntax is simple but powerful:

```lua
local mode = "safe"

if mode == "safe" then
  print("guarded")
elseif mode == "fast" then
  print("optimized")
else
  error("unknown mode: " .. tostring(mode))
end
```

### Truthiness in Conditions

Remember: only `false` and `nil` are falsey:

```lua
-- Common patterns
local value = input or default           -- Default if nil or false
local value = (input ~= nil) and input or default  -- Default only if nil

-- Guard patterns
if not config then
  return nil, "config is required"
end

if type(value) ~= "number" then
  error("expected number, got " .. type(value))
end
```

> **Pitfall**: The `or` pattern fails when `false` is a valid value. Use explicit `nil` checks.

### Conditional Assignment

```lua
-- Ternary-like pattern (Lua doesn't have ternary operator)
local max = (a > b) and a or b

-- But be careful with falsey values!
local result = success and value or default  -- WRONG if value can be false
local result = success and value or nil      -- Safer
if not success then result = default end     -- Safest
```

### Multi-Condition Logic

```lua
-- Complex condition with short-circuit evaluation
if enabled and count > 0 and has_permission(user, "edit") then
  save_changes()
end

-- Use parentheses for clarity in complex conditions
if (is_admin or has_permission(user, "delete")) and not is_protected(target) then
  delete(target)
end
```

---

## Loops

### Numeric `for` Loop

Use when you know the iteration count or need index-based access:

```lua
-- Count up
for i = 1, 10 do
  print(i)
end

-- Count down
for i = 10, 1, -1 do
  print(i)
end

-- Custom step
for i = 0, 100, 5 do
  print(i)
end

-- Array iteration (1-indexed!)
local items = {"a", "b", "c"}
for i = 1, #items do
  print(i, items[i])
end
```

**Key points:**
- Loop variable is **local** to the loop body
- Bounds are evaluated **once** at loop start
- Step can be negative (for countdown)

### Generic `for` Loop

Use with iterators (`pairs`, `ipairs`, custom):

```lua
-- All key-value pairs (unordered!)
local t = {a = 1, b = 2, c = 3}
for k, v in pairs(t) do
  print(k, v)
end

-- Array indices (ordered 1..n)
local items = {"x", "y", "z"}
for i, v in ipairs(items) do
  print(i, v)
end

-- Multiple values from iterator
for key, value in some_iterator() do
  -- ...
end
```

> **Warning**: `pairs` iteration order is **not guaranteed**. Don't rely on order!

### While Loop

Use when termination depends on a condition:

```lua
-- Polling pattern
while not done do
  local event = get_next_event()
  process(event)
end

-- Bounded retry
local max_retries = 3
local attempt = 0
while attempt < max_retries do
  local success, err = try_connect()
  if success then break end
  attempt = attempt + 1
  print("Retry " .. attempt .. ": " .. err)
end
```

**Key points:**
- Condition checked **before** each iteration
- Must ensure condition eventually becomes false
- Use `break` for early exit

### Repeat-Until Loop

Use when body must execute at least once:

```lua
-- Input validation
local input
repeat
  print("Enter a number:")
  input = io.read()
until input:match("^%d+$")

-- State machine
local state = "start"
repeat
  state = process_state(state)
until state == "done"
```

**Key points:**
- Condition checked **after** each iteration
- Body always executes at least once
- Similar to `do { ... } while()` in C

---

## Break and Return

### Break Statement

Exit a loop early:

```lua
-- Search with early exit
local function find_first(items, predicate)
  for i, item in ipairs(items) do
    if predicate(item) then
      return i, item  -- Return immediately
    end
  end
  return nil  -- Not found
end

-- Bounded processing
for i = 1, #items do
  if should_stop() then
    break
  end
  process(items[i])
end
```

### Return Patterns

Multiple return values:

```lua
local function divmod(a, b)
  if b == 0 then
    return nil, "division by zero"  -- Error convention
  end
  return a // b, a % b  -- Multiple values
end

local quotient, remainder = divmod(10, 3)
local result, err = divmod(10, 0)
```

Idiom: success, result/error:

```lua
-- Standard Lua error handling pattern
local function safe_operation()
  if not preconditions_met() then
    return nil, "preconditions failed"
  end
  
  local result = do_operation()
  if not result then
    return nil, "operation failed"
  end
  
  return result  -- Success
end

-- Usage
local result, err = safe_operation()
if not result then
  print("Error: " .. err)
else
  process(result)
end
```

---

## Custom Iterators

### Simple Iterator

Create using closure with state:

```lua
-- Range iterator
local function range(start, stop, step)
  step = step or 1
  local i = start - step
  
  return function()
    i = i + step
    if i <= stop then
      return i
    end
  end
end

-- Usage
for i in range(1, 5) do
  print(i)  -- 1, 2, 3, 4, 5
end

for i in range(10, 1, -2) do
  print(i)  -- 10, 8, 6, 4, 2
end
```

### Iterator with Multiple Values

```lua
-- Enumerate with index
local function enumerate(t)
  local i = 0
  return function()
    i = i + 1
    if i <= #t then
      return i, t[i]
    end
  end
end

-- Usage
for i, value in enumerate({"a", "b", "c"}) do
  print(i, value)
end
```

### Stateful Iterator

Iterator that maintains complex state:

```lua
-- File line reader with line numbers
local function lines_with_number(filename)
  local file = assert(io.open(filename, "r"))
  local line_num = 0
  
  return function()
    local line = file:read("line")
    if line then
      line_num = line_num + 1
      return line_num, line:gsub("%s+$", "")  -- Trim trailing whitespace
    else
      file:close()
      return nil
    end
  end
end

-- Usage (if file exists)
-- for num, line in lines_with_number("data.txt") do
--   print(num .. ": " .. line)
-- end
```

### Iterator Using Coroutine

For complex iteration logic:

```lua
local function tree_iterator(node)
  return coroutine.wrap(function()
    local function traverse(n)
      if n.value then
        coroutine.yield(n.value)
      end
      if n.children then
        for _, child in ipairs(n.children) do
          traverse(child)
        end
      end
    end
    traverse(node)
  end)
end

-- Usage
local tree = {
  value = "root",
  children = {
    {value = "child1"},
    {value = "child2", children = {{value = "grandchild"}}}
  }
}

for value in tree_iterator(tree) do
  print(value)
end
```

---

## Iteration Pitfalls

### Modifying Table During Iteration

**BUG**: Modifying keys while iterating:

```lua
-- WRONG: Modifying table during pairs iteration
local t = {a = 1, b = 2, c = 3}
for k, v in pairs(t) do
  if v % 2 == 0 then
    t[k] = nil  -- Dangerous! May skip elements
  end
end

-- RIGHT: Collect keys first, then modify
local t = {a = 1, b = 2, c = 3}
local to_remove = {}
for k, v in pairs(t) do
  if v % 2 == 0 then
    table.insert(to_remove, k)
  end
end
for _, k in ipairs(to_remove) do
  t[k] = nil
end
```

### Assuming pairs Order

**BUG**: Relying on `pairs` iteration order:

```lua
-- WRONG: Order not guaranteed
local config = {host = "localhost", port = 8080, debug = true}
for k, v in pairs(config) do
  print(k .. "=" .. v)  -- Order varies!
end

-- RIGHT: Sort keys if order matters
local config = {host = "localhost", port = 8080, debug = true}
local keys = {}
for k in pairs(config) do
  table.insert(keys, k)
end
table.sort(keys)
for _, k in ipairs(keys) do
  print(k .. "=" .. tostring(config[k]))
end
```

### Off-by-One Errors

**BUG**: Incorrect loop bounds:

```lua
-- WRONG: Misses last element
local items = {1, 2, 3, 4, 5}
for i = 1, #items - 1 do
  print(items[i])
end

-- RIGHT: Include last element
for i = 1, #items do
  print(items[i])
end

-- WRONG: 0-indexed (Lua is 1-indexed!)
for i = 0, #items - 1 do
  print(items[i])  -- items[0] is nil!
end

-- RIGHT: 1-indexed
for i = 1, #items do
  print(items[i])
end
```

### Infinite Loops

**BUG**: Missing state update:

```lua
-- WRONG: No termination
local i = 0
while i < 10 do
  print(i)
  -- Forgot: i = i + 1
end

-- RIGHT: Update state
local i = 0
while i < 10 do
  print(i)
  i = i + 1
end
```

---

## Best Practices

### 1. Guard Early, Return Often

```lua
-- Instead of deep nesting:
function process_user(user)
  if user ~= nil then
    if user.active then
      if user.has_permission then
        -- Do something
      end
    end
  end
end

-- Use guard clauses:
function process_user(user)
  if not user then return end
  if not user.active then return end
  if not user.has_permission then return end
  -- Do something
end
```

### 2. Prefer Numeric `for` for Arrays

```lua
-- Clear and efficient
for i = 1, #array do
  process(array[i])
end

-- More explicit than:
local i = 1
while i <= #array do
  process(array[i])
  i = i + 1
end
```

### 3. Use `ipairs` for Sequential Access

```lua
-- Guaranteed order, stops at first nil
for i, value in ipairs(array) do
  print(i, value)
end
```

### 4. Extract Complex Loop Logic

```lua
-- Instead of complex loop body:
for i = 1, #items do
  if items[i].active and items[i].value > threshold and not items[i].skip then
    -- Complex processing
  end
end

-- Extract to function:
local function should_process(item)
  return item.active and item.value > threshold and not item.skip
end

for i = 1, #items do
  if should_process(items[i]) then
    -- Complex processing
  end
end
```

### 5. Document Iterator Contracts

```lua
--- Iterate over chunks of array
-- @param array input array
-- @param chunk_size number of items per chunk
-- @return iterator function yielding {start_idx, chunk_table}
local function chunks(array, chunk_size)
  -- Implementation
end
```

---

## Version Notes

### Lua 5.2+

- `goto` statement available for complex control flow
- Use sparingly and document clearly

```lua
-- Lua 5.2+
for i = 1, n do
  for j = 1, m do
    if matrix[i][j] == target then
      goto found
    end
  end
end
::found::
print("Found at " .. i .. "," .. j)
```

### LuaJIT

- Numeric `for` loops are heavily optimized
- Keep loop bodies simple for best JIT performance
- Avoid function calls in hot loops when possible

---

## Knowledge Check

<details>
<summary>1. What's the difference between <code>pairs</code> and <code>ipairs</code>?</summary>

`pairs(t)` iterates all key-value pairs (unordered). `ipairs(t)` iterates integer indices 1, 2, 3... until first nil (ordered, array-safe).
</details>

<details>
<summary>2. Why is <code>for i = 0, #array - 1 do</code> wrong in Lua?</summary>

Lua arrays are 1-indexed. `array[0]` is always `nil`. Use `for i = 1, #array do`.
</details>

<details>
<summary>3. What does <code>repeat ... until</code> guarantee that <code>while</code> doesn't?</summary>

The body executes at least once. Condition is checked after, not before.
</details>

<details>
<summary>4. How do you safely remove elements from a table during iteration?</summary>

Collect keys to remove first, then remove in a second pass. Or iterate in reverse order for arrays.
</details>

<details>
<summary>5. What's the standard Lua error handling return pattern?</summary>

On success: `return result`. On error: `return nil, "error message"`. Check with `if not result then`.
</details>

---

## Common Patterns

### Stable Partition

```lua
--- Partition array by predicate, maintaining order
-- @param array input array
-- @param predicate function(item) -> boolean
-- @return two arrays: matching, non_matching
local function partition(array, predicate)
  local matching = {}
  local non_matching = {}
  
  for _, item in ipairs(array) do
    if predicate(item) then
      table.insert(matching, item)
    else
      table.insert(non_matching, item)
    end
  end
  
  return matching, non_matching
end

-- Usage
local numbers = {1, 2, 3, 4, 5, 6}
local evens, odds = partition(numbers, function(n) return n % 2 == 0 end)
```

### Chunked Iteration

```lua
--- Iterate over array in chunks
-- @param array input array
-- @param chunk_size items per chunk
-- @return iterator yielding chunk tables
local function chunks(array, chunk_size)
  local i = 0
  
  return function()
    if i >= #array then return nil end
    
    local chunk = {}
    for j = 1, chunk_size do
      if i + j <= #array then
        table.insert(chunk, array[i + j])
      end
    end
    i = i + chunk_size
    return chunk
  end
end

-- Usage
for chunk in chunks({1, 2, 3, 4, 5, 6, 7}, 3) do
  print("Chunk: " .. table.concat(chunk, ", "))
end
-- Output: {1,2,3}, {4,5,6}, {7}
```

### Retry with Backoff

```lua
--- Execute function with retry logic
-- @param fn function to execute
-- @param max_attempts maximum retry count
-- @param delay initial delay in seconds
-- @return success, result_or_error
local function retry(fn, max_attempts, delay)
  local last_err
  delay = delay or 1
  
  for attempt = 1, max_attempts do
    local success, result = pcall(fn)
    if success then
      return true, result
    end
    last_err = result
    
    if attempt < max_attempts then
      local wait_time = delay * (2 ^ (attempt - 1))  -- Exponential backoff
      print("Attempt " .. attempt .. " failed: " .. last_err)
      print("Retrying in " .. wait_time .. "s...")
      os.sleep(wait_time)  -- Requires LuaSocket or similar
    end
  end
  
  return false, last_err
end
```

---

## Key Takeaways

- **Conditionals**: Only `false` and `nil` are falsey; guard early
- **Numeric `for`**: Use for arrays and known iteration counts
- **Generic `for`**: Use with `pairs` (unordered) or `ipairs` (ordered)
- **While/Repeat**: Use for condition-based termination
- **Custom iterators**: Closures with state or coroutines for complex logic
- **Pitfalls**: Don't modify tables during `pairs` iteration; Lua is 1-indexed
- **Error handling**: Return `nil, error` on failure

---

## Exercises

### Beginner (30–60 min)

1. **Stable Partition**: Implement `partition(array, predicate)` that splits an array into two arrays while maintaining order.

2. **Range Iterator**: Create `range(start, stop, step)` iterator that works with negative steps.

3. **Input Validation**: Write a `read_number(prompt)` function using `repeat-until` that keeps asking until valid input.

### Intermediate (1–2 hours)

4. **Chunked Iterator**: Implement `chunks(array, size)` that yields arrays of `size` elements.

5. **Safe Table Filter**: Create `filter_in_place(table, predicate)` that safely removes elements during iteration.

6. **Bounded Retry**: Implement `retry(fn, max_attempts, delay)` with exponential backoff.

### Advanced (2–4 hours)

7. **Tree Traversal**: Create iterator for nested tree structure using coroutines.

8. **Priority Queue Iterator**: Implement iterator that yields elements in priority order.

---

## Example Code

Runnable examples for this chapter:
- `examples/beginner/01-moving-average.lua` — Loop with accumulation
- `examples/intermediate/03-coroutine-scheduler.lua` — Coroutine-based iteration

---

## Further Reading

- [Lua 5.4 Reference Manual — Section 3.3](https://www.lua.org/manual/5.4/manual.html#3.3)
- [Programming in Lua (4th ed.) — Chapter 4](https://www.lua.org/pil/)
- [Next Chapter: 03 — Functions](03-functions.md)
