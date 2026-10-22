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
  
  -- 四参数的 load(chunk, chunkname, mode, env) 从 5.2 起才有；在
  -- 5.1（以及作为 5.1 衍生物的 LuaJIT）上，等价写法是
  -- loadstring() 配合 setfenv()。
  local fn, err
  if loadstring then
    fn, err = loadstring(code, "sandbox")
    if fn then setfenv(fn, env) end
  else
    fn, err = load(code, "sandbox", "t", env)
  end
  if not fn then
    return nil, "Compile error: " .. err
  end
  
  -- 这里不能有 __index = _G 回退：create_sandbox() 已经把脚本可能用到的
  -- 全局函数都放进了 env。回退到真实的全局环境会破坏沙箱——查找 `os`
  -- 时 env 中没有命中，接着就会通过 __index 解析到 _G.os，于是被
  -- 排除的名字又能访问到了。
  
  local ok, result = pcall(fn)
  if not ok then
    return nil, "Runtime error: " .. result
  end
  return result
end
```

> **Lua 5.2 说明**：四参数的 load() 是 Lua 5.2 引入的；在 Lua 5.1 上请用 loadstring() 配合 setfenv()。

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
-- 差：深度递归——协程体同样占用 C 栈
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

## 高级嵌入模式

### 资源管理

用 `__gc` 元方法实现自动清理：

```lua
local Resource = {}
Resource.__index = Resource

function Resource.new(handle)
  return setmetatable({handle = handle, closed = false}, Resource)
end

function Resource:__gc()
  if not self.closed then
    print("[GC] Auto-closing resource: " .. tostring(self.handle))
    -- 关闭资源
    self.closed = true
  end
end

function Resource:close()
  if not self.closed then
    print("Closing resource: " .. tostring(self.handle))
    self.closed = true
  end
end

