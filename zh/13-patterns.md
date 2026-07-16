# 13 — 设计模式

> **阶段**: E（性能与生产设计）
> **前置知识**: 第 12 章 — 性能
> **时间预估**: 2–3 小时阅读 + 3–5 小时练习
> **Lua 版本**: 5.1、5.3、5.4、LuaJIT（差异已标注）

---

## 学习目标

完成本章后，你将能够：

1. **应用常见的 Lua 设计模式** — OOP、模块、工厂、观察者、状态机
2. **构建事件驱动系统**，具备正确的发布/取消订阅语义
3. **设计面向数据的模式**，如用于游戏/模拟负载的 ECS
4. **创建 DSL**，使用表、元方法和可调用对象
5. **避免模式陷阱**，包括内存泄漏和隐藏的副作用

---

## OOP 模式

### 原型 + 元表 类

标准的 Lua OOP 模式：

```lua
local Animal = {}
Animal.__index = Animal

function Animal.new(name, sound)
  return setmetatable({name = name, sound = sound, alive = true}, Animal)
end

function Animal:speak()
  return self.name .. " says " .. self.sound
end

function Animal:destroy()
  self.alive = false
end
```

### 继承

```lua
local Dog = setmetatable({}, {__index = Animal})
Dog.__index = Dog

function Dog.new(name, breed)
  local self = Animal.new(name, "woof")
  self.breed = breed
  return setmetatable(self, Dog)
end

function Dog:speak()
  return Animal.speak(self) .. " (breed: " .. self.breed .. ")"
end
```

### 组合优于继承

```lua
-- 错误：深层继承链
-- Entity → LivingEntity → Character → Player → Warrior

-- 正确：组合
local function make_player(name, hp, weapon)
  return {
    name = name,
    health = make_health(hp),
    inventory = make_inventory(),
    combat = make_combat(weapon),
  }
end
```

### Mixin 模式

```lua
-- 为多个类添加行为
local Serializable = {}
function Serializable:serialize()
  local parts = {}
  for k, v in pairs(self) do
    if type(v) ~= "function" then
      parts[#parts + 1] = k .. "=" .. tostring(v)
    end
  end
  return table.concat(parts, ",")
end

-- 应用到任意类
local Player = {}
function Player:new(name)
  return setmetatable({name = name}, Player)
end

-- 添加序列化能力
for k, v in pairs(Serializable) do Player[k] = v end
```

---

## 模块模式

### 无状态工具模块

```lua
-- 纯函数，无副作用
local M = {}
function M.clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end
function M.lerp(a, b, t) return a + (b - a) * t end
function M.round(x) return math.floor(x + 0.5) end
return M
```

### 有状态服务模块

```lua
local M = {}
local connection = nil

function M.connect(host, port)
  connection = create_connection(host, port)
end

function M.query(sql)
  assert(connection, "Not connected")
  return connection:execute(sql)
end

function M.disconnect()
  if connection then
    connection:close()
    connection = nil
  end
end

return M
```

### 工厂模块

```lua
local M = {}
local counter = 0

function M.create(name)
  counter = counter + 1
  return {
    id = counter,
    name = name,
    created_at = os.time(),
  }
end

return M
```

---

## 函数式模式

### Map / Filter / Reduce

```lua
local function map(t, fn)
  local result = {}
  for i, v in ipairs(t) do result[i] = fn(v) end
  return result
end

local function filter(t, fn)
  local result = {}
  for _, v in ipairs(t) do
    if fn(v) then result[#result + 1] = v end
  end
  return result
end

local function reduce(t, fn, init)
  local acc = init
  for _, v in ipairs(t) do acc = fn(acc, v) end
  return acc
end
```

### 函数组合

```lua
local function compose(...)
  local fns = {...}
  return function(...)
    local result = ...
    for i = #fns, 1, -1 do
      result = fns[i](result)
    end
    return result
  end
end

local process = compose(
  function(x) return x * 2 end,
  function(x) return x + 1 end,
  tostring
)
print(process(5))  -- "11"
```

### 柯里化

```lua
local function curry(fn, arity)
  arity = arity or debug.getinfo(fn).nparams
  return function(...)
    local args = {...}
    if #args >= arity then
      return fn(table.unpack(args))
    end
    return function(...)
      return fn(table.unpack(args), ...)
    end
  end
end

local add = curry(function(a, b) return a + b end)
print(add(3)(4))  -- 7
```

---

## 事件系统

### 基础事件总线

