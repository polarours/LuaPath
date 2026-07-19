# Chapter 18: Security in Lua

> **Phase**: Advanced  
> **Prerequisites**: Chapters 06 (Modules), 17 (Embedding Patterns)  
> **Time**: 8–12 hours  
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT

---

## Learning Objectives

After this chapter, you will be able to:

1. Identify security risks in Lua applications
2. Implement secure coding practices
3. Design secure plugin architectures
4. Handle untrusted input safely
5. Apply security best practices in production

---

## Common Security Risks

### Code Injection

```lua
-- DANGEROUS: Executing user input
local user_input = io.read()
local fn = load(user_input)  -- Could execute anything!
fn()

-- SAFE: Validate and restrict
local function safe_execute(code)
  -- Validate code doesn't contain dangerous patterns
  if code:match("os%.") or code:match("io%.") then
    return nil, "Dangerous code detected"
  end
  
  local env = {print = print, math = math}
  local fn = load(code, "user", "t", env)
  if not fn then
    return nil, "Invalid code"
  end
  
  return fn()
end
```

### Path Traversal

```lua
-- DANGEROUS: No path validation
local function read_file(filename)
  local f = io.open(filename, "r")
  if f then
    local content = f:read("*a")
    f:close()
    return content
  end
end

-- SAFE: Validate path
local function safe_read_file(filename, allowed_dirs)
  -- Check for path traversal
  if filename:match("%.%.") or filename:match("^/") then
    return nil, "Invalid path"
  end
  
  -- Check if path is in allowed directories
  local allowed = false
  for _, dir in ipairs(allowed_dirs) do
    if filename:sub(1, #dir) == dir then
      allowed = true
      break
    end
  end
  
  if not allowed then
    return nil, "Access denied"
  end
  
  local f = io.open(filename, "r")
  if f then
    local content = f:read("*a")
    f:close()
    return content
  end
  return nil, "File not found"
end
```

### Integer Overflow

```lua
-- DANGEROUS: Assuming integer bounds
local function calculate_hash(data)
  local hash = 0
  for i = 1, #data do
    hash = (hash * 31 + data:byte(i)) % 2^32
  end
  return hash
end

-- SAFE: Use explicit bounds checking
local function safe_hash(data)
  local hash = 0
  for i = 1, #data do
    hash = (hash * 31 + data:byte(i))
    if hash > 2^52 then
      hash = hash % 2^52  -- Prevent precision loss
    end
  end
  return hash
end
```

---

## Secure Coding Practices

### Input Validation

```lua
-- validator.lua
local Validator = {}
Validator.__index = Validator

function Validator.new()
  return setmetatable({rules = {}}, Validator)
end

function Validator:add_rule(name, fn)
  self.rules[name] = fn
  return self
end

function Validator:validate(data)
  local errors = {}
  for name, rule in pairs(self.rules) do
    local ok, err = pcall(rule, data)
    if not ok then
      errors[#errors + 1] = {rule = name, error = err}
    end
  end
  return #errors == 0, errors
end

-- Usage
local validator = Validator.new()
  :add_rule("type", function(data)
    assert(type(data) == "table", "Data must be a table")
  end)
  :add_rule("required_fields", function(data)
    assert(data.name, "Name is required")
    assert(data.email, "Email is required")
  end)

local ok, errors = validator:validate({name = "Lua"})
-- ok = false, errors = [{rule = "required_fields", error = "Email is required"}]
```

### Parameter Sanitization

```lua
-- sanitizer.lua
local function sanitize_string(input)
  if type(input) ~= "string" then
    return nil, "Input must be a string"
  end
  
  -- Remove null bytes
  input = input:gsub("%z", "")
  
  -- Limit length
  if #input > 10000 then
    input = input:sub(1, 10000)
  end
  
  -- Escape special characters for display
  input = input:gsub("&", "&amp;")
  input = input:gsub("<", "&lt;")
  input = input:gsub(">", "&gt;")
  
  return input
end

local function sanitize_number(input)
  local num = tonumber(input)
  if not num then
    return nil, "Invalid number"
  end
  
  -- Check for reasonable bounds
  if num > 2^52 or num < -(2^52) then
    return nil, "Number out of safe range"
  end
  
  return num
end
```

### Secure Random Generation

