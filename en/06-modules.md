# 06 — Modules

> **Phase**: B (Meta Layer and Architecture)  
> **Prerequisites**: Chapter 05 — Metatables  
> **Time Estimate**: 2–3 hours reading + 2–4 hours exercises  
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT (differences noted)

---

## Learning Objectives

After completing this chapter, you will be able to:

1. **Create Lua modules** using the standard table-return pattern
2. **Understand `require` semantics** including caching, path resolution, and error handling
3. **Design clean module APIs** with explicit exports and encapsulated internals
4. **Avoid circular dependencies** and handle initialization order correctly
5. **Use `package.loaded` and `package.path`** for custom module loading behavior

---

## Module Pattern

A Lua module is a file that returns a table. The table defines the module's public API.

```lua
-- stringx.lua
local M = {}

-- Public function
function M.trim(s)
  return s:match("^%s*(.-)%s*$")
end

-- Public function
function M.split(s, sep)
  local result = {}
  local pattern = "([^" .. sep .. "]+)"
  for match in s:gmatch(pattern) do
    result[#result + 1] = match
  end
  return result
end

-- Private function (not exported)
local function validate(s)
  return type(s) == "string"
end

return M
```

```lua
-- Usage
local stringx = require("stringx")
print(stringx.trim("  hello  "))     -- "hello"
print(table.concat(stringx.split("a,b,c", ","), "|"))  -- "a|b|c"
```

### Why Return a Table?

Returning a table creates a clean namespace:

```lua
-- GOOD: Table-based module
local M = {}
function M.process() ... end
return M

-- BAD: Global functions
function process() ... end  -- Pollutes global namespace
```

---

## Require Semantics

`require` is the standard way to load modules:

```lua
local mod = require("module_name")
```

### Path Resolution

`require` uses `package.path` (for Lua files) and `package.cpath` (for C libraries):

```lua
-- Default package.path (varies by installation)
print(package.path)
-- "?;?.lua;./?/init.lua;/usr/local/share/lua/5.4/?.lua;..."

-- The ? is replaced by the module name
require("mathx")
-- Searches: mathx, mathx.lua, ./mathx/init.lua, ...
```

### package.loaded Cache

`require` caches results in `package.loaded`:

```lua
-- After require("mymod"), it's cached:
print(package.loaded["mymod"])  -- The module table

-- To force reload (e.g., in tests):
package.loaded["mymod"] = nil
local mymod = require("mymod")  -- Reloads from disk
```

### require Return Value

`require` returns the value stored in `package.loaded`. If the module returns a table, that table is cached:

```lua
-- mymod.lua
return {version = "1.0"}  -- This table becomes package.loaded["mymod"]
```

```lua
local m1 = require("mymod")
local m2 = require("mymod")
print(m1 == m2)  -- true (same table, cached)
```

---

## Module Loading Lifecycle

```lua
-- mymod.lua (loaded in order)

-- 1. Module-level code runs once on first require
print("mymod loading...")
local dep = require("dependency")

-- 2. Define local helpers
local function internal_helper() ... end

-- 3. Define public API
local M = {}
function M.do_something() ... end

-- 4. Optional: run initialization
M._initialized = true

-- 5. Return the module table
return M
```

---

## Encapsulation Patterns

### Private State with Upvalues

```lua
-- counter.lua
local M = {}

-- Private state (not accessible from outside)
local count = 0

function M.increment()
  count = count + 1
  return count
end

function M.get_count()
  return count
end

return M
```

### Private via Closure

```lua
-- auth.lua
local M = {}

local function create_token(user)
  -- Private: can't be called directly from outside
  return user .. ":" .. tostring(os.time())
end

function M.authenticate(user, password)
  if verify_password(user, password) then
    return create_token(user)
  end
  return nil, "invalid credentials"
end

return M
```

### Private via Metatable

```lua
-- secret.lua
local M = {}
local data = {}  -- Private storage

local proxy = setmetatable({}, {
  __index = data,
  __newindex = function(_, k, v)
    if k == "secret_key" then
      rawset(data, k, v)
    else
      error("Cannot set field: " .. tostring(k))
    end
  end,
  __metatable = false,  -- Prevent external access
})

function M.get_proxy() return proxy end
return M
```

---

## API Design Principles

### Narrow Export Surface

```lua
-- GOOD: Few, well-defined functions
local M = {}
function M.process(config) ... end
function M.validate(config) ... end
return M

-- BAD: Expose everything
local M = {}
M.process = function() ... end
M._internal_helper = function() ... end  -- Leaks implementation
M._config = {}  -- Mutable internal state exposed
return M
```

