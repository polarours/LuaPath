# Coroutine C-Function Boundary

Yielding from inside a C function boundary is undefined behavior in standard Lua. The coroutine silently fails or crashes.

## The Mistake

```lua
local co = coroutine.create(function()
  -- some C-implemented function that internally calls yield
  local result = io.read("*l") -- C function — can yield? No!
  coroutine.yield(result)
end)

coroutine.resume(co) -- works, but io.read is already complete
```

The real danger is deeper:

```lua
local ffi = require("ffi")

local co = coroutine.create(function()
  -- hypothetical C library callback that yields
  some_c_callback_that_calls_lua() -- crashes or corrupts state
end)
```

## Why It's Wrong

Standard Lua 5.1 does not allow `coroutine.yield` inside C function boundaries (called via C API). LuaJIT and Lua 5.2+ relaxed this in specific cases, but:

- `io.read`, `os.execute`, and most `io.*` functions are C-bound
- Yielding inside a pcall/xpcall wrapped by C code may lose the error
- Behavior varies between Lua versions — code that works in 5.3 may break in 5.1

## The Fix

Restructure so yields happen at Lua boundaries:

```lua
-- ❌ Bad: yield inside C boundary
local co = coroutine.create(function()
  local data = io.read("*l")  -- C function
  coroutine.yield(data)       -- may not survive
end)

-- ✅ Good: yield between Lua-visible steps
local co = coroutine.create(function()
  -- Step 1: do I/O
  local data = io.read("*l")

  -- Step 2: yield at a safe Lua boundary
  coroutine.yield(data)

  -- Step 3: continue
  return data:upper()
end)

local ok, val = coroutine.resume(co)
if ok then
  ok, val = coroutine.resume(co) -- gets the uppercased result
end
```

In Lua 5.2+, `io.read` can yield if the file handle supports it, but this is implementation-dependent. Guard with a version check:

```lua
if _VERSION == "Lua 5.1" then
  -- never yield across C boundaries
end
```

## Key Takeaway

Assume any library function implemented in C cannot yield. Place `coroutine.yield` calls at explicit Lua-layer boundaries. Check `_VERSION` when writing cross-version code.
