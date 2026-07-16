-- Example 3: Custom Memory Allocator Pattern
-- Chapter: 12-performance
-- Difficulty: Advanced
-- Lua Version: 5.4+
--
-- Demonstrates: object pooling, allocation reduction, GC tuning

local ObjectPool = {}
ObjectPool.__index = ObjectPool

--- Create a new object pool
-- @param factory function to create new objects
-- @param reset function to reset objects (optional)
-- @param initial_size initial pool size
-- @return pool instance
function ObjectPool:new(factory, reset, initial_size)
  local self = setmetatable({}, ObjectPool)
  self.factory = factory
  self.reset = reset or function(obj) return obj end
  self.available = {}
  self.in_use = {}
  self.created = 0
  self.reused = 0
  
  -- Pre-allocate
  for i = 1, (initial_size or 10) do
    table.insert(self.available, self.factory())
    self.created = self.created + 1
  end
  
  return self
end

--- Acquire an object from the pool
-- @return object
function ObjectPool:acquire()
  local obj
  
  if #self.available > 0 then
    obj = table.remove(self.available)
    self.reused = self.reused + 1
  else
    obj = self.factory()
    self.created = self.created + 1
  end
  
  self.in_use[obj] = true
  return obj
end

--- Release an object back to the pool
-- @param obj object to release
function ObjectPool:release(obj)
  if not self.in_use[obj] then
    return  -- Not in use, ignore
  end
  
  self.in_use[obj] = nil
  self.reset(obj)
  table.insert(self.available, obj)
end

--- Release all objects
function ObjectPool:release_all()
  for obj in pairs(self.in_use) do
    self:release(obj)
  end
end

--- Get pool statistics
-- @return statistics table
function ObjectPool:stats()
  return {
    available = #self.available,
    in_use = self.count_in_use(self),
    created = self.created,
    reused = self.reused,
    reuse_ratio = self.created > 0 and self.reused / (self.created + self.reused) or 0,
  }
end

function ObjectPool:count_in_use()
  local count = 0
  for _ in pairs(self.in_use) do
    count = count + 1
  end
  return count
end

--- Shrink pool (remove unused objects)
-- @param keep minimum number to keep
function ObjectPool:shrink(keep)
  keep = keep or 0
  while #self.available > keep do
    table.remove(self.available)
  end
end

-- Example: Particle system using object pool
print("Object Pool - Particle System")
print("=============================")

-- Particle factory
local function create_particle()
  return {
    x = 0,
    y = 0,
    vx = 0,
    vy = 0,
    life = 0,
    max_life = 1,
    color = {r = 1, g = 1, b = 1, a = 1},
    active = false,
  }
end

-- Particle reset
local function reset_particle(p)
  p.x = 0
  p.y = 0
  p.vx = 0
  p.vy = 0
  p.life = 0
  p.max_life = 1
  p.color = {r = 1, g = 1, b = 1, a = 1}
  p.active = false
end

-- Create pool
local particle_pool = ObjectPool:new(create_particle, reset_particle, 100)

-- Simulate particle system
local active_particles = {}

local function spawn_particle(x, y, vx, vy)
  local p = particle_pool:acquire()
  p.x = x
  p.y = y
  p.vx = vx
  p.vy = vy
  p.life = 0
  p.max_life = 1 + math.random()
  p.active = true
  table.insert(active_particles, p)
end

local function update_particles(dt)
  local i = 1
  while i <= #active_particles do
    local p = active_particles[i]
    p.life = p.life + dt
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.vy = p.vy - 9.8 * dt  -- Gravity
    
    if p.life >= p.max_life then
      p.active = false
      particle_pool:release(p)
      table.remove(active_particles, i)
    else
      i = i + 1
    end
  end
end

-- Simulation
math.randomseed(os.time())

print("\nSpawning 500 particles...")
for i = 1, 500 do
  spawn_particle(0, 100, math.random() * 100 - 50, math.random() * 50 + 50)
  
  if i % 100 == 0 then
    update_particles(0.016)
  end
end

print(string.format("Active particles: %d", #active_particles))

local stats = particle_pool:stats()
print(string.format("Pool stats - Created: %d, Reused: %d, Reuse ratio: %.2f%%",
  stats.created, stats.reused, stats.reuse_ratio * 100))

-- Continue simulation
print("\nSimulating 100 frames...")
for i = 1, 100 do
  update_particles(0.016)
  
  -- Spawn new particles
  if i % 10 == 0 then
    for j = 1, 50 do
      spawn_particle(0, 100, math.random() * 100 - 50, math.random() * 50 + 50)
    end
  end
end

stats = particle_pool:stats()
print(string.format("Final pool stats - Created: %d, Reused: %d, Reuse ratio: %.2f%%",
  stats.created, stats.reused, stats.reuse_ratio * 100))
print(string.format("Active particles: %d", #active_particles))

-- Cleanup
particle_pool:release_all()
stats = particle_pool:stats()
print(string.format("After release - Available: %d, In use: %d", 
  stats.available, stats.in_use))

print("\n✓ Object pool test completed!")
print("\nPerformance benefits:")
print("  - Reduced GC pressure from fewer allocations")
print("  - Better cache locality from object reuse")
print("  - Predictable memory usage")
