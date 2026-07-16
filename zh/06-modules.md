# 06 — 模块

> **阶段**: B（元层与架构）  
> **前置知识**: 第 05 章 — 元表  
> **预计时间**: 2–3 小时阅读 + 2–4 小时练习  
> **Lua 版本**: 5.1、5.3、5.4、LuaJIT（差异已标注）

---

## 学习目标

完成本章后，你将能够：

1. **创建 Lua 模块**，使用标准的 table 返回模式
2. **理解 `require` 语义**，包括缓存、路径解析和错误处理
3. **设计清晰的模块 API**，具有显式的导出和封装的内部实现
4. **避免循环依赖**，正确处理初始化顺序
5. **使用 `package.loaded` 和 `package.path`** 实现自定义模块加载行为

---

## 模块模式

Lua 模块是一个返回 table 的文件。该 table 定义了模块的公共 API。

```lua
-- stringx.lua
local M = {}

-- 公共函数
function M.trim(s)
  return s:match("^%s*(.-)%s*$")
end

-- 公共函数
function M.split(s, sep)
  local result = {}
  local pattern = "([^" .. sep .. "]+)"
  for match in s:gmatch(pattern) do
    result[#result + 1] = match
  end
  return result
end

-- 私有函数（不导出）
local function validate(s)
  return type(s) == "string"
end

return M
```

```lua
-- 用法
local stringx = require("stringx")
print(stringx.trim("  hello  "))     -- "hello"
print(table.concat(stringx.split("a,b,c", ","), "|"))  -- "a|b|c"
```

### 为什么返回 table？

返回 table 可以创建清晰的命名空间：

```lua
-- 好：基于 table 的模块
local M = {}
function M.process() ... end
return M

-- 差：全局函数
function process() ... end  -- 污染全局命名空间
```

---

## require 语义

`require` 是加载模块的标准方式：

```lua
local mod = require("module_name")
```

### 路径解析

`require` 使用 `package.path`（用于 Lua 文件）和 `package.cpath`（用于 C 库）：

```lua
-- 默认的 package.path（因安装方式而异）
print(package.path)
-- "?;?.lua;./?/init.lua;/usr/local/share/lua/5.4/?.lua;..."

-- ? 会被替换为模块名
require("mathx")
-- 搜索：mathx, mathx.lua, ./mathx/init.lua, ...
```

### package.loaded 缓存

`require` 将结果缓存在 `package.loaded` 中：

```lua
-- 执行 require("mymod") 后，它会被缓存：
print(package.loaded["mymod"])  -- 模块 table

-- 若要强制重新加载（例如在测试中）：
package.loaded["mymod"] = nil
local mymod = require("mymod")  -- 从磁盘重新加载
```

### require 的返回值

`require` 返回存储在 `package.loaded` 中的值。如果模块返回一个 table，则该 table 被缓存：

```lua
-- mymod.lua
return {version = "1.0"}  -- 这个 table 成为 package.loaded["mymod"]
```

```lua
local m1 = require("mymod")
local m2 = require("mymod")
print(m1 == m2)  -- true（同一个 table，已缓存）
```

---

## 模块加载生命周期

```lua
-- mymod.lua（按顺序加载）

-- 1. 模块级代码在首次 require 时运行一次
print("mymod loading...")
local dep = require("dependency")

-- 2. 定义本地辅助函数
local function internal_helper() ... end

-- 3. 定义公共 API
local M = {}
function M.do_something() ... end

-- 4. 可选：运行初始化
M._initialized = true

-- 5. 返回模块 table
return M
```

---

## 封装模式

### 使用 upvalue 实现私有状态

```lua
-- counter.lua
local M = {}

-- 私有状态（外部无法访问）
local count = 0

function M.increment()
  count = count + 1
  return count
end

function M.get_count()
  return count
end

return M
```

### 通过闭包实现私有

```lua
-- auth.lua
local M = {}

local function create_token(user)
  -- 私有：无法从外部直接调用
  return user .. ":" .. tostring(os.time())
end

function M.authenticate(user, password)
  if verify_password(user, password) then
    return create_token(user)
  end
  return nil, "invalid credentials"
end

return M
```

### 通过元表实现私有

```lua
-- secret.lua
local M = {}
local data = {}  -- 私有存储

local proxy = setmetatable({}, {
  __index = data,
  __newindex = function(_, k, v)
    if k == "secret_key" then
      rawset(data, k, v)
    else
      error("Cannot set field: " .. tostring(k))
    end
  end,
  __metatable = false,  -- 阻止外部访问
})

function M.get_proxy() return proxy end
return M
```

---

## API 设计原则

### 缩小导出面

