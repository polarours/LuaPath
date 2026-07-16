# 03 — Functions

> **Phase**: A (Core Language Literacy)  
> **Prerequisites**: Chapter 02 — Control Flow  
> **Time Estimate**: 2–3 hours reading + 2–4 hours exercises  
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT (differences noted)

---

## Learning Objectives

After completing this chapter, you will be able to:

1. **Declare and call functions** using all syntax forms and understand when each is appropriate
2. **Use multiple return values** correctly, including the expansion rules at call sites
3. **Write variadic functions** that handle mixed argument counts safely
4. **Distinguish `.` from `:`** and use method syntax appropriately
5. **Reason about closures and upvalues** — what captures, what escapes, and what mutates

---

## Function Declaration Forms

Lua provides three equivalent ways to declare a function:

```lua
-- Form 1: function statement (syntactic sugar)
local function add(a, b)
  return a + b
end

-- Form 2: local variable assignment
local add = function(a, b)
  return a + b
end

-- Form 3: table field (for modules)
local M = {}
function M.add(a, b)    -- sugar for M.add = function(...)
  return a + b
end
```

**Key difference**: Form 1 (`local function`) allows the function to reference itself recursively. Form 2 requires the name to exist before the function body:

```lua
-- Form 1: recursive — works
local function factorial(n)
  if n <= 1 then return 1 end
  return n * factorial(n - 1)  -- OK: name visible in body
end

-- Form 2: recursive — fails at runtime
local factorial = function(n)
  if n <= 1 then return 1 end
  return n * factorial(n - 1)  -- BUG: factorial is nil here!
end

-- Form 2: recursive — must declare first
local factorial
factorial = function(n)
  if n <= 1 then return 1 end
  return n * factorial(n - 1)  -- OK: now factorial exists
end
```

> **Pitfall**: `local function f() end` is NOT the same as `local f = function() end` when `f` is recursive. The first form creates a forward declaration; the second does not.

---

## First-Class Functions

Functions are values. They can be stored in variables, passed as arguments, and returned from other functions.

```lua
-- Function as value
local double = function(x) return x * 2 end
print(double(5))  -- 10

-- Function in table
local ops = {
  add = function(a, b) return a + b end,
  mul = function(a, b) return a * b end,
}
print(ops.add(3, 4))  -- 7

-- Function as argument
local function apply(fn, x)
  return fn(x)
end
print(apply(double, 5))  -- 10
```

### Functions as Callbacks

```lua
-- Filter: pass function to decide what keeps
local function filter(array, predicate)
  local result = {}
  for _, v in ipairs(array) do
    if predicate(v) then
      result[#result + 1] = v
    end
  end
  return result
end

local numbers = {1, 2, 3, 4, 5, 6}
local evens = filter(numbers, function(n) return n % 2 == 0 end)
-- evens = {2, 4, 6}
```

### Higher-Order Functions

Functions that return functions:

```lua
-- Comparator factory
local function by_field(field, order)
  order = order or "asc"
  return function(a, b)
    if order == "asc" then
      return a[field] < b[field]
    else
      return a[field] > b[field]
    end
  end
end

local items = {{name="c", score=90}, {name="a", score=80}, {name="b", score=95}}
table.sort(items, by_field("score", "desc"))
-- items[1].name == "b", items[2].name == "c", items[3].name == "a"
```

---

## Multiple Return Values

Functions can return multiple values:

```lua
local function minmax(array)
  local min, max = array[1], array[1]
  for i = 2, #array do
    if array[i] < min then min = array[i] end
    if array[i] > max then max = array[i] end
  end
  return min, max
end

local lo, hi = minmax({3, 1, 4, 1, 5, 9})
print(lo, hi)  -- 1  9
```

### Return-Position Expansion Rules

Only the **last** expression in a return statement expands to multiple values:

