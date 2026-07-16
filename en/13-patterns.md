# 13 — Patterns

> **Phase**: E (Performance and Production Design)  
> **Prerequisites**: Chapter 12 — Performance  
> **Time Estimate**: 2–3 hours reading + 3–5 hours exercises  
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT (differences noted)

---

## Learning Objectives

After completing this chapter, you will be able to:

1. **Apply common Lua design patterns** — OOP, module, factory, observer, state
2. **Build event-driven systems** with proper subscribe/unsubscribe semantics
3. **Design data-oriented patterns** like ECS for game/simulation workloads
4. **Create DSLs** using tables, metamethods, and callable objects
5. **Avoid pattern pitfalls** including memory leaks and hidden side effects

---

## OOP Patterns

### Prototype + Metatable Class

The standard Lua OOP pattern:

```lua
local Animal = {}
Animal.__index = Animal

function Animal.new(name, sound)
  return setmetatable({name = name, sound = sound, alive = true}, Animal)
end

function Animal:speak()
  return self.name .. " says " .. self.sound
end

function Animal:destroy()
  self.alive = false
end
```

### Inheritance

```lua
local Dog = setmetatable({}, {__index = Animal})
Dog.__index = Dog

function Dog.new(name, breed)
  local self = Animal.new(name, "woof")
  self.breed = breed
  return setmetatable(self, Dog)
end

function Dog:speak()
  return Animal.speak(self) .. " (breed: " .. self.breed .. ")"
end
```

### Composition Over Inheritance

```lua
-- BAD: Deep inheritance chain
-- Entity → LivingEntity → Character → Player → Warrior

-- GOOD: Composition
local function make_player(name, hp, weapon)
  return {
    name = name,
    health = make_health(hp),
    inventory = make_inventory(),
    combat = make_combat(weapon),
  }
end
```

### Mixin Pattern

```lua
-- Add behavior to multiple classes
local Serializable = {}
function Serializable:serialize()
  local parts = {}
  for k, v in pairs(self) do
    if type(v) ~= "function" then
      parts[#parts + 1] = k .. "=" .. tostring(v)
    end
  end
  return table.concat(parts, ",")
end

-- Apply to any class
local Player = {}
function Player:new(name)
  return setmetatable({name = name}, Player)
end

-- Add serialization
for k, v in pairs(Serializable) do Player[k] = v end
```

---

## Module Patterns

### Stateless Utility Module

```lua
-- Pure functions, no side effects
local M = {}
function M.clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end
function M.lerp(a, b, t) return a + (b - a) * t end
function M.round(x) return math.floor(x + 0.5) end
return M
```

### Stateful Service Module

```lua
local M = {}
local connection = nil

function M.connect(host, port)
  connection = create_connection(host, port)
end

function M.query(sql)
  assert(connection, "Not connected")
  return connection:execute(sql)
end

function M.disconnect()
  if connection then
    connection:close()
    connection = nil
  end
end

return M
```

### Factory Module

```lua
local M = {}
local counter = 0

function M.create(name)
  counter = counter + 1
  return {
    id = counter,
    name = name,
    created_at = os.time(),
  }
end

return M
```

---

## Functional Patterns

### Map / Filter / Reduce

```lua
local function map(t, fn)
  local result = {}
  for i, v in ipairs(t) do result[i] = fn(v) end
  return result
end

local function filter(t, fn)
  local result = {}
  for _, v in ipairs(t) do
    if fn(v) then result[#result + 1] = v end
  end
  return result
end

local function reduce(t, fn, init)
  local acc = init
  for _, v in ipairs(t) do acc = fn(acc, v) end
  return acc
end
```

### Composition

```lua
local function compose(...)
  local fns = {...}
  return function(...)
    local result = ...
    for i = #fns, 1, -1 do
      result = fns[i](result)
    end
    return result
  end
end

local process = compose(
  function(x) return x * 2 end,
  function(x) return x + 1 end,
  tostring
)
print(process(5))  -- "11"
```

### Currying

```lua
local function curry(fn, arity)
  arity = arity or debug.getinfo(fn).nparams
  return function(...)
    local args = {...}
    if #args >= arity then
      return fn(table.unpack(args))
    end
    return function(...)
      return fn(table.unpack(args), ...)
    end
  end
end

local add = curry(function(a, b) return a + b end)
print(add(3)(4))  -- 7
```

---

## Event Systems

