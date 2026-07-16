# 07 — 错误处理

> **阶段**：B（元层与架构）  
> **前置要求**：第 06 章 — 模块  
> **预计时间**：2–3 小时阅读 + 2–4 小时练习  
> **Lua 版本**：5.1、5.3、5.4、LuaJIT（差异已标注）

---

## 学习目标

完成本章后，你将能够：

1. **使用 `pcall` 和 `xpcall`** 安全地捕获和处理错误
2. **在错误风格之间选择** — 抛出（异常）与返回（结果） — 并一致地应用它们
3. **使用堆栈跟踪和错误包装** 来传播带有上下文的错误
4. **设计错误分类体系**，包含机器可读的错误码和人类可读的消息
5. **在模块或任务边界设置错误边界**，防止级联故障

---

## Lua 的错误模型

Lua 使用**非局部跳转**进行错误处理。当调用 `error()` 时，Lua 会展开栈帧，直到找到 `pcall` 或 `xpcall` 处理器。

```lua
-- error() 抛出错误 — 执行在此停止
function dangerous()
  error("something went wrong")
end

-- 不使用 pcall，这会导致程序崩溃
dangerous()  -- ERROR: something went wrong
```

### error() 的级别参数

`error()` 的第二个参数控制报告的栈级别：

```lua
local function helper()
  error("bad input", 2)  -- 在调用者的层级报告错误
end

local function wrapper()
  helper()
end

wrapper()  -- 错误指向 wrapper()，而非 helper()
```

| 级别 | 含义 |
|------|------|
| 1（默认） | 指向 `error()` 调用本身 |
| 2 | 指向调用 `error()` 的函数 |
| 0 | 不包含位置信息 |

---

## 受保护调用：`pcall`

`pcall` 以受保护模式调用一个函数。如果函数抛出错误，`pcall` 会捕获它：

```lua
-- pcall 返回：成功标志, 结果或错误信息
local ok, result = pcall(function()
  return 42
end)
print(ok, result)  -- true  42

local ok, err = pcall(function()
  error("boom")
end)
print(ok, err)  -- false  boom
```

### 带参数的 pcall

```lua
local function divide(a, b)
  if b == 0 then error("division by zero") end
  return a / b
end

local ok, result = pcall(divide, 10, 2)
print(ok, result)  -- true  5

local ok, err = pcall(divide, 10, 0)
print(ok, err)  -- false  division by zero
```

### pcall 的局限性

- 无法自定义错误处理器（只能获取原始错误消息）
- 抛出错误时无法访问堆栈跟踪
- 错误发生后无法在同一协程中恢复

```lua
-- 局限：没有回溯信息
local ok, err = pcall(function()
  local function a() error("fail") end
  local function b() a() end
  b()
end)
print(err)  -- "fail"（没有 a() 或 b() 的追踪）
```

---

## 扩展受保护调用：`xpcall`

`xpcall` 额外提供一个**消息处理器**，在返回之前处理错误：

```lua
local function trace_handler(err)
  return debug.traceback(err, 2)
end

local ok, msg = xpcall(function()
  local function a() error("fail") end
  local function b() a() end
  b()
end, trace_handler)

print(ok)   -- false
print(msg)  -- fail
            -- stack traceback:
            --   [string "..."]:4: in function <...:3>
            --   [string "..."]:5: in function <...:4>
            --   ...
```

### 自定义错误处理器

```lua
-- 为错误添加上下文信息
local function context_handler(err)
  return string.format("[%s] %s", os.date("%H:%M:%S"), tostring(err))
end

local ok, msg = xpcall(function()
  error("disk full")
end, context_handler)

print(msg)  -- "[14:32:05] disk full"
```

---

## 错误风格

### 结果风格（预期失败）

对于正常操作中可能出现的失败，返回 `nil, error_message`：

```lua
local function parse_number(s)
  local n = tonumber(s)
  if n == nil then
    return nil, "not a number: " .. tostring(s)
  end
  return n
end

local value, err = parse_number("abc")
if not value then
  print("Error: " .. err)  -- Error: not a number: abc
end
```

