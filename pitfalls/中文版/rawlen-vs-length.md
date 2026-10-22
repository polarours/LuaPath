# Rawlen 与 # 运算符

## 错误

假设 `#t` 与 `rawlen(t)` 总是返回同一个值，并且假设两者都存在。当元表定义了 `__len` 时它们并不相同——
而在 Lua 5.1 和 LuaJIT 上，`rawlen` 压根就不存在。

## 复现

```lua
local t = {1, 2, 3}
setmetatable(t, {__len = function() return 99 end})

print(#t)        -- 在 Lua 5.2 及之后是 99；但在 Lua 5.1 和 LuaJIT 上是 3，
                 -- 因为那里 __len 只对 userdata 生效
print(rawlen(t)) -- 在 Lua 5.2 及之后是 3；在 Lua 5.1 和 LuaJIT 上会直接报错
                 -- "attempt to call a nil value (global 'rawlen')"
```

## 为什么是错的

这里其实混了两件事，而且它们是在不同版本里加入的：

- 当元表带有 `__len` 时，`#t` 会调用这个元方法——但这从 Lua 5.2 才开始。
  在 Lua 5.1 和 LuaJIT 上，`__len` 只对用户数据生效，所以 `#t` 返回的是表格的原始长度
- `rawlen(t)` 返回未经元方法分派的表格原始长度。它同样是 Lua 5.2 才加入的，
  因此在 Lua 5.1 和 LuaJIT 上这个调用会直接失败

一个同时支持 Lua 5.1、5.3、5.4 和 LuaJIT 的项目，同一行代码会表现出两种不同的行为，
而旧的那个版本里连这个函数都没有。

## 修复

明确自己需要哪一个，并且不要超出当前运行时所提供的能力：

```lua
local t = {1, 2, 3}
setmetatable(t, {__len = function() return 99 end})

-- 表格的原始长度，在所有受支持的版本上都能用。
-- 对连续序列来说它等同于 #t；对带空洞的表格来说它是键的数量，
-- 那是另一个问题。
local function raw_length(t)
  if rawlen then
    return rawlen(t)
  end
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

-- 按当前运行时的规则得到的长度，可能走元方法，也可能不走。
local len = #t
```

当元表定义了 `__len` 时，要有意识地决定你要哪一个——并且写进文档，
因为答案会随 Lua 版本变化。

## 核心要点

从 Lua 5.2 起 `#t` 才会走元方法；`rawlen(t)` 不走元方法，但它本身也是 Lua 5.2 才有的。
在 Lua 5.1 和 LuaJIT 上，表格既没有 `__len` 分派，也没有 `rawlen`，
所以要自己写这个回退实现。
