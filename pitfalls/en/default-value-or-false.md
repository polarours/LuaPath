# Default Value with `or` Fails for False

## The Mistake

Using `value or default` as a default-value pattern fails when `false` is a meaningful value, because `false` is falsey in Lua.

## Reproduction

```lua
local options = {debug = false}
local debug = options.debug or true
print(debug)  -- true! (should be false)

-- The user set debug=false, but the or-pattern overrides it
```

## Why It's Wrong

`or` returns the first truthy value. `false` is falsey, so `or` falls through to the default. This silently overrides intentional `false` values.

Any expression that ends in `or` loses `false`, which is why the usual repair `value ~= nil and value or default` breaks too: its `and` produces `false`, and the trailing `or` replaces that with the default. The value has to be tested with an `if`, not folded into an expression.

## The Fix

The obvious repair does not work either — it still ends in `or`:

```lua
-- Still wrong: `false or true` is true again
local options = {debug = false}
local debug = options.debug ~= nil and options.debug or true
print(debug)  -- true! The and/or idiom loses false as well.
```

The fix is an explicit `nil` check, with no `or` at the end:

```lua
local options = {debug = false}
local debug = options.debug
if debug == nil then
  debug = true
end
print(debug)  -- false (correct!)

-- Or use a helper function
local function with_default(value, default)
  if value ~= nil then return value end
  return default
end

local debug = with_default(options.debug, true)  -- false
```

## Key Takeaway

`or` only checks truthiness, and so does `value ~= nil and value or default`. When `false` is a valid value, use an explicit `nil` check or a helper function.
