# 依赖 pairs 迭代顺序

## 错误

假设 `pairs` 的迭代顺序是确定的（如插入顺序或字母顺序）。

## 复现

```lua
local config = {host = "localhost", port = 8080, debug = true}

-- 顺序可能在不同运行中变化！
for k, v in pairs(config) do
  print(k, v)
end
```

## 为什么是错的

`pairs` 使用哈希表迭代，顺序取决于哈希函数和内部实现，不同 Lua 版本/实现可能不同。

## 修复

```lua
-- 如果需要确定顺序，先排序键
local config = {host = "localhost", port = 8080, debug = true}
local keys = {}
for k in pairs(config) do keys[#keys + 1] = k end
table.sort(keys)

for _, k in ipairs(keys) do
  print(k, config[k])
end
```

## 核心要点

`pairs` 不保证顺序。如需确定顺序，请显式排序键。