### Basic Event Bus

```lua
local Bus = {handlers = {}}

function Bus:on(event, handler)
  local h = self.handlers[event] or {}
  h[#h + 1] = handler
  self.handlers[event] = h
  return function()
    -- Unsubscribe
    for i, fn in ipairs(h) do
      if fn == handler then
        table.remove(h, i)
        break
      end
    end
  end
end

function Bus:emit(event, ...)
  local h = self.handlers[event] or {}
  for _, handler in ipairs(h) do
    handler(...)
  end
end
```

### Priority Event Bus

```lua
function Bus:on(event, handler, priority)
  priority = priority or 0
  local h = self.handlers[event] or {}
  h[#h + 1] = {fn = handler, priority = priority}
  table.sort(h, function(a, b) return a.priority > b.priority end)
  self.handlers[event] = h
end
```

### Once Handler

```lua
function Bus:once(event, handler)
  local unsub
  unsub = self:on(event, function(...)
    handler(...)
    unsub()
  end)
end
```

---

## State Machine Pattern

### Table-Based State Machine

```lua
local FSM = {}
FSM.__index = FSM

function FSM.new(states, initial)
  return setmetatable({
    states = states,
    current = initial,
  }, FSM)
end

function FSM:transition(event)
  local state = self.states[self.current]
  if state and state[event] then
    self.current = state[event]
    return true
  end
  return false
end

-- Usage
local traffic = FSM.new({
  green  = {timeout = "yellow", emergency = "red"},
  yellow = {timeout = "red"},
  red    = {timeout = "green"},
}, "green")

traffic:transition("timeout")  -- → yellow
traffic:transition("timeout")  -- → red
```

### Coroutine-Based State Machine

```lua
local function traffic_light()
  while true do
    print("GREEN")
    coroutine.yield("green")
    print("YELLOW")
    coroutine.yield("yellow")
    print("RED")
    coroutine.yield("red")
  end
end

local co = coroutine.create(traffic_light)
coroutine.resume(co)  -- GREEN
coroutine.resume(co)  -- YELLOW
coroutine.resume(co)  -- RED
```

---

## Entity-Component-System (ECS)

### Data Layout (Structure of Arrays)

```lua
-- Components stored as separate arrays
local ECS = {
  entities = {},       -- {id → true}
  position = {},      -- {id → {x, y}}
  velocity = {},      -- {id → {dx, dy}}
  health = {},        -- {id → hp}
  next_id = 0,
}

function ECS:create()
  self.next_id = self.next_id + 1
  self.entities[self.next_id] = true
  return self.next_id
end

function ECS:add_component(id, name, data)
  if not self[name] then self[name] = {} end
  self[name][id] = data
end
```

### System (Iteration Over Components)

```lua
function ECS:movement_system(dt)
  for id in pairs(self.entities) do
    local pos = self.position[id]
    local vel = self.velocity[id]
    if pos and vel then
      pos.x = pos.x + vel.dx * dt
      pos.y = pos.y + vel.dy * dt
    end
  end
end

function ECS:damage_system(damage)
  for id in pairs(self.entities) do
    local hp = self.health[id]
    if hp then
      self.health[id] = hp - damage
      if self.health[id] <= 0 then
        self.entities[id] = nil
      end
    end
  end
end
```

### Benefits

- **Cache-friendly**: Same-type data is contiguous
- **Iteration speed**: Systems only touch relevant data
- **Flexibility**: Add/remove components without affecting other systems

---

## DSL Building

### Callable Tables

```lua
local Rule = setmetatable({}, {
  __call = function(_, name)
    return {name = name, checks = {}}
  end
})

local r = Rule("age_check")
  :check("age >= 18")
  :check("age <= 120")
  :on_fail("invalid age")
```

### Builder Pattern

```lua
local Query = {}
Query.__index = Query

function Query.new(table_name)
  return setmetatable({table = table_name, conditions = {}, order = nil}, Query)
end

function Query:where(condition)
  self.conditions[#self.conditions + 1] = condition
  return self
end

function Query:order_by(field)
  self.order = field
  return self
end

function Query:build()
  local sql = "SELECT * FROM " .. self.table
  if #self.conditions > 0 then
    sql = sql .. " WHERE " .. table.concat(self.conditions, " AND ")
  end
  if self.order then
    sql = sql .. " ORDER BY " .. self.order
  end
  return sql
end

-- Usage
local q = Query.new("users")
  :where("age >= 18")
  :where("active = true")
  :order_by("name")
print(q:build())
-- SELECT * FROM users WHERE age >= 18 AND active = true ORDER BY name
```