```lua
local function multi()
  return 1, 2, 3
end

-- All values captured
local a, b, c = multi()
print(a, b, c)  -- 1  2  3

-- Only first captured, rest discarded
local a, b = multi()
print(a, b)      -- 1  2

-- In table constructor: all values captured
local t = {multi()}
print(#t)        -- 3

-- In function call: all values captured
print(multi())   -- 1  2  3
```

### Wrapping Multiple Returns

When you need to capture all return values in a non-final position, wrap in parentheses:

```lua
local function multi()
  return 1, 2, 3
end

-- Parentheses force single-value evaluation
local a, b = (multi())
print(a, b)  -- 1  nil

-- Table capture preserves all
local t = {multi()}
print(t[1], t[2], t[3])  -- 1  2  3
```

### Discarding Unwanted Returns

Use `_` for values you don't need:

```lua
local function complex_return()
  return "result", nil, 42
end

local value, _, code = complex_return()
print(value, code)  -- "result"  42
```

---

## Varargs

Functions can accept variable numbers of arguments using `...`:

```lua
local function sum(...)
  local acc = 0
  for _, v in ipairs({...}) do
    acc = acc + v
  end
  return acc
end

print(sum(1, 2, 3))      -- 6
print(sum(1, 2, 3, 4, 5))  -- 15
```

### Selecting Specific Arguments

```lua
local function log(level, ...)
  local message = string.format(...)
  print("[" .. level .. "] " .. message)
end

log("INFO", "Processing %d items", 42)
-- [INFO] Processing 42 items
```

### Forwarding Varargs

Use `...` to pass arguments through:

```lua
local function debug_print(...)
  print("DEBUG:", ...)
end

debug_print("x", 42, true)  -- DEBUG:  x  42  true
```

### Varargs in Lua 5.1 vs 5.3+

In Lua 5.1, `select` with a negative index accesses trailing varargs:

```lua
-- Lua 5.1 only
local function last(...)
  return select(-1, ...)  -- Last argument
end
print(last(1, 2, 3))  -- 3
```

In Lua 5.3+, use the `table.pack`/`table.unpack` pattern instead:

```lua
-- Lua 5.3+
local function last(...)
  local args = {...}
  return args[#args]
end
print(last(1, 2, 3))  -- 3
```

> **Performance note**: Using `{...}` creates a table every call. In hot paths, prefer `select` and individual argument access over table construction.

---

## Method Syntax

Lua has two calling conventions for functions that take an implicit object:

```lua
-- Dot syntax (explicit self)
local player = {health = 100}
function player.take_damage(self, amount)
  self.health = self.health - amount
end
player.take_damage(player, 10)  -- Must pass self explicitly

-- Colon syntax (implicit self)
function player:take_damage(amount)
  self.health = self.health - amount
end
player:take_damage(10)  -- self is player, passed automatically
```

The `:` is syntactic sugar. `obj:method(x)` desugars to `obj.method(obj, x)`.

### When to Use Which

```lua
-- Colon: when function operates on an object (OOP-style)
local Vector = {}
function Vector:new(x, y)
  return setmetatable({x = x, y = y}, Vector)
end
function Vector:magnitude()
  return math.sqrt(self.x^2 + self.y^2)
end

-- Dot: when function is a utility, not tied to one object
local math_utils = {}
function math_utils.clamp(value, lo, hi)
  return math.max(lo, math.min(hi, value))
end
math_utils.clamp(10, 0, 5)  -- No object — dot is correct
```

> **Pitfall**: Using `:` for a function that doesn't use `self` wastes a hidden argument and confuses readers. Use `.` for pure utility functions.

---

## Closures and Upvalues

A closure is a function that captures variables from its enclosing scope. The captured variable is called an **upvalue**.

```lua
local function make_counter(start)
  local n = start or 0       -- n is an upvalue of the returned function
  return function()
    n = n + 1
    return n
  end
end

local c = make_counter(10)
print(c())  -- 11
print(c())  -- 12
print(c())  -- 13
```

### Multiple Closures Sharing State

When two closures capture the same variable, they share it:

```lua
local function make_pair()
  local value = nil
  
  local function get() return value end
  local function set(v) value = v end
  
  return get, set
end

local get, set = make_pair()
print(get())    -- nil
set(42)
print(get())    -- 42
```

### Closures in Loops — The Classic Bug

Capturing a loop variable captures the **variable**, not the value at capture time:

```lua
-- BUG: All functions share the same `i`
local functions = {}
for i = 1, 5 do
  functions[i] = function() return i end
end
print(functions[1]())  -- 5 (not 1!)
print(functions[3]())  -- 5 (not 3!)

-- FIX 1: Create a new variable per iteration
local functions = {}
for i = 1, 5 do
  local j = i  -- New upvalue per iteration
  functions[i] = function() return j end
end
print(functions[1]())  -- 1

-- FIX 2: Use a factory function
local functions = {}
for i = 1, 5 do
  functions[i] = (function(n) return function() return n end end)(i)
end
print(functions[1]())  -- 1
```

### Upvalue Lifetime

Upvalues are captured by reference and live as long as any closure referencing them exists:

```lua
local function create()
  local big_data = string.rep("x", 1000000)  -- Large allocation
  return function()
    return #big_data  -- Keeps big_data alive!
  end
end

local fn = create()
-- big_data is still in memory because fn references it
print(fn())  -- 1000000

-- After fn is garbage collected, big_data can be freed
fn = nil
```

---

## Tail Calls

Lua supports tail call optimization (TCO). A tail call is a function call in tail position (the last thing a function does):

```lua
-- Tail call — optimized (no new stack frame)
local function fact_tail(n, acc)
  acc = acc or 1
  if n <= 1 then return acc end
  return fact_tail(n - 1, n * acc)  -- Tail position
end

-- NOT a tail call — return is not in tail position
local function fact(n)
  if n <= 1 then return 1 end
  return n * fact(n - 1)  -- Must multiply before returning
end
```

### Tail Call Syntax

```lua
-- Tail call: return f(...)
-- Not tail call: return ... f(...)

local function g(x)
  return x + 1
end

-- Tail call
local function f(x)
  return g(x)        -- Tail call
end

-- Not tail call
local function f(x)
  return 1 + g(x)    -- g(x) evaluated, then added to 1
end
```

> **Pitfall**: `return f(...) and g(...)` is NOT a tail call. The `and` operator means the expression evaluates to a single value, not a tail call.

### Practical Use: Trampolining

Tail calls enable infinite recursion without stack overflow:

```lua
-- Trampoline pattern for state machines
local function state_a(input)
  if input == "go" then return state_b end
  return state_a  -- Stay in state A
end

local function state_b(input)
  if input == "back" then return state_a end
  return state_b
end

-- Run state machine (no stack growth)
local current = state_a
current = current("go")    -- state_b
current = current("back")  -- state_a
current = current("stay")  -- state_a (tail call to self)
```

---

## Error Handling in Functions

Functions are the primary boundary for error handling in Lua:

### Return Error Convention

```lua
local function divide(a, b)
  if b == 0 then
    return nil, "division by zero"
  end
  return a / b
end

local result, err = divide(10, 0)
if not result then
  print("Error: " .. err)
end
```

### Pcall for Protected Calls

```lua
local function risky_operation()
  error("something went wrong")
end

local success, result = pcall(risky_operation)
if not success then
  print("Caught: " .. result)  -- Caught: something went wrong
end
```

### Assertions

```lua
local function process(config)
  assert(type(config) == "table", "config must be a table")
  assert(config.host ~= nil, "config.host is required")
  assert(type(config.port) == "number", "config.port must be a number")
  -- ... process config
end

-- Fails fast with clear message
local ok, err = pcall(process, {})
if not ok then
  print(err)  -- config.host is required
end
```

---

## Common Pitfalls

### 1. Confusing `.` and `:`