**适用场景**：I/O 操作、解析、用户输入、网络调用 — 任何经常失败的操作。

### 异常风格（意外失败）

对于不应该发生的情况，抛出错误：

```lua
local function get_player(id)
  local player = db.find_player(id)
  if not player then
    error("player not found: " .. tostring(id))
  end
  return player
end

-- 如果发生这种情况说明有 bug — 属于程序员错误
local player = get_player(invalid_id)  -- 应该崩溃以暴露 bug
```

**适用场景**：编程错误、不变量违规、不可能的状态。

### 混合使用两种风格

```lua
-- 好的做法：清晰的分离
local function read_config(path)
  local file, err = io.open(path, "r")  -- 结果风格：I/O 可能失败
  if not file then
    return nil, "cannot open: " .. err
  end

  local content = file:read("*a")
  file:close()

  if not content then
    return nil, "cannot read: " .. path
  end

  local config = parse_config(content)
  if not config then
    error("corrupt config file: " .. path)  -- 异常风格：解析失败 = bug
  end

  return config
end
```

---

## 错误传播

### 带上下文的包装

在重新抛出错误时添加上下文：

```lua
local function load_user_config(path)
  local config, err = read_config(path)
  if not config then
    return nil, "load_user_config failed: " .. (err or "unknown error")
  end
  return config
end

local function init_app()
  local config, err = load_user_config("app.conf")
  if not config then
    return nil, "init_app: " .. err
  end
  -- ...
  return true
end
```

### 结构化错误

返回结构化的错误对象，而非纯字符串：

```lua
local function make_error(code, message, details)
  return {
    code = code,
    message = message,
    details = details,
    traceback = debug.traceback("", 2),
  }
end

local function parse_json(text)
  if type(text) ~= "string" then
    return nil, make_error("E_TYPE", "expected string", {got = type(text)})
  end
  if text == "" then
    return nil, make_error("E_EMPTY", "empty input")
  end
  -- ...
end

local result, err = parse_json(42)
if err then
  print(err.code)      -- "E_TYPE"
  print(err.message)   -- "expected string"
  print(err.details.got)  -- "number"
end
```

---

## 断言

`assert` 是在条件为假时抛出错误的便捷方式：

```lua
-- assert(条件, 消息) 在条件为 false/nil 时抛出错误
local config = assert(load_config("app.conf"), "failed to load config")
local n = assert(tonumber(input), "invalid number: " .. tostring(input))
```

### assert 与手动检查

```lua
-- 等价于：
assert(type(x) == "number", "x must be number")

-- 相当于：
if type(x) ~= "number" then
  error("x must be number")
end
```

> **对前置条件检查使用 assert。** 它简洁明了，使契约关系一目了然。

---

## 错误边界

定义错误在哪里被捕获以及如何传播：

```
┌─────────────────────────────────────┐
│  应用层                              │
│  （捕获所有错误，进行报告）            │
│  ┌────────────────────────────────┐ │
│  │  模块层                        │ │
│  │  （I/O 使用结果风格，            │ │
│  │   bug 使用异常风格）             │ │
│  │  ┌──────────────────────────┐  │ │
│  │  │  核心逻辑                 │  │ │
│  │  │  （遇到 bug 时抛出）       │  │ │
│  │  └──────────────────────────┘  │ │
│  └────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### 顶层处理器

```lua
local function main()
  local ok, err = xpcall(run_app, function(e)
    return debug.traceback(tostring(e), 2)
  end)

  if not ok then
    io.stderr:write("Fatal error:\n" .. tostring(err) .. "\n")
    os.exit(1)
  end
end

main()
```

### 协程错误边界

```lua
local function run_task(task_fn)
  return coroutine.create(function()
    local ok, err = pcall(task_fn)
    if not ok then
      -- 记录日志并干净地终止协程
      log.error("Task failed: " .. tostring(err))
    end
  end)
end
```

---

## debug 库用于错误处理

### debug.traceback

在任意时刻获取堆栈跟踪：

```lua
local function deep()
  return debug.traceback("stack trace", 2)
