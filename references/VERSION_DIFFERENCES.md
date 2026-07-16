# Lua Version Differences

Comprehensive comparison of behavior across Lua versions.

---

## Quick Comparison Table

| Feature | 5.1 | 5.2 | 5.3 | 5.4 | LuaJIT |
|---------|-----|-----|-----|-----|--------|
| **Number Types** | float | float | int + float | int + float | float + FFI |
| **Integer Division** | ✗ | ✗ | `//` | `//` | `//` (ext) |
| **Bitwise Operators** | ✗ | ✗ | ✓ | ✓ | ✓ (ext) |
| **`_ENV`** | ✗ | ✓ | ✓ | ✓ | Partial |
| **`setfenv`/`getfenv`** | ✓ | ✗ | ✗ | ✗ | ✓ |
| **Generational GC** | ✗ | ✗ | ✗ | ✓ | ✗ |
| **To-Be-Closed Vars** | ✗ | ✗ | ✗ | ✓ | ✗ |
| **Ephemeron Tables** | ✗ | ✓ | ✓ | ✓ | ✓ |
| **`goto` Statement** | ✗ | ✓ | ✓ | ✓ | ✗ |
| **Bitwise Library** | ✗ | `bit32` | operators | operators | `bit.*` |
| **`__len` Metamethod** | ✗ | ✓ (tables) | ✓ | ✓ | ✓ |
| **Package System** | `module` | `require` | `require` | `require` | `require` |
| **FFI** | ✗ | ✗ | ✗ | ✗ | ✓ |
| **JIT Compilation** | ✗ | ✗ | ✗ | ✗ | ✓ |

---

## Number Representation

### Lua 5.1–5.2

```lua
-- Single number type (double-precision float)
print(type(42))       -- "number"
print(type(3.14))     -- "number"
print(42 == 42.0)     -- true

-- Precision limit
print(9007199254740993 == 9007199254740992)  -- true (precision loss!)
```

### Lua 5.3+

```lua
-- Dual representation
print(type(42))       -- "integer"
print(type(3.14))     -- "float"
print(42 == 42.0)     -- true (coerced for comparison)

-- Integer division
print(5 // 2)         -- 2 (integer)
print(5 / 2)          -- 2.5 (float)

-- Bitwise operators
print(5 | 3)          -- 7
print(5 & 3)          -- 1
print(5 ~ 3)          -- 6
print(~5)             -- -6
print(5 << 1)         -- 10
print(5 >> 1)         -- 2
```

### LuaJIT

```lua
-- Single number type (like 5.1)
print(type(42))       -- "number"

-- But FFI provides integers
local ffi = require("ffi")
local x = ffi.cast("int", 42)
print(type(x))        -- "cdata"

-- Bitwise via library
local bit = require("bit")
print(bit.bor(5, 3))  -- 7
```

---

## Environment Model

### Lua 5.1: `setfenv` / `getfenv`

```lua
-- Get current environment
local env = getfenv()

-- Set function's environment
local function restricted()
  print("hello")  -- Will fail if print removed
end

setfenv(restricted, {print = print})  -- Only print allowed

-- Create sandbox
local sandbox = {
  print = print,
  math = math,
}
setfenv(restricted, sandbox)
```

### Lua 5.2+: `_ENV`

```lua
-- _ENV is a regular variable
local function restricted()
  print("hello")
end

-- Change environment at compile time
local function sandboxed()
  print("hello")
end

local sandbox = {print = print}
debug.setupvalue(sandboxed, 1, sandbox)  -- Set _ENV upvalue

-- Or use _ENV directly in chunk
local chunk = load([[
  print(_VERSION)  -- Uses _ENV from load context
]], "=chunk", "t", {print = print, _VERSION = _VERSION})
```

### Migration: 5.1 → 5.2+

```lua
-- 5.1 code
setfenv(1, {print = print, x = 10})

-- 5.2+ equivalent
_ENV = {print = print, x = 10}

-- Or for function
local function fn()
  print(x)
end
debug.setupvalue(fn, 1, {print = print, x = 10})
```

