# String Concatenation Performance

## The Mistake

Building strings with `..` in a loop creates O(n²) allocations because strings are immutable.

## Reproduction

```lua
-- O(n²) — creates a new string every iteration
local result = ""
for i = 1, 10000 do
  result = result .. tostring(i) .. ", "
end
```

## Why It's Wrong

Each `..` creates a new string and copies all previous content. For n iterations, this copies 1+2+3+...+n = O(n²) characters.

## The Fix

```lua
-- O(n) — table.concat builds once
local parts = {}
for i = 1, 10000 do
  parts[#parts + 1] = tostring(i)
end
local result = table.concat(parts, ", ")
```

## Key Takeaway

Use `table.concat` for building strings in loops. It's O(n) instead of O(n²).
