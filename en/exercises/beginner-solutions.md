# Beginner Exercises — Solutions

Solutions and explanations for beginner-level exercises.

---

## Exercise 1: String Split

### Task
Implement `split(s, sep)` without external libraries.

### Solution

```lua
--- Split string by separator
-- @param s input string
-- @param sep separator pattern
-- @return array of substrings
local function split(s, sep)
  if type(s) ~= "string" then
    error("bad argument #1 to 'split' (string expected)", 2)
  end
  
  sep = sep or "%s"  -- Default to whitespace
  
  local result = {}
  local start = 1
  
  while start <= #s do
    -- Find next separator
    local sep_start, sep_end = s:find(sep, start)
    
    if not sep_start then
      -- No more separators, take rest of string
      table.insert(result, s:sub(start))
      break
    elseif sep_start > start then
      -- Found separator, extract substring before it
      table.insert(result, s:sub(start, sep_start - 1))
    end
    
    -- Move past separator
    start = sep_end + 1
  end
  
  return result
end

-- Test
local parts = split("a,b,c", ",")
assert(#parts == 3)
assert(parts[1] == "a")
assert(parts[2] == "b")
assert(parts[3] == "c")
print("✓ split tests passed")
```

### Key Points

1. **Input validation**: Check that `s` is a string
2. **Default separator**: Use whitespace if not specified
3. **Edge cases**: Handle empty string, no separators, consecutive separators
4. **Pattern matching**: Use `string.find` for pattern support

### Common Mistakes

```lua
-- WRONG: Doesn't handle consecutive separators
local function split_wrong(s, sep)
  for part in s:gmatch("[^" .. sep .. "]+") do
    table.insert(result, part)
  end
  return result
end
-- Fails on: split("a,,b", ",") - skips empty element

-- WRONG: Off-by-one error
local function split_off_by_one(s, sep)
  local result = {}
  local start = 1
  local sep_start, sep_end = s:find(sep, start)
  
  while sep_start do
    table.insert(result, s:sub(start, sep_start))  -- Should be sep_start - 1
    start = sep_end + 1
    sep_start, sep_end = s:find(sep, start)
  end
  
  return result
end
```

---

## Exercise 2: Word Frequency Counter

### Task
Build `count_words(text)` using tables.

### Solution

```lua
--- Count word frequencies in text
-- @param text input string
-- @return table mapping words to counts
local function count_words(text)
  local counts = {}
  
  -- Extract words (alphanumeric sequences)
  for word in text:lower():gmatch("%w+") do
    counts[word] = (counts[word] or 0) + 1
  end
  
  return counts
end

--- Print frequency table sorted by count
-- @param counts word frequency table
local function print_frequencies(counts)
  -- Convert to array for sorting
  local entries = {}
  for word, count in pairs(counts) do
    table.insert(entries, {word = word, count = count})
  end
  
  -- Sort by count (descending)
  table.sort(entries, function(a, b)
    return a.count > b.count
  end)
  
  -- Print
  for _, entry in ipairs(entries) do
    print(string.format("%s: %d", entry.word, entry.count))
  end
end

-- Test
local text = "Lua is great. Lua is fast. Lua is simple."
local freq = count_words(text)

print_frequencies(freq)
-- Expected output (order may vary):
-- lua: 3
-- is: 3
-- great: 1
-- fast: 1
-- simple: 1
```

### Key Points

1. **Pattern matching**: `%w+` matches word characters
2. **Idiom**: `(counts[word] or 0) + 1` for incrementing
3. **Sorting**: Convert to array for custom sort order

### Variations

```lua
-- Case-sensitive version
local function count_words_case_sensitive(text)
  local counts = {}
  for word in text:gmatch("%w+") do
    counts[word] = (counts[word] or 0) + 1
  end
  return counts
end

-- With stop words filtering
local function count_words_filtered(text, stop_words)
  local counts = {}
  stop_words = stop_words or {"the", "a", "an", "is", "are"}
  
  for word in text:lower():gmatch("%w+") do
    if not stop_words[word] then
      counts[word] = (counts[word] or 0) + 1
    end
  end
  return counts
end
```

---

## Exercise 3: Clamp and Lerp

### Task
Write `clamp` and `lerp` utilities with edge-case tests.

### Solution

