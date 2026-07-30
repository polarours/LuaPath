# Stage 42.2: SIMD-style Patterns

**Level**: Advanced  
**Description**: Implement vectorized operations on Lua tables using iteration patterns that mimic SIMD (Single Instruction, Multiple Data) behavior. Focus on element-wise operations that can be parallelized by the CPU's vector units.

## Prerequisites

- Stage 03 — Functions
- Stage 12 — Performance

## Project Structure

```
42-performance/simd-patterns/
├── README.md               # This file
├── README.zh-CN.md         # Chinese version
├── vector_ops.lua          -- Vector operations library
├── dot_product.lua         -- Dot product example
├── vector_add.lua          -- Vector addition example
└── tests/
    └── correctness_test.lua  -- Verify vector operations are correct
```

## Implementation

### Vector Operations (`vector_ops.lua`)

Provide Lua table-based vector operations that can be compared against pure loops vs. optimized variants:

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

### Correctness Testing

Create tests that verify Vector operations produce correct results for edge cases (zero vectors, negative values, large numbers).

## Time Estimate

8–12 hours
