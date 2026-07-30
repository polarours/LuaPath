-- aos_particles.lua — AoS particle system implementation
-- Each particle is a self-contained table with all fields.
-- Demonstrates Array-of-Structs layout pattern.

local AosParticles = {}
AosParticles.__index = AosParticles

function AosParticles.new(n)
  local self = setmetatable({}, AosParticles)
  self.particles = {}
  self.n = n

  for i = 1, n do
    self.particles[i] = {
      x = math.random() * 100,
      y = math.random() * 100,
      vx = (math.random() - 0.5) * 10,
      vy = (math.random() - 0.5) * 10,
    }
  end
  return self
end

function AosParticles:update(dt)
  for i = 1, #self.particles do
    local p = self.particles[i]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
  end
end

function AosParticles:get()
  return self.particles
end

return AosParticles
