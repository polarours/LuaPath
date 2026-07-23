# Chapter 17: Embedding Patterns

> **Phase**: Advanced  
> **Prerequisites**: Chapters 10 (Internals), 11 (C API)  
> **Time**: 10–15 hours  
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT

---

## Learning Objectives

After this chapter, you will be able to:

1. Design effective embedding architectures
2. Implement plugin systems using Lua
3. Create sandboxed environments for untrusted code
4. Handle resource management in embedded Lua
5. Build bidirectional communication between host and script

---

## Embedding Architectures

### Script Host Pattern

The host application embeds Lua and exposes a controlled API:

```c
// host.c - Simplified embedding example
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int main(void) {
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    
    // Register host API
    lua_pushcfunction(L, host_log);
    lua_setglobal(L, "host_log");
    
    // Execute script
    if (luaL_dofile(L, "script.lua") != LUA_OK) {
        fprintf(stderr, "Error: %s\n", lua_tostring(L, -1));
    }
    
    lua_close(L);
    return 0;
}
```

### Plugin Architecture

```lua
-- plugin_loader.lua
local PluginLoader = {}
PluginLoader.__index = PluginLoader

function PluginLoader.new(search_path)
  return setmetatable({path = search_path, plugins = {}}, PluginLoader)
end

function PluginLoader:load(name)
  local ok, plugin = pcall(require, self.path .. "." .. name)
  if not ok then
    return nil, "Failed to load plugin: " .. name
  end
  
  if plugin.init then
    local ok, err = pcall(plugin.init)
    if not ok then
      return nil, "Plugin init failed: " .. err
    end
  end
  
  self.plugins[name] = plugin
  return plugin
end

function PluginLoader:call(name, method, ...)
  local plugin = self.plugins[name]
  if not plugin then
    return nil, "Plugin not loaded: " .. name
  end
  if not plugin[method] then
    return nil, "Method not found: " .. method
  end
  return plugin[method](...)
end
```

---

## Sandboxing

### Creating Sandboxed Environments

```lua
-- sandbox.lua
local function create_sandbox(options)
  options = options or {}
  
  -- Base environment with safe functions
  local env = {
    print = print,
    error = error,
    assert = assert,
    type = type,
    tostring = tostring,
    tonumber = tonumber,
    pairs = pairs,
    ipairs = ipairs,
    select = select,
    unpack = unpack or table.unpack,
    pcall = pcall,
    xpcall = xpcall,
  }
  
  -- Add safe string library
  if options.string ~= false then
    env.string = string
  end
  
  -- Add safe math library
  if options.math ~= false then
    env.math = math
  end
  
  -- Add safe table library
  if options.table ~= false then
    env.table = table
  end
  
  -- Block dangerous functions
  env.os = nil
  env.io = nil
  env.debug = nil
  env.loadfile = nil
  env.dofile = nil
  
  if not options.allow_load then
    env.load = nil
    env.loadstring = nil
  end
  
  return env
end

-- Execute in sandbox
local function run_sandboxed(code, options)
  local env = create_sandbox(options)
  local fn, err = load(code, "sandbox", "t", env)
  if not fn then
    return nil, "Compile error: " .. err
  end
  
  setmetatable(env, {__index = _G})
  setfenv(fn, env)  -- Lua 5.1
  
  local ok, result = pcall(fn)
  if not ok then
    return nil, "Runtime error: " .. result
  end
  return result
end
```

### Resource Limits

```lua
-- resource_limiter.lua
local function with_limits(fn, options)
  options = options or {}
  local max_memory = options.max_memory or 1024 * 1024  -- 1MB
  local max_time = options.max_time or 5  -- 5 seconds
  
  local start_time = os.clock()
  local start_memory = collectgarbage("count") * 1024
  
  local function check_limits()
    if os.clock() - start_time > max_time then
      error("Time limit exceeded")
    end
    if collectgarbage("count") * 1024 - start_memory > max_memory then
      error("Memory limit exceeded")
    end
  end
  
  -- Set up hook for checking
  debug.sethook(check_limits, "", 1000)
  
  local ok, result = pcall(fn)
  
  debug.sethook()  -- Remove hook
  
  return ok, result
end
```

---

## Host-Script Communication

