# 05 — Metatable

> **阶段**：B（元层与架构）  
> **前置要求**：第 04 章 — Table  
> **时间预估**：3–4 小时阅读 + 3–5 小时练习  
> **Lua 版本**：5.1、5.3、5.4、LuaJIT（差异已标注）

---

## 学习目标

完成本章后，你将能够：

1. **解释 metatable 分派机制**以及每个 metamethod 的触发时机
2. **实现运算符重载**，使用算术和比较 metamethod
3. **构建基于原型的 OOP**，带有正确的继承链
4. **使用代理模式**实现只读 table、验证和日志记录
5. **避免 metamethod 陷阱**，包括递归、共享原型和性能问题

---

## 什么是 Metatable？

每个 table（和 userdata）都可以有一个关联的 **metatable** — 一个控制其行为的 table。Metatable 定义了 **metamethod**：Lua 在响应操作时自动调用的特殊键。

```lua
local t = {}
local mt = {
  __tostring = function(self)
    return "MyTable"
  end
}
setmetatable(t, mt)
print(t)  -- "MyTable"
```

Metatable 不会改变 table 的数据 — 它们改变的是 table **对操作的响应方式**。

---

## 查找链：`__index`

读取 `obj.key` 时，Lua 按照以下顺序分派：

1. 检查 `key` 是否作为原始字段存在 → 返回它
2. 如果不存在，检查 metatable 中是否有 `__index`
3. `__index` 可以是一个 **table**（在该 table 中查找 `key`）或一个 **函数**（用 `(obj, key)` 调用它）

```lua
-- __index 作为 table：继承
local Animal = {sound = "..." }
local Dog = setmetatable({}, {__index = Animal})
print(Dog.sound)  -- "..."（通过 __index 找到）

-- __index 作为函数：计算属性
local t = setmetatable({}, {
  __index = function(self, key)
    if key == "doubled" then
      return rawget(self, "value") * 2
    end
  end
})
rawset(t, "value", 21)
print(t.doubled)  -- 42
```

### 多层查找链

```lua
local Base = {type = "base"}
local Middle = setmetatable({kind = "middle"}, {__index = Base})
local Instance = setmetatable({name = "obj"}, {__index = Middle})

-- 查找顺序：Instance → Middle → Base
print(Instance.name)   -- "obj"（原始命中）
print(Instance.kind)   -- "middle"（通过 Instance.__index = Middle）
print(Instance.type)   -- "base"（通过 Middle.__index = Base）
```

```text
instance ----__index----> Class ----__index----> BaseClass
   |                           |                     |
 raw miss                   raw miss              raw hit
   '------------------------------> 解析到方法
```

---

## 写入拦截：`__newindex`

仅在写入 table 上**不存在**的键时触发：

```lua
local t = {}
setmetatable(t, {
  __newindex = function(self, key, value)
    print("Setting " .. key .. " = " .. tostring(value))
    rawset(self, key, value)  -- 必须使用 rawset 以避免递归
  end
})

t.x = 10  -- "Setting x = 10"
t.x = 20  -- "Setting x = 20"（仍然触发：x 通过 rawset 设置，但检查是否触发）
```

> **关键区别**：`__newindex` 仅在**缺失原始键**时触发。如果键已作为原始字段存在，写入直接到 table 而不触发 `__newindex`。

### 验证代理

```lua
local function make_validated(schema)
  local data = {}
  return setmetatable(data, {
    __newindex = function(self, key, value)
      local expected = schema[key]
      if not expected then
        error("Unknown field: " .. tostring(key))
      end
      if type(value) ~= expected then
        error(key .. " must be " .. expected .. ", got " .. type(value))
      end
      rawset(self, key, value)
    end,
    __index = data,
  })
end

local player = make_validated({name = "string", hp = "number"})
player.name = "Hero"  -- OK
player.hp = 100       -- OK
-- player.level = 1   -- ERROR: Unknown field: level
-- player.hp = "full" -- ERROR: hp must be number, got string
```

