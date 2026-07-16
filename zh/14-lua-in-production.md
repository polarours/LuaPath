# 14 — Lua 在生产环境中的应用

> **阶段**: E（性能与生产环境设计）  
> **前置知识**: 第13章 — 模式匹配  
> **预计时间**: 2–3小时阅读 + 2–4小时练习  
> **Lua 版本**: 5.1、5.3、5.4、LuaJIT（差异已标注）

---

## 学习目标

完成本章后，你将能够：

1. **设计生产环境的 Lua 架构**，正确划分宿主/脚本边界
2. **实现沙箱机制**，安全地执行不受信任的 Lua 脚本
3. **处理可观测性** — 跨 Lua/C 边界的日志、指标和错误追踪
4. **规划版本升级策略**，应对 Lua 版本迁移
5. **预见并缓解 Lua 特有的生产环境故障模式**

---

## 部署场景

Lua 在嵌入式脚本领域表现出色：

| 领域 | 用例 | 示例 |
|--------|----------|---------|
| 游戏引擎 | 游戏逻辑、UI、Mod支持 | 魔兽世界、Roblox |
| 嵌入式系统 | 配置、自动化 | 网络设备、物联网 |
| 策略引擎 | 规则评估、访问控制 | 防火墙、API网关 |
| 数据库 | 存储过程、扩展 | Redis（EVAL）、OpenResty |
| 文本处理 | 过滤、转换 | Pandoc、Hammerspoon |

---

## 架构指南

### 1. 将宿主权限保留在 C/C++/Rust 中

```text
┌─────────────────────────────────┐
│  宿主应用 (C/C++/Rust)          │
│  - 资源管理                      │
│  - I/O 权限                      │
│  - 安全边界                      │
│  ┌───────────────────────────┐  │
│  │  Lua 脚本                  │  │
│  │  - 游戏逻辑                │  │
│  │  - 配置                    │  │
│  │  - 用户扩展                │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

宿主控制资源；Lua 脚本在边界内运行。

### 2. 暴露最小化的 API 表面

```lua
-- 好的做法：最小化 API
local API = {
  get_player = function() return player end,
  log = function(msg) host_log(msg) end,
}

-- 不好的做法：暴露所有内容
local API = {
  player = player,        -- 直接访问内部数据
  db = db_connection,     -- 数据库访问！
  os = os,                -- 完整系统访问！
}
```

### 3. 对脚本 API 进行版本管理

```lua
-- api_v1.lua
local M = {}
M.get_player = function() return player end
return M

-- api_v2.lua（增量变更）
local v1 = require("api_v1")
local M = setmetatable({}, {__index = v1})
M.get_player_stats = function() return compute_stats(player) end
return M
```

### 4. 隔离不受信任的脚本

```lua
-- Sandbox：创建受限环境
local function create_sandbox()
  local env = {
    print = print,
    string = string,
    math = math,
    table = table,
    -- 不包含 io、os、debug、package
  }
  return setmetatable(env, {__index = _G})
end
```

---

## 沙箱

### 应移除的内容

```lua
-- 对不受信任代码来说危险的全局变量
local blocked = {
  "io", "os", "debug", "package",
  "loadfile", "dofile", "require",
  "rawget", "rawset", "rawequal", "rawlen",
  "setmetatable", "getmetatable",  -- 可选：取决于使用场景
  "pcall", "xpcall", "error",     -- 可选：可能需要保留
}
```

### 资源配额

```lua
-- CPU 步骤限制
local function with_step_limit(fn, max_steps)
  local steps = 0
  debug.sethook(function()
    steps = steps + 1
    if steps > max_steps then
      error("step limit exceeded")
    end
  end, "", 1000)  -- 每 1000 条指令检查一次

  local ok, err = pcall(fn)
  debug.sethook()  -- 移除钩子
  return ok, err
end

-- 内存限制
local function with_memory_limit(fn, max_kb)
  local before = collectgarbage("count")
  local ok, err = pcall(fn)
  collectgarbage("collect")
  local after = collectgarbage("count")
  if after - before > max_kb then
    return false, "memory limit exceeded"
  end
  return ok, err
end
```

### 沙箱化执行

```lua
local function run_untrusted(code, sandbox_env, limits)
  local chunk, err = load(code, "untrusted", "t", sandbox_env)
  if not chunk then
    return nil, "parse error: " .. err
  end

  -- 应用 CPU 限制
  if limits.max_steps then
    local steps = 0
    debug.sethook(function()
      steps = steps + 1
      if steps > limits.max_steps then
        error("CPU limit exceeded")
      end
    end, "", 1000)
  end

  local ok, result = pcall(chunk)
  debug.sethook()  -- 始终清理

  if not ok then
    return nil, "runtime error: " .. tostring(result)
  end
  return result
