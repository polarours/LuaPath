# 01 — 基础：值、类型与作用域

> **阶段**：A（核心语言素养）  
> **前置要求**：无——这是起点  
> **预计时间**：2–3 小时阅读 + 2–4 小时练习  
> **Lua 版本**：5.1、5.3、5.4、LuaJIT（差异已标注）

---

## 学习目标

完成本章后，你将能够：

1. **区分 Lua 的 8 种运行时类型**，并解释哪些是引用类型，哪些是值类型
2. **编写作用域正确的代码**，正确使用 `local` 并避免意外的全局变量
3. **预测真值**——理解任何 Lua 值在布尔上下文中的行为
4. **解释版本差异**——数值表示方面的差异（5.1 vs 5.3+）
5. **识别性能影响**——字符串不可变性和 table 引用的性能含义

---

## 核心类型

Lua 有 8 种运行时类型，分为两大类：

### 值类型（按值复制）

| 类型 | 描述 | 备注 |
|------|------|------|
| `nil` | 值的缺失 | 只有 `nil` 属于 `nil` 类型 |
| `boolean` | `true` 或 `false` | 用于条件判断 |
| `number` | 数值 | 整数或浮点数（5.3+） |

### 引用类型（按引用复制）

| 类型 | 描述 | 备注 |
|------|------|------|
| `string` | 不可变字符序列 | 通过驻留实现相等比较 |
| `table` | 关联数组 | 唯一的数据结构 |
| `function` | 可调用代码 | 一等公民 |
| `thread` | 协程状态 | 独立执行 |
| `userdata` | 不透明 C 数据 | 与原生代码的桥梁 |

```lua
-- 检查类型
print(type(nil))             -- "nil"
print(type(true))            -- "boolean"
print(type(42))              -- "number"（5.3+ 中返回 "integer"）
print(type("hello"))         -- "string"
print(type({}))              -- "table"
print(type(function() end))  -- "function"
print(type(coroutine.create(function() end)))  -- "thread"
```

> **版本说明（5.3+）**：Lua 5.3 区分整数和浮点数。`type(42)` 返回 `"integer"`，`type(3.14)` 返回 `"float"`。在 5.1 和 5.2 中，两者都返回 `"number"`。

---

## 真值规则

Lua 对布尔求值有简单但重要的规则：

```
假值：  false, nil
真值：  其他所有值（包括 0、""、{}、function() end）
```

这与许多语言不同：

| 语言 | 假值 |
|------|------|
| Lua | `false`、`nil` |
| JavaScript | `false`、`null`、`undefined`、`0`、`""`、`NaN`、`[]`（数组是真值！） |
| Python | `False`、`None`、`0`、`""`、`[]`、`{}`、`set()` |
| Ruby | `false`、`nil`（与 Lua 相同） |

### 实际影响

```lua
-- 常见模式：提供默认值
local name = input or "Anonymous"  -- 当 input 为 nil 或 false 时生效

-- 但要注意：false 是一个有效的值！
local config = options.debug or false  -- 错误：当 options.debug 为 false 时结果总是 false
local config = options.debug ~= nil and options.debug or false  -- 正确

-- 显式检查 nil
if value == nil then ... end      -- 显式判断
if value ~= nil then ... end      -- 显式否定

-- 不要这样做（对 false、0、"" 会失败）
if value then ... end             -- 只检查真值
```

> **陷阱**：`or` 模式（`value or default`）在 `false` 是有意义的值时会失败。当 `false` 是有效输入时，请使用显式的 `nil` 检查。

---

## 变量与作用域

### 局部变量（推荐）

```lua
local x = 10        -- 函数或块作用域
local y = x + 5     -- 可以引用更早声明的局部变量
```

**为什么 `local` 更快：**

1. **寄存器分配**：局部变量映射到虚拟机寄存器（直接访问）
2. **无哈希查找**：全局变量需要访问 `_ENV` 表
3. **编译器优化**：局部作用域能实现更好的优化

### 全局变量（谨慎使用）

```lua
global = 42         -- 实际上是 _ENV["global"] = 42
```

每次全局变量访问都是一次表查找：

```lua
-- 这段代码：
print(math.sin(0))

-- 实际上是：
_ENV["print"](_ENV["math"].sin(0))
```

### 块作用域

```lua
local x = 10

do
  local x = 20      -- 新变量，遮蔽了外部的 x
  print(x)          -- 20
end

print(x)            -- 10（外部的 x 未改变）

-- 常见模式：限制变量生命周期
do
  local temp = compute_expensive()
  use(temp)
  -- temp 离开作用域，可被 GC 回收
end
```

### 函数作用域

```lua
local function outer()
  local x = 1
  
  local function inner()
    print(x)        -- 可以访问外部函数的局部变量（upvalue）
  end
  
  inner()
end
```

