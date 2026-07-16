# 04 — Tables

> **Phase**: A (Core Language Literacy)  
> **Prerequisites**: Chapter 03 — Functions  
> **Time Estimate**: 2–3 hours reading + 2–4 hours exercises  
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT (differences noted)

---

## Learning Objectives

After completing this chapter, you will be able to:

1. **Explain Lua's dual table representation** (array part + hash part) and its performance implications
2. **Use the length operator correctly** and understand when its behavior is undefined
3. **Construct tables** using all syntax forms and choose the right one for each situation
4. **Apply reference semantics** to avoid aliasing bugs
5. **Use the table library** effectively for common operations (insert, remove, sort, concat)

---

## Table as Core Data Structure

Tables are Lua's **only** data structure. They implement arrays, maps, records, sets, and objects:

```lua
-- Array (sequential integer keys)
local array = {10, 20, 30}

-- Map (arbitrary keys)
local map = {name = "Lua", version = 5.4}

-- Record (fixed fields)
local point = {x = 100, y = 200}

-- Set (values as keys)
local set = {apple = true, banana = true, cherry = true}

-- Object (methods via metatable)
local obj = {value = 0}
function obj:inc() self.value = self.value + 1 end
```

---

## Array Part vs Hash Part

Internally, Lua splits each table into two parts:

| Part | Keys | Lookup | Use Case |
|------|------|--------|----------|
| Array part | Contiguous integers starting at 1 | Direct index (O(1)) | Lists, sequences |
| Hash part | Everything else | Hash table (O(1) amortized) | Maps, records, mixed |

```lua
-- Primarily uses array part (dense integer keys 1..3)
local array = {10, 20, 30}

-- Primarily uses hash part (string keys)
local record = {name = "Lua", version = 5.4}

-- Mixed: array part for 1..3, hash part for "extra"
local mixed = {10, 20, 30, extra = "value"}
```

### Why This Matters for Performance

```lua
-- GOOD: Dense array — array part, cache-friendly
local items = {}
for i = 1, 10000 do
  items[i] = i * 2
end

-- BAD: Sparse array — hash part, slower iteration
local items = {}
items[1] = "a"
items[10000] = "b"
-- #items is undefined (see Length Operator below)
```

### Pre-Allocating Tables

Lua grows tables dynamically. Pre-allocation avoids repeated reallocation:

```lua
-- Pre-allocate with known size
local result = {}
for i = 1, 10000 do
  result[i] = compute(i)  -- Already has space
end

-- Constructor pre-allocates the array part
local t = {nil, nil, nil, nil, nil}  -- 5 slots ready
```

---

## Length Operator

The `#` operator returns the length of a table's **sequence** — a contiguous range of integer keys starting at 1 with no holes:

```lua
-- Well-defined sequence
local t = {10, 20, 30, 40, 50}
print(#t)  -- 5

-- Sequence ends at first hole
local t = {10, 20, nil, 40, 50}
print(#t)  -- 2 (stops at the nil hole)
```

### When `#t` Is Undefined

The length operator is **only** well-defined for sequences. For tables with holes or non-sequential keys, the result is implementation-dependent:

```lua
-- Holes: behavior varies by Lua version/implementation
local t = {10, nil, 30}
print(#t)  -- Could be 0, 1, or 2 (undefined)

-- Non-sequential integer keys
local t = {[1] = "a", [3] = "c"}
print(#t)  -- Undefined (could be 1 or 3)
```

> **Rule**: Only use `#t` on tables that are sequences (1..n with no nil holes). For everything else, iterate explicitly.

### Version Differences

| Lua Version | `#t` behavior on holes |
|-------------|----------------------|
| 5.1 | May return index of last non-nil in sequence |
| 5.3/5.4 | Returns boundary between sequence and non-sequence |
| LuaJIT | Follows 5.1 semantics |

---

## Table Construction

### Literal Constructor

