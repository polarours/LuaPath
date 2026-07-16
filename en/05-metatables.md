# 05 — Metatables

> **Phase**: B (Meta Layer and Architecture)  
> **Prerequisites**: Chapter 04 — Tables  
> **Time Estimate**: 3–4 hours reading + 3–5 hours exercises  
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT (differences noted)

---

## Learning Objectives

After completing this chapter, you will be able to:

1. **Explain the metatable dispatch mechanism** and when each metamethod fires
2. **Implement operator overloading** using arithmetic and comparison metamethods
3. **Build prototype-based OOP** with proper inheritance chains
4. **Use proxy patterns** for read-only tables, validation, and logging
5. **Avoid metamethod pitfalls** including recursion, shared prototypes, and performance traps

---

## What Are Metatables?

Every table (and userdata) can have an associated **metatable** — a table that controls its behavior. Metatables define **metamethods**: special keys that Lua invokes automatically in response to operations.

```lua
local t = {}
local mt = {
  __tostring = function(self)
    return "MyTable"
  end
}
setmetatable(t, mt)
print(t)  -- "MyTable"
```

Metatables do not change the table's data — they change how the table **responds to operations**.

---

## Lookup Chain: `__index`

When reading `obj.key`, Lua follows this dispatch:

1. Check if `key` exists as a raw field → return it
2. If not, check for metatable with `__index`
3. `__index` can be a **table** (look up `key` in that table) or a **function** (call it with `(obj, key)`)

```lua
-- __index as table: inheritance
local Animal = {sound = "..." }
local Dog = setmetatable({}, {__index = Animal})
print(Dog.sound)  -- "..." (found via __index)

-- __index as function: computed properties
local t = setmetatable({}, {
  __index = function(self, key)
    if key == "doubled" then
      return rawget(self, "value") * 2
    end
  end
})
rawset(t, "value", 21)
print(t.doubled)  -- 42
```

### Multi-Level Lookup Chain

```lua
local Base = {type = "base"}
local Middle = setmetatable({kind = "middle"}, {__index = Base})
local Instance = setmetatable({name = "obj"}, {__index = Middle})

-- Lookup: Instance → Middle → Base
print(Instance.name)   -- "obj" (raw hit)
print(Instance.kind)   -- "middle" (via Instance.__index = Middle)
print(Instance.type)   -- "base" (via Middle.__index = Base)
```

```text
instance ----__index----> Class ----__index----> BaseClass
   |                           |                     |
 raw miss                   raw miss              raw hit
   '------------------------------> resolved method
```

---

## Write Interception: `__newindex`

Triggered only when writing to a key that **does not already exist** on the table:

```lua
local t = {}
setmetatable(t, {
  __newindex = function(self, key, value)
    print("Setting " .. key .. " = " .. tostring(value))
    rawset(self, key, value)  -- Must use rawset to avoid recursion
  end
})

t.x = 10  -- "Setting x = 10"
t.x = 20  -- "Setting x = 20" (still triggers: x was set via rawset, but check)
```

> **Key distinction**: `__newindex` fires on **missing raw keys**. If the key already exists as a raw field, the write goes directly to the table without triggering `__newindex`.

### Validation Proxy

```lua
local function make_validated(schema)
  local data = {}
  return setmetatable(data, {
    __newindex = function(self, key, value)
      local expected = schema[key]
      if not expected then
        error("Unknown field: " .. tostring(key))
      end
      if type(value) ~= expected then
        error(key .. " must be " .. expected .. ", got " .. type(value))
      end
      rawset(self, key, value)
    end,
    __index = data,
  })
end

local player = make_validated({name = "string", hp = "number"})
player.name = "Hero"  -- OK
player.hp = 100       -- OK
-- player.level = 1   -- ERROR: Unknown field: level
-- player.hp = "full" -- ERROR: hp must be number, got string
```

---

## Arithmetic Operators

Metamethods for arithmetic operations:

| Metamethod | Operation | Signature |
|------------|-----------|-----------|
| `__add` | `a + b` | `(a, b) -> result` |
| `__sub` | `a - b` | `(a, b) -> result` |
| `__mul` | `a * b` | `(a, b) -> result` |
| `__div` | `a / b` | `(a, b) -> result` |
| `__mod` | `a % b` | `(a, b) -> result` |
| `__pow` | `a ^ b` | `(a, b) -> result` |
| `__unm` | `-a` | `(a) -> result` |

### Vector Example