```lua
local Bus = {handlers = {}}

function Bus:on(event, handler)
  local h = self.handlers[event] or {}
  h[#h + 1] = handler
  self.handlers[event] = h
  return function()
    -- 取消订阅
    for i, fn in ipairs(h) do
      if fn == handler then
        table.remove(h, i)
        break
      end
    end
  end
end

function Bus:emit(event, ...)
  local h = self.handlers[event] or {}
  for _, handler in ipairs(h) do
    handler(...)
  end
end
```

### 优先级事件总线

```lua
function Bus:on(event, handler, priority)
  priority = priority or 0
  local h = self.handlers[event] or {}
  h[#h + 1] = {fn = handler, priority = priority}
  table.sort(h, function(a, b) return a.priority > b.priority end)
  self.handlers[event] = h
end
```

### 一次性处理器

```lua
function Bus:once(event, handler)
  local unsub
  unsub = self:on(event, function(...)
    handler(...)
    unsub()
  end)
end
```

---

## 状态机模式

### 基于表的状态机

```lua
local FSM = {}
FSM.__index = FSM

function FSM.new(states, initial)
  return setmetatable({
    states = states,
    current = initial,
  }, FSM)
end

function FSM:transition(event)
  local state = self.states[self.current]
  if state and state[event] then
    self.current = state[event]
    return true
  end
  return false
end

-- 用法
local traffic = FSM.new({
  green  = {timeout = "yellow", emergency = "red"},
  yellow = {timeout = "red"},
  red    = {timeout = "green"},
}, "green")

traffic:transition("timeout")  -- → yellow
traffic:transition("timeout")  -- → red
```

### 基于协程的状态机

```lua
local function traffic_light()
  while true do
    print("GREEN")
    coroutine.yield("green")
    print("YELLOW")
    coroutine.yield("yellow")
    print("RED")
    coroutine.yield("red")
  end
end

local co = coroutine.create(traffic_light)
coroutine.resume(co)  -- GREEN
coroutine.resume(co)  -- YELLOW
coroutine.resume(co)  -- RED
```

---

## 实体-组件-系统（ECS）

### 数据布局（Structure of Arrays）

```lua
-- 组件存储在独立的数组中
local ECS = {
  entities = {},       -- {id → true}
  position = {},      -- {id → {x, y}}
  velocity = {},      -- {id → {dx, dy}}
  health = {},        -- {id → hp}
  next_id = 0,
}

function ECS:create()
  self.next_id = self.next_id + 1
  self.entities[self.next_id] = true
  return self.next_id
end

function ECS:add_component(id, name, data)
  if not self[name] then self[name] = {} end
  self[name][id] = data
end
```

### 系统（遍历组件）

```lua
function ECS:movement_system(dt)
  for id in pairs(self.entities) do
    local pos = self.position[id]
    local vel = self.velocity[id]
    if pos and vel then
      pos.x = pos.x + vel.dx * dt
      pos.y = pos.y + vel.dy * dt
    end
  end
end

function ECS:damage_system(damage)
  for id in pairs(self.entities) do
    local hp = self.health[id]
    if hp then
      self.health[id] = hp - damage
      if self.health[id] <= 0 then
        self.entities[id] = nil
      end
    end
  end
end
```

### 优势

- **缓存友好**：同类型数据在内存中连续存储
- **迭代速度**：系统只访问相关数据
- **灵活性**：添加/移除组件不影响其他系统

---

## DSL 构建

### 可调用表

```lua
local Rule = setmetatable({}, {
  __call = function(_, name)
    return {name = name, checks = {}}
  end
})

local r = Rule("age_check")
  :check("age >= 18")
  :check("age <= 120")
  :on_fail("invalid age")
```

### Builder 模式

```lua
local Query = {}
Query.__index = Query

function Query.new(table_name)
  return setmetatable({table = table_name, conditions = {}, order = nil}, Query)
end

function Query:where(condition)
  self.conditions[#self.conditions + 1] = condition
  return self
end

function Query:order_by(field)
  self.order = field
  return self
end

function Query:build()
  local sql = "SELECT * FROM " .. self.table
  if #self.conditions > 0 then
    sql = sql .. " WHERE " .. table.concat(self.conditions, " AND ")
  end
  if self.order then
    sql = sql .. " ORDER BY " .. self.order
  end
  return sql
end

-- 用法
local q = Query.new("users")
  :where("age >= 18")
  :where("active = true")
  :order_by("name")
print(q:build())
-- SELECT * FROM users WHERE age >= 18 AND active = true ORDER BY name
```

