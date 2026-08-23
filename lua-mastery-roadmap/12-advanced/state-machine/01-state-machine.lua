--[[
  Example: State Machine
  Chapter: 12 — Advanced
  Difficulty: Advanced
  Lua Version: 5.3+
  Demonstrates: FSM design, guard conditions, entry/exit callbacks, metatables, traffic light demo
]]

local FSM = {}
FSM.__index = FSM

function FSM.new(name)
    return setmetatable({
        name = name or "FSM",
        _states = {},
        _current = nil,
        _transitions = {},
    }, FSM)
end

function FSM:add_state(name, opts)
    opts = opts or {}
    self._states[name] = {
        name = name,
        on_entry = opts.on_entry,
        on_exit = opts.on_exit,
        data = opts.data or {},
    }
    return self
end

function FSM:add_transition(from, to, event, opts)
    opts = opts or {}
    if not self._transitions[from] then self._transitions[from] = {} end
    self._transitions[from][event] = {
        target = to,
        guard = opts.guard,
        action = opts.action,
    }
    return self
end

function FSM:set_initial(state_name)
    if not self._states[state_name] then
        error(string.format("State '%s' not found", state_name))
    end
    self._current = state_name
    local s = self._states[state_name]
    if s.on_entry then s.on_entry(s) end
    print(string.format("[%s] Entered state: %s", self.name, state_name))
    return self
end

function FSM:fire(event, context)
    context = context or {}
    local transitions = self._transitions[self._current]
    if not transitions or not transitions[event] then
        print(string.format("[%s] No transition for '%s' in state '%s'", self.name, event, self._current))
        return false
    end
    local t = transitions[event]
    if t.guard and not t.guard(context, self._states[self._current]) then
        print(string.format("[%s] Guard rejected: %s -> %s on '%s'", self.name, self._current, t.target, event))
        return false
    end
    local old = self._states[self._current]
    if old.on_exit then old.on_exit(old) end
    print(string.format("[%s] %s --%s--> %s", self.name, self._current, event, t.target))
    if t.action then t.action(context, old, self._states[t.target]) end
    self._current = t.target
    local new = self._states[self._current]
    if new.on_entry then new.on_entry(new) end
    return true
end

function FSM:current() return self._current end

-- Traffic light demo
function traffic_light_demo()
    print("=== Traffic Light FSM ===\n")

    local light = FSM.new("TrafficLight")
    local timers = { green = 0, yellow = 0, red = 0 }

    light:add_state("green", {
        on_entry  = function(s) timers.green = timers.green + 1; s.data.count = timers.green end,
        on_exit   = function(s) print("  [exit green]") end,
    })
    light:add_state("yellow", {
        on_entry  = function(s) timers.yellow = timers.yellow + 1; s.data.count = timers.yellow end,
        on_exit   = function(s) print("  [exit yellow]") end,
    })
    light:add_state("red", {
        on_entry  = function(s) timers.red = timers.red + 1; s.data.count = timers.red end,
        on_exit   = function(s) print("  [exit red]") end,
    })

    light:add_transition("green",  "yellow", "timer_expired")
    light:add_transition("yellow", "red",    "timer_expired")
    light:add_transition("red",    "green",  "timer_expired")
    light:add_transition("green",  "red",    "emergency", {
        guard = function(ctx) return ctx.emergency == true end,
    })

    light:set_initial("green")
    for _ = 1, 3 do
        light:fire("timer_expired")
    end

    print("\n  Attempting emergency override from green:")
    light:fire("timer_expired")
    light:fire("emergency", { emergency = true })
    light:fire("timer_expired")

    print(string.format("\n  Cycle counts: green=%d yellow=%d red=%d",
        timers.green, timers.yellow, timers.red))
    print("=== Done ===\n")
end

-- Game state demo
function game_state_demo()
    print("=== Game State FSM ===\n")

    local game = FSM.new("Game")
    game:add_state("menu",    { on_entry = function() print("  >> Show main menu") end })
    game:add_state("playing", { on_entry = function() print("  >> Start level") end,
                                on_exit  = function() print("  >> Pause game") end })
    game:add_state("paused",  { on_entry = function() print("  >> Show pause overlay") end,
                                on_exit  = function() print("  >> Hide pause overlay") end })
    game:add_state("gameover", { on_entry = function() print("  >> Show game over screen") end })

    game:add_transition("menu",    "playing",  "start")
    game:add_transition("playing", "paused",   "pause")
    game:add_transition("paused",  "playing",  "resume")
    game:add_transition("playing", "gameover", "lose")
    game:add_transition("paused",  "gameover", "lose")
    game:add_transition("gameover","menu",     "restart")

    game:set_initial("menu")
    game:fire("start")
    game:fire("pause")
    game:fire("resume")
    game:fire("pause")
    game:fire("lose")
    game:fire("restart")

    print(string.format("\n  Final state: %s", game:current()))
    print("=== Done ===")
end

function main()
    traffic_light_demo()
    game_state_demo()
end

main()

return FSM