```lua
-- Empty table
local t = {}

-- Array-style
local items = {10, 20, 30}

-- Record-style
local config = {host = "localhost", port = 8080}

-- Mixed
local player = {name = "Hero", hp = 100, inventory = {}}

-- Nested
local matrix = {
  {1, 0, 0},
  {0, 1, 0},
  {0, 0, 1},
}
```

### Explicit Key Constructor

```lua
-- Integer keys (not starting at 1)
local t = {[0] = "zero", [1] = "one", [2] = "two"}

-- String keys with special characters
local t = {["key with spaces"] = 1, ["key.with.dots"] = 2}

-- Computed keys
local field = "name"
local t = {[field] = "Lua"}  -- t.name = "Lua"
```

### Trailing Comma

Lua allows trailing commas in constructors:

```lua
-- Both valid
local t = {1, 2, 3}
local t = {1, 2, 3,}  -- Trailing comma is fine
```

### Functional Constructor

```lua
-- Create table from function output
local function make_range(n)
  return {[n] = true}  -- Sparse: only key n exists
end

-- Using table.pack for varargs
local function collect(...)
  return table.pack(...)
end
local t = collect(1, 2, 3)
print(t.n)  -- 3 (table.pack adds .n field)
```

---

## Reference Semantics

Tables are reference types. Assignment copies the reference, not the data:

```lua
local a = {x = 1, y = 2}
local b = a          -- b points to same table
b.x = 10

print(a.x)           -- 10 (a affected!)
print(a == b)        -- true (same object)
```

### Aliasing Bugs

```lua
-- BUG: Modifying a table through an alias
local function add_item(inventory, item)
  inventory[#inventory + 1] = item
end

local player = {inventory = {}}
local inv = player.inventory
add_item(inv, "sword")
add_item(inv, "shield")

-- Both reference the same table
print(#player.inventory)  -- 2
print(#inv)               -- 2
```

### Identity vs Equality

```lua
local a = {1, 2, 3}
local b = {1, 2, 3}

print(a == b)   -- false (different objects)
print(a ~= b)   -- true

-- To compare contents, use deep_equal (see 01-basics.md)
```

---

## Common Table Patterns

### Set

```lua
-- Membership test
local function make_set(items)
  local s = {}
  for _, v in ipairs(items) do
    s[v] = true
  end
  return s
end

local fruits = make_set({"apple", "banana", "cherry"})
print(fruits["apple"])   -- true
print(fruits["grape"])   -- nil
```

### Bag / Multiset

```lua
-- Count occurrences
local function make_bag(items)
  local bag = {}
  for _, v in ipairs(items) do
    bag[v] = (bag[v] or 0) + 1
  end
  return bag
end

local counts = make_bag({"a", "b", "a", "c", "a"})
print(counts["a"])  -- 3
print(counts["b"])  -- 1
```

### Queue (FIFO)

```lua
-- Array-based queue
local Queue = {}
Queue.__index = Queue

function Queue.new()
  return setmetatable({head = 1, tail = 0}, Queue)
end

function Queue:push(value)
  self.tail = self.tail + 1
  self[self.tail] = value
end

function Queue:pop()
  if self.head > self.tail then return nil end
  local value = self[self.head]
  self[self.head] = nil  -- Allow GC
  self.head = self.head + 1
  return value
end

function Queue:empty()
  return self.head > self.tail
end

-- Usage
local q = Queue.new()
q:push("a")
q:push("b")
print(q:pop())   -- "a"
print(q:pop())   -- "b"
print(q:empty()) -- true
```

### Stack (LIFO)

```lua
-- Table-based stack
local stack = {}
function stack.push(t, v) t[#t + 1] = v end
function stack.pop(t) return table.remove(t) end
function stack.peek(t) return t[#t] end

-- Usage
local s = {}
stack.push(s, 10)
stack.push(s, 20)
print(stack.pop(s))  -- 20
print(stack.peek(s)) -- 10
```

### Linked List

```lua
-- Singly linked list
local function make_node(value, next)
  return {value = value, next = next}
end

local head = make_node(1,
  make_node(2,
    make_node(3, nil)))

-- Traverse
local node = head
while node do
  print(node.value)
  node = node.next
end
```

