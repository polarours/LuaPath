# 高级练习

## 概念巩固

1. **Schema 验证（阶段 17）** — `困难`
   构建一个 `validate(schema, data)` 函数，递归地根据 schema 定义检查表。Schema 支持类型（`"string"`、`"number"`、`"boolean"`、`"table"`）、必填/可选字段和嵌套 schema。返回所有验证错误的列表。
   ```lua
   local schema = { name = "string", age = "number", address = { city = "string", zip = "string" } }
   local ok, errs = validate(schema, { name = "Alice", age = "thirty" })
   -- ok = false, errs = {"age: expected number, got string"}
   ```
   **提示**：使用 `type(v)` 比较基本类型。对嵌套表 schema 进行递归。使用栈跟踪错误路径。

2. **依赖注入（阶段 18）** — `困难`
   创建一个 DI 容器，支持 `register(name, factory)` 和 `resolve(name)`。工厂可以返回缓存的单例或新实例（使用 `cached = true` 标志）。当工厂的函数签名通过 `debug.getinfo` 声明了依赖时，自动解析依赖：
   ```lua
   container:register("db", { cached = true }, function(config)
     return { execute = function(sql) return sql end }
   end)
   container:register("logger", { cached = true }, function(db)
     return { log = function(msg) db.execute("INSERT INTO logs") end }
   end)
   ```
   在解析时检测循环依赖，并抛出包含循环路径的描述性错误（如 `"a -> b -> c -> a"`）。

3. **命令模式（阶段 19）** — `困难`
   使用命令模式实现事务日志。每个命令是一个包含 `execute(self)`、`undo(self)` 和 `serialize(self)` 方法的表。构建一个 `Invoker` 跟踪历史并支持 `undo(n)` 和 `redo(n)`。
   - 将日志序列化为 JSON 文件并从磁盘重新加载
   - 验证重新加载后的 `undo` 与内存中的 `undo` 行为一致
   - 处理边界情况：空历史的 undo、超出栈深度的 redo、序列化引用闭包 upvalue 的命令

4. **观察者模式（阶段 20）** — `困难`
   构建一个 `EventEmitter`，支持 `on(event, handler)`、`off(event, handler)` 和 `emit(event, ...)`。添加 `once(event, handler)` 便捷方法，首次触发后自动移除。
   - 确保 handler 按注册顺序触发
   - 一个 handler 的错误不能阻止后续 handler 的执行
   - 包含 `listenerCount(event)` 工具方法
   - 包含 `prependListener(event, handler)` 将 handler 添加到队列头部

5. **对象池（阶段 21）** — `困难`
   实现一个通用的 `Pool(factory, reset, maxSize)` 管理一组固定的可复用对象。
   - 跟踪 `active`、`idle` 和 `total` 计数
   - 当池耗尽且未达到 `maxSize` 时，创建新对象
   - 如果达到 `maxSize`，使用可配置的超时阻塞调用者
   - 每次 `acquire`/`release` 调用时打印池统计信息
   - 包含 `drain(timeout)` 方法，等待所有活跃对象被释放
   - 包含 `destroy()` 方法，强制关闭所有空闲对象

6. **发布-订阅系统（阶段 22）** — `困难`
   构建一个支持通配符主题匹配的发布-订阅总线。
   - `subscribe("db.>", handler)` 匹配 `db.insert`、`db.update.row` 等
   - 通配符：`>` 匹配任意深度，`*` 精确匹配一个段
   - 支持 `unsubscribe` 和一个拒绝未通过谓词的消息的 `filter` 函数
   - 消息携带元数据：`{topic, timestamp, payload, source}`
   - 添加新订阅时触发 `sys.subscribe` 事件
   - 包含 `bus:history(topic_pattern, count)` 返回最近 N 条消息

