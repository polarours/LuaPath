# 初级练习：参考解答

初级练习的参考实现与说明。

---

## 练习 1：字符串分割

### 任务

不依赖外部库实现 `split(s, sep)`。

### 参考实现

```lua
--- 按分隔符拆分字符串
-- @param s 输入字符串
-- @param sep 分隔模式
-- @return 子串数组
local function split(s, sep)
  if type(s) ~= "string" then
    error("bad argument #1 to 'split' (string expected)", 2)
  end

  sep = sep or "%s"

  local result = {}
  local start = 1

  while start <= #s do
    local sep_start, sep_end = s:find(sep, start)

    if not sep_start then
      table.insert(result, s:sub(start))
      break
    elseif sep_start > start then
      table.insert(result, s:sub(start, sep_start - 1))
    end

    start = sep_end + 1
  end

  return result
end

local parts = split("a,b,c", ",")
assert(#parts == 3)
assert(parts[1] == "a")
assert(parts[2] == "b")
assert(parts[3] == "c")
print("✓ split tests passed")
```

### 要点

1. 先做输入校验，避免把非字符串悄悄吞掉。
2. `string.find` 可以直接复用 Lua 的模式能力。
3. 连续分隔符、没有分隔符、空字符串都要单独想清楚。

### 常见错误

```lua
local function split_wrong(s, sep)
  local result = {}
  for part in s:gmatch("[^" .. sep .. "]+") do
    table.insert(result, part)
  end
  return result
end

local function split_off_by_one(s, sep)
  local result = {}
  local start = 1
  local sep_start, sep_end = s:find(sep, start)

  while sep_start do
    table.insert(result, s:sub(start, sep_start))
    start = sep_end + 1
    sep_start, sep_end = s:find(sep, start)
  end

  return result
end
```

---

## 练习 2：词频统计

### 任务

用 table 实现 `count_words(text)`。

### 参考实现

```lua
--- 统计文本中的词频
-- @param text 输入文本
-- @return 单词到次数的映射
local function count_words(text)
  local counts = {}

  for word in text:lower():gmatch("%w+") do
    counts[word] = (counts[word] or 0) + 1
  end

  return counts
end

--- 按词频降序打印
-- @param counts 词频表
local function print_frequencies(counts)
  local entries = {}
  for word, count in pairs(counts) do
    table.insert(entries, { word = word, count = count })
  end

  table.sort(entries, function(a, b)
    return a.count > b.count
  end)

  for _, entry in ipairs(entries) do
    print(string.format("%s: %d", entry.word, entry.count))
  end
end

local text = "Lua is great. Lua is fast. Lua is simple."
local freq = count_words(text)
print_frequencies(freq)
```

### 要点

1. `%w+` 是最直接的单词切分方式。
2. `(counts[word] or 0) + 1` 是 Lua 里很常见的计数写法。
3. 自定义排序前，先把 map 结构转成数组。

### 变体

```lua
local function count_words_case_sensitive(text)
  local counts = {}
  for word in text:gmatch("%w+") do
    counts[word] = (counts[word] or 0) + 1
  end
  return counts
end

local function count_words_filtered(text, stop_words)
  local counts = {}
  stop_words = stop_words or { the = true, a = true, an = true, is = true, are = true }

  for word in text:lower():gmatch("%w+") do
    if not stop_words[word] then
      counts[word] = (counts[word] or 0) + 1
    end
  end

  return counts
end
```

---

## 练习 3：Clamp 与 Lerp

### 任务

实现 `clamp` 和 `lerp`，并补齐边界测试。

### 参考实现

```lua
local function clamp(value, min, max)
  if value < min then return min end
  if value > max then return max end
  return value
end

local function clamp_alt(value, min, max)
  return math.max(min, math.min(value, max))
end

local function lerp(a, b, t)
  t = clamp(t, 0, 1)
  return a + (b - a) * t
end

local function inverse_lerp(a, b, value)
  if a == b then return 0 end
  return (value - a) / (b - a)
end

local function test_clamp()
  assert(clamp(5, 0, 10) == 5, "within bounds")
  assert(clamp(-5, 0, 10) == 0, "below min")
  assert(clamp(15, 0, 10) == 10, "above max")
  assert(clamp(0, 0, 10) == 0, "at min")
  assert(clamp(10, 0, 10) == 10, "at max")
  assert(clamp(5, 5, 5) == 5, "min == max")
  print("✓ clamp tests passed")
end

local function test_lerp()
  assert(lerp(0, 100, 0) == 0, "t=0")
  assert(lerp(0, 100, 1) == 100, "t=1")
  assert(lerp(0, 100, 0.5) == 50, "t=0.5")
  assert(lerp(0, 100, 1.5) == 100, "t clamped above")
  assert(lerp(0, 100, -0.5) == 0, "t clamped below")
  assert(lerp(10, 20, 0.5) == 15, "non-zero start")
  print("✓ lerp tests passed")
end

local function test_inverse_lerp()
  assert(inverse_lerp(0, 100, 50) == 0.5, "middle")
  assert(inverse_lerp(0, 100, 0) == 0, "start")
  assert(inverse_lerp(0, 100, 100) == 1, "end")
  assert(inverse_lerp(0, 100, 150) == 1.5, "beyond end")
  assert(inverse_lerp(10, 10, 5) == 0, "same endpoints")
  print("✓ inverse_lerp tests passed")
end

test_clamp()
test_lerp()
test_inverse_lerp()
```

