# 03 — 函数

> **阶段**：A（核心语言基础）  
> **前置章节**：第 02 章 — 控制流  
> **预计时间**：阅读 2–3 小时 + 练习 2–4 小时  
> **Lua 版本**：5.1、5.3、5.4、LuaJIT（差异已标注）

---

## 学习目标

完成本章后，你将能够：

1. **使用所有语法形式声明和调用函数**，并理解每种形式的适用场景
2. **正确使用多返回值**，包括调用点的展开规则
3. **编写可变参数函数**，安全处理不同数量的参数
4. **区分 `.` 和 `:`**，正确使用方法语法
5. **理解闭包和上值** — 捕获了什么、什么会逃逸、什么会被修改

---

## 函数声明形式

Lua 提供三种等价的函数声明方式：

```lua
-- 形式 1：function 语句（语法糖）
local function add(a, b)
  return a + b
end

-- 形式 2：局部变量赋值
local add = function(a, b)
  return a + b
end

-- 形式 3：table 字段（用于模块）
local M = {}
function M.add(a, b)    -- 等价于 M.add = function(...)
  return a + b
end
```

**关键区别**：形式 1（`local function`）允许函数在体内递归引用自身。形式 2 要求名称在函数体之前已存在：

```lua
-- 形式 1：递归 — 正常工作
local function factorial(n)
  if n <= 1 then return 1 end
  return n * factorial(n - 1)  -- OK：名称在体内可见
end

-- 形式 2：递归 — 运行时失败
local factorial = function(n)
  if n <= 1 then return 1 end
  return n * factorial(n - 1)  -- BUG：factorial 此时为 nil！
end

-- 形式 2：递归 — 必须先声明
local factorial
factorial = function(n)
  if n <= 1 then return 1 end
  return n * factorial(n - 1)  -- OK：factorial 现在存在了
end
```

> **陷阱**：`local function f() end` 和 `local f = function() end` 在 `f` 是递归时**不等价**。前者创建前向声明；后者不会。

---

## 一等函数

函数是值。它们可以存储在变量中、作为参数传递、从其他函数返回。

```lua
-- 函数作为值
local double = function(x) return x * 2 end
print(double(5))  -- 10

-- 函数在 table 中
local ops = {
  add = function(a, b) return a + b end,
  mul = function(a, b) return a * b end,
}
print(ops.add(3, 4))  -- 7

-- 函数作为参数
local function apply(fn, x)
  return fn(x)
end
print(apply(double, 5))  -- 10
```

### 函数作为回调

```lua
-- Filter：传入函数决定保留什么
local function filter(array, predicate)
  local result = {}
  for _, v in ipairs(array) do
    if predicate(v) then
      result[#result + 1] = v
    end
  end
  return result
end

local numbers = {1, 2, 3, 4, 5, 6}
local evens = filter(numbers, function(n) return n % 2 == 0 end)
-- evens = {2, 4, 6}
```

### 高阶函数

返回函数的函数：

```lua
-- 比较器工厂
local function by_field(field, order)
  order = order or "asc"
  return function(a, b)
    if order == "asc" then
      return a[field] < b[field]
    else
      return a[field] > b[field]
    end
  end
end

local items = {{name="c", score=90}, {name="a", score=80}, {name="b", score=95}}
table.sort(items, by_field("score", "desc"))
-- items[1].name == "b", items[2].name == "c", items[3].name == "a"
```

---

## 多返回值

函数可以返回多个值：

```lua
local function minmax(array)
  local min, max = array[1], array[1]
  for i = 2, #array do
    if array[i] < min then min = array[i] end
    if array[i] > max then max = array[i] end
  end
  return min, max
end

local lo, hi = minmax({3, 1, 4, 1, 5, 9})
print(lo, hi)  -- 1  9
```

### 返回位置展开规则

只有 return 语句中**最后一个**表达式会展开为多个值：

