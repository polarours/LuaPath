# Stage 42.2: SIMD-style Patterns — Chinese Version

**级别**: 高级  
**描述**: 使用模仿 SIMD（单指令多数据）行为的迭代模式在 Lua 表格上实现向量化操作。重点是可以由 CPU 向量单元并行化的元素级运算。

## 前置知识

- Stage 03 — Functions
- Stage 12 — Performance

## 项目结构

```
42-performance/simd-patterns/
├── README.md               # 本文件
├── README.zh-CN.md         # 中文版
├── vector_ops.lua          -- 向量操作库
├── dot_product.lua         -- 点积示例
├── vector_add.lua          -- 向量加法示例
└── tests/
    └── correctness_test.lua  -- 验证向量操作的正确性
```

## 实现细节

### 向量操作 (`vector_ops.lua`)

提供 Lua 表格的向量操作，可以与纯循环或优化版本进行比较：

```lua
local Vector = {}

function Vector.add(a, b)
  local res = {}
  for i = 1, #a do
    res[i] = a[i] + b[i]
  end
  return res
end

function Vector.dot(a, b)
  local sum = 0
  for i = 1, #a do
    sum = sum + a[i] * b[i]
  end
  return sum
end

function Vector.scale(v, s)
  local res = {}
  for i = 1, #v do
    res[i] = v[i] * s
  end
  return res
end
```

## 测试验证

创建测试用例验证向量操作对边缘情况（零向量、负值、大数值）产生正确结果。

## 预估时间

8–12 小时