end
```

---

## 可观测性

### 结构化日志

```lua
-- 带级别和结构化数据的日志器
local Logger = {}
Logger.__index = Logger

function Logger.new(name)
  return setmetatable({name = name}, Logger)
end

function Logger:log(level, message, data)
  local entry = {
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    level = level,
    logger = self.name,
    message = message,
    data = data,
  }
  -- 发送到宿主日志系统
  host_log(json_encode(entry))
end

function Logger:info(msg, data) self:log("info", msg, data) end
function Logger:warn(msg, data) self:log("warn", msg, data) end
function Logger:error(msg, data) self:log("error", msg, data) end
```

### 错误追踪

```lua
-- 捕获带上下文的错误
local function with_error_tracking(fn, context)
  return xpcall(fn, function(err)
    return {
      error = tostring(err),
      traceback = debug.traceback("", 2),
      context = context,
      timestamp = os.time(),
    }
  end)
end
```

### 执行指标

```lua
-- 追踪脚本执行统计
local metrics = {
  calls = 0,
  errors = 0,
  total_time = 0,
}

local function tracked_execute(fn)
  local start = os.clock()
  metrics.calls = metrics.calls + 1
  local ok, err = pcall(fn)
  local elapsed = os.clock() - start
  metrics.total_time = metrics.total_time + elapsed
  if not ok then
    metrics.errors = metrics.errors + 1
  end
  return ok, err, elapsed
end
```

---

## 版本升级策略

### 兼容性测试语料库

```lua
-- tests/compat/5_1.lua
local tests = {}
function tests.test_setfenv()
  -- 仅在 5.1 上运行
  if _VERSION ~= "Lua 5.1" then return true end
  -- 测试 setfenv 行为
  return true
end

-- tests/compat/5_3.lua
function tests.test_integers()
  if _VERSION < "Lua 5.3" then return true end
  -- 测试整数除法、位运算
  return 5 // 2 == 2
end
```

### 特性门控

```lua
-- 门控版本特定特性
local feature = {}

if _VERSION >= "Lua 5.3" then
  function feature.integer_division(a, b)
    return a // b
  end
else
  function feature.integer_division(a, b)
    return math.floor(a / b)
  end
end

if _VERSION >= "Lua 5.4" then
  function feature.close_variable(resource)
    -- 使用 <close> 属性
  end
end
```

### API 契约

```lua
-- 使用语义版本管理冻结 API
-- api/compat.lua
local M = {}

-- v1.0.0：初始 API
function M.get_player() return player end

-- v1.1.0：新增 get_player_stats（增量、非破坏性）
function M.get_player_stats() return compute_stats(player) end

-- v2.0.0：破坏性变更（主版本号升级）
-- M.get_player() 现在返回代理，而非直接引用
```

---

## 故障模式

### 1. GC 峰值

```lua
-- 问题：突发分配导致 GC 停顿
local function burst_alloc()
  local t = {}
  for i = 1, 1000000 do
    t[i] = {x = i, y = i * 2}  -- 100万张表！
  end
  return t
end

-- 缓解：将分配分散到时间上
local function gradual_alloc()
  local t = {}
  for i = 1, 1000000 do
    t[i] = {x = i, y = i * 2}
    if i % 10000 == 0 then
      collectgarbage("step", 100)  -- 小步 GC
    end
  end
  return t
