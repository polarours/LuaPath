# String Concatenation Performance

## The Mistake

Building strings with `..` in a loop creates O(n²) complexity because each concatenation creates a new string.

```lua
-- O(n²) - very slow for large strings
local result = ""
for i = 1, 10000 do
  result = result .. tostring(i) .. ", "
end
```

## Why It Fails

Each `..` operation creates a new string by copying all previous content. For n iterations, this copies 1+2+3+...+n = n(n+1)/2 characters total.

## The Fix

```lua
-- O(n) - use table.concat
local parts = {}
for i = 1, 10000 do
  parts[i] = tostring(i)
end
local result = table.concat(parts, ", ")

-- Or use string.format for simple cases
local result = string.format("%s %s %s", a, b, c)
```

## Related Concepts

- [12-performance.md](../en/12-performance.md) — Performance optimization
- [09-standard-library.md](../en/09-standard-library.md) — String library
