# Metamethod Recursion

## The Mistake

Defining `__index` or `__newindex` that calls itself, causing infinite recursion.

```lua
-- Infinite recursion!
local t = setmetatable({}, {
  __index = function(self, k)
    return self[k]  -- Calls __index again!
  end
})
```

## Why It Fails

When `self[k]` is evaluated, Lua looks up `k` in `self`. If not found, it calls `__index` again with the same `k`, creating an infinite loop.

## The Fix

```lua
-- Use rawget to bypass metamethods
local t = setmetatable({}, {
  __index = function(self, k)
    return rawget(self, k)  -- Direct table access
  end
})

-- Or use a separate data table
local data = {}
local t = setmetatable({}, {
  __index = function(self, k)
    return data[k]
  end
})
```

## Related Concepts

- [05-metatables.md](../en/05-metatables.md) — Metatables and metamethods
- [10-lua-internals.md](../en/10-lua-internals.md) — Lua internals