```lua
local function multi()
  return 1, 2, 3
end

-- 所有值被接收
local a, b, c = multi()
print(a, b, c)  -- 1  2  3

-- 只接收第一个，其余丢弃
local a, b = multi()
print(a, b)      -- 1  2

-- 在 table 构造器中：所有值被接收
local t = {multi()}
print(#t)        -- 3

-- 在函数调用中：所有值被接收
print(multi())   -- 1  2  3
```

### 包装多返回值

当需要在非最后位置捕获所有返回值时，用括号包装：

```lua
local function multi()
  return 1, 2, 3
end

-- 括号强制求值为单值
local a, b = (multi())
print(a, b)  -- 1  nil

-- table 捕获保留所有值
local t = {multi()}
print(t[1], t[2], t[3])  -- 1  2  3
```

### 丢弃不需要的返回值

使用 `_` 表示不需要的值：

```lua
local function complex_return()
  return "result", nil, 42
end

local value, _, code = complex_return()
print(value, code)  -- "result"  42
```

---

## 可变参数

函数可以使用 `...` 接受可变数量的参数：

```lua
local function sum(...)
  local acc = 0
  for _, v in ipairs({...}) do
    acc = acc + v
  end
  return acc
end

print(sum(1, 2, 3))      -- 6
print(sum(1, 2, 3, 4, 5))  -- 15
```

### 选择特定参数

```lua
local function log(level, ...)
  local message = string.format(...)
  print("[" .. level .. "] " .. message)
end

log("INFO", "Processing %d items", 42)
-- [INFO] Processing 42 items
```

### 转发可变参数

使用 `...` 透传参数：

```lua
local function debug_print(...)
  print("DEBUG:", ...)
end

debug_print("x", 42, true)  -- DEBUG:  x  42  true
```

### Lua 5.1 与 5.3+ 的可变参数差异

Lua 5.1 中，`select` 负索引可访问尾部可变参数：

```lua
-- 仅 Lua 5.1
local function last(...)
  return select(-1, ...)  -- 最后一个参数
end
print(last(1, 2, 3))  -- 3
```

Lua 5.3+ 中，使用 `table.pack`/`table.unpack` 模式：

```lua
-- Lua 5.3+
local function last(...)
  local args = {...}
  return args[#args]
end
print(last(1, 2, 3))  -- 3
```

> **性能提示**：`{...}` 每次调用都创建一个 table。在热路径中，优先使用 `select` 和逐个参数访问，而非 table 构造。

---

## 方法语法

Lua 有两种调用约定用于带隐式对象的函数：

```lua
-- 点语法（显式 self）
local player = {health = 100}
function player.take_damage(self, amount)
  self.health = self.health - amount
end
player.take_damage(player, 10)  -- 必须显式传递 self

-- 冒号语法（隐式 self）
function player:take_damage(amount)
  self.health = self.health - amount
end
player:take_damage(10)  -- self 是 player，自动传递
```

`:` 是语法糖。`obj:method(x)` 被解构为 `obj.method(obj, x)`。

### 何时使用哪种

```lua
-- 冒号：函数操作对象时（OOP 风格）
local Vector = {}
function Vector:new(x, y)
  return setmetatable({x = x, y = y}, Vector)
end
function Vector:magnitude()
  return math.sqrt(self.x^2 + self.y^2)
end

-- 点：工具函数，不绑定特定对象
local math_utils = {}
function math_utils.clamp(value, lo, hi)
  return math.max(lo, math.min(hi, value))
end
math_utils.clamp(10, 0, 5)  -- 没有对象 — 用点正确
```

> **陷阱**：对不使用 `self` 的函数使用 `:` 会浪费隐式参数并误导读者。纯工具函数用 `.`。

---

## 闭包与上值

闭包是从外围作用域捕获变量的函数。被捕获的变量称为**上值**。

```lua
local function make_counter(start)
  local n = start or 0       -- n 是返回函数的上值
  return function()
    n = n + 1
    return n
  end
end

local c = make_counter(10)
print(c())  -- 11
print(c())  -- 12
print(c())  -- 13
```

### 多个闭包共享状态

当两个闭包捕获同一个变量时，它们共享该变量：

