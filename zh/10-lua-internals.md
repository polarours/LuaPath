# 10 — Lua 内部机制

> **阶段**：D（内部机制与原生集成）  
> **前置知识**：第 09 章 — 标准库  
> **时间估计**：阅读 3–4 小时 + 练习 3–5 小时  
> **Lua 版本**：5.1、5.3、5.4、LuaJIT（差异已标注）

---

## 学习目标

完成本章后，你将能够：

1. **解释 Lua 的 VM 架构** — 从源码到字节码执行的完整流程
2. **理解基于寄存器的字节码模型** 以及它对性能的影响
3. **理解垃圾回收机制** — 增量式与分代式、调优和常见陷阱
4. **解释闭包和 upvalue 的工作原理** — 打开与关闭的 upvalue
5. **运用内部知识编写更快的 Lua 代码**

---

## VM 架构

Lua 的执行流程：

```
Source code
    ↓
Lexer / Parser
    ↓
Abstract Syntax Tree (AST)
    ↓
Proto (Function Prototype)
    ↓
Bytecode
    ↓
VM Dispatch Loop
    ↓
Execution
```

### 核心数据结构

| 结构 | 用途 |
|-----------|---------|
| `Proto` | 函数原型：常量、指令、upvalue 描述符、调试信息 |
| `Closure` | 可执行对象，绑定 `Proto` + 捕获的 upvalue |
| `CallInfo` | 调用帧元数据：函数指针、保存的 pc、栈基址 |
| `TValue` | 标记值：类型标签 + 载荷（指针或立即数） |
| `Table` | 带数组部分的哈希表 |
| `GCObject` | 所有垃圾回收对象的头信息 |

---

## 基于寄存器的字节码

Lua 使用**基于寄存器**的虚拟机，不同于基于栈的 VM（JVM、CPython）：

### 基于栈的（对比参考）

```
PUSH 1
PUSH 2
ADD        -- pops 2, pushes result
STORE x
```

### Lua 基于寄存器的

```text
LOADK  R1, 1      -- R1 = 1
LOADK  R2, 2      -- R2 = 2
ADD    R0, R1, R2  -- R0 = R1 + R2
SETTABUP R0, x    -- _ENV.x = R0
```

### 为什么选择基于寄存器？

- **更少的指令**：表达式无需为每个操作数执行 push/pop
- **更好的局部性**：临时值留在寄存器中，而非栈上
- **编译器优化**：寄存器分配可以复用槽位

代价是：指令更宽（更多编码位），编译器复杂度增加。

### 查看字节码

```bash
# 反汇编一个 Lua 文件
luac -l file.lua

# 输出显示指令格式：
# main <file.lua:1> (7 instructions, 28 bytes)
# 1       [1]  LOADK     1  -1    ; 1
# 2       [1]  LOADK     2  -2    ; 2
# 3       [1]  ADD       0  1  2  ; R0 = R1 + R2
# ...
```

---

## 值表示：标记值

每个 Lua 值都表示为一个**标记值**：

```
TValue = {
  tag: 类型标签（nil、boolean、number、string、table、function、thread、userdata）
  value: 载荷（立即标量或指向 GC 对象的指针）
}
```

### 影响

- **动态类型检查**频繁发生（标签比较）
- **热点路径中可预测的类型**减少分支
- **数值表示**因版本不同（5.1 中为单精度浮点，5.3+ 中为整数+浮点）

### 数值表示（5.3+）

```lua
-- Lua 5.3+ 使用两种子类型
print(math.type(42))      -- "integer"（存储为 C long/int64）
print(math.type(3.14))    -- "float"（存储为 C double）
print(math.type(42.0))    -- "float"（末尾的 .0 很重要！）

-- 当两个操作数都是整数时，整数运算更快
-- 浮点运算使用 IEEE 754 double
```

---

## 闭包与 Upvalue

### 打开与关闭的 Upvalue

```lua
local function outer()
  local x = 10  -- 这个局部变量被 inner 捕获

  local function inner()
    return x  -- x 是一个 upvalue
  end

  return inner
end

local fn = outer()
-- 此时，x 的栈帧已退出。
-- upvalue 已"关闭"——值被移动到 upvalue 对象中。
print(fn())  -- 10（仍然可以访问！）
```