---

## 算术运算符

算术操作的 metamethod：

| Metamethod | 操作 | 签名 |
|------------|------|------|
| `__add` | `a + b` | `(a, b) -> result` |
| `__sub` | `a - b` | `(a, b) -> result` |
| `__mul` | `a * b` | `(a, b) -> result` |
| `__div` | `a / b` | `(a, b) -> result` |
| `__mod` | `a % b` | `(a, b) -> result` |
| `__pow` | `a ^ b` | `(a, b) -> result` |
| `__unm` | `-a` | `(a) -> result` |

### 向量示例

```lua
local Vector = {}
Vector.__index = Vector

function Vector.new(x, y)
  return setmetatable({x = x or 0, y = y or 0}, Vector)
end

function Vector.__add(a, b)
  return Vector.new(a.x + b.x, a.y + b.y)
end

function Vector.__sub(a, b)
  return Vector.new(a.x - b.x, a.y - b.y)
end

function Vector.__mul(a, scalar)
  if type(a) == "number" then a, scalar = scalar, a end
  return Vector.new(a.x * scalar, a.y * scalar)
end

function Vector.__unm(v)
  return Vector.new(-v.x, -v.y)
end

function Vector:__tostring()
  return string.format("Vector(%.1f, %.1f)", self.x, self.y)
end

-- 用法
local a = Vector.new(1, 2)
local b = Vector.new(3, 4)
print(a + b)    -- Vector(4.0, 6.0)
print(a - b)    -- Vector(-2.0, -2.0)
print(a * 3)    -- Vector(3.0, 6.0)
print(-a)       -- Vector(-1.0, -2.0)
```

> **版本说明（5.4）**：算术 metamethod 仅在两个操作数都是 table 或其中一个操作数有 metamethod 时才调用。混合数字 + table 的算术需要显式处理。

---

## 比较运算符

| Metamethod | 操作 |
|------------|------|
| `__eq` | `a == b` |
| `__lt` | `a < b` |
| `__le` | `a <= b` |

> **规则**：`__eq` 仅在两个操作数都是 table（或都是完全 userdata）且具有相同 metatable 时才调用。

```lua
local Money = {}
Money.__index = Money

function Money.new(amount, currency)
  return setmetatable({amount = amount, currency = currency or "USD"}, Money)
end

function Money.__eq(a, b)
  return a.currency == b.currency and a.amount == b.amount
end

function Money.__lt(a, b)
  assert(a.currency == b.currency, "Cannot compare different currencies")
  return a.amount < b.amount
end

function Money.__le(a, b)
  assert(a.currency == b.currency, "Cannot compare different currencies")
  return a.amount <= b.amount
end

-- 用法
local a = Money.new(100, "USD")
local b = Money.new(200, "USD")
print(a == Money.new(100, "USD"))  -- true
print(a < b)                       -- true
print(a <= b)                      -- true
```

---

## 字符串表示：`__tostring`

由 `tostring()` 和 `print()` 调用：

```lua
local Point = {}
Point.__index = Point

function Point.new(x, y)
  return setmetatable({x = x, y = y}, Point)
end

function Point.__tostring(self)
  return string.format("(%d, %d)", self.x, self.y)
end

local p = Point.new(3, 4)
print(p)         -- (3, 4)
print(tostring(p)) -- (3, 4)
```

---

## 可调用 Table：`__call`

使 table 可以像函数一样被调用：

```lua
local Accumulator = {}
Accumulator.__index = Accumulator

function Accumulator.new(initial)
  return setmetatable({total = initial or 0}, Accumulator)
end

function Accumulator.__call(self, amount)
  self.total = self.total + amount
  return self.total
end

local acc = Accumulator.new(100)
print(acc(10))  -- 110
print(acc(20))  -- 130
print(acc(5))   -- 135
```

### 实际应用：记忆化函数

