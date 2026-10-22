# Closure Loop Variable Capture

## The Mistake

A closure captures the **variable** it refers to, not the value that variable held when the closure was created. When the captured variable is declared *outside* the loop and reassigned on every iteration, every closure observes its final value.

```lua
-- All three functions return 3!
local i = 0
local functions = {}
for k = 1, 3 do
  i = k
  functions[k] = function() return i end
end

print(functions[1]())  -- 3
print(functions[2]())  -- 3
print(functions[3]())  -- 3
```

A hand-rolled counter has the same problem:

```lua
-- All three functions return 4!
local i = 1
local functions = {}
while i <= 3 do
  functions[#functions + 1] = function() return i end
  i = i + 1
end

print(functions[1]())  -- 4
print(functions[2]())  -- 4
print(functions[3]())  -- 4
```

## Not a Bug: the `for` Statement's Own Variable

Since Lua 5.1 the `for` statement gives every iteration its own copy of the control variable, so capturing it is safe:

```lua
-- Returns 1, 2, 3 — not 3, 3, 3
local functions = {}
for i = 1, 3 do
  functions[i] = function() return i end
end

print(functions[1]())  -- 1
print(functions[2]())  -- 2
print(functions[3]())  -- 3
```

Sharing one loop variable was Lua **5.0** behaviour. The Lua 5.1 Reference Manual declares the loop variable *inside* the loop body (§2.4.5) and lists that scope change among the incompatibilities with the previous version (§7.1). There is no 5.1-vs-5.3/5.4 difference.

## The Fix

```lua
-- Option 1: Create a local copy
local functions = {}
for i = 1, 5 do
  local j = i  -- New variable for each iteration
  functions[i] = function() return j end
end

-- Option 2: Use a factory function
local functions = {}
for i = 1, 5 do
  functions[i] = (function(n) return function() return n end end)(i)
end

-- Both return correct values: 1, 2, 3, 4, 5
```

## Key Takeaway

Closures capture variables by reference. Create a local copy inside the loop body if you need the current value.

## Related Concepts

- [03-functions.md](../../en/03-functions.md) — Functions and closures
- [08-coroutines.md](../../en/08-coroutines.md) — Coroutines
