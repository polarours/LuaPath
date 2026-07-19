# 第17章：嵌入模式

> **阶段**：高级  
> **前置章节**：第10章（内部机制）、第11章（C API）  
> **时间**：10–15小时  
> **Lua 版本**：5.1、5.3、5.4、LuaJIT

---

## 学习目标

学完本章后，你将能够：

1. 设计有效的嵌入架构
2. 使用 Lua 实现插件系统
3. 为不受信任的代码创建沙箱环境
4. 在嵌入式 Lua 中处理资源管理
5. 构建主机和脚本之间的双向通信

---

## 嵌入架构

### 脚本主机模式

宿主应用嵌入 Lua 并暴露受控的 API：

```c
// host.c - 简化的嵌入示例
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int main(void) {
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    
    // 注册主机 API
    lua_pushcfunction(L, host_log);
    lua_setglobal(L, "host_log");
    
    // 执行脚本
    if (luaL_dofile(L, "script.lua") != LUA_OK) {
        fprintf(stderr, "Error: %s\n", lua_tostring(L, -1));
    }
    
    lua_close(L);
    return 0;
}
```

### 插件架构

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

## 沙箱

### 创建沙箱环境

```lua
-- sandbox.lua
local function create_sandbox(options)
  options = options or {}
  
  -- 基础环境，包含安全函数
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
  
  -- 添加安全的 string 库
  if options.string ~= false then
    env.string = string
  end
  
  -- 添加安全的 math 库
  if options.math ~= false then
    env.math = math
  end
  
  -- 添加安全的 table 库
  if options.table ~= false then
    env.table = table
  end
  
  -- 阻止危险函数
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

-- 在沙箱中执行
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

### 资源限制

```lua
-- resource_limiter.lua
local function with_limits(fn, options)
  options = options or {}
  local max_memory = options.max_memory or 1024 * 1024  -- 1MB
  local max_time = options.max_time or 5  -- 5 秒
  
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
  
  -- 设置钩子检查限制
  debug.sethook(check_limits, "", 1000)
  
  local ok, result = pcall(fn)
  
  debug.sethook()  -- 移除钩子
  
  return ok, result
end
```

---

## 主机-脚本通信

### 双向 API

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

-- 主机调用脚本
function HostAPI:call_script(name, ...)
  local script = self.scripts[name]
  if not script then
    return nil, "Script not found: " .. name
  end
  return script(...)
end

-- 脚本调用主机
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

### 事件驱动通信

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
  -- 将事件排队供主机处理
  self.host_events[#self.host_events + 1] = {
    event = event,
    data = data,
    time = os.clock(),
  }
end

function EventBridge:emit_to_script(event, data)
  -- 将事件排队供脚本处理
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

## 常见陷阱

### 1. 嵌入式 Lua 中的内存泄漏

```lua
-- 差：创建许多短生命周期对象
for i = 1, 10000 do
  local temp = {data = i}  -- GC 压力
end

-- 更好：复用 table
local temp = {}
for i = 1, 10000 do
  temp.data = i
end
```

### 2. 协程栈问题

```lua
-- 差：协程中的深度递归
local function deep(n)
  if n > 1000 then return end
  deep(n + 1)  -- 栈溢出风险
end

-- 更好：使用迭代方法
local function deep_iterative(n)
  local stack = {}
  while n > 0 do
    stack[#stack + 1] = n
    n = n - 1
  end
  return stack
end
```

### 3. 全局命名空间污染

```lua
-- 差：污染全局命名空间
function helper() end  -- 全局！

-- 更好：使用模块
local M = {}
function M.helper() end
return M
```

---

## 最佳实践

1. **设计清晰的 API 边界**，主机和脚本之间
2. **对不受信任的代码进行沙箱处理**，设置资源限制
3. **使用弱引用**防止内存泄漏
4. **记录脚本执行**以便调试
5. **彻底测试错误处理**路径

---

## 核心要点

- 嵌入架构定义了主机-脚本边界
- 沙箱保护免受恶意或有缺陷的脚本影响
- 资源限制防止脚本失控
- 双向通信需要仔细设计
- 内存管理在嵌入式系统中至关重要

---

## 延伸阅读

- [Lua 5.4 参考手册 — 第4节](https://www.lua.org/manual/5.4/manual.html#4)
- [Lua 程序设计 — 第28章：扩展 Lua](https://www.lua.org/pil/)

---

[下一章：18 — Lua 中的安全性](18-security-in-lua.md)