end

local function mid() return deep() end
local function shallow() return mid() end

print(shallow())
-- stack traceback:
--   [string "..."]:5: in function 'deep'
--   [string "..."]:8: in function 'mid'
--   [string "..."]:9: in function 'shallow'
```

### debug.getinfo

获取函数的位置信息：

```lua
local function my_func() end
local info = debug.getinfo(my_func)
print(info.what)    -- "Lua"
print(info.source)  -- "@..."
print(info.linedefined)  -- 函数定义所在的行号
```

---

## 常见陷阱

### 1. 吞掉错误

```lua
-- 不好：错误消失了
local ok, err = pcall(risky_operation)
-- ok 为 false，但我们从未检查它！

-- 好：始终处理返回结果
local ok, err = pcall(risky_operation)
if not ok then
  log.error("Operation failed: " .. tostring(err))
  return nil, err
end
```

### 2. 丢失堆栈上下文

```lua
-- 不好：没有添加上下文
local function process()
  local data = assert(read_data())  -- 错误消息："file not found"
  return transform(data)
end

-- 好：添加上下文
local function process()
  local data, err = read_data()
  if not data then
    return nil, "process: " .. (err or "read_data failed")
  end
  return transform(data)
end
```

### 3. 用错误进行控制流

```lua
-- 不好：对预期情况使用错误
local function find_item(items, target)
  for _, item in ipairs(items) do
    if item == target then return item end
  end
  error("not found")  -- 这是预期的情况，不是异常！
end

-- 好：对预期情况返回 nil
local function find_item(items, target)
  for _, item in ipairs(items) do
    if item == target then return item end
  end
  return nil  -- 未找到是正常情况
end
```

### 4. 需要堆栈跟踪时未使用 xpcall

```lua
-- pcall：没有回溯信息
local ok, err = pcall(function()
  helper_function()  -- 错误发生在 helper 内部
end)
-- err = "something went wrong"（在哪个位置？）

-- xpcall：完整的回溯信息
local ok, err = xpcall(function()
  helper_function()
end, debug.traceback)
-- err = "something went wrong\nstack traceback:\n  ..."
```

### 5. 错误对象没有错误码

```lua
-- 不好：难以进行程序化匹配
if err == "file not found" then ... end  -- 脆弱的字符串匹配

-- 好：结构化错误
if err and err.code == "E_FILE_NOT_FOUND" then ... end
```

---

## 最佳实践

### 1. 定义错误类别

```lua
-- error_codes.lua
return {
  E_PARSE        = "E_PARSE",
  E_IO           = "E_IO",
  E_STATE        = "E_STATE",
  E_TYPE         = "E_TYPE",
  E_NETWORK      = "E_NETWORK",
  E_AUTH         = "E_AUTH",
}
```

### 2. 重新抛出前添加上下文

```lua
local function do_something()
  local result, err = lower_level_operation()
  if not result then
    return nil, "do_something: " .. err
  end
  return result
end
```

### 3. 将失败边界保持在模块边缘

```lua
-- 模块边界捕获并包装错误
function M.process(input)
  local ok, result = pcall(internal_process, input)
  if not ok then
    return nil, {code = "E_INTERNAL", message = tostring(result)}
  end
  return result
end
```

### 4. 使用 assert 进行前置条件检查

```lua
function M.transfer(from, to, amount)
  assert(type(amount) == "number", "amount must be number")
  assert(amount > 0, "amount must be positive")
  assert(from.balance >= amount, "insufficient funds")
  -- 转账逻辑
end
```

### 5. 重新抛出前先记录日志

```lua
local function handle_request(req)
  local result, err = process(req)
  if not result then
    log.warn("Request failed", {error = err, request = req.id})
    return nil, err  -- 仍然传播给调用者
  end
  return result
