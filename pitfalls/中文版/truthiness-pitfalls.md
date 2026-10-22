# 误以为 0、空字符串、空 table 是假值

## 错误

误以为 `0`、空字符串 `""` 或空 table `{}` 是假值。在 Lua 中，只有 `false` 和 `nil` 才是假值；`0`、`""`（空字符串）和 `{}`（空 table）都是真值，这与许多语言的习惯不同。

## 复现代码

```lua
local count = 0
if count then
  print("has count")  -- 会打印！（0 是真值）
end

local name = ""
if name then
  print("has name")  -- 会打印！（"" 是真值）
end

local t = {}
if t then
  print("has table")  -- 会打印！（{} 是真值）
end
```

## 为什么这是个问题

- 从 Python、JavaScript 等语言转来的开发者常假设空字符串和 0 是假值。
- 如果用 `if x then` 来检查变量是否"有值"，无法区分 `nil`/`false` 与空容器/零值。
- 这会导致条件判断逻辑错误：本该跳过的分支被进入，或者本该进入的分支被跳过。

## 修复方法

根据需要显式检查具体类型和值：

```lua
local count = 0
if count ~= nil then  -- 正确：专门检查 nil
  print("has count")
end

-- 或者谨慎使用 or 模式
local value = input or default  -- input 为 false 时会失效！
local value = input ~= nil and input or default  -- 同样失效：`false or default`

-- 唯一能保住 false 的写法
local value = input
if value == nil then
  value = default
end
```

> **关键区别：** `if x then` 只能用来判断 `x` 是否为 `nil` 或 `false`，不能用来判断"值是否为空/有意义"。需要根据具体类型做针对性检查。

## 核心要点

只有 `false` 和 `nil` 是假值。`0`、`""`、`{}` 以及函数都是真值。又因为 `false` 是假值，
以 `or` 结尾的表达式保不住它——要用 `if` 显式检查 `nil`。
