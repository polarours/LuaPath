# 所有实例共享同一个原型 table，变异 bug

## 错误描述

在 Lua 中，当你基于一个 table 用 `{}` 创建"新实例"时，实际上只是创建了一个指向同一个原型的引用。对实例的修改会直接影响原型和其他所有共享该原型的对象。

```lua
local Dog = {}
Dog.__index = Dog
Dog.bones = {} -- 共享的原型 table

function Dog.new(name)
  local self = setmetatable({}, Dog)
  self.name = name
  return self
end

local rex = Dog.new("Rex")
local fido = Dog.new("Fido")

rex.bones[1] = "steak"

print(fido.bones[1]) -- "steak"：意外！
```

## 复现代码

每个用同一个构造函数创建出来的实例，都会共享原型上的那些 table：

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

-- 赋值是按实例来的：p2 不受影响
p1.hp = 50
print(p1.hp)  -- 50
print(p2.hp)  -- 100 —— p2 读到的仍然是原型上的值

-- 真正共享的是挂在原型上的 table
-- （Enemy 复用 Player 的构造函数）
local Enemy = setmetatable({ buffs = {} }, { __index = Player })
local e1 = Enemy:new({ name = "哥布林" })
local e2 = Enemy:new({ name = "兽人" })

table.insert(e1.buffs, "中毒")
print(#e2.buffs)  -- 1 ← e2 也拿到了"中毒"！
```

## 为什么是错的

Lua 的 `setmetatable(o, self)` + `self.__index = self` 只是建立了原型链。当 `o` 自身没有某个字段时，Lua 会沿原型链向上查找。但 `table` 类型的字段（如 `buffs = {}`）在原型链上是**共享引用**——对它的任何修改都会影响所有实例。

`Dog.bones` 就是只在原型上赋值一次的 table。每个实例都通过元表链继承它。当 `rex.bones` 被解析时，Lua 在 `Dog` 上找到那个共享的 table，然后直接写进去。没有任何按实例复制的过程。

简单类型（number、string）的直接赋值会在实例上创建新字段，覆盖原型值，所以"看起来没问题"。但 table 类型字段的**内部变异**（如 `table.insert`）不会创建新引用，直接修改了原型上的那个 table。

这里要分清两件事，只有一件是共享的。赋值（`p1.hp = 50`）写的是实例自己的 key，所以另一个实例不受影响；而读取实例上没有的 key（`p2.hp`）会沿元表链找到原型上的值。

真正共享的是挂在原型上的 table：`e1.buffs` 并不在 `e1` 上，查找会找到 `Enemy.buffs`——那是每个实例都会访问到的同一个 table，`table.insert` 写进去的就是这个共享对象。

## 修复方法

在构造函数中克隆这个 table，让每个实例持有一份自己的副本：

```lua
local Dog = {}
Dog.__index = Dog
Dog.bones = {} -- 共享的原型 table

function Dog.new(name)
  local self = setmetatable({}, Dog)
  self.name = name
  self.bones = {} -- 每个实例一份副本
  return self
end

local rex = Dog.new("Rex")
local fido = Dog.new("Fido")
rex.bones[1] = "steak"
print(fido.bones[1])  -- nil —— fido 有自己的 bones
```

对于嵌套的 table，递归克隆，或者延迟初始化：

```lua
local Dog = {}
Dog.__index = Dog
Dog.bones = {}
Dog.tricks = {}

function Dog.new(name)
  local self = setmetatable({}, Dog)
  self.name = name
  self.bones = {}
  self.tricks  = {}
  return self
end
```

## 要点总结

- 简单类型字段赋值会遮蔽原型值，不会变异原型
- table 类型字段的内部操作（`table.insert`、直接赋值 key）会污染所有共享实例
- 养成习惯：构造函数中为每个实例克隆 table 字段，避免跨实例的交叉变异
