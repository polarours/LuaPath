# 中级练习：参考解答

中级练习集的参考解答：13 道概念练习、4 个小型项目、6 道调试题与 6 道开放性设计题。
此处所有代码块均可在 Lua 5.1 至 5.5 与 LuaJIT 上运行。

---

## 练习对照表

| 章节 | 练习 |
|---------|--------|
| [元表与元方法](intermediate.md#元表与元方法) | 1 只读表代理 · 2 算术运算符重载 |
| [模块模式](intermediate.md#模块模式) | 3 带私有状态的模块 · 4 循环依赖的解决 |
| [协程与调度](intermediate.md#协程与调度) | 5 生产者-消费者流水线 · 6 协作式轮转调度器 |
| [错误处理模式](intermediate.md#错误处理模式) | 7 错误收集器 · 8 带上下文的断言 |
| [迭代器与生成器](intermediate.md#迭代器与生成器) | 9 滑动窗口迭代器 · 10 有状态生成器 |
| [字符串模式](intermediate.md#字符串模式) | 11 INI 段解析器 |
| [表操作](intermediate.md#表操作) | 12 深度合并 |
| [函数与闭包](intermediate.md#函数与闭包) | 13 偏应用 |
| [小型项目](intermediate.md#小型项目) | P1 带 TTL 的缓存系统 · P2 有限状态机 · P3 事件系统 · P4 测试框架基础 |
| [调试任务](intermediate.md#调试任务) | D1 `__index` 中的无限递归 · D2 协程饿死 · D3 模块重复初始化 · D4 共享元表被修改 · D5 闭包循环捕获 · D6 原地排序的副作用 |
| [开放性设计问题](intermediate.md#开放性设计问题) | Q1 错误处理哲学 · Q2 事件总线的内存管理 · Q3 调度器的可观测性 · Q4 配置分层 · Q5 状态机的可扩展性 · Q6 测试隔离 |

---

## 练习 1：只读表代理

**任务**：实现 `readonly(t)`，返回一个代理表：读操作透传到原表，写操作通过 `__newindex` 抛出错误。

**参考实现**：

```lua
-- 只读代理：读操作落到原表上，写操作由 __newindex 拒绝。
local function readonly(t)
  local proxy = {}
  local mt = {
    __index = t,                        -- 读操作由原表提供
    __newindex = function(_, key, value)
      error(string.format("attempt to modify a read-only table (key %q)",
        tostring(key)), 2)
    end,
    __metatable = "read-only",          -- getmetatable 拿不到真正的元表
  }
  return setmetatable(proxy, mt)
end

local r = readonly({ a = 1 })
print(r.a)                              --> 1

local ok, err = pcall(function() r.a = 2 end)
assert(not ok, "writing to a read-only table must fail")
assert(tostring(err):find("read%-only"), tostring(err))

-- 原表没有被改动。
assert(r.a == 1)
assert(getmetatable(r) == "read-only")
```

**要点**：
- 代理本身不存任何数据：`__index` 指向原表，所有读操作都是对原表的普通查找。
- 代理表始终是空的，因此**任何**赋值都会触发 `__newindex`，包括原表中已存在的键。
- 原表仍然可变，被冻结的只是交给调用方的这个视图。
- `__metatable` 隐藏了真正的元表，避免调用方通过 `getmetatable` 篡改代理。
- 用第 `2` 层抛出错误，位置指向赋值的调用方，而不是元方法本身。

## 练习 2：算术运算符重载

**任务**：构建 `Vec2` 类型，实现 `__add`、`__sub`、`__mul`（标量）和 `__eq` 元方法，`__tostring` 输出 `Vec2(x, y)` 形式。

**参考实现**：

```lua
-- Vec2：由同一个共享元表驱动的小向量类型。
local Vec2 = {}

local mt = {
  __add = function(a, b)
    return Vec2.new(a.x + b.x, a.y + b.y)
  end,
  __sub = function(a, b)
    return Vec2.new(a.x - b.x, a.y - b.y)
  end,
  __mul = function(a, b)
    -- 标量 * 向量、向量 * 标量，以及向量 * 向量
    if type(a) == "number" then return Vec2.new(a * b.x, a * b.y) end
    if type(b) == "number" then return Vec2.new(a.x * b, a.y * b) end
    return Vec2.new(a.x * b.x, a.y * b.y)
  end,
  __eq = function(a, b)
    return a.x == b.x and a.y == b.y
  end,
  __tostring = function(v)
    return string.format("Vec2(%g, %g)", v.x, v.y)
  end,
}

function Vec2.new(x, y)
  return setmetatable({ x = x, y = y }, mt)
end

local v = Vec2.new(1, 2) + Vec2.new(3, 4)
print(tostring(v))                     --> Vec2(4, 6)
assert(tostring(v) == "Vec2(4, 6)")

local d = Vec2.new(10, 20) - Vec2.new(1, 2)
assert(d.x == 9 and d.y == 18)

local scaled = Vec2.new(1, 2) * 3
assert(scaled.x == 3 and scaled.y == 6)

local scaled2 = 3 * Vec2.new(1, 2)
assert(scaled2.x == 3 and scaled2.y == 6)

assert(Vec2.new(1, 2) == Vec2.new(1, 2))
assert(Vec2.new(1, 2) ~= Vec2.new(2, 1))
```

**要点**：
- 所有实例共享同一个元表，`__eq` 因此才能生效：只有两个操作数使用同一个处理函数时 Lua 才会调用它。
- `__mul` 必须同时检查两侧：Lua 先找左操作数的处理函数，再找右操作数的，所以 `3 * v` 进入时是 `__mul(3, v)`。
- `__tostring` 同时决定 `print(v)` 和 `tostring(v)` 的输出；`%g` 对整数和浮点数都不会带上多余的 `.0`。
- 运算符总是返回**新**向量，实例实际上保持不可变。
- 只有原始比较已经不相等时才会调用 `__eq`，所以相等的向量必须是两个不同的表。

## 练习 3：带私有状态的模块

**任务**：使用揭示模块模式（revealing-module pattern）创建一个模块，导出 `get()`、`set()` 和 `reset()`，同时让底层存储在外部无法访问。

**参考实现**：

```lua
-- 揭示模块模式：底层存储留在闭包里，绝不通过返回的表暴露出去。
local function new_counter_module()
  local store = { count = 0 }          -- 私有状态

  local M = {}

  function M.get()
    return store.count
  end

  function M.set(value)
    store.count = value
    return value
  end

  function M.reset()
    store.count = 0
  end

  return M
end

local counter = new_counter_module()

counter.set(42)
assert(counter.get() == 42)
counter.reset()
assert(counter.get() == 0)

-- 外部无法触及底层存储。
assert(rawget(counter, "store") == nil)
assert(counter.store == nil)
assert(rawget(counter, "count") == nil)

-- 往导出的表上写字段不会影响私有状态。
counter.count = 999
assert(counter.get() == 0)
```

**要点**：
- 状态是模块闭包里的局部变量，只有那三个函数能访问它。
- `rawget` 可以验证：导出表上并没有藏着一个名字好猜的字段。
- 导出的表没有 `__newindex`，多余的写入只会新建字段，不影响 `store`。
- 同样的结构可以直接用作真正的模块：在 `do ... end` 块或函数里构造模块，然后 `return M`。

## 练习 4：循环依赖解决

**任务**：重构两个互相依赖的模块 `a` 和 `b`，用延迟初始化模式让两者都能无错加载，交叉引用在首次调用时解析。

**参考实现**：

```lua
-- 延迟模块注册表。模块只在函数体内去引用另一个模块，
-- 于是加载顺序就不再重要。
local registry = {}

local function register(name, factory)
  registry[name] = { factory = factory, value = nil, loaded = false }
end

local function require_module(name)
  local entry = registry[name]
  if not entry then
    error("module not found: " .. tostring(name), 2)
  end
  if not entry.loaded then
    entry.loaded = true                -- 先置位：环不会无限循环
    entry.value = entry.factory()
  end
  return entry.value
end

-- 模块 a：只有在调用 greet() 时才去引用 b。
register("a", function()
  local a = {}
  function a.name() return "a" end
  function a.greet()
    return "a greets " .. require_module("b").name()
  end
  return a
end)

-- 模块 b：只有在调用 greet() 时才去引用 a。
register("b", function()
  local b = {}
  function b.name() return "b" end
  function b.greet()
    return "b greets " .. require_module("a").name()
  end
  return b
end)

-- 两个模块都能成功加载，顺序任意。
local a = require_module("a")
local b = require_module("b")
assert(a.name() == "a")
assert(b.name() == "b")

-- 交叉引用在首次使用时解析成功。
assert(a.greet() == "a greets b")
assert(b.greet() == "b greets a")
```

**要点**：
- 循环引用写在函数体内部，所以在调用时解析，而不是在加载时解析。
- `require_module` 会缓存实例，重复查找返回的是同一张表。
- `loaded` 标志在工厂函数执行**之前**置位，这样意外的加载期环只会变成有界的递归，而不是死循环。
- 标准库里的同一思路就是 `require` 配合 `package.loaded`，再加上模块顶部的前置声明。

## 练习 5：生产者-消费者管道

**任务**：构建一个管道：生产者协程 yield 数据批次，消费者协程处理这些数据，用 `coroutine.resume` 双向传递值。

**参考实现**：

```lua
-- 生产者/消费者管道：生产者 yield 批次，消费者逐个打印元素
-- 并回传确认，于是值可以双向流动。
local function producer(total, batch_size)
  return coroutine.create(function()
    local batch = {}
    for i = 1, total do
      batch[#batch + 1] = i
      if #batch == batch_size then
        local ack = coroutine.yield(batch)
        if ack ~= "ack" then
          error("producer expected an ack, got " .. tostring(ack))
        end
        batch = {}
      end
    end
    if #batch > 0 then
      local ack = coroutine.yield(batch)
      if ack ~= "ack" then
        error("producer expected an ack, got " .. tostring(ack))
      end
    end
    return nil
  end)
end

local function consumer(prod)
  return coroutine.create(function()
    local ok, batch = coroutine.resume(prod)          -- 启动生产者
    if not ok then error(batch, 0) end

    local processed = 0
    while batch ~= nil do
      for _, item in ipairs(batch) do
        processed = processed + 1
        print("consumer processed item " .. tostring(item))
      end
      -- 同一次 resume 既确认当前批次，又取回下一批。
      local ok2, next_batch = coroutine.resume(prod, "ack")
      if not ok2 then error(next_batch, 0) end
      batch = next_batch
    end
    return processed
  end)
end

local prod = producer(10, 3)
local cons = consumer(prod)

local ok, processed = coroutine.resume(cons)
assert(ok, tostring(processed))
assert(processed == 10)
assert(coroutine.status(prod) == "dead")
assert(coroutine.status(cons) == "dead")
```

**要点**：
- `coroutine.resume(co, value)` 把 `value` 送进挂起的 `coroutine.yield`，yield 把它返回给生产者。
- 一次 `resume` 既完成确认又取回下一批，生产者会一直运行到下一次 yield。
- 管道在生产者 return 时结束：此时 `resume` 只返回 `true` 而没有载荷，消费者看到 `nil` 就停止。
- `coroutine.status` 可以确认两端都干净地结束，而不是被挂起在那里。
- 数据由生产者持有；消费者只读取批次，不修改它。

## 练习 6：协作式轮转调度器

**任务**：实现一个轮转调度器，以时间片（按 yield 次数计）运行 N 个协程，时间片用完的协程被抢占并重新入队。

**参考实现**：

```lua
-- 轮转调度器，每个任务有一个时间片（以 yield 次数计）。
local function schedule(tasks, quantum)
  local queue = {}
  for i = 1, #tasks do
    queue[i] = { name = tasks[i].name, co = coroutine.create(tasks[i].fn), used = 0 }
  end

  local tick = 0
  while #queue > 0 do
    local task = table.remove(queue, 1)   -- 取出队首任务
    tick = tick + 1

    local ok, err = coroutine.resume(task.co, tick)
    if not ok then error(err, 0) end

    if coroutine.status(task.co) == "dead" then
      -- 任务已完成：不再重新入队
    elseif task.used + 1 >= quantum then
      task.used = 0
      table.insert(queue, task)          -- 时间片用完：抢占，放到队尾
    else
      task.used = task.used + 1
      table.insert(queue, 1, task)        -- 还有时间片：继续留在队首
    end
  end
end

local log = {}
local function make_task(name, steps)
  return function()
    for _ = 1, steps do
      log[#log + 1] = name
      coroutine.yield(name)
    end
  end
end

schedule({
  { name = "a", fn = make_task("a", 3) },
  { name = "b", fn = make_task("b", 3) },
  { name = "c", fn = make_task("c", 3) },
}, 2)                                     -- 每个时间片两次 yield

print(table.concat(log, " "))

local counts = { a = 0, b = 0, c = 0 }
for _, name in ipairs(log) do counts[name] = counts[name] + 1 end
assert(#log == 9)
assert(counts.a == 3 and counts.b == 3 and counts.c == 3)

-- 每个任务的第一个时间片按轮转顺序开始。
assert(log[1] == "a" and log[3] == "b" and log[5] == "c")

-- 输出是交错的，而不是一个任务跑完再跑下一个。
local first_c, last_a
for i, name in ipairs(log) do
  if name == "c" and not first_c then first_c = i end
  if name == "a" then last_a = i end
end
assert(first_c < last_a, "the tasks must interleave")
```

**要点**：
- 队列里每个任务一项：队首运行，是否留在队首还是移到队尾由时间片决定。
- 已完成的任务直接丢弃，不再入队。
- 任务失败时 `coroutine.resume` 返回 `false, message`，调度器把它转成真正的错误抛出。
- 公平性来自时间片而不是任务数量：每个任务每轮拿到相同的 yield 预算。
- 从不 yield 的协程无法被抢占——调度器只有在协程主动交还控制权时才能拿回控制权。

## 练习 7：错误累积器

**任务**：编写 `pcall_accumulate(fns)`，对每个函数使用 `pcall` 调用，并返回每函数一条 `{ok=..., result=..., error=...}` 记录。

**参考实现**：

```lua
-- 收集每次调用的结果，而不是让一次失败中断整批任务。
local function pcall_accumulate(fns)
  local results = {}
  for i = 1, #fns do
    local ok, value = pcall(fns[i])
    if ok then
      results[i] = { ok = true, result = value }
    else
      results[i] = { ok = false, error = value }
    end
  end
  return results
end

local fns = {
  function() return 42 end,
  function() error("boom") end,
  function() return "fine" end,
  function() error({ code = 500 }) end,
}

local results = pcall_accumulate(fns)

assert(#results == 4)                    -- 整批任务扛住了所有失败
assert(results[1].ok == true and results[1].result == 42)
assert(results[2].ok == false and tostring(results[2].error):find("boom"))
assert(results[3].ok == true and results[3].result == "fine")
assert(results[4].ok == false and results[4].error.code == 500)
```

**要点**：
- `pcall` 返回 `false` 加上错误值，所以失败是数据，永远不会逃出循环。
- 错误值既可能是字符串，也可能是表；原样保留，调用方才能读取 `code`、`reason` 等字段。
- 成功与失败存在不同的字段里，成功的 `false` 或 `nil` 不会和错误混淆。
- 结果列表按位置对应：第 `i` 条永远属于 `fns[i]`。

## 练习 8：带上下文的断言

**任务**：构建 `assertf(condition, fmt, ...)`，抛出带格式化信息且包含失败断言所在文件与行号的错误。

**参考实现**：

```lua
-- 带格式化消息和调用位置的断言。
local function assertf(condition, fmt, ...)
  if condition then
    return condition
  end

  local info = debug.getinfo(2, "Sl")   -- assertf 的调用方
  local where = "unknown location"
  if info then
    where = string.format("%s:%d", info.short_src, info.currentline or 0)
  end

  local message
  if type(fmt) == "string" and select("#", ...) > 0 then
    message = string.format(fmt, ...)
  else
    message = tostring(fmt)
  end

  error(string.format("assertion failed at %s: %s", where, message), 0)
end

-- 断言通过时静默返回。
assertf(1 + 1 == 2, "arithmetic is broken")

local call_line
local ok, err = pcall(function()
  call_line = debug.getinfo(1, "l").currentline + 1
  assertf(1 == 2, "value %d must be positive", -1)
end)

assert(not ok)
assert(err:find("assertion failed at") ~= nil, err)
assert(err:find("value %-1 must be positive") ~= nil, err)
assert(err:find(":" .. call_line .. ":") ~= nil, "wrong line in: " .. err)
print(err)
```

**要点**：
- `debug.getinfo(2, "Sl")` 给出 `assertf` 的调用方：`short_src` 是文件，`currentline` 是调用所在行。
- 第 `2` 层比 `assertf` 自身高一层；第 `1` 层会指向辅助函数内部。
- `select("#", ...)` 判断是否传了额外参数，普通消息因此不会被送进 `string.format`。
- `error(msg, 0)` 保持消息原样——位置已经写在消息里了。
- 检查应放在普通的 Lua 函数里：调用方与 `assertf` 之间若隔着 C 帧，真正的源码位置就看不到了。

## 练习 9：滑动窗口迭代器

**任务**：实现 `window(xs, k)`，返回一个迭代器，依次 yield 列表上连续的 k 大小窗口。

**参考实现**：

```lua
-- 滑动窗口迭代器：每次调用返回下一个 k 大小的窗口。
local function window(xs, k)
  k = k or 1
  if k < 1 then
    error("window size must be >= 1", 2)
  end

  local n = #xs
  local i = 0

  return function()
    i = i + 1
    if i + k - 1 > n then
      return nil                        -- 没有更多窗口
    end
    local w = {}
    for j = 0, k - 1 do
      w[j + 1] = xs[i + j]
    end
    return w
  end
end

local windows = {}
for w in window({ 1, 2, 3, 4, 5 }, 3) do
  windows[#windows + 1] = w
end

assert(#windows == 3)
assert(table.concat(windows[1], ",") == "1,2,3")
assert(table.concat(windows[2], ",") == "2,3,4")
assert(table.concat(windows[3], ",") == "3,4,5")

-- 边界情况：单元素窗口，以及比列表还宽的窗口。
local single = 0
for _ in window({ 1, 2, 3 }, 1) do single = single + 1 end
assert(single == 3)

local none = 0
for _ in window({ 1, 2 }, 3) do none = none + 1 end
assert(none == 0)
```

**要点**：
- 窗口起点存放在返回闭包的上值中，迭代器自己维护位置。
- 每个窗口都是新建的表，调用方修改它不会破坏源列表。
- 窗口越过末尾时迭代器返回 `nil`，通用 for 由此结束。
- 通用 for 调用闭包时会附带两个被忽略的参数，状态全部留在上值里。
- 每个窗口的代价是 O(k)，整趟遍历为 O(n * k)。

## 练习 10：有状态生成器

**任务**：构建 `make_counter(start, step)`，返回一个函数，连续调用即可产生序列中的下一个值。

**参考实现**：

```lua
-- 生成器：每次调用返回下一个值并推进状态。
local function make_counter(start, step)
  start = start or 0
  step = step or 1

  local value = start
  return function()
    local current = value
    value = value + step
    return current
  end
end

local c = make_counter(0, 2)
assert(c() == 0)
assert(c() == 2)
assert(c() == 4)

-- 每个生成器各自持有状态。
local c1 = make_counter(0, 1)
local c2 = make_counter(100, 5)
assert(c1() == 0)
assert(c2() == 100)
assert(c1() == 1)
assert(c2() == 105)
```

**要点**：
- 可变的 `value` 被闭包捕获；每次调用先读出它，再推进它。
- 先返回当前值再更新，所以第一次调用得到的是 `start` 而不是 `start + step`。
- 两个生成器互不共享状态——每次调用 `make_counter` 都会创建新的上值。
- 同样的结构可以推广到任何序列：字符串、表项，或者过滤后的列表。

## 练习 11：INI 分节解析器

**任务**：解析包含 `[section]` 标题和 `key=value` 对的字符串，返回嵌套表 `{section = {key = value}}`。

**参考实现**：

```lua
-- 极简 INI 解析器：[section] 标题加 key = value 对。
local function parse_ini(text)
  local result = {}
  local section = nil

  for line in (text .. "\n"):gmatch("(.-)\r?\n") do
    local trimmed = line:match("^%s*(.-)%s*$")

    if trimmed ~= "" and trimmed:sub(1, 1) ~= "#" then
      local name = trimmed:match("^%[(.+)%]$")
      if name then
        section = name
        result[section] = result[section] or {}
      else
        local key, value = trimmed:match("^(%w+)%s*=%s*(.*)$")
        if key then
          if not section then
            error("key '" .. key .. "' appears before any section", 0)
          end
          result[section][key] = value
        end
      end
    end
  end

  return result
end

local cfg = parse_ini("[db]\nhost=localhost\nport=5432")
assert(cfg.db.host == "localhost")
assert(cfg.db.port == "5432")

-- 多个分节、注释和多余空格。
local cfg2 = parse_ini([[
# a comment
[db]
host = localhost
port = 5432

[cache]
ttl=60
]])
assert(cfg2.db.host == "localhost")
assert(cfg2.db.port == "5432")
assert(cfg2.cache.ttl == "60")
```

**要点**：
- 逐行循环使用 `(.-)\r?\n`，LF 和 CRLF 都能处理；末尾补一个换行是为了把最后一行也吐出来。
- `^%s*(.-)%s*$` 先把行首尾的空白去掉，再判断行的类型。
- `%[(.+)%]$` 捕获分节标题，`^(%w+)%s*=%s*(.*)$` 捕获键和值。
- 值的模式用 `(.*)` 而不是 `(.+)`，这样空值也能接受。
- 当前分节记录在局部变量里；没有分节的键会被直接拒绝，而不是悄悄落到错误的位置。

## 练习 12：深合并

**任务**：实现 `deep_merge(base, override)`，递归合并表，使 `override` 中的嵌套表合并进 `base` 的对应表，而不是替换它。

**参考实现**：

```lua
-- 递归合并：嵌套表被合并，而不是被替换。
-- 就地合并进 base 并返回它。
local function deep_merge(base, override)
  for key, value in pairs(override) do
    if type(value) == "table" then
      if type(base[key]) == "table" then
        deep_merge(base[key], value)     -- 两侧都是表：递归合并
      else
        base[key] = value                -- 没有表可合并：直接取新值
      end
    else
      base[key] = value
    end
  end
  return base
end

local base = { a = 1, b = { c = 2 } }
local merged = deep_merge(base, { b = { d = 3 } })

assert(merged.a == 1)
assert(merged.b.c == 2)
assert(merged.b.d == 3)

-- override 里的非表值覆盖 base 里的值。
local cfg = deep_merge({ port = 80, debug = false }, { port = 5432 })
assert(cfg.port == 5432 and cfg.debug == false)
```

**要点**：
- 合并逻辑由 `type(value) == "table"` 驱动：只有表才递归合并，其余一律覆盖。
- 合并是就地进行的，`base` 会被更新并返回；需要保留原表时请先自行复制。
- `override` 中的表在 `base` 里没有对应项（或对应项不是表）时，会整体赋值过去。
- 来自 `override` 的值是按引用共享的——如果调用方之后可能修改它们，应当先深拷贝。
- 递归深度取决于数据的嵌套层数，循环引用的表会导致无限递归。

## 练习 13：偏应用

**任务**：实现 `partial(fn, ...)`，返回一个预先绑定了前导参数的新函数。

**参考实现**：

```lua
-- 偏应用：绑定函数的前导参数。
local unpack = unpack or table.unpack      -- 5.1 是全局，5.2+ 在 table 里

local function partial(fn, ...)
  local bound = { ... }
  local bound_count = select("#", ...)      -- 用计数保住末尾的 nil

  return function(...)
    local args = {}
    for i = 1, bound_count do
      args[i] = bound[i]
    end

    local extra = { ... }
    local extra_count = select("#", ...)
    for i = 1, extra_count do
      args[bound_count + i] = extra[i]
    end

    return fn(unpack(args, 1, bound_count + extra_count))
  end
end

local add = partial(function(a, b) return a + b end, 10)
assert(add(5) == 15)

local greet = partial(string.format, "Hello, %s!")
assert(greet("Ada") == "Hello, Ada!")

local join3 = partial(function(a, b, c) return a .. b .. c end, "x", "y")
assert(join3("z") == "xyz")
```

**要点**：
- 绑定的参数存放在返回闭包的上值里；每次调用再把新参数追加上去。
- `select("#", ...)` 统计参数个数，末尾的 `nil` 不会像 `{...}` 那样丢失。
- `unpack(args, 1, n)` 恰好传出 `n` 个值，参数列表里的 `nil` 空位得以保留。
- `local unpack = unpack or table.unpack` 兼容了 5.1 的全局函数和 5.2+ 的 table 字段。
- 结果是一个普通函数：可以保存、传递，也可以与其他偏应用组合。

---

## 项目 1：带 TTL 的缓存系统

**任务**：构建一个键值缓存，在可配置的存活时间后驱逐条目 —— `Cache.new(ttl_seconds)`、`cache:get(key)`、`cache:set(key, value)`、`cache:cleanup()`、`cache:keys()`。

**参考实现**：

```lua
-- 项目 1：带存活时间的缓存。
-- 每个条目存储为 {value = ..., created = ...}；当 os.time() - created >= ttl 时条目过期。

local Cache = {}
Cache.__index = Cache

--- 创建一个条目存活 ttl_seconds 的缓存。
-- @param ttl_seconds 条目保持有效的秒数
-- @return 带有 get/set/cleanup/keys 的缓存表
function Cache.new(ttl_seconds)
  assert(type(ttl_seconds) == "number" and ttl_seconds > 0,
         "ttl_seconds must be a positive number")
  return setmetatable({ entries = {}, ttl = ttl_seconds }, Cache)
end

--- 返回 key 对应的值；键不存在或已过期时返回 nil。
-- @param key 缓存键
-- @return 存储的值或 nil
function Cache:get(key)
  local entry = self.entries[key]
  if entry == nil then
    return nil
  end
  if os.time() - entry.created >= self.ttl then
    self.entries[key] = nil            -- 访问时顺手丢弃过期条目
    return nil
  end
  return entry.value
end

--- 存储 value，并重新开始计时。
-- @param key 缓存键
-- @param value 要存储的值
-- @return 缓存自身
function Cache:set(key, value)
  self.entries[key] = { value = value, created = os.time() }
  return self
end

--- 删除所有过期条目。
-- @return 被删除的条目数
function Cache:cleanup()
  local now = os.time()
  local removed = 0
  for key, entry in pairs(self.entries) do
    if now - entry.created >= self.ttl then
      self.entries[key] = nil
      removed = removed + 1
    end
  end
  return removed
end

--- 返回仍然有效的键（已排序）。
-- @return 有效键的数组
function Cache:keys()
  local now = os.time()
  local keys = {}
  for key, entry in pairs(self.entries) do
    if now - entry.created < self.ttl then
      keys[#keys + 1] = key
    end
  end
  table.sort(keys)
  return keys
end

-- 测试。os.time() 的分辨率是一秒，因此用可控的时钟替换它，而不是 sleep。
local real_time = os.time
local now = 1000
os.time = function() return now end

local cache = Cache.new(10)
cache:set("a", 1)
cache:set("b", 2)

assert(cache:get("a") == 1)
assert(cache:get("missing") == nil)
assert(table.concat(cache:keys(), ",") == "a,b")

now = now + 5                              -- 仍然新鲜
assert(cache:get("a") == 1)

now = now + 5                              -- 已存在 10 秒：过期
assert(cache:get("a") == nil)
assert(cache:get("b") == nil)
assert(#cache:keys() == 0)

-- cleanup() 批量删除过期条目
cache:set("c", 3)
now = now + 20
assert(cache:cleanup() == 1)
assert(#cache:keys() == 0)

-- set() 会重置已有键的存活时间
cache:set("d", 4)
now = now + 9
cache:set("d", 5)
now = now + 2
assert(cache:get("d") == 5)

os.time = real_time
print("cache: all tests passed")
```

**要点**：
- 每个条目都是 `{value = ..., created = ...}`；TTL 是缓存的属性而不是条目的属性，所以同一个 `Cache` 实例可以换一个 `ttl_seconds` 重新创建。
- 过期检查出现在三处：访问时（`get`）、批量清理时（`cleanup`）、列举时（`keys`）。即使从不调用 `cleanup`，过期条目也不会被交出去。
- `os.time()` 的分辨率是一秒 —— 小于一秒的 `ttl` 无法被观测；如果需要亚秒精度，请改用 `os.clock()`。
- `set` 会整体覆盖条目，于是 `created` 被重置，TTL 随之刷新。
- 在 `pairs` 迭代中删除条目在这里是安全的：只把已有字段置为 `nil`，这正是手册明确允许的用法。

---

## 项目 2：有限状态机

**任务**：实现一个通用的 FSM 库 —— `FSM.new(states, initial)`、`fsm:transition(event)`、`fsm:current()` —— 对无效转换抛出错误。

**参考实现**：

```lua
-- 项目 2：表驱动的有限状态机。
-- states 把状态名映射到「事件 -> 下一状态」的表。

local FSM = {}
FSM.__index = FSM

--- 创建一个状态机。
-- @param states 表：状态名 -> {事件 = 下一状态}
-- @param initial 初始状态名
-- @return 带有 current/transition 的 fsm 表
function FSM.new(states, initial)
  assert(type(states) == "table", "states must be a table")
  assert(states[initial] ~= nil, "unknown initial state: " .. tostring(initial))
  return setmetatable({ states = states, state = initial }, FSM)
end

--- 状态机当前所处的状态名。
-- @return 状态名
function FSM:current()
  return self.state
end

--- 把一个事件作用到当前状态。
-- @param event 事件名
-- @return 新的状态名
function FSM:transition(event)
  local allowed = self.states[self.state]
  local next_state = allowed and allowed[event]
  if next_state == nil then
    error(string.format("invalid transition: event %q is not allowed in state %q",
                        tostring(event), tostring(self.state)), 2)
  end
  self.state = next_state
  return self.state
end

-- 测试：idle -> loading -> done | error，事件为 start/finish/fail/retry。
local fsm = FSM.new({
  idle    = { start = "loading" },
  loading = { finish = "done", fail = "error" },
  done    = {},
  error   = { retry = "idle" },
}, "idle")

assert(fsm:current() == "idle")
assert(fsm:transition("start") == "loading")
assert(fsm:current() == "loading")
assert(fsm:transition("finish") == "done")
assert(fsm:current() == "done")

-- 当前状态不接受的事件会抛出错误。
local ok, err = pcall(function() fsm:transition("start") end)
assert(not ok)
assert(tostring(err):find("invalid transition", 1, true) ~= nil)

-- error 状态与 retry 事件。
local fsm2 = FSM.new({
  idle    = { start = "loading" },
  loading = { finish = "done", fail = "error" },
  done    = {},
  error   = { retry = "idle" },
}, "idle")
fsm2:transition("start")
assert(fsm2:transition("fail") == "error")
assert(fsm2:current() == "error")
assert(fsm2:transition("retry") == "idle")

-- 未知的初始状态在创建状态机时就被拒绝。
assert(not pcall(function() FSM.new({ idle = {} }, "missing") end))

print("fsm: all tests passed")
```

**要点**：
- 转换表就是纯数据：`states[state][event] = next_state`。新增一个状态或事件意味着新增一条表项，而不是改代码。
- `transition` 是唯一的状态修改点，所以「当前在哪个状态」和「这次转换是否合法」都由同一处回答。
- 错误以第 `2` 层抛出，指向的是 `transition` 的调用方，而不是库内部。
- 映射到 `nil` 的事件即非法事件；空表表示的状态（`done = {}`）是合法的终止状态。
- `current()` 只返回状态名 —— 以后要加 `on_enter`/`on_exit` 回调，只需把它们挂到状态表上，不必改动 API。

---

## 项目 3：事件系统

**任务**：构建一个支持通配符的发布-订阅事件总线 —— `EventBus.new()`、`bus:on(pattern, handler)`、`bus:emit(event, ...)`、`bus:off(pattern, handler)` —— 其中 `"user.*"` 匹配 `"user.created"`。

**参考实现**：

```lua
-- 项目 3：发布/订阅事件总线。
-- 模式要么是精确的事件名（"user.created"），要么是带末尾通配符的事件名
-- （"user.*"、"*"），后者匹配所有以星号之前部分开头的事件。

local EventBus = {}
EventBus.__index = EventBus

--- 创建一个空事件总线。
-- @return 带有 on/off/emit 的总线表
function EventBus.new()
  return setmetatable({ subscriptions = {} }, EventBus)
end

--- pattern 是否覆盖 event？
-- @param pattern 订阅模式
-- @param event 事件名
-- @return 布尔值
local function matches(pattern, event)
  if pattern == event then
    return true
  end
  if pattern:sub(-1) == "*" then
    local prefix = pattern:sub(1, -2)       -- "user.*" -> "user."
    return event:sub(1, #prefix) == prefix
  end
  return false
end

--- 把 handler 订阅到某个模式。
-- @param pattern 订阅模式
-- @param handler 以 handler(event, ...) 形式调用的函数
-- @return handler 本身，便于之后传给 off()
function EventBus:on(pattern, handler)
  assert(type(pattern) == "string", "pattern must be a string")
  assert(type(handler) == "function", "handler must be a function")
  table.insert(self.subscriptions, { pattern = pattern, handler = handler })
  return handler
end

--- 取消订阅。
-- @param pattern 要移除的模式
-- @param handler 要移除的 handler；为 nil 时移除该模式下的全部 handler
-- @return 被移除的订阅数
function EventBus:off(pattern, handler)
  local kept = {}
  local removed = 0
  for _, sub in ipairs(self.subscriptions) do
    if sub.pattern == pattern and (handler == nil or sub.handler == handler) then
      removed = removed + 1
    else
      kept[#kept + 1] = sub
    end
  end
  self.subscriptions = kept                  -- 丢弃旧表，于是不会残留
  return removed                             -- 任何 handler 引用
end

--- 按订阅顺序把事件分发给所有匹配的 handler。
-- @param event 事件名
-- @param ... 传给 handler 的额外参数
-- @return 被调用的 handler 数量
function EventBus:emit(event, ...)
  local called = 0
  for _, sub in ipairs(self.subscriptions) do
    if matches(sub.pattern, event) then
      sub.handler(event, ...)
      called = called + 1
    end
  end
  return called
end

-- 测试。
local bus = EventBus.new()
local log = {}

local exact = bus:on("user.created", function(event, id)
  log[#log + 1] = "exact:" .. event .. ":" .. tostring(id)
end)
local wildcard = bus:on("user.*", function(event)
  log[#log + 1] = "wild:" .. event
end)
bus:on("*", function(event)
  log[#log + 1] = "all:" .. event
end)

assert(bus:emit("user.created", 42) == 3)
assert(#log == 3)
assert(log[1] == "exact:user.created:42")   -- 保持订阅顺序
assert(log[2] == "wild:user.created")
assert(log[3] == "all:user.created")

-- 通配符不匹配其他前缀。
log = {}
assert(bus:emit("order.created") == 1)
assert(log[1] == "all:order.created")

-- off() 摘掉 handler：它不再被调用 ...
log = {}
assert(bus:off("user.*", wildcard) == 1)
assert(bus:emit("user.created", 42) == 2)
assert(log[1] == "exact:user.created:42")
assert(log[2] == "all:user.created")

-- ... 而且总线不再引用它。
assert(#bus.subscriptions == 2)

-- 不带 handler 的 off() 移除该模式下的全部订阅。
bus:on("temp", function() end)
bus:on("temp", function() end)
assert(bus:off("temp") == 2)
assert(#bus.subscriptions == 2)

print("event bus: all tests passed")
```

**要点**：
- 所有订阅放在同一个有序列表里，因此 `emit` 按*全局订阅顺序*调用 handler，而不是按模式分组。`"user.*"` 与 `"user.created"` 的 handler 会严格按注册顺序交错执行。
- 模式用简单的前缀判断来匹配：`"user.*"` 匹配 `"user.created"` 和 `"user.created.v2"`，但不匹配 `"user"`；裸模式 `"*"` 匹配所有事件。
- `on` 返回 handler，调用方可以把它交给 `off`；`off` 重建列表而不是留下空洞，所以被移除的 handler 不再被总线引用（没有泄漏）。
- `off(pattern, nil)` 移除某个模式下的全部 handler，这就是批量退订。
- `emit` 返回被调用的 handler 数量，只靠它就足以测试分发，不必去翻内部列表。
- 这里不捕获 handler 的错误：某个 handler 出错会中断本次分发。如果总线必须扛住 handler 失败，请用 `pcall` 包住调用。

---

## 项目 4：测试框架基础

**任务**：实现一个最小化的 `describe`/`it`/`assert` 测试运行器 —— `describe(name, fn)`、`it(name, fn)`、`assert.eq(a, b)`、`assert.truthy(v)`、`assert.errors(fn)`、`run_all()`。

**参考实现**：

```lua
-- 项目 4：最小化的 describe/it/assert 运行器。
-- 运行器把真正的 assert 保存在 builtin_assert 里，再用带
-- eq/truthy/errors 辅助方法的 assert 对象遮蔽它。

local builtin_assert = assert

--- 把一个值渲染成失败信息里的形式。
-- @param value 任意值
-- @return 字符串
local function show(value)
  if type(value) == "string" then
    return string.format("%q", value)
  end
  return tostring(value)
end

-- 面向学习者的断言对象。
local assert = {}

--- 断言两个值相等。
-- @param actual 被测值
-- @param expected 期望值
function assert.eq(actual, expected)
  if actual ~= expected then
    error(string.format("expected %s, got %s", show(expected), show(actual)), 2)
  end
  return true
end

--- 断言一个值为真。
-- @param value 被测值
function assert.truthy(value)
  if not value then
    error(string.format("expected a truthy value, got %s", show(value)), 2)
  end
  return true
end

--- 断言函数抛出错误，并返回该错误。
-- @param fn 必须失败的函数
-- @return 错误信息
function assert.errors(fn)
  local ok, err = pcall(fn)
  if ok then
    error("expected the function to raise an error, but it returned normally", 2)
  end
  return err
end

local suites = {}
local current

--- 把若干测试归到一个名字下面。
-- @param name 测试套件名
-- @param fn 调用 it() 的函数
function describe(name, fn)
  local suite = { name = name, tests = {} }
  suites[#suites + 1] = suite
  local previous = current
  current = suite
  local ok, err = pcall(fn)                  -- describe 体出错时不能
  current = previous                        -- 打断整轮运行
  if not ok then
    suite.tests[#suite.tests + 1] = {
      name = "describe body failed",
      fn = function() error(err, 0) end,
    }
  end
end

--- 在当前测试套件中登记一个测试。
-- @param name 测试名
-- @param fn 测试体
function it(name, fn)
  builtin_assert(current, "it() must be called inside describe()")
  current.tests[#current.tests + 1] = { name = name, fn = fn }
end

--- 运行所有已登记的测试。
-- @return 通过数、失败数
function run_all()
  local passed, failed = 0, 0
  for _, suite in ipairs(suites) do
    print(suite.name)
    for _, test in ipairs(suite.tests) do
      local ok, err = pcall(test.fn)        -- 每个测试彼此隔离
      if ok then
        passed = passed + 1
        print("  ok   " .. test.name)
      else
        failed = failed + 1
        print("  FAIL " .. test.name .. ": " .. tostring(err))
      end
    end
  end
  print(string.format("\n%d passed, %d failed", passed, failed))
  return passed, failed
end

-- 针对框架自身的测试。
describe("assert helpers", function()
  it("eq accepts equal values", function()
    assert.eq(1, 1)
    assert.eq("lua", "lua")
  end)

  it("eq reports the expected and the actual value", function()
    local ok, err = pcall(function() assert.eq("actual", "expected") end)
    builtin_assert(not ok)
    builtin_assert(tostring(err):find("expected", 1, true) ~= nil)
    builtin_assert(tostring(err):find("actual", 1, true) ~= nil)
  end)

  it("truthy accepts truthy values", function()
    assert.truthy(1)
    assert.truthy("x")
  end)

  it("truthy rejects nil and false", function()
    builtin_assert(not pcall(function() assert.truthy(nil) end))
    builtin_assert(not pcall(function() assert.truthy(false) end))
  end)

  it("errors returns the raised message", function()
    local err = assert.errors(function() error("boom") end)
    builtin_assert(tostring(err):find("boom", 1, true) ~= nil)
  end)

  it("errors fails when the function does not raise", function()
    builtin_assert(not pcall(function()
      assert.errors(function() return 1 end)
    end))
  end)
end)

describe("runner", function()
  it("collected the suites", function()
    builtin_assert(#suites >= 1)
  end)

  it("counts every test", function()
    builtin_assert(#suites[1].tests >= 1)
  end)
end)

local passed, failed = run_all()
builtin_assert(failed == 0)
builtin_assert(passed > 0)

print("test framework: all tests passed")
```

**要点**：
- `describe` 只负责收集测试，`run_all` 负责执行：测试套件体在加载时运行，测试体稍后才运行。这样登记代价很低，输出顺序也稳定。
- `it` 只能在 `describe` 内部使用；`it` 里的 `builtin_assert` 会在登记阶段就抓到误用，而不是等到运行阶段。
- `pcall` 隔离了三类失败：测试体失败、`describe` 体失败（记为一个失败的测试，而不是打断整轮运行）、断言辅助函数自身的失败。
- `assert.eq` 的失败信息先打印期望值、后打印实际值，所以一条红色测试能同时说明「想要什么」和「得到了什么」。
- 本段中 `assert` 是一个局部表，遮蔽了全局 `assert`；真正的那个被保留为 `builtin_assert`，供框架自检使用。在真实项目里，这个对象应当放在模块里，而不是全局变量里。
- `run_all` 返回两个计数器，CI 脚本据此就能在 `failed > 0` 时让构建失败。

---

## 调试题 1：`__index` 中的无限递归

**任务**：解释为什么一个索引自身表的 `__index` 会形成循环，以及正确的 `__index` 模式是什么。

**问题代码**：

```lua
local mt = {}
mt.__index = function(t, k) return t[k] end
local t = setmetatable({}, mt)
print(t.foo)  -- 栈溢出
```

**修复代码**：

```lua
-- __index 必须到别处去找键：另一张表，或者一个读取另一张表的函数。
-- 它绝不能去索引它所依附的那个对象。
local defaults = { greeting = "hello" }

local mt = {
  __index = function(_, key)
    return defaults[key]
  end,
}

local t = setmetatable({}, mt)
print(t.greeting)   --> hello
print(t.missing)    --> nil

-- __index 取表值同样可行，只要那张表不是元表本身。
local base = { a = 1 }
local mt2 = { __index = base }
local t2 = setmetatable({}, mt2)
print(t2.a)         --> 1

-- 真正的无限递归：__index 又去索引同一张表，于是元表分派永远拿不到原始值。
-- C 栈耗尽，Lua 抛出一个可被 pcall 捕获的 "stack overflow" 错误。
local function make_recursive()
  local bad = {}
  bad.__index = function(tbl, key)
    return tbl[key]
  end
  return setmetatable({}, bad)
end

local ok, err = pcall(function()
  return make_recursive().missing
end)
print(ok, err)     --> false  ... stack overflow ...
```

**原因分析**：
- 照这样写，这段代码其实根本没有递归：局部变量的作用域从声明*之后*才开始，所以表构造器里的 `mt` 仍然指向全局的 `mt`，也就是 `nil`。于是元表最终是 `__index = nil`，`print(t.foo)` 只会打印 `nil` —— 已在 Lua 5.1.5、5.4.9、5.5.1 和 LuaJIT 2.1 上验证，并不会栈溢出。
- 即使真的是自引用（`mt.__index = mt`）也不会递归。取表值的 `__index` 只会再对该表做一次查找，而 `mt` 自己没有元表，查找以 `nil` 收场。
- 真正的无限递归要求 `__index` 是一个*函数*，并且它又去索引同一张表（`__index = function(t, k) return t[k] end`）。这时元表分派会永远重新进入该元方法，C 栈被耗尽 —— Lua 把它变成可捕获的 `stack overflow` 错误，修复代码中的 `pcall` 展示了这一点。
- 正确的模式是把查找放在对象*之外*：`__index` 指向一张独立的默认表，或者是一个读取这张表的函数。只读代理和类实例都采用这个形状。
- 共享一张 `__index` 表是实现类的常规做法：`Account.__index = Account` 之所以成立，是因为 `Account` 与以它为元表的那些实例是*不同的*表。

---

## 调试题 2：协程饥饿

**任务**：一个调度器运行 3 个协程，其中一个从不 yield 并独占 CPU —— 诊断这种饥饿并提出修复方案。

**问题代码**：

```lua
-- 一个轮转调度器，但它发放时间片时没有限制时间片内部的工作量。
local progress = 0                 -- 所有任务共享：已完成的工作量

local function new_worker(name, steps)
  return coroutine.create(function()
    for step = 1, steps do
      progress = progress + 1
      coroutine.yield()
    end
  end)
end

-- 贪婪任务：它从不 yield，于是一次 resume() 调用就跑完了全部工作量，
-- 调度器中途根本拿不回控制权。
local function new_hog(work)
  return coroutine.create(function()
    for i = 1, work do
      local x = i * 2                  -- 纯计算，不 yield
    end
    progress = progress + work
  end)
end

local function run_buggy(tasks)
  local log = {}
  local queue = tasks
  while #queue > 0 do
    local task = table.remove(queue, 1)
    log[#log + 1] = string.format("slice -> %-9s (progress %d)", task.name, progress)
    local ok, err = coroutine.resume(task.co)
    if not ok then
      log[#log + 1] = task.name .. " error: " .. tostring(err)
    end
    if coroutine.status(task.co) == "dead" then
      log[#log + 1] = string.format("%-9s finished (progress %d)", task.name, progress)
    else
      log[#log + 1] = string.format("%-9s yielded (progress %d)", task.name, progress)
      table.insert(queue, task)         -- 重新入队，进入下一轮
    end
  end
  return log
end

local log = run_buggy({
  { name = "hog",      co = new_hog(200000) },
  { name = "worker-a", co = new_worker("worker-a", 2) },
  { name = "worker-b", co = new_worker("worker-b", 2) },
})

for _, line in ipairs(log) do
  print(line)
end

-- 贪婪任务拿到了第一个时间片，并在其中跑完了全部工作量，所以两个 worker
-- 直到 200000 个单位全部做完之后才拿到自己的第一个时间片。
local first_worker_slice
for _, line in ipairs(log) do
  if line:find("worker", 1, true) then
    first_worker_slice = line
    break
  end
end
assert(first_worker_slice:find("progress 200000", 1, true) ~= nil)
```

**修复代码**：

```lua
-- 修复：每个时间片都有一个指令预算。
--
-- debug.sethook() 会在协程上安装一个计数钩子：它每执行 `step` 条 VM 指令
-- 就触发一次，并且可以通过抛错误来中止该协程。这是抢占一个从不 yield 的
-- 协程的唯一办法。
--
-- LuaJIT 不会在 JIT 编译过的代码里调用调试钩子，所以这次测量先把 JIT 关掉
-- （并丢弃已编译的 trace）。在参考解释器上这个分支根本不会执行。
local jitlib = rawget(_G, "jit")
if jitlib and jitlib.off and jitlib.flush then
  jitlib.off()
  jitlib.flush()
end

local STEP = 100                -- 钩子的粒度，单位是 VM 指令
local SLOW_SLICE = 0.05         -- 挂钟看门狗，单位是秒

--- 在指令预算内恢复一个协程。
-- @param co 协程
-- @param budget 本时间片允许的指令数
-- @return ok, err, 已用指令数, 是否超出软上限
local function resume_with_budget(co, budget)
  local used = 0
  local over = false
  debug.sethook(co, function()
    used = used + STEP
    if used > budget * 2 then
      error("hard limit exceeded", 0)     -- 中止该协程
    elseif used > budget then
      over = true                          -- 用量超过了它的时间片
    end
  end, "", STEP)
  local started = os.clock()
  local ok, err = coroutine.resume(co)
  local elapsed = os.clock() - started
  debug.sethook(co)                       -- 再次摘掉钩子
  return ok, err, used, over, elapsed
end

--- 轮转运行任务，并惩罚超出预算的任务。
-- @param tasks 形如 {name = ..., co = ..., budget = ...} 的数组
-- @return 日志行、违规次数
local function run(tasks)
  local log = {}
  local queue = tasks
  local violations = 0

  while #queue > 0 do
    local task = table.remove(queue, 1)
    local ok, err, used, over, elapsed = resume_with_budget(task.co, task.budget)

    if not ok then
      violations = violations + 1
      log[#log + 1] = task.name .. ": terminated (" .. tostring(err) .. ")"
      -- 惩罚：无视预算的任务失去继续运行的资格
    elseif over or elapsed > SLOW_SLICE then
      violations = violations + 1
      task.budget = math.max(STEP, math.floor(task.budget / 2))
      log[#log + 1] = task.name .. ": over budget, budget reduced to " .. task.budget
      table.insert(queue, task)            -- 并被推到队尾
    elseif coroutine.status(task.co) == "dead" then
      log[#log + 1] = task.name .. ": finished"
    else
      table.insert(queue, task)
    end
  end

  return log, violations
end

local function new_worker(name, steps)
  return coroutine.create(function()
    for step = 1, steps do
      coroutine.yield(name .. " step " .. step)
    end
  end)
end

local function new_hog(work)
  return coroutine.create(function()
    for i = 1, work do
      local x = i * 2
    end
  end)
end

-- 频繁 yield 但每个时间片仍然烧掉大量 CPU 的任务。
local function new_greedy(work, steps)
  return coroutine.create(function()
    for step = 1, steps do
      for i = 1, work do
        local x = i * 2
      end
      coroutine.yield("greedy step " .. step)
    end
  end)
end

local log, violations = run({
  { name = "hog",      co = new_hog(200000),        budget = 2000 },
  { name = "worker-a", co = new_worker("worker-a", 2), budget = 1000000 },
  { name = "worker-b", co = new_worker("worker-b", 2), budget = 1000000 },
  { name = "greedy",   co = new_greedy(30000, 2),   budget = 50000 },
})

for _, line in ipairs(log) do
  print(line)
end
print("violations: " .. violations)

-- 贪婪任务在第一个时间片内就被终止，其他任务在它尚未结束时得以运行。
local hog_stopped = false
for _, line in ipairs(log) do
  if line:find("hog: terminated", 1, true) then
    hog_stopped = true
  end
end
assert(hog_stopped, "the hog must be stopped inside its first slice")
assert(violations >= 1)

if jitlib and jitlib.on then
  jitlib.on()                              -- 把 JIT 还回去
end
```

**原因分析**：
- `coroutine.resume` 只有在协程 yield 或结束时才会返回。一个从不 yield 的协程会把调度器*卡在一次 resume 调用内部*：此时调度器根本没有在运行，再多轮转记账也无济于事。
- 轮转的公平性是按*时间片*衡量的，不是按时间衡量。一个只发放时间片、却不限制时间片内工作量的调度器，没有任何公平性保证 —— 贪婪任务的第一个时间片里装着它 100% 的工作量，其他任务在它结束前一直被饿死。
- 检测：用 `debug.sethook(co, hook, "", count)` 在协程上安装计数钩子。钩子每 `count` 条 VM 指令触发一次，并且可以通过抛错误中止协程，这是抢占一个从不 yield 的协程的唯一办法。用 `os.clock()` 给时间片计时，则为「yield 很频繁但单次仍然很慢」的任务补上一个挂钟信号。
- 惩罚：一旦违规，要么终止该协程，要么降级它 —— 把它的量子减半并推到队尾，修复代码对 greedy 任务就是这么做的。按任务统计违规次数；反复触线的任务，问题出在任务本身，而不是调度器。
- LuaJIT 的注意事项：LuaJIT 不会在 JIT 编译过的代码里调用调试钩子，于是钩子只触发一次而不是每 `count` 条指令触发一次，预算形同虚设。因此修复代码先关掉 JIT（`jit.off()` 再加 `jit.flush()` 以丢弃已编译的 trace），并在结束时把它还回去；在参考解释器上这个分支不会执行。生产环境更好的做法是把关闭范围限定到任务的函数（`jit.off(func, true)`）。
- 局限：钩子统计的是 Lua VM 指令，因此单次长时间的 C 调用（超大的 `string.rep`、缓慢的 I/O 调用）在进程内无法被中断。对不可信的工作负载，唯一彻底的解法是把它隔离到另一个进程里。

---

## 调试题 3：模块重新初始化 bug

**任务**：模块把状态放在局部变量里；清空 `package.loaded` 后再次 `require`，状态被重置 —— `require` 对单次初始化提供了什么保证？

**问题代码**：

```lua
-- 模块把状态保存在局部变量里，于是状态与 require() 缓存的那份模块实例
-- 生命周期完全一致。
package.preload["counter"] = function()
  local count = 0
  local M = {}
  function M.increment() count = count + 1; return count end
  function M.value() return count end
  return M
end

package.loaded["counter"] = nil            -- 从干净的缓存开始
local counter = require("counter")

counter.increment()
counter.increment()
print("before reload:", counter.value())   --> 2

-- 清掉缓存项会让 require() 再次执行这个 chunk ...
package.loaded["counter"] = nil
local reloaded = require("counter")
-- ... 而模块带着全新的局部变量从头开始：
print("after reload:", reloaded.value())    --> 0  （状态没了）
print("same instance:", tostring(reloaded == counter))  --> false
```

**修复代码**：

```lua
-- 修复：把状态放在一个比 package.loaded 缓存项活得更久的注册表里。
-- 注册表存放在 _G 中，因此重新加载模块时会找到已有的状态，并返回同一个实例。
local registry = {}
rawset(_G, "__APP_STATE__", registry)

package.preload["counter"] = function()
  local M = registry["counter"]
  if M == nil then
    local count = 0
    M = {}
    function M.increment() count = count + 1; return count end
    function M.value() return count end
    registry["counter"] = M                -- 发布这个实例
  end
  return M
end

package.loaded["counter"] = nil
local counter = require("counter")
counter.increment()
counter.increment()
assert(counter.value() == 2)

-- 重新加载模块后，实例和状态都保持不变。
package.loaded["counter"] = nil
local reloaded = require("counter")
assert(reloaded == counter)                -- 同一个实例
assert(reloaded.value() == 2)              -- 状态在重新加载后依然存在
assert(reloaded.increment() == 3)          -- 并且仍然可用

-- 不持有状态的模块不需要注册表：require() 已经保证每个缓存项只执行一次
-- chunk。
package.preload["pure"] = function()
  return { hello = function() return "hi" end }
end
package.loaded["pure"] = nil
local first = require("pure")
local second = require("pure")
assert(first == second)                   -- 复用了被缓存的值

print("module state: all tests passed")
```

**原因分析**：
- `require` 只保证两件事：只要 `package.loaded[name]` 里有值，loader 最多被调用一次；loader 返回的值会被缓存并交给之后的每一次 `require`。仅此而已 —— 它是一个缓存，不是状态管理器。
- `package.loaded[name] = nil` 会移除缓存项，于是下一次 `require` 会再次执行这个 chunk。新的 chunk 意味着新的局部变量，把状态放在局部变量里的模块自然从头开始。旧实例并没有被破坏，它只是不再是「那个模块」了。
- 因此故障形态是一种*脑裂*：应用持有旧表，`require` 发出新表，混用两者的代码会看到两份不同的状态。
- 修复办法是把状态从模块的局部变量里搬到比缓存项活得更久的所有者里 —— `_G` 中的注册表、应用自己持有的表，或者任何别的长生命周期存储。模块在加载时查出状态并复用它，修复代码正是用 `registry["counter"]` 这么做的。
- 热重载流程应当显式地做同样的事：先创建新实例，把状态从旧实例复制过来，然后再替换缓存项。
- 如果模块本来就不持有状态，就完全不需要这些 —— 缓存的值会被复用，同一个模块名总是得到同一张表。

---

## 调试题 4：共享元表变异

**任务**：两个实例共享同一个元表，修改其中一个实例的元表会影响另一个 —— 找出错误并修复。

**问题代码**：

```lua
-- BUG：类表同时充当共享元表，而实例方法把逐实例的数据存进了它里面。
local Point = {}
Point.__index = Point

function Point.new(x, y)
  local self = { x = x, y = y }
  setmetatable(self, Point)              -- 所有实例共享这个元表
  return self
end

function Point:setLabel(text)
  getmetatable(self).label = text        -- 写进了共享的元表
  return self
end

function Point:describe()
  return string.format("(%s,%s) label=%s", tostring(self.x), tostring(self.y),
                        tostring(getmetatable(self).label))
end

local a = Point.new(1, 2)
local b = Point.new(3, 4)

a:setLabel("A")
print(b:describe())   -- BUG："(3,4) label=A" —— b 通过 a 被污染了
```

**修复代码**：

```lua
-- 修复 1（首选）：逐实例的数据放在实例表里，元表保持共享且只读。
local Point = {}
Point.__index = Point

function Point.new(x, y)
  return setmetatable({ x = x, y = y, label = nil }, Point)
end

function Point:setLabel(text)
  self.label = text
  return self
end

function Point:describe()
  return string.format("(%s,%s) label=%s", tostring(self.x), tostring(self.y),
                        tostring(self.label))
end

local a = Point.new(1, 2)
local b = Point.new(3, 4)

a:setLabel("A")
assert(a:describe() == "(1,2) label=A")
assert(b:describe() == "(3,4) label=nil")   -- b 未受影响
assert(getmetatable(a) == getmetatable(b))  -- 元表仍然是共享的

-- 修复 2：当元方法本身必须逐实例不同时，给实例一份自己的元表：
-- 共享元表的一份副本。
local function new_isolated(x, y)
  local meta = {}
  for k, v in pairs(Point) do meta[k] = v end    -- 复制类表
  local self = setmetatable({ x = x, y = y }, meta)
  self.setLabel = function(self, text)
    getmetatable(self).label = text             -- 只写进这个实例的副本
    return self
  end
  return self
end

local c = new_isolated(5, 6)
local d = new_isolated(7, 8)
c.setLabel(c, "C")

assert(getmetatable(c) ~= getmetatable(d))      -- 元表互相独立
assert(getmetatable(c).label == "C")
assert(getmetatable(d).label == nil)            -- d 不受影响
assert(Point.label == nil)                      -- 类表也没有被改动

print("metatable: all tests passed")
```

**原因分析**：
- 元表就是一张普通表，而 `setmetatable(self, Point)` 给每个实例的是*同一张表的引用*。写进这张表的内容，所有实例都能看到 —— 类本身也能看到。
- 错的不是共享元表本身，而是*把逐实例的数据存进元表里*。`getmetatable(self).label = text` 写的是类表，于是最后一个调用 `setLabel` 的实例的标签，成了所有实例的标签。
- 修复 1 是需要记住的规则：逐实例的状态属于实例表（`self.label = text`），元表存放行为而不是数据。这样共享元表既是正确的，也是最省的选择 —— 整个类共用一张元表。
- 修复 2 针对元方法确实必须逐实例不同的情况（不同的比较函数、逐实例的缓存）。这时实例拥有自己的元表 —— 从类复制而来 —— 修改它既不会影响类，也不会影响其他实例。
- `getmetatable(obj)` 是让这个 bug 显形的关键：两个本应互相独立的对象返回的是*同一张*元表，因此存在那里的任何东西都是共享状态。
- 同一个陷阱还会出现在把结果缓存在元表里的 `__index` 函数中，以及把实例列表存在类表里的类中。

---

## 调试题 5：闭包循环捕获

**任务**：解释在 `for` 循环体里创建的闭包究竟捕获了什么，并给出与版本无关的修复方法。

**问题代码**：

```lua
local fns = {}
for i = 1, 5 do
  fns[i] = function() return i end
end
print(fns[1](), fns[3]())  -- 打印 1, 3 —— 每次迭代都有独立的 `i`
```

**修复代码**：

```lua
-- 修复：把值绑定到循环体里一个新的局部变量上。这是可移植的写法，
-- 不依赖当前运行的是哪个 Lua 版本。
local fns = {}
for i = 1, 5 do
  local j = i
  fns[i] = function() return j end
end

assert(fns[1]() == 1)
assert(fns[3]() == 3)
assert(fns[5]() == 5)

-- 真正「闭包捕获的是变量而不是值」的 bug 与版本无关：这里所有闭包共享
-- 同一个局部变量，所以它们报出的都是最终值。
local i = 0
local shared = {}
while i < 3 do
  i = i + 1
  shared[i] = function() return i end
end
assert(shared[1]() == 3 and shared[2]() == 3 and shared[3]() == 3)

-- 这种情况的修复办法：把值取一个快照。
i = 0
local fixed = {}
while i < 3 do
  i = i + 1
  local snapshot = i
  fixed[i] = function() return snapshot end
end
assert(fixed[1]() == 1 and fixed[2]() == 2 and fixed[3]() == 3)

print("closure capture: all tests passed")
```

**原因分析**：
- 就数值 `for` 循环而言，练习中的注释是错的：这段代码打印的是 `1 3`，不是 `5 5`。已在 Lua 5.1.5、5.4.9、5.5.1 和 LuaJIT 2.1 上验证。
- Lua 5.1 手册把数值 `for` 展开为 `while ... do local v = var; <块>; var = var + step end` —— 控制变量声明在*循环体内部*，于是每次迭代都有自己的变量。Lua 5.4 手册的说法相同（"a new variable local to the loop body"），而 5.4 对数值 `for` 唯一的改动是控制变量在整数溢出时不再回绕。这里并不存在 5.1 与 5.3/5.4 的差别。
- 真正要记住的规则正是本题想考的那条：闭包捕获的是*变量*而不是值，它能看到该变量之后发生的每一次变化。与版本无关的复现方式是让多个闭包共享一个局部变量 —— 上面那个 `while` 循环，在所有测试过的版本上三个闭包都报 `3`。
- 循环体里的 `local j = i` 是到处都有效的修复：它为每次迭代创建一个新的变量（上值），其值此后不再改变。它每次迭代多花一个局部变量，当被捕获的值必须是一个快照时，就应该用这种写法。
- 同样的危险也存在于循环之外：任何被多个闭包捕获、之后又被修改的局部变量都是共享状态。要么捕获一份副本，要么捕获一张表，把逐闭包的数据放进表里。

---

## 调试题 6：原地排序的副作用

**任务**：`table.sort` 会修改传入的表，于是排序列表的函数悄悄改动了调用者的数据 —— 如何保护调用者的数据？代价是什么？

**问题代码**：

```lua
-- BUG：table.sort 是原地排序，调用者的表被重新排序了。
local function sort_by_name(items)
  table.sort(items, function(a, b) return a.name < b.name end)
  return items
end

local inventory = {
  { name = "carol" },
  { name = "alice" },
  { name = "bob" },
}

local sorted = sort_by_name(inventory)

print(inventory[1].name)   -- BUG："alice" —— 调用者的顺序没了
print(sorted[1].name)      --> "alice"
print(#inventory)          --> 3
```

**修复代码**：

```lua
-- 修复：排序之前先复制一份列表。
local function sort_by_name(items)
  local copy = {}
  for i = 1, #items do
    copy[i] = items[i]
  end
  table.sort(copy, function(a, b) return a.name < b.name end)
  return copy
end

local inventory = {
  { name = "carol" },
  { name = "alice" },
  { name = "bob" },
}

local sorted = sort_by_name(inventory)

assert(inventory[1].name == "carol")   -- 调用者的数据没有被改动
assert(inventory[2].name == "alice")
assert(sorted[1].name == "alice")      -- 排序结果是新表
assert(sorted ~= inventory)

-- 另一种方案：排序一个下标排列。数据本身完全不用复制，原始顺序也得以保留。
local function sorted_indices(items)
  local order = {}
  for i = 1, #items do
    order[i] = i
  end
  table.sort(order, function(i, j) return items[i].name < items[j].name end)
  return order
end

local order = sorted_indices(inventory)
assert(inventory[1].name == "carol")
assert(inventory[order[1]].name == "alice")
assert(#order == #inventory)

-- 另一种方案：把「会修改」这件事写进 API。
local function sort_in_place(items)
  table.sort(items, function(a, b) return a.name < b.name end)
  return items
end

local owned = { { name = "bob" }, { name = "alice" } }
sort_in_place(owned)
assert(owned[1].name == "alice")

print("sort: all tests passed")
```

**原因分析**：
- `table.sort` 会重排传入的表，它不是纯函数。排序之后再返回同一个表，意味着调用者拿到的对象与入参仍是同一个别名，两个名字指向同一张已排序的表。
- 修复代码里的复制是*浅拷贝*：元素本身仍与调用者共享。如果比较函数会修改元素，调用者的数据依然会被破坏 —— 那需要深拷贝，代价也相应更高。
- 复制的代价是每次调用 O(n) 时间和 O(n) 额外内存。`table.sort` 本身是 O(n log n)，所以对大列表而言复制只是一个常数因子，复杂度级别不变 —— 但这份开销每次调用都要付，而且列表的峰值内存会翻倍。
- 排序下标排列同样是 O(n) 内存，但不用复制数据，而且保留了原始顺序；代价是比较函数要基于下标来写，每次访问还多一层间接。
- 第三种选择是把契约写明：命名为 `sort_in_place` 的函数明确表示它会修改参数，由调用方自己持有结果引用。这样没有额外开销，但前提是每个调用方都知道这条规则。
- 无论选哪种契约，都应该让它体现在名字上：会复制的 `sort_by_name` 和会修改的 `sort_by_name_in_place` 不会被误用。

---

## 设计题 1：错误处理哲学

*模块应该返回 `nil, err` 还是抛出 `error()`？请考虑 API 人体工程学、调用者责任和可调试性。*

**解答**：

分界线是**"调用者能不能做点不一样的事？"** 如果调用者有恢复手段——重试、回退、报错给用户、跳过这条记录——就返回 `nil, err`。如果这个失败意味着"程序写错了，继续下去没有意义"，就抛出。其余情况只是风格偏好，而风格偏好在代码库里应该统一，而不是每个调用点各选各的。

`nil, err` 可以组合；`error()` 会摧毁返回值通道。返回式 API 能自然嵌套（`local v, e = parse(read(f))`），而抛出式 API 迫使每一层中间代码都用 `pcall` 包一层，只为把消息转发上去——这把数据流问题变成了控制流管道，而且用 `error(err, 0)` 重新抛出产生的是**新的**堆栈跟踪，已经不再指向最初的失败点。`pcall` 本身很便宜，真正的代价是每个调用点变成两行、每一层都变成可能篡改消息的地方。所以库应该默认返回。

在三个具体场景下 `error()` 仍然更合适。第一，**程序员错误**：参数类型不对就是 bug，在边界处立刻失败能保住堆栈跟踪，让它指向真正的元凶，而不是三层之外某个没人回溯到缺失检查的 `nil` 解引用。`assert(type(x) == "table", "x must be a table")` 正是为此准备的。第二，**被破坏的不变量**——"这里队列非空"永远不该为假，为它返回 `nil, err` 只是凭空造出第二条没人测试的代码路径。第三，**不能被忽略的失败**：被漏掉的 `if not result then` 检查会把一条清晰的错误消息变成稍后某个毫不相干的崩溃。

决定具体机制的 Lua 细节：`error(msg)` 默认是 level 1，会指向**你的模块内部**那一行——参数错误应该用 level 2 指责调用者，已经装饰过的消息应该用 level 0。`nil` 与 `false` 的区别影响失败判断：`if not result then` 会把合法的 `false` 结果也当成失败，所以要选定一种约定（`nil` 表示失败，或者 `false` 表示失败），并且不要混用。结构化错误对象能原样穿过 `pcall`，所以 `error({code = "ENOENT", ...})` 让调用者可以按机器可读的码分支——但必须加上 `__tostring` 元方法，否则消息只会渲染成 `table: 0x...`。还有，`error()` 在协程内部是**局部**的：协程死掉，`coroutine.resume` 返回 `false, err`，程序继续运行——这意味着"抛还是返回"部分取决于哪一层边界负责这次失败。

```lua
-- 同时提供两种错误风格的模块，外加一种结构化错误类型。
local M = {}

-- 软失败：调用者可以分支处理并采取不同的动作。
function M.parse(text)
  if type(text) ~= "string" or text == "" then
    return nil, "expected a non-empty string"
  end
  return { value = text }
end

-- 硬失败：契约被破坏。level 2 指向调用者，而不是本文件。
function M.parse_strict(text)
  local ok, res = M.parse(text)
  if not ok then
    error(res, 2)
  end
  return res
end

-- 结构化错误能穿过 pcall，但需要 __tostring 才能保持可读。
local Err = {}
function Err.__tostring(self)
  return self.code .. ": " .. self.message
end

function M.fail(code, message)
  error(setmetatable({ code = code, message = message }, Err), 0)
end

-- pcall 完整保留错误对象。
local ok, err = pcall(function() M.fail("ENOENT", "no such file") end)
assert(ok == false)
assert(err.code == "ENOENT")
print(tostring(err))                          --> ENOENT: no such file

-- 在协程内部，error() 是局部失败：resume 返回 false, err。
local co = coroutine.create(function() M.fail("EBADF", "bad descriptor") end)
local cok, cerr = coroutine.resume(co)
assert(cok == false)
assert(cerr.code == "EBADF")

-- 保留堆栈跟踪的边界：debug.traceback 无法转换非字符串的错误值，
-- 因此先归一化。
local function run(f)
  return xpcall(f, function(e)
    return debug.traceback(tostring(e), 2)
  end)
end
local rok, rerr = run(function() M.parse_strict(42) end)
assert(rok == false)
print(rerr)                                    -- 消息 + 堆栈跟踪
```

**实践建议**：
- 库模块内部的输入校验和查找失败返回 `nil, err`（或 `false, err`）；把 `error()`/`assert` 留给被破坏的不变量和参数类型错误。
- 参数错误用 `error(msg, 2)`，已装饰的消息用 `error(msg, 0)`；默认的 level 1 指责的是你自己的文件。
- 如果调用者需要按错误码分支，就返回带 `__tostring` 元方法的结构化错误表。
- 在边界处一次性捕获堆栈跟踪：`xpcall(f, function(e) return debug.traceback(tostring(e), 2) end)`——单用 `debug.traceback` 处理不了非字符串错误值：拿到表它就返回表本身，遇到 `nil` 错误在 5.1/LuaJIT 上直接返回 `nil`，堆栈跟踪全部丢失。
- 在协程里把 `error()` 当作局部失败，`coroutine.resume` 会把它变成 `false, err`；要明确决定由哪一层把它转回返回值。
- 库里绝不调用 `os.exit`：它会直接结束进程而不执行 `__gc` 终结器，待处理的清理随之丢失；而 `error()` 展开栈后把回收交给垃圾回收器。

## 设计题 2：事件总线内存管理

*如何设计事件总线 API 来防止 handler 泄漏？当订阅者被垃圾回收时，什么机制会清理 handler？*

**解答**：

泄漏的形状是固定的：总线强引用 handler 闭包，闭包又把订阅者作为上值捕获，于是只要总线活着，订阅者就永远无法被回收。Lua 的标记清除式垃圾回收解决不了这个问题，因为整张对象图都从总线可达，而总线通常又挂在 `package.loaded` 上——也就是说，在进程后续每一次 `require` 里它都还活着。

能修好它的立场是：**总线不拥有订阅者，订阅者拥有自己的订阅。** 总线把 handler 存进带 `__mode = "v"`（弱值）的表，这样一个 handler 只有在别处（通常是订阅者）还引用它时才活着。订阅者一旦死亡，handler 就不可达，弱表丢掉该表项，两者在同一次垃圾回收中一起被回收。不那么显然的推论是：API 必须把 handler 的强引用交还给订阅者。如果调用 `bus:on("tick", fn)` 之后立刻丢掉 `fn`，订阅项可能在下一轮回收时就凭空消失。所以 `on()` 要返回一个 token，而"只要还想保留这个订阅，就一直持有这个 token"必须写进契约里。

每种清理机制的失效方式都不同，所以生产环境的总线通常不只提供一种：
- **弱值**（`__mode = "v"`）是自动的，但受垃圾回收时机影响：已经死亡的订阅者可能在回收运行之前还收到最后一次事件。对 UI 和插件系统无所谓，对账务代码却很意外。
- **弱键**（`__mode = "k"`）适用于以订阅者对象为键的注册表。但如果 handler 的上值就是订阅者，而其他地方仍强引用着这个 handler，弱键并不能释放它。
- **显式取消订阅**是确定的，不依赖垃圾回收。对 Lua 5.1 和 LuaJIT 里的表来说，这也是唯一能统一工作的机制——那里的 `__gc` 终结器**只对用户数据生效**，表的 `__gc` 元方法根本不会被调用。如果你希望在 5.1 上基于终结器清理，订阅对象本身必须是用户数据。
- **作用域订阅**把一组 handler 绑定到某个宿主对象上，一次性关闭整个作用域——UI 页面和请求处理器通常都应该这样释放。

设计上还值得考虑另外两个 Lua 特有的泄漏源。一是 **`_ENV` 上值**：在 5.2+ 中，chunk 的环境就是普通上值，因此定义在模块顶层的 handler 会捕获该模块的环境，连带环境持有的模块级缓存或注册表一起被钉住。二是 **`package.loaded` 缓存**：模块级总线表会活过每一次重新加载和每一个测试，所以总线实例应当放在局部变量里并导出一个工厂函数，测试中则显式地 `package.loaded["bus"] = nil`。

```lua
-- 总线弱引用 handler；订阅者拥有自己的订阅。
local Bus = {}
Bus.__index = Bus

function Bus.new()
  return setmetatable({ handlers = {}, next_id = 0 }, Bus)
end

function Bus:on(event, fn)
  local list = self.handlers[event]
  if not list then
    list = setmetatable({}, { __mode = "v" })   -- 总线只弱引用 handler
    self.handlers[event] = list
  end
  self.next_id = self.next_id + 1
  local id = self.next_id
  list[id] = fn
  -- token 强引用 fn：订阅者必须持有 token，否则弱表项
  -- 可能在下次垃圾回收时消失。
  local token = { event = event, id = id, fn = fn }
  token.off = function() list[id] = nil end
  return token
end

function Bus:emit(event, ...)
  local list = self.handlers[event]
  if not list then return 0 end
  local n = 0
  for _, fn in pairs(list) do
    fn(...)
    n = n + 1
  end
  return n
end

local function attach(bus)
  local subscriber = { calls = 0 }
  subscriber.token = bus:on("tick", function()
    subscriber.calls = subscriber.calls + 1
  end)
  return subscriber
end

local bus = Bus.new()
local sub = attach(bus)
assert(bus:emit("tick") == 1)
assert(sub.calls == 1)

sub = nil                       -- 订阅者现在不可达
collectgarbage("collect")
collectgarbage("collect")       -- 闭包先死，订阅者随后
assert(bus:emit("tick") == 0)   -- 弱表项已经蒸发

-- 确定性的替代方案：完全不依赖垃圾回收。
local bus2 = Bus.new()
local sub2 = attach(bus2)
sub2.token.off()
assert(bus2:emit("tick") == 0)
```

**实践建议**：
- 每个事件用带 `__mode = "v"` 的表保存 handler，并返回持有 handler 的 token；把"持有 token"写进 `on()` 的契约。
- 提供 `token.off()` 做确定性移除；在测试和关闭路径上优先使用它。
- 不要依赖表的 `__gc`——Lua 5.1 和 LuaJIT 根本不会调用它；改用显式的 `close()` 方法或基于用户数据的订阅对象。
- 不要在 handler 里捕获模块环境（`_ENV` 上值会把模块状态钉住），也不要整个捕获 `self`，能用切片就别用整体。
- 把总线实例放在模块局部变量里并导出工厂函数；如果需要每个测试一份总线，就别把它塞进 `package.loaded`。
- 把"handler 消失了"当作正常行为而不是 bug：当订阅项可能比宿主活得久时，调用处要做保护。

## 设计题 3：调度器可观测性

*哪些指标能证明协程调度器在生产环境中是健康的？如何检测饥饿、过多的上下文切换或无界队列增长？*

**解答**：

要在三个层次埋点——时间片（一次 `coroutine.resume`）、协程（整个生命周期）、队列（调度器）——前两个导出计数器，第三个导出瞬时值。健康的调度器意味着队列深度有界、时间片延迟有界、等待时间分布公平，这三者都是能画图的数字。

第一个 Lua 特有事实决定了一切：`coroutine.resume` 是**协作式**的，因此永不 yield 的协程无法被调度器抢占——没有操作系统线程可以去打断它。限制这种失控协程的唯一办法是让它在 **debug hook** 下运行：`debug.sethook(co, hook, "", 1)` 会在那个特定线程上安装计数 hook（可选的 thread 参数在 5.1 和 LuaJIT 中都存在），在 hook 里抛出错误就会中止该协程。这把饥饿从"进程永久挂起"变成"某个协程带着预算错误死掉"——同时正好产出你需要的那个指标。hook 是按线程隔离的，所以每个协程可以有自己的指令预算而不影响其他协程。代价是性能：启用计数 hook 会让该线程留在解释器里，绕过 JIT 编译器，所以预算强制应当是调试构建或最后手段，而不是常规特性。

真正重要的指标有这些：**时间片延迟**（每次 `resume` 的墙钟时间，看 p50/p99/max，最大值就是饥饿信号）；**队列深度**（每个时间片采样一次，看最大值和趋势，深度只涨不跌说明生产速度超过了消费速度）；**每秒上下文切换次数**以及单位工作量的切换次数，切换太多说明协程切得太碎，太少则意味着单次运行时间过长、响应迟钝；**每个协程的等待时间**（距离上次被调度过去了多久），这才是真正的公平性指标——某个协程的等待时间无界增长时，即使队列很短它也在挨饿；**预算违规次数**（由 hook 计数）；**按协程 id 统计的错误数**，因为 `coroutine.resume` 返回 `false, err`，而忽略第一个返回值的调度器会把失败的协程变成无限重试循环；还有**垃圾回收的停顿开销**，因为把一次增量 GC（`collectgarbage("step")`）安排在单个时间片内，可以让延迟尖峰留在这一片的预算里，而不是拖住整个队列。

检测规则由此直接得出：饥饿是某个时间片超出墙钟预算，或触发了 hook 预算；上下文切换过多是每秒切换次数高于你在真实流量上量出来的基线；无界增长是某个窗口内深度不下降而吞吐量持平——队列根本没在排空。再加一条按协程计数的上限：连续 yield 却没有推进任何工作，也要计入。

```lua
-- 一个真正能测出生产环境问题的调度器。
local function newScheduler(opts)
  opts = opts or {}
  return {
    ready = {},                    -- 挂起协程的 FIFO 队列
    live = 0,
    stats = {
      switches = 0, errors = 0, budget_exceeded = 0,
      max_depth = 0, max_turn = 0, total_turn = 0,
    },
    quantum = opts.quantum or 10000,   -- 每个时间片允许的指令数
  }
end

local function schedule(sched, fn)
  local co = coroutine.create(fn)
  sched.live = sched.live + 1
  table.insert(sched.ready, co)
  return co
end

local function run(sched)
  while #sched.ready > 0 do
    local co = table.remove(sched.ready, 1)
    local depth = #sched.ready + 1
    if depth > sched.stats.max_depth then sched.stats.max_depth = depth end

    -- 指令预算：阻止永不 yield 的协程的唯一办法。
    local budget = sched.quantum
    debug.sethook(co, function()
      budget = budget - 1
      if budget <= 0 then
        debug.sethook(co)                  -- 展开栈之前先摘掉 hook
        error("instruction budget exceeded", 0)
      end
    end, "", 1)

    local t0 = os.clock()
    local ok, err = coroutine.resume(co)
    local elapsed = os.clock() - t0
    debug.sethook(co)

    sched.stats.switches = sched.stats.switches + 1
    sched.stats.total_turn = sched.stats.total_turn + elapsed
    if elapsed > sched.stats.max_turn then sched.stats.max_turn = elapsed end

    if not ok then
      sched.stats.errors = sched.stats.errors + 1
      if type(err) == "string" and string.find(err, "budget", 1, true) then
        sched.stats.budget_exceeded = sched.stats.budget_exceeded + 1
      end
    end

    local status = coroutine.status(co)
    if status == "dead" then
      sched.live = sched.live - 1
    elseif status == "suspended" then
      table.insert(sched.ready, co)         -- 已 yield：放回队尾
    end
  end
end

local sched = newScheduler({ quantum = 5000 })

schedule(sched, function()
  for i = 1, 10 do
    coroutine.yield(i)
  end
end)

schedule(sched, function()
  while true do end          -- 永不 yield：典型的饥饿场景
end)

run(sched)

assert(sched.stats.switches > 0)
assert(sched.stats.errors == 1)            -- 失控协程已被杀死
assert(sched.stats.budget_exceeded == 1)
assert(sched.stats.max_depth >= 1)
```

**实践建议**：
- 导出计数器（`switches`、`errors`、`budget_exceeded`）和瞬时值（`depth`、`live` 协程数）；计数器在采集时重置，瞬时值不会。
- 创建协程时打上 id，这样每个指标都能归因到具体负载，而不只是调度器整体。
- 只在调试构建、或者确实需要硬性按协程限制预算时才用计数 mask 装 `debug.sethook(co, ...)`；要记住解释器/JIT 编译器的开销。
- 永远处理 `coroutine.resume` 的 `false, err`：计数、停用或杀掉该协程，绝不盲目重试。
- 用 `os.clock()` 衡量每个时间片的 CPU 开销，另配一个墙钟来源衡量延迟；单靠 `os.clock()` 会掩盖"阻塞而非繁忙"的调度器。
- 在时间片之间调用 `collectgarbage("step")`，避免一次垃圾回收同时击穿所有协程的延迟预算。

## 设计题 4：配置分层

*设计一个合并默认值、文件、环境变量和 CLI 标志的系统。每层应用什么合并语义？如何处理类型冲突？*

**解答**：

顺序是**默认值 < 文件 < 环境变量 < CLI 标志**：靠后的层覆盖靠前的层。真正有意思的部分是"覆盖"对不同取值形态意味着什么，而这由值的形态决定，而不是由层决定：
- **标量**（字符串、数字、布尔）：直接替换，后面的层获胜。
- **映射**：按键深度合并，而不是整体替换——文件里的 `retry = {count = 5}` 不应该把默认值里的 `retry.backoff` 抹掉。
- **数组**：整体替换。按下标合并从来不是用户的意思；如果某个键确实需要拼接，就为那个键写一条明确规则。
- **删除**：Lua 表无法存放 `nil`，所以"显式置空"没有天然表示。只能用一个唯一的哨兵值（一张表），由某一层写入来表示"删掉这个键"。

类型冲突的来源是环境变量和 CLI 只能携带字符串，而文件里是真正的布尔和数字。解决办法是**按当前值的类型做转换**：默认值就是 schema。如果当前值是数字，就对传入字符串做 `tonumber`；如果是布尔，就解析真值集合（`1/true/yes/on` 对 `0/false/no/off`）；转换失败时要记录一条指明来源层的冲突，而不是悄悄退回默认值——命令行参数里的笔误应该是错误，而不是一个安静的默认值。

每一层都有各自的 Lua 细节。**默认值**层同时充当 schema：它决定值的类型，也定义了合法键的集合。**文件**层应当是数据而不是代码；注意 `loadfile` 执行的是 Lua 代码，出错时返回 `nil, err` 而不是抛错，这本身就是选数据格式的理由。**环境变量**层有两个陷阱：`os.getenv` 在变量未设置时返回 `nil`，设置为空字符串时返回 `""`，这是两种不同状态；而且 Lua 没有可移植的方式枚举环境变量，所以这一层需要显式的键映射（`APP_PORT` → `port`）而不是扫描。**CLI** 层有一个地道的 Lua 怪事：独立解释器**不会**解析脚本自己的标志。在主 chunk 中，`arg[0]` 是脚本名，`arg[1]`、`arg[2]`…… 是脚本参数本身，按顺序排列——`--verbose` 只是普通字符串 `"--verbose"`，所以标志解析器得你自己写。`arg` 的**负**下标（`arg[-1]`、`arg[-2]`……）放的是**解释器自己的**选项和程序名，不是你脚本的标志，所以想从那里反推命令行是错的。更麻烦的是 `arg` 只在主 chunk 里存在，直接读全局 `arg` 的库没法测试；应该把参数向量作为参数传进来。

最后，合并本身绝不能修改它的基底。默认值住在模块级局部变量里，而把结果写回基底的合并会污染整个 schema——第二次调用会继承第一次调用的覆盖值。合并时一律复制，嵌套表也要复制，因为表是引用：浅赋值会把可变状态和来源层共享起来。相关的一点是用 `rawget` 区分"显式设置"和"从默认值继承"——当存在 `__index` 默认值链时，这两者用普通的索引运算根本分不出来。

```lua
-- 分层配置：默认值 < 文件 < 环境变量 < CLI。
local UNSET = setmetatable({}, { __tostring = function() return "<unset>" end })

local DEFAULTS = {
  host = "127.0.0.1",
  port = 8080,
  verbose = false,
  retry = { count = 3, backoff = 0.5 },
  plugins = { "auth", "log" },
}

local function deepCopy(t)
  local out = {}
  for k, v in pairs(t) do
    if type(v) == "table" then out[k] = deepCopy(v) else out[k] = v end
  end
  return out
end

local function isArray(t)
  local n = 0
  for k in pairs(t) do
    if type(k) ~= "number" then return false end
    n = n + 1
  end
  return n == #t
end

local function merge(base, over)
  local out = deepCopy(base)                    -- 绝不修改共享的默认值
  for k, v in pairs(over) do
    if v == UNSET then
      out[k] = nil                              -- 显式"删除该键"
    elseif type(v) == "table" and type(out[k]) == "table" and not isArray(v) then
      out[k] = merge(out[k], v)                 -- 映射按键合并
    else
      out[k] = v                                -- 标量和数组整体替换
    end
  end
  return out
end

local function coerce(value, sample)
  if type(sample) == "boolean" then
    if type(value) == "boolean" then return value end
    local s = string.lower(tostring(value))
    if s == "1" or s == "true" or s == "yes" or s == "on" then return true end
    if s == "0" or s == "false" or s == "no" or s == "off" then return false end
    return nil, "not a boolean: " .. tostring(value)
  elseif type(sample) == "number" then
    if type(value) == "number" then return value end
    local n = tonumber(value)
    if n then return n end
    return nil, "not a number: " .. tostring(value)
  end
  return value
end

local function applyLayer(cfg, layer, source)
  local conflicts = {}
  local out = deepCopy(cfg)
  for k, v in pairs(layer) do
    if v == UNSET then
      out[k] = nil
    elseif type(out[k]) == "boolean" or type(out[k]) == "number" then
      local coerced, err = coerce(v, out[k])
      if coerced == nil then
        conflicts[#conflicts + 1] = source .. ":" .. k .. " " .. err
      else
        out[k] = coerced
      end
    else
      out[k] = v
    end
  end
  return out, conflicts
end

local function parseArgv(argv)
  local opts, positional = {}, {}
  local i = 1
  while i <= #argv do
    local a = argv[i]
    local name, value = a:match("^%-%-(%w[%w%-_]*)=(.*)$")
    if name then
      opts[name] = value
    elseif a:match("^%-%-") then
      opts[a:sub(3)] = true
    else
      positional[#positional + 1] = a
    end
    i = i + 1
  end
  return opts, positional
end

-- 文件层
local cfg = merge(DEFAULTS, { port = 9000, retry = { count = 5 }, plugins = { "auth" } })
assert(cfg.port == 9000)
assert(cfg.retry.count == 5 and cfg.retry.backoff == 0.5)   -- 映射按键合并
assert(#cfg.plugins == 1 and cfg.plugins[1] == "auth")      -- 数组整体替换

-- 环境变量层：只有字符串，按默认值的类型做转换
local conflicts
cfg, conflicts = applyLayer(cfg, { port = "7000", verbose = "yes" }, "env")
assert(cfg.port == 7000 and cfg.verbose == true)
assert(#conflicts == 0)

-- CLI 层
local cli = parseArgv({ "--port=8081", "--verbose" })
cfg = applyLayer(cfg, cli, "cli")
assert(cfg.port == 8081)

-- 类型冲突会被报告，而不是悄悄退回默认值
local _, bad = applyLayer(cfg, { port = "not-a-number" }, "env")
assert(#bad == 1)

-- 显式删除
local pruned = merge(cfg, { plugins = UNSET })
assert(pruned.plugins == nil)

-- 默认值从未被修改
assert(DEFAULTS.port == 8080 and DEFAULTS.retry.count == 3)
```

**实践建议**：
- 按默认值 < 文件 < 环境变量 < CLI 的顺序合并，每一层都合并进累积结果的**副本**。
- 映射深度合并、数组整体替换，用哨兵值表达显式删除，因为 `nil` 无法存进表里。
- 环境变量和 CLI 的字符串按当前值的类型做转换；把所有冲突收集起来一起报告。
- 绝不修改默认值表，合并时要深拷贝嵌套表——表是引用。
- 把 CLI 参数向量传进配置模块，而不是读全局 `arg`；还要记住 Lua 不解析你脚本的标志——`--verbose` 会作为普通字符串出现在 `arg[1]`、`arg[2]`…… 中，而负下标放的是解释器自己的选项。
- 区分环境变量的"未设置"与"设置为空"：`os.getenv` 返回 `nil` 还是 `""`。
- 用 `rawget` 区分"显式设置"的键和通过 `__index` 默认值链继承来的键。

## 设计题 5：状态机可扩展性

*在 20+ 个状态和 50+ 个转换的情况下，转换表会变得难以管理。哪些结构模式能保持可维护性？考虑分层状态和表驱动设计。*

**解答**：

规模问题的根源不是图太大，而是把**图**和**逻辑**混在了一个函数里。所以规则是：**转换图是数据，转换行为是少量具名函数。** 表驱动的机器保持 `transitions[state][event] = target`，新增一个状态就是新增一行，新增一个事件就是新增一列；这张表依然可以 diff、可以评审，而且能被机械地校验。

三个结构模式承担了大部分工作。**把图和行为分开**：`guards[event](ctx)` 决定是否允许，`actions[event](ctx)` 执行效果，而分派器始终只有几行。不做这个拆分，每新增一个条件判断都落进分派器里，它的分支数会无限膨胀。**分层状态**能让表保持小巧：子状态继承父状态的出边，查找时沿父链向上走，直到找到该事件。十个子状态如果都要中止到 `IDLE`，只要在共同的父状态上声明一次那条转换。**通配目标**用来处理那些到处含义相同的横切事件（`RESET`、`ABORT`、`TIMEOUT`），而不是在每个状态行里重复它们。

因为规格是数据，所以可以在**构造时校验**：每个目标状态必须存在，每个 guard 和 action 名字必须解析到函数，每条父链必须终止，且不允许出现父环。会自检的表驱动机器不会在生产环境里被配置错——它在启动时就带着精确消息失败，而不是在凌晨三点某个罕见转换上失败。让分派器保持愚钝：解析目标、跑 guard、跑 action、切换状态。所有复杂度都属于表所指向的具名函数；当多个状态对同一事件有不同规则时，按源状态给 guard 建索引（`guards[event][from]`），而不是把一个大函数越写越长。

要避免的反模式同样具体：**上帝 switch**（`if state == "A" then ... elseif state == "B" then ...`），每加一个状态都要改一个巨大的函数，而且任何两个转换都无法共享行为；把图编码进代码（`if event == "START_" .. state`），这种图无法校验；把行为塞进图里（事件映射到函数），这会毁掉图的可比较性和可序列化性；以及用 `__index` 链来解析转换，因为回退行为会在调用处变得不可见。

与 Lua 相关的几点：状态机天然就是一张带元表的表——用 `__index` 暴露只读状态常量、用 `__tostring` 输出调试信息都是好用法，但两者都不该参与转换解析。每个实例都要各自 `setmetatable`；共享元表本身没问题，前提是它只装方法、绝不装可变状态，否则两台机器会共享状态。

```lua
-- 一个分层的、表驱动的状态机。
local SPEC = {
  states = {                                -- 已知状态的集合
    IDLE = true, RUNNING = true, STOPPING = true,
    CRASHED = true, RECOVERING = true,
  },
  parent = { RECOVERING = "RUNNING" },       -- RECOVERING 继承 RUNNING 的出边
  initial = "IDLE",
  transitions = {
    IDLE     = { START = "RUNNING" },
    RUNNING  = { FAIL = "CRASHED", PAUSE = "STOPPING" },
    STOPPING = { STOPPED = "IDLE" },
    CRASHED  = { RESET = "IDLE" },
  },
  guards = {
    START = function(ctx) return ctx.ready == true end,
  },
  actions = {
    START = function(ctx) ctx.starts = ctx.starts + 1 end,
  },
}

local function validate(spec)
  for state, edges in pairs(spec.transitions) do
    assert(spec.states[state], "unknown source state: " .. tostring(state))
    for event, target in pairs(edges) do
      assert(spec.states[target], "unknown target state: " .. tostring(target))
      local g = spec.guards[event]
      assert(not g or type(g) == "function", "guard must be a function: " .. event)
      local a = spec.actions[event]
      assert(not a or type(a) == "function", "action must be a function: " .. event)
    end
  end
  -- 每条父链都必须终止且不含环
  for state in pairs(spec.states) do
    local seen, cur = {}, state
    while cur do
      assert(not seen[cur], "parent cycle at state: " .. tostring(cur))
      seen[cur] = true
      cur = spec.parent[cur]
    end
  end
end

-- 处理器可以是单个函数，也可以是按源状态索引的表。
local function pick(map, event, state)
  local h = map and map[event]
  if type(h) == "table" then return h[state] end
  return h
end

local FSM = {}
FSM.__index = FSM

local function newFSM(spec)
  validate(spec)
  return setmetatable({ spec = spec, state = spec.initial, ctx = { starts = 0 } }, FSM)
end

function FSM:resolve(event)
  local state, seen = self.state, {}
  while state and not seen[state] do
    seen[state] = true
    local edges = self.spec.transitions[state]
    if edges and edges[event] then return edges[event] end
    state = self.spec.parent[state]            -- 从父状态继承
  end
  return nil
end

function FSM:fire(event)
  local target = self:resolve(event)
  if not target then
    return false, "event '" .. event .. "' is invalid in state '" .. self.state .. "'"
  end
  local guard = pick(self.spec.guards, event, self.state)
  if guard and not guard(self.ctx) then
    return false, "guard rejected '" .. event .. "'"
  end
  local action = pick(self.spec.actions, event, self.state)
  if action then action(self.ctx) end
  self.state = target
  return true
end

local fsm = newFSM(SPEC)
fsm.ctx.ready = false
assert(fsm:fire("START") == false)              -- guard 拒绝
fsm.ctx.ready = true
assert(fsm:fire("START") == true)
assert(fsm.state == "RUNNING")
assert(fsm.ctx.starts == 1)

-- 分层：RECOVERING 继承 RUNNING 的 FAIL 转换
fsm.state = "RECOVERING"
assert(fsm:fire("FAIL") == true)
assert(fsm.state == "CRASHED")
```

**实践建议**：
- 把 `transitions`、`guards`、`actions` 放进三张独立的表；图保持纯数据，行为保持可测。
- 用显式的 `parent` 映射加带访问集合的查找循环来建模分层，而不是靠 `__index` 链。
- 启动时校验整份规格：未知目标、缺失的处理器、父环——在加载时失败，而不是在罕见转换上失败。
- 用通配目标处理横切事件（`RESET`、`ABORT`），而不是在每个状态行里重复。
- 让 `fire()` 控制在几行之内；行为放进具名函数，规则分歧时按源状态给 handler 建索引。
- 如果元表里会放状态，就给每个实例各自的元表；共享元表只能装方法。

## 设计题 6：测试隔离

*如何确保 Lua 测试不通过全局变量或模块级局部变量共享状态？什么模式能在不需要每个测试使用独立 Lua 状态的情况下强制隔离？*

**解答**：

在同一个 Lua 状态里有四个污染源，各需要不同的解法。**`_G` 里的全局变量**：一个测试写下 `_G.cache = {}`，下一个测试就读到了它。**模块级局部变量**：缓存在 `package.loaded` 里的模块会在测试之间保留状态——而清掉 `package.loaded[name] = nil` 只能防止复用，它无法撤销模块在加载时产生的副作用（起了一个协程、打开了文件、注册了信号处理器）。**环境**：函数的环境是它身份的一部分，所以如果某个测试替换了模块函数的环境（5.1/LuaJIT 用 `setfenv`，5.2+ 用 `load` 的 `env` 参数），这个改动会一直影响后面的测试，除非被还原。**共享单例**：测试体结束后仍然存活的定时器、连接池或调度器。

首选的解法是结构性的而不是防御性的：**给模块工厂，而不是单例**。如果 `Counter.new()` 返回带独立状态的新实例，模块级状态就变成了实例状态，根本没有东西需要重置——不用拆卸、不用动 `package.loaded`、不依赖测试顺序。如果单例不可避免，就给它一个明确的 `reset()`/`close()`，清空它的表、停掉它的协程、关掉它的句柄，并在 teardown 中调用。

另外三种机制覆盖剩下的情况。**给 `_G` 拍快照并还原**：测试前复制全局表，测试后删掉测试新增的全局、还原被修改的全局。它能抓住"测试新增了全局变量"这种光还原原值会漏掉的情况，而且对测试套件通常很小的全局集合来说代价很低。**给测试体套沙箱**：用一张新的环境表加载测试 chunk，并把它的 `__index` 指向 `_G`，这样全局**写入**落在沙箱里并随沙箱一起消失，而全局**读取**仍然能看到真实全局。两种实现并不相同——5.1/LuaJIT 用 `setfenv(chunk, env)`，5.2+ 用 `load(src, name, "t", env)`——所以应该在一个辅助函数里做一次特性检测，而不是把版本判断撒得满测试文件都是。**清理比测试活得久的东西**：测试创建的每个协程、文件句柄和定时器都必须在 teardown 里关闭，因为挂起的协程会钉住它栈上的每一个上值——这既是跨测试的泄漏，也是"旧"的值莫名其妙出现在下一个测试里的来源。

最后，测试框架自身必须是封闭的：绝不要在测试里调用 `os.exit`（它会杀掉进程，什么都不报告——用 `xpcall` 并打印摘要），还要记住 5.4 里 `warn("@on")` 可以把警告重定向到处理器从而被测试捕获，而 5.1/LuaJIT 根本没有 `warn`，必须做特性检测。万一你确实需要进程级的彻底隔离，兜底方案是每个测试**文件**一个独立的 Lua 状态（每个文件一个子进程）——更慢，但整类问题都不存在了。

```lua
-- 1. 在单个测试前后快照并恢复全局表。
local function snapshotGlobals()
  local saved = {}
  for k, v in pairs(_G) do saved[k] = v end
  return saved
end

local function restoreGlobals(saved)
  for k in pairs(_G) do
    if saved[k] == nil then _G[k] = nil end
  end
  for k, v in pairs(saved) do _G[k] = v end
end

local saved = snapshotGlobals()
_G.leaked = "oops"
assert(rawget(_G, "leaked") == "oops")
restoreGlobals(saved)
assert(rawget(_G, "leaked") == nil)

-- 2. 在独立环境中运行测试体。
local function loadInEnv(src, name, env)
  if setfenv then                              -- Lua 5.1 / LuaJIT
    local chunk = assert(loadstring(src, name))
    setfenv(chunk, env)
    return chunk
  end
  return assert(load(src, name, "t", env))     -- Lua 5.2+
end

local sandbox = setmetatable({}, { __index = _G })
local run = loadInEnv("scratch = 1; return scratch", "sandbox-test", sandbox)
assert(run() == 1)
assert(rawget(_G, "scratch") == nil)          -- 全局变量从未写入 _G
assert(sandbox.scratch == 1)

-- 3. 用全新实例代替模块单例。
local Counter = {}
Counter.__index = Counter

function Counter.new()
  return setmetatable({ count = 0 }, Counter)
end

function Counter:inc()
  self.count = self.count + 1
  return self.count
end

local a, b = Counter.new(), Counter.new()
a:inc()
assert(a.count == 1 and b.count == 0)         -- 没有共享状态
```

**实践建议**：
- 优先用全新实例（`Module.new()`）；把 `_G` 的快照/还原当安全网，真正必须动全局变量的测试才套沙箱。
- 把 `setfenv`/`loadstring`（5.1、LuaJIT）与 `load(src, name, "t", env)`（5.2+）的特性检测集中写在一个辅助函数里。
- 给每个模块准备 `reset()`/`close()` 并在 teardown 调用；只清 `package.loaded` 无法撤销加载期的副作用。
- 在 teardown 里关闭协程、文件句柄和定时器——挂起的协程会钉住它持有的每一个上值。
- 测试里绝不调用 `os.exit`；用 `xpcall` 包住测试体并打印摘要。
- `warn` 只能在特性检测之后使用（`if warn then warn("@on") end`），因为 5.1/LuaJIT 上没有它。