```lua
local function make_pair()
  local value = nil
  
  local function get() return value end
  local function set(v) value = v end
  
  return get, set
end

local get, set = make_pair()
print(get())    -- nil
set(42)
print(get())    -- 42
```

### 循环中的闭包 — 经典 Bug

捕获循环变量捕获的是**变量本身**，而非捕获时的值：

```lua
-- BUG：所有函数共享同一个 `i`
local functions = {}
for i = 1, 5 do
  functions[i] = function() return i end
end
print(functions[1]())  -- 5（不是 1！）
print(functions[3]())  -- 5（不是 3！）

-- 修复 1：每次迭代创建新变量
local functions = {}
for i = 1, 5 do
  local j = i  -- 每次迭代的新上值
  functions[i] = function() return j end
end
print(functions[1]())  -- 1

-- 修复 2：使用工厂函数
local functions = {}
for i = 1, 5 do
  functions[i] = (function(n) return function() return n end end)(i)
end
print(functions[1]())  -- 1
```

### 上值生命周期

上值通过引用捕获，只要有任何闭包引用它们就会存活：

```lua
local function create()
  local big_data = string.rep("x", 1000000)  -- 大量分配
  return function()
    return #big_data  -- 保持 big_data 存活！
  end
end

local fn = create()
-- big_data 仍在内存中，因为 fn 引用了它
print(fn())  -- 1000000

-- fn 被垃圾回收后，big_data 可以被释放
fn = nil
```

---

## 尾调用

Lua 支持尾调用优化（TCO）。尾调用是函数在尾部位置的调用（函数做的最后一件事）：

```lua
-- 尾调用 — 优化后（不创建新栈帧）
local function fact_tail(n, acc)
  acc = acc or 1
  if n <= 1 then return acc end
  return fact_tail(n - 1, n * acc)  -- 尾部位置
end

-- 非尾调用 — return 不在尾部位置
local function fact(n)
  if n <= 1 then return 1 end
  return n * fact(n - 1)  -- 必须先乘法再返回
end
```

### 尾调用语法

```lua
-- 尾调用：return f(...)
-- 非尾调用：return ... f(...)

local function g(x)
  return x + 1
end

-- 尾调用
local function f(x)
  return g(x)        -- 尾调用
end

-- 非尾调用
local function f(x)
  return 1 + g(x)    -- g(x) 先求值，再加 1
end
```

> **陷阱**：`return f(...) and g(...)` **不是**尾调用。`and` 运算符意味着表达式求值为单个值，不是尾调用。

### 实际应用：蹦床模式

尾调用支持无限递归而不会栈溢出：

```lua
-- 状态机蹦床模式
local function state_a(input)
  if input == "go" then return state_b end
  return state_a  -- 停留在状态 A
end

local function state_b(input)
  if input == "back" then return state_a end
  return state_b
end

-- 运行状态机（无栈增长）
local current = state_a
current = current("go")    -- state_b
current = current("back")  -- state_a
current = current("stay")  -- state_a（对自身的尾调用）
```

---

## 函数中的错误处理

函数是 Lua 中错误处理的主要边界：

### 返回错误约定

```lua
local function divide(a, b)
  if b == 0 then
    return nil, "division by zero"
  end
  return a / b
end

local result, err = divide(10, 0)
if not result then
  print("Error: " .. err)
end
```

### pcall 保护调用

```lua
local function risky_operation()
  error("something went wrong")
end

local success, result = pcall(risky_operation)
if not success then
  print("Caught: " .. result)  -- Caught: something went wrong
end
```

### 断言

```lua
local function process(config)
  assert(type(config) == "table", "config must be a table")
  assert(config.host ~= nil, "config.host is required")
  assert(type(config.port) == "number", "config.port must be a number")
  -- ... 处理 config
end

-- 快速失败，附带清晰消息
local ok, err = pcall(process, {})
if not ok then
  print(err)  -- config.host is required
end
```

---

## 常见陷阱

### 1. 混淆 `.` 和 `:`

```lua
local obj = {value = 10}

function obj:double()       -- 冒号：self 隐式
  self.value = self.value * 2
end

function obj.triple(self)   -- 点：self 必须显式
  self.value = self.value * 3
end

obj:double()    -- OK
obj.triple(obj) -- OK 但冗长

-- 错误：
obj.triple()    -- ERROR：self 为 nil
```

