# 第15章：高级元编程

> **阶段**：高级  
> **前置章节**：第05章（元表）、第06章（模块）  
> **时间**：8–12小时  
> **Lua 版本**：5.1、5.3、5.4、5.5、LuaJIT

---

## 学习目标

学完本章后，你将能够：

1. 使用 `load()` 和 `loadstring()` 进行动态代码生成
2. 使用 Lua 的元编程设施实现自定义 DSL
3. 在运行时生成代码以优化性能
4. 使用 table 和函数构建宏系统
5. 理解元编程在生产环境中的权衡

---

## 动态代码加载

### `load` 函数

`load` 将字符串编译为函数而不执行它：

```lua
-- 动态编译并执行
local code = 'return 1 + 2'
-- 字符串版本的 load(string) 从 5.2 起才有；在 5.1 上请用 loadstring() 编译字符串。
local fn, err
if loadstring then
  fn, err = loadstring(code)
else
  fn, err = load(code)
end
if fn then
  local result = fn()
  print(result)  -- 3
else
  print("编译错误: " .. err)
end
```

> **Lua 5.2 说明**：load() 从 Lua 5.2 起才支持编译字符串；在 Lua 5.1 上请用 loadstring()。

### 环境控制

`load` 可以为加载的代码设置环境：

```lua
-- 受限环境
local restricted = {print = print, math = math}
-- 四参数的 load(chunk, chunkname, mode, env) 从 5.2 起才有；在
-- 5.1（以及作为 5.1 衍生物的 LuaJIT）上，等价写法是
-- loadstring() 配合 setfenv()。
local fn
if loadstring then
  fn = loadstring("return math.sqrt(16)", "chunk")
  if fn then setfenv(fn, restricted) end
else
  fn = load("return math.sqrt(16)", "chunk", "t", restricted)
end
print(fn())  -- 4.0

-- 代码无法访问受限环境之外的全局变量
local fn2
if loadstring then
  fn2 = loadstring("return os.execute('rm -rf /')", "chunk")
  if fn2 then setfenv(fn2, restricted) end
else
  fn2 = load("return os.execute('rm -rf /')", "chunk", "t", restricted)
end
-- 调用 fn2 会失败（os 不在 restricted 中）
```

> **Lua 5.2 说明**：四参数的 load() 是 Lua 5.2 引入的；在 Lua 5.1 上请用 loadstring() 配合 setfenv()。

### `loadstring`（Lua 5.1）

在 Lua 5.1 中，使用 `loadstring` 代替 `load`：

```lua
-- Lua 5.1
local fn = loadstring("return 42")
print(fn())  -- 42

-- Lua 5.2+
local fn = load and load("return 42") or loadstring("return 42")
```

---

## 代码生成模式

### 基于模板的代码生成

从模板生成 Lua 代码：

```lua
local function generate_function(name, params, body)
  local param_str = table.concat(params, ", ")
  local code = string.format(
    "local function %s(%s)\n%s\nend\nreturn %s",
    name, param_str, body, name
  )
  -- 字符串版本的 load(string) 从 5.2 起才有；在 5.1 上请用 loadstring() 编译字符串。
  if loadstring then
    return loadstring(code)()
  end
  return load(code)()
end

-- 运行时生成函数
local double = generate_function("double", {"x"}, "return x * 2")
print(double(5))  -- 10
```

### 基于 Table 的代码生成

使用 table 驱动代码生成：

```lua
local function generate_accessors(fields)
  local code = "local M = {}\n"
  for _, field in ipairs(fields) do
    code = code .. string.format(
      "function M.get_%s(self) return self._%s end\n",
      field, field
    )
    code = code .. string.format(
      "function M.set_%s(self, v) self._%s = v end\n",
      field, field
    )
  end
  code = code .. "return M"
  -- 字符串版本的 load(string) 从 5.2 起才有；在 5.1 上请用 loadstring() 编译字符串。
  if loadstring then
    return loadstring(code)()
  end
  return load(code)()
end

local person_accessors = generate_accessors({"name", "age", "email"})
local p = {_name = "Lua", _age = 30, _email = "lua@example.com"}
print(person_accessors.get_name(p))  -- "Lua"
```