### Stateless Utilities vs Stateful Services

```lua
-- Stateless utility module (no side effects)
local M = {}
function M.add(a, b) return a + b end
function M.mul(a, b) return a * b end
return M

-- Stateful service module (requires initialization)
local M = {}
local connection = nil

function M.connect(host, port)
  connection = create_connection(host, port)
end

function M.query(sql)
  assert(connection, "Not connected")
  return connection:execute(sql)
end

function M.disconnect()
  if connection then
    connection:close()
    connection = nil
  end
end

return M
```

### Constructor Pattern

```lua
-- db.lua
local DB = {}
DB.__index = DB

function DB.new(config)
  return setmetatable({
    host = config.host or "localhost",
    port = config.port or 5432,
    connected = false,
  }, DB)
end

function DB:connect()
  self.connected = true
  return self
end

function DB:close()
  self.connected = false
end

return DB
```

---

## Circular Dependencies

When module A requires B and B requires A:

```lua
-- a.lua
local b = require("b")  -- Triggers loading of b
function a_func() return b.b_func() end
return a

-- b.lua
local a = require("a")  -- a is partially loaded (may be nil or incomplete!)
function b_func() return a.a_func() end
return b
```

### Solutions

**1. Merge into one module** (preferred when coupling is tight):

```lua
-- shared.lua
local M = {}
function M.a_func() ... end
function M.b_func() ... end
return M
```

**2. Lazy require** (defer loading):

```lua
-- a.lua
local a = {}
function a_func()
  local b = require("b")  -- Load on demand
  return b.b_func()
end
return a
```

**3. Extract shared code** into a third module:

```lua
-- common.lua (no dependencies)
local M = {}
function M.shared_func() ... end
return M

-- a.lua
local common = require("common")
return { a_func = common.shared_func }

-- b.lua
local common = require("common")
return { b_func = common.shared_func }
```

---

## Preloading and package.loaded

### Preloading Modules

```lua
-- Inject a module without a file
package.loaded["mypreload"] = {version = "1.0", hello = function() print("hi") end}
local m = require("mypreload")
m.hello()  -- "hi"
```

### Custom package.loaders (5.1) / package.searchers (5.2+)

```lua
-- Custom loader that generates modules on the fly
table.insert(package.searchers, function(name)
  if name == "generated" then
    return function()
      return {generated = true, timestamp = os.time()}
    end
  end
end)

local m = require("generated")
print(m.timestamp)  -- Current timestamp
```

---

## Common Pitfalls

### 1. Side Effects During `require`

```lua
-- BAD: Module does work on require
local M = {}
print("Processing...")  -- Runs every time require is called? No — only first.
-- But: this runs at load time, which may be unexpected

-- GOOD: Separate load from initialization
local M = {}
function M.init()
  print("Processing...")
end
return M
```

### 2. Implicit Globals

```lua
-- BUG: Accidentally creates global
local M = {}
function M.process()
  result = 42  -- Global! Should be local
  return result
end
return M
```

### 3. Mutating package.loaded Directly

```lua
-- BAD: Overwriting another module's cache
package.loaded["other_module"] = nil  -- May break other code

-- BETTER: Only nil your own module for reload
package.loaded["my_module"] = nil
```

### 4. Returning Multiple Values from require

`require` returns only the first value from the module:

```lua
-- mymod.lua
return "value1", "value2"  -- Only "value1" is cached

local v1, v2 = require("mymod")
-- v1 = "value1", v2 = nil!
```

---

## Best Practices

### 1. Return Explicit Module Table

```lua
-- GOOD
local M = {}
M.process = function() ... end
return M

-- Also fine for simple modules
return {
  process = function() ... end,
}
```

### 2. Document Module Lifecycle

```lua
--- Module: database connection manager
-- Usage:
--   local db = require("db")
--   db.connect("localhost", 5432)
--   local result = db.query("SELECT ...")
--   db.disconnect()
--
-- State: requires connect() before query()
-- Cleanup: call disconnect() or use __gc
```

### 3. Keep Dependencies Acyclic

```
app.lua → db.lua → config.lua
                  → logger.lua
      → handler.lua → db.lua (same dependency, fine)
                    → auth.lua → config.lua (fine, shared leaf)
```

Avoid: `a.lua → b.lua → a.lua` (cycle)

### 4. One Module, One Responsibility

