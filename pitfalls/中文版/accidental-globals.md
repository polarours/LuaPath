# 忘记 local 关键字，意外全局污染

## 错误

在 Lua 中，忘记写 `local` 就会创建全局变量：它会污染全局命名空间，并引发难以察觉的 bug，在循环和函数内部尤其容易造成隐蔽的命名冲突。

## 复现代码

```lua
function compute()
  result = 42  -- BUG：创建了全局变量 `result`
  return result
end

print(result)  -- 42（全局污染！）
```

## 为什么这是个问题

- 函数内部未声明 `local` 的赋值会写入 `_G`，即全局表。
- 同名变量在程序的任何地方都可能被意外覆盖或读取。
- 调试时很难追踪"我的局部变量为什么被改了"，根源往往是某个远端函数的全局泄漏。
- 模块化设计被破坏：模块的内部状态泄露到全局作用域。

## 修复方法

始终使用 `local` 声明变量：

```lua
function compute()
  local result = 42  -- 显式的 local
  return result
end

print(result)  -- nil（正确：没有污染）
```

> **最佳实践：** 在脚本或模块顶部添加 `local` 前缀的变量声明，养成"默认 local"的编码习惯。可以配合 `luacheck` 静态分析工具自动检测未声明的全局变量。

### 检测

使用严格模式来捕获意外写入的全局变量：

```lua
setmetatable(_G, {
  __newindex = function(_, name)
    error("Attempt to write to global: " .. name, 2)
  end
})
```

## 核心要点

除非确实需要全局变量，否则始终使用 `local`。用 `luac -l` 审计代码中未声明的全局变量。
