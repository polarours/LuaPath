# Truthiness Pitfalls

## The Mistake

Assuming `0`, empty string `""`, or empty table `{}` are falsey. In Lua, only `false` and `nil` are falsey.

## Reproduction

```lua
local count = 0
if count then
  print("has count")  -- Prints! (0 is truthy)
end

local name = ""
if name then
  print("has name")  -- Prints! ("" is truthy)
end

local t = {}
if t then
  print("has table")  -- Prints! ({} is truthy)
end
```

## Why It's Wrong

Many languages (JavaScript, Python) treat `0` and `""` as falsey. Lua doesn't. This leads to bugs when porting logic from other languages.

## The Fix

Use explicit nil checks:

```lua
local count = 0
if count ~= nil then  -- Correct: check for nil specifically
  print("has count")
end

-- Or use the or-pattern carefully
local value = input or default  -- Fails when input is false!
local value = input ~= nil and input or default  -- Correct
```

## Key Takeaway

Only `false` and `nil` are falsey. `0`, `""`, `{}`, and functions are all truthy.
