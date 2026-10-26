# 快速参考卡片

Lua 常用语法和模式的简明参考。

---

## 语法速查

### 变量与作用域

```lua
local x = 10          -- 局部变量（推荐）
global = 20           -- 全局变量 (_ENV["global"])

do
  local y = 30        -- 块级局部变量
end
```

### 类型

```lua
type(nil)             -- "nil"
type(true)            -- "boolean"
type(42)              -- "number"（5.3+ 为整数或浮点）
type("hello")         -- "string"
type({})              -- "table"
type(function() end)  -- "function"
type(coroutine.create(function() end))  -- "thread"
```

### 控制流

```lua
-- 条件语句
if condition then
  -- ...
elseif other then
  -- ...
else
  -- ...
end

-- 循环
for i = 1, 10 do end           -- 数值 for
for k, v in pairs(t) do end    -- 泛型 for（所有键）
for i, v in ipairs(t) do end   -- 泛型 for（数组索引）
while condition do end         -- while 循环
repeat
  -- ...
until condition     -- do-while 等价
```

### 函数

```lua
-- 定义
function name(param1, param2)
  return result
end

-- 匿名函数
local fn = function(x) return x * 2 end

-- 变长参数
function sum(...)
  local args = {...}
  local total = 0
  for _, v in ipairs(args) do total = total + v end
  return total
end

-- 多返回值
function divmod(a, b)
  -- `//` 是 5.3 才有的语法；用 math.floor 可以让这段在 5.1 上也成立。
  return math.floor(a / b), a % b
end
```

### 表格

```lua
-- 构造
local t = {}
local t2 = {1, 2, 3}           -- 数组部分
local t3 = {x = 1, y = 2}      -- 记录
local t4 = {[1] = "a"}         -- 显式键

-- 访问
local v1 = t.key          -- 同 t["key"]
local v2 = t[key]         -- 动态键
local v3 = t[1]           -- 数组索引

-- 长度（仅对序列可靠！）
local n = #t              -- 数组部分长度

-- 遍历
for k, v in pairs(t) do end    -- 所有键
for i, v in ipairs(t) do end   -- 连续整数键
```

### 元表

```lua
local mt = {
  __index = function(t, k) return default end,
  __newindex = function(t, k, v) rawset(t, k, v) end,
  __add = function(a, b) return a + b end,
  __tostring = function(t) return "table" end,
}

setmetatable(t, mt)
getmetatable(t)
```

### 模块

```lua
-- module.lua
local M = {}

function M.func() end

return M
```

```lua
-- 使用
local mod = require("module")
mod.func()
```

### 错误处理

```lua
-- 抛出错误
error("message", level)

-- 受保护调用
local success, result = pcall(fn, args)

-- 扩展受保护调用
local success, result = xpcall(fn, debug.traceback)

-- 断言（成功返回值，失败抛错）
local file = assert(io.open("file.txt"))
```

### 协程

```lua
local co = coroutine.create(fn)
local success, result = coroutine.resume(co)
local status = coroutine.status(co)  -- "running", "suspended", "dead"
coroutine.yield(value)
```

### 字符串模式

```lua
s:match(pattern)           -- 提取匹配
s:gmatch(pattern)          -- 迭代所有匹配
s:gsub(pattern, repl)      -- 替换
s:find(pattern)            -- 查找位置

-- 模式类
"."    -- 任意字符
"%"    -- 转义字符
"[%w]" -- 字符类（单词字符）
"[^%w]"-- 否定类
"*"    -- 0 次或多次
"+"    -- 1 次或多次
"-"    -- 0 次或多次（非贪婪）
"?"    -- 0 次或 1 次
```

---

## 标准库速查

### `table`

| 函数 | 描述 |
|------|------|
| `table.concat(t, sep, i, j)` | 拼接元素 |
| `table.insert(t, [pos,] val)` | 在位置插入 |
| `table.remove(t, [pos])` | 从位置删除 |
| `table.sort(t, [comp])` | 原地排序 |
| `table.pack(...)` | 打包为索引表 |
| `table.unpack(t)` | 解包为值 |

### `string`

| 函数 | 描述 |
|------|------|
| `string.len(s)` | 长度 |
| `string.sub(s, i, j)` | 子串 |
| `string.format(fmt, ...)` | 格式化（类 printf） |
| `string.match(s, pat)` | 首次匹配 |
| `string.gmatch(s, pat)` | 迭代所有匹配 |
| `string.gsub(s, pat, repl)` | 全局替换 |
| `string.find(s, pat)` | 查找位置 |
| `string.rep(s, n)` | 重复 n 次 |
| `string.reverse(s)` | 反转字符串 |
| `string.lower(s)` / `upper(s)` | 大小写转换 |

### `math`

| 函数 | 描述 |
|------|------|
| `math.abs(x)` | 绝对值 |
| `math.ceil(x)` / `floor(x)` | 向上/向下取整 |
| `math.max(a, b, ...)` / `min(...)` | 最大/最小值 |
| `math.sqrt(x)` | 平方根 |
| `math.sin/cos/tan(x)` | 三角函数 |
| `math.asin/acos/atan(x)` | 反三角函数 |
| `math.exp(x)` | e^x |
| `math.log(x)` / `log10(x)` | 对数 |
| `math.pi` / `huge` | 常量 |
| `math.random([m, n])` | 随机数 |

### `coroutine`

| 函数 | 描述 |
|------|------|
| `coroutine.create(fn)` | 创建协程 |
| `coroutine.resume(co, ...)` | 恢复执行 |
| `coroutine.yield(...)` | 内部挂起 |
| `coroutine.status(co)` | 获取状态 |
| `coroutine.running()` | 获取当前协程 |
| `coroutine.wrap(fn)` | 创建包装函数 |

---

## C API 速查

### 栈操作

```c
lua_pushnil(L);
lua_pushboolean(L, int);
lua_pushinteger(L, lua_Integer);
lua_pushnumber(L, lua_Number);
lua_pushstring(L, const char*);
lua_pushlstring(L, const char*, size_t);
lua_pushfunction(L, lua_CFunction);
lua_pushcclosure(L, lua_CFunction, int n);

