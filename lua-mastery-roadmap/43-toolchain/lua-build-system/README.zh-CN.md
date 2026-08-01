# 第 43.1 阶段：Lua 构建系统

**级别**: 高级  
**描述**: 使用 Lua 元表和依赖图构建基于任务的构建系统。学习编写可以按依赖顺序执行的 Lua 任务，支持增量构建和缓存功能。

## 前置知识

- Stage 05 — Metatables
- Stage 03 — Functions (closures)
- Stage 12 — Performance

## 项目结构

```
43-toolchain/lua-build-system/
├── README.md
├── README.zh-CN.md
├── src/
│   └── build.lua          — 核心构建系统实现
├── examples/
│   └── simple.lua         — 示例构建脚本
└── tests/
    └── build_test.lua     — 构建系统正确性测试
```

## 实现细节

构建系统应支持：

1. **任务定义** — 使用元表定义带依赖的任务
2. **依赖解析** — 任务依赖的拓扑排序
3. **增量构建** — 跳过输入未更改的任务
4. **缓存** — 存储带时间戳的任务输出

### 核心模块 (`src/build.lua`)

```lua
local Build = {}
Build.__index = Build

function Build.new()
  return setmetatable({
    tasks = {},
    executed = {},
    cache = {},
  }, Build)
end

function Build:task(name, dependencies, fn)
  self.tasks[name] = {
    name = name,
    dependencies = dependencies or {},
    fn = fn,
    timestamp = os.time(),
    output = nil,
  }
  return self
end

function Build:resolve_order(name)
  -- 拓扑排序，带环检测
  local order = {}
  local visiting = {}
  local visited = {}

  local function visit(name)
    if visiting[name] then error("检测到循环") end
    if visited[name] then return end
    visiting[name] = true
    for _, dep in ipairs(self.tasks[name].dependencies or {}) do
      visit(dep)
    end
    visited[name] = true
    table.insert(order, name)
    visiting[name] = nil
  end

  for name in pairs(self.tasks) do
    visit(name)
  end

  return order
end

function Build:execute(name)
  local task = self.tasks[name]
  if not task then error("未知任务: " .. name) end

  -- 检查是否需要重新执行
  local cached = self.cache[name]
  if cached then
    -- 简单缓存检查
  end

  -- 先执行依赖
  for _, dep in ipairs(task.dependencies or {}) do
    self:execute(dep)
  end

  -- 执行任务
  local ok, result = pcall(task.fn, self)
  if not ok then error("任务 " .. name .. " 失败: " .. result) end
  task.output = result
  self.cache[name] = { time = os.time(), output = result }
  return result
end

return Build
```

### 示例 (`examples/simple.lua`)

```lua
local Build = require("src.build")

local b = Build.new()

b:task("clean", {}, function()
  print("Cleaning...")
  return true
end)

b:task("compile", {"clean"}, function()
  print("Compiling...")
  return { files = {"main.o"} }
end)

b:task("link", {"compile"}, function()
  print("Linking...")
  return { exe = "app" }
end)

print("Result: " .. b:execute("link")[1])
```

## 预估时间

8–12 小时
