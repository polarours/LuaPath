# 第18章：Lua 中的安全性

> **阶段**：高级  
> **前置章节**：第06章（模块）、第17章（嵌入模式）  
> **时间**：8–12小时  
> **Lua 版本**：5.1、5.3、5.4、5.5、LuaJIT

---

## 学习目标

学完本章后，你将能够：

1. 识别 Lua 应用程序中的安全风险
2. 实现安全的编码实践
3. 设计安全的插件架构
4. 安全地处理不受信任的输入
5. 在生产环境中应用安全最佳实践

---

## 常见安全风险

### 代码注入

```lua
-- 危险：执行用户输入
local user_input = io.read()
-- 字符串版本的 load(string) 从 5.2 起才有；在 5.1 上请用 loadstring() 编译字符串。
local fn
if loadstring then
  fn = loadstring(user_input)
else
  fn = load(user_input)
end
fn()  -- 可能执行任何操作！

-- 安全：验证并限制
local function safe_execute(code)
  -- 验证代码不包含危险模式
  if code:match("os%.") or code:match("io%.") then
    return nil, "检测到危险代码"
  end
  
  local env = {print = print, math = math}
  -- 四参数的 load(chunk, chunkname, mode, env) 从 5.2 起才有；在
  -- 5.1（以及作为 5.1 衍生物的 LuaJIT）上，等价写法是
  -- loadstring() 配合 setfenv()。
  local fn
  if loadstring then
    fn = loadstring(code, "user")
    if fn then setfenv(fn, env) end
  else
    fn = load(code, "user", "t", env)
  end
  if not fn then
    return nil, "无效代码"
  end
  
  return fn()
end
```

> **Lua 5.2 说明**：四参数的 load() 是 Lua 5.2 引入的；在 Lua 5.1 上请用 loadstring() 配合 setfenv()。

### 路径遍历

```lua
-- 危险：没有路径验证
local function read_file(filename)
  local f = io.open(filename, "r")
  if f then
    local content = f:read("*a")
    f:close()
    return content
  end
end

-- 安全：验证路径
local function safe_read_file(filename, allowed_dirs)
  -- 检查路径遍历
  if filename:match("%.%.") or filename:match("^/") then
    return nil, "无效路径"
  end
  
  -- 检查路径是否在允许的目录中
  local allowed = false
  for _, dir in ipairs(allowed_dirs) do
    if filename:sub(1, #dir) == dir then
      allowed = true
      break
    end
  end
  
  if not allowed then
    return nil, "访问被拒绝"
  end
  
  local f = io.open(filename, "r")
  if f then
    local content = f:read("*a")
    f:close()
    return content
  end
  return nil, "文件未找到"
end
```

### 整数溢出

```lua
-- 危险：完全没有上限
-- 在 Lua 5.3 及之后，这次乘法是整数运算，到 2^63 时会静默回绕；
-- 在 Lua 5.1 上则是 double，会静默丢失精度。两种情况下哈希都是垃脆的。
local function calculate_hash(data)
  local hash = 0
  for i = 1, #data do
    hash = hash * 31 + data:byte(i)
  end
  return hash
end

-- 安全：把值限在已知的范围内
-- 除数 2^32 是浮点数，因此取模的结果也是浮点数，
-- 乘法不会再碰到 int64 的上限。
local function safe_hash(data)
  local hash = 0
  for i = 1, #data do
    hash = (hash * 31 + data:byte(i)) % 2^32
  end
  return hash
end
```

---

## 安全编码实践

### 输入验证

