# Pairs Iteration Order

`pairs` does not guarantee insertion order. Relying on order produces non-deterministic results.

## The Mistake

```lua
local config = {
  host = "localhost",
  port = 8080,
  debug = true,
}

for key, value in pairs(config) do
  print(key, value)
end
-- Output order varies across runs and Lua versions
```

Worse — assuming order for serialization:

```lua
local function serialize(t)
  local parts = {}
  for k, v in pairs(t) do
    table.insert(parts, k .. "=" .. tostring(v))
  end
  return table.concat(parts, ", ")
end

-- Two calls may produce different strings:
serialize(config) -- "host=localhost, port=8080, debug=true"
serialize(config) -- "port=8080, host=localhost, debug=true"
```

## Why It's Wrong

`pairs` iterates over the **hash part** of a table. The hash part uses a hash table internally, so iteration order depends on:

- Hash function implementation
- Insertion sequence
- Previous deletions
- Lua version (5.1 vs 5.3 vs 5.4)

There is no documented guarantee of any ordering.

## The Fix

Use an explicit order — either a separate keys array or `ipairs`:

```lua
local config = {
  host   = "localhost",
  port   = 8080,
  debug  = true,
}

local order = { "host", "port", "debug" }

for _, key in ipairs(order) do
  print(key, config[key])
end
-- Always prints host, port, debug
```

For serialization, build a sorted key list:

```lua
local function serialize(t)
  local keys = {}
  for k in pairs(t) do
    keys[#keys + 1] = k
  end
  table.sort(keys)

  local parts = {}
  for _, k in ipairs(keys) do
    parts[#parts + 1] = k .. "=" .. tostring(t[k])
  end
  return table.concat(parts, ", ")
end
```

## Key Takeaway

`pairs` gives you **all** keys, not **ordered** keys. When sequence matters, maintain an explicit key list or sort before iterating.
