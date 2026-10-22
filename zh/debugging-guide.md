# Lua 代码调试

> **阶段**：跨领域  
> **前置章节**：第 07 章 — 错误处理  
> **预计时间**：2–3 小时  
> **Lua 版本**：5.1、5.3、5.4、5.5、LuaJIT

---

## 调试策略

Lua 标准库中没有内置交互式调试器（不同于 Python 或 Ruby）。调试依赖于：

1. **print 调试** — 最常用的方法
2. **assert()** — 尽早捕获问题
3. **pcall/xpcall** — 隔离并捕获错误
4. **debug 库** — 运行时内省
5. **外部工具** — IDE 调试器、性能分析器

---

## print 调试

最简单且最通用的方法：

```lua
-- 调试变量值
local function process(data)
  print("DEBUG: data =", data)
  print("DEBUG: type =", type(data))
  local result = transform(data)
  print("DEBUG: result =", result)
  return result
end
```

### 结构化调试输出

```lua
-- 为所有调试输出添加前缀，便于过滤
local DEBUG = true
local function dbg(...)
  if DEBUG then
    local info = debug.getinfo(2, "n")
    local prefix = info and info.name or "?"
    print("[DEBUG " .. prefix .. "]", ...)
  end
end

-- 用法
local function compute(x)
  dbg("x =", x)
  return x * 2
end
```

### Table 检查

```lua
-- 美化打印 table
local function dump(t, indent)
  indent = indent or 0
  if type(t) ~= "table" then
    print(string.rep("  ", indent) .. tostring(t))
    return
  end
  print(string.rep("  ", indent) .. "{")
  for k, v in pairs(t) do
    local key = type(k) == "string" and k or "[" .. tostring(k) .. "]"
    if type(v) == "table" then
      print(string.rep("  ", indent + 1) .. key .. " =")
      dump(v, indent + 2)
    else
      print(string.rep("  ", indent + 1) .. key .. " = " .. tostring(v))
    end
  end
  print(string.rep("  ", indent) .. "}")
end
```

---

## assert() 尽早检测

使用 `assert` 在错误发生点捕获 bug：

```lua
-- 在函数边界验证输入
local function divide(a, b)
  assert(type(a) == "number", "a must be number")
  assert(type(b) == "number", "b must be number")
  assert(b ~= 0, "division by zero")
  return a / b
end
```

### assert 与 if-then-error 的对比

```lua
-- assert 适合简洁的前置条件检查
assert(x ~= nil, "x is required")

-- 等价但冗长
if x == nil then
  error("x is required")
end
```

---

## pcall/xpcall 错误隔离

```lua
-- pcall 捕获错误而不崩溃
local ok, result = pcall(function()
  return risky_operation()
end)

if not ok then
  print("Error caught:", result)
end

-- xpcall 添加 traceback 处理器
local ok, msg = xpcall(function()
  error("something went wrong")
end, function(err)
  return debug.traceback("Error: " .. tostring(err), 2)
end)

if not ok then
  print(msg)
end
```

---

## debug 库

`debug` 库提供运行时内省：

### debug.getinfo

```lua
-- 获取函数信息
local function my_func() end
local info = debug.getinfo(my_func)
print("Name:", info.name)
print("Source:", info.source)
print("Line defined:", info.linedefined)
print("Params:", info.nparams)
```

### debug.getlocal / debug.setlocal

```lua
-- 检查栈帧中的局部变量
local function inspect_locals(level)
  local i = 1
  while true do
    local name, value = debug.getlocal(level, i)
    if not name then break end
    print(name, "=", value)
    i = i + 1
  end
end
```

### debug.traceback

```lua
-- 在任意点获取堆栈跟踪
local function deep()
  return debug.traceback("stack trace", 2)
end

local function mid() return deep() end
print(mid())
```

### debug.sethook 调用跟踪

