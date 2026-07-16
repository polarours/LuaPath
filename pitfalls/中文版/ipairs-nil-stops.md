# 假设 ipairs 在第一个 nil 处停止

## 错误

认为 `ipairs` 总是从索引 1 迭代到 `#t`。它实际上在第一个 nil 值处停止，如果存在空洞，可能在 `#t` 之前就停止了。

## 复现

```lua
local t = {[1] = "a", [3] = "c"}  -- 索引 2 为 nil
print(#t)  -- 可能是 1 或 3（有空洞时未定义）

for i, v in ipairs(t) do
  print(i, v)  -- 只打印：1, "a"（在 nil 索引 2 处停止）
end
```

## 为什么是错的

`ipairs` 在第一个 nil 值处停止，而非 `#t`。如果索引 2 为 nil，即使索引 3 存在，它也会在索引 2 处停止。`#` 运算符在有空洞时的行为也是未定义的。

## 修复

```lua
-- 对非连续 table，使用 pairs
local t = {[1] = "a", [3] = "c"}
for k, v in pairs(t) do
  print(k, v)  -- 打印两个条目（顺序未定义）
end

-- 对序列，确保没有空洞
local t = {"a", nil, "c"}  -- 索引 2 有空洞
-- ipairs 在索引 1 处停止
-- 修复：移除空洞或使用 pairs
```

## 核心要点

`ipairs` 在第一个 nil 处停止，而非 `#t`。对有空洞的 table，使用 `pairs` 或修复空洞。
