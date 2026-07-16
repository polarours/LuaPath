# 09 — 标准库

> **阶段**: C（并发与运行时表面）
> **前置条件**: 第 08 章 — 协程
> **预计时间**: 2–3 小时阅读 + 2–4 小时练习
> **Lua 版本**: 5.1、5.3、5.4、LuaJIT（差异已注明）

---

## 学习目标

完成本章后，你将能够：

1. **熟练使用标准库**，了解哪个模块处理哪种常见任务
2. **使用 `string` 库模式**进行解析、匹配和转换
3. **正确应用 `table` 库操作**进行排序、拼接和处理
4. **使用 `math` 和 `utf8`** 进行数值和 Unicode 操作
5. **安全使用 `io`/`os`**，了解沙箱限制和平台差异

---

## 标准库概览

| 模块 | 用途 | 沙箱安全？ |
|--------|---------|---------------|
| `string` | 文本处理、模式匹配 | 是 |
| `table` | 数组/映射操作、排序 | 是 |
| `math` | 数值函数、随机数 | 是 |
| `utf8`（5.3+） | Unicode 码点操作 | 是 |
| `io` | 文件 I/O | 否（沙箱中需限制） |
| `os` | 系统调用、时间 | 否（沙箱中需限制） |
| `debug` | 内省、钩子 | 否（沙箱中需禁用） |
| `package` | 模块加载 | 否（沙箱中需限制） |
| `coroutine` | 协程操作 | 是 |
| `bit32`（5.1-5.2） | 位运算 | 是 |

---

## string 库

### 模式匹配

Lua 模式**不是** PCRE 正则。关键区别：

| 特性 | Lua | PCRE |
|---------|-----|------|
| 字符类 | `%d`、`%w`、`%s` | `\d`、`\w`、`\s` |
| 量词 | `*`、`+`、`-`、`?` | `*`、`+`、`?`、`{n}` |
| 捕获组 | `()` | `()` |
| 命名组 | 无 | `(?P<name>...)` |
| 前瞻/后顾 | 无 | `(?=...)`、`(?<=...)` |
| 分支选择 | 无 | `\|` |

```lua
-- 基本模式
local s = "Hello, World 2024!"
print(string.match(s, "%d+"))        -- "2024"（数字）
print(string.match(s, "%a+"))        -- "Hello"（字母）
print(string.match(s, "%s+%S+"))     -- ", World"（空白 + 非空白）

-- 捕获组
local name, domain = string.match("user@example.com", "^([^@]+)@(.+)$")
print(name, domain)          -- "user"  "example.com"

-- 嵌套捕获
local full, area, num = string.match("(555) 123-4567", "%((%d+)%)%s+(%d+)-(%d+)")
print(full, area, num)       -- "(555) 123-4567"  "555"  "123"  "4567"
```

### gmatch：迭代匹配结果

```lua
-- 查找所有单词
local s = "hello world lua"
for word in string.gmatch(s, "%a+") do
  print(word)
end
-- "hello"  "world"  "lua"

-- 查找所有数字
local numbers = {}
for n in string.gmatch("item1 item2 item3", "%d+") do
  numbers[#numbers + 1] = tonumber(n)
end
```

### gsub：全局替换

```lua
-- 简单替换
print(("hello world"):gsub("world", "Lua"))  -- "hello Lua"  1

-- 带捕获的模式替换
print(("abc 123 def 456"):gsub("(%d+)", "[%1]"))
-- "abc [123] def [456]"  2

-- 函数替换
local rotated = ("abc"):gsub("%a", function(c)
  return string.char((byte(c) - 65 + 1) % 26 + 65)
end)
print(rotated)  -- "bcd"
```

### string.format

```lua
-- 基本格式化
print(string.format("Name: %s, Age: %d", "Lua", 30))
-- "Name: Lua, Age: 30"

-- 浮点数
print(string.format("Pi: %.4f", math.pi))  -- "Pi: 3.1416"

-- 十六进制、八进制、二进制
print(string.format("%x %X %o", 255, 255, 255))
-- "ff FF 377"

-- 填充
print(string.format("%10s", "right"))   -- "     right"
print(string.format("%-10s", "left"))   -- "left      "
print(string.format("%05d", 42))        -- "00042"
```

### string.find 纯文本搜索