```lua
-- 好：少量、定义明确的函数
local M = {}
function M.process(config) ... end
function M.validate(config) ... end
return M

-- 差：暴露一切
local M = {}
M.process = function() ... end
M._internal_helper = function() ... end  -- 泄露内部实现
M._config = {}  -- 暴露可变内部状态
return M
```

### 无状态工具 vs 有状态服务

```lua
-- 无状态工具模块（无副作用）
local M = {}
function M.add(a, b) return a + b end
function M.mul(a, b) return a * b end
return M

-- 有状态服务模块（需要初始化）
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

### 构造器模式

```lua
-- db.lua
local DB = {}
DB.__index = DB

function DB.new(config)
  return setmetatable({
    host = config.host or "localhost",
    port = config.port or 5432,
    connected = false,
  }, DB)
end

function DB:connect()
  self.connected = true
  return self
end

function DB:close()
  self.connected = false
end

return DB
```

---

## 循环依赖

当模块 A require B，而 B 又 require A 时：

```lua
-- a.lua
local b = require("b")  -- 触发加载 b
function a_func() return b.b_func() end
return a

-- b.lua
local a = require("a")  -- a 只加载了一部分（可能为 nil 或不完整！）
function b_func() return a.a_func() end
return b
```

### 解决方案

**1. 合并为一个模块**（耦合紧密时首选）：

```lua
-- shared.lua
local M = {}
function M.a_func() ... end
function M.b_func() ... end
return M
```

**2. 延迟 require**（推迟加载）：

```lua
-- a.lua
local a = {}
function a_func()
  local b = require("b")  -- 按需加载
  return b.b_func()
end
return a
```

**3. 提取共享代码**到第三个模块：

```lua
-- common.lua（无依赖）
local M = {}
function M.shared_func() ... end
return M

-- a.lua
local common = require("common")
return { a_func = common.shared_func }

-- b.lua
local common = require("common")
return { b_func = common.shared_func }
```

---

## 预加载与 package.loaded

### 预加载模块

```lua
-- 无需文件即可注入模块
package.loaded["mypreload"] = {version = "1.0", hello = function() print("hi") end}
local m = require("mypreload")
m.hello()  -- "hi"
```

### 自定义 package.loaders（5.1）/ package.searchers（5.2+）

```lua
-- 自定义加载器，动态生成模块
table.insert(package.searchers, function(name)
  if name == "generated" then
    return function()
      return {generated = true, timestamp = os.time()}
    end
  end
end)

local m = require("generated")
print(m.timestamp)  -- 当前时间戳
```

---

## 常见陷阱

### 1. require 期间的副作用

```lua
-- 差：模块在 require 时执行操作
local M = {}
print("Processing...")  -- 每次 require 都运行吗？不——只在第一次运行。
-- 但：这在加载时运行，可能出乎意料

-- 好：将加载与初始化分离
local M = {}
function M.init()
  print("Processing...")
end
return M
```

### 2. 隐式全局变量

```lua
-- BUG：意外创建了全局变量
local M = {}
function M.process()
  result = 42  -- 全局变量！应该是 local
  return result
end
return M
```

### 3. 直接修改 package.loaded

```lua
-- 差：覆盖其他模块的缓存
package.loaded["other_module"] = nil  -- 可能导致其他代码崩溃

-- 更好：只将你自己的模块设为 nil 以重新加载
package.loaded["my_module"] = nil
```

### 4. require 返回多个值

`require` 只返回模块的第一个值：

```lua
-- mymod.lua
return "value1", "value2"  -- 只有 "value1" 被缓存

local v1, v2 = require("mymod")
-- v1 = "value1", v2 = nil！
```

---

## 最佳实践

### 1. 返回显式的模块 table

```lua
-- 好
local M = {}
M.process = function() ... end
return M

-- 对简单模块也可以
return {
  process = function() ... end,
}
```

### 2. 文档化模块生命周期

```lua
--- 模块：数据库连接管理器
-- 用法：
--   local db = require("db")
--   db.connect("localhost", 5432)
--   local result = db.query("SELECT ...")
--   db.disconnect()
--
-- 状态：在 query() 之前需要调用 connect()
-- 清理：调用 disconnect() 或使用 __gc
```

### 3. 保持依赖关系无环

```
app.lua → db.lua → config.lua
                  → logger.lua
      → handler.lua → db.lua（相同依赖，没问题）
                    → auth.lua → config.lua（没问题，共享叶子节点）
```

避免：`a.lua → b.lua → a.lua`（循环）

### 4. 一个模块，一个职责

```lua
-- 好：职责单一的模块
local config = require("config")     -- 配置加载
local db = require("db")            -- 数据库操作
local logger = require("logger")    -- 日志

