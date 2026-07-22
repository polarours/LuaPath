-- Example 18: State Machine
-- Chapter: 13-patterns
-- Difficulty: Advanced
-- Lua Version: 5.1+

-- Demonstrates: state machine pattern, state transitions, actions

local function main()
  print("=== State Machine Demo ===\n")

  -- Simple state machine
  local FSM = {}
  FSM.__index = FSM

  function FSM.new(states, initial)
    return setmetatable({
      states = states,
      current = initial,
      history = {},
    }, FSM)
  end

  function FSM:transition(event)
    local state = self.states[self.current]
    if state and state[event] then
      local next_state = state[event]
      table.insert(self.history, {
        from = self.current,
        to = next_state,
        event = event,
      })
      self.current = next_state
      return true
    end
    return false
  end

  function FSM:get_state()
    return self.current
  end

  function FSM:get_history()
    return self.history
  end

  -- Define states
  local states = {
    idle = {
      start = "running",
      stop = "idle",
    },
    running = {
      pause = "paused",
      stop = "idle",
    },
    paused = {
      resume = "running",
      stop = "idle",
    },
  }

  -- Demo
  local fsm = FSM.new(states, "idle")

  print("Initial state:", fsm:get_state())

  fsm:transition("start")
  print("After start:", fsm:get_state())

  fsm:transition("pause")
  print("After pause:", fsm:get_state())

  fsm:transition("resume")
  print("After resume:", fsm:get_state())

  fsm:transition("stop")
  print("After stop:", fsm:get_state())

  print("\nHistory:")
  for _, h in ipairs(fsm:get_history()) do
    print(string.format("  %s -> %s (event: %s)", h.from, h.to, h.event))
  end

  print("\n=== Done ===")
end

main()