```lua
local Vector = {}
Vector.__index = Vector

function Vector.new(x, y)
  return setmetatable({x = x or 0, y = y or 0}, Vector)
end

function Vector.__add(a, b)
  return Vector.new(a.x + b.x, a.y + b.y)
end

function Vector.__sub(a, b)
  return Vector.new(a.x - b.x, a.y - b.y)
end

function Vector.__mul(a, scalar)
  if type(a) == "number" then a, scalar = scalar, a end
  return Vector.new(a.x * scalar, a.y * scalar)
end

function Vector.__unm(v)
  return Vector.new(-v.x, -v.y)
end

function Vector:__tostring()
  return string.format("Vector(%.1f, %.1f)", self.x, self.y)
end

-- Usage
local a = Vector.new(1, 2)
local b = Vector.new(3, 4)
print(a + b)    -- Vector(4.0, 6.0)
print(a - b)    -- Vector(-2.0, -2.0)
print(a * 3)    -- Vector(3.0, 6.0)
print(-a)       -- Vector(-1.0, -2.0)
```

> **Version Note (5.4)**: Arithmetic metamethods are called only when both operands are tables or when one operand has a metamethod. Mixed number + table arithmetic requires explicit handling.

---

## Comparison Operators

| Metamethod | Operation |
|------------|-----------|
| `__eq` | `a == b` |
| `__lt` | `a < b` |
| `__le` | `a <= b` |

> **Rule**: `__eq` is called only when both operands are tables (or both are full userdata) and have the same metatable.

```lua
local Money = {}
Money.__index = Money

function Money.new(amount, currency)
  return setmetatable({amount = amount, currency = currency or "USD"}, Money)
end

function Money.__eq(a, b)
  return a.currency == b.currency and a.amount == b.amount
end

function Money.__lt(a, b)
  assert(a.currency == b.currency, "Cannot compare different currencies")
  return a.amount < b.amount
end

function Money.__le(a, b)
  assert(a.currency == b.currency, "Cannot compare different currencies")
  return a.amount <= b.amount
end

-- Usage
local a = Money.new(100, "USD")
local b = Money.new(200, "USD")
print(a == Money.new(100, "USD"))  -- true
print(a < b)                       -- true
print(a <= b)                      -- true
```

---

## String Representation: `__tostring`

Called by `tostring()` and `print()`:

```lua
local Point = {}
Point.__index = Point

function Point.new(x, y)
  return setmetatable({x = x, y = y}, Point)
end

function Point.__tostring(self)
  return string.format("(%d, %d)", self.x, self.y)
end

local p = Point.new(3, 4)
print(p)         -- (3, 4)
print(tostring(p)) -- (3, 4)
```

---

## Callable Tables: `__call`

Makes a table callable like a function:

```lua
local Accumulator = {}
Accumulator.__index = Accumulator

function Accumulator.new(initial)
  return setmetatable({total = initial or 0}, Accumulator)
end

function Accumulator.__call(self, amount)
  self.total = self.total + amount
  return self.total
end

local acc = Accumulator.new(100)
print(acc(10))  -- 110
print(acc(20))  -- 130
print(acc(5))   -- 135
```

### Practical Use: Memoized Function

```lua
local function memoize(fn)
  local cache = {}
  return setmetatable({}, {
    __call = function(self, ...)
      local key = table.pack(...)
      -- Simple string key (not production-quality)
      local keystr = ""
      for i = 1, key.n do keystr = keystr .. tostring(key[i]) .. ":" end
      if cache[keystr] == nil then
        cache[keystr] = fn(...)
      end
      return cache[keystr]
    end,
  })
end

local fib = memoize(function(n)
  if n < 2 then return n end
  return fib(n - 1) + fib(n - 2)
end)

print(fib(30))  -- 832040 (cached, fast)
```

---

## Concatenation: `__concat`

Called for the `..` operator:

```lua
local Tagged = {}
Tagged.__index = Tagged

function Tagged.new(tag, value)
  return setmetatable({tag = tag, value = value}, Tagged)
end

function Tagged.__concat(a, b)
  -- Handle string concatenation in both directions
  if type(a) == "string" then
    return a .. b.tag .. ":" .. b.value
  elseif type(b) == "string" then
    return a.tag .. ":" .. a.value .. b
  else
    return a.tag .. ":" .. a.value .. " " .. b.tag .. ":" .. b.value
  end
end

function Tagged:__tostring()
  return self.tag .. ":" .. self.value
end

local t1 = Tagged.new("status", "ok")
local t2 = Tagged.new("code", "200")
print("Result: " .. t1)       -- "Result: status:ok"
print(t1 .. " | " .. t2)      -- "status:ok | code:200"
print(t1 .. t2)               -- "status:ok code:200"
```

