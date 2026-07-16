# Quick Reference Cards

Concise reference for common Lua operations and patterns.

---

## Syntax Quick Reference

### Variables and Scope

```lua
local x = 10          -- Local variable (preferred)
global = 20           -- Global variable (_ENV["global"])

do
  local y = 30        -- Block-scoped local
end
```

### Types

```lua
type(nil)             -- "nil"
type(true)            -- "boolean"
type(42)              -- "number" (integer or float in 5.3+)
type("hello")         -- "string"
type({})              -- "table"
type(function() end)  -- "function"
type(coroutine.create(function() end))  -- "thread"
```

### Control Flow

```lua
-- If statement
if condition then
  -- ...
elseif other then
  -- ...
else
  -- ...
end

-- Loops
for i = 1, 10 do end           -- Numeric for
for k, v in pairs(t) do end    -- Generic for (all keys)
for i, v in ipairs(t) do end   -- Generic for (array indices)
while condition do end         -- While loop
repeat ... until condition     -- Do-while equivalent
```

### Functions

```lua
-- Definition
function name(param1, param2)
  return result
end

-- Anonymous
local fn = function(x) return x * 2 end

-- Variadic
function sum(...)
  local args = {...}
  local total = 0
  for _, v in ipairs(args) do total = total + v end
  return total
end

-- Multiple returns
function divmod(a, b)
  return a // b, a % b
end
```

### Tables

```lua
-- Construction
local t = {}
local t = {1, 2, 3}           -- Array part
local t = {x = 1, y = 2}      -- Record
local t = {[1] = "a"}         -- Explicit key

-- Access
t.key          -- Same as t["key"]
t[key]         -- Dynamic key
t[1]           -- Array index

-- Length (only reliable for sequences!)
#t             -- Length of array part

-- Iteration
for k, v in pairs(t) do end    -- All keys
for i, v in ipairs(t) do end   -- Sequential integer keys
```

### Metatables

```lua
local mt = {
  __index = function(t, k) return default end,
  __newindex = function(t, k, v) rawset(t, k, v) end,
  __add = function(a, b) return a + b end,
  __tostring = function(t) return "table" end,
}

setmetatable(t, mt)
getmetatable(t)
```

### Modules

```lua
-- module.lua
local M = {}

function M.func() end

return M

-- Usage
local mod = require("module")
mod.func()
```

### Error Handling

```lua
-- Raise error
error("message", level)

-- Protected call
local success, result = pcall(fn, args)

-- Extended protected call
local success, result = xpcall(fn, debug.traceback)

-- Assert (returns values or raises)
local file = assert(io.open("file.txt"))
```

### Coroutines

```lua
local co = coroutine.create(fn)
local success, result = coroutine.resume(co)
local status = coroutine.status(co)  -- "running", "suspended", "dead"
coroutine.yield(value)
```

### String Patterns

```lua
s:match(pattern)           -- Extract match
s:gmatch(pattern)          -- Iterator over matches
s:gsub(pattern, repl)      -- Replace
s:find(pattern)            -- Find position

-- Pattern classes
"."    -- Any character
"%"    -- Escape character
"[%w]" -- Character class (word char)
"[^%w]"-- Negated class
"*"    -- 0 or more
"+"    -- 1 or more
"-"    -- 0 or more (non-greedy)
"?"    -- 0 or 1
```

---

## Standard Library Quick Reference

### `table`

| Function | Description |
|----------|-------------|
| `table.concat(t, sep, i, j)` | Concatenate elements |
| `table.insert(t, [pos,] val)` | Insert at position |
| `table.remove(t, [pos])` | Remove from position |
| `table.sort(t, [comp])` | Sort in place |
| `table.pack(...)` | Pack into indexed table |
| `table.unpack(t)` | Unpack to values |

### `string`

| Function | Description |
|----------|-------------|
| `string.len(s)` | Length |
| `string.sub(s, i, j)` | Substring |
| `string.format(fmt, ...)` | Format (printf-style) |
| `string.match(s, pat)` | First match |
| `string.gmatch(s, pat)` | Iterator over matches |
| `string.gsub(s, pat, repl)` | Replace all |
| `string.find(s, pat)` | Find position |
| `string.rep(s, n)` | Repeat n times |
| `string.reverse(s)` | Reverse string |
| `string.lower(s)` / `upper(s)` | Case conversion |

### `math`

| Function | Description |
|----------|-------------|
| `math.abs(x)` | Absolute value |
| `math.ceil(x)` / `floor(x)` | Rounding |
| `math.max(a, b, ...)` / `min(...)` | Extremes |
| `math.sqrt(x)` | Square root |
| `math.sin/cos/tan(x)` | Trigonometric |
| `math.asin/acos/atan(x)` | Inverse trig |
| `math.exp(x)` | e^x |
| `math.log(x)` / `log10(x)` | Logarithm |
| `math.pi` / `huge` | Constants |
| `math.random([m, n])` | Random number |