```lua
-- 纯文本搜索（不使用模式）
local start, finish = string.find("hello world", "world", 1, true)
print(start, finish)  -- 7  11

-- 模式搜索（默认）
local start, finish = string.find("hello 123 world", "%d+")
print(start, finish)  -- 7  9
```

---

## table 库回顾

### table.sort 稳定性

`table.sort` **不保证稳定**。实现稳定排序：

```lua
-- 添加原始索引以保证稳定性
local items = {{name="b", score=90}, {name="a", score=90}}
for i, item in ipairs(items) do item._idx = i end

table.sort(items, function(a, b)
  if a.score == b.score then return a._idx < b._idx end
  return a.score > b.score
end)
```

### table.move（5.3+）

```lua
-- 在表之间移动元素
local src = {1, 2, 3, 4, 5}
local dst = {}
table.move(src, 1, 3, 1, dst)  -- dst = {1, 2, 3}

-- 在同一表内移位
table.move(src, 1, 3, 2, src)  -- src = {1, 1, 2, 3, 5}
```

### table.pack / table.unpack（5.2+）

```lua
-- 打包可变参数
local t = table.pack(1, "two", 3.0)
print(t.n)  -- 3

-- 按范围解包
local values = {10, 20, 30, 40, 50}
print(table.unpack(values, 2, 4))  -- 20  30  40
```

### 构建函数式模式

```lua
-- map
local function map(t, fn)
  local result = {}
  for i, v in ipairs(t) do result[i] = fn(v) end
  return result
end

-- reduce
local function reduce(t, fn, init)
  local acc = init
  for _, v in ipairs(t) do acc = fn(acc, v) end
  return acc
end

-- 使用
local doubled = map({1, 2, 3}, function(x) return x * 2 end)
-- doubled = {2, 4, 6}

local sum = reduce({1, 2, 3, 4}, function(a, b) return a + b end, 0)
-- sum = 10
```

---

## math 库

### 核心函数

```lua
print(math.abs(-5))        -- 5
print(math.ceil(3.2))      -- 4
print(math.floor(3.7))     -- 3
print(math.max(1, 5, 3))   -- 5
print(math.min(1, 5, 3))   -- 1
print(math.sqrt(16))       -- 4
print(math.log(100, 10))   -- 2（以 10 为底的对数）
print(math.exp(1))         -- 2.718...
print(math.pi)             -- 3.14159...
```

### 随机数

```lua
-- 在程序启动时设定一次种子
math.randomseed(os.time())

-- 范围 [1, 100] 内的随机整数
print(math.random(100))

-- 范围 [0, 1) 内的随机浮点数
print(math.random())

-- 范围 [a, b] 内的随机整数
local function rand_int(a, b)
  return math.random(a, b)
end
```

### 整数与浮点数（5.3+）

```lua
-- Lua 5.3+ 区分整数和浮点数
print(math.type(42))      -- "integer"
print(math.type(3.14))    -- "float"
print(math.type(42.0))    -- "float"（仍然是浮点数！）

-- 整数除法
print(7 // 2)   -- 3（整数）
print(7 / 2)    -- 3.5（浮点数）

-- 整数溢出回绕（5.3+）
print(math.maxinteger)    -- 9223372036854775807
print(math.maxinteger + 1) -- -9223372036854775808（回绕！）
```

---

## utf8 库（5.3+）

```lua
-- 码点计数
print(utf8.len("hello"))     -- 5
print(utf8.len("你好世界"))    -- 4

-- 获取指定位置的码点
print(utf8.codepoint("hello", 1))  -- 104（'h'）

-- 将码点编码为 UTF-8
print(utf8.char(72, 101, 108))  -- "Hel"

-- 偏移量计算
local s = "hello"
local pos = utf8.offset(s, 3)  -- 第 3 个码点的字节偏移量
print(pos)  -- 3

-- 字素迭代（手动方式）
for _, cp in utf8.codes("hello") do
  print(cp)
end
```

---

## io 库

### 文件操作

```lua
-- 读取整个文件
local f = io.open("data.txt", "r")
if f then
  local content = f:read("*a")
  f:close()
end

-- 逐行读取
for line in io.lines("data.txt") do
  print(line)
end

-- 写入文件
local f = io.open("output.txt", "w")
f:write("hello\n")
f:close()
```

### io.open 模式

| 模式 | 描述 |
|------|-------------|
| `"r"` | 读取（默认） |
| `"w"` | 写入（截断） |
| `"a"` | 追加 |
| `"r+"` | 读写 |
| `"rb"` | 二进制读取 |
| `"wb"` | 二进制写入 |

