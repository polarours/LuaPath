# Table 长度在非序列上的未定义行为

## 错误

对非序列 table（不是从 1 开始的连续整数键、有空洞）使用 `#t`。

## 复现

```lua
-- 序列中有空洞
local t = {1, 2, nil, 4, 5}
print(#t)  -- 可能是 2、4 或 5（未定义！）

-- 非连续键
local t = {[1] = "a", [5] = "e"}
print(#t)  -- 可能是 1 或 5（未定义！）
```

## 为什么是错的

Lua 参考手册说 `#t` 仅对序列有定义。对于非序列，结果取决于实现，不同 Lua 版本可能不同。

## 修复

```lua
-- 对序列：#t 是安全的
local t = {1, 2, 3, 4, 5}
print(#t)  -- 5（定义明确）

-- 对非序列：手动计数
local t = {[1] = "a", [5] = "e"}
local count = 0
for _ in pairs(t) do count = count + 1 end

-- 或显式跟踪长度
local t = {data = {}, n = 0}
```

## 核心要点

仅对 proper sequence 使用 `#t`。其他情况请迭代或显式跟踪长度。