### Fluent API

```lua
local Pipeline = {}
Pipeline.__index = Pipeline

function Pipeline.new()
  return setmetatable({steps = {}}, Pipeline)
end

function Pipeline:step(name, fn)
  self.steps[#self.steps + 1] = {name = name, fn = fn}
  return self
end

function Pipeline:execute(input)
  local result = input
  for _, step in ipairs(self.steps) do
    result = step.fn(result)
  end
  return result
end

-- Usage
local result = Pipeline.new()
  :step("parse", function(data) return parse_json(data) end)
  :step("validate", function(data) return validate(data) end)
  :step("transform", function(data) return transform(data) end)
  :execute(raw_input)
```

---

## Common Pitfalls

### 1. Hidden Side Effects in Event Handlers

```lua
-- BAD: Handler modifies shared state unexpectedly
Bus:on("update", function(entity)
  entity.x = entity.x + 1  -- Who expects this?
end)

-- GOOD: Document side effects clearly
--- @description Moves entity right by 1 unit
--- @side_effect Modifies entity.x
Bus:on("update", function(entity)
  entity.x = entity.x + 1
end)
```

### 2. Unbounded Listener Growth

```lua
-- BAD: Listeners accumulate, never cleaned up
local function setup()
  Bus:on("tick", function() process() end)
  -- Called every frame → listeners grow forever!
end

-- GOOD: Unsubscribe when done
local function setup()
  local unsub = Bus:on("tick", function() process() end)
  -- Call unsub() when no longer needed
end
```

### 3. Deep Inheritance Chains

```lua
-- BAD: Hard to maintain
-- A → B → C → D → E → F

-- GOOD: Composition
local entity = {
  health = make_health(100),
  movement = make_movement(),
  renderable = make_sprite("hero"),
}
```

### 4. DSL Magic Obscuring Execution Order

```lua
-- BAD: Hard to tell what executes when
Rule("x")
  :check(...)  -- When does this run?
  :transform(...)  -- Before or after check?
  :on_fail(...)  -- When is on_fail called?

-- GOOD: Explicit ordering
rule:add_check(fn, {priority = 1})
rule:add_transform(fn, {priority = 2})
rule:add_on_fail(fn, {priority = 3})
```

### 5. Table Identity Misuse in ECS

```lua
-- BAD: Components as tables (identity issues)
local e1 = {position = {x = 0, y = 0}}
local e2 = {position = {x = 0, y = 0}}
-- Are e1.position and e2.position the same? No!

-- GOOD: Components by ID (no identity issues)
ecs.position[id1] = {x = 0, y = 0}
ecs.position[id2] = {x = 0, y = 0}
```

---

## Best Practices

### 1. Prefer Composition Over Inheritance

```lua
-- Composition: explicit, flexible
local function make_entity(components)
  local entity = {id = next_id()}
  for name, data in pairs(components) do
    entity[name] = data
  end
  return entity
end

-- Usage
local player = make_entity({
  health = {hp = 100, max_hp = 100},
  position = {x = 0, y = 0},
  inventory = {},
})
```

### 2. Document Event Contracts

```lua
--- Event: "damage"
--- Payload: {entity_id, amount, source}
--- Handlers: must return true to consume, false to propagate
Bus:on("damage", function(payload)
  -- ...
  return true  -- Consumed
end)
```

### 3. Keep Systems Pure

```lua
-- GOOD: System is pure function of component data
function movement_system(entities, dt)
  for id, pos in pairs(entities.position) do
    local vel = entities.velocity[id]
    if vel then
      pos.x = pos.x + vel.dx * dt
      pos.y = pos.y + vel.dy * dt
    end
  end
end

-- BAD: System has hidden state
local last_time = 0
function movement_system(entities)
  local dt = os.clock() - last_time  -- Hidden dependency!
  last_time = os.clock()
  -- ...
end
```

### 4. Use Metatables for Behavior, Not Data

```lua
-- GOOD: Metatable defines behavior
local Vec2 = {}
Vec2.__index = Vec2
function Vec2.__add(a, b) return Vec2.new(a.x + b.x, a.y + b.y) end

-- BAD: Metatable stores data
local bad = setmetatable({data = {}}, {__index = function(_, k) ... end})
```