```lua
local function memoize(fn)
  local cache = {}
  return setmetatable({}, {
    __call = function(self, ...)
      local key = table.pack(...)
      -- 简单的字符串键（非生产级）
      local keystr = ""
      for i = 1, key.n do keystr = keystr .. tostring(key[i]) .. ":" end
      if cache[keystr] == nil then
        cache[keystr] = fn(...)
      end
      return cache[keystr]
    end,
  })
end

local fib = memoize(function(n)
  if n < 2 then return n end
  return fib(n - 1) + fib(n - 2)
end)

print(fib(30))  -- 832040（已缓存，速度快）
```

---

## 拼接：`__concat`

`..` 运算符调用的 metamethod：

```lua
local Tagged = {}
Tagged.__index = Tagged

function Tagged.new(tag, value)
  return setmetatable({tag = tag, value = value}, Tagged)
end

function Tagged.__concat(a, b)
  -- 处理两个方向的字符串拼接
  if type(a) == "string" then
    return a .. b.tag .. ":" .. b.value
  elseif type(b) == "string" then
    return a.tag .. ":" .. a.value .. b
  else
    return a.tag .. ":" .. a.value .. " " .. b.tag .. ":" .. b.value
  end
end

function Tagged:__tostring()
  return self.tag .. ":" .. self.value
end

local t1 = Tagged.new("status", "ok")
local t2 = Tagged.new("code", "200")
print("Result: " .. t1)       -- "Result: status:ok"
print(t1 .. " | " .. t2)      -- "status:ok | code:200"
print(t1 .. t2)               -- "status:ok code:200"
```

---

## 终结器：`__gc`

控制 table/userdata 被垃圾回收时的清理行为：

```lua
-- Lua 5.2+：table 可以有 __gc
local function make_resource(name)
  local r = {name = name}
  print("Acquired: " .. name)
  setmetatable(r, {
    __gc = function(self)
      print("Released: " .. self.name)
    end,
  })
  return r
end

do
  local r = make_resource("connection")
end  -- "Released: connection"（在此处被回收）

collectgarbage()  -- 强制 GC 以查看消息
```

### 重要警告

- **永远不要依赖 `__gc` 进行确定性释放。** GC 的时机是不可预测的。
- `__gc` 无法阻止对象销毁 — 它作为回收过程的一部分运行。
- 对于确定性清理，请使用显式的 `close()` 方法或 Lua 5.4 的 `<close>` 变量属性。
- 在 Lua 5.1 中，table 不能有 `__gc`（仅限 userdata）。

---

## 受保护的 Metatable：`__metatable`

控制 `getmetatable()` 返回的内容：

```lua
local mt = {
  __metatable = "no access",
  __index = {secret = 42},
}

local t = setmetatable({}, mt)
print(getmetatable(t))     -- "no access"（不是真正的 metatable）
-- setmetatable(t, {})     -- ERROR: cannot change protected metatable
```

这可以防止外部代码篡改 metatable。

---

## 迭代：`__pairs`、`__ipairs`

自定义迭代协议：

```lua
local Range = {}
Range.__index = Range

function Range.new(start, stop)
  return setmetatable({start = start, stop = stop}, Range)
end

-- __pairs（Lua 5.2+）
function Range.__pairs(range)
  local i = range.start - 1
  return function()
    i = i + 1
    if i <= range.stop then
      return i, i
    end
  end
end

for i in pairs(Range.new(1, 5)) do
  print(i)  -- 1 2 3 4 5
end
```

> **版本说明**：`__ipairs` 在 Lua 5.2 中已弃用。使用 `__pairs` 进行自定义迭代。

---

## 原始访问：`rawget` / `rawset`

绕过 metatable 分派：

```lua
local t = {}
setmetatable(t, {
  __index = function(_, k)
    return "missing: " .. tostring(k)
  end,
})

print(t.foo)          -- "missing: foo"（通过 __index）
print(rawget(t, "foo"))  -- nil（绕过 __index）
```

