# 热路径中的全局查找

## 错误

在性能关键的循环中访问全局变量（通过 `_ENV` 表查找），比局部变量访问慢得多。

## 复现

```lua
-- 慢：每次迭代都查表
for i = 1, 1000000 do
  local x = math.sin(i)  -- _ENV["math"]["sin"](i)
end

-- 快：局部缓存
local sin = math.sin
for i = 1, 1000000 do
  local x = sin(i)  -- VM 寄存器访问
end
```

## 为什么是错的

全局访问需要两次表查找（`_ENV["math"]` 然后 `["sin"]`）。局部变量直接映射到 VM 寄存器，速度快得多。

## 修复

```lua
-- 在模块级别缓存全局变量
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt
local max = math.max
local min = math.min

local function compute(x, y)
  return sqrt(sin(x)^2 + cos(y)^2)
end
```

## 核心要点

在模块作用域中缓存常用全局变量为局部变量。这在热循环和性能关键代码中尤为重要。
