# Lua 版本差异

全面对比各 Lua 版本之间的行为差异。

---

## 快速对比表

| 特性 | 5.1 | 5.2 | 5.3 | 5.4 | 5.5 | LuaJIT |
|---------|-----|-----|-----|-----|-----|--------|
| **数值类型** | float | float | 整数 + 浮点 | 整数 + 浮点 | 整数 + 浮点 | float + FFI |
| **整数除法** | ✗ | ✗ | `//` | `//` | `//` | ✗ |
| **按位运算符** | ✗ | ✗ | ✓ | ✓ | ✓ | ✓（扩展） |
| **`_ENV`** | ✗ | ✓ | ✓ | ✓ | ✓ | ✗ |
| **`setfenv`/`getfenv`** | ✓ | ✗ | ✗ | ✗ | ✗ | ✓ |
| **分代 GC** | ✗ | ✗ | ✗ | ✓ | ✓ | ✗ |
| **to-be-closed 变量** | ✗ | ✗ | ✗ | ✓ | ✓ | ✗ |
| **Ephemeron 表** | ✗ | ✓ | ✓ | ✓ | ✓ | ✗ |
| **`goto` 语句** | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **位运算库** | ✗ | `bit32` | `bit32` | ✗ | ✗ | `bit.*` |
| **`__len` 元方法** | ✗ | ✓（表格） | ✓ | ✓ | ✓ | ✗ |
| **包机制** | `module` | `require` | `require` | `require` | `require` | `module` + `require` |
| **FFI** | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ |
| **JIT 编译** | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ |

---

## 数值表示

### Lua 5.1–5.2

```lua
-- 单一数值类型（双精度浮点）
print(type(42))       -- "number"
print(type(3.14))     -- "number"
print(42 == 42.0)     -- true

-- 精度上限
print(9007199254740993 == 9007199254740992)  -- true（精度丢失！）
```

### Lua 5.3+

```lua
-- 双重表示。注意 type() 对两者都返回 "number"：
-- 区分整数与浮点的是 math.type()。
print(type(42))       -- "number"
print(type(3.14))     -- "number"
print(math.type(42))  -- "integer"   （仅 5.3+）
print(math.type(3.14))-- "float"     （仅 5.3+）
print(42 == 42.0)     -- true（比较时自动转换）

-- 整数除法
print(5 // 2)         -- 2（整数结果）
print(5 / 2)          -- 2.5（浮点数结果）

-- 按位运算符
print(5 | 3)          -- 7
print(5 & 3)          -- 1
print(5 ~ 3)          -- 6
print(~5)             -- -6
print(5 << 1)         -- 10
print(5 >> 1)         -- 2
```

### LuaJIT

```lua
-- 单一数值类型（与 5.1 相同）
print(type(42))       -- "number"

-- 但 FFI 提供了整数
local ffi = require("ffi")
local x = ffi.cast("int", 42)
print(type(x))        -- "cdata"

-- 通过库实现按位运算
local bit = require("bit")
print(bit.bor(5, 3))  -- 7
```

---

## 环境模型

### Lua 5.1：`setfenv` / `getfenv`

```lua
-- 获取当前环境
local env = getfenv()

-- 设置函数的环境
local function restricted()
  print("hello")  -- 如果 print 被移除就会失败
end

setfenv(restricted, {print = print})  -- 只允许 print

-- 创建沙箱
local sandbox = {
  print = print,
  math = math,
}
setfenv(restricted, sandbox)
```

### Lua 5.2+：`_ENV`

```lua
-- _ENV 是一个普通变量
local function restricted()
  print("hello")
end

-- 在编译期更换环境
local function sandboxed()
  print("hello")
end

local sandbox = {print = print}
debug.setupvalue(sandboxed, 1, sandbox)  -- 设置 _ENV 上值

-- 也可以在 chunk 中直接使用 _ENV
local chunk = load([[
  print(_VERSION)  -- 使用 load 上下文中的 _ENV
]], "=chunk", "t", {print = print, _VERSION = _VERSION})
```

### 迁移：5.1 → 5.2+

```lua
-- 5.1 写法
setfenv(1, {print = print, x = 10})

-- 5.2+ 等价写法
_ENV = {print = print, x = 10}

-- 或者用于函数
local function fn()
  print(x)
end
debug.setupvalue(fn, 1, {print = print, x = 10})
```

---

## 垃圾回收

### 增量 GC（所有版本）