---

## Table Library

The `table` library provides essential operations:

### table.insert / table.remove

```lua
local t = {1, 2, 3}

-- Insert at position
table.insert(t, 4)        -- Append: {1, 2, 3, 4}
table.insert(t, 2, 99)    -- Insert at index 2: {1, 99, 2, 3, 4}

-- Remove from position
table.remove(t)            -- Remove last: {1, 99, 2, 3}
table.remove(t, 1)         -- Remove first: {99, 2, 3}
```

### table.sort

```lua
local items = {3, 1, 4, 1, 5, 9}

-- Default: ascending
table.sort(items)
-- items = {1, 1, 3, 4, 5, 9}

-- Custom comparator
table.sort(items, function(a, b) return a > b end)
-- items = {9, 5, 4, 3, 1, 1}

-- Sort by field
local people = {{name="c", age=30}, {name="a", age=25}, {name="b", age=35}}
table.sort(people, function(a, b) return a.age < b.age end)
```

> **Warning**: `table.sort` is not stable. Equal elements may reorder.

### table.concat

```lua
local parts = {"hello", "world", "lua"}

-- Join with separator
print(table.concat(parts, " "))   -- "hello world lua"
print(table.concat(parts, ", "))  -- "hello, world, lua"

-- Join with range
print(table.concat(parts, "", 1, 2))  -- "helloworld"
```

### table.pack / table.unpack (5.2+)

```lua
-- Pack varargs into table with length
local t = table.pack(1, 2, 3)
print(t.n)  -- 3

-- Unpack table into arguments
local values = {10, 20, 30}
print(table.unpack(values))  -- 10  20  30

-- Unpack with range
print(table.unpack(values, 2, 3))  -- 20  30
```

### table.move (5.3+)

```lua
-- Move elements between tables (or within same table)
local a = {1, 2, 3, 4, 5}
local b = {}
table.move(a, 1, 3, 1, b)
-- b = {1, 2, 3}

-- Shift elements within same table
table.move(a, 1, 3, 2, a)
-- a = {1, 1, 2, 3, 5}
```

---

## Table Reuse Patterns

In performance-critical code, avoid allocating new tables:

```lua
-- BAD: Allocates every call
local function get_bounding_box(entity)
  return {
    x = entity.x,
    y = entity.y,
    w = entity.width,
    h = entity.height,
  }
end

-- BETTER: Reuse a pre-allocated table
local bbox = {}
local function get_bounding_box(entity)
  bbox.x = entity.x
  bbox.y = entity.y
  bbox.w = entity.width
  bbox.h = entity.height
  return bbox
end

-- BETTER: Return individual values (no allocation)
local function get_bounding_box(entity)
  return entity.x, entity.y, entity.width, entity.height
end
```

---

## Common Pitfalls

### 1. Assuming `pairs` Order

```lua
-- WRONG: Order not guaranteed
local t = {c = 3, a = 1, b = 2}
for k, v in pairs(t) do
  print(k, v)  -- Order may vary across runs
end

-- RIGHT: Sort keys if order matters
local keys = {}
for k in pairs(t) do keys[#keys + 1] = k end
table.sort(keys)
for _, k in ipairs(keys) do
  print(k, t[k])  -- a 1, b 2, c 3 (alphabetical)
end
```

### 2. Using `nil` as a Value

`nil` in a table means the key doesn't exist:

```lua
local map = {}
map["a"] = nil       -- Same as not setting it
print(map["a"])      -- nil

-- Can't distinguish "key exists with nil value" from "key missing"
-- Workaround: use a sentinel value
local NULL = {}
map["a"] = NULL
print(map["a"] == NULL)  -- true (key exists)
print(map["b"] == NULL)  -- false (key missing)
```

### 3. Modifying Table During Iteration

```lua
-- WRONG: Modifying during pairs iteration
local t = {a = 1, b = 2, c = 3}
for k, v in pairs(t) do
  if v == 2 then t[k] = nil end  -- May skip elements
end

-- RIGHT: Collect keys, then modify
local to_remove = {}
for k, v in pairs(t) do
  if v == 2 then to_remove[#to_remove + 1] = k end
end
for _, k in ipairs(to_remove) do
  t[k] = nil
end
```

