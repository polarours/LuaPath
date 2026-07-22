# Table Length Undefined on Non-Sequences

## The Mistake

Using `#t` on a table that is not a proper sequence (contiguous integer keys from 1 to n with no holes) produces undefined behavior.

```lua
-- Undefined length behavior
local t = {1, 2, nil, 4, 5}
print(#t)  -- Could be 2, 4, or 5 depending on implementation

-- Non-sequential keys
local t = {[1] = "a", [5] = "e"}
print(#t)  -- Could be 1 or 5
```

## Why It Fails

The Lua reference manual states that `#t` is only defined for sequences (tables with contiguous integer keys from 1 to n). For non-sequences, the result is implementation-dependent.

## The Fix

```lua
-- For sequences, # is safe
local t = {1, 2, 3, 4, 5}
print(#t)  -- 5 (safe)

-- For non-sequences, count manually
local t = {[1] = "a", [5] = "e"}
local count = 0
for _ in pairs(t) do count = count + 1 end
print(count)  -- 2

-- Or track length explicitly
local t = {data = {}, length = 0}
t.length = t.length + 1
t.data[t.length] = "new item"
```

## Related Concepts

- [04-tables.md](../en/04-tables.md) — Table fundamentals
- [Lua Reference Manual](https://www.lua.org/manual/5.4/manual.html#3.4.7) — Length operator
