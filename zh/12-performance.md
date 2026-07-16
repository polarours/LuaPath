# 12 — 性能

> **阶段**：E（性能与生产设计）
> **前置要求**：第 11 章 — Lua C API
> **预计时间**：2–3 小时阅读 + 3–5 小时练习
> **Lua 版本**：5.1、5.3、5.4、LuaJIT（差异已标注）

---

## 学习目标

完成本章后，你将能够：

1. **对 Lua 代码进行性能分析**，找出真正的瓶颈（而非猜测的瓶颈）
2. **通过复用 table、字符串和闭包**来减少内存分配压力
3. **优化 table 访问模式**以获得缓存友好的性能
4. **调优垃圾回收**以权衡延迟与吞吐量
5. **利用 LuaJIT 优化**并理解哪些操作会破坏 JIT trace

---

## 先做性能分析

> **原则**：永远不要在没有测量的情况下进行优化。先做性能分析，找出瓶颈，然后再优化。

### os.clock 性能分析

```lua
local function bench(fn, iterations)
  iterations = iterations or 1000000
  local start = os.clock()
  for i = 1, iterations do fn(i) end
  local elapsed = os.clock() - start
  print(string.format("Elapsed: %.4fs (%.1f ns/op)", elapsed, elapsed / iterations * 1e9))
  return elapsed
end

bench(function(i) return i * 2 end)
```

### 使用 debug.getinfo 进行分析

```lua
local function profile_fn()
  local info = debug.getinfo(1, "S")
  print("Source: " .. info.source)
  print("Lines: " .. info.linedefined .. "-" .. info.lastlinedefined)
end
```

### 外部分析工具

- **LuaProfiler**：函数级别的性能分析
- **luatrace**：基于 trace 的性能分析
- **perf + FlameGraph**：结合 Lua 调试钩子的系统级性能分析

---

## Table 优化

### 稠密数组

```lua
-- 好：稠密数组 — 连续内存，缓存友好
local items = {}
for i = 1, 10000 do
  items[i] = i * 2
end

-- 差：稀疏 table — 使用哈希部分，缓存行为差
local items = {}
items[1] = "a"
items[10000] = "b"
-- 遍历很慢；#items 的结果未定义
```

### 预定义 Table 形状

```lua
-- 差：逐步增长（多次重新分配）
local t = {}
for i = 1, 10000 do
  t[i] = i
end

-- 好：预分配（5.3+：table.create）
local t = table.create(10000)
for i = 1, 10000 do
  t[i] = i
end

-- 好：通过构造器使用已知大小初始化
local t = {nil, nil, nil, nil, nil}  -- 5 个槽位
```

### 避免混合键类型

```lua
-- 差：强制所有访问使用哈希部分
local t = {}
t[1] = "a"
t[2] = "b"
t.name = "test"  -- 切换到哈希部分？

-- 更好：保持纯数组 table
local array = {1, 2, 3, 4, 5}
local record = {name = "test", value = 42}
```

---

## 局部变量 vs 全局变量访问

```lua
-- 慢：每次迭代都进行全局查找
for i = 1, 1000000 do
  local x = math.sin(i)  -- _ENV["math"]["sin"]
end

-- 快：局部缓存
local sin = math.sin
for i = 1, 1000000 do
  local x = sin(i)  -- VM 寄存器访问
end
```

### 缓存层级

```lua
-- 局部变量最快
local function fast()
  local sin = math.sin
  return sin(1)
end

-- 上值第二快（仍比全局快）
local sin = math.sin
local function medium()
  return sin(1)
end

-- 全局变量最慢
local function slow()
  return math.sin(1)
end
```

> **何时缓存**：仅在经过验证的热路径中使用。对冷代码进行微优化只会增加复杂性而无实际收益。

---

## 分配模式

### Table 复用

