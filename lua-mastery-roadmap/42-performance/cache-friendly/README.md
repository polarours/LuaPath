# Stage 42.1: Cache-friendly Patterns — AoS vs SoA Comparison

**Level**: Advanced  
**Description**: Implement and benchmark Array-of-Structs (AoS) versus Struct-of-Arrays (SoA) data layouts to understand their impact on CPU cache behavior and Lua performance.

## Prerequisites

- Stage 04 — Tables
- Stage 12 — Performance

## Project Structure

```
42-performance/cache-friendly/
├── README.md               # This file
├── README.zh-CN.md         # Chinese version
├── aos_particles.lua       -- AoS particle system implementation
├── soa_particles.lua       -- SoA particle system implementation
├── tests/
│   └── benchmark_test.lua  -- Performance comparison
└── examples/
    └── compare_layouts.lua -- Side-by-side demo
```

## Implementation Details

### AoS Layout (`aos_particles.lua`)

```lua
-- Each particle is a self-contained table with all fields
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

### SoA Layout (`soa_particles.lua`)

```lua
-- Separate arrays for each field
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

## Benchmarking

Create a benchmark that measures execution time for both layouts with varying N (1k, 10k, 100k, 1M) and reports the ratio of SoA to AoS times. Expected: SoA should be significantly faster as N grows due to better cache locality when only updating position vectors.

## Time Estimate

8–12 hours