```lua
--- Clamp value between min and max
-- @param value number to clamp
-- @param min minimum bound
-- @param max maximum bound
-- @return clamped value
local function clamp(value, min, max)
  if value < min then return min end
  if value > max then return max end
  return value
end

-- Alternative (more concise)
local function clamp_alt(value, min, max)
  return math.max(min, math.min(value, max))
end

--- Linear interpolation
-- @param a start value
-- @param b end value
-- @param t interpolation factor (0-1 clamped)
-- @return interpolated value
local function lerp(a, b, t)
  t = clamp(t, 0, 1)
  return a + (b - a) * t
end

--- Inverse lerp: find t given value
-- @param a start value
-- @param b end value
-- @param value current value
-- @return t factor (unclamped)
local function inverse_lerp(a, b, value)
  if a == b then return 0 end  -- Avoid division by zero
  return (value - a) / (b - a)
end

-- Tests
local function test_clamp()
  assert(clamp(5, 0, 10) == 5, "within bounds")
  assert(clamp(-5, 0, 10) == 0, "below min")
  assert(clamp(15, 0, 10) == 10, "above max")
  assert(clamp(0, 0, 10) == 0, "at min")
  assert(clamp(10, 0, 10) == 10, "at max")
  assert(clamp(5, 5, 5) == 5, "min == max")
  print("✓ clamp tests passed")
end

local function test_lerp()
  assert(lerp(0, 100, 0) == 0, "t=0")
  assert(lerp(0, 100, 1) == 100, "t=1")
  assert(lerp(0, 100, 0.5) == 50, "t=0.5")
  assert(lerp(0, 100, 1.5) == 100, "t clamped above")
  assert(lerp(0, 100, -0.5) == 0, "t clamped below")
  assert(lerp(10, 20, 0.5) == 15, "non-zero start")
  print("✓ lerp tests passed")
end

local function test_inverse_lerp()
  assert(inverse_lerp(0, 100, 50) == 0.5, "middle")
  assert(inverse_lerp(0, 100, 0) == 0, "start")
  assert(inverse_lerp(0, 100, 100) == 1, "end")
  assert(inverse_lerp(0, 100, 150) == 1.5, "beyond end")
  assert(inverse_lerp(10, 10, 5) == 0, "same endpoints")
  print("✓ inverse_lerp tests passed")
end

test_clamp()
test_lerp()
test_inverse_lerp()
```

### Key Points

1. **Edge cases**: Test boundaries, equal min/max, division by zero
2. **Clamping**: `lerp` should clamp `t` to [0, 1]
3. **Inverse**: `inverse_lerp` should NOT clamp (may be useful outside [0,1])

---

## Exercise 4: Accidental Global Bug

### Task
Fix bug from accidental global variable overwrite.

### Buggy Code

```lua
-- BUG: This creates a global 'i'
function sum_array(arr)
  local sum = 0
  for i = 1, #arr do  -- 'i' is global!
    sum = sum + arr[i]
  end
  return sum
end

-- BUG: This also creates a global 'i'
function find_max(arr)
  local max = arr[1]
  for i = 2, #arr do  -- Overwrites the 'i' from sum_array!
    if arr[i] > max then
      max = arr[i]
    end
  end
  return max
end

-- Problem: If these run in coroutines or nested calls,
-- the global 'i' causes bugs
```

### Fixed Code

```lua
function sum_array(arr)
  local sum = 0
  for i = 1, #arr do  -- 'i' is now local to this loop
    sum = sum + arr[i]
  end
  return sum
end

function find_max(arr)
  local max = arr[1]
  for i = 2, #arr do  -- 'i' is local to this loop
    if arr[i] > max then
      max = arr[i]
    end
  end
  return max
end

-- In Lua, numeric for loop variables are implicitly local
-- But explicit is better:
function sum_array_explicit(arr)
  local sum = 0
  for i = 1, #arr do
    sum = sum + arr[i]
  end
  return sum
end
```

### Detection

```lua
-- Enable strict mode to catch globals
setmetatable(_G, {
  __newindex = function(_, name)
    error("Attempt to write to global: " .. name, 2)
  end,
  __index = function(_, name)
    error("Attempt to read global: " .. name, 2)
  end,
})
```

---

## Exercise 5: Off-by-One Loop Bug

### Task
Fix off-by-one loop bug in list rendering.

### Buggy Code

```lua
-- BUG: Off-by-one in loop bounds
function render_list(items)
  for i = 1, #items - 1 do  -- Misses last item!
    print(i .. ". " .. items[i])
  end
end

-- BUG: Wrong starting index
function render_list_wrong_start(items)
  for i = 0, #items do  -- items[0] is nil!
    print(i .. ". " .. items[i])
  end
end
```

### Fixed Code

```lua
function render_list(items)
  for i = 1, #items do  -- Correct: 1 to n inclusive
    print(i .. ". " .. items[i])
  end
end

-- Or using ipairs (preferred)
function render_list_safe(items)
  for i, item in ipairs(items) do
    print(i .. ". " .. item)
  end
end
```

