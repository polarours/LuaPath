# 02 — 控制流：条件判断、循环与迭代

> **阶段**：A（核心语言素养）  
> **前置条件**：第 01 章 — 基础  
> **预计时间**：阅读 2–3 小时 + 练习 2–4 小时  
> **Lua 版本**：5.1、5.3、5.4、LuaJIT（差异已标注）

---

## 学习目标

完成本章后，你将能够：

1. **编写正确的条件判断**，利用 Lua 的真值规则和守卫模式
2. **选择合适的循环结构**（数值 `for`、泛型 `for`、`while`、`repeat`）
3. **创建自定义迭代器**，使用闭包和协程
4. **避免迭代陷阱**，包括迭代期间修改表
5. **合理组织循环退出**，有效使用 `break` 和提前返回

---

## 条件判断

### If-Then-Else 结构

Lua 的条件语法简洁而强大：

```lua
local mode = "safe"

if mode == "safe" then
  print("guarded")
elseif mode == "fast" then
  print("optimized")
else
  error("unknown mode: " .. tostring(mode))
end
```

### 条件中的真值

记住：只有 `false` 和 `nil` 为假值：

```lua
-- 常用模式
local value = input or default           -- 若为 nil 或 false 则使用默认值
local value = (input ~= nil) and input or default  -- 仅在 nil 时使用默认值

-- 守卫模式
if not config then
  return nil, "config is required"
end

if type(value) ~= "number" then
  error("expected number, got " .. type(value))
end
```

> **陷阱**：当 `false` 是一个合法值时，`or` 模式会失效。请使用显式的 `nil` 检查。

### 条件赋值

```lua
-- 类三元运算符模式（Lua 没有三元运算符）
local max = (a > b) and a or b

-- 但要小心假值！
local result = success and value or default  -- 如果 value 为 false 则错误
local result = success and value or nil      -- 更安全
if not success then result = default end     -- 最安全
```

### 多条件逻辑

```lua
-- 带短路求值的复杂条件
if enabled and count > 0 and has_permission(user, "edit") then
  save_changes()
end

-- 在复杂条件中使用括号以提高清晰度
if (is_admin or has_permission(user, "delete")) and not is_protected(target) then
  delete(target)
end
```

---

## 循环

### 数值 `for` 循环

当你知道迭代次数或需要基于索引访问时使用：

```lua
-- 递增
for i = 1, 10 do
  print(i)
end

-- 递减
for i = 10, 1, -1 do
  print(i)
end

-- 自定义步长
for i = 0, 100, 5 do
  print(i)
end

-- 数组迭代（从 1 开始！）
local items = {"a", "b", "c"}
for i = 1, #items do
  print(i, items[i])
end
```

**要点：**
- 循环变量对循环体来说是**局部**的
- 边界值在循环开始时**只求值一次**
- 步长可以为负数（用于倒计时）

### 泛型 `for` 循环

与迭代器（`pairs`、`ipairs`、自定义）配合使用：

```lua
-- 所有键值对（无序！）
local t = {a = 1, b = 2, c = 3}
for k, v in pairs(t) do
  print(k, v)
end

-- 数组索引（有序 1..n）
local items = {"x", "y", "z"}
for i, v in ipairs(items) do
  print(i, v)
end

-- 从迭代器获取多个值
for key, value in some_iterator() do
  -- ...
end
```

> **警告**：`pairs` 的迭代顺序**不保证**。不要依赖顺序！

### While 循环

当终止取决于某个条件时使用：

```lua
-- 轮询模式
while not done do
  local event = get_next_event()
  process(event)
end

-- 有限次重试
local max_retries = 3
local attempt = 0
while attempt < max_retries do
  local success, err = try_connect()
  if success then break end
  attempt = attempt + 1
  print("Retry " .. attempt .. ": " .. err)
end
```

**要点：**
- 每次迭代**之前**检查条件
- 必须确保条件最终会变为 false
- 使用 `break` 提前退出

### Repeat-Until 循环

当循环体至少需要执行一次时使用：

```lua
-- 输入验证
local input
repeat
  print("Enter a number:")
  input = io.read()
until input:match("^%d+$")

-- 状态机
local state = "start"
repeat
  state = process_state(state)
until state == "done"
```