-- 用法
local r = Resource.new("file.txt")
r:close()  -- 显式关闭
-- 如果没有关闭，__gc 会负责清理
```

### 插件架构

设计一个带生命周期钩子的插件系统：

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

### 带限制的脚本沙箱

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
    
    -- 四参数的 load(chunk, chunkname, mode, env) 从 5.2 起才有；在
    -- 5.1（以及作为 5.1 衍生物的 LuaJIT）上，等价写法是
    -- loadstring() 配合 setfenv()。
    local fn, err
    if loadstring then
      fn, err = loadstring(code, "sandbox")
      if fn then setfenv(fn, env) end
    else
      fn, err = load(code, "sandbox", "t", env)
    end
    if not fn then
      return nil, "Compile error: " .. err
    end
    
    -- 设置时间检查钩子
    debug.sethook(function()
      if os.clock() - start_time > max_time then
        error("Time limit exceeded")
      end
    end, "", 1000)
    
    local ok, result = pcall(fn)
    
    -- 移除钩子
    debug.sethook()
    
    -- 检查内存
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

> **Lua 5.2 说明**：四参数的 load() 是 Lua 5.2 引入的；在 Lua 5.1 上请用 loadstring() 配合 setfenv()。

### 双向通信

```lua
local function create_host_script_bridge()
  local bridge = {
    host_to_script = {},
    script_to_host = {},
  }
  
  -- 主机向脚本发送消息
  function bridge:send_to_script(msg)
    self.host_to_script[#self.host_to_script + 1] = msg
  end
  
  -- 脚本向主机发送消息
  function bridge:send_to_host(msg)
    self.script_to_host[#self.script_to_host + 1] = msg
  end
  
  -- 主机取出脚本发来的消息
  function bridge:receive_from_script()
    return table.remove(self.script_to_host, 1)
  end
  
  -- 脚本取自主机发来的消息
  function bridge:receive_from_host()
    return table.remove(self.host_to_script, 1)
  end
  
  return bridge
end
```

### 版本兼容性包装器

```lua
local function create_compat_wrapper()
  local compat = {}
  
  -- Lua 5.1 兼容性
  compat.unpack = unpack or table.unpack
  
  -- Lua 5.3+ 整数支持
  compat.is_integer = math.type and function(x)
    return math.type(x) == "integer"
  end or function(x)
    return x == math.floor(x)
  end
  
  -- 位运算
  compat.band = bit32 and bit32.band or function(a, b)
    -- 没有 bit32 时的 Lua 5.1 兜底实现
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

## 案例研究：你的沙箱真的挡住了什么吗？

Allow-list 沙箱给人一种安全感：你列出了脚本能用的东西，其余的都拦住了。但"我没有列出
`os`"不等于"恶意脚本接触不到 `os`"。本案例研究把四类已知逃逸手法分别投给两种设计，
数一数每种设计真正挡住了几条。

### 两种设计

**朴素**设计是大多数人写的那种：一张允许的全局变量表，没有任何元表护栏。

```lua
local function build_naive_sandbox(allow)
  local env = {}
  for name in pairs(allow) do env[name] = _G[name] end
  return env
end
```

**加固**设计多加了两样很小的东西：一个拒绝新全局变量的 `__newindex` 元表，以及一个
显式过滤器，即使命中 `debug` 也要把它删掉。

```lua
setmetatable(env, {
  __newindex = function(_, k, _)
    error("write to new global " .. tostring(k) .. " not permitted", 2)
  end,
})
```

### 逃逸手法

```lua
local attempts = {
  { name = "1. 读取 _G.os",   code = 'local os = _G.os return os ~= nil and "LEAKED" or "BLOCKED"' },
  { name = "2. pcall(require)", code = 'local ok, v = pcall(require, "cjson") return type(v)' },
  { name = "3. 写入新全局",     code = 'new_global = 42 return "WROTE"' },
  { name = "4. debug.getinfo",  code = 'local ok = pcall(function() return debug.getinfo() end) return ok' },
}
```

跑一下：

```bash
lua examples/advanced/25-sandbox-escape.lua
```

已在 Lua 5.4、Lua 5.1 和 LuaJIT 2.1 上验证，全部退出码 0：

```
naive    : 3/4 escape attempts blocked
hardened : 4/4 escape attempts blocked
```

### 如何读这个结果

两种设计在第 1、2、4 条上结论一致——这些仅靠 allow-list 就挡住了。真正拉开差距的是
**第 3 条**：朴素的 env 会悄无声息地接受 `new_global = 42`，因为一张普通 table 对
新键没有任何态度。`__newindex` 护栏把这次写入变成一个错误，被 `pcall` 边界捕获。

这就是实际结论：allow-list 挡住的是你**列了**的那些；元表挡住的是你**忘了**的那些。
忘了是最常见的失败模式，所以元表值得加。

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

## 练习

### 初级（30–60 分钟）

1. **基础沙箱**：创建一个沙箱函数，将 Lua 代码限制为仅 `print`、`math` 和 `string` 库。测试它是否阻止访问 `os.execute`。

2. **插件加载器**：构建一个简单的插件加载器，从目录中发现并加载 Lua 文件。

### 中级（1–2 小时）

3. **资源限制器**：实现一个函数，使用 `debug.sethook` 进行时间检查，以时间和内存限制执行 Lua 代码。

4. **事件桥接**：创建一个使用事件队列的主机和嵌入式 Lua 脚本之间的双向通信系统。

### 高级（2–4 小时）

5. **完整插件系统**：构建一个完整的插件系统，包含生命周期钩子（init、start、stop、destroy）、依赖管理和配置。

6. **安全审计工具**：创建一个扫描 Lua 代码潜在安全问题（文件访问、网络调用等）的工具。

---

## 示例代码

本章可运行示例：
- `examples/advanced/21-sandbox-demo.lua` — 受限环境执行
- `examples/advanced/25-sandbox-escape.lua` — 四种逃逸手法对比两种设计

---

## 延伸阅读

- [Lua 5.4 参考手册 — 第4节](https://www.lua.org/manual/5.4/manual.html#4)
- [Lua 程序设计 — 第28章：扩展 Lua](https://www.lua.org/pil/)

---

[下一章：18 — Lua 中的安全性](18-security-in-lua.md)
