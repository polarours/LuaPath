# Rawlen vs # Operator

## The Mistake

Assuming `#t` and `rawlen(t)` always return the same value. They differ on tables with metatables that define `__len`.

## Reproduction

```lua
local t = {1, 2, 3}
setmetatable(t, {__len = function() return 99 end})

print(#t)       -- 99 (uses __len)
print(rawlen(t)) -- 3 (bypasses __len)
```

## Why It's Wrong

`#t` invokes the `__len` metamethod if present. `rawlen(t)` always returns the raw table length without metamethod dispatch. Mixing them leads to inconsistent behavior.

## The Fix

```lua
-- Be explicit about which you need
local len = #t           -- Respects metatables
local raw_len = rawlen(t) -- Ignores metatables

-- Document your intent
--- Get the actual data length, ignoring metatables
local function data_length(t)
  return rawlen(t)
end
```

## Key Takeaway

`#t` uses metamethods; `rawlen(t)` doesn't. Choose based on whether you want metatable behavior or raw data length.
