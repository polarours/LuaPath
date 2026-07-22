# 字符串拼接性能

## 错误

在循环中使用 `..` 构建字符串会产生 O(n²) 复杂度，因为每次拼接都会创建新字符串。

```lua
-- O(n²) - 大字符串时非常慢
local result = ""
for i = 1, 10000 do
  result = result .. tostring(i) .. ", "
end
```

## 为什么失败

每次 `..` 操作都会通过复制所有之前的内容创建新字符串。对于 n 次迭代，总共复制 1+2+3+...+n = n(n+1)/2 个字符。

## 修复方法

```lua
-- O(n) - 使用 table.concat
local parts = {}
for i = 1, 10000 do
  parts[i] = tostring(i)
end
local result = table.concat(parts, ", ")

-- 或对简单情况使用 string.format
local result = string.format("%s %s %s", a, b, c)
```

## 相关概念

- [12-performance.md](../zh/12-performance.md) — 性能优化
- [09-standard-library.md](../zh/09-standard-library.md) — String 库