```lua
-- 控制增量 GC
collectgarbage("setpause", 200)    -- 等待上次回收耗时的 200%
collectgarbage("setstepmul", 200)  -- 相对于分配速度的 200%

-- 手动控制
collectgarbage("stop")             -- 停止 GC
collectgarbage("restart")          -- 重启 GC
collectgarbage("collect")          -- 完整回收
collectgarbage("count")            -- 内存占用（KB）
```

### 分代 GC（Lua 5.4+）

```lua
-- 启用分代模式（5.4）
collectgarbage("generational")

-- 或显式切换到增量模式
collectgarbage("incremental")

-- 查询模式
-- 注意：没有直接的查询接口，需要自己在代码中记录
```

### LuaJIT GC

```lua
-- LuaJIT 专属控制
collectgarbage("setpause", 200)

-- JIT 控制
jit.on()
jit.off()
jit.flush()

-- GC 的步进会影响 JIT 行为
```

---

## 字符串格式化

### 所有版本

```lua
-- 基础格式化（各版本一致）
string.format("%d", 42)      -- "42"
string.format("%s", "hi")    -- "hi"
string.format("%.2f", 3.14159)  -- "3.14"
```

### Lua 5.3+（整数格式化）

```lua
-- 整数专用格式
string.format("%i", 42)      -- "42"
string.format("%d", 42)      -- "42"

-- 整数的十六进制格式
string.format("%x", 255)     -- "ff"
string.format("%X", 255)     -- "FF"
```

---

## 长度运算符

### 所有版本

```lua
-- 序列（无空洞）时行为有明确定义
local t1 = {1, 2, 3}
print(#t1)  -- 3

-- 存在空洞时行为未定义
local t2 = {1, nil, 3}
print(#t2)  -- 可能是 1、2 或 3（取决于实现！）
```

### Lua 5.2+（Ephemeron 表）

```lua
-- 设置了 __mode = "k" 的弱表行为更好
local t = setmetatable({}, {__mode = "k"})
local key = {}
t[key] = "value"
-- 键被回收时，对应的条目会被移除
```

---

## 模块系统

### Lua 5.1：`module` 函数

```lua
-- mymodule.lua（5.1 风格）
module("mymodule", package.seeall)

function hello()
  print("Hello")
end
```

```lua
-- 使用
local m = require("mymodule")
m.hello()
```

### Lua 5.2+：显式返回

```lua
-- mymodule.lua（现代风格）
local M = {}

function M.hello()
  print("Hello")
end

return M
```

```lua
-- 使用
local m = require("mymodule")
m.hello()
```

### LuaJIT：推荐使用现代写法

```lua
-- 即使在 LuaJIT 中也使用 5.2+ 风格
-- module() 已被废弃
```

---

## 协程差异

### 所有版本

```lua
-- 基础协程 API（各版本一致）
local co = coroutine.create(function()
  coroutine.yield(1)
  return 2
end)

coroutine.resume(co)  -- true, 1
coroutine.resume(co)  -- true, 2
```

### Lua 5.2+（新增函数）

```lua
-- Lua 5.2+ 新增
coroutine.running()        -- 返回 (thread, is_main)
coroutine.isyieldable()    -- 检查是否允许 yield（5.3+）
```

### LuaJIT

```lua
-- LuaJIT 协程可以与 JIT 协同工作
-- 但跨越某些边界 yield 会禁用 JIT
```

---

## 错误处理

### 所有版本

```lua
-- pcall 与 xpcall（各版本一致）
local success, result = pcall(function()
  error("oops")
end)

local success, result = xpcall(function()
  error("oops")
end, debug.traceback)
```

### Lua 5.4+（错误对象解包）

```lua
-- Lua 5.4：错误对象
local function wrapped()
  local ok, err = pcall(function()
    error({code = "ENOENT", message = "Not found"})
  end)
  
  if not ok then
    print(err.code)  -- 访问结构化错误
  end
end
```

---

## to-be-closed 变量（Lua 5.4+）

```lua
-- 仅 Lua 5.4
local function process_file(path)
  local f <close> = assert(io.open(path))
  -- 作用域退出时 f 会自动关闭
  return f:read("*all")
end

-- 等价写法：
local function process_file(path)
  local f = assert(io.open(path))
  local ok, result = pcall(function()
    return f:read("*all")
  end)
  f:close()
  if not ok then error(result) end
  return result
end
```

---

## `goto` 语句（Lua 5.2+）