```lua
-- GOOD: Focused modules
local config = require("config")     -- Configuration loading
local db = require("db")            -- Database operations
local logger = require("logger")    -- Logging

-- BAD: God module
local everything = require("everything")
everything.config.load()
everything.db.query()
everything.logger.info()
```

### 5. Use __name for Module Identity

```lua
-- Helps with debugging and error messages
local M = {}
setmetatable(M, {__name = "mymodule"})
```

---

## Version Notes

### Lua 5.1

- Uses `setfenv`/`getfenv` for environment manipulation
- `package.loaders` (not `package.searchers`)
- No `table.pack`/`table.unpack`
- `module()` function available (deprecated — don't use it)

```lua
-- Lua 5.1 (deprecated pattern)
module("mymod", package.seeall)  -- DON'T USE THIS
-- Creates global table and sets environment
```

### Lua 5.2/5.3

- `package.searchers` replaces `package.loaders`
- `require` returns only first value
- `table.pack`/`table.unpack` available
- `module()` removed

### Lua 5.4

- No significant module system changes from 5.3
- Better error messages for failed requires

### LuaJIT

- FFI modules loaded via `require` and `ffi.load`
- Some JIT-unfriendly patterns in module loading (avoid in hot paths)
- `package.loadlib` available for custom C library loading

---

## Knowledge Check

<details>
<summary>1. What does <code>require</code> return after the first call?</summary>

The cached value from `package.loaded[modname]`. If the module returned a table, that table is returned. Subsequent `require` calls don't re-execute the module code.
</details>

<details>
<summary>2. How do you force a module to reload?</summary>

Set `package.loaded[modname] = nil` before calling `require(modname)` again. This clears the cache and forces re-execution.
</details>

<details>
<summary>3. Why should you avoid <code>module()</code>?</summary>

It's deprecated (removed in 5.2+), pollutes the global namespace, and uses `setfenv` which makes debugging harder. Use the `local M = {}; return M` pattern instead.
</details>

<details>
<summary>4. How do circular dependencies cause bugs?</summary>

When A requires B which requires A, A may be partially loaded (or nil) when B tries to use it. Functions defined after the circular require may not exist yet.
</details>

<details>
<summary>5. What is the difference between <code>package.path</code> and <code>package.cpath</code?</summary>

`package.path` is for Lua source files (`.lua`). `package.cpath` is for compiled C libraries (`.so`, `.dll`). `require` checks both based on the module name.
</details>

---

## Key Takeaways

- **Module pattern**: `local M = {}; ...; return M`
- **`require` caches** in `package.loaded` — modules load once
- **Path resolution** uses `package.path` with `?` substitution
- **Encapsulate internals** via local variables, closures, or metatables
- **Avoid circular dependencies** — merge, lazy-load, or extract shared code
- **One module, one responsibility** — keep APIs narrow
- **Never use `module()`** — it's deprecated and harmful

---

## Exercises

### Beginner (30–60 min)

1. **String Utilities**: Create a `stringx` module with `trim`, `split`, `starts_with`, and `ends_with`. Include tests.

2. **Config Loader**: Build a `config` module that loads settings from a Lua file, with fallback defaults and environment variable overrides.

3. **Module Reloader**: Write a `reload(name)` function that clears a module from `package.loaded` and re-requires it.

### Intermediate (1–2 hours)

4. **Three-Module Split**: Take a monolithic script and split it into three modules: `config.lua`, `db.lua`, `app.lua`. Ensure clean dependency direction.

5. **Lazy Loader**: Implement a module proxy that defers `require` until the first function call on the module.

6. **Module with State**: Build a `cache` module with `get`, `set`, `invalidate`, and `clear` operations. Use private upvalues for storage.

### Advanced (2–4 hours)

7. **Plugin System**: Create a `plugins` module that auto-discovers and loads plugin modules from a directory. Handle errors gracefully.

8. **Hot Reload**: Implement a development-mode module loader that detects file changes and reloads modules without restarting the application.

---

## Example Code

Runnable examples for this chapter:
- `examples/intermediate/04-stateful-module.lua` — Stateful module with lifecycle
- `examples/intermediate/02-event-bus.lua` — Module-based event system

---

## Further Reading

- [Lua 5.4 Reference Manual — Section 6.3](https://www.lua.org/manual/5.4/manual.html#6.3)
- [Programming in Lua (4th ed.) — Chapter 15](https://www.lua.org/pil/)
- [Next Chapter: 07 — Error Handling](07-error-handling.md)