```lua
local obj = {value = 10}

function obj:double()       -- Colon: self is implicit
  self.value = self.value * 2
end

function obj.triple(self)   -- Dot: self must be explicit
  self.value = self.value * 3
end

obj:double()    -- OK
obj.triple(obj) -- OK but verbose

-- WRONG:
obj.triple()    -- ERROR: self is nil
```

### 2. Capturing Loop Variables

See [Closures in Loops](#closures-in-loops--the-classic-bug) above. The fix: create a local copy per iteration.

### 3. Returning Temporary Tables from Hot Paths

```lua
-- ALLOCATES every call — bad in hot paths
local function get_position(entity)
  return {x = entity.x, y = entity.y}
end

-- BETTER: reuse a table or return individual values
local function get_position(entity)
  return entity.x, entity.y
end
```

### 4. Variable Argument Shadows

```lua
-- Confusing: `v` shadows the outer loop variable
local function process(...)
  for _, v in ipairs({...}) do
    local v = v  -- Unnecessary shadow
    print(v)
  end
end
```

### 5. Forgetting That Functions Are Reference Types

```lua
local function noop() end

local a = noop
local b = a
a = nil
print(type(b))  -- "function" (b still references the function)
```

---

## Best Practices

### 1. Keep Function Contracts Small

```lua
-- BAD: too many responsibilities
function process_order(order, user, payment, inventory, shipping)
  -- 200 lines doing everything
end

-- GOOD: single responsibility
function validate_order(order) ... end
function charge_payment(payment) ... end
function update_inventory(inventory) ... end
function schedule_shipment(shipping) ... end
function process_order(order)
  validate_order(order)
  charge_payment(order.payment)
  update_inventory(order.items)
  schedule_shipment(order.shipping)
end
```

### 2. Separate Pure Functions from Side Effects

```lua
-- Pure: same input → same output, no side effects
local function calculate_total(items)
  local total = 0
  for _, item in ipairs(items) do
    total = total + item.price * item.quantity
  end
  return total
end

-- Side effect: modifies external state
local function save_order(order)
  db.insert("orders", order)
  log.info("Order saved", order.id)
end
```

### 3. Use Guard Clauses

```lua
-- Instead of deep nesting:
function process(user)
  if user then
    if user.active then
      if user.has_permission then
        -- Do something
      end
    end
  end
end

-- Guard clauses:
function process(user)
  if not user then return end
  if not user.active then return end
  if not user.has_permission then return end
  -- Do something
end
```

### 4. Document Return Contracts

```lua
--- Divide two numbers
-- @param a number dividend
-- @param b number divisor (must be non-zero)
-- @return number quotient, nil on error
-- @return string error message on failure
local function divide(a, b)
  if b == 0 then
    return nil, "division by zero"
  end
  return a / b
end
```

### 5. Cache Functions in Hot Paths

```lua
-- BAD: table lookup on every call
for i = 1, 1000000 do
  math.sin(i)  -- _ENV["math"].sin(i)
end

-- GOOD: local reference
local sin = math.sin
for i = 1, 1000000 do
  sin(i)  -- Direct register access
end
```

---

## Version Notes

### Lua 5.1

- Uses `setfenv`/`getfenv` to manipulate function environments
- No `_ENV` variable — environments are set per-function
- `select('#', ...)` returns the count of varargs

```lua
-- Lua 5.1 environment manipulation
local f = function() return x end
setfenv(f, {x = 42})
print(f())  -- 42
```

### Lua 5.3/5.4

- Uses `_ENV` (a regular upvalue) instead of `setfenv`/`getfenv`
- Integer division `//` operator available
- Bitwise operators available
- Lua 5.4 adds `close` variable attribute for automatic resource cleanup

```lua
-- Lua 5.4 to-be-closed variable (requires 5.4+)
-- local function process()
--   local <close> resource = acquire_resource()
--   -- resource automatically released when leaving scope
--   do_work(resource)
-- end  -- resource released here, even on error
--
-- The <close> attribute ensures __close metamethod runs on scope exit.
-- Useful for RAII-style resource management: file handles, locks, connections.
```

### LuaJIT

- FFI allows calling C functions directly without wrapper functions
- Trace compiler may inline small functions automatically
- Avoid function calls with polymorphic arguments in hot loops

---

## Knowledge Check

<details>
<summary>1. What is the difference between <code>local function f() end</code> and <code>local f = function() end</code>?</summary>

The first form creates a forward declaration, allowing `f` to reference itself recursively in the body. The second form does not — `f` is `nil` inside the function body, so recursive calls fail at runtime.
</details>

<details>
<summary>2. What does <code>return a, b, c</code> do when only two variables receive the result?</summary>

The third value is discarded. `local x, y = f()` where `f` returns three values gives `x = a`, `y = b`, and `c` is lost.
</details>

<details>
<summary>3. Why does <code>for i = 1, 5 do fns[i] = function() return i end end</code> give all 5s?</summary>

All closures capture the same variable `i`, not its value at capture time. When the loop finishes, `i` is 5, so all closures return 5. Fix: create a local copy (`local j = i`) inside the loop body.
</details>

<details>
<summary>4. What is a tail call and why does it matter?</summary>

A tail call is `return f(...)` — the last thing a function does. Lua optimizes it by reusing the current stack frame instead of creating a new one. This prevents stack overflow in deeply recursive code (trampolining).
</details>

<details>
<summary>5. When should you use <code>:</code> vs <code>.</code> function syntax?</summary>

Use `:` when the function operates on an object and needs implicit `self` (OOP methods). Use `.` for utility functions that don't take an implicit object, or when you pass `self` explicitly.
</details>

---

## Key Takeaways

- **Three declaration forms**: `local function`, `local f = function`, `M.f = function` — the first supports self-reference
- **Multiple returns**: only the last expression expands; use `_` to discard
- **Varargs**: `...` captures extra args; `{...}` allocates a table — avoid in hot paths
- **Method syntax**: `:` passes `self` implicitly; `.` requires explicit passing
- **Closures**: capture variables by reference, not value; classic loop bug shares one variable
- **Tail calls**: `return f(...)` reuses the stack; enables trampolining
- **Guard clauses**: flatten nesting; return early on failure

---

## Exercises

### Beginner (30–60 min)

1. **Memoize**: Implement `memoize(fn)` that caches results. Bound the cache to N entries (LRU or simple reset).

2. **Once**: Write `once(fn)` that calls `fn` only on the first invocation, returning that result on all subsequent calls.

3. **Flip**: Implement `flip(fn)` that reverses the argument order. `flip(subtract)(10, 3)` should return `subtract(3, 10)`.

### Intermediate (1–2 hours)

4. **Compose**: Write `compose(f, g)` that returns a function applying `g` then `f`. Extend to `compose(...)` accepting multiple functions.

5. **Method vs Dot API**: Design a `Stack` module with both colon-syntax (`stack:push()`) and dot-syntax (`stack_push(stack)`) interfaces. Verify they produce identical behavior.

6. **Vararg Forwarding**: Write `partial(fn, ...)` that pre-fills leading arguments. `partial(add, 1)(2)` should return `3`.

### Advanced (2–4 hours)

7. **Coroutine Iterator**: Write a function `coroutine_iter(fn)` that takes a function yielding values and returns an iterator function usable in `for` loops.

8. **Trampoline**: Implement a trampoline wrapper that converts recursive functions to iterative tail calls. Test with a deeply nested computation.

---

## Example Code

Runnable examples for this chapter:
- `examples/intermediate/04-stateful-module.lua` — Closure-based stateful module
- `examples/intermediate/02-event-bus.lua` — Higher-order function patterns
- `examples/advanced/01-ecs-system.lua` — Function-heavy architecture

---

## Further Reading

- [Lua 5.4 Reference Manual — Section 3](https://www.lua.org/manual/5.4/manual.html#3)
- [Programming in Lua (4th ed.) — Chapter 5–6](https://www.lua.org/pil/)
- [Next Chapter: 04 — Tables](04-tables.md)
