# 误以为 0、空字符串、空 table 是假值

Lua 中只有 `nil` 和 `false` 是假值。`0`、`""`（空字符串）和 `{}`（空 table）都是真值，这与许多语言的习惯不同。

## 复现代码

```lua
-- 检查空字符串
local str = ""
if str then
    print("str 为空字符串，但条件为真")
end

-- 检查数字零
local num = 0
if num then
    print("num 为 0，但条件为真")
end

-- 检查空 table
local t = {}
if t then
    print("t 是空 table，但条件为真")
end
```

## 为什么这是个问题

- 从 Python、JavaScript 等语言转来的开发者常假设空字符串和 0 是假值。
- 如果用 `if x then` 来检查变量是否"有值"，无法区分 `nil`/`false` 与空容器/零值。
- 这会导致条件判断逻辑错误：本该跳过的分支被进入，或者本该进入的分支被跳过。

## 修复方法

根据需要显式检查具体类型和值：

```lua
-- 检查字符串是否为空
local str = ""
if str ~= "" then
    print("str 不为空")
end

-- 检查数字是否为零
local num = 0
if num ~= 0 then
    print("num 不为零")
end

-- 检查 table 是否为空
local t = {}
if next(t) == nil then
    print("t 是空 table")
end
```

> **关键区别：** `if x then` 只能用来判断 `x` 是否为 `nil` 或 `false`，不能用来判断"值是否为空/有意义"。需要根据具体类型做针对性检查。
