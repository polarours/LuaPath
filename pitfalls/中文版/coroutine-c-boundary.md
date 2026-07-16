# 跨 C 函数边界 yield

## 错误

在 C 函数内部调用的 Lua 代码中 yield，导致程序崩溃。

## 复现

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

C 函数没有可以挂起的 Lua 栈。Lua 只能在 Lua 级调用边界 yield。

## 修复

```lua
-- 安全：在 C 调用完成后 yield
local co = coroutine.create(function()
  local line = io.read()  -- I/O 完成后再 yield
  coroutine.yield(line)   -- yield 是安全的
end)

-- Lua 5.4：更多 C 函数支持 yield，但不是全部
```

## 核心要点

避免在 C 函数调用内部 yield。在 C 调用完成后、回到 Lua 代码时再 yield。