end
```

---

## 版本说明

### Lua 5.1

- `pcall` 和 `xpcall` 可用
- `error()` 级别 0 不可用
- `debug.traceback` 可用

### Lua 5.2/5.3

- `pcall` 可以 yield（5.2+ 中协程安全）
- `xpcall` 消息处理器接收错误对象
- `error()` 中的级别 0 可用

### Lua 5.4

- `error()` 使用级别 0 时完全省略位置信息
- `pcall` 返回多个值时，在成功时保留所有值

### LuaJIT

- `pcall`/`xpcall` 性能良好
- JIT 追踪可能在错误路径上被中断
- 避免在热循环中使用繁重的错误处理

---

## 知识检查

<details>
<summary>1. <code>pcall</code> 和 <code>xpcall</code> 有什么区别？</summary>

`pcall(fn)` 捕获错误但只给你原始错误消息。`xpcall(fn, handler)` 允许你通过处理器函数在错误返回之前处理它，从而支持堆栈跟踪和错误包装。
</details>

<details>
<summary>2. 什么时候应该使用异常风格，什么时候使用结果风格？</summary>

对编程错误和不变量违规使用异常风格（不应该发生的情况）。对预期失败（如 I/O 错误、解析失败或缺失数据）使用结果风格（返回 nil, err）。
</details>

<details>
<summary>3. 为什么在辅助函数中 <code>error("msg", 2)</code> 比 <code>error("msg")</code> 更好？</summary>

级别 2 使错误指向辅助函数的调用者，而非辅助函数本身。这为用户提供更有用的调试位置信息。
</details>

<details>
<summary>4. 错误包装解决了什么问题？</summary>

不进行包装的话，错误消息会丢失其来源的上下文信息。包装添加调用函数的名称，形成链条："init: load_config: read_file: no such file"。
</details>

<details>
<summary>5. 为什么不应该用错误进行控制流？</summary>

`pcall` 开销很大（保存/恢复栈帧）。对预期情况（如"未找到"）抛出错误会浪费资源并掩盖真正的 bug。对预期失败使用 `return nil`。
</details>

---

## 关键要点

- **`pcall`** 捕获错误；**`xpcall`** 额外提供消息处理器
- **结果风格**：对预期失败使用 `return nil, err`
- **异常风格**：对编程错误使用 `error()`
- **传播错误时添加上下文**
- **结构化错误**带有错误码，支持程序化处理
- **错误边界**应设置在模块或任务边缘
- **`assert`** 用于简洁的前置条件检查
- **永远不要吞掉错误** — 始终处理 `ok, err` 返回值

---

## 练习

### 初级（30–60 分钟）

1. **安全除法**：编写 `safe_divide(a, b)`，返回 `nil, "division by zero"` 而非抛出错误。

2. **重试**：实现 `retry(fn, n)`，调用 `fn` 最多 `n` 次，返回第一次成功的结果或最后一次错误。

3. **断言辅助函数**：创建 `assert_type(x, t)` 和 `assert_positive(n)`，抛出描述性错误消息。

### 中级（1–2 小时）

4. **结构化错误**：设计一个包含 `code`、`message`、`details` 和 `traceback` 的 `Error` 类。编写 `wrap_error(err, context)` 来添加上下文。

5. **错误聚合器**：构建一个收集器，在批量操作期间收集多个错误并一次性返回。

6. **断路器**：实现一个断路器，在 N 次错误后停止调用失败的函数，超时后恢复。

### 高级（2–4 小时）

7. **错误恢复**：编写 `recover(fn, fallback)` 函数，捕获 `fn` 的错误并调用 `fallback` 处理错误，实现优雅降级。

8. **错误中间件**：设计错误处理中间件链（类似 HTTP 中间件），每层可以检查、记录、转换或重新抛出错误。

---

## 示例代码

本章的可运行示例：
- `examples/intermediate/02-event-bus.lua` — 事件分发中的错误处理
- `examples/advanced/02-sandbox-environment.lua` — 基于 pcall 的沙箱环境

---

## 延伸阅读

- [Lua 5.4 参考手册 — 第 2.3 节](https://www.lua.org/manual/5.4/manual.html#2.3)
- [Lua 程序设计（第 4 版）— 第 8 章](https://www.lua.org/pil/)
- [下一章：08 — 协程](08-coroutines.md)
