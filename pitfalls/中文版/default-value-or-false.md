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

任何以 `or` 结尾的表达式都会丢掉 `false`，这也是常见改法 `value ~= nil and value or default` 同样失效的原因：
它的 `and` 部分算出 `false`，然后被结尾的 `or` 换成了默认值。要判断这个值，只能用 `if`，不能把它折进表达式里。

## 修复

看上去顺理成章的改法同样不行——它还是以 `or` 结尾：

```lua
-- 仍然是错的：`false or true` 又变回 true
local options = {debug = false}
local debug = options.debug ~= nil and options.debug or true
print(debug)  -- true！and/or 写法同样会丢掉 false。
```

正确的做法是显式的 `nil` 检查，结尾不要有 `or`：

```lua
local options = {debug = false}
local debug = options.debug
if debug == nil then
  debug = true
end
print(debug)  -- false（正确！）

-- 或使用辅助函数
local function with_default(value, default)
  if value ~= nil then return value end
  return default
end

local debug = with_default(options.debug, true)  -- false
```

## 核心要点

`or` 只检查真值，`value ~= nil and value or default` 也一样。当 `false` 是有效值时，使用显式的 `nil` 检查或辅助函数。