**打开的 upvalue**：指向仍在栈上的局部变量（栈帧处于活动状态）。

**关闭的 upvalue**：值已被复制/锚定到 upvalue 对象中（栈帧已退出）。

```text
outer frame: local x
   ^
   | (outer 活动期间为 open upvalue)
inner closure

当 outer 返回时：
   VM "关闭" upvalue → 值移动到 upvalue 对象
   内部闭包仍然有效，引用已关闭的 upvalue
```

### Upvalue 生命周期

1. **创建**：当闭包被创建时，它将引用的局部变量捕获为打开的 upvalue
2. **共享**：多个闭包可以共享同一个 upvalue（同一个变量）
3. **关闭**：当外层函数返回时，所有打开的 upvalue 都会被关闭
4. **GC**：当没有闭包引用时，关闭的 upvalue 会被垃圾回收

### 性能影响

```lua
-- 不好：很多闭包 = 很多 upvalue 对象
for i = 1, 10000 do
  local fn = function() return i end  -- 每次迭代创建新的闭包 + upvalue
end

-- 更好：减少闭包创建
local functions = {}
for i = 1, 10000 do
  functions[i] = i  -- 只存储值，不需要闭包
end
```

---

## 垃圾回收

Lua 使用**自动内存管理**，通过垃圾回收实现。

### 增量式标记-清除

Lua 5.1-5.3 的默认模式：

1. **标记**：从根（全局变量、栈、注册表）遍历并标记可达对象
2. **清除**：回收未标记的对象
3. **增量式**：每次执行少量工作以避免长时间停顿

```
GC cycle:
  pause → mark → sweep → pause → ...
```

### 分代模式（5.4）

Lua 5.4 新增分代 GC：

- **新生代**：新分配的对象，更频繁回收
- **老生代**：存活多次回收周期的对象，回收频率更低
- **好处**：减少大量短命对象场景下的 GC 工作量

```lua
-- 切换到分代模式（5.4）
collectgarbage("generational")

-- 或设置步进大小
collectgarbage("setstepmul", 200)  -- 默认为 200
```

### GC 调优参数

| 参数 | 默认值 | 效果 |
|-----------|---------|--------|
| `pause` | 100 | GC 启动新周期前等待的时间 |
| `stepmul` | 200 | GC 步进的激进程度 |
| `stepsize` | 10000 | 每次 GC 步进的字节数 |

```lua
-- 调优为低延迟
collectgarbage("setpause", 50)     -- 更早启动 GC
collectgarbage("setstepmul", 100)  -- 更小的步进

-- 调优为高吞吐量
collectgarbage("setpause", 200)    -- 等待更久
collectgarbage("setstepmul", 400)  -- 更大的步进
```

### GC 元方法

```lua
-- __gc 用于清理（table：5.2+，userdata：始终支持）
local r = setmetatable({}, {
  __gc = function(self)
    print("释放: " .. tostring(self.name))
  end
})
r.name = "resource"

r = nil  -- 最终会被回收
collectgarbage()  -- 强制回收
-- 输出："释放: resource"
```

### 为什么 GC 对性能很重要

```lua
-- 不好：每次迭代都产生垃圾
for i = 1, 1000000 do
  local t = {x = i, y = i * 2}  -- 每次迭代都创建新 table
  process(t)
end

-- 更好：复用 table
local t = {}
for i = 1, 1000000 do
  t.x = i
  t.y = i * 2
  process(t)
end

-- 最好：完全避免 table
for i = 1, 1000000 do
  process(i, i * 2)  -- 无分配
end
```

---

## 字符串驻留

Lua 会对字符串进行**驻留**（去重）：

```lua
local a = "hello"
local b = "hello"
print(a == b)  -- true（同一个驻留字符串）

-- 字符串操作会创建新字符串
local c = a .. " world"  -- 新字符串，"hello" 不变
```

### 影响

- **相等性检查**对字符串是 O(1)（指针比较）
- **内存**：许多相同的字符串共享一次分配
- **分配成本**：创建大量唯一字符串会增加 GC 压力

---

## Table 内部机制

### 数组部分与哈希部分

