# 第18章：Lua 中的安全性

> **阶段**：高级  
> **前置章节**：第06章（模块）、第17章（嵌入模式）  
> **时间**：8–12小时  
> **Lua 版本**：5.1、5.3、5.4、LuaJIT

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
local fn = load(user_input)  -- 可能执行任何操作！
fn()

-- 安全：验证并限制
local function safe_execute(code)
  -- 验证代码不包含危险模式
  if code:match("os%.") or code:match("io%.") then
    return nil, "检测到危险代码"
  end
  
  local env = {print = print, math = math}
  local fn = load(code, "user", "t", env)
  if not fn then
    return nil, "无效代码"
  end
  
  return fn()
end
```

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
-- 危险：假设整数边界
local function calculate_hash(data)
  local hash = 0
  for i = 1, #data do
    hash = (hash * 31 + data:byte(i)) % 2^32
  end
  return hash
end

-- 安全：使用显式边界检查
local function safe_hash(data)
  local hash = 0
  for i = 1, #data do
    hash = (hash * 31 + data:byte(i))
    if hash > 2^52 then
      hash = hash % 2^52  -- 防止精度损失
    end
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
  local fn, err = load(plugin_code, "plugin", "t", env)
  if not fn then
    return nil, "插件编译错误: " .. err
  end
  
  -- 设置环境
  setmetatable(env, {__index = _G})
  
  -- 执行插件
  local ok, result = pcall(fn)
  if not ok then
    return nil, "插件运行时错误: " .. result
  end
  
  return result
end
```

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

## 延伸阅读

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Lua 安全注意事项](https://www.lua.org/pil/contents.html)

---

[返回 README](README.md)