### 4. `#t` on Non-Sequences

```lua
-- WRONG: Assuming #t works on sparse tables
local t = {[1] = "a", [5] = "e"}
print(#t)  -- Undefined! Could be 1 or 5

-- RIGHT: Use next or manual iteration
local max = 0
for k in pairs(t) do
  if type(k) == "number" and k > max then max = k end
end
```

### 5. Accidental Table Sharing

```lua
-- BUG: All players share the same default table
local defaults = {hp = 100, mp = 50}
local players = {}
for i = 1, 3 do
  players[i] = defaults  -- All point to same table!
end
players[1].hp = 0
print(players[2].hp)  -- 0 (not 100!)

-- FIX: Create new table per player
for i = 1, 3 do
  players[i] = {hp = defaults.hp, mp = defaults.mp}
end

-- BETTER: Use a factory function
local function make_player(overrides)
  return {hp = 100, mp = 50, name = "unknown", unpack(overrides or {})}
end
```

---

## Best Practices

### 1. Define Table Shape Early

For performance, initialize tables with a consistent shape:

```lua
-- GOOD: Consistent shape — Lua optimizes lookup
local player = {
  name = "",
  hp = 0,
  mp = 0,
  x = 0.0,
  y = 0.0,
}

-- BAD: Sparse and inconsistent — forces hash lookups
local player = {}
player.name = "Hero"
-- Later: add random fields
player.inventory = {}
player.buffs = {}
```

### 2. Use Explicit Contains Flags

When `nil` is ambiguous, use a flag:

```lua
-- Problem: can't tell if "speed" was set to nil or never set
local config = {speed = nil}
print(config["speed"])      -- nil
print(config["gravity"])    -- nil (never set)

-- Solution: explicit flag
local config = {speed = nil, _has_speed = true}
if config._has_speed then
  print("speed was explicitly set to nil")
end
```

### 3. Separate Config from Runtime

Keep stable configuration separate from mutable state:

```lua
-- Config: created once, never mutated
local ENEMIES = {
  goblin = {hp = 20, damage = 5, speed = 1.0},
  orc    = {hp = 50, damage = 10, speed = 0.8},
}

-- Runtime: created per instance, mutated during play
local function spawn_enemy(type)
  local template = ENEMIES[type]
  return {
    type = type,
    hp = template.hp,
    damage = template.damage,
    speed = template.speed,
    x = 0, y = 0,
  }
end
```

### 4. Prefer `ipairs` for Arrays

`ipairs` stops at the first nil, giving predictable behavior:

```lua
local t = {1, 2, nil, 4, 5}

-- ipairs stops at index 2 (first nil)
for i, v in ipairs(t) do
  print(i, v)  -- 1 1, 2 2 (then stops)
end

-- pairs doesn't stop — iterates all non-nil keys
for k, v in pairs(t) do
  print(k, v)  -- 1 1, 2 2, 4 4, 5 5 (order undefined)
end
```

### 5. Document Table Shape

```lua
--- Player state
-- @field name string Player display name
-- @field hp number Current health [0, max_hp]
-- @field max_hp number Maximum health
-- @field position {x: number, y: number} World position
-- @field inventory string[] Item IDs
local player = {
  name = "Hero",
  hp = 100,
  max_hp = 100,
  position = {x = 0, y = 0},
  inventory = {},
}
```

---

## Version Notes

### Lua 5.1

- `table.maxn(t)` returns the largest integer key (deprecated in 5.2+)
- `unpack(t)` is a global function (replaced by `table.unpack` in 5.2+)
- `table.pack` / `table.unpack` not available

```lua
-- Lua 5.1
print(table.maxn({[100] = "a"}))  -- 100
print(unpack({1, 2, 3}))          -- 1 2 3
```

### Lua 5.3/5.4

- `table.pack` / `table.unpack` available
- `table.move` available (5.3+)
- `#t` behavior on sequences is more consistent

