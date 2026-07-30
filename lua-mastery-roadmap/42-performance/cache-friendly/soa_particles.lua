-- soa_particles.lua — SoA particle system implementation
-- Each field stored in separate arrays (Struct-of-Arrays).
-- Demonstrates Struct-of-Arrays layout pattern.

local SoaParticles = {}
SoaParticles.__index = SoaParticles

function SoaParticles.new(n)
  local self = setmetatable({}, SoaParticles)
  self.n = n
  self.x = {}
  self.y = {}
  self.vx = {}
  self.vy = {}

  for i = 1, n do
    self.x[i] = math.random() * 100
    self.y[i] = math.random() * 100
    self.vx[i] = (math.random() - 0.5) * 10
    self.vy[i] = (math.random() - 0.5) * 10
  end
  return self
end

function SoaParticles:update(dt)
  for i = 1, self.n do
    self.x[i] = self.x[i] + self.vx[i] * dt
    self.y[i] = self.y[i] + self.vy[i] * dt
  end
end

function SoaParticles:get()
  return self.x, self.y, self.vx, self.vy
end

return SoaParticles