### 5. Test Patterns in Isolation

```lua
-- Test event bus independently
local bus = make_bus()
local received = {}
bus:on("test", function(v) received[#received + 1] = v end)
bus:emit("test", 42)
assert(#received == 1)
assert(received[1] == 42)
```

---

## Version Notes

### Lua 5.1

- `setfenv`/`getfenv` for environment manipulation
- `module()` available (deprecated — don't use it)
- No `table.pack`/`table.unpack`

### Lua 5.2/5.3

- `setmetatable` works on tables with `__gc` (5.2+)
- `table.pack`/`table.unpack` available
- `goto` statement for complex control flow

### Lua 5.4

- `__close` for deterministic resource cleanup
- `__type` for custom type names
- Generational GC for better allocation-heavy pattern performance

### LuaJIT

- Metatables are JIT-friendly if patterns are monomorphic
- FFI enables C-style data layout in Lua
- Avoid polymorphic dispatch in hot traces

---

## Knowledge Check

<details>
<summary>1. When should you use composition over inheritance?</summary>

When entities don't share a strict "is-a" relationship, when you need flexibility to mix behaviors, or when inheritance chains get deep (3+ levels). Composition makes dependencies explicit.
</details>

<details>
<summary>2. What is the ECS pattern, and why is it performant?</summary>

ECS stores components in separate arrays by type (Structure of Arrays). Systems iterate over specific component types, touching only relevant data. This is cache-friendly and avoids virtual dispatch.
</details>

<details>
<summary>3. How do you prevent event listener memory leaks?</summary>

Store unsubscribe functions and call them when the listener is no longer needed. Alternatively, use weak tables or explicit cleanup in destroy/disconnect methods.
</details>

<details>
<summary>4. Why use metamethods for behavior instead of data storage?</summary>

Metamethods are called on operations (index, newindex, add, etc.). Using them for data storage creates confusion about where data lives. Metatables should define how objects respond to operations.
</details>

<details>
<summary>5. What makes a good DSL in Lua?</summary>

Clear execution order, explicit rather than magical syntax, easy to test individual parts, and no hidden side effects. Use builder/fluent patterns for readable chaining.
</details>

---

## Key Takeaways

- **Prototype OOP**: `__index` chains for inheritance; prefer composition for flexibility
- **Module patterns**: stateless utilities, stateful services, factories
- **Functional patterns**: map/filter/reduce, composition, currying
- **Event systems**: subscribe/unsubscribe with priority support
- **State machines**: table-based or coroutine-based
- **ECS**: data-oriented, cache-friendly, system-based iteration
- **DSLs**: callable tables, builder patterns, fluent APIs
- **Avoid**: deep inheritance, unbounded listeners, hidden side effects

---

## Exercises

### Beginner (30–60 min)

1. **Event Bus**: Implement a basic event bus with `on`, `emit`, and `off`. Test with 3 events.

2. **State Machine**: Build a turnstile state machine (locked → unlocked → locked) with events `coin` and `push`.

3. **Mixin**: Create a `Drawable` mixin and apply it to two different classes.

### Intermediate (1–2 hours)

4. **ECS Core**: Implement a minimal ECS with `create`, `add_component`, `get_component`, and a `movement_system`.

5. **Pipeline**: Build a data processing pipeline with `add_step` and `execute`. Steps can be async (coroutine-based).

6. **Priority Event Bus**: Add priority support to the event bus. Higher priority handlers run first.

### Advanced (2–4 hours)

7. **Reactive State**: Create a reactive system where changing a value automatically triggers dependents (like a spreadsheet).

8. **DSL Compiler**: Build a small DSL for defining validation rules. Compile rules to optimized check functions.

---

## Example Code

Runnable examples for this chapter:
- `examples/intermediate/01-prototype-entity.lua` — OOP pattern
- `examples/intermediate/02-event-bus.lua` — Event system
- `examples/intermediate/05-readonly-table.lua` — Proxy pattern
- `examples/advanced/01-ecs-system.lua` — ECS implementation

---

## Further Reading

- [Programming in Lua (4th ed.) — Chapter 16, 20, 23](https://www.lua.org/pil/)
- [Lua Design Patterns (community wiki)](https://lua-users.org/wiki/LuaDesignPatterns)
- [Next Chapter: 14 — Lua in Production](14-lua-in-production.md)
