# 第15章：高级元编程

> **阶段**：高级  
> **前置章节**：第05章（元表）、第06章（模块）  
> **时间**：8–12小时  
> **Lua 版本**：5.1、5.3、5.4、LuaJIT

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
local fn, err = load(code)
if fn then
  local result = fn()
  print(result)  -- 3
else
  print("编译错误: " .. err)
end
```

### 环境控制

`load` 可以为加载的代码设置环境：

```lua
-- 受限环境
local restricted = {print = print, math = math}
local fn = load("return math.sqrt(16)", "chunk", "t", restricted)
print(fn())  -- 4.0

-- 代码无法访问受限环境之外的全局变量
local fn2 = load("return os.execute('rm -rf /')", "chunk", "t", restricted)
-- 调用 fn2 会失败（os 不在 restricted 中）
```

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
    "local function %s(%s)\n%s\nend",
    name, param_str, body
  )
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

## 常见陷阱

### 1. `load` 的安全风险

```lua
-- 危险：不要加载不受信任的代码
local user_input = io.read()
local fn = load(user_input)  -- 可能执行任何操作！

-- 安全：使用受限环境
local safe_env = {print = print, math = math}
local fn = load(user_code, "user", "t", safe_env)
```

### 2. 调试信息丢失

```lua
-- 运行时生成的代码缺少调试信息
local fn = load("return 1/0")  -- 错误消息没有行号
fn()  -- 错误消息缺少上下文

-- 更好：包含调试信息
local fn = load("return 1/0", "=generated", "t")
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

## 延伸阅读

- [Lua 5.4 参考手册 — 第6节](https://www.lua.org/manual/5.4/manual.html#6)
- [Lua 程序设计 — 第8章：与 C 接口](https://www.lua.org/pil/)

---

[下一章：16 — Lua 生态系统](16-lua-ecosystem.md)