7. **FSM 进阶（阶段 23）** — `困难`
   实现一个分层 FSM，状态可以嵌套（一个状态拥有子 FSM）。当父状态转换时，所有子状态重置为初始状态。
   - 每个状态转换触发 `onEnter` 和 `onExit` 钩子
   - 在构造时验证转换表 —— 对不可达状态抛出错误
   - 支持 `currentPath()` 方法返回完整状态路径如 `"combat.melee"`
   - 支持 `force` 标志重新进入当前状态而不跳过钩子

8. **数据管道（阶段 24）** — `困难`
   构建一个 `Pipeline` 串联转换阶段：`Pipeline({trim, lowercase, split_words, deduplicate})`。
   - 每个阶段是纯函数 `(data) -> data`
   - 管道支持 `add_stage`、`remove_stage` 和 `run`
   - 通过内置 profiling 钩子跟踪每阶段的执行次数和平均延迟
   - 优雅处理 `nil` 短路（阶段返回 `nil` → 管道停止）
   - 添加 `dry_run` 模式，打印将要执行的操作而不实际执行
   - 添加 `pipeline:inspect(stage_name, fn)` 用于查看中间结果

9. **并发模式（阶段 25）** — `困难`
   使用 `coroutine.create`、`coroutine.resume` 和 `coroutine.wrap`，实现一个带优先级的协作式任务调度器。
   - 任务以 `{fn = function, priority = 1..5, deadline = num}` 形式调度
   - 调度器优先运行高优先级任务
   - 如果任务超过截止时间，将其移入 `deadline_missed` 队列并发出警告
   - 包含 `yield()` 函数协作式地将控制权交回调度器
   - 添加 `sleep(seconds)` 在给定时间后恢复任务

10. **代码生成（阶段 26）** — `困难`
    编写一个 Lua 元编程程序，读取表 schema 并生成一个包含以下内容的模块：
    - 构造函数
    - 字段 getter 和 setter（带类型检查）
    - 用于调试的 `tostring` 元方法
    - 一个 `validate` 方法，检查运行时值是否符合 schema
    ```lua
    -- 输入：{ name = "string", age = "number" }
    -- 生成：local Person = {}; Person.new = function(t) ... end
    ```
    将生成的 Lua 代码输出为字符串，并通过 `load()` 加载以验证生成的代码能正常工作。

11. **内存管理（阶段 27）** — `困难`
    通过 hook `collectgarbage("setpause")` 和 `collectgarbage("setstepmul")` 来分析 Lua GC。构建一个基准测试：
    - 分配 N 个大表（每个约 1MB 嵌套数据）
    - 测量分配突发之间的暂停时间
    - 报告峰值内存、GC 循环次数和总 GC 时间
    - 变化 `stepmul` 和 `pause` 寻找最优设置
    - 如果可用，比较标准 Lua 与 LuaJIT
    - 记录哪些参数组合能最小化尾延迟

12. **部署模式（阶段 28）** — `困难`
    创建一个 `ServiceLoader`，在目录树中发现 Lua 模块，按约定加载（`init.lua`），并暴露统一的 API。
    - 每个模块在 `__meta` 表中声明元数据：`{name, version, dependencies = {}, config = {}}`
    - 加载器按拓扑排序验证依赖顺序
    - 检测版本冲突（如两个模块要求同一依赖的不兼容版本）
    - 提供 `status()` 视图，显示所有已加载服务的健康状态
    - 支持热重载：重新导入模块而不重启宿主

---

## 小型项目

### 项目 1：带统计的对象池（阶段 21）

构建一个生产级的数据库连接对象池（模拟）。

**需求：**
- `Pool:create(config)` 支持 `minSize`、`maxSize`、`idleTimeout`、`healthCheck`
- 跟踪指标：`acquire_count`、`release_count`、`timeout_count`、`error_count`
- 空闲对象在 `idleTimeout` 秒后被回收（使用计时器 coroutine）
- `healthCheck(conn)` 在返回对象前运行；不健康的对象被丢弃
- 暴露 `stats()` 返回包含所有计数器的快照表
- 使用基于 coroutine 的 yield 安全处理并发 `acquire` 调用
- 添加 `drain(timeout)` 方法，等待所有活跃对象被释放
- 添加 `destroy()` 方法，关闭所有连接并停止空闲回收器

