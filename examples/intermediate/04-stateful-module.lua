-- Example 4: Module Pattern with State
-- Chapter: 06-modules
-- Difficulty: Intermediate
-- Lua Version: 5.1+
--
-- Demonstrates: module patterns, encapsulation, state management

-- Counter module with private state
local Counter = {}
local _private = {}

--- Initialize counter
-- @param name counter identifier
-- @param initial starting value
function Counter.init(name, initial)
  _private[name] = {
    value = initial or 0,
    history = {},
  }
  return Counter
end

--- Get current value
-- @param name counter identifier
-- @return current value
function Counter.get(name)
  local data = _private[name]
  if not data then
    return nil
  end
  return data.value
end

--- Increment counter
-- @param name counter identifier
-- @param amount amount to increment (default 1)
-- @return new value
function Counter.inc(name, amount)
  local data = _private[name]
  if not data then
    return nil
  end
  
  amount = amount or 1
  data.value = data.value + amount
  table.insert(data.history, {op = "inc", by = amount, at = os.time()})
  
  return data.value
end

--- Decrement counter
-- @param name counter identifier
-- @param amount amount to decrement (default 1)
-- @return new value
function Counter.dec(name, amount)
  return Counter.inc(name, -(amount or 1))
end

--- Reset counter
-- @param name counter identifier
-- @param to value to reset to (default 0)
-- @return new value
function Counter.reset(name, to)
  local data = _private[name]
  if not data then
    return nil
  end
  
  to = to or 0
  data.value = to
  table.insert(data.history, {op = "reset", to = to, at = os.time()})
  
  return data.value
end

--- Get history
-- @param name counter identifier
-- @return array of history entries
function Counter.history(name)
  local data = _private[name]
  if not data then
    return {}
  end
  
  -- Return copy to prevent external modification
  local copy = {}
  for i, entry in ipairs(data.history) do
    copy[i] = {
      op = entry.op,
      by = entry.by,
      to = entry.to,
      at = entry.at,
    }
  end
  return copy
end

--- Remove counter
-- @param name counter identifier
function Counter.destroy(name)
  _private[name] = nil
end

-- Export module
return Counter
