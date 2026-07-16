# Metamethod Recursion

Accessing a field inside `__index` or `__newindex` without `rawget`/`rawset` causes infinite recursion.

## The Mistake

```lua
local mt = {}

function mt.__index(t, key)
  -- trying to read a default from t itself
  return t.defaults[key] -- BOOM: t.defaults triggers __index again
end

function mt.__newindex(t, key, value)
  -- trying to log all writes
  print("set", key, value)
  t[key] = value -- BOOM: triggers __newindex on itself
end

local obj = setmetatable({}, mt)
```

## Why It's Wrong

When Lua cannot find `defaults` directly on the table, it calls `__index`. Inside `__index`, accessing `t.defaults` hits the same metamethod. This recurses until the stack overflows.

The same applies to `__newindex` — assigning `t[key] = value` inside the handler re-triggers the handler.

## The Fix

Use `rawget` and `rawset` to bypass metamethods:

```lua
local mt = {}

function mt.__index(t, key)
  local defaults = rawget(t, "defaults") or {}
  return defaults[key]
end

function mt.__newindex(t, key, value)
  print("set", key, value)
  rawset(t, key, value) -- no recursion
end

local obj = setmetatable({ defaults = { color = "red" } }, mt)
print(obj.color) -- "red"
obj.x = 42        -- prints: set x  42
```

## Key Takeaway

Inside any metamethod, never read or write the same table using normal indexing. Always use `rawget`/`rawset` to escape the metamethod chain.