lua_pop(L, int n);
lua_topointer(L, int idx);
lua_toboolean(L, int idx);
lua_tointeger(L, int idx);
lua_tonumber(L, int idx);
lua_tostring(L, int idx);
lua_tocfunction(L, int idx);
lua_touserdata(L, int idx);

lua_settop(L, int idx);
lua_gettop(L);
lua_absindex(L, int idx);
lua_checkstack(L, int n);
```

### 表格操作

```c
lua_newtable(L);
lua_gettable(L, int idx);
lua_settable(L, int idx);
lua_rawget(L, int idx);
lua_rawset(L, int idx);
lua_next(L, int idx);
```

### 函数注册

```c
// 注册函数
static const luaL_Reg mylib[] = {
  {"func_name", my_function},
  {NULL, NULL}
};

luaL_newlib(L, mylib);
luaL_requiref(L, "modname", luaopen_mymod, 1);
```

### 错误处理

```c
luaL_error(L, "error message");
luaL_checktype(L, int idx, int type);
luaL_checkinteger(L, int idx);
luaL_checkstring(L, int idx);
luaL_optinteger(L, int idx, lua_Integer def);
```

---

## 性能优化技巧

### 推荐做法

```lua
-- 在热循环中缓存全局变量
local sin = math.sin
for i = 1, 1000000 do
  x = sin(i)
end

-- 已知大小时预分配表格
-- table.create 是 Lua 5.5 才加的；在 5.1 到 5.4 上数组部会随着填充增长，
-- 而下面的构造器写法则预留了位置。
local t = table.create and table.create(n) or {}
for i = 1, n do
  t[i] = i * 2
end

-- 使用局部变量（寄存器分配）
local sum = 0
for i = 1, n do
  sum = sum + values[i]
end

-- 复用表格（当安全时）
local buffer = {}
for i = 1, n do
  -- 清空并复用
  for k in pairs(buffer) do buffer[k] = nil end
  -- ... 使用 buffer ...
end
```

### 避免做法

```lua
-- 不要在循环中拼接字符串
local s = ""
for i = 1, n do
  s = s .. i  -- O(n²) 分配！
end

-- 应该这样做：
local parts = {}
for i = 1, n do
  parts[i] = tostring(i)
end
local s = table.concat(parts)

-- 不要在热循环中创建表格
for i = 1, n do
  local t = {x = i}  -- 每次迭代都分配！
end

-- 不要无缓存地使用全局变量
for i = 1, 1000000 do
  x = math.sin(i)  -- 每次都查找 _ENV
end
```

---

## 版本差异

| 特性 | 5.1 | 5.2 | 5.3 | 5.4 | 5.5 | LuaJIT |
|------|-----|-----|-----|-----|-----|--------|
| **数值类型** | float | float | 整数 + 浮点 | 整数 + 浮点 | 整数 + 浮点 | float + FFI |
| **整数除法** | ✗ | ✗ | `//` | `//` | `//` | ✗ |
| **按位运算符** | ✗ | ✗ | ✓ | ✓ | ✓ | ✓（扩展） |
| **`_ENV`** | ✗ | ✓ | ✓ | ✓ | ✓ | ✗ |
| **`setfenv`/`getfenv`** | ✓ | ✗ | ✗ | ✗ | ✗ | ✓ |
| **分代 GC** | ✗ | ✗ | ✗ | ✓ | ✓ | ✗ |
| **to-be-closed 变量** | ✗ | ✗ | ✗ | ✓ | ✓ | ✗ |
| **FFI** | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ |
| **JIT 编译** | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ |

---

## 常用模式

### 模块模板

```lua
local M = {}

local function private_helper() end

function M.public_function()
  return private_helper()
end

M.CONSTANT = 42

return M
```

### 类式原型

```lua
local Class = {}
Class.__index = Class

function Class:new(value)
  return setmetatable({value = value}, self)
end

function Class:method()
  return self.value
end

return Class
```

### 迭代器模式

```lua
local function my_iterator(t)
  local i = 0
  return function()
    i = i + 1
    return t[i]
  end
end

for value in my_iterator({1, 2, 3}) do
  print(value)
end
```

### 记忆化

```lua
local function memoize(fn)
  local cache = {}
  return function(key)
    if cache[key] == nil then
      cache[key] = fn(key)
    end
    return cache[key]
  end
end
```