```lua
-- secure_random.lua
local function secure_random(min, max)
  -- Use OS-provided entropy
  local handle = io.popen("od -An -tu4 -N4 /dev/urandom")
  if handle then
    local random_str = handle:read("*a")
    handle:close()
    
    local random_num = tonumber(random_str)
    if random_num then
      return min + (random_num % (max - min + 1))
    end
  end
  
  -- Fallback to math.random (less secure)
  math.randomseed(os.time() + os.clock() * 1000)
  return math.random(min, max)
end
```

---

## Secure Plugin Architecture

### Plugin Sandboxing

```lua
-- secure_plugin_loader.lua
local function load_plugin_sandboxed(plugin_code, api)
  -- Create restricted environment
  local env = {
    -- Provide only safe APIs
    print = api.print or print,
    error = error,
    assert = assert,
    type = type,
    tostring = tostring,
    tonumber = tonumber,
    pairs = pairs,
    ipairs = ipairs,
    pcall = pcall,
    xpcall = xpcall,
  }
  
  -- Add plugin-specific API
  if api then
    for k, v in pairs(api) do
      env[k] = v
    end
  end
  
  -- Remove dangerous globals
  env.os = nil
  env.io = nil
  env.debug = nil
  env.load = nil
  env.loadfile = nil
  env.dofile = nil
  env.rawset = nil
  env.rawget = nil
  env.rawequal = nil
  env.setmetatable = nil
  env.getmetatable = nil
  
  -- Compile plugin code
  local fn, err = load(plugin_code, "plugin", "t", env)
  if not fn then
    return nil, "Plugin compile error: " .. err
  end
  
  -- Set up environment
  setmetatable(env, {__index = _G})
  
  -- Execute plugin
  local ok, result = pcall(fn)
  if not ok then
    return nil, "Plugin runtime error: " .. result
  end
  
  return result
end
```

### Permission System

```lua
-- permission_system.lua
local PermissionSystem = {}
PermissionSystem.__index = PermissionSystem

function PermissionSystem.new()
  return setmetatable({
    permissions = {},
    grants = {},
  }, PermissionSystem)
end

function PermissionSystem:grant(plugin, permission)
  if not self.grants[plugin] then
    self.grants[plugin] = {}
  end
  self.grants[plugin][permission] = true
end

function PermissionSystem:check(plugin, permission)
  return self.grants[plugin] and self.grants[plugin][permission]
end

function PermissionSystem:create_proxy(plugin, allowed_permissions)
  local proxy = {}
  local mt = {}
  
  mt.__index = function(_, key)
    if not self:check(plugin, key) then
      error("Permission denied: " .. key)
    end
    return _G[key]
  end
  
  mt.__newindex = function(_, key, value)
    if not self:check(plugin, key) then
      error("Permission denied: " .. key)
    end
    rawset(_, key, value)
  end
  
  return setmetatable(proxy, mt)
end
```

---

## Common Pitfalls

### 1. Trusting User Input

```lua
-- BAD: No validation
local name = input.name
execute_query("SELECT * FROM users WHERE name = '" .. name .. "'")

-- SAFE: Parameterized queries
local function safe_query(name)
  -- Validate input
  if type(name) ~= "string" then
    return nil, "Invalid name"
  end
  
  -- Use parameterized query
  return db.query("SELECT * FROM users WHERE name = ?", name)
end
```

### 2. Exposing Internal State

```lua
-- BAD: Returning internal table
local function get_config()
  return config  -- Exposes entire config!
end

-- SAFE: Return copy or specific values
local function get_config()
  return {
    host = config.host,
    port = config.port,
    -- Don't expose password, keys, etc.
  }
end
```

### 3. Weak Error Messages

```lua
-- BAD: Revealing internal details
error("Database connection failed at line 42 in module.lua")

-- SAFE: Generic error with logging
log.error("Database connection failed", {module = "db", line = 42})
error("Service unavailable")
```

---

## Best Practices

1. **Validate all input** at system boundaries
2. **Use parameterized queries** for database access
3. **Implement least privilege** for plugins
4. **Log security events** for auditing
5. **Regularly update dependencies**

---

## Key Takeaways

- Input validation is the first line of defense
- Sandboxing protects against untrusted code
- Permission systems limit plugin capabilities
- Error messages should not reveal internals
- Security requires defense in depth

---

## Further Reading

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Lua Security Considerations](https://www.lua.org/pil/contents.html)

---

[Back to README](README.md)