### Fluent API

```lua
local Pipeline = {}
Pipeline.__index = Pipeline

function Pipeline.new()
  return setmetatable({steps = {}}, Pipeline)
end

function Pipeline:step(name, fn)
  self.steps[#self.steps + 1] = {name = name, fn = fn}
  return self
end

function Pipeline:execute(input)
  local result = input
  for _, step in ipairs(self.steps) do
    result = step.fn(result)
  end
  return result
end

-- 用法
local result = Pipeline.new()
  :step("parse", function(data) return parse_json(data) end)
  :step("validate", function(data) return validate(data) end)
  :step("transform", function(data) return transform(data) end)
  :execute(raw_input)
```

---

## 常见陷阱

### 1. 事件处理器中的隐藏副作用

```lua
-- 错误：处理器意外修改共享状态
Bus:on("update", function(entity)
  entity.x = entity.x + 1  -- 谁能预料到这个？
end)

-- 正确：清晰地记录副作用
--- @description 将实体向右移动 1 个单位
--- @side_effect 修改 entity.x
Bus:on("update", function(entity)
  entity.x = entity.x + 1
end)
```

### 2. 无限制的监听器增长

```lua
-- 错误：监听器不断累积，从未清理
local function setup()
  Bus:on("tick", function() process() end)
  -- 每帧调用 → 监听器无限增长！
end

-- 正确：完成时取消订阅
local function setup()
  local unsub = Bus:on("tick", function() process() end)
  -- 不再需要时调用 unsub()
end
```

### 3. 深层继承链

```lua
-- 错误：难以维护
-- A → B → C → D → E → F

-- 正确：使用组合
local entity = {
  health = make_health(100),
  movement = make_movement(),
  renderable = make_sprite("hero"),
}
```

### 4. DSL 魔法隐藏执行顺序

```lua
-- 错误：难以判断何时执行
Rule("x")
  :check(...)  -- 这个什么时候运行？
  :transform(...)  -- 在 check 之前还是之后？
  :on_fail(...)  -- on_fail 什么时候被调用？

-- 正确：显式指定顺序
rule:add_check(fn, {priority = 1})
rule:add_transform(fn, {priority = 2})
rule:add_on_fail(fn, {priority = 3})
```

### 5. ECS 中表标识的误用

```lua
-- 错误：组件作为表（标识问题）
local e1 = {position = {x = 0, y = 0}}
local e2 = {position = {x = 0, y = 0}}
-- e1.position 和 e2.position 是同一个吗？不是！

-- 正确：通过 ID 管理组件（无标识问题）
ecs.position[id1] = {x = 0, y = 0}
ecs.position[id2] = {x = 0, y = 0}
```

---

## 最佳实践

### 1. 优先使用组合而非继承

```lua
-- 组合：显式、灵活
local function make_entity(components)
  local entity = {id = next_id()}
  for name, data in pairs(components) do
    entity[name] = data
  end
  return entity
end

-- 用法
local player = make_entity({
  health = {hp = 100, max_hp = 100},
  position = {x = 0, y = 0},
  inventory = {},
})
```

### 2. 记录事件契约

```lua
--- Event: "damage"
--- Payload: {entity_id, amount, source}
--- Handlers: must return true to consume, false to propagate
Bus:on("damage", function(payload)
  -- ...
  return true  -- 已消费
end)
```

### 3. 保持系统纯净

```lua
-- 正确：系统是组件数据的纯函数
function movement_system(entities, dt)
  for id, pos in pairs(entities.position) do
    local vel = entities.velocity[id]
    if vel then
      pos.x = pos.x + vel.dx * dt
      pos.y = pos.y + vel.dy * dt
    end
  end
end

-- 错误：系统有隐藏状态
local last_time = 0
function movement_system(entities)
  local dt = os.clock() - last_time  -- 隐藏依赖！
  last_time = os.clock()
  -- ...
end
```

### 4. 用元方法定义行为，而非存储数据

```lua
-- 正确：元方法定义行为
local Vec2 = {}
Vec2.__index = Vec2
function Vec2.__add(a, b) return Vec2.new(a.x + b.x, a.y + b.y) end

-- 错误：元方法存储数据
local bad = setmetatable({data = {}}, {__index = function(_, k) ... end})
```

### 5. 隔离测试模式

