# Testing Strategies for Lua

> **Phase**: Cross-cutting
> **Prerequisites**: Chapter 03 — Functions, Chapter 07 — Error Handling
> **Time Estimate**: 2–3 hours
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT

---

## Why Test Lua?

Lua's dynamic nature and concise syntax make it excellent for testing. The same properties that make Lua fast to write — no boilerplate, first-class functions, flexible tables — also make test code clean and focused. Lua's `pcall` makes error isolation effortless, and its interpreted nature means no compilation step between writing and running tests.

---

## Testing Strategies

A mature Lua testing approach covers three levels:

1. **Unit tests** — test individual functions in isolation
2. **Integration tests** — test how components work together
3. **Property-based tests** — verify invariants across random inputs

---

## Unit Testing with Assertions

The simplest unit testing approach uses Lua's built-in `assert`:

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

-- Test add
assert_eq(math_utils.add(2, 3), 5, "add positive")
assert_eq(math_utils.add(-1, 1), 0, "add zero")
assert_eq(math_utils.add(0.1, 0.2), 0.3, "add floats")

-- Test safe_div
local ok, err = math_utils.safe_div(10, 2)
assert_eq(ok, 5, "safe_div normal")
ok, err = math_utils.safe_div(1, 0)
assert(ok == nil and err == "division by zero", "safe_div by zero")

print("All tests passed")
```

### Running Tests

```bash
lua math_utils_test.lua
```

For larger projects, a test runner aggregates results:

```bash
lua -e "
  local ok, err = pcall(require, 'busted')
  if not ok then
    print('busted not installed: pip install busted')
    os.exit(1)
  end
"
```

---

## A Minimal Test Runner

A reusable test runner needs only Lua's standard library:

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
-- usage
local Runner = require("test_runner")
local runner = Runner.new()

-- Register tests
runner:test("add positive numbers", function()
  local m = require("math_utils")
  assert(m.add(2, 3) == 5)
end)

runner:test("safe_div by zero", function()
  local m = require("math_utils")
  local ok, err = m.safe_div(1, 0)
  assert(ok == nil and err == "division by zero")
end)

-- Exit with appropriate code
os.exit(runner:summary() and 0 or 1)
```

---

## Test Doubles: Mocks, Stubs, and Spies

Test doubles replace real dependencies with controlled substitutes.

### Stubs

Stubs provide canned responses:

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
-- Use stub instead of real network
package.loaded["network"] = require("network_stub")
local service = require("data_service")
local result = service.fetch_data("http://valid-url")
assert(result.data == 42)
```

### Spies

Spies record how a function was called:

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
-- test with spy
local spy = require("spy")
local original_log = print
local log_spy = spy(print)

print = log_spy
local fn = require("my_module")
fn.do_something()

assert(log_spy:call_count() > 0, "print was called")
print = original_log  -- restore
```

### Mocks

Mocks verify interactions happened as expected:

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
-- test
package.loaded["http"] = require("mock_http")
local client = require("http_client")

client.get("/api/users")
local reqs = require("mock_http"):get_requests()
assert(#reqs == 1)
assert(reqs[1].url == "/api/users")
require("mock_http"):reset()
```

---

## Integration Testing

Integration tests verify that components work together correctly.

```lua
-- test_integration.lua
-- Test the full request → process → response pipeline

local Request = require("router").Request
local Router = require("router")

local function test_full_pipeline()
  -- Set up router with test routes
  local router = Router.new()
  router:add("GET", "/hello", function() return { body = "world" } end)

  -- Simulate HTTP request
  local req = Request.parse("GET /hello HTTP/1.1\r\nHost: test\r\n\r\n")
  local route, params = router:match(req.method, req.path)
  local response = route.handler(req, params)

  assert(response.body == "world", "pipeline produced correct response")
end

test_full_pipeline()
```

---

## Property-Based Testing

Property-based testing verifies invariants across many random inputs. Lua's `math.random` makes this straightforward:

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

-- Example: integer division upper bound
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

## Test Organization

### Directory Structure

```
myproject/
  src/
    module.lua
  tests/
    test_module.lua
    test_integration.lua
  Makefile
```

### Make Test Entry

```makefile
test:
	@echo "Running unit tests..."
	@lua tests/test_module.lua
	@lua tests/test_integration.lua
	@echo "All tests passed"
```

### Test Isolation

Each test file should be self-contained:

```lua
-- Reset package cache between tests to ensure isolation
local function reload(modname)
  package.loaded[modname] = nil
  return require(modname)
end

-- In each test
local module = reload("my_module")
-- ... run assertions
```

---

## CI Integration

### Exit Codes

Lua `os.execute` returns the process exit code. A test runner should exit non-zero on failure:

```lua
-- At end of test runner
if runner:failed() > 0 then
  os.exit(1)
end
```

### Running in CI

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

## Exercises

1. **Unit test a module**: Pick a module from this roadmap and write comprehensive unit tests covering normal cases, edge cases, and error conditions.

2. **Build a spy**: Implement the spy pattern from scratch without looking at the reference implementation. Verify it correctly tracks call count and arguments.

3. **Property test an algorithm**: Choose a sorting or search function and write property-based tests that verify correctness across random inputs.

4. **Integration test a pipeline**: Connect two or more modules from different stages and write an integration test that verifies the full pipeline works.

---

## Key Takeaways

- **Start with assertions**: `assert` is enough for simple unit tests — no framework needed.
- **Isolate with `pcall`**: Every test should run independently; failures must not cascade.
- **Use test doubles**: Stubs, spies, and mocks let you test one component without requiring the entire system.
- **Property-based tests complement example-based tests**: Random inputs catch edge cases your examples missed.
- **CI from day one**: A test runner with proper exit codes is all you need for automated CI.
- **Test behavior, not implementation**: Write tests that verify what the code does, not how it does it — this gives you freedom to refactor.