**要点：**
- 每次迭代**之后**检查条件
- 循环体始终至少执行一次
- 类似 C 语言中的 `do { ... } while()`

---

## Break 和 Return

### Break 语句

提前退出循环：

```lua
-- 带提前退出的搜索
local function find_first(items, predicate)
  for i, item in ipairs(items) do
    if predicate(item) then
      return i, item  -- 立即返回
    end
  end
  return nil  -- 未找到
end

-- 有限次处理
for i = 1, #items do
  if should_stop() then
    break
  end
  process(items[i])
end
```

### Return 模式

多返回值：

```lua
local function divmod(a, b)
  if b == 0 then
    return nil, "division by zero"  -- 错误约定
  end
  return a // b, a % b  -- 多个返回值
end

local quotient, remainder = divmod(10, 3)
local result, err = divmod(10, 0)
```

惯用法：成功, 结果/错误：

```lua
-- 标准 Lua 错误处理模式
local function safe_operation()
  if not preconditions_met() then
    return nil, "preconditions failed"
  end
  
  local result = do_operation()
  if not result then
    return nil, "operation failed"
  end
  
  return result  -- 成功
end

-- 使用方式
local result, err = safe_operation()
if not result then
  print("Error: " .. err)
else
  process(result)
end
```

---

## 自定义迭代器

### 简单迭代器

使用带状态的闭包创建：

```lua
-- 范围迭代器
local function range(start, stop, step)
  step = step or 1
  local i = start - step
  
  return function()
    i = i + step
    if i <= stop then
      return i
    end
  end
end

-- 使用方式
for i in range(1, 5) do
  print(i)  -- 1, 2, 3, 4, 5
end

for i in range(10, 1, -2) do
  print(i)  -- 10, 8, 6, 4, 2
end
```

### 多返回值迭代器

```lua
-- 带索引的枚举
local function enumerate(t)
  local i = 0
  return function()
    i = i + 1
    if i <= #t then
      return i, t[i]
    end
  end
end

-- 使用方式
for i, value in enumerate({"a", "b", "c"}) do
  print(i, value)
end
```

### 有状态迭代器

维护复杂状态的迭代器：

```lua
-- 带行号的文件行读取器
local function lines_with_number(filename)
  local file = assert(io.open(filename, "r"))
  local line_num = 0
  
  return function()
    local line = file:read("line")
    if line then
      line_num = line_num + 1
      return line_num, line:gsub("%s+$", "")  -- 去除尾部空白
    else
      file:close()
      return nil
    end
  end
end

-- 使用方式（如果文件存在）
-- for num, line in lines_with_number("data.txt") do
--   print(num .. ": " .. line)
-- end
```

### 使用协程的迭代器

用于复杂的迭代逻辑：

```lua
local function tree_iterator(node)
  return coroutine.wrap(function()
    local function traverse(n)
      if n.value then
        coroutine.yield(n.value)
      end
      if n.children then
        for _, child in ipairs(n.children) do
          traverse(child)
        end
      end
    end
    traverse(node)
  end)
end

-- 使用方式
local tree = {
  value = "root",
  children = {
    {value = "child1"},
    {value = "child2", children = {{value = "grandchild"}}}
  }
}

for value in tree_iterator(tree) do
  print(value)
end
```

---

## 迭代陷阱

### 迭代期间修改表

**BUG**：在迭代时修改键：

```lua
-- 错误：在 pairs 迭代期间修改表
local t = {a = 1, b = 2, c = 3}
for k, v in pairs(t) do
  if v % 2 == 0 then
    t[k] = nil  -- 危险！可能跳过元素
  end
end

-- 正确：先收集键，再修改
local t = {a = 1, b = 2, c = 3}
local to_remove = {}
for k, v in pairs(t) do
  if v % 2 == 0 then
    table.insert(to_remove, k)
  end
end
for _, k in ipairs(to_remove) do
  t[k] = nil
end
```

### 假设 pairs 的顺序

**BUG**：依赖 `pairs` 的迭代顺序：

```lua
-- 错误：顺序不保证
local config = {host = "localhost", port = 8080, debug = true}
for k, v in pairs(config) do
  print(k .. "=" .. v)  -- 顺序不定！
end

-- 正确：如果需要顺序则排序键
local config = {host = "localhost", port = 8080, debug = true}
local keys = {}
for k in pairs(config) do
  table.insert(keys, k)
end
table.sort(keys)
for _, k in ipairs(keys) do
  print(k .. "=" .. tostring(config[k]))
end
```