**解答：**
```lua
local Pool = {}
Pool.__index = Pool

function Pool:create(config)
  local self = setmetatable({}, Pool)
  self._min = config.minSize or 1
  self._max = config.maxSize or 10
  self._idle_timeout = config.idleTimeout or 30
  self._health_check = config.healthCheck or function(c) return true end

  -- 指标
  self._acquire_count = 0
  self._release_count = 0
  self._timeout_count = 0
  self._error_count = 0

  -- 池状态
  self._idle = {}        -- 空闲对象，以对象自身为键
  self._active = {}     -- 已借出的对象
  self._reaper = nil    -- 回收空闲对象的协程

  -- 预创建 minSize 个对象
  for i = 1, self._min do
    local obj = config.factory and config.factory() or {}
    self._idle[obj] = true
  end

  -- 启动空闲回收协程
  self._reaper = coroutine.create(function()
    while true do
      local deadline = os.clock() + self._idle_timeout
      while os.clock() < deadline do
        coroutine.yield()  -- 定期唤醒以检查是否需要销毁
      end
      -- 回收已过期的空闲对象
      local now = os.clock()
      for obj in pairs(self._idle) do
        local expire = (obj._pool_expire or 0)
        if expire > 0 and now >= expire then
          self._idle[obj] = nil
          self._timeout_count = self._timeout_count + 1
          if config.dispose then config.dispose(obj) end
        end
      end
      -- 维持 minSize
      while #self._idle < self._min do
        local obj = config.factory and config.factory() or {}
        self._idle[obj] = true
      end
    end
  end)
  coroutine.resume(self._reaper)
  return self
end

function Pool:acquire(timeout)
  self._acquire_count = self._acquire_count + 1
  local deadline = timeout and (os.clock() + timeout) or math.huge

  while true do
    -- 尝试找一个健康的空闲对象
    for obj in pairs(self._idle) do
      local ok, err = pcall(self._health_check, obj)
      if ok and err then
        self._idle[obj] = nil
        self._active[obj] = true
        return obj
      else
        -- 不健康：丢弃并计入错误
        self._idle[obj] = nil
        self._error_count = self._error_count + 1
        if self._dispose then self._dispose(obj) end
      end
    end

    -- 无空闲对象：若未达到上限则创建新的
    local total = self:count()
    if total < self._max then
      local obj = self._factory and self._factory() or {}
      self._active[obj] = true
      return obj
    end

    -- 达到上限：等待 release（向回收协程让出）
    if os.clock() >= deadline then
      self._timeout_count = self._timeout_count + 1
      return nil, "acquire timed out"
    end
    coroutine.resume(self._reaper)
    coroutine.yield()
  end
end

function Pool:release(obj)
  if not obj then return end
  self._release_count = self._release_count + 1
  self._active[obj] = nil

  -- 重置对象后再放回空闲池
  if self._reset then self._reset(obj) end

  -- 标记过期时间
  obj._pool_expire = os.clock() + self._idle_timeout
  self._idle[obj] = true
end

function Pool:stats()
  return {
    acquire_count = self._acquire_count,
    release_count = self._release_count,
    timeout_count = self._timeout_count,
    error_count   = self._error_count,
    idle = self:count(),
    active = 0,
  }
end

function Pool:count()
  local n = 0
  for _ in pairs(self._idle) do n = n + 1 end
  return n
end

function Pool:drain(timeout)
  local deadline = timeout and (os.clock() + timeout) or math.huge
  while next(self._active) do
    if os.clock() >= deadline then
      return false, "drain timed out"
    end
    coroutine.yield()
  end
  return true
end

function Pool:destroy()
  if self._reaper then
    coroutine.close(self._reaper)
    self._reaper = nil
  end
  for obj in pairs(self._idle) do
    if self._dispose then self._dispose(obj) end
  end
  self._idle = {}
  self._active = {}
end
```