---

## DSL 构建

### 内部 DSL

Lua 灵活的语法支持可读的内部 DSL：

```lua
-- 类 SQL 查询 DSL
local function query(table_name)
  return setmetatable({from = table_name}, {
    __call = function(self, conditions)
      local where = ""
      if conditions then
        local parts = {}
        for k, v in pairs(conditions) do
          parts[#parts + 1] = string.format("%s = '%s'", k, v)
        end
        where = " WHERE " .. table.concat(parts, " AND ")
      end
      return string.format("SELECT * FROM %s%s", self.from, where)
    end
  })
end

print(query("users")({status = "active"}))
-- "SELECT * FROM users WHERE status = 'active'"
```

### 构建器模式 DSL

先用 `create_builder()` 拿到一个构建器，再用 `:set()` 逐项写入——它返回自身，因此可以链式调用——最后用 `:build()` 取出结果表。

```lua
local function create_builder()
  local builder = {}
  local data = {}

  function builder:set(key, value)
    data[key] = value
    return builder  -- 支持链式调用
  end

  function builder:build()
    local result = {}
    for k, v in pairs(data) do
      result[k] = v
    end
    return result
  end

  return builder
end

local config = create_builder()
  :set("host", "localhost")
  :set("port", 8080)
  :set("debug", true)
  :build()

print(config.host, config.port)
```

---

## 运行时代码优化

### 预计算

在加载时而非运行时计算值：

```lua
-- 预计算查找表
local sin_table = {}
for i = 0, 360 do
  sin_table[i] = math.sin(math.rad(i))
end

-- 运行时快速查找
local function fast_sin(degrees)
  return sin_table[degrees % 360]
end
```

### JIT 友好模式

编写 LuaJIT 可以优化的代码：

```lua
-- 差：多态（同一 trace 中不同类型）
local function process(x)
  if type(x) == "number" then
    return x * 2
  else
    return tostring(x)
  end
end

-- 好：单态（相同类型）
local function process_number(x)
  return x * 2
end

local function process_string(x)
  return tostring(x)
end
```

---

## 高级模式

### 基于属性的访问

使用 `__index` 和 `__newindex` 实现基于属性的访问：

```lua
local function create_attrs(defaults)
  local attrs = {}
  for k, v in pairs(defaults) do
    attrs[k] = v
  end
  
  return setmetatable({}, {
    __index = function(_, k)
      return attrs[k]
    end,
    __newindex = function(_, k, v)
      if attrs[k] ~= nil then
        error("Attribute '" .. k .. "' is read-only")
      end
      rawset(_, k, v)
    end,
  })
end

local obj = create_attrs({name = "test", value = 42})
print(obj.name)  -- "test"
-- obj.name = "new"  -- 错误：只读
```

### 构建器模式与链式调用

```lua
local function builder()
  local data = {}
  
  return setmetatable(data, {
    __call = function(_, key, value)
      data[key] = value
      return data  -- 支持链式调用
    end,
  })
end

-- 链式调用特意写成一行：拆成多行后 `f()\n(g)()` 会产生歧义，
-- Lua 5.1 无法解析这种写法。
local config = builder()("host", "localhost")("port", 8080)("debug", true)

print(config.host, config.port, config.debug)
```

### 算术运算的元方法

```lua
local Vector = {}
Vector.__index = Vector

function Vector.new(x, y)
  return setmetatable({x = x or 0, y = y or 0}, Vector)
end

function Vector.__add(a, b)
  return Vector.new(a.x + b.x, a.y + b.y)
end

function Vector.__mul(v, scalar)
  return Vector.new(v.x * scalar, v.y * scalar)
end

function Vector:__tostring()
  return string.format("Vector(%g, %g)", self.x, self.y)
end

local v1 = Vector.new(1, 2)
local v2 = Vector.new(3, 4)
print(v1 + v2)  -- Vector(4, 6)
print(v1 * 3)   -- Vector(3, 6)
```

---

## 常见陷阱

### 1. `load` 的安全风险

