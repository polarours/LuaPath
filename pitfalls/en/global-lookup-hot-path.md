# Global Lookup in Hot Paths

## The Mistake

Accessing global variables (through `_ENV` table lookups) in performance-critical loops is significantly slower than local variable access.

## Reproduction

```lua
-- SLOW: global lookup on every iteration
for i = 1, 1000000 do
  local x = math.sin(i)  -- _ENV["math"]["sin"](i)
end

-- FASTER: local caching
local sin = math.sin
for i = 1, 1000000 do
  local x = sin(i)  -- VM register access
end
```

## Why It's Wrong

Global access requires two table lookups (`_ENV["math"]` then `["sin"]`). Local variables map directly to VM registers, which are much faster.

## The Fix

```lua
-- Cache globals at module level
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt
local max = math.max
local min = math.min

local function compute(x, y)
  return sqrt(sin(x)^2 + cos(y)^2)
end
```

## Key Takeaway

Cache frequently used globals as locals at module scope. This is especially important in hot loops and performance-critical code.
