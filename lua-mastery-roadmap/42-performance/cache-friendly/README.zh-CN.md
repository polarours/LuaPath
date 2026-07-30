# 第 42.1 阶段：缓存友好模式 — AoS vs SoA 比较

**级别**: 高级  
**描述**: 实现并基准测试数组结构 (AoS) 与结构数组 (SoA) 数据布局，理解其对 CPU 缓存行为和 Lua 性能的影响。

## 前置知识

- Stage 04 — Tables
- Stage 12 — Performance

## 项目结构

```
42-performance/cache-friendly/
├── README.md               # 本文件
├── README.zh-CN.md         # 中文版
├── aos_particles.lua       -- AoS 粒子系统实现
├── soa_particles.lua       -- SoA 粒子系统实现
├── tests/
│   └── benchmark_test.lua  -- 性能对比
└── examples/
    └── compare_layouts.lua -- 并排演示
```

## 实现细节

### AoS 布局 (`aos_particles.lua`)

```lua
-- 每个粒子是一个包含所有字段的自包含表格
local function create_particle(x, y, vx, vy)
  return {
    x = x, y = y,
    vx = vx, vy = vy,
    accel_x = 0, accel_y = 0,
  }
end

local particles = {}
for i = 1, N do
  particles[i] = create_particle(...)
end

local function update(particles, dt)
  for i = 1, #particles do
    local p = particles[i]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
  end
end
```

### SoA 布局 (`soa_particles.lua`)

```lua
-- 每个字段分别存储为独立数组
local x, y, vx, vy = {}, {}, {}, {}

for i = 1, N do
  x[i] = ...; y[i] = ...
  vx[i] = ...; vy[i] = ...
end

local function update(x, y, vx, vy, dt)
  for i = 1, #x do
    x[i] = x[i] + vx[i] * dt
    y[i] = y[i] + vy[i] * dt
  end
end
```

## 基准测试

创建一个基准测试，测量两种布局在不同 N (1k, 10k, 100k, 1M) 下的执行时间，并报告 SoA 与 AoS 的比率。预期：随着 N 增长，SoA 由于更好的缓存局部性将显著快于 AoS。

## 预估时间

8–12 小时
