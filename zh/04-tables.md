# 04 — Table

> **阶段**: A（核心语言素养）  
> **前置条件**: 第 03 章 — 函数  
> **预计时间**: 2–3 小时阅读 + 2–4 小时练习  
> **Lua 版本**: 5.1、5.3、5.4、LuaJIT（差异已标注）

---

## 学习目标

完成本章后，你将能够：

1. **解释 Lua table 的双重内部表示**（数组部分 + 哈希部分）及其对性能的影响
2. **正确使用长度运算符**，并理解其行为未定义的情况
3. **使用所有语法形式构造 table**，并根据场景选择合适的构造方式
4. **运用引用语义**避免别名 bug
5. **有效使用 table 库**完成常见操作（insert、remove、sort、concat）

---

## Table 作为核心数据结构

Table 是 Lua **唯一**的数据结构。它可以实现数组、映射、记录、集合和对象：

```lua
-- 数组（连续整数键）
local array = {10, 20, 30}

-- 映射（任意键）
local map = {name = "Lua", version = 5.4}

-- 记录（固定字段）
local point = {x = 100, y = 200}

-- 集合（值作为键）
local set = {apple = true, banana = true, cherry = true}

-- 对象（通过 metatable 实现方法）
local obj = {value = 0}
function obj:inc() self.value = self.value + 1 end
```

---

## 数组部分 vs 哈希部分

Lua 在内部将每个 table 分为两部分：

| 部分 | 键 | 查找方式 | 使用场景 |
|------|------|----------|----------|
| 数组部分 | 从 1 开始的连续整数 | 直接索引（O(1)） | 列表、序列 |
| 哈希部分 | 其他所有键 | 哈希表（均摊 O(1)） | 映射、记录、混合结构 |

```lua
-- 主要使用数组部分（密集整数键 1..3）
local array = {10, 20, 30}

-- 主要使用哈希部分（字符串键）
local record = {name = "Lua", version = 5.4}

-- 混合：数组部分用于 1..3，哈希部分用于 "extra"
local mixed = {10, 20, 30, extra = "value"}
```

### 为什么这对性能很重要

```lua
-- 好：密集数组 —— 数组部分，缓存友好
local items = {}
for i = 1, 10000 do
  items[i] = i * 2
end

-- 差：稀疏数组 —— 哈希部分，迭代更慢
local items = {}
items[1] = "a"
items[10000] = "b"
-- #items 的结果未定义（参见下方长度运算符）
```

### 预分配 Table

Lua 动态增长 table。预分配可以避免重复的内存重新分配：

```lua
-- 按已知大小预分配
local result = {}
for i = 1, 10000 do
  result[i] = compute(i)  -- 已经有空间
end

-- 构造器会预分配数组部分
local t = {nil, nil, nil, nil, nil}  -- 5 个槽位已就绪
```

---

## 长度运算符

`#` 运算符返回 table **序列**的长度 —— 从 1 开始、没有空洞的连续整数键范围：

```lua
-- 定义良好的序列
local t = {10, 20, 30, 40, 50}
print(#t)  -- 5

-- 序列在第一个空洞处终止
local t = {10, 20, nil, 40, 50}
print(#t)  -- 2（在 nil 空洞处停止）
```

### 何时 `#t` 未定义

长度运算符**仅**对序列有明确定义。对于有空洞或非连续键的 table，结果取决于具体实现：

```lua
-- 空洞：行为因 Lua 版本/实现而异
local t = {10, nil, 30}
print(#t)  -- 可能是 0、1 或 2（未定义）

-- 非连续整数键
local t = {[1] = "a", [3] = "c"}
print(#t)  -- 未定义（可能是 1 或 3）
```

> **规则**：仅在 table 为序列（从 1 到 n，无 nil 空洞）时使用 `#t`。对于其他情况，请显式迭代。

### 版本差异

| Lua 版本 | `#t` 在有空洞时的行为 |
|-------------|----------------------|
| 5.1 | 可能返回序列中最后一个非 nil 元素的索引 |
| 5.3/5.4 | 返回序列与非序列之间的边界 |
| LuaJIT | 遵循 5.1 语义 |

---

## Table 构造

### 字面量构造器

