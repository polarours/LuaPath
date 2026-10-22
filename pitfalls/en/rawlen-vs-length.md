# Rawlen vs # Operator

## The Mistake

Assuming `#t` and `rawlen(t)` always return the same value, and assuming both exist. They differ on tables whose metatable defines `__len` — and on Lua 5.1 and LuaJIT, `rawlen` is not there at all.

## Reproduction

```lua
local t = {1, 2, 3}
setmetatable(t, {__len = function() return 99 end})

print(#t)        -- 99 on Lua 5.2+, but 3 on Lua 5.1 and LuaJIT,
                 -- where __len is honoured for userdata only
print(rawlen(t)) -- 3 on Lua 5.2+; on Lua 5.1 and LuaJIT this raises
                 -- "attempt to call a nil value (global 'rawlen')"
```

## Why It's Wrong

Two different things are going on, and they arrived in different versions:

- `#t` invokes the `__len` metamethod if the metatable has one — but only
  from Lua 5.2 on. In Lua 5.1 and LuaJIT, `__len` applies to userdata only,
  so `#t` returns the raw length of a table
- `rawlen(t)` returns the raw table length without metamethod dispatch. It
  was added in Lua 5.2 as well, so on Lua 5.1 and LuaJIT the call fails
  outright

A project that supports Lua 5.1, 5.3, 5.4 and LuaJIT therefore has two
different behaviours for the same line of code, and the older one does not
even have the function.

## The Fix

Be explicit about which you need, and stay inside what the running version
provides:

```lua
local t = {1, 2, 3}
setmetatable(t, {__len = function() return 99 end})

-- The raw length of a table, on every supported version.
-- For a sequence this is the same as #t; for a table with holes it is the
-- number of keys, which is a different question.
local function raw_length(t)
  if rawlen then
    return rawlen(t)
  end
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

-- The length as the running version sees it, metatable or not.
local len = #t
```

When the metatable defines `__len`, decide deliberately which of the two you
mean — and document it, because the answer changes with the Lua version.

## Key Takeaway

`#t` uses metamethods from Lua 5.2 on; `rawlen(t)` ignores them and exists
only from Lua 5.2 on as well. On Lua 5.1 and LuaJIT a table has no
`__len` dispatch and no `rawlen`, so write the fallback yourself.
