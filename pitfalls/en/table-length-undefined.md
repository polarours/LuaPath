# Table Length Undefined on Non-Sequences

## The Mistake

Using `#t` on tables that aren't proper sequences (contiguous integers starting at 1 with no holes).

## Reproduction

```lua
-- Holes in sequence
local t = {1, 2, nil, 4, 5}
print(#t)  -- Could be 2, 4, or 5 (undefined!)

-- Non-contiguous keys
local t = {[1] = "a", [5] = "e"}
print(#t)  -- Could be 1 or 5 (undefined!)
```

## Why It's Wrong

The Lua reference says `#t` is only defined for sequences. For non-sequences, the result is implementation-dependent and may vary between Lua versions.

## The Fix

```lua
-- For sequences: #t is safe
local t = {1, 2, 3, 4, 5}
print(#t)  -- 5 (well-defined)

-- For non-sequences: count manually
local t = {[1] = "a", [5] = "e"}
local count = 0
for _ in pairs(t) do count = count + 1 end

-- Or track length explicitly
local t = {data = {}, n = 0}
```

## Key Takeaway

Only use `#t` on proper sequences. For everything else, iterate or track length explicitly.
