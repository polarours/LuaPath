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

## Advanced Patterns

### Attribute-Based Access

Use `__index` and `__newindex` to implement attribute-based access:

```lua
local function create_attrs(defaults)
  local attrs = {}
  for k, v in pairs(defaults) do
    attrs[k] = v
  end
  
  return setmetatable({}, {
    __index = function(_, k)
      return attrs[k]
    end,
    __newindex = function(_, k, v)
      if attrs[k] ~= nil then
        error("Attribute '" .. k .. "' is read-only")
      end
      rawset(_, k, v)
    end,
  })
end

local obj = create_attrs({name = "test", value = 42})
print(obj.name)  -- "test"
-- obj.name = "new"  -- Error: read-only
```

### Builder Pattern with Chaining

```lua
local function builder()
  local data = {}
  
  return setmetatable(data, {
    __call = function(_, key, value)
      data[key] = value
      return data  -- Enable chaining
    end,
  })
end

local config = builder()
config("host", "localhost")
  ("port", 8080)
  ("debug", true)

print(config.host, config.port, config.debug)
```

### Metamethod for Arithmetic Operations

```lua
local Vector = {}
Vector.__index = Vector

function Vector.new(x, y)
  return setmetatable({x = x or 0, y = y or 0}, Vector)
end

function Vector.__add(a, b)
  return Vector.new(a.x + b.x, a.y + b.y)
end

function Vector.__mul(v, scalar)
  return Vector.new(v.x * scalar, v.y * scalar)
end

function Vector:__tostring()
  return string.format("Vector(%g, %g)", self.x, self.y)
end

local v1 = Vector.new(1, 2)
local v2 = Vector.new(3, 4)
print(v1 + v2)  -- Vector(4, 6)
print(v1 * 3)   -- Vector(3, 6)
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

## Case Study: A Validator That Writes Itself

A configuration service must validate incoming records against a schema on every
request. The schema lives in a table, so the straightforward implementation walks
that table on every call. This case study asks a narrower question: if the schema
is static, can we turn it into code once at load time instead of interpreting it
forever after — and does that actually pay?

### The Reference Implementation

```lua
local function validate_generic(record, spec)
  for i = 1, #spec do
    local rule = spec[i]
    local value = record[rule.field]
    if value == nil then
      if rule.required then return false, rule.field .. " is required" end
    elseif type(value) ~= rule.type then
      return false, rule.field .. " must be a " .. rule.type
    end
  end
  return true
end
```

Every call re-derives its behaviour from the table: a loop, two branches per rule,
and a message built by concatenation.

### What Metaprogramming Changes

Build the source string from the schema, load it once, and keep the resulting
function. The generated artifact is a normal Lua function:

```lua
-- generated validator
return function(record)
  local v
  v = record["id"]
  if v == nil then return false, "id is required" end
  if v ~= nil and type(v) ~= "number" then return false, "id must be a number" end
  v = record["name"]
  if v == nil then return false, "name is required" end
  if v ~= nil and type(v) ~= "string" then return false, "name must be a string" end
  v = record["score"]
  if v ~= nil and type(v) ~= "number" then return false, "score must be a number" end
  v = record["tags"]
  if v ~= nil and type(v) ~= "table" then return false, "tags must be a table" end
  return true
end
```

Three structural differences, each doing work the reference had to redo per call:

1. **No rule loop.** The loop was unrolled at generation time.
2. **One table lookup per field**, instead of re-reading `rule.field` and `rule.type`.
3. **Messages are pre-rendered literals**, so no concatenation happens while validating.

### The Guard That Makes The Claim Meaningful

Generated code that is faster but wrong is worthless, so the example
cross-checks both implementations against a corpus of eight records — including
misshapen ones (`id` as a string, `name` as a number, `tags` as a string) — and
refuses to report any timing if they disagree:

```
Correctness: 8/8 records agree with the reference validator
             0 mismatches
```

The guard is cheap, permanent, and runs before every measurement. Keep it: it is
what stops the optimization from silently breaking correctness later.

### Measured Results

Run it yourself:

```bash
lua examples/advanced/23-schema-codegen.lua
```

Measured on this machine, 1,200,000 validation calls per path:

| Runtime | Interpreter | Ratio (reference ÷ generated) |
|---------|-------------|-------------------------------|
| Lua 5.4 | PUC | 1.62x – 1.77x |
| Lua 5.1 | PUC | 1.53x |
| LuaJIT 2.1.1791988261 | LuaJIT | 3.10x |

Two readings from those numbers:

- **Absolute times are machine-specific; trust the ratio.** The example prints
  both so you can compare against your own hardware, but the ratio is what
  transfers between machines.
- **The payoff depends on the VM.** LuaJIT gains roughly twice as much as PUC
  Lua here, because it can trace the generated function into tight machine code
  more easily than it can the table-driven loop. Generalizing from one runtime's
  number to another is the mistake this case study exists to prevent.

### When Not To Use This

Code generation is a cost, not a default. Prefer the reference implementation when:

- **The schema changes per request.** Compilation happens once per schema; if you
  recompile constantly, you have only moved the expense.
- **Records are large and validation is not on a hot path.** A 1.6x improvement on
  a 50µs operation is not worth a generated file nobody can read.
- **Readability outranks the loop.** Generated source must be dumped and
  understood during debugging; that is ongoing maintenance, not setup cost.
- **You cannot write the guard.** If the two implementations cannot be compared
  on a corpus, you have no way to tell a correct optimization from a wrong one.

```bash
# Full run with the generated source printed, then the timing block
lua examples/advanced/23-schema-codegen.lua
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

## Exercises

### Beginner (30–60 min)

1. **Dynamic Function Generator**: Write a function `make_multiplier(n)` that uses `load()` to generate and return a function that multiplies its argument by `n`.

2. **Safe Code Loader**: Create a `safe_load(code)` function that loads code in a restricted environment with only `print`, `math`, and `string` libraries.

### Intermediate (1–2 hours)

3. **Simple DSL**: Build a small DSL for defining database queries using Lua tables and metamethods. Example: `Query("users"):where("age > 18"):order_by("name")`.

4. **Code Generator**: Write a function that generates multiple similar functions from a template. For example, generate `get_name()`, `get_age()`, `get_email()` from a list of field names.

### Advanced (2–4 hours)

5. **Macro System**: Implement a simple macro system where `@macro(name, args)` is expanded at load time. Support at least one built-in macro.

6. **Performance Benchmark**: Compare the performance of static code vs. metaprogramming-generated code for a computationally intensive task. Document the overhead.

---

## Further Reading

- [Lua 5.4 Reference Manual — Section 6](https://www.lua.org/manual/5.4/manual.html#6)
- [Programming in Lua — Chapter 8: Interfacing with C](https://www.lua.org/pil/)

---

[Next Chapter: 16 — Lua Ecosystem](16-lua-ecosystem.md)
