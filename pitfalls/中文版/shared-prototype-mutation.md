# 所有实例共享同一个原型 table，变异 bug

## 错误描述

在 Lua 中，当你基于一个 table 用 `{}` 创建"新实例"时，实际上只是创建了一个指向同一个原型的引用。对实例的修改会直接影响原型和其他所有共享该原型的对象。

## 复现代码

```lua
-- 定义一个"类"
local Player = { hp = 100, name = "默认" }

function Player:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- 创建两个"实例"
local p1 = Player:new({ name = "英雄" })
local p2 = Player:new({ name = "战士" })

print(p1.hp)  -- 100

-- 问题：直接修改 p1 的 hp
p1.hp = 50
print(p2.hp)  -- 50 ← 意外！p2 的 hp 也被改了

-- 更隐蔽的变异：修改共享的 table 字段
local Enemy = { buffs = {} }
local e1 = Enemy:new({ name = "哥布林" })
local e2 = Enemy:new({ name = "兽人" })

table.insert(e1.buffs, "中毒")
print(#e2.buffs)  -- 1 ← e2 也拿到了"中毒"！
```

## 为什么是错的

Lua 的 `setmetatable(o, self)` + `self.__index = self` 只是建立了原型链。当 `o` 自身没有某个字段时，Lua 会沿原型链向上查找。但 `table` 类型的字段（如 `buffs = {}`）在原型链上是**共享引用**——对它的任何修改都会影响所有实例。

简单类型（number、string）的直接赋值会在实例上创建新字段，覆盖原型值，所以"看起来没问题"。但 table 类型字段的**内部变异**（如 `table.insert`）不会创建新引用，直接修改了原型上的那个 table。

## 修复方法

在构造函数中为每个实例**深拷贝**共享的 table 字段：

```lua
function Player:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- 为每个实例创建独立的共享数据副本
    o.buffs = {}
    return o
end

local Enemy = { buffs = {} }

function Enemy:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    -- 关键：深拷贝 table 字段
    o.buffs = {}
    return o
end

local e1 = Enemy:new({ name = "哥布林" })
local e2 = Enemy:new({ name = "兽人" })

table.insert(e1.buffs, "中毒")
print(#e2.buffs)  -- 0 ← 正确！各自独立
```

## 要点总结

- 简单类型字段赋值会遮蔽原型值，不会变异原型
- table 类型字段的内部操作（`table.insert`、直接赋值 key）会污染所有共享实例
- 养成习惯：构造函数中为每个实例深拷贝 table 字段