```lua
-- 差：每次调用都分配新 table
local function process(x, y)
  return {x = x, y = y, result = x + y}
end

-- 更好：复用 table
local temp = {}
local function process(x, y)
  temp.x = x
  temp.y = y
  temp.result = x + y
  return temp
end

-- 最好：零分配
local function process(x, y)
  return x, y, x + y
end
```

### 字符串构建

```lua
-- 差：O(n²) — 创建大量中间字符串
local result = ""
for i = 1, 10000 do
  result = result .. tostring(i)
end

-- 好：O(n) — 单次分配
local parts = {}
for i = 1, 10000 do
  parts[i] = tostring(i)
end
local result = table.concat(parts)
```

### 避免闭包

```lua
-- 差：每次迭代创建新闭包
for i = 1, 1000 do
  timer.after(1, function() process(i) end)
end

-- 好：通过参数共享闭包
local function make_callback(i)
  return function() process(i) end
end
for i = 1, 1000 do
  timer.after(1, make_callback(i))
end

-- 更好：尽可能完全避免闭包
for i = 1, 1000 do
  timer.after(1, process, i)  -- 作为参数传递
end
```

---

## 函数调用开销

```lua
-- 函数调用有开销 — 在热路径中应内联
local function hot_loop()
  local sum = 0
  for i = 1, 1000000 do
    sum = sum + i  -- 内联
  end
  return sum
end

-- vs. 大量函数调用的版本（更慢）
local function add(a, b) return a + b end
local function hot_loop()
  local sum = 0
  for i = 1, 1000000 do
    sum = add(sum, i)  -- 函数调用开销
  end
  return sum
end
```

### 方法调用

```lua
-- 冒号语法比点号语法有稍多开销
local obj = {value = 0}
function obj:inc() self.value = self.value + 1 end  -- self 是隐式的
function obj.inc(self) self.value = self.value + 1 end  -- 同样的事情

-- 在热循环中，考虑直接函数调用
local function inc_obj(obj)
  obj.value = obj.value + 1
end
```

---

## GC 调优

### 何时 GC 成为关键

GC 开销在以下情况变得显著：
- 高分配速率（大量短命对象）
- 大堆内存（GC 扫描更多内存）
- 对延迟敏感（GC 暂停导致掉帧）

### 调优参数

```lua
-- 查看当前设置
print(collectgarbage("getpause"))    -- 默认值：100
print(collectgarbage("getstepmul"))  -- 默认值：200

-- 低延迟设置
collectgarbage("setpause", 50)      -- 更早启动 GC
collectgarbage("setstepmul", 100)   -- 更小的步进

-- 高吞吐量设置
collectgarbage("setpause", 200)     -- 等待更久
collectgarbage("setstepmul", 400)   -- 更大的步进
```

### 分代模式（5.4）

```lua
-- 切换到分代模式（适合大量短命对象）
collectgarbage("generational")

-- 切换回增量模式
collectgarbage("incremental")
```

### 监控 GC

```lua
-- 跟踪 GC 统计信息
local before = collectgarbage("count")
-- ... 运行代码 ...
collectgarbage("collect")
local after = collectgarbage("count")
print(string.format("Heap: %.1f KB → %.1f KB", before, after))
```

---

## LuaJIT 优化

### 什么情况下 JIT trace 效果好

```lua
-- 好：简单、可预测的循环
local sum = 0
for i = 1, 1000000 do
  sum = sum + i
end

-- 好：单态函数调用
local sin = math.sin
for i = 1, 1000000 do
  local x = sin(i)
end
```

### 什么会破坏 JIT trace

```lua
-- 差：多态类型（同一 trace 中出现不同类型）
local function process(x)
  return x + 1  -- 对数字有效，对字符串会中断
end
process(1)
process("hello")  -- trace 守卫失败！

-- 差：过多函数调用
for i = 1, 1000000 do
  helper1(helper2(helper3(i)))  -- 太多调用无法内联
end

-- 差：大量元方法模式
local t = setmetatable({}, {
  __index = function(_, k) return compute(k) end
})
for i = 1, 1000000 do
  local v = t[i]  -- 每次访问都触发 __index
end
```