### Bidirectional API

```lua
-- host_api.lua
local HostAPI = {}
HostAPI.__index = HostAPI

function HostAPI.new()
  return setmetatable({
    callbacks = {},
    data = {},
  }, HostAPI)
end

-- Host calls script
function HostAPI:call_script(name, ...)
  local script = self.scripts[name]
  if not script then
    return nil, "Script not found: " .. name
  end
  return script(...)
end

-- Script calls host
function HostAPI:register_callback(name, fn)
  self.callbacks[name] = fn
end

function HostAPI:invoke_callback(name, ...)
  local fn = self.callbacks[name]
  if not fn then
    return nil, "Callback not found: " .. name
  end
  return fn(...)
end
```

### Event-Driven Communication

```lua
-- event_bridge.lua
local EventBridge = {}
EventBridge.__index = EventBridge

function EventBridge.new()
  return setmetatable({
    host_events = {},
    script_events = {},
  }, EventBridge)
end

function EventBridge:emit_to_host(event, data)
  -- Queue event for host to process
  self.host_events[#self.host_events + 1] = {
    event = event,
    data = data,
    time = os.clock(),
  }
end

function EventBridge:emit_to_script(event, data)
  -- Queue event for script to process
  self.script_events[#self.script_events + 1] = {
    event = event,
    data = data,
    time = os.clock(),
  }
end

function EventBridge:process_host_events(handler)
  while #self.host_events > 0 do
    local event = table.remove(self.host_events, 1)
    handler(event.event, event.data)
  end
end
```

---

## Common Pitfalls

### 1. Memory Leaks in Embedded Lua

```lua
-- BAD: Creating many short-lived objects
for i = 1, 10000 do
  local temp = {data = i}  -- GC pressure
end

-- BETTER: Reuse tables
local temp = {}
for i = 1, 10000 do
  temp.data = i
end
```

### 2. Coroutine Stack Issues

```lua
-- BAD: Deep recursion in coroutines
local function deep(n)
  if n > 1000 then return end
  deep(n + 1)  -- Stack overflow risk
end

-- BETTER: Use iterative approach
local function deep_iterative(n)
  local stack = {}
  while n > 0 do
    stack[#stack + 1] = n
    n = n - 1
  end
  return stack
end
```

### 3. Global Namespace Pollution

```lua
-- BAD: Polluting global namespace
function helper() end  -- Global!

-- BETTER: Use modules
local M = {}
function M.helper() end
return M
```

---

## Advanced Embedding Patterns

### Resource Management

Use `__gc` metamethods for automatic cleanup:

```lua
local Resource = {}
Resource.__index = Resource

function Resource.new(handle)
  return setmetatable({handle = handle, closed = false}, Resource)
end

function Resource:__gc()
  if not self.closed then
    print("[GC] Auto-closing resource: " .. tostring(self.handle))
    -- Close the resource
    self.closed = true
  end
end

function Resource:close()
  if not self.closed then
    print("Closing resource: " .. tostring(self.handle))
    self.closed = true
  end
end

-- Usage
local r = Resource.new("file.txt")
r:close()  -- Explicit close
-- If not closed, __gc will clean up
```

### Plugin Architecture

Design a plugin system with lifecycle hooks:

```lua
local PluginManager = {}
PluginManager.__index = PluginManager

function PluginManager.new()
  return setmetatable({
    plugins = {},
    hooks = {
      init = {},
      start = {},
      stop = {},
      destroy = {},
    },
  }, PluginManager)
end

function PluginManager:register(plugin)
  table.insert(self.plugins, plugin)
  if plugin.init then
    self.hooks.init[#self.hooks.init + 1] = plugin.init
  end
  if plugin.start then
    self.hooks.start[#self.hooks.start + 1] = plugin.start
  end
  if plugin.stop then
    self.hooks.stop[#self.hooks.stop + 1] = plugin.stop
  end
end

function PluginManager:run_hook(hook_name, ...)
  for _, hook in ipairs(self.hooks[hook_name] or {}) do
    hook(...)
  end
end
```

### Script Sandboxing with Limits