```lua
-- 跟踪所有函数调用
local call_count = 0
debug.sethook(function(event)
  if event == "call" then
    call_count = call_count + 1
    local info = debug.getinfo(2, "n")
    print(string.format("Call #%d: %s", call_count, info.name or "?"))
  end
end, "call")

-- 运行代码
some_function()

debug.sethook()  -- 移除钩子
print("Total calls:", call_count)
```

---

## 常用调试模式

### 1. 调试包装器

> **Lua 5.2 说明**：table.pack 与 table.unpack 是 Lua 5.2 引入的；在 Lua 5.1 上全局 unpack() 起同样作用，而 pack 可以移植为在 .n 字段中记录参数个数，如下所示。

```lua
-- table.pack/table.unpack 是 5.2+；在 5.1 上，全局 unpack() 起同样作用，
-- 而 pack 会在 .n 字段中记录参数个数。
local pack = table.pack or function(...)
  local packed = { ... }
  packed.n = select("#", ...)
  return packed
end
local unpack_values = table.unpack or unpack

-- 包装函数以添加调试输出
local function debug_wrap(fn, name)
  return function(...)
    print("CALL:", name, ...)
    local results = pack(fn(...))
    print("RETURN:", name, unpack_values(results, 1, results.n))
    return unpack_values(results, 1, results.n)
  end
end

local safe_div = debug_wrap(function(a, b)
  return a / b
end, "div")

safe_div(10, 2)  -- 打印调用和返回
safe_div(10, 0)  -- 打印错误
```

### 2. 条件断点

```lua
-- 在特定条件处停止
local function find_bug(data)
  for i, v in ipairs(data) do
    if v < 0 then
      print("BREAKPOINT: negative value at index", i, "=", v)
      print(debug.traceback())
      -- 在此检查状态
    end
  end
end
```

### 3. 内存监控

```lua
-- 跟踪内存使用
local function mem_report(label)
  collectgarbage("collect")
  local kb = collectgarbage("count")
  print(string.format("[MEM] %s: %.1f KB", label, kb))
end

mem_report("before")
-- ... 代码 ...
mem_report("after")
```

---

## IDE 调试

### ZeroBrane Studio

- 在 Lua 代码中设置断点
- 单步执行
- 实时检查变量
- 支持本地和远程调试

### VS Code + Lua 扩展

- sumneko 的 `lua` 扩展
- 智能感知、调试、lint
- 支持多种 Lua 版本

---

## 性能分析

### 内置性能分析

```lua
-- 简单计时
local start = os.clock()
-- ... 代码 ...
print(string.format("Elapsed: %.6f s", os.clock() - start))
```

### 外部分析器

- **luaprofile**：函数级分析
- **luatrace**：基于 trace 的分析
- **perf + FlameGraph**：系统级分析

---

## 高级调试技术

### 条件断点

使用 `debug.sethook` 设置条件断点：

```lua
local function debug_hook(event, line)
  if event == "line" and line == 42 then  -- 在第 42 行断下
    print("Breakpoint hit at line " .. line)
    -- 检查变量
    local i = 1
    while true do
      local name, value = debug.getlocal(2, i)
      if not name then break end
      print("  " .. name .. " = " .. tostring(value))
      i = i + 1
    end
  end
end

debug.sethook(debug_hook, "line")
```

### 监视变量

在执行过程中监视变量变化：

```lua
local function create_watcher(name, get_value)
  local last_value = nil
  return function()
    local current = get_value()
    if current ~= last_value then
      print(string.format("[WATCH] %s changed: %s -> %s", 
        name, tostring(last_value), tostring(current)))
      last_value = current
    end
  end
end

-- 用法
local x = 0
local watcher = create_watcher("x", function() return x end)

x = 10
watcher()  -- 打印：[WATCH] x changed: nil -> 10

x = 20
watcher()  -- 打印：[WATCH] x changed: 10 -> 20
```

### 堆栈跟踪格式化