```lua
-- validator.lua
local Validator = {}
Validator.__index = Validator

function Validator.new()
  return setmetatable({rules = {}}, Validator)
end

function Validator:add_rule(name, fn)
  self.rules[name] = fn
  return self
end

function Validator:validate(data)
  local errors = {}
  for name, rule in pairs(self.rules) do
    local ok, err = pcall(rule, data)
    if not ok then
      errors[#errors + 1] = {rule = name, error = err}
    end
  end
  return #errors == 0, errors
end

-- 使用
local validator = Validator.new()
  :add_rule("type", function(data)
    assert(type(data) == "table", "数据必须是 table")
  end)
  :add_rule("required_fields", function(data)
    assert(data.name, "名称是必需的")
    assert(data.email, "邮箱是必需的")
  end)

local ok, errors = validator:validate({name = "Lua"})
-- ok = false, errors = [{rule = "required_fields", error = "邮箱是必需的"}]
```

### 参数清理

```lua
-- sanitizer.lua
local function sanitize_string(input)
  if type(input) ~= "string" then
    return nil, "输入必须是字符串"
  end
  
  -- 移除空字节
  input = input:gsub("%z", "")
  
  -- 限制长度
  if #input > 10000 then
    input = input:sub(1, 10000)
  end
  
  -- 转义特殊字符用于显示
  input = input:gsub("&", "&amp;")
  input = input:gsub("<", "&lt;")
  input = input:gsub(">", "&gt;")
  
  return input
end

local function sanitize_number(input)
  local num = tonumber(input)
  if not num then
    return nil, "无效数字"
  end
  
  -- 检查合理范围
  if num > 2^52 or num < -(2^52) then
    return nil, "数字超出安全范围"
  end
  
  return num
end
```

### 安全随机数生成

```lua
-- secure_random.lua
local function secure_random(min, max)
  -- 使用操作系统提供的熵
  local handle = io.popen("od -An -tu4 -N4 /dev/urandom")
  if handle then
    local random_str = handle:read("*a")
    handle:close()
    
    local random_num = tonumber(random_str)
    if random_num then
      return min + (random_num % (max - min + 1))
    end
  end
  
  -- 回退到 math.random（安全性较低）
  math.randomseed(os.time() + os.clock() * 1000)
  return math.random(min, max)
end
```

---

## 安全的插件架构

### 插件沙箱

```lua
-- secure_plugin_loader.lua
local function load_plugin_sandboxed(plugin_code, api)
  -- 创建受限环境
  local env = {
    -- 只提供安全的 API
    print = api.print or print,
    error = error,
    assert = assert,
    type = type,
    tostring = tostring,
    tonumber = tonumber,
    pairs = pairs,
    ipairs = ipairs,
    pcall = pcall,
    xpcall = xpcall,
  }
  
  -- 添加插件特定的 API
  if api then
    for k, v in pairs(api) do
      env[k] = v
    end
  end
  
  -- 移除危险的全局变量
  env.os = nil
  env.io = nil
  env.debug = nil
  env.load = nil
  env.loadfile = nil
  env.dofile = nil
  env.rawset = nil
  env.rawget = nil
  env.rawequal = nil
  env.setmetatable = nil
  env.getmetatable = nil
  
  -- 编译插件代码
  -- 四参数的 load(chunk, chunkname, mode, env) 从 5.2 起才有；在
  -- 5.1（以及作为 5.1 衍生物的 LuaJIT）上，等价写法是
  -- loadstring() 配合 setfenv()。
  local fn, err
  if loadstring then
    fn, err = loadstring(plugin_code, "plugin")
    if fn then setfenv(fn, env) end
  else
    fn, err = load(plugin_code, "plugin", "t", env)
  end
  if not fn then
    return nil, "插件编译错误: " .. err
  end
  
  -- 设置环境
  --
  -- 回退目标只有安全的标准库。如果回退到 _G 就会破坏沙箱：查找 `os`
  -- 时 env 中没有命中，接着就会通过 __index 解析到 _G.os，于是上面
  -- 移除的那些全局变量又能访问到了。
  setmetatable(env, {__index = {string = string, math = math, table = table}})
  
  -- 执行插件
  local ok, result = pcall(fn)
  if not ok then
    return nil, "插件运行时错误: " .. result
  end
  
  return result
end
```