### FFI 性能

```lua
-- LuaJIT FFI：直接 C 访问，无封装开销
local ffi = require("ffi")
ffi.cdef[[
  typedef struct { double x, y; } Point;
  double sqrt(double x);
]]

local p = ffi.new("Point", 3.0, 4.0)
local dist = ffi.C.sqrt(p.x * p.x + p.y * p.y)  -- 直接 C 调用
```

---

## 常见陷阱

### 1. 对冷代码做微基准测试

```lua
-- 错误：对简单代码做基准测试
local start = os.clock()
local x = 1 + 1  -- 这没有意义
print(os.clock() - start)

-- 正确：对实际工作负载做基准测试
local start = os.clock()
for i = 1, 1000000 do
  process_real_data(data)
end
print(os.clock() - start)
```

### 2. 忽视分配速率

```lua
-- 这看起来很快，但会产生巨大的 GC 压力
local function hot_path()
  local t = {}
  for i = 1, 100 do
    t[i] = {x = i, y = i * 2}  -- 100 个 table + 100 个子 table
  end
  return t
end
```

### 3. 不做测量就优化

```lua
-- "我听说局部变量更快" — 但这是你的瓶颈吗？
-- 先做性能分析！也许瓶颈是 I/O，而非计算。
```

### 4. 过度缓存

```lua
-- 差：缓存所有内容只会增加复杂性
local _sin = math.sin
local _cos = math.cos
local _tan = math.tan
local _sqrt = math.sqrt
-- ... 还有 50 多个缓存值

-- 好：只缓存真正处于热路径的内容
local sin = math.sin  -- 每帧使用 1000000 次
```

### 5. 没有对 JIT 进行预热测试

```lua
-- LuaJIT 需要预热 — 前几次迭代是解释执行的
local function bench()
  local sum = 0
  for i = 1, 1000000 do
    sum = sum + i
  end
  return sum
end

-- 错误：只运行一次
bench()  -- 第一次运行很慢（解释执行）

-- 正确：先预热，再测量
bench()  -- 预热
local start = os.clock()
bench()  -- 实际测量
print(os.clock() - start)
```

---

## 最佳实践

### 1. 优化前先做性能分析

```lua
-- 始终先测量
local start = os.clock()
-- ... 热代码 ...
print("Time: " .. (os.clock() - start) .. "s")
```

### 2. 使用有代表性的工作负载

```lua
-- 使用真实数据量进行基准测试
local data = load_production_data()  -- 而不只是 {1, 2, 3}
bench(function() process(data) end)
```

### 3. 跟踪内存占用

```lua
local before = collectgarbage("count")
-- ... 代码 ...
collectgarbage("collect")
local after = collectgarbage("count")
print(string.format("Memory: %.1f KB", after))
```

### 4. 保留优化记录

```lua
-- 记录你改变了什么以及为什么
-- 之前：15ms/帧，500KB 分配/帧
-- 之后：8ms/帧，50KB 分配/帧
-- 改动：在粒子系统中复用了临时 table
```

### 5. 测量 p50 和 p95

```lua
-- 不要只测量平均值 — 还要检查尾部延迟
local samples = {}
for i = 1, 100 do
  local start = os.clock()
  -- ... 热代码 ...
  samples[i] = os.clock() - start
end
table.sort(samples)
print("p50: " .. samples[50])
print("p95: " .. samples[95])
print("p99: " .. samples[99])
```

---

## 版本说明

### Lua 5.1

- 单一数字类型（仅浮点数）
- 没有 `table.create`
- 没有原生位运算符（使用 `bit32` 库）
- GC 仅有增量模式

### Lua 5.3

- 整数运算更快（原生 int64）
- 位运算符是原生的（比 `bit32` 更快）
- `table.create` 用于预分配
- `math.type` 用于数字子类型检查