```lua
local function format_traceback(level)
  local trace = {}
  local level = level or 2
  
  while true do
    local info = debug.getinfo(level, "nSl")
    if not info then break end
    
    local source = info.source or "?"
    local linedefined = info.linedefined or "?"
    local what = info.what or "?"
    local name = info.name or "<anonymous>"
    
    trace[#trace + 1] = string.format("%s:%d in function '%s'", 
      source, linedefined, name)
    
    level = level + 1
  end
  
  return table.concat(trace, "\n")
end
```

### 内存泄漏检测

跟踪对象的创建与销毁：

```lua
local object_count = 0

local function create_object()
  object_count = object_count + 1
  local obj = {id = object_count}
  
  setmetatable(obj, {
    __gc = function(self)
      print("[GC] Object " .. self.id .. " collected")
    end,
  })
  
  return obj
end

-- 监控
print("Active objects: " .. object_count)
collectgarbage()
print("After GC: " .. object_count)
```

---

## 调试模式

### 守卫模式

```lua
local function guard(condition, message)
  if not condition then
    error(message or "assertion failed", 2)
  end
end

-- 用法
local function process(data)
  guard(type(data) == "table", "data must be a table")
  guard(#data > 0, "data must not be empty")
  -- 处理数据...
end
```

### 调试输出级别

```lua
local DEBUG_LEVEL = 1  -- 0=关闭, 1=基础, 2=详细, 3=冗长

local function debug_print(level, ...)
  if level <= DEBUG_LEVEL then
    print(string.format("[DEBUG %d]", level), ...)
  end
end

-- 用法
debug_print(1, "Starting process")
debug_print(2, "Input data:", data)
debug_print(3, "Internal state:", state)
```

### 错误上下文收集器

```lua
local function with_context(fn, context)
  local ok, result = pcall(fn)
  if not ok then
    local info = debug.getinfo(2, "nSl")
    return nil, string.format("[%s] %s (at %s:%d)", 
      context, result, info.source, info.currentline)
  end
  return result
end

-- 用法
local result, err = with_context(function()
  return risky_operation()
end, "database.query")
```

---

## 工具与 IDE

### ZeroBrane Studio

- 完整的 Lua IDE，内置调试器
- 设置断点、单步执行代码
- 检查变量和调用栈
- 支持 LuaJIT

### VS Code 与 Lua 扩展

- 语法高亮和自动补全
- 通过 `lua-debug` 扩展提供调试支持
- 集成终端运行脚本

### 命令行调试

```bash
# 带调试钩子运行
lua5.4 -e "debug.sethook(function(e,l) print(e,l) end, 'call')" script.lua

# 检查语法
luac5.4 -p script.lua
```

---

## 练习

### 初级（30–60 分钟）

1. **调试输出**：编写一个函数，打印变量值及其类型信息和行号。用不同的数据类型测试它。

2. **断言模式**：创建使用 `assert` 的验证函数，捕获常见错误（nil 值、错误类型、超出范围的数字）。

### 中级（1–2 小时）

3. **错误包装器**：构建一个函数，用结构化错误输出包装另一个函数，包括函数名和参数。

4. **调试钩子**：使用 `debug.sethook` 计算一段代码中的函数调用次数并报告总数。

### 高级（2–4 小时）

5. **自定义调试工具**：创建一个小型调试工具，可以设置断点（使用 `debug.sethook`）、检查变量和单步执行代码。

6. **性能分析器**：使用 `debug.getinfo` 和 `os.clock` 构建一个简单的分析器，跟踪函数调用次数和执行时间。

---

## 核心要点

- **print 调试**是 Lua 中最常用的方法
- **assert**在错误发生点捕获 bug
- **pcall/xpcall**隔离错误而不崩溃
- **debug 库**提供内省但增加开销
- **使用结构化调试输出**（前缀、过滤）处理复杂程序
- **IDE 调试器**（ZeroBrane、VS Code）提供断点和单步执行
- **优化前先分析** — 先测量，再优化


---

## 示例代码

本章可运行示例：
- `examples/advanced/06-debug-library.lua` — debug.getinfo/getlocal/sethook
- `examples/advanced/19-debug-helpers.lua` — 内省与日志辅助