---

## Finalization: `__gc`

Controls cleanup when a table/userdata is garbage collected:

```lua
-- Lua 5.2+: tables can have __gc
local function make_resource(name)
  local r = {name = name}
  print("Acquired: " .. name)
  setmetatable(r, {
    __gc = function(self)
      print("Released: " .. self.name)
    end,
  })
  return r
end

do
  local r = make_resource("connection")
end  -- "Released: connection" (collected here)

collectgarbage()  -- Force GC to see the message
```

### Important Warnings

- **Never rely on `__gc` for deterministic release.** GC timing is unpredictable.
- `__gc` cannot prevent object destruction — it runs as part of collection.
- For deterministic cleanup, use explicit `close()` methods or Lua 5.4's `<close>` variable attribute.
- In Lua 5.1, tables cannot have `__gc` (only userdata).

---

## Protected Metatables: `__metatable`

Controls what `getmetatable()` returns:

```lua
local mt = {
  __metatable = "no access",
  __index = {secret = 42},
}

local t = setmetatable({}, mt)
print(getmetatable(t))     -- "no access" (not the real metatable)
-- setmetatable(t, {})     -- ERROR: cannot change protected metatable
```

This prevents external code from tampering with the metatable.

---

## Iteration: `__pairs`, `__ipairs`

Custom iteration protocols:

```lua
local Range = {}
Range.__index = Range

function Range.new(start, stop)
  return setmetatable({start = start, stop = stop}, Range)
end

-- __pairs (Lua 5.2+)
function Range.__pairs(range)
  local i = range.start - 1
  return function()
    i = i + 1
    if i <= range.stop then
      return i, i
    end
  end
end

for i in pairs(Range.new(1, 5)) do
  print(i)  -- 1 2 3 4 5
end
```

> **Version Note**: `__ipairs` was deprecated in Lua 5.2. Use `__pairs` for custom iteration.

---

## Raw Access: `rawget` / `rawset`

Bypass metamethod dispatch:

```lua
local t = {}
setmetatable(t, {
  __index = function(_, k)
    return "missing: " .. tostring(k)
  end,
})

print(t.foo)          -- "missing: foo" (via __index)
print(rawget(t, "foo"))  -- nil (bypasses __index)
```

### Avoiding Recursion

The classic `__newindex` recursion trap:

```lua
-- BROKEN: infinite recursion
local t = {}
setmetatable(t, {
  __newindex = function(self, k, v)
    self[k] = v  -- Triggers __newindex again!
  end,
})

-- FIXED: use rawset
local t = {}
setmetatable(t, {
  __newindex = function(self, k, v)
    rawset(self, k, v)  -- No recursion
  end,
})
```

### Read-Only Proxy

```lua
local function readonly(target)
  return setmetatable({}, {
    __index = target,
    __newindex = function()
      error("attempt to modify read-only table", 2)
    end,
    __len = function() return #target end,
    __pairs = function() return pairs(target) end,
  })
end

local data = {1, 2, 3}
local view = readonly(data)
print(view[1])     -- 1
-- view[4] = 5     -- ERROR: attempt to modify read-only table
```

---

## Prototype-Based OOP

Lua doesn't have classes. It has prototypes — objects that delegate to other objects via `__index`.

### Basic Pattern

```lua
local Entity = {}
Entity.__index = Entity

function Entity.new(id)
  return setmetatable({id = id, alive = true}, Entity)
end

function Entity:describe()
  return string.format("Entity<%d>", self.id)
end

function Entity:destroy()
  self.alive = false
end
```

### Inheritance

```lua
local Player = setmetatable({}, {__index = Entity})
Player.__index = Player

function Player.new(id, name, hp)
  local self = Entity.new(id)
  self.name = name
  self.hp = hp
  self.max_hp = hp
  return setmetatable(self, Player)
end

function Player:describe()
  return string.format("Player<%d, %s, HP:%d/%d>",
    self.id, self.name, self.hp, self.max_hp)
end

function Player:take_damage(amount)
  self.hp = math.max(0, self.hp - amount)
  if self.hp == 0 then self:destroy() end
end

-- Usage
local p = Player.new(1, "Hero", 100)
print(p:describe())       -- Player<1, Hero, HP:100/100>
p:take_damage(30)
print(p:describe())       -- Player<1, Hero, HP:70/100>
print(p.alive)            -- true (inherited from Entity)
```

