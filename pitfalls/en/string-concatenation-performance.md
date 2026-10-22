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

Each `..` creates a new string, and the result of the previous iteration is
part of the next one, so every iteration copies everything built so far. For
n iterations that copies 1+2+3+...+n = O(n²) characters.

Lua does concatenate several `..` operands of a single expression in one
pass, so `a .. b .. c` is not three copies. The quadratic cost comes from the
loop carrying the growing string across iterations, not from the number of
`..` in one statement.

Measured on the reference interpreter, 10,000 up to 160,000 characters:

| n | `result = result .. x` | `table.concat` | Ratio |
|---|---|---|---|
| 1,000 | 0.0005 s | 0.0003 s | 1.8x |
| 4,000 | 0.0045 s | 0.0010 s | 4.7x |
| 8,000 | 0.0101 s | 0.0019 s | 5.2x |
| 16,000 | 0.0475 s | 0.0026 s | 18.6x |

The gap widens with n, which is what quadratic growth looks like.

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

## Related Concepts

- [12-performance.md](../../en/12-performance.md) — Performance optimization
- [09-standard-library.md](../../en/09-standard-library.md) — String library
