# 忘记 local 关键字，意外全局污染

在 Lua 中，不加 `local` 声明的变量会自动成为全局变量。这在循环、函数内部极易造成隐蔽的命名冲突，污染全局环境。

## 复现代码

```lua
function process()
    -- 本意是局部计数器，但漏写了 local
    count = 0
    for i = 1, 10 do
        count = count + 1
    end
    return count
end

print(process())  -- 10

-- 外部代码无意间读到了被污染的全局 count
print(count)      -- 10（不应该存在）
```

## 为什么这是个问题

- 函数内部未声明 `local` 的赋值会写入 `_G`，即全局表。
- 同名变量在程序的任何地方都可能被意外覆盖或读取。
- 调试时很难追踪"我的局部变量为什么被改了"，根源往往是某个远端函数的全局泄漏。
- 模块化设计被破坏：模块的内部状态泄露到全局作用域。

## 修复方法

始终使用 `local` 声明变量：

```lua
function process()
    local count = 0
    for i = 1, 10 do
        count = count + 1
    end
    return count
end

print(process())  -- 10
print(count)      -- nil（全局没有被污染）
```

> **最佳实践：** 在脚本或模块顶部添加 `local` 前缀的变量声明，养成"默认 local"的编码习惯。可以配合 `luacheck` 静态分析工具自动检测未声明的全局变量。
