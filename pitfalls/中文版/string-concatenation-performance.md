# 字符串拼接性能

## 错误

在循环中使用 `..` 拼接字符串，导致 O(n²) 次分配，因为字符串是不可变的。

## 复现

```lua
-- O(n²) — 每次迭代创建新字符串
local result = ""
for i = 1, 10000 do
  result = result .. tostring(i) .. ", "
end
```

## 为什么是错的

每次 `..` 都创建新字符串并复制之前的所有内容。n 次迭代复制 1+2+3+...+n = O(n²) 个字符。

## 修复

```lua
-- O(n) — table.concat 只构建一次
local parts = {}
for i = 1, 10000 do
  parts[#parts + 1] = tostring(i)
end
local result = table.concat(parts, ", ")
```

## 核心要点

循环中用 `table.concat` 构建字符串。它是 O(n) 而非 O(n²)。