```lua
-- 危险：不要加载不受信任的代码
local user_input = io.read()
-- 字符串版本的 load(string) 从 5.2 起才有；在 5.1 上请用 loadstring() 编译字符串。
local fn
if loadstring then
  fn = loadstring(user_input)  -- 可能执行任何操作！
else
  fn = load(user_input)  -- 可能执行任何操作！
end
fn()

-- 安全：使用受限环境
local safe_env = {print = print, math = math}
-- 四参数的 load(chunk, chunkname, mode, env) 从 5.2 起才有；在
-- 5.1（以及作为 5.1 衍生物的 LuaJIT）上，等价写法是
-- loadstring() 配合 setfenv()。
local fn
if loadstring then
  fn = loadstring(user_input, "user")
  if fn then setfenv(fn, safe_env) end
else
  fn = load(user_input, "user", "t", safe_env)
end
```

> **Lua 5.2 说明**：四参数的 load() 是 Lua 5.2 引入的；在 Lua 5.1 上请用 loadstring() 配合 setfenv()。

### 2. 调试信息丢失

```lua
-- 运行时生成的代码缺少调试信息
-- 字符串版本的 load(string) 从 5.2 起才有；在 5.1 上请用 loadstring() 编译字符串。
local fn
if loadstring then
  fn = loadstring("return 1/0")
else
  fn = load("return 1/0")
end
fn()  -- 错误消息缺少上下文

-- 更好：包含调试信息
local fn
if loadstring then
  fn = loadstring("return 1/0", "=generated")
else
  fn = load("return 1/0", "=generated", "t")
end
```

### 3. 性能开销

```lua
-- 元编程增加运行时开销
local t = {}
setmetatable(t, {
  __index = function(_, k)
    return compute_value(k)  -- 每次访问都会调用
  end
})
```

---

## 案例研究：会自己长出来的校验器

一个配置服务必须在每次请求时校验传入记录是否符合 schema。schema 存放在一张
table 里，因此最直接的实现是每次调用都遍历这张表。本案例研究的是一个更窄的
问题：如果 schema 是静态的，能否在加载时把它变成代码，而不是永远解释执行它——
这个改造真的划算吗？

### 参考实现

```lua
local function validate_generic(record, spec)
  for i = 1, #spec do
    local rule = spec[i]
    local value = record[rule.field]
    if value == nil then
      if rule.required then return false, rule.field .. " is required" end
    elseif type(value) ~= rule.type then
      return false, rule.field .. " must be a " .. rule.type
    end
  end
  return true
end
```

每次调用都要从这张表重新推导行为：一个循环、每条规则两个分支，以及靠拼接构造的
错误消息。

### 元编程改变了什么

用 schema 拼出源码字符串，只 `load` 一次，然后保留返回的函数。生成物就是一个
普通的 Lua 函数：

```lua
-- generated validator
return function(record)
  local v
  v = record["id"]
  if v == nil then return false, "id is required" end
  if v ~= nil and type(v) ~= "number" then return false, "id must be a number" end
  v = record["name"]
  if v == nil then return false, "name is required" end
  if v ~= nil and type(v) ~= "string" then return false, "name must be a string" end
  v = record["score"]
  if v ~= nil and type(v) ~= "number" then return false, "score must be a number" end
  v = record["tags"]
  if v ~= nil and type(v) ~= "table" then return false, "tags must be a table" end
  return true
end
```

三处结构性差异，每一处都在省掉参考实现每次调用都要重做的工作：

1. **没有规则循环。** 循环在生成时就被展开了。
2. **每个字段只查一次 table**，不必反复读取 `rule.field` 和 `rule.type`。
3. **消息是预渲染好的字面量**，校验期间不发生任何拼接。

### 让结论成立的那道守卫

生成的代码更快但错了，就毫无价值。因此该示例会用包含八条记录的语料库交叉比对
两种实现（其中包含畸形记录：`id` 是字符串、`name` 是数字、`tags` 是字符串），
一旦发现不一致就拒绝输出任何计时数据：

```
Correctness: 8/8 records agree with the reference validator
             0 mismatches
```

