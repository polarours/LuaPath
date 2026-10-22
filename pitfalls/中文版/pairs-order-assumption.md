# 依赖 pairs 迭代顺序

## 错误

假设 `pairs` 的迭代顺序是确定的（如插入顺序或字母顺序）。

```lua
local config = {
  host = "localhost",
  port = 8080,
  debug = true,
}

for key, value in pairs(config) do
  print(key, value)
end
-- 输出顺序在不同运行之间、也不同 Lua 版本之间都会变化
```

更糟的是，在序列化时也假设顺序：

```lua
local config = { host = "localhost", port = 8080, debug = true }

local function serialize(t)
  local parts = {}
  for k, v in pairs(t) do
    table.insert(parts, k .. "=" .. tostring(v))
  end
  return table.concat(parts, ", ")
end

-- 顺序没有保证。它在不同 Lua 版本之间不同，表被修改后也可能改变：
serialize(config) -- 在 Lua 5.1 上是 "host=localhost, port=8080, debug=true"
serialize(config) -- 在 Lua 5.5 上是 "debug=true, host=localhost, port=8080"

-- 同一次运行里两次调用确实一致，但同样没有任何承诺。
```

## 复现

普通 table 没有固定的迭代顺序：

```lua
local config = {host = "localhost", port = 8080, debug = true}

-- 顺序可能在不同运行中变化！
for k, v in pairs(config) do
  print(k, v)
end
```

## 为什么是错的

`pairs` 遍历的是 table 的**哈希部分**。哈希部分内部就是一个哈希表，所以迭代顺序取决于：

- 哈希函数的实现
- 插入顺序
- 之前发生过的删除
- Lua 版本（5.1 与 5.3/5.4 的差异）

换句话说，`pairs` 的顺序取决于哈希函数和内部实现，不同 Lua 版本/实现可能不同。官方文档从未对迭代顺序做出任何保证。

## 修复

使用显式的顺序：要么单独维护一个键数组，要么改用 `ipairs`：

```lua
local config = {
  host   = "localhost",
  port   = 8080,
  debug  = true,
}

local order = { "host", "port", "debug" }

for _, key in ipairs(order) do
  print(key, config[key])
end
-- 永远按 host、port、debug 的顺序打印
```

如果要序列化，就构建一个排好序的键列表：

```lua
local function serialize(t)
  local keys = {}
  for k in pairs(t) do
    keys[#keys + 1] = k
  end
  table.sort(keys)

  local parts = {}
  for _, k in ipairs(keys) do
    parts[#parts + 1] = k .. "=" .. tostring(t[k])
  end
  return table.concat(parts, ", ")
end
```

## 核心要点

`pairs` 不保证顺序：`pairs` 给你的是**全部**键，而不是**有序**的键。当顺序有影响时，请维护一份显式的键列表，或者在遍历前先排序。
