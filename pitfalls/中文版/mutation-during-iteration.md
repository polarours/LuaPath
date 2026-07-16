# pairs 迭代中修改 table

## 错误

在 `pairs()` 迭代过程中修改 table 的键，导致未定义行为 — 元素可能被跳过或重复。

## 复现

```lua
local t = {a = 1, b = 2, c = 3, d = 4}
for k, v in pairs(t) do
  if v % 2 == 0 then
    t[k] = nil  -- BUG：迭代中修改
  end
end
-- 结果未定义：可能跳过元素或崩溃
```

## 为什么是错的

`pairs()` 使用哈希表的内部结构。迭代中修改键会破坏迭代器状态，导致跳过元素或无限循环。

## 修复

```lua
-- 先收集键，再修改
local t = {a = 1, b = 2, c = 3, d = 4}
local to_remove = {}
for k, v in pairs(t) do
  if v % 2 == 0 then
    to_remove[#to_remove + 1] = k
  end
end
for _, k in ipairs(to_remove) do
  t[k] = nil
end
```

## 核心要点

永远不要在 `pairs()` 迭代中修改 table 的键。先收集更改，再在第二遍中应用。
