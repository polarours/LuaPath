# LuaPath Tutorial: Getting Started

A step-by-step guide for beginners to learn Lua with LuaPath.

## Prerequisites

- Lua 5.4 installed (`lua5.4 --version`)
- A text editor (VS Code recommended with Lua extension)

## Step 1: Hello World

Create your first Lua script:

```lua
-- hello.lua
print("Hello, Lua!")
print("Version:", _VERSION)
```

Run it:

```bash
lua5.4 hello.lua
```

## Step 2: Variables and Types

```lua
-- Variables
local name = "Lua"
local version = 5.4
local is_cool = true
local nothing = nil

-- Type checking
print(type(name))      -- "string"
print(type(version))   -- "number"
print(type(is_cool))   -- "boolean"
print(type(nothing))   -- "nil"
```

## Step 3: Tables

```lua
-- Array
local fruits = {"apple", "banana", "cherry"}
print(fruits[1])  -- "apple" (1-indexed!)

-- Hash map
local person = {
  name = "Alice",
  age = 30,
  city = "Beijing"
}
print(person.name)  -- "Alice"

-- Mixed
local mixed = {1, 2, 3, key = "value"}
```

## Step 4: Functions

```lua
-- Function declaration
local function greet(name)
  return "Hello, " .. name .. "!"
end

print(greet("World"))

-- Anonymous function
local add = function(a, b)
  return a + b
end

print(add(3, 4))  -- 7
```

## Step 5: Control Flow

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

-- For loop
for i = 1, 5 do
  print(i)
end

-- While loop
local count = 0
while count < 3 do
  count = count + 1
  print(count)
end
```

## Step 6: Metatables

```lua
-- Simple OOP
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

## Step 7: Error Handling

```lua
-- Safe division
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

## Next Steps

1. Complete the [chapters](../en/00-roadmap.md) in order
2. Work through the [exercises](../en/01-basics.md#exercises)
3. Build projects from the [roadmap](../lua-mastery-roadmap/00-overview.md)
4. Check the [pitfalls](../pitfalls/) to avoid common mistakes
