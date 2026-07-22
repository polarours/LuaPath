# 共享元表变异

## 错误

修改多个对象共享的元表，影响所有对象。

```lua
local MyClass = {}
MyClass.__index = MyClass

local obj1 = setmetatable({name = "Alice"}, MyClass)
local obj2 = setmetatable({name = "Bob"}, MyClass)

-- 这会修改共享的元表！
MyClass.greet = function(self)
  return "Hello, " .. self.name .. "!"
end

-- 两个对象现在都有 greet 方法
print(obj1:greet())  -- 有效，但可能不是预期的
```

## 为什么失败

共享同一个元表的所有对象都能看到对它的修改。当你只想修改一个对象时，这可能导致意外行为。

## 修复方法

```lua
-- 方法 1：在创建实例之前设置方法
local MyClass = {}
MyClass.__index = MyClass
MyClass.greet = function(self) return "Hello, " .. self.name end

-- 方法 2：使用实例特定的 table 存储可变状态
local obj = setmetatable({}, MyClass)
obj.custom_data = {}  -- 实例特定的数据
```

## 相关概念

- [05-metatables.md](../zh/05-metatables.md) — 元表与元方法
- [13-patterns.md](../zh/13-patterns.md) — 设计模式
