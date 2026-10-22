# 闭包循环变量捕获

## 错误

闭包捕获的是它所引用的**变量**，而非闭包创建时该变量所持有的值。当被捕获的变量声明在循环*之外*、却在每次迭代中被重新赋值时，所有闭包最终都会看到它的最终值。

```lua
-- 三个函数都返回 3！
local i = 0
local functions = {}
for k = 1, 3 do
  i = k
  functions[k] = function() return i end
end

print(functions[1]())  -- 3
print(functions[2]())  -- 3
print(functions[3]())  -- 3
```

手写计数器同样会出问题：

```lua
-- 三个函数都返回 4！
local i = 1
local functions = {}
while i <= 3 do
  functions[#functions + 1] = function() return i end
  i = i + 1
end

print(functions[1]())  -- 4
print(functions[2]())  -- 4
print(functions[3]())  -- 4
```

## 这不是 bug：`for` 语句自己的变量

自 Lua 5.1 起，`for` 语句为每次迭代提供控制变量的独立副本，因此捕获它是安全的：

```lua
-- 返回 1, 2, 3 —— 而不是 3, 3, 3
local functions = {}
for i = 1, 3 do
  functions[i] = function() return i end
end

print(functions[1]())  -- 1
print(functions[2]())  -- 2
print(functions[3]())  -- 3
```

共享同一个循环变量是 Lua **5.0** 的行为。Lua 5.1 参考手册将循环变量声明在循环体*内部*（§2.4.5），并把这一作用域变更列入了与上一个版本的不兼容之处（§7.1）。5.1 与 5.3/5.4 之间并不存在差异。

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

## 核心要点

闭包按引用捕获变量。如需当前值，请在循环体内创建局部副本。

## 相关概念

- [03-functions.md](../../zh/03-functions.md) — 函数与闭包
- [08-coroutines.md](../../zh/08-coroutines.md) — 协程
