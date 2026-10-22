# Shared Prototype Mutation

All instances created from the same constructor share one prototype table — mutating it silently affects every instance.

## The Mistake

```lua
local Dog = {}
Dog.__index = Dog
Dog.bones = {} -- shared prototype table

function Dog.new(name)
  local self = setmetatable({}, Dog)
  self.name = name
  return self
end

local rex = Dog.new("Rex")
local fido = Dog.new("Fido")

rex.bones[1] = "steak"

print(fido.bones[1]) -- "steak" — surprise!
```

## Reproduction

Every instance built from the same constructor shares the prototype's tables:

```lua
-- define a "class"
local Player = { hp = 100, name = "默认" }

function Player:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- create two "instances"
local p1 = Player:new({ name = "英雄" })
local p2 = Player:new({ name = "战士" })

print(p1.hp)  -- 100

-- assigning a key is per-instance: p2 is unaffected
p1.hp = 50
print(p1.hp)  -- 50
print(p2.hp)  -- 100 — p2 still reads the prototype's value

-- the shared part is a table stored *on* the prototype
-- (Enemy reuses Player's constructor)
local Enemy = setmetatable({ buffs = {} }, { __index = Player })
local e1 = Enemy:new({ name = "哥布林" })
local e2 = Enemy:new({ name = "兽人" })

table.insert(e1.buffs, "中毒")
print(#e2.buffs)  -- 1 — e2 also got the "poisoned" buff!
```

## Why It's Wrong

`Dog.bones` is a table assigned once on the prototype. Every instance inherits it through the metatable chain. When `rex.bones` resolves, Lua finds the shared table on `Dog` and writes into it directly. There is no per-instance copy.

Two different things are going on, and only one of them is shared. Assigning a key (`p1.hp = 50`) writes the instance's own key, so the other instance is unaffected. Reading a key that the instance does not have (`p2.hp`) walks the metatable chain and finds the prototype's value.

What *is* shared is a table stored on the prototype: `e1.buffs` does not exist on `e1`, so the lookup finds `Enemy.buffs` — one table that every instance reaches — and `table.insert` writes into that shared table.

## The Fix

Clone the table inside the constructor:

```lua
local Dog = {}
Dog.__index = Dog
Dog.bones = {} -- the shared prototype table

function Dog.new(name)
  local self = setmetatable({}, Dog)
  self.name = name
  self.bones = {} -- per-instance copy
  return self
end

local rex = Dog.new("Rex")
local fido = Dog.new("Fido")
rex.bones[1] = "steak"
print(fido.bones[1])  -- nil -- fido has its own bones
```

For nested tables, clone recursively or initialize lazily:

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

## Key Takeaway

Primitive fields (strings, numbers, booleans) are safe to leave on the prototype — assignment creates a local shadow. Tables and other reference types must be cloned in the constructor to avoid cross-instance mutation.