### Key Points

1. **Lua arrays are 1-indexed**: Start at 1, not 0
2. **Loop bounds**: `for i = 1, #items` includes both endpoints
3. **Use `ipairs`**: Safer than manual indexing

---

## Exercise 6: Table Length with Holes

### Task
Fix incorrect `#t` usage on table with holes.

### Buggy Code

```lua
-- BUG: #t is undefined for tables with holes
local t = {1, 2, nil, 4, 5}
print(#t)  -- Could be 2, 4, or 5 (undefined!)

-- BUG: Assuming #t works after removing elements
local items = {1, 2, 3, 4, 5}
items[3] = nil
print(#items)  -- Undefined behavior!
```

### Fixed Code

```lua
-- Solution 1: Use ipairs for iteration (ignores holes)
local function count_elements(t)
  local count = 0
  for _ in ipairs(t) do
    count = count + 1
  end
  return count
end

-- Solution 2: Use table.remove instead of nil assignment
local items = {1, 2, 3, 4, 5}
table.remove(items, 3)  -- Properly removes and shifts
print(#items)  -- 4 (well-defined)

-- Solution 3: Don't create holes
local t = {1, 2, 4, 5}  -- Explicit, no holes
print(#t)  -- 4 (well-defined)

-- Solution 4: Use a length-tracking wrapper
local function create_list()
  local self = {
    _data = {},
    _length = 0,
  }
  
  function self:push(value)
    self._length = self._length + 1
    self._data[self._length] = value
  end
  
  function self:length()
    return self._length
  end
  
  return self
end

local list = create_list()
list:push(1)
list:push(2)
list:push(3)
print(list:length())  -- 3 (always correct)
```

### Key Points

1. **`#t` is only well-defined for sequences** (no holes)
2. **Use `table.remove`** instead of `t[i] = nil`
3. **Use `ipairs`** for safe iteration
4. **Track length explicitly** if you need to support holes

---

## Design Question Solutions

### 1. Nullable Fields in Lua Tables

```lua
-- Pattern 1: Explicit nil marker
local user = {
  name = "Alice",
  email = nil,  -- Explicitly no email
  _has_email = false,  -- Distinguish from "not set"
}

-- Pattern 2: Sentinel value
local NONE = {}  -- Unique sentinel
local user = {
  name = "Alice",
  email = NONE,  -- No email
}

if user.email == NONE then
  -- Definitely no email
end

-- Pattern 3: Separate existence map
local user = {
  name = "Alice",
  data = {},
  _fields = {
    email = true,  -- Field exists
    phone = false, -- Field doesn't exist
  }
}
```

### 2. Testable Module API Style

```lua
-- Best: Stateless functions with explicit dependencies
local M = {}

function M.process(data, config)
  -- Pure function, easy to test
  return result
end

-- mymodule.lua returns M
local exported = M

-- Test usage:
local M = exported
local result = M.process(test_data, test_config)
assert(result == expected)

-- Avoid: Hidden state
local state = {}
function M.process(data)
  -- Uses hidden state, hard to test
  return result
end
```

### 3. Error Handling Boundaries

```lua
-- Small script: Top-level pcall
local success, err = pcall(function()
  main()
end)
if not success then
  print("Error: " .. err)
  os.exit(1)
end

-- Larger project: Layered boundaries
-- 1. Module level: Validate inputs, return errors
function M.process(data)
  if not data then
    return nil, "data is required"
  end
  -- ...
end

-- 2. Service level: Handle module errors
local result, err = M.process(data)
if not result then
  log_error(err)
  return nil, err
end

-- 3. Application level: User-facing errors
local success, err = pcall(service.run)
if not success then
  show_user_friendly_error(err)
end
```

---

## Testing Your Solutions

```lua
-- Test harness template
local function run_tests()
  local passed = 0
  local failed = 0
  
  local function test(name, fn)
    local success, err = pcall(fn)
    if success then
      passed = passed + 1
      print("✓ " .. name)
    else
      failed = failed + 1
      print("✗ " .. name .. ": " .. err)
    end
  end
  
  test("split basic", function()
    local parts = split("a,b,c", ",")
    assert(#parts == 3)
  end)
  
  test("count_words basic", function()
    local freq = count_words("a a b")
    assert(freq.a == 2)
    assert(freq.b == 1)
  end)
  
  -- Add more tests...
  
  print(string.format("\nResults: %d passed, %d failed", passed, failed))
  return failed == 0
end

run_tests()
```

---

## Next Steps

After completing these exercises:

1. **Review** the solutions and compare with your approach
2. **Experiment** with variations and edge cases
3. **Move on** to [Intermediate Exercises](intermediate.md)