```lua
-- Lua 5.2+ 以及 LuaJIT 2.1
-- 写 `goto` 时有两条规则容易踩坑：
--   * `return` 必须是块内最后一句，所以「没找到」的分支不能在标签之前
--     写 return；
--   * 循环变量在标签处已经出了作用域，所以位置必须自己带出循环。
local function find_needle(haystack)
  local found_i
  for i = 1, #haystack do
    if haystack[i] == "needle" then
      found_i = i
      goto found
    end
  end

  ::found::
  return found_i
end
```

---

## 元方法差异

### `__len` 元方法

| 版本 | 表格 | 用户数据 |
|---------|--------|----------|
| 5.1 | ✗ | ✓ |
| 5.2+ | ✓ | ✓ |
| LuaJIT 2.1 | ✗ | ✓ |

```lua
-- 仅 5.2+
local t = setmetatable({}, {
  __len = function(self) return 42 end
})
print(#t)  -- 42（5.2+）
           -- 出错或返回 0（5.1）
```

---

## LuaJIT 专属特性

### FFI（外部函数接口）

```lua
local ffi = require("ffi")

-- 定义 C 类型
ffi.cdef[[
  int printf(const char *fmt, ...);
  typedef struct { double x, y; } Point;
]]

-- 调用 C 函数
ffi.C.printf("Hello from C!\n")

-- 创建 C 结构体
local p = ffi.new("Point", 1.0, 2.0)
print(p.x, p.y)  -- 1.0, 2.0
```

### JIT 控制

```lua
-- JIT 编译控制
jit.on()              -- 启用 JIT
jit.off()             -- 禁用 JIT
jit.flush()           -- 清除已编译代码

-- 按函数设置
jit.off(function()
  -- 该函数不会被 JIT 编译
end)

-- Pragmas
jit.pruneoff()        -- 对特定模式自动关闭
```

### Bit 库

```lua
local bit = require("bit")

-- 按位运算（适用于所有支持 LuaJIT 的 Lua 版本）
print(bit.bor(5, 3))   -- 7
print(bit.band(5, 3))  -- 1
print(bit.bxor(5, 3))  -- 6
print(bit.bnot(5))     -- -6
print(bit.lshift(5, 1)) -- 10
print(bit.rshift(5, 1)) -- 2
```

---

## 兼容性指南

### 编写跨版本代码

```lua
-- 检测版本
local LUA_VERSION = _VERSION:match("%d+%.%d+")

-- 版本相关的 API：math.type 是 5.3 才有的。
local kind
if LUA_VERSION >= "5.3" then
  kind = math.type(5)      -- "integer"
else
  kind = type(5)           -- "number"
end

-- 检测 LuaJIT
local is_luajit = jit and true or false
if is_luajit then
  local ffi = require("ffi")
  -- 使用 FFI
end
```

```lua
-- 仅 Lua 5.3+ 可用。
-- `//` 运算符不能出现在跨版本代码块里：5.1 的解释器会直接解析失败，
-- 哪怕那个分支根本不会执行。新语法要放进单独标注版本的文件。
local result = 5 // 2
```

### 推荐基线版本

| 使用场景 | 推荐版本 |
|----------|---------------------|
| 嵌入式脚本 | Lua 5.1（兼容性最好）|
| 游戏脚本 | Lua 5.3 或 LuaJIT |
| 新项目 | Lua 5.4 |
| 性能敏感场景 | LuaJIT |
| 库开发 | Lua 5.1（用户面最广）|

---

## 迁移检查清单

### 5.1 → 5.3+

- [ ] 用 `_ENV` 替换 `setfenv`/`getfenv`
- [ ] 更新数值处理（整数）
- [ ] 在适用处加入按位运算符
- [ ] 复查 `module()` 的使用（改用显式返回）
- [ ] 若使用了 `__len` 元方法则进行测试

### PUC Lua → LuaJIT

- [ ] 测试 JIT 兼容性（避免追踪中止）
- [ ] 考虑用 FFI 实现 C 互操作
- [ ] 复查对 GC 敏感的代码
- [ ] 用 `jit.off()` 关闭 JIT 以便调试

---

## 相关链接

- [Lua 5.1 手册](https://www.lua.org/manual/5.1/)
- [Lua 5.3 手册](https://www.lua.org/manual/5.3/)
- [Lua 5.4 手册](https://www.lua.org/manual/5.4/)
- [Lua 5.5 手册](https://www.lua.org/manual/5.5/)
- [LuaJIT 文档](https://luajit.org/)
- [Lua 5.3 变更说明](https://www.lua.org/manual/5.3/readme.html#changes)
- [Lua 5.4 变更说明](https://www.lua.org/manual/5.4/readme.html#changes)
- [Lua 5.5 变更说明](https://www.lua.org/manual/5.5/readme.html#changes)
