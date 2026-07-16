# 08 — 协程（Coroutines）

> **阶段**：C（并发与运行时特性）
> **前置知识**：第 07 章 — 错误处理
> **预计时间**：2–3 小时阅读 + 3–5 小时练习
> **Lua 版本**：5.1、5.3、5.4、LuaJIT（差异已标注）

---

## 学习目标

完成本章后，你将能够：

1. **创建和管理协程**，掌握其完整生命周期（创建 → resume → yield → dead）
2. **使用 `coroutine.wrap`** 实现迭代器风格的协程接口
3. **构建协作式任务调度器**
4. **理解 yield/resume 语义**，包括值传递和错误传播
5. **识别协程陷阱**，包括 C 边界 yield 和资源泄漏

---

## 什么是协程？

协程是**协作式执行单元** —— 它们自愿运行，在显式点让出控制权。与线程不同，协程由程序调度，而非操作系统。

关键特性：
- **协作式**：必须显式 yield；没有抢占
- **非对称**：yield 暂停；resume 继续
- **有栈**：每个协程拥有自己的调用栈
- **轻量级**：比操作系统线程成本低得多

---

## 协程生命周期

```lua
local co = coroutine.create(function()
  for i = 1, 3 do
    coroutine.yield(i)  -- 暂停并返回 i
  end
  return "done"  -- 最终返回值
end)

-- 状态："suspended" → "running" → "suspended" → ... → "dead"
print(coroutine.status(co))  -- "suspended"

print(coroutine.resume(co))  -- true  1
print(coroutine.status(co))  -- "suspended"

print(coroutine.resume(co))  -- true  2
print(coroutine.resume(co))  -- true  3
print(coroutine.resume(co))  -- true  done（dead）
print(coroutine.resume(co))  -- false  cannot resume dead coroutine
```

### 状态

| 状态 | 含义 |
|------|------|
| `"suspended"` | 已创建但未启动，或已 yield |
| `"running"` | 当前正在执行 |
| `"dead"` | 已完成或出错 |

---

## 值传递

协程可以在 resume 和 yield 之间双向传递值：

```lua
-- yield 发送值出去；resume 发送值进来
local co = coroutine.create(function()
  local x = coroutine.yield("first yield")  -- 将 "first yield" 返回给 resume 调用者
  local y = coroutine.yield("second yield") -- 将 "second yield" 返回给 resume 调用者
  return x + y  -- 最终返回
end)

local _, val = coroutine.resume(co)      -- val = "first yield"
local _, val = coroutine.resume(co, 10)  -- val = "second yield"（10 作为 x 传入）
local _, val = coroutine.resume(co, 20)  -- val = 30（10 + 20）
```

### 生产者-消费者模式

```lua
local function producer()
  for i = 1, 10 do
    coroutine.yield(i)  -- 生产值
  end
end

local function consumer(prod)
  while true do
    local ok, value = coroutine.resume(prod)
    if not ok or value == nil then break end
    print("Got: " .. value)
  end
end

consumer(coroutine.create(producer))
```

---

## coroutine.wrap

`coroutine.wrap` 返回一个**函数**，调用该函数会 resume 协程。错误直接传播（不会包装成 `ok, err`）：

```lua
local co = coroutine.wrap(function()
  for i = 1, 5 do
    coroutine.yield(i * 10)
  end
end)

print(co())  -- 10
print(co())  -- 20
print(co())  -- 30
print(co())  -- 40
print(co())  -- 50
print(co())  -- ERROR: cannot resume dead coroutine
```

### wrap 与 create 对比

| 特性 | `coroutine.create` | `coroutine.wrap` |
|------|-------------------|------------------|
| 返回值 | 协程对象 | 迭代器函数 |
| 错误处理 | `resume` 返回 `false, err` | 错误直接传播 |
| 适用场景 | 完全控制 | 简单迭代 |

### 使用 wrap 实现迭代器

```lua
local function fibonacci()
  local a, b = 0, 1
  return coroutine.wrap(function()
    while true do
      coroutine.yield(a)
      a, b = b, a + b
    end
  end)
end

for i, fib in fibonacci() do
  if i > 10 then break end
  print(fib)
end
```

---

## 基于协程的调度器