> **Lua 5.2 说明**：四参数的 load() 是 Lua 5.2 引入的；在 Lua 5.1 上请用 loadstring() 配合 setfenv()。

### 权限系统

```lua
-- permission_system.lua
local PermissionSystem = {}
PermissionSystem.__index = PermissionSystem

function PermissionSystem.new()
  return setmetatable({
    permissions = {},
    grants = {},
  }, PermissionSystem)
end

function PermissionSystem:grant(plugin, permission)
  if not self.grants[plugin] then
    self.grants[plugin] = {}
  end
  self.grants[plugin][permission] = true
end

function PermissionSystem:check(plugin, permission)
  return self.grants[plugin] and self.grants[plugin][permission]
end

function PermissionSystem:create_proxy(plugin, allowed_permissions)
  local proxy = {}
  local mt = {}
  
  mt.__index = function(_, key)
    if not self:check(plugin, key) then
      error("权限被拒绝: " .. key)
    end
    return _G[key]
  end
  
  mt.__newindex = function(_, key, value)
    if not self:check(plugin, key) then
      error("权限被拒绝: " .. key)
    end
    rawset(_, key, value)
  end
  
  return setmetatable(proxy, mt)
end
```

---

## 常见陷阱

### 1. 信任用户输入

```lua
-- 差：没有验证
local name = input.name
execute_query("SELECT * FROM users WHERE name = '" .. name .. "'")

-- 安全：参数化查询
local function safe_query(name)
  -- 验证输入
  if type(name) ~= "string" then
    return nil, "无效名称"
  end
  
  -- 使用参数化查询
  return db.query("SELECT * FROM users WHERE name = ?", name)
end
```

### 2. 暴露内部状态

```lua
-- 差：返回内部 table
local function get_config()
  return config  -- 暴露整个配置！
end

-- 安全：返回副本或特定值
local function get_config()
  return {
    host = config.host,
    port = config.port,
    -- 不要暴露密码、密钥等
  }
end
```

### 3. 弱错误消息

```lua
-- 差：暴露内部细节
error("数据库连接失败，位于 module.lua 第42行")

-- 安全：通用错误并记录日志
log.error("数据库连接失败", {module = "db", line = 42})
error("服务不可用")
```

---

## 实战案例：审计插件边界

某个插件加载器接受用户提交的 Lua 源码，并在进程内运行它。它的"沙箱"就是一张
允许使用的全局变量表。本案例不问这个思路在理论上是否成立，而是问：审查者会
看的那些控制措施，在真正有恶意输入打过来时是否真的生效。
`examples/advanced/27-security-audit.lua` 向边界发起五次真实尝试，并打印结果。

### 五项控制

1. **拒绝预编译字节码**，不让加载器看到它——插件协议接受的是源码，字节码里
   可以藏着另一个程序。
2. **隔离环境**：`os`、`io`、`debug`、`require` 都不存在，且环境只读，插件无法
   自行安装全局量。
3. **在解析前限制载荷大小**，这样攻击者没法仅靠让加载器解码输入就迫使它做
   无界的工作。
4. **在分配前限制重复次数**，一小段源码就不能膨胀成一个巨大的字符串。
5. **净化错误信息**，栈回溯不能把服务器路径或用户数据带回给调用方。

### 审计实际跑了什么

可移植的字节码守卫检查首字节，因为 `load(..., "t")` 只在 Lua 5.2 及以上才拒绝
二进制块：

```lua
local HAS_LOADSTRING = loadstring ~= nil

local function is_bytecode(src)
  return type(src) == "string" and src:byte(1) == 27
end

local function guarded_load(src, name)
  if is_bytecode(src) then
    return nil, "bytecode rejected: precompiled chunks are not accepted"
  end
  if HAS_LOADSTRING then return loadstring(src, name) end
  return load(src, name, "t", nil)
end
```

环境是一张带写入守卫的普通表；危险全局量压根没放进去：

