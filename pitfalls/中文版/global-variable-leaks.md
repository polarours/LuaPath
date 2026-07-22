# 全局变量泄漏

## 错误

忘记使用 `local` 会创建全局变量，污染命名空间。

```lua
-- 这会创建全局变量！
function helper()
  result = 42  -- 全局！
end

-- 检查全局变量
print(result)  -- 42（泄漏了！）
```

## 为什么失败

全局变量存储在 `_G` 中，可从任何地方访问。意外的全局变量会导致命名冲突和难以发现的 bug。

## 修复方法

```lua
-- 始终使用 local
function helper()
  local result = 42  -- 局部作用域
  return result
end

-- 或使用严格模式
local function strict()
  setmetatable(_G, {
    __newindex = function(_, name)
      error("attempt to create global '" .. name .. "'", 2)
    end
  })
end

-- 启用严格模式
strict()

-- 现在这会报错：
-- unknown_global = "test"  -- Error!
```

## 相关概念

- [01-basics.md](../zh/01-basics.md) — 变量与作用域
- [06-modules.md](../zh/06-modules.md) — 模块系统