协作式调度器以轮询方式运行协程：

```lua
local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new()
  return setmetatable({queue = {}, current = nil}, Scheduler)
end

function Scheduler:spawn(fn)
  local co = coroutine.create(fn)
  self.queue[#self.queue + 1] = co
  return co
end

function Scheduler:run()
  while #self.queue > 0 do
    self.current = table.remove(self.queue, 1)
    local ok, err = coroutine.resume(self.current)
    if not ok then
      print("Task error: " .. tostring(err))
    end
    -- 如果未结束则重新入队
    if coroutine.status(self.current) ~= "dead" then
      self.queue[#self.queue + 1] = self.current
    end
  end
end

-- 使用方式
local sched = Scheduler.new()
sched:spawn(function()
  for i = 1, 3 do
    print("Task A: " .. i)
    coroutine.yield()
  end
end)
sched:spawn(function()
  for i = 1, 3 do
    print("Task B: " .. i)
    coroutine.yield()
  end
end)
sched:run()
-- 输出：A1, B1, A2, B2, A3, B3
```

### 添加 sleep（超时）

```lua
function Scheduler:sleep(seconds)
  local timer = os.clock() + seconds
  while os.clock() < timer do
    coroutine.yield()  -- 等待一个 tick
  end
end

sched:spawn(function()
  print("Start")
  sched:sleep(0.1)
  print("After 0.1s")
end)
```

---

## 非对称与对称协程

Lua 使用**非对称**协程（也称为半协程）：

- **yield** 只能从协程内部调用
- **resume** 只能从外部调用

```lua
-- 非对称：内部 yield，外部 resume
local co = coroutine.create(function()
  coroutine.yield(42)  -- 必须 yield 给调用者
end)

coroutine.resume(co)  -- 必须从外部 resume
```

对称协程（某些语言提供）允许直接 yield 到任意协程。Lua 的模型需要调度器来中介。

---

## 协程模式

### 生成器

```lua
local function lines_from(file)
  return coroutine.wrap(function()
    for line in io.lines(file) do
      coroutine.yield(line)
    end
  end)
end

for line in lines_from("data.txt") do
  print(line)
end
```

### 通道（有界队列）

```lua
local function channel()
  local buffer = {}
  local producer_done = false

  local function send(value)
    buffer[#buffer + 1] = value
    coroutine.yield()  -- resume 消费者
  end

  local function receive()
    while #buffer == 0 and not producer_done do
      coroutine.yield()  -- resume 生产者
    end
    if #buffer > 0 then
      return table.remove(buffer, 1)
    end
    return nil
  end

  local function close()
    producer_done = true
  end

  return send, receive, close
end
```

### 基于协程的状态机

```lua
local function state_machine()
  local states = {}
  local current = nil

  function states.idle()
    print("State: idle")
    coroutine.yield("wait")
    return "processing"
  end

  function states.processing()
    print("State: processing")
    coroutine.yield("work")
    return "idle"
  end

  current = states.idle
  while current do
    current = current()
  end
end

local co = coroutine.create(state_machine)
coroutine.resume(co)  -- "State: idle"，返回 "wait"
coroutine.resume(co)  -- "State: processing"，返回 "work"
coroutine.resume(co)  -- "State: idle"，返回 "wait"
```

### 并行迭代

```lua
local function par_iter(...)
  local coroutines = {}
  for _, fn in ipairs({...}) do
    coroutines[#coroutines + 1] = coroutine.create(fn)
  end

  return coroutine.wrap(function()
    while true do
      local any_alive = false
      for i, co in ipairs(coroutines) do
        if coroutine.status(co) ~= "dead" then
          any_alive = true
          local ok, val = coroutine.resume(co)
          if ok and val ~= nil then
            coroutine.yield(i, val)
          end
        end
      end
      if not any_alive then break end
    end
  end)
end
```

---

## 常见陷阱

### 1. 跨 C 边界 yield

某些 C 函数不能 yield。如果协程在 C 函数内部 yield，程序会崩溃：

