# 第 43.3 阶段：Lua 包管理器

**级别**: 高级  
**描述**: 构建一个轻量级的纯 Lua 包依赖解析器。学习解析包清单、解决依赖图、处理版本约束和实现包加载——全部使用纯 Lua 完成，无需外部依赖。

## 前置知识

- Stage 06 — Modules
- Stage 27 — Memory Management
- Stage 12 — Performance

## 项目结构

```
43-toolchain/lua-package-manager/
├── README.md
├── README.zh-CN.md
├── src/
│   └── package.lua    — 包解析器核心
├── examples/
│   └── demo.lua       — 包解析演示
└── tests/
    └── resolve_test.lua  — 依赖解析测试
```

## 背景

像 luarocks、npm 和 pip 这样的包管理器通过解决版本约束和确保所有所需包可用来解决"依赖地狱"问题。本项目用纯 Lua 实现了一个简化版的包管理器，重点解决依赖解析算法。

## 实现细节

### 包解析器 (`src/package.lua`)

```lua
local Package = {}
Package.__index = Package

--- 创建一个新的包解析器。
function Package.new()
  return setmetatable({
    registry = {},     -- 包名 -> 版本列表
    resolved = {},     -- 已解析的包
    conflicts = {},    -- 检测到的冲突
  }, Package)
end

--- 在本地注册一个包。
function Package:register(name, version, dependencies)
  if not self.registry[name] then
    self.registry[name] = {}
  end
  self.registry[name][version] = {
    name = name,
    version = version,
    dependencies = dependencies or {},
  }
  return self
end

--- 解析一组请求的包及其约束。
-- 返回已解析的包表，冲突时返回 nil。
function Package:resolve(roots)
  local visiting = {}
  local function visit(name, version)
    if visiting[name] then
      table.insert(conflicts, "Cycle: " .. name)
      return nil
    end
    visiting[name] = true
    local pkg = self.registry[name][version]
    if not pkg then
      table.insert(conflicts, "Unknown package: " .. name .. "@" .. version)
      return nil
    end
    for dep_name, dep_ver in pairs(pkg.dependencies) do
      local ok = visit(dep_name, dep_ver or "latest")
      if not ok then return nil end
    end
    visiting[name] = false
    self.resolved[name] = { version = version, version_spec = version or "*" }
    return true
  end

  for name, version in pairs(roots) do
    if not visit(name, version) then return nil end
  end

  return self.resolved
end

--- 获取所有已安装的包。
function Package:list()
  local names = {}
  for name in pairs(self.resolved) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

return Package
```

### 示例 (`examples/demo.lua`)

```lua
local Package = require("package")

local pm = Package.new()
pm:register("lua-http-server", "1.0.0", { "lua-build-system": ">=1.0" })
pm:register("lua-build-system", "1.0.0", {})
pm:register("lua-build-system", "1.1.0", {})

local resolved = pm:resolve {
  ["lua-http-server"] = "1.0.0"
}

if resolved then
  print("Resolved packages:")
  for name, info in pairs(resolved) do
    print("  " .. name .. "@" .. info.version)
  end
else
  print("Resolution failed!")
end
```

## 预估时间

8–12 小时
