# Lua 测试策略

> **阶段**: 跨领域
> **前置知识**: 第 3 章 — 函数, 第 7 章 — 错误处理
> **预计时间**: 2–3 小时
> **适用版本**: 5.1, 5.3, 5.4, LuaJIT

---

## 为什么要测试 Lua?

Lua 的动态特性和简洁语法使它非常适合测试。Lua 快速编写代码的特性——无需模板、一等函数、灵活的 table——也让测试代码保持简洁和聚焦。Lua 的 `pcall` 使错误隔离变得毫不费力,而其解释执行特性意味着写完代码后无需编译即可运行测试。

---

## 测试策略

成熟的 Lua 测试方法覆盖三个层次:

1. **单元测试** — 在隔离环境中测试独立函数
2. **集成测试** — 测试组件之间的协作
3. **属性测试** — 在随机输入下验证不变量

---

## 使用断言进行单元测试

最简单的单元测试方法使用 Lua 内置的 `assert`:

```lua
-- math_utils.lua
local function add(a, b) return a + b end
local function safe_div(a, b)
  if b == 0 then return nil, "division by zero" end
  return a / b
end
return { add = add, safe_div = safe_div }
```

```lua
-- math_utils_test.lua
local math_utils = require("math_utils")

local function assert_eq(actual, expected, msg)
  assert(actual == expected, string.format(
    "%s: got %s, expected %s", msg, tostring(actual), tostring(expected)
  ))
end

-- 测试 add
assert_eq(math_utils.add(2, 3), 5, "add positive")
assert_eq(math_utils.add(-1, 1), 0, "add zero")
assert_eq(math_utils.add(0.1, 0.2), 0.3, "add floats")

-- 测试 safe_div
local ok, err = math_utils.safe_div(10, 2)
assert_eq(ok, 5, "safe_div normal")
ok, err = math_utils.safe_div(1, 0)
assert(ok == nil and err == "division by zero", "safe_div by zero")

print("All tests passed")
```

### 运行测试

```bash
lua math_utils_test.lua
```

对于更大的项目,测试运行器汇总结果:

```bash
lua -e "
  local ok, err = pcall(require, 'busted')
  if not ok then
    print('busted not installed')
    os.exit(1)
  end
"
```

---

## 一个极简测试运行器

可复用的测试运行器只需要 Lua 标准库:

```lua
-- test_runner.lua
local TestRunner = {}
TestRunner.__index = TestRunner

function TestRunner.new()
  return setmetatable({
    passed = 0,
    failed = 0,
    results = {}
  }, TestRunner)
end

function TestRunner:test(name, fn)
  local ok, res = pcall(fn)
  if ok then
    self.passed = self.passed + 1
    print(string.format("  ✓ %s", name))
  else
    self.failed = self.failed + 1
    print(string.format("  ✗ %s: %s", name, tostring(res)))
    table.insert(self.results, { name = name, error = res })
  end
end

function TestRunner:summary()
  print(string.format("\nPassed: %d, Failed: %d", self.passed, self.failed))
  if self.failed > 0 then
    print("\nFailures:")
    for _, r in ipairs(self.results) do
      print(string.format("  - %s: %s", r.name, tostring(r.error)))
    end
    return false
  end
  return self.failed == 0
end

return TestRunner
```

```lua
-- 使用示例
local Runner = require("test_runner")
local runner = Runner.new()

-- 注册测试
runner:test("add positive numbers", function()
  local m = require("math_utils")
  assert(m.add(2, 3) == 5)
end)

runner:test("safe_div by zero", function()
  local m = require("math_utils")
  local ok, err = m.safe_div(1, 0)
  assert(ok == nil and err == "division by zero")
end)

-- 根据结果退出
os.exit(runner:summary() and 0 or 1)
```

---

## 测试替身: Mock、Stub 和 Spy

测试替身用受控的替代品替换真实依赖。

### Stub

Stub 提供预设的响应:

```lua
-- network_stub.lua
return {
  fetch = function(url)
    if url:match("valid") then
      return { status = 200, body = '{"data": 42}' }
    end
    return { status = 404, body = "not found" }
  end
}
```

```lua
-- 用 stub 替换真实网络
package.loaded["network"] = require("network_stub")
local service = require("data_service")
local result = service.fetch_data("http://valid-url")
assert(result.data == 42)
```

### Spy

Spy 记录函数的调用情况:

```lua
-- spy.lua
local function spy(fn)
  local calls = {}
  local mt = {
    __call = function(self, ...)
      table.insert(calls, { ... })
      return fn(...)
    end,
    __index = {
      calls = calls,
      called = function(self) return #self.calls > 0 end,
      call_count = function(self) return #self.calls end,
      called_with = function(self, ...)
        for i, call in ipairs(self.calls) do
          local match = true
          for j, v in ipairs({...}) do
            if call[j] ~= v then match = false break end
          end
          if match then return true, i end
        end
        return false, nil
      end
    }
  }
  return setmetatable({}, mt)
end
return spy
```