```lua
-- 错误：io.read 是 C 函数，不能在其中 yield
local co = coroutine.create(function()
  print(io.read())  -- 如果在内部 yield 可能崩溃
end)

-- 安全：使用 Lua 层级的 I/O 或在 C 调用之外 yield
local co = coroutine.create(function()
  local line = io.read()  -- I/O 在 yield 之前完成
  coroutine.yield(line)   -- 此处 yield 是安全的
end)
```

> **Lua 5.4 说明**：5.4 中更多 C 函数支持 yield，但并非全部。请查阅文档。

### 2. 忘记重新入队

```lua
-- 错误：yield 后协程丢失
local co = coroutine.create(function()
  for i = 1, 3 do
    print(i)
    coroutine.yield()
  end
end)

coroutine.resume(co)  -- 输出 1
-- 忘记重新入队！协程现在丢失了。
```

### 3. 错误传播

```lua
-- 协程中的错误不会传播到主线程
local co = coroutine.create(function()
  error("boom")
end)

local ok, err = coroutine.resume(co)
print(ok)   -- false
print(err)  -- boom

-- 但是：wrap() 中的错误会直接传播
local co = coroutine.wrap(function()
  error("boom")
end)
co()  -- ERROR: boom（崩溃调用者）
```

### 4. 资源泄漏

```lua
-- 永不结束的协程会持有资源
local function leaky()
  while true do
    coroutine.yield()  -- 永不返回 → 除非显式杀死，否则不会被 GC 回收
  end
end

-- 修复：添加取消机制
local function cancellable()
  local cancelled = false
  return function()
    while not cancelled do
      coroutine.yield()
    end
  end, function() cancelled = true end
end
```

### 5. 非确定性调度

```lua
-- 错误：队列顺序取决于 spawn 顺序
sched:spawn(function() print("A") coroutine.yield() print("A2") end)
sched:spawn(function() print("B") coroutine.yield() print("B2") end)
-- A, B, A2, B2 — 但如果 B 在内部 spawn A，顺序会改变

-- 修复：显式记录调度策略
```

---

## 最佳实践

### 1. 显式建模 await 点

```lua
-- 好：清晰的 yield 点
function task()
  local data = fetch_data()    -- yield 点（I/O）
  local result = process(data) -- 无 yield（CPU）
  send_result(result)          -- yield 点（网络）
end

-- 差：隐藏的 yield 点
function task()
  helper()  -- 这里哪里 yield 了？谁知道！
end
```

### 2. 保持协程状态最小化

```lua
-- 好：状态在协程外部
local function worker(state)
  while state.running do
    local item = state.queue:pop()
    if item then
      process(item)
    end
    coroutine.yield()
  end
end

-- 差：状态埋在协程内部
local function worker()
  local queue = ...  -- 这从哪来的？
  local running = true  -- 怎么停止？
end
```

### 3. 将调度器与任务逻辑分离

```lua
-- 任务代码：不感知调度器
local function my_task()
  for i = 1, 10 do
    do_work(i)
    coroutine.yield()  -- 通用 yield，不依赖调度器
  end
end

-- 调度器：处理调度策略
local sched = Scheduler.new()
sched:spawn(my_task)
sched:run()  -- 调度器决定何时运行
```

### 4. 添加超时

```lua
function Scheduler:run_with_timeout(timeout)
  local start = os.clock()
  while #self.queue > 0 do
    if os.clock() - start > timeout then
      print("Scheduler timeout")
      break
    end
    -- ... 正常运行逻辑
  end
end
```

### 5. 记录协程契约

```lua
--- 从远程 API 获取数据
-- Yields：等待网络响应
-- Resumes 时传入：响应数据
-- 错误：网络失败时
-- @return table 响应数据
function fetch_remote(url)
  -- ...
  coroutine.yield()  -- 等待响应
  return response
end
```

---

## 版本说明

### Lua 5.1

- `coroutine.wrap` 的错误直接传播
- `coroutine.yield` 完全不能跨 C 边界
- `coroutine.resume` 成功时返回 `true, values...`

### Lua 5.2/5.3

- `coroutine.resume` 多返回值时保留所有值
- `coroutine.yield` 可以跨部分 C 边界（更多函数可 yield）
- `coroutine.isyieldable(co)` 检查协程是否可以 yield

### Lua 5.4

