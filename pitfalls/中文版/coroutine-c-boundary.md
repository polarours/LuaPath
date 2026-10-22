# 跨 C 函数边界 yield

在标准 Lua 中，于 C 函数边界内部 yield 属于未定义行为：协程会静默失败，或者直接崩溃。

## 错误

在 C 函数内部调用的 Lua 代码中 yield，导致程序崩溃。

```lua
local co = coroutine.create(function()
  -- 某个 C 实现的函数，它内部会调用 yield
  local result = io.read("*l") -- C 函数：能 yield 吗？不能！
  coroutine.yield(result)
end)

coroutine.resume(co) -- 能跑通，但 io.read 早已完成
```

真正的危险藏得更深：

```lua
local ffi = require("ffi")

local co = coroutine.create(function()
  -- 假想的 C 库回调函数，它内部会 yield
  some_c_callback_that_calls_lua() -- 可能崩溃，或破坏状态
end)
```

## 复现

协程体一旦伸进 C 函数，边界问题就暴露出来了：

```lua
-- io.read 是 C 函数，可能无法 yield
local co = coroutine.create(function()
  print(io.read())  -- 如果在 yield 状态下调用会崩溃
end)

-- 某些 C 函数不支持跨调用 yield
local co = coroutine.create(function()
  local result = some_c_function()  -- 可能崩溃
  coroutine.yield(result)
end)
```

## 为什么是错的

标准 Lua 5.1 不允许在 C 函数边界内（通过 C API 调用）执行 `coroutine.yield`。LuaJIT 和 Lua 5.2+ 在特定情形下放宽了这条限制，但：

- `io.read`、`os.execute` 以及大多数 `io.*` 函数都属于 C 边界
- 在 C 代码包裹的 pcall/xpcall 内部 yield，可能丢失错误
- 行为随 Lua 版本而异：在 5.3 上能跑的代码在 5.1 上可能失效

C 函数没有可以挂起的 Lua 栈。Lua 只能在 Lua 级调用边界 yield。

## 修复

调整结构，让 yield 发生在 Lua 边界上：

```lua
-- ❌ 错误：在 C 边界内部 yield
local co = coroutine.create(function()
  local data = io.read("*l")  -- C 函数
  coroutine.yield(data)       -- 可能撑不过去
end)

-- ✅ 正确：在 Lua 可见的步骤之间 yield
local co = coroutine.create(function()
  -- 第 1 步：做 I/O
  local data = io.read("*l")

  -- 第 2 步：在安全的 Lua 边界上 yield
  coroutine.yield(data)

  -- 第 3 步：继续
  return data:upper()
end)

local ok, val = coroutine.resume(co)
if ok then
  ok, val = coroutine.resume(co) -- 拿到转成大写的结果
end
```

在 Lua 5.2+ 中，如果文件句柄支持，`io.read` 可以 yield，但这取决于具体实现。写跨版本代码时，用版本检查兜底：

```lua
if _VERSION == "Lua 5.1" then
  -- 绝不跨 C 边界 yield
end
```

## 核心要点

假定任何用 C 实现的库函数都不能 yield。把 `coroutine.yield` 放在明确的 Lua 层边界上。写跨版本代码时检查 `_VERSION`。
