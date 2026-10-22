# 第 41.2 阶段：SIMD 风格模式

**级别**: 高级  
**描述**: 使用模仿 SIMD（单指令多数据）行为的迭代模式，在 Lua 表上实现向量化操作。重点是可以由 CPU 向量单元并行化的逐元素运算。

## 前置知识

- 第 03 章（函数）
- 第 12 章（性能）

## 项目结构

```
41-performance/simd-patterns/
├── README.md               # 本文件
├── README.zh-CN.md         # 中文版
├── vector_ops.lua          -- 向量操作库
└── tests/
    └── correctness_test.lua  -- Verify vector operations are correct
```

## 实现

### 向量操作 (`vector_ops.lua`)

提供基于 Lua 表的向量操作，可与纯循环和优化版本作对比：

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

### 正确性测试

编写测试用例，验证 Vector 操作在边缘情况（零向量、负值、大数值）下产生正确结果。

## 预估时间

8–12 小时