### Checking Type

```lua
function Entity.is_a(obj, class)
  local mt = getmetatable(obj)
  while mt do
    if mt == class then return true end
    mt = getmetatable(mt)
  end
  return false
end

print(p:is_a(Player))  -- true
print(p:is_a(Entity))  -- true
```

---

## Common Pitfalls

### 1. `__index` Only Fires on Missing Keys

```lua
local t = {existing = "value"}
setmetatable(t, {
  __index = function(_, k)
    return "fallback"
  end,
})

print(t.existing)  -- "value" (raw hit, __index NOT called)
print(t.missing)   -- "fallback" (raw miss, __index called)
```

### 2. Shared Prototype Mutation

```lua
-- BUG: All instances share the same defaults table
local Entity = {defaults = {hp = 100, mp = 50}}
Entity.__index = Entity

local a = setmetatable({}, Entity)
local b = setmetatable({}, Entity)

a.defaults.hp = 0
print(b.defaults.hp)  -- 0 (shared!)

-- FIX: Clone defaults per instance
function Entity.new(id)
  local defaults = {hp = 100, mp = 50}
  return setmetatable({id = id, hp = defaults.hp, mp = defaults.mp}, Entity)
end
```

### 3. Recursion in Metamethods

```lua
-- BUG: __index calls self[k] which triggers __index
local t = setmetatable({}, {
  __index = function(self, k)
    return self[k]  -- Infinite recursion!
  end,
})

-- FIX: Use rawget
local t = setmetatable({}, {
  __index = function(self, k)
    return rawget(self, k)  -- Returns nil, no recursion
  end,
})
```

### 4. Performance: Too Many Misses

```lua
-- BAD: Forces __index on every access
local t = setmetatable({value = 10}, {
  __index = function(_, k)
    -- Complex logic for every miss
    return compute(k)
  end,
})

-- BETTER: Cache computed values in the table itself
local computed = {}
setmetatable(computed, {
  __index = function(_, k)
    if computed[k] == nil then
      computed[k] = compute(k)
    end
    return computed[k]
  end,
})
```

### 5. `__newindex` Doesn't Fire on Existing Raw Keys

```lua
local t = {existing = "value"}
setmetatable(t, {
  __newindex = function(_, k, v)
    print("intercepted: " .. k)
    rawset(_, k, v)
  end,
})

t.existing = "new"  -- No message! Key exists, raw write
t.missing = "new"   -- "intercepted: missing" (__newindex fires)
```

---

## Best Practices

### 1. Use `__index` for Inheritance, Not Data

```lua
-- GOOD: Methods on prototype, data on instance
local Class = {x = 0, y = 0}  -- Default values (rarely accessed via __index)
Class.__index = Class

function Class.new(x, y)
  return setmetatable({x = x, y = y}, Class)  -- Data on instance
end

-- BAD: All data on prototype, instances are empty
local Class = {}
Class.__index = Class
-- Instances share Class.x, Class.y — mutation bugs!
```

### 2. Document Metamethod Contracts

```lua
--- Add two vectors (immutable operation)
-- @param a Vector
-- @param b Vector
-- @return Vector new vector
function Vector.__add(a, b)
  return Vector.new(a.x + b.x, a.y + b.y)
end
```

### 3. Prefer `rawget`/`rawset` in Metamethods

```lua
-- Always use raw access in __index and __newindex
__index = function(self, k) return rawget(self, k) end
__newindex = function(self, k, v) rawset(self, k, v) end
```

### 4. Use `setmetatable` at Construction Time

```lua
-- Set metatable once, at creation
function Entity.new(id)
  return setmetatable({id = id}, Entity)
end

-- Avoid changing metatables after creation
-- t = setmetatable(t, new_mt)  -- Risky, breaks type assumptions
```

### 5. Keep Metatables Lightweight

```lua
-- GOOD: Small, focused metatables
local mt = {
  __index = prototype,
  __tostring = tostring_fn,
}

-- AVOID: Giant metatables with every possible metamethod
-- Each metamethod adds dispatch overhead
```

---

## Version Notes

### Lua 5.1

- `__gc` only works on userdata, not tables
- `__ipairs` is the custom iteration metamethod (not `__pairs`)
- `setfenv`/`getfenv` for environment manipulation
- No `__eq` metamethod (uses raw equality)

### Lua 5.2/5.3

