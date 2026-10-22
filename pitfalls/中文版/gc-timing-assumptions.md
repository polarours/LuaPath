# 假设立即垃圾回收

## 错误

假设对象在失去引用后立即被垃圾回收。

```lua
local function create_temp()
  local data = {}
  for i = 1, 10000 do
    data[i] = string.rep("x", 1000)
  end
  return data -- 调用方必须自己持有引用
end

local function process()
  for i = 1, 50 do
    create_temp() -- 返回值被丢弃，但 GC 还没有回收它
    -- 堆会不断攀升，直到回收器追上来
  end
end

process()
print(collectgarbage("count")) -- 内存占用可能偏高
```

更糟的做法，是把 `collectgarbage()` 当成同步点：

```lua
local obj = setmetatable({}, { __gc = function(self)
  print("cleaning up")
end})

obj = nil
collectgarbage("collect")
-- 在 Lua 5.2 及之后的版本上，终结器到这里已经执行过了。
-- 而在 Lua 5.1 和 LuaJIT 上，表格根本没有终结器，所以永远不会有输出。
```

## 复现

丢掉最后一个引用并不会当场执行终结器：

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

Lua 5.1 基线上唯一存在的终结器属于用户数据——文件句柄就是最常见的例子：

```lua
local handle = assert(io.open("resource.tmp", "w"))
handle:write("data")
handle = nil
-- 句柄要等 GC 轮到它时才会被关闭，而不是在这里。
collectgarbage("collect")
```

## 为什么是错的

Lua 使用增量垃圾回收，不会在每次失去引用时立即回收。GC 时机取决于分配率、堆大小和 GC 参数。

这是一个增量运行的标记-清除（mark-and-sweep）回收器，几个关键事实：

- 把引用置为 `nil` **不会**立即释放对象
- `collectgarbage("collect")` 会触发一次完整回收，但回收器不一定在那一轮里就轮到该对象
- **在 Lua 5.1 中，只有用户数据才有终结器。** 带 `__gc` 元表的表格从来不会被终结。
  Lua 5.2 才给表格加上终结器；LuaJIT 至今仍遵循 5.1 的规则
- 在 Lua 5.4 及之后的版本上，一次 `collectgarbage("collect")` 就会执行挂起的终结器；
  而在 Lua 5.2 和 5.3 上可能还需要再来一轮
- 已终结的对象会多存活一个 GC 周期，才真正被回收

## 修复

要让资源清理可预期，就使用显式的生命周期管理：

```lua
local resource = {
  data = {},
  close = function(self)
    self.data = nil
  end,
}

-- 显式清理
resource:close()
resource = nil
```

如果确实要用到终结器，就得把它的延迟算进去——而且要看版本，因为在 Lua 5.1 和 LuaJIT 上
表格的终结器根本不会执行：

```lua
local obj = setmetatable({}, {
  __gc = function(self)
    print("finalizer runs later, not now")
  end,
})

obj = nil
collectgarbage("collect")
-- Lua 5.4 及之后：终结器到这里已经执行过了。
-- Lua 5.2 和 5.3：可能还需要再来一轮。
-- Lua 5.1 和 LuaJIT：表格没有终结器，永远不会执行。
```

主动监控内存：

```lua
local function mem_usage()
  local kb = collectgarbage("count")
  return string.format("%.1f MB", kb / 1024)
end

print("before:", mem_usage())
-- ... 分配大量对象 ...
collectgarbage("collect")
print("after:", mem_usage())
```

## 核心要点

不要依赖 GC 时机来保证正确性，也不要依赖 `__gc` 做确定性资源清理。对有限资源（文件、套接字、FFI 分配的内存）使用显式的 `close()`/`dispose()` 模式。`collectgarbage()` 只是提示，不是保证——还要记住，在 Lua 5.1 和 LuaJIT 上只有用户数据会被终结。