```lua
local function create_sandbox_with_limits(max_time, max_memory)
  local env = {
    print = print,
    error = error,
    assert = assert,
    type = type,
    tostring = tostring,
    tonumber = tonumber,
    pairs = pairs,
    ipairs = ipairs,
    pcall = pcall,
    xpcall = xpcall,
    math = math,
    string = string,
    table = table,
  }
  
  local function run_with_limits(code)
    local start_time = os.clock()
    local start_mem = collectgarbage("count")
    
    local fn, err = load(code, "sandbox", "t", env)
    if not fn then
      return nil, "Compile error: " .. err
    end
    
    -- Set up time check hook
    debug.sethook(function()
      if os.clock() - start_time > max_time then
        error("Time limit exceeded")
      end
    end, "", 1000)
    
    local ok, result = pcall(fn)
    
    -- Remove hook
    debug.sethook()
    
    -- Check memory
    local mem_used = collectgarbage("count") - start_mem
    if mem_used > max_memory then
      return nil, "Memory limit exceeded"
    end
    
    if not ok then
      return nil, "Runtime error: " .. tostring(result)
    end
    
    return result
  end
  
  return run_with_limits
end
```

### Bidirectional Communication

```lua
local function create_host_script_bridge()
  local bridge = {
    host_to_script = {},
    script_to_host = {},
  }
  
  -- Host sends message to script
  function bridge:send_to_script(msg)
    self.host_to_script[#self.host_to_script + 1] = msg
  end
  
  -- Script sends message to host
  function bridge:send_to_host(msg)
    self.script_to_host[#self.script_to_host + 1] = msg
  end
  
  -- Host retrieves messages from script
  function bridge:receive_from_script()
    return table.remove(self.script_to_host, 1)
  end
  
  -- Script retrieves messages from host
  function bridge:receive_from_host()
    return table.remove(self.host_to_script, 1)
  end
  
  return bridge
end
```

### Version Compatibility Wrapper

```lua
local function create_compat_wrapper()
  local compat = {}
  
  -- Lua 5.1 compatibility
  compat.unpack = unpack or table.unpack
  
  -- Lua 5.3+ integer support
  compat.is_integer = math.type and function(x)
    return math.type(x) == "integer"
  end or function(x)
    return x == math.floor(x)
  end
  
  -- Bitwise operations
  compat.band = bit32 and bit32.band or function(a, b)
    -- Fallback for Lua 5.1 without bit32
    local result = 0
    for i = 0, 31 do
      if a % 2 == 1 and b % 2 == 1 then
        result = result + 2^i
      end
      a = math.floor(a / 2)
      b = math.floor(b / 2)
    end
    return result
  end
  
  return compat
end
```

---

## Best Practices

1. **Design clear API boundaries** between host and script
2. **Sandbox untrusted code** with resource limits
3. **Use weak references** to prevent memory leaks
4. **Log script execution** for debugging
5. **Test error handling** paths thoroughly

---

## Key Takeaways

- Embedding architecture defines the host-script boundary
- Sandboxing protects against malicious or buggy scripts
- Resource limits prevent runaway scripts
- Bidirectional communication requires careful design
- Memory management is critical in embedded systems

---

## Exercises

### Beginner (30–60 min)

1. **Basic Sandbox**: Create a sandbox function that restricts Lua code to only `print`, `math`, and `string` libraries. Test it with code that tries to access `os.execute`.

2. **Plugin Loader**: Build a simple plugin loader that discovers and loads Lua files from a directory.

### Intermediate (1–2 hours)

3. **Resource Limiter**: Implement a function that executes Lua code with time and memory limits. Use `debug.sethook` for time checking.

4. **Event Bridge**: Create a bidirectional communication system between a host and embedded Lua scripts using event queues.

### Advanced (2–4 hours)

5. **Full Plugin System**: Build a complete plugin system with lifecycle hooks (init, start, stop, destroy), dependency management, and configuration.

6. **Security Audit Tool**: Create a tool that scans Lua code for potential security issues (file access, network calls, etc.).

---

## Further Reading

- [Lua 5.4 Reference Manual — Section 4](https://www.lua.org/manual/5.4/manual.html#4)
- [Programming in Lua — Chapter 28: Extending Lua](https://www.lua.org/pil/)

---

[Next Chapter: 18 — Security in Lua](18-security-in-lua.md)