**使用示例：**
```lua
local pool = Pool:create {
  minSize       = 2,
  maxSize       = 5,
  idleTimeout   = 5,
  factory       = function() return { id = math.random(1,9999) } end,
  healthCheck   = function(c) return c.id ~= nil end,
  reset         = function(c) c.query = nil end,
  dispose       = function(c) c.id = nil end,
}

local conn = pool:acquire()
print("acquired", conn.id)
pool:release(conn)
print("stats", next(pool:stats()))  -- 验证 stats 键存在
pool:destroy()
```

### 项目 2：带通配符的发布-订阅（阶段 22）

构建一个支持 `device.>`、`device.{sensor_id}.reading` 和 `device.*.error` 的消息总线。

**需求：**
- 使用模式订阅：`bus:subscribe("device.37.>", handler)`
- 发布：`bus:emit("device.37.temperature", payload)`
- 通配符：`>` 匹配任意深度，`*` 精确匹配一个段
- 支持 `bus:history(topic_pattern, count)` 返回最近 N 条消息
- 添加 `bus:replay(topic_pattern, since)` 从指定时间戳重放消息
- 每个 handler 获得一个数字 id；`bus:unsubscribe(id)` 移除它
- 优雅地处理 handler 错误，不中断分发循环
- 分发前按特异性排序模式（通配符越少 = 优先级越高）

**测试场景：**
```lua
local bus = Bus:new()
local readings = {}
bus:subscribe("device.37.>", function(msg) table.insert(readings, msg.payload) end)
bus:subscribe("device.*.error", function(msg) print("ERROR: " .. msg.payload) end)

bus:emit("device.37.temperature", {value = 22.5})
bus:emit("device.37.humidity", {value = 65})
bus:emit("device.99.error", {message = "timeout"})
-- readings 应该包含 temperature 和 humidity
```

### 项目 3：分层 FSM（阶段 23）

将游戏实体的行为建模为嵌套状态机。顶层状态为 `idle`、`combat` 和 `flee`。`combat` 包含子状态：`melee`、`ranged`、`reload`。`idle` 包含子状态：`patrol` 和 `rest`。

**需求：**
- 每个层级的转换规则（如 `idle → combat` 将 `combat` 重置为初始子状态 `melee`）
- 每个状态有 `onEnter(entity)` 和 `onExit(entity)` 钩子，修改实体表
- 添加 `transitionLog` 记录每次转换为 `{from, to, timestamp}`
- 在构建时验证所有转换；对不可达状态报错
- 测试：`entity:transition("combat")` 应进入 `melee`；`entity:transition("reload")` 应留在 `combat` 但切换子状态
- 支持 `entity:currentState()` 返回完整路径如 `"combat.melee"`
- 支持 `entity:pathHistory()` 返回最近 N 个状态路径

**状态图：**
```
idle ──────┐
  ├─ patrol │
  └─ rest   │
            │ (onHit)         ┌── melee
            └──► combat ──────┤── ranged
                  │           └── reload
                  │ (onLowHp)
                  ▼
                 flee
```

### 项目 4：数据管道（阶段 24）

构建一个可配置的 ETL 管道处理 CSV 数据。

**需求：**
- 阶段：`parse_csv`、`filter_rows(predicate)`、`map_columns(transform)`、`aggregate(group_by, reducer)`、`output_csv`
- 每个阶段是接收表列表并返回表列表的函数
- `Pipeline:compose(stages)` 串联阶段；返回新管道
- 添加 profiling：`pipeline:run(data)` 打印每阶段的行数输入/输出和时间
- 处理错误：如果阶段抛出异常，捕获并继续，记录到 `dead_letter` 日志
- 使用合成 CSV 数据（10 行）测试边界情况：空字符串、缺失字段、数字字符串
- 支持 `pipeline:inspect(stage_name, fn)` 查看中间结果
- 支持 `pipeline:skip(stage_name)` 跳过某阶段而不移除它