```lua
-- Lua 5.3+
local t = table.pack(1, 2, 3)
print(t.n)  -- 3

table.move({1, 2, 3}, 1, 2, 1, {})
-- Returns {1, 2}
```

### LuaJIT

- Table operations are heavily optimized
- `table.insert` / `table.remove` may be inlined by JIT
- Avoid creating many small tables in hot loops — JIT traces may not optimize allocation away

---

## Knowledge Check

<details>
<summary>1. Why does Lua split tables into array part and hash part?</summary>

For performance. Dense integer keys (arrays) use direct indexing (O(1) with no hashing overhead). Other keys use a hash table. This makes arrays faster than maps for sequential access.
</details>

<details>
<summary>2. When is <code>#t</code> undefined?</summary>

When `t` is not a sequence — i.e., it has holes (nil values between integer keys) or non-contiguous integer keys. The result is implementation-dependent.
</details>

<details>
<summary>3. What happens when you assign <code>t.a = nil</code>?</summary>

The key `a` is removed from the table. You cannot distinguish "key exists with nil value" from "key was never set" — both return nil.
</details>

<details>
<summary>4. Why is <code>table.sort</code> not safe to use for stable sorting?</summary>

The Lua reference explicitly says the sort is not stable. Equal elements may change relative order. Use a tiebreaker field if stability matters.
</details>

<details>
<summary>5. What is the safest way to iterate and remove from a table?</summary>

Collect keys to remove in a separate list, then remove them in a second pass. Never modify a table during `pairs` iteration — it may skip or duplicate elements.
</details>

---

## Key Takeaways

- **Tables are Lua's only data structure** — arrays, maps, records, sets, objects
- **Dual representation**: array part (dense integers) + hash part (everything else)
- **Length operator `#t`**: only well-defined for sequences (1..n, no holes)
- **Reference semantics**: assignment copies reference, not contents
- **Table library**: `insert`, `remove`, `sort`, `concat`, `pack`/`unpack`, `move`
- **Reuse tables** in hot paths to avoid allocation pressure
- **Never modify during pairs iteration** — collect keys first

---

## Exercises

### Beginner (30–60 min)

1. **Frequency Counter**: Write `count_tokens(text)` that splits text by whitespace and returns a table of word frequencies.

2. **Shallow Copy**: Implement `shallow_copy(t)` that copies one level. Verify that nested tables are still shared.

3. **Set Operations**: Implement `set_union(a, b)` and `set_intersection(a, b)` for two sets represented as `{value = true}` tables.

### Intermediate (1–2 hours)

4. **Deep Copy**: Implement `deep_copy(t)` that handles nested tables and circular references. Document edge cases.

5. **Ring Buffer**: Implement a fixed-size circular buffer with `push`, `pop`, and `full` operations. Use modular arithmetic on indices.

6. **Table Flatten**: Write `flatten(t, depth)` that flattens nested arrays. `flatten({1, {2, {3, 4}}, 5})` → `{1, 2, 3, 4, 5}`.

### Advanced (2–4 hours)

7. **Weak Table Observer**: Use weak tables (`__mode`) to create a weak-key observer that tracks object lifetimes without preventing garbage collection.

8. **Immutable Map**: Implement a persistent (immutable) map where `set` returns a new map, preserving the old one. Optimize for structural sharing.

---

## Example Code

Runnable examples for this chapter:
- `examples/beginner/05-table-copy.lua` — Shallow and deep copy patterns
- `examples/intermediate/01-prototype-entity.lua` — Table-based OOP
- `examples/intermediate/05-readonly-table.lua` — Immutable table patterns
- `examples/advanced/03-object-pool.lua` — Table reuse for performance

---

## Further Reading

- [Lua 5.4 Reference Manual — Section 3.4](https://www.lua.org/manual/5.4/manual.html#3.4)
- [Programming in Lua (4th ed.) — Chapter 7](https://www.lua.org/pil/)
- [Next Chapter: 05 — Metatables](05-metatables.md)