---

## 数值表示

### Lua 5.1 和 5.2

单一 `number` 类型，通常是 IEEE 754 双精度浮点数：

```lua
-- Lua 5.1
print(type(42))       -- "number"
print(type(3.14))     -- "number"
print(42 == 42.0)     -- true（相同的值）
```

**影响：**
- 大于 2^53 的整数会丢失精度
- 没有整数特有的操作
- 按位运算需要 `bit32` 库或外部模块

### Lua 5.3 及更高版本

双重表示：`integer` 和 `float`：

```lua
-- Lua 5.3+
print(type(42))       -- "integer"
print(type(3.14))     -- "float"
print(42 == 42.0)     -- true（比较时自动转换）

-- 整数除法
print(5 // 2)         -- 2（整数结果）
print(5 / 2)          -- 2.5（浮点数结果）

-- 按位运算符
print(5 | 3)          -- 7（按位或）
print(5 & 3)          -- 1（按位与）
print(5 ~ 3)          -- 6（按位异或）
print(~5)             -- -6（按位取反）
print(5 << 1)         -- 10（左移）
print(5 >> 1)         -- 2（右移）
```

> **版本说明**：LuaJIT 使用单一数值类型，但提供 FFI 用于 C 风格整数（`ffi.cast("int", 42)`）。

---

## 字符串

### 不可变性

Lua 中的字符串是不可变的。操作会创建新字符串：

```lua
local s = "hello"
local t = s .. " world"  -- 创建新字符串，s 不变
print(s)                  -- "hello"
print(t)                  -- "hello world"
```

### 性能影响

**低效** — O(n²) 分配：

```lua
local result = ""
for i = 1, 10000 do
  result = result .. i .. ", "  -- 每次迭代都创建新字符串！
end
```

**高效** — O(n) 分配：

```lua
local parts = {}
for i = 1, 10000 do
  parts[#parts + 1] = tostring(i)
  parts[#parts + 1] = ", "
end
local result = table.concat(parts)  -- 单次分配
```

### 字符串驻留

Lua 会驻留（去重）字符串字面量：

```lua
local a = "hello"
local b = "hello"
print(a == b)             -- true（相同的驻留字符串）
print(rawequal(a, b))     -- Lua 中相等的字符串返回 true

local c = string.rep("h", 5)  -- "hhhhh"
print(c == "hello")           -- false（内容不同）
```

---

## Table：引用语义

Table 是引用类型。赋值复制的是引用，而非内容：

```lua
local a = {x = 1}
local b = a          -- b 与 a 引用同一个 table
b.x = 2

print(a.x)           -- 2（a 受到 b 的修改影响！）
print(b.x)           -- 2
print(a == b)        -- true（同一个对象）
```

### 身份 vs. 相等

```lua
local a = {1, 2, 3}
local b = {1, 2, 3}

print(a == b)        -- false（不同的对象，相同的内容）
print(a ~= b)        -- true

-- 要比较内容，必须遍历：
local function deep_equal(x, y)
  if type(x) ~= type(y) then return false end
  if type(x) ~= "table" then return x == y end
  
  for k, v in pairs(x) do
    if not deep_equal(v, y[k]) then return false end
  end
  for k, v in pairs(y) do
    if not deep_equal(x[k], v) then return false end
  end
  return true
end

print(deep_equal(a, b))  -- true（相同的内容）
```

---

## 常见陷阱

### 1. 意外的全局变量

```lua
-- BUG：缺少 'local'
function compute()
  result = 42  -- 创建了全局变量！
  return result
end

-- 修复：始终使用 local
function compute()
  local result = 42
  return result
end
```

**检测方法**：使用 `luac -l` 或启用严格模式：

```lua
-- 严格模式（Lua 5.2+）
setmetatable(_G, {
  __newindex = function(_, name)
    error("Attempt to write to global: " .. name, 2)
  end
})
```

### 2. 误以为 `0` 是假值

```lua
-- BUG：在 Lua 中 0 是真值
if count ~= 0 then  -- 正确
  process()
end

-- 错误：
if count then  -- 当 count 为 0 时会失败！
  process()
end
```

### 3. 用 `==` 比较 Table

```lua
-- BUG：比较的是引用，而非内容
local a = {1, 2, 3}
local b = {1, 2, 3}

if a == b then  -- 总是 false！
  print("same")
end

-- 修复：显式比较内容
```

### 4. 循环中的字符串拼接