```lua
-- 空 table
local t = {}

-- 数组风格
local items = {10, 20, 30}

-- 记录风格
local config = {host = "localhost", port = 8080}

-- 混合风格
local player = {name = "Hero", hp = 100, inventory = {}}

-- 嵌套
local matrix = {
  {1, 0, 0},
  {0, 1, 0},
  {0, 0, 1},
}
```

### 显式键构造器

```lua
-- 整数键（不从 1 开始）
local t = {[0] = "zero", [1] = "one", [2] = "two"}

-- 含特殊字符的字符串键
local t = {["key with spaces"] = 1, ["key.with.dots"] = 2}

-- 计算键
local field = "name"
local t = {[field] = "Lua"}  -- t.name = "Lua"
```

### 尾随逗号

Lua 允许在构造器中使用尾随逗号：

```lua
-- 两者都有效
local t = {1, 2, 3}
local t = {1, 2, 3,}  -- 尾随逗号没有问题
```

### 函数式构造

```lua
-- 从函数输出创建 table
local function make_range(n)
  return {[n] = true}  -- 稀疏：仅键 n 存在
end

-- 使用 table.pack 处理可变参数
local function collect(...)
  return table.pack(...)
end
local t = collect(1, 2, 3)
print(t.n)  -- 3（table.pack 添加了 .n 字段）
```

---

## 引用语义

Table 是引用类型。赋值复制的是引用，而非数据本身：

```lua
local a = {x = 1, y = 2}
local b = a          -- b 指向同一个 table
b.x = 10

print(a.x)           -- 10（a 也受到了影响！）
print(a == b)        -- true（同一个对象）
```

### 别名 Bug

```lua
-- BUG：通过别名修改 table
local function add_item(inventory, item)
  inventory[#inventory + 1] = item
end

local player = {inventory = {}}
local inv = player.inventory
add_item(inv, "sword")
add_item(inv, "shield")

-- 两者引用同一个 table
print(#player.inventory)  -- 2
print(#inv)               -- 2
```

### 身份 vs 相等性

```lua
local a = {1, 2, 3}
local b = {1, 2, 3}

print(a == b)   -- false（不同的对象）
print(a ~= b)   -- true

-- 要比较内容，使用 deep_equal（参见 01-basics.md）
```

---

## 常见 Table 模式

### 集合

```lua
-- 成员测试
local function make_set(items)
  local s = {}
  for _, v in ipairs(items) do
    s[v] = true
  end
  return s
end

local fruits = make_set({"apple", "banana", "cherry"})
print(fruits["apple"])   -- true
print(fruits["grape"])   -- nil
```

### 袋 / 多重集

```lua
-- 计数出现次数
local function make_bag(items)
  local bag = {}
  for _, v in ipairs(items) do
    bag[v] = (bag[v] or 0) + 1
  end
  return bag
end

local counts = make_bag({"a", "b", "a", "c", "a"})
print(counts["a"])  -- 3
print(counts["b"])  -- 1
```

### 队列（FIFO）

```lua
-- 基于数组的队列
local Queue = {}
Queue.__index = Queue

function Queue.new()
  return setmetatable({head = 1, tail = 0}, Queue)
end

function Queue:push(value)
  self.tail = self.tail + 1
  self[self.tail] = value
end

function Queue:pop()
  if self.head > self.tail then return nil end
  local value = self[self.head]
  self[self.head] = nil  -- 允许 GC 回收
  self.head = self.head + 1
  return value
end

function Queue:empty()
  return self.head > self.tail
end

-- 使用示例
local q = Queue.new()
q:push("a")
q:push("b")
print(q:pop())   -- "a"
print(q:pop())   -- "b"
print(q:empty()) -- true
```

### 栈（LIFO）

```lua
-- 基于 table 的栈
local stack = {}
function stack.push(t, v) t[#t + 1] = v end
function stack.pop(t) return table.remove(t) end
function stack.peek(t) return t[#t] end

-- 使用示例
local s = {}
stack.push(s, 10)
stack.push(s, 20)
print(stack.pop(s))  -- 20
print(stack.peek(s)) -- 10
```

### 链表

```lua
-- 单向链表
local function make_node(value, next)
  return {value = value, next = next}
end

local head = make_node(1,
  make_node(2,
    make_node(3, nil)))

-- 遍历
local node = head
while node do
  print(node.value)
  node = node.next
end
```