### `coroutine`

| Function | Description |
|----------|-------------|
| `coroutine.create(fn)` | Create coroutine |
| `coroutine.resume(co, ...)` | Resume execution |
| `coroutine.yield(...)` | Yield from inside |
| `coroutine.status(co)` | Get status |
| `coroutine.running()` | Get running coroutine |
| `coroutine.wrap(fn)` | Create wrapped function |

---

## C API Quick Reference

### Stack Operations

```c
lua_pushnil(L);
lua_pushboolean(L, int);
lua_pushinteger(L, lua_Integer);
lua_pushnumber(L, lua_Number);
lua_pushstring(L, const char*);
lua_pushlstring(L, const char*, size_t);
lua_pushfunction(L, lua_CFunction);
lua_pushcclosure(L, lua_CFunction, int n);

lua_pop(L, int n);
lua_topointer(L, int idx);
lua_toboolean(L, int idx);
lua_tointeger(L, int idx);
lua_tonumber(L, int idx);
lua_tostring(L, int idx);
lua_tocfunction(L, int idx);
lua_touserdata(L, int idx);

lua_settop(L, int idx);
lua_gettop(L);
lua_absindex(L, int idx);
lua_checkstack(L, int n);
```

### Table Operations

```c
lua_newtable(L);
lua_gettable(L, int idx);
lua_settable(L, int idx);
lua_rawget(L, int idx);
lua_rawset(L, int idx);
lua_next(L, int idx);
```

### Function Registration

```c
// Register functions
static const luaL_Reg mylib[] = {
  {"func_name", my_function},
  {NULL, NULL}
};

luaL_newlib(L, mylib);
luaL_requiref(L, "modname", luaopen_mymod, 1);
```

### Error Handling

```c
luaL_error(L, "error message");
luaL_checktype(L, int idx, int type);
luaL_checkinteger(L, int idx);
luaL_checkstring(L, int idx);
luaL_optinteger(L, int idx, lua_Integer def);
```

---

## Performance Tips

### Do's

```lua
-- Cache globals in hot loops
local sin = math.sin
for i = 1, 1000000 do
  x = sin(i)
end

-- Pre-allocate tables when size is known
local t = {}
for i = 1, n do
  t[i] = i * 2
end

-- Use local variables (register allocation)
local sum = 0
for i = 1, n do
  sum = sum + values[i]
end

-- Reuse tables in loops (when safe)
local buffer = {}
for i = 1, n do
  -- Clear and reuse
  for k in pairs(buffer) do buffer[k] = nil end
  -- ... use buffer ...
end
```

### Don'ts

```lua
-- Don't concatenate in loops
local s = ""
for i = 1, n do
  s = s .. i  -- O(n²) allocations!
end

-- Do this instead:
local parts = {}
for i = 1, n do
  parts[i] = tostring(i)
end
local s = table.concat(parts)

-- Don't create tables in hot loops
for i = 1, n do
  local t = {x = i}  -- Allocation every iteration!
end

-- Don't use globals without caching
for i = 1, 1000000 do
  x = math.sin(i)  -- _ENV lookup every time
end
```

---

## Version Differences

| Feature | 5.1 | 5.3 | 5.4 | LuaJIT |
|---------|-----|-----|-----|--------|
| Integers | ✗ | ✓ | ✓ | ✓ (LL) |
| Bitwise ops | ✗ | ✓ | ✓ | ✓ |
| `_ENV` | ✗ | ✓ | ✓ | Partial |
| `setfenv` | ✓ | ✗ | ✗ | ✓ |
| Generational GC | ✗ | ✗ | ✓ | ✗ |
| To-be-closed | ✗ | ✗ | ✓ | ✗ |
| FFI | ✗ | ✗ | ✗ | ✓ |
| Trace JIT | ✗ | ✗ | ✗ | ✓ |

---

## Common Patterns

### Module Template

```lua
local M = {}

local function private_helper() end

function M.public_function()
  return private_helper()
end

M.CONSTANT = 42

return M
```

### Class-like Prototype

```lua
local Class = {}
Class.__index = Class

function Class:new(value)
  return setmetatable({value = value}, self)
end

function Class:method()
  return self.value
end

return Class
```

### Iterator Pattern

```lua
local function my_iterator(t)
  local i = 0
  return function()
    i = i + 1
    return t[i]
  end
end

for value in my_iterator({1, 2, 3}) do
  print(value)
end
```

### Memoization

```lua
local function memoize(fn)
  local cache = {}
  return function(key)
    if cache[key] == nil then
      cache[key] = fn(key)
    end
    return cache[key]
  end
end
```