```lua
-- 独立测试事件总线
local bus = make_bus()
local received = {}
bus:on("test", function(v) received[#received + 1] = v end)
bus:emit("test", 42)
assert(#received == 1)
assert(received[1] == 42)
```

---

## 版本说明

### Lua 5.1

- `setfenv`/`getfenv` 用于环境操作
- `module()` 可用（已弃用 — 不要使用）
- 没有 `table.pack`/`table.unpack`

### Lua 5.2/5.3

- `setmetatable` 支持带有 `__gc` 的表（5.2+）
- 可用 `table.pack`/`table.unpack`
- `goto` 语句用于复杂控制流

### Lua 5.4

- `__close` 用于确定性资源清理
- `__type` 用于自定义类型名称
- 分代 GC 在分配密集的模式下性能更好

### LuaJIT

- 如果模式是单态的，元方法对 JIT 友好
- FFI 可在 Lua 中实现 C 风格的数据布局
- 避免在热路径中使用多态分发

---

## 知识检查

<details>
<summary>1. 什么时候应该使用组合而非继承？</summary>

当实体之间不是严格的"是一个"关系时，当你需要灵活地混合行为时，或者当继承链过深（3 层以上）时。组合使依赖关系更加显式。
</details>

<details>
<summary>2. 什么是 ECS 模式，为什么它性能好？</summary>

ECS 将组件按类型存储在独立的数组中（Structure of Arrays）。系统遍历特定的组件类型，只访问相关数据。这缓存友好且避免了虚函数分发。
</details>

<details>
<summary>3. 如何防止事件监听器的内存泄漏？</summary>

存储取消订阅函数，并在监听器不再需要时调用它们。或者使用弱表或在 destroy/disconnect 方法中进行显式清理。
</details>

<details>
<summary>4. 为什么用元方法定义行为而非存储数据？</summary>

元方法在操作（index、newindex、add 等）时被调用。将它们用于数据存储会造成数据位置的混乱。元表应该定义对象如何响应操作。
</details>

<details>
<summary>5. 什么是好的 Lua DSL？</summary>

清晰的执行顺序、显式而非魔法的语法、容易测试各个部分、没有隐藏的副作用。使用 Builder/Fluent 模式来实现可读的链式调用。
</details>

---

## 关键要点

- **原型 OOP**：`__index` 链实现继承；优先使用组合以获得灵活性
- **模块模式**：无状态工具、有状态服务、工厂
- **函数式模式**：map/filter/reduce、函数组合、柯里化
- **事件系统**：发布/取消订阅，支持优先级
- **状态机**：基于表或基于协程
- **ECS**：面向数据、缓存友好、基于系统的迭代
- **DSL**：可调用表、Builder 模式、Fluent API
- **避免**：深层继承、无限制的监听器、隐藏的副作用

---

## 练习

### 初级（30–60 分钟）

1. **事件总线**：实现一个基础的事件总线，包含 `on`、`emit` 和 `off`。用 3 个事件测试。

2. **状态机**：构建一个旋转门状态机（锁定 → 解锁 → 锁定），事件为 `coin` 和 `push`。

3. **Mixin**：创建一个 `Drawable` mixin 并应用到两个不同的类。

### 中级（1–2 小时）

4. **ECS 核心**：实现一个最小的 ECS，包含 `create`、`add_component`、`get_component` 和一个 `movement_system`。

5. **管道**：构建一个数据处理管道，包含 `add_step` 和 `execute`。步骤可以是异步的（基于协程）。

6. **优先级事件总线**：为事件总线添加优先级支持。高优先级的处理器先运行。

### 高级（2–4 小时）

7. **响应式状态**：创建一个响应式系统，改变一个值会自动触发依赖项（类似电子表格）。

8. **DSL 编译器**：构建一个用于定义验证规则的小型 DSL。将规则编译为优化的检查函数。

---

## 示例代码

本章的可运行示例：
- `examples/intermediate/01-prototype-entity.lua` — OOP 模式
- `examples/intermediate/02-event-bus.lua` — 事件系统
- `examples/intermediate/05-readonly-table.lua` — 代理模式
- `examples/advanced/01-ecs-system.lua` — ECS 实现

---

## 延伸阅读

- [Programming in Lua (4th ed.) — 第 16、20、23 章](https://www.lua.org/pil/)
- [Lua Design Patterns（社区 wiki）](https://lua-users.org/wiki/LuaDesignPatterns)
- [下一章: 14 — Lua 在生产中的应用](14-lua-in-production.md)