- `__gc` works on tables (set metatable before table becomes reachable)
- `__pairs` replaces `__ipairs` (deprecated)
- `__eq` metamethod available
- Raw equality via `rawequal()`

### Lua 5.4

- `__close` metamethod for to-be-closed variables (RAII)
- `__warn` metamethod for warning messages
- `__type` metamethod to customize `type()` output
- `__name` metamethod for `pairs()` iteration order hint

```lua
-- Lua 5.4: custom type name
local t = setmetatable({}, {
  __name = "MyCustomType",
})
print(type(t))         -- "table" (still, __name doesn't change type())
print(getmetatable(t).__name)  -- "MyCustomType"
```

### LuaJIT

- Some metamethods are traced efficiently, others break JIT traces
- Arithmetic metamethods are generally well-optimized
- `__index` with function dispatch may inhibit trace compilation
- Keep metamethod-heavy code paths simple for best JIT performance

---

## Knowledge Check

<details>
<summary>1. When does <code>__newindex</code> fire?</summary>

Only when writing to a key that does not exist as a raw field on the table. If the key already exists, the write goes directly to the table without triggering `__newindex`.
</details>

<details>
<summary>2. What is the difference between <code>__index</code> as a table vs. as a function?</summary>

As a table: Lua looks up the missing key in that table (like inheritance). As a function: Lua calls it with `(self, key)` and returns whatever it returns (like computed properties).
</details>

<details>
<summary>3. Why must you use <code>rawset</code> in <code>__newindex</code>?</summary>

If `__newindex` does `self[k] = v` and `k` is a new key, it triggers `__newindex` again (infinite recursion). `rawset` writes directly to the table without going through metamethods.
</details>

<details>
<summary>4. Why can't you rely on <code>__gc</code> for deterministic cleanup?</summary>

Garbage collection timing is non-deterministic. Objects may be collected immediately, much later, or never in a single session. Use explicit close/destroy methods instead.
</details>

<details>
<summary>5. What happens when you call <code>getmetatable()</code> on a table with <code>__metatable</code> set?</summary>

It returns the value of `__metatable` instead of the actual metatable. This hides the real metatable from external code.
</details>

---

## Key Takeaways

- **Metatables control behavior**, not data — they define how tables respond to operations
- **`__index`** handles missing key reads; `__newindex` handles missing key writes
- **Arithmetic metamethods** enable operator overloading for custom types
- **`rawget`/`rawset`** bypass metamethods — essential for avoiding recursion
- **Prototype-based OOP** uses `__index` chains for inheritance
- **Proxy patterns** enable read-only views, validation, and logging
- **Never rely on `__gc`** for deterministic resource management
- **Stable table shapes** reduce metamethod dispatch overhead

---

## Exercises

### Beginner (30–60 min)

1. **Read-Only Table**: Implement `readonly(t)` that returns a proxy table where any write attempt raises an error. Support `pairs`, `ipairs`, and `#`.

2. **String Metatable**: Create a `String` wrapper with `__add` for concatenation, `__len` for length, and `__tostring` for display.

3. **Clamp Function**: Overload `math.clamp` to work with both numbers and a custom `Clamped` type using metamethods.

### Intermediate (1–2 hours)

4. **Class System**: Build a minimal OOP library with `class()`, `extend()`, and `super()`. Support `isinstance()` checks.

5. **Logging Proxy**: Create a proxy that logs every read and write operation on a table, including the key, value, and operation type.

6. **Immutable Record**: Implement a `Record` type where each field is set once and becomes read-only afterward. Use `__newindex` to enforce immutability after first assignment.

### Advanced (2–4 hours)

7. **Observer Pattern**: Build a reactive table where changes to fields trigger callback functions. Support nested field observation.

8. **Expression AST**: Create a small expression evaluator using operator metamethods. `local expr = (Var("x") + 3) * Var("y")` should produce a callable that evaluates given an environment table.

---

## Example Code

Runnable examples for this chapter:
- `examples/intermediate/01-prototype-entity.lua` — Prototype-based OOP
- `examples/intermediate/05-readonly-table.lua` — Read-only proxy pattern
- `examples/advanced/01-ecs-system.lua` — Metatable-based component system

---

## Further Reading

- [Lua 5.4 Reference Manual — Section 3.4.8](https://www.lua.org/manual/5.4/manual.html#3.4.8)
- [Programming in Lua (4th ed.) — Chapter 13, 16](https://www.lua.org/pil/)
- [Next Chapter: 06 — Modules](06-modules.md)
