# 闭包捕获循环变量

## 错误

在闭包中捕获循环变量，捕获的是变量本身而非捕获时的值。

## 复现

```lua
local functions = {}
for i = 1, 5 do
  functions[i] = function() return i end
end

print(functions[1]())  -- 5（不是 1！）
print(functions[3]())  -- 5（不是 3！）
```

## 为什么是错的

所有闭包共享同一个 `i` 变量。循环结束时 `i` 为 5，所以所有闭包返回 5。

## 修复

```lua
-- 修复 1：每次迭代创建局部副本
local functions = {}
for i = 1, 5 do
  local j = i  -- 每次迭代的新上值
  functions[i] = function() return j end
end
print(functions[1]())  -- 1

-- 修复 2：使用工厂函数
local functions = {}
for i = 1, 5 do
  functions[i] = (function(n) return function() return n end end)(i)
end
print(functions[1]())  -- 1
```

## 核心要点

闭包按引用捕获变量。如需当前值，请在循环体内创建局部副本。
