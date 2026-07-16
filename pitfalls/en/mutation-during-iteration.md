# Mutation During pairs Iteration

## The Mistake

Modifying a table's keys while iterating with `pairs()` causes undefined behavior — elements may be skipped or duplicated.

## Reproduction

```lua
local t = {a = 1, b = 2, c = 3, d = 4}
for k, v in pairs(t) do
  if v % 2 == 0 then
    t[k] = nil  -- BUG: modifying during iteration
  end
end
-- Result is undefined: may skip elements or crash
```

## Why It's Wrong

`pairs()` uses the hash table's internal structure. Modifying keys during iteration corrupts the iterator state, leading to skipped elements or infinite loops.

## The Fix

```lua
-- Collect keys first, then modify
local t = {a = 1, b = 2, c = 3, d = 4}
local to_remove = {}
for k, v in pairs(t) do
  if v % 2 == 0 then
    to_remove[#to_remove + 1] = k
  end
end
for _, k in ipairs(to_remove) do
  t[k] = nil
end
```

## Key Takeaway

Never modify a table's keys during `pairs()` iteration. Collect changes first, then apply them in a second pass.