---

## Garbage Collection

### Incremental GC (All Versions)

```lua
-- Control incremental GC
collectgarbage("setpause", 200)    -- Wait 200% of last collection
collectgarbage("setstepmul", 200)  -- 200% speed relative to allocation

-- Manual control
collectgarbage("stop")             -- Stop GC
collectgarbage("restart")          -- Restart GC
collectgarbage("collect")          -- Full collection
collectgarbage("count")            -- Memory in KB
```

### Generational GC (Lua 5.4+)

```lua
-- Enable generational mode (5.4)
collectgarbage("generational")

-- Or incremental mode explicitly
collectgarbage("incremental")

-- Check mode
-- Note: No direct query, track in your code
```

### LuaJIT GC

```lua
-- LuaJIT-specific control
collectgarbage("setpause", 200)

-- JIT control
jit.on()
jit.off()
jit.flush()

-- GC steps affect JIT behavior
```

---

## String Formatting

### All Versions

```lua
-- Basic formatting (consistent)
string.format("%d", 42)      -- "42"
string.format("%s", "hi")    -- "hi"
string.format("%.2f", 3.14159)  -- "3.14"
```

### Lua 5.3+ (Integer Formatting)

```lua
-- Integer-specific
string.format("%i", 42)      -- "42"
string.format("%d", 42)      -- "42"

-- Hex for integers
string.format("%x", 255)     -- "ff"
string.format("%X", 255)     -- "FF"
```

---

## Table Length Operator

### All Versions

```lua
-- Well-defined for sequences (no holes)
local t = {1, 2, 3}
print(#t)  -- 3

-- Undefined behavior with holes
local t = {1, nil, 3}
print(#t)  -- Could be 1, 2, or 3 (implementation-dependent!)
```

### Lua 5.2+ (Ephemeron Tables)

```lua
-- Weak tables with __mode = "k" behave better
local t = setmetatable({}, {__mode = "k"})
local key = {}
t[key] = "value"
-- When key is collected, entry is removed
```

---

## Module System

### Lua 5.1: `module` Function

```lua
-- mymodule.lua (5.1 style)
module("mymodule", package.seeall)

function hello()
  print("Hello")
end

-- Usage
local m = require("mymodule")
m.hello()
```

### Lua 5.2+: Explicit Return

```lua
-- mymodule.lua (modern style)
local M = {}

function M.hello()
  print("Hello")
end

return M

-- Usage
local m = require("mymodule")
m.hello()
```

### LuaJIT: Prefer Modern Style

```lua
-- Use 5.2+ style even in LuaJIT
-- module() is deprecated
```

---

## Coroutine Differences

### All Versions

```lua
-- Basic coroutine API (consistent)
local co = coroutine.create(function()
  coroutine.yield(1)
  return 2
end)

coroutine.resume(co)  -- true, 1
coroutine.resume(co)  -- true, 2
```

### Lua 5.2+ (Additional Functions)

```lua
-- Lua 5.2+ additions
coroutine.running()        -- Returns (thread, is_main)
coroutine.isyieldable()    -- Check if yield is allowed (5.3+)
```

### LuaJIT

```lua
-- LuaJIT coroutines work with JIT
-- But yielding across certain boundaries disables JIT
```

---

## Error Handling

### All Versions

```lua
-- pcall and xpcall (consistent)
local success, result = pcall(function()
  error("oops")
end)

local success, result = xpcall(function()
  error("oops")
end, debug.traceback)
```

### Lua 5.4+ (Error Unwrap)

```lua
-- Lua 5.4: error objects
local function wrapped()
  local ok, err = pcall(function()
    error({code = "ENOENT", message = "Not found"})
  end)
  
  if not ok then
    print(err.code)  -- Access structured error
  end
end
```

---

## To-Be-Closed Variables (Lua 5.4+)

