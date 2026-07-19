# Chapter 15: Advanced Metaprogramming

> **Phase**: Advanced  
> **Prerequisites**: Chapters 05 (Metatables), 06 (Modules)  
> **Time**: 8–12 hours  
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT

---

## Learning Objectives

After this chapter, you will be able to:

1. Use `load()` and `loadstring()` for dynamic code generation
2. Implement custom DSLs using Lua's metaprogramming facilities
3. Generate code at runtime for performance optimization
4. Build macro-like systems using tables and functions
5. Understand the trade-offs of metaprogramming in production

---

## Dynamic Code Loading

### The `load` Function

`load` compiles a string into a function without executing it:

```lua
-- Compile and execute dynamically
local code = 'return 1 + 2'
local fn, err = load(code)
if fn then
  local result = fn()
  print(result)  -- 3
else
  print("Compile error: " .. err)
end
```

### Environment Control

`load` can set the environment for the loaded code:

```lua
-- Restricted environment
local restricted = {print = print, math = math}
local fn = load("return math.sqrt(16)", "chunk", "t", restricted)
print(fn())  -- 4.0

-- Code cannot access globals outside the environment
local fn2 = load("return os.execute('rm -rf /')", "chunk", "t", restricted)
-- fn2 would fail if called (os is not in restricted)
```

### `loadstring` (Lua 5.1)

In Lua 5.1, use `loadstring` instead of `load`:

```lua
-- Lua 5.1
local fn = loadstring("return 42")
print(fn())  -- 42

-- Lua 5.2+
local fn = load and load("return 42") or loadstring("return 42")
```

---

## Code Generation Patterns

### Template-Based Code Generation

Generate Lua code from templates:

```lua
local function generate_function(name, params, body)
  local param_str = table.concat(params, ", ")
  local code = string.format(
    "local function %s(%s)\n%s\nend",
    name, param_str, body
  )
  return load(code)()
end

-- Generate a function at runtime
local double = generate_function("double", {"x"}, "return x * 2")
print(double(5))  -- 10
```

### Table-Driven Code Generation

Use tables to drive code generation:

```lua
local function generate_accessors(fields)
  local code = "local M = {}\n"
  for _, field in ipairs(fields) do
    code = code .. string.format(
      "function M.get_%s(self) return self._%s end\n",
      field, field
    )
    code = code .. string.format(
      "function M.set_%s(self, v) self._%s = v end\n",
      field, field
    )
  end
  code = code .. "return M"
  return load(code)()
end

local person_accessors = generate_accessors({"name", "age", "email"})
local p = {_name = "Lua", _age = 30, _email = "lua@example.com"}
print(person_accessors.get_name(p))  -- "Lua"
```

---

## DSL Construction

### Internal DSLs

Lua's flexible syntax enables readable internal DSLs:

```lua
-- SQL-like query DSL
local function query(table_name)
  return setmetatable({from = table_name}, {
    __call = function(self, conditions)
      local where = ""
      if conditions then
        local parts = {}
        for k, v in pairs(conditions) do
          parts[#parts + 1] = string.format("%s = '%s'", k, v)
        end
        where = " WHERE " .. table.concat(parts, " AND ")
      end
      return string.format("SELECT * FROM %s%s", self.from, where)
    end
  })
end

print(query("users")({status = "active"}))
-- "SELECT * FROM users WHERE status = 'active'"
```

### Builder Pattern DSL

```lua
local function create_builder()
  local builder = {}
  local data = {}
  
  function builder:set(key, value)
    data[key] = value
    return builder  -- Enable chaining
  end
  
  function builder:build()
    local result = {}
    for k, v in pairs(data) do
      result[k] = v
    end
    return result
  end
  
  return builder
end

local config = create_builder()
  :set("host", "localhost")
  :set("port", 8080)
  :set("debug", true)
  :build()

print(config.host, config.port)
```

---

## Runtime Code Optimization

### Precomputation

Compute values at load time instead of runtime:

```lua
-- Precompute lookup table
local sin_table = {}
for i = 0, 360 do
  sin_table[i] = math.sin(math.rad(i))
end

-- Fast lookup at runtime
local function fast_sin(degrees)
  return sin_table[degrees % 360]
end
```

### JIT-Friendly Patterns

Write code that LuaJIT can optimize:

```lua
-- BAD: Polymorphic (different types in same trace)
local function process(x)
  if type(x) == "number" then
    return x * 2
  else
    return tostring(x)
  end
end

-- GOOD: Monomorphic (same types)
local function process_number(x)
  return x * 2
end

local function process_string(x)
  return tostring(x)
end
```

---

## Common Pitfalls

### 1. Security Risks with `load`

```lua
-- DANGEROUS: Never load untrusted code
local user_input = io.read()
local fn = load(user_input)  -- Could execute anything!

-- SAFE: Use restricted environment
local safe_env = {print = print, math = math}
local fn = load(user_code, "user", "t", safe_env)
```

### 2. Debug Information Loss

```lua
-- Code generated at runtime lacks debug info
local fn = load("return 1/0")  -- No line numbers in errors
fn()  -- Error message lacks context

-- Better: include debug info
local fn = load("return 1/0", "=generated", "t")
```

### 3. Performance Overhead

```lua
-- Metaprogramming adds runtime overhead
local t = {}
setmetatable(t, {
  __index = function(_, k)
    return compute_value(k)  -- Called on every access
  end
})
```

---

## Best Practices

1. **Prefer static code** when performance is critical
2. **Use metaprogramming for DSLs** and configuration, not core logic
3. **Always sandbox `load`** when handling untrusted code
4. **Document generated code** for maintainability
5. **Profile before optimizing** with metaprogramming

---

## Key Takeaways

- `load()` enables dynamic code generation but requires careful security
- Table-driven patterns generate code at load time for runtime efficiency
- Internal DSLs leverage Lua's flexible syntax for readable APIs
- Metaprogramming is powerful but adds complexity and debugging difficulty
- Always balance power against maintainability

---

## Further Reading

- [Lua 5.4 Reference Manual — Section 6](https://www.lua.org/manual/5.4/manual.html#6)
- [Programming in Lua — Chapter 8: Interfacing with C](https://www.lua.org/pil/)

---

[Next Chapter: 16 — Lua Ecosystem](16-lua-ecosystem.md)
