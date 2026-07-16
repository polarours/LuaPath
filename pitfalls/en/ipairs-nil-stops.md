# Assuming ipairs Stops at First Nil

## The Mistake

Believing `ipairs` always iterates from index 1 to `#t`. It actually stops at the first nil value, which may be before `#t` if there are holes.

## Reproduction

```lua
local t = {[1] = "a", [3] = "c"}  -- Index 2 is nil
print(#t)  -- Could be 1 or 3 (undefined with holes)

for i, v in ipairs(t) do
  print(i, v)  -- Only prints: 1, "a" (stops at nil index 2)
end
```

## Why It's Wrong

`ipairs` stops at the first nil value, not at `#t`. If index 2 is nil, it stops there even though index 3 exists. The `#` operator's behavior with holes is also undefined.

## The Fix

```lua
-- For non-contiguous tables, use pairs
local t = {[1] = "a", [3] = "c"}
for k, v in pairs(t) do
  print(k, v)  -- Prints both entries (order undefined)
end

-- For sequences, ensure no holes
local t = {"a", nil, "c"}  -- Hole at index 2
-- ipairs stops at index 1
-- Fix: remove holes or use pairs
```

## Key Takeaway

`ipairs` stops at the first nil, not at `#t`. For tables with holes, use `pairs` or fix the holes.
