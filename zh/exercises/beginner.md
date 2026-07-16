# 初级练习

涵盖路线图阶段 1–8（核心语言能力到模板引擎）。

---

## 1. 概念巩固

### 1.1 — 表构造与数组遍历（阶段 1）[简单]
实现 `range(n)` 返回 `{1, 2, ..., n}`，然后实现 `sum(t)` 返回所有数值的总和（跳过非数值）。
```lua
print(sum(range(5)))              --> 15
print(sum({1, "a", 3, nil, 5}))  --> 9
```
**提示**：使用 `ipairs` 遍历 range；在 sum 中使用 `type()` 进行守卫判断。

### 1.2 — 函数与闭包（阶段 1）[简单]
编写 `make_adder(n)` 返回一个将 `n` 加到参数上的函数。链式调用两个 adder：
```lua
local add5 = make_adder(5)
local add3 = make_adder(3)
print(add5(add3(10)))  --> 18
```

### 1.3 — FizzBuzz 变体（阶段 1）[简单]
编写 `fizzbuzz(n)` 返回一个字符串表。3 的倍数 → `"Fizz"`，5 的倍数 → `"Buzz"`，两者都是 → `"FizzBuzz"`，否则为数字的字符串形式。

### 1.4 — 字符串模式：提取邮箱字段（阶段 1）[中等]
编写 `parse_name(email)` 通过 `string.match` 返回用户名和域名。
```lua
local user, domain = parse_name("alice@example.com")
print(user, domain)  --> alice   example.com
```
**提示**：使用模式 `^(.+)@(.+)$`。

### 1.5 — 字符串模式：CSV 解析器（阶段 1）[中等]
编写 `parse_csv(line)` 分割逗号分隔的字段，处理引号内包含逗号的字段。
```lua
local fields = parse_csv('name,age,"city, state"')
-- fields = {"name", "age", "city, state"}
```
**提示**：使用 `string.find` 配合 `([^,]+)` 和 `"[^"]*"`。

### 1.6 — 词频统计（阶段 1）[中等]
编写 `word_freq(text)` 返回一个 word → count 的表（不区分大小写）。
```lua
local f = word_freq("the cat and the dog")
-- f["the"] = 2, f["cat"] = 1, f["and"] = 1, f["dog"] = 1
```
**提示**：使用 `string.gmatch` 提取单词；使用 `string.lower` 标准化。

### 1.7 — Metatable：委托（阶段 2）[中等]
创建 `parent = {name = "default"}` 和 `child = setmetatable({}, {__index = parent})`。验证 `child.name` 返回 `"default"`，然后设置 `child.name = "override"` 并确认 parent 未被改变。

### 1.8 — Metatable：自定义 `__add`（阶段 2）[中等]
创建 `Vec2.new(x, y)` 并实现 `__add`（逐元素相加）和 `__tostring`。
```lua
print(Vec2.new(1,2) + Vec2.new(3,4))  --> Vec2(4, 6)
```

### 1.9 — 模块模式（阶段 2）[中等]
编写一个 `mathutils` 模块文件，使用局部变量作为内部实现，通过公共表暴露 `clamp(val, lo, hi)` 和 `lerp(a, b, t)`。

### 1.10 — Coroutine：生产者-消费者（阶段 3）[中等]
创建一个 yield 数字 1–5 的 coroutine。在循环中 resume 它，将值收集到一个表中。期望结果：`{1, 2, 3, 4, 5}`。

### 1.11 — 错误处理：安全解析（阶段 2）[中等]
编写 `safe_parse(s)` 在 `pcall` 内调用 `tonumber`。返回 `(number, nil)` 或 `(nil, error_msg)`。
```lua
print(safe_parse("42"))  --> 42    nil
print(safe_parse("abc")) --> nil   "not a valid number"
```

---

## 2. 小型项目

### 2.1 — 简易 JSON 解析器（阶段 6）[中等偏难]
构建一个递归下降 JSON 解析器。支持字符串、数字、布尔值、null、数组、嵌套对象。
- 实现一个分词器，识别 `{}`、`[]`、`,`、`:`、字符串、数字、`true`/`false`/`null`
- 为每个语法规则编写递归下降函数
- 对象和数组返回 Lua 表；将 JSON null 映射为哨兵值

```lua
local data = parse_json('{"name":"Alice","scores":[95,87],"active":true}')
print(data.name)       --> Alice
print(data.scores[1])  --> 95
```

**提示**：使用 `string.find` 配合模式 `^%s*"` 和 `^%s*[%d%-]` 来识别下一个 token。跟踪位置索引。处理字符串中的转义序列。

