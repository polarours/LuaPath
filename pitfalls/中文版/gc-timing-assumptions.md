# 假设立即垃圾回收

## 错误

假设对象在失去引用后立即被垃圾回收。

## 复现

```lua
local function create_resource()
  local data = string.rep("x", 1000000)
  return setmetatable({}, {
    __gc = function(self)
      print("Released resource")
    end,
  })
end

local r = create_resource()
r = nil
-- "Released resource" 不一定立即打印！
-- GC 时机不确定
```

## 为什么是错的

Lua 使用增量垃圾回收，不会在每次失去引用时立即回收。GC 时机取决于分配率、堆大小和 GC 参数。

## 修复

```lua
-- 不要依赖 __gc 进行确定性清理
local r = create_resource()
r:close()  -- 显式清理，不要依赖 GC

-- 如需强制回收
collectgarbage("collect")  -- 但这仍不保证 __gc 立即运行

-- __gc 回调在对象被回收时运行，但时机不确定
```

## 核心要点

不要依赖 `__gc` 进行确定性资源清理。使用显式 `close()` 方法。GC 时机是不确定的。