### 2. 捕获循环变量

参见[循环中的闭包](#循环中的闭包--经典-bug)。修复：每次迭代创建局部副本。

### 3. 从热路径返回临时 table

```lua
-- 每次调用都分配 — 热路径中性能差
local function get_position(entity)
  return {x = entity.x, y = entity.y}
end

-- 更好：复用 table 或返回单个值
local function get_position(entity)
  return entity.x, entity.y
end
```

### 4. 可变参数遮蔽

```lua
-- 混乱：`v` 遮蔽了外部循环变量
local function process(...)
  for _, v in ipairs({...}) do
    local v = v  -- 不必要的遮蔽
    print(v)
  end
end
```

### 5. 忘记函数是引用类型

```lua
local function noop() end

local a = noop
local b = a
a = nil
print(type(b))  -- "function"（b 仍引用该函数）
```

---

## 最佳实践

### 1. 保持函数契约短小

```lua
-- 差：职责过多
function process_order(order, user, payment, inventory, shipping)
  -- 200 行做所有事
end

-- 好：单一职责
function validate_order(order) ... end
function charge_payment(payment) ... end
function update_inventory(inventory) ... end
function schedule_shipment(shipping) ... end
function process_order(order)
  validate_order(order)
  charge_payment(order.payment)
  update_inventory(order.items)
  schedule_shipment(order.shipping)
end
```

### 2. 分离纯函数与副作用

```lua
-- 纯函数：相同输入 → 相同输出，无副作用
local function calculate_total(items)
  local total = 0
  for _, item in ipairs(items) do
    total = total + item.price * item.quantity
  end
  return total
end

-- 副作用：修改外部状态
local function save_order(order)
  db.insert("orders", order)
  log.info("Order saved", order.id)
end
```

### 3. 使用守卫子句

```lua
-- 代替深层嵌套：
function process(user)
  if user then
    if user.active then
      if user.has_permission then
        -- 做某事
      end
    end
  end
end

-- 守卫子句：
function process(user)
  if not user then return end
  if not user.active then return end
  if not user.has_permission then return end
  -- 做某事
end
```

### 4. 文档化返回契约

```lua
--- 除法运算
-- @param a number 被除数
-- @param b number 除数（必须非零）
-- @return number 商，出错时返回 nil
-- @return string 失败时的错误消息
local function divide(a, b)
  if b == 0 then
    return nil, "division by zero"
  end
  return a / b
end
```

### 5. 在热路径中缓存函数

```lua
-- 差：每次调用都查表
for i = 1, 1000000 do
  math.sin(i)  -- _ENV["math"].sin(i)
end

-- 好：局部引用
local sin = math.sin
for i = 1, 1000000 do
  sin(i)  -- 直接寄存器访问
end
```

---

## 版本差异

### Lua 5.1

- 使用 `setfenv`/`getfenv` 操作函数环境
- 没有 `_ENV` 变量 — 环境按函数设置
- `select('#', ...)` 返回可变参数计数

```lua
-- Lua 5.1 环境操作
local f = function() return x end
setfenv(f, {x = 42})
print(f())  -- 42
```

### Lua 5.3/5.4

- 使用 `_ENV`（常规上值）代替 `setfenv`/`getfenv`
- 整数除法 `//` 运算符
- 位运算符可用
- Lua 5.4 新增 `close` 变量属性，用于自动资源清理

```lua
-- Lua 5.4 to-be-closed 变量（需要 5.4+）
-- local function process()
--   local <close> resource = acquire_resource()
--   -- 离开作用域时自动释放 resource
--   do_work(resource)
-- end  -- 在此释放 resource，即使发生错误
--
-- <close> 属性确保 __close 元方法在作用域退出时运行。
-- 适用于 RAII 风格的资源管理：文件句柄、锁、连接。
```

### LuaJIT

- FFI 允许直接调用 C 函数，无需包装函数
- trace 编译器可能自动内联小函数
- 避免在热循环中使用多态参数的函数调用

---

## 知识检查

<details>
<summary>1. <code>local function f() end</code> 和 <code>local f = function() end</code> 有什么区别？</summary>

前者创建前向声明，允许 `f` 在体内递归引用自身。后者不会 — `f` 在函数体内为 `nil`，递归调用在运行时失败。
</details>

<details>
<summary>2. 当只有两个变量接收 <code>return a, b, c</code> 的结果时会发生什么？</summary>

第三个值被丢弃。`local x, y = f()` 其中 `f` 返回三个值，得到 `x = a`、`y = b`，`c` 丢失。
</details>

<details>
<summary>3. 为什么 <code>for i = 1, 5 do fns[i] = function() return i end end</code> 返回全是 5？</summary>

所有闭包捕获的是同一个变量 `i`，而非捕获时的值。循环结束时 `i` 为 5，所以所有闭包返回 5。修复：在循环体内创建局部副本（`local j = i`）。
</details>

<details>
<summary>4. 什么是尾调用，为什么重要？</summary>

尾调用是 `return f(...)` — 函数做的最后一件事。Lua 通过复用当前栈帧来优化它，而非创建新栈帧。这防止了深层递归代码中的栈溢出（蹦床模式）。
</details>

<details>
<summary>5. 何时使用 <code>:</code> 与 <code>.</code> 函数语法？</summary>

当函数操作对象且需要隐式 `self` 时使用 `:`（OOP 方法）。对于不接受隐式对象的工具函数，或显式传递 `self` 时使用 `.`。
</details>

---

## 核心要点

- **三种声明形式**：`local function`、`local f = function`、`M.f = function` — 第一种支持自引用
- **多返回值**：只有最后一个表达式展开；用 `_` 丢弃
- **可变参数**：`...` 捕获额外参数；`{...}` 分配 table — 热路径中避免
- **方法语法**：`:` 隐式传递 `self`；`.` 需要显式传递
- **闭包**：按引用捕获变量，而非值；经典循环 bug 共享一个变量
- **尾调用**：`return f(...)` 复用栈；支持蹦床模式
- **守卫子句**：扁平化嵌套；失败时提前返回

---

## 练习

### 初级（30–60 分钟）

1. **Memoize**：实现 `memoize(fn)` 缓存结果。将缓存限制为 N 个条目（LRU 或简单重置）。

2. **Once**：编写 `once(fn)` 仅在首次调用时执行 `fn`，后续调用返回相同结果。

3. **Flip**：实现 `flip(fn)` 反转参数顺序。`flip(subtract)(10, 3)` 应返回 `subtract(3, 10)`。

### 中级（1–2 小时）

4. **Compose**：编写 `compose(f, g)` 返回一个函数，先应用 `g` 再应用 `f`。扩展为 `compose(...)` 接受多个函数。

5. **Method vs Dot API**：设计一个 `Stack` 模块，同时提供冒号语法（`stack:push()`）和点语法（`stack_push(stack)`）接口。验证它们行为一致。

6. **可变参数转发**：编写 `partial(fn, ...)` 预填充前导参数。`partial(add, 1)(2)` 应返回 `3`。

### 高级（2–4 小时）

7. **协程迭代器**：编写函数 `coroutine_iter(fn)`，接受一个 yield 值的函数，返回可在 `for` 循环中使用的迭代器函数。

8. **蹦床**：实现蹦床包装器，将递归函数转换为迭代尾调用。用深层嵌套计算测试。

---

## 示例代码

本章的可运行示例：
- `examples/intermediate/04-stateful-module.lua` — 基于闭包的有状态模块
- `examples/intermediate/02-event-bus.lua` — 高阶函数模式
- `examples/advanced/01-ecs-system.lua` — 函数密集型架构

---

## 延伸阅读

- [Lua 5.4 参考手册 — 第 3 节](https://www.lua.org/manual/5.4/manual.html#3)
- [Lua 程序设计（第 4 版）— 第 5–6 章](https://www.lua.org/pil/)
- [下一章：04 — Table](04-tables.md)