- 更多 C 函数支持 yield（包括 `tostring`、`pcall`）
- `coroutine.close(co)` 关闭协程并运行所有 to-be-closed 变量
- yield/resume 不匹配时提供更好的错误消息

```lua
-- Lua 5.4：显式关闭协程
-- local co = coroutine.create(function()
--   local <close> resource = acquire()
--   coroutine.yield()
--   -- 关闭时释放 resource
-- end)
-- coroutine.resume(co)
-- coroutine.close(co)  -- 释放资源
```

### LuaJIT

- 协程非常高效（轻量级栈切换）
- 在某些情况下 JIT 追踪可以跨 yield/resume 边界
- 为获得最佳性能，避免在 JIT 追踪的代码内部 yield

---

## 知识检查

<details>
<summary>1. <code>coroutine.create</code> 和 <code>coroutine.wrap</code> 有什么区别？</summary>

`create` 返回协程对象；`resume` 中的错误以 `false, err` 形式返回。`wrap` 返回函数；错误直接传播给调用者。
</details>

<details>
<summary>2. resume 和 yield 之间值如何流动？</summary>

`resume(co, v1, v2)` 将 v1、v2 发送到协程内部。内部 `coroutine.yield(x, y)` 将 x、y 发送回 resume 调用者。第一次 `resume` 将值作为协程函数的参数传入。
</details>

<details>
<summary>3. 为什么不能跨所有 C 函数调用进行 yield？</summary>

C 函数没有可以被挂起的 Lua 栈。Lua 只能在 Lua 层级的调用边界 yield。某些 C 函数（在 5.2+ 中）被显式标记为可 yield。
</details>

<details>
<summary>4. 如果协程出错且你使用了 <code>wrap</code>，会发生什么？</summary>

错误会直接传播给 wrap 函数的调用者，就像普通函数错误一样。它不会被捕获 —— 会崩溃调用者，除非调用者使用 pcall。
</details>

<details>
<summary>5. 如何停止一个永远循环的协程？</summary>

没有内置的取消机制。设置一个标志（共享的 upvalue 或 table 字段），协程每次迭代检查它。或者使用 `coroutine.close`（5.4+）来强制关闭。
</details>

---

## 关键要点

- **协作式**：协程自愿 yield；没有抢占
- **非对称**：内部 yield，外部 resume
- **值传递**：resume 发送值进来，yield 发送值出去
- **调度器**：每次 yield 后轮询重新入队
- **wrap 与 create**：wrap 用于迭代，create 用于完全控制
- **C 边界**：不能在大多数 C 函数内部 yield
- **错误处理**：create 使用 ok/err，wrap 直接传播
- **资源管理**：添加取消标志或使用 `coroutine.close`（5.4）

---

## 练习

### 初级（30–60 分钟）

1. **斐波那契生成器**：创建一个协程，无限 yield 斐波那契数。消费前 20 个。

2. **倒计时**：编写一个协程，从 N 到 0 yield 剩余秒数，然后返回 "done"。

3. **批处理器**：使用协程按 N 个一批处理项目，批次之间 yield。

### 中级（1–2 小时）

4. **协作式调度器**：构建一个包含 `spawn`、`run` 和 `sleep`（基于 tick）的调度器。并发运行 5 个任务。

5. **通道**：实现一个有界通道，包含 `send` 和 `receive`，在满/空时阻塞（yield）。

6. **管道**：创建一个 3 阶段管道（解析 → 转换 → 验证），每个阶段是一个协程。数据通过通道流动。

### 高级（2–4 小时）

7. **协程池**：构建一个工作池，将任务分配到 N 个协程中并实现负载均衡。

8. **事件循环**：使用协程实现一个最小事件循环，处理定时器、I/O 就绪和通道消息。

---

## 示例代码

本章可运行的示例：
- `examples/intermediate/03-coroutine-scheduler.lua` — 完整的协作式调度器
- `examples/beginner/01-moving-average.lua` — 基于协程的流处理

---

## 延伸阅读

- [Lua 5.4 参考手册 — 第 2.6 节](https://www.lua.org/manual/5.4/manual.html#2.6)
- [Lua 程序设计（第 4 版）— 第 9、24 章](https://www.lua.org/pil/)
- [下一章：09 — 标准库](09-standard-library.md)