---

## Table 库

`table` 库提供了常用操作：

### table.insert / table.remove

```lua
local t = {1, 2, 3}

-- 在指定位置插入
table.insert(t, 4)        -- 追加：{1, 2, 3, 4}
table.insert(t, 2, 99)    -- 在索引 2 处插入：{1, 99, 2, 3, 4}

-- 从指定位置移除
table.remove(t)            -- 移除最后一个：{1, 99, 2, 3}
table.remove(t, 1)         -- 移除第一个：{99, 2, 3}
```

### table.sort

```lua
local items = {3, 1, 4, 1, 5, 9}

-- 默认：升序
table.sort(items)
-- items = {1, 1, 3, 4, 5, 9}

-- 自定义比较函数
table.sort(items, function(a, b) return a > b end)
-- items = {9, 5, 4, 3, 1, 1}

-- 按字段排序
local people = {{name="c", age=30}, {name="a", age=25}, {name="b", age=35}}
table.sort(people, function(a, b) return a.age < b.age end)
```

> **警告**：`table.sort` 不是稳定的。相等元素的相对顺序可能会改变。

### table.concat

```lua
local parts = {"hello", "world", "lua"}

-- 用分隔符连接
print(table.concat(parts, " "))   -- "hello world lua"
print(table.concat(parts, ", "))  -- "hello, world, lua"

-- 按范围连接
print(table.concat(parts, "", 1, 2))  -- "helloworld"
```

### table.pack / table.unpack（5.2+）

```lua
-- 将可变参数打包成带长度的 table
local t = table.pack(1, 2, 3)
print(t.n)  -- 3

-- 将 table 解包为参数
local values = {10, 20, 30}
print(table.unpack(values))  -- 10  20  30

-- 按范围解包
print(table.unpack(values, 2, 3))  -- 20  30
```

### table.move（5.3+）

```lua
-- 在 table 之间移动元素（或在同一 table 内移动）
local a = {1, 2, 3, 4, 5}
local b = {}
table.move(a, 1, 3, 1, b)
-- b = {1, 2, 3}

-- 在同一 table 内移动元素
table.move(a, 1, 3, 2, a)
-- a = {1, 1, 2, 3, 5}
```

---

## Table 复用模式

在性能关键代码中，应避免分配新的 table：

```lua
-- 差：每次调用都分配新 table
local function get_bounding_box(entity)
  return {
    x = entity.x,
    y = entity.y,
    w = entity.width,
    h = entity.height,
  }
end

-- 更好：复用预分配的 table
local bbox = {}
local function get_bounding_box(entity)
  bbox.x = entity.x
  bbox.y = entity.y
  bbox.w = entity.width
  bbox.h = entity.height
  return bbox
end

-- 更好：返回单个值（无分配）
local function get_bounding_box(entity)
  return entity.x, entity.y, entity.width, entity.height
end
```

---

## 常见陷阱

### 1. 假设 `pairs` 的迭代顺序

```lua
-- 错误：顺序不保证
local t = {c = 3, a = 1, b = 2}
for k, v in pairs(t) do
  print(k, v)  -- 顺序可能因运行而异
end

-- 正确：如果需要顺序，先对键排序
local keys = {}
for k in pairs(t) do keys[#keys + 1] = k end
table.sort(keys)
for _, k in ipairs(keys) do
  print(k, t[k])  -- a 1, b 2, c 3（字母顺序）
end
```

### 2. 使用 `nil` 作为值

`nil` 在 table 中表示该键不存在：

```lua
local map = {}
map["a"] = nil       -- 与不设置相同
print(map["a"])      -- nil

-- 无法区分"键存在但值为 nil"和"键不存在"
-- 解决方法：使用哨兵值
local NULL = {}
map["a"] = NULL
print(map["a"] == NULL)  -- true（键存在）
print(map["b"] == NULL)  -- false（键不存在）
```

### 3. 在迭代过程中修改 Table

```lua
-- 错误：在 pairs 迭代中修改
local t = {a = 1, b = 2, c = 3}
for k, v in pairs(t) do
  if v == 2 then t[k] = nil end  -- 可能跳过元素
end

-- 正确：先收集键，再修改
local to_remove = {}
for k, v in pairs(t) do
  if v == 2 then to_remove[#to_remove + 1] = k end
end
for _, k in ipairs(to_remove) do
  t[k] = nil
end
```