### 避免递归

经典的 `__newindex` 递归陷阱：

```lua
-- 错误：无限递归
local t = {}
setmetatable(t, {
  __newindex = function(self, k, v)
    self[k] = v  -- 再次触发 __newindex！
  end,
})

-- 修复：使用 rawset
local t = {}
setmetatable(t, {
  __newindex = function(self, k, v)
    rawset(self, k, v)  -- 无递归
  end,
})
```

### 只读代理

```lua
local function readonly(target)
  return setmetatable({}, {
    __index = target,
    __newindex = function()
      error("attempt to modify read-only table", 2)
    end,
    __len = function() return #target end,
    __pairs = function() return pairs(target) end,
  })
end

local data = {1, 2, 3}
local view = readonly(data)
print(view[1])     -- 1
-- view[4] = 5     -- ERROR: attempt to modify read-only table
```

---

## 基于原型的 OOP

Lua 没有类。它有原型 — 通过 `__index` 委托给其他对象的对象。

### 基本模式

```lua
local Entity = {}
Entity.__index = Entity

function Entity.new(id)
  return setmetatable({id = id, alive = true}, Entity)
end

function Entity:describe()
  return string.format("Entity<%d>", self.id)
end

function Entity:destroy()
  self.alive = false
end
```

### 继承

```lua
local Player = setmetatable({}, {__index = Entity})
Player.__index = Player

function Player.new(id, name, hp)
  local self = Entity.new(id)
  self.name = name
  self.hp = hp
  self.max_hp = hp
  return setmetatable(self, Player)
end

function Player:describe()
  return string.format("Player<%d, %s, HP:%d/%d>",
    self.id, self.name, self.hp, self.max_hp)
end

function Player:take_damage(amount)
  self.hp = math.max(0, self.hp - amount)
  if self.hp == 0 then self:destroy() end
end

-- 用法
local p = Player.new(1, "Hero", 100)
print(p:describe())       -- Player<1, Hero, HP:100/100>
p:take_damage(30)
print(p:describe())       -- Player<1, Hero, HP:70/100>
print(p.alive)            -- true（从 Entity 继承）
```

### 类型检查

```lua
function Entity.is_a(obj, class)
  local mt = getmetatable(obj)
  while mt do
    if mt == class then return true end
    mt = getmetatable(mt)
  end
  return false
end

print(p:is_a(Player))  -- true
print(p:is_a(Entity))  -- true
```

---

## 常见陷阱

### 1. `__index` 仅在键缺失时触发

```lua
local t = {existing = "value"}
setmetatable(t, {
  __index = function(_, k)
    return "fallback"
  end,
})

print(t.existing)  -- "value"（原始命中，未调用 __index）
print(t.missing)   -- "fallback"（原始未命中，调用 __index）
```

### 2. 共享原型变异

```lua
-- BUG：所有实例共享同一个 defaults table
local Entity = {defaults = {hp = 100, mp = 50}}
Entity.__index = Entity

local a = setmetatable({}, Entity)
local b = setmetatable({}, Entity)

a.defaults.hp = 0
print(b.defaults.hp)  -- 0（共享！）

-- 修复：为每个实例克隆 defaults
function Entity.new(id)
  local defaults = {hp = 100, mp = 50}
  return setmetatable({id = id, hp = defaults.hp, mp = defaults.mp}, Entity)
end
```

### 3. Metamethod 中的递归

```lua
-- BUG：__index 调用 self[k] 又触发 __index
local t = setmetatable({}, {
  __index = function(self, k)
    return self[k]  -- 无限递归！
  end,
})

-- 修复：使用 rawget
local t = setmetatable({}, {
  __index = function(self, k)
    return rawget(self, k)  -- 返回 nil，无递归
  end,
})
```

### 4. 性能：过多未命中

