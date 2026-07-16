-- Example 1: ECS (Entity Component System) Implementation
-- Chapter: 13-patterns
-- Difficulty: Advanced
-- Lua Version: 5.3+
--
-- Demonstrates: SoA layout, system iteration, performance-conscious design

local ECS = {}
ECS.__index = ECS

--- Create a new ECS world
-- @return world instance
function ECS:new()
  local self = setmetatable({}, ECS)
  self.entities = {}
  self.components = {}
  self.systems = {}
  self.next_id = 1
  return self
end

--- Create a new entity
-- @return entity id
function ECS:create_entity()
  local id = self.next_id
  self.next_id = self.next_id + 1
  self.entities[id] = true
  return id
end

--- Destroy an entity
-- @param id entity id
function ECS:destroy_entity(id)
  self.entities[id] = nil
  -- Remove all components
  for _, comp_type in ipairs(self.components) do
    if comp_type[id] then
      comp_type[id] = nil
    end
  end
end

--- Register a component type
-- @param name component type name
function ECS:register_component_type(name)
  if not self.components[name] then
    -- Structure of Arrays (SoA) for cache efficiency
    self.components[name] = setmetatable({}, {
      __mode = "k"  -- Weak keys for GC
    })
  end
end

--- Add a component to an entity
-- @param id entity id
-- @param type component type name
-- @param data component data
function ECS:add_component(id, type, data)
  if not self.components[type] then
    self:register_component_type(type)
  end
  self.components[type][id] = data or {}
end

--- Get a component from an entity
-- @param id entity id
-- @param type component type name
-- @return component data or nil
function ECS:get_component(id, type)
  local comp = self.components[type]
  return comp and comp[id]
end

--- Check if entity has a component
-- @param id entity id
-- @param type component type name
-- @return boolean
function ECS:has_component(id, type)
  local comp = self.components[type]
  return comp and comp[id] ~= nil
end

--- Remove a component from an entity
-- @param id entity id
-- @param type component type name
function ECS:remove_component(id, type)
  local comp = self.components[type]
  if comp then
    comp[id] = nil
  end
end

--- Query entities with specific components
-- @param ... component types to match (all required)
-- @return iterator function
function ECS:query(...)
  local types = {...}
  local indices = {}
  
  -- Find entities that have all required components
  for id in pairs(self.entities) do
    local has_all = true
    for _, t in ipairs(types) do
      if not self:has_component(id, t) then
        has_all = false
        break
      end
    end
    if has_all then
      table.insert(indices, id)
    end
  end
  
  local i = 0
  return function()
    i = i + 1
    local id = indices[i]
    if id then
      local result = {id = id}
      for _, t in ipairs(types) do
        result[t] = self.components[t][id]
      end
      return result
    end
  end
end

--- Register a system
-- @param name system name
-- @param fn system function (receives world and dt)
function ECS:register_system(name, fn)
  self.systems[name] = fn
end

--- Run a system
-- @param name system name
-- @param dt delta time
function ECS:run_system(name, dt)
  local system = self.systems[name]
  if system then
    system(self, dt)
  end
end

--- Run all systems
-- @param dt delta time
function ECS:update(dt)
  for name, system in pairs(self.systems) do
    system(self, dt)
  end
end

-- Example usage
print("ECS Implementation")
print("==================")

local world = ECS:new()

-- Register systems
world:register_system("movement", function(world, dt)
  for entity in world:query("Position", "Velocity") do
    local pos = entity.Position
    local vel = entity.Velocity
    pos.x = pos.x + vel.x * dt
    pos.y = pos.y + vel.y * dt
  end
end)

world:register_system("render", function(world, dt)
  for entity in world:query("Position", "Sprite") do
    local pos = entity.Position
    local sprite = entity.Sprite
    print(string.format("Rendering %s at (%.2f, %.2f)", 
      sprite.name, pos.x, pos.y))
  end
end)

-- Create entities
local player = world:create_entity()
world:add_component(player, "Position", {x = 100, y = 200})
world:add_component(player, "Velocity", {x = 50, y = 25})
world:add_component(player, "Sprite", {name = "player", frame = 1})

local enemy = world:create_entity()
world:add_component(enemy, "Position", {x = 300, y = 150})
world:add_component(enemy, "Velocity", {x = -30, y = 10})
world:add_component(enemy, "Sprite", {name = "enemy", frame = 1})

-- An entity without Sprite (not rendered)
local invisible = world:create_entity()
world:add_component(invisible, "Position", {x = 0, y = 0})
world:add_component(invisible, "Velocity", {x = 0, y = 0})

-- Update and render
print("\nUpdate 1 (dt=0.016):")
world:update(0.016)
world:run_system("render", 0.016)

print("\nUpdate 2 (dt=0.016):")
world:update(0.016)
world:run_system("render", 0.016)

print("\n✓ ECS test completed!")
