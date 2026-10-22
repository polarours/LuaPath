# Global Lookup in Hot Paths

## The Mistake

Accessing global variables (through the environment table) in performance-critical loops is slower than local variable access.

## Reproduction

```lua
-- SLOW: global lookup on every iteration
for i = 1, 1000000 do
  local x = math.sin(i)  -- lookup of "math", then of "sin"
end

-- FASTER: local caching
local sin = math.sin
for i = 1, 1000000 do
  local x = sin(i)  -- VM register access
end
```

## Why It's Wrong

A global access costs two table lookups — the environment table, then the
field in it — while a local variable is already sitting in a VM register.

The win is real but modest, and it is worth knowing how modest. Timing
twenty million calls to an empty function, once through a global and once
through a local, gives roughly:

| Runtime | Global | Local | Ratio |
|---|---|---|---|
| Lua 5.1 | 0.308 s | 0.248 s | 1.24x |
| Lua 5.3 | 0.278 s | 0.219 s | 1.27x |
| Lua 5.4 | 0.220 s | 0.172 s | 1.28x |
| Lua 5.5 | 0.258 s | 0.175 s | 1.47x |
| LuaJIT 2.1 | 0.006 s | 0.005 s | 1.04x |

So on the reference interpreter a global call is about a quarter to a half
again as expensive as the same call through a local — and on LuaJIT the
difference all but disappears, because the JIT hoists the global lookup out
of the loop.

Note also that a lookup in a loop that spends its time in `math.sin` is a
small part of the cost. Cache the lookup, but do not expect it to change
the shape of a profile on its own.

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

Cache frequently used globals as locals at module scope. It is free to do
and worth a quarter of a call on the interpreter, though LuaJIT already
does it for you.