```lua
-- 不好：每次访问都强制触发 __index
local t = setmetatable({value = 10}, {
  __index = function(_, k)
    -- 每次未命中的复杂逻辑
    return compute(k)
  end,
})

-- 更好：将计算值缓存到 table 中
local computed = {}
setmetatable(computed, {
  __index = function(_, k)
    if computed[k] == nil then
      computed[k] = compute(k)
    end
    return computed[k]
  end,
})
```

### 5. `__newindex` 不会在已有原始键上触发

```lua
local t = {existing = "value"}
setmetatable(t, {
  __newindex = function(_, k, v)
    print("intercepted: " .. k)
    rawset(_, k, v)
  end,
})

t.existing = "new"  -- 无消息！键存在，直接原始写入
t.missing = "new"   -- "intercepted: missing"（__newindex 触发）
```

---

## 最佳实践

### 1. 使用 `__index` 实现继承，而非存储数据

```lua
-- 好：方法在原型上，数据在实例上
local Class = {x = 0, y = 0}  -- 默认值（很少通过 __index 访问）
Class.__index = Class

function Class.new(x, y)
  return setmetatable({x = x, y = y}, Class)  -- 数据在实例上
end

-- 不好：所有数据在原型上，实例为空
local Class = {}
Class.__index = Class
-- 实例共享 Class.x、Class.y — 变异 bug！
```

### 2. 记录 Metamethod 契约

```lua
--- 加法运算（不可变操作）
-- @param a Vector
-- @param b Vector
-- @return Vector 新向量
function Vector.__add(a, b)
  return Vector.new(a.x + b.x, a.y + b.y)
end
```

### 3. 在 Metamethod 中优先使用 `rawget`/`rawset`

```lua
-- 在 __index 和 __newindex 中始终使用原始访问
__index = function(self, k) return rawget(self, k) end
__newindex = function(self, k, v) rawset(self, k, v) end
```

### 4. 在构造时使用 `setmetatable`

```lua
-- 在创建时设置 metatable
function Entity.new(id)
  return setmetatable({id = id}, Entity)
end

-- 避免在创建后更改 metatable
-- t = setmetatable(t, new_mt)  -- 危险，破坏类型假设
```

### 5. 保持 Metatable 轻量

```lua
-- 好：小而专注的 metatable
local mt = {
  __index = prototype,
  __tostring = tostring_fn,
}

-- 避免：包含所有可能 metamethod 的巨型 metatable
-- 每个 metamethod 都增加分派开销
```

---

## 版本说明

### Lua 5.1

- `__gc` 仅对 userdata 有效，对 table 无效
- `__ipairs` 是自定义迭代 metamethod（不是 `__pairs`）
- 使用 `setfenv`/`getfenv` 进行环境操作
- 没有 `__eq` metamethod（使用原始相等比较）

### Lua 5.2/5.3

- `__gc` 对 table 有效（在 table 变为可达之前设置 metatable）
- `__pairs` 取代 `__ipairs`（已弃用）
- 可用 `__eq` metamethod
- 通过 `rawequal()` 进行原始相等比较

### Lua 5.4

- `__close` metamethod 用于 to-be-closed 变量（RAII）
- `__warn` metamethod 用于警告消息
- `__type` metamethod 自定义 `type()` 输出
- `__name` metamethod 用于 `pairs()` 迭代顺序提示

```lua
-- Lua 5.4：自定义类型名
local t = setmetatable({}, {
  __name = "MyCustomType",
})
print(type(t))         -- "table"（仍然，__name 不会改变 type()）
print(getmetatable(t).__name)  -- "MyCustomType"
```

### LuaJIT

- 某些 metamethod 被高效追踪，其他可能中断 JIT 追踪
- 算术 metamethod 通常优化良好
- 使用函数分派的 `__index` 可能抑制追踪编译
- 保持 metamethod 密集的代码路径简单以获得最佳 JIT 性能

---

## 知识检查

