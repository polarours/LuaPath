# `or` 默认值对 false 失效

## 错误

使用 `value or default` 作为默认值模式，当 `false` 是有效值时会失败，因为 `false` 在 Lua 中是假值。

## 复现

```lua
local options = {debug = false}
local debug = options.debug or true
print(debug)  -- true！（应该是 false）

-- 用户设置了 debug=false，但 or 模式覆盖了它
```

## 为什么是错的

`or` 返回第一个真值。`false` 是假值，所以 `or` 会使用默认值。这会静默覆盖有意设置的 `false` 值。

## 修复

```lua
-- 显式 nil 检查保留 false
local options = {debug = false}
local debug = options.debug ~= nil and options.debug or true
print(debug)  -- false（正确！）

-- 或使用辅助函数
local function with_default(value, default)
  if value ~= nil then return value end
  return default
end

local debug = with_default(options.debug, true)  -- false
```

## 核心要点

`or` 只检查真值。当 `false` 是有效值时，使用显式 `nil` 检查或辅助函数。