```lua
local guard = {
  __newindex = function(_, key)
    error("sandbox is read-only: " .. tostring(key), 2)
  end,
}
local env = setmetatable({ print = print }, { __index = guard })
-- env.os、env.io、env.debug、env.require 全为 nil
```

错误处理器返回通用消息，原始消息只留给服务器日志：

```lua
local function handler(err)
  -- 在服务端记录 err；绝不返回给不可信的调用方
  return "internal error: an unexpected condition occurred"
end

local ok, visible = xpcall(function()
  error("/home/user/private/config.lua: nil value (field 'secret_key')")
end, handler)
```

### 实测结果

```
string.dump(...) 的首字节 = 27 (ESC)
5.4 上 mode="t" 拒绝：attempt to load a binary chunk (mode is 't')
字节守卫：字节码被拒，普通源码仍可接受
沙箱：os / io / debug / require 的 type() 全部为 "nil"
      向新全局量写入被拒；沙箱内 _G 为 nil
载荷限制：低于上限的源码可加载，超限的在解析前被拒
资源限制：重复炸弹在未分配内存前被拒
错误净化：xpcall 返回通用消息；
          裸 pcall 泄露了 "/home/user/private/config.lua"
检查数：Lua 5.4、Lua 5.1、LuaJIT 均为 20/20
```

### 这意味着什么

- mode 参数只有在支持它的运行时上才是守卫。Lua 5.1 会忽略多余的参数，二进制块
  照样加载，所以字节检查必须承担跨全部受支持版本的保证。
- 隐藏全局量不等于阻止写入。没有 `__newindex` 的沙箱允许插件在自己的环境里
  造出一个 `os`；审计既要查读，也要查写。
- 限制要放在昂贵操作之前。载荷守卫在解析前拒绝，重复守卫在分配前拒绝，这正是
  它们成为硬限制而不是礼貌建议的原因。
- 错误信息也是输出。审计展示了裸 `pcall` 会返回完整路径，而 `xpcall` 处理器
  只返回调用方可以安全看到的消息——原始文本属于服务端日志。

---

## 最佳实践

1. **验证所有输入**在系统边界
2. **使用参数化查询**进行数据库访问
3. **实现最小权限**给插件
4. **记录安全事件**用于审计
5. **定期更新依赖**

---

## 核心要点

- 输入验证是第一道防线
- 沙箱保护免受不受信任的代码影响
- 权限系统限制插件能力
- 错误消息不应暴露内部细节
- 安全需要纵深防御

---

## 练习

### 初级（30–60 分钟）

1. **输入验证器**：创建一个 `validate_email(email)` 函数，检查有效的邮箱格式并返回 `true` 或 `false`。

2. **路径检查器**：编写一个 `safe_path(filename, allowed_dirs)` 函数，防止路径遍历攻击。

### 中级（1–2 小时）

3. **权限系统**：实现一个简单的权限系统，在 API 访问前授予/撤销插件权限并检查它们。

4. **安全插件加载器**：构建一个对代码执行进行沙箱处理并根据权限限制可用 API 的插件加载器。

### 高级（2–4 小时）

5. **安全扫描器**：创建一个扫描 Lua 代码潜在安全问题（文件访问、网络调用等）并报告结果的工具。

6. **速率限制器**：实现一个速率限制器，通过限制每个时间窗口的 API 调用来防止滥用。

---

## 示例代码

本章可运行示例：
- `examples/advanced/27-security-audit.lua` — 字节码加载拒绝、带写入守卫的沙箱化 `_ENV`、不可达的危险全局变量与资源上限，每一项都针对真实攻击尝试进行验证
- `examples/advanced/21-sandbox-demo.lua` — 恶意输入进入沙箱时的行为
- `examples/advanced/25-sandbox-escape.lua` — 针对朴素白名单沙箱与加固沙箱的四次逃逸尝试

---

## 延伸阅读

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Lua 安全注意事项](https://www.lua.org/pil/contents.html)

---

[返回 README](../README.md)
