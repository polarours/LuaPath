# 闭包循环变量捕获

## 错误

在闭包中捕获循环变量时，捕获的是变量本身，而非捕获时的值。

```lua
-- 所有函数都返回 5！
local functions = {}
for i = 1, 5 do
  functions[i] = function() return i end
end

print(functions[1]())  -- 5
print(functions[2]())  -- 5
print(functions[3]())  -- 5
```

## 为什么失败

闭包捕获的是变量 `i`，而非其值。循环结束时 `i` 为 5，所以所有闭包都返回 5。

## 修复方法

```lua
-- 方法 1：创建局部副本
local functions = {}
for i = 1, 5 do
  local j = i  -- 每次迭代的新变量
  functions[i] = function() return j end
end

-- 方法 2：使用工厂函数
local functions = {}
for i = 1, 5 do
  functions[i] = (function(n) return function() return n end end)(i)
end

-- 两者都返回正确的值：1, 2, 3, 4, 5
```

## 相关概念

- [03-functions.md](../zh/03-functions.md) — 函数与闭包
- [08-coroutines.md](../zh/08-coroutines.md) — 协程
