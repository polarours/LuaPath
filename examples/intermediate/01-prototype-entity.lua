-- Example 1: Prototype-based Entity System
-- Chapter: 05-metatables
-- Difficulty: Intermediate
-- Lua Version: 5.1+
--
-- Demonstrates: metatables, __index, prototype pattern

local Entity = {}
Entity.__index = Entity

--- Create a new entity
-- @param def table with initial properties
-- @return new entity instance
function Entity:new(def)
  local instance = setmetatable({}, self)
  instance.id = tostring(self):match("table: 0x(.+)")
  instance.active = true
  
  if def then
    for k, v in pairs(def) do
      instance[k] = v
    end
  end
  
  return instance
end

--- Update entity state
-- @param dt delta time
function Entity:update(dt)
  -- Override in subclasses
end

--- Render entity
function Entity:render()
  -- Override in subclasses
end

--- Destroy entity
function Entity:destroy()
  self.active = false
end

-- Player entity (inherits from Entity)
local Player = setmetatable({}, {__index = Entity})
Player.__index = Player

function Player:new(x, y)
  local instance = Entity.new(self, {x = x, y = y, health = 100})
  instance.type = "player"
  return setmetatable(instance, self)
end

function Player:update(dt)
  -- Player-specific update
  self.x = self.x + (self.vx or 0) * dt
  self.y = self.y + (self.vy or 0) * dt
end

-- Test
print("Prototype-based Entity System")
print("=============================")

local player = Player:new(100, 200)
print(string.format("Player created at (%d, %d)", player.x, player.y))

player.vx = 50
player.vy = 25
player:update(0.016)

print(string.format("Player moved to (%.2f, %.2f)", player.x, player.y))
print(string.format("Player type: %s", player.type))
print(string.format("Entity ID: %s", player.id))

-- Verify prototype chain
print(string.format("Player.__index == Player: %s", getmetatable(player).__index == Player))
print(string.format("Entity in metatable chain: %s", getmetatable(getmetatable(player).__index) == Entity))