这道守卫成本很低，且永久存在，在每次测量前都会运行。要留着它：正是它防止了这个
优化在日后悄悄破坏正确性。

### 实测结果

自己跑一遍：

```bash
lua examples/advanced/23-schema-codegen.lua
```

在本机实测，每条路径各 1,200,000 次校验调用：

| 运行时 | 解释器 | 比值（参考实现 ÷ 生成实现） |
|--------|--------|------------------------------|
| Lua 5.4 | PUC | 1.62x – 1.77x |
| Lua 5.1 | PUC | 1.53x |
| LuaJIT 2.1.1791988261 | LuaJIT | 3.10x |

从这些数字里应当读出两点：

- **绝对耗时取决于机器；信比值。** 示例会把两者都打印出来，方便你和自己的硬件
  对比，但真正能跨机器迁移的是比值。
- **收益大小取决于 VM。** 这里 LuaJIT 的收益大约是 PUC Lua 的两倍，因为它更容易
  把生成的函数追踪（trace）成紧凑的机器码，而难以用同样方式优化那个驱动 table 的
  循环。把某一个运行时的数字套用到另一个上，正是本案例要避免的错误。

### 什么时候不该用

代码生成是一笔开销，不是默认选项。以下情况请优先使用参考实现：

- **schema 每次请求都会变。** 编译是按 schema 一次完成的；如果你一直在重编译，
  只是把开销挪了个位置。
- **记录很大而校验不在热路径上。** 在一个 50µs 的操作上提升 1.6 倍，不值得换一个
  没人读得懂的生成文件。
- **可读性比循环更重要。** 调试时必须能把生成源码打印出来看懂，那是长期维护成本，
  而不是一次性设置成本。
- **你写不出那道守卫。** 如果两种实现无法用语料库比对，你就无法区分一次正确的
  优化和一次错误的优化。

```bash
# 完整运行：先打印生成源码，再输出计时结果
lua examples/advanced/23-schema-codegen.lua
```

---

## 最佳实践

1. **优先使用静态代码**，当性能至关重要时
2. **将元编程用于 DSL** 和配置，而非核心逻辑
3. **始终对 `load` 进行沙箱处理**，处理不受信任的代码时
4. **记录生成的代码**以便维护
5. **先分析再优化**，使用元编程

---

## 核心要点

- `load()` 支持动态代码生成，但需要谨慎的安全处理
- 基于 Table 的模式在加载时生成代码以提高运行时效率
- 内部 DSL 利用 Lua 灵活的语法实现可读的 API
- 元编程功能强大，但会增加复杂性和调试难度
- 始终在功能和可维护性之间权衡

---

## 练习

### 初级（30–60 分钟）

1. **动态函数生成器**：编写一个函数 `make_multiplier(n)`，使用 `load()` 生成并返回一个将参数乘以 `n` 的函数。

2. **安全代码加载器**：创建一个 `safe_load(code)` 函数，在受限环境中加载代码，仅允许 `print`、`math` 和 `string` 库。

### 中级（1–2 小时）

3. **简单 DSL**：使用 Lua 表和元方法构建一个小型数据库查询 DSL。示例：`Query("users"):where("age > 18"):order_by("name")`。

4. **代码生成器**：编写一个函数，从模板生成多个相似函数。例如，从字段名列表生成 `get_name()`、`get_age()`、`get_email()`。

### 高级（2–4 小时）

5. **宏系统**：实现一个简单的宏系统，其中 `@macro(name, args)` 在加载时被展开。支持至少一个内置宏。

6. **性能基准测试**：比较静态代码与元编程生成代码在计算密集型任务上的性能。记录开销。

---

## 示例代码

本章可运行示例：
- `examples/advanced/23-schema-codegen.lua` — schema 生成校验器代码

---

## 延伸阅读

- [Lua 5.5 参考手册 — 第6节](https://www.lua.org/manual/5.5/manual.html#6)
- [Lua 程序设计 — 第8章：与 C 接口](https://www.lua.org/pil/)

---

[下一章：16 — Lua 生态系统](16-lua-ecosystem.md)
