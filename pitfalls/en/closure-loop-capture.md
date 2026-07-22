# Closure Loop Variable Capture

## The Mistake

Capturing a loop variable in a closure captures the variable itself, not its value at the time of capture.

```lua
-- All functions return 5!
local functions = {}
for i = 1, 5 do
  functions[i] = function() return i end
end

print(functions[1]())  -- 5
print(functions[2]())  -- 5
print(functions[3]())  -- 5
```

## Why It Fails

The closure captures the variable `i`, not its value. When the loop finishes, `i` is 5, so all closures return 5.

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

## Related Concepts

- [03-functions.md](../en/03-functions.md) — Functions and closures
- [08-coroutines.md](../en/08-coroutines.md) — Coroutines
