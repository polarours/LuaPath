# rawlen 与 # 运算符

## 错误

假设 `#t` 和 `rawlen(t)` 总是返回相同值。当 table 有定义 `__len` 的元表时，它们会不同。

## 复现

```lua
local t = {1, 2, 3}
setmetatable(t, {__len = function() return 99 end})

print(#t)       -- 99（使用 __len）
print(rawlen(t)) -- 3（绕过 __len）
```

## 为什么是错的

`#t` 在有 `__len` 元方法时会调用它。`rawlen(t)` 总是返回原始 table 长度，不经过元方法分派。混用它们会导致不一致的行为。

## 修复

```lua
-- 明确你需要哪个
local len = #t           -- 尊重元表
local raw_len = rawlen(t) -- 忽略元表

-- 文档化你的意图
--- 获取实际数据长度，忽略元表
local function data_length(t)
  return rawlen(t)
end
```

## 核心要点

`#t` 使用元方法；`rawlen(t)` 不使用。根据你需要元表行为还是原始数据长度来选择。