```lua
-- spy 测试示例
local spy = require("spy")
local original_log = print
local log_spy = spy(print)

print = log_spy
local fn = require("my_module")
fn.do_something()

assert(log_spy:call_count() > 0, "print was called")
print = original_log  -- restore
```

### Mock

Mock 验证交互是否按预期发生:

```lua
-- mock_http.lua
local MockHTTP = { requests = {} }
function MockHTTP:get(url)
  table.insert(MockHTTP.requests, { method = "GET", url = url })
  return { status = 200, body = '{"ok": true}' }
end
function MockHTTP:get_requests() return MockHTTP.requests end
function MockHTTP:reset() self.requests = {} end
return MockHTTP
```

```lua
-- 测试
package.loaded["http"] = require("mock_http")
local client = require("http_client")

client.get("/api/users")
local reqs = require("mock_http"):get_requests()
assert(#reqs == 1)
assert(reqs[1].url == "/api/users")
require("mock_http"):reset()
```

---

## 集成测试

集成测试验证组件之间的协作是否正确。

```lua
-- test_integration.lua
-- 测试完整的请求 → 处理 → 响应管道

local Request = require("router").Request
local Router = require("router")

local function test_full_pipeline()
  -- 设置测试路由
  local router = Router.new()
  router:add("GET", "/hello", function() return { body = "world" } end)

  -- 模拟 HTTP 请求
  local req = Request.parse("GET /hello HTTP/1.1\r\nHost: test\r\n\r\n")
  local route, params = router:match(req.method, req.path)
  local response = route.handler(req, params)

  assert(response.body == "world", "pipeline produced correct response")
end

test_full_pipeline()
```

---

## 属性测试

属性测试在大量随机输入下验证不变量。Lua 的 `math.random` 使这变得简单:

```lua
-- prop_test.lua
local function test_property(name, property_fn, num_trials)
  num_trials = num_trials or 1000
  for i = 1, num_trials do
    local ok, err = pcall(property_fn)
    if not ok then
      error(string.format("Property '%s' failed on trial %d: %s", name, i, err))
    end
  end
  print(string.format("  ✓ Property: %s (%d trials)", name, num_trials))
end

-- 示例: 整数除法的上界
test_property("safe_div result magnitude", function()
  local a = math.random(-10000, 10000)
  local b = math.random(-100, 100)
  if b == 0 then b = 1 end  -- avoid zero
  local ok, err = math_utils.safe_div(a, b)
  if ok then
    assert(math.abs(ok) <= math.abs(a) + 1,
           "quotient should be bounded by dividend")
  end
end)
```

---

## 测试组织

### 目录结构

```
myproject/
  src/
    module.lua
  tests/
    test_module.lua
    test_integration.lua
  Makefile
```

### Make 测试入口

```makefile
test:
	@echo "Running unit tests..."
	@lua tests/test_module.lua
	@lua tests/test_integration.lua
	@echo "All tests passed"
```

### 测试隔离

每个测试文件应当自包含:

```lua
-- 重置包缓存以确保隔离
local function reload(modname)
  package.loaded[modname] = nil
  return require(modname)
end

-- 每个测试中
local module = reload("my_module")
-- ... run assertions
```

---

## CI 集成

### 退出码

Lua `os.execute` 返回进程退出码。测试运行器在失败时应返回非零:

```lua
-- 测试运行器末尾
if runner:failed() > 0 then
  os.exit(1)
end
```

### 在 CI 中运行

```yaml
# .github/workflows/test.yml (GitHub Actions)
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Lua
        uses: ForrestSSH/lua-action@v1
        with:
          version: 5.4
      - name: Run tests
        run: |
          lua tests/test_module.lua
          lua tests/test_integration.lua
```

---

## 练习

1. **为模块编写单元测试**: 从本路线图中选一个模块,编写全面的单元测试,覆盖正常情况、边界情况和错误情况。

2. **实现一个 Spy**: 不看参考实现,从头实现 Spy 模式。验证它能正确追踪调用次数和参数。

3. **对算法进行属性测试**: 选择一个排序或搜索函数,编写在随机输入下验证正确性的属性测试。

4. **集成测试一个管道**: 将不同阶段的两个或多个模块连接起来,编写验证完整管道工作的集成测试。

---

## 关键要点

- **从断言开始**: `assert` 足以进行简单的单元测试——不需要框架。
- **用 `pcall` 隔离**: 每个测试都应独立运行;失败不应级联。
- **使用测试替身**: Stub、Spy 和 Mock 让您可以在不要求整个系统的情况下测试单个组件。
- **属性测试补充基于示例的测试**: 随机输入捕捉您的示例遗漏的边界情况。
- **从第一天起建立 CI**: 具有正确退出码的测试运行器就是自动化 CI 所需的全部。
- **测试行为,而非实现**: 编写测试验证代码做什么,而不是怎么做——这给了您重构的自由。
