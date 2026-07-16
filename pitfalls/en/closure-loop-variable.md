# Closure Loop Variable Capture

## The Mistake

Capturing a loop variable in a closure captures the variable itself, not its value at capture time.

## Reproduction

```lua
local functions = {}
for i = 1, 5 do
  functions[i] = function() return i end
end

print(functions[1]())  -- 5 (not 1!)
print(functions[3]())  -- 5 (not 3!)
```

## Why It's Wrong

All closures share the same `i` variable. When the loop finishes, `i` is 5, so all closures return 5.

## The Fix

```lua
-- Fix 1: Create a local copy per iteration
local functions = {}
for i = 1, 5 do
  local j = i  -- New upvalue per iteration
  functions[i] = function() return j end
end
print(functions[1]())  -- 1

-- Fix 2: Use a factory function
local functions = {}
for i = 1, 5 do
  functions[i] = (function(n) return function() return n end end)(i)
end
print(functions[1]())  -- 1
```

## Key Takeaway

Closures capture variables by reference. Create a local copy inside the loop body if you need the current value.