### io.popen（子进程）

```lua
-- 运行命令并捕获输出
local handle = io.popen("ls -la")
local result = handle:read("*a")
handle:close()
```

> **沙箱警告**: `io` 和 `os` 可访问文件系统和系统资源。在沙箱环境中需移除或限制使用。

---

## os 库

### 时间

```lua
-- 当前时间（自纪元以来的秒数）
local now = os.time()
print(now)

-- 日期格式化
print(os.date("%Y-%m-%d %H:%M:%S"))  -- "2024-01-15 14:30:00"
print(os.date("!%Y-%m-%dT%H:%M:%SZ"))  -- UTC 格式

-- 日期表
local t = os.date("*t")
print(t.year, t.month, t.day)  -- 2024  1  15

-- 计算时间差（秒）
local start = os.time()
-- ... 执行工作 ...
local elapsed = os.difftime(os.time(), start)
```

### 执行

```lua
-- 执行 shell 命令
os.execute("echo hello")

-- 捕获退出码
local code = os.execute("exit 42")
print(code)  -- 42
```

---

## 常见陷阱

### 1. 将模式当作 PCRE 使用

```lua
-- 错误：PCRE 语法不适用
-- ("hello"):match("\w+")          -- 错误
-- ("hello"):match("(?:hello)")    -- 错误

-- 正确：Lua 模式
("hello"):match("%a+")             -- "hello"
```

### 2. locale 相关的字符串操作

```lua
-- 排序依赖 locale
local items = {"c", "a", "B", "b", "A"}
table.sort(items)
-- 结果取决于 locale！可能不是 ASCII 顺序

-- 如需 ASCII 顺序，使用字节比较
table.sort(items, function(a, b) return a:byte() < b:byte() end)
```

### 3. 在逻辑层中使用阻塞 I/O

```lua
-- 差：在业务逻辑中直接使用 I/O
function process_order(order)
  local data = io.open("config.txt"):read("*a")  -- 阻塞！
  -- ...
end

-- 好：注入 I/O 依赖
function process_order(order, config)
  -- config 已经加载
end
```

### 4. 未检查 io.open 返回值

```lua
-- 差：假设文件存在
local f = io.open("data.txt", "r")
local content = f:read("*a")  -- 如果 f 为 nil 则崩溃！

-- 好：检查返回值
local f, err = io.open("data.txt", "r")
if not f then
  return nil, "cannot open: " .. err
end
local content = f:read("*a")
f:close()
```

### 5. UTF-8 字节与码点

```lua
local s = "你好"
print(#s)           -- 6（字节数，不是字符数！）
print(utf8.len(s))  -- 2（码点数）
```

---

## 最佳实践

### 1. 封装平台 API

```lua
-- 适配器模式，提高可测试性
local clock = {
  now = function() return os.time() end,
  diff = function(a, b) return os.difftime(a, b) end,
}

-- 在测试中，注入模拟对象：
-- clock = { now = function() return 1000 end }
```

### 2. 保持解析函数纯净

```lua
-- 纯函数：相同输入 → 相同输出，无副作用
local function parse_csv_line(line)
  local fields = {}
  for field in (line .. ","):gmatch("([^,]*),") do
    fields[#fields + 1] = field
  end
  return fields
end
```

### 3. 记录文本编码

```lua
--- 解析 UTF-8 字符串并返回码点
-- 假设输入为有效的 UTF-8
-- @param s string UTF-8 编码字符串
-- @return table 码点数组
local function to_codepoints(s)
  local result = {}
  for _, cp in utf8.codes(s) do
    result[#result + 1] = cp
  end
  return result
end
```

### 4. 优先使用 `string.format` 而非拼接

```lua
-- 差：多次拼接
local msg = "Hello, " .. name .. "! You have " .. count .. " items."

-- 好：格式化字符串
local msg = string.format("Hello, %s! You have %d items.", name, count)
```

### 5. 使用 `table.concat` 构建字符串

```lua
-- 差：O(n²) 拼接
local result = ""
for i = 1, 10000 do
  result = result .. i
end

-- 好：使用 table 的 O(n) 方式
local parts = {}
for i = 1, 10000 do
  parts[#parts + 1] = tostring(i)
end
local result = table.concat(parts)
```

---

## 版本说明

### Lua 5.1