### 差一错误

**BUG**：错误的循环边界：

```lua
-- 错误：遗漏最后一个元素
local items = {1, 2, 3, 4, 5}
for i = 1, #items - 1 do
  print(items[i])
end

-- 正确：包含最后一个元素
for i = 1, #items do
  print(items[i])
end

-- 错误：从 0 开始索引（Lua 从 1 开始！）
for i = 0, #items - 1 do
  print(items[i])  -- items[0] 为 nil！
end

-- 正确：从 1 开始索引
for i = 1, #items do
  print(items[i])
end
```

### 无限循环

**BUG**：缺少状态更新：

```lua
-- 错误：没有终止条件
local i = 0
while i < 10 do
  print(i)
  -- 忘记了：i = i + 1
end

-- 正确：更新状态
local i = 0
while i < 10 do
  print(i)
  i = i + 1
end
```

---

## 最佳实践

### 1. 尽早守卫，频繁返回

```lua
-- 避免深层嵌套：
function process_user(user)
  if user ~= nil then
    if user.active then
      if user.has_permission then
        -- 做一些事情
      end
    end
  end
end

-- 使用守卫子句：
function process_user(user)
  if not user then return end
  if not user.active then return end
  if not user.has_permission then return end
  -- 做一些事情
end
```

### 2. 数组优先使用数值 `for`

```lua
-- 清晰高效
for i = 1, #array do
  process(array[i])
end

-- 比以下方式更明确：
local i = 1
while i <= #array do
  process(array[i])
  i = i + 1
end
```

### 3. 顺序访问使用 `ipairs`

```lua
-- 保证顺序，在第一个 nil 处停止
for i, value in ipairs(array) do
  print(i, value)
end
```

### 4. 提取复杂循环逻辑

```lua
-- 避免复杂的循环体：
for i = 1, #items do
  if items[i].active and items[i].value > threshold and not items[i].skip then
    -- 复杂处理
  end
end

-- 提取为函数：
local function should_process(item)
  return item.active and item.value > threshold and not item.skip
end

for i = 1, #items do
  if should_process(items[i]) then
    -- 复杂处理
  end
end
```

### 5. 记录迭代器契约

```lua
--- 遍历数组的分块
-- @param array 输入数组
-- @param chunk_size 每块的元素数量
-- @return 迭代器函数，产出 {start_idx, chunk_table}
local function chunks(array, chunk_size)
  -- 实现
end
```

---

## 版本说明

### Lua 5.2+

- 可用 `goto` 语句处理复杂控制流
- 谨慎使用并清晰记录

```lua
-- Lua 5.2+
for i = 1, n do
  for j = 1, m do
    if matrix[i][j] == target then
      goto found
    end
  end
end
::found::
print("Found at " .. i .. "," .. j)
```

### LuaJIT

- 数值 `for` 循环经过深度优化
- 保持循环体简单以获得最佳 JIT 性能
- 尽量避免在热循环中使用函数调用

---

## 知识检查

<details>
<summary>1. <code>pairs</code> 和 <code>ipairs</code> 有什么区别？</summary>

`pairs(t)` 遍历所有键值对（无序）。`ipairs(t)` 按整数索引 1、2、3... 遍历，直到遇到第一个 nil（有序，适用于数组）。
</details>

<details>
<summary>2. 为什么 <code>for i = 0, #array - 1 do</code> 在 Lua 中是错误的？</summary>

Lua 数组从 1 开始索引。`array[0]` 始终为 `nil`。应使用 `for i = 1, #array do`。
</details>

<details>
<summary>3. <code>repeat ... until</code> 比 <code>while</code> 多保证了什么？</summary>

循环体至少执行一次。条件在之后检查，而不是之前。
</details>

<details>
<summary>4. 如何在迭代期间安全地从表中移除元素？</summary>

先收集要移除的键，然后在第二遍中移除。或者对数组使用逆序迭代。
</details>

<details>
<summary>5. 标准的 Lua 错误处理返回模式是什么？</summary>

