# GC Timing Assumptions

Garbage collection runs asynchronously. Assuming objects are collected immediately leads to resource leaks and dangling references.

## The Mistake

```lua
local function create_temp()
  local data = {}
  for i = 1, 10000 do
    data[i] = string.rep("x", 1000)
  end
  return data -- caller must hold reference
end

local function process()
  for i = 1, 50 do
    create_temp() -- return value ignored, but GC hasn't freed it yet
    -- the heap climbs until the collector catches up
  end
end

process()
print(collectgarbage("count")) -- may show high memory
```

Worse — using `collectgarbage()` as a synchronization point:

```lua
local obj = setmetatable({}, { __gc = function(self)
  print("cleaning up")
end})

obj = nil
collectgarbage("collect")
-- On Lua 5.2 and later the finalizer has run by now. On Lua 5.1 and on
-- LuaJIT a table has no finalizer at all, so nothing is ever printed.
```

## Reproduction

Dropping the last reference does not run the finalizer on the spot:

```lua
local function create_resource()
  local data = string.rep("x", 1000000)
  return setmetatable({}, {
    __gc = function(self)
      print("Released resource")
    end,
  })
end

local r = create_resource()
r = nil
-- "Released resource" is not necessarily printed right away!
-- GC timing is not deterministic
```

The one finalizer the Lua 5.1 baseline does have belongs to userdata — a
file handle is the everyday example:

```lua
local handle = assert(io.open("resource.tmp", "w"))
handle:write("data")
handle = nil
-- The handle is closed when the collector gets to it, not here.
collectgarbage("collect")
```

## Why It's Wrong

Lua's garbage collector is a mark-and-sweep collector that runs incrementally. Key facts:

- Setting a reference to `nil` does **not** immediately free the object
- `collectgarbage("collect")` triggers a full cycle, but the collector may
  not reach the object in that cycle
- **Only userdata had a finalizer in Lua 5.1.** A table with a `__gc`
  metatable was never finalized at all. Lua 5.2 gave tables finalizers;
  LuaJIT still follows the 5.1 rule
- On Lua 5.4 and later, one `collectgarbage("collect")` runs the pending
  finalizers. On Lua 5.2 and 5.3 they may need another cycle
- A finalized object survives one extra cycle before it is actually freed

## The Fix

For predictable resource cleanup, use explicit lifecycle management:

```lua
local resource = {
  data = {},
  close = function(self)
    self.data = nil
  end,
}

-- Explicit cleanup
resource:close()
resource = nil
```

If you do rely on a finalizer, account for the delay — and check the
version, because on Lua 5.1 and LuaJIT a table finalizer never runs:

```lua
local obj = setmetatable({}, {
  __gc = function(self)
    print("finalizer runs later, not now")
  end,
})

obj = nil
collectgarbage("collect")
-- Lua 5.4 and later: the finalizer has run by now.
-- Lua 5.2 and 5.3: it may need one more cycle.
-- Lua 5.1 and LuaJIT: a table has no finalizer; nothing will ever run.
```

Monitor memory proactively:

```lua
local function mem_usage()
  local kb = collectgarbage("count")
  return string.format("%.1f MB", kb / 1024)
end

print("before:", mem_usage())
-- ... allocate heavy objects ...
collectgarbage("collect")
print("after:", mem_usage())
```

## Key Takeaway

Never rely on GC timing for correctness. Use explicit `close()`/`dispose()` patterns for finite resources (files, sockets, FFI allocations). Treat `collectgarbage()` as a hint, not a guarantee — and remember that on Lua 5.1 and LuaJIT only userdata is ever finalized.