### 2.2 — 配置文件读取器（阶段 7）[中等]
解析 INI 风格的文件，支持分节、键值对、注释（`#`/`;`）和 `${VAR}` 环境变量扩展。
```lua
-- config.ini: [database] host = localhost\nport = 5432\nname = ${DB_NAME}
local config = load_config("config.ini")
print(config.database.host)          --> localhost
print(config.get("database.host"))   --> localhost（点路径）
print(config.get("missing", 42))     --> 42（默认值）
```

**提示**：使用 `io.lines(path)` 读取；使用 `string.match(line, "^%[(.+)%]")` 提取分节；使用 `string.gsub(value, "%${([^}]+)}", os.getenv)` 展开环境变量。

### 2.3 — 模板引擎（阶段 8）[中等偏难]
构建一个模板引擎，支持 `{{var}}` 插值、`{% if condition %}...{% end %}` 条件语句和 `{% for k,v in list %}...{% end %}` 循环。
```lua
local tmpl = "Hello {{name}}!{% if items %}\nItems:{% for _,i in ipairs(items) %}\n- {{i}}{% end %}{% end %}"
print(render(tmpl, {name="Alice", items={"a","b"}}))
-- Hello Alice!
-- Items:
-- - a
-- - b
```

**提示**：先处理条件/循环语句，再插值变量。通过 `.` 分隔来解析点路径。

### 2.4 — 任务追踪 CLI（阶段 1–2）[中等]
命令：`add <title>`、`list`、`remove <id>`、`done <id>`。以 JSON 格式存储在 `tasks.json` 中。分离模块：`parser.lua`、`store.lua`、`cli.lua`。

---

## 3. 调试任务

### 3.1 — 全局变量泄漏 [简单]
```lua
function create_user(name)
  user = { name = name, active = true }
  return user
end
local u1 = create_user("Alice")
local u2 = create_user("Bob")
print(u1.name)  --> "Bob" — 错误！
```
**修复**：为什么会发生这种情况？添加 `local` 并重新测试。

### 3.2 — 稀疏数组的表长度 [简单]
```lua
local t = {1, nil, 3}
print(#t)  -- 不可靠
```
**任务**：编写 `safe_length(t)` 统计非 nil 的整数键数量。在 `{1, nil, 3}` 和 `{nil, 2, nil, 4}` 上进行测试。

### 3.3 — 死亡 Coroutine Resume [中等]
```lua
local co = coroutine.create(function()
  coroutine.yield("first"); coroutine.yield("second")
end)
coroutine.resume(co)  --> true, "first"
coroutine.resume(co)  --> true, "second"
coroutine.resume(co)  --> 错误：无法 resume 已终止的 coroutine
```
**修复**：编写 `safe_resume(co, ...)` 返回 `nil, "dead coroutine"` 而不是崩溃。

### 3.4 — Metatable 共享状态 [中等]
```lua
local User = {}; User.__index = User
function User.new(name) return setmetatable({name=name}, User) end
local u1, u2 = User.new("Alice"), User.new("Bob")
u1.scores = {100}
print(#u2.scores)  --> 1 — 应该是 0
```
**任务**：解释这个行为。如果是 bug，请修复。如果不是，请记录为什么 `__index` 在这里不会导致共享可变状态。

### 3.5 — 迭代期间的修改 [中等]
```lua
local t = {a=1, b=2, c=3}
for k,v in pairs(t) do
  if v == 2 then t[k] = nil end
end
```
**修复**：先收集需要删除的键，循环结束后再删除。

### 3.6 — 闭包捕获循环变量 [简单]
```lua
local funcs = {}
for i = 1, 5 do funcs[i] = function() return i end end
print(funcs[1]())  --> 5 — 错误！
```
**修复**：让每个函数捕获自己的 `i` 副本。解释为什么会出现这个 bug。

---

## 4. 开放性设计问题

1. **可空字段**：比较 `nil`、哨兵值（`cjson.null`）和包装器 `{value=x, is_null=true}` 用于可空表字段。在序列化和迭代方面的权衡是什么？

2. **模块 API 风格**：返回函数表 vs metatable 类 vs 导出到 `_G` —— 哪种最容易测试？为什么？

3. **错误处理边界**：在小型脚本中，是每个函数都验证输入，还是在顶层使用 `pcall` 捕获所有错误？在规模化时会有什么变化？

4. **JSON null vs Lua nil**：为什么 Lua 的 `nil` 会破坏 JSON 的往返转换？设计一个在解析 → 转换 → 序列化过程中保留 JSON null 的方案。

5. **模板方法**：基于模式的字符串处理 vs 两阶段（解析为 AST，然后求值）。简单方法在什么情况下会失效？

6. **Coroutine vs 回调**：在什么场景下 coroutine 比回调能简化事件驱动系统？各举一个场景。