### 4. 对非序列使用 `#t`

```lua
-- 错误：假设 #t 对稀疏 table 有效
local t = {[1] = "a", [5] = "e"}
print(#t)  -- 未定义！可能是 1 或 5

-- 正确：使用 next 或手动迭代
local max = 0
for k in pairs(t) do
  if type(k) == "number" and k > max then max = k end
end
```

### 5. 意外的 Table 共享

```lua
-- BUG：所有玩家共享同一个默认 table
local defaults = {hp = 100, mp = 50}
local players = {}
for i = 1, 3 do
  players[i] = defaults  -- 全部指向同一个 table！
end
players[1].hp = 0
print(players[2].hp)  -- 0（不是 100！）

-- 修复：为每个玩家创建新 table
for i = 1, 3 do
  players[i] = {hp = defaults.hp, mp = defaults.mp}
end

-- 更好：使用工厂函数
local function make_player(overrides)
  return {hp = 100, mp = 50, name = "unknown", unpack(overrides or {})}
end
```

---

## 最佳实践

### 1. 尽早定义 Table 的形状

为了性能，应以一致的形状初始化 table：

```lua
-- 好：形状一致 —— Lua 会优化查找
local player = {
  name = "",
  hp = 0,
  mp = 0,
  x = 0.0,
  y = 0.0,
}

-- 差：稀疏且不一致 —— 迫使使用哈希查找
local player = {}
player.name = "Hero"
-- 后续：随机添加字段
player.inventory = {}
player.buffs = {}
```

### 2. 使用显式的包含标志

当 `nil` 存在歧义时，使用标志字段：

```lua
-- 问题：无法判断 "speed" 是被设为 nil 还是从未设置
local config = {speed = nil}
print(config["speed"])      -- nil
print(config["gravity"])    -- nil（从未设置）

-- 解决方案：使用显式标志
local config = {speed = nil, _has_speed = true}
if config._has_speed then
  print("speed was explicitly set to nil")
end
```

### 3. 分离配置与运行时数据

将稳定的配置与可变状态分开：

```lua
-- 配置：创建一次，永不修改
local ENEMIES = {
  goblin = {hp = 20, damage = 5, speed = 1.0},
  orc    = {hp = 50, damage = 10, speed = 0.8},
}

-- 运行时：为每个实例创建，在游戏过程中修改
local function spawn_enemy(type)
  local template = ENEMIES[type]
  return {
    type = type,
    hp = template.hp,
    damage = template.damage,
    speed = template.speed,
    x = 0, y = 0,
  }
end
```

### 4. 对数组优先使用 `ipairs`

`ipairs` 在遇到第一个 nil 时停止，行为可预测：

```lua
local t = {1, 2, nil, 4, 5}

-- ipairs 在索引 2 处停止（第一个 nil）
for i, v in ipairs(t) do
  print(i, v)  -- 1 1, 2 2（然后停止）
end

-- pairs 不会停止 —— 遍历所有非 nil 键
for k, v in pairs(t) do
  print(k, v)  -- 1 1, 2 2, 4 4, 5 5（顺序未定义）
end
```

### 5. 记录 Table 的形状

```lua
--- 玩家状态
-- @field name string 玩家显示名称
-- @field hp number 当前生命值 [0, max_hp]
-- @field max_hp number 最大生命值
-- @field position {x: number, y: number} 世界坐标
-- @field inventory string[] 物品 ID 列表
local player = {
  name = "Hero",
  hp = 100,
  max_hp = 100,
  position = {x = 0, y = 0},
  inventory = {},
}
```

---

## 版本说明

### Lua 5.1

- `table.maxn(t)` 返回最大的整数键（在 5.2+ 中已弃用）
- `unpack(t)` 是全局函数（在 5.2+ 中被 `table.unpack` 替代）
- `table.pack` / `table.unpack` 不可用

```lua
-- Lua 5.1
print(table.maxn({[100] = "a"}))  -- 100
print(unpack({1, 2, 3}))          -- 1 2 3
```

### Lua 5.3/5.4

- `table.pack` / `table.unpack` 可用
- `table.move` 可用（5.3+）
- `#t` 对序列的行为更加一致