<details>
<summary>1. <code>__newindex</code> 何时触发？</summary>

仅在写入 table 上不存在的原始字段时触发。如果键已存在，写入直接到 table 而不触发 `__newindex`。
</details>

<details>
<summary>2. <code>__index</code> 作为 table 与作为函数有什么区别？</summary>

作为 table：Lua 在该 table 中查找缺失的键（类似继承）。作为函数：Lua 用 `(self, key)` 调用它并返回其返回值（类似计算属性）。
</details>

<details>
<summary>3. 为什么必须在 <code>__newindex</code> 中使用 <code>rawset</code>？</summary>

如果 `__newindex` 执行 `self[k] = v` 且 `k` 是新键，它会再次触发 `__newindex`（无限递归）。`rawset` 直接写入 table 而不经过 metamethod。
</details>

<details>
<summary>4. 为什么不能依赖 <code>__gc</code> 进行确定性清理？</summary>

垃圾回收时机是非确定性的。对象可能立即被回收、很久以后被回收，或在单次会话中永远不被回收。请改用显式的 close/destroy 方法。
</details>

<details>
<summary>5. 对设置了 <code>__metatable</code> 的 table 调用 <code>getmetatable()</code> 会发生什么？</summary>

它返回 `__metatable` 的值而非实际的 metatable。这会向外部代码隐藏真正的 metatable。
</details>

---

## 关键要点

- **Metatable 控制行为**，而非数据 — 它们定义 table 如何响应操作
- **`__index`** 处理缺失键的读取；`__newindex` 处理缺失键的写入
- **算术 metamethod** 为自定义类型启用运算符重载
- **`rawget`/`rawset`** 绕过 metamethod — 对避免递归至关重要
- **基于原型的 OOP** 使用 `__index` 链实现继承
- **代理模式** 支持只读视图、验证和日志记录
- **永远不要依赖 `__gc`** 进行确定性资源管理
- **稳定的 table 形状** 减少 metatable 分派开销

---

## 练习

### 初级（30–60 分钟）

1. **只读 Table**：实现 `readonly(t)` 返回一个代理 table，任何写入尝试都会引发错误。支持 `pairs`、`ipairs` 和 `#`。

2. **字符串 Metatable**：创建一个 `String` 包装器，使用 `__add` 进行拼接，`__len` 获取长度，`__tostring` 显示。

3. **Clamp 函数**：重载 `math.clamp` 使其同时适用于数字和自定义 `Clamped` 类型，使用 metamethod。

### 中级（1–2 小时）

4. **类系统**：构建一个最小 OOP 库，包含 `class()`、`extend()` 和 `super()`。支持 `isinstance()` 检查。

5. **日志代理**：创建一个代理，记录 table 上的每次读取和写入操作，包括键、值和操作类型。

6. **不可变记录**：实现一个 `Record` 类型，每个字段只设置一次，之后变为只读。使用 `__newindex` 在首次赋值后强制不可变性。

### 高级（2–4 小时）

7. **观察者模式**：构建一个响应式 table，字段变更时触发回调函数。支持嵌套字段观察。

8. **表达式 AST**：使用运算符 metamethod 创建一个小型表达式求值器。`local expr = (Var("x") + 3) * Var("y")` 应产生一个可调用对象，给定环境 table 后进行求值。

---

## 示例代码

本章的可运行示例：
- `examples/intermediate/01-prototype-entity.lua` — 基于原型的 OOP
- `examples/intermediate/05-readonly-table.lua` — 只读代理模式
- `examples/advanced/01-ecs-system.lua` — 基于 metatable 的组件系统

---

## 延伸阅读

- [Lua 5.4 参考手册 — 第 3.4.8 节](https://www.lua.org/manual/5.4/manual.html#3.4.8)
- [Programming in Lua（第 4 版）— 第 13、16 章](https://www.lua.org/pil/)
- [下一章：06 — 模块](06-modules.md)