**起始骨架：**
```lua
local Pipeline = {}
Pipeline.__index = Pipeline

function Pipeline:new(stages)
  return setmetatable({_stages = stages or {}, _dead_letter = {}, _profile = {}}, Pipeline)
end

function Pipeline:run(data)
  local current = data
  for i, stage in ipairs(self._stages) do
    local t0 = os.clock()
    current = stage(current)
    self._profile[i] = {name = stage.name or ("stage_" .. i), time = os.clock() - t0}
  end
  return current
end
```

---

## 调试任务

1. **Schema 验证 — 漏报** — `困难`
   你的 schema 验证器接受 `{name = 123}` 匹配 schema `{name = "string"}`。找出 bug：你写了 `type(v) == schema[k]` 而不是将 `type(v)` 与该键的 schema 类型字符串进行比较。修复它，并为嵌套表、数组和联合类型如 `"string|number"` 添加测试用例。

2. **对象池 — 资源泄漏** — `困难`
   你的池泄漏对象：`acquire` 返回对象但 `release` 从未减少活跃计数。Bug 在于 `release` 在递减前检查 `obj == nil`，但 `release` 接收的是对象引用（永远不会是 nil）。追踪引用计数逻辑并修复递减。添加一个测试，acquire 和 release 1000 次并断言 `stats().active == 0`。

3. **发布-订阅 — 通配符排序** — `困难`
   你的通配符匹配器先处理 `>` 再处理 `*`，导致 `device.37.reading` 匹配 `device.>` 而不是 `device.*.reading`。Bug 在于匹配优先级：最具体的模式应该获胜。重构为按特异性排序模式（通配符越少 = 越具体）后再分发。添加一个测试断言 handler 执行顺序。

4. **分层 FSM — 可重入转换** — `困难`
   在已处于 `combat` 状态时调用 `entity:transition("combat")` 导致无限递归，因为 `combat` 的 `onEnter` 调用 `transition("melee")`，这又触发 `onExit("combat")`。添加守卫：如果转换到当前状态，跳过 `onExit`/`onEnter`，除非转换指定了 `force = true`。编写一个测试转换到相同状态并验证没有无限循环。

5. **数据管道 — 静默数据丢失** — `困难`
   一个阶段对空结果返回 `nil` 而不是 `{}`。管道将 `nil` 解释为"继续使用未改变的数据"而不是"停止处理"。Bug 在于 `run` 循环：`result = stage(result)` 应该检查 `nil` 并短路或替换为 `{}`。修复并添加一个回归测试，使用一个故意返回 `nil` 的阶段。

6. **内存管理 — GC 停顿** — `困难`
   你的基准测试显示 `collectgarbage()` 在分配突发之间运行时有 2 秒停顿。根本原因是 `setstepmul` 设置太低（100 而不是 200），导致 GC 在分配期间落后。调整参数并在合成负载上验证停顿降至 200ms 以下。记录最优设置并解释为什么它们有效。

---

## 开放性设计问题

1. 如何在嵌入式 Lua 主机的边界处强制执行 schema 验证，而不对受信任的内部代码施加运行时开销？讨论静态分析、运行时守卫和加载时断言之间的权衡。

2. 带通配符匹配的发布-订阅系统在订阅者众多时扩展性很差。你会使用什么数据结构（trie、基于哈希、位掩码）进行模式匹配？如何基准测试内存和查找速度之间的权衡？

3. 在分层 FSM 中，如何处理跨层级转换（如 `combat` 中的子状态直接转换到 `idle` 中的子状态）而不破坏每个层级转换表的封装？

4. 在 Lua 中构建数据管道时，如何在基于 coroutine 的生成器（惰性求值）和基于列表的阶段（立即求值）之间做选择？对内存使用和错误传播有什么影响？

5. 部署加载器在启动时发现冲突的模块版本。应该硬失败、使用最新版本，还是允许按服务覆盖版本？模块应该声明什么契约才能使这个选择安全？

6. 如何测试一个生成 Lua 模块的代码生成器？考虑基于属性的测试、对 schema 输入进行模糊测试，以及将生成的输出与手写的参考实现进行比较。哪些不变量必须始终成立？