```lua
-- Lua 5.3+
local t = table.pack(1, 2, 3)
print(t.n)  -- 3

table.move({1, 2, 3}, 1, 2, 1, {})
-- 返回 {1, 2}
```

### LuaJIT

- Table 操作经过了大量优化
- `table.insert` / `table.remove` 可能被 JIT 内联
- 避免在热循环中创建大量小 table —— JIT 追踪可能无法优化掉内存分配

---

## 知识检测

<details>
<summary>1. 为什么 Lua 将 table 分为数组部分和哈希部分？</summary>

为了性能。密集整数键（数组）使用直接索引（无哈希开销的 O(1)）。其他键使用哈希表。这使得数组在顺序访问时比映射更快。
</details>

<details>
<summary>2. 何时 <code>#t</code> 未定义？</summary>

当 `t` 不是序列时 —— 即它有空洞（整数键之间有 nil 值）或键不连续。结果取决于具体实现。
</details>

<details>
<summary>3. 赋值 <code>t.a = nil</code> 会发生什么？</summary>

键 `a` 会从 table 中移除。无法区分"键存在但值为 nil"和"键从未被设置"—— 两者都返回 nil。
</details>

<details>
<summary>4. 为什么 <code>table.sort</code> 不适合稳定排序？</summary>

Lua 参考手册明确说明排序不是稳定的。相等元素的相对顺序可能会改变。如果稳定性很重要，请使用辅助排序字段。
</details>

<details>
<summary>5. 迭代并删除 table 元素最安全的方式是什么？</summary>

先将要删除的键收集到一个单独的列表中，然后在第二轮遍历中删除它们。永远不要在 `pairs` 迭代过程中修改 table —— 它可能会跳过或重复元素。
</details>

---

## 关键要点

- **Table 是 Lua 唯一的数据结构** —— 数组、映射、记录、集合、对象
- **双重表示**：数组部分（密集整数）+ 哈希部分（其他所有键）
- **长度运算符 `#t`**：仅对序列（从 1 到 n，无空洞）有明确定义
- **引用语义**：赋值复制的是引用，而非内容
- **Table 库**：`insert`、`remove`、`sort`、`concat`、`pack`/`unpack`、`move`
- **在热路径中复用 table** 以避免分配压力
- **永远不要在 pairs 迭代中修改 table** —— 先收集键

---

## 练习

### 初级（30–60 分钟）

1. **频率计数器**：编写 `count_tokens(text)`，按空白符分割文本并返回一个词频 table。

2. **浅拷贝**：实现 `shallow_copy(t)`，仅复制第一层。验证嵌套 table 仍然是共享的。

3. **集合操作**：为两个以 `{value = true}` 表示的集合实现 `set_union(a, b)` 和 `set_intersection(a, b)`。

### 中级（1–2 小时）

4. **深拷贝**：实现 `deep_copy(t)`，处理嵌套 table 和循环引用。记录边界情况。

5. **环形缓冲区**：实现一个固定大小的环形缓冲区，支持 `push`、`pop` 和 `full` 操作。对索引使用模运算。

6. **Table 展平**：编写 `flatten(t, depth)` 展平嵌套数组。`flatten({1, {2, {3, 4}}, 5})` → `{1, 2, 3, 4, 5}`。

### 高级（2–4 小时）

7. **弱引用 Table 观察者**：使用弱引用 table（`__mode`）创建一个弱键观察者，跟踪对象生命周期而不阻止垃圾回收。

8. **不可变 Map**：实现一个持久化（不可变）map，`set` 返回新 map 并保留旧 map。针对结构共享进行优化。

---

## 示例代码

本章的可运行示例：
- `examples/beginner/05-table-copy.lua` — 浅拷贝和深拷贝模式
- `examples/intermediate/01-prototype-entity.lua` — 基于 table 的面向对象
- `examples/intermediate/05-readonly-table.lua` — 不可变 table 模式
- `examples/advanced/03-object-pool.lua` — 性能优化中的 table 复用

---

## 延伸阅读

- [Lua 5.4 参考手册 — 第 3.4 节](https://www.lua.org/manual/5.4/manual.html#3.4)
- [Lua 编程（第 4 版）— 第 7 章](https://www.lua.org/pil/)
- [下一章: 05 — Metatable](05-metatables.md)