### 要点

1. 测试不要只测正常路径，边界条件才最容易露问题。
2. `lerp` 通常应该把 `t` 限制在 `[0, 1]`。
3. `inverse_lerp` 是否截断要看用途，这里保留原始比例更通用。

---

## 练习 4：隐式全局变量 Bug

### 任务

修复由于意外写入全局导致的 bug。

### 问题代码

```lua
function sum_array(arr)
  local sum = 0
  for i = 1, #arr do
    sum = sum + arr[i]
  end
  return sum
end

function find_max(arr)
  local max = arr[1]
  for i = 2, #arr do
    if arr[i] > max then
      max = arr[i]
    end
  end
  return max
end
```

### 修复方式

```lua
function sum_array(arr)
  local sum = 0
  for i = 1, #arr do
    sum = sum + arr[i]
  end
  return sum
end

function find_max(arr)
  local max = arr[1]
  for i = 2, #arr do
    if arr[i] > max then
      max = arr[i]
    end
  end
  return max
end

function sum_array_explicit(arr)
  local sum = 0
  for i = 1, #arr do
    sum = sum + arr[i]
  end
  return sum
end
```

### 检测方式

```lua
setmetatable(_G, {
  __newindex = function(_, name)
    error("Attempt to write to global: " .. name, 2)
  end,
  __index = function(_, name)
    error("Attempt to read global: " .. name, 2)
  end,
})
```

---

## 练习 5：Off-by-One 循环错误

### 任务

修复列表渲染里的 off-by-one 问题。

### 问题代码

```lua
function render_list(items)
  for i = 1, #items - 1 do
    print(i .. ". " .. items[i])
  end
end

function render_list_wrong_start(items)
  for i = 0, #items do
    print(i .. ". " .. items[i])
  end
end
```

### 修复方式

```lua
function render_list(items)
  for i = 1, #items do
    print(i .. ". " .. items[i])
  end
end

function render_list_safe(items)
  for i, item in ipairs(items) do
    print(i .. ". " .. item)
  end
end
```

### 要点

1. Lua 数组是从 1 开始，不是从 0 开始。
2. `for i = 1, #items` 两端都是包含的。
3. `ipairs` 通常比手写索引更稳。

---

## 练习 6：带空洞 table 的长度问题

### 任务

修复对带空洞 table 使用 `#t` 的错误假设。

### 问题代码

```lua
local t = { 1, 2, nil, 4, 5 }
print(#t)

local items = { 1, 2, 3, 4, 5 }
items[3] = nil
print(#items)
```

### 修复方式

```lua
local function count_elements(t)
  local count = 0
  for _ in ipairs(t) do
    count = count + 1
  end
  return count
end

local items = { 1, 2, 3, 4, 5 }
table.remove(items, 3)
print(#items)

local t = { 1, 2, 4, 5 }
print(#t)

local function create_list()
  local self = {
    _data = {},
    _length = 0,
  }

  function self:push(value)
    self._length = self._length + 1
    self._data[self._length] = value
  end

  function self:length()
    return self._length
  end

  return self
end

local list = create_list()
list:push(1)
list:push(2)
list:push(3)
print(list:length())
```

### 要点

1. `#t` 只对连续序列有明确定义。
2. 删除数组元素优先用 `table.remove`。
3. 如果业务允许空洞，就显式维护长度。

---

## 设计题参考答案

### 1. Lua table 中如何表达可空字段

```lua
local user = {
  name = "Alice",
  email = nil,
  _has_email = false,
}

local NONE = {}
local user_with_sentinel = {
  name = "Alice",
  email = NONE,
}

if user_with_sentinel.email == NONE then
  print("no email")
end

local user_with_fields = {
  name = "Alice",
  data = {},
  _fields = {
    email = true,
    phone = false,
  },
}
```

### 2. 更易测试的模块 API 风格

```lua
local M = {}

function M.process(data, config)
  return result
end

local exported = M

-- 测试用法：
local M = exported
local result = M.process(test_data, test_config)
assert(result == expected)

local state = {}
function M.process_with_state(data)
  state.last = data
  return result
end
```

### 3. 错误边界应该放在哪里

```lua
local success, err = pcall(function()
  main()
end)
if not success then
  print("Error: " .. err)
  os.exit(1)
end

function M_process(data)
  if not data then
    return nil, "data is required"
  end
end

local result, process_err = M_process(data)
if not result then
  log_error(process_err)
  return nil, process_err
end

local service_ok, service_err = pcall(service.run)
if not service_ok then
  show_user_friendly_error(service_err)
end
```

---

## 如何测试你的实现

```lua
local function run_tests()
  local passed = 0
  local failed = 0

  local function test(name, fn)
    local success, err = pcall(fn)
    if success then
      passed = passed + 1
      print("✓ " .. name)
    else
      failed = failed + 1
      print("✗ " .. name .. ": " .. err)
    end
  end

  test("split basic", function()
    local parts = split("a,b,c", ",")
    assert(#parts == 3)
  end)

  test("count_words basic", function()
    local freq = count_words("a a b")
    assert(freq.a == 2)
    assert(freq.b == 1)
  end)

  print(string.format("\nResults: %d passed, %d failed", passed, failed))
  return failed == 0
end

run_tests()
```

---

## 下一步

完成这些练习后，建议继续做这几件事：

1. 回看你的实现与参考解法的差异。
2. 补更多边界条件和失败路径测试。
3. 继续进入 [中级练习](intermediate.md)。