-- 差：上帝模块
local everything = require("everything")
everything.config.load()
everything.db.query()
everything.logger.info()
```

### 5. 使用 __name 标识模块

```lua
-- 有助于调试和错误消息
local M = {}
setmetatable(M, {__name = "mymodule"})
```

---

## 版本说明

### Lua 5.1

- 使用 `setfenv`/`getfenv` 进行环境操作
- `package.loaders`（不是 `package.searchers`）
- 没有 `table.pack`/`table.unpack`
- `module()` 函数可用（已弃用——不要使用）

```lua
-- Lua 5.1（已弃用的模式）
module("mymod", package.seeall)  -- 不要使用这个
-- 创建全局 table 并设置环境
```

### Lua 5.2/5.3

- `package.searchers` 替代了 `package.loaders`
- `require` 只返回第一个值
- `table.pack`/`table.unpack` 可用
- `module()` 已移除

### Lua 5.4

- 与 5.3 相比没有显著的模块系统变化
- 失败的 require 有更好的错误消息

### LuaJIT

- FFI 模块通过 `require` 和 `ffi.load` 加载
- 模块加载中有一些对 JIT 不友好的模式（避免在热路径中使用）
- `package.loadlib` 可用于自定义 C 库加载

---

## 知识检查

<details>
<summary>1. <code>require</code> 在首次调用后返回什么？</summary>

从 `package.loaded[modname]` 返回缓存的值。如果模块返回了一个 table，则返回该 table。后续的 `require` 调用不会重新执行模块代码。
</details>

<details>
<summary>2. 如何强制重新加载模块？</summary>

在再次调用 `require(modname)` 之前，设置 `package.loaded[modname] = nil`。这会清除缓存并强制重新执行。
</details>

<details>
<summary>3. 为什么应该避免使用 <code>module()</code>？</summary>

它已弃用（在 5.2+ 中已移除），会污染全局命名空间，并且使用 `setfenv` 会使调试更加困难。请改用 `local M = {}; return M` 模式。
</details>

<details>
<summary>4. 循环依赖如何导致 bug？</summary>

当 A require B 而 B 又 require A 时，A 在 B 尝试使用它时可能只加载了一部分（或为 nil）。在循环 require 之后定义的函数可能还不存在。
</details>

<details>
<summary>5. <code>package.path</code> 和 <code>package.cpath</code> 有什么区别？</summary>

`package.path` 用于 Lua 源文件（`.lua`）。`package.cpath` 用于编译后的 C 库（`.so`、`.dll`）。`require` 会根据模块名检查两者。
</details>

---

## 关键要点

- **模块模式**：`local M = {}; ...; return M`
- **`require` 缓存**在 `package.loaded` 中——模块只加载一次
- **路径解析**使用 `package.path`，通过 `?` 进行替换
- **封装内部实现**通过局部变量、闭包或元表
- **避免循环依赖**——合并、延迟加载或提取共享代码
- **一个模块，一个职责**——保持 API 精简
- **永远不要使用 `module()`**——它已弃用且有害

---

## 练习

### 初级（30–60 分钟）

1. **字符串工具**：创建一个 `stringx` 模块，包含 `trim`、`split`、`starts_with` 和 `ends_with`。包含测试。

2. **配置加载器**：构建一个 `config` 模块，从 Lua 文件加载设置，支持回退默认值和环境变量覆盖。

3. **模块重载器**：编写一个 `reload(name)` 函数，清除 `package.loaded` 中的模块并重新 require。

### 中级（1–2 小时）

4. **三模块拆分**：将一个单体脚本拆分为三个模块：`config.lua`、`db.lua`、`app.lua`。确保依赖方向清晰。

5. **延迟加载器**：实现一个模块代理，在对模块的首次函数调用之前延迟 `require`。

6. **有状态模块**：构建一个 `cache` 模块，提供 `get`、`set`、`invalidate` 和 `clear` 操作。使用私有 upvalue 进行存储。

### 高级（2–4 小时）

7. **插件系统**：创建一个 `plugins` 模块，自动发现并从目录加载插件模块。优雅地处理错误。

8. **热重载**：实现一个开发模式的模块加载器，检测文件更改并在不重启应用程序的情况下重新加载模块。

---

## 示例代码

本章的可运行示例：
- `examples/intermediate/04-stateful-module.lua` — 带生命周期的有状态模块
- `examples/intermediate/02-event-bus.lua` — 基于模块的事件系统

---

## 扩展阅读

- [Lua 5.4 参考手册 — 第 6.3 节](https://www.lua.org/manual/5.4/manual.html#6.3)
- [Programming in Lua（第 4 版）— 第 15 章](https://www.lua.org/pil/)
- [下一章: 07 — 错误处理](07-error-handling.md)