成功时：`return result`。出错时：`return nil, "错误信息"`。使用 `if not result then` 检查。
</details>

---

## 常见模式

### 稳定分区

```lua
--- 按谓词分区数组，保持顺序
-- @param array 输入数组
-- @param predicate function(item) -> boolean
-- @return 两个数组：匹配的、不匹配的
local function partition(array, predicate)
  local matching = {}
  local non_matching = {}
  
  for _, item in ipairs(array) do
    if predicate(item) then
      table.insert(matching, item)
    else
      table.insert(non_matching, item)
    end
  end
  
  return matching, non_matching
end

-- 使用方式
local numbers = {1, 2, 3, 4, 5, 6}
local evens, odds = partition(numbers, function(n) return n % 2 == 0 end)
```

### 分块迭代

```lua
--- 按块遍历数组
-- @param array 输入数组
-- @param chunk_size 每块的元素数量
-- @return 迭代器，产出分块表
local function chunks(array, chunk_size)
  local i = 0
  
  return function()
    if i >= #array then return nil end
    
    local chunk = {}
    for j = 1, chunk_size do
      if i + j <= #array then
        table.insert(chunk, array[i + j])
      end
    end
    i = i + chunk_size
    return chunk
  end
end

-- 使用方式
for chunk in chunks({1, 2, 3, 4, 5, 6, 7}, 3) do
  print("Chunk: " .. table.concat(chunk, ", "))
end
-- 输出：{1,2,3}, {4,5,6}, {7}
```

### 带退避的重试

```lua
--- 带重试逻辑执行函数
-- @param fn 要执行的函数
-- @param max_attempts 最大重试次数
-- @param delay 初始延迟（秒）
-- @return 成功标志, 结果或错误
local function retry(fn, max_attempts, delay)
  local last_err
  delay = delay or 1
  
  for attempt = 1, max_attempts do
    local success, result = pcall(fn)
    if success then
      return true, result
    end
    last_err = result
    
    if attempt < max_attempts then
      local wait_time = delay * (2 ^ (attempt - 1))  -- 指数退避
      print("Attempt " .. attempt .. " failed: " .. last_err)
      print("Retrying in " .. wait_time .. "s...")
      os.sleep(wait_time)  -- 需要 LuaSocket 或类似库
    end
  end
  
  return false, last_err
end
```

---

## 关键要点

- **条件判断**：只有 `false` 和 `nil` 为假值；尽早使用守卫
- **数值 `for`**：用于数组和已知迭代次数的场景
- **泛型 `for`**：配合 `pairs`（无序）或 `ipairs`（有序）使用
- **While/Repeat**：用于基于条件的终止
- **自定义迭代器**：使用带状态的闭包或协程处理复杂逻辑
- **陷阱**：不要在 `pairs` 迭代期间修改表；Lua 从 1 开始索引
- **错误处理**：失败时返回 `nil, error`

---

## 练习

### 初级（30–60 分钟）

1. **稳定分区**：实现 `partition(array, predicate)`，将数组分成两个数组并保持顺序。

2. **范围迭代器**：创建 `range(start, stop, step)` 迭代器，支持负步长。

3. **输入验证**：使用 `repeat-until` 编写 `read_number(prompt)` 函数，持续询问直到输入有效。

### 中级（1–2 小时）

4. **分块迭代器**：实现 `chunks(array, size)`，按 `size` 产出数组分块。

5. **安全表过滤**：创建 `filter_in_place(table, predicate)`，在迭代期间安全移除元素。

6. **有限次重试**：实现带指数退避的 `retry(fn, max_attempts, delay)`。

### 高级（2–4 小时）

7. **树遍历**：使用协程创建嵌套树结构的迭代器。

8. **优先队列迭代器**：实现按优先级顺序产出元素的迭代器。

---

## 示例代码

本章可运行的示例：
- `examples/beginner/01-moving-average.lua` — 带累加的循环
- `examples/intermediate/03-coroutine-scheduler.lua` — 基于协程的迭代

---

## 延伸阅读

- [Lua 5.4 参考手册 — 第 3.3 节](https://www.lua.org/manual/5.4/manual.html#3.3)
- [Programming in Lua（第 4 版）— 第 4 章](https://www.lua.org/pil/)
- [下一章：03 — 函数](03-functions.md)