- 无 `utf8` 库
- `bit32` 库用于位运算
- `string.gmatch` 可用
- `table.pack`/`table.unpack` 不可用

### Lua 5.2/5.3

- 新增 `utf8` 库（5.3+）
- 新增 `table.pack`/`table.unpack`
- 新增 `math.type`（5.3+）
- `bit32` 在 5.3 中移除（由原生运算符替代）

### Lua 5.4

- `string.format` 改进对 `%d` 整数的支持
- `utf8.codepoint` 范围检查改进
- `math.random` 使用更好的算法

### LuaJIT

- 标准库兼容 Lua 5.1
- `ffi` 库用于 C FFI（不属于标准 Lua）
- 部分字符串操作经过 JIT 优化

---

## 知识检查

<details>
<summary>1. <code>string.find</code> 和 <code>string.match</code> 有什么区别？</summary>

`find` 返回匹配的起始和结束字节位置。`match` 返回捕获的子串（如果没有捕获则返回整个匹配）。
</details>

<details>
<summary>2. 为什么 <code>#s</code> 对 UTF-8 字符串不可靠？</summary>

`#s` 返回字节长度，不是字符数。一个 UTF-8 字符可以是 1-4 个字节。使用 `utf8.len()` 获取码点数。
</details>

<details>
<summary>3. <code>string.gsub</code> 返回什么？</summary>

修改后的字符串和替换次数。`("a-b-c"):gsub("-", "/")` 返回 `"a/b/c"` 和 `2`。
</details>

<details>
<summary>4. 为什么要检查 <code>io.open</code> 的返回值？</summary>

`io.open` 失败时返回 `nil, error_message`（文件未找到、权限不足等）。不检查会导致空引用崩溃。
</details>

<details>
<summary>5. 如何使 <code>table.sort</code> 稳定？</summary>

为每个元素添加原始索引字段。在比较函数中，当值相等时比较原始索引以保持输入顺序。
</details>

---

## 关键要点

- **`string`**：模式是 Lua 特有的，不是 PCRE；使用 `%d`、`%a`、`%s` 等字符类
- **`table`**：`sort` 不稳定；使用 `move`（5.3+）进行批量元素转移
- **`math`**：5.3+ 区分整数和浮点数；整数溢出会回绕
- **`utf8`**：使用 `utf8.len()` 而非 `#s` 来计数字符
- **`io`/`os`**：在沙箱中需限制使用；始终检查 `io.open` 返回值
- **`table.concat`** 的复杂度为 O(n)；循环中字符串拼接 `..` 的复杂度为 O(n²)
- **封装平台 API** 以提高可测试性和可移植性

---

## 练习

### 初级（30–60 分钟）

1. **CSV 解析器**：编写 `parse_csv(line)`，处理带引号字段和转义逗号的情况。

2. **词频统计器**：使用 `gmatch` 统计字符串中的单词频率，返回排序结果。

3. **模板引擎**：构建 `render(template, data)`，将 `{{key}}` 占位符替换为表中的值。

### 中级（1–2 小时）

4. **模式测试器**：创建一个交互工具，测试 Lua 模式对输入字符串的匹配结果，显示捕获内容和匹配位置。

5. **文件监视器**：使用 `os.execute` 和 `io.popen` 构建一个简单的文件变更检测器（基于轮询）。

6. **Unicode 规范化器**：编写一个函数，使用 `utf8.codepoint` 和 `utf8.char` 将 UTF-8 字符串转为小写。

### 高级（2–4 小时）

7. **正则子集**：实现一个小型正则编译器，将 PCRE 语法的子集转换为 Lua 模式，并对不支持的特性给出清晰的错误信息。

8. **流式解析器**：构建一个 CSV/JSON 解析器，基于数据块（流式 I/O）工作，而非加载整个文件。

---

## 示例代码

本章可运行的示例：
- `examples/beginner/01-moving-average.lua` — 字符串和 math 模式
- `examples/beginner/03-word-frequency.lua` — 基于 gmatch 的文本处理
- `examples/intermediate/04-stateful-module.lua` — 带 I/O 的模块

---

## 延伸阅读

- [Lua 5.4 参考手册 — 第 6 节](https://www.lua.org/manual/5.4/manual.html#6)
- [Programming in Lua（第 4 版）— 第 10–12 章](https://www.lua.org/pil/)
- [下一章：10 — Lua 内部机制](10-lua-internals.md)
