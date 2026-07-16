# Metamethod 递归

## 错误

在 `__index` 或 `__newindex` 中不使用 `rawget`/`rawset`，导致无限递归。

## 复现

```lua
-- __newindex 无限递归
local t = {}
setmetatable(t, {
  __newindex = function(self, k, v)
    self[k] = v  -- 触发 __newindex → 无限递归！
  end,
})

-- __index 无限递归
local t = setmetatable({}, {
  __index = function(self, k)
    return self[k]  -- 触发 __index → 无限递归！
  end,
})
```

## 为什么是错的

`self[k]` 会再次触发对应的 metamethod，形成无限循环。

## 修复

```lua
-- 使用 rawset
local t = {}
setmetatable(t, {
  __newindex = function(self, k, v)
    rawset(self, k, v)  -- 直接写入，不触发 __newindex
  end,
})

-- 使用 rawget
local t = setmetatable({}, {
  __index = function(self, k)
    return rawget(self, k)  -- 直接读取，不触发 __index
  end,
})
```

## 核心要点

在 metamethod 中始终使用 `rawget`/`rawset` 避免递归。
