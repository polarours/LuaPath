# 元方法递归

## 错误

定义调用自身的 `__index` 或 `__newindex`，导致无限递归。

```lua
-- 无限递归！
local t = setmetatable({}, {
  __index = function(self, k)
    return self[k]  -- 再次调用 __index！
  end
})
```

## 为什么失败

当 `self[k]` 被求值时，Lua 在 `self` 中查找 `k`。如果未找到，会再次用相同的 `k` 调用 `__index`，形成无限循环。

## 修复方法

```lua
-- 使用 rawget 绕过元方法
local t = setmetatable({}, {
  __index = function(self, k)
    return rawget(self, k)  -- 直接访问 table
  end
})

-- 或使用独立的 data table
local data = {}
local t = setmetatable({}, {
  __index = function(self, k)
    return data[k]
  end
})
```

## 相关概念

- [05-metatables.md](../zh/05-metatables.md) — 元表与元方法
- [10-lua-internals.md](../zh/10-lua-internals.md) — Lua 内部机制
