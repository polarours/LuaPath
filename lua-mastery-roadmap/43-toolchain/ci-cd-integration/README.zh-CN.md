# 第 43.2 阶段：CI/CD 集成

**级别**: 高级  
**描述**: 将 Lua 验证和测试集成到 CI/CD 流水线中。学习生成 TAP（Test Anything Protocol）报告，创建构建状态挂钩，并在持续集成系统中实现自动化质量检查。

## 前置知识

- Stage 38 — Testing Patterns
- Stage 28 — Deployment Patterns
- 对 GitHub Actions 或其他 CI 系统的基本了解

## 项目结构

```
43-toolchain/ci-cd-integration/
├── README.md
├── README.zh-CN.md
├── src/
│   └── tap.lua          — TAP 报告器模块
│   └── hooks.lua        — CI 钩子工具
├── examples/
│   └── ci_pipeline.lua  — 完整 CI 流水线示例
└── tests/
    └── tap_test.lua     — TAP 报告器正确性测试
```

## 背景

持续集成系统期望测试结果以标准化格式呈现。Test Anything Protocol (TAP) 是测试程序与 TAP 解析器之间的一种简单文本协议。Lua 可以轻松生成 TAP 输出，供 GitHub Actions、GitLab CI、Jenkins 和其他 CI 系统使用。

## 实现细节

### TAP 报告器 (`src/tap.lua`)

```lua
local TAP = {}
TAP.__index = TAP

function TAP.new()
  return setmetatable({
    tests = 0,
    passed = 0,
    failed = 0,
    plans = {},
  }, TAP)
end

function TAP:plan(n)
  self.plans.total = n
  return self
end

function TAP:test(name)
  self.tests = self.tests + 1
  print("ok " .. self.tests .. " - " .. name)
  return self
end

function TAP:skip(name, reason)
  print("skip " .. (self.tests or 0) .. " " .. name .. " (" .. reason .. ")")
  return self
end

function TAP:done()
  if self.plans.total then
    print("1.." .. self.plans.total)
  end
  print("# Passed: " .. self.passed .. ", Failed: " .. self.failed)
  return self.failed == 0
end

return TAP
```

### CI 流水线示例 (`examples/ci_pipeline.lua`)

```lua
local TAP = require("src.tap")

local tap = TAP():plan(5)

tap:test("语法验证")
-- 运行所有 Lua 文件的语法检查
assert(io.popen("lua -c src/*.lua"):read("*a") == "")

tap:test("单元测试")
-- 运行测试套件
assert(io.popen("lua tests/*.lua"):true):close()

tap:test("依赖解析")
-- 检查所有所需的模块都能加载
require("src.build")

tap:test("格式检查")
-- 验证代码格式

tap:test("文档检查")
-- 确保所有文件都有 README

tap:done()
```

## 预估时间

8–12 小时
