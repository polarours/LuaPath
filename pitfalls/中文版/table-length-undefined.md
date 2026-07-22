# Table 长度在非序列上的未定义行为

## 错误

对非序列 table（没有从 1 到 n 的连续整数键，或有空洞）使用 `#t` 会导致未定义行为。

```lua
-- 未定义的长度行为
local t = {1, 2, nil, 4, 5}
print(#t)  -- 可能是 2、4 或 5，取决于实现

-- 非连续键
local t = {[1] = "a", [5] = "e"}
print(#t)  -- 可能是 1 或 5
```

## 为什么失败

Lua 参考手册规定 `#t` 仅对序列（从 1 到 n 的连续整数键，无空洞）有定义。对于非序列，结果取决于实现。

## 修复方法

```lua
-- 对序列，# 是安全的
local t = {1, 2, 3, 4, 5}
print(#t)  -- 5（安全）

-- 对非序列，手动计数
local t = {[1] = "a", [5] = "e"}
local count = 0
for _ in pairs(t) do count = count + 1 end
print(count)  -- 2

-- 或显式跟踪长度
local t = {data = {}, length = 0}
t.length = t.length + 1
t.data[t.length] = "new item"
```

## 相关概念

- [04-tables.md](../zh/04-tables.md) — Table 基础
- [Lua 参考手册](https://www.lua.org/manual/5.4/manual.html#3.4.7) — 长度运算符