```
Table {
  array: {value, value, ...}      -- 从 1 开始的连续整数键
  hash:  {key → value, ...}       -- 其他所有键
  sizearray: 数组槽位数量
  lsizenode: 哈希大小的 log2
}
```

### Table 增长

当 table 需要更多空间时：

1. **数组部分**：大小翻倍
2. **哈希部分**：大小翻倍
3. 元素重新哈希/移动

```lua
-- 预分配提示（5.3+）
local t = {}
for i = 1, 10000 do
  t[i] = i  -- Table 逐步增长
end

-- 更好：预分配
local t = table.create(10000)  -- 仅 5.3+
for i = 1, 10000 do
  t[i] = i
end
```

---

## 常见陷阱

### 1. 假设 GC 在可预测的时间运行

```lua
-- 不要：依赖立即回收
local t = {big_data}
t = nil
-- big_data 在此处不能保证被释放
collectgarbage()  -- 强制回收，但仍不保证时机
```

### 2. 忽视分配压力

```lua
-- 不好：高分配率
for i = 1, 1000000 do
  local s = string.format("item_%d", i)  -- 每次迭代创建新字符串
end

-- 更好：复用或避免
local parts = {}
for i = 1, 1000000 do
  parts[i] = "item_" .. i  -- 仍有分配，但更少
end
```

### 3. 假设整数运算精确（5.1）

```lua
-- Lua 5.1：所有数字都是浮点数
local x = 10000000000000001
print(x == x + 1)  -- true！（精度丢失）

-- Lua 5.3+：整数运算是精确的（在 int64 范围内）
-- local x = 10000000000000001LL  -- 整数字面量（仅 5.3+）
-- print(x == x + 1)  -- false（正确！）
```

### 4. 循环变量的闭包捕获（再次讨论）

```lua
-- 经典问题：所有闭包共享同一个变量
local fns = {}
for i = 1, 5 do
  fns[i] = function() return i end  -- 全部返回 5
end

-- 修复：每次迭代创建局部副本
for i = 1, 5 do
  local j = i
  fns[i] = function() return j end
end
```

### 5. 不理解字符串的不可变性

```lua
-- 字符串是不可变的——每次操作都创建新字符串
local s = ""
for i = 1, 10000 do
  s = s .. "x"  -- O(n²)——创建了 10000 个中间字符串
end

-- 使用 table.concat 实现 O(n) 字符串构建
local parts = {}
for i = 1, 10000 do
  parts[i] = "x"
end
local s = table.concat(parts)
```

---

## 最佳实践

### 1. 优化前先测量

```lua
-- 使用 os.clock 进行性能分析
local start = os.clock()
-- ... 热点代码 ...
local elapsed = os.clock() - start
print(string.format("耗时: %.6f 秒", elapsed))
```

### 2. 减少 Table 抖动

```lua
-- 在热点路径中复用 table
local temp = {}
local function process(x, y)
  temp.x = x
  temp.y = y
  return compute(temp)
end
```

### 3. 缓存全局变量

```lua
-- 模块级缓存
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt

local function compute(x, y)
  return sqrt(sin(x)^2 + cos(y)^2)
end
```

### 4. 尽可能使用整数运算（5.3+）

```lua
-- 整数运算比浮点运算更快
local sum = 0
for i = 1, 1000000 do
  sum = sum + i  -- 整数加法
end

-- 避免隐式浮点转换
local x = 10 / 2    -- 5.0（浮点数）
local y = 10 // 2   -- 5（整数，更快）
```

### 5. 用 GC 统计进行分析

```lua
-- 监控 GC 压力
collectgarbage("collect")
local before = collectgarbage("count")
-- ... 代码 ...
collectgarbage("collect")
local after = collectgarbage("count")
print(string.format("分配量: %.1f KB", after - before))
```

---

## 版本说明

### Lua 5.1

- 单一数字类型（浮点数）
- 无 `math.type`
- 仅支持增量式 GC
- `setfenv`/`getfenv` 用于环境操作
- `string.dump` 用于字节码查看

### Lua 5.3

- 双数字类型（整数 + 浮点数）
- 原生位运算符
- `math.type` 用于数值子类型检查
- `table.move` 用于元素转移
- `string.format` 支持整数专用格式说明符

