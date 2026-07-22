# LuaPath 教程：入门指南

面向初学者的分步 Lua 学习指南。

## 前置条件

- 已安装 Lua 5.4（`lua5.4 --version`）
- 文本编辑器（推荐 VS Code + Lua 扩展）

## 第一步：Hello World

创建你的第一个 Lua 脚本：

```lua
-- hello.lua
print("Hello, Lua!")
print("Version:", _VERSION)
```

运行它：

```bash
lua5.4 hello.lua
```

## 第二步：变量和类型

```lua
-- 变量
local name = "Lua"
local version = 5.4
local is_cool = true
local nothing = nil

-- 类型检查
print(type(name))      -- "string"
print(type(version))   -- "number"
print(type(is_cool))   -- "boolean"
print(type(nothing))   -- "nil"
```

## 第三步：Table

```lua
-- 数组
local fruits = {"apple", "banana", "cherry"}
print(fruits[1])  -- "apple"（从 1 开始索引！）

-- 哈希映射
local person = {
  name = "Alice",
  age = 30,
  city = "北京"
}
print(person.name)  -- "Alice"

-- 混合
local mixed = {1, 2, 3, key = "value"}
```

## 第四步：函数

```lua
-- 函数声明
local function greet(name)
  return "Hello, " .. name .. "!"
end

print(greet("World"))

-- 匿名函数
local add = function(a, b)
  return a + b
end

print(add(3, 4))  -- 7
```

## 第五步：控制流

```lua
-- If-else
local score = 85
if score >= 90 then
  print("A")
elseif score >= 80 then
  print("B")
else
  print("C")
end

-- For 循环
for i = 1, 5 do
  print(i)
end

-- While 循环
local count = 0
while count < 3 do
  count = count + 1
  print(count)
end
```

## 第六步：元表

```lua
-- 简单 OOP
local Dog = {}
Dog.__index = Dog

function Dog.new(name)
  return setmetatable({name = name}, Dog)
end

function Dog:speak()
  return self.name .. " says woof!"
end

local my_dog = Dog.new("Buddy")
print(my_dog:speak())  -- "Buddy says woof!"
```

## 第七步：错误处理

```lua
-- 安全除法
local function safe_divide(a, b)
  if b == 0 then
    return nil, "division by zero"
  end
  return a / b
end

local result, err = safe_divide(10, 0)
if not result then
  print("Error:", err)
end
```

## 下一步

1. 按顺序完成[章节](../zh/00-roadmap.md)
2. 完成[练习](../zh/01-basics.md#练习)
3. 从[路线图](../lua-mastery-roadmap/00-overview.md)构建项目
4. 查看[陷阱](../pitfalls/)避免常见错误