```lua
-- Lua 5.4 only
local function process_file(path)
  local f <close> = assert(io.open(path))
  -- f is automatically closed when scope exits
  return f:read("*all")
end

-- Equivalent to:
local function process_file(path)
  local f = assert(io.open(path))
  local ok, result = pcall(function()
    return f:read("*all")
  end)
  f:close()
  if not ok then error(result) end
  return result
end
```

---

## `goto` Statement (Lua 5.2+)

```lua
-- Lua 5.2+ only
local function find_needle(haystack)
  for i = 1, #haystack do
    if haystack[i] == "needle" then
      goto found
    end
  end
  return nil
  
  ::found::
  return i
end
```

---

## Metamethod Differences

### `__len` Metamethod

| Version | Tables | Userdata |
|---------|--------|----------|
| 5.1 | ✗ | ✓ |
| 5.2+ | ✓ | ✓ |

```lua
-- 5.2+ only
local t = setmetatable({}, {
  __len = function(self) return 42 end
})
print(#t)  -- 42 (5.2+)
           -- Error or 0 (5.1)
```

---

## LuaJIT-Specific Features

### FFI (Foreign Function Interface)

```lua
local ffi = require("ffi")

-- Define C types
ffi.cdef[[
  int printf(const char *fmt, ...);
  typedef struct { double x, y; } Point;
]]

-- Call C functions
ffi.C.printf("Hello from C!\n")

-- Create C structures
local p = ffi.new("Point", 1.0, 2.0)
print(p.x, p.y)  -- 1.0, 2.0
```

### JIT Control

```lua
-- JIT compilation control
jit.on()              -- Enable JIT
jit.off()             -- Disable JIT
jit.flush()           -- Flush compiled code

-- Per-function
jit.off(function()
  -- This function won't be JIT compiled
end)

-- Pragmas
jit.pruneoff()        -- Auto-off for certain patterns
```

### Bit Library

```lua
local bit = require("bit")

-- Bitwise operations (all Lua versions with LuaJIT)
print(bit.bor(5, 3))   -- 7
print(bit.band(5, 3))  -- 1
print(bit.bxor(5, 3))  -- 6
print(bit.bnot(5))     -- -6
print(bit.lshift(5, 1)) -- 10
print(bit.rshift(5, 1)) -- 2
```

---

## Compatibility Guidelines

### Writing Cross-Version Code

```lua
-- Detect version
local LUA_VERSION = _VERSION:match("%d+%.%d+")

-- Version-specific code
if LUA_VERSION >= "5.3" then
  -- Use integer division
  local result = 5 // 2
else
  -- Fallback
  local result = math.floor(5 / 2)
end

-- Detect LuaJIT
local is_luajit = jit and true or false
if is_luajit then
  local ffi = require("ffi")
  -- Use FFI
end
```

### Recommended Baseline

| Use Case | Recommended Version |
|----------|---------------------|
| Embedded scripting | Lua 5.1 (maximum compatibility) |
| Game scripting | Lua 5.3 or LuaJIT |
| New projects | Lua 5.4 |
| Performance-critical | LuaJIT |
| Library development | Lua 5.1 (widest audience) |

---

## Migration Checklist

### 5.1 → 5.3+

- [ ] Replace `setfenv`/`getfenv` with `_ENV`
- [ ] Update number handling (integers)
- [ ] Add bitwise operators where applicable
- [ ] Review `module()` usage (use explicit return)
- [ ] Test `__len` metamethod if used

### PUC Lua → LuaJIT

- [ ] Test JIT compatibility (avoid trace aborts)
- [ ] Consider FFI for C interop
- [ ] Review GC-sensitive code
- [ ] Test with `jit.off()` for debugging

---

## See Also

- [Lua 5.1 Manual](https://www.lua.org/manual/5.1/)
- [Lua 5.3 Manual](https://www.lua.org/manual/5.3/)
- [Lua 5.4 Manual](https://www.lua.org/manual/5.4/)
- [LuaJIT Documentation](https://luajit.org/)
- [Lua 5.3 Changes](https://www.lua.org/manual/5.3/readme.html#changes)
- [Lua 5.4 Changes](https://www.lua.org/manual/5.4/readme.html#changes)