### Lua 5.4

- 分代 GC 模式
- `__close` 变量属性（待关闭变量）
- `coroutine.close` 用于显式协程清理
- `warn` 函数用于警告消息
- 整数除法改进

### LuaJIT

- JIT 编译器追踪热点循环
- 基于追踪的优化（内联、死代码消除）
- FFI 用于直接 C 互操作
- 某些模式会破坏 JIT 追踪（过多守卫、多态）

---

## 知识检查

<details>
<summary>1. 为什么基于寄存器的字节码在很多表达式中比基于栈的更快？</summary>

基于寄存器的指令直接引用操作数，避免了 push/pop 的开销。像 `a + b * c` 这样的表达式编译后指令更少，因为中间结果留在寄存器中。
</details>

<details>
<summary>2. 打开的 upvalue 和关闭的 upvalue 有什么区别？</summary>

打开的 upvalue 指向仍在活动栈上的局部变量。关闭的 upvalue 在外层函数返回后，将值复制到了 upvalue 对象中。
</details>

<details>
<summary>3. 为什么分代 GC 更适合分配密集的工作负载？</summary>

它更频繁地回收年轻对象（很可能很快消亡），减少了总工作量。老生对象回收频率更低，因为它们更可能继续存活。
</details>

<details>
<summary>4. 为什么局部变量比全局变量更快？</summary>

局部变量存储在 VM 寄存器中（直接访问）。全局变量需要通过 `_ENV` 进行表查找——每次访问需要两次哈希查找（`_ENV["math"]["sin"]`）。
</details>

<details>
<summary>5. 字符串驻留是什么，什么时候会成为问题？</summary>

Lua 会对相同字符串进行去重。这节省了内存，但也意味着创建大量唯一字符串（例如字符串拼接）会分配新的驻留字符串，增加 GC 压力。
</details>

---

## 核心要点

- **基于寄存器的 VM**：比栈机更少的指令、更好的局部性
- **标记值**：动态类型检查；可预测的类型有助于性能
- **打开/关闭的 upvalue**：闭包按引用捕获；值在作用域退出时被锚定
- **增量式 GC**：小步执行避免长时间停顿；分代模式（5.4）适合分配密集的工作
- **字符串驻留**：相等性检查为 O(1)，但唯一字符串会增加 GC 压力
- **Table 内部机制**：数组部分用于密集整数键，哈希部分用于其他所有键
- **整数运算**（5.3+）：比浮点更快；使用 `//` 进行整数除法

---

## 练习

### 入门（30–60 分钟）

1. **字节码查看**：使用 `luac -l` 反汇编简单函数。找出变量访问、算术运算和函数调用对应的 opcode。

2. **GC 监控**：编写一个函数，在代码块前后报告 `collectgarbage("count")` 来测量内存分配。

3. **字符串分配**：比较字符串拼接与 `table.concat` 在构建大字符串时的分配率。

### 中级（1–2 小时）

4. **Upvalue 查看器**：编写一个函数 `get_upvalues(fn)`，返回函数的 upvalue 名称和值（使用 `debug` 库）。

5. **Table 形状分析**：创建一个工具，使用 `debug.getinfo` 或内部启发式方法报告 table 的数组/哈希部分大小。

6. **GC 压力测试**：在包含大量短命对象的工作负载上，比较增量式与分代 GC 的性能。

### 高级（2–4 小时）

7. **字节码编译器**：编写一个简单的表达式编译器，输出算术表达式的 Lua 字节码。

8. **内存分析器**：构建一个分析器，跟踪随时间变化的分配模式，找出热点。

---

## 示例代码

本章的可运行示例：
- `examples/advanced/01-ecs-system.lua` — 性能敏感的 table 用法
- `examples/advanced/03-object-pool.lua` — GC 感知的对象复用

---

## 延伸阅读

- [Lua 5.4 参考手册 — 第 1 节](https://www.lua.org/manual/5.4/manual.html#1)
- [Lua 的演进（PDF）](https://www.lua.org/doc/record.pdf)
- [Lua 编程（第 4 版）— 第 30 章](https://www.lua.org/pil/)
- [下一章：11 — Lua C API](11-lua-c-api.md)