参见上方[字符串](#字符串)部分的高效模式。

---

## 最佳实践

### 1. 默认使用 `local`

```lua
-- 好习惯
local function helper() end  -- 模块外部不可见
local TEMP = {}              -- 可复用的临时 table
```

### 2. 显式模块返回

```lua
-- mymodule.lua
local M = {}

function M.public() end

local function private() end

return M  -- 显式、清晰
```

### 3. 记录 Table 结构

```lua
-- 清晰的约定
local player = {
  id = 1,
  name = "Hero",
  position = {x = 100, y = 200},  -- {x: number, y: number}
  health = 100,                    -- [0, 100]
}
```

### 4. 在热路径中缓存全局变量

```lua
-- 模块级缓存
local sin = math.sin
local cos = math.cos

local function compute()
  for i = 1, 1000000 do
    local x = sin(i)  -- 直接访问，无需 _ENV 查找
  end
end
```

---

## 知识检测

测试你的理解：

<details>
<summary>1. <code>type(0)</code> 返回什么？</summary>

`"number"`（Lua 5.1–5.2）或 `"integer"`（Lua 5.3+）。零是有效的数值，不是假值。
</details>

<details>
<summary>2. <code>print(nil or false or 0 or "" or "end")</code> 的输出是什么？</summary>

`0`。`or` 运算符返回第一个真值。`nil` 和 `false` 是假值，`0` 是真值。
</details>

<details>
<summary>3. 为什么 <code>local x = math.sin</code> 比直接使用 <code>math.sin</code> 更快？</summary>

`local` 变量存储在虚拟机寄存器中。`math.sin` 需要两次表查找：先查 `_ENV["math"]`，再查 `["sin"]`。
</details>

<details>
<summary>4. 以下代码有什么问题：<code>if value or default then use(value) end</code>？</summary>

如果 `value` 是 `false` 但有意义，条件仍然通过，`use(false)` 会被调用。应使用显式的 `nil` 检查：`if value ~= nil then use(value) else use(default) end`。
</details>

<details>
<summary>5. 在 Lua 5.3+ 中，<code>type(5 // 2)</code> 返回什么？</summary>

`"integer"`。`//` 运算符执行整数除法，返回整数。
</details>

---

## 版本总结

| 特性 | Lua 5.1 | Lua 5.3 | Lua 5.4 | LuaJIT |
|------|---------|---------|---------|--------|
| 数值类型 | 1（浮点） | 2（整数、浮点） | 2（整数、浮点） | 1（浮点）+ FFI |
| 整数除法 | ✗ | `//` | `//` | `//`（扩展） |
| 按位运算符 | ✗ | ✓ | ✓ | ✓（扩展） |
| `_ENV` | ✗ | ✓ | ✓ | 部分支持 |
| `setfenv`/`getfenv` | ✓ | ✗ | ✗ | ✓ |

---

## 练习

### 初级（30–60 分钟）

1. **移动平均**：编写一个函数计算数组的移动平均值。只使用 `local` 变量。

2. **Trim 函数**：实现 `trim(s)` 函数，去除首尾空白。处理边界情况：`nil`、空字符串、纯空白。

3. **全局变量检测**：创建一个脚本演示意外全局变量的 bug，然后修复它。

### 中级（1–2 小时）

4. **类型安全的默认值**：编写函数 `get_with_default(table, key, default)`，正确处理 `default` 可能为 `false` 或 `nil` 的情况。

5. **字符串构建器**：实现一个 `StringBuilder` 模块，提供 `append()`、`clear()` 和 `toString()` 方法。与简单拼接对比性能。

### 高级（2–4 小时）

6. **深度相等**：实现 `deep_equal(a, b)`，处理循环引用。记录其限制。

7. **严格模式模块**：创建一个提供严格全局变量检测功能的模块，支持可配置的白名单。

---

## 核心要点

- **8 种类型**：`nil`、`boolean`、`number`、`string`、`table`、`function`、`thread`、`userdata`
- **真值**：只有 `false` 和 `nil` 是假值；`0` 和 `""` 是真值
- **作用域**：默认使用 `local`；全局变量是 `_ENV` 查找
- **字符串**：不可变；在循环中构建字符串请使用 `table.concat`
- **Table**：引用语义；`==` 比较的是身份，而非内容
- **版本意识**：5.3+ 中数值类型和运算符有所不同

---

## 延伸阅读

- [Lua 5.4 参考手册 — 第 2 节](https://www.lua.org/manual/5.4/manual.html#2)
- [Lua 5.1 参考手册 — 第 2 节](https://www.lua.org/manual/5.1/manual.html#2)
- [Lua 程序设计（第 4 版） — 第 1–3 章](https://www.lua.org/pil/)
- [下一章：02 — 控制流](02-control-flow.md)

---

## 示例代码

本章的可运行示例位于：
- `examples/beginner/01-moving-average.lua`
- `examples/beginner/02-trim-function.lua`
- `examples/beginner/04-clamp-lerp.lua`
