# GC Timing Assumptions

Garbage collection runs asynchronously. Assuming objects are collected immediately leads to resource leaks and dangling references.

## The Mistake

```lua
local function create_temp()
  local data = {}
  for i = 1, 100000 do
    data[i] = string.rep("x", 1000)
  end
  return data -- caller must hold reference
end

local function process()
  for i = 1, 1000 do
    create_temp() -- return value ignored, but GC hasn't freed it yet
    -- memory keeps growing
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
-- __gc might NOT have run yet — finalizers are deferred
```

## Why It's Wrong

Lua's garbage collector is a mark-and-sweep collector that runs incrementally. Key facts:

- Setting a reference to `nil` does **not** immediately free the object
- `collectgarbage("collect")` triggers a full cycle, but **finalizers** (`__gc`) run in a separate phase
- Finalized objects survive one extra GC cycle before collection
- In Lua 5.1, finalizers run at the **end** of the collection cycle — not during

## The Fix

For predictable resource cleanup, use explicit lifecycle management:

```lua
local resource = {
  data = {},
  close = function(self)
    self.data = nil
    collectgarbage("collect")
  end,
}

-- Explicit cleanup
resource:close()
resource = nil
```

For finalizers, account for the delay:

```lua
local obj = setmetatable({}, {
  __gc = function(self)
    print("finalizer runs later, not now")
  end,
})

obj = nil
collectgarbage("collect")
collectgarbage("collect") -- second pass to finalize
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

Never rely on GC timing for correctness. Use explicit `close()`/`dispose()` patterns for finite resources (files, sockets, FFI allocations). Treat `collectgarbage()` as a hint, not a guarantee.