### Lua 5.4

- 分代 GC 模式（适合分配密集型工作负载）
- `__close` 用于确定性资源清理
- 整数除法略有优化

### LuaJIT

- JIT trace 对简单、可预测的代码非常快
- FFI 消除了 C 封装开销
- 某些模式会破坏 trace：多态性、大量元方法、深层调用链
- 基准测试前始终先预热

---

## 知识检查

<details>
<summary>1. 为什么 <code>table.concat</code> 在循环中比字符串拼接更快？</summary>

字符串拼接 `..` 每次迭代都会创建一个新字符串（总计 O(n²)）。`table.concat` 构建一个部分数组（O(n)），然后一次性连接它们（O(n)）。
</details>

<details>
<summary>2. 什么时候应该将全局变量缓存为局部变量？</summary>

仅在经过验证的热路径中使用。缓存会增加复杂性。先做性能分析 — 如果瓶颈不是全局查找，缓存不会有帮助。
</details>

<details>
<summary>3. 什么会破坏 LuaJIT trace 编译？</summary>

多态类型（同一代码路径中出现不同类型）、过多的函数调用、大量元方法模式以及不可预测的控制流。
</details>

<details>
<summary>4. 如何减少 GC 压力？</summary>

复用 table 而不是创建新 table。避免在热循环中进行短命分配。使用 `table.concat` 构建字符串。对分配密集型工作负载考虑使用分代 GC（5.4）。
</details>

<details>
<summary>5. 为什么 LuaJIT 基准测试前需要预热？</summary>

前几次迭代是解释执行的（不是 JIT 编译的）。预热允许 JIT 在你测量性能之前追踪并编译热循环。
</details>

---

## 核心要点

- **先做性能分析**：永远不要在没有测量的情况下优化
- **稠密数组**比哈希表在顺序访问时更快
- **局部缓存**在热路径中有帮助，但会增加复杂性
- **复用 table**以减少分配压力和 GC 暂停
- **`table.concat`**是 O(n)；循环中的字符串 `..`是 O(n²)
- **GC 调优**是延迟与吞吐量的权衡
- **LuaJIT**需要预热；避免破坏 trace 的模式
- **跟踪 p50/p95 延迟**，而非仅看平均值

---

## 练习

### 初级（30–60 分钟）

1. **局部缓存基准测试**：比较 `math.sin`（全局）与局部缓存 `sin` 在 100 万次迭代中的性能。报告加速比。

2. **字符串构建器**：比较 `..` 拼接与 `table.concat` 构建 10K 字符串的性能。测量时间和分配量。

3. **GC 监控器**：编写一个函数，在代码块前后报告堆大小。

### 中级（1–2 小时）

4. **Table 预分配**：比较逐步增长 table 与 `table.create` 构建 10 万元素数组的性能。测量时间和 GC 计数。

5. **闭包避免**：重构一个闭包密集的函数以最小化闭包创建。对前后版本进行基准测试。

6. **性能分析器**：使用 `debug.sethook` 构建一个简单的性能分析器，统计函数调用次数和每个函数的耗时。

### 高级（2–4 小时）

7. **分配分析器**：跟踪随时间变化的分配模式，找出哪些函数分配最多。

8. **GC 基准测试**：在包含 1000 万短命对象的工作负载上，比较增量 GC 与分代 GC（5.4）。测量暂停时间。

---

## 示例代码

本章的可运行示例：
- `examples/advanced/03-object-pool.lua` — Table 复用模式
- `examples/advanced/01-ecs-system.lua` — 性能感知设计

---

## 延伸阅读

- [Lua 5.4 参考手册 — 第 11 节](https://www.lua.org/manual/5.4/manual.html#11)
- [Programming in Lua（第 4 版）— 第 24–25 章](https://www.lua.org/pil/)
- [LuaJIT 性能指南](https://luajit.org/perf.html)
- [下一章：13 — 模式匹配](13-patterns.md)