end
```

### 2. 协程泄漏

```lua
-- 问题：永不结束的协程
local leaked = {}
local function spawn_leaky(fn)
  local co = coroutine.create(fn)
  leaked[#leaked + 1] = co
  -- 永不清理！
end

-- 缓解：追踪并取消
local function spawn_tracked(fn, cancel_flag)
  local co = coroutine.create(function()
    while not cancel_flag.cancelled do
      fn()
      coroutine.yield()
    end
  end)
  return co, function() cancel_flag.cancelled = true end
end
```

### 3. ABI 不匹配

```lua
-- 问题：C 模块针对错误的 Lua 版本编译
-- 解决方案：加载时进行版本检查
local function safe_require(modname)
  local ok, mod = pcall(require, modname)
  if not ok then
    error("Failed to load " .. modname .. ": " .. tostring(mod))
  end
  if mod._VERSION and mod._VERSION ~= _VERSION then
    error(modname .. " compiled for " .. mod._VERSION .. ", running " .. _VERSION)
  end
  return mod
end
```

### 4. 行为静默漂移

```lua
-- 问题：元表变更静默改变行为
local config = {debug = false}
local mt = {__index = config}

-- 稍后，在某处：
config.debug = true  -- 全局改变行为！

-- 缓解：深度冻结配置
local function freeze(t)
  return setmetatable({}, {
    __index = t,
    __newindex = function()
      error("attempt to modify frozen table")
    end,
  })
end

local frozen_config = freeze(config)
```

---

## 测试策略

### 单元测试

```lua
-- 简单测试框架
local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("PASS: " .. name)
  else
    print("FAIL: " .. name .. " - " .. tostring(err))
  end
end

test("addition", function()
  assert(1 + 1 == 2)
end)

test("string concat", function()
  assert("hello" .. " " .. "world" == "hello world")
end)
```

### 集成测试

```lua
-- 通过宿主 API 测试 Lua 脚本
local function test_script()
  local env = create_sandbox()
  local result, err = run_untrusted([[
    local player = API.get_player()
    player.hp = player.hp - 10
    return player.hp
  ]], env, {max_steps = 10000})

  assert(result == 90, "Expected 90, got " .. tostring(result))
end
```

### 基于属性的测试

```lua
-- 生成随机输入并验证属性
local function property(name, generator, check, iterations)
  iterations = iterations or 1000
  for i = 1, iterations do
    local input = generator()
    local ok, err = pcall(check, input)
    if not ok then
      error(name .. " failed on input: " .. tostring(input) .. " - " .. tostring(err))
    end
  end
  print("PASS: " .. name .. " (" .. iterations .. " iterations)")
end

property("add commutative", function()
  return {math.random(1000), math.random(1000)}
end, function(t)
  assert(t[1] + t[2] == t[2] + t[1])
end)
```

---

## 常见陷阱

### 1. 未对用户脚本进行沙箱化

```lua
-- 危险：完全访问权限
local chunk = load(user_code)
chunk()  -- 可以做任何事！

-- 安全：沙箱化
local env = create_sandbox()
local chunk = load(user_code, "user", "t", env)
chunk()
```

### 2. 忽略错误上下文

```lua
-- 不好的做法：丢失错误上下文
pcall(dangerous_function)

-- 好的做法：保留上下文
xpcall(dangerous_function, function(err)
  return debug.traceback("Error: " .. tostring(err), 2)
end)
```

### 3. 未监控 GC

```lua
-- 不好的做法：意外的 GC 停顿
-- 无监控，无警告

-- 好的做法：追踪 GC 压力
local gc_before = collectgarbage("count")
-- ... 运行脚本 ...
local gc_after = collectgarbage("count")
if gc_after - gc_before > 1000 then
  log.warn("High GC pressure", {before = gc_before, after = gc_after})
end
```

### 4. 假设确定性终结

```lua
-- 不好的做法：依赖 __gc 进行清理
local r = make_resource()
r = nil  -- 不保证立即释放！
-- __gc 可能在很久之后才运行

-- 好的做法：显式清理
local r = make_resource()
r:close()  -- 确定性清理
```

### 5. 硬编码 Lua 版本假设

```lua
-- 不好的做法：假设 5.3+ 特性
local x = 5 // 2  -- 在 5.1 上会失败

-- 好的做法：版本感知代码
local function intdiv(a, b)
  if _VERSION >= "Lua 5.3" then
    return a // b
  else
    return math.floor(a / b)
  end
end
```

---

## 最佳实践

### 1. 保持确定性路径纯净

```lua
-- 纯函数：相同输入 → 相同输出，无副作用
local function calculate_damage(attack, defense)
  return math.max(1, attack - defense)
end

-- 非纯函数：依赖外部状态
local function get_random_damage()
  return math.random(1, 100)  -- 非确定性！
end
```

### 2. 随附微基准测试

```lua
-- 在热点模块中包含基准测试
local bench = require("bench")

bench("movement_system", function()
  for i = 1, 10000 do
    movement_system(entities, 0.016)
  end
end)
```

### 3. 在内存压力下测试

```lua
-- 模拟低内存条件
local function stress_test(fn)
  -- 设置激进的 GC
  collectgarbage("setpause", 10)
  collectgarbage("setstepmul", 50)

  local ok, err = pcall(fn)

  -- 恢复默认值
  collectgarbage("setpause", 100)
  collectgarbage("setstepmul", 200)

  return ok, err
end
```

### 4. 代码审查检查清单

- [ ] 不受信任脚本路径中无 `io`/`os`
- [ ] 所有 `pcall` 结果均已检查
- [ ] 热循环中无字符串拼接
- [ ] 尽可能复用表
- [ ] 错误消息包含上下文
- [ ] 不依赖 `__gc` 进行确定性清理
- [ ] 版本特定代码通过 `_VERSION` 检查进行门控

### 5. 记录故障模式

```lua
--- 安全处理用户脚本
-- 已知故障模式：
--   - CPU 限制超出（步数计数器）
--   - 内存限制超出（GC 计数）
--   - 解析错误（无效 Lua 语法）
--   - 运行时错误（脚本 bug）
-- 恢复：返回 nil，包含 code 和 message 的错误表
local function process_script(code)
  -- ...
end
```

---

## 版本说明

### Lua 5.1

- 使用 `setfenv`/`getfenv` 进行沙箱化
- 表没有 `__gc`
- 广泛部署（许多 C 模块针对 5.1 编译）

### Lua 5.2/5.3

- 表支持 `setmetatable` 配合 `__gc`（5.2+）
- `table.pack`/`table.unpack` 处理变长参数
- 整数类型（5.3+）— 可能影响现有代码
- 5.3 中移除了 `bit32`（使用原生运算符）

### Lua 5.4

- 分代 GC — 更适合分配密集型工作负载
- `__close` 用于确定性资源清理
- `coroutine.close` 用于显式协程清理
- 从 5.3 开始的破坏性变更（参见迁移指南）

### LuaJIT

- 与 Lua 5.1 兼容（不兼容 5.3/5.4）
- FFI 用于无包装器的 C 互操作
- 可追踪代码具有出色性能
- 某些模式会破坏 JIT 追踪

---

## 知识检查

<details>
<summary>1. 沙箱应从 Lua 环境中移除什么？</summary>

至少移除：`io`、`os`、`debug`、`package`、`loadfile`、`dofile`、`require`。可选移除：`rawget`/`rawset`、`setmetatable`/`getmetatable`，取决于信任级别。
</details>

<details>
<summary>2. 如何防止生产环境中的 GC 峰值？</summary>

通过定期 `collectgarbage("step")` 将分配分散到时间上。复用表。使用分代 GC（5.4）处理分配密集型工作负载。监控 GC 压力。
</details>

<details>
<summary>3. 为什么要对 Lua 特性进行版本门控？</summary>

不同 Lua 版本有不兼容的特性（5.3+ 中的整数除法、5.4 中的 `__close`）。门控确保代码跨版本运行时不出现运行时错误。
</details>

<details>
<summary>4. 什么是宿主/脚本边界，为什么它很重要？</summary>

宿主（C/C++/Rust）控制资源和安全性。Lua 脚本在宿主设定的边界内运行。违反这一原则（例如，给脚本 `os.execute`）会带来安全风险。
</details>

<details>
<summary>5. 为什么不应依赖 <code>__gc</code> 进行清理？</summary>

GC 时机是非确定性的。对象可能立即被回收、很久之后才被回收，或者在单次会话中永远不会被回收。使用显式 `close()` 方法进行确定性清理。
</details>

---

## 关键要点

- **宿主权限**：C/C++/Rust 控制资源；Lua 在边界内运行
- **最小化 API 表面**：仅暴露脚本所需内容
- **沙箱化**：对不受信任代码移除 `io`/`os`/`debug`
- **资源配额**：CPU 步骤、内存限制、超时
- **可观测性**：结构化日志、错误追踪、执行指标
- **版本门控**：通过 `_VERSION` 检查进行特性检测
- **故障模式**：GC 峰值、协程泄漏、ABI 不匹配、行为漂移
- **测试**：单元测试、集成测试、基于属性的测试、压力测试
- **绝不依赖 `__gc`** 进行确定性清理

---

## 练习

### 初级（30–60分钟）

1. **沙箱构建器**：创建 `create_sandbox(options)`，返回受限环境。选项控制哪些库可用。

2. **错误报告器**：实现 `run_safe(code)`，执行 Lua 代码并返回包含调用栈的结构化错误报告。

3. **指标收集器**：构建一个简单的指标模块，追踪函数调用次数和执行时间。

### 中级（1–2小时）

4. **资源限制器**：实现一个基于协程的执行环境，具有 CPU 步骤限制和内存限制。

5. **版本适配器**：创建兼容层，提供跨 Lua 5.1、5.3 和 5.4 的一致 API。

6. **日志聚合器**：构建日志系统，批量发送结构化日志到宿主回调。

### 高级（2–4小时）

7. **脚本热重载**：实现开发模式系统，检测脚本变更并重新加载，无需重启宿主。

8. **生产环境监控器**：构建监控面板，追踪 Lua 脚本健康状况：执行时间、错误率、GC 压力、内存使用。

---

## 示例代码

本章可运行的示例：
- `examples/advanced/02-sandbox-environment.lua` — 沙箱化执行
- `examples/advanced/03-object-pool.lua` — 生产级对象复用

---

## 延伸阅读

- [Lua 5.4 参考手册](https://www.lua.org/manual/5.4/)
- [Programming in Lua（第4版）](https://www.lua.org/pil/)
- [Lua in Practice](https://www.amazon.com/Lua-Practice-Ricardo-Fabricio-Ordines/dp/1784394594)
- [Game AI Pro — Lua Scripting](https://www.gameaipro.com/)